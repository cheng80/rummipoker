# Open Decisions

> 역할: code/test에서 현재 표현은 존재하지만 runtime 계약과 검증이 완성되지 않은 선택지만 기록한다. 확정 정책은 [core 문서](../core/CONTENT_SYSTEM.md), 비교·BM 후보는 [REVERSE_DESIGN_SYNTHESIS.md](REVERSE_DESIGN_SYNTHESIS.md), 완료 이력은 Git history가 소유한다.

## Admission Rule

항목은 다음 조건을 모두 만족할 때만 이 문서에 남긴다.

1. current code에 명시적인 variant, branch 또는 consumer seam이 있다.
2. runtime 동작을 확정하는 구현이나 test가 없다.
3. 선택 결과가 저장, deterministic replay, 점수 또는 플레이어 피드백 계약을 바꾼다.

아이디어, 벤치마크 후보, 완료된 정책, 과거 제출 이력, 날짜별 로그는 open decision으로 보존하지 않는다. 광고 BM·재미 강화 아이디어는 synthesis 문서의 후보로 두고 여기 넣지 않는다. 단, 이미 code seam이 있는 거짓 계약은 아래에 남긴다.

## Admitted Decisions

### OD-01 Challenge carryover producer 공백

- Code seam: completion UI notice, New Run carryover reader, `RunProgressionService` snapshot consumer.
- Missing: `_completedRunSummary()`가 growth/deck/played counts를 채우지 않아 실완료 snapshot이 비거나 무시된다.
- Impact: 플레이어-facing “Challenge 계승” 약속이 저장 계약과 불일치.
- Options: (A) summary 필드 복구 + integration test, (B) UI/문서 약속 제거.
- Status: open / 선행 수정 필요.

### OD-02 Settlement / terminal reward 멱등성

- Code seam: cash-out 후 `battle` save, completion Insight write, `runCompletionRewardClaimed`.
- Missing: durable settlement/claim transaction identity와 restore 재진입 방지 test.
- Impact: kill/restore 시 골드·Boss 보상·Insight 재지급 가능.
- Options: 지급 전 claim marker 저장, restore path skip, fault-injection tests.
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

## Explicitly Not Admitted Here

- Rewarded ad pilot, premium vs demo, build-relevant guarantee, failure-cause card: synthesis 후보이며 현재 production seam이 없거나 정책 결정 전이다.
- Balatro 1.1 content assumptions: 출시 미확인.
