import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_blind_state.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_ruleset.dart';
import 'package:rummipoker/utils/storage_helper.dart';
import 'package:rummipoker/services/active_run_save_facade.dart';
import 'package:rummipoker/services/device_key_store.dart';
import 'package:rummipoker/services/active_run_save_service.dart';
import 'package:rummipoker/services/new_run_setup.dart';

class _MemoryDeviceKeyStore implements DeviceKeyStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String nextValue) async {
    value = nextValue;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ActiveRunSaveService', () {
    late _MemoryDeviceKeyStore deviceKeyStore;

    setUp(() async {
      deviceKeyStore = _MemoryDeviceKeyStore();
      overrideDeviceKeyStoreForTest(deviceKeyStore);
      StorageHelper.resetForTest();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await StorageHelper.init();
    });

    tearDown(() {
      overrideDeviceKeyStoreForTest(null);
    });

    test('captureStageStartSnapshot은 이후 원본 변경과 분리된 복사본을 만든다', () {
      final session = RummiPokerGridSession(runSeed: 4242);
      final runProgress = RummiRunProgress();
      final snapshot = ActiveRunSaveService.captureStageStartSnapshot(
        session: session,
        runProgress: runProgress,
      );

      final drawn = session.drawToHand();
      expect(drawn, isNotNull);
      expect(session.tryPlaceFromHand(drawn!, 0, 0), isTrue);
      runProgress.gold += 9;

      expect(snapshot.session.board.cellAt(0, 0), isNull);
      expect(snapshot.session.hand, isEmpty);
      expect(snapshot.runProgress.gold, RummiEconomyConfig.startingGold);
    });

    test(
      'active run save DTO json roundtrip keeps stageStartSnapshot fields',
      () {
        final save = ActiveRunSaveData(
          schemaVersion: 2,
          savedAtIso8601: '2026-04-19T00:00:00.000Z',
          activeScene: ActiveRunScene.shop.name,
          difficulty: NewRunDifficulty.standard.name,
          session: const SavedSessionData(
            runSeed: 11,
            rulesetId: 'current_defaults_v1',
            deckCopiesPerTile: 1,
            maxHandSize: 1,
            runRandomState: 77,
            blind: <String, dynamic>{
              'targetScore': 300,
              'boardDiscardsRemaining': 4,
              'boardDiscardsMax': 4,
              'handDiscardsRemaining': 2,
              'handDiscardsMax': 2,
              'boardMovesRemaining': 1,
              'boardMovesMax': 3,
              'scoreTowardBlind': 25,
            },
            deckPile: <Map<String, dynamic>>[
              {'color': 'red', 'number': 7, 'id': 0},
            ],
            boardCells: <Map<String, dynamic>?>[
              {'color': 'blue', 'number': 5, 'id': 0},
              null,
            ],
            hand: <Map<String, dynamic>>[
              {'color': 'yellow', 'number': 9, 'id': 0},
            ],
            eliminated: <Map<String, dynamic>>[
              {'color': 'black', 'number': 3, 'id': 0},
            ],
            boardMoveHistory: <Map<String, dynamic>>[
              {'fromRow': 0, 'fromCol': 0, 'toRow': 1, 'toCol': 1},
            ],
          ),
          runProgress: const SavedRunProgressData(
            stageIndex: 3,
            currentStationBlindTierIndex: 1,
            gold: 42,
            rerollCost: 6,
            ownedJesterIds: <String>['jester'],
            shopOffers: <SavedShopOfferData>[
              SavedShopOfferData(slotIndex: 0, cardId: 'jester', price: 3),
            ],
            statefulValuesBySlot: <String, int>{'0': 2},
            playedHandCounts: <String, int>{'straight': 1},
            itemInventory: RunInventoryState(
              ownedItems: <OwnedItemEntry>[
                OwnedItemEntry(
                  itemId: 'board_scrap',
                  count: 2,
                  placement: ItemPlacement.quickSlot,
                ),
              ],
              quickSlotItemIds: <String>['board_scrap'],
            ),
          ),
          stageStartSession: const SavedSessionData(
            runSeed: 11,
            rulesetId: 'current_defaults_v1',
            deckCopiesPerTile: 1,
            maxHandSize: 1,
            runRandomState: 55,
            blind: <String, dynamic>{
              'targetScore': 300,
              'boardDiscardsRemaining': 4,
              'boardDiscardsMax': 4,
              'handDiscardsRemaining': 2,
              'handDiscardsMax': 2,
              'boardMovesRemaining': 3,
              'boardMovesMax': 3,
              'scoreTowardBlind': 0,
            },
            deckPile: <Map<String, dynamic>>[],
            boardCells: <Map<String, dynamic>?>[],
            hand: <Map<String, dynamic>>[],
            eliminated: <Map<String, dynamic>>[],
          ),
          stageStartRunProgress: const SavedRunProgressData(
            stageIndex: 3,
            currentStationBlindTierIndex: 0,
            gold: 10,
            rerollCost: 5,
            ownedJesterIds: <String>[],
            shopOffers: <SavedShopOfferData>[],
            statefulValuesBySlot: <String, int>{},
            playedHandCounts: <String, int>{},
          ),
        );

        final encoded = jsonEncode(save.toJson());
        final restored = ActiveRunSaveData.fromJson(
          jsonDecode(encoded) as Map<String, dynamic>,
        );

        expect(restored.schemaVersion, 2);
        expect(restored.activeScene, ActiveRunScene.shop.name);
        expect(restored.difficulty, NewRunDifficulty.standard.name);
        expect(restored.session.runSeed, 11);
        expect(restored.runProgress.currentStationBlindTierIndex, 1);
        expect(restored.session.rulesetId, 'current_defaults_v1');
        expect(restored.runProgress.gold, 42);
        expect(restored.session.blind['boardMovesRemaining'], 1);
        expect(restored.session.blind['boardMovesMax'], 3);
        expect(restored.session.boardMoveHistory.single['toRow'], 1);
        expect(
          restored.runProgress.itemInventory.ownedItems.single.itemId,
          'board_scrap',
        );
        expect(restored.runProgress.itemInventory.quickSlotItemIds, [
          'board_scrap',
        ]);
        expect(restored.stageStartSession.runRandomState, 55);
        expect(restored.stageStartSession.rulesetId, 'current_defaults_v1');
        expect(restored.stageStartRunProgress.gold, 10);
        expect(restored.stageStartRunProgress.currentStationBlindTierIndex, 0);
        expect(restored.stageStartRunProgress.rerollCost, 5);
      },
    );

