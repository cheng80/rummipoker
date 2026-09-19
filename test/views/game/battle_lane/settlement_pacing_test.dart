import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/views/game/game_settlement_pacing.dart';
import 'package:rummipoker/views/game/widgets/game_jester_widgets.dart';

void main() {
  test('tick pitch는 한 확정 전체에서 약 1.6%씩 오르고 상한에서 멈춘다', () {
    expect(GameSettlementPacing.tickPitch(0), 1);
    expect(GameSettlementPacing.tickPitch(10), closeTo(1.16, 1e-9));
    expect(
      GameSettlementPacing.tickPitch(1000),
      GameSettlementPacing.tickPitchMax,
    );
  });

  test('자동 가속은 긴 정산에서만 켜지고 상한이 있다', () {
    expect(GameSettlementPacing.autoAccel(0), 1);
    expect(
      GameSettlementPacing.autoAccel(GameSettlementPacing.autoAccelStartStep),
      1,
    );
    expect(
      GameSettlementPacing.autoAccel(
        GameSettlementPacing.autoAccelStartStep + 2,
      ),
      greaterThan(1),
    );
    expect(
      GameSettlementPacing.autoAccel(500),
      GameSettlementPacing.autoAccelMax,
    );
  });

  test('점수 등급은 목표 대비 비율로 4단계다', () {
    expect(GameSettlementPacing.grade(5, 100), 0);
    expect(GameSettlementPacing.grade(10, 100), 1);
    expect(GameSettlementPacing.grade(25, 100), 2);
    expect(GameSettlementPacing.grade(80, 100), 3);
    // 같은 줄 점수라도 목표가 크면 등급이 낮다.
    expect(GameSettlementPacing.grade(120, 2000), 0);
  });

  test('목표 달성 예고는 남은 목표를 넘을 때만 켜지고 초과 폭에 따라 커진다', () {
    expect(GameSettlementPacing.goalHeat(expectedScore: 50, remaining: 100), 0);
    expect(GameSettlementPacing.goalHeat(expectedScore: 50, remaining: 0), 0);
    final exact = GameSettlementPacing.goalHeat(
      expectedScore: 100,
      remaining: 100,
    );
    final over = GameSettlementPacing.goalHeat(
      expectedScore: 250,
      remaining: 100,
    );
    expect(exact, greaterThan(0));
    expect(over, greaterThan(exact));
    expect(
      GameSettlementPacing.goalHeat(expectedScore: 100000, remaining: 100),
      1,
    );
  });

  test('callout 자리는 5×5 보드의 모든 줄에서 채점 칸을 피한다', () {
    final lines = <List<(int, int)>>[
      for (var r = 0; r < 5; r++) [for (var c = 0; c < 5; c++) (r, c)],
      for (var c = 0; c < 5; c++) [for (var r = 0; r < 5; r++) (r, c)],
      [for (var i = 0; i < 5; i++) (i, i)],
      [for (var i = 0; i < 5; i++) (i, 4 - i)],
    ];
    for (final cells in lines) {
      final slot = boardCalloutSlotFor(cells);
      for (final (row, col) in cells) {
        final inBand = slot.top ? row < 2 : row >= 3;
        final inCols = switch (slot.horizontal) {
          BoardCalloutHorizontal.full => true,
          BoardCalloutHorizontal.left => col < 2,
          BoardCalloutHorizontal.right => col >= 3,
        };
        expect(inBand && inCols, isFalse, reason: '$cells → ${slot.name}');
      }
    }
    // 첫 줄은 아래, 마지막 줄은 위.
    expect(
      boardCalloutSlotFor([for (var c = 0; c < 5; c++) (0, c)]).top,
      false,
    );
    expect(boardCalloutSlotFor([for (var c = 0; c < 5; c++) (4, c)]).top, true);
  });

  test('Jester 발동 모션은 효과 유형 3종으로만 나뉜다', () {
    RummiJesterEffectBreakdown effect({
      int chips = 0,
      int mult = 0,
      double xmult = 1,
    }) => RummiJesterEffectBreakdown(
      jesterId: 'j',
      displayName: 'J',
      chipsBonus: chips,
      multBonus: mult,
      xmultBonus: xmult,
      scoreDelta: 1,
    );
    expect(GameJesterFireKind.of(effect(chips: 30)), GameJesterFireKind.stamp);
    expect(GameJesterFireKind.of(effect(mult: 4)), GameJesterFireKind.inflate);
    expect(GameJesterFireKind.of(effect(xmult: 2)), GameJesterFireKind.spin);
  });
}
