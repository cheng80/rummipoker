# 게임 로직 상수·규칙 정리

UI 해상도·레이아웃 등 표시 전용 수치는 제외하고, **코드·문서에 정의된 전투·경제·점수 로직**만 모았다.

**근거 코드**: 주로 `lib/logic/rummi_poker_grid/`, `docs/OLD/rummi_poker_grid_game_logic.md`.  
제스터 카드별 `value` / `xValue` 등은 `data/common/jesters_common_phase5.json`을 따른다.

**제스터 수치·조건 요약표**: [`jesters_common_phase5.md`](./jesters_common_phase5.md) (카드 id별 `baseCost`, `value`, `xValue`, 조건, 한 줄 설명).

---

## 1. 보드·덱·손패 (구조)

| 항목 | 수치 | 설명 |
|------|------|------|
| 그리드 크기 | **5×5** (`kBoardSize = 5`) | 한 줄은 정확히 5칸일 때만 평가 |
| 평가 라인 수 | **12** | 행 5 + 열 5 + 주대각 + 반대각 |
| 타일 숫자 범위 | **1 ~ 13** | 포커 랭크(에이스=1, J/Q/K=11~13) |
| 덱 장수 | **4색 × 13랭크 × `copiesPerTile`** | 기본 `copiesPerTile = 1` → **52장** |
| 손패 상한(기본) | **1장** (`kDefaultMaxHandSize`) | 세션 생성 시 기본값 |
| 블라인드 목표(신규 세션 기본) | **`targetScore = 300`** | `RummiPokerGridSession.create` 초기 블라인드 |
| 스테이지 목표 점수 | 스테이지 1: **300**; 2 이상: **`floor(300 × 1.6^(stage−1))`** | `RummiRunProgress.targetForStage` |
| 제스터 슬롯 상한 | **5** (`maxJesterSlots`) | 장착 개수 제한 |

---

## 2. 족보별 기본 점수 (`gddBaseScore`)

| 족보 | 기본 점수 | 비고 |
|------|------------|------|
| High Card | **0** | 죽은 줄 |
| One Pair | **0** | 죽은 줄 |
| Two Pair | **25** | |
| Three of a Kind | **40** | |
| Straight | **70** | 일반 연속 또는 휠(10–11–12–13–1) |
| Flush | **50** | |
| Full House | **80** | |
| Four of a Kind | **100** | |
| Straight Flush | **150** | |

---

## 3. 한 줄 최종 점수 (제스터 합성식)

| 단계 | 식 | 설명 |
|------|-----|------|
| 칩 합 | `chips = baseScore + chipsBonus` | 족보 기본점 + 칩 보너스 합 |
| 멀트 계수 | `multFactor = 1 + (multBonus / 20)` | 멀트 보너스 **20당** 배율 +1 |
| 최종 | `round(max(0, chips × multFactor × xmultBonus))` | `chips ≤ 0`이면 **0** |
| X멀트 | `xmultBonus` 기본 **1.0** | 조건에 따라 곱(예: 빈 제스터 슬롯 수만큼 `xValue` 거듭제곱) |

**특례 (Scholar)**: 에이스당 칩은 카드 `value`, 멀트는 코드상 **에이스당 +4** 고정.

구현: `jester_meta.dart` — `_composeScore`, Scholar 분기.

---

## 4. 블라인드 클리어·누적

| 항목 | 규칙 |
|------|------|
| 클리어 조건 | `scoreTowardBlind >= targetScore` |
| 확정 시 | 완성·점수 있는 줄들의 점수 합이 `scoreTowardBlind`에 가산 |

---

## 5. 블라인드 자원(버림) 초기값 (`RummiBlindState`)

| 필드 | 기본값 | 의미 |
|------|--------|------|
| `boardDiscardsRemaining` / max | **4** | 보드 타일 버림 |
| `handDiscardsRemaining` / max | **2** | 손패 버림 |

---

## 6. 만료(v1) 조건 (`game_logic` §5.2)

| 조건 | 내용 |
|------|------|
| 보드 만료 | `boardDiscardsRemaining == 0` 이고 보드가 **25칸 전부 점유** |
| 덱 소진 | 드로우 불가(덱 비움) 등 |

