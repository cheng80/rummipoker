<!-- /autoplan restore point: /Users/cheng80/.gstack/projects/flame_binggo_card/main-autoplan-restore-20260509-151805.md -->
# Run Hand Growth And Run Info Plan

## 결론

현재 공모전 풀런봇은 S8 boss에서 단순 봇 정책 보정만으로 안정화하기 어렵다. 먼저 게임 룰에 run 내부 족보 성장과 이를 확인하는 `런 정보` UI를 실제 구현한다.

이 작업의 1차 범위는 게임오버 없이 이어지는 하나의 run 안에서만 성장하는 구조다. 게임오버 후 새 run 계승은 이번 범위에서 제외한다.

## 목표

- 유저가 run 중 완성한 족보가 이후 전투 점수에 반영된다.
- 족보 성장은 손패 개수 증가가 아니라 Balatro식 레벨 성장이다.
- 족보를 완성할 때마다 현재 레벨 보정으로 점수를 더 얻고, 완성 후 다음 레벨로 오른다.
- 유저가 전투, 마켓, 다음 진행 준비 흐름에서 현재 성장 상태를 볼 수 있다.
- 저장된 active run이 있으면 타이틀의 이어하기 흐름에서도 현재 성장 상태를 read-only로 볼 수 있다.
- S8 후반이 “봇 전용 가중치”가 아니라 실제 게임 룰의 장기 성장으로 통과 가능해지는지 다시 검증한다.

## 비목표

- 게임오버 후 새 run으로 족보 성장을 영구 계승하지 않는다.
- Balatro의 카드명, UI 명칭, 소모품 구조를 그대로 복제하지 않는다.
- 이번 단계에서 덱 증가, 행성 카드류 소비 아이템, 부스터팩 전체 체계를 한 번에 추가하지 않는다.
- 족보 성장을 손패 최대치 증가, 드로우 수 증가, 덱 확장으로 해석하지 않는다.
- 공모전 풀런봇의 무의미한 아이템/이동/버림 사용을 성장 기능으로 숨기지 않는다.

## 현재 코드 기반 판단

- `RummiRunProgress`는 이미 `playedHandCounts`를 갖고 있고 저장/복원도 `ActiveRunSaveService`에 연결돼 있다.
- 여기서 `playedHandCounts`는 내부 필드명일 뿐이며 “손패 개수”가 아니라 “족보 완성 횟수”를 뜻한다.
- `RummiPokerGridSession.confirmAllFullLines`는 현재 `evaluation.baseScore`와 중복줄 배율을 기반으로 줄 점수를 계산한다.
- `RummiRunProgress.onConfirmedLines`는 확정된 줄의 rank를 `playedHandCounts`에 누적한다.
- 따라서 새 저장 필드를 만들기보다, 점수 계산과 UI가 이 값을 직접 읽게 하는 쪽이 가장 작고 안전하다.
- `currentHandPlayedCount`는 Jester 효과 조건용으로 현재 confirm 안의 순번까지 포함한다. 족보 성장 점수는 이 값을 재사용하지 않고, confirm 시작 시점의 `runtimeSnapshot.playedCountForRank(rank)`만 사용한다.

## 룰 설계

### 성장 단위

- 성장 대상은 점수화되는 족보만 포함한다.
- `highCard`, `onePair`처럼 dead line으로 취급되는 rank는 성장 UI 목록에서는 보조 표기로만 다루거나 제외한다.
- 기본 레벨은 `Lv.1`이다.
- 현재 run에서 해당 족보를 N회 확정했다면 현재 레벨은 `Lv.(1 + N)`이다.
- 이번에 족보를 완성하면 현재 레벨의 보정 점수를 받고, 정산 후 `Lv.(2 + N)`으로 오른다.

### 점수 반영

- 성장 보너스는 현재 레벨 기준으로 `rankBaseScore`에 더해진 뒤 중복줄 배율과 Jester/Item/Boss 보정이 적용된다.
- 한 번의 confirm에서 동시에 여러 줄이 확정될 때는 confirm 시작 전의 성장 상태를 기준으로 점수를 계산한다.
- 그 confirm에서 얻은 성장 횟수는 같은 confirm 안의 다른 줄 점수에는 즉시 끼어들지 않고, confirm 완료 후 레벨에 반영한다.
- 이 순서는 유저에게 “현재 레벨로 점수를 받고, 완성 후 레벨업한다”로 설명하기 쉽고, 같은 confirm 안의 줄 처리 순서가 점수에 영향을 주지 않는다.
- Supernova류 Jester처럼 “이번 confirm 안에서 몇 번째로 나온 족보인지”를 보는 효과는 기존 `currentHandPlayedCount` 경로를 유지한다. 성장 레벨 계산과 Jester 조건 계산은 분리한다.

