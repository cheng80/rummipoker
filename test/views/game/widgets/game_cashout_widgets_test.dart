import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_settlement_facade.dart';
import 'package:rummipoker/views/game/widgets/game_cashout_widgets.dart';

void main() {
  testWidgets('GameCashOutSheet shows collection feedback as lines reveal', (
    tester,
  ) async {
    final settlement = RummiSettlementRuntimeFacade(
      stageIndex: 2,
      targetScore: 400,
      currentGold: 11,
      totalGold: 9,
      entries: const [
        RummiSettlementEntryView(
          kind: RummiSettlementEntryKind.stationReward,
          leadingLabel: 'Station 2',
          description: 'Station Goal 400 달성 보상',
          gold: 5,
        ),
        RummiSettlementEntryView(
          kind: RummiSettlementEntryKind.boardDiscardReward,
          leadingLabel: '2',
          description: '남은 보드 버림 2회 x 1',
          gold: 2,
        ),
        RummiSettlementEntryView(
          kind: RummiSettlementEntryKind.handDiscardReward,
          leadingLabel: '2',
          description: '남은 손패 버림 2회 x 1',
          gold: 2,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GameCashOutSheet(settlement: settlement)),
      ),
    );

    await tester.pump(const Duration(milliseconds: 240));

    expect(find.byKey(const ValueKey('cashout-collect-badge')), findsWidgets);
    expect(find.byKey(const ValueKey('cashout-line-pulse')), findsWidgets);
    expect(find.byKey(const ValueKey('cashout-reveal-size')), findsWidgets);
    expect(find.text('+5'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