---

## 7. 상태형 제스터 — 코드 고정 증감

| 카드 | 동작 | 수치 |
|------|------|------|
| `popcorn` | 장착 시 초기 상태 | `state = card.value` (데이터, 보통 **20**) |
| `popcorn` | 스테이지 종료 후 | 상태 **−4** (0 미만이면 0) |
| `ice_cream` | 장착 시 초기 상태 | `state = card.value` (데이터, 보통 **100**) |
| `ice_cream` | 줄 확정 후 | 상태 **−5** (0 미만이면 0) |
| `green_jester` | 줄 확정 시 | **+1** |
| `green_jester` | 디스카드 사용 시 | **−1** |
| `ride_the_bus` | 확정 줄에 스코어링 페이스 카드 있음 | **0**으로 리셋 |
| `ride_the_bus` | 페이스 카드 없음 | **+1** |
| `supernova` | 멀트 보너스 | `currentHandPlayedCount` (해당 족보 이번 런 플레이 횟수) |

페이스 카드: 타일 번호 **11, 12, 13**.

---

## 8. 제스터 점수 컨텍스트 (`RummiJesterScoreContext`)

| 필드 | 용도 예 |
|------|---------|
| `discardsRemaining` | 남은 버림 → 배너/미스틱 서밋 등 |
| `cardsRemainingInDeck` | 덱 잔량 × 보너스 |
| `ownedJesterCount` | 보유 제스터 수 × 보너스 등 |
| `maxJesterSlots` | 빈 슬롯 계산(스텐실 등) |
| `stateValue` | 상태형 슬롯 값 |
| `currentHandPlayedCount` | 슈퍼노바 등 |

---

## 9. 경제·상점 (`RummiEconomyConfig` / `RummiRunProgress`)

| 항목 | 값 |
|------|-----|
| 시작 골드 | **10** |
| 스테이지 클리어 기본 보상 | **10** Gold |
| 남은 보드 버림당 보너스 | **+5** Gold / 회 |
| 남은 손패 버림당 보너스 | **+2** Gold / 회 |
| 상점 리롤 기본 비용 | **5** Gold |
| 리롤할 때마다 비용 증가 | **+1** Gold |
| 상점 오퍼 개수 | **3** |
| 판매가 | `baseCost ~/ 2`, 최소 **1** |
| 구매가 | 카드 데이터 **`baseCost`** |

**라운드 종료 이코노미 제스터 (예시)**

- `egg`, `golden_jester`: 카드 `value`만큼 Gold
- `delayed_gratification`: `value × (남은 보드 버림 + 남은 손패 버림)`

---

## 10. 턴/줄 위험도 (`LineHazardTuning`)

| 필드 | 기본값 | 설명 |
|------|--------|------|
| `deadLineCarryPerTurnAdd` | **0** | 죽은 줄 방치 시 턴당 가산(미사용) |
| `evaluatedLineIdlePerTurnAdd` | **0** | 완성 줄 미확정 시 턴당 가산(미사용) |

현재 빌드는 효과 **0** (`LineHazardTuning.none`).

---

## 11. 스테이지 셔플 시드 파생

`deriveStageShuffleSeed(runSeed, stageIndex)`:

- `(runSeed * 1103515245 + 12345 + stageIndex * 1013904223) & 0x7fffffff`
- 결과가 **0**이면 **`stageIndex + 1`** 사용

---

## 변경 시 참고

- 족보 점수: `lib/logic/rummi_poker_grid/hand_rank.dart` — `gddBaseScore`
- 합성식·제스터: `lib/logic/rummi_poker_grid/jester_meta.dart`
- 블라인드·세션: `lib/logic/rummi_poker_grid/rummi_blind_state.dart`, `rummi_poker_grid_session.dart`
- 경제·스테이지 스케일: `jester_meta.dart` 내 `RummiEconomyConfig`, `RummiRunProgress`
- 제스터 카드 표: `data/common/jesters_common_phase5.json` ↔ 문서 `docs/OLD/jesters_common_phase5.md`
