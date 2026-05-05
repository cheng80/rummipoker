# Leveling Applied Status

> 문서 성격: leveling implementation checklist / applied status
> 작성일: 2026-05-04
> 정책 기준: `docs/current_system/CURRENT_LEVELING_POLICY.md`
> 런타임 기준표: `docs/current_system/CURRENT_LEVELING_RUNTIME_SPEC.md`
> ML 기준: `docs/current_system/CURRENT_LEVELING_ML_BASELINE.md`

이 문서는 레벨링 실험 산출물이 실제 런타임에 어디까지 반영되었는지 추적한다.

상태 기준:

- `Applied`: 코드와 테스트에 반영됨.
- `Partially applied`: 일부 축만 코드화됨.
- `Workspace pending`: 현재 작업 트리에 반영됐지만 아직 커밋 전.
- `Spec only`: 문서 기준만 있고 런타임 적용 전.
- `Rejected`: 정책상 폐기.

## 1. Current Snapshot

| Area | Status | Runtime anchor | Notes |
|---|---|---|---|
| S1~S8 standard target table | Applied | `BlindSelectionSpecBuilder._standardTargetScore` | small/big/boss 목표표 런타임 연결 완료 |
| difficulty multiplier | Applied | `BlindSelectionSpecBuilder._difficultyMultiplier` | relaxed 0.8, standard 1.0, pressure 1.2 |
| blind tier resource pressure | Applied | `BlindSelectionSpecBuilder` | 전투 시작 압박이며 자동 보상/성장 지급이 아님 |
| run modifier target/reward hook | Applied | `NewRunModifier` / `RunUnlockStateService` / `BlindSelectionSpecBuilder` / active run save | `basic`은 기존 값 유지. `high_stakes`는 Insight 20 해금 후 target 1.04, reward 1.12를 명시 적용하며 active run 저장/복원에 modifier id를 보존 |
| run modifier market pressure profile | Applied | `RummiMarketPressureProfile` / `RummiStationBandMarketPolicy` / `RummiMarketRuntimeFacade` / `RummiRunProgress.openShop` | 저장 포맷 없이 `high_stakes`에서만 S3+ item offer 후보 폭 +1, missing growth 후보 노출 확률 보강. 자동 지급/고정 슬롯/자동 구매 아님 |
| S1 first clear bonus gold | Applied | settlement/run clear reward flow | 현재 유일하게 허용된 시스템 보너스 |
| runtime boss modifier cycle | Applied | `BlindSelectionSpecBuilder._bossModifierForStation` | S1~S8 순환 보스 제약 표시/전투 적용 |
| S1 onboarding target/severity | Applied | `BlindSelectionSpecBuilder._standardTargetScore` / `RummiBossModifier.redDampener` / `tools/sim/run_balance_sim.dart` | 출품용 S1 입구 안정화를 위해 S1 target을 240/264/265로 낮추고 `red_dampener_v1`을 35% 감소로 완화. sim S1 soft v2 target도 runtime과 맞춤 |
| boss constraint pool v4 / late boss 068 | Partially applied | `tools/sim/run_balance_sim.dart` / `RummiBossModifier` | sim 10종 pool 중 runtime은 색상/라인/face 약화 3계열 적용 |
| station band rarity/tag weight | Applied | `RummiStationBandMarketPolicy` | `shop_slot_market_v9` 해석을 런타임 마켓 weight로 반영 |
| missing growth market exposure | Applied | `RummiMarketFacade` / `RummiStationBandMarketPolicy` | 직접 지급 없이 랜덤 offer slot 후보 가중치만 조정 |
| S7~S8 shape correction floor | Applied | `RummiStationBandMarketPolicy._itemTagBonus` | final band `tile_color`/`draw`/순수 `rank` 후보 +80, `92c162b` 반영 |
| economy reward / price policy | Applied | `RummiEconomyConfig` / catalog JSON | 카탈로그 기준가 보정 후 정수 `11/5` effective price scale과 0.40 reward 번역 적용 |
| catalog value audit | Applied | `tools/sim/catalog_value_audit.py` | Item/Jester 가격과 effect role의 불일치 후보를 runtime effective price 기준으로 표시한다 |
| jester hook price adjustment | Applied | `data/common/items_common_v1.json` | `jester_hook` base 10G/effective 22G는 sell value +1 대비 과해 base 7G/effective 15G로 낮춤 |
| catalog audit v2 price probe | Workspace pending | `tools/sim/run_balance_sim.dart` / `tools/sim/economy_audit.py` | `catalog_audit_v2` sim-only price band 추가. r120에서는 조정 후보 구매 이벤트가 없어 normalized와 결과 동일. economy audit가 content/proxy/source candidate별 구매 count와 audit watchlist를 출력 |
| runtime offer audit | Workspace pending | `tools/sim/runtime_market_offer_audit.dart` | 실제 runtime offer r200에서 `reroll_token` 85회, `trade_ticket` 110회, `ride_the_bus` 68회, `jester_hook` 48회. 다음 판단 축은 노출 여부가 아니라 구매력/가격 대비 가치 |
| jester hook economy probe | Applied | `tools/sim/run_balance_sim.dart` | r400에서 balanced none 52.2%, balanced v9 57.5%, power none 60.8%, power v9 61.3%. `jester_hook` 가격 조정은 즉시 부작용 없음 |
| Pack/Tarot-like/Planet-like role mapping | Spec only | docs only | 현재는 Item/market candidate role로 해석. 별도 타입 런타임은 미도입 |
| smoke sweep after shape floor | Applied | `tools/sim/ml_sweep_dataset.py` | v87 r120 runtime parity smoke 완료 |
| r400 revalidation after shape floor | Applied | `tools/sim/ml_sweep_dataset.py` | v88 r400 runtime parity sweep 완료 |

## 2. Applied Runtime Details

### Target Score

Applied:

- S1~S8 `standard` target table은 blind 선택 런타임에 연결되어 있다.
- small < big < boss 압박 구조는 유지한다.
- S1은 출품용 프로토타입 기준으로 “거의 누구나 통과하는 입구” 역할을 우선해 240/264/265로 낮췄다.
- S8 이후는 디버그/테스트용 단조 증가 fallback으로만 본다.

Not applied:

- S1 boss target만 별도로 낮추는 방식은 적용하지 않는다.

### Boss Constraint

Applied:

- Boss blind에는 station별 runtime modifier가 붙는다.
- 색상 타일 약화처럼 특정 타일에 걸리는 제약은 타일 위에 표시한다.
- Boss 표시를 눌러 제약 팝업을 다시 확인할 수 있다.
- S1 `red_dampener_v1`은 40% 감소에서 35% 감소로 완화했다. S1 통과 안정성을 위한 severity 조정이며, 자동 자원 지급이나 무료 성장 보정은 아니다.
- 현재 구현된 제약 계열은 `tileColorWeaken`, `lineKindWeaken`, `faceTileWeaken`, `allScoreWeaken`, `firstConfirmWeaken`, `confirmCountWeaken`, `repeatHandRankWeaken`, `singleHandRankPressure`이다.

Partially applied:

- simulation boss pool의 10개 proxy는 현재 시뮬 기준표로 유지된다.
- 런타임은 아직 weighted pool 전체를 그대로 뽑지 않고, station modifier cycle을 사용한다.
- all score dampener, first confirm tax, confirm count tax, repeat rank, single rank는 runtime modifier 타입으로 승격했다.
- repeat rank, single rank는 modifier와 저장/복원은 구현됐지만 S1~S8 runtime boss cycle에는 아직 편입하지 않았다.
- target spike, resource squeeze는 아직 runtime modifier 타입으로 승격하지 않았다.

Not applied:

- S8 boss를 더 낮추는 `late_boss_070`류 완화는 현재 기준이 아니다.
- `resource +1`이 붙은 boss 완화 후보는 폐기 상태다.

