# 카드 일러스트 이미지 생성 프롬프트 팩

이 문서는 `54 x 70` 카드 face 안에 들어갈 작은 중앙 아트 asset 생성을 위한 프롬프트 모음이다. 최종 UI에는 등급/희귀도 표시, 카드명, 하단 타입/카테고리 배지, 가격/선택 상태가 함께 표시되므로, 생성 이미지는 카드 전체 레이아웃을 대체하지 않는다. 그림은 텍스트 없이 **중앙 문장/룬/도형**만 생성하고, UI overlay가 올라갈 위/아래 영역을 침범하지 않는 것을 기본으로 한다.

## 카드 정보 계층 전제

- 희귀도/등급 판독은 별도 UI 작업으로 진행한다. 런타임 UI의 등급 pill/라벨, 색 띠, 테두리, 필요 시 독립된 장식 marker가 담당하며, 이미지 안에 별, 글자, 숫자, 등급 마크를 굽지 않는다.
- 타입은 런타임 UI의 하단 배지로 표시한다. Item은 `Q-Slot`, `Tool`, `Gear`, `Relic` 배지가 붙고, Jester는 효과 카테고리 배지가 붙는다.
- 이미지는 중앙 hard safe area 안에 한 개의 큰 문장만 둔다. 상단 22%, 하단 20%, 좌우 8%는 UI 전용 no-art zone으로 잠그고, 배경 질감 외의 선/문장/장식이 들어가면 실패로 본다.
- 타입 차이는 이미지의 큰 실루엣 언어로만 보조한다. 예: `Q-Slot`은 즉발 룬/충전구, `Tool`은 작은 도구/소모품, `Gear`는 장착 장비, `Relic`은 유물/상징물, `Jester`는 효과 반응 문장.
- Market 후보 카드와 보유 카드 모두 같은 asset을 쓰므로, 가격표나 구매 가능 표시처럼 상태에 따라 달라지는 정보는 이미지에 넣지 않는다.
- 카드 UI 장식처럼 보이는 띠, 탭, pill, corner marker, badge 형태는 이미지 안에 만들지 않는다. 이런 요소는 실제 UI와 겹치거나 깨진 카드 장식처럼 보일 수 있으므로 실패로 본다.

## 마스터 프롬프트

```text
Small center-art asset for a Rummi Poker game card, aspect ratio 27:35, readable inside a 54x70 px card face with UI overlays. Hard layout lock: the top 22%, bottom 20%, left 8%, and right 8% are UI-only no-art zones; keep them flat, quiet, and free of linework except subtle background texture. Put exactly one large geometric magic-circle emblem fully inside the central safe rectangle, approximately x 8%-92% and y 22%-80%, with no part extending into the UI-only zones. Dark talisman card surface, muted green-black background, thin gold or off-white ink linework, subtle Rummikub tile motif, clean silhouette, limited internal lines, premium roguelite deckbuilder item icon style. No text. No letters. No price tag. No rarity badge. No type badge. No corner marker. No UI tab. No top banner. No bottom badge shape. No poker suits. No playing-card layout. No character portrait. No tiny decorative clutter.
```

## 네거티브 프롬프트

```text
text, letters, numbers unless explicitly requested, price, coin price label, rarity label, type label, badge text, top banner, bottom banner, UI tab, corner marker, attached shape marker, rarity icon, type icon, poker suit symbols, playing cards, realistic portrait, detailed character face, complex scene, tiny UI text, photorealistic object, noisy background, overly bright neon, web icon, emoji, sticker style, cluttered fantasy painting
```

## Hard safe zone

이미지 생성 시 카드 UI 영역은 권장 여백이 아니라 금지 구역이다.

| 영역 | 비율 | 허용 | 금지 |
|---|---:|---|---|
| 상단 UI zone | y 0-22% | 낮은 대비 배경 질감 | 문장, 선, 아이콘, 탭, 띠, 밝은 장식 |
| 중앙 art zone | x 8-92%, y 22-80% | 문장 1개, 효과군 실루엣 | 카드명/등급/타입처럼 보이는 요소 |
| 하단 UI zone | y 80-100% | 낮은 대비 배경 질감 | 배지 모양, 선, 아이콘, 밝은 장식 |
| 좌우 여백 | x 0-8%, x 92-100% | 낮은 대비 배경 질감 | 테두리처럼 보이는 선, corner marker |

