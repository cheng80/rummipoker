part of '../game_view.dart';

extension _GameViewRunEndFlow on _GameViewState {
  Future<bool> _bookmarkCurrentRun() async {
    final runtime = _gameNotifier.buildSaveRuntimeState(
      scene: _gameState.activeRunScene,
      difficulty: widget.difficulty,
    );
    final slots = await ActiveRunSaveService.loadBookmarkSlots();
    if (!mounted) return false;
    final slotIndex = await showBookmarkSlotDialog(
      context: context,
      title: '북마크하기',
      message: '저장할 슬롯을 선택하세요. 저장된 슬롯을 선택하면 해당 북마크를 덮어씁니다.',
      slots: slots,
    );
    if (!mounted || slotIndex == null) return false;
    final selected = slots[slotIndex];
    if (!selected.isEmpty) {
      final confirmed = await showConfirmDialog(
        context,
        title: '북마크 덮어쓰기',
        message: '${selected.label}\n\n이 슬롯을 현재 진행 상태로 덮어쓸까요?',
        cancelLabel: '취소',
        confirmLabel: '덮어쓰기',
      );
      if (!mounted || !confirmed) return false;
    }
    await ActiveRunSaveService.saveBookmarkSlot(
      slotIndex: slotIndex,
      runtime: runtime,
    );
    if (!mounted) return false;
    showTopNotice(context, '북마크 슬롯 ${slotIndex + 1}에 저장했습니다.');
    return true;
  }

  Future<bool> _loadBookmarkRunFromOptions() async {
    final slots = await ActiveRunSaveService.loadBookmarkSlots();
    if (!mounted) return false;
    final slotIndex = await showBookmarkSlotDialog(
      context: context,
      title: '북마크 불러오기',
      message: '불러올 슬롯을 선택하세요. 북마크를 불러오면 현재 이어하기 데이터가 선택한 북마크로 덮어써집니다.',
      slots: slots,
    );
    if (!mounted || slotIndex == null) return false;
    final selected = slots[slotIndex];
    if (selected.isEmpty) {
      showTopNotice(context, '비어 있는 북마크 슬롯입니다.');
      return false;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: '북마크 불러오기',
      message:
          '${selected.label}\n\n'
          '이 북마크를 불러오면 현재 이어하기 데이터가 이 상태로 바뀝니다.',
      cancelLabel: '취소',
      confirmLabel: '불러오기',
    );
    if (!mounted || !confirmed) return false;
    final runtime = await ActiveRunSaveService.restoreBookmarkToActiveRun(
      slotIndex,
    );
    if (!mounted) return false;
    if (runtime == null) {
      showTopNotice(context, '북마크를 불러오지 못했습니다.');
      return false;
    }
    _resumePresentation();
    _persistRetrySnapshotOnSave = false;
    _gameNotifier.replaceRuntimeState(
      session: runtime.session,
      runProgress: runtime.runProgress,
      stageStartSnapshot: runtime.stageStartSnapshot,
      stakeStartSnapshot: runtime.stakeStartSnapshot,
      activeRunScene: runtime.activeScene,
    );
    showTopNotice(context, '북마크 슬롯 ${slotIndex + 1}을 불러왔습니다.');
    return true;
  }

  Future<bool> _restartCurrentStakeWithConfirm() async {
    final confirmed = await showConfirmDialog(
      context,
      title: '현재 전투 재시작',
      message: '현재 전투 시작 시점으로 되돌릴까요?\n이번 전투에서 만든 보드와 점수 진행은 취소됩니다.',
      cancelLabel: '취소',
      confirmLabel: '현재 전투 재시작',
    );
    if (!mounted || !confirmed) return false;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return false;

    SoundManager.playSfx(AssetPaths.sfxBtnSnd);
    await _restartFromStakeSnapshot();
    return true;
  }

