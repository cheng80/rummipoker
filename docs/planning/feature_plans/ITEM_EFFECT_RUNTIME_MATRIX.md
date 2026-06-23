# Item Effect Runtime Matrix

> GCSE role: `Execution`
> Source of truth: Item effect runtime 연결 상태와 다음 구현 묶음.

기준 데이터: `data/common/items_common_v1.json`

현재 기준:

- Item catalog: 91개
- 기존 v1 baseline: 54개
- Ritual/Item 확장 계열: 37개
- 전투 보드 선 선택형 `ritual_line_effect`는 31장
- Fate 변환 16종
- `applied`: 91개
- `pendingHook`: 0개

이 문서는 v1 Item catalog의 발동 효과를 `ItemEffectRuntime` 기준으로 정리한다.
Item 효과의 화면 연출 계약은 `docs/planning/feature_plans/ITEM_PRESENTATION_CONTRACT_REVIEW.md`를 따른다.
과거 소모품/바우처 장기 확장 reference에서 현재 필요한 원칙은 이 문서에 승격했다.
아이템의 발동/대상/결과 연출 coverage는 `docs/planning/feature_plans/ANIMATION_EFFECTS_PLAN.md`와 함께 본다.
이 문서의 `applied`는 런타임 상태 변경과 소모 정책이 연결됐다는 뜻이며, 플레이어가 효과를 충분히 이해할 수 있는 UX까지 완료됐다는 뜻은 아니다.

## 운명/의식 Runtime 분류

| 분류 | 수 | Runtime action |
|---|---:|---|
| 족보 변환형 운명 | 16 | `fate_two_pair_high`, `fate_three_kind_low`, `fate_three_kind_high`, `fate_four_kind_high`, `fate_four_kind_low`, `fate_full_house_high`, `fate_full_house_low`, `fate_flush_house`, `fate_flush_five`, `fate_flush_high`, `fate_flush_low`, `fate_straight_high`, `fate_straight_low`, `fate_straight_flush_high`, `fate_straight_flush_low`, `fate_royal_flush` |
| 성장/점수/표식/위치 의식 | 6 Ritual + `line_memory` 별도 | Ritual 활성: `seal_bridge`, `line_bonus_35`, `center_growth`, `copy_endpoint`, `line_bonus_25`, `growth_marker`. `line_memory`는 `ritual_line_effect`가 아닌 별도 선 성장형 quickSlot이다. 삭제된 기억 의식 3종의 전용 action은 runtime에서 제거했다. |
| 덱 복사/메아리 | 6 | `copy_selected`, `copy_color`, `copy_rank`, `copy_center` |
| 제거/소각/제물 | 3 | `prune_line_to_color`, `burn_line`, `sacrifice_line` |

족보 변환형 운명은 override 점수 보정이 아니라 보드 선 타일을 실제 세트로 치환한다. `number_mask`는 선택 줄에 1 타일이 있으면 1의 색상, 없으면 최고 숫자 색상을 기준으로 `10-11-12-13-1` 로얄플러시 세트를 만든다.
badge, notice, toast, label만 추가한 항목은 "표시/피드백 1차"로만 기록한다. 실제 연출은 `ANIMATION_EFFECTS_PLAN.md`의 아이템 source -> target/목적지 -> result 기준으로 별도 판단/구현한다.
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
| `applyExpiryGuardItem` | `expiry_guard` |

## Effect Matrix

