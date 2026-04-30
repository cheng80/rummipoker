# Blind / Station Pacing Baseline Plan

> 문서 성격: ML readiness prerequisite / balance baseline
> 코드 반영 상태: current constants documented
> 핵심 정책: ML 시뮬레이션과 후속 밸런스 비교가 같은 기준을 보도록 현재 Station/Blind target, reward, pressure 수치를 `v4_pacing_baseline_1`로 고정한다.

## 1. Balance Version

Baseline id:

```text
v4_pacing_baseline_1
```

이 baseline은 현재 런타임 수치를 그대로 문서화한다. 이번 pass에서는 수치를 바꾸지 않는다.

Source of truth:

- `AppConfig.stationTargetScoreScale`
- `BlindSelectionSetup._baseTargetForStation`
- `BlindSelectionSetup._buildSpec`
- `RummiRuleset.currentDefaults`
- `RummiEconomyConfig`
- `GameSessionNotifier._initialGold`
- `GameSessionNotifier._initialRerollCost`

## 2. Station Target Curve

Base station target:

```text
raw_station_target(stationIndex):
  if stationIndex <= 1: 300
  else: floor(300 * 1.6^(stationIndex - 1))

scaled_station_target = round(raw_station_target * 0.9)
```

Difficulty multiplier:

| Difficulty | Multiplier |
|---|---:|
| standard | 1.0 |
| relaxed | 0.8 |
| pressure | 1.2 |

Examples:

| Station | Raw | Scaled standard | Relaxed | Pressure |
|---:|---:|---:|---:|---:|
| 1 | 300 | 270 | 216 | 324 |
| 2 | 480 | 432 | 346 | 518 |
| 3 | 768 | 691 | 553 | 829 |
| 4 | 1228 | 1105 | 884 | 1326 |

## 3. Blind Tier Pressure

Blind tier modifies the station target and resources.

| Tier | Target multiplier | Board discards | Hand discards | Max hand size |
|---|---:|---|---|---|
| Small | 1.0 | base | base | base |
| Big | 1.5 | base - 1, min 1 | base | base |
| Boss | 2.0 | base - 1, min 1 | base - 1, min 1 | base - 1, min 1 |

Base resources from `RummiRuleset.currentDefaults`:

```text
defaultMaxHandSize = 1
defaultBoardDiscards = 4
defaultHandDiscards = 2
```

Difficulty resource adjustment:

| Difficulty | Board discards | Hand discards | Starting gold | Initial reroll |
|---|---:|---:|---:|---:|
| standard | base | base | 10 | 5 |
| relaxed | base + 1 | base + 1 | 13 | 4 |
| pressure | base - 1 | base - 1 | 10 | 5 |

Notes:

- Because baseline max hand size is 1, Boss currently remains at 1 by min clamp.
- Pressure difficulty can lower discard resources, but current selectable difficulty gate still defaults most players to standard unless unlocked.

## 4. Reward Baseline

Blind select reward preview:

| Tier | Preview Gold |
|---|---:|
| Small | 10 |
| Big | 14 |
| Boss | 18 |

Cash-out reward calculation:

```text
blindReward = 10
remainingBoardDiscardGoldBonus = remainingBoardDiscards * 5
remainingHandDiscardGoldBonus = remainingHandDiscards * 2
totalGold = blindReward + board bonus + hand bonus + settlement item modifiers
```

Important:

- Blind select reward preview is currently tier-shaped.
- Actual cash-out base reward currently uses `stageClearGoldBase = 10` plus remaining resource bonuses and settlement item modifiers.
- This mismatch is accepted for `v4_pacing_baseline_1` and should be measured before changing.

## 5. Unlock Tempo

Within a Station:

```text
Small selectable at station entry
Big selectable after Small cleared
Boss selectable after Big cleared
Next Station unlocks after Boss cleared
```

Current state fields:

- `stageIndex`: Station index
- `currentStationBlindTierIndex`: last cleared tier in the current Station

When `currentStationBlindTierIndex >= boss`, blind select preparation increments `stageIndex` and resets cleared tier to `-1`.

## 6. ML / Simulator Fields

Pacing logs should include:

```json
{
  "balance_version": "v4_pacing_baseline_1",
  "station_index": 2,
  "blind_tier": "big",
  "difficulty": "standard",
  "raw_station_target": 480,
  "station_target_scale": 0.9,
  "difficulty_target_multiplier": 1.0,
  "tier_target_multiplier": 1.5,
  "target_score": 648,
  "base_board_discards": 4,
  "base_hand_discards": 2,
  "board_discards": 3,
  "hand_discards": 2,
  "max_hand_size": 1,
  "reward_preview_gold": 14,
  "boss_modifier_id": null,
  "boss_modifier_category": null,
  "stage_clear_gold_base": 10,
  "remaining_board_discard_gold_bonus": 5,
  "remaining_hand_discard_gold_bonus": 2
}
```

## 7. Known Questions

- Should actual cash-out base reward scale by blind tier, matching preview?
- Is `1.6^(stationIndex - 1)` too steep once Jester/Item rarity roll is active?
- Should Boss pressure reduce max hand size only after baseline hand size grows above 1?
- Should pressure difficulty reduce starting gold or only target/resources?
- Should discard reward remain high enough that conservative play competes with score acceleration?
- Should Boss be defined primarily by a visible rule modifier rather than only target/resource pressure?

## 8. Ante / Stake Reference Policy

Balatro reference:

- Ante raises the required score curve across the run.
- Small / Big / Boss generally map to `x1.0 / x1.5 / x2.0` requirements.
- Higher stake tiers can make the required score grow faster and add extra penalties.

Rummi Poker policy:

- Do not copy Balatro ante/stake chip tables directly.
- Use those tables only as external shape references for curve steepness and tier pressure.
- Our score requirement must be tuned against the 5x5 board, 12-line scoring, Jester/Item runtime, draw cadence, and resource economy.
- Future ML/simulation tooling should tune `target_score`, tier multipliers, and difficulty multipliers from logged run outcomes.
- Any direct number change must either update `v4_pacing_baseline_1` or create a new `balance_version`.

ML tuning target:

```text
input:
  station_index
  blind_tier
  difficulty
  boss_modifier_id
  market/jester/item state
  run resources

output candidates:
  target_score_scale
  station_growth_base
  tier_target_multiplier
  difficulty_target_multiplier
  reward/pressure adjustment
```

## 9. Boss Modifier Follow-Up

Detailed taxonomy and adoption order: `docs/planning/feature_plans/BOSS_MODIFIER_TAXONOMY_PLAN.md`.

Balatro-style Boss fights are not just higher target fights. They usually add a visible constraint that attacks part of the player's build: suit, hand type, card/rank, Joker, chip output, or round resource.

For this game, Boss v1 should translate that idea into systems that fit the 5x5 board and one-at-a-time hand draw model.

Candidate categories:

| Category | Rummi Poker equivalent | Caution |
|---|---|---|
| Suit weaken | tile color score dampening or color line penalty | Must still show affected board tiles clearly |
| Hand weaken | specific hand rank base score dampening or disabled rank bonus | Avoid fully invalidating too many lines at once |
| Card/rank weaken | number/rank tile score dampening | Works better than face-down hand cards |
| Joker restriction | selected Jester slot/effect disabled or reduced | Must preview affected Jester before entering Boss |
| Chip/score pressure | target multiplier, score dampening, or reduced scoring window | Already partially covered by Boss target x2.0 |
| Resource pressure | board/hand discard reduction, hand size pressure | Already partially covered by current Boss baseline |

Do not directly copy face-down hand-card patterns without redesign.

Reason:

- Current hand is drawn incrementally, not dealt as a full poker hand.
- Hiding the single drawn tile can remove planning rather than create interesting adaptation.
- If hidden information is used later, prefer board/tile preview constraints, temporary tile fog, or clear reveal timing over permanent hand opacity.

Boss modifier implementation should be a later pass after `balance simulation readiness pass`, because simulator logs need explicit modifier ids and parameters.

## 10. Acceptance Criteria

- Current target/reward/pressure constants are recorded under one balance version.
- ML simulator can log the exact inputs used to build each blind objective.
- No runtime number changes are included in this pass.
- Follow-up balance changes must either update `v4_pacing_baseline_1` or create a new `balance_version`.
- Boss modifier design is recognized as separate from the current target/resource baseline.
- Balatro ante/stake chip tables are reference-only and not copied into runtime constants.
