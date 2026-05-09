# Tutorial Coach Mark Plan

## 결론

`tutorial_coach_mark`는 전투 첫 진입 설명과 마켓 첫 진입 설명에 사용한다. Rummi Poker의 핵심 재미를 해치지 않도록 정답 후보나 추천 빌드를 알려주지 않고, 화면 영역과 조작 흐름만 짧게 안내한다.

이전 후보였던 `showcaseview`는 `PhoneFrame`의 `FittedBox`, 웹 창 크기 변경, dialog z-order와 맞지 않아 제거했다. 현재 구현은 `tutorial_coach_mark`의 skip/finish 제어와 명시 target을 사용한다.

현재 구현 상태:

- 전투 첫 진입 튜토리얼: 구현됨. 보드, 점수 미리보기, 전투 액션, 손패/드로우를 순서대로 안내한다.
- 전투 다시 보기: 구현됨. 일시정지/옵션 dialog의 `튜토리얼 다시 보기`에서 실행한다.
- 마켓 첫 진입 튜토리얼: 구현됨. 보유 슬롯, 상세/구매 패널, lane/리롤, offer 영역을 순서대로 안내한다.
- 마켓 다시 보기: 구현됨. 상점 상단 우측 `?` 버튼에서 실행한다.
- 반복 방지 저장 키: 구현됨. `tutorial_battle_intro_seen`, `tutorial_market_intro_seen`를 사용한다. 단, 자동 튜토리얼을 끝까지 완료한 경우에만 seen을 저장하고, 스킵/포커스 아웃/옵션 진입 등으로 중단되면 다음 진입 때 다시 표시한다.
- 정산, 게임오버, 런 정보, 도감 튜토리얼: 이번 범위에서 제외한다.

## 목표

- 첫 플레이어가 전투와 마켓의 기본 조작 흐름을 이해한다.
- 전략 정답이나 추천 빌드를 직접 알려주지 않는다.
- 튜토리얼은 다시 볼 수 있어야 한다.
- 진행 상태는 저장되어 같은 안내가 반복되지 않게 한다.
- 정산, 게임오버, 런 정보, 도감은 별도 튜토리얼로 설명하지 않고 플레이 중 자연스럽게 발견하게 둔다.

## 1차 튜토리얼 범위

### 전투

- 손패 타일
- 보드 칸
- 라인 preview
- 확정 버튼
- 드로우
- 보드 이동/버림 자원

다시 보기 진입점:

- 전투 화면에 상시 노출 버튼을 추가하지 않는다.
- 일시정지/옵션 dialog 안에 `튜토리얼 다시 보기` 버튼을 둔다.
- 설정, 나가기, 재시작 같은 위험 액션보다 위쪽에 배치한다.

### 마켓

- Jester offer
- Item offer lane
- 슬롯 장착
- 판매
- 리롤
- 무료/할인 조건 표시

다시 보기 진입점:

- 상점 상단 우측에 작은 `?` 아이콘 버튼을 둔다.
- 리롤 버튼 근처에는 두지 않는다.
- tooltip/semantics 라벨은 `상점 튜토리얼 다시 보기`로 둔다.
- 텍스트 버튼보다 아이콘 버튼을 우선한다.

### 범위 제외

- 정산
- 게임오버
- 런 정보
- 도감/수집 화면
- 메인 화면 성장 진입점

위 항목은 전투와 마켓을 한 번 지나면 유저가 자연스럽게 눌러보고 이해할 수 있는 영역으로 둔다. 이후 실제 QA에서 반복적으로 놓치는 항목이 확인될 때만 별도 안내 추가를 검토한다.

## 구현 원칙

- route 전환 중에는 tutorial overlay를 시작하지 않는다.
- dialog, bottom sheet, navigation transition과 겹치지 않게 한다.
- 옵션 dialog나 앱 포커스 변경으로 일시정지/옵션이 뜨기 전에는 실행 중인 tutorial overlay를 먼저 닫는다.
- FittedBox, canvas, Flame overlay 위젯에서 target 위치가 흔들리지 않는지 Browser/기기 눈검증을 한다.
- 전투 중 tutorial step은 플레이 입력을 막는 시간과 허용하는 시간을 분리한다.
- `TextOverflow.ellipsis`로 설명을 숨기지 않는다.
- 튜토리얼 문구는 한국어/영어 키 기준으로 관리한다.
- 튜토리얼 card 색상은 게임 배경 녹색과 분리되는 중간 톤 보라/흑청 계열과 금색 테두리로 둔다.
- 마켓처럼 `AnimatedSwitcher`가 같은 target을 동시에 그릴 수 있는 영역은 실제 위젯을 직접 target으로 감싸지 않고, 별도 anchor layer에 target key를 둔다.

## 저장 상태

저장 키:

- `tutorial_battle_intro_seen`
- `tutorial_market_intro_seen`

## 검증

- [x] `flutter analyze`
- [x] 핵심 위젯 테스트: title, settings, options dialog, shop, shop reroll confirmation
- [x] `flutter build web`
- [ ] 첫 실행에서 필요한 안내가 뜨는지 Browser/기기 눈검증
- [ ] 이미 본 안내가 반복되지 않는지 Browser/기기 눈검증
- [ ] 다시 보기 버튼에서 재실행되는지 Browser/기기 눈검증
- [ ] 작은 iPhone 세로 화면에서 문구가 잘리지 않는지 기기 눈검증
- [ ] iPad에서 target 위치가 맞는지 기기 눈검증
