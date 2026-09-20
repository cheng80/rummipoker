part of '../game_view.dart';

extension _GameViewPresentationFlow on _GameViewState {
  void _handleLifecyclePause() {
    _dismissBattleTutorial();
    final isShopScene = _gameState.activeRunScene == ActiveRunScene.shop;
    if (!isShopScene &&
        !_optionsDialogOpen &&
        _stageFlowPhase == GameStageFlowPhase.none) {
      _pendingLifecycleOptions = true;
    }
    if (!isShopScene) {
      _pausePresentation();
    }
    SoundManager.pauseBgm(onlyIfCurrent: AssetPaths.bgmMain);
    if (!isShopScene && _stageFlowPhase != GameStageFlowPhase.none) {
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
    _presentationClock.pause();
  }

  void _resumePresentation() {
    if (!_presentationPaused) return;
    _mutate(() {
      _presentationPaused = false;
    });
    _presentationClock.resume();
  }

  Future<void> _waitWhilePresentationPaused() =>
      _presentationClock.waitWhilePaused();

  /// pause 중에는 멈추고, 설정한 정산 속도와 hit-stop을 반영해 기다린다.
  Future<void> _presentationDelay(Duration duration) =>
      _presentationClock.delay(duration);

  void _scheduleBattleTutorialIfNeeded() {
    if (_battleTutorialScheduled ||
        !_shouldAutoStartTutorials ||
        _optionsDialogOpen ||
        _presentationPaused ||
        _gameState.activeRunScene != ActiveRunScene.battle ||
        _stageFlowPhase != GameStageFlowPhase.none ||
        _bossIntroPending ||
        _battleIntroSeenForAnalytics()) {
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
          _bossIntroPending ||
          _battleIntroSeenForAnalytics()) {
        _battleTutorialScheduled = false;
        return;
      }
      await _startBattleTutorial(markSeen: true);
    });
  }

  bool _battleIntroSeenForAnalytics() {
    final seen = TutorialStateService.battleIntroSeen;
    if (seen && !_battleTutorialAlreadySeenLogged) {
      _battleTutorialAlreadySeenLogged = true;
      TutorialStateService.logBattleIntroAlreadySeen();
    }
    return seen;
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
      TutorialStateService.logBattleIntroStart();
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
        TutorialStateService.markBattleIntroSeen(
          outcome: TutorialStateService.skipOutcome,
        );
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
