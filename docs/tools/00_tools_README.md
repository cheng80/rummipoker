# 도구 문서 안내

## 이 폴더는 무엇을 다루나

`docs/tools/`에는 문서, 디자인, 카드·이미지 asset을 만들 때 다시 사용할 수 있는 도구 설명을 모아 둔다. 게임 규칙이나 기능 명세를 대신하는 문서는 아니다.

이 폴더는 현재 코드 사실이나 기능 명세의 source-of-truth가 아니다. 도구 결과를 런타임 정책에 반영할 때는 [문서 경계](../00_docs_README.md)에서 owner를 확인하고, 확정 동작은 관련 `docs/core/*.md`, 미결 결정과 실행 판단은 `docs/planning/*.md`에 갱신한다.

## 문서 구성

- `card_assets/CARD_ITEM_ILLUSTRATION_GUIDE.md`: 카드형 Item/Jester 일러스트 가이드
- `card_assets/CARD_ITEM_IMAGE_PROMPTS.md`: 카드 일러스트 이미지 생성 프롬프트 팩

## 언제 고치나

- asset 생성 방식이나 safe zone 규칙이 바뀌면 `card_assets/` 문서를 갱신한다.
- 특정 시점의 이미지 겹침 검수 결과는 현재 도구 기준이 아니다. 반복 적용할 규칙만 도구 문서로 승격한다.
