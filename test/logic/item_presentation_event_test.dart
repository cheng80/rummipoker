import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_effect_runtime.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_presentation_event.dart';

void main() {
  group('ItemPresentationEvent helpers', () {
    test('labels next-confirm item consumption with activation timing', () {
      final item = _item(
        id: 'chip_surge',
        timing: 'next_confirm',
        op: 'chips_bonus',
        consume: true,
      );

      expect(isDelayedItemActivation(item), isTrue);
      expect(delayedItemConsumedTimingLabel(item), '소모됨 · 다음 확정에서 발동합니다.');
    });

    test('labels station-start activation result and consumption', () {
      final result = ItemUseResult.success(
        itemId: 'spare_move',
        events: const [
          ItemEffectEvent(
            kind: ItemEffectEventKind.boardMoveAdded,
            itemId: 'spare_move',
            amount: 1,
          ),
          ItemEffectEvent(
            kind: ItemEffectEventKind.itemConsumed,
            itemId: 'spare_move',
          ),
        ],
      );

      expect(itemUseResultPresentationLabel(result), '타일 이동 +1 · 소모됨');
    });

    test('labels market-buy queued effect as purchase discount', () {
      final result = ItemUseResult.success(
        itemId: 'coupon',
        events: const [
          ItemEffectEvent(
            kind: ItemEffectEventKind.marketModifierQueued,
            itemId: 'coupon',
            amount: 2,
            detail: 'market_buy:discount_next_purchase',
          ),
          ItemEffectEvent(
            kind: ItemEffectEventKind.itemConsumed,
            itemId: 'coupon',
          ),
        ],
      );

      expect(itemUseResultPresentationLabel(result), '구매가 -2G · 소모됨');
    });
  });
}

ItemDefinition _item({
  required String id,
  required String timing,
  required String op,
  bool consume = false,
}) {
  return ItemDefinition.fromJson(<String, dynamic>{
    'id': id,
    'displayName': id,
    'displayNameKey': 'data.items.$id.displayName',
    'type': 'consumable',
    'rarity': 'common',
    'basePrice': 4,
    'sellPrice': 2,
    'stackable': true,
    'maxStack': 2,
    'sellable': true,
    'usableInBattle': timing == 'use_battle',
    'placement': 'quickSlot',
    'slotHint': 'q',
    'effectText': 'Test effect.',
    'effectTextKey': 'data.items.$id.effectText',
    'effect': <String, dynamic>{
      'timing': timing,
      'op': op,
      'amount': 1,
      'consume': consume,
    },
    'tags': <String>['battle'],
    'sourceNotes': 'Test fixture.',
  });
}
