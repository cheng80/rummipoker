# Task 6 Compact Review Packet v3

## Reviewer Rejection Addressed

v1 rejected for missing embedded diff/evidence. v2 rejected for stale contradiction: Board-Line Ritual row still said current catalog 0. v3 embeds updated diff and RED/GREEN proof for that reviewer-found issue.

## Scope Note

Task 6 changed docs/test policy source-of-truth only. `.omo/notepads/...` is untracked evidence, so it does not appear in git diff; the Task 6 notepad section is quoted below. The scoped git diff command includes data/common/items_common_v1.json, data/common/jesters_common_phase5.json, and lib/logic/rummi_poker_grid/rummi_market_facade_builders.dart; stat shows no changes for those files.

## Scoped Git Diff And Stat
```diff
## git diff --stat
 .../feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md     |  62 ++++-
 test/logic/item_definition_test.dart               | 262 +++++++++++++++++++++
 2 files changed, 317 insertions(+), 7 deletions(-)

## scoped diff
diff --git a/docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md b/docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md
index 75a3863..d9c5e92 100644
--- a/docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md
+++ b/docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md
@@ -17,12 +17,12 @@ Board-Line Ritual: 0
 Direct Tile Modifier Item: 0
 ```
 
-현재는 Board-Line Ritual 38종을 실제 catalog에 추가해 총 92개 아이템 상태다. 따라서 다음 catalog 확장은 단순 점수 보정 아이템을 더 늘리는 일이 아니라, 추가된 Ritual 38종이 아래 기준을 만족하는지 닫는 작업이다.
+현재는 Ritual/Item 확장 계열 37종을 실제 catalog에 추가해 총 91개 아이템 상태다. 전투 보드 선 선택형 `ritual_line_effect`는 31장이고, Fate 변환 16종은 그 안의 고강도 변환 축으로 관리한다. active Ritual 31장은 normal market 후보, hold 마켓 보조 5종은 normal market 제외, debug 전용 0종은 현재 없음, deleted legacy 3종은 `boss_memory`, `thin_memory`, `minor_memory`다. 따라서 다음 catalog 확장은 단순 점수 보정 아이템을 더 늘리는 일이 아니라, 추가된 Ritual/Item 확장 계열이 아래 기준을 만족하는지 닫는 작업이다.
 
 - 효과별 target 조건이 유저에게 읽히는가.
 - 적용 결과가 board/deck/growth/seal/run info/log에 남는가.
 - `ritual_lens`, `ritual_coupon`, `seal_vendor`, `prune_vendor`, `line_pack_ticket`이 단순 할인/후보 수 변경처럼 약하게 보이지 않는가.
-- 38종 전부를 한 번에 pool에 넣은 상태에서 희귀도/가격/출현 weight가 과하지 않은가.
+- active Ritual 31종과 hold 마켓 보조 5종의 희귀도/가격/출현 weight가 과하지 않은가.
 
 ## 2. 분류 기준
 
@@ -33,9 +33,54 @@ Direct Tile Modifier Item: 0
 | `Resource / Board Action` | 손패, 보드 버림, 이동, 되돌리기, 덱 확인 | 유지. 풀런봇 정책과 UI 피드백 기준으로 가치 재점검. |
 | `Market / Economy / Pool` | 할인, 골드, 후보 교체, 후보 수/가격 조정 | 유지하되 자동 지급처럼 보이는 항목은 조건/표시 보강. |
 | `Survival` | 실패 방지/구제 | 희소하게 유지. 자동 완화처럼 보이지 않게 표시 필요. |
-| `Board-Line Ritual` | 보드 라인을 재료로 복제/각인/변형/압축 | 현재 catalog 0개. 새 덱빌딩 다양성의 1순위. |
+| `Board-Line Ritual` | 보드 라인을 재료로 복제/각인/변형/압축 | 현재 active Ritual 31장. 새 덱빌딩 다양성의 1순위였고, 지금은 active/hold 경계를 유지하며 가격/가중치와 전달력을 검증한다. |
 | `Direct Tile Modifier Item` | 타일 enhancement/seal/edition 직접 부여 | 현재 catalog 0개. 특수 타일 시스템과 연결해 확장. |
 
