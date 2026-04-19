import 'rummi_blind_state.dart';
import 'rummi_poker_grid_session.dart';

/// Documentation/target-term facade over the current stage/blind runtime.
///
/// Important:
/// - This is a read-only compatibility layer.
/// - It does not rename or replace current runtime symbols.
/// - It lets future Station-oriented code and docs read current values without
///   forcing an early `Blind -> Station` refactor.
enum RummiStationType {
  currentStage,
  entry,
  pressure,
  lock,
}

class RummiStationObjectiveView {
  const RummiStationObjectiveView({
    required this.targetScore,
    required this.scoreTowardObjective,
  });

  factory RummiStationObjectiveView.fromBlind(RummiBlindState blind) {
    return RummiStationObjectiveView(
      targetScore: blind.targetScore,
      scoreTowardObjective: blind.scoreTowardBlind,
    );
  }

  final int targetScore;
  final int scoreTowardObjective;

  bool get isMet => scoreTowardObjective >= targetScore;
}

class RummiStationResourceView {
  const RummiStationResourceView({
    required this.boardDiscardsRemaining,
    required this.boardDiscardsMax,
    required this.handDiscardsRemaining,
    required this.handDiscardsMax,
    required this.maxHandSize,
    required this.drawPileRemaining,
  });

  factory RummiStationResourceView.fromSession(
    RummiPokerGridSession session,
  ) {
    return RummiStationResourceView(
      boardDiscardsRemaining: session.blind.boardDiscardsRemaining,
      boardDiscardsMax: session.blind.boardDiscardsMax,
      handDiscardsRemaining: session.blind.handDiscardsRemaining,
      handDiscardsMax: session.blind.handDiscardsMax,
      maxHandSize: session.maxHandSize,
      drawPileRemaining: session.deck.remaining,
    );
  }

  final int boardDiscardsRemaining;
  final int boardDiscardsMax;
  final int handDiscardsRemaining;
  final int handDiscardsMax;
  final int maxHandSize;
  final int drawPileRemaining;
}

class RummiStationRuntimeFacade {
  const RummiStationRuntimeFacade({
    required this.stationType,
    required this.objective,
    required this.resources,
  });

  final RummiStationType stationType;
  final RummiStationObjectiveView objective;
  final RummiStationResourceView resources;

  factory RummiStationRuntimeFacade.fromSession(
    RummiPokerGridSession session, {
    RummiStationType stationType = RummiStationType.currentStage,
  }) {
    return RummiStationRuntimeFacade(
      stationType: stationType,
      objective: RummiStationObjectiveView.fromBlind(session.blind),
      resources: RummiStationResourceView.fromSession(session),
    );
  }
}
