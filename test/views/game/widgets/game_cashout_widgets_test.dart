import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_settlement_facade.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_state.dart';
import 'package:rummipoker/utils/common_ui.dart';
import 'package:rummipoker/views/game/widgets/game_cashout_widgets.dart';
import 'package:rummipoker/views/game/widgets/game_options_dialog.dart';

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

  testWidgets('GameCashOutSheet blocks inherited text underline decoration', (
    tester,
  ) async {
    final settlement = RummiSettlementRuntimeFacade(
      stageIndex: 1,
      targetScore: 240,
      currentGold: 19,
      totalGold: 19,
      entries: const [
        RummiSettlementEntryView(
          kind: RummiSettlementEntryKind.stationReward,
          leadingLabel: 'Station 1',
          description: 'Station Goal 240 달성 보상',
          gold: 4,
        ),
        RummiSettlementEntryView(
          kind: RummiSettlementEntryKind.boardDiscardReward,
          leadingLabel: '4',
          description: '남은 보드 버림 4회 x 2',
          gold: 8,
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
          body: DefaultTextStyle(
            style: const TextStyle(
              decoration: TextDecoration.underline,
              decorationColor: Colors.yellow,
            ),
            child: GameCashOutSheet(settlement: settlement),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 240));

    final cashOutDefaultStyles = tester.widgetList<DefaultTextStyle>(
      find.ancestor(
        of: find.byKey(const ValueKey('cashout-sheet-frame')),
        matching: find.byType(DefaultTextStyle),
      ),
    );
    expect(
      cashOutDefaultStyles.any(
        (style) => style.style.decoration == TextDecoration.none,
      ),
      isTrue,
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('GameCashOutSheet auto close does not pop a covering dialog', (
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
    Future<GameCashOutAction?>? cashOutFuture;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Column(
                children: [
                  TextButton(
                    onPressed: () {
                      cashOutFuture = showGeneralDialog<GameCashOutAction>(
                        context: context,
                        barrierDismissible: false,
                        pageBuilder: (_, _, _) => GameCashOutSheet(
                          settlement: settlement,
                          autoEnterMarketOnLoad: true,
                        ),
                      );
                    },
                    child: const Text('cashout'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('cashout'));
    await tester.pump();
    final cashOutContext = tester.element(find.byType(GameCashOutSheet));
    showDialog<GameOptionsCloseAction>(
      context: cashOutContext,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('covering-options-dialog'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(GameOptionsCloseAction.resumeGame),
            child: const Text('close options'),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.byKey(const ValueKey('covering-options-dialog')),
      findsOneWidget,
    );

    await tester.tap(find.text('close options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Market으로'));
    await tester.pumpAndSettle();

    expect(await cashOutFuture, GameCashOutAction.enterMarket);
  });

  testWidgets('GameCashOutSheet shows boss deck tile reward as a tile face', (
    tester,
  ) async {
    final settlement = RummiSettlementRuntimeFacade(
      stageIndex: 2,
      targetScore: 480,
      currentGold: 11,
      totalGold: 8,
      entries: const [
        RummiSettlementEntryView(
          kind: RummiSettlementEntryKind.stationReward,
          leadingLabel: 'Station 2',
          description: 'Station Goal 480 달성 보상',
          gold: 8,
        ),
        RummiSettlementEntryView(
          kind: RummiSettlementEntryKind.boardDiscardReward,
          leadingLabel: '0',
          description: '남은 보드 버림 0회 x 3',
          gold: 0,
        ),
        RummiSettlementEntryView(
          kind: RummiSettlementEntryKind.handDiscardReward,
          leadingLabel: '0',
          description: '남은 손패 버림 0회 x 2',
          gold: 0,
        ),
        RummiSettlementEntryView(
          kind: RummiSettlementEntryKind.deckTileReward,
          leadingLabel: 'Tile',
          description: '보스 클리어 보상 - 다음 전투 덱에 추가',
          gold: 0,
          tile: Tile(color: TileColor.red, number: 9, id: 1),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GameCashOutSheet(settlement: settlement)),
      ),
    );

    await tester.pump(const Duration(seconds: 2));

    expect(find.text('덱 타일 보상'), findsOneWidget);
    expect(find.textContaining('다음 전투 덱에 추가'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cashout-deck-tile-reward-face')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'GameCashOutSheet can close a final run with memory card reward',
    (tester) async {
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
      expect(find.textContaining('S8 이후는 무한 도전입니다'), findsOneWidget);
      expect(find.widgetWithText(GameChromeButton, '무한 도전 진입'), findsOneWidget);
      expect(find.widgetWithText(GameChromeButton, '런 완료'), findsOneWidget);
      expect(find.text('Market으로'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
