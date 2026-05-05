# Documentation Consolidation Plan

> 문서 성격: next work plan / documentation governance
> 기준 문서: `docs/planning/OVERALL_GOAL_PROGRESS.md`
> 목적: 파편화된 planning/current/archive 문서를 다시 한 기준으로 정리한다.

## 1. 현재 문제

- 레벨링, 경제, ML, 출품 준비 문서가 여러 위치에 나뉘어 있다.
- `ML`이 들어간 과거 파일명과 현재 휴리스틱 파이프라인 문서가 섞여 실제 머신러닝 적용처럼 오해될 수 있다.
- archive 문서와 current 문서의 경계가 약해, 과거 폐기 후보가 현재 정책처럼 읽힐 위험이 있다.
- 공모전 기준 작업 큐와 전체 goal 진도표가 같은 문서에서 항상 동기화되지 않는다.

## 2. 정리 원칙

- current source-of-truth는 `docs/current_system/`와 `docs/planning/OVERALL_GOAL_PROGRESS.md`에 둔다.
- 과거 실험 로그, 폐기 후보, 장기 히스토리는 `docs/archive/`에 둔다.
- 실제 런타임 적용 여부는 `docs/planning/LEVELING_APPLIED_STATUS.md`에 기록한다.
- 경제 실행 계획은 `docs/planning/ECONOMY_LEVELING_PLAN.md`로 유지하되, 완료/보류/탐색 상태를 명확히 적는다.
- 실제 ML 전환 전까지 `ML` 명칭이 있는 문서는 호환 경로 또는 스캐폴딩으로 표시한다.

## 3. 작업 순서

1. 문서 inventory 작성
   - `docs/current_system/`
   - `docs/planning/`
   - `docs/archive/`
   - `analysis/leveling/`

2. source-of-truth 지정
   - 현재 정책
   - 런타임 기준표
   - 적용 상태
   - 경제 계획
   - 공모전 진도
   - ML/휴리스틱 분석 상태

3. archive 이동 후보 분류
   - 오래된 계획
   - 현재 정책과 충돌하는 실험안
   - 완료된 임시 QA 기록
   - 실제 ML이 아닌데 ML 적용처럼 읽히는 과거 보고서

4. 문서 링크 정리
   - current 문서 상단에 기준/후속/과거 문서 링크를 맞춘다.
   - archive 문서에는 현재 기준이 아니라는 표시를 둔다.

5. 공모전 작업 큐 복귀
   - 텍스트 자름/줄바꿈 정책 QA
   - browser/compute QA
   - 출품 후보 smoke

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
| `docs/current_system/CURRENT_LEVELING_ML_BASELINE.md` | 과거 경로 호환용 deprecated 안내 | 유지하되 실제 ML 기준으로 인용 금지 |

### Planning

| 문서 | 현재 역할 | 정리 판단 |
|---|---|---|
| `docs/planning/OVERALL_GOAL_PROGRESS.md` | 전체 진도와 다음 작업 순서 source-of-truth | 유지 |
| `docs/planning/LEVELING_APPLIED_STATUS.md` | 레벨링 적용 상태 | 유지 |
| `docs/planning/ECONOMY_LEVELING_PLAN.md` | 경제 레벨링 실행 계획 | 유지, probe 완료/미완료 상태 갱신 필요 |
| `docs/planning/HEURISTIC_LEVELING_SIMULATION_DIRECTION.md` | ML 명칭 정정 후 active summary | 유지 |
| `docs/planning/ML_LEVELING_SIMULATION_DIRECTION.md` | 과거 경로 호환용 deprecated 안내 | 유지하되 current 링크만 제공 |
| `docs/planning/DOCUMENTATION_CONSOLIDATION_PLAN.md` | 문서 정리 작업 계획 | 현재 작업 후 archive 또는 유지 판단 |
| `docs/planning/ANIMATION_EFFECTS_PLAN.md` | 연출 작업 계획 | 출품 큐와 연결해 유지 |
| `docs/planning/ITEM_EFFECT_RUNTIME_MATRIX.md` | Item hook 적용 상태 | 유지 |
| `docs/planning/OPEN_DECISIONS.md` | 열린 결정 목록 | 검토 후 current open decision만 남김 |
| `docs/planning/STATUS.md` | 과거 V4 status snapshot | archive 이동 후보 |
| `docs/planning/IMPLEMENTATION_PLAN.md` | 과거 대형 실행 계획 | archive 이동 후보. current 진행은 `OVERALL_GOAL_PROGRESS.md`로 대체 |
| `docs/planning/MIGRATION_ROADMAP.md` | 과거 migration roadmap | archive 이동 후보 |
| `docs/planning/verification/` | 검증 절차와 QA 기록 | 유지. 오래된 daily log는 archive 후보 |

