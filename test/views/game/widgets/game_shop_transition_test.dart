import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/views/game/widgets/game_market_feedback_widgets.dart';
import 'package:rummipoker/widgets/fx/motion_policy.dart';

void main() {
  tearDown(() => MotionPolicy.debugReduceMotionOverride = null);

  testWidgets('outgoing offer cannot receive taps during page transition', (
    tester,
  ) async {
    MotionPolicy.debugReduceMotionOverride = false;
    var selected = 0;
    Widget page(bool old) => MaterialApp(
      home: Center(
        child: SizedBox(
          width: 300,
          height: 100,
          child: MarketDirectionalSwitcher(
            direction: 1,
            child: Row(
              key: ValueKey(old),
              children: List.generate(
                old ? 3 : 1,
                (i) => SizedBox(
                  width: 100,
                  height: 100,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => selected++,
                    child: Text('offer-$i'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(page(true));
    final oldPosition = tester.getCenter(find.text('offer-2'));
    await tester.pumpWidget(page(false));
    await tester.tapAt(oldPosition);
    expect(selected, 0);
    await tester.pumpAndSettle();
  });
}
