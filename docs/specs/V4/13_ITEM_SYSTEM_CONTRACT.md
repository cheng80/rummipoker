# 13. Item System Contract

> 문서 성격: target contract for Jester / Item split
> 코드 반영 상태: Item v1 catalog written, runtime partially implemented
> 핵심 정책: 이 문서는 `영역 방향성 확정`과 `구현 전 계약 고정`을 위한 기준이다.

## 1. Purpose

[V4_DECISION]

이 문서는 아래 세 가지를 고정한다.

- Item 4분류의 UI 표현 계약
- battle / market 화면에서 Jester와 Item의 정보 구조 계약
- save / runtime / market adapter에 필요한 최소 도메인 모델 초안

현재 목표는 완성 규칙 확정이 아니라,
`레이아웃 리팩터링과 도메인 분리 구현을 다시 뜯지 않게 만드는 것`이다.

과거 소모품/바우처류 장기 확장 reference는 `docs/archive/feature_plans_2026_04/CONSUMABLE_VOUCHER_REFERENCE_PLAN.md`에서 검색한다.

## 2. Core Separation

[V4_DECISION]

Jester와 Item은 다음처럼 분리한다.

```text
Jester
- run-long equipped synergy asset
- fixed slot driven
- persistent build identity

Item
- tactical or utility asset
- subtype specific lifecycle
- inventory / quick slot / passive rack driven
```

분리 원칙:

- Jester는 `장착 카드 strip`으로 읽힌다.
- Item은 `도구 / 장비 / 소모품 / 유물` 계층으로 읽혀야 한다.
- Item은 Jester의 빈 슬롯을 재활용하지 않는다.
- Item은 Jester 카드의 축소판으로 보이면 안 된다.

## 2.1 Concrete Data Catalog

[V4_DECISION]

실제 런에 투입할 첫 아이템 데이터 기준은 아래 파일이다.

```text
data/common/items_common_v1.json
```

이 파일은 placeholder 샘플이 아니라 `common run`에서 사용할 v1 후보 카탈로그다.
현재 수록 범위는 v1 baseline에 Planet-like 족보 성장 직접 지원 아이템군을 더한 54개 아이템이며, 분포는 다음과 같다.

```text
utility: 9
consumable: 26
equipment: 9
passive_relic: 10
```

런타임 연결 상태는 이 명세에 중복 기록하지 않는다. 실제 적용/미적용 상태는 `docs/planning/feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md`를 기준으로 본다.

데이터 작성 기준:

- Balatro의 `consumable / voucher / shop economy` 구조를 참고하되, 효과와 명칭은 본 게임 규칙에 맞춘 원본 데이터로 작성한다.
- Slay the Spire의 `relic`처럼 런 전체에 영향을 주는 패시브 효과를 `passive_relic`으로 분리한다.
- Luck be a Landlord의 `reroll / removal / capsule / item synergy` 계열처럼 선택지 조정, 경제, 보드 상태 변화 도구를 `utility / consumable`에 반영한다.
- 모든 아이템은 `effect.op` 기반으로 런타임 구현이 가능해야 하며, 텍스트만 있는 아이템은 허용하지 않는다.
- 가격과 희귀도는 초기 실사용 밸런스 후보이며, 실제 플레이 로그 기반으로 조정한다.
- Tarot/Planet/Spectral/Voucher식 구조는 그대로 가져오지 않고, confirm modifier, tile enhancement, tile conversion, rank progression, high-risk mutation, run-long passive로 분리한다.
- Planet-like rank progression은 특정 족보 성장 +1을 주는 직접 지원류로 다룬다. Tile enhancement/conversion과 Spectral-like high-risk mutation은 현재 정책 정화에서 `Board-Line Ritual`과 특수 타일 modifier 축으로 재분류한 뒤 구현 범위를 정한다.

### 2.2 Board-Line Ritual Mutation Policy

[TARGET]

Balatro식 Tarot/Spectral 참고 축 중 `카드 파괴`, `카드 변형`, `문양/숫자 변환`, `복제`, `강화 부여`는 덱빌딩 다양성을 만드는 핵심이다. 다만 Rummi Poker의 손패는 작고, 손패 직접 변형은 UI, 저장/복원, 시뮬레이터 재현, 풀런봇 판단 비용이 크다.

따라서 고위험 mutation 계열은 손패가 아니라 **이미 보드에 구성한 족보/라인**에 적용하는 `Ritual` 계열 Item으로 재해석한다.