| Item | 실질 효과 | Timing / Op | Handler | 상태 |
|---|---|---|---|---|
| `reroll_token` | 다음 market reroll 무료 | `market_reroll` / `free_next_reroll` | `applyMarketRerollItem` | `applied` |
| `coupon_stamp` | 다음 구매 가격 -2 | `market_buy` / `discount_next_purchase` | `applyMarketBuyItem` | `applied` |
| `coin_cache` | Gold +3 | `use_market` / `gain_gold` | `applyMarketUseItem` | `applied` |
| `two_pair_study` | 투 페어 성장 +1 | `use_market` / `add_hand_rank_progress` | `applyMarketUseItem` | `applied` |
| `triple_study` | 트리플 성장 +1 | `use_market` / `add_hand_rank_progress` | `applyMarketUseItem` | `applied` |
| `straight_study` | 스트레이트 성장 +1 | `use_market` / `add_hand_rank_progress` | `applyMarketUseItem` | `applied` |
| `flush_study` | 플러시 성장 +1 | `use_market` / `add_hand_rank_progress` | `applyMarketUseItem` | `applied` |
| `full_house_study` | 풀하우스 성장 +1 | `use_market` / `add_hand_rank_progress` | `applyMarketUseItem` | `applied` |
| `four_kind_study` | 포카드 성장 +1 | `use_market` / `add_hand_rank_progress` | `applyMarketUseItem` | `applied` |
| `straight_flush_study` | 스티플 성장 +1 | `use_market` / `add_hand_rank_progress` | `applyMarketUseItem` | `applied` |
| `board_scrap` | 현재 Station 보드 버림 +1 | `use_battle` / `add_board_discard` | `useBattleItem` | `applied` |
| `hand_scrap` | 현재 Station 손패 버림 +1 | `use_battle` / `add_hand_discard` | `useBattleItem` | `applied` |
| `chip_capsule` | 다음 confirm chips +25 | `next_confirm` / `chips_bonus` | `applyConfirmModifierItem` | `applied` |
| `mult_capsule` | 다음 confirm mult +6 | `next_confirm` / `mult_bonus` | `applyConfirmModifierItem` | `applied` |
| `line_polish` | 다음 confirm xmult x1.25 | `next_confirm` / `xmult_bonus` | `applyConfirmModifierItem` | `applied` |
| `straight_oil` | 다음 Straight 이상 confirm chips +40 | `next_confirm_if_rank_at_least` / `chips_bonus` | `applyConfirmModifierItem` | `applied` |
| `flush_powder` | 다음 Flush 이상 confirm mult +8 | `next_confirm_if_rank_at_least` / `mult_bonus` | `applyConfirmModifierItem` | `applied` |
| `pair_splint` | 다음 Two Pair confirm chips +35 | `next_confirm_if_rank` / `chips_bonus` | `applyConfirmModifierItem` | `applied` |
| `overlap_pin` | 다음 confirm overlap cap bonus +0.25 | `next_confirm` / `temporary_overlap_cap_bonus` | `applyConfirmModifierItem` | `applied` |
| `emergency_draw` | 손패가 비었으면 덱 소모 없이 무작위 타일 1장 생성 | `use_battle` / `draw_if_hand_empty` | `useBattleItem` | `applied` |
| `ledger_clip` | market 진입 시 Gold +1 | `enter_market` / `gain_gold` | `applyEnterMarketItem` | `applied` |
| `discard_glove` | Station 시작 시 보드 버림 +1 | `station_start` / `add_board_discard` | `applyStationStartItem` | `applied` |
| `mulligan_sleeve` | Station 시작 시 손패 버림 +1 | `station_start` / `add_hand_discard` | `applyStationStartItem` | `applied` |
| `jester_hook` | Jester 판매 가격 +1 | `sell_jester` / `sell_price_bonus` | `applySellJesterItem` | `applied` |
| `score_abacus` | Station 첫 confirm chips +30 | `first_confirm_each_station` / `chips_bonus` | `applyConfirmModifierItem` | `applied` |
| `thin_caliper` | 작은 hand confirm mult +4 | `on_confirm_if_played_hand_size_lte` / `mult_bonus` | `applyConfirmModifierItem` | `applied` |
| `stage_map` | boss blind clear reward Gold +1 | `boss_blind_clear_reward` / `gain_gold` | `applyBossClearItem` | `applied` |
| `merchant_stamp` | market 진입 시 첫 reroll 할인 -1 | `enter_market` / `discount_first_reroll` | `applyEnterMarketItem` | `applied` |
| `safety_net` | Station 첫 전투 종료 위기 방어 | `expiry_guard` / `rescue_first_expiry_each_station` | `applyExpiryGuardItem` | `applied` |
| `coin_funnel` | 남은 보드 버림 보상 Gold +1씩 추가 | `settlement` / `board_discard_reward_bonus` | `applySettlementItem` | `applied` |
| `hand_funnel` | 남은 손패 버림 보상 Gold +1씩 추가 | `settlement` / `hand_discard_reward_bonus` | `applySettlementItem` | `applied` |
| `echo_bell` | 두 번째 confirm에 첫 confirm 점수 10% 추가 | `second_confirm_each_station` / `add_percent_of_first_confirm_score` | `applyConfirmModifierItem` | `applied` |
| `boss_trophy` | 다음 market Jester offer +1 | `boss_blind_clear_market` / `extra_jester_offer_next_market` | `applyBossClearItem` | `applied` |
| `thin_wallet` | Gold 3 이하이면 Gold +5 | `use_market_if_gold_lte` / `gain_gold` | `applyMarketUseItem` | `applied` |
| `trade_ticket` | item offer만 reroll | `use_market` / `reroll_item_offers_only` | `applyMarketUseItem` | `applied` |
| `jester_invoice` | 다음 Jester 구매 가격 -4 | `market_buy_if_category` / `discount_next_purchase` | `applyMarketBuyItem` | `applied` |
| `item_invoice` | 다음 Item 구매 가격 -4 | `market_buy_if_category` / `discount_next_purchase` | `applyMarketBuyItem` | `applied` |
| `red_swatch` | 다음 confirm red tile마다 mult +2 | `next_confirm_per_tile_color` / `mult_bonus` | `applyConfirmModifierItem` | `applied` |
| `blue_swatch` | 다음 confirm blue tile마다 mult +2 | `next_confirm_per_tile_color` / `mult_bonus` | `applyConfirmModifierItem` | `applied` |
| `black_swatch` | 다음 confirm black tile마다 mult +2 | `next_confirm_per_tile_color` / `mult_bonus` | `applyConfirmModifierItem` | `applied` |
| `yellow_swatch` | 다음 confirm yellow tile마다 mult +2 | `next_confirm_per_tile_color` / `mult_bonus` | `applyConfirmModifierItem` | `applied` |
| `rank_chalk` | 반복 rank tile마다 chips +12 | `next_confirm_per_repeated_rank_tile` / `chips_bonus` | `applyConfirmModifierItem` | `applied` |
| `deck_needle` | deck top 3 확인 후 1장 버림 | `use_battle` / `peek_deck_discard_one` | `useBattleItem` | `applied` |
| `tile_polisher` | Station 첫 scored tile chips +20 | `first_scored_tile_each_station` / `chips_bonus` | `applyConfirmModifierItem` | `applied` |
| `move_token` | 현재 Station 보드 이동 +1 | `use_battle` / `add_board_move` | `useBattleItem` | `applied` |
| `slide_wax` | 다음 board move bonus trigger 등록 | `use_battle` / `mark_next_board_move_bonus` | `useBattleItem` | `applied` |
| `board_lift` | 다음 Station 보드 이동 +1 예약 | `station_start` / `add_board_move` | `applyStationStartItem` | `applied` |
| `undo_seal` | 마지막 board move 1회 되돌리기 | `use_battle` / `undo_last_board_move` | `useBattleItem` | `applied` |
| `organizer_glove` | Station 시작 시 보드 이동 +1 | `station_start` / `add_board_move` | `applyStationStartItem` | `applied` |
| `travel_pouch` | 손패 한도 +1 | `inventory_capacity` / `increase_hand_size` | `applyInventoryCapacityItem` | `applied` |
| `wide_grip` | 손패 한도 +1, 보드 버림 -1 | `station_start` / `increase_hand_size_with_discard_penalty` | `applyStationStartItem` | `applied` |
| `grand_satchel` | 손패 한도 +2, 손패 버림 -1 | `station_start` / `increase_hand_size_with_discard_penalty` | `applyStationStartItem` | `applied` |
| `market_compass` | market 진입 시 가장 싼 첫 offer 할인 -1 | `enter_market` / `discount_cheapest_first_offer` | `applyEnterMarketItem` | `applied` |
| `prune_vendor` | 다음 item 구매 가격 -1 | `market_buy_if_category` / `discount_next_purchase` | `applyMarketBuyItem` | `applied` |
| `seal_vendor` | 다음 item 구매 가격 -1 | `market_buy_if_category` / `discount_next_purchase` | `applyMarketBuyItem` | `applied` |
| `line_pack_ticket` | 다음 market item offer slot +1 | `market_build_offers` / `extra_item_offer_slot` | `applyEnterMarketItem` | `applied` |
| `ritual_lens` | item offer reroll | `use_market` / `reroll_item_offers_only` | `applyMarketUseItem` | `applied` |
| `ritual_coupon` | 다음 item 구매 가격 -2 | `market_buy_if_category` / `discount_next_purchase` | `applyMarketBuyItem` | `applied` |
| `bridge_rite` | 선택 보드 선 타일에 bridge seal | `use_battle` / `ritual_line_effect: seal_bridge` | `useBattleItemOnLine` | `applied` |
| `diagonal_rite` | 선택 점수 대각선 score bonus | `use_battle` / `ritual_line_effect: line_bonus_35` | `useBattleItemOnLine` | `applied` |
| `center_rite` | 중앙 포함 점수 족보 성장 +1 | `use_battle` / `ritual_line_effect: center_growth` | `useBattleItemOnLine` | `applied` |
| `corner_rite` | 모서리 포함 보드 선 끝 타일 복사 | `use_battle` / `ritual_line_effect: copy_endpoint` | `useBattleItemOnLine` | `applied` |
| `cross_rite` | 교차 가능한 점수 족보 score bonus | `use_battle` / `ritual_line_effect: line_bonus_25` | `useBattleItemOnLine` | `applied` |
| `sacrifice_line` | 보드 선 제거, 타일 2장 덱 맨 위 복사 | `use_battle` / `ritual_line_effect: sacrifice_line` | `useBattleItemOnLine` | `applied` |
| `deadwood_burn` | 보드 선 제거, Gold +3 | `use_battle` / `ritual_line_effect: burn_line` | `useBattleItemOnLine` | `applied` |
| `trim_rank` | 최고/차순위 높은 숫자 기준 Two Pair 세트로 보드 선 변환 | `use_battle` / `ritual_line_effect: fate_two_pair_high` | `useBattleItemOnLine` | `applied` |
| `trim_color` | 선택 색 외 타일 제거, 같은 색 타일 덱 맨 위 보충 | `use_battle` / `ritual_line_effect: prune_line_to_color` | `useBattleItemOnLine` | `applied` |
| `line_pruner` | 차순위 낮은 숫자 기준 Three of a Kind 세트로 보드 선 변환 | `use_battle` / `ritual_line_effect: fate_three_kind_low` | `useBattleItemOnLine` | `applied` |
| `number_mask` | 1 타일 우선, 없으면 최고 숫자 색상 기준 Royal Straight Flush 세트로 보드 선 변환 | `use_battle` / `ritual_line_effect: fate_royal_flush` | `useBattleItemOnLine` | `applied` |
| `wild_thread` | 최고 숫자/색상 기준 높은 Straight Flush 세트로 보드 선 변환 | `use_battle` / `ritual_line_effect: fate_straight_flush_high` | `useBattleItemOnLine` | `applied` |
| `off_color_rite` | 최저 숫자/색상 기준 낮은 Straight Flush 세트로 보드 선 변환 | `use_battle` / `ritual_line_effect: fate_straight_flush_low` | `useBattleItemOnLine` | `applied` |
| `color_concord` | 최고 숫자 기준 Four of a Kind 세트로 보드 선 변환 | `use_battle` / `ritual_line_effect: fate_four_kind_high` | `useBattleItemOnLine` | `applied` |
| `step_rite` | 최저 숫자 기준 Four of a Kind 세트로 보드 선 변환 | `use_battle` / `ritual_line_effect: fate_four_kind_low` | `useBattleItemOnLine` | `applied` |
| `rank_concord` | 최고 숫자 triple + 차순위 높은 숫자 pair Full House 세트로 보드 선 변환 | `use_battle` / `ritual_line_effect: fate_full_house_high` | `useBattleItemOnLine` | `applied` |
| `fate_full_house_low` | 차순위 낮은 숫자 triple + 최고 숫자 pair Full House 세트로 보드 선 변환 | `use_battle` / `ritual_line_effect: fate_full_house_low` | `useBattleItemOnLine` | `applied` |
| `flush_house_fate` | 최고 숫자 triple + 차순위 높은 숫자 pair를 같은 색으로 만드는 Flush House 세트로 보드 선 변환 | `use_battle` / `ritual_line_effect: fate_flush_house` | `useBattleItemOnLine` | `applied` |
| `flush_five_fate` | 최고 숫자 5장을 같은 색으로 만드는 Flush Five 세트로 보드 선 변환 | `use_battle` / `ritual_line_effect: fate_flush_five` | `useBattleItemOnLine` | `applied` |
| `fate_flush_high` | 최고 숫자 색상 기준 Flush 세트로 보드 선 변환 | `use_battle` / `ritual_line_effect: fate_flush_high` | `useBattleItemOnLine` | `applied` |
| `fate_flush_low` | 최저 숫자 색상 기준 Flush 세트로 보드 선 변환 | `use_battle` / `ritual_line_effect: fate_flush_low` | `useBattleItemOnLine` | `applied` |
| `fate_straight_high` | 최고 숫자 기준 높은 Straight 세트로 보드 선 변환, 기준 타일 off-color | `use_battle` / `ritual_line_effect: fate_straight_high` | `useBattleItemOnLine` | `applied` |
| `fate_straight_low` | 최저 숫자 기준 낮은 Straight 세트로 보드 선 변환, 기준 타일 off-color | `use_battle` / `ritual_line_effect: fate_straight_low` | `useBattleItemOnLine` | `applied` |
| `fate_three_kind_high` | 최고 숫자 기준 Three of a Kind 세트로 보드 선 변환 | `use_battle` / `ritual_line_effect: fate_three_kind_high` | `useBattleItemOnLine` | `applied` |
| `sealed_copy` | 봉인/강화 scoringTile 복사, 다음 draw 후보로 덱 맨 위 추가 | `use_battle` / `ritual_line_effect: copy_selected` | `useBattleItemOnLine` | `applied` |
| `scarce_copy` | scoringTile 복사, 다음 draw 후보로 덱 맨 위 추가 | `use_battle` / `ritual_line_effect: copy_selected` | `useBattleItemOnLine` | `applied` |
| `color_echo` | 선택 scoringTile과 같은 색 무작위 숫자 타일을 덱 맨 위 추가 | `use_battle` / `ritual_line_effect: copy_color` | `useBattleItemOnLine` | `applied` |
| `rank_echo` | 선택 scoringTile과 같은 숫자 무작위 색 타일을 덱 맨 위 추가 | `use_battle` / `ritual_line_effect: copy_rank` | `useBattleItemOnLine` | `applied` |
| `edge_copy` | 보드 선 양끝 scoringTile 복사, 다음 draw 후보로 덱 맨 위 추가 | `use_battle` / `ritual_line_effect: copy_selected` | `useBattleItemOnLine` | `applied` |
| `keystone_copy` | 보드 선 중앙 scoringTile 복사, 다음 draw 후보로 덱 맨 위 추가 | `use_battle` / `ritual_line_effect: copy_center` | `useBattleItemOnLine` | `applied` |
| `line_memory` | 선택한 점수 족보 선 성장 +1 | `use_battle` / `add_hand_rank_progress_from_selected_line` | `useBattleItemOnLine` | `applied` |
| `cross_memory` | 선택한 교차 점수 타일에 표식, 이후 겹친 줄 정산 시 추가 족보 성장 | `use_battle` / `ritual_line_effect: growth_marker` | `useBattleItemOnLine` | `applied` |

