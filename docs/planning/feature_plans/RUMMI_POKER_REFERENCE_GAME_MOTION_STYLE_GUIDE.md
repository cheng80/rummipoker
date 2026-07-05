# RummiPoker Reference Game Motion Style Guide v2

> 목적: 이 문서는 `RummiPoker_Reference_Game_Motion_Direction_v1.md`를 대체하는 **레퍼런스 게임 기반 모션 추천 가이드**다.  
> v1이 “현재 코드에 적용할 작업 패스”에 가까웠다면, v2는 먼저 **레퍼런스 게임들의 모션 언어를 분석**하고, 그 언어를 Rummi Poker의 액션별 연출로 변환한다.  
> 이 문서는 구현 명령서가 아니라 **모션 아트 디렉션 문서**다. Codex는 이 문서를 읽고 구현 계획을 세운다.

---

# 0. 이 문서의 정체성

## 이 문서는 무엇인가

```text
Balatro / Marvel Snap / Royal Match / Clash Royale / Rummikub / Bejeweled Classic의
모션 문법을 분석하고,
Rummi Poker의 전투/마켓/정산/보상 액션에 어떤 감각으로 적용할지 추천하는 문서.
```

## 이 문서가 아닌 것

```text
- 단순 코드 수정 목록
- 특정 파일만 고치는 작업 지시서
- 원본 게임의 UI/아트/에셋 복제 지시서
- 모든 애니메이션을 한 번에 구현하는 Motion Bible
```

## Codex가 이 문서를 읽고 해야 하는 일

```text
1. 레퍼런스 게임별 모션 문법을 이해한다.
2. Rummi Poker의 각 액션이 어떤 레퍼런스 감각을 가져야 하는지 판단한다.
3. 현재 코드에서 가장 작은 변경으로 그 감각을 낼 수 있는 구현 계획을 제안한다.
4. 구현할 때는 runtime/save/scoring을 건드리지 않고 presentation layer만 수정한다.
```

---

# 1. 전체 모션 방향 한 줄 요약

```text
Rummi Poker는 타일 조작은 Rummikub처럼 손에 잡히고,
점수/정산은 Balatro처럼 반응하며,
마켓 카드는 Marvel Snap처럼 빠르게 들어오고,
라인 확정과 충격은 Royal Match처럼 명확하며,
보상/해금은 Clash Royale처럼 만족스럽게 느껴져야 한다.
```

---

# 2. 레퍼런스 게임별 역할

| 레퍼런스 | Rummi Poker에서 가져올 감각 | 적용 영역 |
|---|---|---|
| Rummikub | 물리 타일을 집고 놓는 감각 | 타일 드로우, 배치, 이동, 버림 |
| Balatro | 점수 계산, 카드/Joker 발동, 숫자 타격감 | 점수 preview, Confirm, Settlement, Jester/Item 발동 |
| Marvel Snap | 카드 reveal, snap-to-slot, 빠른 UI 반응 | Market, 구매, 장착, 도감/보상 카드 |
| Royal Match | 라인 제거, 타일 burst, 장애물 impact | Line Confirm, contributor 제거, Boss/Constraint |
| Clash Royale | 보상 획득, 해금, 승리/클리어 피드백 | Stage Clear, Cash-out, Reward, Slot Unlock |
| Bejeweled Classic | 작은 파티클 burst와 매치 피드백 | Flame overlay, line spark, small clear effect |

---

# 3. 레퍼런스 게임별 모션 분석

## 3.1 Rummikub / 물리 타일 감각

### 핵심 감각

Rummi Poker의 가장 기본 조작은 카드보다 **타일**에 가깝다.  
따라서 보드 조작은 카드가 휘날리는 느낌보다, 손으로 타일을 들어 올려 칸에 맞춰 놓는 느낌이 우선이다.

### 가져올 모션 언어

```text
- lift: 살짝 들어 올림
- place: 칸에 내려놓음
- snap: 칸에 딱 맞게 정렬됨
- settle: 흔들리지 않고 안정화됨
- tactile pause: 아주 짧은 접촉감
```

### 적용 대상

```text
- 손패에서 타일 등장
- 보드에 타일 배치
- 보드 타일 이동
- 보드 타일 버림
- 정산 중 contributor 타일 lift
```

### 권장 타이밍