정책:

- `Ritual`은 기존 `Item`의 하위 family이며, 별도 Jester가 아니다.
- 1차 대상은 손패가 아니라 `보드 위 완성 라인(row/col/diag)`이다.
- 가능하면 `확정 가능한 라인` 또는 `5칸 완성 라인`만 선택 대상으로 한다.
- 변형 결과는 보드 타일, `addedDeckTiles`, hand-rank progression, next-confirm modifier 중 하나 이상으로 명확히 남아야 한다.
- 사용 즉시 target line, source item, result delta가 보드/덱/런 정보/로그에서 읽혀야 한다.
- 손패 직접 파괴/변형은 V1 범위에서 금지한다.
- 무작위 파괴만 있고 선택/예고/보상이 없는 효과는 금지한다.
- 현재 전투만 바꾸는 임시 효과와 덱에 영구 반영되는 효과를 데이터 필드로 분리한다.
- 타일의 `enhancement`, `seal`, `edition` 필드는 이미 존재하므로, Ritual V1은 이 필드를 재사용하되 새 save schema가 필요하면 별도 migration plan을 먼저 세운다.

왜 필요한가:

- 현재 런은 강한 족보, 특히 flush 계열로 반복 수렴하기 쉽다.
- line mutation은 플레이어가 이미 만든 족보를 재료로 써서 다음 덱 방향을 바꾸게 한다.
- 보드는 손패보다 시각적으로 안정되어 target 선택, 연출, 풀런봇 로그 수집이 쉽다.
- 덱 파괴/복제/변형이 들어가야 Market deckbuilding이 점수 보정 구매를 넘어선다.

V1 구현 전제:

- `use_battle_select_line` 같은 대상 선택 timing이 필요하다.
- 선택 가능한 line highlight와 선택 후 confirm dialog가 필요하다.
- 풀런봇은 처음에 `확정 가능 라인`, `고점 라인`, `중복 확정 후보 라인`에만 Ritual을 사용한다.
- 시뮬레이터는 Ritual 사용 전후의 board/deck delta를 JSONL에 남긴다.

asset path:

```dart
AssetPaths.itemsCommon
```

### 2.3 Policy Cleanup Gate

[ACTIVE]

현재 정책 정화는 기존 54개 아이템을 바로 갈아엎는 작업이 아니다. 먼저 콘텐츠 family와 구현 책임을 다시 나눈다.

분류 기준:

| Family | 역할 | 1차 적용 위치 | 금지/주의 |
|---|---|---|---|
| `Jester` | run-long 점수/조건 synergy | 장착 슬롯, 정산 | Item 슬롯/소모품처럼 보이면 안 됨 |
| `Quick Item` | 전투/마켓에서 직접 쓰는 1회성 도구 | Q-Slot, Tool/Gear 후보 | 자동 지급/의미 없는 사용 금지 |
| `Passive Relic` | 런/Station 단위 장기 효과 | Passive rack | Voucher처럼 보이면 별도 `Run Voucher` 검토 |
| `Hand-Rank Growth` | 족보 레벨 성장 | 성장 아이템, 보상, 런 정보 | next-confirm 임시 보정으로 축소 금지 |
| `Tile Modifier` | 타일 자체의 강화/각인/판본 | 타일 offer, 보드/손패/정산 | 마켓에서만 설명되고 전투에서 안 보이면 실패 |
| `Board-Line Ritual` | 이미 만든 보드 라인에 적용하는 변형/복제/파괴 | 전투 line target UI | 손패 직접 파괴/변형 V1 금지 |
| `Market Pool Mutation` | 다음/현재 마켓 후보 pool과 가격/pack 조정 | Market state, offer lane | 후보 수만 바꾸고 체감 없는 효과 금지 |

정화 순서:

1. 현재 catalog 54개를 위 family로 다시 태깅한다.
2. 실제 runtime에 이미 있는 효과와 문서 후보를 분리한다.
3. Balatro 참고 축은 taxonomy로만 유지하고, 표시명/효과값/대상은 Rummi Poker 원본으로 작성한다.
4. Board-Line Ritual 후보 pool은 넓게 유지한다. 첫 catalog draft는 18종 안팎, 첫 구현 slice는 그중 8~12종으로 잡는다.
5. 새 family를 catalog에 넣기 전에는 저장/복원, target UI, 정산/런 정보 표시, 풀런봇 로그, 시뮬레이터 재현 경로를 먼저 정의한다.