판정 기준:

- 문장 외곽선이 상단/하단 UI zone을 침범하면 실패다.
- 밝은 선이 카드명, 등급 pill, 타입 배지 뒤로 지나갈 것 같으면 실패다.
- 생성 모델이 전체 카드 레이아웃, 테두리, 상단 띠, 하단 배지를 만들어 내면 실패다.
- 중앙 art zone 안에서도 작은 내부선은 3-5개 이하로 유지한다.

## UI와 일러스트 분리 원칙

- 일러스트 작업은 카드 효과/정체성/컨셉군을 읽히게 하는 작업이다.
- 등급/희귀도 보강 UI는 별도 작업이다. 색 띠 하나만으로 부족하면 카드 컴포넌트에서 등급 라벨, 테두리, 배지, 상세 패널 표시를 보강한다.
- 일러스트는 희귀도 보강 UI를 대신하지 않는다. Common/Uncommon/Rare/Legendary를 이미지 스타일 차이로만 구분하려고 하지 않는다.
- 생성 결과에 상단 띠 오른쪽이 깨진 듯한 장식, 탭처럼 붙은 marker, 배지처럼 보이는 도형이 생기면 UI 결함으로 오인될 수 있으므로 폐기하거나 재생성한다.

## Pilot 순서

바로 97장 전체를 생성하지 않는다. 먼저 카드 정보 계층이 살아 있는지 확인하는 UI 판독성 pilot 6장을 만든 뒤, 승인되면 컨셉군 대표 14장으로 확장한다. 단, pilot 판정은 이미지 단독이 아니라 강화된 카드 UI mock 또는 실제 런타임 카드 face 위에 얹어서 본다.

1. Common Jester
2. Rare Jester
3. Legendary Jester
4. Q-Slot Item
5. Tool Item
6. Gear 또는 Relic Item

6장 pilot은 실제 카드 face에 상단 등급 pill/라벨, 희귀도 색 띠, 이름, 하단 타입/카테고리 배지를 얹었을 때 중앙 문장이 가려지지 않는지 확인하는 용도다. 여기서 통과한 safe area와 선 밀도를 14장 컨셉군 pilot 및 전체 97장 생성에 적용한다.

## 컨셉군별 프롬프트

### 경제 Jester 문장

```text
Create a small game card illustration for Rummi Poker. Aspect ratio 27:35, designed to remain readable at 54x70 px. Dark talisman card background, muted green-black ink, thin gold outline, single central geometric magic-circle emblem. Visual concept: 작은 금화 원 + 영수증/주머니 실루엣 룬. No text, no poker suits, no playing-card layout, no character portrait, no tiny details. Use one strong silhouette and 3 to 5 internal line details only.
```

### 경제/상점 문장

```text
Create a small game card illustration for Rummi Poker. Aspect ratio 27:35, designed to remain readable at 54x70 px. Dark talisman card background, muted green-black ink, thin gold outline, single central geometric magic-circle emblem. Visual concept: 도장/코인/가격표 룬. 사각 도장과 금색 원을 결합. No text, no poker suits, no playing-card layout, no character portrait, no tiny details. Use one strong silhouette and 3 to 5 internal line details only.
```

### 고배수 Jester 문장

```text
Create a small game card illustration for Rummi Poker. Aspect ratio 27:35, designed to remain readable at 54x70 px. Dark talisman card background, muted green-black ink, thin gold outline, single central geometric magic-circle emblem. Visual concept: 증폭 렌즈 문장. 겹원, 삼각 프리즘, 굵은 외곽 링. No text, no poker suits, no playing-card layout, no character portrait, no tiny details. Use one strong silhouette and 3 to 5 internal line details only.
```

### 덱/손패 문장

```text
Create a small game card illustration for Rummi Poker. Aspect ratio 27:35, designed to remain readable at 54x70 px. Dark talisman card background, muted green-black ink, thin gold outline, single central geometric magic-circle emblem. Visual concept: 겹친 타일 더미 + 위로 떠오르는 타일. 바늘/주머니는 단순 선형 부속물. No text, no poker suits, no playing-card layout, no character portrait, no tiny details. Use one strong silhouette and 3 to 5 internal line details only.
```

