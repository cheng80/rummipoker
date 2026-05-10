# Active Execution Plan

> 문서 성격: 현재 실행 라우터
> 기준: 문서 진입과 읽는 순서는 `START_HERE.md`를 따른다. 이 문서는 `planning` 단계에서 현재 어떤 트랙을 실행할지 정한다.

이 문서는 공모전 기준 완성과 실제 Goal 기준 완성을 분리한다.
새 세션은 `START_HERE.md`와 `current_system` 기준 문서를 읽은 뒤, 이 문서에서 현재 활성 트랙과 다음 작업만 확인한다.

## 1. 현재 활성 트랙

| Track | Status | 기준 문서 | 지금 판단 |
|---|---|---|---|
| 공모전 기준 완성 | Active for challenge full-run | `docs/planning/competition/COMPETITION_SUBMISSION_CHECKLIST.md` | 2026-05-09 최신 룰/UI 후보에서 `contest_full_run_bot` fresh 표준 S1~S8 boss 통과 증거를 확보했다. 2026-05-10에는 도전 난이도 fresh S1~S8 Boss 5개 locale full-run을 제외하고 최근 24시간 내 룰/UI/문서/튜토리얼 항목과 Flutter semantics 경고 보정을 최신 build/test/smoke로 검증했다. S8 boss 이후는 임시 계속 진행이 아니라 정식 `무한 도전` 진입 UX와 S9+ target 산식으로 정리했다. |
| 실제 Goal 기준 완성 | Runtime rule V1 landed | `docs/planning/goal/OVERALL_GOAL_PROGRESS.md` | 족보 레벨 성장, 덱 추가, 히든 족보 V1, 보스 클리어 덱 타일 보상, 타일 구매 연출/선택 표시 보강, 타이틀 로고/서브타이틀, 전투/마켓 튜토리얼 V1, submission kit 문서화는 반영됐다. 장기 밸런스와 스토어 최종 산출물은 별도 트랙으로 남긴다. |

현재는 공모전 기준 QA를 재개한다. 다음 남은 gate는 도전 난이도 fresh S1~S8 Boss `contest_full_run_bot` full-run을 지원 locale 5개(`ko`, `en`, `ja`, `zh-CN`, `zh-TW`) 각각 1회씩 실행하는 것이다. 단, 5개 locale을 한 번에 연속 실행하지 않는다. 각 locale full-run 완료 후 로그/console/UI 결함을 점검하고 사용자 승인받은 뒤 다음 locale을 시작한다. 플레이 범위는 S8 Boss 클리어와 S8 정산/보상/무한 도전 진입 직전 확인까지이며, S9+ 무한 도전 장기 생존은 별도 확장 검증이다.

## 2. 공모전 기준 다음 작업

상세 체크리스트는 `docs/planning/competition/COMPETITION_SUBMISSION_CHECKLIST.md`를 따른다.
현재 실행 순서는 아래로 고정한다.

1. `contest_full_run_bot`을 도전 난이도 fresh S1부터 최신 build 기준으로 실행한다. locale 순서는 `ko` -> `en` -> `ja` -> `zh-CN` -> `zh-TW`다. 각 locale은 완료/점검/사용자 승인 후 다음 locale로 넘어간다.
2. 각 locale 실행 전 저장 세션/SharedPreferences를 지워 첫 전투/첫 Market 튜토리얼이 표시되는 조건으로 시작한다.
   - bot은 튜토리얼 overlay가 보이면 전투/마켓 액션보다 `Next/Done` 완료를 먼저 처리하고, fresh locale gate에서는 전투/마켓 튜토리얼 완료 로그가 없으면 pass로 인정하지 않는다.
   - fresh locale 실행은 WebDriver Chrome profile의 cookie/localStorage/sessionStorage도 초기화한다. `--resume-active-run`이 아닌 실행은 browser profile dir을 지운 뒤 시작한다.
3. 도전 full-run 도중 실패하면 game over/retry/checkpoint 로그를 먼저 확인한다.
4. 실패 원인이 policy 문제면 문서만 바꾸지 말고 policy code/test를 먼저 고친 뒤 재실행한다.
5. game over가 아니어도 UI overflow, 튜토리얼 target/문구 문제, Jester/Item/자원 카드 제목·설명 잘림, 다국어 텍스트 넘침이 발견되면 제출 QA 결함으로 수정하고 해당 locale gate를 다시 실행한다.
6. 도전 full-run 도중 세션이 종료되면 마지막 로그/출력 디렉터리/checkpoint를 먼저 확인하고, debug fixture 없이 이어서 진행한다.

최근 `contest_full_run_bot` 기준선:

- 최신 fresh 표준 실행 로그: `/tmp/rummipoker_contest_full_run_bot/fresh_after_reward_tile_rules_20260509_201727/10_contest_full_run_bot.log`
- 실행 조건: `--seed 91460 --difficulty standard --web-port 7362 --skip-pub-get`
- 결과: `CONTEST_FULL_RUN_BOT_PASS`, `All tests passed!`, S8 boss run complete
- S8 boss 정산: `870/3 -> 728/2 -> 312/1`, 목표 `1739` 통과
- game over/retry: 없음
- 보스 클리어 덱 타일 보상: S2 `deck=53`부터 S8 `deck=59`까지 증가 확인
- 당시 남은 문제: `Semantic node ... scopesRoute and namesRoute ... missing the label` Flutter semantics 경고가 반복 출력됐다. 2026-05-10 보정 후 최신 build smoke에서는 재현되지 않았다.

최근 2026-05-10 검증:

- `flutter analyze` 통과
- 핵심 `flutter test` 묶음 통과
- `flutter build web` 통과
- Browser/CDP smoke 통과: `/`, `/new-run`, `/archive`, `/game?fixture=game_over_insight_ready&debug_show_game_over_on_load=1`, `/game?fixture=final_boss_cash_out_ready&debug_complete_run_on_load=1` 모두 앱 warn/error/exception 0건
- Flutter semantics route label 경고는 dialog/bottom sheet route label 보정 뒤 최신 build smoke에서 재현되지 않음
- Headless Chrome의 `Falling back to CPU-only rendering`은 WebGL 없는 headless 환경 경고라 앱 경고로 집계하지 않음
- `contest_full_run_bot` market policy는 `*_study` 같은 직접 족보 성장 아이템과 Tool/Gear lane 구매 후보를 평가하도록 code/test 동기화 완료
- S8 boss 이후 `무한 도전 진입` CTA를 표시하고, S9+는 Scout 1배, Clash 1.5배, Boss 2배 target 비율에 station 상승률을 적용한다. Station Select, 전투 HUD, 정산 라벨은 `무한 도전` 색상과 경고 톤으로 표시한다.
- 타이틀 로고 이미지와 서브타이틀 `타일로 만드는 포커 런` 적용 완료
- `docs/submission_kit/` 제출 문서 세트 정리 완료. Android/iOS 실제 release artifact 생성은 아직 제출 전 별도 gate다.
- 전투/마켓 튜토리얼 V1은 `tutorial_coach_mark`로 구현. `flutter analyze`, 핵심 widget test, `flutter build web` 통과. 리사이즈 후 focus 크기 눈검증은 아직 남아 있다.

## 3. 공모전 Done Evidence

공모전 트랙은 기능 존재만으로 닫지 않는다.
아래 증거가 있어야 제출 후보로 본다.

- `flutter analyze` 통과
- 핵심 `flutter test` 통과
- 최신 `flutter build web` 통과
- Browser/WebDriver full-play QA에서 최신 빌드 기준 console error/warn 0건
- Browser/WebDriver + Compute Use hybrid bot으로 debug fixture 없이 도전 S1~S8 Boss clear 확인: `ko`, `en`, `ja`, `zh-CN`, `zh-TW` 각각 fresh 세션
- full-play 중 마켓 구매와 아이템 실제 사용 증거 확인
- 게임오버/런 완료 보상, 도감, 새 run 복귀가 심사자에게 설명 없이 읽힌다는 눈검증
- 전투/마켓 튜토리얼이 첫 진입/다시 보기/포커스 아웃/옵션 겹침/창 크기 변경에서 깨지지 않는다는 눈검증. full-run locale gate에서는 각 실행 전 세션을 지워 첫 전투/첫 Market 튜토리얼도 함께 확인한다.

## 4. 지금 시작하지 않는 작업

아래 항목은 실제 Goal 기준 완성 트랙으로 넘긴다.

- 장기 multi-seed r400/r800 밸런스 확정
- ML 리포트 갱신과 NotebookLM용 재가공
- production ML 또는 runtime 자동 밸런싱
- 신규 대형 UI 구조 변경
- 전체 카탈로그 가격 2차 재산정
- 반복 플레이용 해금 tree와 run modifier 깊이 확장

예외적으로 지금 시작하는 작업:

- 족보 완성 시 족보 자체가 성장하는 최소 런타임 규칙: 반영 완료
- 그 규칙에 필요한 저장/복원/정산 테스트: 반영 완료
- 게임 중/게임 밖에서 언제든 족보 성장 상태를 확인하는 `런 정보` 화면 또는 동등한 UI: 반영 완료
- Planet-like 직접 족보 성장 아이템군과 초과 클리어 대표 족보 성장 보너스: 반영 완료
- `handGrowthStates(level/progress/requiredProgress)` 분리: 반영 완료. `playedHandCounts`는 완성 횟수/Jester 통계용으로 유지하고 점수 성장 source를 분리했다.
- 타이틀의 `런 정보` 직접 진입점과 게임오버 런 요약/랜덤 도발 문구: 반영 완료. 정산 progress bar는 이번 범위에서 제외한다.
- 타이틀 로고/서브타이틀, submission kit 문서화, 전투/마켓 튜토리얼 V1: 반영 완료. 튜토리얼 리사이즈 눈검증은 남김.
- 새 run까지 이어지는 영구 계승은 이번 1차 범위에서 제외하고 별도 검토로 남긴다.
- 공모전 풀런봇이 성장한 족보를 평가하도록 하는 bot 정책 동기화

## 5. 문서 교통정리

| 필요 | 읽을 문서 |
|---|---|
| 전체 문서 흐름과 읽는 순서 | `START_HERE.md` |
| docs 폴더 분류 규칙 | `docs/00_docs_README.md` |
| 현재 코드 사실과 보호 규칙 | `docs/current_system/*` |
| 현재 실행 트랙 선택 | `docs/planning/ACTIVE_EXECUTION_PLAN.md` |
| 공모전 제출 세부 체크 | `docs/planning/competition/COMPETITION_SUBMISSION_CHECKLIST.md` |
| 공모전 full-play bot 제작 기준 | `docs/planning/competition/COMPUTE_BROWSER_FULL_PLAY_BOT.md` |
| 실제 Goal 전체 진도 | `docs/planning/goal/OVERALL_GOAL_PROGRESS.md` |
| 장기 레벨링/경제 적용 상태 | `docs/planning/leveling/*` |
| 과거 V4/migration 순서 lock | `docs/planning/legacy/*` |

`docs/planning/legacy/*`는 현재 실행 판단 기준이 아니다.
