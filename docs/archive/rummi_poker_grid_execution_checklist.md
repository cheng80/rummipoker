# Rummi Poker Grid — 실행 체크리스트

> 순서대로 진행. 항목을 끝낼 때마다 `[ ]` → `[x]`로 갱신한다.  
> 기획·규칙: `rummi_poker_grid_gdd.md` / 구현 스펙: `rummi_poker_grid_game_logic.md` / 세션 재개 메모: `START_HERE.md`

---

## 0. 기획 고정 (GDD·게임 로직 문서)

- [x] **덱**: `copiesPerTile` 기반 (`총 장수 = 4×13×copiesPerTile`) — **52/104 공용 처리 가능**
- [x] **평가 라인**: 행·열·주/반 대각 = **12줄** (`rummi_poker_grid_gdd.md` §1.1)
- [x] **Straight**: 일반 연속 + 휠 **10–11–12–13–1** (`HandEvaluator._isStraight`)
- [x] **손패 한도**: 기본값은 **1장**, 현재 구현은 디버그 메뉴에서 **1~3장 조절 가능** — 드로우/버림 보충/UI가 `maxHandSize` 기준으로 동작
- [x] **죽은 줄 / 방치**: 죽은 줄 = 하이카드 + 원페어; 투페어 이상만 즉시 확정 가능
- [x] **일괄 확정**: 현재 점수 성립 줄 **개수 제한 없음**; 확정 버튼으로 성립 줄 **전부** 한 번에
- [x] **확정 제거 범위**: 줄 전체가 아니라 **족보 성립에 실제 기여한 카드만 제거**
- [x] **겹침 보너스**: 기여 카드의 최고 `k` 기준으로 `α = 0.3`, `cap = 2.0` 배수 적용
- [x] **블라인드 자원**: §8 — **\(T\)·\(D\)** · 족보 확정 **횟수 제한 없음** · 배치 턴 무제한
- [x] **만료**: **\(D=0\)** 후 **25칸 만재**, 또는 **현재 덱 전부 소모** (`copiesPerTile` 값과 무관하게 동일 로직)
- [x] **`RummiBlindState`** + **`PokerDeck`(`copiesPerTile` 기반)** + **`RummiPokerGridSession`** (드로우·배치·버림·일괄 확정·만료 신호) — `lib/logic/rummi_poker_grid/` (`test/logic/rummi_session_test.dart`)
- [x] **빈 칸이 있는 줄**: **현재 놓인 카드만으로 즉시 판정**
- [x] **조커**: **메타(장착 슬롯)만** — 보드 타일 아님

---

## 0.5 비주얼·Stitch (참고 디자인)

> 기존 루미큐브 계열 게임과 **동일 타일 렌더링 클래스**를 쓰는 전제에서, **색·비율**을 맞추고 Stitch로 목업을 뽑는다. 레이아웃 기준은 `docs/OLD/DESIGN.md`의 responsive frame 규칙을 따른다.

- [ ] **참고 소스**: 다른 프로젝트(예: `flame_rummideck`)의 타일 색(`TileColor` → 앱 팔레트), `BattleTileCard` 시각 규칙(테두리·그라데이션·숫자 대비) 정리
- [ ] **톤**: 다크 그린 필·세로 모바일·상단 스코어·하단 손패·액션 버튼 구획 등 레퍼런스 스크린과의 대응표 (발라트로식 HUD 등은 **참고만**)
- [x] **Google Stitch MCP**: 위 팔레트·구획을 넣은 **프롬프트**로 참고 화면 생성 (`projects/6203966996273785875`)
- [ ] **산출물 정리**: Stitch/캡처에서 **색 hex·간격·폰트 역할**만 추출해 `docs/` 메모 또는 앱 테마 상수 초안에 반영 (Flutter 게임 화면 다듬기 단계)

---

## 1. 순수 로직 (`lib/logic/rummi_poker_grid/`)

