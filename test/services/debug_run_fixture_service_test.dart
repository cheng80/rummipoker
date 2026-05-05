import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/line_ref.dart';
import 'package:rummipoker/logic/rummi_poker_grid/boss_modifier.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
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
    expect(fixture.runProgress.effectiveJesterOfferPrice(0), 12);
    expect(fixture.runProgress.marketModifiers.itemOfferSlotCount, 4);
    expect(fixture.runProgress.itemInventory.passiveRelicIds, [
      'merchant_stamp',
      'market_compass',
    ]);
  });

  test('market badge preview fixture opens shop with badge sample offers', () {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.marketBadgePreview,
    );

    expect(fixture, isNotNull);
    expect(fixture!.activeScene, ActiveRunScene.shop);
    expect(fixture.runProgress.stageIndex, 5);
    expect(fixture.runProgress.gold, 88);
    expect(fixture.runProgress.shopOffers.map((offer) => offer.card.id), [
      'badge_preview_chips',
      'badge_preview_mult',
    ]);
    expect(fixture.runProgress.shopOffers.map((offer) => offer.card.rarity), [
      RummiJesterRarity.common,
      RummiJesterRarity.uncommon,
    ]);
    expect(fixture.runProgress.marketModifiers.itemOfferSlotCount, 5);
    expect(fixture.runProgress.itemInventory.passiveRelicIds, isEmpty);
    expect(
      fixture.runProgress.marketModifiers.consumedItemOfferIds,
      isNot(contains('board_scrap')),
    );
    expect(
      fixture.runProgress.marketModifiers.consumedItemOfferIds,
      isNot(contains('thin_wallet')),
    );
    expect(
      fixture.runProgress.marketModifiers.consumedItemOfferIds,
      isNot(contains('shop_lens')),
    );
    expect(
      fixture.runProgress.marketModifiers.consumedItemOfferIds,
      isNot(contains('merchant_stamp')),
    );
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

  test('market item use fixture opens shop with coin cache', () {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.marketItemUseShop,
    );

    expect(fixture, isNotNull);
    expect(fixture!.activeScene, ActiveRunScene.shop);
    expect(fixture.runProgress.gold, 4);
    expect(fixture.runProgress.ownedJesters, isEmpty);
    expect(fixture.runProgress.shopOffers, isEmpty);
    expect(
      fixture.runProgress.itemInventory.ownedItems.map((entry) => entry.itemId),
      ['coin_cache'],
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

  test('animation effects fixture exposes score and item feedback setup', () {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.animationEffectsEyeCheck,
    );

    expect(fixture, isNotNull);
    expect(fixture!.activeScene, ActiveRunScene.battle);
    expect(fixture.session.canConfirmAllFullLines, isTrue);
    expect(fixture.runProgress.ownedJesters.map((card) => card.id), [
      'crazy_jester',
      'scary_face',
    ]);
    expect(fixture.runProgress.itemInventory.quickSlotItemIds, [
      'board_scrap',
      'hand_scrap',
      'move_token',
    ]);
    expect(fixture.runProgress.itemInventory.passiveRelicIds, ['spare_pouch']);
  });

  test(
    'settlement cash-out fixture is ready to clear into settlement sheet',
    () {
      final fixture = DebugRunFixtureService.build(
        DebugRunFixtureService.settlementCashOutReady,
      );

      expect(fixture, isNotNull);
      expect(fixture!.activeScene, ActiveRunScene.battle);
      expect(fixture.session.canConfirmAllFullLines, isTrue);
      expect(fixture.session.blind.targetScore, 1);
      expect(fixture.runProgress.itemInventory.equippedItemIds, [
        'coin_funnel',
        'hand_funnel',
      ]);

      final out = fixture.session.confirmAllFullLines(
        jesters: fixture.runProgress.ownedJesters,
        runtimeSnapshot: fixture.runProgress.buildRuntimeSnapshot(),
        applyScoreToBlind: false,
      );
      expect(out.result.ok, isTrue);
      expect(out.cleared, isNotNull);
      expect(out.result.lineBreakdowns.length, greaterThanOrEqualTo(10));
      expect(
        out.result.lineBreakdowns.map((line) => line.rank),
        contains(RummiHandRank.straight),
      );
    },
  );

  test('final boss cash-out fixture is ready to close the run', () {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.finalBossCashOutReady,
    );

    expect(fixture, isNotNull);
    expect(fixture!.activeScene, ActiveRunScene.battle);
    expect(fixture.runProgress.stageIndex, 8);
    expect(fixture.runProgress.currentStationBlindTierIndex, 2);
    expect(fixture.session.blind.targetScore, 1);
    expect(fixture.session.blind.bossModifier?.id, 'confirm_count_tax_v2');
    expect(fixture.session.canConfirmAllFullLines, isTrue);
  });

  test('boss line constraint fixtures expose confirmable line penalties', () {
    final cases = [
      (
        id: DebugRunFixtureService.bossRowConstraintPreview,
        modifier: RummiBossModifier.rowDampener,
        kind: LineKind.row,
      ),
      (
        id: DebugRunFixtureService.bossColumnConstraintPreview,
        modifier: RummiBossModifier.columnDampener,
        kind: LineKind.col,
      ),
      (
        id: DebugRunFixtureService.bossDiagonalConstraintPreview,
        modifier: RummiBossModifier.diagonalDampener,
        kind: LineKind.diagMain,
      ),
    ];

    for (final c in cases) {
      final fixture = DebugRunFixtureService.build(c.id);

      expect(fixture, isNotNull, reason: c.id);
      expect(fixture!.activeScene, ActiveRunScene.battle, reason: c.id);
      expect(fixture.runProgress.currentStationBlindTierIndex, 2);
      expect(fixture.session.blind.bossModifier?.id, c.modifier.id);
      expect(fixture.session.canConfirmAllFullLines, isTrue, reason: c.id);

      final out = fixture.session.confirmAllFullLines(applyScoreToBlind: false);
      expect(out.result.lineBreakdowns, hasLength(1), reason: c.id);
      final line = out.result.lineBreakdowns.single;
      expect(line.ref.kind, c.kind, reason: c.id);
      expect(line.constraintPenalties, hasLength(1), reason: c.id);
      expect(line.constraintPenalties.single.modifierId, c.modifier.id);
    }
  });

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

  test('game over fixture starts with board-full expiry state', () {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.gameOverInsightReady,
    );

    expect(fixture, isNotNull);
    expect(fixture!.activeScene, ActiveRunScene.battle);
    expect(fixture.runProgress.stageIndex, 2);
    expect(fixture.session.canConfirmAllFullLines, isFalse);
    expect(fixture.session.blind.boardDiscardsRemaining, 0);
    expect(
      fixture.session.evaluateExpirySignals(),
      contains(RummiExpirySignal.boardFullAfterDcExhausted),
    );
    expect(fixture.runProgress.itemInventory.passiveRelicIds, isEmpty);
  });
}
