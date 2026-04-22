# 02. Core Combat Rules

> 문서 성격: core combat rules contract
> 코드 반영 상태: current combat implemented
> 핵심 정책: 전투 코어는 V4에서 가장 먼저 보호한다.

현재 코드 상세와 파일 위치는 `docs/current_system/CURRENT_CODE_MAP.md`와 `docs/current_system/CURRENT_BUILD_BASELINE.md`를 기준으로 본다.

## 1. 전투 정체성

[V4_DECISION]

Rummi Poker Grid의 전투 정체성은 다음 네 가지다.

1. 부분 줄 평가
2. 즉시 확정
3. overlap 보너스
4. contributor 제거

이 네 가지는 V4의 핵심 규칙으로 고정한다. 이후 Station, Risk, Market, Archive를 추가해도 이 전투 코어는 기본 ruleset에서 유지한다.

## 2. Board / Line

[V4_DECISION]

- Board size: 5 x 5
- 평가 라인: 12줄
  - row 5
  - column 5
  - main diagonal 1
  - anti diagonal 1
- 빈 칸이 있어도 현재 놓인 타일만으로 라인을 평가한다.
- 라인에 타일이 하나도 없으면 평가하지 않는다.

## 3. Tile / Deck

[V4_DECISION]

- 색: red, blue, yellow, black
- 숫자: 1~13
- 물리 타일 identity: `Tile(color, number, id)`
- 덱 크기: `4 * 13 * copiesPerTile`
- 기본 copiesPerTile: 1
- 같은 로직으로 copiesPerTile 2, 즉 104장 구조도 대응 가능하다.

[V4_DECISION]

V4에서도 `copiesPerTile` 기반 구조를 유지한다. 문서나 UI에서 “52장 고정”으로 표현하지 않는다.

## 4. Hand Rank / Score

[V4_DECISION]

| Rank | Base Score | Dead Line | 확정 후보 |
|---|---:|---|---|
| High Card | 0 | 예 | 아니오 |
| One Pair | 0 | 예 | 아니오 |
| Two Pair | 25 | 아니오 | 예 |
| Three of a Kind | 40 | 아니오 | 예 |
| Straight | 70 | 아니오 | 예 |
| Flush | 50 | 아니오 | 예 |
| Full House | 80 | 아니오 | 예 |
| Four of a Kind | 100 | 아니오 | 예 |
| Straight Flush | 150 | 아니오 | 예 |

[V4_DECISION]

One Pair는 V4 기본 ruleset에서도 dead line이다. One Pair를 점수화하면 초반 템포, dead line 압박, overlap loop, Jester 밸런스가 모두 바뀌므로 기본값으로 도입하지 않는다.

[EXPERIMENT]

One Pair 10점 ruleset은 나중에 `RummiRulesetConfig.enablePairScoring` 같은 feature flag로만 검증한다.

## 5. Partial Line Evaluation

[V4_DECISION]

V4 기본 ruleset의 가능한 판정:

| Occupied Count | 가능한 scoring rank |
|---:|---|
| 0 | 없음 |
| 1 | 없음 |
| 2 | 없음. One Pair는 가능하지만 dead line |
| 3 | Three of a Kind |
| 4 | Two Pair, Three of a Kind, Four of a Kind |
| 5 | Two Pair 이상 전체 족보 |

세부 처리:

- 4장 `7,7,7,12`는 Three of a Kind로 점수화 가능하다.
- 이 경우 contributor는 `7,7,7` 세 장이고 `12`는 남는다.
- 4장 `7,7,8,8`은 Two Pair이며 네 장 모두 contributor다.
- 5장 `7,7,7,12,13`은 Three of a Kind이며 contributor는 세 장이다.

## 6. Straight

[V4_DECISION]

Straight는 5장 전용이다.

허용:

- 일반 연속: `1-2-3-4-5`부터 `9-10-11-12-13`
- high-Ace wheel: `10-11-12-13-1`

불허:

- 중복 랭크 포함 straight
- 4장 straight preview의 scoring 처리
- partial straight bonus

[TARGET]

Station modifier나 Jester로 partial straight preview를 추가할 수는 있으나, 기본 hand evaluator의 rank로 넣지 않는다.

## 7. Flush

[V4_DECISION]

Flush는 5장 전용이다.

- 5장이 모두 같은 색이면 Flush
- Straight와 동시에 성립하면 Straight Flush
- 2~4장 같은 색은 기본 ruleset에서 scoring rank가 아니다.

## 8. Confirm Candidate

[V4_DECISION]

확정 후보 조건:

```text
candidate = evaluation.isDeadLine == false
```

즉, base score가 있는 rank만 확정 후보다.

[V4_DECISION]

V4 문서에서는 “확정 후보”와 “평가 결과”를 분리해서 쓴다.

- 평가 결과: High Card / One Pair도 포함
- 확정 후보: Two Pair 이상
- 제거 후보: 확정 후보의 contributor cell union

