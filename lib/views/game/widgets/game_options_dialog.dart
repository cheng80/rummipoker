import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../resources/asset_paths.dart';
import '../../../resources/sound_manager.dart';
import '../../../services/active_run_save_facade.dart';
import '../../../utils/active_run_translation.dart';
import '../../../utils/app_translation.dart';
import '../../../utils/common_ui.dart';
import '../../../widgets/semantic_text.dart';
import 'game_shared_widgets.dart';
import 'game_ui_palette.dart';

const bool _enableTestCrash = bool.fromEnvironment('ENABLE_TEST_CRASH');

enum GameOptionsCloseAction {
  resumeGame,
  keepPaused,
  openSettings,
  openRunInfo,
  openBattleTutorial,
}

Future<GameOptionsCloseAction> showGameOptionsDialog({
  required BuildContext context,
  required int runSeed,
  RummiActiveRunSaveFacade? activeRunSaveView,
  Future<bool> Function()? onBookmarkRun,
  Future<bool> Function()? onLoadBookmarkRun,
  Future<bool> Function()? onRestartStake,
  required Future<bool> Function() onRestartRun,
  required Future<bool> Function() onExitToTitle,
  required bool isDebugFixtureRun,
}) async {
  SoundManager.unlockForWeb();
  final action = await showGameFramedDialog<GameOptionsCloseAction>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => GameModalCard(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.78,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dialogContext.translate('gameOptions'),
                      style: TextStyle(
                        fontFamily: AssetPaths.fontNexonLv2Gothic,
                        color: GameUiPalette.textPrimary.withValues(
                          alpha: 0.95,
                        ),
                      ),
                    ),
                  ),
                  GameIconButtonChip(
                    tooltip: dialogContext.translate('cancel'),
                    onPressed: () {
                      Navigator.of(
                        dialogContext,
                      ).pop(GameOptionsCloseAction.resumeGame);
                    },
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
                            '$runSeed',
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
                          tooltip: dialogContext.translate('copy'),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: '$runSeed'),
                            );
                            if (!context.mounted || !dialogContext.mounted) {
                              return;
                            }
                            showTopNotice(
                              context,
                              dialogContext.translate('menuSeedCopied'),
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
                  title: dialogContext.translate('menuRunSnapshot'),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemanticText(
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
                  ).pop(GameOptionsCloseAction.openRunInfo);
                },
              ),
              const SizedBox(height: 8),
              GameMenuActionTile(
                title: dialogContext.translate('tutorialBattleReplayTitle'),
                subtitle: dialogContext.translate(
                  'tutorialBattleReplaySubtitle',
                ),
                icon: Icons.help_outline_rounded,
                accentColor: GameUiPalette.menuAccentTutorial,
                onTap: () async {
                  Navigator.of(
                    dialogContext,
                  ).pop(GameOptionsCloseAction.openBattleTutorial);
                },
              ),
              const SizedBox(height: 8),
              GameMenuActionTile(
                title: dialogContext.translate('menuBookmark'),
                subtitle: dialogContext.translate('menuBookmarkDesc'),
                icon: Icons.bookmark_add_rounded,
                accentColor: GameUiPalette.actionInfoBlue,
                onTap: () async {
                  await onBookmarkRun?.call();
                },
              ),
              const SizedBox(height: 8),
              GameMenuActionTile(
                title: dialogContext.translate('menuLoadBookmark'),
                subtitle: dialogContext.translate('menuBookmarkOptionsDesc'),
                icon: Icons.bookmarks_rounded,
                accentColor: GameUiPalette.titleDebugBlue,
                onTap: () async {
                  final loaded = await onLoadBookmarkRun?.call() ?? false;
                  if (!dialogContext.mounted || !loaded) return;
                  Navigator.of(
                    dialogContext,
                  ).pop(GameOptionsCloseAction.resumeGame);
                },
              ),
              const SizedBox(height: 8),
              GameMenuActionTile(
                title: dialogContext.translate('menuRestartBattle'),
                subtitle: dialogContext.translate('menuRestartBattleDesc'),
                icon: Icons.replay_rounded,
                accentColor: GameUiPalette.menuAccentRestart,
                onTap: () async {
                  final changed = await onRestartStake?.call() ?? false;
                  if (!dialogContext.mounted || !changed) return;
                  Navigator.of(
                    dialogContext,
                  ).pop(GameOptionsCloseAction.resumeGame);
                },
              ),
              const SizedBox(height: 8),
              GameMenuActionTile(
                title: isDebugFixtureRun
                    ? dialogContext.translate('menuReloadFixture')
                    : dialogContext.translate('menuRestartStation'),
                subtitle: dialogContext.translate('menuRestartStationDesc'),
                icon: Icons.refresh_rounded,
                accentColor: GameUiPalette.menuAccentRestart,
                onTap: () async {
                  final changed = await onRestartRun();
                  if (!dialogContext.mounted || !changed) return;
                  Navigator.of(
                    dialogContext,
                  ).pop(GameOptionsCloseAction.resumeGame);
                },
              ),
              const SizedBox(height: 8),
              GameMenuActionTile(
                title: dialogContext.translate('settings'),
                subtitle: dialogContext.translate('menuSettingsDesc'),
                icon: Icons.settings_rounded,
                accentColor: GameUiPalette.menuAccentSettings,
                onTap: () async {
                  Navigator.of(
                    dialogContext,
                  ).pop(GameOptionsCloseAction.openSettings);
                },
              ),
              if (_enableTestCrash) ...[
                const SizedBox(height: 8),
                GameMenuActionTile(
                  title: dialogContext.translate('menuTestCrash'),
                  subtitle: dialogContext.translate('menuTestCrashDesc'),
                  icon: Icons.bug_report_rounded,
                  accentColor: GameUiPalette.menuAccentExit,
                  onTap: () {
                    FirebaseCrashlytics.instance.crash();
                  },
                ),
              ],
              const SizedBox(height: 8),
              GameMenuActionTile(
                title: dialogContext.translate('exit'),
                subtitle: dialogContext.translate('menuExitDesc'),
                icon: Icons.logout_rounded,
                accentColor: GameUiPalette.menuAccentExit,
                onTap: () async {
                  final changed = await onExitToTitle();
                  if (!dialogContext.mounted || !changed) return;
                  Navigator.of(
                    dialogContext,
                  ).pop(GameOptionsCloseAction.keepPaused);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return action ?? GameOptionsCloseAction.resumeGame;
}
