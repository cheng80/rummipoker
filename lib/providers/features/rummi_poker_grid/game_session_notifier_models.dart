part of 'game_session_notifier.dart';

class GameSessionArgs {
  const GameSessionArgs({
    required this.runSeed,
    this.restoredRun,
    this.debugFixtureId,
    this.ruleset = RummiRuleset.currentDefaults,
    this.difficulty = NewRunDifficulty.standard,
    this.runModifier = NewRunModifier.basic,
    this.blindTier = BlindTier.small,
    this.challengeCarryover,
  });

  final int runSeed;
  final ActiveRunRuntimeState? restoredRun;
  final String? debugFixtureId;
  final RummiRuleset ruleset;
  final NewRunDifficulty difficulty;
  final NewRunModifier runModifier;
  final BlindTier blindTier;
  final ChallengeCarryoverSnapshot? challengeCarryover;

  @override
  bool operator ==(Object other) =>
      other is GameSessionArgs &&
      other.runSeed == runSeed &&
      identical(other.restoredRun, restoredRun) &&
      other.debugFixtureId == debugFixtureId &&
      other.ruleset == ruleset &&
      other.difficulty == difficulty &&
      other.runModifier == runModifier &&
      other.blindTier == blindTier &&
      other.challengeCarryover == challengeCarryover;

  @override
  int get hashCode => Object.hash(
    runSeed,
    restoredRun,
    debugFixtureId,
    ruleset,
    difficulty,
    runModifier,
    blindTier,
    challengeCarryover,
  );
}

/// [GameSessionNotifier.confirmLines] 결과.
class ConfirmLinesResult {
  const ConfirmLinesResult({
    required this.totalScore,
    required this.lineBreakdowns,
    required this.stageCleared,
  });

  final int totalScore;
  final List<ConfirmedLineBreakdown> lineBreakdowns;
  final bool stageCleared;
}

class ExpiryGuardResult {
  const ExpiryGuardResult({required this.signals, required this.events});

  final List<RummiExpirySignal> signals;
  final List<ItemEffectEvent> events;

  String get message {
    final hasBoardRescue = events.any(
      (event) => event.kind == ItemEffectEventKind.boardDiscardAdded,
    );
    final hasDrawRescue = events.any(
      (event) => event.kind == ItemEffectEventKind.tileDrawn,
    );
    if (hasBoardRescue && hasDrawRescue) {
      return '안전망이 보드 버림과 구조 드로우를 확보했습니다.';
    }
    if (hasBoardRescue) {
      return '안전망이 보드 버림 1회를 확보했습니다.';
    }
    return '안전망이 제거 더미를 섞어 타일 1장을 구조했습니다.';
  }

  String get feedbackDetail {
    final hasBoardRescue = events.any(
      (event) => event.kind == ItemEffectEventKind.boardDiscardAdded,
    );
    final hasDrawRescue = events.any(
      (event) => event.kind == ItemEffectEventKind.tileDrawn,
    );
    if (hasBoardRescue && hasDrawRescue) {
      return '보드 버림 +1 · 구조 드로우 +1';
    }
    if (hasBoardRescue) {
      return '보드 버림 +1';
    }
    return '구조 드로우 +1';
  }
}

class BattleBoardTapResult {
  const BattleBoardTapResult._({
    required this.didPlaceTile,
    required this.didChangeSelection,
    this.failMessage,
  });

  const BattleBoardTapResult.placed()
    : this._(didPlaceTile: true, didChangeSelection: false);

  const BattleBoardTapResult.selectionChanged()
    : this._(didPlaceTile: false, didChangeSelection: true);

  const BattleBoardTapResult.ignored()
    : this._(didPlaceTile: false, didChangeSelection: false);

  const BattleBoardTapResult.fail(String message)
    : this._(
        didPlaceTile: false,
        didChangeSelection: false,
        failMessage: message,
      );

  final bool didPlaceTile;
  final bool didChangeSelection;
  final String? failMessage;
}
