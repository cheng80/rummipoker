# 14. Balance Automation & ML Pipeline

> 문서 성격: future technical option / balance tooling note
> 코드 반영 상태: not implemented
> 핵심 정책: 이 문서는 추후 도입 검토용이다. 현재 게임 밸런스나 런타임 규칙을 자동으로 바꾸지 않는다.

## 1. Purpose

[FUTURE]

이 문서는 카드 게임 레벨링과 밸런스 조정을 위해 로컬 머신에서 자동 시뮬레이션 로그를 쌓고,
PyTorch 모델로 난이도/성능을 예측하는 후보 구조를 정리한다.

목표는 자동 밸런스 결정을 바로 도입하는 것이 아니다.

목표:

- 사용자가 직접 플레이하지 않아도 대량의 전투/런 데이터를 만들 수 있게 한다.
- station / blind / market / item 조합별 난이도 경향을 수치로 본다.
- 사람이 target score, reward, item 가격, offer weight를 조정할 때 참고 리포트를 만든다.

비목표:

- Flutter UI 자동 클릭으로 플레이를 돌리는 것
- 모델이 직접 게임 밸런스를 패치하는 것
- 초기에 강화학습으로 최적 플레이어를 만드는 것
- current runtime 규칙을 모델 학습 때문에 바꾸는 것

## 2. Recommended Shape

[FUTURE]

권장 파이프라인:

```text
Dart game logic simulator
+ Bot policy
+ Random seed
-> JSONL simulation logs
-> Python/PyTorch training
-> evaluation report
-> optional balance candidate JSON
-> human review
```

중요한 결정:

- Flutter UI를 자동화하지 않는다.
- `RummiPokerGridSession`, `HandEvaluator`, Jester effect, Item effect 같은 순수 로직을 CLI/test harness에서 반복 실행한다.
- 생성된 데이터는 앱 런타임 저장과 분리한다.
- 모델 결과는 참고 지표이며, 실제 수치 반영은 사람이 한다.

## 3. Simulation CLI Target

[TARGET]

후보 명령:

```bash
dart run tools/sim/run_balance_sim.dart --runs 50000 --bot greedy_v1 --seed 42 --out logs/sim_balance.jsonl
python tools/balance_model/train.py --input logs/sim_balance.jsonl
python tools/balance_model/evaluate.py --input logs/sim_balance.jsonl
```

후보 폴더:

```text
tools/sim/
- run_balance_sim.dart
- bot_policy.dart
- random_bot.dart
- greedy_bot.dart
- lookahead_bot.dart

tools/balance_model/
- dataset.py
- train.py
- evaluate.py
- export_report.py
- README.md

logs/
- sim_balance.jsonl
```

`logs/` 산출물은 기본적으로 git에 넣지 않는다.
필요하면 집계 리포트만 별도 문서나 CSV로 남긴다.

## 4. Bot Policy Levels

[FUTURE]

초기 bot은 완벽할 필요가 없다. 세 단계로 나눈다.

```text
random_bot
- 무작위 합법 행동 선택
- 룰 버그, 극단 케이스, crash 탐지에 유리
- 밸런스 기준으로는 너무 약할 수 있음

greedy_bot
- 현재 턴에서 즉시 점수가 가장 높은 행동 선택
- 첫 밸런스 baseline으로 적합
- 일반적인 합리 플레이어 기준선 후보

lookahead_bot
- 1~2턴 앞까지 탐색
- 숙련 플레이어 상한선 후보
- 계산량이 커지므로 후순위
```

밸런스 리포트는 bot별로 분리해야 한다.
자동 시뮬레이션 데이터는 항상 `그 bot 기준의 난이도`이기 때문이다.

후보 목표:

```text
random_bot clear rate: 20-40%
greedy_bot clear rate: 55-70%
lookahead_bot clear rate: 75-90%
```

위 수치는 초기 감각값이다. 실제 목표는 플레이 테스트 후 조정한다.

## 5. Dataset Unit

[TARGET]

첫 데이터 단위는 `battle start -> battle result`가 가장 적절하다.

한 row는 전투 시작 snapshot과 전투 결과를 함께 가진다.