## 현재 실제 적용 완료

- `board_scrap`: 보드 버림 +1, consume
- `hand_scrap`: 손패 버림 +1, consume
- `move_token`: 보드 이동 +1, consume
- `slide_wax`: 다음 성공한 보드 이동에 slide bonus trigger marker 저장/소비, consume
- `emergency_draw`: 손패가 비었을 때 덱 소모 없이 무작위 타일 1장 생성, consume
- `deck_needle`: 덱 위 3장 중 선택한 1장을 버림, consume
- `discard_glove`: Station 시작 시 보드 버림 +1
- `mulligan_sleeve`: Station 시작 시 손패 버림 +1
- `board_lift` / `organizer_glove`: Station 시작 시 보드 이동 +1
- `travel_pouch`: Station 시작 read path에서 손패 한도 +1
- `wide_grip`: Station 시작 시 손패 한도 +1, 보드 버림 -1
- `grand_satchel`: Station 시작 시 손패 한도 +2, 손패 버림 -1
- `undo_seal`: 마지막 보드 이동을 되돌리고 이동 자원 1회 복원, consume
- Confirm modifier queue/save/scoring hook:
  `chip_capsule`, `mult_capsule`, `line_polish`, `straight_oil`, `flush_powder`, `pair_splint`,
  `overlap_pin`, `score_abacus`, `thin_caliper`, `echo_bell`, `red_swatch`, `blue_swatch`,
  `black_swatch`, `yellow_swatch`, `rank_chalk`, `tile_polisher`