  Future<bool> _restartCurrentRun() async {
    if (_battleView.stageIndex >= 9) {
      final warned = await showConfirmDialog(
        context,
        title: '무한 Station 재시작',
        message:
            '무한 구간에서 Station 재시작은 현재 무한 진행을 크게 되돌릴 수 있습니다.\n'
            '계속할까요?',
        cancelLabel: '취소',
        confirmLabel: 'Station 재시작',
      );
      if (!mounted || !warned) return false;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return false;
    }
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
    _clearGameOverPresentation();
    _resumePresentation();
    _persistRetrySnapshotOnSave = false;
    _gameNotifier.restartCurrentStage();
    if (_isDebugFixtureRun) return;
    final blindSelectRuntime = _gameNotifier
        .prepareNextStationBlindSelectRuntime(difficulty: widget.difficulty);
    await ActiveRunSaveService.saveRuntimeState(blindSelectRuntime);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(
        '${RoutePaths.blindSelect}?difficulty=${widget.difficulty.name}',
        extra: blindSelectRuntime,
      );
    });
  }

  Future<void> _restartFromStageSnapshotAfterGameOver() async {
    if (_battleView.stageIndex >= 9) {
      final confirmed = await showConfirmDialog(
        context,
        title: '무한 Station 재시작',
        message:
            '무한 구간에서 Station 재시작은 현재 무한 진행을 크게 되돌릴 수 있습니다.\n'
            '계속할까요?',
        cancelLabel: '취소',
        confirmLabel: 'Station 재시작',
      );
      if (!mounted || !confirmed) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
    await _restartFromStageSnapshot();
  }

  Future<void> _restartFromStakeSnapshot() async {
    _clearGameOverPresentation();
    _resumePresentation();
    _persistRetrySnapshotOnSave = false;
    _gameNotifier.restartCurrentStake();
    await _saveActiveRun(scene: ActiveRunScene.battle);
  }

  Future<void> _exitAfterGameOver() async {
    _clearGameOverPresentation();
    _persistRetrySnapshotOnSave = false;
    await _recordRunEndIfNeeded(_expiredRunSummary());
    await ActiveRunSaveService.clearActiveRun();
    await _goToTitleAfterStoppingBgm();
  }

  Future<void> _startNewRunAfterGameOver() async {
    _clearGameOverPresentation();
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
    _clearGameOverPresentation();
    _persistRetrySnapshotOnSave = false;
    await _recordRunEndIfNeeded(_completedRunSummary());
    await ActiveRunSaveService.clearActiveRun();
    await _goToTitleAfterStoppingBgm();
  }

  Future<void> _recordRunEndIfNeeded(RunEndSummary summary) async {
    // 디버그 fixture는 눈검증용이므로 보상/도감 저장 상태를 바꾸지 않는다.
    if (_isDebugFixtureRun) return;
    _logRunEndSummaryForAnalytics(summary);
    await RunProgressionService.handleRunEnded(
      summary,
      runClaimId: summary.result == RunEndResult.completed
          ? _gameState.runProgress?.runClaimId
          : null,
    );
  }

  void _logRunEndSummaryForAnalytics(RunEndSummary summary) {
    if (summary.result == RunEndResult.expired) {
      if (_analyticsExpiredRunLogged) return;
      _analyticsExpiredRunLogged = true;
    } else {
      if (_analyticsCompletedRunLogged) return;
      _analyticsCompletedRunLogged = true;
    }
    unawaited(
      GameAnalyticsService.instance.logEvent(
        'run_end',
        parameters: {
          'result': summary.result.name,
          'difficulty': summary.difficulty.name,
          'modifier': widget.runModifier.id,
          'station_index': _battleView.stageIndex,
          'blind_tier': widget.blindTier.name,
          'reached_stage_index': summary.reachedStageIndex,
          'defeated_boss_count': summary.defeatedBossCount,
          'seen_jester_count': summary.seenMarketJesterIds.length,
          'seen_item_count': summary.seenMarketItemIds.length,
          'bought_jester_count': summary.boughtJesterIds.length,
          'bought_item_count': summary.boughtItemIds.length,
          'boss_modifier_count': summary.seenBossModifierIds.length,
          'cleared_station_count': summary.clearedStationKeys.length,
        },
        context: _gameAnalyticsContext,
      ),
    );
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

  void _clearGameOverPresentation() {
    if (!mounted) return;
    _mutate(() {
      _gameOverFadeVisible = false;
      _gameOverSequenceInProgress = false;
    });
  }

  Future<void> _startGameOverSequence(List<RummiExpirySignal> signals) async {
    if (_gameOverSequenceInProgress) return;
    _logExpiredRunEnd(signals);
    _dismissBattleTutorial();
    _clearSelections();
    SoundManager.unlockForWeb();
    SoundManager.playSfx(AssetPaths.sfxTimeUp);
    _mutate(() {
      _gameOverSequenceInProgress = true;
      _gameOverFadeVisible = true;
    });
    await Future<void>.delayed(GamePresentationTimings.gameOverFade);
    if (!mounted) return;
    _showGameOverDialog(signals);
  }

  void _logExpiredRunEnd(List<RummiExpirySignal> signals) {
    if (_analyticsExpiredRunLogged) return;
    _analyticsExpiredRunLogged = true;
    unawaited(
      GameAnalyticsService.instance.logEvent(
        'run_end',
        parameters: {
          'result': 'expired',
          'difficulty': widget.difficulty.name,
          'modifier': widget.runModifier.id,
          'station_index': _battleView.stageIndex,
          'blind_tier': widget.blindTier.name,
          'target_score': _stationView.objective.targetScore,
          'score': _stationView.objective.scoreTowardObjective,
          'defeated_boss_count': _defeatedBossCountForRunEnd(completed: false),
          'expiry_signal_count': signals.length,
          'primary_expiry_signal': signals.isEmpty
              ? 'unknown'
              : signals.first.name,
        },
        context: _gameAnalyticsContext,
      ),
    );
  }

  void _showGameOverDialog(List<RummiExpirySignal> signals) {
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
      onRetryStake: _restartFromStakeSnapshot,
      onRetryStation: _restartFromStageSnapshotAfterGameOver,
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
      await Future<void>.delayed(
        GamePresentationTimings.debugGameOverOnLoadDelay,
      );
      if (!mounted) return;
      final signals = _gameNotifier.evaluateExpiry();
      unawaited(
        _startGameOverSequence(
          signals.isEmpty
              ? const [RummiExpirySignal.boardFullAfterDcExhausted]
              : signals,
        ),
      );
    });
  }
}
