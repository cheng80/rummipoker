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

따라서 다음 catalog 확장은 단순 점수 보정 아이템을 더 늘리지 않는다. 우선순위는 `Board-Line Ritual`, `Tile Modifier`, `Market Pool Mutation`, `Hand-Rank Growth`의 구분을 명확히 하고, 새 후보는 보드 라인 target과 trace가 있는 방향으로 추가한다.

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

초기 catalog 후보는 최소 9개 이상으로 잡되, 실제 첫 구현은 낮은 리스크부터 시작한다.

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
2. 완료: Board-Line Ritual V1 9개 후보의 효과값, 가격, 희귀도, placement를 draft했다.
3. 다음: `use_battle_select_line` target UI 계약을 작성한다.
4. 다음: 풀런봇/시뮬레이터 trace 필드를 확정한다.
5. 그 뒤에만 catalog/runtime 구현으로 넘어간다.

## 6. Board-Line Ritual V1 Draft Catalog

아래 9개는 바로 JSON에 넣을 확정값이 아니라, 구현 전 계약을 닫기 위한 draft다. 공통 placement는 `quickSlot` 우선이며, 전투 중 `use_battle_select_line`으로 보드 라인을 선택한다.

공통 target:

```text
target: completed_line | confirmable_line
line types: row | column | diagonal
minimum tiles: 3
default consume: true
```

공통 trace:

```text
source_item_id
target_line_ref
target_line_kind
target_tile_codes_before
result_kind
tiles_after
deck_delta
rank_progress_delta
modifier_delta
score_preview_delta
```

| ID | rarity | price | family | 효과 draft | V1 리스크 | 구현 판정 |
|---|---:|---:|---|---|---|---|
| `line_memory` | uncommon | 7 | growth | 선택 라인의 대표 족보 성장 +1 | 기존 study와 중복 | P0 |
| `keystone_copy` | uncommon | 8 | copy/deck | 선택 라인에서 점수 기여가 가장 큰 타일 1장을 `addedDeckTiles`에 복사 | 덱 비대화 | P0 |
| `line_seal_stamp` | uncommon | 8 | seal | 선택 라인 타일 1개에 `seal=line_mark` 부여. 다음 해당 타일 포함 확정 때 작은 성장/점수 보너스 | seal 표시/정산 필요 | P0 |
| `minor_memory` | rare | 9 | growth | 선택 라인의 두 번째 족보 후보 성장 +1. 없으면 대표 족보 +1로 fallback | 후보 계산 설명 난이도 | P1 |
| `edge_copy` | common | 6 | copy/deck | 선택 라인의 양끝 타일 중 하나를 선택해 `addedDeckTiles`에 복사 | endpoint UI 필요 | P1 |
| `growth_seal` | rare | 10 | seal | 선택 타일에 `seal=growth_seal` 부여. 해당 타일이 contributor가 되면 그 족보 성장 +1 후 seal 소비 | 발동 추적 필요 | P1 |
| `gold_seal_stamp` | uncommon | 8 | seal/economy | 선택 타일에 `seal=gold_seal` 부여. 해당 타일 포함 scoring line 확정 시 Gold +1 | 경제 snowball | P1 |
| `rank_concord` | rare | 11 | conversion | 선택 라인 타일 1장을 pair/triple 후보 숫자로 전투 한정 wild-rank 처리 | 족보 판정 혼란 | P2 실험 |
| `line_pruner` | rare | 10 | prune/deck | 선택 라인 최저 기여 타일 1장을 전투 후 덱 제거 후보로 기록. 즉시 Gold +2 | 영구 제거/undo 정책 | P2 실험 |

V1 도입 최소 묶음:

```text
P0: line_memory, keystone_copy, line_seal_stamp
P1: minor_memory, edge_copy, growth_seal, gold_seal_stamp
P2 experiment: rank_concord, line_pruner
```

V1에서 아직 넣지 않는 후보:

- `sacrifice_line`: 라인 손실감과 undo/보상 설명이 무겁다.
- `line_transmute`: flush/straight 밸런스를 크게 흔든다.
- `mirror_line`: 덱 폭증이 크다.
- `void_mark`: 보스 제약 강화와 보상 tradeoff UI가 아직 없다.

## 7. Catalog 적용 Gate

Draft 9개를 실제 `items_common_v1.json`에 넣기 전 조건:

1. `use_battle_select_line` timing enum 또는 동등한 action path가 있다.
2. 선택 가능한 line highlight가 row/column/diagonal에서 동작한다.
3. 선택 후 item source, target line, result delta가 전투 UI에 표시된다.
4. save/restore에서 line target 선택 전/후 상태가 깨지지 않는다.
5. `addedDeckTiles`, `handRankProgress`, `Tile.seal/enhancement/edition` 변경이 JSON roundtrip된다.
6. 풀런봇 action schema에 `use_item_on_line`이 추가된다.
7. sim/LLM trace에 ritual 사용 전후 board/deck/rank/modifier delta가 남는다.
