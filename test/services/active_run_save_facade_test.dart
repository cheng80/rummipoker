import 'package:flutter_test/flutter_test.dart';

import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_blind_state.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/services/active_run_save_facade.dart';
import 'package:rummipoker/services/active_run_save_service.dart';

void main() {
  group('RummiActiveRunSaveFacade', () {
    test('maps current save dto into station/checkpoint aliases', () {
      const save = ActiveRunSaveData(
        schemaVersion: 2,
        savedAtIso8601: '2026-04-19T00:00:00.000Z',
        activeScene: 'shop',
        session: SavedSessionData(
          runSeed: 41,
          deckCopiesPerTile: 1,
          maxHandSize: 1,
          runRandomState: 77,
          blind: <String, dynamic>{
            'targetScore': 300,
            'boardDiscardsRemaining': 4,
            'boardDiscardsMax': 4,
            'handDiscardsRemaining': 2,
            'handDiscardsMax': 2,
            'scoreTowardBlind': 120,
          },
          deckPile: <Map<String, dynamic>>[],
          boardCells: <Map<String, dynamic>?>[],
          hand: <Map<String, dynamic>>[],
          eliminated: <Map<String, dynamic>>[],
        ),
        runProgress: SavedRunProgressData(
          stageIndex: 4,
          gold: 33,
          rerollCost: 7,
          ownedJesterIds: <String>['egg'],
          shopOffers: <SavedShopOfferData>[
            SavedShopOfferData(slotIndex: 0, cardId: 'popcorn', price: 9),
          ],
          statefulValuesBySlot: <String, int>{'0': 1},
          playedHandCounts: <String, int>{'straight': 2},
        ),
        stageStartSession: SavedSessionData(
          runSeed: 41,
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
        stageStartRunProgress: SavedRunProgressData(
          stageIndex: 4,
          gold: 10,
          rerollCost: 5,
          ownedJesterIds: <String>[],
          shopOffers: <SavedShopOfferData>[],
          statefulValuesBySlot: <String, int>{},
          playedHandCounts: <String, int>{},
        ),
      );

      final facade = RummiActiveRunSaveFacade.fromSaveData(save);

      expect(facade.schemaVersion, 2);
      expect(facade.activeScene, 'shop');
      expect(facade.sceneAlias, RummiSaveSceneAlias.market);
      expect(facade.currentStageIndex, 4);
      expect(facade.currentStationIndex, 4);
      expect(facade.currentRunSeed, 41);
      expect(facade.currentGold, 33);
      expect(facade.checkpoint.stageIndex, 4);
      expect(facade.checkpoint.stationIndex, 4);
      expect(facade.checkpoint.runSeed, 41);
      expect(facade.checkpoint.gold, 10);
    });

    test('maps runtime state into the same station/checkpoint aliases', () {
      final session = RummiPokerGridSession(
        runSeed: 99,
        blind: RummiBlindState(targetScore: 500, scoreTowardBlind: 140),
      );
      final runProgress = RummiRunProgress()
        ..stageIndex = 3
        ..gold = 27;
      final checkpointSession = session.copySnapshot();
      final checkpointProgress = runProgress.copySnapshot()..gold = 10;
      final runtime = ActiveRunRuntimeState(
        activeScene: ActiveRunScene.battle,
        session: session,
        runProgress: runProgress,
        stageStartSnapshot: ActiveRunStageSnapshot(
          session: checkpointSession,
          runProgress: checkpointProgress,
        ),
      );

      final facade = RummiActiveRunSaveFacade.fromRuntimeState(runtime);

      expect(facade.schemaVersion, ActiveRunSaveService.schemaVersion);
      expect(facade.sceneAlias, RummiSaveSceneAlias.battle);
      expect(facade.currentStageIndex, 3);
      expect(facade.currentStationIndex, 3);
      expect(facade.currentRunSeed, 99);
      expect(facade.currentGold, 27);
      expect(facade.checkpoint.stageIndex, 3);
      expect(facade.checkpoint.stationIndex, 3);
      expect(facade.checkpoint.gold, 10);
    });

    test('provides centralized summary labels for continue/home UI', () {
      final session = RummiPokerGridSession(
        runSeed: 99,
        blind: RummiBlindState(targetScore: 500, scoreTowardBlind: 140),
      );
      final runProgress = RummiRunProgress()
        ..stageIndex = 3
        ..gold = 27;
      final runtime = ActiveRunRuntimeState(
        activeScene: ActiveRunScene.shop,
        session: session,
        runProgress: runProgress,
        stageStartSnapshot: ActiveRunStageSnapshot(
          session: session.copySnapshot(),
          runProgress: runProgress.copySnapshot()..gold = 10,
        ),
      );

      final facade = RummiActiveRunSaveFacade.fromRuntimeState(runtime);

      expect(rummiSaveSceneLabel(facade.sceneAlias), 'Market');
      expect(
        facade.currentLocationSummary,
        '현재 Station 3 · Market · Gold 27',
      );
      expect(facade.checkpointSummary, '체크포인트 Station 3');
      expect(
        facade.snapshotSummaryLabel(),
        '현재 Station 3 · Market · Gold 27\n체크포인트 Station 3',
      );
      expect(
        facade.continueDialogMessage(),
        '저장된 현재 런을 복원합니다.\n'
        '현재 Station 3 · Market · Gold 27\n'
        '체크포인트 Station 3\n'
        '삭제하거나 그대로 이어할지 선택하세요.',
      );
    });
  });
}
