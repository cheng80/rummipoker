# Temporary Work Sequence Plan

> 문서 성격: temporary execution lock
> 생성 이유: boss pool 확장, 레벨링/경제 재검증, ML 재학습 순서를 섞지 않기 위해 현재 작업 큐를 고정한다.
> 삭제 조건: boss pool 확장, 확장 후 레벨링/경제 gate, ML 재학습/리포트, 공모전 QA 재개 여부가 source-of-truth에 반영된 뒤에도 바로 삭제하지 않는다. 사람 검토 승인을 받은 뒤에만 삭제한다.

## 0. 고정 순서

이 문서가 남아 있는 동안 아래 순서를 바꾸지 않는다.

1. 완료된 선행 정리 상태 유지
2. Boss pool mapping
3. Boss pool 1차 확장
4. 확장 boss pool 기준 레벨링 재검증
5. 확장 boss pool + lane reroll split 기준 경제 재검증
6. 실제 ML 이행 재개
7. 공모전 기준 남은 작업 재개

핵심 정정:

- `1ddda4b`의 ML 산출물은 좁은 boss pool 기준 offline candidate recommendation gate다.
- Boss pool이 확장되면 레벨링 입력 공간이 바뀌므로, 최종 ML 이행은 boss pool 확장과 레벨링/경제 재검증 이후에 다시 수행한다.
- ML 재개 시에는 데이터 증량 필요 여부를 먼저 검토한다. 데이터가 부족하면 기존 휴리스틱/시뮬레이션 파이프라인으로 보강하고, 그래도 부족하면 적절한 candidate sweep/probe로 증량한다.

## 1. 완료된 선행 정리 상태

Status: Done

완료:

- [x] `analysis/leveling/`, `tools/leveling/`, 관련 docs에서 “실제 ML 완료”처럼 읽히는 표현을 감사했다.
- [x] pre-outcome 산출물을 `planned transition scaffold`, `not production ML`, `runtime 자동 적용 아님`으로 정정했다.
- [x] 텍스트 자름/줄바꿈 정책 작업을 완료했다.
- [x] `START_HERE.md` 기준 문서 진입점과 planning 문서 파편화 점검을 완료했다.
- [x] current 문서와 V4 spec의 잔여 `STATUS.md`/legacy planning 참조를 current 기준으로 정리했다.

보존할 산출물:

- `analysis/leveling/reports/actual_ml_transition_human_review.md`
- `analysis/leveling/reports/preoutcome_candidate_recommendation_report.md`
- `analysis/leveling/data/features/*.metadata.json`
- `analysis/leveling/models/*_metrics.json`
- `analysis/leveling/models/*_feature_importance.csv`

대용량 generated 산출물:

- `analysis/leveling/generated/features/leveling_preoutcome_feature_table.csv`
- `analysis/leveling/generated/features/leveling_preoutcome_sequence_feature_table.csv`
- 위 CSV들은 재생성 가능한 heavy artifact이므로 Git 추적 대상이 아니다.
- `logs/sim/*.jsonl` raw run log도 Git 추적 대상이 아니다.
- `tools/leveling/train_leveling_model.py`와 `tools/leveling/recommend_leveling_candidates.py`는 generated feature CSV가 없으면 metadata의 `source_paths` 기준으로 자동 재생성을 시도한다.
- 단, 다른 PC에서 `logs/sim/*_summary.json` source가 없으면 자동 재생성은 불가능하므로 summary 로그를 외부 저장소에서 복원하거나 해당 probe를 다시 실행해야 한다.

주의:

- 위 산출물은 좁은 boss pool 기준 baseline이다.
- Boss pool 확장 후 재학습 전까지 최종 ML 이행 완료 근거로 쓰지 않는다.

## 2. Boss Pool Mapping

Status: Done

목표:

- 원본 28개 boss pattern을 우리 게임 룰 패턴으로 매핑한다.
- 이름/IP를 가져오지 않고, 룰 패턴과 압박 구조만 흡수한다.
- 현재 10개 simulation proxy / 8개 runtime modifier와 겹치는 것, 새로 흡수 가능한 것, 금지할 것을 분류한다.

필수 분류:

- [x] 이미 흡수됨
- [x] simulation proxy는 있으나 runtime 미편입
- [x] runtime modifier 추가 가능
- [x] simulation-only 후보
- [x] 자동 자원 보정/유저 선택 강제라 금지
- [x] 출품 전 1차 범위에서 제외

현재 진행:

- [x] `docs/planning/BOSS_POOL_EXPANSION_MAPPING.md`에 reference pattern mapping 초안 작성
- [x] `boss_expansion_probe_v1` simulation-only profile 추가
- [x] r80/r120 exploratory smoke 실행
- [x] 후보별 r80 split smoke 실행
- [x] `confirm_limit_tax_v1` runtime 구현 가능 경로 확인 후 Boss Pool 1차 확장으로 넘김

제약:

- `Jester` 명칭은 유지한다.
- 원본 보스 이름/테마를 그대로 가져오지 않는다.
- 자동 자원 지급, 직접 지급, 특정 슬롯 고정, 유저 선택 강제는 금지한다.

## 3. Boss Pool 1차 확장

Status: Done for first pass / station pool applied / revalidation pending

목표:

- 출품 안정성을 해치지 않는 boss modifier 후보를 1차로 추가한다.
- 먼저 simulation proxy에 추가하고, runtime 적용은 안전한 범위만 고른다.

완료 조건:

