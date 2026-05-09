<!-- /autoplan restore point: original plan state = file did not exist before this plan. -->
# 초과 클리어 족보 성장 Progress 플랜

## 결론

현재 런 안에서 족보 레벨 성장은 이미 구현돼 있다. 다음 보강은 목표 점수를 크게 넘긴 클리어가 단순 낭비가 아니라, 그 Station에서 가장 크게 기여한 대표 족보의 성장 progress로 이어지게 하는 것이다.

이 기능은 골드 보상을 늘리지 않는다. 플레이어가 큰 족보와 중복줄을 더 노릴 이유를 만들고, `런 정보`에서 현재 강한 족보와 다음 성장까지 남은 양을 읽게 만든다.

행성 카드류 이식은 이 플랜과 같은 성장 축이다. V1 구현 순서는 먼저 유저가 칩/레벨 성장을 UI에서 읽을 수 있게 하고, 상점에서 특정 족보 성장에 직접 투자하는 Planet-like 아이템군을 연결한 뒤, 초과 클리어 보너스를 같은 성장 통로로 넣는다.

타일 강화/변환/복사/파괴형 타로류와 손패/덱을 크게 흔드는 유령 카드류는 현재 공모전 제출 전 범위에 넣지 않는다. 저장/복원, 시각 표시, 시뮬 재현, 밸런스 검증이 준비된 뒤 공모전 이후 이식 검토로 분리한다.

## 현재 반영 상태

- 정산 breakdown과 `런 정보`는 족보 기본 점수를 `칩` 축으로 표시한다.
- `two_pair_study`, `triple_study`, `straight_study`, `flush_study`, `full_house_study`, `four_kind_study`, `straight_flush_study`는 상점에서 사용해 해당 족보 성장 +1을 직접 지급한다.
- 초과 클리어 보너스는 일반 Station 130% 이상, Boss 120% 이상에서 해당 Station의 대표 족보 성장 +1을 지급한다.
- 초과 보너스는 station key/tier 기준으로 중복 지급을 막고 active run save에 저장/복원한다.
- 정산 완료 시트에는 초과 보너스가 있을 때만 non-gold 성장 라인을 표시하며 `+0G`처럼 보이지 않게 처리한다.
- `handGrowthStates(level/progress/requiredProgress)` 분리 리팩터링까지 반영했다. `playedHandCounts`는 Jester/통계용 완성 횟수로 유지하고, 성장 점수 source는 `handGrowthStates`로 분리했다.

## 목표

- 클리어 점수가 target score를 의미 있게 초과하면 대표 족보 1개에 bonus progress를 지급한다.
- 대표 족보는 해당 Station에서 가장 많은 최종 점수를 만든 scoring rank로 정한다.
- 기존 “족보 완성 시 성장”은 유지하되, 내부 모델은 `level + progress + requiredProgress`로 확장한다.
- progress가 가득 차면 해당 족보 level이 오른다.
- `런 정보`에서 족보별 level, progress, required progress, 현재 점수, 다음 점수를 볼 수 있다.
- 정산 완료 시트에서 초과 성장 보너스가 발생했을 때만 한 줄로 보여준다.
- 게임오버 후 새 run 영구 계승은 이번 범위에 넣지 않는다.

## 비목표

- 초과 점수를 골드로 환산하지 않는다.
- 손패 최대치, 덱 크기, 드로우 수를 초과 보상으로 늘리지 않는다.
- 타일 변환/강화형 타로류나 고위험 유령 카드류를 이 플랜에 섞지 않는다.
- 플레이어에게 “다음에 이 족보를 노려라” 같은 추천 문구를 보여주지 않는다.
- 공모전 풀런봇 전용 점수 완화나 치팅 정책으로 처리하지 않는다.
- 게임오버 후 meta growth로 계승하지 않는다.

## 현재 코드 기반 판단

