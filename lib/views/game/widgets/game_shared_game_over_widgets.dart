part of 'game_shared_widgets.dart';

class GameOverInsightRewardCard extends StatelessWidget {
  const GameOverInsightRewardCard({super.key, required this.insightReward});

  final int insightReward;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: GameUiPalette.gameOverRewardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GameUiPalette.actionSuccess.withValues(alpha: 0.42),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 54,
            decoration: BoxDecoration(
              color: GameUiPalette.gameOverRewardIconSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: GameUiPalette.gameOverRewardAccent,
                width: 1.4,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.style_rounded,
              color: GameUiPalette.gameOverRewardAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.translate('battleWidgetsMemoryEarned'),
                  style: TextStyle(
                    color: GameUiPalette.gameOverRewardAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                SemanticText(
                  context.translate('battleWidgetsMemoryDescription'),
                  style: TextStyle(
                    color: GameUiPalette.textPrimary.withValues(alpha: 0.72),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GameOverRunSummary {
  const GameOverRunSummary({
    this.difficultyLabel,
    this.difficulty,
    this.runModifier,
    required this.stageIndex,
    required this.scoreTowardTarget,
    required this.targetScore,
    required this.seed,
    this.bestRank,
    this.bestRankScore = 0,
    this.mostPlayedRank,
    this.mostPlayedCount = 0,
    this.playedHandTotal = 0,
    this.boughtJesterCount = 0,
    this.boughtItemCount = 0,
    this.addedDeckTileCount = 0,
  });

  final String? difficultyLabel;
  final NewRunDifficulty? difficulty;
  final NewRunModifier? runModifier;
  final int stageIndex;
  final int scoreTowardTarget;
  final int targetScore;
  final int seed;
  final RummiHandRank? bestRank;
  final int bestRankScore;
  final RummiHandRank? mostPlayedRank;
  final int mostPlayedCount;
  final int playedHandTotal;
  final int boughtJesterCount;
  final int boughtItemCount;
  final int addedDeckTileCount;
}

String gameOverTauntLineForSeed(int seed, {BuildContext? context}) {
  const lines = [
    'battleWidgetsTaunt0',
    'battleWidgetsTaunt1',
    'battleWidgetsTaunt2',
    'battleWidgetsTaunt3',
    'battleWidgetsTaunt4',
    'battleWidgetsTaunt5',
    'battleWidgetsTaunt6',
    'battleWidgetsTaunt7',
    'battleWidgetsTaunt8',
    'battleWidgetsTaunt9',
  ];
  return _battleWidgetTranslation(context, lines[seed.abs() % lines.length]);
}

/// 만료 신호 목록으로 게임오버 다이얼로그를 표시한다.
/// [onRetryStake]는 현재 전투 시작 스냅샷으로 즉시 복원한다.
/// [onRetryStation]은 현재 Station 시작 스냅샷으로 즉시 복원한다.
/// [onNewRun]은 이번 런 기록을 남기고 새 run 준비로 이동한다.
/// [onExit]는 저장을 정리하고 타이틀로 이동한다.
void showGameOverDialog({
  required BuildContext context,
  required List<RummiExpirySignal> signals,
  required int insightReward,
  GameOverRunSummary? runSummary,
  String? tauntLine,
  required Future<void> Function() onRetryStake,
  required Future<void> Function() onRetryStation,
  required Future<void> Function() onNewRun,
  required Future<void> Function() onExit,
}) {
  showGameFramedDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final resolvedTaunt =
          tauntLine ??
          gameOverTauntLineForSeed(
            (runSummary?.seed ?? 0) +
                (runSummary?.stageIndex ?? 0) +
                (runSummary?.scoreTowardTarget ?? 0),
            context: ctx,
          );
      final text = ctx.translate(
        'battleWidgetsGameOverMessage',
        namedArgs: {
          'signals': signals
              .map((signal) => expirySignalLabel(signal, context: ctx))
              .join('\n'),
        },
      );
      return GameModalCard(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ctx.translate('gameResult'),
                style: TextStyle(
                  fontFamily: AssetPaths.fontNexonLv2Gothic,
                  color: GameUiPalette.textPrimary.withValues(alpha: 0.95),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 14),
              _GameOverTauntPanel(text: resolvedTaunt),
              const SizedBox(height: 12),
              SemanticText(
                text,
                style: TextStyle(
                  color: GameUiPalette.textPrimary.withValues(alpha: 0.82),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              if (runSummary != null) ...[
                const SizedBox(height: 12),
                _GameOverRunSummaryCard(summary: runSummary),
              ],
              if (insightReward > 0) ...[
                const SizedBox(height: 12),
                _GameOverRewardReveal(
                  child: GameOverInsightRewardCard(
                    insightReward: insightReward,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GameActionButton(
                    key: const ValueKey('game-over-retry-stake'),
                    label: ctx.translate('battleWidgetsRetryBattle'),
                    background: GameUiPalette.actionGold,
                    foreground: GameUiPalette.ink,
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await WidgetsBinding.instance.endOfFrame;
                      _leaveGameOverSound(GameCue.runRestore);
                      await onRetryStake();
                    },
                  ),
                  const SizedBox(height: 10),
                  GameActionButton(
                    key: const ValueKey('game-over-retry-station'),
                    label: ctx.translate('battleWidgetsRetryStation'),
                    background: GameUiPalette.menuAccentRestart,
                    foreground: GameUiPalette.ink,
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await WidgetsBinding.instance.endOfFrame;
                      _leaveGameOverSound(GameCue.runRestore);
                      await onRetryStation();
                    },
                  ),
                  const SizedBox(height: 10),
                  GameActionButton(
                    key: const ValueKey('game-over-new-run'),
                    label: ctx.translate('battleWidgetsNewRun'),
                    background: GameUiPalette.actionSuccess,
                    foreground: GameUiPalette.ink,
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await WidgetsBinding.instance.endOfFrame;
                      _leaveGameOverSound(GameCue.runStart);
                      await onNewRun();
                    },
                  ),
                  const SizedBox(height: 10),
                  GameActionButton(
                    key: const ValueKey('game-over-exit'),
                    label: ctx.translate('exit'),
                    background: GameUiPalette.disabledControl,
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await WidgetsBinding.instance.endOfFrame;
                      _leaveGameOverSound(GameCue.buttonTap);
                      await onExit();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// 결과 창을 떠날 때 전역 pitch를 먼저 되돌린 뒤 버튼 의미에 맞는 소리를 낸다.
void _leaveGameOverSound(GameCue cue) {
  SoundManager.rampGlobalPitch(1, Duration.zero);
  GameFeedback.play(cue);
}

/// 기억 카드가 결과 창이 열린 뒤 한 번 뒤집히며 공개된다.
class _GameOverRewardReveal extends StatefulWidget {
  const _GameOverRewardReveal({required this.child});

  final Widget child;

  @override
  State<_GameOverRewardReveal> createState() => _GameOverRewardRevealState();
}

class _GameOverRewardRevealState extends State<_GameOverRewardReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _flip;
  bool _cuePlayed = false;

  static Duration get _total =>
      GamePresentationTimings.gameOverRewardRevealDelay +
      GamePresentationTimings.gameOverRewardReveal;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _total);
    final start =
        GamePresentationTimings.gameOverRewardRevealDelay.inMicroseconds /
        _total.inMicroseconds;
    _flip = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: Curves.easeOutBack),
    );
    if (MotionPolicy.juiceScale <= 0) {
      _controller.value = 1;
      return;
    }
    _controller.addListener(() {
      if (_cuePlayed || _controller.value < start) return;
      _cuePlayed = true;
      GameFeedback.play(GameCue.unlock);
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      key: const ValueKey('game-over-reward-reveal'),
      animation: _flip,
      child: widget.child,
      builder: (context, child) {
        // 옆면(0, 90도)에서 앞면(1)으로 세로축 회전해 공개된다.
        final t = _flip.value;
        final angle = (1 - t) * pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angle),
          child: child,
        );
      },
    );
  }
}

class _GameOverTauntPanel extends StatelessWidget {
  const _GameOverTauntPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiPalette.surfaceDanger,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GameUiPalette.specialDangerBorder.withValues(alpha: 0.46),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.theater_comedy_rounded,
              color: GameUiPalette.specialDangerText,
              size: 24,
            ),
            Expanded(
              child: SemanticText(
                text,
                softWrap: true,
                style: const TextStyle(
                  color: GameUiPalette.specialDangerPale,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  height: 1.28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameOverRunSummaryCard extends StatelessWidget {
  const _GameOverRunSummaryCard({required this.summary});

  final GameOverRunSummary summary;

  @override
  Widget build(BuildContext context) {
    final scoreText = summary.targetScore <= 0
        ? '${summary.scoreTowardTarget}'
        : '${summary.scoreTowardTarget} / ${summary.targetScore}';
    final bestHand = summary.bestRank == null
        ? context.translate('battleWidgetsNone')
        : context.translate(
            'battleWidgetsBestHandValue',
            namedArgs: {
              'rank': context.translate(rummiHandRankKey(summary.bestRank!)),
              'chips': '${summary.bestRankScore}',
            },
          );
    final mostPlayed = summary.mostPlayedRank == null
        ? context.translate('battleWidgetsNone')
        : context.translate(
            'battleWidgetsMostPlayedValue',
            namedArgs: {
              'rank': context.translate(
                rummiHandRankKey(summary.mostPlayedRank!),
              ),
              'count': '${summary.mostPlayedCount}',
            },
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiPalette.surfaceInfo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GameUiPalette.cardFallback.withValues(alpha: 0.26),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 7,
          children: [
            Text(
              context.translate('battleWidgetsRunSummary'),
              style: TextStyle(
                color: GameUiPalette.specialMutedText,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            _GameOverSummaryRow(
              label: context.translate('battleWidgetsReached'),
              value: context.translate(
                'coreSaveStationMode',
                namedArgs: {
                  'station': 'S${summary.stageIndex}',
                  'mode': context.runModeLabel(
                    difficulty: summary.difficulty,
                    runModifier: summary.runModifier,
                    difficultyLabel: summary.difficultyLabel,
                  ),
                },
              ),
            ),
            _GameOverSummaryRow(
              label: context.translate('battleWidgetsScore'),
              value: scoreText,
            ),
            _GameOverSummaryRow(
              label: context.translate('battleWidgetsBestHand'),
              value: bestHand,
            ),
            _GameOverSummaryRow(
              label: context.translate('battleWidgetsMostPlayed'),
              value: mostPlayed,
            ),
            _GameOverSummaryRow(
              label: context.translate('battleWidgetsCompletionsPurchases'),
              value: context.translate(
                'battleWidgetsCompletionsPurchasesValue',
                namedArgs: {
                  'hands': '${summary.playedHandTotal}',
                  'jesters': '${summary.boughtJesterCount}',
                  'items': '${summary.boughtItemCount}',
                },
              ),
            ),
            _GameOverSummaryRow(
              label: context.translate('battleWidgetsDeckSeed'),
              value: context.translate(
                'battleWidgetsDeckSeedValue',
                namedArgs: {
                  'count': '${summary.addedDeckTileCount}',
                  'seed': '${summary.seed}',
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameOverSummaryRow extends StatelessWidget {
  const _GameOverSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: TextStyle(
              color: GameUiPalette.textPrimary.withValues(alpha: 0.62),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ),
        Expanded(
          child: SemanticText(
            value,
            softWrap: true,
            style: const TextStyle(
              color: GameUiPalette.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}
