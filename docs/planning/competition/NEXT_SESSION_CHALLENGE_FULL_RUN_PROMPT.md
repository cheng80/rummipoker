# Next Session Prompt: Locale Cycle Full-Run

아래 프롬프트는 다음 세션에서 그대로 붙여 넣어 공모전 풀런봇 locale별 표준→도전 사이클 검증을 이어가기 위한 것이다.
모든 경로는 repo root 기준 상대 경로다.

```text
이 repo는 현재 작업 디렉터리의 repo root 기준으로 진행하고, AGENTS.md 규칙을 따른다.

이번 세션 목표:
- 공모전 제출 QA를 `공모전 풀런봇` 기준으로 이어간다.
- 최신 룰/UI 후보에서 표준 난이도 fresh S1~S8 boss 단독 full-run은 이미 통과했지만, 제출 gate는 locale별 표준→도전 cycle 기준으로 다시 닫는다.
- 이제 지원 locale 5개(`ko`, `en`, `ja`, `zh-CN`, `zh-TW`) 각각에서 fresh 표준 S1~S8 Boss를 먼저 클리어하고, 같은 locale fresh 도전 S1~S8 Boss와 S8 정산/보상/무한 도전 진입 직전 확인까지 진행한다.
- Flutter semantics 반복 경고는 2026-05-10 route/dialog label 보정과 최신 build smoke로 1차 처리됐다.
- 전투/마켓 튜토리얼은 `showcaseview`가 아니라 `tutorial_coach_mark` 기준이다. dialog/focus-out 시 overlay가 위에 남지 않게 닫고, FittedBox 변환 뒤 실제 화면 rect로 focus 위치와 크기를 계산하도록 보정했다.
- S8 Boss 이후는 `무한 도전 진입` UX로 정리됐다. 제출 gate는 각 locale에서 표준 S8 Boss 클리어 후 같은 locale 도전 S8 Boss 클리어와 S8 정산/보상/무한 도전 진입 직전 확인까지이며, S9+ 장기 생존은 이번 제출 gate가 아니다.
- full-run 중 수정 범위는 game over뿐 아니라 UI overflow, 튜토리얼 target/문구 문제, Jester/Item/자원 카드 제목·설명 잘림, 다국어 텍스트 넘침까지 포함한다.
- 각 locale 실행 전 저장 세션/SharedPreferences를 지우고 첫 전투/첫 Market 튜토리얼이 실제로 표시되는지 확인한다.

먼저 읽을 문서:
- START_HERE.md
- docs/planning/ACTIVE_EXECUTION_PLAN.md
- docs/planning/competition/COMPETITION_SUBMISSION_CHECKLIST.md
- docs/planning/competition/COMPUTE_BROWSER_FULL_PLAY_BOT.md
- docs/planning/competition/NEXT_SESSION_CHALLENGE_FULL_RUN_PROMPT.md

최근 표준 fresh pass 증거:
- 로그: /tmp/rummipoker_contest_full_run_bot/fresh_after_reward_tile_rules_20260509_201727/10_contest_full_run_bot.log
- 실행 조건: --seed 91460 --difficulty standard --web-port 7362 --skip-pub-get
- 결과:
  - CONTEST_FULL_RUN_BOT_PASS
  - All tests passed!
  - S8 boss: run complete
- S8 boss 정산:
  - 870/3
  - 728/2
  - 312/1
  - target 1739 통과
- game over/retry 없음
- 보스 클리어 덱 타일 보상으로 S2 deck=53부터 S8 deck=59까지 증가 확인

이번 세션 첫 작업 순서:
1. git status --short, git log -3 --oneline으로 시작한다.
2. `docs/planning/competition/COMPETITION_SUBMISSION_CHECKLIST.md`의 “0.1 최근 24시간 이내 추가 항목과 검증 대기 목록”을 먼저 확인한다.
   - 족보 성장 UI/점수 반영
   - 행성카드형 성장 아이템
   - 초과 점수 기반 대표 족보 성장
   - 메인 화면 `런 정보` 진입
   - 게임오버 정산 화면과 랜덤 도발 문구
   - S8 이후 무한 도전 진입 UX
   - 타이틀 로고/서브타이틀
   - submission kit 빌드/스토어 문서
   - 전투/마켓 튜토리얼과 다시 보기
   - 인앱 리뷰 store id gate
   - 위 항목들은 locale별 standard→challenge full-run cycle을 제외하고 최신 제출 후보 build/test/smoke 기준으로 1차 검증됐다.
3. full-run cycle 직전 최신 상태가 바뀌었으면 `flutter analyze`, 핵심 `flutter test`, `flutter build web`을 다시 실행한다.
4. 공모전 풀런봇 policy code/test가 추가 덱, 보상 타일, 특수 족보, 족보 성장 점수를 실제 후보 평가에 반영하는지 확인한다.
5. 공모전 풀런봇을 `ko` 표준 난이도 fresh S1부터 실행한다.
   - 스크립트: tools/contest_full_run_bot.sh
   - 영문 식별자: contest_full_run_bot
   - 한 locale cycle은 `standard` S1~S8 Boss 통과 후 같은 locale `challenge` S1~S8 Boss와 무한 도전 진입 직전 확인까지다.
   - locale 실행 순서: `ko` -> `en` -> `ja` -> `zh-CN` -> `zh-TW`
   - 각 standard/challenge 실행 시작 전에 저장 세션/SharedPreferences와 WebDriver Chrome profile을 초기화한다.
   - 각 locale은 standard 완료/점검/승인 후 challenge로 넘어가고, challenge 완료/점검/승인 후 다음 locale로 넘어간다.
   - 첫 전투/첫 Market 튜토리얼 표시, 스킵/완료/포커스 아웃 처리, UI overflow/Jester/Item 설명 잘림을 함께 확인한다.
6. full-run cycle이 실패하거나 UI overflow/텍스트 잘림이 발견되면 문서만 바꾸고 재실행하지 않는다.
   - 먼저 policy code와 관련 test에 반영됐는지 확인한다.
   - game over/retry/checkpoint 로그를 근거로 족보, 중복줄 확정, 덱 추가, 히든 족보, 마켓 구매/판매, 보드 이동/버림 정책을 점검한다.
   - UI/Jester/Item/자원 텍스트 문제는 code 또는 번역 자산을 수정하고 해당 locale gate를 다시 실행한다.
7. full-run cycle 도중 세션이 종료되면 다음 세션에서는 마지막 output-dir, 10_contest_full_run_bot.log, checkpoint 상태를 먼저 확인하고 이어간다.

2026-05-10 locale cycle 제외 검증:
- `flutter analyze` 통과
- 핵심 `flutter test` 묶음 통과
- `flutter build web` 통과
- Browser/CDP smoke 통과:
  - /
  - /new-run
  - /archive
  - /game?fixture=game_over_insight_ready&debug_show_game_over_on_load=1
  - /game?fixture=final_boss_cash_out_ready&debug_complete_run_on_load=1
- 위 경로 모두 앱 warn/error/exception 0건
- Headless Chrome의 `Falling back to CPU-only rendering`은 WebGL 없는 headless 환경 경고라 앱 경고로 집계하지 않는다.

2026-05-10 최근 24시간 내 풀런 제외 진행 상태:
- 런 내부 족보 레벨 성장, `handGrowthStates(level/progress/requiredProgress)` 분리, 런 정보 UI, 성장 점수 반영: 구현/테스트 완료.
- 행성카드형 직접 성장 아이템(`*_study`)과 bot market policy 구매 평가: 구현/테스트 완료.
- 초과 점수 기반 대표 족보 성장 보상: 구현/테스트 완료.
- 덱 추가, 히든 족보 V1, 보스 클리어 덱 타일 보상: 구현/테스트 완료. 표준 fresh full-run에서도 덱 증가 확인됨.
- S8 boss 이후 `무한 도전 진입`, S9+ Station Select/전투 HUD/정산 라벨 위험 색상, target 비율: 구현/테스트/눈검증 완료.
- 타이틀 로고 이미지와 서브타이틀 `타일로 만드는 포커 런`: 구현/커밋 완료.
- `docs/submission_kit/` 제출 문서 세트, Android signing/key.properties 예시, 플랫폼별 빌드 가이드, store metadata: 문서화 완료.
- 인앱 리뷰는 store id가 없으면 진입 메뉴 버튼을 숨기는 방향으로 반영됨.
- 전투/마켓 튜토리얼은 `tutorial_coach_mark`로 구현. 자동 튜토리얼은 끝까지 완료된 경우만 seen 저장, skip/focus-out/options 진입은 다음에 다시 뜨게 한다.
- 튜토리얼 최신 보정: focus 위치/크기를 FittedBox 변환 후 실제 화면 좌표로 계산하고, 창 크기 변경 시 현재 step 유지 후 overlay 재생성. `flutter analyze`, 핵심 widget test, `flutter build web` 통과. 남은 항목은 Browser/기기에서 리사이즈 후 크기 눈검증.
- 정산 progress bar, 게임오버 후 새 run까지 족보 성장 영구 계승, 타로/유령카드류 전체 이식은 이번 제출 전 구현 범위에서 제외.

중요 정책:
- full-play bot 증거와 Browser Use smoke를 혼동하지 않는다.
- debug fixture, 즉시 클리어, forced reward는 full-play evidence가 아니다.
- 아이템 사용, 보드 이동, 손패 버림, 보드 버림의 최상위 조건은 항상 족보 형성 또는 확정 점수 개선이다.
- 사용 로그를 남기기 위한 무의미한 사용을 만들지 않는다.
- 보드 이동/버림은 낮은 target score를 이유로 절대 금지하지 않는다. 실제 족보 형성이나 중복 확정으로 이어지면 사용 가능하다.
- 보스 클리어 덱 타일 보상은 마켓 offer 자리를 차지하지 않고 정산에서 즉시 덱에 추가되는 구조다.
- S8 Boss 정산 후 `무한 도전 진입`을 누르면 S8 보상은 1회 claim되고 Market을 거쳐 S9+ 무한 도전 Station Select로 이어진다.
- S9+ 무한 도전 target은 Scout 1배, Clash 1.5배, Boss 2배 비율을 따른다.
- 마켓 tile offer는 실제 타일 face로 보이고, 구매 시 오른쪽 중단 덱 방향으로 날아가야 한다.
- 제출 Done으로 쓰려면 5개 locale 각각에서 standard→challenge cycle이 모두 통과하고, console error/warn 0건과 overflow/텍스트 잘림 0건도 함께 닫혀야 한다.
- 튜토리얼 smoke는 full-play evidence가 아니다. 단, 제출 후보 UX QA 항목으로 전투 첫 진입, 마켓 첫 진입, 다시 보기, 포커스 아웃/옵션 겹침, 창 크기 변경 후 focus 위치/크기를 확인한다.

완료 시 해야 할 일:
- docs/planning/ACTIVE_EXECUTION_PLAN.md 업데이트
- docs/planning/competition/COMPETITION_SUBMISSION_CHECKLIST.md 업데이트
- docs/planning/competition/COMPUTE_BROWSER_FULL_PLAY_BOT.md 업데이트
- 필요 시 AGENTS.md에 재발 방지 규칙 추가
- 테스트/빌드/풀런 로그 경로를 응답에 남긴다.
- 변경 내용을 커밋/푸시한다.
```
