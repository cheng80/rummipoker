# 10. Terminology & Alias Policy

> 문서 성격: terminology policy
> 코드 반영 상태: current names retained
> 핵심 정책: 플레이어-facing 용어와 코드 심볼을 분리해서 단계 전환한다.

## 1. Naming Problem

[CURRENT]

현재 코드에는 prototype/legacy 용어가 남아 있다.

예:

- `stage`
- `blind`
- `scoreTowardBlind`
- `confirmAllFullLines`
- `discardsRemaining` alias

하지만 실제 게임 의미는 이미 다음에 가깝다.

- stage = 하나의 전투 노드
- blind = 해당 전투 목표와 자원 상태
- confirmAllFullLines = scoring line 즉시 확정

## 2. Alias Table

[V4_DECISION]

| Current Code Term | V4 Canonical Concept | 전환 정책 |
|---|---|---|
| Stage | Station | UI 먼저, 코드 나중 |
| Blind | Station Objective / Combat Objective | 코드 유지 |
| `RummiBlindState` | `StationCombatState` 후보 | rename 보류 |
| `scoreTowardBlind` | `scoreTowardStation` 후보 | save adapter 전까지 유지 |
| `confirmAllFullLines` | `confirmScoringLines` | wrapper 추가 후 점진 전환 |
| Board Discard | Board Discard | 유지 |
| Hand Discard | Hand Discard | 유지 |
| Jester | Jester | 유지 |
| Shop | Market | UI는 단계 전환, 내부는 유지 |
| Stage Start Snapshot | Station Checkpoint | 개념 전환, 저장 구조 보호 |

## 3. Current / UI / Target 구분

[MIGRATION]

| 층 | 지금 써도 되는 용어 | 비고 |
|---|---|---|
| 코드 내부 | stage, blind | 유지 |
| 저장 DTO | stageStartSession, blind | 유지 |
| 개발 문서 current | stage/blind + alias | 둘 다 표기 |
| 플레이어 UI | Stage 또는 Station | 단계 실험 가능 |
| target docs | Station, Station Objective | target 명칭 |

## 4. Code Rename Rules

[V4_DECISION]

코드 rename은 다음 조건 전까지 금지한다.

- save/load golden test 존재
- provider tests 존재
- activeScene restore tests 존재
- old save migration adapter 존재
- UI copy 전환 완료
- current-to-target alias가 문서화됨

금지 예:

```text
한 PR에서 RummiBlindState rename + save schema 변경 + Station economy 도입
```

허용 예:

```text
새 confirmScoringLines 메서드 추가 + 기존 confirmAllFullLines wrapper 유지
```

## 5. Documentation Phrase Rules

[V4_DECISION]

문서에서 다음 표현을 피한다.

- “현재 구현은 5장 완성을 기다린다.”
- “One Pair는 현재 10점이다.”
- “V4는 Drift/SQLite를 즉시 사용한다.”
- “Station 구조가 현재 구현되어 있다.”
- “Blind 이름은 즉시 제거한다.”

대신 다음처럼 쓴다.

- “현재는 부분 줄 평가와 즉시 확정을 사용한다.”
- “One Pair는 현재/V4 기본 모두 0점 dead line이다.”
- “DB 계층은 target이며 active run save v2를 즉시 대체하지 않는다.”
- “Station은 target 메타 용어이고 current code는 stage/blind 명칭을 유지한다.”

## 6. Player-facing Copy Target

[TARGET]

장기 UI 문구 예:

| Current UI | Target UI |
|---|---|
| Stage 1 | Station 1 |
| 목표 점수 | Station Goal |
| 보상 | Reward |
| 확정 | Confirm |
| 보드 버림 | Board Discard |
| 손패 버림 | Hand Discard |
| 상점 | Market |
| 다음 스테이지 | Next Station |

[V4_DECISION]

`Confirm`, `Board Discard`, `Hand Discard`, `Jester`는 게임 규칙 이해에 직접 중요하므로 무리하게 바꾸지 않는다.
