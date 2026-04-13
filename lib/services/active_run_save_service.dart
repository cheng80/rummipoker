import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../app_config.dart';
import '../logic/rummi_poker_grid/hand_rank.dart';
import '../logic/rummi_poker_grid/jester_meta.dart';
import '../logic/rummi_poker_grid/models/board.dart';
import '../logic/rummi_poker_grid/models/poker_deck.dart';
import '../logic/rummi_poker_grid/models/tile.dart';
import '../logic/rummi_poker_grid/rummi_blind_state.dart';
import '../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../resources/asset_paths.dart';
import '../utils/storage_helper.dart';

enum ActiveRunScene { battle, shop }

enum ActiveRunAvailability { none, available, invalid }

class ActiveRunRuntimeState {
  const ActiveRunRuntimeState({
    required this.activeScene,
    required this.session,
    required this.runProgress,
  });

  final ActiveRunScene activeScene;
  final RummiPokerGridSession session;
  final RummiRunProgress runProgress;
}

class ActiveRunSaveData {
  const ActiveRunSaveData({
    required this.schemaVersion,
    required this.savedAtIso8601,
    required this.activeScene,
    required this.session,
    required this.runProgress,
  });

  final int schemaVersion;
  final String savedAtIso8601;
  final String activeScene;
  final SavedSessionData session;
  final SavedRunProgressData runProgress;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'savedAt': savedAtIso8601,
    'activeScene': activeScene,
    'session': session.toJson(),
    'runProgress': runProgress.toJson(),
  };

  static ActiveRunSaveData fromJson(Map<String, dynamic> json) {
    return ActiveRunSaveData(
      schemaVersion: (json['schemaVersion'] as num).toInt(),
      savedAtIso8601: json['savedAt'] as String,
      activeScene: json['activeScene'] as String,
      session: SavedSessionData.fromJson(
        json['session'] as Map<String, dynamic>,
      ),
      runProgress: SavedRunProgressData.fromJson(
        json['runProgress'] as Map<String, dynamic>,
      ),
    );
  }
}

class SavedSessionData {
  const SavedSessionData({
    required this.runSeed,
    required this.deckCopiesPerTile,
    required this.maxHandSize,
    required this.runRandomState,
    required this.blind,
    required this.deckPile,
    required this.boardCells,
    required this.hand,
    required this.eliminated,
  });

  final int runSeed;
  final int deckCopiesPerTile;
  final int maxHandSize;
  final int runRandomState;
  final Map<String, dynamic> blind;
  final List<Map<String, dynamic>> deckPile;
  final List<Map<String, dynamic>?> boardCells;
  final List<Map<String, dynamic>> hand;
  final List<Map<String, dynamic>> eliminated;

  Map<String, dynamic> toJson() => {
    'runSeed': runSeed,
    'deckCopiesPerTile': deckCopiesPerTile,
    'maxHandSize': maxHandSize,
    'runRandomState': runRandomState,
    'blind': blind,
    'deckPile': deckPile,
    'boardCells': boardCells,
    'hand': hand,
    'eliminated': eliminated,
  };

  static SavedSessionData fromJson(Map<String, dynamic> json) {
    return SavedSessionData(
      runSeed: (json['runSeed'] as num).toInt(),
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
            (cell) => cell == null
                ? null
                : Map<String, dynamic>.from(cell as Map),
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
    required this.gold,
    required this.rerollCost,
    required this.ownedJesterIds,
    required this.shopOffers,
    required this.statefulValuesBySlot,
    required this.playedHandCounts,
  });

  final int stageIndex;
  final int gold;
  final int rerollCost;
  final List<String> ownedJesterIds;
  final List<SavedShopOfferData> shopOffers;
  final Map<String, int> statefulValuesBySlot;
  final Map<String, int> playedHandCounts;

  Map<String, dynamic> toJson() => {
    'stageIndex': stageIndex,
    'gold': gold,
    'rerollCost': rerollCost,
    'ownedJesterIds': ownedJesterIds,
    'shopOffers': shopOffers.map((offer) => offer.toJson()).toList(),
    'statefulValuesBySlot': statefulValuesBySlot,
    'playedHandCounts': playedHandCounts,
  };

  static SavedRunProgressData fromJson(Map<String, dynamic> json) {
    return SavedRunProgressData(
      stageIndex: (json['stageIndex'] as num).toInt(),
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
      statefulValuesBySlot: (json['statefulValuesBySlot'] as Map)
          .map((key, value) => MapEntry(key as String, (value as num).toInt())),
      playedHandCounts: (json['playedHandCounts'] as Map).map(
        (key, value) => MapEntry(key as String, (value as num).toInt()),
      ),
    );
  }
}

class ActiveRunSaveService {
  ActiveRunSaveService._();

