# Active Execution Plan Implementation

## TL;DR

> **Summary**: `ritual-runtime-20260603` 이후 작업을 실제 구현 가능한 순서로 닫는 계획이다. 첫 작업은 catalog census로 문서/코드 숫자와 ID 충돌을 고정하고, 이후 Fate, Ritual, 전체 카드 정책, 구조/성능, 데이터 재개, QA 순서로 진행한다.
> **Deliverables**:
> - Catalog census report and corrected source-of-truth docs
> - Fate 16-card completion: runtime, feedback, rarity/price/weight, tests
> - Ritual hold-group redesign with normal/hold/debug separation
> - Item/Jester/Tool/Gear policy cleanup
> - Behavior-preserving refactor/performance slices
> - Fresh simulation restart gate and final QA evidence
> **Effort**: XL
> **Parallel**: YES - 6 waves
> **Critical Path**: Task 1 -> Task 2 -> Task 3 -> Task 5 -> Task 8 -> Task 10 -> Final Verification

## Context

### Original Request

User requested: `ulw-plan으로 ACTIVE_EXECUTION_PLAN.md 구현 계획 세워줘`.

### Interview Summary

No interview questions are required. The user already fixed the remaining-work order and asked for a plan. Repository exploration found enough implementation paths, tests, fixtures, and planning docs to make default decisions.

### Metis Review

Metis identified these required guardrails:

- First implementation step must be catalog census: exact item count, Ritual count, Fate count, normal/hold/debug eligibility, IDs, rarity, price, weight.
- "Normal market" means eligible offer pool with rarity gating, not common/common-like pool.
- Fate IDs and Ritual IDs must not remain ambiguous where old names imply different effects.
- Ritual scope must split active normal-market candidates, hold/debug candidates, and deleted legacy memories.
- Required comprehension visuals are part of Fate/Ritual acceptance, not lower-priority visual QA.
- Broad ML/simulation work waits until policy cleanup, but small deterministic pricing probes may run before broad restart.
- Refactor is behavior-preserving only and must not run concurrently with catalog/policy changes.
- Tag baseline clean state is separate from current planning artifacts.

## Work Objectives

### Core Objective

Implement the active execution plan after `ritual-runtime-20260603` without mixing policy decisions, runtime behavior, UI feedback, refactor, and simulation into one unsafe change.

### Deliverables

- `docs/planning/POST_RITUAL_RUNTIME_REMAINING_WORK.md` kept as queue index.
- `docs/current_system/CURRENT_CARD_CATALOG_TABLE.md`, `docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md`, `docs/planning/feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md`, and `docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md` synced with implementation.
- Runtime and UI changes for Fate/Ritual as required.
- Tests updated or added before each task is considered done.
- Commit after each wave or task group.

### Definition of Done

- `dart analyze` passes for changed Dart scopes.
- Relevant `flutter test` suites pass:
  - `test/logic/item_definition_test.dart`
  - `test/logic/item_effect_runtime_test.dart`
  - `test/logic/rummi_market_facade_test.dart`
  - `test/services/debug_run_fixture_service_test.dart`
  - relevant game view widget tests when UI changes
- JSON catalog and translation files parse.
- `flutter build web --release --base-href "/rummipoker/"` passes before final QA.
- No normal market candidate violates rarity/hold/debug policy.
- Every committed change has source, target, result behavior documented or explicitly scoped out.

### Must Have

- Catalog counts and IDs are verified from `data/common/items_common_v1.json`, not copied from older docs.
- Fate 16 cards are all covered, not representative-only.
- Required comprehension visuals are implemented with tests/fixtures before Fate/Ritual completion.
- Save/restore changes include roundtrip tests.
- Broad simulation only starts after catalog/policy cleanup is stable.

### Must NOT Have

- No new effects before census and pool rules are fixed.
- No hand/deck destructive mechanics that only help future battles unless explicitly moved to hold/debug.
- No broad refactor while catalog/policy semantics are changing.
- No use of old ML outputs as active source-of-truth.
- No normal market common/uncommon Fate cards.

