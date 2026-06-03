# Task 9 Compact Review Packet

Request: review Task 9 Fresh Data And Small Pricing Probe Restart.

## Scope

Implemented the current-catalog small probe gate and archive isolation guard.

Code changes:

- `tools/sim/runtime_market_offer_audit.dart`
  - Adds `fresh_run_metadata` to JSON output:
    - `commit_hash`
    - `item_catalog_sha256`
    - `jester_catalog_sha256`
    - current input paths
    - `archive_inputs: []`
    - `advisory_only: true`
  - Collection audit item denominator now excludes the 5 hold/redesign item IDs, matching Task 6 normal item source of truth.
- `test/tools/sim/runtime_market_offer_audit_metadata_test.dart`
  - New RED/GREEN coverage for fresh metadata and archive isolation fields.
- `test/tools/sim/runtime_market_collection_audit_smoke_test.dart`
  - Locks collection audit item total at 86 normal-market candidates.
- `docs/planning/leveling/HEURISTIC_LEVELING_SIMULATION_DIRECTION.md`
  - Records the 2026-06-03 small probe result as advisory-only.

No pricing, rarity, market weight, target score, scoring rule, or save format changes were made.

## RED/GREEN Evidence

RED:

- `.omo/evidence/task-9-red-fresh-metadata.txt`
- Failure: `fresh_run_metadata` was absent.

GREEN:

- `.omo/evidence/task-9-green-fresh-metadata.txt`
- Metadata test passed.

Regression:

- `.omo/evidence/task-9-runtime-market-audit-tests.txt`
- Metadata test and existing collection audit smoke passed.
- Collection audit now reports normal item candidate denominator 86.

Analyzer:

- `.omo/evidence/task-9-dart-analyze.txt`
- Result: no issues found.

## Probe Evidence

Runtime offer audit:

- `.omo/evidence/task-9-runtime-market-offer-audit.txt`
- JSON: `logs/sim/task9_runtime_market_offer_audit_20260603.json`
- Watchlist exposure:
  - `reroll_token`: 400
  - `trade_ticket`: 240
  - `full_house_study`: 80
  - `four_kind_study`: 0
  - `straight_flush_study`: 80
  - `ride_the_bus`: 16
  - `jester_hook`: 320
- Seen coverage: Jesters 1.0, Items 0.9884.
- Bought coverage: Jesters 1.0, Items 0.8837.

Small sequence sim:

- `.omo/evidence/task-9-balance-sim-small-probe-run.txt`
- JSONL: `logs/sim/task9_fresh_small_probe_20260603.jsonl`
- Summary: `logs/sim/task9_fresh_small_probe_20260603_summary.json`
- S1-S4 standard, fixed seed, `full_run_policy_v1`, `none` vs `shop_slot_market_v9`.

Balance summary:

- `.omo/evidence/task-9-balance-summary-report.txt`
- `none`: path_clear_rate 0.0, avg_total_score_ratio 1.0279.
- `shop_slot_market_v9`: path_clear_rate 0.0, avg_total_score_ratio 1.0253.

Economy audit:

- `.omo/evidence/task-9-economy-audit.txt`
- JSON: `logs/sim/task9_fresh_small_probe_20260603_economy_audit.json`
- Purchase events: 29.
- Catalog watchlist content/proxy/source events are all 0 in this tiny sequence trace.

Small probe report:

- `.omo/evidence/task-9-small-probe.md`
- Conclusion is explicitly advisory-only:
  - no archived ML output is used
  - no auto pricing/weight/target recommendation is applied
  - no early-game overpowered Fate/watchlist frequency observed from sequence purchase trace
  - broad restart should begin only from current catalog/runtime artifacts

Archive isolation:

- `.omo/evidence/task-9-archive-isolation.txt`
- Generated Task 9 artifacts were checked for archive path references.
- `archive_inputs` is empty.

Cleanup:

- `.omo/evidence/task-9-cleanup.txt`
- No Task 9 Flutter test, flutter_tester, WebDriver, ChromeDriver, Flutter web server, or headless Chrome residue remains; tmux unavailable.

## Risk Check

Primary risk:

- Collection audit could silently count hold/redesign cards as expected market candidates.

Mitigation:

- Smoke test now asserts `catalog_totals.items == 86`.
- Task 6 source-of-truth already locks normal item 86 and hold item 5.

Primary probe caveat:

- The small sequence sim reports path_clear_rate 0.0 for both tested profiles. This is not used to change balance. It is recorded as a bot/path endurance signal before broad S1-S8 sweeps.