### 1차 수치안

성장 보너스는 족보별 기본 점수의 일부를 더한다.

| Rank | Base | Growth per level |
| --- | ---: | ---: |
| twoPair | 25 | +5 |
| threeOfAKind | 40 | +8 |
| straight | 70 | +14 |
| flush | 50 | +10 |
| fullHouse | 80 | +16 |
| fourOfAKind | 100 | +20 |
| straightFlush | 150 | +30 |

공식:

```text
completedCountBeforeConfirm = playedHandCounts[rank]
currentLevel = 1 + completedCountBeforeConfirm
growthBonus = (currentLevel - 1) * growthStep(rank)
grownRankBaseScore = rankBaseScore + growthBonus
baseLineScore = grownRankBaseScore * overlapMultiplier
```

이 수치는 기본 점수의 약 20%씩 성장한다. S8처럼 긴 run 후반에서 반복 전략의 힘을 만들되, 한두 번 완성한 족보만으로 난이도가 붕괴하지 않게 한다.

## UI 설계

### 런 정보 화면

`런 정보`는 modal/dialog 형태로 시작한다. 새 전용 route는 필요해질 때 분리한다.

표시 항목:

- 족보명
- 현재 레벨
- 현재 기본 점수
- 다음 성장 후 기본 점수
- 이번 run 완성 횟수
- 플레이어 문구는 번역 키 기준으로 추가한다. 한/영 문구를 먼저 잠그고, 기존 hardcoded 한국어가 남아 있더라도 새 성장 UI 문구는 translation resource에 둔다.

정렬:

- 성장한 족보를 위에 둔다.
- 성장 횟수가 같으면 현재 점수가 높은 족보를 먼저 둔다.
- 미성장 족보도 아래에 남긴다. 다만 “키울 추천 후보”처럼 전략을 직접 알려주는 표현은 쓰지 않고, 현재 레벨/완성 횟수/점수만 사실로 보여준다.

### 접근 경로

- 전투 옵션 dialog에 `런 정보` 액션을 추가한다.
- 마켓/options 계열 화면에서도 같은 `런 정보` dialog를 열 수 있게 한다.
- active run 저장이 있는 타이틀/이어하기 경로에서도 저장 facade를 통해 read-only `런 정보`를 열 수 있게 한다.
- 전투/마켓 옵션 안에만 숨겨 접근성이 부족하면 HUD 단축 버튼을 추가한다. 1차 구현에서는 옵션 경로와 타이틀 read-only 경로를 먼저 닫고, 플레이 확인 뒤 HUD 버튼을 결정한다.

## 구현 순서

1. `RummiHandGrowth` 같은 작은 pure helper를 추가한다.
2. `RummiPokerGridSession.confirmAllFullLines`에서 성장된 base score를 사용한다.
3. `ConfirmedLineBreakdown`에 `growthLevel`, `growthBonus`, `grownRankBaseScore`를 추가한다.
4. 런 정보 dialog 위젯을 추가한다.
5. 정산 breakdown에서 `기본 70 + 성장 14`처럼 성장 보너스를 명시한다.
6. 전투 옵션, 마켓 옵션, 타이틀 이어하기 흐름에서 dialog를 연결한다.
7. 저장/복원 뒤에도 같은 성장 상태가 보이는지 확인한다.
8. 공모전 풀런봇 재개 전 `flutter analyze`, 핵심 logic/widget test, `flutter build web`을 통과시킨다.
9. 성장 룰이 들어간 뒤 `contest_full_run_bot` policy가 즉시 점수만 보지 않고 반복 rank 성장도 가치로 보게 할지 검증한다.

## 테스트 계획

- `RummiHandGrowth` helper 단위 테스트
  - 기본 레벨 1
  - N회 확정 후 레벨 1 + N
  - dead line은 성장 점수 0 또는 목록 제외
- session scoring 테스트
  - 첫 straight는 기존 점수
  - straight 1회 누적 후 다음 straight는 성장 보너스 포함
  - 같은 confirm 안의 같은 rank 2줄은 서로 즉시 성장 보너스를 주지 않음
  - overlap multiplier가 성장된 base에 적용됨
  - Jester의 `currentHandPlayedCount`와 성장 레벨 계산이 서로 섞이지 않음
- save/restore 테스트
  - `playedHandCounts` 복원 뒤 점수와 런 정보 표시가 유지됨
  - `playedHandCounts` 누락은 빈 성장 상태로 복원됨
  - 알 수 없는 rank key가 들어온 저장 데이터는 앱 크래시가 아니라 해당 key 무시 또는 저장 무효화 경로로 처리됨
