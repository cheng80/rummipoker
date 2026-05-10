# Compute + Browser Full-Play Bot

> 문서 성격: 공모전 제출용 실제 UI full-play QA bot 제작 기준
> 호출 별명: `공모전 풀런봇`
> 영문 식별자: `contest_full_run_bot`
> 부분 실행 별명: `공모전 서브런봇`
> 부분 실행 영문 식별자: `contest_sub_run_bot`
> 1차 실행 환경: Browser/WebDriver + Compute Use hybrid
> 2차 보조 환경: Codex 앱 내장 Browser Use
> 현재 실행 라우터: `docs/planning/ACTIVE_EXECUTION_PLAN.md`
> 공모전 체크리스트: `docs/planning/competition/COMPETITION_SUBMISSION_CHECKLIST.md`

## 0. 제작 결론

공모전 full-play QA는 사람 수동 플레이가 아니라 제작된 bot 기준으로 닫는다.
bot은 Browser/WebDriver의 실행·로그 수집과 Compute Use의 화면 좌표·시각 조작을 함께 사용해 실제 Flutter Web 화면을 플레이한다.

2026-05-09 현재 `contest_full_run_bot`은 최신 룰/UI 후보에서 fresh 표준 난이도 S1~S8 boss pass 증거를 확보했다. 2026-05-10에는 `ko`, `en` locale 표준→도전 2사이클도 통과했다.
이전 체크포인트/재시도 기반 S8 boss pass 증거와, S8 boss 실패/timeout을 만들었던 최신 보정 후보 로그도 기준선으로 남긴다.
다음 full-run 재개는 사용자 승인 후 `ja` fresh 표준 gate다. 제출 gate는 지원 locale 5개(`ko`, `en`, `ja`, `zh-CN`, `zh-TW`) 각각에서 fresh 표준 난이도 S1~S8 Boss를 먼저 클리어한 뒤, 같은 locale fresh 도전 난이도 S1~S8 Boss와 S8 정산/보상/무한 도전 진입 직전까지 확인해 닫는다. 5개 locale을 한 번에 연속 실행하지 않고 한 locale cycle 완료/점검/사용자 승인 후 다음 locale을 시작한다.
fresh 표준 로그에 Flutter semantics route label 경고가 반복 출력됐으나, 2026-05-10 route/dialog label 보정 뒤 최신 build smoke에서는 재현되지 않았다.
locale별 표준/도전 full-run 로그에서도 같은 console 0건 기준으로 다시 확인한다.
S8 boss 이후는 정식 `무한 도전` 진입 UX로 정리했다. 제출 gate는 각 locale에서 표준 S8 Boss clear를 먼저 확인한 뒤, 도전 S8 Boss clear와 S8 정산/보상/무한 도전 진입 직전 확인까지이며, S9+ 무한 도전 자체의 장기 생존은 제출 gate로 요구하지 않는다.
full-run 중 수정 범위는 game over에 한정하지 않는다. 실제 플레이 도중 UI overflow, 튜토리얼 target/문구 문제, Jester/Item/자원 카드의 제목·설명 잘림, locale별 텍스트 넘침이 보이면 제출 QA 결함으로 보고 수정 뒤 해당 locale gate를 다시 실행한다.
각 locale cycle의 standard 실행은 저장 세션/SharedPreferences와 WebDriver Chrome profile의 cookie/localStorage/sessionStorage를 지운 fresh 세션에서 시작한다. 첫 전투와 첫 Market 튜토리얼이 표시되고 `Next/Done`으로 완료되는지, 스킵/완료/포커스 아웃 처리 기준이 깨지지 않는지도 full-run QA에 포함한다. 같은 locale의 challenge 실행은 새 run으로 시작하되 같은 cycle 내부 진행이므로 tutorial seen 상태를 유지한다. 튜토리얼 overlay가 떠 있으면 bot은 전투/마켓 실제 액션보다 튜토리얼 완료를 먼저 처리한다.
각 테스트 실행/실패/중단 후에는 WebDriver Chrome, Google Chrome Helper, ChromeDriver, Flutter web 서버를 정리한다. 다음 실행 전에도 같은 cleanup을 먼저 수행해 이전 테스트의 helper 프로세스가 메모리와 profile을 붙잡지 않게 한다.

과거 checkpoint pass 증거:

- commit: `9262e6d Stabilize contest full run bot strategy`
- 최종 pass 로그: `/tmp/rummipoker_contest_full_run_bot/resume_s8_boss_final_pass/10_contest_full_run_bot.log`
- 핵심 로그:
  - `S8 boss: used battle Item slide_wax op=mark_next_board_move_bonus`
  - `game over -> retry 1/24`
  - `All tests passed.`
