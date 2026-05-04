import 'dart:math';

import '../logic/rummi_poker_grid/hand_rank.dart';
import '../logic/rummi_poker_grid/boss_modifier.dart';
import '../logic/rummi_poker_grid/item_definition.dart';
import '../logic/rummi_poker_grid/jester_meta.dart';
import '../logic/rummi_poker_grid/models/board.dart';
import '../logic/rummi_poker_grid/models/poker_deck.dart';
import '../logic/rummi_poker_grid/models/tile.dart';
import '../logic/rummi_poker_grid/rummi_blind_state.dart';
import '../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../utils/seeded_random.dart';
import 'active_run_save_service.dart';
import 'new_run_setup.dart';

class DebugRunFixtureDefinition {
  const DebugRunFixtureDefinition({
    required this.id,
    required this.label,
    required this.description,
    required this.builder,
  });

  final String id;
  final String label;
  final String description;
  final ActiveRunRuntimeState Function() builder;
}

class DebugRunFixtureService {
  DebugRunFixtureService._();

  static const String stage2ScoringSnapshot = 'stage2_scoring_snapshot';
  static const String stage2MarketResume = 'stage2_market_resume';
  static const String deckNeedleBattle = 'deck_needle_battle';
  static const String marketModifierShop = 'market_modifier_shop';
  static const String marketBadgePreview = 'market_badge_preview';
  static const String settlementItemBonus = 'settlement_item_bonus';
  static const String inventorySellHookShop = 'inventory_sell_hook_shop';
  static const String marketItemUseShop = 'market_item_use_shop';
  static const String inventoryQuickSlotBattle = 'inventory_quick_slot_battle';
  static const String safetyNetExpiryGuard = 'safety_net_expiry_guard';
  static const String animationEffectsEyeCheck = 'animation_effects_eye_check';
  static const String settlementCashOutReady = 'settlement_cash_out_ready';
  static const String bossRowConstraintPreview = 'boss_row_constraint_preview';
  static const String bossColumnConstraintPreview =
      'boss_column_constraint_preview';
  static const String bossDiagonalConstraintPreview =
      'boss_diagonal_constraint_preview';

  /// 새 디버그 픽스처는 여기에 등록하고, 아래에 대응하는 builder를 추가한다.
  static final List<DebugRunFixtureDefinition> _fixtures = [
    DebugRunFixtureDefinition(
      id: stage2ScoringSnapshot,
      label: 'Stage 2 점수 스냅샷',
      description:
          'Stage 2 / Gold 36 / Crazy Jester + Scary Face / Hand 비어 있음 / Deck 34',
      builder: _buildStage2ScoringSnapshot,
    ),
    DebugRunFixtureDefinition(
      id: stage2MarketResume,
      label: 'Stage 2 Market 복귀',
      description: 'Stage 2 / Shop scene 복귀 / Gold 46 / 다음 Station 자동 진행 검증용',
      builder: _buildStage2MarketResume,
    ),
    DebugRunFixtureDefinition(
      id: deckNeedleBattle,
      label: 'Deck Needle 전투 아이템',
      description: 'Deck Needle 보유 / 덱 상단 3장 확인 dialog 검증용',
      builder: _buildDeckNeedleBattle,
    ),
    DebugRunFixtureDefinition(
      id: marketModifierShop,
      label: 'Market Modifier 상점',
      description: '리롤/구매 할인 + Item offer 4칸 검증용',
      builder: _buildMarketModifierShop,
    ),
    DebugRunFixtureDefinition(
      id: marketBadgePreview,
      label: 'Market Badge 프리뷰',
      description: 'Jester category badge + Item rarity/slot badge 눈검증용',
      builder: _buildMarketBadgePreview,
    ),
    DebugRunFixtureDefinition(
      id: settlementItemBonus,
      label: 'Settlement Item 보너스',
      description: 'Coin Funnel + Hand Funnel 보유 / cash-out 보너스 라인 검증용',
      builder: _buildSettlementItemBonus,
    ),
    DebugRunFixtureDefinition(
      id: inventorySellHookShop,
      label: 'Inventory Sell Hook 상점',
      description: 'Jester Hook 보유 / Market 판매가 +1 표시 검증용',
      builder: _buildInventorySellHookShop,
    ),
    DebugRunFixtureDefinition(
      id: marketItemUseShop,
      label: 'Market Item 사용 상점',
      description: 'Coin Cache 보유 / Market 사용 골드 비행 연출 검증용',
      builder: _buildMarketItemUseShop,
    ),
    DebugRunFixtureDefinition(
      id: inventoryQuickSlotBattle,
      label: 'Inventory Quick Slot 전투',
      description: 'Spare Pouch 보유 / quick slot 3칸 표시 검증용',
      builder: _buildInventoryQuickSlotBattle,
    ),
    DebugRunFixtureDefinition(
      id: safetyNetExpiryGuard,
      label: 'Safety Net 종료 방지',
      description: 'Safety Net 보유 / 보드가 꽉 찬 종료 위기 구조 검증용',
      builder: _buildSafetyNetExpiryGuard,
    ),
    DebugRunFixtureDefinition(
      id: animationEffectsEyeCheck,
      label: '연출 눈검증 전투',
      description:
          '점수 preview pulse / line confirm particle / quick item toast 검증용',
      builder: _buildAnimationEffectsEyeCheck,
    ),
    DebugRunFixtureDefinition(
      id: settlementCashOutReady,
      label: '정산 화면 체크',
      description: '확정하기 1회로 Stage Clear + cash-out 정산 시트 진입 검증용',
      builder: _buildSettlementCashOutReady,
    ),
    DebugRunFixtureDefinition(
      id: bossRowConstraintPreview,
      label: 'Boss 가로줄 제약',
      description: '가로줄 약화 보스전 / 확정 가능한 가로줄 표시 검증용',
      builder: _buildBossRowConstraintPreview,
    ),
    DebugRunFixtureDefinition(
      id: bossColumnConstraintPreview,
      label: 'Boss 세로줄 제약',
      description: '세로줄 약화 보스전 / 확정 가능한 세로줄 표시 검증용',
      builder: _buildBossColumnConstraintPreview,
    ),
    DebugRunFixtureDefinition(
      id: bossDiagonalConstraintPreview,
      label: 'Boss 대각선 제약',
      description: '대각선 약화 보스전 / 확정 가능한 대각선 표시 검증용',
      builder: _buildBossDiagonalConstraintPreview,
    ),
  ];

