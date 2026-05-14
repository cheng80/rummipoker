# Competition Submission Checklist

> 문서 성격: 공모전 제출 준비용 실행 체크리스트
> 현재 실행 라우터: `docs/planning/ACTIVE_EXECUTION_PLAN.md`
> 기준 문서: `docs/planning/goal/OVERALL_GOAL_PROGRESS.md`, `docs/planning/leveling/LEVELING_APPLIED_STATUS.md`, `docs/current_system/CURRENT_LEVELING_POLICY.md`
> 목표: BIC 일반부문 1차 접수용 플레이 가능 빌드를 안정적으로 제출한다.
> full-play gate 별명: `공모전 풀런봇` (`contest_full_run_bot`)

이 문서는 공모전 제출 이력과 제출 당시 검증 증거를 보존한다.
2026-05-15 12시경 최종 산출물을 우선 등록했으므로 이 문서는 더 이상 활성 작업 큐가 아니다.
현재 활성 트랙과 다음 작업 선택은 `docs/planning/ACTIVE_EXECUTION_PLAN.md`를 따른다.
전체 진도와 장기 목표 판단은 `docs/planning/goal/OVERALL_GOAL_PROGRESS.md`를 기준으로 하고, 이 문서는 제출 준비 실행표로만 사용한다.

## 0. 제출 작업 첫 화면

현재 결론:

- 2026-05-15 12시경 최종 산출물을 우선 등록했다. 공모전 트랙은 off이며, 아래 항목은 제출 전 검증 이력이다.
- 공모전 풀런봇 QA는 제출용 handoff 상태로 닫는다. `ko`, `en` 표준→도전 cycle을 통과했고, 최신 UI/Web 회귀 수정 뒤 `ko` standard→challenge 재확인도 통과했다. `ja`, `zh-CN`, `zh-TW` full-run은 문제가 발견될 때 또는 공모전 이후 추가 검증으로 둔다.
- 2026-05-09 최신 룰/UI 후보에서 fresh 표준 난이도 S1~S8 boss full-run 통과 증거를 확보했다.
- 2026-05-10 최신 제출 후보 build에서 locale별 standard→challenge full-run cycle을 제외한 최근 룰/UI 항목 검증을 마쳤다.
- 2026-05-10 `ko` fresh 표준 locale gate는 `/tmp/rummipoker_contest_full_run_bot/standard_ko_20260510_104511/10_contest_full_run_bot.log`에서 `CONTEST_FULL_RUN_BOT_PASS`와 `All tests passed!`를 기록했다.
- 2026-05-10 `ko` fresh 도전 locale gate는 `/tmp/rummipoker_contest_full_run_bot/challenge_ko_20260510_115046/10_contest_full_run_bot.log`에서 `CONTEST_FULL_RUN_BOT_PASS`와 `All tests passed!`를 기록했다.
- 2026-05-10 `en` fresh 표준 locale gate는 `/tmp/rummipoker_contest_full_run_bot/standard_en_20260510_140623/10_contest_full_run_bot.log`에서 `CONTEST_FULL_RUN_BOT_PASS`와 `All tests passed!`를 기록했다.
- 2026-05-10 `en` fresh 도전 locale gate는 `/tmp/rummipoker_contest_full_run_bot/challenge_en_20260510_145813/10_contest_full_run_bot.log`에서 `CONTEST_FULL_RUN_BOT_PASS`와 `All tests passed!`를 기록했다.
- `ko`, `en` 표준→도전 2사이클은 완료됐다. 이후 발견한 잠긴 슬롯 해금 공백은 S2/S4/S6 Boss 보상과 Market 진입 연출로 보강했고, 앱 기본 언어도 OS/브라우저 시스템 locale을 따르게 수정했다. `slot_unlock_market` fixture 눈검증도 완료했다. 이후 web 제출 산물/BGM/릴리즈 메뉴/정산 UI 회귀를 수정했고, 최신 후보에서 `ko` standard→challenge 재확인을 다시 통과했다. 한 locale 사이클의 기준은 fresh 표준 난이도 S1~S8 Boss 클리어, 이어서 같은 locale fresh 도전 난이도 S1~S8 Boss 클리어와 S8 정산/보상/무한 도전 진입 직전 확인까지다. `ja`, `zh-CN`, `zh-TW`는 제출 gate 필수 대기열에서 내리고, 문제가 발견될 때 또는 공모전 이후 추가 검증으로 둔다.
- 2026-05-14 제출 전 상점 가격/오퍼 회귀 수정 완료: 보유 Jester/Item/Passive 판매는 명시적 리롤 없이 현재 보이는 오퍼 리스트를 유지하고, 오퍼 구매 후 남은 Jester/Item 가격이 자동으로 0G가 되지 않으며, 구매 할인은 UI에 원가/할인가/`할인` 배지로 표시된다. `reroll_token`은 문구와 맞게 다음 리롤 1G 할인으로 동작한다. 이후 `market_discount_visual_bot`을 추가해 할인 Jester 구매/판매, 할인 Item offer 표시, Passive 판매 후 offer 유지, 리롤 할인/피드백, 비할인 Jester/Item 가격 표시, 슬롯 해금 Market 상태를 7개 fresh Chrome/Flutter drive 시나리오로 확인했다. 커밋: `d77f289`, `2d1a4d4`.
- 제출 전 핵심 룰 보강이었던 족보 레벨 성장, 덱 추가, 히든 족보 V1, 보스 클리어 덱 타일 보상, 행성카드형 성장 아이템, 초과 점수 기반 대표 족보 성장, 타이틀 `런 정보`, 게임오버 정산/도발 문구는 런타임 반영과 핵심 검증을 마쳤다.
- S8 boss 이후는 더 이상 애매한 `계속 진행`이 아니라 `무한 도전 진입`으로 표시한다. S9+는 Scout 1배, Clash 1.5배, Boss 2배 target 비율을 따르고 Station Select, 전투 HUD, 정산 라벨에서 위험한 무한 구간 색상으로 드러낸다.
- runtime/economy/boss pool은 공모전 기준 임시 handoff 가능 상태이며, 장기 밸런스 완료는 아니다.
- full-play 기준은 사람 수동 플레이가 아니라 제작된 bot이 Browser/WebDriver의 실행·로그 수집과 Compute Use의 화면 좌표 조작을 결합해 각 locale의 표준 S1~S8 Boss와 도전 S1~S8 Boss를 클리어하는 것이다.
- 이 hybrid full-play bot의 대화 호출 별명은 `공모전 풀런봇`이고, 영문 식별자는 `contest_full_run_bot`이다.
- 제출 gate의 플레이 범위는 확인 대상 locale에서 표준 S8 Boss 클리어를 먼저 확인한 뒤, 도전 S8 Boss 클리어와 S8 정산/보상/무한 도전 진입 직전 확인까지다. 이번 제출용 풀런봇 플랜은 `ko`, `en` cycle과 최신 `ko` 재확인으로 닫고, S9+ 무한 도전 장기 생존은 별도 확장 검증이다.
- full-run 도중 수정 범위는 game over에 한정하지 않는다. UI overflow, 튜토리얼 target/문구 문제, Jester/Item/자원 카드의 제목·설명 잘림, locale별 텍스트 넘침이 발견되면 제출 QA 결함으로 수정하고 해당 locale gate를 다시 실행한다.
- 향후 문제 발생 또는 공모전 이후 locale cycle을 추가 검증할 때는 standard 실행 전에 저장 세션/SharedPreferences와 WebDriver Chrome profile의 cookie/localStorage/sessionStorage를 지운 fresh 세션에서 시작해 첫 전투/첫 Market 튜토리얼 표시와 `Next/Done` 완료 로그를 함께 확인한다. 같은 locale의 challenge 실행은 새 run으로 시작하되 같은 cycle 내부 진행이므로 tutorial seen 상태를 유지한다. 튜토리얼 overlay가 떠 있으면 bot은 드로우/구매/다음 Station 같은 실제 액션보다 튜토리얼 완료를 먼저 처리한다.
- Codex 앱 내장 Browser Use는 제출 gate가 아니라 bot 실패 구간 분석, 보조 눈검증, 최종 감각 확인에 사용한다.
- 2026-05-08 checkpoint pass 증거는 commit `9262e6d`와 `/tmp/rummipoker_contest_full_run_bot/resume_s8_boss_final_pass/10_contest_full_run_bot.log`에 남아 있다.
- 2026-05-09 최신 보정 후보는 commit `18f0b53` 기준 S8 big을 `1739/1738`로 통과했지만, S8 boss는 `698/1739` 실패 후 retry 2에서 timeout이 났다.
- 이 결과는 bot 전용 정책만으로 S8 boss를 밀기보다, runtime의 족보 성장/덱 확장 축을 먼저 보강해야 한다는 판단 근거다.
- 2026-05-09 최신 룰/UI 보강 후 fresh 표준 실행은 `/tmp/rummipoker_contest_full_run_bot/fresh_after_reward_tile_rules_20260509_201727/10_contest_full_run_bot.log`에서 `CONTEST_FULL_RUN_BOT_PASS`와 `All tests passed!`를 기록했다.
- fresh 표준 실행 조건은 `--seed 91460 --difficulty standard --web-port 7362 --skip-pub-get`이고, game over/retry 없이 S8 boss까지 통과했다.
- S8 boss 정산은 `870/3 -> 728/2 -> 312/1`로 목표 `1739`를 넘겼다.
- 보스 클리어 덱 타일 보상은 다음 전투 덱 크기 증가로 확인했다. S2 `deck=53`, S3 `deck=54`, S4 `deck=55`, S5 `deck=56`, S6 `deck=57`, S7 `deck=58`, S8 `deck=59`.
- fresh 표준 로그에는 `Semantic node ... scopesRoute and namesRoute ... missing the label` 경고가 반복 출력됐다. 2026-05-10 route/dialog semantics label 보정 후 최신 build smoke에서는 같은 경고가 재현되지 않았다.
- 2026-05-10 검증: `flutter analyze`, 핵심 `flutter test`, `flutter build web` 통과.
- 2026-05-10 Browser/CDP smoke: `/`, `/new-run`, `/archive`, `/game?fixture=game_over_insight_ready&debug_show_game_over_on_load=1`, `/game?fixture=final_boss_cash_out_ready&debug_complete_run_on_load=1` 모두 앱 warn/error/exception 0건. Headless Chrome의 `Falling back to CPU-only rendering`은 WebGL 없는 headless 환경 경고라 앱 경고로 집계하지 않는다.
- 2026-05-10 추가 검증: 무한 도전 target 산식, S9+ Station Select 표시, 전투 HUD 무한 라벨, 정산 무한 라벨/CTA 테스트와 `flutter build web` 통과.
- 2026-05-10 추가 작업: 타이틀 로고 이미지와 서브타이틀 `타일로 만드는 포커 런`을 적용했고, `docs/submission_kit/`에 플랫폼별 빌드/스토어/튜토리얼/인앱 리뷰 문서를 정리했다.
- 2026-05-10 튜토리얼: `showcaseview` 대신 `tutorial_coach_mark` 기반 전투/마켓 첫 설명과 다시 보기를 구현했다. 옵션/포커스 아웃 시 overlay가 위에 남지 않게 닫고, FittedBox 변환 뒤 실제 화면 rect로 focus 위치/크기를 계산하도록 보정했다. Browser/기기 리사이즈 후 focus 위치/크기 눈검증도 완료했다.
- 2026-05-10 `ko` 표준 locale gate: `locale=ko`, `resolvedLocale=ko`, `freshStorage=true`, 첫 battle/market tutorial completed, S8 boss 정산 `951/3 -> 778/2 -> 246/1`, 목표 `1739` 통과, S2 `deck=53`부터 S8 `deck=59`까지 증가, game over/retry/Flutter semantics warning/UI overflow/error/warn 0건.
- 2026-05-10 `ko` 도전 locale gate: `locale=ko`, `resolvedLocale=ko`, `freshStorage=true`, `difficulty=challenge`, `--tutorials-already-seen`으로 같은 locale cycle의 tutorial seen 상태 유지, S8 small `1622/2 -> 230/1` 목표 `1729` 통과, S8 big `1009/2 -> 1032/2 -> 368/1` 목표 `2086` 통과, S8 boss `1010/3 -> 869/2 -> 312/1` 목표 `2087` 통과, S8 시작 `deck=59`, game over/retry/Flutter semantics warning/UI overflow/error/warn 0건.
- 2026-05-10 `en` 표준 locale gate: `locale=en`, `resolvedLocale=en`, `freshStorage=true`, 첫 battle/market tutorial completed, S8 small `1539/2` 목표 `1441` 통과, S8 big `902/2 -> 925/2` 목표 `1738` 통과, S8 boss `951/3 -> 778/2 -> 246/1` 목표 `1739` 통과, S8 시작 `deck=59`, game over/retry/Flutter semantics warning/UI overflow/error/warn 0건.
- 2026-05-10 `en` 도전 locale gate: `locale=en`, `resolvedLocale=en`, `freshStorage=true`, `difficulty=challenge`, `--tutorials-already-seen`으로 같은 locale cycle의 tutorial seen 상태 유지, S8 small `1622/2 -> 230/1` 목표 `1729` 통과, S8 big `1009/2 -> 1032/2 -> 368/1` 목표 `2086` 통과, S8 boss `1010/3 -> 869/2 -> 312/1` 목표 `2087` 통과, S8 시작 `deck=59`, game over/retry/Flutter semantics warning/UI overflow/error/warn 0건.
- 2026-05-10~11 최신 후보 `ko` 재확인:
  - 표준 로그: `/tmp/rummipoker_contest_full_run_bot/standard_ko_recheck_20260510_233626/10_contest_full_run_bot.log`
  - 도전 로그: `/tmp/rummipoker_contest_full_run_bot/challenge_ko_recheck_20260511_005027/10_contest_full_run_bot.log`
  - 둘 다 `CONTEST_FULL_RUN_BOT_PASS`, `All tests passed!`, `S8 boss: run complete`.
  - grep 기준 game over/retry/Flutter semantics warning/UI overflow/error/warn 0건.
  - 종료 후 WebDriver Chrome, Chrome Helper, ChromeDriver, Flutter web 서버 잔류 프로세스 없음.
