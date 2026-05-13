# Active Execution Plan

> 문서 성격: 현재 실행 라우터
> 기준: 문서 진입과 읽는 순서는 `START_HERE.md`를 따른다. 이 문서는 `planning` 단계에서 현재 어떤 트랙을 실행할지 정한다.

이 문서는 공모전 기준 완성과 실제 Goal 기준 완성을 분리한다.
새 세션은 `START_HERE.md`와 `current_system` 기준 문서를 읽은 뒤, 이 문서에서 현재 활성 트랙과 다음 작업만 확인한다.

## 1. 현재 활성 트랙

| Track | Status | 기준 문서 | 지금 판단 |
|---|---|---|---|
| 공모전 기준 완성 | Closed for submission QA handoff | `docs/planning/competition/COMPETITION_SUBMISSION_CHECKLIST.md` | 2026-05-09 최신 룰/UI 후보에서 `contest_full_run_bot` fresh 표준 S1~S8 boss 통과 증거를 확보했다. 2026-05-10에는 최근 24시간 내 룰/UI/문서/튜토리얼 항목과 Flutter semantics 경고 보정을 최신 build/test/smoke로 검증했고, `ko`, `en` locale 표준→도전 2사이클도 통과했다. 이후 잠긴 Jester/Quick Item/Passive 슬롯 해금 룰, Market 진입 연출, 시스템 locale 기본값, `slot_unlock_market` debug fixture, web icon/splash/OG image, 릴리즈 메뉴, 웹 BGM unlock/scroll 묵음, 정산 밑줄, 정산 dialog PhoneFrame 폭 회귀를 보강했다. 2026-05-10~11 최신 후보에서 `ko` standard→challenge 재확인을 다시 통과했으므로, 공모전 제출용 풀런봇 플랜은 여기서 닫는다. `ja`, `zh-CN`, `zh-TW`는 문제가 발견될 때 또는 공모전 이후 추가 검증으로 둔다. |
| 실제 Goal 기준 완성 | Runtime rule V1 landed | `docs/planning/goal/OVERALL_GOAL_PROGRESS.md` | 족보 레벨 성장, 덱 추가, 히든 족보 V1, 보스 클리어 덱 타일 보상, 타일 구매 연출/선택 표시 보강, 타이틀 로고/서브타이틀, 전투/마켓 튜토리얼 V1, submission kit 문서화는 반영됐다. 장기 밸런스와 스토어 최종 산출물은 별도 트랙으로 남긴다. |

현재는 공모전 기준 풀런봇 QA 플랜을 제출용 handoff 상태로 닫았다. 한 locale 사이클 기준은 fresh 표준 난이도 S1~S8 Boss 클리어, 이어서 같은 locale fresh 도전 난이도 S1~S8 Boss 클리어와 S8 정산/보상/무한 도전 진입 직전 확인까지다. `ko`, `en` cycle은 2026-05-10에 완료했고, S2/S4/S6 Boss 보상 슬롯 해금, Market 해금 연출, 시스템 locale 기본값, debug fixture, web 제출 산물/BGM/메뉴/정산 UI 회귀 수정 뒤 2026-05-10~11 최신 후보에서 `ko` standard→challenge 재확인도 통과했다. `ja`, `zh-CN`, `zh-TW` full-run은 제출 gate 필수 대기열에서 내리고, 문제가 발견될 때 또는 공모전 이후 추가 검증으로 잡는다. S9+ 무한 도전 장기 생존은 계속 별도 확장 검증이다.

