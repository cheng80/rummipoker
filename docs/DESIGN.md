# Design System: Rummi Poker Grid

> 목적: 현재 구현된 `GameView` 기반 화면과 최신 게임 규칙을 기준으로,  
> **Flutter 게임 UI 리디자인**과 **Stitch MCP 목업 생성**에 바로 사용할 수 있는 시각 사양을 고정한다.

---

## 1. Current Screen Snapshot

현재 화면은 다음 구조를 가진다.

1. **App Shell**
   - 바깥은 어두운 배경 또는 별 배경
   - 중앙에 세로형 게임 프레임
   - 상단은 별도 제목줄 없이 아주 얇은 정보 레이어만 허용
   - `runSeed`는 메인 화면에 노출하지 않고 **옵션 다이얼로그 내부**에서만 복사 가능하게 둔다
   - 옵션 버튼도 HUD를 먹지 않는 최소 면적으로 정리한다

2. **In-Game HUD**
   - 남은 **보드 버림 `D_board` / 손패 버림 `D_hand`**
   - 현재 점수 / 목표 점수 `T`
   - 골드 / 블라인드 / 보드 상태 같은 스테이지 핵심 정보

3. **Jester Strip**
   - 상단 정보 바 바로 아래에 장착 Jester 5슬롯
   - 빈 슬롯도 카드형 세로 비율 플레이스홀더로 유지
   - 장착 카드 탭 시 정보/판매 패널 진입 가능
   - 슬롯 카드 본문은 현재 **제목 + 분류 배지 + 활성 표시만** 보여 주고, 긴 설명과 현재 수치는 상세 패널에서 확인한다

4. **Playfield**
   - 중앙 5x5 보드
   - 보드 셀에 루미큐브 질감의 숫자 타일
   - 완성된 줄에 족보 라벨 오버레이
   - 점수 줄과 죽은 줄을 다른 외곽선으로 표현

5. **Hand + Draw Zone**
   - 손패 기본값은 1장
   - 현재 구현은 디버그 메뉴에서 1~3장까지 조절 가능하지만, 기본 밀도 설계는 1장 기준으로 본다
   - 좌측 드로우 버튼 + 우측 단일 손패 표시
   - 남은 덱 수 / 버림 정보는 사용자 행동과 가까운 이 구역에 두는 쪽을 우선
   - 불필요한 받침대/녹색 레일/장식선은 기본값에서 제거
   - 나중에 필요하면 Flutter 또는 별도 이펙트 레이어로 연출만 추가

6. **Bottom Action Row**
   - `줄 확정`
   - `보드패 버림`
   - `손패 버림`
   - `선택 해제`

현재 코드 기준 핵심 룰:
- 점수 줄만 `줄 확정`으로 제거 가능
- **죽은 줄은 확정 제거하지 않음**
- 죽은 줄은 **보드 위 5개 타일 중 하나를 버림(D)** 해서 완화
- `Removal(C)` 자원은 **없음**

Stitch용 해석 우선순위:
1. **레이아웃 구조**
2. **타일 재질과 보드 가독성**
3. **상태 색 구분**
4. **분위기와 장식 효과**

즉, 무드보다 구조가 먼저다.

---

## 2. Visual Theme & Atmosphere

이 게임의 화면은 `Balatro`의 과장된 네온과 카지노 감성을 참고하되, 실제 터치 플레이는 **루미큐브 타일의 물성**과 **정갈한 보드 읽기성**이 우선이다.

분위기 키워드:
- **Dark card-room**
- **Emerald felt**
- **Cream tile tactility**
- **Arcade glow without chaos**
- **Readable strategy dashboard**

화면은 완전히 사이키델릭하게 가면 안 된다. 현재 게임은 5x5 라인 판독이 중요하므로, 배경은 깊고 어둡게 유지하고 정보 계층은 또렷해야 한다. 즉, 무드는 `Balatro`, 읽기성은 `board puzzle`, 촉감은 `Rummikub tile` 쪽으로 잡는다.

피해야 할 해석:
- 슬롯머신 UI처럼 정보 패널이 과도하게 번쩍이는 구성
- 카드배틀 게임처럼 캐릭터 일러스트나 대형 아이콘이 들어가는 구성
- 퍼즐 보드보다 버튼이나 장식이 더 눈에 띄는 구성

---

## 3. Color Palette & Roles

### Core Surface

- **Night Felt Green** `#0D1F14`
  - 게임 필드의 기본 배경
  - 현재 Flutter 게임 화면의 기본 바닥색 출발점