- 보조 검증:
  - `flutter analyze integration_test/competition_bot_policy.dart integration_test/competition_full_play_bot_test.dart test/competition_bot_policy_test.dart`
  - `flutter test test/competition_bot_policy_test.dart test/views/game/widgets/game_shop_screen_save_flush_test.dart`

최신 보정 후보 기준선:

- commit: `18f0b53 Tune boss retry deck scoring`
- 로그: `/tmp/rummipoker_contest_full_run_bot/resume_s8_shop_boss_score_weight_20260509_140900/10_contest_full_run_bot.log`
- S8 big retry 6:
  - `417 + 617 + 705 = 1739/1738`
  - `S8 big: cashout -> market`
- S8 boss retry 0/1:
  - `116 + 212 + 290 + 80 = 698/1739`
  - `game over -> retry 2/24`
- S8 boss retry 2:
  - 진행 중 `Timed out waiting for game state update`
- 판단:
  - 5장 deck lookahead와 late confirm 보정은 S8 big 통과에 효과가 있었다.
  - S8 boss는 같은 색상 플러시 축과 장기 족보 성장 축이 약해, bot 정책만으로 안정화하면 QA 보정이 과해진다.
- 현재는 `contest_full_run_bot` 재실행보다 족보 성장/덱 확장 같은 런타임 규칙 보강을 먼저 한다.
- 족보 성장은 이번 1차 범위에서 게임오버 없이 이어지는 하나의 run 전체의 성장 기록과 이후 전투 점수 반영으로 다룬다. 게임오버 후 새 run까지 이어지는 영구 계승은 별도 검토로 남긴다.

최신 fresh 표준 pass 기준선:

- 로그: `/tmp/rummipoker_contest_full_run_bot/fresh_after_reward_tile_rules_20260509_201727/10_contest_full_run_bot.log`
- 실행 조건: `--seed 91460 --difficulty standard --web-port 7362 --skip-pub-get`
- 결과:
  - `CONTEST_FULL_RUN_BOT_PASS`
  - `All tests passed!`
  - `S8 boss: run complete`
- S8 boss 정산:
  - `confirm=870/3`
  - `confirm=728/2`
  - `confirm=312/1`
  - 목표 `1739` 통과
- game over/retry:
  - 없음
- 보스 클리어 덱 타일 보상:
  - S2 `deck=53`
  - S3 `deck=54`
  - S4 `deck=55`
  - S5 `deck=56`
  - S6 `deck=57`
  - S7 `deck=58`
  - S8 `deck=59`
- 자원 사용 정책 관찰:
  - 초반 증거용 이동/버림은 보이지 않았다.
  - S3 big, S6 small/big, S7/S8 구간의 보드 이동/버림은 확정 점수 또는 중복줄 형성에 연결됐다.
- 남은 문제:
  - `Semantic node ... scopesRoute and namesRoute ... missing the label` 경고가 cashout/market 전환마다 반복됐다.
  - 2026-05-10 최신 build smoke에서는 같은 경고가 재현되지 않았다. 도전 full-run에서 최종 재확인한다.

2026-05-10 `ko` fresh 표준 locale gate 증거:

- 로그: `/tmp/rummipoker_contest_full_run_bot/standard_ko_20260510_104511/10_contest_full_run_bot.log`
- 출력 디렉터리: `/tmp/rummipoker_contest_full_run_bot/standard_ko_20260510_104511`
- 실행 조건: `--seed 91460 --difficulty standard --locale ko --web-port 7363 --browser-profile-dir /tmp/rummipoker_contest_full_run_bot/standard_ko_profile_20260510_104511 --output-dir /tmp/rummipoker_contest_full_run_bot/standard_ko_20260510_104511 --skip-pub-get`
- 결과:
  - `CONTEST_FULL_RUN_BOT_PASS`
  - `All tests passed!`
  - `S8 boss: run complete`
- locale/fresh 조건:
  - `locale=ko`
  - `resolvedLocale=ko`
  - `freshStorage=true`
- 튜토리얼:
  - battle tutorial completed
  - market tutorial completed
- S8 boss 정산:
  - `confirm=951/3`
  - `confirm=778/2`
  - `confirm=246/1`
  - 목표 `1739` 통과
- game over/retry/Flutter semantics warning/UI overflow/error/warn:
  - 없음
