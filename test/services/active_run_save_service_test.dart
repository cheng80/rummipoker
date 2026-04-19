import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/services/active_run_save_facade.dart';
import 'package:rummipoker/services/active_run_save_service.dart';

void main() {
  group('ActiveRunSaveService', () {
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
          session: const SavedSessionData(
            runSeed: 11,
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
          ),
          runProgress: const SavedRunProgressData(
            stageIndex: 3,
            gold: 42,
            rerollCost: 6,
            ownedJesterIds: <String>['jester'],
            shopOffers: <SavedShopOfferData>[
              SavedShopOfferData(slotIndex: 0, cardId: 'jester', price: 3),
            ],
            statefulValuesBySlot: <String, int>{'0': 2},
            playedHandCounts: <String, int>{'straight': 1},
          ),
          stageStartSession: const SavedSessionData(
            runSeed: 11,
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

        final encoded = jsonEncode(save.toJson());
        final restored = ActiveRunSaveData.fromJson(
          jsonDecode(encoded) as Map<String, dynamic>,
        );

        expect(restored.schemaVersion, 2);
        expect(restored.activeScene, ActiveRunScene.shop.name);
        expect(restored.session.runSeed, 11);
        expect(restored.runProgress.gold, 42);
        expect(restored.stageStartSession.runRandomState, 55);
        expect(restored.stageStartRunProgress.gold, 10);
        expect(restored.stageStartRunProgress.rerollCost, 5);
      },
    );

    test('save facade summary maps dto scene and checkpoint aliases', () {
      final save = ActiveRunSaveData(
        schemaVersion: 2,
        savedAtIso8601: '2026-04-19T00:00:00.000Z',
        activeScene: ActiveRunScene.shop.name,
        session: const SavedSessionData(
          runSeed: 11,
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
  });
}
