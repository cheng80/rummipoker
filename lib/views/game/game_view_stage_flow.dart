part of '../game_view.dart';

extension _GameViewStageFlow on _GameViewState {
  Future<void> _runSettlementSequence({
    required List<ConfirmedLineBreakdown> lines,
    required int totalScore,
    required bool shouldClearAfter,
    required int settlementGoalBaseScore,
    int settlementGoalAppliedScore = 0,
    int index = 0,
  }) async {
    if (!mounted) return;
    if (lines.isEmpty || index >= lines.length) {
      await _waitWhilePresentationPaused();
      if (!mounted) return;
      _gameNotifier.setStageFlow(
        phase: GameStageFlowPhase.none,
        activeSettlementLine: null,
        activeSettlementStep: ScoringPresentationStep.none,
        activeSettlementEffectIndex: null,
        settlementGoalDisplayScore: null,
        settlementBoardSnapshot: const {},
      );
      if (shouldClearAfter) {
        SoundManager.playSfx(AssetPaths.sfxClear);
        await _runStageClearFlow(totalScore);
      } else {
        await _saveActiveRun(scene: ActiveRunScene.battle);
      }
      return;
    }

    final line = lines[index];
    final lineGoalStartScore =
        settlementGoalBaseScore + settlementGoalAppliedScore;
    final lineGoalDisplayScore =
        settlementGoalBaseScore + settlementGoalAppliedScore + line.finalScore;
    final jesterIds = {
      for (final entry in _marketView.ownedEntries) entry.card.id,
    };
    final jesterEffectIndexes = <int>[
      for (var i = 0; i < line.effects.length; i++)
        if (jesterIds.contains(line.effects[i].jesterId)) i,
    ];
    final tileEffectIndexes = <int>[
      for (var i = 0; i < line.effects.length; i++)
        if (_isTileSettlementEffect(line.effects[i].jesterId)) i,
    ];
    final itemEffectIndexes = <int>[
      for (var i = 0; i < line.effects.length; i++)
        if (!jesterIds.contains(line.effects[i].jesterId) &&
            !_isTileSettlementEffect(line.effects[i].jesterId))
          i,
    ];

    await _showSettlementStep(
      totalScore: totalScore,
      line: line,
      step: ScoringPresentationStep.boardLine,
      settlementGoalDisplayScore: lineGoalStartScore,
      bump: true,
      delay: GamePresentationTimings.settlementBoardLineStep,
    );
    if (!mounted) return;
    await _showSettlementStep(
      totalScore: totalScore,
      line: line,
      step: ScoringPresentationStep.handRank,
      settlementGoalDisplayScore: lineGoalStartScore,
      delay: GamePresentationTimings.settlementHandRankStep,
    );
    if (!mounted) return;
    if (line.overlapBonus > 0) {
      await _showSettlementStep(
        totalScore: totalScore,
        line: line,
        step: ScoringPresentationStep.overlap,
        settlementGoalDisplayScore: lineGoalStartScore,
        delay: GamePresentationTimings.settlementOverlapStep,
      );
      if (!mounted) return;
    }
    if (line.constraintPenalties.isNotEmpty) {
      await _showSettlementStep(
        totalScore: totalScore,
        line: line,
        step: ScoringPresentationStep.constraint,
        settlementGoalDisplayScore: lineGoalStartScore,
        bump: true,
        delay: GamePresentationTimings.settlementConstraintStep,
      );
      if (!mounted) return;
    }
    if (jesterEffectIndexes.isNotEmpty) {
      await _showSettlementStep(
        totalScore: totalScore,
        line: line,
        step: ScoringPresentationStep.jester,
        effectIndexes: jesterEffectIndexes,
        settlementGoalDisplayScore: lineGoalStartScore,
        bump: true,
        delay: GamePresentationTimings.settlementEffectStep,
      );
      if (!mounted) return;
    }
    if (tileEffectIndexes.isNotEmpty) {
      await _showSettlementStep(
        totalScore: totalScore,
        line: line,
        step: ScoringPresentationStep.tile,
        effectIndexes: tileEffectIndexes,
        settlementGoalDisplayScore: lineGoalStartScore,
        bump: true,
        delay: GamePresentationTimings.settlementEffectStep,
      );
      if (!mounted) return;
    }
    if (itemEffectIndexes.isNotEmpty) {
      await _showSettlementStep(
        totalScore: totalScore,
        line: line,
        step: ScoringPresentationStep.item,
        effectIndexes: itemEffectIndexes,
        settlementGoalDisplayScore: lineGoalStartScore,
        bump: true,
        delay: GamePresentationTimings.settlementEffectStep,
      );
      if (!mounted) return;
    }
    await _showSettlementStep(
      totalScore: totalScore,
      line: line,
      step: ScoringPresentationStep.finalScore,
      settlementGoalDisplayScore: lineGoalDisplayScore,
      delay: GamePresentationTimings.settlementFinalScoreStep,
    );
    if (!mounted) return;

    await _presentationDelay(GamePresentationTimings.settlementLineTail);
    if (!mounted) return;
    await _runSettlementSequence(
      lines: lines,
      totalScore: totalScore,
      shouldClearAfter: shouldClearAfter,
      settlementGoalBaseScore: settlementGoalBaseScore,
      settlementGoalAppliedScore: settlementGoalAppliedScore + line.finalScore,
      index: index + 1,
    );
  }