    test('save facade summary maps dto scene and checkpoint aliases', () {
      final save = ActiveRunSaveData(
        schemaVersion: 2,
        savedAtIso8601: '2026-04-19T00:00:00.000Z',
        activeScene: ActiveRunScene.shop.name,
        difficulty: NewRunDifficulty.standard.name,
        session: const SavedSessionData(
          runSeed: 11,
          rulesetId: 'current_defaults_v1',
          deckCopiesPerTile: 1,
          maxHandSize: 1,
          runRandomState: 77,
          blind: <String, dynamic>{
            'targetScore': 300,
            'boardDiscardsRemaining': 4,
            'boardDiscardsMax': 4,
            'handDiscardsRemaining': 2,
            'handDiscardsMax': 2,
            'scoreTowardBlind': 25,
          },
          deckPile: <Map<String, dynamic>>[],
          boardCells: <Map<String, dynamic>?>[],
          hand: <Map<String, dynamic>>[],
          eliminated: <Map<String, dynamic>>[],
        ),
        runProgress: const SavedRunProgressData(
          stageIndex: 3,
          gold: 42,
          rerollCost: 6,
          ownedJesterIds: <String>['jester'],
          shopOffers: <SavedShopOfferData>[],
          statefulValuesBySlot: <String, int>{'0': 2},
          playedHandCounts: <String, int>{'straight': 1},
        ),
        stageStartSession: const SavedSessionData(
          runSeed: 11,
          rulesetId: 'current_defaults_v1',
          deckCopiesPerTile: 1,
          maxHandSize: 1,
          runRandomState: 55,
          blind: <String, dynamic>{
            'targetScore': 300,
            'boardDiscardsRemaining': 4,
            'boardDiscardsMax': 4,
            'handDiscardsRemaining': 2,
            'handDiscardsMax': 2,
            'scoreTowardBlind': 0,
          },
          deckPile: <Map<String, dynamic>>[],
          boardCells: <Map<String, dynamic>?>[],
          hand: <Map<String, dynamic>>[],
          eliminated: <Map<String, dynamic>>[],
        ),
        stageStartRunProgress: const SavedRunProgressData(
          stageIndex: 3,
          gold: 10,
          rerollCost: 5,
          ownedJesterIds: <String>[],
          shopOffers: <SavedShopOfferData>[],
          statefulValuesBySlot: <String, int>{},
          playedHandCounts: <String, int>{},
        ),
      );

      final summary = RummiActiveRunSaveFacade.fromSaveData(save);

      expect(summary.sceneAlias, RummiSaveSceneAlias.market);
      expect(summary.currentStationIndex, 3);
      expect(summary.currentGold, 42);
      expect(summary.checkpoint.stationIndex, 3);
      expect(summary.checkpoint.gold, 10);
    });

