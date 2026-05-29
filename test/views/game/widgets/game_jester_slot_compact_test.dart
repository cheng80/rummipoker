import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/views/game/widgets/game_jester_widgets.dart';

void main() {
  testWidgets('compact jester slot fits the battle slot frame', (tester) async {
    final card = RummiJesterCard(
      id: 'jolly_jester',
      displayName: 'Jolly Jester',
      rarity: RummiJesterRarity.common,
      baseCost: 3,
      effectText: '',
      effectType: 'chips_bonus',
      trigger: 'onScore',
      conditionType: 'none',
      conditionValue: null,
      value: 10,
      xValue: null,
      mappedTileColors: const [],
      mappedTileNumbers: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: kBattleItemSlotWidth,
              height: kBattleItemSlotHeight,
              child: GameJesterSlot(
                card: card,
                runtimeValueText: null,
                extended: false,
                activeEffect: const RummiJesterEffectBreakdown(
                  jesterId: 'jolly_jester',
                  displayName: 'Jolly Jester',
                  chipsBonus: 10,
                  multBonus: 0,
                  xmultBonus: 1,
                  scoreDelta: 10,
                ),
                settlementSequenceTick: 1,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
