# ML 레벨링 시뮬레이션 진행 방향

기준 커밋: `09d11a5 Add ML leveling simulation workflow`

이 문서는 기준 커밋 이후 진행한 ML 레벨링/시뮬레이션 대화와 구성 방향을 다음 작업에서 잃지 않기 위한 실행 메모다. 현재 단계의 원칙은 **게임 UI와 실제 저장 구조는 아직 확정하지 않고, 시뮬레이터에서 먼저 재미/레벨링 후보를 검증한다**이다.

## 목표

- 단순 Decision Tree로 정답을 고르는 것이 아니라, 제대로 된 feature와 target을 잡고 충분한 시뮬레이션 데이터를 만든다.
- 게임 기획 관점의 재미 기준과 AI/ML 관점의 지표를 함께 본다.
- 덱 고갈, 보스 병목, 클리어율, 턴 템포, 점수 스파이크, 빌드 다양성을 동시에 평가한다.
- 유의미한 후보가 반복 seed에서 확인될 때만 실제 시스템 구현으로 옮긴다.

## 중요한 전제

- 레벨링은 보스 데이터만으로 하지 않는다. small/big/boss, station curve, loadout, market purchase, resource state, deck pressure를 함께 본다.
- 지금까지 잡아 온 기준값은 “게임의 재미와 적절한 난이도 지점”을 찾기 위한 기준이다. 기존 테스트 과정과 기준값은 버리지 않고 새 sweep의 비교 기준으로 계속 사용한다.
- Balatro는 참고 모델일 뿐 그대로 복제하지 않는다. 문양은 색상, 클럽 같은 특정 조건은 숫자 범위 등 우리 게임 규칙으로 치환한다.
- Legendary/Rare는 초반에 완전히 막지 않는다. 낮은 확률이라도 초반 등장 가능성을 열어 희열 요소를 만든다.
- Pack/Voucher/Jester/Item/Gear는 모두 “덱 고갈 완화, 빌드 선택, 점수 성장, 장기 동기”의 역할로 재분류한다.

## 용어 정의

- 기준 스코어커브 / `base_score_curve`
  - 치환 후보와 보스 제약을 얹기 전의 small/big/boss, station별 기본 target score 곡선이다.
  - 이 레이어가 먼저 진행 가능해야 이후 후보와 제약의 효과를 해석할 수 있다.
- 룰 치환 후보 / `adapted_rule_candidate`
  - Balatro의 Joker/Jester, Planet, Tarot, Voucher, Pack 같은 요소를 우리 게임 규칙으로 바꾼 시뮬 전용 후보다.
  - 문양은 색상, face card는 11~13, rank는 1~13 타일, hand/score 효과는 confirm/line/deck/board pressure로 치환한다.
- 치환 후보 풀 / `adapted_candidate_pool`
  - 여러 `adapted_rule_candidate`를 rarity, category, loadout 궁합, 등장 확률로 묶은 시뮬 전용 market profile이다.
  - 예: `s1_probabilistic_candidate_pool`, `s1_full_safe_candidate_pool`.
- 보스 제약 치환 세트 / `boss_constraint_adaptation_set`
  - Balatro boss/blind 제약을 우리 게임의 색상, rank, face tile, confirm count, score multiplier, deck pressure 제약으로 바꾼 세트다.
  - 예: `repeat_rank_pressure_v4`, `confirm_count_tax_v2`, `face_tile_dampener`.
- 레벨링 학습 데이터 / `leveling_dataset`
  - `base_score_curve`, `boss_constraint_adaptation_set`, `adapted_candidate_pool`을 단계적으로 얹어 만든 summary/report 기반 데이터다.
  - clear rate만 보지 않고 turn drag, deck exhausted, board locked, score spike, loadout gap, station_path survival을 함께 본다.

## 레이어 순서

1. `base_score_curve`
   - 후보 없음, 보스 제약 없음 또는 최소.
   - small/big/boss와 station_path가 진행 가능한지 본다.
2. `boss_constraint_adaptation_set`
   - 보스 제약 치환 세트를 얹어 hard wall이 생기는지 본다.
3. `adapted_rule_candidate` / `adapted_candidate_pool`
   - Jester/Planet/Tarot/Voucher/Pack 치환 후보가 막힌 구간을 풀고 재미 구간을 만드는지 본다.
4. `leveling_dataset`
   - matrix stress와 station_path survival을 분리해 학습/해석한다.
5. 실제 구현 승격
   - 아직 현재 단계가 아니다. 수치와 역할이 안정될 때 먼저 “실 구현 후보로 승격 가능”이라고 명시한다.

## 현재까지 한 일

- Balatro 참고 페이지 2개의 데이터 부분을 크롤링해 원본 인덱스를 만들었다.
  - `logs/research/balatro_reference_index.json`
  - `logs/research/rummi_balatro_adaptation_backlog.json`
- Common 기반 Jester를 우리 게임의 Jester로 매핑했다.
  - 예: `greedy_joker`는 `greedy_jester`로 본다.
- Rare/XMult 계열 Jester 후보를 데이터와 런타임에 추가했다.
- `station_curve_125`, `station_curve_135` 중심으로 S5/S6 후반 병목을 재검증했다.
- 실제 UI 없이 시뮬 전용 market profile을 추가했다.
  - `s1_tile_pack_small`
  - `s1_pair_seed_pack`
  - `s1_color_seed_pack`
  - `s1_face_seed_pack`
- 실제 마켓 구조와 UI를 확정하기 전까지는 `s1_random_candidate_pool`처럼 랜덤 등장/구매를 가정하는 시뮬 전용 profile로 후보를 넓게 검증한다.
- sweep 실행 중 진행 상황이 보이도록 30초 heartbeat를 추가했다.

## 현재까지의 실험 결론

### v6: 가상 강화 preset

주요 파일:

- `logs/sim/ml_sweep_virtual_enhance_v6_summary.json`
- `logs/sim/ml_sweep_virtual_enhance_v6_summary_bottleneck_report.md`

결론:

- `planet_like_rank_level`, `tarot_like_tile_shape`, `enhanced_line_score`는 단독으로 보스 병목을 해결하지 못했다.
- 특히 S5 boss에서 덱 고갈이 크게 남았다.
- `rare_jester_engine`과 `s5_boss_bridge_build` 쪽이 훨씬 안정적이었다.

### v7: Rare/XMult Jester

주요 파일:

- `logs/sim/ml_sweep_rare_xmult_v7_summary.json`
- `logs/sim/ml_sweep_rare_xmult_v7_summary_bottleneck_report.md`

결론:

- Rare/XMult Jester는 재미 있는 고점 후보지만, 덱 고갈 해결책은 아니다.
- `rare_xmult_engine`은 일부 조건에서 높은 점수 잠재력은 있으나 boss에서 deck exhausted가 크게 남는다.
- `rare_jester_engine`, `s5_boss_bridge_build`, `s6_boss_breaker_build`가 더 안정적인 진행형 후보였다.

### v8: Pack/덱 추가 market profile

주요 파일:

- `logs/sim/ml_sweep_tile_pack_v8_summary.json`
- `logs/sim/ml_sweep_tile_pack_v8_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_tile_pack_v8_summary_ml_insights_report.md`

Boss 전체 기준:

| market profile | clear | deck exhausted |
|---|---:|---:|
| `none` | 64.8% | 33.8% |
| `s1_tile_pack_small` | 68.9% | 29.3% |
| `s1_pair_seed_pack` | 69.1% | 28.9% |
| `s1_color_seed_pack` | 69.3% | 28.7% |
| `s1_face_seed_pack` | 69.4% | 28.9% |
| `s1_buy_discard_glove` | 74.7% | 24.3% |

결론:

- Pack은 `none` 대비 덱 고갈 완화에 유의미하다.
- 현재의 `+2 tile Pack`만으로는 기존 `discard_glove`보다 약하다.
- 따라서 Pack 방향은 맞지만, 실 구현 후보로 확정하기 전에 Pack 크기, 선택형 Pack, Voucher, 덱 성장 Jester를 결합해 더 검증해야 한다.

### v9: 랜덤 후보 market pool

주요 파일:

- `logs/sim/ml_sweep_random_market_v9_summary.json`
- `logs/sim/ml_sweep_random_market_v9_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_random_market_v9_summary_ml_insights_report.md`

Boss 전체 기준:

| market profile | clear | deck exhausted |
|---|---:|---:|
| `none` | 65.8% | 32.7% |
| `s1_random_candidate_pool` | 69.3% | 29.1% |
| `s1_color_seed_pack` | 69.5% | 28.7% |
| `s1_tile_pack_small` | 69.2% | 28.9% |
| `s1_buy_discard_glove` | 72.9% | 25.8% |

결론:

- 랜덤 후보 pool은 `none`보다 유의미하게 낫고 개별 Pack과 비슷한 수준이다.
- 이 방식은 실제 마켓/UI를 확정하지 않고도 “랜덤 등장 가정”으로 후보군을 넓게 검증하는 데 적합하다.
- 단, 현재 pool은 `discard_glove`보다 약하므로 Pack 크기, Voucher, 덱 성장 Jester가 추가로 필요하다.

### v10: Pack 크기와 build-aware Pack

주요 파일:

- `logs/sim/ml_sweep_pack_size_v10_summary.json`
- `logs/sim/ml_sweep_pack_size_v10_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_pack_size_v10_summary_ml_insights_report.md`

Boss 전체 기준:

| market profile | clear | deck exhausted | turn |
|---|---:|---:|---:|
| `none` | 65.8% | 32.7% | 98.1 |
| `s1_tile_pack_small` | 69.3% | 28.9% | 100.1 |
| `s1_tile_pack_plus3` | 71.1% | 26.8% | 100.4 |
| `s1_tile_pack_plus4` | 71.9% | 26.3% | 101.3 |
| `s1_tile_pack_plus5` | 74.4% | 24.0% | 102.2 |
| `s1_build_aware_pack_plus3` | 71.7% | 26.8% | 100.7 |
| `s1_build_aware_pack_plus5` | 74.8% | 23.1% | 101.3 |
| `s1_buy_discard_glove` | 74.6% | 24.4% | 94.0 |

결론:

- 단순 랜덤 +N은 하한선으로만 봐야 한다. 실제 유저는 자주 만드는 족보에 맞는 숫자/색을 고를 가능성이 높다.
- `build-aware +5`는 boss clear 기준으로 `discard_glove`와 동급 이상이며, deck exhausted는 더 낮다.
- 단점은 turn 수와 board locked가 늘어날 수 있다는 점이다. 덱을 늘리는 것만으로는 플레이 템포가 느려질 수 있으므로 선택형 Pack 또는 bot 선택 품질 개선이 필요하다.
- 다음 실험은 “N장 중 1~2장 선택”과 “현재/이전 전투에서 자주 만든 족보 기반 선택”이다.

### v11: 확률형 시뮬 마켓 후보 pool

주요 파일:

- `logs/sim/ml_sweep_probabilistic_candidates_v11_summary.json`
- `logs/sim/ml_sweep_probabilistic_candidates_v11_report.md`
- `logs/sim/ml_sweep_probabilistic_candidates_v11_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_probabilistic_candidates_v11_summary_ml_insights_report.md`

실험 범위:

- market profile: `none`, `s1_buy_discard_glove`, `s1_build_aware_pack_plus5`, `s1_probabilistic_candidate_pool`
- station: S5, S6
- experiment: `station_curve_125`, `station_curve_135`
- loadout: `s5_power_build`, `rare_jester_engine`, `s5_boss_bridge_build`
- 실행: `summary-only`, 100 runs per experiment candidate

Boss 전체 기준:

| market profile | clear | deck exhausted | board locked | turn |
|---|---:|---:|---:|---:|
| `none` | 65.1% | 34.2% | 0.7% | 98.7 |
| `s1_buy_discard_glove` | 73.7% | 25.3% | 1.0% | 94.4 |
| `s1_build_aware_pack_plus5` | 76.2% | 23.2% | 0.6% | 101.7 |
| `s1_probabilistic_candidate_pool` | 70.2% | 27.6% | 2.1% | 97.6 |

결론:

- `s1_probabilistic_candidate_pool`은 `none`보다 boss clear를 +5.1%p 올리고 deck exhausted를 -6.6%p 낮췄다.
- 하지만 고정 `s1_build_aware_pack_plus5`와 `discard_glove`보다는 약하다. 후보 pool 안에 점수/덱 압박을 직접 풀지 못하는 proxy가 섞인 영향으로 본다.
- build-aware Pack은 여전히 boss clear/deck pressure 기준 최강 후보지만, 평균 turn이 길어지는 단점이 유지된다.
- 확률형 pool은 평균 turn이 `discard_glove`보다 길고 `build_aware_pack_plus5`보다 짧아, “여러 후보가 섞인 실제 마켓에 가까운 하한선”으로는 의미가 있다.
- `s5_power_build`의 S5 boss는 여전히 최악 병목이다. `station_curve_135 s5_power_build S5 boss`는 clear 0%, deck exhausted 100%였고, 확률형 pool도 같은 조건에서 clear 0%, deck exhausted 92%, board locked 8%에 그쳤다.
- `rare_jester_engine`, `s5_boss_bridge_build`에서는 확률형 pool이 `none`보다 안정적이지만, 이미 강한 빌드에서는 `build_aware_pack_plus5`나 `discard_glove`가 더 명확하다.

시뮬 후보 해석:

- 이번 profile은 실제 게임 카탈로그가 아니라 시뮬 전용 proxy다.
- priority 1~2 후보 중 충돌 가능성이 큰 복사/파괴/판매/렌탈/이터널/네거티브, 도감/해금 전제, 저장 구조 변경 필요 후보는 제외했다.
- Common Jester는 높은 가중치, Uncommon/Rare는 낮은 가중치, Pack/Tarot/Planet은 중간 가중치, Voucher는 낮은 가중치, 강한 Rare/Legendary proxy는 아주 낮은 가중치로 뒀다.
- Rare/Legendary 가능성은 초반에도 0으로 막지 않았다.
- bot 선택 proxy는 loadout과 맞는 후보에 소폭 가중치를 주는 build-aware 방식이다.