- [x] 모델: `Tile` / `TileColor`, 보드 5×5, **대각 2줄** (`diagMain` / `diagAnti`)
- [x] **덱 공용화** `PokerDeck`·`buildStandardPokerDeck({copiesPerTile})`·`remainingAfterPlaced`; **`RummiBlindState`**(\(T,D\), 누적 점수)
- [x] `HandEvaluator`: 2~5장 부분 족보·점수 (단위 테스트) — 휠 스트레이트·원페어 dead-line 판정·기여 인덱스 반영
- [x] 엔진: 행·열·**주/반 대각** 현재 카드 평가 + **`listEvaluatedLines`** (12줄) (`RummiPokerGridEngine`)
- [x] **`RummiPokerGridSession`**: 드로우·배치·버림(\(D\))·**일괄 확정**·`evaluateExpirySignals` — 세부는 `rummi_poker_grid_session.dart`
- [x] GDD §3·§8과 엔진 이벤트 **대응표** (`docs/` 또는 `game_logic` 부록) — 정산 체인/메타 후속 책임 기준 반영

---

## 2. Riverpod

- [x] `GameSessionNotifier` 도입: `RummiPokerGridSession` / `RummiRunProgress` / 선택 상태 / stage flow / Jester catalog / 디버그 손패 크기를 `GameSessionState`로 관리
- [x] `TitleNotifier` 도입: 이어하기 가능 여부 / 손상 세이브 분기 / 삭제 액션을 `TitleState`로 관리
- [x] `GameView` 내부 액션 핸들러를 추가 분리
  - 옵션 다이얼로그 → `game_options_dialog.dart`
  - 게임오버 다이얼로그 → `game_shared_widgets.dart` (`showGameOverDialog`)
  - 줄 확정/보드 스냅샷/정산 준비 → `GameSessionNotifier.confirmLines()`
  - 캐시아웃 계산/적용 → `GameSessionNotifier.prepareCashOut()`
  - 상점 오픈 → `GameSessionNotifier.openShop()`
  - 다음 스테이지 진입 → `GameSessionNotifier.advanceToNextStage()`
  - 현재 스테이지 재시작 → `GameSessionNotifier.restartCurrentStage()`
  - JESTER 헤더 행 → `GameJesterHeaderRow` 위젯
- [x] 전역 설정/환경 상태 Riverpod 정리: `SettingsNotifier` + `SettingsState` 도입
  - `SettingView` → `ConsumerWidget`으로 전환 (로컬 setState 제거)
  - `App` → `ConsumerWidget`으로 전환, Wakelock 초기 적용을 Notifier로 통합
  - `main.dart`에서 중복 `_applyKeepScreenOn()` 제거
  - 설정 변경 흐름: `SettingsNotifier` → `GameSettings`(영구 저장) + `SoundManager`(런타임) + `WakelockPlus`
- [ ] Flame ↔ `ref.read` 주입 패턴 확정 (`docs/OLD/riverpod_architecture.md` 참고)

---

## 3. Runtime / Effects