- **Deep Moss Panel** `#1B3326`
  - 보드 빈 칸, 내부 패널, HUD 바닥색
  - 필드와 같은 계열이지만 한 단계 밝은 레이어

- **Shadow Black-Green** `#08110C`
  - 외곽 그림자, 프레임 분리, 깊이감

### Tile System

- **Warm Ivory Tile Face** `#F2EDE6`
  - 루미 타일 전면
  - 가장 중요한 촉감 요소

- **Soft Stone Border** `#C5BDB0`
  - 타일 테두리
  - 크림 면과 숫자 사이를 안정적으로 구분

- **Ruby Rank** `#C62828`
  - 빨간 타일 숫자/상단 바

- **Royal Blue Rank** `#1565C0`
  - 파란 타일 숫자/상단 바

- **Amber Orange Rank** `#E65100`
  - 노랑 슈트 대응 컬러
  - 현재 구현에서는 노란색 대신 주황 계열로 선명도 확보

- **Graphite Rank** `#212121`
  - 검정 타일 숫자/상단 바

### State / Feedback

- **Gold Selection Ring** `#FFC107`
  - 선택한 손패 또는 보드 타일 강조

- **Burnt Orange Score Line** `#E65100`
  - 점수 줄 외곽선
  - 완성된 유효 핸드 하이라이트

- **Mist Slate Dead Line** `#37474F`
  - 죽은 줄 외곽선
  - 실패는 아니지만 지금 확정 가치가 없다는 뜻

- **Pale Mist Label** `#ECEFF1`
  - 죽은 줄 라벨 텍스트

- **Dark Olive Label Chip** `#263D0D`
  - 점수 줄 족보 라벨 배경감

### Shell / Overlay

- **Outer Space Black** `#000000`
  - 웹/프레임 바깥 배경

- **Dialog Forest** `#1A2E24`
  - 설정/옵션 다이얼로그 배경

---

## 4. Typography Rules

### Display Tone

- 헤드라인과 중요한 버튼은 **압축감 있는 게임형 디스플레이 폰트**
- 숫자, 점수, 족보 라벨은 **짧고 강하게**
- 지나치게 픽셀화된 폰트보다는, 픽셀 감성만 느껴지는 **단단한 아케이드 스타일**이 적합

### Body Tone

- 시스템 안내, 설정, 스낵바, 보조 정보는 읽기 쉬운 산세리프
- 손패/덱/점수 수치는 작은 크기에서도 또렷해야 하므로 장식보다 명료함 우선

### Text Character

- 점수 줄 라벨: `bold`, 약한 그림자, 작은 배지 느낌
- HUD 수치: 정보 밀도는 높지만 한 줄씩 빠르게 스캔 가능해야 함
- 버튼: 짧은 한국어 라벨을 기준으로 중앙 정렬

---

## 5. Component Stylings

### Game Frame

- 전체 게임 패널은 **둥근 모서리의 세로형 카드/캐비닛**
- 웹에서는 어두운 배경 위에 떠 있는 듯한 그림자 사용
- 모바일에서는 화면 전체를 차지해도 내부 구조는 동일하게 유지

### HUD Panel

- 상단 HUD는 하나의 넓은 패널처럼 읽히되, 실제 시각적으로는
  - 덱/버림
  - 목표/점수
  - 보드 상태
  의 3개 정보 레이어가 느껴지게 구성
- 단순 텍스트 나열보다 **계기판(dashboard)** 처럼 보여야 함
- 추후 리디자인 시 얇은 금속 프레임, 미세한 내부 광택, 절제된 네온 라인 허용
- **중요**: 숫자 위계는 `현재 점수 / 목표 점수`가 가장 크고, 덱/손패/보드 점유 정보는 보조 정보여야 함

### Board Cells

- 셀 자체는 어두운 초록 사각 슬롯
- 각 셀은 얇은 테두리로만 구획
- 타일이 들어가면 타일의 크림색 면이 강하게 떠야 함
- 보드 자체는 **정보 해석 도구**이므로, 지나친 패턴 배경은 피한다
- Stitch 결과에서도 보드 셀 크기와 간격은 균일해야 하며, 체스판처럼 강한 대비 패턴을 넣지 않는다

### Rummikub Tile

- 실물 타일처럼 **크림색 전면 + 상단 컬러 바 + 큰 숫자**
- 둥근 직사각형
- 미세한 그림자
- 선택 시 금색 링
- 현재 구현에서는 **슈트 아이콘은 넣지 않고**, face card인 `11/12/13`만 **하단 중앙의 컬러 점**으로 표시한다
- 이 타일 비주얼은 프로젝트의 핵심 아이덴티티이므로 Stitch 결과물에도 반드시 유지

