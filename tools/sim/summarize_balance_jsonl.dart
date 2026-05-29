import 'dart:convert';
import 'dart:io';

import 'run_balance_sim.dart';

Future<void> main(List<String> args) async {
  final code = await summarizeBalanceJsonl(args);
  if (code != 0) exitCode = code;
}

Future<int> summarizeBalanceJsonl(
  List<String> args, {
  StringSink? out,
  StringSink? err,
}) async {
  final output = out ?? stdout;
  final errors = err ?? stderr;
  if (args.isEmpty || args.first == '--help' || args.first == '-h') {
    errors.writeln(_usage);
    return args.isEmpty ? 64 : 0;
  }

  String? outPath;
  final inputPath = args.first;
  for (var index = 1; index < args.length; index++) {
    final arg = args[index];
    String readValue() {
      if (index + 1 >= args.length) {
        throw FormatException('Missing value for $arg');
      }
      return args[++index];
    }

    switch (arg) {
      case '--out':
        outPath = readValue();
      default:
        throw FormatException('Unknown argument: $arg');
    }
  }

  try {
    final input = File(inputPath);
    if (!input.existsSync()) {
      throw FormatException('JSONL file not found: $inputPath');
    }
    final summary = BalanceSimSummaryAccumulator(sourcePath: input.path);
    var lineNumber = 0;
    for (final line in input.readAsLinesSync()) {
      lineNumber += 1;
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('Line $lineNumber is not a JSON object');
      }
      summary.add(decoded);
    }

    final encoded = jsonEncode(summary.toJson());
    if (outPath == null) {
      output.writeln(encoded);
    } else {
      final file = File(outPath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(encoded);
    }
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
    'Usage: dart run tools/sim/summarize_balance_jsonl.dart logs/sim/raw.jsonl [--out logs/sim/summary.json]';