```yaml
physical_tile_place:
  duration: 240ms~280ms
  curve: easeOutBack
  start:
    translateY: 14~18
    scale: 0.90
    opacity: 0.72
  peak:
    translateY: -2
    scale: 1.03~1.05
  end:
    translateY: 0
    scale: 1.00
    opacity: 1.00
```

```yaml
physical_tile_lift:
  duration: 360ms~440ms
  curve: easeOutCubic
  start:
    translateY: 0
    scale: 1.00
  peak:
    translateY: -6
    scale: 1.03
  end:
    translateY: 0
    scale: 1.00
```

### 강도 기준

| 상황 | 강도 |
|---|---|
| 일반 배치 | 낮음 |
| 보드 이동 | 중간 |
| 보드 버림 | 중간 |
| 정산 contributor lift | 낮음~중간 |
| 큰 점수 contributor | 중간 |

### 금지

```text
- 카드처럼 크게 회전하는 모션
- 보드 전체 흔들림
- 타일이 너무 가볍게 날아가는 느낌
- 칸 위치가 바뀌어 보이는 layout shift
```

---

## 3.2 Balatro 모션 언어

### 핵심 감각

Balatro에서 가져올 것은 그래픽이 아니라 **점수 계산의 리듬**이다.  
Rummi Poker의 점수는 단순 숫자 업데이트가 아니라 “판정 → 보정 → 증폭 → 최종 점수”의 순서로 읽혀야 한다.

### 가져올 모션 언어

```text
- score pop: 숫자가 짧게 커졌다가 안정화
- trigger badge: Joker/Item 발동 표시
- multiplier rhythm: 단계별 점수 증폭 리듬
- punch: 큰 점수에서 짧은 타격감
- float score: 결과 숫자가 살짝 떠오르며 사라짐
```

### 적용 대상

```text
- Score Preview
- Confirm 후 scoring breakdown
- Jester 발동
- Item 발동
- Tile modifier 발동
- Final score
- Large score burst
```

### 권장 타이밍

```yaml
balatro_score_pop:
  duration: 260ms~340ms
  curve: easeOutBack
  start:
    scale: 0.92
    opacity: 0
  peak:
    scale: 1.10~1.14
    opacity: 1
  end:
    scale: 1.00
```

```yaml
balatro_trigger_badge:
  duration: 420ms~620ms
  curve: easeOutCubic
  start:
    translateY: 8
    scale: 0.94
    opacity: 0
  peak:
    translateY: -2
    scale: 1.06
    opacity: 1
  end:
    translateY: -10
    scale: 1.00
    opacity: 0
```

```yaml
balatro_settlement_step:
  duration: 680ms~1040ms
  rhythm:
    board_line: 720ms
    hand_rank: 720ms
    overlap: 680ms
    effect: 940ms~1040ms
    final_score: 920ms
```

### Rummi Poker 적용 해석

Balatro식 정산은 다음 순서로 변환한다.

```text
1. 라인이 읽힌다.
2. 족보 이름이 뜬다.
3. overlap 또는 multiplier가 붙는다.
4. Jester / Item / Tile modifier가 발동한다.
5. 최종 점수가 punch된다.
```

### 금지

```text
- Balatro UI/카드 디자인 복제
- 모든 숫자를 과하게 흔들기
- 매 confirm마다 대형 폭발
- score preview가 최적 수 추천처럼 보이는 강조
```

---

## 3.3 Marvel Snap 모션 언어

### 핵심 감각

Marvel Snap에서 가져올 것은 **카드가 빠르게 등장하고 슬롯에 꽂히는 반응성**이다.  
마켓/보상/도감 카드가 정적으로 놓여 있으면 게임성이 약해 보이므로, 빠른 reveal과 snap-to-slot이 필요하다.

### 가져올 모션 언어

```text
- fast card reveal: 빠른 카드 등장
- snap-to-slot: 카드가 슬롯에 딱 장착됨
- source card pulse: 구매한 카드가 먼저 반응
- target slot pulse: 도착 슬롯이 반응
- compact transition: 짧고 입력을 방해하지 않는 전환
```

### 적용 대상

```text
- Market 진입
- Market offer reveal
- Reroll 후 새 offer 등장
- Jester 구매
- Item 구매
- Passive/Gear 장착
- Reward card reveal
- Archive card unlock
```

### 권장 타이밍

```yaml
snap_card_reveal:
  duration: 160ms~220ms
  stagger: 36ms~48ms
  curve: easeOutCubic
  start:
    translateY: 8~12
    scale: 0.96~0.98
    opacity: 0
  end:
    translateY: 0
    scale: 1.00
    opacity: 1
```