- [x] 새 boss 후보 id와 설명이 우리 게임 용어로 작성된다.
- [x] `tools/sim/run_balance_sim.dart` 또는 해당 boss simulation 경로에 후보가 들어간다.
- [x] runtime에 넣는 후보는 저장/복원/표시/정산 penalty 경로가 확인된다.
- [x] S1~S8에 즉시 전부 고정 배치하지 않고, station pool 후보 또는 별도 experiment axis로 검증한다.

현재 판정:

- `confirm_limit_tax_v1`은 후보별 r80 split에서 v9가 none보다 높아 1차 runtime 후보로 좁힌다.
- `min_contributor_count_v1`, `rank_family_decay_v1`은 boss 전투 단위 clear는 높지만 balanced v9 역전 신호가 있어 simulation-only 보류한다.
- `confirm_limit_tax_v1`은 runtime modifier로 구현됐고 seed 기반 station pool 후보로 편입했다.
- 28개 reference pattern 재검토 후 Stage A 추가 proxy를 넣었고, split probe 기준 `reward_tax_by_contributor_v1`과 `hand_discard_cost_v1`를 Stage B 우선 후보로 좁혔다.
- 코드 경로 확인 결과, 다음 작은 구현 후보는 저장 schema를 늘리지 않는 `hand_discard_cost_v1` resource-pressure spike다. `reward_tax_by_contributor_v1`은 cashout/economy/UI 영향이 커서 별도 작업으로 분리한다.
- 앱 runtime에는 simulator처럼 boss 후보만 주입하는 experiment axis가 없으므로, `hand_discard_cost_v1`도 적용하면 실제 런타임 규칙 변경이다. 구현 전 승인 대상으로 둔다.
- S2/S3/S4 position r80 probe 기준으로는 S3 boss가 가장 자연스럽다. S2는 너무 안전하고 S4는 v9가 none보다 낮아지는 신호가 있다.
- 구현 후보 증량을 위해 이미 구현된 rank 계열도 재검토했다. r80 기준 `repeat_rank_pressure_v4` S4와 `single_rank_pressure` S4는 v9가 none보다 높아 Stage B station pool 후보로 재승격한다.
- 추가 r80 기준 `confirm_limit_tax_v1` S4와 `color_dampener_variant_v1` S4/S5도 Stage B station pool 후보로 재승격한다. S6 confirm-limit와 S2 color는 너무 안전해 우선순위에서 제외한다.
- runtime은 고정 8개 cycle에서 station 난이도 level별 3~4개 seed 기반 boss pool로 확장했다. 선택된 boss modifier는 기존 blind state에 저장되므로 새 저장 schema는 없다.
- simulation pool에도 runtime과 같은 station 난이도 level별 profile `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_runtime_station_pool_v1`을 추가했다. 이후 레벨링/경제/ML 재검증은 이 profile을 우선 입력으로 사용한다.
- 저장 포맷, UI/피드백 구조, 정산 reward tax line, Jester/Item 비활성 표시가 필요한 나머지 boss 후보는 공모전 이후 적용 후보로 넘긴다. 공모전 전에는 현재 runtime/sim mirror pool 기준으로 레벨링과 경제를 다시 맞춘다.

주의:

- 출품 전 1차 확장은 다양성 확보가 목표다.
- 한 번에 28개 모두 runtime 구현하지 않는다.
- 저장 포맷 변경이 필요하면 중간 승인 대상이다.

## 4. 확장 Boss Pool 기준 레벨링 재검증

Status: Closed for ML handoff / runtime S4 rank-weight patch applied

목표:

- 확장 boss pool이 S1~S8 난이도 역할을 깨지 않는지 확인한다.

검증 항목:

- [x] S1은 거의 누구나 깨는 입구인지
- [x] S2는 성장이 있으면 쉽고, 없으면 간신히 통과하는지
- [x] S3부터 성장이 없으면 막히는지
- [x] S4~S6은 성장 선택을 점차 검증하는지
- [x] S7~S8은 후반 압박과 실패 비중이 남는지
- [x] board locked / draw exhausted / boss bottleneck 변화

이전 결과:

- `confirm_limit_tax_v1` 확장 profile 기준 r400 leveling probe 완료.
- balanced none 50.7%, balanced v9 68.8%, power none 63.5%, power v9 69.0%.
- S1/S8 boss 병목과 board/draw stop이 남아 있어 확장 profile이 압박을 지우지는 않는다.

현재 runtime station pool 결과:

- profile: `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_runtime_station_pool_v1`
- r80 smoke: balanced none 50.0%, balanced v9 51.2%, power none 61.2%, power v9 63.7%.
- r400 leveling: balanced none 48.0%, balanced v9 67.2%, power none 54.0%, power v9 66.0%.
- S8 boss, S1 boss, S3/S4 boss 병목이 남아 있어 boss 압박은 사라지지 않았다.
- v9가 none보다 낮아지는 레벨링 역전은 없다.

최신 적용 후보:

- S4 mid boss pool에서 `single_rank_pressure` 후보 비중을 1/4에서 2/4로 올렸다. 고정 배치가 아니라 seed 기반 후보 가중이다.
- 같은 구조의 sim profile `runtime_station_pool_s4_rank_weight_v1` r400에서 v9는 balanced 47.5% -> 52.0%, power 53.8% -> 57.0%로 none보다 높다.
- S8 boss, S1 boss, board full, draw exhausted 실패가 남아 후반 압박은 유지된다.

실행 기준:

