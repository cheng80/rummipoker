# Next Session Prompt: Challenge Full-Run

아래 프롬프트는 다음 세션에서 그대로 붙여 넣어 공모전 풀런봇 도전 난이도 검증을 이어가기 위한 것이다.
모든 경로는 repo root 기준 상대 경로다.

```text
이 repo는 현재 작업 디렉터리의 repo root 기준으로 진행하고, AGENTS.md 규칙을 따른다.

이번 세션 목표:
- 공모전 제출 QA를 `공모전 풀런봇` 기준으로 이어간다.
- 최신 룰/UI 후보에서 표준 난이도 fresh S1~S8 boss full-run은 이미 통과했다.
- 이제 도전 난이도 fresh S1~S8 full-run을 시작한다.
- Flutter semantics 반복 경고는 2026-05-10 route/dialog label 보정과 최신 build smoke로 1차 처리됐다.

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
2. `docs/planning/competition/COMPETITION_SUBMISSION_CHECKLIST.md`의 “0.1 최근 5시간 이내 추가 항목과 검증 대기 목록”을 먼저 확인한다.
   - 족보 성장 UI/점수 반영
   - 행성카드형 성장 아이템
   - 초과 점수 기반 대표 족보 성장
   - 메인 화면 `런 정보` 진입
   - 게임오버 정산 화면과 랜덤 도발 문구
   - 위 항목들은 도전 난이도 fresh S1~S8 full-run을 제외하고 최신 제출 후보 build/test/smoke 기준으로 1차 검증됐다.
3. 도전 풀런 직전 최신 상태가 바뀌었으면 `flutter analyze`, 핵심 `flutter test`, `flutter build web`을 다시 실행한다.
4. 공모전 풀런봇 policy code/test가 추가 덱, 보상 타일, 특수 족보, 족보 성장 점수를 실제 후보 평가에 반영하는지 확인한다.
5. 공모전 풀런봇을 도전 난이도 fresh S1부터 실행한다.
   - 스크립트: tools/contest_full_run_bot.sh
   - 영문 식별자: contest_full_run_bot
   - 난이도는 도전/challenge 계열을 사용한다. 실제 CLI 인자는 스크립트와 기존 테스트에서 확인한다.
6. 도전 풀런이 실패하면 문서만 바꾸고 재실행하지 않는다.
   - 먼저 policy code와 관련 test에 반영됐는지 확인한다.
   - game over/retry/checkpoint 로그를 근거로 족보, 중복줄 확정, 덱 추가, 히든 족보, 마켓 구매/판매, 보드 이동/버림 정책을 점검한다.
7. 도전 풀런 도중 세션이 종료되면 다음 세션에서는 마지막 output-dir, 10_contest_full_run_bot.log, checkpoint 상태를 먼저 확인하고 이어간다.

2026-05-10 도전 풀런 제외 검증:
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

중요 정책:
- full-play bot 증거와 Browser Use smoke를 혼동하지 않는다.
- debug fixture, 즉시 클리어, forced reward는 full-play evidence가 아니다.
- 아이템 사용, 보드 이동, 손패 버림, 보드 버림의 최상위 조건은 항상 족보 형성 또는 확정 점수 개선이다.
- 사용 로그를 남기기 위한 무의미한 사용을 만들지 않는다.
- 보드 이동/버림은 낮은 target score를 이유로 절대 금지하지 않는다. 실제 족보 형성이나 중복 확정으로 이어지면 사용 가능하다.
- 보스 클리어 덱 타일 보상은 마켓 offer 자리를 차지하지 않고 정산에서 즉시 덱에 추가되는 구조다.
- 마켓 tile offer는 실제 타일 face로 보이고, 구매 시 오른쪽 중단 덱 방향으로 날아가야 한다.
- 도전 풀런 통과를 제출 Done으로 쓰려면 console error/warn 0건도 함께 닫혀야 한다.

완료 시 해야 할 일:
- docs/planning/ACTIVE_EXECUTION_PLAN.md 업데이트
- docs/planning/competition/COMPETITION_SUBMISSION_CHECKLIST.md 업데이트
- docs/planning/competition/COMPUTE_BROWSER_FULL_PLAY_BOT.md 업데이트
- 필요 시 AGENTS.md에 재발 방지 규칙 추가
- 테스트/빌드/풀런 로그 경로를 응답에 남긴다.
- 변경 내용을 커밋/푸시한다.
```
