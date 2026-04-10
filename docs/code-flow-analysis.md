# Tab Order 코드 흐름 분석

이 문서는 현재 프로젝트의 구조와 실행 흐름을 1차 정리한 분석본이다.  
목표는 `lib/main.dart`를 시작점으로 앱이 어떻게 올라오고, 어떤 위젯과 게임 객체가 어떤 순서로 연결되는지 빠르게 따라갈 수 있게 정리하는 것이다.

## 1. 프로젝트 구조 요약

이 프로젝트는 크게 4개 층으로 나뉜다.

1. 앱 시작/부트스트랩
   - `lib/main.dart`
   - `lib/app.dart`
2. 라우팅/화면 전환
   - `lib/router.dart`
   - `lib/views/title_view.dart`
   - `lib/views/game_view.dart`
   - `lib/views/setting_view.dart`
3. 게임 코어
   - `lib/game/bingo_card_game.dart`
   - `lib/game/components/*.dart`
4. 공통 서비스
   - `lib/resources/sound_manager.dart`
   - `lib/services/game_settings.dart`
   - `lib/utils/storage_helper.dart`

핵심 구조는 다음과 같다.

```text
Flutter App Shell
├─ main.dart
├─ App(MaterialApp.router)
├─ GoRouter
│  ├─ TitleView
│  ├─ GameView
│  └─ SettingView
└─ GameView 내부
   └─ Flame GameWidget
      └─ BingoCardGame
         ├─ camera.backdrop
         │  └─ SpaceBg
         ├─ camera.viewport
         │  └─ GameHud
         │     └─ _PauseButton
         └─ world
            ├─ GridBg
            └─ CubeButton x 25
```

현재 프로젝트는 템플릿과 같은 앱 셸 구조에서 출발했지만, 게임 코어는 `Player 이동형`이 아니라 `5×5 그리드 퍼즐형`으로 바뀌었다.

## 2. main.dart부터 시작하는 전체 실행 순서

### 2-1. 큰 흐름

```text
main()
├─ WidgetsFlutterBinding.ensureInitialized()
├─ EasyLocalization.ensureInitialized()
├─ StorageHelper.init()
├─ InAppReviewService.saveFirstLaunchDateIfNeeded()
├─ SoundManager.preload()
├─ _applyKeepScreenOn()
└─ runApp(EasyLocalization(child: App()))
   └─ App.build()
      └─ MaterialApp.router(...)
         └─ appRouter
            └─ initialLocation = "/"
               └─ TitleView.build()
                  ├─ _StarryBackground
                  ├─ "숫자 모드" -> context.go("/game?mode=0")
                  ├─ "알파벳 모드" -> context.go("/game?mode=1")
                  └─ "설정" -> context.push("/setting")
                     └─ SettingView
```

게임 시작 시 흐름은 다음과 같다.

```text
GameView.initState()
└─ SoundManager.playBgm(AssetPaths.bgmMain)

GameView.build()
└─ GameWidget<BingoCardGame>.controlled(...)
   └─ gameFactory()
      └─ BingoCardGame(gameMode, safeAreaPadding)
         └─ BingoCardGame.onLoad()
            ├─ camera.viewfinder anchor = topLeft
            ├─ camera.backdrop.add(SpaceBg())
            ├─ camera.viewport.add(GameHud())
            ├─ _prepareGrid()
            │  ├─ shuffledFirst / shuffledSecond 생성
            │  ├─ world.add(GridBg)
            │  └─ world.add(CubeButton x 25)
            └─ overlays.add('Countdown')
```

### 2-2. 실제 역할 기준 해석

- `main.dart`
  - 앱 실행 전 필요한 전역 초기화를 담당한다.
- `app.dart`
  - `MaterialApp.router`, 테마, 다국어 설정을 담는 앱 루트다.
- `router.dart`
  - 어떤 경로가 어떤 화면을 여는지 정의한다.
- `title_view.dart`
  - 모드 선택과 설정 이동을 담당하는 첫 진입 화면이다.
- `game_view.dart`
  - Flame 게임을 Flutter 위젯 트리에 마운트하고 오버레이를 연결한다.
- `bingo_card_game.dart`
  - 실제 게임 루프, HUD/그리드 좌표 계산, 탭 판정, 진행 상태를 담당한다.

## 3. 파일별 역할 정리

### 3-1. `lib/main.dart`

앱의 진입점이다.

- Flutter 엔진 초기화
- 다국어 초기화
- 로컬 저장소 초기화
- 인앱 리뷰 기준일 저장
- 사운드 프리로드
- 화면 꺼짐 방지 설정 적용
- `App` 실행

