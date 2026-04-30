# Board Move / Hand Size / Item-Jester Runtime Plan

> GCSE role: `Execution`
> Role: 보드 이동, 손패 한도, Item/Jester runtime 확장 feature plan.

이 문서는 `보드 타일 이동`, `손패 한도 증가`, 기존 `ItemEffectRuntime` 미구현 항목을 같은 작업 흐름으로 묶는 실행 계획이다.

## 1. Design Decision

### 보드 타일 이동

- `보드 버림`, `손패 버림`과 같은 전투 제한 자원으로 `보드 이동`을 추가한다.
- 기본 이동은 “보드 위 타일 1장을 빈 칸으로 옮기기”다.
- 이미 좋은 줄을 깨뜨릴 수 있다. 이동 가능 여부를 줄 확정 가능 상태나 잠금 상태로 막지 않는다.
- 잘못 이동해서 점수 후보가 깨지는 리스크는 유저 선택으로 둔다.
- 이동 후 보드는 즉시 재평가된다.
- 이동 자체는 점수나 골드를 주지 않는다.
- 기본값은 보드/손패 버림처럼 넉넉하게 `스테이션마다 3회`에서 시작하고, 밸런스 확인 후 줄이는 방향으로 조정한다.
- 밸런스 확인 전까지 이동 가능한 대상은 “타일이 있는 칸 -> 빈 칸”으로 제한한다. 타일끼리 swap은 후속 변형 효과로만 검토한다.

### 손패 한도 증가

- 기본 손패 한도는 현행처럼 1장을 유지한다.
- 일반 런에서 손패 2장은 장비/희귀 Jester/패시브 아이템 보상으로 제공한다.
- 손패 3장은 전설급 보상 또는 큰 패널티가 있는 빌드로 제한한다.
- 기존 debug hand size 1~3 기능은 유지하되, 일반 런 밸런스와 섞이지 않도록 “debug override”로 분리해서 다룬다.

### Item / Jester 역할 분리

- 기본 시스템: 모든 런에서 `보드 이동 3회`를 제공한다.
- Item: 이동 횟수 추가, 이동 변형, 이동 되돌리기, 손패 한도 보정처럼 “사용/장착 효과”를 담당한다.
- Jester: 이동을 사용했을 때, 아꼈을 때, 이동 후 특정 족보를 만들었을 때 보상을 주는 “빌드 방향”을 담당한다.

## 2. New Runtime Concepts

### Station Resource

`RummiBlindState` 또는 별도 station resource adapter에 다음 값을 추가한다.

| Field | 의미 | 기본값 |
|---|---|---:|
| `boardMovesRemaining` | 이번 스테이션에서 남은 보드 이동 횟수 | 3 |
| `boardMovesMax` | 이번 스테이션의 보드 이동 최대치 | 3 |

초기 구현은 save 호환성 때문에 optional restore fallback을 둔다.

- 저장 payload에 값이 없으면 `3/3`으로 복원한다.
- stage start snapshot에도 포함한다.
- restart current stage는 이동 횟수도 stage 시작 상태로 되돌린다.

### Runtime Events

Item/Jester 애니메이션과 후속 콜백 연결을 위해 이벤트 이름을 명확히 둔다.

| Event | 발생 시점 |
|---|---|
| `boardTileMoved` | 보드 타일 이동 성공 |
| `boardMoveAdded` | 아이템/장비/Jester로 이동 횟수 증가 |
| `boardMoveConsumed` | 이동 횟수 1 차감 |
| `handSizeIncreased` | 손패 한도 증가 |
| `moveUndoRegistered` | 이동 되돌리기 가능 상태 저장 |
| `moveTriggeredJester` | 이동 관련 Jester 발동 |

## 3. UX Safety Plan

타일 이동은 단순 탭으로 발동하지 않는다.  
드래그/드롭 대신 현재 UI 구조에 맞춰 `선택한 보드 타일 + 이동 버튼 + 빈 칸 선택 + 확인 팝업` 흐름으로 구현한다.

### 기본 조작

