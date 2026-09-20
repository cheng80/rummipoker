part of '../game_view.dart';

class _FateLineSelection {
  const _FateLineSelection({
    required this.slot,
    required this.lines,
    this.selectedLine,
    this.selectedTileIndex,
  });

  final RummiBattleItemSlotView slot;
  String displayName(BuildContext context) => ItemTranslationScope.of(
    context,
  ).resolveDisplayName(slot.contentId, slot.displayName);
  final List<RummiScoringLineSummary> lines;
  final RummiScoringLineSummary? selectedLine;
  final int? selectedTileIndex;

  bool get needsTileTarget => slot.item.effect.value('target') == 'tile';

  Tile? get selectedTile {
    final line = selectedLine;
    final index = selectedTileIndex;
    if (line == null || index == null) return null;
    if (index < 0 || index >= line.scoringTiles.length) return null;
    return line.scoringTiles[index];
  }

  List<GameBoardTileSelectionTarget> get tileTargets {
    final targets = <GameBoardTileSelectionTarget>[];
    for (final line in lines) {
      final maxCount = math.min(
        line.scoringTiles.length,
        line.contributingCells.length,
      );
      for (var i = 0; i < maxCount; i += 1) {
        final tile = line.scoringTiles[i];
        final cell = line.contributingCells[i];
        if (!_isValidRitualTileTarget(slot.item, line, tile, cell)) continue;
        targets.add(
          GameBoardTileSelectionTarget(
            line: line,
            tileIndex: i,
            cell: cell,
            tile: tile,
          ),
        );
      }
    }
    return List<GameBoardTileSelectionTarget>.unmodifiable(targets);
  }

  _FateLineSelection copyWith({
    RummiScoringLineSummary? selectedLine,
    int? selectedTileIndex,
  }) {
    return _FateLineSelection(
      slot: slot,
      lines: lines,
      selectedLine: selectedLine ?? this.selectedLine,
      selectedTileIndex: selectedTileIndex == -1
          ? null
          : selectedTileIndex ?? this.selectedTileIndex,
    );
  }
}

class _FateLineSelectionPanel extends StatelessWidget {
  const _FateLineSelectionPanel({
    required this.selection,
    required this.onConfirm,
    required this.onCancel,
  });

  final _FateLineSelection selection;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final selectedLine = selection.selectedLine;
    final selectedTile = selection.selectedTile;
    final previewText = selectedLine == null
        ? selection.needsTileTarget
              ? context.translate('battlePickOutlinedTile')
              : context.translate('battlePickOutlinedLine')
        : _ritualSelectionPreviewText(
            context,
            selection.slot.item,
            selectedLine,
            selectedTile,
          );
    final targetText = selectedLine == null
        ? context.translate('battleNoSelection')
        : selection.needsTileTarget
        ? context.translate(
            'battleSelectedLineTile',
            namedArgs: {
              'line': _lineLabel(context, selectedLine.ref),
              'tile':
                  selectedTile?.code ?? context.translate('battleTileRequired'),
            },
          )
        : context.translate(
            'battleSelectedLineSummary',
            namedArgs: {
              'line': _lineLabel(context, selectedLine.ref),
              'rank': _rankLabel(context, selectedLine),
              'count': '${selectedLine.occupiedCount}',
            },
          );
    final confirmEnabled =
        selectedLine != null &&
        (!selection.needsTileTarget || selectedTile != null);
    final confirmLabel = _isFateLineTransformDefinition(selection.slot.item)
        ? context.translate('battleTransform')
        : context.translate('ok');
    final countText = selection.needsTileTarget
        ? context.translate(
            'battleTargetTileCount',
            namedArgs: {'count': '${selection.tileTargets.length}'},
          )
        : context.translate(
            'battleTargetLineCount',
            namedArgs: {'count': '${selection.lines.length}'},
          );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiPalette.surfaceModalInner,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: GameUiPalette.userSelection.withValues(alpha: 0.72),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: GameUiPalette.ink.withValues(alpha: 0.34),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    selection.displayName(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GameUiPalette.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  countText,
                  style: const TextStyle(
                    color: GameUiPalette.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              targetText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: GameUiPalette.userSelection,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            SemanticText(
              previewText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: GameUiPalette.textPrimary,
                fontSize: 11.5,
                height: 1.18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: withButtonSound(onCancel),
                  child: Text(context.translate('cancel')),
                ),
                const SizedBox(width: 6),
                FilledButton(
                  key: const ValueKey('fate-line-confirm-button'),
                  onPressed: confirmEnabled ? onConfirm : null,
                  child: Text(confirmLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
