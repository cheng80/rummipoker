# Task 1 Compact Review Packet

## Expected Census
- total items: 91
- quickSlot placement: 52
- ritual_line_effect: 31
- Fate transform: 16
- active Ritual: 31
- hold/debug Ritual: 0
- deleted legacy memories absent from catalog: boss_memory, thin_memory, minor_memory

## Changed Files
docs/current_system/CURRENT_CARD_CATALOG_TABLE.md
docs/planning/ACTIVE_EXECUTION_PLAN.md
docs/planning/feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md
docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md
docs/planning/feature_plans/ITEM_PRESENTATION_CONTRACT_REVIEW.md
docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md
test/logic/item_definition_test.dart
docs/planning/POST_RITUAL_RUNTIME_REMAINING_WORK.md (untracked existing doc edited)
.omo/notepads/active-execution-task1-catalog-census.md
.omo/evidence/task-1-*.txt

## Key Diff Summary
 docs/current_system/CURRENT_CARD_CATALOG_TABLE.md  |  6 +-
 docs/planning/ACTIVE_EXECUTION_PLAN.md             | 10 +--
 .../feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md    | 16 ++---
 .../feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md     | 13 ++--
 .../ITEM_PRESENTATION_CONTRACT_REVIEW.md           |  2 +-
 docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md           | 13 ++--
 test/logic/item_definition_test.dart               | 77 ++++++++++++++++++++++
 7 files changed, 109 insertions(+), 28 deletions(-)

