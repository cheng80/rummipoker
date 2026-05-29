part of '../game_view.dart';

class _BoardScoringCallout extends StatelessWidget {
  const _BoardScoringCallout({
    super.key,
    required this.line,
    required this.step,
  });

  final ConfirmedLineBreakdown line;
  final ScoringPresentationStep step;

  @override
  Widget build(BuildContext context) {
    final isConstraint = step == ScoringPresentationStep.constraint;
    final (title, value, detail) = switch (step) {
      ScoringPresentationStep.boardLine => (
        '${gameLineRefShortLabel(line.ref)} 라인',
        '확정',
        '하이라이트된 타일이 점수 라인입니다',
      ),
      ScoringPresentationStep.handRank => (
        gameHandRankLabel(line.rank),
        '칩 +${line.rankBaseScore ?? line.baseScore}',
        '족보 기본 칩',
      ),
      ScoringPresentationStep.overlap => (
        'overlap',
        '+${line.overlapBonus}',
        '겹친 타일 보너스',
      ),
      ScoringPresentationStep.constraint => (
        line.constraintPenalties.first.title,
        line.constraintPenalties.first.markerText,
        line.constraintPenalties.first.ruleText,
      ),
      _ => ('점수', '+0', ''),
    };
    final valueColor = step == ScoringPresentationStep.constraint
        ? GameUiPalette.specialDangerBright
        : GameUiPalette.actionGoldBright;
    final accentColor = isConstraint
        ? GameUiPalette.specialDangerEffectBorder
        : GameUiPalette.actionGoldBright;
    return IgnorePointer(
      child:
          Align(
                alignment: Alignment.topCenter,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: GameUiPalette.settlementEffectSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.78),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.16),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: GameUiPalette.ink.withValues(alpha: 0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: isConstraint
                        ? ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 290),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        title,
                                        softWrap: true,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: GameUiPalette.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          height: 1.15,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      value,
                                      style: TextStyle(
                                        color: valueColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        height: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  detail,
                                  softWrap: true,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: GameUiPalette.textPrimary.withValues(
                                      alpha: 0.72,
                                    ),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                style: const TextStyle(
                                  color: GameUiPalette.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                value,
                                maxLines: 1,
                                style: TextStyle(
                                  color: valueColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  detail,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: GameUiPalette.textPrimary.withValues(
                                      alpha: 0.68,
                                    ),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              )
              .animate()
              .fadeIn(
                duration: GamePresentationTimings.boardScoringCalloutIn,
                curve: Curves.easeOutCubic,
              )
              .slideY(
                begin: 0.12,
                end: 0,
                duration: GamePresentationTimings.boardScoringCalloutIn,
                curve: Curves.easeOutCubic,
              ),
    );
  }
}

class _BattleActionBar extends StatelessWidget {
  const _BattleActionBar({
    required this.scoringPreview,
    required this.canStartBoardMove,
    required this.onConfirm,
    required this.onClearSelection,
    required this.onStartBoardMove,
    required this.onBoardDiscard,
    required this.onHandDiscard,
    required this.confirmEnabled,
    required this.utilityEnabled,
    required this.onRunInfo,
  });

  final RummiScoringPreview? scoringPreview;
  final bool canStartBoardMove;
  final VoidCallback onConfirm;
  final VoidCallback onClearSelection;
  final VoidCallback onStartBoardMove;
  final VoidCallback onBoardDiscard;
  final VoidCallback onHandDiscard;
  final bool confirmEnabled;
  final bool utilityEnabled;
  final VoidCallback onRunInfo;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        const confirmGap = 18.0;
        const buttonSide = 42.0;
        final confirmReady = scoringPreview != null;

