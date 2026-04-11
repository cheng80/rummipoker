# Rummi Poker Grid — 마이그레이션·구조 플랜

> 목표: **Flutter 위젯 기반 전투 화면**으로 루미 포커 그리드를 우선 완성하고, Flame은 필요 시 **연출 레이어**로만 부분 도입한다. 앱 골격·공용 서비스는 재사용한다. 레거시 “순서 탭” 게임 코드는 **제거됨** (히스토리는 Git).

---

## 1. 원칙 (효율 우선)

1. **앱 = 셸**, **게임 = 플러그인**: `main` / `app` / `router` / 다국어 / 저장소 / 사운드는 유지, 게임만 교체 가능하게 경계를 둔다.
2. **상태: Riverpod**: 세션·게임 단계·점수 요약 등은 `lib/providers/features/`의 `Notifier`로 관리한다. **코드젠 없음**(`riverpod_annotation` 미사용). 상세는 `docs/riverpod_architecture.md`.
3. **Flutter-first**: 보드·타일·라인·입력·HUD·상점은 Flutter 위젯으로 우선 정리한다. Flame은 드로우/정산/이펙트가 필요할 때만 별도 레이어 후보로 둔다.
4. **레거시 탭탭 게임**: 제거됨. 새 게임은 현재 `lib/views/game_view.dart` 중심으로 유지하고, Flame 재도입이 필요하면 범위를 좁혀 추가한다.
5. **비주얼**: 루미 타일은 **동일 렌더링 클래스(색·비율)** 를 재사용하는 전제에서, **기존 다른 게임의 팔레트·UI 톤**을 참고한다. **Google Stitch MCP**로 프롬프트를 넣어 **참고용 목업(세로 화면·구획·버튼)** 을 만든 뒤, Flutter 테마/간격 상수로 이식한다 (코드와 병행, 스티치 산출물은 레퍼런스).

### 1.1 현재 룰 스냅샷 (문서 기준 — 플랜·구현과 정합)

> 상세는 `rummi_poker_grid_gdd.md` / `rummi_poker_grid_game_logic.md` / `rummi_poker_grid_v1_assumptions.md`.

| 영역 | 확정 방향 |
|------|-----------|
| 덱 | `copiesPerTile` 기반(`4슈트×13랭크×copiesPerTile`), 리셔플 없음. 구현은 52/104 공용 |
| 보드·라인 | 5×5, **12줄** 평가, 일괄 확정·공유 타일 동시 제거 |
| 블라인드 자원 | 목표 **\(T\)**, 버림 **\(D\)** — **족보 확정 횟수 제한 없음** |
| 턴 | 배치 사이클 **무제한**; 압박은 \(D\)·\(T\)·덱 |
| 만료 | **\(D=0\)** 후 **25칸 만재**, 또는 **현재 덱 전부 소모** |
| 조커 | **메타 슬롯만** — 보드 타일 아님 |
| 메타 흐름 | **실시간 줄 정산 → Stage Clear 판정 → Cash Out 바텀시트 → 상점 전체 화면 → 다음 스테이지** |
| 스테이지 전환 | 다음 스테이지 진입 시 **덱 전체 리셋 + runSeed 기반 파생 셔플** |

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
| 플랫폼 설정 | `android/`, `ios/`, `web/` 등 번들·빌드 | 앱 ID `com.cheng80.rummipoker` |

**조건부 보존**

| 영역 | 조건 |
|------|------|
| `lib/views/title_view.dart` | 메뉴 카피·모드 선택이 새 게임과 다르면 **UI만 개편**, 라우팅 패턴은 유지 |
| `lib/views/game_view.dart` | 현재 전투 화면 본체. 이후 필요 시 일부 연출만 Flame 레이어로 분리 가능 |

---

## 3. 전환·교체할 것 (Transition)

