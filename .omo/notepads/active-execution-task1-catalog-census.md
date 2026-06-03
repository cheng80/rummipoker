# ULW Notepad: Task 1 Catalog Census

Started: 2026-06-03 09:09 KST

## Scope

Implement Task 1 from `.omo/plans/active-execution-plan-implementation.md`:
Catalog Census And Source-Of-Truth Repair.

## Skills Used

- `omo:ulw-loop`: user explicitly requested ultrawork execution; required for evidence-led goal loop.
- `omo:programming`: applies to Dart/test/script work if production or tests are edited.
- `caveman`: project default response mode; use concise Korean-friendly reporting.

## Initial Constraints

- Task 1 must not change runtime behavior, card rarity, price, market weight, or offer policy.
- Catalog counts must come from `data/common/items_common_v1.json`.
- Edit scope should stay to tests/docs/evidence unless census reveals a blocking mismatch.
- Because 3+ files may change, execute as a small slice: first census evidence and doc count repair only.

## Success Criteria

1. `task1_catalog_census_matches_docs`: automated test proves docs include current total, Ritual, Fate, active, hold/debug, deleted legacy counts.
   - RED evidence: `.omo/evidence/task-1-red-doc-census-test.txt`
   - GREEN evidence: `.omo/evidence/task-1-green-doc-census-test.txt`
   - Manual QA channel: tmux
   - Scenario: run `dart test test/logic/item_definition_test.dart --name "catalog census docs match current catalog"`
   - PASS: transcript contains passing test id and no failing assertion.
2. `task1_catalog_census_artifact`: command parses JSON and writes every Fate/Ritual id exactly once.
   - Evidence: `.omo/evidence/task-1-catalog-census.txt`
   - Manual QA channel: tmux
   - Scenario: run census command in tmux and capture transcript.
   - PASS: artifact has total item count, `ritual_line_effect` count, Fate count, active Ritual count, hold/debug count, deleted legacy IDs.
3. `task1_legacy_memory_refs`: grep verifies `boss_memory`, `thin_memory`, `minor_memory` references are documented as deleted/legacy or absent.
   - Evidence: `.omo/evidence/task-1-legacy-memory-refs.txt`
   - Manual QA channel: tmux
   - Scenario: run `rg "boss_memory|thin_memory|minor_memory" data docs lib test`.
   - PASS: no data/lib runtime reference; docs/test references explicitly state deleted/legacy.
4. `task1_diff_check`: `git diff --check` passes.
   - Evidence: `.omo/evidence/task-1-diff-check.txt`
   - Manual QA channel: tmux
   - PASS: transcript contains no whitespace error.

## Evidence Log

- RED captured: `.omo/evidence/task-1-red-doc-census-test.txt`
  - Focused test failed on stale `Item total: 94`.
- Extended RED captured: `.omo/evidence/task-1-red-extended-doc-census-test.txt`
  - Focused test failed on stale policy/runtime/spec docs.
- GREEN captured: `.omo/evidence/task-1-green-extended-doc-census-test.txt`
  - Focused doc census test passed.
- Census artifact: `.omo/evidence/task-1-catalog-census.txt`
  - `totalItemCount: 91`, `ritualLineEffectCount: 31`, `fateTransformCount: 16`, `activeRitualCount: 31`, `holdDebugRitualCount: 0`.
- Legacy refs: `.omo/evidence/task-1-legacy-memory-refs.txt`
  - No data/lib runtime references remain; remaining docs/test refs state deleted legacy status.
- Stale search: `.omo/evidence/task-1-stale-count-search.txt`
  - Remaining stale-number matches are historical candidate/presentation/leveling records, not current source-of-truth claims.
- Verification:
  - `.omo/evidence/task-1-item-definition-test.txt`: passed.
  - `.omo/evidence/task-1-rummi-market-facade-test.txt`: passed after rerun; first parallel attempt hit Flutter native-assets race.
  - `.omo/evidence/task-1-dart-analyze-test-file.txt`: passed.
  - `.omo/evidence/task-1-diff-check.txt`: passed.
- Cleanup: `.omo/evidence/task-1-cleanup.txt`
  - No QA-spawned Flutter test, webdriver, server, or long find process remains; tmux unavailable.
