# 작업 세션 시작 — 여기부터 읽기

> **역할**: Codex든 Cursor든 새 대화를 열어 작업을 다시 이어갈 때 **가장 먼저** 읽는 문서다.  
> 코딩 규칙은 `CURSOR.md`에 두고, **현재 어디까지 왔는지 / 다음에 무엇을 해야 하는지**는 이 문서가 안내한다.

---

## 대화 시작 시 한 줄

**「`START_HERE.md`, `docs/rummi_poker_grid_execution_checklist.md`, `docs/save_resume_architecture.md`를 보고, 이어하기 저장 아키텍처와 현재 우선 작업을 같이 확인한 뒤 진행하자.」**

---

## 1. 필수 순서

| 순서 | 문서 | 할 일 |
|:---:|:---|:---|
| 1 | **이 파일** (`START_HERE.md`) | 아래 §2, §3만 먼저 확인 |
| 2 | [`docs/rummi_poker_grid_execution_checklist.md`](docs/rummi_poker_grid_execution_checklist.md) | 체크 안 된 다음 작업 확인 |
| 3 | [`docs/DESIGN.md`](docs/DESIGN.md) | 현재 화면에 적용할 디자인 기준 확인 |
| 4 | [`docs/save_resume_architecture.md`](docs/save_resume_architecture.md) | 이어하기 저장/복원/키 분리 정책 확인 |
| 5 | [`docs/rummi_poker_grid_gdd.md`](docs/rummi_poker_grid_gdd.md) | 룰 충돌이 생길 때만 확인 |
| 6 | [`docs/rummi_poker_grid_game_logic.md`](docs/rummi_poker_grid_game_logic.md) | 구현 세부 기준 확인 |

---

## 2. 현재 프로젝트 상태

- 프로젝트는 기존 `빙고 카드` 앱에서 **`Rummi Poker Grid`** 로 대규모 마이그레이션 중이다.
- 핵심 룰은 현재 문서 기준으로 고정되어 있다.
  - `5x5` 보드
  - `12줄` 평가
  - 덱은 `copiesPerTile` 기반 (`총 장수 = 4색 × 13랭크 × copiesPerTile`)
  - 현재 기본값은 `copiesPerTile = 1` 이라 `52장`, 필요 시 `2`로 올리면 `104장`
  - 손패 기본값은 `1장`
  - 현재 구현에는 디버그용 `maxHandSize` 변수가 있고, 게임 화면에서 `1~3장`까지 조절 가능
  - 목표 점수 `T`
  - 버림 자원은 **보드 버림 `D_board` / 손패 버림 `D_hand`** 으로 분리
  - 죽은 줄은 **줄 확정으로 제거하지 않고**, **보드 타일 하나를 버려서 완화**
  - 줄 확정 시에는 **줄 전체가 아니라, 족보 성립에 기여한 카드만 제거**
- `Removal(C)` 자원 규칙은 **폐기**되었다. 새 대화에서 이 규칙을 다시 살리면 안 된다.

