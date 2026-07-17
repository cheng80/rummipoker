part of 'jester_meta.dart';

class RummiRunProgress {
  RummiRunProgress();

  RummiRunProgress.restore({
    required this.stageIndex,
    this.currentStationBlindTierIndex = 0,
    this.runCompletionRewardClaimed = false,
    String? runClaimId,
    this.settlementReceiptKey,
    this.settlementReceipt,
    required this.gold,
    required this.rerollCost,
    int? tileRerollCost,
    int? itemRerollCost,
    int? quickSlotRerollCost,
    int? passiveRerollCost,
    int? toolRerollCost,
    int? gearRerollCost,
    required List<RummiJesterCard> ownedJesters,
    required List<RummiShopOffer> shopOffers,
    required Map<int, int> statefulValuesBySlot,
    required Map<RummiHandRank, int> playedHandCounts,
    Map<RummiHandRank, RummiHandGrowthState> handGrowthStates = const {},
    Map<RummiHandRank, int> stationRankFinalScores = const {},
    Set<String> overkillGrowthClaimedStationKeys = const <String>{},
    List<Tile> addedDeckTiles = const [],
    List<Tile> tileOffers = const [],
    this.pendingBossTileReward = false,
    this.firstShopRerollDiscountConsumed = false,
    Set<String> firstShopRerollDiscountConsumedLanes = const <String>{},
    int? unlockedJesterSlots,
    int? unlockedQuickSlotCapacity,
    int? unlockedPassiveRelicCapacity,
    Set<RummiSlotUnlockKind> pendingSlotUnlockPresentations =
        const <RummiSlotUnlockKind>{},
    this.itemInventory = const RunInventoryState(),
    this.marketModifiers = const RummiMarketModifierState(),
    Set<String> seenMarketJesterIds = const <String>{},
    Set<String> seenMarketItemIds = const <String>{},
    Set<String> boughtJesterIds = const <String>{},
    Set<String> boughtItemIds = const <String>{},
    Set<String> seenBossModifierIds = const <String>{},
    Set<String> clearedStationKeys = const <String>{},
  }) {
    this.runClaimId = runClaimId ?? _newRunClaimId();
    this.unlockedJesterSlots = (unlockedJesterSlots ?? baseUnlockedJesterSlots)
        .clamp(baseUnlockedJesterSlots, maxJesterSlots)
        .toInt();
    this.unlockedQuickSlotCapacity =
        (unlockedQuickSlotCapacity ??
                RunInventoryState.defaultQuickSlotCapacity)
            .clamp(
              RunInventoryState.defaultQuickSlotCapacity,
              RunInventoryState.maxQuickSlotCapacity,
            )
            .toInt();
    this.unlockedPassiveRelicCapacity =
        (unlockedPassiveRelicCapacity ??
                RunInventoryState.defaultPassiveRelicCapacity)
            .clamp(
              RunInventoryState.defaultPassiveRelicCapacity,
              RunInventoryState.maxPassiveRelicCapacity,
            )
            .toInt();
    this.itemRerollCost = itemRerollCost ?? rerollCost;
    this.tileRerollCost = tileRerollCost ?? rerollCost;
    this.quickSlotRerollCost =
        quickSlotRerollCost ?? itemRerollCost ?? rerollCost;
    this.passiveRerollCost = passiveRerollCost ?? itemRerollCost ?? rerollCost;
    this.toolRerollCost = toolRerollCost ?? itemRerollCost ?? rerollCost;
    this.gearRerollCost = gearRerollCost ?? itemRerollCost ?? rerollCost;
    this.ownedJesters.addAll(ownedJesters);
    this.shopOffers.addAll(shopOffers);
    _statefulValuesBySlot.addAll(statefulValuesBySlot);
    _playedHandCounts.addAll(playedHandCounts);
    if (handGrowthStates.isEmpty) {
      for (final entry in playedHandCounts.entries) {
        if (isDeadLineRank(entry.key)) continue;
        _handGrowthStates[entry.key] = RummiHandGrowthState.fromCompletedCount(
          entry.key,
          entry.value,
        );
      }
    } else {
      _handGrowthStates.addAll(handGrowthStates);
    }
    _stationRankFinalScores.addAll(stationRankFinalScores);
    _overkillGrowthClaimedStationKeys.addAll(overkillGrowthClaimedStationKeys);
    this.addedDeckTiles.addAll(addedDeckTiles);
    this.tileOffers.addAll(tileOffers);
    if (firstShopRerollDiscountConsumedLanes.isEmpty &&
        firstShopRerollDiscountConsumed) {
      _firstShopRerollDiscountConsumedLanes.addAll(_marketRerollLaneKeys);
    } else {
      _firstShopRerollDiscountConsumedLanes.addAll(
        firstShopRerollDiscountConsumedLanes.where(
          _marketRerollLaneKeys.contains,
        ),
      );
      if (_firstShopRerollDiscountConsumedLanes.isNotEmpty) {
        firstShopRerollDiscountConsumed = true;
        _firstShopRerollDiscountConsumedLanes.addAll(_marketRerollLaneKeys);
      }
    }
    _pendingSlotUnlockPresentations.addAll(pendingSlotUnlockPresentations);
    this.seenMarketJesterIds = Set<String>.from(seenMarketJesterIds);
    this.seenMarketItemIds = Set<String>.from(seenMarketItemIds);
    this.boughtJesterIds = Set<String>.from(boughtJesterIds);
    this.boughtItemIds = Set<String>.from(boughtItemIds);
    this.seenBossModifierIds = Set<String>.from(seenBossModifierIds);
    this.clearedStationKeys = Set<String>.from(clearedStationKeys);
  }

  static const int maxJesterSlots = 5;
  static const int baseUnlockedJesterSlots = 4;
  static const int stageClearGoldBase = RummiEconomyConfig.stageClearGoldBase;
  static const int remainingBoardDiscardGoldBonus =
      RummiEconomyConfig.remainingBoardDiscardGoldBonus;
  static const int remainingHandDiscardGoldBonus =
      RummiEconomyConfig.remainingHandDiscardGoldBonus;
  static const int remainingBoardMoveGoldBonus =
      RummiEconomyConfig.remainingBoardMoveGoldBonus;
  static const int shopBaseRerollCost = RummiEconomyConfig.shopBaseRerollCost;
  static const int shopRerollCostStep = RummiEconomyConfig.shopRerollCostStep;
  static const String _jesterRerollLaneKey = 'jester';
  static const String _tileRerollLaneKey = 'tile';
  static const String _quickSlotRerollLaneKey = 'quickSlot';
  static const String _passiveRerollLaneKey = 'passive';
  static const String _toolRerollLaneKey = 'tool';
  static const String _gearRerollLaneKey = 'gear';
  static const Set<String> _marketRerollLaneKeys = <String>{
    _jesterRerollLaneKey,
    _tileRerollLaneKey,
    _quickSlotRerollLaneKey,
    _passiveRerollLaneKey,
    _toolRerollLaneKey,
    _gearRerollLaneKey,
  };

