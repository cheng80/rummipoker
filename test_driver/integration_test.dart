// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() {
  return integrationDriver(
    responseDataCallback: (data) async {
      if (data == null) return;

      final tracePath = data['full_run_trace_path'];
      final traceRows = data['full_run_trace_rows'];
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
      }

      await writeResponseData(data);
    },
    writeResponseOnFailure: true,
  );
}
