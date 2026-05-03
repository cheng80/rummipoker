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

## v29 중반 성장 보상 간격 sweep

v29는 S1 soft 이후 성장 보상이 언제 들어와야 하는지 확인했다. 실제 보상/상점 구현은 건드리지 않고, 시뮬 전용 progression route만 추가했다.

추가한 route:

- `progression_route_delayed`
  - S2~S3를 `s2_foundation_build`로 더 오래 유지한다.
  - S4에서 `s3_hand_growth_build`, S5에서 `s4_resource_build`, S6에서 `s5_power_build`로 늦게 성장한다.
- `progression_route_sustain`
  - `progression_route_balanced`와 거의 같지만 S5를 `s5_power_build` 대신 `s5_sustain_build`로 본다.
  - 목적은 S5 전후에서 점수 폭발보다 자원/덱 압박 완화가 더 나은지 확인하는 것이다.

실험 파일:

- `logs/sim/ml_sweep_mid_growth_spacing_v29_r400_summary.json`
- `logs/sim/ml_sweep_mid_growth_spacing_v29_r400_report.md`
- `logs/sim/ml_sweep_mid_growth_spacing_v29_r400_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_mid_growth_spacing_v29_r400_summary_ml_insights_report.md`

조건:

- runs: 400
- experiment: `base_score_curve_v2_boss_constraint_pool_v4_s1_soft`
- stations: 1~8
- loadout:
  - `progression_route_delayed`
  - `progression_route_balanced`
  - `progression_route_sustain`
  - `progression_route_power`
- market:
  - `none`
  - `s1_build_aware_pack_plus5`
  - `s1_role_score_growth_pool`
  - `s1_role_shape_fix_pool`
- summary-only

Route 전체:

| route | path clear | avg attempted steps | avg cleared steps | total turn | top failures |
|---|---:|---:|---:|---:|---|
| `progression_route_delayed` | 43.9% | 16.69 | 16.13 | 1281.8 | S5 boss, S1 boss, S5 big |
| `progression_route_balanced` | 62.9% | 18.47 | 18.10 | 1313.3 | S1 boss, S1 big, S4 boss, S5 boss |
| `progression_route_sustain` | 63.8% | 18.61 | 18.25 | 1322.5 | S1 boss, S1 big, S4 boss, S3 boss |
| `progression_route_power` | 69.2% | 19.41 | 19.10 | 1281.8 | S1 boss, S1 big, S1 small, S2 boss |

Market 전체:

| market profile | path clear | avg attempted steps | avg cleared steps | total turn | top failures |
|---|---:|---:|---:|---:|---|
| `none` | 50.8% | 17.25 | 16.76 | 1254.5 | S1 boss, S5 boss, S4 boss |
| `s1_build_aware_pack_plus5` | 66.6% | 18.96 | 18.63 | 1348.9 | S1 boss, S1 big, S5 boss |
| `s1_role_score_growth_pool` | 61.1% | 18.43 | 18.04 | 1292.4 | S1 boss, S5 boss, S1 big |
| `s1_role_shape_fix_pool` | 61.3% | 18.54 | 18.16 | 1303.7 | S1 boss, S5 boss, S1 big |

상위 조합:

| route / market | path clear | total turn | top failures |
|---|---:|---:|---|
| `progression_route_power` / `s1_build_aware_pack_plus5` | 75.8% | 1329.9 | S1 boss, S1 big, S1 small |
| `progression_route_sustain` / `s1_build_aware_pack_plus5` | 68.8% | 1354.7 | S1 boss, S1 big, S3 boss |
| `progression_route_power` / `s1_role_shape_fix_pool` | 68.8% | 1289.1 | S1 boss, S8 boss, S8 big |
| `progression_route_power` / `s1_role_score_growth_pool` | 68.5% | 1255.1 | S1 boss, S1 big, S3 big |
| `progression_route_balanced` / `s1_role_score_growth_pool` | 66.5% | 1341.9 | S1 boss, S1 big, S1 small |

해석:

- 성장 보상을 늦추면 안 된다. `progression_route_delayed`는 S5 boss/big에서 무너진다.
- S5에서 `s5_sustain_build`를 쓰는 route는 `balanced`보다 아주 조금 낫지만, total turn이 더 길다.
- `progression_route_power`는 path clear와 total turn의 균형이 가장 좋다.
- 중반 설계 방향은 “S2~S4에서 빠르게 hand/resource/power 축을 열고, S5부터 boss bridge로 넘어가는 구조”가 현재 가장 안정적이다.

## v30 S1 soft 기준 market role 재비교

v30은 `s1_soft`와 progression route 기준이 잡힌 뒤, 넓은 market profile을 다시 비교했다. 목적은 실제 구현 후보로 남길 역할군과 시뮬 상한/하한을 분리하는 것이다.

실험 파일:

- `logs/sim/ml_sweep_s1_soft_market_roles_v30_r400_summary.json`
- `logs/sim/ml_sweep_s1_soft_market_roles_v30_r400_report.md`
- `logs/sim/ml_sweep_s1_soft_market_roles_v30_r400_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_s1_soft_market_roles_v30_r400_summary_ml_insights_report.md`

조건:

- runs: 400
- experiment: `base_score_curve_v2_boss_constraint_pool_v4_s1_soft`
- stations: 1~8
- loadout:
  - `progression_route_balanced`
  - `progression_route_power`
- market:
  - `none`
  - `s1_build_aware_pack_plus5`
  - `s1_probabilistic_candidate_pool`
  - `s1_full_safe_candidate_pool`
  - `s1_role_deck_sustain_pool`
  - `s1_role_score_growth_pool`
  - `s1_role_shape_fix_pool`
  - `s1_role_weak_flavor_pool`
- summary-only

Route 전체:

| route | path clear | avg attempted steps | avg cleared steps | total turn | top failures |
|---|---:|---:|---:|---:|---|
| `progression_route_balanced` | 58.6% | 17.95 | 17.53 | 1279.8 | S1 boss, S1 big, S4 boss, S5 boss |
| `progression_route_power` | 67.3% | 18.97 | 18.64 | 1250.8 | S1 boss, S1 big, S1 small, S8 boss |

Market 전체:

| market profile | path clear | avg attempted steps | avg cleared steps | total turn | top failures |
|---|---:|---:|---:|---:|---|
| `none` | 55.2% | 17.54 | 17.10 | 1230.2 | S1 boss, S1 big, S5 boss |
| `s1_build_aware_pack_plus5` | 69.8% | 19.04 | 18.73 | 1302.1 | S1 boss, S1 big, S4 boss |
| `s1_full_safe_candidate_pool` | 62.0% | 18.38 | 18.00 | 1250.6 | S1 boss, S1 big, S1 small |
| `s1_probabilistic_candidate_pool` | 61.5% | 18.04 | 17.65 | 1239.2 | S1 boss, S1 big, S4 boss |
| `s1_role_deck_sustain_pool` | 64.4% | 18.42 | 18.07 | 1265.0 | S1 boss, S1 big, S1 small |
| `s1_role_score_growth_pool` | 62.2% | 18.49 | 18.11 | 1251.3 | S1 boss, S1 big, S1 small |
| `s1_role_shape_fix_pool` | 66.9% | 19.35 | 19.02 | 1312.4 | S1 boss, S1 big, S3 big |
| `s1_role_weak_flavor_pool` | 61.8% | 18.39 | 18.00 | 1271.7 | S1 boss, S4 boss, S1 big |

상위 조합:

| route / market | path clear | total turn | top failures |
|---|---:|---:|---|
| `progression_route_power` / `s1_role_shape_fix_pool` | 73.0% | 1335.0 | S1 boss, S1 big, S8 big |
| `progression_route_power` / `s1_build_aware_pack_plus5` | 72.0% | 1262.0 | S1 boss, S1 big, S1 small |
| `progression_route_power` / `s1_full_safe_candidate_pool` | 66.8% | 1252.8 | S1 boss, S1 big, S4 boss |
| `progression_route_power` / `s1_probabilistic_candidate_pool` | 66.8% | 1232.8 | S1 boss, S1 big, S1 small |
| `progression_route_power` / `s1_role_deck_sustain_pool` | 66.8% | 1222.6 | S1 boss, S1 big, S1 small |
| `progression_route_power` / `s1_role_score_growth_pool` | 65.2% | 1232.2 | S1 boss, S1 big, S1 small |

해석:

- `progression_route_power`는 v29에 이어 가장 안정적이다.
- `s1_role_shape_fix_pool`은 최고 path clear를 만들지만 total turn이 길다. 늘어지는 게임 방지 기준에서는 그대로 상한 후보로만 본다.
- `s1_build_aware_pack_plus5`는 여전히 강력한 상한선이다. 다만 실제 Pack이 항상 이 품질로 선택되면 너무 안정적일 수 있다.
- `s1_role_deck_sustain_pool`, `s1_probabilistic_candidate_pool`, `s1_full_safe_candidate_pool`은 clear가 비슷하면서 total turn이 낮아 실 구현 후보로 더 현실적이다.
- 다음 기준 후보는 `base_score_curve_v2_boss_constraint_pool_v4_s1_soft` + `progression_route_power` + `s1_role_deck_sustain_pool` 또는 `s1_probabilistic_candidate_pool`이다.
- 실제 구현 승격은 아직 아니다. 다음에는 확률형 후보 풀 내부의 등장/선택 가중치를 조정해 `build-aware Pack` 상한과 `weak_flavor` 하한 사이의 안정 구간을 만든다.

## v31 Station weighted market policy

v31은 고정 market profile이 아니라 station/tier마다 후보를 다시 뽑는 시뮬 전용 마켓 정책을 검증했다. 목표는 레벨링 테이블이 “고정 지급”이 아니라 “그 시점에 열리는 후보군 + 가중치”로 갈 수 있는지 확인하는 것이다.

추가한 profile:

- `s1_station_weighted_candidate_pool`
  - summary의 `market_profile`은 정책 이름으로 유지한다.
  - battle row의 `resolved_market_profile`에는 실제 station/tier에서 뽑힌 후보를 기록한다.
  - S1은 마켓 적용 전 구간이라 정책 이름 그대로 남긴다.
  - S2~S3은 Common Jester와 Tarot/Pack을 높게 둔다.
  - S4~S5는 Uncommon, Tarot, Pack, Planet 비중을 올린다.
  - S6~S8은 Planet/Rare/Legendary 쪽 가중치를 조금 올린다.
  - Rare/Legendary는 초반에도 0으로 막지 않는다.

실험 파일:

- `logs/sim/ml_sweep_station_weighted_market_v31_r400_summary.json`
- `logs/sim/ml_sweep_station_weighted_market_v31_r400_report.md`
- `logs/sim/ml_sweep_station_weighted_market_v31_r400_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_station_weighted_market_v31_r400_summary_ml_insights_report.md`

조건:

- runs: 400
- experiment: `base_score_curve_v2_boss_constraint_pool_v4_s1_soft`
- stations: 1~8
- loadout:
  - `progression_route_balanced`
  - `progression_route_power`
- market:
  - `none`
  - `s1_build_aware_pack_plus5`
  - `s1_probabilistic_candidate_pool`
  - `s1_role_deck_sustain_pool`
  - `s1_station_weighted_candidate_pool`
- summary-only

Market 전체:

| market profile | path clear | avg attempted steps | avg cleared steps | total turn | top failures |
|---|---:|---:|---:|---:|---|
| `none` | 60.9% | 18.32 | 17.93 | 1286.1 | S1 boss, S5 boss, S1 big |
| `s1_build_aware_pack_plus5` | 69.1% | 19.12 | 18.81 | 1307.5 | S1 boss, S1 big, S1 small |
| `s1_probabilistic_candidate_pool` | 63.9% | 18.69 | 18.33 | 1283.3 | S1 boss, S1 big, S1 small |
| `s1_role_deck_sustain_pool` | 61.4% | 18.25 | 17.86 | 1258.8 | S1 boss, S1 big, S5 boss |
| `s1_station_weighted_candidate_pool` | 64.8% | 18.76 | 18.41 | 1279.4 | S1 boss, S1 big, S1 small |

Route + market:

| route / market | path clear | total turn | top failures |
|---|---:|---:|---|
| `progression_route_power` / `s1_station_weighted_candidate_pool` | 69.2% | 1269.3 | S1 boss, S1 small, S1 big |
| `progression_route_power` / `s1_build_aware_pack_plus5` | 69.0% | 1250.9 | S1 boss, S1 big, S1 small |
| `progression_route_power` / `s1_probabilistic_candidate_pool` | 68.2% | 1282.9 | S1 boss, S1 big, S1 small |
| `progression_route_power` / `s1_role_deck_sustain_pool` | 67.5% | 1256.5 | S1 boss, S1 big, S3 boss |
| `progression_route_balanced` / `s1_station_weighted_candidate_pool` | 60.2% | 1289.5 | S1 boss, S5 boss, S1 big |

Station weighted resolved 분포:

| station | 상위 resolved 후보 |
|---|---|
| S2 | common color, common rank, uncommon build, tarot, tile pack |
| S3 | common color, common rank, planet, uncommon build, tarot |
| S4 | uncommon build, planet, common color, tarot, build-aware pack |
| S5 | uncommon build, tarot, planet, common rank, tile pack |
| S6 | planet, uncommon build, tile pack, voucher, tarot |
| S7 | planet, uncommon build, common color, tarot, build-aware pack |
| S8 | planet, uncommon build, common color, voucher, rare xmult |

해석:

- `s1_station_weighted_candidate_pool`은 고정 보상이 아니라 station별 후보 분포를 만들면서도 `probabilistic`보다 높고 `build-aware` 상한선보다 낮다.
- `progression_route_power`와 결합하면 `build-aware Pack`과 거의 같은 path clear를 보인다.
- 다만 현재 v31은 station/tier 기반 가중치만 있고, 실제 run state 기반 보정은 아직 약하다.
- 다음 단계는 `s1_station_weighted_candidate_pool`을 기준으로 deck pressure, score shortfall, board lock 위험에 따른 state modifier를 추가해 “현재 상태에 맞는 마켓 등장 가중치”를 검증하는 것이다.
- 최종 레벨링 테이블은 고정 보상 목록이 아니라 `station target score + boss constraint + market unlock band + role/rarity weight table` 형태로 가야 한다.

## v32b 상태 기반 마켓 가중치 검증

목적:

- v31의 station/tier 기반 후보 분포 위에 직전 전투 상태를 반영한다.
- 실제 저장/상점 상태를 만들지 않고, 시뮬 전용 `s1_state_weighted_candidate_pool`만 추가한다.
- deck pressure, score shortfall, board lock risk에 따라 다음 전투의 후보 가중치가 약하게 기울어지는지 본다.

주의:

- v32 초안은 `board_occupancy`를 0~1 비율로 잘못 해석했다. 실제 값은 점유 칸 수에 가까워 평균 13 수준이므로, board lock 기준을 `>= 18` 칸으로 고친 v32b를 판단 기준으로 삼는다.

실행:

- summary: `logs/sim/ml_sweep_state_weighted_market_v32b_r400_summary.json`
- report: `logs/sim/ml_sweep_state_weighted_market_v32b_r400_report.md`
- bottleneck: `logs/sim/ml_sweep_state_weighted_market_v32b_r400_summary_bottleneck_report.md`
- ML insight: `logs/sim/ml_sweep_state_weighted_market_v32b_r400_summary_ml_insights_report.md`
- runs: 400
- stations: 1~8
- loadout: `progression_route_balanced`, `progression_route_power`
- market:
  - `none`
  - `s1_build_aware_pack_plus5`
  - `s1_probabilistic_candidate_pool`
  - `s1_station_weighted_candidate_pool`
  - `s1_state_weighted_candidate_pool`

Market 전체:

| market profile | path clear | total turn |
|---|---:|---:|
| `none` | 58.2% | 1270.6 |
| `s1_build_aware_pack_plus5` | 72.1% | 1332.3 |
| `s1_probabilistic_candidate_pool` | 66.2% | 1288.0 |
| `s1_station_weighted_candidate_pool` | 64.6% | 1260.3 |
| `s1_state_weighted_candidate_pool` | 64.5% | 1253.5 |

Route + market:

| route / market | path clear | total turn | top failures |
|---|---:|---:|---|
| `progression_route_power` / `s1_probabilistic_candidate_pool` | 74.2% | 1327.6 | S1 boss, S2 boss, S1 big |
| `progression_route_power` / `s1_build_aware_pack_plus5` | 72.5% | 1283.2 | S1 boss, S1 big, S1 small |
| `progression_route_power` / `s1_station_weighted_candidate_pool` | 70.2% | 1276.9 | S1 boss, S1 small, S1 big |
| `progression_route_power` / `s1_state_weighted_candidate_pool` | 70.0% | 1257.4 | S1 boss, S1 big, S1 small |
| `progression_route_balanced` / `s1_state_weighted_candidate_pool` | 59.0% | 1249.6 | S1 boss, S1 big, S1 small |

해석:

- `s1_state_weighted_candidate_pool`은 `s1_station_weighted_candidate_pool`과 거의 같은 clear rate를 유지하면서 평균 turn을 약간 낮춘다.
- 하지만 clear rate가 더 좋아진 것은 아니다. 따라서 현재 상태 보정은 “승률 보강”보다는 “늘어짐 억제형 변형”에 가깝다.
- `progression_route_power`에서는 `probabilistic`이 74.2%로 가장 높았지만, turn도 1327.6으로 길다. 높은 승률만 보면 안 되고 턴 늘어짐과 실패 분포를 같이 봐야 한다.
- S1 실패가 계속 상위에 남는다. S1은 market 적용 전 구간이므로, 마켓 보상만으로는 해결되지 않는다. 초반 base curve, S1 boss 제약, 시작 loadout을 따로 다시 봐야 한다.
- 현재 유력 기준은 `progression_route_power + station/state weighted` 계열이다. 단, 최종 테이블은 고정 profile이 아니라 station band, rarity weight, state modifier를 분리해야 한다.

다음 판단:

- 상태 기반 profile은 버리지 않는다. 다만 지금 가중치는 승률 향상보다 턴 억제 쪽이므로, target score curve 재검토와 함께 다시 학습해야 한다.
- 다음 sweep는 S1/S2 초반 병목을 분리해서 `market 적용 전 실패`와 `market 적용 후 실패`를 나눠 봐야 한다.
- 이후 전체 레벨링 테이블은 `초반 생존 curve`, `중반 성장 curve`, `후반 빌드 완성 curve`를 별도 구간으로 잡는다.

## v33 early curve 재검토

목적:

- S1/S2 실패를 마켓 문제가 아니라 초반 curve 문제로 분리한다.
- 기존 sim-only 후보인 `base_score_curve_v2_boss_constraint_pool_v4`의 S1 soft/resource 변형을 같은 조건으로 비교한다.

실행:

- summary: `logs/sim/ml_sweep_early_curve_v33_r400_summary.json`
- report: `logs/sim/ml_sweep_early_curve_v33_r400_report.md`
- bottleneck: `logs/sim/ml_sweep_early_curve_v33_r400_summary_bottleneck_report.md`
- ML insight: `logs/sim/ml_sweep_early_curve_v33_r400_summary_ml_insights_report.md`
- runs: 400
- experiments:
  - `base_score_curve_v2_boss_constraint_pool_v4`
  - `base_score_curve_v2_boss_constraint_pool_v4_s1_soft`
  - `base_score_curve_v2_boss_constraint_pool_v4_s1_resource`
  - `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_resource`

결과:

| experiment | path clear | total turn | S1 fail | S2 fail | top failures |
|---|---:|---:|---:|---:|---|
| `base_score_curve_v2_boss_constraint_pool_v4` | 57.6% | 1192.7 | 914 | 107 | S1 boss, S1 big, S1 small |
| `base_score_curve_v2_boss_constraint_pool_v4_s1_resource` | 58.4% | 1192.8 | 903 | 123 | S1 boss, S1 big, S1 small |
| `base_score_curve_v2_boss_constraint_pool_v4_s1_soft` | 64.9% | 1284.0 | 580 | 122 | S1 boss, S1 big, S1 small |
| `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_resource` | 65.8% | 1292.1 | 548 | 141 | S1 boss, S1 big, S4 boss |

해석:

- S1 resource만 추가하는 것은 거의 효과가 없다.
- S1 soft는 S1 실패를 크게 줄이고 전체 clear를 약 7%p 올린다.
- S1 soft_resource가 전체 clear는 가장 높지만 S2 실패와 평균 turn이 늘어난다.
- 초반을 살리는 핵심은 자원 보정이 아니라 S1 target/제약 완화다.
- 현재 기준 후보는 `base_score_curve_v2_boss_constraint_pool_v4_s1_soft`다. `soft_resource`는 강한 후보지만, 초반에 너무 많은 안정성을 주는지 추가 확인이 필요하다.

## v34 S1 soft + S2 boss bridge 검증

목적:

- v33에서 S1 soft 이후 S2 boss 실패가 보이므로, S1 soft를 유지한 상태에서 S2 boss target만 약하게 낮추는 후보를 검증한다.
- 추가한 후보는 sim-only experiment이며 실제 게임 테이블에는 연결하지 않았다.

실행:

- summary: `logs/sim/ml_sweep_early_s2_bridge_v34_r400_summary.json`
- report: `logs/sim/ml_sweep_early_s2_bridge_v34_r400_report.md`
- bottleneck: `logs/sim/ml_sweep_early_s2_bridge_v34_r400_summary_bottleneck_report.md`
- ML insight: `logs/sim/ml_sweep_early_s2_bridge_v34_r400_summary_ml_insights_report.md`
- runs: 400
- experiments:
  - `base_score_curve_v2_boss_constraint_pool_v4_s1_soft`
  - `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_s2_boss_090`
  - `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_s2_boss_085`

결과:

| experiment | path clear | total turn | S1 fail | S2 fail | top failures |
|---|---:|---:|---:|---:|---|
| `base_score_curve_v2_boss_constraint_pool_v4_s1_soft` | 64.8% | 1284.9 | 586 | 128 | S1 boss, S1 big, S1 small |
| `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_s2_boss_090` | 64.7% | 1281.0 | 598 | 122 | S1 boss, S1 big, S1 small |
| `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_s2_boss_085` | 64.8% | 1280.8 | 592 | 115 | S1 boss, S1 big, S1 small |

Power route 주요 market:

| experiment / market | path clear | total turn | top failures |
|---|---:|---:|---|
| `s1_soft` / `s1_build_aware_pack_plus5` | 74.2% | 1299.4 | S1 boss, S1 big, S1 small |
| `s1_soft` / `s1_probabilistic_candidate_pool` | 70.5% | 1288.0 | S1 boss, S1 big, S2 boss |
| `s1_soft` / `s1_station_weighted_candidate_pool` | 69.2% | 1284.5 | S1 boss, S1 big, S8 boss |
| `s1_soft_s2_boss_085` / `s1_probabilistic_candidate_pool` | 70.2% | 1275.2 | S1 boss, S1 big, S1 small |
| `s1_soft_s2_boss_085` / `s1_state_weighted_candidate_pool` | 68.2% | 1250.6 | S1 boss, S1 small, S1 big |

해석:

- S2 boss를 0.90/0.85로 낮춰도 전체 clear가 의미 있게 오르지 않는다.
- S2 fail은 줄지만 S1 fail과 S4/S8 실패가 남아, 병목이 단순 S2 target 문제가 아님을 확인했다.
- S2 보정 후보는 현재 기준 테이블로 승격하지 않는다.
- 다음 기준은 `base_score_curve_v2_boss_constraint_pool_v4_s1_soft`를 유지하고, S1 자체와 S4/S8 이후의 실패 구조를 별도 구간으로 본다.

## v35 S1 curve 세분화

목적:

- v34에서 S2 boss 보정이 효과적이지 않았으므로, S1 자체를 다시 분해한다.
- S1 boss만 낮추는 후보와 S1 small/big/boss 전체를 조금 더 낮추는 후보를 비교한다.
- 모두 sim-only experiment이며 실제 블라인드/상점 데이터에는 연결하지 않았다.

실행:

- summary: `logs/sim/ml_sweep_s1_curve_v35_r400_summary.json`
- report: `logs/sim/ml_sweep_s1_curve_v35_r400_report.md`
- bottleneck: `logs/sim/ml_sweep_s1_curve_v35_r400_summary_bottleneck_report.md`
- ML insight: `logs/sim/ml_sweep_s1_curve_v35_r400_summary_ml_insights_report.md`
- runs: 400
- experiments:
  - `base_score_curve_v2_boss_constraint_pool_v4_s1_soft`
  - `base_score_curve_v2_boss_constraint_pool_v4_s1_boss_052`
  - `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2`

