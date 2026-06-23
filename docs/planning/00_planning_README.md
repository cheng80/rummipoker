# planning Folder Definition

`docs/planning/`은 현재 실행 판단, 남은 작업 선택, 검증 절차만 담는 폴더다.

GCSE 역할: `Execution`

## Current Rule

- 현재 실행 라우터는 `ACTIVE_EXECUTION_PLAN.md` 하나다.
- 완료된 대형 feature plan, 과거 큐, prompt, 긴 검증 로그는 archive 폴더로 내리고 active 문서에서 직접 링크하지 않는다.
- `planning` 문서는 코드 사실이나 기능 계약을 대신하지 않는다. 코드 사실은 `docs/current_system/`, 기능 계약은 `docs/specs/`를 우선한다.

## Folder Layout

| 위치 | 역할 |
| --- | --- |
| `ACTIVE_EXECUTION_PLAN.md` | 현재 활성 트랙과 다음 작업 선택 |
| `goal/` | 장기 Goal 진행 상태와 남은 목표 |
| `leveling/` | 현재 레벨링/경제/휴리스틱 적용 상태 |
| `feature_plans/` | 아직 current 판단에 필요한 기능별 실행 문서 |
| `verification/` | QA, smoke, acceptance 기준 |

## Current Feature Plan Boundary

`feature_plans/`에 남기는 문서는 아래 성격이어야 한다.

- 현재 catalog, item policy, runtime matrix, open decision처럼 다음 구현 판단에 직접 필요하다.
- active plan에서 현재 트랙이나 가까운 side track으로 참조한다.
- 완료 이력만 남은 문서는 archive 폴더로 옮긴다.

현재 완료 이력으로 내린 문서:

- 특수 타일 V1/V2 완료 이력
- 족보 성장과 런 정보 완료 이력
- superseded runtime queue

## Update Rule

- 구현 상태만 바뀌면 해당 feature/goal/leveling 문서를 갱신한다.
- 현재 활성 트랙이 바뀌면 `ACTIVE_EXECUTION_PLAN.md`를 갱신한다.
- 긴 날짜별 검증 로그는 archive 폴더에만 둔다.
