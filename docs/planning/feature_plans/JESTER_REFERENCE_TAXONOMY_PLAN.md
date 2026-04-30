# Jester Reference Taxonomy Plan

> 문서 성격: design reference / catalog expansion prerequisite
> 코드 반영 상태: planning only
> 핵심 정책: Jester는 run-long equipped scoring engine이다. Balatro의 Joker 목록은 수치나 이름을 복사하기 위한 자료가 아니라, 발동 순서, 조건 포함 관계, edition/penalty, 성장/경제/상태형 효과 taxonomy를 정리하기 위한 reference로만 사용한다.

Reference:

- https://danbain.tistory.com/entry/%EB%B0%9C%EB%9D%BC%ED%8A%B8%EB%A1%9C-%EA%B3%B5%EB%9E%B5-4-%EC%A1%B0%EC%BB%A4

## 1. Reference Reading

해당 글에서 현재 게임에 직접 중요한 축은 아래다.

1. Joker activation order
   - scoring card trigger
   - cards left in hand trigger
   - unconditional / hand-rank / edition trigger
   - same condition에서는 slot order
2. Hand-rank condition inheritance
   - stronger hand rank can satisfy lower-rank condition in specific cases.
3. Joker edition / penalty
   - flat chips, +mult, xmult, extra slot, unsellable, timed debuff, rental upkeep.
4. Joker effect taxonomy
   - scored tile trigger
   - hand-rank trigger
   - remaining hand / deck / discard trigger
   - economy trigger
   - growth trigger
   - random/probability trigger
   - market/reroll trigger
   - deck/top-card information trigger
   - score composition mutation

## 2. Current Decision

Do not import Balatro Joker names, values, or full catalog.

Reasons:

- Current catalog already has stable save ids in `data/common/jesters_common_phase5.json`.
- Jester id rename is migration-critical and forbidden.
- Current scoring feedback has only recently become slot-local; adding many new effect forms now would increase verification cost.
- Rarity/shop roll and ML simulator boundaries should be stable before large catalog expansion.

Instead:

- Keep current phase5 Jester catalog.
- Use the reference to refine effect taxonomy, ordering, edition/penalty planning, and simulator fields.
- Add new Jesters only after the taxonomy maps cleanly to `JesterEffectRuntime` events.

## 3. Activation Order Policy

Current Rummi Poker baseline:

- Equipped Jesters apply in slot order.
- Jester scoring effects apply only to valid scoring candidate lines.
- Dead lines are not rescued by Jester effects.
- Conditions use contributor-based `scoringTiles`.

Future extension:

```text
line/tile scoring trigger
-> hand/rank trigger
-> held/remaining hand trigger
-> unconditional equipped trigger
-> edition modifier
-> final score modifier
```

Policy:

- Slot order remains visible and player-controlled.
- +Mult-style additive effects should be readable before xMult-style multiplicative effects.
- Any exception to slot order must be explicitly documented in the Jester definition.
- Scoring feedback must show the local slot burst for each triggered Jester.

## 4. Hand Rank Condition Inheritance

Balatro-style rank inheritance is useful as a design reference, but Rummi Poker must define its own rank lattice.

Candidate policy:

| Condition | Candidate higher-rank satisfiers |
|---|---|
| pair-like | two pair, triple, full house, four/five-kind candidates if enabled |
| two-pair-like | full house candidates |
| triple-like | full house, four/five-kind candidates |
| straight-like | straight flush candidates if enabled |
| flush-like | straight flush / flush house candidates if enabled |

Current caution:

- One Pair is currently a dead line in the default ruleset.
- Pair scoring remains an experiment and must not be enabled implicitly by Jester inheritance.
- Inheritance must be data-driven and test-covered before new Jesters depend on it.

## 5. Edition / Penalty Candidate Taxonomy

Balatro-style edition and penalty tags map to Jester instance modifiers, not base Jester ids.

| Reference modifier | Rummi Poker candidate |
|---|---|
| flat chips edition | `jester_edition_chips` |
| +mult edition | `jester_edition_mult` |
| xmult edition | `jester_edition_xmult` |
| extra slot edition | `jester_edition_extra_slot` or separate slot-capacity item |
| unsellable penalty | `jester_penalty_eternal` |
| timed debuff penalty | `jester_penalty_perishable` |
| upkeep penalty | `jester_penalty_rental` |

