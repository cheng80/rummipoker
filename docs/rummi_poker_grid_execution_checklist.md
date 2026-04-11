# Rummi Poker Grid — 실행 체크리스트

> 순서대로 진행. 항목을 끝낼 때마다 `[ ]` → `[x]`로 갱신한다.  
> 기획·규칙: `rummi_poker_grid_gdd.md` / 구현 스펙: `rummi_poker_grid_game_logic.md` / 구조: `rummi_poker_grid_migration_plan.md`
> 착수 준비 메모: `rummi_poker_grid_next_work_prep.md`

---

## 0. 기획 고정 (GDD·게임 로직 문서)

- [x] **덱**: `copiesPerTile` 기반 (`총 장수 = 4×13×copiesPerTile`) — **52/104 공용 처리 가능**
- [x] **평가 라인**: 행·열·주/반 대각 = **12줄** (`rummi_poker_grid_v1_assumptions.md`)
- [x] **Straight**: 일반 연속 + 휠 **10–11–12–13–1** (`HandEvaluator._isStraight`)
- [x] **손패 한도**: **최대 1장** — 드로우/버림 보충/UI 모두 이 기준
- [x] **죽은 줄 / 방치**: 죽은 줄 = 하이카드·원페어; **방치·대기 ±** 미확정 — `LineHazardTuning` 기본 0 (추후 수식 가능)
- [x] **일괄 확정**: 완성 줄 **개수 제한 없음**; 전용 버튼·완성줄 탭 동일 → 대기 줄 **전부** 한 번에
- [x] **확정 제거 범위**: 줄 전체가 아니라 **족보 성립에 실제 기여한 카드만 제거**
- [x] **블라인드 자원**: §8 — **\(T\)·\(D\)** · 족보 확정 **횟수 제한 없음** · 배치 턴 무제한
- [x] **만료**: **\(D=0\)** 후 **25칸 만재**, 또는 **현재 덱 전부 소모** (`copiesPerTile` 값과 무관하게 동일 로직)
- [x] **`RummiBlindState`** + **`PokerDeck`(`copiesPerTile` 기반)** + **`RummiPokerGridSession`** (드로우·배치·버림·일괄 확정·만료 신호) — `lib/logic/rummi_poker_grid/` (`test/logic/rummi_session_test.dart`)
- [x] **빈 칸이 있는 줄**: **5칸 다 찰 때만** 판정
- [x] **조커**: **메타(장착 슬롯)만** — 보드 타일 아님

---

## 0.5 비주얼·Stitch (참고 디자인)

> 기존 루미큐브 계열 게임과 **동일 타일 렌더링 클래스**를 쓰는 전제에서, **색·비율**을 맞추고 Stitch로 목업을 뽑는다. (`migration_plan` §1 원칙 5·단계 0.5)

- [ ] **참고 소스**: 다른 프로젝트(예: `flame_rummideck`)의 타일 색(`TileColor` → 앱 팔레트), `BattleTileCard` 시각 규칙(테두리·그라데이션·숫자 대비) 정리
- [ ] **톤**: 다크 그린 필·세로 모바일·상단 스코어·하단 손패·액션 버튼 구획 등 레퍼런스 스크린과의 대응표 (발라트로식 HUD 등은 **참고만**)
- [x] **Google Stitch MCP**: 위 팔레트·구획을 넣은 **프롬프트**로 참고 화면 생성 (`projects/6203966996273785875`)
- [ ] **산출물 정리**: Stitch/캡처에서 **색 hex·간격·폰트 역할**만 추출해 `docs/` 메모 또는 앱 테마 상수 초안에 반영 (Flutter 게임 화면 다듬기 단계)

---

## 1. 순수 로직 (`lib/logic/rummi_poker_grid/`)

- [x] 모델: `Tile` / `TileColor`, 보드 5×5, **대각 2줄** (`diagMain` / `diagAnti`)
- [x] **덱 공용화** `PokerDeck`·`buildStandardPokerDeck({copiesPerTile})`·`remainingAfterPlaced`; `WasteTray`(1); **`RummiBlindState`**(\(T,D\), 누적 점수)
- [x] `HandEvaluator`: 5장 → 족보·점수 (단위 테스트) — 휠 스트레이트·죽은 줄 플래그 반영
- [x] 엔진: 행·열·**주/반 대각** 평가 + **`listFullLines`** (12줄) (`RummiPokerGridEngine`)
- [x] **`RummiPokerGridSession`**: 드로우·배치·버림(\(D\))·**일괄 확정**·`evaluateExpirySignals` — 세부는 `rummi_poker_grid_session.dart`
- [ ] GDD §3·§8과 엔진 이벤트 **대응표** (`docs/` 또는 `game_logic` 부록) — 선택