```yaml
snap_purchase_to_slot:
  duration: 480ms~620ms
  curve: easeInOutQuart
  source:
    pulse: 120ms
    scale: 1.00 -> 1.04 -> 0.98
  flight:
    ghost_scale: 1.00 -> 0.72
    opacity: 0.92 -> 0
  target:
    pulse: 220ms~360ms
    scale: 1.00 -> 1.10 -> 1.00
```

### Rummi Poker 적용 해석

마켓 구매는 다음 인과가 보여야 한다.

```text
offer card가 반응한다.
→ 카드 ghost 또는 pulse가 장착 영역으로 향한다.
→ target slot이 반응한다.
→ Gold HUD에 -cost가 표시된다.
```

### 금지

```text
- 긴 3D flip 과용
- 구매 입력을 오래 막기
- 카드가 장착됐는데 target slot이 반응하지 않음
- 실패인데 성공처럼 card flight 표시
```

---

## 3.4 Royal Match 모션 언어

### 핵심 감각

Royal Match에서 가져올 것은 **라인이 지워지고 타일/장애물이 맞는 명확한 impact**다.  
Rummi Poker의 confirm은 match-3처럼 연쇄 폭발하는 게임은 아니지만, contributor line이 “점수화됐다”는 순간은 명확해야 한다.

### 가져올 모션 언어

```text
- line sweep: 줄 방향으로 순차 강조
- cell spark: 각 contributor cell의 작은 spark
- impact flash: 보스/제약이 걸린 cell에 충격 표시
- burst strength tiers: 일반/큰 점수/보스 충격을 강도별 분리
- short chain: 여러 cell이 순서대로 반응
```

### 적용 대상

```text
- Line Confirm
- contributor tile removal
- Boss constraint penalty
- blocked cell feedback
- large score burst
```

### 권장 타이밍

```yaml
royal_line_sweep:
  duration: 480ms~560ms
  stagger_per_cell: 28ms~36ms
  cell:
    ring_scale: 0.72 -> 1.06
    opacity: 1.00 -> 0
    fade_after: 70%
  particle:
    count: low~medium
    glow: false for normal
```

```yaml
royal_constraint_impact:
  duration: 760ms~940ms
  flash:
    color_family: danger
    scale: 0.72 -> 1.14 -> 1.00
  badge:
    scale: 0.78 -> 1.08 -> 1.00
    floatY: -12
  particle:
    count: medium
    glow: true
    lifetime: short
```

### Rummi Poker 적용 해석

Royal Match 감각은 “기분 좋은 성공 이펙트”와 “보스 제약 충격”을 분리하는 데 사용한다.

```text
Line confirm:
  금색/밝은 sweep

Large score:
  금색 + 큰 badge + medium burst

Boss/constraint:
  danger flash + impact badge + 날카로운 spark
```

### 금지

```text
- match-3처럼 화면 전체 폭발
- 보드 전체 shake
- 너무 많은 particle로 타일 가독성 저하
- 일반 confirm과 boss impact의 색/리듬이 같아지는 것
```

---

## 3.5 Clash Royale 모션 언어

### 핵심 감각

Clash Royale에서 가져올 것은 **보상과 해금의 만족감**이다.  
Rummi Poker의 stage clear, cash-out, slot unlock은 정보만 보여주면 약하다. 보상은 “받았다”는 느낌이 있어야 한다.

### 가져올 모션 언어

```text
- reward count-up: 보상 숫자가 올라감
- collect burst: 골드/보상 획득 순간 burst
- unlock hold: 해금은 충분히 오래 보여줌
- victory pop: clear 문구의 짧은 pop
- anticipation: 보상 직전의 짧은 기대감
```

### 적용 대상

```text
- Stage Clear
- Cash-out
- Gold reward
- Boss clear reward
- Slot unlock
- Run complete reward
- Archive unlock
```

### 권장 타이밍

```yaml
clash_stage_clear:
  overlay_pop: 300ms~360ms
  score_count: 640ms~760ms
  spark: 480ms~560ms
  hold: 850ms~950ms
```

```yaml
clash_reward_line:
  line_reveal: 160ms~220ms
  line_pulse: 320ms~420ms
  step_delay: 220ms~280ms
  collect_badge: 380ms~460ms
  coin_burst: 480ms~560ms
```

