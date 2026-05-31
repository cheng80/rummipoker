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

현재는 Board-Line Ritual 38종을 실제 catalog에 추가해 총 92개 아이템 상태다. 따라서 다음 catalog 확장은 단순 점수 보정 아이템을 더 늘리는 일이 아니라, 추가된 Ritual 38종이 아래 기준을 만족하는지 닫는 작업이다.

- 효과별 target 조건이 유저에게 읽히는가.
- 적용 결과가 board/deck/growth/seal/run info/log에 남는가.
- `ritual_lens`, `ritual_coupon`, `seal_vendor`, `prune_vendor`, `line_pack_ticket`이 단순 할인/후보 수 변경처럼 약하게 보이지 않는가.
- 38종 전부를 한 번에 pool에 넣은 상태에서 희귀도/가격/출현 weight가 과하지 않은가.

## 2. 분류 기준

| Family | 설명 | 이번 정화 판단 |
|---|---|---|
| `Hand-Rank Growth` | 특정 족보 레벨을 올리는 Planet-like 축 | 유지. 단 next-confirm 임시 보정과 섞지 않는다. |
| `Confirm / Score Modifier` | 다음 확정 또는 조건부 확정 점수 보정 | 이미 많음. 추가 억제. 조건/대상/연출 없는 항목은 정리 후보. |
| `Resource / Board Action` | 손패, 보드 버림, 이동, 되돌리기, 덱 확인 | 유지. 풀런봇 정책과 UI 피드백 기준으로 가치 재점검. |
| `Market / Economy / Pool` | 할인, 골드, 후보 교체, 후보 수/가격 조정 | 유지하되 자동 지급처럼 보이는 항목은 조건/표시 보강. |
| `Survival` | 실패 방지/구제 | 희소하게 유지. 자동 완화처럼 보이지 않게 표시 필요. |
| `Board-Line Ritual` | 보드 라인을 재료로 복제/각인/변형/압축 | 현재 catalog 0개. 새 덱빌딩 다양성의 1순위. |
| `Direct Tile Modifier Item` | 타일 enhancement/seal/edition 직접 부여 | 현재 catalog 0개. 특수 타일 시스템과 연결해 확장. |

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
| `emergency_draw` | 손패 비었을 때 드로우 | 유지 |
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

기준점 당시 catalog에는 0개였고, 다음 확장 1순위였다. 현재는 38종이 실제 catalog/runtime/번역/이미지 경로에 들어갔다.

초기 9개 후보는 부족하다는 판단으로 폐기했고, 설계 pool 38종 전체를 먼저 연결했다. 기존 Draft/Reserve/Later 표는 “구현 순서 후보” 기록으로만 보고, 현재 실행 판단은 아래 V1 QA/정책 정리 기준을 따른다.

| 우선 | 후보 | 이유 |
|---|---|---|
| P0 | `line_memory` | 저장/점수/UI 리스크 낮음. 족보 성장과 바로 연결 |
| P0 | `keystone_copy` | `addedDeckTiles` 경로 재사용 가능 |
| P0 | `line_seal_stamp` | 특수 타일 modifier UI와 연결 |
| P1 | `minor_memory` | 주력 족보 반복 완화 |
| P1 | `edge_copy` | 라인 endpoint 의미 부여 |
| P1 | `growth_seal` | 타일과 성장 연결 |
| P1 | `gold_seal_stamp` | 경제 빌드 축 추가 |
| P2 | `rank_concord` | 숫자 족보 route 강화, 판정 혼란 리스크 |
| P2 | `line_pruner` | 덱 압축, 영구 제거 정책 필요 |

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
3. 완료: Board-Line Ritual 후보 38종을 실제 catalog에 추가했다.
4. 완료: 성장, 복사, 각인, 족보 강제 판정, 압축/제거 후보, 보드 선 제거/회수, geometry, market 보조 계열을 `ritual_line_effect`/`ritualAction` 또는 기존 market op로 연결했다.
5. 완료: Ritual line target을 scoring line 밖의 보드 선까지 확장했다. 효과별 target 조건은 점수 족보 선, 타일 3개 이상 보드 선, 보드 선 안의 타일로 나뉜다.
6. 완료: 전투 선택 UI는 보드 미니 프리뷰 + line choice chip dialog로 교체했고, 다국어 효과 문구도 현재 조건에 맞게 정리했다.
7. 현재 우선순위: 새 카드 추가가 아니라 V1 QA/정책 정리다.