Boss constraint runtime scope:

| Sim slot | Constraint | Runtime status | Reason |
|---:|---|---|---|
| 0 | `color_dampener_cycle` | Applied | `tileColorWeaken`으로 전투/저장/표시 적용 완료 |
| 1 | `line_kind_dampener_cycle` | Applied | `lineKindWeaken`으로 전투/저장/표시 적용 완료 |
| 2 | `face_tile_dampener` | Applied | S3 boss modifier. 11~13 타일 포함 라인을 35% 감소 |
| 3 | `repeat_rank_pressure_v4` | Implemented, not in cycle | 이전 confirm에서 나온 같은 족보를 다시 확정하면 20% 감소. `confirmedRanksThisStation` 저장/복원 |
| 4 | `single_rank_pressure` | Implemented, not in cycle | A안 기준 첫 confirm 족보를 다시 확정하면 30% 감소. 타일 배지 없이 보스 팝업/정산 penalty 표시 |
| 5 | `confirm_count_tax_v2` | Applied | 기존 `confirmCountThisStation`으로 세 번째 confirm부터 25% 감소 |
| 6 | `all_score_dampener` | Applied | 모든 점수 라인 20% 감소. 타일별 표시 없이 보스 팝업/정산 penalty로 표시 |
| 7 | `first_confirm_tax` | Applied | 첫 confirm 점수 라인 30% 감소. 기존 confirm ordinal로 판정 |
| 8 | `target_spike_wall` | Spec only | target score 조정 계열이므로 boss modifier와 별도 target 레버로 다뤄야 함 |
| 9 | `resource_squeeze` | Rejected for auto grant | 자원 지급이 아니라 시작 압박/마켓 후보 노출로만 해석 |

Boss constraint implementation checklist:

- [x] color dampener family: 타일 색상 포함 라인 약화
- [x] line kind dampener family: 가로/세로/대각선 라인 약화
- [x] face tile dampener: 11~13 포함 라인 약화
- [x] all score dampener: 모든 점수 라인 약화
- [x] first confirm tax: 첫 confirm 약화
- [x] confirm count tax: 세 번째 confirm부터 약화
- [x] repeat rank pressure: 이전 confirm rank 기록/저장/표시 정책 적용
- [x] single rank pressure: A안 기준 첫 confirm rank 저장/표시 정책 적용
- [ ] target spike wall: boss modifier가 아니라 target score table 레버로 별도 검증
- [x] resource squeeze: 자동 지급/보정 후보에서 제외

현재 제외:

- `repeat_rank_pressure_v4`, `single_rank_pressure`는 modifier 구현은 완료했지만, S1~S8 cycle 배치는 아직 하지 않는다.
- `target_spike_wall`은 boss modifier가 아니라 target table 레버로 둔다.
- `resource_squeeze`는 자동 자원 지급/보정으로 번역하지 않는다.

### Market Policy

Applied:

- `shop_slot_market_v9`는 직접 지급이 아니라 station band market weight로 번역되어 있다.
- Jester rarity weight는 stage tier에 따라 Common에서 Rare/Legendary 쪽으로 천천히 이동한다.
- Item rarity/tag weight는 early/mid/late band에 따라 다르게 적용된다.
- missing growth exposure는 필요한 후보군의 마켓 등장 확률만 올린다.
- 보정 slot 위치는 고정하지 않고 stage/reroll/rng에 따라 흔들린다.

Applied:

- S7~S8 final band에서 덱/타일 형상 보정 후보가 완전히 밀려나지 않도록 +80 floor를 추가했다.
- 이 변경은 slot 수, 직접 지급, 특정 위치 고정을 바꾸지 않는다.

## 3. Explicitly Rejected

| Candidate | Status | Reason |
|---|---|---|
| automatic resource +1 | Rejected | S1 첫 클리어 보너스 골드 외 공짜 지급 금지 |
| board discard/hand discard/max hand size 자동 증가 | Rejected | 성장 수요를 게임이 대신 해결함 |
| Jester/Item/Pack/Tarot-like/Planet-like 직접 지급 | Rejected | 구매/장착/사용 선택을 유저에게서 빼앗음 |
| fixed offer slot exposure | Rejected | scripted market처럼 보이고 선택 압박이 강해짐 |
| bot purchase result as player reward | Rejected | bot은 선택 proxy일 뿐 지급 근거가 아님 |
| S1 boss target-only nerf | Rejected | small/big/boss 압박 구조를 깨뜨림 |

## 4. Verification Status

최근 확인 완료:

- `flutter test test/logic/rummi_market_facade_test.dart`
- `flutter test test/logic/rummi_market_facade_test.dart test/services/blind_selection_setup_test.dart test/providers/game_session_notifier_test.dart`
- `git diff --check`

S7~S8 shape correction workspace probe:

| Stage | shape floor share | Notes |
|---:|---:|---|
| S6 | 10.3% | 기존 late band 기준 |
| S7 | 12.5% | final band +80 반영 |
| S8 | 12.5% | final band +80 반영 |

판정:

- 점수/boss 후보를 더 올린 변경이 아니다.
- 형상 보정 후보가 후반 마켓에서 조금 더 안정적으로 남는 수준이다.
- 장기 sweep 전이므로 기준 확정이 아니라 1차 적용 후보 상태다.

v87 smoke, pre-parity:

- command: `python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 120 --seed 87200 --bot planner_v2 --stations 1,2,3,4,5,6,7,8 --difficulty standard --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068 --loadout-ids progression_route_balanced,progression_route_power --market-profiles none,shop_slot_market_v9 --summary-only --jobs 4 --out-prefix logs/sim/ml_sweep_shape_floor_v87_smoke_r120`
- summary: `logs/sim/ml_sweep_shape_floor_v87_smoke_r120_summary.json`
- report: `logs/sim/ml_sweep_shape_floor_v87_smoke_r120_report.md`

| loadout | market | path clear | avg total turn | top bottlenecks | stop reason |
|---|---|---:|---:|---|---|
| balanced | none | 56.7% | 1384.5 | S4 boss 12, S5 boss 6, S8 boss 6, S1 boss 4 | board 23, draw 28, both 1 |
| balanced | v9 | 64.2% | 1395.0 | S8 boss 10, S3 boss 6, S4 boss 4, S1 big 3 | board 30, draw 12, both 1 |
| power | none | 60.8% | 1297.9 | S1 boss 7, S8 boss 7, S1 small 4, S3 boss 4 | board 33, draw 14 |
| power | v9 | 65.0% | 1308.0 | S8 boss 8, S7 boss 6, S1 big 5, S1 boss 5 | board 28, draw 13, both 1 |

해석:

- v9는 clear를 올리지만 S1/S7/S8 boss 병목을 지우지 않는다.
- avg total turn도 급격히 낮아지지 않는다.
- balanced 기준 draw exhausted는 줄지만 board pressure가 남는다.
- 이 smoke는 `shop_slot_market_v9` sim profile 기준이다. 현재 runtime +80 final band floor와 1:1 동일한 후보 weight 검증은 아니므로, 다음에는 sim/runtime parity를 맞추거나 runtime offer sampling을 별도로 기록해야 한다.

v87 runtime parity smoke:

- command: `python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 120 --seed 87200 --bot planner_v2 --stations 1,2,3,4,5,6,7,8 --difficulty standard --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068 --loadout-ids progression_route_balanced,progression_route_power --market-profiles none,shop_slot_market_v9 --summary-only --jobs 4 --out-prefix logs/sim/ml_sweep_shape_floor_v87_runtime_parity_r120`
- summary: `logs/sim/ml_sweep_shape_floor_v87_runtime_parity_r120_summary.json`
- report: `logs/sim/ml_sweep_shape_floor_v87_runtime_parity_r120_report.md`

