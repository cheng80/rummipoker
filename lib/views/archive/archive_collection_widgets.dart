part of '../archive_view.dart';

enum _ArchiveCollectionStatus {
  undiscovered('미발견', GameUiPalette.archiveUndiscovered),
  discovered('발견', GameUiPalette.archiveDiscovered),
  acquired('획득', GameUiPalette.gameOverRewardAccent),
  cleared('클리어', GameUiPalette.archiveCleared);

  const _ArchiveCollectionStatus(this.label, this.color);

  final String label;
  final Color color;
}

_ArchiveCollectionStatus _jesterStatus(
  String id, {
  required Set<String> seenIds,
  required Set<String> boughtIds,
}) {
  if (boughtIds.contains(id)) return _ArchiveCollectionStatus.acquired;
  if (seenIds.contains(id)) return _ArchiveCollectionStatus.discovered;
  return _ArchiveCollectionStatus.undiscovered;
}

_ArchiveCollectionStatus _itemStatus(
  String id, {
  required Set<String> seenIds,
  required Set<String> boughtIds,
}) {
  if (boughtIds.contains(id)) return _ArchiveCollectionStatus.acquired;
  if (seenIds.contains(id)) return _ArchiveCollectionStatus.discovered;
  return _ArchiveCollectionStatus.undiscovered;
}

_ArchiveCollectionStatus _memoryCardStatus(
  _ArchiveMemoryCardDefinition card, {
  required bool collected,
}) {
  if (!collected) return _ArchiveCollectionStatus.undiscovered;
  if (card.id.contains('_completed_')) {
    return _ArchiveCollectionStatus.cleared;
  }
  return _ArchiveCollectionStatus.acquired;
}

class _ArchiveCollectionSection extends StatelessWidget {
  const _ArchiveCollectionSection({
    required this.title,
    required this.collectedCount,
    required this.totalCount,
    required this.child,
  });

  final String title;
  final int collectedCount;
  final int totalCount;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: GameUiPalette.ink.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: GameUiPalette.textPrimary.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ArchiveCountUp(
            value: collectedCount,
            builder: (shown) => Text(
              '$title $shown/$totalCount',
              style: TextStyle(
                color: GameUiPalette.textPrimary.withValues(alpha: 0.88),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ArchiveJesterGrid extends StatefulWidget {
  const _ArchiveJesterGrid({
    required this.cards,
    required this.seenIds,
    required this.boughtIds,
    this.newIds = const <String>{},
  });

  final List<RummiJesterCard> cards;
  final Set<String> seenIds;
  final Set<String> boughtIds;
  final Set<String> newIds;

  @override
  State<_ArchiveJesterGrid> createState() => _ArchiveJesterGridState();
}

class _ArchiveJesterGridState extends State<_ArchiveJesterGrid>
    with _ArchiveNewRevealState {
  @override
  Set<String> get initialNewIds => widget.newIds;

  RummiJesterCard? _selectedCard;
  bool _detailOpen = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ArchivePagedGrid(
          cardHeight: _ArchiveSelectableCard.totalHeight(kJesterCardHeight),
          cardWidth: kJesterCardWidth,
          children: [
            for (final card in widget.cards)
              _ArchiveSelectableCard(
                width: kJesterCardWidth,
                height: kJesterCardHeight,
                status: _jesterStatus(
                  card.id,
                  seenIds: widget.seenIds,
                  boughtIds: widget.boughtIds,
                ),
                selected: _detailOpen && _selectedCard?.id == card.id,
                isNew: newIds.contains(card.id),
                flipTick: flipTickFor(card.id),
                onTap: () => setState(() {
                  _selectedCard = card;
                  _detailOpen = true;
                  revealIfNew(card.id, ArchiveSeenService.jesterId(card.id));
                }),
                child:
                    widget.seenIds.contains(card.id) ||
                        widget.boughtIds.contains(card.id)
                    ? GameJesterSlot(
                        card: card,
                        runtimeValueText: null,
                        extended: false,
                        activeEffect: null,
                        settlementSequenceTick: 0,
                      )
                    : const _ArchiveEmptyCard(label: 'Jester'),
              ),
          ],
        ),
        _ArchiveDetailHost(
          open: _detailOpen && _selectedCard != null,
          onClose: () => setState(() => _detailOpen = false),
          child: _selectedCard == null
              ? const SizedBox.shrink()
              : _ArchiveJesterDetail(
                  card: _selectedCard!,
                  status: _jesterStatus(
                    _selectedCard!.id,
                    seenIds: widget.seenIds,
                    boughtIds: widget.boughtIds,
                  ),
                ),
        ),
      ],
    );
  }
}

class _ArchiveItemGrid extends StatefulWidget {
  const _ArchiveItemGrid({
    required this.items,
    required this.seenIds,
    required this.boughtIds,
    this.newIds = const <String>{},
  });