2026-05-14 제출 전 상점 회귀 수정도 닫았다. 보유 Jester/Item/Passive 판매 시 명시적 리롤 없이 오퍼 리스트가 바뀌지 않게 했고, Jester 오퍼 구매 후 남은 오퍼 가격이 0G로 튀던 stale slot index 경로를 막았다. 첫 무료 Jester 리롤은 다음 Market에서 다시 복원되지 않도록 저장/복원 상태까지 보강했으며, 구매 할인은 원가/할인가/`할인` 배지로 UI에 드러난다. 검증은 `rummi_market_facade_test`, `item_definition_test`, `item_effect_runtime_test`, `game_session_notifier_test`, `game_shop_discount_badge_test`, `game_shop_sell_offer_stability_test`와 `market_discount_visual_bot` 상점 시각 매트릭스로 완료했다. 시각 매트릭스는 7개 fresh Chrome/Flutter drive 시나리오로 할인 Jester 구매/판매, 할인 Item offer 표시, Passive 판매 후 offer 유지, 리롤 할인/피드백, 비할인 Jester/Item 가격 표시, 슬롯 해금 Market 상태를 확인한다. 최신 로그는 `/tmp/rummipoker_market_discount_visual_bot/matrix_full_20260514_060908/10_market_discount_visual_bot.log`이며 `MARKET_DISCOUNT_VISUAL_BOT_PASS` 7건과 `All tests passed!` 7건을 기록했다. 이 수정은 full-run gate 재개 근거가 아니라 제출 전 발견된 상점 회귀의 로직/위젯/시각 회귀 방지다.

## 2. 공모전 기준 다음 작업

상세 체크리스트는 `docs/planning/competition/COMPETITION_SUBMISSION_CHECKLIST.md`를 따른다.
현재 실행 순서는 아래로 고정한다.

1. 완료: `contest_full_run_bot` `ko` locale 표준 난이도 fresh S1~S8 Boss full-run 통과.
2. 완료: 같은 `ko` cycle 내부의 도전 난이도 fresh S1부터 S8 Boss와 S8 정산/보상/무한 도전 진입 직전 확인 통과.
3. 완료: `contest_full_run_bot` `en` locale 표준 난이도 fresh S1~S8 Boss full-run 통과.
4. 완료: 같은 `en` cycle 내부의 도전 난이도 fresh S1부터 S8 Boss와 S8 정산/보상/무한 도전 진입 직전 확인 통과.
5. 완료: 잠긴 슬롯 해금 룰을 S2/S4/S6 Boss 보상으로 연결하고, Market 진입 시 해금 연출을 보여준 뒤 전투에는 해금된 슬롯 상태로 들어가게 했다.
6. 완료: 앱 기본 언어는 OS/브라우저 시스템 locale을 따르도록 `startLocale` 강제를 제거했고, `slot_unlock_market` debug fixture를 추가했다.
7. 완료: `/game?fixture=slot_unlock_market`에서 자동 튜토리얼 없이 해금 배너/슬롯 pulse를 눈검증했다. 자물쇠 확대/fade-out과 pulse가 1회 보이는 기준으로 조정했고, 반복 재생은 실제 플레이와 다르므로 넣지 않는다.
8. 완료: web 제출 산물에 icon/splash/OG image를 반영하고, 릴리즈 진입 메뉴에서 debug/special 메뉴가 보이지 않게 정리했다. 웹 BGM은 첫 터치/버튼 tap에서 unlock되고, 스크롤 중 같은 BGM을 stop/play 반복하지 않게 보정했다.
9. 완료: 정산 sheet 텍스트의 노란 밑줄 회귀를 `TextDecoration` 상속 차단으로 수정했고, `showGeneralDialog` 정산 overlay가 desktop/web에서 PhoneFrame 밖 전체 폭으로 새는 회귀를 `PhoneFrame` 제약과 landscape widget test로 막았다.
10. 완료: 최신 후보에서 `ko` standard→challenge 재확인을 통과했으므로 공모전 제출용 풀런봇 플랜은 닫는다. `ja`, `zh-CN`, `zh-TW`는 문제가 발견될 때 또는 공모전 이후 추가 검증으로 둔다.
11. 향후 문제 발생 또는 공모전 이후 locale cycle을 추가 검증할 때는 standard 실행 전 저장 세션/SharedPreferences를 지워 첫 전투/첫 Market 튜토리얼이 표시되는 조건으로 시작한다. 같은 locale의 challenge 실행은 새 도전 run으로 시작하되 같은 cycle 내부 진행이므로 battle/market tutorial seen 상태는 유지한다.
   - bot은 튜토리얼 overlay가 보이면 전투/마켓 액션보다 `Next/Done` 완료를 먼저 처리하고, fresh locale gate에서는 전투/마켓 튜토리얼 완료 로그가 없으면 pass로 인정하지 않는다.
   - fresh locale standard 실행은 WebDriver Chrome profile의 cookie/localStorage/sessionStorage도 초기화한다. 같은 locale challenge 실행은 active run/save를 새로 시작하되 tutorial seen flag는 유지하거나 bot 옵션으로 다시 세팅한다.
