# Current Card Catalog Table

> Source of truth table for currently used Jester, Q-Slot, Passive, Tool, and Gear cards.
> Generated from `data/common/jesters_common_phase5.json`, `data/common/items_common_v1.json`, and Korean translation files.

## Summary

- Jester: 43
- Item total: 92
- Q-Slot: 53
- Passive: 10
- Tool: 20
- Gear: 9

## Jester

| ID | 이름 | 희귀도 | 가격 | 트리거 | 효과 타입 | 조건 | 효과 |
|---|---|---:|---:|---|---|---|---|
| `abstract_jester` | 합창단 | common | 4G | passive | mult_bonus | other: owned_jester_count | 보유한 Jester마다 점수 +15%. |
| `blue_jester` | 남은 덱 | common | 5G | passive | chips_bonus | other: cards_remaining_in_deck | 덱에 남은 타일마다 칩 +2. |
| `bonus_jester` | 칩 고정핀 | common | 3G | passive | chips_bonus |  | 칩 +10. |
| `clever_jester` | 투페어 칩 | common | 4G | onScore | chips_bonus | two_pair: contains_two_pair | 투 페어 이상 점수 라인을 확정하면 칩 +80. |
| `crafty_jester` | 색상 칩 | common | 4G | onScore | chips_bonus | flush: contains_flush | 플러시 이상 점수 라인을 확정하면 칩 +80. |
| `crazy_jester` | 연속 호출 | common | 4G | onScore | mult_bonus | straight: contains_straight | 스트레이트 이상 점수 라인을 확정하면 점수 +60%. |
| `delayed_gratification` | 미사용 환급 | common | 4G | onRoundEnd | economy | other: unused_discards | 정산 시 남은 버림마다 골드 +2. |
| `devious_jester` | 연속 칩 | common | 4G | onScore | chips_bonus | straight: contains_straight | 스트레이트 이상 점수 라인을 확정하면 칩 +100. |
| `droll_jester` | 색상 호출 | common | 4G | onScore | mult_bonus | flush: contains_flush | 플러시 이상 점수 라인을 확정하면 점수 +50%. |
| `egg` | 예비 금화 | common | 4G | onRoundEnd | economy |  | 정산 시 골드 +3. |
| `even_steven` | 짝수 엔진 | common | 4G | onScore | mult_bonus | rank_scored: 2,4,6,8,10 | 점수 라인의 짝수 타일마다 점수 +20%. |
| `gluttonous_jester` | 검정 불씨 | common | 5G | onScore | mult_bonus | tile_color_scored: black | 점수 라인의 검은 타일마다 점수 +15%. |
| `golden_jester` | 금빛 주머니 | common | 6G | onRoundEnd | economy |  | 정산 시 골드 +4. |
| `greedy_jester` | 노랑 불씨 | common | 5G | onScore | mult_bonus | tile_color_scored: yellow | 점수 라인의 노란 타일마다 점수 +15%. |
| `half_jester` | 작은 손 | common | 5G | onPlay | mult_bonus | other: played_hand_size_lte_3 | 3장 이하 점수 라인을 확정하면 점수 +100%. |
| `jester` | 기본패 | common | 2G | passive | mult_bonus |  | 점수 +20%. |
| `jester_stencil` | 빈 자리 | common | 8G | passive | xmult_bonus | other: empty_jester_slots | 빈 Jester 슬롯마다 1배 보너스. |
| `jolly_jester` | 페어 호출 | common | 3G | onScore | mult_bonus | pair: pair_or_contains_pair | 원 페어 이상 점수 라인을 확정하면 점수 +40%. |
| `lusty_jester` | 빨강 불씨 | common | 5G | onScore | mult_bonus | tile_color_scored: red | 점수 라인의 빨간 타일마다 점수 +15%. |
| `mad_jester` | 투페어 호출 | common | 4G | onScore | mult_bonus | two_pair: contains_two_pair | 투 페어 이상 점수 라인을 확정하면 점수 +50%. |
| `mystic_summit` | 마지막 힘 | common | 5G | passive | mult_bonus | other: zero_discards_remaining | 남은 버림이 0이면 점수 +75%. |
| `odd_todd` | 홀수 엔진 | common | 4G | onScore | chips_bonus | rank_scored: 1,3,5,7,9 | 점수 라인의 홀수 타일마다 칩 +31. |
| `scary_face` | 그림 칩 | common | 4G | onScore | chips_bonus | face_card: jack_queen_king | 점수 라인의 11~13 타일마다 칩 +30. |
| `scholar` | 1번 장부 | common | 4G | onScore | other | rank_scored: ace | 점수 라인의 1 타일마다 칩 +20, 점수 +20%. |
| `sly_jester` | 페어 칩 | common | 3G | onScore | chips_bonus | pair: contains_pair | 원 페어 이상 점수 라인을 확정하면 칩 +50. |
| `smiley_face` | 그림 증폭 | common | 4G | onScore | mult_bonus | face_card: jack_queen_king | 점수 라인의 11~13 타일마다 점수 +25%. |
| `walkie_talkie` | 10과 4 | common | 4G | onScore | mult_bonus | rank_scored: 10,4 | 점수 라인의 10 또는 4 타일마다 점수 +20%. |
| `wily_jester` | 트리플 칩 | common | 4G | onScore | chips_bonus | four_of_a_kind: contains_three_of_a_kind | 트리플 이상 점수 라인을 확정하면 칩 +100. |
| `wrathful_jester` | 파랑 불씨 | common | 5G | onScore | mult_bonus | tile_color_scored: blue | 점수 라인의 파란 타일마다 점수 +15%. |
| `zany_jester` | 트리플 호출 | common | 4G | onScore | mult_bonus | three_of_a_kind: contains_three_of_a_kind | 트리플 이상 점수 라인을 확정하면 점수 +60%. |
| `ice_cream` | 줄어드는 칩 | uncommon | 7G | onPlay | stateful_growth | stateful: chips_decay_per_hand_played | 칩 +100. 확정할 때마다 칩 -5. |
| `popcorn` | 시한 증폭 | uncommon | 6G | onRoundEnd | stateful_growth | stateful: mult_decay | 점수 +100%. Station을 마칠 때마다 점수 -20%. |
| `ride_the_bus` | 무사고 연속 | uncommon | 6G | onScore | stateful_growth | face_card: consecutive_hands_without_scoring_face_card | 11~13 타일 없이 확정할 때마다 점수 +5%. |
| `banner` | 남은 버림 | rare | 7G | passive | chips_bonus | other: remaining_discards | 남은 버림마다 칩 +30. |
| `fibonacci` | 수열 보너스 | rare | 8G | onScore | mult_bonus | rank_scored: 1,2,3,5,8 | 점수 라인의 1, 2, 3, 5, 8 타일마다 점수 +40%. |
| `green_jester` | 기세 | rare | 8G | other | stateful_growth | stateful: hands_plus_discards_minus | 확정할 때마다 점수 +5%. 버릴 때마다 점수 -5%. |
| `gros_michel` | 숙성 부스터 | rare | 7G | passive | mult_bonus |  | 점수 +75%. |
| `supernova` | 런 기억 장치 | rare | 8G | passive | stateful_growth | stateful: times_current_hand_played_this_run | 이번 런에서 같은 족보를 확정한 횟수마다 점수 +5%. |
| `the_duo` | 페어 증폭 | rare | 8G | onScore | xmult_bonus | pair: pair_or_contains_pair | 원 페어 이상 점수 라인을 확정하면 점수 x2. |
| `the_family` | 4묶음 증폭 | rare | 8G | onScore | xmult_bonus | three_of_a_kind: contains_four_of_a_kind | 4묶음 이상 점수 라인을 확정하면 점수 x4. |
| `the_order` | 연속 증폭 | rare | 8G | onScore | xmult_bonus | straight: contains_straight | 스트레이트 이상 점수 라인을 확정하면 점수 x3. |
| `the_tribe` | 색상 증폭 | rare | 8G | onScore | xmult_bonus | flush: contains_flush | 플러시 이상 점수 라인을 확정하면 점수 x2. |
| `the_trio` | 트리플 증폭 | rare | 8G | onScore | xmult_bonus | three_of_a_kind: contains_three_of_a_kind | 트리플 이상 점수 라인을 확정하면 점수 x3. |

