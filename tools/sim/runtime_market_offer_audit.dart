// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_market_facade.dart';

const _defaultJesterCatalogPath = 'data/common/jesters_common_phase5.json';
const _defaultItemCatalogPath = 'data/common/items_common_v1.json';
const _defaultRuns = 200;
const _watchIds = <String>{
  'reroll_token',
  'trade_ticket',
  'full_house_study',
  'four_kind_study',
  'straight_flush_study',
  'ride_the_bus',
  'jester_hook',
};

void main(List<String> args) {
  final options = _Options.parse(args);
  final jesterCatalog = RummiJesterCatalog.fromJsonString(
    File(options.jesterCatalogPath).readAsStringSync(),
  );
  final itemCatalog = ItemCatalog.fromJsonString(
    File(options.itemCatalogPath).readAsStringSync(),
  );

  final report = _buildReport(
    options: options,
    jesterCatalog: jesterCatalog,
    itemCatalog: itemCatalog,
  );
  if (options.jsonOutPath != null) {
    final outFile = File(options.jsonOutPath!);
    outFile.parent.createSync(recursive: true);
    outFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(report),
    );
    outFile.writeAsStringSync('\n', mode: FileMode.append);
  }
  _printReport(report);
}

Map<String, Object?> _buildReport({
  required _Options options,
  required RummiJesterCatalog jesterCatalog,
  required ItemCatalog itemCatalog,
}) {
  final byStage = <String, Map<String, Object?>>{};
  final totalJesterCounts = <String, int>{};
  final totalItemCounts = <String, int>{};
  final watchCounts = {for (final id in _watchIds) id: 0};
  final collectionAudit = _buildCollectionAudit(
    options: options,
    jesterCatalog: jesterCatalog,
    itemCatalog: itemCatalog,
  );

  for (final stage in options.stages) {
    final stageJesterCounts = <String, int>{};
    final stageItemCounts = <String, int>{};
    final stageWatchCounts = {for (final id in _watchIds) id: 0};
    var jesterOfferCount = 0;
    var itemOfferCount = 0;

    for (var seed = 0; seed < options.runs; seed++) {
      final progress = RummiRunProgress()
        ..stageIndex = stage
        ..gold = 999;
      progress.openShop(
        catalog: jesterCatalog.shopCatalog,
        rng: Random(options.seed + stage * 1009 + seed),
        pressureProfile: options.pressureProfile,
      );
      progress.marketModifiers = progress.marketModifiers.copyWith(
        itemOfferRerollOffset: seed,
      );
      final market = RummiMarketRuntimeFacade.fromRunProgress(
        progress,
        itemCatalog: itemCatalog,
        pressureProfile: options.pressureProfile,
      );

      for (final offer in market.offers) {
        jesterOfferCount += 1;
        _increment(stageJesterCounts, offer.contentId);
        _increment(totalJesterCounts, offer.contentId);
        if (_watchIds.contains(offer.contentId)) {
          _increment(stageWatchCounts, offer.contentId);
          _increment(watchCounts, offer.contentId);
        }
      }
      for (final offer in market.itemOffers) {
        itemOfferCount += 1;
        _increment(stageItemCounts, offer.contentId);
        _increment(totalItemCounts, offer.contentId);
        if (_watchIds.contains(offer.contentId)) {
          _increment(stageWatchCounts, offer.contentId);
          _increment(watchCounts, offer.contentId);
        }
      }
    }

    byStage['S$stage'] = <String, Object?>{
      'runs': options.runs,
      'jester_offer_count': jesterOfferCount,
      'item_offer_count': itemOfferCount,
      'watch_counts': stageWatchCounts,
      'top_jesters': _topCounts(stageJesterCounts),
      'top_items': _topCounts(stageItemCounts),
    };
  }

  return <String, Object?>{
    'schema_version': 1,
    'runs_per_stage': options.runs,
    'seed': options.seed,
    'stages': options.stages,
    'pressure_profile': options.pressureProfile.name,
    'watch_ids': _watchIds.toList(growable: false)..sort(),
    'watch_counts': watchCounts,
    'top_jesters': _topCounts(totalJesterCounts),
    'top_items': _topCounts(totalItemCounts),
    'collection_audit': collectionAudit,
    'by_stage': byStage,
  };
}

