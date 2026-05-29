part of 'active_run_save_service.dart';

Future<RummiJesterCatalog> _loadCatalog() async {
  try {
    return await RummiJesterCatalogLoader.loadFromAsset(
      AssetPaths.jestersCommon,
    );
  } catch (_) {
    final jsonString = await rootBundle.loadString(AssetPaths.jestersCommon);
    return RummiJesterCatalog.fromJsonString(jsonString);
  }
}

RummiJesterCard _findCardOrThrow(RummiJesterCatalog catalog, String id) {
  final card = catalog.findById(id);
  if (card == null) {
    throw StateError('저장 데이터에 없는 Jester id: $id');
  }
  return card;
}

RummiHandRank? _tryParseHandRank(String name) {
  for (final rank in RummiHandRank.values) {
    if (rank.name == name) {
      return rank;
    }
  }
  return null;
}

ActiveRunStageSnapshot _captureStageStartSnapshot({
  required RummiPokerGridSession session,
  required RummiRunProgress runProgress,
}) {
  return ActiveRunStageSnapshot(
    session: session.copySnapshot(),
    runProgress: runProgress.copySnapshot(),
  );
}

SavedSessionData _buildSavedSessionData(RummiPokerGridSession session) {
  return SavedSessionData(
    runSeed: session.runSeed,
    rulesetId: session.ruleset.persistenceId,
    deckCopiesPerTile: session.deckCopiesPerTile,
    initialDeckSizeForBlind: session.initialDeckSizeForBlind,
    maxHandSize: session.maxHandSize,
    runRandomState: session.runRandom.state,
    blind: session.blind.toJson(),
    deckPile: session.deck
        .snapshotPile()
        .map((tile) => tile.toJson())
        .toList(growable: false),
    boardCells: session.board
        .snapshotCells()
        .map((tile) => tile?.toJson())
        .toList(growable: false),
    hand: session.hand.map((tile) => tile.toJson()).toList(growable: false),
    eliminated: session.eliminated
        .map((tile) => tile.toJson())
        .toList(growable: false),
    boardMoveHistory: session.boardMoveHistory
        .map((record) => record.toJson())
        .toList(growable: false),
    nextBoardMoveSlideBonusQueued: session.nextBoardMoveSlideBonusQueued,
    slideBonusTriggerCountThisStation:
        session.slideBonusTriggerCountThisStation,
    confirmModifiers: session.confirmModifiers
        .map((modifier) => modifier.toJson())
        .toList(growable: false),
    confirmCountThisStation: session.confirmCountThisStation,
    firstConfirmScoreThisStation: session.firstConfirmScoreThisStation,
    confirmedRanksThisStation: session.confirmedRanksThisStation
        .map((rank) => rank.name)
        .toList(growable: false),
    expiryGuardUsedThisStation: session.expiryGuardUsedThisStation,
  );
}