1. 유저가 보드 위 타일을 선택한다.
2. `이동` 버튼을 누른다.
3. 이동 모드에 들어가면 선택한 타일만 강조하고, 다른 타일이 있는 칸은 회색 잠금 상태로 보인다.
4. 이동 가능한 빈 칸만 선택 가능 상태로 표시한다.
5. 이동 모드 중 선택한 원래 타일을 다시 누르면 이동 모드를 해제한다. 이때 이동 횟수는 소모하지 않는다.
6. 빈 칸을 누르면 확인 팝업을 띄운다.
7. 팝업에서 `이동`을 누르면 실제 이동하고 이동 횟수 1회를 소모한다.
8. 팝업에서 `취소`를 누르면 이동 모드는 유지하며, 다시 이동 가능한 빈 칸 표시 상태로 돌아간다.

### 안전장치

- 이동 횟수 `이동 X/Y`를 하단 resource row에 표시한다.
- 이동 모드에서는 보드 이동과 팝업 외의 모든 전투 기능을 막는다.
- 이동 모드 입력 차단은 새 시스템을 만들지 않고, 현재 `GameView`의 최상위 `Stack`과 Jester/Item overlay에서 쓰는 `ModalBarrier` 패턴을 재사용한다.
- 단, barrier 위에 보드 이동 전용 레이어를 올려 보드 셀 선택은 계속 받을 수 있게 한다.
- 첫 구현은 전체 화면 barrier + 보드 레이어 재표시 + 이동 확인 dialog 조합으로 단순하게 간다.
- 이동 중 영향을 받는 행/열/대각선을 하이라이트한다.
- 이동 전후 확정 가능 줄 수 또는 예상 점수 변화를 표시한다.
- 확정 가능한 줄을 깨뜨리는 이동이면 경고 텍스트를 보여준다.
- 남은 이동이 0이면 `이동` 버튼을 비활성화하고 이유를 표시한다.
- 이동 확정 후 snack/event를 띄운다.
- “이동 되돌리기”는 기본 기능이 아니라 item/Jester 효과로만 제공한다.

### UI 구현 단위

| Step | UI 작업 |
|---|---|
| UI-1 | 하단 resource row에 `이동 X/Y` 추가 |
| UI-2 | 하단 액션 버튼을 2단 구조로 재배치 |
| UI-3 | 선택된 보드 타일이 있을 때 `이동` 버튼 활성화 |
| UI-4 | `_boardMoveMode` / `_pendingBoardMoveSource` UI state 추가 |
| UI-5 | 이동 모드 전용 barrier + 보드 레이어 추가 |
| UI-6 | 이동 가능한 빈 칸 / 잠긴 타일 칸 / 선택 원본 칸 visual state 추가 |
| UI-7 | 빈 칸 선택 시 이동 확인 dialog 추가 |
| UI-8 | 팝업 취소 시 이동 모드 유지, 원본 타일 재터치 시 이동 모드 해제 |
| UI-9 | 영향 라인 highlight / 위험 문구 추가 |
| UI-10 | item/Jester 이동 효과 toast/badge 연결 |

### 하단 액션 버튼 배치

현재 하단 액션은 `선택 해제 / 보드 버림 / 손패 버림 / 확정` 4개 버튼 한 줄이다. `이동`을 같은 줄에 추가하면 모바일 폭에서 버튼 텍스트가 너무 좁아지므로 2단 구조로 바꾼다.

권장 배치:

```text
[ 선택 해제 ][ 이동 ][ 보드 버림 ][ 손패 버림 ]
[                  확정                  ]
```

구현 기준:

- 상단 utility row: 4개 버튼 동일 폭, compact height `32~34`.
- 하단 primary row: `확정` 단독 full width, height `40`.
- row gap은 `6`, button gap은 `6`부터 시작한다.
- `확정`은 기존 노란 primary 색을 유지한다.
- `이동`은 보드 타일이 선택되어 있고 이동 횟수가 남아 있을 때만 활성화한다.
- 손패 타일만 선택된 상태에서는 `이동`을 비활성화한다.
- 이동 횟수가 0이면 `이동` 비활성화와 함께 snack 또는 disabled reason을 제공한다.
- 이동 모드에 들어가면 하단 액션 바는 barrier 아래에 잠기며, 이동 모드 전용 보드 레이어와 확인 팝업만 입력을 받는다.
- 향후 아이콘을 넣을 경우 `이동`은 swap/arrow 계열 아이콘을 쓰되, 1차 구현은 텍스트 버튼으로 시작한다.

## 4. Core Implementation Phases

### Phase A: Resource Model

목표: 이동 자원을 저장 가능한 전투 자원으로 추가한다.

Files:

- `lib/logic/rummi_poker_grid/rummi_blind_state.dart`
- `lib/logic/rummi_poker_grid/rummi_station_facade.dart`
- `lib/services/active_run_save_service.dart`
- `test/logic/rummi_session_test.dart`
- `test/services/active_run_save_service_test.dart`

작업:

- `boardMovesRemaining`, `boardMovesMax` 추가
- `prepareNextBlind`에서 이동 기본값 주입
- save/restore optional fallback 추가
- stage restart snapshot에 이동 자원 포함
- station facade resource에 이동 값 추가

Acceptance:

- 새 런은 이동 `3/3`으로 시작한다.
- 저장/복원 후 이동 값이 유지된다.
- 기존 저장 데이터는 이동 값이 없어도 복원된다.

### Phase B: Board Move Command

목표: UI와 분리된 세션/노티파이어 command로 보드 이동을 적용한다.

Files:

- `lib/logic/rummi_poker_grid/models/board.dart`
- `lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart`
- `lib/providers/features/rummi_poker_grid/game_session_notifier.dart`
- `test/logic/rummi_session_test.dart`
- `test/providers/game_session_notifier_test.dart`

작업:

- `RummiBoard.moveCell(fromRow, fromCol, toRow, toCol)` 추가
- 비어 있는 출발칸/차 있는 도착칸/횟수 0 실패 처리
- 성공 시 이동 횟수 1 차감
- 이동 후 선택 상태 정리
- 이동 후 expiry/confirm 후보 재평가 흐름 유지

Acceptance:

- 타일이 있는 칸에서 빈 칸으로 이동된다.
- 점수 후보 줄에 있던 타일도 이동 가능하다.
- 이동 횟수가 0이면 실패한다.
- 보드 버림/손패 버림 횟수는 변하지 않는다.

### Phase C: UI Move Mode + Confirm

목표: 실수 방지를 위한 버튼 기반 이동 모드와 confirm UX를 만든다.

Files:

- `lib/views/game_view.dart`
- `lib/views/game/widgets/game_board.dart` 또는 현재 board widget 파일
- `lib/views/game/widgets/game_shared_widgets.dart`
- `test/views/game/*`

작업:

- 하단 버튼을 compact utility row + full-width confirm row로 재배치
- utility row에 `이동` 버튼 추가
- 선택 타일이 있을 때 `이동` 버튼 표시
- `_boardMoveMode` / `_pendingBoardMoveSource` UI state 추가
- 이동 모드 중 일반 전투 입력 차단
- 타일이 있는 칸은 회색 잠금, 빈 칸은 이동 가능 표시
- 원본 타일 재터치 시 이동 모드 해제
- 빈 칸 선택 시 이동 확인 dialog 표시
- 팝업 취소 시 이동 모드 유지
- 이동 전후 영향 라인 표시
- resource row에 이동 횟수 추가

Acceptance:

- 단순 탭으로 이동되지 않는다.
- 하단 버튼은 모바일 폭에서 텍스트가 잘리지 않는다.
- `확정`은 full-width primary 버튼으로 남는다.
- 선택한 타일에서 `이동` 버튼을 눌러야 이동 모드가 열린다.
- 이동 모드에서는 다른 전투 기능이 실행되지 않는다.
- 이동 모드에서 원본 타일을 다시 누르면 이동이 취소된다.
- 빈 칸 선택 후 팝업에서 확인해야 이동된다.
- 팝업 취소는 이동 모드를 유지하고 보드/자원을 바꾸지 않는다.
- 이동 성공 시 저장된다.

### Phase D: Item Data Additions

목표: 이동/손패 관련 item을 v1 catalog에 추가하고 한글 번역을 연결한다.

추가 후보:

| ID | Type | Placement | 효과 |
|---|---|---|---|
| `move_token` | consumable | quickSlot | 이번 스테이션 보드 이동 +1 |
| `slide_wax` | consumable | quickSlot | 이번 이동은 추가 보너스 발동 조건을 만족 |
| `board_lift` | utility | inventory | 상점/전투에서 다음 스테이션 이동 +1 예약 |
| `undo_seal` | consumable | quickSlot | 마지막 보드 이동 1회 되돌리기 |
| `organizer_glove` | equipment | equipped | 각 스테이션 시작 시 보드 이동 +1 |
| `travel_pouch` | passive_relic | passiveRack | 손패 한도 +1 |
| `wide_grip` | equipment | equipped | 손패 한도 +1, 보드 버림 -1 |
| `grand_satchel` | passive_relic | passiveRack | 손패 한도 +2, 손패 버림 -1 |