| loadout | market | path clear | avg total turn | top bottlenecks | stop reason |
|---|---|---:|---:|---|---|
| balanced | none | 56.7% | 1384.5 | S4 boss 12, S5 boss 6, S8 boss 6, S1 boss 4 | board 23, draw 28, both 1 |
| balanced | v9 | 65.8% | 1396.9 | S8 boss 8, S3 boss 6, S4 boss 4, S1 big 3 | board 30, draw 10, both 1 |
| power | none | 60.8% | 1297.9 | S1 boss 7, S8 boss 7, S1 small 4, S3 boss 4 | board 33, draw 14 |
| power | v9 | 65.0% | 1310.2 | S8 boss 8, S7 boss 6, S1 big 5, S1 boss 5 | board 28, draw 13, both 1 |

Final band v9 slot exposure:

| Run | shape proxies | score breaker proxies | other |
|---|---:|---:|---:|
| pre-parity | 241 | 1787 | 2292 |
| runtime parity | 740 | 1619 | 1961 |

판정:

- sim profile도 runtime final band floor와 같은 방향으로 형상 보정 후보를 남긴다.
- score breaker 후보가 여전히 shape 후보보다 많으므로, 후반 점수 돌파 후보를 밀어낸 상태는 아니다.
- `balanced + v9` clear는 64.2%에서 65.8%로 소폭 상승했고, `power + v9`는 65.0%로 유지됐다.
- S1/S7/S8 boss 병목이 남아 있어 과보정으로 보지 않는다.

v88 runtime parity r400:

- command: `python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 400 --seed 88400 --bot planner_v2 --stations 1,2,3,4,5,6,7,8 --difficulty standard --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068 --loadout-ids progression_route_balanced,progression_route_power --market-profiles none,shop_slot_market_v9 --summary-only --jobs 4 --out-prefix logs/sim/ml_sweep_shape_floor_v88_runtime_parity_r400`
- summary: `logs/sim/ml_sweep_shape_floor_v88_runtime_parity_r400_summary.json`
- report: `logs/sim/ml_sweep_shape_floor_v88_runtime_parity_r400_report.md`

| loadout | market | path clear | avg total turn | top bottlenecks | stop reason |
|---|---|---:|---:|---|---|
| balanced | none | 50.5% | 1315.2 | S4 boss 26, S8 boss 21, S1 boss 19, S3 boss 13, S5 boss 13 | board 127, draw 69, both 2 |
| balanced | v9 | 64.8% | 1396.2 | S8 boss 21, S5 boss 18, S1 big 12, S1 boss 12, S5 big 10 | board 99, draw 42 |
| power | none | 61.3% | 1363.1 | S8 boss 28, S1 boss 16, S3 boss 15, S8 big 14, S7 boss 12 | board 102, draw 53 |
| power | v9 | 72.8% | 1360.4 | S8 boss 21, S1 boss 18, S1 big 12, S8 big 10, S2 big 5 | board 69, draw 37, both 3 |

Final band v9 slot exposure:

| Run | shape proxies | score breaker proxies | other |
|---|---:|---:|---:|
| v88 r400 | 2465 | 5601 | 6714 |

Key bottlenecks:

| loadout | market | S1 small | S1 big | S1 boss | S4 boss | S5 boss | S7 boss | S8 boss |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| balanced | none | 8 | 10 | 19 | 26 | 13 | 4 | 21 |
| balanced | v9 | 4 | 12 | 12 | 8 | 18 | 4 | 21 |
| power | none | 5 | 8 | 16 | 6 | 2 | 12 | 28 |
| power | v9 | 4 | 12 | 18 | 4 | 0 | 5 | 21 |

판정:

- v9는 r400에서도 board/draw stop을 줄이고 path clear를 올린다.
- S1/S8 boss 병목은 남아 있으므로 전체 경로를 무너뜨리는 과보정으로 보지 않는다.
- `power + v9`는 72.8%까지 올라가므로, 추가 강화는 보류한다.
- shape proxy는 2465회 노출됐지만 score breaker 5601회보다 낮아, 후반 점수 후보를 밀어낸 상태는 아니다.

v89 face boss runtime smoke:

- command: `python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 120 --seed 88900 --bot planner_v2 --stations 1,2,3,4,5,6,7,8 --difficulty standard --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068 --loadout-ids progression_route_balanced,progression_route_power --market-profiles none,shop_slot_market_v9 --summary-only --jobs 4 --out-prefix logs/sim/ml_sweep_face_boss_v89_smoke_r120`
- summary: `logs/sim/ml_sweep_face_boss_v89_smoke_r120_summary.json`
- report: `logs/sim/ml_sweep_face_boss_v89_smoke_r120_report.md`

| loadout | market | path clear | avg total turn | top bottlenecks | stop reason |
|---|---|---:|---:|---|---|
| balanced | none | 52.5% | 1374.5 | S4 boss 9, S8 boss 8, S1 boss 6, S5 boss 4 | board 35, draw 20, both 2 |
| balanced | v9 | 61.7% | 1371.3 | S8 boss 7, S1 boss 5, S5 boss 4, S7 boss 4 | board 31, draw 13, both 2 |
| power | none | 58.3% | 1281.9 | S8 boss 9, S1 boss 7, S2 boss 6, S7 boss 5 | board 33, draw 17 |
| power | v9 | 66.7% | 1282.5 | S1 boss 8, S8 boss 5, S1 small 4, S2 big 3 | board 31, draw 9 |

판정:

- S8 boss가 `faceDampener`였던 v89 기준에서도 S1/S8 boss 병목은 남았다.
- r120 기준에서 v9 clear가 balanced 61.7%, power 66.7%로 과하게 뛰지 않았다.
- `face_tile_dampener`는 S8에 넣어도 현재 target/market 기준을 무너뜨리지 않는 1차 후보로 본다.

v90 boss runtime phase 1 proxy smoke:

- command: `python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 120 --seed 89000 --bot planner_v2 --stations 1,2,3,4,5,6,7,8 --difficulty standard --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068 --loadout-ids progression_route_balanced,progression_route_power --market-profiles none,shop_slot_market_v9 --summary-only --jobs 4 --out-prefix logs/sim/ml_sweep_boss_runtime_v90_smoke_r120`
- summary: `logs/sim/ml_sweep_boss_runtime_v90_smoke_r120_summary.json`
- report: `logs/sim/ml_sweep_boss_runtime_v90_smoke_r120_report.md`
- note: 이 sweep은 Python sim의 boss proxy 기준이며, Dart runtime cycle 자체는 `blind_selection_setup_test.dart`로 검증한다.

Runtime S1~S8 boss cycle:

| Station | Modifier |
|---:|---|
| S1 | `red_dampener_v1` |
| S2 | `row_line_dampener_v1` |
| S3 | `face_tile_dampener_v1` |
| S4 | `column_line_dampener_v1` |
| S5 | `all_score_dampener_v1` |
| S6 | `diagonal_line_dampener_v1` |
| S7 | `first_confirm_tax_v1` |
| S8 | `confirm_count_tax_v2` |

| loadout | market | path clear | avg total turn | S1/S4/S5/S8 boss bottleneck | top bottlenecks | stop reason |
|---|---|---:|---:|---|---|---|
| balanced | none | 45.0% | 1331.1 | S1 5, S4 15, S5 7, S8 7 | S4 boss 15, S5 boss 7, S8 boss 7, S1 boss 5 | board 33, draw 32, both 1 |
| balanced | v9 | 57.5% | 1356.3 | S1 8, S4 3, S5 1, S8 9 | S8 boss 9, S1 boss 8, S8 big 6, S2 boss 5 | board 34, draw 17 |
| power | none | 59.2% | 1270.5 | S1 7, S4 1, S5 0, S8 9 | S8 boss 9, S1 boss 7, S3 boss 5, S2 big 4 | board 31, draw 18 |
| power | v9 | 68.3% | 1378.2 | S1 1, S4 2, S5 2, S8 9 | S8 boss 9, S8 big 4, S1 big 3, S7 boss 3 | board 25, draw 13 |

