# Item Presentation Contract Review

> GCSE role: `Execution`
> 기준: 모든 Item 효과를 `발동 객체 -> 적용 대상 -> 결과` 관점에서 재검토한다.
> 과거 1차 결론: 당시 55개 검토 중 `shop_lens` 1개 삭제, 활성 Item 54개 보강 계획.

## 결론

현재 Item runtime은 54개 활성 Item 모두 상태 변경까지 적용된다. 그러나 연출 기준의 Done은 아니다.

연출 Done 기준:

1. 발동 객체가 먼저 보인다.
2. 적용 대상 UI가 이어서 강조된다.
3. 숫자, 가격, 후보, 손패 칸, 보드 자원, 점수 항목 같은 결과가 실제로 바뀐다.
4. 예약 효과는 언제 발동될지 남아 있어야 한다.

`shop_lens`는 삭제했다. Item 후보 수 +1은 유저가 이전 후보 수를 기억해야 체감되는 효과였고, source-target-result 연출 없이 후보 수만 바뀌어 효과 의미가 약했다. 같은 축을 재도입하려면 아이템 발동, 후보 영역 확장, 새 후보 등장, 결과 유지 표시까지 전용 연출 계약을 먼저 승인받는다.

## 공통 연출 문법

| 단계 | 화면에서 보여야 하는 것 | 저장 여부 |
|---|---|---|
| Source | 보유 Item 카드/Quick slot/Passive/Tool/Gear가 점등한다. | 저장하지 않음 |
| Target | 적용 대상 UI가 하이라이트된다. 예: 골드, 후보 카드, Confirm 버튼, 보드 자원, 손패 칸, 런 정보 족보. | 저장하지 않음 |
| Result | 실제 바뀐 숫자나 카드가 pulse/count-up/flight로 보인다. | runtime state만 저장 |
| Remainder | 예약 효과면 `다음 확정`, `다음 구매`, `다음 Market` 같은 남은 상태가 읽힌다. | 예약 runtime state 저장 |

presentation queue는 save/continue source of truth가 아니다. 저장 가능한 상태는 runtime state이고, 연출 queue는 transient state로 둔다.

## 우선순위

| 우선순위 | 범위 | 이유 |
|---|---|---|
| P0 | Market 예약/가격/후보 효과 | 발동 시점과 결과 시점이 분리되어 가장 오해가 크다. |
| P1 | Battle 직접 사용/조건부 no-op | 유저가 직접 누르는 효과라 즉시 피드백 품질이 중요하다. |
| P2 | Confirm 예약/정산 패시브 | 사용 시 예약과 확정 시 발동을 두 번 보여야 한다. |
| P3 | Station 시작/Settlement/Boss 자동 효과 | 자동 발동이라 놓치기 쉽지만, 공통 문법이 생긴 뒤 붙이기 쉽다. |

## 삭제/보류

| Item | 판정 | 이유 | 재도입 조건 |
|---|---|---|---|
| `shop_lens` | 삭제 | Item 후보 수 +1은 현재 화면에서 유저가 체감하기 어렵고, 후보 영역에 결과만 남아 source가 사라진다. | 후보 영역 확장과 새 후보 등장까지 전용 연출 계약이 있을 때만 재검토한다. |

## 활성 54개 연출 계약