## Q-Slot

| ID | 이름 | 타입 | 희귀도 | 가격 | 판매가 | 사용 위치 | 효과 op | 효과 |
|---|---|---|---:|---:|---:|---|---|---|
| `black_swatch` | 검정 견본 | consumable | common | 4G | 2G | quickSlot | next_confirm_per_tile_color / mult_bonus | 다음 확정에서 검은 타일마다 점수 +10%. |
| `blue_swatch` | 파랑 견본 | consumable | common | 4G | 2G | quickSlot | next_confirm_per_tile_color / mult_bonus | 다음 확정에서 파란 타일마다 점수 +10%. |
| `board_scrap` | 보드 패스 | consumable | common | 4G | 2G | quickSlot | use_battle / add_board_discard | 이번 Station의 보드 버림 +1. |
| `chip_capsule` | 칩 충전구 | consumable | common | 4G | 2G | quickSlot | next_confirm / chips_bonus | 다음 확정에 칩 +25. |
| `coin_cache` | 금화 보관함 | consumable | common | 4G | 1G | inventory | use_market / gain_gold | 즉시 골드 +3. |
| `hand_scrap` | 손패 패스 | consumable | common | 4G | 2G | quickSlot | use_battle / add_hand_discard | 이번 Station의 손패 버림 +1. |
| `move_token` | 이동 칩 | consumable | common | 5G | 2G | quickSlot | use_battle / add_board_move | 이번 Station의 보드 이동 +1. |
| `mult_capsule` | 점수 충전구 | consumable | common | 4G | 2G | quickSlot | next_confirm / mult_bonus | 다음 확정에 점수 +30%. |
| `red_swatch` | 빨강 견본 | consumable | common | 4G | 2G | quickSlot | next_confirm_per_tile_color / mult_bonus | 다음 확정에서 빨간 타일마다 점수 +10%. |
| `yellow_swatch` | 노랑 견본 | consumable | common | 4G | 2G | quickSlot | next_confirm_per_tile_color / mult_bonus | 다음 확정에서 노란 타일마다 점수 +10%. |
| `battle_pouch` | 전투 주머니 | utility | uncommon | 7G | 3G | quickSlot | use_battle / increase_hand_size | 이번 Battle 동안 최대 손패 크기 +1. |
| `flush_powder` | 색상 준비 | consumable | uncommon | 5G | 2G | quickSlot | next_confirm_if_rank_at_least / mult_bonus | 다음 플러시 이상 확정에 점수 +40%. |
| `line_polish` | 점수 광택제 | consumable | uncommon | 6G | 3G | quickSlot | next_confirm / xmult_bonus | 다음 확정의 최종 점수가 x1.25가 됩니다. |
| `pair_splint` | 페어 고정대 | consumable | uncommon | 5G | 2G | quickSlot | next_confirm_if_rank / chips_bonus | 다음 투 페어 확정에 칩 +35. |
| `rank_chalk` | 숫자 분필 | consumable | uncommon | 6G | 3G | quickSlot | next_confirm_per_repeated_rank_tile / chips_bonus | 다음 확정에서 같은 숫자 타일마다 칩 +12. |
| `slide_wax` | 슬라이드 왁스 | consumable | uncommon | 6G | 3G | quickSlot | use_battle / mark_next_board_move_bonus | 다음 보드 이동이 슬라이드 보너스도 발동합니다. |
| `straight_oil` | 연속 준비 | consumable | uncommon | 5G | 2G | quickSlot | next_confirm_if_rank_at_least / chips_bonus | 다음 스트레이트 이상 확정에 칩 +40. |
| `deck_needle` | 덱 바늘 | utility | rare | 9G | 4G | quickSlot | use_battle / peek_deck_discard_one | 덱 맨 위 타일 3장을 보고 1장을 버립니다. |
| `emergency_draw` | 비상 드로우 | consumable | rare | 7G | 3G | quickSlot | use_battle / draw_if_hand_empty | 손패가 비어 있고 덱이 남아 있으면 즉시 타일 1장을 뽑습니다. |
| `overlap_pin` | 겹침 핀 | consumable | rare | 8G | 4G | quickSlot | next_confirm / temporary_overlap_cap_bonus | 다음 확정의 겹침 보너스 한도가 조금 증가합니다. |
| `undo_seal` | 되돌림 표식 | consumable | rare | 9G | 4G | quickSlot | use_battle / undo_last_board_move | 마지막 보드 이동을 1회 되돌립니다. |