- `RummiHandGrowth`는 현재 `completedCount`를 곧바로 `level = 1 + completedCount`로 바꾼다.
- `RummiRunProgress.playedHandCounts`는 저장/복원과 Jester/통계용 완성 횟수에 연결돼 있다.
- `RummiPokerGridSession.confirmAllFullLines`는 line별 `ConfirmedLineBreakdown`에 `rank`, `finalScore`, `growthLevel`, `growthBonus`, `grownRankBaseScore`를 기록한다.
- `GameCashOutSheet`는 정산 보상 라인을 이미 표시한다.
- `GameRunInfoDialog`는 현재 level, 완성 횟수, 현재 점수, 다음 점수를 보여주지만 progress bar는 없다.
- 기존 저장 데이터가 `playedHandCounts`만 있으면 `handGrowthStates`로 호환 복원한다.

## 룰 설계

### 기본 성장

V1에서 기존 플레이 감각을 크게 바꾸지 않기 위해, 기존 완성 횟수 기반 성장은 progress 모델로 해석만 바꾼다.

```text
requiredProgress(level) = 1
족보 완성 시 해당 rank progress +1
progress >= requiredProgress이면 level +1, progress 차감
```

즉 V1 기본 규칙만 보면 기존과 거의 같다. 차이는 초과 클리어 보너스가 같은 progress 통로로 들어갈 수 있다는 점이다.

### 초과 클리어 보너스

```text
일반 Station:
  finalScore >= targetScore * 1.30 이면 대표 족보 progress +1

Boss:
  finalScore >= targetScore * 1.20 이면 대표 족보 progress +1

한 Station당 초과 성장 보너스는 최대 1회
대표 족보 = 해당 Station에서 finalScore 합계가 가장 큰 scoring rank
동률이면 더 높은 currentScore를 가진 rank, 그래도 같으면 더 높은 baseScore rank
```

초과 보너스는 clear를 만든 confirm 하나만 보지 않고, 해당 Station 전체의 확정 breakdown 누적을 본다. 그래야 초반에 만든 큰 족보도 대표 후보가 될 수 있다.

### 성장 적용 순서

- 전투 중 점수 계산은 confirm 시작 전의 level/progress 상태를 사용한다.
- confirm 완료 후 해당 confirm에 포함된 족보들의 기본 progress를 반영한다.
- Station clear 정산 시 초과 조건을 평가하고, 대표 족보 bonus progress를 추가한다.
- bonus progress로 level up이 발생하면 다음 Station부터 점수에 반영된다.

## 데이터 모델

V1 권장 구조:

```dart
class RummiHandGrowthState {
  final int level;
  final int progress;
}
```

저장 JSON은 rank key 기반 map으로 둔다.

```json
"handGrowthStates": {
  "flush": { "level": 3, "progress": 0 },
  "straight": { "level": 2, "progress": 0 }
}
```

호환 정책:

- 새 저장에 `handGrowthStates`가 있으면 그것을 source of truth로 사용한다.
- 이전 저장처럼 `playedHandCounts`만 있으면 `level = 1 + count`, `progress = 0`으로 복원한다.
- 한동안 `playedHandCounts`는 도감/기존 UI/테스트 호환을 위해 유지하되, 레벨 계산의 source of truth는 helper를 통해 읽는다.
- 알 수 없는 rank key는 무시한다.

## UI 설계

### 런 정보

- 각 족보 row에 `Lv.x`, 현재 점수, 다음 점수, `progress/required`를 표시한다.
- V1 required가 1이면 대부분 `0/1`처럼 보일 수 있다. 초과 보너스가 들어간 직후 level up까지 완료되면 progress는 0으로 돌아간다.
- 그래서 정산 직후에는 “초과 성장 +1” 정산 라인이 더 중요하다.
- 장기적으로 `requiredProgress(level)`을 2 이상으로 키우면 런 정보 progress bar가 더 의미 있어진다.

### 정산 완료 시트

초과 보너스가 있을 때만 보상 라인을 추가한다.
정산 progress bar는 이번 범위에서 제외한다. 현재 정산은 숫자/문구 라인으로만 성장 보너스를 보여주고, progress 시각화는 후속 검토로 남긴다.

```text
초과 달성: 플러시 성장 +1
```

level up이 발생했으면 아래처럼 더 명확히 표시한다.

```text
초과 달성: 플러시 Lv.3
```

### 문구 원칙

