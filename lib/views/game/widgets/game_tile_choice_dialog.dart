import 'package:flutter/material.dart';

import '../../../utils/app_translation.dart';
import '../../../utils/common_ui.dart';
import '../../../widgets/semantic_text.dart';

import '../../../logic/rummi_poker_grid/models/tile.dart';
import '../game_presentation_timings.dart';
import 'game_shared_widgets.dart';
import 'game_ui_palette.dart';

class GameTileChoiceDialog extends StatefulWidget {
  const GameTileChoiceDialog({
    super.key,
    required this.title,
    required this.tiles,
    this.message,
    this.closeLabel,
    this.onTileSelected,
    this.resultOwnsSound = false,
    this.closeResultOwnsSound = false,
    this.onClose,
    this.tileSize = 58,
    this.tileSpacing = 8,
  });

  final String title;
  final String? message;
  final List<Tile> tiles;
  final String? closeLabel;
  final ValueChanged<int>? onTileSelected;

  /// 선택 후 호출부가 결과음을 내는 경우 기본 클릭음을 생략한다.
  final bool resultOwnsSound;
  final bool closeResultOwnsSound;
  final VoidCallback? onClose;
  final double tileSize;
  final double tileSpacing;

  @override
  State<GameTileChoiceDialog> createState() => _GameTileChoiceDialogState();
}

class _GameTileChoiceDialogState extends State<GameTileChoiceDialog> {
  int? _selectedIndex;

  Future<void> _selectTile(int index) async {
    if (_selectedIndex != null) return;
    if (!widget.resultOwnsSound) playButtonSound();
    setState(() => _selectedIndex = index);
    widget.onTileSelected?.call(index);
    await Future<void>.delayed(
      GamePresentationTimings.tileChoiceSelectFeedback,
    );
    if (!mounted) return;
    Navigator.of(context).pop(index);
  }

  @override
  Widget build(BuildContext context) {
    final routeLabel = widget.title.trim().isEmpty
        ? context.translate('battleWidgetsTileChoice')
        : widget.title;
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: routeLabel,
      child: Dialog(
        backgroundColor: GameUiPalette.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: GameUiPalette.surfaceModalInner.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: GameUiPalette.textPrimary.withValues(alpha: 0.12),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              14,
              14,
              14,
              widget.closeLabel == null ? 14 : 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: GameUiPalette.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.message != null) ...[
                  const SizedBox(height: 6),
                  SemanticText(
                    widget.message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: GameUiPalette.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (
                      var index = 0;
                      index < widget.tiles.length;
                      index++
                    ) ...[
                      _TileChoiceButton(
                        index: index,
                        tile: widget.tiles[index],
                        size: widget.tileSize,
                        selected: _selectedIndex == index,
                        disabled: _selectedIndex != null,
                        onTap: () => _selectTile(index),
                      ),
                      if (index != widget.tiles.length - 1)
                        SizedBox(width: widget.tileSpacing),
                    ],
                  ],
                ),
                if (widget.closeLabel != null) ...[
                  const SizedBox(height: 12),
                  GameActionButton(
                    playSound: !widget.closeResultOwnsSound,
                    label: widget.closeLabel!,
                    background: GameUiPalette.passiveSlotAccent,
                    onPressed: _selectedIndex == null
                        ? () {
                            widget.onClose?.call();
                            Navigator.of(context).pop();
                          }
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TileChoiceButton extends StatelessWidget {
  const _TileChoiceButton({
    required this.index,
    required this.tile,
    required this.size,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final int index;
  final Tile tile;
  final double size;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      child: Semantics(
        button: true,
        label: context.translate(
          'battleWidgetsTileCandidateLabel',
          namedArgs: {'index': '${index + 1}', 'code': tile.code},
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              key: ValueKey('tile-choice-$index'),
              width: size,
              height: size,
              child: AnimatedScale(
                scale: selected ? 0.94 : 1,
                duration: GamePresentationTimings.tileChoiceSelectFeedback,
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: disabled && !selected ? 0.42 : 1,
                  duration: GamePresentationTimings.tileChoiceSelectFeedback,
                  curve: Curves.easeOutCubic,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Material(
                        color: GameUiPalette.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: disabled ? null : onTap,
                          borderRadius: BorderRadius.circular(8),
                          child: GameRummiTileCard(
                            tile: tile,
                            selected: selected,
                            accent: false,
                          ),
                        ),
                      ),
                      if (selected)
                        DecoratedBox(
                          key: ValueKey('tile-choice-selected-feedback-$index'),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: GameUiPalette.specialGoldLabel,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFFD86B,
                                ).withValues(alpha: 0.55),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                      if (selected)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Transform.translate(
                            offset: const Offset(0, 9),
                            child: DecoratedBox(
                              key: ValueKey(
                                'tile-choice-discard-result-$index',
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF181D20,
                                ).withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: GameUiPalette.specialGoldLabel,
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                child: Text(
                                  context.translate(
                                    'battleWidgetsDiscardConfirmed',
                                  ),
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: GameUiPalette.specialGoldPale,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              context.translate(
                'battleWidgetsTileCandidate',
                namedArgs: {'index': '${index + 1}'},
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GameUiPalette.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              tile.code,
              maxLines: 1,
              style: const TextStyle(
                color: GameUiPalette.actionGoldBright,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