SavedRunProgressData _buildSavedRunProgressData(RummiRunProgress runProgress) {
  return SavedRunProgressData(
    stageIndex: runProgress.stageIndex,
    currentStationBlindTierIndex: runProgress.currentStationBlindTierIndex,
    runCompletionRewardClaimed: runProgress.runCompletionRewardClaimed,
    gold: runProgress.gold,
    rerollCost: runProgress.rerollCost,
    tileRerollCost: runProgress.tileRerollCost,
    itemRerollCost: runProgress.itemRerollCost,
    quickSlotRerollCost: runProgress.quickSlotRerollCost,
    passiveRerollCost: runProgress.passiveRerollCost,
    toolRerollCost: runProgress.toolRerollCost,
    gearRerollCost: runProgress.gearRerollCost,
    ownedJesterIds: runProgress.ownedJesters
        .map((card) => card.id)
        .toList(growable: false),
    shopOffers: runProgress.shopOffers
        .map(
          (offer) => SavedShopOfferData(
            slotIndex: offer.slotIndex,
            cardId: offer.card.id,
            price: offer.price,
          ),
        )
        .toList(growable: false),
    statefulValuesBySlot: runProgress.snapshotStatefulValuesBySlot().map(
      (key, value) => MapEntry('$key', value),
    ),
    playedHandCounts: runProgress.snapshotPlayedHandCounts().map(
      (key, value) => MapEntry(key.name, value),
    ),
    handGrowthStates: runProgress.snapshotHandGrowthStates().map(
      (key, value) => MapEntry(key.name, value.toJson()),
    ),
    stationRankFinalScores: runProgress.snapshotStationRankFinalScores().map(
      (key, value) => MapEntry(key.name, value),
    ),
    overkillGrowthClaimedStationKeys:
        runProgress.snapshotOverkillGrowthClaimedStationKeys().toList()..sort(),
    addedDeckTiles: runProgress.addedDeckTiles
        .map((tile) => tile.toJson())
        .toList(growable: false),
    tileOffers: runProgress.tileOffers
        .map((tile) => tile.toJson())
        .toList(growable: false),
    pendingBossTileReward: runProgress.pendingBossTileReward,
    firstShopRerollDiscountConsumed:
        runProgress.firstShopRerollDiscountConsumed,
    firstShopRerollDiscountConsumedLanes:
        runProgress.snapshotFirstShopRerollDiscountConsumedLanes().toList()
          ..sort(),
    unlockedJesterSlots: runProgress.unlockedJesterSlots,
    unlockedQuickSlotCapacity: runProgress.unlockedQuickSlotCapacity,
    unlockedPassiveRelicCapacity: runProgress.unlockedPassiveRelicCapacity,
    pendingSlotUnlockPresentations:
        runProgress
            .snapshotPendingSlotUnlockPresentations()
            .map((kind) => kind.persistenceValue)
            .toList()
          ..sort(),
    itemInventory: runProgress.itemInventory,
    marketModifiers: runProgress.marketModifiers,
    seenMarketJesterIds: runProgress.seenMarketJesterIds.toList()..sort(),
    seenMarketItemIds: runProgress.seenMarketItemIds.toList()..sort(),
    boughtJesterIds: runProgress.boughtJesterIds.toList()..sort(),
    boughtItemIds: runProgress.boughtItemIds.toList()..sort(),
    seenBossModifierIds: runProgress.seenBossModifierIds.toList()..sort(),
    clearedStationKeys: runProgress.clearedStationKeys.toList()..sort(),
  );
}

RummiPokerGridSession _restoreSession(SavedSessionData data) {
  final board = RummiBoard.fromSnapshot(
    data.boardCells
        .map((cell) => cell == null ? null : Tile.fromJson(cell))
        .toList(growable: false),
  );
  final deck = PokerDeck.fromSnapshot(
    data.deckPile.map(Tile.fromJson).toList(growable: false),
  );
  final hand = data.hand.map(Tile.fromJson).toList(growable: false);
  final eliminated = data.eliminated.map(Tile.fromJson).toList(growable: false);
  return RummiPokerGridSession.restored(
    runSeed: data.runSeed,
    deckCopiesPerTile: data.deckCopiesPerTile,
    initialDeckSizeForBlind: data.initialDeckSizeForBlind,
    maxHandSize: data.maxHandSize,
    runRandomState: data.runRandomState,
    ruleset: RummiRuleset.fromPersistenceId(data.rulesetId),
    blind: RummiBlindState.fromJson(data.blind),
    deck: deck,
    board: board,
    hand: hand,
    eliminated: eliminated,
    boardMoveHistory: data.boardMoveHistory
        .map(BoardMoveRecord.fromJson)
        .toList(growable: false),
    nextBoardMoveSlideBonusQueued: data.nextBoardMoveSlideBonusQueued,
    slideBonusTriggerCountThisStation: data.slideBonusTriggerCountThisStation,
    confirmModifiers: data.confirmModifiers
        .map(RummiConfirmModifier.fromJson)
        .toList(growable: false),
    confirmCountThisStation: data.confirmCountThisStation,
    firstConfirmScoreThisStation: data.firstConfirmScoreThisStation,
    confirmedRanksThisStation: data.confirmedRanksThisStation
        .map(RummiHandRank.values.byName)
        .toList(growable: false),
    expiryGuardUsedThisStation: data.expiryGuardUsedThisStation,
  );
}

