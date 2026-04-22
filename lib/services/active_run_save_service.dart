import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../app_config.dart';
import '../logic/rummi_poker_grid/hand_rank.dart';
import '../logic/rummi_poker_grid/item_definition.dart';
import '../logic/rummi_poker_grid/jester_meta.dart';
import '../logic/rummi_poker_grid/models/board.dart';
import '../logic/rummi_poker_grid/models/poker_deck.dart';
import '../logic/rummi_poker_grid/models/tile.dart';
import '../logic/rummi_poker_grid/rummi_blind_state.dart';
import '../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../logic/rummi_poker_grid/rummi_ruleset.dart';
import '../resources/asset_paths.dart';
import 'new_run_setup.dart';
import '../utils/storage_helper.dart';
import 'active_run_save_facade.dart';
import 'device_key_store.dart';

enum ActiveRunScene { battle, shop, blindSelect }

enum ActiveRunAvailability { none, available, invalid }

class ActiveRunRuntimeState {
  const ActiveRunRuntimeState({
    required this.activeScene,
    required this.difficulty,
    required this.session,
    required this.runProgress,
    required this.stageStartSnapshot,
  });

  final ActiveRunScene activeScene;
  final NewRunDifficulty difficulty;
  final RummiPokerGridSession session;
  final RummiRunProgress runProgress;
  final ActiveRunStageSnapshot stageStartSnapshot;
}

class ActiveRunStageSnapshot {
  const ActiveRunStageSnapshot({
    required this.session,
    required this.runProgress,
  });

  final RummiPokerGridSession session;
  final RummiRunProgress runProgress;
}

class ActiveRunSaveData {
  const ActiveRunSaveData({
    required this.schemaVersion,
    required this.savedAtIso8601,
    required this.activeScene,
    required this.difficulty,
    required this.session,
    required this.runProgress,
    required this.stageStartSession,
    required this.stageStartRunProgress,
  });

  final int schemaVersion;
  final String savedAtIso8601;
  final String activeScene;
  final String difficulty;
  final SavedSessionData session;
  final SavedRunProgressData runProgress;
  final SavedSessionData stageStartSession;
  final SavedRunProgressData stageStartRunProgress;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'savedAt': savedAtIso8601,
    'activeScene': activeScene,
    'difficulty': difficulty,
    'session': session.toJson(),
    'runProgress': runProgress.toJson(),
    'stageStartSession': stageStartSession.toJson(),
    'stageStartRunProgress': stageStartRunProgress.toJson(),
  };

  static ActiveRunSaveData fromJson(Map<String, dynamic> json) {
    return ActiveRunSaveData(
      schemaVersion: (json['schemaVersion'] as num).toInt(),
      savedAtIso8601: json['savedAt'] as String,
      activeScene: json['activeScene'] as String,
      difficulty:
          json['difficulty'] as String? ?? NewRunDifficulty.standard.name,
      session: SavedSessionData.fromJson(
        json['session'] as Map<String, dynamic>,
      ),
      runProgress: SavedRunProgressData.fromJson(
        json['runProgress'] as Map<String, dynamic>,
      ),
      stageStartSession: SavedSessionData.fromJson(
        json['stageStartSession'] as Map<String, dynamic>,
      ),
      stageStartRunProgress: SavedRunProgressData.fromJson(
        json['stageStartRunProgress'] as Map<String, dynamic>,
      ),
    );
  }
}

class SavedSessionData {
  const SavedSessionData({
    required this.runSeed,
    this.rulesetId = RummiRuleset.currentDefaultsPersistenceId,
    required this.deckCopiesPerTile,
    required this.maxHandSize,
    required this.runRandomState,
    required this.blind,
    required this.deckPile,
    required this.boardCells,
    required this.hand,
    required this.eliminated,
    this.boardMoveHistory = const [],
    this.confirmModifiers = const [],
    this.confirmCountThisStation = 0,
    this.firstConfirmScoreThisStation = 0,
  });

  final int runSeed;
  final String rulesetId;
  final int deckCopiesPerTile;
  final int maxHandSize;
  final int runRandomState;
  final Map<String, dynamic> blind;
  final List<Map<String, dynamic>> deckPile;
  final List<Map<String, dynamic>?> boardCells;
  final List<Map<String, dynamic>> hand;
  final List<Map<String, dynamic>> eliminated;
  final List<Map<String, dynamic>> boardMoveHistory;
  final List<Map<String, dynamic>> confirmModifiers;
  final int confirmCountThisStation;
  final int firstConfirmScoreThisStation;