- r80~r120은 탐색용이다.
- gate 판단은 가능하면 r400 이상으로 본다.
- runs를 낮추면 문서에 exploratory/not closed로 분리한다.

## 5. 확장 Boss Pool + Lane Reroll Split 기준 경제 재검증

Status: Closed for ML handoff / runtime growth-access price cap applied

목표:

- boss pool 확장으로 전투 소모와 실패율이 바뀐 상태에서 경제 baseline을 다시 본다.
- Jester/Slots와 Tool/Gear lane reroll split 이후의 reroll spend도 함께 확인한다.

검증 항목:

- [x] v9 market clear가 none/control보다 부당하게 낮아지지 않는지
- [x] final gold avg
- [x] S8 boss 시작 골드
- [x] reroll spend
- [x] unaffordable event
- [x] S1/S2/S3/S7/S8 병목
- [x] board locked / draw exhausted

현재 기준:

- `reward 0.40 / price 2.2 / catalog_normalized_v1`은 출품용 baseline으로 유지한다.
- 그러나 fresh r80에서 balanced+v9가 none보다 낮은 신호가 있으므로 경제 gate는 not closed다.

현재 결과:

- 확장 boss pool `confirm_limit_tax_v1` profile 기준 r400 raw economy probe 완료.
- balanced none 49.8%, balanced v9 56.0%, power none 59.0%, power v9 58.8%.
- v9 final gold avg 약 6.45G, v9 S8 boss 시작 골드 약 9.4G, reroll spend 98,470G, unaffordable event 7,474회.
- 즉시 경고는 없지만 power v9 미세 역전이 남아 있고, seed 기반 runtime pool 적용 후 재검증 전이므로 최종 경제 gate 완료가 아니라 “expanded profile 기준 즉시 경고 없음 / not fully closed”로 둔다.
- 이 결과는 실제 ML 이행 재개 입력으로 사용한다.

runtime station pool 경제 결과:

- command output: `logs/sim/runtime_station_pool_economy_r400_summary.json`
- audit: `logs/sim/runtime_station_pool_economy_r400_audit.json`
- balanced none 48.5%, balanced v9 48.2%, power none 56.8%, power v9 56.8%.
- v9 final gold avg 6.23G, v9 S8 boss 시작 골드 9.48G, reroll spend 96,307G, unaffordable event 7,185회.
- 경제 trace를 적용하면 `shop_slot_market_v9`가 clear를 올리지 못하므로, runtime station pool 기준 경제 gate는 not closed다.
- 자동 지급/슬롯 고정으로 풀지 않는다. 다음 후보는 market availability, board/move/discard 후보 접근성, boss severity 위치를 분리해 본다.

market availability 분리 r80:

- command output: `logs/sim/runtime_station_pool_market_availability_r80_summary.json`
- audit: `logs/sim/runtime_station_pool_market_availability_r80_audit.json`
- balanced: none 57.5%, v9 48.8%, v10 48.8%, v11 53.8%, v12 50.0%, v13 52.5%.
- power: none 62.5%, v9 63.7%, v10 67.5%, v11 56.2%, v12 66.2%, v13 43.8%.
- v11/v13은 balanced를 v9보다 일부 회복하지만 none보다 낮다. v10/v12는 power를 올리지만 balanced가 낮다.
- 결론: 단일 market availability profile로 balanced/power를 동시에 해결하지 못한다. 다음 후보는 loadout별 전략을 강제하지 않고, S4~S8 market role band와 boss severity 위치를 분리하는 multi-seed probe다.

S4~S8 role band 분리 r80:

- command output: `logs/sim/runtime_station_pool_market_role_band_probe_r80_summary.json`
- audit: `logs/sim/runtime_station_pool_market_role_band_probe_r80_audit.json`
- balanced: none 57.5%, v9 48.8%, v10 48.8%, v11 53.8%, v12 50.0%, v13 52.5%.
- power: none 62.5%, v9 63.7%, v10 67.5%, v11 56.2%, v12 66.2%, v13 43.8%.
- v9 S8 boss 시작 골드는 약 9.57G, v9 final gold avg는 약 6.51G다.
- 전체 reroll spend는 58,751G, unaffordable event는 7,459회다.
- 판정: 이전 market availability r80과 같은 방향이다. balanced를 none 이상으로 회복하지 못하고, power 개선 후보(v10/v12)는 balanced를 악화한다. 단일 role band profile로 닫지 않는다.

Boss severity placement 분리 r80:

- command output: `logs/sim/runtime_station_pool_boss_severity_placement_probe_r80_summary.json`
- report: `logs/sim/runtime_station_pool_boss_severity_placement_probe_r80_report.md`
- 비교 축은 `none,v9` market만 사용해 market role band와 섞지 않았다.
- runtime station pool control: balanced none 51.2%, balanced v9 57.5%, power none 60.0%, power v9 53.8%.
- `hand_discard S3`: balanced none 60.0%, balanced v9 57.5%, power none 53.8%, power v9 70.0%. balanced v9가 none보다 낮아 바로 적용하지 않는다.
- `single_rank S4`: balanced none 57.5%, balanced v9 58.8%, power none 68.8%, power v9 81.2%. 가장 강한 clear 신호지만 power v9가 높아 과보정 watch다.
- `confirm_limit S5`: balanced none 46.2%, balanced v9 55.0%, power none 56.2%, power v9 56.2%. balanced 회복 후보지만 power 개선은 없다.
- `confirm_limit S4`: balanced none 50.0%, balanced v9 51.2%, power none 53.8%, power v9 53.8%. 개선폭이 작다.
- `color_variant S4/S5`: balanced는 v9가 none보다 높지만 power v9가 none보다 낮다.
- 판정: boss placement만으로도 loadout별 반응이 갈린다. `single_rank S4`와 `confirm_limit S5`는 후속 r120 후보로 남기되, r80 결과만으로 runtime pool이나 economy 값을 바꾸지 않는다.

