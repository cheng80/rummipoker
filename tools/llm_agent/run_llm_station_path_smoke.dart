import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_market_facade.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_ruleset.dart';
import 'package:rummipoker/services/blind_selection_spec.dart';
import 'package:rummipoker/services/new_run_setup.dart';

import '../sim/balance_action_executor.dart';
import '../sim/bot_policy.dart';
import '../sim/llm_action_schema.dart';
import '../sim/llm_state_exporter.dart';
import '../sim/planner_bot.dart';
import 'llm_policy_client.dart';
import 'llm_policy_guidance.dart';

const _jesterCatalogPath = 'data/common/jesters_common_phase5.json';
const _itemCatalogPath = 'data/common/items_common_v1.json';

Future<void> main(List<String> args) async {
  final config = _Config.parse(args);
  final jesterCatalog = RummiJesterCatalog.fromJsonString(
    File(_jesterCatalogPath).readAsStringSync(),
  );
  final itemCatalog = ItemCatalog.fromJsonString(
    File(_itemCatalogPath).readAsStringSync(),
  );
  final out = File(config.outPath)..parent.createSync(recursive: true);
  final report = File(config.reportOutPath)..parent.createSync(recursive: true);
  final rows = <Map<String, Object?>>[];

  for (var runIndex = 0; runIndex < config.runs; runIndex++) {
    final seed = config.seed + runIndex;
    final llmSession = RummiPokerGridSession(runSeed: seed);
    final baselineSession = RummiPokerGridSession(runSeed: seed);
    final runProgress = RummiRunProgress();
    final baselineProgress = RummiRunProgress();

    var pathStopped = false;
    for (
      var station = config.stationStart;
      station <= config.stationEnd;
      station++
    ) {
      if (pathStopped) break;
      for (final tier in config.tiers) {
        final spec = BlindSelectionSpecBuilder.resolveSpec(
          tier: tier,
          stationIndex: station,
          difficulty: config.difficulty,
          runModifier: NewRunModifier.basic,
          runSeed: seed,
          ruleset: RummiRuleset.currentDefaults,
        );
        _startBlind(runProgress, llmSession, spec, station, seed);
        _startBlind(baselineProgress, baselineSession, spec, station, seed);
        llmSession.blind.bossModifier = spec.bossModifier;
        baselineSession.blind.bossModifier = spec.bossModifier;

        final blindRows = await _runBlind(
          config: config,
          rows: rows,
          runIndex: runIndex,
          seed: seed,
          station: station,
          tier: tier,
          spec: spec,
          llmSession: llmSession,
          baselineSession: baselineSession,
          runProgress: runProgress,
          baselineProgress: baselineProgress,
        );
        await _runMarketDecision(
          config: config,
          rows: rows,
          runIndex: runIndex,
          seed: seed,
          station: station,
          tier: tier,
          runProgress: runProgress,
          jesterCatalog: jesterCatalog,
          itemCatalog: itemCatalog,
        );
        if (!blindRows.cleared && !config.continueAfterFail) {
          pathStopped = true;
          break;
        }
      }
    }
  }

  final sink = out.openWrite();
  try {
    for (final row in rows) {
      sink.writeln(jsonEncode(row));
    }
  } finally {
    await sink.close();
  }
  report.writeAsStringSync(_buildReport(rows, config));
  stdout.writeln('out: ${out.path}');
  stdout.writeln('report: ${report.path}');
}