### Line Overlay

- 점수 줄: 따뜻한 주황 외곽선 + 또렷한 족보 라벨
- 죽은 줄: 차갑고 탁한 회청색 외곽선 + 덜 공격적인 라벨
- 라벨은 보드를 가리지 않도록 선 근처에 작게 뜨는 배지 형태
- 화면이 복잡해지지 않도록 **채우기(fill)** 보다 **외곽선(stroke)** 위주

### Draw Button

- 손패 왼쪽에 세로로 긴 액션 버튼
- "새 타일 유입구"처럼 보여야 함
- 버튼이라기보다 **드로우 레버/도어** 같은 성격이 어울림

### Hand Strip

- 기본 1장 기준, **플레잉 카드**가 아니라 **실제 루미큐브 타일**처럼 보여야 한다. 디버그로 2~3장까지 늘어나도 같은 시각 언어를 유지한다
- 현재 기본안은 **불필요한 랙/받침대 없이 타일 자체만 또렷하게** 보여 주는 방향이다
- 나중에 랙을 추가하더라도 화면 하단을 잡아먹는 받침대보다는, 최소 두께의 보조 요소만 허용한다
- Stitch 결과에서 손패가 종이 카드, 트럼프, 포커 카드처럼 보이면 실패다
- 타일은 반드시 다음 특성을 유지한다
  - 크림색 전면
  - 상단 컬러 바
  - 굵은 숫자
  - `11/12/13` 하단 중앙 점 표식
  - 짧은 그림자
  - 두께감 있는 플라스틱 조각 느낌

### Bottom Action Buttons

- 하단 4분할
- `줄 확정`이 가장 중요하지만, 현재 구조상 네 버튼 모두 동등한 폭을 유지
- 이후 리디자인에서 `줄 확정`만 더 밝거나 발광도를 높여 우선순위를 줄 수 있음
- Stitch 목업에서는 버튼 텍스트를 아래 중 하나로 통일한다
  - 한국어: `보드패 버림`, `손패 버림`, `줄 확정`, `선택 해제`
  - 영어 대체: `BOARD DISCARD`, `HAND DISCARD`, `COMMIT`, `CLEAR`
- 한 목업 안에서 한국어/영어를 섞지 않는다

---

## 6. Responsive Frame Rules

### 목표

- iPhone 기준으로 설계한 세로형 UI 비율과 밀도를 유지한다.
- iPad 같은 넓은 화면에서는 콘텐츠를 중앙에 두고, 남는 좌우 영역은 배경으로만 채운다.
- 게임 화면뿐 아니라 타이틀, 설정, 상점 같은 비게임 화면도 같은 중앙 phone-frame 기준을 쓴다.

### 위젯 레이어

```text
Scaffold
└─ SafeArea
   └─ 전체 배경
      └─ LayoutBuilder
         └─ Center
            └─ SizedBox(frameWidth, frameHeight)
               └─ 필요 시 FittedBox + 고정 논리 해상도 + MediaQuery(size override)
                  └─ 실제 화면 콘텐츠
```

- 배경은 항상 `Center` 바깥에서 SafeArea 전체를 채운다.
- 실제 콘텐츠는 중앙의 세로형 프레임 안에서만 그린다.
- 태블릿에서는 프레임만 중앙 정렬되고, 좌우는 늘어난 배경만 보여야 한다.

### 프레임 계산 규칙

- 기준 논리 크기: `390 x 750`
- 기준 비율: `13:25`
- 플랫폼별 분기 없이, **항상 같은 논리 크기**를 사용한다.
- 실제 프레임 크기는 `min(maxWidth / 390, maxHeight / 750)` 스케일로 계산한다.
- 즉 웹 / iPad / 폰 모두:
  - 바깥은 현재 화면에 맞는 `13:25` 프레임만 계산
  - 안쪽은 항상 `390 x 750` 기준으로 레이아웃
  - 남는 좌우 또는 상하 영역은 배경으로만 채운다

### 논리 해상도 고정

- `SizedBox(width: 390, height: 750)` 로 기준 화면을 고정한다.
- 자식은 `MediaQuery.copyWith(size: Size(390, 750))` 를 통해 항상 같은 논리 크기를 보게 한다.
- 바깥 프레임과 실제 콘텐츠는 `FittedBox(fit: BoxFit.contain)` 로 연결한다.

