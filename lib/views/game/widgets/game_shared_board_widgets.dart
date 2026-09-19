part of 'game_shared_widgets.dart';

/// 교차 타일이 맞을수록 달아오르는 색.
const Color _kOverlapHeatColor = Color(0xFFFF8A3D);

Tile? _boardTileAtKey(RummiBoard board, String cellKey) {
  final (row, col) = _parseBoardCellKey(cellKey);
  return board.cellAt(row, col);
}

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
    this.settlementTileHeat = const {},
    this.settlementTileHitSerial = const {},
    this.dealOnEnter = false,
    this.showLineHints = false,
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

  /// 한 확정 안에서 여러 줄에 기여한 교차 타일이 맞은 횟수. 달아오름 표시에 쓴다.
  final Map<String, int> settlementTileHeat;

  /// 정산 tick이 칸을 마지막으로 친 순번. 바뀌면 그 칸이 튕긴다.
  final Map<String, int> settlementTileHitSerial;

  /// 처음 그릴 때 타일과 Boss 표시가 짧은 stagger로 깔린다(전투 진입).
  final bool dealOnEnter;

  /// 지금 확정하면 점수가 나는 줄을 숨쉬듯 비추고, 한 칸 남은 줄에 희미한 힌트를 준다.
  final bool showLineHints;
  final void Function(int row, int col) onTapCell;
  final ValueChanged<Tile> onLongPressTile;
  final AlignmentGeometry alignment;

  @override
  State<GameBoardGrid> createState() => _GameBoardGridState();
}

