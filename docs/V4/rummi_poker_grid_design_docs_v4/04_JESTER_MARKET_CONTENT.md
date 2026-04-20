# 04. Jester, Market & Content System

> 문서 성격: current baseline + target content architecture
> 코드 반영 상태: Jester current implemented, multi-content market not implemented
> 핵심 정책: 현재 Jester는 초기 제품의 중심축으로 유지하되, 장기 콘텐츠 계층과 분리 가능한 구조로 확장한다.

## 1. 현재 Jester 구현

[CURRENT]

현재 Jester 시스템은 `jester_meta.dart`에 집중되어 있다.

현재 책임:

- Jester 카드 모델
- JSON catalog load
- supported card filtering
- scoring effect 계산
- economy reward 계산
- stateful Jester 값 관리
- played hand count 관리
- shop offer 생성
- buy / sell / reroll
- stage target score 계산
- cash-out 계산

[WATCH]

현재 `jester_meta.dart`는 Jester, economy, run progress를 함께 품는다. 프로토타입에서는 적절하지만, V4 target에서는 분리가 필요하다.

## 2. Current Catalog

[CURRENT]

데이터 소스:

```text
data/common/jesters_common_phase5.json
```

현재 운영 카탈로그:

- common Jester 38종
- 상점 노출은 `isSupportedInCurrentRunMeta` 기준 필터링

지원 범주:

| 범주 | 현재 처리 |
|---|---|
| `chips_bonus` | onScore line scoring |
| `mult_bonus` | onScore line scoring |
| `xmult_bonus` | onScore line scoring |
| `scholar` | ace 기반 chips + mult 특수 처리 |
| `economy` | 일부 onRoundEnd 처리 |
| `stateful_growth` | 일부 card id 특수 처리 |

## 3. Current Scoring Jester Rules

[CURRENT]

Jester 점수 적용 기준:

- scoring candidate line에만 적용
- dead line에는 적용하지 않음
- contributor 기반 `scoringTiles`만 조건 판정에 사용
- 장착 슬롯 순서대로 순차 적용
- stateful 값은 slot index로 조회

Score context 현재 필드:

- discardsRemaining
- cardsRemainingInDeck
- ownedJesterCount
- maxJesterSlots
- stateValue
- currentHandPlayedCount

[WATCH]

`discardsRemaining`은 현재 board discard를 의미한다. hand discard까지 포함하는 조건이 필요하면 V4에서 context를 확장해야 한다.

## 4. Current Stateful Jester

[CURRENT]

현재 직접 처리되는 stateful Jester:

| ID | 현재 state 변화 |
|---|---|
| `supernova` | rank별 played count 기반 mult |
| `popcorn` | 초기 value, round end decay |
| `ice_cream` | 초기 value, confirm 후 감소 |
| `green_jester` | confirm 시 증가, discard 시 감소 |
| `ride_the_bus` | face card scoring 여부에 따라 증가/리셋 |

[V4_DECISION]

Stateful Jester는 slot index 기반 저장을 유지한다. 장기적으로 고유 instance id를 추가할 수 있지만, 기존 save와 호환되게 adapter가 필요하다.

## 5. Current Shop

[CURRENT]

현재 shop 특징:

- full-screen route
- Jester 중심 offer
- offer count 3
- reroll cost 5, reroll마다 +1
- 구매 시 ownedJesters에 추가
- 판매 시 baseCost 절반, 최소 1 gold
- owned id는 pool에서 제외
- test-only preferred offer path 존재

[WATCH]

검사용 상점 진입은 제품 빌드에서 제거 또는 debug flag 뒤로 숨겨야 한다.

## 6. V4 Content Layers

[TARGET]

V4 장기 콘텐츠는 다음 계층으로 나눈다.

| Content | 역할 | 현재 상태 |
|---|---|---|
| Jester | 전투 점수/경제/상태 보정 | partial implemented |
| Run Kit | run 시작 loadout / 초기 규칙 | not implemented |
| Permit | 콘텐츠/Station 접근 권한 | not implemented |
| Glyph | 특정 scoring 패턴/타일/라인 modifier | not implemented |
| Orbit | run 전체 궤도형 modifier / 장기 조건 | not implemented |
| Echo | 과거 run 또는 이전 Station 결과 반영 | not implemented |
| Sigil | 강한 제약과 강한 보상 | not implemented |
| Risk Grade | 난이도/보상 계층 | not implemented |
| Trial | 특수 룰 challenge run | not implemented |
| Archive | collection / stats / history | not implemented |

[V4_DECISION]

위 계층은 target architecture로 정의하되, 현재 build에 구현된 것으로 쓰지 않는다.

## 7. Unified Content Schema Target