12. full-run 도중 실패하면 game over/retry/checkpoint 로그를 먼저 확인한다.
13. 실패 원인이 policy 문제면 문서만 바꾸지 말고 policy code/test를 먼저 고친 뒤 재실행한다.
14. game over가 아니어도 UI overflow, 튜토리얼 target/문구 문제, Jester/Item/자원 카드 제목·설명 잘림, 다국어 텍스트 넘침이 발견되면 제출 QA 결함으로 수정하고 해당 locale gate를 다시 실행한다.
15. full-run 도중 세션이 종료되면 마지막 로그/출력 디렉터리/checkpoint를 먼저 확인하고, debug fixture 없이 이어서 진행한다.

최근 `contest_full_run_bot` 기준선:

- 2026-05-10 `ko` fresh 표준 locale gate 로그: `/tmp/rummipoker_contest_full_run_bot/standard_ko_20260510_104511/10_contest_full_run_bot.log`
- 출력 디렉터리: `/tmp/rummipoker_contest_full_run_bot/standard_ko_20260510_104511`
- 실행 조건: `--seed 91460 --difficulty standard --locale ko --web-port 7363 --browser-profile-dir /tmp/rummipoker_contest_full_run_bot/standard_ko_profile_20260510_104511 --output-dir /tmp/rummipoker_contest_full_run_bot/standard_ko_20260510_104511 --skip-pub-get`
- 결과: `CONTEST_FULL_RUN_BOT_PASS`, `All tests passed!`, S8 boss run complete
- locale/fresh 조건: `locale=ko`, `resolvedLocale=ko`, `freshStorage=true`
- 튜토리얼: 첫 battle tutorial completed, 첫 market tutorial completed
- S8 boss 정산: `951/3 -> 778/2 -> 246/1`, 목표 `1739` 통과
- game over/retry/Flutter semantics warning/UI overflow/error/warn: 없음
- 보스 클리어 덱 타일 보상: S2 `deck=53`부터 S8 `deck=59`까지 증가 확인
- 종료 후 WebDriver Chrome, Chrome Helper, ChromeDriver, Flutter web 서버 잔류 프로세스 없음

- 2026-05-10 `ko` fresh 도전 locale gate 로그: `/tmp/rummipoker_contest_full_run_bot/challenge_ko_20260510_115046/10_contest_full_run_bot.log`
- 출력 디렉터리: `/tmp/rummipoker_contest_full_run_bot/challenge_ko_20260510_115046`
- 실행 조건: `--seed 91460 --difficulty challenge --locale ko --web-port 7364 --browser-profile-dir /tmp/rummipoker_contest_full_run_bot/challenge_ko_profile_20260510_115046 --output-dir /tmp/rummipoker_contest_full_run_bot/challenge_ko_20260510_115046 --tutorials-already-seen --skip-pub-get`
- 결과: `CONTEST_FULL_RUN_BOT_PASS`, `All tests passed!`, S8 boss run complete
- locale/fresh 조건: `locale=ko`, `resolvedLocale=ko`, `freshStorage=true`, `difficulty=challenge`
- 튜토리얼: 같은 locale cycle 내부 challenge 실행이므로 `--tutorials-already-seen`으로 battle/market tutorial seen 상태를 유지했다. fresh 튜토리얼 완료 로그는 이 실행에서 요구하지 않는다.
- S8 small 정산: `1622/2 -> 230/1`, 목표 `1729` 통과
- S8 big 정산: `1009/2 -> 1032/2 -> 368/1`, 목표 `2086` 통과
- S8 boss 정산: `1010/3 -> 869/2 -> 312/1`, 목표 `2087` 통과
- S8 시작 덱: `deck=59`
- game over/retry/Flutter semantics warning/UI overflow/error/warn: 없음
- 종료 후 WebDriver Chrome, Chrome Helper, ChromeDriver, Flutter web 서버 잔류 프로세스 없음