Policy:

- Do not add edition/penalty before `ownedJesterInstanceId` or equivalent instance identity is decided.
- Edition/penalty belongs to an owned Jester instance, not the base catalog row.
- Save/restore must retain modifier state.
- Market details must show edition/penalty in the detail panel before purchase.

## 6. Effect Category Candidates

### A. Scored Tile Trigger

Effect examples:

- scored tile color adds chips/mult
- scored tile number family adds chips/mult
- scored tile marker retriggers

Rummi mapping:

- Uses contributor `scoringTiles`.
- Good fit for slot-local scoring feedback.

### B. Hand Rank Trigger

Effect examples:

- straight/flush/full-house-like rank gives chips, +mult, xMult, gold, or growth.

Rummi mapping:

- Must use the rank lattice from section 4.
- Must not make dead lines score by itself.

### C. Remaining Hand / Deck / Resource Trigger

Effect examples:

- remaining hand tile value
- deck remaining count
- board/hand discard remaining
- no discard used this battle

Rummi mapping:

- Good ML feature candidate because it depends on play style, not only catalog possession.

### D. Growth Trigger

Effect examples:

- grows when a condition is met
- decays when a resource is spent
- loses value after each confirm

Rummi mapping:

- Requires stateful value save/restore and clear reset boundary.
- Should be visible in card face or detail panel.

### E. Economy Trigger

Effect examples:

- score event grants gold
- sell value grows
- market discount/reroll effect
- debt/upkeep rule

Rummi mapping:

- Must stay separate from Item economy hooks.
- Simulator should log earned/spent gold source.

### F. Market / Pool Trigger

Effect examples:

- extra offers
- free reroll
- rarity weight change
- generated Jester on station start or blind select

Rummi mapping:

- Must integrate with `MARKET_OFFER_COUNT_RARITY_ROLL_PLAN.md`.
- Offer generation must be reproducible by seed and saved result.

### G. Score Formula Mutation

Effect examples:

- all tiles score
- balance chips/mult
- modify final score after all Jesters

Rummi mapping:

- High-risk.
- Should be introduced only after simulator and scoring feedback can explain the mutation.

## 7. Catalog Expansion Policy

Before adding many Jesters:

- Keep existing ids stable.
- Add effect category tags to current Jester metadata or a read model.
- Verify every new `effectType` maps to a runtime event.
- Verify every new scoring delta appears in sequential scoring feedback.
- Add tests before exposing the Jester in Market.

Recommended expansion order:

1. Fill missing metadata for current phase5 Jesters.
2. Add rarity/shop roll support.
3. Add instance identity plan for edition/penalty.
4. Add one low-risk scored-tile trigger Jester.
5. Add one economy trigger Jester.
6. Add growth/stateful Jesters only after save/restore smoke is stable.
7. Add score formula mutation last.

## 8. ML / Simulator Fields

Candidate fields:

```json
{
  "owned_jester_instance_ids": ["jester_inst_001"],
  "owned_jester_base_ids": ["green_jester"],
  "jester_effect_type_counts": {
    "scored_tile_trigger": 1,
    "hand_rank_trigger": 2,
    "growth": 1,
    "economy": 0,
    "market_pool": 0
  },
  "jester_edition_counts": {
    "chips": 0,
    "mult": 0,
    "xmult": 0,
    "extra_slot": 0
  },
  "jester_penalty_counts": {
    "eternal": 0,
    "perishable": 0,
    "rental": 0
  },
  "jester_trigger_count_by_stage": {
    "tile": 0,
    "rank": 0,
    "held": 0,
    "unconditional": 0,
    "final": 0
  }
}
```

Balance reports should group by:

- Jester count
- rarity count
- effect category count
- edition/penalty count
- stateful Jester count
- order-sensitive additive/multiplicative composition

## 9. Acceptance Criteria

- Balatro Joker reference is documented as taxonomy input only.
- Current Jester ids remain stable.
- Activation order and slot-order policy are explicit.
- Hand-rank inheritance is not enabled implicitly.
- Edition/penalty requires instance identity before implementation.
- New Jester categories must be visible in scoring feedback and simulator logs before Market exposure.
