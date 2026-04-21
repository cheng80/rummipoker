import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';

void main() {
  group('ItemCatalog', () {
    test('parses item definitions and exposes lookup helpers', () {
      final catalog = ItemCatalog.fromJsonString('''
{
  "schemaVersion": 1,
  "catalogId": "items_test",
  "rarityWeights": {
    "common": 48,
    "rare": 15
  },
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
      "effectText": "Gain +1 board discard for this Station.",
      "effectTextKey": "data.items.board_scrap.effectText",
      "effect": {
        "timing": "use_battle",
        "op": "add_board_discard",
        "amount": 1,
        "capIncrease": false,
        "consume": true
      },
      "tags": ["battle", "discard", "safety"],
      "sourceNotes": "Test fixture."
    }
  ]
}
''');

      expect(catalog.schemaVersion, 1);
      expect(catalog.catalogId, 'items_test');
      expect(catalog.rarityWeights[ItemRarity.common], 48);

      final item = catalog.findById('board_scrap');
      expect(item, isNotNull);
      expect(item!.displayName, 'Board Scrap');
      expect(item.displayNameKey, 'data.items.board_scrap.displayName');
      expect(item.type, ItemType.consumable);
      expect(item.rarity, ItemRarity.common);
      expect(item.basePrice, 4);
      expect(item.sellPrice, 2);
      expect(item.stackable, isTrue);
      expect(item.maxStack, 2);
      expect(item.usableInBattle, isTrue);
      expect(item.placement, ItemPlacement.quickSlot);
      expect(item.effect.timing, 'use_battle');
      expect(item.effect.op, 'add_board_discard');
      expect(item.effect.amount, 1);
      expect(item.effect.consume, isTrue);
      expect(item.effect.value('capIncrease'), isFalse);
      expect(item.tags, ['battle', 'discard', 'safety']);
      expect(catalog.byType(ItemType.consumable), [item]);
      expect(catalog.byPlacement(ItemPlacement.quickSlot), [item]);
    });

    test('v1 catalog keeps Korean text in localization data only', () {
      final catalogJson = File(
        'data/common/items_common_v1.json',
      ).readAsStringSync();
      final translationJson = File(
        'assets/translations/data/ko/items.json',
      ).readAsStringSync();

      final catalog = ItemCatalog.fromJsonString(catalogJson);

      expect(catalog.schemaVersion, 1);
      expect(catalog.catalogId, 'items_common_v1');
      expect(catalog.all.length, 41);
      expect(catalog.byType(ItemType.utility).length, 7);
      expect(catalog.byType(ItemType.consumable).length, 16);
      expect(catalog.byType(ItemType.equipment).length, 8);
      expect(catalog.byType(ItemType.passiveRelic).length, 10);
      expect(catalog.byPlacement(ItemPlacement.inventory).length, 7);
      expect(catalog.byPlacement(ItemPlacement.quickSlot).length, 16);
      expect(catalog.byPlacement(ItemPlacement.equipped).length, 8);
      expect(catalog.byPlacement(ItemPlacement.passiveRack).length, 10);

      for (final item in catalog.all) {
        expect(item.displayName, isNot(contains(RegExp('[가-힣]'))));
        expect(item.effectText, isNot(contains(RegExp('[가-힣]'))));
        expect(item.displayNameKey, 'data.items.${item.id}.displayName');
        expect(item.effectTextKey, 'data.items.${item.id}.effectText');
        expect(item.effect.timing, isNotEmpty);
        expect(item.effect.op, isNotEmpty);
      }

      expect(translationJson, contains('"리롤 토큰"'));
      expect(translationJson, contains('"다음 상점 리롤 비용이 1 줄어듭니다."'));

      final translationData =
          jsonDecode(translationJson) as Map<String, dynamic>;
      final translatedItems =
          (translationData['data'] as Map<String, dynamic>)['items']
              as Map<String, dynamic>;
      const internalTerms = [
        'Market',
        'Gold',
        'Chips',
        'Mult',
        'Item Shop',
        'Jester Shop',
        'quick slot',
        'Rare Item',
        'Boss Blind',
        'overlap',
        'cap',
        'scoring',
      ];
      for (final entry in translatedItems.entries) {
        final effectText =
            (entry.value as Map<String, dynamic>)['effectText'] as String;
        for (final term in internalTerms) {
          expect(
            effectText,
            isNot(contains(term)),
            reason: '${entry.key} effectText exposes internal term "$term"',
          );
        }
      }
    });

    test('owned item inventory state roundtrips storage shape', () {
      const inventory = RunInventoryState(
        ownedItems: [
          OwnedItemEntry(
            itemId: 'board_scrap',
            count: 2,
            placement: ItemPlacement.quickSlot,
          ),
          OwnedItemEntry(
            itemId: 'market_compass',
            count: 1,
            placement: ItemPlacement.passiveRack,
            isActive: false,
          ),
        ],
        equippedItemIds: ['discard_glove'],
        passiveRelicIds: ['market_compass'],
        quickSlotItemIds: ['board_scrap'],
      );

      final restored = RunInventoryState.fromJson(inventory.toJson());

      expect(restored.isEmpty, isFalse);
      expect(restored.ownedItems.length, 2);
      expect(restored.ownedItems.first.itemId, 'board_scrap');
      expect(restored.ownedItems.first.count, 2);
      expect(restored.ownedItems.first.placement, ItemPlacement.quickSlot);
      expect(restored.ownedItems.first.isActive, isTrue);
      expect(restored.ownedItems.last.itemId, 'market_compass');
      expect(restored.ownedItems.last.placement, ItemPlacement.passiveRack);
      expect(restored.ownedItems.last.isActive, isFalse);
      expect(restored.equippedItemIds, ['discard_glove']);
      expect(restored.passiveRelicIds, ['market_compass']);
      expect(restored.quickSlotItemIds, ['board_scrap']);
    });

    test(
      'owned item inventory acquires items by placement and stack limit',
      () {
        final item = ItemDefinition.fromJson(const <String, dynamic>{
          'id': 'board_scrap',
          'displayName': 'Board Scrap',
          'displayNameKey': 'data.items.board_scrap.displayName',
          'type': 'consumable',
          'rarity': 'common',
          'basePrice': 4,
          'sellPrice': 2,
          'stackable': true,
          'maxStack': 2,
          'sellable': true,
          'usableInBattle': true,
          'placement': 'quickSlot',
          'slotHint': 'q',
          'effectText': 'Gain +1 board discard for this Station.',
          'effectTextKey': 'data.items.board_scrap.effectText',
          'effect': <String, dynamic>{
            'timing': 'use_battle',
            'op': 'add_board_discard',
            'amount': 1,
            'consume': true,
          },
          'tags': <String>['battle', 'discard', 'safety'],
          'sourceNotes': 'Test fixture.',
        });

        final first = const RunInventoryState().withAcquiredItem(item);
        final second = first.withAcquiredItem(item);

        expect(first.ownedItems.single.count, 1);
        expect(first.quickSlotItemIds, ['board_scrap']);
        expect(second.ownedItems.single.count, 2);
        expect(second.quickSlotItemIds, ['board_scrap']);
        expect(second.canAcquire(item), isFalse);
        expect(second.withAcquiredItem(item).ownedItems.single.count, 2);
      },
    );

    test('owned item inventory consumes stacks and removes empty slot ids', () {
      const inventory = RunInventoryState(
        ownedItems: [
          OwnedItemEntry(
            itemId: 'board_scrap',
            count: 2,
            placement: ItemPlacement.quickSlot,
          ),
        ],
        quickSlotItemIds: ['board_scrap'],
      );

      final oneLeft = inventory.withConsumedItem('board_scrap');
      final empty = oneLeft.withConsumedItem('board_scrap');

      expect(oneLeft.ownedItems.single.count, 1);
      expect(oneLeft.quickSlotItemIds, ['board_scrap']);
      expect(empty.ownedItems, isEmpty);
      expect(empty.quickSlotItemIds, isEmpty);
    });
  });
}