### 5.1 Ritual V1 다음 작업

1. 대표 8종 이상 눈검증:
   - `line_memory`, `thin_memory`: 점수 족보 선 성장.
   - `keystone_copy`, `edge_copy`, `rank_echo`: 보드 선 기반 덱 추가.
   - `line_seal_stamp`, `gold_seal_stamp`, `growth_seal`: 타일 각인/정산 발동.
   - `rank_concord`, `step_rite`, `number_mask`: 타일 3개 이상 보드 선 강제 판정.
   - `deadwood_burn`, `sacrifice_line`: 보드 선 제거/회수.
2. result communication 보강:
   - item source, target board line, result delta가 한 흐름으로 보이는지 확인한다.
   - 부족하면 line flash, result panel, toast/callout, run info delta를 보강한다.
3. run info/log 보강:
   - `addedDeckTiles`, 제거 후보, seal/marker, hand-rank growth가 런 정보와 trace에서 확인되는지 본다.
4. market 보조 계열 재검토:
   - `ritual_lens`, `ritual_coupon`, `seal_vendor`, `prune_vendor`, `line_pack_ticket`은 지금 효과가 기존 할인/후보 수 변경 op를 재사용하므로 Ritual family 정체성이 약할 수 있다.
5. balance watch:
   - `wild_thread`, `number_mask`, `sacrifice_line`, `risk_seal`은 효과가 강하고 손실/보상이 커서 가격/희귀도/출현률을 소규모 fresh run으로 본다.

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
- 손패 직접 파괴/변형은 V1 금지다. 보드 라인, 덱 추가/제거 후보, 타일 각인/강화, 족보 성장으로 우회한다.

## 7. New Item Card Candidate Pool

아래 후보는 “추가 가능 카드 pool”이다. 바로 런타임에 넣는 확정 JSON이 아니라, 다음 catalog draft의 후보군이다.

### 7.1 Line Memory / Growth

Ritual 성장 카드는 자동으로 "가장 강한/약한/대표" 줄을 고르지 않는다. 기본 입력은 유저가 직접 고른 완성 줄이고, 그 줄의 현재 족보가 성장 대상이 된다.

| ID | 표시명 | rarity | price | 대상 | 결과 | 설계 의도 |
|---|---|---:|---:|---|---|---|
| `line_memory` | 라인 기억 | uncommon | 7 | 선택한 완성 줄 1개 | 그 줄의 현재 족보 성장 +1 | 유저가 고른 족보를 run-long 성장으로 연결 |
| `minor_memory` | 잔상 기억 | rare | 9 | 선택한 완성 줄 1개 | 그 줄의 현재 족보 성장 +2, 이번 확정 점수 -25% | 고성장 리스크 선택 |
| `cross_memory` | 교차 기억 | rare | 10 | 교차 타일 1개와 row/col 중 유저가 고른 완성 줄 1개 | 고른 줄의 현재 족보 성장 +1, 교차 타일에 `cross_memory` 표식 | 교차 빌드 유도 |
| `thin_memory` | 얇은 기억 | common | 6 | 3~4타일로도 scoring 가능한 선택 줄 1개 | 그 줄의 현재 족보 성장 +1, 이번 확정 점수 -10% | 작은 라인 활용 |
| `boss_memory` | 보스 기억 | rare | 11 | 보스전에서 선택한 완성 줄 1개 | 그 줄의 현재 족보 성장 +2 | 위험 전투 보상 |

### 7.2 Copy / Deck Injection

복사 카드는 "조건에 맞는 타일을 자동 선택"하지 않는다. 줄을 먼저 고르고, 그 안에서 복사 타일을 직접 고르는 2단계 UX를 기본으로 한다.

