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
| S1 first clear bonus gold | Applied | settlement/run clear reward flow | 현재 유일하게 허용된 시스템 보너스 |
| runtime boss modifier cycle | Applied | `BlindSelectionSpecBuilder._bossModifierForStation` | S1~S8 순환 보스 제약 표시/전투 적용 |
| boss constraint pool v4 / late boss 068 | Partially applied | `tools/sim/run_balance_sim.dart` / `RummiBossModifier` | sim 10종 pool 중 runtime은 색상/라인/face 약화 3계열 적용 |
| station band rarity/tag weight | Applied | `RummiStationBandMarketPolicy` | `shop_slot_market_v9` 해석을 런타임 마켓 weight로 반영 |
| missing growth market exposure | Applied | `RummiMarketFacade` / `RummiStationBandMarketPolicy` | 직접 지급 없이 랜덤 offer slot 후보 가중치만 조정 |
| S7~S8 shape correction floor | Applied | `RummiStationBandMarketPolicy._itemTagBonus` | final band `tile_color`/`draw`/순수 `rank` 후보 +80, `92c162b` 반영 |
| Pack/Tarot-like/Planet-like role mapping | Spec only | docs only | 현재는 Item/market candidate role로 해석. 별도 타입 런타임은 미도입 |
| smoke sweep after shape floor | Applied | `tools/sim/ml_sweep_dataset.py` | v87 r120 runtime parity smoke 완료 |
| r400 revalidation after shape floor | Applied | `tools/sim/ml_sweep_dataset.py` | v88 r400 runtime parity sweep 완료 |

## 2. Applied Runtime Details

### Target Score

Applied:

- S1~S8 `standard` target table은 blind 선택 런타임에 연결되어 있다.
- small < big < boss 압박 구조는 유지한다.
- S8 이후는 디버그/테스트용 단조 증가 fallback으로만 본다.

Not applied:

- S1 boss target만 별도로 낮추는 방식은 적용하지 않는다.

### Boss Constraint

Applied:

- Boss blind에는 station별 runtime modifier가 붙는다.
- 색상 타일 약화처럼 특정 타일에 걸리는 제약은 타일 위에 표시한다.
- Boss 표시를 눌러 제약 팝업을 다시 확인할 수 있다.
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

## 6. Read Order

레벨링 작업 재개 시 순서:

1. `docs/current_system/CURRENT_LEVELING_POLICY.md`
2. `docs/current_system/CURRENT_LEVELING_RUNTIME_SPEC.md`
3. `docs/current_system/CURRENT_LEVELING_ML_BASELINE.md`
4. `docs/planning/LEVELING_APPLIED_STATUS.md`
5. `docs/planning/ECONOMY_LEVELING_PLAN.md`
6. 필요한 경우에만 `docs/archive/leveling/ML_LEVELING_SIMULATION_DIRECTION_HISTORY.md`
