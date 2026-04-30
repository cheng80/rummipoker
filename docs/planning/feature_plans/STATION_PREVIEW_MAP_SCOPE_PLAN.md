# Station Preview / Map Scope Plan

> 문서 성격: ML readiness prerequisite / Station scope decision
> 코드 반영 상태: scope decision only
> 핵심 정책: Station Map 전체 구현 전에 현재 Blind Select를 `Station Preview v1`로 고정해 ML log schema와 후속 balance pass의 station 단위를 안정화한다.

## 1. Purpose

ML 기반 밸런스 자동화는 `station_id`, blind tier, 선택지, reward/pressure 조건이 흔들리지 않아야 시작할 수 있다.

현재 제품 루프는 이미 아래처럼 작동한다.

```text
Battle -> Settlement -> Market -> Blind Select -> Battle
```

따라서 이번 scope decision은 새 Station Map UI를 바로 구현하지 않고, 현재 `BlindSelectView`를 Station Preview v1로 공식화한다.

## 2. Scope Decision

### 결정

- `Station`은 현재 `runProgress.stageIndex`가 가리키는 큰 진행 단위다.
- 한 Station 안에는 `Small / Big / Boss` 3개 blind objective가 있다.
- `currentStationBlindTierIndex`는 해당 Station 안에서 마지막으로 클리어한 blind tier를 뜻한다.
- `BlindSelectView`는 앞으로 `Station Preview v1` 역할을 한다.
- `Station Map`은 v1에서 별도 node graph 화면으로 만들지 않는다.

### v1 화면 책임

`Station Preview v1`은 다음을 보여 준다.

- station index
- difficulty label 또는 continue context
- Small / Big / Boss objective cards
- target score
- board discard
- hand discard
- max hand size
- reward preview
- cleared/selectable/locked state
- lock reason

Boss modifier preview는 v1에서 빈 상태로 둔다.

- Boss card에는 현재 target/resource pressure만 반영한다.
- 향후 Boss modifier가 붙으면 entering 전에 modifier id, category, affected build surface를 반드시 표시한다.
- modifier preview는 ML log field에도 들어가야 한다.

### v1에서 하지 않는 것

- branch형 Station Map
- sector map
- route 선택
- Station modifier 카드
- Boss-specific visible modifier
- Entry / Pressure / Lock 본 구현
- permit, glyph, orbit, sigil 선택지
- skip blind reward/tag 규칙

## 3. ML Log Schema Contract

ML / simulator 로그에서 Station 단위는 아래 필드를 최소 기준으로 둔다.

```json
{
  "balance_version": "v4_station_preview_v1",
  "run_seed": 12345,
  "station_id": "s001",
  "station_index": 1,
  "blind_tier": "small",
  "cleared_blind_tier_index_before_select": -1,
  "difficulty": "standard",
  "target_score": 300,
  "board_discards": 4,
  "hand_discards": 2,
  "max_hand_size": 8,
  "reward_preview_gold": 4,
  "station_modifiers": [],
  "boss_modifier_id": null,
  "boss_modifier_category": null,
  "map_node_id": null,
  "map_branch_id": null
}
```

Notes:

- `station_id`는 v1에서 `s{stationIndex.padLeft(3, "0")}` 형식으로 충분하다.
- `map_node_id`와 `map_branch_id`는 v1에서 `null`로 둔다.
- `station_modifiers`는 v1에서 빈 배열로 둔다.
- `boss_modifier_id`와 `boss_modifier_category`는 v1에서 `null`로 둔다. Boss modifier pass에서 visible rule modifier가 붙으면 채운다.
- `blind_tier`는 `small | big | boss` 중 하나다.
- simulator는 `BlindSelectionSetup.buildForStation`과 `resolveSpec` 결과를 기준으로 같은 값을 재현해야 한다.

## 4. Code Boundary

현재 코드 기준 source of truth:

- `BlindSelectionSetup.buildForStation`
- `BlindSelectionSetup.resolveSpec`
- `BlindSelectionSetup.prepareRuntimeForBlindSelect`
- `BlindSelectionSetup.prepareContinuedRunForSelectedBlind`
- `BlindSelectView`
- `RummiRunProgress.stageIndex`
- `RummiRunProgress.currentStationBlindTierIndex`

v1에서는 별도 StationDefinition 모델을 만들지 않는다.

단, 후속 `balance simulation readiness pass`에서 pure logic simulator가 같은 값을 읽기 쉽도록 `StationPreviewSnapshot` 또는 equivalent read model을 추가할 수 있다.

## 5. Follow-Up Order

이 결정 이후 ML readiness 순서는 아래로 간다.

1. `market offer count and rarity roll planning pass`
2. `blind/station pacing baseline pass`
3. `balance simulation readiness pass`
4. `tools/sim/run_balance_sim.dart` smoke simulator

## 6. Acceptance Criteria

- Station Preview v1의 station 단위가 `stageIndex + blind tier`로 문서상 고정된다.
- Station Map 전체 구현이 ML readiness의 blocker가 아니다.
- ML 로그는 현재 Blind Select spec 값을 재현할 수 있다.
- branch map, station modifier, skip/tag는 명시적으로 후속이다.
