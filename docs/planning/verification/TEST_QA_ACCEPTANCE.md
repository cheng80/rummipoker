# 테스트와 QA 기준

> 역할: 변경 종류별로 어떤 명령을 실행하고 무엇을 직접 확인해야 하는지 적는다. 진행 상황은 [ACTIVE_EXECUTION_PLAN.md](../ACTIVE_EXECUTION_PLAN.md), 아직 정하지 못한 정책은 [OPEN_DECISIONS.md](../OPEN_DECISIONS.md)가 맡는다.

## 자동으로 확인할 항목

바꾼 범위에 맞는 작은 테스트를 먼저 돌린 뒤, 마지막에 전체 문서·빌드 검사를 돌린다.

```sh
dart run tools/generate_docs.dart --check
flutter test
flutter analyze
git diff --check
```

| 변경 영역 | 최소 targeted suite |
|---|---|
| 족보 판정·확정·overlap | `test/logic/hand_evaluator_test.dart`, `test/logic/rummi_session_test.dart` |
| Item runtime·inventory | `test/logic/item_definition_test.dart`, `test/logic/item_effect_runtime_test.dart` |
| Market economy·facade | `test/logic/rummi_market_facade_test.dart`, `test/providers/game_session_notifier_test.dart` |
| 저장·재시작 | `test/services/active_run_save_service_test.dart`, notifier의 restart/restore tests |
| Market UI | 관련 `test/views/game/widgets/game_shop_*_test.dart` |
| generated docs | `test/tools/generate_docs_test.dart`, generator `--check` |

## 게임 핵심 흐름이 지켜졌는지 확인

- dead line은 확정 후보가 아니고 부분 족보는 contributor만 제거한다.
- 여러 scoring line과 overlap은 같은 tile을 한 번만 제거하며 line별 multiplier를 유지한다.
- draw, place, discard, confirm, next Blind, save/load 뒤 deck conservation이 유지된다.
- valid save는 scene과 snapshot을 복원하고 invalid HMAC·exact schema mismatch는 invalid로 판정한다.
- current Stage/Stake restart는 각각 저장된 snapshot 경계로 돌아가며 transient presentation은 복원하지 않는다.
- Battle → settlement → Market → next Blind flow가 provider와 UI에서 같은 runtime state를 읽는다.

## Market과 Item 자동 점검

반복 실행 가능한 bucket만 유지한다. 날짜별 closing status와 일회성 screenshot 경로는 Git history가 소유한다.

| Bucket | 검증 | Primary tests / fixture |
|---|---|---|
| `reroll_policy` | S1 첫 Market 무료 1회, stale flag 무시, Item/Passive 할인 비용과 문구 | `game_shop_reroll_confirmation_test.dart`, `game_shop_discounted_reroll_test.dart`, `rummi_market_facade_test.dart`, `/game?fixture=stale_first_reroll_market` |
| `tool_use_feedback` | source Item, target, result label, Gold `+NG`, non-Gold feedback, 사용 후 선택 해제 | `game_shop_use_feedback_test.dart`, `game_shop_growth_use_feedback_test.dart`, `game_shop_non_gold_use_flight_test.dart`, `game_shop_screen_trade_ticket_test.dart`, `/game?fixture=market_item_motion_eye_check` |
| `offer_stability` | 구매한 Item 후보는 빈자리로 남고 `trade_ticket`은 Item 후보만 교체 | `rummi_market_facade_test.dart`, `debug_run_fixture_service_test.dart`, `game_shop_screen_trade_ticket_test.dart` |
| `slot_height` | Jester/Slots와 Tool/Gear section 외곽 높이가 tab·구매·사용 중 유지 | `/game?fixture=market_item_motion_eye_check` browser eye-check |

## Market 직접 확인