현재 구현 상태 요약:
- 순수 로직: `lib/logic/rummi_poker_grid/` 에 기본 엔진/세션/덱/보드/테스트가 들어와 있다.
- 게임 로직: `lib/logic/rummi_poker_grid/` 의 세션/엔진이 플레이 규칙을 담당한다.
- Flutter 화면: `lib/views/game_view.dart` 를 중심으로 쓰되, **상단 HUD / Jester 5슬롯 / 5x5 보드 / 손패 / 캐시아웃 / 상점**은 `lib/views/game/widgets/` 하위 위젯으로 1차 분리되었다.
- Riverpod 상태: `GameView` 는 `GameSessionNotifier`, `TitleView` 는 `TitleNotifier`, `SettingView` 는 `SettingsNotifier` 기준으로 UI 상태를 읽는다.
- 공용 UI 유틸: `lib/utils/common_ui.dart` 에서 **상단 알림(`showTopNotice`) / 하단 알림(`showBottomNotice`) / 공통 다이얼로그(`showAppDialog`, `showConfirmDialog`)** 를 관리한다.
- Flame 코드는 당장 핵심 화면 책임에서 한 발 물러났고, 이후 필요 시 **드로우/정산/조커 연출 레이어**로만 재도입하는 방향이 현재 판단이다.
- 디자인 문서: [`docs/DESIGN.md`](docs/DESIGN.md) 를 현재 코드/룰 기준으로 최신화했다.
- 최근 작업:
  - `RummiPokerGridSession.confirmAllFullLines()` 를 **족보 기여 카드만 제거**하도록 수정했다.
  - 손패 기본 한도를 `1장`으로 두되, 디버그 메뉴에서 `1~3장` 조절이 가능하도록 유지했고, 관련 테스트/문서 기준도 함께 갱신했다.
  - `GameView` 를 **Flutter 위젯 기반 전투 화면**으로 전환했다.
  - `GameView` 는 현재 `GameSessionNotifier` 기반으로 세션/선택/stage flow/UI 잠금 상태를 읽도록 정리했다.
  - `TitleView` 는 현재 `TitleNotifier` 기반으로 이어하기 가능 여부/손상 세이브 분기/삭제 흐름을 처리한다.
  - 시드 번호는 상단 HUD에서 제거하고 **옵션 다이얼로그에서만 복사 가능**하게 정리했다.
  - Jester 슬롯 5장, 5x5 보드, 단일 손패, 하단 액션 버튼의 밀도를 다시 맞췄다.
  - 액션 버튼은 이제 **보드 버림 / 손패 버림 / 줄 확정 / 선택 해제**로 분리되어, 보드 타일 버림과 손패 버림을 혼동하지 않게 정리했다.
  - 목표 점수 달성 시 **실시간 줄 정산 -> Stage Clear 판정 -> Cash Out Bottom Sheet -> Jester Shop 전체 화면 -> 다음 스테이지** 흐름을 붙였다.
  - `data/common/jesters_common.json` 을 읽어 **Jester 상점 / 구매 / 판매 / 보유 슬롯**을 연결했다.
  - 상점은 이제 **바텀시트가 아니라 전체 화면 라우트**이며, 보유 Jester 5슬롯 / 드래그 판매 / 오퍼 리스트 / 다음 스테이지 진입을 포함한다.
  - 상점 / 옵션 / 타이틀도 게임 화면과 같은 **중앙 정렬형 phone-frame 레이아웃**으로 통일했다.
  - `PhoneFrameScaffold` 기준 논리 크기는 **`390 x 750`**, 비율은 **`13:25`** 로 고정한다. 웹 / iPad / 폰 모두 바깥 프레임만 맞추고, 내부 콘텐츠는 같은 논리 해상도를 본다.
  - 다음 스테이지 진입 시 덱은 **`copiesPerTile` 값 그대로 전체 리셋**되고, **`runSeed + stageIndex` 기반 파생 시드 셔플**로 재현 가능하게 맞췄다.
  - 앱 루트에 `JesterTranslationScope` 를 붙여 **Jester 한글 이름/효과 텍스트**를 리소스에서 읽도록 연결했다.
  - 게임 화면에서 장착된 Jester를 누르면 **판매 가능한 모달형 정보 패널**이 뜨고, 상점의 보유 슬롯도 탭으로 상세/판매 확인이 가능하다.
  - 임시 테스트용으로 시작 골드는 `10` 이고, 게임 화면 Jester 헤더 줄에 **`SHOP` 진입 버튼**을 두었다.
  - 현재는 **전투 점수에 직접 반영 가능한 Jester 효과**를 우선 연결했다.
  - common Jester 전체를 그대로 쓰지 않고, 현재 룰에 맞는 curated 런타임 카탈로그를 `data/common/jesters_common_phase5.json`으로 분리해 사용한다.
  - 현재 runtime curated 카탈로그 기준 **사용 가능 common Jester는 38종**이다.
    - `chips_bonus`
    - `mult_bonus`
    - `xmult_bonus`
    - `scholar` 특수 처리
    - 조건: `none`, `tile_color_scored`, `pair`, `two_pair`, `three_of_a_kind`, `straight`, `flush`, `face_card`, `rank_scored`, `cards_remaining_in_deck`, `remaining_discards`, `owned_jester_count`, `zero_discards_remaining`, `empty_jester_slots`
  - economy 2차 1차분은 구현되었다.
    - `egg`
    - `golden_jester`
    - `delayed_gratification`
  - stateful 1차도 구현되었다.
    - `green_jester`
    - `supernova`
    - `popcorn`
    - `ice_cream`
    - `ride_the_bus`
  - 검사 편의를 위해 현재 `SHOP` 버튼은 **8장 검사 오퍼를 한 번에 띄우는 테스트 상태**가 들어가 있다.
  - Jester 슬롯 카드는 지금 **제목 + 분류 배지 + 활성 표시만** 노출하고, 실제 효과 설명/현재 값은 상세 패널에서 확인한다.
  - 숫자 타일은 현재 **11/12/13만 하단 중앙 점 표시**로 face card 여부를 구분한다.
  - Jester 슬롯 / 상점 오퍼 / 보유 5슬롯의 선택 외곽선은 최신 바깥 링 방식으로 정리했다.
  - 상점 오퍼 리스트는 현재 **선택 외곽선만 유지**하고, 배경색 애니메이션에 따른 번쩍임 효과는 제거했다.
  - 저장 스키마는 현재 **v2** 이고, 현재 시점 상태와 함께 **현재 스테이지 시작 시점 스냅샷**도 저장한다.
  - 게임/상점 옵션의 `재시작`은 현재 **같은 시드 새 런**이 아니라, **현재 스테이지 시작 시점 복원**으로 동작한다.
  - 웹에서는 `flutter run -d chrome` 직접 검증 대신, 현재 **`flutter build web` + 정적 서버 + Playwright** 절차로 저장/이어하기 회귀를 확인한다.
  - 2026-04-13 기준 웹에서 **`랜덤 시작 -> 옵션 나가기 -> 타이틀 즉시 이어하기 표시`** 까지 검증했다.
  - 보드 5x5 강조는 **셀 단위 강조 방식**을 유지하되, 빈 슬롯 / 배치 카드 / 기여 표시 / 정산 글로우가 같은 곡률로 읽히도록 **카드와 동일한 라운드 계산 기준**으로 통일했다.
  - `StarryBackground`를 **그룹 Opacity 방식**으로 최적화했다. 별을 3 그룹으로 나눠 `RepaintBoundary`로 래스터 캐싱하고, 깜빡임은 `FadeTransition`(GPU alpha)으로만 처리한다. `paint()` 재호출 0회/프레임, 별 좌표는 정규화(0~1)로 리사이즈 시 재생성 불필요.
  - `TitleView`가 자체 `Scaffold + StarryBackground + PhoneFrame`을 조합하던 것을 **`PhoneFrameScaffold`**로 통일했다. 이제 모든 뷰(`GameView`, `TitleView`, `SettingView`, 상점)가 같은 `PhoneFrameScaffold`를 사용한다.
  - 중복 UI 클래스를 공용 위젯으로 통합했다: `GameTableBackdrop`, `GameModalCard`, `showGameFramedDialog`.
  - `GameView.initState`에서 BGM/카탈로그 로딩을 `addPostFrameCallback`으로 지연하여 타이틀→게임 전환 시 버벅임을 해결했다.
  - **GameView orchestration 2차 리팩토링 완료** (2026-04-14):
    - 옵션 다이얼로그를 `game_options_dialog.dart`(`showGameOptionsDialog`)로 추출
    - 게임오버 다이얼로그를 `game_shared_widgets.dart`(`showGameOverDialog`)로 추출
    - 줄 확정/캐시아웃/상점/스테이지진입/재시작 비즈니스 로직을 `GameSessionNotifier`로 이전 (`confirmLines`, `prepareCashOut`, `openShop`, `advanceToNextStage`, `restartCurrentStage`)
    - JESTER 헤더 행을 `GameJesterHeaderRow` 위젯으로 추출
    - `game_view.dart` 1129행 → 846행 (25% 축소)
  - **GameView 전투 액션 Notifier 이전 + 레거시 삭제** (2026-04-14):
    - 전투 액션 6종을 `GameSessionNotifier`로 이전: `tryPlaceTile`, `drawTile`, `discardBoardTile`, `discardHandTile`, `sellOwnedJester`, `evaluateExpiry`
    - 검사 상점 열기도 `openShopForTest`로 이전
    - View는 이제 **SFX 재생 + UI 피드백(snack) + 저장 트리거**만 담당하고, 세션/보드/손패 직접 조작 없음
    - `game_view.dart` 846행 → 813행 추가 축소
    - `GameSessionNotifier` 295행 → 402행 (전투 액션 포함)
    - 미사용 레거시 `rummi_poker_grid_game.dart` (1,420행) 삭제

