part of 'game_shop_screen.dart';

const bool _enableMarketTestCrash = bool.fromEnvironment('ENABLE_TEST_CRASH');

extension _GameShopOptionsFlow on _GameShopScreenState {
  Future<bool> _restartCurrentRun() async {
    final confirmed = await showConfirmDialog(
      context,
      titleBuilder: (dialogContext) => widget.isDebugFixtureRun
          ? dialogContext.translate('marketReloadFixture')
          : dialogContext.translate('marketRestartStation'),
      messageBuilder: (dialogContext) => widget.isDebugFixtureRun
          ? dialogContext.translate('marketReloadFixtureConfirm')
          : dialogContext.translate('marketRestartStationConfirm'),
      confirmLabelBuilder: (dialogContext) => widget.isDebugFixtureRun
          ? dialogContext.translate('marketReloadFixture')
          : dialogContext.translate('marketRestartStation'),
    );
    if (!mounted || !confirmed) return false;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return false;

    await widget.onRestartRun();
    return true;
  }

  Future<bool> _exitToTitleWithConfirm() async {
    final confirmed = await showConfirmDialog(
      context,
      titleBuilder: (dialogContext) =>
          dialogContext.translate('marketExitTitle'),
      messageBuilder: (dialogContext) =>
          dialogContext.translate('marketExitConfirm'),
      confirmLabelBuilder: (dialogContext) => dialogContext.translate('exit'),
    );
    if (!mounted || !confirmed) return false;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return false;

    try {
      await _flushStateSave();
      if (!mounted) return false;
      await widget.onExitToTitle();
      return true;
    } catch (_) {
      if (mounted) {
        showBottomNotice(context, context.translate('marketSaveFailed'));
      }
      return false;
    }
  }