## Passive

| ID | 이름 | 타입 | 희귀도 | 가격 | 판매가 | 사용 위치 | 효과 op | 효과 |
|---|---|---|---:|---:|---:|---|---|---|
| `stage_map` | Station 지도 | passive_relic | common | 6G | 3G | passiveRack | boss_blind_clear_reward / gain_gold | Boss 클리어 보상 골드 +1. |
| `coin_funnel` | 보드 환급 | passive_relic | uncommon | 9G | 4G | passiveRack | settlement / board_discard_reward_bonus | 정산 시 남은 보드 버림마다 보상 골드 +1. |
| `hand_funnel` | 손패 환급 | passive_relic | uncommon | 9G | 4G | passiveRack | settlement / hand_discard_reward_bonus | 정산 시 남은 손패 버림마다 보상 골드 +1. |
| `merchant_stamp` | 상점 도장 | passive_relic | uncommon | 8G | 4G | passiveRack | enter_market / discount_first_reroll | 상점에 들어갈 때 첫 리롤 비용이 1 줄어듭니다. |
| `safety_net` | 안전 장치망 | passive_relic | uncommon | 8G | 4G | passiveRack | expiry_guard / rescue_first_expiry_each_station | Station마다 런 종료 전투 막힘을 1회 막습니다. |
| `echo_bell` | 메아리 종 | passive_relic | rare | 12G | 6G | passiveRack | second_confirm_each_station / add_percent_of_first_confirm_score | 각 Station의 두 번째 확정에 첫 확정 점수의 10%를 더합니다. |
| `travel_pouch` | 여행 주머니 | passive_relic | rare | 11G | 5G | passiveRack | inventory_capacity / increase_hand_size | 최대 손패 크기 +1. |
| `boss_trophy` | Boss 전리품 | passive_relic | legendary | 15G | 7G | passiveRack | boss_blind_clear_market / extra_jester_offer_next_market | Boss를 클리어하면 다음 Market의 Jester 후보 +1. |
| `grand_satchel` | 큰 가방 | passive_relic | legendary | 16G | 8G | passiveRack | station_start / increase_hand_size_with_discard_penalty | 각 Station 시작 시 최대 손패 크기 +2, 손패 버림 -1. |
| `market_compass` | 상점 나침반 | passive_relic | legendary | 16G | 8G | passiveRack | enter_market / discount_cheapest_first_offer | Market에 들어갈 때 아이템/Jester 첫 후보 중 더 싼 쪽을 1골드 할인합니다. |

