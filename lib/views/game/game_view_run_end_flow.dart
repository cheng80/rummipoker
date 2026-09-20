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
      titleBuilder: (dialogContext) =>
          dialogContext.translate('battleBookmarkSave'),
      messageBuilder: (dialogContext) =>
          dialogContext.translate('battleBookmarkSavePrompt'),
      slots: slots,
    );
    if (!mounted || slotIndex == null) return false;
    final selected = slots[slotIndex];
    if (!selected.isEmpty) {
      final confirmed = await showConfirmDialog(
        context,
        titleBuilder: (dialogContext) =>
            dialogContext.translate('battleBookmarkOverwrite'),
        messageBuilder: (dialogContext) => dialogContext.translate(
          'battleBookmarkOverwritePrompt',
          namedArgs: {'label': dialogContext.activeRunSlotLabel(selected)},
        ),
        cancelLabelBuilder: (dialogContext) =>
            dialogContext.translate('cancel'),
        confirmLabelBuilder: (dialogContext) =>
            dialogContext.translate('battleOverwrite'),
      );
      if (!mounted || !confirmed) return false;
    }
    await ActiveRunSaveService.saveBookmarkSlot(
      slotIndex: slotIndex,
      runtime: runtime,
    );
    if (!mounted) return false;
    showTopNotice(
      context,
      context.translate(
        'battleBookmarkSaved',
        namedArgs: {'slot': '${slotIndex + 1}'},
      ),
    );
    return true;
  }

  Future<bool> _loadBookmarkRunFromOptions() async {
    final slots = await ActiveRunSaveService.loadBookmarkSlots();
    if (!mounted) return false;
    final slotIndex = await showBookmarkSlotDialog(
      context: context,
      titleBuilder: (dialogContext) =>
          dialogContext.translate('battleBookmarkLoad'),
      messageBuilder: (dialogContext) =>
          dialogContext.translate('battleBookmarkLoadPrompt'),
      slots: slots,
    );
    if (!mounted || slotIndex == null) return false;
    final selected = slots[slotIndex];
    if (selected.isEmpty) {
      showTopNotice(context, context.translate('battleBookmarkEmpty'));
      return false;
    }
    final confirmed = await showConfirmDialog(
      context,
      titleBuilder: (dialogContext) =>
          dialogContext.translate('battleBookmarkLoad'),
      messageBuilder: (dialogContext) => dialogContext.translate(
        'battleBookmarkRestorePrompt',
        namedArgs: {'label': dialogContext.activeRunSlotLabel(selected)},
      ),
      cancelLabelBuilder: (dialogContext) => dialogContext.translate('cancel'),
      confirmLabelBuilder: (dialogContext) =>
          dialogContext.translate('battleLoad'),
    );
    if (!mounted || !confirmed) return false;
    final runtime = await ActiveRunSaveService.restoreBookmarkToActiveRun(
      slotIndex,
    );
    if (!mounted) return false;
    if (runtime == null) {
      showTopNotice(context, context.translate('battleBookmarkLoadFailed'));
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
    showTopNotice(
      context,
      context.translate(
        'battleBookmarkLoaded',
        namedArgs: {'slot': '${slotIndex + 1}'},
      ),
    );
    return true;
  }

  Future<bool> _restartCurrentStakeWithConfirm() async {
    final confirmed = await showConfirmDialog(
      context,
      titleBuilder: (dialogContext) =>
          dialogContext.translate('battleRestartBattle'),
      messageBuilder: (dialogContext) =>
          dialogContext.translate('battleRestartBattlePrompt'),
      cancelLabelBuilder: (dialogContext) => dialogContext.translate('cancel'),
      confirmLabelBuilder: (dialogContext) =>
          dialogContext.translate('battleRestartBattle'),
    );
    if (!mounted || !confirmed) return false;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return false;

    await _restartFromStakeSnapshot();
    return true;
  }

  Future<bool> _restartCurrentRun() async {
    if (_battleView.stageIndex >= 9) {
      final warned = await showConfirmDialog(
        context,
        titleBuilder: (dialogContext) =>
            dialogContext.translate('battleRestartEndless'),
        messageBuilder: (dialogContext) =>
            dialogContext.translate('battleRestartEndlessPrompt'),
        cancelLabelBuilder: (dialogContext) =>
            dialogContext.translate('cancel'),
        confirmLabelBuilder: (dialogContext) =>
            dialogContext.translate('battleRestartStation'),
      );
      if (!mounted || !warned) return false;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return false;
    }
    final confirmed = await showConfirmDialog(
      context,
      titleBuilder: (dialogContext) =>
          dialogContext.translate('battleRestartCurrentStation'),
      messageBuilder: (dialogContext) =>
          dialogContext.translate('battleRestartStationPrompt'),
      cancelLabelBuilder: (dialogContext) => dialogContext.translate('cancel'),
      confirmLabelBuilder: (dialogContext) =>
          dialogContext.translate('battleRestartCurrentStation'),
    );
    if (!mounted || !confirmed) return false;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return false;

    await _restartFromStageSnapshot();
    return true;
  }

  Future<bool> _exitToTitleWithConfirm() async {
    final confirmed = await showConfirmDialog(
      context,
      titleBuilder: (dialogContext) =>
          dialogContext.translate('battleExitTitle'),
      messageBuilder: (dialogContext) =>
          dialogContext.translate('battleExitTitlePrompt'),
      cancelLabelBuilder: (dialogContext) => dialogContext.translate('cancel'),
      confirmLabelBuilder: (dialogContext) => dialogContext.translate('exit'),
    );
    if (!mounted || !confirmed) return false;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return false;

    await _goToTitleAfterStoppingBgm();
    return true;
  }

  Future<void> _restartFromStageSnapshot() async {
    _clearGameOverPresentation();
    _resumePresentation();
    _persistRetrySnapshotOnSave = false;
    _gameNotifier.restartCurrentStage();
    FxAmbient.setMood(_battleAmbientMood);
    await _saveActiveRun(scene: ActiveRunScene.battle);
  }

  Future<void> _restartFromStageSnapshotAfterGameOver() async {
    if (_battleView.stageIndex >= 9) {
      final confirmed = await showConfirmDialog(
        context,
        titleBuilder: (dialogContext) =>
            dialogContext.translate('battleRestartEndless'),
        messageBuilder: (dialogContext) =>
            dialogContext.translate('battleRestartEndlessPrompt'),
        cancelLabelBuilder: (dialogContext) =>
            dialogContext.translate('cancel'),
        confirmLabelBuilder: (dialogContext) =>
            dialogContext.translate('battleRestartStation'),
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
    FxAmbient.setMood(_battleAmbientMood);
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
    final summary = _completedRunSummary();
    await _recordRunEndIfNeeded(summary);
    await ActiveRunSaveService.clearActiveRun();
    // 기록과 save 정리가 끝난 뒤에만 승리 장면을 보여 준다. 장면은 상태를 바꾸지 않는다.
    if (_skipsFlowPresentation || !mounted) {
      await _goToTitleAfterStoppingBgm();
      return;
    }
    await _playRunVictory(summary);
    if (!mounted) return;
    _resumePresentation();
    // 승리 장면을 끝까지 본 뒤에만 첫 클리어 리뷰를 요청한다. 결과를 기다리지 않으므로
    // 타이틀 복귀와 입력을 막지 않는다. 디버그 픽스처는 저장 상태를 바꾸지 않는다.
    if (!_isDebugFixtureRun) {
      unawaited(InAppReviewService.maybeRequestReviewAfterFirstClear());
    }
    await SoundManager.fadeOutBgm(GamePresentationTimings.runVictoryBgmFadeOut);
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    context.go(RoutePaths.title);
  }

  Future<void> _playRunVictory(RunEndSummary summary) {
    final done = Completer<void>();
    _mutate(() {
      _runVictoryStats = [
        GameRunVictoryStat(
          labelKey: 'flowVictoryStations',
          value: summary.reachedStageIndex,
        ),
        GameRunVictoryStat(
          labelKey: 'flowVictoryBosses',
          value: summary.defeatedBossCount,
        ),
        GameRunVictoryStat(
          labelKey: 'flowVictoryHands',
          value: summary.playedHandCounts.values.fold(
            0,
            (sum, count) => sum + math.max(0, count),
          ),
        ),
        GameRunVictoryStat(
          labelKey: 'flowVictoryJesters',
          value: summary.boughtJesterIds.length,
        ),
        GameRunVictoryStat(
          labelKey: 'flowVictoryInsight',
          value: RunProgressionService.calculateInsightReward(summary),
        ),
      ];
      _runVictoryDone = done;
    });
    return done.future;
  }

  void _onRunVictoryDone() {
    final done = _runVictoryDone;
    _runVictoryDone = null;
    if (done != null && !done.isCompleted) done.complete();
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
    // 게임오버에서 내려간 전역 pitch를 어느 출구에서든 원래대로 돌린다.
    SoundManager.rampGlobalPitch(1, Duration.zero);
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
    _mutate(() {
      _gameOverSequenceInProgress = true;
      _gameOverFadeVisible = true;
    });
    SoundManager.unlockForWeb();
    GameFeedback.play(GameCue.gameOver);
    // 위험 fade 동안 전체 소리가 테이프 늘어지듯 내려간다. 출구에서 1로 되돌린다.
    SoundManager.rampGlobalPitch(0.5, GamePresentationTimings.gameOverFade);
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
      difficulty: widget.difficulty,
      runModifier: _gameState.runModifier,
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