| ID | 표시명 | rarity | price | 대상 | 결과 | 설계 의도 |
|---|---|---:|---:|---|---|---|
| `keystone_copy` | 중심석 복사 | uncommon | 8 | 선택한 완성 줄의 가운데 타일 | 같은 타일 1장을 덱에 추가 | 핵심 타일 중심 덱빌딩 |
| `edge_copy` | 끝점 복사 | common | 6 | 선택한 완성 줄의 양끝 중 유저가 고른 타일 1장 | 같은 타일 1장을 덱에 추가 | 위치 의미 부여 |
| `rank_echo` | 숫자 메아리 | uncommon | 8 | 선택한 완성 줄의 타일 1장 | 같은 숫자, 무작위 색 타일 1장을 덱에 추가 | 숫자 족보 강화 |
| `color_echo` | 색 메아리 | uncommon | 8 | 선택한 완성 줄의 타일 1장 | 같은 색, 무작위 숫자 타일 1장을 덱에 추가 | 색 빌드 지원 |
| `scarce_copy` | 희소석 복사 | rare | 10 | 선택한 완성 줄의 타일 1장 | 현재 덱에 같은 색/숫자가 적으면 같은 타일 1장을 덱에 추가 | 덱 편중 완화 |
| `sealed_copy` | 각인 복사 | rare | 12 | 선택한 완성 줄의 각인/강화 타일 1장 | 같은 타일 1장을 덱에 추가하되 seal/enhancement는 한 단계 약화 | modifier 빌드 지원 |

### 7.3 Seal / Enhancement

각인 카드는 선택 줄 안의 타일 1개를 직접 고르게 한다. 각인은 전투 화면 타일 badge와 long-press 상세에서 읽혀야 한다.

| ID | 표시명 | rarity | price | 대상 | 결과 | 설계 의도 |
|---|---|---:|---:|---|---|---|
| `line_seal_stamp` | 라인 각인 | uncommon | 8 | 선택한 완성 줄의 타일 1장 | `line_mark` 각인 부여. 포함 줄 확정 시 칩 +10% | Ritual 기본 감각 |
| `growth_seal` | 성장 각인 | rare | 10 | 선택한 완성 줄의 타일 1장 | 포함 줄 확정 시 그 족보 성장 +1 후 각인 소비 | 타일과 성장 연결 |
| `gold_seal_stamp` | 금빛 각인 | uncommon | 8 | 선택한 완성 줄의 타일 1장 | 포함 줄 확정 시 Gold +1 후 각인 소비 | 경제 빌드 축 |
| `echo_seal` | 메아리 각인 | rare | 10 | 선택한 완성 줄의 타일 1장 | 같은 확정에서 두 줄 이상에 기여하면 두 번째 줄 점수 +25% | overlap 유도 |
| `anchor_seal` | 닻 각인 | uncommon | 7 | 선택한 완성 줄의 타일 1장 | 이후 보드 이동 후 포함 줄 확정 시 배수 +0.2 | 이동 아이템 연계 |
| `risk_seal` | 균열 각인 | legendary | 14 | 선택한 완성 줄의 타일 1장 | 포함 줄 확정 시 배수 +0.5, 확정 뒤 해당 타일은 덱 제거 후보 | Spectral-like tradeoff |

### 7.4 Hand-Rank Override / Conversion

변환 카드는 유저가 효과 강도를 읽기 쉽게, 선택한 완성 줄을 특정 족보로 강제 판정한다. 실제 타일 값을 영구 변경하지 않고 이번 확정 preview/settlement에만 override를 건다.

| ID | 표시명 | rarity | price | 대상 | 결과 | 설계 의도 |
|---|---|---:|---:|---|---|---|
| `rank_concord` | 숫자 맞춤 의식 | rare | 11 | 선택한 완성 줄 1개 | 이번 확정에서 `Three of a Kind`로 강제 판정 | 숫자 족보 지원 |
| `step_rite` | 계단 의식 | uncommon | 9 | 선택한 완성 줄 1개 | 이번 확정에서 `Straight`로 강제 판정 | straight 지원 |
| `color_concord` | 색 맞춤 의식 | rare | 11 | 선택한 완성 줄 1개 | 이번 확정에서 `Flush`로 강제 판정 | 색 빌드 지원 |
| `off_color_rite` | 이색 의식 | rare | 12 | 선택한 완성 줄 1개 | 이번 확정에서 `Full House`로 강제 판정 | flush 일변도 완화와 숫자/색 혼합 보상 |
| `wild_thread` | 만능 실 | rare | 13 | 선택한 완성 줄 1개 | 이번 확정에서 `Four of a Kind`로 강제 판정 | 고위험 숫자 빌드 보상 |
| `number_mask` | 숫자 가면 | legendary | 15 | 선택한 완성 줄 1개 | 이번 확정에서 `Five of a Kind`로 강제 판정, 확정 뒤 선택 줄 타일 1장 제거 후보 | 강한 Spectral-like 변형 |

### 7.5 Prune / Sacrifice / Compression