- Market modifier state/save/facade hook:
  `reroll_token`, `coupon_stamp`, `merchant_stamp`, `jester_invoice`, `item_invoice`,
  `market_compass`, `trade_ticket`
- 삭제: `shop_lens`는 Item 후보 수 증가가 유저에게 와닿지 않고 source-target-result 연출 없이 후보 수만 바꾸는 효과라 카탈로그에서 제거했다. `extra_item_offer_slot` handler는 과거 저장값/테스트 호환을 위해 남기되 신규 catalog item으로 노출하지 않는다.
- 삭제: `lucky_counter`는 rarity weight만 바꾸고 화면 피드백이 약해 현재 카탈로그에서 제거했다.
- 삭제: `spare_pouch`는 S2 Boss Quick Slot 해금과 겹치는 보유 슬롯 확장 아이템이라 카탈로그에서 제거했다. Quick/Passive/Jester 보유 슬롯 확장은 Boss 진행 보상 전용 축으로 둔다.
- Direct economy hook:
  `coin_cache`, `thin_wallet`, `ledger_clip`, `stage_map`
- Planet-like direct hand-rank growth hook:
  `two_pair_study`, `triple_study`, `straight_study`, `flush_study`, `full_house_study`,
  `four_kind_study`, `straight_flush_study`
