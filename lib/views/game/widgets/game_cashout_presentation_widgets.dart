part of 'game_cashout_widgets.dart';

class GameStageClearOverlay extends StatelessWidget {
  const GameStageClearOverlay({
    super.key,
    required this.phase,
    required this.stageIndex,
    required this.scoreAdded,
  });

  final GameStageFlowPhase phase;
  final int stageIndex;
  final int scoreAdded;

  @override
  Widget build(BuildContext context) {
    final isSettlement = phase == GameStageFlowPhase.settlement;
    final isEndless = stageIndex > 8;
    final accentColor = isEndless
        ? GameUiPalette.specialDanger
        : GameUiPalette.actionGoldBright;
    return ColoredBox(
      color: (isEndless ? GameUiPalette.surfaceEndlessDeep : GameUiPalette.ink)
          .withValues(alpha: 0.58),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.94, end: 1),
          duration: GamePresentationTimings.stageClearOverlayPop,
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!isSettlement) const _StageClearSparkField(),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                decoration: BoxDecoration(
                  color: isEndless
                      ? GameUiPalette.surfaceEndless
                      : GameUiPalette.surfacePanel,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.72),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GameUiPalette.ink.withValues(alpha: 0.28),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.translate(
                        isEndless
                            ? (isSettlement
                                  ? 'coreSettlementEndlessScore'
                                  : 'coreSettlementEndlessClear')
                            : (isSettlement
                                  ? 'coreSettlementScoreSettled'
                                  : 'coreSettlementStationClear'),
                      ),
                      style: TextStyle(
                        color: isSettlement
                            ? GameUiPalette.textPrimary.withValues(alpha: 0.78)
                            : accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isEndless
                          ? context.translate(
                              'marketEndlessStation',
                              namedArgs: {'stage': '$stageIndex'},
                            )
                          : context.translate(
                              'coreSettlementStation',
                              namedArgs: {'stage': '$stageIndex'},
                            ),
                      style: TextStyle(
                        color: isEndless
                            ? GameUiPalette.specialEndlessText
                            : GameUiPalette.textPrimary.withValues(alpha: 0.96),
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (isSettlement)
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: scoreAdded),
                        duration: GamePresentationTimings.stageClearScoreCount,
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return Text(
                            '+$value',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          );
                        },
                      )
                    else
                      Text(
                        isEndless
                            ? context.translate('marketEndlessGoalReached')
                            : context.translate('marketGoalReached'),
                        style: TextStyle(
                          color: GameUiPalette.textPrimary.withValues(
                            alpha: 0.9,
                          ),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      isSettlement
                          ? context.translate(
                              'marketConfirmedScore',
                              namedArgs: {'score': '$scoreAdded'},
                            )
                          : context.translate('marketSettling'),
                      style: TextStyle(
                        color: GameUiPalette.textPrimary.withValues(
                          alpha: 0.66,
                        ),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageClearSparkField extends StatelessWidget {
  const _StageClearSparkField();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('stage-clear-spark-field'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.stageClearSpark,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return CustomPaint(
          painter: _StageClearSparkPainter(progress: value),
          size: const Size(260, 150),
        );
      },
    );
  }
}

class _StageClearSparkPainter extends CustomPainter {
  const _StageClearSparkPainter({required this.progress});

  final double progress;

  static const List<Offset> _origins = [
    Offset(-90, -44),
    Offset(-54, 38),
    Offset(58, -42),
    Offset(94, 32),
    Offset(0, -64),
    Offset(10, 54),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..strokeCap = StrokeCap.round;
    final fade = (1 - progress).clamp(0.0, 1.0);
    for (var i = 0; i < _origins.length; i++) {
      final angle = -math.pi / 2 + i * math.pi / 3;
      final origin = center + _origins[i];
      final travel = 20.0 + 8.0 * (i % 2);
      final sparkCenter =
          origin + Offset(math.cos(angle), math.sin(angle)) * travel * progress;
      final arm = 5.0 + 2.0 * (1 - progress);
      paint
        ..color = const Color(
          0xFFF2C14E,
          // 바깥 Opacity(1 - progress)를 선 알파에 합쳐 그린다.
        ).withValues(alpha: (0.82 * fade * fade).clamp(0.0, 1.0))
        ..strokeWidth = 2.2 * (1 - progress * 0.45);
      canvas.drawLine(
        sparkCenter.translate(-arm, 0),
        sparkCenter.translate(arm, 0),
        paint,
      );
      canvas.drawLine(
        sparkCenter.translate(0, -arm),
        sparkCenter.translate(0, arm),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StageClearSparkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class GameFloatingSettlementBurst extends StatelessWidget {
  const GameFloatingSettlementBurst({
    super.key,
    required this.line,
    required this.step,
    required this.effectIndex,
    this.effectIndexes = const [],
  });

  final ConfirmedLineBreakdown? line;
  final ScoringPresentationStep step;
  final int? effectIndex;
  final List<int> effectIndexes;

  @override
  Widget build(BuildContext context) {
    final currentLine = line;
    final activeEffects = _settlementStepEffects(
      currentLine,
      effectIndex,
      effectIndexes,
    );
    final activeEffect = activeEffects.length == 1
        ? activeEffects.single
        : null;
    final label = activeEffects.length > 1
        ? _settlementStepMultiEffectLabel(context, step, activeEffects)
        : _settlementStepLabel(context, currentLine, step, activeEffect);
    final subLabel = activeEffects.length > 1
        ? _settlementStepMultiEffectSubLabel(context, activeEffects)
        : _settlementStepSubLabel(context, currentLine, step, activeEffect);
    final displayedScore = activeEffects.length > 1
        ? activeEffects.fold<int>(0, (sum, effect) => sum + effect.scoreDelta)
        : _settlementStepScore(currentLine, step, activeEffect);

    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: GamePresentationTimings.settlementStepCalloutIn,
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          final opacity = (value / 0.65).clamp(0.0, 1.0);
          final dy = lerpDouble(10, 0, value)!;
          final scale = lerpDouble(0.96, 1, value)!;
          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        },
        child: Align(
          alignment: const Alignment(0, -0.18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: GameUiPalette.ink.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GameOutlinedLabel(
                    label,
                    textAlign: TextAlign.center,
                    fillColor: GameUiPalette.textPrimary.withValues(
                      alpha: 0.96,
                    ),
                    strokeColor: GameUiPalette.ink.withValues(alpha: 0.82),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.25,
                  ),
                  const SizedBox(height: 6),
                  _GameOutlinedLabel(
                    '+$displayedScore',
                    fillColor: GameUiPalette.actionGoldBright,
                    strokeColor: GameUiPalette.ink.withValues(alpha: 0.88),
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                  if (subLabel != null) ...[
                    const SizedBox(height: 4),
                    _GameOutlinedLabel(
                      subLabel,
                      textAlign: TextAlign.center,
                      fillColor: GameUiPalette.textPrimary.withValues(
                        alpha: 0.78,
                      ),
                      strokeColor: GameUiPalette.ink.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<RummiJesterEffectBreakdown> _settlementStepEffects(
  ConfirmedLineBreakdown? line,
  int? effectIndex,
  List<int> effectIndexes,
) {
  if (line == null) return const [];
  if (effectIndexes.isNotEmpty) {
    return [
      for (final index in effectIndexes)
        if (index >= 0 && index < line.effects.length) line.effects[index],
    ];
  }
  if (effectIndex == null ||
      effectIndex < 0 ||
      effectIndex >= line.effects.length) {
    return const [];
  }
  return [line.effects[effectIndex]];
}

String _settlementStepMultiEffectLabel(
  BuildContext context,
  ScoringPresentationStep step,
  List<RummiJesterEffectBreakdown> effects,
) {
  if (effects.length <= 2) {
    return effects
        .map((effect) {
          return switch (step) {
            ScoringPresentationStep.jester => JesterTranslationScope.of(
              context,
            ).resolveDisplayName(effect.jesterId, effect.displayName),
            ScoringPresentationStep.item => ItemTranslationScope.of(
              context,
            ).resolveDisplayName(effect.jesterId, effect.displayName),
            _ => localizedSettlementTileEffectName(context, effect),
          };
        })
        .join(' · ');
  }
  return switch (step) {
    ScoringPresentationStep.jester => context.translate(
      'marketJesterEffects',
      namedArgs: {'count': '${effects.length}'},
    ),
    ScoringPresentationStep.tile => context.translate(
      'marketTileEffects',
      namedArgs: {'count': '${effects.length}'},
    ),
    ScoringPresentationStep.item => context.translate(
      'marketItemEffects',
      namedArgs: {'count': '${effects.length}'},
    ),
    _ => context.translate(
      'marketScoreEffects',
      namedArgs: {'count': '${effects.length}'},
    ),
  };
}

String _settlementStepMultiEffectSubLabel(
  BuildContext context,
  List<RummiJesterEffectBreakdown> effects,
) {
  return effects
      .map((effect) => jesterEffectBadge(effect, context: context))
      .join(' · ');
}

String _settlementStepLabel(
  BuildContext context,
  ConfirmedLineBreakdown? line,
  ScoringPresentationStep step,
  RummiJesterEffectBreakdown? effect,
) {
  if (line == null) return context.translate('marketScoreSettlement');
  return switch (step) {
    ScoringPresentationStep.boardLine => context.translate(
      'marketNamedLine',
      namedArgs: {'line': localizedGameLineRefShortLabel(context, line.ref)},
    ),
    ScoringPresentationStep.handRank => gameHandRankLabel(
      line.rank,
      context: context,
    ),
    ScoringPresentationStep.overlap => context.translate(
      'coreSettlementOverlap',
    ),
    ScoringPresentationStep.constraint =>
      line.constraintPenalties.isEmpty
          ? context.translate('marketConstraintApplied')
          : (line.constraintPenalties.first.displayKeys == null
                ? line.constraintPenalties.first.title
                : context.translate(
                    line.constraintPenalties.first.displayKeys!.titleKey,
                  )),
    ScoringPresentationStep.jester =>
      effect == null
          ? context.translate('marketJesterEffect')
          : JesterTranslationScope.of(
              context,
            ).resolveDisplayName(effect.jesterId, effect.displayName),
    ScoringPresentationStep.tile =>
      effect == null
          ? context.translate('marketTileEffect')
          : localizedSettlementTileEffectName(context, effect),
    ScoringPresentationStep.item =>
      effect == null
          ? context.translate('marketItemEffect')
          : ItemTranslationScope.of(
              context,
            ).resolveDisplayName(effect.jesterId, effect.displayName),
    ScoringPresentationStep.finalScore => context.translate(
      'coreSettlementGoal',
    ),
    ScoringPresentationStep.none => context.translate(
      'marketRankLine',
      namedArgs: {
        'rank': gameHandRankLabel(line.rank, context: context),
        'line': localizedGameLineRefShortLabel(context, line.ref),
      },
    ),
  };
}

String? _settlementStepSubLabel(
  BuildContext context,
  ConfirmedLineBreakdown? line,
  ScoringPresentationStep step,
  RummiJesterEffectBreakdown? effect,
) {
  if (line == null) return null;
  return switch (step) {
    ScoringPresentationStep.boardLine => context.translate(
      'marketBoardLineConfirmed',
    ),
    ScoringPresentationStep.handRank => context.translate(
      'marketBaseChips',
      namedArgs: {'count': '${line.rankBaseScore ?? line.baseScore}'},
    ),
    ScoringPresentationStep.overlap => context.translate(
      'marketOverlapBonus',
      namedArgs: {'count': '${line.overlapBonus}'},
    ),
    ScoringPresentationStep.constraint =>
      line.constraintPenalties.isEmpty
          ? null
          : (line.constraintPenalties.first.displayKeys == null
                ? line.constraintPenalties.first.ruleText
                : context.translate(
                    line.constraintPenalties.first.displayKeys!.ruleTextKey,
                  )),
    ScoringPresentationStep.jester ||
    ScoringPresentationStep.tile ||
    ScoringPresentationStep.item =>
      effect == null ? null : jesterEffectBadge(effect, context: context),
    ScoringPresentationStep.finalScore => gameScoreBreakdownLabel(
      line,
      context: context,
    ),
    ScoringPresentationStep.none => gameScoreBreakdownLabel(
      line,
      context: context,
    ),
  };
}

int _settlementStepScore(
  ConfirmedLineBreakdown? line,
  ScoringPresentationStep step,
  RummiJesterEffectBreakdown? effect,
) {
  if (line == null) return 0;
  return switch (step) {
    ScoringPresentationStep.boardLine => 0,
    ScoringPresentationStep.handRank => line.rankBaseScore ?? line.baseScore,
    ScoringPresentationStep.overlap => line.overlapBonus,
    ScoringPresentationStep.constraint =>
      line.constraintPenalties.isEmpty
          ? 0
          : line.constraintPenalties.first.scoreDelta,
    ScoringPresentationStep.jester ||
    ScoringPresentationStep.tile ||
    ScoringPresentationStep.item => effect?.scoreDelta ?? 0,
    ScoringPresentationStep.finalScore ||
    ScoringPresentationStep.none => line.finalScore,
  };
}