다음 반복 방향:

- 확률형 pool 자체는 유지하되, 후보별 resolved 분포를 확인할 수 있는 raw 소형 실험을 별도로 돌린다.
- `s5_power_build` S5 boss 병목에는 단순 점수 Jester보다 덱 압박 완화/board locked 완화 후보가 더 필요하다.
- 다음 v12는 pool 안의 약한 proxy를 분리해 `resource_safety_pool`, `score_spike_pool`, `deck_shape_pool`처럼 역할별 확률 pool로 나눠 비교한다.
- 후보가 실제 구현으로 승격할 단계는 아직 아니다. 현재는 시뮬 전용 profile 검증 단계다.

### v12: 충돌 제외 후 전체 safe 후보 pool

주요 파일:

- `logs/sim/ml_sweep_full_safe_candidate_pool_v12_summary.json`
- `logs/sim/ml_sweep_full_safe_candidate_pool_v12_report.md`
- `logs/sim/ml_sweep_full_safe_candidate_pool_v12_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_full_safe_candidate_pool_v12_summary_ml_insights_report.md`

실험 범위:

- market profile: `none`, `s1_buy_discard_glove`, `s1_build_aware_pack_plus5`, `s1_probabilistic_candidate_pool`, `s1_full_safe_candidate_pool`
- station: S5, S6
- experiment: `station_curve_125`, `station_curve_135`
- loadout: `s5_power_build`, `rare_jester_engine`, `s5_boss_bridge_build`
- 실행: `summary-only`, 100 runs per experiment candidate

후보 구성:

- `logs/research/rummi_balatro_adaptation_backlog.json`의 priority 1~2 후보 중 충돌 가능성이 큰 항목만 제외했다.
- 제외 기준: 복사/파괴/판매/렌탈/이터널/네거티브, 도감/해금 전제, spectral/edition/seal 계층, high card처럼 현재 족보와 직접 맞지 않는 항목.
- 남은 후보는 약한 후보를 포함해 모두 시뮬 proxy로 매핑했다.
- 소형 raw 분포 확인에서 200개 sequence 기준으로 Jester 143, Tarot 28, Voucher 15, Planet 14가 선택됐다.
- rarity는 common 96, uncommon 34, rare 13, non-rarity item 57로 분포했다.
- raw 파일은 분포 확인 후 삭제했고, 본 sweep은 summary-only로 남겼다.
- `s1_full_safe_candidate_pool`은 선택된 원본 후보를 `resolved_market_candidate`와 `market_purchase_events[].source_candidate`에 기록한다.

Boss 전체 기준:

| market profile | clear | deck exhausted | board locked | turn |
|---|---:|---:|---:|---:|
| `none` | 62.7% | 35.4% | 1.9% | 98.1 |
| `s1_buy_discard_glove` | 73.5% | 25.9% | 0.6% | 94.5 |
| `s1_build_aware_pack_plus5` | 76.5% | 21.4% | 2.1% | 100.8 |
| `s1_probabilistic_candidate_pool` | 69.0% | 28.8% | 2.2% | 98.4 |
| `s1_full_safe_candidate_pool` | 70.5% | 28.0% | 1.5% | 97.3 |

Loadout별 boss 기준:

| loadout / market | clear | deck exhausted | board locked | turn |
|---|---:|---:|---:|---:|
| `s5_power_build` / `none` | 2.0% | 97.4% | 0.7% | 111.5 |
| `s5_power_build` / `s1_probabilistic_candidate_pool` | 4.4% | 93.4% | 2.2% | 114.0 |
| `s5_power_build` / `s1_full_safe_candidate_pool` | 8.1% | 90.1% | 1.7% | 112.2 |
| `s5_power_build` / `s1_build_aware_pack_plus5` | 9.4% | 88.0% | 2.6% | 121.2 |
| `rare_jester_engine` / `s1_full_safe_candidate_pool` | 79.9% | 19.5% | 0.6% | 97.7 |
| `s5_boss_bridge_build` / `s1_full_safe_candidate_pool` | 90.5% | 7.4% | 2.1% | 90.2 |

결론:

- 약한 후보까지 포함한 `s1_full_safe_candidate_pool`은 `none`보다 확실히 낫고, 기존 `s1_probabilistic_candidate_pool`보다 boss 기준 clear/deck/board locked가 조금 더 좋다.
- 그래도 `s1_build_aware_pack_plus5`보다 강하지 않다. 넓은 후보 pool은 실제 마켓의 다양성을 보는 실험으로 유효하지만, S5/S6 병목 해소용 단일 해답은 아니다.
- `s5_power_build` 병목은 계속 심하다. full safe pool도 S5/S6 boss 합산 clear 8.1%, deck exhausted 90.1%에 그쳐 덱 압박 해소가 충분하지 않다.
- `rare_jester_engine`과 `s5_boss_bridge_build`는 full safe pool에서 성능이 안정적이다. 강한 빌드에는 다양한 후보가 성장 파생을 만들지만, 약한 빌드에는 resource/deck safety가 먼저 필요하다.
- “좋은 효과만 존재해야 한다”는 전제가 아니라, 약한 효과도 빌드 다양성을 만든다는 방향이 맞다. 다만 약한 효과를 포함한 pool은 병목 완화력이 희석되므로, 실제 구현 전에는 역할군별 등장률과 보정 장치를 따로 봐야 한다.

다음 반복 방향:

- `s1_full_safe_candidate_pool`은 유지한다. 이는 실제 마켓 다양성의 하한선 역할이다.
- 다음 v13은 원 후보 `source_candidate`별 결과를 볼 수 있게 full safe pool만 raw를 보존하는 300~500 runs 소형 실험을 별도로 돌린다.
- 이후 source 후보를 `resource_safety`, `deck_shape`, `score_growth`, `economy`, `special_weak`로 라벨링해 약한 후보가 어느 역할군에서 생기는지 본다.
- 실제 구현 전환은 아직 아니다. 현재는 “다양한 약/강 후보가 섞인 시뮬 마켓에서 병목이 어디서 드러나는가”를 보는 단계다.

### v13: 전체 safe 후보 + 보스 제약 pool 병목

참조:

- Balatro 엔티/블라인드/보스 구조 참고: `https://danbain.tistory.com/entry/발라트로-공략-2-엔티`
- 주요 리포트:
  - `logs/sim/ml_sweep_boss_constraints_full_curve_v13_summary.json`
  - `logs/sim/ml_sweep_boss_constraints_full_curve_v13_report.md`
  - `logs/sim/ml_sweep_boss_constraints_full_curve_v13_summary_bottleneck_report.md`
  - `logs/sim/ml_sweep_boss_constraints_full_curve_v13_summary_ml_insights_report.md`
- raw probe:
  - `logs/sim/ml_sweep_boss_constraints_v13_raw_probe.jsonl`
  - `logs/sim/ml_sweep_boss_constraints_v13_raw_probe_s6_s7.jsonl`
  - `logs/sim/ml_sweep_boss_constraints_v13_raw_probe_s7.jsonl`

실험 범위:

- experiment: `station_curve_125`, `station_curve_135`, `station_curve_125_boss_constraint_pool_v1`, `station_curve_135_boss_constraint_pool_v1`
- market profile: `none`, `s1_buy_discard_glove`, `s1_build_aware_pack_plus5`, `s1_probabilistic_candidate_pool`, `s1_full_safe_candidate_pool`
- station: S1~S8
- tier: small, big, boss
- loadout: `baseline`, `s1_entry_bridge_build`, `s2_foundation_build`, `s3_hand_growth_build`, `s4_resource_build`, `s5_power_build`, `rare_jester_engine`, `s5_boss_bridge_build`, `s8_finale_build`
- 실행: `summary-only`, 40 runs per experiment candidate

보스 제약 pool 치환:

- 색상 디버프: 문양을 색상으로 치환한다.
- 그림 카드 디버프: face tile 11~13 감점으로 치환한다.
- 같은 족보 반복 금지: 같은 rank 중심 scoring line 반복 감점으로 치환한다.
- 한 종류 족보만 허용: 첫 scoring rank와 다른 rank 중심 line 감점으로 치환한다.
- 1회 핸드 제한: confirm 횟수 제한으로 치환한다.
- 전체 점수 반감: scoring line 전체 multiplier 감점으로 치환한다.
- 초대형 블라인드: target multiplier 상승으로 치환한다.
- 손패/버리기 압박: max hand size 또는 resource squeeze로 치환한다.

전체 결과:

| experiment | clear | deck exhausted | board locked | turn | max hit |
|---|---:|---:|---:|---:|---:|
| `station_curve_125` | 93% | 6% | 1% | 64.9 | 271.3 |
| `station_curve_125_boss_constraint_pool_v1` | 91% | 6% | 1% | 62.6 | 257.0 |
| `station_curve_135` | 91% | 8% | 1% | 67.3 | 269.5 |
| `station_curve_135_boss_constraint_pool_v1` | 90% | 8% | 1% | 66.1 | 257.3 |

Tier 기준:

| tier / family | clear | deck exhausted |
|---|---:|---:|
| small / base curve | 99.4% | 0.2% |
| small / constraint pool | 99.3% | 0.3% |
| big / base curve | 96.7% | 2.2% |
| big / constraint pool | 96.8% | 2.3% |
| boss / base curve | 78.2% | 20.1% |
| boss / constraint pool | 74.4% | 23.7% |

Station/Tier 주요 병목:

| station/tier | clear | deck exhausted | turn |
|---|---:|---:|---:|
| S7 boss | 30% | 68% | 113.3 |
| S6 boss | 49% | 5% | 73.3 |
| S4 boss | 66% | 33% | 93.2 |
| S3 boss | 71% | 28% | 87.9 |
| S8 boss | 66% | 32% | 108.8 |
| S5 boss | 76% | 23% | 96.3 |

Market별 boss 기준:

| market profile | boss clear |
|---|---:|
| `none` | 79.5% |
| `s1_build_aware_pack_plus5` | 75.6% |
| `s1_buy_discard_glove` | 74.3% |
| `s1_probabilistic_candidate_pool` | 73.8% |
| `s1_full_safe_candidate_pool` | 73.5% |

해석:

- small/big는 여전히 대부분 안정적이고, 일부는 `too_easy`/`tempo_too_fast`/`resource_too_loose`로 잡힌다.
- boss는 base curve에서도 병목이지만, constraint pool을 넣으면 병목 성격이 달라진다.
- 기존 `s1_build_aware_pack_plus5`는 덱 고갈 완화에는 강했지만, 반복 rank 제한이나 confirm 제한 같은 보스 제약까지 포함하면 만능 해답이 아니다.
- market profile이 boss 전체 clear에서 낮아 보이는 이유는 후보가 약해서만이 아니라, 더 깊은 구간과 더 강한 제약까지 진행하면서 병목에 노출되는 효과도 섞여 있다.
- 따라서 “현재 보스만 뚫는 튜닝”은 충분하지 않다. 전체 후보와 제약이 들어온 상태에서 병목을 봐야 한다는 판단이 맞다.

raw probe 확인:

| constraint | sample | clear | avg penalty | 주요 stop reason |
|---|---:|---:|---:|---|
| S3 `face_tile_dampener` | 1388 | 63.3% | 169.5 | `drawPileExhausted`, `cleared` |
| S4 `repeat_rank_limit` | 820 | 0.1% | 742.1 | `drawPileExhausted` |
| S6 `confirm_limit_pressure` | 1166 | 0.0% | 0.0 | `sim_boss_confirm_limit` |
| S7 `all_score_dampener` | 1003 | 35.9% | 692.3 | `drawPileExhausted` |

raw probe 결론:

- S4 `repeat_rank_limit`는 현재 v1 강도로는 거의 하드 벽이다. `s2_foundation_build`, `s4_resource_build`, `s5_power_build` 모두 clear 0~0.2% 수준으로 떨어진다.
- S6 `confirm_limit_pressure`는 점수/덱 병목이 아니라 `sim_boss_confirm_limit` 종료다. 현재 우리 룰에서 “1회 또는 2회 confirm으로 끝내라”는 proxy는 지나치게 인위적이다.
- S7 `all_score_dampener`는 후반 점수/덱 압박 병목이다. `s5_power_build`는 clear 0%, `rare_jester_engine`은 32.6%, `s5_boss_bridge_build`는 47.9%로 빌드 차이가 드러난다.
- S3 `face_tile_dampener`는 빌드와 market에 따라 37~91%까지 차이가 나므로, 완전 배제할 제약은 아니고 대응 빌드를 만드는 후보로 남길 수 있다.

다음 반복 방향:

- 보스 제약 pool은 유지하되 v1을 그대로 목표 난이도로 쓰지 않는다.
- S4 `repeat_rank_limit`는 hard 제약이므로 soft profile에서 penalty multiplier를 낮추거나, boss 후반 전용으로 미룬다.
- S6 `confirm_limit_pressure`는 현재 룰에 맞게 “confirm 횟수 제한” 대신 “confirm 후 target 일부 증가”, “첫 confirm 외 감점”, “남은 deck 압박” 같은 완충형 proxy로 바꿔야 한다.
- S7 `all_score_dampener`는 후반 boss wall로 의미가 있다. 다만 `s5_power_build`가 완전히 막히므로 score growth 후보와 deck sustain 후보의 조합을 추가로 봐야 한다.
- small/big는 지금 당장 상향하지 않는다. 이 구간은 재미/템포 측면에서 너무 쉬운 그룹이 많아, 보강은 boss 대응 후보와 station curve 쪽에 집중한다.
- 실제 UI/저장/실제 마켓 구조로 옮길 단계는 아직 아니다. 현재는 시뮬 전용 boss constraint와 후보 pool의 병목 분해 단계다.

### v14: target score curve 재검증

사용자 지적대로 v13의 40 runs probe는 판단용으로 부족했다. v1~v3 수준으로 runs를 줄이지 않고 target score curve부터 다시 봤다.

주요 파일:

- `logs/sim/ml_sweep_target_v4_constraints_full_safe_r400_summary.json`
- `logs/sim/ml_sweep_target_v4_constraints_full_safe_r400_report.md`
- `logs/sim/ml_sweep_target_v4_constraints_full_safe_r400_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_target_v4_constraints_full_safe_r400_summary_ml_insights_report.md`

