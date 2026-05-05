# planning Folder Definition

`docs/planning/`은 실행 상태와 작업 계획을 담는 폴더다.

GCSE 역할: `Execution`

## Purpose

- 현재 완료/미완료 상태를 추적한다.
- 다음 작업 우선순위를 관리한다.
- 구현 계획, 체크리스트, 검증 절차와 결과를 둔다.

현재 작업 순서와 전체 진도 source-of-truth는 `OVERALL_GOAL_PROGRESS.md`다. 오래된 `STATUS.md`, `IMPLEMENTATION_PLAN.md`, `MIGRATION_ROADMAP.md`는 바로 이동하지 않고, 필요한 내용이 current source-of-truth로 승격됐는지 확인한 뒤 정리한다.

## Current Source-Of-Truth Documents

| 문서 | 역할 |
|---|---|
| `OVERALL_GOAL_PROGRESS.md` | 전체 진도, 현재 작업 순서, 공모전 gate |
| `LEVELING_APPLIED_STATUS.md` | 레벨링 실험이 실제 런타임에 반영된 상태 |
| `ECONOMY_LEVELING_PLAN.md` | 경제/가격/리롤 probe 계획과 상태 |
| `DOCUMENTATION_CONSOLIDATION_PLAN.md` | 문서 정리 순서와 archive 보류 기준 |
| `ITEM_EFFECT_RUNTIME_MATRIX.md` | 아이템 runtime hook 적용 상태 |
| `HEURISTIC_LEVELING_SIMULATION_DIRECTION.md` | 현재 휴리스틱/시뮬레이션 레벨링 진입 요약 |

## Legacy Or Compatibility Documents

| 문서 | 취급 |
|---|---|
| `STATUS.md` | `START_HERE.md`가 읽던 기존 진행 snapshot. 필요한 최신 항목 승격 전 archive 이동 금지 |
| `IMPLEMENTATION_PLAN.md` | 과거 대형 실행 계획. 남은 항목 확인 후 정리 |
| `MIGRATION_ROADMAP.md` | 과거 migration roadmap. 현재 blocker 승격 여부 확인 후 정리 |
| `ML_LEVELING_SIMULATION_DIRECTION.md` | deprecated compatibility path. 현재 기준은 `HEURISTIC_LEVELING_SIMULATION_DIRECTION.md` |

## Temporary Documents

- `TEMP_WORK_SEQUENCE_PLAN.md`는 현재 작업 순서를 잠그기 위한 임시 문서다.
- 모든 항목이 완료되고 결과가 source-of-truth 문서에 반영되면 삭제한다.
- 임시 문서를 새 source-of-truth로 승격하지 않는다.

## Allowed Documents

- 현재 status
- implementation plan
- migration roadmap
- item effect runtime matrix
- open decisions and experiments
- smoke/build verification guide
- daily verification history
- test/QA acceptance criteria

Risk register와 traceability matrix를 새 문서로 늘릴 때는 먼저 `OVERALL_GOAL_PROGRESS.md`나 해당 current 문서 안에 흡수 가능한지 확인한다.

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
