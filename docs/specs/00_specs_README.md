# specs Folder Definition

`docs/specs/`은 기능별 명세와 계약만 담는 폴더다.

GCSE 역할: `Spec`

## Purpose

- 게임 규칙, UX 흐름, 저장 구조, 아키텍처 계약을 정의한다.
- 현재 구현과 목표 구현을 구분하되, 최신 진행률이나 코드 현황 원본을 중복 보관하지 않는다.
- 구현자가 코드 변경 시 지켜야 할 기능 기준을 제공한다.

## Allowed Documents

- 전투 규칙
- 런/경제 규칙
- Jester/Item/Market 계약
- Save/Checkpoint/Data 구조
- UI/UX flow
- Technical architecture
- 용어/alias 정책
- 기능별 acceptance rule

## Not Allowed

- 현재 코드 baseline 원본
- 최신 진행률
- 완료 체크
- PR 작업 순서
- 검증 산출물 경로
- decision log
- migration roadmap
- V3/V4 변경 이력 원문
- 전체 문서 병합본

현재 코드 baseline은 `docs/current_system/`, 진행 상태와 구현 순서는 `docs/planning/`, 과거 변경 이력과 병합본은 `docs/archive/`를 참조한다.