결과:

| experiment | path clear | total turn | S1 fail | S2 fail | S3~S5 fail | S6~S8 fail |
|---|---:|---:|---:|---:|---:|---:|
| `s1_soft` | 64.3% | 1278.0 | 603 | 135 | 428 | 263 |
| `s1_boss_052` | 66.3% | 1314.2 | 488 | 133 | 458 | 269 |
| `s1_soft_v2` | 67.3% | 1313.1 | 452 | 134 | 457 | 265 |

Power route 주요 market:

| experiment / market | path clear | total turn | top failures |
|---|---:|---:|---|
| `s1_boss_052` / `s1_station_weighted_candidate_pool` | 70.8% | 1302.6 | S1 big, S1 boss, S1 small |
| `s1_soft_v2` / `s1_station_weighted_candidate_pool` | 71.5% | 1284.3 | S1 boss, S1 big, S1 small |
| `s1_soft_v2` / `s1_state_weighted_candidate_pool` | 72.5% | 1301.5 | S1 boss, S1 big, S7 boss |
| `s1_soft_v2` / `s1_build_aware_pack_plus5` | 76.0% | 1306.0 | S1 boss, S1 big, S1 small |

해석:

- S1 boss만 낮추는 것보다 S1 small/big/boss 전체를 낮춘 `s1_soft_v2`가 더 안정적이다.
- S1 fail은 `s1_soft` 603에서 `s1_soft_v2` 452로 줄었다.
- 대신 평균 turn이 약 35턴 늘고, 실패가 S3~S5/S6~S8로 이동한다. 즉 초반 생존은 개선됐지만 중후반 늘어짐 억제와 후반 병목은 별도 조정이 필요하다.
- 현재 기준 후보는 `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2`로 올려 볼 수 있다.
- 단, `s1_soft_v2 + build-aware pack`은 clear 76.0%까지 올라 상한선 성격이다. 실제 기준 후보는 `station_weighted` 또는 `state_weighted`와 함께 봐야 한다.

다음 판단:

- 다음 sweep는 `s1_soft_v2`를 기준으로 S4/S5/S8 병목을 분리한다.
- 초반은 더 낮추기보다 현재 후보를 기준으로 묶고, 중후반 boss constraint/target curve를 조정해야 한다.
- 목표는 “초반 통과율 확보 + 중반 성장 요구 + 후반 빌드 완성”의 3구간 curve를 만드는 것이다.

## v36 3구간 target curve guard 검증

목적:

- S1~S2, S3~S5, S6~S8을 다른 기준으로 봐야 한다는 전제를 실험으로 확인한다.
- 초반 빌드가 다음 구간 초입까지는 간신히 닿더라도, 다음 구간 boss를 안정적으로 클리어하지 못하는지 본다.
- 새 후보는 모두 sim-only experiment이며 실제 UI/저장/마켓 데이터에는 연결하지 않았다.

추가한 sim-only experiment:

- `base_score_curve_v2_boss_constraint_pool_v4_three_band_v1`
  - S1은 `s1_soft_v2`와 동일.
  - S3~S5는 small 1.10, big 0.88, boss 0.70.
  - S6~S8은 small 1.14, big 0.92, boss 0.76.
- `base_score_curve_v2_boss_constraint_pool_v4_mid_gate_v1`
  - S3~S5를 더 강하게 올린 중반 gate 후보.
- `base_score_curve_v2_boss_constraint_pool_v4_late_gate_v1`
  - S6~S8을 더 강하게 올린 후반 gate 후보.

실행:

- summary: `logs/sim/ml_sweep_three_band_curve_v36_r400_summary.json`
- report: `logs/sim/ml_sweep_three_band_curve_v36_r400_report.md`
- bottleneck: `logs/sim/ml_sweep_three_band_curve_v36_r400_summary_bottleneck_report.md`
- ML insight: `logs/sim/ml_sweep_three_band_curve_v36_r400_summary_ml_insights_report.md`
- runs: 400
- elapsed: 28m31s
- summary-only 실행으로 통합 JSONL은 남기지 않았다.

Progression route 전체 평균:

| experiment | market | path clear | avg turn | S1~S2 fail | S3~S5 fail | S6~S8 fail |
|---|---|---:|---:|---:|---:|---:|
| `s1_soft_v2` | `none` | 59.5% | 1303.5 | 179 | 208 | 99 |
| `s1_soft_v2` | `probabilistic` | 66.7% | 1332.1 | 155 | 167 | 78 |
| `s1_soft_v2` | `station_weighted` | 67.8% | 1327.8 | 170 | 143 | 74 |
| `s1_soft_v2` | `state_weighted` | 67.5% | 1327.0 | 164 | 146 | 80 |
| `three_band_v1` | `none` | 50.8% | 1313.3 | 158 | 286 | 146 |
| `three_band_v1` | `probabilistic` | 61.5% | 1333.4 | 158 | 211 | 93 |
| `three_band_v1` | `station_weighted` | 62.3% | 1344.5 | 179 | 164 | 109 |
| `three_band_v1` | `state_weighted` | 60.7% | 1335.0 | 176 | 175 | 121 |
| `mid_gate_v1` | `station_weighted` | 58.3% | 1329.2 | 161 | 230 | 109 |
| `late_gate_v1` | `state_weighted` | 61.8% | 1391.7 | 145 | 167 | 147 |

Progression route power:

| experiment | market | path clear | avg turn | 주요 병목 |
|---|---|---:|---:|---|
| `s1_soft_v2` | `station_weighted` | 71.8% | 1287.7 | S1 boss, S1 big, S3 boss |
| `s1_soft_v2` | `state_weighted` | 74.2% | 1336.9 | S1 boss, S1 big, S7 boss |
| `three_band_v1` | `probabilistic` | 69.5% | 1336.8 | S1 boss, S8 boss, S3 big |
| `mid_gate_v1` | `station_weighted` | 68.8% | 1365.0 | S1 boss, S8 boss, S8 big |
| `late_gate_v1` | `state_weighted` | 66.8% | 1364.2 | S8 boss, S8 big, S1 big |

Static guard 확인:

| experiment | loadout | market | path clear | 주 실패 구간 |
|---|---|---|---:|---|
| `s1_soft_v2` | `s2_foundation_build` | `none` | 0.0% | S3~S5 297회 |
| `s1_soft_v2` | `s3_hand_growth_build` | `none` | 0.0% | S3~S5 212회, S6~S8 153회 |
| `s1_soft_v2` | `s5_power_build` | `none` | 0.2% | S6~S8 312회 |
| `three_band_v1` | `s2_foundation_build` | `none` | 0.0% | S3~S5 349회 |
| `mid_gate_v1` | `s2_foundation_build` | `none` | 0.0% | S3~S5 354회 |
| `late_gate_v1` | `s5_power_build` | `none` | 0.0% | S6~S8 306회 |

해석:

- “초반 빌드가 후반까지 그대로 가면 안 된다”는 guard는 이미 `s1_soft_v2`에서도 대부분 만족한다.
  - `s2_foundation_build`, `s3_hand_growth_build`는 전체 path clear 0%.
  - `s5_power_build`도 `none`에서는 0.2% 수준이며, weighted market에서도 0~3.2% 수준이다.
- 3구간 target을 전역으로 올리면 guard는 더 강해지지만 정상 progression route도 같이 약해진다.
  - `s1_soft_v2 + station_weighted` progression 평균 clear 67.8%.
  - `three_band_v1 + station_weighted`는 62.3%.
  - `mid_gate_v1 + station_weighted`는 58.3%.
- 따라서 3구간화는 맞지만, 해결책은 target curve를 전역으로 올리는 방식이 아니다.
- 다음 기준 후보는 여전히 `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2`다.
- market 기준은 `station_weighted`와 `state_weighted`를 둘 다 유지한다.
  - `station_weighted`는 turn이 낮고 안정적이다.
  - `state_weighted`는 power route clear가 높지만 turn이 늘 수 있다.

다음 판단:

- S3~S5, S6~S8의 “성장 요구”는 target curve 상승보다 reward/market availability/route upgrade timing으로 만들어야 한다.
- 다음 sweep는 `s1_soft_v2`를 유지하고, progression route의 구간별 보상 투입 시점과 market pool availability를 조정한다.
- `three_band_v1`, `mid_gate_v1`, `late_gate_v1`은 기준 승격 보류. hard wall 상한선/반례 자료로만 둔다.

## v37 Banded market availability 검증

목적:

- v36 결론에 따라 target curve를 더 올리지 않고, 구간별로 열리는 후보군을 다르게 둔다.
- 실제 상점 UI/저장/실제 market catalog는 건드리지 않는다.
- `market_profile` 하나가 실제 상점 슬롯이 아니라 “해당 step에서 구매 결과 하나가 뽑혔다”는 proxy임을 유지한다.

추가한 sim-only market profile:

- `banded_candidate_pool_v1`
  - S1~S2: Common Jester, 기초 shape/Tarot, Pack 위주.
  - S3~S5: Uncommon build Jester, Tarot/Planet, Pack 위주.
  - S6~S8: Planet, Rare XMult, Legendary proxy 가중치 상승.
  - Rare/Legendary는 초반에도 0%로 막지 않고 낮은 확률로 남긴다.

실행:

- summary: `logs/sim/ml_sweep_banded_market_v37_r400_summary.json`
- report: `logs/sim/ml_sweep_banded_market_v37_r400_report.md`
- bottleneck: `logs/sim/ml_sweep_banded_market_v37_r400_summary_bottleneck_report.md`
- ML insight: `logs/sim/ml_sweep_banded_market_v37_r400_summary_ml_insights_report.md`
- runs: 400
- elapsed: 17m55s
- summary-only 실행으로 통합 JSONL은 남기지 않았다.

Progression route 전체 평균:

| market | path clear | avg turn | S1~S2 fail | S3~S5 fail | S6~S8 fail | 주요 병목 |
|---|---:|---:|---:|---:|---:|---|
| `none` | 60.8% | 1325.9 | 169 | 203 | 99 | S1 boss, S5 boss, S4 boss |
| `probabilistic` | 65.7% | 1324.1 | 151 | 189 | 72 | S1 boss, S1 big, S4 boss |
| `station_weighted` | 65.2% | 1293.9 | 198 | 142 | 78 | S1 boss, S1 big, S1 small |
| `state_weighted` | 67.9% | 1326.6 | 166 | 148 | 71 | S1 boss, S1 big, S5 boss |
| `banded_v1` | 67.5% | 1347.3 | 149 | 149 | 92 | S1 boss, S1 small, S5 boss |

Progression route power:

| market | path clear | avg turn | S1~S2 fail | S3~S5 fail | S6~S8 fail | 주요 병목 |
|---|---:|---:|---:|---:|---:|---|
| `none` | 68.0% | 1326.9 | 58 | 26 | 44 | S1 boss, S8 boss, S1 big |
| `probabilistic` | 72.2% | 1298.6 | 53 | 29 | 29 | S1 boss, S1 big, S3 boss |
| `station_weighted` | 71.8% | 1272.2 | 65 | 25 | 23 | S1 boss, S1 big, S1 small |
| `state_weighted` | 73.8% | 1319.5 | 46 | 31 | 28 | S1 boss, S1 small, S3 big |
| `banded_v1` | 73.8% | 1334.5 | 43 | 29 | 33 | S1 boss, S1 small, S8 boss |

Static guard:

| market | `s2_foundation_build` clear | `s3_hand_growth_build` clear | `s5_power_build` clear |
|---|---:|---:|---:|
| `none` | 0.0% | 0.0% | 0.0% |
| `probabilistic` | 0.0% | 0.0% | 3.8% |
| `station_weighted` | 0.0% | 0.0% | 1.5% |
| `state_weighted` | 0.0% | 0.0% | 2.2% |
| `banded_v1` | 0.0% | 0.0% | 3.5% |

해석:

- `banded_candidate_pool_v1`은 progression 전체 평균 clear 67.5%로 `state_weighted` 67.9%와 거의 동급이다.
- `banded_v1`은 S1~S2 실패를 줄이지만 S6~S8 실패가 다시 늘고, 평균 turn이 1347.3으로 가장 길다.
- power route에서는 `banded_v1` clear 73.8%로 `state_weighted`와 같지만 turn은 더 길다.
- static guard는 유지된다.
  - `s2_foundation_build`, `s3_hand_growth_build`는 모든 market에서 path clear 0%.
  - `s5_power_build`는 market이 붙으면 1.5~3.8%까지 살아남지만, 후반 안정 클리어로 보기는 어렵다.
- 따라서 구간별 후보군 방향은 맞지만, `banded_v1` 그대로 기준 승격은 보류한다.

다음 판단:

- `banded_v2`는 S6~S8의 Planet/Rare/Legendary 가중치를 조금 낮추고, 중반 S3~S5에서 성장 후보를 더 일찍 주되 후반 턴 늘어짐을 줄이는 쪽으로 조정한다.
- 실제 구현 전환은 아직 아니다. 실제 상점에서는 이 proxy를 “고정 지급”으로 옮기지 말고, 구간별 candidate availability와 슬롯별 rarity roll로 다시 설계해야 한다.

## v38 Banded v2 smoke funnel

목적:

- 긴 400 runs를 바로 돌리지 않고, 100 runs smoke로 `banded_candidate_pool_v2`의 방향성을 빠르게 본다.
- 우선순위는 turn 감소, deck/board 막힘 감소, progression route clear 유지, static guard 유지 순서로 둔다.
- “조금 잘 터지는 초반 재미”는 허용하지만, 늘어지는 턴은 가장 먼저 배제한다.

추가/조정:

- `banded_candidate_pool_v2`
  - `banded_v1`보다 S6~S8의 장기 resource/Planet 비중을 낮추고 Rare/XMult, Legendary proxy 쪽을 올렸다.
  - 목적은 오래 버티는 후반이 아니라 짧게 터지는 후반이다.

실행:

- 1차 smoke summary: `logs/sim/ml_sweep_banded_market_v38_smoke_r100_summary.json`
- 2차 조정 smoke summary: `logs/sim/ml_sweep_banded_market_v38b_smoke_r100_summary.json`
- runs: 100
- summary-only 실행으로 통합 JSONL은 남기지 않았다.

2차 smoke 결과:

| market | progression clear | avg turn | S1~S2 fail | S3~S5 fail | S6~S8 fail |
|---|---:|---:|---:|---:|---:|
| `none` | 60.3% | 1284.4 | 43 | 59 | 17 |
| `state_weighted` | 68.0% | 1355.2 | 35 | 38 | 23 |
| `banded_v1` | 67.7% | 1330.8 | 41 | 38 | 18 |
| `banded_v2` | 62.3% | 1268.3 | 52 | 38 | 23 |

Route별:

| market | balanced clear/turn | sustain clear/turn | power clear/turn |
|---|---:|---:|---:|
| `state_weighted` | 66.0% / 1412.8 | 66.0% / 1365.6 | 72.0% / 1287.3 |
| `banded_v1` | 73.0% / 1426.9 | 64.0% / 1320.2 | 66.0% / 1245.2 |
| `banded_v2` | 58.0% / 1231.5 | 63.0% / 1292.2 | 66.0% / 1281.4 |

Static guard:

| market | `s2_foundation_build` | `s3_hand_growth_build` | `s5_power_build` |
|---|---:|---:|---:|
| `state_weighted` | 0.0% | 0.0% | 3.0% |
| `banded_v1` | 0.0% | 0.0% | 1.0% |
| `banded_v2` | 0.0% | 0.0% | 4.0% |

해석:

- `banded_v2`는 turn을 줄였지만 progression clear가 62.3%로 낮아졌다.
- `banded_v2`는 power route도 66.0%로 낮아져 실무 기준 후보로 올리기 어렵다.
- `banded_v1`은 clear는 유지하지만 balanced route turn이 길고, `state_weighted`는 clear가 안정적이지만 평균 turn이 길다.
- 따라서 `banded_v2`는 400 runs로 승격하지 않는다.

실무 판단:

- 이제 target curve나 단일 market proxy를 계속 미세 조정하기보다, 실제 상점에 가까운 “슬롯형 마켓 시뮬”로 넘어갈 기준이 생겼다.
- 다음 단계는 구매 결과 하나를 바로 뽑는 방식이 아니라, station band별 candidate availability에서 3~5개 shop slot을 roll하고 bot이 하나를 고르는 proxy다.
- 우선 실무 기준은 다음 중간값을 목표로 둔다.
  - progression 전체 clear: 66~68%
  - power route clear: 72% 전후
  - 평균 turn: `state_weighted`보다 낮게, `banded_v1` 수준 이하
  - static guard: `s2_foundation_build`, `s3_hand_growth_build` 0%, `s5_power_build` 4% 이하
  - 초반 high-roll은 허용하되 후반 resource drag는 줄인다.

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

## 시뮬레이션 자료 인덱스

2026-05-02 기준 `logs/sim`에는 379개 파일, 약 303MB가 있다. 파일은 `.gitignore`의 `logs/` 규칙으로 Git 추적 대상이 아니므로, 장기 기준은 이 문서의 링크와 요약을 우선한다.

### 현재 판단 기준 자료

아래 자료는 다음 레벨링 판단에서 우선 참조한다.

| 구분 | 대표 파일 | 판단 용도 |
|------|-----------|-----------|
| 기준 스코어커브 재산정 | `logs/sim/ml_sweep_base_score_curve_v2_final_r400_summary.json` | 후보/보스 제약을 얹기 전의 순수 station target curve 기준 |
| 보스 제약 치환 세트 | `logs/sim/ml_sweep_base_curve_v2_constraints_v21_r400_summary.json` | `boss_constraint_adaptation_set`이 hard wall을 만드는지 확인 |
| 치환 후보 풀 1차 | `logs/sim/ml_sweep_base_v2_constraint_v4_candidate_pool_v22_r400_summary.json` | `adapted_candidate_pool`이 S5/S7 deck pressure를 얼마나 푸는지 확인 |
| 역할별 후보 풀 | `logs/sim/ml_sweep_role_candidate_pools_v24_r400_summary.json` | deck sustain, score spike, shape fix, economy 계열 역할 분리 |
| 경로 생존 기준 | `logs/sim/ml_sweep_progression_routes_v26_r400_summary.json` | static loadout이 아니라 성장 route 기준으로 전체 path survival 확인 |
| 초반 온보딩 | `logs/sim/ml_sweep_s1_onboarding_progression_v27_r400_summary.json` | S1 실패 집중과 soft/resource 보정 비교 |
| 초반 빌드 방지 guard | `logs/sim/ml_sweep_static_vs_progression_guard_v28_r400_summary.json` | S1~S2 빌드가 후반까지 그대로 통하지 않는지 확인 |
| 중반 성장 간격 | `logs/sim/ml_sweep_mid_growth_spacing_v29_r400_summary.json` | S3~S5 성장 보상 투입 시점 확인 |
| 마켓 역할 재비교 | `logs/sim/ml_sweep_s1_soft_market_roles_v30_r400_summary.json` | S1 soft 기준에서 market role별 장단점 확인 |
| station 가중 마켓 | `logs/sim/ml_sweep_station_weighted_market_v31_r400_summary.json` | 고정 지급이 아닌 station/tier별 등장 후보군 검증 |
| state 가중 마켓 | `logs/sim/ml_sweep_state_weighted_market_v32b_r400_summary.json` | resource state, deck pressure, board pressure 기반 등장 가중치 검증 |
| 초반 curve 재검토 | `logs/sim/ml_sweep_early_curve_v33_r400_summary.json` | S1 soft/resource 후보 재비교 |
| S2 bridge 검증 | `logs/sim/ml_sweep_early_s2_bridge_v34_r400_summary.json` | S1 soft 이후 S2 boss 완화가 필요한지 확인 |
| S1 curve 세분화 | `logs/sim/ml_sweep_s1_curve_v35_r400_summary.json` | S1 small/big/boss multiplier 분리 기준 |
| 슬롯형 마켓 검증 | `logs/sim/ml_sweep_shop_slot_market_v39_r400_summary.json` | 실제 상점에 가까운 슬롯 롤 + bot 선택 proxy가 성장 route와 static guard를 동시에 만족하는지 확인 |

### 역사적 참고 자료

아래 자료는 현재 기준을 만든 과정의 근거다. 새 기준 판단에는 직접 쓰기보다, 왜 기준을 바꿨는지 확인할 때 참조한다.

| 구분 | 대표 파일 | 참고 이유 |
|------|-----------|-----------|
| Pack 하한선 | `logs/sim/ml_sweep_pack_size_v10_summary.json` | 단순 Pack +N과 build-aware Pack의 하한/상한 확인 |
| 확률형 후보 풀 시작점 | `logs/sim/ml_sweep_probabilistic_candidates_v11_summary.json` | Rare/Legendary를 0%로 막지 않는 확률형 풀의 초기 형태 |
| 전체 safe 후보 풀 | `logs/sim/ml_sweep_full_safe_candidate_pool_v12_summary.json` | 충돌 가능 후보 제외 후 넓은 후보를 넣은 기준 |
| 보스 제약 초안 | `logs/sim/ml_sweep_boss_constraints_full_curve_v13_summary.json` | 보스 제약을 한 번에 얹으면 hard wall이 생긴다는 반례 |
| target curve v4~v6 | `logs/sim/ml_sweep_target_v4_constraints_full_safe_r400_summary.json`, `logs/sim/ml_sweep_target_v6_s5_r400_summary.json` | target 보정만으로는 기준이 흔들릴 수 있음을 확인 |
| S4 제약 반복 | `logs/sim/ml_sweep_s4_constraint_v18_r400_summary.json` | `repeat_rank_pressure_v4`가 현재 보스 제약 후보로 남은 과정 |
| 초기 ML sweep | `logs/sim/ml_sweep_train_v1_summary.json`, `logs/sim/ml_sweep_target_v3_summary.json` | 이전 v1~v3 장시간 실험의 비교 맥락 |

### 정리 후보 자료

아래 파일군은 삭제 후보지만, 아직 삭제하지 않는다. 삭제가 필요하면 사용자가 승인한 뒤에만 처리한다.

| 구분 | 파일군 | 이유 |
|------|--------|------|
| raw probe JSONL | `logs/sim/*raw_probe*.jsonl` | v13 병목 분석용 raw이며 현재 판단은 summary/report로 충분함 |
| planner v2 raw JSONL | `logs/sim/planner_v2_*_200.jsonl`, `logs/sim/planner_v2_*_300.jsonl` | 초기 sequence/probe용 raw이며 상위 sweep이 결론을 흡수함 |
| auto leveling smoke | `logs/sim/auto_leveling_*` | 초기 smoke/preview로 현재 기준과 직접 연결되지 않음 |
| v32 초안 | `logs/sim/ml_sweep_state_weighted_market_v32_r400_*` | `board_occupancy` 해석 오류가 있어 v32b만 판단 기준으로 사용 |

현재 공간을 가장 많이 쓰는 raw 파일은 다음 8개다.

| 파일 | 크기 | 처리 제안 |
|------|------|-----------|
| `logs/sim/planner_v2_early_onboarding_joker_200.jsonl` | 44MB | 삭제 후보 |
| `logs/sim/ml_sweep_boss_constraints_v13_raw_probe.jsonl` | 26MB | 삭제 후보 |
| `logs/sim/planner_v2_s1_safety_sequence_200.jsonl` | 23MB | 삭제 후보 |
| `logs/sim/planner_v2_sequence_onboarding_200.jsonl` | 22MB | 삭제 후보 |
| `logs/sim/ml_sweep_boss_constraints_v13_raw_probe_s6_s7.jsonl` | 17MB | 삭제 후보 |
| `logs/sim/ml_sweep_boss_constraints_v13_raw_probe_s7.jsonl` | 16MB | 삭제 후보 |
| `logs/sim/planner_v2_sequence_market_minimal_200.jsonl` | 16MB | 삭제 후보 |
| `logs/sim/planner_v2_s1_safety_resource_probe_300.jsonl` | 5.3MB | 삭제 후보 |

### 현재 기준선

