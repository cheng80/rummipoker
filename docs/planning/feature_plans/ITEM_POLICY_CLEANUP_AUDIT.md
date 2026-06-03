# Item Policy Cleanup Audit

> 목적: `policy-cleanup-baseline-20260530` 이후 아이템/덱빌딩 정책 정화의 작업 표.
> Source contract: `docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md`

## 1. 결론

기준점 `policy-cleanup-baseline-20260530` 당시 `data/common/items_common_v1.json`의 54개 아이템은 런타임 동작은 넓게 갖췄지만, 덱빌딩 다양성 관점에서는 아래로 치우쳐 있었다.

```text
Hand-Rank Growth: 7
Confirm / Score Modifier: 16
Resource / Board Action: 15
Market / Economy / Pool: 15
Survival: 1
Board-Line Ritual: 0
Direct Tile Modifier Item: 0
```

현재는 Ritual/Item 확장 계열 37종을 실제 catalog에 추가해 총 91개 아이템 상태다. 전투 보드 선 선택형 `ritual_line_effect`는 31장이고, Fate 변환 16종은 그 안의 고강도 변환 축으로 관리한다. active Ritual 31장은 normal market 후보, hold 마켓 보조 5종은 normal market 제외, debug 전용 0종은 현재 없음, deleted legacy 3종은 `boss_memory`, `thin_memory`, `minor_memory`다. 따라서 다음 catalog 확장은 단순 점수 보정 아이템을 더 늘리는 일이 아니라, 추가된 Ritual/Item 확장 계열이 아래 기준을 만족하는지 닫는 작업이다.

- 효과별 target 조건이 유저에게 읽히는가.
- 적용 결과가 board/deck/growth/seal/run info/log에 남는가.
- `ritual_lens`, `ritual_coupon`, `seal_vendor`, `prune_vendor`, `line_pack_ticket`이 단순 할인/후보 수 변경처럼 약하게 보이지 않는가.
- active Ritual 31종과 hold 마켓 보조 5종의 희귀도/가격/출현 weight가 과하지 않은가.

## 2. 분류 기준

| Family | 설명 | 이번 정화 판단 |
|---|---|---|
| `Hand-Rank Growth` | 특정 족보 레벨을 올리는 Planet-like 축 | 유지. 단 next-confirm 임시 보정과 섞지 않는다. |
| `Confirm / Score Modifier` | 다음 확정 또는 조건부 확정 점수 보정 | 이미 많음. 추가 억제. 조건/대상/연출 없는 항목은 정리 후보. |
| `Resource / Board Action` | 손패, 보드 버림, 이동, 되돌리기, 덱 확인 | 유지. 풀런봇 정책과 UI 피드백 기준으로 가치 재점검. |
| `Market / Economy / Pool` | 할인, 골드, 후보 교체, 후보 수/가격 조정 | 유지하되 자동 지급처럼 보이는 항목은 조건/표시 보강. |
| `Survival` | 실패 방지/구제 | 희소하게 유지. 자동 완화처럼 보이지 않게 표시 필요. |
| `Board-Line Ritual` | 보드 라인을 재료로 복제/각인/변형/압축 | 현재 active Ritual 31장. 새 덱빌딩 다양성의 1순위였고, 지금은 active/hold 경계를 유지하며 가격/가중치와 전달력을 검증한다. |
| `Direct Tile Modifier Item` | 타일 enhancement/seal/edition 직접 부여 | 현재 catalog 0개. 특수 타일 시스템과 연결해 확장. |

### 2.1 Exposure group source of truth

Task 6의 1차 정화 범위는 catalog 값을 바로 바꾸는 것이 아니라, 현재 노출 정책을 코드/문서/test에서 같은 기준으로 고정하는 것이다. 현행 catalog 기준 노출 그룹은 아래와 같다.

| Group | Count | Policy |
|---|---:|---|
| normal item 86 | 86 | normal market 후보. 기존 Q-Slot/Tool/Gear/Passive와 active Ritual 31장을 포함한다. |
| normal Jester 43 | 43 | normal market Jester 후보. 현재 Jester catalog 전부가 normal 노출이다. |
| hold item 5 | 5 | Ritual 마켓 보조 후보. 재설계 전까지 normal market 제외. |
| debug item 0 | 0 | 현재 debug 전용 item catalog 항목 없음. |
| deleted legacy 3 | 3 | `boss_memory`, `thin_memory`, `minor_memory`; catalog/runtime/translation 대상에서 제거된 legacy 이름. |

Normal item 86:

