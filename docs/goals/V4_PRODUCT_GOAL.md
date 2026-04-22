# V4 Product Goal

> GCSE role: `Goal`
> Source of truth: V4 제품 목표와 판단 원칙 요약.

Rummi Poker Grid V4의 목표는 현재 작동하는 보드형 로그라이트 전투 프로토타입을 버리지 않고, 장기 제품 구조로 안전하게 확장하는 것이다.

## Core Goal

- 현재 전투 코어를 보호한다.
- V4 target 구조를 current runtime 위에 단계적으로 얹는다.
- 문서가 미래 목표를 현재 구현처럼 오해하게 만들지 않는다.
- 코드와 테스트를 기준으로 작게 검증 가능한 변경을 누적한다.

## Product Direction

- 5x5 보드, 12라인 평가, 즉시 확정, overlap, contributor 제거를 핵심 정체성으로 유지한다.
- Stage 기반 current loop를 Station / Market / Archive / Run Result 같은 장기 구조로 확장한다.
- Jester 중심 프로토타입에서 Item, Market, Archive, Risk Grade, Trial 등으로 콘텐츠 계층을 확장한다.
- active run save와 restart 안정성을 우선 보호한다.

## Decision Rules

- 현재 코드와 충돌하는 장기 목표는 즉시 구현 기준으로 보지 않는다.
- 기본 규칙 변경은 `current_system` 문서와 테스트 갱신 없이 진행하지 않는다.
- 진행률은 `planning`, 기능 계약은 `specs`, 코드 기준 사실은 `current_system`에 둔다.
- archive 문서는 배경 참고이며 최신 기준이 아니다.

## Non-Goals

- One Pair 점수 즉시 변경
- save schema 즉시 교체
- Jester / Item id 변경
- 대규모 symbol rename
- DB 엔진 즉시 도입
