# Docs Organization

이 문서는 `docs/` 전체의 문서 분류 기준이다.

문서는 목적형 폴더로 배치하고, 각 폴더 정의서에 대응하는 `GCSE` 역할을 명시한다.

- `goals`: Goal, 제품 목표, 방향성, 의사결정 원칙
- `current_system`: Context, 현재 코드/시스템 상태와 배경 맥락
- `specs`: Spec, 기능 규칙, UX, 데이터 계약, 아키텍처 명세
- `planning`: Execution, 진행 상태, 구현 계획, 체크리스트, 검증 절차
- `archive`: 최신 판단 기준은 아니지만 이력 검색에 사용할 수 있는 과거 자료, 생성 산출물, 과거 프롬프트

## Source of Truth

최신 판단은 아래 순서로 한다.

1. 실제 코드와 테스트
2. `START_HERE.md`
3. `docs/00_docs_README.md`
4. `docs/current_system/*`
5. `docs/planning/*`
6. `docs/specs/*`
7. `docs/archive/*`

문서는 현재 목적형 폴더 기준으로 배치한다. 새 문서도 같은 기준으로 추가한다.

## Code Continuation Rule

새 작업자는 코드 기준 문서 3종만 읽어도 작업을 이어갈 수 있어야 한다.

현재 3종은 아래다.

1. `docs/current_system/CURRENT_SYSTEM_OVERVIEW.md`
2. `docs/current_system/CURRENT_CODE_MAP.md`
3. `docs/current_system/CURRENT_TO_V4_GAP.md`

이 3종은 `current_system`의 핵심 문서이며, 아래를 판단할 수 있어야 한다.

- 현재 앱이 실제로 구현한 기능
- 먼저 읽어야 할 코드 파일과 책임 경계
- 현재 코드에서 보호해야 할 불변 규칙
- V4 목표와 현재 코드 사이의 차이
- 다음 구현이 어떤 코드 영역을 건드릴 가능성이 높은지

`planning`은 진행률과 다음 작업을 보완하지만, 코드 기준 사실을 대신하지 않는다. 진행 문서가 코드 기준 문서와 충돌하면 실제 코드와 `current_system`을 우선 확인한다.

## Baseline Document Rule

기준 문서는 아래 조건을 만족해야 한다.

- 문서만 읽어도 해당 폴더의 목적과 사용 제한을 알 수 있어야 한다.
- 폴더 정의서는 `00_` prefix와 폴더명을 파일명에 포함한다.
- `current_system` 기준 문서는 작업 재개에 필요한 코드 지도와 보호 규칙을 포함한다.
- 기준 문서가 실제 코드와 어긋났다고 판단되면, 코드 확인 후 기준 문서를 먼저 갱신한다.

## Update Rule

- 진행률, 완료/미완료, 다음 작업은 `planning` 문서에 둔다.
- 기능 규칙과 계약은 `specs` 문서에 둔다.
- 현재 코드의 사실 설명과 작업 재개에 필요한 코드 지도는 `current_system` 문서에 둔다.
- 제품 방향과 금지 원칙은 `goals` 문서에 둔다.
- 중복 문서는 바로 삭제하지 않고 `archive` 후보로 표시한 뒤 링크를 정리한다.

## Folder Boundary Rule

문서 위치는 파일 이름보다 목적을 우선한다.

| 목적 | 위치 |
|---|---|
| 제품 목표, 금지 원칙, 의사결정 기준 | `docs/goals/` |
| 현재 코드 사실, 코드 맵, 작업 재개 기준 | `docs/current_system/` |
| 기능 규칙, UX/데이터/아키텍처 계약 | `docs/specs/` |
| 진행 상태, 구현 순서, open decision, 테스트 게이트 | `docs/planning/` |
| 과거 문서, 병합본, 중복 요약, 프롬프트 | `docs/archive/` |

`specs`에는 현재 baseline 원본, roadmap, QA 실행 계획, open decision, changelog, master summary를 두지 않는다. 해당 문서는 각각 `current_system`, `planning`, `archive`로 분리한다.