`reroll_token`, `coupon_stamp`, `coin_cache`, `two_pair_study`, `triple_study`, `straight_study`, `flush_study`, `full_house_study`, `four_kind_study`, `straight_flush_study`, `line_memory`, `bridge_rite`
`diagonal_rite`, `center_rite`, `corner_rite`, `cross_rite`, `sacrifice_line`, `deadwood_burn`, `trim_rank`, `trim_color`, `line_pruner`, `number_mask`, `wild_thread`, `off_color_rite`
`color_concord`, `step_rite`, `rank_concord`, `fate_full_house_low`, `flush_house_fate`, `flush_five_fate`, `fate_flush_high`, `fate_flush_low`, `fate_straight_high`, `fate_straight_low`, `fate_three_kind_high`, `sealed_copy`
`scarce_copy`, `color_echo`, `rank_echo`, `edge_copy`, `keystone_copy`, `cross_memory`, `board_scrap`, `hand_scrap`, `chip_capsule`, `mult_capsule`, `line_polish`, `straight_oil`
`flush_powder`, `pair_splint`, `overlap_pin`, `emergency_draw`, `ledger_clip`, `discard_glove`, `mulligan_sleeve`, `jester_hook`, `score_abacus`, `thin_caliper`, `stage_map`, `merchant_stamp`
`safety_net`, `coin_funnel`, `hand_funnel`, `echo_bell`, `boss_trophy`, `thin_wallet`, `trade_ticket`, `jester_invoice`, `item_invoice`, `red_swatch`, `blue_swatch`, `black_swatch`
`yellow_swatch`, `rank_chalk`, `deck_needle`, `battle_pouch`, `tile_polisher`, `move_token`, `slide_wax`, `board_lift`, `undo_seal`, `organizer_glove`, `travel_pouch`, `wide_grip`
`grand_satchel`, `market_compass`

Normal Jester 43:

`jester`, `greedy_jester`, `lusty_jester`, `wrathful_jester`, `gluttonous_jester`, `jolly_jester`, `zany_jester`, `mad_jester`, `crazy_jester`, `droll_jester`, `sly_jester`, `wily_jester`
`clever_jester`, `devious_jester`, `crafty_jester`, `half_jester`, `jester_stencil`, `abstract_jester`, `green_jester`, `blue_jester`, `scary_face`, `smiley_face`, `egg`, `bonus_jester`
`popcorn`, `ice_cream`, `delayed_gratification`, `walkie_talkie`, `golden_jester`, `mystic_summit`, `even_steven`, `odd_todd`, `scholar`, `fibonacci`, `banner`, `gros_michel`
`supernova`, `ride_the_bus`, `the_duo`, `the_trio`, `the_family`, `the_order`, `the_tribe`

Hold item 5:

`ritual_coupon`, `ritual_lens`, `line_pack_ticket`, `seal_vendor`, `prune_vendor`

Watchlist value lock:

| ID | rarity | price | sell | Task 6 decision |
|---|---|---:|---:|---|
| `reroll_token` | common | 5G | 1G | low-tier utility. 유지하되 구매 가치 probe 대상. |
| `trade_ticket` | uncommon | 6G | 3G | market pool mutation. Item 후보만 교체하는 기준 사례로 유지. |
| `full_house_study` | rare | 9G | 4G | advanced study probe. Broad sim 전 fresh probe에서 구매/성장 빈도 확인. |
| `four_kind_study` | rare | 10G | 5G | advanced study probe. Broad sim 전 fresh probe에서 구매/성장 빈도 확인. |
| `straight_flush_study` | rare | 12G | 6G | advanced study probe. Broad sim 전 fresh probe에서 구매/성장 빈도 확인. |
| `ride_the_bus` | uncommon | 6G | stateful_growth | redesign watch. 현재 Jester 값은 유지하되 stateful 성장 가독성과 face-card 조건 전달을 재검토한다. |

## 3. 현재 Catalog 분류

### 3.1 Hand-Rank Growth

| ID | 효과 | 정책 |
|---|---|---|
| `two_pair_study` | Two Pair 성장 +1 | 유지 |
| `triple_study` | Three of a Kind 성장 +1 | 유지 |
| `straight_study` | Straight 성장 +1 | 유지 |
| `flush_study` | Flush 성장 +1 | 유지하되 flush 고착 데이터 확인 |
| `full_house_study` | Full House 성장 +1 | 가격/출현 probe |
| `four_kind_study` | Four of a Kind 성장 +1 | 가격/출현 probe |
| `straight_flush_study` | Straight Flush 성장 +1 | 가격/출현 probe |

정화 방향:

- 성장 아이템은 “이번 확정 보너스”가 아니라 run-long 성장 투자로 유지한다.
- 고급 study 3종은 등장률/가격이 실제 구매 가치와 맞는지 fresh data로 재검증한다.

### 3.2 Confirm / Score Modifier