+### 2.1 Exposure group source of truth
+
+Task 6의 1차 정화 범위는 catalog 값을 바로 바꾸는 것이 아니라, 현재 노출 정책을 코드/문서/test에서 같은 기준으로 고정하는 것이다. 현행 catalog 기준 노출 그룹은 아래와 같다.
+
+| Group | Count | Policy |
+|---|---:|---|
+| normal item 86 | 86 | normal market 후보. 기존 Q-Slot/Tool/Gear/Passive와 active Ritual 31장을 포함한다. |
+| normal Jester 43 | 43 | normal market Jester 후보. 현재 Jester catalog 전부가 normal 노출이다. |
+| hold item 5 | 5 | Ritual 마켓 보조 후보. 재설계 전까지 normal market 제외. |
+| debug item 0 | 0 | 현재 debug 전용 item catalog 항목 없음. |
+| deleted legacy 3 | 3 | `boss_memory`, `thin_memory`, `minor_memory`; catalog/runtime/translation 대상에서 제거된 legacy 이름. |
+
+Normal item 86:
+
+`reroll_token`, `coupon_stamp`, `coin_cache`, `two_pair_study`, `triple_study`, `straight_study`, `flush_study`, `full_house_study`, `four_kind_study`, `straight_flush_study`, `line_memory`, `bridge_rite`
+`diagonal_rite`, `center_rite`, `corner_rite`, `cross_rite`, `sacrifice_line`, `deadwood_burn`, `trim_rank`, `trim_color`, `line_pruner`, `number_mask`, `wild_thread`, `off_color_rite`
+`color_concord`, `step_rite`, `rank_concord`, `fate_full_house_low`, `flush_house_fate`, `flush_five_fate`, `fate_flush_high`, `fate_flush_low`, `fate_straight_high`, `fate_straight_low`, `fate_three_kind_high`, `sealed_copy`
+`scarce_copy`, `color_echo`, `rank_echo`, `edge_copy`, `keystone_copy`, `cross_memory`, `board_scrap`, `hand_scrap`, `chip_capsule`, `mult_capsule`, `line_polish`, `straight_oil`
+`flush_powder`, `pair_splint`, `overlap_pin`, `emergency_draw`, `ledger_clip`, `discard_glove`, `mulligan_sleeve`, `jester_hook`, `score_abacus`, `thin_caliper`, `stage_map`, `merchant_stamp`
+`safety_net`, `coin_funnel`, `hand_funnel`, `echo_bell`, `boss_trophy`, `thin_wallet`, `trade_ticket`, `jester_invoice`, `item_invoice`, `red_swatch`, `blue_swatch`, `black_swatch`
+`yellow_swatch`, `rank_chalk`, `deck_needle`, `battle_pouch`, `tile_polisher`, `move_token`, `slide_wax`, `board_lift`, `undo_seal`, `organizer_glove`, `travel_pouch`, `wide_grip`
+`grand_satchel`, `market_compass`
+
+Normal Jester 43:
+
+`jester`, `greedy_jester`, `lusty_jester`, `wrathful_jester`, `gluttonous_jester`, `jolly_jester`, `zany_jester`, `mad_jester`, `crazy_jester`, `droll_jester`, `sly_jester`, `wily_jester`
+`clever_jester`, `devious_jester`, `crafty_jester`, `half_jester`, `jester_stencil`, `abstract_jester`, `green_jester`, `blue_jester`, `scary_face`, `smiley_face`, `egg`, `bonus_jester`
+`popcorn`, `ice_cream`, `delayed_gratification`, `walkie_talkie`, `golden_jester`, `mystic_summit`, `even_steven`, `odd_todd`, `scholar`, `fibonacci`, `banner`, `gros_michel`
+`supernova`, `ride_the_bus`, `the_duo`, `the_trio`, `the_family`, `the_order`, `the_tribe`
+
+Hold item 5:
+
+`ritual_coupon`, `ritual_lens`, `line_pack_ticket`, `seal_vendor`, `prune_vendor`
+
+Watchlist value lock:
+
+| ID | rarity | price | sell | Task 6 decision |
+|---|---|---:|---:|---|
+| `reroll_token` | common | 5G | 1G | low-tier utility. 유지하되 구매 가치 probe 대상. |
+| `trade_ticket` | uncommon | 6G | 3G | market pool mutation. Item 후보만 교체하는 기준 사례로 유지. |
+| `full_house_study` | rare | 9G | 4G | advanced study probe. Broad sim 전 fresh probe에서 구매/성장 빈도 확인. |
+| `four_kind_study` | rare | 10G | 5G | advanced study probe. Broad sim 전 fresh probe에서 구매/성장 빈도 확인. |
+| `straight_flush_study` | rare | 12G | 6G | advanced study probe. Broad sim 전 fresh probe에서 구매/성장 빈도 확인. |
+| `ride_the_bus` | uncommon | 6G | stateful_growth | redesign watch. 현재 Jester 값은 유지하되 stateful 성장 가독성과 face-card 조건 전달을 재검토한다. |
+
 ## 3. 현재 Catalog 분류
 
 ### 3.1 Hand-Rank Growth
@@ -145,7 +190,7 @@ Direct Tile Modifier Item: 0
 
 ### 4.1 Board-Line Ritual
 
-기준점 당시 catalog에는 0개였고, 다음 확장 1순위였다. 현재는 40종이 실제 catalog/runtime/번역/이미지 경로에 들어갔다. 전투 보드 선 선택형 `ritual_line_effect`는 34장이고, normal market 노출 후보는 31장으로 제한한다.
+기준점 당시 catalog에는 0개였고, 다음 확장 1순위였다. 현재는 Ritual/Item 확장 계열 37종이 실제 catalog/runtime/번역/이미지 경로에 들어갔다. 전투 보드 선 선택형 `ritual_line_effect`는 31장이고, normal market 노출 후보도 현재 active Ritual 31장으로 제한한다.
 
 현재 실행 분류:
 
@@ -154,8 +199,11 @@ Direct Tile Modifier Item: 0
 | 족보 변환형 운명 | 16 | Active | `trim_rank`, `line_pruner`, `fate_three_kind_high`, `color_concord`, `step_rite`, `rank_concord`, `fate_full_house_low`, `flush_house_fate`, `flush_five_fate`, `fate_flush_high`, `fate_flush_low`, `fate_straight_high`, `fate_straight_low`, `wild_thread`, `off_color_rite`, `number_mask` |
 | 제거/소각/제물 | 3 | Active | `trim_color`, `deadwood_burn`, `sacrifice_line` |
 | 덱 복사/메아리 | 6 | Active | `sealed_copy`, `scarce_copy`, `color_echo`, `rank_echo`, `edge_copy`, `keystone_copy` |
-| 성장/점수/표식/위치 의식 | 7 | Active | `line_memory`, `bridge_rite`, `diagonal_rite`, `center_rite`, `corner_rite`, `cross_rite`, `cross_memory` |
+| 성장/점수/표식/위치 의식 | 6 | Active | `bridge_rite`, `diagonal_rite`, `center_rite`, `corner_rite`, `cross_rite`, `cross_memory` |
 | 마켓 보조 의식 | 5 | Hold | `ritual_coupon`, `ritual_lens`, `line_pack_ticket`, `seal_vendor`, `prune_vendor` |