---

## 3. 지금 가장 중요한 작업

**현재 1순위는 “GameView orchestration 2차 리팩토링이 완료되었으므로, 남은 기능 작업(재시작 검증, rule_modifier 분류, 검사 상점 정리, 유저 문구 정리)을 이어가는 것”이다.**

즉, 새 세션에서 바로 이어야 할 일:

1. [`docs/rummi_poker_grid_execution_checklist.md`](docs/rummi_poker_grid_execution_checklist.md), [`docs/save_resume_architecture.md`](docs/save_resume_architecture.md) 를 먼저 보고, 현재 리팩토링 배치와 저장 정책 기준을 확인한다.
2. 특히 아래 파일을 우선 본다.
   - [`lib/providers/features/rummi_poker_grid/game_session_notifier.dart`](lib/providers/features/rummi_poker_grid/game_session_notifier.dart) — 비즈니스 로직 (`confirmLines`, `prepareCashOut`, `openShop`, `advanceToNextStage`, `restartCurrentStage`, `tryPlaceTile`, `drawTile`, `discardBoardTile`, `discardHandTile`, `sellOwnedJester`, `evaluateExpiry`, `openShopForTest`). 402행.
   - [`lib/views/game_view.dart`](lib/views/game_view.dart) — orchestration (SFX, snack 피드백, settlement sequence 타이밍, 네비게이션, save 트리거). 813행.
   - [`lib/views/game/widgets/`](lib/views/game/widgets/) — `game_options_dialog.dart`(신규), `game_jester_widgets.dart`(`GameJesterHeaderRow` 신규), `game_shared_widgets.dart`(`showGameOverDialog` 신규)
   - [`lib/logic/rummi_poker_grid/jester_meta.dart`](lib/logic/rummi_poker_grid/jester_meta.dart)
   - [`lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart`](lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart)
   - 참고용 [`/Users/cheng80/Desktop/FlutterFrame_work/flame_rummideck/lib/`](</Users/cheng80/Desktop/FlutterFrame_work/flame_rummideck/lib/>)
