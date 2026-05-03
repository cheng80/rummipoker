# Starting Deck Archetype Plan

> 문서 성격: design reference / ML readiness follow-up
> 코드 반영 상태: planning only
> 핵심 정책: 시작 덱은 단순 cosmetic 선택이 아니라 run rule preset이다. Balatro의 덱/카드 강화 구조는 참고하되, Rummi Poker의 tile deck, 5x5 board, Jester/Item runtime과 맞는 축만 후속 후보로 둔다.

Reference:

- https://danbain.tistory.com/entry/%EB%B0%9C%EB%9D%BC%ED%8A%B8%EB%A1%9C-%EA%B3%B5%EB%9E%B5-3-%EB%8D%B1

## 1. Reference Reading

해당 글에서 참고할 수 있는 축은 세 가지다.

1. Starting deck archetype
   - 버리기/핸드 횟수, 시작 골드, Jester slot, hand size, consumable slot, boss reward, scoring formula, deck composition이 시작 덱마다 달라진다.
2. Card rank/chip baseline
   - 카드 숫자/랭크가 base chip 기대값과 연결된다.
3. Card enhancement / seal / edition
   - 카드 한 장에 chip, multiplier, wild, breakable, held-in-hand, gold, lucky, retrigger 같은 modifier가 붙는다.

Rummi Poker에서는 이를 그대로 복사하지 않고 아래처럼 해석한다.

| Balatro reference axis | Rummi Poker interpretation |
|---|---|
| Red/Blue deck resource bonus | board discard / hand discard / draw cadence preset |
| Yellow deck start money | starting gold preset |
| Black/Painted deck slot tradeoff | Jester slot / hand size / item slot tradeoff |
| Checkered/Abandoned/Erratic deck | tile color/number composition preset |
| Magic/Nebula/Ghost/Zodiac deck | starting item/voucher/shop pool preset |
| Anaglyph boss reward | Boss clear reward/tag modifier preset |
| Plasma scoring formula | alternate scoring formula experiment |
| playing card enhancement | per-tile modifier candidate |
| seal / edition | tile trigger modifier or Jester/Item edition candidate |

## 2. Current Decision

Do not implement starting deck selection yet.

Reasons:

- Current New Run flow intentionally exposes only Random / Seed start.
- ML baseline still needs stable Station, Market roll, Boss modifier, and simulator log boundaries.
- Starting deck presets multiply the balance space and should not be added before simulation can compare outcomes.

Instead:

- Treat starting deck as a future `run_archetype_id`.
- Treat card enhancement as a future `tile_modifier_id`.
- Keep current runtime default equivalent to `standard_tile_deck_v1`.

## 3. Candidate Starting Deck Taxonomy

### A. Resource Preset

Examples:

- board discard +1
- hand discard +1
- draw cadence improvement
- starting gold bonus

ML fields:

```json
{
  "run_archetype_id": "resource_board_discard_v1",
  "starting_gold_delta": 0,
  "board_discard_delta": 1,
  "hand_discard_delta": 0
}
```

### B. Slot Tradeoff Preset

Examples:

- Jester slot +1, hand size -1
- hand size +2, Jester slot -1
- quick item slot +1, passive item slot -1

Rules:

- Must use shared slot capacity constants.
- Must show tradeoff clearly in New Run preview.
- Must be save/restore stable from run start.

### C. Tile Composition Preset

Examples:

- remove one number/rank family
- bias deck toward two tile colors
- randomize tile number/color distribution for challenge mode

Rules:

- Must preserve deck conservation tests.
- Must log full generated composition hash or seed.
- Must not silently change hand evaluator assumptions.

### D. Starting Build Preset

Examples:

- start with one low-tier item
- start with one Jester
- unlock a specific shop pool
- start with a voucher-like passive run rule

Rules:

- Starting build must appear in run summary and save state.
- Shop pool changes must be visible to simulator and reroll logic.

### E. Scoring Formula Preset

Examples:

- alternate chip/mult balancing
- overlap bonus weighting change
- base score smoothing

Rules:

- This is high-risk and should be last.
- Must create a new `balance_version`.
- Must be backed by simulator report before runtime use.

## 4. Tile Enhancement Candidate

Balatro card enhancement maps better to per-tile modifier than to global deck preset.

Candidate tile modifier categories:

| Category | Rummi Poker effect candidate |
|---|---|
| bonus chip | scored tile adds flat chips/base score |
| mult tile | scored tile adds multiplier |
| wild tile | tile counts as additional color/number family |
| fragile tile | strong score boost with chance to remove tile |
| held tile | bonus while tile stays in hand |
| gold tile | reward when scored or retained at settlement |
| lucky tile | chance-based score/economy proc |
| retrigger seal | scored tile triggers its tile modifier twice |

Policy:

- Do not add tile enhancement before scoring feedback can point to the exact tile that generated the delta.
- Enhancement should appear as board/hand-local visual marker, not only as text in a side panel.
- Enhancement state must be included in save/restore and simulator logs.

## 5. UX Contract

Starting deck selection should not be exposed until at least two choices are genuinely playable and meaningfully different.

When exposed:

- It belongs in New Run after Random/Seed entry, not in Blind Select.
- Each archetype card must show resource, slot, deck composition, and starting build changes.
- Locked archetypes should explain unlock condition only if unlock tracking exists.
- Challenge-only archetypes should stay under Trial/Challenge, not default New Run.

## 6. ML / Simulator Contract

Required fields:

```json
{
  "run_archetype_id": "standard_tile_deck_v1",
  "run_archetype_version": 1,
  "tile_deck_composition_id": "standard_52_v1",
  "tile_modifier_pool_id": null,
  "starting_build_preset_id": null,
  "starting_resource_delta": {
    "gold": 0,
    "board_discard": 0,
    "hand_discard": 0,
    "hand_size": 0
  },
  "slot_capacity_delta": {
    "jester": 0,
    "quick_item": 0,
    "passive_item": 0
  }
}
```

Balance automation must group reports by `run_archetype_id`, because the same Station/Market/Boss setup can have different difficulty under different starting decks.

## 7. Implementation Order

Recommended order after balance simulation readiness:

1. Add read-only `run_archetype_id = standard_tile_deck_v1` to run setup/logs.
2. Add simulator support for archetype preset inputs with only the standard preset.
3. Add one low-risk resource preset for simulation only.
4. Add New Run preview UI only after simulator shows the delta is understandable.
5. Add tile modifier taxonomy only after tile-local scoring feedback is stable.
6. Add scoring formula preset last, under a new balance version.

## 8. Acceptance Criteria

- Balatro deck/card enhancement reference is documented as reference-only.
- Current runtime New Run remains Random/Seed only.
- Future starting deck work is represented as `run_archetype_id`, not ad hoc flags.
- Tile enhancement work is separated from starting deck selection.
- ML simulator requirements include archetype, deck composition, resource deltas, slot deltas, and tile modifier pool fields.