- Boss/next market offer hook:
  `boss_trophy`
- Settlement reward modifier hook:
  `coin_funnel`, `hand_funnel`
- Inventory and sell hook:
  `travel_pouch`, `jester_hook`
- Expiry guard hook:
  `safety_net`

현재 실제 런타임 기준:

- 총 91개 중 `applied` 91개
- 남은 `pendingHook` 0개

Ritual 계열의 다음 검증은 runtime hook 존재 여부가 아니라 UX/밸런스다. 특히 line choice dialog, result communication, run info/log visibility, market pool 계열 정체성, 강제 판정/고위험 카드 가격과 출현률을 별도 확인한다.

## Post-contest 정책 재검토 리스트

2026-05-15 post-contest 안정화 첫 작업으로 손패 최대치 4장 이상 UI/효과 버그를 닫았다.

적용 정책:

- 손패 최대치는 현재 전투 UI 기준 5장이다.
- `battle_pouch`, `travel_pouch`, `wide_grip`, `grand_satchel` 같은 손패 증가 효과는 5장까지만 적용한다.
- 이미 5장이면 `손패 최대치입니다.`로 실패 처리하고 아이템/효과를 소모하지 않는다.
- 손패 증가와 패널티가 묶인 `wide_grip`, `grand_satchel`은 손패 증가가 실패하면 보드/손패 버림 패널티만 적용하지 않는다.
- 전투 자원 증가 상한은 보드 버림 6회, 손패 버림 4회, 보드 이동 5회다.
- `board_scrap`, `hand_scrap`, `move_token`, `discard_glove`, `mulligan_sleeve`, `board_lift`, `organizer_glove`는 상한 도달 시 실패 처리하고 아이템/효과를 소모하지 않는다.
- 자원 증가가 일부만 적용 가능하면 상한까지만 올리고 실제 증가량만 이벤트에 남긴다.
- Quick/Passive/Jester 보유 슬롯 확장은 Boss 진행 보상 전용 축으로 둔다.
- `spare_pouch`는 S2 Boss Quick Slot 해금과 겹쳐 삭제했다.
- Market 후보 슬롯은 현재 Jester/Item 각각 4개가 상한이다.
- `shop_lens`는 유저가 효과를 체감하기 어렵고 source-target-result 연출 없이 후보 수만 바꾸는 효과라 삭제했다. `boss_trophy`는 다음 Market Jester 후보 슬롯을 4개까지만 예약한다.

