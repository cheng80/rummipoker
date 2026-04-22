# Current Code Map

> GCSE role: `Context`
> Source of truth: 현재 코드 탐색 순서, 책임 경계, 작업 재개 기준.

이 문서는 코드 기준 문서 3종 중 하나다.

- `CURRENT_SYSTEM_OVERVIEW.md`: 현재 앱이 실제로 무엇을 구현했는가
- `CURRENT_CODE_MAP.md`: 어디를 읽고 어디를 고쳐야 하는가
- `CURRENT_TO_V4_GAP.md`: 현재 코드와 V4 목표 사이의 차이는 무엇인가

새 작업자는 이 3개 문서만 읽어도 코드 작업을 이어갈 수 있어야 한다. 진행률과 다음 작업은 `planning` 문서에서 보완하지만, 코드 사실은 이 문서를 우선한다.

---

## 1. Read Order

문서 읽기 순서:

1. `START_HERE.md`
2. `docs/00_docs_README.md`
3. `docs/current_system/CURRENT_SYSTEM_OVERVIEW.md`
4. `docs/current_system/CURRENT_CODE_MAP.md`
5. `docs/current_system/CURRENT_TO_V4_GAP.md`
6. `docs/planning/STATUS.md`
7. `docs/planning/IMPLEMENTATION_PLAN.md`

코드 읽기 순서:

1. `lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart`
2. `lib/providers/features/rummi_poker_grid/game_session_notifier.dart`
3. `lib/providers/features/rummi_poker_grid/game_session_state.dart`
4. `lib/services/active_run_save_service.dart`
5. `lib/views/game_view.dart`
6. `lib/views/game/widgets/`
7. `lib/views/title_view.dart`
8. `lib/router.dart`

Item/Market/Station 작업이면 아래 파일을 추가로 먼저 본다.

- `lib/logic/rummi_poker_grid/item_definition.dart`
- `lib/logic/rummi_poker_grid/item_effect_runtime.dart`
- `lib/logic/rummi_poker_grid/rummi_market_facade.dart`
- `lib/logic/rummi_poker_grid/rummi_battle_facade.dart`
- `lib/logic/rummi_poker_grid/rummi_settlement_facade.dart`
- `lib/logic/rummi_poker_grid/rummi_station_facade.dart`
- `data/common/items_common_v1.json`

---

## 2. Core Combat

### `lib/logic/rummi_poker_grid/models/tile.dart`

- tile model
- color/rank representation
- physical tile identity basis

### `lib/logic/rummi_poker_grid/models/poker_deck.dart`

- standard deck generation
- shuffle
- draw pile snapshot/restore
- `copiesPerTile` deck size support

### `lib/logic/rummi_poker_grid/models/board.dart`

- 5x5 board storage
- cell read/write
- board snapshot/restore

### `lib/logic/rummi_poker_grid/hand_rank.dart`

- hand rank enum
- base score table
- dead-line score definition

Protection rule:

- `onePair = 0` is the current baseline.
- Do not change One Pair scoring unless the user explicitly asks for a rules change.

### `lib/logic/rummi_poker_grid/hand_evaluator.dart`

- best hand evaluation per line
- contributor index calculation
- partial-line evaluation
- `10-11-12-13-1` straight handling

### `lib/logic/rummi_poker_grid/rummi_poker_grid_engine.dart`

- row/column/diagonal scan
- 12-line evaluation
- occupied-count handling

### `lib/logic/rummi_poker_grid/rummi_blind_state.dart`

- current battle target score
- board discard / hand discard resources

Current naming caveat:

- `blind` is still used in code, but much of the current meaning is battle/stage objective state.

### `lib/logic/rummi_poker_grid/rummi_ruleset.dart`

- runtime ruleset values
- hand-size and combat rule toggles
- migration bridge for target rules without broad symbol rename

### `lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart`

Main runtime facade for the battle session.

Responsibilities:

- draw
- place tile
- board discard
- hand discard
- confirm scoring lines
- contributor removal
- overlap multiplier application
- expiry signal
- next-stage preparation
- session snapshot/restore

If a behavior changes battle state, this file or a facade around it is usually involved.

---

## 3. Jester, Item, Market, Economy

### `lib/logic/rummi_poker_grid/jester_meta.dart`

Current combined runtime for:

- Jester model/catalog interpretation
- run progress
- stage target curve
- gold/economy
- shop offer generation
- buy/sell/reroll
- stateful Jester values

Boundary caveat:

- This file still combines several long-term domains. Prefer adding adapter/facade boundaries over broad rewrites.

### `lib/logic/rummi_poker_grid/jester_effect_runtime.dart`

- Jester runtime effect application
- scoring/economy/stateful hooks

### `lib/logic/rummi_poker_grid/item_definition.dart`

- Item data model
- item catalog loading
- effect operation definitions

### `lib/logic/rummi_poker_grid/item_effect_runtime.dart`

- Item effect handlers
- battle/market/settlement/station timing hooks
- owned item runtime effect application

When implementing new item behavior, check `docs/planning/ITEM_EFFECT_RUNTIME_MATRIX.md` after reading this file.

### Facades

- `rummi_battle_facade.dart`: battle read model boundary
- `rummi_market_facade.dart`: market/shop read model boundary
- `rummi_settlement_facade.dart`: settlement/cash-out read model boundary
- `rummi_station_facade.dart`: station/blind selection read model boundary

