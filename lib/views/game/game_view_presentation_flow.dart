part of '../game_view.dart';

extension _GameViewPresentationFlow on _GameViewState {
  void _handleLifecyclePause() {
    _dismissBattleTutorial();
    final isShopScene = _gameState.activeRunScene == ActiveRunScene.shop;
    if (!isShopScene) {
      _pausePresentation();
    }
    SoundManager.pauseBgm(onlyIfCurrent: AssetPaths.bgmMain);
    if (!isShopScene && !_optionsDialogOpen) {
      _pendingLifecycleOptions = true;
    } else if (!isShopScene && _stageFlowPhase != GameStageFlowPhase.none) {
      _pausedLifecycleDuringStageFlow = true;
    }
    _saveActiveRun();
  }

  void _pausePresentation() {
    if (_presentationPaused) return;
    _removeBattleTutorialForPause();
    _mutate(() {
      _presentationPaused = true;
    });
    _presentationResumeCompleter ??= Completer<void>();
  }

  void _resumePresentation() {
    if (!_presentationPaused) return;
    _mutate(() {
      _presentationPaused = false;
    });
    final completer = _presentationResumeCompleter;
    _presentationResumeCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  Future<void> _waitWhilePresentationPaused() async {
    while (mounted && _presentationPaused) {
      final completer = _presentationResumeCompleter;
      if (completer == null) return;
      await completer.future;
    }
  }

  Future<void> _presentationDelay(Duration duration) async {
    var remaining = duration;
    const tick = GamePresentationTimings.presentationPauseTick;
    while (mounted && remaining > Duration.zero) {
      await _waitWhilePresentationPaused();
      if (!mounted) return;
      final chunk = remaining < tick ? remaining : tick;
      await Future<void>.delayed(chunk);
      if (!_presentationPaused) {
        remaining -= chunk;
      }
    }
  }

  void _scheduleBattleTutorialIfNeeded() {
    if (_battleTutorialScheduled ||
        !_shouldAutoStartTutorials ||
        _optionsDialogOpen ||
        _presentationPaused ||
        _gameState.activeRunScene != ActiveRunScene.battle ||
        _stageFlowPhase != GameStageFlowPhase.none ||
        TutorialStateService.battleIntroSeen) {
      return;
    }
    _battleTutorialScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _waitForBattleTutorialLayout();
      if (!mounted ||
          _optionsDialogOpen ||
          !_shouldAutoStartTutorials ||
          _presentationPaused ||
          _gameState.activeRunScene != ActiveRunScene.battle ||
          _stageFlowPhase != GameStageFlowPhase.none ||
          TutorialStateService.battleIntroSeen) {
        _battleTutorialScheduled = false;
        return;
      }
      await _startBattleTutorial(markSeen: true);
    });
  }

  Future<void> _waitForBattleTutorialLayout() async {
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(GamePresentationTimings.scoringPreviewFadeIn);
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _startBattleTutorial({
    required bool markSeen,
    int initialFocus = 0,
  }) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (_presentationPaused ||
        _optionsDialogOpen ||
        _gameState.activeRunScene != ActiveRunScene.battle) {
      _battleTutorialScheduled = false;
      _battleTutorialShouldMarkSeenOnFinish = false;
      _battleTutorialFocusIndex = 0;
      return;
    }
    _battleTutorialFocusIndex = initialFocus.clamp(0, 3);
    if (markSeen) {
      _battleTutorialShouldMarkSeenOnFinish = true;
    } else {
      _battleTutorialShouldMarkSeenOnFinish = false;
    }
    _battleTutorialCoachMark?.removeOverlayEntry();
    _battleTutorialCoachMark = TutorialCoachMark(
      targets: buildGameTutorialTargets(
        context: context,
        steps: [
          GameTutorialStep(
            targetKey: _battleBoardTutorialKey,
            title: context.tr('tutorialBattleBoardTitle'),
            description: context.tr('tutorialBattleBoardDesc'),
            align: ContentAlign.bottom,
          ),
          GameTutorialStep(
            targetKey: _battlePreviewTutorialKey,
            title: context.tr('tutorialBattlePreviewTitle'),
            description: context.tr('tutorialBattlePreviewDesc'),
            align: ContentAlign.top,
          ),
          GameTutorialStep(
            targetKey: _battleActionsTutorialKey,
            title: context.tr('tutorialBattleActionsTitle'),
            description: context.tr('tutorialBattleActionsDesc'),
            align: ContentAlign.top,
          ),
          GameTutorialStep(
            targetKey: _battleHandTutorialKey,
            title: context.tr('tutorialBattleHandTitle'),
            description: context.tr('tutorialBattleHandDesc'),
            align: ContentAlign.top,
          ),
        ],
        nextLabel: context.tr('tutorialNext'),
        doneLabel: context.tr('tutorialDone'),
        skipLabel: context.tr('tutorialSkip'),
        onStepAdvanced: (index) {
          _battleTutorialFocusIndex = index.clamp(0, 3);
        },
      ),
      colorShadow: GameUiPalette.tutorialShadow,
      opacityShadow: 0.62,
      pulseEnable: false,
      paddingFocus: 6,
      alignSkip: Alignment.topRight,
      skipWidget: buildGameTutorialSkipButton(context.tr('tutorialSkip')),
      initialFocus: _battleTutorialFocusIndex,
      onFinish: _markBattleTutorialSeenOnFinish,
      onSkip: () {
        TutorialStateService.markBattleIntroSeen();
        _battleTutorialShouldMarkSeenOnFinish = false;
        _battleTutorialScheduled = false;
        _battleTutorialFocusIndex = 0;
        return true;
      },
    )..show(context: context);
  }

  void _dismissBattleTutorial() {
    if (!(_battleTutorialCoachMark?.isShowing ?? false)) return;
    _battleTutorialCoachMark?.removeOverlayEntry();
    _battleTutorialScheduled = false;
    _battleTutorialShouldMarkSeenOnFinish = false;
    _battleTutorialFocusIndex = 0;
  }

  void _removeBattleTutorialForPause() {
    if (_battleTutorialCoachMark?.isShowing ?? false) {
      _battleTutorialCoachMark?.removeOverlayEntry();
    }
    _battleTutorialScheduled = false;
    _battleTutorialShouldMarkSeenOnFinish = false;
    _battleTutorialFocusIndex = 0;
  }

  void _markBattleTutorialSeenOnFinish() {
    _battleTutorialFocusIndex = 0;
    if (!_battleTutorialShouldMarkSeenOnFinish) return;
    _battleTutorialShouldMarkSeenOnFinish = false;
    TutorialStateService.markBattleIntroSeen();
  }

  void _showItemEffectFeedback({
    required String title,
    required String detail,
    String? sourceLabel,
    bool passive = false,
    bool fateTransform = false,
  }) {
    if (!mounted) return;
    final tick = _itemEffectFeedbackTick + 1;
    _mutate(() {
      _itemEffectFeedbackTick = tick;
      _itemEffectFeedback = _ItemEffectFeedback(
        title: title,
        detail: detail,
        sourceLabel: sourceLabel,
        passive: passive,
        fateTransform: fateTransform,
      );
    });
    unawaited(
      Future<void>.delayed(GamePresentationTimings.itemEffectFeedback, () {
        if (!mounted || _itemEffectFeedbackTick != tick) return;
        _mutate(() => _itemEffectFeedback = null);
      }),
    );
  }
}