- Reviewer: approved via compact packet.
  - `.omo/evidence/task-1-compact-review-packet.md`
  - Verdict: `APPROVE: The packet proves RED-to-GREEN on the catalog census, includes the expected census artifact with totals and deleted legacy IDs, shows stale current-count assertions removed or demoted to historical references, and records passing test/analyze/diff-check plus cleanup receipt.`

## Reviewer Timeout Resolution

- `codex-ultrawork-reviewer` with the full 430-line diff/evidence bundle timed out twice.
- A worker reviewer with the same broad artifact list also timed out.
- A one-line ping worker returned immediately, proving the agent runtime itself was healthy.
- A compact 116-line review packet returned approval immediately.
- Operational fix: for future verification gates, create a compact review packet first and keep the full diff/evidence available as backup.

## Task 2 Fate Runtime And Market Policy Evidence

Status: verified with no production change.

Reason no new RED test was added: existing tests already directly cover the Task 2 acceptance criteria, and no production/catalog/market code was changed in this slice.

Evidence:

- `.omo/evidence/task-2-fate-runtime.txt`
  - Focused runtime test passed: `fate cards transform selected board lines into scoring tile sets`.
- `.omo/evidence/task-2-fate-fixtures.txt`
  - Focused fixture test passed: `fate transform fixtures apply selected line into expected hand rank`.
- `.omo/evidence/task-2-fate-market-policy.txt`
  - Focused catalog guard passed: all 16 Fate IDs are rare-or-higher, high-tier Fate IDs are legendary/high price.
- `.omo/evidence/task-2-fate-market-pressure.txt`
  - Focused market pressure test passed.
- `.omo/evidence/task-2-item-effect-runtime-full.txt`
  - Full `test/logic/item_effect_runtime_test.dart` passed.
- `.omo/evidence/task-2-debug-fixture-service-full.txt`
  - Full `test/services/debug_run_fixture_service_test.dart` passed.
- `.omo/evidence/task-2-fate-catalog-policy-census.txt`
  - Lists all 16 Fate IDs, actions, expected ranks, rarity, and prices.
- `.omo/evidence/task-2-cleanup.txt`
  - No QA-spawned Flutter test, webdriver, or server process remains.

## Task 3 Fate Required Comprehension Feedback

Status: implemented and verified.

Problem closed:

- Fate line transform already had the main selection/confirm flow, but widget tests and reviewer evidence could not reliably identify candidate, selected, confirm, flash, and result-feedback states.
- Initial RED evidence failed on missing `fate-line-selection-overlay` key.

Implementation:

- Added stable test/QA keys for Fate line and tile selection overlays.
- Added candidate/selected tap targets on non-intersection line hotspots so row/col/diag markers do not fight for the same center tap.
- Added `fate-line-confirm-button` key on the confirm action.
- Added deterministic `fate-line-transform-flash-<line>` key for the applied line flash.
- Added `fateTransform` flag to item-effect feedback so Fate result feedback exposes `fate-line-transform-result-feedback` without depending on localized detail text.
- Split the new Fate widget test into `test/views/game/game_view_fate_feedback_test.dart` because the existing long `game_view_item_feedback_test.dart` has same-file order interference when another EasyLocalization/GameView test is appended after it.

Evidence:

- RED: `.omo/evidence/task-3-red-fate-confirm-flow.txt`
  - Failed on missing `fate-line-selection-overlay`.
- GREEN focused: `.omo/evidence/task-3-green-fate-confirm-flow.txt`
  - `fate line transform requires selection confirm feedback` passed.
- Fate file: `.omo/evidence/task-3-game-view-fate-feedback-test.txt`
  - Full new Fate feedback test file passed.
- Existing feedback regression: `.omo/evidence/task-3-game-view-item-feedback-test.txt`
  - Existing `game_view_item_feedback_test.dart` passed after keeping the new Fate scenario in its own file.
- Analyze: `.omo/evidence/task-3-dart-analyze.txt`
  - No issues found for changed AGENTS, view, widget, and test files.
- Cleanup: `.omo/evidence/task-3-cleanup.txt`
  - No Task 3 flutter test/flutter_tester/WebDriver/ChromeDriver/server process remains; only existing user Chrome Helper processes matched the broad cleanup grep.

