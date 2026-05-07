import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_settlement_facade.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_state.dart';
import 'package:rummipoker/utils/common_ui.dart';
import 'package:rummipoker/views/game/widgets/game_cashout_widgets.dart';

void main() {
  testWidgets(
    'GameStageClearOverlay shows spark field only during station clear',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameStageClearOverlay(
              phase: GameStageFlowPhase.cleared,
              stageIndex: 2,
              scoreAdded: 150,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('stage-clear-spark-field')),
        findsOneWidget,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameStageClearOverlay(
              phase: GameStageFlowPhase.settlement,
              stageIndex: 2,
              scoreAdded: 150,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('stage-clear-spark-field')),
        findsNothing,
      );
    },
  );

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

    expect(find.byType(AnimatedSize), findsNothing);
    final initialSheetHeight = tester
        .getSize(find.byKey(const ValueKey('cashout-sheet-frame')))
        .height;
    final initialSheetTop = tester
        .getTopLeft(find.byKey(const ValueKey('cashout-sheet-frame')))
        .dy;

    await tester.pump(const Duration(milliseconds: 240));

    expect(find.byKey(const ValueKey('cashout-collect-badge')), findsWidgets);
    expect(find.byKey(const ValueKey('cashout-coin-burst')), findsWidgets);
    expect(find.byKey(const ValueKey('cashout-line-pulse')), findsWidgets);
    expect(find.text('+5'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    final finalSheetHeight = tester
        .getSize(find.byKey(const ValueKey('cashout-sheet-frame')))
        .height;
    final finalSheetTop = tester
        .getTopLeft(find.byKey(const ValueKey('cashout-sheet-frame')))
        .dy;
    expect(finalSheetHeight, initialSheetHeight);
    expect(finalSheetTop, initialSheetTop);

    final totalGoldText = tester.widget<Text>(
      find.byKey(const ValueKey('cashout-total-gold-value')),
    );
    expect(totalGoldText.data, '+9G');
    expect(totalGoldText.style?.fontSize, greaterThanOrEqualTo(28));
    expect(totalGoldText.style?.fontWeight, FontWeight.w900);

    final currentGoldText = tester.widget<Text>(
      find.byKey(const ValueKey('cashout-current-gold-value')),
    );
    expect(currentGoldText.data, '11G');
    expect(currentGoldText.style?.fontSize, greaterThanOrEqualTo(20));
    expect(currentGoldText.style?.fontWeight, FontWeight.w900);

    final marketButton = find.widgetWithText(GameChromeButton, 'Market으로');
    expect(marketButton, findsOneWidget);
    expect(tester.getSize(marketButton).height, greaterThanOrEqualTo(48));
    final marketButtonText = tester.widget<Text>(find.text('Market으로'));
    expect(marketButtonText.style?.fontWeight, FontWeight.w900);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('GameCashOutSheet can close a final run with memory card reward', (
    tester,
  ) async {
    final settlement = RummiSettlementRuntimeFacade(
      stageIndex: 8,
      targetScore: 2600,
      currentGold: 7,
      totalGold: 11,
      entries: const [
        RummiSettlementEntryView(
          kind: RummiSettlementEntryKind.stationReward,
          leadingLabel: 'Station 8',
          description: 'Station Goal 2600 달성 보상',
          gold: 7,
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
        home: Scaffold(
          body: GameCashOutSheet(
            settlement: settlement,
            completesRun: true,
            insightReward: 36,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 2));

    expect(find.text('기억 카드 획득'), findsOneWidget);
    expect(find.textContaining('Insight'), findsNothing);
    expect(find.widgetWithText(GameChromeButton, '계속 진행'), findsOneWidget);
    expect(find.widgetWithText(GameChromeButton, '런 완료'), findsOneWidget);
    expect(find.text('Market으로'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
