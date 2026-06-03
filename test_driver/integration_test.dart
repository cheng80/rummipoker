// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() {
  return integrationDriver(
    timeout: const Duration(minutes: 120),
    responseDataCallback: (data) async {
      if (data == null) return;

      final tracePath = data['full_run_trace_path'];
      final traceRows = data['full_run_trace_rows'];
      final profileDir =
          Platform.environment['FULL_RUN_BOT_BROWSER_PROFILE_DIR'];
      if (profileDir != null && profileDir.isNotEmpty) {
        final checkpoint = data['full_run_checkpoint_b64'];
        if (checkpoint is String && checkpoint.isNotEmpty) {
          final file = File('$profileDir/latest_checkpoint.env');
          await file.parent.create(recursive: true);
          await file.writeAsString(
            'FULL_RUN_BOT_RESUME_SAVE_B64=$checkpoint\n',
          );
          print('Wrote full-run checkpoint: ${file.path}');
        }
        final carryover = data['full_run_challenge_carryover_b64'];
        if (carryover is String && carryover.isNotEmpty) {
          final file = File('$profileDir/latest_challenge_carryover.env');
          await file.parent.create(recursive: true);
          await file.writeAsString(
            'FULL_RUN_BOT_CHALLENGE_CARRYOVER_B64=$carryover\n',
          );
          print('Wrote full-run challenge carryover: ${file.path}');
        }
      }
      if (tracePath is String && traceRows is List<dynamic>) {
        final file = File(tracePath);
        await file.parent.create(recursive: true);
        final sink = file.openWrite();
        for (final row in traceRows) {
          sink.writeln(jsonEncode(row));
        }
        await sink.close();
        print('Wrote full-run trace: $tracePath');
        data.remove('full_run_trace_rows');
      } else if (tracePath is String && traceRows is int) {
        print(
          'Full-run trace streamed through driver log: '
          '$tracePath ($traceRows rows)',
        );
      }

      await writeResponseData(data);
    },
    writeResponseOnFailure: true,
  );
}