## 3. Item Subtype UI Contract

[V4_DECISION]

Item은 최소 4종으로 시작한다.

### 3.1 Consumable

정의:

- 직접 사용 시 수량이 줄어드는 소모형
- 전투 중 즉시 사용 가능하거나 market 이후 준비된 상태로 소지 가능

UI 계약:

- battle에서는 `quick-use slot` 또는 `count chip`을 가진 버튼형 오브젝트로 표시
- 카드형 세로 레이아웃 대신 `짧고 눌리는 도구형` 실루엣 사용
- 남은 개수, 사용 가능 여부, 쿨다운 또는 잠금 상태를 즉시 읽을 수 있어야 함

행동 계약:

- `use`
- `consume`
- `empty`

### 3.2 Equipment

정의:

- 장착 후 전투 동안 지속되는 보조 장비
- 일반적으로 즉시 소모되지 않음

UI 계약:

- battle에서는 `equipped gear rack` 또는 `passive strip`에 고정 표시
- Jester보다 단순한 shape language 사용
- 개별 수량보다 `장착 중` 상태가 우선

행동 계약:

- `equip`
- `unequip`
- `sell`

### 3.3 PassiveRelic

정의:

- 런 또는 station 단위로 장기 패시브 효과를 주는 유물형
- 보통 전투 중 직접 누르지 않음

UI 계약:

- battle에서는 작은 `passive badge / relic tray`에 요약 표시
- 활성 효과 설명은 tooltip 또는 detail panel에서 읽게 함
- 액션 버튼과 섞이지 않게 상시 패시브 영역에 둠

행동 계약:

- `acquire`
- `persist`
- `sell or lock` 정책은 별도 정의 가능

Voucher-like effect:

- 단순 run-long passive는 `passive_relic`으로 처리할 수 있다.
- chain/unlock/한 구간 1개 offer 같은 voucher 전용 규칙이 필요해지면 별도 `Run Voucher` content type으로 분리한다.

### 3.4 Utility

정의:

- 소모품과 장비의 중간 성격
- 전투 외 또는 특정 타이밍에서 상태를 바꾸는 도구형

UI 계약:

- battle에서는 상황에 따라 quick slot 또는 collapsed inventory로 표시
- market에서는 `도구형` badge가 필요
- 사용 트리거가 항상 있는지, market 전용인지 구분 가능한 표기 필요

행동 계약:

- `use`
- `hold`
- `sell`

## 4. Battle Information Structure

[V4_DECISION]

battle은 아래 정보 구조를 기본으로 한다.

```text
Top HUD
├─ station / goal / gold / options

Jester Strip
├─ equipped Jester slots
├─ fixed slot count
└─ synergy identity

Item Zone
├─ quick consumables
├─ equipment / passive summary
└─ utility state

Main Board
└─ 5x5 play field

Hand / Draw Zone
└─ hand, deck, discard context

Bottom Actions
├─ draw group
├─ selection clear / discard group
└─ confirm group
```

정책:

- `Main Board`는 계속 화면 중심이어야 한다.
- `Jester Strip`은 보드 상단 loadout 영역으로 유지한다.
- `Item Zone`은 Jester 아래 또는 보드 주변의 별도 띠로 두되, 같은 카드 strip처럼 보이지 않게 한다.
- `Confirm`는 draw flow와 물리적으로 분리한다.
- passive item 정보는 action row 안으로 넣지 않는다.

### 4.1 Battle Density Rule

[V4_DECISION]

작은 phone frame에서 정보가 넘치지 않게 다음 우선순위를 고정한다.

1. board 가독성
2. confirm 오동작 방지
3. jester / item 시스템 분리 가독성
4. passive 세부 정보

즉, item 정보가 늘어도 먼저 줄어드는 것은 세부 텍스트이지
board 크기나 confirm 안전 간격이 아니다.

### 4.2 Battle Item Display Rule

[TARGET]

초기 battle item zone은 다음 수준으로 제한한다.

```text
quickConsumables: 최대 2~3칸
equippedItems: 최대 2칸
passiveRelics: 요약 badge 1줄
```

이 수치를 넘어가는 장기 인벤토리는 별도 overlay 또는 상세 sheet로 보낸다.

## 5. Market Information Structure

[V4_DECISION]