+| Debug 전용 | 0 | debug 전용 0종 | 없음 |
+| 삭제 legacy 기억 의식 | 3 | deleted legacy 3종 | `boss_memory`, `thin_memory`, `minor_memory` |
+| 비-Ritual 선 성장 | 1 | Active quickSlot | `line_memory` |
 
 정리 원칙:
 
@@ -189,7 +237,7 @@ Direct Tile Modifier Item: 0
 
 1. 완료: 현재 catalog 54개를 policy family 기준으로 1차 분류했다.
 2. 정정: 9개 후보는 너무 적다. 구현 안전 후보가 아니라 실제 카드 pool이 먼저 넓어야 한다.
-3. 완료: Board-Line Ritual 후보 38종을 실제 catalog에 추가했다.
+3. 완료: Ritual/Item 확장 계열 37종을 실제 catalog에 추가했다.
 4. 완료: 성장, 복사, 각인, 족보 강제 판정, 압축/즉시 제거, 보드 선 제거/회수, geometry, market 보조 계열을 `ritual_line_effect`/`ritualAction` 또는 기존 market op로 연결했다.
 5. 완료: Ritual line target을 scoring line 밖의 보드 선까지 확장했다. 효과별 target 조건은 점수 족보 선, 타일 3개 이상 보드 선, 보드 선 안의 타일로 나뉜다.
 6. 완료: 전투 선택 UI는 보드 미니 프리뷰 + line choice chip dialog로 교체했고, 다국어 효과 문구도 현재 조건에 맞게 정리했다.
@@ -347,7 +395,7 @@ Ritual 성장 카드는 자동으로 "가장 강한/약한/대표" 줄을 고르
 | fate transform | 운명 변환 16종 | 선택 보드 선 5칸을 실제 타일 세트로 치환 | board state | 선택 선, 변환 전후 타일, 확정 preview |
 | deck add | `sealed_copy`, `scarce_copy`, `color_echo`, `rank_echo`, `edge_copy`, `keystone_copy` | scoringTiles 기반 타일을 `addedDeckTiles`와 session deck top에 추가 | runProgress `addedDeckTiles`, session deck top | 덱 변화 flight, 다음 draw 반영 |
 | prune / burn / sacrifice | `trim_color`, `deadwood_burn`, `sacrifice_line` | 보드 선 제거, 골드/덱 보충 | board state, deck top, gold | 제거 line, 골드 flight, 덱 flight |
-| growth / geometry / marker | `line_memory`, `bridge_rite`, `diagonal_rite`, `center_rite`, `corner_rite`, `cross_rite`, `cross_memory` | 위치 조건에 따른 성장, 점수, 복사, 표식 보상 | 선택 결과별 runtime/runProgress | 중앙/대각/교차/모서리/겹친 줄 highlight |
+| growth / geometry / marker | `line_memory`, `bridge_rite`, `diagonal_rite`, `center_rite`, `corner_rite`, `cross_rite`, `cross_memory` | 위치 조건에 따른 성장, 점수, 복사, 표식 보상. `line_memory`는 `ritual_line_effect`가 아닌 별도 선 성장형 quickSlot이다. | 선택 결과별 runtime/runProgress | 중앙/대각/교차/모서리/겹친 줄 highlight |
 | hold / redesign | 마켓 보조 의식 5종 | normal market 제외 | catalog 검토 자산만 유지 | 별도 재설계 후 |
 
 ## 10. Policy Update Order
diff --git a/test/logic/item_definition_test.dart b/test/logic/item_definition_test.dart
index 913360b..17ecbe9 100644
--- a/test/logic/item_definition_test.dart
+++ b/test/logic/item_definition_test.dart
@@ -183,6 +183,83 @@ void main() {
       }
     });
 