Future<void> _runMarketDecision({
  required _Config config,
  required List<Map<String, Object?>> rows,
  required int runIndex,
  required int seed,
  required int station,
  required BlindTier tier,
  required RummiRunProgress runProgress,
  required RummiJesterCatalog jesterCatalog,
  required ItemCatalog itemCatalog,
}) async {
  runProgress.openShop(
    catalog: jesterCatalog.shopCatalog,
    rng: Random(seed + station * 31 + tier.index),
  );
  final facade = RummiMarketRuntimeFacade.fromRunProgress(
    runProgress,
    itemCatalog: itemCatalog,
  );
  final legalActions = _buildMarketLegalActions(facade, runProgress);
  final requestId =
      'llm_market_${config.seed}_${runIndex}_s${station}_${tier.name}';
  final requestJson = <String, dynamic>{
    'schema_version': 1,
    'request_id': requestId,
    'bot_policy': 'llm_gemma4_market_v1',
    'state': {
      'schema_version': 1,
      'phase': 'market',
      'station': station,
      'blind_tier': tier.name,
      'gold': runProgress.gold,
      'owned_jesters': [
        for (final entry in facade.ownedEntries)
          {
            'slot_index': entry.slotIndex,
            'id': entry.contentId,
            'sell_price': entry.sellPrice,
          },
      ],
      'owned_items': [
        for (final entry in runProgress.itemInventory.ownedItems)
          {
            'id': entry.itemId,
            'count': entry.count,
            'placement': entry.placement.name,
          },
      ],
      'policy_guidance': const {
        'contract_id': 'contest_full_run_market_guidance_v1',
        'rules': [
          'Preserve enough gold for Q-slot and key item opportunities.',
          'Do not buy every Jester first if that starves item economy.',
          'Sell only weak or redundant holdings to enable stronger purchases.',
          'Reroll only when offers are low value and gold remains useful.',
          'Skip when no purchase improves survival, score, or economy path.',
        ],
      },
    },
    'legal_actions': legalActions,
  };
  final responseResult = await requestLocalJsonAction(
    requestJson: requestJson,
    config: config.marketClientConfig,
  );
  final response = responseResult.response;
  final selectedId = response?['selected_action_id'] as String?;
  final selected = legalActions
      .cast<Map<String, dynamic>>()
      .where((action) => action['id'] == selectedId)
      .firstOrNull;
  final execute = selected == null
      ? (ok: false, reason: 'invalid_or_missing_market_action')
      : _executeMarketAction(
          selected,
          runProgress: runProgress,
          itemCatalog: itemCatalog,
        );
  rows.add({
    'schema_version': 1,
    'row_type': 'llm_market_decision',
    'run_index': runIndex,
    'seed': seed,
    'station': station,
    'blind_tier': tier.name,
    'request_id': requestId,
    'model': config.model,
    'gold_before': facade.gold,
    'gold_after': runProgress.gold,
    'candidate_count': legalActions.length,
    'is_valid': selected != null,
    'selected_action_id': selectedId,
    'selected_action_type': selected?['type'],
    'execute_ok': execute.ok,
    'execute_reason': execute.reason,
    'latency_ms': responseResult.latencyMs,
    'llm_error': responseResult.error,
  });
}

List<Map<String, Object?>> _buildMarketLegalActions(
  RummiMarketRuntimeFacade facade,
  RummiRunProgress runProgress,
) {
  final actions = <Map<String, Object?>>[];
  for (final offer in facade.offers) {
    if (!offer.isAffordable) continue;
    actions.add({
      'id': 'buy_jester_${offer.slotIndex}_${offer.contentId}',
      'type': 'buyJester',
      'offer_index': offer.slotIndex,
      'content_id': offer.contentId,
      'cost': offer.price,
      'reason_hint': 'buy an affordable Jester offer',
    });
  }
  for (final offer in facade.itemOffers) {
    if (!offer.isAffordable) continue;
    actions.add({
      'id': 'buy_item_${offer.slotIndex}_${offer.contentId}',
      'type': 'buyItem',
      'offer_index': offer.slotIndex,
      'content_id': offer.contentId,
      'placement': offer.item.placement.name,
      'cost': offer.price,
      'reason_hint': 'buy an affordable item/tool/gear/passive offer',
    });
  }
  for (final entry in facade.ownedEntries) {
    if (entry.sellPrice <= 0) continue;
    actions.add({
      'id': 'sell_jester_${entry.slotIndex}_${entry.contentId}',
      'type': 'sellJester',
      'slot_index': entry.slotIndex,
      'content_id': entry.contentId,
      'gold_gain': entry.sellPrice,
      'reason_hint': 'sell a Jester only if it enables a stronger path',
    });
  }
  for (final entry in runProgress.itemInventory.ownedItems) {
    if (entry.count <= 0) continue;
    actions.add({
      'id': 'sell_item_${entry.itemId}',
      'type': 'sellItem',
      'content_id': entry.itemId,
      'placement': entry.placement.name,
      'reason_hint': 'sell a weak or redundant item only when useful',
    });
  }
  if (facade.gold >= facade.rerollCost) {
    actions.add({
      'id': 'reroll_jester',
      'type': 'reroll',
      'lane': 'jester',
      'cost': facade.rerollCost,
    });
  }
  for (final entry in [
    ('quickSlot', ItemPlacement.quickSlot, facade.quickSlotRerollCost),
    ('passive', ItemPlacement.passiveRack, facade.passiveRerollCost),
    ('tool', ItemPlacement.inventory, facade.toolRerollCost),
    ('gear', ItemPlacement.equipped, facade.gearRerollCost),
  ]) {
    if (facade.gold >= entry.$3) {
      actions.add({
        'id': 'reroll_${entry.$1}',
        'type': 'reroll',
        'lane': entry.$1,
        'placement': entry.$2.name,
        'cost': entry.$3,
      });
    }
  }
  actions.add(const {
    'id': 'skip_market',
    'type': 'skip',
    'reason_hint': 'skip when no offer improves the run path',
  });
  return actions.take(32).toList(growable: false);
}