Market v14 recovery probe:

- code: `tools/sim/run_balance_sim.dart`에 sim-only `shop_slot_market_v14`를 추가했다.
- 의도: v9의 late breaker를 넘지 않고, S4+ missing-growth 후보와 직전 board/draw 압박 relief만 조건부로 보강한다. 직접 지급, 자동 구매, 특정 슬롯 고정, runtime 적용은 없다.
- r80 first: `logs/sim/runtime_station_pool_market_v14_probe_r80_summary.json`, audit `logs/sim/runtime_station_pool_market_v14_probe_r80_audit.json`.
  - balanced none 57.5%, v9 48.8%, v14 60.0%.
  - power none 61.3%, v9 56.2%, v14 58.8%.
  - 판정: balanced는 회복했지만 power가 none보다 낮아 미통과.
- r80 pressure adjusted: `logs/sim/runtime_station_pool_market_v14_pressure_s4_probe_r80_summary.json`, audit `logs/sim/runtime_station_pool_market_v14_pressure_s4_probe_r80_audit.json`.
  - balanced none 46.2%, v9 47.5%, v14 65.0%.
  - power none 62.5%, v9 63.7%, v14 57.5%.
  - 판정: balanced 과회복, power 악화로 미통과.
- r80 combo check: `logs/sim/runtime_station_pool_market_v14_boss_combo_probe_r80_summary.json`.
  - runtime station pool 기준 balanced none 45.0%, v9 48.8%, v14 56.2%; power none 55.0%, v9 53.8%, v14 66.2%.
  - S8 실패와 board/draw stop은 남았다.
  - 판정: seed상 좋아 보여 r120 확인 후보로 올렸다.
- r120 confirm: `logs/sim/runtime_station_pool_market_v14_confirm_r120_summary.json`, audit `logs/sim/runtime_station_pool_market_v14_confirm_r120_audit.json`.
  - balanced none 53.3%, v9 49.2%, v14 51.7%.
  - power none 58.3%, v9 60.0%, v14 59.2%.
  - v14 final gold avg는 약 6.30G, v14 S8 boss 시작 골드는 약 31.65G 전체 평균 기준이며 none 골드가 섞인 비교는 market별 분리해서 봐야 한다.
  - 판정: v14는 v9 대비 balanced를 회복하고 power를 none보다 소폭 올리지만, balanced가 none보다 낮아 strict gate는 닫지 못한다. runtime 적용 금지, 후속 r400 후보도 아직 보류한다.

Condition profile review:

- command output: `logs/sim/runtime_station_pool_market_condition_probe_r120_summary.json`
- audit: `logs/sim/runtime_station_pool_market_condition_probe_r120_audit.json`
- runtime station pool 기준:
  - none: balanced 55.8%, power 62.5%.
  - v9: balanced 50.8%, power 59.2%.
  - v14: balanced 50.0%, power 56.7%.
  - `s1_state_weighted_candidate_pool`: balanced 58.3%, power 60.0%.
  - `banded_candidate_pool_v2`: balanced 59.2%, power 62.5%.
- 판정: 기존 조건형 profile은 balanced 회복에 유리하다. 특히 `banded_candidate_pool_v2`는 power를 none과 동률로 유지하고 S8 병목도 남긴다. 다만 shop-slot lane/offer slot 경제와 1:1 대응되는 runtime profile은 아니므로 그대로 적용하지 않는다.

Condition + boss placement combo r120:

- command output: `logs/sim/runtime_station_pool_condition_boss_combo_probe_r120_summary.json`
- report: `logs/sim/runtime_station_pool_condition_boss_combo_probe_r120_report.md`
- `confirm_limit S5 + banded_v2`: balanced none 53.3% -> 59.2%, power none 54.2% -> 70.8%. S8 fail 22, board/draw stop 유지.
- `confirm_limit S5 + state_weighted`: balanced 60.0%, power 74.2%. 좋은 신호지만 power가 높아 과보정 watch.
- `single_rank S4 + v14`: balanced 56.7%, power 64.2%. none 대비 양쪽 모두 개선하지만 S1 fail 27, S8 fail 30으로 초반/후반 병목이 같이 남는다.
- `single_rank S4 + banded_v2`: balanced 52.5%, power 68.3%. balanced 개선폭이 작고 power 쪽이 크다.
- 판정: market 단독보다 boss placement와 조건형 market 조합이 더 유망하다. 다음 구현 후보는 `banded_v2/state_weighted`의 score/deck/board 압박 조건을 shop-slot lane 구조에 옮긴 sim-only `shop_slot_market_v15`다. 단, 코드 작성 전 사람 승인 대상으로 둔다.

shop-slot v15 + boss combo r80:

- outputs: `logs/sim/runtime_station_pool_market_v15_probe_r80_summary.json`, `logs/sim/runtime_station_pool_v15_boss_combo_probe_r80_summary.json`, `logs/sim/runtime_station_pool_v15_boss_combo_probe_r80_report.md`
- 쉬운 결론: v15는 "상점 후보를 현재 상황에 맞게 고르는" 실험이지만, 지금 값은 마지막 보스에서 점수 성장 후보보다 보정 후보를 자주 고르게 해 clear를 올리지 못했다.
- runtime station pool 단독 r80: none은 balanced 51.2%, power 57.5%. v15는 balanced 50.0%, power 56.2%로 둘 다 기준보다 낮다.
- boss combo r80: `single_rank S4 + v15`는 balanced 57.5%, power 60.0%지만, 같은 boss 조건의 none이 balanced 66.2%, power 76.2%라 개선이 아니다. `confirm_limit S5 + v15`도 none보다 낮다.
- 현재 막히는 곳: S1 boss와 S8 boss가 둘 다 남고, 실패 이유도 board full과 draw exhausted가 같이 남는다. 즉, 한 구간만 고치면 해결되는 문제가 아니다.
- 판단: v15는 runtime 적용 후보가 아니다. 다음은 더 큰 보정이 아니라, boss 배치/target/market 후보가 서로 충돌하는 지점을 줄이는 방향으로 설계를 다시 잡는다.

S1/S8 target split r80:

- outputs: `logs/sim/runtime_station_pool_control_r80_summary.json`, `logs/sim/runtime_station_pool_s1_boss_t095_r80_summary.json`, `logs/sim/runtime_station_pool_s8_boss_t095_r80_summary.json`
- 쉬운 결론: 초반 보스만 살짝 낮춰도 거의 안 변한다. 마지막 보스만 낮추면 조금 좋아지지만, v9 상점은 여전히 기준보다 낮다.
- control: none balanced 52.5%, power 60.0% / v9 balanced 43.8%, power 51.2%.
- S1 boss target 5% 완화: v9 balanced 45.0%, power 52.5%. 개선폭이 작다.
- S8 boss target 5% 완화: v9 balanced 46.2%, power 53.8%. S8 실패는 줄지만 전체 문제는 안 닫힌다.
- 판단: S1 또는 S8 하나만 고치는 문제가 아니다. v9 상점 선택이 중간 boss와 후반 boss에서 점수 성장/보드 정리 선택을 엇갈리게 만드는지 다음에 확인한다.

Market choice split r80:

- output: `logs/sim/runtime_station_pool_market_choice_none_r80_summary.json`
- 쉬운 결론: 상점 후보를 뽑는 기준과, 그중 살 수 있는 후보를 최종 선택하는 기준이 서로 따로 논다.
- 기존 최종 선택 사용: v9 balanced 43.8%, power 51.2%.
- 최종 재선택 끔: v9 balanced 48.8%, power 50.0%. balanced는 좋아지지만 power는 그대로 낮다.
- v15는 최종 재선택을 끄면 balanced 57.5%로 기준 none 52.5%를 넘지만, power는 45.0%로 무너진다.
- 판단: 다음 코드 후보는 새 market profile을 더 세게 만드는 것이 아니라, sim-only `affordable_alternative_v2`처럼 최종 구매 선택도 현재 상태와 성장 route를 보게 하는 것이다.

Average market choice proxy r80:

- output: `logs/sim/runtime_station_pool_average_market_choice_r80_summary.json`
- 쉬운 결론: 전투 봇은 있지만, 상점 구매는 아직 평균 플레이어처럼 충분히 판단하지 못한다.
- 현재 `planner_v2`는 전투에서 배치/확정/버림을 고르는 봇이다. 상점에서는 별도 구매 proxy가 후보를 고른다.
- `average_market_choice_v1`은 비싼 구매와 슬롯 교체를 피하게 한 실험이다. v9 balanced 46.2%, power 51.2%로 기존보다 조금 낫지만 기준 none balanced 52.5%, power 60.0%에는 못 미친다.
- 판단: 다음은 상점 proxy만 더 손보지 말고, 전투 bot이 실제 플레이어처럼 보드 정리/낮은 점수 확정/버림을 더 잘 하는지도 같이 본다.

Growth access price + single_rank S4 r400:

- outputs: `logs/sim/single_s4_growth_access_r400_summary.json`, `logs/sim/single_s4_growth_access_r400_economy_audit.json`
- 쉬운 결론: 처음으로 기준을 넘는 실무 후보가 나왔다. S4에 single-rank 압박을 두고, 성장 후보 가격대를 낮춘 조건에서 v9/v15가 둘 다 기준보다 높다.
- 기준 none: balanced 51.7%, power 57.8%.
- v9: balanced 58.0%, power 62.5%.
- v15: balanced 59.2%, power 60.5%.
- 경제: v9/v15 final gold 평균은 약 6G이고, 즉시 경제 경고는 없다. S8 boss 실패와 board/draw 실패도 남아 압박이 사라지지 않았다.
- 판단: `single_rank S4 + growth_access_v1`은 다음 r400 재현/feature 재생성 후보로 올린다. 아직 runtime 적용 완료는 아니며, seed 재현성과 ML/리포트 갱신이 남아 있다.

Runtime S4 rank weight + growth access final r400:

- outputs: `logs/sim/runtime_s4_rank_weight_v1_growth_access_final_r400_summary.json`, `logs/sim/runtime_s4_rank_weight_v1_growth_access_final_r400_economy_audit.json`
- 쉬운 결론: 런타임에 옮길 수 있는 형태로 다시 확인했고, v9가 balanced/power 둘 다 none보다 높다.
- none: balanced 47.5%, power 53.8%.
- v9: balanced 52.0%, power 57.0%.
- v15 sim-only: balanced 59.5%, power 58.2%.
- 경제: v9 final gold 평균 약 5.86G, v9 S8 boss 시작 약 9.98G, 즉시 경제 경고 없음.
- 판단: ML 재개 전 막고 있던 economy gate는 이 후보 기준으로 닫는다. v15는 아직 runtime 적용 후보가 아니므로 ML 입력에서는 별도 sim-only 후보로만 취급한다.