## Verification Strategy

> ZERO HUMAN INTERVENTION - all verification is agent-executed until final optional eye-check.

- Test decision: tests-after for each implementation slice, with regression tests added for policy/runtime changes.
- QA policy: Every task has command-level verification and at least one failure/edge scenario.
- Evidence location: `.omo/evidence/task-{N}-{slug}.{txt|json|png}`.

## Execution Strategy

### Parallel Execution Waves

Wave 1: Task 1 only. Census is blocking.

Wave 2: Task 2 and Task 3 can run after Task 1, but must not edit the same catalog rows without coordination. Prefer Task 2 first if one agent executes.

Wave 3: Task 4 and Task 5 after Fate policy is stable.

Wave 4: Task 6 and Task 7 after Ritual policy split is stable.

Wave 5: Task 8 and Task 9 after policy/runtime stabilization. No policy changes during refactor.

Wave 6: Task 10 and final verification.

### Dependency Matrix

| Task | Blocks | Blocked By |
|---|---|---|
| 1. Catalog census | 2, 3, 4, 5, 6, 7, 8, 9, 10 | none |
| 2. Fate policy/runtime close | 4, 5, 10 | 1 |
| 3. Fate comprehension feedback | 5, 10 | 1 |
| 4. Ritual pool split | 5, 6, 10 | 1, 2 |
| 5. Ritual runtime/UI redesign | 6, 10 | 2, 3, 4 |
| 6. Full catalog policy cleanup | 8, 9, 10 | 4, 5 |
| 7. Save/restore and modifier sync | 8, 10 | 1, 5 |
| 8. Refactor/performance slices | 9, 10 | 6, 7 |
| 9. Fresh data/sim restart gate | 10 | 6, 8 |
| 10. Final QA and full-run readiness | final | 2-9 |

## TODOs

- [ ] 1. Catalog Census And Source-Of-Truth Repair

  **What to do**: Build or run a small read-only census over `data/common/items_common_v1.json` that reports total item count, `ritual_line_effect` count, Fate transform count, active Ritual count, hold/debug count, deleted legacy references, rarity, price, tags, and market eligibility. Update docs to use the census result and remove conflicting numbers.

  **Must NOT do**: Do not change card behavior, rarity, price, or market weights in this task. Do not infer counts from docs.

  **Parallelization**: Can Parallel: NO | Wave 1 | Blocks: 2-10 | Blocked By: none

  **References**:
  - Catalog: `data/common/items_common_v1.json`
  - Market eligibility: `lib/logic/rummi_poker_grid/rummi_market_facade_builders.dart`
  - Current docs: `docs/planning/ACTIVE_EXECUTION_PLAN.md`, `docs/planning/POST_RITUAL_RUNTIME_REMAINING_WORK.md`, `docs/current_system/CURRENT_CARD_CATALOG_TABLE.md`
  - Tests: `test/logic/item_definition_test.dart`, `test/logic/rummi_market_facade_test.dart`

  **Acceptance Criteria**:
  - [ ] Command prints a census artifact to `.omo/evidence/task-1-catalog-census.txt`.
  - [ ] Docs no longer disagree on total item count, Ritual count, Fate count, and active/hold/debug counts.
  - [ ] `boss_memory`, `thin_memory`, `minor_memory` status is explicit: deleted, legacy-only, or hold/debug.
  - [ ] `git diff --check` passes.

  **QA Scenarios**:
  ```text
  Scenario: Census from catalog
    Tool: bash
    Steps: Parse data/common/items_common_v1.json and group by effect op/tags/rarity.
    Expected: Evidence file lists every Fate/Ritual id exactly once.
    Evidence: .omo/evidence/task-1-catalog-census.txt

  Scenario: Deleted legacy references
    Tool: bash
    Steps: rg "boss_memory|thin_memory|minor_memory" data docs lib test.
    Expected: Any remaining match is documented as legacy/deleted or test assertion.
    Evidence: .omo/evidence/task-1-legacy-memory-refs.txt
  ```

  **Commit**: YES | Message: `문서상 카드 카탈로그 기준 정리` | Files: docs and optional read-only report script if added

