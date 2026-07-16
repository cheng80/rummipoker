# START_HERE

이 문서는 새 세션의 3분 진입 지도이자 프로젝트 문서의 최상위 진입점이다.
게임 사실은 코드·데이터·테스트와 `docs/core/`가 소유한다.

## 현재 위치

- 현재 흐름은 post-contest 런타임 고도화와 문서 권위 수렴이다.
- 다음 실행 판단은 `docs/planning/ACTIVE_EXECUTION_PLAN.md`가 소유한다.
- 역기획 비교·재미 후보·광고 BM 요약은 `docs/planning/REVERSE_DESIGN_SYNTHESIS.md`가 소유한다.
- Planning은 이 문서 아래에서 현재 작업만 고르며 진입 순서를 대체하지 않는다.
- Release는 빌드·배포·스토어·홍보를 위한 별도 문서군이며 여기서 연결하지 않는다.

## 기본 진입 순서

새 작업은 아래 네 단계만 기본으로 읽는다.

1. [START_HERE](START_HERE.md)
2. [GAME_DESIGN](docs/core/GAME_DESIGN.md)
3. [SYSTEM_ARCHITECTURE](docs/core/SYSTEM_ARCHITECTURE.md)
4. [ACTIVE_EXECUTION_PLAN](docs/planning/ACTIVE_EXECUTION_PLAN.md)

네 번째 문서는 current active track, next action, blocker, Done evidence만 보완한다.
구현 사실이 필요하면 planning 설명을 늘리지 말고 관련 core와 source를 확인한다.

## 작업별 추가 문서

- 전투 규칙·족보·확정·Boss 제약: [GAME_RULES](docs/core/GAME_RULES.md)
- 성장·골드·정산·Market: [RUN_ECONOMY](docs/core/RUN_ECONOMY.md)
- Jester·Item·Tile modifier·Boss family: [CONTENT_SYSTEM](docs/core/CONTENT_SYSTEM.md)
- 화면·튜토리얼·연출·사운드·다국어: [UI_UX](docs/core/UI_UX.md)
- 저장·복원·재시작·무결성: [SAVE_DATA](docs/core/SAVE_DATA.md)
- 정확한 Jester·Item 목록: [CONTENT_CATALOG](docs/generated/CONTENT_CATALOG.md)
- 정확한 Boss board pattern: [BOSS_PATTERNS](docs/generated/BOSS_PATTERNS.md)

필요한 주제 문서만 추가로 읽는다.
Generated 표는 목록 확인용이며 source나 core 계약을 대신하지 않는다.

## 판단 우선순위

1. 실제 코드·데이터·테스트
2. 프로젝트 작업 규칙인 `AGENTS.md`
3. 현재 계약을 설명하는 `docs/core/`
4. 다음 행동과 미결 결정을 설명하는 `docs/planning/`

Generated 문서는 source에서 만든 검증 가능한 projection으로 사용한다.
문서와 source가 충돌하면 source를 확인하고 소유 문서를 같은 변경에서 갱신한다.
진행률과 완료 이력을 core나 이 문서에 복제하지 않는다.
새 문서를 만들기 전에 기존 authority 문서의 책임인지 먼저 확인한다.