- [x] `GameView` Flutter 위젯 기반 화면 — HUD·Jester 5슬롯·5×5 보드·단일 손패·드로우/확정/버림/선택 해제
- [x] 액션 분리: **보드 버림**과 **손패 버림**을 별도 버튼/별도 카운트로 분리
- [x] 타일 렌더 재사용 (`rummikub_tile_canvas.dart`) + 손패 탭(선택) + 빈 칸 탭(배치)
- [x] 점수 줄 기여 카드 하이라이트 및 선택/버림 상태색 반영
- [x] 목표 점수 달성 시 `실시간 줄 정산 -> Stage Clear 판정 -> Cash Out -> Jester Shop` 흐름
- [x] `data/common/jesters_common.json` 기반 Jester 상점 / 구매 / 판매 / 보유 슬롯
- [x] common curated 풀을 `data/common/jesters_common_phase5.json`까지 분리해 현재 룰과 상점 오퍼 기준을 고정
- [x] 전투 점수에 직접 반영 가능한 Jester 효과 연결 (`chips_bonus`, `mult_bonus`, `xmult_bonus`, `scholar`)
- [x] 게임 화면 장착 Jester 탭 시 모달형 정보 패널 + 판매 버튼
- [x] 실시간 줄 정산 중 활성 Jester 강조 + 카드 슬롯 위치 배점 버스트 연출
- [x] 경제 수치 v1 고정: 시작 골드 / 캐시아웃 / 리롤 / 판매가 / 상점 오퍼 수 규칙을 문서·코드에서 공통화
- [ ] Flame는 필요 시 드로우/정산/조커 연출 전용 레이어로 재도입
- [x] 웨이스트 슬롯 폐기: 손패 1장이 이미 대기/보류 역할을 대체하므로 별도 UI를 두지 않음
- [ ] 태블릿 `FittedBox`+`MediaQuery` 경로에서 실기기 확인 (`docs/OLD/DESIGN.md` §6)
- [x] economy 2차 1차분: `delayed_gratification` / `golden_jester` / `egg` 라운드 종료형 도입
- [x] stateful_growth 1차: 카드별 단일 카운터 상태 모델 추가 (`green_jester`, `supernova`, `popcorn`, `ice_cream`, `ride_the_bus`)
- [ ] rule_modifier / retrigger는 이벤트 경계 정리 전까지 보류
- [x] Jester 슬롯 카드 표현 단순화: 제목 + 분류 배지 + 활성 표시만 노출, 상세 패널에서 설명/현재 값 확인
- [x] 숫자 타일 face 표시: `11/12/13` 하단 중앙 점으로 구분
- [x] 뷰 모듈화 1차: `game_shared_widgets.dart`, `game_jester_widgets.dart`, `game_hand_zone.dart`, `game_cashout_widgets.dart`, `game_shop_screen.dart` 로 분리
- [x] 중복 UI 클래스 공용화: `GameTableBackdrop`, `GameModalCard`, `showGameFramedDialog`를 `game_shared_widgets.dart`로 통합
- [x] `StarryBackground` 성능 최적화: 그룹 Opacity 방식 (래스터 캐싱 + FadeTransition GPU alpha, paint() 재호출 0회/프레임)
- [x] `TitleView` → `PhoneFrameScaffold` 통일: 모든 뷰가 동일한 `PhoneFrameScaffold` 패턴 사용
- [x] `GameView` 전환 버벅임 해소: BGM/카탈로그 로딩을 `addPostFrameCallback`으로 지연
- [x] `GameView` 추가 경량화 2차
  - stage flow coordinator 비즈니스 로직을 `GameSessionNotifier`로 이전
  - 옵션 다이얼로그 / 게임오버 다이얼로그를 별도 위젯·함수로 추출
  - JESTER 헤더 행을 `GameJesterHeaderRow`로 추출
  - `game_view.dart`: 1129행 → 846행 (25% 축소)
- [x] `GameView` 전투 액션 Notifier 이전 3차
  - 전투 액션 6종 (`tryPlaceTile`, `drawTile`, `discardBoardTile`, `discardHandTile`, `sellOwnedJester`, `evaluateExpiry`) + 검사 상점 (`openShopForTest`)을 `GameSessionNotifier`로 이전
  - View는 SFX + snack + save 트리거만 담당, 세션/보드/손패 직접 조작 제거
  - `game_view.dart`: 846행 → 813행
  - `GameSessionNotifier`: 295행 → 402행
- [x] 미사용 레거시 `rummi_poker_grid_game.dart` (1,420행) 삭제
- [ ] 추후 추가 검토: `_GameSurface`/`_GameLayout`을 별도 파일로 분리 여부

---

## 4. Flutter 셸