```yaml
clash_slot_unlock:
  duration: 1000ms~1300ms
  lock:
    scale: 1.00 -> 1.10 -> 0.96
    fade: 450ms~800ms
  slot:
    border_pulse: 700ms onward
    stable_after: 1000ms
```

### Rummi Poker 적용 해석

보상 연출은 다음 순서가 좋다.

```text
Stage Clear 문구 pop
→ 점수/보상 count-up
→ 보상 line이 하나씩 reveal
→ Gold HUD 또는 reward card로 collect
→ 다음 행동 버튼 활성
```

### 금지

```text
- 보상 연출이 너무 길어 반복 플레이 방해
- chest UI 자체 복제
- 해금이 너무 짧아 인지 불가
- 보상 결과와 실제 runtime 값 불일치
```

---

## 3.6 Bejeweled Classic 모션 언어

### 핵심 감각

Bejeweled에서 가져올 것은 단순하다.  
작고 빠른 particle burst, 그리고 match 순간의 즉각적인 sparkle이다.

### 가져올 모션 언어

```text
- small spark
- particle pool
- short lifetime
- cell-local burst
- low-cost visual feedback
```

### 적용 대상

```text
- line confirm spark
- large score 추가 spark
- boss impact spark
- item effect spark
```

### 권장 타이밍

```yaml
bejeweled_small_spark:
  lifetime: 0.4s~0.7s
  count: 8~14
  speed: low~medium
  glow: false for normal
```

```yaml
bejeweled_big_spark:
  lifetime: 0.7s~0.9s
  count: 16~22
  speed: medium
  glow: true
```

### 금지

```text
- 상시 GameWidget loop
- particle 남발
- fullscreen glow
- 큰 면적 blur/saveLayer 반복
```

---

# 4. Rummi Poker 액션별 추천 레퍼런스 매핑

## 4.1 Battle

| Rummi Poker 액션 | 1순위 레퍼런스 | 2순위 레퍼런스 | 감정 목표 |
|---|---|---|---|
| 손패 타일 등장 | Rummikub | Marvel Snap | 타일을 뽑아 손에 받은 느낌 |
| 보드 배치 | Rummikub | Marvel Snap | 칸에 딱 맞게 놓는 손맛 |
| 보드 이동 | Rummikub | Marvel Snap | 들어서 옮기는 명확한 이동 |
| 보드 버림 | Rummikub | Balatro | 집어 올려 제거하는 느낌 |
| 손패 버림 | Balatro | Rummikub | 카드/타일을 버리는 빠른 피드백 |
| 점수 preview | Balatro | - | 점수가 생길 것 같은 기대감 |
| Confirm | Royal Match | Balatro | 라인이 점수화되는 명확함 |
| contributor 제거 | Royal Match | Rummikub | 점수화된 타일이 사라짐 |
| Boss/constraint | Royal Match | Clash Royale | 제약이 충격을 줬다는 감각 |
| 큰 점수 | Balatro | Royal Match | “한 방 터짐” |

---

## 4.2 Settlement

| Rummi Poker 액션 | 1순위 레퍼런스 | 2순위 레퍼런스 | 감정 목표 |
|---|---|---|---|
| 라인 판정 | Balatro | Royal Match | 어떤 줄이 점수화됐는지 읽힘 |
| 족보 표시 | Balatro | - | 판정 결과가 카드게임처럼 반응 |
| overlap 표시 | Balatro | - | 배수/보너스가 붙는 리듬 |
| Jester 발동 | Balatro | Marvel Snap | 슬롯에서 효과가 터짐 |
| Item 발동 | Balatro | Clash Royale | 발동 → 대상 → 결과가 읽힘 |
| 최종 점수 | Balatro | Royal Match | 점수 punch와 burst |

---

## 4.3 Market

| Rummi Poker 액션 | 1순위 레퍼런스 | 2순위 레퍼런스 | 감정 목표 |
|---|---|---|---|
| Market 진입 | Marvel Snap | - | 빠르게 카드 화면으로 들어옴 |
| Offer reveal | Marvel Snap | - | 카드가 펼쳐짐 |
| Reroll | Marvel Snap | Royal Match | 새 후보로 교체되는 리듬 |
| 구매 성공 | Marvel Snap | Clash Royale | 카드가 슬롯/보유 영역에 들어감 |
| 구매 실패 | Mobile deny pattern | - | 짧게 실패를 인지 |
| 판매 | Clash Royale | Marvel Snap | 카드가 골드로 회수됨 |
| Slot unlock | Clash Royale | Marvel Snap | 새 공간이 열리는 만족감 |