Reviewer protocol update:

- Added AGENTS.md rule: when ultrawork reviewer does not respond to a large artifact bundle, stop repeating the large request and create a 100-150 line compact review packet first.

Task 3 reviewer approval:

- Packet: `.omo/evidence/task-3-compact-review-packet.md`
- Reviewer: `task3_compact_reviewer_v2`
- Verdict: `APPROVE: v2 packet proves red failure, green confirm-flow behavior, painter-backed selected/candidate distinction, regression/analyze pass, and process cleanup.`

## Task 4 Ritual Pool Split And Hold Policy

Status: implemented and verified as a docs/test policy split slice.

Implementation:

- Added catalog-driven test `ritual pool split docs match catalog groups` in `test/logic/item_definition_test.dart`.
- The test requires active Ritual 31 IDs, hold market-helper 5 IDs, deleted legacy 3 IDs, debug-only 0, and explicit `normal market 제외` wording across current/policy/runtime docs.
- Updated `docs/current_system/CURRENT_CARD_CATALOG_TABLE.md` with active/hold/debug/deleted Ritual rows.
- Updated `docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md` with exact active/hold/debug/deleted source-of-truth counts and IDs.
- Updated `docs/planning/feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md` with runtime-policy split and normal market exclusion wording.

Evidence:

- RED: `.omo/evidence/task-4-red-ritual-pool-doc-split.txt`
  - Failed because `boss_memory` was not documented with a backticked ID in the current source docs.
- GREEN: `.omo/evidence/task-4-green-ritual-pool-doc-split.txt`
  - Focused split docs test passed.
- Market filter: `.omo/evidence/task-4-ritual-market-filter.txt`
  - Existing focused market test passed: deferred ritual items are filtered while active ritual items remain.
- Full item definition: `.omo/evidence/task-4-item-definition-test.txt`
  - Full `test/logic/item_definition_test.dart` passed.
- Analyze: `.omo/evidence/task-4-dart-analyze.txt`
  - No issues found for `test/logic/item_definition_test.dart`.
- Cleanup: `.omo/evidence/task-4-cleanup.txt`
  - No Task 4 test/browser/webdriver/server residual remains.

## Task 5 Ritual Selection, Flight, And Result Redesign

Status: implemented and verified.

Implementation:

- Added copied-tile identity keys in `_RitualDeckTileFlightPayload`: `ritual-deck-flight-tile-<index>-<tile code>`.
- Added gold flight container and coin keys in `_RitualGoldCoinFlights`: `ritual-gold-flight` and `ritual-gold-flight-coin-<index>`.
- Added one-file-per-GameView widget tests for:
  - tile copy Ritual selection/selected/confirm grammar and copied tile deck flight.
  - burn-line Ritual selection/selected/confirm grammar and gold coin flight.
  - no-valid-target Ritual failure path, proving the item remains and no selection overlay/flight starts.

Evidence:

- RED copy flight: `.omo/evidence/task-5-red-ritual-copy-flight.txt`
  - Failed on missing `ritual-deck-flight-tile-*` key after confirm.
- RED gold flight: `.omo/evidence/task-5-red-ritual-gold-flight.txt`
  - Failed on missing `ritual-gold-flight` after confirm.
- GREEN copy flight: `.omo/evidence/task-5-game-view-ritual-feedback-test.txt`
  - Full new copy-flight test file passed.
- GREEN gold flight: `.omo/evidence/task-5-green-ritual-gold-flight.txt`
  - Gold flight and `+3G` badge test passed.
- GREEN no-target: `.omo/evidence/task-5-ritual-no-target-test.txt`
  - No-valid-target failure path test passed.
- Runtime draw order: `.omo/evidence/task-5-ritual-runtime-copy-draw.txt`
  - Existing runtime test passed: copied Ritual tiles are placed on next draw.
- Fixture regression: `.omo/evidence/task-5-ritual-fixtures.txt`
  - Representative Ritual fixture test passed.
- Analyze: `.omo/evidence/task-5-dart-analyze.txt`
  - No issues found for changed production/test files.
- Cleanup: `.omo/evidence/task-5-cleanup.txt`
  - No Task 5 Flutter test, flutter_tester, WebDriver, ChromeDriver, Flutter web server, or headless Chrome residue remains; tmux unavailable.

