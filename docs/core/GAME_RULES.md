# 게임 규칙

이 문서는 전투에서 무엇이 가능한지 설명한다. 처음 읽을 때는 ‘보드와 평가 라인’, ‘행동과 조건’, ‘확정 처리’만 먼저 보면 된다. 코드 이름은 테스트와 맞춰야 하므로 그대로 둔다.

## 보드와 점수 줄

- 보드는 5×5, 좌표는 row와 column 각각 0..4다.
- 평가 라인은 행 5개, 열 5개, 주대각선 1개, 역대각선 1개로 총 12개다.
- 빈 칸이 있는 줄도 현재 놓인 타일만으로 평가한다.
- 점수 후보는 `High Card`와 `One Pair`를 제외한 족보다. 이 둘은 현재 점수를 주지 않는 dead line이다.

기본값은 [rummi_ruleset.dart](../../lib/logic/rummi_poker_grid/rummi_ruleset.dart)의 `RummiRuleset.currentDefaults`와 `kCurrentEvaluationLineCount`가 소유한다.

## 덱과 손에 든 타일

- 타일은 네 색과 숫자 1..13, 물리 identity로 구성된다.
- 기본 덱은 `4 × 13 × copiesPerTile`이며 기본 `copiesPerTile`은 1이다.
- 기본 최대 손패는 1장이다. 현재 ruleset의 debug 범위는 1..3장이다.
- 드로우는 손패가 최대치보다 작고 덱이 비어 있지 않을 때만 성공한다.
- 기본 draw/place/discard/move 흐름에서는 덱, 손패, 보드, 제거 더미의 타일 합이 전투의 초기 덱 크기를 보존한다. `emergency_draw` 같은 명시적 새 타일 생성·복사 효과는 예외이며, 현재 구현은 덱을 소모하지 않고 손패에 새 타일을 추가할 수 있다([item_effect_handlers.dart](../../lib/logic/rummi_poker_grid/item_effect_handlers.dart), [item_effect_runtime_test.dart](../../test/logic/item_effect_runtime_test.dart)).

## 행동과 가능한 조건

| 행동 | 성공 조건 | 성공 결과 | 실패 시 불변식 |
|---|---|---|---|
| 드로우 | 손패 여유가 있고 덱이 비어 있지 않음 | 덱 위 타일 1장을 손패에 추가 | 상태 변화 없음 |
| 배치 | 타일이 손패에 있고 목적지가 비었으며 Boss 금지칸이 아님 | 손패 타일을 목적지로 이동 | 손패와 보드 유지 |
| 보드 버림 | 보드 버림이 1 이상이고 선택 칸에 타일이 있음 | 자원 1 소모, 타일을 제거 더미로 이동, 손패 여유 시 1장 드로우 | 자원과 타일 위치 유지 |
| 손패 버림 | 손패 버림이 1 이상이고 선택 타일이 손패에 있음 | 자원 1 소모, 타일을 제거 더미로 이동, 가능하면 1장 드로우 | 자원과 손패 유지 |
| 보드 이동 | 보드 이동이 1 이상, source에 타일 존재, destination이 비었고 Boss 금지칸이 아님 | 자원 1 소모, 타일 위치 변경, 이동 이력 기록 | 자원과 보드 유지 |
| 확정 | 현재 보드에 non-dead-line 점수 줄이 1개 이상 있음 | 모든 점수 줄 계산, contributor 합집합 제거, 정산 결과 생성 | 점수 줄이 없으면 `nothing`, 보드 유지 |

기본 전투 자원은 보드 버림 4회, 손패 버림 2회, 보드 이동 3회다. 난이도와 Blind에 따라 숫자가 달라질 수 있으므로 실제 전투에서는 `RummiBlindState`에 들어 있는 값을 사용한다.

## 족보 ID와 기본 점수

아래 ID와 점수는 [hand_rank.dart](../../lib/logic/rummi_poker_grid/hand_rank.dart)의 `RummiHandRank`와 `gddBaseScore`를 그대로 따른다.