| ID | 효과 | 정책 |
|---|---|---|
| `chip_capsule` | 다음 확정 칩 보정 | 유지, 초반 소모품 |
| `mult_capsule` | 다음 확정 점수 +% | 유지, 초반 소모품 |
| `line_polish` | 다음 확정 점수 x | 유지, 희귀도/가격 probe |
| `straight_oil` | Straight 조건부 칩 | 유지, 조건 표시 필수 |
| `flush_powder` | Flush 조건부 점수 +% | 유지하되 flush 고착 감시 |
| `pair_splint` | Pair 계열 조건부 칩 | 유지 |
| `overlap_pin` | overlap cap 임시 증가 | 유지, overlap 빌드 지원 |
| `red_swatch` | 색 조건부 점수 +% | 유지 |
| `blue_swatch` | 색 조건부 점수 +% | 유지 |
| `black_swatch` | 색 조건부 점수 +% | 유지 |
| `yellow_swatch` | 색 조건부 점수 +% | 유지 |
| `rank_chalk` | 숫자 조건부 칩 | 유지 |
| `score_abacus` | 장비형 점수 보정 | 유지, 장비 정체성 재검토 |
| `thin_caliper` | 장비형 점수 +% | 유지, 장비 정체성 재검토 |
| `tile_polisher` | 장비형 칩 보정 | 유지, Tile Modifier와 혼동 주의 |
| `echo_bell` | 첫 확정 점수 비율 보너스 | 유지, passive 발동 가독성 필요 |

정화 방향:

- 이 family는 이미 충분히 많다. 새 후보 추가보다 기존 후보의 조건 가독성, source-target-result 연출, 가격/희귀도 조정이 우선이다.
- `tile_polisher`는 이름상 타일 modifier처럼 읽히므로 실제 효과가 점수 보정이면 표시명/설명 재검토 대상이다.

### 3.3 Resource / Board Action

| ID | 효과 | 정책 |
|---|---|---|
| `board_scrap` | 보드 버림 + | 유지 |
| `hand_scrap` | 손패 버림 + | 유지 |
| `discard_glove` | 보드 버림 + 장비 | 유지 |
| `mulligan_sleeve` | 손패 버림 + 장비 | 유지 |
| `move_token` | 보드 이동 + | 유지 |
| `slide_wax` | 다음 보드 이동 보너스 | 유지 |
| `board_lift` | 보드 이동 + | 유지, inventory/quick 역할 재검토 |
| `undo_seal` | 마지막 보드 이동 취소 | 유지 |
| `organizer_glove` | 보드 이동 + 장비 | 유지 |
| `emergency_draw` | 손패 비었을 때 덱 소모 없는 타일 생성 | 유지 |
| `deck_needle` | 덱 상단 확인/버림 | 유지, 전략 축 중요 |
| `battle_pouch` | 손패 최대치 증가 | 유지, 상한/피드백 필수 |
| `travel_pouch` | 손패 최대치 증가 passive | 유지 |
| `wide_grip` | 손패 증가 + 패널티 | 유지, 고위험 성장 후보 |
| `grand_satchel` | 손패 증가 + 패널티 passive | 유지, 고위험 성장 후보 |

정화 방향:

- 이 family는 전투 선택 폭을 늘린다. 단 풀런봇이 의미 없는 사용을 하지 않도록 “족보 형성/확정 점수 개선” 조건을 유지한다.
- 손패 증가 계열은 덱빌딩 다양성에 중요하지만 UI 한계와 상한이 같이 관리되어야 한다.

### 3.4 Market / Economy / Pool

| ID | 효과 | 정책 |
|---|---|---|
| `reroll_token` | 다음 리롤 할인 | 유지, 구매 가치 probe |
| `coupon_stamp` | 다음 구매 할인 | 유지 |
| `coin_cache` | 골드 획득 | 조건/표시 보강 |
| `ledger_clip` | 장비형 골드 획득 | 조건/표시 보강 |
| `stage_map` | passive 골드 획득 | 자동 지급처럼 보이지 않게 표시 |
| `merchant_stamp` | 첫 리롤 할인 | 유지 |
| `coin_funnel` | 남은 보드 버림 보상 증가 | 유지 |
| `hand_funnel` | 남은 손패 버림 보상 증가 | 유지 |
| `thin_wallet` | 골드 획득/경제 보정 | 조건/표시 재검토 |
| `trade_ticket` | Item 후보 교체 | 유지, Market Pool Mutation의 현재형 |
| `jester_invoice` | Jester 구매 할인 | 유지 |
| `item_invoice` | Item 구매 할인 | 유지 |
| `jester_hook` | 판매가 보정 | 유지 |
| `boss_trophy` | 다음 Market Jester 후보 슬롯 보너스 | 유지, 상한/표시 필수 |
| `market_compass` | 현재 Market 최저가 할인 | 유지 |

정화 방향:

- 경제 family는 플레이어 선택을 늘려야 한다. 자동 지급처럼 읽히는 효과는 발동 조건, 대상, 결과 표시가 없으면 정리 후보가 된다.
- `trade_ticket`, `boss_trophy`, `market_compass`는 새 `Market Pool Mutation` family의 기준 사례로 둔다.

### 3.5 Survival

| ID | 효과 | 정책 |
|---|---|---|
| `safety_net` | Station 첫 만료 구제 | 유지, 자동 완화로 보이지 않게 발동 표시 강화 |

정화 방향:

- 구제 효과는 적게 유지한다. 난이도 보정 도구로 남발하지 않는다.

## 4. 비어 있는 축

### 4.1 Board-Line Ritual

기준점 당시 catalog에는 0개였고, 다음 확장 1순위였다. 현재는 Ritual/Item 확장 계열 37종이 실제 catalog/runtime/번역/이미지 경로에 들어갔다. 전투 보드 선 선택형 `ritual_line_effect`는 31장이고, normal market 노출 후보도 현재 active Ritual 31장으로 제한한다.

현재 실행 분류:

| 분류 | 수 | 상태 | 카드 |
|---|---:|---|---|
| 족보 변환형 운명 | 16 | Active | `trim_rank`, `line_pruner`, `fate_three_kind_high`, `color_concord`, `step_rite`, `rank_concord`, `fate_full_house_low`, `flush_house_fate`, `flush_five_fate`, `fate_flush_high`, `fate_flush_low`, `fate_straight_high`, `fate_straight_low`, `wild_thread`, `off_color_rite`, `number_mask` |
| 제거/소각/제물 | 3 | Active | `trim_color`, `deadwood_burn`, `sacrifice_line` |
| 덱 복사/메아리 | 6 | Active | `sealed_copy`, `scarce_copy`, `color_echo`, `rank_echo`, `edge_copy`, `keystone_copy` |
| 성장/점수/표식/위치 의식 | 6 | Active | `bridge_rite`, `diagonal_rite`, `center_rite`, `corner_rite`, `cross_rite`, `cross_memory` |
| 마켓 보조 의식 | 5 | Hold | `ritual_coupon`, `ritual_lens`, `line_pack_ticket`, `seal_vendor`, `prune_vendor` |
| Debug 전용 | 0 | debug 전용 0종 | 없음 |
| 삭제 legacy 기억 의식 | 3 | deleted legacy 3종 | `boss_memory`, `thin_memory`, `minor_memory` |
| 비-Ritual 선 성장 | 1 | Active quickSlot | `line_memory` |

정리 원칙:

- 운명 카드는 실제 5칸 타일 세트 치환으로 현재 전투 족보를 즉시 바꾼다.
- 각인/표식 이름은 타일 modifier persistence 값과 카드 ID를 섞지 않는다. 운명 카드 ID는 `fate_*` 계열로 둔다.
- 보류군은 catalog/이미지/fixture 검토 자산으로 남기되 normal market offer에서는 제외한다.
- 손패 직접 파괴/변형은 V1 금지다. 보드 선, 덱 맨 위 보충, 타일 modifier, 족보 성장으로 우회한다.

금지:

- 손패 직접 파괴/변형.
- 선택/예고 없는 무작위 영구 변경.
- 보드 라인을 지우기만 하고 보상/로그가 없는 효과.

### 4.2 Direct Tile Modifier Item

특수 타일 시스템은 이미 있지만, 아이템이 직접 타일 modifier를 부여하는 catalog 항목은 없다.

후보 방향:

- 라인 타일 1개에 `seal` 부여.
- 라인 타일 1개에 전투 한정 enhancement 부여.
- scoring line에 포함된 modifier tile을 덱에 약화 복사.

주의:

- 마켓에서만 설명되고 전투/정산에서 일반 타일처럼 보이면 실패다.
- 특수 타일 뱃지, 보스 제약 X, 숫자, 선택 표시가 겹치지 않아야 한다.

## 5. 정화 진행 상태

1. 완료: 현재 catalog 54개를 policy family 기준으로 1차 분류했다.
2. 정정: 9개 후보는 너무 적다. 구현 안전 후보가 아니라 실제 카드 pool이 먼저 넓어야 한다.
3. 완료: Ritual/Item 확장 계열 37종을 실제 catalog에 추가했다.
4. 완료: 성장, 복사, 각인, 족보 강제 판정, 압축/즉시 제거, 보드 선 제거/회수, geometry, market 보조 계열을 `ritual_line_effect`/`ritualAction` 또는 기존 market op로 연결했다.
5. 완료: Ritual line target을 scoring line 밖의 보드 선까지 확장했다. 효과별 target 조건은 점수 족보 선, 타일 3개 이상 보드 선, 보드 선 안의 타일로 나뉜다.
6. 완료: 전투 선택 UI는 보드 미니 프리뷰 + line choice chip dialog로 교체했고, 다국어 효과 문구도 현재 조건에 맞게 정리했다.
7. 현재 우선순위: 새 카드 추가가 아니라 V1 QA/정책 정리다.