실험 범위:

- mode: `progression_curve`
- runs per candidate: 400
- 후보 수: 32
- 총 run 수: 677,253
- stations: S2, S4, S5, S6
- station curve: `station_curve_125`, `station_curve_135`, `station_curve_125_boss_constraint_pool_v1`, `station_curve_135_boss_constraint_pool_v1`
- small multiplier: 1.05, 1.10
- big multiplier: 1.00, 1.05
- boss multiplier: 0.85, 0.95
- loadout: `baseline`, `s2_foundation_build`, `s3_hand_growth_build`, `s4_resource_build`, `s5_power_build`
- market profile: `none`, `s1_full_safe_candidate_pool`
- 실행: `summary-only`

전체 결과:

| family | clear | deck exhausted | board locked | turn |
|---|---:|---:|---:|---:|
| `station_curve_125` | 84.4% | 13.8% | 1.8% | 82.1 |
| `station_curve_135` | 80.5% | 17.7% | 1.8% | 85.0 |
| `station_curve_125_boss_constraint_pool_v1` | 80.0% | 18.2% | 1.7% | 80.5 |
| `station_curve_135_boss_constraint_pool_v1` | 78.8% | 19.4% | 1.8% | 84.3 |

Tier x family:

| tier / family | clear | deck exhausted | turn |
|---|---:|---:|---:|
| boss / `station_curve_125` | 66.6% | 31.0% | 94.3 |
| boss / `station_curve_135` | 66.3% | 31.3% | 94.5 |
| boss / `station_curve_125_boss_constraint_pool_v1` | 50.7% | 47.1% | 95.7 |
| boss / `station_curve_135_boss_constraint_pool_v1` | 57.1% | 40.6% | 95.5 |
| big / `station_curve_125` | 87.1% | 11.0% | 84.5 |
| big / `station_curve_135` | 76.6% | 21.3% | 89.0 |
| small / `station_curve_125` | 96.7% | 2.1% | 69.6 |
| small / `station_curve_135` | 94.3% | 4.4% | 74.5 |

Station/Tier 병목:

| station/tier | clear | deck exhausted | turn |
|---|---:|---:|---:|
| S5 boss | 9.0% | 88.2% | 110.8 |
| S4 boss | 26.0% | 71.7% | 109.3 |
| S6 boss | 36.4% | 56.4% | 107.5 |
| S5 big | 72.0% | 26.0% | 100.0 |
| S4 big | 80.6% | 17.2% | 95.1 |
| S2 boss | 92.5% | 5.2% | 82.4 |
| S2 small | 94.1% | 4.8% | 64.7 |

Target multiplier 관찰:

- boss multiplier 0.85는 0.95보다 낫지만, S4/S5 boss 병목을 충분히 풀지 못한다.
- boss 전체 기준 `station_curve_125 boss0.85`는 clear 69.6%, `station_curve_125 boss0.95`는 63.3%다.
- `station_curve_135 boss0.85`는 clear 69.2%, `station_curve_135 boss0.95`는 63.4%다.
- constraint pool에서는 boss0.85와 boss0.95 차이가 1~1.5%p 수준으로 작다. 즉 S4/S6 제약 병목은 target score만으로는 해결되지 않는다.
- small multiplier 1.10은 1.05보다 오히려 clear가 낮다. small은 이미 안정권이므로 올릴 이유가 약하다.
- big multiplier 1.05는 1.00보다 clear가 낮고 deck exhausted가 오른다. S5/S6로 이어지는 resource pressure를 키울 수 있다.

S4/S5 boss 핵심 비교:

| slice | clear | deck exhausted | 해석 |
|---|---:|---:|---|
| S4 boss / `station_curve_125` / boss0.85 / full safe | 78.8% | 18.7% | base curve에서는 target 완화 + full safe가 효과 있음 |
| S4 boss / `station_curve_135` / boss0.85 / full safe | 47.9% | 49.8% | 135 curve는 중반 boss 압박이 큼 |
| S4 boss / constraint pool / boss0.85~0.95 | 0~1.7% | 96~98% | 반복 rank 제약은 target score로 해결 불가 |
| S5 boss / `station_curve_125` / boss0.85 / full safe | 16.2% | 80.7% | base curve에서도 S5 boss target/deck 압박이 너무 큼 |
| S5 boss / `station_curve_135` / boss0.85 / full safe | 2.8% | 95.1% | 135 curve는 S5 boss wall로 과함 |

ML 리포트:

- 현재 등급: D
- good_playfeel: 576/2327 groups
- too_hard: 512/2327 groups
- needs_balance_attention: 1709/2327 groups
- target 모델 RandomForestRegressor: MAE 0.13, R2 +0.69
- 중요 피처는 `tier_index`, `station`, `loadout` 순서다. target multiplier보다 어느 station/tier인지가 더 크게 작동한다.

결론:

- target score 구간부터 다시 봐야 한다는 판단이 맞다.
- 현재 target grid에서 가장 무난한 큰 방향은 `station_curve_125`, small 1.05, big 1.00, boss 0.85다.
- 하지만 S5 boss는 이 조합에서도 충분히 풀리지 않는다. S5 boss는 target multiplier 0.85보다 더 낮추거나, station-specific target/resource 보정이 필요하다.
- S4 constraint pool은 target score 문제가 아니라 보스 제약 설계 문제다. `repeat_rank_limit`를 soft화하거나 후반 전용으로 미뤄야 한다.
- S6 constraint pool도 target score 문제가 아니라 confirm-limit proxy 문제다. 횟수 제한형 제약은 현재 룰에 맞게 완충형으로 바꿔야 한다.
- small/big target은 더 올리지 않는다. 특히 big 1.05는 후속 boss resource pressure를 키울 수 있다.
- 실제 구현으로 옮길 단계는 아직 아니다. 먼저 target curve v5와 boss constraint soft v2를 시뮬 전용으로 다시 돌려야 한다.

### v15: target curve v5 + boss constraint v2

v14 결론을 바탕으로 시뮬 전용 후보를 추가했다.

추가한 experiment:

- `station_curve_125_target_v5`
  - station curve는 1.25 유지
  - small target multiplier: 1.05
  - big target multiplier: 1.00
  - boss target multiplier:
    - S2: 0.95
    - S4: 0.85
    - S5: 0.65
    - S6: 0.75
  - S5/S6 boss에 board discard +1, hand discard +1, max hand size +1
- `station_curve_125_boss_constraint_pool_v2`
  - S4 `repeat_rank_limit`을 `repeat_rank_pressure_v2`로 완화
  - S6 `confirm_limit_pressure`를 hard stop이 아닌 `confirm_count_tax_v2`로 변경
  - confirm 2회 이후 scoring line 감점으로 압박한다.
- `station_curve_125_target_v5_boss_constraint_pool_v2`
  - target v5와 constraint v2를 합친 후보

주요 파일:

- `logs/sim/ml_sweep_target_v5_constraint_v2_r400_summary.json`
- `logs/sim/ml_sweep_target_v5_constraint_v2_r400_report.md`
- `logs/sim/ml_sweep_target_v5_constraint_v2_r400_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_target_v5_constraint_v2_r400_summary_ml_insights_report.md`

실험 범위:

- mode: `experiment_matrix`
- runs per candidate: 400
- 후보 수: 5
- 총 run 수: 120,541
- stations: S2, S4, S5, S6
- loadout: `baseline`, `s2_foundation_build`, `s3_hand_growth_build`, `s4_resource_build`, `s5_power_build`
- market profile: `none`, `s1_full_safe_candidate_pool`
- 실행: `summary-only`

전체 비교:

| experiment | clear | deck exhausted | board locked | turn |
|---|---:|---:|---:|---:|
| `station_curve_125_boss_constraint_pool_v1` | 80.0% | 18.3% | 1.8% | 80.1 |
| `station_curve_125_boss_constraint_pool_v2` | 82.4% | 15.9% | 1.8% | 80.8 |
| `station_curve_125` | 83.2% | 15.1% | 1.7% | 81.3 |
| `station_curve_125_target_v5` | 86.6% | 11.7% | 1.7% | 82.5 |
| `station_curve_125_target_v5_boss_constraint_pool_v2` | 86.6% | 11.7% | 1.7% | 82.2 |

Boss 기준:

| experiment | boss clear | boss deck exhausted | boss turn |
|---|---:|---:|---:|
| `station_curve_125_boss_constraint_pool_v1` | 49.2% | 48.4% | 98.5 |
| `station_curve_125_boss_constraint_pool_v2` | 57.0% | 40.6% | 98.4 |
| `station_curve_125` | 60.2% | 37.5% | 97.7 |
| `station_curve_125_target_v5` | 75.0% | 23.0% | 94.0 |
| `station_curve_125_target_v5_boss_constraint_pool_v2` | 73.7% | 24.1% | 94.5 |

Station/Tier 주요 비교:

| station/tier / experiment | clear | deck exhausted | turn |
|---|---:|---:|---:|
| S4 boss / constraint v1 | 0.1% | 97.8% | 113.9 |
| S4 boss / constraint v2 | 25.8% | 72.1% | 110.1 |
| S4 boss / target v5 + constraint v2 | 50.7% | 46.8% | 105.2 |
| S5 boss / base 125 | 5.5% | 91.6% | 111.3 |
| S5 boss / target v5 | 48.0% | 49.8% | 103.9 |
| S5 boss / target v5 + constraint v2 | 83.2% | 15.5% | 95.3 |
| S6 boss / base 125 | 13.3% | 82.2% | 111.4 |
| S6 boss / constraint v2 | 26.4% | 70.1% | 111.3 |
| S6 boss / target v5 | 57.3% | 41.9% | 106.1 |
| S6 boss / target v5 + constraint v2 | 64.6% | 34.2% | 102.9 |

해석:

- `boss_constraint_pool_v2`는 v1보다 명확히 낫다. boss clear +7.8%p, deck exhausted -7.8%p다.
- `target_v5`는 S5/S6 boss 병목을 크게 줄인다. 특히 S5 boss는 base 5.5%에서 target v5 48.0%로 오른다.
- `target_v5 + constraint_v2`는 전체 boss 기준으로 가장 안정적이다. boss clear 73.7%, deck exhausted 24.1%다.
- 하지만 S5 boss는 83.2%까지 올라가 과보정 가능성이 있다. S5는 target multiplier 0.65 또는 resource +1을 그대로 확정하면 안 된다.
- S4 boss는 constraint v2만으로는 아직 부족하지만, target v5와 결합하면 50.7%까지 회복한다.
- S6 boss는 confirm hard stop을 제거한 뒤에도 deck pressure가 남는다. target/resource 보정이 필요하지만, S5만큼 강하게 보정하면 안 된다.
- full safe market은 전체 clear를 83%에서 85%로 올리고 deck exhausted를 15%에서 13%로 낮춘다. 하한선 후보 pool로 계속 유지할 가치가 있다.

다음 반복 방향:

- `boss_constraint_pool_v2`는 유지한다. v1은 hard-wall 확인용으로만 남긴다.
- target v6는 S4/S6은 유지 또는 소폭 보강하고, S5는 과보정을 줄인다.
  - S5 boss target multiplier 후보: 0.70, 0.75
  - S5 resource 후보: resource +0 또는 max hand size +0
  - S6 boss target multiplier 후보: 0.70, 0.75
  - S6 resource 후보: resource +1 유지
- 다음 sweep은 S4/S5/S6 boss 중심으로 400~500 runs를 유지한다.
- 아직 실제 구현 전환 단계가 아니다. target/constraint 값이 안정된 뒤에만 실제 boss/market 설계를 논의한다.

### v16: target curve v6 S5 과보정 재검증

v15에서 `target_v5 + constraint_v2`가 전체 boss clear를 크게 올렸지만, S5 boss가 83.2%까지 올라가 과보정 가능성이 있었다. 따라서 S4/S6 보정은 유지하고 S5만 줄인 v6 후보를 시뮬 전용으로 추가했다.

추가한 experiment:

- `station_curve_125_target_v6_s5_070`
  - S5 boss target multiplier: 0.70
  - S5 boss board discard/hand discard/max hand size 추가 보정 없음
- `station_curve_125_target_v6_s5_075`
  - S5 boss target multiplier: 0.75
  - S5 boss board discard/hand discard/max hand size 추가 보정 없음
- `station_curve_125_target_v6_s5_070_boss_constraint_pool_v2`
- `station_curve_125_target_v6_s5_075_boss_constraint_pool_v2`

주요 파일:

- `logs/sim/ml_sweep_target_v6_s5_r400_summary.json`
- `logs/sim/ml_sweep_target_v6_s5_r400_report.md`
- `logs/sim/ml_sweep_target_v6_s5_r400_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_target_v6_s5_r400_summary_ml_insights_report.md`

실험 범위:

- mode: `experiment_matrix`
- runs per candidate: 400
- 후보 수: 3
- 총 run 수: 78,878
- stations: S2, S4, S5, S6
- loadout: `baseline`, `s2_foundation_build`, `s3_hand_growth_build`, `s4_resource_build`, `s5_power_build`
- market profile: `none`, `s1_full_safe_candidate_pool`
- 실행: `summary-only`

전체 비교:

| experiment | clear | deck exhausted | board locked | turn |
|---|---:|---:|---:|---:|
| `target_v5 + constraint_v2` | 86.5% | 11.8% | 1.7% | 82.2 |
| `target_v6_s5_070 + constraint_v2` | 86.2% | 12.1% | 1.7% | 82.2 |
| `target_v6_s5_075 + constraint_v2` | 86.0% | 12.2% | 1.7% | 82.0 |

Blind tier 비교:

| experiment / tier | clear | deck exhausted | board locked | turn |
|---|---:|---:|---:|---:|
| `target_v5 + constraint_v2` / small | 97.0% | 1.7% | 1.2% | 69.6 |
| `target_v5 + constraint_v2` / big | 86.2% | 11.8% | 2.1% | 84.6 |
| `target_v5 + constraint_v2` / boss | 74.2% | 23.8% | 2.0% | 94.4 |
| `target_v6_s5_070 + constraint_v2` / small | 97.3% | 1.5% | 1.1% | 69.2 |
| `target_v6_s5_070 + constraint_v2` / big | 86.5% | 11.6% | 1.9% | 84.4 |
| `target_v6_s5_070 + constraint_v2` / boss | 72.8% | 25.2% | 2.1% | 95.1 |
| `target_v6_s5_075 + constraint_v2` / small | 96.9% | 1.9% | 1.2% | 69.1 |
| `target_v6_s5_075 + constraint_v2` / big | 87.8% | 10.2% | 1.9% | 83.8 |
| `target_v6_s5_075 + constraint_v2` / boss | 71.3% | 26.6% | 2.1% | 95.2 |

Station boss 비교:

| station boss / experiment | clear | deck exhausted | board locked | turn |
|---|---:|---:|---:|---:|
| S2 boss / `target_v5 + constraint_v2` | 91.5% | 6.3% | 2.2% | 83.6 |
| S2 boss / `target_v6_s5_070 + constraint_v2` | 91.4% | 6.4% | 2.2% | 83.8 |
| S2 boss / `target_v6_s5_075 + constraint_v2` | 90.7% | 7.0% | 2.2% | 83.4 |
| S4 boss / `target_v5 + constraint_v2` | 51.8% | 46.2% | 2.0% | 104.9 |
| S4 boss / `target_v6_s5_070 + constraint_v2` | 50.4% | 47.4% | 2.2% | 105.5 |
| S4 boss / `target_v6_s5_075 + constraint_v2` | 50.9% | 46.5% | 2.5% | 105.1 |
| S5 boss / `target_v5 + constraint_v2` | 82.8% | 15.4% | 1.8% | 95.4 |
| S5 boss / `target_v6_s5_070 + constraint_v2` | 74.1% | 24.1% | 1.9% | 99.0 |
| S5 boss / `target_v6_s5_075 + constraint_v2` | 64.7% | 34.0% | 1.3% | 102.7 |
| S6 boss / `target_v5 + constraint_v2` | 65.9% | 33.1% | 1.0% | 102.5 |
| S6 boss / `target_v6_s5_070 + constraint_v2` | 71.1% | 27.2% | 1.6% | 101.7 |
| S6 boss / `target_v6_s5_075 + constraint_v2` | 70.7% | 28.4% | 0.9% | 100.6 |

S5 boss market profile 비교:

| experiment / market | clear | deck exhausted | board locked | turn |
|---|---:|---:|---:|---:|
| `target_v5 + constraint_v2` / none | 80.9% | 17.3% | 1.7% | 95.7 |
| `target_v5 + constraint_v2` / full safe | 83.9% | 14.2% | 1.8% | 95.2 |
| `target_v6_s5_070 + constraint_v2` / none | 70.3% | 28.7% | 1.1% | 100.1 |
| `target_v6_s5_070 + constraint_v2` / full safe | 76.6% | 21.0% | 2.4% | 98.3 |
| `target_v6_s5_075 + constraint_v2` / none | 58.2% | 40.4% | 1.3% | 103.5 |
| `target_v6_s5_075 + constraint_v2` / full safe | 68.8% | 30.0% | 1.2% | 102.1 |

해석:

- v6 S5 0.70은 S5 boss 과보정을 줄인다. v5의 S5 boss clear 82.8%를 74.1%로 낮추고, 전체 clear는 86.5%에서 86.2%로 거의 유지한다.
- v6 S5 0.75는 너무 세게 되돌린다. S5 boss clear가 64.7%로 낮아지고 deck exhausted가 34.0%까지 오른다.
- small/big는 세 후보 모두 큰 차이가 없다. S5 보정 변경의 영향은 주로 boss에 집중된다.
- S4 boss는 여전히 가장 큰 병목이다. 세 후보 모두 S4 boss clear가 약 50~52%, deck exhausted가 약 46~47%다.
- S6 boss는 v6 후보에서 오히려 좋아졌다. S5 자원 브리지를 제거하면서 run 분포가 달라졌거나, constraint v2와 S6 보정 조합이 더 잘 맞는 것으로 보인다. 다만 이 차이는 추가 seed로 확인해야 한다.
- full safe market은 S5 boss에서 여전히 의미가 있다. 특히 v6 S5 0.70에서 none 70.3% -> full safe 76.6%로 오른다.

결론:

- 현재 후보 중 다음 기준점은 `station_curve_125_target_v6_s5_070_boss_constraint_pool_v2`다.
- `target_v6_s5_075`는 S5 boss를 다시 deck pressure 병목으로 만들 가능성이 크므로 보류한다.
- 다음 반복은 S4 boss 병목을 직접 다룬다. target만 낮추는 방식보다 S4 제약/패턴 보강을 먼저 검토한다.
- S5는 0.70을 유지하되, full safe market이 없을 때 70% 초반으로 내려가는 점을 감안해 S5 boss 목표 구간은 70~78%로 잡는다.
- 아직 실제 구현 전환 단계가 아니다. 현재 변경은 시뮬 전용 target/constraint 후보와 리포트 기록에 한정한다.

### v18: S4 repeat-rank boss 제약 중간 강도

v16에서 다음 병목으로 남은 S4 boss를 직접 다뤘다. S4 boss는 station slot상 `repeat_rank_pressure_v2`가 걸리는 구간이며, v2의 `repeat_rank_score_multiplier = 0.72`는 deck exhaustion을 크게 유발했다.

먼저 v17에서 `repeat_rank_pressure_v3 = 0.85`와 S4 target 0.80 후보를 확인했다. 이 과정에서 v3가 S6 confirm 제약을 v2의 soft tax가 아니라 예전 confirm limit로 되돌리는 회귀가 발견되어 테스트로 막았다. 이후 v17b 기준으로 재실행했다.

v17b 관찰:

- `repeat_rank_pressure_v3 = 0.85`는 S4 boss deck pressure를 크게 낮춘다.
- 하지만 S4 boss clear가 72~73%까지 올라, 강한 loadout/full safe market에서는 쉬운 쪽으로 치우친다.
- S4 target 0.80까지 같이 적용한 v7은 S4 boss clear 77% 이상으로 올라 보류한다.

따라서 v18에서 중간 강도 후보를 추가했다.

추가한 experiment:

- `station_curve_125_target_v6_s5_070_boss_constraint_pool_v4`
  - target curve는 v6 유지
  - S5 boss target multiplier 0.70, S5 resource bridge 없음
  - S4 `repeat_rank_pressure_v4`
  - `repeat_rank_score_multiplier = 0.80`
  - S6 confirm 제약은 v2/v3와 같은 `confirm_count_tax_v2` 유지

주요 파일:

- `logs/sim/ml_sweep_s4_constraint_v18_r400_summary.json`
- `logs/sim/ml_sweep_s4_constraint_v18_r400_report.md`
- `logs/sim/ml_sweep_s4_constraint_v18_r400_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_s4_constraint_v18_r400_summary_ml_insights_report.md`

실험 범위:

- mode: `experiment_matrix`
- runs per candidate: 400
- 후보 수: 3
- 총 run 수: 82,775
- stations: S2, S4, S5, S6
- loadout: `baseline`, `s2_foundation_build`, `s3_hand_growth_build`, `s4_resource_build`, `s5_power_build`
- market profile: `none`, `s1_full_safe_candidate_pool`
- 실행: `summary-only`

전체 비교:

| experiment | clear | deck exhausted | board locked | turn |
|---|---:|---:|---:|---:|
| `target_v6_s5_070 + constraint_v2` | 86.4% | 12.0% | 1.7% | 82.3 |
| `target_v6_s5_070 + constraint_v4` | 87.1% | 11.2% | 1.7% | 82.7 |
| `target_v6_s5_070 + constraint_v3` | 87.5% | 10.8% | 1.7% | 82.9 |

Blind tier 비교:

| experiment / tier | clear | deck exhausted | board locked | turn |
|---|---:|---:|---:|---:|
| `constraint_v2` / small | 97.0% | 1.9% | 1.1% | 69.5 |
| `constraint_v2` / big | 86.9% | 11.2% | 1.9% | 84.5 |
| `constraint_v2` / boss | 73.3% | 24.8% | 2.0% | 95.0 |
| `constraint_v4` / small | 97.0% | 1.9% | 1.1% | 70.4 |
| `constraint_v4` / big | 85.4% | 12.7% | 1.9% | 85.6 |
| `constraint_v4` / boss | 77.4% | 20.6% | 2.0% | 94.2 |
| `constraint_v3` / small | 96.8% | 2.0% | 1.2% | 71.0 |
| `constraint_v3` / big | 84.4% | 13.6% | 1.9% | 86.2 |
| `constraint_v3` / boss | 79.8% | 18.2% | 2.0% | 93.6 |

Station boss 비교:

| station boss / experiment | clear | deck exhausted | board locked | turn |
|---|---:|---:|---:|---:|
| S2 boss / `constraint_v2` | 91.8% | 6.4% | 1.9% | 83.4 |
| S2 boss / `constraint_v4` | 91.8% | 6.3% | 1.9% | 83.4 |
| S2 boss / `constraint_v3` | 91.8% | 6.3% | 1.9% | 83.4 |
| S4 boss / `constraint_v2` | 51.4% | 46.5% | 2.1% | 105.4 |
| S4 boss / `constraint_v4` | 65.0% | 32.9% | 2.1% | 102.2 |
| S4 boss / `constraint_v3` | 72.3% | 25.6% | 2.1% | 100.2 |
| S5 boss / `constraint_v2` | 74.6% | 23.1% | 2.3% | 99.5 |
| S5 boss / `constraint_v4` | 72.4% | 25.3% | 2.3% | 100.3 |
| S5 boss / `constraint_v3` | 73.6% | 24.0% | 2.4% | 99.8 |
| S6 boss / `constraint_v2` | 69.5% | 28.9% | 1.5% | 101.7 |
| S6 boss / `constraint_v4` | 67.5% | 31.1% | 1.4% | 102.1 |
| S6 boss / `constraint_v3` | 66.4% | 32.3% | 1.3% | 102.4 |

S4 boss market profile 비교:

| experiment / market | clear | deck exhausted | board locked | turn |
|---|---:|---:|---:|---:|
| `constraint_v2` / none | 44.9% | 52.9% | 2.3% | 106.5 |
| `constraint_v2` / full safe | 57.8% | 40.3% | 2.0% | 104.3 |
| `constraint_v4` / none | 58.1% | 39.6% | 2.3% | 103.7 |
| `constraint_v4` / full safe | 71.7% | 26.4% | 2.0% | 100.9 |
| `constraint_v3` / none | 66.8% | 31.0% | 2.3% | 101.7 |
| `constraint_v3` / full safe | 77.7% | 20.3% | 2.0% | 98.8 |

해석:

- v4가 현재 가장 좋은 중간점이다. S4 boss deck exhausted를 46.5%에서 32.9%로 낮추면서, v3처럼 70%대 초반까지 과하게 풀지는 않는다.
- v3는 병목 해소에는 강하지만 S4 boss clear 72.3%, full safe 77.7%, `s5_power_build` 94% 이상으로 쉬운 쪽 위험이 크다.
- v4도 강한 loadout에서는 여전히 쉽다. `s5_power_build` S4 boss clear 91.9%, full safe 94.3%이므로 강한 빌드의 희열/고점으로 둘지, boss 제약으로 더 눌러야 할지 별도 판단이 필요하다.
- foundation 계열은 v4에서도 아직 어렵다. `s2_foundation_build` S4 boss clear 16.6%, deck exhausted 80.1%다. S4 제약만으로는 약한 빌드와 강한 빌드의 격차를 동시에 해결하지 못한다.
- S5/S6 boss는 v4에서 약간 나빠진다. S5 boss clear 74.6% -> 72.4%, S6 boss clear 69.5% -> 67.5%다. 허용 가능한 범위지만 다음 seed에서 재확인해야 한다.

결론:

- 다음 기준 후보는 `station_curve_125_target_v6_s5_070_boss_constraint_pool_v4`다.
- v3는 S4 병목을 강하게 뚫는 상한 후보로 보관한다.
- v7은 S4 target까지 낮춰 과보정 가능성이 커서 보류한다.
- 다음 반복은 S4 boss에서 loadout 격차를 줄이는 방향이다. target/constraint를 더 낮추기보다 foundation 계열이 반복 rank 압박을 버틸 수 있는 선택형 market/build proxy를 먼저 검토한다.
- 아직 실제 구현 전환 단계가 아니다. v4 역시 시뮬 전용 후보로만 유지한다.

### v19: candidate baseline v1 기준점 고정

v18까지는 실험 id가 길고, “현재 기준점”이 문서/명령어마다 흔들릴 수 있었다. 그래서 실제 구현과 무관한 시뮬 전용 alias를 추가했다.

추가한 experiment:

- `candidate_baseline_v1`
  - 내부 기준은 `station_curve_125_target_v6_s5_070_boss_constraint_pool_v4`
  - station curve: 1.25
  - S5 boss target multiplier: 0.70
  - S5 resource bridge 없음
  - S4 repeat rank pressure: v4, `repeat_rank_score_multiplier = 0.80`
  - S6 confirm pressure: v2의 soft tax 유지

검증:

- `flutter test test/tools/sim/balance_sim_test.dart`
- `python3 -m py_compile tools/sim/ml_sweep_dataset.py`
- `dart analyze tools/sim/run_balance_sim.dart`

#### v19a: 전체 강제 로드아웃 매트릭스

주요 파일:

- `logs/sim/ml_sweep_candidate_baseline_v1_full_r400_summary.json`
- `logs/sim/ml_sweep_candidate_baseline_v1_full_r400_report.md`
- `logs/sim/ml_sweep_candidate_baseline_v1_full_r400_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_candidate_baseline_v1_full_r400_summary_ml_insights_report.md`

실험 범위:

- mode: `experiment_matrix`
- runs: 400
- experiment: `candidate_baseline_v1`
- stations: S1~S8
- loadout: `baseline`, `s2_foundation_build`, `s3_hand_growth_build`, `s4_resource_build`, `s5_power_build`, `s5_sustain_build`, `s5_boss_bridge_build`, `rare_jester_engine`, `s6_boss_breaker_build`, `s8_finale_build`
- market profile: `none`, `s1_full_safe_candidate_pool`
- 총 run 수: 132,396
- 실행: `summary-only`

전체/티어 기준:

| scope | clear | deck exhausted | board locked | turn |
|---|---:|---:|---:|---:|
| 전체 | 96.0% | 3.0% | 1.0% | 63.9 |
| small | 99.1% | 0.3% | 0.6% | 53.8 |
| big | 95.4% | 3.6% | 1.0% | 66.3 |
| boss | 92.8% | 6.0% | 1.2% | 72.1 |

주요 station/tier:

| station/tier | clear | deck exhausted | turn |
|---|---:|---:|---:|
| S4 boss | 86.5% | 12.1% | 78.1 |
| S5 boss | 90.5% | 8.2% | 74.9 |
| S7 big | 88.1% | 10.9% | 81.2 |
| S7 boss | 88.1% | 10.7% | 89.8 |
| S8 boss | 90.5% | 8.3% | 95.0 |

Loadout별 전체:

| loadout | clear | deck exhausted | turn |
|---|---:|---:|---:|
| `baseline` | 59.3% | 37.1% | 96.8 |
| `s2_foundation_build` | 92%대 | 6~7%대 | 70~80대 |
| `s3_hand_growth_build` 이상 | 98~99%대 | 0~2%대 | 50~70대 |

Boss loadout 기준:

| loadout | boss clear | boss deck exhausted |
|---|---:|---:|
| `baseline` | 4.4% | 92.1% |
| `s2_foundation_build` | 83.1% | 14.7% |
| `s3_hand_growth_build` | 86.5% | 10.4% |
| `s4_resource_build` | 87.0% | 10.9% |
| `s5_power_build` | 92.4% | 6.2% |
| `rare_jester_engine` 이상 | 97~99% | 매우 낮음 |

해석:

- 이 매트릭스는 “모든 station에 모든 loadout을 강제로 끼워 넣는 스트레스 테스트”다. 실제 런 진행 경로로 읽으면 안 된다.
- 강한/후반 loadout이 S1~S8 전체를 거의 다 통과하므로 전체 clear가 96%까지 올라간다.
- 반대로 `baseline` boss는 clear 4.4%, deck exhausted 92.1%로 거의 막힌다.
- 따라서 현재 기준점의 핵심 문제는 단순히 “boss가 너무 쉽다/어렵다”가 아니라, 빌드 성장 전후 격차가 너무 크다는 점이다.
- ML target label은 이 매트릭스에서 `too_easy`를 과다하게 붙인다. 강제 후반 loadout 매트릭스는 target band 보정 전에는 모델 학습용 정답으로 쓰기 어렵고, 병목/상한 확인용으로 둔다.

#### v19b: 실제 진행 경로 station_path

주요 파일:

- `logs/sim/candidate_baseline_v1_station_path_r400_summary.json`
- `logs/sim/candidate_baseline_v1_station_path_r400_summary_bottleneck_report.md`
- `logs/sim/candidate_baseline_v1_station_path_r400_summary_ml_insights_report.md`

실험 범위:

- sequence mode: `station_path`
- runs: 400
- experiment: `candidate_baseline_v1`
- station path: S1~S8
- loadout: `baseline`
- market profile: `none`, `s1_full_safe_candidate_pool`

전투 step 요약:

| station/tier | clear | deck exhausted | board locked | turn |
|---|---:|---:|---:|---:|
| S1 small | 93.5% | 4.0% | 2.5% | 86.5 |
| S1 big | 50.3% | 46.0% | 3.7% | 102.9 |
| S1 boss | 5.6% | 89.6% | 4.8% | 108.0 |
| S2 small | 61~63% | 25~39% | 0~13% | 93~101 |
| S2 big | 0~80% | 20~63% | 0~38% | 97~101 |
| S2 boss | 25.0% | 50.0% | 25.0% | 107.2 |

런 경로 기준:

| market profile | path clear | avg cleared steps | avg attempted steps | 주요 실패 구간 |
|---|---:|---:|---:|---|
| `none` | 0.0% | 1.48 | 2.48 | S1 big 182회, S1 boss 181회 |
| `s1_full_safe_candidate_pool` | 0.0% | 1.43 | 2.43 | S1 big 190회, S1 boss 174회 |

해석:

- 실제 진행 경로 기준으로는 현재 기준점이 너무 어렵다. S1 big과 S1 boss에서 대부분 끊기며, S2 이후 표본은 매우 적다.
- 전체 매트릭스에서 clear 96%가 나온 이유는 강한 loadout을 초반 station에도 강제로 주입했기 때문이다. 실제 baseline 시작 경로와는 결론이 반대다.
- `s1_full_safe_candidate_pool`은 이 경로에서 path clear를 만들지 못했다. 초반 S1 big/boss target 또는 시작 덱/초기 후보의 역할을 다시 봐야 한다.
- “보스전만 보면 안 된다”는 기준은 유지한다. 지금 병목은 S1 big도 boss만큼 크며, small은 비교적 통과권이다.
- 다음 기준은 두 개로 분리한다.
  - `matrix_baseline`: loadout별 상한/하한과 과성장 여부를 보는 스트레스 기준.
  - `path_baseline`: 실제 progression survival과 초반 병목을 보는 기준.

다음 액션:

- 후보 효과를 더 추가하기 전에 target band를 재정의한다. 강제 loadout 매트릭스와 실제 path run을 같은 target으로 학습시키면 라벨이 왜곡된다.
- `path_baseline`은 S1 big/S1 boss를 먼저 풀어야 한다. 단, S1 small은 이미 93.5% clear이므로 전체 S1 target을 일괄 하향하면 초반 small이 더 쉬워질 수 있다.
- 우선 후보는 S1 big/boss 전용 완충이다.
  - S1 big target multiplier 소폭 하향
  - S1 boss 제약/target 완화
  - 첫 market purchase가 실제로 S1 big 이전에 들어가는지 확인
  - baseline 시작 덱의 deck pressure 완화
- 실제 UI/저장/실제 마켓 구조로 옮길 단계는 아니다. `candidate_baseline_v1`도 시뮬 기준점 alias일 뿐이다.

### v20: base_score_curve v2 재산정

v19에서 확인한 문제는 `candidate_baseline_v1`이 전체 기준점으로 부적합하다는 점이었다. 해당 alias는 target curve, boss constraint, 국소 보정을 섞은 reference였고, 강제 loadout matrix에서는 너무 쉽고 실제 station_path에서는 S1 big/boss에서 막히는 모순이 생겼다.

따라서 v20은 `adapted_rule_candidate`, `adapted_candidate_pool`, `boss_constraint_adaptation_set`을 모두 잠시 분리하고, 순수 `base_score_curve`부터 다시 잡았다.

탐색 batch:

- `logs/sim/ml_sweep_base_score_curve_v2_probe_r150_summary.json`
- `logs/sim/ml_sweep_base_score_curve_v2_probe_r150_report.md`
- `logs/sim/ml_sweep_base_score_curve_v2_probe_r150_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_base_score_curve_v2_probe_r150_summary_ml_insights_report.md`

탐색 범위:

- mode: `progression_curve`
- runs: 150
- station growth: `station_curve_125`, `station_curve_135`
- small multiplier: 1.05, 1.10
- big multiplier: 0.75, 0.85, 0.95
- boss multiplier: 0.45, 0.55, 0.65, 0.75
- loadout: `baseline`, `s1_entry_bridge_build`, `s2_foundation_build`, `s3_hand_growth_build`, `s5_power_build`
- market: `none`
- 후보 수: 48
- 실행: `summary-only`

탐색 해석:

- 전체 loadout을 섞은 ranking은 강한 loadout 때문에 초반 S1을 거의 100%로 만들며 왜곡된다.
- 기준 스코어커브 판단은 `baseline`과 초반 progression loadout을 분리해서 봐야 한다.
- `baseline` 기준으로 가장 균형이 좋았던 후보는 `station_curve_125`, small 1.10, big 0.85, boss 0.65였다.
  - S1 small 92.7%
  - S1 big 74.8%
  - S1 boss 44.2%
  - 전체 baseline clear 69.6%, deck exhausted 26.2%, turn 96.2
- `station_curve_135` 같은 multiplier 후보는 비슷한 초반 값을 만들 수 있지만 후반 path 도달 범위가 더 좁다.

최종 검증 batch:

- `logs/sim/ml_sweep_base_score_curve_v2_final_r400_summary.json`
- `logs/sim/ml_sweep_base_score_curve_v2_final_r400_report.md`
- `logs/sim/ml_sweep_base_score_curve_v2_final_r400_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_base_score_curve_v2_final_r400_summary_ml_insights_report.md`

최종 범위:

- runs: 400
- 후보:
  - `station_curve_125`, small 1.10, big 0.85, boss 0.65
  - `station_curve_135`, small 1.10, big 0.85, boss 0.65
- loadout: `baseline`, `s1_entry_bridge_build`, `s2_foundation_build`, `s3_hand_growth_build`, `s5_power_build`
- market: `none`
- 실행: `summary-only`

Baseline 기준:

| curve | clear | deck exhausted | board locked | turn | max reached |
|---|---:|---:|---:|---:|---:|
| `125 / small1.10 / big0.85 / boss0.65` | 68.3% | 27.8% | 3.9% | 96.8 | S3 |
| `135 / small1.10 / big0.85 / boss0.65` | 68.6% | 27.9% | 3.5% | 97.0 | S3 |

Baseline S1/S2:

| curve / station tier | clear | deck exhausted | turn |
|---|---:|---:|---:|
| `125` / S1 small | 91.2% | 5.2% | 88.9 |
| `125` / S1 big | 77.3% | 20.0% | 96.6 |
| `125` / S1 boss | 39.4% | 54.6% | 103.2 |
| `125` / S2 small | 64.9% | 31.5% | 100.8 |
| `125` / S2 big | 34.7% | 62.5% | 105.0 |
| `125` / S2 boss | 20.0% | 76.0% | 107.6 |
| `135` / S1 small | 91.8% | 6.0% | 89.1 |
| `135` / S1 big | 79.0% | 18.0% | 96.4 |
| `135` / S1 boss | 43.8% | 51.4% | 103.0 |
| `135` / S2 small | 53.5% | 41.7% | 102.9 |
| `135` / S2 big | 27.9% | 69.1% | 107.7 |
| `135` / S2 boss | 10.5% | 78.9% | 106.5 |

전체 loadout stress 기준:

| curve | clear | deck exhausted | board locked | turn | max reached |
|---|---:|---:|---:|---:|---:|
| `125 / small1.10 / big0.85 / boss0.65` | 90.1% | 8.1% | 1.8% | 76.2 | S8 |
| `135 / small1.10 / big0.85 / boss0.65` | 88.4% | 9.7% | 2.0% | 77.3 | S7 |

후반 boss stress:

| curve / station boss | clear | deck exhausted | turn |
|---|---:|---:|---:|
| `125` / S5 boss | 63.9% | 34.1% | 100.7 |
| `125` / S6 boss | 79.7% | 19.3% | 100.7 |
| `135` / S5 boss | 11.4% | 87.0% | 110.5 |
| `135` / S6 boss | 16.7% | 83.3% | 113.3 |

결론:

- `base_score_curve_v2`는 `station_curve_125`, small 1.10, big 0.85, boss 0.65로 둔다.
- 이 값은 후보/보스 제약을 얹기 전 기준 스코어커브이며, `candidate_baseline_v1`과 다른 레이어다.
- baseline은 S1을 통과할 가능성이 생기지만, S2 이후에는 덱 압박이 남아 성장/마켓 후보가 필요하다. 이는 의도에 맞다.
- early progression loadout은 S1~S2를 거의 안정적으로 통과한다. 이 구간은 이후 market/후보 등장률을 조정해 템포를 맞춰야 한다.
- 전체 stress에서 `125`는 S8까지 도달하지만 `135`는 S5 boss가 다시 hard wall이 된다. 따라서 `135`는 기준 스코어커브로 부적합하다.
- 아직 실제 구현 승격 단계가 아니다. 다음은 `base_score_curve_v2` 위에 `boss_constraint_adaptation_set`을 얹어 hard wall 여부를 다시 본다.

추가한 시뮬 전용 alias:

- `base_score_curve_v2`
  - station growth: 1.25
  - small target multiplier: 1.10
  - big target multiplier: 0.85
  - boss target multiplier: 0.65
  - resource delta 없음
  - boss constraint 없음

### v21: base_score_curve v2 + boss constraint adaptation set

v20에서 순수 `base_score_curve_v2`를 잡았으므로, v21에서는 그 위에 `boss_constraint_adaptation_set`만 얹어 hard wall 여부를 확인했다. `adapted_rule_candidate`와 `adapted_candidate_pool`은 아직 얹지 않았다.

추가한 시뮬 전용 alias:

- `base_score_curve_v2_boss_constraint_pool_v2`
  - `base_score_curve_v2` target multiplier 유지
  - resource delta 없음
  - boss constraint pool severity v2
- `base_score_curve_v2_boss_constraint_pool_v4`
  - `base_score_curve_v2` target multiplier 유지
  - resource delta 없음
  - boss constraint pool severity v4
  - S4 repeat rank pressure는 v4, `repeat_rank_score_multiplier = 0.80`

주요 파일:

- `logs/sim/ml_sweep_base_curve_v2_constraints_v21_r400_summary.json`
- `logs/sim/ml_sweep_base_curve_v2_constraints_v21_r400_report.md`
- `logs/sim/ml_sweep_base_curve_v2_constraints_v21_r400_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_base_curve_v2_constraints_v21_r400_summary_ml_insights_report.md`

실험 범위:

- mode: `experiment_matrix`
- runs: 400
- experiment:
  - `base_score_curve_v2`
  - `base_score_curve_v2_boss_constraint_pool_v2`
  - `base_score_curve_v2_boss_constraint_pool_v4`