({bool ok, String reason}) _executeMarketAction(
  Map<String, dynamic> action, {
  required RummiRunProgress runProgress,
  required ItemCatalog itemCatalog,
}) {
  switch (action['type']) {
    case 'buyJester':
      final index = action['offer_index'] as int? ?? -1;
      return (ok: runProgress.buyOffer(index), reason: 'buyJester');
    case 'buyItem':
      final itemId = action['content_id'] as String?;
      final item = itemId == null ? null : itemCatalog.findById(itemId);
      if (item == null) return (ok: false, reason: 'missing_item');
      return (
        ok: runProgress.buyItem(item, itemCatalog: itemCatalog),
        reason: 'buyItem',
      );
    case 'sellJester':
      final slotIndex = action['slot_index'] as int? ?? -1;
      return (
        ok: runProgress.sellOwnedJester(slotIndex, itemCatalog: itemCatalog),
        reason: 'sellJester',
      );
    case 'sellItem':
      final itemId = action['content_id'] as String?;
      final item = itemId == null ? null : itemCatalog.findById(itemId);
      if (item == null) return (ok: false, reason: 'missing_item');
      return (ok: runProgress.sellOwnedItem(item), reason: 'sellItem');
    case 'reroll':
      final placementRaw = action['placement'] as String?;
      if (placementRaw == null) {
        return (
          ok: runProgress.rerollShop(catalog: const [], rng: Random(1)),
          reason: 'rerollJester',
        );
      }
      final placement = ItemPlacement.values.firstWhere(
        (value) => value.name == placementRaw,
        orElse: () => ItemPlacement.inventory,
      );
      return (
        ok: runProgress.rerollItemOffers(placement: placement),
        reason: 'rerollItem',
      );
    case 'skip':
      return (ok: true, reason: 'skip');
    default:
      return (ok: false, reason: 'unknown_market_action');
  }
}