---

## 4.4 Reward / Meta

| Rummi Poker 액션 | 1순위 레퍼런스 | 2순위 레퍼런스 | 감정 목표 |
|---|---|---|---|
| Stage Clear | Clash Royale | Balatro | 한 판을 끝냈다는 보상감 |
| Cash-out | Clash Royale | - | 보상을 하나씩 받는 느낌 |
| Boss reward | Clash Royale | Marvel Snap | 특별 보상 획득 |
| Archive unlock | Marvel Snap | Clash Royale | 수집 카드가 열림 |
| Run complete | Clash Royale | Balatro | 큰 완료감 |

---

# 5. 액션별 상세 모션 추천

## 5.1 Tile Place

### Reference

```text
Rummikub physical tile placement
+ Marvel Snap snap-to-slot
```

### 목표 감정

```text
“타일이 보드 칸에 딱 들어갔다.”
```

### 추천 연출

```yaml
duration: 240ms~280ms
curve: easeOutBack
motion:
  - 아래에서 14~18px 올라옴
  - scale 0.90으로 시작
  - 1.03~1.05까지 살짝 overshoot
  - 1.00으로 settle
  - 짧은 gold glow
```

### 사용하지 말 것

```text
- 큰 회전
- 긴 bounce
- 보드 전체 흔들림
```

---

## 5.2 Board Move

### Reference

```text
Rummikub tile lift
+ Marvel Snap snap travel
```

### 목표 감정

```text
“타일을 들어서 다른 칸으로 옮겼다.”
```

### 추천 연출

```yaml
duration: 260ms~320ms
curve: easeInOutQuart
motion:
  source:
    small lift
    source cell faint highlight
  flight:
    arc or smooth interpolation
    scale peak 1.04
    shadow medium
  target:
    border pulse
    scale settle 1.00
```

### 사용하지 말 것

```text
- 즉시 위치 변경만 보임
- 너무 빠른 순간이동
- drag interaction 새로 구현
```

---

## 5.3 Tile Remove / Discard

### Reference

```text
Balatro discard
+ Rummikub tile lift
```

### 목표 감정

```text
“타일이 선택되어 보드에서 제거됐다.”
```

### 추천 연출

```yaml
duration: 260ms~320ms
curve: easeOutCubic
motion:
  - scale 1.00 -> 1.06 -> 0.82
  - translateY 0 -> -8 -> -18
  - opacity 1.00 -> 0
  - optional rotation ±2deg
```

### 구분

```text
유저가 버림:
  lift + fade + slight rotation

정산으로 제거:
  line sweep 후 fade

보스/제약으로 제거:
  danger flash 후 fade
```

---

## 5.4 Score Preview

### Reference

```text
Balatro score preview pop
```

### 목표 감정

```text
“현재 보드에서 점수가 날 수 있다.”
```

### 추천 연출

```yaml
duration: 260ms~320ms
curve: easeOutBack
motion:
  - opacity 0 -> 1
  - scale 0.94 -> 1.06 -> 1.00
  - number change pulse only when value changes
```

### 주의

```text
점수 preview는 전략 추천이 아니다.
특정 칸을 과하게 강조하면 정답 노출처럼 보일 수 있다.
```

---

## 5.5 Line Confirm

### Reference

```text
Royal Match line sweep
+ Balatro scoring confirmation
+ Bejeweled cell spark
```

### 목표 감정

```text
“이 줄이 점수화됐다.”
```

### 추천 연출

```yaml
duration: 480ms~560ms
stagger_per_cell: 28ms~36ms
motion:
  - contributor cell 순서대로 ring 등장
  - cell-local spark
  - line callout pop
  - fade after 70%
```

### 강도

```yaml
normal_line:
  particle_count: 8~12
  glow: false

high_score_line:
  particle_count: 14~18
  glow: true
  badge: true

constraint_line:
  color_family: danger
  badge: penalty label
```

---

## 5.6 Settlement Score Step

### Reference

```text
Balatro scoring breakdown
```

### 목표 감정

```text
“점수가 어떤 이유로 만들어졌는지 단계적으로 이해된다.”
```

### 추천 순서

```text
1. Board Line
2. Hand Rank
3. Overlap
4. Jester / Item / Tile Modifier
5. Final Score
```

### 추천 리듬

