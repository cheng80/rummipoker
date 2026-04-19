# 09. Test, QA & Acceptance Criteria

> 문서 성격: QA baseline + migration acceptance
> 코드 반영 상태: planned test expansion
> 핵심 정책: V4 migration은 테스트 보호망 없이 시작하지 않는다.

## 1. Test Policy

[V4_DECISION]

V4 migration에서 테스트는 문서보다 강한 보호 장치다. 특히 다음 영역은 테스트 없이 수정하지 않는다.

- HandEvaluator
- confirm transaction
- contributor removal
- overlap
- Jester scoring
- active run save/load
- stageStartSnapshot restart
- shop buy/sell/reroll

## 2. Combat Logic Tests

[MIGRATION]

필수 케이스:

### Dead line

- 1장 line은 High Card, score 0, 확정 불가
- 2장 pair는 One Pair, score 0, 확정 불가
- 3장 pair + kicker는 One Pair, score 0, 확정 불가

### Partial scoring

- 3장 같은 rank는 Three of a Kind, score 40, 3장 제거
- 4장 `A,A,A,K`는 Three of a Kind, A 3장 제거, K 유지
- 4장 `A,A,K,K`는 Two Pair, 4장 제거
- 4장 `A,A,A,A`는 Four of a Kind, 4장 제거

### 5-card scoring

- Straight score 70
- Flush score 50
- Full House score 80
- Four of a Kind score 100, kicker 유지
- Straight Flush score 150
- `10-11-12-13-1` straight 인정

## 3. Confirm Transaction Tests

[MIGRATION]

필수 검증:

- 12줄 중 scoring candidate만 정산
- 여러 line이 동시에 성립하면 모두 정산
- contributor cell union만 제거
- 같은 타일이 두 line에 겹치면 한 번만 제거
- overlap multiplier line별 계산
- baseScoreSum, jesterBonusSum, scoreAdded 일관성
- stage clear signal이 target score 기준으로 계산

## 4. Overlap Tests

[MIGRATION]

필수 케이스:

| contribution count | expected multiplier |
|---:|---:|
| 1 | 1.0 |
| 2 | 1.3 |
| 3 | 1.6 |
| 4 | 1.9 |
| 5+ | 2.0 |

테스트는 round 후 line score도 확인한다.

## 5. Jester Tests

[MIGRATION]

필수 검증:

- Jester는 dead line에 적용되지 않는다.
- Jester는 contributor scoringTiles만 본다.
- face card 조건은 contributor에 있는 face card만 센다.
- scholar는 Ace contributor 기준으로 동작한다.
- slot order 적용이 안정적이다.
- stateful slot index가 save/load 후 유지된다.
- `green_jester` confirm/discard 변화
- `ride_the_bus` face card scoring 시 reset
- `ice_cream` confirm 후 감소
- `popcorn` round end decay
- `supernova` played hand count 참조

## 6. Deck Conservation Tests

[MIGRATION]

항상 유지해야 하는 불변식:

```text
deck.remaining + hand.length + boardTileCount + eliminated.length == totalDeckSize
```

검증 액션:

- draw
- place
- board discard
- hand discard
- confirm
- discardStageRemainder
- prepareNextBlind
- save/load 후 conservation

## 7. Save / Load Tests

[MIGRATION]

필수 검증:

- valid save restore
- invalid HMAC이면 invalid
- missing payload/signature 처리
- schemaVersion mismatch invalid
- activeScene battle restore
- activeScene shop restore
- stageStartSnapshot restore
- ownedJesterIds restore
- shopOffers restore
- statefulValuesBySlot restore
- playedHandCounts restore
- deckPile/boardCells/hand/eliminated restore
- runRandomState restore

## 8. Restart Tests

[MIGRATION]

필수 검증:

- current stage 중 액션 후 restart하면 stage 시작점으로 돌아간다.
- gold, owned Jesters, shopOffers, stateful values도 stage 시작점으로 돌아간다.
- restart는 run 전체 초기화가 아니다.
- game over retry는 stageStartSnapshot을 사용한다.

## 9. Provider / UI Flow Tests

[MIGRATION]

필수 검증:

- `GameSessionNotifier.confirmLines`가 result 반환
- confirm result가 없을 때 null
- applyConfirmedLineScore가 점수 반영
- prepareCashOut가 gold 반영
- openShop이 offers 생성
- buy/sell/reroll 동작
- advanceToNextStage가 stageStartSnapshot 갱신
- pendingResumeShop 처리

## 10. Manual QA Checklist

[MIGRATION]

새 build마다 최소 확인:

1. 새 랜덤 run 시작
2. 시드 run 시작
3. 타이틀에서 이어하기
4. 손상 save 삭제 flow
5. draw/place/confirm
6. One Pair 확정 불가
7. Three of a Kind 부분 확정 가능
8. overlap 시 점수 증가 표시
9. contributor만 사라지는지 확인
10. stage clear → cash-out → shop → next stage
11. shop에서 buy/sell/reroll
12. app background 후 복귀 save 유지
13. 현재 stage 재시작
14. game over retry

## 11. Merge Gate

[V4_DECISION]

다음 조건을 만족하지 않으면 V4 migration PR은 merge하지 않는다.

- current baseline 테스트 통과
- save/load 테스트 통과
- 기존 save 호환성 판단 명시
- 변경된 ruleset이 있으면 default false
- docs의 `[CURRENT]`와 코드가 불일치하지 않음
- 디버그 전용 기능이 release UI에 노출되지 않음
