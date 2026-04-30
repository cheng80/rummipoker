# Constraint Visual Language Plan

> 문서 성격: UX implementation prerequisite
> 코드 반영 상태: Boss tile color weaken v1 implemented
> 핵심 정책: 제약 표시는 최대한 단순하고 한눈에 알아볼 수 있어야 한다. 전투 화면에 설명 텍스트를 계속 늘리지 않고, Station/Boss 진입 시 팝업으로 규칙을 먼저 설명한 뒤 전투 중에는 작은 표식과 실제 점수 위치 feedback만 사용한다.
> 화면 문구 정책: user-facing 화면에는 `boss_modifier_id`, `tile_color_weaken`, `score_multiplier` 같은 내부 변수/enum/schema 이름을 노출하지 않는다. 플레이어에게는 짧은 한글 설명만 보여 준다.

## 1. Goal

Boss modifier, Station modifier, Item/Jester penalty가 추가될 때 플레이어가 아래를 즉시 이해하게 만든다.

```text
무엇이 제약인가
어디에 적용되는가
이번 점수에서 실제로 얼마나 깎였는가
```

Non-goals:

- 전투 화면에 긴 설명문을 상시 노출하지 않는다.
- 타일, Jester, Item마다 서로 다른 복잡한 아이콘 언어를 만들지 않는다.
- debug용 id/category를 user-facing 텍스트로 노출하지 않는다.
- 내부 변수명, enum, JSON field, modifier id를 user-facing UI copy로 사용하지 않는다.

## 1.1 User-Facing Copy Policy

제약 설명은 반드시 짧은 한글 문장으로 쓴다.

Rules:

- 플레이어 화면에는 내부 변수명을 표시하지 않는다.
- `tile_color_weaken` 대신 `빨간 타일 점수 감소`
- `score_multiplier: 0.5` 대신 `빨간 타일 점수가 절반만 적용됩니다`
- `jester_suppressed` 대신 `조커 효과가 발동하지 않습니다`
- `hand_rank_weaken` 대신 `스트레이트 점수 감소`
- debug detail 또는 simulator log에만 id/category/parameter를 남긴다.

Copy shape:

```text
제목: 무엇이 약해지는가
본문: 어떻게 달라지는가
짧은 표식: 대상 또는 변화량
```

Examples:

| Internal | User-facing title | User-facing rule | Marker/float |
|---|---|---|---|
| `tile_color_weaken(red, 0.5)` | 빨간 타일 약화 | 빨간 타일 점수가 절반만 적용됩니다 | `절반` / `x0.5` |
| `hand_rank_weaken(straight)` | 스트레이트 약화 | 스트레이트 기본 점수가 감소합니다 | `약화` |
| `jester_slot_disabled(2)` | 조커 봉인 | 두 번째 조커가 이번 전투에서 발동하지 않습니다 | `봉인` |
| `line_kind_penalty(row)` | 가로줄 약화 | 가로줄 점수가 감소합니다 | `약화` |

금지:

```text
tile_color_weaken
score_multiplier 0.5
boss_modifier_id red_dampener_v1
affected_surface tile_color
severity 1
```

## 2. Core UX Flow

제약 전달 순서는 고정한다.

```text
Station Preview
-> Stage/Boss entry constraint popup
-> Battle minimal affected marker
-> Scoring position-local penalty float
-> Optional detail panel explanation
```

### 2.1 Station Preview

역할:

- 어떤 Boss/Station 제약이 있는지 전투 진입 전에 미리 알린다.

표시:

- 제약 이름
- 한 줄 규칙
- 영향 대상 badge 1개 또는 2개

예시:

```text
Red Dampener
Red tiles score 50%
[Red tile]
```

### 2.2 Entry Popup

역할:

- 전투 시작 직전에 제약을 확정적으로 설명한다.
- 플레이어가 확인할 시간 없이 지나가는 애니메이션이 아니라, 짧은 modal/bottom sheet로 보여 준다.

필수 요소:

- 제목: 제약 이름
- 대상: 색상/랭크/라인/Jester/Item 중 하나
- 규칙: 한 문장
- 예시 수치: 있으면 `x0.5`, `-50%`, `disabled`
- 확인 버튼: 전투 시작

문구 정책:

- 제목과 규칙은 한글 user-facing copy만 사용한다.
- 내부 id/category/parameter는 팝업에 표시하지 않는다.
- 수치는 `x0.5`처럼 짧은 보조 표기로만 허용하고, 반드시 한글 설명과 함께 둔다.

정책:

- Boss modifier가 있으면 첫 진입 시 반드시 표시한다.
- 같은 battle restore/continue에서는 이미 확인한 경우 다시 띄우지 않아도 되지만, 확인 상태는 save/restore 경계에서 명확해야 한다.
- 팝업은 전투 시작 전 정보 제공용이다. scoring animation 도중에는 사용하지 않는다.

### 2.3 Battle Minimal Marker

역할:

- 영향을 받는 대상이 어디인지 계속 알려 주되, 보드 가독성을 해치지 않는다.

표시:

- tile: corner badge 1개
- Jester/Item slot: 작은 badge 또는 dim overlay
- hand rank/line: preview chip 또는 line label 옆 badge

정책:

- marker는 설명문이 아니라 상태 표시다.
- marker는 대상의 소유/선택/발동 상태를 가리지 않는다.
- 영향을 받는다는 뜻과 비활성화됐다는 뜻을 구분한다.

