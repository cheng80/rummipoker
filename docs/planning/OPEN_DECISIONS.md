# Open Decisions

> 역할: code/test에서 현재 표현은 존재하지만 runtime 계약과 검증이 완성되지 않은 선택지만 기록한다. 확정 정책은 [core 문서](../core/CONTENT_SYSTEM.md), 완료 이력은 Git history가 소유한다.

## Admission Rule

항목은 다음 조건을 모두 만족할 때만 이 문서에 남긴다.

1. current code에 명시적인 variant, branch 또는 consumer seam이 있다.
2. runtime 동작을 확정하는 구현이나 test가 없다.
3. 선택 결과가 저장, deterministic replay, 점수 또는 플레이어 피드백 계약을 바꾼다.

아이디어, 벤치마크 후보, 완료된 정책, 과거 제출 이력, 날짜별 로그는 open decision으로 보존하지 않는다.

## Tile Enhancement Activation

### `wild_painted`와 `lucky_tile`

Evidence:

- [tile.dart](../../lib/logic/rummi_poker_grid/models/tile.dart)는 `TileEnhancement.wildPainted`와 `TileEnhancement.luckyTile` variant 및 저장 ID를 정의한다.
- `lib/**`와 `test/**`의 direct reference scan에서 두 ID는 위 enum 정의 외에 runtime consumer와 test가 없다.

결정이 필요한 경계:

- `wild_painted`가 색상 판정에 개입하는 정확한 evaluator 규칙
- `lucky_tile` 발동 확률, RNG state 저장과 retry/replay 재현 규칙
- 손패·보드·preview·정산에서 보유와 발동을 구분하는 feedback

현재 guard:

- 두 variant를 Market/runtime 활성 콘텐츠로 간주하지 않는다.
- evaluator, deterministic save/replay, UI feedback test가 함께 준비되기 전에는 pool에 노출하지 않는다.

Done evidence:

- 선택한 규칙이 evaluator/runtime에 구현되고 deterministic unit test와 save roundtrip test가 통과한다.
- 전투 UI에서 보유와 발동 상태를 구분하는 widget 또는 fixture 검증이 통과한다.
- 완료 후 이 항목을 삭제하고 확정 계약만 core 문서에 반영한다.

## No Other Admitted Decisions

현재 code/test evidence를 충족하는 다른 open decision은 없다. 새 항목은 아이디어를 보존하기 위해 추가하지 않고 위 admission rule의 source와 missing test를 함께 제시한다.