- 2026-05-10 `en` fresh 표준 locale gate 로그: `/tmp/rummipoker_contest_full_run_bot/standard_en_20260510_140623/10_contest_full_run_bot.log`
- 출력 디렉터리: `/tmp/rummipoker_contest_full_run_bot/standard_en_20260510_140623`
- 실행 조건: `--seed 91460 --difficulty standard --locale en --web-port 7365 --browser-profile-dir /tmp/rummipoker_contest_full_run_bot/standard_en_profile_20260510_140623 --output-dir /tmp/rummipoker_contest_full_run_bot/standard_en_20260510_140623 --skip-pub-get`
- 결과: `CONTEST_FULL_RUN_BOT_PASS`, `All tests passed!`, S8 boss run complete
- locale/fresh 조건: `locale=en`, `resolvedLocale=en`, `freshStorage=true`
- 튜토리얼: 첫 battle tutorial completed, 첫 market tutorial completed
- S8 small 정산: `1539/2`, 목표 `1441` 통과
- S8 big 정산: `902/2 -> 925/2`, 목표 `1738` 통과
- S8 boss 정산: `951/3 -> 778/2 -> 246/1`, 목표 `1739` 통과
- S8 시작 덱: `deck=59`
- game over/retry/Flutter semantics warning/UI overflow/error/warn: 없음
- 종료 후 WebDriver Chrome, Chrome Helper, ChromeDriver, Flutter web 서버 잔류 프로세스 없음

- 2026-05-10 `en` fresh 도전 locale gate 로그: `/tmp/rummipoker_contest_full_run_bot/challenge_en_20260510_145813/10_contest_full_run_bot.log`
- 출력 디렉터리: `/tmp/rummipoker_contest_full_run_bot/challenge_en_20260510_145813`
- 실행 조건: `--seed 91460 --difficulty challenge --locale en --web-port 7366 --browser-profile-dir /tmp/rummipoker_contest_full_run_bot/challenge_en_profile_20260510_145813 --output-dir /tmp/rummipoker_contest_full_run_bot/challenge_en_20260510_145813 --tutorials-already-seen --skip-pub-get`
- 결과: `CONTEST_FULL_RUN_BOT_PASS`, `All tests passed!`, S8 boss run complete
- locale/fresh 조건: `locale=en`, `resolvedLocale=en`, `freshStorage=true`, `difficulty=challenge`
- 튜토리얼: 같은 locale cycle 내부 challenge 실행이므로 `--tutorials-already-seen`으로 battle/market tutorial seen 상태를 유지했다. fresh 튜토리얼 완료 로그는 이 실행에서 요구하지 않는다.
- S8 small 정산: `1622/2 -> 230/1`, 목표 `1729` 통과
- S8 big 정산: `1009/2 -> 1032/2 -> 368/1`, 목표 `2086` 통과
- S8 boss 정산: `1010/3 -> 869/2 -> 312/1`, 목표 `2087` 통과
- S8 시작 덱: `deck=59`
- game over/retry/Flutter semantics warning/UI overflow/error/warn: 없음
- 종료 후 WebDriver Chrome, Chrome Helper, ChromeDriver, Flutter web 서버 잔류 프로세스 없음

