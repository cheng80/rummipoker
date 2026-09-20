part of '../game_view.dart';

extension _GameViewDialogRoutes on _GameViewState {
  Future<void> _openShopForTest() async {
    if (_isUiLocked) return;
    _gameNotifier.openShopForTest(
      preferredOfferIds: _GameViewState._shopInspectOfferIds,
    );
    await _saveActiveRun(scene: ActiveRunScene.shop);
    if (!mounted) return;
    _showSnack(
      context.translate(
        'battleDebugOffers',
        namedArgs: {'count': '${_GameViewState._shopInspectOfferIds.length}'},
      ),
    );
    await _showShopScreen();
    if (!mounted) return;
    await _saveActiveRun(scene: ActiveRunScene.battle);
    _gameNotifier.markDirty();
  }

  Future<void> _openGameOptions({bool allowDuringStageFlow = false}) async {
    if ((!allowDuringStageFlow && _stageFlowPhase != GameStageFlowPhase.none) ||
        _optionsDialogOpen) {
      return;
    }
    _dismissBattleTutorial();
    while (mounted) {
      _optionsDialogOpen = true;
      SoundManager.pauseBgm(onlyIfCurrent: AssetPaths.bgmMain);
      if (!mounted) return;
      late final GameOptionsCloseAction action;
      SoundManager.beginBgmAutoResumeBlock();
      try {
        action = await showGameOptionsDialog(
          context: context,
          runSeed: widget.runSeed,
          activeRunSaveView: _gameState.activeRunSaveView,
          onBookmarkRun: _bookmarkCurrentRun,
          onLoadBookmarkRun: _loadBookmarkRunFromOptions,
          onRestartStake: _restartCurrentStakeWithConfirm,
          onRestartRun: _restartCurrentRun,
          onExitToTitle: _exitToTitleWithConfirm,
          isDebugFixtureRun: _isDebugFixtureRun,
        );
      } finally {
        SoundManager.endBgmAutoResumeBlock();
        _optionsDialogOpen = false;
      }
      if (!mounted) return;
      switch (action) {
        case GameOptionsCloseAction.resumeGame:
          _resumePresentation();
          SoundManager.resumeBgmFromUserGesture(
            onlyIfCurrent: AssetPaths.bgmMain,
          );
          return;
        case GameOptionsCloseAction.keepPaused:
          return;
        case GameOptionsCloseAction.openSettings:
          SoundManager.beginBgmAutoResumeBlock();
          try {
            SoundManager.playSfx(AssetPaths.sfxBtnSnd);
            await WidgetsBinding.instance.endOfFrame;
            if (!mounted) return;
            await context.push(RoutePaths.setting);
          } finally {
            SoundManager.endBgmAutoResumeBlock();
          }
          if (!mounted ||
              (!allowDuringStageFlow &&
                  _stageFlowPhase != GameStageFlowPhase.none)) {
            return;
          }
        case GameOptionsCloseAction.openRunInfo:
          await _openRunInfo();
          if (!mounted) return;
          _resumePresentation();
          SoundManager.resumeBgm(onlyIfCurrent: AssetPaths.bgmMain);
          return;
        case GameOptionsCloseAction.openBattleTutorial:
          _resumePresentation();
          SoundManager.resumeBgm(onlyIfCurrent: AssetPaths.bgmMain);
          await _startBattleTutorial(markSeen: false);
          return;
      }
    }
  }