  final List<ItemDefinition> items;
  final Set<String> seenIds;
  final Set<String> boughtIds;
  final Set<String> newIds;

  @override
  State<_ArchiveItemGrid> createState() => _ArchiveItemGridState();
}

class _ArchiveItemGridState extends State<_ArchiveItemGrid>
    with _ArchiveNewRevealState {
  @override
  Set<String> get initialNewIds => widget.newIds;

  ItemDefinition? _selectedItem;
  bool _detailOpen = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ArchivePagedGrid(
          cardHeight: _ArchiveSelectableCard.totalHeight(kBattleItemSlotHeight),
          cardWidth: kBattleItemSlotWidth,
          children: [
            for (final item in widget.items)
              _ArchiveSelectableCard(
                width: kBattleItemSlotWidth,
                height: kBattleItemSlotHeight,
                status: _itemStatus(
                  item.id,
                  seenIds: widget.seenIds,
                  boughtIds: widget.boughtIds,
                ),
                selected: _detailOpen && _selectedItem?.id == item.id,
                isNew: newIds.contains(item.id),
                flipTick: flipTickFor(item.id),
                onTap: () => setState(() {
                  _selectedItem = item;
                  _detailOpen = true;
                  revealIfNew(item.id, ArchiveSeenService.itemId(item.id));
                }),
                child:
                    widget.seenIds.contains(item.id) ||
                        widget.boughtIds.contains(item.id)
                    ? _ArchiveItemCardFace(item: item)
                    : const _ArchiveEmptyCard(label: 'Item'),
              ),
          ],
        ),
        _ArchiveDetailHost(
          open: _detailOpen && _selectedItem != null,
          onClose: () => setState(() => _detailOpen = false),
          child: _selectedItem == null
              ? const SizedBox.shrink()
              : _ArchiveItemDetail(
                  item: _selectedItem!,
                  status: _itemStatus(
                    _selectedItem!.id,
                    seenIds: widget.seenIds,
                    boughtIds: widget.boughtIds,
                  ),
                ),
        ),
      ],
    );
  }
}

class _ArchiveMemoryCardGrid extends StatefulWidget {
  const _ArchiveMemoryCardGrid({
    required this.cards,
    required this.collectedIds,
    this.newIds = const <String>{},
  });

  final List<_ArchiveMemoryCardDefinition> cards;
  final Set<String> collectedIds;
  final Set<String> newIds;

  @override
  State<_ArchiveMemoryCardGrid> createState() => _ArchiveMemoryCardGridState();
}