## Tool

| ID | 이름 | 타입 | 희귀도 | 가격 | 판매가 | 사용 위치 | 효과 op | 효과 |
|---|---|---|---:|---:|---:|---|---|---|
| `coupon_stamp` | 할인 도장 | utility | common | 4G | 2G | inventory | market_buy / discount_next_purchase | 다음 아이템 또는 Jester 구매 가격이 2 줄어듭니다. |
| `reroll_token` | 리롤 칩 | utility | common | 5G | 1G | inventory | market_reroll / discount_next_reroll | 다음 상점 리롤 비용이 1 줄어듭니다. |
| `board_lift` | 이동 예약 | utility | uncommon | 8G | 4G | inventory | station_start / add_board_move | 다음 Station에 보드 이동 +1을 예약합니다. |
| `flush_study` | 플러시 연구 | consumable | uncommon | 8G | 4G | inventory | use_market / add_hand_rank_progress | 상점에서 사용하면 플러시 성장 +1. |
| `straight_study` | 스트레이트 연구 | consumable | uncommon | 8G | 4G | inventory | use_market / add_hand_rank_progress | 상점에서 사용하면 스트레이트 성장 +1. |
| `thin_wallet` | 빈 지갑 | utility | uncommon | 7G | 2G | inventory | use_market_if_gold_lte / gain_gold | 골드가 3 이하일 때만 사용 가능. 골드 +5. |
| `trade_ticket` | 아이템 티켓 | utility | uncommon | 6G | 3G | inventory | use_market / reroll_item_offers_only | 아이템 후보만 다시 뽑습니다. |
| `triple_study` | 트리플 연구 | consumable | uncommon | 7G | 3G | inventory | use_market / add_hand_rank_progress | 상점에서 사용하면 트리플 성장 +1. |
| `two_pair_study` | 투 페어 연구 | consumable | uncommon | 6G | 3G | inventory | use_market / add_hand_rank_progress | 상점에서 사용하면 투 페어 성장 +1. |
| `four_kind_study` | 포카드 연구 | consumable | rare | 10G | 5G | inventory | use_market / add_hand_rank_progress | 상점에서 사용하면 포카드 성장 +1. |
| `full_house_study` | 풀하우스 연구 | consumable | rare | 9G | 4G | inventory | use_market / add_hand_rank_progress | 상점에서 사용하면 풀하우스 성장 +1. |
| `item_invoice` | 아이템 청구서 | utility | rare | 8G | 4G | inventory | market_buy_if_category / discount_next_purchase | 다음 아이템 구매 가격이 4 줄어듭니다. |
| `jester_invoice` | Jester 청구서 | utility | rare | 8G | 4G | inventory | market_buy_if_category / discount_next_purchase | 다음 Jester 구매 가격이 4 줄어듭니다. |
| `straight_flush_study` | 스티플 연구 | consumable | rare | 12G | 6G | inventory | use_market / add_hand_rank_progress | 상점에서 사용하면 스티플 성장 +1. |

