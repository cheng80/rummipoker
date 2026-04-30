# 06. UI / UX Flow

> 문서 성격: UI/UX 기능 계약
> 코드 반영 상태: title/battle/shop/settings implemented, station/archive/trial target partial shell
> 핵심 정책: 현재 플레이 가능한 흐름을 깨지 않고, Home / Battle / Market / Archive 축으로 확장한다.

현재 화면 파일과 widget 경계는 `docs/current_system/CURRENT_CODE_MAP.md`를 기준으로 본다.
구현 완료/미완료 상태는 `docs/planning/STATUS.md`를 기준으로 본다.

## 1. Current Boundary Reference

[CURRENT]

현재 구현에서 보호해야 할 사실만 요약한다.

- 주요 화면: `TitleView`, `GameView`, `GameShopScreen`, `SettingView`
- 공통 frame: `PhoneFrameScaffold`, portrait-first, 논리 크기 390 x 750
- 현재 주요 flow: title -> setup/blind select -> battle -> settlement -> market -> next station
- current shop은 full-screen route다.
- battle은 Jester strip, Item zone, 5x5 board, hand/draw, action row를 함께 보여 준다.
- debug 조작은 일반 HUD와 분리해야 한다.

## 2. Home / Entry Contract

[V4_DECISION]

현재 `TitleView`는 Home의 1차 구현으로 본다.

Home은 아래 entry를 분리해서 보여야 한다.

```text
Home
- Continue
- New Run
- Special Mode / Trial
- Archive
- Settings
- Developer entry(debug only)
```

UX 계약:

- 사용자는 내부 구조명 `Home / Trial / Archive`를 직접 볼 필요가 없다.
- `Continue`는 버튼 하나가 아니라 저장된 진행 요약을 포함한 block으로 본다.
- `Continue`의 Home 노출 요약은 현재 위치를 짧게 보여 주고, 체크포인트/scene 같은 검증성 세부 정보는 dialog 또는 debug 맥락으로 보낸다.
- `New Run`은 유저에게 `새 게임 시작`으로 보인다.
- 개발 검증용 진입은 user-facing special mode와 섞지 않는다.
- debug entry는 debug build 또는 developer option 뒤에 둔다.

## 3. Run Setup / Blind Select Contract

[V4_DECISION]

Run setup은 현재 가능한 시작 방식만 제품 화면에 노출한다.
future setup 축은 실제 선택 가능한 기능이 되기 전까지 일반 화면에 플레이스홀더로 보이지 않는다.

```text
New Run
-> Random / Seed start
-> Blind Select
-> Battle
```

Starting deck/archetype selection은 v1 New Run 범위가 아니다. 후속으로 추가할 경우 `docs/planning/feature_plans/STARTING_DECK_ARCHETYPE_PLAN.md`의 `run_archetype_id` 기준을 따른다.

Blind select card는 최소한 아래 정보를 함께 보여야 한다.

- station/stage index
- blind kind
- target score
- hand size
- board discard
- hand discard
- reward preview
- locked/unlocked state

Blind Select UX 규칙:

- `Small / Big / Boss` card는 한 모바일 viewport에서 비교 가능해야 한다.
- card 전체 tap은 시작 액션이 아니다. 사용자가 정보를 읽는 중 실수로 전투에 들어가지 않도록 명시적인 play button만 시작 액션을 가진다.
- 별도 현재 선택 summary와 하단 시작 button은 두지 않는다.
- 게임 화면 문구에는 말줄임표를 쓰지 않는다. 필요한 경우 짧은 문구로 바꾸거나 2줄까지 허용한다.

장기적으로 Market 이후 다음 Station 진입도 같은 blind select 구조를 재사용할 수 있어야 한다.

Station Preview v1 결정:

- 현재 `BlindSelectView`를 Station Preview v1로 사용한다.
- `Station N` 섹션 안에서 `Small / Big / Boss` objective를 비교하는 구조를 유지한다.
- branch형 Station Map 화면, route 선택, Station modifier 선택 UI는 후속이다.
- 이 화면의 카드 정보는 ML simulator/log schema의 station objective source와 일치해야 한다.
- Boss objective에 modifier가 붙는 경우, modifier 이름/영향 범위/짧은 규칙 문구를 전투 진입 전에 같은 카드 안에서 보여야 한다.

Constraint visual rule:

- 제약 표시는 `docs/planning/feature_plans/CONSTRAINT_VISUAL_LANGUAGE_PLAN.md`를 기준으로 한다.
- Boss/Station 제약이 있으면 전투 진입 시 팝업 또는 bottom sheet로 제약 이름, 대상, 한 줄 규칙을 먼저 설명한다.
- 전투 중에는 타일/Jester/Item 위에 작은 marker만 유지하고, 실제 감점은 점수 발생 위치의 짧은 float로 보여 준다.
- 긴 제약 설명을 battle board 주변에 상시 노출하지 않는다.
- user-facing 문구는 짧은 한글 설명만 사용한다. 내부 modifier id, enum, JSON field, score parameter를 화면에 노출하지 않는다.

## 4. Battle Screen Contract

[V4_DECISION]

