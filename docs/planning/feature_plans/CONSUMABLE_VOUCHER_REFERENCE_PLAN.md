# Consumable / Voucher Reference Plan

> 문서 성격: design reference / Item system follow-up
> 코드 반영 상태: planning only
> 핵심 정책: Balatro의 Tarot / Planet / Spectral / Voucher 구조는 Item 확장 참고 자료로만 사용한다. Rummi Poker에서는 1회성 전술 도구, hand-rank progression, deck/tile mutation, run-long passive를 서로 다른 시스템 경계로 분리한다.

Reference:

- https://danbain.tistory.com/entry/%EB%B0%9C%EB%9D%BC%ED%8A%B8%EB%A1%9C-%EA%B3%B5%EB%9E%B5-5-%EC%86%8C%EB%AA%A8%ED%92%88-%EB%B0%94%EC%9A%B0%EC%B2%98

## 1. Reference Reading

해당 글에서 참고할 수 있는 축은 아래다.

1. Tarot-like consumables
   - card/tile enhancement
   - suit/color conversion
   - rank/number conversion
   - card/tile destruction or copy
   - gold gain
   - Joker creation / edition
2. Planet-like progression
   - 특정 hand rank의 base chip/mult 또는 level을 올린다.
3. Spectral-like high-risk mutation
   - deck/tile composition을 크게 바꾸고 강한 보상을 준다.
   - hand size, gold, Jester ownership 같은 큰 대가가 붙을 수 있다.
4. Voucher-like run passive
   - market offer slot, discount, reroll cost, consumable slot, hand/discard count, interest cap, shop pool frequency, Jester slot 같은 장기 패시브를 제공한다.
   - 하위/상위 voucher chain과 unlock condition이 있다.

## 2. Current Decision

Do not import Balatro consumable/voucher catalog or values.

Current Rummi Poker state:

- `data/common/items_common_v1.json` has 49 original v1 items.
- All 49 item effects are currently connected in `ItemEffectRuntime`.
- Item subtype baseline is `consumable / equipment / passive_relic / utility`.

Policy:

- Keep current item catalog stable.
- Use this reference to define future taxonomy, not immediate content import.
- Do not add large deck/tile mutation before save/restore and simulator can reproduce it.
- Do not expose voucher-like permanent passives as ordinary quick-use items.

## 3. Rummi Poker Mapping

| Balatro reference | Rummi Poker candidate |
|---|---|
| Tarot card | consumable item that modifies next confirm, tile state, gold, or Jester/shop state |
| Planet card | hand-rank progression system or rank-specific passive item |
| Spectral card | high-risk tile/deck/Jester mutation item |
| Voucher | run-long passive relic or separate `Run Voucher` content type |
| Booster pack | market pack/choice offer, deferred |

## 4. Consumable Taxonomy

### A. Confirm Modifier Consumable

Already represented by:

- `chip_capsule`
- `mult_capsule`
- `line_polish`
- rank/color conditional confirm items

Future rule:

- Must create a visible queued effect.
- Must display local delta during scoring feedback.
- Must be saved before scoring animation starts.

### B. Tile Enhancement Consumable

Candidate effects:

- scored tile gains flat chips
- tile gains multiplier marker
- tile becomes wild color
- tile gains retrigger marker
- tile becomes gold/reward tile

Policy:

- Requires `tile_modifier_id` support.
- Must be board/hand-local visually marked.
- Must integrate with `STARTING_DECK_ARCHETYPE_PLAN.md`.

### C. Tile Conversion Consumable

Candidate effects:

- selected tiles change color
- selected tiles change number/rank family
- selected tile copies another tile

Policy:

- Must preserve deck conservation or explicitly log tile mutation.
- Must define whether converted tiles persist only for battle, station, or full run.

### D. Tile Removal / Copy Consumable

Candidate effects:

- destroy selected tile
- copy selected tile into hand/deck
- remove low-value tile from deck

Policy:

- High impact on balance.
- Requires simulator reproduction and save schema review.

### E. Economy / Market Consumable

Already represented by:

- `coin_cache`
- `thin_wallet`
- `trade_ticket`
- `reroll_token`
- `coupon_stamp`
- `jester_invoice`
- `item_invoice`

Future rule:

- Gold source and reroll source should be logged separately for ML.

### F. Jester Mutation Consumable

Candidate effects:

- create random Jester
- apply Jester edition
- duplicate/destroy Jester with tradeoff