| 현재 | 전환 방향 |
|------|-----------|
| (삭제됨) `bingo_card_game.dart`, `game/components/*` | 제거 유지. 새 전투 화면은 Flutter 위젯 기준으로 계속 다듬고, 필요 시 효과 전용 Flame 레이어만 추가 |
| `GameView` | 현재 메인 전투/메타 진입점. 상점, 제스터 오버레이, 정산 흐름 포함 |
| `app_config.dart` 문구·타이틀 | 앱 스토어/타이틀을 새 게임에 맞게 수정 (기능 키 구조는 유지) |
| (삭제됨) `game_flow.md`, `code-flow-analysis.md` | 구 탭 게임 분석 문서는 제거. 진행은 `rummi_poker_grid_execution_checklist.md` 사용 |

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
├── views/
│   ├── game_view.dart        # 현재 메인 게임 화면 (전투/HUD/상점 흐름)
│   └── rummi_game_view.dart  # (선택) 새 게임 전용 뷰
└── resources/, services/, utils/  # 위 Preserve와 동일
```

- **`logic/`**: 단위 테스트하기 쉬움 (GDD의 핸드·점수·버림 규칙).
- **`views/game_view.dart`**: 현재 렌더링·입력·메타 UI 중심.
- **Flame 레이어**: 필요 시 정산/드로우/제스터 효과 전용으로만 좁게 추가.

---

## 5. 단계별 플랜

| 단계 | 내용 | 산출물 |
|------|------|--------|
| **0** | 룰 문서 동기화 유지: §1.1 스냅샷·`v1_assumptions` — **`copiesPerTile`·\(T,D\)·죽은 줄 버림 처리·만료** 등 변경 시 본 표·체크리스트 갱신 | 문서만 |
| **0.5** | **비주얼·Stitch**: 기존 게임 색상/타일 스타일 정리 → **Google Stitch MCP** 프롬프트로 참고 목업 생성 → 색·간격 토큰 초안 | Stitch 화면·`DESIGN.md` 또는 메모에 팔레트 표 |
| **1** | `logic/rummi_poker_grid`: (완료) 타일·보드·12줄·`HandEvaluator` — **추가** `Deck`·웨이스트·`RummiBlindState`(\(T,D\), 누적 점수)·드로우/배치/버림/일괄 확정 퍼사드·만료(25칸·덱 소진) 이벤트 | 테스트 + 엔진 이벤트 표 |
| **2** | `views/game_view.dart`: HUD + Jester 5슬롯 + 5x5 보드 + 단일 손패 + 액션 버튼 + 옵션/시드 UI | 화면 프로토타입 |
| **3** | 실시간 줄 정산·캐시아웃·상점 전체 화면·죽은 줄 버림 완화 연동 | GDD §2~5·§8 핵심 루프 |
| **4** | 조커 메타·경제·방치 패널티 (`LineHazardTuning`)·미구현 Jester 계열 | 밸런스 튜닝 |
| **5** | `TitleView`·`app_config`·번역·스토어 문구 정리 | 출시 준비 |

**체크**: 세부 진행은 `rummi_poker_grid_execution_checklist.md` — 본 절과 **주기적으로 대조**한다.

---

## 6. 문서 역할 분리

| 문서 | 역할 |
|------|------|
| `docs/rummi_poker_grid_gdd.md` | 기획·UX·철학 (단일 진실 원천) |
| `docs/rummi_poker_grid_game_logic.md` | **구현용** 규칙·상태·판정 (엔진 스펙) |
| `docs/rummi_poker_grid_execution_checklist.md` | **실행 순서** 체크리스트 (일정·진행 상태) |
| `docs/riverpod_architecture.md` | Riverpod 계층·Flame 연동 패턴 |
| `docs/responsive-phone-frame-layout.md` | 세로·폰/태블릿 프레임 레이아웃 |
| 본 문서 (`…migration_plan.md`) | 보존/전환·폴더·단계 |

---

## 7. 리스크·메모

- **라우트**: `/game?seed=` 단일 진입; 레거시 모드 분기는 없음.
- **에셋**: 루미 타일 비주얼은 현재 Flutter 렌더링 클래스 기준을 유지하고, 필요 시 효과 레이어만 별도 구현한다.
- **Stitch MCP**: 생성 목업은 **최종 UI가 아님**. 색·구획·타이포만 추출하고, 실제 구현은 현재 Flutter 위젯 레이아웃 기준으로 맞춘다.