- 보스 클리어 덱 타일 보상:
  - S2 `deck=53`
  - S3 `deck=54`
  - S4 `deck=55`
  - S5 `deck=56`
  - S6 `deck=57`
  - S7 `deck=58`
  - S8 `deck=59`
- 종료 후 WebDriver Chrome, Chrome Helper, ChromeDriver, Flutter web 서버 잔류 프로세스 없음

2026-05-10 `ko` fresh 도전 locale gate 증거:

- 로그: `/tmp/rummipoker_contest_full_run_bot/challenge_ko_20260510_115046/10_contest_full_run_bot.log`
- 출력 디렉터리: `/tmp/rummipoker_contest_full_run_bot/challenge_ko_20260510_115046`
- 실행 조건: `--seed 91460 --difficulty challenge --locale ko --web-port 7364 --browser-profile-dir /tmp/rummipoker_contest_full_run_bot/challenge_ko_profile_20260510_115046 --output-dir /tmp/rummipoker_contest_full_run_bot/challenge_ko_20260510_115046 --tutorials-already-seen --skip-pub-get`
- 결과:
  - `CONTEST_FULL_RUN_BOT_PASS`
  - `All tests passed!`
  - `S8 boss: run complete`
- locale/fresh 조건:
  - `locale=ko`
  - `resolvedLocale=ko`
  - `freshStorage=true`
  - `difficulty=challenge`
- 튜토리얼:
  - 같은 locale cycle 내부 challenge 실행이라 `--tutorials-already-seen`으로 battle/market tutorial seen 상태를 유지했다.
  - 이 실행에서는 fresh tutorial completed 로그를 pass 요구사항으로 보지 않는다.
- S8 small 정산:
  - `confirm=1622/2`
  - `confirm=230/1`
  - 목표 `1729` 통과
- S8 big 정산:
  - `confirm=1009/2`
  - `confirm=1032/2`
  - `confirm=368/1`
  - 목표 `2086` 통과
- S8 boss 정산:
  - `confirm=1010/3`
  - `confirm=869/2`
  - `confirm=312/1`
  - 목표 `2087` 통과
- S8 시작 덱:
  - `deck=59`
- game over/retry/Flutter semantics warning/UI overflow/error/warn:
  - 없음
- 종료 후 WebDriver Chrome, Chrome Helper, ChromeDriver, Flutter web 서버 잔류 프로세스 없음
- 다음 상태:
  - `ko` cycle은 닫혔다.

2026-05-10 `en` fresh 표준 locale gate 증거:

- 로그: `/tmp/rummipoker_contest_full_run_bot/standard_en_20260510_140623/10_contest_full_run_bot.log`
- 출력 디렉터리: `/tmp/rummipoker_contest_full_run_bot/standard_en_20260510_140623`
- 실행 조건: `--seed 91460 --difficulty standard --locale en --web-port 7365 --browser-profile-dir /tmp/rummipoker_contest_full_run_bot/standard_en_profile_20260510_140623 --output-dir /tmp/rummipoker_contest_full_run_bot/standard_en_20260510_140623 --skip-pub-get`
- 결과:
  - `CONTEST_FULL_RUN_BOT_PASS`
  - `All tests passed!`
  - `S8 boss: run complete`
- locale/fresh 조건:
  - `locale=en`
  - `resolvedLocale=en`
  - `freshStorage=true`
- 튜토리얼:
  - battle tutorial completed
  - market tutorial completed
- S8 small 정산:
  - `confirm=1539/2`
  - 목표 `1441` 통과
- S8 big 정산:
  - `confirm=902/2`
  - `confirm=925/2`
  - 목표 `1738` 통과
- S8 boss 정산:
  - `confirm=951/3`
  - `confirm=778/2`
  - `confirm=246/1`
  - 목표 `1739` 통과
- S8 시작 덱:
  - `deck=59`
- game over/retry/Flutter semantics warning/UI overflow/error/warn:
  - 없음
- 종료 후 WebDriver Chrome, Chrome Helper, ChromeDriver, Flutter web 서버 잔류 프로세스 없음

2026-05-10 `en` fresh 도전 locale gate 증거:

- 로그: `/tmp/rummipoker_contest_full_run_bot/challenge_en_20260510_145813/10_contest_full_run_bot.log`
- 출력 디렉터리: `/tmp/rummipoker_contest_full_run_bot/challenge_en_20260510_145813`
- 실행 조건: `--seed 91460 --difficulty challenge --locale en --web-port 7366 --browser-profile-dir /tmp/rummipoker_contest_full_run_bot/challenge_en_profile_20260510_145813 --output-dir /tmp/rummipoker_contest_full_run_bot/challenge_en_20260510_145813 --tutorials-already-seen --skip-pub-get`
- 결과:
  - `CONTEST_FULL_RUN_BOT_PASS`
  - `All tests passed!`
  - `S8 boss: run complete`