즉, 게임 화면을 만드는 파일이 아니라 앱이 돌아갈 환경을 먼저 준비하는 파일이다.

### 3-2. `lib/app.dart`

`MaterialApp.router`를 생성하는 앱 루트다.

- 앱 제목 설정
- 디버그 배너 제거
- 다국어 delegate / locale 연결
- 기본 다크 테마 설정
- `appRouter` 주입
- 웹에서 첫 포인터 입력 시 `SoundManager.unlockForWeb()` 호출

### 3-3. `lib/router.dart`

라우팅 테이블이다.

- `/` -> `TitleView`
- `/game` -> `GameView`
- `/setting` -> `SettingView`

`/game`은 query parameter `mode`를 읽는다.

- `mode=0`
  - 숫자 모드
- `mode=1`
  - 알파벳 모드

즉 같은 게임 화면을 재사용하되, 모드만 바꾸는 구조다.

### 3-4. `lib/views/title_view.dart`

첫 진입 화면이다.

- 우주 배경 렌더링
- 타이틀 / 부제목 표시
- 숫자 모드 버튼
- 알파벳 모드 버튼
- 설정 버튼
- 하단 버전 텍스트 표시

버튼 동작:

- 숫자 모드
  - 효과음 재생
  - `context.go('/game?mode=0')`
- 알파벳 모드
  - 효과음 재생
  - `context.go('/game?mode=1')`
- 설정
  - 효과음 재생
  - `context.push('/setting')`

### 3-5. `lib/views/game_view.dart`

Flame을 Flutter에 연결하는 핵심 화면이다.

- `initState()`
  - 게임 BGM 재생 시작
- `build()`
  - `GameWidget<BingoCardGame>.controlled(...)` 생성
  - `gameFactory`로 `BingoCardGame` 인스턴스 생성
  - `overlayBuilderMap`으로 `Countdown`, `PauseMenu`, `Clear` 연결

또한 웹에서는 전체 화면에 게임을 직접 늘리지 않고:

- 세로형 기준 크기 `390×750`
- 최소/최대 스케일 범위 적용
- 중앙 정렬된 게임 프레임
- 남는 좌우는 우주 배경

구조로 처리한다.

### 3-6. `lib/game/bingo_card_game.dart`

실제 Flame 게임 클래스다.

- `FlameGame` 상속
- 탭 입력 처리
- 게임 진행 상태 관리
- 카운트다운 후 시작
- 1차 / 2차 셔플 테이블 생성
- 5×5 그리드 생성
- HUD 좌표 계산
- safe area 내부 기준 레이아웃 계산
- 힌트 표시
- 클리어 / 일시정지 처리

### 3-7. `lib/game/components/space_bg.dart`

배경 컴포넌트다.

- 우주 배경 그라데이션
- 별 위치 생성
- 별 반짝임 갱신
- 화면 전체 배경 렌더링

이 컴포넌트는 `camera.backdrop`에 올라간다.

### 3-8. `lib/game/components/game_hud.dart`

HUD 레이어다.

- 상단 타임 패널 렌더링
- 힌트 말풍선 렌더링
- 베스트 스코어 표시
- 일시정지 버튼 렌더링

이 컴포넌트는 `camera.viewport`에 올라간다.  
즉 화면에 고정된 UI 좌표계를 사용한다.

### 3-9. `lib/game/components/grid_bg.dart`

그리드 뒤의 반투명 배경판이다.

- 5×5 큐브 영역을 시각적으로 묶어준다.
- `world`에 올라간다.

### 3-10. `lib/game/components/cube_button.dart`

개별 큐브 컴포넌트다.

- 현재 id / label 보유
- 정답 시 회전 후 페이드아웃
- 오답 시 좌우 흔들림
- 힌트 시 깜박임
- 교체 큐브 페이드인

이 컴포넌트는 `world`에 올라간다.

### 3-11. 설정/사운드/저장소

- `game_settings.dart`
  - 설정값 getter / setter 제공
  - 베스트 스코어 저장
- `sound_manager.dart`
  - BGM / 효과음 / 웹 unlock 처리
- `storage_helper.dart`
  - `GetStorage` 래퍼

구조는 다음과 같다.

```text
UI / Game
└─ GameSettings
   └─ StorageHelper
      └─ GetStorage
```

## 4. 게임 규칙과 큐브 배치 방식

현재 게임은 "순서를 외워 누르는 반응속도 퍼즐"이다.  
기본 규칙은 단순하지만, 실제 큐브 교체 방식은 2단계 테이블 구조를 쓴다.

### 4-1. 게임 규칙

- 숫자 모드
  - `1`부터 `50`까지 순서대로 누른다.