## Gear

| ID | 이름 | 타입 | 희귀도 | 가격 | 판매가 | 사용 위치 | 효과 op | 효과 |
|---|---|---|---:|---:|---:|---|---|---|
| `discard_glove` | 보드 장갑 | equipment | common | 6G | 3G | equipped | station_start / add_board_discard | 각 Station 시작 시 보드 버림 +1. |
| `ledger_clip` | 장부 클립 | equipment | common | 5G | 2G | equipped | enter_market / gain_gold | 상점에 들어갈 때 골드 +1. |
| `mulligan_sleeve` | 손패 슬리브 | equipment | uncommon | 7G | 3G | equipped | station_start / add_hand_discard | 각 Station 시작 시 손패 버림 +1. |
| `organizer_glove` | 정리 장갑 | equipment | uncommon | 9G | 4G | equipped | station_start / add_board_move | 각 Station 시작 시 보드 이동 +1. |
| `jester_hook` | Jester 후크 | equipment | rare | 7G | 3G | equipped | sell_jester / sell_price_bonus | Jester 판매 가격 +1골드. |
| `score_abacus` | 점수 주판 | equipment | rare | 9G | 4G | equipped | first_confirm_each_station / chips_bonus | 각 Station의 첫 확정에 칩 +30. |
| `thin_caliper` | 짧은 줄 | equipment | rare | 9G | 4G | equipped | on_confirm_if_played_hand_size_lte / mult_bonus | 3장 이하 확정에 점수 +20%. |
| `wide_grip` | 넓은 손잡이 | equipment | rare | 11G | 5G | equipped | station_start / increase_hand_size_with_discard_penalty | 각 Station 시작 시 최대 손패 크기 +1, 보드 버림 -1. |
| `tile_polisher` | 타일 광택기 | equipment | legendary | 14G | 7G | equipped | first_scored_tile_each_station / chips_bonus | 각 Station에서 처음 점수화된 타일에 칩 +20. |