  Map<String, dynamic> toJson() => {
    'runSeed': runSeed,
    'rulesetId': rulesetId,
    'deckCopiesPerTile': deckCopiesPerTile,
    'maxHandSize': maxHandSize,
    'runRandomState': runRandomState,
    'blind': blind,
    'deckPile': deckPile,
    'boardCells': boardCells,
    'hand': hand,
    'eliminated': eliminated,
    'boardMoveHistory': boardMoveHistory,
    'confirmModifiers': confirmModifiers,
    'confirmCountThisStation': confirmCountThisStation,
    'firstConfirmScoreThisStation': firstConfirmScoreThisStation,
  };

  static SavedSessionData fromJson(Map<String, dynamic> json) {
    return SavedSessionData(
      runSeed: (json['runSeed'] as num).toInt(),
      rulesetId:
          json['rulesetId'] as String? ??
          RummiRuleset.currentDefaultsPersistenceId,
      deckCopiesPerTile: (json['deckCopiesPerTile'] as num).toInt(),
      maxHandSize: (json['maxHandSize'] as num).toInt(),
      runRandomState: (json['runRandomState'] as num).toInt(),
      blind: Map<String, dynamic>.from(json['blind'] as Map),
      deckPile: (json['deckPile'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(Map<String, dynamic>.from)
          .toList(growable: false),
      boardCells: (json['boardCells'] as List<dynamic>)
          .map(
            (cell) =>
                cell == null ? null : Map<String, dynamic>.from(cell as Map),
          )
          .toList(growable: false),
      hand: (json['hand'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(Map<String, dynamic>.from)
          .toList(growable: false),
      eliminated: (json['eliminated'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(Map<String, dynamic>.from)
          .toList(growable: false),
      boardMoveHistory: (json['boardMoveHistory'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(Map<String, dynamic>.from)
          .toList(growable: false),
      confirmModifiers: (json['confirmModifiers'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(Map<String, dynamic>.from)
          .toList(growable: false),
      confirmCountThisStation:
          (json['confirmCountThisStation'] as num?)?.toInt() ?? 0,
      firstConfirmScoreThisStation:
          (json['firstConfirmScoreThisStation'] as num?)?.toInt() ?? 0,
    );
  }
}

class SavedShopOfferData {
  const SavedShopOfferData({
    required this.slotIndex,
    required this.cardId,
    required this.price,
  });

  final int slotIndex;
  final String cardId;
  final int price;

  Map<String, dynamic> toJson() => {
    'slotIndex': slotIndex,
    'cardId': cardId,
    'price': price,
  };

  static SavedShopOfferData fromJson(Map<String, dynamic> json) {
    return SavedShopOfferData(
      slotIndex: (json['slotIndex'] as num).toInt(),
      cardId: json['cardId'] as String,
      price: (json['price'] as num).toInt(),
    );
  }
}

class SavedRunProgressData {
  const SavedRunProgressData({
    required this.stageIndex,
    this.currentStationBlindTierIndex = 0,
    required this.gold,
    required this.rerollCost,
    required this.ownedJesterIds,
    required this.shopOffers,
    required this.statefulValuesBySlot,
    required this.playedHandCounts,
    this.itemInventory = const RunInventoryState(),
    this.marketModifiers = const RummiMarketModifierState(),
  });

  final int stageIndex;
  final int currentStationBlindTierIndex;
  final int gold;
  final int rerollCost;
  final List<String> ownedJesterIds;
  final List<SavedShopOfferData> shopOffers;
  final Map<String, int> statefulValuesBySlot;
  final Map<String, int> playedHandCounts;
  final RunInventoryState itemInventory;
  final RummiMarketModifierState marketModifiers;

  Map<String, dynamic> toJson() => {
    'stageIndex': stageIndex,
    'currentStationBlindTierIndex': currentStationBlindTierIndex,
    'gold': gold,
    'rerollCost': rerollCost,
    'ownedJesterIds': ownedJesterIds,
    'shopOffers': shopOffers.map((offer) => offer.toJson()).toList(),
    'statefulValuesBySlot': statefulValuesBySlot,
    'playedHandCounts': playedHandCounts,
    'itemInventory': itemInventory.toJson(),
    'marketModifiers': marketModifiers.toJson(),
  };

  static SavedRunProgressData fromJson(Map<String, dynamic> json) {
    return SavedRunProgressData(
      stageIndex: (json['stageIndex'] as num).toInt(),
      currentStationBlindTierIndex:
          (json['currentStationBlindTierIndex'] as num?)?.toInt() ?? 0,
      gold: (json['gold'] as num).toInt(),
      rerollCost: (json['rerollCost'] as num).toInt(),
      ownedJesterIds: (json['ownedJesterIds'] as List<dynamic>)
          .map((value) => value as String)
          .toList(growable: false),
      shopOffers: (json['shopOffers'] as List<dynamic>)
          .map(
            (value) =>
                SavedShopOfferData.fromJson(Map<String, dynamic>.from(value)),
          )
          .toList(growable: false),
      statefulValuesBySlot: (json['statefulValuesBySlot'] as Map).map(
        (key, value) => MapEntry(key as String, (value as num).toInt()),
      ),
      playedHandCounts: (json['playedHandCounts'] as Map).map(
        (key, value) => MapEntry(key as String, (value as num).toInt()),
      ),
      itemInventory: RunInventoryState.fromJson(
        (json['itemInventory'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      marketModifiers: RummiMarketModifierState.fromJson(
        (json['marketModifiers'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
    );
  }
}

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
    required RummiPokerGridSession session,
    required RummiRunProgress runProgress,
    required ActiveRunStageSnapshot stageStartSnapshot,
  }) async {
    final savedSession = _buildSavedSessionData(session);
    final savedRunProgress = _buildSavedRunProgressData(runProgress);
    final save = ActiveRunSaveData(
      schemaVersion: schemaVersion,
      savedAtIso8601: DateTime.now().toUtc().toIso8601String(),
      activeScene: activeScene.name,
      difficulty: difficulty.name,
      session: savedSession,
      runProgress: savedRunProgress,
      stageStartSession: _buildSavedSessionData(stageStartSnapshot.session),
      stageStartRunProgress: _buildSavedRunProgressData(
        stageStartSnapshot.runProgress,
      ),
    );
    final payload = jsonEncode(save.toJson());
    final deviceKey = await _ensureDeviceKey();
    final signature = _signPayload(payload, deviceKey);
    await StorageHelper.write(StorageKeys.activeRunPayloadV1, payload);
    await StorageHelper.write(StorageKeys.activeRunSignatureV1, signature);
  }

  static Future<void> saveRuntimeState(ActiveRunRuntimeState runtime) {
    return saveActiveRun(
      activeScene: runtime.activeScene,
      difficulty: runtime.difficulty,
      session: runtime.session,
      runProgress: runtime.runProgress,
      stageStartSnapshot: runtime.stageStartSnapshot,
    );
  }

  static Future<ActiveRunRuntimeState?> loadActiveRun() async {
    final save = await _loadVerifiedSaveData();
    if (save == null) return null;
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
      session: session,
      runProgress: runProgress,
      stageStartSnapshot: stageStartSnapshot,
    );
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
      return await RummiJesterCatalog.loadFromAsset(AssetPaths.jestersCommon);
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
      confirmModifiers: session.confirmModifiers
          .map((modifier) => modifier.toJson())
          .toList(growable: false),
      confirmCountThisStation: session.confirmCountThisStation,
      firstConfirmScoreThisStation: session.firstConfirmScoreThisStation,
    );
  }

  static SavedRunProgressData _buildSavedRunProgressData(
    RummiRunProgress runProgress,
  ) {
    return SavedRunProgressData(
      stageIndex: runProgress.stageIndex,
      currentStationBlindTierIndex: runProgress.currentStationBlindTierIndex,
      gold: runProgress.gold,
      rerollCost: runProgress.rerollCost,
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
      itemInventory: runProgress.itemInventory,
      marketModifiers: runProgress.marketModifiers,
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
      confirmModifiers: data.confirmModifiers
          .map(RummiConfirmModifier.fromJson)
          .toList(growable: false),
      confirmCountThisStation: data.confirmCountThisStation,
      firstConfirmScoreThisStation: data.firstConfirmScoreThisStation,
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
    final playedHandCounts = data.playedHandCounts.map(
      (key, value) => MapEntry(RummiHandRank.values.byName(key), value),
    );
    return RummiRunProgress.restore(
      stageIndex: data.stageIndex,
      currentStationBlindTierIndex: data.currentStationBlindTierIndex,
      gold: data.gold,
      rerollCost: data.rerollCost,
      ownedJesters: ownedJesters,
      shopOffers: shopOffers,
      statefulValuesBySlot: statefulValuesBySlot,
      playedHandCounts: playedHandCounts,
      itemInventory: data.itemInventory,
      marketModifiers: data.marketModifiers,
    );
  }
}
