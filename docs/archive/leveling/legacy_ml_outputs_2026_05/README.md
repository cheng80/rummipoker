# Legacy ML Outputs 2026-05

이 폴더는 2026-05-29에 active `analysis/leveling/` workspace에서 내린 구 ML/레벨링 산출물이다.

## 판정

- 현재 runtime/catalog/ruleset/bot policy 기준 판단 근거가 아니다.
- 현재 clear rate, 경제 압박, 카드 가치, market availability, ML 추천 결론에 직접 사용하지 않는다.
- 필요한 경우 과거 후보 축, 실패 패턴, 리포트 형식 참고용 `historical prior`로만 사용한다.

## 다시 쓰려면

1. 현재 코드의 runtime/catalog/ruleset/bot policy/feature schema와 산출 당시 조건 차이를 먼저 적는다.
2. 재사용 등급을 `historical prior`, `schema reusable`, `fresh rerun required`로 나눈다.
3. 현재 판단에는 fresh simulation row와 새 모델 결과를 우선한다.

대량 generated CSV와 `logs/sim` 원본은 git 밖 로컬 archive로 옮겼다.
