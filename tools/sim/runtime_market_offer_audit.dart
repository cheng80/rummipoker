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

  for (final stage in options.stages) {
    final stageJesterCounts = <String, int>{};
    final stageItemCounts = <String, int>{};
    final stageWatchCounts = {for (final id in _watchIds) id: 0};
    var jesterOfferCount = 0;
    var itemOfferCount = 0;

    for (var seed = 0; seed < options.runs; seed++) {
      final progress = RummiRunProgress()
        ..stageIndex = stage
        ..gold = 999
        ..marketModifiers = RummiMarketModifierState(
          itemOfferRerollOffset: seed,
        );
      progress.openShop(
        catalog: jesterCatalog.shopCatalog,
        rng: Random(options.seed + stage * 1009 + seed),
        pressureProfile: options.pressureProfile,
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
    'by_stage': byStage,
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

class _Options {
  const _Options({
    required this.runs,
    required this.seed,
    required this.stages,
    required this.jesterCatalogPath,
    required this.itemCatalogPath,
    required this.pressureProfile,
    required this.jsonOutPath,
  });

  factory _Options.parse(List<String> args) {
    var runs = _defaultRuns;
    var seed = 92000;
    var stages = List<int>.generate(8, (index) => index + 1);
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
      jesterCatalogPath: jesterCatalogPath,
      itemCatalogPath: itemCatalogPath,
      pressureProfile: pressureProfile,
      jsonOutPath: jsonOutPath,
    );
  }

  final int runs;
  final int seed;
  final List<int> stages;
  final String jesterCatalogPath;
  final String itemCatalogPath;
  final RummiMarketPressureProfile pressureProfile;
  final String? jsonOutPath;
}