    test(
      'saved session dto without rulesetId falls back to current defaults',
      () {
        final restored = SavedSessionData.fromJson(const <String, dynamic>{
          'runSeed': 11,
          'deckCopiesPerTile': 1,
          'maxHandSize': 1,
          'runRandomState': 77,
          'blind': <String, dynamic>{
            'targetScore': 300,
            'boardDiscardsRemaining': 4,
            'boardDiscardsMax': 4,
            'handDiscardsRemaining': 2,
            'handDiscardsMax': 2,
            'scoreTowardBlind': 25,
          },
          'deckPile': <Map<String, dynamic>>[],
          'boardCells': <Map<String, dynamic>?>[],
          'hand': <Map<String, dynamic>>[],
          'eliminated': <Map<String, dynamic>>[],
        });

        expect(restored.rulesetId, RummiRuleset.currentDefaultsPersistenceId);
      },
    );

    test('blind json without board move fields falls back to 3/3', () {
      final restored = RummiBlindState.fromJson(const <String, dynamic>{
        'targetScore': 300,
        'boardDiscardsRemaining': 4,
        'boardDiscardsMax': 4,
        'handDiscardsRemaining': 2,
        'handDiscardsMax': 2,
        'scoreTowardBlind': 25,
      });

      expect(restored.boardMovesRemaining, 3);
      expect(restored.boardMovesMax, 3);
    });

    test(
      'saved run progress without itemInventory falls back to empty shape',
      () {
        final restored = SavedRunProgressData.fromJson(const <String, dynamic>{
          'stageIndex': 3,
          'gold': 42,
          'rerollCost': 6,
          'ownedJesterIds': <String>['jester'],
          'shopOffers': <SavedShopOfferData>[],
          'statefulValuesBySlot': <String, int>{},
          'playedHandCounts': <String, int>{},
        });

        expect(restored.itemInventory.isEmpty, isTrue);
      },
    );

