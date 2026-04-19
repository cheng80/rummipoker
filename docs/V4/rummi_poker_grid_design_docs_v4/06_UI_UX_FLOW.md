# 06. UI / UX Flow

> 문서 성격: current baseline + target UX
> 코드 반영 상태: title/battle/shop/settings implemented, station/archive/trial target not implemented
> 핵심 정책: 현재 플레이 가능한 흐름을 깨지 않고, 장기 화면을 옆으로 확장한다.

## 1. Current Screens

[CURRENT]

현재 주요 화면:

- `TitleView`
- `GameView`
- `GameShopScreen`
- `SettingView`

공통 레이아웃:

- `PhoneFrameScaffold`
- 논리 크기 390 x 750
- portrait-first
- `StarryBackground`
- `RummikubTileCanvas` 기반 타일 렌더

## 2. Current Title Flow

[CURRENT]

```text
TitleView
├─ 이어하기
│  ├─ no save: 버튼 미표시 또는 동작 없음
│  ├─ available: continue/delete dialog
│  └─ invalid: corrupted save dialog
├─ 랜덤 시작
├─ 시드 시작
├─ 디버그 fixture 시작(debug only)
└─ 설정
```

[V4_DECISION]

Title flow는 현재 형태를 유지한다. Run Kit, Risk Grade, Trial은 새 런 시작 전 하위 화면으로 추가한다.

## 3. Current Battle Flow

[CURRENT]

```text
GameView
→ catalog load
→ battle ready
→ draw/place/discard
→ confirm
→ settlement animation
→ score apply line by line
→ stage clear if target met
→ cash-out sheet
→ shop route
→ next stage
```

UI 구성:

1. top HUD
2. Jester 5-slot strip
3. 5x5 board
4. hand/draw zone
5. bottom action buttons
6. settlement overlay
7. stage clear overlay
8. Jester detail overlay

## 4. Current Confirm UX

[CURRENT]

확정 가능한 contributor cell은 `scoringCellSet(session)`로 강조한다.

- dead line은 강조하지 않는다.
- scoring candidate의 contributor cell만 강조한다.
- 키커나 non-contributor는 강조하지 않는다.
- 정산 시 해당 contributor cell이 사라진다.

[TARGET]

V4 UX 개선 후보:

- line별 rank badge
- overlap multiplier badge
- Jester effect token animation
- dead line risk hint
- contributor vs remaining tile 시각 구분

## 5. Current Cash-out UX

[CURRENT]

Stage clear 후 cash-out sheet가 뜬다.

표시해야 하는 정보:

- stage index
- target score
- blind reward
- remaining board discard reward
- remaining hand discard reward
- economy Jester reward
- total gold
- current gold

[TARGET]

Station 전환 후에는 `Station Reward Settlement`로 표현할 수 있다.

## 6. Current Shop UX

[CURRENT]

Shop은 bottom sheet가 아니라 full-screen route다.

기능:

- 3개 offer 표시
- reroll
- buy
- owned Jester 표시
- selected Jester 상세
- sell
- next stage

[TARGET]

Market 확장 후에는 다음 category를 표시한다.

- Jester
- Upgrade
- Permit
- Glyph
- Echo
- Service

단, 기존 Jester shop UX를 먼저 유지한다.

## 7. Target Product Flow

[TARGET]

장기 제품 UX:

```text
Title
├─ Continue
├─ New Run
│  ├─ Run Kit Select
│  ├─ Risk Grade Select
│  └─ Start
├─ Trial
├─ Archive
├─ Settings
└─ Credits / Info

Run
├─ Station Map
├─ Station Entry Preview
├─ Battle
├─ Settlement
├─ Market / Reward
└─ Next Station

Archive
├─ Collection
├─ Jester Database
├─ Run History
├─ Stats
└─ Trial Records
```

[V4_DECISION]

이 target flow는 현재 build의 필수 구현이 아니다. Migration 단계에 따라 도입한다.

## 8. UI Terminology

[MIGRATION]

UI 용어 전환 우선순위:

1. 플레이어-facing 문구에서 `Stage`를 `Station`으로 전환할 수 있다.
2. 코드 내부 `stageIndex`, `RummiBlindState`, `scoreTowardBlind`는 유지한다.
3. save schema는 먼저 adapter를 둔다.
4. 모든 화면에서 용어가 안정화된 뒤 코드 rename을 검토한다.

## 9. Debug UX Policy

[CURRENT]

현재 debug 요소:

- debug hand size 1~3
- debug fixture menu
- shop inspect offers

[V4_DECISION]

Debug 동선은 개발에는 유지하되, release build에서는 다음 중 하나로 처리한다.

- `kDebugMode` 뒤로 숨김
- developer options로 이동
- QA build flavor 전용

## 10. Accessibility / Readability Target

[TARGET]

V4 UI 개선 방향:

- board tile readability 우선
- overlap/score feedback는 텍스트와 애니메이션 모두 제공
- color-only feedback 금지
- Jester effect 설명은 한 줄 요약 + 상세 패널 분리
- seed/run id 복사 기능 추가
- save invalid 메시지는 사용자가 선택할 수 있게 표시