---

## 2. Riverpod

- [ ] 세션·점수 요약 등 UI 스냅샷을 `Notifier`에 연결 (기존 `rummi_session` 확장 또는 신규)
- [ ] Flame ↔ `ref.read` 주입 패턴 확정 (`docs/riverpod_architecture.md` 참고)

---

## 3. Runtime / Effects

- [x] `GameView` Flutter 위젯 기반 화면 — HUD·Jester 5슬롯·5×5 보드·단일 손패·드로우/줄 확정/버림/선택 해제
- [x] 타일 렌더 재사용 (`rummikub_tile_canvas.dart`) + 손패 탭(선택) + 빈 칸 탭(배치)
- [x] 점수 줄 기여 카드 하이라이트 및 선택/버림 상태색 반영
- [x] 목표 점수 달성 시 `실시간 줄 정산 -> Stage Clear 판정 -> Cash Out -> Jester Shop` 흐름
- [x] `data/common/jesters_common.json` 기반 Jester 상점 / 구매 / 판매 / 보유 슬롯
- [x] 전투 점수에 직접 반영 가능한 Jester 효과 연결 (`chips_bonus`, `mult_bonus`, `xmult_bonus`, `scholar`)
- [x] 게임 화면 장착 Jester 탭 시 모달형 정보 패널 + 판매 버튼
- [x] 실시간 줄 정산 중 활성 Jester 강조 + 카드 슬롯 위치 배점 버스트 연출
- [ ] Flame는 필요 시 드로우/정산/조커 연출 전용 레이어로 재도입
- [ ] 웨이스트 슬롯 UI
- [ ] 태블릿 `FittedBox`+`MediaQuery` 경로에서 실기기 확인 (`docs/responsive-phone-frame-layout.md`)

---

## 4. Flutter 셸

- [x] `GameView` — `RummiPokerGridSession(runSeed)` 직결 + 만료 다이얼로그·스낵바 + 옵션 다이얼로그 시드 복사
- [ ] `TitleView` 카피·진입 문구 최종 다듬기
- [x] 오버레이/바텀시트: 옵션 다이얼로그, 스테이지 클리어 오버레이, 캐시아웃 바텀시트
- [x] 상점 전체 화면 라우트 + 보유 슬롯 상세/판매 + 리롤 확인 다이얼로그

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

- 룰: **`copiesPerTile` 기반 포커 덱**·**손패 최대 1장**·**\(T,D\)**·죽은 줄은 **보드 버림으로만 완화**·만료 **25칸 / 현재 덱 전부 소모** — `rummi_poker_grid_gdd.md` §2.2·§8, `game_logic`, `v1_assumptions`
- 플랜 재정렬: `rummi_poker_grid_migration_plan.md` §1.1 스냅샷·§5 단계 1~3
- 코드: 핸드·보드·**`PokerDeck`·`RummiPokerGridSession`**·테스트 + **`GameView` Flutter 전환** 완료. HUD 대시보드/Jester 5슬롯/5×5 보드/단일 손패/하단 액션을 위젯으로 재구성했고, Flame은 후속 효과 레이어 후보로 남겨둠.
- 메타 진행: 스테이지 클리어 후 정산/상점/Jester 매매 흐름이 현재 Flutter 쪽에 연결되어 있다.
- 스테이지 전환: 다음 스테이지 진입 시 **현재 덱 전체 리셋 + 시드 파생 셔플**로 재현 가능하게 맞췄다.
- Jester 점수: 현재는 전투 점수에 직접 반영 가능한 조건형 효과만 우선 지원하며, `stateful_growth / economy / rule_modifier / retrigger` 계열은 후속이다.
- Jester 표시: 앱은 현재 한글 우선이며, `JesterTranslationScope` 로 카드명/효과/노트를 리소스에서 읽는다.
- Stitch: `Rummi Poker Grid - Flame UI Mockups` 프로젝트에서 1차/2차 플레이 화면 생성 완료. 2차안은 에메랄드 필드·보드 지배력·라인 배지 차등이 더 적합함. 다음은 색/간격 토큰 추출 후 Flutter 화면 미세조정에 반영.
- UI 재배치: 모바일 `SafeArea` 중복 패딩 제거, 상단 오버레이 최소화, HUD 압축, Jester 슬롯 카드형 정리, 보드 최대화, 단일 손패 단순화, 하단 버튼 우선순위 재배치 적용.
- 정합성 메모: 사용자 확정 규칙은 **죽은 줄을 버림(D)으로만 완화**하고, **줄 확정 시에는 족보 성립에 기여한 카드만 제거**하는 것이다. 세션/테스트는 이 방향으로 갱신되었고, 남은 작업은 문서/UI 표현을 이 기준으로 맞추는 쪽이다.
