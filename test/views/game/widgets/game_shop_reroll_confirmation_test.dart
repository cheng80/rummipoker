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

RummiJesterCard _jester() {
  return const RummiJesterCard(
    id: 'jester_offer',
    displayName: 'Jester Offer',
    rarity: RummiJesterRarity.common,
    baseCost: 4,
    effectText: '',
    effectType: 'chips_bonus',
    trigger: 'onScore',
    conditionType: 'none',
    conditionValue: null,
    value: 5,
    xValue: null,
    mappedTileColors: [],
    mappedTileNumbers: [],
  );
}

ItemDefinition _quickSlotItem() {
  return ItemDefinition.fromJson(const <String, dynamic>{
    'id': 'board_scrap',
    'displayName': 'Board Scrap',
    'displayNameKey': 'data.items.board_scrap.displayName',
    'type': 'consumable',
    'rarity': 'common',
    'basePrice': 3,
    'sellPrice': 1,
    'stackable': true,
    'maxStack': 3,
    'sellable': true,
    'usableInBattle': true,
    'placement': 'quickSlot',
    'slotHint': 'q',
    'effectText': 'Test effect.',
    'effectTextKey': 'data.items.board_scrap.effectText',
    'effect': <String, dynamic>{
      'timing': 'use_battle',
      'op': 'add_board_discard',
      'amount': 1,
      'consume': true,
    },
    'tags': <String>['test'],
    'sourceNotes': 'Test fixture.',
  });
}

Future<void> _pumpShopScreen(WidgetTester tester) async {
  final jester = _jester();
  final quickSlotItem = _quickSlotItem();
  final market = RummiMarketRuntimeFacade(
    gold: 20,
    rerollCost: 5,
    maxOwnedSlots: RummiRunProgress.maxJesterSlots,
    runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    ownedEntries: const [],
    offers: [
      RummiMarketOfferView.fromShopOffer(
        RummiShopOffer(slotIndex: 0, card: jester, price: 4),
        currentGold: 20,
      ),
    ],
    itemOfferSlotCount: 3,
    quickSlotCapacity: RunInventoryState.defaultQuickSlotCapacity,
    itemOffers: [
      RummiMarketItemOfferView.fromItemDefinition(
        quickSlotItem,
        slotIndex: 0,
        currentGold: 20,
      ),
    ],
    itemSlots: const [
      RummiMarketItemSlotView(
        slotIndex: 0,
        slotLabel: 'Q1',
        placement: ItemPlacement.quickSlot,
      ),
    ],
  );
  const save = RummiActiveRunSaveFacade(
    schemaVersion: 2,
    activeScene: 'shop',
    sceneAlias: RummiSaveSceneAlias.market,
    currentStageIndex: 1,
    currentStationIndex: 1,
    currentRunSeed: 77,
    currentGold: 20,
    checkpoint: RummiStationCheckpointSaveView(
      stageIndex: 1,
      stationIndex: 1,
      runSeed: 77,
      gold: 20,
    ),
  );

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
                  runSeed: 77,
                  readMarketView: () => market,
                  readActiveRunSaveView: () => save,
                  onReroll: () => null,
                  onRerollItemOffers: (_) => null,
                  onBuyOffer: (_) => null,
                  onBuyItemOffer: (_) => null,
                  onUseMarketItem: (_) => null,
                  onSellOwnedJester: (_) => false,
                  onSellMarketItem: (_) => false,
                  onStateChanged: () async {},
                  onOpenSettings: () async {},
                  onExitToTitle: () async {},
                  onRestartRun: () async {},
                  isDebugFixtureRun: false,
                  initialItemShopTab: false,
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

  testWidgets('reroll confirmation names the current offer lane', (
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

    await _pumpShopScreen(tester);

    await tester.tap(find.text('Jester / Slots'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Q-Slot'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('리롤 5'));
    await tester.pumpAndSettle();

    expect(find.text('Q-Slot 후보를 리롤할까요?'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jester'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('리롤 5'));
    await tester.pumpAndSettle();

    expect(find.text('Jester 후보를 리롤할까요?'), findsOneWidget);
  });
}