### 보드 이동 문장

```text
Create a small game card illustration for Rummi Poker. Aspect ratio 27:35, designed to remain readable at 54x70 px. Dark talisman card background, muted green-black ink, thin gold outline, single central geometric magic-circle emblem. Visual concept: 3x3 격자 + 방향 화살표 문장. 이동/되돌림은 같은 격자에서 화살표 방향만 변경. No text, no poker suits, no playing-card layout, no character portrait, no tiny details. Use one strong silhouette and 3 to 5 internal line details only.
```

### 색상 룬

```text
Create a small game card illustration for Rummi Poker. Aspect ratio 27:35, designed to remain readable at 54x70 px. Dark talisman card background, muted green-black ink, thin gold outline, single central geometric magic-circle emblem. Visual concept: 색 견본 룬. 큰 색 막대와 작은 원 3개만 사용. No text, no poker suits, no playing-card layout, no character portrait, no tiny details. Use one strong silhouette and 3 to 5 internal line details only.
```

### 색상 반응 Jester 문장

```text
Create a small game card illustration for Rummi Poker. Aspect ratio 27:35, designed to remain readable at 54x70 px. Dark talisman card background, muted green-black ink, thin gold outline, single central geometric magic-circle emblem. Visual concept: 중앙 원소 룬 + 해당 색 파편 4개. 빨강/파랑/노랑/검정이 한눈에 보이게 한다. No text, no poker suits, no playing-card layout, no character portrait, no tiny details. Use one strong silhouette and 3 to 5 internal line details only.
```

### 성장/기억 Jester 문장

```text
Create a small game card illustration for Rummi Poker. Aspect ratio 27:35, designed to remain readable at 54x70 px. Dark talisman card background, muted green-black ink, thin gold outline, single central geometric magic-circle emblem. Visual concept: 나선형 기록 룬. 원 궤도에 노드가 누적되는 형태. No text, no poker suits, no playing-card layout, no character portrait, no tiny details. Use one strong silhouette and 3 to 5 internal line details only.
```

### 숫자 반응 Jester 문장

```text
Create a small game card illustration for Rummi Poker. Aspect ratio 27:35, designed to remain readable at 54x70 px. Dark talisman card background, muted green-black ink, thin gold outline, single central geometric magic-circle emblem. Visual concept: 숫자 궤도 문장. 1, 10/4, 짝수/홀수, 11~13, 수열을 작은 노드 배열로 표현한다. No text, no poker suits, no playing-card layout, no character portrait, no tiny details. Use one strong silhouette and 3 to 5 internal line details only.
```

### 안전/버림 문장

```text
Create a small game card illustration for Rummi Poker. Aspect ratio 27:35, designed to remain readable at 54x70 px. Dark talisman card background, muted green-black ink, thin gold outline, single central geometric magic-circle emblem. Visual concept: 방패/그물/빠지는 타일 문장. 점선 그물과 보호 링. No text, no poker suits, no playing-card layout, no character portrait, no tiny details. Use one strong silhouette and 3 to 5 internal line details only.
```

### 점수 증폭 문장

```text
Create a small game card illustration for Rummi Poker. Aspect ratio 27:35, designed to remain readable at 54x70 px. Dark talisman card background, muted green-black ink, thin gold outline, single central geometric magic-circle emblem. Visual concept: 충전구/광택 문장. 에너지 코어, 작은 + 눈금, 단순 원형 회로. No text, no poker suits, no playing-card layout, no character portrait, no tiny details. Use one strong silhouette and 3 to 5 internal line details only.
```

### 점수 Jester 문장

```text
Create a small game card illustration for Rummi Poker. Aspect ratio 27:35, designed to remain readable at 54x70 px. Dark talisman card background, muted green-black ink, thin gold outline, single central geometric magic-circle emblem. Visual concept: 점수 파동 문장. 중심 별/렌즈와 바깥으로 퍼지는 2중 원. No text, no poker suits, no playing-card layout, no character portrait, no tiny details. Use one strong silhouette and 3 to 5 internal line details only.
```

### 족보 반응 Jester 문장