## Ritual Cards

> 아래 38종은 현재 `data/common/items_common_v1.json`에 들어간 검토용 catalog 항목이다. 2026-06-01 기준 Ritual 계열은 전투 즉시성/효과 전달 실패로 일반 마켓 pool에서 제외되어 실제 런에는 노출하지 않는다. Catalog, 번역, 이미지, debug fixture, runtime hook은 재설계용 자산으로만 유지한다.

| ID | 이름 | 희귀도 | 가격 | 위치 | Timing / op | 효과 |
|---|---|---:|---:|---|---|---|
| `line_memory` | 라인 기억 | uncommon | 7G | quickSlot | use_battle / add_hand_rank_progress_from_selected_line: growth | 점수 족보 선을 선택합니다. 해당 족보 성장 +1. |
| `prune_vendor` | 정리 상인 | uncommon | 8G | inventory | market_buy_if_category / discount_next_purchase | 다음 아이템 구매 가격이 1 줄어듭니다. |
| `seal_vendor` | 각인 상인 | uncommon | 8G | inventory | market_buy_if_category / discount_next_purchase | 다음 아이템 구매 가격이 1 줄어듭니다. |
| `line_pack_ticket` | 라인 팩 티켓 | rare | 10G | inventory | market_build_offers / extra_item_offer_slot | 다음 상점의 아이템 후보 슬롯 +1. |
| `ritual_lens` | 의식 렌즈 | uncommon | 7G | inventory | use_market / reroll_item_offers_only | 현재 아이템 후보를 다시 뽑고 의식 선택지를 노립니다. |
| `ritual_coupon` | 의식 쿠폰 | common | 5G | inventory | market_buy_if_category / discount_next_purchase | 다음 아이템 구매 가격이 2 줄어듭니다. |
| `bridge_rite` | 다리 의식 | rare | 12G | quickSlot | use_battle / ritual_line_effect: seal_bridge | 선택 타일에 다리 표식을 부여합니다. |
| `diagonal_rite` | 대각 의식 | rare | 10G | quickSlot | use_battle / ritual_line_effect: line_bonus_35 | 점수 족보 대각선을 선택합니다. 이번 확정에서 그 선 점수 +35%. |
| `center_rite` | 중심 의식 | uncommon | 8G | quickSlot | use_battle / ritual_line_effect: center_growth | 중앙을 포함한 점수 족보 선을 선택합니다. 해당 족보 성장 +1. |
| `corner_rite` | 모서리 의식 | uncommon | 8G | quickSlot | use_battle / ritual_line_effect: copy_endpoint | 모서리를 포함한 보드 선을 선택합니다. 끝 타일 1장을 덱에 복사합니다. |
| `cross_rite` | 교차 의식 | rare | 11G | quickSlot | use_battle / ritual_line_effect: line_bonus_25 | 교차 가능한 점수 족보 선을 선택합니다. 이번 확정에서 그 선 점수 +25%. |
| `sacrifice_line` | 제물 의식 | legendary | 15G | quickSlot | use_battle / ritual_line_effect: sacrifice_line | 보드 선 하나를 지웁니다. 타일 최대 2장을 덱에 복사하고 복사 타일 1장에 제거 표식을 남깁니다. |
| `deadwood_burn` | 마른가지 소각 | rare | 10G | quickSlot | use_battle / ritual_line_effect: burn_line | 보드 선 하나를 지웁니다. 그 선의 보드 타일을 제거하고 골드 +3. |
| `trim_rank` | 투페어 운명 | common | 7G | quickSlot | use_battle / ritual_line_effect: fate_two_pair_high | 보드 선을 선택합니다. 최고 숫자와 차순위 높은 숫자 기준 투페어 세트로 변환합니다. |
| `trim_color` | 색 가지치기 | uncommon | 8G | quickSlot | use_battle / ritual_line_effect: remove_same_color | 보드 선 안의 타일을 선택합니다. 같은 색 덱 타일 1장에 제거 표식을 남깁니다. |
| `line_pruner` | 하위 트리플 운명 | uncommon | 8G | quickSlot | use_battle / ritual_line_effect: fate_three_kind_low | 보드 선을 선택합니다. 차순위 낮은 숫자 트리플 세트로 변환합니다. 나머지 숫자는 트리플 숫자와 겹치지 않습니다. |
| `number_mask` | 로얄 운명 | legendary | 16G | quickSlot | use_battle / ritual_line_effect: fate_royal_flush | 보드 선을 선택합니다. 그 선의 최고 숫자 색상 기준으로 동색 9-13 로얄플러시 세트로 변환합니다. |
| `wild_thread` | 상행 스티플 운명 | rare | 14G | quickSlot | use_battle / ritual_line_effect: fate_straight_flush_high | 보드 선을 선택합니다. 그 선의 최고 숫자와 색상 기준으로 만들 수 있는 가장 높은 스티플 세트로 변환합니다. |
| `off_color_rite` | 하행 스티플 운명 | rare | 13G | quickSlot | use_battle / ritual_line_effect: fate_straight_flush_low | 보드 선을 선택합니다. 그 선의 최저 숫자와 색상 기준으로 만들 수 있는 가장 낮은 스티플 세트로 변환합니다. |
| `color_concord` | 상위 포카드 운명 | rare | 12G | quickSlot | use_battle / ritual_line_effect: fate_four_kind_high | 보드 선을 선택합니다. 그 선의 최고 숫자 기준 포카드 세트로 변환합니다. |
| `step_rite` | 하위 포카드 운명 | rare | 12G | quickSlot | use_battle / ritual_line_effect: fate_four_kind_low | 보드 선을 선택합니다. 그 선의 최저 숫자 기준 포카드 세트로 변환합니다. |
| `rank_concord` | 상위 풀하우스 운명 | rare | 12G | quickSlot | use_battle / ritual_line_effect: fate_full_house_high | 보드 선을 선택합니다. 최고 숫자 트리플과 차순위 높은 숫자 원페어 풀하우스 세트로 변환합니다. |
| `risk_seal` | 하위 풀하우스 운명 | rare | 12G | quickSlot | use_battle / ritual_line_effect: fate_full_house_low | 보드 선을 선택합니다. 차순위 낮은 숫자 트리플과 최고 숫자 원페어 풀하우스 세트로 변환합니다. |
| `anchor_seal` | 상위 플러시 운명 | uncommon | 10G | quickSlot | use_battle / ritual_line_effect: fate_flush_high | 보드 선을 선택합니다. 그 선의 최고 숫자 색상 기준 플러시 세트로 변환합니다. |
| `echo_seal` | 하위 플러시 운명 | uncommon | 10G | quickSlot | use_battle / ritual_line_effect: fate_flush_low | 보드 선을 선택합니다. 그 선의 최저 숫자 색상 기준 플러시 세트로 변환합니다. |
| `gold_seal_stamp` | 상행 스트레이트 운명 | uncommon | 9G | quickSlot | use_battle / ritual_line_effect: fate_straight_high | 보드 선을 선택합니다. 최고 숫자 기준 가장 높은 스트레이트 세트로 변환하고, 기준 타일 색상 하나를 다르게 둡니다. |
| `growth_seal` | 하행 스트레이트 운명 | uncommon | 9G | quickSlot | use_battle / ritual_line_effect: fate_straight_low | 보드 선을 선택합니다. 최저 숫자 기준 가장 낮은 스트레이트 세트로 변환하고, 기준 타일 색상 하나를 다르게 둡니다. |
| `line_seal_stamp` | 상위 트리플 운명 | uncommon | 8G | quickSlot | use_battle / ritual_line_effect: fate_three_kind_high | 보드 선을 선택합니다. 최고 숫자 트리플 세트로 변환합니다. 나머지 숫자는 트리플 숫자와 겹치지 않습니다. |
| `sealed_copy` | 각인 복사 | rare | 12G | quickSlot | use_battle / ritual_line_effect: copy_selected | 봉인 또는 강화된 보드 선 타일을 선택합니다. 복사본을 덱에 추가합니다. |
| `scarce_copy` | 희소석 복사 | rare | 10G | quickSlot | use_battle / ritual_line_effect: copy_selected | 보드 선 안의 타일을 선택합니다. 복사본을 덱에 추가합니다. |
| `color_echo` | 색 메아리 | uncommon | 8G | quickSlot | use_battle / ritual_line_effect: copy_color | 보드 선 안의 타일을 선택합니다. 같은 색의 무작위 숫자 타일을 덱에 추가합니다. |
| `rank_echo` | 숫자 메아리 | uncommon | 8G | quickSlot | use_battle / ritual_line_effect: copy_rank | 보드 선 안의 타일을 선택합니다. 같은 숫자의 무작위 색 타일을 덱에 추가합니다. |
| `edge_copy` | 끝점 복사 | common | 6G | quickSlot | use_battle / ritual_line_effect: copy_selected | 보드 선의 끝 타일을 선택합니다. 복사본을 덱에 추가합니다. |
| `keystone_copy` | 중심석 복사 | uncommon | 8G | quickSlot | use_battle / ritual_line_effect: copy_center | 보드 선 하나를 선택합니다. 중앙 타일을 덱에 추가합니다. |
| `boss_memory` | 보스 기억 | rare | 11G | quickSlot | use_battle / ritual_line_effect: boss_growth | 보스전에서 점수 족보 선을 선택합니다. 해당 족보 성장 +2. |
| `thin_memory` | 얇은 기억 | common | 6G | quickSlot | use_battle / ritual_line_effect: thin_growth | 타일 3-4개의 점수 족보 선을 선택합니다. 해당 족보 성장 +1, 이번 확정에서 그 선 점수 -10%. |
| `cross_memory` | 교차 기억 | rare | 10G | quickSlot | use_battle / ritual_line_effect: growth_marker | 교차 가능한 점수 족보 선을 선택합니다. 해당 족보 성장 +1 및 교차 기억 표식 부여. |
| `minor_memory` | 잔상 기억 | rare | 9G | quickSlot | use_battle / ritual_line_effect: growth_risk | 점수 족보 선을 선택합니다. 해당 족보 성장 +2, 이번 확정에서 그 선 점수 -25%. |

## Notes

- `Q-Slot`, `Passive`, `Tool`, `Gear` 분류는 현재 item `slotHint`/`placement` 기준이다.
- 이 문서는 사람이 읽는 현행 카탈로그 표다. 실제 런타임 원본은 JSON catalog와 번역 파일이다.
- Ritual/Board-Line 계열 38종은 현재 런타임 카탈로그다. 세부 정책 source는 `ITEM_POLICY_CLEANUP_AUDIT.md`, 실제 runtime hook 상태는 `ITEM_EFFECT_RUNTIME_MATRIX.md`다.