| ID | 플레이어 명칭 | 기본 점수 | 판정 핵심 | Contributor |
|---|---|---:|---|---|
| `highCard` | 하이카드 | 0 | 다른 족보 없음 | 없음 |
| `onePair` | 원페어 | 0 | 같은 숫자 2장 | 같은 숫자 2장; dead line이라 기본 확정 대상 아님 |
| `twoPair` | 투 페어 | 25 | 서로 다른 pair 2개 | pair 4장 |
| `threeOfAKind` | 트리플 | 40 | 같은 숫자 3장 | 같은 숫자 3장 |
| `straight` | 스트레이트 | 70 | 5장 연속 숫자 | 5장 전체 |
| `flush` | 플러시 | 50 | 같은 색 5장 | 5장 전체 |
| `fullHouse` | 풀하우스 | 80 | 같은 숫자 3장과 다른 숫자 2장 | 5장 전체 |
| `fourOfAKind` | 포카드 | 100 | 같은 숫자 4장 | 같은 숫자 4장 |
| `straightFlush` | 스티플 | 150 | 같은 색 5장 연속 숫자 | 5장 전체 |
| `prismStraight` | 프리즘 스트레이트 | 90 | 스트레이트이며 네 색을 모두 포함 | 5장 전체 |
| `crownFourOfAKind` | 크라운 포카드 | 130 | 11..13 숫자의 포카드 | 같은 숫자 4장 |
| `lowStraightFlush` | 로우 스티플 | 180 | 같은 색 `1-2-3-4-5` | 5장 전체 |
| `royalStraightFlush` | 로얄플러시 | 200 | 같은 색 `10-11-12-13-1` | 5장 전체 |
| `fiveOfAKind` | 파이브카드 | 220 | 물리 identity가 다른 같은 숫자 5장 | 5장 전체 |
| `flushHouse` | 플러시 하우스 | 240 | 같은 색 안에서 3장+2장 | 5장 전체 |
| `flushFive` | 플러시 파이브 | 260 | 같은 색·같은 숫자 5장 | 5장 전체 |

`highCard`와 `onePair`만 dead line이다. Straight는 일반 `1-2-3-4-5`부터 `9-10-11-12-13`까지와 `10-11-12-13-1`을 허용한다. Flush와 Straight 계열은 5장일 때만 성립한다.

## Partial Evaluation

| 현재 줄의 타일 수 | 가능한 평가 |
|---:|---|
| 0 | 엔진의 점수 줄 목록에 없음 |
| 1 | `highCard` |
| 2 | `onePair`, `highCard` |
| 3 | `threeOfAKind`, `onePair`, `highCard` |
| 4 | `fourOfAKind`, `twoPair`, `threeOfAKind`, `onePair`, `highCard` |
| 5 | 16개 족보 중 조건에 맞는 최상위 판정 |

부분 평가는 빈 칸을 압축하지 않고 원래 줄 좌표를 contributor index로 돌려준다. 예를 들어 5칸 중 index 1, 2, 4에 같은 숫자 타일이 있으면 `threeOfAKind`, 40점, contributor `[1, 2, 4]`다.

## ‘확정’을 누르면 일어나는 일

확정은 현재 보드의 모든 non-dead-line 줄을 한 transaction으로 처리한다.

1. 12개 점수 줄을 살펴보고 점수를 낼 수 있는 줄을 찾는다.
2. 각 줄에서 점수에 실제로 필요한 타일과 위치를 기록한다.
3. 같은 타일이 여러 줄에 쓰였는지 세어 줄마다 겹침 배율을 계산한다.
4. 족보 성장 상태가 반영된 base score에 overlap을 적용하고 반올림한다.
5. 장착 Jester를 slot index 순서로 적용한다.
6. 타일 modifier, confirm Item modifier, Boss 점수 제약 순으로 적용한다.
7. line breakdown과 총점을 만든다.
8. 점수에 쓰인 타일만 한 번씩 보드에서 빼서 제거 더미로 옮긴다.
9. 사용된 one-shot modifier와 이동 이력을 정리하고, 확정 횟수·확정 족보 이력을 갱신한다.
10. 누적 점수가 목표 이상이면 clear signal을 반환한다.

UI 정산 연출에서는 `applyScoreToBlind: false`로 같은 계산 결과를 만든 뒤 line별 점수를 순차 반영할 수 있다. 이는 표시 시점을 나누는 것이며 판정·제거 transaction을 바꾸지 않는다.

## 점수에 쓰인 타일과 겹침

Contributor는 족보 성립에 실제로 필요한 타일이다. 투 페어의 kicker, 트리플의 나머지 타일, 포카드의 kicker는 제거되지 않는다. 여러 점수 줄이 공유한 contributor는 보드에서 한 번만 제거된다.

line별 overlap은 해당 line contributor 중 가장 큰 참여 횟수 `peakContributionCount`로 계산한다.

```text
multiplier = min(1 + 0.3 × (max(1, peakContributionCount) - 1), 2.0)
lineBaseScore = round(grownRankBaseScore × multiplier)
```

참여 횟수 1, 2, 3, 4, 5 이상은 각각 1.0, 1.3, 1.6, 1.9, 2.0 배다.

## 버림과 이동

- 보드 버림과 손패 버림은 서로 다른 자원이다.
- 버린 타일은 제거 더미로 이동하며 덱으로 자동 복귀하지 않는다.
- 보드 버림은 선택 칸을 비우고 손패 여유가 있으면 보충 드로우를 시도한다.
- 손패 버림은 선택한 손패 타일을 제거하고 덱에서 보충 드로우를 시도한다.
- 보드 이동은 source 타일을 destination 빈 칸으로 옮기며 덱·손패·제거 더미를 바꾸지 않는다.
- Boss 금지칸은 손패 배치와 보드 이동 destination 모두를 거부한다.

## Boss 제약

Boss modifier는 전투 목표의 규칙 제약이다. 현재 category는 다음 의미를 가진다.