- [x] `GameView` — `RummiPokerGridSession(runSeed)` 직결 + 만료 다이얼로그·상단 알림 + 옵션 다이얼로그 시드 복사
- [x] 공용 UI 유틸 정리: `lib/utils/common_ui.dart` 기준 상단 알림(`showTopNotice`) + 하단 알림(`showBottomNotice`) + 공통 다이얼로그 래퍼로 통일
- [ ] `TitleView` 카피·진입 문구 최종 다듬기
- [x] 오버레이/바텀시트: 옵션 다이얼로그, 스테이지 클리어 오버레이, 캐시아웃 바텀시트
- [x] 상점 전체 화면 라우트 + 보유 슬롯 상세/판매 + 리롤 확인 다이얼로그
- [x] 상점/옵션 화면도 게임 화면과 같은 **중앙 정렬 phone-frame 레이아웃** 기준 적용
- [ ] 하단 알림이 꼭 필요한 예외 케이스가 있는지 실기기에서 검토하고, 필요 시 `common_ui`에 하단 variant를 추가

---

## 4.5 이어하기 저장

- [x] 이어하기 저장 아키텍처 문서화: `docs/OLD/save_resume_architecture.md`
- [x] 저장 포맷 고정: `payload + signature + schemaVersion` 구조
- [x] 보안 경로 고정: `GetStorage` payload + `flutter_secure_storage` 설치별 키 + `HMAC-SHA256`
- [x] `RummiPokerGridSession` / `RummiRunProgress` 세이브 DTO 설계
- [x] autosave 트리거 연결: 드로우/배치/버림/확정/상점/스테이지 전환/lifecycle
- [x] 타이틀 `이어하기` 진입 및 손상 세이브 처리 UX
- [x] 게임오버 `다시하기 / 종료` UX
  - `다시하기`: `stageStartSnapshot` 즉시 복원
  - `종료`: 저장 삭제 후 타이틀 이동
- [x] 푸시 대비 키 분리 정책 유지: `saveDeviceKey` / `installationId` / `pushToken`
- [x] 웹 저장/이어하기 회귀 검증 절차 문서화: `flutter build web` + 정적 서버 + Playwright
- [x] 웹에서 `랜덤 시작 -> 옵션 나가기 -> 타이틀 즉시 이어하기 표시` 검증

---

## 5. 레거시 정리

- [x] 레거시 탭탭 `BingoCardGame`·`game/components/*` 제거
- [ ] `app_config`·번역·앱 표시 이름 갱신

---

## 6. 출시 전

- [ ] `docs/STORE_METADATA_PLAY_APPSTORE_2026.md` 패키지명·스크린샷·설명
- [ ] 웹 빌드 `base-href` 확인 (`docs/web_build.md`)

---

## 현재 진행 메모