market은 `공통 offer list`보다 `분리 section`이 우선이다.

```text
Market Header
├─ gold
├─ reroll
└─ exit / next progression

Owned Jesters
├─ fixed slots
└─ sell / inspect

Owned Items
├─ consumables
├─ equipment
└─ relic / utility summary

Offer Sections
├─ Jester Offers
└─ Item Offers
```

정책:

- Jester와 Item은 같은 스크롤 묶음 안에 존재할 수 있다.
- 그러나 `section title`, `card shape`, `badge`, `행동 문구`는 분리한다.
- Jester 구매는 `slot pressure`와 연결된다.
- Item 구매는 `inventory / quick slot / passive capacity`와 연결된다.

### 5.1 Market Offer Contract

[TARGET]

market 진열용 최소 공통 필드:

```text
offerId
category
subtype
contentId
price
currency
availability
previewLabel
```

category / subtype 규칙:

```text
JesterOffer
- category: jester
- subtype: fixed or synergy tags

ItemOffer
- category: item
- subtype: consumable | equipment | passive_relic | utility
```

## 6. Domain Model Draft

[TARGET]

구현 전 최소 초안:

```dart
enum ItemType {
  consumable,
  equipment,
  passiveRelic,
  utility,
}

enum ItemPlacement {
  inventory,
  quickSlot,
  equipped,
  passiveRack,
}

class ItemDefinition {
  final String id;
  final ItemType type;
  final String nameKey;
  final int basePrice;
  final bool stackable;
  final bool sellable;
  final bool usableInBattle;
}

class OwnedItemEntry {
  final String itemId;
  final int count;
  final ItemPlacement placement;
  final bool isActive;
}

class ItemOffer {
  final String offerId;
  final String itemId;
  final ItemType type;
  final int price;
}
```

save/runtime 분리 초안:

```dart
class RunInventoryState {
  final List<String> ownedJesterIds;
  final List<OwnedItemEntry> ownedItems;
  final List<String> equippedJesterIds;
  final List<String> passiveRelicIds;
  final List<String> quickSlotItemIds;
}
```

정책:

- `ownedJesterIds`를 `ownedItems` 안으로 합치지 않는다.
- count가 있는 item은 `OwnedItemEntry`로 간다.
- passive relic과 quick slot은 저장 시 파생 가능한지 여부를 보고 중복 저장 여부를 결정한다.
- 첫 구현에서는 단순성을 위해 `derived field`보다 `restore 안정성`을 우선한다.

## 7. Runtime Interaction Contract

[TARGET]

런타임 최소 행위:

```text
buyJester
sellJester

buyItem
sellItem
useItem
equipItem
unequipItem
consumeItem
```

제약:

- `useItem`과 `consumeItem`은 같은 이벤트가 아니다.
- `equipItem`은 battle 중 허용되지 않을 수 있다.
- `PassiveRelic`은 구매 즉시 활성화되되, UI에서는 장착 액션 없이 passive rack으로 이동할 수 있다.

## 8. Implementation Order

[MIGRATION]

권장 구현 순서:

1. domain type 추가
2. save model 분리
3. market offer adapter 확장
4. market UI section 분리
5. battle UI item zone skeleton 추가
6. subtype별 행위 연결
7. economy balance tuning

이번 단계에서 허용되는 구현 범위:

- `ItemDefinition`, `OwnedItemEntry`, `ItemOffer` 같은 뼈대 추가
- market / battle에 placeholder zone 추가
- debug fixture로 item zone 노출 검증

이번 단계에서 미루는 것:

- 완전한 item effect 시스템
- subtype별 고급 애니메이션
- 소비 로직과 전투 룰 전체 결합

## 9. Acceptance For Layout Lock

[V4_DECISION]

다음 조건을 만족하면 영역 방향성은 잠긴 것으로 본다.

- battle에서 Jester와 Item이 다른 시각 시스템으로 읽힌다.
- market에서 Jester offers와 Item offers가 다른 section으로 읽힌다.
- phone frame safe area 안에서 board 중심성이 유지된다.
- confirm / draw 오동작 위험이 현저히 줄어든다.
- 이후 item subtype이 추가되어도 Jester strip을 다시 설계하지 않아도 된다.

## 10. Ritual Item Candidate List

[TARGET]

이 목록은 `data/common/items_common_v1.json`에 즉시 추가할 확정 데이터가 아니라, Board-Line Ritual Mutation 계열의 정책 후보 목록이다. 지금은 ML/시뮬레이션보다 먼저 실제 추가할 아이템 카드와 효과 pool을 넓게 잡는 단계다.