- “추천”, “다음 목표”, “이걸 키우세요” 같은 전략 노출 문구는 쓰지 않는다.
- 사실만 표시한다. 예: `성장 0/1`, `초과 달성`, `Lv.3`.

## 구현 순서

0. 선행 가시성 보강: 정산 breakdown과 `런 정보`에서 족보 기본 점수가 칩 축임을 명확히 표시한다.
0.5. Planet-like 직접 성장 아이템군: 특정 족보 성장 +1을 주는 상점 사용 아이템을 연결하고, `ItemEffectRuntime`/catalog matrix/test를 닫는다.
1. `RummiHandGrowthState`와 helper를 추가한다.
2. `RummiRunProgress`에 rank별 growth state를 추가하고, 기존 `playedHandCounts` 호환 복원을 붙인다.
3. `RummiHandGrowth`가 completed count 대신 growth state로 level/bonus를 계산할 수 있게 확장한다.
4. `RummiPokerGridSession.confirmAllFullLines`에서 실제 확정에 한해 Station별 rank final score contribution을 누적한다. preview나 `applyScoreToBlind: false` 경로는 상태를 바꾸지 않는다.
5. Station별 초과 성장 보너스 적용 여부를 station key/tier 기준으로 저장해, cashout 재진입이나 resume 뒤에도 한 번만 적용되게 한다.
6. Stage clear 정산 시 정수 비교로 초과 조건을 평가해 대표 족보 bonus progress를 적용한다.
7. `RummiSettlementEntryKind.overkillGrowthBonus` 같은 non-gold 전용 entry를 추가해 `GameCashOutSheet`에 초과 성장 보너스를 표시한다.
8. `GameCashOutSheet`의 고정 `[0]..[2]` 렌더링은 유지 범위를 넘기므로 이번 변경이 닿는 구간에서 non-gold reward group이 `+0G`처럼 보이지 않게 분리한다.
9. `GameRunInfoDialog`에 progress/required 표시를 추가한다.
10. 저장/복원, 정산, run info, bot policy 테스트를 보강한다.

## 테스트 계획

- `RummiHandGrowth` 단위 테스트
  - 기존 count 2는 level 3, progress 0으로 해석된다.
  - progress +1이 required를 채우면 level이 오른다.
  - dead line rank는 성장하지 않는다.
- 저장/복원 테스트
  - `handGrowthStates` 저장/복원.
  - 기존 `playedHandCounts`만 있는 save는 growth state로 마이그레이션.
  - 알 수 없는 rank key는 무시.
- 정산 테스트
  - 130% 미만 일반 Station은 초과 보너스 없음.
  - 130% 이상 일반 Station은 대표 족보 +1.
  - 120% 이상 boss는 대표 족보 +1.
  - 한 Station당 bonus는 최대 1회.
  - 대표 족보는 Station 전체 finalScore 합계로 선택된다.
- UI 테스트
  - 런 정보가 progress/required를 표시한다.
  - 정산 완료 시트가 초과 보너스 라인을 표시한다.
  - 보너스가 없으면 초과 라인을 표시하지 않는다.
- Bot policy 테스트
  - 초과 보너스가 있는 상태에서도 무의미한 이동/버림/아이템 사용을 허용하지 않는다.
  - 후보 평가가 clear 직전 큰 중복줄의 장기 성장 가치를 완전히 무시하지 않는다.

## 공모전 풀런봇 재개 조건

- 위 구현과 테스트가 끝난다.
- `flutter analyze` 통과.
- 핵심 `flutter test` 통과.
- `flutter build web` 통과.
- 최신 build 기준 console error/warn 0건 확인.
- 그 다음 도전 난이도 fresh `contest_full_run_bot`을 재개한다.

## 위험

- V1 requiredProgress가 1이면 progress UI가 레벨업 직후 0으로 돌아가 체감이 약할 수 있다.
- requiredProgress를 2 이상으로 바로 키우면 기존 족보 성장 속도가 느려져 후반 난이도에 악영향을 줄 수 있다.
- Station 전체 대표 족보를 추적하려면 현재 confirm breakdown보다 한 단계 긴 수명 상태가 필요하다.
- 저장 모델 변경이 들어가므로 stage start snapshot과 active run restore를 반드시 같이 닫아야 한다.