압축/제물 카드는 손패를 직접 파괴하지 않는다. 선택한 보드 줄 또는 그 안의 타일을 대상으로 하며, 덱 제거는 즉시 삭제보다 확인 가능한 pending 후보로 남기는 것을 기본으로 한다.

| ID | 표시명 | rarity | price | 대상 | 결과 | 설계 의도 |
|---|---|---:|---:|---|---|---|
| `line_pruner` | 가지치기 의식 | rare | 10 | 선택한 완성 줄의 타일 1장 | 같은 타일을 덱 제거 후보로 기록, Gold +2 | 덱 압축 |
| `trim_color` | 색 가지치기 | uncommon | 8 | 선택한 완성 줄의 타일 1장 | 같은 색 타일 1장을 덱 제거 후보로 기록 | 색 편중 관리 |
| `trim_rank` | 숫자 가지치기 | uncommon | 8 | 선택한 완성 줄의 타일 1장 | 같은 숫자 타일 1장을 덱 제거 후보로 기록 | 숫자 편중 관리 |
| `deadwood_burn` | 마른가지 소각 | rare | 10 | 유저가 고른 미확정/실패 줄 1개 | 해당 줄의 보드 타일을 비우고 Gold +3. 점수 확정은 하지 않음 | 실패 라인 회수 |
| `sacrifice_line` | 제물 의식 | legendary | 15 | 선택한 완성 줄 1개 | 이번 확정 점수를 0으로 만들고, 그 줄 타일 2장을 덱에 복사한 뒤 1장을 제거 후보로 기록 | 고위험 선택 |

### 7.6 Geometry / Board State

위치 의식은 보드 좌표 자체를 선택하게 한다. "중앙 포함이면 알아서 보너스"가 아니라, 조건을 만족하는 줄/타일만 활성 target으로 보여준다.

| ID | 표시명 | rarity | price | 대상 | 결과 | 설계 의도 |
|---|---|---:|---:|---|---|---|
| `cross_rite` | 교차 의식 | rare | 11 | 선택한 교차 타일 1개와 row/col 중 유저가 고른 줄 | 고른 줄 점수 +25%, 반대 방향 줄은 다음 확정 때 +10% marker | 교차점 가치 상승 |
| `corner_rite` | 모서리 의식 | uncommon | 8 | 모서리 타일을 포함한 선택 줄 1개 | 선택 줄의 끝점 타일 1장을 덱에 복사 | 배치 위치 의미 |
| `center_rite` | 중심 의식 | uncommon | 8 | 중앙 타일을 포함한 선택 줄 1개 | 선택 줄의 현재 족보 성장 +1 | 중앙 싸움 유도 |
| `diagonal_rite` | 대각 의식 | rare | 10 | 선택한 대각선 완성 줄 1개 | 이번 확정에서 해당 줄 점수 +35% | row/col 반복 완화 |
| `bridge_rite` | 다리 의식 | rare | 12 | 두 줄이 공유하는 선택 타일 1개 | 해당 타일에 `bridge` marker 부여. 이후 두 줄 모두 확정되면 Gold +3 | 미래 확정 설계 |

### 7.7 Market / Pool Mutation

마켓형 의식은 전투 target이 없지만, 효과 결과가 다음 Market에서 visible badge로 표시되어야 한다.

| ID | 표시명 | rarity | price | 대상 | 결과 | 설계 의도 |
|---|---|---:|---:|---|---|---|
| `ritual_coupon` | 의식 쿠폰 | common | 5 | 다음 Market | 다음 Ritual 계열 첫 구매 가격 -2G | 새 family 진입 완화 |
| `ritual_lens` | 의식 렌즈 | uncommon | 7 | 다음 Market | Ritual 후보 출현 가중치 증가, 후보 카드에 `Lens` badge 표시 | 빌드 방향 선택 |
| `line_pack_ticket` | 라인 팩 티켓 | rare | 10 | 다음 Market | 완성 줄 기반 Ritual 3택1 pack 후보 1개 추가 | pack 확장 |
| `seal_vendor` | 각인 상인 | uncommon | 8 | 다음 Market | seal/enhancement Ritual 후보 가중치 증가 | modifier 빌드 지원 |
| `prune_vendor` | 정리 상인 | uncommon | 8 | 다음 Market | prune/compression Ritual 후보 가중치 증가 | 압축 빌드 지원 |