```text
Create a small game card illustration for Rummi Poker. Aspect ratio 27:35, designed to remain readable at 54x70 px. Dark talisman card background, muted green-black ink, thin gold outline, single central geometric magic-circle emblem. Visual concept: 타일 점 배열 문장. 페어는 쌍원, 트리플은 삼각, 포카드는 네 점 십자, 스트레이트는 상승 사선, 플러시는 같은 색 5점. No text, no poker suits, no playing-card layout, no character portrait, no tiny details. Use one strong silhouette and 3 to 5 internal line details only.
```

### 족보 성장 문장

```text
Create a small game card illustration for Rummi Poker. Aspect ratio 27:35, designed to remain readable at 54x70 px. Dark talisman card background, muted green-black ink, thin gold outline, single central geometric magic-circle emblem. Visual concept: 연구/행성 카드 느낌의 궤도 룬. 족보별 점 배열을 작은 별궤도처럼 배치. No text, no poker suits, no playing-card layout, no character portrait, no tiny details. Use one strong silhouette and 3 to 5 internal line details only.
```

### 의식/라인 기억 문장

```text
Create a small game card illustration for Rummi Poker. Aspect ratio 27:35, designed to remain readable at 54x70 px. Dark talisman card background, muted green-black ink, thin gold outline, single central geometric magic-circle emblem. Visual concept: 보드 라인 하나가 원형 기억 궤도로 저장되는 의식 문장. 라인 점 3~5개와 작은 기억 노드가 중심 링 안에 정렬된다. No text, no poker suits, no playing-card layout, no character portrait, no tiny details. Use one strong silhouette and 3 to 5 internal line details only.
```

### 의식/덱 복사 문장

```text
Create a small game card illustration for Rummi Poker. Aspect ratio 27:35, designed to remain readable at 54x70 px. Dark talisman card background, muted green-black ink, thin gold outline, single central geometric magic-circle emblem. Visual concept: 보드 라인의 핵심 타일이 덱으로 복사되는 룬. 중앙 타일 하나와 뒤에 희미한 복제 타일 그림자, 짧은 궤도 화살표. No text, no poker suits, no playing-card layout, no character portrait, no tiny details. Use one strong silhouette and 3 to 5 internal line details only.
```

### 의식/각인 문장

```text
Create a small game card illustration for Rummi Poker. Aspect ratio 27:35, designed to remain readable at 54x70 px. Dark talisman card background, muted green-black ink, thin gold outline, single central geometric magic-circle emblem. Visual concept: 한 타일 위에 각인 도장이 찍히는 룬. 작은 사각 타일, 원형 seal, 짧은 빛 점 2~3개만 사용. No text, no poker suits, no playing-card layout, no character portrait, no tiny details. Use one strong silhouette and 3 to 5 internal line details only.
```

### 의식/숫자 변환 문장

```text
Create a small game card illustration for Rummi Poker. Aspect ratio 27:35, designed to remain readable at 54x70 px. Dark talisman card background, muted green-black ink, thin gold outline, single central geometric magic-circle emblem. Visual concept: 라인 위 타일의 숫자 성질이 바뀌는 추상 룬. 실제 숫자 글자는 쓰지 말고 점 배열이 한 패턴에서 다른 패턴으로 이동하는 모습. No text, no poker suits, no playing-card layout, no character portrait, no tiny details. Use one strong silhouette and 3 to 5 internal line details only.
```

### 의식/덱 압축 문장

```text
Create a small game card illustration for Rummi Poker. Aspect ratio 27:35, designed to remain readable at 54x70 px. Dark talisman card background, muted green-black ink, thin gold outline, single central geometric magic-circle emblem. Visual concept: 라인에서 약한 타일 하나를 가지치기해 덱을 압축하는 룬. 작은 가위/가지치기 곡선과 사라지는 타일 실루엣. No text, no poker suits, no playing-card layout, no character portrait, no tiny details. Use one strong silhouette and 3 to 5 internal line details only.
```

### 의식/보드 위치 문장