### 5.1 Ritual V1 다음 작업

1. ID/source-of-truth 정리:
   - 완료 기준: 운명 카드 16종은 `fate_*` 또는 명확한 변환 ID를 쓰고, 과거 `*_seal`, `*_stamp` 계열 ID는 legacy alias로만 남긴다.
   - 타일 modifier persistence 값(`anchor_seal`, `echo_seal`, `growth_seal`, `fracture_seal` 등)은 카드 ID와 분리한다.
2. result communication 보강:
   - item source, target board line, result delta가 한 흐름으로 보이는지 확인한다.
   - 부족하면 line flash, result panel, toast/callout, run info delta를 보강한다.
3. run info/log 보강:
   - `addedDeckTiles`, 즉시 제거, seal/marker, hand-rank growth가 런 정보와 trace에서 확인되는지 본다.
4. market 보조 계열 재검토:
   - `ritual_lens`, `ritual_coupon`, `seal_vendor`, `prune_vendor`, `line_pack_ticket`은 지금 효과가 기존 할인/후보 수 변경 op를 재사용하므로 Ritual family 정체성이 약하다. normal market 투입 전 재설계한다.
5. balance watch:
   - `number_mask`, `flush_five_fate`, `flush_house_fate`, `wild_thread`, `off_color_rite`, `sacrifice_line`은 효과가 강해 가격/희귀도/출현률을 fresh run으로 본다.

## 6. New Item Card Pool Direction

목표는 기존처럼 매판 같은 족보와 같은 성장 루트로 수렴하지 않게 만드는 것이다. 따라서 새 아이템 pool은 단순 점수 보정이 아니라 아래 질문에 답해야 한다.

- 이번 전투에서 이미 만든 라인을 다음 덱 방향으로 바꿀 수 있는가?
- 점수 확정만이 아니라 덱 압축, 복사, 각인, 변형, 성장 투자가 선택지로 보이는가?
- flush 위주 플레이만 강화하지 않고 숫자 족보, 교차 라인, 대각, 위치 기반 빌드도 살리는가?
- 손패 직접 파괴/변형 없이도 Balatro의 Tarot/Spectral 같은 덱빌딩 변화를 줄 수 있는가?

공통 원칙:

- ML/시뮬레이션은 잠시 보류한다. 지금은 카드와 효과를 먼저 잡는다.
- 첫 catalog pool은 최소 24종 이상을 기준으로 한다.
- 첫 구현 slice는 그중 8~12종만 골라도 되지만, 설계 pool 자체는 좁히지 않는다.
- 손패 직접 파괴/변형은 V1 금지다. 보드 라인, 덱 추가/즉시 제거, 타일 각인/강화, 족보 성장으로 우회한다.

## 7. New Item Card Candidate Pool

아래 후보는 “추가 가능 카드 pool”이다. 바로 런타임에 넣는 확정 JSON이 아니라, 다음 catalog draft의 후보군이다.

### 7.1 Line Memory / Growth

Ritual 성장 카드는 자동으로 "가장 강한/약한/대표" 줄을 고르지 않는다. 기본 입력은 유저가 직접 고른 완성 줄이고, 그 줄의 현재 족보가 성장 대상이 된다.

| ID | 표시명 | rarity | price | 대상 | 결과 | 설계 의도 |
|---|---|---:|---:|---|---|---|
| `line_memory` | 라인 기억 | uncommon | 7 | 선택한 완성 줄 1개 | 그 줄의 현재 족보 성장 +1 | 유저가 고른 족보를 run-long 성장으로 연결 |
| `cross_memory` | 교차 기억 | rare | 10 | 교차 점수 타일 1개 | 교차 타일에 `cross_memory` 표식. 이후 해당 타일이 겹친 줄 정산에 포함되면 추가 족보 성장 | 겹친 줄의 핵심 타일 가치를 명확히 보상 |

### 7.2 Copy / Deck Injection

복사 카드는 "조건에 맞는 타일을 자동 선택"하지 않는다. 줄을 먼저 고르고, 그 안의 scoringTiles 후보를 직접 고르는 2단계 UX를 기본으로 한다. 추가된 타일은 `runProgress.addedDeckTiles` 기록뿐 아니라 현재 session deck 맨 위에도 들어가 다음 draw에서 바로 체감되어야 한다.