These are migration bridges. Prefer routing UI reads through facades instead of reintroducing direct mutable runtime reads in widgets.

### Data

- `data/common/jesters_common_phase5.json`: current curated Jester runtime catalog
- `data/common/items_common_v1.json`: current Item v1 runtime catalog
- `assets/translations/data/`: localized names/effect copy

---

## 4. Save, Continue, Run Setup

### `lib/services/active_run_save_service.dart`

Main active run persistence service.

Responsibilities:

- active run save/load
- integrity check
- schema version handling
- stage start snapshot
- saved session DTOs
- saved run progress DTOs

Protection rule:

- Current save is active-run snapshot based.
- Do not replace the save schema or persistence engine as part of unrelated gameplay work.

### `lib/services/active_run_save_facade.dart`

- smaller read/write boundary around active run save
- used to reduce direct service coupling

### `lib/services/new_run_setup.dart`

- new run creation setup
- target flow entry support

### `lib/services/blind_selection_setup.dart`

- blind/station selection setup
- connects selection flow to battle startup

### `lib/services/run_progression_service.dart`

- run/stage progression helper logic

### `lib/services/run_unlock_state_service.dart`

- unlock state support for run selection flows

### `lib/services/debug_run_fixture_service.dart`

- debug fixture entry support
- useful for smoke and targeted UI checks

### `lib/utils/storage_helper.dart`

- lower-level local storage wrapper

---

## 5. State Management

### `lib/providers/features/rummi_poker_grid/game_session_state.dart`

Runtime UI state snapshot for battle/shop/settlement.

Contains:

- session
- run progress
- stage start snapshot
- active run scene
- selection state
- Jester overlay state
- settlement flow state
- item/battle/market state that must trigger redraw

### `lib/providers/features/rummi_poker_grid/game_session_notifier.dart`

Primary app orchestration layer for the current playable loop.

Responsibilities:

- create/restore session
- restart current stage
- handle selection state
- place/discard/confirm actions
- open settlement/cash-out
- shop reroll/buy/sell
- item commands
- next battle/stage transition
- save runtime state

Rule:

- UI should call notifier commands.
- Avoid moving command logic back into widgets.

### `lib/providers/features/rummi_poker_grid/title_notifier.dart`

- continue availability
- save deletion
- stored run load entry
- title screen state decisions

### `lib/providers/features/rummi_poker_grid/rummi_session_notifier.dart`

- older or narrower session provider path
- verify current usage before extending it

---

## 6. Views And Routing

### `lib/views/title_view.dart`

- home/title UI
- continue/new run/debug fixture entry

### `lib/views/game_view.dart`

- battle screen orchestration
- notifier command calls
- save trigger
- SFX/overlay/navigation wiring
- transition to shop/settlement related UI

Rule:

- `game_view.dart` should coordinate UI flow, not own core game rules.

### `lib/views/blind_select_view.dart`

- blind/station selection UI
- next battle setup entry

### `lib/views/game/widgets/`

Important widgets:

- `game_shared_widgets.dart`
- `game_jester_widgets.dart`
- `game_hand_zone.dart`
- `game_cashout_widgets.dart`
- `game_shop_screen.dart`
- `game_options_dialog.dart`
- `game_tile_choice_dialog.dart`

Widget rule:

- Widgets should render read models and dispatch commands.
- They should not become new sources of game truth.

### Shared UI

- `lib/widgets/phone_frame_scaffold.dart`: common phone frame layout
- `lib/widgets/starry_background.dart`: common background

### Routing

- `lib/router.dart`: route definitions and navigation targets

---

## 7. Tests And Smoke

Core tests to check before/after risky work:

- `test/logic/rummi_board_engine_test.dart`
- `test/logic/rummi_session_test.dart`
- `test/providers/game_session_notifier_test.dart`
- `test/services/active_run_save_service_test.dart`

Smoke scripts:

- `tools/ios_sim_smoke.sh`
- `tools/web_build_smoke.sh`

Use iOS smoke for user-facing mobile flow changes. Use web smoke when routing, storage, or web build boundaries change.

---

## 8. Change Boundary Rules

- Combat rule changes start in `lib/logic/rummi_poker_grid/` and require logic tests.
- UI state command changes start in `game_session_notifier.dart`, not widgets.
- Save/restore changes start in `active_run_save_service.dart` and require save tests.
- Market/shop read changes should prefer `rummi_market_facade.dart`.
- Battle read changes should prefer `rummi_battle_facade.dart`.
- Settlement reward/read changes should prefer `rummi_settlement_facade.dart`.
- Station/blind setup changes should check `blind_selection_setup.dart`, `new_run_setup.dart`, and `rummi_station_facade.dart`.
- Item effect changes should update `item_effect_runtime.dart` and `docs/planning/ITEM_EFFECT_RUNTIME_MATRIX.md` together.

---

## 9. Do Not Change Casually

- One Pair score
- save schema
- Jester ids
- item ids
- broad symbol names such as `stage`/`blind`
- persistence engine
- current prototype helper paths used by smoke/debug flows

---

## 10. Short Summary

The current runtime is anchored by five files:

1. `rummi_poker_grid_session.dart`
2. `game_session_notifier.dart`
3. `active_run_save_service.dart`
4. `jester_meta.dart`
5. `item_effect_runtime.dart`

Most work should start by identifying which of these owns the behavior, then checking the relevant facade/read model and widget boundary.
