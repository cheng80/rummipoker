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
              IconButton(
                tooltip: context.tr('cancel'),
                onPressed: () {
                  SoundManager.playSfx(AssetPaths.sfxBtnSnd);
                  Navigator.of(dialogContext).pop();
                },
                icon: const Icon(Icons.close_rounded),
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('runSeedLabel'),
                  style: TextStyle(
                    fontFamily: AssetPaths.fontAngduIpsul140,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 6),
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
                    IconButton(
                      tooltip: context.tr('copy'),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: '$runSeed'),
                        );
                        if (!context.mounted) return;
                        showTopNotice(context, '시드 번호를 복사했습니다.');
                      },
                      icon: const Icon(Icons.copy_rounded),
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (activeRunSaveView != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Run Snapshot',
                    style: TextStyle(
                      fontFamily: AssetPaths.fontAngduIpsul140,
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 6),
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
          ListTile(
            leading: Icon(Icons.refresh_rounded, color: Colors.amber.shade200),
            title: Text(
              isDebugFixtureRun ? '디버그 픽스처 재로드' : '현재 Station 재시작',
              style: TextStyle(
                fontFamily: AssetPaths.fontAngduIpsul140,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            onTap: () async {
              Navigator.of(dialogContext).pop();
              await WidgetsBinding.instance.endOfFrame;
              await onRestartRun();
            },
          ),
          ListTile(
            leading: Icon(
              Icons.logout_rounded,
              color: Colors.redAccent.shade100,
            ),
            title: Text(
              context.tr('exit'),
              style: TextStyle(
                fontFamily: AssetPaths.fontAngduIpsul140,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            onTap: () async {
              Navigator.of(dialogContext).pop();
              await WidgetsBinding.instance.endOfFrame;
              await onExitToTitle();
            },
          ),
          ListTile(
            leading: Icon(
              Icons.settings_rounded,
              color: Colors.lightBlueAccent.shade100,
            ),
            title: Text(
              context.tr('settings'),
              style: TextStyle(
                fontFamily: AssetPaths.fontAngduIpsul140,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
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
          if (kDebugMode) ...[
            const SizedBox(height: 4),
            Divider(color: Colors.white.withValues(alpha: 0.08)),
            ListTile(
              leading: Icon(
                Icons.bug_report_rounded,
                color: Colors.orange.shade200,
              ),
              title: Text(
                '현재 Blind 즉시 클리어',
                style: TextStyle(
                  fontFamily: AssetPaths.fontAngduIpsul140,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
              onTap: () async {
                Navigator.of(dialogContext).pop();
                await WidgetsBinding.instance.endOfFrame;
                await onDebugForceBlindClear();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.skip_next_rounded,
                color: Colors.lightGreenAccent.shade100,
              ),
              title: Text(
                '보스 클리어 후 다음 Blind Select',
                style: TextStyle(
                  fontFamily: AssetPaths.fontAngduIpsul140,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
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