Map<String, Object?> _buildCollectionAudit({
  required _Options options,
  required RummiJesterCatalog jesterCatalog,
  required ItemCatalog itemCatalog,
}) {
  final jesterIds = jesterCatalog.shopCatalog
      .map((card) => card.id)
      .where((id) => id.isNotEmpty)
      .toSet();
  final itemIds = itemCatalog.all
      .map((item) => item.id)
      .where((id) => id.isNotEmpty)
      .toSet();
  final itemById = {for (final item in itemCatalog.all) item.id: item};

  final aggregateSeenJesters = <String>{};
  final aggregateSeenItems = <String>{};
  final aggregateBoughtJesters = <String>{};
  final aggregateBoughtItems = <String>{};
  final goldBlockedJesters = <String, int>{};
  final goldBlockedItems = <String, int>{};
  final preCoverageGoldBlockedJesters = <String, int>{};
  final preCoverageGoldBlockedItems = <String, int>{};
  final capacityBlockedJesters = <String, int>{};
  final capacityBlockedItems = <String, int>{};
  final preCoverageCapacityBlockedJesters = <String, int>{};
  final preCoverageCapacityBlockedItems = <String, int>{};
  final finalGoldValues = <int>[];
  int? allJestersSeenAtEntry;
  int? allItemsSeenAtEntry;
  int? allJestersBoughtAtEntry;
  int? allItemsBoughtAtEntry;
  var marketEntries = 0;
  var jesterSellCount = 0;
  var itemSellCount = 0;

  for (var runIndex = 0; runIndex < options.runs; runIndex++) {
    final progress = RummiRunProgress()..gold = options.initialGold;
    final claimedRewardStages = <int>{};

    for (final stage in options.stages) {
      progress.stageIndex = stage;
      for (final rewardStage in const [2, 4, 6]) {
        if (stage > rewardStage && claimedRewardStages.add(rewardStage)) {
          progress
            ..stageIndex = rewardStage
            ..claimBossSlotUnlockRewards()
            ..clearPendingSlotUnlockPresentations();
          progress.stageIndex = stage;
        }
      }

      for (var entry = 0; entry < options.marketsPerStage; entry++) {
        marketEntries += 1;
        progress
          ..stageIndex = stage
          ..gold += options.cashoutGold;
        progress.openShop(
          catalog: jesterCatalog.shopCatalog,
          rng: Random(options.seed + runIndex * 7919 + stage * 101 + entry),
          pressureProfile: options.pressureProfile,
        );
        progress.marketModifiers = progress.marketModifiers.copyWith(
          itemOfferRerollOffset: runIndex * 31 + stage * 7 + entry,
        );
        final market = RummiMarketRuntimeFacade.fromRunProgress(
          progress,
          itemCatalog: itemCatalog,
          pressureProfile: options.pressureProfile,
        );

        aggregateSeenJesters.addAll(
          market.offers.map((offer) => offer.contentId),
        );
        aggregateSeenItems.addAll(
          market.itemOffers.map((offer) => offer.contentId),
        );
        allJestersSeenAtEntry ??=
            aggregateSeenJesters.length >= jesterIds.length
            ? marketEntries
            : null;
        allItemsSeenAtEntry ??= aggregateSeenItems.length >= itemIds.length
            ? marketEntries
            : null;

        final jesterCandidate = _firstUnboughtJesterOffer(
          progress,
          market,
          aggregateBoughtJesters,
        );
        if (jesterCandidate != null) {
          final index = progress.shopOffers.indexWhere(
            (offer) => offer.card.id == jesterCandidate.contentId,
          );
          if (index >= 0) {
            final price = progress.effectiveJesterOfferPrice(index);
            if (progress.gold < price) {
              _increment(goldBlockedJesters, jesterCandidate.contentId);
              if (allJestersBoughtAtEntry == null) {
                _increment(
                  preCoverageGoldBlockedJesters,
                  jesterCandidate.contentId,
                );
              }
            } else if (progress.ownedJesters.length >=
                progress.jesterSlotCapacity(itemCatalog: itemCatalog)) {
              if (options.allowSell && progress.ownedJesters.isNotEmpty) {
                progress.sellOwnedJester(0, itemCatalog: itemCatalog);
                jesterSellCount += 1;
              } else {
                _increment(capacityBlockedJesters, jesterCandidate.contentId);
                if (allJestersBoughtAtEntry == null) {
                  _increment(
                    preCoverageCapacityBlockedJesters,
                    jesterCandidate.contentId,
                  );
                }
              }
            }
            if (progress.buyOffer(index)) {
              aggregateBoughtJesters.add(jesterCandidate.contentId);
              allJestersBoughtAtEntry ??=
                  aggregateBoughtJesters.length >= jesterIds.length
                  ? marketEntries
                  : null;
            } else if (progress.gold >= price) {
              _increment(capacityBlockedJesters, jesterCandidate.contentId);
              if (allJestersBoughtAtEntry == null) {
                _increment(
                  preCoverageCapacityBlockedJesters,
                  jesterCandidate.contentId,
                );
              }
            }
          }
        }

        final itemCandidate = _firstUnboughtItemOffer(
          progress,
          market,
          aggregateBoughtItems,
        );
        if (itemCandidate != null) {
          final item = itemCandidate.item;
          final price = itemCandidate.price;
          if (progress.gold < price) {
            _increment(goldBlockedItems, item.id);
            if (allItemsBoughtAtEntry == null) {
              _increment(preCoverageGoldBlockedItems, item.id);
            }
          } else {
            final bought = progress.buyItem(
              item,
              price: price,
              itemCatalog: itemCatalog,
            );
            if (bought) {
              aggregateBoughtItems.add(item.id);
              allItemsBoughtAtEntry ??=
                  aggregateBoughtItems.length >= itemIds.length
                  ? marketEntries
                  : null;
            } else if (options.allowSell &&
                _sellOneOwnedItemForPlacement(progress, item, itemById)) {
              itemSellCount += 1;
              if (progress.buyItem(
                item,
                price: price,
                itemCatalog: itemCatalog,
              )) {
                aggregateBoughtItems.add(item.id);
                allItemsBoughtAtEntry ??=
                    aggregateBoughtItems.length >= itemIds.length
                    ? marketEntries
                    : null;
              } else {
                _increment(capacityBlockedItems, item.id);
                if (allItemsBoughtAtEntry == null) {
                  _increment(preCoverageCapacityBlockedItems, item.id);
                }
              }
            } else {
              _increment(capacityBlockedItems, item.id);
              if (allItemsBoughtAtEntry == null) {
                _increment(preCoverageCapacityBlockedItems, item.id);
              }
            }
          }
        }
      }
    }
    finalGoldValues.add(progress.gold);
  }

  return <String, Object?>{
    'runs': options.runs,
    'market_entries': marketEntries,
    'markets_per_stage': options.marketsPerStage,
    'initial_gold': options.initialGold,
    'cashout_gold_per_market': options.cashoutGold,
    'allow_sell': options.allowSell,
    'catalog_totals': <String, Object?>{
      'jesters': jesterIds.length,
      'items': itemIds.length,
    },
    'seen': <String, Object?>{
      'jesters': aggregateSeenJesters.length,
      'items': aggregateSeenItems.length,
      'jester_coverage': _ratio(aggregateSeenJesters.length, jesterIds.length),
      'item_coverage': _ratio(aggregateSeenItems.length, itemIds.length),
      'all_jesters_seen_at_market_entry': allJestersSeenAtEntry,
      'all_items_seen_at_market_entry': allItemsSeenAtEntry,
      'unseen_jesters': _missingIds(jesterIds, aggregateSeenJesters),
      'unseen_items': _missingIds(itemIds, aggregateSeenItems),
    },
    'bought': <String, Object?>{
      'jesters': aggregateBoughtJesters.length,
      'items': aggregateBoughtItems.length,
      'jester_coverage': _ratio(
        aggregateBoughtJesters.length,
        jesterIds.length,
      ),
      'item_coverage': _ratio(aggregateBoughtItems.length, itemIds.length),
      'all_jesters_bought_at_market_entry': allJestersBoughtAtEntry,
      'all_items_bought_at_market_entry': allItemsBoughtAtEntry,
      'unbought_jesters': _missingIds(jesterIds, aggregateBoughtJesters),
      'unbought_items': _missingIds(itemIds, aggregateBoughtItems),
    },
    'blocked': <String, Object?>{
      'gold_jesters': _sumCounts(goldBlockedJesters),
      'gold_items': _sumCounts(goldBlockedItems),
      'capacity_jesters': _sumCounts(capacityBlockedJesters),
      'capacity_items': _sumCounts(capacityBlockedItems),
      'pre_collection_gold_jesters': _sumCounts(preCoverageGoldBlockedJesters),
      'pre_collection_gold_items': _sumCounts(preCoverageGoldBlockedItems),
      'pre_collection_capacity_jesters': _sumCounts(
        preCoverageCapacityBlockedJesters,
      ),
      'pre_collection_capacity_items': _sumCounts(
        preCoverageCapacityBlockedItems,
      ),
      'top_gold_jesters': _topCounts(goldBlockedJesters),
      'top_gold_items': _topCounts(goldBlockedItems),
      'top_pre_collection_gold_jesters': _topCounts(
        preCoverageGoldBlockedJesters,
      ),
      'top_pre_collection_gold_items': _topCounts(preCoverageGoldBlockedItems),
      'top_capacity_jesters': _topCounts(capacityBlockedJesters),
      'top_capacity_items': _topCounts(capacityBlockedItems),
    },
    'sold': <String, Object?>{
      'jesters': jesterSellCount,
      'items': itemSellCount,
    },
    'final_gold': _intSummary(finalGoldValues),
  };
}