- `base_score_curve_v2`는 후보/보스 제약을 얹기 전 기준 스코어커브다.
- `base_score_curve_v2_boss_constraint_pool_v4`는 보스 제약 치환 세트를 얹은 현재 기준 레이어다.
- `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2`는 v35 이후 검토할 S1 온보딩 기준 후보지만, 아직 최종 확정은 아니다.
- market은 고정 지급이 아니라 station band, rarity weight, state modifier를 분리한 가중 등장 구조로 가야 한다.
- 전체 레벨은 S1~S2, S3~S5, S6~S8 세 구간으로 나눠야 한다. 각 구간의 이전 빌드는 다음 구간 초입까지는 간신히 닿을 수 있어도, 다음 구간 boss를 안정적으로 클리어하지 못하는 방향으로 검증한다.

## v39 슬롯형 마켓 profile 검증

v39는 고정 지급형 market profile이 아니라 실제 상점 구조에 더 가까운 슬롯형 시뮬 profile을 추가했다. 실제 UI, 저장 데이터, 실제 market catalog는 건드리지 않았다.

추가한 sim-only profile:

- `shop_slot_market_v1`
  - S2 이하는 3 slots, S3~S5는 4 slots, S6~S8은 5 slots를 굴린다.
  - 슬롯 후보는 `banded_candidate_pool_v1` 기반으로 station band별 후보를 사용한다.
  - bot은 슬롯 중 하나를 고른다. 선택 proxy는 build-aware 궁합, boss 필요도, late burst를 반영한다.
  - 정적 단일 build가 late rare/legendary 한 번으로 전체 경로를 뚫는 현상을 막기 위해, progression route가 아닌 loadout은 S6 이후 강한 burst 선택 점수를 낮춘다.
  - battle/sequence row에는 `market_shop_slots`를 기록해 “무엇이 등장했고 무엇을 골랐는지”를 분리한다.

실험 파일:

- `logs/sim/ml_sweep_shop_slot_market_v39_r400_summary.json`
- `logs/sim/ml_sweep_shop_slot_market_v39_r400_report.md`
- `logs/sim/ml_sweep_shop_slot_market_v39_r400_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_shop_slot_market_v39_r400_summary_ml_insights_report.md`

조건:

- runs: 400
- experiment: `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2`
- loadout:
  - progression: `progression_route_balanced`, `progression_route_sustain`, `progression_route_power`
  - static guard: `s2_foundation_build`, `s3_hand_growth_build`, `s5_power_build`
- market:
  - `none`
  - `s1_state_weighted_candidate_pool`
  - `banded_candidate_pool_v1`
  - `shop_slot_market_v1`
- summary-only

Progression route 평균:

| market profile | path clear | total turn | attempted steps | cleared steps | top failures |
|---|---:|---:|---:|---:|---|
| `none` | 60.8% | 1320.6 | 18.81 | 18.41 | S1 boss, S4 boss, S5 boss |
| `s1_state_weighted_candidate_pool` | 67.6% | 1323.2 | 19.33 | 19.00 | S1 boss, S1 big, S1 small |
| `banded_candidate_pool_v1` | 66.2% | 1325.7 | 19.39 | 19.05 | S1 boss, S1 big, S4 boss |
| `shop_slot_market_v1` | 69.6% | 1326.3 | 19.75 | 19.45 | S1 boss, S1 big, S5 boss |

Progression route별:

| route / market | path clear | total turn | top failures |
|---|---:|---:|---|
| `progression_route_balanced` / `shop_slot_market_v1` | 63.7% | 1311.2 | S1 boss, S5 boss, S8 boss |
| `progression_route_sustain` / `shop_slot_market_v1` | 69.0% | 1338.6 | S1 boss, S4 boss, S1 big |
| `progression_route_power` / `shop_slot_market_v1` | 76.0% | 1329.1 | S1 boss, S1 big, S8 boss |

Static guard:

| static loadout / market | path clear | total turn | top failures |
|---|---:|---:|---|
| `s2_foundation_build` / `shop_slot_market_v1` | 0.0% | 1148.0 | S5 boss, S6 boss, S6 big |
| `s3_hand_growth_build` / `shop_slot_market_v1` | 0.0% | 1177.2 | S7 big, S7 small, S5 boss |
| `s5_power_build` / `shop_slot_market_v1` | 3.5% | 1354.7 | S7 boss, S8 big, S8 small |

해석:

- `shop_slot_market_v1`은 progression 평균 clear를 가장 높였다. `state_weighted`보다 +2.0%p, `banded_v1`보다 +3.4%p다.
- deck exhausted 계열 stop은 progression route에서 줄었다. `shop_slot`은 `drawPileExhausted` 70회로 `state_weighted` 81회, `banded_v1` 96회보다 낮다.
- 대신 평균 turn과 attempted steps가 올라간다. 늘어짐 방지 기준에서는 장점만 있는 후보가 아니다.
- static guard는 유지된다. S2/S3 고정 build는 전체 path clear 0%, S5 고정 build도 3.5%라 “초반/중반 build가 후반을 그대로 뚫는” 수준은 아니다.
- `progression_route_power + shop_slot_market_v1`은 76.0%로 강하다. 실제 구현으로 바로 옮기면 너무 안정적일 수 있으므로, 구현 후보가 아니라 “상점 구조 proxy의 상한선”으로 둔다.

현재 판단:

- 실제 레벨링 테이블은 `shop_slot_market_v1`처럼 가야 한다. 즉, market은 고정 보상이 아니라 `station band unlock + rarity/category weight + slot count + bot/player choice` 구조여야 한다.
- 단, 현재 v39 수치는 실제 구현 승인 기준이 아니다. `shop_slot_market_v1`은 실제 상점 설계 전 검증용 구조다.
- 다음 단계는 슬롯형 구조를 유지하되, 턴 늘어짐을 줄이기 위해 `S6~S8 slot count/late burst weight/board lock 완화 후보`를 분리해 비교한다.
- 목표는 “클리어율을 조금 올리고, 덱 고갈을 줄이되, total turn은 state weighted 수준 이하로 내리는 것”이다.

## v40 Tempo 슬롯형 마켓 검증

v40은 v39의 `shop_slot_market_v1`을 그대로 두고, 턴 늘어짐을 줄이는 `shop_slot_market_v2`를 추가했다. 실제 UI, 저장 데이터, 실제 market catalog는 건드리지 않았다.

추가한 sim-only profile:

- `shop_slot_market_v2`
  - S6~S8 슬롯 수를 5에서 4로 낮춘다.
  - late 구간에서 Pack/Voucher/장기 자원 후보의 선택 점수를 낮춘다.
  - Rare/Planet/Uncommon build 후보는 즉시 점수 전환 쪽으로 조금 더 선택되게 한다.
  - progression route가 아닌 static loadout에는 v1과 같은 late burst 억제를 유지한다.

실험 파일:

- `logs/sim/ml_sweep_shop_slot_market_v40_r400_summary.json`
- `logs/sim/ml_sweep_shop_slot_market_v40_r400_report.md`
- `logs/sim/ml_sweep_shop_slot_market_v40_r400_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_shop_slot_market_v40_r400_summary_ml_insights_report.md`

조건:

- runs: 400
- experiment: `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2`
- loadout:
  - progression: `progression_route_balanced`, `progression_route_sustain`, `progression_route_power`
  - static guard: `s2_foundation_build`, `s3_hand_growth_build`, `s5_power_build`
- market:
  - `none`
  - `s1_state_weighted_candidate_pool`
  - `shop_slot_market_v1`
  - `shop_slot_market_v2`
- summary-only

Progression route 평균:

| market profile | path clear | total turn | attempted steps | cleared steps | top failures | 주요 stop |
|---|---:|---:|---:|---:|---|---|
| `none` | 61.6% | 1314.2 | 18.70 | 18.31 | S1 boss, S5 boss, S4 boss | board lock 309, deck exhausted 150 |
| `s1_state_weighted_candidate_pool` | 67.6% | 1319.5 | 19.26 | 18.93 | S1 boss, S1 big, S4 boss | board lock 299, deck exhausted 85 |
| `shop_slot_market_v1` | 70.2% | 1329.1 | 19.80 | 19.50 | S1 boss, S1 big, S4 boss | board lock 301, deck exhausted 53 |
| `shop_slot_market_v2` | 68.1% | 1308.6 | 19.39 | 19.07 | S1 boss, S1 big, S1 small | board lock 317, deck exhausted 61 |

Progression route별:

| route / market | path clear | total turn | top failures |
|---|---:|---:|---|
| `progression_route_balanced` / `shop_slot_market_v1` | 68.2% | 1347.8 | S1 boss, S8 big, S1 small |
| `progression_route_balanced` / `shop_slot_market_v2` | 63.2% | 1293.3 | S1 boss, S1 big, S5 boss |
| `progression_route_power` / `shop_slot_market_v1` | 72.8% | 1282.8 | S1 big, S1 boss, S2 boss |
| `progression_route_power` / `shop_slot_market_v2` | 73.5% | 1296.6 | S1 big, S1 boss, S8 big |
| `progression_route_sustain` / `shop_slot_market_v1` | 69.8% | 1356.7 | S1 boss, S1 big, S4 boss |
| `progression_route_sustain` / `shop_slot_market_v2` | 67.5% | 1335.8 | S1 boss, S1 big, S3 boss |

Static guard:

| static loadout / market | path clear | total turn | top failures |
|---|---:|---:|---|
| `s2_foundation_build` / `shop_slot_market_v2` | 0.0% | 1127.0 | S5 boss, S6 big, S6 boss |
| `s3_hand_growth_build` / `shop_slot_market_v2` | 0.0% | 1196.7 | S5 boss, S6 boss, S6 big |
| `s5_power_build` / `shop_slot_market_v2` | 4.8% | 1366.5 | S7 boss, S7 big, S8 big |

해석:

- `shop_slot_market_v2`는 v1보다 progression 평균 clear가 2.1%p 낮지만, total turn을 20.5 낮췄다.
- `s1_state_weighted_candidate_pool`과 비교하면 clear는 +0.5%p, total turn은 -10.9다. 이 점은 실무적으로 의미가 있다.
- deck exhausted는 `state_weighted` 85회에서 `shop_slot_market_v2` 61회로 줄었다. v1의 53회보다는 높지만 충분히 개선됐다.
- 대신 board lock stop은 `state_weighted` 299회에서 `shop_slot_market_v2` 317회로 늘었다. v2의 다음 보강 지점은 덱 고갈이 아니라 board lock이다.
- static guard는 유지되지만 S5 고정 build가 4.8%로 v39의 3.5%보다 높다. 5% 근처는 watch zone으로 본다.

현재 판단:

- `shop_slot_market_v1`은 상한선이다. 잘 터지고 덱 고갈을 크게 줄이지만 평균 턴이 오른다.
- `shop_slot_market_v2`는 실무 기준 후보에 더 가깝다. clear를 유지하면서 total turn을 낮췄다.
- 다만 v2는 board lock과 S5 static guard가 살짝 위험하다.
- 다음 단계는 v2 기반으로 `board_lock_relief`만 약하게 넣은 `shop_slot_market_v3` 또는 boss 제약 쪽 board lock 완화를 비교한다.
- 목표는 `shop_slot_market_v2`의 clear/turn 균형을 유지하면서 board lock stop을 `state_weighted` 수준으로 낮추는 것이다.

## v41 Board lock relief 슬롯형 마켓 검증

v41은 `shop_slot_market_v2`에 직전 전투의 board lock 압박이 있을 때만 Tarot/Discard Glove/shape-fix 선택 점수를 올리는 `shop_slot_market_v3`를 추가했다. 실제 UI, 저장 데이터, 실제 market catalog는 건드리지 않았다.

실험 파일:

- `logs/sim/ml_sweep_shop_slot_market_v41_r400_summary.json`
- `logs/sim/ml_sweep_shop_slot_market_v41_r400_report.md`
- `logs/sim/ml_sweep_shop_slot_market_v41_r400_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_shop_slot_market_v41_r400_summary_ml_insights_report.md`

Progression route 평균:

| market profile | path clear | total turn | attempted steps | cleared steps | 주요 stop |
|---|---:|---:|---:|---:|---|
| `s1_state_weighted_candidate_pool` | 66.0% | 1320.0 | 19.24 | 18.90 | board lock 299, deck exhausted 104 |
| `shop_slot_market_v2` | 68.2% | 1319.6 | 19.55 | 19.24 | board lock 312, deck exhausted 65 |
| `shop_slot_market_v3` | 67.9% | 1314.3 | 19.42 | 19.10 | board lock 312, deck exhausted 71 |

Static guard:

| static loadout / market | path clear | total turn | top failures |
|---|---:|---:|---|
| `s2_foundation_build` / `shop_slot_market_v3` | 0.0% | 1162.6 | S5 boss, S6 boss, S6 big |
| `s3_hand_growth_build` / `shop_slot_market_v3` | 0.0% | 1160.9 | S6 boss, S6 big, S7 big |
| `s5_power_build` / `shop_slot_market_v3` | 4.5% | 1350.5 | S7 boss, S7 big, S8 big |

판단:

- `shop_slot_market_v3`는 v2보다 total turn을 5.3 낮췄지만, board lock stop을 줄이지 못했다.
- deck exhausted는 v2 65회에서 v3 71회로 나빠졌다.
- S5 static guard도 v2 3.2%에서 v3 4.5%로 나빠졌다.
- 따라서 v3는 기준 후보에서 제외한다. 현재 기준 proxy는 `shop_slot_market_v2`로 유지한다.

## 현재 우선순위

1. `shop_slot_market_v2`를 기준 proxy로 고정하고, 전체 stage curve 후보를 다시 비교한다.
2. S1~S2, S3~S5, S6~S8 구간별로 이전 구간 build가 다음 구간 boss를 안정적으로 넘지 못하는지 확인한다.
3. clear rate가 높아진 후보는 tempo, score spike, resource too loose, static guard를 함께 본다.
4. 반복 seed에서 안정적인 후보만 실제 구현 대상으로 승격한다. 아직 실제 UI/저장/상점 구조로 옮기지 않는다.

## v42~v44 Stage curve 재조정

목적은 `shop_slot_market_v2`를 기준 proxy로 두고, S1~S2 빌드가 S3~S5를 그대로 넘거나 S5 빌드가 S6~S8을 그대로 넘는지를 확인하는 것이다. 실제 UI, 저장 데이터, 실제 market catalog는 건드리지 않았다.

실험 파일:

- `logs/sim/ml_sweep_stage_curve_v43_r400_summary.json`
- `logs/sim/ml_sweep_stage_curve_v43_r400_report.md`
- `logs/sim/ml_sweep_stage_curve_v43_r400_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_stage_curve_v43_r400_summary_ml_insights_report.md`
- `logs/sim/ml_sweep_stage_curve_v44_smoke_r100_summary.json`

추가한 sim-only experiment:

- `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1`
  - S1~S2는 `s1_soft_v2`와 동일하게 초반 재미/진입 완화를 유지한다.
  - S3~S5는 별도 강화하지 않는다.
  - S6~S8만 small/big/boss 요구치를 올려 S5 고정 build가 후반을 그대로 뚫지 못하게 한다.
- `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v2`
  - v1에서 small/big만 조금 낮춘 턴 감소 후보.
  - smoke 기준 개선이 작아 r400 승격은 보류한다.

v43 r400 progression route 평균:

| experiment | path clear | total turn | board lock stop | deck exhausted stop |
|---|---:|---:|---:|---:|
| `s1_soft_v2` | 66.7% | 1306.2 | 324 | 79 |
| `s1_soft_v2_late_guard_v1` | 66.3% | 1329.2 | 315 | 96 |
| `three_band_v1` | 60.5% | 1315.1 | 343 | 136 |

v43 r400 static guard:

| experiment / static loadout | path clear | total turn |
|---|---:|---:|
| `s1_soft_v2` / `s2_foundation_build` | 0.0% | 1099.1 |
| `s1_soft_v2` / `s3_hand_growth_build` | 0.0% | 1171.8 |
| `s1_soft_v2` / `s5_power_build` | 4.8% | 1340.5 |
| `s1_soft_v2_late_guard_v1` / `s2_foundation_build` | 0.0% | 1107.0 |
| `s1_soft_v2_late_guard_v1` / `s3_hand_growth_build` | 0.0% | 1124.9 |
| `s1_soft_v2_late_guard_v1` / `s5_power_build` | 0.0% | 1283.1 |
| `three_band_v1` / `s2_foundation_build` | 0.0% | 1071.7 |
| `three_band_v1` / `s3_hand_growth_build` | 0.0% | 1097.7 |
| `three_band_v1` / `s5_power_build` | 0.5% | 1279.3 |

v44 smoke:

| experiment | progression path clear | total turn | S5 static clear |
|---|---:|---:|---:|
| `s1_soft_v2` | 66.3% | 1287.5 | 3.0% |
| `s1_soft_v2_late_guard_v1` | 66.7% | 1310.3 | 1.0% |
| `s1_soft_v2_late_guard_v2` | 67.0% | 1309.7 | 1.0% |

해석:

- `three_band_v1`은 static guard는 강하지만 progression clear를 너무 낮춘다. 전체 기준 curve로는 과하게 빡빡하다.
- `s1_soft_v2`는 progression/turn 균형이 좋지만 S5 static build가 4~5%대로 후반을 누수한다.
- `late_guard_v1`은 S5 static 누수를 0%까지 줄이면서 progression clear를 거의 유지했다. 단점은 total turn 증가와 deck exhausted 증가다.
- `late_guard_v2`는 smoke에서 v1보다 턴을 의미 있게 줄이지 못했다. 현재는 후보 보관만 한다.

현재 판단:

- 실무 후보는 `shop_slot_market_v2 + s1_soft_v2_late_guard_v1` 쪽으로 한 단계 가까워졌다.
- 아직 “완성된 레벨링 테이블”은 아니다. S6~S8 guard가 후반 고정 build를 막는 대신 턴을 늘리고 있으므로, 다음은 target curve보다 market tempo/후반 보상 품질 쪽에서 턴을 낮춰야 한다.
- 다음 실험은 보스 요구치를 더 올리는 방향이 아니라, 후반 시장에서 즉시 점수 전환 후보의 선택 확률을 높이고 장기 자원/덱 비대화 후보를 줄이는 방향으로 진행한다.

## v45~v46 Late market tempo 검증

v45~v46은 `s1_soft_v2_late_guard_v1`에서 후반 시장 선택 품질만 바꿔 평균 턴을 낮출 수 있는지 확인했다. 실제 UI, 저장 데이터, 실제 market catalog는 건드리지 않았다.

추가한 sim-only market profile:

- `shop_slot_market_v4`
  - S6~S8에서 Rare/Planet/Uncommon 즉시 점수 전환 후보를 더 강하게 고른다.
  - Pack/Tarot/Voucher 같은 장기 자원 후보 선택 점수를 더 낮춘다.
- `shop_slot_market_v5`
  - v4가 너무 강하면 승률/턴 중간값을 찾기 위한 완화 후보.

실험 파일:

- `logs/sim/ml_sweep_market_tempo_v46_r400_summary.json`
- `logs/sim/ml_sweep_market_tempo_v46_r400_report.md`
- `logs/sim/ml_sweep_market_tempo_v46_r400_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_market_tempo_v46_r400_summary_ml_insights_report.md`

v46 r400 progression route 평균:

| market | path clear | total turn | board lock stop | deck exhausted stop |
|---|---:|---:|---:|---:|
| `shop_slot_market_v2` | 64.8% | 1323.4 | 318 | 108 |
| `shop_slot_market_v4` | 70.3% | 1372.6 | 279 | 81 |
| `shop_slot_market_v5` | 65.2% | 1348.7 | 317 | 103 |

v46 r400 static guard:

| market / static loadout | path clear | total turn |
|---|---:|---:|
| `shop_slot_market_v2` / `s2_foundation_build` | 0.0% | 1120.6 |
| `shop_slot_market_v2` / `s3_hand_growth_build` | 0.0% | 1135.5 |
| `shop_slot_market_v2` / `s5_power_build` | 1.2% | 1325.2 |
| `shop_slot_market_v4` / `s2_foundation_build` | 0.0% | 1130.7 |
| `shop_slot_market_v4` / `s3_hand_growth_build` | 0.0% | 1107.2 |
| `shop_slot_market_v4` / `s5_power_build` | 0.0% | 1254.8 |
| `shop_slot_market_v5` / `s2_foundation_build` | 0.0% | 1125.8 |
| `shop_slot_market_v5` / `s3_hand_growth_build` | 0.0% | 1127.7 |
| `shop_slot_market_v5` / `s5_power_build` | 0.8% | 1308.4 |

해석:

- `shop_slot_market_v4`는 clear를 70.3%까지 올리고 board/deck stop도 줄였다. total turn은 1372.6으로 높지만, 추가 분해 결과 전투당 턴은 `v2`와 거의 같다.
- progression 평균 turn/attempted step:
  - `shop_slot_market_v2`: 68.4
  - `shop_slot_market_v4`: 68.2
  - `shop_slot_market_v5`: 68.4
- 즉 v4의 total turn 증가는 “한 전투가 늘어지는 현상”이라기보다 더 많은 step을 밟고 더 자주 완주해서 생긴 값이다.
- `shop_slot_market_v5`는 static guard는 유지하지만 clear가 v2와 거의 같고 total turn은 더 길어 애매하다.

현재 판단:

- `shop_slot_market_v4`는 탈락이 아니라 “강한 후보”로 재분류한다. 후반 재미/폭발감, static guard, board/deck stop 기준은 좋다.
- total turn만 보면 오판할 수 있으므로, sequence summary에 clear-only turn, failed-only turn, turn per attempted step, turn per cleared step을 직접 기록하도록 보강했다.
- 기준 proxy는 당장 `shop_slot_market_v2`로 유지하되, v4는 실제 후보군으로 계속 비교한다. 다음 작업은 보강된 summary metric으로 v4를 재측정하는 것이다.

## v47 Sequence tempo metric 재측정

v47은 v46 이후 추가한 sequence tempo metric으로 `shop_slot_market_v2`와 `shop_slot_market_v4`를 다시 비교했다. 실제 UI, 저장 데이터, 실제 market catalog는 건드리지 않았다.

추가된 sequence summary metric:

- `avg_clear_path_turn_count`
- `avg_failed_path_turn_count`
- `avg_turn_per_attempted_step`
- `avg_turn_per_cleared_step`

실험 파일:

- `logs/sim/ml_sweep_sequence_metric_v47_r400_summary.json`
- `logs/sim/ml_sweep_sequence_metric_v47_r400_report.md`
- `logs/sim/ml_sweep_sequence_metric_v47_r400_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_sequence_metric_v47_r400_summary_ml_insights_report.md`

v47 r400 progression route 평균:

| market | path clear | total turn | clear-path turn | failed-path turn | turn/attempt | turn/cleared | board lock stop | deck exhausted stop |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `shop_slot_market_v2` | 65.8% | 1348.7 | 1635.1 | 795.9 | 68.5 | 69.7 | 310 | 104 |
| `shop_slot_market_v4` | 67.8% | 1349.7 | 1629.5 | 761.5 | 68.3 | 69.4 | 299 | 92 |

v47 r400 static guard:

| market / static loadout | path clear | total turn | turn/attempt |
|---|---:|---:|---:|
| `shop_slot_market_v2` / `s2_foundation_build` | 0.0% | 1160.1 | 77.4 |
| `shop_slot_market_v2` / `s3_hand_growth_build` | 0.0% | 1135.4 | 72.5 |
| `shop_slot_market_v2` / `s5_power_build` | 0.8% | 1269.3 | 67.4 |
| `shop_slot_market_v4` / `s2_foundation_build` | 0.0% | 1136.7 | 77.1 |
| `shop_slot_market_v4` / `s3_hand_growth_build` | 0.0% | 1130.4 | 72.5 |
| `shop_slot_market_v4` / `s5_power_build` | 0.2% | 1301.1 | 67.8 |

해석:

- v47 기준에서는 `shop_slot_market_v4`가 v2보다 낫다.
- path clear는 +2.0%p이고, clear-path turn은 오히려 5.6 낮다.
- turn/attempt와 turn/cleared도 v4가 약간 낮다. 즉 v4는 전투를 늘어지게 하는 후보가 아니라, 더 잘 진행시키는 후보에 가깝다.
- board lock stop과 deck exhausted stop도 v4가 낮다.
- static guard도 유지된다. S2/S3 고정 build는 0%, S5 고정 build도 0.2%다.

