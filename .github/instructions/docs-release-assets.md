---
description: 게임 정본 문서, 계획, 릴리즈, 스토어 이미지와 인포그래픽 작업 규칙
globs: ["README.md", "START_HERE.md", "docs/**/*", "tools/app_store_screenshots/**/*", "tools/imagegen/**/*", "output/**/*", ".agents/skills/**/*.md"]
alwaysApply: false
---

# 문서·릴리즈 자산 규칙

## 문서 체계

- `START_HERE.md`를 최상위 진입점으로 유지하고 다른 router나 active plan으로 대체하지 않는다. 문서 정리 전에 START_HERE의 읽기 순서와 current 참조를 먼저 맞춘다.
- 현재 게임 정본은 `docs/core/`의 `GAME_DESIGN`, `GAME_RULES`, `RUN_ECONOMY`, `UI_UX`, `CONTENT_SYSTEM`, `SAVE_DATA`, `SYSTEM_ARCHITECTURE`다. 코드·데이터·테스트 근거 없이 새 규칙을 단정하지 않는다.
- `docs/release/`는 build, deploy, store metadata, screenshot, infographic 전용이며 게임 역기획 정본과 합치지 않는다. release 작업에서도 게임 설명은 `docs/core/`를 참조한다.
- 표와 catalog snapshot 같은 기계 파생물은 `docs/generated/`에 두고 원본처럼 수동 편집하지 않는다.
- `docs/superpowers/specs/**`와 `docs/superpowers/plans/**`는 선택적 스킬 산출물로 허용하되 제품 정본이나 registry 대상으로 취급하지 않는다. 확정된 계약과 실행 상태는 담당 core·planning 문서에 반영한다.

## Current, planning, archive

- current 문서에는 post-contest runtime 고도화만 활성 작업으로 표시한다. 공모전·과거 ML/LLM autoplay·구 leveling 결과는 closed history 또는 historical prior로 분리한다.
- `docs/planning/ACTIVE_EXECUTION_PLAN.md`에 현재 실행 판단을 모으고 `OPEN_DECISIONS.md`에는 실제 미정 사항만 둔다. 계획 첫 화면에는 결론, 다음 작업, Done 기준, 위험·보류를 먼저 쓴다.
- archive 이동 전 START_HERE, README, core, planning, 코드와 테스트의 참조를 확인한다. 고유 근거는 current 문서로 승격하고, archive 밖 문서에 폐기 경로를 active dependency처럼 남기지 않는다.
- 문서·probe·scaffold·추천표를 `완료`로 쓰지 않는다. runtime 반영과 검증이 없으면 `후보`, `보류`, `탐색 완료`, `not closed`로 표시한다.

## 보고서와 분석

- 사람이 읽는 보고서는 한국어를 기본으로 하고 식별자·metric·경로만 원문을 유지한다. 첫 화면에 결론, 핵심 수치, 사용 가능 여부, 다음 행동을 둔다.
- ML 지표는 현재값과 함께 이상값 또는 이론상 최선, target 범위, 실무 기준을 적는다. 품질이 부족하면 NotebookLM·외부 발표 재가공보다 fresh data와 재평가를 우선한다.
- 실험 약어만 나열하지 말고 게임에서 무엇을 뜻하는지, 왜 비교하는지, 다음 결정이 무엇인지 짧게 설명한다. 구 데이터는 schema/runtime/catalog 차이를 감사한 뒤 `historical prior`, `schema reusable`, `fresh rerun required`로 구분한다.

## 릴리즈·시각 자산

- App Store/Play Store screenshot은 모바일 safe area의 실제 최종 플레이 화면을 주 피사체로 쓴다. debug 버튼·라벨·QA 메뉴·desktop 여백·빈 상태를 제출물에 남기지 않고 export 결과를 눈검증한다.
- screenshot fixture는 최종 화면과 동일한 장면을 안정적으로 만드는 데만 쓰며 debug chrome은 숨긴다. 화면 변경 뒤 기존 캡처를 재사용하지 않는다.
- 인포그래픽 HTML은 구조화 원천과 관계도만 제공한다. 최종물 요청 시 HTML screenshot으로 대체하지 않고 지정된 poster/image-generation 경로를 사용한다.
- Rummi Poker 인포그래픽 제목에 `Grid`를 붙이지 않는다. 포커는 족보 차용으로 설명하고 시각 예시는 숫자·색의 루미큐브식 tile을 쓴다. 기존 이미지의 일부만 바꾸라는 요청은 다른 구성·문구를 재설계하지 않는다.
- build, deploy, store 제출, 외부 업로드는 명시적 요청이 있을 때만 수행한다. 실제 실행하지 않은 검증을 통과로 기록하지 않는다.

## 유지보수

- `.agents/skills` 안내는 repository root 기준 상대 경로를 쓴다. 개인 홈 절대 경로를 문서나 스크립트에 고정하지 않는다.
- 교정 규칙은 루트 `AGENTS.md`에 누적하지 말고 이 파일의 기존 항목과 중복을 제거해 갱신한다.