RummiRunProgress _restoreRunProgress(
  SavedRunProgressData data,
  RummiJesterCatalog catalog,
) {
  final ownedJesters = data.ownedJesterIds
      .map((id) => _findCardOrThrow(catalog, id))
      .toList(growable: false);
  final shopOffers = data.shopOffers
      .map(
        (offer) => RummiShopOffer(
          slotIndex: offer.slotIndex,
          card: _findCardOrThrow(catalog, offer.cardId),
          price: offer.price,
        ),
      )
      .toList(growable: false);
  final statefulValuesBySlot = data.statefulValuesBySlot.map(
    (key, value) => MapEntry(int.parse(key), value),
  );
  final playedHandCounts = <RummiHandRank, int>{};
  for (final entry in data.playedHandCounts.entries) {
    final rank = _tryParseHandRank(entry.key);
    if (rank == null) continue;
    playedHandCounts[rank] = entry.value;
  }
  final stationRankFinalScores = <RummiHandRank, int>{};
  for (final entry in data.stationRankFinalScores.entries) {
    final rank = _tryParseHandRank(entry.key);
    if (rank == null) continue;
    stationRankFinalScores[rank] = entry.value;
  }
  final handGrowthStates = <RummiHandRank, RummiHandGrowthState>{};
  for (final entry in data.handGrowthStates.entries) {
    final rank = _tryParseHandRank(entry.key);
    if (rank == null) continue;
    handGrowthStates[rank] = RummiHandGrowthState.fromJson(rank, entry.value);
  }
  return RummiRunProgress.restore(
    stageIndex: data.stageIndex,
    currentStationBlindTierIndex: data.currentStationBlindTierIndex,
    runCompletionRewardClaimed: data.runCompletionRewardClaimed,
    gold: data.gold,
    rerollCost: data.rerollCost,
    tileRerollCost: data.tileRerollCost,
    itemRerollCost: data.itemRerollCost,
    quickSlotRerollCost: data.quickSlotRerollCost,
    passiveRerollCost: data.passiveRerollCost,
    toolRerollCost: data.toolRerollCost,
    gearRerollCost: data.gearRerollCost,
    ownedJesters: ownedJesters,
    shopOffers: shopOffers,
    statefulValuesBySlot: statefulValuesBySlot,
    playedHandCounts: playedHandCounts,
    handGrowthStates: handGrowthStates,
    stationRankFinalScores: stationRankFinalScores,
    overkillGrowthClaimedStationKeys: data.overkillGrowthClaimedStationKeys
        .toSet(),
    addedDeckTiles: data.addedDeckTiles
        .map(Tile.fromJson)
        .toList(growable: false),
    tileOffers: data.tileOffers.map(Tile.fromJson).toList(growable: false),
    pendingBossTileReward: data.pendingBossTileReward,
    firstShopRerollDiscountConsumed: data.firstShopRerollDiscountConsumed,
    firstShopRerollDiscountConsumedLanes: data
        .firstShopRerollDiscountConsumedLanes
        .toSet(),
    unlockedJesterSlots: data.unlockedJesterSlots,
    unlockedQuickSlotCapacity: data.unlockedQuickSlotCapacity,
    unlockedPassiveRelicCapacity: data.unlockedPassiveRelicCapacity,
    pendingSlotUnlockPresentations: data.pendingSlotUnlockPresentations
        .map(RummiSlotUnlockKind.fromPersistenceValue)
        .whereType<RummiSlotUnlockKind>()
        .toSet(),
    itemInventory: data.itemInventory,
    marketModifiers: data.marketModifiers,
    seenMarketJesterIds: data.seenMarketJesterIds.toSet(),
    seenMarketItemIds: data.seenMarketItemIds.toSet(),
    boughtJesterIds: data.boughtJesterIds.toSet(),
    boughtItemIds: data.boughtItemIds.toSet(),
    seenBossModifierIds: data.seenBossModifierIds.toSet(),
    clearedStationKeys: data.clearedStationKeys.toSet(),
  );
}