```text
Create a small game card illustration for Rummi Poker. Aspect ratio 27:35, designed to remain readable at 54x70 px. Dark talisman card background, muted green-black ink, thin gold outline, single central geometric magic-circle emblem. Visual concept: 5x5 보드의 중심/모서리/대각 위치가 의식 원 안에서 강조되는 문장. 작은 격자와 한 개의 빛나는 위치 노드. No text, no poker suits, no playing-card layout, no character portrait, no tiny details. Use one strong silhouette and 3 to 5 internal line details only.
```

### 의식/마켓 렌즈 문장

```text
Create a small game card illustration for Rummi Poker. Aspect ratio 27:35, designed to remain readable at 54x70 px. Dark talisman card background, muted green-black ink, thin gold outline, single central geometric magic-circle emblem. Visual concept: 다음 Market 후보를 비추는 의식 렌즈. 작은 렌즈 원, 카드 후보 실루엣 2개, 가느다란 초점선. No text, no poker suits, no playing-card layout, no character portrait, no tiny details. Use one strong silhouette and 3 to 5 internal line details only.
```

### 칩 Jester 문장

```text
Create a small game card illustration for Rummi Poker. Aspect ratio 27:35, designed to remain readable at 54x70 px. Dark talisman card background, muted green-black ink, thin gold outline, single central geometric magic-circle emblem. Visual concept: 코인형 칩 마법진. 바깥 원, 안쪽 점, 짧은 방사 눈금. No text, no poker suits, no playing-card layout, no character portrait, no tiny details. Use one strong silhouette and 3 to 5 internal line details only.
```

## 카드별 프롬프트 토큰: Jester

| 컨셉군 | ID | 이름 | 구분 토큰 |
|---|---|---|---|
| 점수 Jester 문장 | `jester` | 기본패 | none |
| 색상 반응 Jester 문장 | `greedy_jester` | 노랑 불씨 | tile_color_scored |
| 색상 반응 Jester 문장 | `lusty_jester` | 빨강 불씨 | tile_color_scored |
| 색상 반응 Jester 문장 | `wrathful_jester` | 파랑 불씨 | tile_color_scored |
| 색상 반응 Jester 문장 | `gluttonous_jester` | 검정 불씨 | tile_color_scored |
| 족보 반응 Jester 문장 | `jolly_jester` | 페어 호출 | pair |
| 족보 반응 Jester 문장 | `zany_jester` | 트리플 호출 | three_of_a_kind |
| 족보 반응 Jester 문장 | `mad_jester` | 투페어 호출 | two_pair |
| 족보 반응 Jester 문장 | `crazy_jester` | 연속 호출 | straight |
| 족보 반응 Jester 문장 | `droll_jester` | 색상 호출 | flush |
| 족보 반응 Jester 문장 | `sly_jester` | 페어 칩 | pair |
| 족보 반응 Jester 문장 | `wily_jester` | 트리플 칩 | three_of_a_kind |
| 족보 반응 Jester 문장 | `clever_jester` | 투페어 칩 | two_pair |
| 족보 반응 Jester 문장 | `devious_jester` | 연속 칩 | straight |
| 족보 반응 Jester 문장 | `crafty_jester` | 색상 칩 | flush |
| 점수 Jester 문장 | `half_jester` | 작은 손 | other |
| 고배수 Jester 문장 | `jester_stencil` | 빈 자리 | other |
| 점수 Jester 문장 | `abstract_jester` | 합창단 | other |
| 성장/기억 Jester 문장 | `green_jester` | 기세 | stateful |
| 칩 Jester 문장 | `blue_jester` | 남은 덱 | other |
| 숫자 반응 Jester 문장 | `scary_face` | 그림 칩 | 11~13 tiles |
| 숫자 반응 Jester 문장 | `smiley_face` | 그림 증폭 | 11~13 tiles |
| 경제 Jester 문장 | `egg` | 예비 금화 | none |
| 칩 Jester 문장 | `bonus_jester` | 칩 고정핀 | none |
| 성장/기억 Jester 문장 | `popcorn` | 시한 증폭 | stateful |
| 성장/기억 Jester 문장 | `ice_cream` | 줄어드는 칩 | stateful |
| 경제 Jester 문장 | `delayed_gratification` | 미사용 환급 | other |
| 숫자 반응 Jester 문장 | `walkie_talkie` | 10과 4 | rank_scored |
| 경제 Jester 문장 | `golden_jester` | 금빛 주머니 | none |
| 점수 Jester 문장 | `mystic_summit` | 마지막 힘 | other |
| 숫자 반응 Jester 문장 | `even_steven` | 짝수 엔진 | rank_scored |
| 숫자 반응 Jester 문장 | `odd_todd` | 홀수 엔진 | rank_scored |
| 숫자 반응 Jester 문장 | `scholar` | 1번 장부 | rank_scored |
| 숫자 반응 Jester 문장 | `fibonacci` | 수열 보너스 | rank_scored |
| 칩 Jester 문장 | `banner` | 남은 버림 | other |
| 점수 Jester 문장 | `gros_michel` | 숙성 부스터 | none |
| 성장/기억 Jester 문장 | `supernova` | 런 기억 장치 | stateful |
| 성장/기억 Jester 문장 | `ride_the_bus` | 무사고 연속 | 11~13 tiles |
| 족보 반응 Jester 문장 | `the_duo` | 페어 증폭 | pair |
| 족보 반응 Jester 문장 | `the_trio` | 트리플 증폭 | three_of_a_kind |
| 족보 반응 Jester 문장 | `the_family` | 4묶음 증폭 | four_of_a_kind |
| 족보 반응 Jester 문장 | `the_order` | 연속 증폭 | straight |
| 족보 반응 Jester 문장 | `the_tribe` | 색상 증폭 | flush |

