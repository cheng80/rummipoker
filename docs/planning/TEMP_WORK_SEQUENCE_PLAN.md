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

Status: Next

목표:

- 원본 28개 boss pattern을 우리 게임 룰 패턴으로 매핑한다.
- 이름/IP를 가져오지 않고, 룰 패턴과 압박 구조만 흡수한다.
- 현재 10개 simulation proxy / 8개 runtime modifier와 겹치는 것, 새로 흡수 가능한 것, 금지할 것을 분류한다.

필수 분류:

- [ ] 이미 흡수됨
- [ ] simulation proxy는 있으나 runtime 미편입
- [ ] runtime modifier 추가 가능
- [ ] simulation-only 후보
- [ ] 자동 자원 보정/유저 선택 강제라 금지
- [ ] 출품 전 1차 범위에서 제외

제약:

- `Jester` 명칭은 유지한다.
- 원본 보스 이름/테마를 그대로 가져오지 않는다.
- 자동 자원 지급, 직접 지급, 특정 슬롯 고정, 유저 선택 강제는 금지한다.

## 3. Boss Pool 1차 확장

Status: Pending

목표:

- 출품 안정성을 해치지 않는 boss modifier 후보를 1차로 추가한다.
- 먼저 simulation proxy에 추가하고, runtime 적용은 안전한 범위만 고른다.

완료 조건:

- [ ] 새 boss 후보 id와 설명이 우리 게임 용어로 작성된다.
- [ ] `tools/sim/run_balance_sim.dart` 또는 해당 boss simulation 경로에 후보가 들어간다.
- [ ] runtime에 넣는 후보는 저장/복원/표시/정산 penalty 경로가 확인된다.
- [ ] S1~S8 cycle에 즉시 전부 넣지 않고, pool 후보 또는 별도 experiment axis로 검증한다.

주의:

- 출품 전 1차 확장은 다양성 확보가 목표다.
- 한 번에 28개 모두 runtime 구현하지 않는다.
- 저장 포맷 변경이 필요하면 중간 승인 대상이다.

## 4. 확장 Boss Pool 기준 레벨링 재검증

Status: Pending

목표:

- 확장 boss pool이 S1~S8 난이도 역할을 깨지 않는지 확인한다.

검증 항목:

- [ ] S1은 거의 누구나 깨는 입구인지
- [ ] S2는 성장이 있으면 쉽고, 없으면 간신히 통과하는지
- [ ] S3부터 성장이 없으면 막히는지
- [ ] S4~S6은 성장 선택을 점차 검증하는지
- [ ] S7~S8은 후반 압박과 실패 비중이 남는지
- [ ] board locked / draw exhausted / boss bottleneck 변화

실행 기준:

- r80~r120은 탐색용이다.
- gate 판단은 가능하면 r400 이상으로 본다.
- runs를 낮추면 문서에 exploratory/not closed로 분리한다.

## 5. 확장 Boss Pool + Lane Reroll Split 기준 경제 재검증

Status: Pending

목표:

- boss pool 확장으로 전투 소모와 실패율이 바뀐 상태에서 경제 baseline을 다시 본다.
- Jester/Slots와 Tool/Gear lane reroll split 이후의 reroll spend도 함께 확인한다.

검증 항목:

- [ ] v9 market clear가 none/control보다 부당하게 낮아지지 않는지
- [ ] final gold avg
- [ ] S8 boss 시작 골드
- [ ] reroll spend
- [ ] unaffordable event
- [ ] S1/S2/S3/S7/S8 병목
- [ ] board locked / draw exhausted

현재 기준:

- `reward 0.40 / price 2.2 / catalog_normalized_v1`은 출품용 baseline으로 유지한다.
- 그러나 fresh r80에서 balanced+v9가 none보다 낮은 신호가 있으므로 경제 gate는 not closed다.

## 6. 실제 ML 이행 재개

Status: Blocked by boss/economy gates

재개 조건:

- [ ] Boss pool mapping 완료
- [ ] Boss pool 1차 확장 완료 또는 명시 보류
- [ ] 확장 boss pool 기준 레벨링 probe 완료
- [ ] 확장 boss pool + lane reroll split 기준 경제 probe 완료 또는 명시 보류

ML 재개 시 필수 작업:

- [ ] 데이터 증량 필요 여부를 먼저 검토한다.
- [ ] 기존 휴리스틱/시뮬레이션 summary로 충당 가능한지 확인한다.
- [ ] 부족하면 candidate grid/probe/sweep으로 데이터를 증량한다.
- [ ] pre-outcome station/tier feature table을 다시 만든다.
- [ ] sequence/path feature table을 다시 만든다.
- [ ] baseline model과 metric을 다시 생성한다.
- [ ] 모델 추천표를 다시 만든다.
- [ ] 추천 후보를 fresh resimulation으로 검증한다.
- [ ] 사람 승인용 MD 분석 보고서를 갱신한다.
- [ ] 사람 승인 전 runtime target/boss/market/economy 값은 바꾸지 않는다.

완료로 인정하지 않는 것:

- feature table만 다시 만든 상태
- r80 exploratory probe만 실행한 상태
- 모델 metric만 생성한 상태
- production ML/자동 적용처럼 읽히는 문구

## 7. 공모전 기준 남은 작업 재개

Status: Blocked

재개 조건:

- [ ] 확장 boss pool 기준 레벨링/경제/ML 상태가 source-of-truth에 반영된다.
- [ ] 경제 gate가 완료 또는 출품 기준 명시 보류로 정리된다.
- [ ] Boss pool 1차 확장 범위가 구현 완료 또는 출품 기준 명시 보류된다.

재개 후 우선순위:

1. Boss pool 1차 확장 적용 범위 QA
2. 텍스트/네이밍/IP 리스크 잔여 정리
3. browser/compute QA
4. submission smoke
5. 제출 후보 빌드 안정화
