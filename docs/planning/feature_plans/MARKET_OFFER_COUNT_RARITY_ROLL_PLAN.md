# Market Offer Count / Rarity Roll Plan

> 문서 성격: ML readiness prerequisite / Market generation contract
> 코드 반영 상태: planning only
> 핵심 정책: simulator가 실제 Market 분포를 재현할 수 있도록 offer 수, 증설 효과, rarity weighted roll, 중복 제외, save/restore 경계를 먼저 고정한다.

## 1. Current Implementation

현재 Market 생성은 두 경로로 나뉜다.

### Jester offers

Source:

- `RummiRunProgress.openShop`
- `RummiRunProgress._generateOffers`
- `RummiMarketModifierState.jesterOfferSlotCount`

현재 규칙:

- 기본 Jester offer 수: `RummiEconomyConfig.shopOfferCount = 3`
- `boss_trophy`가 boss clear 후 `nextMarketExtraJesterOfferSlots +1`을 예약한다.
- 다음 Market open 시 `nextMarketExtraJesterOfferSlots`가 `extraJesterOfferSlots`로 이동하고, 해당 Market의 reroll 동안 유지된다.
- 보유 중인 Jester id는 offer pool에서 제외한다.
- `preferredOfferIds`는 debug/test fixture 우선 노출용이다.
- 실제 random pick은 현재 pool 균등 랜덤이다.
- Jester rarity는 card meta에 있지만 현재 roll weight에 쓰지 않는다.

### Item offers

Source:

- `RummiMarketRuntimeFacade._buildItemOffers`
- `ItemCatalog.rarityWeights`
- `RummiMarketModifierState.itemOfferSlotCount`
- `RummiMarketModifierState.itemOfferRerollOffset`
- `RummiMarketModifierState.consumedItemOfferIds`

현재 규칙:

- 기본 Item offer 수: `RummiEconomyConfig.shopOfferCount = 3`
- `shop_lens`는 `extraItemOfferSlots +1`로 item offer slot을 늘린다.
- `trade_ticket`은 `itemOfferRerollOffset += itemOfferSlotCount`로 item offer 목록만 회전시킨다.
- 구매한 Item id는 `consumedItemOfferIds`에 들어가 같은 Market에서 재노출되지 않는다.
- Item offer는 현재 `catalog.all` 순서 + offset 회전 기반이다.
- `data/common/items_common_v1.json`의 `rarityWeights`는 로드되지만 현재 roll에 쓰지 않는다.
- `rarityWeightBonus`는 state/save에 있지만 현재 roll에 직접 쓰지 않는다.

## 2. Target Contract

### Base counts

v1 baseline:

| Category | Base offer count | Max v1 cap | Current modifier |
|---|---:|---:|---|
| Jester | 3 | 5 | `extraJesterOfferSlots`, `nextMarketExtraJesterOfferSlots` |
| Item | 3 | 5 | `extraItemOfferSlots` |

Rules:

- Base count는 당분간 3으로 유지한다.
- 증설 효과는 category별로 적용한다.
- v1 cap은 5로 둔다. UI/phone frame 검증 전에는 5 초과를 허용하지 않는다.
- cap은 simulator와 UI가 같은 값을 써야 한다.

### Rarity weights

공통 기본 weight:

```text
common: 48
uncommon: 32
rare: 15
legendary: 5
```

Item은 `ItemCatalog.rarityWeights`를 source of truth로 쓴다.

Jester는 아직 별도 catalog weight가 없으므로 v1에서는 동일 기본 weight를 사용한다. 향후 `jesters_common_*.json` 또는 별도 market config에 rarity weight를 넣을 수 있다.

Jester catalog 확장과 effect taxonomy는 `docs/planning/feature_plans/JESTER_REFERENCE_TAXONOMY_PLAN.md`를 기준으로 본다. Rarity roll 구현은 기존 Jester id를 변경하지 않는다.

