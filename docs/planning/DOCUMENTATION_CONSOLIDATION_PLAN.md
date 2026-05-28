# Documentation Consolidation Plan

> 문서 성격: next work plan / documentation governance
> 기준 문서: `docs/planning/ACTIVE_EXECUTION_PLAN.md`
> 목적: 파편화된 planning/current/archive 문서를 다시 한 기준으로 정리한다.

## 1. 현재 문제

- 레벨링, 경제, ML, 출품 준비 문서가 `docs/planning/` 하위 역할별 폴더로 1차 분리됐다.
- `ML`이 들어간 과거 파일명과 현재 휴리스틱 파이프라인 문서가 섞여 실제 머신러닝 적용처럼 오해될 수 있다.
- archive 문서와 current 문서의 경계가 약해, 과거 폐기 후보가 현재 정책처럼 읽힐 위험이 있다.
- 공모전 기준 작업 큐와 전체 goal 진도표는 `ACTIVE_EXECUTION_PLAN.md`를 통해 연결한다.

## 2. 정리 원칙

- 문서 정리는 `START_HERE.md`의 새 세션 진입 경로를 먼저 맞춘 뒤 진행한다.
- 현재 실행 source-of-truth는 `docs/planning/ACTIVE_EXECUTION_PLAN.md`에 둔다.
- 실제 Goal 전체 진도는 `docs/planning/goal/OVERALL_GOAL_PROGRESS.md`에 둔다.
- current code fact source-of-truth는 `docs/current_system/`에 둔다.
- 과거 실험 로그, 폐기 후보, 장기 히스토리는 `docs/archive/`에 둔다.
- 실제 런타임 적용 여부는 `docs/planning/leveling/LEVELING_APPLIED_STATUS.md`에 기록한다.
- 경제 실행 계획은 `docs/planning/leveling/ECONOMY_LEVELING_PLAN.md`로 유지하되, 완료/보류/탐색 상태를 명확히 적는다.
- 실제 ML 전환 전까지 `ML` 명칭이 있는 문서는 호환 경로 또는 스캐폴딩으로 표시한다.
- `START_HERE.md`가 아직 읽는 문서는 archive 후보로 확정하지 않는다. 필요한 내용이 current source-of-truth로 승격되고 진입 경로가 바뀐 뒤에만 이동 여부를 판단한다.

## 3. 작업 순서

0. 새 세션 진입 경로 정렬: 적용됨
   - `START_HERE.md`의 먼저 읽을 문서 목록
   - `START_HERE.md`의 Source of Truth
   - 새 세션 시작 지시문

1. 문서 inventory 작성: 적용됨
   - `docs/current_system/`
   - `docs/planning/`
   - `docs/archive/`
   - `analysis/leveling/`

2. source-of-truth 지정: 적용됨
   - 현재 실행 라우터
   - 현재 정책
   - 런타임 기준표
   - 적용 상태
   - 경제 계획
   - 공모전 진도
   - ML/휴리스틱 분석 상태

3. archive 이동 후보 보류/분류: 1차 적용
   - 오래된 계획
   - 현재 정책과 충돌하는 실험안
   - 완료된 임시 QA 기록
   - 실제 ML이 아닌데 ML 적용처럼 읽히는 과거 보고서
   - 2026-05-29 기준 구 planning/ML 호환 문서는 archive로 이동했다.

4. 문서 링크 정리: 진행 중
   - current 문서 상단에 기준/후속/과거 문서 링크를 맞춘다.
   - archive 문서에는 현재 기준이 아니라는 표시를 둔다.

5. 공모전 작업 큐 복귀
   - `docs/planning/ACTIVE_EXECUTION_PLAN.md`의 공모전 기준 다음 작업을 따른다.

## 4. 문서 Inventory

### Current System

| 문서 | 현재 역할 | 정리 판단 |
|---|---|---|
| `docs/current_system/00_current_system_README.md` | current_system 폴더 규칙 | 유지 |
| `docs/current_system/CURRENT_SYSTEM_OVERVIEW.md` | 현재 시스템 개요 | 유지 |
| `docs/current_system/CURRENT_CODE_MAP.md` | 현재 코드 맵 | 유지 |
| `docs/current_system/CURRENT_TO_V4_GAP.md` | 현재 구현과 목표 차이 | 유지 |
| `docs/current_system/CURRENT_BUILD_BASELINE.md` | 빌드 baseline 보조 | 유지 |
| `docs/current_system/CURRENT_LEVELING_POLICY.md` | 레벨링 정책 source-of-truth | 유지 |
| `docs/current_system/CURRENT_LEVELING_RUNTIME_SPEC.md` | 런타임 레벨링 표 | 유지 |
| `docs/current_system/CURRENT_LEVELING_SIMULATION_BASELINE.md` | 시뮬레이션/휴리스틱 기준 | 유지 |
| `docs/archive/leveling/deprecated_2026_05/CURRENT_LEVELING_ML_BASELINE.md` | 과거 경로 호환용 deprecated 안내 | archive. 실제 ML 기준으로 인용 금지 |

### Planning

