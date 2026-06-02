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
                const Text(
                  '기억 카드 획득',
                  style: TextStyle(
                    color: GameUiPalette.gameOverRewardAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '다음 런 준비에서 새 규칙을 여는 데 사용됩니다.',
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
    required this.difficultyLabel,
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

  final String difficultyLabel;
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

String gameOverTauntLineForSeed(int seed) {
  const lines = [
    '전략은 좋았어요. 결과만 빼면요.',
    '덱은 기억합니다. 이번 실수도요.',
    '한 줄만 더 만들었으면 멋졌겠네요. 만들었다면요.',
    '보드는 가득 찼고, 변명도 꽤 찼습니다.',
    '족보는 자랐습니다. 자존심은 잠시 접어 둡시다.',
    '이번 런은 교훈이 많네요. 점수 빼고요.',
    '방금 선택은 기록해 뒀습니다. 반면교사로요.',
    '운이 나빴다고 해도 됩니다. 카드가 듣지 않는다면요.',
    '다음 런에서는 이 장면을 못 본 척해 드릴게요.',
    '성장은 남았습니다. 승리는 다음에 찾죠.',
  ];
  return lines[seed.abs() % lines.length];
}

/// 만료 신호 목록으로 게임오버 다이얼로그를 표시한다.
/// [onRetry]는 현재 스테이지 시작 스냅샷으로 즉시 복원한다.
/// [onNewRun]은 이번 런 기록을 남기고 새 run 준비로 이동한다.
/// [onExit]는 저장을 정리하고 타이틀로 이동한다.
void showGameOverDialog({
  required BuildContext context,
  required List<RummiExpirySignal> signals,
  required int insightReward,
  GameOverRunSummary? runSummary,
  String? tauntLine,
  required Future<void> Function() onRetry,
  required Future<void> Function() onNewRun,
  required Future<void> Function() onExit,
}) {
  final resolvedTaunt =
      tauntLine ??
      gameOverTauntLineForSeed(
        (runSummary?.seed ?? 0) +
            (runSummary?.stageIndex ?? 0) +
            (runSummary?.scoreTowardTarget ?? 0),
      );
  final text =
      '${signals.map(expirySignalLabel).join('\n')}\n\n'
      '이번 런의 기록을 남기고 새로 시작할 수 있습니다.';
  showGameFramedDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => GameModalCard(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _localizedGameResultTitle(context),
              style: TextStyle(
                fontFamily: AssetPaths.fontNexonLv2Gothic,
                color: GameUiPalette.textPrimary.withValues(alpha: 0.95),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 14),
            _GameOverTauntPanel(text: resolvedTaunt),
            const SizedBox(height: 12),
            Text(
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
              GameOverInsightRewardCard(insightReward: insightReward),
            ],
            const SizedBox(height: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GameActionButton(
                  label: '다시 도전',
                  background: GameUiPalette.actionGold,
                  foreground: GameUiPalette.ink,
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await WidgetsBinding.instance.endOfFrame;
                    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
                    await onRetry();
                  },
                ),
                const SizedBox(height: 10),
                GameActionButton(
                  label: '새 run 준비',
                  background: GameUiPalette.actionSuccess,
                  foreground: GameUiPalette.ink,
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await WidgetsBinding.instance.endOfFrame;
                    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
                    await onNewRun();
                  },
                ),
                const SizedBox(height: 10),
                GameActionButton(
                  label: _localizedDialogLabel(context, 'exit', '나가기'),
                  background: GameUiPalette.disabledControl,
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await WidgetsBinding.instance.endOfFrame;
                    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
                    await onExit();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
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
              child: Text(
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
        ? '없음'
        : '${_gameOverHandRankLabel(summary.bestRank!)} · 칩 ${summary.bestRankScore}';
    final mostPlayed = summary.mostPlayedRank == null
        ? '없음'
        : '${_gameOverHandRankLabel(summary.mostPlayedRank!)} (${summary.mostPlayedCount})';

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
            const Text(
              '이번 런 정산',
              style: TextStyle(
                color: GameUiPalette.specialMutedText,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            _GameOverSummaryRow(
              label: '도달',
              value: 'S${summary.stageIndex} · ${summary.difficultyLabel}',
            ),
            _GameOverSummaryRow(label: '점수', value: scoreText),
            _GameOverSummaryRow(label: '베스트 족보', value: bestHand),
            _GameOverSummaryRow(label: '가장 많이 완성', value: mostPlayed),
            _GameOverSummaryRow(
              label: '완성/구매',
              value:
                  '족보 ${summary.playedHandTotal} · Jester ${summary.boughtJesterCount} · 아이템 ${summary.boughtItemCount}',
            ),
            _GameOverSummaryRow(
              label: '덱/시드',
              value: '추가 타일 ${summary.addedDeckTileCount} · ${summary.seed}',
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
          child: Text(
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

String _gameOverHandRankLabel(RummiHandRank rank) {
  return switch (rank) {
    RummiHandRank.highCard => '하이',
    RummiHandRank.onePair => '원페어',
    RummiHandRank.twoPair => '투페어',
    RummiHandRank.threeOfAKind => '트리플',
    RummiHandRank.straight => '스트레이트',
    RummiHandRank.flush => '플러시',
    RummiHandRank.fullHouse => '풀하우스',
    RummiHandRank.fourOfAKind => '포카드',
    RummiHandRank.straightFlush => '스티플',
    RummiHandRank.prismStraight => '프리즘 스트레이트',
    RummiHandRank.crownFourOfAKind => '크라운 포카드',
    RummiHandRank.lowStraightFlush => '로우 스티플',
    RummiHandRank.royalStraightFlush => '로열 스티플',
    RummiHandRank.fiveOfAKind => '파이브 카드',
    RummiHandRank.flushHouse => '플러시 하우스',
    RummiHandRank.flushFive => '플러시 파이브',
  };
}

String _localizedGameResultTitle(BuildContext context) {
  return _localizedDialogLabel(context, 'gameResult', '게임결과');
}

String _localizedDialogLabel(
  BuildContext context,
  String key,
  String fallback,
) {
  try {
    return context.tr(key);
  } on Object {
    return fallback;
  }
}