현재 판단:

- 현재 실무 proxy 후보를 `s1_soft_v2_late_guard_v1 + shop_slot_market_v4`로 한 단계 승격한다.
- `shop_slot_market_v2`는 보수 기준선으로 남긴다.
- 다음 단계는 이 조합을 S1~S2, S3~S5, S6~S8 구간 기준으로 더 넓게 재검증하고, station별 target table 후보로 뽑을 수 있는지 본다.

## v48 In-game target 후보 재정의

v48부터 여기서 말하는 target은 단순 sweep 후보 점수가 아니라, 실제 인게임에 사용할 레벨링 목표 지점이다. 즉 “어느 station/tier에 어떤 목표 점수를 배치할지”, “그 목표표를 UI/상점/전투 구현 검토로 넘겨도 되는지”를 판단하기 위한 기준이다. 이번 단계도 실제 UI, 저장 데이터, 실제 market catalog는 건드리지 않았다.

실험 파일:

- `logs/sim/ml_sweep_target_curve_v48_r400_summary.json`
- `logs/sim/ml_sweep_target_curve_v48_r400_report.md`
- `logs/sim/ml_sweep_target_curve_v48_r400_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_target_curve_v48_r400_summary_ml_insights_report.md`

고정 조건:

- experiment base: `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1`
- market proxy: `shop_slot_market_v4`
- loadout:
  - progression: `progression_route_balanced`, `progression_route_sustain`, `progression_route_power`
  - static guard: `s2_foundation_build`, `s3_hand_growth_build`, `s5_power_build`
- sweep:
  - small multiplier: `1.00`, `1.05`, `1.10`
  - big multiplier: `0.95`, `1.00`, `1.05`
  - boss multiplier: `0.78`, `0.82`, `0.86`

v48 r400 주요 후보:

| candidate | progression clear | total turn | clear-path turn | failed-path turn | turn/attempt | S2 static | S3 static | S5 static | board lock stop | deck exhausted stop |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `small_1p05_big_1p05_boss_0p78` | 71.0% | 1317.6 | 1578.6 | 677.5 | 66.1 | 0.0% | 0.0% | 2.5% | 309 | 36 |
| `small_1p0_big_1p05_boss_0p86` | 68.3% | 1319.2 | 1599.1 | 719.4 | 67.0 | 0.0% | 0.0% | 0.5% | 330 | 45 |
| `small_1p05_big_1p05_boss_0p82` | 70.8% | 1349.4 | 1594.7 | 758.6 | 66.8 | 0.0% | 0.0% | 2.2% | 295 | 53 |
| `small_1p1_big_1p0_boss_0p78` | 72.4% | 1321.4 | 1574.7 | 655.4 | 66.0 | 0.0% | 0.0% | 3.0% | 280 | 47 |
| `small_1p0_big_0p95_boss_0p78` | 73.1% | 1290.1 | 1534.8 | 629.7 | 64.2 | 0.0% | 0.0% | 9.5% | 295 | 26 |
| `small_1p0_big_0p95_boss_0p82` | 74.9% | 1335.8 | 1549.8 | 696.1 | 64.8 | 0.0% | 0.0% | 7.8% | 270 | 29 |

해석:

- `small_1p0_big_0p95_*` 계열은 턴이 짧고 clear가 높지만 S5 static build 누수가 7~10%대로 커진다. “초반/중반 빌드가 후반을 그대로 밀면 안 된다”는 기준에는 맞지 않는다.
- `small_1p05_big_1p05_boss_0p78`은 progression clear 71.0%, total turn 1317.6으로 실무적으로 보기 좋다. 단점은 S5 static clear가 2.5%로 완전 차단은 아니다.
- `small_1p0_big_1p05_boss_0p86`은 progression clear가 68.3%로 낮지만 S5 static clear가 0.5%라 구간 성장 요구가 가장 선명하다. 대신 board/deck stop과 clear-path turn이 더 높다.
- `small_1p05_big_1p05_boss_0p82`는 중간값처럼 보이지만 total turn과 deck exhausted가 늘어난다.
- 현재 데이터 기준으로는 “조금은 잘 터지고 늘어지지 않는 방향”과 “이전 구간 빌드를 다음 구간에서 막는 방향”이 서로 충돌한다. 따라서 하나의 최적값보다 적용 목적별 후보를 나눠야 한다.

현재 판단:

- UI 적용 검토용 1순위 후보는 `small_1p05_big_1p05_boss_0p78 + shop_slot_market_v4`다.
  - 초반 재미와 전체 진행률을 확보하면서 total turn을 낮춘다.
  - S5 static 누수 2.5%는 실제 상점 후보 가중치/후반 boss 제약 표시/보상 템포를 함께 설계할 때 다시 막아야 할 위험으로 둔다.
- 성장 구간 차단을 더 중시하는 보수 후보는 `small_1p0_big_1p05_boss_0p86 + shop_slot_market_v4`다.
  - S5 static 누수가 0.5%로 낮다.
  - 대신 전체 clear와 stop reason이 나빠져, 실제 게임 초안으로는 다소 빡빡할 수 있다.
- 아직 실제 구현으로 옮기지 않는다. 다음 기준을 만족하면 “실제 UI/상점/전투 구현 검토” 단계로 전환한다.
  - 레벨 목표표 후보가 S1~S8 small/big/boss 전체에 대해 한 세트로 고정된다.
  - 마켓 후보는 고정 지급이 아니라 station/tier별 unlock pool + weighted roll 형태로 정리된다.
  - S1~S2 전법은 S3 boss 전후에서 한계가 오고, S3~S5 전법은 S6~S8에서 다시 성장을 요구한다.
  - 늘어짐 방지 기준은 total turn만 보지 않고 `turn/attempt`, `clear-path turn`, `failed-path turn`, board/deck stop을 함께 본다.

## v49 Finalist seed 안정성 확인

v49는 v48의 주요 후보 4개만 r800으로 다시 돌려 seed 안정성을 봤다. 목표는 “실제 UI 적용 검토 후보”를 숫자로 좁히는 것이다. 이번 단계도 실제 UI, 저장 데이터, 실제 market catalog는 건드리지 않았다.

실험 파일:

- `logs/sim/ml_sweep_target_curve_v49_r800_summary.json`
- `logs/sim/ml_sweep_target_curve_v49_r800_report.md`
- `logs/sim/ml_sweep_target_curve_v49_r800_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_target_curve_v49_r800_summary_ml_insights_report.md`

v49 r800 결과:

| candidate | progression clear | total turn | clear-path turn | failed-path turn | turn/attempt | S2 static | S3 static | S5 static | board lock stop | deck exhausted stop |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `small_1p05_big_1p05_boss_0p78` | 72.7% | 1339.0 | 1577.8 | 702.8 | 66.1 | 0.0% | 0.0% | 3.1% | 565 | 84 |
| `small_1p05_big_1p05_boss_0p86` | 68.2% | 1329.6 | 1611.7 | 724.5 | 67.5 | 0.0% | 0.0% | 1.3% | 654 | 104 |
| `small_1p0_big_1p05_boss_0p78` | 72.9% | 1336.6 | 1566.0 | 720.4 | 65.5 | 0.0% | 0.0% | 5.0% | 563 | 79 |
| `small_1p0_big_1p05_boss_0p86` | 69.5% | 1315.0 | 1594.6 | 680.9 | 66.8 | 0.0% | 0.0% | 2.6% | 644 | 83 |

해석:

- v48에서 보수 후보로 보였던 `small_1p0_big_1p05_boss_0p86`은 r800에서 S5 static clear가 2.6%까지 올라갔다. 완전 차단 후보로 보기 어렵다.
- `small_1p05_big_1p05_boss_0p78`은 r800에서도 clear와 turn이 안정적이다. 다만 S5 static clear가 3.1%라 후반 누수 위험은 남는다.
- `small_1p05_big_1p05_boss_0p86`은 S5 static clear가 1.3%로 가장 낮지만, progression clear 68.2%, board/deck stop 654/104로 플레이 감각이 빡빡해질 가능성이 크다.
- `small_1p0_big_1p05_boss_0p78`은 turn/attempt가 가장 낮지만 S5 static 누수 5.0%라 실제 레벨링 후보로는 위험하다.

현재 판단:

- UI 적용 검토 1순위는 계속 `small_1p05_big_1p05_boss_0p78 + shop_slot_market_v4`다.
- 단, 이 후보는 “완성”이 아니라 “초안 후보”다. S5 static 누수 3%대를 실제 구현에서 그대로 두면 중반 빌드가 후반을 일부 밀 수 있다.
- 다음 작업은 boss target을 더 올리는 것이 아니라, S6~S8 boss 제약/market unlock pool 쪽에서 S5 static 누수를 막는 것이다.
  - 목표 점수표는 너무 빡빡하게 올리면 턴과 고갈이 다시 나빠진다.
  - 후반 진입 후에는 강한 후보가 더 잘 나오되, 이전 구간 build만 들고 온 경우에는 boss 제약에 걸리도록 해야 한다.
- “실제 UI 적용 시점”은 아직 아니다. 다음에는 이 후보를 기준으로 실제 상점에 필요한 unlock band/weighted roll 설계안을 sim-only 데이터 형태로 먼저 만든다.

## v50 Late market guard 후보

v50은 `small_1p05_big_1p05_boss_0p78` 목표표를 유지한 상태에서 `shop_slot_market_v4`와 신규 sim-only `shop_slot_market_v6`를 비교했다. `v6`는 실제 상점 구현이 아니라, S6~S8에서 강한 Rare/Legendary/Planet류 후보가 “성장 경로를 밟은 loadout”에는 유지되고, 고정 단일 build에는 덜 붙도록 만든 unlock/weight proxy다.

실험 파일:

- `logs/sim/ml_sweep_market_guard_v50_r400_summary.json`
- `logs/sim/ml_sweep_market_guard_v50_r400_report.md`
- `logs/sim/ml_sweep_market_guard_v50_r400_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_market_guard_v50_r400_summary_ml_insights_report.md`

v50 r400 결과:

| market | progression clear | total turn | clear-path turn | failed-path turn | turn/attempt | S2 static | S3 static | S5 static | board lock stop | deck exhausted stop |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `shop_slot_market_v4` | 69.5% | 1307.6 | 1575.1 | 696.2 | 66.0 | 0.0% | 0.0% | 4.8% | 310 | 51 |
| `shop_slot_market_v6` | 72.3% | 1329.7 | 1574.7 | 698.0 | 66.0 | 0.0% | 0.0% | 3.7% | 297 | 36 |

해석:

- `shop_slot_market_v6`는 기대한 방향으로 움직였다. progression clear는 높아지고 board/deck stop은 줄었으며 S5 static 누수도 4.8%에서 3.7%로 낮아졌다.
- 하지만 S5 static clear가 아직 3%대라 “구간 성장을 확실히 요구한다”는 기준에는 부족하다.
- 목표 점수표를 더 올리면 turn/stop이 악화될 가능성이 높으므로, 다음 보강은 점수표가 아니라 후반 boss 제약과 unlock 조건 proxy를 더 정교하게 나누는 쪽이 맞다.

현재 판단:

- 현재 실무 초안 후보는 `small_1p05_big_1p05_boss_0p78 + shop_slot_market_v6`로 교체한다.
- 이 후보는 UI 적용 후보가 아니라 “UI 적용 검토 전 최종 sim 후보”에 가깝다.
- 다음 기준:
  - S5 static 누수를 1~2%대로 낮춘다.
  - progression clear는 70% 전후를 유지한다.
  - turn/attempt는 66~67 범위를 넘지 않는다.
  - board/deck stop은 v50 v6보다 악화시키지 않는다.

## v51 Late market guard 강화

v51은 `shop_slot_market_v6`를 보존하고, 더 강한 후반 unlock proxy인 `shop_slot_market_v7`을 추가 비교했다. v7은 S6~S8에서 고정 단일 build가 Rare/Legendary/Planet류 강한 후보를 집어 후반을 미는 확률을 더 낮춘다. progression route에는 같은 late tempo bias를 유지한다.

실험 파일:

- `logs/sim/ml_sweep_market_guard_v51_r400_summary.json`
- `logs/sim/ml_sweep_market_guard_v51_r400_report.md`
- `logs/sim/ml_sweep_market_guard_v51_r400_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_market_guard_v51_r400_summary_ml_insights_report.md`

v51 r400 결과:

| market | progression clear | total turn | clear-path turn | failed-path turn | turn/attempt | S2 static | S3 static | S5 static | board lock stop | deck exhausted stop |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `shop_slot_market_v6` | 74.4% | 1371.6 | 1578.6 | 771.2 | 66.1 | 0.0% | 0.0% | 3.0% | 264 | 39 |
| `shop_slot_market_v7` | 72.2% | 1341.9 | 1576.9 | 735.2 | 66.1 | 0.0% | 0.0% | 0.3% | 279 | 50 |

해석:

- v7은 S5 static 누수를 0.3%까지 낮췄다. “이전 구간 build가 후반을 그대로 밀면 안 된다”는 기준에 가장 가깝다.
- progression clear는 72.2%로 유지되고, turn/attempt도 66.1로 v6와 같다.
- board/deck stop은 v6보다 조금 나쁘지만, v50 v4/v6와 비교하면 아직 허용 범위다.
- v6는 clear가 더 높지만 S5 static 누수가 계속 3%대다. 실무 레벨링 목표로는 v7 쪽이 더 맞다.

현재 판단:

- 현재 UI 적용 검토 전 최종 sim 후보는 `small_1p05_big_1p05_boss_0p78 + shop_slot_market_v7`이다.
- 아직 실제 구현으로 옮기지 않는다. v7은 실제 상점 정책이 아니라 unlock/weight 방향을 검증하기 위한 sim-only proxy다.
- 다음은 v7을 r800 이상으로 재검증하고, 결과가 유지되면 이 조합을 기준으로 S1~S8 small/big/boss 목표표와 station별 unlock band 초안을 작성한다.

## v52 Final sim 후보 r800 확인

v52는 v51의 후보인 `small_1p05_big_1p05_boss_0p78 + shop_slot_market_v7`을 r800으로 단독 재검증했다. 이번 단계도 실제 UI, 저장 데이터, 실제 market catalog는 건드리지 않았다.

실험 파일:

- `logs/sim/ml_sweep_market_guard_v52_r800_summary.json`
- `logs/sim/ml_sweep_market_guard_v52_r800_report.md`
- `logs/sim/ml_sweep_market_guard_v52_r800_summary_bottleneck_report.md`
- `logs/sim/ml_sweep_market_guard_v52_r800_summary_ml_insights_report.md`

v52 r800 결과:

| market | progression clear | total turn | clear-path turn | failed-path turn | turn/attempt | S2 static | S3 static | S5 static | board lock stop | deck exhausted stop |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `shop_slot_market_v7` | 70.5% | 1313.5 | 1576.8 | 687.8 | 66.1 | 0.0% | 0.0% | 0.1% | 616 | 82 |

해석:

- r800에서도 S5 static clear가 0.1%로 유지됐다. 고정 S5 빌드가 후반을 거의 밀지 못한다.
- progression clear 70.5%는 목표 범위에 들어온다.
- total turn 1313.5, turn/attempt 66.1로 늘어짐 방지 기준도 유지된다.
- board/deck stop은 v51 r400보다 높게 보이지만, r800 기준으로도 v47~v49의 후보군과 비교하면 허용 가능한 범위다. 다음 단계에서 stop reason을 줄이는 보강은 점수표가 아니라 보스 제약 표시/후반 unlock pool 품질로 처리해야 한다.

현재 판단:

- 현재 sim 기준 최종 후보:
  - target curve: `small_1p05_big_1p05_boss_0p78`
  - base experiment: `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1`
  - market proxy: `shop_slot_market_v7`
- 이 후보는 “실제 구현 시작”이 아니라 “실제 구현 검토로 넘길 수 있는 수치 기준”이다.
- 실제 UI/상점/전투로 옮기기 전에 필요한 산출물:
  - S1~S8 small/big/boss 목표 점수표
  - station/tier별 후보 unlock band
  - weighted roll 확률표
  - boss 제약 표시/룰 텍스트 초안
  - 실제 저장 데이터에 넣지 않을 transient/sim-only 필드 분리안

## v53 Implementation review 산출물 초안

v53은 v52 후보를 실제 구현 검토로 넘기기 전에 필요한 숫자 표와 정책 초안을 정리한다. 아직 실제 UI, 저장 데이터, 실제 market catalog에는 반영하지 않는다.

현재 기준 조합:

- target curve: `small_1p05_big_1p05_boss_0p78`
- base experiment: `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1`
- market proxy: `shop_slot_market_v7`

S1~S8 target score 후보:

| station | small | big | boss |
|---|---:|---:|---:|
| S1 | 257 | 284 | 225 |
| S2 | 372 | 431 | 439 |
| S3 | 463 | 537 | 547 |
| S4 | 580 | 672 | 685 |
| S5 | 725 | 841 | 857 |
| S6 | 923 | 1112 | 915 |
| S7 | 1154 | 1391 | 1524 |
| S8 | 1441 | 1738 | 1905 |

해석:

- S1은 진입용이다. boss target이 small/big보다 낮다. 초반 boss를 벽이 아니라 “첫 변주”로 두기 위한 의도다.
- S2~S5는 small/big/boss가 완만하게 오른다. 중반까지는 특정 한 방보다 build 안정성을 보게 한다.
- S6부터는 late guard가 걸린다. S6 boss target 자체는 낮아 보이지만 boss constraint proxy가 붙어, 이전 build가 단순 점수만으로 넘는 구조를 막는다.
- S7~S8은 최종 build 검증 구간이다. target score와 boss constraint가 같이 작동해야 한다.

현재 boss constraint proxy:

| station | boss constraint id | family | source |
|---|---|---|---|
| S6 | `confirm_count_tax_v2` | confirm count tax | The Needle one hand only |
| S7 | `all_score_dampener` | base score and mult weaken | The Flint base chips and mult reduced |
| S8 | `first_confirm_tax` | forced selection or opening tax | The Hook / forced selection pressure proxy |

실제 구현 전환 시 명칭:

- Balatro 치환 후보군: `Rummi Relic Proxy Pool`
  - Jester, Planet, Tarot, Voucher를 우리 규칙으로 바꾼 sim-only 후보군을 가리킨다.
  - 실제 게임 catalog가 아니라 ML/시뮬용 설계 후보라는 뜻을 유지한다.
- Balatro 보스 제약 치환군: `Rummi Boss Constraint Proxy Pool`
  - 원본 boss blind를 복제하지 않고, 우리 보드/족보/확정/덱 고갈 구조로 바꾼 제약 후보군이다.

station/tier별 unlock band 초안:

| band | station | 목적 | 후보군 방향 |
|---|---|---|---|
| early | S1~S2 | 초반 재미와 첫 build 방향 제시 | Common Jester, 낮은 Tarot/Pack, 낮은 Planet, 아주 낮은 Rare |
| mid | S3~S5 | 초반 전법의 한계와 중반 성장 요구 | Uncommon Jester, Tarot shape fix, Planet rank level, Pack 보강, 낮은 Rare |
| late | S6~S8 | 완성 build 검증과 후반 폭발감 | Rare/Planet/강한 Jester 가능, 단 고정 S5 build에는 강한 후보 weight 제한 |

weighted roll 방향:

- Common Jester는 early에서 높고 late에서 낮춘다.
- Tarot/Pack은 early~mid에서 shape fix와 덱 압박 완화용으로 유지한다.
- Planet은 mid부터 의미 있게 나오고, late에서는 progression build가 점수 전환을 할 때 더 유리하게 둔다.
- Rare/Legendary는 early에서도 0으로 막지 않는다. 단 late static build가 후반을 밀어버리는 경우에는 weight를 강하게 낮춘다.
- Voucher는 낮은 확률로 유지하되, 실제 저장 구조를 바꾸는 효과는 아직 금지한다. sim에서는 resource/profile proxy로만 둔다.

v7 observed roll 방향성 샘플:

| route | band | 주요 resolved profile 분포 |
|---|---|---|
| progression | early | Common color 58.8%, Common rank 23.7%, Tarot 8.1%, Uncommon 5.1%, Rare 0.2% |
| progression | mid | Uncommon 66.2%, Planet 19.1%, Tarot 9.3%, Build-aware Pack 1.7%, Rare 0.4% |
| progression | late | Rare 54.1%, Uncommon 37.2%, Planet 8.4%, Common color 0.3% |
| S5 static | early | Common rank 52.1%, Common color 26.3%, Tarot 14.1%, Rare 2.0% |
| S5 static | mid | Uncommon 52.1%, Tarot 34.8%, Build-aware Pack 8.6%, Planet 2.3%, Rare 0.3% |
| S5 static | late | Common rank 68.8%, Uncommon 25.2%, Tarot 3.1%, Common color 2.8%, Discard glove 0.1% |

해석:

- progression route는 late에 Rare/Uncommon/Planet으로 실제 점수 전환을 받는다.
- S5 static route는 late에 Rare/Planet이 사실상 막히고 Common/Uncommon 중심으로 남는다.
- 따라서 v7은 “고정 지급”이 아니라 “같은 station이라도 성장 상태에 따라 후보 weight가 달라지는 상점”의 수치 해석으로 사용할 수 있다.

실제 UI 적용 전 필수 확인:

- `shop_slot_market_v7`의 “progression route 우대 / static build 억제”는 현재 sim loadout id 기반이다. 실제 구현에서는 loadout id가 아니라 보유 Jester/Item, 최근 구매, station 진입 상태, boss constraint 대응 가능성으로 판정해야 한다.
- S6~S8 boss constraint는 UI에서 작은 아이콘만으로 표시하면 안 된다. 점수 영향이 즉시 읽히는 각진 배지와 높은 대비가 필요하다.
- market roll은 고정 지급이 아니다. station/tier별 unlock pool에서 확률로 뜨고, bot/player가 선택하는 구조여야 한다.
- 저장 데이터에는 `market_profile`, `resolved_market_profile`, `simulated` 같은 sim-only 필드를 그대로 넣지 않는다.

## v54 실제 구현 접점 검토

현재 실제 코드 기준으로 v52 후보를 바로 넣으면 재현되지 않는 부분이 있다. 이 단계는 구현 검토이며, 아직 실제 UI/저장/상점/전투 코드는 변경하지 않는다.

현재 실제 구조:

- 목표 점수:
  - `BlindSelectionSpecBuilder._baseTargetForStation`은 station growth `1.6`을 사용한다.
  - v52 후보는 sim에서 station growth `1.25`와 별도 small/big/boss multiplier를 사용한다.
  - 따라서 실제 적용 시 `BlindSelectionSpecBuilder`에 v52 target table 또는 curve profile이 들어가야 한다.
- 보스 제약:
  - 실제 `RummiBossModifier`는 현재 `red_dampener_v1`, `row_line_dampener_v1` 중심이다.
  - v52의 `confirm_count_tax_v2`, `all_score_dampener`, `first_confirm_tax`는 아직 sim-only boss constraint다.
  - 실제 적용하려면 `RummiBossModifierCategory`를 확장하거나, boss constraint runtime을 modifier와 분리해야 한다.
- 상점:
  - 실제 Jester offer는 `RummiRunProgress._generateOffers`에서 rarity weight만으로 뽑는다.
  - 실제 rarity weight는 station에 따라 Common이 줄고 Rare/Legendary가 조금 늘지만, v7처럼 progression/static 상태를 구분하지 않는다.
  - Item offer는 `RummiMarketRuntimeFacade._buildItemOffers`에서 catalog 순환/소모 상태 기반이다.
  - 따라서 v52 market을 옮기려면 “offer pool builder + weighted roll policy”를 별도 도입해야 한다.
- 저장:
  - 실제 저장은 `ActiveRunRuntimeState`, `RummiRunProgress`, `RummiPokerGridSession`이 기준이다.
  - sim-only `market_profile`, `resolved_market_profile`, `simulated` 필드는 저장에 넣으면 안 된다.

실제 구현 가능성 판단:

- target score table 적용: 가능. `BlindSelectionSpecBuilder` 쪽에서 가장 작고 명확하게 시작할 수 있다.
- market weighted roll 적용: 가능하지만 바로 catalog에 섞으면 위험하다. 먼저 `RummiMarketOfferPolicy` 같은 순수 정책 객체로 분리한 뒤, 기존 `_generateOffers`가 이를 호출하게 해야 한다.
- boss constraint 적용: 가능하지만 가장 위험하다. 현재 UI/전투 표시/점수 계산이 `RummiBossModifier`의 단순 multiplier 전제에 맞춰져 있으므로, v52 boss proxy를 넣으려면 전투 점수 계산과 표시를 함께 설계해야 한다.
- UI 적용 시점: 아직 아님. 먼저 target table과 market policy를 실제 런타임 구조로 옮길 수 있는 작은 설계 패치를 준비하고, boss constraint는 별도 단계로 분리해야 한다.

권장 적용 순서:

1. `BlindSelectionSpecBuilder`에 v52 target table/curve profile을 sim과 동일하게 재현하는 테스트를 먼저 추가한다.
2. 실제 상점에 넣기 전, `RummiMarketOfferPolicy` 순수 함수로 station/tier/build-state별 weighted roll을 만든다.
3. 현재 Jester offer와 Item offer를 한 번에 합치지 말고, Jester policy부터 적용한다.
4. Boss constraint는 `RummiBossModifier` 확장 전에 UI 표시와 점수 계산 계약을 먼저 정한다.
5. 위 1~2가 테스트로 고정되면 그때 실제 UI/상점/전투 적용 여부를 판단한다.

## v55 Ordered Boss 재검증

사용자 지적대로 v53의 target score 후보는 실제 Blind 계층 규칙에 어긋난다.

- S1: small `257`, big `284`, boss `225`
- S6: small `923`, big `1112`, boss `915`

시뮬 후보로는 “보스 제약이 붙으니 목표 점수 자체는 낮출 수 있다”는 해석이 가능했지만, 실제 게임 규칙에서는 `small < big < boss`가 항상 유지되어야 한다. 따라서 v53 target table은 실제 구현 후보에서 보류한다.

이번 v55는 실제 런타임 적용이 아니라 sim-only 후보다.

- experiment: `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_ordered_boss_v1`
- market: `shop_slot_market_v7`
- loadout route: `progression_route_power`
- runs: `800`
- summary-only

ordered boss rule:

- 같은 station의 boss target이 big target 이하로 내려가면 `big + 1`로 보정한다.
- 기존 후보값을 최대한 유지하고, 순서가 깨지는 S1/S6 같은 구간만 최소 보정한다.
- 실제 런타임에는 아직 반영하지 않는다.

보정 후 주요 boss target:

| station | raw boss | ordered boss | 이유 |
|---|---:|---:|---|
| S1 | 225 | 285 | S1 big 284보다 높게 보정 |
| S6 | 915 | 1113 | S6 big 1112보다 높게 보정 |

보스 제약 전체 타입 검증:

S1~S10 boss를 한 번씩 돌려 `Rummi Boss Constraint Proxy Pool` 10종이 모두 노출되는지 확인했다.

| station | boss target | raw boss target | boss proxy |
|---|---:|---:|---|
| S1 | 285 | 225 | `color_dampener_cycle` |
| S2 | 439 | 439 | `line_kind_dampener_cycle` |
| S3 | 547 | 547 | `face_tile_dampener` |
| S4 | 685 | 685 | `repeat_rank_pressure_v4` |
| S5 | 857 | 857 | `single_rank_pressure` |
| S6 | 1113 | 915 | `confirm_count_tax_v2` |
| S7 | 1524 | 1524 | `all_score_dampener` |
| S8 | 1905 | 1905 | `first_confirm_tax` |
| S9 | 2720 | 2720 | `target_spike_wall` |
| S10 | 2616 | 2616 | `resource_squeeze` |

S1~S8 비교 결과:

| metric | v52 기준 | v55 ordered boss S1~S8 |
|---|---:|---:|
| path clear | 70.5% | 59.4% |
| avg total turn | 1313.5 | 1153.3 |
| clear-path turn | 1576.8 | 1573.6 |
| failed-path turn | 687.8 | 539.1 |
| turn per attempted step | 66.1 | 66.3 |
| 주요 실패 | board lock 616, deck exhausted 82 | board lock 174, deck exhausted 146 |

S1~S10 전체 보스 타입 포함 결과:

| metric | value |
|---|---:|
| path clear | 13.9% |
| avg total turn | 1405.3 |
| clear-path turn | 2122.0 |
| failed-path turn | 1289.9 |
| turn per attempted step | 69.9 |

S1~S10 주요 실패:

| bottleneck | count |
|---|---:|
| S1 boss | 146 |
| S9 boss | 139 |
| S10 boss | 102 |
| S10 big | 72 |
| S1 big | 32 |
| S9 big | 21 |
| S8 boss | 20 |
| S1 small | 19 |
| S7 boss | 17 |

해석:

- `small < big < boss` 규칙을 적용하면 S1/S6 완화가 줄어 path clear가 70.5%에서 59.4%로 떨어진다.
- 대신 평균 총 턴은 줄어든다. 실패가 더 빨리 발생하기 때문이다.
- 이 상태로 실제 UI/상점에 넘기면 안 된다. 초반 재미와 진행 안정성이 부족하다.
- S1 boss는 여전히 가장 큰 early 병목이다. 단, boss target을 big보다 낮추는 방식은 폐기한다.
- S9/S10을 포함하면 최종 구간은 아직 과도하게 막힌다. 전체 10 boss type pool을 쓰려면 S9~S10 전용 late reward/market 확장 또는 target 완화가 필요하다.

다음 방향:

1. `ordered_boss_v1`을 기준으로 유지한다.
2. S1 boss는 target을 낮추지 말고, 시작 build 보상/초기 market 선택 품질/초반 resource로 푼다.
3. S6 이후는 boss target을 낮추기보다 late market 후보와 boss 대응 build를 강화한다.
4. S9~S10은 “전체 boss type pool 검증용 확장 구간”으로 보고, 실제 적용 레벨 범위에 넣을지 별도 결정한다.
5. 실제 런타임 적용은 다시 보류한다. 먼저 ordered boss 기준으로 target/market 재시뮬을 더 돌린다.

## v56 통합 Weighted Boss Pool 레벨링 데이터 후보

목표:

- 룰 치환 후보(`Rummi Relic Proxy Pool`)
- 시장 후보(`shop_slot_market_v7`)
- 보스 제약 치환 세트(`Rummi Boss Constraint Proxy Pool`)

위 세 축을 모두 얹은 상태에서 S1~S8 전체 경로 레벨링 데이터를 다시 만든다.

작업 체크리스트:

- [x] 실제 런타임 target table 적용 보류
- [x] 보스 고정 순환 대신 `early/mid/late/final weighted boss pool` 추가
- [x] summary group에 `sim_boss_constraint_id`를 남겨 보스 proxy별 병목을 볼 수 있게 함
- [x] `shop_slot_market_v7`과 함께 S1~S8 통합 sweep 실행
- [x] bottleneck / ML insight report 생성
- [ ] 다음 후보 재시뮬: S1 boss 완화는 target 역전이 아니라 초반 보상/시장 품질로 해결

실험 설정:

- experiment: `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_weighted_boss_v1`
- market: `shop_slot_market_v7`
- loadout route: `progression_route_power`
- stations: `1,2,3,4,5,6,7,8`
- bot: `planner_v2`
- runs: `800`
- summary-only

산출물:

- summary: `logs/sim/ml_sweep_integrated_weighted_boss_v56_s8_r800_summary.json`
- report: `logs/sim/ml_sweep_integrated_weighted_boss_v56_s8_r800_report.md`
- bottleneck: `logs/sim/ml_sweep_integrated_weighted_boss_v56_s8_r800_summary_bottleneck_report.md`
- ML insight: `logs/sim/ml_sweep_integrated_weighted_boss_v56_s8_r800_summary_ml_insights_report.md`

Weighted boss pool 설계:

| band | station | 높은 weight | 낮은 확률 후보 |
|---|---|---|---|
| early | S1~S2 | color/line/face/resource/first confirm | repeat, confirm tax |
| mid | S3~S5 | repeat/single/confirm/all-score/face | target spike, resource, color/line |
| late | S6~S7 | confirm/all-score/target/resource/repeat | first confirm, single, face |
| final | S8 | target spike/all-score/resource/confirm | first confirm, repeat, single, face |

S1~S8 path 결과:

| metric | value |
|---|---:|
| path clear | 60.0% |
| clear count | 480 / 800 |
| avg total turn | 1255.8 |
| clear-path turn | 1577.7 |
| failed-path turn | 773.0 |
| turn per attempted step | 66.2 |
| turn per cleared step | 67.6 |

주요 실패:

| bottleneck | count |
|---|---:|
| S1 boss | 72 |
| S8 boss | 60 |
| S1 big | 24 |
| S8 big | 19 |
| S2 big | 18 |
| S1 small | 16 |
| S7 boss | 14 |
| S3 big | 13 |
| S3 boss | 12 |
| S2 boss | 10 |

실패 stop reason:

| stop reason | count |
|---|---:|
| boardFullAfterDcExhausted | 195 |
| drawPileExhausted | 119 |
| drawPileExhausted + boardFullAfterDcExhausted | 6 |

보스 proxy별 aggregate:

| boss proxy | runs | clear | avg turn | 주요 실패 |
|---|---:|---:|---:|---|
| `confirm_count_tax_v2` | 652 | 96.8% | 74.8 | board 7, deck 14 |
| `repeat_rank_pressure_v4` | 629 | 98.3% | 68.9 | board 6, deck 5 |
| `all_score_dampener` | 549 | 97.4% | 72.1 | board 7, deck 7 |
| `face_tile_dampener` | 529 | 97.5% | 70.8 | board 11, deck 2 |
| `color_dampener_cycle` | 498 | 90.4% | 79.1 | board 13, deck 35 |
| `first_confirm_tax` | 453 | 98.7% | 71.0 | board 5, deck 1 |
| `single_rank_pressure` | 452 | 98.2% | 69.6 | board 4, deck 4 |
| `line_kind_dampener_cycle` | 423 | 96.2% | 72.3 | board 12, deck 4 |
| `resource_squeeze` | 406 | 96.6% | 73.8 | board 7, deck 7 |
| `target_spike_wall` | 389 | 92.0% | 84.2 | board 3, deck 28 |

station + boss proxy 최악 조합:

| station | boss proxy | runs | clear | avg turn | 해석 |
|---|---|---:|---:|---:|---|
| S8 | `target_spike_wall` | 134 | 79.9% | 100.4 | 최종 목표 점수 압박이 deck 고갈을 유발 |
| S1 | `color_dampener_cycle` | 240 | 81.7% | 92.2 | 초반 색상 약화가 첫 build 전 덱 고갈을 유발 |
| S8 | `single_rank_pressure` | 24 | 83.3% | 89.3 | 표본은 적지만 final band에서 특정 족보 압박이 강함 |
| S8 | `confirm_count_tax_v2` | 88 | 87.5% | 97.4 | 후반 확정 횟수 tax가 deck 고갈로 이어짐 |
| S8 | `resource_squeeze` | 95 | 90.5% | 91.5 | 후반 자원 압박은 다소 강함 |

v55 ordered boss와 비교:

| metric | ordered fixed S1~S8 | weighted boss S1~S8 |
|---|---:|---:|
| path clear | 59.4% | 60.0% |
| avg total turn | 1153.3 | 1255.8 |
| clear-path turn | 1573.6 | 1577.7 |
| failed-path turn | 539.1 | 773.0 |
| turn per attempted step | 66.3 | 66.2 |

해석:

- weighted boss pool은 fixed ordered보다 path clear를 크게 올리지는 못했다.
- 그러나 실패가 S1/S8에 더 명확히 드러났다. 즉 보스 전체 pool을 넣은 상태에서 실제 병목 위치를 보는 데이터로는 v56이 더 유효하다.
- S1 boss는 target을 낮춰 해결하면 `small < big < boss` 규칙을 깨므로 폐기한다.
- S1은 초반 market 선택 품질, 시작 보상, 초기 resource로 보완해야 한다.
- S8은 `target_spike_wall`, `confirm_count_tax_v2`, `resource_squeeze`가 deck 고갈을 만든다. final band의 강한 보스 weight를 낮추거나 late market에서 대응 후보 weight를 올려야 한다.

다음 순차 작업:

1. `shop_slot_market_v8` 후보를 만든다.
   - S1 boss 이전/직후의 초반 shape fix, resource, common build 후보 선택 품질을 강화한다.
   - Rare/Legendary 확률은 0으로 막지 않는다.
2. final band에서 `target_spike_wall` weight를 조금 낮춘다.
3. S1~S8 800 runs를 다시 돌려 v56과 비교한다.
4. path clear가 65~70% 근처로 회복되고, 실패 turn이 과도하게 늘지 않으면 실제 구현 검토로 다시 넘긴다.

## 통합 레벨링 실무 전환 체크리스트

이 체크리스트는 “룰 치환 후보 + 시장 후보 + 보스 제약 proxy”를 모두 얹은 뒤, 실제 UI/상점/전투 구현으로 넘길 수 있는 레벨링 기준점을 만들기 위한 작업 목록이다.

용어:

- `Rummi Relic Proxy Pool`: Balatro의 Joker/Jester, Voucher, Planet, Tarot 계열을 우리 게임의 색상, 숫자, 족보, 자원, 덱 압박 규칙으로 치환한 시뮬 전용 효과 후보.
- `Rummi Market Candidate Pool`: 실제 상점 카탈로그가 아니라 시뮬에서만 사용하는 등장 후보와 확률 profile. 예: `shop_slot_market_v7`, 다음 후보 `shop_slot_market_v8`.
- `Rummi Boss Constraint Proxy Pool`: Balatro 보스 제약을 우리 게임의 점수 감쇠, 색상/라인 압박, 반복 rank 압박, confirm tax, 자원 압박 등으로 치환한 시뮬 전용 보스 제약 세트.
- `Integrated Leveling Sweep`: 위 세 pool을 함께 적용하고 S1~S8 small/big/boss 전체 경로를 돌려 실제 게임 적용 가능성을 판단하는 sweep.

현재 완료:

- [x] 실제 런타임 UI, 저장 데이터, 실제 마켓 구조는 건드리지 않는다.
- [x] 실제 점수표 적용은 보류하고 시뮬 전용 experiment로만 검증한다.
- [x] `Rummi Relic Proxy Pool`과 `Rummi Market Candidate Pool`을 함께 쓰는 S1~S8 sweep 경로를 확보했다.
- [x] `Rummi Boss Constraint Proxy Pool`을 fixed order가 아니라 early/mid/late/final weighted pool로 돌릴 수 있게 했다.
- [x] summary row/group에 `sim_boss_constraint_id`를 기록해 어떤 보스 proxy가 병목인지 볼 수 있게 했다.
- [x] v56에서 `shop_slot_market_v7` + weighted boss pool + S1~S8 800 runs 통합 sweep을 완료했다.
- [x] v56 병목은 S1 boss와 S8 boss이며, S1은 초반 market 품질 문제, S8은 `target_spike_wall`/confirm/resource 압박 문제로 해석했다.

진행 중 / 다음 작업:

- [x] `shop_slot_market_v8`을 시뮬 전용으로 만든다.
- [x] S1~S2 구간에서 shape fix, resource, common build 후보의 등장/선택 품질을 올린다.
- [x] Rare/Legendary/강한 Rare 후보는 초반 확률을 0으로 막지 않고 낮은 확률로 유지한다.
- [x] final band의 `target_spike_wall` weight를 낮춘 weighted boss 후보를 만든다.
- [x] S1~S8, 800 runs, `progression_route_power`, weighted boss + `shop_slot_market_v8` 조합으로 v57 sweep을 실행한다.
- [x] v57 결과를 v56과 비교한다.
- [x] 기준을 만족하지 않으면 market weight 또는 boss weight만 조정하고 다시 sweep한다.
- [x] path clear 65~70% 근처, 실패 turn 과증가 없음, small/big/boss 병목이 특정 한 곳에 과집중하지 않는지 확인한다.
- [x] 기준을 만족하면 “실제 구현 검토 가능”으로 표시하되, 바로 UI/저장/실제 마켓에 적용하지 않고 별도 승인 후 진행한다.

추가 완료:

- [x] v57에서 `shop_slot_market_v8` + weighted boss v2를 검증했다.
- [x] v58에서 early/final boss weight를 v3로 재조정했다.
- [x] v59에서 S1 시작 자원 보정을 시뮬 전용으로 추가했다.
- [x] v60에서 `shop_slot_market_v9` late breaker 후보를 추가했다.
- [x] v61에서 v60 후보를 1600 runs로 재검증했다.

작업 중 추가/삭제 규칙:

- 새 병목이 발견되면 이 체크리스트에 항목을 추가하고, 해결되면 체크한다.
- 결과가 약한 후보도 삭제하지 않는다. 실제 게임에는 강한 효과와 약한 효과가 함께 있어야 덱 빌드 파생이 생긴다.
- 단, 복사/파괴/판매/렌탈/이터널/네거티브, 도감/해금 전제, 저장 구조 변경 필요, 현재 족보와 직접 맞지 않는 후보는 통합 sweep 후보에서 제외한다.
- 보스 target은 같은 station의 small < big < boss 순서를 깨지 않는다.
- 초반 빌드가 후반까지 그대로 밀고 가는 구조는 실패로 본다. S1~S2, S3~S5, S6~S8은 필요한 성장 기준이 달라야 한다.
- 가장 나쁜 상태는 턴이 늘어지는 것이고, 그 다음은 덱 고갈로 게임이 막히는 것이다. 승률만 보지 않고 평균 turn, clear-path turn, failed-path turn, stop reason을 함께 본다.

## v57~v61 통합 레벨링 후보 수렴

목표:

- v56에서 드러난 S1 boss / S8 boss 병목을 target 역전 없이 줄인다.
- S1은 마켓 적용 전 구간이므로, market만으로는 S1 boss를 해결할 수 없다는 점을 분리한다.
- 실제 UI/저장/마켓 구현은 건드리지 않고 시뮬 전용 profile/experiment로만 검증한다.

추가한 시뮬 전용 후보:

- `shop_slot_market_v8`
  - S1~S2 이후 초반 구간에서 common jester, Tarot/Pack, resource 후보 선택 품질을 올린다.
  - Rare/Legendary는 낮은 확률로 유지한다.
- `weighted_boss_v2`
  - final band의 `target_spike_wall` weight를 낮춘다.
- `weighted_boss_v3`
  - S1~S2에서 `color_dampener_cycle` 과밀을 줄이고 모든 boss type이 낮은 확률로라도 나오게 한다.
  - final band도 `target_spike_wall` 과밀을 더 줄인다.
- `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3`
  - S1에서 board/hand/max hand resource를 +1 주는 시뮬 전용 시작 보정이다.
  - 실제 시작 보상 구현이 아니라, “초반 재미/막힘 완화가 필요하면 이 정도 자원이 어느 정도 효과인지” 보는 수치 실험이다.
- `shop_slot_market_v9`
  - S7~S8에서 late breaker 성격의 Rare/Planet/Uncommon 후보 선택을 더 선호한다.
  - 목적은 후반에 늦게 죽는 run의 실패 turn을 줄이는 것이다.

실험 산출물:

- v57 summary: `logs/sim/ml_sweep_integrated_weighted_boss_v57_s8_r800_summary.json`
- v58 summary: `logs/sim/ml_sweep_integrated_weighted_boss_v58_s8_r800_summary.json`
- v59 summary: `logs/sim/ml_sweep_integrated_weighted_boss_v59_s8_r800_summary.json`
- v60 summary: `logs/sim/ml_sweep_integrated_weighted_boss_v60_s8_r800_summary.json`
- v61 summary: `logs/sim/ml_sweep_integrated_weighted_boss_v61_s8_r1600_summary.json`
- v61 bottleneck: `logs/sim/ml_sweep_integrated_weighted_boss_v61_s8_r1600_summary_bottleneck_report.md`
- v61 ML insight: `logs/sim/ml_sweep_integrated_weighted_boss_v61_s8_r1600_summary_ml_insights_report.md`

비교:

| version | runs | market | boss/resource profile | path clear | avg total turn | clear-path turn | failed-path turn | 주요 실패 |
|---|---:|---|---|---:|---:|---:|---:|---|
| v56 | 800 | `shop_slot_market_v7` | weighted boss v1 | 60.0% | 1255.8 | 1577.7 | 773.0 | S1 boss 72, S8 boss 60 |
| v57 | 800 | `shop_slot_market_v8` | weighted boss v2 | 60.1% | 1248.7 | 1578.1 | 752.1 | S1 boss 71, S8 boss 54 |
| v58 | 800 | `shop_slot_market_v8` | weighted boss v3 | 62.7% | 1277.7 | 1577.1 | 773.4 | S8 boss 46, S1 boss 44 |
| v59 | 800 | `shop_slot_market_v8` | S1 resource + weighted boss v3 | 67.5% | 1347.9 | 1571.6 | 883.3 | S8 boss 50, S1 boss 40 |
| v60 | 800 | `shop_slot_market_v9` | S1 resource + weighted boss v3 | 68.9% | 1350.6 | 1567.3 | 871.0 | S8 boss 45, S1 boss 37 |
| v61 | 1600 | `shop_slot_market_v9` | S1 resource + weighted boss v3 | 68.4% | 1330.1 | 1566.5 | 818.8 | S1 boss 92, S8 boss 84 |

v61 주요 실패:

| bottleneck | count |
|---|---:|
| S1 boss | 92 / 1600 |
| S8 boss | 84 / 1600 |
| S7 boss | 36 / 1600 |
| S1 big | 34 / 1600 |
| S8 big | 32 / 1600 |
| S3 boss | 24 / 1600 |
| S1 small | 23 / 1600 |
| S2 boss | 22 / 1600 |

v61 stop reason:

| stop reason | count |
|---|---:|
| boardFullAfterDcExhausted | 340 |
| drawPileExhausted | 161 |
| drawPileExhausted + boardFullAfterDcExhausted | 5 |

판정:

- v61은 path clear 68.4%로 목표 범위 65~70% 안에 안정적으로 들어온다.
- clear-path turn은 v56보다 줄었다. 즉 성공 run은 더 늘어지지 않는다.
- failed-path turn은 v56보다 높지만 v60보다 낮아졌다. 이는 S1에서 바로 죽는 run이 줄고, S7~S8까지 간 뒤 실패하는 run이 늘어난 영향이다.
- S1 시작 자원 +1은 실제 구현 후보로 검토할 가치가 있다. 단, 실제 저장/시작 보상 구조에 넣기 전에는 별도 구현 승인 필요.
- `shop_slot_market_v9`는 late breaker 후보로 의미가 있다. 실제 상점에서는 고정 지급이 아니라 S7~S8 후보 pool weight로 해석해야 한다.
- 현재 후보는 “실제 구현 검토 가능” 단계에 도달했다. 아직 실제 UI/저장/마켓/전투에 적용한 것은 아니다.

다음 실무 전환 전에 확인할 것:

1. S1 시작 자원 +1을 실제 게임에서 “기본 지급”으로 할지, “첫 선택 보상/튜토리얼 보상”으로 할지 결정해야 한다.
2. `shop_slot_market_v9`는 실제 상점 catalog가 아니라 구간별 등장 weight 설계로 변환해야 한다.
3. weighted boss v3는 실제 `RummiBossModifier` 구조로 바로 들어가지 않는다. 먼저 실제 보스 제약 표현 가능 범위를 따져야 한다.
4. 현재 레벨링 수치는 전체 구현의 기준점 후보이지 최종 밸런스 테이블이 아니다. 실제 상점 UI와 전투 보스 제약이 들어가면 다시 S1~S8 통합 sweep을 돌려야 한다.

## v62 구현 전환 검토 체크리스트

목표:

- v61의 통합 후보를 실제 게임 코드에 바로 넣는 것이 아니라, 실제 구현 가능한 단위로 번역한다.
- 실제 UI, 저장 데이터, 실제 상점, 실제 전투 코드는 아직 변경하지 않는다.
- S1~S8 레벨링 기준은 고정 지급표가 아니라, 구간별 후보 pool과 weight, 시작 자원, 보스 제약이 함께 만든 기대값으로 본다.
- 우리가 실제로 확정할 수 있는 것은 target score, 후보 등장 weight, 허용 범위, 병목 기준이다.
- 시뮬에서 확인한 성장은 유저가 해당 성장 방식을 따라왔을 때의 best-case 후보이며, 실제 유저가 항상 그 루트를 선택한다고 가정하지 않는다.
- 따라서 구현 전환 기준은 “특정 빌드가 깬다”가 아니라 “여러 성장 선택이 섞여도 늘어짐/고갈/스몰·빅·보스 병목이 허용 범위 안에 남는다”이다.

