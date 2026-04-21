# Rummi Poker Grid (`rummipoker`)

**루미 포커 그리드** 전환을 진행 중인 Flutter 앱입니다. 레거시 탭탭 게임은 제거되었고, `lib/logic/rummi_poker_grid/` 엔진과 Flutter 화면 기반의 현재 플레이 루프가 연결되어 있습니다.

현재 진행 상태와 다음 작업 기준은 [`START_HERE.md`](START_HERE.md)를 우선해서 봅니다.

## 기술 스택

- **Flutter** — UI
- **Flame** — 렌더링/오디오 등 게임 기능 기반
- **GoRouter** — 라우팅
- **easy_localization** — 다국어 리소스
- **flame_audio** — BGM·SFX
- **shared_preferences** — 설정·active run 저장
- **Riverpod** — 세션 등

## 앱 구조 (요약)

```
lib/
├── main.dart, app.dart, router.dart, app_config.dart
├── logic/rummi_poker_grid/   # 타일·보드·덱·세션 (Flame 무관)
├── views/                    # home/title, new-run, blind-select, game, market/archive/settings UI
├── resources/, services/, utils/, widgets/, providers/
```

| 경로 | 설명 |
|------|------|
| `/` | Home/Title — 이어하기, 새 시작, 특별 모드, 기록실, 설정 진입 |
| `/new-run` | 새 게임 시작 설정 |
| `/blind-select` | 블라인드 선택 |
| `/game` | 전투/정산/Market 런타임 |
| `/setting` | 볼륨·화면 설정 |
| `/trial` | 특별 모드 placeholder |
| `/archive` | 기록실 shell |

## 문서

- [`START_HERE.md`](START_HERE.md) — 현재 상태 / 다음 작업 진입점
- [`docs/V4/V4_REVIEW_CHECKLIST.md`](docs/V4/V4_REVIEW_CHECKLIST.md) — V4 진행 상태 source of truth
- [`docs/V4/V4_IMPLEMENTATION_PLAN.md`](docs/V4/V4_IMPLEMENTATION_PLAN.md) — V4 구현 계획
- [`docs/current_system/CURRENT_SYSTEM_OVERVIEW.md`](docs/current_system/CURRENT_SYSTEM_OVERVIEW.md) — 현재 시스템 요약
- [`docs/web_build.md`](docs/web_build.md) — Web 빌드

`docs/archive/` 문서는 레거시 참고 자료이며, 현재 기준과 충돌하면 `START_HERE.md`, `docs/V4/*`, `docs/current_system/*`, 실제 `lib/` 코드를 우선합니다.

## 실행

```bash
flutter run
```

웹: `flutter run -d chrome`

## 빌드

| 플랫폼 | 명령어 |
|--------|--------|
| Android/iOS | `flutter build apk` / `flutter build ios` |
| Web | `flutter build web --release --base-href "/rummipoker/"` |

→ 상세: [`docs/web_build.md`](docs/web_build.md)