  static List<DebugRunFixtureDefinition> get fixtures =>
      List<DebugRunFixtureDefinition>.unmodifiable(_fixtures);

  static DebugRunFixtureDefinition? find(String fixtureId) {
    for (final fixture in _fixtures) {
      if (fixture.id == fixtureId) {
        return fixture;
      }
    }
    return null;
  }

  static ActiveRunRuntimeState? build(String fixtureId) {
    return find(fixtureId)?.builder();
  }

  static ActiveRunRuntimeState _buildStage2ScoringSnapshot() {
    final board = RummiBoard()
      ..setCell(0, 0, _tile(TileColor.blue, 12))
      ..setCell(0, 1, _tile(TileColor.blue, 11))
      ..setCell(0, 2, _tile(TileColor.red, 10))
      ..setCell(0, 3, _tile(TileColor.black, 8))
      ..setCell(0, 4, _tile(TileColor.red, 9))
      ..setCell(1, 0, _tile(TileColor.blue, 4))
      ..setCell(1, 1, _tile(TileColor.red, 5))
      ..setCell(1, 2, _tile(TileColor.black, 5))
      ..setCell(1, 3, _tile(TileColor.blue, 8))
      ..setCell(2, 0, _tile(TileColor.blue, 2))
      ..setCell(2, 1, _tile(TileColor.red, 2))
      ..setCell(2, 2, _tile(TileColor.yellow, 7))
      ..setCell(2, 3, _tile(TileColor.red, 8))
      ..setCell(3, 1, _tile(TileColor.yellow, 12))
      ..setCell(3, 2, _tile(TileColor.yellow, 4))
      ..setCell(4, 2, _tile(TileColor.black, 7))
      ..setCell(4, 3, _tile(TileColor.black, 11))
      ..setCell(4, 4, _tile(TileColor.black, 12));

    final session = RummiPokerGridSession.restored(
      runSeed: 2026041901,
      deckCopiesPerTile: kDefaultCopiesPerTile,
      maxHandSize: 1,
      runRandomState: SeededRandom(2026041901).state,
      blind: RummiBlindState(
        targetScore: 480,
        boardDiscardsRemaining: 4,
        handDiscardsRemaining: 2,
        scoreTowardBlind: 0,
      ),
      deck: PokerDeck.remainingAfterPlaced(
        board: board,
        random: Random(2026041901),
      ),
      board: board,
      hand: const [],
      eliminated: const [],
    );

    final runProgress = RummiRunProgress.restore(
      stageIndex: 2,
      gold: 36,
      rerollCost: RummiRunProgress.shopBaseRerollCost,
      ownedJesters: const [
        RummiJesterCard(
          id: 'crazy_jester',
          displayName: 'Crazy Jester',
          rarity: RummiJesterRarity.common,
          baseCost: 4,
          effectText: 'Played hand containing a Straight gives +12 Mult',
          effectType: 'mult_bonus',
          trigger: 'onScore',
          conditionType: 'straight',
          conditionValue: 'contains_straight',
          value: 12,
          xValue: null,
          mappedTileColors: [],
          mappedTileNumbers: [],
        ),
        RummiJesterCard(
          id: 'scary_face',
          displayName: 'Scary Face',
          rarity: RummiJesterRarity.common,
          baseCost: 4,
          effectText: 'Played face cards give +30 Chips when scored',
          effectType: 'chips_bonus',
          trigger: 'onScore',
          conditionType: 'face_card',
          conditionValue: 'jack_queen_king',
          value: 30,
          xValue: null,
          mappedTileColors: [],
          mappedTileNumbers: [11, 12, 13],
        ),
      ],
      shopOffers: const [],
      statefulValuesBySlot: const {},
      playedHandCounts: const <RummiHandRank, int>{},
    );

    final stageStartSnapshot = ActiveRunStageSnapshot(
      session: session.copySnapshot(),
      runProgress: runProgress.copySnapshot(),
    );

    return ActiveRunRuntimeState(
      activeScene: ActiveRunScene.battle,
      difficulty: NewRunDifficulty.standard,
      session: session,
      runProgress: runProgress,
      stageStartSnapshot: stageStartSnapshot,
    );
  }