| 문서 | 현재 역할 | 정리 판단 |
|---|---|---|
| `docs/planning/ACTIVE_EXECUTION_PLAN.md` | 현재 활성 트랙과 다음 작업 source-of-truth | 유지 |
| `docs/planning/competition/COMPETITION_SUBMISSION_CHECKLIST.md` | 공모전 제출 실행표 | 유지 |
| `docs/planning/goal/OVERALL_GOAL_PROGRESS.md` | 전체 Goal 진도와 장기 track | 유지 |
| `docs/planning/leveling/LEVELING_APPLIED_STATUS.md` | 레벨링 적용 상태 | 유지 |
| `docs/planning/leveling/ECONOMY_LEVELING_PLAN.md` | 경제 레벨링 실행 계획 | 유지, probe 완료/미완료 상태 갱신 필요 |
| `docs/planning/leveling/HEURISTIC_LEVELING_SIMULATION_DIRECTION.md` | ML 명칭 정정 후 active summary | 유지 |
| `docs/planning/DOCUMENTATION_CONSOLIDATION_PLAN.md` | 문서 정리 작업 계획 | 이번 정리 이력으로 유지 |
| `docs/planning/feature_plans/ANIMATION_EFFECTS_PLAN.md` | 연출 작업 계획 | 출품 큐와 연결해 유지 |
| `docs/planning/feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md` | Item hook 적용 상태 | 유지 |
| `docs/planning/feature_plans/OPEN_DECISIONS.md` | 열린 결정 목록 | 검토 후 current open decision만 남김 |
| `docs/planning/verification/` | 검증 절차와 QA 기록 | 유지. 오래된 daily log는 archive 후보 |
| `docs/archive/planning_legacy_2026_05/` | 과거 V4 진행/migration/순서 lock snapshot | archive. 현재 실행 판단 기준 아님 |
| `docs/archive/leveling/deprecated_2026_05/` | 과거 레벨링/ML 호환 문서와 boss pool mapping | archive. 현재 실행 판단 기준 아님 |

### Analysis

| 문서/폴더 | 현재 역할 | 정리 판단 |
|---|---|---|
| `analysis/leveling/README.md` | 새 fresh ML/레벨링 workspace 성격 구분 | 유지 |
| `analysis/leveling/data/raw/` | 앞으로 새 fresh simulation 원본을 선별 저장할 위치 | 구 snapshot 제거 완료 |
| `analysis/leveling/data/features/` | 앞으로 새 feature metadata를 둘 위치 | 구 metadata 제거 완료 |
| `analysis/leveling/models/` | 앞으로 새 모델/metric을 둘 위치 | 구 모델 제거 완료 |
| `analysis/leveling/reports/` | 앞으로 새 분석/전환 보고서를 둘 위치 | 구 리포트 제거 완료 |
| `docs/archive/leveling/legacy_ml_outputs_2026_05/` | 구 tracked ML/레벨링 산출물 archive | historical prior로만 사용 |
| `analysis/leveling/archive/legacy_pre_20260529/` | 구 generated feature CSV 로컬 archive | git 추적 제외 |
| `logs/archive/legacy_pre_20260529/sim/` | 구 `logs/sim` 로컬 archive | git 추적 제외 |

## 5. Source-Of-Truth Map

| 주제 | 기준 문서 | 보조/이력 |
|---|---|---|
| 새 세션 진입 경로 | `START_HERE.md` | `docs/00_docs_README.md` |
| 현재 실행 트랙과 다음 작업 | `docs/planning/ACTIVE_EXECUTION_PLAN.md` | `docs/planning/DOCUMENTATION_CONSOLIDATION_PLAN.md` |
| 실제 Goal 전체 진도 | `docs/planning/goal/OVERALL_GOAL_PROGRESS.md` | `docs/goals/V4_PRODUCT_GOAL.md` |
| 공모전 제출 실행표 | `docs/planning/competition/COMPETITION_SUBMISSION_CHECKLIST.md` | browser/compute QA 기록 |
| 레벨링 정책 | `docs/current_system/CURRENT_LEVELING_POLICY.md` | `docs/archive/leveling/` |
| 런타임 target/boss/market 표 | `docs/current_system/CURRENT_LEVELING_RUNTIME_SPEC.md` | `docs/planning/leveling/LEVELING_APPLIED_STATUS.md` |
| 시뮬레이션/휴리스틱 기준 | `docs/current_system/CURRENT_LEVELING_SIMULATION_BASELINE.md` | `docs/planning/leveling/HEURISTIC_LEVELING_SIMULATION_DIRECTION.md` |
| 경제 계획 | `docs/planning/leveling/ECONOMY_LEVELING_PLAN.md` | `tools/sim/economy_audit.py`, `logs/sim/` |
| 실제 적용 여부 | `docs/planning/leveling/LEVELING_APPLIED_STATUS.md` | 테스트/커밋 이력 |
| ML 전환 상태 | `analysis/leveling/README.md` | `docs/archive/leveling/deprecated_2026_05/`, `docs/archive/leveling/legacy_ml_outputs_2026_05/` |

## 6. 다음 Archive 보류 후보

아래 문서는 바로 삭제하거나 archive로 보내지 않는다. 먼저 `START_HERE.md`와 current 문서의 참조를 확인하고, 필요한 내용을 current source-of-truth로 승격한 뒤 `docs/archive/` 하위로 이동하거나 상단에 snapshot 표시를 더한다.

| 후보 | 이유 | 선행 확인 |
|---|---|---|
| 오래된 `docs/planning/verification/daily_logs/` | 검증 이력은 필요하지만 current planning를 흐릴 수 있음 | latest QA만 current에 요약됐는지 확인 |

## 7. 완료 조건

- 새 세션에서 `ACTIVE_EXECUTION_PLAN.md`만 읽어도 현재 활성 트랙과 다음 작업을 알 수 있다.
- `START_HERE.md`의 기본 읽기 경로와 이 문서의 source-of-truth map이 서로 충돌하지 않는다.
- 레벨링 정책은 `CURRENT_LEVELING_POLICY.md`와 충돌하지 않는다.
- 실제 ML 전환은 미완료 상태로 남고, 스캐폴딩과 본 구현이 분리되어 읽힌다.
- archive 문서를 현재 적용 근거로 오해하지 않는다.
