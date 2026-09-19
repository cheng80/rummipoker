import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/widgets/fx/presentation_clock.dart';

void main() {
  const tick = Duration(milliseconds: 50);

  testWidgets('pause stops time and resume continues the remaining delay', (
    tester,
  ) async {
    final clock = PresentationClock(tick: tick);
    var done = false;
    clock.delay(const Duration(milliseconds: 200)).then((_) => done = true);

    await tester.pump(const Duration(milliseconds: 100));
    clock.pause();
    await tester.pump(const Duration(milliseconds: 500));
    expect(done, isFalse);

    clock.resume();
    await tester.pump(const Duration(milliseconds: 90));
    expect(done, isFalse);
    await tester.pump(const Duration(milliseconds: 60));
    expect(done, isTrue);
  });

  testWidgets('speed multiplier shortens the wall-clock wait', (tester) async {
    var speed = 4.0;
    final clock = PresentationClock(tick: tick, speed: () => speed);
    var done = false;
    clock.delay(const Duration(milliseconds: 400)).then((_) => done = true);

    await tester.pump(const Duration(milliseconds: 90));
    expect(done, isFalse);
    await tester.pump(const Duration(milliseconds: 20));
    expect(done, isTrue);
  });

  testWidgets('instant speed returns without waiting', (tester) async {
    final clock = PresentationClock(tick: tick, speed: () => double.infinity);
    var done = false;
    clock.delay(const Duration(seconds: 3)).then((_) => done = true);
    await tester.pump();
    expect(done, isTrue);
  });

  testWidgets('hit-stop adds a short freeze before the remaining delay', (
    tester,
  ) async {
    final clock = PresentationClock(tick: tick);
    clock.hitStop(const Duration(milliseconds: 80));
    clock.hitStop(const Duration(milliseconds: 60));
    expect(clock.pendingHitStop, const Duration(milliseconds: 80));
    var done = false;
    clock.delay(const Duration(milliseconds: 100)).then((_) => done = true);

    await tester.pump(const Duration(milliseconds: 170));
    expect(done, isFalse);
    await tester.pump(const Duration(milliseconds: 20));
    expect(done, isTrue);
    expect(clock.pendingHitStop, Duration.zero);
  });

  testWidgets('dispose releases waits while paused', (tester) async {
    final clock = PresentationClock(tick: tick)..pause();
    var done = false;
    clock.delay(const Duration(seconds: 1)).then((_) => done = true);
    await tester.pump(const Duration(seconds: 2));
    expect(done, isFalse);
    clock.dispose();
    await tester.pump();
    expect(done, isTrue);
  });
}
