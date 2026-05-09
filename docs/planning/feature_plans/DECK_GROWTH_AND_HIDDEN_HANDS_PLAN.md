<!-- /autoplan restore point: original plan state = file did not exist before this plan. -->

# 덱 성장과 히든 족보 구현 플랜

## 결론

- 현재 런 안에서 족보 레벨 성장은 구현됐지만, 후반을 받쳐 줄 덱 빌딩 축은 아직 없다.
- 다음 구현 단위는 `런 중 추가 타일 획득 -> 다음 블라인드 덱에 합성 -> 런 정보에서 덱 변화 확인 -> 추가 타일로만 성립 가능한 히든 족보 발견`까지 한 번에 닫는다.
- 히든 족보는 처음부터 런 정보에 정답 목록을 보여주지 않는다. 실제로 만족해 확정한 뒤 `특수 족보` 영역에 나타나고, 그 뒤부터 일반 족보처럼 레벨 성장과 점수 보정을 받는다.
- 2026-05-09 기준 V1 구현은 런타임 반영과 핵심 테스트/분석/웹 빌드를 통과했다. 공모전 풀런봇 재개 전에는 최신 build 기준 smoke와 bot 정책 반영 여부를 별도로 확인한다.

## 현재 상태

- `RummiRunProgress`는 런 전체 상태, 골드, 상점, 아이템, 족보 완성 횟수를 들고 있다.
- `RummiPokerGridSession`은 현재 블라인드의 덱, 손패, 보드, 제거 더미를 들고 있다.
- 다음 블라인드 진입 시 `RummiPokerGridSession.prepareNextBlind()`가 표준 덱을 다시 셔플한다.
- `deckCopiesPerTile`과 타일 `id`는 복제 타일을 표현할 수 있지만, 런 중 덱에 새 타일을 추가하는 실제 경로는 없다.
- `RummiHandRank`와 `HandEvaluator`에는 기본 족보만 있다. 현재 족보: 하이 카드, 원 페어, 투 페어, 트리플, 스트레이트, 플러시, 풀하우스, 포카드, 스트레이트 플러시.

## 목표

1. 플레이어가 런 중 카드를 보상으로 받거나 마켓에서 구매해 덱을 키울 수 있게 한다.
2. 추가된 타일은 현재 런 동안 유지되고 다음 블라인드부터 드로우 덱에 들어간다.
3. 덱 성장으로 만들 수 있는 특수/히든 족보를 추가한다.
4. 히든 족보는 최초 확정 뒤 런 정보에 나타나고, 일반 족보와 같은 레벨 성장 규칙을 따른다.
5. UI는 전략 정답을 직접 알려주지 않고, 덱 변화와 발견된 성장 상태만 읽히게 한다.

## 비목표

- 게임 오버 뒤 새 런까지 족보 레벨이나 덱 추가 타일을 계승하지 않는다.
- 현재 전투 중 덱에 즉시 타일을 주입하지 않는다. V1에서는 다음 블라인드부터 적용한다.
- 히든 족보 후보를 미리 전부 공개하거나 추천하지 않는다.
- 공모전 풀런봇 정책 보정으로 이 기능을 대체하지 않는다. 봇 QA는 이 룰 보강 이후 다시 재개한다.

## 구현 방향

### 1. 런 덱 추가 상태

- `RummiRunProgress`에 `addedDeckTiles`를 추가한다.
- `addedDeckTiles`는 `List<Tile>`로 저장한다.
- 저장/복원 경로:
  - `SavedRunProgressData.addedDeckTiles`
  - `ActiveRunSaveService` snapshot/restore
  - stage start snapshot
  - debug fixture restore
- 기존 저장 파일은 `addedDeckTiles: []`로 복원한다.
- `copySnapshot()`은 추가 타일 목록을 깊은 복사한다.

### 2. 다음 블라인드 덱 합성

- `RummiPokerGridSession.prepareNextBlind()` 또는 그 호출부에 덱 source를 넘길 수 있게 한다.
- 기본 source는 `buildStandardPokerDeck(copiesPerTile: deckCopiesPerTile) + runProgress.addedDeckTiles`.
- 합성된 source를 `PokerDeck.resetShuffled(source: ...)`로 섞는다.
- `conservationTotal`은 현재 세션의 실제 source 크기와 맞아야 하므로, 세션에 `extraDeckTiles` 또는 `currentDeckSourceSize`를 함께 보관하는 방식을 검토한다.
- V1 권장안은 세션에 `baseDeckTiles` 같은 별도 구조를 추가하기보다 `initialDeckSizeForBlind`를 저장해 `totalDeckSize`와 검증 표시가 실제 덱 크기를 쓰게 하는 것이다.

