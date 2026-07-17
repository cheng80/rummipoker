# Web 빌드 안내

## 이 문서의 목적

출시 후보를 만들거나 Browser QA를 할 때 필요한 Web 빌드 절차다. Web만 작업할 때는 이 문서 하나를 순서대로 따라간다.

## 빌드 전에 준비할 것

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
- full-play 증거는 fixture 없이 `풀런봇`(`full_run_bot`)으로 남긴다.

## 고정 포트 Chrome 눈검증

매번 Chrome 실행 포트가 바뀌면 같은 URL로 fixture를 다시 열기 어렵다.
개발 서버 눈검증은 포트를 고정한다.

```bash
flutter run -d web-server --web-port=7357 --dart-define=SHOW_DEBUG_FIXTURES=true
```

기존 Chrome 탭에서 아래 주소를 연다.

```text
http://localhost:7357
```

Chrome을 Flutter가 직접 열어도 되는 경우에는 아래처럼 실행한다.

```bash
flutter run -d chrome --web-port=7357 --dart-define=SHOW_DEBUG_FIXTURES=true
```

터미널에서 `flutter run`으로 띄우면 앱은 debug mode지만 IDE의 Pause/Run/Stop 디버그 패널은 뜨지 않는다.
터미널에서는 `r` hot reload, `R` hot restart, `q` quit로 제어한다.

VS Code의 디버그 패널까지 필요하면 `.vscode/launch.json`에 고정 포트 실행 구성을 추가한다.

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "RummiPoker Chrome Debug Fixtures",
      "request": "launch",
      "type": "dart",
      "deviceId": "chrome",
      "toolArgs": [
        "--web-port=7357",
        "--dart-define=SHOW_DEBUG_FIXTURES=true"
      ]
    }
  ]
}
```

이 구성으로 VS Code Run and Debug에서 실행하면 포트 `7357`, debug fixture, IDE 디버그 패널을 함께 쓴다.

주의:

- `--web-port` 값은 진행 중인 다른 테스트와 겹치지 않게 정한다.
- debug fixture 눈검증은 QA/재현용이며, 제출 full-play evidence로 쓰지 않는다.
- 테스트 종료 뒤 Flutter web-server와 Chrome/Chrome Helper 잔류 프로세스를 확인한다.

## 릴리즈 산출물 로컬 확인

`flutter build web` 산출물은 자체 포트가 없다. 어느 서버로 서빙하는지가 포트를 정한다.
`/rummipoker/` base-href 산출물을 로컬에서 확인할 때는 repo root에서 아래처럼 고정 포트로 연다.

```bash
python3 -m http.server 7358 -d .
```

그 다음 브라우저에서 아래 주소를 연다.

```text
http://localhost:7358/rummipoker/
```

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

## full-play 기준

- 사람 수동 플레이가 아니라 `풀런봇`(`full_run_bot`) 기준으로 닫는다.
- Debug fixture, 즉시 클리어, forced reward는 full-play evidence가 아니다.
- 로그에는 fresh run인지 checkpoint resume인지 명확히 남긴다.