판정:

- 신규 cycle은 v89 대비 balanced clear를 낮춘다. 특히 `none` balanced가 52.5%에서 45.0%로 내려가므로, 이 배치를 그대로 확정하기 전에는 r120보다 큰 runs로 재검증해야 한다.
- `shop_slot_market_v9`는 여전히 clear를 올리지만 balanced v9도 57.5%라 과보정은 아니다.
- S8 boss 병목이 모든 조합에서 남는다. S8에 들어간 `confirm_count_tax_v2`는 보스 압박으로 읽히지만, 후반 병목을 키우는지 장기 sweep으로 확인해야 한다.
- 자동 자원 지급/보정은 추가하지 않는다. 다음 조정이 필요하면 boss severity나 S8 후보군 availability를 먼저 본다.

v90 boss runtime long sweep:

- command: `python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 800 --seed 90800 --bot planner_v2 --stations 1,2,3,4,5,6,7,8 --difficulty standard --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068 --loadout-ids progression_route_balanced,progression_route_power --market-profiles none,shop_slot_market_v9 --summary-only --jobs 4 --out-prefix logs/sim/ml_sweep_boss_runtime_v90_long_r800`
- summary: `logs/sim/ml_sweep_boss_runtime_v90_long_r800_summary.json`
- report: `logs/sim/ml_sweep_boss_runtime_v90_long_r800_report.md`
- note: r120 smoke에서 확인한 신규 boss runtime cycle을 기존 장기 sweep 기준인 r800으로 재검증했다.

| loadout | market | path clear | avg total turn | S1/S4/S5/S8 boss bottleneck | top bottlenecks | stop reason |
|---|---|---:|---:|---|---|---|
| balanced | none | 51.6% | 1353.3 | S1 32, S4 45, S5 34, S8 57 | S8 boss 57, S4 boss 45, S5 boss 34, S1 boss 32 | board 230, draw 155, both 2 |
| balanced | v9 | 65.4% | 1386.6 | S1 30, S4 26, S5 24, S8 38 | S8 boss 38, S1 boss 30, S4 boss 26, S5 boss 24 | board 196, draw 78, both 3 |
| power | none | 57.8% | 1348.2 | S1 45, S4 12, S5 2, S8 81 | S8 boss 81, S1 boss 45, S8 big 26, S7 boss 22 | board 203, draw 127, both 8 |
| power | v9 | 73.2% | 1349.1 | S1 33, S4 9, S5 1, S8 29 | S1 boss 33, S8 boss 29, S1 big 21, S8 big 19 | board 148, draw 63, both 3 |

판정:

- r120 smoke에서 낮아 보였던 `balanced + none` 45.0%는 r800에서 51.6%로 회복됐다.
- `shop_slot_market_v9`는 clear를 올리고 draw stop을 줄이지만, S1/S8 boss 병목은 지우지 않는다.
- `power + v9`가 73.2%까지 올라가므로 S7~S8 shape floor나 market weight 추가 강화는 보류한다.
- S8 `confirm_count_tax_v2`는 병목을 유지하지만, v9에서는 S8 boss stop이 balanced 38/800, power 29/800까지 내려가므로 즉시 완화할 hard wall로 보지 않는다.
- 자동 자원 지급/자동 보정은 여전히 근거가 없다. 필요 시 boss severity/cycle 위치 또는 S8 후보군 availability를 먼저 검토한다.

v91 출품용 S1 entry smoke:

- command: `python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 120 --seed 90515 --bot planner_v2 --stations 1,2,3,4,5,6,7,8 --difficulty standard --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068 --loadout-ids progression_route_balanced,progression_route_power --market-profiles none,shop_slot_market_v9 --summary-only --jobs 4 --out-prefix logs/sim/prototype_stability_v91_s1_easy_r120`
- summary: `logs/sim/prototype_stability_v91_s1_easy_r120_summary.json`
- S1 focused summary: `logs/sim/prototype_s1_easy_entry_v91_r240_summary.json`
- note: r120은 출품 안정성 확인용 smoke이며, 장기 확정 sweep이 아니다.

| loadout | market | path clear | avg total turn | top bottlenecks | stop reason |
|---|---|---:|---:|---|---|
| balanced | none | 45.0% | 1237.6 | S4 boss 10, S5 boss 7, S1 big 6, S1 boss 5, S8 boss 5 | board 46, draw 20 |
| balanced | v9 | 65.0% | 1380.5 | S1 boss 5, S2 boss 4, S8 boss 4, S1 small 3, S4 boss 3 | board 28, draw 12, both 2 |
| power | none | 63.3% | 1370.6 | S8 boss 9, S4 boss 4, S1 big 3, S8 big 3, S3 big 3 | board 33, draw 10, both 1 |
| power | v9 | 65.8% | 1270.2 | S1 boss 6, S8 boss 5, S3 boss 4, S8 big 4, S1 big 3 | board 33, draw 8 |

S1 focused r240:

| loadout | market | S1 path clear | stop reason |
|---|---|---:|---|
| balanced | none | 94.2% | board 13, draw 1 |
| balanced | v9 | 94.6% | board 11, draw 2 |
| power | none | 94.2% | board 13, draw 1 |
| power | v9 | 95.0% | board 11, draw 1 |

판정:

- S1 entry는 기존 90.8~92.9%에서 94.2~95.0%로 올라갔다.
- draw exhaustion은 거의 사라졌고, 남은 S1 실패는 board lock 중심이다.
- balanced+v9 전체 path clear는 61.7%에서 65.0%로 올라갔지만, S8 boss 병목은 남아 후반 압박을 지우지 않았다.
- 출품용 기준으로 S1 target/severity 조정은 유지한다. 장기 확정은 별도 r400/r800으로 재검증한다.

## 5. Next Leveling Work

다음 순서:

1. Economy leveling gate를 먼저 통과한다. 보상 골드와 item/Jester 가격대가 구매력 기준과 맞지 않으면 boss/market 장기 sweep이 왜곡된다.
2. S7~S8 shape floor는 현재 값으로 동결한다. 추가 강화하지 않는다.
3. 신규 boss modifier cycle은 r800 기준으로 1차 유지 가능하다. 다음 조정은 자동 보정이 아니라 boss severity/cycle 위치 또는 S8 market availability만 검토한다.
4. repeat/single rank 계열은 modifier와 저장/표시 정책이 구현됐으므로, S1~S8 cycle 편입 전 severity와 배치 위치를 별도 sweep으로 검증한다.
5. Pack/Tarot-like/Planet-like를 별도 타입으로 승격할지, 현재 Item/market role proxy로 유지할지 결정한다.

Economy leveling gate:

- plan: `docs/planning/ECONOMY_LEVELING_PLAN.md`
- tool: `tools/sim/economy_audit.py`
- current signal: v90 r800 summary 기준 평균 추정 cashout은 약 38G이고, common item/Jester 평균가는 약 4.3G라 정산 1회가 common 후보 8~9장 구매력이다.
- implication: 보상/가격을 보정하기 전에는 v90 이후 장기 sweep을 확정 판단에 쓰지 않는다.
- applied: runtime 저장 포맷을 바꾸지 않는 sim-only `trace_only` economy layer가 battle row와 sequence summary에 골드 수입, 알려진 구매비, cost-null 이벤트, 잔고 부족 이벤트를 기록한다.
- current trace: `economy_trace_v1_r20` 탐색 run에서 trace-only 평균 최종 잔고가 약 770G로 높게 나왔다. 기존 sim은 가격/잔고로 market effect를 제한하지 않는 상태다.
- applied: `gated_known_cost` sim economy mode를 추가했다. 이 모드는 cost를 알 수 없거나 잔고로 살 수 없는 market effect를 적용하지 않는다.
- current gated trace: `economy_gated_v1_r20` 탐색 run에서 cost-null 이벤트는 줄었지만 평균 최종 잔고는 약 676G로 여전히 높다.
- applied: `--sim-reward-scale`, `--sim-price-scale`을 추가했다. 기본값은 1.0이며 runtime 수치에는 영향이 없다.
- current scale probe: r20 탐색에서 `reward 0.45 / price 2.2` 혼합 후보가 단일 축 조정보다 path clear 균형이 덜 흔드는 1차 후보로 보인다.
- applied: economy audit이 station/tier별 시작 골드와 정산 후 골드 분포를 집계한다.
- current station signal: `reward 0.45 / price 2.2` r20에서도 S4 boss 시작 평균 약 117G, S8 boss 시작 평균 약 245G로 높다.
- r120 probe: `reward 0.45 / price 2.2`는 balanced v9 64.2%, power v9 64.2%이고, `reward 0.34 / price 1.0`은 balanced v9 63.3%, power v9 73.3%다.
- current conclusion: 단순 보상/가격 scale만으로는 경제 압박이 충분하지 않다. `gated_known_cost`에서도 잔고 부족 이벤트가 거의 없다.
- applied: `station_band_v1` market budget probe를 추가했다. 이 방식은 unaffordable event를 만들지만 알려진 spend를 줄여 중후반 잔고가 더 높아질 수 있다.
- applied: `reroll_slot_sell_v1` market spend mode를 추가했다. 이 방식은 reroll spend, 슬롯이 찬 상태의 판매 회수, Jester slot cap 유지 loadout을 sim-only로 반영한다.
- current spend probe: `economy_spend_v1_r20`에서 `reward 0.45 / price 2.2 / reroll_slot_sell_v1`은 reroll spend 5550G, sell recovery 352G, slot replace 352회를 기록했다. S8 boss 시작 평균은 약 180G로 내려갔지만 최종 잔고 평균은 약 154G라 아직 높다.
- r120 spend probe: `reward 0.34 / price 1.0`은 final gold avg 약 136.5G, `reward 0.45 / price 2.2`는 약 150.0G, `reward 0.40 / price 2.4`는 약 121.6G다.
- current conclusion: scale-only 조정은 부족하다. 잔고를 더 누르면 clear가 흔들리므로 rarity/category별 가격 band와 누락된 gold sink를 분리해 다음 probe를 잡는다.
- applied: `rarity_category_v1`, `rarity_category_soft_v1` sim-only price band mode를 추가했다.
- price band probe: hard band r20은 balanced v9 45.0%, power v9 50.0%로 너무 강하고, soft band r20은 final gold avg 약 158.5G로 잔고 압박이 약하다.
- current conclusion: 가격 band 단독 조정은 장기 후보에서 제외한다. 다음은 구매 후보 utility/cost 선택, reroll 빈도, 판매 회수율 모델을 더 현실화한다.
- applied: `affordable_alternative_v1` sim-only market choice mode를 추가했다. shop slot에서 비싼 1순위 대신 구매 가능한 대안을 고르는 proxy다.
- current affordable choice probe: `reward 0.40 / price 2.4 / reroll_slot_sell_v1 / affordable_alternative_v1` r120은 balanced none 52.5%, balanced v9 70.0%, power none 63.3%, power v9 67.5%다.
- current economy signal: 전체 S8 boss 시작 평균 약 142.1G와 final gold avg 약 121.7G는 none/v9가 섞인 값이라 market별 분리 해석이 필요하다.
- narrowed probe: `reward 0.38 / price 2.4 / reroll_slot_sell_v1 / affordable_alternative_v1` r120은 balanced none 54.2%, balanced v9 65.0%, power none 63.3%, power v9 67.5%, S8 boss 시작 평균 약 138.6G, final gold avg 약 116.1G다.
- audit correction: 전체 final gold avg는 none control의 미사용 골드가 크게 섞인다. `reward 0.40 / price 2.4`에서 final gold는 none 약 226.1G, v9 약 17.3G이고, S8 boss 시작 골드는 none 약 279.5G, v9 약 22.5G다.
- current candidate: `reward 0.40 / price 2.4`를 다시 우선한다. `reward 0.38 / price 2.4`는 v9 잔고를 거의 낮추지 못하면서 balanced v9 clear를 70.0%에서 65.0%로 낮춘다.
- long check: `reward 0.40 / price 2.4 / reroll_slot_sell_v1 / affordable_alternative_v1` r800은 balanced none 57.5%, balanced v9 65.8%, power none 62.3%, power v9 68.1%다. v9 final gold avg는 약 18.0G, v9 S8 boss 시작 골드는 약 22.8G다.
- current conclusion: economy sim 후보는 `reward 0.40 / price 2.4`로 유지한다. runtime 적용은 별도 승인 후 진행한다.
- tool update: `tools/sim/economy_audit.py`가 `catalog_value_flags`를 출력한다.
- current price flags: `reroll_token`, `coin_cache`, `thin_wallet`은 자기 회수형 item 후보이며, `green_jester`, `popcorn`, `ice_cream`, `supernova`는 low-price growth Jester 후보로 먼저 검토한다.
- applied: `catalog_value_flags_v1` sim-only price band를 추가했다. price flag 후보 일부만 올리는 검증용이다.
- catalog flag probe: `reward 0.38 / price 2.4 / catalog_value_flags_v1` r120은 balanced v9가 59.2%로 낮아지고 final gold avg는 114.9G에 그쳐, 현재 장기 후보에서는 제외한다.
- applied: `catalog_normalized_v1` sim-only price band를 추가했다. 카탈로그 기준가 후보는 `reroll_token` 5G, `coin_cache` 4G, `thin_wallet` 7G, `green_jester` 8G, `popcorn` 6G, `ice_cream` 7G, `banner` 7G, `gros_michel` 7G, `supernova` 8G다.
- catalog-first probe: `reward 0.40 / price 1.0 / catalog_normalized_v1` r120은 balanced v9 67.5%, power v9 70.8%였지만 v9 final gold avg가 약 129.6G, v9 S8 boss 시작 골드가 약 155.3G라 카탈로그 정리만으로는 골드 압박이 부족했다.
- catalog + scale probe: `reward 0.40 / price 2.4 / catalog_normalized_v1` r120은 v9 final gold avg 약 17.2G로 낮지만 power v9 59.2%가 none 65.0%보다 낮아 “떠도 못 사는 상점” 위험이 있다.
- selected runtime translation: `reward 0.40 / price 2.2 / catalog_normalized_v1` r120은 balanced none 54.2%, balanced v9 63.3%, power none 63.3%, power v9 66.7%다. v9 final gold avg는 약 18.7G, v9 S8 boss 시작 골드는 약 23.7G다.
- runtime applied: 보상 상수는 `stageClearGoldBase` 4G, S1 첫 클리어 보너스 2G, 남은 board discard 2G, 남은 hand discard 1G로 낮췄다. 구매 가격은 `RummiEconomyConfig.scaledMarketPrice`에서 정수 `11/5` 비율로 반올림한다. 표시/구매 가격은 모두 정수 G다.
- runtime catalog applied: 자기 회수형/저가 성장 후보의 기준가를 정수로 보정했다. `reroll_token` 5G, `coin_cache` 4G, `thin_wallet` 7G, `green_jester` 8G, `popcorn` 6G, `ice_cream` 7G, `banner` 7G, `gros_michel` 7G, `supernova` 8G.
- updated audit: 새 런타임 기준 reward envelope는 S1 small 자원 미사용 16G, 자원 전부 사용 6G다. runtime effective price 기준 자기 회수 flag는 남지 않는다.
- v91 runtime economy long sweep: `reward 0.40 / price 2.2 / catalog_normalized_v1 / reroll_slot_sell_v1 / affordable_alternative_v1` r800을 실행했다.
- command: `python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 800 --seed 99800 --bot planner_v2 --stations 1,2,3,4,5,6,7,8 --difficulty standard --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068 --loadout-ids progression_route_balanced,progression_route_power --market-profiles none,shop_slot_market_v9 --sim-economy-mode gated_known_cost --sim-reward-scale 0.40 --sim-price-scale 2.2 --sim-market-spend-mode reroll_slot_sell_v1 --sim-market-choice-mode affordable_alternative_v1 --sim-price-band-mode catalog_normalized_v1 --jobs 4 --out-prefix logs/sim/economy_runtime_v91_long_r800`
- summary: `logs/sim/economy_runtime_v91_long_r800_summary.json`
- report: `logs/sim/economy_runtime_v91_long_r800_report.md`
- audit: `logs/sim/economy_runtime_v91_long_r800_economy_audit.json`