- stations: S1~S8
- loadout: `baseline`, `s1_entry_bridge_build`, `s2_foundation_build`, `s3_hand_growth_build`, `s5_power_build`
- market: `none`
- 실행: `summary-only`

전체 loadout stress:

| experiment | clear | deck exhausted | board locked | turn |
|---|---:|---:|---:|---:|
| `base_score_curve_v2` | 90.1% | 8.0% | 1.9% | 76.1 |
| `base_score_curve_v2_boss_constraint_pool_v2` | 90.6% | 7.5% | 1.8% | 76.6 |
| `base_score_curve_v2_boss_constraint_pool_v4` | 90.7% | 7.4% | 1.8% | 76.6 |

전체 boss 기준:

| experiment | boss clear | boss deck exhausted | boss turn |
|---|---:|---:|---:|
| `base_score_curve_v2` | 81.3% | 16.0% | 82.6 |
| `base_score_curve_v2_boss_constraint_pool_v2` | 84.7% | 13.1% | 81.6 |
| `base_score_curve_v2_boss_constraint_pool_v4` | 85.5% | 12.2% | 81.0 |

주요 boss 구간:

| experiment / station boss | clear | deck exhausted | turn |
|---|---:|---:|---:|
| `base` / S4 boss | 92.8% | 4.5% | 86.0 |
| `v2` / S4 boss | 85.2% | 12.1% | 92.6 |
| `v4` / S4 boss | 91.5% | 5.9% | 88.0 |
| `base` / S5 boss | 41.3% | 55.6% | 104.2 |
| `v2` / S5 boss | 66.2% | 32.4% | 99.8 |
| `v4` / S5 boss | 67.5% | 31.2% | 99.4 |
| `base` / S6 boss | 70.4% | 27.5% | 101.5 |
| `v2` / S6 boss | 77.0% | 20.5% | 96.0 |
| `v4` / S6 boss | 75.6% | 22.1% | 96.3 |
| `base` / S7 boss | 7.4% | 91.4% | 110.7 |
| `v2` / S7 boss | 28.8% | 69.6% | 110.9 |
| `v4` / S7 boss | 32.0% | 66.4% | 110.4 |

Baseline only:

| experiment | clear | deck exhausted | board locked | turn |
|---|---:|---:|---:|---:|
| `base_score_curve_v2` | 69.3% | 27.2% | 3.5% | 96.2 |
| `base_score_curve_v2_boss_constraint_pool_v2` | 70.3% | 26.9% | 2.8% | 96.6 |
| `base_score_curve_v2_boss_constraint_pool_v4` | 70.3% | 26.9% | 2.8% | 96.6 |

해석:

- `boss_constraint_adaptation_set`을 얹어도 v13처럼 즉시 hard wall로 무너지지는 않는다. v20에서 기준 스코어커브를 다시 잡은 효과가 있다.
- v4가 v2보다 낫다. 특히 S4 boss에서 v2는 clear 85.2%, deck exhausted 12.1%인데 v4는 clear 91.5%, deck exhausted 5.9%로 더 안정적이다.
- S5/S7 boss는 여전히 deck pressure가 크다. v4 기준 S5 boss deck exhausted 31.2%, S7 boss deck exhausted 66.4%다.
- 이는 보스 제약 자체만의 문제가 아니라, 후반 진행에 필요한 `adapted_rule_candidate`와 `adapted_candidate_pool`이 아직 빠져 있기 때문이다.
- baseline only는 여전히 S2 이후 압박이 남는다. 이는 초반 성장/마켓 후보가 필요하다는 신호로 해석한다.

결론:

- 다음 layer 기준은 `base_score_curve_v2_boss_constraint_pool_v4`로 둔다.
- 이 값은 실제 구현 승격 후보가 아니라, 치환 후보 풀을 평가하기 위한 시뮬 기준점이다.
- 다음 실험은 `base_score_curve_v2_boss_constraint_pool_v4` 위에 `adapted_candidate_pool`을 얹는다.
  - `none`
  - `s1_full_safe_candidate_pool`
  - 필요 시 `s1_probabilistic_candidate_pool`
  - 비교용 `s1_build_aware_pack_plus5`
- 판단 기준은 S5/S7 boss deck pressure 완화, turn drag 증가 여부, strong loadout 과성장 여부다.

### v22: boss constraint v4 + adapted candidate pool

v22는 `base_score_curve_v2_boss_constraint_pool_v4` 위에 `adapted_candidate_pool`을 얹었다. 목적은 치환 후보 풀이 S5/S7 boss deck pressure를 풀 수 있는지, 동시에 turn drag와 강한 빌드 과성장을 만들지 않는지 확인하는 것이다.

진행 중 발견한 보강:

- 기존 summary-only group key는 `market_profile`과 `resolved_market_profile`을 직접 보존하지 않았다.
- S1 이전 전투는 loadout suffix가 붙지 않으므로, market profile별 비교가 섞이는 문제가 있었다.
- `BalanceSimSummaryAccumulator`의 `group_by`에 `market_profile`, `resolved_market_profile`을 추가했다.
- 이 변경 후 v22를 같은 조건으로 재실행했다.

주요 파일:

- `logs/sim/ml_sweep_base_v2_constraint_v4_candidate_pool_v22_r400_summary.json`
- `logs/sim/ml_sweep_base_v2_constraint_v4_candidate_pool_v22_r400_report.md`
- `logs/sim/ml_sweep_base_v2_constraint_v4_candidate_pool_v22_r400_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_base_v2_constraint_v4_candidate_pool_v22_r400_summary_ml_insights_report.md`

실험 범위:

- mode: `experiment_matrix`
- runs: 400
- experiment: `base_score_curve_v2_boss_constraint_pool_v4`
- stations: S1~S8
- loadout:
  - `baseline`
  - `s1_entry_bridge_build`
  - `s2_foundation_build`
  - `s3_hand_growth_build`
  - `s5_power_build`
  - `rare_jester_engine`
  - `s5_boss_bridge_build`
  - `s6_boss_breaker_build`
  - `s8_finale_build`
- market:
  - `none`
  - `s1_full_safe_candidate_pool`
  - `s1_probabilistic_candidate_pool`
  - `s1_build_aware_pack_plus5`
- 실행: `summary-only`
- group 수: 4125
- 실행 시간: 18분 14초

Market 전체:

| market profile | clear | deck exhausted | board locked | turn | max hit |
|---|---:|---:|---:|---:|---:|
| `none` | 96.2% | 2.8% | 1.0% | 61.4 | 276.3 |
| `s1_build_aware_pack_plus5` | 96.6% | 2.4% | 1.0% | 62.3 | 277.1 |
| `s1_full_safe_candidate_pool` | 96.5% | 2.7% | 0.9% | 61.1 | 284.0 |
| `s1_probabilistic_candidate_pool` | 96.4% | 2.7% | 0.9% | 61.4 | 280.7 |

Boss 전체:

| market profile | boss clear | boss deck exhausted | boss turn | max hit |
|---|---:|---:|---:|---:|
| `none` | 94.6% | 4.3% | 64.8 | 259.2 |
| `s1_build_aware_pack_plus5` | 95.0% | 3.9% | 65.8 | 260.5 |
| `s1_full_safe_candidate_pool` | 94.7% | 4.3% | 64.5 | 267.0 |
| `s1_probabilistic_candidate_pool` | 94.8% | 4.2% | 64.8 | 263.8 |

Station boss 핵심:

| market / station boss | clear | deck exhausted | turn |
|---|---:|---:|---:|
| `none` / S5 | 89.8% | 9.1% | 72.2 |
| `s1_build_aware_pack_plus5` / S5 | 94.0% | 4.8% | 73.7 |
| `s1_full_safe_candidate_pool` / S5 | 92.1% | 7.3% | 72.0 |
| `s1_probabilistic_candidate_pool` / S5 | 91.3% | 8.0% | 72.9 |
| `none` / S7 | 92.6% | 6.3% | 78.1 |
| `s1_build_aware_pack_plus5` / S7 | 91.9% | 6.8% | 80.7 |
| `s1_full_safe_candidate_pool` / S7 | 90.8% | 8.2% | 78.3 |
| `s1_probabilistic_candidate_pool` / S7 | 91.9% | 6.7% | 78.2 |

Loadout별 S5/S7 boss 병목:

| loadout / market / station boss | clear | deck exhausted | turn |
|---|---:|---:|---:|
| `s2_foundation_build` / `none` / S5 | 33.9% | 64.0% | 109.9 |
| `s2_foundation_build` / `s1_build_aware_pack_plus5` / S5 | 67.6% | 30.4% | 114.7 |
| `s2_foundation_build` / `s1_full_safe_candidate_pool` / S5 | 55.3% | 43.9% | 108.8 |
| `s2_foundation_build` / `s1_probabilistic_candidate_pool` / S5 | 56.8% | 42.0% | 109.8 |
| `s3_hand_growth_build` / `none` / S5 | 66.9% | 30.1% | 104.0 |
| `s3_hand_growth_build` / `s1_build_aware_pack_plus5` / S5 | 89.1% | 7.4% | 105.1 |
| `s3_hand_growth_build` / `s1_full_safe_candidate_pool` / S5 | 80.3% | 18.0% | 101.5 |
| `s3_hand_growth_build` / `s1_probabilistic_candidate_pool` / S5 | 74.3% | 24.3% | 103.2 |
| `s5_power_build` / `none` / S7 | 30.4% | 68.1% | 110.1 |
| `s5_power_build` / `s1_build_aware_pack_plus5` / S7 | 68.2% | 29.3% | 114.7 |
| `s5_power_build` / `s1_full_safe_candidate_pool` / S7 | 52.4% | 46.3% | 107.6 |
| `s5_power_build` / `s1_probabilistic_candidate_pool` / S7 | 52.0% | 46.5% | 110.3 |

해석:

- 전체 평균만 보면 market profile 차이가 작다. 강한 late loadout이 많아 전체 boss clear가 94~95%로 높기 때문이다.
- 병목 loadout/station으로 쪼개면 차이가 선명하다.
- `s1_build_aware_pack_plus5`는 S5/S7 병목을 가장 강하게 푼다.
  - `s2_foundation_build` S5 boss deck exhausted 64.0% -> 30.4%
  - `s3_hand_growth_build` S5 boss deck exhausted 30.1% -> 7.4%
  - `s5_power_build` S7 boss deck exhausted 68.1% -> 29.3%
- 단점도 뚜렷하다. `s1_build_aware_pack_plus5`는 병목 구간 turn을 4~5턴 정도 늘릴 수 있다.
- `s1_full_safe_candidate_pool`과 `s1_probabilistic_candidate_pool`은 병목을 일부 완화하지만, build-aware Pack만큼 강하지 않다.
- 강한 late loadout(`rare_jester_engine`, `s5_boss_bridge_build`, `s6_boss_breaker_build`, `s8_finale_build`)은 이미 98~99% clear로 안정적이다. 이쪽은 후보 풀 추가가 재미 다양성은 줄 수 있지만 밸런스 완화 근거로 보기는 어렵다.
- baseline은 후보 pool로도 boss deck pressure가 크게 남는다. baseline은 “무성장으로 끝까지 가는 빌드”가 아니라 초반 성장을 요구하는 기준으로 보는 게 맞다.

결론:

- `adapted_candidate_pool` 방향은 유지한다. 단, pool 전체가 병목을 뚫는 해답은 아니고 역할군 분리가 필요하다.
- `s1_build_aware_pack_plus5`는 병목 완화 상한 후보로 보관한다. 실제 구현 후보로 바로 승격하기에는 turn drag와 선택형 pack UI/저장/시장 구조가 아직 필요하다.
- `s1_full_safe_candidate_pool`은 다양성 하한선으로 유지한다. 강한 효과와 약한 효과가 섞인 실제 마켓에 가까운 참고값이다.
- 다음은 pool을 `deck_sustain`, `score_growth`, `shape_fix`, `weak_flavor` 역할군으로 나눠 비교한다.
- 실제 구현으로 옮길 단계는 아직 아니다. 다만 `build-aware 선택형 Pack` 계열은 실 구현 후보군에 가까워지고 있으므로, 다음 반복에서 역할군별 pool에서도 반복적으로 상위이면 승격 검토를 시작한다.

### v23: sweep 병렬화 보강

v22 재실행이 18분 14초 걸렸다. 후보/market/loadout 조합이 늘어나면 CPU 시뮬 반복이 병목이 되므로, `tools/sim/ml_sweep_dataset.py`에 후보 단위 병렬 실행을 추가했다.

추가:

- `--jobs N`
  - 기본값은 1이다.
  - `jobs=1`은 기존 순차 실행과 같은 동작이다.
  - `jobs>1`이면 후보 candidate를 병렬 실행한다.
  - 후보별 raw/summary 파일명은 기존처럼 고유하게 유지한다.
  - 최종 병합은 후보 index 순서대로 수행해 summary/report 순서를 안정적으로 유지한다.
- combined summary `group_by`에도 `market_profile`, `resolved_market_profile`을 유지한다.

검증:

- smoke sweep를 `--jobs 1`과 `--jobs 2`로 각각 실행했다.
- 두 결과의 `run_count`, group 수, 핵심 group 내용이 동일했다.
- smoke 산출물은 비교 후 삭제했다.

검증 명령:

- `python3 -m py_compile tools/sim/ml_sweep_dataset.py`
- `dart analyze tools/sim/run_balance_sim.dart`

운영 기준:

- 후보 수가 1이면 `--jobs` 이득이 없다.
- progression curve처럼 후보가 여러 개인 sweep부터 `--jobs 4` 또는 `--jobs 6`을 우선 사용한다.
- 너무 큰 값은 CPU 경합으로 turn time만 늘릴 수 있으므로, 다음 장기 sweep에서는 먼저 `--jobs 4`를 기본으로 쓴다.

### v24: role-based adapted candidate pool

v22에서 `adapted_candidate_pool` 전체 평균은 차이가 작았지만, `s2_foundation_build`, `s3_hand_growth_build`, `s5_power_build`의 S5/S7 boss 병목은 여전히 컸다. v24에서는 안전 필터를 통과한 backlog 후보를 실제 카탈로그가 아니라 시뮬 전용 role pool로 나눴다.

