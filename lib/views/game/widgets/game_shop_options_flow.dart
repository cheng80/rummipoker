part of 'game_shop_screen.dart';

extension _GameShopOptionsFlow on _GameShopScreenState {
  Future<bool> _restartCurrentRun() async {
    final confirmed = await showConfirmDialog(
      context,
      title: widget.isDebugFixtureRun ? '디버그 픽스처 재로드' : '현재 Station 재시작',
      message: widget.isDebugFixtureRun
          ? '디버그 픽스처 시작 상태로 다시 불러올까요?\n현재 화면에서 만든 변경 사항은 취소됩니다.'
          : '현재 Station 시작 시점으로 되돌릴까요?\n이 Station에서 얻은 골드, 제스터, 진행 상태는 취소됩니다.',
      cancelLabel: '취소',
      confirmLabel: widget.isDebugFixtureRun ? '디버그 픽스처 재로드' : '현재 Station 재시작',
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
      title: '메인 메뉴로 나가기',
      message: '현재 진행을 멈추고 메인 메뉴로 돌아갈까요?\n이어하기로 다시 복원할 수 있습니다.',
      cancelLabel: '취소',
      confirmLabel: '나가기',
    );
    if (!mounted || !confirmed) return false;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return false;

    await widget.onExitToTitle();
    return true;
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Market 옵션',
                      style: TextStyle(
                        color: GameUiPalette.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  GameIconButtonChip(
                    onPressed: () => Navigator.of(
                      dialogContext,
                    ).pop(_MarketOptionsCloseAction.resumeGame),
                    icon: Icons.close_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GameDialogSection(
                title: 'Run Seed',
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
                            showTopNotice(context, '시드 번호를 복사했습니다.');
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
                        _activeRunSummaryLabel(activeRunSaveView),
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
                title: context.tr('runInfoTitle'),
                subtitle: context.tr('runInfoActionSubtitle'),
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
                title: context.tr('tutorialMarketReplayTitle'),
                subtitle: context.tr('tutorialMarketReplaySubtitle'),
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
                title: context.tr('settings'),
                subtitle: '설정 화면을 열고, Market으로 다시 돌아옵니다.',
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
                title: widget.isDebugFixtureRun
                    ? '디버그 픽스처 재로드'
                    : '현재 Station 재시작',
                subtitle: '현재 Station 시작 시점으로 되돌립니다.',
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
              const SizedBox(height: 8),
              GameMenuActionTile(
                title: context.tr('exit'),
                subtitle: '현재 진행을 멈추고 메인 메뉴로 돌아갑니다.',
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
}