### 3. 타일 획득 경로

- V1은 두 경로를 둔다.
- 마켓 타일 구매:
  - Jester/Item lane과 섞지 않고 별도 `Tile` lane을 둔다.
  - offer는 3장, 가격은 초반 과한 snowball을 막기 위해 낮은 기본값에서 시작하고 stage에 따라 조금 상승한다.
  - 구매하면 `RummiRunProgress.addedDeckTiles`에 들어가고 다음 블라인드부터 적용된다.
- 보스 클리어 타일 보상:
  - 보스 클리어 뒤 다음 마켓에 1회성 무료 타일 선택을 제공한다.
  - 보상 후보는 3장 중 1장 선택으로 시작한다.
  - 정산 bottom sheet 자체를 크게 바꾸기보다, 마켓 진입 후 상단/별도 lane에서 처리하는 것이 V1 UI 리스크가 작다.

### 4. 타일 offer 생성

- offer 생성은 run seed, stage, lane reroll offset을 사용해 재현 가능하게 만든다.
- 후보 생성은 완전 추천형이 아니라 일반적인 덱 빌딩 선택지로 둔다.
- 같은 색/연속 숫자/중복 숫자 후보가 섞이도록 하되, 현재 보드나 손패의 정답을 직접 보고 offer를 만들지 않는다.
- 구매 이력은 도감/QA 목적으로 `seenMarketTileCodes`, `boughtTileCodes` 같은 별도 필드를 추가할 수 있다. 단, V1에서 도감까지 닫지 않으면 문서에는 보류로 표시한다.

### 5. 히든 족보 V1 후보

히든 족보는 기본 족보의 상위 변형이거나 덱 성장으로만 안정적으로 가능한 패로 제한한다.

| 족보 | 조건 | 노출 |
| --- | --- | --- |
| 파이브 카드 | 같은 숫자 5장 | 덱 추가 타일이 있어야 자연 성립 가능 |
| 로열 스트레이트 플러시 | 같은 색 9-10-11-12-13 | 첫 확정 뒤 특수 족보에 노출 |
| 로우 스트레이트 플러시 | 같은 색 1-2-3-4-5 | 첫 확정 뒤 특수 족보에 노출 |
| 프리즘 스트레이트 | 스트레이트이면서 4색이 모두 포함 | 첫 확정 뒤 특수 족보에 노출 |
| 크라운 포카드 | 11/12/13 중 하나로 포카드 | 첫 확정 뒤 특수 족보에 노출 |

초기 우선순위는 `파이브 카드 > 로열 스트레이트 플러시 > 로우 스트레이트 플러시 > 스트레이트 플러시 > 크라운 포카드 > 프리즘 스트레이트`로 둔다.

V1 기본 점수와 성장 step은 아래 값으로 시작한다.

| 족보 | 기본 점수 | 성장 step |
| --- | ---: | ---: |
| 프리즘 스트레이트 | 90 | 18 |
| 크라운 포카드 | 130 | 26 |
| 로우 스트레이트 플러시 | 180 | 36 |
| 로열 스트레이트 플러시 | 200 | 40 |
| 파이브 카드 | 220 | 44 |

이 값은 기존 `스트레이트 70`, `포카드 100`, `스트레이트 플러시 150`보다 높은 보상으로 두되, 히든 족보 하나만으로 후반 목표를 자동 돌파하지 않도록 성장 step을 기본 점수의 20% 안팎으로 제한한다.

### 6. 평가와 성장

- `RummiHandRank`에 특수 족보 enum 값을 추가한다.
- `gddBaseScore()`와 `RummiHandGrowth.growthStepFor()`에 점수를 추가한다.
- `RummiHandGrowth.scoringRanks`는 기본 족보 목록과 특수 족보 목록을 분리한다.
- `HandEvaluator.evaluateLine()`은 기존 기본 족보보다 먼저 특수 조건을 판정한다.
- 확정 정산은 기존 `playedHandCounts`와 `RummiHandGrowth` 경로를 그대로 사용한다.
- 저장된 오래된 `playedHandCounts`에 새 enum이 없어도 정상 동작해야 한다.

### 7. 런 정보 UI

