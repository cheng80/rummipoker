# P0 보상·정산·저장 신뢰 설계

## 한눈에 보기

이번 작업의 핵심은 세 가지다.

- 화면에 안내한 보상과 실제 지급 보상을 맞춘다.
- 강제 종료 후 다시 실행해도 정산 보상과 런 완료 보상은 한 번만 지급한다.
- 기존 v2 이어하기를 유지하면서, 저장 도중 종료되어 데이터가 어긋나는 구간을 줄인다.

## 작업 범위

- Blind 보상 미리보기는 실제 기본 보상인 `4G × run modifier`로 계산한다.
- 같은 Blind에서 cash-out을 두 번 호출해도 골드, Boss 타일, 슬롯 해금, 정산 Item 효과가 중복 적용되지 않게 한다.
- S8 완료 Insight는 stable run claim ID와 기존 `runCompletionRewardClaimed`를 함께 확인해 한 번만 지급한다.
- New Run을 시작하면 Blind Select로 이동하기 전에 최초 active run을 저장한다.
- Market에서 Title로 나갈 때는 대기 중인 저장을 먼저 끝낸다.
- active run의 payload와 signature는 하나의 SharedPreferences 값으로 저장한다.
- 기존 v2의 payload와 signature 두 키도 계속 읽는다. 한 번 저장한 뒤부터는 새 단일 값 형식으로 전환한다.

광고/IAP, Challenge carryover, 저장 schema v3, bookmark 저장 형식 변경은 이번 작업에 포함하지 않는다.

## 상세 설계

### 1. 안내 보상과 실제 보상을 맞춘다

현재 `BlindSelectionSpecBuilder`는 tier에 따라 보상을 `4/8/12`로 만든다. 이 계산을 없애고, `RummiRunProgress.stageClearGoldBase`에 현재 run modifier를 적용한다.

이때 실제 정산에서 쓰는 기본 보상 상수와 반올림 규칙을 그대로 재사용한다. UI는 기존 `rewardPreview`를 표시하므로 화면을 따로 분기할 필요가 없다.

### 2. 정산은 여러 번 호출해도 한 번만 반영한다

`RummiRunProgress`에 정산 영수증 역할을 하는 durable receipt를 둔다. 이 receipt에는 현재 Blind를 구분하는 station/tier key와 최초 정산 결과인 `RummiCashOutBreakdown`을 저장한다.

`prepareSettlementAndCashOut`은 receipt가 있으면 상태를 다시 바꾸지 않는다. 대신 처음 저장한 breakdown을 그대로 반환한다. 새 Blind가 시작될 때만 이전 receipt를 비운다.

cash-out 적용과 receipt 생성은 메모리에서 한 번에 처리한다. 그 직후, 결과 화면을 보여 주기 전에 active run 단일 레코드를 저장한다.

- 저장 전에 앱이 종료되면 이전 정상 상태에서 정산을 다시 계산한다.
- 저장 후 앱이 종료되면 receipt가 같은 정산의 재적용을 막는다.

따라서 복원된 already-cleared Battle이 같은 흐름에 다시 들어와도 골드, Boss 보상, 슬롯 해금, settlement Item 효과는 중복되지 않는다. 화면 연출 상태는 저장하지 않는다.

### 3. 런 완료 Insight도 한 번만 지급한다

새 런을 만들 때 stable claim ID를 생성하고 active save에 보관한다. 기존 v2 save에 이 ID가 없으면 복원 직후 한 번 생성해 저장한다.

`RunUnlockStateService`는 처리한 claim ID도 함께 저장한다. 같은 ID로 Insight 지급을 다시 요청하면 아무 작업도 하지 않는다. active run의 `runCompletionRewardClaimed`는 화면 흐름을 표시하는 기존 용도로 유지한다.

이 작은 지급 기록(ledger)은 unlock state 저장과 Insight 증가를 한 번의 쓰기로 묶는다. 외부 저장은 성공했지만 active save 전에 앱이 종료된 경우에도 Insight가 중복 지급되지 않는다.

