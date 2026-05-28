part of 'game_shared_widgets.dart';

class GameBoardGrid extends StatefulWidget {
  const GameBoardGrid({
    super.key,
    required this.board,
    required this.scoringCells,
    required this.constrainedScoringCells,
    required this.activeSettlementCells,
    required this.settlementBoardSnapshot,
    required this.selectedRow,
    required this.selectedCol,
    required this.boardMoveMode,
    required this.moveSourceRow,
    required this.moveSourceCol,
    required this.onTapCell,
    required this.onLongPressTile,
    this.constrainedCells = const {},
    this.bonusFlashCellKey,
    this.bonusFlashTick = 0,
    this.alignment = Alignment.center,
  });

  final RummiBoard board;
  final Set<String> scoringCells;
  final Set<String> constrainedScoringCells;
  final Set<String> constrainedCells;
  final Set<String> activeSettlementCells;
  final Map<String, Tile> settlementBoardSnapshot;
  final int? selectedRow;
  final int? selectedCol;
  final bool boardMoveMode;
  final int? moveSourceRow;
  final int? moveSourceCol;
  final String? bonusFlashCellKey;
  final int bonusFlashTick;
  final void Function(int row, int col) onTapCell;
  final ValueChanged<Tile> onLongPressTile;
  final AlignmentGeometry alignment;

  @override
  State<GameBoardGrid> createState() => _GameBoardGridState();
}

class _GameBoardGridState extends State<GameBoardGrid> {
  late Map<String, String?> _previousTileKeys;
  late Map<String, Tile?> _previousTiles;
  Set<String> _appearingCells = const {};
  _BoardMoveFlight? _moveFlight;
  _BoardRemoveFlight? _removeFlight;
  int _moveFlightTick = 0;
  int _removeFlightTick = 0;

  @override
  void initState() {
    super.initState();
    _previousTileKeys = _tileKeysForBoard(widget.board);
    _previousTiles = _tilesForBoard(widget.board);
  }