Balatro에서 참고할 축:

- Tarot-like: card enhancement, suit/color conversion, rank/number conversion, economy gain.
- Spectral-like: card copy/destruction, seal/edition 부여, 강한 보상과 손실 tradeoff.
- Voucher-like: shop slot, discount, reroll, consumable slot, rarity/frequency 조정.

Rummi Poker에서는 위 효과를 그대로 복사하지 않는다. 손패 직접 조작 대신 `보드 라인`, `확정 preview`, `addedDeckTiles`, `tile modifier`, `hand-rank progression`, `market pool`로 재해석한다.

공통 규칙:

- type: `consumable` 우선
- placement: V1은 `quickSlot` 또는 battle usable inventory로 제한
- timing 후보: `use_battle_select_line`
- target: `completed_line` 또는 `confirmable_line`
- target line은 row/col/diag를 모두 지원하되, V1 UI가 어려우면 row/col부터 시작한다.
- UI/저장/로그 계약은 카드 pool 확정 뒤 역으로 도출한다.

### 10.1 First Catalog Draft Policy

첫 catalog draft는 38종 후보 pool에서 18종 안팎을 고른다. 9종 이하의 작은 pool은 반복 구매 패턴을 만들 가능성이 높으므로 폐기한다.

구성 목표:

```text
Line Memory / Growth: 4
Copy / Deck Injection: 4
Seal / Enhancement: 4
Color / Number Conversion: 2
Prune / Compression: 2
Geometry / Board State: 1
Market / Pool Mutation: 1
```

첫 draft 후보는 `docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md`를 기준으로 확정한다.

### 10.2 High-Risk Candidates

| 후보 ID | 한국어명 | 역할 | 대상 | 효과 | 리스크 | V1 판정 |
|---|---|---|---|---|---|---|
| `line_transmute` | 라인 변환 | 대규모 변형 | 완성 라인 1개 | 라인 전체를 한 색 또는 한 숫자 family로 변환 | flush/족보 밸런스 파괴 | V2 이상 |
| `sacrifice_line` | 제물 의식 | 파괴 보상 | 확정 가능한 라인 1개 | 라인을 확정하지 않고 제거하고 희귀 타일/Jester/Gold 보상 | 유저 손실감, undo 필요 | V2 이상 |
| `mirror_line` | 거울 의식 | 복제 | 완성 라인 1개 | 라인 전체에서 2~3장을 덱에 복사 | 덱 폭증 | V2 이상 |
| `void_mark` | 공허 표식 | 저주/보상 | 완성 라인 1개 | 강한 seal을 주지만 다음 boss modifier 강화 또는 Gold 0 | 규칙 설명 난이도 | V2 이상 |

### 10.3 V1에서 금지

- 손패 타일 직접 파괴.
- 손패 타일 직접 색/숫자 변환.
- 플레이어가 target을 이해하기 전에 무작위로 영구 덱을 바꾸는 효과.
- 보드 라인을 지우기만 하고 보상/로그/되돌릴 수 있는 이해 경로가 없는 효과.
- Jester 생성/파괴/edition 부여를 Ritual V1에 섞는 것. Jester mutation은 별도 family로 둔다.

### 10.4 First Implementation Slice

첫 구현 slice는 catalog draft 18종 중 8~12종만 골라도 된다. 단 설계 pool과 catalog draft 자체를 3~9종으로 축소하지 않는다.

초기 구현은 아래 capability를 많이 공유하는 카드부터 시작한다.

1. line target + hand-rank growth
2. line target + `addedDeckTiles`
3. line target + tile seal
4. line target + light deck prune

색/숫자 변환, sacrifice, wild marker는 evaluator/preview 설명이 닫힌 뒤 구현한다.

### 10.5 Expanded Ritual Pool

정책 후보 pool은 구현 1차보다 넓게 유지한다. pool이 작으면 마켓에서 반복 구매 패턴이 고정되고, 결국 기존 flush/성장 루트만 강화한다.

아래 목록은 Balatro 참고 축과 Rummi Poker 자체 보드 규칙을 섞은 장기 후보군이다.

#### A. Line Memory / Growth