  int stageIndex = 1;
  int currentStationBlindTierIndex = 0;
  bool runCompletionRewardClaimed = false;
  String runClaimId = _newRunClaimId();
  String? settlementReceiptKey;
  RummiCashOutBreakdown? settlementReceipt;
  int gold = RummiEconomyConfig.startingGold;
  int rerollCost = shopBaseRerollCost;
  int tileRerollCost = shopBaseRerollCost;
  int itemRerollCost = shopBaseRerollCost;
  int quickSlotRerollCost = shopBaseRerollCost;
  int passiveRerollCost = shopBaseRerollCost;
  int toolRerollCost = shopBaseRerollCost;
  int gearRerollCost = shopBaseRerollCost;
  RunInventoryState itemInventory = const RunInventoryState();
  RummiMarketModifierState marketModifiers = const RummiMarketModifierState();
  Set<String> seenMarketJesterIds = <String>{};
  Set<String> seenMarketItemIds = <String>{};
  Set<String> boughtJesterIds = <String>{};
  Set<String> boughtItemIds = <String>{};
  Set<String> seenBossModifierIds = <String>{};
  Set<String> clearedStationKeys = <String>{};
  int unlockedJesterSlots = baseUnlockedJesterSlots;
  int unlockedQuickSlotCapacity = RunInventoryState.defaultQuickSlotCapacity;
  int unlockedPassiveRelicCapacity =
      RunInventoryState.defaultPassiveRelicCapacity;
  final List<RummiJesterCard> ownedJesters = <RummiJesterCard>[];
  final List<RummiShopOffer> shopOffers = <RummiShopOffer>[];
  final List<Tile> addedDeckTiles = <Tile>[];
  final List<Tile> tileOffers = <Tile>[];
  bool pendingBossTileReward = false;
  bool firstShopRerollDiscountConsumed = false;
  final Set<String> _firstShopRerollDiscountConsumedLanes = <String>{};
  final Map<int, int> _statefulValuesBySlot = <int, int>{};
  final Map<RummiHandRank, int> _playedHandCounts = <RummiHandRank, int>{};
  final Map<RummiHandRank, RummiHandGrowthState> _handGrowthStates =
      <RummiHandRank, RummiHandGrowthState>{};
  final Map<RummiHandRank, int> _stationRankFinalScores =
      <RummiHandRank, int>{};
  final Set<String> _overkillGrowthClaimedStationKeys = <String>{};
  final Set<RummiSlotUnlockKind> _pendingSlotUnlockPresentations =
      <RummiSlotUnlockKind>{};

  Map<int, int> snapshotStatefulValuesBySlot() =>
      Map<int, int>.unmodifiable(_statefulValuesBySlot);

  Map<RummiHandRank, int> snapshotPlayedHandCounts() =>
      Map<RummiHandRank, int>.unmodifiable(_playedHandCounts);

  Map<RummiHandRank, RummiHandGrowthState> snapshotHandGrowthStates() =>
      Map<RummiHandRank, RummiHandGrowthState>.unmodifiable(_handGrowthStates);

  Map<RummiHandRank, int> snapshotStationRankFinalScores() =>
      Map<RummiHandRank, int>.unmodifiable(_stationRankFinalScores);

  Set<String> snapshotOverkillGrowthClaimedStationKeys() =>
      Set<String>.unmodifiable(_overkillGrowthClaimedStationKeys);

  Set<String> snapshotFirstShopRerollDiscountConsumedLanes() =>
      Set<String>.unmodifiable(_firstShopRerollDiscountConsumedLanes);

  Set<RummiSlotUnlockKind> snapshotPendingSlotUnlockPresentations() =>
      Set<RummiSlotUnlockKind>.unmodifiable(_pendingSlotUnlockPresentations);

  void applyChallengeCarryover({
    Map<RummiHandRank, int> playedHandCounts = const <RummiHandRank, int>{},
    Map<RummiHandRank, RummiHandGrowthState> handGrowthStates =
        const <RummiHandRank, RummiHandGrowthState>{},
    List<Tile> addedDeckTiles = const <Tile>[],
  }) {
    _playedHandCounts
      ..clear()
      ..addAll(playedHandCounts);
    _handGrowthStates
      ..clear()
      ..addAll(handGrowthStates);
    this.addedDeckTiles
      ..clear()
      ..addAll(addedDeckTiles);
  }

  bool addHandRankProgress(RummiHandRank rank, {int amount = 1}) {
    if (amount <= 0 || isDeadLineRank(rank)) {
      return false;
    }
    final current =
        _handGrowthStates[rank] ?? RummiHandGrowthState.initial(rank);
    _handGrowthStates[rank] = current.addProgress(rank, amount);
    return true;
  }

  bool recordHandRankCompletion(RummiHandRank rank) {
    _playedHandCounts.update(rank, (value) => value + 1, ifAbsent: () => 1);
    return addHandRankProgress(rank);
  }

  RummiRunProgress copySnapshot() {
    return RummiRunProgress.restore(
      stageIndex: stageIndex,
      currentStationBlindTierIndex: currentStationBlindTierIndex,
      runCompletionRewardClaimed: runCompletionRewardClaimed,
      runClaimId: runClaimId,
      settlementReceiptKey: settlementReceiptKey,
      settlementReceipt: settlementReceipt,
      gold: gold,
      rerollCost: rerollCost,
      itemRerollCost: itemRerollCost,
      quickSlotRerollCost: quickSlotRerollCost,
      passiveRerollCost: passiveRerollCost,
      toolRerollCost: toolRerollCost,
      gearRerollCost: gearRerollCost,
      ownedJesters: List<RummiJesterCard>.from(ownedJesters),
      shopOffers: shopOffers
          .map(
            (offer) => RummiShopOffer(
              slotIndex: offer.slotIndex,
              card: offer.card,
              price: offer.price,
            ),
          )
          .toList(growable: false),
      statefulValuesBySlot: Map<int, int>.from(_statefulValuesBySlot),
      playedHandCounts: Map<RummiHandRank, int>.from(_playedHandCounts),
      handGrowthStates: Map<RummiHandRank, RummiHandGrowthState>.from(
        _handGrowthStates,
      ),
      stationRankFinalScores: Map<RummiHandRank, int>.from(
        _stationRankFinalScores,
      ),
      overkillGrowthClaimedStationKeys: Set<String>.from(
        _overkillGrowthClaimedStationKeys,
      ),
      addedDeckTiles: List<Tile>.from(addedDeckTiles),
      tileOffers: List<Tile>.from(tileOffers),
      pendingBossTileReward: pendingBossTileReward,
      firstShopRerollDiscountConsumed: firstShopRerollDiscountConsumed,
      firstShopRerollDiscountConsumedLanes: Set<String>.from(
        _firstShopRerollDiscountConsumedLanes,
      ),
      unlockedJesterSlots: unlockedJesterSlots,
      unlockedQuickSlotCapacity: unlockedQuickSlotCapacity,
      unlockedPassiveRelicCapacity: unlockedPassiveRelicCapacity,
      pendingSlotUnlockPresentations: Set<RummiSlotUnlockKind>.from(
        _pendingSlotUnlockPresentations,
      ),
      itemInventory: itemInventory,
      marketModifiers: marketModifiers,
      seenMarketJesterIds: Set<String>.from(seenMarketJesterIds),
      seenMarketItemIds: Set<String>.from(seenMarketItemIds),
      boughtJesterIds: Set<String>.from(boughtJesterIds),
      boughtItemIds: Set<String>.from(boughtItemIds),
      seenBossModifierIds: Set<String>.from(seenBossModifierIds),
      clearedStationKeys: Set<String>.from(clearedStationKeys),
    );
  }