## 8. First Catalog Draft Target (Historical)

후보 pool은 38종이다. 이 섹션은 38종 전체를 catalog에 넣기 전의 18종 draft 계획 기록이다. 현재 실행 판단은 위 `5.1 Ritual V1 다음 작업`을 따른다.

권장 1차 구성:

```text
Line Memory / Growth: 4
Copy / Deck Injection: 4
Seal / Enhancement: 4
Color / Number Conversion: 2
Prune / Compression: 2
Geometry / Board State: 1
Market / Pool Mutation: 1
```

1차 추천 18종:

```text
line_memory
minor_memory
thin_memory
boss_memory
keystone_copy
edge_copy
rank_echo
scarce_copy
line_seal_stamp
growth_seal
gold_seal_stamp
anchor_seal
rank_concord
step_rite
line_pruner
trim_color
center_rite
ritual_lens
```

뒤로 미룰 후보:

- `risk_seal`, `sacrifice_line`: 손실 tradeoff가 커서 UI/undo/보상 설명이 필요하다.
- `line_transmute`, `mirror_line`, `void_mark`: 밸런스 파괴 리스크가 크다.
- `wild_thread`, `number_mask`: evaluator와 preview 설명이 먼저 필요하다.
- `line_pack_ticket`: pack UI가 아직 없다.

## 9. Candidate Decision Table (Historical)

38종 후보를 1차 draft 관점에서 다시 분류한다.

판정:

- `Draft`: 첫 catalog draft에 넣는다.
- `Reserve`: pool에는 유지하지만 첫 draft에서는 보류한다.
- `Later`: 새 UI/룰 capability가 필요해 후순위다.
- `Reject V1`: V1에서는 넣지 않는다.

| ID | 판정 | 이유 | 다음 조치 |
|---|---|---|---|
| `line_memory` | Draft | 가장 단순한 selected line -> 족보 성장 연결 | 선택 줄 UX와 성장 피드백 확정 |
| `minor_memory` | Draft | 같은 선택 UX에서 성장량과 점수 손실 tradeoff가 명확 | 점수 손실 preview와 확정 toast 필요 |
| `cross_memory` | Reserve | 교차 빌드 의도는 좋지만 target 선택이 복잡 | row/col 동시 preview가 생긴 뒤 재검토 |
| `thin_memory` | Draft | 작은 라인 활용, 초반 선택 다양화 | 3~4타일 scoring 기준 확정 |
| `boss_memory` | Draft | 보스전 보상성 명확 | 보스전 전용 표시 필요 |
| `keystone_copy` | Draft | 덱빌딩 체감이 크고 구현 경로가 비교적 명확 | 가운데 타일 복사 기준 검증 |
| `edge_copy` | Draft | 위치 의미 부여, 구현 단순 | endpoint 선택 UI 단순화 |
| `rank_echo` | Draft | 선택 타일 숫자를 직접 복사하므로 효과가 읽힘 | 같은 숫자/무작위 색 생성 규칙 표시 |
| `color_echo` | Reserve | flush 강화 가능성이 커 첫 draft에서는 감시 | flush 고착 완화 후보와 함께 재검토 |
| `scarce_copy` | Draft | 덱 편중 완화라 장기성 좋음 | 현재 덱 색/숫자 scarcity 계산 필요 |
| `sealed_copy` | Reserve | modifier 빌드 후속으로 좋지만 선행 seal 카드 필요 | seal 카드 안정 후 투입 |
| `line_seal_stamp` | Draft | Ritual 정체성, modifier UI와 직접 연결 | `line_mark` 효과값 확정 |
| `growth_seal` | Draft | 타일과 족보 성장을 연결 | seal 소비/잔존 규칙 확정 |
| `gold_seal_stamp` | Draft | 경제 축 추가, 이해 쉬움 | Gold +1 상한/발동 빈도 검토 |
| `echo_seal` | Reserve | overlap 빌드와 잘 맞지만 설명 난이도 있음 | overlap 표시 강화 뒤 재검토 |
| `anchor_seal` | Draft | 보드 이동 아이템과 연결 | 이동 후 flag 유지 범위 확정 |
| `risk_seal` | Later | tradeoff는 좋지만 손실 설명/보상 UX 필요 | 고위험 family로 별도 설계 |
| `rank_concord` | Draft | 줄을 특정 족보로 강제 판정해 효과가 큼 | Three of a Kind override 표시 필요 |
| `step_rite` | Draft | 줄을 Straight로 강제해 선택 가치가 명확 | Straight override 표시 필요 |
| `color_concord` | Reserve | flush 보정은 유용하지만 고착 위험 | off-color 계열과 묶어서 재검토 |
| `off_color_rite` | Reserve | flush 일변도 완화 의도는 좋음 | 유저가 왜 색을 깨는지 보상 명확화 필요 |
| `wild_thread` | Later | Four of a Kind 강제 판정은 강력해서 preview/밸런스 검증 필요 | hand-rank override 상위권 검증 후 |
| `number_mask` | Later | Five of a Kind 강제 판정은 손실 tradeoff까지 설명해야 함 | 고위험 override UX 설계 후 |
| `line_pruner` | Draft | 덱 압축 축을 열어야 함 | 제거 후보/확정 제거 타이밍 확정 |
| `trim_color` | Draft | 색 편중 관리 | 과다 색 계산 기준 확정 |
| `trim_rank` | Reserve | 숫자 편중 관리지만 trim_color와 역할 중복 | trim_color 반응 확인 후 |
| `deadwood_burn` | Later | 실패 라인 회수는 좋지만 target 정의가 다름 | dead line/failed line UI 필요 |
| `sacrifice_line` | Reject V1 | 점수 포기/손실감이 큼 | V2 고위험 의식 후보 |
| `cross_rite` | Reserve | 교차점 가치는 좋지만 UI 복잡 | center_rite 이후 |
| `corner_rite` | Reserve | 위치 의미는 좋지만 우선순위 낮음 | geometry 확장 때 |
| `center_rite` | Draft | 위치 기반 첫 카드로 적당 | 중앙 포함 line 판정 |
| `diagonal_rite` | Reserve | 대각 활용은 좋지만 target 후보 적음 | 대각 highlight 안정 후 |
| `bridge_rite` | Later | 미완성 라인 marker는 새 상태가 필요 | future-line marker 설계 필요 |
| `ritual_coupon` | Reserve | 할인만으로는 새 family의 재미가 약함 | ritual_lens 반응 후 |
| `ritual_lens` | Draft | Market에서 빌드 방향을 선택하게 함 | 다음 Market family weight 저장 |
| `line_pack_ticket` | Later | pack UI가 아직 없음 | pack/choice offer 설계 후 |
| `seal_vendor` | Reserve | modifier 빌드 지원 | seal 카드 안정 후 |
| `prune_vendor` | Reserve | 압축 빌드 지원 | prune 카드 안정 후 |

