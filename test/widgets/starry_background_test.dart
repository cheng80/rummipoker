import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/widgets/fx/fx_ambient.dart';
import 'package:rummipoker/widgets/fx/motion_policy.dart';
import 'package:rummipoker/widgets/starry_background.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    StorageHelper.resetForTest();
    await StorageHelper.init();
    GameSettings.fxIntensity = FxIntensity.strong;
  });
  tearDown(() {
    MotionPolicy.debugReduceMotionOverride = null;
  });

  testWidgets(
    'stars animate independently of the cached gradient and stop when off',
    (tester) async {
      final controller = FxAmbientController();
      var gradientChanges = 0;
      controller.moodRepaint.addListener(() => gradientChanges++);
      await tester.pumpWidget(
        MaterialApp(home: StarryBackground(controller: controller)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(controller.elapsed, greaterThan(0));
      expect(gradientChanges, 0);
      expect(tester.takeException(), isNull);
      final previous = controller.elapsed;
      GameSettings.fxIntensity = FxIntensity.off;
      await tester.pumpWidget(
        MaterialApp(
          home: StarryBackground(
            key: const ValueKey('off'),
            controller: controller,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(controller.elapsed, previous);
      expect(controller.shouldAnimate, isFalse);
      final painters = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
      expect(painters.where((p) => p.willChange), isEmpty);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );

  testWidgets('reduced motion, TickerMode and lifecycle pause the star clock', (
    tester,
  ) async {
    final controller = FxAmbientController();
    Widget host(bool reduce, bool enabled) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: TickerMode(
          enabled: enabled,
          child: StarryBackground(controller: controller),
        ),
      ),
    );
    await tester.pumpWidget(host(true, true));
    await tester.pump(const Duration(seconds: 1));
    expect(controller.elapsed, 0);
    await tester.pumpWidget(host(false, false));
    await tester.pump(const Duration(seconds: 1));
    expect(controller.elapsed, 0);
    await tester.pumpWidget(host(false, true));
    await tester.pump(const Duration(milliseconds: 200));
    expect(controller.elapsed, greaterThan(0));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    final paused = controller.elapsed;
    await tester.pump(const Duration(seconds: 1));
    expect(controller.elapsed, paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 200));
    expect(controller.elapsed, greaterThan(paused));
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  testWidgets(
    'shared background survives key replacement with motion enabled',
    (tester) async {
      FxAmbient.debugReset();
      final controller = FxAmbient.controller;
      Widget host(int key) =>
          MaterialApp(home: StarryBackground(key: ValueKey(key)));
      await tester.pumpWidget(host(1));
      await tester.pump(const Duration(milliseconds: 200));
      final previous = controller.elapsed;
      await tester.pumpWidget(host(2));
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.motionAllowed, isTrue);
      expect(controller.elapsed, greaterThan(previous));
      controller.setMood(FxAmbientMood.boss);
      expect(controller.isTransitioning, isTrue);
      await tester.pumpWidget(const SizedBox());
      expect(controller.shouldAnimate, isFalse);
    },
  );
}