```yaml
board_line:
  visual: line sweep
  duration: 720ms

hand_rank:
  visual: rank callout pop
  duration: 720ms

overlap:
  visual: multiplier badge
  duration: 680ms

effect:
  visual: source slot burst -> result badge
  duration: 940ms~1040ms

final_score:
  visual: score punch / count
  duration: 920ms
```

---

## 5.7 Jester / Item Trigger

### Reference

```text
Balatro Joker trigger
+ Marvel Snap slot pulse
```

### 목표 감정

```text
“어떤 슬롯/카드가 발동했고, 그 결과가 점수나 자원에 반영됐다.”
```

### 추천 구조

```yaml
source:
  slot/card pulse

target:
  score preview / line / HUD / market card / hand area flash

result:
  +score / +gold / discount / +discard / +hand capacity badge
```

### 추천 타임라인

```yaml
0ms:
  source pulse

120ms:
  source badge appears

240ms:
  target flash

420ms:
  result delta appears

560ms~940ms:
  fade / settle
```

### 가장 중요한 규칙

```text
아이템/Jester 연출은 반드시 Source → Target → Result를 보여준다.
Toast 하나만 띄우고 끝내면 안 된다.
```

---

## 5.8 Market Offer Reveal

### Reference

```text
Marvel Snap card reveal
```

### 목표 감정

```text
“마켓 후보 카드가 빠르게 펼쳐졌다.”
```

### 추천 연출

```yaml
duration: 160ms~220ms
stagger: 36ms~48ms
curve: easeOutCubic
motion:
  opacity: 0 -> 1
  translateY: 8~12 -> 0
  scale: 0.97 -> 1.00
```

### 주의

```text
- layout shift 금지
- 카드 텍스트 가독성 유지
- 구매 입력을 오래 막지 않음
```

---

## 5.9 Market Purchase

### Reference

```text
Marvel Snap snap-to-slot
+ Clash Royale reward collect
```

### 목표 감정

```text
“이 카드를 샀고, 어디에 들어갔고, 골드가 줄었다.”
```

### 추천 연출

```yaml
duration: 480ms~620ms
sequence:
  1_source_card_pulse:
    duration: 120ms
  2_card_ghost_flight:
    duration: 360ms~480ms
  3_target_slot_pulse:
    duration: 220ms~360ms
  4_gold_cost_badge:
    duration: 380ms~460ms
```

### 최소 구현

```text
source card pulse
+ target slot pulse
+ Gold -cost badge
```

### 이상적 구현

```text
source card pulse
+ ghost flight to slot
+ target slot snap
+ Gold -cost badge
+ small collect spark
```

---

## 5.10 Market Deny

### Reference

```text
mobile deny shake
```

### 목표 감정

```text
“안 된다. 하지만 게임은 끊기지 않는다.”
```

### 추천 연출

```yaml
duration: 280ms~380ms
motion:
  x: 0 -> -4 -> 4 -> -3 -> 2 -> 0
  badge: short red label
  sound: optional deny tap
```

### 금지

```text
- 성공 particle
- card flight
- 슬롯 pulse
- 너무 긴 error dialog
```

---

## 5.11 Slot Unlock

### Reference

```text
Clash Royale unlock
+ Marvel Snap slot reveal
```

### 목표 감정

```text
“새 슬롯이 열렸다.”
```

### 추천 연출

```yaml
duration: 1000ms~1300ms
sequence:
  lock_attention:
    scale: 1.00 -> 1.10
    duration: 200ms
  lock_release:
    opacity: 1 -> 0
    duration: 450ms~800ms
  slot_reveal:
    border_pulse: 700ms onward
    scale: 0.96 -> 1.04 -> 1.00
```

### 중요

```text
슬롯 해금은 짧은 구매 pulse처럼 처리하면 인지되지 않는다.
최소 1초 이상 유지한다.
```

---

## 5.12 Stage Clear

### Reference

```text
Clash Royale victory
+ Balatro final score
```

### 목표 감정

```text
“스테이지를 깼다.”
```

### 추천 연출

```yaml
sequence:
  overlay_dim:
    120ms~180ms
  clear_label_pop:
    300ms~360ms
  score_count:
    640ms~760ms
  spark:
    480ms~560ms
  hold:
    850ms~950ms
```

### 주의

```text
반복 플레이가 핵심이므로 2초 이상 막는 연출은 피한다.
```

---

## 5.13 Cash-out

