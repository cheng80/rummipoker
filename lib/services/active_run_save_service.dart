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
part 'active_run_save_codec.dart';

class ActiveRunSaveService {
  ActiveRunSaveService._();

  static const int schemaVersion = 2;
  static const int bookmarkSlotCount = 3;

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
    ActiveRunStageSnapshot? stakeStartSnapshot,
  }) async {
    final payload = runtimeStateToJson(
      ActiveRunRuntimeState(
        activeScene: activeScene,
        difficulty: difficulty,
        runModifier: runModifier,
        session: session,
        runProgress: runProgress,
        stageStartSnapshot: stageStartSnapshot,
        stakeStartSnapshot: stakeStartSnapshot,
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
      stakeStartSnapshot: runtime.stakeStartSnapshot,
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
    final stakeStartSnapshot = ActiveRunStageSnapshot(
      session: _restoreSession(
        save.stakeStartSession ?? save.stageStartSession,
      ),
      runProgress: _restoreRunProgress(
        save.stakeStartRunProgress ?? save.stageStartRunProgress,
        catalog,
      ),
    );

    return ActiveRunRuntimeState(
      activeScene: ActiveRunScene.values.byName(save.activeScene),
      difficulty: NewRunSetup.parseDifficulty(save.difficulty),
      runModifier: NewRunModifier.parse(save.runModifier),
      session: session,
      runProgress: runProgress,
      stageStartSnapshot: stageStartSnapshot,
      stakeStartSnapshot: stakeStartSnapshot,
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
      stakeStartSession: _buildSavedSessionData(
        runtime.stakeStartSnapshot.session,
      ),
      stakeStartRunProgress: _buildSavedRunProgressData(
        runtime.stakeStartSnapshot.runProgress,
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

  static Future<List<ActiveRunBookmarkSlotView>> loadBookmarkSlots() async {
    final slots = <ActiveRunBookmarkSlotView>[];
    for (var slotIndex = 0; slotIndex < bookmarkSlotCount; slotIndex++) {
      final save = await _loadVerifiedSaveDataForKeys(
        payloadKey: _bookmarkPayloadKey(slotIndex),
        signatureKey: _bookmarkSignatureKey(slotIndex),
      );
      slots.add(
        ActiveRunBookmarkSlotView(
          slotIndex: slotIndex,
          summary: save == null
              ? null
              : RummiActiveRunSaveFacade.fromSaveData(save),
        ),
      );
    }
    return List<ActiveRunBookmarkSlotView>.unmodifiable(slots);
  }

  static Future<void> saveBookmarkSlot({
    required int slotIndex,
    required ActiveRunRuntimeState runtime,
  }) async {
    _checkBookmarkSlotIndex(slotIndex);
    final payload = runtimeStateToJson(runtime);
    final deviceKey = await _ensureDeviceKey();
    final signature = _signPayload(payload, deviceKey);
    await StorageHelper.write(_bookmarkPayloadKey(slotIndex), payload);
    await StorageHelper.write(_bookmarkSignatureKey(slotIndex), signature);
  }

  static Future<ActiveRunRuntimeState?> loadBookmarkRun(int slotIndex) async {
    _checkBookmarkSlotIndex(slotIndex);
    final save = await _loadVerifiedSaveDataForKeys(
      payloadKey: _bookmarkPayloadKey(slotIndex),
      signatureKey: _bookmarkSignatureKey(slotIndex),
    );
    if (save == null) return null;
    return runtimeStateFromSaveData(save);
  }

  static Future<ActiveRunRuntimeState?> restoreBookmarkToActiveRun(
    int slotIndex,
  ) async {
    final runtime = await loadBookmarkRun(slotIndex);
    if (runtime == null) return null;
    await saveRuntimeState(runtime);
    return runtime;
  }

  static ActiveRunStageSnapshot captureStageStartSnapshot({
    required RummiPokerGridSession session,
    required RummiRunProgress runProgress,
  }) {
    return _captureStageStartSnapshot(
      session: session,
      runProgress: runProgress,
    );
  }

  static String _signPayload(String payload, String deviceKey) {
    final hmac = Hmac(sha256, utf8.encode(deviceKey));
    return hmac.convert(utf8.encode(payload)).toString();
  }

  static Future<ActiveRunSaveData?> _loadVerifiedSaveData() async {
    return _loadVerifiedSaveDataForKeys(
      payloadKey: StorageKeys.activeRunPayloadV1,
      signatureKey: StorageKeys.activeRunSignatureV1,
    );
  }

  static Future<ActiveRunSaveData?> _loadVerifiedSaveDataForKeys({
    required String payloadKey,
    required String signatureKey,
  }) async {
    final payload = StorageHelper.readString(payloadKey, defaultValue: '');
    final signature = StorageHelper.readString(signatureKey, defaultValue: '');
    if (payload.isEmpty || signature.isEmpty) return null;
    final deviceKey = await _readDeviceKey();
    if (deviceKey == null || deviceKey.isEmpty) return null;
    if (_signPayload(payload, deviceKey) != signature) return null;
    try {
      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      final save = ActiveRunSaveData.fromJson(decoded);
      if (save.schemaVersion != schemaVersion) return null;
      return save;
    } catch (_) {
      return null;
    }
  }

  static String _bookmarkPayloadKey(int slotIndex) =>
      '${StorageKeys.activeRunBookmarkPayloadPrefix}$slotIndex';

  static String _bookmarkSignatureKey(int slotIndex) =>
      '${StorageKeys.activeRunBookmarkSignaturePrefix}$slotIndex';

  static void _checkBookmarkSlotIndex(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= bookmarkSlotCount) {
      throw RangeError.range(slotIndex, 0, bookmarkSlotCount - 1, 'slotIndex');
    }
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
}
