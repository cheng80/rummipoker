# Web Build Guide

## 목적

공모전 제출 후보와 Browser QA를 위한 Web 빌드 절차다. Web 제출이나 QA만 진행할 때는 이 문서 하나만 보면 된다.

## 공통 준비

```bash
flutter pub get
flutter analyze
```

핵심 회귀 테스트는 변경 범위에 맞춰 실행한다. 제출 직전에는 title/new run, 전투, 마켓, 정산, bot policy 관련 테스트를 우선 포함한다.

## 일반 제출 후보 빌드

```bash
flutter build web --build-name=<버전명> --build-number=<빌드번호>
```

버전 override가 필요 없으면 기본값을 사용해도 된다.

```bash
flutter build web
```

출력:

```text
build/web
```

## QA용 Debug fixture 포함 빌드

```bash
flutter build web --dart-define=SHOW_DEBUG_FIXTURES=true --build-name=<버전명> --build-number=<빌드번호>
```

주의:

- 일반 release 빌드에는 Debug fixture 진입점이 보이면 안 된다.
- QA fixture는 눈검증과 버그 재현용이다.
- 공모전 full-play 증거는 fixture 없이 `contest_full_run_bot`으로 남긴다.

## Browser QA

Web 빌드 후 로컬 서버로 열어 다음을 확인한다.

- title 화면 로고, 서브타이틀, 버전 footer
- 새 run, 난이도 선택, 표준/도전 구분
- 전투 화면 HUD와 런 정보
- 마켓 구매/판매/리롤
- 보상과 정산
- 게임오버 정산
- 무한 도전 진입 표시
- 일반 release에서 Debug fixture 숨김
- QA 빌드에서 Debug fixture 노출
- console error/warn 0건

## 공모전 full-play 기준

- 사람 수동 플레이가 아니라 `contest_full_run_bot` 기준으로 닫는다.
- Debug fixture, 즉시 클리어, forced reward는 full-play evidence가 아니다.
- 로그에는 fresh run인지 checkpoint resume인지 명확히 남긴다.