| loadout | market | path clear | avg total turn | S1/S4/S5/S8 boss bottleneck | top bottlenecks | stop reason |
|---|---|---:|---:|---|---|---|
| balanced | none | 55.9% | 1390.7 | S1 25, S4 41, S5 26, S8 51 | S8 boss 51, S4 boss 41, S5 boss 26, S1 boss 25 | board 214, draw 136, both 3 |
| balanced | v9 | 57.0% | 1389.9 | S1 20, S4 45, S5 36, S8 49 | S8 boss 49, S4 boss 45, S5 boss 36, S1 boss 20 | board 196, draw 141, both 7 |
| power | none | 63.6% | 1353.2 | S1 35, S4 7, S5 4, S8 50 | S8 boss 50, S1 boss 35, S7 boss 28, S8 big 13 | board 205, draw 82, both 4 |
| power | v9 | 64.4% | 1358.5 | S1 35, S4 10, S5 6, S8 42 | S8 boss 42, S1 boss 35, S8 big 26, S7 boss 24 | board 190, draw 92, both 3 |

경제 audit:

- v9 final gold avg는 balanced 6.23G, power 6.42G다. none control은 각각 54.6G, 60.51G로 남는다.
- v9 S8 boss 시작 골드는 평균 9.4G, S8 boss 이후는 7.28G다.
- 전체 sim economy final gold avg는 31.94G이며, 이는 none control 미사용 골드가 섞인 값이다.
- unaffordable event는 15395회로, 이전 scale-only 후보와 달리 “떠도 바로 다 사는 상점” 상태는 아니다.

판정:

- 새 런타임 경제는 골드 과잉을 크게 낮춘다. 특히 v9 평균 최종 잔고가 한 자리수 G로 내려와 상점 선택/리롤 비용 압박이 생겼다.
- v9 clear 상승폭은 balanced +1.1%p, power +0.8%p로 작다. 기존 v90 장기 sweep의 v9 상승폭보다 훨씬 낮아졌으므로, 경제 압박이 market profile 효과를 강하게 누르고 있다.
- balanced v9 57.0%는 낮은 편이다. 자동 지급이나 슬롯 고정 보정으로 풀지 말고, 다음 조정은 S8 후보군 availability 또는 boss severity/cycle 위치 쪽에서 검토한다.
- S8 `confirm_count_tax_v2` 병목은 모든 조합에서 여전히 최상위다. 다만 v9에서 S8 boss stop이 balanced 49/800, power 42/800으로 남는 수준이라 즉시 완화보다 후속 후보군 availability probe가 먼저다.
- board locked가 draw exhausted보다 많다. 자원 +1 지급으로 풀지 않고, board/move/discard 후보의 마켓 등장성 및 가격 접근성을 다음 probe 후보로 본다.
- v91 market availability probe: `shop_slot_market_v10`~`shop_slot_market_v13`을 같은 economy 조건에서 r120 탐색 비교했다.
- command: `python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 120 --seed 99920 --bot planner_v2 --stations 1,2,3,4,5,6,7,8 --difficulty standard --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068 --loadout-ids progression_route_balanced,progression_route_power --market-profiles none,shop_slot_market_v9,shop_slot_market_v10,shop_slot_market_v11,shop_slot_market_v12,shop_slot_market_v13 --sim-economy-mode gated_known_cost --sim-reward-scale 0.40 --sim-price-scale 2.2 --sim-market-spend-mode reroll_slot_sell_v1 --sim-market-choice-mode affordable_alternative_v1 --sim-price-band-mode catalog_normalized_v1 --summary-only --jobs 4 --out-prefix logs/sim/economy_runtime_v91_market_probe_r120`

| market | balanced clear | power clear | 1차 해석 |
|---|---:|---:|---|
| none | 52.5% | 63.3% | control |
| v9 | 63.3% | 65.8% | 기존 후보. clear 상승, 압박 유지 |
| v10 | 49.2% | 61.7% | balanced가 none보다 낮아 폐기 후보 |
| v11 | 64.2% | 63.3% | balanced는 좋지만 power 개선 없음 |
| v12 | 55.0% | 55.8% | power가 크게 낮아 폐기 후보 |
| v13 | 65.8% | 65.8% | 좋아 보이나 seed 안정성 확인 필요 |

- v13 raw check: 같은 economy 조건에서 `none,v9,v13`만 JSONL 포함 r120으로 재검사했다.
- command: `python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 120 --seed 99980 --bot planner_v2 --stations 1,2,3,4,5,6,7,8 --difficulty standard --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068 --loadout-ids progression_route_balanced,progression_route_power --market-profiles none,shop_slot_market_v9,shop_slot_market_v13 --sim-economy-mode gated_known_cost --sim-reward-scale 0.40 --sim-price-scale 2.2 --sim-market-spend-mode reroll_slot_sell_v1 --sim-market-choice-mode affordable_alternative_v1 --sim-price-band-mode catalog_normalized_v1 --jobs 4 --out-prefix logs/sim/economy_runtime_v91_market_probe_raw_r120`
- raw check result: balanced none 56.7%, balanced v9 59.2%, balanced v13 51.7%, power none 65.8%, power v9 65.8%, power v13 60.0%.
- raw audit: v9 final gold avg 6.51G, v13 final gold avg 6.45G로 경제 압박은 비슷하다. v13이 더 낮은 clear를 보인 이유는 잔고 완화가 아니라 후보/선택 proxy 안정성 문제로 본다.
- 판정: 어느 정도 압박은 필요하지만, 이상적인 플레이 proxy가 none보다 낮아지면 안 된다. v13은 seed에 따라 none보다 낮아지는 케이스가 있어 적용하지 않는다. 현재는 v9를 유지하고, 다음 조정은 “압박 제거”가 아니라 “좋은 선택을 했을 때 통과 가능성 확보” 기준으로 별도 후보를 설계한다.

Run modifier probe:

- runtime applied: `high_stakes`는 Insight 20 해금 후 선택 가능한 명시적 run modifier다. 현재 target score 1.04, blind reward 1.12를 적용하며 직접 골드/아이템/Jester/자원을 지급하지 않는다.
- tool update: `tools/sim/run_balance_sim.dart`와 `tools/sim/ml_sweep_dataset.py`가 `--run-modifier basic|high_stakes`를 받는다. sim economy reward scale은 입력 scale에 modifier reward multiplier를 곱한 effective scale로 기록한다.
- r120 proxy note: 전용 CLI 추가 전 `target 1.08 / reward 0.448` 조합으로 current economy 조건의 탐색 probe를 돌렸지만, seed 흔들림이 커서 tuning 근거로 쓰지 않는다.
- current signal: high stakes는 balanced none/v9를 크게 누르고, power 계열은 어느 정도 유지한다. 장기 판단 전에는 반드시 `--run-modifier high_stakes` direct sweep으로 다시 비교한다.
- next check: basic/high_stakes를 같은 economy 조건에서 r400 이상으로 비교하고, 좋은 market 선택 proxy가 같은 modifier의 none/control보다 낮아지는지 먼저 본다.
- direct r400 check:
  - basic command: `python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 400 --seed 90300 --bot planner_v2 --stations 1,2,3,4,5,6,7,8 --difficulty standard --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068 --loadout-ids progression_route_balanced,progression_route_power --market-profiles none,shop_slot_market_v9 --sim-economy-mode gated_known_cost --sim-reward-scale 0.40 --sim-price-scale 2.2 --sim-market-spend-mode reroll_slot_sell_v1 --sim-market-choice-mode affordable_alternative_v1 --sim-price-band-mode catalog_normalized_v1 --run-modifier basic --summary-only --jobs 4 --out-prefix logs/sim/run_modifier_basic_direct_r400`
  - high stakes command: same options with `--run-modifier high_stakes --out-prefix logs/sim/run_modifier_high_stakes_direct_r400`