  static ActiveRunRuntimeState _buildStage2MarketResume() {
    final base = _buildStage2ScoringSnapshot();
    final runProgress = base.runProgress.copySnapshot()
      ..gold = 46
      ..shopOffers.addAll([
        RummiShopOffer(
          slotIndex: 0,
          card: RummiJesterCard(
            id: 'green_jester',
            displayName: 'Green Jester',
            rarity: RummiJesterRarity.common,
            baseCost: 4,
            effectText: 'Every discard changes current Mult by +1',
            effectType: 'stateful_growth',
            trigger: 'onDiscard',
            conditionType: 'none',
            conditionValue: null,
            value: 0,
            xValue: null,
            mappedTileColors: [],
            mappedTileNumbers: [],
          ),
          price: 7,
        ),
        RummiShopOffer(
          slotIndex: 1,
          card: RummiJesterCard(
            id: 'popcorn',
            displayName: 'Popcorn',
            rarity: RummiJesterRarity.common,
            baseCost: 5,
            effectText: 'Starts at +20 Mult, decreases by 4 each round',
            effectType: 'stateful_growth',
            trigger: 'onScore',
            conditionType: 'none',
            conditionValue: null,
            value: 20,
            xValue: null,
            mappedTileColors: [],
            mappedTileNumbers: [],
          ),
          price: 8,
        ),
      ]);

    return ActiveRunRuntimeState(
      activeScene: ActiveRunScene.shop,
      difficulty: NewRunDifficulty.standard,
      session: base.session.copySnapshot(),
      runProgress: runProgress,
      stageStartSnapshot: base.stageStartSnapshot,
    );
  }

  static ActiveRunRuntimeState _buildDeckNeedleBattle() {
    final base = _buildStage2ScoringSnapshot();
    final deckTop = [
      _tile(TileColor.black, 4),
      _tile(TileColor.yellow, 3),
      _tile(TileColor.blue, 2),
      _tile(TileColor.red, 1),
    ];
    final session = RummiPokerGridSession.restored(
      runSeed: base.session.runSeed,
      deckCopiesPerTile: kDefaultCopiesPerTile,
      maxHandSize: base.session.maxHandSize,
      runRandomState: base.session.runRandom.state,
      ruleset: base.session.ruleset,
      blind: base.session.blind.copyWith(),
      deck: PokerDeck.fromSnapshot(deckTop),
      board: base.session.board.copy(),
      hand: List<Tile>.from(base.session.hand),
      eliminated: List<Tile>.from(base.session.eliminated),
      boardMoveHistory: List<BoardMoveRecord>.from(
        base.session.boardMoveHistory,
      ),
    );
    final runProgress = base.runProgress.copySnapshot()
      ..itemInventory = const RunInventoryState(
        ownedItems: [
          OwnedItemEntry(
            itemId: 'deck_needle',
            count: 1,
            placement: ItemPlacement.quickSlot,
          ),
        ],
        quickSlotItemIds: ['deck_needle'],
      );
    return ActiveRunRuntimeState(
      activeScene: ActiveRunScene.battle,
      difficulty: NewRunDifficulty.standard,
      session: session,
      runProgress: runProgress,
      stageStartSnapshot: ActiveRunStageSnapshot(
        session: session.copySnapshot(),
        runProgress: runProgress.copySnapshot(),
      ),
    );
  }