- [ ] 2. Fate 16 Runtime And Market Policy Close

  **What to do**: Verify all 16 Fate transform cards are runtime-applied, have correct `ritualAction`, transform selected board line into expected 5-tile set, and are rare+ only. Ensure `number_mask`, `flush_five_fate`, `flush_house_fate`, `wild_thread`, `off_color_rite` remain legendary/high price and have weight controls.

  **Must NOT do**: Do not add new Fate cards. Do not move hold Rituals into normal market.

  **Parallelization**: Can Parallel: YES | Wave 2 | Blocks: 4, 5, 10 | Blocked By: 1

  **References**:
  - Runtime: `lib/logic/rummi_poker_grid/item_effect_runtime.dart`
  - Hand evaluator: `lib/logic/rummi_poker_grid/hand_evaluator.dart`
  - Market policy: `lib/logic/rummi_poker_grid/rummi_market_facade_builders.dart`
  - Fixture tests: `test/services/debug_run_fixture_service_test.dart`
  - Runtime tests: `test/logic/item_effect_runtime_test.dart`

  **Acceptance Criteria**:
  - [ ] `flutter test test/logic/item_definition_test.dart` passes.
  - [ ] `flutter test test/logic/item_effect_runtime_test.dart` passes.
  - [ ] `flutter test test/services/debug_run_fixture_service_test.dart` passes.
  - [ ] Test coverage asserts all 16 Fate IDs and expected resulting `RummiHandRank`.
  - [ ] Test coverage asserts no Fate transform card is common/uncommon.

  **QA Scenarios**:
  ```text
  Scenario: All Fate transforms apply
    Tool: flutter test
    Steps: Run debug fixture service Fate transform apply test.
    Expected: Each fixture applies selected line into expected hand rank.
    Evidence: .omo/evidence/task-2-fate-runtime.txt

  Scenario: Market rarity guard
    Tool: flutter test
    Steps: Run item definition and market facade tests.
    Expected: Fate transform cards are rare or legendary, and high-tier Fate IDs are legendary.
    Evidence: .omo/evidence/task-2-fate-market-policy.txt
  ```

  **Commit**: YES | Message: `운명 카드 런타임과 마켓 정책 마무리` | Files: catalog, runtime, market policy, tests, docs

- [ ] 3. Fate Required Comprehension Feedback

  **What to do**: Implement required feedback for Fate selection and result: candidate lines in blue, selected line in orange, pre-confirm panel with target rank/result, post-apply line flash, transformed tile highlight, and result toast/panel. This is required comprehension, not optional eye polish.

  **Must NOT do**: Do not reintroduce central dialog that covers board judgment. Do not apply on tap before confirm.

  **Parallelization**: Can Parallel: YES | Wave 2 | Blocks: 5, 10 | Blocked By: 1

  **References**:
  - Battle actions: `lib/views/game/game_view_battle_actions.dart`
  - Effect widgets: `lib/views/game/game_view_item_effect_widgets.dart`
  - Board widgets: `lib/views/game/widgets/game_shared_board_widgets.dart`
  - Timings: `lib/views/game/game_presentation_timings.dart`
  - Widget tests: `test/views/game/game_view_item_feedback_test.dart`

  **Acceptance Criteria**:
  - [ ] Widget or fixture test verifies confirm is required before transformation.
  - [ ] Candidate and selected visual states are exposed through stable keys or inspectable widget state.
  - [ ] Result feedback includes item name, selected line label, and resulting hand rank.
  - [ ] `dart analyze lib/views/game/game_view_battle_actions.dart lib/views/game/game_view_item_effect_widgets.dart lib/views/game/widgets/game_shared_board_widgets.dart` passes.

  **QA Scenarios**:
  ```text
  Scenario: Select then confirm
    Tool: flutter test
    Steps: Open Fate fixture, select candidate line, verify selected state, tap confirm.
    Expected: Board transforms only after confirm and shows result feedback.
    Evidence: .omo/evidence/task-3-fate-confirm-flow.txt

  Scenario: Cancel
    Tool: flutter test
    Steps: Open Fate fixture, select candidate line, tap cancel.
    Expected: No board transformation, item remains or returns according to existing cancel policy.
    Evidence: .omo/evidence/task-3-fate-cancel-flow.txt
  ```

  **Commit**: YES | Message: `운명 카드 변환 전달 연출 보강` | Files: battle UI, effect widgets, tests, docs