```text
affected: small outline/badge, opacity 유지
disabled: dim + lock/slash badge
penalized now: scoring float
```

### 2.4 Scoring Position-Local Float

역할:

- 실제 점수가 깎인 순간, 원인 위치에서 알려 준다.

예시:

```text
절반
약화
봉인
발동 없음
```

정책:

- 중앙 텍스트만 갈아끼우지 않는다.
- tile penalty는 tile 또는 line 근처에 표시한다.
- Jester penalty는 해당 Jester slot 위에 표시한다.
- Item penalty는 해당 Item slot 위에 표시한다.
- float는 짧고 반복 가능해야 한다.
- float도 내부 변수명이 아니라 한글 단어 또는 짧은 수치만 사용한다.

## 3. Visual Vocabulary

가능한 적은 시각 언어만 사용한다.

| State | Visual |
|---|---|
| affected | small badge / thin outline |
| active penalty | red/violet float + brief pulse |
| disabled | dim + lock/slash badge |
| buff/gain | gold/green float + upward motion |
| neutral info | white/gray chip |

Rules:

- 제약 marker는 1개 surface에 최대 1개만 붙인다.
- 같은 대상에 여러 제약이 걸리면 `!` 또는 `2` count badge로 축약하고 detail panel에서 펼친다.
- 색상만으로 구분하지 않는다. badge shape 또는 symbol이 함께 있어야 한다.
- 숫자/텍스트는 1~2 token으로 제한한다.

## 4. Surface Rules

### Tile / Board

Use:

- tile corner badge
- subtle outline
- score float on scoring

Do not use:

- tile 전체를 어둡게 만들어 숫자/색상을 읽기 어렵게 만들기
- 긴 tooltip 상시 노출

### Hand Tile

Use:

- same corner badge as board tile
- popup/detail에서 설명

주의:

- hand tile은 draw 기반이라 정보량이 작다. 숨김/뒤집기 제약은 v1에서 피한다.

### Jester Slot

Use:

- disabled이면 dim + slash/lock badge
- 약화만 되면 opacity 유지 + small penalty badge
- scoring 시 slot-local float

Do not use:

- Jester card text를 축소해서 제약 설명을 밀어 넣기

### Item Slot

Use:

- quick/passive/equipment slot 위 small badge
- 사용 불가 상태면 button disabled state와 badge를 같이 표시
- effect delta는 기존 Item active effect display와 같은 위치 체계를 사용

Do not use:

- item tag를 카드 위에 계속 늘려 말줄임표를 만들기

### Detail Panel

Use:

- 선택한 Boss/tile/Jester/Item에 걸린 active constraint를 한 줄 목록으로 표시

정책:

- detail panel은 설명 보조다.
- 핵심 이해는 entry popup과 marker만으로 가능해야 한다.

## 5. First Boss Modifier V1 Contract

첫 구현은 `tile_color_weaken`을 기준으로 한다.

Example:

```json
{
  "boss_modifier_id": "red_dampener_v1",
  "boss_modifier_name": "Red Dampener",
  "boss_modifier_category": "tile_color_weaken",
  "affected_surface": "tile",
  "affected_tile_colors": ["red"],
  "score_multiplier": 0.5,
  "short_rule_text": "Red tiles score 50%"
}
```

UX:

- Station Preview Boss card: `빨간 타일 약화` + `[빨간 타일]`
- Entry popup: title `빨간 타일 약화`, red swatch, `빨간 타일 점수가 절반만 적용됩니다`
- Battle board/hand: red tiles show small affected badge
- Scoring: affected tile or line emits `절반` or `x0.5` float when penalty applies
- Detail panel: `이 보스전에서는 빨간 타일 점수가 절반만 적용됩니다`

Internal fields stay internal:

- `boss_modifier_id`
- `boss_modifier_category`
- `affected_surface`
- `score_multiplier`
- `severity`

## 6. Save / Restore Boundary

Required state:

```json
{
  "active_constraint_ids": ["red_dampener_v1"],
  "constraint_intro_seen_ids": ["red_dampener_v1"]
}
```

Policy:

- Active constraints must restore with the battle.
- Popup seen state may restore to avoid repeating the same intro after app background/continue.
- If seen state is not saved in v1, repeating the popup on continue is acceptable; losing the active constraint is not.

## 7. Acceptance Criteria

- Every new Boss/Station/Jester/Item constraint has an entry popup or equivalent pre-combat explanation.
- Battle screen uses compact markers, not long in-place text.
- Actual penalty appears at the cause position during scoring.
- Affected and disabled states are visually different.
- Tile/Jester/Item constraints share the same minimal visual vocabulary.
- First Boss modifier implementation follows this document before ML simulation readiness.

## 8. Implementation Notes

Implemented for Boss modifier v1:

- Entry popup uses title `빨간 타일 약화`.
- Popup rule copy is `빨간 타일이 포함된 점수 라인은 절반만 적용됩니다.`
- Board and hand red tiles show compact `!` marker.
- Scoring callout shows Korean user-facing penalty copy.
- Internal names such as `tile_color_weaken` and `scoreMultiplier` are not shown in user-facing UI.

Deferred:

- persisted intro-seen state
- stacked multiple constraint count badge
- Jester/Item disabled marker variants
