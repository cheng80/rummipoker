# Catalog Census And Source-Of-Truth Repair

## TL;DR
> Summary:      Repair Task 1 from `.omo/plans/active-execution-plan-implementation.md` by deriving current item catalog facts from `data/common/items_common_v1.json`, then syncing docs/tests/evidence so stale 92/94/38/40-count claims stop driving execution.
> Deliverables:
> - Catalog census evidence artifact from the JSON catalog
> - RED and GREEN focused test transcripts for doc/census agreement
> - Corrected current-system, planning, feature-plan, and V4-contract source-of-truth docs
> - Legacy/deleted memory reference grep receipt
> - Diff/check and process-cleanup receipts
> Effort:       Short
> Risk:         Medium - docs and tests are already dirty, and multiple docs currently disagree with runtime catalog counts.

## Scope
### Must have
- Derive all counts from `data/common/items_common_v1.json:1`, not from existing prose.
- Preserve existing uncommitted work in `docs/current_system/CURRENT_CARD_CATALOG_TABLE.md`, `docs/planning/ACTIVE_EXECUTION_PLAN.md`, `test/logic/item_definition_test.dart`, `.omo/notepads/active-execution-task1-catalog-census.md`, and `docs/planning/POST_RITUAL_RUNTIME_REMAINING_WORK.md`.
- Fix current item total, placement/type totals, `ritual_line_effect` count, Fate count, active/hold/deleted split, and legacy memory wording across source-of-truth docs.
- Keep runtime behavior unchanged: no catalog price, rarity, effect, market weight, save format, or UI behavior changes.
- Capture evidence under `.omo/evidence/`.
- Use `flutter test` as the canonical focused test command because this Flutter project uses `flutter_test` in `pubspec.yaml:61`.

### Must NOT have (guardrails, anti-slop, scope boundaries)
- Do not change `data/common/items_common_v1.json` unless the census reveals invalid JSON or duplicate IDs that make the task impossible.
- Do not edit market behavior in `lib/logic/rummi_poker_grid/rummi_market_facade_builders.dart`; only read its active Ritual allow-list around `lib/logic/rummi_poker_grid/rummi_market_facade_builders.dart:116`.
- Do not update archive docs except to verify they are clearly legacy.
- Do not run browser, WebDriver, Chrome, Flutter web server, full-run bot, long simulations, or web builds for this docs/test slice.
- Do not commit unrelated dirty files.

## Verification strategy
> Zero human intervention - all verification is agent-executed.
- Test decision: TDD + Flutter focused test using `flutter test test/logic/item_definition_test.dart --name "catalog census docs match current catalog"`
- QA policy: every task has agent-executed scenarios
- Evidence: `.omo/evidence/task-<N>-<slug>.<ext>`

## Execution strategy
### Parallel execution waves
> Target 5-8 tasks per wave. <3 per wave (except final) = under-splitting.
> Extract shared dependencies as Wave-1 tasks to maximize parallelism.

Wave 1 (no dependencies):
- Task 1: Capture RED, current census, and before-process receipt

Wave 2 (after Wave 1):
- Task 2: depends [1]
- Task 3: depends [1]
- Task 4: depends [1]
- Task 5: depends [1]
- Task 6: depends [1]

Wave 3 (after Wave 2):
- Task 7: depends [2, 3, 4, 5, 6]

Critical path: Task 1 -> Task 2 -> Task 7

### Dependency matrix
| Task | Depends on | Blocks | Can parallelize with |
|------|------------|--------|----------------------|
| 1    | none       | 2, 3, 4, 5, 6 | none |
| 2    | 1          | 7      | 3, 4, 5, 6 |
| 3    | 1          | 7      | 2, 4, 5, 6 |
| 4    | 1          | 7      | 2, 3, 5, 6 |
| 5    | 1          | 7      | 2, 3, 4, 6 |
| 6    | 1          | 7      | 2, 3, 4, 5 |
| 7    | 2, 3, 4, 5, 6 | final | none |

## Todos
> Implementation + Test = ONE task. Never separate.
> Every task MUST have: References + Acceptance Criteria + QA Scenarios + Commit.