    test(
      'save -> inspect -> summary/load -> clear 전체 active run 저장 흐름이 동작한다',
      () async {
        final session = RummiPokerGridSession(runSeed: 4242);
        final runProgress = RummiRunProgress();
        runProgress.gold += 12;
        session.blind.boardMovesRemaining = 2;
        runProgress.itemInventory = const RunInventoryState(
          ownedItems: <OwnedItemEntry>[
            OwnedItemEntry(
              itemId: 'board_scrap',
              count: 1,
              placement: ItemPlacement.quickSlot,
            ),
          ],
          quickSlotItemIds: <String>['board_scrap'],
        );
        final drawn = session.drawToHand();
        expect(drawn, isNotNull);
        expect(session.tryPlaceFromHand(drawn!, 0, 0), isTrue);

        final stageStartSnapshot =
            ActiveRunSaveService.captureStageStartSnapshot(
              session: session,
              runProgress: runProgress,
            );

        session.drawToHand();
        session.blind.boardMovesRemaining = 1;
        runProgress.gold += 5;
        runProgress.itemInventory = const RunInventoryState(
          ownedItems: <OwnedItemEntry>[
            OwnedItemEntry(
              itemId: 'board_scrap',
              count: 2,
              placement: ItemPlacement.quickSlot,
            ),
            OwnedItemEntry(
              itemId: 'market_compass',
              count: 1,
              placement: ItemPlacement.passiveRack,
            ),
          ],
          passiveRelicIds: <String>['market_compass'],
          quickSlotItemIds: <String>['board_scrap'],
        );

        await ActiveRunSaveService.saveActiveRun(
          activeScene: ActiveRunScene.shop,
          difficulty: NewRunDifficulty.standard,
          session: session,
          runProgress: runProgress,
          stageStartSnapshot: stageStartSnapshot,
        );

        expect(
          await ActiveRunSaveService.inspectActiveRun(),
          ActiveRunAvailability.available,
        );
        expect(ActiveRunSaveService.hasStoredActiveRun(), isTrue);

        final summary = await ActiveRunSaveService.loadActiveRunSummary();
        expect(summary, isNotNull);
        expect(summary!.sceneAlias, RummiSaveSceneAlias.market);
        expect(summary.currentRunSeed, 4242);
        expect(summary.currentGold, RummiEconomyConfig.startingGold + 17);

        final restored = await ActiveRunSaveService.loadActiveRun();
        expect(restored, isNotNull);
        expect(restored!.activeScene, ActiveRunScene.shop);
        expect(restored.difficulty, NewRunDifficulty.standard);
        expect(restored.session.runSeed, 4242);
        expect(
          restored.session.ruleset.persistenceId,
          RummiRuleset.currentDefaultsPersistenceId,
        );
        expect(restored.runProgress.gold, RummiEconomyConfig.startingGold + 17);
        expect(restored.runProgress.itemInventory.ownedItems.length, 2);
        expect(restored.session.blind.boardMovesRemaining, 1);
        expect(restored.session.blind.boardMovesMax, 3);
        expect(restored.runProgress.itemInventory.passiveRelicIds, <String>[
          'market_compass',
        ]);
        expect(restored.session.board.cellAt(0, 0), isNotNull);
        expect(
          restored.stageStartSnapshot.session.board.cellAt(0, 0),
          isNotNull,
        );
        expect(
          restored.stageStartSnapshot.runProgress.gold,
          RummiEconomyConfig.startingGold + 12,
        );
        expect(
          restored.stageStartSnapshot.session.blind.boardMovesRemaining,
          2,
        );
        expect(restored.stageStartSnapshot.session.blind.boardMovesMax, 3);
        expect(
          restored
              .stageStartSnapshot
              .runProgress
              .itemInventory
              .ownedItems
              .single
              .count,
          1,
        );

        await ActiveRunSaveService.clearActiveRun();

        expect(
          await ActiveRunSaveService.inspectActiveRun(),
          ActiveRunAvailability.none,
        );
        expect(ActiveRunSaveService.hasStoredActiveRun(), isFalse);
        expect(await ActiveRunSaveService.loadActiveRunSummary(), isNull);
        expect(await ActiveRunSaveService.loadActiveRun(), isNull);
      },
    );

    test('saveRuntimeState는 ActiveRunRuntimeState를 그대로 저장한다', () async {
      final session = RummiPokerGridSession(runSeed: 5151);
      final runProgress = RummiRunProgress()..gold += 9;
      final drawn = session.drawToHand();
      expect(drawn, isNotNull);
      expect(session.tryPlaceFromHand(drawn!, 0, 0), isTrue);
      expect(
        session.tryMoveBoardTile(fromRow: 0, fromCol: 0, toRow: 1, toCol: 1),
        isNull,
      );

      final runtime = ActiveRunRuntimeState(
        activeScene: ActiveRunScene.shop,
        difficulty: NewRunDifficulty.standard,
        session: session,
        runProgress: runProgress,
        stageStartSnapshot: ActiveRunSaveService.captureStageStartSnapshot(
          session: session,
          runProgress: runProgress,
        ),
      );

      await ActiveRunSaveService.saveRuntimeState(runtime);

      final restored = await ActiveRunSaveService.loadActiveRun();
      expect(restored, isNotNull);
      expect(restored!.activeScene, ActiveRunScene.shop);
      expect(restored.difficulty, NewRunDifficulty.standard);
      expect(restored.session.runSeed, 5151);
      expect(restored.runProgress.gold, RummiEconomyConfig.startingGold + 9);
      expect(restored.session.board.cellAt(0, 0), isNull);
      expect(restored.session.board.cellAt(1, 1), isNotNull);
      expect(restored.session.boardMoveHistory.single.toRow, 1);
      expect(restored.session.undoLastBoardMove(), isNull);
      expect(restored.session.board.cellAt(0, 0), isNotNull);
      expect(
        restored.stageStartSnapshot.session.boardMoveHistory.single.toRow,
        1,
      );
    });
  });
}
