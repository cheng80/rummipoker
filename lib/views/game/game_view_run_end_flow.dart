part of '../game_view.dart';

extension _GameViewRunEndFlow on _GameViewState {
  Future<bool> _restartCurrentRun() async {
    final confirmed = await showConfirmDialog(
      context,
      title: '현재 Station 재시작',
      message:
          '현재 Station 시작 시점으로 되돌릴까요?\n이 Station에서 얻은 골드, 제스터, 진행 상태는 취소됩니다.',
      cancelLabel: '취소',
      confirmLabel: '현재 Station 재시작',
    );
    if (!mounted || !confirmed) return false;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return false;

    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    await _restartFromStageSnapshot();
    return true;
  }

  Future<bool> _exitToTitleWithConfirm() async {
    final confirmed = await showConfirmDialog(
      context,
      title: '메인 메뉴로 나가기',
      message: '현재 진행을 멈추고 메인 메뉴로 돌아갈까요?\n이어하기로 다시 복원할 수 있습니다.',
      cancelLabel: '취소',
      confirmLabel: '나가기',
    );
    if (!mounted || !confirmed) return false;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return false;

    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    await _goToTitleAfterStoppingBgm();
    return true;
  }

  Future<void> _restartFromStageSnapshot() async {
    _resumePresentation();
    _persistRetrySnapshotOnSave = false;
    _gameNotifier.restartCurrentStage();
    await _saveActiveRun(scene: ActiveRunScene.battle);
  }

  Future<void> _exitAfterGameOver() async {
    _persistRetrySnapshotOnSave = false;
    await _recordRunEndIfNeeded(_expiredRunSummary());
    await ActiveRunSaveService.clearActiveRun();
    await _goToTitleAfterStoppingBgm();
  }

  Future<void> _startNewRunAfterGameOver() async {
    _persistRetrySnapshotOnSave = false;
    await _recordRunEndIfNeeded(_expiredRunSummary());
    await ActiveRunSaveService.clearActiveRun();
    await SoundManager.stopBgm();
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    context.go(RoutePaths.newRun);
  }

  Future<void> _completeRunAndReturnToTitle() async {
    _persistRetrySnapshotOnSave = false;
    await _recordRunEndIfNeeded(_completedRunSummary());
    await ActiveRunSaveService.clearActiveRun();
    await _goToTitleAfterStoppingBgm();
  }

  Future<void> _recordRunEndIfNeeded(RunEndSummary summary) async {
    // 디버그 fixture는 눈검증용이므로 보상/도감 저장 상태를 바꾸지 않는다.
    if (_isDebugFixtureRun) return;
    await RunProgressionService.handleRunEnded(summary);
  }

  RunEndSummary _expiredRunSummary() {
    return RunEndSummary(
      result: RunEndResult.expired,
      difficulty: widget.difficulty,
      reachedStageIndex: _battleView.stageIndex,
      defeatedBossCount: _defeatedBossCountForRunEnd(completed: false),
      seenMarketJesterIds: _runProgressCollection.seenMarketJesterIds,
      seenMarketItemIds: _runProgressCollection.seenMarketItemIds,
      boughtJesterIds: _runProgressCollection.boughtJesterIds,
      boughtItemIds: _runProgressCollection.boughtItemIds,
      seenBossModifierIds: _runProgressCollection.seenBossModifierIds,
      clearedStationKeys: _runProgressCollection.clearedStationKeys,
      playedHandCounts: _runProgressCollection.snapshotPlayedHandCounts(),
      handGrowthStates: _runProgressCollection.snapshotHandGrowthStates(),
      addedDeckTiles: List<Tile>.from(_runProgressCollection.addedDeckTiles),
    );
  }

  int _defeatedBossCountForRunEnd({required bool completed}) {
    final stageIndex = _battleView.stageIndex;
    if (stageIndex <= 0) return 0;
    return completed ? stageIndex : math.max(0, stageIndex - 1);
  }

  void _showGameOver(List<RummiExpirySignal> signals) {
    if (!mounted) return;
    final summary = RunEndSummary(
      result: RunEndResult.expired,
      difficulty: widget.difficulty,
      reachedStageIndex: _battleView.stageIndex,
      defeatedBossCount: _defeatedBossCountForRunEnd(completed: false),
    );
    showGameOverDialog(
      context: context,
      signals: signals,
      insightReward: RunProgressionService.calculateInsightReward(summary),
      runSummary: _gameOverRunSummary(),
      onRetry: _restartFromStageSnapshot,
      onNewRun: _startNewRunAfterGameOver,
      onExit: _exitAfterGameOver,
    );
  }

  GameOverRunSummary _gameOverRunSummary() {
    final session = _gameState.session;
    final counts = _runProgressCollection.snapshotPlayedHandCounts();
    final growthStates = _runProgressCollection.snapshotHandGrowthStates();
    RummiHandRank? bestRank;
    var bestRankScore = 0;
    RummiHandRank? mostPlayedRank;
    var mostPlayedCount = 0;
    var playedHandTotal = 0;

    for (final entry in counts.entries) {
      final count = entry.value < 0 ? 0 : entry.value;
      playedHandTotal += count;
      if (count > mostPlayedCount) {
        mostPlayedRank = entry.key;
        mostPlayedCount = count;
      }
      final growthState =
          growthStates[entry.key] ??
          RummiHandGrowthState.fromCompletedCount(entry.key, count);
      final score = RummiHandGrowth.grownBaseScoreForState(
        rank: entry.key,
        baseScore: gddBaseScore(entry.key),
        state: growthState,
      );
      if (score > bestRankScore) {
        bestRank = entry.key;
        bestRankScore = score;
      }
    }

    return GameOverRunSummary(
      difficultyLabel: NewRunSetup(
        difficulty: widget.difficulty,
      ).difficultyLabel,
      stageIndex: _battleView.stageIndex,
      scoreTowardTarget: session?.blind.scoreTowardBlind ?? 0,
      targetScore: session?.blind.targetScore ?? 0,
      seed: session?.runSeed ?? widget.runSeed,
      bestRank: bestRank,
      bestRankScore: bestRankScore,
      mostPlayedRank: mostPlayedRank,
      mostPlayedCount: mostPlayedCount,
      playedHandTotal: playedHandTotal,
      boughtJesterCount: _runProgressCollection.boughtJesterIds.length,
      boughtItemCount: _runProgressCollection.boughtItemIds.length,
      addedDeckTileCount: _runProgressCollection.addedDeckTiles.length,
    );
  }

  void _showDebugGameOverOnLoadIfNeeded() {
    if (!AppConfig.showDebugFixtures ||
        !widget.debugShowGameOverOnLoad ||
        _debugGameOverDialogShown) {
      return;
    }
    _debugGameOverDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
      final signals = _gameNotifier.evaluateExpiry();
      _showGameOver(
        signals.isEmpty
            ? const [RummiExpirySignal.boardFullAfterDcExhausted]
            : signals,
      );
    });
  }
}
