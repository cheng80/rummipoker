# gstack-codex 사용 요약

## 설치 상태

- 설치 방식: 프로젝트 로컬 설치
- 설치 명령:

```bash
npx gstack-codex@latest init --project
```

- 설치된 버전: `0.2.0`
- 추가된 위치:
  - `AGENTS.md`의 `gstack-codex` 관리 블록
  - `.agents/skills/`의 gstack 스킬 파일들

## 기본 사용법

Codex를 이 프로젝트에서 연 뒤 slash command를 실행한다.

```text
/office-hours
```

slash command가 보이지 않으면 Codex에게 이렇게 요청한다.

```text
office hours를 시작해줘
```

## 자주 쓰는 명령

| 명령 | 용도 |
| --- | --- |
| `/office-hours` | 아이디어를 질문 기반으로 정리 |
| `/plan-ceo-review` | 제품 관점에서 계획 검토 |
| `/plan-eng-review` | 기술 구현 관점에서 계획 검토 |
| `/review` | 변경 사항 리뷰 |
| `/investigate` | 버그 원인 조사 |
| `/qa` | 웹 앱 QA 후 수정 |
| `/qa-only` | 수정 없이 QA 리포트만 작성 |
| `/ship` | 테스트, 리뷰, 릴리즈 흐름 진행 |
| `/gstack-upgrade` | gstack 스킬 업그레이드 |

## 다시 설치/갱신

프로젝트 스킬을 다시 생성하거나 갱신할 때 사용한다.

```bash
npx gstack-codex@latest init --project
```

## 글로벌 설치가 필요한 경우

깨끗한 Codex 전용 환경에서 모든 프로젝트에 공통으로 쓰고 싶을 때만 사용한다.

```bash
npx gstack-codex@latest init --global
```

이 프로젝트는 이미 로컬 설치를 했으므로 보통은 글로벌 설치가 필요 없다.

## 주의사항

- `gstack-codex`가 관리하는 `AGENTS.md` 블록 안은 직접 수정하지 않는다.
- 프로젝트 규칙은 기존 `AGENTS.md` 내용이 우선이며, gstack은 추가 워크플로로 사용한다.
- 공식 README 기준 권장 환경은 Node.js `18.17+`, Codex CLI `0.122.0+`이다.
- 이 PC의 `codex-cli`는 Homebrew cask로 `0.125.0`까지 업데이트했다.

## 참고 링크

- GitHub: https://github.com/phd-peter/gstack-codex
- 설치 문서: https://github.com/phd-peter/gstack-codex/blob/main/docs/install.md
