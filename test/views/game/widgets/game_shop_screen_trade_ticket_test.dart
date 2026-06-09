import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_market_facade.dart';
import 'package:rummipoker/resources/item_translation_scope.dart';
import 'package:rummipoker/resources/jester_translation_scope.dart';
import 'package:rummipoker/services/active_run_save_facade.dart';
import 'package:rummipoker/views/game/widgets/game_shop_screen.dart';

Future<void> _pumpShopScreen(
  WidgetTester tester, {
  required RummiMarketRuntimeFacade Function() readMarketView,
  required RummiActiveRunSaveFacade Function() readActiveRunSaveView,
  required String? Function(RummiMarketOfferView offer) onBuyOffer,
  required String? Function(ItemDefinition item) onUseMarketItem,
}) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ko'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ko'),
      startLocale: const Locale('ko'),
      saveLocale: false,
      child: Builder(
        builder: (context) {
          return MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: JesterTranslationScope(
              child: ItemTranslationScope(
                child: GameShopScreen(
                  key: UniqueKey(),
                  runSeed: 77,
                  readMarketView: readMarketView,
                  readActiveRunSaveView: readActiveRunSaveView,
                  onReroll: () => null,
                  onRerollItemOffers: (_) => null,
                  onBuyOffer: onBuyOffer,
                  onBuyItemOffer: (_) => null,
                  onBuyTileOffer: (_) => null,
                  onUseMarketItem: onUseMarketItem,
                  onSellOwnedJester: (_) => false,
                  onSellMarketItem: (_) => false,
                  onStateChanged: () async {},
                  onOpenSettings: () async {},
                  onExitToTitle: () async {},
                  onRestartRun: () async {},
                  isDebugFixtureRun: false,
                  initialItemShopTab: true,
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ItemDefinition _item({
  required String id,
  required String displayName,
  required Map<String, dynamic> effect,
}) {
  return ItemDefinition.fromJson(<String, dynamic>{
    'id': id,
    'displayName': displayName,
    'displayNameKey': 'data.items.$id.displayName',
    'type': 'utility',
    'rarity': 'common',
    'basePrice': 4,
    'sellPrice': 2,
    'stackable': true,
    'maxStack': 3,
    'sellable': true,
    'usableInBattle': false,
    'placement': 'inventory',
    'slotHint': 'utility',
    'effectText': 'Test fixture.',
    'effectTextKey': 'data.items.$id.effectText',
    'effect': effect,
    'tags': <String>['market'],
    'sourceNotes': 'Test fixture.',
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('trade ticket use shows source target result presentation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final tradeTicket = _item(
      id: 'trade_ticket',
      displayName: 'Trade Ticket',
      effect: const <String, dynamic>{
        'timing': 'use_market',
        'op': 'reroll_item_offers_only',
        'consume': true,
      },
    );
    final oldOfferItem = _item(
      id: 'old_tool',
      displayName: 'Old Tool',
      effect: const <String, dynamic>{
        'timing': 'use_market',
        'op': 'gain_gold',
        'amount': 1,
        'consume': true,
      },
    );
    final newOfferItem = _item(
      id: 'new_tool',
      displayName: 'New Tool',
      effect: const <String, dynamic>{
        'timing': 'use_market',
        'op': 'gain_gold',
        'amount': 1,
        'consume': true,
      },
    );

    RummiMarketRuntimeFacade marketWith({
      required List<RummiMarketItemOfferView> itemOffers,
      required List<RummiMarketItemSlotView> itemSlots,
    }) {
      return RummiMarketRuntimeFacade(
        gold: 12,
        rerollCost: 5,
        maxOwnedSlots: RummiRunProgress.maxJesterSlots,
        runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
        ownedEntries: const [],
        offers: const [],
        itemOfferSlotCount: 3,
        quickSlotCapacity: RunInventoryState.defaultQuickSlotCapacity,
        itemOffers: itemOffers,
        itemSlots: itemSlots,
      );
    }

    var currentMarket = marketWith(
      itemOffers: [
        RummiMarketItemOfferView.fromItemDefinition(
          oldOfferItem,
          slotIndex: 0,
          currentGold: 12,
        ),
      ],
      itemSlots: [
        RummiMarketItemSlotView.fromOwnedItem(
          slotIndex: 0,
          slotLabel: 'T1',
          entry: const OwnedItemEntry(
            itemId: 'trade_ticket',
            count: 1,
            placement: ItemPlacement.inventory,
          ),
          item: tradeTicket,
        ),
        const RummiMarketItemSlotView(
          slotIndex: 1,
          slotLabel: 'T2',
          placement: ItemPlacement.inventory,
        ),
        const RummiMarketItemSlotView(
          slotIndex: 2,
          slotLabel: 'T3',
          placement: ItemPlacement.inventory,
        ),
        const RummiMarketItemSlotView(
          slotIndex: 3,
          slotLabel: 'G1',
          placement: ItemPlacement.equipped,
        ),
        const RummiMarketItemSlotView(
          slotIndex: 4,
          slotLabel: 'G2',
          placement: ItemPlacement.equipped,
        ),
      ],
    );
    const currentSave = RummiActiveRunSaveFacade(
      schemaVersion: 2,
      activeScene: 'shop',
      sceneAlias: RummiSaveSceneAlias.market,
      currentStageIndex: 2,
      currentStationIndex: 2,
      currentRunSeed: 77,
      currentGold: 12,
      checkpoint: RummiStationCheckpointSaveView(
        stageIndex: 2,
        stationIndex: 2,
        runSeed: 77,
        gold: 12,
      ),
    );
    String? usedItemId;

    await _pumpShopScreen(
      tester,
      readMarketView: () => currentMarket,
      readActiveRunSaveView: () => currentSave,
      onBuyOffer: (_) => null,
      onUseMarketItem: (item) {
        usedItemId = item.id;
        currentMarket = marketWith(
          itemOffers: [
            RummiMarketItemOfferView.fromItemDefinition(
              newOfferItem,
              slotIndex: 0,
              currentGold: 12,
            ),
          ],
          itemSlots: const [
            RummiMarketItemSlotView(
              slotIndex: 0,
              slotLabel: 'T1',
              placement: ItemPlacement.inventory,
            ),
          ],
        );
        return null;
      },
    );

    final tradeTicketSlot = find.byKey(
      const ValueKey('market-item-slot-T1'),
      skipOffstage: false,
    );
    expect(tradeTicketSlot, findsOneWidget);
    await tester.ensureVisible(tradeTicketSlot);
    await tester.tap(tradeTicketSlot);
    await tester.pumpAndSettle();
    await tester.tap(find.text('사용'));
    await tester.pump(const Duration(milliseconds: 120));

    expect(usedItemId, 'trade_ticket');
    expect(find.byKey(const ValueKey('market-effect-source')), findsOneWidget);
    expect(find.text('Item 후보 영역'), findsOneWidget);
    expect(find.text('후보 교체 완료'), findsOneWidget);
    expect(find.text('아이템 티켓'), findsWidgets);
    expect(find.text('Item 후보 교체'), findsOneWidget);
    expect(find.text('New Tool'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 1900));
    expect(find.byKey(const ValueKey('market-effect-source')), findsNothing);
  });
}
