import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tools/sim/runtime_market_offer_audit.dart' as audit;

void main() {
  test('runtime market collection audit gathers meaningful coverage', () {
    const standardOutPath =
        'logs/sim/runtime_market_collection_audit_standard_r800_20260511_064500.json';
    const affordabilityOutPath =
        'logs/sim/runtime_market_collection_audit_affordability_r800_20260511_064500.json';

    final standardReport = _runAudit(outPath: standardOutPath, cashoutGold: 10);
    final standardCollection =
        standardReport['collection_audit'] as Map<String, dynamic>;
    final standardSeen = standardCollection['seen'] as Map<String, dynamic>;
    final standardBought = standardCollection['bought'] as Map<String, dynamic>;
    final standardBlocked =
        standardCollection['blocked'] as Map<String, dynamic>;

    expect(standardSeen['jester_coverage'], greaterThanOrEqualTo(0.95));
    expect(standardSeen['item_coverage'], greaterThanOrEqualTo(0.95));
    expect(standardBought['jester_coverage'], greaterThanOrEqualTo(0.80));
    expect(standardBought['item_coverage'], greaterThanOrEqualTo(0.35));
    expect(standardBlocked['gold_items'], greaterThan(0));
    expect(
      standardBlocked['pre_collection_gold_items'],
      lessThanOrEqualTo(standardBlocked['gold_items'] as num),
    );
    expect(
      standardBought['all_items_bought_at_market_entry'] ??
          standardCollection['market_entries'],
      lessThanOrEqualTo(standardCollection['market_entries'] as num),
    );

    final affordabilityReport = _runAudit(
      outPath: affordabilityOutPath,
      cashoutGold: 25,
    );
    final affordabilityCollection =
        affordabilityReport['collection_audit'] as Map<String, dynamic>;
    final affordabilityBought =
        affordabilityCollection['bought'] as Map<String, dynamic>;
    final affordabilityBlocked =
        affordabilityCollection['blocked'] as Map<String, dynamic>;

    expect(
      affordabilityBought['item_coverage'],
      greaterThanOrEqualTo(standardBought['item_coverage'] as num),
    );
    expect(
      affordabilityBlocked['gold_items'],
      lessThanOrEqualTo(standardBlocked['gold_items'] as num),
    );
  });
}

Map<String, dynamic> _runAudit({
  required String outPath,
  required int cashoutGold,
}) {
  audit.main([
    '--runs',
    '800',
    '--seed',
    '92100',
    '--markets-per-stage',
    '3',
    '--initial-gold',
    '10',
    '--cashout-gold',
    '$cashoutGold',
    '--allow-sell',
    'true',
    '--json-out',
    outPath,
  ]);
  return jsonDecode(File(outPath).readAsStringSync()) as Map<String, dynamic>;
}
