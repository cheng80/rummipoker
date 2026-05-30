# Item Policy Cleanup Audit

> 목적: `policy-cleanup-baseline-20260530` 이후 아이템/덱빌딩 정책 정화의 작업 표.
> Source contract: `docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md`

## 1. 결론

현재 `data/common/items_common_v1.json`의 54개 아이템은 런타임 동작은 넓게 갖췄지만, 덱빌딩 다양성 관점에서는 아래로 치우쳐 있다.

```text
Hand-Rank Growth: 7
Confirm / Score Modifier: 16
Resource / Board Action: 15
Market / Economy / Pool: 15
Survival: 1
Board-Line Ritual: 0
Direct Tile Modifier Item: 0
```

따라서 다음 catalog 확장은 단순 점수 보정 아이템을 더 늘리지 않는다. 우선순위는 `Board-Line Ritual`, `Tile Modifier`, `Market Pool Mutation`, `Hand-Rank Growth`의 구분을 명확히 하고, 새 후보는 보드 라인 target, 덱 변화, 타일 각인/강화, 족보 성장으로 플레이 양상을 바꾸는 방향으로 추가한다.

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

현재 catalog에는 0개다. 다음 확장 1순위다.

초기 catalog 후보는 9개로 부족하다. 설계 pool은 최소 24개 이상, 현재 draft는 34개를 기준으로 잡고, 실제 첫 catalog draft는 18종 안팎에서 시작한다.

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
3. 현재 우선순위: 새로 추가할 아이템 카드와 효과 pool을 먼저 정한다.
4. 정책 문서와 UI/풀런봇/시뮬레이션 계약은 카드 pool이 잡힌 뒤 그에 맞춰 갱신한다.

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

| ID | 표시명 | rarity | price | 효과 | 설계 의도 |
|---|---|---:|---:|---|---|
| `line_memory` | 라인 기억 | uncommon | 7 | 선택 라인의 대표 족보 성장 +1 | 만든 족보를 run-long 성장으로 연결 |
| `minor_memory` | 잔상 기억 | rare | 9 | 선택 라인의 두 번째 족보 후보 성장 +1 | 주력 족보 반복 완화 |
| `cross_memory` | 교차 기억 | rare | 10 | 선택 타일의 row/col 중 낮은 성장 계열 +1 | 교차 빌드 유도 |
| `thin_memory` | 얇은 기억 | common | 6 | 3~4타일 scoring line 족보 성장 +1 | 작은 라인 활용 |
| `boss_memory` | 보스 기억 | rare | 11 | 보스전에서 선택 라인 대표 족보 성장 +2 | 위험 전투 보상 |

### 7.2 Copy / Deck Injection

| ID | 표시명 | rarity | price | 효과 | 설계 의도 |
|---|---|---:|---:|---|---|
| `keystone_copy` | 중심석 복사 | uncommon | 8 | 선택 라인 최고 기여 타일 1장을 덱에 복사 | 핵심 타일 중심 덱빌딩 |
| `edge_copy` | 끝점 복사 | common | 6 | 선택 라인의 양끝 중 1장을 덱에 복사 | 위치 의미 부여 |
| `rank_echo` | 숫자 메아리 | uncommon | 8 | 라인 내 반복 숫자 또는 pair 후보 1장 복사 | 숫자 족보 강화 |
| `color_echo` | 색 메아리 | uncommon | 8 | 라인 다수 색 타일 1장 복사 | 색 빌드 지원 |
| `scarce_copy` | 희소석 복사 | rare | 10 | 현재 덱에 적은 색/숫자 타일을 라인에서 복사 | 덱 편중 완화 |
| `sealed_copy` | 각인 복사 | rare | 12 | 각인/강화가 있는 라인 타일을 약화 복사 | modifier 빌드 지원 |

### 7.3 Seal / Enhancement

| ID | 표시명 | rarity | price | 효과 | 설계 의도 |
|---|---|---:|---:|---|---|
| `line_seal_stamp` | 라인 각인 | uncommon | 8 | 라인 타일 1개에 `line_mark` 각인 | Ritual 기본 감각 |
| `growth_seal` | 성장 각인 | rare | 10 | 해당 타일이 contributor가 되면 족보 성장 +1 후 소비 | 타일과 성장 연결 |
| `gold_seal_stamp` | 금빛 각인 | uncommon | 8 | 해당 타일 포함 scoring line 확정 시 Gold +1 | 경제 빌드 축 |
| `echo_seal` | 메아리 각인 | rare | 10 | 같은 타일이 두 번째 scoring line에도 기여하면 보너스 | overlap 유도 |
| `anchor_seal` | 닻 각인 | uncommon | 7 | 보드 이동 후 해당 타일 포함 확정 시 보너스 | 이동 아이템 연계 |
| `risk_seal` | 균열 각인 | legendary | 14 | 큰 보너스, 확정 후 덱 제거 후보가 됨 | Spectral-like tradeoff |