[TARGET]

장기적으로 콘텐츠는 공통 meta를 가진다.

```text
ContentDefinition
- id
- type
- displayNameKey
- descriptionKey
- rarity / tier
- tags
- unlockCondition
- marketEligibility
- effectDefinition
- version
```

Jester는 다음처럼 adapter 가능하다.

```text
RummiJesterCard -> ContentDefinition(type: jester)
```

[MIGRATION]

기존 Jester JSON을 즉시 갈아엎지 않는다. 먼저 adapter layer를 추가한다.

## 8. Market Offer Target

[TARGET]

현재 `RummiShopOffer`는 Jester 전용이다. V4 target에서는 다음 구조를 지향한다.

```text
MarketOffer
- offerId
- slotIndex
- category
- contentId
- price
- currency
- availabilityReason
- debugSource
```

초기 adapter:

```text
RummiShopOffer(card) -> MarketOffer(category: jester, contentId: card.id)
```

## 8.1 Jester / Item Split Policy

[V4_DECISION]

Jester와 Item은 같은 콘텐츠 묶음으로 보지 않는다.

분리 이유:

- Jester는 기본적으로 `지속 장착형 시너지 자산`이다.
- Item은 `소비형`, `전투 보조형`, `패시브 장비형`, `런 중간 개조형`처럼 수명이 다르다.
- 슬롯 규칙, 판매 가능 여부, 중복 허용, 저장 방식, 전투 중 사용 여부가 다르다.
- UI도 동일한 카드 진열 구조로 두면 장기 확장이 꼬인다.

초기 target 분리:

```text
Jester
- equipped / fixed slot / run-long synergy

Item
- Consumable
- Equipment
- PassiveRelic
- Utility
```

Market 진열 레벨에서는 공통 wrapper를 둘 수 있지만,
도메인 / 저장 / 전투 UI는 분리한다.

## 8.2 Multi-content Market Target

[TARGET]

장기 Market은 아래처럼 분리된 상품군을 가진다.

```text
MarketOffer
- JesterOffer
- ItemOffer
```

ItemOffer는 최소한 아래 하위 타입을 구분 가능해야 한다.

```text
ItemOffer(type: consumable)
ItemOffer(type: equipment)
ItemOffer(type: passive_relic)
ItemOffer(type: utility)
```

정책:

- 현재 shop card list에 Jester와 Item을 임시로 같이 보여줄 수는 있다.
- 그러나 내부 save/runtime에서는 `ownedJesters`와 `ownedItems`를 분리한다.
- 전투 중 사용 가능한 item은 `inventory / quick slot` 계층에서 읽고,
  Jester strip과 같은 컴포넌트로 다루지 않는다.
- sell / use / consume / persist 규칙은 Jester와 별도 정의한다.

## 9. Content ID Policy

[V4_DECISION]

- 기존 Jester id는 저장 데이터와 연결되므로 변경하지 않는다.
- 표시 이름 변경은 localization key에서 처리한다.
- effectType 문자열은 adapter로 보존한다.
- 삭제 예정 카드는 catalog에서 숨기되, save restore를 위해 id lookup은 유지한다.
- `ownedJesterIds`에 저장된 id는 앞으로도 복원 가능해야 한다.

## 10. Future Jester Refactor

[MIGRATION]

권장 분리:

```text
jester_meta.dart
→ jester_card.dart
→ jester_catalog.dart
→ jester_effect_engine.dart
→ run_progress.dart
→ economy_config.dart
→ market_offer.dart
→ market_service.dart
```

단, 첫 PR에서 분리하지 않는다. 현재 프로토타입 안정성을 위해 테스트를 먼저 보강한다.

## 11. UI Consequence

[V4_DECISION]

Jester / Item 분리는 UI 재설계를 전제로 한다.

필수 방향:

- `GameView`
  - Jester 영역과 Item 영역을 분리
  - Item이 consumable이면 quick-use zone 또는 inventory zone 필요
  - passive/equipment item은 Jester strip과 다른 표현을 사용
- `MarketView`
  - Jester 섹션과 Item 섹션을 분리
  - category badge 수준이 아니라 정보 구조 자체를 나눌 수 있어야 함
- `Save / Runtime`
  - ownedJesters / ownedItems 분리
  - item 사용/소모/장착 상태 분리

현재 화면은 Jester-only 기준선으로 유지하되,
시안 확보 단계에서는 `battle 화면`과 `market 화면`을 item 확장 전제로 다시 잡는다.

참조:

- Item subtype UI 계약, battle / market 정보 구조, 도메인 모델 초안은 `13_ITEM_SYSTEM_CONTRACT.md`를 기준으로 본다.