추가한 시뮬 전용 market profile:

- `s1_role_deck_sustain_pool`
  - 덱 압박/자원 보강 계열이다.
  - proxy: build-aware Pack, Tarot tile shape, Voucher resource.
- `s1_role_score_growth_pool`
  - 점수 성장 계열이다.
  - proxy: common/uncommon/rare Jester, Planet, Legendary bridge.
- `s1_role_shape_fix_pool`
  - 족보/색/숫자 모양 보정 계열이다.
  - proxy: build-aware Pack, Tarot, common color/rank, uncommon build Jester.
- `s1_role_weak_flavor_pool`
  - 약한 후보와 풍미 후보의 다양성 하한선이다.
  - proxy: common color/rank, Tarot, Voucher.

산출물:

- `logs/sim/ml_sweep_role_candidate_pools_v24_r400_summary.json`
- `logs/sim/ml_sweep_role_candidate_pools_v24_r400_report.md`
- `logs/sim/ml_sweep_role_candidate_pools_v24_r400_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_role_candidate_pools_v24_r400_summary_ml_insights_report.md`

실험 조건:

- runs: 400
- summary-only
- experiment: `base_score_curve_v2_boss_constraint_pool_v4`
- stations: 1~8
- difficulty: `standard`
- loadout:
  - `s2_foundation_build`
  - `s3_hand_growth_build`
  - `s5_power_build`
  - `s5_boss_bridge_build`
- market profile:
  - `none`
  - `s1_build_aware_pack_plus5`
  - `s1_full_safe_candidate_pool`
  - `s1_probabilistic_candidate_pool`
  - `s1_role_deck_sustain_pool`
  - `s1_role_score_growth_pool`
  - `s1_role_shape_fix_pool`
  - `s1_role_weak_flavor_pool`

실행 시간:

- 18분 26초
- `--jobs 4`를 사용했지만 이번 sweep는 experiment candidate가 1개라 병렬 이득이 없었다.
- 다음 병렬화는 candidate 단위가 아니라 market/loadout 단위 분할이 필요하다.

전체 boss, 도달 전투 기준:

| market profile | boss clear | boss deck exhausted | boss board locked | boss turn |
|---|---:|---:|---:|---:|
| `none` | 93.2% | 5.5% | 1.3% | 69.5 |
| `s1_build_aware_pack_plus5` | 94.3% | 4.3% | 1.4% | 71.9 |
| `s1_full_safe_candidate_pool` | 94.3% | 4.6% | 1.1% | 69.4 |
| `s1_probabilistic_candidate_pool` | 94.0% | 4.6% | 1.4% | 69.8 |
| `s1_role_deck_sustain_pool` | 93.9% | 4.9% | 1.2% | 69.8 |
| `s1_role_score_growth_pool` | 94.1% | 4.7% | 1.2% | 68.8 |
| `s1_role_shape_fix_pool` | 94.0% | 4.6% | 1.4% | 69.6 |
| `s1_role_weak_flavor_pool` | 93.8% | 4.8% | 1.4% | 69.3 |

S5 boss, 병목 loadout 기준:

| loadout / market profile | clear | deck exhausted | board locked | turn |
|---|---:|---:|---:|---:|
| `s2_foundation_build` / `none` | 25.5% | 73.4% | 1.1% | 111.1 |
| `s2_foundation_build` / `s1_build_aware_pack_plus5` | 70.8% | 27.7% | 1.6% | 114.7 |
| `s2_foundation_build` / `s1_role_score_growth_pool` | 62.3% | 36.2% | 1.5% | 105.5 |
| `s2_foundation_build` / `s1_role_shape_fix_pool` | 63.0% | 35.5% | 1.5% | 108.9 |
| `s2_foundation_build` / `s1_role_weak_flavor_pool` | 44.0% | 55.0% | 1.0% | 110.7 |
| `s3_hand_growth_build` / `none` | 60.9% | 34.2% | 4.9% | 104.6 |
| `s3_hand_growth_build` / `s1_build_aware_pack_plus5` | 90.1% | 6.7% | 3.2% | 104.4 |
| `s3_hand_growth_build` / `s1_role_score_growth_pool` | 80.1% | 18.6% | 1.3% | 99.8 |
| `s3_hand_growth_build` / `s1_role_shape_fix_pool` | 81.4% | 15.3% | 3.3% | 99.3 |
| `s3_hand_growth_build` / `s1_role_weak_flavor_pool` | 65.8% | 31.3% | 2.8% | 104.6 |
| `s5_power_build` / `none` | 93.3% | 5.8% | 0.9% | 89.6 |
| `s5_power_build` / `s1_role_score_growth_pool` | 95.4% | 4.0% | 0.6% | 82.8 |
| `s5_power_build` / `s1_role_shape_fix_pool` | 96.4% | 1.7% | 1.9% | 84.3 |

S7 boss 주의:

- `s2_foundation_build`와 `s3_hand_growth_build`는 S7까지 도달한 표본 수가 매우 적다.
- 따라서 S7 boss 수치는 “S7에 도달한 전투의 난이도”이지 “전체 경로 생존율”이 아니다.
- 현재 summary-only 집계만으로는 path survival을 직접 비교하기 어렵다.

해석:

- S5 boss 병목에서는 `s1_build_aware_pack_plus5`가 여전히 가장 강한 완화 상한선이다.
- 다만 `s1_build_aware_pack_plus5`는 `s2_foundation_build`에서 turn이 111.1 -> 114.7로 늘어난다. 덱 고갈을 크게 줄이지만 템포 비용이 있다.
- `s1_role_score_growth_pool`과 `s1_role_shape_fix_pool`은 build-aware Pack보다 약하지만, S5 boss에서 turn을 덜 늘리거나 오히려 줄이면서 clear를 올린다.
- `s1_role_weak_flavor_pool`은 의도대로 약하다. 병목 완화용이 아니라 실제 마켓 다양성 하한선으로 취급한다.
- `s5_boss_bridge_build`는 S5/S7 boss 모두 이미 99% 내외로 안정적이다. 이 계열은 밸런스 완화보다 과성장/too easy 감시 대상이다.

결론:

- `adapted_candidate_pool` 방향은 유지한다.
- 이제 후보를 “강한 단일 Pack”으로만 보지 말고 `score_growth`, `shape_fix`, `deck_sustain`, `weak_flavor` 역할군으로 설계해야 한다.
- 실제 구현 후보 승격은 아직 아니다.
- 승격에 가까운 후보군:
  - `shape_fix` 계열: S5 boss에서 clear/deck/turn 균형이 좋다.
  - `score_growth` 계열: S5 boss에서 turn을 줄이는 경향이 있다.
  - `build-aware Pack`: 병목 완화 상한선이지만 turn drag와 UI/선택 구조가 필요하다.
- 다음 보강은 summary에 `sequence_summary`/path survival 집계를 추가하는 것이다. 도달 전투 기준만으로는 S7 이후 해석이 흔들린다.

### v25: path survival summary 보강

v24에서 확인한 한계는 “전투에 도달한 경우”와 “전체 경로를 통과한 경우”가 섞여 해석될 수 있다는 점이다. 특히 S7/S8은 약한 loadout이 그 지점까지 도달하지 못하면, boss 수치만으로 전체 진행 가능성을 판단하기 어렵다.

보강:

- `run_balance_sim.dart` summary에 `sequence_groups`를 추가했다.
- `sequence_groups`는 battle group과 별개로 path 단위 생존율을 집계한다.
- 집계 필드:
  - `path_clear_count`
  - `path_clear_rate`
  - `avg_attempted_step_count`
  - `avg_cleared_step_count`
  - `avg_total_turn_count`
  - `avg_total_score_ratio`
  - `failure_counts`
  - `failure_stop_reason_counts`
- `ml_sweep_dataset.py` 병합 summary도 `sequence_groups`와 `sequence_run_count`를 보존한다.

검증:

- `flutter test test/tools/sim/balance_sim_test.dart`
- `python3 -m py_compile tools/sim/ml_sweep_dataset.py`
- smoke sweep에서 `sequence_groups`가 병합 summary에 남는 것을 확인하고 smoke 파일은 삭제했다.

다음 실험부터는 station/tier별 battle 병목과 path survival 병목을 함께 본다.

### v26: progression route 기반 전체 경로 검증

v25 결과에서 `s2_foundation_build`, `s3_hand_growth_build`를 S8까지 고정하는 방식은 전체 레벨 검증으로 부적절하다는 점이 확인됐다. 초반 빌드를 후반까지 끌고 가면 “성장하는 런”이 아니라 “초반 장비로 끝까지 버티기”가 된다.

보강:

- 시뮬 전용 진행형 loadout route를 추가했다.
- 실제 save/UI/market 구조는 건드리지 않았다.
- route는 station별로 기존 시뮬 loadout preset을 바꿔 끼우는 proxy다.

추가 route:

- `progression_route_slow`
  - S1 `s1_entry_bridge_build`
  - S2 `s2_foundation_build`
  - S3 `s3_hand_growth_build`
  - S4 `s4_resource_build`
  - S5~S6 `s5_power_build`
  - S7 `s5_boss_bridge_build`
  - S8 `s6_boss_breaker_build`
- `progression_route_balanced`
  - S1 `s1_entry_bridge_build`
  - S2 `s2_foundation_build`
  - S3 `s3_hand_growth_build`
  - S4 `s4_resource_build`
  - S5 `s5_power_build`
  - S6 `s5_boss_bridge_build`
  - S7 `s6_boss_breaker_build`
  - S8 `s8_finale_build`
- `progression_route_power`
  - S1 `s1_entry_bridge_build`
  - S2 `s3_hand_growth_build`
  - S3 `s4_resource_build`
  - S4 `s5_power_build`
  - S5 `s5_boss_bridge_build`
  - S6 `s6_boss_breaker_build`
  - S7~S8 `s8_finale_build`

산출물:

- `logs/sim/ml_sweep_progression_routes_v26_r400_summary.json`
- `logs/sim/ml_sweep_progression_routes_v26_r400_report.md`
- `logs/sim/ml_sweep_progression_routes_v26_r400_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_progression_routes_v26_r400_summary_ml_insights_report.md`

실험 조건:

- runs: 400
- summary-only
- experiment: `base_score_curve_v2_boss_constraint_pool_v4`
- stations: 1~8
- loadout route:
  - `progression_route_slow`
  - `progression_route_balanced`
  - `progression_route_power`
- market profile:
  - `none`
  - `s1_build_aware_pack_plus5`
  - `s1_full_safe_candidate_pool`
  - `s1_probabilistic_candidate_pool`
  - `s1_role_deck_sustain_pool`
  - `s1_role_score_growth_pool`
  - `s1_role_shape_fix_pool`
  - `s1_role_weak_flavor_pool`
- 실행 시간: 14분 13초

Route 전체:

| route | path clear | avg attempted steps | avg cleared steps | total turn | top failures |
|---|---:|---:|---:|---:|---|
| `progression_route_slow` | 48.1% | 16.05 | 15.53 | 1210.1 | S1 boss, S1 big, S6 boss |
| `progression_route_balanced` | 55.3% | 16.65 | 16.21 | 1202.4 | S1 boss, S1 big, S5 boss |
| `progression_route_power` | 60.9% | 17.26 | 16.87 | 1156.6 | S1 boss, S1 big, S1 small |

Market 전체:

| market profile | path clear | avg attempted steps | avg cleared steps | total turn | top failures |
|---|---:|---:|---:|---:|---|
| `none` | 48.3% | 16.14 | 15.62 | 1178.9 | S1 boss, S1 big, S5 boss |
| `s1_build_aware_pack_plus5` | 62.3% | 17.38 | 17.00 | 1240.3 | S1 boss, S1 big, S1 small |
| `s1_full_safe_candidate_pool` | 56.2% | 17.02 | 16.59 | 1210.1 | S1 boss, S1 big, S1 small |
| `s1_probabilistic_candidate_pool` | 51.1% | 16.01 | 15.52 | 1144.5 | S1 boss, S1 big, S1 small |
| `s1_role_deck_sustain_pool` | 55.2% | 16.74 | 16.29 | 1197.7 | S1 boss, S1 big, S1 small |
| `s1_role_score_growth_pool` | 58.6% | 17.15 | 16.74 | 1201.9 | S1 boss, S1 big, S1 small |
| `s1_role_shape_fix_pool` | 55.8% | 16.66 | 16.22 | 1176.7 | S1 boss, S1 big, S1 small |
| `s1_role_weak_flavor_pool` | 50.7% | 16.15 | 15.65 | 1167.7 | S1 boss, S1 big, S1 small |

상위 조합:

| route / market | path clear | avg attempted steps | avg cleared steps | total turn | top failures |
|---|---:|---:|---:|---:|---|
| `progression_route_power` / `s1_build_aware_pack_plus5` | 65.0% | 17.61 | 17.26 | 1171.3 | S1 boss, S1 small, S1 big |
| `progression_route_power` / `s1_role_score_growth_pool` | 64.5% | 18.02 | 17.66 | 1192.6 | S1 boss, S1 big, S2 big |
| `progression_route_power` / `s1_role_deck_sustain_pool` | 62.7% | 17.73 | 17.36 | 1180.0 | S1 boss, S1 big, S1 small |
| `progression_route_balanced` / `s1_build_aware_pack_plus5` | 62.0% | 17.07 | 16.70 | 1234.8 | S1 boss, S1 big, S1 small |
| `progression_route_power` / `s1_role_shape_fix_pool` | 60.2% | 16.95 | 16.55 | 1132.2 | S1 boss, S1 big, S1 small |

해석:

- 성장 route를 넣으니 path clear가 0~9% 구간에서 48~65% 구간으로 올라왔다.
- `progression_route_power`가 현재 가장 안정적이다.
- `s1_build_aware_pack_plus5`는 path clear를 가장 크게 올리지만, 전체 turn이 늘 수 있다.
- `s1_role_score_growth_pool`은 `build-aware Pack`과 거의 동급의 path clear를 보이며, turn 부담은 조금 낮다.
- `s1_role_shape_fix_pool`은 최고 clear는 아니지만 total turn이 낮아 “늘어지는 게임 방지” 관점에서 계속 볼 가치가 있다.
- `weak_flavor`는 여전히 하한선 역할이다.

