import 'bot_policy.dart';

const int kLlmActionSchemaVersion = 1;

class LlmLegalAction {
  const LlmLegalAction({
    required this.id,
    required this.type,
    required this.action,
    this.handIndex,
    this.row,
    this.col,
    this.toRow,
    this.toCol,
    this.previewScore,
    this.potentialScore,
    this.boardPressure,
    this.clearsTarget,
    this.reasonHint,
    this.policyRank,
    this.policyScore,
  });

  final String id;
  final String type;
  final BalanceSimAction action;
  final int? handIndex;
  final int? row;
  final int? col;
  final int? toRow;
  final int? toCol;
  final int? previewScore;
  final int? potentialScore;
  final int? boardPressure;
  final bool? clearsTarget;
  final String? reasonHint;
  final int? policyRank;
  final int? policyScore;

  LlmLegalAction withPolicyHint({
    required int policyRank,
    required int policyScore,
  }) {
    return LlmLegalAction(
      id: id,
      type: type,
      action: action,
      handIndex: handIndex,
      row: row,
      col: col,
      toRow: toRow,
      toCol: toCol,
      previewScore: previewScore,
      potentialScore: potentialScore,
      boardPressure: boardPressure,
      clearsTarget: clearsTarget,
      reasonHint: reasonHint,
      policyRank: policyRank,
      policyScore: policyScore,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    if (handIndex != null) 'hand_index': handIndex,
    if (row != null) 'row': row,
    if (col != null) 'col': col,
    if (toRow != null) 'to_row': toRow,
    if (toCol != null) 'to_col': toCol,
    if (previewScore != null) 'preview_score': previewScore,
    if (potentialScore != null) 'potential_score': potentialScore,
    if (boardPressure != null) 'board_pressure': boardPressure,
    if (clearsTarget != null) 'clears_target': clearsTarget,
    if (reasonHint != null) 'reason_hint': reasonHint,
    if (policyRank != null) 'policy_rank': policyRank,
    if (policyScore != null) 'policy_score': policyScore,
  };
}

class LlmActionRequest {
  const LlmActionRequest({
    required this.requestId,
    required this.botPolicy,
    required this.state,
    required this.legalActions,
  });

  final String requestId;
  final String botPolicy;
  final Map<String, dynamic> state;
  final List<LlmLegalAction> legalActions;

  Map<String, dynamic> toJson() => {
    'schema_version': kLlmActionSchemaVersion,
    'request_id': requestId,
    'bot_policy': botPolicy,
    'state': state,
    'legal_actions': [for (final action in legalActions) action.toJson()],
  };
}

class LlmActionResponse {
  const LlmActionResponse({
    required this.schemaVersion,
    required this.status,
    this.selectedActionId,
    this.confidence,
    this.reason,
    this.errorCode,
    this.message,
  });

  factory LlmActionResponse.fromJson(Map<String, dynamic> json) {
    final confidence = json['confidence'];
    return LlmActionResponse(
      schemaVersion:
          (json['schema_version'] as num?)?.toInt() ?? kLlmActionSchemaVersion,
      status: json['status'] as String? ?? 'ok',
      selectedActionId: json['selected_action_id'] as String?,
      confidence: confidence is num ? confidence.toDouble() : null,
      reason: json['reason'] as String?,
      errorCode: json['error_code'] as String?,
      message: json['message'] as String?,
    );
  }

  final int schemaVersion;
  final String status;
  final String? selectedActionId;
  final double? confidence;
  final String? reason;
  final String? errorCode;
  final String? message;
}

class LlmActionValidationResult {
  const LlmActionValidationResult._({
    required this.isValid,
    this.selectedAction,
    this.invalidReason,
    this.responseReason,
    this.confidence,
  });

  factory LlmActionValidationResult.valid({
    required LlmLegalAction selectedAction,
    String? responseReason,
    double? confidence,
  }) {
    return LlmActionValidationResult._(
      isValid: true,
      selectedAction: selectedAction,
      responseReason: responseReason,
      confidence: confidence,
    );
  }

  factory LlmActionValidationResult.invalid(String reason) {
    return LlmActionValidationResult._(isValid: false, invalidReason: reason);
  }

  final bool isValid;
  final LlmLegalAction? selectedAction;
  final String? invalidReason;
  final String? responseReason;
  final double? confidence;

  BalanceSimAction? get balanceAction => selectedAction?.action;

  Map<String, dynamic> toDecisionLogJson({
    required String requestId,
    required String botPolicy,
    required String model,
    required int latencyMs,
    required bool usedFallback,
    String? fallbackPolicy,
  }) {
    return {
      'schema_version': kLlmActionSchemaVersion,
      'request_id': requestId,
      'bot_policy': botPolicy,
      'model': model,
      'selected_action_id': selectedAction?.id,
      'selected_action_type': selectedAction?.type,
      'is_valid': isValid,
      'invalid_reason': invalidReason,
      'used_fallback': usedFallback,
      'fallback_policy': fallbackPolicy,
      'confidence': confidence,
      'reason': responseReason,
      'latency_ms': latencyMs,
    };
  }
}

LlmActionValidationResult validateLlmActionResponse({
  required LlmActionResponse response,
  required List<LlmLegalAction> legalActions,
}) {
  if (response.schemaVersion != kLlmActionSchemaVersion) {
    return LlmActionValidationResult.invalid('unsupported_schema_version');
  }
  if (response.status != 'ok') {
    return LlmActionValidationResult.invalid(
      response.errorCode ?? 'response_status_not_ok',
    );
  }
  final selectedId = response.selectedActionId;
  if (selectedId == null || selectedId.isEmpty) {
    return LlmActionValidationResult.invalid('missing_selected_action_id');
  }
  for (final action in legalActions) {
    if (action.id == selectedId) {
      return LlmActionValidationResult.valid(
        selectedAction: action,
        responseReason: response.reason,
        confidence: response.confidence,
      );
    }
  }
  return LlmActionValidationResult.invalid('unknown_action_id');
}
