# Item Effect Runtime Matrix

기준 데이터: `data/common/items_common_v1.json`

이 문서는 v1 Item 49개의 발동 효과를 `ItemEffectRuntime` 기준으로 정리한다.
상태 의미:

- `applied`: 현재 runtime에서 실제 상태 변경까지 적용된다.
- `pendingHook`: handler 함수와 연결 지점은 정해졌지만, 추가 UI/state/model 연결이 필요하다.

## Runtime Handler 기준

| Handler | 담당 timing |
|---|---|
| `useBattleItem` | `use_battle` |
| `applyMarketUseItem` | `use_market`, `use_market_if_gold_lte` |
| `applyMarketRerollItem` | `market_reroll` |
| `applyMarketBuyItem` | `market_buy`, `market_buy_if_category` |
| `applyStationStartItem` | `station_start` |
| `applyEnterMarketItem` | `enter_market`, `market_build_offers` |
| `applySettlementItem` | `settlement` |
| `applyConfirmModifierItem` | `next_confirm`, rank/color confirm variants, first/second confirm variants |
| `applyBossClearItem` | `boss_blind_clear_reward`, `boss_blind_clear_market` |
| `applyInventoryCapacityItem` | `inventory_capacity` |
| `applySellJesterItem` | `sell_jester` |
| `applyFailedConfirmItem` | `failed_confirm` |

## Effect Matrix

