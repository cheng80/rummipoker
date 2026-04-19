# Current Code Map

문서 목적: `V4` 작성 AI 또는 후속 구현자가 **어디를 먼저 읽어야 하는지** 빠르게 판단하게 하는 코드 맵이다.

이 문서는 “파일 목록”이 아니라 “책임 경계”를 설명한다.

---

## 1. 가장 먼저 볼 파일

우선순위는 아래 순서가 좋다.

1. `START_HERE.md`
2. `docs/CURRENT_SYSTEM_OVERVIEW.md`
3. `lib/logic/rummi_poker_grid/`
4. `lib/providers/features/rummi_poker_grid/`
5. `lib/views/game_view.dart`
6. `lib/services/active_run_save_service.dart`
7. `docs/archive/`

---

## 2. 코어 전투 로직

### 2.1 `lib/logic/rummi_poker_grid/models/tile.dart`

역할:

- 타일 모델
- 색과 숫자 표현
- `copiesPerTile` 기반 물리 타일 개념의 기초

여기서 확인할 것:

- 타일 identity
- 색 enum
- 타일 snapshot 기초 구조

### 2.2 `lib/logic/rummi_poker_grid/models/poker_deck.dart`

역할:

- 표준 덱 생성
- 셔플
- 남은 카드 스냅샷
- `copiesPerTile` 기반 덱 총량 유지

여기서 확인할 것:

- 52/104 대응 구조
- 표준 덱 생성 순서
- draw pile snapshot 방식

### 2.3 `lib/logic/rummi_poker_grid/models/board.dart`

역할:

- 5x5 보드 저장
- 셀 접근
- 스냅샷 / 복원

### 2.4 `lib/logic/rummi_poker_grid/hand_rank.dart`

역할:

- 현재 족보 enum
- 현재 기본 점수표
- dead line 정의

중요:

- 현재는 `onePair = 0`
- V4 작성 시 현재 구현 사실 확인의 기준 파일 중 하나다.

### 2.5 `lib/logic/rummi_poker_grid/hand_evaluator.dart`

역할:

- 줄 단위 최고 족보 판정
- contributor index 계산
- Straight / Flush / Full House 등 현재 규칙 구현

여기서 확인할 것:

- 부분 줄 판정 방식
- contributor 계산 방식
- `10-11-12-13-1` 처리 여부

### 2.6 `lib/logic/rummi_poker_grid/rummi_poker_grid_engine.dart`

역할:

- 행/열/대각선 평가
- 현재 보드의 평가 가능한 라인 목록 생성

여기서 확인할 것:

- 줄 스캔 범위
- occupied count 처리
- 부분 줄도 평가하는 구조

### 2.7 `lib/logic/rummi_poker_grid/rummi_blind_state.dart`

역할:

- 현재 stage 목표 점수
- board discard / hand discard 자원 상태

중요:

- 이름은 `blind`지만 현재 의미는 stage 전투 자원 상태다.

### 2.8 `lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart`

역할:

- 현재 전투 세션의 핵심 퍼사드
- 드로우
- 배치
- 버림
- 확정
- 만료 신호
- 다음 stage 준비
- 세션 snapshot/restore

이 파일이 담당하는 핵심:

1. 현재 session 상태의 truth source
2. confirm 결과 계산과 contributor 제거
3. overlap 배수 적용
4. draw / board discard / hand discard 규칙
5. stage 전환 시 덱 리셋/셔플

`V4` 작성 시 가장 중요하게 읽어야 하는 파일 중 하나다.

---

## 3. Jester / economy / run progress

### 3.1 `lib/logic/rummi_poker_grid/jester_meta.dart`

역할:

- Jester 카드 모델
- 카탈로그 로드
- 상점 오퍼
- 런 진행도
- economy 보상
- stateful Jester 값
- played hand count
- 상점 구매/판매/리롤

이 파일이 실질적으로 품는 것:

1. Jester 데이터 해석
2. 점수 보정 계산
3. stage clear cash-out 계산
4. stage 인덱스와 목표 점수 계산
5. shop flow의 핵심 상태

주의:

- 장기적으로는 분리될 가능성이 높지만, **현재는 Jester + economy + run progress가 한 축에 모여 있다.**

### 3.2 `data/common/jesters_common_phase5.json`

역할:

- 현재 curated runtime common Jester 카탈로그

여기서 확인할 것:

- 실제 사용 카드 id
- rarity / baseCost / effectType / conditionType

---

## 4. 저장 / 이어하기

### 4.1 `lib/services/active_run_save_service.dart`

역할:

- active run 저장
- active run 로드
- 무결성 검증
- stage start snapshot 캡처
- save schema version 관리

핵심 개념:

1. `ActiveRunRuntimeState`
2. `ActiveRunStageSnapshot`
3. `SavedSessionData`
4. `SavedRunProgressData`

이 파일이 의미하는 것:

- 현재 저장은 단일 active run snapshot 중심
- `stageStartSnapshot`이 구조적으로 중요
- `V4` DB/저장 설계 시 반드시 먼저 읽어야 한다

