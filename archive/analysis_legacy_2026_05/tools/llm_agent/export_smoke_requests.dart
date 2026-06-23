import 'dart:convert';
import 'dart:io';

import 'smoke_session_factory.dart';

Future<void> main(List<String> args) async {
  final config = _Config.parse(args);
  final out = File(config.outPath);
  out.parent.createSync(recursive: true);
  final sink = out.openWrite();
  try {
    for (var index = 0; index < config.count; index++) {
      final session = buildLlmSmokeSession(config.seed + index, index);
      final request = buildLimitedLlmSmokeRequest(
        session: session,
        requestId: 'llm_smoke_${config.seed}_$index',
        index: index,
      );
      sink.writeln(jsonEncode(request.toJson()));
    }
  } finally {
    await sink.close();
  }
  stdout.writeln('requests: ${out.path}');
  stdout.writeln('count: ${config.count}');
}

class _Config {
  const _Config({
    required this.outPath,
    required this.count,
    required this.seed,
  });

  final String outPath;
  final int count;
  final int seed;

  static _Config parse(List<String> args) {
    var outPath = 'archive/analysis_legacy_2026_05/local_ignored_generated/logs/llm/requests_smoke.jsonl';
    var count = 10;
    var seed = 20260529;
    for (var i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--out':
          outPath = args[++i];
        case '--count':
          count = int.parse(args[++i]);
        case '--seed':
          seed = int.parse(args[++i]);
        case '--help':
          _printUsageAndExit();
        default:
          throw FormatException('Unknown arg: ${args[i]}');
      }
    }
    if (count <= 0) {
      throw const FormatException('--count must be positive');
    }
    return _Config(outPath: outPath, count: count, seed: seed);
  }
}

Never _printUsageAndExit() {
  stdout.writeln(
    'Usage: dart run archive/analysis_legacy_2026_05/tools/llm_agent/export_smoke_requests.dart '
    '--out archive/analysis_legacy_2026_05/local_ignored_generated/logs/llm/requests_smoke.jsonl [--count 10] [--seed 20260529]',
  );
  exit(0);
}