| 후보 ID | 한국어명 | 효과 요약 | 설계 의도 |
|---|---|---|---|
| `line_memory` | 라인 기억 | 선택 라인의 대표 족보 성장 +1 | 확정한 족보를 다음 성장 방향으로 연결 |
| `minor_memory` | 잔상 기억 | 선택 라인의 두 번째로 강한 족보 후보 성장 +1 | 주력 족보만 반복하는 현상 완화 |
| `cross_memory` | 교차 기억 | 선택 타일이 속한 row/col 중 낮은 점수 라인 계열 성장 +1 | 교차 라인 빌드 유도 |
| `boss_memory` | 보스 기억 | 보스전에서만 선택 라인의 대표 족보 성장 +2 | 고위험 전투 보상 강화 |
| `thin_memory` | 얇은 기억 | 4타일 이하로 확정 가능한 라인 계열 성장 +1 | 작은 족보/희소 라인 보정 |

#### B. Copy / Deck Injection

| 후보 ID | 한국어명 | 효과 요약 | 설계 의도 |
|---|---|---|---|
| `keystone_copy` | 중심석 복사 | 라인 최고 기여 타일 1장을 덱에 복사 | 핵심 타일 중심 덱빌딩 |
| `edge_copy` | 끝점 복사 | 라인의 양끝 중 하나를 선택해 덱에 복사 | line endpoint 의미 부여 |
| `color_echo` | 색 메아리 | 라인 다수 색 타일 1장을 무작위 복사 | 색 빌드 지원 |
| `rank_echo` | 숫자 메아리 | 라인 내 반복 숫자 또는 pair 후보 1장 복사 | pair/triple 루트 지원 |
| `scarce_copy` | 희소석 복사 | 현재 덱에 적은 색/숫자 타일을 라인에서 복사 | 덱 편중 완화 |
| `sealed_copy` | 각인 복사 | seal/enhancement가 있는 라인 타일을 약화 복사 | modifier 중심 빌드 지원 |

#### C. Seal / Enhancement

| 후보 ID | 한국어명 | 효과 요약 | 설계 의도 |
|---|---|---|---|
| `line_seal_stamp` | 라인 각인 | 라인 타일 1개에 `line_mark` seal 부여 | Ritual의 기본 강화 감각 |
| `growth_seal` | 성장 각인 | 다음 확정 때 해당 타일 포함 족보 성장 +1 | 타일과 성장 연결 |
| `gold_seal_stamp` | 금빛 각인 | 해당 타일이 scoring line에 포함되면 Gold +1 | 경제 빌드 축 추가 |
| `echo_seal` | 메아리 각인 | 해당 타일 포함 라인이 두 번째 확정이면 보너스 | 다중 confirm 유도 |
| `anchor_seal` | 닻 각인 | 해당 타일이 보드 이동 후 확정되면 보너스 | 이동 아이템과 연계 |
| `risk_seal` | 균열 각인 | 강한 점수 보너스, 단 확정 후 타일 제거 후보가 됨 | Spectral-like tradeoff |

#### D. Color / Number Conversion

| 후보 ID | 한국어명 | 효과 요약 | 설계 의도 |
|---|---|---|---|
| `color_concord` | 색 맞춤 의식 | 라인 1~2장을 다수 색으로 전투 한정 변환 | flush 루트 조정 |
| `off_color_rite` | 이색 의식 | 라인 1장을 다수 색이 아닌 색으로 변환 | flush 일변도 억제 |
| `rank_concord` | 숫자 맞춤 의식 | 라인 1장을 pair/triple 후보 숫자로 전투 한정 변환 | 숫자 족보 루트 강화 |
| `step_rite` | 계단 의식 | 라인 1장을 straight에 가까운 숫자로 변환 | straight 루트 지원 |
| `wild_thread` | 만능 실 | 라인 타일 1장에 전투 한정 wild-color marker | 임시 변형의 안전 버전 |
| `number_mask` | 숫자 가면 | 라인 타일 1장에 전투 한정 wild-rank marker | pair/straight 실험용 |

#### E. Prune / Sacrifice / Compression