- 해당 run 종료 후 WebDriver Chrome, Chrome Helper, ChromeDriver, Flutter web 서버 잔류 프로세스 없음.
- 2026-05-10 추가 룰 보강: 잠겨 있던 Quick Item 3번 슬롯, Passive 2번 슬롯, Jester 5번 슬롯을 각각 S2/S4/S6 Boss 클리어 보상으로 해금하도록 구현했다. 해금은 즉시 저장 상태에 반영하고, 다음 Market 진입 시 1회 배너/슬롯 pulse로 보여준 뒤 전투에는 이미 해금된 슬롯 상태로 진입한다. 검증: `flutter analyze`, `flutter build web`, `rummi_market_facade_test`, `game_session_notifier_test`, `active_run_save_service_test`, `game_shop_slot_unlock_screen_test`, `debug_run_fixture_service_test`.
- 2026-05-10 추가 UX/QA 보강: 앱 기본 언어는 특정 한국어 `startLocale` 강제가 아니라 OS/브라우저 시스템 locale을 따르게 했다. 해금 연출 확인용 debug fixture `slot_unlock_market`를 추가했고, 확인 URL은 `/game?fixture=slot_unlock_market`다. 튜토리얼 검증 전용이 아닌 debug fixture는 자동 튜토리얼을 띄우지 않고, 튜토리얼은 다시 보기 버튼으로만 연다. 해금 연출은 자물쇠 확대/fade-out과 슬롯 pulse가 1회 보이는 기준으로 눈검증 완료했다. 커밋: `4dea65c Add boss slot unlock rewards`, `8adc86d Add slot unlock debug fixture`.
- 2026-05-10 추가 Web/릴리즈 보강: icon/splash를 새 asset으로 반영하고 OG image를 `https://cheng80.myqnapcloud.com/rummipoker/assets/assets/splash.png` 기준으로 잡았다. 릴리즈 홈 메뉴는 도감 중심으로 정리하고 debug/special 메뉴는 debug gate 뒤로 숨겼다.
- 2026-05-10 추가 오디오/정산 회귀 수정: 웹 BGM은 첫 사용자 터치/홈 카드 tap에서 unlock되고, 스크롤 중 같은 BGM을 stop/play 반복해 묵음이 되는 경로를 막았다. 정산 sheet의 노란 밑줄은 `TextDecoration` 상속 차단으로 수정했고, desktop/web에서 정산 dialog가 PhoneFrame 밖 전체 폭으로 그려지는 회귀는 `PhoneFrame` 제약과 landscape widget test로 막았다.
- 2026-05-14 상점 회귀 수정: 보유물 판매 후 오퍼 리스트가 암묵적으로 리롤되는 문제, 오퍼 구매 후 남은 오퍼 가격이 0G로 바뀌는 stale slot index 문제, 첫 무료 Jester 리롤이 다음 Market에서 복원되는 문제, 할인 상태가 UI에 드러나지 않는 문제를 수정했다. 검증: `flutter test test/logic/rummi_market_facade_test.dart test/logic/item_definition_test.dart test/logic/item_effect_runtime_test.dart test/providers/game_session_notifier_test.dart`, `flutter test test/views/game/widgets/game_shop_discount_badge_test.dart test/views/game/widgets/game_shop_sell_offer_stability_test.dart`, `flutter analyze integration_test/market_discount_visual_bot_test.dart`, `bash -n tools/market_discount_visual_bot.sh`, `tools/market_discount_visual_bot.sh --skip-pub-get --web-port 7371 --output-dir /tmp/rummipoker_market_discount_visual_bot/matrix_full_20260514_060908`, `git diff --check`. 상점 시각 봇 결과는 `MARKET_DISCOUNT_VISUAL_BOT_PASS` 7건과 `All tests passed!` 7건이며, 종료 후 WebDriver Chrome/ChromeDriver/Flutter web server 잔류 프로세스 없음.
- 2026-05-14 웹 focus-out BGM 완화: 웹뷰에서 focus-out 후 복귀할 때 BGM이 씹히거나 처음부터 재생되는 문제를 `SoundManager` 내부 정책으로 제한했다. lifecycle pause만 recovery pending으로 표시하고, 복귀 후 첫 사용자 제스처는 `resume()`을 먼저 시도한다. 그 resume이 실패한 경우에만 다음 제스처에서 `stop()`/`play()` fallback을 허용하며, `pointerdown`/`pointerup` 중복 replay는 막는다. 검증: `flutter test test/resources/sound_manager_test.dart`, `flutter test test/views/game/game_view_test.dart`, `flutter analyze lib/app.dart lib/resources/sound_manager.dart test/resources/sound_manager_test.dart`, `flutter build web`, `git diff --check`. 웹뷰/브라우저 오디오 정책 때문에 BGM 위치 유지가 완전하지 않은 경우는 known limitation으로 둔다.
- 2026-05-14 용어 UX 보강: `+N Mult`처럼 보이던 Jester/Item 설명을 실제 효과인 `점수 +N*5%`로 환산했고, 진짜 곱셈은 `점수 xN`으로 표시한다. 한국어 Chips는 `칩`으로 통일하며, 런 정보 다이얼로그에 `게임 용어` 설명을 추가해 `칩`, `점수 +%`, `점수 xN`, `골드` 차이를 설명한다. 검증: `flutter test test/views/game/widgets/game_run_info_dialog_test.dart test/logic/jester_translation_test.dart test/logic/item_definition_test.dart test/views/game/widgets/game_shop_jester_runtime_value_test.dart test/views/game/widgets/game_shop_screen_test.dart test/views/game/widgets/game_station_read_path_test.dart`, JSON validation, `git diff --check`.

