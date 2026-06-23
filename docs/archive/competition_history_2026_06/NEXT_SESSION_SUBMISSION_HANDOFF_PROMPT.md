# Next Session Prompt: Competition Submission Handoff

아래 프롬프트는 다음 세션에서 그대로 붙여 넣어 공모전 제출 작업을 이어가기 위한 것이다.
모든 경로는 repo root 기준 상대 경로다.

```text
이 repo는 현재 작업 디렉터리의 repo root 기준으로 진행하고, AGENTS.md 규칙을 따른다.

이번 세션 목표:
- 공모전 풀런봇 QA 재개가 아니라, 공모전 제출 handoff를 이어간다.
- 공모전 풀런봇 제출용 플랜은 닫혔다.
- `ja`, `zh-CN`, `zh-TW` full-run은 문제 발생 시 또는 공모전 이후 추가 검증으로 둔다.
- 이번 세션에서 새 기능/밸런스/대형 UI 변경을 시작하지 않는다.
- 실제 남은 일은 제출 빌드 산출물, 배포/업로드, 제출 폼/자료 확인이다.

먼저 읽을 문서:
- START_HERE.md
- docs/planning/ACTIVE_EXECUTION_PLAN.md
- docs/archive/competition_history_2026_06/COMPETITION_SUBMISSION_CHECKLIST.md
- docs/archive/competition_history_2026_06/COMPUTE_BROWSER_FULL_PLAY_BOT.md
- docs/release/submission_kit/README.md
- docs/release/submission_kit/RELEASE_CHECKLIST.md
- docs/release/submission_kit/WEB_BUILD_GUIDE.md
- docs/release/submission_kit/STORE_METADATA_KO_EN.md
- docs/release/submission_kit/SCREENSHOT_PROMO_COPY_KO_EN.md

주의:
- docs/archive/competition_history_2026_06/NEXT_SESSION_CHALLENGE_FULL_RUN_PROMPT.md 는 보존 중인 과거 full-run 재개 프롬프트다.
- 그 문서는 5개 locale full-run을 제출 필수 gate로 보던 시점의 문서라, 다음 작업 판단 기준으로 쓰지 않는다.
- 최신 기준은 ACTIVE_EXECUTION_PLAN, COMPETITION_SUBMISSION_CHECKLIST, 이 handoff 문서다.
- 2026-05-11 이후 `full_run_policy_v1`, market collection audit, economy choice probe가 추가됐지만 이는 레벨링 분석 보조 자료다. 공모전 제출 handoff 기준을 바꾸거나 full-run gate를 재개하는 근거로 쓰지 않는다.

현재 제출 QA 결론:
- `contest_full_run_bot` `ko` standard→challenge cycle 통과.
- `contest_full_run_bot` `en` standard→challenge cycle 통과.
- 최신 UI/Web 회귀 수정 뒤 `ko` standard→challenge 재확인 통과.
- 2026-05-14 상점 가격/오퍼 회귀는 로직·위젯 테스트로 닫았다. 보유 Jester/Item/Passive 판매 시 보이는 오퍼 리스트가 명시적 리롤 없이 바뀌지 않고, Jester 오퍼 구매 후 남은 오퍼 가격이 0G로 튀지 않으며, 구매 할인은 UI에 원가/할인가/`할인` 배지로 표시된다.
- 2026-05-14 상점 할인 시각 봇 `market_discount_visual_bot`을 추가했다. 같은 fixture 10회 반복이 아니라 7개 fresh 시나리오 매트릭스가 기본이며, 할인 Jester 구매/판매, 할인 Item offer 표시, Passive 판매 후 offer 유지, 리롤 할인/피드백, 비할인 Jester/Item 가격 표시, 슬롯 해금 Market 상태를 각각 별도 Chrome/Flutter drive 실행으로 확인한다. 이는 상점 회귀 눈검증용 보조 QA이며 full-play evidence나 full-run gate 재개 근거가 아니다.
- 2026-05-14 웹 focus-out BGM은 `SoundManager` 내부에서 best-effort 완화했다. lifecycle pause만 recovery pending으로 표시하고, 복귀 후 첫 제스처는 `resume()`을 먼저 시도하며 실패 시 다음 제스처에서만 `stop()`/`play()` fallback을 허용한다. 이 변경은 웹뷰에서 사운드가 완전히 씹히는 빈도를 줄이기 위한 것이며, 웹뷰별 오디오 정책 때문에 BGM 위치 유지가 완전하지 않은 경우는 known limitation으로 둔다.
- 2026-05-14 용어 UX를 보강했다. `+N Mult`처럼 보이던 Jester/Item 설명은 실제 공식 `1 + N / 20` 기준 `점수 +N*5%`로 노출하고, 진짜 곱셈 효과는 `점수 xN`으로 표시한다. 한국어 Chips는 `칩`으로 통일했고, 런 정보 다이얼로그의 책 아이콘에서 `게임 용어` 설명을 열어 `칩`, `점수 +%`, `점수 xN`, `골드` 차이를 확인할 수 있다.
- `CONTEST_FULL_RUN_BOT_PASS`, `All tests passed!`, `S8 boss: run complete` 확인.
- grep 기준 game over/retry/Flutter semantics warning/UI overflow/error/warn 0건.
- 종료 후 WebDriver Chrome, Chrome Helper, ChromeDriver, Flutter web 서버 잔류 프로세스 없음.
- 튜토리얼 리사이즈 후 focus 위치/크기 눈검증 완료.
- 풀런봇 플랜은 제출용 handoff 상태로 닫힘.

주요 증거 로그:
- `ko` 표준: /tmp/rummipoker_contest_full_run_bot/standard_ko_20260510_104511/10_contest_full_run_bot.log
- `ko` 도전: /tmp/rummipoker_contest_full_run_bot/challenge_ko_20260510_115046/10_contest_full_run_bot.log
- `en` 표준: /tmp/rummipoker_contest_full_run_bot/standard_en_20260510_140623/10_contest_full_run_bot.log
- `en` 도전: /tmp/rummipoker_contest_full_run_bot/challenge_en_20260510_145813/10_contest_full_run_bot.log
- 최신 `ko` 재확인 표준: /tmp/rummipoker_contest_full_run_bot/standard_ko_recheck_20260510_233626/10_contest_full_run_bot.log
- 최신 `ko` 재확인 도전: /tmp/rummipoker_contest_full_run_bot/challenge_ko_recheck_20260511_005027/10_contest_full_run_bot.log
- 상점 할인 시각 봇 전체 매트릭스: /tmp/rummipoker_market_discount_visual_bot/matrix_full_20260514_060908/10_market_discount_visual_bot.log

최근 상태 커밋:
- 2d1a4d4 Add market discount visual bot
- d77f289 Fix shop offer pricing regressions
- 200da7c Enhance iOS profile build documentation with debug execution instructions and clarify debug fixture visibility in release builds

최근 상점 회귀 수정 검증:
- `flutter test test/logic/rummi_market_facade_test.dart test/logic/item_definition_test.dart test/logic/item_effect_runtime_test.dart test/providers/game_session_notifier_test.dart`
- `flutter test test/views/game/widgets/game_shop_discount_badge_test.dart test/views/game/widgets/game_shop_sell_offer_stability_test.dart`
- `flutter analyze integration_test/market_discount_visual_bot_test.dart`
- `bash -n tools/market_discount_visual_bot.sh`
- `tools/market_discount_visual_bot.sh --skip-pub-get --web-port 7371 --output-dir /tmp/rummipoker_market_discount_visual_bot/matrix_full_20260514_060908`
  - 결과: `MARKET_DISCOUNT_VISUAL_BOT_PASS` 7건, `All tests passed!` 7건.
  - 종료 후 WebDriver Chrome, ChromeDriver, Flutter web server 잔류 프로세스 없음.
- `git diff --check`
- `reroll_token`은 문구와 맞게 “다음 리롤 1G 할인”(`discount_next_reroll`)으로 정정했다. 기존 fixture용 `free_next_reroll` 지원은 남겨 두었다.

최근 웹 BGM focus-out 완화 검증:
- `flutter test test/resources/sound_manager_test.dart`
- `flutter test test/views/game/game_view_test.dart`
- `flutter analyze lib/app.dart lib/resources/sound_manager.dart test/resources/sound_manager_test.dart`
- `flutter build web`
- `git diff --check`
- 남은 제한: 일부 웹뷰/브라우저에서 focus-out 복귀 후 BGM 위치가 항상 유지되지는 않는다. 제출 blocker가 아니라 known limitation이며, 추가 화면/라우팅별 웹 전용 분기를 늘리지 않는다.

최근 용어 UX 보강 검증:
- `flutter test test/views/game/widgets/game_run_info_dialog_test.dart test/logic/jester_translation_test.dart test/logic/item_definition_test.dart test/views/game/widgets/game_shop_jester_runtime_value_test.dart test/views/game/widgets/game_shop_screen_test.dart test/views/game/widgets/game_station_read_path_test.dart`
- JSON validation: `assets/translations/{ko,en,ja,zh-CN,zh-TW}.json`, `assets/translations/data/*/{jesters,items}.json`, `data/common/{jesters_common_phase5,items_common_v1}.json`
- `git diff --check`
- 남은 제한: `점수 +%` 문구가 기존 `+Mult`보다 길다. widget test는 통과했지만 제출 전 실제 마켓 카드/툴팁 다국어 눈검증을 하면 좋다.

이번 세션 첫 작업 순서:
1. `git status --short`, `git log -3 --oneline`으로 시작한다.
2. `docs/planning/ACTIVE_EXECUTION_PLAN.md`에서 공모전 기준 완성이 `Closed for submission QA handoff`인지 확인한다.
3. `docs/archive/competition_history_2026_06/COMPETITION_SUBMISSION_CHECKLIST.md`에서 오래된 `Status: In progress` 또는 `Reopened`가 새로 생기지 않았는지 확인한다.
4. Web 제출이면 `docs/release/submission_kit/WEB_BUILD_GUIDE.md`와 `docs/release/submission_kit/RELEASE_CHECKLIST.md` 기준으로 최종 빌드를 만든다.
   - 배포 경로가 `/rummipoker/`면 `flutter build web --release --base-href "/rummipoker/"` 기준이다.
   - 로컬 smoke만이면 base-href 없이도 가능하지만, 제출 배포 산물은 실제 배포 경로 기준으로 맞춘다.
5. 최종 산물 업로드/배포 후 실제 URL에서 빠른 smoke를 한다.
   - `/`
   - `/new-run`
   - `/archive`
   - 필요 시 `/game?fixture=game_over_insight_ready&debug_show_game_over_on_load=1`
   - 필요 시 `/game?fixture=final_boss_cash_out_ready&debug_complete_run_on_load=1`
   - 웹 BGM은 첫 터치/버튼 tap, 스크롤 중 묵음 없음, focus-out 후 복귀 시 사운드가 완전히 먹통으로 남지 않는지만 확인한다. BGM 위치가 항상 유지되는지까지 제출 blocker로 보지 않는다.
6. 제출 폼/스토어 문구는 `docs/release/submission_kit/STORE_METADATA_KO_EN.md`와 `docs/release/submission_kit/SCREENSHOT_PROMO_COPY_KO_EN.md`를 참고한다.
7. 제출 전 최종 응답에는 빌드 명령, 산출물 경로, 배포 URL, smoke 결과, git 상태를 남긴다.

하지 말 것:
- 풀런봇을 다시 5개 locale 전체로 돌리지 않는다.
- `ja`, `zh-CN`, `zh-TW`를 제출 필수 gate로 되살리지 않는다.
- debug fixture나 즉시 클리어를 full-play evidence로 쓰지 않는다.
- 장기 밸런스, ML 리포트, 타로/유령카드류, 영구 족보 계승, 정산 progress bar를 제출 전 새 작업으로 열지 않는다.
- 웹 focus-out BGM을 더 파지 않는다. 현재 `SoundManager`의 resume-first/fallback-on-next-gesture 정책을 제출 전 기준으로 유지한다.
- 용어를 다시 `기초`로 바꾸지 않는다. 한국어 Chips는 현재 제출 후보에서 `칩`으로 유지하고, 의미 보강은 `게임 용어` 다이얼로그로 처리한다.
- Android/iOS release artifact는 이번 웹 제출 범위가 아니라면 만들지 않는다. 필요해진 경우에만 `docs/release/submission_kit/ANDROID_BUILD_NOTES.md`와 `docs/release/submission_kit/IOS_PROFILE_BUILD.md`를 따른다.

공모전 이후로 둔 항목:
- `ja`, `zh-CN`, `zh-TW` full-run.
- S9+ 장기 생존.
- 정산 progress bar.
- 게임오버 후 새 run까지 이어지는 족보 성장 영구 계승.
- 타로류/유령카드류 전체 이식.
- 기억 카드가 실제 Jester/Item을 지급하는 구조.
- 장기 multi-seed 밸런스와 ML 리포트 갱신.

완료 시 해야 할 일:
- 필요하면 docs/planning/ACTIVE_EXECUTION_PLAN.md와 docs/archive/competition_history_2026_06/COMPETITION_SUBMISSION_CHECKLIST.md에 제출 산물/URL/smoke 결과를 업데이트한다.
- 변경이 있으면 커밋/푸시한다.
- 최종 응답에 산출물 경로, 배포 URL, smoke 결과, 커밋 해시를 남긴다.
```
