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
      expect(catalog.all.length, 91);
      expect(catalog.byType(ItemType.utility).length, 14);
      expect(catalog.byType(ItemType.consumable).length, 58);
      expect(catalog.byType(ItemType.equipment).length, 9);
      expect(catalog.byType(ItemType.passiveRelic).length, 10);
      expect(catalog.byPlacement(ItemPlacement.inventory).length, 20);
      expect(catalog.byPlacement(ItemPlacement.quickSlot).length, 52);
      expect(catalog.byPlacement(ItemPlacement.equipped).length, 9);
      expect(catalog.byPlacement(ItemPlacement.passiveRack).length, 10);

      for (final item in catalog.all) {
        expect(item.displayName, isNot(contains(RegExp('[가-힣]'))));
        expect(item.effectText, isNot(contains(RegExp('[가-힣]'))));
        expect(item.displayNameKey, 'data.items.${item.id}.displayName');
        expect(item.effectTextKey, 'data.items.${item.id}.effectText');
        expect(item.effect.timing, isNotEmpty);
        expect(item.effect.op, isNotEmpty);
      }

      expect(translationJson, contains('"리롤 칩"'));
      expect(translationJson, contains('"다음 상점 리롤 비용이 1 줄어듭니다."'));
      expect(translationJson, contains('"이동 칩"'));
      expect(translationJson, contains('"최대 손패 크기 +1."'));

      expect(catalog.findById('move_token')!.effect.op, 'add_board_move');
      expect(
        catalog.findById('reroll_token')!.effect.op,
        'discount_next_reroll',
      );
      expect(catalog.findById('reroll_token')!.effect.amount, 1);
      expect(catalog.findById('battle_pouch')!.effect.op, 'increase_hand_size');
      expect(catalog.findById('battle_pouch')!.effect.timing, 'use_battle');
      expect(
        catalog.findById('line_memory')!.effect.op,
        'add_hand_rank_progress_from_selected_line',
      );
      expect(catalog.findById('line_memory')!.usableInBattle, isTrue);
      expect(catalog.findById('cross_memory')!.effect.op, 'ritual_line_effect');
      expect(catalog.findById('cross_memory')!.effect.value('target'), 'tile');
      expect(
        catalog.findById('cross_memory')!.effect.value('ritualAction'),
        'growth_marker',
      );
      expect(catalog.findById('travel_pouch')!.effect.op, 'increase_hand_size');
      expect(catalog.findById('jester_hook')!.basePrice, 7);
      expect(catalog.findById('jester_hook')!.sellPrice, 3);
      expect(
        catalog.findById('wide_grip')!.effect.op,
        'increase_hand_size_with_discard_penalty',
      );

      final translationData =
          jsonDecode(translationJson) as Map<String, dynamic>;
      final translatedItems =
          (translationData['data'] as Map<String, dynamic>)['items']
              as Map<String, dynamic>;
      const internalTerms = [
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

    test('player-facing item data does not use voucher wording', () {
      final playerFacingText = [
        File('data/common/items_common_v1.json').readAsStringSync(),
        File('assets/translations/data/ko/items.json').readAsStringSync(),
        File('assets/translations/data/en/items.json').readAsStringSync(),
      ].join('\n');

      const blockedTerms = ['Voucher', 'voucher'];
      for (final term in blockedTerms) {
        expect(
          playerFacingText,
          isNot(contains(term)),
          reason: 'Item data must not expose "$term" wording',
        );
      }
    });

    test('catalog census docs match current catalog', () {
      final catalog = ItemCatalog.fromJsonString(
        File('data/common/items_common_v1.json').readAsStringSync(),
      );
      final currentCatalogDoc = File(
        'docs/current_system/CURRENT_CARD_CATALOG_TABLE.md',
      ).readAsStringSync();
      final activePlanDoc = File(
        'docs/planning/ACTIVE_EXECUTION_PLAN.md',
      ).readAsStringSync();
      final remainingWorkDoc = File(
        'docs/planning/POST_RITUAL_RUNTIME_REMAINING_WORK.md',
      ).readAsStringSync();
      final policyAuditDoc = File(
        'docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md',
      ).readAsStringSync();
      final runtimeMatrixDoc = File(
        'docs/planning/feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md',
      ).readAsStringSync();
      final itemContractDoc = File(
        'docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md',
      ).readAsStringSync();

      const fateActions = {
        'fate_royal_flush',
        'fate_straight_flush_high',
        'fate_straight_flush_low',
        'fate_four_kind_high',
        'fate_four_kind_low',
        'fate_full_house_high',
        'fate_full_house_low',
        'fate_flush_house',
        'fate_flush_five',
        'fate_flush_high',
        'fate_flush_low',
        'fate_straight_high',
        'fate_straight_low',
        'fate_three_kind_high',
        'fate_three_kind_low',
        'fate_two_pair_high',
      };
      final ritualItems = catalog.all
          .where((item) => item.effect.op == 'ritual_line_effect')
          .toList(growable: false);
      final fateItems = ritualItems
          .where(
            (item) => fateActions.contains(item.effect.value('ritualAction')),
          )
          .toList(growable: false);

      expect(
        currentCatalogDoc,
        contains('- Item total: ${catalog.all.length}'),
      );
      expect(
        currentCatalogDoc,
        contains('전투 보드 선 선택형 `ritual_line_effect`는 ${ritualItems.length}장'),
      );
      expect(currentCatalogDoc, contains('족보 변환형 운명 카드는 ${fateItems.length}장'));
      expect(activePlanDoc, contains('현재 item catalog ${catalog.all.length}개'));
      expect(
        activePlanDoc,
        contains('전투 보드 선 선택형 `ritual_line_effect`는 ${ritualItems.length}장'),
      );
      expect(
        remainingWorkDoc,
        contains(
          '`boss_memory`, `thin_memory`, `minor_memory`는 catalog에서 삭제된 legacy 기억 의식',
        ),
      );
      for (final doc in [policyAuditDoc, runtimeMatrixDoc, itemContractDoc]) {
        expect(doc, contains('${catalog.all.length}개'));
        expect(doc, contains('`ritual_line_effect`는 ${ritualItems.length}장'));
        expect(doc, contains('Fate 변환 ${fateItems.length}'));
      }
    });

    test('fate transform items stay rare-or-higher and expensive', () {
      final catalog = ItemCatalog.fromJsonString(
        File('data/common/items_common_v1.json').readAsStringSync(),
      );
      const fateIds = [
        'trim_rank',
        'line_pruner',
        'fate_three_kind_high',
        'color_concord',
        'step_rite',
        'rank_concord',
        'fate_full_house_low',
        'flush_house_fate',
        'flush_five_fate',
        'fate_flush_high',
        'fate_flush_low',
        'fate_straight_high',
        'fate_straight_low',
        'wild_thread',
        'off_color_rite',
        'number_mask',
      ];

      for (final id in fateIds) {
        final item = catalog.findById(id);
        expect(item, isNotNull, reason: id);
        expect(
          item!.rarity,
          isNot(anyOf(ItemRarity.common, ItemRarity.uncommon)),
          reason: '$id must not be common/uncommon in the normal market',
        );
        expect(
          item.basePrice,
          greaterThanOrEqualTo(11),
          reason: '$id must be priced as a high-impact fate item',
        );
      }

      const legendaryFateIds = [
        'number_mask',
        'flush_five_fate',
        'flush_house_fate',
        'wild_thread',
        'off_color_rite',
      ];
      for (final id in legendaryFateIds) {
        expect(catalog.findById(id)!.rarity, ItemRarity.legendary, reason: id);
      }
      expect(catalog.findById('number_mask')!.basePrice, 20);
      expect(catalog.findById('flush_house_fate')!.basePrice, 20);
      expect(catalog.findById('flush_five_fate')!.basePrice, 22);
    });

    test('ritual pool split docs match catalog groups', () {
      final catalog = ItemCatalog.fromJsonString(
        File('data/common/items_common_v1.json').readAsStringSync(),
      );
      final currentCatalogDoc = File(
        'docs/current_system/CURRENT_CARD_CATALOG_TABLE.md',
      ).readAsStringSync();
      final policyAuditDoc = File(
        'docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md',
      ).readAsStringSync();
      final runtimeMatrixDoc = File(
        'docs/planning/feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md',
      ).readAsStringSync();
      final docs = [
        currentCatalogDoc,
        policyAuditDoc,
        runtimeMatrixDoc,
      ].join('\n');

      const holdRitualIds = [
        'ritual_coupon',
        'ritual_lens',
        'line_pack_ticket',
        'seal_vendor',
        'prune_vendor',
      ];
      const deletedLegacyRitualIds = [
        'boss_memory',
        'thin_memory',
        'minor_memory',
      ];
      final activeRitualIds = catalog.all
          .where((item) => item.effect.op == 'ritual_line_effect')
          .map((item) => item.id)
          .toSet();

      expect(activeRitualIds.length, 31);
      for (final id in activeRitualIds) {
        expect(docs, contains('`$id`'), reason: '$id must be documented');
      }
      for (final id in holdRitualIds) {
        expect(catalog.findById(id), isNotNull, reason: id);
        expect(
          docs,
          contains('`$id`'),
          reason: '$id must be documented as hold/redesign',
        );
      }
      for (final id in deletedLegacyRitualIds) {
        expect(catalog.findById(id), isNull, reason: id);
        expect(
          docs,
          contains('`$id`'),
          reason: '$id must be documented as deleted legacy',
        );
      }

      expect(docs, contains('active Ritual 31'));
      expect(docs, contains('hold 마켓 보조 5종'));
      expect(docs, contains('debug 전용 0종'));
      expect(docs, contains('deleted legacy 3종'));
      expect(
        docs,
        contains('normal market 제외'),
        reason: 'hold/debug Ritual groups must be explicitly excluded',
      );
    });

    test('policy cleanup docs classify full catalog and watchlist values', () {
      final itemCatalog = ItemCatalog.fromJsonString(
        File('data/common/items_common_v1.json').readAsStringSync(),
      );
      final jesterData =
          jsonDecode(
                File(
                  'data/common/jesters_common_phase5.json',
                ).readAsStringSync(),
              )
              as List<dynamic>;
      final policyAuditDoc = File(
        'docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md',
      ).readAsStringSync();
      final currentCatalogDoc = File(
        'docs/current_system/CURRENT_CARD_CATALOG_TABLE.md',
      ).readAsStringSync();
      final docs = '$policyAuditDoc\n$currentCatalogDoc';

      final jesterIds = jesterData
          .cast<Map<String, dynamic>>()
          .map((entry) => entry['id'] as String)
          .toSet();
      const holdItemIds = {
        'ritual_coupon',
        'ritual_lens',
        'line_pack_ticket',
        'seal_vendor',
        'prune_vendor',
      };
      const deletedLegacyIds = {'boss_memory', 'thin_memory', 'minor_memory'};
      final normalItemIds = itemCatalog.all
          .map((item) => item.id)
          .where((id) => !holdItemIds.contains(id))
          .toSet();

      expect(normalItemIds.length, 86);
      expect(jesterIds.length, 43);
      expect(holdItemIds.length, 5);

      expect(docs, contains('Exposure group source of truth'));
      expect(docs, contains('normal item 86'));
      expect(docs, contains('normal Jester 43'));
      expect(docs, contains('hold item 5'));
      expect(docs, contains('debug item 0'));
      expect(docs, contains('deleted legacy 3'));
      expect(
        policyAuditDoc,
        isNot(
          contains(
            '| `Board-Line Ritual` | 보드 라인을 재료로 복제/각인/변형/압축 | 현재 catalog 0개',
          ),
        ),
        reason:
            'current policy docs must not retain the pre-Ritual baseline as current state',
      );
      expect(
        policyAuditDoc,
        contains('현재 active Ritual 31장'),
        reason:
            'classification row must point at the current active Ritual pool',
      );

      for (final id in normalItemIds) {
        expect(docs, contains('`$id`'), reason: '$id missing from policy docs');
      }
      for (final id in jesterIds) {
        expect(docs, contains('`$id`'), reason: '$id missing from policy docs');
      }
      for (final id in holdItemIds) {
        expect(
          docs,
          contains('`$id`'),
          reason: '$id missing from hold policy docs',
        );
      }
      for (final id in deletedLegacyIds) {
        expect(
          docs,
          contains('`$id`'),
          reason: '$id missing from deleted legacy policy docs',
        );
      }

      final watchlistItems = {
        'reroll_token': ('common', 5, 1, 'low-tier utility'),
        'trade_ticket': ('uncommon', 6, 3, 'market pool mutation'),
        'full_house_study': ('rare', 9, 4, 'advanced study probe'),
        'four_kind_study': ('rare', 10, 5, 'advanced study probe'),
        'straight_flush_study': ('rare', 12, 6, 'advanced study probe'),
      };
      for (final MapEntry(:key, :value) in watchlistItems.entries) {
        final item = itemCatalog.findById(key)!;
        expect(item.rarity.name, value.$1, reason: key);
        expect(item.basePrice, value.$2, reason: key);
        expect(item.sellPrice, value.$3, reason: key);
        expect(
          docs,
          contains('`$key` | ${value.$1} | ${value.$2}G | ${value.$3}G'),
          reason: '$key watchlist values must be documented',
        );
        expect(docs, contains(value.$4), reason: key);
      }

      final rideTheBus = jesterData.cast<Map<String, dynamic>>().singleWhere(
        (entry) => entry['id'] == 'ride_the_bus',
      );
      expect(rideTheBus['rarity'], 'uncommon');
      expect(rideTheBus['baseCost'], 6);
      expect(rideTheBus['effectType'], 'stateful_growth');
      expect(
        docs,
        contains('`ride_the_bus` | uncommon | 6G | stateful_growth'),
      );
      expect(docs, contains('redesign watch'));
    });

    test('legacy fate item ids resolve to canonical item ids', () {
      final catalog = ItemCatalog.fromJsonString(
        File('data/common/items_common_v1.json').readAsStringSync(),
      );

      const legacyToCanonical = {
        'risk_seal': 'fate_full_house_low',
        'anchor_seal': 'fate_flush_high',
        'echo_seal': 'fate_flush_low',
        'gold_seal_stamp': 'fate_straight_high',
        'growth_seal': 'fate_straight_low',
        'line_seal_stamp': 'fate_three_kind_high',
      };

      for (final entry in legacyToCanonical.entries) {
        expect(catalog.findById(entry.key)?.id, entry.value);
      }

      final inventory = RunInventoryState.fromJson(const {
        'ownedItems': [
          {'itemId': 'risk_seal', 'count': 1, 'placement': 'quickSlot'},
        ],
        'quickSlotItemIds': ['risk_seal'],
      });

      expect(inventory.ownedItems.single.itemId, 'fate_full_house_low');
      expect(inventory.quickSlotItemIds, ['fate_full_house_low']);
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

    test('quick slot acquisition respects dynamic slot capacity', () {
      ItemDefinition quickItem(String id) =>
          ItemDefinition.fromJson(<String, dynamic>{
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
            'usableInBattle': true,
            'placement': 'quickSlot',
            'slotHint': 'q',
            'effectText': 'Test effect.',
            'effectTextKey': 'data.items.$id.effectText',
            'effect': <String, dynamic>{
              'timing': 'use_battle',
              'op': 'add_board_discard',
              'amount': 1,
              'consume': true,
            },
            'tags': <String>['battle'],
            'sourceNotes': 'Test fixture.',
          });
      final thirdItem = quickItem('third_quick_item');
      const inventory = RunInventoryState(
        ownedItems: [
          OwnedItemEntry(
            itemId: 'board_scrap',
            count: 1,
            placement: ItemPlacement.quickSlot,
          ),
          OwnedItemEntry(
            itemId: 'peek_chip',
            count: 1,
            placement: ItemPlacement.quickSlot,
          ),
        ],
        quickSlotItemIds: ['board_scrap', 'peek_chip'],
      );

      expect(inventory.canAcquire(thirdItem), isFalse);
      expect(inventory.canAcquire(thirdItem, quickSlotCapacity: 3), isTrue);

      final expanded = inventory.withAcquiredItem(
        thirdItem,
        quickSlotCapacity: 3,
      );

      expect(expanded.quickSlotItemIds, [
        'board_scrap',
        'peek_chip',
        'third_quick_item',
      ]);
    });

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