닫힌 제출 작업:

1. 완료: Browser/WebDriver + Compute Use hybrid bot으로 `ko` 표준 난이도 fresh S1~S8 Boss를 통과했다.
2. 완료: 같은 `ko` cycle 내부에서 `ko` 도전 난이도 fresh S1~S8 Boss와 S8 정산/보상/무한 도전 진입 직전 확인까지 통과했다.
3. 완료: Browser/WebDriver + Compute Use hybrid bot으로 `en` 표준 난이도 fresh S1~S8 Boss를 통과했다.
4. 완료: 같은 `en` cycle 내부에서 `en` 도전 난이도 fresh S1~S8 Boss와 S8 정산/보상/무한 도전 진입 직전 확인까지 통과했다.
5. 완료: 잠긴 슬롯 해금 룰과 Market 진입 연출 보강을 닫았다.
6. 완료: 시스템 locale 기본값과 `slot_unlock_market` debug fixture를 추가했다.
7. 완료: `/game?fixture=slot_unlock_market`에서 자동 튜토리얼 없이 해금 배너/자물쇠 해제/슬롯 pulse가 보이는지 눈검증했다.
8. 완료: web icon/splash/OG image, 릴리즈 홈 메뉴, 웹 BGM unlock/scroll 묵음, 정산 밑줄, 정산 PhoneFrame 폭 회귀를 수정하고 최신 build/test를 통과했다.
9. 완료: 최신 후보 `ko` standard→challenge 재확인 통과를 근거로 공모전 제출용 풀런봇 플랜을 닫는다. `ja`, `zh-CN`, `zh-TW`는 문제가 발견될 때 또는 공모전 이후 추가 검증으로 둔다.
10. full-run 도중 실패하면 game over/retry/checkpoint 로그를 기준으로 policy code/test를 먼저 고치고, 문서만 바꾼 상태로 재실행하지 않는다.
11. full-run 통과 뒤 최신 build 기준 console 0건을 다시 확인한다.

## 0.1 최근 24시간 이내 추가 항목과 검증 대기 목록

이 섹션을 제출 QA의 최상위 작업 큐로 본다.
아래 항목은 locale별 standard→challenge full-run cycle을 제외한 최근 24시간 내 구현/문서/UX 작업 기준이다.

### A. 구현과 1차 검증을 닫은 항목

- [x] 족보 성장 UI/점수 반영
  - 구현 상태: run 내부 족보 성장, `handGrowthStates(level/progress/requiredProgress)` 분리, 성장 점수 반영, `런 정보` 표시까지 반영.
  - 검증: `game_run_info_dialog_test`, `rummi_session_test`, 저장/복원 관련 테스트와 최신 build smoke에서 확인.
- [x] 행성카드형 성장 아이템
  - 구현 상태: 특정 족보 성장 +1을 직접 지급하는 `*_study` 계열 아이템과 runtime/test가 반영됨.
  - 검증: `item_effect_runtime_test`, `item_definition_test`, `competition_bot_market_policy_test`에서 runtime과 bot 구매 평가를 확인.
- [x] 초과 점수 기반 대표 족보 성장
  - 구현 상태: 목표 점수를 의미 있게 초과해 클리어하면 해당 Station의 대표 족보 성장 보너스를 지급하는 경로가 반영됨.
  - 검증: `rummi_overkill_growth_test`, `rummi_settlement_facade_test`, 정산 관련 widget test에서 확인.
- [x] 메인 화면 `런 정보` 진입
  - 구현 상태: active run이 있을 때 타이틀에서 저장된 현재 run의 `런 정보`를 열 수 있음.
  - 검증: `title_view_test`와 `/`, `/new-run` 최신 build smoke에서 확인.
- [x] 게임오버 정산 화면과 랜덤 도발 문구
  - 구현 상태: 게임오버 dialog에 이번 run 요약과 랜덤 도발 문구가 표시됨.
  - 검증: `game_view_test`와 `game_over_insight_ready` 최신 build smoke에서 확인.
- [x] S8 이후 무한 도전 진입 UX
  - 구현 상태: S8 Boss 정산에서 `무한 도전 진입` CTA를 표시하고, S9+ Station Select/전투 HUD/정산 라벨을 위험 구간 색상으로 표시한다.
  - 검증: `blind_selection_setup_test`, `blind_select_view_test`, `game_station_read_path_test`, `rummi_settlement_facade_test`, `game_cashout_widgets_test`에서 확인.
- [x] 타이틀 로고와 서브타이틀
  - 구현 상태: 이미지 로고를 적용하고 서브타이틀을 `타일로 만드는 포커 런`으로 고정했다.
  - 검증: `title_view_test`, `flutter analyze`, `flutter build web` 기준으로 확인. 최종 스토어용 스크린샷은 별도 촬영 필요.