Future<({bool cleared})> _runBlind({
  required _Config config,
  required List<Map<String, Object?>> rows,
  required int runIndex,
  required int seed,
  required int station,
  required BlindTier tier,
  required BlindSelectionSpec spec,
  required RummiPokerGridSession llmSession,
  required RummiPokerGridSession baselineSession,
  required RummiRunProgress runProgress,
  required RummiRunProgress baselineProgress,
}) async {
  for (var turn = 0; turn < config.turnCapPerBlind; turn++) {
    final expiry = llmSession.evaluateExpirySignals();
    if (llmSession.blind.isTargetMet || expiry.isNotEmpty) {
      rows.add(
        _terminalRow(
          config: config,
          runIndex: runIndex,
          station: station,
          tier: tier,
          turn: turn,
          spec: spec,
          llmSession: llmSession,
          baselineSession: baselineSession,
          stopReason: llmSession.blind.isTargetMet
              ? 'cleared'
              : expiry.map((signal) => signal.name).join(','),
        ),
      );
      return (cleared: llmSession.blind.isTargetMet);
    }

    final requestId =
        'llm_path_${config.seed}_${runIndex}_s${station}_${tier.name}_$turn';
    final request = applyFullRunPolicyGuidance(
      buildLlmActionRequest(
        llmSession,
        requestId: requestId,
        jesters: const [],
        runtimeSnapshot: runProgress.buildRuntimeSnapshot(),
        station: station,
        blindTier: tier.name,
        turnCount: turn,
      ),
      maxActions: config.maxLegalActions,
    );
    final responseResult = await requestLocalLlmAction(
      request: request,
      config: config.clientConfig,
    );
    final validation = responseResult.response == null
        ? LlmActionValidationResult.invalid(responseResult.error ?? 'no_llm')
        : validateLlmActionResponse(
            response: LlmActionResponse.fromJson(responseResult.response!),
            legalActions: request.legalActions,
          );
    final fallbackAction = const ContestPolicyV1BotPolicy().chooseAction(
      llmSession,
      jesters: const [],
      runtimeSnapshot: runProgress.buildRuntimeSnapshot(),
    );
    final selectedAction = validation.balanceAction ?? fallbackAction;
    final llmExecute = executeBalanceAction(
      llmSession,
      selectedAction,
      runtimeSnapshot: runProgress.buildRuntimeSnapshot(),
    );
    final baselineAction = const ContestPolicyV1BotPolicy().chooseAction(
      baselineSession,
      jesters: const [],
      runtimeSnapshot: baselineProgress.buildRuntimeSnapshot(),
    );
    final baselineExecute = executeBalanceAction(
      baselineSession,
      baselineAction,
      runtimeSnapshot: baselineProgress.buildRuntimeSnapshot(),
    );

    rows.add({
      'schema_version': 1,
      'row_type': 'llm_station_path_turn',
      'run_index': runIndex,
      'seed': seed,
      'station': station,
      'blind_tier': tier.name,
      'turn': turn,
      'target_score': spec.targetScore,
      'boss_modifier_id': spec.bossModifier?.id,
      'request_id': requestId,
      'model': config.model,
      'is_valid': validation.isValid,
      'invalid_reason': validation.invalidReason,
      'used_fallback': !validation.isValid,
      'selected_action_id': validation.selectedAction?.id,
      'selected_action_type': validation.selectedAction?.type,
      'executed_action_type': selectedAction.type.name,
      'baseline_action_type': baselineAction.type.name,
      'diverged_from_baseline':
          selectedAction.type != baselineAction.type ||
          selectedAction.handIndex != baselineAction.handIndex ||
          selectedAction.row != baselineAction.row ||
          selectedAction.col != baselineAction.col ||
          selectedAction.toRow != baselineAction.toRow ||
          selectedAction.toCol != baselineAction.toCol,
      'llm_execute_ok': llmExecute.ok,
      'llm_execute_reason': llmExecute.reason,
      'baseline_execute_ok': baselineExecute.ok,
      'baseline_execute_reason': baselineExecute.reason,
      'llm_score_after': llmExecute.scoreAfter,
      'baseline_score_after': baselineExecute.scoreAfter,
      'llm_reached_target': llmSession.blind.isTargetMet,
      'baseline_reached_target': baselineSession.blind.isTargetMet,
      'llm_score_delta': llmExecute.scoreDelta,
      'baseline_score_delta': baselineExecute.scoreDelta,
      'llm_board_occupancy_after': llmExecute.boardOccupancyAfter,
      'llm_hand_size_after': llmExecute.handSizeAfter,
      'llm_deck_remaining_after': llmExecute.deckRemainingAfter,
      'latency_ms': responseResult.latencyMs,
      'llm_error': responseResult.error,
    });
    if (selectedAction.type == BalanceSimActionType.stop) {
      return (cleared: false);
    }
  }

  rows.add(
    _terminalRow(
      config: config,
      runIndex: runIndex,
      station: station,
      tier: tier,
      turn: config.turnCapPerBlind,
      spec: spec,
      llmSession: llmSession,
      baselineSession: baselineSession,
      stopReason: 'turn_cap',
    ),
  );
  return (cleared: llmSession.blind.isTargetMet);
}

void _startBlind(
  RummiRunProgress runProgress,
  RummiPokerGridSession session,
  BlindSelectionSpec spec,
  int station,
  int seed,
) {
  runProgress.startBlind(
    session,
    stationIndex: station,
    blindTierIndex: spec.tier.index,
    shuffleSeed: _deriveBlindShuffleSeed(
      runSeed: seed,
      stationIndex: station,
      blindTierIndex: spec.tier.index,
    ),
    targetScore: spec.targetScore,
    boardDiscards: spec.boardDiscards,
    handDiscards: spec.handDiscards,
    maxHandSize: spec.maxHandSize,
    applyRoundEndDecay: false,
  );
}

int _deriveBlindShuffleSeed({
  required int runSeed,
  required int stationIndex,
  required int blindTierIndex,
}) {
  final stageSeed = runSeed * 1103515245 + 12345 + stationIndex * 1013904223;
  final mixed = (stageSeed + (blindTierIndex + 1) * 2654435761) & 0x7fffffff;
  return mixed == 0 ? stationIndex + blindTierIndex + 1 : mixed;
}

