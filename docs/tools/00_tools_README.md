# tools Folder Definition

## Purpose

`docs/tools/`는 문서 제작, 디자인 제작, 카드/이미지 asset 생성처럼 재사용 가능한 작업 도구 문서를 모은다.

이 폴더는 현재 코드 사실이나 기능 명세의 source-of-truth가 아니다. 도구가 생성한 결과를 런타임 정책으로 반영하려면 `docs/current_system/` 또는 `docs/specs/`에 별도로 요약해야 한다.

## Contents

- `huashu-design-codex-usage.md`: Huashu Design Codex 사용법
- `card_assets/CARD_ITEM_ILLUSTRATION_GUIDE.md`: 카드형 Item/Jester 일러스트 가이드
- `card_assets/CARD_ITEM_IMAGE_PROMPTS.md`: 카드 일러스트 이미지 생성 프롬프트 팩

## Update Rule

- asset 생성 방식이나 safe zone 규칙이 바뀌면 `card_assets/` 문서를 갱신한다.
- 특정 시점의 이미지 겹침 검수 결과는 현재 도구 기준이 아니다. 반복 적용할 규칙만 도구 문서로 승격한다.
