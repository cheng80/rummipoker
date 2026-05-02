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