3. 다음 구현 우선순위는 이 순서다.
   - `현재 스테이지 재시작` 검증
     - 전투 중 누적된 골드/Jester/stateful 값이 정확히 롤백되는지
     - 상점에서 구매/판매 후 재시작 시 stage-start 기준으로 되돌아가는지
     - 앱 재실행 후에도 같은 기준으로 재시작되는지
   - 현재 검사 전용 상점 오퍼를 유지할지, 다음 작업 시작 전에 다시 랜덤 3장 정책으로 되돌릴지 결정
   - 유저 노출 문구에서 `멀트` 같은 내부 용어를 `배율` 등으로 바꿀지 정리
   - `rule_modifier` 후보 common Jester를 id 인덱스 순서대로 다시 분류하고, 현재 룰에서 즉시 적용 가능한 것만 추린다
   - 필요 시 전투/정산 연출만 Flame 레이어로 분리
4. 디자인 작업은 계속 중요하지만, 현재는 **문서 기준과 실제 코드 상태가 다시 어긋나지 않게 유지하는 것**이 우선이다.

룰 정합성에서 특히 확인할 것:
- 덱 장수가 고정 숫자가 아니라 `copiesPerTile`에서 결정된다는 점이 문서 전체에 반영되어 있는지
- `52장 / 104장`을 같은 로직과 같은 UI 흐름으로 지원하는 구조가 문서에 적혀 있는지
- 줄 확정 시 **기본 점수 + 제스터 보너스**가 어떻게 합산되는지 설명이 필요한지
- 스테이지 클리어 후 **상점이 전체 화면**이라는 점과, 다음 스테이지 진입 시 **시드 기반 덱 리셋/셔플**이 문서에 반영되어 있는지
- Jester 한글화/정보 패널/판매 동선이 실제 UI와 같은 말로 정리되어 있는지
- 손패 기본값 `1장`과 디버그 조절 범위 `1~3장` 설명이 문서 전체에 일관되게 반영되어 있는지