  static ActiveRunRuntimeState _buildMarketModifierShop() {
    final base = _buildStage2ScoringSnapshot();
    final runProgress = base.runProgress.copySnapshot()
      ..gold = 18
      ..rerollCost = RummiRunProgress.shopBaseRerollCost
      ..shopOffers.addAll([
        RummiShopOffer(
          slotIndex: 0,
          card: RummiJesterCard(
            id: 'green_jester',
            displayName: 'Green Jester',
            rarity: RummiJesterRarity.common,
            baseCost: 4,
            effectText: 'Every discard changes current Mult by +1',
            effectType: 'stateful_growth',
            trigger: 'onDiscard',
            conditionType: 'none',
            conditionValue: null,
            value: 0,
            xValue: null,
            mappedTileColors: [],
            mappedTileNumbers: [],
          ),
          price: 7,
        ),
        RummiShopOffer(
          slotIndex: 1,
          card: RummiJesterCard(
            id: 'popcorn',
            displayName: 'Popcorn',
            rarity: RummiJesterRarity.common,
            baseCost: 5,
            effectText: 'Starts at +20 Mult, decreases by 4 each round',
            effectType: 'stateful_growth',
            trigger: 'onScore',
            conditionType: 'none',
            conditionValue: null,
            value: 20,
            xValue: null,
            mappedTileColors: [],
            mappedTileNumbers: [],
          ),
          price: 8,
        ),
      ])
      ..itemInventory = const RunInventoryState(
        ownedItems: [
          OwnedItemEntry(
            itemId: 'reroll_token',
            count: 1,
            placement: ItemPlacement.inventory,
          ),
          OwnedItemEntry(
            itemId: 'item_invoice',
            count: 1,
            placement: ItemPlacement.inventory,
          ),
          OwnedItemEntry(
            itemId: 'merchant_stamp',
            count: 1,
            placement: ItemPlacement.passiveRack,
          ),
          OwnedItemEntry(
            itemId: 'shop_lens',
            count: 1,
            placement: ItemPlacement.equipped,
          ),
          OwnedItemEntry(
            itemId: 'market_compass',
            count: 1,
            placement: ItemPlacement.passiveRack,
          ),
        ],
        passiveRelicIds: ['merchant_stamp', 'market_compass'],
        equippedItemIds: ['shop_lens'],
      );
    runProgress.queueMarketModifier(op: 'discount_next_reroll', amount: 1);
    runProgress.queueMarketModifier(
      op: 'discount_next_purchase',
      amount: 2,
      category: 'item',
    );
    runProgress.queueMarketModifier(
      op: 'discount_next_purchase',
      amount: 2,
      category: 'jester',
    );
    runProgress.queueMarketModifier(
      op: 'discount_cheapest_first_offer',
      amount: 1,
    );
    runProgress.queueMarketModifier(op: 'extra_item_offer_slot', amount: 1);

    return ActiveRunRuntimeState(
      activeScene: ActiveRunScene.shop,
      difficulty: NewRunDifficulty.standard,
      session: base.session.copySnapshot(),
      runProgress: runProgress,
      stageStartSnapshot: base.stageStartSnapshot,
    );
  }