## 카드별 프롬프트 토큰: Item / Tool / Gear / Passive

| 컨셉군 | ID | 이름 | 태그 토큰 |
|---|---|---|---|
| 경제/상점 문장 | `reroll_token` | 리롤 칩 | market, economy, discount |
| 경제/상점 문장 | `coupon_stamp` | 할인 도장 | market, economy, discount |
| 경제/상점 문장 | `coin_cache` | 금화 보관함 | gold, economy |
| 족보 성장 문장 | `two_pair_study` | 투 페어 연구 | consumable, rank_growth, planet_like, two_pair |
| 족보 성장 문장 | `triple_study` | 트리플 연구 | consumable, rank_growth, planet_like, three_kind |
| 족보 성장 문장 | `straight_study` | 스트레이트 연구 | consumable, rank_growth, planet_like, straight |
| 족보 성장 문장 | `flush_study` | 플러시 연구 | consumable, rank_growth, planet_like, flush |
| 족보 성장 문장 | `full_house_study` | 풀하우스 연구 | consumable, rank_growth, planet_like, full_house |
| 족보 성장 문장 | `four_kind_study` | 포카드 연구 | consumable, rank_growth, planet_like, four_kind |
| 족보 성장 문장 | `straight_flush_study` | 스티플 연구 | consumable, rank_growth, planet_like, straight_flush |
| 안전/버림 문장 | `board_scrap` | 보드 패스 | battle, discard, safety |
| 안전/버림 문장 | `hand_scrap` | 손패 패스 | battle, discard, safety |
| 점수 증폭 문장 | `chip_capsule` | 칩 충전구 | battle, score, chips |
| 점수 증폭 문장 | `mult_capsule` | 점수 충전구 | battle, score, mult |
| 점수 증폭 문장 | `line_polish` | 점수 광택제 | battle, score, xmult |
| 점수 증폭 문장 | `straight_oil` | 연속 준비 | battle, score, rank, straight |
| 점수 증폭 문장 | `flush_powder` | 색상 준비 | battle, score, rank, flush |
| 점수 증폭 문장 | `pair_splint` | 페어 고정대 | battle, score, rank, two_pair |
| 점수 증폭 문장 | `overlap_pin` | 겹침 핀 | battle, overlap, score |
| 덱/손패 문장 | `emergency_draw` | 비상 드로우 | battle, draw, safety |
| 경제/상점 문장 | `ledger_clip` | 장부 클립 | equipment, economy, market |
| 안전/버림 문장 | `discard_glove` | 보드 장갑 | equipment, discard, station_start |
| 안전/버림 문장 | `mulligan_sleeve` | 손패 슬리브 | equipment, discard, station_start |
| 경제/상점 문장 | `jester_hook` | Jester 후크 | equipment, tactic, economy |
| 점수 증폭 문장 | `score_abacus` | 점수 주판 | equipment, battle, score |
| 점수 증폭 문장 | `thin_caliper` | 짧은 줄 | equipment, battle, small_hand |
| 경제/상점 문장 | `stage_map` | Station 지도 | relic, gold, boss |
| 경제/상점 문장 | `merchant_stamp` | 상점 도장 | relic, market, reroll |
| 안전/버림 문장 | `safety_net` | 안전 장치망 | relic, safety, battle |
| 안전/버림 문장 | `coin_funnel` | 보드 환급 | relic, settlement, gold |
| 안전/버림 문장 | `hand_funnel` | 손패 환급 | relic, settlement, gold |
| 점수 증폭 문장 | `echo_bell` | 메아리 종 | relic, battle, score, echo |
| 경제/상점 문장 | `boss_trophy` | Boss 전리품 | relic, boss, market, tactic |
| 경제/상점 문장 | `thin_wallet` | 빈 지갑 | utility, economy, comeback |
| 경제/상점 문장 | `trade_ticket` | 아이템 티켓 | utility, market, reroll |
| 경제/상점 문장 | `jester_invoice` | Jester 청구서 | utility, market, tactic, discount |
| 경제/상점 문장 | `item_invoice` | 아이템 청구서 | utility, market, item, discount |
| 색상 룬 | `red_swatch` | 빨강 견본 | consumable, tile_color, mult |
| 색상 룬 | `blue_swatch` | 파랑 견본 | consumable, tile_color, mult |
| 색상 룬 | `black_swatch` | 검정 견본 | consumable, tile_color, mult |
| 색상 룬 | `yellow_swatch` | 노랑 견본 | consumable, tile_color, mult |
| 점수 증폭 문장 | `rank_chalk` | 숫자 분필 | consumable, rank, chips |
| 덱/손패 문장 | `deck_needle` | 덱 바늘 | utility, deck, selection |
| 덱/손패 문장 | `battle_pouch` | 전투 주머니 | utility, hand_size, battle |
| 점수 증폭 문장 | `tile_polisher` | 타일 광택기 | equipment, score, legendary |
| 보드 이동 문장 | `move_token` | 이동 칩 | battle, move, safety |
| 보드 이동 문장 | `slide_wax` | 슬라이드 왁스 | battle, move, trigger |
| 보드 이동 문장 | `board_lift` | 이동 예약 | move, station_start, utility |
| 보드 이동 문장 | `undo_seal` | 되돌림 표식 | battle, move, undo |
| 보드 이동 문장 | `organizer_glove` | 정리 장갑 | equipment, move, station_start |
| 덱/손패 문장 | `travel_pouch` | 여행 주머니 | relic, hand_size, capacity |
| 덱/손패 문장 | `wide_grip` | 넓은 손잡이 | equipment, hand_size, penalty |
| 덱/손패 문장 | `grand_satchel` | 큰 가방 | relic, hand_size, legendary, penalty |
| 경제/상점 문장 | `market_compass` | 상점 나침반 | relic, market, legendary, discount |

