# P0 보상·정산·저장 신뢰 설계

## 목표

Blind Select의 보상 안내를 실제 정산과 일치시키고, 강제 종료·복원에도 정산 및 런 완료 보상이 한 번만 지급되며, 기존 v2 이어하기를 보존하면서 active run 저장 실패 구간을 줄인다.

## 범위

- Blind 보상 미리보기를 실제 기본 보상 `4G × run modifier`와 일치시킨다.
- 같은 Blind의 cash-out을 두 번 호출해도 골드, Boss 타일, 슬롯 해금, 정산 Item 효과가 중복 적용되지 않게 한다.
- S8 완료 Insight는 stable run claim ID와 기존 `runCompletionRewardClaimed`를 함께 사용해 한 번만 지급한다.
- New Run에서 Blind Select로 이동하기 전에 최초 active run을 저장한다.
- Market에서 Title로 나가는 경로는 대기 중인 저장을 완료한 뒤 이동한다.
- active run의 payload와 signature를 단일 SharedPreferences 값으로 저장한다.
- 기존 v2 payload/signature 두 키는 계속 읽고, 다음 저장부터 단일 값으로 전환한다.

광고/IAP, Challenge carryover, 저장 schema v3, bookmark 저장 형식 변경은 제외한다.

## 설계

### 보상 진실성

`BlindSelectionSpecBuilder`가 tier별 `4/8/12`를 만들지 않고 `RummiRunProgress.stageClearGoldBase`에 현재 run modifier만 적용한다. 정산의 기본 보상 계산과 같은 상수·반올림 규칙을 재사용한다. UI는 기존 `rewardPreview`를 그대로 표시하므로 별도 화면 분기를 추가하지 않는다.

### 정산 멱등성

`RummiRunProgress`에 현재 Blind를 식별하는 station/tier key와 최초 `RummiCashOutBreakdown`을 담은 durable receipt를 둔다. `prepareSettlementAndCashOut`은 receipt가 있으면 상태를 다시 변경하지 않고 저장된 breakdown을 반환한다. 새 Blind가 시작될 때 이전 receipt를 비운다.

cash-out 적용과 receipt 생성을 한 번의 in-memory 변경으로 만든 뒤 presentation 전에 active run 단일 레코드를 저장한다. 저장 전 종료는 이전 정상 상태에서 다시 계산하고, 저장 후 종료는 receipt가 재적용을 막는다. 복원된 already-cleared Battle이 같은 흐름에 다시 들어가도 골드, Boss 보상, 슬롯 해금과 settlement Item 효과는 중복되지 않는다. 화면 연출 상태는 저장하지 않는다.

새 런마다 stable claim ID를 만들고 active save에 보존한다. 기존 v2 save에 ID가 없으면 복원 직후 한 번 생성해 저장한다. `RunUnlockStateService`는 처리한 claim ID를 함께 저장하며 같은 ID의 Insight 지급 요청을 no-op으로 처리한다. active run의 `runCompletionRewardClaimed`는 화면 흐름 표식으로 유지한다. 이 작은 ledger가 unlock state 저장과 Insight 증가를 같은 쓰기로 묶어, 외부 저장 성공 후 active save 전에 종료돼도 중복 지급을 막는다.

### 저장 신뢰성

새 active run 저장은 `{payload, signature}` JSON envelope 하나를 `active_run_record_v1` 키에 기록한다. HMAC은 기존처럼 exact payload 문자열을 대상으로 계산한다. 단일 SharedPreferences `setString` 호출만 성공하면 읽을 수 있는 한 쌍이 생기므로 두 키 사이 강제 종료 구간이 사라진다.

읽기 순서는 새 envelope 우선, 기존 v2 두 키 fallback이다. 기존 값을 정상 로드한 뒤 다음 save가 새 envelope을 기록하고 기존 두 키를 제거한다. 새 envelope이 존재하지만 손상된 경우 오래된 v2로 조용히 되돌아가지 않고 `invalid`로 처리해 stale 진행 부활을 막는다. `clearActiveRun`은 새 키와 기존 두 키를 모두 지운다. bookmark는 현재 범위에서 기존 저장 방식을 유지한다.

New Run 초기 runtime 생성 로직은 기존 notifier bootstrap과 함께 쓰는 helper로 모은다. New Run은 `blindSelect` scene의 initial runtime을 저장한 뒤 route extra로 넘기고, Blind 선택은 기존 continued-run 준비 경로를 재사용한다. Market의 Title 종료는 `_pendingStateSave`를 flush한 뒤 route를 닫는다. 저장 실패 시 이동을 계속하지 않고 기존 오류 표시 경로를 사용하거나 호출자에게 실패를 반환해 최신 상태가 사라진 채 종료되지 않게 한다.

## 오류 처리

- 새 envelope 필드 누락, signature 불일치, JSON 오류는 `invalid`다.
- 새 envelope이 없을 때만 기존 v2 키를 검사한다.
- 기존 v2 한쪽 키만 남은 상태는 현재와 같이 `invalid/none` 복구 대상으로 유지한다.
- 저장 실패를 성공으로 기록하거나 기존 정상 저장을 선제 삭제하지 않는다.

## 검증

- Blind tier 세 개와 high-stakes modifier의 preview가 실제 settlement 기본 보상과 같은지 테스트한다.
- cash-out 두 번 호출, cash-out 저장 후 복원·재호출에서 골드·Boss 보상·Item 효과가 한 번만 변하는지 테스트한다.
- 같은 run claim ID로 완료 기록을 두 번 요청해도 Insight가 한 번만 증가하는지 테스트한다.
- 기존 v2 저장 load와 다음 save의 envelope 전환, 손상 envelope, clear를 테스트한다.
- New Run 직후 active save 존재와 Market Title 종료 전 flush를 widget test로 보호한다.
- 관련 targeted tests, 전체 `flutter test`, `flutter analyze`, 문서 생성 검사, `git diff --check`를 실행한다.
- 최신 web build에서 New Run 직후 이어하기, cash-out 후 재진입, Market 변경 후 Title→이어하기를 직접 확인한다.

## 완료 조건

표시 보상과 실제 기본 보상이 일치하고, 동일 정산·완료 보상이 복원 후에도 한 번만 지급되며, 기존 v2 저장이 유지된 채 새 저장 형식으로 전환되고, 최초 저장과 Market 종료 flush가 자동·수동 검증을 통과하면 완료다.