  static ActiveRunRuntimeState _buildMarketBadgePreview() {
    final base = _buildStage2ScoringSnapshot();
    final runProgress = base.runProgress.copySnapshot()
      ..stageIndex = 5
      ..gold = 88
      ..rerollCost = RummiRunProgress.shopBaseRerollCost;
    runProgress.shopOffers
      ..clear()
      ..addAll([
        RummiShopOffer(
          slotIndex: 0,
          card: RummiJesterCard(
            id: 'badge_preview_chips',
            displayName: 'Badge Chips',
            rarity: RummiJesterRarity.common,
            baseCost: 4,
            effectText: 'Played number 7 tiles give +24 Chips when scored',
            effectType: 'chips_bonus',
            trigger: 'onScore',
            conditionType: 'number',
            conditionValue: '7',
            value: 24,
            xValue: null,
            mappedTileColors: [],
            mappedTileNumbers: [7],
          ),
          price: 4,
        ),
        RummiShopOffer(
          slotIndex: 1,
          card: RummiJesterCard(
            id: 'badge_preview_mult',
            displayName: 'Badge Mult',
            rarity: RummiJesterRarity.uncommon,
            baseCost: 6,
            effectText: 'Played hand containing a Flush gives +16 Mult',
            effectType: 'mult_bonus',
            trigger: 'onScore',
            conditionType: 'flush',
            conditionValue: 'contains_flush',
            value: 16,
            xValue: null,
            mappedTileColors: [],
            mappedTileNumbers: [],
          ),
          price: 6,
        ),
      ]);
    runProgress.queueMarketModifier(op: 'extra_item_offer_slot', amount: 2);
    runProgress.queueMarketModifier(op: 'rarity_weight_bonus', amount: 70);
    _limitMarketBadgePreviewItems(runProgress);

    return ActiveRunRuntimeState(
      activeScene: ActiveRunScene.shop,
      difficulty: NewRunDifficulty.standard,
      session: base.session.copySnapshot(),
      runProgress: runProgress,
      stageStartSnapshot: ActiveRunStageSnapshot(
        session: base.stageStartSnapshot.session.copySnapshot(),
        runProgress: runProgress.copySnapshot(),
      ),
    );
  }

  static void _limitMarketBadgePreviewItems(RummiRunProgress runProgress) {
    final previewIds = _marketBadgePreviewItemIds.toSet();
    for (final itemId in _marketBadgePreviewCatalogItemIds) {
      if (!previewIds.contains(itemId)) {
        runProgress.markItemOfferConsumed(itemId);
      }
    }
  }

  /// Market badge 프리뷰가 Q-SLT/TOOL/GEAR/PSV를 비교하기 쉽게 남기는 대표 후보.
  static const List<String> _marketBadgePreviewItemIds = [
    'board_scrap',
    'thin_wallet',
    'shop_lens',
    'merchant_stamp',
  ];

  /// data/common/items_common_v1.json의 현재 item id 목록.
  ///
  /// 디버그 fixture에서만 쓰는 명시적 allow-list 보조 자료다. 실제 market 생성,
  /// 구매, 저장 규칙은 이 목록을 읽지 않는다.
  static const List<String> _marketBadgePreviewCatalogItemIds = [
    'reroll_token',
    'coupon_stamp',
    'coin_cache',
    'board_scrap',
    'hand_scrap',
    'chip_capsule',
    'mult_capsule',
    'line_polish',
    'straight_oil',
    'flush_powder',
    'pair_splint',
    'overlap_pin',
    'emergency_draw',
    'ledger_clip',
    'discard_glove',
    'mulligan_sleeve',
    'shop_lens',
    'jester_hook',
    'score_abacus',
    'thin_caliper',
    'stage_map',
    'spare_pouch',
    'merchant_stamp',
    'safety_net',
    'coin_funnel',
    'hand_funnel',
    'lucky_counter',
    'echo_bell',
    'boss_trophy',
    'thin_wallet',
    'trade_ticket',
    'jester_invoice',
    'item_invoice',
    'red_swatch',
    'blue_swatch',
    'black_swatch',
    'yellow_swatch',
    'rank_chalk',
    'deck_needle',
    'tile_polisher',
    'move_token',
    'slide_wax',
    'board_lift',
    'undo_seal',
    'organizer_glove',
    'travel_pouch',
    'wide_grip',
    'grand_satchel',
    'market_compass',
  ];

  static ActiveRunRuntimeState _buildSettlementItemBonus() {
    final base = _buildStage2ScoringSnapshot();
    final runProgress = base.runProgress.copySnapshot()
      ..itemInventory = const RunInventoryState(
        ownedItems: [
          OwnedItemEntry(
            itemId: 'coin_funnel',
            count: 1,
            placement: ItemPlacement.equipped,
          ),
          OwnedItemEntry(
            itemId: 'hand_funnel',
            count: 1,
            placement: ItemPlacement.equipped,
          ),
        ],
        equippedItemIds: ['coin_funnel', 'hand_funnel'],
      );
    return ActiveRunRuntimeState(
      activeScene: ActiveRunScene.battle,
      difficulty: NewRunDifficulty.standard,
      session: base.session.copySnapshot(),
      runProgress: runProgress,
      stageStartSnapshot: ActiveRunStageSnapshot(
        session: base.stageStartSnapshot.session.copySnapshot(),
        runProgress: runProgress.copySnapshot(),
      ),
    );
  }

