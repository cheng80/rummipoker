import 'package:flutter/material.dart';

import '../../../resources/asset_paths.dart';
import '../../../services/active_run_save_facade.dart';
import '../../../utils/common_ui.dart';
import 'game_ui_palette.dart';

Future<int?> showBookmarkSlotDialog({
  required BuildContext context,
  required String title,
  required String message,
  required List<ActiveRunBookmarkSlotView> slots,
}) {
  return showGameChoiceDialog<int?>(
    context,
    title: title,
    message: message,
    content: SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < slots.length; i++) ...[
            _BookmarkSlotOption(
              slot: slots[i],
              onTap: () => Navigator.of(context).pop(slots[i].slotIndex),
            ),
            if (i != slots.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    ),
    actions: const [
      GameDialogAction<int?>(
        label: '취소',
        value: null,
        accent: GameUiPalette.disabledControl,
      ),
    ],
  );
}

class _BookmarkSlotOption extends StatelessWidget {
  const _BookmarkSlotOption({required this.slot, required this.onTap});

  final ActiveRunBookmarkSlotView slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isEmpty = slot.isEmpty;
    return Semantics(
      button: true,
      label: '${slot.title} ${slot.label}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: GameUiPalette.titlePanelSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  (isEmpty
                          ? GameUiPalette.disabledControl
                          : GameUiPalette.actionGold)
                      .withValues(alpha: 0.42),
              width: 1.3,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              spacing: 10,
              children: [
                Icon(
                  isEmpty
                      ? Icons.bookmark_add_outlined
                      : Icons.bookmark_rounded,
                  color: isEmpty
                      ? GameUiPalette.textPrimary.withValues(alpha: 0.52)
                      : GameUiPalette.actionGold,
                  size: 24,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        slot.title,
                        style: TextStyle(
                          fontFamily: AssetPaths.fontNexonLv2Gothic,
                          color: GameUiPalette.textPrimary.withValues(
                            alpha: 0.92,
                          ),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        slot.label,
                        softWrap: true,
                        style: TextStyle(
                          color: GameUiPalette.textPrimary.withValues(
                            alpha: isEmpty ? 0.56 : 0.82,
                          ),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: GameUiPalette.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
