import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final code = await reportBalanceSummary(args);
  if (code != 0) exitCode = code;
}

Future<int> reportBalanceSummary(
  List<String> args, {
  StringSink? out,
  StringSink? err,
}) async {
  final output = out ?? stdout;
  final errors = err ?? stderr;
  if (args.length != 1 || args.first == '--help' || args.first == '-h') {
    errors.writeln(_usage);
    return args.length == 1 ? 0 : 64;
  }

  try {
    final file = File(args.single);
    if (!file.existsSync()) {
      throw FormatException('Summary file not found: ${args.single}');
    }
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Summary JSON must be an object');
    }
    final report = BalanceSummaryReport.fromJson(decoded);
    output.write(report.render());
    return 0;
  } on FormatException catch (error) {
    errors.writeln(error.message);
    errors.writeln(_usage);
    return 64;
  } on Object catch (error) {
    errors.writeln(error);
    return 1;
  }
}

const _usage =
    'Usage: dart run tools/sim/report_balance_summary.dart logs/sim/summary.json';

class BalanceSummaryReport {
  const BalanceSummaryReport({required this.groups});

  final List<BalanceSummaryReportGroup> groups;

  factory BalanceSummaryReport.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['groups'];
    if (rawGroups is! List) {
      throw const FormatException('Summary JSON missing groups list');
    }
    final groups =
        rawGroups
            .map(
              (raw) => BalanceSummaryReportGroup.fromJson(
                Map<String, dynamic>.from(raw as Map),
              ),
            )
            .toList()
          ..sort(_compareGroups);
    return BalanceSummaryReport(groups: List.unmodifiable(groups));
  }

  String render() {
    final buffer = StringBuffer();
    buffer.writeln(
      'loadout      station tier  diff      clear  turns  maxHit  first  last   discard  outcomes',
    );
    for (final group in groups) {
      buffer.writeln(group.renderLine());
    }
    return buffer.toString();
  }

  static int _compareGroups(
    BalanceSummaryReportGroup a,
    BalanceSummaryReportGroup b,
  ) {
    final loadout = a.loadoutId.compareTo(b.loadoutId);
    if (loadout != 0) return loadout;
    final station = a.station.compareTo(b.station);
    if (station != 0) return station;
    final tier = _tierOrder(a.blindTier).compareTo(_tierOrder(b.blindTier));
    if (tier != 0) return tier;
    return _difficultyOrder(
      a.difficulty,
    ).compareTo(_difficultyOrder(b.difficulty));
  }

  static int _tierOrder(String tier) {
    return switch (tier) {
      'small' => 0,
      'big' => 1,
      'boss' => 2,
      _ => 99,
    };
  }

  static int _difficultyOrder(String difficulty) {
    return switch (difficulty) {
      'relaxed' => 0,
      'standard' => 1,
      'pressure' => 2,
      _ => 99,
    };
  }
}

class BalanceSummaryReportGroup {
  const BalanceSummaryReportGroup({
    required this.loadoutId,
    required this.station,
    required this.blindTier,
    required this.difficulty,
    required this.clearRate,
    required this.avgTurnCount,
    required this.avgMaxSingleConfirmScore,
    required this.avgFirstScoreTurn,
    required this.avgLastScoreTurn,
    required this.avgDiscardedBoardCount,
    required this.outcomeCounts,
  });

  final String loadoutId;
  final int station;
  final String blindTier;
  final String difficulty;
  final num clearRate;
  final num avgTurnCount;
  final num avgMaxSingleConfirmScore;
  final num? avgFirstScoreTurn;
  final num? avgLastScoreTurn;
  final num avgDiscardedBoardCount;
  final Map<String, int> outcomeCounts;

  factory BalanceSummaryReportGroup.fromJson(Map<String, dynamic> json) {
    return BalanceSummaryReportGroup(
      loadoutId: _requiredString(json, 'loadout_id'),
      station: _requiredInt(json, 'station'),
      blindTier: _requiredString(json, 'blind_tier'),
      difficulty: _requiredString(json, 'difficulty'),
      clearRate: _requiredNum(json, 'clear_rate'),
      avgTurnCount: _requiredNum(json, 'avg_turn_count'),
      avgMaxSingleConfirmScore: _requiredNum(
        json,
        'avg_max_single_confirm_score',
      ),
      avgFirstScoreTurn: _optionalNum(json, 'avg_first_score_turn'),
      avgLastScoreTurn: _optionalNum(json, 'avg_last_score_turn'),
      avgDiscardedBoardCount: _requiredNum(json, 'avg_discarded_board_count'),
      outcomeCounts: _parseOutcomeCounts(json['outcome_counts']),
    );
  }

  String renderLine() {
    return [
      loadoutId.padRight(12),
      '$station'.padLeft(7),
      blindTier.padRight(5),
      difficulty.padRight(9),
      _percent(clearRate).padLeft(6),
      _fixed(avgTurnCount).padLeft(6),
      _fixed(avgMaxSingleConfirmScore).padLeft(7),
      _optionalFixed(avgFirstScoreTurn).padLeft(6),
      _optionalFixed(avgLastScoreTurn).padLeft(6),
      _fixed(avgDiscardedBoardCount).padLeft(8),
      _outcomesText(outcomeCounts),
    ].join(' ');
  }

  static String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is String) return value;
    throw FormatException('Summary group missing string field: $field');
  }

  static int _requiredInt(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is int) return value;
    throw FormatException('Summary group missing int field: $field');
  }

  static num _requiredNum(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is num) return value;
    throw FormatException('Summary group missing numeric field: $field');
  }

  static num? _optionalNum(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null || value is num) return value as num?;
    throw FormatException('Summary group has non-numeric field: $field');
  }

  static Map<String, int> _parseOutcomeCounts(Object? raw) {
    if (raw is! Map) {
      throw const FormatException('Summary group missing outcome_counts map');
    }
    return raw.map(
      (key, value) => MapEntry(key as String, (value as num).toInt()),
    );
  }

  static String _percent(num value) {
    return '${(value.toDouble() * 100).round()}%';
  }

  static String _fixed(num value) {
    return value.toDouble().toStringAsFixed(1);
  }

  static String _optionalFixed(num? value) {
    return value == null ? '-' : _fixed(value);
  }

  static String _outcomesText(Map<String, int> outcomes) {
    if (outcomes.isEmpty) return '-';
    final entries = outcomes.entries.toList()
      ..sort((a, b) {
        final count = b.value.compareTo(a.value);
        if (count != 0) return count;
        return a.key.compareTo(b.key);
      });
    return entries.map((entry) => '${entry.key}:${entry.value}').join(',');
  }
}