  static ActiveRunRuntimeState _buildInventorySellHookShop() {
    final base = _buildStage2MarketResume();
    final runProgress = base.runProgress.copySnapshot()
      ..gold = 24
      ..itemInventory = const RunInventoryState(
        ownedItems: [
          OwnedItemEntry(
            itemId: 'jester_hook',
            count: 1,
            placement: ItemPlacement.passiveRack,
          ),
        ],
        passiveRelicIds: ['jester_hook'],
      );
    runProgress.ownedJesters
      ..clear()
      ..add(
        RummiJesterCard(
          id: 'egg',
          displayName: 'Egg',
          rarity: RummiJesterRarity.common,
          baseCost: 5,
          effectText: 'Test sell hook fixture.',
          effectType: 'chips_bonus',
          trigger: 'onScore',
          conditionType: 'none',
          conditionValue: null,
          value: 10,
          xValue: null,
          mappedTileColors: [],
          mappedTileNumbers: [],
        ),
      );
    return ActiveRunRuntimeState(
      activeScene: ActiveRunScene.shop,
      difficulty: NewRunDifficulty.standard,
      session: base.session.copySnapshot(),
      runProgress: runProgress,
      stageStartSnapshot: base.stageStartSnapshot,
    );
  }

  static ActiveRunRuntimeState _buildMarketItemUseShop() {
    final base = _buildStage2MarketResume();
    final runProgress = base.runProgress.copySnapshot()
      ..gold = 4
      ..itemInventory = const RunInventoryState(
        ownedItems: [
          OwnedItemEntry(
            itemId: 'coin_cache',
            count: 1,
            placement: ItemPlacement.inventory,
          ),
        ],
      );
    runProgress
      ..ownedJesters.clear()
      ..shopOffers.clear();
    return ActiveRunRuntimeState(
      activeScene: ActiveRunScene.shop,
      difficulty: NewRunDifficulty.standard,
      session: base.session.copySnapshot(),
      runProgress: runProgress,
      stageStartSnapshot: base.stageStartSnapshot,
    );
  }

  static ActiveRunRuntimeState _buildInventoryQuickSlotBattle() {
    final base = _buildStage2ScoringSnapshot();
    final runProgress = base.runProgress.copySnapshot()
      ..itemInventory = const RunInventoryState(
        ownedItems: [
          OwnedItemEntry(
            itemId: 'board_scrap',
            count: 1,
            placement: ItemPlacement.quickSlot,
          ),
          OwnedItemEntry(
            itemId: 'hand_scrap',
            count: 1,
            placement: ItemPlacement.quickSlot,
          ),
          OwnedItemEntry(
            itemId: 'move_token',
            count: 1,
            placement: ItemPlacement.quickSlot,
          ),
          OwnedItemEntry(
            itemId: 'spare_pouch',
            count: 1,
            placement: ItemPlacement.passiveRack,
          ),
        ],
        quickSlotItemIds: ['board_scrap', 'hand_scrap', 'move_token'],
        passiveRelicIds: ['spare_pouch'],
      );
    return ActiveRunRuntimeState(
      activeScene: ActiveRunScene.battle,
      difficulty: NewRunDifficulty.standard,
      session: base.session.copySnapshot(),
      runProgress: runProgress,
      stageStartSnapshot: ActiveRunStageSnapshot(
        session: base.stageStartSnapshot.session.copySnapshot(),
        runProgress: runProgress.copySnapshot(),
      ),
    );
  }

  static ActiveRunRuntimeState _buildAnimationEffectsEyeCheck() {
    final base = _buildStage2ScoringSnapshot();
    final runProgress = base.runProgress.copySnapshot()
      ..itemInventory = const RunInventoryState(
        ownedItems: [
          OwnedItemEntry(
            itemId: 'board_scrap',
            count: 1,
            placement: ItemPlacement.quickSlot,
          ),
          OwnedItemEntry(
            itemId: 'hand_scrap',
            count: 1,
            placement: ItemPlacement.quickSlot,
          ),
          OwnedItemEntry(
            itemId: 'move_token',
            count: 1,
            placement: ItemPlacement.quickSlot,
          ),
          OwnedItemEntry(
            itemId: 'spare_pouch',
            count: 1,
            placement: ItemPlacement.passiveRack,
          ),
        ],
        quickSlotItemIds: ['board_scrap', 'hand_scrap', 'move_token'],
        passiveRelicIds: ['spare_pouch'],
      );
    return ActiveRunRuntimeState(
      activeScene: ActiveRunScene.battle,
      difficulty: NewRunDifficulty.standard,
      session: base.session.copySnapshot(),
      runProgress: runProgress,
      stageStartSnapshot: ActiveRunStageSnapshot(
        session: base.stageStartSnapshot.session.copySnapshot(),
        runProgress: runProgress.copySnapshot(),
      ),
    );
  }