### Draft 18 (Historical)

첫 catalog draft는 아래 18종으로 본다.

```text
line_memory
minor_memory
thin_memory
boss_memory
keystone_copy
edge_copy
rank_echo
scarce_copy
line_seal_stamp
growth_seal
gold_seal_stamp
anchor_seal
rank_concord
step_rite
line_pruner
trim_color
center_rite
ritual_lens
```

### Draft 18 Effect Contract (Historical)

이 표는 구현 전 효과 계약이다. 실제 JSON 반영 전 이름/가격/수치는 한 번 더 잠근다.

| ID | effect family | target | result | required capability |
|---|---|---|---|---|
| `line_memory` | rank_growth | selected completed line | 선택한 완성 줄의 현재 족보 성장 +1 | selected-line hand-rank resolver |
| `minor_memory` | rank_growth | selected completed line | 선택한 완성 줄의 현재 족보 성장 +2, 이번 확정 점수 -25% | selected-line risk growth resolver |
| `thin_memory` | rank_growth | selected 3~4 tile scoring line | 선택 줄의 현재 족보 성장 +1, 이번 확정 점수 -10% | partial-line scorer |
| `boss_memory` | rank_growth | selected boss completed line | 보스전에서 선택한 완성 줄의 현재 족보 성장 +2 | boss-only selected-line condition |
| `keystone_copy` | deck_add | selected completed line center tile | 가운데 타일 1장을 덱에 추가 | selected-cell copy resolver |
| `edge_copy` | deck_add | selected completed line endpoint tile | 유저가 고른 끝점 타일 1장을 덱에 추가 | endpoint tile selection |
| `rank_echo` | deck_add | selected completed line tile | 같은 숫자, 무작위 색 타일 1장을 덱에 추가 | rank copy resolver |
| `scarce_copy` | deck_add | selected completed line tile | 덱에 같은 색/숫자가 적으면 같은 타일 1장을 덱에 추가 | deck composition analyzer |
| `line_seal_stamp` | seal_apply | selected line tile | `line_mark` 각인 부여. 포함 줄 확정 시 칩 +10% | tile seal write/display |
| `growth_seal` | seal_apply | selected line tile | 포함 줄 확정 시 족보 성장 +1 후 각인 소비 | seal trigger on settlement |
| `gold_seal_stamp` | seal_apply | selected line tile | 포함 줄 확정 시 Gold +1 후 각인 소비 | seal gold settlement |
| `anchor_seal` | seal_apply | selected line tile | 보드 이동 후 포함 확정 시 배수 +0.2 | moved-tile marker |
| `rank_concord` | hand_rank_override | selected completed line | 이번 확정에서 Three of a Kind로 강제 판정 | hand-rank override preview |
| `step_rite` | hand_rank_override | selected completed line | 이번 확정에서 Straight로 강제 판정 | hand-rank override preview |
| `line_pruner` | deck_remove_candidate | selected completed line tile | 같은 타일을 전투 후 덱 제거 후보로 기록, Gold +2 | deferred deck removal |
| `trim_color` | deck_remove_candidate | selected completed line tile | 같은 색 타일 1장을 제거 후보로 기록 | deck color distribution |
| `center_rite` | geometry_bonus | selected center-including line | 선택 줄의 현재 족보 성장 +1 | center line detector |
| `ritual_lens` | market_pool_weight | next market | 다음 Market Ritual 후보 출현 가중치 증가, 후보 badge 표시 | next-market family weight |

