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

class _ContributorClear {
  const _ContributorClear({required this.tick, required this.tiles});

  final int tick;

  /// 줄 방향 순서의 (칸 키, 타일).
  final List<(String, Tile)> tiles;
}

/// 확정 뒤 contributor 타일이 30~40ms 간격으로 부풀었다 터지고, 빈 칸에 잔광이 남는다.
class _ContributorClearOverlay extends StatelessWidget {
  const _ContributorClearOverlay({required this.clear});

  final _ContributorClear clear;

  @override
  Widget build(BuildContext context) {
    const stagger = GamePresentationTimings.contributorClearStagger;
    const pop = GamePresentationTimings.contributorClearPop;
    const afterglow = GamePresentationTimings.contributorClearAfterglow;
    final total = stagger * clear.tiles.length + pop + afterglow;
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentSide = min(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              final tileSide =
                  (contentSide - (kBoardGridGap * (kBoardSize - 1))) /
                  kBoardSize;
              return TweenAnimationBuilder<double>(
                key: ValueKey('contributor-clear-${clear.tick}'),
                tween: Tween<double>(begin: 0, end: 1),
                duration: total,
                builder: (context, value, _) {
                  final elapsed = total * value;
                  return Stack(
                    children: [
                      for (var i = 0; i < clear.tiles.length; i++)
                        _buildTile(
                          clear.tiles[i],
                          tileSide: tileSide,
                          popT: _phase(elapsed - stagger * i, pop),
                          glowT: _phase(elapsed - stagger * i - pop, afterglow),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  static double _phase(Duration elapsed, Duration length) =>
      (elapsed.inMicroseconds / length.inMicroseconds).clamp(0.0, 1.0);

  Widget _buildTile(
    (String, Tile) entry, {
    required double tileSide,
    required double popT,
    required double glowT,
  }) {
    final (row, col) = _parseBoardCellKey(entry.$1);
    // 0~0.35 부풀기, 이후 0으로 터지며 사라진다.
    final scale = popT < 0.35
        ? 1 + 0.16 * (popT / 0.35)
        : 1.16 * (1 - Curves.easeInCubic.transform((popT - 0.35) / 0.65));
    final glowAlpha = popT < 1 ? 0.6 * popT : 0.6 * (1 - glowT);
    return Positioned(
      key: ValueKey('contributor-clear-tile-${entry.$1}'),
      left: col * (tileSide + kBoardGridGap),
      top: row * (tileSide + kBoardGridGap),
      width: tileSide,
      height: tileSide,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (glowAlpha > 0)
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: GameUiPalette.actionGoldBright.withValues(
                  alpha: 0.28 * glowAlpha,
                ),
                border: Border.all(
                  color: GameUiPalette.actionGoldBright.withValues(
                    alpha: glowAlpha,
                  ),
                  width: 2,
                ),
              ),
            ),
          if (scale > 0.01)
            Transform.rotate(
              angle: 0.12 * popT,
              child: Transform.scale(
                scale: scale,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: GameRummiTileCard(
                    tile: entry.$2,
                    selected: false,
                    accent: false,
                    aspectRatio: kGameTileAspectRatio,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
