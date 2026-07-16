# Open Decisions

> 역할: code/test에서 현재 표현은 존재하지만 runtime 계약과 검증이 완성되지 않은 선택지만 기록한다. 확정 정책은 [core 문서](../core/CONTENT_SYSTEM.md), 완료 이력은 Git history가 소유한다.

## Admission Rule

항목은 다음 조건을 모두 만족할 때만 이 문서에 남긴다.

1. current code에 명시적인 variant, branch 또는 consumer seam이 있다.
2. runtime 동작을 확정하는 구현이나 test가 없다.
3. 선택 결과가 저장, deterministic replay, 점수 또는 플레이어 피드백 계약을 바꾼다.

아이디어, 벤치마크 후보, 완료된 정책, 과거 제출 이력, 날짜별 로그는 open decision으로 보존하지 않는다.

## No Other Admitted Decisions

현재 code/test evidence를 충족하는 다른 open decision은 없다. 새 항목은 아이디어를 보존하기 위해 추가하지 않고 위 admission rule의 source와 missing test를 함께 제시한다.