| ID | 표시명 | rarity | price | 대상 | 결과 | 설계 의도 |
|---|---|---:|---:|---|---|---|
| `keystone_copy` | 중심석 복사 | uncommon | 8 | 선택한 줄의 가운데 scoringTile | 같은 타일 1장을 덱 맨 위에 추가 | 핵심 타일 중심 덱빌딩 |
| `edge_copy` | 끝점 복사 | common | 6 | 선택한 줄 양끝의 scoringTile 중 유저가 고른 타일 1장 | 같은 타일 1장을 덱 맨 위에 추가 | 위치 의미 부여 |
| `rank_echo` | 숫자 메아리 | uncommon | 8 | 선택한 줄의 scoringTile 1장 | 같은 숫자, 무작위 색 타일 1장을 덱 맨 위에 추가 | 숫자 족보 강화 |
| `color_echo` | 색 메아리 | uncommon | 8 | 선택한 줄의 scoringTile 1장 | 같은 색, 무작위 숫자 타일 1장을 덱 맨 위에 추가 | 색 빌드 지원 |
| `scarce_copy` | 희소석 복사 | rare | 10 | 선택한 줄의 scoringTile 1장 | 같은 타일 1장을 덱 맨 위에 추가 | 덱 편중 완화 |
| `sealed_copy` | 각인 복사 | rare | 12 | 선택한 줄의 각인/강화 scoringTile 1장 | 같은 타일 1장을 덱 맨 위에 추가 | modifier 빌드 지원 |

### 7.3 Seal / Enhancement

이 섹션의 `*_seal` 값은 타일 modifier persistence value다. 현재 운명 카드 ID로 재사용하지 않는다. seal/marker 기반 카드는 별도 카드 ID를 써야 하며, 기존 운명 카드의 legacy ID는 runtime alias로만 읽는다.

| 값 | 표시명 | 효과 | 비고 |
|---|---|---|---|
| `line_mark` | 라인 각인 | 포함 줄 확정 시 점수 +10% | 타일 seal 값 |
| `growth_seal` | 성장 각인 | 포함 줄 확정 시 해당 족보 성장 +1 | 타일 seal 값 |
| `gold_seal` | 금빛 각인 | 포함 줄 확정 시 Gold +1 | 타일 seal 값 |
| `echo_seal` | 메아리 각인 | 같은 확정에서 두 줄 이상에 기여하면 포함 줄마다 점수 +25% | 타일 seal 값 |
| `anchor_seal` | 닻 각인 | 이번 Station에 보드 이동한 뒤 포함 확정 시 점수 +20% | 타일 seal 값 |
| `fracture_seal` | 균열 각인 | 포함 줄 확정 시 점수 +50%, 확정 뒤 각인이 붙은 이 타일 자신 제거 | 타일 seal 값, legacy `risk_seal` 저장값만 alias로 읽음 |
| `bridge_seal` | 다리 표식 | 겹친 줄 확정 시 포함 줄마다 Gold +2 | 타일 seal 값 |

### 7.4 Fate Transform / Line Conversion

운명 변환 카드는 유저가 고른 보드 선 5칸을 실제 타일 세트로 치환한다. 임시 override가 아니라 board state가 바뀌고, 적용 직후 evaluator가 새 족보를 다시 판정한다.

운명 변환 카드는 normal market에 노출되더라도 common/uncommon 등급으로 풀지 않는다. 모든 운명 변환 카드는 rare 이상으로 유지하고, 로얄/스티플/숨은 상위 족보 계열은 legendary 고가 카드로 둔다.

