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
| 풀런봇 Market 저장·복원 복구 | Closed / Done | DWDS 이중 Chrome 경로 제거, Cash-out→Market 구매→새 Chrome Continue 복원 결과를 기록한 PR #14 병합 |

## 다음에 할 일

1. `ko` release locale gate 완료 결과를 유지한다.
2. `en → ja → zh-CN → zh-TW` gate는 2026-07-18 사용자 지시에 따라 실제 실행 없이 통과 처리한다.
3. 광고/IAP 구현은 비즈니스 결정 없이는 시작하지 않는다.

## 다음 gate Done 기준

- 실제 실행 범위인 `ko`는 표준·도전 run이 S1~S8을 끝내고 S8 정산 직전 증거를 남긴다.
- `ko` fresh 표준 run에서 첫 Battle·Market tutorial을 실제 `Next/Done`으로 완료한다.
- `ko` Market 구매와 Continue 복원에서 Gold, Jester·Item, 추가 덱 타일 상태를 검토한다.
- `ko`에서 overflow, 잘림, tutorial target, sound, save/restore 결함이 없고 종료 뒤 관련 프로세스가 남지 않는다.
- `ko` 실행 명령, seed, locale, difficulty/modifier, checkpoint 여부, trace, console, screenshot와 정산 결과를 기록한다.
- `en → ja → zh-CN → zh-TW`는 2026-07-18 사용자 지시로 실제 실행을 생략하고 통과 처리한다.

## 막힌 점

- 광고 파일럿은 consent/ledger/analytics 선행 게이트와 비즈니스 결정이 필요하다.
- `en → ja → zh-CN → zh-TW`는 사용자 지시로 실제 실행을 생략했으므로 해당 locale의 runtime QA 증거는 없다.

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

풀런봇 Market 저장·복원 복구:

- runner: `flutter drive -d web-server`, persistent Chrome `user-data-dir`, `market_persistence` fresh/resume 2단계 gate
- targeted tests 62개, `flutter analyze`, `bash -n tools/full_run_bot.sh`, production `flutter build web` PASS
- PR #14 실기 기록: S1 Scout Cash-out 뒤 Market Gold 19→1, Jester 3개와 추가 덱 타일 구매
- PR #14 실기 기록: 새 Chrome Title `계속하기→이어하기` 뒤 scene `shop`, Gold 1, Jester 3개, 추가 덱 타일 동일 복원
- 병합: PR #14, squash merge `36052cf5`

ko release locale gate:

- 표준 fresh S1~S8 PASS: `/tmp/rummipoker_full_run_bot/release_locale_gate/20260718/ko_standard_fresh_retry2/`
- 도전 S1~S8 및 S8 boss 정산 직전 PASS: `/tmp/rummipoker_full_run_bot/release_locale_gate/20260718/ko_challenge_retry4_profile/`
- cycle 검토: [ko_cycle_review.md](verification/ko_cycle_review.md)
- 사용자 범위 변경: `en → ja → zh-CN → zh-TW`는 실제 실행 없이 통과 처리
