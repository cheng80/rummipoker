part of 'debug_run_fixture_service.dart';

ActiveRunRuntimeState _buildStage2ScoringSnapshot() {
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

ActiveRunRuntimeState _buildStage2MarketResume() {
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

ActiveRunRuntimeState _buildDeckNeedleBattle() {
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
    boardMoveHistory: List<BoardMoveRecord>.from(base.session.boardMoveHistory),
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

ActiveRunRuntimeState _buildHandCapacityIncreasePreviewBattle() {
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
    boardMoveHistory: List<BoardMoveRecord>.from(base.session.boardMoveHistory),
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

ActiveRunRuntimeState _buildHandCapacityDeckControlBattle() {
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
    boardMoveHistory: List<BoardMoveRecord>.from(base.session.boardMoveHistory),
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

ActiveRunRuntimeState _buildMarketModifierShop() {
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
          itemId: 'market_compass',
          count: 1,
          placement: ItemPlacement.passiveRack,
        ),
      ],
      passiveRelicIds: ['merchant_stamp', 'market_compass'],
      equippedItemIds: [],
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

  return ActiveRunRuntimeState(
    activeScene: ActiveRunScene.shop,
    difficulty: NewRunDifficulty.standard,
    session: base.session.copySnapshot(),
    runProgress: runProgress,
    stageStartSnapshot: base.stageStartSnapshot,
  );
}

ActiveRunRuntimeState _buildScreenshotRunGrowthBattle() {
  final base = _buildHandCapacityDeckControlBattle();
  final runProgress = base.runProgress.copySnapshot()
    ..stageIndex = 4
    ..gold = 42;
  for (var i = 0; i < 4; i++) {
    runProgress.recordHandRankCompletion(RummiHandRank.straight);
  }
  for (var i = 0; i < 3; i++) {
    runProgress.recordHandRankCompletion(RummiHandRank.flush);
  }
  for (var i = 0; i < 2; i++) {
    runProgress.recordHandRankCompletion(RummiHandRank.fullHouse);
  }
  runProgress.recordHandRankCompletion(RummiHandRank.twoPair);
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

ActiveRunRuntimeState _buildSlotUnlockMarket() {
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

ActiveRunRuntimeState _buildAnimationEffectsEyeCheck() {
  final base = _buildStage2ScoringSnapshot();
  final runProgress = base.runProgress.copySnapshot()
    ..unlockedQuickSlotCapacity = RunInventoryState.maxQuickSlotCapacity
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
      ],
      quickSlotItemIds: ['board_scrap', 'hand_scrap', 'move_token'],
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

ActiveRunRuntimeState _buildItemMotionEyeCheck() {
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
    maxHandSize: 1,
    runRandomState: base.session.runRandom.state,
    ruleset: base.session.ruleset,
    blind: base.session.blind.copyWith(
      boardMovesRemaining: 2,
      handDiscardsRemaining: 2,
      boardDiscardsRemaining: 4,
    ),
    deck: PokerDeck.fromSnapshot(deckTop),
    board: base.session.board.copy(),
    hand: const [],
    eliminated: List<Tile>.from(base.session.eliminated),
    boardMoveHistory: List<BoardMoveRecord>.from(base.session.boardMoveHistory),
  );
  final runProgress = base.runProgress.copySnapshot()
    ..unlockedQuickSlotCapacity = RunInventoryState.maxQuickSlotCapacity
    ..itemInventory = const RunInventoryState(
      ownedItems: [
        OwnedItemEntry(
          itemId: 'deck_needle',
          count: 1,
          placement: ItemPlacement.quickSlot,
        ),
        OwnedItemEntry(
          itemId: 'emergency_draw',
          count: 1,
          placement: ItemPlacement.quickSlot,
        ),
        OwnedItemEntry(
          itemId: 'slide_wax',
          count: 1,
          placement: ItemPlacement.quickSlot,
        ),
      ],
      quickSlotItemIds: ['deck_needle', 'emergency_draw', 'slide_wax'],
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

ActiveRunRuntimeState _buildNextConfirmMotionEyeCheck() {
  final base = _buildStage2ScoringSnapshot();
  final runProgress = base.runProgress.copySnapshot()
    ..itemInventory = const RunInventoryState(
      ownedItems: [
        OwnedItemEntry(
          itemId: 'straight_oil',
          count: 1,
          placement: ItemPlacement.quickSlot,
        ),
      ],
      quickSlotItemIds: ['straight_oil'],
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

ActiveRunRuntimeState _buildMarketItemMotionEyeCheck() {
  final base = _buildStage2ScoringSnapshot();
  final runProgress = base.runProgress.copySnapshot()
    ..gold = 18
    ..itemInventory = const RunInventoryState(
      ownedItems: [
        OwnedItemEntry(
          itemId: 'coin_cache',
          count: 1,
          placement: ItemPlacement.inventory,
        ),
        OwnedItemEntry(
          itemId: 'trade_ticket',
          count: 1,
          placement: ItemPlacement.inventory,
        ),
      ],
    );
  return ActiveRunRuntimeState(
    activeScene: ActiveRunScene.shop,
    difficulty: NewRunDifficulty.standard,
    session: base.session.copySnapshot(),
    runProgress: runProgress,
    stageStartSnapshot: base.stageStartSnapshot,
  );
}

ActiveRunRuntimeState _buildSpecialTileMarketPreview() {
  final base = _buildStage2ScoringSnapshot();
  final runProgress = base.runProgress.copySnapshot()
    ..stageIndex = 6
    ..gold = 24
    ..tileOffers.addAll(const [
      Tile(
        color: TileColor.red,
        number: 7,
        enhancement: TileEnhancement.glassTile,
        seal: TileSeal.redSeal,
      ),
      Tile(
        color: TileColor.blue,
        number: 9,
        enhancement: TileEnhancement.chipInlaid,
        seal: TileSeal.blueSeal,
      ),
      Tile(
        color: TileColor.yellow,
        number: 4,
        enhancement: TileEnhancement.goldTile,
      ),
    ])
    ..addedDeckTiles.addAll(const [
      Tile(
        color: TileColor.black,
        number: 12,
        enhancement: TileEnhancement.scoreGilded,
        seal: TileSeal.blueSeal,
      ),
    ]);
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

ActiveRunRuntimeState _buildSpecialTileBattlePreview() {
  final board = RummiBoard()
    ..setCell(
      2,
      0,
      const Tile(
        color: TileColor.red,
        number: 1,
        enhancement: TileEnhancement.chipInlaid,
        seal: TileSeal.blueSeal,
      ),
    )
    ..setCell(
      2,
      1,
      const Tile(
        color: TileColor.blue,
        number: 2,
        enhancement: TileEnhancement.glassTile,
        seal: TileSeal.redSeal,
      ),
    )
    ..setCell(2, 2, _tile(TileColor.yellow, 3))
    ..setCell(
      2,
      3,
      const Tile(
        color: TileColor.black,
        number: 4,
        enhancement: TileEnhancement.goldTile,
      ),
    )
    ..setCell(2, 4, _tile(TileColor.red, 5))
    ..setCell(
      4,
      0,
      const Tile(
        color: TileColor.black,
        number: 12,
        enhancement: TileEnhancement.scoreGilded,
      ),
    );
  final hand = const [
    Tile(
      color: TileColor.blue,
      number: 9,
      enhancement: TileEnhancement.chipInlaid,
      seal: TileSeal.blueSeal,
    ),
    Tile(
      color: TileColor.yellow,
      number: 11,
      enhancement: TileEnhancement.goldTile,
    ),
  ];
  final session = RummiPokerGridSession.restored(
    runSeed: 2026052301,
    deckCopiesPerTile: kDefaultCopiesPerTile,
    maxHandSize: 3,
    runRandomState: SeededRandom(2026052301).state,
    blind: RummiBlindState(
      targetScore: 720,
      boardDiscardsRemaining: 4,
      handDiscardsRemaining: 2,
      scoreTowardBlind: 210,
      bossModifier: RummiBossModifier.redDampener,
    ),
    deck: PokerDeck.remainingAfterPlaced(
      board: board,
      hand: hand,
      random: Random(2026052301),
    ),
    board: board,
    hand: hand,
    eliminated: const [],
  );
  final runProgress = RummiRunProgress.restore(
    stageIndex: 6,
    gold: 28,
    rerollCost: RummiRunProgress.shopBaseRerollCost,
    ownedJesters: const [],
    shopOffers: const [],
    statefulValuesBySlot: const {},
    playedHandCounts: const <RummiHandRank, int>{},
    addedDeckTiles: const [
      Tile(
        color: TileColor.red,
        number: 1,
        enhancement: TileEnhancement.chipInlaid,
        seal: TileSeal.blueSeal,
      ),
      Tile(
        color: TileColor.blue,
        number: 2,
        enhancement: TileEnhancement.glassTile,
        seal: TileSeal.redSeal,
      ),
      Tile(
        color: TileColor.black,
        number: 12,
        enhancement: TileEnhancement.scoreGilded,
      ),
    ],
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

ActiveRunRuntimeState _buildLineMemoryMarketPreview() {
  final base = _buildStage2MarketResume();
  final runProgress = base.runProgress.copySnapshot()
    ..stageIndex = 4
    ..gold = 24;
  runProgress.pinCurrentItemOfferKeys([
    RummiMarketModifierState.itemOfferKey(
      ItemPlacement.quickSlot,
      'line_memory',
    ),
  ]);
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

ActiveRunRuntimeState _buildLineMemoryBattlePreview() {
  final board = RummiBoard()
    ..setCell(1, 0, _tile(TileColor.red, 1))
    ..setCell(1, 1, _tile(TileColor.red, 2))
    ..setCell(1, 2, _tile(TileColor.red, 3))
    ..setCell(1, 3, _tile(TileColor.red, 4))
    ..setCell(1, 4, _tile(TileColor.red, 5))
    ..setCell(3, 1, _tile(TileColor.blue, 9))
    ..setCell(4, 3, _tile(TileColor.yellow, 12));
  final session = RummiPokerGridSession.restored(
    runSeed: 2026053101,
    deckCopiesPerTile: kDefaultCopiesPerTile,
    maxHandSize: 2,
    runRandomState: SeededRandom(2026053101).state,
    blind: RummiBlindState(
      targetScore: 720,
      boardDiscardsRemaining: 4,
      handDiscardsRemaining: 2,
      scoreTowardBlind: 0,
    ),
    deck: PokerDeck.remainingAfterPlaced(
      board: board,
      random: Random(2026053101),
    ),
    board: board,
    hand: const [],
    eliminated: const [],
  );
  final runProgress = RummiRunProgress.restore(
    stageIndex: 4,
    gold: 24,
    rerollCost: RummiRunProgress.shopBaseRerollCost,
    ownedJesters: const [],
    shopOffers: const [],
    statefulValuesBySlot: const {},
    playedHandCounts: const <RummiHandRank, int>{},
    itemInventory: const RunInventoryState(
      ownedItems: [
        OwnedItemEntry(
          itemId: 'line_memory',
          count: 1,
          placement: ItemPlacement.quickSlot,
        ),
      ],
      quickSlotItemIds: ['line_memory'],
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

ActiveRunRuntimeState _buildRitualGrowthCopyBattlePreview() {
  return _buildRitualV1BattlePreview(
    runSeed: 2026060101,
    itemIds: const ['line_memory', 'keystone_copy', 'rank_echo'],
  );
}

ActiveRunRuntimeState _buildRitualSealOverrideBattlePreview() {
  return _buildRitualV1BattlePreview(
    runSeed: 2026060102,
    itemIds: const ['line_seal_stamp', 'gold_seal_stamp', 'rank_concord'],
  );
}

ActiveRunRuntimeState _buildRitualPruneBurnBattlePreview() {
  return _buildRitualV1BattlePreview(
    runSeed: 2026060103,
    itemIds: const ['line_pruner', 'deadwood_burn', 'number_mask'],
  );
}

ActiveRunRuntimeState _buildRitualV1BattlePreview({
  required int runSeed,
  required List<String> itemIds,
}) {
  final board = RummiBoard()
    // Scoring straight-flush line for growth and scoring-only rituals.
    ..setCell(0, 0, _tile(TileColor.red, 1))
    ..setCell(0, 1, _tile(TileColor.red, 2))
    ..setCell(0, 2, _tile(TileColor.red, 3))
    ..setCell(0, 3, _tile(TileColor.red, 4))
    ..setCell(0, 4, _tile(TileColor.red, 5))
    // Three occupied tiles that are not a scoring hand, for board-line rituals.
    ..setCell(2, 0, _tile(TileColor.blue, 2))
    ..setCell(2, 2, _tile(TileColor.yellow, 7))
    ..setCell(2, 4, _tile(TileColor.black, 11))
    // Three of a kind line for override comparison.
    ..setCell(4, 1, _tile(TileColor.blue, 9))
    ..setCell(4, 2, _tile(TileColor.red, 9))
    ..setCell(4, 3, _tile(TileColor.black, 9));
  final session = RummiPokerGridSession.restored(
    runSeed: runSeed,
    deckCopiesPerTile: kDefaultCopiesPerTile,
    maxHandSize: 2,
    runRandomState: SeededRandom(runSeed).state,
    blind: RummiBlindState(
      targetScore: 720,
      boardDiscardsRemaining: 4,
      handDiscardsRemaining: 2,
      scoreTowardBlind: 0,
    ),
    deck: PokerDeck.remainingAfterPlaced(board: board, random: Random(runSeed)),
    board: board,
    hand: const [],
    eliminated: const [],
  );
  final runProgress = RummiRunProgress.restore(
    stageIndex: 4,
    gold: 24,
    rerollCost: RummiRunProgress.shopBaseRerollCost,
    ownedJesters: const [],
    shopOffers: const [],
    statefulValuesBySlot: const {},
    playedHandCounts: const <RummiHandRank, int>{},
    unlockedQuickSlotCapacity: RunInventoryState.maxQuickSlotCapacity,
    itemInventory: RunInventoryState(
      ownedItems: [
        for (final itemId in itemIds)
          OwnedItemEntry(
            itemId: itemId,
            count: 1,
            placement: ItemPlacement.quickSlot,
          ),
      ],
      quickSlotItemIds: itemIds,
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

ActiveRunRuntimeState _buildSettlementCashOutReady() {
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

ActiveRunRuntimeState _buildSafetyNetExpiryGuard() {
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

ActiveRunRuntimeState _buildGameOverInsightReady() {
  return _buildBoardFullExpiryState(
    runSeed: 2026050501,
    itemInventory: const RunInventoryState(),
  );
}

ActiveRunRuntimeState _buildBoardFullExpiryState({
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
    deck: PokerDeck.remainingAfterPlaced(board: board, random: Random(runSeed)),
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

ActiveRunRuntimeState _buildFinalBossCashOutReady() {
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

ActiveRunRuntimeState _buildBossRowConstraintPreview() {
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

ActiveRunRuntimeState _buildBossColumnConstraintPreview() {
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

ActiveRunRuntimeState _buildBossDiagonalConstraintPreview() {
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

ActiveRunRuntimeState _buildBossLineConstraintPreview({
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

Tile _tile(TileColor color, int number) => Tile(color: color, number: number);