void _printReport(Map<String, Object?> report) {
  print('# Runtime market offer audit');
  print('- runs per stage: ${report['runs_per_stage']}');
  print('- seed: ${report['seed']}');
  print('- pressure profile: ${report['pressure_profile']}');
  print('## Watchlist');
  final watchCounts = (report['watch_counts'] as Map).cast<String, Object?>();
  for (final entry in watchCounts.entries) {
    print('- ${entry.key}: ${entry.value}');
  }
  print('## Top Jesters');
  for (final row in (report['top_jesters'] as List).take(12)) {
    final data = (row as Map).cast<String, Object?>();
    print("- ${data['id']}: ${data['count']}");
  }
  print('## Top Items');
  for (final row in (report['top_items'] as List).take(12)) {
    final data = (row as Map).cast<String, Object?>();
    print("- ${data['id']}: ${data['count']}");
  }
  final collection = (report['collection_audit'] as Map)
      .cast<String, Object?>();
  final seen = (collection['seen'] as Map).cast<String, Object?>();
  final bought = (collection['bought'] as Map).cast<String, Object?>();
  final blocked = (collection['blocked'] as Map).cast<String, Object?>();
  print('## Collection audit');
  print(
    '- seen coverage: jesters ${seen['jester_coverage']}, '
    'items ${seen['item_coverage']}',
  );
  print(
    '- bought coverage: jesters ${bought['jester_coverage']}, '
    'items ${bought['item_coverage']}',
  );
  print(
    '- blocked: gold jester ${blocked['gold_jesters']}, '
    'gold item ${blocked['gold_items']}, '
    'capacity jester ${blocked['capacity_jesters']}, '
    'capacity item ${blocked['capacity_items']}',
  );
  print(
    '- pre-collection blocked: gold jester '
    "${blocked['pre_collection_gold_jesters']}, "
    "gold item ${blocked['pre_collection_gold_items']}, "
    "capacity jester ${blocked['pre_collection_capacity_jesters']}, "
    "capacity item ${blocked['pre_collection_capacity_items']}",
  );
}

