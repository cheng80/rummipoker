# planning Folder Definition

`docs/planning/`은 실행 상태와 작업 계획을 담는 폴더다.

GCSE 역할: `Execution`

## Purpose

- 현재 완료/미완료 상태를 추적한다.
- 다음 작업 우선순위를 관리한다.
- 구현 계획, 체크리스트, 검증 절차와 결과를 둔다.

## Allowed Documents

- 현재 status
- implementation plan
- migration roadmap
- item effect runtime matrix
- open decisions and experiments
- smoke/build verification guide
- daily verification history
- test/QA acceptance criteria

Risk register와 traceability matrix는 별도 파일로 늘리지 않고 `IMPLEMENTATION_PLAN.md` 안에 둔다.

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
