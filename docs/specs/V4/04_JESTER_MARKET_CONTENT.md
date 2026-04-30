# 04. Jester, Market & Content System

> 문서 성격: Jester / Item / Market 기능 계약
> 코드 반영 상태: Jester current implemented, Item runtime partially implemented, multi-content market target
> 핵심 정책: Jester는 초기 제품의 중심축으로 유지하되, Item과 Market은 저장/runtime/UI에서 분리 가능한 계약으로 확장한다.

현재 코드 상세는 `docs/current_system/CURRENT_CODE_MAP.md`와 `docs/current_system/CURRENT_BUILD_BASELINE.md`를 기준으로 본다.
Item effect 적용 상태는 `docs/planning/ITEM_EFFECT_RUNTIME_MATRIX.md`를 기준으로 본다.
Jester taxonomy와 후속 catalog 확장 reference는 `docs/planning/feature_plans/JESTER_REFERENCE_TAXONOMY_PLAN.md`를 기준으로 본다.

## 1. Current Boundary Reference

[CURRENT]

현재 구현에서 보호해야 할 사실만 요약한다.

- Jester catalog source: `data/common/jesters_common_phase5.json`
- phase5 Jester catalog: 38개
- Jester translation file: `assets/translations/data/ko/jesters.json`
- Jester save identity: `ownedJesterIds`
- Jester stateful values: slot index 기반
- 현재 shop은 full-screen route와 Jester 중심 offer 흐름을 유지한다.
- Item catalog source: `data/common/items_common_v1.json`
- Item catalog: 49개, `consumable / equipment / passive_relic / utility`
- Item translation file: `assets/translations/data/ko/items.json`

## 2. Jester Contract

[V4_DECISION]

Jester는 `run-long equipped synergy asset`으로 취급한다.

필수 계약:

- Jester id는 저장 데이터와 연결되므로 변경하지 않는다.
- 표시 이름과 설명은 localization key로 처리한다.
- 장착 슬롯 순서가 effect 적용 순서다.
- dead line에는 Jester scoring effect를 적용하지 않는다.
- 조건 판정은 contributor 기반 `scoringTiles`를 사용한다.
- stateful Jester는 기존 slot index 저장을 유지한다.
- 장기적으로 instance id를 도입하더라도 기존 save는 adapter로 복원해야 한다.

후속 확장 정책:

- Balatro-style Joker 목록은 효과 taxonomy reference로만 사용하고, 이름/수치/목록을 그대로 복사하지 않는다.
- hand-rank condition inheritance는 데이터와 테스트가 준비되기 전까지 암묵 적용하지 않는다.
- Jester edition/penalty는 base catalog id가 아니라 owned instance modifier로 다룬다.
- 새 effect category는 `JesterEffectRuntime`, scoring feedback, simulator log에 모두 연결된 뒤 Market에 노출한다.

## 3. Item Contract

[V4_DECISION]

Item은 Jester의 하위 타입이 아니다.

분리 이유:

- Jester는 지속 장착형 시너지 자산이다.
- Item은 소비형, 장비형, 패시브 유물, 유틸리티처럼 수명과 사용 타이밍이 다르다.
- 슬롯 규칙, 판매 가능 여부, 중복 허용, 저장 방식, 전투 중 사용 여부가 다르다.
- UI에서 같은 카드 strip으로 보이면 장기 확장이 꼬인다.

초기 분류:

```text
Item
- Consumable
- Equipment
- PassiveRelic
- Utility
```

필수 계약:

- 내부 save/runtime에서는 `ownedJesters`와 `ownedItems`를 분리한다.
- 전투 중 사용 가능한 item은 `inventory / quick slot` 계층에서 읽는다.
- Item은 Jester strip과 같은 컴포넌트로 다루지 않는다.
- sell / use / consume / persist 규칙은 Jester와 별도로 정의한다.
- 모든 item은 `effect.op` 기반으로 runtime 연결 가능해야 한다.

세부 UI/도메인 계약은 `13_ITEM_SYSTEM_CONTRACT.md`를 기준으로 본다.

## 4. Market Offer Contract

[TARGET]

장기 Market은 상품군을 분리하되, 화면 진열에는 공통 wrapper를 사용할 수 있다.

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
ItemDefinition -> MarketOffer(category: item, contentId: item.id)
```

Market category 최소 단위:

```text
JesterOffer
ItemOffer(type: consumable)
ItemOffer(type: equipment)
ItemOffer(type: passive_relic)
ItemOffer(type: utility)
```

## 5. Content Layer Target

[TARGET]

V4 장기 콘텐츠는 다음 계층으로 나눈다.

| Content | 역할 | 현재 기준 |
|---|---|---|
| Jester | 전투 점수/경제/상태 보정 | current implemented subset |
| Item | 소비형 / 장비형 / 패시브 유물 / 유틸리티 | catalog implemented, runtime partially implemented |
| Run Kit | run 시작 loadout / 초기 규칙 | target only |
| Permit | 콘텐츠/Station 접근 권한 | target only |
| Glyph | 특정 scoring 패턴/타일/라인 modifier | target only |
| Orbit | run 전체 궤도형 modifier / 장기 조건 | target only |
| Echo | 과거 run 또는 이전 Station 결과 반영 | target only |
| Sigil | 강한 제약과 강한 보상 | target only |
| Risk Grade | 난이도/보상 계층 | target only |
| Trial | 특수 룰 challenge run | target only |
| Archive | collection / stats / history | target only |

위 계층은 현재 build에 구현된 것으로 쓰지 않는다.

## 6. Unified Content Schema Target

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

Jester와 Item은 공통 schema로 읽을 수 있어도 runtime ownership은 분리한다.

## 7. Migration Policy

[MIGRATION]

- 기존 Jester JSON을 즉시 갈아엎지 않는다.
- 기존 Jester id를 변경하지 않는다.
- `jester_meta.dart` 분리는 테스트 보강 이후 단계적으로 진행한다.
- multi-content market은 adapter/read model부터 추가한다.
- Jester와 Item을 같은 save field에 합치지 않는다.
- 미지원 effectType을 market에 무분별하게 노출하지 않는다.

권장 분리 순서:

```text
jester_meta.dart
-> jester_card.dart
-> jester_catalog.dart
-> jester_effect_engine.dart
-> run_progress.dart
-> economy_config.dart
-> market_offer.dart
-> market_service.dart
```

## 8. UI Consequence

[V4_DECISION]

Jester / Item 분리는 UI 재설계를 전제로 한다.

- Battle: `Jester strip`과 `Item zone`을 분리한다.
- Market: `Jester Shop`과 `Item Shop`을 먼저 분리한다.
- Item은 consumable이면 quick-use zone 또는 inventory zone에서 읽힌다.
- passive/equipment item은 Jester card와 다른 표현을 사용한다.
- ownedJesters / ownedItems / item 사용 상태는 저장과 runtime에서 분리한다.

시안 확보 단계에서는 `battle 화면`과 `market 화면`을 item 확장 전제로 다시 잡는다.
