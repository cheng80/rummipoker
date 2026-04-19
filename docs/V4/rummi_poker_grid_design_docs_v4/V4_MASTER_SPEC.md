# Rummi Poker Grid V4 Master Spec

> 문서 성격: master spec
> 코드 반영 상태: current baseline + target roadmap
> 사용법: 구현자는 이 문서를 먼저 읽고, 세부 항목은 개별 V4 문서를 참조한다.

## 1. V4 정의

Rummi Poker Grid V4는 “현재 작동하는 즉시 확정 보드 전투 프로토타입을 장기 제품 구조로 흡수 확장하기 위한 기준”이다.

V4는 current build를 부정하지 않는다. 현재 build는 이미 다음 핵심을 확보했다.

- 5x5 보드
- 12라인 평가
- 부분 줄 평가
- 즉시 확정
- One Pair 0점 dead line
- overlap 보너스
- contributor만 제거
- Jester 점수 보정
- cash-out
- Jester shop
- next stage
- active run save/load
- stageStartSnapshot restart

## 2. V4 기본 규칙

| 항목 | V4 기본값 |
|---|---|
| Board | 5 x 5 |
| Lines | 12 |
| Deck | `4 * 13 * copiesPerTile` |
| copiesPerTile | 1 |
| Hand size | 기본 1, debug 1~3 |
| Board discard | 4 |
| Hand discard | 2 |
| Confirm | scoring candidate line 즉시 확정 |
| Removal | contributor cell union만 제거 |
| Dead line | High Card, One Pair |
| Overlap | alpha 0.3, cap 2.0 |
| Stage loop | current 유지 |
| Save | active run save v2 유지 |

## 3. Score Table

| Rank | Score | V4 의미 |
|---|---:|---|
| High Card | 0 | dead line |
| One Pair | 0 | dead line |
| Two Pair | 25 | scoring |
| Three of a Kind | 40 | scoring |
| Flush | 50 | scoring |
| Straight | 70 | scoring |
| Full House | 80 | scoring |
| Four of a Kind | 100 | scoring |
| Straight Flush | 150 | scoring |

V4 기본 ruleset에서 One Pair는 계속 0점이다.

## 4. Confirm Flow

```text
Player taps Confirm
→ evaluate 12 lines
→ filter Two Pair or better
→ collect contributor cells
→ compute overlap contribution count
→ apply overlap multiplier
→ apply equipped Jesters by slot order
→ create line breakdowns
→ remove contributor union
→ move removed tiles to eliminated
→ settlement animation
→ apply line scores
→ if target met: cash-out → shop → next stage
→ save
```

## 5. Current Code Anchors

| Anchor | 파일 |
|---|---|
| Combat session | `lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart` |
| Hand rank | `lib/logic/rummi_poker_grid/hand_rank.dart` |
| Hand evaluation | `lib/logic/rummi_poker_grid/hand_evaluator.dart` |
| Board scan | `lib/logic/rummi_poker_grid/rummi_poker_grid_engine.dart` |
| Run/economy/Jester | `lib/logic/rummi_poker_grid/jester_meta.dart` |
| Save | `lib/services/active_run_save_service.dart` |
| Provider orchestration | `lib/providers/features/rummi_poker_grid/game_session_notifier.dart` |
| Runtime UI | `lib/views/game_view.dart` |

## 6. V4 Target Structure

장기 target:

```text
Run
└─ Sector[]
   └─ Station[]
      ├─ Entry
      ├─ Pressure
      ├─ Lock
      ├─ Combat Objective
      ├─ Reward Settlement
      └─ Market
```

Content target:

```text
Jester
Run Kit
Permit
Glyph
Orbit
Echo
Sigil
Risk Grade
Trial
Archive
```

Data target:

```text
ProfileState
ActiveRunState
CheckpointState
RunHistoryRecord
ArchiveState
Stats
```

## 7. Migration Order

```text
0. V4 docs lock
1. regression tests
2. compatibility wrappers
3. ruleset config skeleton
4. Station terminology UI-only
5. MarketOffer adapter
6. save/checkpoint adapter
7. Station modifier prototype
8. Archive/stats read model
9. balance pass
10. optional code rename
```

## 8. Do Not Do

V4 작업에서 바로 하면 안 되는 것:

- One Pair를 기본 10점으로 변경
- current save를 DB로 즉시 교체
- `RummiBlindState` 같은 코드명을 바로 rename
- Jester id 변경
- Station target을 current implementation처럼 문서화
- 경제 수치와 전투 룰을 한 PR에서 동시에 변경
- save schema와 provider 구조를 한 PR에서 동시에 변경

## 9. First Implementation PR Recommendation

첫 PR은 docs-only 또는 tests-only가 좋다.

권장 첫 작업:

```text
V4 문서 추가
→ current combat regression test 추가
→ save/load regression test 추가
→ confirmScoringLines wrapper 추가
```

코드는 지금 작동하는 프로토타입이므로, 기능 확장은 보호 테스트 뒤에 진행한다.