### Analysis

| 문서/폴더 | 현재 역할 | 정리 판단 |
|---|---|---|
| `analysis/leveling/README.md` | 분석 폴더 성격 구분 | 유지 |
| `analysis/leveling/data/raw/` | 선택된 summary snapshot | 유지하되 원본 provenance 명확화 |
| `analysis/leveling/data/features/` | ML 전환 스캐폴딩 feature table | 유지 |
| `analysis/leveling/models/` | 설명 baseline metric | 유지하되 runtime 적용 근거로 사용 금지 |
| `analysis/leveling/reports/` | 분석/전환 요구사항 리포트 | 유지 |
| `analysis/leveling/notebooks/` | 사람이 읽는 분석 노트북 | 유지 |

## 5. Source-Of-Truth Map

| 주제 | 기준 문서 | 보조/이력 |
|---|---|---|
| 전체 작업 순서 | `docs/planning/OVERALL_GOAL_PROGRESS.md` | `docs/planning/DOCUMENTATION_CONSOLIDATION_PLAN.md` |
| 레벨링 정책 | `docs/current_system/CURRENT_LEVELING_POLICY.md` | `docs/archive/leveling/` |
| 런타임 target/boss/market 표 | `docs/current_system/CURRENT_LEVELING_RUNTIME_SPEC.md` | `docs/planning/LEVELING_APPLIED_STATUS.md` |
| 시뮬레이션/휴리스틱 기준 | `docs/current_system/CURRENT_LEVELING_SIMULATION_BASELINE.md` | `docs/planning/HEURISTIC_LEVELING_SIMULATION_DIRECTION.md` |
| 경제 계획 | `docs/planning/ECONOMY_LEVELING_PLAN.md` | `tools/sim/economy_audit.py`, `logs/sim/` |
| 실제 적용 여부 | `docs/planning/LEVELING_APPLIED_STATUS.md` | 테스트/커밋 이력 |
| ML 전환 상태 | `analysis/leveling/README.md`, `analysis/leveling/reports/leveling_analysis_methodology.md` | `docs/current_system/CURRENT_LEVELING_ML_BASELINE.md` |
| 공모전 작업 큐 | `docs/planning/OVERALL_GOAL_PROGRESS.md` | browser/compute QA 기록 |

## 6. 다음 Archive 후보

아래 문서는 바로 삭제하지 않는다. 다음 문서 정리 작업에서 링크 참조를 확인한 뒤 `docs/archive/` 하위로 이동하거나, 상단에 snapshot 표시를 더한다.

| 후보 | 이유 | 선행 확인 |
|---|---|---|
| `docs/planning/STATUS.md` | 현재 source-of-truth처럼 읽히지만 실제로는 과거 V4 snapshot | current 문서에서 필요한 최신 항목이 남아 있는지 확인 |
| `docs/planning/IMPLEMENTATION_PLAN.md` | 대형 계획이 현재 진행표와 중복 | 남은 미완료 항목이 `OVERALL_GOAL_PROGRESS.md`로 승격됐는지 확인 |
| `docs/planning/MIGRATION_ROADMAP.md` | migration 중심 과거 계획 | 현재 migration blocker가 남아 있는지 확인 |
| 오래된 `docs/planning/verification/daily_logs/` | 검증 이력은 필요하지만 current planning를 흐릴 수 있음 | latest QA만 current에 요약됐는지 확인 |

## 7. 완료 조건

- 새 세션에서 `OVERALL_GOAL_PROGRESS.md`만 읽어도 현재 작업 순서를 알 수 있다.
- 레벨링 정책은 `CURRENT_LEVELING_POLICY.md`와 충돌하지 않는다.
- 실제 ML 전환은 미완료 상태로 남고, 스캐폴딩과 본 구현이 분리되어 읽힌다.
- archive 문서를 현재 적용 근거로 오해하지 않는다.