이번 단계 완료:

- [x] S1 시작 자원 +1 후보가 실제 코드 어느 경계에 걸리는지 확인했다.
- [x] `shop_slot_market_v9`가 실제 상점 구조에서 고정 지급이 아니라 market weight 정책으로 번역되어야 함을 확인했다.
- [x] `weighted_boss_v3`가 현재 `RummiBossModifier`만으로 전부 표현되지 않음을 확인했다.
- [x] 저장 구조 변경이 필요한 항목과 기존 필드로 처리 가능한 항목을 분리했다.
- [x] 실제 구현 후보를 1차 구현, 2차 구조 보강, 보류 항목으로 나눴다.

### S1 시작 자원 +1 번역

시뮬 후보:

- `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3`
- 의미: S1에서 board discard, hand discard, max hand를 각각 +1 보정한다.
- v61 효과: S1에서 바로 막히는 run을 줄이고, path clear를 목표 범위 65~70% 안으로 올렸다.

실제 코드 경계:

- 초기 전투 생성은 `GameSessionNotifier.build`에서 `BlindSelectionSetup.resolveSpec(...)` 결과를 받아 만든다.
- 후속 small/big/boss 전투는 `BlindSelectionSetup.prepareContinuedRunForSelectedBlind(...)`와 `RummiRunProgress.startBlind(...)` 흐름을 탄다.
- 실제 blind 필드에는 이미 `boardDiscardsRemaining`, `handDiscardsRemaining`, `maxHandSize`가 있다.
- `ItemEffectRuntime.applyOwnedStationStartItems(...)`에는 station start 시 board/hand discard나 hand size를 바꾸는 효과 계열이 이미 있다.

구현 선택지:

| 선택지 | 설명 | 장점 | 위험 |
|---|---|---|---|
| S1 기본 blind 보정 | S1의 `BlindSelectionSpec`만 board/hand/max hand +1 | 구현이 가장 단순하고 저장 구조 변경이 거의 없다 | 모든 새 run의 기본 난이도가 직접 내려간다 |
| 첫 보상/튜토리얼 시작 보상 | 기존 station start item effect 계열로 초반 보강을 준다 | “초반 재미와 선택”으로 표현하기 좋다 | 실제 보상 UI/소유 item/저장 흐름과 연결해야 한다 |
| 상점으로 해결 | S1 이후 market 후보로 보강한다 | 상점 구조와 일관된다 | S1 boss 이전 병목은 해결하지 못한다 |

판정:

- 1차 실제 구현 후보는 “첫 보상/튜토리얼 시작 보상”이다.
- S1 보강은 기본 난이도 보정이 아니라, S1 small 클리어 후 유저가 받는 첫 성장 보상으로 적용한다.
- 이 보상은 첫 상점/다음 blind 진입 전에 적용되어야 한다.
- 지금 단계에서는 실제 적용하지 않고, 구현 후보만 남긴다.

### `shop_slot_market_v9` 번역

시뮬 후보:

- `shop_slot_market_v9`
- 의미: S7~S8에서 late breaker 성격의 Rare/Planet/Uncommon 후보 선택 확률을 올린다.
- 목적: 후반까지 간 run이 마지막 병목에서 너무 오래 버티다 죽는 것을 줄인다.

실제 코드 경계:

- 현재 실제 상점은 `RummiRunProgress.shopOffers`, `rerollShop(...)`, `buyOffer(...)`, `buildShopOffers(...)` 중심이다.
- `RummiMarketFacade`는 실제 상점 구조를 대체하지 않는 read facade다.
- 현재 실제 shop weight는 Jester rarity weight와 일부 item slot/rarity modifier 중심이다.
- Pack, Tarot, Planet은 아직 실제 상점 카테고리로 완성된 구조가 아니다.

실제 번역 방향:

| 구간 | market policy |
|---|---|
| S1 | 상점 전 병목이므로 market으로 해결하지 않는다 |
| S2~S3 | Common Jester, shape fix, resource, 작은 pack/tarot-like item 비중을 높인다 |
| S4~S5 | Uncommon build, rank growth/planet-like, tarot-like shaping, sustain resource를 섞는다 |
| S6~S8 | Rare xmult/late breaker, uncommon bridge, resource safety, 낮은 Legendary 확률을 유지한다 |

판정:

- `shop_slot_market_v9`는 실제 게임에서 특정 아이템을 고정 지급하는 데이터가 아니다.
- 실제 구현 시 이름은 `station_band_market_policy_v1` 같은 “구간별 시장 가중치 정책”으로 옮기는 것이 맞다.
- 1차 구현은 Jester + 기존 Item 효과를 기본으로 하되, 실제 구조가 감당 가능한 범위 안에서 Pack/Tarot/Planet proxy도 최대한 많이 포함하는 방향으로 잡는다.
- 단, Pack/Tarot/Planet이 실제 저장/UI/구매/소비 구조를 강제로 바꾸게 되면 그 항목은 2차로 분리한다.

### `weighted_boss_v3` 번역

시뮬 후보:

- `weighted_boss_v3`
- 의미: early/mid/late/final 구간별 boss constraint 후보를 weighted pool로 뽑는다.
- 목적: 보스 병목을 한두 패턴에 고정하지 않고, 실제 게임처럼 다양한 제약이 섞이게 한다.

현재 실제 `RummiBossModifier` 표현 범위:

- 가능:
  - 특정 색상 타일이 포함된 line score 감쇠
  - 특정 line kind score 감쇠
- 제한적 가능:
  - target spike는 boss modifier가 아니라 blind target multiplier로 표현 가능하다.
  - resource squeeze는 boss modifier가 아니라 board/hand/max hand 조정으로 표현 가능하다.
- 바로 불가:
  - face tile dampener
  - repeat rank pressure
  - single rank pressure
  - confirm count tax
  - first confirm tax
  - 전체 점수 감쇠

판정:

- 현재 구조에 `weighted_boss_v3`를 그대로 넣으면 시뮬의 의미가 깨진다.
- 1차 구현은 기존 `RummiBossModifier`로 표현 가능한 색상/라인 감쇠와 target/resource 조정을 우선 적용한다.
- 동시에 실제 구조가 감당 가능한 범위 안에서 face/rank/confirm pressure 계열도 최대한 많이 포함할 수 있는지 검토한다.
- 단, 전투 점수 계산, preview, UI 표시, 저장/복원 계약을 깨는 항목은 `Boss Constraint Runtime v1`로 분리한다.

권장 명칭:

- 시뮬에서 Balatro 보스 패턴을 우리 게임 규칙으로 바꾼 세트: `Rummi Boss Constraint Proxy Pool`
- 실제 런타임에 들어갈 보스 제약 구조: `Boss Constraint Runtime v1`
- 실제 구간별 보스 배치 정책: `station_band_boss_constraint_policy_v1`

### 실제 구현 후보 분류

1차 구현 가능:

- S1 small 클리어 후 첫 성장 보상
  - 기존 blind 필드로 표현 가능하다.
  - 기본 난이도 보정이 아니라 유저가 받은 보상으로 표현한다.
  - 단, 기존 저장/이어하기와 충돌하지 않는지 테스트가 필요하다.
- Jester + 기존 Item + 가능한 proxy 기반 market weight 정책
  - 기존 shop offer와 rarity/item slot 구조를 활용한다.
  - Pack/Tarot/Planet 전용 구조가 없어도 item proxy로 표현 가능한 후보는 최대한 포함한다.
- 기존 boss modifier 기반 색상/라인 감쇠 순환 + target/resource boss pressure
  - 현재 전투 점수 계산과 저장 구조가 이미 이해하는 범위다.
  - 실제 구조가 감당 가능한 추가 boss pressure는 1차 후보에 포함할 수 있는지 검토한다.

2차 구조 보강 후 가능:

- Pack/Tarot/Planet 전용 후보
  - item proxy로 표현되지 않는 후보는 실제 카탈로그, UI 표시, 구매/소비 흐름, 저장 구조 검토가 필요하다.
- `Boss Constraint Runtime v1`
  - 보스 제약 계산, 전투 표시, 점수 preview, 저장/복원 계약을 함께 설계해야 한다.
- 구간별 boss weighted pool의 실제 런타임 적용
  - 현재는 시뮬 proxy이고, 실제 boss modifier 구조와 1:1 대응하지 않는다.

보류:

- 복사/파괴/판매/렌탈/이터널/네거티브 계열
- 도감/해금 전제 항목
- 실제 저장 구조 변경이 먼저 필요한 후보
- 현재 족보와 직접 맞지 않는 후보

### 다음 순차 작업

- [x] 1차 구현 범위를 `S1 small 첫 클리어 골드 보상 + Jester/Item/proxy market weight policy + 가능한 boss pressure 최대 포함`으로 제한한다.
- [x] 실제 코드 수정 전에 해당 범위의 테스트 지점을 먼저 정리한다.
- [x] S1 시작 자원 보정은 기본값 변경이나 무료 아이템 지급이 아니라 S1 small 첫 클리어 골드 보상으로 적용하기로 결정했다.
- [x] S1 small 첫 클리어 보너스는 cash-out 보상 체계 안의 추가 골드로 구현했다.
- [x] market policy는 `shop_slot_market_v9`를 고정 지급이 아니라 구간별 weight table로 번역한다.
- [x] market policy는 실제 구조가 감당 가능한 후보를 최대한 많이 포함하되, 저장/UI/구매/소비 구조 변경이 큰 항목은 2차로 분리한다.
- [x] boss는 색상/라인/target/resource를 기본 포함하고, face/rank/confirm pressure 계열은 실제 구조에 넣을 수 있는 만큼 포함 여부를 검토한다.
- [x] 저장 구조는 추천 방향대로 1차에서는 가능한 기존 필드와 transient policy로 처리하고, 새 save field가 필요하면 별도 단계로 분리한다.
- [x] 1차 구현 후 `flutter test test/tools/sim/balance_sim_test.dart`를 실행한다.
- [x] blind selection을 건드리면 blind selection 관련 테스트를 추가/실행한다.
- [x] market generation을 건드리면 reroll/offer determinism 테스트를 추가/실행한다.
- [ ] 실제 save field를 건드리게 되면 저장/복원 테스트를 추가한다.
- [x] 1차 구현 후 S1~S8 통합 sweep을 다시 돌려 v61과 비교한다.
- [x] 재검증 기준은 path clear뿐 아니라 평균 turn, clear-path turn, failed-path turn, deck exhausted, board locked, small/big/boss 병목 분포를 모두 충족해야 한다.

v62 S1 첫 성장 보상 구현 메모:

- 무료 아이템은 만들지 않는다.
- 이유 없는 보정 골드도 지급하지 않는다.
- S1 small 클리어 후 보상은 `첫 블라인드 클리어 보너스`라는 cash-out 시스템 보상으로 정의한다.
- 보너스 금액은 +5 Gold다. 현재 상점 가격대 기준으로 공통 아이템 1개 또는 리롤 1회 선택권에 가깝다.
- 이 보상은 자동 스탯 증가가 아니라, 유저가 첫 상점에서 직접 성장 방향을 고르게 하기 위한 자원이다.
- 실제 저장 schema는 변경하지 않았다. 별도 무료 item stack도 저장하지 않는다.
- 검증:
  - `python3 -m json.tool data/common/items_common_v1.json`
  - `python3 -m json.tool assets/translations/data/ko/items.json`
- `flutter test test/logic/item_effect_runtime_test.dart test/logic/rummi_market_facade_test.dart test/providers/game_session_notifier_test.dart`
- `flutter test test/tools/sim/balance_sim_test.dart`
- `python3 -m py_compile tools/sim/ml_sweep_dataset.py`

v62 market policy 구현 메모:

- 실제 이름은 `RummiStationBandMarketPolicy`로 두고, 정책 의미는 `station_band_market_policy_v1`이다.
- S1~S2, S3~S5, S6~S8을 early/mid/late band로 나눴다.
- Jester는 기존 stage별 rarity weight를 정책 클래스로 분리했다.
- Item offer는 catalog 순서 고정 노출이 아니라 stage band, rarity, tag 기반 weighted pick으로 바꿨다.
- early는 economy/market/discard/safety/move/shape 보정 후보를 더 잘 보이게 한다.
- mid는 score/rank/tile_color/market/rarity/capacity 후보를 올려 빌드 성장 전환을 돕는다.
- late는 boss/legendary/xmult/rarity/market/capacity 후보를 올려 후반 breaker 가능성을 유지한다.
- Rare/Legendary는 초반에도 0으로 막지 않는다. 다만 낮은 확률과 낮은 weight로 남긴다.
- 이 정책은 성장 루트를 지급하거나 보장하지 않는다. 유저가 선택할 수 있는 후보의 등장 범위와 확률을 조정할 뿐이다.
- 이 변경은 save schema를 늘리지 않는다. 상점 표시 시점의 transient policy다.
- Pack/Tarot/Planet 전용 UI/구매/소비 구조가 필요한 항목은 아직 2차 구조 보강으로 남긴다.
- 검증:
  - `flutter test test/logic/rummi_market_facade_test.dart test/logic/rummi_session_test.dart`
  - `flutter test test/providers/game_session_notifier_test.dart`
  - `flutter test test/tools/sim/balance_sim_test.dart`

v62 boss policy 구현 메모:

- 1차 실제 보스 정책은 현재 `RummiBossModifier`가 이미 표현할 수 있는 색상/라인 감쇠로 제한한다.
- target pressure는 기존 boss target multiplier로 유지한다.
- resource pressure는 기존 boss blind의 board discard, hand discard, max hand 감소로 유지한다.
- 실제 보스 후보는 red/blue/black/yellow tile dampener와 row/column/diagonal line dampener로 넓혔다.
- 이 확장은 기존 `RummiBossModifierCategory.tileColorWeaken`과 `lineKindWeaken`만 사용하므로 save schema를 늘리지 않는다.
- face/rank/confirm tax/all-score dampener는 1차에 넣지 않는다. 이 계열은 점수 계산, preview, 전투 표시, 저장/복원 계약을 함께 설계하는 `Boss Constraint Runtime v1`에서 다룬다.
- 검증:
  - `flutter test test/services/blind_selection_setup_test.dart test/services/active_run_save_service_test.dart test/logic/rummi_session_test.dart`
  - `flutter test test/logic/rummi_market_facade_test.dart test/providers/game_session_notifier_test.dart`

v63 통합 runtime transition sweep:

- 목적: 1차 실제 런타임 전환 후보가 “특정 성장 루트를 보장”하는 방식이 아니라, target/weight/range 레벨링으로 기능하는지 확인한다.
- 실행:
  - `python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 800 --jobs 4 --summary-only --out-prefix logs/sim/ml_sweep_integrated_runtime_transition_v63_r800 --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3 --market-profiles none,shop_slot_market_v9 --loadout-ids progression_route_balanced,progression_route_delayed,progression_route_sustain,progression_route_power`
- 결과 파일:
  - `logs/sim/ml_sweep_integrated_runtime_transition_v63_r800_summary.json`
  - `logs/sim/ml_sweep_integrated_runtime_transition_v63_r800_report.md`
  - `logs/sim/ml_sweep_integrated_runtime_transition_v63_r800_summary_ml_insights_report.md`
- 규모:
  - run_count 117061
  - sequence_run_count 6400
  - groups 1262
  - sequence_groups 8

v63 sequence 결과:

| loadout route | market | path clear | turn/attempted step | clear path turn | failed path turn | 주요 실패 |
|---|---:|---:|---:|---:|---:|---|
| progression_route_balanced | none | 46.5% | 73.7 | 1758.5 | 942.8 | S8 boss, S4 boss, S1 boss |
| progression_route_balanced | shop_slot_market_v9 | 61.4% | 70.4 | 1679.7 | 782.3 | S1 boss, S8 boss, S4 boss |
| progression_route_delayed | none | 15.4% | 79.5 | 1901.5 | 1045.0 | S5 boss, S6 boss, S4 boss |
| progression_route_delayed | shop_slot_market_v9 | 39.6% | 75.7 | 1803.7 | 940.3 | S5 boss, S6 boss, S1 boss |
| progression_route_sustain | none | 46.5% | 73.8 | 1761.4 | 990.9 | S8 boss, S4 boss, S1 boss |
| progression_route_sustain | shop_slot_market_v9 | 61.9% | 70.2 | 1675.5 | 829.5 | S8 boss, S1 boss, S1 small |
| progression_route_power | none | 55.7% | 68.4 | 1636.6 | 1002.2 | S8 boss, S1 boss, S7 boss |
| progression_route_power | shop_slot_market_v9 | 68.4% | 65.5 | 1566.0 | 832.1 | S8 boss, S1 boss, S1 big |

v63 station 병목:

- 전체 aggregate 기준 `shop_slot_market_v9`는 clear 96.7% -> 97.8%, turn 73.5 -> 70.2, deck exhausted 1.9% -> 0.9%로 개선했다.
- S8 boss는 clear 87.9%, turn 93.9, deck exhausted 10.6%로 가장 강한 잔여 병목이다.
- S5 boss는 clear 91.8%, deck exhausted 6.9%, S6 boss는 clear 93.6%, deck exhausted 5.1%로 중후반 boss 병목이 남는다.
- S1 boss는 clear 94.5%, turn 81.0으로 초반 재미 구간치고는 아직 길다. 단, S1 small/big는 각각 clear 98.2%/97.3%로 시작 자체는 막히지 않는다.
- delayed route는 market이 있어도 path clear 39.6%에 그친다. 초반 빌드를 늦게 잡는 유저는 S5~S6 boss에서 막히는 구조다.

v63 판정:

- 현재 방향은 “우리가 성장 루트를 제공하는 것”이 아니라, 유저가 스스로 고르는 성장 후보의 등장 weight와 점수 range를 잡는 레벨링에 가깝다.
- `shop_slot_market_v9`는 실제 적용 후보로 유지할 가치가 있다. 다만 이것만으로 delayed route를 충분히 보호하지 못한다.
- 후반까지 초반 빌드 하나로 밀어붙이는 구조는 아니다. S5~S8 boss에서 route별 격차가 분명히 난다.
- 늘어짐 관점에서는 market이 turn/step을 줄이므로 방향은 맞다. 다만 S8 boss와 delayed route는 여전히 긴 실패 run을 만든다.
- 다음 수치 작업은 전체 curve를 다시 흔드는 것보다 S5~S8 boss target/resource/market late breaker weight를 좁게 sweep하는 편이 맞다.

v64 late boss 좁은 sweep:

- 목적: v63에서 남은 S5~S8 boss 병목을 전체 curve 재작성 없이 줄일 수 있는지 확인한다.
- 방향:
  - S5는 점수 완화보다 자원/선택 병목으로 본다.
  - S6~S8 boss는 target multiplier를 0.70 또는 0.68로 낮추는 후보를 비교한다.
  - S5~S8 boss 자원 보강은 `board_discards +1`, `hand_discards +1`, `max_hand_size +1` proxy로만 둔다.
  - 이 보강은 실제 보상 지급 후보가 아니라, 필요한 자원 성장 아이템이 어느 정도 가치가 있는지 측정하는 진단용 upper-bound다.
  - 실제 적용 방향은 보스전 자동 자원 보정이 아니라 S3~S5/S6~S8 market candidate availability, 등장 weight, 가격대 검토다.
  - 게임은 구매/장착/사용을 대신해 주지 않는다. 유저가 해당 아이템을 발견하고 선택할 수 있게 마켓에 등장시키는 것까지만 레벨링 범위다.
- 실행:
  - `python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 800 --jobs 4 --summary-only --out-prefix logs/sim/ml_sweep_late_boss_v64_r800 --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3,base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070,base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068,base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_resource_1,base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070_resource_1 --market-profiles shop_slot_market_v9 --loadout-ids progression_route_delayed,progression_route_balanced,progression_route_sustain,progression_route_power`
- 결과 파일:
  - `logs/sim/ml_sweep_late_boss_v64_r800_summary.json`
  - `logs/sim/ml_sweep_late_boss_v64_r800_report.md`
  - `logs/sim/ml_sweep_late_boss_v64_r800_summary_ml_insights_report.md`
- 규모:
  - run_count 305024
  - sequence_run_count 16000
  - groups 5091
  - sequence_groups 20

v64 sequence aggregate:

| experiment | path clear | avg turn | clear path turn | failed path turn | 주요 실패 |
|---|---:|---:|---:|---:|---|
| base_v63 | 58.6% | 1347.2 | 1664.9 | 897.1 | S8 boss, S1 boss, S5 boss, S6 boss |
| late_boss_070 | 58.2% | 1325.1 | 1662.1 | 856.2 | S1 boss, S5 boss, S8 boss, S6 boss |
| late_boss_068 | 59.1% | 1329.7 | 1659.6 | 853.2 | S1 boss, S5 boss, S8 boss, S4 boss |
| late_boss_resource_1 | 60.1% | 1326.6 | 1653.6 | 833.5 | S1 boss, S5 boss, S6 boss, S4 boss |
| late_boss_070_resource_1 | 62.8% | 1338.2 | 1650.7 | 809.6 | S1 boss, S5 boss, S4 boss, S6 boss |

v64 route별 핵심:

| experiment | balanced | delayed | sustain | power |
|---|---:|---:|---:|---:|
| base_v63 | 64.0% | 39.2% | 63.1% | 68.1% |
| late_boss_070 | 61.6% | 41.6% | 62.5% | 67.0% |
| late_boss_068 | 63.1% | 42.6% | 63.5% | 67.1% |
| late_boss_resource_1 | 65.1% | 40.4% | 66.5% | 68.5% |
| late_boss_070_resource_1 | 70.4% | 44.9% | 66.9% | 69.2% |

v64 S5~S8 boss 병목:

| experiment | S5 boss | S6 boss | S7 boss | S8 boss |
|---|---:|---:|---:|---:|
| base_v63 | 94.2%, turn 78.4, deck 4.4% | 95.3%, turn 70.0, deck 3.6% | 97.9%, turn 75.2, deck 1.0% | 92.0%, turn 90.4, deck 6.5% |
| late_boss_070 | 93.4%, turn 78.9, deck 5.3% | 95.8%, turn 69.1, deck 3.0% | 97.9%, turn 73.5, deck 0.8% | 93.5%, turn 88.0, deck 5.1% |
| late_boss_068 | 93.5%, turn 78.9, deck 5.3% | 96.2%, turn 68.3, deck 2.7% | 98.1%, turn 72.6, deck 0.6% | 93.9%, turn 86.5, deck 4.6% |
| late_boss_resource_1 | 93.2%, turn 78.5, deck 5.3% | 95.5%, turn 67.7, deck 3.8% | 98.5%, turn 70.8, deck 0.6% | 96.1%, turn 84.3, deck 3.1% |
| late_boss_070_resource_1 | 94.5%, turn 78.4, deck 4.4% | 96.7%, turn 66.4, deck 2.8% | 99.0%, turn 68.7, deck 0.2% | 96.4%, turn 82.3, deck 2.5% |

v64 판정:

- `late_boss_070_resource_1`은 수치상 가장 좋지만, 자동 자원 +1이 포함되어 실제 기준 후보로 쓰면 안 된다.
- 이 결과는 “S5~S8에서 자원 성장 아이템이 마켓에 등장하고 유저가 선택했을 때 어느 정도 병목이 풀리는가”를 보여주는 진단값으로만 남긴다.
- 전체 path clear는 58.6% -> 62.8%로 올랐고, failed path turn은 897.1 -> 809.6으로 줄었다.
- S8 boss는 clear 92.0% -> 96.4%, turn 90.4 -> 82.3, deck exhausted 6.5% -> 2.5%로 개선했다.
- S6/S7 boss도 turn과 deck pressure가 같이 줄었다.
- delayed route는 39.2% -> 44.9%로 개선됐지만 여전히 낮다. 이 구간은 target 완화만으로는 부족하고, S3~S5 성장 후보가 마켓에 등장 가능한지와 등장 weight가 적절한지 더 봐야 한다.
- S1 boss와 S4 boss가 여전히 sequence 실패 상위권이다. 후반 완화 후에도 초반/중반 gate를 따로 잡아야 한다.
- 자동 자원 보정 없는 후보 중에서는 `late_boss_068`이 S6~S8 boss를 가장 부드럽게 만들었지만, path clear 개선은 58.6% -> 59.1%로 제한적이다.
- 다음 실제 기준 후보는 자동 자원 보정이 없는 `shop_slot_market_v9 + late_boss_068` 또는 `late_boss_070` 계열에서 출발하고, resource +1 효과는 market candidate availability와 등장 weight 실험으로 재현해야 한다.

