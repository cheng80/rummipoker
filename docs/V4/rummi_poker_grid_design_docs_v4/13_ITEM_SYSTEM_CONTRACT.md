# 13. Item System Contract

> 문서 성격: target contract for Jester / Item split
> 코드 반영 상태: Item v1 catalog written, runtime not implemented
> 핵심 정책: 이 문서는 `영역 방향성 확정`과 `구현 전 계약 고정`을 위한 기준이다.

## 1. Purpose

[V4_DECISION]

이 문서는 아래 세 가지를 고정한다.

- Item 4분류의 UI 표현 계약
- battle / market 화면에서 Jester와 Item의 정보 구조 계약
- save / runtime / market adapter에 필요한 최소 도메인 모델 초안

현재 목표는 완성 규칙 확정이 아니라,
`레이아웃 리팩터링과 도메인 분리 구현을 다시 뜯지 않게 만드는 것`이다.

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
현재 수록 범위는 41개 아이템이며, 분포는 다음과 같다.

```text
utility: 7
consumable: 16
equipment: 8
passive_relic: 10
```

데이터 작성 기준:

- Balatro의 `consumable / voucher / shop economy` 구조를 참고하되, 효과와 명칭은 본 게임 규칙에 맞춘 원본 데이터로 작성한다.
- Slay the Spire의 `relic`처럼 런 전체에 영향을 주는 패시브 효과를 `passive_relic`으로 분리한다.
- Luck be a Landlord의 `reroll / removal / capsule / item synergy` 계열처럼 선택지 조정, 경제, 보드 상태 변화 도구를 `utility / consumable`에 반영한다.
- 모든 아이템은 `effect.op` 기반으로 런타임 구현이 가능해야 하며, 텍스트만 있는 아이템은 허용하지 않는다.
- 가격과 희귀도는 초기 실사용 밸런스 후보이며, 실제 플레이 로그 기반으로 조정한다.

asset path:

```dart
AssetPaths.itemsCommon
```

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