- 2026-05-10~11 최신 후보 `ko` 재확인 표준 로그: `/tmp/rummipoker_contest_full_run_bot/standard_ko_recheck_20260510_233626/10_contest_full_run_bot.log`
- 결과: `CONTEST_FULL_RUN_BOT_PASS`, `All tests passed!`, S8 boss run complete
- grep 기준 game over/retry/Flutter semantics warning/UI overflow/error/warn: 없음
- 종료 후 WebDriver Chrome, Chrome Helper, ChromeDriver, Flutter web 서버 잔류 프로세스 없음

- 2026-05-10~11 최신 후보 `ko` 재확인 도전 로그: `/tmp/rummipoker_contest_full_run_bot/challenge_ko_recheck_20260511_005027/10_contest_full_run_bot.log`
- 결과: `CONTEST_FULL_RUN_BOT_PASS`, `All tests passed!`, S8 boss run complete
- locale/fresh 조건: `locale=ko`, `resolvedLocale=ko`, `freshStorage=true`, `difficulty=challenge`
- S8 boss 목표 `2087` 통과, S8 시작 덱 `deck=59`
- grep 기준 game over/retry/Flutter semantics warning/UI overflow/error/warn: 없음
- 종료 후 WebDriver Chrome, Chrome Helper, ChromeDriver, Flutter web 서버 잔류 프로세스 없음

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
- `docs/submission_kit/` 제출 문서 세트 정리 완료. 이번 웹 제출 기준에서는 문서화로 닫고, Android/iOS 실제 release artifact 생성은 해당 플랫폼 제출 시 별도 gate로 둔다.
- 전투/마켓 튜토리얼 V1은 `tutorial_coach_mark`로 구현. `flutter analyze`, 핵심 widget test, `flutter build web` 통과. 리사이즈 후 focus 위치/크기 눈검증도 완료했다.
- 2026-05-10 추가 UI/Web 회귀 수정: icon/splash/OG image를 최신 asset으로 반영, 릴리즈 홈 메뉴를 도감 중심으로 정리, 웹 BGM unlock과 스크롤 중 묵음 회귀 수정, 정산 sheet의 `TextDecoration` 상속 밑줄과 `showGeneralDialog` PhoneFrame 폭 회귀 수정. 검증: `flutter analyze`, `flutter test test/views/game/widgets/game_cashout_widgets_test.dart`, `flutter test test/views/game/game_view_test.dart`, `flutter build web --release --base-href "/rummipoker/"`.

## 3. 공모전 Done Evidence

공모전 트랙은 기능 존재만으로 닫지 않는다.
아래 증거가 있어야 제출 후보로 본다.

- `flutter analyze` 통과
- 핵심 `flutter test` 통과
- 최신 `flutter build web` 통과
- Browser/WebDriver full-play QA에서 최신 빌드 기준 console error/warn 0건
- Browser/WebDriver + Compute Use hybrid bot으로 debug fixture 없이 `ko`, `en` 표준 S1~S8 Boss clear와 도전 S1~S8 Boss clear 확인. 최신 후보에서는 `ko` standard→challenge 재확인까지 통과했으므로 제출용 full-run bot 플랜은 닫는다. `ja`, `zh-CN`, `zh-TW`는 문제 발견 시 또는 공모전 이후 추가 검증으로 둔다.
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
- 타이틀 로고/서브타이틀, submission kit 문서화, 전투/마켓 튜토리얼 V1: 반영 완료. 튜토리얼 리사이즈 눈검증도 완료했다.
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
| 다음 세션 공모전 제출 handoff | `docs/planning/competition/NEXT_SESSION_SUBMISSION_HANDOFF_PROMPT.md` |
| 공모전 full-play bot 제작 기준 | `docs/planning/competition/COMPUTE_BROWSER_FULL_PLAY_BOT.md` |
| 실제 Goal 전체 진도 | `docs/planning/goal/OVERALL_GOAL_PROGRESS.md` |
| 장기 레벨링/경제 적용 상태 | `docs/planning/leveling/*` |
| 과거 V4/migration 순서 lock | `docs/planning/legacy/*` |

`docs/planning/legacy/*`는 현재 실행 판단 기준이 아니다.
