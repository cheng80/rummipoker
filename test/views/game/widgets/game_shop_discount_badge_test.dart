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

  testWidgets('GameShopScreen marks discounted jester offer prices', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() async {
      await disposeLocalizedGameWidget(tester);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final offerCard = _jester(id: 'discounted_card', displayName: 'D');
    final market = RummiMarketRuntimeFacade(
      gold: 3,
      rerollCost: 5,
      maxOwnedSlots: RummiRunProgress.maxJesterSlots,
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
      ownedEntries: const [],
      offers: [
        RummiMarketOfferView.fromShopOffer(
          RummiShopOffer(slotIndex: 0, card: offerCard, price: 3),
          currentGold: 3,
          price: 3,
          originalPrice: 7,
        ),
      ],
      itemOfferSlotCount: 3,
      quickSlotCapacity: RunInventoryState.defaultQuickSlotCapacity,
    );

    await pumpLocalizedGameWidget(
      tester,
      child: GameShopScreen(
        runSeed: 77,
        readMarketView: () => market,
        readActiveRunSaveView: () => const RummiActiveRunSaveFacade(
          schemaVersion: 2,
          activeScene: 'shop',
          sceneAlias: RummiSaveSceneAlias.market,
          currentStageIndex: 2,
          currentStationIndex: 2,
          currentRunSeed: 77,
          currentGold: 3,
          checkpoint: RummiStationCheckpointSaveView(
            stageIndex: 2,
            stationIndex: 2,
            runSeed: 77,
            gold: 3,
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
        initialItemShopTab: false,
      ),
    );

    expect(find.text('7G'), findsOneWidget);
    expect(find.text('3G'), findsOneWidget);
    expect(find.text('할인'), findsOneWidget);
  });
}

RummiJesterCard _jester({
  required String id,
  required String displayName,
  int baseCost = 4,
}) {
  return RummiJesterCard(
    id: id,
    displayName: displayName,
    rarity: RummiJesterRarity.common,
    baseCost: baseCost,
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