  static ActiveRunRuntimeState _buildSettlementCashOutReady() {
    final board = RummiBoard();
    for (var row = 0; row < kBoardSize; row++) {
      for (var col = 0; col < kBoardSize; col++) {
        board.setCell(
          row,
          col,
          _tile(
            TileColor.values[(row + col) % TileColor.values.length],
            row + col + 1,
          ),
        );
      }
    }
    final session = RummiPokerGridSession.restored(
      runSeed: 2026050404,
      deckCopiesPerTile: kDefaultCopiesPerTile,
      maxHandSize: 1,
      runRandomState: SeededRandom(2026050404).state,
      blind: RummiBlindState(
        targetScore: 1,
        boardDiscardsRemaining: 4,
        handDiscardsRemaining: 2,
        scoreTowardBlind: 0,
      ),
      deck: PokerDeck.remainingAfterPlaced(
        board: board,
        random: Random(2026050404),
      ),
      board: board,
      hand: const [],
      eliminated: const [],
    );
    final runProgress = RummiRunProgress.restore(
      stageIndex: 1,
      gold: 0,
      rerollCost: RummiRunProgress.shopBaseRerollCost,
      ownedJesters: const [
        RummiJesterCard(
          id: 'crazy_jester',
          displayName: 'Crazy Jester',
          rarity: RummiJesterRarity.common,
          baseCost: 4,
          effectText: 'Played hand containing a Straight gives +12 Mult',
          effectType: 'mult_bonus',
          trigger: 'onScore',
          conditionType: 'straight',
          conditionValue: 'contains_straight',
          value: 12,
          xValue: null,
          mappedTileColors: [],
          mappedTileNumbers: [],
        ),
      ],
      shopOffers: const [],
      statefulValuesBySlot: const {},
      playedHandCounts: const <RummiHandRank, int>{},
      itemInventory: const RunInventoryState(
        ownedItems: [
          OwnedItemEntry(
            itemId: 'coin_funnel',
            count: 1,
            placement: ItemPlacement.equipped,
          ),
          OwnedItemEntry(
            itemId: 'hand_funnel',
            count: 1,
            placement: ItemPlacement.equipped,
          ),
        ],
        equippedItemIds: ['coin_funnel', 'hand_funnel'],
      ),
    );
    return ActiveRunRuntimeState(
      activeScene: ActiveRunScene.battle,
      difficulty: NewRunDifficulty.standard,
      session: session,
      runProgress: runProgress,
      stageStartSnapshot: ActiveRunStageSnapshot(
        session: session.copySnapshot(),
        runProgress: runProgress.copySnapshot(),
      ),
    );
  }

  static ActiveRunRuntimeState _buildSafetyNetExpiryGuard() {
    final board = RummiBoard();
    const ranks = [
      [1, 3, 6, 8, 11],
      [2, 5, 9, 12, 4],
      [7, 10, 13, 1, 5],
      [8, 11, 2, 6, 9],
      [2, 4, 7, 10, 13],
    ];
    for (var row = 0; row < kBoardSize; row++) {
      for (var col = 0; col < kBoardSize; col++) {
        board.setCell(
          row,
          col,
          _tile(
            TileColor.values[(row + col * 2) % TileColor.values.length],
            ranks[row][col],
          ),
        );
      }
    }
    final session = RummiPokerGridSession.restored(
      runSeed: 2026042501,
      deckCopiesPerTile: kDefaultCopiesPerTile,
      maxHandSize: 1,
      runRandomState: SeededRandom(2026042501).state,
      blind: RummiBlindState(
        targetScore: 480,
        boardDiscardsRemaining: 0,
        handDiscardsRemaining: 2,
        scoreTowardBlind: 0,
      ),
      deck: PokerDeck.remainingAfterPlaced(
        board: board,
        random: Random(2026042501),
      ),
      board: board,
      hand: const [],
      eliminated: const [],
    );
    final runProgress = RummiRunProgress.restore(
      stageIndex: 2,
      gold: 36,
      rerollCost: RummiRunProgress.shopBaseRerollCost,
      ownedJesters: const [],
      shopOffers: const [],
      statefulValuesBySlot: const {},
      playedHandCounts: const <RummiHandRank, int>{},
      itemInventory: const RunInventoryState(
        ownedItems: [
          OwnedItemEntry(
            itemId: 'safety_net',
            count: 1,
            placement: ItemPlacement.passiveRack,
          ),
        ],
        passiveRelicIds: ['safety_net'],
      ),
    );
    return ActiveRunRuntimeState(
      activeScene: ActiveRunScene.battle,
      difficulty: NewRunDifficulty.standard,
      session: session,
      runProgress: runProgress,
      stageStartSnapshot: ActiveRunStageSnapshot(
        session: session.copySnapshot(),
        runProgress: runProgress.copySnapshot(),
      ),
    );
  }