- [ ] 4. Ritual Pool Split And Hold Policy

  **What to do**: Split non-Fate Ritual cards into active normal-market, hold/redesign, debug-only, and deleted/legacy groups. Ensure market facade only includes active eligible cards and docs list every ID in exactly one group.

  **Must NOT do**: Do not implement redesigned effects yet. Do not expose hold/debug cards in normal market.

  **Parallelization**: Can Parallel: NO | Wave 3 | Blocks: 5, 6, 10 | Blocked By: 1, 2

  **References**:
  - Catalog: `data/common/items_common_v1.json`
  - Market facade: `lib/logic/rummi_poker_grid/rummi_market_facade_builders.dart`
  - Docs: `docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md`, `docs/planning/feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md`
  - Tests: `test/logic/rummi_market_facade_test.dart`

  **Acceptance Criteria**:
  - [ ] Every non-Fate Ritual ID has one group: active, hold, debug, deleted/legacy.
  - [ ] Market tests assert hold/debug/deleted groups do not enter normal offer pool.
  - [ ] Active group count matches census.
  - [ ] Docs and runtime market policy agree.

  **QA Scenarios**:
  ```text
  Scenario: Normal pool excludes hold Rituals
    Tool: flutter test
    Steps: Run market facade tests with deterministic policy.
    Expected: Normal item offers contain only eligible active Rituals.
    Evidence: .omo/evidence/task-4-ritual-pool.txt

  Scenario: Every Ritual classified
    Tool: bash
    Steps: Parse catalog IDs tagged/effected as Ritual and compare against docs group table.
    Expected: No unclassified ID.
    Evidence: .omo/evidence/task-4-ritual-classification.txt
  ```

  **Commit**: YES | Message: `의식 카드 노출 그룹 분리` | Files: catalog, market facade, docs, tests

- [ ] 5. Ritual Selection, Flight, And Result Redesign

  **What to do**: For active Rituals, unify selection UI with Fate rules. Line/tile candidates use blue rounded rectangles, selected candidate uses orange, confirm panel triggers effect. Deck copy/echo/sacrifice/gold effects must show readable flight: generated/copied tile holds center, moves to deck with easing; gold uses multiple coins to Gold HUD.

  **Must NOT do**: Do not leave current-battle irrelevant effects in active pool. Do not show ambiguous copy result without tile identity.

  **Parallelization**: Can Parallel: NO | Wave 3 | Blocks: 6, 7, 10 | Blocked By: 2, 3, 4

  **References**:
  - Runtime: `lib/logic/rummi_poker_grid/item_effect_runtime.dart`, `lib/logic/rummi_poker_grid/item_effect_handlers.dart`
  - Session deck: `lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart`
  - UI: `lib/views/game/game_view_battle_actions.dart`, `lib/views/game/game_view_item_effect_widgets.dart`
  - Flight widgets: `lib/views/game/widgets/game_effect_overlay_layers.dart`, `lib/views/game/widgets/game_shop_flight_widgets.dart`
  - Tests: `test/logic/item_effect_runtime_test.dart`, `test/views/game/game_view_item_feedback_test.dart`

  **Acceptance Criteria**:
  - [ ] Tile-selection Rituals use same candidate/selected/confirm grammar as Fate.
  - [ ] Deck-added tile is inserted into current session deck in the intended draw position.
  - [ ] Flight evidence distinguishes deck tile flight and gold coin flight.
  - [ ] Failure path with no valid candidate consumes nothing and shows clear notice.

  **QA Scenarios**:
  ```text
  Scenario: Copy selected tile to deck
    Tool: flutter test
    Steps: Use a deck copy fixture, select scoring tile, confirm.
    Expected: Copied tile identity appears in session deck top and in feedback.
    Evidence: .omo/evidence/task-5-copy-to-deck.txt

  Scenario: No valid target
    Tool: flutter test
    Steps: Use Ritual on a board with no valid scoring tile or line.
    Expected: Item not consumed and notice explains no target.
    Evidence: .omo/evidence/task-5-no-target.txt
  ```

  **Commit**: YES | Message: `의식 카드 선택과 결과 연출 정리` | Files: runtime, session, battle UI, overlay widgets, tests, docs