Consumable/voucher-like content expansion은 `docs/planning/feature_plans/CONSUMABLE_VOUCHER_REFERENCE_PLAN.md`를 기준으로 본다. v1 Market roll은 현재 Item offer lane을 유지하고, voucher/pack lane은 후속으로 둔다.

### Rarity weight bonus

`RummiMarketModifierState.rarityWeightBonus`는 v1에서 rare 이상 weight에 더한다.

Draft:

```text
common: unchanged
uncommon: unchanged
rare: base + rarityWeightBonus
legendary: base + floor(rarityWeightBonus / 2)
```

이 보너스는 item/Jester 양쪽 roll에 모두 적용할 수 있지만, 실제 적용 PR에서는 테스트 범위를 줄이기 위해 Item roll부터 적용해도 된다.

## 3. Roll Algorithm

후속 구현 PR은 아래 알고리즘을 따른다.

```text
build eligible pool
remove owned / consumed / capacity-blocked entries
repeat until offer slot count filled or pool empty:
  group eligible pool by rarity
  pick rarity by adjusted rarity weight among non-empty rarity buckets
  pick one content uniformly inside selected rarity bucket
  remove picked content from current pool
```

Category-specific eligibility:

- Jester:
  - already owned Jester id 제외
  - current Market에서 이미 뽑은 id 제외
  - currently supported run meta만 포함
- Item:
  - `consumedItemOfferIds` 제외
  - inventory capacity / quick slot capacity / passive rack capacity 기준으로 `canAcquire`가 false인 item 제외
  - current Market에서 이미 뽑은 id 제외

## 4. Reroll / Save Contract

### Market open

- Jester and Item offer lists should be generated at Market open and saved.
- Restore/resume must display the saved offer result, not reroll from current catalog order.
- Current implementation saves Jester offers but derives Item offers from market modifier state. 후속 구현에서는 Item offer ids도 save snapshot에 포함하는 방향을 검토한다.

### Reroll

- Full reroll rerolls both Jester and Item offers.
- `trade_ticket` rerolls Item offers only.
- Reroll must preserve:
  - current Market consumed item ids
  - owned Jester exclusions
  - capacity exclusions
  - current rarityWeightBonus

### Bought content

- Bought Jester disappears from current Market.
- Bought Item disappears from current Market and is added to `consumedItemOfferIds` or saved offer state equivalent.
- Bought content must not reappear until a new reroll/open event.

## 5. ML / Simulator Fields

Market roll logs should include:

```json
{
  "balance_version": "v4_market_roll_v1",
  "market_index": 3,
  "station_id": "s002",
  "run_seed": 12345,
  "market_seed": 99123,
  "reroll_index": 0,
  "jester_offer_count": 3,
  "item_offer_count": 3,
  "rarity_weights": {
    "common": 48,
    "uncommon": 32,
    "rare": 15,
    "legendary": 5
  },
  "rarity_weight_bonus": 0,
  "jester_offer_ids": ["green_jester", "scholar", "egg"],
  "item_offer_ids": ["reroll_token", "chip_capsule", "ledger_clip"],
  "excluded_jester_ids": [],
  "consumed_item_offer_ids": []
}
```

The simulator must use the same roll algorithm and seed source as runtime.

## 6. Implementation Slices

Recommended PR order:

1. Add market roll config/read model
   - shared base weights
   - offer caps
   - deterministic helper boundaries
2. Persist generated item offer ids
   - active run save/restore
   - market resume regression
3. Apply rarity weighted roll to Item offers
   - `ItemCatalog.rarityWeights`
   - capacity and consumed exclusions
4. Apply rarity weighted roll to Jester offers
   - default rarity weights
   - owned exclusions
5. Add simulator-facing market roll snapshot
   - used by `balance simulation readiness pass`

## 7. Acceptance Criteria

- Base offer counts remain 3/3 unless modifier state increases them.
- Offer count cap is documented and shared.
- Rarity weighted roll is deterministic for a fixed seed.
- Bought Jester/Item does not reappear in the same Market unless rules explicitly allow it.
- Market resume shows the same offers after save/restore.
- Simulator can reproduce runtime Market offers from the logged seed/config.
