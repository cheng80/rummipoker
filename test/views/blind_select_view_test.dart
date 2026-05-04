import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/boss_modifier.dart';
import 'package:rummipoker/services/new_run_setup.dart';
import 'package:rummipoker/views/blind_select_view.dart';

void main() {
  testWidgets('boss constraint chip keeps long rule text out of card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: BlindSelectView(
          runSeed: 77,
          difficulty: NewRunDifficulty.standard,
        ),
      ),
    );
    await tester.pump();

    const modifier = RummiBossModifier.redDampener;
    final finder = find.text(modifier.title);

    expect(finder, findsOneWidget);
    expect(find.text(modifier.ruleText), findsNothing);
    expect(find.text(modifier.markerText), findsOneWidget);

    final text = tester.widget<Text>(finder);
    expect(text.overflow, isNull);
    expect(text.softWrap, isTrue);
  });
}