```json
{
  "schema_version": 1,
  "sim_id": "sim_20260421_001",
  "run_id": "run_000042",
  "seed": 42,
  "bot_policy": "greedy_v1",
  "app_version": "dev",
  "balance_version": "v4_dev",
  "ruleset_id": "current_defaults",
  "catalog_versions": {
    "jester": "jesters_common_phase5",
    "item": "items_common_v1"
  },
  "run_archetype_id": "standard_tile_deck_v1",
  "tile_deck_composition_id": "standard_52_v1",
  "tile_modifier_pool_id": null,
  "is_debug_run": false,
  "is_fixture": false,
  "station": 3,
  "blind_tier": "big",
  "target_score": 650,
  "start_state": {
    "gold": 8,
    "hands_remaining": 5,
    "board_discards": 4,
    "hand_discards": 2,
    "jester_ids": ["jolly_joker"],
    "item_ids": ["mult_capsule"],
    "deck_size": 52
  },
  "result": {
    "cleared": true,
    "final_score": 812,
    "score_ratio": 1.249,
    "turn_count": 17
  }
}
```

필수 로그 플래그:

- `is_debug_run`
- `is_fixture`
- `app_version`
- `balance_version`
- `ruleset_id`
- `catalog_versions`
- `bot_policy`
- `seed`

debug fixture 데이터와 실제 자동 시뮬레이션 데이터를 섞으면 모델이 잘못 학습한다.

## 6. Feature Candidates

[FUTURE]

초기 feature는 사람이 해석 가능한 수치로 시작한다.

Run / station:

```text
station_index
blind_tier
target_score
current_gold
hands_remaining
board_discards_remaining
hand_discards_remaining
deck_remaining_count
```

Deck / hand potential:

```text
deck_size
tile_deck_composition_id
tile_modifier_pool_id
rank_counts
suit_counts
unique_rank_count
unique_suit_count
pair_potential
straight_potential
flush_potential
```

Jester:

```text
owned_jester_count
empty_jester_slots
jester_rarity_counts
jester_effect_type_counts
jester_trigger_stage_counts
jester_edition_counts
jester_penalty_counts
flat_chips_power
flat_mult_power
xmult_power
economy_jester_count
stateful_jester_count
```

Item:

```text
consumable_count
equipment_count
passive_relic_count
utility_count
quick_slot_count
consumable_effect_type_counts
voucher_effect_type_counts
hand_rank_levels
score_item_power
discard_item_power
economy_item_power
reroll_item_power
```

Market / economy:

```text
reroll_cost
shop_offer_count
affordable_offer_count
average_offer_price
can_buy_jester
can_buy_item
```

Recent performance:

```text
previous_score_ratio
last_station_clear_margin
last_station_failed
average_score_ratio_last_3
gold_delta_last_station
```

## 7. Target Candidates

[FUTURE]

첫 모델 타겟은 `expected_score_ratio`를 권장한다.

```text
expected_score_ratio = final_score / target_score
```

이유:

- station target score가 바뀌어도 의미가 유지된다.
- 회귀 모델로 다루기 쉽다.
- easy / fair / hard bucket으로 후처리하기 쉽다.

후보 bucket:

```text
score_ratio < 0.75       -> hard
0.75 <= score_ratio < 1.25 -> fair
1.25 <= score_ratio < 1.75 -> easy
1.75 <= score_ratio      -> too_easy
```

보조 타겟:

- `cleared`: binary classification
- `turn_count`: 전투 길이 예측
- `gold_delta`: 경제 압박 예측
- `remaining_resource_ratio`: 자원 여유 예측

## 8. Model Baseline

[FUTURE]

처음 모델은 단순한 MLP regression으로 충분하다.

```text
input: battle start feature vector
target: score_ratio
loss: HuberLoss or MSELoss
metrics:
- MAE
- clear prediction accuracy
- difficulty bucket accuracy
- station/blind별 residual
```

초기에는 모델 복잡도보다 데이터 품질이 중요하다.

주의:

- bot이 너무 약하면 모든 난이도가 어렵게 보인다.
- bot이 너무 강하면 실제 사용자보다 목표 점수가 높아질 수 있다.
- 같은 balance version 안에서만 학습/평가를 비교한다.
- catalog나 ruleset이 바뀐 데이터는 같은 학습 세트에서 구분 가능해야 한다.

## 9. Balance Report Target

[TARGET]

모델 또는 단순 집계가 내야 하는 리포트:

```text
station/blind별 clear rate
station/blind별 score_ratio 평균/중앙값
bot_policy별 clear rate 차이
jester_count별 score_ratio
item_count별 score_ratio
특정 item / jester 보유 시 score_ratio lift
target_score 대비 과소/과대 추정 구간
```

수치 조정 후보:

```text
target_score_scale
small/big/boss reward
item basePrice
jester baseCost
shop offer weight
reroll cost
discard resource count
```

리포트는 자동 패치가 아니라 사람이 검토하는 근거다.

## 10. Adoption Order

[MIGRATION]

본격 구현 전에 아래 게임 규칙/데이터 경계를 먼저 고정한다.

