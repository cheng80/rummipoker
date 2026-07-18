# ko release locale gate 검토

> 역할: ko locale gate 실행 결과와 검토 근거를 기록한다.

## 결론

`ko` 표준 fresh S1~S8과 같은 cycle의 도전 S1~S8을 모두 통과했다. S8 boss 정산 직전까지의 전투·정산·Market·checkpoint evidence가 남아 다음 locale로 진행할 수 있다.

## 실행

- seed: `91460`
- modifier: `basic`
- 표준: `tools/full_run_bot.sh --locale ko --difficulty standard --run-modifier basic --seed 91460 --mode full`
- 도전: `tools/full_run_bot.sh --locale ko --difficulty challenge --run-modifier basic --seed 91460 --mode full --tutorials-already-seen` + 표준 cycle carryover
- 표준 결과: `All tests passed`, S8 boss complete, trace 3383행
- 도전 결과: profile WebDriver에서 `All tests passed`, S8 boss complete, trace 2561행

## 검토 결과

- 표준 trace에서 Battle·Market tutorial completion event가 각각 1회 확인됐다.
- 표준·도전 모두 `cashout_to_market` 23회, `checkpoint_saved` 23회와 S8 `run_complete`가 확인됐다.
- 표준은 Jester 20회, deck tile 23회, Item 18회 구매와 Item 사용 15회를 기록했다.
- 도전은 Jester 21회, deck tile 20회, Item 11회 구매와 Item 사용 11회를 기록했다.
- 도전 carryover에서 성장 카드와 추가 deck tile이 복원됐고, Market에서 Jester 교체·tile 구매·slot 부족 skip 경로가 action trace에 남았다.
- 두 console에서 Flutter overflow, clipping, tutorial target, save/restore 실패 및 Flutter 예외는 확인되지 않았다. Chrome 자체 서비스 오류는 앱 오류가 아닌 브라우저 종료·서비스 메시지로 분리했다.
- full-run bot은 자동화 재현성을 위해 BGM/SFX를 mute한다. sound playback 자체는 `test/resources/sound_manager_test.dart`와 전체 `flutter test` 결과로 확인하며, 이 cycle에서 audible playback을 수동 청취했다고 기록하지 않는다.
- release web build를 Playwright로 열어 debug overlay 없는 `ko` title 화면을 캡처했다: `/tmp/rummipoker_full_run_bot/release_locale_gate/20260718/ko_visual_release/ko_release_title_after_load.png`
- 실행 종료 뒤 `full_run_bot`, Flutter Web Server, ChromeDriver, WebDriver Chrome 잔류 프로세스가 없음을 확인했다.

## 근거 경로

- 표준: `/tmp/rummipoker_full_run_bot/release_locale_gate/20260718/ko_standard_fresh_retry2/`
- 도전: `/tmp/rummipoker_full_run_bot/release_locale_gate/20260718/ko_challenge_retry4_profile/`
- release visual: `/tmp/rummipoker_full_run_bot/release_locale_gate/20260718/ko_visual_release/`

## 범위 변경

2026-07-18 사용자가 `ko`만 실제 gate를 통과하면 되고 `en → ja → zh-CN → zh-TW`는 통과 처리하라고 지시했다. 따라서 나머지 locale은 실제 full-run 검증 대상에서 제외하며, 실행하지 않은 결과를 실행 PASS로 가장하지 않는다.
