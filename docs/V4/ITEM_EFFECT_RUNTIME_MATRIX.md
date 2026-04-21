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
| `discard_glove` | Station 시작 시 보드 버림 +1 | `station_start` / `add_board_discard` | `applyStationStartItem` | `pendingHook` |
| `mulligan_sleeve` | Station 시작 시 손패 버림 +1 | `station_start` / `add_hand_discard` | `applyStationStartItem` | `pendingHook` |
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
| `deck_needle` | deck top 3 확인 후 1장 버림 | `use_battle` / `peek_deck_discard_one` | `useBattleItem` | `pendingHook` |
| `tile_polisher` | Station 첫 scored tile chips +20 | `first_scored_tile_each_station` / `chips_bonus` | `applyConfirmModifierItem` | `pendingHook` |
| `move_token` | 현재 Station 보드 이동 +1 | `use_battle` / `add_board_move` | `useBattleItem` | `applied` |
| `slide_wax` | 다음 board move bonus trigger 등록 | `use_battle` / `mark_next_board_move_bonus` | `useBattleItem` | `pendingHook` |
| `board_lift` | 다음 Station 보드 이동 +1 예약 | `station_start` / `add_board_move` | `applyStationStartItem` | `pendingHook` |
| `undo_seal` | 마지막 board move 1회 되돌리기 | `use_battle` / `undo_last_board_move` | `useBattleItem` | `pendingHook` |
| `organizer_glove` | Station 시작 시 보드 이동 +1 | `station_start` / `add_board_move` | `applyStationStartItem` | `pendingHook` |
| `travel_pouch` | 손패 한도 +1 | `inventory_capacity` / `increase_hand_size` | `applyInventoryCapacityItem` | `pendingHook` |
| `wide_grip` | 손패 한도 +1, 보드 버림 -1 | `station_start` / `increase_hand_size_with_discard_penalty` | `applyStationStartItem` | `pendingHook` |
| `grand_satchel` | 손패 한도 +2, 손패 버림 -1 | `station_start` / `increase_hand_size_with_discard_penalty` | `applyStationStartItem` | `pendingHook` |
| `market_compass` | market 진입 시 가장 싼 첫 offer 할인 -1 | `enter_market` / `discount_cheapest_first_offer` | `applyEnterMarketItem` | `pendingHook` |

## 현재 실제 적용 완료

- `board_scrap`: 보드 버림 +1, consume
- `hand_scrap`: 손패 버림 +1, consume
- `move_token`: 보드 이동 +1, consume
- `emergency_draw`: 손패가 비었을 때 1장 draw, consume

## 다음 구현 우선순위

1. `increase_hand_size*`: station start / inventory capacity에서 손패 한도 보정 연결
2. `undo_last_board_move`: move history 저장과 선택 UI 연결
3. `deck_needle`: `peek_deck_discard_one` 선택 UI와 deck 조작 API 필요
4. `next_confirm*`: 다음 confirm modifier 저장 state 필요
5. `station_start` / `enter_market` / `settlement`: run transition hook에 passive/equipment 적용 지점 연결 필요
6. `market_*`: market offer builder와 purchase/reroll command에 discount/modifier state 연결 필요