  Future<void> _showSettlementStep({
    required int totalScore,
    required ConfirmedLineBreakdown line,
    required ScoringPresentationStep step,
    required Duration delay,
    int? effectIndex,
    List<int> effectIndexes = const [],
    Object? settlementGoalDisplayScore = GameSessionState.unsetValue,
    bool bump = false,
  }) async {
    await _waitWhilePresentationPaused();
    if (!mounted) return;
    SoundManager.playSfx(AssetPaths.sfxCollect);
    _gameNotifier.setStageFlow(
      phase: GameStageFlowPhase.confirmSettlement,
      stageScoreAdded: totalScore,
      activeSettlementLine: line,
      activeSettlementStep: step,
      activeSettlementEffectIndex: effectIndex,
      activeSettlementEffectIndexes: effectIndexes,
      settlementGoalDisplayScore: settlementGoalDisplayScore,
      bumpSettlementSequence: bump,
    );
    await _presentationDelay(delay);
  }

  bool _isTileSettlementEffect(String effectId) {
    return effectId.startsWith('tile:') ||
        effectId.startsWith('tile_edition:');
  }

  Future<void> _runStageClearFlow(int scoreAdded) async {
    final canContinue = await _runStageClearPresentation(scoreAdded);
    if (!canContinue) return;
    if (widget.debugCompleteRunOnClear) {
      await _completeRunAndReturnToTitle();
      return;
    }
    final breakdown = _gameNotifier.prepareSettlementAndCashOut(
      itemCatalog: _itemCatalog,
    );
    await _runSettlementToNextStationLoop(breakdown);
  }

  Future<void> _debugForceBlindClear() async {
    if (!AppConfig.showDebugFixtures || _isUiLocked) return;
    final scoreAdded = _gameNotifier.debugForceBlindClear();
    await _runStageClearFlow(scoreAdded);
  }

  Future<void> _debugForceBossClearToNextBlindSelect() async {
    if (!AppConfig.showDebugFixtures || _isUiLocked) return;
    final scoreAdded = _gameNotifier.debugForceBlindClear(
      overrideTier: BlindTier.boss,
    );
    final canContinue = await _runStageClearPresentation(scoreAdded);
    if (!canContinue) return;
    final breakdown = _gameNotifier.prepareSettlementAndCashOut(
      itemCatalog: _itemCatalog,
    );
    await _runSettlementToNextStationLoop(
      breakdown,
      autoEnterMarketOnLoad: true,
      autoAdvanceMarketOnLoad: true,
    );
  }

  Future<bool> _runStageClearPresentation(int scoreAdded) async {
    if (!mounted) return false;
    _gameNotifier.setStageFlow(
      phase: GameStageFlowPhase.cleared,
      stageScoreAdded: scoreAdded,
      activeSettlementLine: null,
    );

    await _presentationDelay(GamePresentationTimings.stageClearClearedHold);
    if (!mounted) return false;
    _gameNotifier.setStageFlow(phase: GameStageFlowPhase.settlement);

    await _presentationDelay(GamePresentationTimings.stageClearSettlementHold);
    return mounted;
  }