- 알파벳 모드
  - `A`부터 `Z`까지 순서대로 누른다.
- 정답을 누르면
  - 큐브가 회전하며 사라진다.
  - 다음 목표 값으로 진행한다.
- 오답을 누르면
  - 큐브가 좌우로 흔들린다.
  - 진행 상태는 유지된다.
- 5초 동안 정답을 누르지 못하면
  - 현재 정답 큐브가 깜박여 힌트를 준다.
- 마지막 값을 누르면
  - 게임이 종료된다.
  - 결과 시간과 베스트 스코어를 보여준다.

즉 사용자는 "현재 힌트에 적힌 값"을 계속 찾아서 순서대로 제거해야 한다.

### 4-2. 1차 / 2차 테이블 개념

현재 게임은 전체 값을 한 번에 25칸에 다 올리지 않는다.

```text
숫자 모드
├─ 1차 테이블: 1 ~ 25
└─ 2차 테이블: 26 ~ 50

알파벳 모드
├─ 1차 테이블: A ~ Y (1 ~ 25에 대응)
└─ 2차 테이블: Z (26에 대응)
```

초기 화면에는 항상 1차 테이블만 25칸에 셔플되어 보인다.  
이후 정답을 맞출 때마다 같은 칸에 2차 테이블 값이 순서대로 보충된다.

### 4-3. 실제 배치 절차

그리드를 준비할 때 순서는 다음과 같다.

```text
_prepareGrid()
├─ currentNumber = 1
├─ 타이머 / 힌트 상태 초기화
├─ shuffledFirst = shuffle(1차 테이블)
├─ shuffledSecond = shuffle(2차 테이블)
└─ _createGrid()
   ├─ 5×5 칸 인덱스 0~24 순회
   ├─ 각 칸에 shuffledFirst[i]를 배치
   └─ CubeButton(gridIndex = i) 생성
```

즉 처음 25칸은 모두 1차 테이블 값이다.

```text
gridIndex 0  -> shuffledFirst[0]
gridIndex 1  -> shuffledFirst[1]
...
gridIndex 24 -> shuffledFirst[24]
```

### 4-4. 정답 큐브가 사라진 뒤 교체 방식

정답 큐브를 누르면 그 칸은 그냥 비워지는 것이 아니라, 2차 테이블이 남아 있으면 새 값이 채워진다.

```text
정답 탭
├─ cube.animateCorrect()
└─ onComplete
   ├─ if (_nextSecondIndex < shuffledSecond.length)
   │  ├─ nextId = shuffledSecond[_nextSecondIndex]
   │  ├─ _nextSecondIndex++
   │  └─ 같은 gridIndex 위치에 새 CubeButton 생성
   └─ else
      └─ 더 채울 값이 없으므로 빈 칸 유지
```

중요한 점은 다음과 같다.

- 2차 큐브는 "정답 순서"로 채워지는 것이 아니다.
- 2차 큐브도 별도 셔플된 순서로 공급된다.
- 다만 사용자가 눌러야 하는 목표 값 `currentNumber`는 항상 순차 증가한다.

즉 화면에 새로 등장하는 값의 위치와 등장 순서는 랜덤이지만,  
사용자가 눌러야 하는 값 자체는 항상 순서대로 정해져 있다.

### 4-5. 5×5 배치 수식

그리드는 safe area 안쪽에서 들어갈 수 있는 최대 정사각형 영역을 구한 뒤, 그 안에 5×5로 배치한다.

```text
layoutRef = min(안전영역 내부 가용 너비, 안전영역 내부 가용 높이)
cubeSize  = layoutRef / (5 + spacingRatio * 6)
spacing   = cubeSize * spacingRatio
step      = cubeSize + spacing
```

각 큐브의 좌표는 다음처럼 계산한다.

```text
row = gridIndex ~/ 5
col = gridIndex % 5

x = gridLeft + col * step + cubeSize / 2
y = gridTop  + spacing + row * step + cubeSize / 2
```

즉:

- 큐브 위치는 `gridIndex`만 알면 다시 계산할 수 있다.
- 창 크기가 바뀌어도 `gridIndex`를 기준으로 같은 칸 위치를 재계산한다.
- 그래서 리사이즈 시에도 "배치 순서"는 유지되고, 화면상의 크기와 좌표만 다시 맞춘다.

## 5. 게임 화면 진입 뒤 Flame 내부 생성 순서

`GameView`에서 `GameWidget.controlled`가 만들어진 다음, `gameFactory`가 `BingoCardGame`을 생성한다.  
그 뒤 Flame이 `BingoCardGame.onLoad()`를 호출한다.