0. ML readiness 선행 작업
   1. Station Preview/Map 최소 범위 결정
      - `station_id`, blind tier, 선택지, modifier 후보가 로그 필드로 안정화되어야 한다.
      - 현재 결정은 `docs/planning/feature_plans/STATION_PREVIEW_MAP_SCOPE_PLAN.md`를 따른다. `BlindSelectView`가 `Station Preview v1`이며 Station Map graph는 후속이다.
   2. Market offer count와 rarity weighted roll 규칙 결정
      - Jester/Item offer 수, 증설 효과, 중복 제외, 구매 후 재노출 방지, rarity weight를 simulator가 재현할 수 있어야 한다.
      - 계획은 `docs/planning/feature_plans/MARKET_OFFER_COUNT_RARITY_ROLL_PLAN.md`를 기준으로 본다.
   3. Blind / station pacing baseline 결정
      - target score curve, small/big/boss reward/pressure, discard reward, unlock tempo를 하나의 `balance_version`으로 묶는다.
      - 현재 baseline은 `v4_pacing_baseline_1`이며 `docs/planning/feature_plans/BLIND_STATION_PACING_BASELINE_PLAN.md`를 기준으로 본다.
      - Balatro ante/stake 요구 칩 표는 reference shape로만 쓰고, 실제 target score 조정은 simulator/ML 결과로 별도 `balance_version`에 반영한다.
   4. Boss modifier taxonomy 결정
      - Boss modifier는 target/resource baseline과 분리해 `boss_modifier_id`와 category를 로그 필드로 남긴다.
      - 상세 범주는 `docs/planning/feature_plans/BOSS_MODIFIER_TAXONOMY_PLAN.md`를 기준으로 본다.
      - Balatro Boss/Stake 제약은 reference-only이며, face-down hand-card 패턴은 Rummi Poker의 draw 기반 구조에 맞게 재설계한다.
   5. Starting deck archetype 기준 결정
      - 현재 runtime은 `standard_tile_deck_v1` 단일 archetype으로 본다.
      - 후속 starting deck과 tile enhancement는 `run_archetype_id`, `tile_modifier_id`로 분리한다.
      - 상세 기준은 `docs/planning/feature_plans/STARTING_DECK_ARCHETYPE_PLAN.md`를 따른다.
   6. Jester taxonomy 기준 결정
      - Jester activation order, effect category, trigger stage, edition/penalty 후보를 simulator feature로 남긴다.
      - 상세 기준은 `docs/planning/feature_plans/JESTER_REFERENCE_TAXONOMY_PLAN.md`를 따른다.
   7. Consumable / voucher taxonomy 기준 결정
      - Item consumable, rank progression, high-risk mutation, run-long passive/voucher 후보를 simulator feature로 분리한다.
      - 상세 기준은 `docs/planning/feature_plans/CONSUMABLE_VOUCHER_REFERENCE_PLAN.md`를 따른다.
   8. Simulation readiness pass
      - UI 의존성, save 의존성, randomness source, log field, bot policy boundary를 확인한다.

그 다음 실제 도입 순서는 아래가 안전하다.

1. 전투 시작/종료 snapshot을 JSONL로 남기는 구조 정의
2. `greedy_bot_v1`만 구현
3. `dart run tools/sim/run_balance_sim.dart --runs 1000` 수준의 smoke 시뮬레이션
4. station/blind별 단순 집계 리포트 작성
5. PyTorch MLP regression 추가
6. bot policy를 `random / greedy / lookahead`로 확장
7. balance candidate JSON export 검토

첫 acceptance:

- 동일 seed에서 재현 가능한 결과가 나온다.
- fixture/debug run 데이터가 학습 데이터에 섞이지 않는다.
- `greedy_bot_v1` 1000회 시뮬레이션이 로컬에서 안정적으로 완료된다.
- 리포트가 최소 `clear rate`, `score_ratio`, `station/blind별 편차`를 보여 준다.

## 11. Open Risks

[WATCH]

- 현재 전투/상점 로직이 UI/provider와 너무 강하게 결합되어 있으면 CLI 시뮬레이터 분리가 먼저 필요하다.
- Item effect가 runtime에 연결되기 전에는 item 관련 feature가 placeholder가 된다.
- greedy bot은 실제 플레이어보다 특정 패턴을 과하게 선호할 수 있다.
- market 선택 policy가 약하면 전투 bot이 좋아도 run 전체 데이터가 왜곡된다.
- 자동 시뮬레이션 결과를 너무 일찍 밸런스 truth로 쓰면 플레이 감각이 나빠질 수 있다.
