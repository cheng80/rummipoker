part of '../game_view.dart';

extension _GameViewDialogRoutes on _GameViewState {
  Future<void> _openShopForTest() async {
    if (_isUiLocked) return;
    _gameNotifier.openShopForTest(
      preferredOfferIds: _GameViewState._shopInspectOfferIds,
    );
    await _saveActiveRun(scene: ActiveRunScene.shop);
    _showSnack(
      '검사용 Market 오퍼 ${_GameViewState._shopInspectOfferIds.length}장 표시',
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
      final action = await showGameOptionsDialog(
        context: context,
        runSeed: widget.runSeed,
        activeRunSaveView: _gameState.activeRunSaveView,
        onRestartRun: _restartCurrentRun,
        onExitToTitle: _exitToTitleWithConfirm,
        isDebugFixtureRun: _isDebugFixtureRun,
      );
      _optionsDialogOpen = false;
      if (!mounted) return;
      switch (action) {
        case GameOptionsCloseAction.resumeGame:
          _resumePresentation();
          SoundManager.resumeBgm(onlyIfCurrent: AssetPaths.bgmMain);
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
      barrierLabel: '디버그 설정',
      routeSettings: const RouteSettings(name: '디버그 설정'),
      builder: (sheetContext) {
        var handSize = _stationView.resources.maxHandSize;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Semantics(
              container: true,
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label: '디버그 설정',
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
                                tooltip: '닫기',
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
                                    title: '현재 구간 즉시 클리어',
                                    subtitle: '현재 선택된 구간을 즉시 정산 완료 상태로 넘깁니다.',
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
                                    title: 'Boss 클리어 후 다음 Station Select',
                                    subtitle: '다음 Station Select로 바로 이행합니다.',
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
