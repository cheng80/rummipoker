# Task 9 Reviewer Minipacket V2

Decision requested: APPROVE or REJECT Task 9.

## Code Scope

Changed:

- `tools/sim/runtime_market_offer_audit.dart`
  - adds `fresh_run_metadata` with commit hash, item catalog sha256, Jester catalog sha256, current input paths, `archive_inputs: []`, `advisory_only: true`
  - excludes 5 hold/redesign item IDs from collection audit item denominator
- `test/tools/sim/runtime_market_offer_audit_metadata_test.dart`
  - new metadata/current-only test
- `test/tools/sim/runtime_market_collection_audit_smoke_test.dart`
  - now asserts normal item denominator is 86
- `docs/planning/leveling/HEURISTIC_LEVELING_SIMULATION_DIRECTION.md`
  - adds advisory-only Task 9 probe note

Not changed:

- no pricing
- no rarity
- no market weights
- no target scores
- no scoring rules
- no save format

## Required Evidence

- RED metadata absent: `.omo/evidence/task-9-red-fresh-metadata.txt`
- GREEN tests: `.omo/evidence/task-9-runtime-market-audit-tests.txt`
- Analyzer: `.omo/evidence/task-9-dart-analyze.txt`
- Small probe report: `.omo/evidence/task-9-small-probe.md`
- Archive isolation: `.omo/evidence/task-9-archive-isolation.txt`
- Cleanup: `.omo/evidence/task-9-cleanup.txt`

## Probe Result

- Runtime offer audit JSON has current catalog hashes and empty archive inputs.
- Watchlist exposure exists, but small sequence economy trace has 0 catalog watchlist purchase/source events.
- S1-S4 tiny sequence path_clear_rate is 0.0 for both `none` and `shop_slot_market_v9`; report records this as an advisory bot/path endurance risk, not as a balance change.

Expected verdict if no issue: approve Task 9 as a current-catalog advisory gate, not a broad balance restart.
