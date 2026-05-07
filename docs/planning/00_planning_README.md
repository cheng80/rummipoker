# planning Folder Definition

`docs/planning/`은 실행 상태와 작업 계획을 담는 폴더다.

GCSE 역할: `Execution`

## Purpose

- 현재 완료/미완료 상태를 추적한다.
- 다음 작업 우선순위를 관리한다.
- 구현 계획, 체크리스트, 검증 절차와 결과를 둔다.

현재 작업 순서 source-of-truth는 `ACTIVE_EXECUTION_PLAN.md`다.
전체 Goal 진도는 `goal/OVERALL_GOAL_PROGRESS.md`, 공모전 제출 실행표는 `competition/COMPETITION_SUBMISSION_CHECKLIST.md`를 따른다.
오래된 `legacy/STATUS.md`, `legacy/IMPLEMENTATION_PLAN.md`, `legacy/MIGRATION_ROADMAP.md`, `legacy/TEMP_WORK_SEQUENCE_PLAN.md`는 현재 실행 판단 기준이 아니다.

## Folder Layout

| 경로 | 역할 |
|---|---|
| `ACTIVE_EXECUTION_PLAN.md` | 현재 활성 트랙과 다음 작업을 고르는 실행 라우터 |
| `competition/` | 공모전 제출 기준 실행 체크리스트 |
| `goal/` | 실제 제품 Goal 기준 전체 진도와 장기 track |
| `leveling/` | 레벨링/경제/휴리스틱/ML 전환 상태 |
| `feature_plans/` | 기능별 runtime matrix, open decision, 연출 후보 |
| `legacy/` | 과거 V4 status, migration, 순서 lock snapshot |
| `verification/` | QA, smoke, build 절차와 검증 로그 |

## Current Source-Of-Truth Documents

| 문서 | 역할 |
|---|---|
| `ACTIVE_EXECUTION_PLAN.md` | 현재 활성 트랙, 다음 작업, 보류 트랙 |
| `competition/COMPETITION_SUBMISSION_CHECKLIST.md` | 공모전 제출 전 실행 체크리스트 |
| `competition/COMPUTE_BROWSER_FULL_PLAY_BOT.md` | Browser/WebDriver + Compute Use hybrid 공모전 full-play bot 제작 기준 |
| `goal/OVERALL_GOAL_PROGRESS.md` | 전체 Goal 진도, 장기 완성 track |
| `leveling/LEVELING_APPLIED_STATUS.md` | 레벨링 실험이 실제 런타임에 반영된 상태 |
| `leveling/ECONOMY_LEVELING_PLAN.md` | 경제/가격/리롤 probe 계획과 상태 |
| `DOCUMENTATION_CONSOLIDATION_PLAN.md` | 문서 정리 순서와 archive 보류 기준 |
| `feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md` | 아이템 runtime hook 적용 상태 |
| `leveling/HEURISTIC_LEVELING_SIMULATION_DIRECTION.md` | 현재 휴리스틱/시뮬레이션 레벨링 진입 요약 |

## Legacy Or Compatibility Documents

| 문서 | 취급 |
|---|---|
| `legacy/STATUS.md` | 과거 V4 진행 snapshot. 현재 status처럼 읽지 않는다 |
| `legacy/IMPLEMENTATION_PLAN.md` | 과거 대형 실행 계획. 남은 항목 확인 후 정리 |
| `legacy/MIGRATION_ROADMAP.md` | 과거 migration roadmap. 현재 blocker 승격 여부 확인 후 정리 |
| `leveling/ML_LEVELING_SIMULATION_DIRECTION.md` | deprecated compatibility path. 현재 기준은 `leveling/HEURISTIC_LEVELING_SIMULATION_DIRECTION.md` |

## Temporary Documents

- `legacy/TEMP_WORK_SEQUENCE_PLAN.md`는 과거 작업 순서 lock snapshot이다.
- 현재 실행 판단은 `ACTIVE_EXECUTION_PLAN.md`를 따른다.
- 사람 검토 승인 전에는 삭제하지 않는다.

## Allowed Documents

- 현재 status
- implementation plan
- migration roadmap
- item effect runtime matrix
- open decisions and experiments
- smoke/build verification guide
- daily verification history
- test/QA acceptance criteria

Risk register와 traceability matrix를 새 문서로 늘릴 때는 먼저 `ACTIVE_EXECUTION_PLAN.md`, `goal/OVERALL_GOAL_PROGRESS.md`나 해당 current 문서 안에 흡수 가능한지 확인한다.

## Not Allowed

- 장기 제품 방향만 담은 문서
- 기능 규칙의 원본 명세
- 현재 코드 전체 설명
- 과거 참고 문서 원문
- 완료된 feature plan 스냅샷
- 긴 레벨링 시뮬레이션 이력 원문

기능 기준은 `docs/specs/`, 현재 코드 설명은 `docs/current_system/`을 참조한다.
현재 레벨링 정책은 `docs/current_system/CURRENT_LEVELING_POLICY.md`를 참조한다.
과거 feature plan과 레벨링 로그는 `docs/archive/`에서 검색한다.