## 9. Contributor

[V4_DECISION]

Contributor는 실제 족보 성립에 필요한 타일만 뜻한다.

| Rank | Contributor |
|---|---|
| Two Pair | pair를 이루는 4장 |
| Three of a Kind | 같은 rank 3장 |
| Straight | 5장 전체 |
| Flush | 5장 전체 |
| Full House | 5장 전체 |
| Four of a Kind | 같은 rank 4장 |
| Straight Flush | 5장 전체 |

[V4_DECISION]

Jester 조건, face card 조건, scoring tile count 조건, 제거는 모두 contributor 기반 `scoringTiles`를 기준으로 한다.

## 10. Overlap

[V4_DECISION]

하나의 contributor cell이 여러 scoring line에 기여하면 overlap으로 간주한다.

공식:

```text
lineMultiplier = min(1 + alpha * (peakContributionCount - 1), cap)
alpha = 0.3
cap = 2.0
```

line별 multiplier는 해당 line의 contributor cell 중 가장 높은 contribution count를 사용한다.

예:

| peakContributionCount | multiplier |
|---:|---:|
| 1 | 1.0 |
| 2 | 1.3 |
| 3 | 1.6 |
| 4 | 1.9 |
| 5+ | 2.0 cap |

[V4_DECISION]

Overlap은 V4의 전략 핵심으로 유지한다. 다만 장기적으로 alpha/cap은 Station modifier나 difficulty scaling으로 조정할 수 있다.

## 11. Jester Score Composition

[V4_DECISION]

라인 점수는 다음 순서로 합성된다.

1. rank base score
2. overlap multiplier 적용 후 round
3. Jester별 chips/mult/xmult 적용
4. 최종 line score 계산

Jester compose 식:

```text
chips = baseScore + chipsBonus
if chips <= 0: finalScore = 0
multFactor = 1 + multBonus / 20.0
finalScore = round(chips * multFactor * xmultBonus)
```

[V4_DECISION]

One Pair처럼 baseScore가 0인 dead line은 Jester 보정으로 점수화하지 않는다. 확정 후보에 올라온 line에만 Jester를 적용한다.

## 12. Confirm Transaction

[V4_DECISION]

전투 logic 관점의 confirm transaction:

```text
scan 12 lines
→ evaluate each non-empty line
→ filter scoring candidates
→ build contributor cells
→ count overlap
→ calculate line scores
→ apply equipped Jesters in slot order
→ produce line breakdowns
→ remove contributor cell union
→ move removed tiles to eliminated
→ return score and clear signal
```

현재 UI / Provider 호출 흐름은 `CURRENT_CODE_MAP.md`를 기준으로 확인한다. 핵심 경계만 요약하면 아래와 같다.

```text
GameView confirm button
→ GameSessionNotifier.confirmLines()
→ session.confirmAllFullLines(applyScoreToBlind: false)
→ runProgress.onConfirmedLines(...)
→ settlement animation
→ line별 applyConfirmedLineScore(...)
→ save
→ stage clear flow if target met
```

[WATCH]

메서드명 `confirmAllFullLines`는 더 이상 실제 의미와 맞지 않는다. V4 migration에서는 `confirmScoringLines`를 새 이름으로 추가하고 기존 메서드는 compatibility wrapper로 유지하는 것이 좋다.

## 13. Discard

[V4_DECISION]

Board discard:

- board tile 제거
- board discard 1 소모
- 제거 타일은 `eliminated`로 이동
- 손패에 여유가 있으면 덱에서 1장 보충
- `green_jester` 등 discard 반응 stateful Jester가 갱신될 수 있음

Hand discard:

- 선택한 손패 타일 제거
- hand discard 1 소모
- 제거 타일은 `eliminated`로 이동
- 덱에서 1장 보충
- discard 반응 stateful Jester가 갱신될 수 있음

## 14. Expiry

[CURRENT]

현재 만료 신호:

1. `boardFullAfterDcExhausted`
   - board discard가 0 이하
   - board tile count가 25
2. `drawPileExhausted`
   - deck empty
   - hand empty
   - confirm 가능한 scoring line 없음

[TARGET]

V4에서 검토할 board lock 정책:

```text
board lock expiry = board full && boardDiscard == 0 && scoringCandidateLines.isEmpty
```

이 target은 현재 코드와 다르므로 즉시 바꾸지 않는다. 먼저 테스트와 UX 결정이 필요하다.

## 15. Balance Direction

[TARGET]

전투 밸런스는 다음 축으로 조정한다.

- target score curve
- board / hand discard 수
- Jester shop price
- shop offer pool
- overlap alpha/cap
- Station modifier
- deck copiesPerTile

[V4_DECISION]

One Pair 점수화로 난이도를 낮추는 접근은 기본 밸런스 조정 수단으로 사용하지 않는다. dead line 압박은 현재 게임의 중요한 감각이다.