### 4. active run은 하나의 값으로 저장한다

새 active run 저장 형식은 `{payload, signature}`를 담은 JSON envelope이다. 이 값을 `active_run_record_v1` 키 하나에 기록한다. HMAC은 기존과 같이 exact payload 문자열을 기준으로 계산한다.

SharedPreferences의 `setString`을 한 번만 호출하므로 payload와 signature 중 한쪽만 저장되는 문제가 사라진다.

읽기와 전환 규칙은 다음과 같다.

1. 새 envelope을 먼저 읽는다.
2. 새 envelope이 없을 때만 기존 v2의 두 키를 읽는다.
3. 기존 v2 값을 정상적으로 불러오면, 다음 저장 때 새 envelope을 기록하고 기존 두 키를 제거한다.
4. 새 envelope이 있지만 손상됐다면 `invalid`로 처리한다. 오래된 v2 값으로 조용히 되돌아가 stale 진행이 되살아나는 일을 막기 위해서다.
5. `clearActiveRun`은 새 키와 기존 두 키를 모두 지운다.

bookmark는 이번 범위에서 기존 저장 방식을 유지한다.

### 5. 화면을 떠나기 전에 저장을 끝낸다

New Run의 최초 runtime 생성 로직은 기존 notifier bootstrap과 함께 사용하는 helper로 모은다. New Run은 `blindSelect` scene의 initial runtime을 먼저 저장한 뒤 route extra로 넘긴다. Blind를 선택한 뒤에는 기존 continued-run 준비 경로를 재사용한다.

Market에서 Title로 나갈 때는 `_pendingStateSave`를 먼저 flush하고 route를 닫는다. 저장에 실패하면 이동하지 않는다. 기존 오류 표시 경로를 사용하거나 호출자에게 실패를 반환해, 최신 상태가 사라진 채 화면이 종료되지 않게 한다.

## 오류 처리 원칙

- 새 envelope에 필요한 필드가 없거나 signature가 일치하지 않거나 JSON을 읽을 수 없으면 `invalid`로 처리한다.
- 기존 v2 키는 새 envelope이 없을 때만 확인한다.
- 기존 v2 키가 하나만 남으면 inspect는 `none`, load는 null을 반환하고 raw key 존재 여부는 유지한다.
- 저장 실패를 성공으로 기록하지 않는다.
- 새 저장이 성공하기 전에 기존의 정상 저장을 지우지 않는다.

## 검증 방법

- 세 Blind tier와 high-stakes modifier에서 미리보기와 실제 settlement 기본 보상이 같은지 테스트한다.
- cash-out을 두 번 호출한 경우와 cash-out 저장 후 복원해 다시 호출한 경우, 골드·Boss 보상·Item 효과가 한 번만 바뀌는지 테스트한다.
- 같은 run claim ID로 완료 기록을 두 번 요청해도 Insight가 한 번만 증가하는지 테스트한다.
- 기존 v2 저장 불러오기, 다음 저장에서 envelope로 전환, 손상된 envelope 처리, 저장 삭제를 테스트한다.
- New Run 직후 active save가 생기는지, Market에서 Title로 나가기 전에 저장을 flush하는지 widget test로 보호한다.
- 관련 targeted tests, 전체 `flutter test`, `flutter analyze`, 문서 생성 검사, `git diff --check`를 실행한다.
- 최신 web build에서 New Run 직후 이어하기, cash-out 후 재진입, Market 변경 후 Title→이어하기를 직접 확인한다.

## 완료 조건

다음 조건을 모두 만족하면 완료다.

- 표시 보상과 실제 기본 보상이 일치한다.
- 동일한 정산 보상과 완료 보상은 복원 후에도 한 번만 지급된다.
- 기존 v2 저장을 유지하면서 새 저장 형식으로 전환된다.
- 최초 저장과 Market 종료 전 flush가 자동 테스트와 수동 검증을 모두 통과한다.