### 현재 적용 원칙

- `GameView`, `TitleView`, `SettingView`, 상점/옵션 계열은 같은 `PhoneFrameScaffold` 규칙을 공유한다.
- 타이틀 화면은 중앙 정렬만 유지하고, 별도 외곽선/그림자 패널 없이 배경 위에 내용만 올린다.
- 설정/상점 화면은 일반 `Scaffold` 관성 대신, 게임 화면과 동일한 안전 영역·폭·정렬 기준을 사용한다.
- 내부 콘텐츠는 화면 실제 픽셀 크기가 아니라 **고정 논리 해상도**를 기준으로 폰트와 비율을 유지한다.

### 체크 포인트

1. 큰 화면에서도 콘텐츠가 프레임 내부에서 다시 왼쪽 정렬되지 않는지 확인한다.
2. 배경이 프레임과 함께 줄어들지 않고 SafeArea 전체를 채우는지 확인한다.
3. `MediaQuery`를 덮어쓸 때 `size`만 바꾸고 나머지 접근성 정보는 유지한다.
4. 키보드, 분할 화면, 웹 브라우저 리사이즈 시에도 `13:25` 비율과 내부 밀도가 유지되는지 확인한다.

### Seed / Options

- 시드 번호는 메인 HUD에 상시 노출하지 않는다
- 시드 확인/복사는 **옵션 다이얼로그 안**에서만 제공한다
- 실제 플레이 화면은 제목줄 없이 유지하고, 옵션 버튼만 최소 면적으로 남긴다

---

## 6. Layout Principles

### Portrait-First

- 기준은 **세로형 9:16 모바일**
- `390 x 750` 전후의 논리 크기에서 밀도 조정
- 태블릿/웹에서는 중앙 정렬 + 바깥 배경 확장
- Stitch에서는 **단일 모바일 프레임** 안에서 먼저 해결하고, 태블릿 변형은 별도 화면으로 분리한다
- 상단 세이프 에어리어를 제외하면 세로 여유가 매우 제한적이므로, 앱식 타이틀 바/네비게이션 바/브랜드 헤더는 금지한다

### Vertical Rhythm

- 상단 HUD
- 중앙 보드
- 하단 손패
- 최하단 액션 행

이 네 구역이 분명히 읽혀야 한다.

권장 비율:
- 상단 HUD: 약 14%~18%
- 중앙 보드: 약 42%~50%
- 손패/드로우 영역: 약 18%~22%
- 하단 액션 행: 약 10%~14%

### Board Priority

- 화면의 주인공은 항상 5x5 보드
- 손패와 버튼은 보드의 이해를 돕는 보조 레이어여야 한다
- 보드보다 더 강한 비주얼 노이즈를 아래 영역에 두지 않는다

### Thumb Reach

- `버림`, `줄 확정`, `선택 해제`는 한 줄에 두고 엄지 영역에서 바로 누를 수 있어야 한다
- 드로우는 별도 세로 버튼으로 분리해 행동 종류를 명확히 구분한다

### Controlled Density

- 화면 정보는 많지만 복잡해 보이면 안 된다
- 카드게임식 화려함은 HUD 외곽, 버튼 발광, 라벨 처리에 제한적으로만 사용
- 보드 셀 내부와 타일 숫자는 항상 최우선 가독성을 유지

---

## 7. Screen Mapping for Stitch

Stitch에 넣을 때는 아래 요소를 **반드시 현재 규칙 기준**으로 유지한다.

포함해야 하는 것:
- 세로형 게임 화면
- 상단 목표 점수 / 현재 점수 / 버림 `D`
- 상단 또는 HUD에 이번 스테이지 핵심 정보
- 남은 덱 수는 하단 손패/드로우 구역 쪽 정보로 배치 가능
- 상단 정보 바 바로 아래의 `Jester` 5슬롯
- 중앙 5x5 보드
- 루미큐브 스타일 숫자 타일
- 점수 줄 1개와 죽은 줄 1개를 서로 다른 라인 스타일로 표시
- 좌측 세로 드로우 버튼
- 하단 기본 1장 손패 슬롯 또는 단일 랙. 디버그 시 2~3장까지도 같은 영역에서 수용 가능해야 한다
- 하단 액션 버튼 3개: `줄 확정`, `버림`, `선택 해제`
- 상단 우측 옵션 버튼
- 시드는 메인 화면 상시 노출이 아니라 옵션/설정 컨텍스트에서만 노출