- locale/fresh 조건:
  - `locale=en`
  - `resolvedLocale=en`
  - `freshStorage=true`
  - `difficulty=challenge`
- 튜토리얼:
  - 같은 locale cycle 내부 challenge 실행이라 `--tutorials-already-seen`으로 battle/market tutorial seen 상태를 유지했다.
  - 이 실행에서는 fresh tutorial completed 로그를 pass 요구사항으로 보지 않는다.
- S8 small 정산:
  - `confirm=1622/2`
  - `confirm=230/1`
  - 목표 `1729` 통과
- S8 big 정산:
  - `confirm=1009/2`
  - `confirm=1032/2`
  - `confirm=368/1`
  - 목표 `2086` 통과
- S8 boss 정산:
  - `confirm=1010/3`
  - `confirm=869/2`
  - `confirm=312/1`
  - 목표 `2087` 통과
- S8 시작 덱:
  - `deck=59`
- game over/retry/Flutter semantics warning/UI overflow/error/warn:
  - 없음
- 종료 후 WebDriver Chrome, Chrome Helper, ChromeDriver, Flutter web 서버 잔류 프로세스 없음
- 다음 상태:
  - `en` cycle은 닫혔다. 사용자 승인 후 `ja` fresh 표준 난이도 S1부터 실행한다.

2026-05-10 locale cycle 제외 검증:

- `flutter analyze` 통과
- 핵심 `flutter test` 묶음 통과
- `flutter build web` 통과
- Browser/CDP smoke 통과: `/`, `/new-run`, `/archive`, `/game?fixture=game_over_insight_ready&debug_show_game_over_on_load=1`, `/game?fixture=final_boss_cash_out_ready&debug_complete_run_on_load=1` 모두 앱 warn/error/exception 0건
- Headless Chrome의 `Falling back to CPU-only rendering`은 WebGL 없는 headless 환경 경고라 앱 경고로 집계하지 않는다.

앞으로 대화에서 `공모전 풀런봇 실행`, `공모전 풀런봇 준비`, `공모전 풀런봇 이어서`라고 말하면 이 문서의 Browser/WebDriver + Compute Use hybrid full-play gate를 뜻한다.
스크립트, 로그 prefix, 파일명에는 영문 식별자 `contest_full_run_bot`을 사용한다.

같은 엔진을 특정 목표 지점까지만 실행할 때는 `공모전 서브런봇`이라고 부른다.
스크립트, 로그 prefix, 파일명에는 영문 식별자 `contest_sub_run_bot`을 사용한다.

제작 기준:

- 1차 제출 gate는 Browser/WebDriver와 Compute Use를 결합해 재실행 가능해야 한다.
- Codex 앱 내장 Browser Use는 bot 실패 분석, 보조 눈검증, 최종 감각 확인에 사용한다.
- Browser/WebDriver는 앱 실행, console 확인, trace/video/screenshot 저장, runtime 상태 수집을 맡는다.
- Compute Use는 손패 타일, 보드 셀, 마켓 카드처럼 Flutter transform/canvas/semantics 때문에 selector tap이 흔들리는 실제 화면 조작을 맡는다.
- `tools/sim/planner_bot.dart`의 `planner_v2` 전투 판단은 재사용한다.
- 기존 시뮬레이션 bot만으로 통과 처리하지 않는다. 실제 UI 조작 증거가 필요하다.
- debug fixture, 즉시 클리어, forced reward 같은 보조 경로는 full-play 증거로 쓰지 않는다.

현재 구현/정책 요약:

- full-run은 `tools/contest_full_run_bot.sh`로 실행한다.
- 실패 시 game over에서 재시도하며, 저장된 active run checkpoint부터 이어서 실행할 수 있다.
- 체크포인트 재개 시 Jester/Item 구매 이력과 실제 전투 진행 상태를 저장 상태에서 복원한다.
- 보스 클리어 덱 타일 보상은 마켓 tile offer 자리를 무료 보상으로 차지하지 않는다. 정산 화면에서 실제 타일 face로 보이고, 정산 시점에 즉시 덱에 추가되어 다음 전투부터 쓰인다.
- 마켓 tile offer는 실제 타일 face로 표시하고, 구매 시 오른쪽 중단 덱 방향으로 날아가는 연출을 쓴다. 선택 표시는 카드형 프레임이 아니라 타일 크기에 맞춘 selector만 사용한다.
- S8 boss는 bot 정책에서만 작은 확정을 억제하고, 완성 직전 라인 수, 교차 유망 라인 수, 손패/덱 기반 1-step lookahead로 중복줄 확정 가능성을 평가한다.
- 최신 fresh 표준 run에서는 족보 레벨 성장과 덱 확장/보상 타일 축이 들어간 상태로 S8 boss까지 통과했다. `ko`, `en` 도전 난이도도 S8 boss까지 통과했으며, 남은 `ja`, `zh-CN`, `zh-TW` locale의 도전 난이도는 아직 미검증이다.
- S8 boss 정산의 계속 진행 버튼은 `무한 도전 진입`으로 표시한다. S9+는 Scout 1배, Clash 1.5배, Boss 2배 target 비율을 따르고, Station Select/전투 HUD/정산 라벨은 위험 구간 색상으로 표시한다.
- 후반 game over 대응은 봇 전용 가중치 숫자 조정보다 족보/중복줄 확정, 손패 여유 칸, 보드 이동/버림, 아이템 사용, 구매/판매 전략을 함께 점검한다.
- 마켓에서는 Jester 슬롯/골드가 허용하는 한 구매를 시도하고, 슬롯이 꽉 찬 경우 더 좋은 후보가 있으면 약한 Jester 판매 후 교체한다. 후반에는 구간별 등장 확률을 올린 Jester/Item을 안정화 구매 후보로 더 높게 평가한다.
- Item 구매 정책은 Q-Slot만 보지 않고 Q-Slot/Passive/Tool/Gear lane의 모든 affordable offer를 평가한다. `*_study`처럼 족보 성장을 직접 올리는 행성카드형 아이템은 후반 안정화 후보로 높게 평가한다.
- Q-Slot이 비어 있으면 과거 구매 이력이 있더라도 새 Item 구매를 검토한다. 단, 아이템 사용은 족보 형성 또는 확정 점수 개선이 분명할 때만 한다.
- 단일 fresh process로 S1부터 S8까지 끊김 없이 다시 도는 최종 회귀는 제출 직전 한 번 더 돌리는 것을 권장한다.

## 0.1 실행 방식 판단

1차 후보는 Browser/WebDriver + Compute Use hybrid다.
이유는 trace, video, screenshot, console log를 자동 산출물로 남기면서도 Flutter Web의 실제 화면 좌표 조작을 안정적으로 수행할 수 있기 때문이다.

단, Flutter Web은 일반 DOM 앱과 다르게 canvas/semantics 렌더링이 섞여 selector가 불안정할 수 있다.
Playwright나 Flutter `integration_test`의 selector/tap이 안정적이지 않으면 Browser-only 통과를 고집하지 않고 Compute Use 좌표 실행으로 전환한다.
이 경우에도 기준은 같다. 실제 Chrome에서 실행되고, debug fixture 없이 S1~S8을 UI action으로 클리어해야 한다.

| 후보 | 사용 판단 | 역할 |
|---|---|---|
| Browser/WebDriver + Compute Use | 1차 gate | 앱 실행, console/trace 수집, 화면 좌표 기반 실제 조작 |
| Playwright | text/role/key 기반 조작이 안정적인 구간에 사용 | trace/video/screenshot/console evidence |
| Flutter `integration_test` on Chrome | planner 상태 수집과 재현 가능한 smoke에 사용 | 실제 Chrome 실행 + widget 상태 확인 |
| Codex Browser Use | 1차 gate로 쓰지 않음 | 실패 분석, 보조 눈검증, 최종 감각 확인 |

## 0.2 실행 별명과 호출 예시

`공모전 풀런봇`은 S1부터 S8 boss 이후 런 완료/보상/도감 확인까지 닫는 최종 제출 gate다.
`공모전 서브런봇`은 같은 엔진을 쓰되 종료 조건만 제한해 특정 지점까지 빠르게 재현하는 부분 실행 bot이다.

| 별명 | 영문 식별자 | 목적 | 기본 종료 조건 |
|---|---|---|---|
| `공모전 풀런봇` | `contest_full_run_bot` | 최종 제출 full-play gate | locale별 표준 S8 Boss clear 후 같은 locale 도전 S8 Boss clear, S8 정산/보상/무한 도전 진입 직전 확인, 5개 locale cycle fresh 통과 |
| `공모전 서브런봇` | `contest_sub_run_bot` | 특정 stage/scene까지 재현, 실패 구간 격리 | 사용자가 지정한 target 도달 |

