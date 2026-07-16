# System Architecture

## Runtime Context and Containers

[main.dart](../../lib/main.dart)는 Flutter binding, Firebase, EasyLocalization, StorageHelper, review state, SoundManager를 초기화한 뒤 `ProviderScope → EasyLocalization → App` 순서로 runtime context를 만든다. [app.dart](../../lib/app.dart)는 translation scope, `MaterialApp.router`, theme, global background, app lifecycle BGM을 소유한다. [router.dart](../../lib/router.dart)는 7 route와 restored runtime 주입을 소유한다.

게임별 container는 `NotifierProvider.family<GameSessionNotifier, GameSessionState, GameSessionArgs>`다. args가 seed, difficulty, modifier, Blind tier, optional restored runtime을 고정하고, notifier는 current session/run progress를 facade로 변환해 view에 전달한다. Settings와 Title 저장 검사는 별도 Riverpod notifier를 사용해 game session과 생명주기를 섞지 않는다.

## Layer Responsibilities

| Layer | 책임 | 금지되는 결합 |
|---|---|---|
| logic/model | board, deck, hand, Blind, scoring, Jester/Item/tile/Boss 효과와 pure-ish facade 계산 | route, dialog, animation timing 소유 금지 |
| provider/notifier | command precondition, mutable runtime 변경, revision, derived Battle/Market/Station/save facade, scene·loop phase 전환 | BuildContext, modal navigation, asset text layout 소유 금지 |
| service | save codec/integrity, unlock/progression, catalog asset loader, tutorial state, analytics, sound/settings platform boundary | widget-local selection·animation 소유 금지 |
| view/widget | route input, user gesture, modal/overlay, presentation sequence, locale text, save 호출 시점 | scoring/economy를 별도로 재구현하거나 transient animation을 save 정답으로 사용 금지 |

핵심 runtime은 [rummi_poker_grid_session.dart](../../lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart), provider 경계는 [game_session_notifier.dart](../../lib/providers/features/rummi_poker_grid/game_session_notifier.dart), view host는 [game_view.dart](../../lib/views/game_view.dart)가 소유한다.

## Durable Domain and Transient Presentation

| Durable domain / save 대상 | Transient presentation / save 제외 |
|---|---|
| `RummiPokerGridSession`: RNG, ruleset, Blind, deck, board, hand, eliminated, move history, confirm modifiers·counters | selected hand/board/Jester/Item overlay, board-move selection mode, dialog open state |
| `RummiRunProgress`: Station/tier, gold, reroll lanes, inventory, Jester slot state, growth, added/tile offers, unlock·collection state | `GameStageFlowPhase`, active settlement line/step/effect index, displayed score, board snapshot, animation tick |
| active scene, difficulty, run modifier | tutorial overlay/focus index, pause veil, game-over fade, Market selection/tab animation, feedback flight |
| stage-start와 stake-start snapshot | pending item presentation event와 view-local timers/completer |

[game_session_state.dart](../../lib/providers/features/rummi_poker_grid/game_session_state.dart)는 durable object와 read facade를 한 state snapshot으로 노출하지만, [game_session_presentation_state.dart](../../lib/providers/features/rummi_poker_grid/game_session_presentation_state.dart)는 save에서 제외한다. restore/restart는 presentation을 `initial`로 reset하므로 animation 중간 상태가 gameplay 정답을 바꾸지 않는다.

## Critical Flow 1: Battle

```text
gesture
→ GameView callback
→ GameSessionNotifier battle command
→ session/runProgress mutation
→ _replaceState + revision
→ Station/Battle/Market facade rebuild
→ widget render and feedback
→ stable boundary에서 active-run save
```

View는 input lock과 selection mode를 확인하고 notifier command를 호출한다. notifier/session이 action precondition과 결과를 소유하며 view는 반환값을 notice·motion·sound로 표현한다. confirm은 durable 결과를 먼저 만든 뒤 settlement presentation을 순차 실행한다. `GameStageFlowPhase` 중 implicit save는 건너뛰고 명시적 stable scene에서 저장한다.

## Critical Flow 2: Settlement and Market

```text
target clear
→ notifier prepareSettlementAndCashOut
→ battle scene save
→ settlement/cash-out presentation
→ enterMarketAfterCashOut + shop scene
→ Market commands + queued/flush save
→ blindSelect runtime 생성·저장
→ router 이동
```

Settlement command가 gold, Boss reward, growth, scene/loop phase를 갱신한다. Market open은 offer와 enter-market Item effect를 만든다. Market widget은 command callback만 호출하고 durable inventory/economy는 notifier/run progress가 소유한다. 다음 이동 전 save scene을 `blindSelect`로 바꾸고 Boss tier 뒤 Station index를 정규화한다.

## Critical Flow 3: Save and Restore

```text
notifier buildSaveRuntimeState
→ codec DTO / JSON
→ device key HMAC-SHA256
→ StorageHelper payload + signature
→ Title inspect
→ signature/schema verify
→ catalog ID rebind + runtime restore
→ active scene route
→ notifier bootstrap + presentation reset
```