넣으면 안 되는 것:
- 앱 제목줄, 브랜드 헤더, 큰 상단 네비게이션 바
- 상단 중앙 시드 배지
- `Removal(C)` 버튼 또는 `C` 자원
- 중앙에 단일 부유 타일만 두는 구도
- 보드를 가리는 과도한 네온, 이펙트, 입자
- 보드 바깥에 떠다니는 조커 카드, 캐릭터, 장식 패널
- 손패를 2장 이상으로 그리는 구성

---

## 8. Stitch MCP Prompt

아래 프롬프트는 현재 코드와 최신 룰에 맞춘 버전이다.

```markdown
# Command: Generate a portrait mobile mockup for "Rummi Poker Grid"

You are a senior game UI designer. Create a high-fidelity portrait mobile game mockup for a puzzle-card game called "Rummi Poker Grid".

## Core concept
- A 5x5 board puzzle using Rummikub-style number tiles and poker hand evaluation.
- The screen should feel like a dark casino strategy game mixed with tactile tabletop tiles.
- The mood should be dramatic and stylish, but still highly readable.
- Prioritize layout accuracy and board readability over cinematic decoration.

## Important rule alignment
- There is NO Removal(C) resource.
- Dead lines are NOT removed by a special button.
- Dead lines are softened only by discarding one tile from the board.
- The UI must show target score T, current score, and discard count D.
- The hand size is 1 tile maximum.

## Visual style
- Dark emerald felt background
- Cream-colored Rummikub-like tiles with a colored top bar
- Warm orange highlight for scoring lines
- Cool slate highlight for dead lines
- Soft neon accents, but not psychedelic clutter
- Rounded portrait game cabinet / panel framing

## Layout requirements
1. Top shell
- A small option button at the top right

2. HUD panel
- Show current score and target score T prominently
- Show discard count D
- Show stage-level core information such as gold, blind, or board state in compact form
- Show hand count and board occupancy in a compact dashboard style
- Make score progress visually dominant inside the HUD

2.5 Jester strip
- Place a 5-slot Jester strip directly below the top HUD
- Empty slots should still read as upright card-shaped placeholders
- These are equipped meta cards, not board tiles

3. Main board area
- A centered 5x5 board
- Several cream tile pieces already placed on the board
- One completed scoring line highlighted with a warm orange outline and a small rank label
- One dead line highlighted with a cool gray-blue outline and a small rank label
- The board itself must remain clean and readable

4. Draw and hand area
- On the left side, a tall vertical DRAW button
- On the right side, a single-tile rack or 1-slot tray
- The tile should look tactile and slightly shadowed
- Do not show more than 1 hand slot
- Avoid decorative backplates or long glowing rails behind the hand tile

5. Bottom action row
- Three side-by-side buttons:
  - "COMMIT"
  - "DISCARD"
  - "CLEAR"
- Keep them large enough for thumb interaction
- The three buttons should sit on one bottom row, equal width

## Typography
- Use a strong arcade-inspired display font for key labels
- Use a clean sans-serif for supporting information
- Keep labels short and sharp

## Composition guidance
- 9:16 portrait
- The board is the hero
- Avoid clutter and avoid oversized decorative effects
- The design should feel production-ready for a Flame mobile game, not like a generic fantasy card UI
- Keep the HUD, board, hand area, and action row clearly separated as four stacked bands
- Use only one mobile screen, not a presentation board or multi-panel concept sheet

## Explicit exclusions
- Do not put jokers on the board or add a "Removal(C)" button
- Do not show an always-visible seed badge on the main HUD
- Do not center the whole design around a single floating tile
- Do not use purple-dominant color schemes
- Do not add character portraits, fantasy card frames, or oversized VFX clouds
```

---

## 9. Implementation Notes

- 현재 타일 외형 기준은 [`lib/game/rummi_poker_grid/rummikub_tile_canvas.dart`](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/lib/game/rummi_poker_grid/rummikub_tile_canvas.dart) 이다.
- 현재 레이아웃 구조 기준은 [`lib/game/rummi_poker_grid/rummi_poker_grid_game.dart`](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/lib/game/rummi_poker_grid/rummi_poker_grid_game.dart) 와 [`lib/views/game_view.dart`](/Users/cheng80/Desktop/FlutterFrame_work/flame_binggo_card/lib/views/game_view.dart) 이다.
- Stitch 결과물은 **레퍼런스 목업**으로만 사용하고, 실제 구현은 현재 Flutter 위젯 레이아웃과 타일 렌더링 규칙을 우선한다.
