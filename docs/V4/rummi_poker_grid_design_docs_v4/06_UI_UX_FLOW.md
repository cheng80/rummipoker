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
├─ Continue
│  ├─ 이어하기 entry
│  ├─ no save: disabled card
│  ├─ available: continue/delete dialog
│  └─ invalid: corrupted save dialog
├─ New Run
│  ├─ 랜덤 시작
│  ├─ 시드 시작
│  └─ future setup preview
├─ More
│  ├─ Trial placeholder
│  └─ Archive placeholder
├─ Developer(debug only)
│  └─ debug fixture 시작
└─ Settings
```

[V4_DECISION]

현재는 `TitleView`를 Home의 1차 구현으로 본다.
Run Kit, Risk Grade, Trial, Archive는 별도 구조로 확장하되,
초기에는 기존 route를 재사용하면서 entry 그룹만 먼저 드러낸다.

### B1 Home Screen Stencil

[STENCIL]

```text
┌──────────────────────────────────────┐
│              RUMMI POKER             │
│      5x5 그리드 · 12줄 포커 족보      │
├──────────────────────────────────────┤
│ [이어하기]                            │
│  저장된 진행 요약                     │
│  - 현재 Station / 현재 위치 / Gold    │
│  - 체크포인트 Station                 │
├──────────────────────────────────────┤
│ [새 시작]                             │
│  새 게임 시작                         │
│  안내: 다음 화면에서 시작 방식 선택    │
├──────────────────────────────────────┤
│ [다른 메뉴]                           │
│  [특별 모드]                          │
│  [기록실]                             │
├──────────────────────────────────────┤
│ [디버그]      (debug build only)      │
│  [디버그 픽스처]                      │
├──────────────────────────────────────┤
│ [설정]                                │
├──────────────────────────────────────┤
│               version                │
└──────────────────────────────────────┘
```

설계 메모:

- 사용자는 내부 구조명 `Home / Trial / Archive`를 직접 보지 않는다.
- `Continue / New Run / Trial / Archive`는 내부 기획 축이고, 실제 노출 문구는 별도 UX 카피를 쓴다.
- `디버그`는 개발/검증용 진입을 모으는 전용 섹션으로만 남긴다.
- `이어하기`는 버튼 하나가 아니라 저장된 진행 요약까지 포함한 block으로 본다.

### B1 New Start Screen Stencil

[STENCIL]

```text
┌──────────────────────────────────────┐
│ ← 뒤로                               │
│              새 게임 시작             │
│   지금 가능한 시작 방식과 준비 중      │
│   시작 옵션을 나눠 보여준다           │
├──────────────────────────────────────┤
│ [바로 시작]                           │
│  [무작위 시작]                        │
│  [시드 시작]                          │
├──────────────────────────────────────┤
│ [시작 설정]                           │
│  덱 선택        : 플레이스홀더         │
│  난이도 선택    : 표준/해금 기반 잠금   │
│  다음 단계      : 블라인드 선택 화면    │
└──────────────────────────────────────┘
```

설계 메모:

- `New Run`은 내부 구조명이고, 유저에게는 `새 게임 시작`으로만 보인다.
- 이 화면은 `B2 Run Setup`의 1차 선택 화면이다.
- 현재는 `랜덤 시작 / 시드 시작 -> 블라인드 선택`으로 이어진다.
- `덱 선택`은 자리만 유지하고, 실제 시작 분기는 `난이도`와 다음 `블라인드 선택` 화면이 맡는다.

### B2 Blind Select Screen Stencil

[STENCIL]

```text
┌──────────────────────────────────────┐
│ ← 뒤로                               │
│              블라인드 선택            │
│   이번 Station의 목표와 압박 조건 선택 │
├──────────────────────────────────────┤
│ [Station 1]                           │
│  [스몰 블라인드]                      │
│   목표 300 / 손패 1 / 보드 버림 4      │
│   손패 버림 2 / 보상 +10              │
│                                       │
│  [빅 블라인드]                        │
│   목표 상승 / 보드 버림 감소           │
│   현재는 잠금                         │
│                                       │
│  [보스 블라인드]                      │
│   목표 대폭 상승 / 손패 압박           │
│   현재는 잠금                         │
├──────────────────────────────────────┤
│ [현재 선택 요약]                      │
│  난이도 / 블라인드 / 목표 / 자원       │
├──────────────────────────────────────┤
│ [이 블라인드 시작]                    │
└──────────────────────────────────────┘
```

설계 메모:

- 현재 1차 구현은 `새 게임 시작`에서만 이 화면으로 진입한다.
- 장기적으로는 `이어하기 복원 직전`, `Market 이후 다음 Station 진입`도 이 화면을 공유한다.
- 블라인드 card는 `목표 점수`, `손패 크기`, `보드/손패 버림`, `보상 preview`를 함께 보여 준다.

### B1 Special Mode Screen Stencil

[STENCIL]

```text
┌──────────────────────────────────────┐
│ ← 뒤로                               │
│               특별 모드               │
│     별도 규칙을 가진 추가 모드 자리    │
├──────────────────────────────────────┤
│ [안내 카드]                           │
│  - 지금은 진입 구조만 분리             │
│  - 규칙/보상/기록 정책은 미정          │
│  - 개발 검증용 진입은 여기 두지 않음   │
└──────────────────────────────────────┘
```

설계 메모:

- 현재는 user-facing placeholder일 뿐이다.
- 개발 검증용 시나리오는 `디버그` 섹션으로만 모은다.
- 이 화면을 실제 모드로 올릴지, 더 중립적 entry로 둘지는 별도 결정이 필요하다.

### B1 Archive Screen Stencil

[STENCIL]

```text
┌──────────────────────────────────────┐
│ ← 뒤로                               │
│                기록실                 │
│   기록, 수집, 통계 흐름을 나눠 둘 자리  │
├──────────────────────────────────────┤
│ [기록]                                │
│  최근 런 결과 / 최고 기록 / 도달 정보   │
├──────────────────────────────────────┤
│ [수집]                                │
│  해금 요소 / 발견 규칙 / 수집 진행      │
├──────────────────────────────────────┤
│ [통계]                                │
│  평균 점수 / 족보 빈도 / 선택 경향      │
└──────────────────────────────────────┘
```

설계 메모:

- `Archive`는 내부 구조명이다.
- 실제 유저 노출명은 현재 `기록실`로 둔다.
- 지금 단계에서는 탭보다 3개 section shell을 먼저 고정한다.
- 세부 데이터 연결 순서와 탭 구조는 `B10`에서 확정한다.

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

[TARGET]

```text
New Run / Continue
→ Blind Select
→ battle ready
→ draw/place/discard
→ confirm
→ settlement
→ market
→ next station blind select
→ battle ready
```

UI 구성:

1. top HUD
2. Jester 5-slot strip
3. compact item zone
4. 5x5 board
5. hand/draw zone
6. bottom action buttons
7. settlement overlay
8. stage clear overlay
9. Jester detail overlay

[V4_DECISION]

Item 시스템 추가 후 battle 정보 구조는 다음 순서로 읽힌다.

1. top HUD
2. Jester strip
3. Item zone
4. 5x5 board
5. hand/draw zone

현재 반영 메모:

- `JESTER 4/5`형 긴 헤더는 축소하고, item zone이 더 많은 가로 폭을 쓰도록 정리 중이다.
- item zone은 설명형 bar보다 `큰 슬롯 3개`를 우선 보여 주는 방식으로 이동 중이다.
- battle debug 진입은 상단 inline cluster 대신 `보드 우측 small debug button -> modal bottom sheet` 구조로 이동했다.
- debug bottom sheet에는 `MARKET`, `Hand size`, blind clear 류 조작을 모아 일반 HUD와 의미가 섞이지 않게 분리한다.
- 하단 action row 기본 순서는 `선택 해제 / 보드 버림 / 손패 버림 / 확정`이다.

### 3.1 Card Slot Visual Contract

[CURRENT]

Battle과 Market의 Jester / Item 슬롯은 같은 카드 체급을 기준으로 한다.

기준 크기:

- Jester card body: `58 x 78`
- Item slot body: `58 x 78`
- Jester strip: 5 slots
- Item zone: 3 large slots
- Selection outline outset: card body 바깥 `3px`
- Selection outline stroke: `3px`

구조 규칙:

- 카드 body는 슬롯 전체를 채운다. 선택 표시를 위해 카드 body 자체를 축소하지 않는다.
- 선택 외곽선은 카드 안쪽 padding이 아니라 카드 바깥 overlay로 그린다.
- 선택 외곽선 공간이 필요한 화면은 카드 주변 layout cell에 별도 여백을 예약한다.
- Jester 실제 카드와 빈 Jester 슬롯은 같은 외곽 체급으로 보여야 한다.
- Market의 Jester card는 battle의 `GameJesterSlot` 기준을 따른다. Market 전용 wrapper는 위치/여백 예약만 맡고 카드 구조를 다시 만들지 않는다.
- Market의 Item offer card도 같은 `58 x 78` 체급을 따른다. 다만 Item의 내부 표현은 Jester와 별도 구현할 수 있다.
- 가격 라벨처럼 카드 아래에 붙는 텍스트가 있으면 cell height는 `card height + selection outset * 2 + label line budget`으로 계산한다.

코드 기준:

- Jester body size: `kJesterCardWidth`, `kJesterCardHeight`
- Battle item slot size: `kBattleItemSlotWidth`, `kBattleItemSlotHeight`
- Selection outline: `kJesterSelectionOutset`, `kJesterSelectionBorderWidth`
- Market offer cell height는 위 상수를 조합한 식으로 유지하고, magic number로 되돌리지 않는다.

[WATCH]

전투 화면에서 item을 `5x5 보드 우측 세로 column`으로 이동하는 안은 상세 패널 충돌 때문에 현재 보류한다.

이유:

- item 선택 상세와 grid/jester 선택 상세가 같은 공용 정보 패널을 써야 한다.
- 우측 세로 column을 고정하면 detail overlay/panel과 충돌하거나 phone frame에서 읽기성이 떨어진다.
- 현재 방향은 `가로 item zone 유지 + 슬롯 체급 확대 + 공용 상세 패널 유지`다.
6. bottom action buttons
7. overlays

상세 계약은 `13_ITEM_SYSTEM_CONTRACT.md`를 기준으로 한다.

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
- Item
- Upgrade
- Permit
- Glyph
- Echo
- Service

단, 기존 Jester shop UX를 먼저 유지한다.

[V4_DECISION]

`Item`은 `Jester`와 별도 섹션으로 취급한다.

예상 UI 변화:

- Market 상단 또는 본문에서 `Jester` / `Item` section 분리
- Jester는 현재처럼 보유 슬롯과 연결된 카드 진열형 유지 가능
- Item은 `inventory`, `quick slot`, `service card`, `consumable row` 중 하나로 별도 표현
- battle 화면도 `Jester strip + Item zone`으로 분리 재설계 필요
- item 4분류 표현 규칙과 market 정보 구조는 `13_ITEM_SYSTEM_CONTRACT.md`를 기준으로 확정한다

### 6.1 Market Category Grouping

[TARGET]

상점 UI는 내부 도메인 타입을 그대로 노출하기보다,
유저가 이해하기 쉬운 상위 카테고리로 묶을 수 있다.

권장 묶음:

```text
Jester Shop
- Jester

Utility Shop
- Item
- Service

Meta Shop
- Permit
- Run Kit upgrade
- Sigil

Modifier / Pack
- Glyph
- Echo
```

[V4_DECISION]

단, 현재 단계에서 가장 먼저 구현할 상점 분리는 아래 두 축이다.

```text
1. Jester Shop
2. Item Shop
```

이후 multi-content market이 확장되면 `Meta Shop`, `Modifier / Pack` 계층을 추가한다.

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
