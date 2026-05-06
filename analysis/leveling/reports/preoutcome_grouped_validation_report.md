# Pre-Outcome Source Split 검증 리포트

## 최종 결론 요약

- 결론: random row split만 보면 과적합/데이터 누수를 과소평가할 수 있다. source_path 단위로 실험 파일을 통째로 가리면 station/tier 점수는 크게 낮아진다.
- station/tier source split: MAE 0.0436, RMSE 0.0899, R2 0.5264.
- sequence/path source split: MAE 0.0582, RMSE 0.1120, R2 0.8408.
- 사용 가능: sequence/path는 후보 선별 보조 신호로 유지한다.
- 사용 주의: station/tier는 구간 위험 힌트로만 보고, 단독 추천 gate로 쓰지 않는다.
- 다음 액션: 향후 ML gate 문구와 문서는 source split 점수를 함께 표기한다.

## 핵심 지표

| 모델 | MAE | RMSE | R2 | Row | Source groups | 판단 |
|---|---:|---:|---:|---:|---:|---|
| station/tier | 0.0436 | 0.0899 | 0.5264 | 44831 | 214 | 구간 힌트 전용 |
| sequence/path | 0.0582 | 0.1120 | 0.8408 | 3020 | 189 | 후보 선별 보조 신호 |

## 산출물

- JSON metrics: `analysis/leveling/models/preoutcome_grouped_validation_metrics.json`
