import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('full run bot uses one persisted WebDriver browser', () {
    final runner = File('tools/full_run_bot.sh').readAsStringSync();

    expect(runner, contains('-d web-server'));
    expect(
      runner,
      contains(
        r'--web-browser-flag="--user-data-dir=$BROWSER_PROFILE_DIR/chrome"',
      ),
    );
    expect(runner, contains('PERSISTENCE_RESUME_STARTED'));
    expect(runner, contains('full_run_trace_fresh.jsonl'));
  });
}
