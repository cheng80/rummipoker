import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/line_ref.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_battle_facade.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';

RummiJesterEffectBreakdown effect({
  double x = 1,
  int chips = 0,
  int mult = 0,
  int delta = 10,
}) => RummiJesterEffectBreakdown(
  jesterId: 'custom',
  displayName: 'Custom',
  chipsBonus: chips,
  multBonus: mult,
  xmultBonus: x,
  scoreDelta: delta,
);

void main() {
  test('display identity has exactly the legacy equality partitions', () {
    final samples = [
      for (final x in [
        0.0,
        1.0,
        1.001,
        1.04,
        1.05,
        1.35,
        1.36,
        1.94,
        1.96,
        2.04,
        2.06,
      ])
        for (final chips in [-1, 0, 10])
          for (final mult in [-1, 0, 2]) effect(x: x, chips: chips, mult: mult),
      effect(delta: -10),
      effect(delta: 0),
      effect(delta: 10),
    ];
    for (final left in samples) {
      for (final right in samples) {
        expect(
          left.displayIdentity == right.displayIdentity,
          left.displayToken == right.displayToken,
        );
      }
    }
  });

  test('preview preserves legacy token dedupe and rounding boundaries', () {
    final effects = [
      effect(x: 2.01),
      effect(x: 1.99),
      effect(x: 2.06),
      effect(x: 2.09),
      effect(chips: 10),
      effect(delta: 10),
      effect(mult: 2),
      effect(chips: 10, mult: 4),
      effect(x: 1.35),
      effect(x: 1.36),
    ];
    expect(effects.map((e) => e.displayToken).toSet(), {
      '점수 x2',
      '점수 x2.1',
      '+10',
      '+10%',
      '점수 x1.4',
    });
    final preview = RummiScoringPreview.fromBreakdowns(
      lines: [
        ConfirmedLineBreakdown(
          ref: LineRef.row(0),
          rank: RummiHandRank.flushFive,
          baseScore: 100,
          finalScore: 200,
          jesterBonus: 100,
          hasScoringFaceCard: false,
          effects: effects,
        ),
      ],
      expectedScore: 200,
      jesterIds: {'custom'},
    );
    expect(preview.expectedJesterEffectCount, 5);
    expect(preview.expectedScore, 200);
    expect(preview.representativeRank, RummiHandRank.flushFive);
  });
}