다음 재검토 후보:

| 묶음 | 후보 | 리스크 | 다음 판단 |
|---|---|---|---|
| 자원 상한/no-op | `board_scrap`, `hand_scrap`, `discard_glove`, `mulligan_sleeve`, `move_token`, `board_lift`, `organizer_glove` | 완료: board discard / hand discard / board move는 런타임 상한과 실패/미소모 정책을 갖는다. 남은 표시는 `N/base` 형태의 현재 UI 의미를 별도 리팩터링 때 재검토한다. | 상한 정책은 닫고, 표시 최대치 동기화는 resource model 리팩터링 후보로 넘긴다. |
| 슬롯 상한/no-op | Boss 보유 슬롯 해금 | 완료: Quick/Passive/Jester 보유 슬롯 확장은 Boss 진행 보상 전용 축으로 두고, 중복되는 `spare_pouch`는 삭제했다. | 보유 슬롯 확장 아이템은 재도입하지 않는다. |
| offer/market 상한 | `boss_trophy`, `market_compass` | 완료: `shop_lens`는 삭제했다. `boss_trophy`는 후보 슬롯 수 4개 상한, 실제 적용량 이벤트, 적용 Market의 Jester 후보 영역 `트로피 +N` 표시를 갖는다. `market_compass`는 현재 Market의 보이는 후보 1개에만 `나침반` 할인 배지를 붙이고 0G 후보는 건너뛴다. `lucky_counter`는 삭제했다. | 상한/표시 1차는 닫고, 가격/가치 이상 후보로 이동한다. |
| 조건부 사용 no-op | `slide_wax`, `undo_seal`, `emergency_draw`, `deck_needle`, next-confirm 계열 소모품 | 이미 queue가 있거나 조건이 충족되지 않거나 0점 confirm에 묻히면 소모품이 의미 없이 사라질 수 있다. | 실패 시 미소모는 유지하고, 사용 전/후 피드백과 조건 표시를 보강한다. |
| 가격/가치 이상 후보 | `ride_the_bus`, `reroll_token`, `trade_ticket`, `full_house_study`, `four_kind_study`, `straight_flush_study` | catalog audit 기준 cheap high-impact 또는 expensive low-impact 후보가 있다. | 가격표를 바로 바꾸지 말고 실제 노출/구매/사용률, S7~S8 병목, v9 market 개선 여부를 함께 본다. |
| 자동/직접 지급으로 보일 수 있는 효과 | `coin_cache`, `thin_wallet`, `ledger_clip`, `stage_map`, `coin_funnel`, `hand_funnel` | 경제 보정이 선택 부담을 지우거나 자동 지급처럼 읽힐 수 있다. | 직접 지급 금지 원칙과 충돌하지 않는지, 조건/타이밍/표시가 플레이어 선택으로 읽히는지 확인한다. |
| Board-Line Ritual 후보 | active Ritual 31: Fate 변환 16, 제거/소각/제물 3, 덱 복사/메아리 6, 성장/점수/표식/위치 Ritual 6. `line_memory`는 별도 선 성장형 quickSlot. hold 마켓 보조 5종: `ritual_coupon`, `ritual_lens`, `line_pack_ticket`, `seal_vendor`, `prune_vendor`. debug 전용 0종. deleted legacy 3종: `boss_memory`, `thin_memory`, `minor_memory`. | 손패 직접 파괴/변형 대신 보드에 구성된 선과 scoringTiles를 대상으로 즉시 전투에 읽히는 변환, 제거, 덱 맨 위 보충, 성장/점수/표식/위치 보상을 다룬다. hold/debug는 normal market 제외다. | 활성 Ritual 31종은 runtime/market 노출/선택 UI/flight 검증을 닫고, deleted legacy 3종은 catalog/runtime에서 제거했다. |

2026-05-17 1차 적용:

주의: 아래 묶음은 대부분 표시/피드백 1차다. 새 발동 모션, target 이동, stagger, particle까지 완료됐다는 뜻이 아니다. 기존 animation-first UX 규칙상 아이템 source, 목적지/대상, 결과가 게임적으로 이어지는지 `ANIMATION_EFFECTS_PLAN.md`에서 별도 재점검한다.

