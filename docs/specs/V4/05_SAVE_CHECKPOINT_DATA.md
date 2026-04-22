# 05. Save, Checkpoint & Data Architecture

> 문서 성격: 저장/체크포인트/데이터 계약
> 코드 반영 상태: active run save v2 implemented, DB/archive target not implemented
> 핵심 정책: 저장 구조는 회귀 비용이 가장 크므로 current save를 보호하고, target data model은 adapter로 확장한다.

현재 save 구현 상세와 코드 위치는 `docs/current_system/CURRENT_CODE_MAP.md`와 `docs/current_system/CURRENT_BUILD_BASELINE.md`를 기준으로 본다.

## 1. Current Boundary Reference

[CURRENT]

현재 구현에서 보호해야 할 사실만 요약한다.

- 저장 단위는 active run snapshot이다.
- payload `schemaVersion`은 2다.
- storage key suffix는 `v1`이지만 payload schema version과 별개다.
- HMAC-SHA256 signature로 payload 무결성을 확인한다.
- active scene은 `battle` / `shop`을 구분한다.
- `stageStartSnapshot`은 현재 stage 시작점 복원을 위한 핵심 구조다.
- continue, invalid save, delete flow는 Title 경로에서 처리한다.

## 2. Save Compatibility Rules

[V4_DECISION]

V4 저장 변경은 아래 규칙을 지켜야 한다.

- active run save v2는 즉시 제거하지 않는다.
- 기존 `ownedJesterIds`는 계속 복원 가능해야 한다.
- Jester id는 삭제하거나 rename하지 않는다.
- `stageIndex`는 Station 전환 후에도 adapter로 해석 가능해야 한다.
- `blind` JSON은 이름을 바꾸기 전에 adapter를 둔다.
- `stageStartSession` / `stageStartRunProgress`는 Station checkpoint로 migration 가능해야 한다.
- 저장 데이터의 서명 검증 실패 시 자동 복구하지 않고 invalid 처리한다.
- save schema 변경은 regression test와 migration adapter 없이 진행하지 않는다.

## 3. Restart / Checkpoint Contract

[V4_DECISION]

인게임 재시작은 run 전체 리셋이 아니다.

```text
현재 stage 시작 시점으로 복원
```

Station 구조에서는 이 의미를 `StationCheckpoint`로 확장한다.

```text
ActiveRunStageSnapshot -> StationCheckpoint
```

복원 대상은 전투 상태와 run progression을 함께 포함해야 한다.

- board / hand / deck pile / eliminated
- runRandom state
- target score / scoreTowardBlind / discard resources
- gold
- owned Jesters
- owned Items
- shop offers
- stateful Jester values
- played hand counts

## 4. Target Domain Data Model

[TARGET]

V4 장기 저장 도메인은 다음으로 나눈다.

```text
ProfileState
- profileId
- settings refs
- unlocks
- collection
- archive summary

ActiveRunState
- runId
- runSeed
- rulesetVersion
- currentSectorIndex
- currentStationIndex
- activeScene
- combatState
- runProgress
- marketState
- checkpointRef

CheckpointState
- runId
- stationIndex
- combatSnapshot
- runProgressSnapshot
- createdAt

RunHistoryRecord
- runId
- startedAt
- endedAt
- result
- reachedStation
- scoreSummary
- ownedContentSummary

ArchiveState
- discoveredContentIds
- bestRuns
- stats
- trials
```

물리 저장 엔진은 지금 확정하지 않는다. 도메인 경계를 먼저 정하고, 구현 엔진은 단계적으로 선택한다.

## 5. Persistence Engine Policy

[V4_DECISION]

- Drift / SQLite / IndexedDB는 target persistence layer 후보일 뿐이다.
- DB 도입은 active run save를 즉시 대체하지 않는다.
- 먼저 read-only mirror 또는 archive-only 저장으로 도입한다.
- active run restore와 archive/stats 저장은 강하게 결합하지 않는다.

권장 순서:

1. current save golden test 추가
2. schemaVersion 2 restore test 추가
3. save corruption test 추가
4. `rulesetVersion` 필드 추가 검토
5. DB read model 도입
6. active run save와 DB mirror 병행
7. 불일치 검사
8. active run 저장 전환 여부 결정

## 6. Save Schema Migration Strategy

[MIGRATION]

V4 schema migration은 다음 원칙을 따른다.

```text
old payload parse
-> version check
-> version-specific adapter
-> current runtime model restore
-> optional upgraded save write
```

새 schema 후보:

```text
schemaVersion = 3
- rulesetVersion
- runId
- currentNodeKind
- currentNodeIndex
- checkpointVersion
- contentCatalogVersion
```

`schemaVersion = 3`은 V4 문서만으로 즉시 도입하지 않는다. 먼저 테스트가 필요하다.

## 7. Security Scope

[V4_DECISION]

현재 HMAC은 로컬 tamper detection 목적이다. 서버 검증이나 경쟁 리더보드 보안 모델이 아니다.

향후 archive/stats가 서버와 연결될 경우:

- active run local save와 server profile sync를 분리한다.
- local HMAC은 계속 tamper detection으로 유지한다.
- server-authoritative economy를 도입할 경우 별도 protocol이 필요하다.

현재 V4 범위에서는 서버 저장을 확정하지 않는다.
