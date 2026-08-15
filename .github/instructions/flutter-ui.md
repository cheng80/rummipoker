---
description: Flutter 화면, 상호작용, 연출, 다국어, 오디오 작업 규칙
globs: ["lib/views/**/*.dart", "lib/widgets/**/*.dart", "lib/game/**/*.dart", "lib/providers/**/*.dart", "lib/app.dart", "lib/router.dart", "lib/resources/**/*.dart", "lib/services/tutorial*.dart", "lib/services/game_settings.dart", "lib/utils/common_ui.dart", "test/views/**/*.dart", "test/widgets/**/*.dart", "test/providers/**/*.dart", "test/services/tutorial*.dart", "assets/translations/**/*", "assets/images/**/*", "assets/audio/**/*", "web/**/*", "ios/**/*", "android/**/*", "macos/**/*", "linux/**/*", "windows/**/*", "pubspec.yaml"]
alwaysApply: false
---

# Flutter UI 규칙

## 정본과 구조

- 수정 전에 `docs/core/UI_UX.md`, `docs/core/SYSTEM_ARCHITECTURE.md`, `docs/planning/verification/TEST_QA_ACCEPTANCE.md`의 관련 절을 확인한다. 화면별 수치와 상태 위계는 이 문서나 코드·테스트를 다시 적지 않는다.
- View에는 표시와 입력 조정만 두고 게임 규칙·저장·카탈로그 상태는 `logic`, `providers`, `services`가 소유한다. Riverpod은 수동 `Notifier`/`Provider`를 유지하고 코드젠을 추가하지 않는다.
- 공용 helper는 책임이 맞는 파일에 둔다. 한 화면만 위한 예외나 카드별 px 보정으로 공용 레이아웃 문제를 덮지 않는다.

## 레이아웃과 표현

- 모든 플레이 화면, dialog, notice, toast는 `PhoneFrameScaffold`, SafeArea, 논리 프레임 안에 남아야 한다. 폰 세로 화면을 기준으로 하고 넓은 화면은 여백만 확장한다.
- 플레이어가 읽어야 하는 이름·설명·라벨을 `ellipsis`나 `clip`으로 숨기지 않는다. 공간, 단어 단위 줄바꿈, 상세 영역, 작은 화면용 scroll 순으로 해결한다. 짧은 HUD 값만 `FittedBox.scaleDown`을 허용한다.
- 선택, 점수, 약화, 보상 색은 의미 기반 공용 palette를 쓴다. 선택은 주황, 보스 약화는 빨강, 족보·보상은 금색 계열로 구분하고 색 하나만으로 의미를 전달하지 않는다.
- 카드 face, 빈/잠긴 slot, 상세/사용 overlay는 같은 골격과 이미지 safe zone을 쓴다. parent와 child가 선택 테두리를 중복해서 그리지 않으며 이미지 오류를 빈 박스로 숨기지 않는다.
- 타일 숫자, 특수 modifier badge, 보스 제약 `X`, 선택·확정 표시는 서로 다른 영역과 layer를 사용한다. 작은 타일과 큰 타일은 공용 metrics를 쓰고 정지 화면과 연출 중간을 모두 확인한다.

## Overlay, tutorial, lifecycle

- 위계는 `content < tutorial < pause veil/modal`이다. options, focus-out, route 전환 전에 tutorial을 제거한다.
- `showDialog`, `showModalBottomSheet`, 키보드처럼 UI overlay가 닫힌 직후 route를 전환할 때는 `WidgetsBinding.instance.endOfFrame`을 기다리고 `mounted`를 다시 확인한다. 고정 `Future.delayed`로 프레임 차이를 보정하지 않으며, overlay 없는 단순 전환에는 이 대기를 추가하지 않는다.
- 자동 tutorial은 해당 scene과 layout이 안정된 뒤 시작한다. 수동 다시보기는 즉시 시작할 수 있고 Battle·Market 모두 상단 버튼과 options에서 접근한다.
- 사용자 Skip은 seen 처리한다. focus-out, options, route 전환, dispose 같은 강제 종료는 seen 처리하지 않고 다음 진입 때 첫 step부터 다시 시작한다. resize 보정만 현재 step 유지가 가능하다.
- modal 입력 차단은 공용 barrier 한 장으로 처리한다. lifecycle 변화만으로 options를 자동으로 열지 않으며 진행 중 정산·전환 연출의 resume을 우선한다.

## 피드백과 오디오

- Item/Jester/Ritual 효과는 `source → target → result`가 보이게 presentation event와 피드백을 함께 설계한다. 지연·동시 발동은 아이템명, 효과, 소모 여부를 읽을 수 있는 요약으로 표시한다.
- 웹 autoplay 대응은 `SoundManager` 안에 제한한다. 실제 사용자 gesture에서 unlock/resume을 재시도하고 같은 BGM을 스크롤마다 재시작하지 않는다. 짧은 `inactive`는 debounce 후 공통 pause로 처리한다.

## 검증

- 상태·입력은 widget test, 실제 모양은 최신 build의 Chrome/Simulator screenshot 또는 video로 확인한다. UI 변경 뒤 `build/web`이나 `--skip-build` 캡처를 재사용하지 않는다.
- overflow, 잘림, 겹침, frame 밖 누수, 읽을 수 없는 문구는 기능이 동작해도 실패다. 실제 화면 잔존 문제는 단위 테스트만으로 닫지 않고 재현 fixture나 저장 상태로 눈검증한다.
- 테스트 입력은 표시 텍스트 대신 안정된 key, content id, slot index를 사용한다.