## GSTACK REVIEW REPORT

### Scope Summary

UI scope: yes. `런 정보` row와 정산 완료 sheet에 플레이어 노출 변경이 있다.

DX scope: no. 내부 bot/test 정책은 있지만 개발자용 API나 CLI 기능은 아니다.

Base branch: `main`.

### CEO Review

Premise gate: approved by user.

The product direction is sound. Gold is already generous, so over-target reward should reinforce the run's hand-growth identity rather than add more economy. This gives players a reason to keep building large duplicate lines after the clear threshold is reachable.

Not in scope:

- 게임오버 후 영구 계승.
- 초과 점수 골드 환산.
- 손패/덱/드로우 수 증가.
- bot 전용 점수 완화.

Dream state:

```text
Current:
  목표 점수를 넘긴 큰 확정은 대부분 낭비처럼 느껴짐.

This plan:
  초과 클리어가 대표 족보 성장으로 이어지고 정산에서 보임.

12-month ideal:
  족보 성장, 덱 확장, 발견 족보, 마켓 빌드가 모두 런 정보에서 읽히고,
  플레이어가 자기 run의 강한 축을 스스로 판단함.
```

Implementation alternatives:

| Option | Decision | Reason |
|---|---|---|
| Overkill gold | Rejected | 사용자가 골드는 충분하다고 판단했고 성장과 연결되지 않는다. |
| Representative hand progress | Accepted | 룰 수정 범위가 작고 큰 족보/중복줄 동기를 만든다. |
| Post-clear player choice | Deferred | 보상 선택 UI가 추가되어 scope가 커진다. |

### Design Review

Initial score: 7/10. Final target: 8/10.

Information hierarchy:

- `런 정보`는 level과 현재 점수를 먼저 보여준다.
- progress는 보조 정보다. V1에서 required progress가 1이면 대부분 `0/1`이 되므로, 정산 시트의 “초과 달성” 라인이 실제 피드백의 중심이다.
- 정산 시트에는 non-gold reward line을 따로 보여준다. `+0G`처럼 보이면 안 된다.

Copy decision:

- 추천 문구 금지.
- 사용 가능한 문구: `성장 0/1`, `초과 달성`, `플러시 Lv.3`.
- 피해야 할 문구: `다음엔 플러시를 노리세요`, `추천 성장`.

Missing states:

- 초과 보너스 없음: 정산 시트에 아무 라인도 추가하지 않는다.
- hidden rank 미발견: 기존처럼 런 정보에 숨긴다.
- save migration: progress 표시가 없는 old save도 crash 없이 level만 표시 가능해야 한다.

### Engineering Review

Architecture:

```text
ConfirmedLineBreakdown(finalScore, rank)
  -> RummiPokerGridSession.stationRankScoreContributions
  -> RummiRunProgress.applyConfirmedLineGrowth()
  -> RummiRunProgress.applyOverkillGrowthAwardOnce(stationKey, tier, scoreRatio)
  -> ActiveRunSaveService(runProgress + stageStartRunProgress)
  -> RummiSettlementRuntimeFacade(overkillGrowthBonus entry)
  -> GameCashOutSheet / GameRunInfoDialog
```

Primary findings:

| Severity | Finding | Decision |
|---|---|---|
| High | Station-wide representative rank needs durable contribution state. | Add per-rank final score contribution state, save/restore/copy/reset it. |
| High | `playedHandCounts` is used by Jester logic and must not become the growth level source. | Keep it for total completions and Jester compatibility. Add explicit growth state. |
| High | Cashout/resume could double-award overkill progress. | Add station key/tier idempotency guard and persist it. |
| Medium | Threshold math is ambiguous. | Use cumulative station score after clearing confirm, integer comparison: `score * 100 >= target * 130` or boss `120`. |
| Medium | Cashout sheet is gold-entry oriented. | Add a distinct overkill growth non-gold entry/render path. |
| Medium | Save schema is strict. | Prefer optional `handGrowthStates` under current schema unless a full v3 migration is deliberately chosen. |
| Low | Progress UI may be decorative with required=1. | Keep progress small in V1, make cashout award text the main feedback. |

