import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/services/game_settings.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/widgets/fx/fx_layer.dart';
import 'package:rummipoker/widgets/fx/juice.dart';
import 'package:rummipoker/widgets/fx/motion_policy.dart';
import 'package:rummipoker/widgets/fx/screen_shake.dart';
import 'package:rummipoker/widgets/fx/spring_follow.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    StorageHelper.resetForTest();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageHelper.init();
    MotionPolicy.debugReduceMotionOverride = false;
  });

  tearDown(() {
    MotionPolicy.debugReduceMotionOverride = null;
  });

  group('ScreenShake', () {
    test('trauma adds up, decays linearly, and shake is trauma squared', () {
      final shake = ScreenShake();
      shake.add(0.3);
      shake.add(0.3);
      expect(shake.trauma, closeTo(0.6, 1e-9));
      shake.advance(0.25);
      expect(shake.trauma, closeTo(0.6 - ScreenShake.decayPerSecond * 0.25,
          1e-9));
      final magnitude = shake.offset.distance;
      expect(
        magnitude,
        lessThanOrEqualTo(shake.trauma * shake.trauma * ScreenShake.maxOffset *
            1.5),
      );
      shake.advance(2);
      expect(shake.trauma, 0);
      expect(shake.offset, Offset.zero);
      shake.reset();
    });

    test('is zero under reduce motion or when disabled in settings', () {
      final shake = ScreenShake();
      MotionPolicy.debugReduceMotionOverride = true;
      shake.add(1);
      expect(shake.trauma, 0);

      MotionPolicy.debugReduceMotionOverride = false;
      GameSettings.screenShakeEnabled = false;
      shake.add(1);
      expect(shake.trauma, 0);

      GameSettings.screenShakeEnabled = true;
      GameSettings.fxIntensity = FxIntensity.off;
      shake.add(1);
      expect(shake.trauma, 0);
    });
  });

  group('Juice', () {
    test('squashes first, oscillates, and settles within 0.4s', () {
      expect(JuiceCurve.scaleAt(0, 1), lessThan(1));
      expect(JuiceCurve.scaleAt(1 / 16, 1), greaterThan(1));
      expect(JuiceCurve.scaleAt(0.4, 1), 1);
      expect(JuiceCurve.rotationAt(0.4, 1), 0);
      expect(JuiceCurve.scaleAt(0, 0), 1);
    });

    test('policy strength is zero under reduce motion', () {
      expect(MotionPolicy.juiceScale, 1);
      MotionPolicy.debugReduceMotionOverride = true;
      expect(MotionPolicy.juiceScale, 0);
      expect(MotionPolicy.shakeScale, 0);
    });

    testWidgets('does not transform the child under reduce motion', (
      tester,
    ) async {
      MotionPolicy.debugReduceMotionOverride = true;
      Widget host(int trigger) => Directionality(
        textDirection: TextDirection.ltr,
        child: Juice(
          trigger: trigger,
          pressed: true,
          child: const SizedBox(key: ValueKey('juice-child'), width: 20),
        ),
      );
      await tester.pumpWidget(host(0));
      await tester.pumpWidget(host(1));
      await tester.pump(const Duration(milliseconds: 30));
      final transform = tester.widget<Transform>(
        find.ancestor(
          of: find.byKey(const ValueKey('juice-child')),
          matching: find.byType(Transform),
        ),
      );
      expect(transform.transform.isIdentity(), isTrue);
    });
  });

  test('spring follow approaches the target exponentially', () {
    final half = springFollowStep(0, 10, 1, 0.6931471805599453);
    expect(half, closeTo(5, 1e-9));
    expect(springFollowStep(3, 3, 20, 0.016), 3);
  });

  testWidgets('FX layer draws particles and stops ticking when idle', (
    tester,
  ) async {
    final controller = FxController();
    await tester.pumpWidget(FxLayer(controller: controller));
    controller.emit(FxPresets.lineConfirm, const [Offset(40, 40)]);
    expect(controller.particleCount, FxPresets.lineConfirm.count);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(controller.particleCount, greaterThan(0));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 16));
    expect(controller.isIdle, isTrue);
    expect(tester.binding.transientCallbackCount, 0);

    GameSettings.fxIntensity = FxIntensity.off;
    controller.emit(FxPresets.coins, const [Offset(40, 40)]);
    expect(controller.particleCount, 0);
  });
}