- [ ] 1. Capture RED And Canonical Catalog Census

  What to do: Start by recording `git status --short`. Create `.omo/evidence/` if needed. Run the focused census doc test before doc repair and capture the RED transcript. Generate a deterministic census artifact from `data/common/items_common_v1.json` that lists totals, type counts, placement counts, all `ritual_line_effect` IDs, Fate IDs derived from `effect.ritualAction` values beginning with `fate_`, Ritual market-helper hold IDs, and deleted legacy memory IDs. Capture a before-process receipt for Chrome/WebDriver/Flutter-web residue.
  Must NOT do: Do not edit docs or catalog in this task. Do not use stale docs as census inputs.

  Parallelization: Can parallel: NO | Wave 1 | Blocks: [2, 3, 4, 5, 6] | Blocked by: []

  References (executor has NO interview context - be exhaustive):
  - Pattern:  `test/logic/item_definition_test.dart:186` - existing focused test name and doc/census assertions
  - Pattern:  `.omo/notepads/active-execution-task1-catalog-census.md:23` - existing Task 1 evidence expectations
  - API/Type: `lib/logic/rummi_poker_grid/item_definition.dart:160` - `ItemCatalog.fromJsonString` parser used by tests
  - API/Type: `lib/logic/rummi_poker_grid/item_definition.dart:71` - item fields parsed from JSON
  - Test:     `test/logic/item_definition_test.dart:75` - current catalog test pattern and count assertions
  - External: `https://api.dart.dev/dart-convert/jsonDecode.html` - Dart JSON decode reference
  - External: `https://docs.flutter.dev/reference/flutter-cli` - Flutter CLI reference for `flutter test`

  Acceptance criteria (agent-executable only):
  - [ ] `mkdir -p .omo/evidence` succeeds.
  - [ ] `flutter test test/logic/item_definition_test.dart --name "catalog census docs match current catalog" 2>&1 | tee .omo/evidence/task-1-red-doc-census-test.txt` captures the expected RED before doc repair, or records that another concurrent agent already repaired docs before RED could be observed.
  - [ ] The census command below writes `.omo/evidence/task-1-catalog-census.txt` and includes `total=91`, `ritual_line_effect=31`, and `ritual_action_fate=16` based on the current JSON.
  - [ ] `.omo/evidence/task-1-processes-before.txt` exists.

  QA scenarios (MANDATORY - task incomplete without these):
  > Name the exact tool AND its exact invocation - not "verify it works". Browser use: use Chrome to drive the page; if Chrome is not available, download and use agent-browser (https://github.com/vercel-labs/agent-browser). Computer use: OS-level GUI automation for a non-browser desktop app.
  ```
  Scenario: RED focused census test
    Tool:     bash
    Steps:    mkdir -p .omo/evidence && flutter test test/logic/item_definition_test.dart --name "catalog census docs match current catalog" 2>&1 | tee .omo/evidence/task-1-red-doc-census-test.txt
    Expected: Transcript contains a failing assertion about stale doc text, unless docs were already fixed before this task started and the transcript is marked pre-green in the evidence header.
    Evidence: .omo/evidence/task-1-red-doc-census-test.txt

  Scenario: Catalog census artifact
    Tool:     bash
    Steps:    jq -r '.items as $items | "total=\($items|length)", "by_type=\($items|group_by(.type)|map({key:.[0].type,count:length})|sort_by(.key)|@json)", "by_placement=\($items|group_by(.placement)|map({key:.[0].placement,count:length})|sort_by(.key)|@json)", "ritual_line_effect=\($items|map(select(.effect.op=="ritual_line_effect"))|length)", "ritual_action_fate=\($items|map(select((.effect.ritualAction // "")|startswith("fate_")))|length)", "ritual_line_ids=\($items|map(select(.effect.op=="ritual_line_effect")|.id)|@json)", "fate_ids=\($items|map(select((.effect.ritualAction // "")|startswith("fate_"))|.id)|@json)", "market_helper_ritual_ids=\($items|map(select(((.tags // [])|index("ritual")) and .effect.op!="ritual_line_effect" and .effect.op!="add_hand_rank_progress_from_selected_line")|.id)|@json)", "deleted_legacy_present=\($items|map(select(.id=="boss_memory" or .id=="thin_memory" or .id=="minor_memory")|.id)|@json)"' data/common/items_common_v1.json | tee .omo/evidence/task-1-catalog-census.txt
    Expected: Output contains total=91, ritual_line_effect=31, ritual_action_fate=16, deleted_legacy_present=[].
    Evidence: .omo/evidence/task-1-catalog-census.txt
  ```

  Commit: NO | Message: `test(catalog): capture item census baseline` | Files: [.omo/evidence/task-1-red-doc-census-test.txt, .omo/evidence/task-1-catalog-census.txt, .omo/evidence/task-1-processes-before.txt]

- [ ] 2. Repair Current Catalog Table Census

  What to do: Update `docs/current_system/CURRENT_CARD_CATALOG_TABLE.md` so its Summary, Fate/Ritual classification, Ritual Cards sections, and Notes all match the generated census. The current table already states the runtime source relationship at `docs/current_system/CURRENT_CARD_CATALOG_TABLE.md:251`; keep that relationship explicit. Ensure headings and prose no longer claim 94 total items, 55 Q-Slot items, 37/38/40 expansion items, or 34 `ritual_line_effect` cards unless those values are explicitly marked legacy.
  Must NOT do: Do not reorganize the full table layout or rewrite card descriptions beyond count/status repair.

  Parallelization: Can parallel: YES | Wave 2 | Blocks: [7] | Blocked by: [1]

  References (executor has NO interview context - be exhaustive):
  - Pattern:  `docs/current_system/CURRENT_CARD_CATALOG_TABLE.md:6` - Summary block with stale Item/Q-Slot counts
  - Pattern:  `docs/current_system/CURRENT_CARD_CATALOG_TABLE.md:15` - Fate/Ritual classification prose
  - Pattern:  `docs/current_system/CURRENT_CARD_CATALOG_TABLE.md:152` - Ritual Cards section with expansion-count prose
  - Pattern:  `docs/current_system/CURRENT_CARD_CATALOG_TABLE.md:249` - Notes/source-of-truth wording
  - API/Type: `data/common/items_common_v1.json:25` - runtime item array that drives counts
  - Test:     `test/logic/item_definition_test.dart:225` - assertions checking current catalog doc text
  - External: `https://api.dart.dev/dart-convert/jsonDecode.html` - JSON data source can be parsed deterministically

  Acceptance criteria (agent-executable only):
  - [ ] `rg -n "Item total: 94|Q-Slot: 55|34장|37종|38종|40종" docs/current_system/CURRENT_CARD_CATALOG_TABLE.md` returns no unstated-current matches.
  - [ ] `flutter test test/logic/item_definition_test.dart --name "catalog census docs match current catalog"` passes or fails only on docs outside this task.
  - [ ] `docs/current_system/CURRENT_CARD_CATALOG_TABLE.md` contains `- Item total: 91`, `- Q-Slot: 52`, `전투 보드 선 선택형 \`ritual_line_effect\`는 31장`, and `족보 변환형 운명 카드는 16장`.

  QA scenarios (MANDATORY - task incomplete without these):
  > Name the exact tool AND its exact invocation - not "verify it works". Browser use: use Chrome to drive the page; if Chrome is not available, download and use agent-browser (https://github.com/vercel-labs/agent-browser). Computer use: OS-level GUI automation for a non-browser desktop app.
  ```
  Scenario: Current catalog table has no stale current counts
    Tool:     bash
    Steps:    (rg -n "Item total: 94|Q-Slot: 55|34장|37종|38종|40종" docs/current_system/CURRENT_CARD_CATALOG_TABLE.md || true) | tee .omo/evidence/task-2-current-catalog-stale-counts.txt
    Expected: Evidence is empty or only contains text explicitly labeled legacy/history, not current source-of-truth.
    Evidence: .omo/evidence/task-2-current-catalog-stale-counts.txt

  Scenario: Current catalog table satisfies focused test
    Tool:     bash
    Steps:    flutter test test/logic/item_definition_test.dart --name "catalog census docs match current catalog" 2>&1 | tee .omo/evidence/task-2-current-catalog-focused-test.txt
    Expected: Test passes, or any remaining failure points to docs owned by Tasks 3-6.
    Evidence: .omo/evidence/task-2-current-catalog-focused-test.txt
  ```

  Commit: NO | Message: `docs(catalog): align current catalog census` | Files: [docs/current_system/CURRENT_CARD_CATALOG_TABLE.md]

- [ ] 3. Repair Active Router And Remaining Work Queue

  What to do: Update `docs/planning/ACTIVE_EXECUTION_PLAN.md` and `docs/planning/POST_RITUAL_RUNTIME_REMAINING_WORK.md` so active execution text matches current census and legacy memory status. Preserve the post-ritual work order introduced at `docs/planning/ACTIVE_EXECUTION_PLAN.md:9`. Replace stale active claims at `docs/planning/ACTIVE_EXECUTION_PLAN.md:45` and `docs/planning/ACTIVE_EXECUTION_PLAN.md:76` only where they are current-status claims. In remaining-work docs, make `boss_memory`, `thin_memory`, and `minor_memory` explicitly deleted legacy memories, because the current JSON census has no such IDs.
  Must NOT do: Do not reopen full-run bot or simulation work. Do not change queue priority.

  Parallelization: Can parallel: YES | Wave 2 | Blocks: [7] | Blocked by: [1]

  References (executor has NO interview context - be exhaustive):
  - Pattern:  `docs/planning/ACTIVE_EXECUTION_PLAN.md:3` - document role as current execution router
  - Pattern:  `docs/planning/ACTIVE_EXECUTION_PLAN.md:45` - stale 94/40/34 active catalog claim
  - Pattern:  `docs/planning/POST_RITUAL_RUNTIME_REMAINING_WORK.md:43` - Ritual hold-group queue
  - Pattern:  `docs/planning/POST_RITUAL_RUNTIME_REMAINING_WORK.md:50` - legacy memory status line to make explicit
  - API/Type: `data/common/items_common_v1.json:25` - item array source for current counts
  - Test:     `test/logic/item_definition_test.dart:235` - active plan doc count assertion
  - Test:     `test/logic/item_definition_test.dart:242` - remaining work legacy-memory assertion
  - External: `https://docs.flutter.dev/reference/flutter-cli` - focused test command reference

  Acceptance criteria (agent-executable only):
  - [ ] `docs/planning/ACTIVE_EXECUTION_PLAN.md` contains `현재 item catalog 91개` and `전투 보드 선 선택형 \`ritual_line_effect\`는 31장`.
  - [ ] `docs/planning/POST_RITUAL_RUNTIME_REMAINING_WORK.md` contains `` `boss_memory`, `thin_memory`, `minor_memory`는 catalog에서 삭제된 legacy 기억 의식 ``.
  - [ ] `rg -n "현재 item catalog 94개|Ritual/Item 확장 계열 40종|ritual_line_effect`는 34장" docs/planning/ACTIVE_EXECUTION_PLAN.md docs/planning/POST_RITUAL_RUNTIME_REMAINING_WORK.md` returns no current-status matches.

  QA scenarios (MANDATORY - task incomplete without these):
  > Name the exact tool AND its exact invocation - not "verify it works". Browser use: use Chrome to drive the page; if Chrome is not available, download and use agent-browser (https://github.com/vercel-labs/agent-browser). Computer use: OS-level GUI automation for a non-browser desktop app.
  ```
  Scenario: Active router source-of-truth counts
    Tool:     bash
    Steps:    rg -n "현재 item catalog 91개|전투 보드 선 선택형 `ritual_line_effect`는 31장|catalog에서 삭제된 legacy 기억 의식" docs/planning/ACTIVE_EXECUTION_PLAN.md docs/planning/POST_RITUAL_RUNTIME_REMAINING_WORK.md | tee .omo/evidence/task-3-active-router-current-counts.txt
    Expected: Evidence contains all three required current phrases.
    Evidence: .omo/evidence/task-3-active-router-current-counts.txt

  Scenario: Active router stale current claims removed
    Tool:     bash
    Steps:    (rg -n "현재 item catalog 94개|Ritual/Item 확장 계열 40종|ritual_line_effect`는 34장" docs/planning/ACTIVE_EXECUTION_PLAN.md docs/planning/POST_RITUAL_RUNTIME_REMAINING_WORK.md || true) | tee .omo/evidence/task-3-active-router-stale-counts.txt
    Expected: Evidence is empty.
    Evidence: .omo/evidence/task-3-active-router-stale-counts.txt
  ```

  Commit: NO | Message: `docs(planning): align active catalog routing` | Files: [docs/planning/ACTIVE_EXECUTION_PLAN.md, docs/planning/POST_RITUAL_RUNTIME_REMAINING_WORK.md]

- [ ] 4. Repair Item Policy Cleanup Audit

  What to do: Update `docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md` so it distinguishes historical baseline 54 from current catalog 91, current `ritual_line_effect` 31, Fate 16, active visible candidates, hold market-helper Ritual IDs, and deleted legacy memory IDs. Keep policy conclusions, but remove stale current claims at `docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md:20`, `docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md:148`, and `docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md:188`.
  Must NOT do: Do not add new candidate cards. Do not move hold market-helper Rituals into normal market.

  Parallelization: Can parallel: YES | Wave 2 | Blocks: [7] | Blocked by: [1]

  References (executor has NO interview context - be exhaustive):
  - Pattern:  `docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md:6` - conclusion/current catalog framing
  - Pattern:  `docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md:144` - Board-Line Ritual section
  - Pattern:  `docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md:150` - current execution classification table
  - Pattern:  `lib/logic/rummi_poker_grid/rummi_market_facade_builders.dart:116` - active Ritual market gate
  - Pattern:  `lib/logic/rummi_poker_grid/rummi_market_facade_builders.dart:121` - allowed active Ritual IDs
  - Test:     `test/logic/rummi_market_facade_test.dart:720` - pinned active/deferred Ritual offer behavior
  - External: `https://api.dart.dev/dart-convert/jsonDecode.html` - JSON parsing reference for generated census

  Acceptance criteria (agent-executable only):
  - [ ] Audit doc states current total 91, `ritual_line_effect` 31, Fate 16, and hold market-helper IDs `prune_vendor`, `seal_vendor`, `line_pack_ticket`, `ritual_lens`, `ritual_coupon`.
  - [ ] Audit doc states deleted legacy memory IDs are not in the catalog.
  - [ ] `rg -n "총 92개|40종이 실제|34장|38종을 실제 catalog" docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md` returns no current-status matches.
  - [ ] `flutter test test/logic/rummi_market_facade_test.dart --name "Ritual"` passes or records no matching tests; if no matching tests run, run the full file.

  QA scenarios (MANDATORY - task incomplete without these):
  > Name the exact tool AND its exact invocation - not "verify it works". Browser use: use Chrome to drive the page; if Chrome is not available, download and use agent-browser (https://github.com/vercel-labs/agent-browser). Computer use: OS-level GUI automation for a non-browser desktop app.
  ```
  Scenario: Policy audit stale current counts removed
    Tool:     bash
    Steps:    (rg -n "총 92개|40종이 실제|34장|38종을 실제 catalog" docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md || true) | tee .omo/evidence/task-4-policy-audit-stale-counts.txt
    Expected: Evidence is empty or each match is explicitly marked as historical baseline, not current state.
    Evidence: .omo/evidence/task-4-policy-audit-stale-counts.txt

  Scenario: Market Ritual behavior still covered
    Tool:     bash
    Steps:    flutter test test/logic/rummi_market_facade_test.dart --name "Ritual" 2>&1 | tee .omo/evidence/task-4-market-ritual-focused-test.txt
    Expected: Matching Ritual tests pass; if test runner reports no tests matched, rerun `flutter test test/logic/rummi_market_facade_test.dart` and capture the replacement transcript in the same evidence file.
    Evidence: .omo/evidence/task-4-market-ritual-focused-test.txt
  ```

  Commit: NO | Message: `docs(policy): align item cleanup audit census` | Files: [docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md]

- [ ] 5. Repair Runtime Matrix Counts Without Runtime Changes

  What to do: Update `docs/planning/feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md` to match current catalog counts and runtime hook status. The table itself lists active item rows through `docs/planning/feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md:59`; only correct summary/current-basis prose and any stale aggregate totals. Keep the meaning of `applied` at `docs/planning/feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md:37`: runtime state change, not UX completion.
  Must NOT do: Do not edit `lib/logic/rummi_poker_grid/item_effect_runtime.dart` or any effect handlers in this task.

  Parallelization: Can parallel: YES | Wave 2 | Blocks: [7] | Blocked by: [1]

  References (executor has NO interview context - be exhaustive):
  - Pattern:  `docs/planning/feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md:6` - basis data file
  - Pattern:  `docs/planning/feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md:8` - stale current basis counts
  - Pattern:  `docs/planning/feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md:24` - Ritual runtime classification
  - Pattern:  `docs/planning/feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md:191` - stale total/applied aggregate
  - API/Type: `lib/logic/rummi_poker_grid/item_definition.dart:152` - catalog parser
  - Test:     `test/logic/item_definition_test.dart:75` - catalog count assertions
  - External: `https://api.dart.dev/dart-convert/jsonDecode.html` - JSON parsing reference

  Acceptance criteria (agent-executable only):
  - [ ] Matrix doc current-basis section states Item catalog 91, `ritual_line_effect` 31, Fate 16.
  - [ ] Matrix doc no longer has contradictory active totals such as `Item catalog: 94개` and `총 92개 중`.
  - [ ] `flutter test test/logic/item_definition_test.dart --name "v1 catalog keeps Korean text in localization data only"` passes.

  QA scenarios (MANDATORY - task incomplete without these):
  > Name the exact tool AND its exact invocation - not "verify it works". Browser use: use Chrome to drive the page; if Chrome is not available, download and use agent-browser (https://github.com/vercel-labs/agent-browser). Computer use: OS-level GUI automation for a non-browser desktop app.
  ```
  Scenario: Runtime matrix aggregate counts repaired
    Tool:     bash
    Steps:    (rg -n "Item catalog: 94개|총 92개 중|ritual_line_effect`: 34개" docs/planning/feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md || true) | tee .omo/evidence/task-5-runtime-matrix-stale-counts.txt
    Expected: Evidence is empty.
    Evidence: .omo/evidence/task-5-runtime-matrix-stale-counts.txt

  Scenario: Catalog parser/localization regression
    Tool:     bash
    Steps:    flutter test test/logic/item_definition_test.dart --name "v1 catalog keeps Korean text in localization data only" 2>&1 | tee .omo/evidence/task-5-item-definition-localization-test.txt
    Expected: Test passes.
    Evidence: .omo/evidence/task-5-item-definition-localization-test.txt
  ```

  Commit: NO | Message: `docs(runtime): align item effect matrix census` | Files: [docs/planning/feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md]

- [ ] 6. Repair V4 Contract And Secondary References

  What to do: Update `docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md` and only necessary secondary current/planning references so the contract points to current JSON census without implying stale 92/38 current facts. Lines `docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md:47` through `docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md:67` are the concrete catalog section; lines `docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md:79` through `docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md:121` are active Ritual policy. Later draft/history sections such as `docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md:503` may remain if explicitly framed as history.
  Must NOT do: Do not archive or reorder `START_HERE.md`; project rules keep it as the top-level entry document.

  Parallelization: Can parallel: YES | Wave 2 | Blocks: [7] | Blocked by: [1]

  References (executor has NO interview context - be exhaustive):
  - Pattern:  `docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md:51` - concrete catalog source
  - Pattern:  `docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md:58` - stale 92/38 current catalog claim
  - Pattern:  `docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md:87` - stale 38 Ritual current claim
  - Pattern:  `START_HERE.md:1` - top-level entry file; only touch if source-of-truth routing becomes inconsistent
  - Pattern:  `docs/planning/00_planning_README.md:1` - planning folder routing; only touch if active/current routing changes
  - Test:     `test/logic/item_definition_test.dart:186` - focused census test catches the main docs
  - External: `https://docs.flutter.dev/reference/flutter-cli` - Flutter test command reference

  Acceptance criteria (agent-executable only):
  - [ ] V4 contract concrete catalog section states current 91 total and type distribution `utility: 14`, `consumable: 58`, `equipment: 9`, `passive_relic: 10`.
  - [ ] Active Ritual policy states current `ritual_line_effect` 31 and Fate 16, with hold market-helper IDs separated.
  - [ ] `rg -n "92개 아이템|38종 Ritual|Board-Line Ritual 후보 pool은 38종을 현재 catalog" docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md` returns only explicitly historical matches.
  - [ ] If `START_HERE.md` or planning README are touched, `rg -n "START_HERE.md|ACTIVE_EXECUTION_PLAN.md|CURRENT_CARD_CATALOG_TABLE.md" START_HERE.md docs/00_docs_README.md docs/planning/00_planning_README.md` still shows `START_HERE.md` as top entry and current docs as current facts.

  QA scenarios (MANDATORY - task incomplete without these):
  > Name the exact tool AND its exact invocation - not "verify it works". Browser use: use Chrome to drive the page; if Chrome is not available, download and use agent-browser (https://github.com/vercel-labs/agent-browser). Computer use: OS-level GUI automation for a non-browser desktop app.
  ```
  Scenario: V4 contract stale current claims isolated
    Tool:     bash
    Steps:    (rg -n "92개 아이템|38종 Ritual|Board-Line Ritual 후보 pool은 38종을 현재 catalog" docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md || true) | tee .omo/evidence/task-6-v4-contract-stale-counts.txt
    Expected: Evidence is empty or every match is in a section explicitly labeled historical/draft, not active current state.
    Evidence: .omo/evidence/task-6-v4-contract-stale-counts.txt

  Scenario: Entry routing still intact
    Tool:     bash
    Steps:    rg -n "START_HERE.md|ACTIVE_EXECUTION_PLAN.md|CURRENT_CARD_CATALOG_TABLE.md" START_HERE.md docs/00_docs_README.md docs/planning/00_planning_README.md | tee .omo/evidence/task-6-entry-routing-grep.txt
    Expected: Output shows START_HERE remains the top entry, ACTIVE_EXECUTION_PLAN remains planning router, and CURRENT_CARD_CATALOG_TABLE remains current catalog fact table.
    Evidence: .omo/evidence/task-6-entry-routing-grep.txt
  ```

  Commit: NO | Message: `docs(spec): align item contract census` | Files: [docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md, START_HERE.md, docs/00_docs_README.md, docs/planning/00_planning_README.md]

- [ ] 7. Final Focused Green, Grep, Diff Check, Cleanup, Commit

  What to do: Run final focused verification after Tasks 2-6. Capture GREEN transcript for the census doc test, market facade regression, legacy reference grep, global stale-count grep for current docs, `git diff --check`, and after-process cleanup receipt. Review `git diff --stat` and commit only Task 1 files if the caller requested commits in the active execution flow.
  Must NOT do: Do not run broad `flutter test`, web build, browser QA, full-run bot, or simulations for this docs/test slice.

  Parallelization: Can parallel: NO | Wave 3 | Blocks: [final] | Blocked by: [2, 3, 4, 5, 6]

  References (executor has NO interview context - be exhaustive):
  - Pattern:  `README.md:71` - repo baseline `flutter test` / `flutter analyze` commands
  - Pattern:  `docs/planning/verification/MARKET_ITEM_SMOKE_CHECKLIST.md:6` - market/item targeted suite list
  - Pattern:  `docs/planning/competition/COMPUTE_BROWSER_FULL_PLAY_BOT.md:41` - process cleanup rule source
  - Test:     `test/logic/item_definition_test.dart:186` - focused census doc test
  - Test:     `test/logic/rummi_market_facade_test.dart:746` - item-offer non-refill behavior guard
  - External: `https://docs.flutter.dev/reference/flutter-cli` - Flutter test command reference

  Acceptance criteria (agent-executable only):
  - [ ] `flutter test test/logic/item_definition_test.dart --name "catalog census docs match current catalog"` passes and evidence is written.
  - [ ] `flutter test test/logic/rummi_market_facade_test.dart` passes or any failure is unrelated and documented with exact failure lines.
  - [ ] `rg "boss_memory|thin_memory|minor_memory" data docs lib test` has no data/lib runtime matches; doc/test matches explicitly say legacy/deleted.
  - [ ] `rg -n "current item catalog 94|Item catalog: 94|Item total: 94|총 92개|Ritual/Item 확장 계열 40종|ritual_line_effect.*34"` over current docs has no current-status matches.
  - [ ] `git diff --check` passes.
  - [ ] Cleanup receipt exists and records no WebDriver Chrome, ChromeDriver, or Flutter web server spawned by this task.

  QA scenarios (MANDATORY - task incomplete without these):
  > Name the exact tool AND its exact invocation - not "verify it works". Browser use: use Chrome to drive the page; if Chrome is not available, download and use agent-browser (https://github.com/vercel-labs/agent-browser). Computer use: OS-level GUI automation for a non-browser desktop app.
  ```
  Scenario: GREEN focused census test
    Tool:     bash
    Steps:    flutter test test/logic/item_definition_test.dart --name "catalog census docs match current catalog" 2>&1 | tee .omo/evidence/task-7-green-doc-census-test.txt
    Expected: Transcript contains "All tests passed!".
    Evidence: .omo/evidence/task-7-green-doc-census-test.txt

  Scenario: Legacy memory refs are deleted/legacy only
    Tool:     bash
    Steps:    (rg "boss_memory|thin_memory|minor_memory" data docs lib test || true) | tee .omo/evidence/task-7-legacy-memory-refs.txt
    Expected: No data/lib runtime matches; every docs/test match explicitly says deleted, legacy, or asserts that status.
    Evidence: .omo/evidence/task-7-legacy-memory-refs.txt

  Scenario: Diff and cleanup receipts
    Tool:     bash
    Steps:    git diff --check 2>&1 | tee .omo/evidence/task-7-diff-check.txt; (ps -axo pid,ppid,comm,args | rg -i "Chrome Helper|chromedriver|WebDriver|flutter.*web-server|--web-port" || true) | tee .omo/evidence/task-7-cleanup-receipt.txt
    Expected: `git diff --check` emits no whitespace errors; cleanup receipt has no WebDriver Chrome, ChromeDriver, or Flutter web-server process started by this task.
    Evidence: .omo/evidence/task-7-diff-check.txt
  ```

  Commit: YES | Message: `docs(catalog): align item census source of truth` | Files: [docs/current_system/CURRENT_CARD_CATALOG_TABLE.md, docs/planning/ACTIVE_EXECUTION_PLAN.md, docs/planning/POST_RITUAL_RUNTIME_REMAINING_WORK.md, docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md, docs/planning/feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md, docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md, test/logic/item_definition_test.dart, .omo/evidence/*]

## Final verification wave (MANDATORY - after all implementation tasks)
> Runs in PARALLEL. ALL must APPROVE. Surface results to the caller and wait for an explicit "okay" before declaring complete.
- [ ] F1. Plan compliance audit - every task done, every acceptance criterion met
- [ ] F2. Code quality review - diagnostics clean, idioms match, no dead code
- [ ] F3. Real manual QA - every QA scenario executed with evidence captured
- [ ] F4. Scope fidelity - nothing extra shipped beyond Must-Have, nothing Must-NOT-Have introduced

## Commit strategy
- One logical change per commit. Conventional Commits (`<type>(<scope>): <subject>` body + footer).
- Atomic: every commit builds and passes tests on its own.
- No "WIP" / "fix typo squash later" commits on the final branch - clean up before merge.
- Reference the plan file path in the final commit footer: `Plan: .omo/plans/task-1-catalog-census-source-of-truth-repair.md`.

## Success criteria
- All Must-Have shipped; all QA scenarios pass with captured evidence; F1-F4 approved; commit history clean.