사용자가 이렇게 말하면 같은 의미로 해석한다.

- `공모전 풀런봇 실행`: S1부터 S8 boss 이후 제출 Done 기준까지 진행한다.
- `공모전 풀런봇 이어서`: 마지막 중단 지점과 로그를 확인해 가능한 경우 이어서 진행한다.
- `공모전 서브런봇 S3까지`: S3의 지정 tier 또는 기본 boss clear 후 정지한다. tier가 없으면 S3 boss clear를 기본 목표로 본다.
- `공모전 서브런봇 S5 Market까지`: S5 전투 클리어 후 Market 진입을 확인하고 정지한다.
- `공모전 서브런봇 S8 Boss 진입까지`: S8 boss 전투 화면 진입을 확인하고 정지한다.
- `공모전 서브런봇 아이템 사용까지`: 실제 족보 형성 또는 확정 점수 개선에 도움이 되는 Item 사용이 발생하면 정지한다.

서브런봇 target은 아래 필드로 기록한다.

```text
contest_sub_run_bot target
- targetStage: S1..S8
- targetTier: small | big | boss | any
- targetScene: Title | NewRunSetup | StationSelect | Battle | CashOut | Market | RunComplete | Archive
- requiredEvidence: market_purchase | item_purchase | item_use | boss_seen | boss_clear | reward_seen | archive_seen
```

서브런봇 결과는 full-play Done을 대체하지 않는다.
특정 구간 실패 재현, 좌표 보정, 마켓/아이템 정책 검증, 제출 영상 후보 장면 확인에만 사용한다.

## 1. Done 기준

아래를 모두 만족해야 bot 제작과 full-play QA를 완료로 본다.

- 최신 제출 후보 web build 또는 최신 Flutter web-server에서 시작한다.
- 저장 세션/SharedPreferences를 지운 fresh 세션에서 시작한다.
- `ko`, `en`, `ja`, `zh-CN`, `zh-TW` 5개 locale 각각에서 표준 run과 도전 run을 fresh로 시작한다.
- 각 locale에서 표준 난이도 S1 small부터 S8 Boss까지 실제 화면 조작으로 먼저 클리어한다.
- 같은 locale에서 도전 난이도 S1 small부터 S8 Boss까지 실제 화면 조작으로 다시 클리어한다. 이때 active run/save는 새로 시작하되 standard에서 완료한 tutorial seen 상태는 유지한다.
- 각 station에서 전투 진입, 드로우, 타일 배치, 확정, 정산, 마켓 이동을 실제 UI로 수행한다.
- 첫 전투와 첫 Market 튜토리얼이 각 locale에서 표시되고, bot 로그에 튜토리얼 완료가 남으며, 스킵/완료/포커스 아웃 처리 기준이 깨지지 않는지 확인한다.
- 전투/마켓/정산/런 정보/상점 카드에서 UI overflow, Jester/Item/자원 제목·설명 잘림, 다국어 텍스트 넘침이 없어야 한다.
- 마켓에서 최소 1회 이상 Jester 또는 카드형 성장 구매를 수행한다.
- 마켓에서 최소 1회 이상 Item 구매를 수행한다.
- 전투 또는 마켓에서 최소 1회 이상 Item을 실제 사용한다.
- 도전 S8 Boss 이후 S8 정산/보상과 `무한 도전 진입` 직전 CTA까지 확인한다. S9+ 무한 도전 장기 생존은 별도 검증이다.
- Browser/WebDriver console log 기준 새 error/warn 0건을 확인한다.
- 실행 로그에는 locale, stage, blind tier, 구매 내역, 아이템 사용, tutorial 확인, overflow 수정 여부, stop reason, console 결과를 남긴다.

현재 판정:

- Bot 구현/정책: 최신 fresh 표준 S1~S8 pass 확보.
- S1~S8 표준 클리어 가능성: debug fixture 없이 fresh full-run으로 확인.
- locale별 표준→도전 cycle 가능성: `ko`, `en` 2/5 cycle 통과. `ja`, `zh-CN`, `zh-TW` fresh cycle은 미검증이며 다음 full-run gate다.
- S8 boss 최신 표준 단독 판정: pass, game over/retry 없음. 단독 표준 pass는 locale cycle 완료를 대체하지 않는다.
- 남은 제출 QA: Flutter semantics warning 제거, 최신 제출 후보 build, console error/warn 0건, locale별 standard→challenge fresh cycle, 보상/도감/새 run 눈검증.