1. 정산 뒤 Market에 진입하고 title, Gold, 현재 tab을 확인한다.
2. `Jester / Slots`에서 Jester offer와 `Q1-Q3`, `P1-P2` 보유 slot을 확인한다.
3. `Tool / Gear`에서 Tool/Gear offer와 `T1-T3`, `G1-G2` 보유 slot을 확인한다.
4. Q-slot Item을 구매하고 Gold 차감, 다음 빈 Q slot 배치, 현재 offer 빈자리를 확인한다.
5. Passive, Tool, Gear를 각각 구매해 지정 placement에만 들어가는지 확인한다.
6. 구매, tab switch, Tool 사용 중 두 tab의 외곽 높이와 card animation이 container를 움직이지 않는지 확인한다.

## Reroll Smoke

- S1 basic 첫 Market은 `첫 리롤 무료`를 표시하고 `리롤 5→0`을 표시하지 않는다.
- 무료 보상은 lane별이 아니라 Market 전체에서 한 번만 소비된다.
- 이후 Market과 stale `firstRerollDiscount` restore는 정상 비용 `리롤 5`를 표시한다.
- Item/Passive 할인은 `리롤 5→4`처럼 원가와 실제 비용을 함께 표시한다.
- reroll할 때마다 다음 비용은 `+2`, 다음 Market 진입 시 기본 `5`로 reset된다.
- Reroll Token은 구매만으로 발동하지 않고 eligible reroll 시 stack과 실제 할인 Gold만 소비한다.
- stale fixture는 `/game?fixture=stale_first_reroll_market&debug_suppress_fixture_notice=1`로 열어 Jester와 Tool lane 모두 정상 비용인지 확인한다.

## Item Trigger Smoke

- `market_buy`: 자신을 할인하지 않고 다음 eligible 구매 성공 때만 stack을 소비한다.
- `enter_market`: 다음 Market 진입 뒤 한 번 적용되고 새 trigger 없이 반복되지 않는다.
- `boss_trophy`: 다음 Market의 Jester offer slot만 한 칸 늘리고 reroll 동안 유지한 뒤 다음 Market에서 제거된다.
- `trade_ticket`: Item offer만 교체하며 Jester/Tile offer는 유지한다.
- `coin_cache`, `thin_wallet`: 명시적 사용 또는 각 conditional rule이 성공한 경우에만 Gold를 바꾼다.
- 실패/no-op 경로는 Item을 소비하거나 다른 offer를 선택하지 않는다.

## Battle Item Zone Smoke

- 기본 tab은 `Slots`; `Q1-Q3`, `P1-P2`를 표시한다.
- `Tool / Gear` tab은 `T1-T3`, `G1-G2`를 표시한다.
- Jester와 Item card는 공용 54×70 sizing/inset을 따르고 count badge가 다른 정보와 겹치지 않는다.
- Q-slot usable Item은 detail overlay에 `사용` action을 표시한다.
- Passive/Gear는 자동 효과 안내, Tool은 Market 사용 안내를 표시하고 Battle action을 노출하지 않는다.

## Device and Accessibility Eye-Check

- 기존 Chrome/Simulator 창을 재사용하고 새 창을 중복 실행하지 않는다.
- 대상 phone frame에서 Market 두 tab, Battle item zone, bottom safe area가 잘리거나 overflow하지 않는지 확인한다.
- locale `ko`, `en`, `ja`, `zh-CN`, `zh-TW`에서 핵심 label이 card/action 영역을 넘지 않는지 확인한다.
- focus-out/options 진입 전 tutorial이 닫히고 강제 종료 뒤 첫 step부터 복구되는지 확인한다.
- 실행 종료 뒤 Chrome Helper, WebDriver, ChromeDriver, Flutter web server 잔류 process를 정리한다.

## Evidence and Done Gate

- 실행한 명령, exit code, pass/fail 수, fixture/locale/viewport를 기록한다.
- 발견한 overflow, text clipping, stale offer, 잘못된 Gold·inventory 변화는 실패로 기록하고 같은 bucket을 재실행한다.
- 실행하지 않은 검증은 통과로 쓰지 않는다.
- 관련 targeted suite, generator freshness, `git diff --check`, scope check가 통과해야 Done이다.
