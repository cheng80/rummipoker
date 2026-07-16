---
description: 풀런봇, 시뮬레이션, 브라우저 실기 QA와 증거 수집 규칙
globs: ["tools/full_run_bot.sh", "tools/sub_run_bot.sh", "tools/full_run_*.py", "tools/sim/**/*", "integration_test/**/*", "test_driver/**/*", "test/tools/**/*", "data/full_run_bot/**/*", "lib/services/debug_run_fixture*.dart", "test/services/debug_run_fixture*.dart", "docs/planning/verification/**/*"]
alwaysApply: false
---

# 풀런·QA 규칙

## 기준

- 실행 전에 `docs/planning/verification/TEST_QA_ACCEPTANCE.md`, 실제 runner, `full_run_policy_v1` 코드와 테스트를 확인한다. 문서만 바꾸고 실행하지 않는다.
- UI 실기 bot은 `풀런봇`, 영문 식별자는 `full_run_bot`으로 쓴다. `contest_full_run_bot`, `contest_policy_v1`는 과거 이력에서만 허용한다.
- debug fixture나 즉시 clear 보조 없이 Browser/WebDriver 로그와 실제 좌표·시각 조작을 결합해 검증한다. selector가 Flutter transform/canvas에서 흔들리면 Computer Use를 실행 계층으로 사용한다.

## 실행 gate

- fresh 실행과 checkpoint resume을 명확히 구분한다. fresh는 S1부터 시작하며 profile cookie, localStorage, sessionStorage와 앱 저장 상태를 초기화한다.
- release locale gate는 `ko → en → ja → zh-CN → zh-TW` 순서다. locale마다 표준 S1~S8 뒤 같은 cycle에서 도전 S1~S8과 S8 정산 직전까지 이어가고, cycle 결과를 검토·보고한 뒤 다음 locale 승인을 받는다.
- 첫 Battle·Market tutorial은 각 locale의 표준 run에서 실제 `Next/Done`까지 확인한다. 도전 run은 seen flag를 유지한다.
- 사용자가 runtime 전체 재도전을 승인한 경우 basic, basic high-stakes, challenge, challenge high-stakes를 추가 승인 없이 순차 실행한다.

## Bot 판단

- action은 족보 형성, 중복 line, 확정 점수 개선을 우선한다. 이동·버림·Item을 evidence용으로 소비하지 않고 정산/presentation phase가 끝난 뒤 다음 입력을 보낸다.
- 1회 game over로 평상시 정책을 바꾸지 않는다. 같은 run에서 2회 이상 실패한 뒤 관측 deck 순서와 lookahead를 retry recovery에 반영하며 production 난이도를 낮추지 않는다.
- Market은 최신 policy와 catalog를 따른다. 현재 기준은 Jester, tile 1장, Q-Slot, Tool/Gear 순으로 가치가 있을 때 구매하고, 가득 찬 slot은 명확한 상향 교체만 허용한다.
- text label이나 첫 카드 위치를 탭하지 않는다. stable key, content id, slot index로 선택하고 결과 상태가 바뀐 뒤에만 성공 로그를 남긴다.

## QA와 정리

- game over뿐 아니라 overflow, 잘림, tutorial target, 다국어, sound, save/restore 결함도 같은 locale gate의 실패다. 수정 뒤 해당 gate를 다시 실행한다.
- 기존 Chrome/Simulator가 있으면 재사용한다. 성공, 실패, 중단, timeout 모든 종료 경로에서 Chrome Helper, WebDriver, ChromeDriver, Flutter web server 잔류 process를 정리하고 확인 전 다음 실행이나 최종 보고를 하지 않는다.
- run마다 seed, locale, difficulty/modifier, checkpoint 여부, action trace, console, screenshot/video와 정산 결과를 남긴다. debug chrome이 보이는 캡처를 release evidence로 쓰지 않는다.
- 테스트·검증 실패 보고는 `failure-reporting.md` 형식을 따르고 원인, 해결책, 재검증 명령을 포함한다.