- 기존 기본 족보 레벨 표는 유지한다.
- 하단에 `특수 족보` 섹션을 추가한다.
- 특수 족보 섹션은 `completedCount > 0`인 항목만 보여준다.
- 아직 발견하지 못한 특수 족보는 이름이나 조건을 보여주지 않는다.
- 덱 섹션을 추가해 현재 런 덱 크기, 추가 타일 수, 추가된 타일 요약을 보여준다.
- 이 화면은 유저가 강한 축을 읽는 정보 화면이지, 다음 정답을 추천하는 화면이 아니다.

### 8. 봇 QA 연결

- 공모전 풀런봇은 이 기능 구현 후 다시 재개한다.
- 봇은 추가 타일 구매/보스 보상 선택을 “증거 확보용”으로 무조건 누르지 않는다.
- 구매 판단은 족보 성장, 중복 확정 가능성, 플러시/스트레이트/파이브 카드 가능성을 기준으로 한다.
- 히든 족보가 evaluator에 들어가면 기존 line evaluation 기반 정책이 자연스럽게 점수를 반영해야 한다. 부족하면 그때 봇 후보 평가에 특수 족보 근접도를 추가한다.

## 단계별 작업

1. 데이터 모델과 저장/복원
   - `RummiRunProgress.addedDeckTiles`
   - `SavedRunProgressData` JSON
   - snapshot/restore/test fixture
2. 덱 합성
   - 다음 블라인드 덱 생성 source에 추가 타일 반영
   - 덱 크기/보존 검증 수정
3. 히든 족보 평가
   - enum, 점수, growth step, evaluator priority
   - evaluator unit test
4. 런 정보 UI
   - 기본 족보/특수 족보/덱 섹션 분리
   - 닫기 버튼과 스크롤 동작 회귀 확인
5. 마켓 타일 lane
   - tile offer model/generator
   - 구매 처리와 골드 차감
   - 다음 블라인드 반영
6. 보스 클리어 타일 보상
   - 보스 클리어 후 다음 마켓 무료 tile pick
   - 저장/복원
7. 문서와 봇 준비
   - active plan/checklist에 “룰 보강 진행 중” 반영
   - 구현 뒤 full-run bot 재개 전 policy code/test 반영 여부 확인

## 테스트 계획

- `test/logic/rummi_poker_grid/hand_evaluator_test.dart`
  - 파이브 카드가 포카드보다 우선된다.
  - 로열/로우 스트레이트 플러시가 일반 스트레이트 플러시보다 우선된다.
  - 프리즘 스트레이트가 일반 스트레이트보다 우선된다.
  - 히든 조건이 아니면 기존 족보 결과가 변하지 않는다.
- `test/logic/rummi_poker_grid/rummi_hand_growth_test.dart`
  - 특수 족보도 completed count에 따라 레벨과 점수가 오른다.
- `test/services/active_run_save_service_test.dart`
  - 추가 타일 저장/복원.
  - 이전 저장 데이터는 빈 추가 타일로 복원.
- `test/services/blind_selection_setup_test.dart` 또는 인접 테스트
  - 추가 타일이 다음 블라인드 덱 source에 포함된다.
  - 현재 블라인드 중에는 추가 타일이 즉시 드로우되지 않는다.
- `test/views/game/game_run_info_dialog_test.dart`
  - 미발견 특수 족보는 표시되지 않는다.
  - 발견된 특수 족보와 덱 추가 요약은 표시된다.
- `test/views/game/game_shop_screen_test.dart`
  - tile lane offer 표시, 구매, 골드 차감, 저장 상태 반영.
- 검증 명령
  - `flutter analyze`
  - 핵심 `flutter test`
  - `flutter build web`
  - 구현 완료 후 공모전 풀런봇 재개

## Autoplan 리뷰 결과

### CEO 리뷰

- 단순히 봇 S8 통과를 위해 점수 보정을 더 넣는 방향은 장기적으로 게임을 약하게 만든다.
- 덱 성장과 히든 족보는 후반 고득점 구간의 이유를 플레이어가 이해하고 설계할 수 있게 만드는 핵심 룰 보강이다.
- V1은 영구 로그라이트 계승 없이 현재 런 안에서만 성장하게 하므로, 밸런스 폭발을 제한하면서도 후반 전략 축을 만든다.

### 디자인 리뷰

- 런 정보는 “내가 무엇을 키웠는지”를 보여주는 화면이어야 한다.
- 히든 족보는 조건을 미리 나열하면 전략 문제를 유출하므로, 첫 발견 뒤 표시한다.
- 타일 구매는 기존 offer lane과 섞지 않고 별도 lane으로 둬야 구매 목적이 명확하다.
- 덱 섹션은 숫자만 던지지 말고 추가 타일을 색/숫자로 읽히게 하되, 추천 문구는 쓰지 않는다.