class _GameBoardGridState extends State<GameBoardGrid>
    with SingleTickerProviderStateMixin {
  late Map<String, String?> _previousTileKeys;
  late Map<String, Tile?> _previousTiles;
  Set<String> _appearingCells = const {};
  _BoardMoveFlight? _moveFlight;
  _BoardRemoveFlight? _removeFlight;
  int _moveFlightTick = 0;
  int _removeFlightTick = 0;
  _ContributorClear? _contributorClear;
  int _contributorClearTick = 0;
  int _boardWobbleSerial = 0;
  final List<Timer> _clearTimers = [];
  final Map<String, int> _rippleSerial = {};
  final List<Timer> _rippleTimers = [];
  late final AnimationController _dealController;

  @override
  void initState() {
    super.initState();
    _previousTileKeys = _tileKeysForBoard(widget.board);
    _previousTiles = _tilesForBoard(widget.board);
    final deal = widget.dealOnEnter && !MotionPolicy.reduceMotion;
    _dealController = AnimationController(
      vsync: this,
      duration:
          GamePresentationTimings.battleEntryDeal +
          GamePresentationTimings.battleEntryStagger *
              (kBoardSize * kBoardSize),
      value: deal ? 0 : 1,
    );
    if (deal) _dealController.forward();
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
    _startContributorClearIfNeeded(oldWidget);
    if (appearedCells.length == 1 && _moveFlight == null) {
      _startLandingRipple(appearedCells.single);
    }
    _emitSettlementHitSparks(oldWidget);
    _previousTileKeys = currentTileKeys;
    _previousTiles = _tilesForBoard(widget.board);
    _appearingCells = _moveFlight == null
        ? appearingCells
        : appearingCells.difference({_moveFlight!.toCellKey});
  }

  @override
  void dispose() {
    for (final timer in [..._clearTimers, ..._rippleTimers]) {
      timer.cancel();
    }
    _dealController.dispose();
    super.dispose();
  }

  /// 확정 뒤 snapshot이 비워질 때 사라지는 contributor 타일을 줄 방향으로 터뜨린다.
  ///
  /// 보드 state는 이미 갱신되어 있고 overlay는 입력을 막지 않는다.
  void _startContributorClearIfNeeded(GameBoardGrid oldWidget) {
    if (oldWidget.settlementBoardSnapshot.isEmpty ||
        widget.settlementBoardSnapshot.isNotEmpty) {
      return;
    }
    final cleared = <(String, Tile)>[
      for (final entry in oldWidget.settlementBoardSnapshot.entries)
        if (_boardTileAtKey(widget.board, entry.key) == null)
          (entry.key, entry.value),
    ];
    if (cleared.isEmpty || MotionPolicy.juiceScale <= 0) return;
    final tick = ++_contributorClearTick;
    _boardWobbleSerial++;
    _contributorClear = _ContributorClear(tick: tick, tiles: cleared);
    for (final timer in _clearTimers) {
      timer.cancel();
    }
    _clearTimers.clear();
    const stagger = GamePresentationTimings.contributorClearStagger;
    final popAt = GamePresentationTimings.contributorClearPop * 0.4;
    for (var i = 0; i < cleared.length; i++) {
      final key = cleared[i].$1;
      _clearTimers.add(
        Timer(stagger * i + popAt, () {
          if (!mounted) return;
          final center = _cellCenter(key);
          if (center == null) return;
          Fx.emit(context, FxPresets.shards, [center]);
        }),
      );
    }
    final total =
        stagger * cleared.length +
        GamePresentationTimings.contributorClearPop +
        GamePresentationTimings.contributorClearAfterglow;
    _clearTimers.add(
      Timer(total, () {
        if (!mounted || _contributorClear?.tick != tick) return;
        setState(() => _contributorClear = null);
      }),
    );
  }

  /// 타일이 착지하면 주변 타일이 거리순으로 20~30ms 간격 파문을 탄다.
  void _startLandingRipple(String cellKey) {
    if (MotionPolicy.juiceScale <= 0) return;
    final (row, col) = _parseBoardCellKey(cellKey);
    final landing = GamePresentationTimings.boardTilePlacePop * 0.45;
    for (var r = 0; r < kBoardSize; r++) {
      for (var c = 0; c < kBoardSize; c++) {
        final distance = (r - row).abs() + (c - col).abs();
        if (distance == 0 || distance > 2) continue;
        if (widget.board.cellAt(r, c) == null) continue;
        final key = '$r:$c';
        _rippleTimers.add(
          Timer(
            landing + GamePresentationTimings.landingRippleStagger * distance,
            () {
              if (!mounted) return;
              setState(
                () => _rippleSerial[key] = (_rippleSerial[key] ?? 0) + 1,
              );
            },
          ),
        );
      }
    }
    _rippleTimers.removeWhere((timer) => !timer.isActive);
  }

  /// 진입 deal에서 [index]번째 칸의 진행도(0~1).
  double _dealProgress(int index) {
    if (_dealController.isCompleted) return 1;
    final elapsed = _dealController.duration! * _dealController.value;
    final local =
        (elapsed - GamePresentationTimings.battleEntryStagger * index)
            .inMicroseconds /
        GamePresentationTimings.battleEntryDeal.inMicroseconds;
    return local.clamp(0.0, 1.0);
  }

  /// 정산 tick으로 새로 맞은 칸에서 불꽃을 튀긴다. 교차 타일은 맞을수록 크게.
  void _emitSettlementHitSparks(GameBoardGrid oldWidget) {
    final hits = <String>[
      for (final entry in widget.settlementTileHitSerial.entries)
        if (oldWidget.settlementTileHitSerial[entry.key] != entry.value)
          entry.key,
    ];
    if (hits.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final key in hits) {
        final center = _cellCenter(key);
        if (center == null) continue;
        final heat = widget.settlementTileHeat[key] ?? 0;
        Fx.emit(
          context,
          heat > 1
              ? FxPresets.burst.copyWith(
                  color: _kOverlapHeatColor,
                  count: 10 + 6 * heat,
                )
              : FxPresets.sparks.copyWith(count: 6),
          [center],
        );
      }
    });
  }

  /// 네 칸이 찼고 한 칸만 빈 줄의 빈 칸. 이미 점수 줄에 든 칸은 뺀다.
  Set<String> _nearCompleteCells() {
    final refs = [
      for (var i = 0; i < kBoardSize; i++) LineRef.row(i),
      for (var i = 0; i < kBoardSize; i++) LineRef.col(i),
      LineRef.diagMain,
      LineRef.diagAnti,
    ];
    final out = <String>{};
    for (final ref in refs) {
      final cells = ref.cells();
      final empty = [
        for (final (r, c) in cells)
          if (widget.board.cellAt(r, c) == null) '$r:$c',
      ];
      if (empty.length != 1) continue;
      final key = empty.single;
      if (widget.blockedCellKeys.contains(key)) continue;
      final alreadyScoring = cells.every(
        (cell) => widget.scoringCells.contains('${cell.$1}:${cell.$2}'),
      );
      if (!alreadyScoring) out.add(key);
    }
    return out;
  }

  Offset? _cellCenter(String cellKey) {
    final size = context.size;
    if (size == null || size.isEmpty) return null;
    final side = min(size.width, size.height);
    final inner = side - kBoardFrameInset * 2;
    final cell = (inner - kBoardGridGap * (kBoardSize - 1)) / kBoardSize;
    final (row, col) = _parseBoardCellKey(cellKey);
    final origin = Offset(
      (size.width - side) / 2 + kBoardFrameInset,
      (size.height - side) / 2 + kBoardFrameInset,
    );
    return origin +
        Offset(
          col * (cell + kBoardGridGap) + cell / 2,
          row * (cell + kBoardGridGap) + cell / 2,
        );
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
                        final heat = widget.settlementTileHeat[cellKey] ?? 0;
                        if (heat > 0) {
                          child = FxBoxGlow(
                            key: ValueKey('board-cell-heat-$row-$col-$heat'),
                            color: _kOverlapHeatColor.withValues(
                              alpha: min(0.85, 0.3 + 0.2 * heat),
                            ),
                            blurRadius: 8 + 4.0 * heat,
                            spreadRadius: 1.0 * heat,
                            child: child,
                          );
                        }
                        child = Juice(
                          trigger: (_boardWobbleSerial, _rippleSerial[cellKey]),
                          strength: 0.35,
                          child: Juice(
                            trigger: widget.settlementTileHitSerial[cellKey],
                            strength: heat > 0 ? 0.9 + 0.45 * heat : 0.7,
                            child: child,
                          ),
                        );
                        if (!_dealController.isCompleted &&
                            (tile != null || placementBlocked)) {
                          child = AnimatedBuilder(
                            animation: _dealController,
                            child: child,
                            builder: (context, child) {
                              final t = Curves.easeOutBack.transform(
                                _dealProgress(index),
                              );
                              return Transform.translate(
                                offset: Offset(0, -24 * (1 - t)),
                                child: Transform.scale(
                                  scale: 0.6 + 0.4 * t,
                                  child: child,
                                ),
                              );
                            },
                          );
                        }
                        if (!_appearingCells.contains(cellKey)) {
                          return child;
                        }
                        return _BoardPlacePop(child: child);
                      },
                    ),
                    if (widget.showLineHints &&
                        !widget.boardMoveMode &&
                        widget.activeSettlementCells.isEmpty)
                      Positioned.fill(
                        child: _BoardLineHintLayer(
                          scoringCells: widget.scoringCells,
                          nearCells: _nearCompleteCells(),
                        ),
                      ),
                    if (_contributorClear != null)
                      _ContributorClearOverlay(clear: _contributorClear!),
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
                child: FxBoxGlow(
                  color: const Color(0xFFFFD86B).withValues(alpha: 0.48 * wave),
                  blurRadius: 18 * wave,
                  spreadRadius: 2.5 * wave,
                  child: FxBoxGlow(
                    color: const Color(
                      0xFF80F7CA,
                    ).withValues(alpha: 0.35 * wave),
                    blurRadius: 22 * wave,
                    spreadRadius: 1.5 * wave,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(
                            0xFFFFD86B,
                          ).withValues(alpha: 0.95 * fade),
                          width: 2 + (1.5 * wave),
                        ),
                      ),
                    ),
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