## 2. 구조

```text
최신 web build/server
  |
  v
Browser/WebDriver
  - 앱 실행
  - console error/warn 확인
  - trace/video/screenshot 저장
  |
  v
Compute 판단
  - 현재 scene 판정
  - 전투 action 결정
  - 마켓 action 결정
  - 실패/재시도 판단
  |
  v
Compute Use 실행
  - 실제 화면 좌표 클릭/드래그
  - 손패/보드/마켓 카드 조작
  - selector tap 실패 구간 fallback
  |
  v
Full-play evidence
  - S1~S8 clear trace
  - market purchase trace
  - item use trace
  - reward/archive/new run trace
```

## 3. 판단 계층

### 전투 판단

전투 판단은 기존 `planner_v2`를 우선 재사용한다.

`planner_v2`가 내는 action을 실제 UI 조작으로 번역한다.

| Bot action | Hybrid 조작 |
|---|---|
| `draw` | text/role click 우선, 실패 시 Compute Use로 드로우 버튼 좌표 클릭 |
| `place(handIndex,row,col)` | Browser runtime 상태로 대상 타일/셀을 정하고 Compute Use로 손패 타일과 보드 셀 좌표 클릭 |
| `confirm` | text/role click 우선, 실패 시 Compute Use로 확정 버튼 좌표 클릭 |
| `discardBoard(row,col)` | Compute Use로 보드 셀과 보드 버림 버튼 좌표 클릭 |
| `stop(reason)` | 실행 중단, 로그에 reason 기록 |

Browser/WebDriver에서 직접 읽은 runtime 상태를 `planner_v2` 입력으로 넘긴다.
화면과 runtime 상태가 어긋나면 Compute Use screenshot으로 hand/board/score/target을 다시 판독하고, 그 결과를 로그에 남긴 뒤 action을 재선택한다.

### 마켓 판단

마켓은 기존 경제/레벨링 bot의 구매 proxy를 참고하되, full-play QA용으로 아래 정책을 둔다.

- 구매 가능하면 성장 효과가 분명한 Jester를 우선 구매한다.
- Item offer가 있고 골드가 충분하면 최소 1개는 구매한다.
- quick slot 또는 즉시 사용 가능한 utility item은 다음 전투 또는 마켓에서 실제 사용한다.
- 슬롯이 부족하면 판매가 가능한 항목을 팔지, 구매를 포기할지 Compute 판단으로 결정하고 로그에 남긴다.
- 리롤은 무료/할인 조건이 화면에 보일 때 우선 사용하되, S1~S8 클리어 안정성을 해치지 않는 선에서만 사용한다.

세부 id별 구매/판매 가중치는 이 문서의 “현재 구현/정책 요약”을 source로 삼고, 실제 값은 `integration_test/competition_full_play_bot_test.dart`의 bot score 함수와 함께 검증한다.

## 4. Scene 상태 기계

```text
Title
  -> NewRunSetup
  -> StationSelect
  -> Battle(Small)
  -> CashOut
  -> Market
  -> StationSelect
  -> Battle(Big)
  -> CashOut
  -> Market
  -> StationSelect
  -> Battle(Boss)
  -> CashOut
  -> Market
  -> ... repeat until S8 Boss
  -> RunComplete
  -> Reward
  -> Title or NewRunSetup
  -> Archive spot-check
```

허용되지 않는 경로:

- `fixture=` route로 시작
- `현재 구간 즉시 클리어` 같은 debug action 사용
- S8 fixture로 직접 점프
- 시뮬레이션 결과만 보고 UI QA를 통과 처리

## 5. 실행 로그 형식

full-play 실행 결과는 daily log 또는 별도 QA 로그에 아래 형태로 남긴다.

```text
Full-play bot run
- build/server: <path-or-url>
- seed/difficulty/modifier: <value>
- runner: Browser/WebDriver + Compute Use hybrid
- start time: <local time>
- console baseline timestamp: <timestamp>
- result: pass/fail
- last scene: <scene>
- reached stage: S<n> <small|big|boss>
- market purchases:
  - S<n> Market: <item-or-jester-id/display-name>, price <gold>
- item uses:
  - S<n> <battle|market>: <item-id/display-name>, result <summary>
- S1~S8 trace:
  - S1 small: clear
  - S1 big: clear
  - S1 boss: clear
  - ...
  - S8 boss: clear
- console: error 0, warn 0
- screenshots/video: <paths-if-any>
- notes: <known-risk-or-observation>
```

