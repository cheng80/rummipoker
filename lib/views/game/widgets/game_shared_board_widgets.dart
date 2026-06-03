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
    this.blockedCellKeys = const {},
    this.lineSelectionLines = const [],
    this.selectedLineRef,
    this.onTapLine,
    this.lineFlashRef,
    this.lineFlashTick = 0,
    this.bonusFlashCellKey,
    this.bonusFlashTick = 0,
    this.alignment = Alignment.center,
  });

  final RummiBoard board;
  final Set<String> scoringCells;
  final Set<String> constrainedScoringCells;
  final Set<String> constrainedCells;
  final Set<String> blockedCellKeys;
  final List<RummiScoringLineSummary> lineSelectionLines;
  final LineRef? selectedLineRef;
  final ValueChanged<RummiScoringLineSummary>? onTapLine;
  final LineRef? lineFlashRef;
  final int lineFlashTick;
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
                        final placementBlocked = widget.blockedCellKeys
                            .contains(cellKey);
                        final settlementActive = widget.activeSettlementCells
                            .contains(cellKey);
                        final isMoveSource =
                            widget.boardMoveMode &&
                            widget.moveSourceRow == row &&
                            widget.moveSourceCol == col;
                        final isMoveAvailable =
                            widget.boardMoveMode &&
                            tile == null &&
                            !placementBlocked;
                        final isMoveLocked =
                            widget.boardMoveMode &&
                            (placementBlocked ||
                                (tile != null && !isMoveSource));
                        Widget child = GameBoardCell(
                          key: ValueKey('board-cell-$row-$col'),
                          tile: tile,
                          selected: selected,
                          scoring: scoring,
                          constrainedScoring: constrainedScoring,
                          constrained: constrained,
                          placementBlocked: placementBlocked,
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
                    if (widget.lineFlashRef != null && widget.lineFlashTick > 0)
                      Positioned.fill(
                        child: _BoardLineFlashOverlay(
                          lineRef: widget.lineFlashRef!,
                          tick: widget.lineFlashTick,
                        ),
                      ),
                    if (widget.onTapLine != null &&
                        widget.lineSelectionLines.isNotEmpty)
                      Positioned.fill(
                        child: GameBoardLineSelectionOverlay(
                          lines: widget.lineSelectionLines,
                          selectedLineRef: widget.selectedLineRef,
                          onTapLine: widget.onTapLine!,
                        ),
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

class GameBoardLineSelectionOverlay extends StatelessWidget {
  const GameBoardLineSelectionOverlay({
    super.key,
    required this.lines,
    required this.selectedLineRef,
    required this.onTapLine,
  });

  final List<RummiScoringLineSummary> lines;
  final LineRef? selectedLineRef;
  final ValueChanged<RummiScoringLineSummary> onTapLine;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        RummiScoringLineSummary? lineAt(Offset localPosition) {
          final metric = _BoardLineOverlayMetric(
            Size(constraints.maxWidth, constraints.maxHeight),
          );
          RummiScoringLineSummary? closestLine;
          var closestDistance = double.infinity;
          for (final line in lines) {
            final cells = line.ref.cells();
            final start = metric.centerFor(cells.first.$1, cells.first.$2);
            final end = metric.centerFor(cells.last.$1, cells.last.$2);
            final distance = _distanceToSegment(localPosition, start, end);
            if (distance < closestDistance) {
              closestDistance = distance;
              closestLine = line;
            }
          }
          return closestDistance <= metric.tapTolerance ? closestLine : null;
        }

        return GestureDetector(
          key: const ValueKey('fate-line-selection-overlay'),
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final line = lineAt(details.localPosition);
            if (line != null) onTapLine(line);
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _BoardLineSelectionPainter(
                    lines,
                    selectedLineRef: selectedLineRef,
                  ),
                ),
              ),
              for (final line in lines)
                Positioned.fromRect(
                  rect: _lineMarkerRect(
                    line.ref,
                    Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                  child: GestureDetector(
                    key: ValueKey(
                      'fate-line-selection-'
                      '${line.ref == selectedLineRef ? 'selected' : 'candidate'}-'
                      '${_lineRefTestKey(line.ref)}',
                    ),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTapLine(line),
                    child: const SizedBox.expand(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class GameBoardTileSelectionTarget {
  const GameBoardTileSelectionTarget({
    required this.line,
    required this.tileIndex,
    required this.cell,
    required this.tile,
  });

  final RummiScoringLineSummary line;
  final int tileIndex;
  final (int, int) cell;
  final Tile tile;
}

class GameBoardTileSelectionOverlay extends StatelessWidget {
  const GameBoardTileSelectionOverlay({
    super.key,
    required this.targets,
    required this.selectedLineRef,
    required this.selectedTileIndex,
    required this.onTapTile,
  });

  final List<GameBoardTileSelectionTarget> targets;
  final LineRef? selectedLineRef;
  final int? selectedTileIndex;
  final ValueChanged<GameBoardTileSelectionTarget> onTapTile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        GameBoardTileSelectionTarget? targetAt(Offset localPosition) {
          final metric = _BoardLineOverlayMetric(
            Size(constraints.maxWidth, constraints.maxHeight),
          );
          GameBoardTileSelectionTarget? closestTarget;
          var closestDistance = double.infinity;
          for (final target in targets) {
            final (row, col) = target.cell;
            final rect = metric
                .rectFor(row, col)
                .inflate(metric.tapTolerance * 0.2);
            if (!rect.contains(localPosition)) continue;
            final distance =
                (metric.centerFor(row, col) - localPosition).distance;
            if (distance < closestDistance) {
              closestDistance = distance;
              closestTarget = target;
            }
          }
          return closestTarget;
        }

        return GestureDetector(
          key: const ValueKey('fate-tile-selection-overlay'),
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final target = targetAt(details.localPosition);
            if (target != null) onTapTile(target);
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _BoardTileSelectionPainter(
                    targets,
                    selectedLineRef: selectedLineRef,
                    selectedTileIndex: selectedTileIndex,
                  ),
                ),
              ),
              for (final target in targets)
                Positioned.fromRect(
                  rect: _tileMarkerRect(
                    target.cell,
                    Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                  child: GestureDetector(
                    key: ValueKey(
                      'fate-tile-selection-'
                      '${target.line.ref == selectedLineRef && target.tileIndex == selectedTileIndex ? 'selected' : 'candidate'}-'
                      '${_lineRefTestKey(target.line.ref)}-${target.tileIndex}',
                    ),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTapTile(target),
                    child: const SizedBox.expand(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BoardLineFlashOverlay extends StatelessWidget {
  const _BoardLineFlashOverlay({required this.lineRef, required this.tick});

  final LineRef lineRef;
  final int tick;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey('fate-line-transform-flash-${_lineRefTestKey(lineRef)}'),
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          key: ValueKey('fate-line-flash-$tick'),
          tween: Tween<double>(begin: 0, end: 1),
          duration: GamePresentationTimings.fateLineTransformFlash,
          curve: Curves.easeInOutQuart,
          builder: (context, value, _) {
            return CustomPaint(
              painter: _BoardLineFlashPainter(lineRef, progress: value),
            );
          },
        ),
      ),
    );
  }
}

String _lineRefTestKey(LineRef ref) => '${ref.kind.name}-${ref.index}';

Rect _lineMarkerRect(LineRef ref, Size size) {
  final metric = _BoardLineOverlayMetric(size);
  final cells = ref.cells();
  final start = metric.centerFor(cells.first.$1, cells.first.$2);
  final next = metric.centerFor(cells[1].$1, cells[1].$2);
  final center = Offset.lerp(start, next, 0.5)!;
  final side = metric.tapTolerance * 1.6;
  return Rect.fromCenter(center: center, width: side, height: side);
}

Rect _tileMarkerRect((int, int) cell, Size size) {
  final metric = _BoardLineOverlayMetric(size);
  return metric.rectFor(cell.$1, cell.$2).inflate(metric.tapTolerance * 0.1);
}

class _BoardTileSelectionPainter extends CustomPainter {
  const _BoardTileSelectionPainter(
    this.targets, {
    required this.selectedLineRef,
    required this.selectedTileIndex,
  });

  final List<GameBoardTileSelectionTarget> targets;
  final LineRef? selectedLineRef;
  final int? selectedTileIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final metric = _BoardLineOverlayMetric(size);
    for (final target in targets) {
      final selected =
          target.line.ref == selectedLineRef &&
          target.tileIndex == selectedTileIndex;
      final color = selected
          ? GameUiPalette.userSelection
          : GameUiPalette.tileBlueSeal;
      final glow = Paint()
        ..color = color.withValues(alpha: selected ? 0.24 : 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 8 : 5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      final stroke = Paint()
        ..color = color.withValues(alpha: selected ? 0.98 : 0.68)
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 4.4 : 2.6
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      final (row, col) = target.cell;
      final rect = metric.rectFor(row, col).deflate(selected ? 2 : 4);
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(metric.cellCornerRadius),
      );
      canvas
        ..drawRRect(rrect, glow)
        ..drawRRect(rrect, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _BoardTileSelectionPainter oldDelegate) {
    return oldDelegate.targets != targets ||
        oldDelegate.selectedLineRef != selectedLineRef ||
        oldDelegate.selectedTileIndex != selectedTileIndex;
  }
}

class _BoardLineSelectionPainter extends CustomPainter {
  const _BoardLineSelectionPainter(this.lines, {required this.selectedLineRef});

  final List<RummiScoringLineSummary> lines;
  final LineRef? selectedLineRef;

  @override
  void paint(Canvas canvas, Size size) {
    final metric = _BoardLineOverlayMetric(size);
    for (final line in lines) {
      final selected = line.ref == selectedLineRef;
      final cells = line.ref.cells();
      final color = selected
          ? GameUiPalette.userSelection
          : GameUiPalette.tileBlueSeal;
      final glow = Paint()
        ..color = color.withValues(alpha: selected ? 0.20 : 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 8 : 5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      final stroke = Paint()
        ..color = selected
            ? color.withValues(alpha: 0.96)
            : color.withValues(alpha: 0.58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 4.4 : 2.4
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      for (final (row, col) in cells) {
        final rect = metric.rectFor(row, col).deflate(selected ? 2 : 4);
        final rrect = RRect.fromRectAndRadius(
          rect,
          Radius.circular(metric.cellCornerRadius),
        );
        canvas
          ..drawRRect(rrect, glow)
          ..drawRRect(rrect, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardLineSelectionPainter oldDelegate) {
    return oldDelegate.lines != lines ||
        oldDelegate.selectedLineRef != selectedLineRef;
  }
}

class _BoardLineFlashPainter extends CustomPainter {
  const _BoardLineFlashPainter(this.lineRef, {required this.progress});

  final LineRef lineRef;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final metric = _BoardLineOverlayMetric(size);
    final cells = lineRef.cells();
    final wave = sin(pi * progress).clamp(0.0, 1.0);
    final fade = (1 - progress).clamp(0.0, 1.0);
    final reveal = progress < 0.36 ? progress / 0.36 : 1.0;
    final glow = Paint()
      ..color = GameUiPalette.userSelection.withValues(alpha: 0.72 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9 + 7 * wave
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * wave);
    final fill = Paint()
      ..color = GameUiPalette.userSelection.withValues(alpha: 0.12 * fade)
      ..style = PaintingStyle.fill;
    final core = Paint()
      ..color = GameUiPalette.actionGoldBright.withValues(alpha: 0.95 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final visibleCount = (cells.length * reveal).ceil().clamp(1, cells.length);
    for (final (row, col) in cells.take(visibleCount)) {
      final rect = metric.rectFor(row, col).deflate(2);
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(metric.cellCornerRadius),
      );
      canvas
        ..drawRRect(rrect, fill)
        ..drawRRect(rrect, glow)
        ..drawRRect(rrect, core);
    }
  }

  @override
  bool shouldRepaint(covariant _BoardLineFlashPainter oldDelegate) {
    return oldDelegate.lineRef != lineRef || oldDelegate.progress != progress;
  }
}

class _BoardLineOverlayMetric {
  const _BoardLineOverlayMetric(this.size);

  final Size size;

  double get _cellSide =>
      (size.shortestSide - kBoardGridGap * (kBoardSize - 1)) / kBoardSize;
  double get tapTolerance => max(18, _cellSide * 0.36);
  double get cellCornerRadius => max(8, _cellSide * 0.13);

  Offset centerFor(int row, int col) {
    return Offset(
      col * (_cellSide + kBoardGridGap) + _cellSide / 2,
      row * (_cellSide + kBoardGridGap) + _cellSide / 2,
    );
  }

  Rect rectFor(int row, int col) {
    return Rect.fromLTWH(
      col * (_cellSide + kBoardGridGap),
      row * (_cellSide + kBoardGridGap),
      _cellSide,
      _cellSide,
    );
  }
}

double _distanceToSegment(Offset point, Offset start, Offset end) {
  final dx = end.dx - start.dx;
  final dy = end.dy - start.dy;
  final lengthSquared = dx * dx + dy * dy;
  if (lengthSquared == 0) {
    return (point - start).distance;
  }
  final t =
      (((point.dx - start.dx) * dx + (point.dy - start.dy) * dy) /
              lengthSquared)
          .clamp(0.0, 1.0);
  final projection = Offset(start.dx + t * dx, start.dy + t * dy);
  return (point - projection).distance;
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
    required this.placementBlocked,
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
  final bool placementBlocked;
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
        : placementBlocked
        ? GameUiPalette.bossWeakenPreview
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
                    : placementBlocked
                    ? GameUiPalette.surfaceDangerDeep.withValues(alpha: 0.76)
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
                  ? placementBlocked
                        ? GameBoardBlockedCellBadge(side: side)
                        : moveAvailable
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

class GameBoardBlockedCellBadge extends StatelessWidget {
  const GameBoardBlockedCellBadge({super.key, required this.side});

  final double side;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Text(
          'X',
          maxLines: 1,
          style: TextStyle(
            color: GameUiPalette.bossWeakenPreview.withValues(alpha: 0.96),
            fontSize: side * 0.58,
            fontWeight: FontWeight.w900,
            height: 0.9,
            shadows: [
              Shadow(
                color: GameUiPalette.ink.withValues(alpha: 0.72),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
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