Failure modes registry:

| Failure | Impact | Guard |
|---|---|---|
| Duplicate cashout applies bonus twice | Free level inflation | station key/tier award set persisted |
| Preview mutates contribution state | Bot/UI preview changes real run | update contribution only when score is applied |
| Jester Supernova changes | Existing cards regress | `playedHandCounts` remains separate |
| Old save loses growth | Active run restore mismatch | migrate from `playedHandCounts` when `handGrowthStates` absent |
| Non-gold reward shows `+0G` | Player confusion | dedicated rendering branch |

Test plan artifact:

`~/.gstack/projects/flame_binggo_card/main-overkill-hand-growth-progress-test-plan-20260509-224758.md`

### Codex Voice

Codex read-only review found 7 concerns:

- High: station-wide representative rank has no durable state.
- High: `playedHandCounts` is doing two jobs and Jester behavior can regress.
- High: settlement bonus application boundary is underspecified.
- Medium: threshold math is ambiguous.
- Medium: cashout UI cannot safely absorb non-gold reward lines as generic bonus entries.
- Medium: save migration conflicts with strict schema handling.
- Low: V1 progress UI may be mostly decorative.

All accepted into this plan.

### Review Scores

| Phase | Score | Status |
|---|---:|---|
| CEO | 8/10 | Clear after premise approval |
| Design | 8/10 | Clear with non-gold reward UI guard |
| Eng | 7/10 | Clear only if idempotency/save/contribution tests are included |
| DX | N/A | Skipped, no developer-facing scope |

### Approval Gate

No user challenge remains. Taste decision:

- `requiredProgress(level) = 1` keeps current growth speed and minimizes balance risk, but progress UI is less interesting.
- `requiredProgress(level) = 2+` makes the progress bar more meaningful, but changes current growth speed and needs broader balance testing.

Autoplan recommendation: keep `requiredProgress(level) = 1` for V1, implement the state model and cashout feedback now, and tune required progress later if the UI feels decorative.

## Decision Audit Trail

| # | Phase | Decision | Classification | Principle | Rationale | Rejected |
|---|-------|----------|----------------|-----------|-----------|----------|
| 1 | Intake | 기존 완성 횟수 기반 성장과 초과 성장 progress를 분리하지 않고 같은 progress 통로로 통합 | Mechanical | DRY | 성장 경로가 둘이면 런 정보와 정산 설명이 갈라진다 | 별도 overkillGrowthCounts |
| 2 | Intake | 초과 보너스는 골드가 아니라 대표 족보 progress로 지급 | Mechanical | User value | 골드는 충분하다는 사용자 판단과 성장 연결 목표에 맞다 | overkill gold payout |
| 3 | Intake | 게임오버 후 영구 계승 제외 | Mechanical | Scope control | 사용자가 이번엔 적용하지 않겠다고 명시했다 | meta growth inheritance |
| 4 | CEO | 초과 보너스 기준은 cumulative station score로 정의 | Mechanical | Explicit over clever | `scoreAdded`와 누적 점수 혼동을 막는다 | clearing confirm score only |
| 5 | Eng | `playedHandCounts`와 `handGrowthStates`를 분리 | Mechanical | Safety | Jester의 현재 완성 횟수 효과를 깨지 않는다 | playedHandCounts를 level source로 재사용 |
| 6 | Eng | station contribution state를 저장/복원한다 | Mechanical | Completeness | resume 뒤 대표 족보가 바뀌면 보상이 흔들린다 | cashout 순간 breakdown만 사용 |
| 7 | Eng | 초과 성장 award는 station key/tier로 idempotent 처리 | Mechanical | Completeness | cashout 재진입과 restore 중복 지급을 막는다 | transient bool only |
| 8 | Design | non-gold reward 전용 cashout line 추가 | Mechanical | User clarity | `+0G` 보상처럼 보이지 않게 한다 | economy bonus entry 재사용 |
| 9 | Taste | V1 requiredProgress는 1로 유지 | Taste | Pragmatic | 기존 성장 속도를 보존하고 후속 밸런스 리스크를 줄인다 | requiredProgress 2+ 즉시 적용 |