- widget 테스트
  - 런 정보 dialog가 성장 횟수, 레벨, 현재 점수를 표시함
  - 옵션 dialog에서 `런 정보` 액션이 숨겨지지 않음
  - 타이틀의 이어하기 메뉴에서 저장된 active run 성장 상태를 read-only로 볼 수 있음
- bot policy 테스트
  - 반복 rank 성장 보너스가 있는 상태에서 같은 rank 확정의 장기 가치가 배치/confirm 후보 평가에 반영됨
  - 성장 기능 때문에 무의미한 버림/이동/아이템 사용을 다시 허용하지 않음

## 공모전 풀런봇 재개 조건

- 룰/UI 구현 완료
- `flutter analyze` 통과
- 핵심 logic/widget test 통과
- `flutter build web` 통과
- 최신 web build 기준으로 `contest_full_run_bot` fresh 또는 checkpoint-resume 재실행
- console error/warn 0건 확인
- bot policy가 족보 성장 보너스를 읽거나 적어도 성장 후 scoring preview를 사용한다는 테스트 확인

## 위험과 보류

- 성장 수치가 강하면 중반 난이도가 무너질 수 있다. S1~S8 score log를 보고 조정한다.
- 성장 UI가 옵션 안에만 있으면 “언제든 확인” 감각이 약할 수 있다. 1차 구현 후 실제 플레이에서 접근성이 부족하면 HUD 단축 버튼을 추가한다.
- 게임오버 후 영구 계승은 로그라이트 메타로 강력하지만, 이번에는 저장 포맷과 밸런스 파급이 커서 보류한다.

## GSTACK REVIEW REPORT

### Scope Decision

Autoplan mode: hold scope with targeted completeness fixes.

The requested product change is correct: this is Balatro식 족보 레벨 성장, not hand-size growth, deck growth, or bot-only compensation. The scope stays on current-run hand rank levels plus run info UI, but the implementation must include settlement explanation, save/restore hardening, and bot-policy validation because those are in the direct blast radius.

### CEO Review

Decision: proceed with current-run-only growth.

- User value: players can see which hands are stronger in the current run and deliberately build around them.
- Not in scope: permanent gameover inheritance, deck expansion, booster packs, planet-card item system.
- Challenge: if UI only shows after combat, users cannot plan. V1 must expose run info in battle, market, and title continue flow.

### Design Review

Decision: factual run info, no strategy recommendation.

- Show rank name, level, current score, next score, completion count.
- Do not label ungrown ranks as “recommended” or “should grow next.”
- Settlement text must explain score changes: base score, growth bonus, overlap, Jester/Item, Boss penalty.
- New player-facing strings should be translation-key based.

### Engineering Review

Decision: add a pure helper and keep growth separate from Jester counters.

Architecture:

```text
RummiRunProgress.playedHandCounts
  -> RummiJesterRuntimeSnapshot.playedCountForRank(rank)
  -> RummiHandGrowth.level/bonus/effectiveBase(rank, completedCount)
  -> RummiPokerGridSession.confirmAllFullLines
  -> ConfirmedLineBreakdown(growthLevel, growthBonus, grownRankBaseScore)
  -> Cashout/Run Info UI
```

Critical implementation guard:

- Do not use `currentHandPlayedCount` for growth scoring. That value includes current-confirm ordering for Jester effects.
- Use `runtimeSnapshot.playedCountForRank(rank)` captured before line scoring.

Failure modes:

- Missing old save key: default to empty growth.
- Unknown rank save key: ignore or invalidate active save without crashing.
- UI score mismatch: tests must assert breakdown labels include growth when growth bonus is nonzero.
- Bot still values only immediate score: add bot-policy test before full-run evidence is treated as meaningful.

### Test Artifact

Primary commands:

```bash
flutter test test/logic/rummi_session_test.dart test/services/active_run_save_service_test.dart test/views/game/widgets/game_options_dialog_test.dart
flutter test test/competition_bot_policy_test.dart
flutter analyze
flutter build web
```

QA focus:

- Battle options opens run info.
- Market options opens run info.
- Title continue menu opens read-only run info for saved active run.
- Scoring a grown hand displays the growth contribution in settlement text.
- `contest_full_run_bot` does not spend movement/discard/item actions merely to create evidence.

### Approval Gate

No user challenge remains. The only taste decision is whether to add a HUD shortcut in V1. Autoplan recommendation: defer HUD shortcut until after option/title paths are verified, because the current UI already has constrained HUD space and option access is lower risk.
