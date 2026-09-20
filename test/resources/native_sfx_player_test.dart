import 'dart:async';
import 'dart:io';
import 'package:rummipoker/resources/asset_paths.dart';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rummipoker/resources/native_sfx_player.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/storage_helper.dart';

class FakeSfxEngine implements NativeSfxEngine {
  int initCount = 0;
  int disposeCount = 0;
  int loads = 0;
  int next = 0;
  bool fail = false;
  Completer<void>? initGate;
  final events = <String>[];
  final rates = <int, double>{};
  final volumes = <int, double>{};
  final handles = <int>{};
  @override
  Future<void> initialize(int maxVoices) async {
    initCount++;
    if (fail) throw StateError('device unavailable');
    await initGate?.future;
  }

  @override
  Future<Object> load(String path, Uint8List bytes) async {
    loads++;
    return path;
  }

  @override
  int playPaused(Object source, double volume) {
    final handle = ++next;
    handles.add(handle);
    volumes[handle] = volume;
    events.add('paused:$handle');
    return handle;
  }

  @override
  void setRate(int handle, double rate) {
    rates[handle] = rate;
    events.add('rate:$handle');
  }

  @override
  void setPaused(int handle, bool paused) => events.add('resume:$handle');
  @override
  void setVolume(int handle, double volume) => volumes[handle] = volume;
  @override
  bool isValid(int handle) => handles.contains(handle);
  @override
  Future<void> stop(int handle) async {
    handles.remove(handle);
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
    handles.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeSfxEngine engine;
  late NativeSfxPlayer player;
  late List<String> errors;
  setUp(() {
    engine = FakeSfxEngine();
    errors = [];
    player = NativeSfxPlayer(
      engine: engine,
      loadAsset: (_) async => Uint8List(4),
      log: (message, _) => errors.add(message),
      maxVoices: 2,
    );
  });
  tearDown(() async {
    SoundManager.debugResetForTest();
    await player.dispose();
  });

  test(
    'all twelve registered assets load once and reach native output',
    () async {
      final loaded = <String>[];
      final realAssetPlayer = NativeSfxPlayer(
        engine: engine,
        loadAsset: (path) async {
          loaded.add(path);
          final bytes = await File('assets/audio/$path').readAsBytes();
          expect(bytes, isNotEmpty);
          return bytes;
        },
        log: (message, _) => errors.add(message),
      );
      addTearDown(realAssetPlayer.dispose);
      await realAssetPlayer.initialize(AssetPaths.sfxAssets);
      expect(AssetPaths.sfxAssets, hasLength(12));
      expect(loaded.toSet(), AssetPaths.sfxAssets.toSet());
      expect(realAssetPlayer.cachedSourceCount, 12);
      for (final path in AssetPaths.sfxAssets) {
        expect(realAssetPlayer.play(path, volume: 1, rate: 1), isNotNull);
      }
      expect(engine.rates.values, everyElement(1));
      expect(errors, isEmpty);
    },
  );

  test('concurrent preload shares init and source cache', () async {
    engine.initGate = Completer<void>();
    final first = player.initialize(['one', 'two', 'one']);
    final second = player.initialize(['one', 'two']);
    expect(identical(first, second), isTrue);
    engine.initGate!.complete();
    await Future.wait([first, second]);
    await player.initialize(['one', 'two']);
    expect(engine.initCount, 1);
    expect(engine.loads, 2);
    expect(player.cachedSourceCount, 2);
  });

  test(
    'each overlapping voice gets rate before first output and respects limit',
    () async {
      await player.initialize(['one']);
      final first = player.play('one', volume: 0.4, rate: 0.5)!;
      final second = player.play('one', volume: 0.4, rate: 1.5)!;
      expect(engine.events, [
        'paused:$first',
        'rate:$first',
        'resume:$first',
        'paused:$second',
        'rate:$second',
        'resume:$second',
      ]);
      expect(engine.rates, {first: 0.5, second: 1.5});
      expect(player.play('one', volume: 1, rate: 1), isNull);
      engine.handles.remove(first);
      expect(player.play('one', volume: 1, rate: 9), isNotNull);
      expect(engine.rates.values.last, 4);
    },
  );

  testWidgets('completed handles are pruned even without further playback', (
    tester,
  ) async {
    await player.initialize(['one']);
    player.play('one', volume: 1, rate: 1);
    engine.handles.clear();
    await tester.pump(const Duration(milliseconds: 300));
    expect(player.activeHandles, isEmpty);
  });

  test(
    'volume/mute and suspend stop old sounds without replay on resume',
    () async {
      await player.initialize(['one']);
      final first = player.play('one', volume: 1, rate: 0.5)!;
      player.configure(muted: false, volume: 0.2);
      expect(engine.volumes[first], 0.2);
      player.configure(muted: true, volume: 1);
      expect(engine.handles, isEmpty);
      expect(player.play('one', volume: 1, rate: 1), isNull);
      player.configure(muted: false, volume: 1);
      player.play('one', volume: 1, rate: 1);
      player.suspend();
      expect(engine.handles, isEmpty);
      expect(player.play('one', volume: 1, rate: 1), isNull);
      player.resume();
      expect(engine.handles, isEmpty);
      expect(player.play('one', volume: 1, rate: 0.01), isNotNull);
      expect(engine.rates.values.last, 0.25);
    },
  );

  test(
    'initialization failure logs, does not throw, and explicit retry succeeds',
    () async {
      engine.fail = true;
      await player.initialize(['one']);
      expect(player.isReady, isFalse);
      expect(errors, hasLength(1));
      expect(player.play('one', volume: 1, rate: 1), isNull);
      engine.fail = false;
      await player.initialize(['one']);
      expect(player.isReady, isTrue);
      expect(engine.initCount, 2);
    },
  );

  test(
    'timeout unblocks boot and late init cannot populate disposed cache',
    () async {
      player = NativeSfxPlayer(
        engine: engine,
        loadAsset: (_) async => Uint8List(4),
        log: (message, _) => errors.add(message),
        initializationTimeout: const Duration(milliseconds: 5),
      );
      engine.initGate = Completer<void>();
      await player.initialize(['one']);
      expect(player.isReady, isFalse);
      expect(engine.disposeCount, 1);
      engine.initGate!.complete();
      await Future<void>.delayed(Duration.zero);
      expect(engine.loads, 0);
      await player.initialize(['one']);
      expect(player.isReady, isTrue);
    },
  );

  test(
    'dispose during initialization invalidates cache and retry works',
    () async {
      engine.initGate = Completer<void>();
      final pending = player.initialize(['one']);
      await Future<void>.delayed(Duration.zero);
      await player.dispose();
      engine.initGate!.complete();
      await pending;
      expect(player.isReady, isFalse);
      expect(player.cachedSourceCount, 0);
      expect(engine.loads, 0);
      await player.initialize(['one']);
      expect(player.isReady, isTrue);
    },
  );

  test(
    'dispose before initialization starts prevents late engine creation',
    () async {
      final pending = player.initialize(['one']);
      await player.dispose();
      await pending;
      expect(engine.initCount, 0);
      expect(player.isReady, isFalse);
    },
  );

  test('global pitch and variance reach independent native voices', () async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues({});
    await StorageHelper.init();
    await player.initialize(['one']);
    SoundManager.debugNativeSfxPlayer = player;
    // BGM platform call만 생략한다. 실제 SFX 출력은 아래에서 native adapter로 간다.
    SoundManager.debugSfxSink = (_, _, _) {};
    SoundManager.rampGlobalPitch(0.5, Duration.zero);
    SoundManager.debugSfxSink = null;
    SoundManager.playSfx('one', pitch: 1.5, pitchVariance: 0.1);
    expect(engine.rates.values.single, inInclusiveRange(0.675, 0.825));
    SoundManager.debugSfxSink = (_, _, _) {};
    SoundManager.rampGlobalPitch(1, Duration.zero);
    SoundManager.debugSfxSink = null;
    SoundManager.playSfx('one', pitch: 2);
    expect(engine.rates.values.last, 2);
    expect(engine.rates.values.first, inInclusiveRange(0.675, 0.825));
  });

  test(
    'SoundManager forwards resolved rate and volume to native backend, without debug sink',
    () async {
      StorageHelper.resetForTest();
      SharedPreferences.setMockInitialValues({});
      await StorageHelper.init();
      await player.initialize(['one']);
      SoundManager.debugNativeSfxPlayer = player;
      GameSettings.sfxMuted = false;
      GameSettings.sfxVolume = 0.3;
      expect(SoundManager.debugSfxSink, isNull);
      SoundManager.playSfx('one', pitch: 1.5, pitchVariance: 0.1);
      expect(engine.rates.values.single, inInclusiveRange(1.35, 1.65));
      expect(engine.volumes.values.single, 0.3);
      GameSettings.sfxMuted = true;
      SoundManager.applySfxVolume();
      SoundManager.playSfx('one', pitch: 2);
      expect(engine.handles, isEmpty);
      expect(engine.next, 1);
    },
  );
}
