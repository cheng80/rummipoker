# archive Folder Definition

`docs/archive/`는 최신 source of truth가 아닌 문서를 보관하는 폴더다.

## Purpose

- 과거 설계 문서, 생성 병합본, 과거 프롬프트를 보존한다.
- 현재 문서 체계에서 기준 역할을 잃은 스냅샷과 중복 요약본을 보존한다.
- 현재 판단 기준과 충돌할 때는 최신 문서를 우선한다.
- 삭제 전 근거 추적이 필요한 문서를 격리한다.

## Subfolders

- `legacy/`: 과거 설계와 구현 참고 문서
- `generated/`: 병합본, 스냅샷, 자동 생성 산출물
- `prompts/`: 과거 AI/Codex 지시서와 프롬프트

## Rule

`archive` 문서는 직접적인 구현 기준으로 사용하지 않는다. 필요한 경우 최신 `goals`, `current_system`, `specs`, `planning` 문서로 내용을 승격한 뒤 사용한다.
