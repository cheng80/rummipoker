import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app_config.dart';
import '../../../resources/asset_paths.dart';
import '../../../resources/sound_manager.dart';
import '../../../services/active_run_save_facade.dart';
import '../../../utils/common_ui.dart';
import 'game_shared_widgets.dart';

Future<void> showGameOptionsDialog({
  required BuildContext context,
  required int runSeed,
  RummiActiveRunSaveFacade? activeRunSaveView,
  required Future<void> Function() onRestartRun,
  required Future<void> Function() onExitToTitle,
  required Future<void> Function(BuildContext context) onReopenOptions,
  required Future<void> Function() onDebugForceBlindClear,
  required Future<void> Function() onDebugForceBossClearToNextBlindSelect,
  required bool isDebugFixtureRun,
}) async {
  SoundManager.unlockForWeb();
  SoundManager.playSfx(AssetPaths.sfxBtnSnd);
  await showGameFramedDialog<void>(
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
                    fontFamily: AssetPaths.fontAngduIpsul140,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ),
              GameIconButtonChip(
                tooltip: context.tr('cancel'),
                onPressed: () {
                  SoundManager.playSfx(AssetPaths.sfxBtnSnd);
                  Navigator.of(dialogContext).pop();
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
              Navigator.of(dialogContext).pop();
              await WidgetsBinding.instance.endOfFrame;
              await onRestartRun();
            },
          ),
          const SizedBox(height: 8),
          GameMenuActionTile(
            title: context.tr('settings'),
            subtitle: '설정 화면을 열고 복귀 후 현재 메뉴를 다시 엽니다.',
            icon: Icons.settings_rounded,
            accentColor: Colors.lightBlueAccent.shade100,
            onTap: () async {
              Navigator.of(dialogContext).pop();
              await WidgetsBinding.instance.endOfFrame;
              if (!context.mounted) return;
              SoundManager.playSfx(AssetPaths.sfxBtnSnd);
              await context.push(RoutePaths.setting);
              if (!context.mounted) return;
              await onReopenOptions(context);
            },
          ),
          const SizedBox(height: 8),
          GameMenuActionTile(
            title: context.tr('exit'),
            subtitle: '현재 런을 종료하고 타이틀 화면으로 돌아갑니다.',
            icon: Icons.logout_rounded,
            accentColor: Colors.redAccent.shade100,
            onTap: () async {
              Navigator.of(dialogContext).pop();
              await WidgetsBinding.instance.endOfFrame;
              await onExitToTitle();
            },
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 10),
            Divider(color: Colors.white.withValues(alpha: 0.08)),
            const SizedBox(height: 8),
            GameMenuActionTile(
              title: '현재 Blind 즉시 클리어',
              subtitle: '현재 선택된 블라인드를 즉시 정산 완료 상태로 넘깁니다.',
              icon: Icons.bug_report_rounded,
              accentColor: Colors.orange.shade200,
              onTap: () async {
                Navigator.of(dialogContext).pop();
                await WidgetsBinding.instance.endOfFrame;
                await onDebugForceBlindClear();
              },
            ),
            const SizedBox(height: 8),
            GameMenuActionTile(
              title: '보스 클리어 후 다음 Blind Select',
              subtitle: '다음 스테이션의 블라인드 선택으로 바로 이행합니다.',
              icon: Icons.skip_next_rounded,
              accentColor: Colors.lightGreenAccent.shade100,
              onTap: () async {
                Navigator.of(dialogContext).pop();
                await WidgetsBinding.instance.endOfFrame;
                await onDebugForceBossClearToNextBlindSelect();
              },
            ),
          ],
        ],
      ),
    ),
  );
}

String _activeRunSummaryLabel(RummiActiveRunSaveFacade summary) {
  return summary.snapshotSummaryLabel();
}
