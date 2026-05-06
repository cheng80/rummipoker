# Pre-Outcome 후보 추천 리포트

## 최종 결론 요약

- 결론: 이 추천표는 fresh resimulation 후보를 고르는 참고자료이며 ML 마감 근거가 아니다.
- 1위 후보: `economy_r040_p240_spend_choice` / score 3.2021.
- 사용 가능: 후보 우선순위 정리와 후속 probe 설계.
- 사용 금지: 추천 후보를 runtime target/boss/market/economy 값에 자동 적용.
- NotebookLM 상태: 모델 지표가 사용 수준이 된 뒤 보고서/인포그래픽 source로 재생성한다.
- 다음 액션: 상위 후보를 fresh resimulation으로 검증하고 사람 검토표에 통합한다.
- 주의: `reward 0.40 / price 2.4`, `reward 0.38 / price 2.4` 계열은 이전 expanded boss fresh r120에서 balanced+v9가 none보다 낮아져 적용 보류 중이다.

## 핵심 점수

| 순위 | 후보 | 분류 | 점수 | v9 평균 | none 평균 | 차이 | S1 boss | S8 boss |
|---:|---|---|---:|---:|---:|---:|---:|---:|
| 1 | `economy_r040_p240_spend_choice` | economy | 3.2021 | 0.9896 | 0.9822 | 0.0074 | 0.9843 | 0.9608 |
| 2 | `economy_r038_p240_spend_choice` | economy | 3.1958 | 0.9897 | 0.9824 | 0.0073 | 0.9842 | 0.9638 |
| 3 | `economy_r040_p220_spend_choice` | economy | 3.1642 | 0.9934 | 0.9850 | 0.0083 | 0.9969 | 0.9684 |
| 4 | `current_runtime_trace` | baseline | 2.9997 | 0.9964 | 0.9868 | 0.0096 | 0.9959 | 0.9787 |
| 5 | `early_boss_soft_s1_098_s2_100_s3_100` | target | 2.9997 | 0.9964 | 0.9868 | 0.0096 | 0.9959 | 0.9787 |
| 6 | `market_v9_current_no_economy_change` | market | 2.9997 | 0.9964 | 0.9868 | 0.0096 | 0.9959 | 0.9787 |

## 범위

이 보고서는 실제 ML 전환의 후보 추천 단계다.
모델은 pre-outcome feature만 사용해 후보 grid를 랭킹하지만, 런타임 값은 자동으로 바꾸지 않는다.
추천 후보는 반드시 fresh resimulation과 사람 검토를 거쳐야 한다.

## 입력

- feature table: `analysis/leveling/generated/features/leveling_preoutcome_feature_table.csv`
- recommendation csv: `analysis/leveling/models/preoutcome_candidate_recommendations.csv`

## 상위 후보 상세

| 순위 | 후보 | 분류 | 점수 | v9 평균 | none 평균 | 차이 | S1 boss | S8 boss |
|---:|---|---|---:|---:|---:|---:|---:|---:|
| 1 | `economy_r040_p240_spend_choice` | economy | 3.2021 | 0.9896 | 0.9822 | 0.0074 | 0.9843 | 0.9608 |
| 2 | `economy_r038_p240_spend_choice` | economy | 3.1958 | 0.9897 | 0.9824 | 0.0073 | 0.9842 | 0.9638 |
| 3 | `economy_r040_p220_spend_choice` | economy | 3.1642 | 0.9934 | 0.9850 | 0.0083 | 0.9969 | 0.9684 |
| 4 | `current_runtime_trace` | baseline | 2.9997 | 0.9964 | 0.9868 | 0.0096 | 0.9959 | 0.9787 |
| 5 | `early_boss_soft_s1_098_s2_100_s3_100` | target | 2.9997 | 0.9964 | 0.9868 | 0.0096 | 0.9959 | 0.9787 |
| 6 | `market_v9_current_no_economy_change` | market | 2.9997 | 0.9964 | 0.9868 | 0.0096 | 0.9959 | 0.9787 |

## 해석

- `predicted_market_delta`가 음수인 후보는 좋은 market 선택 proxy가 none보다 나빠질 수 있어 위험하다.
- S1 boss는 entry 안정성을, S8 boss는 후반 압박 보존 여부를 보기 위한 모델상 proxy다.
- 이 점수는 자동 밸런싱 점수가 아니라 fresh resimulation 후보를 고르기 위한 사람 검토 우선순위다.

## 다음 단계

상위 후보 중 economy 후보와 target 후보를 분리해 fresh resimulation을 실행하고, 결과가 정책 위반 없이 안정적인지 확인한다.