## Test Added
186:    test('catalog census docs match current catalog', () {
199:      final policyAuditDoc = File(
202:      final runtimeMatrixDoc = File(
205:      final itemContractDoc = File(
209:      const fateActions = {
232:            (item) => fateActions.contains(item.effect.value('ritualAction')),
256:      for (final doc in [policyAuditDoc, runtimeMatrixDoc, itemContractDoc]) {

## Evidence Results
- RED 1: .omo/evidence/task-1-red-doc-census-test.txt failed on stale Item total 94.
- RED 2: .omo/evidence/task-1-red-extended-doc-census-test.txt failed on stale policy/runtime/spec docs.
- GREEN focused: .omo/evidence/task-1-green-extended-doc-census-test.txt passed.
- Full item_definition_test: .omo/evidence/task-1-item-definition-test.txt passed.
- rummi_market_facade_test: .omo/evidence/task-1-rummi-market-facade-test.txt passed.
- dart analyze test file: .omo/evidence/task-1-dart-analyze-test-file.txt passed.
- git diff --check: .omo/evidence/task-1-diff-check.txt passed.
- cleanup: .omo/evidence/task-1-cleanup.txt says no QA-spawned flutter/webdriver/server process remains; tmux unavailable.

## Stale Search
command: rg stale current-count patterns
docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md:530:첫 catalog draft는 38종 후보 pool에서 18종 안팎을 고른다. 9종 이하의 작은 pool은 반복 구매 패턴을 만들 가능성이 높으므로 폐기한다.
docs/planning/leveling/ECONOMY_LEVELING_PLAN.md:335:  - item 49개, Jester 43개, 총 92개 후보를 점검한다.
docs/planning/feature_plans/ITEM_PRESENTATION_CONTRACT_REVIEW.md:5:> 과거 1차 결론: 당시 55개 검토 중 `shop_lens` 1개 삭제, 활성 Item 54개 보강 계획.
docs/planning/ACTIVE_EXECUTION_PLAN.md:78:3. 완료: 9개 후보는 너무 적다는 판단으로 폐기하고, 새 카드 후보 pool을 40종으로 확장했다. 이후 기억 의식 3종은 재설계 가치가 낮아 삭제했다.
docs/planning/ACTIVE_EXECUTION_PLAN.md:123:   - 완료: 당시 전체 Item 55개를 `발동 객체 -> 적용 대상 -> 결과` 기준으로 재검토하는 1차 계약표를 `docs/planning/feature_plans/ITEM_PRESENTATION_CONTRACT_REVIEW.md`에 만들었다. `shop_lens`는 삭제 상태로 두고, 당시 활성 54개는 P0~P3 보강 우선순위로 분류했다.
PASS condition: no stale count remains in current source-of-truth statements; remaining matches are historical candidate/presentation/leveling records.

## Census Artifact Head
Task 1 Catalog Census
source: data/common/items_common_v1.json
schemaVersion: 1
catalogId: items_common_v1
totalItemCount: 91
typeCounts: {"consumable":58,"equipment":9,"passive_relic":10,"utility":14}
placementCounts: {"equipped":9,"inventory":20,"passiveRack":10,"quickSlot":52}
ritualLineEffectCount: 31
fateTransformCount: 16
activeRitualCount: 31
holdDebugRitualCount: 0
deletedLegacyMemoryIds: boss_memory, thin_memory, minor_memory

Fate transform ids:
- trim_rank | rarity=rare | price=11 | action=fate_two_pair_high | weight=n/a
- line_pruner | rarity=rare | price=12 | action=fate_three_kind_low | weight=n/a
- number_mask | rarity=legendary | price=20 | action=fate_royal_flush | weight=n/a
- wild_thread | rarity=legendary | price=18 | action=fate_straight_flush_high | weight=n/a
- off_color_rite | rarity=legendary | price=17 | action=fate_straight_flush_low | weight=n/a
- color_concord | rarity=rare | price=15 | action=fate_four_kind_high | weight=n/a
- step_rite | rarity=rare | price=15 | action=fate_four_kind_low | weight=n/a
- rank_concord | rarity=rare | price=15 | action=fate_full_house_high | weight=n/a
- fate_full_house_low | rarity=rare | price=15 | action=fate_full_house_low | weight=n/a
- flush_house_fate | rarity=legendary | price=20 | action=fate_flush_house | weight=n/a
- flush_five_fate | rarity=legendary | price=22 | action=fate_flush_five | weight=n/a
- fate_flush_high | rarity=rare | price=14 | action=fate_flush_high | weight=n/a
- fate_flush_low | rarity=rare | price=14 | action=fate_flush_low | weight=n/a
- fate_straight_high | rarity=rare | price=13 | action=fate_straight_high | weight=n/a
- fate_straight_low | rarity=rare | price=13 | action=fate_straight_low | weight=n/a
- fate_three_kind_high | rarity=rare | price=12 | action=fate_three_kind_high | weight=n/a

Non-Fate active ritual ids:
- bridge_rite | rarity=rare | price=12 | action=seal_bridge | weight=n/a
- diagonal_rite | rarity=rare | price=10 | action=line_bonus_35 | weight=n/a
- center_rite | rarity=uncommon | price=8 | action=center_growth | weight=n/a
- corner_rite | rarity=uncommon | price=8 | action=copy_endpoint | weight=n/a
- cross_rite | rarity=rare | price=11 | action=line_bonus_25 | weight=n/a
- sacrifice_line | rarity=legendary | price=15 | action=sacrifice_line | weight=n/a
- deadwood_burn | rarity=rare | price=10 | action=burn_line | weight=n/a
- trim_color | rarity=uncommon | price=8 | action=prune_line_to_color | weight=n/a
- sealed_copy | rarity=rare | price=12 | action=copy_selected | weight=n/a
- scarce_copy | rarity=rare | price=10 | action=copy_selected | weight=n/a
- color_echo | rarity=uncommon | price=8 | action=copy_color | weight=n/a
- rank_echo | rarity=uncommon | price=8 | action=copy_rank | weight=n/a
- edge_copy | rarity=common | price=6 | action=copy_selected | weight=n/a
- keystone_copy | rarity=uncommon | price=8 | action=copy_center | weight=n/a
- cross_memory | rarity=rare | price=10 | action=growth_marker | weight=n/a

## Legacy Refs
channel: cli stdout
command: rg "boss_memory|thin_memory|minor_memory" data docs lib test
test/logic/item_definition_test.dart:244:          '`boss_memory`, `thin_memory`, `minor_memory`는 catalog에서 삭제된 legacy 기억 의식',
docs/planning/POST_RITUAL_RUNTIME_REMAINING_WORK.md:50:- `boss_memory`, `thin_memory`, `minor_memory`는 catalog에서 삭제된 legacy 기억 의식으로 유지
PASS condition: no data/lib runtime references; remaining doc reference states catalog-deleted legacy memory status.