`onLoad()`의 실제 순서는 다음과 같다.

```text
BingoCardGame.onLoad()
├─ _initLabels()
├─ camera.viewfinder.anchor = Anchor.topLeft
├─ camera.viewfinder.position = (0, 0)
├─ camera.backdrop.add(SpaceBg())
├─ _hud = GameHud()
├─ camera.viewport.add(_hud)
├─ _prepareGrid()
│  ├─ 상태 초기화
│  ├─ shuffledFirst / shuffledSecond 생성
│  └─ _createGrid()
│     ├─ world.add(GridBg)
│     └─ world.add(CubeButton x 25)
└─ overlays.add('Countdown')
```

해석하면:

1. 모드에 맞는 라벨 목록을 만든다.
2. 좌표계를 top-left 기준으로 고정한다.
3. 배경을 `backdrop`에 올린다.
4. HUD를 `viewport`에 올린다.
5. 그리드와 큐브를 `world`에 올린다.
6. 카운트다운 오버레이를 띄운다.

즉 현재 게임 구조는 다음과 같다.

```text
BingoCardGame
├─ camera.backdrop
│  └─ SpaceBg
├─ camera.viewport
│  └─ GameHud
│     └─ _PauseButton
└─ world
   ├─ GridBg
   └─ CubeButton x 25
```

## 6. 좌표계와 safe area 기준

현재 프로젝트는 좌표계를 3개 층으로 나눠서 본다.

```text
1) Flutter 화면 좌표
   - MediaQuery, SafeArea, Web LayoutBuilder가 사용하는 좌표

2) Flame 게임 레이아웃 좌표
   - camera.viewfinder를 topLeft로 맞춘 뒤
   - (0, 0) = 게임 프레임의 좌상단

3) HUD / Viewport 좌표
   - 화면에 고정된 UI 좌표
   - 타임 패널, 힌트, pause 버튼이 여기서 그려짐
```

템플릿과 다른 점은 다음과 같다.

- 현재는 `world 중심 원점`을 쓰지 않는다.
- `camera.viewfinder.anchor = Anchor.topLeft`로 맞춘다.
- 그래서 `world`와 `viewport` 모두 사실상 화면 상단 기준 좌표를 공유한다.
- 다만 의미상으로는 여전히 구분한다.
  - `world`
    - 게임 오브젝트
  - `viewport`
    - 화면 고정 UI

### 5-1. safe area를 어떻게 쓰는가

현재 프로젝트에서 safe area는 디버그 선을 그리기 위한 값이 아니다.  
오직 "게임 UI와 게임 오브젝트가 침범하지 않아야 하는 배치 기준"으로만 사용한다.

즉:

- 배경
  - safe area를 무시하고 전체 화면 사용
- 딤 배경
  - safe area를 무시하고 전체 화면 사용
- 실제 게임 요소
  - safe area 안쪽에만 배치

현재 레이아웃 기준은 다음과 같다.

```text
safeContentLeft   = safeArea.left + 화면가로의 3%
safeContentRight  = 화면너비 - safeArea.right - 화면가로의 3%
safeContentWidth  = safeContentRight - safeContentLeft
safeContentCenter = safeContentLeft + safeContentWidth / 2
```

상단 HUD와 그리드도 이 내부 영역을 기준으로 계산한다.

### 5-2. HUD와 그리드 배치 기준

상단 배치 기준:

```text
panelCenterY = safeArea.top + gap + panelHeight / 2
hintCenterY  = safeArea.top + 2*gap + panelHeight + hintRadius
gridTopY     = safeArea.top + gap + panelHeight + gap + hintRowHeight + gap
```

그리드 크기 기준:

```text
availW  = safeContentWidth
maxGridH = 화면높이 - safeArea.bottom - gridTopY - gap
layoutRef = min(availW, maxGridH)
```

즉 현재 기준은:

- 상단 HUD는 safe area 아래에 둔다.
- 좌우 버튼과 힌트는 safe area 안쪽에 둔다.
- 그리드는 safe area 안쪽 직사각형에 들어가는 최대 정사각형으로 계산한다.

## 7. 게임 진행 흐름

### 6-1. 카운트다운

```text
GameView overlay 'Countdown'
└─ _CountdownOverlay
   ├─ 500ms 대기
   ├─ 3 -> TimeTic
   ├─ 2 -> TimeTic
   ├─ 1 -> TimeTic
   ├─ Start -> Start 효과음
   └─ game.startGame()
```

`startGame()`이 호출되기 전까지는 `isPlaying = false`라서 입력이 진행되지 않는다.

### 6-2. 플레이 중 매 프레임