Map<String, Object?> _terminalRow({
  required _Config config,
  required int runIndex,
  required int station,
  required BlindTier tier,
  required int turn,
  required BlindSelectionSpec spec,
  required RummiPokerGridSession llmSession,
  required RummiPokerGridSession baselineSession,
  required String stopReason,
}) {
  return {
    'schema_version': 1,
    'row_type': 'llm_station_path_terminal',
    'run_index': runIndex,
    'station': station,
    'blind_tier': tier.name,
    'turn': turn,
    'target_score': spec.targetScore,
    'boss_modifier_id': spec.bossModifier?.id,
    'stop_reason': stopReason,
    'llm_score_after': llmSession.blind.scoreTowardBlind,
    'baseline_score_after': baselineSession.blind.scoreTowardBlind,
    'llm_reached_target': llmSession.blind.isTargetMet,
    'baseline_reached_target': baselineSession.blind.isTargetMet,
  };
}

String _buildReport(List<Map<String, Object?>> rows, _Config config) {
  final decisions = rows
      .where((row) => row['row_type'] == 'llm_station_path_turn')
      .toList(growable: false);
  final terminals = rows
      .where((row) => row['row_type'] == 'llm_station_path_terminal')
      .toList(growable: false);
  final marketDecisions = rows
      .where((row) => row['row_type'] == 'llm_market_decision')
      .toList(growable: false);
  final valid = decisions.where((row) => row['is_valid'] == true).length;
  final fallback = decisions
      .where((row) => row['used_fallback'] == true)
      .length;
  final validMarket = marketDecisions
      .where((row) => row['is_valid'] == true)
      .length;
  final diverged = decisions
      .where((row) => row['diverged_from_baseline'] == true)
      .length;
  final cleared = terminals
      .where((row) => row['llm_reached_target'] == true)
      .length;
  final avgLatency = decisions.isEmpty
      ? 0.0
      : decisions.fold<int>(
              0,
              (sum, row) => sum + ((row['latency_ms'] as num?)?.toInt() ?? 0),
            ) /
            decisions.length;
  return [
    '# LLM Station Path Smoke',
    '',
    '## Summary',
    '',
    '- model: ${config.model}',
    '- runs: ${config.runs}',
    '- station_range: S${config.stationStart}~S${config.stationEnd}',
    '- tiers: ${config.tiers.map((tier) => tier.name).join(', ')}',
    '- turn_cap_per_blind: ${config.turnCapPerBlind}',
    '- decisions: ${decisions.length}',
    '- market_decisions: ${marketDecisions.length}',
    '- terminal_blinds: ${terminals.length}',
    '- cleared_blinds: $cleared',
    '- valid responses: $valid',
    '- valid market responses: $validMarket',
    '- fallback executions: $fallback',
    '- fallback_rate: ${_rate(fallback, decisions.length)}',
    '- diverged_from_baseline: $diverged',
    '- divergence_rate: ${_rate(diverged, decisions.length)}',
    '- avg_latency_ms: ${avgLatency.toStringAsFixed(1)}',
    '',
    '## Action Types',
    '',
    for (final entry in _countBy(decisions, 'executed_action_type').entries)
      '- ${entry.key}: ${entry.value}',
    '',
    '## Market Action Types',
    '',
    for (final entry in _countBy(
      marketDecisions,
      'selected_action_type',
    ).entries)
      '- ${entry.key}: ${entry.value}',
    '',
    '## Scope',
    '',
    'This is the first S1-S8-capable LLM station path runner.',
    'It uses real blind specs, target scores, resources, and boss modifiers.',
    'Market buy/sell/reroll decision contracts are included as smoke rows.',
    'Battle item-use choices and full economy application are still pending before this can be treated as full balance evidence.',
  ].join('\n');
}

Map<String, int> _countBy(List<Map<String, Object?>> rows, String key) {
  final counts = <String, int>{};
  for (final row in rows) {
    final value = row[key] as String? ?? 'unknown';
    counts[value] = (counts[value] ?? 0) + 1;
  }
  return counts;
}

String _rate(int numerator, int denominator) {
  if (denominator == 0) return '0.0000';
  return (numerator / denominator).toStringAsFixed(4);
}

class _Config {
  const _Config({
    required this.outPath,
    required this.reportOutPath,
    required this.runs,
    required this.seed,
    required this.stationStart,
    required this.stationEnd,
    required this.tiers,
    required this.turnCapPerBlind,
    required this.continueAfterFail,
    required this.maxLegalActions,
    required this.difficulty,
    required this.model,
    required this.temperature,
    required this.topP,
    required this.timeoutSeconds,
  });

