# Open Decisions

> 역할: 코드에는 흔적이 있지만 아직 어떤 방식으로 확정할지 정하지 못한 내용만 적는다. 확정된 규칙은 [core 문서](../core/CONTENT_SYSTEM.md), 비교·BM 후보는 [REVERSE_DESIGN_SYNTHESIS.md](REVERSE_DESIGN_SYNTHESIS.md), 완료 이력은 Git history가 맡는다.

## 이 문서에 남길 기준

아래 세 가지를 모두 만족할 때만 이 문서에 남긴다.

1. 현재 코드에 선택지나 분기, 실제로 연결된 사용 지점이 있다.
2. 어떤 방식으로 동작할지 정한 구현이나 테스트가 아직 없다.
3. 결정 결과가 저장, 같은 seed 재현, 점수, 플레이어 안내 중 하나를 바꾼다.

아이디어, 벤치마크 후보, 완료된 정책, 과거 제출 이력, 날짜별 로그는 open decision으로 보존하지 않는다. 광고 BM·재미 강화 아이디어는 synthesis 문서의 후보로 두고 여기 넣지 않는다. 단, 이미 code seam이 있는 거짓 계약은 아래에 남긴다.

## 아직 정하지 못한 내용

### OD-01 Challenge carryover producer 공백

- 연결된 코드: 완료 화면 안내, New Run의 Challenge 계승 읽기, `RunProgressionService`의 기준점 사용.
- 빠진 부분: `_completedRunSummary()`가 성장·덱·플레이 횟수를 채우지 않아 실제 완료 뒤 기준점이 비거나 무시된다.
- 영향: 플레이어에게 한 “Challenge 계승” 약속과 저장 내용이 다르다.
- 선택지: (A) 완료 요약 필드를 복구하고 통합 테스트 추가, (B) 화면과 문서에서 약속 제거.
- Status: open / 선행 수정 필요.

### OD-02 Settlement / terminal reward 멱등성

- 연결된 코드: cash-out 뒤 `battle` 저장, 완료 Insight 기록, `runCompletionRewardClaimed`.
- 빠진 부분: 정산과 보상 지급을 한 번만 처리했다는 표식, 복원 때 다시 들어가지 않는 테스트.
- 영향: 강제 종료 후 다시 열면 골드·Boss 보상·Insight가 다시 지급될 수 있다.
- 선택지: 지급 전에 완료 표식을 저장하고, 복원 경로에서 재처리를 막으며, 강제 종료 테스트를 추가한다.
- Status: open / P0.

### OD-03 Tool/Gear capacity vs UI slots

- Code seam: Tool/Gear acquisition은 cap 없이 허용, Market UI는 3/2만 렌더.
- Missing: capacity enforce 또는 overflow use/sale UI + tests.
- Impact: 숨은 보유 효과, 판매/사용 접근 불능.
- Options: (A) acquisition cap, (B) overflow UI.
- Status: open.

### OD-04 Voluntary retirement contract

- Code seam: `RunEndResult.retired` enum + service test.
- Missing: 플레이어 경로에서 retirement 기록/Insight 처리 없음.
- Impact: 문서·enum이 실제 terminal 선택과 불일치.
- Options: (A) 자발적 종료 경로 구현, (B) retired 계약 제거.
- Status: open.

### OD-05 Blind rewardPreview SSoT

- Code seam: `BlindSelectionSpec.rewardPreview` 4/8/12 display vs Settlement base 4.
- Missing: 표시와 cash-out 단일 권위 + widget/runtime tests.
- Impact: Blind Select 보상 정보가 거짓.
- Options: preview를 Settlement formula에 맞추거나 tier 차등 보상을 실제로 도입.
- Status: open / P0 display truth.

## 이 문서에 넣지 않는 내용

- Rewarded ad pilot, premium vs demo, build-relevant guarantee, failure-cause card: synthesis 후보이며 현재 production seam이 없거나 정책 결정 전이다.
- Balatro 1.1 content assumptions: 출시 미확인.