| modifier | loadout | market | path clear | avg total turn | top bottlenecks | stop reason |
|---|---|---|---:|---:|---|---|
| basic | balanced | none | 54.5% | 1314.7 | S4 boss 19, S8 boss 18, S3 boss 16, S1 big 14, S1 boss 14 | board 120, draw 60, both 2 |
| basic | balanced | v9 | 56.8% | 1386.2 | S8 boss 25, S5 boss 13, S4 boss 13, S3 big 12, S4 big 11 | board 110, draw 62, both 1 |
| basic | power | none | 65.8% | 1366.4 | S8 boss 26, S1 boss 12, S8 big 11, S2 boss 11, S1 small 8 | board 92, draw 44, both 1 |
| basic | power | v9 | 63.2% | 1364.5 | S8 boss 28, S8 big 15, S1 big 15, S1 boss 13, S7 boss 12 | board 100, draw 44, both 3 |
| high_stakes | balanced | none | 41.8% | 1250.6 | S4 boss 28, S8 boss 25, S1 boss 23, S5 boss 19, S3 boss 19 | board 117, draw 113, both 3 |
| high_stakes | balanced | v9 | 42.0% | 1335.7 | S8 boss 39, S4 boss 31, S5 boss 18, S1 boss 15, S4 big 14 | board 116, draw 115, both 1 |
| high_stakes | power | none | 56.2% | 1376.2 | S8 boss 37, S1 boss 17, S8 big 16, S7 boss 12, S1 big 11 | board 99, draw 75, both 1 |
| high_stakes | power | v9 | 52.5% | 1379.4 | S8 boss 50, S1 boss 19, S1 big 17, S8 big 16, S7 boss 15 | board 100, draw 86, both 4 |

판정:

- `high_stakes`는 확실히 압박을 만든다. 다만 v9가 같은 modifier의 none/control보다 안정적으로 좋아지는지 아직 확인되지 않았다.
- basic power v9도 이 seed에서는 none보다 낮아졌다. v91 r800에서는 power v9가 none보다 높았으므로 r400 단일 seed만으로 market 정책을 되돌리지 않는다.
- `high_stakes` target 1.08 / reward 1.12는 그대로 확정하지 않는다. 다음은 r800 direct sweep 또는 `target 1.04~1.08 / reward 1.12~1.20` 후보 비교로 확인한다.
- 조정이 필요해도 자동 자원 지급/고정 슬롯/직접 아이템 지급은 쓰지 않는다. modifier target/reward 또는 market availability만 검토한다.

Run modifier candidate probe:

- purpose: `high_stakes` 압박이 너무 강한지 보기 위해 런타임을 바꾸지 않고 sim-only target override와 reward scale proxy로 후보를 비교했다.
- note: 아래 값은 확정용 r800이 아니라 탐색용이다. `run_modifier`는 `basic`으로 두고 target override를 걸었으므로 실제 runtime modifier 적용값과 1:1 동일한 장기 근거가 아니다.
- r120 same-seed probe:

| proxy | balanced none | balanced v9 | power none | power v9 | 1차 해석 |
|---|---:|---:|---:|---:|---|
| target 1.02 / reward 1.12 | 49.2% | 63.3% | 55.0% | 60.8% | r120에서는 v9가 none보다 높음 |
| target 1.04 / reward 1.12 | 44.2% | 60.0% | 50.8% | 57.5% | r120에서는 가장 안정적으로 보였음 |
| target 1.06 / reward 1.16 | 38.3% | 57.5% | 49.2% | 51.7% | 압박이 강하고 power 개선폭이 작음 |
| target 1.08 / reward 1.12 | 35.0% | 55.0% | 45.8% | 50.0% | 현재값 proxy. absolute clear가 낮음 |
| target 1.08 / reward 1.20 | 35.0% | 52.5% | 45.8% | 48.3% | reward만 올려도 target 압박을 충분히 보완하지 못함 |

- r400 follow-up:

| proxy | balanced none | balanced v9 | power none | power v9 | 1차 해석 |
|---|---:|---:|---:|---:|---|
| target 1.02 / reward 1.12 | 57.5% | 53.2% | 57.2% | 64.8% | balanced v9가 none보다 낮아 적용 보류 |
| target 1.04 / reward 1.12 | 55.5% | 49.5% | 53.5% | 63.7% | balanced v9가 none보다 낮아 적용 보류 |

판정:

- target multiplier를 1.02~1.04까지 낮춰도 seed에 따라 balanced v9가 none/control보다 낮아진다.
- 이 시점에서는 seed 흔들림 때문에 `high_stakes` runtime 값을 `target 1.04`나 `target 1.02`로 바로 바꾸지 않았다.
- 다음 후보는 단순 target/reward 배율보다, high pressure 조건에서 좋은 선택 proxy가 실제로 구매 가능한 후보군을 만나는지 보는 market availability under pressure probe다.
- 이 probe도 직접 지급, 고정 슬롯, 자동 구매가 아니라 candidate availability/weight와 가격 접근성만 다룬다.

Market availability under pressure probe:

- purpose: 같은 `target 1.04 / reward 1.12` proxy에서 기존 market 변형이 high pressure 조건을 더 잘 받치는지 확인했다.
- r120 probe: `none,v9,v10,v11,v12,v13` 비교에서 v9가 balanced 62.5%, power 60.8%로 가장 좋아 보였고, v10은 balanced 55.0%, power 60.8%였다.
- r400 follow-up:

| market | balanced clear | power clear | avg total turn signal | 1차 해석 |
|---|---:|---:|---|---|
| none | 51.7% | 56.0% | balanced 1399.8, power 1332.2 | control |
| v9 | 51.2% | 62.0% | balanced 1358.8, power 1384.2 | power는 개선되지만 balanced가 none보다 낮음 |
| v10 | 54.2% | 65.8% | balanced 1401.6, power 1414.6 | high pressure 조건에서는 가장 안정적인 탐색 후보 |

판정:

- high pressure에서는 단순 target/reward 조정보다 market availability가 더 큰 변수다.
- v10은 직접 지급이 아니라 missing growth 후보의 마켓 노출 확률과 slot 후보 수를 조정하는 sim-only profile이다.
- 다음 구현 후보는 `high_stakes`에서 기존 런타임 market policy를 숨은 자동 보정으로 바꾸는 것이 아니라, 명시적 run modifier에 묶인 market availability profile을 설계하는 것이다.
- 실제 적용 전에는 `basic` market 기준을 흔들지 않는 구조와 save/runtime 전달 경로를 먼저 검토한다.
- runtime applied: 저장 포맷은 바꾸지 않고 `high_stakes` 선택 상태에서 transient `RummiMarketPressureProfile.highStakes`를 파생한다. `basic`은 기존 market policy를 그대로 쓰며, `high_stakes`는 S3 이후 item offer 후보 폭을 +1 하고 missing growth item/Jester 후보 노출 확률만 보강한다.
- post-apply risk check: 현재 runtime target에 가까운 `target 1.08 / reward 1.12` proxy에서 v10 r120은 balanced none 42.5%, balanced v10 42.5%, power none 45.0%, power v10 61.7%다. market pressure profile은 power 쪽을 확실히 받치지만 balanced에는 아직 충분하지 않으므로, 다음 조정 후보는 `high_stakes` target multiplier 자체를 낮추는 장기 sweep이다.
- sim parity applied: `tools/sim/run_balance_sim.dart`도 `--run-modifier high_stakes`와 `shop_slot_market_v9`가 함께 쓰이면 runtime high stakes market pressure에 해당하는 missing growth/slot pressure를 반영한다.
- parity r120 check: sim parity 이후 direct `high_stakes + v9` r120은 balanced none 40.8%, balanced v9 42.5%, power none 56.7%, power v9 55.8%다. effective target 1.04/1.02 probe에서도 balanced v9가 none보다 낮은 seed가 남았다. 따라서 target multiplier 변경은 아직 적용하지 않고, 다음은 multi-seed 또는 r400 이상으로 balanced route의 v9 역전 원인을 확인한다.
- parity r400 check: sim parity 이후 direct `high_stakes + v9` r400은 balanced none 41.8%, balanced v9 46.2%, power none 54.0%, power v9 55.5%다. v9는 같은 modifier의 none/control보다 높아졌지만, balanced v9 absolute clear 46.2%는 낮다.
- effective target 1.04 r400 check: 런타임 변경 없이 `--run-modifier high_stakes`에 target override `1.04 / 1.08`을 곱한 r400은 balanced none 48.2%, balanced v9 54.0%, power none 55.8%, power v9 59.0%다.
- bottleneck signal: effective target 1.04 r400에서도 S8 boss는 balanced v9 32회, power v9 30회로 남고, stop reason은 board/draw가 모두 남는다. 압박은 제거되지 않았다.
- current candidate: `high_stakes` target multiplier를 1.08에서 effective 1.04로 낮추는 방향은 다음 r800 후보로 올린다. 단, 아직 runtime 값은 바꾸지 않는다. 적용 판단은 multi-seed 또는 r800에서 `balanced v9 >= balanced none`, `power v9 >= power none`, absolute clear와 S8 bottleneck이 동시에 허용 범위인지 확인한 뒤 한다.
- effective target 1.04 r800 check:
  - command summary: `dart run tools/sim/run_balance_sim.dart --runs 800 --bot planner_v2 --seed 91380 --sequence-mode station_path --stations 1,2,3,4,5,6,7,8 --blind-tiers small,big,boss --difficulty standard --experiment-id base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068 --market-profiles none,shop_slot_market_v9 --loadout-id progression_route_balanced --loadout-id progression_route_power --sim-economy-mode gated_known_cost --sim-reward-scale 0.40 --sim-price-scale 2.2 --sim-market-spend-mode reroll_slot_sell_v1 --sim-market-choice-mode affordable_alternative_v1 --sim-price-band-mode catalog_normalized_v1 --run-modifier high_stakes --out logs/sim/run_modifier_high_stakes_market_pressure_effective_t104_r800.jsonl --summary-out logs/sim/run_modifier_high_stakes_market_pressure_effective_t104_r800_summary.json`
  - target override: S1~S8의 small/big/boss 전체에 `--target-multiplier ...:0.962962962962963`을 적용해 `high_stakes` effective target을 1.04로 맞췄다.
  - result: balanced none 48.8%, balanced v9 54.1%, power none 57.8%, power v9 61.3%.
  - bottleneck signal: S8 boss는 balanced v9 56회, power v9 55회로 남고, stop reason도 board/draw 양쪽이 모두 남는다.
  - judgement: `high_stakes` effective target 1.04는 r800에서 좋은 market 선택 proxy가 none/control보다 낮아지는 문제를 해소하면서 압박을 유지한다. 목표는 `basic`급 clear rate가 아니라, 고레벨 보스다운 어려움과 통과 가능성을 같이 유지하는 것이다. 다음 후보는 runtime `high_stakes` target multiplier를 1.08에서 1.04로 낮추는 적용이다. reward 1.12와 market pressure profile은 유지하고, 자동 지급/고정 슬롯/자동 구매는 추가하지 않는다.
- runtime applied: r800 결과를 기준으로 `NewRunModifier.highStakes.targetScoreMultiplier`를 1.08에서 1.04로 낮췄다. reward 1.12와 market pressure profile은 유지한다.
- station curve audit: 같은 r800 JSONL을 도달 전투 대비 실패율로 보면 `high_stakes + v9`는 balanced 기준 S1 3.4%, S2 1.2%, S3 1.5%, S4 3.5%, S5 3.0%, S6 0.7%, S7 0.8%, S8 5.8%다. power 기준은 S1 3.3%, S2 1.0%, S3 1.4%, S4 1.4%, S5 0.3%, S6 0.9%, S7 2.2%, S8 5.3%다.
- curve judgement: 실패 총량이 아니라 실패율로 보면 S8이 가장 어렵고, S2/S3/S6은 쉬운 구간으로 남아 있다. 다만 “초반은 쉽고 갈수록 어려워진다” 기준에서는 S1 3%대가 약간 높을 수 있으므로, 다음 검토는 S1 target 단독 하향이 아니라 S1 boss constraint severity/초반 curve 체감/early market 접근성을 같이 본다.
- next guardrail: S1을 완화하더라도 `small < big < boss` 구조를 깨거나 자동 자원 지급으로 풀지 않는다. 고레벨 계약의 최종 압박은 S8에 남기는 방향을 유지한다.
- growth gate probe r120:
  - command: `dart run tools/sim/run_balance_sim.dart --runs 120 --bot planner_v2 --seed 91420 --sequence-mode station_path --stations 1,2,3,4,5,6,7,8 --blind-tiers small,big,boss --difficulty standard --experiment-id base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068 --market-profiles none,shop_slot_market_v9 --loadout-id baseline --loadout-id progression_route_balanced --loadout-id progression_route_power --sim-economy-mode gated_known_cost --sim-reward-scale 0.40 --sim-price-scale 2.2 --sim-market-spend-mode reroll_slot_sell_v1 --sim-market-choice-mode affordable_alternative_v1 --sim-price-band-mode catalog_normalized_v1 --run-modifier basic --out logs/sim/station_curve_growth_gate_probe_r120.jsonl --summary-out logs/sim/station_curve_growth_gate_probe_r120_summary.json`
  - baseline/no-growth result: path clear 0.0%. 도달 전투 실패율은 `baseline + none` 기준 S1 7.4%, S2 49.4%, S3 83.3%이며, `baseline + v9` 기준 S1 10.6%, S2 37.9%, S3 66.7%다. 무성장은 S2에서 간신히 버티고 S3부터 확실히 막히는 목표와 대체로 맞다.
  - growth route result: `balanced + v9` path clear 55.0%, `power + v9` 64.2%다. 도달 전투 실패율은 `balanced + v9` 기준 S4 4.2%, S5 3.0%, S8 6.0%이고, `power + v9` 기준 S7 2.8%, S8 4.3%다.
  - curve issue: 현재 숨은 문제는 S1만이 아니라, 성장 route에서 S4~S8 특히 S7/S8의 실패율이 고난도 후반으로 보기엔 낮은 점이다. 다음 조정은 S1 입구를 과하게 어렵게 두지 않으면서, S4~S8 target/boss severity/market pressure를 단계적으로 올리는 방향으로 잡는다.

## 6. Read Order

레벨링 작업 재개 시 순서:

1. `docs/current_system/CURRENT_LEVELING_POLICY.md`
2. `docs/current_system/CURRENT_LEVELING_RUNTIME_SPEC.md`
3. `docs/current_system/CURRENT_LEVELING_ML_BASELINE.md`
4. `docs/planning/LEVELING_APPLIED_STATUS.md`
5. `docs/planning/ECONOMY_LEVELING_PLAN.md`
6. 필요한 경우에만 `docs/archive/leveling/ML_LEVELING_SIMULATION_DIRECTION_HISTORY.md`
