# Temporary Work Sequence Plan

> 문서 성격: temporary execution lock
> 생성 이유: gate 완료와 scaffold/탐색 완료를 섞지 않기 위해 현재 작업 큐를 고정한다.
> 삭제 조건: 실제 ML 이행과 post lane reroll 경제 probe 상태 정리가 source-of-truth에 완료로 반영되고, 사용자가 공모전 작업 재개를 확인한 뒤 삭제한다.

## 0. 고정 순서

이 문서가 남아 있는 동안 아래 순서를 바꾸지 않는다.

1. `analysis/leveling/`, `tools/leveling/`, 관련 docs의 ML 표현 감사/정정
2. 텍스트 자름/줄바꿈 정책 작업
3. `START_HERE.md` 기준 문서 진입점 점검과 planning 문서 파편화 점검
4. 실제 ML 이행
5. 경제 probe 마감 여부 정리
6. 공모전 기준 남은 작업 재개

## 1. ML 표현 감사/정정

Status: Done

Done:

- [x] `analysis/leveling/`, `tools/leveling/`, 관련 docs에서 “실제 ML 완료”처럼 읽히는 표현을 감사했다.
- [x] pre-outcome 산출물을 `planned transition scaffold`, `not production ML`, `runtime 자동 적용 아님`으로 정정했다.
- [x] 새 pre-outcome 산출물이 있어도 아직 runtime 자동 조정이 아님을 문서화했다.

## 2. 텍스트 자름/줄바꿈 정책 작업

Status: Done

Done:

- [x] `lib` 전체의 `maxLines`, `softWrap: false`, `FittedBox.scaleDown`, `TextOverflow.*`, `Clip.*` 위험 지점을 분류했다.
- [x] `GameCardNameText`는 이름 텍스트를 `maxLines: null`, `softWrap: true`, `TextOverflow.visible`로 고정했다.
- [x] 상점 offer/장착 슬롯/전투 보유 창/Jester 슬롯의 이름 cap을 제거했다.
- [x] 상점 상세 설명은 `maxLines` 제거와 내부 `SingleChildScrollView`로 처리했다.
- [x] 설명 텍스트와 아이템 이름 회귀 테스트를 갱신했다.

남은 리스크:

- HUD 숫자, 짧은 배지, 슬롯 라벨에는 `maxLines: 1`과 `FittedBox.scaleDown`이 남아 있다.
- 이는 현재 허용 구간이지만, 실제 QA에서 시인성이 떨어지면 폰트 축소가 아니라 레이아웃 공간 확보로 수정한다.

## 3. 문서 진입점/파편화 점검

Status: Done

Done:

- [x] `START_HERE.md`의 먼저 읽을 문서 목록과 Source of Truth가 current 문서와 충돌하지 않는지 확인했다.
- [x] `docs/planning/00_planning_README.md`를 current / legacy / temporary 문서 분류로 정리했다.
- [x] `STATUS.md`는 기존 진행 snapshot으로 두고, 필요한 최신 항목 승격 전 archive 이동 금지로 유지했다.
- [x] current 문서와 V4 spec의 잔여 `STATUS.md`/legacy planning 참조를 다시 감사했다.
- [x] 잔여 current 참조 수정 후 `rg`로 `STATUS.md`/`IMPLEMENTATION_PLAN.md`/`MIGRATION_ROADMAP.md`가 current source-of-truth처럼 남아 있지 않은지 재확인했다.

확인 결과:

- `START_HERE.md`와 `docs/planning/00_planning_README.md`는 current source-of-truth와 legacy/temporary 분류가 일치한다.
- 남아 있는 `STATUS.md`/`IMPLEMENTATION_PLAN.md`/`MIGRATION_ROADMAP.md` 참조는 legacy/snapshot/compatibility 안내 또는 archive/daily log 이력이다.

## 4. 실제 ML 이행

Status: Done for offline candidate recommendation gate, not production ML

완료:

- [x] 기존 휴리스틱/시뮬레이션 summary를 pre-outcome feature table로 확장했다.
- [x] station/tier group table은 13,113 row까지 증량했다.
- [x] sequence/path table은 기존 heuristic summary와 fresh target/economy probe를 포함해 80 row로 만들었다.
- [x] `path_clear_rate` 기준 sequence model을 별도로 학습했다.
- [x] 모델 추천표를 생성했다.
- [x] target 후보 grid와 economy 후보를 fresh r80 resimulation으로 검증했다.
- [x] 사람 승인용 MD 분석 보고서를 작성했다.
- [x] 사람 승인 전 runtime target/boss/market/economy 값은 바꾸지 않았다.

완료로 오해하면 안 되는 것:

- production ML 자동 밸런싱은 아직 없다.
- 모델이 runtime 값을 직접 패치하지 않는다.
- sequence/path 데이터는 아직 80 row라 장기 자동화 근거로 부족하다.

현재 산출물:

- `analysis/leveling/data/features/leveling_preoutcome_feature_table.csv`
- `analysis/leveling/data/features/leveling_preoutcome_sequence_feature_table.csv`
- `analysis/leveling/models/clear_rate_preoutcome_metrics.json`
- `analysis/leveling/models/path_clear_rate_preoutcome_sequence_metrics.json`
- `analysis/leveling/models/preoutcome_candidate_recommendations.csv`
- `analysis/leveling/reports/preoutcome_baseline_model_report.md`
- `analysis/leveling/reports/preoutcome_sequence_baseline_model_report.md`
- `analysis/leveling/reports/preoutcome_candidate_recommendation_report.md`
- `analysis/leveling/reports/actual_ml_transition_human_review.md`
- `logs/sim/ml_actual_target_grid_v1_r80_summary.json`
- `logs/sim/ml_actual_economy_r040_p220_v1_r80_summary.json`
- `logs/sim/ml_actual_economy_r040_p240_v1_r80_summary.json`

## 5. 경제 Probe 마감 여부 정리

Status: Done as not closed

현재 판단:

- 출품용 baseline은 `good enough`로 유지할 수 있다.
- 그러나 Jester/Slots와 Tool/Gear lane reroll 분리 이후 경제 영향은 아직 닫지 않았다.
- post lane reroll probe는 exploratory/not closed다.
- ML transition fresh economy r80에서도 balanced+v9가 none보다 낮은 경우가 있어 경제 gate를 완료로 올리면 안 된다.

확인 완료:

- [x] lane split 이후 기준 fresh r80 economy probe를 실행했다.
- [x] v9 market clear가 balanced none보다 낮아지는 신호를 확인했다.
- [x] 결과를 `ECONOMY_LEVELING_PLAN.md`와 `OVERALL_GOAL_PROGRESS.md`에 반영했다.

남은 일:

- [ ] r400 이상으로 reroll spend, final gold, S8 boss 시작 골드, S1/S2/S3/S7/S8 병목, board locked/draw exhausted를 닫는다.

## 6. 공모전 기준 남은 작업 재개

Status: Blocked

차단 이유:

- post lane reroll 경제 probe가 아직 not closed다.

재개 조건:

- [x] 실제 ML 이행의 추천/재시뮬레이션/사람 승인용 보고서가 완료 또는 명시 보류된다.
- [ ] 경제 probe가 완료 또는 출품 기준 명시 보류로 정리된다.
- [ ] 그 다음 공모전 기준 Boss pool expansion, 텍스트/UX/QA 작업으로 돌아간다.

공모전용으로 포함된 추가 작업:

- [ ] 원본 28개 boss pattern을 우리 게임 룰 패턴으로 매핑한다.
- [ ] 현재 10개 simulation proxy / 8개 runtime modifier와 겹치는 것, 새로 흡수 가능한 것, 금지할 것을 분류한다.
- [ ] 출품 안정성을 해치지 않는 1차 boss pool 확장 범위를 확정한다.
