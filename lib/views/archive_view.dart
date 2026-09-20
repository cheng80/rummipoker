import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_config.dart';
import '../logic/rummi_poker_grid/item_catalog_loader.dart';
import '../logic/rummi_poker_grid/item_definition.dart';
import '../logic/rummi_poker_grid/jester_catalog_loader.dart';
import '../logic/rummi_poker_grid/jester_meta.dart';
import '../resources/asset_paths.dart';
import '../resources/item_translation_scope.dart';
import '../services/archive_seen_service.dart';
import '../services/run_unlock_state_service.dart';
import '../utils/app_translation.dart';
import '../utils/common_ui.dart';
import '../widgets/fx/entrance_in.dart';
import '../widgets/fx/motion_policy.dart';
import '../widgets/phone_frame_scaffold.dart';
import '../widgets/semantic_text.dart';
import 'game/game_feedback_cues.dart';
import 'game/game_presentation_timings.dart';
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
    required this.acknowledgedIds,
  });

  final RunUnlockState state;

  /// Archive에서 이미 확인한 발견 항목(접두 포함). 여기 없는 발견 항목이 NEW다.
  final Set<String> acknowledgedIds;
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
                  onPressed: withButtonSound(() => context.pop()),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: GameUiPalette.textPrimary,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              context.translate('archiveTitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AssetPaths.fontNexonLv2Gothic,
                fontSize: 38,
                color: GameUiPalette.textPrimary.withValues(alpha: 0.96),
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 10),
            SemanticText(
              context.translate('menuArchiveIntro'),
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
                final acknowledged = data?.acknowledgedIds ?? const <String>{};
                bool isNew(String prefixedId) =>
                    !acknowledged.contains(prefixedId);
                return HomeSection(
                  title: context.translate('menuRecords'),
                  subtitle: context.translate('menuRecordsDesc'),
                  child: Column(
                    children: [
                      HomeSnapshotCard(
                        title: context.translate('menuMemoryCards'),
                        summary: context.translate(
                          'menuMemorySummary',
                          namedArgs: {
                            'owned': '${state.insight}',
                            'collected': '${collectedMemoryCardIds.length}',
                            'total': '${_archiveMemoryCards.length}',
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      HomeSnapshotCard(
                        title: context.translate('menuMarketRecords'),
                        summary: data == null
                            ? context.translate('menuArchiveLoading')
                            : 'Jester ${collectedJesterIds.length}/${data.jesterCatalog.all.length} · Item ${collectedItemIds.length}/${data.itemCatalog.all.length}',
                      ),
                      if (data != null) ...[
                        const SizedBox(height: 10),
                        _ArchiveCollectionSection(
                          title: context.translate('menuMemoryCollection'),
                          collectedCount: collectedMemoryCardIds.length,
                          totalCount: _archiveMemoryCards.length,
                          child: _ArchiveMemoryCardGrid(
                            cards: _archiveMemoryCards,
                            collectedIds: collectedMemoryCardIds,
                            newIds: {
                              for (final id in collectedMemoryCardIds)
                                if (isNew(ArchiveSeenService.memoryId(id))) id,
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ArchiveCollectionSection(
                          title: context.translate('menuJesterCollection'),
                          collectedCount: collectedJesterIds.length,
                          totalCount: data.jesterCatalog.all.length,
                          child: _ArchiveJesterGrid(
                            cards: data.jesterCatalog.all,
                            seenIds: state.seenMarketJesterIds,
                            boughtIds: state.boughtJesterIds,
                            newIds: {
                              for (final id in collectedJesterIds)
                                if (isNew(ArchiveSeenService.jesterId(id))) id,
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ArchiveCollectionSection(
                          title: context.translate('menuItemCollection'),
                          collectedCount: collectedItemIds.length,
                          totalCount: data.itemCatalog.all.length,
                          child: _ArchiveItemGrid(
                            items: data.itemCatalog.all,
                            seenIds: state.seenMarketItemIds,
                            boughtIds: state.boughtItemIds,
                            newIds: {
                              for (final id in collectedItemIds)
                                if (isNew(ArchiveSeenService.itemId(id))) id,
                            },
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 10),
                        HomeSnapshotCard(
                          title: context.translate('menuCardsLoading'),
                          summary: context.translate('menuArchiveLoading'),
                        ),
                      ],
                      if (data != null &&
                          collectedJesterIds.isEmpty &&
                          collectedItemIds.isEmpty) ...[
                        const SizedBox(height: 10),
                        HomeSnapshotCard(
                          title: context.translate('menuNoRecords'),
                          summary: context.translate('menuNoRecordsDesc'),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            HomeSection(
              title: context.translate('menuRewardCards'),
              subtitle: context.translate('menuRewardCardsDesc'),
              child: Column(
                children: [
                  HomeSnapshotCard(
                    title: context.translate('menuMemoryCards'),
                    summary: context.translate('menuMemoryPurpose'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            HomeSection(
              title: context.translate('menuRunRules'),
              subtitle: context.translate('menuRunRulesDesc'),
              child: Column(
                children: [
                  HomeSnapshotCard(
                    title: context.translate('menuHighStakes'),
                    summary: context.translate('menuHighStakesDesc'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            HomeSection(
              title: context.translate('menuCollectionEntries'),
              subtitle: context.translate('menuCollectionEntriesDesc'),
              child: Column(
                children: [
                  HomeSnapshotCard(
                    title: 'Jester',
                    summary: context.translate('menuJesterDesc'),
                  ),
                  SizedBox(height: 10),
                  HomeSnapshotCard(
                    title: 'Item',
                    summary: context.translate('menuItemDesc'),
                  ),
                  SizedBox(height: 10),
                  HomeSnapshotCard(
                    title: 'Boss',
                    summary: context.translate('menuBossDesc'),
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
      acknowledgedIds: await ArchiveSeenService.loadOrInitialize(loadedState),
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
