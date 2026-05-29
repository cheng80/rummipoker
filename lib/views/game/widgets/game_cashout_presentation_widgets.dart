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
                      isEndless
                          ? (isSettlement ? 'ENDLESS SCORE' : 'ENDLESS CLEAR')
                          : (isSettlement ? 'SCORE SETTLED' : 'STATION CLEAR'),
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
                      isEndless ? '무한 도전 S$stageIndex' : 'Station $stageIndex',
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
                        isEndless ? '무한 도전 목표 달성' : 'Station Goal 달성',
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
                      isSettlement ? '이번 확정으로 +$scoreAdded' : '정산 중...',
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
        return Opacity(
          opacity: (1 - value).clamp(0.0, 1.0),
          child: CustomPaint(
            painter: _StageClearSparkPainter(progress: value),
            size: const Size(260, 150),
          ),
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
        ).withValues(alpha: 0.82 * (1 - progress))
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
  });

  final ConfirmedLineBreakdown? line;
  final ScoringPresentationStep step;
  final int? effectIndex;

  @override
  Widget build(BuildContext context) {
    final currentLine = line;
    final activeEffect =
        currentLine != null &&
            effectIndex != null &&
            effectIndex! >= 0 &&
            effectIndex! < currentLine.effects.length
        ? currentLine.effects[effectIndex!]
        : null;
    final label = _settlementStepLabel(
      context,
      currentLine,
      step,
      activeEffect,
    );
    final subLabel = _settlementStepSubLabel(currentLine, step, activeEffect);
    final displayedScore = _settlementStepScore(
      currentLine,
      step,
      activeEffect,
    );

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

String _settlementStepLabel(
  BuildContext context,
  ConfirmedLineBreakdown? line,
  ScoringPresentationStep step,
  RummiJesterEffectBreakdown? effect,
) {
  if (line == null) return '점수 정산';
  return switch (step) {
    ScoringPresentationStep.boardLine =>
      '${gameLineRefShortLabel(line.ref)} 라인',
    ScoringPresentationStep.handRank => gameHandRankLabel(line.rank),
    ScoringPresentationStep.overlap => 'overlap bonus',
    ScoringPresentationStep.constraint =>
      line.constraintPenalties.isEmpty
          ? '제약 적용'
          : line.constraintPenalties.first.title,
    ScoringPresentationStep.jester =>
      effect == null
          ? 'Jester 발동'
          : JesterTranslationScope.of(
              context,
            ).resolveDisplayName(effect.jesterId, effect.displayName),
    ScoringPresentationStep.tile => effect == null
        ? '타일 효과'
        : effect.displayName,
    ScoringPresentationStep.item =>
      effect == null
          ? 'Item 발동'
          : ItemTranslationScope.of(
              context,
            ).resolveDisplayName(effect.jesterId, effect.displayName),
    ScoringPresentationStep.finalScore => 'Station Goal',
    ScoringPresentationStep.none =>
      '${gameHandRankLabel(line.rank)} · ${gameLineRefShortLabel(line.ref)}',
  };
}

String? _settlementStepSubLabel(
  ConfirmedLineBreakdown? line,
  ScoringPresentationStep step,
  RummiJesterEffectBreakdown? effect,
) {
  if (line == null) return null;
  return switch (step) {
    ScoringPresentationStep.boardLine => '보드 라인 확정',
    ScoringPresentationStep.handRank =>
      '칩 ${line.rankBaseScore ?? line.baseScore}',
    ScoringPresentationStep.overlap => '겹침 +${line.overlapBonus}',
    ScoringPresentationStep.constraint =>
      line.constraintPenalties.isEmpty
          ? null
          : line.constraintPenalties.first.ruleText,
    ScoringPresentationStep.jester ||
    ScoringPresentationStep.tile ||
    ScoringPresentationStep.item =>
      effect == null ? null : jesterEffectBadge(effect),
    ScoringPresentationStep.finalScore => gameScoreBreakdownLabel(line),
    ScoringPresentationStep.none => gameScoreBreakdownLabel(line),
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
