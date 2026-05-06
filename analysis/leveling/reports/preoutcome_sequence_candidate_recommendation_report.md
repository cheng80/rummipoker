# Pre-Outcome Sequence 후보 추천 리포트

## 최종 결론 요약

- 결론: 전체 경로 모델은 후보 선별 보조 신호로 사용한다. 다만 source split 점수가 낮아졌으므로, 실제 r400 이상 재시뮬레이션으로 확인한 후보만 적용 후보가 된다.
- 핵심 판단: 좋은 마켓 선택(v9)이 마켓 없음(none)보다 balanced와 power 양쪽에서 나아져야 통과다.
- 사용 가능: 어떤 후보를 다음 검증 대상으로 볼지 고르는 보조 판단, 이미 실행한 r400/r800 결과의 우선순위 정리.
- 사용 금지: 모델 예측만 보고 target/boss/market/economy를 자동 변경하는 일.
- 다음 액션: fresh gate와 ML gate가 함께 맞는 후보를 runtime/economy handoff 문서에 연결하고, 부족한 후보는 다시 실험한다.

## 핵심 지표

| 항목 | 현재값 | 이상값/최선 | 판단 |
|---|---:|---:|---|
| MAE | 0.0509 | 0.0000 | 낮을수록 좋다. 한 판 클리어율 예측 오차다. |
| RMSE | 0.0905 | 0.0000 | 큰 오차에 더 민감한 예측 오차다. |
| R2 | 0.9014 | 1.0000 | random split 기준이다. source split과 함께 본다. |
| source split MAE | 0.0582 | 0.0000 | 새 실험 파일을 숨기고 맞힌 오차다. |
| source split RMSE | 0.1120 | 0.0000 | 새 실험 파일에서 큰 오차를 본다. |
| source split R2 | 0.8408 | 1.0000 | 후보 선별 보조 신호로만 쓴다. |

## 현재 후보 상태

쉽게 말하면, `none`은 좋은 마켓 도움 없이 돈 판이고 `v9`는 좋은 마켓 선택을 한 판이다.
우리가 원하는 것은 `v9`가 balanced와 power 둘 다에서 `none`보다 나아지는 것이다.

| 순위 | 후보 요약 | 실제 통과 | ML 통과 | balanced none→v9 | power none→v9 | 점수 |
|---:|---|---:|---:|---:|---:|---:|
| 1 | `runtime_s4_rank_weight_v1_growth_access_confirm_r240` | 1 | 1 | 0.5375→0.5875 (+0.0500) | 0.5583→0.5875 (+0.0292) | 2.8593 |
| 2 | `runtime_s4_rank_weight_v1_growth_access_seed91628_r400` | 1 | 1 | 0.4700→0.5200 (+0.0500) | 0.5375→0.5675 (+0.0300) | 2.7614 |
| 3 | `runtime_s4_rank_weight_v1_growth_access_final_r400` | 1 | 1 | 0.4750→0.5200 (+0.0450) | 0.5375→0.5700 (+0.0325) | 2.7514 |
| 4 | `runtime_s4_rank_weight_v1_growth_access_seed91627_r400` | 1 | 1 | 0.4725→0.5200 (+0.0475) | 0.5400→0.5700 (+0.0300) | 2.7514 |

추가 상승 후보:

| 후보 | 실제 통과 | ML 통과 | balanced none→v9 | power none→v9 | 판단 |
|---|---:|---:|---:|---:|---|
| `runtime_s4_rank_weight_v1_v9_lift_slot_sell_r400` | 1 | 1 | 0.5175→0.6525 (+0.1350) | 0.5625→0.6775 (+0.1150) | 목표 범위 통과, runtime 리롤 비용 정책 검토 필요 |
| `runtime_s4_rank_weight_v1_v9_lift_slot_sell_seed91761_r400` | 1 | 1 | 0.5175→0.6500 (+0.1325) | 0.5650→0.6750 (+0.1100) | 목표 범위 재현, runtime 리롤 비용 정책 검토 필요 |

## 상위 후보

| 순위 | 후보 요약 | 실제 통과 | ML 통과 | balanced none→v9 | power none→v9 | 점수 |
|---:|---|---:|---:|---:|---:|---:|
| 1 | `economy_trace_v1_r20` | 1 | 1 | 0.4500→0.7500 (+0.3000) | 0.6000→0.8000 (+0.2000) | 5.0501 |
| 2 | `economy_gated_v1_r20` | 1 | 1 | 0.4500→0.8000 (+0.3500) | 0.5000→0.6000 (+0.1000) | 4.7154 |
| 3 | `economy_choice_affordable_v1_r20` | 1 | 1 | 0.3000→0.5500 (+0.2500) | 0.5000→0.7000 (+0.2000) | 4.5420 |
| 4 | `economy_budget_v1_r20` | 1 | 1 | 0.3000→0.6000 (+0.3000) | 0.5000→0.6000 (+0.1000) | 4.3846 |
| 5 | `boss_expansion_probe_v1_r80` | 1 | 1 | 0.5000→0.6625 (+0.1625) | 0.5500→0.7125 (+0.1625) | 4.2135 |
| 6 | `ml_sweep_market_exposure_v72_smoke_r200` | 1 | 1 | 0.4900→0.6550 (+0.1650) | 0.6000→0.7450 (+0.1450) | 4.1476 |
| 7 | `ml_sweep_market_exposure_v75_smoke_r200` | 1 | 1 | 0.4900→0.6550 (+0.1650) | 0.6000→0.7450 (+0.1450) | 4.1476 |
| 8 | `ml_sweep_runtime_table_v71_smoke_r200` | 1 | 1 | 0.4900→0.6550 (+0.1650) | 0.6000→0.7450 (+0.1450) | 4.1476 |

## 입력과 산출물

- feature table: `analysis/leveling/generated/features/leveling_preoutcome_sequence_feature_table.csv`
- recommendation csv: `analysis/leveling/models/preoutcome_sequence_candidate_recommendations.csv`
- rows: 3020

## 해석 기준

- fresh gate: 실제 시뮬레이션 결과에서 v9가 none보다 나은지 보는 기준이다.
- ML gate: 모델 예측에서도 v9가 none보다 나은지 보는 기준이다.
- 둘 다 통과하면 다음 적용 후보로 볼 수 있다. 둘 중 하나라도 실패하면 원인을 다시 좁혀야 한다.