```text
BingoCardGame.update(dt)
├─ isPlaying 검사
├─ _elapsedTime += dt
├─ _hud.updateTime(_elapsedTime)
├─ _hintTimer += dt
└─ if (_hintTimer >= 5초)
   └─ _showHint()
```

즉 타이머와 힌트는 `update(dt)`에서 관리된다.

### 6-3. 큐브 탭 처리

```text
CubeButton.onTapDown()
└─ onTap(this)
   └─ BingoCardGame._onCubeTap(cube)
      ├─ 정답 검사
      ├─ 정답이면
      │  ├─ Collect 효과음
      │  ├─ currentNumber 증가
      │  ├─ HUD 힌트 갱신
      │  ├─ cube.animateCorrect()
      │  └─ 필요 시 새 CubeButton 생성
      └─ 오답이면
         ├─ Fail 효과음
         └─ cube.animateWrong()
```

## 8. 일시정지 / 클리어 흐름

### 7-1. 일시정지

```text
Pause 버튼 탭
└─ BingoCardGame.pauseGame()
   ├─ isPlaying = false
   ├─ SoundManager.pauseBgm()
   ├─ pauseEngine()
   └─ overlays.add('PauseMenu')
```

재개 흐름:

```text
PauseMenu의 "계속하기"
├─ SoundManager.resumeBgm()
├─ game.resumeEngine()
├─ overlays.remove('PauseMenu')
└─ game.isPlaying = true
```

### 7-2. 게임 클리어

```text
마지막 정답 큐브 탭
└─ _onCubeTap()
   ├─ isPlaying = false
   ├─ GameSettings.saveBestScoreIfBetter()
   ├─ cube.animateCorrect()
   ├─ Clear 효과음
   └─ overlays.add('Clear')
```

클리어 오버레이에서는:

- 결과 시간 표시
- 베스트 스코어 표시
- 다시하기
- 나가기

를 제공한다.

## 9. 웹 레이아웃 정책

웹에서는 게임이 전체 브라우저에 맞춰 자유롭게 늘어나지 않는다.  
현재 정책은 "세로형 모바일 게임 프레임"을 중앙에 유지하는 것이다.

```text
브라우저 전체
├─ 바깥 배경 = StarryBackground()
└─ 중앙 게임 프레임
   ├─ 기준 크기 = 390 x 750
   ├─ fittedScale = min(가로비, 세로비)
   ├─ 최소 스케일 = 0.83
   ├─ 최대 스케일 = 1.5
   └─ SizedBox(width: 390*scale, height: 750*scale)
```

의미는 다음과 같다.

- 큰 화면
  - 게임 프레임은 최대 스케일까지 커진다.
- 작은 화면
  - 프레임이 전체적으로 줄어든다.
- 남는 좌우 영역
  - 우주 배경만 확장된다.

즉 웹에서도 "세로형 모바일 게임처럼 보이는 느낌"을 유지하려는 구조다.

## 10. 화면별 요약

### 9-1. TitleView

- 전체 화면 우주 배경
- SafeArea 안에 제목/버튼/버전 텍스트 배치
- 메뉴 BGM 재생

### 9-2. SettingView

- `AppBar`
- SafeArea 안의 스크롤 설정 목록
- BGM / SFX / 화면 꺼짐 방지 / 언어 설정

### 9-3. GameView

- 앱에서는 전체 화면 게임
- 웹에서는 중앙 세로 프레임 게임
- 오버레이:
  - Countdown
  - PauseMenu
  - Clear

## 11. 정리

현재 프로젝트의 핵심은 다음 세 가지다.

1. 앱 셸 구조는 Flutter 표준 방식 유지
   - `main -> App -> Router -> View`
2. 게임 내부는 Flame 레이어를 명확히 분리
   - `backdrop / viewport / world`
3. 좌표계는 top-left 기반 화면형 레이아웃으로 단순화
   - safe area는 침범 금지 기준으로만 사용

즉 이 프로젝트는 템플릿과 같은 출발점에서 왔지만, 현재는 다음에 더 가깝다.

```text
모바일 세로형 퍼즐 게임
+ Flutter 라우팅 셸
+ Flame 기반 렌더링
+ backdrop/world/HUD 분리
+ safe area 기반 배치
+ 웹에서는 중앙 세로 프레임 유지
```

다음에 구조를 더 발전시킬 때도 아래 원칙을 유지하면 파악이 쉽다.

- 배경은 `backdrop`
- 게임 오브젝트는 `world`
- 화면 고정 UI는 `viewport`
- 오버레이 팝업은 Flutter overlay
- safe area는 "게임 요소 배치 기준"으로만 사용
