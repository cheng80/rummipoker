import '../../../../tools/sim/llm_action_schema.dart';
import '../../../../tools/sim/bot_policy.dart';

const int kDefaultGuidedLegalActionLimit = 24;

LlmActionRequest applyFullRunPolicyGuidance(
  LlmActionRequest request, {
  int maxActions = kDefaultGuidedLegalActionLimit,
  BalanceSimAction? defaultRecommendation,
}) {
  final recommendedAction = defaultRecommendation == null
      ? null
      : _findMatchingAction(request.legalActions, defaultRecommendation);
  final scored = [
    for (final action in request.legalActions)
      _GuidedAction(
        action: action,
        score:
            _policyScore(action) +
            (action.id == recommendedAction?.id ? 1000000 : 0),
      ),
  ]..sort((a, b) => b.score.compareTo(a.score));

  final preferred = scored
      .where((entry) => !_isLowValueResourceSpend(entry.action))
      .map((entry) => entry.action)
      .take(maxActions)
      .toList(growable: false);
  final selected = preferred.isNotEmpty
      ? preferred
      : scored
            .map((entry) => entry.action)
            .take(maxActions)
            .toList(growable: false);
  final ranked = [
    for (var index = 0; index < selected.length; index++)
      selected[index].withPolicyHint(
        policyRank: index + 1,
        policyScore: _policyScore(selected[index]),
      ),
  ];

  return LlmActionRequest(
    requestId: request.requestId,
    botPolicy: request.botPolicy,
    state: {
      ...request.state,
      'policy_guidance': const {
        'contract_id': 'contest_full_run_guidance_v1',
        'candidate_policy':
            'Legal actions are pre-ranked and filtered with full-run bot rules.',
        'rules': [
          'If default_recommended_action_id is present and no action clearly clears the target, choose that action.',
          'Actions include policy_rank and policy_score; lower policy_rank is the default recommendation.',
          'Prefer actions that clear the target immediately.',
          'Do not spend board discard, hand discard, or board move only for evidence.',
          'Use discard or move only when it improves survival, scoring, or board lock recovery.',
          'Do not confirm tiny score if a near-term placement can build stronger duplicate/scoring lines.',
          'Draw when hand space is available and the current board has no useful confirm or placement.',
          'Preserve scarce resources unless the board is close to locked or target progress is blocked.',
        ],
      },
      if (recommendedAction != null)
        'default_recommended_action_id': recommendedAction.id,
      if (recommendedAction != null)
        'default_recommended_action_type': recommendedAction.type,
      if (recommendedAction != null)
        'default_recommendation_source': 'full_run_policy_v1',
      'candidate_count_before_guidance': request.legalActions.length,
      'candidate_count_after_guidance': ranked.length,
    },
    legalActions: ranked,
  );
}

LlmLegalAction? _findMatchingAction(
  List<LlmLegalAction> actions,
  BalanceSimAction recommendation,
) {
  for (final action in actions) {
    final candidate = action.action;
    if (candidate.type == recommendation.type &&
        candidate.handIndex == recommendation.handIndex &&
        candidate.row == recommendation.row &&
        candidate.col == recommendation.col &&
        candidate.toRow == recommendation.toRow &&
        candidate.toCol == recommendation.toCol) {
      return action;
    }
  }
  return null;
}

bool _isLowValueResourceSpend(LlmLegalAction action) {
  if (action.clearsTarget == true) return false;
  final preview = action.previewScore ?? action.potentialScore ?? 0;
  final pressure = action.boardPressure ?? 0;
  switch (action.type) {
    case 'discardHand':
    case 'discardBoard':
      return preview <= 0 && pressure < 22;
    case 'moveBoard':
      return preview <= 0 && pressure < 20;
    default:
      return false;
  }
}

int _policyScore(LlmLegalAction action) {
  var score = 0;
  if (action.clearsTarget == true) score += 100000;
  score += (action.previewScore ?? 0) * 20;
  score += (action.potentialScore ?? 0) * 10;
  final pressure = action.boardPressure ?? 0;
  score += pressure;
  switch (action.type) {
    case 'confirm':
      score += action.previewScore == null || action.previewScore == 0
          ? -500
          : 4000;
    case 'place':
      score += 2500;
    case 'draw':
      score += pressure >= 20 ? -1200 : 1200;
    case 'discardBoard':
      score += pressure >= 22 ? 800 : -2500;
    case 'discardHand':
      score += pressure >= 22 ? 300 : -2200;
    case 'moveBoard':
      score += pressure >= 20 ? 400 : -1800;
    case 'stop':
      score -= 10000;
  }
  return score;
}

class _GuidedAction {
  const _GuidedAction({required this.action, required this.score});

  final LlmLegalAction action;
  final int score;
}