Policy:

- Requires `JESTER_REFERENCE_TAXONOMY_PLAN.md`.
- Edition/penalty needs owned Jester instance identity.

## 5. Planet-Like Rank Progression

Balatro planet cards upgrade specific poker hands. In Rummi Poker this maps to hand-rank progression, not simple consumable score boost.

Candidate:

```json
{
  "hand_rank_progression": {
    "straight": {
      "level": 2,
      "base_score_delta": 20,
      "mult_delta": 1
    }
  }
}
```

Policy:

- Do not implement before hand-rank balance baseline is stable.
- One Pair remains dead-line unless a separate experiment enables it.
- Rank progression must be shown in scoring preview and final scoring presentation.
- Simulator must log rank level at battle start and score event.

## 6. Spectral-Like High-Risk Mutation

Candidate categories:

- destroy random/selected tile for gold
- convert hand to one color/number family
- add strong Jester edition with hand size penalty
- create rare/legendary Jester with gold reset
- duplicate Jester while destroying others

Policy:

- Treat as high-risk item family.
- Do not add to common market pool early.
- Requires explicit confirmation UI and undo/restart implications.
- Must create a new balance version if added to normal runs.

## 7. Voucher / Run Passive Taxonomy

Voucher-like effects should be run-long passives.

Candidate categories:

| Category | Rummi Poker candidate |
|---|---|
| market slot expansion | Jester/Item offer count +1 |
| discount | global shop discount or category discount |
| reroll cost | reroll cost reduction |
| consumable slot | quick item slot +1 |
| hand/discard count | station hand/discard resource +1 |
| shop pool frequency | item/Jester rarity or subtype weight bonus |
| interest/economy cap | settlement reward or interest cap |
| Jester slot | equipped Jester capacity +1 |

Policy:

- Current `passive_relic` can cover simple voucher-like effects.
- If chain/unlock/ante-limited shop logic is added, introduce a separate `Run Voucher` content type.
- Voucher offers should be generated and saved like Market offers.
- Voucher effects must be included in Station Preview and simulator start state.

## 8. Market / Offer Policy

Consumable and voucher-like content should not be blindly mixed into the same item lane.

Near-term:

- Keep current Item offers as the only implemented non-Jester content lane.
- Use rarity roll plan for item offer distribution.
- Represent voucher-like effects as `passive_relic` only when they fit current inventory/rack rules.

Future:

```text
Market
├─ Jester Offers
├─ Item Offers
├─ Pack / Choice Offers
└─ Voucher Offer
```

Rules:

- Voucher offer count should be low, likely one per Station/Sector interval.
- Voucher purchase should affect future Market generation only after save state is updated.
- Pack/choice offers are deferred until item selection UI is ready.

## 9. ML / Simulator Fields

Candidate fields:

```json
{
  "consumable_owned_count": 2,
  "consumable_effect_type_counts": {
    "confirm_modifier": 1,
    "tile_enhancement": 0,
    "tile_conversion": 0,
    "economy": 1,
    "jester_mutation": 0
  },
  "voucher_ids": [],
  "voucher_effect_type_counts": {
    "market_slot": 0,
    "discount": 0,
    "reroll_cost": 0,
    "resource": 0,
    "shop_pool": 0,
    "jester_slot": 0
  },
  "hand_rank_levels": {
    "straight": 1,
    "flush": 1,
    "full_house": 1
  }
}
```

Simulator reports should group by:

- consumable effect category
- voucher effect category
- rank progression level
- tile mutation count
- market slot/rarity modifiers

## 10. Implementation Order

Recommended order after balance simulation readiness:

1. Add read-only consumable effect category fields to simulator features.
2. Add read-only `voucher_ids = []` / `voucher_effect_type_counts = {}` fields.
3. Keep current 49 items as baseline and verify all item effects are represented.
4. Add rank progression as simulator-only experiment.
5. Add one voucher-like passive relic with clear UI and save/restore.
6. Add tile enhancement only after tile-local scoring feedback and `tile_modifier_id` are stable.
7. Add spectral-like high-risk mutation last.

## 11. Acceptance Criteria

- Balatro consumable/voucher reference is documented as taxonomy input only.
- Current item catalog and runtime remain unchanged.
- Consumables, rank progression, high-risk mutation, and voucher/passive effects are separated.
- Voucher-like effects are not treated as ordinary quick-use items.
- Future ML fields include consumable categories, voucher categories, and rank progression.