        return SizedBox(
          height: buttonSide,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _BattleRailButton(
                tooltip: '런 정보',
                label: '런\n정보',
                size: buttonSide,
                borderRadius: 7,
                backgroundColor: GameUiPalette.battleActionHand,
                onPressed: onRunInfo,
              ),
              const SizedBox(width: 16),
              _BattleRailButton(
                tooltip: '선택 해제',
                label: '선택\n해제',
                size: buttonSide,
                borderRadius: 7,
                backgroundColor: GameUiPalette.passiveSlotAccent,
                onPressed: utilityEnabled ? onClearSelection : null,
              ),
              const SizedBox(width: gap),
              _BattleRailButton(
                tooltip: '이동',
                label: '타일\n이동',
                size: buttonSide,
                borderRadius: 7,
                backgroundColor: GameUiPalette.battleActionTool,
                onPressed: canStartBoardMove ? onStartBoardMove : null,
              ),
              const SizedBox(width: gap),
              _BattleRailButton(
                tooltip: '보드 버림',
                label: '보드\n버림',
                size: buttonSide,
                borderRadius: 7,
                backgroundColor: GameUiPalette.battleActionPassive,
                onPressed: utilityEnabled ? onBoardDiscard : null,
              ),
              const SizedBox(width: gap),
              _BattleRailButton(
                tooltip: '손패 버림',
                label: '손패\n버림',
                size: buttonSide,
                borderRadius: 7,
                backgroundColor: GameUiPalette.battleActionDeck,
                onPressed: utilityEnabled ? onHandDiscard : null,
              ),
              const SizedBox(width: confirmGap),
              _BattleRailButton(
                tooltip: '확정',
                label: '확정\n하기',
                size: buttonSide,
                borderRadius: 7,
                backgroundColor: confirmReady
                    ? GameUiPalette.actionGold
                    : GameUiPalette.actionDisabledMuted,
                foregroundColor: confirmReady
                    ? GameUiPalette.ink
                    : GameUiPalette.textPrimary.withValues(alpha: 0.54),
                onPressed: confirmEnabled ? onConfirm : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScoringPreviewChip extends StatelessWidget {
  const _ScoringPreviewChip({
    required this.preview,
    required this.pendingConfirmItemCount,
  });

  final RummiScoringPreview? preview;
  final int pendingConfirmItemCount;

  @override
  Widget build(BuildContext context) {
    final preview = this.preview;
    final hasConstraint = preview?.hasConstraintPenalty ?? false;
    final accent = preview == null
        ? GameUiPalette.textPrimary.withValues(alpha: 0.34)
        : GameUiPalette.actionGold;
    final rankLabel = preview == null
        ? ''
        : gameHandRankLabel(preview.representativeRank);
    final label = preview == null
        ? '확정 가능 줄 없음'
        : preview.lineCount == 1
        ? '1줄 확정 · $rankLabel · 예상 +${preview.expectedScore}'
        : '${preview.lineCount}줄 확정 · 최고 $rankLabel · 예상 +${preview.expectedScore}';
    final detail = _previewDetail(
      preview,
      hasConstraint: hasConstraint,
      pendingConfirmItemCount: pendingConfirmItemCount,
    );
    final hasPendingItem = pendingConfirmItemCount > 0;
    final pulseKey = ValueKey(
      preview == null
          ? 'score-preview-empty-$pendingConfirmItemCount'
          : 'score-preview-${preview.expectedScore}-${preview.lineCount}-$pendingConfirmItemCount',
    );
    return SizedBox(
      height: 28,
      child:
          DecoratedBox(
                key: hasPendingItem
                    ? const ValueKey('scoring-preview-item-link-flash')
                    : null,
                decoration: BoxDecoration(
                  color: GameUiPalette.ink.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasPendingItem
                        ? GameUiPalette.specialScoreText.withValues(alpha: 0.78)
                        : accent.withValues(alpha: 0.42),
                    width: hasPendingItem ? 1.4 : 1,
                  ),
                  boxShadow: hasPendingItem
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFFFFD36B,
                            ).withValues(alpha: 0.18),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        preview == null
                            ? Icons.info_outline_rounded
                            : Icons.auto_awesome_rounded,
                        color: accent,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          style: TextStyle(
                            color: preview == null
                                ? GameUiPalette.textPrimary.withValues(
                                    alpha: 0.54,
                                  )
                                : GameUiPalette.textPrimary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: hasConstraint ? 58 : 92,
                        ),
                        child: Text(
                          detail,
                          maxLines: 1,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate(key: pulseKey)
              .fadeIn(
                duration: GamePresentationTimings.scoringPreviewFadeIn,
                curve: Curves.easeOutCubic,
              )
              .scale(
                begin: const Offset(0.985, 0.985),
                end: const Offset(1, 1),
                duration: GamePresentationTimings.scoringPreviewScale,
                curve: Curves.easeOutCubic,
              ),
    );
  }
}

String _previewDetail(
  RummiScoringPreview? preview, {
  required bool hasConstraint,
  required int pendingConfirmItemCount,
}) {
  if (preview == null) {
    return pendingConfirmItemCount > 0
        ? '아이템 대기 $pendingConfirmItemCount'
        : '빌드 효과 표시';
  }
  if (hasConstraint) {
    return '약화 -${preview.constraintPenaltyPercent}%';
  }
  if (pendingConfirmItemCount > 0) {
    final applied = preview.expectedItemEffectCount;
    return applied > 0
        ? '아이템 적용 $applied/$pendingConfirmItemCount'
        : '아이템 조건 미충족 0/$pendingConfirmItemCount';
  }
  if (preview.expectedTileModifierEffectCount > 0) {
    return '타일 효과 ${preview.expectedTileModifierEffectCount}';
  }
  return '칩 ${preview.baseScore}'
      '${preview.overlapBonus > 0 ? ' · overlap +${preview.overlapBonus}' : ''}'
      ' · J${preview.expectedJesterEffectCount}/I${preview.expectedItemEffectCount}';
}

class _BattleRailButton extends StatelessWidget {
  const _BattleRailButton({
    required this.tooltip,
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
    this.foregroundColor = GameUiPalette.textPrimary,
    this.size = 58,
    this.borderRadius = 9,
  });

  final String tooltip;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final baseColor = isEnabled
        ? backgroundColor
        : backgroundColor.withValues(alpha: 0.34);
    final textColor = isEnabled
        ? foregroundColor
        : foregroundColor.withValues(alpha: 0.58);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: GameUiPalette.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: isEnabled
                    ? foregroundColor.withValues(alpha: 0.28)
                    : foregroundColor.withValues(alpha: 0.12),
                width: 1.4,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.0,
                      fontWeight: FontWeight.w400,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
