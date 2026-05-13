import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_market_facade.dart';
import 'package:rummipoker/services/active_run_save_facade.dart';
import 'package:rummipoker/views/game/widgets/game_shop_screen.dart';

import 'game_localized_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'GameShopScreen keeps item offers visible after selling an item',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await disposeLocalizedGameWidget(tester);
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final ownedPassive = _item(
        id: 'old_passive',
        name: 'Old Passive',
        placement: 'passiveRack',
        op: 'discount_first_reroll',
        tags: const ['relic'],
      );
      final wantedPassive = _item(
        id: 'wanted_passive',
        name: 'Wanted Passive',
        placement: 'passiveRack',
        op: 'add_board_move',
        tags: const ['score'],
      );
      final replacementPassive = _item(
        id: 'replacement_passive',
        name: 'Replacement Passive',
        placement: 'passiveRack',
        op: 'add_hand_discard',
        tags: const ['discard'],
      );

      var currentMarket = RummiMarketRuntimeFacade(
        gold: 4,
        rerollCost: 5,
        maxOwnedSlots: RummiRunProgress.maxJesterSlots,
        runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
        ownedEntries: const [],
        offers: const [],
        itemOfferSlotCount: 3,
        quickSlotCapacity: RunInventoryState.defaultQuickSlotCapacity,
        itemOffers: [
          RummiMarketItemOfferView.fromItemDefinition(
            wantedPassive,
            slotIndex: 0,
            currentGold: 4,
          ),
        ],
        itemSlots: [
          RummiMarketItemSlotView.fromOwnedItem(
            slotIndex: 0,
            slotLabel: 'P1',
            entry: const OwnedItemEntry(
              itemId: 'old_passive',
              count: 1,
              placement: ItemPlacement.passiveRack,
            ),
            item: ownedPassive,
          ),
        ],
      );

      await pumpLocalizedGameWidget(
        tester,
        child: GameShopScreen(
          runSeed: 77,
          readMarketView: () => currentMarket,
          readActiveRunSaveView: () => const RummiActiveRunSaveFacade(
            schemaVersion: 2,
            activeScene: 'shop',
            sceneAlias: RummiSaveSceneAlias.market,
            currentStageIndex: 2,
            currentStationIndex: 2,
            currentRunSeed: 77,
            currentGold: 4,
            checkpoint: RummiStationCheckpointSaveView(
              stageIndex: 2,
              stationIndex: 2,
              runSeed: 77,
              gold: 4,
            ),
          ),
          onReroll: () => null,
          onBuyOffer: (_) => null,
          onBuyItemOffer: (_) => null,
          onBuyTileOffer: (_) => null,
          onUseMarketItem: (_) => null,
          onSellOwnedJester: (_) => false,
          onSellMarketItem: (item) {
            expect(item.id, 'old_passive');
            currentMarket = RummiMarketRuntimeFacade(
              gold: 6,
              rerollCost: 5,
              maxOwnedSlots: currentMarket.maxOwnedSlots,
              runtimeSnapshot: currentMarket.runtimeSnapshot,
              ownedEntries: currentMarket.ownedEntries,
              offers: currentMarket.offers,
              itemOfferSlotCount: currentMarket.itemOfferSlotCount,
              quickSlotCapacity: currentMarket.quickSlotCapacity,
              itemOffers: [
                RummiMarketItemOfferView.fromItemDefinition(
                  replacementPassive,
                  slotIndex: 0,
                  currentGold: 6,
                ),
              ],
              itemSlots: const [
                RummiMarketItemSlotView(
                  slotIndex: 0,
                  slotLabel: 'P1',
                  placement: ItemPlacement.passiveRack,
                ),
              ],
            );
            return true;
          },
          onStateChanged: () async {},
          onOpenSettings: () async {},
          onExitToTitle: () async {},
          onRestartRun: () async {},
          isDebugFixtureRun: false,
          initialItemShopTab: false,
        ),
      );

      await tester.tap(find.text('Passive'));
      await tester.pumpAndSettle();
      expect(find.text('Wanted Passive'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('market-item-slot-P1')));
      await tester.pumpAndSettle();
      expect(find.text('Wanted Passive'), findsWidgets);

      await tester.tap(find.text('판매'));
      await tester.pump(const Duration(milliseconds: 120));

      expect(find.text('Wanted Passive'), findsWidgets);
      expect(find.text('Replacement Passive'), findsNothing);
      await tester.pump(const Duration(seconds: 3));
    },
  );
}

ItemDefinition _item({
  required String id,
  required String name,
  required String placement,
  required String op,
  required List<String> tags,
}) {
  return ItemDefinition.fromJson(<String, dynamic>{
    'id': id,
    'displayName': name,
    'type': 'relic',
    'rarity': 'common',
    'basePrice': 6,
    'sellPrice': 2,
    'stackable': false,
    'maxStack': 1,
    'sellable': true,
    'usableInBattle': false,
    'placement': placement,
    'slotHint': 'passive',
    'effectText': '$name support.',
    'effect': <String, dynamic>{
      'timing': 'station_start',
      'op': op,
      'amount': 1,
      'consume': false,
    },
    'tags': tags,
    'sourceNotes': 'Test fixture.',
  });
}