  static String _newRunClaimId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(0x7fffffff)}';

  /// 도감에 남길 마켓 노출 이력을 런 진행 상태에 쌓는다.
  void recordSeenMarketItems(Iterable<String> itemIds) {
    seenMarketItemIds.addAll(itemIds.where((id) => id.isNotEmpty));
  }

  void recordSeenBossModifier(String? modifierId) {
    if (modifierId == null || modifierId.isEmpty) return;
    seenBossModifierIds.add(modifierId);
  }

  void recordClearedStation(int stationIndex) {
    if (stationIndex <= 0) return;
    clearedStationKeys.add('station_$stationIndex');
  }

  bool unlockSlotCapacity(
    RummiSlotUnlockKind kind, {
    ItemCatalog? itemCatalog,
  }) {
    final visibleCapacityBefore = _slotCapacityFor(
      kind,
      itemCatalog: itemCatalog,
    );
    final unlocked = switch (kind) {
      RummiSlotUnlockKind.jester => _increaseJesterSlots(),
      RummiSlotUnlockKind.quickSlot => _increaseQuickSlotCapacity(),
      RummiSlotUnlockKind.passiveRelic => _increasePassiveRelicCapacity(),
    };
    if (unlocked) {
      final visibleCapacityAfter = _slotCapacityFor(
        kind,
        itemCatalog: itemCatalog,
      );
      if (visibleCapacityAfter > visibleCapacityBefore) {
        _pendingSlotUnlockPresentations.add(kind);
      }
    }
    return unlocked;
  }

  List<RummiSlotUnlockKind> claimBossSlotUnlockRewards({
    ItemCatalog? itemCatalog,
  }) {
    final rewardKind = switch (stageIndex) {
      2 => RummiSlotUnlockKind.quickSlot,
      4 => RummiSlotUnlockKind.passiveRelic,
      6 => RummiSlotUnlockKind.jester,
      _ => null,
    };
    if (rewardKind == null) return const <RummiSlotUnlockKind>[];
    return unlockSlotCapacity(rewardKind, itemCatalog: itemCatalog) &&
            _pendingSlotUnlockPresentations.contains(rewardKind)
        ? <RummiSlotUnlockKind>[rewardKind]
        : const <RummiSlotUnlockKind>[];
  }

  int _slotCapacityFor(RummiSlotUnlockKind kind, {ItemCatalog? itemCatalog}) {
    return switch (kind) {
      RummiSlotUnlockKind.jester => jesterSlotCapacity(
        itemCatalog: itemCatalog,
      ),
      RummiSlotUnlockKind.quickSlot => quickSlotCapacity(
        itemCatalog: itemCatalog,
      ),
      RummiSlotUnlockKind.passiveRelic => passiveRelicCapacity(
        itemCatalog: itemCatalog,
      ),
    };
  }

  void clearPendingSlotUnlockPresentations() {
    _pendingSlotUnlockPresentations.clear();
  }

  bool _increaseJesterSlots() {
    if (unlockedJesterSlots >= maxJesterSlots) return false;
    unlockedJesterSlots += 1;
    return true;
  }

  bool _increaseQuickSlotCapacity() {
    if (unlockedQuickSlotCapacity >= RunInventoryState.maxQuickSlotCapacity) {
      return false;
    }
    unlockedQuickSlotCapacity += 1;
    return true;
  }

  bool _increasePassiveRelicCapacity() {
    if (unlockedPassiveRelicCapacity >=
        RunInventoryState.maxPassiveRelicCapacity) {
      return false;
    }
    unlockedPassiveRelicCapacity += 1;
    return true;
  }

  List<Tile> buildDeckSourceForNextBlind(int deckCopiesPerTile) {
    return List<Tile>.unmodifiable([
      ...buildStandardPokerDeck(copiesPerTile: deckCopiesPerTile),
      ...addedDeckTiles,
    ]);
  }

  void queueBossTileReward() {
    pendingBossTileReward = true;
  }

  Tile addDeckTile(Tile tile) {
    final copyId = _nextCopyIdForTile(tile);
    final addedTile = Tile(
      color: tile.color,
      number: tile.number,
      id: copyId,
      enhancement: tile.enhancement,
      seal: tile.seal,
      edition: tile.edition,
    );
    addedDeckTiles.add(addedTile);
    return addedTile;
  }

  Tile addBossClearDeckTileReward(Random rng) {
    final rewardPool = buildStandardPokerDeck(copiesPerTile: 1);
    return addDeckTile(rewardPool[rng.nextInt(rewardPool.length)]);
  }

  bool buyTileOffer(int offerIndex) {
    if (offerIndex < 0 || offerIndex >= tileOffers.length) return false;
    final price = effectiveTileOfferPrice(offerIndex);
    if (gold < price) return false;
    final tile = tileOffers.removeAt(offerIndex);
    gold -= price;
    addDeckTile(tile);
    _consumePurchaseDiscounts('tile');
    return true;
  }

  bool claimFreeTileOffer(int offerIndex) {
    if (!pendingBossTileReward) return false;
    if (offerIndex < 0 || offerIndex >= tileOffers.length) return false;
    final tile = tileOffers.removeAt(offerIndex);
    addDeckTile(tile);
    pendingBossTileReward = false;
    return true;
  }

  int effectiveTileOfferPrice(int offerIndex) {
    if (offerIndex < 0 || offerIndex >= tileOffers.length) return 0;
    final stageStep = max(0, stageIndex - 1) ~/ 2;
    return 3 + stageStep + _tileModifierSurcharge(tileOffers[offerIndex]);
  }

  int _tileModifierSurcharge(Tile tile) {
    final enhancementSurcharge = switch (tile.enhancement) {
      TileEnhancement.chipInlaid => 2,
      TileEnhancement.scoreGilded => 3,
      TileEnhancement.goldTile => 2,
      TileEnhancement.glassTile => 4,
      null => 0,
    };
    final sealSurcharge = switch (tile.seal) {
      TileSeal.blueSeal => 3,
      TileSeal.redSeal => 4,
      TileSeal.lineMark ||
      TileSeal.growthSeal ||
      TileSeal.goldSeal ||
      TileSeal.echoSeal ||
      TileSeal.anchorSeal ||
      TileSeal.fractureSeal ||
      TileSeal.crossMemory ||
      TileSeal.bridgeSeal => 3,
      null => 0,
    };
    final editionSurcharge = switch (tile.edition) {
      TileEdition.silverEdition => 3,
      TileEdition.glowEdition => 4,
      TileEdition.prismEdition => 5,
      null => 0,
    };
    return enhancementSurcharge + sealSurcharge + editionSurcharge;
  }

  int _nextCopyIdForTile(Tile tile) {
    var maxId = 0;
    for (final existing in addedDeckTiles) {
      if (existing.color == tile.color && existing.number == tile.number) {
        maxId = max(maxId, existing.id);
      }
    }
    return maxId + 1;
  }

  static bool _samePhysicalTile(Tile a, Tile b) {
    return a.color == b.color &&
        a.number == b.number &&
        a.id == b.id &&
        a.enhancement == b.enhancement &&
        a.seal == b.seal &&
        a.edition == b.edition;
  }

  int targetForStage(int stageNumber) {
    const scoutTargets = <int>[480, 650, 900, 1250, 1750, 2450, 3450, 4850];
    if (stageNumber <= 1) return scoutTargets.first;
    if (stageNumber <= scoutTargets.length) {
      return scoutTargets[stageNumber - 1];
    }
    final extraStep = stageNumber - scoutTargets.length;
    return (scoutTargets.last * pow(1.25, extraStep)).round();
  }

  void startBlind(
    RummiPokerGridSession session, {
    required int stationIndex,
    required int blindTierIndex,
    required int shuffleSeed,
    required int targetScore,
    required int boardDiscards,
    required int handDiscards,
    required int maxHandSize,
    List<Tile>? deckSource,
    bool applyRoundEndDecay = true,
  }) {
    stageIndex = stationIndex;
    currentStationBlindTierIndex = blindTierIndex;
    settlementReceiptKey = null;
    settlementReceipt = null;
    _stationRankFinalScores.clear();
    if (applyRoundEndDecay) {
      _applyRoundEndStateDecay();
    }
    session.prepareNextBlind(
      targetScore: targetScore,
      boardDiscardsRemaining: boardDiscards,
      handDiscardsRemaining: handDiscards,
      shuffleSeed: shuffleSeed,
      deckSource: deckSource,
    );
    session.maxHandSize = maxHandSize;
  }

  RummiCashOutBreakdown buildCashOutBreakdown(
    RummiPokerGridSession session, {
    ItemCatalog? itemCatalog,
    double rewardMultiplier = 1,
  }) {
    final blindReward = (stageClearGoldBase * rewardMultiplier).round();
    final firstBlindClearBonusGold = _firstBlindClearBonusGold();
    final remainingBoardDiscards = session.blind.boardDiscardsRemaining;
    final remainingHandDiscards = session.blind.handDiscardsRemaining;
    final remainingBoardMoves = session.blind.boardMovesRemaining;
    final boardDiscardGold =
        remainingBoardDiscards * remainingBoardDiscardGoldBonus;
    final handDiscardGold =
        remainingHandDiscards * remainingHandDiscardGoldBonus;
    final boardMoveGold = remainingBoardMoves * remainingBoardMoveGoldBonus;
    final economyBonuses = ownedJesters
        .map(
          (card) => _buildRoundEndEconomyBonus(
            card: card,
            remainingBoardDiscards: remainingBoardDiscards,
            remainingHandDiscards: remainingHandDiscards,
          ),
        )
        .whereType<RummiRoundEndEconomyBonus>()
        .toList(growable: false);
    final economyGold = economyBonuses.fold<int>(
      0,
      (sum, bonus) => sum + bonus.gold,
    );
    final itemBonuses = itemCatalog == null
        ? const <RummiRoundEndItemBonus>[]
        : _buildRoundEndItemBonuses(
            catalog: itemCatalog,
            remainingBoardDiscards: remainingBoardDiscards,
            remainingHandDiscards: remainingHandDiscards,
          );
    final itemGold = itemBonuses.fold<int>(0, (sum, bonus) => sum + bonus.gold);
    final overkillGrowthBonuses = claimOverkillGrowthBonus(
      targetScore: session.blind.targetScore,
      finalScore: session.blind.scoreTowardBlind,
    );
    final overkillGoldBonus = overkillGrowthBonuses.isEmpty
        ? 0
        : calculateOverkillGoldBonus(
            targetScore: session.blind.targetScore,
            finalScore: session.blind.scoreTowardBlind,
          );
    return RummiCashOutBreakdown(
      stageIndex: stageIndex,
      targetScore: session.blind.targetScore,
      blindReward: blindReward,
      remainingBoardDiscards: remainingBoardDiscards,
      remainingHandDiscards: remainingHandDiscards,
      remainingBoardMoves: remainingBoardMoves,
      perBoardDiscardBonus: remainingBoardDiscardGoldBonus,
      perHandDiscardBonus: remainingHandDiscardGoldBonus,
      perBoardMoveBonus: remainingBoardMoveGoldBonus,
      boardDiscardGold: boardDiscardGold,
      handDiscardGold: handDiscardGold,
      boardMoveGold: boardMoveGold,
      economyBonuses: economyBonuses,
      economyGold: economyGold,
      firstBlindClearBonusGold: firstBlindClearBonusGold,
      itemBonuses: itemBonuses,
      itemGold: itemGold,
      overkillGrowthBonuses: overkillGrowthBonuses,
      overkillGoldBonus: overkillGoldBonus,
      totalGold:
          blindReward +
          firstBlindClearBonusGold +
          boardDiscardGold +
          handDiscardGold +
          boardMoveGold +
          economyGold +
          itemGold +
          overkillGoldBonus,
    );
  }

  int _firstBlindClearBonusGold() {
    if (stageIndex == 1 && currentStationBlindTierIndex == 0) {
      return RummiEconomyConfig.firstBlindClearBonusGold;
    }
    return 0;
  }

  List<RummiRoundEndItemBonus> _buildRoundEndItemBonuses({
    required ItemCatalog catalog,
    required int remainingBoardDiscards,
    required int remainingHandDiscards,
  }) {
    final activeIds = <String>{
      for (final entry in itemInventory.ownedItems)
        if (entry.count > 0) entry.itemId,
    };
    final bonuses = <RummiRoundEndItemBonus>[];
    for (final itemId in activeIds) {
      final item = catalog.findById(itemId);
      if (item == null || item.effect.timing != 'settlement') {
        continue;
      }
      final amount = (item.effect.amount ?? 0).toInt();
      if (amount <= 0) continue;
      final gold = switch (item.effect.op) {
        'board_discard_reward_bonus' => remainingBoardDiscards * amount,
        'hand_discard_reward_bonus' => remainingHandDiscards * amount,
        _ => 0,
      };
      if (gold <= 0) continue;
      bonuses.add(
        RummiRoundEndItemBonus(
          itemId: item.id,
          displayName: item.displayName,
          gold: gold,
        ),
      );
    }
    return List<RummiRoundEndItemBonus>.unmodifiable(bonuses);
  }

  void applyCashOut(RummiCashOutBreakdown breakdown) {
    gold += breakdown.totalGold;
  }

  RummiJesterRuntimeSnapshot buildRuntimeSnapshot() {
    return RummiJesterRuntimeSnapshot(
      slotStateValues: Map<int, int>.unmodifiable(_statefulValuesBySlot),
      playedHandCounts: Map<RummiHandRank, int>.unmodifiable(_playedHandCounts),
      handGrowthStates: Map<RummiHandRank, RummiHandGrowthState>.unmodifiable(
        _handGrowthStates,
      ),
    );
  }

  /// 현재 상점은 "전투 점수 정산 또는 라운드 종료 정산에 즉시 반영 가능한
  /// Jester만 노출" 정책을 쓴다.
  void openShop({
    required List<RummiJesterCard> catalog,
    required Random rng,
    List<String> preferredOfferIds = const [],
    int? offerCountOverride,
    RummiMarketPressureProfile pressureProfile =
        RummiMarketPressureProfile.standard,
  }) {
    rerollCost = shopBaseRerollCost;
    tileRerollCost = shopBaseRerollCost;
    itemRerollCost = shopBaseRerollCost;
    quickSlotRerollCost = shopBaseRerollCost;
    passiveRerollCost = shopBaseRerollCost;
    toolRerollCost = shopBaseRerollCost;
    gearRerollCost = shopBaseRerollCost;
    final nextMarketExtraJesterOfferSlots =
        marketModifiers.nextMarketExtraJesterOfferSlots;
    firstShopRerollDiscountConsumed = false;
    _firstShopRerollDiscountConsumedLanes.clear();
    final firstRerollDiscount = _isFirstMarketRerollDiscountEligible
        ? RummiEconomyConfig.shopFirstRerollDiscount
        : 0;
    marketModifiers = marketModifiers.copyWith(
      nextRerollDiscount: 0,
      firstRerollDiscount: firstRerollDiscount,
      nextPurchaseDiscount: 0,
      nextJesterPurchaseDiscount: 0,
      nextItemPurchaseDiscount: 0,
      cheapestFirstOfferDiscount: 0,
      extraJesterOfferSlots: nextMarketExtraJesterOfferSlots,
      nextMarketExtraJesterOfferSlots: 0,
      itemOfferRerollOffset: 0,
      quickSlotOfferRerollOffset: 0,
      passiveOfferRerollOffset: 0,
      toolOfferRerollOffset: 0,
      gearOfferRerollOffset: 0,
      consumedItemOfferIds: const [],
      pinnedItemOfferKeys: const [],
    );
    _generateOffers(
      catalog: catalog,
      rng: rng,
      preferredOfferIds: preferredOfferIds,
      offerCountOverride: offerCountOverride,
      pressureProfile: pressureProfile,
    );
    _generateTileOffers(rng);
  }

  bool canAfford(int cost) => gold >= cost;

  int effectiveRerollCost() {
    return _effectiveRerollCostForRawCost(rerollCost, _jesterRerollLaneKey);
  }

  int effectiveTileRerollCost() {
    return _effectiveRerollCostForRawCost(tileRerollCost, _tileRerollLaneKey);
  }

  int effectiveItemRerollCost() {
    return effectiveItemRerollCostFor(ItemPlacement.inventory);
  }

  int itemRerollCostFor(ItemPlacement placement) {
    return switch (placement) {
      ItemPlacement.quickSlot => quickSlotRerollCost,
      ItemPlacement.passiveRack => passiveRerollCost,
      ItemPlacement.inventory => toolRerollCost,
      ItemPlacement.equipped => gearRerollCost,
    };
  }

  int effectiveItemRerollCostFor(ItemPlacement placement) {
    return _effectiveRerollCostForRawCost(
      itemRerollCostFor(placement),
      _rerollLaneKeyForPlacement(placement),
    );
  }

  int _effectiveRerollCostForRawCost(int rawCost, String laneKey) {
    final firstRerollDiscount =
        rawCost == shopBaseRerollCost &&
            _isFirstMarketRerollDiscountEligible &&
            !firstShopRerollDiscountConsumed
        ? marketModifiers.firstRerollDiscount
        : 0;
    return max(
      0,
      rawCost - marketModifiers.nextRerollDiscount - firstRerollDiscount,
    );
  }

  bool get _isFirstMarketRerollDiscountEligible =>
      stageIndex == 1 && currentStationBlindTierIndex == 0;

  String _rerollLaneKeyForPlacement(ItemPlacement placement) {
    return switch (placement) {
      ItemPlacement.quickSlot => _quickSlotRerollLaneKey,
      ItemPlacement.passiveRack => _passiveRerollLaneKey,
      ItemPlacement.inventory => _toolRerollLaneKey,
      ItemPlacement.equipped => _gearRerollLaneKey,
    };
  }

  int effectiveJesterOfferPrice(
    int offerIndex, {
    bool includeCheapestFirstOfferDiscount = true,
  }) {
    if (offerIndex < 0 || offerIndex >= shopOffers.length) return 0;
    final offer = shopOffers[offerIndex];
    return effectivePurchasePrice(
      basePrice: offer.price,
      category: 'jester',
      jester: offer.card,
      includeCheapestFirstOfferDiscount: includeCheapestFirstOfferDiscount,
    );
  }

  int effectiveJesterOfferBasePrice(int offerIndex) {
    if (offerIndex < 0 || offerIndex >= shopOffers.length) return 0;
    final offer = shopOffers[offerIndex];
    return effectivePurchaseBasePrice(
      basePrice: offer.price,
      jester: offer.card,
    );
  }

  int effectiveItemPrice(
    ItemDefinition item, {
    bool includeCheapestFirstOfferDiscount = true,
  }) {
    return effectivePurchasePrice(
      basePrice: item.basePrice,
      category: 'item',
      item: item,
      includeCheapestFirstOfferDiscount: includeCheapestFirstOfferDiscount,
    );
  }

  int effectiveItemBasePrice(ItemDefinition item) {
    return effectivePurchaseBasePrice(basePrice: item.basePrice, item: item);
  }

  int effectivePurchaseBasePrice({
    required int basePrice,
    RummiJesterCard? jester,
    ItemDefinition? item,
  }) {
    return _growthAccessMarketPrice(
      scaledBasePrice: RummiEconomyConfig.scaledMarketPrice(basePrice),
      jester: jester,
      item: item,
    );
  }

  int effectivePurchasePrice({
    required int basePrice,
    required String category,
    RummiJesterCard? jester,
    ItemDefinition? item,
    bool includeCheapestFirstOfferDiscount = true,
  }) {
    final scaledBasePrice = effectivePurchaseBasePrice(
      basePrice: basePrice,
      jester: jester,
      item: item,
    );
    final categoryDiscount = switch (category) {
      'jester' => marketModifiers.nextJesterPurchaseDiscount,
      'item' => marketModifiers.nextItemPurchaseDiscount,
      _ => 0,
    };
    final cheapestDiscount =
        includeCheapestFirstOfferDiscount &&
            _cheapestFirstOfferDiscountApplies(scaledBasePrice, category)
        ? marketModifiers.cheapestFirstOfferDiscount
        : 0;
    return max(
      0,
      scaledBasePrice -
          marketModifiers.nextPurchaseDiscount -
          categoryDiscount -
          cheapestDiscount,
    );
  }

  int _growthAccessMarketPrice({
    required int scaledBasePrice,
    RummiJesterCard? jester,
    ItemDefinition? item,
  }) {
    if (jester != null && _isGrowthAccessJester(jester)) {
      final cap = switch (jester.rarity) {
        RummiJesterRarity.common => 5,
        RummiJesterRarity.uncommon => 7,
        RummiJesterRarity.rare => 8,
        RummiJesterRarity.legendary => 14,
      };
      return min(scaledBasePrice, cap);
    }
    if (item != null && _isGrowthAccessItem(item)) {
      final cap = switch (item.rarity) {
        ItemRarity.common => 5,
        ItemRarity.uncommon => 7,
        ItemRarity.rare => 8,
        ItemRarity.legendary => 14,
      };
      return min(scaledBasePrice, cap);
    }
    return scaledBasePrice;
  }

  bool _isGrowthAccessJester(RummiJesterCard card) {
    return card.effectType == 'chips_bonus' ||
        card.effectType == 'mult_bonus' ||
        card.effectType == 'xmult_bonus' ||
        card.effectType == 'stateful_growth';
  }

  bool _isGrowthAccessItem(ItemDefinition item) {
    const growthTags = {
      'score',
      'rank',
      'tile_color',
      'xmult',
      'discard',
      'move',
      'safety',
      'draw',
    };
    for (final tag in item.tags) {
      if (growthTags.contains(tag)) return true;
    }
    return false;
  }

  void queueMarketModifier({
    required String op,
    required int amount,
    String? category,
  }) {
    if (amount <= 0) return;
    switch (op) {
      case 'discount_next_reroll':
        marketModifiers = marketModifiers.copyWith(
          nextRerollDiscount: marketModifiers.nextRerollDiscount + amount,
        );
      case 'discount_first_reroll':
        marketModifiers = marketModifiers.copyWith(
          firstRerollDiscount: marketModifiers.firstRerollDiscount + amount,
        );
      case 'discount_next_purchase':
        if (category == 'jester') {
          marketModifiers = marketModifiers.copyWith(
            nextJesterPurchaseDiscount:
                marketModifiers.nextJesterPurchaseDiscount + amount,
          );
        } else if (category == 'item') {
          marketModifiers = marketModifiers.copyWith(
            nextItemPurchaseDiscount:
                marketModifiers.nextItemPurchaseDiscount + amount,
          );
        } else {
          marketModifiers = marketModifiers.copyWith(
            nextPurchaseDiscount: marketModifiers.nextPurchaseDiscount + amount,
          );
        }
      case 'discount_cheapest_first_offer':
        marketModifiers = marketModifiers.copyWith(
          cheapestFirstOfferDiscount:
              marketModifiers.cheapestFirstOfferDiscount + amount,
        );
      case 'extra_item_offer_slot':
        marketModifiers = marketModifiers.copyWith(
          extraItemOfferSlots: marketModifiers.extraItemOfferSlots + amount,
        );
      case 'reroll_item_offers_only':
        final nextQuickSlotOffset =
            marketModifiers.quickSlotOfferRerollOffset +
            marketModifiers.itemOfferSlotCount;
        final nextPassiveOffset =
            marketModifiers.passiveOfferRerollOffset +
            marketModifiers.itemOfferSlotCount;
        final nextToolOffset =
            marketModifiers.toolOfferRerollOffset +
            marketModifiers.itemOfferSlotCount;
        final nextGearOffset =
            marketModifiers.gearOfferRerollOffset +
            marketModifiers.itemOfferSlotCount;
        marketModifiers = marketModifiers.copyWith(
          itemOfferRerollOffset:
              marketModifiers.itemOfferRerollOffset +
              marketModifiers.itemOfferSlotCount,
          quickSlotOfferRerollOffset: nextQuickSlotOffset,
          passiveOfferRerollOffset: nextPassiveOffset,
          toolOfferRerollOffset: nextToolOffset,
          gearOfferRerollOffset: nextGearOffset,
          consumedItemOfferIds: const [],
          pinnedItemOfferKeys: const [],
        );
      case 'extra_jester_offer_next_market':
        marketModifiers = marketModifiers.copyWith(
          nextMarketExtraJesterOfferSlots:
              marketModifiers.nextMarketExtraJesterOfferSlots + amount,
        );
    }
  }

  bool rerollShop({
    required List<RummiJesterCard> catalog,
    required Random rng,
    List<String> preferredOfferIds = const [],
    int? offerCountOverride,
    RummiMarketPressureProfile pressureProfile =
        RummiMarketPressureProfile.standard,
  }) {
    final cost = effectiveRerollCost();
    if (gold < cost) {
      return false;
    }
    gold -= cost;
    rerollCost += shopRerollCostStep;
    _markFirstShopRerollDiscountConsumed();
    marketModifiers = marketModifiers.copyWith(nextRerollDiscount: 0);
    _generateOffers(
      catalog: catalog,
      rng: rng,
      preferredOfferIds: preferredOfferIds,
      offerCountOverride: offerCountOverride,
      pressureProfile: pressureProfile,
    );
    return true;
  }

  bool rerollTileOffers({required Random rng}) {
    final cost = effectiveTileRerollCost();
    if (gold < cost) {
      return false;
    }
    gold -= cost;
    tileRerollCost += shopRerollCostStep;
    _markFirstShopRerollDiscountConsumed();
    marketModifiers = marketModifiers.copyWith(nextRerollDiscount: 0);
    _generateTileOffers(rng);
    return true;
  }

  bool rerollItemOffers({ItemPlacement placement = ItemPlacement.inventory}) {
    final cost = effectiveItemRerollCostFor(placement);
    if (gold < cost) {
      return false;
    }
    gold -= cost;
    _increaseItemRerollCostFor(placement);
    _markFirstShopRerollDiscountConsumed();
    final nextOffset =
        marketModifiers.itemOfferRerollOffsetFor(placement) +
        marketModifiers.itemOfferSlotCount;
    marketModifiers = marketModifiers.copyWith(
      nextRerollDiscount: 0,
      itemOfferRerollOffset: placement == ItemPlacement.inventory
          ? nextOffset
          : marketModifiers.itemOfferRerollOffset,
      quickSlotOfferRerollOffset: placement == ItemPlacement.quickSlot
          ? nextOffset
          : marketModifiers.quickSlotOfferRerollOffset,
      passiveOfferRerollOffset: placement == ItemPlacement.passiveRack
          ? nextOffset
          : marketModifiers.passiveOfferRerollOffset,
      toolOfferRerollOffset: placement == ItemPlacement.inventory
          ? nextOffset
          : marketModifiers.toolOfferRerollOffset,
      gearOfferRerollOffset: placement == ItemPlacement.equipped
          ? nextOffset
          : marketModifiers.gearOfferRerollOffset,
      pinnedItemOfferKeys: _itemOfferKeysWithoutPlacement(
        marketModifiers.pinnedItemOfferKeys,
        placement,
      ),
    );
    return true;
  }

  void _markFirstShopRerollDiscountConsumed() {
    if (marketModifiers.firstRerollDiscount > 0 &&
        !firstShopRerollDiscountConsumed) {
      _firstShopRerollDiscountConsumedLanes.addAll(_marketRerollLaneKeys);
      firstShopRerollDiscountConsumed = true;
    }
  }

  void _increaseItemRerollCostFor(ItemPlacement placement) {
    switch (placement) {
      case ItemPlacement.quickSlot:
        quickSlotRerollCost += shopRerollCostStep;
      case ItemPlacement.passiveRack:
        passiveRerollCost += shopRerollCostStep;
      case ItemPlacement.inventory:
        toolRerollCost += shopRerollCostStep;
        itemRerollCost = toolRerollCost;
      case ItemPlacement.equipped:
        gearRerollCost += shopRerollCostStep;
    }
  }

  bool buyOffer(
    int offerIndex, {
    int? price,
    bool consumeCheapestFirstOfferDiscount = true,
  }) {
    if (offerIndex < 0 || offerIndex >= shopOffers.length) {
      return false;
    }
    if (ownedJesters.length >= jesterSlotCapacity()) {
      return false;
    }
    final offer = shopOffers[offerIndex];
    final resolvedPrice = price ?? effectiveJesterOfferPrice(offerIndex);
    if (gold < resolvedPrice) {
      return false;
    }
    gold -= resolvedPrice;
    ownedJesters.add(offer.card);
    boughtJesterIds.add(offer.card.id);
    _initializeStateForSlot(ownedJesters.length - 1, offer.card);
    shopOffers.removeAt(offerIndex);
    _consumePurchaseDiscounts(
      'jester',
      consumeCheapestFirstOfferDiscount: consumeCheapestFirstOfferDiscount,
    );
    return true;
  }

  bool buyItem(
    ItemDefinition item, {
    int? price,
    ItemCatalog? itemCatalog,
    bool consumeCheapestFirstOfferDiscount = true,
  }) {
    final resolvedPrice = price ?? effectiveItemPrice(item);
    if (gold < resolvedPrice) {
      return false;
    }
    final capacity = quickSlotCapacity(itemCatalog: itemCatalog);
    if (!itemInventory.canAcquire(
      item,
      quickSlotCapacity: capacity,
      passiveRelicCapacity: passiveRelicCapacity(itemCatalog: itemCatalog),
    )) {
      return false;
    }
    gold -= resolvedPrice;
    itemInventory = itemInventory.withAcquiredItem(
      item,
      quickSlotCapacity: capacity,
      passiveRelicCapacity: passiveRelicCapacity(itemCatalog: itemCatalog),
    );
    boughtItemIds.add(item.id);
    _consumePurchaseDiscounts(
      'item',
      consumeCheapestFirstOfferDiscount: consumeCheapestFirstOfferDiscount,
    );
    return true;
  }

  bool sellOwnedItem(ItemDefinition item) {
    final existing = itemInventory.ownedItems.any(
      (entry) => entry.itemId == item.id && entry.count > 0,
    );
    if (!existing) return false;
    itemInventory = itemInventory.withSoldItem(item.id);
    gold += item.sellPrice < 0 ? 0 : item.sellPrice;
    return true;
  }

  void markItemOfferConsumed(String itemId) {
    if (marketModifiers.consumedItemOfferIds.contains(itemId)) return;
    marketModifiers = marketModifiers.copyWith(
      consumedItemOfferIds: List<String>.unmodifiable([
        ...marketModifiers.consumedItemOfferIds,
        itemId,
      ]),
    );
  }

  void pinCurrentItemOfferKeys(Iterable<String> itemOfferKeys) {
    final keys = itemOfferKeys
        .where((key) => key.isNotEmpty)
        .toList(growable: false);
    marketModifiers = marketModifiers.copyWith(
      pinnedItemOfferKeys: List<String>.unmodifiable(keys),
    );
  }

  static List<String> _itemOfferKeysWithoutPlacement(
    List<String> keys,
    ItemPlacement placement,
  ) {
    return List<String>.unmodifiable(
      keys.where(
        (key) => !RummiMarketModifierState.itemOfferKeyMatchesPlacement(
          key,
          placement,
        ),
      ),
    );
  }

  bool sellOwnedJester(int slotIndex, {ItemCatalog? itemCatalog}) {
    if (slotIndex < 0 || slotIndex >= ownedJesters.length) {
      return false;
    }
    final sold = ownedJesters.removeAt(slotIndex);
    _removeStateAtSlot(slotIndex);
    gold +=
        _sellPriceFor(sold) + jesterSellPriceBonus(itemCatalog: itemCatalog);
    return true;
  }

  int sellPriceAt(int slotIndex, {ItemCatalog? itemCatalog}) {
    if (slotIndex < 0 || slotIndex >= ownedJesters.length) {
      return 0;
    }
    return _sellPriceFor(ownedJesters[slotIndex]) +
        jesterSellPriceBonus(itemCatalog: itemCatalog);
  }

  int quickSlotCapacity({ItemCatalog? itemCatalog}) {
    return unlockedQuickSlotCapacity
        .clamp(
          RunInventoryState.defaultQuickSlotCapacity,
          RunInventoryState.maxQuickSlotCapacity,
        )
        .toInt();
  }

  int passiveRelicCapacity({ItemCatalog? itemCatalog}) {
    return unlockedPassiveRelicCapacity
        .clamp(
          RunInventoryState.defaultPassiveRelicCapacity,
          RunInventoryState.maxPassiveRelicCapacity,
        )
        .toInt();
  }

  int jesterSlotCapacity({ItemCatalog? itemCatalog}) {
    return unlockedJesterSlots.clamp(0, maxJesterSlots).toInt();
  }

  int jesterSellPriceBonus({ItemCatalog? itemCatalog}) {
    return _sumOwnedItemEffectAmount(
      itemCatalog: itemCatalog,
      timing: 'sell_jester',
      op: 'sell_price_bonus',
    );
  }

  void advanceStage(
    RummiPokerGridSession session, {
    required int runSeed,
    int? targetScoreOverride,
    int? boardDiscardsOverride,
    int? handDiscardsOverride,
    int? maxHandSizeOverride,
  }) {
    stageIndex += 1;
    _applyRoundEndStateDecay();
    session.prepareNextBlind(
      targetScore: targetScoreOverride ?? targetForStage(stageIndex),
      boardDiscardsRemaining:
          boardDiscardsOverride ?? session.blind.boardDiscardsMax,
      handDiscardsRemaining:
          handDiscardsOverride ?? session.blind.handDiscardsMax,
      shuffleSeed: RummiPokerGridSession.deriveStageShuffleSeed(
        runSeed,
        stageIndex,
      ),
    );
    if (maxHandSizeOverride != null) {
      session.maxHandSize = maxHandSizeOverride;
    }
  }

  void onConfirmedLines(List<ConfirmedLineBreakdown> lineBreakdowns) {
    if (lineBreakdowns.isEmpty) {
      return;
    }
    final hadScoringFaceCard = lineBreakdowns.any(
      (line) => line.hasScoringFaceCard,
    );
    for (var slot = 0; slot < ownedJesters.length; slot++) {
      if (ownedJesters[slot].id == 'green_jester') {
        _statefulValuesBySlot.update(
          slot,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
      if (ownedJesters[slot].id == 'ride_the_bus') {
        if (hadScoringFaceCard) {
          _statefulValuesBySlot[slot] = 0;
        } else {
          _statefulValuesBySlot.update(
            slot,
            (value) => value + 1,
            ifAbsent: () => 1,
          );
        }
      }
    }
    for (final line in lineBreakdowns) {
      if (line.tileGoldBonus > 0) {
        gold += line.tileGoldBonus;
      }
      if (line.destroyedTiles.isNotEmpty) {
        removeAddedDeckTiles(line.destroyedTiles);
      }
      recordHandRankCompletion(line.rank);
      for (var i = 0; i < line.bonusRankProgress; i += 1) {
        recordHandRankCompletion(line.rank);
      }
      if (!isDeadLineRank(line.rank)) {
        _stationRankFinalScores.update(
          line.rank,
          (value) => value + line.finalScore,
          ifAbsent: () => line.finalScore,
        );
      }
    }
    for (var slot = 0; slot < ownedJesters.length; slot++) {
      if (ownedJesters[slot].id == 'ice_cream') {
        final next = (_statefulValuesBySlot[slot] ?? 0) - 5;
        _statefulValuesBySlot[slot] = next < 0 ? 0 : next;
      }
    }
  }

  int removeAddedDeckTiles(Iterable<Tile> tiles) {
    var removed = 0;
    for (final tile in tiles) {
      final index = addedDeckTiles.indexWhere(
        (candidate) => _samePhysicalTile(candidate, tile),
      );
      if (index < 0) continue;
      addedDeckTiles.removeAt(index);
      removed += 1;
    }
    return removed;
  }

  List<RummiOverkillGrowthBonus> claimOverkillGrowthBonus({
    required int targetScore,
    required int finalScore,
  }) {
    if (targetScore <= 0 ||
        finalScore <= 0 ||
        _stationRankFinalScores.isEmpty) {
      return const <RummiOverkillGrowthBonus>[];
    }
    final thresholdPercent = _overkillThresholdPercent();
    final thresholdScore = ((targetScore * thresholdPercent) / 100).ceil();
    if (finalScore < thresholdScore) {
      return const <RummiOverkillGrowthBonus>[];
    }
    final stationKey = '$stageIndex:$currentStationBlindTierIndex';
    if (_overkillGrowthClaimedStationKeys.contains(stationKey)) {
      return const <RummiOverkillGrowthBonus>[];
    }
    final rank = _representativeOverkillRank();
    if (rank == null) {
      return const <RummiOverkillGrowthBonus>[];
    }
    final applied = addHandRankProgress(rank);
    if (!applied) {
      return const <RummiOverkillGrowthBonus>[];
    }
    _overkillGrowthClaimedStationKeys.add(stationKey);
    return [
      RummiOverkillGrowthBonus(
        rank: rank,
        amount: 1,
        finalScore: finalScore,
        thresholdScore: thresholdScore,
      ),
    ];
  }

  int calculateOverkillGoldBonus({
    required int targetScore,
    required int finalScore,
  }) {
    if (targetScore <= 0 || finalScore <= 0) return 0;
    final surplusNumerator =
        finalScore * 100 - targetScore * _overkillThresholdPercent();
    if (surplusNumerator <= 0) return 0;
    return surplusNumerator ~/ (targetScore * 50);
  }

  int _overkillThresholdPercent() =>
      currentStationBlindTierIndex >= 2 ? 120 : 130;

  RummiHandRank? _representativeOverkillRank() {
    RummiHandRank? bestRank;
    var bestFinalScore = -1;
    var bestCurrentScore = -1;
    var bestBaseScore = -1;
    for (final entry in _stationRankFinalScores.entries) {
      if (isDeadLineRank(entry.key)) continue;
      final currentScore =
          gddBaseScore(entry.key) +
          RummiHandGrowth.growthBonusForState(
            rank: entry.key,
            state:
                _handGrowthStates[entry.key] ??
                RummiHandGrowthState.fromCompletedCount(
                  entry.key,
                  _playedHandCounts[entry.key] ?? 0,
                ),
          );
      final baseScore = gddBaseScore(entry.key);
      final isBetter =
          entry.value > bestFinalScore ||
          (entry.value == bestFinalScore && currentScore > bestCurrentScore) ||
          (entry.value == bestFinalScore &&
              currentScore == bestCurrentScore &&
              baseScore > bestBaseScore);
      if (!isBetter) continue;
      bestRank = entry.key;
      bestFinalScore = entry.value;
      bestCurrentScore = currentScore;
      bestBaseScore = baseScore;
    }
    return bestRank;
  }

  void onDiscardUsed() {
    for (var slot = 0; slot < ownedJesters.length; slot++) {
      if (ownedJesters[slot].id == 'green_jester') {
        _statefulValuesBySlot.update(
          slot,
          (value) => value - 1,
          ifAbsent: () => -1,
        );
      }
    }
  }

  void _generateOffers({
    required List<RummiJesterCard> catalog,
    required Random rng,
    List<String> preferredOfferIds = const [],
    int? offerCountOverride,
    RummiMarketPressureProfile pressureProfile =
        RummiMarketPressureProfile.standard,
  }) {
    shopOffers.clear();
    final ownedIds = ownedJesters.map((card) => card.id).toSet();
    final pool = catalog.where((card) => !ownedIds.contains(card.id)).toList();
    if (pool.isEmpty) {
      return;
    }

    final requestedCount =
        offerCountOverride ?? marketModifiers.jesterOfferSlotCount;
    final slotCount = min(requestedCount, pool.length);
    final pickedIds = <String>{};
    for (final preferredId in preferredOfferIds) {
      if (shopOffers.length >= slotCount) break;
      final index = pool.indexWhere(
        (card) => card.id == preferredId && !pickedIds.contains(card.id),
      );
      if (index < 0) continue;
      final selected = pool.removeAt(index);
      pickedIds.add(selected.id);
      shopOffers.add(
        RummiShopOffer(slotIndex: shopOffers.length, card: selected),
      );
      seenMarketJesterIds.add(selected.id);
    }
    final focusSlot = _missingJesterGrowthFocusSlot(
      rng,
      startSlot: shopOffers.length,
      slotCount: slotCount,
      pressureProfile: pressureProfile,
    );
    for (var slot = 0; slot < slotCount && pool.isNotEmpty; slot++) {
      if (slot < shopOffers.length) {
        continue;
      }
      if (slot == focusSlot) {
        final missingTags = _missingJesterGrowthTags();
        final focusPool = pool
            .where((card) => _jesterMatchesAnyGrowthTag(card, missingTags))
            .toList(growable: false);
        if (focusPool.isNotEmpty) {
          final selected = _pickWeightedShopJester(pool: focusPool, rng: rng);
          pool.remove(selected);
          shopOffers.add(RummiShopOffer(slotIndex: slot, card: selected));
          seenMarketJesterIds.add(selected.id);
          continue;
        }
      }
      final selected = _pickWeightedShopJester(pool: pool, rng: rng);
      pool.remove(selected);
      shopOffers.add(RummiShopOffer(slotIndex: slot, card: selected));
      seenMarketJesterIds.add(selected.id);
    }
  }

  void _generateTileOffers(Random rng) {
    tileOffers.clear();
    final usedCodes = <String>{};
    final allTiles = buildStandardPokerDeck(copiesPerTile: 1);
    while (tileOffers.length < 3 && usedCodes.length < allTiles.length) {
      final tile = allTiles[rng.nextInt(allTiles.length)];
      final code = tile.code;
      if (!usedCodes.add(code)) continue;
      tileOffers.add(
        decorateTileWithMarketStyleModifiers(
          tile,
          stageIndex: stageIndex,
          offerIndex: tileOffers.length,
        ),
      );
    }
  }

  RummiJesterCard _pickWeightedShopJester({
    required List<RummiJesterCard> pool,
    required Random rng,
  }) {
    final candidates = pool;
    final weights = candidates
        .map(_shopOfferWeightForCard)
        .toList(growable: false);
    final totalWeight = weights.fold<int>(0, (sum, weight) => sum + weight);
    if (totalWeight <= 0) {
      return candidates[rng.nextInt(candidates.length)];
    }

    var roll = rng.nextInt(totalWeight);
    for (var i = 0; i < candidates.length; i++) {
      roll -= weights[i];
      if (roll < 0) {
        return candidates[i];
      }
    }
    return candidates.last;
  }

  int _shopOfferWeightForRarity(RummiJesterRarity rarity) {
    return RummiStationBandMarketPolicy.forStage(stageIndex).jesterRarityWeight(
      rarity,
      rarityWeightBonus: marketModifiers.rarityWeightBonus,
    );
  }

  int _shopOfferWeightForCard(RummiJesterCard card) {
    var weight = _shopOfferWeightForRarity(card.rarity);
    // 수집 audit가 실제 미수집 후보 노출을 볼 수 있도록 개별 미수집에도
    // 작은 가중치를 준다. 성장축 보강보다 약하며, 직접 지급/고정 노출은 아니다.
    if (!boughtJesterIds.contains(card.id)) weight += 45;
    if (!seenMarketJesterIds.contains(card.id)) weight += 90;
    return weight < 1 ? 1 : weight;
  }

  int? _missingJesterGrowthFocusSlot(
    Random rng, {
    required int startSlot,
    required int slotCount,
    RummiMarketPressureProfile pressureProfile =
        RummiMarketPressureProfile.standard,
  }) {
    final missingTags = _missingJesterGrowthTags();
    if (missingTags.isEmpty || stageIndex <= 2 || startSlot >= slotCount) {
      return null;
    }
    final chance = stageIndex >= 6
        ? 45
        : stageIndex >= 4
        ? 35
        : 25;
    final pressureBonus =
        pressureProfile == RummiMarketPressureProfile.highStakes ? 15 : 0;
    if (rng.nextInt(100) >= chance + pressureBonus) return null;
    return startSlot + rng.nextInt(slotCount - startSlot);
  }

  Set<String> _missingJesterGrowthTags() {
    final station = stageIndex < 1 ? 1 : stageIndex;
    if (station <= 2) return const {};

    final ownedTags = <String>{};
    for (final card in ownedJesters) {
      ownedTags.addAll(_growthTagsForJester(card));
    }

    final missing = <String>{};
    final hasScoreGrowth =
        ownedTags.contains('score') ||
        ownedTags.contains('rank') ||
        ownedTags.contains('tile_color');
    if (!hasScoreGrowth) {
      missing.addAll(const ['score', 'rank', 'tile_color']);
    }

    if (station >= 6) {
      final hasBossGrowth =
          ownedTags.contains('boss') || ownedTags.contains('xmult');
      if (!hasBossGrowth) {
        missing.addAll(const ['boss', 'xmult']);
      }
    }

    return Set<String>.unmodifiable(missing);
  }

  static bool _jesterMatchesAnyGrowthTag(
    RummiJesterCard card,
    Set<String> expectedTags,
  ) {
    if (expectedTags.isEmpty) return false;
    for (final tag in _growthTagsForJester(card)) {
      if (expectedTags.contains(tag)) {
        return true;
      }
    }
    return false;
  }

  static Set<String> _growthTagsForJester(RummiJesterCard card) {
    final tags = <String>{};
    if (card.effectType == 'chips_bonus' ||
        card.effectType == 'mult_bonus' ||
        card.effectType == 'stateful_growth') {
      tags.add('score');
    }
    if (card.effectType == 'xmult_bonus') {
      tags.addAll(const ['score', 'xmult', 'boss']);
    }
    if (card.conditionType == 'rank_scored') {
      tags.add('rank');
    }
    if (card.conditionType == 'tile_color_scored') {
      tags.add('tile_color');
    }
    return Set<String>.unmodifiable(tags);
  }

  static int _sellPriceFor(RummiJesterCard card) {
    final value = card.baseCost ~/ 2;
    return value < 1 ? 1 : value;
  }

  int _sumOwnedItemEffectAmount({
    required ItemCatalog? itemCatalog,
    required String timing,
    required String op,
  }) {
    if (itemCatalog == null) return 0;
    var total = 0;
    for (final entry in itemInventory.ownedItems) {
      if (entry.count <= 0 || !entry.isActive) continue;
      final item = itemCatalog.findById(entry.itemId);
      if (item == null) continue;
      if (item.effect.timing != timing || item.effect.op != op) continue;
      final amount = (item.effect.amount ?? 0).toInt();
      if (amount > 0) total += amount * entry.count;
    }
    return total;
  }

  bool _cheapestFirstOfferDiscountApplies(int basePrice, String category) {
    if (marketModifiers.cheapestFirstOfferDiscount <= 0) return false;
    final firstJesterPrice = shopOffers.isEmpty ? null : shopOffers.first.price;
    final firstItemPrice = category == 'item' ? basePrice : null;
    return switch (category) {
      'jester' =>
        firstJesterPrice != null &&
            (firstItemPrice == null || firstJesterPrice <= firstItemPrice),
      'item' =>
        firstItemPrice != null &&
            (firstJesterPrice == null || firstItemPrice < firstJesterPrice),
      _ => false,
    };
  }

  void _consumePurchaseDiscounts(
    String category, {
    bool consumeCheapestFirstOfferDiscount = true,
  }) {
    marketModifiers = marketModifiers.copyWith(
      nextPurchaseDiscount: 0,
      nextJesterPurchaseDiscount: category == 'jester'
          ? 0
          : marketModifiers.nextJesterPurchaseDiscount,
      nextItemPurchaseDiscount: category == 'item'
          ? 0
          : marketModifiers.nextItemPurchaseDiscount,
      cheapestFirstOfferDiscount: consumeCheapestFirstOfferDiscount
          ? 0
          : marketModifiers.cheapestFirstOfferDiscount,
    );
  }

  void _initializeStateForSlot(int slotIndex, RummiJesterCard card) {
    // 상태형 Jester는 장착 슬롯 인덱스를 키로 쓴다.
    // 이후 점수 계산도 같은 슬롯 인덱스로 state를 조회하므로 순서가 규칙이다.
    final initialValue = switch (card.id) {
      'popcorn' || 'ice_cream' => card.value ?? 0,
      _ => 0,
    };
    if (initialValue > 0) {
      _statefulValuesBySlot[slotIndex] = initialValue;
    }
  }

  void _removeStateAtSlot(int slotIndex) {
    _statefulValuesBySlot.remove(slotIndex);
    final shifted = <int, int>{};
    for (final entry in _statefulValuesBySlot.entries) {
      final nextKey = entry.key > slotIndex ? entry.key - 1 : entry.key;
      shifted[nextKey] = entry.value;
    }
    _statefulValuesBySlot
      ..clear()
      ..addAll(shifted);
  }

  void _applyRoundEndStateDecay() {
    for (var slot = 0; slot < ownedJesters.length; slot++) {
      if (ownedJesters[slot].id == 'popcorn') {
        final next = (_statefulValuesBySlot[slot] ?? 0) - 4;
        _statefulValuesBySlot[slot] = next < 0 ? 0 : next;
      }
    }
  }

  RummiRoundEndEconomyBonus? _buildRoundEndEconomyBonus({
    required RummiJesterCard card,
    required int remainingBoardDiscards,
    required int remainingHandDiscards,
  }) {
    if (!card.isSupportedInCurrentEconomyMeta) {
      return null;
    }

    final gold = switch (card.id) {
      'egg' || 'golden_jester' => card.value ?? 0,
      'delayed_gratification' =>
        (card.value ?? 0) * (remainingBoardDiscards + remainingHandDiscards),
      _ => 0,
    };
    if (gold <= 0) {
      return null;
    }
    return RummiRoundEndEconomyBonus(
      jesterId: card.id,
      displayName: card.displayName,
      gold: gold,
    );
  }
}
