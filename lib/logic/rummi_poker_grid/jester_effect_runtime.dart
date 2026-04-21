import 'hand_rank.dart';
import 'jester_meta.dart';
import 'models/tile.dart';

enum JesterEffectEventKind { scoreApplied }

class JesterEffectEvent {
  const JesterEffectEvent({
    required this.kind,
    required this.jesterId,
    required this.slotIndex,
    required this.scoreDelta,
    this.effect,
  });

  final JesterEffectEventKind kind;
  final String jesterId;
  final int slotIndex;
  final int scoreDelta;
  final RummiJesterEffectBreakdown? effect;
}

class JesterLineEffectResult {
  const JesterLineEffectResult({
    required this.slotIndex,
    required this.jester,
    required this.score,
    required this.events,
  });

  final int slotIndex;
  final RummiJesterCard jester;
  final RummiLineScore score;
  final List<JesterEffectEvent> events;

  int get scoreDelta => score.finalScore - score.baseScore;
}

class JesterEffectRuntime {
  const JesterEffectRuntime._();

  static JesterLineEffectResult applyToLine({
    required int slotIndex,
    required RummiJesterCard jester,
    required RummiHandRank rank,
    required int baseScore,
    required List<Tile> scoringTiles,
    required RummiJesterScoreContext context,
  }) {
    final score = jester.applyToLine(
      rank: rank,
      baseScore: baseScore,
      scoringTiles: scoringTiles,
      context: context,
    );
    final event = score.effect == null
        ? null
        : JesterEffectEvent(
            kind: JesterEffectEventKind.scoreApplied,
            jesterId: jester.id,
            slotIndex: slotIndex,
            scoreDelta: score.finalScore - score.baseScore,
            effect: score.effect,
          );
    return JesterLineEffectResult(
      slotIndex: slotIndex,
      jester: jester,
      score: score,
      events: event == null ? const [] : [event],
    );
  }
}