### 7.4 Color / Number Conversion

| ID | 표시명 | rarity | price | 효과 | 설계 의도 |
|---|---|---:|---:|---|---|
| `rank_concord` | 숫자 맞춤 의식 | rare | 11 | 라인 타일 1장을 pair/triple 후보 숫자로 전투 한정 처리 | 숫자 족보 지원 |
| `step_rite` | 계단 의식 | uncommon | 9 | 라인 타일 1장을 straight에 가까운 숫자로 전투 한정 처리 | straight 지원 |
| `color_concord` | 색 맞춤 의식 | rare | 11 | 라인 타일 1장을 다수 색으로 전투 한정 처리 | flush 조정 |
| `off_color_rite` | 이색 의식 | uncommon | 8 | 라인 타일 1장을 다수 색이 아닌 색으로 전투 한정 처리 | flush 일변도 완화 |
| `wild_thread` | 만능 실 | rare | 12 | 라인 타일 1장에 전투 한정 wild-color 부여 | 안전한 임시 변형 |
| `number_mask` | 숫자 가면 | rare | 12 | 라인 타일 1장에 전투 한정 wild-rank 부여 | pair/straight 실험 |

### 7.5 Prune / Sacrifice / Compression

| ID | 표시명 | rarity | price | 효과 | 설계 의도 |
|---|---|---:|---:|---|---|
| `line_pruner` | 가지치기 의식 | rare | 10 | 라인 최저 기여 타일 1장을 덱 제거 후보로 기록, Gold +2 | 덱 압축 |
| `trim_color` | 색 가지치기 | uncommon | 8 | 덱에 많은 색 타일을 라인에서 제거 후보로 기록 | 색 편중 관리 |
| `trim_rank` | 숫자 가지치기 | uncommon | 8 | 덱에 많은 숫자 타일을 라인에서 제거 후보로 기록 | 숫자 편중 관리 |
| `deadwood_burn` | 마른가지 소각 | rare | 10 | 확정 불가능한 4~5타일 라인을 정리하고 Gold 획득 | 실패 라인 회수 |
| `sacrifice_line` | 제물 의식 | legendary | 15 | scoring line 점수를 포기하고 덱 변형 보상 획득 | 고위험 선택 |

### 7.6 Geometry / Board State

| ID | 표시명 | rarity | price | 효과 | 설계 의도 |
|---|---|---:|---:|---|---|
| `cross_rite` | 교차 의식 | rare | 11 | 선택 타일의 row/col 양쪽 preview를 강화 | 교차점 가치 상승 |
| `corner_rite` | 모서리 의식 | uncommon | 8 | 모서리/끝점 포함 라인에 성장 또는 복사 보너스 | 배치 위치 의미 |
| `center_rite` | 중심 의식 | uncommon | 8 | 중앙 포함 라인에 성장 또는 복사 보너스 | 중앙 싸움 유도 |
| `diagonal_rite` | 대각 의식 | rare | 10 | 대각선 라인에만 강한 보상 | row/col 반복 완화 |
| `bridge_rite` | 다리 의식 | rare | 12 | 두 미완성 라인이 같은 타일을 공유하면 marker 부여 | 미래 확정 설계 |

### 7.7 Market / Pool Mutation

| ID | 표시명 | rarity | price | 효과 | 설계 의도 |
|---|---|---:|---:|---|---|
| `ritual_coupon` | 의식 쿠폰 | common | 5 | 다음 Ritual 계열 구매 할인 | 새 family 진입 완화 |
| `ritual_lens` | 의식 렌즈 | uncommon | 7 | 다음 Market에서 Ritual 후보 출현 가중치 증가 | 빌드 방향 선택 |
| `line_pack_ticket` | 라인 팩 티켓 | rare | 10 | 다음 Market에 line 기반 선택 pack 후보 추가 | pack 확장 |
| `seal_vendor` | 각인 상인 | uncommon | 8 | 다음 Market에 각인/강화 계열 가중 | modifier 빌드 지원 |
| `prune_vendor` | 정리 상인 | uncommon | 8 | 다음 Market에 덱 압축 계열 가중 | 압축 빌드 지원 |

## 8. First Catalog Draft Target

후보 pool은 34종이다. 첫 catalog draft는 이 중 18종 안팎을 목표로 한다.

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

## 9. Policy Update Order

이제 정책 수정 순서는 아래로 바꾼다.

1. 새 카드 pool과 1차 catalog draft를 먼저 확정한다.
2. 각 카드가 요구하는 runtime capability를 역으로 도출한다.
3. 그 capability 기준으로 `use_battle_select_line`, 저장/복원, 전투 표시, 정산 표시 정책을 쓴다.
4. ML/시뮬레이션/풀런봇 계약은 마지막에 붙인다.