| Item | Source | Target | Result | 판정 |
|---|---|---|---|---|
| `reroll_token` | 보유 Tool | Reroll 버튼/비용 | 다음 reroll 비용 차감, 사용 시 Tool 소모 | P0 보강 필요 |
| `coupon_stamp` | 보유 Tool | 다음 Jester/Item 구매 카드 | 구매 가격 차감, 구매 시 Tool 소모 | P0 보강 필요 |
| `coin_cache` | 보유 Tool | Gold HUD | Gold +3 flight/count-up | P1 보강 필요 |
| `two_pair_study` | 보유 Tool | 런 정보의 Two Pair 성장줄 | 성장 +1, 다음 완성 보정 읽힘 | P1 보강 필요 |
| `triple_study` | 보유 Tool | 런 정보의 Triple 성장줄 | 성장 +1, 다음 완성 보정 읽힘 | P1 보강 필요 |
| `straight_study` | 보유 Tool | 런 정보의 Straight 성장줄 | 성장 +1, 다음 완성 보정 읽힘 | P1 보강 필요 |
| `flush_study` | 보유 Tool | 런 정보의 Flush 성장줄 | 성장 +1, 다음 완성 보정 읽힘 | P1 보강 필요 |
| `full_house_study` | 보유 Tool | 런 정보의 Full House 성장줄 | 성장 +1, 다음 완성 보정 읽힘 | P1 보강 필요 |
| `four_kind_study` | 보유 Tool | 런 정보의 Four of a Kind 성장줄 | 성장 +1, 다음 완성 보정 읽힘 | P1 보강 필요 |
| `straight_flush_study` | 보유 Tool | 런 정보의 Straight Flush 성장줄 | 성장 +1, 다음 완성 보정 읽힘 | P1 보강 필요 |
| `board_scrap` | Quick slot | 보드 버림 HUD | 보드 버림 +N pulse, 상한 실패 미소모 | P1 보강 필요 |
| `hand_scrap` | Quick slot | 손패 버림 HUD | 손패 버림 +N pulse, 상한 실패 미소모 | P1 보강 필요 |
| `chip_capsule` | Quick slot | Confirm 버튼/점수 preview | 다음 확정 칩 보너스 예약, 확정 시 재발동 | P2 보강 필요 |
| `mult_capsule` | Quick slot | Confirm 버튼/점수 preview | 다음 확정 점수 +% 예약, 확정 시 재발동 | P2 보강 필요 |
| `line_polish` | Quick slot | Confirm 버튼/점수 preview | 다음 확정 점수 xN 예약, 확정 시 재발동 | P2 보강 필요 |
| `straight_oil` | Quick slot | Confirm 버튼/족보 조건 표시 | Straight 이상 조건부 칩 보너스 예약 | P2 보강 필요 |
| `flush_powder` | Quick slot | Confirm 버튼/족보 조건 표시 | Flush 이상 조건부 점수 +% 예약 | P2 보강 필요 |
| `pair_splint` | Quick slot | Confirm 버튼/족보 조건 표시 | Two Pair 조건부 칩 보너스 예약 | P2 보강 필요 |
| `overlap_pin` | Quick slot | Confirm preview overlap 항목 | 다음 확정 overlap cap 보너스 예약 | P2 보강 필요 |
| `emergency_draw` | Quick slot | 손패/덱 HUD | 손패가 비었을 때 1장 draw, 조건 실패 미소모 | P1 보강 필요 |
| `ledger_clip` | Gear | Market 진입 Gold HUD | Market 진입 시 Gold +1 | P3 보강 필요 |
| `discard_glove` | Gear | 전투 시작 보드 버림 HUD | Station 시작 보드 버림 +1 | P3 보강 필요 |
| `mulligan_sleeve` | Gear | 전투 시작 손패 버림 HUD | Station 시작 손패 버림 +1 | P3 보강 필요 |
| `jester_hook` | Gear | Jester 판매 가격 | 판매가 +1 배지, 판매 시 Gold 결과 | P0 보강 필요 |
| `score_abacus` | Gear | 첫 Confirm 점수 breakdown | Station 첫 확정 칩 +30 | P2 보강 필요 |
| `thin_caliper` | Gear | 3장 이하 Confirm preview | 조건 충족 시 점수 +% | P2 보강 필요 |
| `stage_map` | Passive | Boss clear reward | 보스 클리어 보상 Gold +1 | P3 보강 필요 |
| `merchant_stamp` | Passive | 첫 Reroll 버튼/비용 | Market 진입 후 첫 reroll 할인 | P0 보강 필요 |
| `safety_net` | Passive | 종료 위기 overlay/보드 자원/덱 | Station당 1회 구조 발동, 사용됨 표시 | P3 보강 필요 |
| `coin_funnel` | Passive | Settlement 보상 breakdown | 남은 보드 버림당 Gold +1 | P3 보강 필요 |
| `hand_funnel` | Passive | Settlement 보상 breakdown | 남은 손패 버림당 Gold +1 | P3 보강 필요 |
| `echo_bell` | Passive | 두 번째 Confirm 점수 breakdown | 첫 확정 점수 10% 추가 | P2 보강 필요 |
| `boss_trophy` | Passive | Boss clear -> 다음 Market Jester 후보 | 다음 Market Jester 후보 +1 예약/도착 | P0 보강 필요 |
| `thin_wallet` | 보유 Tool | Gold HUD | Gold 3 이하일 때 Gold +5, 조건 실패 미소모 | P1 보강 필요 |
| `trade_ticket` | 보유 Tool | Item 후보 영역 | Item 후보만 reroll, 후보 교체 전후가 보여야 함 | P0 보강 필요 |
| `jester_invoice` | 보유 Tool | 다음 Jester 구매 카드 | Jester 구매 가격 -4, 구매 시 소모 | P0 보강 필요 |
| `item_invoice` | 보유 Tool | 다음 Item 구매 카드 | Item 구매 가격 -4, 구매 시 소모 | P0 보강 필요 |
| `red_swatch` | Quick slot | 빨간 타일/Confirm preview | 다음 확정 빨간 타일당 점수 +% | P2 보강 필요 |
| `blue_swatch` | Quick slot | 파란 타일/Confirm preview | 다음 확정 파란 타일당 점수 +% | P2 보강 필요 |
| `black_swatch` | Quick slot | 검은 타일/Confirm preview | 다음 확정 검은 타일당 점수 +% | P2 보강 필요 |
| `yellow_swatch` | Quick slot | 노란 타일/Confirm preview | 다음 확정 노란 타일당 점수 +% | P2 보강 필요 |
| `rank_chalk` | Quick slot | 반복 숫자 타일/Confirm preview | 반복 숫자 타일당 칩 +12 | P2 보강 필요 |
| `deck_needle` | Quick slot | 덱 상단 선택 dialog/덱 HUD | 상단 3장 중 1장 버림, 선택 흐름 명확화 | P1 보강 필요 |
| `battle_pouch` | Quick slot | 손패 슬롯/손패 HUD | 손패 최대치 +1, 상한 실패 미소모 | P1 보강 필요 |
| `tile_polisher` | Gear | 첫 scoring tile | 첫 scoring tile 칩 +20 | P2 보강 필요 |
| `move_token` | Quick slot | 보드 이동 HUD | 보드 이동 +1, 상한 실패 미소모 | P1 보강 필요 |
| `slide_wax` | Quick slot | 다음 보드 이동 mode | 다음 보드 이동 보너스 예약, 이동 시 재발동 | P1 보강 필요 |
| `board_lift` | 보유 Tool | 다음 Station 보드 이동 HUD | 다음 Station 보드 이동 +1 예약/도착 | P3 보강 필요 |
| `undo_seal` | Quick slot | 마지막 이동 타일 경로 | 마지막 보드 이동 되돌림, 실패 미소모 | P1 보강 필요 |
| `organizer_glove` | Gear | 전투 시작 보드 이동 HUD | Station 시작 보드 이동 +1 | P3 보강 필요 |
| `travel_pouch` | Passive | 손패 슬롯/손패 HUD | 손패 최대치 +1 | P3 보강 필요 |
| `wide_grip` | Gear | 손패 슬롯 + 보드 버림 HUD | 손패 최대치 +1, 보드 버림 -1 | P3 보강 필요 |
| `grand_satchel` | Passive | 손패 슬롯 + 손패 버림 HUD | 손패 최대치 +2, 손패 버림 -1 | P3 보강 필요 |
| `market_compass` | Passive | 최저가 Jester/Item 후보 카드 | 1G 이상 최저가 후보 1개 할인 배지/가격 차감 | P0 보강 필요 |

## 구현 순서 제안

1. `ItemPresentationEvent`와 `ItemPresentationTarget`을 transient model로 정의한다.
2. `ItemEffectEvent`를 화면 연출 이벤트로 변환하는 adapter를 만든다.
3. Market P0부터 적용한다: `market_compass`, `merchant_stamp`, `reroll_token`, `coupon_stamp`, `jester_invoice`, `item_invoice`, `trade_ticket`, `boss_trophy`, `jester_hook`.
4. Battle P1을 적용한다: 전투 Quick slot 직접 사용과 조건부 실패/no-op.
5. Confirm P2를 적용한다: 예약 시 표시와 확정 시 발동을 분리한다.
6. Station/Settlement/Boss P3를 적용한다.

## 검증 기준

- Widget test는 source/target/result 요소가 동시에 존재하는지만 보지 않고 순차 상태를 확인한다.
- Chrome fixture 눈검증은 최소 P0 Market, P1 Battle, P2 Confirm, P3 Settlement/Station 각각 1개 이상을 찍는다.
- `shop_lens`는 catalog/translation/fixture에 다시 나타나면 회귀로 본다.
