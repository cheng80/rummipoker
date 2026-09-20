part of 'game_shared_widgets.dart';

class GameTopHud extends StatelessWidget {
  const GameTopHud({
    super.key,
    required this.station,
    required this.battle,
    required this.onOptionsTap,
    this.onTutorialTap,
    this.difficultyLabel,
    this.difficulty,
    this.runModifier,
    this.onBlindInfoTap,
    this.stationGoalDisplayScore,
    this.stationGoalPulse = false,
    this.stationGoalPulseTick = 0,
    this.goalHeat = 0,
  });

  final RummiStationRuntimeFacade station;
  final RummiBattleRuntimeFacade battle;
  final String? difficultyLabel;
  final NewRunDifficulty? difficulty;
  final NewRunModifier? runModifier;
  final VoidCallback onOptionsTap;
  final VoidCallback? onTutorialTap;
  final VoidCallback? onBlindInfoTap;
  final int? stationGoalDisplayScore;
  final bool stationGoalPulse;
  final int stationGoalPulseTick;

  /// 미리보기 점수가 남은 목표를 넘을 때의 달아오름(0~1).
  final double goalHeat;

  @override
  Widget build(BuildContext context) {
    final difficultyLabel = context.runModeLabel(
      difficulty: difficulty,
      runModifier: runModifier,
      difficultyLabel: this.difficultyLabel,
    );
    final objective = station.objective;
    final scoreTowardObjective =
        stationGoalDisplayScore ?? objective.scoreTowardObjective;
    final goalReached =
        objective.targetScore > 0 &&
        scoreTowardObjective >= objective.targetScore;
    final isEndless = BlindSelectionSetup.isEndlessStation(battle.stageIndex);
    final blindLabel = _battleBlindLabel(battle.currentBlindTierIndex);
    final blindColor = _battleBlindColor(
      battle.currentBlindTierIndex,
      isEndless: isEndless,
    );
    final bossModifier = battle.bossModifier;
    final stationLabel = context.translate(
      'coreSaveStationMode',
      namedArgs: {
        'station': '${isEndless ? '∞' : ''}S${battle.stageIndex}',
        'mode': difficultyLabel,
      },
    );
    final goalLabel = isEndless ? 'ENDLESS GOAL' : 'STATION GOAL';
    final goalColor = isEndless
        ? GameUiPalette.specialGold
        : GameUiPalette.textPrimary.withValues(alpha: 0.92);
    final progressColor = isEndless
        ? GameUiPalette.specialDanger
        : GameUiPalette.actionGold;

    return SizedBox(
      height: kGameHudHeight,
      child: Row(
        children: [
          SizedBox(
            width: kGameHudBlindWidth,
            child: GestureDetector(
              key: const ValueKey('battle-blind-info-chip'),
              onTap: onBlindInfoTap,
              behavior: onBlindInfoTap == null
                  ? HitTestBehavior.deferToChild
                  : HitTestBehavior.opaque,
              child: GameHudChip(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 12,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: _StationLabelText(
                          label: stationLabel,
                          isEndless: isEndless,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Text(
                            blindLabel,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: gameHudValueStyle.copyWith(
                              color: blindColor,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 0),
                    if (bossModifier == null)
                      Text(
                        context.translate(
                          'battleWidgetsReward',
                          namedArgs: {
                            'gold': '${RummiRunProgress.stageClearGoldBase}',
                          },
                        ),
                        style: gameHudSubStyle,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      )
                    else
                      _BossModifierHudLabel(modifier: bossModifier),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: kGameHudGap),
          Expanded(
            child: TweenAnimationBuilder<double>(
              key: ValueKey(
                stationGoalPulse ? 'goal-$stationGoalPulseTick' : 'goal-idle',
              ),
              tween: Tween<double>(begin: 0, end: stationGoalPulse ? 1 : 0),
              duration: GamePresentationTimings.hudGoalPulse,
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                final glow = stationGoalPulse ? sin(value * pi) : 0.0;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kGameHudRadius),
                    boxShadow: [
                      if (glow > 0)
                        BoxShadow(
                          color: GameUiPalette.actionGoldBright.withValues(
                            alpha: 0.24 * glow,
                          ),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: child,
                );
              },
              child: FxBoxGlow(
                key: ValueKey(
                  goalHeat > 0 ? 'station-goal-heat' : 'station-goal-cool',
                ),
                color: GameUiPalette.actionGoldBright.withValues(
                  alpha: 0.5 * goalHeat,
                ),
                blurRadius: 6 + 10 * goalHeat,
                spreadRadius: 1.5 * goalHeat,
                child: GameHudChip(
                  key: const ValueKey('station-goal-chip'),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            goalLabel,
                            style: gameHudLabelStyle.copyWith(
                              color: isEndless
                                  ? GameUiPalette.specialGold
                                  : gameHudLabelStyle.color,
                            ),
                            maxLines: 1,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Expanded(
                            child: GameCountUpInt(
                              key: const ValueKey('station-goal-count-up'),
                              value: scoreTowardObjective,
                              builder: (context, shown) => Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.center,
                                        child: _StationGoalScoreText(
                                          score: shown,
                                          targetScore: objective.targetScore,
                                          color: goalColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      kGameHudProgressRadius,
                                    ),
                                    child: LinearProgressIndicator(
                                      key: const ValueKey(
                                        'station-goal-progress',
                                      ),
                                      value: objective.targetScore <= 0
                                          ? 0.0
                                          : (shown / objective.targetScore)
                                                .clamp(0.0, 1.0),
                                      minHeight: 6,
                                      backgroundColor: GameUiPalette.ink
                                          .withValues(alpha: 0.3),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.lerp(
                                          progressColor,
                                          GameUiPalette.actionGoldBright,
                                          goalHeat,
                                        )!,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (goalReached)
                        const Positioned(
                          key: ValueKey('station-goal-clear-badge'),
                          right: -2,
                          top: -5,
                          child: _StationGoalClearBadge(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: kGameHudGap),
          SizedBox(
            width: kGameHudGoldWidth,
            child: _GameGoldHudChip(
              gold: battle.currentGold,
              onOptionsTap: onOptionsTap,
              onTutorialTap: onTutorialTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _StationLabelText extends StatelessWidget {
  const _StationLabelText({required this.label, required this.isEndless});

  final String label;
  final bool isEndless;

  @override
  Widget build(BuildContext context) {
    final baseStyle = gameHudLabelStyle.copyWith(
      color: isEndless ? GameUiPalette.specialGold : gameHudLabelStyle.color,
    );
    if (!isEndless || !label.startsWith('∞')) {
      return Text(
        label,
        style: baseStyle,
        maxLines: 1,
        textAlign: TextAlign.center,
      );
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '∞',
            style: baseStyle.copyWith(color: GameUiPalette.specialDanger),
          ),
          TextSpan(text: label.substring(1), style: baseStyle),
        ],
      ),
      maxLines: 1,
      textAlign: TextAlign.center,
    );
  }
}

class _StationGoalScoreText extends StatelessWidget {
  const _StationGoalScoreText({
    required this.score,
    required this.targetScore,
    required this.color,
  });

  final int score;
  final int targetScore;
  final Color color;

  static const int _singleLineMaxLength = 11;

  @override
  Widget build(BuildContext context) {
    final singleLineText = '$score/$targetScore';
    final baseStyle = gameHudValueStyle.copyWith(color: color, fontSize: 17);
    if (singleLineText.length <= _singleLineMaxLength) {
      return Text(
        singleLineText,
        maxLines: 1,
        textAlign: TextAlign.center,
        overflow: TextOverflow.visible,
        style: baseStyle,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$score',
          maxLines: 1,
          textAlign: TextAlign.center,
          style: baseStyle.copyWith(fontSize: 14, height: 0.9),
        ),
        Text(
          '/$targetScore',
          maxLines: 1,
          textAlign: TextAlign.center,
          style: baseStyle.copyWith(fontSize: 14, height: 0.9),
        ),
      ],
    );
  }
}

String _battleBlindLabel(int tierIndex) {
  return switch (tierIndex) {
    1 => 'CLASH',
    2 => 'BOSS',
    _ => 'SCOUT',
  };
}

Color _battleBlindColor(int tierIndex, {bool isEndless = false}) {
  if (isEndless) {
    return switch (tierIndex) {
      1 => GameUiPalette.specialGold,
      2 => GameUiPalette.specialDanger,
      _ => GameUiPalette.specialWarning,
    };
  }
  return switch (tierIndex) {
    1 => GameUiPalette.specialBlue,
    2 => GameUiPalette.actionWarning,
    _ => GameUiPalette.specialMint,
  };
}