- [x] submission kit 문서 세트
  - 구현 상태: `docs/submission_kit/`에 플랫폼별 빌드 가이드, release checklist, store metadata, promo copy, tutorial plan, in-app review guide를 정리했다.
  - 검증: 문서 구조와 old doc 흡수 범위 확인. 이번 웹 제출 기준에서는 문서화로 닫고, 실제 Android/iOS release artifact 생성은 해당 플랫폼 제출 시 별도 gate로 둔다.
- [x] 인앱 리뷰 store id gate
  - 구현 상태: market id/store id가 없으면 진입 메뉴의 인앱 리뷰 버튼이 보이지 않게 처리했다.
  - 검증: `setting_view_test`와 최신 analyze/test에서 확인.
- [x] 잠긴 슬롯 해금 룰과 Market 진입 연출
  - 구현 상태: S2 Boss 클리어로 Quick Item 3번 슬롯, S4 Boss 클리어로 Passive 2번 슬롯, S6 Boss 클리어로 Jester 5번 슬롯을 해금한다. 해금 상태와 pending 연출은 저장/복원되며, Market 진입 시 1회 배너와 슬롯 pulse로 보여주고 전투 진입 시에는 해금된 슬롯 상태만 표시한다.
  - 검증: `flutter analyze`, `flutter build web`, `rummi_market_facade_test`, `game_session_notifier_test`, `active_run_save_service_test`, `game_shop_slot_unlock_screen_test`, `debug_run_fixture_service_test`에서 확인. 제출용 full-run과 `slot_unlock_market` 눈검증 기준으로 닫았다.
- [x] 시스템 locale 기본값과 슬롯 해금 debug fixture
  - 구현 상태: 앱 일반 진입점은 `startLocale`로 한국어를 강제하지 않고 OS/브라우저 시스템 locale을 따른다. `slot_unlock_market` fixture는 해금 상태와 pending 연출을 담은 Market scene으로 열린다.
  - 검증: `setting_view_test`, `title_view_test`, `game_shop_slot_unlock_screen_test`, `debug_run_fixture_service_test`, `flutter analyze`, `flutter build web` 통과. 슬롯 해금 fixture 화면은 사용자 눈검증 완료.
- [x] debug fixture 자동 튜토리얼 차단
  - 구현 상태: 튜토리얼 검증 전용으로 명시되지 않은 debug fixture는 battle/market 자동 튜토리얼을 시작하지 않는다. 튜토리얼은 상단/옵션 다시 보기 버튼을 통해서만 열린다.
  - 검증: `debug_run_fixture_service_test`, `game_shop_slot_unlock_screen_test`에서 fixture 기본값과 Market 자동 튜토리얼 차단을 확인. 실제 fixture 화면에서도 자동 튜토리얼이 해금 연출을 가리지 않는 것을 확인.
- [x] Web 제출 산물과 공유 이미지
  - 구현 상태: 새 `icon.png`/`splash.png`를 패키지 설정 기준으로 반영했고, web OG image는 배포 절대 주소의 splash asset을 바라보게 했다.
  - 검증: `flutter_native_splash:create`, `flutter_launcher_icons`, `flutter build web --release --base-href "/rummipoker/"` 기준으로 확인. 카카오톡/브라우저 캐시는 별도 외부 캐시 정책 영향을 받을 수 있다.
- [x] 릴리즈 홈 메뉴 정리
  - 구현 상태: 일반 릴리즈 진입 화면의 “다른 화면” 메뉴는 도감 중심으로 정리했고, debug/special 성격 메뉴는 debug gate 뒤로 숨겼다.
  - 검증: `flutter analyze`, 관련 home/title widget test, 최신 web build 기준으로 확인.
- [x] 웹 BGM unlock/스크롤 묵음/focus-out 복구 회귀
  - 구현 상태: 첫 사용자 pointer/tap에서 BGM 재생을 재시도하고, 홈 카드 tap에서는 직접 unlock/SFX를 호출한다. 같은 화면 BGM이 이미 재생 중이면 스크롤마다 stop/play를 반복하지 않는다. focus-out 복귀는 lifecycle pause만 recovery pending으로 만들고, 다음 사용자 제스처에서 `resume()`을 먼저 시도한 뒤 실패 시 다음 제스처에서만 `stop()`/`play()` fallback을 허용한다.
  - 검증: 데스크톱 웹과 iPhone Safari/카카오톡 브라우저에서 사용자 눈검증 완료. 2026-05-14 후속 완화는 `flutter test test/resources/sound_manager_test.dart`, `flutter test test/views/game/game_view_test.dart`, `flutter analyze lib/app.dart lib/resources/sound_manager.dart test/resources/sound_manager_test.dart`, `flutter build web`, `git diff --check` 통과. 일부 웹뷰에서 BGM 위치 유지가 완전하지 않은 것은 known limitation이다.
- [x] 정산 텍스트 밑줄과 PhoneFrame 폭 회귀
  - 구현 상태: 정산 sheet 루트에서 의도치 않은 `TextDecoration` 상속을 차단하고, `showGeneralDialog`로 뜨는 정산 overlay를 `PhoneFrame` 안에 제한했다.
  - 검증: `flutter analyze`, `flutter test test/views/game/widgets/game_cashout_widgets_test.dart`, `flutter test test/views/game/game_view_test.dart`, `flutter build web --release --base-href "/rummipoker/"` 통과.
- [x] Jester/Item 점수 용어 명확화와 게임 용어 설명
  - 구현 상태: `mult_bonus` 플레이어 문구는 `점수 +%`, `xmult_bonus`는 `점수 xN`, Chips는 한국어 `칩`으로 통일했다. 런 정보에서 `게임 용어` 다이얼로그를 열 수 있다.
  - 검증: `game_run_info_dialog_test`, `jester_translation_test`, `item_definition_test`, `game_shop_jester_runtime_value_test`, `game_shop_screen_test`, `game_station_read_path_test`, JSON validation, `git diff --check` 통과. 실제 기기/브라우저 마켓 카드와 tooltip의 다국어 줄바꿈은 제출 전 눈검증 권장.

### B. 최근 추가 항목 때문에 다시 열어 둔 QA

- [x] Flutter semantics route label 반복 경고 제거.
- [x] 최신 제출 후보 `flutter build web` 재실행.
- [x] 최신 build 또는 새 web-server 기준 console error/warn 0건 확인.
- [x] `contest_full_run_bot`이 추가 덱, 보상 타일, 특수 족보, 족보 성장 점수를 실제 후보 평가에 반영하는지 policy code/test 확인.
- [x] 제출용 `contest_full_run_bot` cycle 증거 확보: `ko`, `en` 표준→도전 cycle과 최신 후보 `ko` 재확인을 제출용 기준선으로 채택한다. `ja`, `zh-CN`, `zh-TW`는 문제가 발견될 때 또는 공모전 이후 추가 검증으로 둔다.
  - `ko` 표준: 완료. 로그 `/tmp/rummipoker_contest_full_run_bot/standard_ko_20260510_104511/10_contest_full_run_bot.log`.
  - `ko` 도전: 완료. 로그 `/tmp/rummipoker_contest_full_run_bot/challenge_ko_20260510_115046/10_contest_full_run_bot.log`.
  - `ko` cycle: 완료.
  - `en` 표준: 완료. 로그 `/tmp/rummipoker_contest_full_run_bot/standard_en_20260510_140623/10_contest_full_run_bot.log`.
  - `en` 도전: 완료. 로그 `/tmp/rummipoker_contest_full_run_bot/challenge_en_20260510_145813/10_contest_full_run_bot.log`.
  - `en` cycle: 완료.
  - 최신 후보 `ko` 재확인 표준: 완료. 로그 `/tmp/rummipoker_contest_full_run_bot/standard_ko_recheck_20260510_233626/10_contest_full_run_bot.log`.
  - 최신 후보 `ko` 재확인 도전: 완료. 로그 `/tmp/rummipoker_contest_full_run_bot/challenge_ko_recheck_20260511_005027/10_contest_full_run_bot.log`.
  - `ja`, `zh-CN`, `zh-TW`: 문제가 발견될 때 또는 공모전 이후 추가 검증.
- [x] 제출용 확인 대상 cycle에서 standard 첫 전투/첫 Market 튜토리얼 표시와 `Next/Done` 완료 로그, challenge의 tutorial seen 유지, 스킵/완료/포커스 아웃 처리, UI overflow/Jester/Item/자원 설명 잘림 0건 확인.
  - `ko`: standard 첫 battle/market tutorial completed, challenge tutorial seen 유지, UI overflow/Jester/Item/자원 설명 잘림 0건.
  - `en`: standard 첫 battle/market tutorial completed, challenge tutorial seen 유지, UI overflow/Jester/Item/자원 설명 잘림 0건.