### 엔지니어링 리뷰

- 덱 추가 상태는 세션보다 런 진행 상태에 둬야 다음 블라인드 생성과 저장/복원이 맞는다.
- 현재 `deckCopiesPerTile`은 전체 복제 수를 뜻하므로, 개별 추가 타일과 섞어 쓰면 의미가 흐려진다.
- 추가 타일 때문에 `totalDeckSize`와 `conservationTotal` 검증이 깨질 수 있다. 이 값을 실제 블라인드 시작 덱 크기 기준으로 바꾸는 작업이 필수다.
- enum 추가는 저장 호환성 관점에서 비교적 안전하지만, `byName` 복원 경로와 translation key 누락은 테스트로 막아야 한다.

### DX 리뷰

- 구현자는 `RummiRunProgress -> BlindSelectionSetup -> RummiPokerGridSession.prepareNextBlind()` 순서로 데이터 흐름을 따라가면 된다.
- 히든 족보는 evaluator test를 먼저 쓰면 회귀를 잡기 쉽다.
- 마켓 lane은 기존 Jester/Item lane 구조를 재사용하되, 모델을 억지로 `Item`에 끼워 넣지 않는 편이 장기 유지보수에 낫다.

## Autoplan 기본 결정

1. 타일 구매 lane은 모든 마켓에 연다. 대신 초반 가격과 offer 수로 조절한다.
2. 보스 클리어 무료 타일 선택은 모든 보스 클리어 뒤 다음 마켓에서 1회 제공한다.
3. 히든 족보 기본 점수와 성장 step은 위 표를 V1 값으로 쓴다.
4. 추가 타일 도감 수집은 이번 구현 범위에서 제외한다. 이번 작업은 런 정보 표시와 저장/복원까지만 닫는다.

## Taste Decisions

- 타일 구매를 S3 이후로 늦추는 안도 가능하지만, 후반 문제의 원인이 덱 빌딩 축 부재라면 초반부터 선택지를 보여주는 편이 게임 구조를 더 빨리 학습시킨다.
- 무료 타일 보상을 일부 보스에만 주면 구현은 작아지지만, 덱 성장이 플레이 감각으로 느껴지는 속도가 늦다. V1은 모든 보스 보상으로 시작하고 가격·후반 목표·offer 품질로 밸런스를 조정한다.
- 히든 족보를 런 정보에 `???`로 미리 보여주는 안은 수집 욕구는 만들 수 있지만, 현재 AGENTS 규칙의 전략 후보 노출 금지와 충돌할 수 있다. V1은 발견 전 완전 비노출이 더 안전하다.

## 구현 결과

- `RummiRunProgress.addedDeckTiles`, `tileOffers`, `pendingBossTileReward` 추가.
- 저장/복원과 stage start snapshot에 추가 타일과 tile offer 상태 반영.
- 다음 블라인드 진입 시 표준 덱과 `addedDeckTiles`를 합성해 셔플.
- `RummiHandRank`에 특수 족보 5종 추가.
- `HandEvaluator`, `gddBaseScore`, `RummiHandGrowth`에 특수 족보 점수와 성장 step 반영.
- 런 정보에 덱 요약과 발견된 특수 족보 표시.
- 마켓에 `Tile` lane 추가.
- 보스 클리어 뒤 다음 마켓에서 무료 타일 선택 가능.

## 검증 결과

- `flutter analyze` 통과.
- 핵심 테스트 통과:
  - `test/logic/hand_evaluator_test.dart`
  - `test/logic/rummi_hand_growth_test.dart`
  - `test/logic/rummi_market_facade_test.dart`
  - `test/services/active_run_save_service_test.dart`
  - `test/services/blind_selection_setup_test.dart`
  - `test/views/game/widgets/game_run_info_dialog_test.dart`
  - 관련 `game_shop_screen` widget tests
- `flutter build web` 통과.

## 남은 작업

- 최신 build를 띄워 Browser/WebDriver smoke로 console error/warn을 확인한다.
- 공모전 풀런봇 재개 전, tile lane 구매와 특수 족보 점수가 bot policy code/test에 반영되는지 확인한다.
- 필요하면 bot 후보 평가에 특수 족보 근접도와 추가 타일 구매 판단을 보강한다.