Reviewer:

- Packet: `.omo/evidence/task-5-compact-review-packet.md`
- Verdict: `APPROVE: Packet covers the Task 5 slice.`

## Task 6 Item/Jester/Tool/Gear Policy Cleanup

Status: implemented and verified as a policy source-of-truth/test slice.

Implementation:

- Added `policy cleanup docs classify full catalog and watchlist values` in `test/logic/item_definition_test.dart`.
- Added `Exposure group source of truth` to `docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md`.
- Locked current exposure groups:
  - normal item 86
  - normal Jester 43
  - hold item 5
  - debug item 0
  - deleted legacy 3
- Locked watchlist values for `reroll_token`, `trade_ticket`, advanced study cards, and `ride_the_bus`.
- No catalog price/rarity/weight/runtime value changed in this slice.

Evidence:

- RED: `.omo/evidence/task-6-red-policy-catalog-match.txt`
  - Failed on missing `Exposure group source of truth`.
- GREEN focused: `.omo/evidence/task-6-green-policy-catalog-match.txt`
  - Focused policy cleanup docs/watchlist test passed.
- Reviewer RED follow-up: `.omo/evidence/task-6-red-stale-board-line-ritual-policy.txt`
  - Failed because the policy family table still said Board-Line Ritual current catalog was 0.
- Reviewer fix GREEN: `.omo/evidence/task-6-green-stale-board-line-ritual-policy.txt`
  - Focused test passed after the family table now says `현재 active Ritual 31장`.
- Bash policy artifact: `.omo/evidence/task-6-policy-catalog-match.txt`
  - Lists item/Jester totals, normal/hold/debug/deleted counts, rarity counts, and watchlist values.
- Watchlist test: `.omo/evidence/task-6-watchlist-values.txt`
  - Focused watchlist values test passed.
- Full item definition: `.omo/evidence/task-6-item-definition-test.txt`
  - Full `test/logic/item_definition_test.dart` passed.
- Full market facade: `.omo/evidence/task-6-rummi-market-facade-test.txt`
  - Full `test/logic/rummi_market_facade_test.dart` passed.
- Analyze: `.omo/evidence/task-6-dart-analyze.txt`
  - No issues found for `test/logic/item_definition_test.dart`.
- Cleanup: `.omo/evidence/task-6-cleanup.txt`
  - No Task 6 Flutter test, flutter_tester, WebDriver, ChromeDriver, Flutter web server, or headless Chrome residue remains; tmux unavailable.

Reviewer:

- v1 packet rejected: missing full diff/evidence contents.
- v2 packet rejected: reviewer found stale contradiction in the Board-Line Ritual family row.
- Fix added a test assertion so stale `현재 catalog 0개` current-state wording fails.
- v3 packet: `.omo/evidence/task-6-compact-review-packet-v3.md`
- Verdict: `APPROVE: UNCONDITIONAL APPROVAL.`

## Task 7 Seal, Enhancement, Save/Restore Sync

Status: implemented and verified.

Implementation:

- Added `test/views/game/widgets/game_tile_modifier_copy_test.dart`.
- Added all-enum modifier roundtrip coverage in `test/logic/tile_model_test.dart`.
- Replaced `wild_painted` and `lucky_tile` detail copy from `예정` wording to concrete current-state text: `현재 확정 점수 효과 없음`.

Evidence:

- RED: `.omo/evidence/task-7-red-tile-detail-copy.txt`
  - Failed on `wildPainted` effect text containing `예정`.
- GREEN tile detail: `.omo/evidence/task-7-green-tile-detail-copy.txt`
  - All persisted enhancement/seal/edition labels and effect copy are non-empty and do not contain `예정` or `준비 중`.
- Tile model roundtrip: `.omo/evidence/task-7-tile-model-roundtrip.txt`
  - Full `test/logic/tile_model_test.dart` passed, including every persisted enhancement/seal/edition value and legacy `risk_seal`/`riskSeal` aliases.
- Save roundtrip: `.omo/evidence/task-7-save-roundtrip.txt`
  - ActiveRun save/restore focused tests passed for added deck tiles, explicit `tileOffers` modifiers, deck, board, hand, eliminated, and stage-start snapshot modifiers.