### 4.2 `lib/utils/storage_helper.dart`

역할:

- 실제 로컬 저장 래퍼

### 4.3 `docs/archive/save_resume_architecture.md`

역할:

- 현재 저장 정책의 배경 설명
- save scope
- integrity layer 설계 의도

---

## 5. 상태 관리

### 5.1 `lib/providers/features/rummi_poker_grid/game_session_state.dart`

역할:

- 전투 화면이 구독하는 런타임 UI 상태 스냅샷
- mutable session/runProgress를 품고 revision으로 redraw 트리거

포함 상태:

- session
- runProgress
- stageStartSnapshot
- activeRunScene
- 선택 상태
- Jester overlay 선택
- settlement flow 상태

### 5.2 `lib/providers/features/rummi_poker_grid/game_session_notifier.dart`

역할:

- 현재 전투 화면의 핵심 비즈니스 오케스트레이터

책임:

1. 새 세션 시작 / restore
2. restart current stage
3. 선택 상태 변경
4. confirmLines
5. cash-out 준비
6. shop open / reroll / buy / sell
7. 다음 stage 진입
8. 배치 / 드로우 / 버림 액션 처리

주의:

- 순수 로직 파일은 아니지만, 현재 프로토타입의 실제 흐름은 이 파일을 읽어야 보인다.

### 5.3 `lib/providers/features/rummi_poker_grid/title_notifier.dart`

역할:

- continue availability 검사
- 저장 삭제
- stored run 로드 진입

### 5.4 `lib/providers/features/settings/`

역할:

- 음량 / 설정 상태

---

## 6. 화면 계층

### 6.1 `lib/views/title_view.dart`

역할:

- 타이틀 UI
- 이어하기 / 랜덤 시작 / 시드 시작
- 디버그 픽스처 시작

### 6.2 `lib/views/game_view.dart`

역할:

- 전투 화면 orchestration
- notifier 호출
- save trigger
- SFX / overlay / 네비게이션
- shop 화면 전환

현재 의미:

- UI와 비즈니스 분리가 어느 정도 되었지만,
- 실제 런타임 흐름을 보려면 이 파일도 반드시 같이 봐야 한다.

### 6.3 `lib/views/game/widgets/`

주요 파일:

- `game_shared_widgets.dart`
- `game_jester_widgets.dart`
- `game_hand_zone.dart`
- `game_cashout_widgets.dart`
- `game_shop_screen.dart`
- `game_options_dialog.dart`

역할:

- 전투 화면 조각 위젯
- 상점 전체 화면
- game over / 옵션 / HUD / 보드 / 액션 버튼

### 6.4 `lib/widgets/phone_frame_scaffold.dart`

역할:

- 공통 phone frame 레이아웃

### 6.5 `lib/widgets/starry_background.dart`

역할:

- 공통 배경

---

## 7. 테스트 파일

### 7.1 `test/logic/rummi_board_engine_test.dart`

검증 내용:

- 부분 줄 평가
- 줄 판정 결과
- 대각선 / 스트레이트 기본 동작

### 7.2 `test/logic/rummi_session_test.dart`

검증 내용:

- 덱 보존 총량
- draw / discard
- confirm
- contributor 제거
- stage transition
- expiry signal

### 7.3 `test/providers/game_session_notifier_test.dart`

검증 내용:

- notifier 수준 상태 변경
- debug hand size 반영 등

이 테스트들은 `V4` 문서 작성 시 “현재 구현 사실”의 보조 근거로 쓸 수 있다.

---

## 8. 코드 경계 정리

현재 경계는 아래처럼 이해하면 된다.

### 8.1 순수 로직에 가까운 층

- `lib/logic/rummi_poker_grid/`

### 8.2 프로토타입 런 메타와 점수 보정 층

- `lib/logic/rummi_poker_grid/jester_meta.dart`

### 8.3 앱 상태 오케스트레이션 층

- `lib/providers/features/...`

### 8.4 UI orchestration 층

- `lib/views/`
- `lib/views/game/widgets/`

### 8.5 persistence 층

- `lib/services/active_run_save_service.dart`
- `lib/utils/storage_helper.dart`

---

## 9. V4 작성 시 같이 봐야 하는 보조 문서

1. `START_HERE.md`
2. `docs/CURRENT_SYSTEM_OVERVIEW.md`
3. `docs/CURRENT_TO_V4_GAP.md`
4. `docs/archive/rummi_poker_grid_gdd.md`
5. `docs/archive/rummi_poker_grid_game_logic.md`
6. `docs/archive/save_resume_architecture.md`
7. `docs/archive/rummi_poker_grid_execution_checklist.md`

---

## 10. 짧은 결론

현재 코드에서 가장 중요한 축은 아래 4개다.

1. `rummi_poker_grid_session.dart`
2. `jester_meta.dart`
3. `game_session_notifier.dart`
4. `active_run_save_service.dart`

`V4`를 다시 쓰는 AI는 이 4개와 `START_HERE.md`만 정확히 읽어도 현재 시스템의 뼈대를 거의 파악할 수 있다.
