# Rummi Poker Grid (`rummipoker`)

**루미 포커 그리드** 전환을 진행 중인 Flutter 앱입니다. 레거시 탭탭 게임은 제거되었고, `lib/logic/rummi_poker_grid/` 엔진과 `lib/game/rummi_poker_grid/` Flame 플레이·타이틀(시드)이 연결되어 있습니다.

## 기술 스택

- **Flutter** — UI
- **Flame** — 이후 `lib/game/rummi_poker_grid/` 등에서 사용 예정
- **GoRouter** — 라우팅 (`/game?seed=`)
- **easy_localization** — 현재 `ko`만 (`assets/translations/ko.json`)
- **flame_audio** — BGM·SFX
- **get_storage** — 설정
- **Riverpod** — 세션 등

## 앱 구조 (요약)

```
lib/
├── main.dart, app.dart, router.dart, app_config.dart
├── logic/rummi_poker_grid/   # 타일·보드·덱·세션 (Flame 무관)
├── views/                    # title_view, game_view(플레이스홀더), setting_view
├── resources/, services/, utils/, widgets/, providers/
```

| 경로 | 설명 |
|------|------|
| `/` | 타이틀 — 랜덤 시드 / 시드 입력 후 게임 진입 |
| `/game?seed=` | 시드 표시 + 준비 중 UI |
| `/setting` | 볼륨·화면 설정 |

## 문서

- [`docs/rummi_poker_grid_execution_checklist.md`](docs/rummi_poker_grid_execution_checklist.md) — 실행 체크리스트
- [`docs/rummi_poker_grid_gdd.md`](docs/rummi_poker_grid_gdd.md) — GDD
- [`START_HERE.md`](START_HERE.md) — 현재 상태 / 다음 작업 진입점
- [`docs/rummi_poker_grid_game_logic.md`](docs/rummi_poker_grid_game_logic.md) — 구현 스펙
- [`docs/DESIGN.md`](docs/DESIGN.md) — UI/레이아웃 기준
- [`docs/web_build.md`](docs/web_build.md) — Web 빌드

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