List<Map<String, Object?>> _topCounts(Map<String, int> counts) {
  final entries = counts.entries.toList(growable: false)
    ..sort((a, b) {
      final countOrder = b.value.compareTo(a.value);
      if (countOrder != 0) return countOrder;
      return a.key.compareTo(b.key);
    });
  return [
    for (final entry in entries.take(20))
      <String, Object?>{'id': entry.key, 'count': entry.value},
  ];
}

void _increment(Map<String, int> counts, String id) {
  counts[id] = (counts[id] ?? 0) + 1;
}

int _sumCounts(Map<String, int> counts) =>
    counts.values.fold<int>(0, (sum, value) => sum + value);

double _ratio(int numerator, int denominator) {
  if (denominator <= 0) return 1;
  return double.parse((numerator / denominator).toStringAsFixed(4));
}

List<String> _missingIds(Set<String> allIds, Set<String> presentIds) {
  final missing = allIds.difference(presentIds).toList(growable: false)..sort();
  return missing;
}

Map<String, Object?> _intSummary(List<int> values) {
  if (values.isEmpty) {
    return <String, Object?>{'min': 0, 'avg': 0, 'max': 0};
  }
  final sorted = List<int>.of(values)..sort();
  final sum = values.fold<int>(0, (total, value) => total + value);
  return <String, Object?>{
    'min': sorted.first,
    'avg': double.parse((sum / values.length).toStringAsFixed(2)),
    'max': sorted.last,
  };
}

