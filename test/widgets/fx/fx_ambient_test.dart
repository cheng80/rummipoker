import 'package:flutter_test/flutter_test.dart';

import 'package:rummipoker/widgets/fx/fx_ambient.dart';

void main() {
  group('FxAmbientController', () {
    test('creates 100 deterministic stars', () {
      final first = createFxAmbientStars();
      final second = createFxAmbientStars();

      expect(first, hasLength(100));
      expect(first.map((star) => star.nx), second.map((star) => star.nx));
      expect(first.where((star) => star.glow), isNotEmpty);
    });

    test('mood transition reaches its target over the shared timing', () {
      final controller = FxAmbientController();
      addTearDown(controller.dispose);

      controller.setMood(FxAmbientMood.battle);
      expect(controller.isTransitioning, isTrue);
      controller.advance(
        FxAmbientController.transitionDuration.inMilliseconds / 1000,
      );

      expect(controller.isTransitioning, isFalse);
      expect(controller.moodColor, controller.moodTargetColor);
    });

    test('off motion settles mood immediately and skips pulse', () {
      final controller = FxAmbientController();
      addTearDown(controller.dispose);
      controller.setMotionEnabled(false);

      controller.setMood(FxAmbientMood.reward);
      controller.pulse(1);
      controller.advance(1);

      expect(controller.moodProgress, 1);
      expect(controller.moodColor, controller.moodTargetColor);
      expect(controller.pulseStrength, 0);
      expect(controller.elapsed, 0);
    });

    test('lifecycle, ticker mode, and empty star set stop the clock', () {
      final controller = FxAmbientController();
      addTearDown(controller.dispose);

      controller.setLifecycleActive(false);
      controller.advance(1);
      expect(controller.elapsed, 0);
      controller.setLifecycleActive(true);

      controller.setTickerModeEnabled(false);
      controller.advance(1);
      expect(controller.elapsed, 0);
      controller.setTickerModeEnabled(true);

      controller.setHasAnimatedStars(false);
      controller.advance(1);
      expect(controller.elapsed, 0);
      expect(controller.shouldAnimate, isFalse);
    });
  });
  test('pulse fades completely and the same mood survives skipping motion', () {
    final animated = FxAmbientController();
    final skipped = FxAmbientController();
    animated.setMood(FxAmbientMood.boss);
    animated.pulse(1);
    final start = animated.pulseValue;
    animated.advance(.4);
    expect(animated.pulseValue, lessThan(start));
    animated.advance(.6);
    skipped.setMotionEnabled(false);
    skipped.setMood(FxAmbientMood.boss);
    expect(animated.pulseValue, 0);
    expect(animated.pulseStrength, 0);
    expect(animated.moodColor, skipped.moodColor);
    animated.dispose();
    skipped.dispose();
  });
  test('controller without stars wakes for mood and pulse then returns to idle', () {
    final controller = FxAmbientController()..setHasAnimatedStars(false);
    expect(controller.shouldAnimate, isFalse);
    controller.setMood(FxAmbientMood.market);
    expect(controller.shouldAnimate, isTrue);
    controller.advance(1);
    expect(controller.moodColor, controller.moodTargetColor);
    expect(controller.shouldAnimate, isFalse);
    controller.pulse(.5);
    expect(controller.shouldAnimate, isTrue);
    controller.advance(1);
    expect(controller.shouldAnimate, isFalse);
    controller.dispose();
  });
}