중요 병목:

- 실패 Top이 대부분 S1 boss/S1 big/S1 small에 몰려 있다.
- S1 market은 S1 이후 적용되므로, 현재 S1 실패는 market 후보로 해결되지 않는다.
- 다음 안정화 축은 후보 풀이 아니라 S1 온보딩 curve 또는 시작 route다.

결론:

- 전체 레벨 검증 기준은 static loadout이 아니라 `progression_route_*`로 전환한다.
- 다음은 `progression_route_power`와 `progression_route_balanced`를 중심으로 S1 small/big/boss 온보딩 보정을 sweep한다.
- 실 구현 승격은 아직 아니다. 단, `score_growth`, `shape_fix`, `build-aware Pack`은 후보군으로 계속 유지한다.

## v27 S1 온보딩 보정 sweep

v27은 v26에서 확인된 S1 실패 집중을 직접 검증했다. 목표는 초반 진입을 부드럽게 만들되, 초반 빌드만으로 후반까지 밀어붙이는 구조를 만들지 않는 것이다.

실험 파일:

- `logs/sim/ml_sweep_s1_onboarding_progression_v27_r400_summary.json`
- `logs/sim/ml_sweep_s1_onboarding_progression_v27_r400_report.md`
- `logs/sim/ml_sweep_s1_onboarding_progression_v27_r400_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_s1_onboarding_progression_v27_r400_summary_ml_insights_report.md`

조건:

- runs: 400
- experiment:
  - `base_score_curve_v2_boss_constraint_pool_v4`
  - `base_score_curve_v2_boss_constraint_pool_v4_s1_soft`
  - `base_score_curve_v2_boss_constraint_pool_v4_s1_resource`
  - `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_resource`
- stations: 1~8
- loadout:
  - `progression_route_balanced`
  - `progression_route_power`
- market:
  - `none`
  - `s1_build_aware_pack_plus5`
  - `s1_role_score_growth_pool`
  - `s1_role_shape_fix_pool`
- summary-only

Experiment 전체:

| experiment | path clear | avg attempted steps | avg cleared steps | total turn | top failures |
|---|---:|---:|---:|---:|---|
| `base_score_curve_v2_boss_constraint_pool_v4` | 57.8% | 17.08 | 16.66 | 1188.6 | S1 boss, S1 big, S1 small, S5 boss |
| `base_score_curve_v2_boss_constraint_pool_v4_s1_resource` | 59.3% | 17.44 | 17.04 | 1210.1 | S1 boss, S1 big, S1 small, S4 boss |
| `base_score_curve_v2_boss_constraint_pool_v4_s1_soft` | 65.0% | 18.77 | 18.42 | 1285.7 | S1 boss, S1 big, S1 small, S8 boss |
| `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_resource` | 65.6% | 19.04 | 18.70 | 1303.1 | S1 boss, S1 big, S5 boss, S8 boss |

S1 tier별 변화:

| experiment | S1 small clear | S1 big clear | S1 boss clear | S1 boss deck exhausted |
|---|---:|---:|---:|---:|
| `base_score_curve_v2_boss_constraint_pool_v4` | 97.1% | 94.6% | 83.2% | 13.1% |
| `base_score_curve_v2_boss_constraint_pool_v4_s1_resource` | 97.7% | 95.7% | 83.9% | 12.6% |
| `base_score_curve_v2_boss_constraint_pool_v4_s1_soft` | 97.4% | 96.1% | 91.5% | 5.3% |
| `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_resource` | 98.5% | 96.3% | 91.5% | 5.2% |

Market 전체:

| market profile | path clear | avg attempted steps | avg cleared steps | total turn | top failures |
|---|---:|---:|---:|---:|---|
| `none` | 56.0% | 17.50 | 17.06 | 1236.5 | S1 boss, S1 big, S4 boss |
| `s1_build_aware_pack_plus5` | 66.1% | 18.45 | 18.11 | 1268.6 | S1 boss, S1 big, S1 small |
| `s1_role_score_growth_pool` | 61.6% | 17.96 | 17.58 | 1222.8 | S1 boss, S1 big, S1 small |
| `s1_role_shape_fix_pool` | 64.0% | 18.44 | 18.08 | 1259.5 | S1 boss, S1 big, S1 small |

상위 주요 조합:

| experiment / route / market | path clear | avg attempted steps | avg cleared steps | total turn | top failures |
|---|---:|---:|---:|---:|---|
| `s1_soft_resource` / `progression_route_power` / `s1_build_aware_pack_plus5` | 74.5% | 20.11 | 19.85 | 1313.6 | S1 boss, S1 big, S1 small |
| `s1_soft` / `progression_route_power` / `s1_build_aware_pack_plus5` | 72.8% | 19.51 | 19.24 | 1281.6 | S1 boss, S1 big, S1 small |
| `s1_soft` / `progression_route_power` / `s1_role_shape_fix_pool` | 70.5% | 19.93 | 19.63 | 1307.8 | S1 boss, S1 big, S8 boss |
| `s1_soft_resource` / `progression_route_power` / `s1_role_score_growth_pool` | 69.8% | 19.49 | 19.19 | 1272.5 | S1 boss, S1 big, S8 boss |

해석:

- S1의 실제 병목은 small/big보다 boss다.
- `s1_resource` 단독은 path clear 개선이 작다. 시작 자원 +1은 S1 boss 실패를 충분히 낮추지 못한다.
- `s1_soft`는 S1 boss clear를 83.2%에서 91.5%로 올리고, deck exhausted를 13.1%에서 5.3%로 낮춘다.
- `s1_soft_resource`는 `s1_soft`보다 path clear가 0.6%p만 높고 total turn이 더 늘어난다.
- 현재 기준 후보는 `base_score_curve_v2_boss_constraint_pool_v4_s1_soft`다.
- `s1_soft_resource`는 안정성 상한선으로 보되, 실제 기준으로 쓰기에는 초반 자원 완화가 과하다.

## v28 Static vs Progression guard sweep

v28은 “초반 빌드가 후반까지 그대로 가면 안 된다”는 조건을 검증했다. S1 soft가 초반 진입을 완화하더라도, static loadout은 전체 path clear가 0%로 남아야 한다.

실험 파일:

- `logs/sim/ml_sweep_static_vs_progression_guard_v28_r400_summary.json`
- `logs/sim/ml_sweep_static_vs_progression_guard_v28_r400_report.md`
- `logs/sim/ml_sweep_static_vs_progression_guard_v28_r400_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_static_vs_progression_guard_v28_r400_summary_ml_insights_report.md`

조건:

- runs: 400
- experiment:
  - `base_score_curve_v2_boss_constraint_pool_v4`
  - `base_score_curve_v2_boss_constraint_pool_v4_s1_soft`
- stations: 1~8
- loadout:
  - `s1_entry_bridge_build`
  - `s2_foundation_build`
  - `s3_hand_growth_build`
  - `progression_route_balanced`
  - `progression_route_power`
- market:
  - `none`
  - `s1_build_aware_pack_plus5`
  - `s1_role_score_growth_pool`
  - `s1_role_shape_fix_pool`
- summary-only

Loadout별 결과:

| experiment / loadout | path clear | avg attempted steps | avg cleared steps | total turn | top failures |
|---|---:|---:|---:|---:|---|
| `v4` / `progression_route_balanced` | 56.2% | 16.90 | 16.46 | 1219.0 | S1 boss, S1 big, S4 boss |
| `v4` / `progression_route_power` | 61.4% | 17.53 | 17.14 | 1174.1 | S1 boss, S1 big, S1 small |
| `v4` / `s1_entry_bridge_build` | 0.0% | 6.93 | 5.93 | 623.7 | S1 boss, S2 boss, S3 boss |
| `v4` / `s2_foundation_build` | 0.0% | 14.50 | 13.50 | 1144.0 | S5 boss, S6 big, S6 boss |
| `v4` / `s3_hand_growth_build` | 0.0% | 15.46 | 14.46 | 1153.2 | S5 boss, S6 boss, S6 big |
| `s1_soft` / `progression_route_balanced` | 63.1% | 18.66 | 18.29 | 1327.1 | S1 boss, S1 big, S5 boss |
| `s1_soft` / `progression_route_power` | 68.5% | 19.38 | 19.06 | 1277.2 | S1 boss, S1 big, S8 big |
| `s1_soft` / `s1_entry_bridge_build` | 0.0% | 7.52 | 6.52 | 663.8 | S3 boss, S3 big, S2 boss |
| `s1_soft` / `s2_foundation_build` | 0.0% | 14.44 | 13.44 | 1127.7 | S5 boss, S6 big, S6 boss |
| `s1_soft` / `s3_hand_growth_build` | 0.0% | 15.55 | 14.55 | 1151.0 | S5 boss, S6 big, S7 big |

해석:

- `s1_soft`는 progression route의 path clear를 올리지만, static 초반 빌드의 path clear는 여전히 0.0%다.
- `s1_entry_bridge_build`는 S1 완화 후에도 S3 전후에서 멈춘다.
- `s2_foundation_build`와 `s3_hand_growth_build`는 S5~S7 병목에서 멈춘다.
- 따라서 `s1_soft`는 “초반 빌드로 후반까지 캐리”를 만들지 않고, 성장 route가 필요하다는 구조를 유지한다.
- 현재 안정 기준은 `base_score_curve_v2_boss_constraint_pool_v4_s1_soft` + `progression_route_*` path survival이다.
- 다음 단계는 S2~S5 성장 보상 간격을 조정해 `s1_soft`의 늘어난 생존자가 중반에서 어떤 역할 후보를 필요로 하는지 본다.

## 아직 실 구현으로 옮기지 않는 이유

- 현재 Pack은 “덱을 늘리면 고갈이 줄어든다”는 방향성만 확인했다.
- 어떤 Pack이 상점에서 어떤 확률로 뜨고, 구매 후 즉시 적용인지 개봉 선택인지, 도감/해금과 연결할지 아직 확정 전이다.
- Voucher는 Balatro처럼 구매 후 장기 효과를 줄지, 우리 게임에서는 Item/Gear/도감 해금으로 치환할지 설계가 더 필요하다.
- UI가 아니라 시뮬에서 먼저 모델을 안정화해야 실제 구현 후 되돌림 비용이 작다.

## 실 데이터 영향 관리

- 후보를 넓게 넣더라도 기존 실제 run/save/market 데이터에 바로 섞지 않는다.
- 실제 마켓 등장 구조와 UI는 나중에 결정한다. 현재는 “랜덤하게 등장했다고 가정한 시뮬 결과”를 먼저 본다.
- 시뮬 후보는 `market_profile`, `resolved_market_profile`, `simulated` 같은 필드로 추적해 실제 데이터와 구분한다.
- 실제 구현으로 승격할 때는 신규 run version 또는 feature flag를 우선 검토한다.
- 기존 유저 run에는 새 Pack/Voucher/Jester 효과를 소급 적용하지 않는 방향을 기본값으로 둔다.

## 실 구현 전환 기준

아래 조건 중 하나 이상을 만족하면 실제 게임 시스템 구현 단계로 전환한다.

- Pack/Voucher/Jester 후보가 여러 seed와 curve에서 반복적으로 덱 고갈률을 낮춘다.
- clear rate가 목표 구간에 들어오면서 너무 쉬워지는 부작용이 작다.
- 특정 기재가 단독 사기가 아니라 빌드 선택지를 넓히는 방향으로 작동한다.
- `none`, 기존 item, 기존 Jester 대비 우위가 명확하거나 역할 차이가 뚜렷하다.
- 데이터 모델, market rarity/appearance, 저장 구조를 확정할 만큼 기획이 안정된다.

전환 시 먼저 알려야 할 내용:

- “이제 실 구현으로 옮길 시점이다.”
- 구현 대상 최소 세트.
- UI 없이 먼저 들어갈 core model/runtime 범위.
- 이후 필요한 shop UI, pack opening UI, codex/도감 연결 범위.

## 다음 권장 실험 순서

1. Pack 크기 sweep
   - 완료: v10에서 `+2`, `+3`, `+4`, `+5`, build-aware `+3/+5`를 비교했다.
   - 현재 유력 후보는 `s1_build_aware_pack_plus5`다.

2. 선택형 Pack sweep
   - “N장 중 1~2장 선택”을 시뮬레이션한다.
   - bot이 사람처럼 빌드를 고르는 능력이 아직 제한적이므로, 우선 휴리스틱 선택으로 구현한다.

3. Voucher/장기 효과 sweep
   - 매 station 덱 +1.
   - Pack 등장률 증가.
   - Pack 선택지 수 증가.
   - Rare/Jester 등장률 소폭 증가.

4. 덱 성장 Jester sweep
   - confirm 성공 시 낮은 확률로 유사 색상/숫자 타일 추가.
   - boss 전투 시작 시 조건부 타일 추가.
   - 덱이 적을수록 보정되는 안전장치형 Jester.

5. 조합 sweep
   - `rare_jester_engine`
   - `s5_boss_bridge_build`
   - `discard_glove`
   - Pack/Voucher 후보를 조합해 S5/S6 boss 병목을 재검증한다.

## 데이터 정리 원칙

- 유의미한 summary/report/chart만 남긴다.
- 같은 실험의 후보별 중간 JSONL은 `--summary-only`를 우선 사용해 남기지 않는다.
- 후보별 raw가 꼭 필요하면 `--keep-candidate-files`를 명시한 실험만 보존한다.
- 다음 작업에서 참조할 핵심 리포트는 이 문서에 링크를 추가한다.

## 현재 우선순위

1. 시뮬 전용 Pack/Voucher/Jester 후보를 더 넓게 생성한다.
2. S5/S6 boss deck exhausted를 우선 낮춘다.
3. clear rate가 높아진 후보는 tempo, score spike, resource too loose를 함께 본다.
4. 반복 seed에서 안정적인 후보만 실제 구현 대상으로 승격한다.