Battle 화면의 정보 우선순위는 아래 순서를 따른다.

1. top HUD
2. Jester strip
3. Item zone
4. 5x5 board
5. hand/draw zone
6. bottom action buttons
7. overlays

Item 시스템 추가 후에도 Jester와 Item은 같은 strip으로 합치지 않는다.

기본 action row:

```text
선택 해제 / 보드 버림 / 손패 버림 / 확정
```

debug 조작은 상단 inline cluster가 아니라 작은 진입 버튼과 modal/bottom sheet로 분리한다.

## 5. Card Slot Visual Contract

[V4_DECISION]

Battle과 Market의 Jester / Item 슬롯은 같은 카드 체급을 기준으로 한다.

기준 크기:

- Jester card body: `58 x 78`
- Item slot body: `58 x 78`
- Jester strip: 5 slots
- Item zone: 3 large slots
- Selection outline outset: card body 바깥 `3px`
- Selection outline stroke: `3px`

구조 규칙:

- 카드 body는 슬롯 전체를 채운다.
- 선택 표시를 위해 카드 body 자체를 축소하지 않는다.
- 선택 외곽선은 카드 바깥 overlay로 그린다.
- 선택 외곽선 공간이 필요한 화면은 카드 주변 layout cell에 별도 여백을 예약한다.
- Jester 실제 카드와 빈 Jester 슬롯은 같은 외곽 체급으로 보여야 한다.
- Market의 Jester card는 battle의 `GameJesterSlot` 기준을 따른다.
- Market의 Item offer card도 같은 `58 x 78` 체급을 따른다.
- 가격 라벨처럼 카드 아래에 붙는 텍스트가 있으면 cell height는 `card height + selection outset * 2 + label line budget`으로 계산한다.

코드 상수 기준:

- `kJesterCardWidth`
- `kJesterCardHeight`
- `kBattleItemSlotWidth`
- `kBattleItemSlotHeight`
- `kJesterSelectionOutset`
- `kJesterSelectionBorderWidth`

전투 화면에서 item을 `5x5 보드 우측 세로 column`으로 이동하는 안은 현재 보류한다. 공용 상세 패널과 phone frame 읽기성을 우선한다.

## 6. Confirm / Settlement UX Contract

[V4_DECISION]

Confirm UX는 contributor와 non-contributor를 명확히 구분해야 한다.

- dead line은 강조하지 않는다.
- scoring candidate의 contributor cell만 강조한다.
- 키커나 non-contributor는 강조하지 않는다.
- 정산 시 사라지는 타일과 남는 타일이 예측 가능해야 한다.
- line별 rank, overlap, Jester/Item effect feedback을 확장할 수 있어야 한다.

Settlement는 현재 cash-out sheet에서 Station Reward Settlement로 확장 가능해야 한다.

표시 기준:

- station/stage index
- target score
- base reward
- remaining board discard reward
- remaining hand discard reward
- economy Jester/Item reward
- total gained gold
- current gold

## 7. Market UX Contract

[V4_DECISION]

Market은 full-screen route를 유지하되, 상품군을 분리할 수 있어야 한다.

초기 분리:

```text
Jester Shop
Item Shop
```

장기 grouping:

```text
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

Jester는 현재처럼 보유 슬롯과 연결된 카드 진열형을 유지할 수 있다.
Item은 inventory, quick slot, service card, consumable row 중 별도 표현을 사용한다.

Item 4분류 표현 규칙과 market 정보 구조는 `13_ITEM_SYSTEM_CONTRACT.md`를 기준으로 본다.

## 8. Archive / Trial UX Contract

[TARGET]

Archive는 실제 유저 노출명으로 `기록실`을 사용한다.

초기 shell은 아래 세 section을 기준으로 한다.

```text
기록
수집
통계
```

Trial / Special Mode는 user-facing placeholder와 개발 검증용 entry를 분리한다.
규칙/보상/기록 정책은 별도 결정 전까지 current runtime 기준으로 쓰지 않는다.

## 9. Terminology Contract

[MIGRATION]

UI 용어 전환 우선순위:

1. 플레이어-facing 문구에서 `Stage`를 `Station`으로 전환할 수 있다.
2. 코드 내부 `stageIndex`, `RummiBlindState`, `scoreTowardBlind`는 유지한다.
3. save schema는 먼저 adapter를 둔다.
4. 모든 화면에서 용어가 안정화된 뒤 코드 rename을 검토한다.

## 10. Debug UX Policy

[V4_DECISION]

Debug 동선은 개발에는 유지하되, release build에서는 다음 중 하나로 처리한다.

- `kDebugMode` 뒤로 숨김
- developer options로 이동
- QA build flavor 전용

Debug 기능은 일반 런의 player-facing UX와 같은 hierarchy에 두지 않는다.

## 11. Accessibility / Readability Target

[TARGET]

V4 UI 개선 방향:

- board tile readability 우선
- overlap/score feedback는 텍스트와 애니메이션 모두 제공
- color-only feedback 금지
- Jester / Item effect 설명은 한 줄 요약 + 상세 패널 분리
- seed/run id 복사 기능 추가
- save invalid 메시지는 사용자가 선택할 수 있게 표시