---

## 4. Stitch 관련 메모

- Cursor 쪽 Stitch MCP는 사용 중일 수 있다.
- Codex 쪽은 `~/.codex/config.toml` 에 `stitch` MCP 서버를 추가했다.
- 다만 **지금 핵심은 Stitch 신규 목업 생성보다, 이미 구현된 Flutter 위젯 UI와 메타 루프 문서 기준을 맞추는 것**이다.
- 화면 구조를 다시 크게 갈아엎기 전에는 `DESIGN.md`를 코드 기준으로 유지한다.

## 5. v1 고정 규칙 요약

- 평가 라인: **행 5 + 열 5 + 주/반 대각 2 = 총 12줄**
- 빈 칸이 있는 줄: **판정하지 않음**
- Straight: 일반 연속 + **10–11–12–13–1**
- 죽은 줄: **하이카드 / 원페어**
- 죽은 줄 처리: **보드패 버림으로만 완화**
- 일괄 확정: 대기 중인 완성 줄 **전부**를 한 번에 점수화/제거
- 조커: **보드 타일 아님**, 메타 슬롯만 사용
- 덱: `copiesPerTile` 기반, v1 기본은 `1`
- 만료: `D_board == 0` 상태 보드 25칸 만재 또는 현재 덱 전부 소모

## 6. 현재 메모

- 사용자 확정 규칙은 **죽은 줄을 줄 확정으로 지우지 않고**, **보드패 버림으로만 완화**하는 방향으로 고정됐다.
- 웨이스트 슬롯은 현재 룰상 불필요하다고 판단하여 **폐기**했다.
- common Jester 전체를 그대로 쓰지 않고, 현재 룰에 맞는 curated 런타임 카탈로그 `data/common/jesters_common_phase5.json`만 분리해 사용한다.
- 정산 체인은 붙어 있고, **economy 2차 1차분**과 **stateful 1차**도 이미 코드에 반영되었다.
- 이어하기 기능 1차 구현이 들어갔다.
- 저장 방식은 **GetStorage payload + secure storage key + HMAC 서명** 하이브리드다.
- 저장 포맷은 이제 **현재 시점 + 현재 스테이지 시작 시점(stageStartSnapshot)** 을 함께 가진다.
- 저장 스키마 버전은 현재 **v2** 다. 이전 v1 세이브는 구버전으로 간주되어 복원이 거부될 수 있다.
- 웹 저장/이어하기 회귀는 현재 `docs/save_resume_architecture.md` 의 정적 빌드 + Playwright 절차를 기준으로 검증한다.
- 알림/다이얼로그는 `lib/utils/common_ui.dart` 기준으로 공용화했다.
- `StarryBackground`는 `App`의 `MaterialApp.router(builder:)`에서 **앱 전체에 단 1개**만 존재한다. 페이지 전환에도 파괴/재생성되지 않아 AnimationController와 RepaintBoundary 래스터 캐시가 유지된다.
- Riverpod 분리가 들어갔다.
  - `GameSessionNotifier` — 전투 세션/선택/stage flow/Jester 관리 + 모든 전투 액션 비즈니스 로직 (402행)
  - `TitleNotifier` — 타이틀 화면 이어하기/삭제 흐름
  - `SettingsNotifier` — 볼륨/음소거/화면꺼짐방지 설정 (SettingView → ConsumerWidget, App → ConsumerWidget)