### Reference

```text
Clash Royale reward count
```

### 목표 감정

```text
“보상을 하나씩 받았다.”
```

### 추천 연출

```yaml
initial_delay: 180ms~240ms
step_delay: 220ms~280ms

per_line:
  reveal: 160ms~220ms
  pulse: 320ms~420ms
  collect_badge: 380ms~460ms
```

### 보상 줄 순서

```text
1. 기본 clear reward
2. board discard bonus
3. hand discard bonus
4. item/passive bonus
5. total gold
```

---

# 6. 레퍼런스 감각별 Motion Token 제안

## 6.1 Motion Family

```yaml
motion_family:
  physical_tile:
    reference: Rummikub
    use_for:
      - tile_place
      - tile_move
      - tile_discard
      - settlement_tile_lift

  score_reactive:
    reference: Balatro
    use_for:
      - score_preview
      - settlement_step
      - jester_trigger
      - item_trigger
      - large_score

  card_snap:
    reference: Marvel Snap
    use_for:
      - market_offer_reveal
      - purchase_flight
      - equip_slot
      - reward_card_reveal

  line_impact:
    reference: Royal Match
    use_for:
      - line_confirm
      - contributor_remove
      - constraint_impact

  reward_unlock:
    reference: Clash Royale
    use_for:
      - stage_clear
      - cashout
      - slot_unlock
      - boss_reward

  particle_spark:
    reference: Bejeweled Classic
    use_for:
      - cell_spark
      - score_burst
      - impact_spark
```

---

## 6.2 Timing Families

```yaml
timing:
  micro:
    duration: 120ms~180ms
    use: tap, small state change, tab switch

  quick:
    duration: 180ms~280ms
    use: tile place, card reveal, preview pop

  medium:
    duration: 320ms~560ms
    use: purchase flight, line sweep, badge pop

  long_feedback:
    duration: 680ms~1040ms
    use: settlement step, large score, constraint impact

  unlock_hold:
    duration: 1000ms~1300ms
    use: slot unlock, special reward
```

---

## 6.3 Curve Families

```yaml
curves:
  snap:
    preferred: easeOutBack
    use: tile place, card snap, score pop

  smooth_flight:
    preferred: easeInOutQuart
    use: board move, purchase flight

  readable_reveal:
    preferred: easeOutCubic
    use: market offer, reward line, callout

  impact:
    preferred: easeOutCubic + punch scale
    use: constraint, large score

  settle:
    preferred: easeInOut
    use: overlay, modal, cashout sheet
```

---

# 7. 구현 시 우선순위

## 7.1 먼저 적용하면 체감이 큰 것

```text
1. Tile Place - Rummikub physical place
2. Board Move - lift and snap
3. Score Preview - Balatro score pop
4. Line Confirm - Royal Match line sweep
5. Market Offer Reveal - Marvel Snap card reveal
6. Market Purchase - source to slot
```

## 7.2 그다음 적용

```text
7. Jester/Item trigger - Balatro source trigger
8. Cash-out lines - Clash Royale reward count
9. Stage clear - victory pop
10. Slot unlock - Clash Royale unlock hold
```

## 7.3 나중에 적용

```text
11. Reward card reveal
12. Archive unlock
13. Advanced particle variants
14. Formal presentation event queue
```

---

# 8. Codex용 작업 지시 방식

## 8.1 문서 역할 지정 프롬프트

```text
RummiPoker_Reference_Game_Motion_Style_Guide_v2.md 를 읽어라.

이 문서는 구현 목록이 아니라 레퍼런스 게임 기반 모션 아트 디렉션 문서다.
먼저 Balatro / Marvel Snap / Royal Match / Clash Royale / Rummikub / Bejeweled Classic의
모션 문법을 이해하고,
Rummi Poker의 각 액션에 어떤 감각을 적용해야 하는지 정리해라.

그 다음 현재 코드에서 가장 작은 변경으로 적용 가능한 P0 작업 계획을 제안해라.

금지:
- game rule 변경
- scoring 변경
- save schema 변경
- runtime state 변경
- market/item economy 변경
- 새 animation package 추가
- 대규모 widget 구조 재작성

허용:
- existing Flutter animation polish
- existing flutter_animate usage
- existing Flame overlay particle value polish
- GamePresentationTimings 상수 정리
- eye-check fixture 보강
```

---

## 8.2 P0 작업 프롬프트