v64 후속 체크리스트:

- [x] v63 기준과 같은 weighted boss v3를 상속하는 v64 실험 ID를 추가한다.
- [x] S6~S8 boss target 0.70/0.68 후보를 추가한다.
- [x] S5~S8 boss resource +1 후보를 추가한다.
- [x] S5는 target 완화 대상에서 제외하고 resource 후보로 검증한다.
- [x] `flutter test test/tools/sim/balance_sim_test.dart`를 통과시킨다.
- [x] `python3 -m py_compile tools/sim/ml_sweep_dataset.py`를 통과시킨다.
- [x] `git diff --check`를 통과시킨다.
- [x] v64 r800 summary-only sweep을 완료한다.
- [x] v64 결과를 sequence, route, S5~S8 boss 병목 기준으로 문서화한다.
- [x] 다음 작업: S1/S4 boss 실패를 줄이는 early/mid gate 후보를 좁게 sweep한다.
- [ ] 다음 작업: delayed route를 위해 S3~S5 resource/growth 후보가 market에 등장 가능한지와 등장 weight를 보강한다.
- [x] 다음 작업: 실제 UI/상점/전투 구현 전에 `late_boss_070_resource_1`의 의미를 실제 시스템 용어로 번역한다.
- [ ] 다음 작업: `late_boss_070_resource_1`을 기준 후보에서 제외하고, 동일 효과를 S3~S5/S6~S8 market 후보 등장 가능성과 등장 weight로 재현한다.

v65 early/mid gate 좁은 sweep:

- 목적: v64 best에서 남은 S1 boss, S4 boss 실패가 단순 target/resource 조정으로 줄어드는지 확인한다.
- 기준 후보: 당시에는 `shop_slot_market_v9 + late_boss_070_resource_1`를 사용했다.
- 정정: 이 기준에는 자동 자원 +1이 포함되어 있으므로 실제 적용 기준 후보가 아니라 진단용 비교군이다.
- 추가 후보:
  - `early_mid_s1_boss_050`: S1 boss target multiplier 0.50
  - `early_mid_s4_boss_060`: S4 boss target multiplier 0.60
  - `early_mid_s4_boss_resource_1`: S4 boss resource +1
  - `early_mid_s1_050_s4_060_resource_1`: S1 target + S4 target/resource 조합
- 실행:
  - `python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 800 --jobs 4 --summary-only --out-prefix logs/sim/ml_sweep_early_mid_gate_v65_r800 --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070_resource_1,base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070_resource_1_early_mid_s1_boss_050,base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070_resource_1_early_mid_s4_boss_060,base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070_resource_1_early_mid_s4_boss_resource_1,base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070_resource_1_early_mid_s1_050_s4_060_resource_1 --market-profiles shop_slot_market_v9 --loadout-ids progression_route_delayed,progression_route_balanced,progression_route_sustain,progression_route_power`
- 결과 파일:
  - `logs/sim/ml_sweep_early_mid_gate_v65_r800_summary.json`
  - `logs/sim/ml_sweep_early_mid_gate_v65_r800_report.md`
  - `logs/sim/ml_sweep_early_mid_gate_v65_r800_summary_ml_insights_report.md`

v65 sequence aggregate:

| experiment | path clear | avg turn | clear path turn | failed path turn | 주요 실패 |
|---|---:|---:|---:|---:|---|
| v64_best | 62.8% | 1338.2 | 1650.7 | 809.6 | S1 boss, S5 boss, S4 boss, S6 boss |
| s1_boss_050 | 63.0% | 1336.9 | 1649.2 | 805.1 | S1 boss, S5 boss, S4 boss, S1 big |
| s4_boss_060 | 63.3% | 1346.4 | 1648.0 | 827.3 | S5 boss, S1 boss, S6 boss, S1 big |
| s4_boss_resource_1 | 61.5% | 1324.1 | 1644.8 | 812.6 | S1 boss, S5 boss, S6 boss, S1 big |
| s1_050_s4_060_resource_1 | 62.5% | 1331.0 | 1648.0 | 803.5 | S1 boss, S5 boss, S6 boss, S1 big |

v65 route별 핵심:

| experiment | balanced | delayed | sustain | power |
|---|---:|---:|---:|---:|
| v64_best | 70.4% | 44.9% | 66.9% | 69.2% |
| s1_boss_050 | 64.9% | 47.1% | 66.4% | 73.6% |
| s4_boss_060 | 67.5% | 45.9% | 68.0% | 71.6% |
| s4_boss_resource_1 | 63.6% | 44.0% | 64.1% | 74.1% |
| s1_050_s4_060_resource_1 | 68.4% | 43.6% | 66.2% | 71.6% |

v65 S1/S4/S8 boss 병목:

| experiment | S1 boss | S4 boss | S8 boss |
|---|---:|---:|---:|
| v64_best | 94.5%, turn 81.3, deck 2.8% | 96.9%, turn 81.9, deck 1.5% | 96.4%, turn 82.3, deck 2.5% |
| s1_boss_050 | 94.6%, turn 80.9, deck 2.8% | 96.6%, turn 81.6, deck 1.3% | 97.2%, turn 81.9, deck 2.1% |
| s4_boss_060 | 95.4%, turn 81.0, deck 2.7% | 97.3%, turn 80.7, deck 1.0% | 96.6%, turn 81.9, deck 2.5% |
| s4_boss_resource_1 | 93.6%, turn 81.0, deck 3.7% | 97.2%, turn 81.3, deck 1.4% | 96.6%, turn 82.0, deck 2.0% |
| s1_050_s4_060_resource_1 | 93.5%, turn 81.3, deck 3.5% | 97.0%, turn 80.3, deck 1.0% | 96.6%, turn 81.7, deck 2.3% |

v65 판정:

- 단독 `s4_boss_060`은 전체 path clear를 62.8% -> 63.3%로 소폭 올렸지만 failed path turn은 809.6 -> 827.3으로 나빠졌다.
- 단독 `s1_boss_050`은 delayed route 44.9% -> 47.1%, power route 69.2% -> 73.6%를 올렸지만 balanced route 70.4% -> 64.9%로 크게 깎았다.
- S4 resource +1은 전체 path clear가 낮아져 탈락이다.
- S1/S4 조합은 failed path turn은 줄지만 path clear가 v64 best보다 낮아져 탈락이다.
- 따라서 S1/S4 boss는 단순 target/resource 조정보다 S3~S5 성장 후보가 market에 등장하는지, 그리고 그 등장 weight가 충분한지의 병목일 가능성이 크다.
- `v64_best = shop_slot_market_v9 + late_boss_070_resource_1`은 자동 자원 +1이므로 실제 기준 후보에서 제외한다.
- 다음 작업은 target을 더 낮추거나 자원을 자동 지급하는 것이 아니라, `delayed route`가 S3~S5에서 자원/성장 후보를 발견할 수 있도록 market candidate availability와 등장 weight를 검증하는 것이다.
- 자원 +1 계열 실험은 앞으로 “보스 보정 후보”가 아니라 “상점에서 구매되어야 할 성장 수요의 upper-bound”로만 해석한다.
- bot 선택 proxy는 유저 선택 성향을 보기 위한 시뮬 장치일 뿐이며, 실제 게임은 구매를 대신해 주지 않는다.

v65 후속 체크리스트:

- [x] v64 best 위에 S1/S4 boss target/resource 후보를 시뮬 전용 ID로 추가한다.
- [x] `flutter test test/tools/sim/balance_sim_test.dart`를 통과시킨다.
- [x] `python3 -m py_compile tools/sim/ml_sweep_dataset.py`를 통과시킨다.
- [x] `git diff --check`를 통과시킨다.
- [x] v65 r800 summary-only sweep을 완료한다.
- [x] v65 결과를 sequence, route, S1/S4/S8 boss 병목 기준으로 문서화한다.
- [x] 다음 작업: S3~S5 market candidate availability와 등장 weight를 delayed route 중심으로 보강한다.

v66/v67 market availability 보정 sweep:

- 목적: 자동 자원 +1 없이, 유저가 아직 성장 축을 얻지 못한 구간에서 마켓 등장 확률/슬롯 노출만 보정하면 delayed route 병목이 줄어드는지 확인한다.
- 전제:
  - 자원 +1, Pack, Tarot, Planet, Jester, Item은 무료 지급하지 않는다.
  - 게임이 유저 대신 구매/장착/사용하지 않는다.
  - bot 선택은 “유저가 그 후보를 고를 가능성”을 보는 proxy일 뿐이다.
  - 실제 적용값은 market 후보 등장 범위와 weight로만 번역한다.
- 코드 보강:
  - `shop_slot_market_v10`: 미획득 성장축 강보정. S3~S5/S6~S8에서 resource, discard, Tarot, Pack 후보 노출과 선택 proxy를 강하게 올린다.
  - `shop_slot_market_v11`: 미획득 성장축 약보정. S3~S5 슬롯 수와 후보 노출은 늘리되, bot 선택 utility 보정은 강제하지 않는다.
  - summary-only에서도 `market_shop_slot_counts`를 기록해 raw 없이 후보 노출 빈도를 볼 수 있게 했다.
- 실행:
  - v66: `python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 800 --jobs 4 --summary-only --out-prefix logs/sim/ml_sweep_market_availability_v66_r800 --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3,base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068,base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070 --market-profiles shop_slot_market_v9,shop_slot_market_v10 --loadout-ids progression_route_delayed,progression_route_balanced,progression_route_sustain,progression_route_power`
  - v67: `python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 800 --jobs 4 --summary-only --out-prefix logs/sim/ml_sweep_market_availability_v67_r800 --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3,base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068,base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070 --market-profiles shop_slot_market_v9,shop_slot_market_v11 --loadout-ids progression_route_delayed,progression_route_balanced,progression_route_sustain,progression_route_power`
- 결과 파일:
  - `logs/sim/ml_sweep_market_availability_v66_r800_summary.json`
  - `logs/sim/ml_sweep_market_availability_v66_r800_report.md`
  - `logs/sim/ml_sweep_market_availability_v67_r800_summary.json`
  - `logs/sim/ml_sweep_market_availability_v67_r800_report.md`

v66 sequence aggregate:

| experiment | market | path clear | avg turn | 주요 실패 |
|---|---|---:|---:|---|
| base_weighted_v3 | v9 | 58.4% | 1346.5 | S8 boss, S1 boss, S5 boss, S6 boss |
| base_weighted_v3 | v10 | 51.8% | 1304.6 | S5 boss, S1 boss, S8 boss, S4 boss |
| late_boss_068 | v9 | 59.1% | 1329.1 | S1 boss, S5 boss, S8 boss, S6 boss |
| late_boss_068 | v10 | 54.2% | 1302.1 | S5 boss, S1 boss, S4 boss, S8 boss |
| late_boss_070 | v9 | 58.1% | 1324.3 | S1 boss, S5 boss, S8 boss, S6 boss |
| late_boss_070 | v10 | 53.6% | 1303.7 | S5 boss, S1 boss, S4 boss, S8 boss |

v66 판정:

- `shop_slot_market_v10`은 실패다.
- 후보 노출 자체는 늘었다. 예: base 기준 slot count에서 `voucher_resource`는 v9 1.0% 선택에서 v10 26.5% 선택으로 급증했다.
- 하지만 이건 “유저가 필요한 후보를 살 수 있게 등장시킨다”를 넘어, bot proxy가 자원 후보를 과도하게 고르게 만든 것이다.
- 결과적으로 path clear는 내려갔고, S5 boss 실패가 다시 커졌다.
- 결론: 미획득 성장축 보정은 허용하되, 보정은 약해야 한다. 특히 resource/voucher 계열을 점수 성장 후보보다 앞세우면 턴은 줄어도 경로 생존이 깨진다.

v67 sequence aggregate:

| experiment | market | path clear | avg turn | 주요 실패 |
|---|---|---:|---:|---|
| base_weighted_v3 | v9 | 58.3% | 1343.7 | S8 boss, S1 boss, S5 boss, S6 boss |
| base_weighted_v3 | v11 | 56.3% | 1321.1 | S8 boss, S1 boss, S5 boss, S6 boss |
| late_boss_068 | v9 | 58.9% | 1328.1 | S1 boss, S5 boss, S8 boss, S4 boss |
| late_boss_068 | v11 | 58.9% | 1321.1 | S1 boss, S5 boss, S8 boss, S4 boss |
| late_boss_070 | v9 | 58.0% | 1323.3 | S1 boss, S5 boss, S8 boss, S6 boss |
| late_boss_070 | v11 | 58.5% | 1324.9 | S1 boss, S8 boss, S5 boss, S6 boss |

v67 delayed route:

| experiment | market | delayed path clear | avg turn | 주요 실패 |
|---|---|---:|---:|---|
| base_weighted_v3 | v9 | 39.1% | 1282.7 | S5 boss, S6 boss, S1 boss, S5 big |
| base_weighted_v3 | v11 | 38.1% | 1260.0 | S5 boss, S6 boss, S1 boss, S5 big |
| late_boss_068 | v9 | 43.6% | 1322.7 | S5 boss, S6 boss, S1 boss, S5 big |
| late_boss_068 | v11 | 41.9% | 1262.0 | S5 boss, S6 boss, S1 boss, S4 boss |
| late_boss_070 | v9 | 42.8% | 1318.3 | S5 boss, S6 boss, S1 boss, S5 big |
| late_boss_070 | v11 | 41.9% | 1265.5 | S5 boss, S6 boss, S1 boss, S5 big |

v67 후보 노출/선택 해석:

- v11은 v10의 과도한 `voucher_resource` 선택을 줄였다.
  - base 기준 resolved 선택 비율:
    - v9 `voucher_resource`: 1.0%
    - v10 `voucher_resource`: 26.5%
    - v11 `voucher_resource`: 0.9%
- v11은 후보 노출에서는 Tarot/Pack 쪽을 늘렸지만, 최종 선택은 기존 score growth 중심 구조를 유지했다.
- battle aggregate는 v9/v11이 거의 같다.
  - late_boss_068: v9 clear 97.8%, turn 70.0, deck exhausted 0.8%
  - late_boss_068: v11 clear 97.8%, turn 69.9, deck exhausted 0.8%
- 하지만 sequence path clear는 v9가 여전히 더 안정적이거나 동률이다.

v66/v67 결론:

- 현재 실제 기준 후보는 `shop_slot_market_v9 + late_boss_068`을 유지한다.
- `shop_slot_market_v11 + late_boss_070`은 약보정 대안으로 남길 수 있지만, v9를 명확히 이기지 못했다.
- market availability만으로 delayed route를 충분히 구제하지 못한다.
- delayed route의 S5/S6 boss 병목은 “성장 후보가 안 나온다”보다 “S3~S5까지 점수 성장 축을 유저가 충분히 선택하지 않으면 이후 구간이 막힌다”에 가깝다.
- 따라서 실제 레벨링 테이블 방향은 다음과 같다.
  - S3~S5: resource 후보를 과도하게 밀지 않는다. score growth, Planet, Uncommon/Rare Jester, Tarot/Pack을 균형 있게 둔다.
  - resource/voucher 후보는 보조축이다. 고갈 방지에는 필요하지만 선택이 과하면 boss clear가 떨어진다.
  - S6~S8: late boss target은 `late_boss_068` 또는 `late_boss_070` 수준에서 보되, 후반 돌파 후보는 v9처럼 rare/planet 중심을 유지한다.
  - 보스 target을 더 낮추는 것보다, S1~S5 구간에서 “초반 전법만으로 S6 이후까지 밀고 가는 루트”를 막고 성장 선택 필요성을 유지해야 한다.

v66/v67 후속 체크리스트:

- [x] `shop_slot_market_v10` 강보정 profile을 추가한다.
- [x] summary-only에 `market_shop_slot_counts`를 추가한다.
- [x] v66 r800 sweep을 완료한다.
- [x] v10 과보정 문제를 확인한다.
- [x] `shop_slot_market_v11` 약보정 profile을 추가한다.
- [x] v67 r800 sweep을 완료한다.
- [x] v9/v11 비교를 문서화한다.
- [x] 다음 작업: 실제 레벨링 목표 후보를 `shop_slot_market_v9 + late_boss_068` 기준으로 고정하고, S1~S2 / S3~S5 / S6~S8 3구간 목표표 초안을 만든다.

v68 3구간 레벨링 목표표 초안:

- 목적: 지금까지의 sweep 결과를 “실제 UI/상점/전투 구현 전 기준점”으로 고정한다.
- 기준 후보:
  - experiment: `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068`
  - market: `shop_slot_market_v9`
  - 이유: 자동 자원 지급 없이 v67 기준 path clear 58.9%, battle clear 97.8%, avg battle turn 70.0, deck exhausted 0.8%로 가장 무난하다.
  - `shop_slot_market_v11 + late_boss_070`은 약보정 대안으로 남기되, 기준값으로 고정하지 않는다.

목표 점수 초안:

| 구간 | station | small | big | boss | boss proxy 예시 | 의도 |
|---|---:|---:|---:|---:|---|---|
| early | S1 | 257 | 284 | 285 | repeat_rank_pressure_v4 | 시작 직후 재미를 주되 S1 boss는 첫 gate로 유지 |
| early | S2 | 372 | 431 | 439 | face_tile_dampener | S1 전법만으로 간신히 넘길 수 있지만 성장 선택 없이는 S3 이후가 막히게 유도 |
| mid | S3 | 463 | 537 | 547 | repeat_rank_pressure_v4 | hand/resource/shape 성장 후보가 필요해지는 첫 구간 |
| mid | S4 | 580 | 672 | 685 | all_score_dampener | 단순 초반 조합의 한계가 보이게 하는 중간 gate |
| mid | S5 | 725 | 841 | 857 | repeat_rank_pressure_v4 | delayed route의 핵심 병목. 점수 성장축 선택을 요구 |
| late | S6 | 923 | 1112 | 1121 | all_score_dampener | 중반 성장 선택이 없으면 boss에서 멈추는 전환점 |
| late | S7 | 1154 | 1391 | 1401 | resource_squeeze | rare/planet/late breaker 후보의 의미를 살리는 구간 |
| late | S8 | 1441 | 1738 | 1739 | confirm_count_tax_v2 | 최종 검증. boss는 big보다 항상 높게 유지하되 제약으로 체감 난도 확보 |

구간별 market weight 방향:

| 구간 | 후보 노출 방향 | 피해야 할 것 |
|---|---|---|
| S1~S2 | Common Jester, shape fix, 소량 Pack/Tarot, 낮은 확률 Rare/Legendary | 무료 아이템, 자동 자원 +1, 초반 빌드가 후반까지 그대로 통하는 구조 |
| S3~S5 | Uncommon Jester, Planet, Tarot/Pack, 점수 성장 Jester, 보조 resource 후보 | resource/voucher가 score growth보다 앞서는 과보정 |
| S6~S8 | Rare/late breaker, Planet, boss bridge, 제한적 resource 보조 | 후반 boss target만 계속 낮춰서 성장 선택 필요성을 지우는 구조 |

v68 판정:

- 현재 기준은 “유저가 성장 선택을 잘 했을 때 안정적이고, 초반 전법만 고집하면 S3~S5 또는 S6~S8에서 막히는” 방향을 유지한다.
- 레벨링 테이블은 고정 지급표가 아니다. station별 target score와 market candidate weight/range의 초안이다.
- 실제 구현으로 넘어갈 때 필요한 것은 다음 3가지다.
  - UI 상점이 Jester/Item/Pack/Tarot/Planet 후보를 슬롯과 rarity/weight로 보여줄 수 있어야 한다.
  - battle UI가 boss proxy 제약을 유저가 이해할 수 있게 표시해야 한다.
  - simulator/CLI가 실제 UI 선택지와 같은 후보 id/weight를 사용해 재검증할 수 있어야 한다.

v68 후속 체크리스트:

- [x] 기준 후보를 `shop_slot_market_v9 + late_boss_068`로 고정한다.
- [x] S1~S8 small/big/boss target 초안을 문서화한다.
- [x] 구간별 market weight 방향을 문서화한다.
- [x] 다음 작업: 이 초안을 실제 구현 전환 체크리스트로 분리한다. UI/상점/전투/CLI 연결 중 어떤 코드가 필요한지 파일 단위로 나눈다.

v69 실제 구현 전환 체크리스트 초안:

- 전제: 아직 실제 구현에 들어간 것이 아니다. 아래는 “어떤 파일을 건드려야 하는가”를 분리한 작업 목록이다.
- 원칙:
  - 레벨링 테이블은 고정 지급이 아니다.
  - 유저가 직접 상점에서 성장 후보를 선택해야 한다.
  - 자동 자원 +1, 무료 아이템, 숨은 보정은 넣지 않는다.

1. Target score / blind 배치

- 후보 파일:
  - `lib/services/blind_selection_spec.dart`
  - `lib/services/blind_selection_setup.dart`
  - `test/services/blind_selection_setup_test.dart`
- 할 일:
  - v68 target score 초안을 실제 station/blind 생성 규칙으로 옮길 수 있는지 확인한다.
  - small < big < boss 관계를 모든 station에서 유지한다.
  - S1~S2, S3~S5, S6~S8 구간별 score multiplier를 코드에 직접 박기 전에, 이름 있는 profile/table로 분리한다.
- 완료 기준:
  - S1~S8 target table snapshot test가 생긴다.
  - 기존 저장/런 구조를 바꾸지 않는다.

2. Market 후보 weight / range

- 후보 파일:
  - `lib/logic/rummi_poker_grid/jester_meta.dart`
  - `lib/logic/rummi_poker_grid/rummi_market_facade.dart`
  - `lib/providers/features/rummi_poker_grid/game_session_notifier.dart`
  - `test/logic/rummi_market_facade_test.dart`
  - `test/providers/game_session_notifier_test.dart`
- 할 일:
  - `shop_slot_market_v9`를 실제 catalog 고정값이 아니라 station band별 후보 weight table로 번역한다.
  - Jester/Item 후보만 먼저 실제 runtime에 연결하고, Pack/Tarot/Planet은 UI 흐름 없이는 바로 연결하지 않는다.
  - Rare/Legendary는 초반 0%로 막지 않는다. 다만 매우 낮은 weight로 둔다.
  - 미획득 성장축 보정은 v11 수준의 약보정만 허용한다.
- 완료 기준:
  - market row가 같은 station/seed에서 deterministic하다.
  - 후보는 등장만 하며, 구매는 기존 `buyShopOffer`/`buyItemOffer` 흐름을 거친다.

3. Boss 제약 runtime

- 후보 파일:
  - `lib/logic/rummi_poker_grid/boss_modifier.dart`
  - `lib/logic/rummi_poker_grid/rummi_battle_facade.dart`
  - `lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart`
  - `test/logic/rummi_session_test.dart`
  - `test/providers/game_session_notifier_test.dart`
- 할 일:
  - 현재 runtime이 표현 가능한 색/라인/감점 제약부터 적용 후보로 둔다.
  - face/rank/confirm tax/all-score dampener는 UI preview가 없으면 실제 적용하지 않는다.
  - 보스 제약은 boss score를 낮추는 보정이 아니라 체감 난도/전략 전환 장치로 둔다.
- 완료 기준:
  - 보스 제약 대상이 계산 결과와 UI 표시에서 같은 의미를 가진다.
  - small/big에는 boss-only 제약이 새지 않는다.

4. UI 상점 / 전투 표시

- 후보 파일:
  - `lib/views/blind_select_view.dart`
  - `lib/views/game/widgets/game_jester_widgets.dart`
  - 관련 shop widget: `test/views/game/widgets/game_shop_screen_test.dart`에서 참조하는 GameShop 계열 파일
  - `test/views/game/widgets/game_station_read_path_test.dart`
- 할 일:
  - 상점은 후보 rarity/category/tag를 보여줘야 한다.
  - 전투 UI는 boss 제약이 점수에 미치는 영향을 작은 점/단독 `!`가 아니라 읽을 수 있는 배지로 보여줘야 한다.
  - Pack/Tarot/Planet은 구매 후 선택/소비 흐름이 필요하므로 별도 UI 설계 후 연결한다.