| Category | 의미 |
|---|---|
| `tileColorWeaken` | 특정 색 contributor가 있는 점수 줄 감점 |
| `lineKindWeaken` | 행·열·대각선 중 지정 line kind 감점 |
| `faceTileWeaken` | 11..13 타일을 포함한 점수 줄 감점 |
| `allScoreWeaken` | 모든 점수 줄 감점 |
| `firstConfirmWeaken` | 첫 확정 감점 |
| `confirmCountWeaken` | 지정 확정 ordinal 이후 감점 |
| `repeatHandRankWeaken` | 이미 확정한 족보를 다시 확정할 때 감점 |
| `singleHandRankPressure` | 첫 확정 족보를 다시 확정할 때 감점 |
| `boardCellBlock` | 지정 보드 칸의 배치와 이동 destination 금지; 점수 multiplier는 변경하지 않음 |

현재 14개 `boardCellBlock` ID와 정확한 5×5 mask는 생성 문서 [BOSS_PATTERNS.md](../generated/BOSS_PATTERNS.md)가 소유한다.

## 만료와 Game Over

전투 session은 다음 두 expiry signal을 낸다.

- `drawPileExhausted`: 덱이 비고 손패도 비었으며 확정 가능한 점수 줄이 없다.
- `boardFullAfterDcExhausted`: 보드 버림이 0 이하이고 25칸이 찼으며 확정 가능한 점수 줄이 없다.

보드가 가득 차거나 덱이 비었다는 사실만으로는 만료되지 않는다. 손패 또는 확정 가능한 점수 줄이 남아 있으면 해당 signal을 내지 않는다. 상위 run layer는 이 signal과 보호 효과를 처리해 계속 진행 가능 여부 또는 game over를 결정한다.

## Deterministic Examples

### 부분 트리플

한 줄의 index 1, 2, 4에 색이 다른 숫자 6 타일이 있고 나머지가 비어 있으면 `threeOfAKind`다. 기본 점수는 40, contributor는 `[1, 2, 4]`다.

### 투 페어와 kicker

`5, 5, 2, 2, 11`은 `twoPair`, 기본 점수 25다. contributor는 앞의 네 타일이며 11 kicker는 확정 뒤 보드에 남는다.

### 교차 트리플 두 줄

가로와 세로가 중앙 숫자 7을 공유하고 각 줄이 7 세 장으로 성립하면 두 줄의 `peakContributionCount`는 2다. 각 줄은 `round(40 × 1.3) = 52`, 합계는 104이며 공유 타일을 포함한 contributor 합집합 5칸만 한 번씩 제거된다.

### 만료 직전 확정 우선

보드 25칸이 차고 보드 버림이 0이어도 점수 줄이 하나 이상 있으면 `boardFullAfterDcExhausted`가 아니다. 플레이어는 먼저 확정할 수 있다.

## Source와 Test Anchors

- 기본 보드·손패·자원·overlap: [rummi_ruleset.dart](../../lib/logic/rummi_poker_grid/rummi_ruleset.dart), [rummi_blind_state.dart](../../lib/logic/rummi_poker_grid/rummi_blind_state.dart)
- 족보 ID·점수·dead line: [hand_rank.dart](../../lib/logic/rummi_poker_grid/hand_rank.dart)
- partial 판정과 contributor: [hand_evaluator.dart](../../lib/logic/rummi_poker_grid/hand_evaluator.dart), [hand_evaluator_test.dart](../../test/logic/hand_evaluator_test.dart)
- 행동·confirm·overlap·expiry: [rummi_poker_grid_session.dart](../../lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart), [rummi_session_test.dart](../../test/logic/rummi_session_test.dart)
- Boss category와 제약: [boss_modifier.dart](../../lib/logic/rummi_poker_grid/boss_modifier.dart), [BOSS_PATTERNS.md](../generated/BOSS_PATTERNS.md)



## Presentation vs Calculation

- Confirm 계산 순서는 growth → overlap → Jester(slot 순) → tile → Item → Boss다.
- UI settlement 연출 step 이름과 라벨이 이 순서와 다를 수 있다. 특히 합산 effect 라벨이 `Jester`로 보이더라도 tile/Item/Boss 기여를 포함할 수 있다.
- 연출 순서를 계산 권위로 쓰지 않는다. 판정 권위는 session confirm transaction이다.

## Source와 Update Trigger

코드·데이터·테스트가 이 문서보다 우선한다. 다음 항목이 바뀌면 같은 변경에서 이 문서와 관련 보호 테스트를 갱신한다.

- `RummiRuleset.currentDefaults`의 보드, 손패, 자원, overlap 값
- `RummiHandRank`, `gddBaseScore`, dead-line 판정
- partial evaluation과 contributor 선택 순서
- draw/place/discard/move precondition
- confirm score 적용 순서 또는 제거 transaction
- Boss category, 감점 조건, boardCellBlock 목록
- expiry signal 조건