```text
Reference Game Motion Style Guide v2 기준으로 P0 motion pass를 진행해라.

목표:
- Tile Place는 Rummikub physical tile placement 감각
- Score Preview는 Balatro score pop 감각
- Line Confirm은 Royal Match line sweep 감각
- Market Offer Reveal은 Marvel Snap card reveal 감각

우선 작업:
1. Tile Place
2. Board Move
3. Tile Remove / Discard
4. Score Preview

이번 작업에서는 Market / Reward / Item/Jester는 건드리지 않는다.
먼저 1~3개 파일 범위의 작은 구현 계획을 제안해라.
```

---

## 8.3 Market 작업 프롬프트

```text
Reference Game Motion Style Guide v2의 Marvel Snap / Clash Royale 문법을 기준으로
Market motion pass를 진행해라.

목표:
- Offer reveal은 Marvel Snap처럼 빠르고 짧게
- Purchase는 source card -> target slot -> gold result가 읽히게
- Deny는 성공처럼 보이지 않게 짧은 shake/badge로
- Slot unlock은 Clash Royale처럼 1초 이상 인지 가능하게

먼저 구현 계획을 제안해라.
```

---

## 8.4 Item/Jester 작업 프롬프트

```text
Reference Game Motion Style Guide v2의 Balatro trigger 문법을 기준으로
Item/Jester 발동 연출을 보강해라.

원칙:
모든 발동은 Source -> Target -> Result가 보여야 한다.

예:
Quick slot pulse
-> Confirm preview flash
-> settlement score delta badge

또는:
Jester slot pulse
-> scoring line callout
-> final score pop

runtime 결과와 다른 과장 연출은 금지한다.
먼저 구현 계획을 제안해라.
```

---

# 9. 검수 기준

## 9.1 레퍼런스 기반인지 확인하는 질문

작업 결과를 볼 때 아래 질문에 답할 수 있어야 한다.

```text
1. 이 모션은 어느 레퍼런스 게임의 어떤 감각을 가져왔는가?
2. 그 감각을 Rummi Poker의 어떤 액션에 맞게 변환했는가?
3. 원본 게임을 복사하지 않고 motion language만 가져왔는가?
4. 유저가 source -> target -> result를 이해할 수 있는가?
5. 반복 플레이 속도를 방해하지 않는가?
```

---

## 9.2 실패 예시

```text
"Balatro 느낌으로 해주세요"라고만 적혀 있고
어떤 액션에 어떤 타이밍/스케일/리듬을 적용할지 없다.

"Marvel Snap처럼"이라고만 적혀 있고
card reveal인지 snap-to-slot인지 purchase flight인지 구분이 없다.

"Royal Match처럼 화려하게"라고만 적혀 있고
line sweep인지 impact인지 clear burst인지 구분이 없다.

"Clash Royale처럼 보상감 있게"라고만 적혀 있고
count-up인지 unlock hold인지 reward reveal인지 구분이 없다.
```

---

## 9.3 성공 예시

```text
Tile Place:
Rummikub의 물리 타일 배치 감각을 가져온다.
240~280ms 동안 아래에서 올라오며 0.90 -> 1.04 -> 1.00 scale로 settle한다.
짧은 gold glow만 사용하고 보드 전체는 흔들지 않는다.

Market Purchase:
Marvel Snap의 card snap-to-slot 감각을 가져온다.
source offer card가 먼저 pulse하고, ghost card가 target slot으로 이동한 뒤,
target slot이 pulse하고 Gold HUD에 -cost badge가 뜬다.

Line Confirm:
Royal Match의 line sweep 감각을 가져온다.
contributor cell을 28~36ms stagger로 순서대로 ring 처리하고,
cell-local spark를 짧게 표시한다.
큰 점수는 Balatro식 score badge를 추가한다.
```

---

# 10. 최종 요약

이 문서의 핵심은 “무엇을 구현하라”가 아니라 “어떤 게임의 어떤 모션 언어를 어떤 Rummi Poker 액션에 적용하라”이다.

```text
Rummikub:
  타일 조작의 손맛

Balatro:
  점수와 발동의 반응성

Marvel Snap:
  카드 reveal과 slot 장착

Royal Match:
  라인 확정과 impact

Clash Royale:
  보상과 해금의 만족감

Bejeweled Classic:
  작은 cell-local particle
```

Codex는 이 문서를 기반으로 현재 코드에 바로 적용 가능한 작은 motion pass를 제안해야 한다.
