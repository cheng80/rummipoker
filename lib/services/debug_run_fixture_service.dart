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
    this.autoTutorialsEnabled = false,
  });

  final String id;
  final String label;
  final String description;
  final ActiveRunRuntimeState Function() builder;
  final bool autoTutorialsEnabled;
}

class DebugRunFixtureService {
  DebugRunFixtureService._();

  static const String stage2ScoringSnapshot = 'stage2_scoring_snapshot';
  static const String stage2MarketResume = 'stage2_market_resume';
  static const String deckNeedleBattle = 'deck_needle_battle';
  static const String handCapacityIncreasePreviewBattle =
      'hand_capacity_increase_preview_battle';
  static const String handCapacityDeckControlBattle =
      'hand_capacity_deck_control_battle';
  static const String marketModifierShop = 'market_modifier_shop';
  static const String slotUnlockMarket = 'slot_unlock_market';
  static const String safetyNetExpiryGuard = 'safety_net_expiry_guard';
  static const String gameOverInsightReady = 'game_over_insight_ready';
  static const String animationEffectsEyeCheck = 'animation_effects_eye_check';
  static const String finalBossCashOutReady = 'final_boss_cash_out_ready';
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
          'Stage 2 / Gold 36 / Run Call + Face Battery / 손패 비어 있음 / 덱 34',
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
      id: handCapacityIncreasePreviewBattle,
      label: '손패 증가 연출 전투',
      description: '전투 진입 후 손패 1/1에서 1/3으로 자동 증가 / 드로우 버튼 pulse 검증용',
      builder: _buildHandCapacityIncreasePreviewBattle,
    ),
    DebugRunFixtureDefinition(
      id: handCapacityDeckControlBattle,
      label: '손패 증가 + 덱 제어 전투',
      description:
          '손패 1/3 + Travel Pouch + Deck Needle / 드로우 잔여 칸과 덱 버림 UI 검증용',
      builder: _buildHandCapacityDeckControlBattle,
    ),
    DebugRunFixtureDefinition(
      id: marketModifierShop,
      label: 'Market Modifier 상점',
      description: '리롤/구매 할인 + Item offer 4칸 검증용',
      builder: _buildMarketModifierShop,
    ),
    DebugRunFixtureDefinition(
      id: slotUnlockMarket,
      label: '슬롯 해금 Market',
      description: 'S2/S4/S6 Boss 보상 슬롯 해금 배너와 Jester/Item/Passive 열린 상태 검증용',
      builder: _buildSlotUnlockMarket,
    ),
    DebugRunFixtureDefinition(
      id: safetyNetExpiryGuard,
      label: 'Safety Net 종료 방지',
      description: 'Safety Net 보유 / 보드가 꽉 찬 종료 위기 구조 검증용',
      builder: _buildSafetyNetExpiryGuard,
    ),
    DebugRunFixtureDefinition(
      id: gameOverInsightReady,
      label: '게임오버 기억 카드 체크',
      description: '보드 꽉 참 + 보드 버림 0 / 패배 보상 카드 검증용',
      builder: _buildGameOverInsightReady,
    ),
    DebugRunFixtureDefinition(
      id: animationEffectsEyeCheck,
      label: '연출 눈검증 전투',
      description:
          '점수 preview pulse / line confirm particle / quick item toast 검증용',
      builder: _buildAnimationEffectsEyeCheck,
    ),
    DebugRunFixtureDefinition(
      id: finalBossCashOutReady,
      label: '최종 Boss 런 완료 체크',
      description: 'S8 Boss 확정 1회로 런 완료 + 기억 카드 보상 시트 검증용',
      builder: _buildFinalBossCashOutReady,
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

  static bool shouldAutoStartTutorials(String? fixtureId) {
    if (fixtureId == null) return true;
    return find(fixtureId)?.autoTutorialsEnabled ?? false;
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
          displayName: 'Run Call',
          rarity: RummiJesterRarity.common,
          baseCost: 4,
          effectText: 'Scoring a run line gives score +60%',
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
          displayName: 'Face Battery',
          rarity: RummiJesterRarity.common,
          baseCost: 4,
          effectText: 'Each 11-13 tile in the scoring line gives +30 Chips',
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
            displayName: 'Momentum Meter',
            rarity: RummiJesterRarity.common,
            baseCost: 4,
            effectText: 'Confirm/discard changes current score by 5%',
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
            displayName: 'Fading Boost',
            rarity: RummiJesterRarity.common,
            baseCost: 5,
            effectText: 'Starts at score +100%, decreases by 20% each round',
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

  static ActiveRunRuntimeState _buildHandCapacityIncreasePreviewBattle() {
    final base = _buildStage2ScoringSnapshot();
    final deckTop = [
      _tile(TileColor.black, 10),
      _tile(TileColor.blue, 7),
      _tile(TileColor.red, 7),
      _tile(TileColor.black, 7),
      _tile(TileColor.red, 1),
    ];
    final session = RummiPokerGridSession.restored(
      runSeed: base.session.runSeed,
      deckCopiesPerTile: kDefaultCopiesPerTile,
      maxHandSize: 1,
      runRandomState: base.session.runRandom.state,
      ruleset: base.session.ruleset,
      blind: base.session.blind.copyWith(),
      deck: PokerDeck.fromSnapshot(deckTop),
      board: base.session.board.copy(),
      hand: [_tile(TileColor.yellow, 7)],
      eliminated: List<Tile>.from(base.session.eliminated),
      boardMoveHistory: List<BoardMoveRecord>.from(
        base.session.boardMoveHistory,
      ),
    );
    final runProgress = base.runProgress.copySnapshot()
      ..itemInventory = const RunInventoryState(
        ownedItems: [
          OwnedItemEntry(
            itemId: 'battle_pouch',
            count: 1,
            placement: ItemPlacement.quickSlot,
          ),
        ],
        quickSlotItemIds: ['battle_pouch'],
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

  static ActiveRunRuntimeState _buildHandCapacityDeckControlBattle() {
    final base = _buildStage2ScoringSnapshot();
    final deckTop = [
      _tile(TileColor.black, 10),
      _tile(TileColor.yellow, 3),
      _tile(TileColor.blue, 7),
      _tile(TileColor.red, 7),
      _tile(TileColor.black, 7),
      _tile(TileColor.red, 1),
    ];
    final hand = [_tile(TileColor.yellow, 7)];
    final session = RummiPokerGridSession.restored(
      runSeed: base.session.runSeed,
      deckCopiesPerTile: kDefaultCopiesPerTile,
      maxHandSize: 3,
      runRandomState: base.session.runRandom.state,
      ruleset: base.session.ruleset,
      blind: base.session.blind.copyWith(),
      deck: PokerDeck.fromSnapshot(deckTop),
      board: base.session.board.copy(),
      hand: hand,
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
          OwnedItemEntry(
            itemId: 'travel_pouch',
            count: 1,
            placement: ItemPlacement.passiveRack,
          ),
        ],
        quickSlotItemIds: ['deck_needle'],
        passiveRelicIds: ['travel_pouch'],
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
            displayName: 'Momentum Meter',
            rarity: RummiJesterRarity.common,
            baseCost: 4,
            effectText: 'Confirm/discard changes current score by 5%',
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
            displayName: 'Fading Boost',
            rarity: RummiJesterRarity.common,
            baseCost: 5,
            effectText: 'Starts at score +100%, decreases by 20% each round',
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

  static ActiveRunRuntimeState _buildSlotUnlockMarket() {
    final base = _buildStage2MarketResume();
    final runProgress = base.runProgress.copySnapshot()
      ..stageIndex = 6
      ..gold = 64;
    runProgress.unlockSlotCapacity(RummiSlotUnlockKind.quickSlot);
    runProgress.unlockSlotCapacity(RummiSlotUnlockKind.passiveRelic);
    runProgress.unlockSlotCapacity(RummiSlotUnlockKind.jester);

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
          displayName: 'Run Call',
          rarity: RummiJesterRarity.common,
          baseCost: 4,
          effectText: 'Scoring a run line gives score +60%',
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
    return _buildBoardFullExpiryState(
      runSeed: 2026042501,
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
  }

  static ActiveRunRuntimeState _buildGameOverInsightReady() {
    return _buildBoardFullExpiryState(
      runSeed: 2026050501,
      itemInventory: const RunInventoryState(),
    );
  }

  static ActiveRunRuntimeState _buildBoardFullExpiryState({
    required int runSeed,
    required RunInventoryState itemInventory,
  }) {
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
      runSeed: runSeed,
      deckCopiesPerTile: kDefaultCopiesPerTile,
      maxHandSize: 1,
      runRandomState: SeededRandom(runSeed).state,
      blind: RummiBlindState(
        targetScore: 480,
        boardDiscardsRemaining: 0,
        handDiscardsRemaining: 2,
        scoreTowardBlind: 0,
      ),
      deck: PokerDeck.remainingAfterPlaced(
        board: board,
        random: Random(runSeed),
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
      itemInventory: itemInventory,
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

  static ActiveRunRuntimeState _buildFinalBossCashOutReady() {
    final runtime = _buildSettlementCashOutReady();
    final session = runtime.session.copySnapshot();
    session.blind.bossModifier = RummiBossModifier.confirmCountTax;
    final runProgress = runtime.runProgress.copySnapshot()
      ..stageIndex = 8
      ..currentStationBlindTierIndex = 2;
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
