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
- `analysis/leveling/data/features/leveling_preoutcome_feature_table.csv`
- `analysis/leveling/data/features/leveling_preoutcome_sequence_feature_table.csv`

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

Status: Done for first pass / cycle pending

목표:

- 출품 안정성을 해치지 않는 boss modifier 후보를 1차로 추가한다.
- 먼저 simulation proxy에 추가하고, runtime 적용은 안전한 범위만 고른다.

완료 조건:

- [x] 새 boss 후보 id와 설명이 우리 게임 용어로 작성된다.
- [x] `tools/sim/run_balance_sim.dart` 또는 해당 boss simulation 경로에 후보가 들어간다.
- [x] runtime에 넣는 후보는 저장/복원/표시/정산 penalty 경로가 확인된다.
- [x] S1~S8 cycle에 즉시 전부 넣지 않고, pool 후보 또는 별도 experiment axis로 검증한다.

현재 판정:

- `confirm_limit_tax_v1`은 후보별 r80 split에서 v9가 none보다 높아 1차 runtime 후보로 좁힌다.
- `min_contributor_count_v1`, `rank_family_decay_v1`은 boss 전투 단위 clear는 높지만 balanced v9 역전 신호가 있어 simulation-only 보류한다.
- `confirm_limit_tax_v1`은 runtime modifier로 구현됐지만 S1~S8 cycle에는 아직 편입하지 않았다.
- 28개 reference pattern 재검토 후 Stage A 추가 proxy를 넣었고, split probe 기준 `reward_tax_by_contributor_v1`과 `hand_discard_cost_v1`를 Stage B 우선 후보로 좁혔다.
- 코드 경로 확인 결과, 다음 작은 구현 후보는 저장 schema를 늘리지 않는 `hand_discard_cost_v1` resource-pressure spike다. `reward_tax_by_contributor_v1`은 cashout/economy/UI 영향이 커서 별도 작업으로 분리한다.
- 앱 runtime에는 simulator처럼 boss 후보만 주입하는 experiment axis가 없으므로, `hand_discard_cost_v1`도 적용하면 실제 런타임 규칙 변경이다. 구현 전 승인 대상으로 둔다.
- S2/S3/S4 position r80 probe 기준으로는 S3 boss가 가장 자연스럽다. S2는 너무 안전하고 S4는 v9가 none보다 낮아지는 신호가 있다.
- 구현 후보 증량을 위해 이미 구현된 rank 계열도 재검토했다. r80 기준 `repeat_rank_pressure_v4` S4와 `single_rank_pressure` S4는 v9가 none보다 높아 Stage B cycle 편입 후보로 재승격한다.
- 추가 r80 기준 `confirm_limit_tax_v1` S4와 `color_dampener_variant_v1` S4/S5도 Stage B cycle 편입 후보로 재승격한다. S6 confirm-limit와 S2 color는 너무 안전해 우선순위에서 제외한다.

주의:

- 출품 전 1차 확장은 다양성 확보가 목표다.
- 한 번에 28개 모두 runtime 구현하지 않는다.
- 저장 포맷 변경이 필요하면 중간 승인 대상이다.

## 4. 확장 Boss Pool 기준 레벨링 재검증

Status: Done for expanded profile probe

목표:

- 확장 boss pool이 S1~S8 난이도 역할을 깨지 않는지 확인한다.

검증 항목:

- [x] S1은 거의 누구나 깨는 입구인지
- [x] S2는 성장이 있으면 쉽고, 없으면 간신히 통과하는지
- [x] S3부터 성장이 없으면 막히는지
- [x] S4~S6은 성장 선택을 점차 검증하는지
- [x] S7~S8은 후반 압박과 실패 비중이 남는지
- [x] board locked / draw exhausted / boss bottleneck 변화

현재 결과:

- `confirm_limit_tax_v1` 확장 profile 기준 r400 leveling probe 완료.
- balanced none 50.7%, balanced v9 68.8%, power none 63.5%, power v9 69.0%.
- S1/S8 boss 병목과 board/draw stop이 남아 있어 확장 profile이 압박을 지우지는 않는다.
- 다음 순서인 확장 boss pool + lane reroll split 기준 경제 재검증으로 진행한다.

실행 기준:

- r80~r120은 탐색용이다.
- gate 판단은 가능하면 r400 이상으로 본다.
- runs를 낮추면 문서에 exploratory/not closed로 분리한다.

## 5. 확장 Boss Pool + Lane Reroll Split 기준 경제 재검증

Status: Done for expanded profile probe / not fully closed

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
- 즉시 경고는 없지만 power v9 미세 역전과 runtime cycle 미편입 상태가 남아 있어 최종 경제 gate 완료가 아니라 “expanded profile 기준 즉시 경고 없음 / not fully closed”로 둔다.
- 이 결과는 실제 ML 이행 재개 입력으로 사용한다.

## 6. 실제 ML 이행 재개

Status: In progress / model quality not sufficient for gate closure

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
- [ ] 회귀 모델 지표를 MAE/RMSE/R2 기준으로 다시 산출한다.
- [ ] 실무 추천 기준에 충분한 모델 품질과 데이터 수를 확보한다.

현재 결과:

- station/tier pre-outcome table 14,544 rows, MAE 0.0360, RMSE 0.1014, R2 0.1548.
- sequence/path pre-outcome table 92 rows, MAE 0.0651, RMSE 0.1246, R2 0.4202.
- 모델 추천 상위 economy 후보 `reward 0.38 / price 2.4`, `reward 0.40 / price 2.4`는 expanded boss fresh r120에서 balanced+v9가 none보다 낮아져 runtime 적용 보류.
- 현재 runtime economy baseline `reward 0.40 / price 2.2 / catalog_normalized_v1` 유지.
- production ML/자동 적용은 여전히 아님.
- 현재 모델 지표는 실무 추천 기준에 한참 부족하므로 ML 마감이나 recommendation gate 완료로 보지 않는다.
- NotebookLM 보고서/인포그래픽 재생성은 모델 지표가 사용 수준이 된 뒤에만 한다. 현재 리포트는 내부 판단 source로만 둔다.

완료로 인정하지 않는 것:

- feature table만 다시 만든 상태
- r80 exploratory probe만 실행한 상태
- 모델 metric만 생성한 상태
- MAE/RMSE/R2 중 일부만 있거나 R2가 낮아 실무 사용 기준에 못 미치는 상태
- production ML/자동 적용처럼 읽히는 문구

## 7. 공모전 기준 남은 작업 재개

Status: Next

재개 조건:

- [x] 확장 boss pool 기준 레벨링/경제/ML 상태가 source-of-truth에 반영된다.
- [x] 경제 gate가 완료 또는 출품 기준 명시 보류로 정리된다.
- [x] Boss pool 1차 확장 범위가 구현 완료 또는 출품 기준 명시 보류된다.

재개 후 우선순위:

1. Boss pool 1차 확장 적용 범위 QA
2. 텍스트/네이밍/IP 리스크 잔여 정리
3. browser/compute QA
4. submission smoke
5. 제출 후보 빌드 안정화