| Item | 실질 효과 | Timing / Op | Handler | 상태 |
|---|---|---|---|---|
| `reroll_token` | 다음 market reroll 비용 -1 | `market_reroll` / `discount_next_reroll` | `applyMarketRerollItem` | `pendingHook` |
| `coupon_stamp` | 다음 구매 가격 -2 | `market_buy` / `discount_next_purchase` | `applyMarketBuyItem` | `pendingHook` |
| `coin_cache` | Gold +3 | `use_market` / `gain_gold` | `applyMarketUseItem` | `pendingHook` |
| `board_scrap` | 현재 Station 보드 버림 +1 | `use_battle` / `add_board_discard` | `useBattleItem` | `applied` |
| `hand_scrap` | 현재 Station 손패 버림 +1 | `use_battle` / `add_hand_discard` | `useBattleItem` | `applied` |
| `chip_capsule` | 다음 confirm chips +25 | `next_confirm` / `chips_bonus` | `applyConfirmModifierItem` | `pendingHook` |
| `mult_capsule` | 다음 confirm mult +6 | `next_confirm` / `mult_bonus` | `applyConfirmModifierItem` | `pendingHook` |
| `line_polish` | 다음 confirm xmult x1.25 | `next_confirm` / `xmult_bonus` | `applyConfirmModifierItem` | `pendingHook` |
| `straight_oil` | 다음 Straight 이상 confirm chips +40 | `next_confirm_if_rank_at_least` / `chips_bonus` | `applyConfirmModifierItem` | `pendingHook` |
| `flush_powder` | 다음 Flush 이상 confirm mult +8 | `next_confirm_if_rank_at_least` / `mult_bonus` | `applyConfirmModifierItem` | `pendingHook` |
| `pair_splint` | 다음 Two Pair confirm chips +35 | `next_confirm_if_rank` / `chips_bonus` | `applyConfirmModifierItem` | `pendingHook` |
| `overlap_pin` | 다음 confirm overlap cap bonus +0.25 | `next_confirm` / `temporary_overlap_cap_bonus` | `applyConfirmModifierItem` | `pendingHook` |
| `emergency_draw` | 손패가 비었으면 즉시 1장 draw | `use_battle` / `draw_if_hand_empty` | `useBattleItem` | `applied` |
| `ledger_clip` | market 진입 시 Gold +1 | `enter_market` / `gain_gold` | `applyEnterMarketItem` | `pendingHook` |
| `discard_glove` | Station 시작 시 보드 버림 +1 | `station_start` / `add_board_discard` | `applyStationStartItem` | `applied` |
| `mulligan_sleeve` | Station 시작 시 손패 버림 +1 | `station_start` / `add_hand_discard` | `applyStationStartItem` | `applied` |
| `shop_lens` | item offer slot +1 | `market_build_offers` / `extra_item_offer_slot` | `applyEnterMarketItem` | `pendingHook` |
| `jester_hook` | Jester 판매 가격 +1 | `sell_jester` / `sell_price_bonus` | `applySellJesterItem` | `pendingHook` |
| `score_abacus` | Station 첫 confirm chips +30 | `first_confirm_each_station` / `chips_bonus` | `applyConfirmModifierItem` | `pendingHook` |
| `thin_caliper` | 작은 hand confirm mult +4 | `on_confirm_if_played_hand_size_lte` / `mult_bonus` | `applyConfirmModifierItem` | `pendingHook` |
| `stage_map` | boss blind clear reward Gold +1 | `boss_blind_clear_reward` / `gain_gold` | `applyBossClearItem` | `pendingHook` |
| `spare_pouch` | quick slot +1 | `inventory_capacity` / `extra_quick_slot` | `applyInventoryCapacityItem` | `pendingHook` |
| `merchant_stamp` | market 진입 시 첫 reroll 할인 -1 | `enter_market` / `discount_first_reroll` | `applyEnterMarketItem` | `pendingHook` |
| `safety_net` | Station 첫 failed confirm refund | `failed_confirm` / `refund_first_failed_confirm_each_station` | `applyFailedConfirmItem` | `pendingHook` |
| `coin_funnel` | 남은 보드 버림 보상 Gold +1씩 추가 | `settlement` / `board_discard_reward_bonus` | `applySettlementItem` | `pendingHook` |
| `hand_funnel` | 남은 손패 버림 보상 Gold +1씩 추가 | `settlement` / `hand_discard_reward_bonus` | `applySettlementItem` | `pendingHook` |
| `lucky_counter` | rare item weight +5 | `market_build_offers` / `rarity_weight_bonus` | `applyEnterMarketItem` | `pendingHook` |
| `echo_bell` | 두 번째 confirm에 첫 confirm 점수 10% 추가 | `second_confirm_each_station` / `add_percent_of_first_confirm_score` | `applyConfirmModifierItem` | `pendingHook` |
| `boss_trophy` | 다음 market Jester offer +1 | `boss_blind_clear_market` / `extra_jester_offer_next_market` | `applyBossClearItem` | `pendingHook` |
| `thin_wallet` | Gold 2 이하이면 Gold +5 | `use_market_if_gold_lte` / `gain_gold` | `applyMarketUseItem` | `pendingHook` |
| `trade_ticket` | item offer만 reroll | `use_market` / `reroll_item_offers_only` | `applyMarketUseItem` | `pendingHook` |
| `jester_invoice` | 다음 Jester 구매 가격 -4 | `market_buy_if_category` / `discount_next_purchase` | `applyMarketBuyItem` | `pendingHook` |
| `item_invoice` | 다음 Item 구매 가격 -4 | `market_buy_if_category` / `discount_next_purchase` | `applyMarketBuyItem` | `pendingHook` |
| `red_swatch` | 다음 confirm red tile마다 mult +2 | `next_confirm_per_tile_color` / `mult_bonus` | `applyConfirmModifierItem` | `pendingHook` |
| `blue_swatch` | 다음 confirm blue tile마다 mult +2 | `next_confirm_per_tile_color` / `mult_bonus` | `applyConfirmModifierItem` | `pendingHook` |
| `black_swatch` | 다음 confirm black tile마다 mult +2 | `next_confirm_per_tile_color` / `mult_bonus` | `applyConfirmModifierItem` | `pendingHook` |
| `yellow_swatch` | 다음 confirm yellow tile마다 mult +2 | `next_confirm_per_tile_color` / `mult_bonus` | `applyConfirmModifierItem` | `pendingHook` |
| `rank_chalk` | 반복 rank tile마다 chips +12 | `next_confirm_per_repeated_rank_tile` / `chips_bonus` | `applyConfirmModifierItem` | `pendingHook` |
| `deck_needle` | deck top 3 확인 후 1장 버림 | `use_battle` / `peek_deck_discard_one` | `useBattleItem` | `applied` |
| `tile_polisher` | Station 첫 scored tile chips +20 | `first_scored_tile_each_station` / `chips_bonus` | `applyConfirmModifierItem` | `pendingHook` |
| `move_token` | 현재 Station 보드 이동 +1 | `use_battle` / `add_board_move` | `useBattleItem` | `applied` |
| `slide_wax` | 다음 board move bonus trigger 등록 | `use_battle` / `mark_next_board_move_bonus` | `useBattleItem` | `pendingHook` |
| `board_lift` | 다음 Station 보드 이동 +1 예약 | `station_start` / `add_board_move` | `applyStationStartItem` | `applied` |
| `undo_seal` | 마지막 board move 1회 되돌리기 | `use_battle` / `undo_last_board_move` | `useBattleItem` | `applied` |
| `organizer_glove` | Station 시작 시 보드 이동 +1 | `station_start` / `add_board_move` | `applyStationStartItem` | `applied` |
| `travel_pouch` | 손패 한도 +1 | `inventory_capacity` / `increase_hand_size` | `applyInventoryCapacityItem` | `applied` |
| `wide_grip` | 손패 한도 +1, 보드 버림 -1 | `station_start` / `increase_hand_size_with_discard_penalty` | `applyStationStartItem` | `applied` |
| `grand_satchel` | 손패 한도 +2, 손패 버림 -1 | `station_start` / `increase_hand_size_with_discard_penalty` | `applyStationStartItem` | `applied` |
| `market_compass` | market 진입 시 가장 싼 첫 offer 할인 -1 | `enter_market` / `discount_cheapest_first_offer` | `applyEnterMarketItem` | `pendingHook` |

