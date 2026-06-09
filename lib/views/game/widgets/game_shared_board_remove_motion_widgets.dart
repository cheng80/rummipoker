part of 'game_shared_widgets.dart';

class _BoardRemoveFlight {
  const _BoardRemoveFlight({
    required this.tick,
    required this.tile,
    required this.cellKey,
  });

  final int tick;
  final Tile tile;
  final String cellKey;
}

class _BoardRemoveFlightOverlay extends StatelessWidget {
  const _BoardRemoveFlightOverlay({required this.flight});

  final _BoardRemoveFlight flight;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentSide = min(constraints.maxWidth, constraints.maxHeight);
          final tileSide =
              (contentSide - (kBoardGridGap * (kBoardSize - 1))) / kBoardSize;
          final offset = _cellOffset(flight.cellKey, tileSide);
          return TweenAnimationBuilder<double>(
            key: ValueKey<int>(flight.tick),
            tween: Tween<double>(begin: 0, end: 1),
            duration: GamePresentationTimings.boardTileRemoveFlight,
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              final progress = value.clamp(0.0, 1.0);
              final rise = progress < 0.32
                  ? 8 * (progress / 0.32)
                  : 8 + (10 * ((progress - 0.32) / 0.68));
              final scale = progress < 0.32
                  ? 1.00 + (0.06 * (progress / 0.32))
                  : 1.06 + (-0.24 * ((progress - 0.32) / 0.68));
              final opacity = progress < 0.32
                  ? 1.0
                  : (1 - ((progress - 0.32) / 0.68)).clamp(0.0, 1.0);
              return Stack(
                children: [
                  Positioned(
                    key: const ValueKey('board-remove-flight'),
                    left: offset.dx,
                    top: offset.dy - rise,
                    width: tileSide,
                    height: tileSide,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: Transform.rotate(
                          angle: -0.035 * progress,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: IgnorePointer(
                child: GameRummiTileCard(
                  tile: flight.tile,
                  selected: true,
                  accent: false,
                  aspectRatio: kGameTileAspectRatio,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Offset _cellOffset(String cellKey, double tileSide) {
    final (row, col) = _parseBoardCellKey(cellKey);
    return Offset(
      col * (tileSide + kBoardGridGap),
      row * (tileSide + kBoardGridGap),
    );
  }
}