/// `MaskFilter.blur` 없이 번진 stroke를 그린다.
///
/// ponytail: blur 대신 폭을 넓힌 반투명 stroke 3장을 겹쳐 가우시안 번짐을
/// 근사한다. 번짐이 더 부드러워야 하면 구운 링 스프라이트로 바꾼다.
void _paintGlowStroke(
  Canvas canvas,
  RRect rrect, {
  required Color color,
  required double strokeWidth,
  required double sigma,
}) {
  if (color.a <= 0) return;
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round;
  const spreads = [2.0, 1.2, 0.4];
  const weights = [0.2, 0.32, 0.5];
  for (var i = 0; i < spreads.length; i++) {
    paint
      ..color = color.withValues(alpha: color.a * weights[i])
      ..strokeWidth = strokeWidth + 2 * spreads[i] * sigma;
    canvas.drawRRect(rrect, paint);
  }
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
      _paintGlowStroke(
        canvas,
        rrect,
        color: color.withValues(alpha: selected ? 0.24 : 0.12),
        strokeWidth: selected ? 8 : 5,
        sigma: 4,
      );
      canvas.drawRRect(rrect, stroke);
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
        _paintGlowStroke(
          canvas,
          rrect,
          color: color.withValues(alpha: selected ? 0.20 : 0.10),
          strokeWidth: selected ? 8 : 5,
          sigma: 4,
        );
        canvas.drawRRect(rrect, stroke);
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
      canvas.drawRRect(rrect, fill);
      _paintGlowStroke(
        canvas,
        rrect,
        color: GameUiPalette.userSelection.withValues(alpha: 0.72 * fade),
        strokeWidth: 9 + 7 * wave,
        sigma: 8 * wave,
      );
      canvas.drawRRect(rrect, core);
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

/// 손패 쪽(아래)에서 호를 그리며 들어와 착지할 때 눌렸다 펴진다.
class _BoardPlacePop extends StatelessWidget {
  const _BoardPlacePop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('board-place-pop'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.boardTilePlacePop,
      builder: (context, value, child) {
        final progress = value.clamp(0.0, 1.0);
        // 0~0.45 비행(아래에서 위로, 옆으로 살짝 휘며), 이후 착지 찌그러짐.
        final flight = Curves.easeOutCubic.transform(
          (progress / 0.45).clamp(0.0, 1.0),
        );
        final travel = 34 * (1 - flight);
        final sway = 8 * sin(pi * flight);
        final landing = progress < 0.45
            ? 0.0
            : sin(pi * ((progress - 0.45) / 0.55)) * (1 - progress) * 2;
        final glow = 0.24 * (1 - progress);
        return Transform.translate(
          key: const ValueKey('board-place-flight'),
          offset: Offset(sway, travel),
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..scaleByDouble(
                (0.86 + 0.14 * flight) * (1 + 0.1 * landing),
                (0.86 + 0.14 * flight) * (1 - 0.12 * landing),
                1,
                1,
              ),
            child: FxBoxGlow(
              color: const Color(0xFFF2C14E).withValues(alpha: glow),
              blurRadius: 16 * (glow / 0.24),
              spreadRadius: 1.5 * (glow / 0.24),
              child: child!,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// 점수 줄 예고: 3번 숨쉬듯 빛난 뒤 은은하게 멈춘다. 한 칸 남은 줄은 빈 칸에 희미한 테두리만.
class _BoardLineHintLayer extends StatelessWidget {
  const _BoardLineHintLayer({
    required this.scoringCells,
    required this.nearCells,
  });

  final Set<String> scoringCells;
  final Set<String> nearCells;

  @override
  Widget build(BuildContext context) {
    if (scoringCells.isEmpty && nearCells.isEmpty) {
      return const SizedBox.shrink();
    }
    const breath = GamePresentationTimings.lineHintBreath;
    const cycles = GamePresentationTimings.lineHintBreathCycles;
    final signature = ([...scoringCells]..sort()).join('|');
    return IgnorePointer(
      child: RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          key: ValueKey('board-line-hint-$signature'),
          tween: Tween<double>(begin: 0, end: 1),
          duration: MotionPolicy.reduceMotion ? Duration.zero : breath * cycles,
          builder: (context, t, _) {
            // 끝나면 0.5 밝기로 멈춘다. 반복 루프를 두지 않는다.
            final phase = t >= 1 ? 0.5 : 0.5 - 0.5 * cos(2 * pi * cycles * t);
            return CustomPaint(
              key: const ValueKey('board-line-hint'),
              painter: _BoardLineHintPainter(
                scoringCells: scoringCells,
                nearCells: nearCells,
                pulse: phase,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BoardLineHintPainter extends CustomPainter {
  const _BoardLineHintPainter({
    required this.scoringCells,
    required this.nearCells,
    required this.pulse,
  });

  final Set<String> scoringCells;
  final Set<String> nearCells;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final metric = _BoardLineOverlayMetric(size);
    for (final key in scoringCells) {
      final (row, col) = _parseBoardCellKey(key);
      final rrect = RRect.fromRectAndRadius(
        metric.rectFor(row, col).deflate(1),
        Radius.circular(metric.cellCornerRadius),
      );
      _paintGlowStroke(
        canvas,
        rrect,
        color: GameUiPalette.scoringPreview.withValues(
          alpha: 0.18 + 0.4 * pulse,
        ),
        strokeWidth: 2,
        sigma: 3 + 3 * pulse,
      );
    }
    final faint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = GameUiPalette.scoringPreview.withValues(alpha: 0.32);
    for (final key in nearCells) {
      final (row, col) = _parseBoardCellKey(key);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          metric.rectFor(row, col).deflate(5),
          Radius.circular(metric.cellCornerRadius),
        ),
        faint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BoardLineHintPainter oldDelegate) =>
      oldDelegate.pulse != pulse ||
      oldDelegate.scoringCells != scoringCells ||
      oldDelegate.nearCells != nearCells;
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
      child: GameStampIn(
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
      ),
    );
  }
}

/// Boss 제약 표시가 처음 나타날 때 도장처럼 크게 찍혔다 자리 잡는다.
class GameStampIn extends StatelessWidget {
  const GameStampIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // T4: Boss 인트로 배너가 닫히기 전에는 숨겼다가, 풀리는 순간 도장을 찍는다.
    if (GameBossMarkVeil.hiddenOf(context)) {
      return Opacity(opacity: 0, child: child);
    }
    if (MotionPolicy.juiceScale <= 0) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: GamePresentationTimings.bossMarkStamp,
      curve: Curves.easeOutBack,
      builder: (context, t, child) =>
          Transform.scale(scale: 1.9 - 0.9 * t, child: child),
      child: child,
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
          child: GameStampIn(
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
                        color: GameUiPalette.textPrimary.withValues(
                          alpha: 0.96,
                        ),
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
          ),
        );
      },
    );
  }
}
