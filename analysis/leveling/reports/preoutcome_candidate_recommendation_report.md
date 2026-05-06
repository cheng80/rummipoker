# Pre-Outcome 후보 추천 리포트

## 최종 결론 요약

- 결론: 이 추천표는 fresh resimulation 후보를 고르는 참고자료이며 ML 마감 근거가 아니다.
- 1위 후보: `economy_r038_p240_spend_choice` / score 3.2360.
- 사용 가능: 후보 우선순위 정리와 후속 probe 설계.
- 사용 금지: 추천 후보를 runtime target/boss/market/economy 값에 자동 적용.
- NotebookLM 상태: 모델 지표가 사용 수준이 된 뒤 보고서/인포그래픽 source로 재생성한다.
- 다음 액션: 상위 후보를 fresh resimulation으로 검증하고 사람 검토표에 통합한다.

## 핵심 점수

| 순위 | 후보 | 분류 | 점수 | v9 평균 | none 평균 | 차이 | S1 boss | S8 boss |
|---:|---|---|---:|---:|---:|---:|---:|---:|
| 1 | `economy_r038_p240_spend_choice` | economy | 3.2360 | 0.9857 | 0.9793 | 0.0064 | 0.9712 | 0.9555 |
| 2 | `economy_r040_p240_spend_choice` | economy | 3.2140 | 0.9873 | 0.9793 | 0.0081 | 0.9723 | 0.9678 |
| 3 | `economy_r040_p220_spend_choice` | economy | 3.1749 | 0.9889 | 0.9826 | 0.0063 | 0.9732 | 0.9839 |
| 4 | `target_boss_098` | target | 3.0349 | 0.9870 | 0.9793 | 0.0077 | 0.9741 | 0.9800 |
| 5 | `current_runtime_trace` | baseline | 3.0137 | 0.9912 | 0.9849 | 0.0063 | 0.9714 | 0.9912 |
| 6 | `early_boss_soft_s1_098_s2_100_s3_100` | target | 3.0137 | 0.9912 | 0.9849 | 0.0063 | 0.9714 | 0.9912 |

## 범위

이 보고서는 실제 ML 전환의 후보 추천 단계다.
모델은 pre-outcome feature만 사용해 후보 grid를 랭킹하지만, 런타임 값은 자동으로 바꾸지 않는다.
추천 후보는 반드시 fresh resimulation과 사람 검토를 거쳐야 한다.

## 입력

- feature table: `analysis/leveling/data/features/leveling_preoutcome_feature_table.csv`
- recommendation csv: `analysis/leveling/models/preoutcome_candidate_recommendations.csv`

## 상위 후보 상세

| 순위 | 후보 | 분류 | 점수 | v9 평균 | none 평균 | 차이 | S1 boss | S8 boss |
|---:|---|---|---:|---:|---:|---:|---:|---:|
| 1 | `economy_r038_p240_spend_choice` | economy | 3.2360 | 0.9857 | 0.9793 | 0.0064 | 0.9712 | 0.9555 |
| 2 | `economy_r040_p240_spend_choice` | economy | 3.2140 | 0.9873 | 0.9793 | 0.0081 | 0.9723 | 0.9678 |
| 3 | `economy_r040_p220_spend_choice` | economy | 3.1749 | 0.9889 | 0.9826 | 0.0063 | 0.9732 | 0.9839 |
| 4 | `target_boss_098` | target | 3.0349 | 0.9870 | 0.9793 | 0.0077 | 0.9741 | 0.9800 |
| 5 | `current_runtime_trace` | baseline | 3.0137 | 0.9912 | 0.9849 | 0.0063 | 0.9714 | 0.9912 |
| 6 | `early_boss_soft_s1_098_s2_100_s3_100` | target | 3.0137 | 0.9912 | 0.9849 | 0.0063 | 0.9714 | 0.9912 |

## 해석

- `predicted_market_delta`가 음수인 후보는 좋은 market 선택 proxy가 none보다 나빠질 수 있어 위험하다.
- S1 boss는 entry 안정성을, S8 boss는 후반 압박 보존 여부를 보기 위한 모델상 proxy다.
- 이 점수는 자동 밸런싱 점수가 아니라 fresh resimulation 후보를 고르기 위한 사람 검토 우선순위다.

## 다음 단계

상위 후보 중 economy 후보와 target 후보를 분리해 fresh resimulation을 실행하고, 결과가 정책 위반 없이 안정적인지 확인한다.