RummiMarketOfferView? _firstUnboughtJesterOffer(
  RummiRunProgress progress,
  RummiMarketRuntimeFacade market,
  Set<String> aggregateBoughtIds,
) {
  for (final offer in market.offers) {
    if (!aggregateBoughtIds.contains(offer.contentId)) return offer;
  }
  for (final offer in market.offers) {
    if (!progress.boughtJesterIds.contains(offer.contentId)) return offer;
  }
  return market.offers.isEmpty ? null : market.offers.first;
}

RummiMarketItemOfferView? _firstUnboughtItemOffer(
  RummiRunProgress progress,
  RummiMarketRuntimeFacade market,
  Set<String> aggregateBoughtIds,
) {
  for (final offer in market.itemOffers) {
    if (!aggregateBoughtIds.contains(offer.contentId)) return offer;
  }
  for (final offer in market.itemOffers) {
    if (!progress.boughtItemIds.contains(offer.contentId)) return offer;
  }
  return market.itemOffers.isEmpty ? null : market.itemOffers.first;
}

bool _sellOneOwnedItemForPlacement(
  RummiRunProgress progress,
  ItemDefinition target,
  Map<String, ItemDefinition> itemById,
) {
  for (final entry in progress.itemInventory.ownedItems) {
    final item = itemById[entry.itemId];
    if (item == null || !item.sellable || item.placement != target.placement) {
      continue;
    }
    return progress.sellOwnedItem(item);
  }
  return false;
}

class _Options {
  const _Options({
    required this.runs,
    required this.seed,
    required this.stages,
    required this.marketsPerStage,
    required this.initialGold,
    required this.cashoutGold,
    required this.allowSell,
    required this.jesterCatalogPath,
    required this.itemCatalogPath,
    required this.pressureProfile,
    required this.jsonOutPath,
  });

  factory _Options.parse(List<String> args) {
    var runs = _defaultRuns;
    var seed = 92000;
    var stages = List<int>.generate(8, (index) => index + 1);
    var marketsPerStage = 3;
    var initialGold = 10;
    var cashoutGold = 10;
    var allowSell = true;
    var jesterCatalogPath = _defaultJesterCatalogPath;
    var itemCatalogPath = _defaultItemCatalogPath;
    var pressureProfile = RummiMarketPressureProfile.standard;
    String? jsonOutPath;

    for (var index = 0; index < args.length; index++) {
      final arg = args[index];
      String readValue() {
        index += 1;
        if (index >= args.length) {
          throw FormatException('Missing value for $arg');
        }
        return args[index];
      }

      switch (arg) {
        case '--runs':
          runs = int.parse(readValue());
        case '--seed':
          seed = int.parse(readValue());
        case '--stages':
          stages = readValue()
              .split(',')
              .where((part) => part.trim().isNotEmpty)
              .map((part) => int.parse(part.trim()))
              .toList(growable: false);
        case '--markets-per-stage':
          marketsPerStage = int.parse(readValue());
        case '--initial-gold':
          initialGold = int.parse(readValue());
        case '--cashout-gold':
          cashoutGold = int.parse(readValue());
        case '--allow-sell':
          allowSell = _parseBool(readValue());
        case '--jesters':
          jesterCatalogPath = readValue();
        case '--items':
          itemCatalogPath = readValue();
        case '--pressure-profile':
          pressureProfile = switch (readValue()) {
            'standard' => RummiMarketPressureProfile.standard,
            'high_stakes' => RummiMarketPressureProfile.highStakes,
            final value => throw FormatException(
              'Unknown pressure profile: $value',
            ),
          };
        case '--json-out':
          jsonOutPath = readValue();
        default:
          throw FormatException('Unknown argument: $arg');
      }
    }

    return _Options(
      runs: runs,
      seed: seed,
      stages: stages,
      marketsPerStage: marketsPerStage,
      initialGold: initialGold,
      cashoutGold: cashoutGold,
      allowSell: allowSell,
      jesterCatalogPath: jesterCatalogPath,
      itemCatalogPath: itemCatalogPath,
      pressureProfile: pressureProfile,
      jsonOutPath: jsonOutPath,
    );
  }

  final int runs;
  final int seed;
  final List<int> stages;
  final int marketsPerStage;
  final int initialGold;
  final int cashoutGold;
  final bool allowSell;
  final String jesterCatalogPath;
  final String itemCatalogPath;
  final RummiMarketPressureProfile pressureProfile;
  final String? jsonOutPath;
}

bool _parseBool(String value) {
  return switch (value) {
    'true' || '1' || 'yes' => true,
    'false' || '0' || 'no' => false,
    _ => throw FormatException('Expected boolean, got $value'),
  };
}