Title은 `available/none/invalid`를 읽어 continue 또는 delete recovery를 제공한다. `blindSelect` scene은 해당 route로, `battle`과 `shop`은 `/game`으로 복원한다. `shop` restore는 Jester와 Item catalog가 준비된 뒤 Market dialog를 다시 연다. 세부 계약은 [SAVE_DATA.md](SAVE_DATA.md)가 소유한다.

## Content Loading

- Jester와 Item definition은 asset JSON을 loader/model로 parse한다.
- GameView는 첫 frame 뒤 catalog load를 시작한다. Jester catalog는 notifier state에 넣고 Item catalog는 GameView가 Item runtime/UI 결합에 사용한다.
- restored Market은 Item catalog 없이 먼저 열지 않고 catalog 준비 callback에서 재개한다.
- active save restore는 owned Jester ID를 현재 Jester catalog definition에 다시 결합한다.
- Archive는 unlock state, Jester catalog, Item catalog를 함께 읽어 read-only collection view를 만든다.
- locale-specific Jester/Item text는 definition과 분리된 translation scope가 current locale에 맞춰 읽고 fallback을 제공한다.

정의와 runtime chain은 [CONTENT_SYSTEM.md](CONTENT_SYSTEM.md), loader는 [jester_catalog_loader.dart](../../lib/logic/rummi_poker_grid/jester_catalog_loader.dart)와 [item_catalog_loader.dart](../../lib/logic/rummi_poker_grid/item_catalog_loader.dart)가 소유한다.

## Firebase Analytics and Privacy Boundary

- 앱 시작 시 Firebase Core를 초기화하고 router에 `FirebaseAnalyticsObserver`를 붙인다.
- `GameAnalyticsService`는 event/parameter 이름과 string 길이·개수를 제한하고 실패를 gameplay 밖으로 격리한다.
- debug fixture와 automation query context는 gameplay event 전송을 막는다. run seed는 raw 값 대신 bucket만 보내는 호출을 사용한다.
- current analytics call에는 app-specific user ID 설정이나 active save payload/board serialization 전송이 없다.
- native는 uncaught Flutter/platform error를 Crashlytics에 fatal로 기록하고 web에서는 이 handler를 등록하지 않는다.
- code에는 analytics collection consent/opt-out UI가 별도로 없다. SDK 수준 수집 정책과 플랫폼 설정은 이 문서가 보증하지 않는다.
- 스토어 privacy disclosure의 작성·검증은 이 consolidation 범위에서 제외하며 여기서 별도 문서에 링크하지 않는다.

경계 구현은 [game_analytics_service.dart](../../lib/services/game_analytics_service.dart), 초기화는 [main.dart](../../lib/main.dart), route observation은 [router.dart](../../lib/router.dart)가 소유한다.

## Module, Change Risk, and Test Map

| 변경 종류 | 영향 경계 | 우선 검증 |
|---|---|---|
| scoring/action | logic → notifier facade → Battle UI → save snapshot | `rummi_session_test`, `game_session_notifier_test`, station read-path tests |
| Station/Market economy | run progress → Market facade/commands → settlement/Market UI → save | Market facade/notifier, cash-out, Market widget tests |
| content field/ID | JSON → loader/model → runtime → translation/UI → save rebind | generator check, Item/Jester runtime, active save tests |
| presentation/timing | presentation state → overlays/dialog/lifecycle | game/shop lifecycle, motion/effect/cash-out widget tests; durable diff가 없어야 함 |
| route/continue | router → Title/New Run/Blind Select → active scene restore | title, navigation, Blind Select, active save tests |
| save field/schema | runtime → codec → HMAC/storage → restore/restart | active save service와 notifier restart tests |
| locale/accessibility | translation scopes → fixed frame/widgets → semantics | settings/navigation/overflow tests와 별도 수동 assistive-tech 검증 |
| analytics | view event context → service sanitizer → Firebase sink | analytics service와 event caller tests; gameplay state 불변 확인 |

이 표는 change boundary를 설명하며 파일 수나 directory snapshot을 inventory로 고정하지 않는다.



## Analytics and Monetization Boundary

- 현재 runtime event는 기계적 funnel 중심이며 Continue/resume, save health, bookmark, retry-vs-abandon 구분, unlock spend, locale, review 결과가 없다.
- `run_end(expired)`는 Game Over 첫 표시 때 기록되어 Retry와 실제 종료를 구분하지 못한다. S8 completed도 endless 선택 전에 찍힐 수 있다.
- restored route argument 기본값 때문에 High Stakes/Clash/Boss resume analytics가 오분류될 수 있다.
- iOS `IS_ANALYTICS_ENABLED=false` 설정이 남아 있어 수집 여부는 device 검증 전까지 unknown이다.
- 광고 SDK, IAP, consent/CMP, ATT, reward ledger, server-side verification은 없다. 광고·유료화는 현재 아키텍처 계약이 아니라 planning 후보다.

## Source and Update Trigger

bootstrap/container 순서, layer ownership, durable/transient 경계, 세 critical flow, catalog load 순서, Firebase event/privacy boundary 또는 module test boundary가 바뀌면 이 문서와 직접 보호 테스트를 같은 변경에서 갱신한다.