  Future<void> _openOptions() async {
    if (_optionsDialogOpen) return;
    _dismissMarketTutorial();
    while (mounted) {
      final activeRunSaveView = widget.readActiveRunSaveView?.call();
      _optionsDialogOpen = true;
      SoundManager.pauseBgm(onlyIfCurrent: AssetPaths.bgmMain);
      if (!mounted) return;
      final action = await showGameFramedDialog<_MarketOptionsCloseAction>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => GameModalCard(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dialogContext.translate('marketOptions'),
                        style: TextStyle(
                          color: GameUiPalette.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    GameIconButtonChip(
                      key: const ValueKey('market-options-close'),
                      onPressed: () => Navigator.of(
                        dialogContext,
                      ).pop(_MarketOptionsCloseAction.resumeGame),
                      icon: Icons.close_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GameDialogSection(
                  title: dialogContext.translate('runSeedLabel'),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              '${widget.runSeed}',
                              style: TextStyle(
                                color: GameUiPalette.textPrimary.withValues(
                                  alpha: 0.92,
                                ),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          GameIconButtonChip(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: '${widget.runSeed}'),
                              );
                              if (!mounted) return;
                              showTopNotice(
                                context,
                                context.translate('marketSeedCopied'),
                              );
                            },
                            icon: Icons.copy_rounded,
                            backgroundColor: GameUiPalette.iconButtonMuted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (activeRunSaveView != null)
                  GameDialogSection(
                    title: 'Run Snapshot',
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dialogContext.activeRunSnapshot(activeRunSaveView),
                          style: TextStyle(
                            color: GameUiPalette.textPrimary.withValues(
                              alpha: 0.92,
                            ),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                GameMenuActionTile(
                  title: dialogContext.translate('runInfoTitle'),
                  subtitle: dialogContext.translate('runInfoActionSubtitle'),
                  icon: Icons.bar_chart_rounded,
                  accentColor: GameUiPalette.actionGoldBright,
                  onTap: () async {
                    Navigator.of(
                      dialogContext,
                    ).pop(_MarketOptionsCloseAction.openRunInfo);
                  },
                ),
                const SizedBox(height: 8),
                GameMenuActionTile(
                  title: dialogContext.translate('tutorialMarketReplayTitle'),
                  subtitle: dialogContext.translate(
                    'tutorialMarketReplaySubtitle',
                  ),
                  icon: Icons.help_outline_rounded,
                  accentColor: GameUiPalette.menuAccentTutorial,
                  onTap: () async {
                    Navigator.of(
                      dialogContext,
                    ).pop(_MarketOptionsCloseAction.openMarketTutorial);
                  },
                ),
                const SizedBox(height: 8),
                GameMenuActionTile(
                  title: dialogContext.translate('marketBookmark'),
                  subtitle: dialogContext.translate('marketBookmarkHelp'),
                  icon: Icons.bookmark_add_rounded,
                  accentColor: GameUiPalette.actionInfoBlue,
                  onTap: () async {
                    final saved = await widget.onBookmarkRun?.call() ?? false;
                    if (!dialogContext.mounted || !saved) return;
                    Navigator.of(
                      dialogContext,
                    ).pop(_MarketOptionsCloseAction.resumeGame);
                  },
                ),
                const SizedBox(height: 8),
                GameMenuActionTile(
                  title: dialogContext.translate('marketLoadBookmark'),
                  subtitle: dialogContext.translate('marketLoadBookmarkHelp'),
                  icon: Icons.bookmarks_rounded,
                  accentColor: GameUiPalette.titleDebugBlue,
                  onTap: () async {
                    final loaded =
                        await widget.onLoadBookmarkRun?.call() ?? false;
                    if (!dialogContext.mounted || !loaded) return;
                    Navigator.of(
                      dialogContext,
                    ).pop(_MarketOptionsCloseAction.resumeGame);
                  },
                ),
                const SizedBox(height: 8),
                GameMenuActionTile(
                  title: dialogContext.translate('settings'),
                  subtitle: dialogContext.translate('marketSettingsHelp'),
                  icon: Icons.settings_rounded,
                  accentColor: GameUiPalette.menuAccentSettings,
                  onTap: () async {
                    Navigator.of(
                      dialogContext,
                    ).pop(_MarketOptionsCloseAction.openSettings);
                  },
                ),
                const SizedBox(height: 8),
                GameMenuActionTile(
                  key: const ValueKey('market-options-restart'),
                  title: widget.isDebugFixtureRun
                      ? dialogContext.translate('marketReloadFixture')
                      : dialogContext.translate('marketRestartStation'),
                  subtitle: dialogContext.translate('marketRestartHelp'),
                  icon: Icons.refresh_rounded,
                  accentColor: GameUiPalette.menuAccentRestart,
                  onTap: () async {
                    final changed = await _restartCurrentRun();
                    if (!dialogContext.mounted || !changed) return;
                    Navigator.of(
                      dialogContext,
                    ).pop(_MarketOptionsCloseAction.resumeGame);
                  },
                ),
                if (_enableMarketTestCrash) ...[
                  const SizedBox(height: 8),
                  GameMenuActionTile(
                    title: dialogContext.translate('marketTestCrash'),
                    subtitle: dialogContext.translate('marketTestCrashHelp'),
                    icon: Icons.bug_report_rounded,
                    accentColor: GameUiPalette.menuAccentExit,
                    onTap: () {
                      FirebaseCrashlytics.instance.crash();
                    },
                  ),
                ],
                const SizedBox(height: 8),
                GameMenuActionTile(
                  key: const ValueKey('market-options-exit'),
                  title: dialogContext.translate('exit'),
                  subtitle: dialogContext.translate('marketExitHelp'),
                  icon: Icons.logout_rounded,
                  accentColor: GameUiPalette.menuAccentExit,
                  onTap: () async {
                    final changed = await _exitToTitleWithConfirm();
                    if (!dialogContext.mounted || !changed) return;
                    Navigator.of(
                      dialogContext,
                    ).pop(_MarketOptionsCloseAction.keepPaused);
                  },
                ),
              ],
            ),
          ),
        ),
      );
      _optionsDialogOpen = false;
      if (!mounted) return;
      switch (action ?? _MarketOptionsCloseAction.resumeGame) {
        case _MarketOptionsCloseAction.resumeGame:
          SoundManager.resumeBgm(onlyIfCurrent: AssetPaths.bgmMain);
          return;
        case _MarketOptionsCloseAction.keepPaused:
          return;
        case _MarketOptionsCloseAction.openSettings:
          SoundManager.beginBgmAutoResumeBlock();
          try {
            await WidgetsBinding.instance.endOfFrame;
            if (!mounted) return;
            await widget.onOpenSettings();
          } finally {
            SoundManager.endBgmAutoResumeBlock();
          }
          if (!mounted) return;
        case _MarketOptionsCloseAction.openRunInfo:
          await showGameRunInfoDialog(
            context: context,
            playedHandCounts:
                widget.readActiveRunSaveView?.call()?.currentPlayedHandCounts ??
                const {},
            handGrowthStates:
                widget.readActiveRunSaveView?.call()?.currentHandGrowthStates ??
                const {},
            addedDeckTiles: _market.addedDeckTiles,
          );
          if (!mounted) return;
          SoundManager.resumeBgm(onlyIfCurrent: AssetPaths.bgmMain);
          return;
        case _MarketOptionsCloseAction.openMarketTutorial:
          SoundManager.resumeBgm(onlyIfCurrent: AssetPaths.bgmMain);
          await _startMarketTutorial(markSeen: false);
          return;
      }
    }
  }

  Future<void> _openLifecycleOptionsAfterResume() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || _optionsDialogOpen) return;
    await _openOptions();
  }
}