- 룰: **`copiesPerTile` 기반 포커 덱**·**손패 기본 1장(디버그 `1~3` 조절 가능)**·**\(T,D_board,D_hand\)**·**즉시 확정 + 부분 줄 평가 + overlap 보너스**·**원페어는 dead line(0점)**·만료 **25칸 / 현재 덱 전부 소모** — `rummi_poker_grid_v2_instant_confirm_overlap.md`, `game_logic`
- 구조 방향: **Flutter-first 전투 화면 + Flame은 필요 시 연출 레이어만 재도입** 기준 유지
- 코드: 핸드·보드·**`PokerDeck`·`RummiPokerGridSession`**·테스트 + **`GameView` Flutter 전환** 완료. HUD 대시보드/Jester 5슬롯/5×5 보드/단일 손패/하단 액션을 위젯으로 재구성했고, Flame은 후속 효과 레이어 후보로 남겨둠.
- 메타 진행: 스테이지 클리어 후 정산/상점/Jester 매매 흐름이 현재 Flutter 쪽에 연결되어 있다.
- 스테이지 전환: 다음 스테이지 진입 시 **현재 덱 전체 리셋 + 시드 파생 셔플**로 재현 가능하게 맞췄다.
- 이어하기 저장: 1차 구현 완료. `docs/OLD/save_resume_architecture.md` 기준으로 하이브리드(`GetStorage` payload + secure storage key + HMAC) 저장, 타이틀 `이어하기`, 손상 세이브 삭제, 기본 autosave가 연결되어 있다.
- 게임오버 저장 정책: 게임오버 직전에는 현재 스테이지 시작 스냅샷 기준으로 재시도 상태를 보존하고, 팝업에서 `다시하기 / 종료`를 선택한다.
- 웹 검증: 개발용 `flutter run -d chrome` 세션 대신, 현재는 `build/web` 정적 서빙 + Playwright 경로를 표준 회귀 검증 절차로 본다.
- Riverpod 분리: `GameView`는 `GameSessionNotifier`, `TitleView`는 `TitleNotifier` 기준으로 주요 UI 상태를 읽는다.
- 알림 정책: 현재는 **상단 오버레이 알림을 기본값**으로 사용한다. 하단 `SnackBar`는 CTA가 필요하거나, 폼/키보드와 맥락상 더 적합한 경우만 예외적으로 검토한다.
- 모듈화 진행: 상점 / 캐시아웃 / 손패 / Jester / 공용 HUD 위젯은 별도 파일로 분리되었고, 다음 배치는 `GameView` 잔여 orchestration 정리다.
- Jester 점수: 현재는 전투 점수에 직접 반영 가능한 조건형 효과에 더해, `economy` 1차 종료형과 `stateful_growth` 1차까지 반영되었다. 남은 큰 묶음은 `rule_modifier / retrigger`다.
- 상점 정책: 현재는 **실시간 점수 정산에 실제 반영 가능한 Jester만 오퍼로 노출**한다. 미구현 계열은 데이터에 있어도 상점 풀에서 제외한다.
- 카탈로그 운영: 원본 전체 common은 `jesters_common.json`, 현재 런타임용 curated 풀은 `jesters_common_phase5.json`으로 분리한다. 현재 사용 가능 common Jester는 38종이다.
- Jester 표시: 앱은 현재 한글 우선이며, `JesterTranslationScope` 로 카드명/효과/노트를 리소스에서 읽는다.
- Jester UI: 슬롯 카드 본문은 지금 임시로 설명을 줄이고 분류만 보여 준다. 수치와 현재 상태는 상세 패널에서 확인한다.
- 타일 UI: 슈트 아이콘은 두지 않고, face card 여부만 `11/12/13` 하단 중앙 점으로 표시한다.
- 검사 메모: 현재 `SHOP` 버튼은 테스트 편의를 위해 8장 검사 오퍼를 한 번에 띄우는 상태다.
- Stitch: `Rummi Poker Grid - Flame UI Mockups` 프로젝트에서 1차/2차 플레이 화면 생성 완료. 2차안은 에메랄드 필드·보드 지배력·라인 배지 차등이 더 적합함. 다음은 색/간격 토큰 추출 후 Flutter 화면 미세조정에 반영.
- UI 재배치: 모바일 `SafeArea` 중복 패딩 제거, 상단 오버레이 최소화, HUD 압축, Jester 슬롯 카드형 정리, 보드 최대화, 단일 손패 단순화, 하단 버튼 우선순위 재배치 적용.
- 성능 최적화: `StarryBackground`를 그룹 Opacity 방식(래스터 캐싱 + FadeTransition)으로 전환, `GameView` 전환 시 BGM/카탈로그 로딩 지연, 중복 UI 클래스(`TableBackdrop`, `ModalCard`) 공용화. 모든 뷰가 `PhoneFrameScaffold`를 일관되게 사용하도록 통일.
- 정합성 메모: 사용자 확정 규칙은 **현재 성립 줄 즉시 확정**, **overlap 배수 적용**, **줄 확정 시 족보 성립 기여 카드만 제거**다. 세션/테스트는 이 기준으로 갱신되었고, 남은 작업은 하위 문서/UI 표현을 이 기준으로 맞추는 쪽이다.
