import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../resources/asset_paths.dart';
import '../../../utils/common_ui.dart';
import 'game_shared_widgets.dart';
import 'game_ui_palette.dart';

Future<void> showGameTermsDialog({required BuildContext context}) {
  return showGameFramedDialog<void>(
    context: context,
    barrierDismissible: true,
    semanticLabel: context.tr('gameTermsTitle'),
    builder: (dialogContext) => GameModalCard(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('gameTermsTitle'),
                    style: TextStyle(
                      fontFamily: AssetPaths.fontNexonLv2Gothic,
                      color: GameUiPalette.textPrimary.withValues(alpha: 0.96),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                GameIconButtonChip(
                  tooltip: context.tr('cancel'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: Icons.close_rounded,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _GameTermRow(
                      title: context.tr('gameTermChipsTitle'),
                      body: context.tr('gameTermChipsBody'),
                    ),
                    _GameTermRow(
                      title: context.tr('gameTermScorePercentTitle'),
                      body: context.tr('gameTermScorePercentBody'),
                    ),
                    _GameTermRow(
                      title: context.tr('gameTermScoreMultiplierTitle'),
                      body: context.tr('gameTermScoreMultiplierBody'),
                    ),
                    _GameTermRow(
                      title: context.tr('gameTermGoldTitle'),
                      body: context.tr('gameTermGoldBody'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _GameTermRow extends StatelessWidget {
  const _GameTermRow({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: GameUiPalette.surfaceRunInfo,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: GameUiPalette.specialSoftMint.withValues(alpha: 0.38),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: GameUiPalette.actionGoldBright,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              color: GameUiPalette.textPrimary.withValues(alpha: 0.76),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