## 현재 실제 적용 완료

- `board_scrap`: 보드 버림 +1, consume
- `hand_scrap`: 손패 버림 +1, consume
- `move_token`: 보드 이동 +1, consume
- `emergency_draw`: 손패가 비었을 때 1장 draw, consume
- `deck_needle`: 덱 위 3장 중 선택한 1장을 버림, consume
- `discard_glove`: Station 시작 시 보드 버림 +1
- `mulligan_sleeve`: Station 시작 시 손패 버림 +1
- `board_lift` / `organizer_glove`: Station 시작 시 보드 이동 +1
- `travel_pouch`: Station 시작 read path에서 손패 한도 +1
- `wide_grip`: Station 시작 시 손패 한도 +1, 보드 버림 -1
- `grand_satchel`: Station 시작 시 손패 한도 +2, 손패 버림 -1
- `undo_seal`: 마지막 보드 이동을 되돌리고 이동 자원 1회 복원, consume

현재 실제 런타임 기준:

- 총 49개 중 `applied` 13개
- 남은 `pendingHook` 36개

## 공통 구현 묶음 플랜

남은 item은 개별 구현보다 같은 read/write 경계를 공유하는 묶음 단위로 처리한다.

### Group 1. Confirm Modifier Runtime

공통 기반: 다음/조건부 확정 보너스를 저장하는 modifier queue, confirm 시 평가/소비, save/restore.

대상 16개:

- 기본 다음 확정: `chip_capsule`, `mult_capsule`, `line_polish`
- 랭크 조건: `straight_oil`, `flush_powder`, `pair_splint`
- 색상/반복 랭크 조건: `red_swatch`, `blue_swatch`, `black_swatch`, `yellow_swatch`, `rank_chalk`
- 스테이션 내 순서 조건: `score_abacus`, `tile_polisher`, `echo_bell`
- 손패 크기/overlap 조건: `thin_caliper`, `overlap_pin`

공통 작업:

- `RummiRunProgress` 또는 battle session snapshot에 confirm modifier queue 추가
- modifier JSON save/restore/copySnapshot 추가
- `ItemEffectRuntime.applyConfirmModifierItem`에서 queue push
- confirm scoring path에서 조건 평가 후 chips/mult/xmult/overlap 보너스 적용
- first/second confirm, first scored tile, played hand size, repeated rank, tile color context 제공