  @override
  void didUpdateWidget(covariant GameBoardGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentTileKeys = _tileKeysForBoard(widget.board);
    final appearingCells = <String>{};
    final removedCells = <String>[];
    final appearedCells = <String>[];
    for (final entry in currentTileKeys.entries) {
      final previous = _previousTileKeys[entry.key];
      if (previous == null && entry.value != null) {
        appearingCells.add(entry.key);
        appearedCells.add(entry.key);
      } else if (previous != null && entry.value == null) {
        removedCells.add(entry.key);
      }
    }
    _startBoardMoveFlightIfNeeded(
      removedCells: removedCells,
      appearedCells: appearedCells,
      previousTileKeys: _previousTileKeys,
      currentTileKeys: currentTileKeys,
    );
    _startBoardRemoveFlightIfNeeded(
      removedCells: removedCells,
      appearedCells: appearedCells,
      previousTiles: _previousTiles,
    );
    _previousTileKeys = currentTileKeys;
    _previousTiles = _tilesForBoard(widget.board);
    _appearingCells = _moveFlight == null
        ? appearingCells
        : appearingCells.difference({_moveFlight!.toCellKey});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = min(constraints.maxWidth, constraints.maxHeight);

        return Align(
          alignment: widget.alignment,
          child: SizedBox(
            width: side,
            height: side,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: GameUiPalette.surfaceSection.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: GameUiPalette.boardFrameBorder.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(kBoardFrameInset),
                child: Stack(
                  children: [
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: kBoardSize,
                            mainAxisSpacing: kBoardGridGap,
                            crossAxisSpacing: kBoardGridGap,
                          ),
                      itemCount: kBoardSize * kBoardSize,
                      itemBuilder: (context, index) {
                        final row = index ~/ kBoardSize;
                        final col = index % kBoardSize;
                        final cellKey = '$row:$col';
                        final tile = cellKey == _moveFlight?.toCellKey
                            ? null
                            : widget.board.cellAt(row, col) ??
                                  widget.settlementBoardSnapshot['$row:$col'];
                        final selected =
                            widget.selectedRow == row &&
                            widget.selectedCol == col;
                        final scoring = widget.scoringCells.contains(cellKey);
                        final constrainedScoring = widget
                            .constrainedScoringCells
                            .contains(cellKey);
                        final constrained = widget.constrainedCells.contains(
                          cellKey,
                        );
                        final settlementActive = widget.activeSettlementCells
                            .contains(cellKey);
                        final isMoveSource =
                            widget.boardMoveMode &&
                            widget.moveSourceRow == row &&
                            widget.moveSourceCol == col;
                        final isMoveAvailable =
                            widget.boardMoveMode && tile == null;
                        final isMoveLocked =
                            widget.boardMoveMode &&
                            tile != null &&
                            !isMoveSource;
                        Widget child = GameBoardCell(
                          key: ValueKey('board-cell-$row-$col'),
                          tile: tile,
                          selected: selected,
                          scoring: scoring,
                          constrainedScoring: constrainedScoring,
                          constrained: constrained,
                          settlementActive: settlementActive,
                          moveSource: isMoveSource,
                          moveAvailable: isMoveAvailable,
                          moveLocked: isMoveLocked,
                          onTap: () => widget.onTapCell(row, col),
                          onLongPress: tile == null
                              ? null
                              : () => widget.onLongPressTile(tile),
                        );
                        if (widget.bonusFlashCellKey == cellKey &&
                            widget.bonusFlashTick > 0) {
                          child = _BoardMoveBonusFlash(
                            tick: widget.bonusFlashTick,
                            child: child,
                          );
                        }
                        if (!_appearingCells.contains(cellKey)) {
                          return child;
                        }
                        return _BoardPlacePop(child: child);
                      },
                    ),
                    if (_moveFlight != null)
                      _BoardMoveFlightOverlay(flight: _moveFlight!),
                    if (_removeFlight != null)
                      _BoardRemoveFlightOverlay(flight: _removeFlight!),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _startBoardMoveFlightIfNeeded({
    required List<String> removedCells,
    required List<String> appearedCells,
    required Map<String, String?> previousTileKeys,
    required Map<String, String?> currentTileKeys,
  }) {
    if (removedCells.length != 1 || appearedCells.length != 1) {
      _moveFlight = null;
      return;
    }
    final fromCellKey = removedCells.single;
    final toCellKey = appearedCells.single;
    if (previousTileKeys[fromCellKey] != currentTileKeys[toCellKey]) {
      _moveFlight = null;
      return;
    }
    final (toRow, toCol) = _parseBoardCellKey(toCellKey);
    final tile = widget.board.cellAt(toRow, toCol);
    if (tile == null) {
      _moveFlight = null;
      return;
    }
    final tick = _moveFlightTick + 1;
    _moveFlightTick = tick;
    _moveFlight = _BoardMoveFlight(
      tick: tick,
      tile: tile,
      fromCellKey: fromCellKey,
      toCellKey: toCellKey,
    );
    Future<void>.delayed(GamePresentationTimings.boardTileMoveFlight, () {
      if (!mounted || _moveFlight?.tick != tick) return;
      setState(() => _moveFlight = null);
    });
  }

  void _startBoardRemoveFlightIfNeeded({
    required List<String> removedCells,
    required List<String> appearedCells,
    required Map<String, Tile?> previousTiles,
  }) {
    if (removedCells.length != 1 || appearedCells.isNotEmpty) {
      _removeFlight = null;
      return;
    }
    final cellKey = removedCells.single;
    final tile = previousTiles[cellKey];
    if (tile == null) {
      _removeFlight = null;
      return;
    }
    final tick = _removeFlightTick + 1;
    _removeFlightTick = tick;
    _removeFlight = _BoardRemoveFlight(
      tick: tick,
      tile: tile,
      cellKey: cellKey,
    );
    Future<void>.delayed(GamePresentationTimings.boardTileRemoveFlight, () {
      if (!mounted || _removeFlight?.tick != tick) return;
      setState(() => _removeFlight = null);
    });
  }
}

class _BoardMoveBonusFlash extends StatelessWidget {
  const _BoardMoveBonusFlash({required this.tick, required this.child});

  final int tick;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('board-move-bonus-flash-$tick'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.boardMoveBonusFlash,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final wave = sin(pi * value).clamp(0.0, 1.0);
        final fade = (1 - value).clamp(0.0, 1.0);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned.fill(
              key: const ValueKey('board-move-bonus-flash'),
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(
                        0xFFFFD86B,
                      ).withValues(alpha: 0.95 * fade),
                      width: 2 + (1.5 * wave),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFFFFD86B,
                        ).withValues(alpha: 0.48 * wave),
                        blurRadius: 18 * wave,
                        spreadRadius: 2.5 * wave,
                      ),
                      BoxShadow(
                        color: const Color(
                          0xFF80F7CA,
                        ).withValues(alpha: 0.35 * wave),
                        blurRadius: 22 * wave,
                        spreadRadius: 1.5 * wave,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

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
            curve: Curves.easeInOutCubic,
            builder: (context, value, child) {
              final offset = Offset.lerp(fromOffset, toOffset, value)!;
              final arc = sin(pi * value) * -10;
              final pulse = sin(pi * value);
              return Stack(
                children: [
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
              final rise = value * 20;
              final opacity = (1 - value).clamp(0.0, 1.0);
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
                        scale: 1 - (0.08 * value),
                        child: Transform.rotate(
                          angle: -0.08 * value,
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

class _BoardPlacePop extends StatelessWidget {
  const _BoardPlacePop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('board-place-pop'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.boardTilePlacePop,
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final glow = (1 - value).clamp(0.0, 1.0);
        final progress = value.clamp(0.0, 1.0);
        final travel = (1 - Curves.easeOutCubic.transform(progress)) * 18;
        return Transform.translate(
          key: const ValueKey('board-place-flight'),
          offset: Offset(0, travel),
          child: Opacity(
            opacity: (0.72 + (progress * 0.28)).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.9 + (value * 0.1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFFF2C14E,
                      ).withValues(alpha: 0.24 * glow),
                      blurRadius: 16 * glow,
                      spreadRadius: 1.5 * glow,
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class GameBoardCell extends StatelessWidget {
  const GameBoardCell({
    super.key,
    required this.tile,
    required this.selected,
    required this.scoring,
    required this.constrainedScoring,
    required this.constrained,
    required this.settlementActive,
    required this.moveSource,
    required this.moveAvailable,
    required this.moveLocked,
    required this.onTap,
    this.onLongPress,
  });

  final Tile? tile;
  final bool selected;
  final bool scoring;
  final bool constrainedScoring;
  final bool constrained;
  final bool settlementActive;
  final bool moveSource;
  final bool moveAvailable;
  final bool moveLocked;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final borderColor = moveSource
        ? GameUiPalette.boardMoveSource
        : moveAvailable
        ? GameUiPalette.boardMoveAvailable
        : moveLocked
        ? GameUiPalette.textPrimary.withValues(alpha: 0.18)
        : selected
        ? GameUiPalette.userSelection
        : settlementActive
        ? GameUiPalette.settlementActive
        : constrainedScoring
        ? GameUiPalette.bossWeakenPreview
        : scoring
        ? GameUiPalette.scoringPreview
        : GameUiPalette.textPrimary.withValues(alpha: 0.1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = min(constraints.maxWidth, constraints.maxHeight);
        final cornerRadius = rummikubTileCornerRadiusForSide(side);

        return Material(
          color: GameUiPalette.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(cornerRadius),
            child: AnimatedContainer(
              duration: GamePresentationTimings.boardTileState,
              decoration: BoxDecoration(
                color: selected
                    ? GameUiPalette.boardSelectedFill
                    : moveAvailable
                    ? GameUiPalette.boardMoveAvailableFill.withValues(
                        alpha: 0.86,
                      )
                    : moveLocked
                    ? GameUiPalette.boardMoveLockedFill.withValues(alpha: 0.78)
                    : settlementActive
                    ? GameUiPalette.boardSettlementFill
                    : GameUiPalette.boardDefaultFill.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(cornerRadius),
                border: Border.all(
                  color: borderColor,
                  width:
                      selected ||
                          settlementActive ||
                          constrainedScoring ||
                          moveSource ||
                          moveAvailable
                      ? 2
                      : 1,
                ),
                boxShadow: settlementActive
                    ? [
                        BoxShadow(
                          color: GameUiPalette.settlementActive.withValues(
                            alpha: 0.18,
                          ),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : selected
                    ? [
                        BoxShadow(
                          color: GameUiPalette.userSelection.withValues(
                            alpha: 0.32,
                          ),
                          blurRadius: 12,
                          spreadRadius: 1.5,
                        ),
                      ]
                    : null,
              ),
              child: tile == null
                  ? moveAvailable
                        ? Center(
                            child: Icon(
                              Icons.open_with_rounded,
                              color: GameUiPalette.textPrimary.withValues(
                                alpha: 0.58,
                              ),
                              size: side * 0.32,
                            ),
                          )
                        : null
                  : _SettlementTileLift(
                      active: settlementActive,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Opacity(
                              opacity: moveLocked ? 0.42 : 1,
                              child: GameRummiTileCard(
                                tile: tile!,
                                selected: false,
                                accent: false,
                                aspectRatio: kGameTileAspectRatio,
                                reserveConstraintBadgeSpace: constrained,
                              ),
                            ),
                          ),
                          if (constrained)
                            Positioned(
                              left: 4,
                              top: 4,
                              right: 4,
                              bottom: 4,
                              child: GameConstraintBadge(side: side),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _SettlementTileLift extends StatelessWidget {
  const _SettlementTileLift({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    return TweenAnimationBuilder<double>(
      key: const ValueKey('settlement-tile-lift'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.settlementTileLift,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final lift = sin(pi * value);
        return Transform.translate(
          offset: Offset(0, -6 * lift),
          child: Transform.scale(scale: 1 + (0.035 * lift), child: child),
        );
      },
      child: child,
    );
  }
}

class GameConstraintBadge extends StatelessWidget {
  const GameConstraintBadge({super.key, required this.side});

  final double side;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final pad = width * 0.06;
        final innerWidth = width - (pad * 2);
        final innerHeight = height - (pad * 2);
        final barHeight = innerHeight * 0.24;
        final fontSize = barHeight * 0.98;

        return IgnorePointer(
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: innerWidth,
                height: barHeight,
                child: Center(
                  child: Text(
                    'X',
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: GameUiPalette.textPrimary.withValues(alpha: 0.96),
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      shadows: [
                        Shadow(
                          color: GameUiPalette.ink.withValues(alpha: 0.36),
                          blurRadius: 1.7,
                          offset: const Offset(0, 0.9),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class GameRummiTileCard extends StatelessWidget {
  const GameRummiTileCard({
    super.key,
    required this.tile,
    required this.selected,
    required this.accent,
    this.aspectRatio = kGameTileAspectRatio,
    this.reserveConstraintBadgeSpace = false,
  });

  final Tile tile;
  final bool selected;
  final bool accent;
  final double aspectRatio;
  final bool reserveConstraintBadgeSpace;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _GameRummiTilePainter(
                tile: tile,
                selected: selected,
                accent: accent,
              ),
            ),
          ),
          if (tile.hasModifier)
            Positioned.fill(
              child: GameTileModifierBadges(
                tile: tile,
                reserveConstraintBadgeSpace: reserveConstraintBadgeSpace,
              ),
            ),
        ],
      ),
    );
  }
}

class GameTileModifierBadges extends StatelessWidget {
  const GameTileModifierBadges({
    super.key,
    required this.tile,
    this.reserveConstraintBadgeSpace = false,
  });

  final Tile tile;
  final bool reserveConstraintBadgeSpace;

  @override
  Widget build(BuildContext context) {
    final enhancement = tile.enhancement;
    final seal = tile.seal;
    return IgnorePointer(
      key: const ValueKey('tile-modifier-badge-layer'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.biggest.shortestSide;
          final metrics = _TileModifierBadgeMetrics.forTileSide(side);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (enhancement != null)
                Positioned(
                  key: const ValueKey('tile-enhancement-badge'),
                  left: metrics.enhancementInset,
                  top: metrics.enhancementInset,
                  child: _TileModifierBadge(
                    label: tileEnhancementShortLabel(enhancement),
                    height: metrics.badgeHeight,
                    fontSize: metrics.fontSize,
                    background: tileEnhancementColor(enhancement),
                    foreground: enhancement == TileEnhancement.goldTile
                        ? GameUiPalette.ink
                        : GameUiPalette.textPrimary,
                  ),
                ),
              if (seal != null)
                Positioned(
                  key: const ValueKey('tile-seal-badge'),
                  right: metrics.sealInset,
                  bottom: metrics.sealInset,
                  child: _TileModifierBadge(
                    label: tileSealShortLabel(seal),
                    height: metrics.badgeHeight,
                    fontSize: metrics.fontSize,
                    background: tileSealColor(seal),
                    foreground: GameUiPalette.textPrimary,
                    circular: true,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TileModifierBadgeMetrics {
  const _TileModifierBadgeMetrics({
    required this.badgeHeight,
    required this.fontSize,
    required this.enhancementInset,
    required this.sealInset,
  });

  factory _TileModifierBadgeMetrics.forTileSide(double side) {
    final badgeHeight = (side * 0.22).clamp(12.0, 14.0).toDouble();
    return _TileModifierBadgeMetrics(
      badgeHeight: badgeHeight,
      fontSize: (badgeHeight * 0.62).clamp(7.0, 9.0).toDouble(),
      enhancementInset: -2.0,
      sealInset: (side * 0.055).clamp(2.0, 4.0).toDouble(),
    );
  }

  final double badgeHeight;
  final double fontSize;
  final double enhancementInset;
  final double sealInset;
}

class _TileModifierBadge extends StatelessWidget {
  const _TileModifierBadge({
    required this.label,
    required this.height,
    required this.fontSize,
    required this.background,
    required this.foreground,
    this.circular = false,
  });

  final String label;
  final double height;
  final double fontSize;
  final Color background;
  final Color foreground;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(circular ? 999 : height * 0.28),
        border: Border.all(
          color: GameUiPalette.textPrimary.withValues(alpha: 0.82),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: GameUiPalette.ink.withValues(alpha: 0.32),
            blurRadius: 5,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: SizedBox(
        height: height,
        width: circular ? height : height * 1.45,
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foreground,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

String tileModifierSummary(Tile tile) {
  final parts = <String>[
    if (tile.enhancement != null) tileEnhancementDisplayName(tile.enhancement!),
    if (tile.seal != null) tileSealDisplayName(tile.seal!),
  ];
  return parts.join(' · ');
}

String tileModifierEffectText(Tile tile) {
  final parts = <String>[
    if (tile.enhancement != null) tileEnhancementEffectText(tile.enhancement!),
    if (tile.seal != null) tileSealEffectText(tile.seal!),
  ];
  return parts.join(' / ');
}

String tileColorDisplayName(TileColor color) {
  return switch (color) {
    TileColor.red => '빨간 타일',
    TileColor.blue => '파란 타일',
    TileColor.yellow => '노란 타일',
    TileColor.black => '검은 타일',
  };
}

String tileEnhancementShortLabel(TileEnhancement enhancement) {
  return switch (enhancement) {
    TileEnhancement.chipInlaid => '+C',
    TileEnhancement.scoreGilded => '+%',
    TileEnhancement.goldTile => 'G',
    TileEnhancement.glassTile => 'x',
    TileEnhancement.wildPainted => 'W',
    TileEnhancement.luckyTile => '?',
  };
}

String tileSealShortLabel(TileSeal seal) {
  return switch (seal) {
    TileSeal.blueSeal => 'B',
    TileSeal.redSeal => 'R',
  };
}

String tileEnhancementDisplayName(TileEnhancement enhancement) {
  return switch (enhancement) {
    TileEnhancement.chipInlaid => '칩 박힘',
    TileEnhancement.scoreGilded => '점수 도금',
    TileEnhancement.goldTile => '골드',
    TileEnhancement.glassTile => '유리',
    TileEnhancement.wildPainted => '와일드',
    TileEnhancement.luckyTile => '럭키',
  };
}

String tileSealDisplayName(TileSeal seal) {
  return switch (seal) {
    TileSeal.blueSeal => '푸른 인장',
    TileSeal.redSeal => '붉은 인장',
  };
}

String tileEnhancementEffectText(TileEnhancement enhancement) {
  return switch (enhancement) {
    TileEnhancement.chipInlaid => '확정 시 +20칩',
    TileEnhancement.scoreGilded => '확정 시 점수 +20%',
    TileEnhancement.goldTile => '확정 후 골드 +1',
    TileEnhancement.glassTile => '확정 시 점수 x1.5',
    TileEnhancement.wildPainted => '색상 판정 확장 예정',
    TileEnhancement.luckyTile => '확률 발동 예정',
  };
}

String tileSealEffectText(TileSeal seal) {
  return switch (seal) {
    TileSeal.blueSeal => '확정 족보 성장 +1',
    TileSeal.redSeal => '타일 효과 1회 재발동',
  };
}

Color tileEnhancementColor(TileEnhancement enhancement) {
  return switch (enhancement) {
    TileEnhancement.chipInlaid => GameUiPalette.tileChipInlaid,
    TileEnhancement.scoreGilded => GameUiPalette.tileScoreGilded,
    TileEnhancement.goldTile => GameUiPalette.actionGoldBright,
    TileEnhancement.glassTile => GameUiPalette.tileGlass,
    TileEnhancement.wildPainted => GameUiPalette.tileWild,
    TileEnhancement.luckyTile => GameUiPalette.tileLucky,
  };
}

Color tileSealColor(TileSeal seal) {
  return switch (seal) {
    TileSeal.blueSeal => GameUiPalette.tileBlueSeal,
    TileSeal.redSeal => GameUiPalette.tileRedSeal,
  };
}

class _GameRummiTilePainter extends CustomPainter {
  const _GameRummiTilePainter({
    required this.tile,
    required this.selected,
    required this.accent,
  });

  final Tile tile;
  final bool selected;
  final bool accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    paintRummikubTile(
      canvas,
      rect,
      tile,
      selected: selected,
      shadowElevation: selected ? 4 : 2.4,
    );

    if (!accent) return;
    final accentRect = rect.deflate(3.5);
    final rr = RRect.fromRectAndRadius(
      accentRect,
      Radius.circular(size.shortestSide * 0.11),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = GameUiPalette.actionGoldBright.withValues(alpha: 0.75),
    );
  }

  @override
  bool shouldRepaint(covariant _GameRummiTilePainter oldDelegate) {
    return oldDelegate.tile != tile ||
        oldDelegate.selected != selected ||
        oldDelegate.accent != accent;
  }
}
