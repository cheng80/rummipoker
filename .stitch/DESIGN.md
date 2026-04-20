# RummiPoker Mobile Design System

이 파일은 Stitch 시안 생성 시 현재 앱의 시각 기준선을 유지하기 위한 최소 디자인 토큰이다.

## 1. Platform

- Platform: Mobile
- Device target: iPhone portrait
- Frame rule: 모든 핵심 UI는 `PhoneFrame` 내부 안전 영역을 지킨다
- Layout bias: top HUD + center board/content + bottom actions

## 2. Visual Direction

- Tone: tactile game UI, not generic SaaS
- Mood: deep-night arcade card game
- Density: compact but readable
- Priority: small phone 화면에서 조작 오동작이 적어야 함

## 3. Color Tokens

- App background: deep navy space `#0A0B1A`
- Primary surface: dark green felt `#173F34`
- Secondary surface: muted green `#20493D`
- Surface border: translucent pale green/white
- Primary CTA: warm amber `#F4A81D`
- Secondary CTA: teal green `#267B67`
- Neutral action: desaturated gray-green `#4C5A55`
- Danger action: brick red `#B74B3B`
- Accent blue: market utility blue `#2D6F9E`
- Primary text: off-white
- Secondary text: soft white with reduced opacity

## 4. Shape Language

- Rounded cards: 16-28 radius
- Buttons: chunky rounded rectangles, low height, hard readable silhouette
- Avoid: flat text buttons, glass blur, soft floating glow
- Keep: hard bottom shadow or subtle depth only

## 5. Typography

- Display font: playful bold rounded Korean display style
- Headings: oversized, high contrast, arcade-like
- Body: compact, heavy enough for mobile readability
- Avoid: thin modern editorial typography

## 6. Components

- HUD chips: compact status panels with strong labels
- Card slots: visible framed wells
- Market cards: readable title/effect/price/action separation
- Dialogs: framed modal cards with low-height tactile buttons
- Action rows: accidental taps must be minimized by spacing and grouping

## 7. Interaction Rules

- `Confirm` 계열 위험 액션은 draw와 가까운 위치에 두지 않는다
- Drag target / reroll / scroll 경계는 충분한 세로 간격을 둔다
- Jester와 Item은 같은 시각 그룹으로 섞지 않는다

## 8. Expansion Direction

- Battle screen must support:
  - Jester strip
  - separate Item zone
  - optional quick-use consumable area
- Market screen must support:
  - Jester section
  - Item section
  - service/upgrade sub-section if needed
