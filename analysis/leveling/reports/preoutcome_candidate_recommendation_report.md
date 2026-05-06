# Pre-Outcome 후보 추천 리포트

## 최종 결론 요약

- 결론: 이 추천표는 high-confidence row 기준 fresh resimulation 후보를 고르는 참고자료이며 ML 마감 근거가 아니다.
- 1위 후보: `runtime_s4_rank_growth_access_current` / score -1.1435.
- 사용 가능: 후보 우선순위 정리와 후속 probe 설계.
- 사용 금지: 추천 후보를 runtime target/boss/market/economy 값에 자동 적용.
- NotebookLM 상태: source split 기준 station/tier가 힌트 전용이므로 아직 보고서/인포그래픽 재생성 단계가 아니다.
- 다음 액션: 상위 후보를 fresh resimulation으로 검증하고 사람 검토표에 통합한다.

## 핵심 점수

| 순위 | 후보 | 분류 | 통과 | 점수 | v9 평균 | none 평균 | 차이 | S1 boss | S8 boss |
|---:|---|---|---:|---:|---:|---:|---:|---:|---:|
| 1 | `runtime_s4_rank_growth_access_current` | runtime_handoff | 0 | -1.1435 | 0.8533 | 0.8834 | -0.0301 | 0.8711 | 0.6727 |
| 2 | `runtime_s4_rank_growth_access_slot_sell` | runtime_handoff_probe | 0 | -2.3012 | 0.8757 | 0.8947 | -0.0189 | 0.8637 | 0.7609 |
| 3 | `economy_r040_p220_spend_choice` | economy | 0 | -2.3151 | 0.8582 | 0.8777 | -0.0195 | 0.8746 | 0.7779 |
| 4 | `economy_r040_p240_spend_choice` | economy | 0 | -2.3170 | 0.8582 | 0.8777 | -0.0195 | 0.8736 | 0.7779 |
| 5 | `economy_r038_p240_spend_choice` | economy | 0 | -2.3189 | 0.8576 | 0.8777 | -0.0201 | 0.8736 | 0.7779 |
| 6 | `current_runtime_trace` | baseline | 0 | -2.3744 | 0.8650 | 0.8810 | -0.0160 | 0.8617 | 0.7249 |

## 범위

이 보고서는 실제 ML 전환의 후보 추천 단계다.
모델은 pre-outcome feature만 사용해 후보 grid를 랭킹하지만, 런타임 값은 자동으로 바꾸지 않는다.
추천 후보는 반드시 fresh resimulation과 사람 검토를 거쳐야 한다.

## 입력

- feature table: `analysis/leveling/generated/features/leveling_preoutcome_feature_table.csv`
- recommendation csv: `analysis/leveling/models/preoutcome_candidate_recommendations.csv`
- source rows: 248248
- rows before filter: 248248
- training rows: 44831
- max rows: 0
- min run count: 80
- target: `clear_rate_smoothed`

## 상위 후보 상세

| 순위 | 후보 | 분류 | 통과 | 점수 | v9 평균 | none 평균 | 차이 | S1 boss | S8 boss |
|---:|---|---|---:|---:|---:|---:|---:|---:|---:|
| 1 | `runtime_s4_rank_growth_access_current` | runtime_handoff | 0 | -1.1435 | 0.8533 | 0.8834 | -0.0301 | 0.8711 | 0.6727 |
| 2 | `runtime_s4_rank_growth_access_slot_sell` | runtime_handoff_probe | 0 | -2.3012 | 0.8757 | 0.8947 | -0.0189 | 0.8637 | 0.7609 |
| 3 | `economy_r040_p220_spend_choice` | economy | 0 | -2.3151 | 0.8582 | 0.8777 | -0.0195 | 0.8746 | 0.7779 |
| 4 | `economy_r040_p240_spend_choice` | economy | 0 | -2.3170 | 0.8582 | 0.8777 | -0.0195 | 0.8736 | 0.7779 |
| 5 | `economy_r038_p240_spend_choice` | economy | 0 | -2.3189 | 0.8576 | 0.8777 | -0.0201 | 0.8736 | 0.7779 |
| 6 | `current_runtime_trace` | baseline | 0 | -2.3744 | 0.8650 | 0.8810 | -0.0160 | 0.8617 | 0.7249 |

## 해석

- `predicted_market_delta`가 음수인 후보는 좋은 market 선택 proxy가 none보다 나빠질 수 있어 위험하다.
- S1 boss는 entry 안정성을, S8 boss는 후반 압박 보존 여부를 보기 위한 모델상 proxy다.
- 이 점수는 자동 밸런싱 점수가 아니라 fresh resimulation 후보를 고르기 위한 사람 검토 우선순위다.
- `runtime_s4_rank_growth_access_slot_sell`은 실제 r400 multi-seed에서는 목표 통과지만, station/tier 평균 예측에서는 아직 통과가 아니다. 그래서 이 표만으로 적용하지 않고 sequence/path 추천표와 실제 r400 결과를 함께 본다.

## 다음 단계

상위 후보 중 economy 후보와 target 후보를 분리해 fresh resimulation을 실행하고, 결과가 정책 위반 없이 안정적인지 확인한다.