### Group 2. Market Discount and Offer Modifier Runtime

공통 기반: market 진입/offer 생성/구매/reroll에서 쓰는 modifier state와 가격 계산 경계.

대상 9개:

- reroll/구매 할인: `reroll_token`, `coupon_stamp`, `merchant_stamp`, `jester_invoice`, `item_invoice`, `market_compass`
- offer 구성 변경: `shop_lens`, `lucky_counter`
- 부분 offer 갱신: `trade_ticket`

공통 작업:

- market modifier state 추가: next reroll discount, next purchase discount, category purchase discount, first reroll discount, cheapest first offer discount
- offer build config 추가: extra item slot, rarity weight bonus
- market facade에 할인 적용 전/후 가격과 modifier source 노출
- reroll/buy command에서 modifier 소비
- `trade_ticket`용 item offer only reroll command 또는 market runtime hook 추가

### Group 3. Direct Gold and Economy Hooks

공통 기반: 특정 scene/use timing에서 골드를 더하는 단순 economy effect.

대상 4개:

- 즉시/조건부 market 사용: `coin_cache`, `thin_wallet`
- market 진입: `ledger_clip`
- boss clear reward: `stage_map`

공통 작업:

- `applyMarketUseItem`, `applyEnterMarketItem`, `applyBossClearItem`의 `gain_gold` 처리
- `use_market_if_gold_lte` 조건 평가
- consume, toast/event, save 갱신

### Group 4. Settlement Reward Modifiers

공통 기반: 스테이션 종료 보상 계산에 남은 자원 기반 보너스를 더하는 hook.

대상 2개:

- `coin_funnel`, `hand_funnel`

공통 작업:

- settlement reward calculation에 item modifier context 전달
- 남은 보드/손패 버림 수 기반 추가 gold 계산
- settlement facade breakdown에 item bonus line 추가

### Group 5. Inventory and Sell Hooks

공통 기반: 인벤토리 capacity와 판매 가격 계산 read path.

대상 2개:

- `spare_pouch`, `jester_hook`

공통 작업:

- quick slot capacity read model 추가 및 acquisition/placement validation 반영
- jester sell price modifier hook 추가
- market/game facade에 변경된 capacity/가격 노출

### Group 6. Failed Confirm Hook

공통 기반: confirm 실패 이벤트를 감지하고 스테이션당 1회 refund.

대상 1개:

- `safety_net`

공통 작업:

- failed confirm event/result 경계 정의
- station-scoped consumed flag save/restore
- refund amount와 consume 정책 확정

### Group 7. Boss/Next Market Offer Hook

공통 기반: boss clear 후 다음 market offer 구성에 영향을 주는 delayed modifier.

대상 1개:

- `boss_trophy`

공통 작업:

- boss clear reward와 next market build 사이에 delayed market modifier 저장
- 다음 market jester offer slot +1 적용 후 소비

### Group 8. Board Move Follow-up Modifier

공통 기반: 보드 이동 이벤트 후 다음 scoring/trigger context에 플래그를 전달.

대상 1개:

- `slide_wax`

공통 작업:

- next board move bonus marker 저장
- board move 성공 시 marker를 station/battle scoring context로 이전
- 어떤 보너스가 발동되는지 수치/대상 확정 필요

## 다음 구현 우선순위

1. Group 1 `Confirm Modifier Runtime`: 16개를 가장 많이 줄일 수 있고 scoring 경계가 명확하다.
2. Group 2 `Market Discount and Offer Modifier Runtime`: market state/facade를 한 번에 정리한다.
3. Group 3 `Direct Gold and Economy Hooks`: 작은 단위라 Group 2 전후로 빠르게 닫을 수 있다.
4. Group 4 `Settlement Reward Modifiers`: settlement breakdown UX와 같이 처리한다.
5. Group 5-8: capacity/sell/failed confirm/boss delayed/board move follow-up처럼 각각 별도 hook이 필요한 단건 묶음으로 처리한다.