확인 로그:

```text
Full-play bot checkpoint-resume verification
- date: 2026-05-08
- commit: 9262e6d Stabilize contest full run bot strategy
- runner: flutter drive integration_test/competition_full_play_bot_test.dart on Chrome
- result: pass
- final log: /tmp/rummipoker_contest_full_run_bot/resume_s8_boss_final_pass/10_contest_full_run_bot.log
- reached stage: S8 boss run complete
- market/item evidence:
  - S8 market: bought Item
  - S8 boss: used battle Item slide_wax op=mark_next_board_move_bonus
- retry evidence:
  - game over -> retry 1/24
- final line:
  - All tests passed.
- notes:
  - checkpoint/resume evidence sync is part of the bot contract.
  - S8 boss uses bot-only confirmation delay to reduce deck exhaustion.
  - runtime balance was not changed by this bot stabilization.

Full-play bot latest regression baseline
- date: 2026-05-09
- commit: 18f0b53 Tune boss retry deck scoring
- runner: tools/contest_full_run_bot.sh --resume-active-run on Chrome
- result: fail/timeout, bot paused
- final log: /tmp/rummipoker_contest_full_run_bot/resume_s8_shop_boss_score_weight_20260509_140900/10_contest_full_run_bot.log
- reached stage:
  - S8 big clear, S8 boss retry 2
- S8 big evidence:
  - retry 6 confirms: 417, 617, 705
  - total: 1739/1738
- S8 boss evidence:
  - retry 0/1 confirms: 116, 212, 290, 80
  - total: 698/1739
  - retry 2 ended with `Timed out waiting for game state update`
- notes:
  - boss 실패를 bot 전용 치팅으로 덮지 않는다.
  - 족보 완성 시 족보 자체가 성장하는 런타임 규칙과 덱 확장/성장 보조 축을 먼저 검토한다.
  - full-run 재개 전 문서 정책이 실제 policy code/test에 반영됐는지 확인한다.
```

## 6. 제작 범위와 보류

이번 제작 범위:

- full-play bot 기준을 공모전 Done Evidence로 고정한다.
- Browser/WebDriver + Compute Use hybrid를 1차 제출 gate로 문서화한다.
- Codex 내장 Browser Use는 보조 디버깅/눈검증 경로로 문서화한다.
- 기존 `planner_v2`를 전투 판단 엔진으로 재사용한다.
- 마켓 구매를 full-play 필수 증거에 포함한다. 아이템 사용, 보드 이동, 손패/보드 버림은 증거용으로 강제하지 않고 족보 형성 또는 확정 점수 개선이 있을 때만 기록한다.

이번 범위에서 하지 않는 것:

- Browser Use만으로 제출 gate를 닫는 방식
- Browser-only selector/tap만으로 Flutter Web 조작 안정성을 보장했다고 보는 방식
- production runtime 자동 밸런싱
- ML 추천 모델 갱신
- 사람 수동 플레이를 full-play evidence로 대체
- debug fixture 기반 S8 점프를 full-play evidence로 인정

## 7. 다음 실행 순서

1. 족보 완성 시 해당 족보가 게임오버 없이 이어지는 하나의 run 전체에서 성장하고, 그 run의 이후 전투 점수에 반영되는 런타임 규칙을 구현하고 저장/복원/정산 테스트로 닫는다.
2. 게임 중/게임 밖에서 언제든 열 수 있는 `런 정보` 화면 또는 동등한 UI로 족보별 레벨, 현재 점수, 완성 횟수를 확인하게 한다.
3. 덱 확장 또는 족보 성장 보조 아이템/Jester 후보가 필요한지 현재 카탈로그와 runtime effect를 기준으로 검토한다.
4. bot 정책이 성장한 족보 점수와 플러시/스트레이트 장기 성장 가치를 평가하도록 동기화한다.
5. `tools/prototype_submission_smoke.sh` 또는 동등한 analyze/test/build로 최신 후보를 만든다.
6. 최신 build 또는 Flutter web-server URL을 Browser/WebDriver로 열고 console/trace 수집을 시작한다.
7. `contest_full_run_bot`을 S8 boss checkpoint-resume부터 먼저 재검증하고, 통과하면 단일 fresh full-run 회귀를 실행한다.
8. S8 boss clear 후 보상, 새 run 복귀, 도감 반영을 확인한다.
9. console error/warn 0건과 실행 로그를 competition checklist에 반영한다.
