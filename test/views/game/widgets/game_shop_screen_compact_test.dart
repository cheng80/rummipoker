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

RummiJesterCard _jester({required String id, required String displayName}) {
  return RummiJesterCard(
    id: id,
    displayName: displayName,
    rarity: RummiJesterRarity.common,
    baseCost: 4,
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

ItemDefinition _itemDefinition({
  required String id,
  required String displayName,
  required String placement,
  required String effectText,
}) {
  return ItemDefinition.fromJson(<String, dynamic>{
    'id': id,
    'displayName': displayName,
    'displayNameKey': 'data.items.$id.displayName',
    'type': 'utility',
    'rarity': 'common',
    'basePrice': 3,
    'sellPrice': 1,
    'stackable': true,
    'maxStack': 3,
    'sellable': true,
    'usableInBattle': false,
    'placement': placement,
    'slotHint': 'utility',
    'effectText': effectText,
    'effectTextKey': 'data.items.$id.effectText',
    'effect': const <String, dynamic>{
      'timing': 'market_reroll',
      'op': 'free_next_reroll',
      'amount': 1,
      'consume': true,
    },
    'tags': const <String>['market', 'economy', 'discount'],
    'sourceNotes': 'Test fixture.',
  });
}

Future<void> _pumpShopScreen(
  WidgetTester tester, {
  required RummiMarketRuntimeFacade Function() readMarketView,
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
                  readActiveRunSaveView: () => const RummiActiveRunSaveFacade(
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
                      gold: 10,
                    ),
                  ),
                  onReroll: () => null,
                  onBuyOffer: (_) => null,
                  onBuyItemOffer: (_) => null,
                  onBuyTileOffer: (_) => null,
                  onUseMarketItem: (_) => null,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('compact market smoke keeps type labels readable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final offerCard = _jester(id: 'compact_card', displayName: 'Compact');
    final toolOffer = RummiMarketItemOfferView.fromItemDefinition(
      _itemDefinition(
        id: 'compact_tool',
        displayName: 'Compact Tool',
        placement: 'inventory',
        effectText: 'Preview tool effect.',
      ),
      slotIndex: 0,
      currentGold: 12,
    );
    final market = RummiMarketRuntimeFacade(
      gold: 12,
      rerollCost: 5,
      maxOwnedSlots: RummiRunProgress.maxJesterSlots,
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
      ownedEntries: const [],
      offers: [
        RummiMarketOfferView.fromShopOffer(
          RummiShopOffer(slotIndex: 0, card: offerCard, price: 4),
          currentGold: 12,
        ),
      ],
      itemOfferSlotCount: 3,
      quickSlotCapacity: RunInventoryState.defaultQuickSlotCapacity,
      itemOffers: [toolOffer],
      itemSlots: const [
        RummiMarketItemSlotView(
          slotIndex: 0,
          slotLabel: 'Q1',
          placement: ItemPlacement.quickSlot,
        ),
        RummiMarketItemSlotView(
          slotIndex: 1,
          slotLabel: 'Q2',
          placement: ItemPlacement.quickSlot,
        ),
        RummiMarketItemSlotView(
          slotIndex: 2,
          slotLabel: 'Q3',
          placement: ItemPlacement.quickSlot,
          locked: true,
        ),
        RummiMarketItemSlotView(
          slotIndex: 3,
          slotLabel: 'P1',
          placement: ItemPlacement.passiveRack,
        ),
        RummiMarketItemSlotView(
          slotIndex: 4,
          slotLabel: 'P2',
          placement: ItemPlacement.passiveRack,
          locked: true,
        ),
        RummiMarketItemSlotView(
          slotIndex: 5,
          slotLabel: 'T1',
          placement: ItemPlacement.inventory,
        ),
        RummiMarketItemSlotView(
          slotIndex: 6,
          slotLabel: 'G1',
          placement: ItemPlacement.equipped,
        ),
      ],
    );

    await _pumpShopScreen(tester, readMarketView: () => market);

    expect(find.text('Tool Slots'), findsOneWidget);
    expect(find.text('Gear Slots'), findsOneWidget);
    expect(find.text('TOOL'), findsWidgets);
    final rerollButton = find.text('리롤 5');
    final toolRerollTop = tester.getTopLeft(rerollButton).dy;

    await tester.tap(find.text('Jester / Slots'));
    await tester.pumpAndSettle();

    final jesterRerollTop = tester.getTopLeft(rerollButton).dy;
    expect(find.text('Jester Slots'), findsOneWidget);
    expect(find.text('Item Slots'), findsNothing);
    expect(find.text('Q-SLT'), findsWidgets);
    expect(find.text('PSV'), findsOneWidget);
    expect((jesterRerollTop - toolRerollTop).abs(), lessThanOrEqualTo(1));
    expect(tester.takeException(), isNull);
  });
}
