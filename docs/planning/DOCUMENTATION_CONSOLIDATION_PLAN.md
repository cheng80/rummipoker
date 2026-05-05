# Documentation Consolidation Plan

> 문서 성격: next work plan / documentation governance
> 기준 문서: `docs/planning/OVERALL_GOAL_PROGRESS.md`
> 목적: 파편화된 planning/current/archive 문서를 다시 한 기준으로 정리한다.

## 1. 현재 문제

- 레벨링, 경제, ML, 출품 준비 문서가 여러 위치에 나뉘어 있다.
- `ML`이 들어간 과거 파일명과 현재 휴리스틱 파이프라인 문서가 섞여 실제 머신러닝 적용처럼 오해될 수 있다.
- archive 문서와 current 문서의 경계가 약해, 과거 폐기 후보가 현재 정책처럼 읽힐 위험이 있다.
- 공모전 기준 작업 큐와 전체 goal 진도표가 같은 문서에서 항상 동기화되지 않는다.

## 2. 정리 원칙

- current source-of-truth는 `docs/current_system/`와 `docs/planning/OVERALL_GOAL_PROGRESS.md`에 둔다.
- 과거 실험 로그, 폐기 후보, 장기 히스토리는 `docs/archive/`에 둔다.
- 실제 런타임 적용 여부는 `docs/planning/LEVELING_APPLIED_STATUS.md`에 기록한다.
- 경제 실행 계획은 `docs/planning/ECONOMY_LEVELING_PLAN.md`로 유지하되, 완료/보류/탐색 상태를 명확히 적는다.
- 실제 ML 전환 전까지 `ML` 명칭이 있는 문서는 호환 경로 또는 스캐폴딩으로 표시한다.

## 3. 작업 순서

1. 문서 inventory 작성
   - `docs/current_system/`
   - `docs/planning/`
   - `docs/archive/`
   - `analysis/leveling/`

2. source-of-truth 지정
   - 현재 정책
   - 런타임 기준표
   - 적용 상태
   - 경제 계획
   - 공모전 진도
   - ML/휴리스틱 분석 상태

3. archive 이동 후보 분류
   - 오래된 계획
   - 현재 정책과 충돌하는 실험안
   - 완료된 임시 QA 기록
   - 실제 ML이 아닌데 ML 적용처럼 읽히는 과거 보고서

4. 문서 링크 정리
   - current 문서 상단에 기준/후속/과거 문서 링크를 맞춘다.
   - archive 문서에는 현재 기준이 아니라는 표시를 둔다.

5. 공모전 작업 큐 복귀
   - 텍스트 자름/줄바꿈 정책 QA
   - browser/compute QA
   - 출품 후보 smoke

## 4. 완료 조건

- 새 세션에서 `OVERALL_GOAL_PROGRESS.md`만 읽어도 현재 작업 순서를 알 수 있다.
- 레벨링 정책은 `CURRENT_LEVELING_POLICY.md`와 충돌하지 않는다.
- 실제 ML 전환은 미완료 상태로 남고, 스캐폴딩과 본 구현이 분리되어 읽힌다.
- archive 문서를 현재 적용 근거로 오해하지 않는다.