| ID | 표시명 | rarity | price | 대상 | 결과 | 설계 의도 |
|---|---|---:|---:|---|---|---|
| `trim_rank` | 투페어 운명 | rare | 11 | 보드 선 1개 | 최고 숫자와 차순위 높은 숫자 기준 투페어 세트로 변환 | 낮은 단계 변환 |
| `line_pruner` | 하위 트리플 운명 | rare | 12 | 보드 선 1개 | 차순위 낮은 숫자 트리플 세트로 변환 | 트리플 하위 기준 |
| `fate_three_kind_high` | 상위 트리플 운명 | rare | 12 | 보드 선 1개 | 최고 숫자 트리플 세트로 변환 | 트리플 상위 기준 |
| `color_concord` | 상위 포카드 운명 | rare | 15 | 보드 선 1개 | 최고 숫자 기준 포카드 세트로 변환 | 숫자 빌드 강화 |
| `step_rite` | 하위 포카드 운명 | rare | 15 | 보드 선 1개 | 최저 숫자 기준 포카드 세트로 변환 | 하위 숫자 회수 |
| `rank_concord` | 상위 풀하우스 운명 | rare | 15 | 보드 선 1개 | 최고 숫자 triple + 차순위 높은 숫자 pair | 풀하우스 상위 기준 |
| `fate_full_house_low` | 하위 풀하우스 운명 | rare | 15 | 보드 선 1개 | 차순위 낮은 숫자 triple + 최고 숫자 pair | 풀하우스 하위 기준 |
| `flush_house_fate` | 플러시 하우스 운명 | legendary | 20 | 보드 선 1개 | 같은 색 풀하우스 세트로 변환 | hidden 상위 족보 |
| `flush_five_fate` | 플러시 파이브 운명 | legendary | 22 | 보드 선 1개 | 같은 색 같은 숫자 5장으로 변환 | hidden 최상위 족보 |
| `fate_flush_high` | 상위 플러시 운명 | rare | 14 | 보드 선 1개 | 최고 숫자 색상 기준 플러시 세트로 변환 | 색 빌드 |
| `fate_flush_low` | 하위 플러시 운명 | rare | 14 | 보드 선 1개 | 최저 숫자 색상 기준 플러시 세트로 변환 | 색 빌드 하위 기준 |
| `fate_straight_high` | 상행 스트레이트 운명 | rare | 13 | 보드 선 1개 | 최고 숫자 기준 높은 스트레이트 세트로 변환 | 스트레이트 상위 기준 |
| `fate_straight_low` | 하행 스트레이트 운명 | rare | 13 | 보드 선 1개 | 최저 숫자 기준 낮은 스트레이트 세트로 변환 | 스트레이트 하위 기준 |
| `wild_thread` | 상행 스티플 운명 | legendary | 18 | 보드 선 1개 | 최고 숫자/색상 기준 높은 스티플 세트로 변환 | 상위 고가 변환 |
| `off_color_rite` | 하행 스티플 운명 | legendary | 17 | 보드 선 1개 | 최저 숫자/색상 기준 낮은 스티플 세트로 변환 | 상위 고가 변환 |
| `number_mask` | 로얄 운명 | legendary | 20 | 보드 선 1개 | 1 타일 색상 우선, 없으면 최고 숫자 색상 기준 `10-11-12-13-1` 로얄 세트 | 로얄 변환 |

### 7.5 Prune / Sacrifice / Compression

압축/제물 카드는 손패를 직접 파괴하지 않는다. 선택한 보드 줄 또는 그 안의 타일을 대상으로 하며, 덱 제거는 즉시 삭제보다 확인 가능한 pending 후보로 남기는 것을 기본으로 한다.

| ID | 표시명 | rarity | price | 대상 | 결과 | 설계 의도 |
|---|---|---:|---:|---|---|---|
| `line_pruner` | 가지치기 의식 | rare | 12 | 선택한 완성 줄의 타일 1장 | 같은 타일을 즉시 덱 제거로 기록, Gold +2 | 덱 압축 |
| `trim_color` | 색 가지치기 | uncommon | 8 | 선택한 보드 선의 기준 색 타일 1장 | 선택 색이 아닌 보드 타일을 제거하고 같은 수의 기준색 타일을 덱 맨 위에 추가 | 색 정렬/다음 드로우 준비 |
| `trim_rank` | 숫자 가지치기 | rare | 11 | 선택한 완성 줄의 타일 1장 | 같은 숫자 타일 1장을 즉시 덱 제거로 기록 | 숫자 편중 관리 |
| `deadwood_burn` | 마른가지 소각 | rare | 10 | 유저가 고른 미확정/실패 줄 1개 | 해당 줄의 보드 타일을 비우고 Gold +3. 점수 확정은 하지 않음 | 실패 라인 회수 |
| `sacrifice_line` | 제물 의식 | legendary | 15 | 선택한 보드 선 1개 | 그 줄을 지우고 보이는 타일 2장을 덱 맨 위에 복사 | 고위험 즉시 덱 보충 |

### 7.6 Geometry / Board State

위치 의식은 보드 좌표 자체를 선택하게 한다. "중앙 포함이면 알아서 보너스"가 아니라, 조건을 만족하는 줄/타일만 활성 target으로 보여준다.

| ID | 표시명 | rarity | price | 대상 | 결과 | 설계 의도 |
|---|---|---:|---:|---|---|---|
| `cross_rite` | 교차 의식 | rare | 11 | 선택한 교차 타일 1개와 row/col 중 유저가 고른 줄 | 고른 줄 점수 +25%, 반대 방향 줄은 다음 확정 때 +10% marker | 교차점 가치 상승 |
| `corner_rite` | 모서리 의식 | uncommon | 8 | 모서리 타일을 포함한 선택 줄 1개 | 선택 줄의 끝점 타일 1장을 덱에 복사 | 배치 위치 의미 |
| `center_rite` | 중심 의식 | uncommon | 8 | 중앙 타일을 포함한 선택 줄 1개 | 선택 줄의 현재 족보 성장 +1 | 중앙 싸움 유도 |
| `diagonal_rite` | 대각 의식 | rare | 10 | 선택한 대각선 완성 줄 1개 | 이번 확정에서 해당 줄 점수 +35% | row/col 반복 완화 |
| `bridge_rite` | 다리 의식 | rare | 12 | 두 줄이 공유하는 선택 타일 1개 | 해당 타일에 `bridge_seal` 부여. 겹친 줄 확정 시 포함 줄마다 Gold +2 | overlap 경제 보상 |

