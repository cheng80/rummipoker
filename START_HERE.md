# 작업 세션 시작 — 여기부터 읽기

> **역할**: Codex든 Cursor든 새 대화를 열어 작업을 다시 이어갈 때 **가장 먼저** 읽는 문서다.  
> 코딩 규칙은 `CURSOR.md`에 두고, **현재 어디까지 왔는지 / 다음에 무엇을 해야 하는지**는 이 문서가 안내한다.

---

## 대화 시작 시 한 줄

**「`START_HERE.md`와 `docs/rummi_poker_grid_execution_checklist.md`를 보고, 현재 우선 작업인 정산 흐름 / 상점 화면 / Jester 효과 후속부터 이어가자.」**

---

## 1. 필수 순서

| 순서 | 문서 | 할 일 |
|:---:|:---|:---|
| 1 | **이 파일** (`START_HERE.md`) | 아래 §2, §3만 먼저 확인 |
| 2 | [`docs/rummi_poker_grid_execution_checklist.md`](docs/rummi_poker_grid_execution_checklist.md) | 체크 안 된 다음 작업 확인 |
| 3 | [`docs/DESIGN.md`](docs/DESIGN.md) | 현재 화면에 적용할 디자인 기준 확인 |
| 4 | [`docs/rummi_poker_grid_gdd.md`](docs/rummi_poker_grid_gdd.md) | 룰 충돌이 생길 때만 확인 |
| 5 | [`docs/rummi_poker_grid_game_logic.md`](docs/rummi_poker_grid_game_logic.md) | 구현 세부 기준 확인 |
| 6 | [`docs/rummi_poker_grid_next_work_prep.md`](docs/rummi_poker_grid_next_work_prep.md) | 다음 작업 순서/정합성 메모 확인 |

---

## 2. 현재 프로젝트 상태

- 프로젝트는 기존 `빙고 카드` 앱에서 **`Rummi Poker Grid`** 로 대규모 마이그레이션 중이다.
- 핵심 룰은 현재 문서 기준으로 고정되어 있다.
  - `5x5` 보드
  - `12줄` 평가
  - 덱은 `copiesPerTile` 기반 (`총 장수 = 4색 × 13랭크 × copiesPerTile`)
  - 현재 기본값은 `copiesPerTile = 1` 이라 `52장`, 필요 시 `2`로 올리면 `104장`
  - 손패 최대 `1장`
  - 목표 점수 `T`
  - 버림 `D`
  - 죽은 줄은 **줄 확정으로 제거하지 않고**, **보드 타일 하나를 버려서 완화**
  - 줄 확정 시에는 **줄 전체가 아니라, 족보 성립에 기여한 카드만 제거**
- `Removal(C)` 자원 규칙은 **폐기**되었다. 새 대화에서 이 규칙을 다시 살리면 안 된다.

