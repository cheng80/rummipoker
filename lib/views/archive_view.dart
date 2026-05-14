import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_config.dart';
import '../logic/rummi_poker_grid/item_catalog_loader.dart';
import '../logic/rummi_poker_grid/item_definition.dart';
import '../logic/rummi_poker_grid/jester_catalog_loader.dart';
import '../logic/rummi_poker_grid/jester_meta.dart';
import '../resources/asset_paths.dart';
import '../services/run_unlock_state_service.dart';
import '../widgets/phone_frame_scaffold.dart';
import 'game/widgets/game_card_name_text.dart';
import 'game/widgets/game_jester_widgets.dart';
import 'game/widgets/game_shared_widgets.dart';
import 'home_entry_widgets.dart';

class _ArchiveData {
  const _ArchiveData({
    required this.state,
    required this.jesterCatalog,
    required this.itemCatalog,
  });

  final RunUnlockState state;
  final RummiJesterCatalog jesterCatalog;
  final ItemCatalog itemCatalog;
}

class ArchiveView extends StatefulWidget {
  const ArchiveView({
    super.key,
    this.debugScrollPreset,
    this.debugCollectionPreset,
  });

  final String? debugScrollPreset;
  final String? debugCollectionPreset;

  @override
  State<ArchiveView> createState() => _ArchiveViewState();
}

class _ArchiveViewState extends State<ArchiveView> {
  final ScrollController _scrollController = ScrollController();
  late final Future<_ArchiveData> _archiveData = _loadArchiveData();

  @override
  void initState() {
    super.initState();
    _applyDebugScrollPreset();
  }

