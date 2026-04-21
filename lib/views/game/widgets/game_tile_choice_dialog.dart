import 'package:flutter/material.dart';

import '../../../logic/rummi_poker_grid/models/tile.dart';
import 'game_shared_widgets.dart';

class GameTileChoiceDialog extends StatelessWidget {
  const GameTileChoiceDialog({
    super.key,
    required this.title,
    required this.tiles,
    this.message,
    this.closeLabel,
    this.onTileSelected,
    this.onClose,
    this.tileSize = 58,
    this.tileSpacing = 8,
  });

  final String title;
  final String? message;
  final List<Tile> tiles;
  final String? closeLabel;
  final ValueChanged<int>? onTileSelected;
  final VoidCallback? onClose;
  final double tileSize;
  final double tileSpacing;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF123126).withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            14,
            14,
            14,
            closeLabel == null ? 14 : 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 6),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < tiles.length; index++) ...[
                    _TileChoiceButton(
                      tile: tiles[index],
                      size: tileSize,
                      onTap: () {
                        onTileSelected?.call(index);
                        Navigator.of(context).pop(index);
                      },
                    ),
                    if (index != tiles.length - 1) SizedBox(width: tileSpacing),
                  ],
                ],
              ),
              if (closeLabel != null) ...[
                const SizedBox(height: 12),
                GameActionButton(
                  label: closeLabel!,
                  background: const Color(0xFF4C5A55),
                  onPressed: () {
                    onClose?.call();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TileChoiceButton extends StatelessWidget {
  const _TileChoiceButton({
    required this.tile,
    required this.size,
    required this.onTap,
  });

  final Tile tile;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: GameRummiTileCard(tile: tile, selected: false, accent: true),
        ),
      ),
    );
  }
}