### 7.7 Market / Pool Mutation

마켓형 의식은 전투 target이 없지만, 효과 결과가 다음 Market에서 visible badge로 표시되어야 한다.

| ID | 표시명 | rarity | price | 대상 | 결과 | 설계 의도 |
|---|---|---:|---:|---|---|---|
| `ritual_coupon` | 의식 쿠폰 | common | 5 | 다음 Market | 다음 Ritual 계열 첫 구매 가격 -2G | 새 family 진입 완화 |
| `ritual_lens` | 의식 렌즈 | uncommon | 7 | 다음 Market | Ritual 후보 출현 가중치 증가, 후보 카드에 `Lens` badge 표시 | 빌드 방향 선택 |
| `line_pack_ticket` | 라인 팩 티켓 | rare | 10 | 다음 Market | 완성 줄 기반 Ritual 3택1 pack 후보 1개 추가 | pack 확장 |
| `seal_vendor` | 각인 상인 | uncommon | 8 | 다음 Market | seal/enhancement Ritual 후보 가중치 증가 | modifier 빌드 지원 |
| `prune_vendor` | 정리 상인 | uncommon | 8 | 다음 Market | prune/compression Ritual 후보 가중치 증가 | 압축 빌드 지원 |

## 8. Legacy Draft Notes

과거 Draft 18 / Reserve / Later 표는 현재 source-of-truth가 아니다. 현재 실행 판단은 이 문서 상단의 active/hold 분류와 `CURRENT_CARD_CATALOG_TABLE.md`, `ITEM_EFFECT_RUNTIME_MATRIX.md`를 따른다.

폐기된 구 기준:

- `*_seal`, `*_stamp` 계열을 운명 카드 ID로 쓰던 계획은 폐기했다. 운명 변환 카드는 `fate_*` 또는 명확한 변환 ID를 쓴다.
- `rank_concord`, `step_rite` 같은 temporary override 계획은 폐기했다. 현재 운명 카드는 선택 보드 선 5칸을 실제 타일 세트로 치환한다.
- 삭제된 기억 의식 3종은 catalog/runtime에서 제거했다.
- `ritual_coupon`, `ritual_lens`, `line_pack_ticket`, `seal_vendor`, `prune_vendor`는 마켓 보조 의식으로 재설계 전까지 normal market에 넣지 않는다.

## 9. Runtime Capability Contract

현재 capability는 카드군별로 아래처럼 본다.

| Capability | 포함 카드 | 상태 변화 | 저장 대상 | 표시 대상 |
|---|---|---|---|---|
| fate transform | 운명 변환 16종 | 선택 보드 선 5칸을 실제 타일 세트로 치환 | board state | 선택 선, 변환 전후 타일, 확정 preview |
| deck add | `sealed_copy`, `scarce_copy`, `color_echo`, `rank_echo`, `edge_copy`, `keystone_copy` | scoringTiles 기반 타일을 `addedDeckTiles`와 session deck top에 추가 | runProgress `addedDeckTiles`, session deck top | 덱 변화 flight, 다음 draw 반영 |
| prune / burn / sacrifice | `trim_color`, `deadwood_burn`, `sacrifice_line` | 보드 선 제거, 골드/덱 보충 | board state, deck top, gold | 제거 line, 골드 flight, 덱 flight |
| growth / geometry / marker | `line_memory`, `bridge_rite`, `diagonal_rite`, `center_rite`, `corner_rite`, `cross_rite`, `cross_memory` | 위치 조건에 따른 성장, 점수, 복사, 표식 보상. `line_memory`는 `ritual_line_effect`가 아닌 별도 선 성장형 quickSlot이다. | 선택 결과별 runtime/runProgress | 중앙/대각/교차/모서리/겹친 줄 highlight |
| hold / redesign | 마켓 보조 의식 5종 | normal market 제외 | catalog 검토 자산만 유지 | 별도 재설계 후 |

## 10. Policy Update Order

이제 정책 수정 순서는 아래로 바꾼다.

1. 새 카드 pool과 1차 catalog draft를 먼저 확정한다.
2. 각 카드가 요구하는 runtime capability를 역으로 도출한다.
3. 그 capability 기준으로 `use_battle_select_line`, 저장/복원, 전투 표시, 정산 표시 정책을 쓴다.
4. ML/시뮬레이션/풀런봇 계약은 마지막에 붙인다.
