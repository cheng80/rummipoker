# Riverpod 상태 구조

> 목표: **UI(Flutter) · 게임(Flame) · 순수 로직** 경계를 유지하면서, 세션·설정·비동기 흐름을 한곳에서 추적한다.

---

## 정책 (코드젠 없음)

- **`riverpod_annotation` / `build_runner` 기반 코드젠은 도입하지 않는다.**
- 프로바이더는 **`Notifier` + `NotifierProvider` (또는 `Provider` 등)를 수동 선언**한다.
- 이유: 빌드 단계 단순화, 초급 기여자가 생성물 없이 흐름을 읽기 쉽게 유지.

---

## 1. 계층

```
┌─────────────────────────────────────────────────────────┐
│  Widget (TitleView, GameView, SettingView)              │
│  ConsumerWidget / ConsumerStatefulWidget / ref.watch      │
└─────────────────────────┬───────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────┐
│  Notifier / AsyncNotifier (providers/features/...)       │
│  - 세션 단계, 점수, 턴 요약 (UI가 필요로 하는 스냅샷)      │
└─────────────────────────┬───────────────────────────────┘
                          │  메서드 호출 / 상태 동기화
┌─────────────────────────▼───────────────────────────────┐
│  logic/ (추가 예정)                                       │
│  - 덱, 보드, 핸드 판정 — Flutter·Flame 의존성 없음        │
└───────────────────────────────────────────────────────────┘
```

- **Flame**: `FlameGame`은 `WidgetRef`를 직접 갖지 않는다. 패턴은 아래 중 하나.
  - **오버레이**에서 `Consumer`로 `ref.watch` 후 `game`에 콜백 전달
  - **`gameRef` 패턴**: `GameView`에서 `ref.read(sessionProvider.notifier)`를 클로저로 게임에 주입
  - **`ProviderContainer`**를 `GameView`에서 `ProviderScope.containerOf(context)`로 얻어 필요 시 전달 (드물게)

---

## 2. 폴더 규칙 (`lib/providers/`)

| 경로 | 역할 |
|------|------|
| `providers/features/<기능명>/` | 해당 기능 전용 `Notifier` + `State` |
| `providers/providers.dart` | export barrel (선택적) |

- **앱 전역 설정**(볼륨 등)은 기존 `GameSettings` + GetStorage를 유지할 수 있고, 필요 시 **`settingsNotifierProvider`**로 감싸 점진적 이전 가능.
- **GoRouter**와 Riverpod: `go_router`는 `ref` 없이 동작하므로, 네비게이션은 `context.go` 유지 + 상태는 `Notifier`에서 관리.

---

## 3. 명명

- `*Notifier` + `*State` + `*NotifierProvider` (Riverpod 2.x `Notifier` API)
- 프로바이더 이름: `xxxNotifierProvider` — `ref.watch(xxxNotifierProvider)` / `ref.read(xxxNotifierProvider.notifier)`

---

## 4. 테스트

- `ProviderScope`로 감싼 위젯 테스트 또는 `ProviderContainer` 단위 테스트로 `Notifier` 검증.
- 예: `test/rummi_session_notifier_test.dart`

---

## 5. 참고

- 공식: [Riverpod](https://riverpod.dev/)
- 세션 재개/작업 인덱스: `START_HERE.md`