  static ActiveRunRuntimeState _buildBossRowConstraintPreview() {
    final board = RummiBoard()
      ..setCell(1, 0, _tile(TileColor.red, 1))
      ..setCell(1, 1, _tile(TileColor.blue, 2))
      ..setCell(1, 2, _tile(TileColor.black, 3))
      ..setCell(1, 3, _tile(TileColor.yellow, 4))
      ..setCell(1, 4, _tile(TileColor.red, 5))
      ..setCell(3, 1, _tile(TileColor.blue, 9))
      ..setCell(4, 3, _tile(TileColor.yellow, 12));
    return _buildBossLineConstraintPreview(
      seed: 2026050401,
      stageIndex: 2,
      board: board,
      modifier: RummiBossModifier.rowDampener,
    );
  }

  static ActiveRunRuntimeState _buildBossColumnConstraintPreview() {
    final board = RummiBoard()
      ..setCell(0, 2, _tile(TileColor.red, 1))
      ..setCell(1, 2, _tile(TileColor.blue, 2))
      ..setCell(2, 2, _tile(TileColor.black, 3))
      ..setCell(3, 2, _tile(TileColor.yellow, 4))
      ..setCell(4, 2, _tile(TileColor.red, 5))
      ..setCell(0, 4, _tile(TileColor.blue, 9))
      ..setCell(4, 0, _tile(TileColor.yellow, 12));
    return _buildBossLineConstraintPreview(
      seed: 2026050402,
      stageIndex: 4,
      board: board,
      modifier: RummiBossModifier.columnDampener,
    );
  }

  static ActiveRunRuntimeState _buildBossDiagonalConstraintPreview() {
    final board = RummiBoard()
      ..setCell(0, 0, _tile(TileColor.red, 1))
      ..setCell(1, 1, _tile(TileColor.blue, 2))
      ..setCell(2, 2, _tile(TileColor.black, 3))
      ..setCell(3, 3, _tile(TileColor.yellow, 4))
      ..setCell(4, 4, _tile(TileColor.red, 5))
      ..setCell(0, 4, _tile(TileColor.blue, 9))
      ..setCell(4, 0, _tile(TileColor.yellow, 12));
    return _buildBossLineConstraintPreview(
      seed: 2026050403,
      stageIndex: 6,
      board: board,
      modifier: RummiBossModifier.diagonalDampener,
    );
  }

  static ActiveRunRuntimeState _buildBossLineConstraintPreview({
    required int seed,
    required int stageIndex,
    required RummiBoard board,
    required RummiBossModifier modifier,
  }) {
    final session = RummiPokerGridSession.restored(
      runSeed: seed,
      deckCopiesPerTile: kDefaultCopiesPerTile,
      maxHandSize: 1,
      runRandomState: SeededRandom(seed).state,
      blind: RummiBlindState(
        targetScore: 285,
        boardDiscardsRemaining: 4,
        handDiscardsRemaining: 2,
        scoreTowardBlind: 0,
        bossModifier: modifier,
      ),
      deck: PokerDeck.remainingAfterPlaced(board: board, random: Random(seed)),
      board: board,
      hand: const [],
      eliminated: const [],
    );
    final runProgress = RummiRunProgress.restore(
      stageIndex: stageIndex,
      gold: 30,
      rerollCost: RummiRunProgress.shopBaseRerollCost,
      ownedJesters: const [],
      shopOffers: const [],
      statefulValuesBySlot: const {},
      playedHandCounts: const <RummiHandRank, int>{},
    )..currentStationBlindTierIndex = 2;
    return ActiveRunRuntimeState(
      activeScene: ActiveRunScene.battle,
      difficulty: NewRunDifficulty.standard,
      session: session,
      runProgress: runProgress,
      stageStartSnapshot: ActiveRunStageSnapshot(
        session: session.copySnapshot(),
        runProgress: runProgress.copySnapshot(),
      ),
    );
  }

  static Tile _tile(TileColor color, int number) =>
      Tile(color: color, number: number);
}