  void _applyDebugScrollPreset() {
    if (!AppConfig.showDebugFixtures || widget.debugScrollPreset != 'bottom') {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 150), () {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PhoneFrameScaffold(
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '도감',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AssetPaths.fontNexonLv2Gothic,
                fontSize: 38,
                color: Colors.white.withValues(alpha: 0.96),
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '런에서 만난 기억 카드, Jester, 아이템, 보스 규칙을 확인합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            FutureBuilder<_ArchiveData>(
              future: _archiveData,
              builder: (context, snapshot) {
                final data = snapshot.data;
                final state = data == null
                    ? RunUnlockState.defaults()
                    : _debugArchiveState(data.state);
                final collectedJesterIds = _collectedJesterIds(state);
                final collectedItemIds = _collectedItemIds(state);
                final collectedMemoryCardIds = state.earnedMemoryCardIds;
                return HomeSection(
                  title: '내 기록',
                  subtitle: '이번 기기에서 런을 이어가며 남은 수집 기록',
                  child: Column(
                    children: [
                      HomeSnapshotCard(
                        title: '기억 카드',
                        summary:
                            '보유 ${state.insight}장 · 수집 ${collectedMemoryCardIds.length}/${_archiveMemoryCards.length}',
                      ),
                      const SizedBox(height: 10),
                      HomeSnapshotCard(
                        title: '마켓 기록',
                        summary: data == null
                            ? '도감 항목을 불러오고 있습니다.'
                            : 'Jester ${collectedJesterIds.length}/${data.jesterCatalog.all.length} · Item ${collectedItemIds.length}/${data.itemCatalog.all.length}',
                      ),
                      if (data != null) ...[
                        const SizedBox(height: 10),
                        _ArchiveCollectionSection(
                          title: '기억 카드 수집',
                          collectedCount: collectedMemoryCardIds.length,
                          totalCount: _archiveMemoryCards.length,
                          child: _ArchiveMemoryCardGrid(
                            cards: _archiveMemoryCards,
                            collectedIds: collectedMemoryCardIds,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ArchiveCollectionSection(
                          title: 'Jester 수집',
                          collectedCount: collectedJesterIds.length,
                          totalCount: data.jesterCatalog.all.length,
                          child: _ArchiveJesterGrid(
                            cards: data.jesterCatalog.all,
                            seenIds: state.seenMarketJesterIds,
                            boughtIds: state.boughtJesterIds,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ArchiveCollectionSection(
                          title: 'Item 수집',
                          collectedCount: collectedItemIds.length,
                          totalCount: data.itemCatalog.all.length,
                          child: _ArchiveItemGrid(
                            items: data.itemCatalog.all,
                            seenIds: state.seenMarketItemIds,
                            boughtIds: state.boughtItemIds,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 10),
                        const HomeSnapshotCard(
                          title: '카드 로딩 중',
                          summary: '도감 항목을 불러오고 있습니다.',
                        ),
                      ],
                      if (data != null &&
                          collectedJesterIds.isEmpty &&
                          collectedItemIds.isEmpty) ...[
                        const SizedBox(height: 10),
                        const HomeSnapshotCard(
                          title: '아직 기록 없음',
                          summary: '마켓에서 만난 카드와 아이템이 여기에 남습니다.',
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            const HomeSection(
              title: '보상 카드',
              subtitle: '게임오버와 런 완료 후 받는 기억 카드',
              child: Column(
                children: [
                  HomeSnapshotCard(
                    title: '기억 카드',
                    summary:
                        '다음 런 준비에서 새 규칙을 여는 전용 보상 카드입니다. 전투 중 아이템이나 Jester를 자동 지급하지 않습니다.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const HomeSection(
              title: '런 규칙',
              subtitle: '기억 카드로 열 수 있는 다음 런 규칙',
              child: Column(
                children: [
                  HomeSnapshotCard(
                    title: '하이 스테이크',
                    summary:
                        '목표 점수와 보상이 함께 올라가는 선택형 규칙입니다. 선택하지 않으면 기본 런으로 시작합니다.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const HomeSection(
              title: '수집 항목',
              subtitle: '공모전 빌드에서 확인해야 할 주요 도감 분류',
              child: Column(
                children: [
                  HomeSnapshotCard(
                    title: 'Jester',
                    summary:
                        '상점에서 구매해 빌드를 바꾸는 카드입니다. 전투 점수, 타일 색, 족보 조건처럼 발동 기준을 확인합니다.',
                  ),
                  SizedBox(height: 10),
                  HomeSnapshotCard(
                    title: 'Item',
                    summary:
                        'Q-Slot, Passive, Tool, Gear에 들어가는 장비입니다. 사용 시점과 지속 범위를 확인합니다.',
                  ),
                  SizedBox(height: 10),
                  HomeSnapshotCard(
                    title: 'Boss',
                    summary: '스테이션마다 전투 규칙을 바꾸는 제약입니다. 어떤 줄이나 타일이 약해지는지 확인합니다.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<_ArchiveData> _loadArchiveData() async {
    final results = await Future.wait<Object>([
      RunUnlockStateService.load(),
      RummiJesterCatalogLoader.loadFromAsset(AssetPaths.jestersCommon),
      ItemCatalogLoader.loadFromAsset(AssetPaths.itemsCommon),
    ]);
    final loadedState = results[0] as RunUnlockState;
    return _ArchiveData(
      state: loadedState,
      jesterCatalog: results[1] as RummiJesterCatalog,
      itemCatalog: results[2] as ItemCatalog,
    );
  }

  RunUnlockState _debugArchiveState(RunUnlockState loadedState) {
    if (!AppConfig.showDebugFixtures ||
        widget.debugCollectionPreset != 'full') {
      return loadedState;
    }
    return loadedState.copyWith(
      insight: 14,
      seenMarketJesterIds: const <String>{
        'crazy_jester',
        'green_jester',
        'scary_face',
        'egg',
        'popcorn',
        'ice_cream',
        'supernova',
        'ride_the_bus',
      },
      seenMarketItemIds: const <String>{
        'coin_cache',
        'board_scrap',
        'jester_hook',
        'safety_net',
        'deck_needle',
        'market_compass',
        'boss_trophy',
      },
      boughtJesterIds: const <String>{'green_jester', 'egg', 'supernova'},
      boughtItemIds: const <String>{'coin_cache', 'deck_needle'},
      seenBossModifierIds: const <String>{
        'red_dampener_v1',
        'row_line_dampener_v1',
        'confirm_count_tax_v2',
      },
      clearedStationKeys: const <String>{
        'standard_s1_small',
        'standard_s1_big',
        'standard_s1_boss',
        'standard_s2_small',
        'standard_s2_big',
      },
      earnedMemoryCardIds: const <String>{
        'memory_card_expired_standard_s2',
        'memory_card_completed_standard_s8',
      },
    );
  }
}

Set<String> _collectedJesterIds(RunUnlockState state) {
  return <String>{...state.seenMarketJesterIds, ...state.boughtJesterIds};
}

Set<String> _collectedItemIds(RunUnlockState state) {
  return <String>{...state.seenMarketItemIds, ...state.boughtItemIds};
}

enum _ArchiveCollectionStatus {
  undiscovered('미발견', Color(0xFF8B9390)),
  discovered('발견', Color(0xFFB9D8FF)),
  acquired('획득', Color(0xFF9DF0BE)),
  cleared('클리어', Color(0xFFF4C75D));

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
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title $collectedCount/$totalCount',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 13,
              fontWeight: FontWeight.w900,
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
  });

  final List<RummiJesterCard> cards;
  final Set<String> seenIds;
  final Set<String> boughtIds;

  @override
  State<_ArchiveJesterGrid> createState() => _ArchiveJesterGridState();
}

class _ArchiveJesterGridState extends State<_ArchiveJesterGrid> {
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
                onTap: () => setState(() {
                  _selectedCard = card;
                  _detailOpen = true;
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
  });

  final List<ItemDefinition> items;
  final Set<String> seenIds;
  final Set<String> boughtIds;

  @override
  State<_ArchiveItemGrid> createState() => _ArchiveItemGridState();
}

class _ArchiveItemGridState extends State<_ArchiveItemGrid> {
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
                onTap: () => setState(() {
                  _selectedItem = item;
                  _detailOpen = true;
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
  });

  final List<_ArchiveMemoryCardDefinition> cards;
  final Set<String> collectedIds;

  @override
  State<_ArchiveMemoryCardGrid> createState() => _ArchiveMemoryCardGridState();
}

class _ArchiveMemoryCardGridState extends State<_ArchiveMemoryCardGrid> {
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
                onTap: () => setState(() {
                  _selectedCard = card;
                  _detailOpen = true;
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
                  color: Colors.white.withValues(alpha: 0.74),
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
    return IconButton.filled(
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: enabled
            ? const Color(0xFF253D38)
            : Colors.white.withValues(alpha: 0.08),
        foregroundColor: enabled
            ? const Color(0xFF9DF0BE)
            : Colors.white.withValues(alpha: 0.22),
        fixedSize: const Size(34, 34),
      ),
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 22),
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

class _ArchiveDetailHost extends StatelessWidget {
  const _ArchiveDetailHost({
    required this.open,
    required this.onClose,
    required this.child,
  });

  final bool open;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 160),
      crossFadeState: open
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      firstChild: const SizedBox(width: double.infinity),
      secondChild: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: _ArchiveDetailCard(onClose: onClose, child: child),
      ),
    );
  }
}

class _ArchiveDetailCard extends StatelessWidget {
  const _ArchiveDetailCard({required this.onClose, required this.child});

  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111D1B).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF9DF0BE).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: child),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
            icon: const Icon(Icons.keyboard_arrow_up_rounded),
            color: Colors.white.withValues(alpha: 0.66),
            tooltip: '접기',
          ),
        ],
      ),
    );
  }
}

class _ArchiveMemoryCardDetail extends StatelessWidget {
  const _ArchiveMemoryCardDetail({required this.card, required this.status});

  final _ArchiveMemoryCardDefinition card;
  final _ArchiveCollectionStatus status;

  @override
  Widget build(BuildContext context) {
    final collected = status != _ArchiveCollectionStatus.undiscovered;
    return _ArchiveDetailText(
      title: collected ? card.title : '아직 얻지 못한 기억 카드',
      subtitle: '${status.label} · 기억 카드',
      body: collected
          ? '게임오버나 런 완료 후 얻는 보상 카드입니다. 다음 런 준비에서 새 규칙을 여는 데 사용됩니다.'
          : '이 칸은 아직 비어 있습니다. 런을 더 진행하면 기억 카드가 여기에 채워집니다.',
    );
  }
}

class _ArchiveJesterDetail extends StatelessWidget {
  const _ArchiveJesterDetail({required this.card, required this.status});

  final RummiJesterCard card;
  final _ArchiveCollectionStatus status;

  @override
  Widget build(BuildContext context) {
    final collected = status != _ArchiveCollectionStatus.undiscovered;
    return _ArchiveDetailText(
      title: collected ? card.displayName : '아직 만나지 못한 Jester',
      subtitle: collected
          ? '${status.label} · ${_archiveJesterRarityLabel(card.rarity)}'
          : '${status.label} · Jester',
      body: collected
          ? card.effectText
          : '이 칸은 아직 비어 있습니다. 마켓에서 만나거나 구매한 Jester가 여기에 채워집니다.',
    );
  }
}

class _ArchiveItemDetail extends StatelessWidget {
  const _ArchiveItemDetail({required this.item, required this.status});

  final ItemDefinition item;
  final _ArchiveCollectionStatus status;

  @override
  Widget build(BuildContext context) {
    final collected = status != _ArchiveCollectionStatus.undiscovered;
    return _ArchiveDetailText(
      title: collected ? item.displayName : '아직 만나지 못한 Item',
      subtitle: collected
          ? '${status.label} · ${_archiveItemSlotLabel(item.placement)} · ${_archiveItemRarityLabel(item.rarity)}'
          : '${status.label} · Item',
      body: collected
          ? item.effectText
          : '이 칸은 아직 비어 있습니다. 마켓에서 만나거나 구매한 아이템이 여기에 채워집니다.',
    );
  }
}

class _ArchiveDetailText extends StatelessWidget {
  const _ArchiveDetailText({
    required this.title,
    required this.subtitle,
    required this.body,
  });

  final String title;
  final String subtitle;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subtitle,
          style: TextStyle(
            color: const Color(0xFF9DF0BE).withValues(alpha: 0.82),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          body,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.76),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _ArchiveSelectableCard extends StatelessWidget {
  const _ArchiveSelectableCard({
    required this.width,
    required this.height,
    required this.status,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final double width;
  final double height;
  final _ArchiveCollectionStatus status;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  static const double _labelGap = 4;
  static const double _labelHeight = _ArchiveStatusBadge.height;
  static const double _outerPadding = 2;
  static const double _borderWidth = 2;
  static const double _labelHorizontalInset = 6;

  static double totalHeight(double cardHeight) =>
      cardHeight +
      _labelGap +
      _labelHeight +
      (_outerPadding * 2) +
      (_borderWidth * 2);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: totalHeight(height),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: width,
              height: height + ((_outerPadding + _borderWidth) * 2),
              padding: const EdgeInsets.all(_outerPadding),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF9DF0BE)
                      : Colors.transparent,
                  width: _borderWidth,
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: height,
                child: child,
              ),
            ),
          ),
          const SizedBox(height: _labelGap),
          Center(
            child: _ArchiveStatusBadge(
              status: status,
              width: width - (_labelHorizontalInset * 2),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveStatusBadge extends StatelessWidget {
  const _ArchiveStatusBadge({required this.status, required this.width});

  final _ArchiveCollectionStatus status;
  final double width;

  static const double height = 14;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.black.withValues(alpha: 0.16)),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 7,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ArchiveEmptyCard extends StatelessWidget {
  const _ArchiveEmptyCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1817).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: Colors.white.withValues(alpha: 0.26),
              size: 19,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.30),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveMemoryCardFace extends StatelessWidget {
  const _ArchiveMemoryCardFace({required this.card});

  final _ArchiveMemoryCardDefinition card;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF132520),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF9DF0BE), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64D8A4).withValues(alpha: 0.16),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 6, 5, 5),
        child: Column(
          children: [
            const Icon(Icons.style_rounded, color: Color(0xFF9DF0BE), size: 20),
            const SizedBox(height: 4),
            Expanded(
              child: Center(
                child: Text(
                  card.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFDDF7EA),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
              ),
            ),
            _ArchiveItemBadge(label: card.badge),
          ],
        ),
      ),
    );
  }
}

class _ArchiveItemCardFace extends StatelessWidget {
  const _ArchiveItemCardFace({required this.item});

  final ItemDefinition item;

  @override
  Widget build(BuildContext context) {
    final accent = _archiveItemAccent(item.placement);
    return Container(
      decoration: BoxDecoration(
        color: _archiveItemSurface(item.placement),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          children: [
            FractionallySizedBox(
              widthFactor: 0.82,
              child: Container(
                height: 7,
                decoration: BoxDecoration(
                  color: gameItemRarityColor(item.rarity),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: GameCardNameText(
                  item.displayName,
                  style: const TextStyle(
                    color: Color(0xFF26352F),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
              ),
            ),
            _ArchiveItemBadge(label: _archiveItemSlotLabel(item.placement)),
          ],
        ),
      ),
    );
  }
}

class _ArchiveItemBadge extends StatelessWidget {
  const _ArchiveItemBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 26),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(
          color: Color(0xFF26352F),
          fontSize: 7,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      ),
    );
  }
}

Color _archiveItemSurface(ItemPlacement placement) {
  return switch (placement) {
    ItemPlacement.quickSlot => const Color(0xFFDCEBFF),
    ItemPlacement.passiveRack => const Color(0xFFE2F7DD),
    ItemPlacement.inventory => const Color(0xFFFFF0C9),
    ItemPlacement.equipped => const Color(0xFFEADFFF),
  };
}

Color _archiveItemAccent(ItemPlacement placement) {
  return switch (placement) {
    ItemPlacement.quickSlot => const Color(0xFF4E8BE8),
    ItemPlacement.passiveRack => const Color(0xFF42A85A),
    ItemPlacement.inventory => const Color(0xFFD6962B),
    ItemPlacement.equipped => const Color(0xFF9B72D9),
  };
}

String _archiveItemSlotLabel(ItemPlacement placement) {
  return switch (placement) {
    ItemPlacement.quickSlot => 'Q-SLT',
    ItemPlacement.passiveRack => 'PSV',
    ItemPlacement.inventory => 'Tool',
    ItemPlacement.equipped => 'Gear',
  };
}

String _archiveJesterRarityLabel(RummiJesterRarity rarity) {
  return switch (rarity) {
    RummiJesterRarity.common => '일반',
    RummiJesterRarity.uncommon => '희귀',
    RummiJesterRarity.rare => '레어',
    RummiJesterRarity.legendary => '전설',
  };
}

String _archiveItemRarityLabel(ItemRarity rarity) {
  return switch (rarity) {
    ItemRarity.common => '일반',
    ItemRarity.uncommon => '희귀',
    ItemRarity.rare => '레어',
    ItemRarity.legendary => '전설',
  };
}

class _ArchiveMemoryCardDefinition {
  const _ArchiveMemoryCardDefinition({
    required this.id,
    required this.title,
    required this.badge,
  });

  final String id;
  final String title;
  final String badge;
}

const List<_ArchiveMemoryCardDefinition> _archiveMemoryCards = [
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_standard_s1',
    title: '표준 S1',
    badge: '패배',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_standard_s2',
    title: '표준 S2',
    badge: '패배',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_standard_s3',
    title: '표준 S3',
    badge: '패배',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_standard_s4',
    title: '표준 S4',
    badge: '패배',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_standard_s5',
    title: '표준 S5',
    badge: '패배',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_standard_s6',
    title: '표준 S6',
    badge: '패배',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_standard_s7',
    title: '표준 S7',
    badge: '패배',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_standard_s8',
    title: '표준 S8',
    badge: '패배',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_completed_standard_s8',
    title: '표준 완료',
    badge: '완료',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_challenge_s1',
    title: '도전 S1',
    badge: '패배',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_challenge_s2',
    title: '도전 S2',
    badge: '패배',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_challenge_s3',
    title: '도전 S3',
    badge: '패배',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_challenge_s4',
    title: '도전 S4',
    badge: '패배',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_challenge_s5',
    title: '도전 S5',
    badge: '패배',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_challenge_s6',
    title: '도전 S6',
    badge: '패배',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_challenge_s7',
    title: '도전 S7',
    badge: '패배',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_expired_challenge_s8',
    title: '도전 S8',
    badge: '패배',
  ),
  _ArchiveMemoryCardDefinition(
    id: 'memory_card_completed_challenge_s8',
    title: '도전 완료',
    badge: '완료',
  ),
];
