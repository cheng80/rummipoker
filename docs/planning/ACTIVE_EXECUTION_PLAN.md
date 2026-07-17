# Active Execution Plan

> 역할: 지금 진행 중인 일, 다음에 할 일, 막힌 이유, 완료 근거만 적는다. 게임 규칙은 [core 문서](../core/GAME_DESIGN.md), 정확한 콘텐츠 목록은 [generated catalog](../generated/CONTENT_CATALOG.md), 역기획·비교·BM 내용은 [REVERSE_DESIGN_SYNTHESIS.md](REVERSE_DESIGN_SYNTHESIS.md)가 맡는다.

## Planning Ownership

계획 문서는 다음 네 개만 기준으로 사용한다.

| 문서 | 소유하는 정보 |
|---|---|
| `ACTIVE_EXECUTION_PLAN.md` | current active track, next action, blocker, Done evidence |
| [OPEN_DECISIONS.md](OPEN_DECISIONS.md) | code/test로 미결임이 확인된 선택지만 |
| [REVERSE_DESIGN_SYNTHESIS.md](REVERSE_DESIGN_SYNTHESIS.md) | 역기획 비교·재미 후보·BM 권고 요약 |
| [TEST_QA_ACCEPTANCE.md](verification/TEST_QA_ACCEPTANCE.md) | 반복 실행 가능한 검증 절차와 acceptance |

## 지금 진행 중인 일

| Track | 상태 | 결과 |
|---|---|---|
| Documentation authority consolidation | Closed / Done | core 7개, generated 2개, retained planning과 entry point 수렴 |
| Reverse design research and doc refresh | Closed / Done | core Known Gaps 반영, synthesis/BM 정리, docs structure·generate 검증 PASS. 구현 수정은 별도 track |
| P0 reward/settlement/save trust | Closed / Done | runtime·회귀 테스트, 전체 자동 검증, 최신 web Computer Use 실기 QA PASS |

## 다음에 할 일

1. 광고/IAP 구현은 비즈니스 결정 없이는 시작하지 않는다.

## 막힌 점

- 광고 파일럿은 consent/ledger/analytics 선행 게이트와 비즈니스 결정이 필요하다.

## 완료 근거

문서 authority consolidation은 이전 작업에서 완료했다. 상세 기록은 작업 브랜치의 `.omo` 임시 자료에만 남기며, 현재 문서의 계약은 아래 core 문서가 기준이다.

역기획 문서 보강:

- core Known Gaps: GAME_DESIGN, RUN_ECONOMY, UI_UX, SAVE_DATA, CONTENT_SYSTEM, SYSTEM_ARCHITECTURE
- synthesis: [REVERSE_DESIGN_SYNTHESIS.md](REVERSE_DESIGN_SYNTHESIS.md)
- research session: `.omo/ulw-research/20260717-071150/`

P0 reward/settlement/save trust:

- 전체 `flutter test`, `flutter analyze`, 문서 구조 검사, `git diff --check`, production `flutter build web` PASS
- Computer Use: New Run 직후 이어하기 생성 PASS
- Computer Use: cash-out 후 Market 재진입 전후 Gold 11 유지, 중복 보상 없음 PASS
- Computer Use: Market Gold 11·Jester 4개 상태가 Title→이어하기 후 동일하게 복원됨 PASS