- [x] 게임오버 보상, 도감 카드 face, 새 run 화면이 수집/재시작 욕구로 읽히는지 Browser Use 또는 Browser/WebDriver로 눈검증.
- [x] 전투/마켓 튜토리얼 구현과 build/test 검증.
  - `showcaseview` 제거, `tutorial_coach_mark` 적용.
  - 자동 튜토리얼 완료 때만 seen 저장, skip/focus-out/options 진입 시 다음 진입에서 다시 표시.
  - tooltip/card 색상은 녹색 배경과 분리된 흑청/보라 계열과 금색 테두리로 조정.
- [x] 튜토리얼 Browser/기기 눈검증.
  - 전투 첫 진입, 마켓 첫 진입, 다시 보기 버튼, 옵션/포커스 아웃 겹침, 작은 화면/큰 화면에서 문구 잘림 확인.
  - 창 크기 변경 뒤 focus 위치뿐 아니라 크기도 따라오는지 확인.
- [x] 일반 release build에서 debug/special 성격 메뉴가 숨겨지고, QA/debug gate에서만 보이는지 재확인.

### C. 문서화됐지만 이번 제출 전 구현 범위에서 제외한 항목

- [ ] 정산 progress bar는 이번 범위에서 제외한다. 정산에는 숫자/보상/요약만 우선 표시한다.
- [ ] 게임오버 후 새 run까지 이어지는 족보 성장 영구 계승은 이번 범위에서 제외한다.
- [ ] `requiredProgress(level)`를 2 이상으로 키우는 성장 속도 재튜닝은 도전 full-run 결과 이후로 미룬다.
- [ ] 타로류 타일 강화/변환/복사/파괴와 유령카드류 고위험 덱/손패 변형은 공모전 이후 이식 검토로 둔다.
- [ ] 기억 카드가 실제 Jester/Item을 지급하는 보상 구조는 아직 구현하지 않는다. 현재는 기억 카드 이력/해금 중심이다.

제출 후보 Done 기준:

- `flutter analyze` 통과
- 핵심 `flutter test` 통과
- 최신 `flutter build web` 통과
- 최신 빌드 기준 Browser/WebDriver full-play QA console error/warn 0건
- Browser/WebDriver + Compute Use hybrid bot으로 debug fixture 없이 표준 S1~S8 clear 확인
- Browser/WebDriver + Compute Use hybrid bot으로 debug fixture 없이 `ko`, `en` 표준 S1~S8 Boss clear와 도전 S1~S8 Boss clear 확인. 최신 후보에서는 `ko` standard→challenge 재확인까지 통과했으므로 제출용 full-run bot 플랜은 닫는다. `ja`, `zh-CN`, `zh-TW`는 문제 발견 시 또는 공모전 이후 추가 검증으로 둔다.
- full-play 중 마켓 구매와 실제 플레이 흐름 확인. 아이템/보드 이동/버림은 증거용 강제 사용이 아니라 족보 형성 또는 확정 점수 개선이 있을 때만 확인한다.
- full-play 중 UI overflow, 튜토리얼 target/문구 문제, Jester/Item/자원 카드 제목·설명 잘림, 다국어 텍스트 넘침 0건 확인
- 게임오버/런 완료 보상, 도감, 새 run 복귀가 심사자에게 설명 없이 읽힌다는 눈검증

Known risk / 공모전 이후 검토:

- full-play bot의 과거 checkpoint-resume clear 증거, 최신 fresh 표준 clear 증거, `ko/en` 표준→도전 cycle 증거, 최신 후보 `ko` 재확인 증거를 확보했다. `ja`, `zh-CN`, `zh-TW`는 제출 gate 필수 대기열에서 내렸고 문제 발견 시 또는 공모전 이후 추가 검증으로 남긴다.
- fresh 표준 로그의 Flutter semantics warning은 route/dialog label 보정 뒤 최신 build smoke와 `ko/en` cycle, 최신 `ko` 재확인 로그에서 재현되지 않았다.
- 향후 full-run 문제가 재발하면 bot 전용 치팅이나 과한 가중치 추가가 아니라, 해당 locale에서 표준을 먼저 실제로 닫고 그 다음 도전 난이도에서 족보/중복줄/성장/덱 확장 정책이 충분히 작동하는지 확인한다.
- 참고한 방향은 Balatro류 `런 정보`/족보 표처럼 각 족보의 레벨, 현재 점수, 완성 횟수를 한 화면에서 보여주는 구조다. 단, 명칭과 UI는 이 게임 용어와 시각 체계에 맞춘다.
- `런 정보`는 전투 중 보조 팝업으로만 두지 않는다. 유저가 전투/마켓/새 run 준비/타이틀 또는 도감 계열 화면에서 현재 강한 족보와 다음 성장 목표를 확인할 수 있어야 한다.
- 후반 game over가 재발하면 봇 전용 가중치 숫자 조정만 보지 않고, 중복줄 확정 정책과 손패/이동/버림/아이템/구매/판매 전략을 함께 점검한다. 구간별 등장 확률을 올린 Jester/Item은 후반 안정화 구매 후보로 검토한다.
- 도감은 수집/발견/구매/보상/보스/스테이지 이력을 저장하지만, 항목별 미발견/발견/획득/클리어 상태 상세 UI는 남아 있다.
- `power none`과 `balanced v9` seed 편차는 장기 밸런스 risk로 유지한다.
- 기억 카드 보상은 현재 기억 카드류 이력에 한정하며, 실제 보상 아이템/Jester 지급은 아직 없다.

## 1. 기준과 보류 항목

- 공모전 작업은 재개 가능하다.
- runtime/economy/boss pool은 공모전 기준 임시 handoff 가능 상태다.
- ML 갱신, production ML, runtime 자동 밸런싱은 보류한다.
- `power none` clear가 일부 seed에서 높고, `balanced v9`가 한 seed에서 60%를 살짝 밑도는 점은 known risk로 둔다.
- 세부 레벨링 재조정보다 플레이 가능성, 이해도, 제출 안정성을 우선한다.
- 도감, 보상 카드, 해금 확인 흐름은 공모전 이해도에 필요한 항목으로 본다. 필요하면 UI와 저장 구조 변경도 구현 대상으로 올린다.
- 완료 체크는 기능 존재만으로 닫지 않는다. 게임완성도, 심미성, 재미도, full-play bot 증거, 최신 제출 후보 빌드 기준으로 다시 본다.
- full-play bot 제작 기준은 `docs/planning/competition/COMPUTE_BROWSER_FULL_PLAY_BOT.md`를 따른다.

## 2. 공모전 마감 재점검

Status: Closed for submission handoff

- [x] 최신 변경 후 제출 후보 web build를 다시 만든다.
- [x] 최신 빌드 또는 새 web-server에서 console error/warn 0건을 다시 확인한다.
- [x] Browser/WebDriver + Compute Use hybrid bot으로 debug fixture 없이 표준 S1~S8 실제 UI clear 가능한 최신 경로를 확인한다.
- [x] Browser/WebDriver + Compute Use hybrid bot으로 debug fixture 없이 도전 S1~S8 실제 UI clear 가능한 최신 경로를 확인한다.
  - `ko`, `en` 도전 통과와 최신 후보 `ko` standard→challenge 재확인을 제출 기준선으로 채택했다. `ja`, `zh-CN`, `zh-TW`는 문제 발생 시 또는 공모전 이후 추가 검증이다.
- [x] full-play bot이 마켓 구매를 수행하고 로그에 남긴다.
- [x] 게임오버 화면이 패배 후 다시 시작하고 싶게 만드는지 확인한다.
- [x] 도감의 Jester/Item 카드가 마켓/보유 슬롯의 실물 카드 face와 같은 인상인지 확인한다.
- [x] 첫 10분 플레이에서 “목표 이해 -> 선택 -> 결과 -> 보상 -> 다시 시작” 흐름이 심사자에게 설명 없이 읽히는지 확인한다.
- [x] 제출 영상 촬영 기준 smoke에서 전투/마켓/정산/도감/새 run 화면이 같은 build 안에서 깨지지 않는지 확인한다.

