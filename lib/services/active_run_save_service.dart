import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../app_config.dart';
import '../logic/rummi_poker_grid/hand_rank.dart';
import '../logic/rummi_poker_grid/item_definition.dart';
import '../logic/rummi_poker_grid/jester_catalog_loader.dart';
import '../logic/rummi_poker_grid/jester_meta.dart';
import '../logic/rummi_poker_grid/models/board.dart';
import '../logic/rummi_poker_grid/models/poker_deck.dart';
import '../logic/rummi_poker_grid/models/tile.dart';
import '../logic/rummi_poker_grid/rummi_blind_state.dart';
import '../logic/rummi_poker_grid/rummi_hand_growth.dart';
import '../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../logic/rummi_poker_grid/rummi_ruleset.dart';
import '../resources/asset_paths.dart';
import 'new_run_setup.dart';
import '../utils/storage_helper.dart';
import 'active_run_save_facade.dart';
import 'device_key_store.dart';

part 'active_run_save_models.dart';

class ActiveRunSaveService {
  ActiveRunSaveService._();

  static const int schemaVersion = 2;

  static Future<ActiveRunAvailability> inspectActiveRun() async {
    final payload = StorageHelper.readString(
      StorageKeys.activeRunPayloadV1,
      defaultValue: '',
    );
    final signature = StorageHelper.readString(
      StorageKeys.activeRunSignatureV1,
      defaultValue: '',
    );
    if (payload.isEmpty || signature.isEmpty) {
      return ActiveRunAvailability.none;
    }
    final deviceKey = await _readDeviceKey();
    if (deviceKey == null || deviceKey.isEmpty) {
      return ActiveRunAvailability.invalid;
    }
    if (_signPayload(payload, deviceKey) != signature) {
      return ActiveRunAvailability.invalid;
    }
    try {
      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      final save = ActiveRunSaveData.fromJson(decoded);
      if (save.schemaVersion != schemaVersion) {
        return ActiveRunAvailability.invalid;
      }
      return ActiveRunAvailability.available;
    } catch (_) {
      return ActiveRunAvailability.invalid;
    }
  }

  static bool hasStoredActiveRun() {
    final payload = StorageHelper.readString(
      StorageKeys.activeRunPayloadV1,
      defaultValue: '',
    );
    final signature = StorageHelper.readString(
      StorageKeys.activeRunSignatureV1,
      defaultValue: '',
    );
    return payload.isNotEmpty || signature.isNotEmpty;
  }

  static Future<void> saveActiveRun({
    required ActiveRunScene activeScene,
    required NewRunDifficulty difficulty,
    NewRunModifier runModifier = NewRunModifier.basic,
    required RummiPokerGridSession session,
    required RummiRunProgress runProgress,
    required ActiveRunStageSnapshot stageStartSnapshot,
  }) async {
    final payload = runtimeStateToJson(
      ActiveRunRuntimeState(
        activeScene: activeScene,
        difficulty: difficulty,
        runModifier: runModifier,
        session: session,
        runProgress: runProgress,
        stageStartSnapshot: stageStartSnapshot,
      ),
    );
    final deviceKey = await _ensureDeviceKey();
    final signature = _signPayload(payload, deviceKey);
    await StorageHelper.write(StorageKeys.activeRunPayloadV1, payload);
    await StorageHelper.write(StorageKeys.activeRunSignatureV1, signature);
  }

  static Future<void> saveRuntimeState(ActiveRunRuntimeState runtime) {
    return saveActiveRun(
      activeScene: runtime.activeScene,
      difficulty: runtime.difficulty,
      runModifier: runtime.runModifier,
      session: runtime.session,
      runProgress: runtime.runProgress,
      stageStartSnapshot: runtime.stageStartSnapshot,
    );
  }

  static Future<ActiveRunRuntimeState?> loadActiveRun() async {
    final save = await _loadVerifiedSaveData();
    if (save == null) return null;
    return runtimeStateFromSaveData(save);
  }

  static Future<ActiveRunRuntimeState> runtimeStateFromJson(String jsonString) {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    return runtimeStateFromSaveData(ActiveRunSaveData.fromJson(decoded));
  }

  static Future<ActiveRunRuntimeState> runtimeStateFromSaveData(
    ActiveRunSaveData save,
  ) async {
    final catalog = await _loadCatalog();

    final session = _restoreSession(save.session);
    final runProgress = _restoreRunProgress(save.runProgress, catalog);
    final stageStartSnapshot = ActiveRunStageSnapshot(
      session: _restoreSession(save.stageStartSession),
      runProgress: _restoreRunProgress(save.stageStartRunProgress, catalog),
    );

    return ActiveRunRuntimeState(
      activeScene: ActiveRunScene.values.byName(save.activeScene),
      difficulty: NewRunSetup.parseDifficulty(save.difficulty),
      runModifier: NewRunModifier.parse(save.runModifier),
      session: session,
      runProgress: runProgress,
      stageStartSnapshot: stageStartSnapshot,
    );
  }