현재 구현 상태 요약:
- 순수 로직: `lib/logic/rummi_poker_grid/` 에 기본 엔진/세션/덱/보드/테스트가 들어와 있다.
- 게임 로직: `lib/logic/rummi_poker_grid/` 의 세션/엔진이 플레이 규칙을 담당한다.
- Flutter 화면: `lib/views/game_view.dart` 에서 **상단 HUD / Jester 5슬롯 / 5x5 보드 / 단일 손패 / 액션 버튼**을 직접 그린다.
- Flame 코드는 당장 핵심 화면 책임에서 한 발 물러났고, 이후 필요 시 **드로우/정산/조커 연출 레이어**로만 재도입하는 방향이 현재 판단이다.
- 디자인 문서: [`docs/DESIGN.md`](docs/DESIGN.md) 를 현재 코드/룰 기준으로 최신화했다.
- 최근 작업:
  - `RummiPokerGridSession.confirmAllFullLines()` 를 **족보 기여 카드만 제거**하도록 수정했다.
  - 손패 한도를 **최대 1장**으로 유지했고, 테스트/문서도 같이 갱신했다.
  - `GameView` 를 **Flutter 위젯 기반 전투 화면**으로 전환했다.
  - 시드 번호는 상단 HUD에서 제거하고 **옵션 다이얼로그에서만 복사 가능**하게 정리했다.
  - Jester 슬롯 5장, 5x5 보드, 단일 손패, 하단 액션 버튼의 밀도를 다시 맞췄다.
  - 목표 점수 달성 시 **실시간 줄 정산 -> Stage Clear 판정 -> Cash Out Bottom Sheet -> Jester Shop 전체 화면 -> 다음 스테이지** 흐름을 붙였다.
  - `data/common/jesters_common.json` 을 읽어 **Jester 상점 / 구매 / 판매 / 보유 슬롯**을 연결했다.
  - 상점은 이제 **바텀시트가 아니라 전체 화면 라우트**이며, 보유 Jester 5슬롯 / 드래그 판매 / 오퍼 리스트 / 다음 스테이지 진입을 포함한다.
  - 다음 스테이지 진입 시 덱은 **`copiesPerTile` 값 그대로 전체 리셋**되고, **`runSeed + stageIndex` 기반 파생 시드 셔플**로 재현 가능하게 맞췄다.
  - 앱 루트에 `JesterTranslationScope` 를 붙여 **Jester 한글 이름/효과 텍스트**를 리소스에서 읽도록 연결했다.
  - 게임 화면에서 장착된 Jester를 누르면 **판매 가능한 모달형 정보 패널**이 뜨고, 상점의 보유 슬롯도 탭으로 상세/판매 확인이 가능하다.
  - 임시 테스트용으로 시작 골드는 `10` 이고, 게임 화면 Jester 헤더 줄에 **`SHOP` 진입 버튼**을 두었다.
  - 현재는 **전투 점수에 직접 반영 가능한 Jester 효과**를 우선 연결했다.
    - `chips_bonus`
    - `mult_bonus`
    - `xmult_bonus`
    - `scholar` 특수 처리
    - 조건: `none`, `suit_scored`, `pair`, `two_pair`, `three_of_a_kind`, `straight`, `flush`, `face_card`, `rank_scored`, `cards_remaining_in_deck`, `remaining_discards`, `owned_jester_count`, `zero_discards_remaining`, `empty_jester_slots`

---

## 3. 지금 가장 중요한 작업

**현재 1순위는 “정산 흐름/Jester 메타/UI 문서 정합성 유지 + 후속 구현”이다.**

즉, 새 세션에서 바로 이어야 할 일:

1. [`docs/rummi_poker_grid_gdd.md`](docs/rummi_poker_grid_gdd.md), [`docs/rummi_poker_grid_game_logic.md`](docs/rummi_poker_grid_game_logic.md), [`docs/rummi_poker_grid_execution_checklist.md`](docs/rummi_poker_grid_execution_checklist.md) 의 덱/만료/메타 진행 기준이 코드와 맞는지 먼저 확인한다.
2. 특히 아래 파일을 우선 본다.
   - [`lib/logic/rummi_poker_grid/jester_meta.dart`](lib/logic/rummi_poker_grid/jester_meta.dart)
   - [`lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart`](lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart)
   - [`lib/views/game_view.dart`](lib/views/game_view.dart)
   - 참고용 [`/Users/cheng80/Desktop/FlutterFrame_work/flame_rummideck/lib/`](</Users/cheng80/Desktop/FlutterFrame_work/flame_rummideck/lib/>)
3. 다음 구현 우선순위는 이 순서다.
   - 실시간 줄 정산 체인과 최종 정산 바텀시트의 역할 경계를 문서/코드에서 고정
   - 아직 미구현인 `stateful_growth / economy / rule_modifier / retrigger` 계열 Jester의 적용 범위 정의
   - 상점 오퍼 노출 정책, 구매/판매/리롤 경제 수치 정리
   - 필요 시 전투/정산 연출만 Flame 레이어로 분리
