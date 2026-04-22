# current_system Folder Definition

`docs/current_system/`는 현재 프로젝트의 맥락과 실제 코드 상태를 설명하는 폴더다.

GCSE 역할: `Context`

이 폴더는 단순 배경 문서가 아니라 코드 기준 작업 재개 패킷이다.

## Purpose

- 현재 프로토타입이 어떻게 동작하는지 설명한다.
- V4 목표와 현재 코드 사이의 차이를 정리한다.
- 새 작업자가 코드를 읽기 전에 필요한 배경을 제공한다.
- 코드 기준 문서만 보고도 다음 작업을 이어갈 수 있게 한다.

## Allowed Documents

- 현재 시스템 개요
- 현재 코드 맵
- 현재 빌드 baseline
- current-to-target gap
- 레거시 결정이 현재 코드에 남긴 영향
- 보호해야 할 코드 규칙과 주요 테스트/검증 진입점

## Not Allowed

- 미래 기능의 확정 스펙
- 최신 진행률
- 작업 체크리스트
- 과거 문서 원문 보관

기능 규칙은 `docs/specs/`, 실행 상태는 `docs/planning/`을 참조한다.

## Minimum Continuation Contents

`current_system`의 핵심 기준 문서는 아래 3개다.

1. `CURRENT_SYSTEM_OVERVIEW.md`
2. `CURRENT_CODE_MAP.md`
3. `CURRENT_TO_V4_GAP.md`

이 3개만 읽어도 코드 작업을 이어갈 수 있어야 한다.

`CURRENT_BUILD_BASELINE.md`는 V4 문서 생성 시점의 상세 baseline에서 분리한 보조 문서다. 작업 재개 기준은 위 3개 문서가 우선이며, baseline 표가 필요할 때만 추가로 확인한다.

`current_system` 문서는 아래 정보를 놓치면 안 된다.

- 현재 런타임 루프와 화면 흐름
- 핵심 모델, provider, service, view의 책임 경계
- 저장/복원 구조와 schema 보호 기준
- 현재 데이터 카탈로그와 loader 위치
- 현재 구현된 기능과 미구현/부분 구현 기능
- 코드 변경 전 확인해야 할 테스트 또는 smoke script

## Maintenance Rule

- 코드 구조가 바뀌면 `CURRENT_CODE_MAP.md`를 함께 갱신한다.
- 구현 상태가 바뀌면 `CURRENT_SYSTEM_OVERVIEW.md`를 함께 갱신한다.
- V4 목표와 현재 구현 사이의 차이가 바뀌면 `CURRENT_TO_V4_GAP.md`를 함께 갱신한다.
- 진행률만 바뀌는 경우에는 `planning` 문서만 갱신한다.