Runtime S4 rank weight + growth access multi-seed check:

- outputs: `logs/sim/runtime_s4_rank_weight_v1_growth_access_seed91627_r400_summary.json`, `logs/sim/runtime_s4_rank_weight_v1_growth_access_seed91628_r400_summary.json`
- 쉬운 결론: 같은 조건을 seed만 바꿔 다시 돌려도 결과가 거의 같다.
- seed91627: none balanced 47.2%, power 54.0% / v9 balanced 52.0%, power 57.0%.
- seed91628: none balanced 47.0%, power 53.8% / v9 balanced 52.0%, power 56.8%.
- 경제: v9 final gold 평균은 약 5.85~5.86G, v9 S8 boss 시작 골드는 약 9.98~10.00G, 즉시 경제 경고 없음.
- 가격 보정 정리: `growth_access` runtime 가격 상한은 점수/족보/색/버림/이동/안전/드로우 성장 후보에만 적용한다. `market`/`boss` 전용 아이템은 더 이상 이 상한으로 싸지지 않는다.

Runtime handoff clear target:

- 쉬운 목표: `none`은 "좋은 상점 도움 없이 돈 판"이므로 너무 높으면 안 된다. `v9`는 "좋은 상점 선택을 한 판"이므로 `none`보다 확실히 높아야 한다.
- `none` 목표: balanced/power 모두 대략 45~55%를 유지한다. 이 범위는 성장 없이도 가끔 깰 수 있지만, 안정 클리어는 어렵다는 뜻이다.
- `balanced v9` 목표: 60~68%를 우선 목표로 둔다. 평균적인 성장 선택을 잘 했을 때 체감 보상이 있어야 한다.
- `power v9` 목표: 62~72%를 우선 목표로 둔다. 점수 성장 선택은 balanced보다 약간 높거나 비슷해야 한다.
- 70% 이상은 장기 목표 후보로 볼 수 있지만, S8/board/draw 실패가 사라지면 과완화로 본다.
- 지금 handoff의 balanced v9 52.0%, power v9 57.0%는 최소 통과선일 뿐 충분한 목표값은 아니다. 다음 작업은 `none`을 크게 올리지 않고 `v9`만 10~15%p 올리는 후보를 찾는다.

Runtime handoff uplift checklist:

- [x] 목표 이유를 문서에 기록한다.
- [x] 가격/보상만 낮추는 후보를 r120으로 확인한다.
- [x] 리롤/슬롯 교체 지출을 분리한 후보를 r120으로 확인한다.
- [x] 목표 범위 후보를 r400으로 확인한다.
- [x] 목표 범위 후보를 다른 seed r400으로 재현한다.
- [x] 목표 범위 후보를 feature table / ML 추천표 / 사람 검토 리포트 입력에 반영한다.
- [x] random split 과대평가를 source split으로 다시 확인한다.
- [x] 목표 범위 후보가 runtime 경제 정책으로 옮겨도 되는지 영향 범위를 확인한다.
- [x] runtime 적용 가능한 리롤 비용 정책 후보를 새로 좁힌다.
- [x] runtime에 적용하고 관련 테스트를 통과시킨다.
- [x] 최신 feature table, station/tier 모델, sequence/path 모델, 추천표, 사람 검토 리포트를 갱신한다.

Runtime handoff uplift results:

- 가격만 낮춘 `price 2.0 / 1.8` r120은 balanced v9 52.5%, power v9 60.8%로 부족했다.
- 보상만 올린 `reward 0.45` r120은 balanced v9 53.3%, power v9 60.0%로 부족했다.
- `no_spend` r120은 balanced v9 62.5~63.3%, power v9 65.8~67.5%로 목표에 가까웠다. 단, 슬롯 교체 비용까지 사라지는 실험이라 그대로 적용하지 않는다.
- 새 sim-only spend mode `slot_sell_v1`은 리롤 비용만 빼고 슬롯 교체/판매는 유지한다.
- `slot_sell_v1` r400 결과: none balanced 51.7%, none power 56.2%, v9 balanced 65.2%, v9 power 67.8%.
- `slot_sell_v1` seed91761 r400 재현: none balanced 51.7%, none power 56.5%, v9 balanced 65.0%, v9 power 67.5%.
- `slot_sell_v1` 경제 감사: v9 final gold 평균은 balanced 16.2G, power 24.3G이고 즉시 경제 경고는 없다. 이전 handoff의 5.9G보다는 느슨하므로 런타임 적용 전 리롤 비용 정책 검토가 필요하다.
- 쉬운 해석: 현재 낮은 v9 clear의 주된 원인은 성장 후보 가격보다 “좋은 후보를 찾기 위한 리롤 비용 압박”이다. 다만 runtime 적용 전에는 리롤 비용 정책 변경이 게임 경제와 UI 기대값을 흔드는지 별도 확인한다.
- ML 입력 반영 후 sequence/path 추천표에서도 `slot_sell_v1` 두 r400은 실제 통과 1, ML 통과 1로 잡힌다. 다만 station/tier 추천표는 여전히 구간별 평균에서는 none 예측이 더 높게 나와 단독 gate로 쓰지 않는다.
- `first_reroll_free_v1` r400 결과: none balanced 48.0%, none power 55.0%, v9 balanced 54.5%, v9 power 66.0%.
- 쉬운 해석: 첫 리롤만 무료로 하면 경제는 안전해진다. v9 final gold는 balanced 약 8.0G, power 약 11.2G다. 하지만 balanced v9가 목표 60%에 못 닿는다. 따라서 “리롤 비용을 조금 줄이는 것”만으로는 부족하고, 후반 성장 후보 접근이나 구매 선택 조건을 같이 봐야 한다.
- `affordable_alternative_v2 + first_reroll_free_v1` r120 결과: v9 balanced 57.5%, power 68.3%다. 쉬운 해석: 상점 구매 판단이 직전 전투의 부족한 점을 봐도 balanced는 아직 60%에 못 닿는다.
- `shop_slot_market_v16` r120 결과: balanced 59.2%, power 62.5%다. 쉬운 해석: 후반 후보를 더 넓히면 balanced는 조금 낫지만 power가 내려간다. 필요한 후보를 더 많이 보이게 하는 것만으로는 답이 아니다.
- `shop_slot_market_v15 + affordable_alternative_v2 + first_reroll_free_v1` r400 결과: none balanced 55.8%, power 65.0% / v15 balanced 55.8%, power 68.5%다. 쉬운 해석: 상태 기반 후보 접근은 power에는 도움이 되지만 balanced에는 도움이 되지 않았다.
- 기준 정정: `growth_access_v1 + affordable_alternative_v2 + first_reroll_free_v1`의 첫 r120/r400은 최신 runtime handoff profile이 아니라 이전 base profile로 돌린 값이라 판단 근거에서 제외한다.
- 최신 runtime profile `runtime_station_pool_s4_rank_weight_v1` r120 결과: none balanced 50.8%, none power 50.8% / v9 balanced 57.5%, power 67.5% / v15 balanced 72.5%, power 72.5%.
- 최신 runtime profile r400 결과: none balanced 48.8%, none power 54.8% / v9 balanced 60.5%, power 69.8% / v15 balanced 59.2%, power 64.8%.
- 쉬운 해석: 최신 기준에서는 `none`은 목표 범위에 남고, v9만 목표 범위로 올라간다. S8 boss 실패와 board/draw 실패도 남아 있어 압박을 완전히 지우지 않았다.
- runtime 적용: 성장 후보 가격 상한은 이미 runtime에 있었고, 부족했던 첫 리롤 무료 정책을 `RummiEconomyConfig.shopFirstRerollDiscount`와 `RummiRunProgress.openShop()`에 적용했다. 저장 필드는 기존 `firstRerollDiscount`를 사용하므로 save schema 변경은 없다.
- economy audit: `logs/sim/runtime_s4_rank_late_access_growth_price_r400_economy_audit.json`에서 즉시 경제 경고 없음.
- ML refresh: station/tier source split MAE 0.0487, RMSE 0.0952, R2 0.7265 / sequence/path source split MAE 0.0560, RMSE 0.1055, R2 0.8482.
- sequence/path recommendation: `logs/sim/runtime_s4_rank_late_access_growth_price_r400_summary.json`은 fresh gate 1, ML gate 1이다.
- 판정: 공모전 기준 ML 임시 handoff 가능. production ML/자동 밸런싱은 아니다.

Shuffle review pre-check:

- 참고 자료: `/Users/cheng80/Desktop/셔플.txt`에서 가져온 “카드 게임 셔플 알고리즘 및 개발 가이드” 내용을 링크 본문 대체 자료로 확인했다.
- 핵심 정리: 현재 같은 seed에서 재현 가능한 Fisher-Yates 계열 셔플은 유지 후보다. Dart `List.shuffle(Random)`은 표준 라이브러리 셔플이고, 우리 게임의 seed 기반 재현성과 시뮬레이션 재현성에 맞다.
- Bag System, Pity Timer, Smart Shuffle, Deck Smoothing은 “공정 셔플”이 아니라 플레이 경험 보정이다. 적용하면 연속 투페어/패 꼬임 체감은 줄일 수 있지만, 확률 룰 자체가 바뀌므로 레벨링과 경제 재검증이 필요하다.
- 셔플 변경 후보는 공모전 작업 전 별도 체크로 둔다. 우선 검토 순서는 현재 셔플 통계 측정 -> 투페어 연속 발생률 확인 -> 보정 셔플이 필요한지 판단 -> 필요 시 runtime/sim 양쪽 적용 -> r400+ 레벨링/경제 재검증이다.

ML leakage / overfit checklist:

- [x] random row split 지표가 과하게 좋아 보일 수 있는지 의심한다.
- [x] source_path 단위 grouped validation 스크립트를 추가한다.
- [x] grouped validation을 실행한다.
- [x] 기존 ML 리포트와 planning 문서의 “사용 가능” 표현을 source split 기준으로 낮춘다.
- [x] 이후 ML gate는 random split과 source split을 함께 표기한다.
- [ ] 새 후보 추가 때마다 source split 지표를 다시 갱신한다.

ML leakage / overfit result:

- random row split은 같은 실험 파일의 비슷한 row가 train/test에 섞일 수 있어 낙관적이다.
- source_path grouped validation 결과 station/tier는 MAE 0.0436, RMSE 0.0899, R2 0.5264이다. 구간 위험 힌트로만 쓰고 단독 gate로 쓰지 않는다.
- source_path grouped validation 결과 sequence/path는 MAE 0.0582, RMSE 0.1120, R2 0.8408이다. 후보 선별 보조 신호로는 유지하되, fresh r400+ 검증이 최종 판단이다.

