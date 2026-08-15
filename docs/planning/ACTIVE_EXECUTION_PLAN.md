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

## 현재 실행 상태

| Track | 상태 | 다음 판단 |
|---|---|---|
| 현재 활성 구현 track | 없음 / 선택 필요 | [OD-02·OD-03](OPEN_DECISIONS.md) 중 하나를 해결하거나 release 준비를 시작한다 |
| release 준비 | 미완료 | [출시 체크리스트](../release/submission_kit/RELEASE_CHECKLIST.md)의 build·실기 QA·store 항목을 처리한다 |
| 광고/IAP | 보류 | 비즈니스 결정과 선행 gate 없이는 시작하지 않는다 |

## 다음에 할 일

1. 다음 활성 track을 [OPEN_DECISIONS.md](OPEN_DECISIONS.md)의 OD-02·OD-03 또는 [출시 체크리스트](../release/submission_kit/RELEASE_CHECKLIST.md) 중에서 고른다.
2. release 준비를 고르면 최신 build에서 analyze, test, build, 실기 QA, full-run 증거를 새로 남긴다.
3. 광고/IAP 구현은 비즈니스 결정 없이는 시작하지 않는다.

## 다음 작업 Done 기준

- 선택한 track의 범위, acceptance, 검증 방법을 구현 전에 확정한다.
- OD-02·OD-03을 고르면 code와 test로 결정을 증명하고 [OPEN_DECISIONS.md](OPEN_DECISIONS.md)에서 닫는다.
- release 준비를 고르면 [출시 체크리스트](../release/submission_kit/RELEASE_CHECKLIST.md)를 최신 release candidate 기준으로 실행한다.
- 실행 증거는 다시 확인할 수 있는 경로에 보존하고 임시 `/tmp` 경로만 완료 근거로 사용하지 않는다.

## 막힌 점

- 활성 track을 아직 고르지 않았다. 구현을 막는 확인된 기술 blocker는 없다.
- 광고 파일럿은 consent/ledger/analytics 선행 gate와 비즈니스 결정이 필요하다.
- `en → ja → zh-CN → zh-TW`는 사용자 지시로 실제 실행을 생략했으므로 해당 locale의 runtime QA 증거는 없다.

## 최근 완료 근거

- 문서 authority consolidation과 역기획 정리는 core 7개, generated 2개, planning과 [START_HERE](../../START_HERE.md) 수렴으로 닫았다.
- P0 reward/settlement/save trust는 commit `1a356bb`의 runtime·회귀 테스트와 문서로 닫았다.
- Market 저장·복원 복구는 PR #14, squash merge `36052cf5`로 닫았다.
- `ko` 표준·도전 S1~S8 locale gate 결과는 [ko_cycle_review.md](verification/ko_cycle_review.md)에 요약했다. 당시 임시 실행 경로는 보존되지 않았으므로 release 제출 증거가 필요하면 다시 실행한다.
