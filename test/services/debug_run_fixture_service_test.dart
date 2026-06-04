import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_effect_runtime.dart';
import 'package:rummipoker/logic/rummi_poker_grid/line_ref.dart';
import 'package:rummipoker/logic/rummi_poker_grid/boss_modifier.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_battle_facade.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_market_facade.dart';
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

  test('fixture registry exposes slot unlock market entry', () {
    final fixtures = DebugRunFixtureService.fixtures;
    final fixture = fixtures.where(
      (entry) => entry.id == DebugRunFixtureService.slotUnlockMarket,
    );

    expect(fixture, isNotEmpty);
    expect(fixture.single.label, isNotEmpty);
    expect(fixture.single.description, isNotEmpty);
  });

  test('debug fixtures do not auto start tutorials by default', () {
    expect(DebugRunFixtureService.shouldAutoStartTutorials(null), isTrue);
    expect(
      DebugRunFixtureService.shouldAutoStartTutorials(
        DebugRunFixtureService.slotUnlockMarket,
      ),
      isFalse,
    );
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
    'slot unlock market fixture opens pending unlock presentation state',
    () {
      final fixture = DebugRunFixtureService.build(
        DebugRunFixtureService.slotUnlockMarket,
      );

      expect(fixture, isNotNull);
      expect(fixture!.activeScene, ActiveRunScene.shop);
      expect(fixture.runProgress.stageIndex, 6);
      expect(fixture.runProgress.jesterSlotCapacity(), 5);
      expect(fixture.runProgress.quickSlotCapacity(), 3);
      expect(fixture.runProgress.passiveRelicCapacity(), 2);
      expect(fixture.runProgress.snapshotPendingSlotUnlockPresentations(), {
        RummiSlotUnlockKind.jester,
        RummiSlotUnlockKind.quickSlot,
        RummiSlotUnlockKind.passiveRelic,
      });
    },
  );

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
      expect(fixture.runProgress.itemInventory.ownedItems.single.count, 2);
      expect(fixture.session.peekDeckTop(3).map((tile) => tile.number), [
        1,
        2,
        3,
      ]);
    },
  );

  test(
    'hand capacity deck control fixture exposes larger hand and deck needle',
    () {
      final fixture = DebugRunFixtureService.build(
        DebugRunFixtureService.handCapacityDeckControlBattle,
      );

      expect(fixture, isNotNull);
      expect(fixture!.activeScene, ActiveRunScene.battle);
      expect(fixture.session.maxHandSize, 3);
      expect(fixture.session.hand.length, 1);
      expect(fixture.session.canDrawFromDeck, isTrue);
      expect(fixture.runProgress.itemInventory.quickSlotItemIds, [
        'deck_needle',
      ]);
      expect(fixture.runProgress.itemInventory.passiveRelicIds, [
        'travel_pouch',
      ]);
      expect(fixture.session.peekDeckTop(3).map((tile) => tile.number), [
        1,
        7,
        7,
      ]);
    },
  );

  test(
    'hand capacity increase preview fixture starts before capacity pulse',
    () {
      final fixture = DebugRunFixtureService.build(
        DebugRunFixtureService.handCapacityIncreasePreviewBattle,
      );

      expect(fixture, isNotNull);
      expect(fixture!.activeScene, ActiveRunScene.battle);
      expect(fixture.session.maxHandSize, 1);
      expect(fixture.session.hand.length, 1);
      expect(fixture.session.canDrawFromDeck, isFalse);
      expect(fixture.runProgress.itemInventory.quickSlotItemIds, [
        'battle_pouch',
      ]);
    },
  );

  test('game over pre fade fixture expires after last hand discard', () {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.gameOverPreFadeTrigger,
    );

    expect(fixture, isNotNull);
    expect(fixture!.activeScene, ActiveRunScene.battle);
    expect(fixture.session.deck.remaining, 0);
    expect(fixture.session.hand.length, 1);
    expect(fixture.session.blind.handDiscardsRemaining, 1);
    expect(fixture.session.evaluateExpirySignals(), isEmpty);

    final discardResult = fixture.session.tryDiscardFromHand(
      fixture.session.hand.single,
    );

    expect(discardResult.fail, isNull);
    expect(fixture.session.hand, isEmpty);
    expect(fixture.session.blind.handDiscardsRemaining, 0);
    expect(fixture.session.evaluateExpirySignals(), [
      RummiExpirySignal.drawPileExhausted,
    ]);
  });

  test('screenshot run growth fixture exposes played hand growth state', () {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.screenshotRunGrowthBattle,
    );

    expect(fixture, isNotNull);
    expect(fixture!.activeScene, ActiveRunScene.battle);
    expect(fixture.runProgress.stageIndex, 4);
    expect(
      fixture.runProgress.snapshotPlayedHandCounts()[RummiHandRank.straight],
      4,
    );
    expect(
      fixture.runProgress.snapshotPlayedHandCounts()[RummiHandRank.flush],
      3,
    );
    expect(
      fixture.runProgress.snapshotPlayedHandCounts()[RummiHandRank.fullHouse],
      2,
    );
  });

  test('market modifier fixture opens shop with discounted market state', () {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.marketModifierShop,
    );

    expect(fixture, isNotNull);
    expect(fixture!.activeScene, ActiveRunScene.shop);
    expect(fixture.runProgress.gold, 18);
    expect(fixture.runProgress.effectiveRerollCost(), 4);
    expect(fixture.runProgress.effectiveJesterOfferPrice(0), 2);
    expect(fixture.runProgress.marketModifiers.itemOfferSlotCount, 3);
    expect(fixture.runProgress.itemInventory.passiveRelicIds, [
      'merchant_stamp',
      'market_compass',
    ]);
  });

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
    expect(fixture.runProgress.unlockedQuickSlotCapacity, 3);
    expect(fixture.runProgress.itemInventory.passiveRelicIds, isEmpty);
  });

  test('item motion fixture exposes battle item motion setup', () {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.itemMotionEyeCheck,
    );

    expect(fixture, isNotNull);
    expect(fixture!.activeScene, ActiveRunScene.battle);
    expect(fixture.session.hand, isEmpty);
    expect(fixture.session.canDrawFromDeck, isTrue);
    expect(fixture.session.blind.boardMovesRemaining, greaterThan(0));
    expect(fixture.runProgress.itemInventory.quickSlotItemIds, [
      'deck_needle',
      'emergency_draw',
      'slide_wax',
    ]);
    expect(fixture.session.peekDeckTop(3).map((tile) => tile.number), [
      1,
      2,
      3,
    ]);
  });

  test('next confirm motion fixture exposes queued item setup', () {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.nextConfirmMotionEyeCheck,
    );

    expect(fixture, isNotNull);
    expect(fixture!.activeScene, ActiveRunScene.battle);
    expect(fixture.session.canConfirmAllFullLines, isTrue);
    expect(fixture.runProgress.itemInventory.quickSlotItemIds, [
      'straight_oil',
    ]);
  });

  test('market item motion fixture exposes gold and non-gold use items', () {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.marketItemMotionEyeCheck,
    );

    expect(fixture, isNotNull);
    expect(fixture!.activeScene, ActiveRunScene.shop);
    expect(fixture.runProgress.gold, 18);
    expect(
      fixture.runProgress.itemInventory.ownedItems.map((entry) => entry.itemId),
      ['coin_cache', 'trade_ticket'],
    );
  });

  test('special tile market fixture exposes modified tile offers', () {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.specialTileMarketPreview,
    );

    expect(fixture, isNotNull);
    expect(fixture!.activeScene, ActiveRunScene.shop);
    expect(
      fixture.runProgress.tileOffers.any((tile) => tile.hasModifier),
      isTrue,
    );
  });

  test('special tile battle fixture exposes modified board and hand tiles', () {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.specialTileBattlePreview,
    );

    expect(fixture, isNotNull);
    expect(fixture!.activeScene, ActiveRunScene.battle);
    expect(fixture.session.canConfirmAllFullLines, isTrue);
    expect(
      fixture.session.blind.bossModifier?.id,
      RummiBossModifier.redDampener.id,
    );
    expect(
      fixture.session.board.snapshotCells().whereType<Tile>().any(
        (tile) => tile.hasModifier,
      ),
      isTrue,
    );
    expect(fixture.session.hand.any((tile) => tile.hasModifier), isTrue);

    final battle = RummiBattleRuntimeFacade.fromRuntime(
      session: fixture.session,
      runProgress: fixture.runProgress,
    );
    expect(
      battle.scoringPreview?.expectedTileModifierEffectCount,
      greaterThan(0),
    );
  });

  test('line memory market fixture exposes active ritual offer', () {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.lineMemoryMarketPreview,
    );
    final catalog = ItemCatalog.fromJson(
      jsonDecode(File('data/common/items_common_v1.json').readAsStringSync())
          as Map<String, dynamic>,
    );

    expect(fixture, isNotNull);
    expect(fixture!.activeScene, ActiveRunScene.shop);

    final market = RummiMarketRuntimeFacade.fromRunProgress(
      fixture.runProgress,
      itemCatalog: catalog,
    );
    expect(
      market.itemOffers.map((offer) => offer.contentId),
      contains('line_memory'),
    );
  });

  test('line memory battle fixture starts with usable scoring line', () {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.lineMemoryBattlePreview,
    );

    expect(fixture, isNotNull);
    expect(fixture!.activeScene, ActiveRunScene.battle);
    expect(fixture.runProgress.itemInventory.quickSlotItemIds, ['line_memory']);
    expect(fixture.session.canConfirmAllFullLines, isTrue);
    expect(
      fixture.session.currentScoringLineSummaries().map((line) => line.rank),
      contains(RummiHandRank.lowStraightFlush),
    );
  });

  test('ritual battle preview fixtures expose representative item groups', () {
    final cases = [
      (
        id: DebugRunFixtureService.ritualGrowthCopyBattlePreview,
        items: ['line_memory', 'keystone_copy', 'rank_echo'],
      ),
      (
        id: DebugRunFixtureService.ritualDeckEchoBattlePreview,
        items: ['sealed_copy', 'scarce_copy', 'color_echo'],
      ),
      (
        id: DebugRunFixtureService.ritualSealOverrideBattlePreview,
        items: ['fate_three_kind_high', 'fate_straight_high', 'rank_concord'],
      ),
      (
        id: DebugRunFixtureService.ritualPruneBurnBattlePreview,
        items: ['trim_color', 'deadwood_burn', 'sacrifice_line'],
      ),
    ];

    for (final c in cases) {
      final fixture = DebugRunFixtureService.build(c.id);

      expect(fixture, isNotNull, reason: c.id);
      expect(fixture!.activeScene, ActiveRunScene.battle, reason: c.id);
      expect(
        fixture.runProgress.itemInventory.quickSlotItemIds,
        c.items,
        reason: c.id,
      );
      expect(
        fixture.runProgress.quickSlotCapacity(),
        RunInventoryState.maxQuickSlotCapacity,
        reason: c.id,
      );
      expect(
        fixture.session.currentScoringLineSummaries(),
        isNotEmpty,
        reason: c.id,
      );
      expect(
        fixture.session.currentBoardLineSummaries().any(
          (line) => !line.isScoringLine && line.occupiedCount >= 3,
        ),
        isTrue,
        reason: c.id,
      );
    }
  });

  test('fate transform fixtures expose one card each in review order', () {
    expect(
      DebugRunFixtureService.fateLineTransformPreviewItemsByFixture.values
          .toList(),
      [
        'number_mask',
        'wild_thread',
        'off_color_rite',
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
        'fate_three_kind_high',
        'line_pruner',
        'trim_rank',
      ],
    );

    for (final entry
        in DebugRunFixtureService
            .fateLineTransformPreviewItemsByFixture
            .entries) {
      final fixture = DebugRunFixtureService.build(entry.key);

      expect(fixture, isNotNull, reason: entry.key);
      expect(fixture!.activeScene, ActiveRunScene.battle, reason: entry.key);
      expect(fixture.runProgress.itemInventory.quickSlotItemIds, [
        entry.value,
      ], reason: entry.key);
      expect(
        fixture.session
            .currentBoardLineSummaryFor(LineRef.row(2))
            ?.isScoringLine,
        isFalse,
        reason: entry.key,
      );
    }
  });

  test(
    'fate transform fixtures apply selected line into expected hand rank',
    () {
      final catalog = ItemCatalog.fromJsonString(
        File('data/common/items_common_v1.json').readAsStringSync(),
      );
      final expectedRanks = <String, RummiHandRank>{
        'number_mask': RummiHandRank.royalStraightFlush,
        'wild_thread': RummiHandRank.straightFlush,
        'off_color_rite': RummiHandRank.lowStraightFlush,
        'color_concord': RummiHandRank.crownFourOfAKind,
        'step_rite': RummiHandRank.fourOfAKind,
        'rank_concord': RummiHandRank.fullHouse,
        'fate_full_house_low': RummiHandRank.fullHouse,
        'flush_house_fate': RummiHandRank.flushHouse,
        'flush_five_fate': RummiHandRank.flushFive,
        'fate_flush_high': RummiHandRank.flush,
        'fate_flush_low': RummiHandRank.flush,
        'fate_straight_high': RummiHandRank.straight,
        'fate_straight_low': RummiHandRank.straight,
        'fate_three_kind_high': RummiHandRank.threeOfAKind,
        'line_pruner': RummiHandRank.threeOfAKind,
        'trim_rank': RummiHandRank.twoPair,
      };

      for (final entry
          in DebugRunFixtureService
              .fateLineTransformPreviewItemsByFixture
              .entries) {
        final fixture = DebugRunFixtureService.build(entry.key)!;
        final item = catalog.findById(entry.value)!;
        expect(
          item.id,
          entry.value,
          reason: '${entry.key} must use canonical id',
        );
        expect(
          item.effect.op,
          'ritual_line_effect',
          reason: '${entry.key} must stay a ritual line fixture',
        );
        expect(
          item.effect.value('ritualAction'),
          startsWith('fate_'),
          reason: '${entry.key} must use a fate transform action',
        );
        final result = ItemEffectRuntime.useBattleItemOnRitualTarget(
          item: item,
          session: fixture.session,
          runProgress: fixture.runProgress,
          lineRef: LineRef.row(2),
        );
        final transformed = fixture.session.currentBoardLineSummaryFor(
          LineRef.row(2),
        );

        expect(result.isSuccess, isTrue, reason: entry.value);
        expect(transformed?.occupiedCount, 5, reason: entry.value);
        expect(
          transformed?.rank,
          expectedRanks[entry.value],
          reason: entry.value,
        );
        expect(
          fixture.runProgress.itemInventory.quickSlotItemIds,
          isEmpty,
          reason: entry.value,
        );
      }
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

  test(
    'boss board cell block fixture exposes blocked cells and scoring line',
    () {
      final fixture = DebugRunFixtureService.build(
        DebugRunFixtureService.bossBoardCellBlockPreview,
      );

      expect(fixture, isNotNull);
      expect(fixture!.activeScene, ActiveRunScene.battle);
      expect(fixture.runProgress.currentStationBlindTierIndex, 2);
      expect(
        fixture.session.blind.bossModifier?.id,
        RummiBossModifier.blockCornersCenter.id,
      );
      expect(fixture.session.blind.bossModifier?.blockedCells, hasLength(5));
      expect(fixture.session.canConfirmAllFullLines, isTrue);

      final out = fixture.session.confirmAllFullLines(applyScoreToBlind: false);
      expect(out.result.lineBreakdowns, isNotEmpty);
      expect(out.result.lineBreakdowns.first.constraintPenalties, isEmpty);
      expect(out.result.scoreAdded, greaterThanOrEqualTo(60));
    },
  );

  test('boss board cell block variant fixtures expose requested patterns', () {
    final cases = [
      (
        id: DebugRunFixtureService.bossBoardCellBlockRightColumnPreview,
        modifier: RummiBossModifier.blockRightColumn,
        canConfirm: true,
      ),
      (
        id: DebugRunFixtureService.bossBoardCellBlockMainDiagonalPreview,
        modifier: RummiBossModifier.blockMainDiagonal,
        canConfirm: true,
      ),
    ];

    for (final c in cases) {
      final fixture = DebugRunFixtureService.build(c.id);

      expect(fixture, isNotNull, reason: c.id);
      expect(fixture!.activeScene, ActiveRunScene.battle, reason: c.id);
      expect(fixture.runProgress.currentStationBlindTierIndex, 2);
      expect(fixture.session.blind.bossModifier?.id, c.modifier.id);
      expect(fixture.session.blind.bossModifier?.blockedCells, hasLength(5));
      for (final cell in c.modifier.blockedCells) {
        expect(
          fixture.session.board.cellAt(cell.$1, cell.$2),
          isNull,
          reason: '${c.id} keeps blocked cell $cell empty',
        );
      }
      expect(
        fixture.session.canConfirmAllFullLines,
        c.canConfirm,
        reason: c.id,
      );
      if (c.canConfirm) {
        final out = fixture.session.confirmAllFullLines(
          applyScoreToBlind: false,
        );
        expect(out.result.lineBreakdowns, isNotEmpty, reason: c.id);
      }
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

  test('S8 color Jester stack fixture reproduces stacked flush effects', () {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.s8ColorJesterStackPreview,
    );

    expect(fixture, isNotNull);
    expect(fixture!.activeScene, ActiveRunScene.battle);
    expect(fixture.runProgress.stageIndex, 8);
    expect(fixture.runProgress.currentStationBlindTierIndex, 2);
    expect(fixture.session.blind.bossModifier?.id, 'all_score_dampener_v1');
    expect(fixture.runProgress.ownedJesters.map((card) => card.id), [
      'droll_jester',
      'the_tribe',
    ]);
    expect(fixture.session.canConfirmAllFullLines, isTrue);

    final out = fixture.session.confirmAllFullLines(
      jesters: fixture.runProgress.ownedJesters,
      runtimeSnapshot: fixture.runProgress.buildRuntimeSnapshot(),
      applyScoreToBlind: false,
    );
    final line = out.result.lineBreakdowns.single;

    expect(line.rank, RummiHandRank.flush);
    expect(line.constraintPenalties.single.modifierId, 'all_score_dampener_v1');
    expect(line.effects.map((effect) => effect.jesterId), [
      'droll_jester',
      'the_tribe',
    ]);
    expect(line.effects.map((effect) => effect.displayToken), [
      '+50%',
      '점수 x2',
    ]);
    expect(line.effects.every((effect) => effect.scoreDelta > 0), isTrue);
  });
}
