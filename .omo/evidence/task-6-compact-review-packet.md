# Task 6 Compact Review Packet: Item/Jester/Tool/Gear Policy Cleanup

## Scope

Plan task: Item/Jester/Tool/Gear Policy Cleanup.

Changed Task 6 files:

- `test/logic/item_definition_test.dart`
- `docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md`
- `.omo/notepads/active-execution-task1-catalog-census.md`

No catalog JSON, runtime, rarity, price, or market weight value was changed in Task 6. This slice locks current policy as source-of-truth before future balance/data work.

## RED Evidence

Artifact: `.omo/evidence/task-6-red-policy-catalog-match.txt`

Focused test:

`policy cleanup docs classify full catalog and watchlist values`

Right-reason failure:

- `Expected: contains 'Exposure group source of truth'`
- Existing docs had family lists and Ritual split, but no complete exposure-group source-of-truth for full Item + Jester catalog or watchlist value lock.

## Implementation

Added `Exposure group source of truth` in `docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md` with:

- `normal item 86`
- `normal Jester 43`
- `hold item 5`
- `debug item 0`
- `deleted legacy 3`

The section lists:

- all 86 normal item IDs
- all 43 normal Jester IDs
- hold item IDs: `ritual_coupon`, `ritual_lens`, `line_pack_ticket`, `seal_vendor`, `prune_vendor`
- deleted legacy IDs: `boss_memory`, `thin_memory`, `minor_memory`

Added watchlist value lock table:

- `reroll_token` | common | 5G | 1G | low-tier utility
- `trade_ticket` | uncommon | 6G | 3G | market pool mutation
- `full_house_study` | rare | 9G | 4G | advanced study probe
- `four_kind_study` | rare | 10G | 5G | advanced study probe
- `straight_flush_study` | rare | 12G | 6G | advanced study probe
- `ride_the_bus` | uncommon | 6G | stateful_growth | redesign watch

## Test Coverage

New test in `test/logic/item_definition_test.dart`:

- Reads `data/common/items_common_v1.json`.
- Reads `data/common/jesters_common_phase5.json`.
- Reads policy/current docs.
- Computes normal items as all catalog items except the five hold items.
- Asserts counts:
  - normal item 86
  - normal Jester 43
  - hold item 5
- Asserts docs contain:
  - `Exposure group source of truth`
  - `normal item 86`
  - `normal Jester 43`
  - `hold item 5`
  - `debug item 0`
  - `deleted legacy 3`
- Asserts every normal item ID, Jester ID, hold ID, and deleted legacy ID is documented.
- Asserts watchlist values match current catalog/Jester JSON and docs.

## GREEN Evidence

Focused GREEN:

- Command: `/Users/cheng80/flutter/bin/flutter test test/logic/item_definition_test.dart --name "policy cleanup docs classify full catalog and watchlist values"`
- Artifact: `.omo/evidence/task-6-green-policy-catalog-match.txt`
- Result: `00:00 +1: All tests passed!`

Bash catalog artifact:

- Artifact: `.omo/evidence/task-6-policy-catalog-match.txt`
- Includes:
  - `item total: 91`
  - `jester total: 43`
  - `normal item 86: True`
  - `normal Jester 43: True`
  - watchlist item/Jester values

Watchlist focused evidence:

- Artifact: `.omo/evidence/task-6-watchlist-values.txt`
- Result: `00:00 +1: All tests passed!`

Acceptance suites:

- `/Users/cheng80/flutter/bin/flutter test test/logic/item_definition_test.dart`
  - Artifact: `.omo/evidence/task-6-item-definition-test.txt`
  - Result: `00:00 +12: All tests passed!`
- `/Users/cheng80/flutter/bin/flutter test test/logic/rummi_market_facade_test.dart`
  - Artifact: `.omo/evidence/task-6-rummi-market-facade-test.txt`
  - Result: `00:00 +42: All tests passed!`

Static:

- `/Users/cheng80/flutter/bin/dart analyze test/logic/item_definition_test.dart`
- Artifact: `.omo/evidence/task-6-dart-analyze.txt`
- Result: `No issues found!`

Cleanup:

- Artifact: `.omo/evidence/task-6-cleanup.txt`
- Result: no Flutter test/flutter_tester/WebDriver/ChromeDriver/Flutter web server/headless Chrome residue.
- `tmux: unavailable`; evidence captured through command stdout artifacts.

## Reviewer Questions

Please audit:

1. Does the new test prove every current Item/Jester catalog ID is represented in the policy docs?
2. Does the watchlist lock cover the plan's named candidates: `trade_ticket`, `ride_the_bus`, advanced study cards, and `reroll_token`?
3. Is it acceptable that this Task 6 slice changes docs/tests only and intentionally defers actual price/rarity/weight changes to later data/probe work?
