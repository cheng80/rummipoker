# Next Session Item Presentation Prompt

아래 프롬프트는 다음 세션에서 그대로 붙여 넣어 Item/Jester/Passive/Tool/Gear 효과 연출 작업을 이어가기 위한 것이다.

```text
작업 시작 전에 START_HERE.md, docs/00_docs_README.md, docs/current_system/CURRENT_SYSTEM_OVERVIEW.md, docs/current_system/CURRENT_CODE_MAP.md, docs/current_system/CURRENT_TO_V4_GAP.md 를 먼저 읽고,
그 다음 docs/planning/ACTIVE_EXECUTION_PLAN.md 를 확인해 현재 활성 트랙과 다음 작업부터 이어서 진행해라.

이번 세션의 직접 목표는 Item 효과 연출을 `발동 객체 -> 적용 대상 -> 결과` 기준으로 계속 보강하는 것이다.

반드시 먼저 아래 문서를 읽어라.

- docs/planning/feature_plans/ITEM_PRESENTATION_CONTRACT_REVIEW.md
- docs/planning/feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md
- docs/planning/verification/MARKET_ITEM_SMOKE_CHECKLIST.md

현재 상태:

- `shop_lens`는 삭제했다. 카탈로그/번역/fixture에 다시 추가하지 않는다.
- 활성 Item은 54개다.
- `lib/logic/rummi_poker_grid/item_presentation_event.dart`에 transient presentation 계약 1차가 추가됐다.
- `GameShopScreen`에는 Market P0 1차 연출이 들어갔다.
  - market reroll 할인: 보유 Item source -> reroll target -> 할인 결과 toast
  - 구매 할인/나침반 할인: source -> Jester/Item 후보 target -> 구매가 할인 결과 toast
  - 구매 flight의 spent gold는 표시 가격 고정이 아니라 실제 Gold 차이 기준으로 보정했다.
- Chrome 눈검증은 2026-05-16에 통과했고, 기능뿐 아니라 overflow/잘림/겹침/프레임 누수 기준으로도 미통과 항목은 없었다.
- `trade_ticket`은 보유 Tool source -> Item 후보 영역 target -> 후보 교체 완료 result toast를 표시한다.
- Tool/Gear 사용/판매 action pane에서 발견한 overflow는 수정했고, widget test에서 overflow 무시 필터를 제거했다.

이번 세션 첫 작업:

1. 현재 working tree를 먼저 확인하고, 이전 세션 변경을 되돌리지 않는다.
2. 관련 테스트를 한 번 재확인한다.
   - flutter test test/views/game/widgets/game_shop_screen_test.dart --reporter expanded
   - flutter test test/views/game/widgets/game_shop_screen_trade_ticket_test.dart --reporter expanded
   - flutter test test/logic/item_effect_runtime_test.dart test/logic/item_definition_test.dart test/services/debug_run_fixture_service_test.dart --reporter expanded
   - flutter analyze lib/logic/rummi_poker_grid/item_presentation_event.dart lib/logic/rummi_poker_grid/rummi_market_facade.dart lib/views/game/widgets/game_shop_screen.dart lib/services/debug_run_fixture_service.dart test/logic/item_effect_runtime_test.dart test/logic/item_definition_test.dart test/services/debug_run_fixture_service_test.dart test/views/game/widgets/game_shop_screen_test.dart test/views/game/widgets/game_shop_screen_trade_ticket_test.dart
   - git diff --check
3. P0 Market 남은 항목을 작은 단위로 구현한다.
   - `boss_trophy`: Boss clear source -> 다음 Market Jester 후보 예약 -> Market 진입 시 도착 연출이 보이게 한다.
   - `jester_hook`: Gear source -> Jester 판매 가격 target -> 판매 Gold 결과가 보이게 한다.
4. 구현 후 필요한 fixture/widget test/눈검증을 추가한다. 눈검증은 기능뿐 아니라 overflow, 잘림, 겹침, 프레임 누수를 오류로 본다.

작업 원칙:

- presentation queue/state는 save/continue source of truth로 만들지 않는다. 저장 가능한 runtime state와 transient 연출 상태를 분리한다.
- 효과는 단순 toast 하나로 닫지 말고, 가능한 한 source, target, result를 모두 화면에서 식별 가능하게 한다.
- 화면 overflow나 문구 잘림이 보이면 제출 QA 결함으로 보고 함께 고친다.
- Browser/WebDriver/Chrome 기반 테스트를 실행한 뒤에는 Chrome Helper, WebDriver Chrome, ChromeDriver, Flutter web server 잔류 프로세스를 확인하고 정리한다.

현재 통과한 검증:

- flutter test test/views/game/widgets/game_shop_screen_test.dart --reporter expanded
- flutter test test/views/game/widgets/game_shop_screen_trade_ticket_test.dart --reporter expanded
- flutter test test/logic/item_effect_runtime_test.dart test/logic/item_definition_test.dart test/services/debug_run_fixture_service_test.dart --reporter expanded
- flutter analyze lib/logic/rummi_poker_grid/item_presentation_event.dart lib/logic/rummi_poker_grid/rummi_market_facade.dart lib/views/game/widgets/game_shop_screen.dart lib/services/debug_run_fixture_service.dart test/logic/item_effect_runtime_test.dart test/logic/item_definition_test.dart test/services/debug_run_fixture_service_test.dart test/views/game/widgets/game_shop_screen_test.dart test/views/game/widgets/game_shop_screen_trade_ticket_test.dart
- git diff --check
```

## 다음 구현 후보

| 우선순위 | 후보 | Done 기준 |
|---|---|---|
| 1 | `boss_trophy` delayed 연출 | Boss clear에서 예약되고 다음 Market 진입 시 Jester 후보 증가가 도착 연출로 보임 |
| 2 | `jester_hook` 판매 연출 | Gear source, Jester sell price target, Gold result가 보임 |
| 완료 | Chrome 눈검증 | 스크린샷/로그 경로와 통과/미통과를 verification log에 기록 |
| 완료 | `trade_ticket` 연출 | source item, item offer target, 새 후보 결과가 순차적으로 보임 |
