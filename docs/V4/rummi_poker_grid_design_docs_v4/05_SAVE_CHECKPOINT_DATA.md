# 05. Save, Checkpoint & Data Architecture

> 문서 성격: current baseline + target persistence architecture
> 코드 반영 상태: active run save v2 implemented, DB/archive target not implemented
> 핵심 정책: 저장 구조는 회귀 비용이 가장 크므로 current save를 보호한다.

## 1. Current Save Summary

[CURRENT]

현재 저장은 단일 active run snapshot 중심이다.

구성:

- `GetStorage` payload 저장
- `flutter_secure_storage` device key
- Web에서는 device key도 `GetStorage` fallback
- HMAC-SHA256 signature
- `schemaVersion = 2`
- active scene 저장: `battle` / `shop`
- stageStartSnapshot 저장

Storage keys:

| Key | 의미 |
|---|---|
| `active_run_payload_v1` | JSON payload |
| `active_run_signature_v1` | HMAC signature |
| `save_device_key_v1` | device key |

[WATCH]

Key suffix는 v1이고 payload schema는 v2다. V4에서는 key version과 schema version을 분리해서 다룬다.

## 2. Current Runtime Save Model

[CURRENT]

```text
ActiveRunRuntimeState
- activeScene
- session
- runProgress
- stageStartSnapshot

ActiveRunStageSnapshot
- session
- runProgress
```

`stageStartSnapshot`은 현재 stage 시작점 복원을 위한 핵심 구조다.

## 3. Current Payload Schema

[CURRENT]

```text
ActiveRunSaveData
- schemaVersion
- savedAt
- activeScene
- session
- runProgress
- stageStartSession
- stageStartRunProgress
```

```text
SavedSessionData
- runSeed
- deckCopiesPerTile
- maxHandSize
- runRandomState
- blind
- deckPile
- boardCells
- hand
- eliminated
```

```text
SavedRunProgressData
- stageIndex
- gold
- rerollCost
- ownedJesterIds
- shopOffers
- statefulValuesBySlot
- playedHandCounts
```

```text
SavedShopOfferData
- slotIndex
- cardId
- price
```

## 4. Integrity Flow

[CURRENT]

저장:

```text
build ActiveRunSaveData
→ jsonEncode
→ ensure device key
→ HMAC-SHA256(payload, deviceKey)
→ write payload + signature
```

로드:

```text
read payload + signature
→ read device key
→ compare HMAC
→ decode JSON
→ schemaVersion check
→ restore session
→ restore runProgress via Jester catalog lookup
→ restore stageStartSnapshot
```

## 5. Continue / Invalid Save Flow

[CURRENT]

Title flow:

1. `inspectActiveRun()`
2. `none / available / invalid`
3. available이면 continue 또는 delete 선택
4. invalid이면 손상/호환 불가 안내 후 delete 선택
5. load 성공 시 `GameView`로 restoredRun 전달
6. activeScene이 `shop`이면 catalog load 후 shop resume

## 6. Restart Semantics

[CURRENT]

인게임 재시작은 run 전체 리셋이 아니다.

의미:

```text
현재 stage 시작 시점으로 복원
```

복원 대상:

- board
- hand
- deck pile
- eliminated
- runRandom state
- target score / scoreTowardBlind / discards
- gold
- owned Jesters
- shop offers
- stateful Jester values
- played hand counts

[V4_DECISION]

이 의미는 V4 target에서도 유지한다. Station 구조에서는 `StationCheckpoint`로 이름만 확장한다.

## 7. Target Domain Data Model

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

[V4_DECISION]

물리 저장 엔진은 지금 확정하지 않는다. 도메인 경계를 먼저 정하고, 구현 엔진은 단계적으로 선택한다.

## 8. Persistence Engine Policy

[V4_DECISION]

- 현재 active run save v2는 유지한다.
- Drift / SQLite / IndexedDB는 target persistence layer 후보일 뿐이다.
- DB 도입은 active run save를 즉시 대체하지 않는다.
- 먼저 read-only mirror 또는 archive-only 저장으로 도입한다.

[MIGRATION]

권장 순서:

1. current save golden test 추가
2. schemaVersion 2 restore test 추가
3. save corruption test 추가
4. `rulesetVersion` 필드 추가 검토
5. DB read model 도입
6. active run save와 DB mirror 병행
7. 불일치 검사
8. active run 저장 전환 여부 결정

## 9. Save Compatibility Rules

[V4_DECISION]

- 기존 `ownedJesterIds`는 계속 복원 가능해야 한다.
- Jester id는 삭제하지 않는다.
- `stageIndex`는 Station 전환 후에도 adapter로 해석 가능해야 한다.
- `blind` JSON은 이름을 바꾸기 전에 adapter를 둔다.
- `stageStartSession` / `stageStartRunProgress`는 Station checkpoint로 migration 가능해야 한다.
- 저장 데이터의 서명 검증 실패 시 자동 복구하지 않고 invalid 처리한다.

## 10. Save Schema Migration Strategy

[MIGRATION]

V4 schema migration은 다음 원칙을 따른다.

```text
old payload parse
→ version check
→ version-specific adapter
→ current runtime model restore
→ optional upgraded save write
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

단, schemaVersion 3은 V4 문서만으로 즉시 도입하지 않는다. 먼저 테스트가 필요하다.

## 11. Security Scope

[CURRENT]

현재 HMAC은 로컬 tamper detection 목적이다. 서버 검증이나 경쟁 리더보드 보안 모델은 아니다.

[TARGET]

향후 archive/stats가 서버와 연결될 경우:

- active run local save와 server profile sync를 분리
- local HMAC은 계속 tamper detection으로 유지
- server-authoritative economy를 도입할 경우 별도 protocol 필요

현재 V4 범위에서는 서버 저장을 확정하지 않는다.