+    test('catalog census docs match current catalog', () {
+      final catalog = ItemCatalog.fromJsonString(
+        File('data/common/items_common_v1.json').readAsStringSync(),
+      );
+      final currentCatalogDoc = File(
+        'docs/current_system/CURRENT_CARD_CATALOG_TABLE.md',
+      ).readAsStringSync();
+      final activePlanDoc = File(
+        'docs/planning/ACTIVE_EXECUTION_PLAN.md',
+      ).readAsStringSync();
+      final remainingWorkDoc = File(
+        'docs/planning/POST_RITUAL_RUNTIME_REMAINING_WORK.md',
+      ).readAsStringSync();
+      final policyAuditDoc = File(
+        'docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md',
+      ).readAsStringSync();
+      final runtimeMatrixDoc = File(
+        'docs/planning/feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md',
+      ).readAsStringSync();
+      final itemContractDoc = File(
+        'docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md',
+      ).readAsStringSync();
+
+      const fateActions = {
+        'fate_royal_flush',
+        'fate_straight_flush_high',
+        'fate_straight_flush_low',
+        'fate_four_kind_high',
+        'fate_four_kind_low',
+        'fate_full_house_high',
+        'fate_full_house_low',
+        'fate_flush_house',
+        'fate_flush_five',
+        'fate_flush_high',
+        'fate_flush_low',
+        'fate_straight_high',
+        'fate_straight_low',
+        'fate_three_kind_high',
+        'fate_three_kind_low',
+        'fate_two_pair_high',
+      };
+      final ritualItems = catalog.all
+          .where((item) => item.effect.op == 'ritual_line_effect')
+          .toList(growable: false);
+      final fateItems = ritualItems
+          .where(
+            (item) => fateActions.contains(item.effect.value('ritualAction')),
+          )
+          .toList(growable: false);
+
+      expect(
+        currentCatalogDoc,
+        contains('- Item total: ${catalog.all.length}'),
+      );
+      expect(
+        currentCatalogDoc,
+        contains('전투 보드 선 선택형 `ritual_line_effect`는 ${ritualItems.length}장'),
+      );
+      expect(currentCatalogDoc, contains('족보 변환형 운명 카드는 ${fateItems.length}장'));
+      expect(activePlanDoc, contains('현재 item catalog ${catalog.all.length}개'));
+      expect(
+        activePlanDoc,
+        contains('전투 보드 선 선택형 `ritual_line_effect`는 ${ritualItems.length}장'),
+      );
+      expect(
+        remainingWorkDoc,
+        contains(
+          '`boss_memory`, `thin_memory`, `minor_memory`는 catalog에서 삭제된 legacy 기억 의식',
+        ),
+      );
+      for (final doc in [policyAuditDoc, runtimeMatrixDoc, itemContractDoc]) {
+        expect(doc, contains('${catalog.all.length}개'));
+        expect(doc, contains('`ritual_line_effect`는 ${ritualItems.length}장'));
+        expect(doc, contains('Fate 변환 ${fateItems.length}'));
+      }
+    });
+
     test('fate transform items stay rare-or-higher and expensive', () {
       final catalog = ItemCatalog.fromJsonString(
         File('data/common/items_common_v1.json').readAsStringSync(),
@@ -236,6 +313,191 @@ void main() {
       expect(catalog.findById('flush_five_fate')!.basePrice, 22);
     });
 
+    test('ritual pool split docs match catalog groups', () {
+      final catalog = ItemCatalog.fromJsonString(
+        File('data/common/items_common_v1.json').readAsStringSync(),
+      );
+      final currentCatalogDoc = File(
+        'docs/current_system/CURRENT_CARD_CATALOG_TABLE.md',
+      ).readAsStringSync();
+      final policyAuditDoc = File(
+        'docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md',
+      ).readAsStringSync();
+      final runtimeMatrixDoc = File(
+        'docs/planning/feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md',
+      ).readAsStringSync();
+      final docs = [
+        currentCatalogDoc,
+        policyAuditDoc,
+        runtimeMatrixDoc,
+      ].join('\n');
+
+      const holdRitualIds = [
+        'ritual_coupon',
+        'ritual_lens',
+        'line_pack_ticket',
+        'seal_vendor',
+        'prune_vendor',
+      ];
+      const deletedLegacyRitualIds = [
+        'boss_memory',
+        'thin_memory',
+        'minor_memory',
+      ];
+      final activeRitualIds = catalog.all
+          .where((item) => item.effect.op == 'ritual_line_effect')
+          .map((item) => item.id)
+          .toSet();
+
+      expect(activeRitualIds.length, 31);
+      for (final id in activeRitualIds) {
+        expect(docs, contains('`$id`'), reason: '$id must be documented');
+      }
+      for (final id in holdRitualIds) {
+        expect(catalog.findById(id), isNotNull, reason: id);
+        expect(
+          docs,
+          contains('`$id`'),
+          reason: '$id must be documented as hold/redesign',
+        );
+      }
+      for (final id in deletedLegacyRitualIds) {
+        expect(catalog.findById(id), isNull, reason: id);
+        expect(
+          docs,
+          contains('`$id`'),
+          reason: '$id must be documented as deleted legacy',
+        );
+      }
+
+      expect(docs, contains('active Ritual 31'));
+      expect(docs, contains('hold 마켓 보조 5종'));
+      expect(docs, contains('debug 전용 0종'));
+      expect(docs, contains('deleted legacy 3종'));
+      expect(
+        docs,
+        contains('normal market 제외'),
+        reason: 'hold/debug Ritual groups must be explicitly excluded',
+      );
+    });
+
+    test('policy cleanup docs classify full catalog and watchlist values', () {
+      final itemCatalog = ItemCatalog.fromJsonString(
+        File('data/common/items_common_v1.json').readAsStringSync(),
+      );
+      final jesterData =
+          jsonDecode(
+                File(
+                  'data/common/jesters_common_phase5.json',
+                ).readAsStringSync(),
+              )
+              as List<dynamic>;
+      final policyAuditDoc = File(
+        'docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md',
+      ).readAsStringSync();
+      final currentCatalogDoc = File(
+        'docs/current_system/CURRENT_CARD_CATALOG_TABLE.md',
+      ).readAsStringSync();
+      final docs = '$policyAuditDoc\n$currentCatalogDoc';
+
+      final jesterIds = jesterData
+          .cast<Map<String, dynamic>>()
+          .map((entry) => entry['id'] as String)
+          .toSet();
+      const holdItemIds = {
+        'ritual_coupon',
+        'ritual_lens',
+        'line_pack_ticket',
+        'seal_vendor',
+        'prune_vendor',
+      };
+      const deletedLegacyIds = {'boss_memory', 'thin_memory', 'minor_memory'};
+      final normalItemIds = itemCatalog.all
+          .map((item) => item.id)
+          .where((id) => !holdItemIds.contains(id))
+          .toSet();
+
+      expect(normalItemIds.length, 86);
+      expect(jesterIds.length, 43);
+      expect(holdItemIds.length, 5);
+
+      expect(docs, contains('Exposure group source of truth'));
+      expect(docs, contains('normal item 86'));
+      expect(docs, contains('normal Jester 43'));
+      expect(docs, contains('hold item 5'));
+      expect(docs, contains('debug item 0'));
+      expect(docs, contains('deleted legacy 3'));
+      expect(
+        policyAuditDoc,
+        isNot(
+          contains(
+            '| `Board-Line Ritual` | 보드 라인을 재료로 복제/각인/변형/압축 | 현재 catalog 0개',
+          ),
+        ),
+        reason:
+            'current policy docs must not retain the pre-Ritual baseline as current state',
+      );
+      expect(
+        policyAuditDoc,
+        contains('현재 active Ritual 31장'),
+        reason:
+            'classification row must point at the current active Ritual pool',
+      );
+
+      for (final id in normalItemIds) {
+        expect(docs, contains('`$id`'), reason: '$id missing from policy docs');
+      }
+      for (final id in jesterIds) {
+        expect(docs, contains('`$id`'), reason: '$id missing from policy docs');
+      }
+      for (final id in holdItemIds) {
+        expect(
+          docs,
+          contains('`$id`'),
+          reason: '$id missing from hold policy docs',
+        );
+      }
+      for (final id in deletedLegacyIds) {
+        expect(
+          docs,
+          contains('`$id`'),
+          reason: '$id missing from deleted legacy policy docs',
+        );
+      }
+
+      final watchlistItems = {
+        'reroll_token': ('common', 5, 1, 'low-tier utility'),
+        'trade_ticket': ('uncommon', 6, 3, 'market pool mutation'),
+        'full_house_study': ('rare', 9, 4, 'advanced study probe'),
+        'four_kind_study': ('rare', 10, 5, 'advanced study probe'),
+        'straight_flush_study': ('rare', 12, 6, 'advanced study probe'),
+      };
+      for (final MapEntry(:key, :value) in watchlistItems.entries) {
+        final item = itemCatalog.findById(key)!;
+        expect(item.rarity.name, value.$1, reason: key);
+        expect(item.basePrice, value.$2, reason: key);
+        expect(item.sellPrice, value.$3, reason: key);
+        expect(
+          docs,
+          contains('`$key` | ${value.$1} | ${value.$2}G | ${value.$3}G'),
+          reason: '$key watchlist values must be documented',
+        );
+        expect(docs, contains(value.$4), reason: key);
+      }
+
+      final rideTheBus = jesterData.cast<Map<String, dynamic>>().singleWhere(
+        (entry) => entry['id'] == 'ride_the_bus',
+      );
+      expect(rideTheBus['rarity'], 'uncommon');
+      expect(rideTheBus['baseCost'], 6);
+      expect(rideTheBus['effectType'], 'stateful_growth');
+      expect(
+        docs,
+        contains('`ride_the_bus` | uncommon | 6G | stateful_growth'),
+      );
+      expect(docs, contains('redesign watch'));
+    });
+
     test('legacy fate item ids resolve to canonical item ids', () {
       final catalog = ItemCatalog.fromJsonString(
         File('data/common/items_common_v1.json').readAsStringSync(),
```

## Task 6 Notepad Section
```md
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
```

## Initial RED Evidence Output
```text
00:00 +0: loading /Users/cheng80/Desktop/flame_binggo_card/test/logic/item_definition_test.dart
00:00 +0: ItemCatalog policy cleanup docs classify full catalog and watchlist values
00:00 +0 -1: ItemCatalog policy cleanup docs classify full catalog and watchlist values [E]
  Expected: contains 'Exposure group source of truth'
    Actual: '# Item Policy Cleanup Audit\n'
              '\n'
              '> 목적: `policy-cleanup-baseline-20260530` 이후 아이템/덱빌딩 정책 정화의 작업 표.\n'
              '> Source contract: `docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md`\n'
              '\n'
              '## 1. 결론\n'
              '\n'
              '기준점 `policy-cleanup-baseline-20260530` 당시 `data/common/items_common_v1.json`의 54개 아이템은 런타임 동작은 넓게 갖췄지만, 덱빌딩 다양성 관점에서는 아래로 치우쳐 있었다.\n'
              '\n'
              '```text\n'
              'Hand-Rank Growth: 7\n'
              'Confirm / Score Modifier: 16\n'
              'Resource / Board Action: 15\n'
              'Market / Economy / Pool: 15\n'
              'Survival: 1\n'
              'Board-Line Ritual: 0\n'
              'Direct Tile Modifier Item: 0\n'
              '```\n'
              '\n'
              '현재는 Ritual/Item 확장 계열 37종을 실제 catalog에 추가해 총 91개 아이템 상태다. 전투 보드 선 선택형 `ritual_line_effect`는 31장이고, Fate 변환 16종은 그 안의 고강도 변환 축으로 관리한다. active Ritual 31장은 normal market 후보, hold 마켓 보조 5종은 normal market 제외, debug 전용 0종은 현재 없음, deleted legacy 3종은 `boss_memory`, `thin_memory`, `minor_memory`다. 따라서 다음 catalog 확장은 단순 점수 보정 아이템을 더 늘리는 일이 아니라, 추가된 Ritual/Item 확장 계열이 아래 기준을 만족하는지 닫는 작업이다.\n'
              '\n'
              '- 효과별 target 조건이 유저에게 읽히는가.\n'
              '- 적용 결과가 board/deck/growth/seal/run info/log에 남는가.\n'
              '- `ritual_lens`, `ritual_coupon`, `seal_vendor`, `prune_vendor`, `line_pack_ticket`이 단순 할인/후보 수 변경처럼 약하게 보이지 않는가.\n'
              '- active Ritual 31종과 hold 마켓 보조 5종의 희귀도/가격/출현 weight가 과하지 않은가.\n'
              '\n'
              '## 2. 분류 기준\n'
              '\n'
              '| Family | 설명 | 이번 정화 판단 |\n'
              '|---|---|---|\n'
              '| `Hand-Rank Growth` | 특정 족보 레벨을 올리는 Planet-like 축 | 유지. 단 next-confirm 임시 보정과 섞지 않는다. |\n'
              '| `Confirm / Score Modifier` | 다음 확정 또는 조건부 확정 점수 보정 | 이미 많음. 추가 억제. 조건/대상/연출 없는 항목은 정리 후보. |\n'
              '| `Resource / Board Action` | 손패, 보드 버림, 이동, 되돌리기, 덱 확인 | 유지. 풀런봇 정책과 UI 피드백 기준으로 가치 재점검. |\n'
              '| `Market / Economy / Pool` | 할인, 골드, 후보 교체, 후보 수/가격 조정 | 유지하되 자동 지급처럼 보이는 항목은 조건/표시 보강. |\n'
              '| `Survival` | 실패 방지/구제 | 희소하게 유지. 자동 완화처럼 보이지 않게 표시 필요. |\n'
              '| `Board-Line Ritual` | 보드 라인을 재료로 복제/각인/변형/압축 | 현재 catalog 0개. 새 덱빌딩 다양성의 1순위. |\n'
              '| `Direct Tile Modifier Item` | 타일 enhancement/seal/edition 직접 부여 | 현재 catalog 0개. 특수 타일 시스템과 연결해 확장. |\n'
              '\n'
              '## 3. 현재 Catalog 분류\n'
              '\n'
              '### 3.1 Hand-Rank Growth\n'
```

## Reviewer-Found Stale Policy RED Output
```text
00:00 +0: loading /Users/cheng80/Desktop/flame_binggo_card/test/logic/item_definition_test.dart
00:00 +0: ItemCatalog policy cleanup docs classify full catalog and watchlist values
00:00 +0 -1: ItemCatalog policy cleanup docs classify full catalog and watchlist values [E]
  Expected: not contains '| `Board-Line Ritual` | 보드 라인을 재료로 복제/각인/변형/압축 | 현재 catalog 0개'
    Actual: '# Item Policy Cleanup Audit\n'
              '\n'
              '> 목적: `policy-cleanup-baseline-20260530` 이후 아이템/덱빌딩 정책 정화의 작업 표.\n'
              '> Source contract: `docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md`\n'
              '\n'
              '## 1. 결론\n'
              '\n'
              '기준점 `policy-cleanup-baseline-20260530` 당시 `data/common/items_common_v1.json`의 54개 아이템은 런타임 동작은 넓게 갖췄지만, 덱빌딩 다양성 관점에서는 아래로 치우쳐 있었다.\n'
              '\n'
              '```text\n'
              'Hand-Rank Growth: 7\n'
              'Confirm / Score Modifier: 16\n'
              'Resource / Board Action: 15\n'
              'Market / Economy / Pool: 15\n'
              'Survival: 1\n'
              'Board-Line Ritual: 0\n'
              'Direct Tile Modifier Item: 0\n'
              '```\n'
              '\n'
              '현재는 Ritual/Item 확장 계열 37종을 실제 catalog에 추가해 총 91개 아이템 상태다. 전투 보드 선 선택형 `ritual_line_effect`는 31장이고, Fate 변환 16종은 그 안의 고강도 변환 축으로 관리한다. active Ritual 31장은 normal market 후보, hold 마켓 보조 5종은 normal market 제외, debug 전용 0종은 현재 없음, deleted legacy 3종은 `boss_memory`, `thin_memory`, `minor_memory`다. 따라서 다음 catalog 확장은 단순 점수 보정 아이템을 더 늘리는 일이 아니라, 추가된 Ritual/Item 확장 계열이 아래 기준을 만족하는지 닫는 작업이다.\n'
              '\n'
              '- 효과별 target 조건이 유저에게 읽히는가.\n'
              '- 적용 결과가 board/deck/growth/seal/run info/log에 남는가.\n'
              '- `ritual_lens`, `ritual_coupon`, `seal_vendor`, `prune_vendor`, `line_pack_ticket`이 단순 할인/후보 수 변경처럼 약하게 보이지 않는가.\n'
              '- active Ritual 31종과 hold 마켓 보조 5종의 희귀도/가격/출현 weight가 과하지 않은가.\n'
              '\n'
              '## 2. 분류 기준\n'
              '\n'
              '| Family | 설명 | 이번 정화 판단 |\n'
              '|---|---|---|\n'
              '| `Hand-Rank Growth` | 특정 족보 레벨을 올리는 Planet-like 축 | 유지. 단 next-confirm 임시 보정과 섞지 않는다. |\n'
              '| `Confirm / Score Modifier` | 다음 확정 또는 조건부 확정 점수 보정 | 이미 많음. 추가 억제. 조건/대상/연출 없는 항목은 정리 후보. |\n'
              '| `Resource / Board Action` | 손패, 보드 버림, 이동, 되돌리기, 덱 확인 | 유지. 풀런봇 정책과 UI 피드백 기준으로 가치 재점검. |\n'
              '| `Market / Economy / Pool` | 할인, 골드, 후보 교체, 후보 수/가격 조정 | 유지하되 자동 지급처럼 보이는 항목은 조건/표시 보강. |\n'
              '| `Survival` | 실패 방지/구제 | 희소하게 유지. 자동 완화처럼 보이지 않게 표시 필요. |\n'
              '| `Board-Line Ritual` | 보드 라인을 재료로 복제/각인/변형/압축 | 현재 catalog 0개. 새 덱빌딩 다양성의 1순위. |\n'
              '| `Direct Tile Modifier Item` | 타일 enhancement/seal/edition 직접 부여 | 현재 catalog 0개. 특수 타일 시스템과 연결해 확장. |\n'
              '\n'
              '### 2.1 Exposure group source of truth\n'
              '\n'
              'Task 6의 1차 정화 범위는 catalog 값을 바로 바꾸는 것이 아니라, 현재 노출 정책을 코드/문서/test에서 같은 기준으로 고정하는 것이다. 현행 catalog 기준 노출 그룹은 아래와 같다.\n'
              '\n'
              '| Group | Count | Policy |\n'
              '|---|---:|---|\n'
              '| normal item 86 | 86 | normal market 후보. 기존 Q-Slot/Tool/Gear/Passive와 active Ritual 31장을 포함한다. |\n'
              '| normal Jester 43 | 43 | normal market Jester 후보. 현재 Jester catalog 전부가 normal 노출이다. |\n'
              '| hold item 5 | 5 | Ritual 마켓 보조 후보. 재설계 전까지 normal market 제외. |\n'
              '| debug item 0 | 0 | 현재 debug 전용 item catalog 항목 없음. |\n'
              '| deleted legacy 3 | 3 | `boss_memory`, `thin_memory`, `minor_memory`; catalog/runtime/translation 대상에서 제거된 legacy 이름. |\n'
              '\n'
              'Normal item 86:\n'
              '\n'
              '`reroll_token`, `coupon_stamp`, `coin_cache`, `two_pair_study`, `triple_study`, `straight_study`, `flush_study`, `full_house_study`, `four_kind_study`, `straight_flush_study`, `line_memory`, `bridge_rite`\n'
              '`diagonal_rite`, `center_rite`, `corner_rite`, `cross_rite`, `sacrifice_line`, `deadwood_burn`, `trim_rank`, `trim_color`, `line_pruner`, `number_mask`, `wild_thread`, `off_color_rite`\n'
              '`color_concord`, `step_rite`, `rank_concord`, `fate_full_house_low`, `flush_house_fate`, `flush_five_fate`, `fate_flush_high`, `fate_flush_low`, `fate_straight_high`, `fate_straight_low`, `fate_three_kind_high`, `sealed_copy`\n'
              '`scarce_copy`, `color_echo`, `rank_echo`, `edge_copy`, `keystone_copy`, `cross_memory`, `board_scrap`, `hand_scrap`, `chip_capsule`, `mult_capsule`, `line_polish`, `straight_oil`\n'
              '`flush_powder`, `pair_splint`, `overlap_pin`, `emergency_draw`, `ledger_clip`, `discard_glove`, `mulligan_sleeve`, `jester_hook`, `score_abacus`, `thin_caliper`, `stage_map`, `merchant_stamp`\n'
              '`safety_net`, `coin_funnel`, `hand_funnel`, `echo_bell`, `boss_trophy`, `thin_wallet`, `trade_ticket`, `jester_invoice`, `item_invoice`, `red_swatch`, `blue_swatch`, `black_swatch`\n'
              '`yellow_swatch`, `rank_chalk`, `deck_needle`, `battle_pouch`, `tile_polisher`, `move_token`, `slide_wax`, `board_lift`, `undo_seal`, `organizer_glove`, `travel_pouch`, `wide_grip`\n'
              '`grand_satchel`, `market_compass`\n'
              '\n'
              'Normal Jester 43:\n'
              '\n'
              '`jester`, `greedy_jester`, `lusty_jester`, `wrathful_jester`, `gluttonous_jester`, `jolly_jester`, `zany_jester`, `mad_jester`, `crazy_jester`, `droll_jester`, `sly_jester`, `wily_jester`\n'
              '`clever_jester`, `devious_jester`, `crafty_jester`, `half_jester`, `jester_stencil`, `abstract_jester`, `green_jester`, `blue_jester`, `scary_face`, `smiley_face`, `egg`, `bonus_jester`\n'
              '`popcorn`, `ice_cream`, `delayed_gratification`, `walkie_talkie`, `golden_jester`, `mystic_summit`, `even_steven`, `odd_todd`, `scholar`, `fibonacci`, `banner`, `gros_michel`\n'
```

## Stale Policy Fix GREEN Output
```text
00:00 +0: loading /Users/cheng80/Desktop/flame_binggo_card/test/logic/item_definition_test.dart
00:00 +0: ItemCatalog policy cleanup docs classify full catalog and watchlist values
00:00 +1: All tests passed!
```

## Bash Policy Artifact Output
```text
item total: 91
jester total: 43
normal item 86: True
normal Jester 43: True
hold item 5: ['line_pack_ticket', 'prune_vendor', 'ritual_coupon', 'ritual_lens', 'seal_vendor']
debug item 0: true
deleted legacy 3: ['boss_memory', 'minor_memory', 'thin_memory']
item placement counts: {'inventory': 20, 'quickSlot': 52, 'equipped': 9, 'passiveRack': 10}
item rarity counts: {'common': 17, 'uncommon': 30, 'rare': 34, 'legendary': 10}
jester rarity counts: {'common': 30, 'rare': 10, 'uncommon': 3}
watchlist item: reroll_token common 5G 1G discount_next_reroll
watchlist item: trade_ticket uncommon 6G 3G reroll_item_offers_only
watchlist item: full_house_study rare 9G 4G add_hand_rank_progress
watchlist item: four_kind_study rare 10G 5G add_hand_rank_progress
watchlist item: straight_flush_study rare 12G 6G add_hand_rank_progress
watchlist jester: ride_the_bus uncommon 6G stateful_growth consecutive_hands_without_scoring_face_card
```

## Watchlist Evidence Output
```text
00:00 +0: loading /Users/cheng80/Desktop/flame_binggo_card/test/logic/item_definition_test.dart
00:00 +0: ItemCatalog policy cleanup docs classify full catalog and watchlist values
00:00 +1: All tests passed!
```

## Full Acceptance Suite Outputs
```text
00:00 +0: loading /Users/cheng80/Desktop/flame_binggo_card/test/logic/item_definition_test.dart
00:00 +0: ItemCatalog parses item definitions and exposes lookup helpers
00:00 +1: ItemCatalog v1 catalog keeps Korean text in localization data only
00:00 +2: ItemCatalog player-facing item data does not use voucher wording
00:00 +3: ItemCatalog catalog census docs match current catalog
00:00 +4: ItemCatalog fate transform items stay rare-or-higher and expensive
00:00 +5: ItemCatalog ritual pool split docs match catalog groups
00:00 +6: ItemCatalog policy cleanup docs classify full catalog and watchlist values
00:00 +7: ItemCatalog legacy fate item ids resolve to canonical item ids
00:00 +8: ItemCatalog owned item inventory state roundtrips storage shape
00:00 +9: ItemCatalog owned item inventory acquires items by placement and stack limit
00:00 +10: ItemCatalog quick slot acquisition respects dynamic slot capacity
00:00 +11: ItemCatalog owned item inventory consumes stacks and removes empty slot ids
00:00 +12: All tests passed!

00:00 +0: loading /Users/cheng80/Desktop/flame_binggo_card/test/logic/rummi_market_facade_test.dart
00:00 +0: RummiMarketRuntimeFacade maps current shop offers into market offers
00:00 +1: RummiMarketRuntimeFacade keeps remaining jester offer prices after buying another offer
00:00 +2: RummiMarketRuntimeFacade keeps remaining jester offers normally priced after any offer purchase
00:00 +3: RummiMarketRuntimeFacade consumes jester purchase discount after one offer purchase
00:00 +4: RummiMarketRuntimeFacade item purchase discount does not leak into jester offer prices
00:00 +5: RummiMarketRuntimeFacade consumes item purchase discount after one item purchase
00:00 +6: RummiMarketRuntimeFacade maps tile offers and added deck tiles into market facade
00:00 +7: RummiMarketRuntimeFacade maps item definitions into item market offers without jester slots
00:00 +8: RummiMarketRuntimeFacade maps market modifiers into displayed reroll and offer prices
00:00 +9: RummiMarketRuntimeFacade market compass discounts one visible cheapest item offer
00:00 +10: RummiMarketRuntimeFacade market compass skips zero price item offers
00:00 +11: RummiMarketRuntimeFacade maps owned jesters into sellable market entries
00:00 +12: RummiMarketRuntimeFacade applies owned sell item modifiers
00:00 +13: RummiMarketRuntimeFacade maps owned item inventory into market item slots
00:00 +14: RummiMarketRuntimeFacade consumed item offers are removed from market item offers
00:00 +15: RummiMarketRuntimeFacade deferred ritual items are filtered while active ritual items remain
00:00 +16: RummiMarketRuntimeFacade buying an item offer does not refill the empty market slot
00:00 +17: RummiMarketRuntimeFacade station band market policy keeps early economy and late boss growth
00:00 +18: RummiMarketRuntimeFacade mid station market policy keeps score growth ahead of resources
00:00 +19: RummiMarketRuntimeFacade fate transforms stay rare market pressure picks
00:00 +20: RummiMarketRuntimeFacade final station market policy keeps shape correction available
00:00 +21: RummiMarketRuntimeFacade missing growth correction only changes market appearance weight
00:00 +22: RummiMarketRuntimeFacade collection correction only changes market appearance weight
00:00 +23: RummiMarketRuntimeFacade collection correction makes unseen jester offers observable
00:00 +24: RummiMarketRuntimeFacade high stakes market pressure adds transient item offer room
00:00 +25: RummiMarketRuntimeFacade full passive rack still shows sell-and-replace passive offers
00:00 +26: RummiMarketRuntimeFacade full quick slots still show sell-and-replace quick item offers
00:00 +27: RummiMarketRuntimeFacade missing growth exposure can focus a random item offer slot
00:00 +28: RummiMarketRuntimeFacade missing growth exposure can focus a random jester offer slot
00:00 +29: RummiMarketRuntimeFacade marks unaffordable offers and carries runtime snapshot values
00:00 +30: RummiMarketRuntimeFacade tile gold bonus and blue seal progress apply after confirm
00:00 +31: RummiMarketRuntimeFacade base run leaves the fifth jester slot locked until boss reward
00:00 +32: RummiMarketRuntimeFacade boss slot rewards unlock quick and passive capacities
00:00 +33: RummiMarketRuntimeFacade boss trophy next-market jester slot applies for one market
00:00 +34: RummiMarketRuntimeFacade boss trophy jester slot bonus is exposed as market label
00:00 +35: RummiMarketRuntimeFacade jester, tile, and item reroll costs advance independently
00:00 +36: RummiMarketRuntimeFacade first free jester reroll is not restored on the next market
00:00 +37: RummiMarketRuntimeFacade tile reroll refills only tile offers and consumes tile first free reroll
00:00 +38: RummiMarketRuntimeFacade first free reroll consumed lanes survive restore
00:00 +39: RummiMarketRuntimeFacade tile reroll keeps tile card offers available after bought tiles
00:00 +40: RummiMarketRuntimeFacade late shop tile offers can generate special modifiers
00:00 +41: RummiMarketRuntimeFacade facade is snapshot-based and requires re-creation after mutations
00:00 +42: All tests passed!
```

## Analyze And Cleanup Outputs
```text
Analyzing item_definition_test.dart...
No issues found!

cleanup receipt 2026-06-03 10:16:34 KST
tmux: unavailable
flutter/webdriver/headless residue after excluding this receipt command:
conclusion: no flutter test/flutter_tester/chromedriver/webdriver/flutter web server/headless Chrome residue from Task 6 tests.
```

## Review Questions

1. Does updated diff/test prove stale Board-Line Ritual current-catalog-0 wording is blocked and fixed?
2. Does embedded diff/test prove full Item/Jester exposure group source-of-truth?
3. Does watchlist lock cover trade_ticket, ride_the_bus, advanced study cards, and reroll_token?
4. Does stat prove no catalog JSON/runtime/market policy code value changes in Task 6?