## 6. 실제 ML 이행 재개

Status: Closed for offline ML handoff / runtime auto-balancing not enabled

재개 조건:

- [x] Boss pool mapping 완료
- [x] Boss pool 1차 확장 완료 또는 명시 보류
- [x] 확장 boss pool 기준 레벨링 probe 완료
- [x] 확장 boss pool + lane reroll split 기준 경제 probe 완료 또는 명시 보류

ML 재개 시 필수 작업:

- [x] 데이터 증량 필요 여부를 먼저 검토한다.
- [x] 기존 휴리스틱/시뮬레이션 summary로 충당 가능한지 확인한다.
- [x] 부족하면 candidate grid/probe/sweep으로 데이터를 증량한다.
- [x] pre-outcome station/tier feature table을 다시 만든다.
- [x] sequence/path feature table을 다시 만든다.
- [x] baseline model과 metric을 다시 생성한다.
- [x] 모델 추천표를 다시 만든다.
- [x] 추천 후보를 fresh resimulation으로 검증한다.
- [x] 사람 승인용 MD 분석 보고서를 갱신한다.
- [x] 사람 승인 전 runtime target/boss/market/economy 값은 바꾸지 않는다.
- [x] 회귀 모델 지표를 MAE/RMSE/R2 기준으로 다시 산출한다.
- [x] 실무 추천 기준에 충분한 모델 품질과 데이터 수를 확보한다.

현재 결과:

- 이전 station/tier pre-outcome table 14,544 rows, MAE 0.0360, RMSE 0.1014, R2 0.1548.
- 이전 sequence/path pre-outcome table 92 rows, MAE 0.0651, RMSE 0.1246, R2 0.4202.
- 중간 station/tier pre-outcome table은 전체 source 239,212 rows 중 60,000 sampled train set을 사용했다. MAE 0.0631, RMSE 0.1314, R2 0.5610이며 이후 갱신 전 기준이다.
- 최신 high-confidence station/tier random split은 MAE 0.0239, RMSE 0.0499, R2 0.9037이지만, source-path split은 MAE 0.0436, RMSE 0.0899, R2 0.5264이다. 쉽게 말하면 “위험해 보이는 구간 힌트”로만 쓴다.
- 최신 sequence/path random split은 MAE 0.0509, RMSE 0.0905, R2 0.9014이고, source-path split은 MAE 0.0582, RMSE 0.1120, R2 0.8408이다. 쉽게 말하면 “다음 후보를 고르는 보조 신호”로 쓴다.
- feature 추가: station/tier 조합, station-boss 상호작용, station-pressure 상호작용, market-station 상호작용, economy-market 상호작용, 실제 target score, reward/resource pressure, price band/spend/choice mode flag.
- 모델 개선: 큰 데이터 반복 실행이 가능하도록 baseline tree 수와 `n_jobs=2`를 조정하고, `run_count`는 모델 feature가 아니라 sample weight로만 쓴다. 작은 표본 결과가 큰 표본 결과와 같은 힘으로 학습되는 문제를 줄이기 위한 조치다.
- 최신 station/tier 추천표는 `clear_rate_smoothed` 기준으로 다시 만들었다. 이 표는 구간별 위험 진단용이고, 최종 후보 판단은 sequence/path 추천표와 fresh r400+ 결과를 따른다.
- 최신 sequence/path 추천표 `analysis/leveling/reports/preoutcome_sequence_candidate_recommendation_report.md`는 현재 runtime handoff 후보를 실제 결과와 ML 예측 양쪽에서 통과로 본다.
- 현재 runtime economy baseline `reward 0.40 / price 2.2 / catalog_normalized_v1` 유지.
- production ML/자동 적용은 여전히 아님. 이번에 남긴 것은 source split으로 보수화한 offline ML 보조 신호와 fresh simulation gate다.
- 실무 적용 기준: source split을 우선한다. sequence/path는 후보 선별 보조 신호로 쓰되, fresh resimulation에서 v9 >= none 및 S1/S8 병목 보존을 동시에 만족해야 한다. station/tier는 source split R2가 낮으므로 단독 추천 gate로 쓰지 않는다.
- NotebookLM 보고서/인포그래픽 재생성은 아직 보류한다. source split 기준 station/tier가 힌트 전용이고, runtime 리롤 비용 정책 후보도 아직 닫히지 않았다.

완료로 인정하지 않는 것:

- feature table만 다시 만든 상태
- r80 exploratory probe만 실행한 상태
- 모델 metric만 생성한 상태
- MAE/RMSE/R2 중 일부만 있거나 R2가 낮아 실무 사용 기준에 못 미치는 상태
- production ML/자동 적용처럼 읽히는 문구

## 7. 공모전 기준 남은 작업 재개

Status: Ready to resume / ML handoff closed for offline use

재개 조건:

- [x] 확장 boss pool 기준 레벨링/경제/ML 상태가 source-of-truth에 반영된다.
- [x] 경제 gate가 완료 또는 출품 기준 명시 보류로 정리된다.
- [x] Boss pool 1차 확장 범위가 구현 완료 또는 출품 기준 명시 보류된다.
- [x] 현재 market/economy/proxy 문제를 출품 기준으로 닫는다.

재개 후 우선순위:

1. Boss pool 1차 확장 적용 범위 QA
2. 텍스트/네이밍/IP 리스크 잔여 정리
3. browser/compute QA
4. submission smoke
5. 제출 후보 빌드 안정화
