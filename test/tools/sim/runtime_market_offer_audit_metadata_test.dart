import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tools/sim/runtime_market_offer_audit.dart' as audit;

void main() {
  test('runtime market offer audit records fresh current-only metadata', () {
    final outFile = File(
      '${Directory.systemTemp.path}/runtime_market_offer_audit_metadata.json',
    );
    if (outFile.existsSync()) outFile.deleteSync();

    audit.main([
      '--runs',
      '2',
      '--seed',
      '93000',
      '--stages',
      '1',
      '--markets-per-stage',
      '1',
      '--json-out',
      outFile.path,
    ]);

    final report =
        jsonDecode(outFile.readAsStringSync()) as Map<String, dynamic>;
    final metadata = report['fresh_run_metadata'] as Map<String, dynamic>;
    final inputs = metadata['inputs'] as Map<String, dynamic>;
    final archiveInputs = metadata['archive_inputs'] as List<dynamic>;

    expect(metadata['commit_hash'], isA<String>());
    expect((metadata['commit_hash'] as String), isNotEmpty);
    expect(metadata['item_catalog_sha256'], hasLength(64));
    expect(metadata['jester_catalog_sha256'], hasLength(64));
    expect(metadata['advisory_only'], isTrue);
    expect(inputs['items'], 'data/common/items_common_v1.json');
    expect(inputs['jesters'], 'data/common/jesters_common_phase5.json');
    expect(archiveInputs, isEmpty);
  });
}
