import 'package:flutter_test/flutter_test.dart';

import 'package:rummipoker/logic/rummi_poker_grid/rummi_blind_state.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_station_facade.dart';

void main() {
  group('RummiStationRuntimeFacade', () {
    test(
      'maps current blind target and score into station objective aliases',
      () {
        final session = RummiPokerGridSession(
          runSeed: 55,
          blind: RummiBlindState(
            targetScore: 480,
            boardDiscardsRemaining: 3,
            handDiscardsRemaining: 1,
            scoreTowardBlind: 125,
          ),
        );

        final facade = RummiStationRuntimeFacade.fromSession(session);

        expect(facade.stationType, RummiStationType.currentStage);
        expect(facade.objective.targetScore, 480);
        expect(facade.objective.scoreTowardObjective, 125);
        expect(facade.objective.isMet, isFalse);
      },
    );

    test(
      'maps current discard, hand size, and draw pile values into resources',
      () {
        final session = RummiPokerGridSession(
          runSeed: 99,
          blind: RummiBlindState(
            targetScore: 300,
            boardDiscardsRemaining: 2,
            boardDiscardsMax: 4,
            handDiscardsRemaining: 1,
            handDiscardsMax: 2,
            boardMovesRemaining: 2,
            boardMovesMax: 3,
          ),
        );
        session.setDebugMaxHandSize(3);

        final facade = RummiStationRuntimeFacade.fromSession(
          session,
          stationType: RummiStationType.entry,
        );

        expect(facade.stationType, RummiStationType.entry);
        expect(facade.resources.boardDiscardsRemaining, 2);
        expect(facade.resources.boardDiscardsMax, 4);
        expect(facade.resources.handDiscardsRemaining, 1);
        expect(facade.resources.handDiscardsMax, 2);
        expect(facade.resources.boardMovesRemaining, 2);
        expect(facade.resources.boardMovesMax, 3);
        expect(facade.resources.maxHandSize, 3);
        expect(facade.resources.drawPileRemaining, session.deck.remaining);
      },
    );

    test(
      'facade is read-only and reflects later snapshots via re-creation only',
      () {
        final session = RummiPokerGridSession(runSeed: 7);
        final before = RummiStationRuntimeFacade.fromSession(session);

        session.addScoreToBlind(70);

        expect(before.objective.scoreTowardObjective, 0);

        final after = RummiStationRuntimeFacade.fromSession(session);
        expect(after.objective.scoreTowardObjective, 70);
      },
    );
  });
}