- [ ] 6. Item/Jester/Tool/Gear Policy Cleanup

  **What to do**: Classify the full catalog into normal, hold, debug, and deleted. Revisit prices, rarity, weights, and weak/strong card intent. Focus first on `trade_ticket`, `ride_the_bus`, advanced study cards, and `reroll_token`.

  **Must NOT do**: Do not use broad ML outputs as automatic authority. Do not change more than one policy family without tests and docs.

  **Parallelization**: Can Parallel: YES | Wave 4 | Blocks: 8, 9, 10 | Blocked By: 4, 5

  **References**:
  - Main contract: `docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md`
  - Catalog table: `docs/current_system/CURRENT_CARD_CATALOG_TABLE.md`
  - Runtime matrix: `docs/planning/feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md`
  - Presentation contract: `docs/planning/feature_plans/ITEM_PRESENTATION_CONTRACT_REVIEW.md`
  - Market tests: `test/logic/rummi_market_facade_test.dart`

  **Acceptance Criteria**:
  - [ ] Every catalog card has one exposure group.
  - [ ] Price/rarity/weight changes are documented by card or family.
  - [ ] Weak card decisions are one of: delete, hold, redesign, or explicit low-tier utility.
  - [ ] `flutter test test/logic/item_definition_test.dart test/logic/rummi_market_facade_test.dart` passes.

  **QA Scenarios**:
  ```text
  Scenario: Policy table matches catalog
    Tool: bash + flutter test
    Steps: Compare docs policy rows with catalog IDs and run item definition tests.
    Expected: No missing/extra active IDs.
    Evidence: .omo/evidence/task-6-policy-catalog-match.txt

  Scenario: Watchlist values
    Tool: flutter test
    Steps: Assert watchlist item prices/rarities/weights against documented expected values.
    Expected: Tests fail if watchlist values drift undocumented.
    Evidence: .omo/evidence/task-6-watchlist-values.txt
  ```

  **Commit**: YES | Message: `카드 정책과 마켓 노출 기준 정리` | Files: catalog, market policy, docs, tests

- [ ] 7. Seal, Enhancement, Save/Restore Sync

  **What to do**: Ensure seal/enhancement names, Korean display names, runtime settlement effects, tile detail text, JSON persistence, deck/board/hand/addedDeckTiles roundtrip, and docs are synchronized.

  **Must NOT do**: Do not introduce a save schema break without alias/migration and roundtrip tests.

  **Parallelization**: Can Parallel: YES | Wave 4 | Blocks: 8, 10 | Blocked By: 1, 5

  **References**:
  - Tile model: `lib/logic/rummi_poker_grid/models/tile.dart`
  - Deck/session models: `lib/logic/rummi_poker_grid/models/poker_deck.dart`, `lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart`
  - Settlement: `lib/logic/rummi_poker_grid/rummi_settlement_facade.dart`
  - UI detail: `lib/views/game/widgets/game_shared_tile_widgets.dart`
  - Tests: `test/logic/rummi_session_test.dart`, `test/logic/item_effect_runtime_test.dart`

  **Acceptance Criteria**:
  - [ ] Every persisted seal/enhancement has a user-facing label and detail text.
  - [ ] Settlement code applies documented effects.
  - [ ] JSON roundtrip tests cover deck, board, hand, eliminated, tile offers, and added deck tiles.
  - [ ] Legacy aliases are documented where needed.

  **QA Scenarios**:
  ```text
  Scenario: Roundtrip special tile
    Tool: flutter test
    Steps: Serialize and restore a session containing all active seal/enhancement variants.
    Expected: Restored tiles preserve modifier values and settlement effects.
    Evidence: .omo/evidence/task-7-roundtrip.txt

  Scenario: Tile detail copy
    Tool: flutter test
    Steps: Open tile detail model/widget for each modifier.
    Expected: Display text contains concrete effect, not "준비 중".
    Evidence: .omo/evidence/task-7-tile-detail.txt
  ```

  **Commit**: YES | Message: `특수 타일 표식 저장과 설명 동기화` | Files: tile/session/settlement/UI docs/tests