class _ArchiveMemoryCardGridState extends State<_ArchiveMemoryCardGrid>
    with _ArchiveNewRevealState {
  @override
  Set<String> get initialNewIds => widget.newIds;

  _ArchiveMemoryCardDefinition? _selectedCard;
  bool _detailOpen = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ArchivePagedGrid(
          cardHeight: _ArchiveSelectableCard.totalHeight(kBattleItemSlotHeight),
          cardWidth: kBattleItemSlotWidth,
          children: [
            for (final card in widget.cards)
              _ArchiveSelectableCard(
                width: kBattleItemSlotWidth,
                height: kBattleItemSlotHeight,
                status: _memoryCardStatus(
                  card,
                  collected: widget.collectedIds.contains(card.id),
                ),
                selected: _detailOpen && _selectedCard?.id == card.id,
                isNew: newIds.contains(card.id),
                flipTick: flipTickFor(card.id),
                onTap: () => setState(() {
                  _selectedCard = card;
                  _detailOpen = true;
                  revealIfNew(card.id, ArchiveSeenService.memoryId(card.id));
                }),
                child: widget.collectedIds.contains(card.id)
                    ? _ArchiveMemoryCardFace(card: card)
                    : const _ArchiveEmptyCard(label: '기억'),
              ),
          ],
        ),
        _ArchiveDetailHost(
          open: _detailOpen && _selectedCard != null,
          onClose: () => setState(() => _detailOpen = false),
          child: _selectedCard == null
              ? const SizedBox.shrink()
              : _ArchiveMemoryCardDetail(
                  card: _selectedCard!,
                  status: _memoryCardStatus(
                    _selectedCard!,
                    collected: widget.collectedIds.contains(_selectedCard!.id),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ArchivePagedGrid extends StatefulWidget {
  const _ArchivePagedGrid({
    required this.children,
    required this.cardHeight,
    required this.cardWidth,
  });

  static const int columns = 4;
  static const int rows = 3;
  static const int pageSize = columns * rows;
  static const double spacing = 12;
  static const double runSpacing = 14;

  final List<Widget> children;
  final double cardHeight;
  final double cardWidth;

  @override
  State<_ArchivePagedGrid> createState() => _ArchivePagedGridState();
}

class _ArchivePagedGridState extends State<_ArchivePagedGrid> {
  late final PageController _pageController = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _chunked(widget.children, _ArchivePagedGrid.pageSize);
    final pageHeight =
        widget.cardHeight * _ArchivePagedGrid.rows +
        _ArchivePagedGrid.runSpacing * (_ArchivePagedGrid.rows - 1);
    final gridWidth =
        widget.cardWidth * _ArchivePagedGrid.columns +
        _ArchivePagedGrid.spacing * (_ArchivePagedGrid.columns - 1);
    final pageCount = pages.isEmpty ? 1 : pages.length;
    final canGoBack = _pageIndex > 0;
    final canGoNext = _pageIndex < pageCount - 1;

    return Column(
      children: [
        SizedBox(
          height: pageHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: pageCount,
            onPageChanged: (index) => setState(() => _pageIndex = index),
            itemBuilder: (context, index) {
              final pageChildren = pages.isEmpty
                  ? const <Widget>[]
                  : pages[index];
              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: gridWidth,
                  child: Wrap(
                    alignment: WrapAlignment.start,
                    spacing: _ArchivePagedGrid.spacing,
                    runSpacing: _ArchivePagedGrid.runSpacing,
                    children: pageChildren,
                  ),
                ),
              );
            },
          ),
        ),
        if (pageCount > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ArchivePageButton(
                icon: Icons.chevron_left_rounded,
                enabled: canGoBack,
                onPressed: () => _animateToPage(_pageIndex - 1),
              ),
              const SizedBox(width: 14),
              Text(
                '${_pageIndex + 1} / $pageCount',
                style: TextStyle(
                  color: GameUiPalette.textPrimary.withValues(alpha: 0.74),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 14),
              _ArchivePageButton(
                icon: Icons.chevron_right_rounded,
                enabled: canGoNext,
                onPressed: () => _animateToPage(_pageIndex + 1),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _animateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }
}

class _ArchivePageButton extends StatelessWidget {
  const _ArchivePageButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PressFeedback(
      onTap: enabled ? onPressed : null,
      builder: (context, onTap) => IconButton.filled(
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          backgroundColor: enabled
              ? GameUiPalette.archiveChipSurface
              : GameUiPalette.textPrimary.withValues(alpha: 0.08),
          foregroundColor: enabled
              ? GameUiPalette.gameOverRewardAccent
              : GameUiPalette.textPrimary.withValues(alpha: 0.22),
          fixedSize: const Size(34, 34),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 22),
      ),
    );
  }
}

List<List<T>> _chunked<T>(List<T> values, int size) {
  final chunks = <List<T>>[];
  for (var index = 0; index < values.length; index += size) {
    final end = index + size > values.length ? values.length : index + size;
    chunks.add(values.sublist(index, end));
  }
  return chunks;
}

/// NEW 항목을 처음 열 때 한 번 뒤집어 공개하고 확인한 것으로 기록한다.
mixin _ArchiveNewRevealState<T extends StatefulWidget> on State<T> {
  Set<String> get initialNewIds;

  late final Set<String> newIds = {...initialNewIds};
  String? _flipId;
  int _flipTick = 0;

  int flipTickFor(String id) => _flipId == id ? _flipTick : 0;

  /// setState 안에서 부른다. 새 항목이 아니면 아무것도 하지 않는다.
  void revealIfNew(String id, String prefixedId) {
    if (!newIds.remove(id)) return;
    _flipId = id;
    _flipTick++;
    GameFeedback.play(GameCue.unlock);
    unawaited(ArchiveSeenService.acknowledge(prefixedId));
  }
}

/// 처음 그릴 때 0에서 [value]까지 count-up한다. 전투의 [GameCountUpInt]를 그대로 쓴다.
class _ArchiveCountUp extends StatefulWidget {
  const _ArchiveCountUp({required this.value, required this.builder});

  final int value;
  final Widget Function(int shown) builder;

  @override
  State<_ArchiveCountUp> createState() => _ArchiveCountUpState();
}

class _ArchiveCountUpState extends State<_ArchiveCountUp> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _started = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameCountUpInt(
      value: _started ? widget.value : 0,
      builder: (context, shown) => widget.builder(shown),
    );
  }
}