4. 디자인 작업은 계속 중요하지만, 현재는 **정산 흐름과 메타 루프가 문서/코드에서 다시 어긋나지 않게 유지하는 것**이 우선이다.

룰 정합성에서 특히 확인할 것:
- 덱 장수가 고정 숫자가 아니라 `copiesPerTile`에서 결정된다는 점이 문서 전체에 반영되어 있는지
- `52장 / 104장`을 같은 로직과 같은 UI 흐름으로 지원하는 구조가 문서에 적혀 있는지
- 줄 확정 시 **기본 점수 + 제스터 보너스**가 어떻게 합산되는지 설명이 필요한지
- 스테이지 클리어 후 **상점이 전체 화면**이라는 점과, 다음 스테이지 진입 시 **시드 기반 덱 리셋/셔플**이 문서에 반영되어 있는지
- Jester 한글화/정보 패널/판매 동선이 실제 UI와 같은 말로 정리되어 있는지
- 손패 최대 1장 규칙이 계속 유지되는지

---

## 4. Stitch 관련 메모

- Cursor 쪽 Stitch MCP는 사용 중일 수 있다.
- Codex 쪽은 `~/.codex/config.toml` 에 `stitch` MCP 서버를 추가했다.
- 다만 **지금 핵심은 Stitch 신규 목업 생성보다, 이미 구현된 Flutter 위젯 UI와 메타 루프 문서 기준을 맞추는 것**이다.
- 화면 구조를 다시 크게 갈아엎기 전에는 `DESIGN.md`를 코드 기준으로 유지한다.

---

## 5. 파일 우선순위

새 세션에서 코드 읽기 순서는 아래가 가장 효율적이다.

1. [`START_HERE.md`](START_HERE.md)
2. [`docs/rummi_poker_grid_execution_checklist.md`](docs/rummi_poker_grid_execution_checklist.md)
3. [`docs/rummi_poker_grid_gdd.md`](docs/rummi_poker_grid_gdd.md)
4. [`docs/rummi_poker_grid_game_logic.md`](docs/rummi_poker_grid_game_logic.md)
5. [`lib/views/game_view.dart`](lib/views/game_view.dart)
6. [`lib/logic/rummi_poker_grid/jester_meta.dart`](lib/logic/rummi_poker_grid/jester_meta.dart)
7. [`lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart`](lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart)
8. 필요할 때만 [`docs/DESIGN.md`](docs/DESIGN.md), [`docs/rummi_poker_grid_next_work_prep.md`](docs/rummi_poker_grid_next_work_prep.md)

---

## 6. 세션 종료 전 갱신 규칙

작업을 끊기 전에 최소한 아래는 갱신한다.

1. 끝낸 항목이 있으면 [`docs/rummi_poker_grid_execution_checklist.md`](docs/rummi_poker_grid_execution_checklist.md) 체크 상태를 갱신
2. 덱 장수, 만료, 메타 루프, Jester 효과 범위를 건드렸으면 [`docs/rummi_poker_grid_gdd.md`](docs/rummi_poker_grid_gdd.md), [`docs/rummi_poker_grid_game_logic.md`](docs/rummi_poker_grid_game_logic.md) 같이 수정
3. 디자인 방향이 바뀌었으면 [`docs/DESIGN.md`](docs/DESIGN.md) 수정
4. 새 세션이 바로 이어질 수 있게 이 문서의 §3 “지금 가장 중요한 작업”을 최신 상태로 유지

---

## 7. 한 줄 요약

**다음 세션은 `START_HERE.md`로 시작하고, 현재는 `copiesPerTile` 기반 덱 + Flutter 위젯 전투 화면 + 실시간 정산/캐시아웃/전체화면 상점 흐름 + 전투형 Jester 효과/한글화 기준으로 문서와 코드를 함께 유지하면 된다.**
