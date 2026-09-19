import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rummipoker/providers/features/settings/settings_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/widgets/fx/motion_policy.dart';
import 'package:rummipoker/widgets/fx/tile_material.dart';
import 'package:rummipoker/views/game/widgets/game_shared_widgets.dart';

void main() {
  const tile = Tile(
    color: TileColor.red,
    number: 13,
    edition: TileEdition.prismEdition,
  );
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    StorageHelper.resetForTest();
    await StorageHelper.init();
    GameSettings.fxIntensity = FxIntensity.strong;
    MotionPolicy.debugReduceMotionOverride = false;
  });
  tearDown(() {
    MotionPolicy.debugReduceMotionOverride = null;
  });

  test(
    'every modifier paints at board and detail sizes without changing tile state',
    () {
      final tiles = [
        for (final e in TileEnhancement.values) tile.copyWith(enhancement: e),
        for (final s in TileSeal.values) tile.copyWith(seal: s),
        for (final e in TileEdition.values) tile.copyWith(edition: e),
      ];
      for (final t in tiles) {
        final state = t.toJson();
        for (final side in [28.0, 54.0, 160.0]) {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          final size = Size(side, side * 1.3);
          paintTileMaterialFace(canvas, Offset.zero & size, t);
          TileMaterialPainter(tile: t).paint(canvas, size);
          recorder.endRecording().dispose();
        }
        expect(t.toJson(), state);
      }
    },
  );

  testWidgets(
    'one clock advances four visible tiles and stops when none remain',
    (tester) async {
      final clock = TileMaterialClock();
      final leases = List.generate(12, (_) => TileMaterialLease(() => true));
      for (final lease in leases) {
        clock.attach(lease);
      }
      await tester.pump();
      expect(clock.animatedCount, 4);
      await tester.pump(const Duration(milliseconds: 200));
      expect(leases.take(4).every((l) => l.phase != .25), isTrue);
      expect(leases.skip(4).every((l) => l.phase == .25), isTrue);
      for (final lease in leases) {
        clock.detach(lease);
        lease.dispose();
      }
      expect(clock.isRunning, isFalse);
    },
  );

  testWidgets('off, reduced motion, invisibility and inactive stop the clock', (
    tester,
  ) async {
    var visible = true;
    final clock = TileMaterialClock();
    final lease = TileMaterialLease(() => visible);
    clock.attach(lease);
    await tester.pump();
    expect(clock.isRunning, isTrue);
    GameSettings.fxIntensity = FxIntensity.off;
    clock.refresh();
    expect(clock.isRunning, isFalse);
    GameSettings.fxIntensity = FxIntensity.strong;
    MotionPolicy.debugReduceMotionOverride = true;
    clock.refresh();
    expect(clock.isRunning, isFalse);
    MotionPolicy.debugReduceMotionOverride = false;
    visible = false;
    clock.refresh();
    expect(clock.isRunning, isFalse);
    visible = true;
    clock.didChangeAppLifecycleState(AppLifecycleState.inactive);
    expect(clock.isRunning, isFalse);
    clock.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(clock.isRunning, isTrue);
    clock.detach(lease);
    lease.dispose();
  });

  testWidgets(
    'tile keeps badge selection and final state when motion is skipped',
    (tester) async {
      final state = tile.toJson();
      Widget host(bool reduce, bool offstage) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(800, 600),
            disableAnimations: reduce,
          ),
          child: Center(
            child: Offstage(
              offstage: offstage,
              child: const SizedBox(
                width: 54,
                child: GameRummiTileCard(
                  tile: tile,
                  selected: true,
                  accent: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(host(false, false));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const ValueKey('tile-edition-badge')), findsOneWidget);
      expect(TileMaterialClock.instance.isRunning, isTrue);
      await tester.pumpWidget(host(true, false));
      expect(TileMaterialClock.instance.isRunning, isFalse);
      await tester.pumpWidget(host(false, true));
      expect(TileMaterialClock.instance.isRunning, isFalse);
      expect(tile.toJson(), state);
      await tester.pumpWidget(const SizedBox());
      expect(TileMaterialClock.instance.isRunning, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'settings changes resume a stopped visible tile without rebuilding it',
    (tester) async {
      final container = ProviderContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Center(
              child: SizedBox(
                width: 54,
                height: 70,
                child: TileMaterialSurface(tile: tile),
              ),
            ),
          ),
        ),
      );
      expect(TileMaterialClock.instance.isRunning, isTrue);
      final settings = container.read(settingsNotifierProvider.notifier);
      settings.setFxIntensity(FxIntensity.off);
      await tester.pump();
      expect(TileMaterialClock.instance.isRunning, isFalse);
      settings.setFxIntensity(FxIntensity.strong);
      await tester.pump();
      expect(TileMaterialClock.instance.isRunning, isTrue);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    },
  );

  testWidgets(
    'clipped scrolling tiles yield animation slots and resume on return',
    (tester) async {
      final scroll = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: SingleChildScrollView(
                controller: scroll,
                child: const Column(
                  children: [
                    SizedBox(
                      width: 54,
                      height: 70,
                      child: TileMaterialSurface(tile: tile),
                    ),
                    SizedBox(height: 500),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(TileMaterialClock.instance.isRunning, isTrue);
      scroll.jumpTo(200);
      await tester.pump(const Duration(milliseconds: 100));
      expect(TileMaterialClock.instance.isRunning, isFalse);
      scroll.jumpTo(0);
      await tester.pump();
      expect(TileMaterialClock.instance.isRunning, isTrue);
      await tester.pumpWidget(const SizedBox());
      scroll.dispose();
    },
  );
  testWidgets(
    'replacement tile releases inactive lease before a new tile mounts',
    (tester) async {
      Widget host(int id) => MaterialApp(
        home: Center(
          child: SizedBox(
            width: 54,
            height: 70,
            child: TileMaterialSurface(key: ValueKey(id), tile: tile),
          ),
        ),
      );
      await tester.pumpWidget(host(1));
      await tester.pumpWidget(host(2));
      expect(tester.takeException(), isNull);
      expect(TileMaterialClock.instance.animatedCount, 1);
      await tester.pumpWidget(const SizedBox());
      expect(TileMaterialClock.instance.isRunning, isFalse);
    },
  );
  testWidgets('twelve material rebuilds share one visibility pass per frame', (
    tester,
  ) async {
    Widget host() => MaterialApp(
      home: Row(
        children: [
          for (var i = 0; i < 12; i++)
            SizedBox(
              width: 28,
              height: 40,
              child: TileMaterialSurface(tile: tile),
            ),
        ],
      ),
    );
    final clock = TileMaterialClock.instance;
    await tester.pumpWidget(host());
    final before = clock.debugVisibilityPasses;
    await tester.pumpWidget(host());
    expect(clock.debugVisibilityPasses - before, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('one timer tick inspects each candidate at most once', (
    tester,
  ) async {
    final clock = TileMaterialClock();
    var calls = 0;
    final leases = List.generate(
      12,
      (_) => TileMaterialLease(() {
        calls++;
        return true;
      }),
    );
    for (final lease in leases) {
      clock.attach(lease);
    }
    await tester.pump();
    calls = 0;
    await tester.pump(const Duration(milliseconds: 200));
    expect(calls, TileMaterialClock.maxAnimatedTiles);
    for (final lease in leases) {
      clock.detach(lease);
      lease.dispose();
    }
  });

  test('unassigned material starts with an in-face static highlight', () {
    final lease = TileMaterialLease(() => true);
    expect(lease.phase, .25);
    lease.dispose();
  });

  for (final side in [28.0, 54.0, 160.0]) {
    testWidgets('accent ring pixels survive material overlay at $side', (
      tester,
    ) async {
      GameSettings.fxIntensity = FxIntensity.off;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: side,
              child: const GameRummiTileCard(
                tile: tile,
                selected: false,
                accent: true,
              ),
            ),
          ),
        ),
      );
      final paints = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(GameRummiTileCard),
              matching: find.byType(CustomPaint),
            ),
          )
          .toList();
      final base = paints
          .firstWhere((p) => p.painter is! TileMaterialPainter)
          .painter!;
      final material = paints
          .firstWhere((p) => p.painter is TileMaterialPainter)
          .painter!;
      final size = tester.getSize(find.byType(TileMaterialSurface));
      await tester.runAsync(() async {
        Future<List<int>> ringPixel(bool overlay) async {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          base.paint(canvas, size);
          if (overlay) material.paint(canvas, size);
          final picture = recorder.endRecording();
          final image = await picture.toImage(
            size.width.ceil(),
            size.height.ceil(),
          );
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          final offset = (3 * image.width + image.width ~/ 2) * 4;
          final pixel = List.generate(4, (i) => bytes.getUint8(offset + i));
          image.dispose();
          picture.dispose();
          return pixel;
        }

        final original = await ringPixel(false);
        expect(original[3], 255);
        expect(original[0], greaterThan(original[2]));
        expect(await ringPixel(true), original);
      });
      await tester.pumpWidget(const SizedBox());
    });
  }
}
