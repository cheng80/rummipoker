# Rummi Poker Grid — 마이그레이션·구조 플랜

> 목표: **Flame 뷰 위주**로 새 게임을 붙이되, 앱 골격·공용 서비스는 재사용하고, 기존 “순서 탭” 게임은 **코드베이스에서 분리·보존** 전략을 명확히 한다.

---

## 1. 원칙 (효율 우선)

1. **앱 = 셸**, **게임 = 플러그인**: `main` / `app` / `router` / 다국어 / 저장소 / 사운드는 유지, 게임만 교체 가능하게 경계를 둔다.
2. **상태: Riverpod**: 세션·게임 단계·점수 요약 등은 `lib/providers/features/`의 `Notifier`로 관리한다. **코드젠 없음**(`riverpod_annotation` 미사용). 상세는 `docs/riverpod_architecture.md`.
3. **Flame**: 보드·타일·라인·입력은 `FlameGame` + `Component`. Flutter는 라우트·설정·모달 오버레이 위주.
4. **기존 `BingoCardGame` 코드**: 당장 삭제하지 않고 **네임스페이스(폴더)로 격리** 후, 라우트에서 새 게임으로 전환한다 (롤백·비교 용이).

---

## 2. 보존할 것 (Preserve)

| 영역 | 경로·요소 | 이유 |
|------|-----------|------|
| 진입·라우팅 | `lib/main.dart`, `lib/app.dart`, `lib/router.dart` | GoRouter 패턴 유지 |
| 설정·저장 | `lib/services/game_settings.dart`, `lib/utils/storage_helper.dart`, `StorageKeys` | 볼륨·음소거 등 공통 |
| 사운드 | `lib/resources/sound_manager.dart`, `asset_paths.dart` (경로만 확장) | BGM/SFX 파이프라인 재사용 |
| 인앱 리뷰 | `lib/services/in_app_review_service.dart` | 트리거만 새 게임 이벤트에 연결 |
| 로케일 헬퍼 | `lib/utils/app_locale.dart` | 다국어 구조 유지 |
| Flutter 화면 | `lib/views/setting_view.dart` | 설정 UI 그대로 |
| 에셋 선언 | `pubspec.yaml` `flutter.assets` | 타일·사운드 경로 추가만 |
| 플랫폼 설정 | `android/`, `ios/`, `web/` 등 번들·빌드 | 앱 ID는 이미 `binggocard` 기준 |

**조건부 보존**

| 영역 | 조건 |
|------|------|
| `lib/views/title_view.dart` | 메뉴 카피·모드 선택이 새 게임과 다르면 **UI만 개편**, 라우팅 패턴은 유지 |
| `lib/views/game_view.dart` | **패턴**(GameWidget + overlays)은 보존, 내부는 `BingoCardGame` → 새 `FlameGame`으로 교체하거나 **별도 `RummiGameView`** 로 분리 |

---

## 3. 전환·교체할 것 (Transition)

| 현재 | 전환 방향 |
|------|-----------|
| `lib/game/bingo_card_game.dart` 및 `game/components/*` (큐브·기존 HUD) | **Rummi Poker Grid 전용** `FlameGame` + 컴포넌트로 대체. 기존 파일은 `lib/game/legacy_taptap/` 등으로 이동하거나 브랜치 보관 (아래 폴더안 참고) |
| `GameView`의 `GameWidget<BingoCardGame>` | `GameWidget<새FlameGame>` 또는 전용 뷰 |
| `app_config.dart` 문구·타이틀 | 앱 스토어/타이틀을 새 게임에 맞게 수정 (기능 키 구조는 유지) |
| `docs/game_flow.md`, `code-flow-analysis.md` | **구 게임 기준** 문서 → 새 게임은 `rummi_poker_grid_*` 문서가 소스 오브 트루스. 구 문서는 “Legacy” 표기 또는 링크만 |

---

## 4. 권장 폴더 구조 (신규 위주)

기존 파일을 한 번에 옮기지 않고, **새 코드만 아래에 추가**한 뒤 라우트를 바꾸는 방식이 충돌이 적다.

```text
lib/
├── main.dart, app.dart, router.dart, app_config.dart   # 셸 (수정 최소)
├── logic/
│   └── rummi_poker_grid/     # 순수 Dart: 덱, 핸드 판정, 점수, 턴 상태 (Flame 무관)
│       ├── models/           # Tile, BoardState, LineId, HandRank …
│       └── rummi_poker_grid_engine.dart  # (선택) 퍼사드
├── game/
│   ├── rummi_poker_grid/     # Flame 전용
│   │   ├── rummi_poker_grid_game.dart    # FlameGame
│   │   └── components/       # 타일, 보드, 라인 하이라이트, 웨이스트 슬롯 …
│   └── legacy_taptap/        # (선택) 기존 BingoCardGame 일괄 이동 시
│       └── ...
├── views/
│   ├── game_view.dart        # 공통 래퍼 또는 legacy 진입
│   └── rummi_game_view.dart  # (선택) 새 게임 전용 뷰
└── resources/, services/, utils/  # 위 Preserve와 동일
```

- **`logic/`**: 단위 테스트하기 쉬움 (GDD의 핸드·점수·버림 규칙).
- **`game/rummi_poker_grid/`**: 렌더링·터치·오버레이 이름만 Flame에 종속.

---

## 5. 단계별 플랜

| 단계 | 내용 | 산출물 |
|------|------|--------|
| **0** | GDD 확정 (라인 정의, Straight 색 규칙, 죽은 줄 vs 방치 패널티 중복 여부) | GDD 패치 |
| **1** | `logic/rummi_poker_grid`: 타일·보드 5×5·덱·웨이스트·턴 상태 + **핸드 판정 단위 테스트** | 테스트 통과 |
| **2** | `game/rummi_poker_grid`: 빈 보드 + 타일 컴포넌트 + 터치 한 줄 (Flame) | 화면 프로토타입 |
| **3** | 버림·슬롯 보충·라인 클릭 제거·점수 HUD | GDD 3~5장 구현 |
| **4** | 조커·유지 보너스·방치 패널티 (GDD 6~7) | 밸런스 튜닝 |
| **5** | `TitleView`·`app_config`·번역·스토어 문구 정리 | 출시 준비 |

---

## 6. 문서 역할 분리

| 문서 | 역할 |
|------|------|
| `docs/rummi_poker_grid_gdd.md` | 기획·UX·철학 (단일 진실 원천) |
| `docs/rummi_poker_grid_game_logic.md` | **구현용** 규칙·상태·판정 (엔진 스펙) |
| `docs/riverpod_architecture.md` | Riverpod 계층·Flame 연동 패턴 |
| 본 문서 (`…migration_plan.md`) | 보존/전환·폴더·단계 |

---

## 7. 리스크·메모

- **두 게임 병행**: `RoutePaths.game` 쿼리로 `mode=legacy` vs `rummi` 분기 가능하나, 유지 비용 증가. 초기에는 **한 게임만** 라우트에 연결하는 편이 효율적이다.
- **에셋**: 루미 타일 비주얼은 스프라이트 또는 `Canvas` 도형; 기존 Flutter `BattleTileCard`는 **레이아웃·색 참고** 후 Flame `render`로 이식.