- 완료 기준:
  - 유저가 왜 점수가 덜 들어가는지/왜 특정 후보가 성장 후보인지 화면에서 읽을 수 있다.
  - 설명 텍스트는 말줄임표로 숨기지 않는다.

5. Simulator / CLI 연결

- 후보 파일:
  - `tools/sim/run_balance_sim.dart`
  - `tools/sim/ml_sweep_dataset.py`
  - `test/tools/sim/balance_sim_test.dart`
- 할 일:
  - 실제 market weight table과 simulator의 `market_profile` 용어를 맞춘다.
  - `resolved_market_profile`, `market_shop_slot_counts`, `simulated` 필드를 유지한다.
  - UI 선택지가 생긴 뒤에는 CLI에서 같은 선택지를 seed 기반으로 재현하게 한다.
- 완료 기준:
  - 실제 market table 변경 후 같은 조건의 summary sweep을 다시 돌릴 수 있다.
  - raw 없이도 후보 노출/선택 분포를 summary에서 확인할 수 있다.

v69 후속 체크리스트:

- [x] UI/상점/전투/CLI 연결 작업을 파일 단위로 분리한다.
- [x] 다음 작업: 위 체크리스트 중 “1. Target score / blind 배치”만 작은 작업으로 시작할지, 아니면 실제 구현 전 마지막으로 v68 기준의 full regression sweep을 한 번 더 돌릴지 결정한다.

v70 final regression sweep:

- 목적: `shop_slot_market_v9 + late_boss_068` 기준 후보가 난이도별로 어떤 성격인지 마지막으로 확인한다.
- 기준:
  - experiment: `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068`
  - market: `shop_slot_market_v9`
  - loadout: `progression_route_delayed`, `balanced`, `sustain`, `power`
  - runs: 800
  - summary-only
- 실행 파일:
  - `logs/sim/ml_sweep_final_regression_v70_relaxed_r800_summary.json`
  - `logs/sim/ml_sweep_final_regression_v70_standard_r800_summary.json`
  - `logs/sim/ml_sweep_final_regression_v70_pressure_r800_summary.json`

v70 난이도별 aggregate:

| difficulty | path clear | avg turn | avg attempted steps | battle clear | battle turn | deck exhausted | 주요 실패 |
|---|---:|---:|---:|---:|---:|---:|---|
| relaxed | 82.3% | 1315.8 | 21.67 | 99.2% | 60.7 | 0.1% | S1 boss, S5 boss, S1 big, S8 boss |
| standard | 58.9% | 1328.1 | 18.97 | 97.8% | 70.0 | 0.8% | S1 boss, S5 boss, S8 boss, S4 boss |
| pressure | 20.4% | 1151.7 | 14.59 | 94.5% | 78.9 | 3.3% | S1 boss, S8 boss, S5 boss, S4 boss |

v70 route별 path clear:

| difficulty | delayed | balanced | sustain | power |
|---|---:|---:|---:|---:|
| relaxed | 78.2% | 82.6% | 83.5% | 85.0% |
| standard | 43.6% | 61.9% | 62.9% | 67.2% |
| pressure | 8.5% | 23.0% | 21.8% | 28.2% |

v70 판정:

- relaxed는 초반 재미/성장 체험용 난이도로 성립한다.
- standard는 현재 레벨링 기준으로 유지 가능하지만, delayed route가 43.6%라 “성장 선택을 잘못하면 막히는” 구조가 강하다.
- pressure는 현재 기준으로 실사용 난이도라기보다 stress test다. path clear 20.4%, delayed 8.5%라 초기 출시 기본값으로 쓰면 너무 빡빡하다.
- 따라서 실제 구현 전환 기준은 `standard`를 기본, `relaxed`를 온보딩/초반 재미 기준, `pressure`를 내부 검증/상위 난이도 후보로 분리한다.
- 구현 전환은 target table부터 시작해도 되지만, 상점 UI가 후보 weight/range를 보여주지 못하면 레벨링 의도가 전달되지 않는다.

v70 후속 체크리스트:

- [x] v68 기준 final regression sweep을 난이도별로 완료한다.
- [x] 난이도별 route/battle 병목을 문서화한다.
- [x] 다음 작업: 실제 구현은 `Target score / blind 배치`와 `Market 후보 weight table`을 함께 작은 단위로 시작한다. 단, Pack/Tarot/Planet 선택 UI는 별도 차수로 미룬다.

v71 실제 구현 전환 1차:

- 범위:
  - 실제 저장 구조는 변경하지 않는다.
  - UI shop/Pack/Tarot/Planet 선택 흐름은 아직 변경하지 않는다.
  - target score와 market weight table의 계산 기준만 실제 runtime 쪽으로 옮긴다.
- 변경:
  - `BlindSelectionSpecBuilder`가 S1~S8 standard target table을 직접 사용한다.
  - relaxed/pressure는 이 table에 difficulty multiplier를 적용한다.
  - S8 이후는 아직 실제 구간 밖이므로 마지막 구간에서 완만한 fallback growth만 둔다.
  - `RummiStationBandMarketPolicy` mid 구간에서 score/rank/tile_color 후보가 resource/capacity 후보보다 밀리지 않게 weight를 보정했다.
- 고정한 standard target:

| station | small | big | boss |
|---:|---:|---:|---:|
| S1 | 257 | 284 | 285 |
| S2 | 372 | 431 | 439 |
| S3 | 463 | 537 | 547 |
| S4 | 580 | 672 | 685 |
| S5 | 725 | 841 | 857 |
| S6 | 923 | 1112 | 1121 |
| S7 | 1154 | 1391 | 1401 |
| S8 | 1441 | 1738 | 1739 |

v71 검증:

- `flutter test test/services/blind_selection_setup_test.dart test/providers/game_session_notifier_test.dart`
- `flutter test test/logic/rummi_market_facade_test.dart test/services/blind_selection_setup_test.dart test/providers/game_session_notifier_test.dart`
- `flutter test test/tools/sim/balance_sim_test.dart`
- `python3 -m py_compile tools/sim/ml_sweep_dataset.py`
- `git diff --check`

v71 후속 체크리스트:

- [x] 실제 blind target table을 `BlindSelectionSpecBuilder`에 연결한다.
- [x] S1~S8 target snapshot test를 추가한다.
- [x] provider 초기 target 기대값을 v68 table 기준으로 갱신한다.
- [x] mid market policy가 score growth를 resource보다 우선하는지 테스트한다.
- [x] sim CLI 단위 테스트와 Python sweep script compile을 돌려 target table 변경이 CLI/sim 쪽과 충돌하지 않는지 확인한다.
- [x] CLI 도움말의 market profile 목록에 `shop_slot_market_v11`을 반영한다.
- [x] v71 runtime table 기준으로 짧은 smoke sweep을 한 번 돌려 route/market 지표가 v70 방향과 크게 어긋나지 않는지 확인한다.

v71 smoke sweep:

- 파일:
  - `logs/sim/ml_sweep_runtime_table_v71_smoke_r200_summary.json`
  - `logs/sim/ml_sweep_runtime_table_v71_smoke_r200_report.md`
- 조건:
  - runs: 200
  - difficulty: `standard`
  - experiment: `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068`
  - loadout: `progression_route_balanced`, `progression_route_power`
  - market: `none`, `shop_slot_market_v9`
  - summary-only

| route | market | path clear | avg attempted | avg cleared | avg total turn | top failures |
|---|---|---:|---:|---:|---:|---|
| `progression_route_balanced` | `none` | 49.0% | 18.02 | 17.51 | 1323.3 | S8 boss, S4 boss, S5 boss, S1 boss |
| `progression_route_power` | `none` | 60.0% | 20.70 | 20.30 | 1404.9 | S8 boss, S7 boss, S8 big, S2 big |
| `progression_route_balanced` | `shop_slot_market_v9` | 65.5% | 19.33 | 18.99 | 1350.6 | S1 boss, S8 boss, S4 boss, S1 small |
| `progression_route_power` | `shop_slot_market_v9` | 74.5% | 20.65 | 20.40 | 1347.1 | S1 boss, S8 boss, S1 small, S1 big |

해석:

- v71 runtime target table 연결 후에도 `shop_slot_market_v9 + progression_route_power` 방향은 유지된다.
- `none`은 성장 후보 노출이 없을 때 중후반 boss와 board lock 병목이 다시 커진다.
- `progression_route_power`는 성공률은 좋지만 no-market에서는 turn이 늘어지므로, 실제 구현 기준은 성장 아이템을 직접 지급하는 것이 아니라 S2~S5 market exposure를 충분히 열어 유저가 구매할 수 있게 하는 쪽이다.
- 다음 실험은 자동 보상이 아니라 “미획득 성장축 보정 weight”를 market slot/category/rarity/tag 레벨로 약하게 넣고, 과보정이었던 v10처럼 resource 후보가 과선택되지 않는지 확인한다.

v71 적용 원칙 재확인:

- resource +1, board/hand discard +1, max hand size +1은 자동 지급하지 않는다.
- 해당 후보들은 마켓에 등장해야 하며, 유저가 직접 구매해서 성장해야 한다.
- 특정 구간까지 필요한 성장 축을 얻지 못했을 때의 보정은 직접 지급이 아니라 slot/category/rarity/tag weight를 올리는 방식으로만 허용한다.
- 시뮬 bot 선택은 유저 선택 성향 proxy이며, 실제 레벨링 산출물은 `target score + boss constraint + market candidate availability/weight`다.

다음 차수 메모: UI 보강이 필요한 후보

- UI 없이 1차 적용 가능한 것은 target score, market weight, 기존 색상/라인 boss modifier까지다.
- face/rank/confirm tax/all-score dampener는 UI와 전투 preview가 같이 있어야 유저가 납득할 수 있다.
- Pack/Tarot/Planet 전용 후보도 UI 상점 카테고리, 구매/소비/선택 흐름이 있어야 실제 적용 가능하다.
- 다음 차수에서는 `Boss Constraint Runtime v1`과 Pack/Tarot/Planet 선택 UI를 먼저 보강하고, 그 선택을 CLI/simulator에서 proxy 선택으로 재현하는 방법을 찾아야 한다.
- CLI 연결 방향:
  - 실제 UI 선택지는 `market_profile`의 고정 지급이 아니라 slot/category/rarity/tag weight로 기록한다.
  - 시뮬은 “유저가 특정 성장 루트를 항상 따라온다”가 아니라, 선택 후보와 bot preference proxy가 다른 결과를 낼 수 있게 유지한다.
  - UI에서 드러나는 선택 정보와 simulator의 선택 로그가 같은 단어를 쓰도록 `resolved_market_profile`, `resolved_market_candidate`, `simulated` 같은 필드를 계속 유지한다.

v72 미획득 성장축 market exposure 보정:

- 범위:
  - 실제 저장 구조는 변경하지 않는다.
  - 아이템을 자동 지급하지 않는다.
  - 유저가 필요한 성장축을 아직 얻지 못한 경우, 해당 Jester/Item 후보의 마켓 노출 기회만 올린다.
- 변경:
  - `RummiStationBandMarketPolicy.itemOfferWeight()`에 `missingGrowthTags` 입력을 추가했다.
  - `RummiMarketRuntimeFacade`가 현재 보유 아이템 태그를 보고 stage별 missing growth tag를 계산한다.
  - item offer는 일부 확률로 랜덤한 슬롯 하나가 missing growth 후보군을 먼저 보고, 실패하면 일반 weighted pool로 돌아간다.
  - Jester offer도 일부 확률로 랜덤한 슬롯 하나가 missing growth 후보군을 먼저 본다.
  - S3~S5에서는 score/rank/tile_color 축을 우선 확인한다.
  - S4 이후에는 discard/move/safety 축을 보조로 확인한다.
  - S6 이후에는 boss/xmult/legendary 축을 확인한다.
  - 보정은 tag match당 +45, 최대 +90으로 제한한다.
  - focus 발동 확률은 item 기준 S3 35%, S4~S5 45%, S6+ 55%다.
  - Jester focus 확률은 item보다 낮게 두어 S3 25%, S4~S5 35%, S6+ 45%다.
- 이유:
  - 유저를 직접 도와주는 것이 아니라, 필요한 성장 수단이 마켓에 보일 확률만 올린다.
  - v10처럼 resource 후보가 과선택되는 실패를 막기 위해 보정 폭을 낮게 제한했다.
  - 단순 weight 보너스만으로는 후보 풀이 커졌을 때 실제 등장률이 너무 낮을 수 있어, 랜덤 슬롯 focus를 함께 둔다.
  - focus 슬롯을 첫 칸에 고정하면 상점 자리가 고정된 것처럼 보이므로, 슬롯 위치도 stage/reroll/rng에 따라 흔든다.

v72 검증:

- `dart format lib/logic/rummi_poker_grid/jester_meta.dart lib/logic/rummi_poker_grid/rummi_market_facade.dart test/logic/rummi_market_facade_test.dart`
- `flutter test test/logic/rummi_market_facade_test.dart`

v72 후속 체크리스트:

- [x] missing growth tag 보정을 직접 지급이 아닌 item/Jester offer exposure로만 구현한다.
- [x] 보정 상한을 두어 특정 resource 후보 과노출을 막는다.
- [x] 단위 테스트로 score growth 후보만 missing tag 보정을 받는지 확인한다.
- [x] 단위 테스트로 item/Jester offer의 랜덤 슬롯이 missing growth 후보군을 볼 수 있는지 확인한다.
- [x] 핵심 Flutter test와 sim CLI test를 다시 돌려 v72 market exposure 보정이 기존 runtime과 충돌하지 않는지 확인한다.
- [x] v72 exposure 보정이 실제 route/market 성능을 과하게 올리지 않는지 smoke sweep으로 확인한다.

v73 market exposure smoke sweep:

- 목적: v72 missing growth exposure 보정이 `shop_slot_market_v9` route 성능을 과하게 올리는지 확인한다.
- 파일:
  - `logs/sim/ml_sweep_market_exposure_v72_smoke_r200_summary.json`
  - `logs/sim/ml_sweep_market_exposure_v72_smoke_r200_report.md`
  - `logs/sim/ml_sweep_market_exposure_v72_smoke_r200_summary_bottleneck_report.md`
- 조건:
  - runs: 200
  - difficulty: `standard`
  - experiment: `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068`
  - loadout: `progression_route_balanced`, `progression_route_power`
  - market: `none`, `shop_slot_market_v9`
  - summary-only

| route | market | path clear | avg attempted | avg cleared | avg total turn | fail draw | fail board | top failures |
|---|---|---:|---:|---:|---:|---:|---:|---|
| `progression_route_balanced` | `none` | 49.0% | 18.02 | 17.51 | 1323.3 | 46 | 56 | S8 boss, S4 boss, S5 boss, S1 boss |
| `progression_route_power` | `none` | 60.0% | 20.70 | 20.30 | 1404.9 | 34 | 46 | S8 boss, S7 boss, S8 big, S2 big |
| `progression_route_balanced` | `shop_slot_market_v9` | 65.5% | 19.33 | 18.98 | 1350.5 | 21 | 48 | S1 boss, S8 boss, S4 boss, S5 big |
| `progression_route_power` | `shop_slot_market_v9` | 74.5% | 20.65 | 20.39 | 1347.1 | 18 | 34 | S1 boss, S8 boss, S1 small, S3 boss |

S1/S4/S5/S8 battle aggregate:

| market | station | battle clear | avg turn | deck exhausted | board locked |
|---|---:|---:|---:|---:|---:|
| `none` | S1 | 97.2% | 75.1 | 0.6% | 2.2% |
| `none` | S4 | 98.0% | 75.2 | 1.0% | 1.0% |
| `none` | S5 | 98.2% | 64.2 | 1.2% | 0.6% |
| `none` | S8 | 93.2% | 82.6 | 5.2% | 1.6% |
| `shop_slot_market_v9` | S1 | 96.3% | 75.3 | 1.5% | 2.1% |
| `shop_slot_market_v9` | S4 | 98.6% | 71.2 | 0.2% | 1.2% |
| `shop_slot_market_v9` | S5 | 99.0% | 61.5 | 0.3% | 0.7% |
| `shop_slot_market_v9` | S8 | 97.4% | 77.1 | 1.7% | 1.0% |

v73 판정:

- `shop_slot_market_v9`는 path clear를 balanced +16.5%p, power +14.5%p 올렸지만, v71 smoke와 같은 수준이라 v72 exposure 보정이 추가 과보정을 만든 증거는 없다.
- S4/S5/S8 battle aggregate에서 deck exhausted가 낮아지고 평균 turn도 줄어든다. 특히 S8은 clear 93.2% → 97.4%, deck exhausted 5.2% → 1.7%로 개선되어 market exposure의 방향은 유효하다.
- S1은 `shop_slot_market_v9`에서 battle clear가 97.2% → 96.3%로 소폭 낮고, S1 boss 실패가 여전히 top failure다. 초반 병목은 보정 강화보다 S1 boss constraint/초기 target/첫 클리어 골드 보상의 체감 흐름을 따로 봐야 한다.
- 실패 stop reason은 board 쪽이 여전히 더 많다. 다음 튜닝을 한다면 slot focus 확률을 더 올리기보다, 구간별 후보군 availability와 board pressure 완화 후보의 실제 노출/구매 가능성을 먼저 확인한다.
- 현재 수치만으로는 slot focus 확률을 낮출 필요가 없다. 다만 runs 200 smoke이므로 최종 확정 전에는 standard 기준 800+ runs 재검증이 필요하다.

v73 후속 체크리스트:

- [x] UI 변경 전, 저장 구조를 바꾸지 않는 표시 개선 범위를 먼저 확정한다.
- [x] S1 boss 병목은 market 보정 강화가 아니라 boss 제약/target/초반 골드 흐름 중 어느 축인지 분리한다.
- [ ] Pack/Tarot/Planet처럼 구매 후 선택/소비 UI가 필요한 후보는 별도 설계 승인 전까지 실제 runtime에 연결하지 않는다.

v74 market exposure confirm sweep:

- 목적: v73의 200 runs smoke 판정을 standard 800 runs로 확인한다.
- 파일:
  - `logs/sim/ml_sweep_market_exposure_v73_confirm_r800_summary.json`
  - `logs/sim/ml_sweep_market_exposure_v73_confirm_r800_report.md`
- 조건:
  - runs: 800
  - difficulty: `standard`
  - experiment: `base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068`
  - loadout: `progression_route_balanced`, `progression_route_power`
  - market: `none`, `shop_slot_market_v9`
  - summary-only

| route | market | path clear | avg attempted | avg cleared | avg total turn | fail draw | fail board | top failures |
|---|---|---:|---:|---:|---:|---:|---:|---|
| `progression_route_balanced` | `none` | 49.9% | 18.26 | 17.76 | 1343.8 | 201 | 201 | S4 boss, S8 boss, S5 boss, S1 boss |
| `progression_route_power` | `none` | 59.4% | 19.63 | 19.23 | 1336.1 | 137 | 191 | S8 boss, S1 boss, S3 boss, S1 big |
| `progression_route_balanced` | `shop_slot_market_v9` | 62.9% | 19.29 | 18.92 | 1348.5 | 91 | 212 | S1 boss, S8 boss, S4 boss, S5 boss |
| `progression_route_power` | `shop_slot_market_v9` | 67.3% | 20.03 | 19.70 | 1307.6 | 82 | 185 | S1 boss, S8 boss, S1 big, S1 small |

S1/S4/S5/S8 battle aggregate:

| market | station | battle clear | avg turn | deck exhausted | board locked |
|---|---:|---:|---:|---:|---:|
| `none` | S1 | 96.9% | 75.2 | 1.0% | 2.1% |
| `none` | S4 | 97.1% | 75.8 | 1.8% | 1.2% |
| `none` | S5 | 98.1% | 65.6 | 1.0% | 0.9% |
| `none` | S8 | 94.2% | 82.8 | 4.7% | 1.1% |
| `shop_slot_market_v9` | S1 | 96.7% | 75.1 | 1.3% | 2.0% |
| `shop_slot_market_v9` | S4 | 98.2% | 71.1 | 0.3% | 1.5% |
| `shop_slot_market_v9` | S5 | 98.9% | 61.8 | 0.2% | 0.9% |
| `shop_slot_market_v9` | S8 | 96.9% | 77.5 | 2.0% | 1.1% |

v74 판정:

- 800 runs에서도 `shop_slot_market_v9`는 유효하지만 과보정은 아니다. path clear 개선폭은 balanced +13.0%p, power +7.9%p로 200 runs smoke보다 보수적으로 수렴했다.
- S4/S5/S8의 deck exhausted와 turn 개선은 유지된다. 특히 S8은 battle clear 94.2% → 96.9%, deck exhausted 4.7% → 2.0%로 안정화된다.
- S1은 market 유무와 무관하게 96~97%대 battle clear이며, `shop_slot_market_v9`가 S1을 직접 풀어주는 구조는 아니다. 따라서 S1 boss top failure는 보정 부족보다 station path에서 초반 실패가 눈에 띄는 자연스러운 잔여 병목으로 본다.
- board failure는 market 적용 후에도 draw failure보다 많다. 다음 레벨링 조정은 slot focus 확률 상향이 아니라 board pressure 완화 후보의 availability/구매 가능성 검증이 우선이다.
- UI 1차 적용은 저장 구조 없이 진행 가능하다. 단, 보스/제약 설명은 말줄임표로 숨기지 않는다.

v74 UI 적용 범위:

- 허용:
  - 기존 `BlindSelectionSpec`과 `RummiBossModifier` 표시 개선.
  - 기존 Jester/Item offer의 rarity/category/tag 표시 개선.
  - 기존 구매/판매/리롤 흐름 유지.
- 보류:
  - Pack/Tarot/Planet 구매 후 선택/소비 UI.
  - 새 저장 필드가 필요한 market category.
  - face/rank/confirm tax/all-score dampener 같은 새 boss constraint runtime.

v75 Market metadata 표시 1차:

- 범위:
  - 실제 저장 구조는 변경하지 않는다.
  - market 후보 생성/구매/판매/리롤 로직은 변경하지 않는다.
  - Pack/Tarot/Planet 정식 타입은 아직 만들지 않는다.
- 변경:
  - Market 상세 패널의 Jester tag 우선순위를 `rarity → category → condition → effect`로 정리했다.
  - Market 상세 패널의 Item tag 우선순위를 `rarity → placement → timing → effect`로 정리했다.
  - offer 카드 자체에는 과하지 않은 수준의 소형 배지만 추가했다.
    - Jester offer: rarity 색을 입힌 category 배지.
    - Item offer: rarity dot + placement 배지.
  - 상세 패널은 기존 tag wrap을 재사용해 새 UI 구조를 만들지 않았다.
- 확인:
  - Jester offer는 `Common`, `점수형`, `+Chips` 같은 메타가 먼저 보인다.
  - Item offer는 `Common`, `TOOL`, `리롤`, `Discount` 같은 메타가 먼저 보인다.
  - 설명 문구는 기존 `_MarketDescriptionText`의 clip 정책을 유지하며, 말줄임표로 숨기지 않는다.

Pack/Tarot/Planet 이름 치환 메모:

- 현재 실제 runtime 정식 타입은 `Jester`와 `Item`뿐이다.
- `Pack`, `Tarot`, `Planet`, `Voucher`는 `tools/sim/run_balance_sim.dart`에서 시뮬 proxy/category로만 남아 있다.
- 실제 게임용 이름 후보:
  - Pack 대응: `Tile Kit`
  - Tarot 대응: `Pattern Card`
  - Planet 대응: `Hand Manual`
  - Voucher 대응: `Permit` 또는 `Contract`
- 위 후보는 아직 적용하지 않는다. 구매 후 선택/소비 UI와 저장 구조가 필요하므로 별도 설계 승인 후 진행한다.

v75 검증:

- `flutter test test/views/game/widgets/game_shop_screen_test.dart`

이번 단계 결론:

- v61은 실제 구현 검토 기준점으로 쓸 수 있다.
- 다만 “전체 통합 후보를 그대로 구현”하는 단계가 아니라, 먼저 런타임이 이미 표현 가능한 부분만 1차로 옮겨야 한다.
- 실제 구현의 첫 목표는 최종 밸런스 완성이 아니라, 시뮬에서 확인한 방향성이 실제 코드 구조에서도 깨지지 않는지 검증하는 것이다.