정리 메모:

- `Submission Smoke`의 `flutter build web`은 최신 후보에서 다시 통과했다.
- Browser Use full route QA는 debug fixture/즉시 클리어 보조가 섞였으므로 full-play bot 증거가 아니다.
- `contest_full_run_bot`은 과거 checkpoint-resume pass, 최신 fresh 표준 pass, `ko/en` 표준→도전 cycle, 최신 후보 `ko` 재확인까지 확보했다. 제출용 풀런봇 플랜은 닫았다.
- 게임오버 보상 루프는 최신 build fixture smoke와 widget test 기준으로 재점검했다. 최신 풀런봇 run에서는 자연 game over/retry가 발생하지 않았다.
- 도감은 `/archive` 최신 build smoke에서 console 0건을 확인했다. 항목별 상태와 화면 밀도 장기 개선은 별도 polish로 남긴다.

## 3. 텍스트/네이밍/IP 리스크

Status: Closed for submission handoff

- [x] 플레이어 노출 텍스트에서 원본 IP 냄새가 나는 이름을 찾는다.
- [x] `Joker` 원명이나 참고작 고유 조합명을 런타임 표시명/UI copy에서 제거한다.
- [x] `Jester`는 우리 게임 용어로 유지한다.
- [x] 보스 표시명과 설명은 우리 게임 룰 용어로 읽히게 정리한다.
- [x] 카드/Jester/Item/보스 효과 설명은 “언제, 무엇이, 얼마나, 언제까지”가 짧게 읽히게 정리한다.
- [x] 텍스트 변경 후 관련 fixture/test 또는 grep으로 잔여 표현을 확인한다.

진행 메모:

- `data/common/jesters_common_phase5.json`과 `assets/translations/data/{ko,en}/jesters.json`는 이미 독자 표시명 기준이었다.
- QA fixture로 화면에 노출될 수 있는 `lib/services/debug_run_fixture_service.dart`의 원본 계열 Jester 표시명을 `Run Call`, `Face Battery`, `Momentum Meter`, `Fading Boost`, `Reserve Coin`으로 교체했다.
- `Crazy Jester`, `Scary Face`, `Green Jester`, `Popcorn`, `Egg`, `Played hand`, `face cards`, `Straight`, `Flush`는 debug fixture에서 제거했다.
- 영어 Jester/Item fallback과 상점 tag label의 `Straight`/`Flush` 표현을 `run`, `same-color`, `Run`, `Color` 기준으로 바꿨다.
- 보스 modifier title/ruleText는 원본명 없이 색상/라인/확정/족보 제한으로 읽힌다.

## 4. 보스/상점/정산 설명 QA

Status: Closed for submission handoff

- [x] 보스 제약 설명이 말줄임표 없이 읽히는지 확인한다.
- [x] 타일 위 제약 배지가 숫자와 색상 바를 가리지 않는지 확인한다.
- [x] 라인 제약은 개별 타일 배지로 잘못 표시되지 않는지 확인한다.
- [x] 상점 첫 리롤 무료 문구가 `첫 리롤 무료`로 보이는지 확인한다.
- [x] 리롤 확인창에 `상점 입장 보너스로 첫 리롤은 무료입니다.`가 보이는지 확인한다.
- [x] `정찰` 표현이 플레이어 노출 텍스트에 남아 있지 않은지 확인한다.
- [x] 정산 보상/기억 카드/런 완료 문구가 짧고 명확한지 확인한다.

진행 메모:

- 보스 제약 dialog의 `ruleText`는 내부 스크롤로 표시되고 말줄임표를 쓰지 않는다.
- `test/views/game/widgets/game_shop_reroll_confirmation_test.dart`에서 무료 리롤 버튼과 확인창 문구를 검증했다.
- `test/views/game/widgets/game_cashout_widgets_test.dart`에서 기억 카드 보상, 일반 정산의 `Market으로`, 최종 정산의 `무한 도전 진입`/`런 완료` 분기를 검증한다.
- Browser Use QA에서 `boss_row_constraint_preview`는 라인 제약이 보스 팝업/preview 문구로만 표시되고 개별 타일 배지로 뜨지 않는 것을 확인했다.
- Browser Use QA에서 S1 Boss 색상 제약은 보드 위 타일 숫자와 색상 바를 가리는 별도 배지 없이 표시되는 것을 확인했다.

## 5. 핵심 Run Flow QA

Status: Closed for submission handoff

- [x] 새 run 시작 -> 전투 -> 마켓 -> 보스 -> 정산 -> 게임오버/런 완료 -> 실제 보상 획득 -> 새 run 복귀가 자연 플레이 기준 end-to-end로 끊기지 않는다.
- [x] debug fixture/즉시 클리어 보조를 사용한 split QA에서 주요 화면 전환이 끊기지 않는지 확인한다.
- [x] 새 run 시작이 정상 동작한다.
- [x] S1 전투에서 배치, 확정, 드로우, 버림이 끊기지 않는다.
- [x] 전투 후 마켓 진입이 정상 동작한다.
- [x] 구매, 판매, 장착, 사용, 리롤이 정상 동작한다.
- [x] 보스 전투 후 정산 또는 실패 흐름이 정상 동작한다.
- [x] 게임오버 시 보상 확인 후 Title 또는 새 run 화면으로 돌아갈 수 있다.
- [x] 런 완료 시 보상 확인 후 Title 또는 새 run 화면으로 돌아갈 수 있다.
- [x] 실제 기억 카드 획득 후 다음 새 run 시작 화면과 도감에서 최신 상태가 보인다.
- [x] 저장/이어하기가 현재 runtime state 기준으로 복구된다.
- [x] presentation state가 저장 기준으로 섞이지 않는다.

진행 메모:

- `test/views/game/game_view_test.dart`, `test/services/active_run_save_service_test.dart`, `test/services/run_progression_service_test.dart`, `test/services/run_unlock_state_service_test.dart`, `test/services/run_completion_flow_test.dart` 통과.
- 저장/복원 테스트에서 boss modifier, 확정 transaction, stageStartSnapshot round-trip을 확인했다.
- Browser Use로 Flutter web-server 기준 split QA를 수행했고, fresh origin은 `127.0.0.1:7360`으로 다시 확인했다.
- Title -> 새 게임 시작 -> 새 run 설정 -> 랜덤 시작 -> Station Select -> S1 전투 진입 -> 드로우 -> 타일 배치까지 실제 화면에서 확인했다. 이후 확정/마켓/보스/정산 흐름은 Browser Use smoke와 `contest_full_run_bot` full-play 증거로 닫았다.
- Browser Use로 fresh origin `127.0.0.1:7360`에서 새 run 설정 화면을 다시 확인했다. 난이도는 `표준`/`도전`만 노출되고, `도전` 선택 후 URL이 `difficulty=challenge`로 유지되며 S1 Scout 목표가 288로 표시돼 표준 240 대비 1.2배 target이 적용되는 것을 확인했다.
- `game_over_insight_ready` fixture에서 드로우 후 게임오버 dialog가 표시되고, 보상 카드가 `기억 카드 획득`으로 보이며 `나가기` 후 Title과 새 run 화면으로 복귀하는 것을 확인했다.
- `final_boss_cash_out_ready` fixture에서 S8 Boss 확정 후 정산 완료 sheet가 `런 완료`, `무한 도전 진입`, `기억 카드 획득`을 표시하고, `런 완료`는 Title로 복귀하며 `무한 도전 진입`은 Market과 S9 무한 도전 Station Select로 이어지는 구조를 확인했다.
- Browser Use QA에서 S1 전투의 드로우, 손패 버림, 타일 배치, 확정 버튼 피드백이 새 console error 없이 동작하는 것을 확인했다.
- 최신 `127.0.0.1:7361` 기준 Browser Use 한 세션에서 Title -> 새 run -> Station Select -> Scout/Clash/Boss -> 정산 -> Market -> 다음 Station 흐름을 확인했다. 전투 클리어는 디버그 `현재 구간 즉시 클리어` 보조를 사용했다.
- 같은 Browser Use QA 세션에서 `final_boss_cash_out_ready` fixture로 S8 정산 완료 -> `런 완료` -> Title -> `새 게임 시작` -> 새 run 화면 복귀까지 최신 문구 기준으로 다시 확인했다.
- 위 split QA 자체는 화면 전환 smoke였지만, 디버그 보조 없는 S1~S8 full-play는 `contest_full_run_bot` 증거로 별도 확보했다.
- 실제 보상 획득/저장/도감 반영은 widget/service test와 최신 Browser/CDP smoke 기준으로 확인했다.
- 2026-05-07: 게임오버에서 `새 run 준비` CTA를 추가했고, 보상/수집 기록은 `run_unlock_state_v1`에 저장해 새 run 화면과 도감에서 읽을 수 있게 했다. 이후 full-play bot QA는 제출용 handoff 기준으로 닫았다.