Draft 18 중 첫 구현 slice 권장:

```text
line_memory
thin_memory
keystone_copy
edge_copy
line_seal_stamp
gold_seal_stamp
line_pruner
ritual_lens
```

이 8종은 required capability가 비교적 분리되어 있고, 성장/복사/각인/압축/마켓 가중치를 모두 한 번씩 검증한다.

## 10. Runtime Capability Contract

Draft 18은 개별 구현보다 capability 단위로 먼저 나눈다. 같은 capability를 공유하는 카드를 묶어야 저장/표시/정산이 중복 구현되지 않는다.

### 10.1 Capability Groups

| Capability | 포함 카드 | 상태 변화 | 저장 대상 | 표시 대상 |
|---|---|---|---|---|
| line target selection | Draft 18 중 `ritual_lens` 제외 17종 | 전투 중 보드 라인/타일 target 선택 | 적용 완료 결과만 저장. targeting/preview는 저장하지 않음 | 선택 가능 라인, 선택 라인, preview panel |
| line hand-rank resolver | `line_memory`, `minor_memory`, `thin_memory`, `boss_memory` | `playedHandCounts` 또는 hand-rank progression 증가 | runProgress hand-rank growth | 전투 적용 toast, 런 정보 성장 표 |
| deck add | `keystone_copy`, `edge_copy`, `rank_echo`, `scarce_copy` | `addedDeckTiles`에 타일 추가 | runProgress `addedDeckTiles` | 덱 변화 badge, 런 정보 덱 추가 목록 |
| seal apply | `line_seal_stamp`, `growth_seal`, `gold_seal_stamp`, `anchor_seal` | board/deck tile에 seal 부여 | Tile `seal` field | 타일 badge, long-press 상세, 정산 발동 |
| hand-rank override | `rank_concord`, `step_rite` | 선택 줄의 이번 확정 족보 판정 override | 전투 runtime state. run save에는 적용 완료 후에도 영구 저장하지 않음 | 줄 override badge, 확정 preview |
| deck remove candidate | `line_pruner`, `trim_color` | 전투 후 제거할 덱 타일 후보 기록 | 적용 완료 시 pending remove list 또는 즉시 제거 결과 | 덱 압축 badge, 결과 panel |
| geometry bonus | `center_rite` | center 포함 라인에 성장/복사 보너스 | 선택 결과에 따라 growth 또는 deck add로 저장 | 중앙 라인 highlight |
| market pool weight | `ritual_lens` | 다음 Market Ritual 후보 가중치 증가 | runProgress next-market modifier | Market 후보 영역 badge |

### 10.2 Line Target Selection

`use_battle_select_line`은 Draft 18의 핵심 action이다.

상태 흐름:

```text
idle
-> item_selected
-> line_targeting
-> line_preview
-> confirm_apply
-> applying
-> idle
```