  static String runtimeStateToJson(ActiveRunRuntimeState runtime) {
    final save = ActiveRunSaveData(
      schemaVersion: schemaVersion,
      savedAtIso8601: DateTime.now().toUtc().toIso8601String(),
      activeScene: runtime.activeScene.name,
      difficulty: runtime.difficulty.name,
      runModifier: runtime.runModifier.id,
      session: _buildSavedSessionData(runtime.session),
      runProgress: _buildSavedRunProgressData(runtime.runProgress),
      stageStartSession: _buildSavedSessionData(
        runtime.stageStartSnapshot.session,
      ),
      stageStartRunProgress: _buildSavedRunProgressData(
        runtime.stageStartSnapshot.runProgress,
      ),
    );
    return jsonEncode(save.toJson());
  }

  static Future<RummiActiveRunSaveFacade?> loadActiveRunSummary() async {
    final save = await _loadVerifiedSaveData();
    if (save == null) return null;
    return RummiActiveRunSaveFacade.fromSaveData(save);
  }

  static Future<void> clearActiveRun() async {
    await StorageHelper.remove(StorageKeys.activeRunPayloadV1);
    await StorageHelper.remove(StorageKeys.activeRunSignatureV1);
  }

  static String _signPayload(String payload, String deviceKey) {
    final hmac = Hmac(sha256, utf8.encode(deviceKey));
    return hmac.convert(utf8.encode(payload)).toString();
  }

  static Future<ActiveRunSaveData?> _loadVerifiedSaveData() async {
    final availability = await inspectActiveRun();
    if (availability != ActiveRunAvailability.available) {
      return null;
    }

    final payload = StorageHelper.readString(
      StorageKeys.activeRunPayloadV1,
      defaultValue: '',
    );
    if (payload.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    return ActiveRunSaveData.fromJson(decoded);
  }

  static Future<String> _ensureDeviceKey() async {
    final existing = await _readDeviceKey();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final bytes = List<int>.generate(32, (_) => _secureRandom().nextInt(256));
    final key = base64UrlEncode(bytes);
    await _writeDeviceKey(key);
    return key;
  }

  static Future<String?> _readDeviceKey() async {
    return getDeviceKeyStore().read();
  }

  static Future<void> _writeDeviceKey(String key) async {
    await getDeviceKeyStore().write(key);
  }

  static Random _secureRandom() {
    try {
      return Random.secure();
    } catch (_) {
      return Random();
    }
  }

  static Future<RummiJesterCatalog> _loadCatalog() async {
    try {
      return await RummiJesterCatalogLoader.loadFromAsset(
        AssetPaths.jestersCommon,
      );
    } catch (_) {
      final jsonString = await rootBundle.loadString(AssetPaths.jestersCommon);
      return RummiJesterCatalog.fromJsonString(jsonString);
    }
  }

  static RummiJesterCard _findCardOrThrow(
    RummiJesterCatalog catalog,
    String id,
  ) {
    final card = catalog.findById(id);
    if (card == null) {
      throw StateError('저장 데이터에 없는 Jester id: $id');
    }
    return card;
  }

  static RummiHandRank? _tryParseHandRank(String name) {
    for (final rank in RummiHandRank.values) {
      if (rank.name == name) {
        return rank;
      }
    }
    return null;
  }

  static ActiveRunStageSnapshot captureStageStartSnapshot({
    required RummiPokerGridSession session,
    required RummiRunProgress runProgress,
  }) {
    return ActiveRunStageSnapshot(
      session: session.copySnapshot(),
      runProgress: runProgress.copySnapshot(),
    );
  }

  static SavedSessionData _buildSavedSessionData(
    RummiPokerGridSession session,
  ) {
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

  static SavedRunProgressData _buildSavedRunProgressData(
    RummiRunProgress runProgress,
  ) {
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
          runProgress.snapshotOverkillGrowthClaimedStationKeys().toList()
            ..sort(),
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

  static RummiPokerGridSession _restoreSession(SavedSessionData data) {
    final board = RummiBoard.fromSnapshot(
      data.boardCells
          .map((cell) => cell == null ? null : Tile.fromJson(cell))
          .toList(growable: false),
    );
    final deck = PokerDeck.fromSnapshot(
      data.deckPile.map(Tile.fromJson).toList(growable: false),
    );
    final hand = data.hand.map(Tile.fromJson).toList(growable: false);
    final eliminated = data.eliminated
        .map(Tile.fromJson)
        .toList(growable: false);
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

  static RummiRunProgress _restoreRunProgress(
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
}
