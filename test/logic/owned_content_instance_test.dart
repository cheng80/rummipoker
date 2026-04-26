import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/owned_content_instance.dart';

RummiJesterCard _jester({required String id, String? displayName}) {
  return RummiJesterCard(
    id: id,
    displayName: displayName ?? id,
    rarity: RummiJesterRarity.common,
    baseCost: 6,
    effectText: '',
    effectType: 'chips_bonus',
    trigger: 'onScore',
    conditionType: 'none',
    conditionValue: null,
    value: 5,
    xValue: null,
    mappedTileColors: const [],
    mappedTileNumbers: const [],
  );
}

ItemCatalog _catalog() {
  return ItemCatalog.fromJsonString('''
{
  "schemaVersion": 1,
  "catalogId": "items_test",
  "rarityWeights": {"common": 48},
  "items": [
    {
      "id": "board_scrap",
      "displayName": "Board Scrap",
      "displayNameKey": "data.items.board_scrap.displayName",
      "type": "consumable",
      "rarity": "common",
      "basePrice": 4,
      "sellPrice": 2,
      "stackable": true,
      "maxStack": 2,
      "sellable": true,
      "usableInBattle": true,
      "placement": "quickSlot",
      "slotHint": "q",
      "effectText": "Gain +1 board discard.",
      "effectTextKey": "data.items.board_scrap.effectText",
      "effect": {
        "timing": "use_battle",
        "op": "add_board_discard",
        "amount": 1,
        "consume": true
      },
      "tags": ["battle"],
      "sourceNotes": "Test fixture."
    }
  ]
}
''');
}

void main() {
  group('OwnedContentInstances', () {
    test('joins owned item entries with catalog definitions', () {
      final inventory = RunInventoryState(
        ownedItems: const [
          OwnedItemEntry(
            itemId: 'board_scrap',
            count: 2,
            placement: ItemPlacement.quickSlot,
          ),
          OwnedItemEntry(
            itemId: 'missing_item',
            count: 1,
            placement: ItemPlacement.quickSlot,
          ),
        ],
        quickSlotItemIds: const ['board_scrap'],
      );

      final instances = OwnedContentInstances.itemInstances(
        inventory: inventory,
        catalog: _catalog(),
      );

      expect(instances, hasLength(1));
      expect(instances.single.id, 'board_scrap');
      expect(instances.single.count, 2);
      expect(instances.single.displayName, 'Board Scrap');
      expect(instances.single.usableInBattle, isTrue);
    });

    test('wraps owned jesters with slot-local runtime state', () {
      final progress = RummiRunProgress.restore(
        stageIndex: 1,
        gold: 10,
        rerollCost: 5,
        ownedJesters: [_jester(id: 'egg', displayName: 'Egg')],
        shopOffers: const [],
        statefulValuesBySlot: const {0: 3},
        playedHandCounts: const {},
      );

      final instances = OwnedContentInstances.jesterInstances(progress);

      expect(instances, hasLength(1));
      expect(instances.single.slotIndex, 0);
      expect(instances.single.id, 'egg');
      expect(instances.single.displayName, 'Egg');
      expect(instances.single.stateValue, 3);
    });
  });
}
