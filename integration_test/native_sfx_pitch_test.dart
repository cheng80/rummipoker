// 엔진 PCM 캡처 API는 실기 검증에서만 사용한다.
// ignore_for_file: avoid_print, experimental_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rummipoker/resources/asset_paths.dart';
import 'package:rummipoker/resources/native_sfx_bridge_io.dart';
import 'package:rummipoker/resources/native_sfx_player.dart';
import 'package:rummipoker/resources/sound_manager.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/storage_helper.dart';

const _sampleRate = 44100;
const _fftSize = 32768;
const _tone = 'qa-generated-440.wav';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native engine resamples SFX and coexists with BGM', (
    tester,
  ) async {
    // 게임 본체를 띄우지 않고 기기의 저장 데이터도 변경하지 않는다.
    SharedPreferences.setMockInitialValues({});
    StorageHelper.resetForTest();
    await StorageHelper.init();
    GameSettings.sfxMuted = false;
    GameSettings.bgmMuted = false;
    GameSettings.bgmVolume = 0.1;
    final errors = <String>[];
    final player = NativeSfxPlayer(
      engine: SoloudSfxEngine(),
      loadAsset: (path) async {
        if (path == _tone) return _sineWav();
        final data = await rootBundle.load('assets/audio/$path');
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      },
      log: (message, error) {
        errors.add('$message: $error');
        print(errors.last);
      },
    );
    final results = <Map<String, Object>>[];
    SoundManager.debugNativeSfxPlayer = player;
    var cleanedUp = false;
    Future<void> cleanup() async {
      if (cleanedUp) return;
      cleanedUp = true;
      SoLoud.instance.stopMixerOutputStream();
      await SoundManager.stopBgm();
      await FlameAudio.bgm.dispose();
      await player.dispose();
      SoundManager.debugResetForTest();
    }

    addTearDown(cleanup);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Native SFX QA'))),
    );
    await player.initialize([_tone, ...AssetPaths.sfxAssets]);
    expect(player.isReady, isTrue, reason: errors.join('\n'));
    expect(player.cachedSourceCount, AssetPaths.sfxAssets.length + 1);
    expect(SoundManager.debugSfxSink, isNull);

    for (final rate in [0.5, 1.0, 1.5, 2.0]) {
      final samples = await _capture('rate_$rate', () {
        final handle = player.play(_tone, volume: 0.15, rate: rate);
        expect(handle, isNotNull);
        print(
          'NATIVE_SFX_HANDLE requested=$rate actual=${SoLoud.instance.getRelativePlaySpeed(SoundHandle(handle!))} handle=$handle',
        );
        expect(
          SoLoud.instance.getRelativePlaySpeed(SoundHandle(handle)),
          closeTo(rate, 1e-5),
        );
      });
      final magnitudes = _fft(samples);
      final peak = _peakHz(magnitudes, 100, 1400);
      expect(peak, closeTo(440 * rate, 5));
      results.add({'rate': rate, 'expectedHz': 440 * rate, 'measuredHz': peak});
      print('NATIVE_SFX_FFT ${results.last}');
      player.suspend();
      player.resume();
    }
    final overlap = await _capture('overlap_0.5_2', () {
      player.play(_tone, volume: 0.1, rate: 0.5);
      player.play(_tone, volume: 0.1, rate: 2);
    });
    final spectrum = _fft(overlap);
    expect(_peakHz(spectrum, 150, 300), closeTo(220, 5));
    expect(_peakHz(spectrum, 700, 1000), closeTo(880, 5));
    // 두 피크에 실제 에너지가 있어야 한다. 무음이나 잡음을 성공으로 판정하지 않는다.
    final low = spectrum[(220 * _fftSize / _sampleRate).round()];
    final high = spectrum[(880 * _fftSize / _sampleRate).round()];
    expect(low, greaterThan(10));
    expect(high, greaterThan(10));
    player.suspend();
    player.resume();

    await SoundManager.playBgm(AssetPaths.bgmMenu);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(FlameAudio.bgm.audioPlayer.state, PlayerState.playing);
    final withBgm = await _capture(
      'with_bgm',
      () => SoundManager.playSfx(_tone, pitch: 1.5),
    );
    expect(_peakHz(_fft(withBgm), 100, 1400), closeTo(660, 5));
    expect(FlameAudio.bgm.audioPlayer.state, PlayerState.playing);
    SoundManager.suspendSfx();
    SoundManager.pauseBgm();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(player.activeHandles, isEmpty);
    expect(FlameAudio.bgm.audioPlayer.state, PlayerState.paused);
    SoundManager.resumeSfx();
    // BGM이 정지한 상태에서도 SFX 단독 출력이 가능해야 한다.
    final sfxOnly = await _capture(
      'after_bgm_pause',
      () => SoundManager.playSfx(_tone, pitch: 0.5),
    );
    expect(_peakHz(_fft(sfxOnly), 100, 1400), closeTo(220, 5));
    SoundManager.resumeBgm();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(FlameAudio.bgm.audioPlayer.state, PlayerState.playing);
    GameSettings.sfxMuted = true;
    SoundManager.applySfxVolume();
    expect(player.activeHandles, isEmpty);
    SoundManager.playSfx(_tone);
    expect(player.activeHandles, isEmpty);
    GameSettings.sfxMuted = false;
    SoundManager.applySfxVolume();
    // 등록된 실제 음원 12개를 연속 재생하고 캐시를 재사용한다.
    for (final path in AssetPaths.sfxAssets) {
      SoundManager.playSfx(path, pitch: 1.12);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    expect(player.cachedSourceCount, AssetPaths.sfxAssets.length + 1);
    expect(errors, isEmpty);
    binding.reportData = {
      'native_sfx_fft': results,
      'overlapHz': [220, 880],
      'bgmCoexistence': true,
      'sourceCount': AssetPaths.sfxAssets.length + 1,
    };
    // Widget test는 tearDown 전에 transient frame callback을 검사한다.
    // BGM의 FramePositionUpdater까지 본문 종료 전에 정리한다.
    await cleanup();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

Future<List<double>> _capture(String label, void Function() play) async {
  final values = <double>[];
  final rawValues = <double>[];
  final chunkSizes = <int>[];
  final watch = Stopwatch()..start();
  final complete = Completer<void>();
  // 4.1.7 capture는 채널 변환 없이 mixer PCM을 복사한다.
  // 엔진의 stereo 형식을 그대로 받고 Dart에서 L/R 평균을 낸다.
  final stream = SoLoud.instance.startMixerOutputStream();
  final subscription = stream.listen(
    (bytes) {
      chunkSizes.add(bytes.length);
      final data = ByteData.sublistView(bytes);
      for (var i = 0; i + 8 <= data.lengthInBytes; i += 8) {
        final left = data.getFloat32(i, Endian.little);
        final right = data.getFloat32(i + 4, Endian.little);
        rawValues.addAll([left, right]);
        values.add((left + right) / 2);
      }
      if (values.length >= _fftSize + 8192 && !complete.isCompleted) {
        complete.complete();
      }
    },
    onError: (Object error, StackTrace stack) {
      if (!complete.isCompleted) complete.completeError(error, stack);
    },
  );
  try {
    play();
    await complete.future.timeout(const Duration(seconds: 8));
    SoLoud.instance.stopMixerOutputStream();
    await subscription.cancel();
    final window = values.sublist(values.length - _fftSize);
    final directory = Directory(
      '${Directory.systemTemp.path}/native_sfx_pitch',
    );
    await directory.create(recursive: true);
    final raw = ByteData(rawValues.length * 4);
    for (var i = 0; i < rawValues.length; i++) {
      raw.setFloat32(i * 4, rawValues[i], Endian.little);
    }
    await File(
      '${directory.path}/$label.f32',
    ).writeAsBytes(raw.buffer.asUint8List());
    await File('${directory.path}/source_440.wav').writeAsBytes(_sineWav());
    final spectrum = _fft(window);
    final bins = List.generate(spectrum.length - 1, (i) => i + 1)
      ..sort((a, b) => spectrum[b].compareTo(spectrum[a]));
    final metadata = <String, Object>{
      'label': label,
      'platform': Platform.operatingSystem,
      'engineRequestedSampleRate': 44100,
      'engineRequestedChannels': 2,
      'engineActualFormat': 'not exposed by SoLoud 4.1.7 public Dart API',
      'captureSampleRate': _sampleRate,
      'captureChannels': 2,
      'rawSamples': rawValues.length,
      'format': 'float32 little endian',
      'samples': values.length,
      'fftSize': _fftSize,
      'elapsedMs': watch.elapsedMilliseconds,
      'rms': math.sqrt(
        values.fold(0.0, (sum, x) => sum + x * x) / values.length,
      ),
      'min': values.reduce(math.min),
      'max': values.reduce(math.max),
      'chunks': chunkSizes,
      'peaks': bins
          .take(12)
          .map(
            (i) => {'hz': i * _sampleRate / _fftSize, 'magnitude': spectrum[i]},
          )
          .toList(),
      'path': '${directory.path}/$label.f32',
    };
    await File(
      '${directory.path}/$label.json',
    ).writeAsString(jsonEncode(metadata));
    print('NATIVE_SFX_PCM ${jsonEncode(metadata)}');
    return window;
  } finally {
    SoLoud.instance.stopMixerOutputStream();
    await subscription.cancel();
  }
}

Uint8List _sineWav() {
  const frames = _sampleRate * 4;
  final data = ByteData(44 + frames * 2);
  void text(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      data.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  text(0, 'RIFF');
  data.setUint32(4, data.lengthInBytes - 8, Endian.little);
  text(8, 'WAVE');
  text(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, _sampleRate, Endian.little);
  data.setUint32(28, _sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  text(36, 'data');
  data.setUint32(40, frames * 2, Endian.little);
  for (var i = 0; i < frames; i++) {
    data.setInt16(
      44 + i * 2,
      (math.sin(2 * math.pi * 440 * i / _sampleRate) * 16000).round(),
      Endian.little,
    );
  }
  return data.buffer.asUint8List();
}

// Radix-2 FFT on captured engine PCM, with a Hann window.
List<double> _fft(List<double> samples) {
  final real = List.generate(
    _fftSize,
    (i) =>
        samples[i] * (0.5 - 0.5 * math.cos(2 * math.pi * i / (_fftSize - 1))),
  );
  final imaginary = List.filled(_fftSize, 0.0);
  for (int i = 1, j = 0; i < _fftSize; i++) {
    var bit = _fftSize >> 1;
    for (; j & bit != 0; bit >>= 1) {
      j ^= bit;
    }
    j ^= bit;
    if (i < j) {
      final value = real[i];
      real[i] = real[j];
      real[j] = value;
    }
  }
  for (var size = 2; size <= _fftSize; size <<= 1) {
    for (var base = 0; base < _fftSize; base += size) {
      for (var j = 0; j < size ~/ 2; j++) {
        final angle = -2 * math.pi * j / size;
        final a = base + j, b = a + size ~/ 2;
        final tr = real[b] * math.cos(angle) - imaginary[b] * math.sin(angle);
        final ti = real[b] * math.sin(angle) + imaginary[b] * math.cos(angle);
        real[b] = real[a] - tr;
        imaginary[b] = imaginary[a] - ti;
        real[a] += tr;
        imaginary[a] += ti;
      }
    }
  }
  return List.generate(
    _fftSize ~/ 2,
    (i) => math.sqrt(real[i] * real[i] + imaginary[i] * imaginary[i]),
  );
}

double _peakHz(List<double> spectrum, double low, double high) {
  var peak = (low * _fftSize / _sampleRate).ceil();
  for (var i = peak + 1; i <= (high * _fftSize / _sampleRate).floor(); i++) {
    if (spectrum[i] > spectrum[peak]) peak = i;
  }
  expect(
    spectrum[peak],
    greaterThan(10),
    reason: 'Captured tone must not be silent',
  );
  return peak * _sampleRate / _fftSize;
}
