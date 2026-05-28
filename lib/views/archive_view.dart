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
import 'game/widgets/game_ui_palette.dart';
import 'home_entry_widgets.dart';

part 'archive/archive_collection_widgets.dart';
part 'archive/archive_detail_widgets.dart';
part 'archive/archive_memory_cards.dart';

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
                  color: GameUiPalette.textPrimary,
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
                color: GameUiPalette.textPrimary.withValues(alpha: 0.96),
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '런에서 만난 기억 카드, Jester, 아이템, 보스 규칙을 확인합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GameUiPalette.textPrimary.withValues(alpha: 0.72),
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
