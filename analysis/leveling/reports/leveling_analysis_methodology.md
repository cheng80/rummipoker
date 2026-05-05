# Leveling Analysis Methodology

## Current State

현재 런타임 레벨링은 학습 모델이 자동 조정하지 않는다.

현재 적용된 파이프라인은 다음과 같다.

1. Flutter CLI 시뮬레이터가 station/tier/loadout/market/boss 조건별 run 결과를 만든다.
2. summary JSON에서 clear rate, failure reason, score ratio, resource residual, market exposure를 집계한다.
3. 규칙 기반 휴리스틱 라벨이 `too_hard`, `tempo_drag`, `good_playfeel`, `needs_balance_attention` 같은 진단값을 붙인다.
4. 사람이 정책 원칙에 맞게 해석하고 runtime target, boss modifier, market weight 후보로 번역한다.

## ML Transition Target

실제 ML 전환 목표는 모델이 런타임을 직접 바꾸는 것이 아니다.

모델은 아래 후보를 오프라인에서 추천한다.

- target score multiplier 후보
- boss constraint severity/cycle 후보
- market candidate availability/weight 후보
- reward/price scale 후보

추천 후보는 다시 시뮬레이션으로 검증하고, 사람이 승인한 뒤 코드/데이터에 반영한다.

## Report Requirements

실제 ML 적용 보고서에는 최소한 다음 항목을 포함한다.

- dataset 생성 조건과 run 수
- feature 목록과 target 정의
- 휴리스틱 `silver label` 사용 여부
- train/test split
- 모델 종류와 선택 이유
- metric
- feature importance
- 추천 후보와 재시뮬레이션 검증 결과
- 적용하지 않은 후보와 폐기 이유