규칙:

- Ritual item을 누르면 바로 소비하지 않는다.
- 선택 가능한 line만 highlight한다.
- 빈칸, 불가능한 line, 일반 타일 tap은 item을 소모하지 않는다.
- preview에는 대상 line, 예상 결과, item 소모 여부를 보여준다.
- 적용 버튼을 누른 뒤에만 item을 소비한다.
- targeting/preview/dialog open 상태는 저장하지 않는다. 앱이 종료되면 idle로 복원되고 item은 남아 있어야 한다.

Target 후보:

| 조건 | 정책 |
|---|---|
| 3타일 이상 line | 기본 허용 후보 |
| 점수 성립 가능한 line | 우선 highlight |
| 현재 확정 preview에 포함된 line | 우선 highlight |
| 5칸 완성 line | 허용 |
| 1~2타일 line | V1 금지 |
| empty line | 금지 |
| 이미 적용 불가 상태의 line | 비활성 표시 |

Line 종류:

- row
- column
- main diagonal
- anti diagonal

V1 구현이 복잡하면 row/column부터 열 수 있다. 단 데이터 모델과 UI 용어는 diagonal까지 확장 가능해야 한다.

### 10.3 Save / Restore Policy

저장한다:

- item 소비 결과
- `addedDeckTiles` 변화
- hand-rank progression 변화
- Tile `seal` 변화
- 전투 후 확정된 deck remove 결과
- next-market Ritual 가중치

저장하지 않는다:

- line targeting 중인 선택 상태
- hover/highlight
- preview panel/dialog open state
- temporary conversion의 preview-only 상태

전투 한정 temporary conversion은 active battle state 안에서만 유지한다. confirm 또는 battle 종료 뒤에는 원본 타일 데이터와 분리되어야 한다.

### 10.4 Battle / Settlement Display Policy

적용 직후:

- item source card가 짧게 pulse한다.
- target line 전체가 highlight된다.
- result panel에 `족보 성장 +1`, `덱에 B10 추가`, `금빛 각인 부여`처럼 결과가 직접 표시된다.

정산 중:

- seal 발동은 tile modifier settlement step에서 보여준다.
- hand-rank growth는 성장 증가가 실제로 반영된 시점에 별도 callout을 띄운다.
- deck add/remove는 정산 끝 또는 battle result panel에서 덱 변화 요약으로 보여준다.

런 정보:

- 성장한 족보, 추가된 덱 타일, 각인/강화 타일, 다음 Market 가중치를 확인할 수 있어야 한다.
- Ritual 효과가 전투 중에만 보이고 run info에서 사라지면 덱빌딩 가치 전달 실패로 본다.

### 10.5 Capability Implementation Order

첫 구현 slice 8종 기준 권장 순서:

1. `use_battle_select_line` target shell
2. `line_memory`, `thin_memory`: line -> hand-rank growth
3. `keystone_copy`, `edge_copy`: line -> `addedDeckTiles`
4. `line_seal_stamp`, `gold_seal_stamp`: line tile -> seal apply/settlement
5. `line_pruner`: line -> deck remove candidate
6. `ritual_lens`: next Market family weight

이 순서가 닫히기 전에는 `rank_concord`, `step_rite` 같은 temporary conversion을 구현하지 않는다. conversion은 evaluator/preview 혼란이 크다.

### Reserve 13

```text
cross_memory
color_echo
sealed_copy
echo_seal
color_concord
off_color_rite
trim_rank
cross_rite
corner_rite
diagonal_rite
ritual_coupon
seal_vendor
prune_vendor
```

`ritual_coupon`, `seal_vendor`, `prune_vendor`는 Market pool family라 18종 draft 안정 후 2차 batch로 묶어 검토한다.

### Later / Reject

```text
risk_seal
wild_thread
number_mask
deadwood_burn
bridge_rite
line_pack_ticket
sacrifice_line
```

## 10. Policy Update Order

이제 정책 수정 순서는 아래로 바꾼다.

1. 새 카드 pool과 1차 catalog draft를 먼저 확정한다.
2. 각 카드가 요구하는 runtime capability를 역으로 도출한다.
3. 그 capability 기준으로 `use_battle_select_line`, 저장/복원, 전투 표시, 정산 표시 정책을 쓴다.
4. ML/시뮬레이션/풀런봇 계약은 마지막에 붙인다.