  Future<void> _openLifecycleOptionsAfterResume() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted ||
        _optionsDialogOpen ||
        _gameState.activeRunScene == ActiveRunScene.shop) {
      return;
    }
    await _openGameOptions(allowDuringStageFlow: true);
  }

  Future<void> _openRunInfo() async {
    if (_optionsDialogOpen) return;
    await showGameRunInfoDialog(
      context: context,
      playedHandCounts:
          _gameState.activeRunSaveView?.currentPlayedHandCounts ?? const {},
      handGrowthStates:
          _gameState.runProgress?.snapshotHandGrowthStates() ?? const {},
      addedDeckTiles: _gameState.runProgress?.addedDeckTiles ?? const [],
    );
  }

  void _showDebugRunInfoOnLoadIfNeeded() {
    if (!AppConfig.showDebugFixtures ||
        !widget.debugOpenRunInfoOnLoad ||
        !_isDebugFixtureRun) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _openRunInfo();
    });
  }

  Future<void> _openDebugBottomSheet(BuildContext context) async {
    if (!AppConfig.showDebugFixtures ||
        _stageFlowPhase != GameStageFlowPhase.none) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: GameUiPalette.transparent,
      isScrollControlled: true,
      barrierLabel: context.translate('battleDebugSettings'),
      routeSettings: const RouteSettings(name: 'debug-settings'),
      builder: (sheetContext) {
        var handSize = _stationView.resources.maxHandSize;
        var debugGold = _gameState.runProgress?.gold ?? 0;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Semantics(
              container: true,
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label: context.translate('battleDebugSettings'),
              child: SafeArea(
                top: false,
                child: FractionallySizedBox(
                  heightFactor: 0.72,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: GameModalCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'DEBUG',
                                  style: TextStyle(
                                    color: GameUiPalette.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              GameIconButtonChip(
                                tooltip: context.translate('battleClose'),
                                onPressed: () =>
                                    Navigator.of(sheetContext).pop(),
                                icon: Icons.close_rounded,
                                size: 34,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              SizedBox(
                                width: 88,
                                child: GameActionButton(
                                  label: 'G -10',
                                  background: GameUiPalette.disabledControl,
                                  onPressed: debugGold <= 0
                                      ? null
                                      : () {
                                          _adjustDebugGold(-10);
                                          setModalState(() {
                                            debugGold =
                                                _gameState.runProgress?.gold ??
                                                0;
                                          });
                                        },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: GameUiPalette.textPrimary.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: GameUiPalette.textPrimary
                                          .withValues(alpha: 0.12),
                                    ),
                                  ),
                                  child: Text(
                                    'GOLD $debugGold',
                                    style: const TextStyle(
                                      color: GameUiPalette.actionGoldBright,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 88,
                                child: GameActionButton(
                                  label: 'G +10',
                                  background: GameUiPalette.actionGold,
                                  foreground: GameUiPalette.ink,
                                  onPressed: () {
                                    _adjustDebugGold(10);
                                    setModalState(() {
                                      debugGold =
                                          _gameState.runProgress?.gold ?? 0;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              SizedBox(
                                width: 108,
                                child: GameActionButton(
                                  label: 'MARKET',
                                  background: GameUiPalette.actionGold,
                                  foreground: GameUiPalette.ink,
                                  onPressed: () async {
                                    Navigator.of(sheetContext).pop();
                                    await WidgetsBinding.instance.endOfFrame;
                                    await _openShopForTest();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                    width: 228,
                                    height: 40,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: GameUiPalette.textPrimary
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: GameUiPalette.textPrimary
                                              .withValues(alpha: 0.12),
                                        ),
                                      ),
                                      child: GameDebugHandSizeSegment(
                                        value: handSize,
                                        onChanged: (value) {
                                          setModalState(() => handSize = value);
                                          _setDebugMaxHandSize(value);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  GameMenuActionTile(
                                    title: context.translate(
                                      'battleDebugClear',
                                    ),
                                    subtitle: context.translate(
                                      'battleDebugClearDescription',
                                    ),
                                    icon: Icons.bug_report_rounded,
                                    accentColor:
                                        GameUiPalette.menuAccentRestart,
                                    onTap: () async {
                                      Navigator.of(sheetContext).pop();
                                      await WidgetsBinding.instance.endOfFrame;
                                      await _debugForceBlindClear();
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  GameMenuActionTile(
                                    title: context.translate(
                                      'battleDebugNextStation',
                                    ),
                                    subtitle: context.translate(
                                      'battleDebugNextStationDescription',
                                    ),
                                    icon: Icons.skip_next_rounded,
                                    accentColor:
                                        GameUiPalette.menuAccentTutorial,
                                    onTap: () async {
                                      Navigator.of(sheetContext).pop();
                                      await WidgetsBinding.instance.endOfFrame;
                                      await _debugForceBossClearToNextBlindSelect();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
