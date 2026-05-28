# 레벨링 분석 방법론

## 최종 결론 요약

- 결론: 현재 레벨링 ML은 NotebookLM용 최종 보고서/인포그래픽 source로 재생성할 단계가 아니다.
- 핵심 기준: 회귀 모델은 MAE/RMSE/R2가 실무 사용 수준이 되어야 후보 추천 gate로 인정한다. R2의 이상값은 1.0이고, MAE/RMSE의 이론상 최선은 0.0이다.
- 사용 가능: 현재 문서는 방법론과 gate 기준 source로 사용한다.
- 사용 금지: 현재 scaffold 지표를 production ML이나 최종 밸런스 보고서 근거로 사용.
- 다음 액션: candidate grid 확장, 데이터 증량, MAE/RMSE/R2 재평가, fresh resimulation과 사람 승인 절차를 갖춘다.

## 현재 상태

현재 런타임 레벨링은 학습 모델이 자동 조정하지 않는다. 실제 ML 기반 밸런스 추천도 아직 적용되지 않았다.

현재 적용된 파이프라인은 다음과 같다.

1. Flutter CLI 시뮬레이터가 station/tier/loadout/market/boss 조건별 run 결과를 만든다.
2. summary JSON에서 clear rate, failure reason, score ratio, resource residual, market exposure를 집계한다.
3. 규칙 기반 휴리스틱 라벨이 `too_hard`, `tempo_drag`, `good_playfeel`, `needs_balance_attention` 같은 진단값을 붙인다.
4. 사람이 정책 원칙에 맞게 해석하고 runtime target, boss modifier, market weight 후보로 번역한다.

## ML 전환 목표

실제 ML 전환 목표는 모델이 런타임을 직접 바꾸는 것이 아니다.

모델은 아래 후보를 오프라인에서 추천한다.

- target score multiplier 후보
- boss constraint severity/cycle 후보
- market candidate availability/weight 후보
- reward/price scale 후보

추천 후보는 다시 시뮬레이션으로 검증하고, 사람이 승인한 뒤 코드/데이터에 반영한다.

현재 `analysis/leveling/`에 있는 feature table과 RandomForest 리포트는 이 전환을 위한 준비물이다. outcome-derived feature로 `clear_rate`를 설명하는 baseline이라서, 아직 target score, boss severity, market weight, economy scale 후보를 추천하는 모델이 아니다.

## 리포트 필수 항목

실제 ML 적용 보고서에는 최소한 다음 항목을 포함한다.

- dataset 생성 조건과 run 수
- feature 목록과 target 정의
- 휴리스틱 `silver label` 사용 여부
- train/test split
- 모델 종류와 선택 이유
- metric: 회귀 모델은 최소 MAE, RMSE, R2를 함께 기록한다. 표에는 현재값, 이상값/최선, 실무 사용 기준, 판단을 같이 쓴다.
- feature importance
- 추천 후보와 재시뮬레이션 검증 결과
- 적용하지 않은 후보와 폐기 이유
- 지표가 실무 사용 기준에 부족하면 ML 마감이나 추천 gate 완료로 기록하지 않는다는 판단

## 현재 공백

아직 완료되지 않은 실제 ML 전환 항목:

- 실무 추천 기준을 만족하는 pre-outcome feature 설계
- 추천 가능한 supervised target 정의
- 후보 공간 정의: target multiplier, boss severity, market weight, economy scale
- 충분한 데이터와 MAE/RMSE/R2 품질을 갖춘 모델 추천 후보 생성
- 추천 후보 재시뮬레이션
- 정책 위반 후보 필터링
- 사람 승인 후 runtime 반영
