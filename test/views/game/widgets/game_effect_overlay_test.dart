import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/boss_modifier.dart';
import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/line_ref.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/providers/features/rummi_poker_grid/game_session_state.dart';
import 'package:rummipoker/views/game/widgets/game_effect_overlay.dart';

void main() {
  testWidgets('보드 라인 정산 단계에서 점수 조각 연출을 띄운다', (tester) async {
    await tester.pumpWidget(
      _effectOverlayHost(
        activeSettlementStep: ScoringPresentationStep.boardLine,
        line: _line(),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('settlement-score-mote-layer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('line-confirm-sweep-layer')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 1350));
  });

  testWidgets('제약 penalty가 있는 정산 단계에서 보드 이펙트를 띄운다', (tester) async {
    await tester.pumpWidget(
      _effectOverlayHost(
        activeSettlementStep: ScoringPresentationStep.constraint,
        line: _lineWithConstraintPenalty(),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(_gameWidgetFinder(), findsOneWidget);
    expect(
      find.byKey(const ValueKey('constraint-impact-badge-layer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('constraint-impact-cell-1-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('constraint-impact-cell-1-4')),
      findsOneWidget,
    );
    expect(find.text('BOSS'), findsOneWidget);
    expect(find.text('-40%'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1350));
  });

  testWidgets('제약 penalty가 없으면 제약 단계 보드 이펙트를 띄우지 않는다', (tester) async {
    await tester.pumpWidget(
      _effectOverlayHost(
        activeSettlementStep: ScoringPresentationStep.constraint,
        line: _line(),
      ),
    );
    await tester.pump();

    expect(_gameWidgetFinder(), findsNothing);
    expect(
      find.byKey(const ValueKey('constraint-impact-badge-layer')),
      findsNothing,
    );
  });

  testWidgets('큰 final score 정산 단계에서 보드 이펙트를 띄운다', (tester) async {
    await tester.pumpWidget(
      _effectOverlayHost(
        activeSettlementStep: ScoringPresentationStep.finalScore,
        line: _line(finalScore: 150),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(_gameWidgetFinder(), findsOneWidget);
    expect(
      find.byKey(const ValueKey('large-score-burst-badge-layer')),
      findsOneWidget,
    );
    expect(find.text('+150'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1350));
  });

  testWidgets('작은 final score 정산 단계는 보드 이펙트를 띄우지 않는다', (tester) async {
    await tester.pumpWidget(
      _effectOverlayHost(
        activeSettlementStep: ScoringPresentationStep.finalScore,
        line: _line(finalScore: 70),
      ),
    );
    await tester.pump();

    expect(_gameWidgetFinder(), findsNothing);
    expect(
      find.byKey(const ValueKey('large-score-burst-badge-layer')),
      findsNothing,
    );
  });
}

Finder _gameWidgetFinder() {
  return find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString().startsWith('GameWidget<'),
  );
}

Widget _effectOverlayHost({
  required ScoringPresentationStep activeSettlementStep,
  required ConfirmedLineBreakdown line,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox.square(
          dimension: 240,
          child: GameBoardEffectOverlay(
            activeSettlementLine: line,
            activeSettlementStep: activeSettlementStep,
            settlementSequenceTick: 1,
            frameInset: 6,
            gridGap: 4,
          ),
        ),
      ),
    ),
  );
}

ConfirmedLineBreakdown _lineWithConstraintPenalty() {
  return _line(
    constraintPenalties: const [
      RummiConstraintPenaltyBreakdown(
        modifierId: 'red_dampener_v1',
        title: '빨간 타일 약화',
        ruleText: '빨간 타일이 포함된 줄 점수 40% 감소',
        markerText: '-40%',
        scoreDelta: -28,
        scoreMultiplier: 0.6,
        affectedTileColors: [TileColor.red],
      ),
    ],
  );
}

ConfirmedLineBreakdown _line({
  int finalScore = 42,
  List<RummiConstraintPenaltyBreakdown> constraintPenalties = const [],
}) {
  return ConfirmedLineBreakdown(
    ref: LineRef.row(2),
    rank: RummiHandRank.straight,
    baseScore: 70,
    finalScore: finalScore,
    jesterBonus: 0,
    hasScoringFaceCard: false,
    effects: const [],
    contributingCells: const [(2, 0), (2, 1), (2, 2), (2, 3), (2, 4)],
    constraintPenalties: constraintPenalties,
  );
}
