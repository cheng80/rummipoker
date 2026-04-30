# Boss Modifier Taxonomy Plan

> 문서 성격: design reference / ML readiness prerequisite
> 코드 반영 상태: planning only
> 핵심 정책: Boss는 단순 target/resource 압박이 아니라, 진입 전 공개되는 visible rule modifier를 가진 전투로 설계한다. Balatro의 Boss/Stake 제약은 참고하되, Rummi Poker의 draw 기반 손패와 5x5 board 구조에 맞게 재해석한다.

Reference:

- https://danbain.tistory.com/entry/%EB%B0%9C%EB%9D%BC%ED%8A%B8%EB%A1%9C-%EA%B3%B5%EB%9E%B5-2-%EC%97%94%ED%8B%B0

## 1. Balatro Reference Categories

해당 글 기준으로 Boss Blind는 아래 제약 패턴을 갖는다.

| Reference pattern | Example bosses | Rummi Poker interpretation |
|---|---|---|
| Random hand discard after play | The Hook | draw/hand discard pressure, forced tile discard event |
| Economy punishment | The Ox, The Tooth | gold loss, sell/buy pressure, market penalty |
| Face-down / hidden cards | The House, The Wheel, The Fish, The Mark | 직접 복사 금지. draw 기반 손패에 맞게 tile fog/reveal timing으로 재설계 필요 |
| Extra target requirement | The Wall, Violet Vessel | target multiplier / score dampening |
| Hand type degradation/restriction | The Arm, The Eye, The Mouth, The Psychic, The Needle | hand rank weaken, rank repeat restriction, minimum/maximum line confirm condition |
| Suit debuff | The Club, The Goad, The Window, The Head | tile color weaken |
| Face card debuff | The Plant | tile number/rank family weaken |
| Discard/resource constraint | The Water, The Manacle, The Serpent | board/hand discard, max hand size, draw cadence pressure |
| Played-card debuff memory | The Pillar | tiles/lines used earlier in Station become weakened |
| Base chips/mult reduction | The Flint | base score / multiplier dampening |
| Joker disruption | Amber Acorn, Verdant Leaf, Crimson Heart | Jester slot/effect disable, shuffle, sell requirement, temporary suppress |
| Forced card selection | Cerulean Bell | forced tile/line priority, constrained selection |

## 2. Rummi Poker Candidate Taxonomy

### A. Tile Color Weaken

Effect:

- 특정 tile color가 포함된 scoring line의 base score 또는 modifier 기여를 줄인다.

Preview requirement:

- Boss card에 affected color swatch 표시
- Battle board에서 affected color tile에 subtle debuff marker 표시

ML fields:

```json
{
  "boss_modifier_category": "tile_color_weaken",
  "affected_tile_colors": ["red"],
  "score_multiplier": 0.5
}
```

### B. Hand Rank Weaken / Restrict

Effect candidates:

- 특정 hand rank base score 감소
- 같은 rank를 Boss battle 중 반복 사용하면 보너스 감소
- 첫 confirm rank만 허용 또는 첫 confirm rank 재사용 금지

Preview requirement:

- affected rank label 표시
- scoring preview에서 affected rank penalty 표시

ML fields:

```json
{
  "boss_modifier_category": "hand_rank_weaken",
  "affected_ranks": ["straight", "flush"],
  "base_score_multiplier": 0.5
}
```

### C. Tile Number / Rank Family Weaken

Effect:

- 특정 number/rank group이 scoring line에 포함될 때 해당 tile contribution 감소
- face-card 개념이 약하므로 Rummi Poker에서는 `high number`, `low number`, `specific number`로 재해석한다.

Preview requirement:

- affected number chip 표시

### D. Jester Effect Restrict

Effect candidates:

- Boss battle 동안 특정 Jester slot 비활성화
- 매 confirm마다 random Jester 1개 suppress
- 특정 effect type만 감소: `+Chips`, `+Mult`, `xMult`, economy

Preview requirement:

- entering 전에 affected slot/effect type을 표시
- battle slot에도 disabled/suppressed 상태 표시

주의:

- 장착 빌드를 이해하게 만드는 현재 scoring feedback 방향과 충돌하지 않게, 반드시 “왜 점수가 안 나오는지”를 slot-local feedback으로 보여야 한다.

### E. Score Output Pressure

Effect:

- base score / mult output / overlap bonus / final score 중 하나를 dampen
- 현재 Boss target x2.0과 중복되므로 과도하게 겹치지 않게 조절한다.

### F. Resource / Draw Cadence Pressure

Effect candidates:

- board discard 감소
- hand discard 감소
- max hand size 감소
- draw cadence 제한
- confirm 횟수 제한

주의:

- 현재 baseline Boss가 이미 board discard -1, hand discard -1, max hand size -1 clamp를 갖기 때문에 중복 압박을 피한다.

### G. Board / Line Constraint

Effect candidates:

- 특정 row/column/diagonal line score 감소
- 특정 line kind 제한
- 이미 사용한 line kind 반복 penalty

Rummi Poker에 잘 맞는 이유:

- 5x5 board와 12-line scoring 구조를 직접 건드리므로 hidden hand보다 더 명확하다.

## 3. Do Not Copy Directly

Balatro의 face-down hand-card 패턴은 그대로 복사하지 않는다.

Reasons:

- Rummi Poker는 손패가 한 번에 주어지는 구조가 아니라 draw 기반이다.
- 손패가 작고 순차 draw이므로, 숨김 정보가 전략적 조정이 아니라 정보 박탈로 느껴질 수 있다.
- 필요하다면 `temporary tile fog`, `board tile reveal timing`, `affected tile marker`처럼 board 중심으로 재설계한다.

## 4. Difficulty / Stake Constraint Reference

해당 글 기준 stake식 난이도 제약은 아래 형태로 읽을 수 있다.

| Reference stake pressure | Rummi Poker interpretation |
|---|---|
| Small Blind reward removed | Small reward preview/cash-out reward 감소 또는 skip/tag 보상 구조 후보 |
| Required score grows faster | `station_growth_base`, `stationTargetScoreScale`, `difficulty_target_multiplier` 조정 후보 |
| Eternal Joker appears | unsellable/permanent Jester trait 후보 |
| Discard -1 | board/hand discard difficulty modifier |
| Perishable Joker appears | timed Jester effect decay 후보 |
| Rental Joker appears | per-battle/per-station upkeep cost 후보 |

Policy:

- 현재 difficulty는 `standard / relaxed / pressure`만 유지한다.
- Stake식 누적 제약은 지금 구현하지 않는다.
- ML/simulator가 충분한 run outcome을 쌓은 뒤 difficulty/stake 후보를 별도 `balance_version`으로 분리한다.

## 5. Preview / UX Contract

Boss modifier는 entering 전에 반드시 보여야 한다.

Required preview fields:

```json
{
  "boss_modifier_id": "color_red_weaken_v1",
  "boss_modifier_name": "Red Dampener",
  "boss_modifier_category": "tile_color_weaken",
  "affected_surface": "tile_color",
  "short_rule_text": "Red tile scoring is reduced",
  "severity": 1
}
```

Battle UX requirements:

- affected board tile / Jester slot / rank preview에 debuff marker 표시
- scoring feedback에서 penalty가 적용된 위치를 보여 줌
- Boss modifier text는 숨겨진 debug 정보가 아니라 player-facing 정보

## 6. Implementation Order

Recommended order:

1. Boss modifier read model only
   - id/category/name/rule text/severity
   - Station Preview card display
   - ML log field
2. One low-risk modifier
   - tile color score dampening or line kind penalty
3. Scoring feedback integration
   - affected tile/line/rank callout
4. Save/restore and simulator reproduction
5. Jester restriction modifiers
6. Draw/hidden-information experiments only after board-visible modifiers are proven

## 7. Acceptance Criteria

- Boss modifier taxonomy is documented before implementation.
- Face-down card patterns are explicitly marked as redesign-needed.
- Difficulty/stake constraints are reference-only.
- First implemented Boss modifier must be visible in Station Preview, Battle UI, scoring feedback, save/restore, and simulator logs.
