part of '../game_view.dart';

/// 채점 중인 줄을 가리지 않는 보드 가장자리에 callout을 놓는다.
///
/// 위·아래 두 줄 띠와 좌·우 두 칸 폭 후보 중 contributor 칸과 겹치지 않는 첫 자리를 고른다.
class _BoardScoringCalloutPlacement extends StatelessWidget {
  const _BoardScoringCalloutPlacement({
    required this.line,
    required this.child,
  });

  final ConfirmedLineBreakdown line;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slot = boardCalloutSlotFor(line.contributingCells);
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final side = math.min(width, height);
        final boardLeft = (width - side) / 2;
        final boardTop = (height - side) / 2;
        final inner = side - kBoardFrameInset * 2;
        final cell = (inner - kBoardGridGap * (kBoardSize - 1)) / kBoardSize;
        final twoCells = cell * 2 + kBoardGridGap;
        final left = boardLeft + kBoardFrameInset;
        final (slotLeft, slotWidth) = switch (slot.horizontal) {
          BoardCalloutHorizontal.full => (left, inner),
          BoardCalloutHorizontal.left => (left, twoCells),
          BoardCalloutHorizontal.right => (left + inner - twoCells, twoCells),
        };
        final edge = kBoardFrameInset + 2;
        return Stack(
          children: [
            Positioned(
              key: ValueKey('board-score-callout-slot-${slot.name}'),
              left: slotLeft,
              width: slotWidth,
              top: slot.top ? boardTop + edge : null,
              bottom: slot.top ? null : height - (boardTop + side) + edge,
              child: Align(
                alignment: slot.top
                    ? Alignment.topCenter
                    : Alignment.bottomCenter,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BoardScoringCallout extends StatelessWidget {
  const _BoardScoringCallout({
    super.key,
    required this.line,
    required this.step,
    this.grade = 0,
  });

  final ConfirmedLineBreakdown line;
  final ScoringPresentationStep step;
  final int grade;

  @override
  Widget build(BuildContext context) {
    final isConstraint = step == ScoringPresentationStep.constraint;
    final isFinal = step == ScoringPresentationStep.finalScore;
    final (title, value, detail) = switch (step) {
      ScoringPresentationStep.boardLine => (
        context.translate(
          'battleScoringLine',
          namedArgs: {
            'line': gameLineRefShortLabel(line.ref, context: context),
          },
        ),
        context.translate('battleConfirm'),
        context.translate('battleScoringTilesHint'),
      ),
      ScoringPresentationStep.handRank => (
        context.translate(rummiHandRankKey(line.rank)),
        context.translate(
          'battleChipsAdded',
          namedArgs: {'chips': '${line.rankBaseScore ?? line.baseScore}'},
        ),
        context.translate('battleBaseChips'),
      ),
      ScoringPresentationStep.overlap => (
        context.translate('coreSettlementOverlap'),
        '+${line.overlapBonus}',
        context.translate('battleOverlapBonus'),
      ),
      ScoringPresentationStep.constraint => (
        line.constraintPenalties.first.displayKeys == null
            ? line.constraintPenalties.first.title
            : context.translate(
                line.constraintPenalties.first.displayKeys!.titleKey,
              ),
        line.constraintPenalties.first.displayKeys == null
            ? line.constraintPenalties.first.markerText
            : context.translate(
                line.constraintPenalties.first.displayKeys!.markerTextKey,
              ),
        line.constraintPenalties.first.displayKeys == null
            ? line.constraintPenalties.first.ruleText
            : context.translate(
                line.constraintPenalties.first.displayKeys!.ruleTextKey,
              ),
      ),
      ScoringPresentationStep.finalScore => (
        context.translate('settlementGrade${grade.clamp(0, 3)}'),
        '+${line.finalScore}',
        '',
      ),
      _ => (context.translate('battleScore'), '+0', ''),
    };
    final valueColor = isConstraint
        ? GameUiPalette.specialDangerBright
        : GameUiPalette.actionGoldBright;
    final accentColor = isConstraint
        ? GameUiPalette.specialDangerEffectBorder
        : GameUiPalette.actionGoldBright;
    final titleSize = isFinal ? 12.0 + grade * 1.5 : 12.0;
    return IgnorePointer(
      child:
          DecoratedBox(
                key: isFinal ? ValueKey('board-score-grade-$grade') : null,
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked =
                          isConstraint || constraints.maxWidth < 240;
                      final titleText = Text(
                        title,
                        softWrap: true,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isFinal
                              ? GameUiPalette.actionGoldBright
                              : GameUiPalette.textPrimary,
                          fontSize: titleSize,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      );
                      final valueText = Text(
                        value,
                        maxLines: 1,
                        style: TextStyle(
                          color: valueColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      );
                      final detailText = SemanticText(
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
                      );
                      if (!stacked) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            titleText,
                            const SizedBox(width: 10),
                            valueText,
                            if (detail.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              Flexible(child: detailText),
                            ],
                          ],
                        );
                      }
                      return ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 290),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 2,
                              children: [titleText, valueText],
                            ),
                            if (detail.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              detailText,
                            ],
                          ],
                        ),
                      );
                    },
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
    this.goalHeat = 0,
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