  static const int schemaVersion = 1;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

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
    final deviceKey = await _secureStorage.read(
      key: StorageKeys.saveDeviceKeyV1,
    );
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
    required RummiPokerGridSession session,
    required RummiRunProgress runProgress,
  }) async {
    final save = ActiveRunSaveData(
      schemaVersion: schemaVersion,
      savedAtIso8601: DateTime.now().toUtc().toIso8601String(),
      activeScene: activeScene.name,
      session: SavedSessionData(
        runSeed: session.runSeed,
        deckCopiesPerTile: session.deckCopiesPerTile,
        maxHandSize: session.maxHandSize,
        runRandomState: session.runRandom.state,
        blind: session.blind.toJson(),
        deckPile: session.deck.snapshotPile().map((tile) => tile.toJson()).toList(
          growable: false,
        ),
        boardCells: session.board
            .snapshotCells()
            .map((tile) => tile?.toJson())
            .toList(growable: false),
        hand: session.hand.map((tile) => tile.toJson()).toList(growable: false),
        eliminated: session.eliminated
            .map((tile) => tile.toJson())
            .toList(growable: false),
      ),
      runProgress: SavedRunProgressData(
        stageIndex: runProgress.stageIndex,
        gold: runProgress.gold,
        rerollCost: runProgress.rerollCost,
        ownedJesterIds:
            runProgress.ownedJesters.map((card) => card.id).toList(
                  growable: false,
                ),
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
      ),
    );
    final payload = jsonEncode(save.toJson());
    final deviceKey = await _ensureDeviceKey();
    final signature = _signPayload(payload, deviceKey);
    await StorageHelper.write(StorageKeys.activeRunPayloadV1, payload);
    await StorageHelper.write(StorageKeys.activeRunSignatureV1, signature);
  }

  static Future<ActiveRunRuntimeState?> loadActiveRun() async {
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
    final save = ActiveRunSaveData.fromJson(decoded);
    final catalog = await _loadCatalog();

    final board = RummiBoard.fromSnapshot(
      save.session.boardCells
          .map((cell) => cell == null ? null : Tile.fromJson(cell))
          .toList(growable: false),
    );
    final deck = PokerDeck.fromSnapshot(
      save.session.deckPile.map(Tile.fromJson).toList(growable: false),
    );
    final hand = save.session.hand.map(Tile.fromJson).toList(growable: false);
    final eliminated = save.session.eliminated
        .map(Tile.fromJson)
        .toList(growable: false);
    final session = RummiPokerGridSession.restored(
      runSeed: save.session.runSeed,
      deckCopiesPerTile: save.session.deckCopiesPerTile,
      maxHandSize: save.session.maxHandSize,
      runRandomState: save.session.runRandomState,
      blind: RummiBlindState.fromJson(save.session.blind),
      deck: deck,
      board: board,
      hand: hand,
      eliminated: eliminated,
    );

    final ownedJesters = save.runProgress.ownedJesterIds
        .map((id) => _findCardOrThrow(catalog, id))
        .toList(growable: false);
    final shopOffers = save.runProgress.shopOffers
        .map(
          (offer) => RummiShopOffer(
            slotIndex: offer.slotIndex,
            card: _findCardOrThrow(catalog, offer.cardId),
            price: offer.price,
          ),
        )
        .toList(growable: false);
    final statefulValuesBySlot = save.runProgress.statefulValuesBySlot.map(
      (key, value) => MapEntry(int.parse(key), value),
    );
    final playedHandCounts = save.runProgress.playedHandCounts.map(
      (key, value) => MapEntry(RummiHandRank.values.byName(key), value),
    );
    final runProgress = RummiRunProgress.restore(
      stageIndex: save.runProgress.stageIndex,
      gold: save.runProgress.gold,
      rerollCost: save.runProgress.rerollCost,
      ownedJesters: ownedJesters,
      shopOffers: shopOffers,
      statefulValuesBySlot: statefulValuesBySlot,
      playedHandCounts: playedHandCounts,
    );

    return ActiveRunRuntimeState(
      activeScene: ActiveRunScene.values.byName(save.activeScene),
      session: session,
      runProgress: runProgress,
    );
  }

  static Future<void> clearActiveRun() async {
    await StorageHelper.remove(StorageKeys.activeRunPayloadV1);
    await StorageHelper.remove(StorageKeys.activeRunSignatureV1);
  }

  static String _signPayload(String payload, String deviceKey) {
    final hmac = Hmac(sha256, utf8.encode(deviceKey));
    return hmac.convert(utf8.encode(payload)).toString();
  }

  static Future<String> _ensureDeviceKey() async {
    final existing = await _secureStorage.read(key: StorageKeys.saveDeviceKeyV1);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final bytes = List<int>.generate(32, (_) => _secureRandom().nextInt(256));
    final key = base64UrlEncode(bytes);
    await _secureStorage.write(key: StorageKeys.saveDeviceKeyV1, value: key);
    return key;
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
}