- 위젯 모듈화 1차가 들어갔다.
  - `game_shared_widgets.dart`
  - `game_jester_widgets.dart`
  - `game_hand_zone.dart`
  - `game_cashout_widgets.dart`
  - `game_shop_screen.dart`
- 타이틀은 이제 **이어하기 / 랜덤 시작 / 시드 시작**을 분리한다.
- `이어하기`는 저장된 현재 런 복원이고, `랜덤 시작`/`시드 시작`은 모두 새 런 시작이다.
- 인게임 옵션의 `재시작`은 이제 **런 전체 재시작이 아니라 현재 스테이지 재시작**이다.
- 현재 스테이지 재시작은 아래 상태를 stage-start 기준으로 되돌린다.
  - 보드 / 손패 / 제거 더미 / 덱 순서
  - 현재 스테이지 골드
  - 장착 Jester / 상점 상태
  - stateful Jester 값 (`Ride the Bus` 등)
- `이어하기`를 누르면 **이어하기 / 삭제하기 / 취소** 메뉴가 먼저 나오고, 손상 세이브는 삭제 유도 다이얼로그로 분기한다.
- 인게임은 **드로우/배치/버림/확정/상점/스테이지 전환/lifecycle autosave**가 연결되어 있다.
- 정보성 피드백은 현재 **하단 `SnackBar` 대신 상단 오버레이 알림**을 기본으로 사용한다.
- 푸시를 붙이더라도 세이브용 `saveDeviceKey`는 푸시 토큰/설치 ID와 분리한다.
- 경제 고정값은 현재 아래 값으로 유지 중이다.
  - 시작 골드 `10`
  - 스테이지 클리어 기본 보상 `10`
  - 남은 `D_board` 보상 `+5`
  - 남은 `D_hand` 보상 `+2`
  - 상점 리롤 시작 `5`, 같은 상점에서 리롤마다 `+1`
  - 상점 오퍼 수 기본 `3`
  - 판매가 `floor(baseCost / 2)`, 최소 `1`
- 상점/옵션/설정/타이틀은 현재 게임 화면과 동일한 **중앙 정렬 phone-frame 기준**으로 동작한다.
- `PhoneFrameScaffold` 는 항상 **`390 x 750` 고정 논리 크기 + `13:25` 비율**을 사용한다. 모든 뷰가 `PhoneFrameScaffold`를 사용하며, 배경은 `App` 레벨에서 한 번만 생성된 `StarryBackground`를 투과시킨다.
- 현재 남은 큰 묶음은 아래 두 가지다.
  - `rule_modifier`
  - `retrigger`
- Riverpod + MVVM 리팩토링 2차 완료 (2026-04-14):
  - `GameSessionNotifier`에 비즈니스 로직 이전: `confirmLines`, `prepareCashOut`, `openShop`, `advanceToNextStage`, `restartCurrentStage`
  - `game_view.dart` 1129행 → 846행 (25% 축소): 옵션 다이얼로그, 게임오버 다이얼로그, JESTER 헤더 행 위젯 추출
  - 신규 파일: `game_options_dialog.dart`
  - 신규 위젯: `GameJesterHeaderRow`, `showGameOverDialog`, `showGameOptionsDialog`
- 현재 남은 리팩토링은 아래 순서다.
  - `_GameSurface`/`_GameLayout`을 별도 파일로 분리 여부 검토 (현재 각각 162행/147행으로, 급하지 않음)
  - `game_shared_widgets.dart` (885행) / `game_shop_screen.dart` (1012행) 분리는 해당 기능 수정 시 같이 진행
- 외부 시스템이 필요한 항목은 계속 보류다.
  - `square_jester`
  - `red_card`
  - `fortune_teller`
  - `constellation`

## 7. 다음 작업 순서 메모

1. ~~`GameView` orchestration 리팩토링 2차~~ — **완료** (2026-04-14)
2. 이어하기/재시작 실기기 검증
   - 앱 강제 종료 / 상점 열린 상태 / 다음 스테이지 직전 / 손상 세이브 삭제 동선이 실제 기기에서 기대대로 동작하는지 확인
   - 현재 스테이지 재시작 시 골드/Jester/stateful 값이 stage-start 기준으로 롤백되는지 확인
   - 상점에서 재시작했을 때도 같은 복원 기준을 유지하는지 확인
