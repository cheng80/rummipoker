import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../resources/asset_paths.dart';
import '../../../resources/sound_manager.dart';
import '../../../services/active_run_save_facade.dart';
import '../../../utils/common_ui.dart';
import 'game_shared_widgets.dart';

enum GameOptionsCloseAction { resumeGame, keepPaused, openSettings }

Future<GameOptionsCloseAction> showGameOptionsDialog({
  required BuildContext context,
  required int runSeed,
  RummiActiveRunSaveFacade? activeRunSaveView,
  required Future<bool> Function() onRestartRun,
  required Future<bool> Function() onExitToTitle,
  required bool isDebugFixtureRun,
}) async {
  SoundManager.unlockForWeb();
  SoundManager.playSfx(AssetPaths.sfxBtnSnd);
  final action = await showGameFramedDialog<GameOptionsCloseAction>(
    context: context,
    builder: (dialogContext) => GameModalCard(
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
                    color: Colors.white.withValues(alpha: 0.95),
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
                          color: Colors.white.withValues(alpha: 0.92),
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
                      backgroundColor: const Color(0xFF21423A),
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
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          GameMenuActionTile(
            title: isDebugFixtureRun ? '디버그 픽스처 재로드' : '현재 Station 재시작',
            subtitle: '현재 진행을 유지한 채 이번 Station 시작 시점으로 되돌립니다.',
            icon: Icons.refresh_rounded,
            accentColor: Colors.amber.shade200,
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
            accentColor: Colors.lightBlueAccent.shade100,
            onTap: () async {
              Navigator.of(
                dialogContext,
              ).pop(GameOptionsCloseAction.openSettings);
            },
          ),
          const SizedBox(height: 8),
          GameMenuActionTile(
            title: context.tr('exit'),
            subtitle: '현재 런을 종료하고 타이틀 화면으로 돌아갑니다.',
            icon: Icons.logout_rounded,
            accentColor: Colors.redAccent.shade100,
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
  );
  return action ?? GameOptionsCloseAction.resumeGame;
}

String _activeRunSummaryLabel(RummiActiveRunSaveFacade summary) {
  return summary.snapshotSummaryLabel();
}