## 6. 게임오버/런 완료 보상 루프

Status: Closed for submission handoff

- [x] 패배 시 기억 카드 보상이 보인다.
- [x] 패배 후 Title 또는 새 run 화면으로 자연스럽게 돌아간다.
- [x] S8 boss 완료 후 런 완료 또는 무한 도전 진입을 선택할 수 있다.
- [x] 런 완료 보상 후 내부 메타 값이 반영된다.
- [x] 게임오버/런 완료 기억 카드 보상이 단순 내부 수치가 아니라 획득 이력으로 저장된다.
- [x] 획득한 기억 카드 보상이 새 run 화면과 도감에서 확인된다.
- [x] high stakes 해금/선택 상태가 기존 저장과 충돌하지 않는다.
- [x] 새 run 재시작 동선이 심사자가 이해할 수 있게 이어진다.
- [x] 회차 결과 보상 산식이 도달 스테이션, 보스 처치 수, 클리어 여부를 기준으로 계산되는지 확인한다.
- [x] 보상이 다음 run의 선택지를 여는 역할에 머물고, 인런 자동 지급이나 특정 성장 강제가 되지 않는지 확인한다.
- [x] high stakes처럼 회차 선택으로 바뀌는 target/reward 배율이 UI preview, runtime, 저장/복원에서 같은 값으로 이어지는지 확인한다.
- [x] 회차 보상이 너무 커서 다음 run 난이도를 무효화하지 않는지 공모전 기준 known risk로 남길지 판단한다.

진행 메모:

- `GameOverInsightRewardCard`와 `GameCashOutSheet` 테스트에서 기억 카드 보상과 `런 완료` 분기를 확인한다.
- `RunProgressionService`와 `RunUnlockStateService` 테스트에서 보상/해금 상태 갱신을 확인했다.
- 현재 내부 보상 산식은 도달 스테이션, 보스 처치 수, 클리어 보너스를 더해 메타 보상값을 계산한다.
- 플레이어에게는 수치 재화가 아니라 `기억 카드` 전용 보상처럼 보여준다. 내부 `insight` 계열 값은 유지하되, 별도 `earnedMemoryCardIds` 이력을 함께 남긴다.
- 현재 `high_stakes`는 내부 메타 보상값으로 해금되며 target score 1.04, reward 1.12를 명시 적용한다. 직접 골드, 아이템, Jester, 자원을 지급하지 않는다.
- S8 Boss 정산 후 `무한 도전 진입`을 고르면 S8 승리 보상/난이도 해금을 1회 처리한 뒤 Market으로 들어가고, 다음 Station에서 S9+ 기록 도전으로 이어진다.
- S9+ 무한 도전 target은 Station 기준 점수 상승에 Scout 1배, Clash 1.5배, Boss 2배를 적용한다.
- S8 승리 보상은 `runCompletionRewardClaimed`로 저장/복원해 계속 진행 중 중복 지급되지 않게 했다.
- 보상 산식상 S8 완료 보상은 기억 카드 36이며, 현재 이 값은 인런 자원이 아니라 `하이 스테이크` 같은 다음 런 규칙을 여는 데만 쓰인다. 공모전 기준으로는 다음 run 난이도를 무효화하는 즉시 위험보다 해금 선택 폭이 아직 얕은 점을 known risk로 둔다.
- Browser Use QA에서 패배 후 `나가기` -> Title -> `새 게임 시작` -> 새 run 설정 화면 복귀를 확인했다.
- Browser Use QA에서 런 완료 후 `런 완료` -> Title -> `새 게임 시작` -> 새 run 설정 화면 복귀를 확인했다.
- 최신 소스 기준 게임오버/런 완료 보상은 수치 재화 문구가 아니라 `기억 카드 획득` 카드로 보인다. 이전 `build/web` 산출물에서는 stale build 때문에 구버전 보상 문구가 보였으므로 제출 후보 빌드는 반드시 최신 소스로 재빌드해야 한다.
- 실제 보상 아이템/Jester 지급은 아직 없다. 현재 보상 이력은 기억 카드류 보상에 한정한다.

## 7. 도감/수집 확인

Status: Closed for submission handoff

- [x] Title에서 도감 화면으로 들어갈 수 있다.
- [x] 도감 placeholder에 `기억 카드`가 전용 보상 카드처럼 표시된다.
- [x] 도감 placeholder에 `하이 스테이크` 런 규칙 설명이 표시된다.
- [x] 도감 placeholder에 Jester/Item/Boss 주요 항목이 표시된다.
- [x] 기억 카드가 어떤 해금에 쓰이는지 도감과 새 run 화면이 같은 말로 설명한다.
- [x] 도감 화면에서 수치 재화처럼 보이는 `Insight +N` 표현이 노출되지 않는다.
- [x] 도감이 실제 발견/획득/구매/클리어 상태를 저장하고 복원한다.
- [x] 마켓에 한 번이라도 나온 Jester/Item을 발견 항목으로 남긴다.
- [x] 구매한 Jester/Item을 획득 이력으로 남긴다.
- [x] 게임오버/런 완료 보상으로 얻은 기억 카드류 보상을 도감에 남긴다.
- [x] 만난 Boss와 보스 규칙을 도감에 남긴다.
- [x] 클리어한 스테이지/Station/Boss 진행 이력을 도감에서 확인할 수 있다.
- [x] 도감 항목이 공모전 제출 기준에서 필요한 발견/획득/클리어 이력을 구분해 저장하고 표시한다.

진행 메모:

- Title의 `기록실` 진입은 `도감`으로 바꿨다.
- 도감에는 `기억 카드`, `하이 스테이크`, `Jester`, `Item`, `Boss` 항목을 공모전 확인용 placeholder로 먼저 배치했다.
- 게임오버 보상, 새 run 화면, 도감 화면에서 `Insight +N` 같은 수치 재화 표현이 보이지 않는 것을 grep과 web screenshot으로 확인했다.
- 내부 메타 보상값은 유지하되, 도감용 수집 이력은 `run_unlock_state_v1`의 `seenMarketJesterIds`, `seenMarketItemIds`, `boughtJesterIds`, `boughtItemIds`, `seenBossModifierIds`, `clearedStationKeys`, `earnedMemoryCardIds`에 따로 저장한다.
- 도감은 내 기록 섹션에서 실제 Jester 카드 face와 Item 카드 face를 재사용해 보여준다. 구매/Boss/Station은 공모전 기준 요약 텍스트로 충분하다고 판단하고, 미발견/발견/획득/클리어를 더 세분화한 전용 상세 UI는 공모전 이후 polish로 둔다.
- Browser Use QA에서 Title의 `도감` 진입, `기억 카드`, `하이 스테이크`, `Jester`, `Item`, `Boss` 항목 표시를 확인했다.
- 최신 소스 기준 새 run 화면은 `기억 카드 보유`, `기억 카드 필요`, `기억 카드로 해금`으로 표시된다.

## 8. Submission Smoke

Status: Closed for submission handoff

- [x] `flutter analyze` 통과.
- [x] 핵심 `flutter test` 통과.
- [x] 최신 변경 후 `flutter build web` 통과.
- [x] Browser/WebDriver + Compute Use hybrid bot으로 S1~S8 실제 UI clear 가능한 checkpoint-resume 경로를 검증한다.
- [x] full-play bot 로그에 마켓 구매 증거를 남긴다.
- [x] 제출 후보 빌드에서 콘솔 에러나 화면 깨짐이 없는지 확인한다.
- [x] 최종 빌드 산출물과 실행 경로를 정리한다.

진행 메모:

- `tools/prototype_submission_smoke.sh --skip-pub-get` 통과.
- 로그 경로: `/tmp/rummipoker_submission_smoke/20260507_132745`
- 자동 smoke는 코드 분석, 핵심 테스트, web 빌드 생성까지 확인했다. 실제 화면 조작과 콘솔 확인은 browser/compute QA에서 별도로 닫는다.
- Browser Use는 `tool_search`에서 `mcp__node_repl__.js`가 노출되어 정상 사용 가능했다. Computer Use fallback은 사용하지 않았다.
- 최신 Flutter web-server 기준 Browser Use QA에서 Title/new run/S1 전투 진입/게임오버 보상/런 완료 보상/도감 진입을 확인했다.
- 웹 제출 후보에서는 `WakelockPlus` 호출을 건너뛰어 브라우저의 wake lock 거부가 console error로 남지 않게 했다. Browser Use timestamp-filter console check에서 새 error/warn 0건을 확인했다.
- 최신 소스 기준 `flutter build web` 통과. 제출 후보 산출물은 `build/web`이며, 현재 눈검증용 Flutter web-server는 `http://127.0.0.1:7361`에서 실행 중이다.
- 이전 `127.0.0.1:7360` 서버는 stale 문자열을 보여줄 수 있으므로, 제출 전 확인은 최신 빌드 또는 새로 띄운 서버 기준으로 한다.
- `127.0.0.1:7361` Browser Use full route QA 후 `tab.dev.logs` 기준 error/warn 0건을 확인했다.
- 이후 도감/게임오버/수집 저장 변경 뒤 제출 후보 build와 browser QA를 다시 닫았다.
- 2026-05-08 기준 공모전 full-play QA는 사람 수동 플레이가 아니라 `docs/planning/competition/COMPUTE_BROWSER_FULL_PLAY_BOT.md`의 Browser/WebDriver + Compute Use hybrid bot 기준으로 닫는다.
- 2026-05-08 `contest_full_run_bot`은 checkpoint/resume 기반으로 S8 boss까지 클리어했고, 과거 pass 로그는 `/tmp/rummipoker_contest_full_run_bot/resume_s8_boss_final_pass/10_contest_full_run_bot.log`다.
- 과거 pass 로그에는 `S8 boss: used battle Item slide_wax op=mark_next_board_move_bonus`, `game over -> retry 1/24`, `All tests passed.`가 포함된다.
- 2026-05-09 최신 보정 후보 로그는 `/tmp/rummipoker_contest_full_run_bot/resume_s8_shop_boss_score_weight_20260509_140900/10_contest_full_run_bot.log`다.
- 최신 후보에서 S8 big은 retry 6의 `417 + 617 + 705 = 1739/1738`로 통과했고, S8 boss는 `116 + 212 + 290 + 80 = 698/1739` 이후 retry 2에서 `Timed out waiting for game state update`로 끊겼다.
- 관련 최신 커밋은 `18f0b53 Tune boss retry deck scoring`이다. 이 결과는 5장 lookahead와 boss retry 점수 가중치가 S8 big에는 효과가 있었지만, S8 boss에는 runtime 족보 성장축이 필요하다는 근거로 남긴다.

## 9. 심미성/재미도 재점검

Status: Closed for submission handoff

- [x] 게임오버 dialog의 `기억 카드 획득` 카드가 보상처럼 보이는지 확인한다.
- [x] `다시 도전`, `새 run 준비`, `나가기` 버튼 우선순위가 자연스러운지 확인한다.
- [x] 도감의 Jester/Item 실물 카드 face가 작거나 답답하지 않은지 확인한다.
- [x] 도감에서 구매/Boss/Station 기록이 텍스트 요약으로만 남아도 공모전 기준 충분한지 판단한다.
- [x] 새 run 화면에서 기억 카드/규칙 해금 정보가 다음 런 동기로 읽히는지 확인한다.
- [x] 마켓 구매/판매/리롤이 심사자가 보기에도 카드 게임 액션처럼 보이는지 확인한다.
- [x] 정산 sheet가 보상/진행의 쾌감을 충분히 주는지 확인한다.
- [x] 보스 제약이 어렵게 느껴지되 억울하거나 설명 부족으로 보이지 않는지 확인한다.

진행 메모:

- 이 섹션은 기능 완성 체크가 아니라 제출 전 눈검증/영상 기준 체크다.
- 공모전 제출 기준으로는 닫았고, 추가 개선이 필요하면 새 시스템을 크게 추가하지 않고 문구, 버튼 위계, spacing, 카드 face 재사용, 화면 전환 안정화 범위에서만 다룬다.

## 10. Feature Freeze 기준

Status: Closed for submission handoff

- [x] 새 레벨링/경제/ML 조정은 공모전 이후로 미룬다.
- [x] 족보 완성 시 족보 자체가 게임오버 없이 이어지는 하나의 run 전체에서 성장하고, 그 run의 이후 전투 점수에 반영되는 최소 저장/정산 변경은 공모전 풀런봇 재개 전에 먼저 닫는다.
- [x] 게임 중/게임 밖에서 족보 성장 상태를 확인하는 `런 정보` 화면 또는 동등한 UI를 공모전 풀런봇 재개 전에 먼저 닫는다.
- [x] 그 외 대형 저장 포맷 변경은 공모전 이후로 미룬다.
- [x] `run_unlock_state_v1`에 도감 수집 이력을 추가한 소형 변경은 공모전 핵심 흐름 보강으로 적용하고 테스트했다.
- [x] 신규 대형 UI 구조 변경은 공모전 이후로 미룬다.
- [x] 제출 전에는 버그 수정, 문구 정리, QA 안정화만 허용한다.

진행 메모:

- 족보 성장 최소 런타임은 반영됐다. 추가로 칩 축 UI 표시, Planet-like 직접 족보 성장 아이템군, 초과 클리어 대표 족보 성장 보너스까지 반영했다.
- `handGrowthStates(level/progress/requiredProgress)` 분리까지 반영해, Jester/통계용 `playedHandCounts`와 실제 성장 점수 source가 분리됐다.
- 타이틀 화면에서 저장된 현재 런의 `런 정보`를 바로 열 수 있고, 게임오버 dialog는 이번 런 정산 요약과 랜덤 도발 문구를 보여준다. 정산 progress bar는 이번 범위에서 제외했다.
- 자연 full end-to-end QA, 최신 빌드 산출물/실행 경로 정리, 문구/시각/재미도 회귀 확인은 제출용 handoff 기준으로 닫았다.
- ML 리포트 갱신, 큰 화면 구조 변경, 반복 플레이용 깊은 해금 구조는 제출 후 polishing으로 분리한다.

## Known Risk

- `power none`은 fresh r400 일부 seed에서 58.8~62.0%로 목표 45~55%보다 높다.
- `balanced v9`는 fresh seed 93041에서 59.0%로 목표 60%를 살짝 밑돈다.
- 현재는 장기 밸런스 완료가 아니라 공모전 임시 handoff다.
- 장기 밸런스에서는 multi-seed r400/r800과 ML 리포트 갱신을 다시 수행한다.
- Browser/WebDriver + Compute Use hybrid bot은 과거 checkpoint pass, 최신 fresh 표준 pass, `ko/en` 표준→도전 cycle, 최신 후보 `ko` 재확인 pass를 확보했다.
- 족보별 레벨 성장과 덱 확장 축이 들어간 뒤 최신 도전 난이도 fresh full-run은 `ko/en` 및 최신 `ko` 재확인 기준으로 S8 boss까지 통과했다.
- 족보 성장 상태는 `런 정보`에서 확인 가능하고, 최신 build 기준 Browser/WebDriver와 눈검증으로 실제 가시성을 확인했다.
- 게임오버 후 새 run까지 이어지는 영구 계승은 이번 1차 범위에서 제외한다. 현재 중요한 것은 유저가 게임오버 없이 이어지는 하나의 run 동안 사용한 족보가 성장 기록으로 남고, 그 run의 이후 전투 점수에 추가 반영되는 것이다.
- 도감은 수집/발견/구매/보상/보스/스테이지 이력을 저장하지만, 아직 항목별 미발견/발견/획득/클리어 상태를 나눈 상세 UI는 없다.
- 기억 카드 보상은 내부 `insight` 계열 값을 유지하면서 `earnedMemoryCardIds` 획득 이력을 함께 남긴다. 실제 보상 아이템/Jester 지급은 아직 없다.
