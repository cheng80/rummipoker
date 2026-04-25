import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/services/debug_run_fixture_service.dart';
import 'package:rummipoker/services/active_run_save_service.dart';

void main() {
  test('fixture registry exposes stage2 scoring snapshot entry', () {
    final fixtures = DebugRunFixtureService.fixtures;
    final fixture = fixtures.where(
      (entry) => entry.id == DebugRunFixtureService.stage2ScoringSnapshot,
    );

    expect(fixture, isNotEmpty);
    expect(fixture.single.label, isNotEmpty);
    expect(fixture.single.description, isNotEmpty);
  });

  test('fixture registry exposes stage2 market resume entry', () {
    final fixtures = DebugRunFixtureService.fixtures;
    final fixture = fixtures.where(
      (entry) => entry.id == DebugRunFixtureService.stage2MarketResume,
    );

    expect(fixture, isNotEmpty);
    expect(fixture.single.label, isNotEmpty);
    expect(fixture.single.description, isNotEmpty);
  });

  test('stage2 scoring snapshot fixture restores expected board and meta', () {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.stage2ScoringSnapshot,
    );

    expect(fixture, isNotNull);
    expect(fixture!.runProgress.stageIndex, 2);
    expect(fixture.runProgress.gold, 36);
    expect(fixture.runProgress.ownedJesters.map((card) => card.id).toList(), [
      'crazy_jester',
      'scary_face',
    ]);
    expect(fixture.session.blind.targetScore, 480);
    expect(fixture.session.blind.scoreTowardBlind, 0);
    expect(fixture.session.deck.remaining, 34);
    expect(fixture.session.hand, isEmpty);
    expect(fixture.session.board.cellAt(0, 0)?.number, 12);
    expect(fixture.session.board.cellAt(0, 1)?.number, 11);
    expect(fixture.session.board.cellAt(4, 2)?.number, 7);
    expect(fixture.session.board.cellAt(4, 4)?.number, 12);
  });

  test('stage2 market resume fixture opens in shop scene with offers', () {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.stage2MarketResume,
    );

    expect(fixture, isNotNull);
    expect(fixture!.activeScene, ActiveRunScene.shop);
    expect(fixture.runProgress.stageIndex, 2);
    expect(fixture.runProgress.gold, 46);
    expect(fixture.runProgress.shopOffers.length, 2);
    expect(
      fixture.runProgress.shopOffers.map((offer) => offer.card.id).toList(),
      ['green_jester', 'popcorn'],
    );
  });

  test(
    'deck needle battle fixture starts with quick slot item and known deck top',
    () {
      final fixture = DebugRunFixtureService.build(
        DebugRunFixtureService.deckNeedleBattle,
      );

      expect(fixture, isNotNull);
      expect(fixture!.activeScene, ActiveRunScene.battle);
      expect(fixture.runProgress.itemInventory.quickSlotItemIds, [
        'deck_needle',
      ]);
      expect(fixture.session.peekDeckTop(3).map((tile) => tile.number), [
        1,
        2,
        3,
      ]);
    },
  );

  test('market modifier fixture opens shop with discounted market state', () {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.marketModifierShop,
    );

    expect(fixture, isNotNull);
    expect(fixture!.activeScene, ActiveRunScene.shop);
    expect(fixture.runProgress.gold, 18);
    expect(fixture.runProgress.effectiveRerollCost(), 4);
    expect(fixture.runProgress.effectiveJesterOfferPrice(0), 4);
    expect(fixture.runProgress.marketModifiers.itemOfferSlotCount, 4);
    expect(fixture.runProgress.itemInventory.passiveRelicIds, [
      'merchant_stamp',
      'market_compass',
    ]);
  });

  test('settlement item bonus fixture starts with settlement reward items', () {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.settlementItemBonus,
    );

    expect(fixture, isNotNull);
    expect(fixture!.activeScene, ActiveRunScene.battle);
    expect(fixture.runProgress.itemInventory.equippedItemIds, [
      'coin_funnel',
      'hand_funnel',
    ]);
    expect(
      fixture.runProgress.itemInventory.ownedItems.map((entry) => entry.itemId),
      ['coin_funnel', 'hand_funnel'],
    );
  });

  test('inventory sell hook fixture opens shop with jester hook', () {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.inventorySellHookShop,
    );

    expect(fixture, isNotNull);
    expect(fixture!.activeScene, ActiveRunScene.shop);
    expect(fixture.runProgress.ownedJesters.single.id, 'egg');
    expect(fixture.runProgress.itemInventory.passiveRelicIds, ['jester_hook']);
    expect(
      fixture.runProgress.itemInventory.ownedItems.map((entry) => entry.itemId),
      ['jester_hook'],
    );
  });

  test(
    'inventory quick slot fixture starts with spare pouch and 3 quick slots',
    () {
      final fixture = DebugRunFixtureService.build(
        DebugRunFixtureService.inventoryQuickSlotBattle,
      );

      expect(fixture, isNotNull);
      expect(fixture!.activeScene, ActiveRunScene.battle);
      expect(fixture.runProgress.itemInventory.passiveRelicIds, [
        'spare_pouch',
      ]);
      expect(fixture.runProgress.itemInventory.quickSlotItemIds, [
        'board_scrap',
        'hand_scrap',
        'move_token',
      ]);
    },
  );

  test('safety net fixture starts with board-full expiry guard state', () {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.safetyNetExpiryGuard,
    );

    expect(fixture, isNotNull);
    expect(fixture!.activeScene, ActiveRunScene.battle);
    expect(fixture.session.canConfirmAllFullLines, isFalse);
    expect(fixture.session.blind.boardDiscardsRemaining, 0);
    expect(
      fixture.session.evaluateExpirySignals(),
      contains(RummiExpirySignal.boardFullAfterDcExhausted),
    );
    expect(fixture.runProgress.itemInventory.passiveRelicIds, ['safety_net']);
  });
}