| 후보 ID | 한국어명 | 효과 요약 | 설계 의도 |
|---|---|---|---|
| `line_pruner` | 가지치기 의식 | 라인 최저 기여 타일 1장을 덱 제거 후보로 기록 | 덱 압축 |
| `deadwood_burn` | 마른가지 소각 | 확정 불가능한 완성 라인을 제거하고 Gold 획득 | 실패 라인 회수 |
| `sacrifice_line` | 제물 의식 | 확정 가능한 라인을 점수 대신 덱 변형 보상으로 교환 | 점수/성장 선택 |
| `trim_color` | 색 가지치기 | 라인에서 덱 내 과다 색 타일 1장을 제거 후보로 기록 | 색 편중 관리 |
| `trim_rank` | 숫자 가지치기 | 라인에서 덱 내 과다 숫자 타일 1장을 제거 후보로 기록 | 숫자 편중 관리 |
| `void_mark` | 공허 표식 | 강한 seal 부여 후 다음 boss 제약 강화 | 고위험 보상 |

#### F. Line Geometry / Board State

| 후보 ID | 한국어명 | 효과 요약 | 설계 의도 |
|---|---|---|---|
| `cross_rite` | 교차 의식 | 선택 타일의 row/col 양쪽 preview를 강화 | 보드 교차점 가치 상승 |
| `corner_rite` | 모서리 의식 | 라인 끝점/모서리 타일 포함 시 보너스 | 배치 위치 의미 강화 |
| `center_rite` | 중심 의식 | 중앙 포함 라인에 성장 또는 복사 보너스 | 중앙 싸움 유도 |
| `diagonal_rite` | 대각 의식 | 대각선 라인에만 강한 보상 | row/col 반복 완화 |
| `bridge_rite` | 다리 의식 | 두 미완성 라인이 같은 타일을 공유하면 marker 부여 | 미래 확정 설계 |
| `line_swap` | 라인 교환 | 같은 길이의 row/col line 일부 타일 교환 | 고난도 보드 조작 |

#### G. Market / Pool Mutation

| 후보 ID | 한국어명 | 효과 요약 | 설계 의도 |
|---|---|---|---|
| `ritual_coupon` | 의식 쿠폰 | Ritual 계열 다음 구매 할인 | 새 family 진입 완화 |
| `ritual_lens` | 의식 렌즈 | 다음 Market에서 Ritual 후보 출현 가중치 증가 | 빌드 방향 선택 |
| `line_pack_ticket` | 라인 팩 티켓 | 다음 Market에 라인 기반 선택 pack 후보 추가 | booster/pack 확장 후보 |
| `seal_vendor` | 각인 상인 | 다음 Market에 seal/enhancement 계열만 가중 | modifier 빌드 지원 |
| `prune_vendor` | 정리 상인 | 다음 Market에 덱 압축 계열만 가중 | 파괴/압축 빌드 지원 |

#### H. Boss / Constraint Interaction

| 후보 ID | 한국어명 | 효과 요약 | 설계 의도 |
|---|---|---|---|
| `constraint_etch` | 제약 새김 | 현재 boss 제약에 걸린 라인을 변형하면 보너스 | 제약을 회피가 아닌 재료로 사용 |
| `tax_refund_rite` | 세금 환급 의식 | penalty 받은 라인에서 Gold/성장 보상 | 약화 라인 보상 |
| `boss_scar` | 보스 흉터 | 보스전에서 살아남은 라인에 seal 부여 | 보스전 서사 강화 |
| `redemption_rite` | 회복 의식 | 이전 blind에서 실패/낮은 점수 라인 계열 강화 | 실패 경험의 다음 선택화 |

### 10.6 Pool Composition Target

초기 Ritual pool이 너무 작으면 새 시스템이 또 하나의 고정 루트가 된다. 따라서 실제 catalog 투입 전에도 후보 pool은 다음 비율을 목표로 한다.

```text
growth/memory: 20%
copy/deck injection: 20%
seal/enhancement: 20%
conversion: 15%
prune/sacrifice: 10%
geometry/board-state: 10%
market/boss interaction: 5%
```

V1 catalog 투입 최소 조건:

- 설계 후보 pool은 최소 24개 이상. 현재 정화 audit 기준 후보 pool은 38개다.
- 첫 catalog draft는 18종 안팎을 목표로 한다.
- 성장, 복사, seal 계열을 각각 4개 안팎 포함한다.
- 변환, prune, geometry, market pool mutation도 각각 최소 1개 이상 포함한다.
- 고위험 후보는 첫 구현에서 제외하거나 등장 가중치를 낮춘다.
- ML/시뮬레이션/풀런봇 계약은 잠시 보류한다. 먼저 카드와 효과를 확정한 뒤, 필요한 target UI와 저장/표시 정책을 역으로 도출한다.