  /// 이번 확정으로 목표를 넘길 때의 달아오름(0~1).
  final double goalHeat;

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
                tooltip: context.translate('runInfoTitle'),
                label: context.translate('battleRunInfoCompact'),
                size: buttonSide,
                borderRadius: 7,
                backgroundColor: GameUiPalette.battleActionHand,
                pressCue: GameCue.buttonTap,
                onPressed: onRunInfo,
              ),
              const SizedBox(width: 16),
              _BattleRailButton(
                tooltip: context.translate('battleDeselect'),
                label: context.translate('battleDeselectCompact'),
                size: buttonSide,
                borderRadius: 7,
                backgroundColor: GameUiPalette.passiveSlotAccent,
                pressCue: GameCue.tileSelect,
                onPressed: utilityEnabled ? onClearSelection : null,
              ),
              const SizedBox(width: gap),
              _BattleRailButton(
                tooltip: context.translate('battleMove'),
                label: context.translate('battleMoveCompact'),
                size: buttonSide,
                borderRadius: 7,
                backgroundColor: GameUiPalette.battleActionTool,
                pressCue: GameCue.buttonTap,
                onPressed: canStartBoardMove ? onStartBoardMove : null,
              ),
              const SizedBox(width: gap),
              _BattleRailButton(
                tooltip: context.translate('battleDiscardBoard'),
                label: context.translate('battleDiscardBoardCompact'),
                size: buttonSide,
                borderRadius: 7,
                backgroundColor: GameUiPalette.battleActionPassive,
                onPressed: utilityEnabled ? onBoardDiscard : null,
              ),
              const SizedBox(width: gap),
              _BattleRailButton(
                tooltip: context.translate('battleDiscardHand'),
                label: context.translate('battleDiscardHandCompact'),
                size: buttonSide,
                borderRadius: 7,
                backgroundColor: GameUiPalette.battleActionDeck,
                onPressed: utilityEnabled ? onHandDiscard : null,
              ),
              const SizedBox(width: confirmGap),
              _BattleRailButton(
                tooltip: context.translate('battleConfirm'),
                label: context.translate('battleConfirmCompact'),
                size: buttonSide,
                borderRadius: 7,
                backgroundColor: confirmReady
                    ? GameUiPalette.actionGold
                    : GameUiPalette.actionDisabledMuted,
                foregroundColor: confirmReady
                    ? GameUiPalette.ink
                    : GameUiPalette.textPrimary.withValues(alpha: 0.54),
                armed: confirmReady && confirmEnabled,
                heat: goalHeat,
                onPressed: confirmEnabled ? onConfirm : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScoringPreviewChip extends StatefulWidget {
  const _ScoringPreviewChip({
    required this.preview,
    required this.pendingConfirmItemCount,
  });

  final RummiScoringPreview? preview;
  final int pendingConfirmItemCount;

  @override
  State<_ScoringPreviewChip> createState() => _ScoringPreviewChipState();
}

class _ScoringPreviewChipState extends State<_ScoringPreviewChip> {
  /// 예상 점수가 바뀌면 가벼운 tick. 오르면 높게, 내리면 낮게 낸다.
  @override
  void didUpdateWidget(covariant _ScoringPreviewChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.preview?.expectedScore;
    final after = widget.preview?.expectedScore;
    if (after == null || before == after) return;
    GameFeedback.play(
      GameCue.previewChange,
      pitch: before == null || after > before ? 1 : 0.85,
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
    final pendingConfirmItemCount = widget.pendingConfirmItemCount;
    final hasConstraint = preview?.hasConstraintPenalty ?? false;
    final accent = preview == null
        ? GameUiPalette.textPrimary.withValues(alpha: 0.34)
        : GameUiPalette.actionGold;
    final rankLabel = preview == null
        ? ''
        : context.translate(rummiHandRankKey(preview.representativeRank));
    final label = preview == null
        ? context.translate('battleNoConfirmLines')
        : preview.lineCount == 1
        ? context.translate(
            'battlePreviewOneLine',
            namedArgs: {'rank': rankLabel, 'score': '${preview.expectedScore}'},
          )
        : context.translate(
            'battlePreviewLines',
            namedArgs: {
              'count': '${preview.lineCount}',
              'rank': rankLabel,
              'score': '${preview.expectedScore}',
            },
          );
    final detail = _previewDetail(
      context,
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
      child: TweenAnimationBuilder<double>(
        key: pulseKey,
        tween: Tween<double>(begin: 0, end: 1),
        duration: GamePresentationTimings.scoringPreviewScale,
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          final progress = value.clamp(0.0, 1.0);
          final fadeEnd =
              GamePresentationTimings.scoringPreviewFadeIn.inMilliseconds /
              GamePresentationTimings.scoringPreviewScale.inMilliseconds;
          final opacity = (progress / fadeEnd).clamp(0.0, 1.0);
          final scale = progress < 0.45
              ? 0.94 + (0.12 * (progress / 0.45))
              : 1.06 + (-0.06 * ((progress - 0.45) / 0.55));
          return Opacity(
            opacity: opacity,
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: DecoratedBox(
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
                      color: const Color(0xFFFFD36B).withValues(alpha: 0.18),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                          ? GameUiPalette.textPrimary.withValues(alpha: 0.54)
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
        ),
      ),
    );
  }
}

String _previewDetail(
  BuildContext context,
  RummiScoringPreview? preview, {
  required bool hasConstraint,
  required int pendingConfirmItemCount,
}) {
  if (preview == null) {
    return pendingConfirmItemCount > 0
        ? context.translate(
            'battlePendingItems',
            namedArgs: {'count': '$pendingConfirmItemCount'},
          )
        : context.translate('battleBuildEffects');
  }
  if (hasConstraint) {
    return context.translate(
      'battlePenaltyPercent',
      namedArgs: {'percent': '${preview.constraintPenaltyPercent}'},
    );
  }
  if (pendingConfirmItemCount > 0) {
    final applied = preview.expectedItemEffectCount;
    return applied > 0
        ? context.translate(
            'battleAppliedItems',
            namedArgs: {
              'applied': '$applied',
              'total': '$pendingConfirmItemCount',
            },
          )
        : context.translate(
            'battleUnmetItems',
            namedArgs: {'total': '$pendingConfirmItemCount'},
          );
  }
  if (preview.expectedTileModifierEffectCount > 0) {
    return context.translate(
      'battleTileEffects',
      namedArgs: {'count': '${preview.expectedTileModifierEffectCount}'},
    );
  }
  return context.translate(
    preview.overlapBonus > 0
        ? 'battlePreviewEffectsOverlap'
        : 'battlePreviewEffects',
    namedArgs: {
      'chips': '${preview.baseScore}',
      'overlap': '${preview.overlapBonus}',
      'jesters': '${preview.expectedJesterEffectCount}',
      'items': '${preview.expectedItemEffectCount}',
    },
  );
}

/// 전투 액션 버튼. 누르는 동안 찌그러지고 떼면 juice로 튕긴다.
///
/// 결과 소리는 행동 처리부가 의미 키로 낸다. [pressCue]는 결과 소리가 없는 버튼만 쓴다.
/// [armed]면 점수 가능 줄이 있어 확정이 장전된 상태로 빛나고, [heat]만큼 더 달아오른다.
class _BattleRailButton extends StatefulWidget {
  const _BattleRailButton({
    required this.tooltip,
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
    this.foregroundColor = GameUiPalette.textPrimary,
    this.size = 58,
    this.borderRadius = 9,
    this.pressCue,
    this.armed = false,
    this.heat = 0,
  });

  final String tooltip;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;
  final double size;
  final double borderRadius;
  final GameCue? pressCue;
  final bool armed;
  final double heat;

  @override
  State<_BattleRailButton> createState() => _BattleRailButtonState();
}

class _BattleRailButtonState extends State<_BattleRailButton> {
  bool _pressed = false;
  int _tapTick = 0;
  int _armTick = 0;

  @override
  void didUpdateWidget(covariant _BattleRailButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.armed && !oldWidget.armed) _armTick++;
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    final onPressed = widget.onPressed;
    if (onPressed == null) return;
    final cue = widget.pressCue;
    if (cue != null) GameFeedback.play(cue);
    setState(() => _tapTick++);
    onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final baseColor = isEnabled
        ? widget.backgroundColor
        : widget.backgroundColor.withValues(alpha: 0.34);
    final textColor = isEnabled
        ? widget.foregroundColor
        : widget.foregroundColor.withValues(alpha: 0.58);
    final armed = widget.armed && isEnabled;
    final glow = armed ? 0.45 + 0.4 * widget.heat : 0.0;

    return Tooltip(
      message: widget.tooltip,
      child: Juice(
        trigger: (_tapTick, _armTick),
        strength: _armTick > 0 && armed ? 1.2 : 0.9,
        pressed: _pressed && isEnabled,
        child: FxBoxGlow(
          key: armed ? const ValueKey('battle-confirm-armed') : null,
          color: GameUiPalette.actionGoldBright.withValues(alpha: glow),
          blurRadius: armed ? 10 + 10 * widget.heat : 0,
          spreadRadius: armed ? 1 + 2 * widget.heat : 0,
          child: Material(
            color: GameUiPalette.transparent,
            child: InkWell(
              onTap: isEnabled ? _handleTap : null,
              onTapDown: isEnabled ? (_) => _setPressed(true) : null,
              onTapUp: (_) => _setPressed(false),
              onTapCancel: () => _setPressed(false),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Ink(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: armed
                        ? GameUiPalette.actionGoldBright
                        : isEnabled
                        ? widget.foregroundColor.withValues(alpha: 0.28)
                        : widget.foregroundColor.withValues(alpha: 0.12),
                    width: armed ? 2 : 1.4,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 3,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.label,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.0,
                          fontWeight: armed ? FontWeight.w800 : FontWeight.w400,
                          color: textColor,
                        ),
                      ),
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