## 카드별 프롬프트 토큰: Current Ritual/Fate

현재 Ritual/Item 확장 계열은 37종이다. 전투 보드 선 선택형 `ritual_line_effect`는 31장이고, 이 중 족보 변환형 운명은 16장이다. 이미지 프롬프트도 아래 분류를 기준으로 생성/재생성한다.

| 컨셉군 | ID | 이름 | 태그 토큰 |
|---|---|---|---|
| 의식/라인 기억 문장 | `line_memory` | 라인 기억 | ritual, line, hand_rank_growth, primary |
| 의식/라인 기억 문장 | `cross_memory` | 교차 기억 | ritual, cross_line, row_column_memory |
| 의식/덱 복사 문장 | `keystone_copy` | 중심석 복사 | ritual, deck_add, key_tile |
| 의식/덱 복사 문장 | `edge_copy` | 끝점 복사 | ritual, deck_add, endpoint_tile |
| 의식/덱 복사 문장 | `rank_echo` | 숫자 메아리 | ritual, deck_add, repeated_rank |
| 의식/덱 복사 문장 | `color_echo` | 색 메아리 | ritual, deck_add, majority_color |
| 의식/덱 복사 문장 | `scarce_copy` | 희소석 복사 | ritual, deck_add, scarce_tile |
| 의식/덱 복사 문장 | `sealed_copy` | 각인 복사 | ritual, deck_add, sealed_tile |
| 의식/족보 변환 문장 | `trim_rank` | 투페어 운명 | ritual, fate_transform, two_pair |
| 의식/족보 변환 문장 | `line_pruner` | 하위 트리플 운명 | ritual, fate_transform, low_three_kind |
| 의식/족보 변환 문장 | `fate_three_kind_high` | 상위 트리플 운명 | ritual, fate_transform, high_three_kind |
| 의식/족보 변환 문장 | `color_concord` | 상위 포카드 운명 | ritual, fate_transform, high_four_kind |
| 의식/족보 변환 문장 | `step_rite` | 하위 포카드 운명 | ritual, fate_transform, low_four_kind |
| 의식/족보 변환 문장 | `rank_concord` | 상위 풀하우스 운명 | ritual, fate_transform, high_full_house |
| 의식/족보 변환 문장 | `fate_full_house_low` | 하위 풀하우스 운명 | ritual, fate_transform, low_full_house |
| 의식/족보 변환 문장 | `flush_house_fate` | 플러시 하우스 운명 | ritual, fate_transform, flush_house |
| 의식/족보 변환 문장 | `flush_five_fate` | 플러시 파이브 운명 | ritual, fate_transform, flush_five |
| 의식/족보 변환 문장 | `fate_flush_high` | 상위 플러시 운명 | ritual, fate_transform, high_flush |
| 의식/족보 변환 문장 | `fate_flush_low` | 하위 플러시 운명 | ritual, fate_transform, low_flush |
| 의식/족보 변환 문장 | `fate_straight_high` | 상행 스트레이트 운명 | ritual, fate_transform, high_straight |
| 의식/족보 변환 문장 | `fate_straight_low` | 하행 스트레이트 운명 | ritual, fate_transform, low_straight |
| 의식/족보 변환 문장 | `wild_thread` | 상행 스티플 운명 | ritual, fate_transform, high_straight_flush |
| 의식/족보 변환 문장 | `off_color_rite` | 하행 스티플 운명 | ritual, fate_transform, low_straight_flush |
| 의식/족보 변환 문장 | `number_mask` | 로얄 운명 | ritual, fate_transform, royal_flush |
| 의식/색 정리 문장 | `trim_color` | 색 가지치기 | ritual, color_prune, deck_top_refill |
| 의식/덱 압축 문장 | `deadwood_burn` | 마른가지 소각 | ritual, dead_line, gold_recovery |
| 의식/덱 압축 문장 | `sacrifice_line` | 제물 의식 | ritual, sacrifice, high_risk_reward |
| 의식/보드 위치 문장 | `cross_rite` | 교차 의식 | ritual, geometry, cross_point |
| 의식/보드 위치 문장 | `corner_rite` | 모서리 의식 | ritual, geometry, corner |
| 의식/보드 위치 문장 | `center_rite` | 중심 의식 | ritual, geometry, center |
| 의식/보드 위치 문장 | `diagonal_rite` | 대각 의식 | ritual, geometry, diagonal |
| 의식/보드 위치 문장 | `bridge_rite` | 다리 의식 | ritual, geometry, future_line |
| 의식/마켓 렌즈 문장 | `ritual_coupon` | 의식 쿠폰 | ritual, market, discount |
| 의식/마켓 렌즈 문장 | `ritual_lens` | 의식 렌즈 | ritual, market, family_weight |
| 의식/마켓 렌즈 문장 | `line_pack_ticket` | 라인 팩 티켓 | ritual, market, line_pack |
| 의식/마켓 렌즈 문장 | `seal_vendor` | 각인 상인 | ritual, market, seal_weight |
| 의식/마켓 렌즈 문장 | `prune_vendor` | 정리 상인 | ritual, market, prune_weight |

## 사용 예시

```text
Create one card illustration using the master style. Card: "보드 장갑". Family: "안전/버림 문장". Emblem: shield-like ring with a small tile slipping out and a protective grid behind it. Aspect ratio 27:35. No text, no poker suits, no character portrait.
```