  Future<GameCashOutAction?> _showCashOutSheet(
    RummiCashOutBreakdown breakdown, {
    bool autoEnterMarketOnLoad = false,
    bool completesRun = false,
  }) {
    final settlementView = RummiSettlementRuntimeFacade.fromCashOut(
      breakdown: breakdown,
      currentGold: _marketView.gold,
    );
    final insightReward = completesRun
        ? RunProgressionService.calculateInsightReward(_completedRunSummary())
        : 0;
    final showsChallengeCarryoverNotice =
        completesRun && widget.difficulty == NewRunDifficulty.standard;
    return showGeneralDialog<GameCashOutAction>(
      context: context,
      barrierLabel: '정산 결과',
      barrierDismissible: false,
      barrierColor: kGameModalBarrierColor,
      routeSettings: const RouteSettings(name: '정산 결과'),
      transitionDuration: Duration.zero,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return PhoneFrame(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Semantics(
              container: true,
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label: '정산 결과',
              child: GameCashOutSheet(
                settlement: settlementView,
                autoEnterMarketOnLoad:
                    !completesRun &&
                    (autoEnterMarketOnLoad || widget.autoEnterMarketOnCashOut),
                completesRun: completesRun,
                insightReward: insightReward,
                showsChallengeCarryoverNotice: showsChallengeCarryoverNotice,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _runAutoCashOutLoopOnLoad() async {
    final breakdown = _gameNotifier.prepareSettlementAndCashOut(
      itemCatalog: _itemCatalog,
    );
    await _runSettlementToNextStationLoop(breakdown);
  }

  Future<void> _runSettlementToNextStationLoop(
    RummiCashOutBreakdown breakdown, {
    bool autoEnterMarketOnLoad = false,
    bool autoAdvanceMarketOnLoad = false,
  }) async {
    _gameNotifier.setStageFlow(phase: GameStageFlowPhase.none);
    await _saveActiveRun(scene: ActiveRunScene.battle);

    final completesRun = _isFinalBossCleared;
    final cashOutAction = await _showCashOutSheet(
      breakdown,
      autoEnterMarketOnLoad: autoEnterMarketOnLoad,
      completesRun: completesRun,
    );
    if (cashOutAction == GameCashOutAction.completeRun) {
      await _completeRunAndReturnToTitle();
      return;
    }
    if (cashOutAction == GameCashOutAction.continueEndless) {
      await _claimRunCompletionRewardIfNeeded();
    }
    if (!mounted ||
        cashOutAction != GameCashOutAction.enterMarket &&
            cashOutAction != GameCashOutAction.continueEndless) {
      return;
    }

    _gameNotifier.enterMarketAfterCashOut(itemCatalog: _itemCatalog);
    await _saveActiveRun();
    if (!mounted) return;
    await _playSettlementToMarketTransition(breakdown);
    if (!mounted) return;

    final nextStage = await _showShopScreen(
      autoAdvanceOnLoad: autoAdvanceMarketOnLoad,
    );
    if (!mounted || nextStage != true) return;

    final blindSelectRuntime = _gameNotifier
        .prepareNextStationBlindSelectRuntime(difficulty: widget.difficulty);
    await ActiveRunSaveService.saveRuntimeState(blindSelectRuntime);
    if (!mounted) return;
    await _playNextStationTransition();
    if (!mounted) return;
    context.go(
      '${RoutePaths.blindSelect}?difficulty=${widget.difficulty.name}',
      extra: blindSelectRuntime,
    );
  }

  bool get _isFinalBossCleared {
    return _battleView.stageIndex == _GameViewState._finalStationIndex &&
        _battleView.currentBlindTierIndex >= BlindTier.boss.index;
  }

  Future<void> _claimRunCompletionRewardIfNeeded() async {
    final runProgress = _gameState.runProgress;
    if (runProgress == null || runProgress.runCompletionRewardClaimed) {
      return;
    }
    await _recordRunEndIfNeeded(_completedRunSummary());
    runProgress.runCompletionRewardClaimed = true;
    _gameNotifier.markDirty();
    await _saveActiveRun(scene: ActiveRunScene.battle);
  }

  RunEndSummary _completedRunSummary() {
    return RunEndSummary(
      result: RunEndResult.completed,
      difficulty: widget.difficulty,
      reachedStageIndex: _battleView.stageIndex,
      defeatedBossCount: _defeatedBossCountForRunEnd(completed: true),
      seenMarketJesterIds: _runProgressCollection.seenMarketJesterIds,
      seenMarketItemIds: _runProgressCollection.seenMarketItemIds,
      boughtJesterIds: _runProgressCollection.boughtJesterIds,
      boughtItemIds: _runProgressCollection.boughtItemIds,
      seenBossModifierIds: _runProgressCollection.seenBossModifierIds,
      clearedStationKeys: _runProgressCollection.clearedStationKeys,
    );
  }

  RummiRunProgress get _runProgressCollection {
    return _gameState.runProgress ?? RummiRunProgress();
  }

  Future<void> _playSettlementToMarketTransition(
    RummiCashOutBreakdown breakdown,
  ) async {
    if (!mounted) return;
    _mutate(() => _settlementToMarketTransition = breakdown);
    await _presentationDelay(
      GamePresentationTimings.stageTransitionOverlayHold,
    );
    if (!mounted) return;
    _mutate(() => _settlementToMarketTransition = null);
  }

  Future<void> _goToNextStationBlindSelect() async {
    final blindSelectRuntime = _gameNotifier
        .prepareNextStationBlindSelectRuntime(difficulty: widget.difficulty);
    await ActiveRunSaveService.saveRuntimeState(blindSelectRuntime);
    if (!mounted) return;
    await _playNextStationTransition();
    if (!mounted) return;
    context.go(
      '${RoutePaths.blindSelect}?difficulty=${widget.difficulty.name}',
      extra: blindSelectRuntime,
    );
  }

  Future<void> _playNextStationTransition() async {
    if (!mounted) return;
    _mutate(() => _nextStationTransitionVisible = true);
    await _presentationDelay(
      GamePresentationTimings.stageTransitionOverlayHold,
    );
    if (!mounted) return;
    _mutate(() => _nextStationTransitionVisible = false);
  }

  Future<bool?> _showShopScreen({bool autoAdvanceOnLoad = false}) {
    _removeBattleTutorialForPause();
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => GameShopScreen(
          runSeed: widget.runSeed,
          readMarketView: _readMarketViewWithItemOffers,
          onReroll: () =>
              _gameNotifier.rerollShopFromState(itemCatalog: _itemCatalog),
          onRerollItemOffers: (placement) =>
              _gameNotifier.rerollItemOffersFromState(
                itemCatalog: _itemCatalog,
                placement: placement,
              ),
          onRerollTileOffers: () => _gameNotifier.rerollTileOffersFromState(
            itemCatalog: _itemCatalog,
          ),
          onBuyOffer: (offer) =>
              _gameNotifier.buyShopOfferView(offer, itemCatalog: _itemCatalog),
          onBuyItemOffer: (offer) =>
              _gameNotifier.buyItemOffer(offer, itemCatalog: _itemCatalog),
          onBuyTileOffer: _gameNotifier.buyTileOffer,
          onUseMarketItem: _gameNotifier.useMarketItem,
          onSellOwnedJester: (index) =>
              _gameNotifier.sellOwnedJester(index, itemCatalog: _itemCatalog),
          onSellMarketItem: _gameNotifier.sellMarketItem,
          autoStartTutorials: _shouldAutoStartTutorials,
          onSlotUnlockPresentationShown: () async {
            _gameNotifier.markSlotUnlockPresentationShown();
            await _saveActiveRun(scene: ActiveRunScene.shop);
          },
          onStateChanged: _saveActiveRun,
          readActiveRunSaveView: () => ref
              .read(gameSessionNotifierProvider(_gameArgs))
              .activeRunSaveView,
          onOpenSettings: () async {
            await context.push(RoutePaths.setting);
          },
          onExitToTitle: _goToTitleAfterStoppingBgm,
          onRestartRun: _restartCurrentRun,
          isDebugFixtureRun: _isDebugFixtureRun,
          initialItemShopTab: widget.debugStartItemShop,
          autoAdvanceOnLoad:
              autoAdvanceOnLoad || widget.autoAdvanceMarketOnLoad,
        ),
      ),
    );
  }
}