- Settlement modifiers: `.omo/evidence/task-7-settlement-modifiers.txt`
  - Focused `rummi_session_test.dart` settlement modifier tests passed for enhancement, red seal repeat, editions, seal score/gold/growth, anchor, overlap, bridge, cross memory, and glass tile removal from addedDeckTiles.
- Analyze: `.omo/evidence/task-7-dart-analyze.txt`
  - No issues found for changed production/test files.
- Cleanup: `.omo/evidence/task-7-cleanup.txt`
  - No Task 7 Flutter test, flutter_tester, WebDriver, ChromeDriver, Flutter web server, or headless Chrome residue remains; tmux unavailable.

Reviewer:

- v1 packet rejected: explicit `tileOffers` evidence missing, untracked new test file diff absent, and placeholder-copy assertion not visible enough.
- Fix added explicit `run progress saves and restores tileOffers modifiers` test and v2 packet embeds new test file content.
- v2 packet: `.omo/evidence/task-7-compact-review-packet-v2.md`
- Verdict: `APPROVE: v2 evidence satisfies the requested review points.`

## Task 8 Behavior-Preserving Structure And Performance Refactor

Status: implemented and awaiting reviewer.

Implementation:

- Moved shared modal/barrier responsibilities out of `lib/views/game/widgets/game_shared_widgets.dart`.
- Added `lib/views/game/widgets/game_shared_modal_widgets.dart` as a `part of 'game_shared_widgets.dart'`.
- Kept all public names and implementations behavior-preserving:
  - `kGameModalBarrierColor`
  - `kGameFeedbackBarrierColor`
  - `GameInputBarrier`
  - `GameModalCard`
  - `showGameFramedDialog`
- No catalog, market weight, save format, or scoring rule files were changed in this slice.

Evidence:

- Baseline focused widget regression: `.omo/evidence/task-8-widget-baseline.txt`
  - `GameRummiTileCard` badge and `GameTopHud` objective focused tests passed before the move.
- Post-refactor focused widget regression: `.omo/evidence/task-8-widget-regression.txt`
  - Same focused tests passed after the move.
- Dialog behavior:
  - `.omo/evidence/task-8-options-dialog-test.txt`
  - `.omo/evidence/task-8-run-info-dialog-test.txt`
  - `.omo/evidence/task-8-game-view-dialog-test.txt`
  - Options barrier, run info dialog, stage-clear/game-over dialog cases passed.
- Analyze: `.omo/evidence/task-8-dart-analyze.txt`
  - No issues found for `game_shared_widgets.dart` and `game_shared_modal_widgets.dart`.
- File responsibility: `.omo/evidence/task-8-file-sizes.txt`
  - `game_shared_widgets.dart` reduced from 882 to 804 lines.
  - New `game_shared_modal_widgets.dart` is 80 lines.
  - Modal symbols now live only in `game_shared_modal_widgets.dart`.
- Cleanup: `.omo/evidence/task-8-cleanup.txt`
  - No Task 8 Flutter test, flutter_tester, WebDriver, ChromeDriver, Flutter web server, or headless Chrome residue remains; tmux unavailable.

Reviewer:

- Packet: `.omo/evidence/task-8-compact-review-packet.md`
- Verdict: `UNCONDITIONAL APPROVAL.`

## Task 9 Fresh Data And Small Pricing Probe Restart

Status: implemented and awaiting reviewer.

Implementation:

- Added fresh/current-only metadata to `tools/sim/runtime_market_offer_audit.dart`.
  - commit hash
  - item catalog sha256
  - Jester catalog sha256
  - input paths
  - empty archive input list
  - advisory-only flag
- Adjusted runtime market collection denominator to current normal-market item candidates, excluding the 5 hold/redesign item IDs.
- Added `test/tools/sim/runtime_market_offer_audit_metadata_test.dart`.
- Extended `test/tools/sim/runtime_market_collection_audit_smoke_test.dart` to lock item denominator at 86.
- Updated `docs/planning/leveling/HEURISTIC_LEVELING_SIMULATION_DIRECTION.md` with the 2026-06-03 small probe conclusion.

Evidence:

- RED metadata: `.omo/evidence/task-9-red-fresh-metadata.txt`
  - Failed because `fresh_run_metadata` was absent.