  final String outPath;
  final String reportOutPath;
  final int runs;
  final int seed;
  final int stationStart;
  final int stationEnd;
  final List<BlindTier> tiers;
  final int turnCapPerBlind;
  final bool continueAfterFail;
  final int maxLegalActions;
  final NewRunDifficulty difficulty;
  final String model;
  final double temperature;
  final double topP;
  final int timeoutSeconds;

  LlmPolicyClientConfig get clientConfig {
    return LlmPolicyClientConfig(
      model: model,
      temperature: temperature,
      topP: topP,
      timeoutSeconds: timeoutSeconds,
      requestDir: 'logs/llm/station_path_requests',
      responseDir: 'logs/llm/station_path_responses',
    );
  }

  LlmPolicyClientConfig get marketClientConfig {
    return LlmPolicyClientConfig(
      model: model,
      temperature: temperature,
      topP: topP,
      timeoutSeconds: timeoutSeconds,
      requestDir: 'logs/llm/market_decision_requests',
      responseDir: 'logs/llm/market_decision_responses',
    );
  }

  static _Config parse(List<String> args) {
    var outPath = 'logs/llm/station_path_smoke_20260529.jsonl';
    var reportOutPath =
        'analysis/leveling/reports/llm_station_path_smoke_20260529.md';
    var runs = 1;
    var seed = 20260529;
    var stationStart = 1;
    var stationEnd = 8;
    var tiers = const [BlindTier.small, BlindTier.big, BlindTier.boss];
    var turnCapPerBlind = 4;
    var continueAfterFail = false;
    var maxLegalActions = 24;
    var difficulty = NewRunDifficulty.standard;
    var model = 'gemma4:e4b';
    var temperature = 0.2;
    var topP = 0.9;
    var timeoutSeconds = 60;
    for (var i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--out':
          outPath = args[++i];
        case '--report-out':
          reportOutPath = args[++i];
        case '--runs':
          runs = int.parse(args[++i]);
        case '--seed':
          seed = int.parse(args[++i]);
        case '--station-start':
          stationStart = int.parse(args[++i]);
        case '--station-end':
          stationEnd = int.parse(args[++i]);
        case '--tiers':
          tiers = _parseTiers(args[++i]);
        case '--turn-cap-per-blind':
          turnCapPerBlind = int.parse(args[++i]);
        case '--continue-after-fail':
          continueAfterFail = true;
        case '--max-legal-actions':
          maxLegalActions = int.parse(args[++i]);
        case '--difficulty':
          difficulty = _parseDifficulty(args[++i]);
        case '--model':
          model = args[++i];
        case '--temperature':
          temperature = double.parse(args[++i]);
        case '--top-p':
          topP = double.parse(args[++i]);
        case '--timeout-seconds':
          timeoutSeconds = int.parse(args[++i]);
        case '--help':
          _printUsageAndExit();
        default:
          throw FormatException('Unknown arg: ${args[i]}');
      }
    }
    if (runs <= 0) throw const FormatException('--runs must be positive');
    if (stationStart <= 0 || stationEnd < stationStart) {
      throw const FormatException('station range must be positive and ordered');
    }
    if (turnCapPerBlind <= 0) {
      throw const FormatException('--turn-cap-per-blind must be positive');
    }
    return _Config(
      outPath: outPath,
      reportOutPath: reportOutPath,
      runs: runs,
      seed: seed,
      stationStart: stationStart,
      stationEnd: stationEnd,
      tiers: tiers,
      turnCapPerBlind: turnCapPerBlind,
      continueAfterFail: continueAfterFail,
      maxLegalActions: maxLegalActions,
      difficulty: difficulty,
      model: model,
      temperature: temperature,
      topP: topP,
      timeoutSeconds: timeoutSeconds,
    );
  }
}

List<BlindTier> _parseTiers(String raw) {
  final tiers = raw
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .map(BlindSelectionSpecBuilder.parseTier)
      .toList(growable: false);
  if (tiers.isEmpty) throw const FormatException('--tiers cannot be empty');
  return tiers;
}

NewRunDifficulty _parseDifficulty(String raw) {
  return switch (raw) {
    'relaxed' => NewRunDifficulty.relaxed,
    'challenge' => NewRunDifficulty.challenge,
    _ => NewRunDifficulty.standard,
  };
}

Never _printUsageAndExit() {
  stdout.writeln(
    'Usage: dart run tools/llm_agent/run_llm_station_path_smoke.dart '
    '--station-start 1 --station-end 8 --tiers small,big,boss '
    '--turn-cap-per-blind 4',
  );
  exit(0);
}