- [ ] 8. Behavior-Preserving Structure And Performance Refactor

  **What to do**: Refactor only after policy/runtime stabilization. Split remaining large widgets by boundary, separate runtime and presentation state further, extract constants, and reduce unnecessary rebuilds. Freeze catalog/policy changes during this task.

  **Must NOT do**: Do not change card behavior, market weights, save format, or scoring rules. Do not mix refactor with new features.

  **Parallelization**: Can Parallel: NO | Wave 5 | Blocks: 9, 10 | Blocked By: 6, 7

  **References**:
  - Remaining large files: `lib/views/game_view.dart`, `lib/views/game/widgets/game_shared_widgets.dart`, `lib/views/game/widgets/game_shop_screen.dart`
  - Existing split patterns: `lib/views/game/game_view_battle_actions.dart`, `lib/views/game/widgets/game_shop_*`
  - Metrics/timing: `lib/views/game/widgets/game_card_metrics.dart`, `lib/views/game/widgets/game_market_metrics.dart`, `lib/views/game/game_presentation_timings.dart`

  **Acceptance Criteria**:
  - [ ] Refactor diff is behavior-preserving by tests.
  - [ ] No catalog/policy/scoring files changed unless test-only import path update requires it.
  - [ ] Analyzer passes.
  - [ ] Before/after fixture smoke captures no new overflow or console error.

  **QA Scenarios**:
  ```text
  Scenario: Widget behavior unchanged
    Tool: flutter test
    Steps: Run existing game view/shop/battle widget tests before and after refactor.
    Expected: Same behavioral assertions pass.
    Evidence: .omo/evidence/task-8-widget-regression.txt

  Scenario: File responsibility check
    Tool: bash
    Steps: wc -l target files and rg for moved responsibilities.
    Expected: Large files shrink or have clear reason if unchanged; no duplicate helper responsibility.
    Evidence: .omo/evidence/task-8-file-sizes.txt
  ```

  **Commit**: YES | Message: `게임 화면 구조와 표시 상태 정리` | Files: view/widget/state/metrics/tests

- [ ] 9. Fresh Data And Small Pricing Probe Restart

  **What to do**: After policy cleanup and refactor, restart data work with current runtime/catalog only. First run small deterministic probes for Fate/Ritual pricing/weight sanity, then broader multi-seed standard/challenge data. ML remains advisory.

  **Must NOT do**: Do not use archived ML outputs as features. Do not auto-apply model recommendations.

  **Parallelization**: Can Parallel: YES | Wave 5 | Blocks: 10 | Blocked By: 6, 8

  **References**:
  - Sim entry: `tools/sim/run_balance_sim.dart`
  - Chunk runner: `tools/sim/chunked_balance_run.py`
  - Reports: `tools/sim/report_balance_summary_ko.py`, `tools/leveling/train_leveling_model.py`
  - Planning: `docs/planning/leveling/HEURISTIC_LEVELING_SIMULATION_DIRECTION.md`

  **Acceptance Criteria**:
  - [ ] Fresh run metadata records commit hash and catalog census hash.
  - [ ] Small probe report covers Fate/Ritual watchlist purchase/use frequency and clear-rate/score-ratio impact.
  - [ ] Broad data restart is blocked if small probe exposes overpowered early-game Fate frequency.
  - [ ] Report states advisory-only conclusion.

  **QA Scenarios**:
  ```text
  Scenario: Small pricing probe
    Tool: bash/python/dart
    Steps: Run deterministic small probe over current catalog with fixed seeds.
    Expected: Report lists watchlist item exposure/purchase/use and flags outliers.
    Evidence: .omo/evidence/task-9-small-probe.md

  Scenario: Archive isolation
    Tool: bash
    Steps: Verify generated metadata references current run files only.
    Expected: No active report consumes legacy archive paths as input.
    Evidence: .omo/evidence/task-9-archive-isolation.txt
  ```

  **Commit**: YES | Message: `현재 카탈로그 기준 밸런스 데이터 재시작` | Files: sim scripts/reports/docs, not raw heavy generated logs unless explicitly tracked summary