3. 알림 정책 실기기 점검
   - 현재 상단 오버레이 알림이 모든 주요 화면에서 버튼/HUD를 과하게 가리지 않는지 확인
   - CTA가 필요한 예외 케이스만 하단 variant가 필요한지 검토
4. 유저 노출 문구 정리
   - 상세 패널 설명에서 `멀트` 같은 내부 용어를 유지할지, `배율`/`추가 배율`로 바꿀지 결정
5. `rule_modifier` common 분류 착수
   - id 인덱스 순서대로 전수 확인
   - 즉시 적용 가능 / 후순위 / 외부 시스템 의존으로 한 번에 분리
6. 검사 상점 상태 정리
   - 지금은 8장 검사 오퍼 강제 노출 상태
   - 다음 작업 전에 유지 여부를 결정
7. 보류 유지
   - `retrigger`
   - 외부 시스템 의존 `stateful_growth`

## 8. 파일 우선순위

새 세션에서 코드 읽기 순서는 아래가 가장 효율적이다.

1. [`START_HERE.md`](START_HERE.md)
2. [`docs/rummi_poker_grid_execution_checklist.md`](docs/rummi_poker_grid_execution_checklist.md)
3. [`docs/save_resume_architecture.md`](docs/save_resume_architecture.md)
4. [`docs/rummi_poker_grid_gdd.md`](docs/rummi_poker_grid_gdd.md)
5. [`docs/rummi_poker_grid_game_logic.md`](docs/rummi_poker_grid_game_logic.md)
6. [`lib/providers/features/rummi_poker_grid/game_session_notifier.dart`](lib/providers/features/rummi_poker_grid/game_session_notifier.dart)
7. [`lib/views/game_view.dart`](lib/views/game_view.dart)
8. [`lib/views/game/widgets/`](lib/views/game/widgets/)
9. [`lib/logic/rummi_poker_grid/jester_meta.dart`](lib/logic/rummi_poker_grid/jester_meta.dart)
10. [`lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart`](lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart)
11. 필요할 때만 [`docs/DESIGN.md`](docs/DESIGN.md)

## 9. 세션 종료 전 갱신 규칙

작업을 끊기 전에 최소한 아래는 갱신한다.

1. 끝낸 항목이 있으면 [`docs/rummi_poker_grid_execution_checklist.md`](docs/rummi_poker_grid_execution_checklist.md) 체크 상태를 갱신
2. 덱 장수, 만료, 메타 루프, Jester 효과 범위를 건드렸으면 [`docs/rummi_poker_grid_gdd.md`](docs/rummi_poker_grid_gdd.md), [`docs/rummi_poker_grid_game_logic.md`](docs/rummi_poker_grid_game_logic.md) 같이 수정
3. 이어하기 저장/복원/키 정책을 건드렸으면 [`docs/save_resume_architecture.md`](docs/save_resume_architecture.md) 를 같이 수정
4. 디자인 방향이 바뀌었으면 [`docs/DESIGN.md`](docs/DESIGN.md) 수정
5. 알림/다이얼로그 정책을 건드렸으면 `lib/utils/common_ui.dart` 와 체크리스트 메모를 같이 갱신
6. 새 세션이 바로 이어질 수 있게 이 문서의 §3 “지금 가장 중요한 작업”을 최신 상태로 유지

## 10. 한 줄 요약

**다음 세션은 `START_HERE.md`와 `docs/save_resume_architecture.md`로 시작하고, 현재는 `copiesPerTile` 기반 덱 + Riverpod 1차 분리(`GameSessionNotifier`, `TitleNotifier`) + Flutter 위젯 전투 화면 모듈화 1차 + 실시간 정산/캐시아웃/전체화면 상점 흐름 + economy 2차 1차분 + stateful 1차 + phase5 curated common 38종 + 하이브리드 이어하기 저장 v2 + 현재 스테이지 재시작(stage-start snapshot) 기준으로 문서와 코드를 함께 유지하면 된다.**