- `slide_wax`: 보드 이동 자원이 0이면 `사용 가능한 보드 이동이 없습니다.`로 실패 처리하고 소모하지 않는다.
- `deck_needle`: 확인할 덱 타일이 없으면 선택 overlay를 열지 않고 `덱에 확인할 타일이 없습니다.`로 실패 처리하고 소모하지 않는다.
- next-confirm 수동 one-shot 소모품: 이미 다음 확정 보너스가 queued이면 `이미 다음 확정 보너스가 준비되어 있습니다.`로 실패 처리하고 소모하지 않는다.
- `undo_seal`, `emergency_draw`: 전투 UI 실패 경로에서 명시 notice를 보여주고 성공 burst를 띄우지 않는 것을 `game_view_item_feedback_test`로 고정했다.
- next-confirm 조건부 rank/color 계열: 수동 one-shot confirm modifier가 대기 중이면 battle facade와 확정 preview에 `아이템 대기 N`, `아이템 적용 A/N`, `아이템 조건 미충족 0/N`을 노출한다. 런타임 scoring 규칙은 그대로 두고 read path/presentation 표시만 보강했다.
- next-confirm 대기 상태: 수동 소모품은 사용 즉시 Quick slot에서 사라지므로 원래 slot-local badge 대신 Item zone 내부에 `확정 대기 N` badge를 표시한다.
- next-confirm 확정 순간: 정산 presentation의 item/jester step에서도 floating settlement burst를 띄워 실제 적용된 item delta를 보여준다. item 이름은 `ItemTranslationScope`로 resolve해 현지화된 이름과 `+N 칩`, `+N 점수 보정`, `xN` 결과를 callout으로 읽게 한다.
- `deck_needle`: 덱 확인 dialog의 후보마다 `후보 N`과 타일 코드를 표시하고, 선택 후보를 짧게 강조한 뒤 실제 제거된 타일 코드를 notice/toast에 보여준다. 런타임 소비/버림 규칙은 그대로 두고 대상/결과 read path와 필요한 최소 presentation만 보강했다.
- `emergency_draw`: 성공 시 기존 hand tile incoming 전환과 함께 hand zone에 `드로우 +1` badge를 표시한다. 덱은 소모하지 않고 손패에 생성된 타일을 추가한다. 실패 시 `손패가 비어 있을 때만 사용할 수 있습니다.` notice만 보이고 성공 burst가 뜨지 않는 정책을 유지한다.
- `slide_wax`: session의 `nextBoardMoveSlideBonusQueued`를 battle facade로 노출하고 Item zone에 `이동 보너스 대기` badge를 표시한다. 다음 보드 이동 성공 시 queued marker가 소비되고 `슬라이드 왁스 / 이동 보너스 발동` feedback과 이동 도착 칸 bonus flash를 보여준다.
- `boss_trophy`: 다음 Market Jester 후보 슬롯 보너스가 적용 중이면 market facade에 `트로피 +N` label을 노출하고, Jester offer lane pager badge로 표시한다.
- `deck_needle`: 선택한 후보에 `버림 확정` result badge를 붙여 선택 후보가 discard 결과로 이어졌음을 dialog 안에서 즉시 보여준다.
- next-confirm 16종: `확정 대기 N` badge pulse, scoring preview item link flash, settlement item burst를 묶어 source -> preview -> result 체인을 고정했다.
- `market_compass`, `boss_trophy`: 할인 후보는 affected offer pulse, 후보 슬롯 증가는 lane bonus pulse로 보강했다.
- `board_scrap`, `hand_scrap`, `move_token`, `battle_pouch`: 실제로 바뀐 하단 자원 HUD 또는 hand capacity badge가 반응하는지 전투 widget test로 고정했다.
- `undo_seal`: 성공 시 되돌아간 board target 칸 flash를 보여주고, 실패는 기존처럼 notice만 보여준다.
- Market 직접 사용/성장류: `coin_cache`의 slot source -> item use flight -> Gold HUD badge -> use feedback 경로를 widget test로 고정했고, reroll/discount/growth류는 기존 가격/후보/read path를 유지한다.
- 검증: `item_effect_runtime_test`, `rummi_battle_facade_test`, `game_view_item_feedback_test`, `game_station_read_path_test`, `game_cashout_widgets_test`, 관련 `dart analyze`.

다음 진행:

- 조건부 사용 no-op/표시와 P1+ source -> target/목적지 -> result 연출 1차 묶음은 닫았다.
- P2 후보(`board_scrap`, `hand_scrap`, `move_token`, `battle_pouch`, `undo_seal`, Market 직접 사용/성장 아이템)의 source -> target/결과 연결도 1차 Done으로 닫았다. 다음은 정책 결함이 새로 발견될 때만 열고, 그 외에는 가격/가치 이상 후보 검토로 돌아간다.
- 연출 정정: pulse/glow는 필요한 곳의 보조 강조로만 쓰고, 남발을 피한다. 2026-05-17 추가 polish는 전투 item toast의 source -> result trail, `slide_wax` queued badge의 chevron 이동, 비골드 Market item use flight처럼 실제 이동/방향성이 보이는 쪽으로 반영한다.
- Playwright 눈검증: 정적 web build의 `item_motion_eye_check`, `next_confirm_motion_eye_check`, `animation_effects_eye_check`, `market_modifier_shop`, `market_item_motion_eye_check` fixture에서 `deck_needle`, `emergency_draw`, `slide_wax`, next-confirm, direct resource item, Market modifier, gold/non-gold Market item use flight를 확인했다. 산출물은 `/tmp/rummipoker_item_motion_eye_check_20260517_152554/`, `/tmp/rummipoker_next_confirm_eye_check_20260517_153152/`, `/tmp/rummipoker_next_confirm_eye_check_more_20260517_153249/`, important console/error/overflow/warn 0건이다.
- 그 다음 가격/가치 이상 후보를 실제 노출/구매/사용률, S7~S8 병목, v9 market 개선 여부와 함께 검토한다.
- 2026-05-17 1차 audit 결과, 가격표는 아직 바꾸지 않는다. runtime offer에는 watchlist 일부가 노출되지만 station path sim 구매 이벤트는 proxy 중심이라 `catalog_audit_v3`와 normalized 결과가 동일했다. 다음은 실제 후보 구매/사용 가치 추적을 보강한다.
- runtime 변경이 필요한 항목은 이 문서에 남기고, transient 연출/표시/눈검증 항목은 `ANIMATION_EFFECTS_PLAN.md`에 남긴다.

정책상 주의:

- 상한이 있는 효과는 런타임 상한, UI 표시, 실패 메시지, 소모 여부를 한 세트로 검토한다.
- 복합 효과는 이득이 막힌 상태에서 비용만 적용하지 않는다.
- 가격 후보는 단독 감각으로 바꾸지 않고 `catalog_value_audit.py`, runtime offer audit, 장기 economy probe를 함께 본다.

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

대상 7개:

- reroll/구매 할인: `reroll_token`, `coupon_stamp`, `merchant_stamp`, `jester_invoice`, `item_invoice`, `market_compass`
- 부분 offer 갱신: `trade_ticket` 적용 완료

공통 작업:

- market modifier state 추가: next reroll discount, next purchase discount, category purchase discount, first reroll discount, cheapest first offer discount
- offer build config 추가: extra item slot, rarity weight bonus
- market facade에 할인 적용 전/후 가격과 modifier source 노출
- reroll/buy command에서 modifier 소비
- `trade_ticket`용 item offer only reroll offset/save/read path 추가 완료

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

- `travel_pouch`, `jester_hook`

공통 작업:

- quick slot capacity read model 추가 및 acquisition/placement validation 반영 완료
- jester sell price modifier hook 추가 완료
- market/game facade에 변경된 capacity/가격 노출 완료

### Group 6. Expiry Guard Hook

공통 기반: 전투 종료 판정 직전 expiry signal을 감지하고 스테이션당 1회 구조 자원을 제공.

대상 1개:

- `safety_net`

공통 작업:

- expiry guard event/result 경계 정의 완료
- station-scoped consumed flag save/restore 완료
- 현재 정책: `safety_net`은 보드가 꽉 차고 보드 버림이 없으면 보드 버림 +1, 드로우 더미가 고갈되면 제거 더미를 섞어 타일 1장을 구조한다.

### Group 7. Boss/Next Market Offer Hook

공통 기반: boss clear 후 다음 market offer 구성에 영향을 주는 delayed modifier.

대상 1개:

- `boss_trophy`

공통 작업:

- boss clear reward와 next market build 사이에 delayed market modifier 저장 완료
- 다음 market jester offer slot +1 적용 후 해당 market의 reroll 동안 유지, 다음 market 진입 시 해제 완료

### Group 8. Board Move Follow-up Modifier

공통 기반: 보드 이동 이벤트 후 다음 scoring/trigger context에 플래그를 전달.

대상 1개:

- `slide_wax`

공통 작업:

- next board move bonus marker 저장 완료
- board move 성공 시 marker를 `BoardMoveRecord.slideBonusTriggered`와 station trigger count로 이전 완료
- undo 시 해당 marker/count를 되돌려 다음 이동에 다시 사용할 수 있게 복원 완료

## 다음 구현 우선순위

현재 실행 기준:

- 보드 이동, 손패 한도, station start 자원, deck peek/discard 계열은 1차 runtime 적용 완료
- Group 1 `Confirm Modifier Runtime`은 queue/save/restore/scoring hook까지 1차 적용 완료
- Group 2 `Market Discount and Offer Modifier Runtime`은 modifier state/save/facade/가격 적용까지 1차 적용 완료
- Group 3 `Direct Gold and Economy Hooks`는 gold delta/event/save 경계까지 1차 적용 완료
- Group 4 `Settlement Reward Modifiers`는 settlement breakdown UX와 gold total 반영까지 1차 적용 완료
- B7 `Next Station Loop`의 next station transition command 정리는 1차 적용 완료
- 다음 최우선은 full loop smoke / save-restore 경계 재점검

1. Full loop smoke / save-restore 경계 재점검
   - `Battle -> Settlement -> Market -> Next Station/Blind Select -> Battle`
   - market resume, next station checkpoint, death/continue/restart
