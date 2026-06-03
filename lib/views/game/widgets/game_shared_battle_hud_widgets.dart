part of 'game_shared_widgets.dart';

class GameTopHud extends StatelessWidget {
  const GameTopHud({
    super.key,
    required this.station,
    required this.battle,
    required this.onOptionsTap,
    this.onTutorialTap,
    this.difficultyLabel = '표준',
    this.onBlindInfoTap,
    this.stationGoalDisplayScore,
    this.stationGoalPulse = false,
    this.stationGoalPulseTick = 0,
  });

  final RummiStationRuntimeFacade station;
  final RummiBattleRuntimeFacade battle;
  final String difficultyLabel;
  final VoidCallback onOptionsTap;
  final VoidCallback? onTutorialTap;
  final VoidCallback? onBlindInfoTap;
  final int? stationGoalDisplayScore;
  final bool stationGoalPulse;
  final int stationGoalPulseTick;

  @override
  Widget build(BuildContext context) {
    final objective = station.objective;
    final scoreTowardObjective =
        stationGoalDisplayScore ?? objective.scoreTowardObjective;
    final progress = objective.targetScore <= 0
        ? 0.0
        : (scoreTowardObjective / objective.targetScore).clamp(0.0, 1.0);
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
    final stationLabel = isEndless
        ? '무한 S${battle.stageIndex} · $difficultyLabel'
        : 'S${battle.stageIndex} · $difficultyLabel';
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
                    Text(
                      stationLabel,
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
                        '보상 +${RummiRunProgress.stageClearGoldBase}',
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
                          child: Align(
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: Text(
                                '$scoreTowardObjective/${objective.targetScore}',
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.visible,
                                style: gameHudValueStyle.copyWith(
                                  color: goalColor,
                                  fontSize: 17,
                                ),
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
                            value: progress,
                            minHeight: 6,
                            backgroundColor: GameUiPalette.ink.withValues(
                              alpha: 0.3,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progressColor,
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
