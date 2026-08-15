import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../resources/asset_paths.dart';
import '../../../resources/sound_manager.dart';
import '../../../services/active_run_save_facade.dart';
import '../../../utils/common_ui.dart';
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
  SoundManager.playSfx(AssetPaths.sfxBtnSnd);
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
                      context.tr('gameOptions'),
                      style: TextStyle(
                        fontFamily: AssetPaths.fontNexonLv2Gothic,
                        color: GameUiPalette.textPrimary.withValues(
                          alpha: 0.95,
                        ),
                      ),
                    ),
                  ),
                  GameIconButtonChip(
                    tooltip: context.tr('cancel'),
                    onPressed: () {
                      SoundManager.playSfx(AssetPaths.sfxBtnSnd);
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
                title: context.tr('runSeedLabel'),
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
                          tooltip: context.tr('copy'),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: '$runSeed'),
                            );
                            if (!context.mounted) return;
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
                  ).pop(GameOptionsCloseAction.openRunInfo);
                },
              ),
              const SizedBox(height: 8),
              GameMenuActionTile(
                title: context.tr('tutorialBattleReplayTitle'),
                subtitle: context.tr('tutorialBattleReplaySubtitle'),
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
                title: '북마크하기',
                subtitle: '현재 진행 상태를 북마크 슬롯 3개 중 하나에 저장합니다.',
                icon: Icons.bookmark_add_rounded,
                accentColor: GameUiPalette.actionInfoBlue,
                onTap: () async {
                  await onBookmarkRun?.call();
                },
              ),
              const SizedBox(height: 8),
              GameMenuActionTile(
                title: '북마크 불러오기',
                subtitle: '저장된 북마크를 불러오고 이어하기 데이터를 덮어씁니다.',
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
                title: '현재 전투 재시작',
                subtitle: '현재 전투 시작 시점으로만 되돌립니다.',
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
                title: isDebugFixtureRun ? '디버그 픽스처 재로드' : '현재 Station 재시작',
                subtitle: '현재 진행을 유지한 채 이번 Station 시작 시점으로 되돌립니다.',
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
                title: context.tr('settings'),
                subtitle: '설정 화면을 열고 복귀 후 현재 메뉴를 다시 엽니다.',
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
                  title: 'Crashlytics 테스트 크래시',
                  subtitle: 'Firebase Console 수신 확인용입니다.',
                  icon: Icons.bug_report_rounded,
                  accentColor: GameUiPalette.menuAccentExit,
                  onTap: () {
                    FirebaseCrashlytics.instance.crash();
                  },
                ),
              ],
              const SizedBox(height: 8),
              GameMenuActionTile(
                title: context.tr('exit'),
                subtitle: '현재 런을 종료하고 타이틀 화면으로 돌아갑니다.',
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

String _activeRunSummaryLabel(RummiActiveRunSaveFacade summary) {
  return summary.snapshotSummaryLabel();
}
