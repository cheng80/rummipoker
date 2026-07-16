# Active Execution Plan

> 역할: 현재 실행 상태, 다음 행동, blocker, Done evidence만 기록한다. 현재 구현 계약은 [core 문서](../core/GAME_DESIGN.md)가, 정확한 콘텐츠 목록은 [generated catalog](../generated/CONTENT_CATALOG.md)가 소유한다.

## Planning Ownership

Retained planning 문서는 다음 세 개만 canonical로 사용한다.

| 문서 | 소유하는 정보 |
|---|---|
| `ACTIVE_EXECUTION_PLAN.md` | current active track, next action, blocker, Done evidence |
| [OPEN_DECISIONS.md](OPEN_DECISIONS.md) | code/test로 미결임이 확인된 선택지만 |
| [TEST_QA_ACCEPTANCE.md](verification/TEST_QA_ACCEPTANCE.md) | 반복 실행 가능한 검증 절차와 acceptance |

## Current Active Track

| Track | 상태 | 결과 |
|---|---|---|
| Documentation authority consolidation | Closed / Done | core 7개, generated 2개, retained planning 3개와 entry point 3개로 수렴했고 superseded prose의 non-release 참조가 0임을 확인했다. |
| 현재 active track | None | 사용자 결정 없이 새 product 작업을 시작하지 않는다. |

## Next Action

현재 next action은 없다. 사용자가 새 작업을 결정하면 별도 plan을 만든다. 실제 미결 선택지를 진행하는 경우에는 [OPEN_DECISIONS.md](OPEN_DECISIONS.md)에서 대상을 선택한 뒤 별도 plan으로 범위를 확정한다.

## Blocker

- 없음.
- active track이 없는 것은 blocker가 아니다.

## Done Evidence

문서 authority consolidation은 종료되었다.

- [Entrypoint 전환 검증](../../.omo/evidence/reverse-design-doc-consolidation/task-7-entrypoints.md)
- [Superseded prose 제거 및 최종 검증](../../.omo/evidence/reverse-design-doc-consolidation/task-8-delete-cleanup.md)