- GREEN metadata: `.omo/evidence/task-9-green-fresh-metadata.txt`
  - Metadata test passed.
- Runtime market audit tests: `.omo/evidence/task-9-runtime-market-audit-tests.txt`
  - Metadata test and collection audit smoke passed.
- Small sequence sim run: `.omo/evidence/task-9-balance-sim-small-probe-run.txt`
  - Generated `logs/sim/task9_fresh_small_probe_20260603.jsonl`.
  - Generated `logs/sim/task9_fresh_small_probe_20260603_summary.json`.
- Balance summary: `.omo/evidence/task-9-balance-summary-report.txt`
  - S1-S4 standard tiny sequence groups reported clear-rate/turn/score data.
- Economy audit: `.omo/evidence/task-9-economy-audit.txt`
  - Generated `logs/sim/task9_fresh_small_probe_20260603_economy_audit.json`.
- Runtime offer audit: `.omo/evidence/task-9-runtime-market-offer-audit.txt`
  - Generated `logs/sim/task9_runtime_market_offer_audit_20260603.json`.
- Small probe report: `.omo/evidence/task-9-small-probe.md`
  - Advisory-only conclusion, current input metadata, watchlist exposure, purchase/use proxy, clear-rate/score-ratio summary.
- Archive isolation: `.omo/evidence/task-9-archive-isolation.txt`
  - No generated Task 9 artifact consumes archive paths.
- Analyze: `.omo/evidence/task-9-dart-analyze.txt`
  - No issues found.
- Cleanup: `.omo/evidence/task-9-cleanup.txt`
  - No Task 9 Flutter test, flutter_tester, WebDriver, ChromeDriver, Flutter web server, or headless Chrome residue remains; tmux unavailable.

Reviewer:

- Packet: `.omo/evidence/task-9-compact-review-packet.md`
- v2 minipacket for delayed reviewer fallback: `.omo/evidence/task-9-reviewer-minipacket-v2.md`
- Verdict: `UNCONDITIONAL APPROVAL.`

## Task 10 Final Visual QA And Full-Run Readiness

Status: implemented and awaiting final reviewer.

Implementation:

- Ran final release web build.
- Ran fixture smoke on current source through local web-server with `SHOW_DEBUG_FIXTURES=true`.
- Fixed missing Fate ritual emblem mapping found by fixture smoke.
  - `flush_house_fate` -> existing `rank_concord` ritual emblem.
  - `flush_five_fate` -> existing `color_concord` ritual emblem.
- Added `test/resources/card_emblem_assets_test.dart` to assert every catalog item emblem asset path exists.
- Wrote full-run readiness checklist.

Evidence:

- Initial fixture smoke: `.omo/evidence/task-10-fixture-smoke.txt`
  - First run found missing `ritual_flush_house_fate.png` 404.
  - After fix, same evidence file records PASS with 0 important console messages.
- Screenshots:
  - `.omo/evidence/screenshots/task-10-fate-after-fix.png`
  - `.omo/evidence/screenshots/task-10-ritual_deck_echo-after-fix.png`
  - `.omo/evidence/screenshots/task-10-market_policy-after-fix.png`
  - `.omo/evidence/screenshots/task-10-mobile_fate-after-fix.png`
- Web build: `.omo/evidence/task-10-web-build.txt`
  - Latest post-fix release build passed.
- Emblem asset test: `.omo/evidence/task-10-card-emblem-assets-test.txt`
  - Catalog-wide item emblem path existence passed.
- Full analyzer: `.omo/evidence/final-dart-analyze.txt`
  - No issues found.
- Diff check: `.omo/evidence/final-git-diff-check.txt`
  - Passed.
- Changed-scope tests: `.omo/evidence/final-changed-scope-tests.txt`
  - Passed.
- Readiness: `.omo/evidence/task-10-full-run-readiness.md`
  - `full_run_bot` not started automatically; local build/fixture gate no longer blocks it.
- Cleanup: `.omo/evidence/task-10-cleanup.txt`
  - No Task 10 Flutter web-server, Flutter test, WebDriver, ChromeDriver, or headless Chrome residue remains; tmux unavailable.

Reviewer:

- Packet: `.omo/evidence/final-ultrawork-review-packet.md`
