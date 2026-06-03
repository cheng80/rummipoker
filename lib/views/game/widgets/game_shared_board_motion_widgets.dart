part of 'game_shared_widgets.dart';

class _BoardMoveFlight {
  const _BoardMoveFlight({
    required this.tick,
    required this.tile,
    required this.fromCellKey,
    required this.toCellKey,
  });

  final int tick;
  final Tile tile;
  final String fromCellKey;
  final String toCellKey;
}

Map<String, Tile?> _tilesForBoard(RummiBoard board) {
  return {
    for (var row = 0; row < kBoardSize; row++)
      for (var col = 0; col < kBoardSize; col++)
        '$row:$col': board.cellAt(row, col),
  };
}

Map<String, String?> _tileKeysForBoard(RummiBoard board) {
  return {
    for (var row = 0; row < kBoardSize; row++)
      for (var col = 0; col < kBoardSize; col++)
        '$row:$col': _boardTileKey(board.cellAt(row, col)),
  };
}

String? _boardTileKey(Tile? tile) => tile?.toString();

(int, int) _parseBoardCellKey(String key) {
  final parts = key.split(':');
  return (int.parse(parts[0]), int.parse(parts[1]));
}

class _BoardMoveFlightOverlay extends StatelessWidget {
  const _BoardMoveFlightOverlay({required this.flight});

  final _BoardMoveFlight flight;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentSide = min(constraints.maxWidth, constraints.maxHeight);
          final tileSide =
              (contentSide - (kBoardGridGap * (kBoardSize - 1))) / kBoardSize;
          final fromOffset = _cellOffset(flight.fromCellKey, tileSide);
          final toOffset = _cellOffset(flight.toCellKey, tileSide);
          return TweenAnimationBuilder<double>(
            key: ValueKey<int>(flight.tick),
            tween: Tween<double>(begin: 0, end: 1),
            duration: GamePresentationTimings.boardTileMoveFlight,
            curve: Curves.linear,
            builder: (context, value, child) {
              final travel = GamePresentationMotion.flightProgress(value);
              final offset = GamePresentationMotion.flightOffset(
                fromOffset,
                toOffset,
                value,
              );
              final arc = sin(pi * travel) * -10;
              final pulse = sin(pi * travel);
              return Stack(
                children: [
                  _BoardMoveFlightRing(
                    key: const ValueKey('board-move-flight-source-ring'),
                    offset: fromOffset,
                    tileSide: tileSide,
                    progress: value,
                    isSource: true,
                  ),
                  _BoardMoveFlightRing(
                    key: const ValueKey('board-move-flight-destination-ring'),
                    offset: toOffset,
                    tileSide: tileSide,
                    progress: value,
                    isSource: false,
                  ),
                  Positioned(
                    key: const ValueKey('board-move-flight'),
                    left: offset.dx,
                    top: offset.dy + arc,
                    width: tileSide,
                    height: tileSide,
                    child: Transform.scale(
                      scale: 1 + (0.05 * pulse),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF86F4C3,
                              ).withValues(alpha: 0.22 * pulse),
                              blurRadius: 14 * pulse,
                              spreadRadius: 1.2 * pulse,
                            ),
                          ],
                        ),
                        child: child,
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

class _BoardMoveFlightRing extends StatelessWidget {
  const _BoardMoveFlightRing({
    super.key,
    required this.offset,
    required this.tileSide,
    required this.progress,
    required this.isSource,
  });

  final Offset offset;
  final double tileSide;
  final double progress;
  final bool isSource;

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0));
    final visible = isSource ? (1 - eased).clamp(0.0, 1.0) : eased;
    final pulse = sin(pi * progress).clamp(0.0, 1.0);
    final color = isSource
        ? GameUiPalette.boardMoveSource
        : GameUiPalette.boardMoveAvailable;
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      width: tileSide,
      height: tileSide,
      child: IgnorePointer(
        child: Opacity(
          opacity: (0.28 + visible * 0.72).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 1 + (pulse * 0.08),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: color.withValues(alpha: 0.84),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.28 + pulse * 0.18),
                    blurRadius: 12 + pulse * 8,
                    spreadRadius: 1.2 + pulse,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