Data files:

- `data/common/items_common_v1.json`
- `assets/translations/data/ko/items.json`
- `docs/planning/ITEM_EFFECT_RUNTIME_MATRIX.md`
- `test/logic/item_definition_test.dart`

새 op:

| Timing | Op |
|---|---|
| `use_battle` | `add_board_move` |
| `station_start` | `add_board_move` |
| `inventory_capacity` | `increase_hand_size` |
| `station_start` | `increase_hand_size_with_discard_penalty` |
| `use_battle` | `undo_last_board_move` |

Acceptance:

- 모든 신규 item은 localization key를 가진다.
- 원본 fallback은 영어, 유저 노출 한국어는 `타일/확정/스테이션/골드/칩/배수` 기준이다.
- 테스트에서 item 수와 신규 op mapping이 고정된다.

### Phase E: Item Effect Runtime Expansion

목표: 기존 미구현 item effect와 신규 이동/손패 op를 같은 runtime 확장으로 처리한다.

Files:

- `lib/logic/rummi_poker_grid/item_effect_runtime.dart`
- `lib/providers/features/rummi_poker_grid/game_session_notifier.dart`
- `test/logic/item_effect_runtime_test.dart`
- `test/providers/game_session_notifier_test.dart`

작업 순서:

완료된 축:

1. `add_board_move` 적용
2. `increase_hand_size` 적용
3. `increase_hand_size_with_discard_penalty` 적용
4. `undo_last_board_move` 적용
5. 기존 `station_start` 자원 item 적용
6. `deck_needle` 덱 확인/선택 버림 dialog 적용

남은 축은 item 단건이 아니라 공통 runtime hook 단위로 진행한다. 세부 대상은 [ITEM_EFFECT_RUNTIME_MATRIX.md](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/docs/planning/ITEM_EFFECT_RUNTIME_MATRIX.md)의 "공통 구현 묶음 플랜"을 따른다.

현재 기준:

- Phase A `Resource Model`: 완료
- Phase B `Board Move Command`: 완료
- Phase C `UI Move Mode + Confirm`: 1차 완료
- Phase D `Item Data Additions`: 완료
- Phase E `Item Effect Runtime Expansion`: v1 item 49개 runtime hook 1차 완료, `pendingHook` 0개

적용 완료 순서:

1. Direct gold/economy hooks 추가
   - 대상: `coin_cache`, `thin_wallet`, `ledger_clip`, `stage_map`
   - 상태: 1차 완료
2. Settlement reward modifier hook 추가
   - 대상: `coin_funnel`, `hand_funnel`
   - 상태: 1차 완료
3. Market discount/offer modifier state 추가
   - 대상: `reroll_token`, `coupon_stamp`, `merchant_stamp`, `jester_invoice`, `item_invoice`, `market_compass`, `shop_lens`, `lucky_counter`
   - 상태: 1차 완료
4. Confirm modifier queue/save/scoring hook 추가
   - 대상: `chip_capsule`, `mult_capsule`, `line_polish`, `straight_oil`, `flush_powder`, `pair_splint`, `score_abacus`, `thin_caliper`, `echo_bell`, `red_swatch`, `blue_swatch`, `black_swatch`, `yellow_swatch`, `rank_chalk`, `tile_polisher`, `overlap_pin`
   - 상태: 1차 완료
5. Inventory/sell hook 추가
   - 대상: `spare_pouch`, `jester_hook`
   - 상태: 1차 완료
6. Expiry guard hook 추가
   - 대상: `safety_net`
   - 상태: 1차 완료
7. Boss delayed market hook 추가
   - 대상: `boss_trophy`
   - 상태: 1차 완료
8. Board move follow-up marker 추가
   - 대상: `slide_wax`
   - 상태: 1차 완료

Acceptance:

- `catalogEffectRows`에 신규 item과 기존 item이 모두 handler에 매핑된다.
- v1 item 기준 `pendingHook`은 0개다.
- discard/move/hand size 자원 변경은 event list로 반환된다.

### Phase F: Jester Data Additions

목표: 이동/손패 전략을 강화하는 Jester를 추가한다.

추가 후보:

| ID | 효과 | 비고 |
|---|---|---|
| `mover_jester` | 보드 이동 후 첫 확정에 칩 +30 | 이동 사용 보상 |
| `maze_jester` | 이동을 쓰지 않고 스테이션 클리어 시 골드 +3 | 이동 보존 보상 |
| `switch_jester` | 이동을 모두 사용하면 배수 +8 | 이동 소모 보상 |
| `organizer_jester` | 이동 후 같은 숫자 2개 이상 포함 확정 시 배수 +6 | 이동 후 족보 보상 |
| `heavy_pockets` | 손패 한도 +1, 보드 이동 -1 | 강한 손패 보상에 패널티 |
| `wide_table` | 스테이션마다 보드 이동 +1 | 희귀/전설급 |
| `three_hand_trick` | 손패 한도 +2, 손패 버림 -1 | 전설급 |

Data files:

- `data/common/jesters_common_phase5.json`
- `assets/translations/data/ko/jesters.json`
- `test/logic/jester_translation_test.dart`

Acceptance:

- Jester id는 기존 id와 충돌하지 않는다.
- 한국어 문구에 트럼프 카드 기준 용어가 없다.
- 상점 노출 여부는 runtime 지원 상태에 따라 결정된다.

### Phase G: Jester Runtime Expansion

목표: 이동/손패 관련 Jester가 실제 상태에 영향을 주도록 한다.

Files:

- `lib/logic/rummi_poker_grid/jester_meta.dart`
- `lib/logic/rummi_poker_grid/jester_effect_runtime.dart`
- `lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart`
- `test/logic/jester_effect_runtime_test.dart`
- `test/logic/rummi_session_test.dart`

새 context:

| Field | 의미 |
|---|---|
| `boardMovesRemaining` | 남은 이동 |
| `boardMovesMax` | 이동 최대치 |
| `boardMoveUsedThisStation` | 이번 스테이션 이동 사용 여부 |
| `lastActionWasBoardMove` | 직전 액션이 이동인지 |
| `maxHandSize` | 현재 손패 한도 |

Acceptance:

- 이동 관련 Jester는 이동 이벤트 이후 조건을 판정한다.
- 손패 한도 Jester는 station start에 적용된다.
- Jester 발동도 `JesterEffectRuntime` event로 남는다.

### Phase H: Balance Pass

목표: 새 자원의 기본값과 보상 수치를 낮은 위험으로 조정한다.

초기값:

- 기본 이동: `3/3`
- 이동 +1 소모품 가격: 5~6 골드
- 이동 +1 장비 가격: 8~10 골드
- 손패 +1 장비 가격: 9~11 골드
- 손패 +2 전설 가격: 15+ 골드, 패널티 필수

검증 시나리오:

- 이동 1회/2회/3회 클리어율 비교
- 손패 1/2/3 평균 확정 점수 비교
- 이동 보존 Jester와 이동 소모 Jester가 동시에 과도한 보상을 주지 않는지 확인

## 5. Test Plan

### Unit

- board move success/fail
- move resource decrement
- save/restore move resources
- item `add_board_move`
- item `increase_hand_size`
- item `undo_last_board_move`
- Jester movement condition scoring
- hand size Jester station start

### Widget

- tap alone does not move a tile
- move button enters move mode
- tapping source tile again exits move mode without spending a move
- tapping occupied non-source cells in move mode does nothing
- popup cancel keeps move mode and leaves board unchanged
- popup confirm updates board/resource row
- no moves remaining disables confirm
- item overlay use updates move/hand resources

### Integration

- start station -> move tile -> confirm line -> save -> restore
- move tile -> restart current stage -> move resource restored
- buy move item -> use in battle -> move count increases
- own hand-size Jester -> station start max hand size increases

## 6. Implementation Order

작업 순서는 아래로 고정한다.

1. `Phase A` 이동 자원 모델 + save fallback
2. `Phase B` board move command
3. `Phase C` move mode/confirm UX
4. `Phase D` item data 추가
5. `Phase E` item effect runtime 확장
6. `Phase F` Jester data 추가
7. `Phase G` Jester runtime 확장
8. `Phase H` 밸런스/수치 조정

중간에 기존 미구현 item effect를 처리할 때도 `Phase E` 안에서 진행한다.

## 7. Non-Goals

- One Pair 점수 변경
- 타일끼리 swap 기본 제공
- 이동 되돌리기 기본 제공
- 손패 3장을 기본화
- save schema hard break
- Jester id rename
