part of '../game_view.dart';

class _FateLineSelectionBarrier extends StatefulWidget {
  const _FateLineSelectionBarrier({required this.boardKey});

  final GlobalKey boardKey;

  @override
  State<_FateLineSelectionBarrier> createState() =>
      _FateLineSelectionBarrierState();
}

class _FateLineSelectionBarrierState extends State<_FateLineSelectionBarrier> {
  Rect? _boardRect;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncBoardRect());
    return LayoutBuilder(
      builder: (context, constraints) {
        final frameHeight = constraints.maxHeight;
        final boardRect = _boardRect;
        if (boardRect == null || boardRect.isEmpty) {
          return const GameInputBarrier.modal();
        }
        final topHeight = math.max(0.0, boardRect.top);
        final bottomTop = boardRect.bottom;
        return Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              height: topHeight,
              child: const GameInputBarrier.modal(),
            ),
            Positioned(
              left: 0,
              top: bottomTop,
              right: 0,
              height: math.max(0.0, frameHeight - bottomTop),
              child: const GameInputBarrier.modal(),
            ),
          ],
        );
      },
    );
  }

  void _syncBoardRect() {
    if (!mounted) return;
    final rootBox = context.findRenderObject();
    final boardContext = widget.boardKey.currentContext;
    final boardBox = boardContext?.findRenderObject();
    if (rootBox is! RenderBox ||
        boardBox is! RenderBox ||
        !rootBox.attached ||
        !boardBox.attached) {
      return;
    }
    final nextRect =
        boardBox.localToGlobal(Offset.zero, ancestor: rootBox) & boardBox.size;
    if (_boardRect == nextRect) return;
    setState(() => _boardRect = nextRect);
  }
}

class _FateBoardLineSelectionLayer extends StatefulWidget {
  const _FateBoardLineSelectionLayer({
    required this.boardKey,
    required this.selection,
    required this.onTapLine,
    required this.onTapTile,
  });

  final GlobalKey boardKey;
  final _FateLineSelection selection;
  final ValueChanged<RummiScoringLineSummary> onTapLine;
  final ValueChanged<GameBoardTileSelectionTarget> onTapTile;

  @override
  State<_FateBoardLineSelectionLayer> createState() =>
      _FateBoardLineSelectionLayerState();
}

class _FateBoardLineSelectionLayerState
    extends State<_FateBoardLineSelectionLayer> {
  Rect? _boardRect;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncBoardRect());
    return LayoutBuilder(
      builder: (context, constraints) {
        final frameRect = Rect.fromLTWH(
          0,
          0,
          constraints.maxWidth,
          constraints.maxHeight,
        );
        final gridRect = _boardRect
            ?.deflate(kBoardFrameInset)
            .intersect(frameRect);
        if (gridRect == null || gridRect.isEmpty) {
          return const SizedBox.shrink();
        }
        return Stack(
          children: [
            Positioned.fromRect(
              rect: gridRect,
              child: widget.selection.needsTileTarget
                  ? GameBoardTileSelectionOverlay(
                      targets: widget.selection.tileTargets,
                      selectedLineRef: widget.selection.selectedLine?.ref,
                      selectedTileIndex: widget.selection.selectedTileIndex,
                      onTapTile: widget.onTapTile,
                    )
                  : GameBoardLineSelectionOverlay(
                      lines: widget.selection.lines,
                      selectedLineRef: widget.selection.selectedLine?.ref,
                      onTapLine: widget.onTapLine,
                    ),
            ),
          ],
        );
      },
    );
  }

  void _syncBoardRect() {
    if (!mounted) return;
    final rootBox = context.findRenderObject();
    final boardContext = widget.boardKey.currentContext;
    final boardBox = boardContext?.findRenderObject();
    if (rootBox is! RenderBox ||
        boardBox is! RenderBox ||
        !rootBox.attached ||
        !boardBox.attached) {
      return;
    }
    final nextRect =
        boardBox.localToGlobal(Offset.zero, ancestor: rootBox) & boardBox.size;
    if (_boardRect == nextRect) return;
    setState(() => _boardRect = nextRect);
  }
}