- [ ] 10. Final Visual QA And Full-Run Readiness

  **What to do**: Run required fixture and web build QA after all policy/runtime/refactor work. Visual QA is last, but required comprehension visuals from Tasks 3 and 5 must already exist.

  **Must NOT do**: Do not treat manual eye-check as substitute for tests. Do not start full-run bot if web build or fixture smoke fails.

  **Parallelization**: Can Parallel: NO | Wave 6 | Blocks: final | Blocked By: 2-9

  **References**:
  - Web build: `tools/deploy_rummipoker_web.sh`, `docs/web_build.md`
  - Fixtures: `lib/services/debug_run_fixture_service.dart`
  - Full-run bot: `tools/full_run_bot.sh`
  - Browser QA skills: `nas-web-build`, `browse`, `qa`

  **Acceptance Criteria**:
  - [ ] `flutter build web --release --base-href "/rummipoker/"` passes.
  - [ ] Fixture smoke covers Fate, Ritual copy/echo, market policy, and mobile viewport.
  - [ ] Console has no important error/warn/overflow.
  - [ ] Full-run readiness checklist states whether full_run_bot should be run now or after next feature slice.

  **QA Scenarios**:
  ```text
  Scenario: Web build and fixture smoke
    Tool: bash + browser
    Steps: Build web, serve locally, open key fixtures with debug_suppress_fixture_notice=1.
    Expected: No build failure, no console error, no visible overflow.
    Evidence: .omo/evidence/task-10-fixture-smoke.txt

  Scenario: NAS build gate
    Tool: nas-web-build skill
    Steps: Run NAS web build only after local smoke passes.
    Expected: NAS deployment completes and app route loads.
    Evidence: .omo/evidence/task-10-nas-build.txt
  ```

  **Commit**: YES | Message: `운명 의식 카드 후속 QA 정리` | Files: QA docs/checklists and any final fixes

## Final Verification Wave

- [ ] F1. Plan Compliance Audit
  - Verify every task has evidence files or a documented blocker.
  - Verify every planned commit exists or was intentionally merged into an adjacent task commit.

- [ ] F2. Code Quality Review
  - Run `dart analyze`.
  - Run all changed-scope tests.
  - Run `git diff --check`.

- [ ] F3. Real Manual QA
  - Use browser QA only after build passes.
  - Capture Fate and Ritual representative screenshots/video.
  - Check mobile viewport touchability and overflow.

- [ ] F4. Scope Fidelity Check
  - Confirm no archived ML output is used as active source.
  - Confirm no hold/debug Ritual is exposed in normal market.
  - Confirm no refactor task changed catalog/scoring semantics.

## Commit Strategy

- Commit after each task or tightly related pair.
- Use Korean commit messages.
- Push after meaningful wave completion.
- Tag only after a stable milestone:
  - Candidate tag: `fate-ritual-policy-stable-YYYYMMDD` after Tasks 1-7.
  - Candidate tag: `post-ritual-refactor-stable-YYYYMMDD` after Tasks 8-10.

## Success Criteria

- `ACTIVE_EXECUTION_PLAN.md` points to the remaining-work queue and no longer carries stale implementation counts as the only source.
- Current catalog census, runtime behavior, docs, tests, and market policy agree.
- Fate 16 and active Rituals are testable, understandable, and correctly gated in market.
- Refactor is behavior-preserving.
- Fresh data restart uses current runtime only.
- Final QA can proceed without unresolved policy ambiguity.
