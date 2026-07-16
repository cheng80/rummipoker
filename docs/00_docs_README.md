# Documentation Boundaries

이 문서는 문서군의 책임, 사실 권위, 갱신 소유권만 정의한다. 새 세션의 읽기 순서는 루트 `START_HERE.md`가 소유한다.

## Boundaries

| 문서군 | 경계 | 소유자 |
|---|---|---|
| `docs/core/` | current runtime 계약을 주제별로 설명 | 해당 runtime 변경 작업자 |
| `docs/planning/` | active track, next action, blocker, open decision | 현재 작업 책임자 |
| `docs/generated/` | code/data에서 재생성한 정확한 catalog·pattern 표 | `tools/generate_docs.dart` |
| `docs/planning/verification/` | 반복 가능한 test·QA acceptance | 검증 절차 변경 작업자 |
| `docs/release/` | 빌드·배포·스토어·홍보를 위한 별도 문서군 | 출시 작업 책임자 |
| `docs/tools/` | 문서·이미지·asset 생성 입력과 사용법 | 해당 도구 변경 작업자 |

## Authority Priority

사실 판단 순서는 `code/data/test → generated → core → planning`이다. 하위 단계는 상위 단계의 사실을 덮어쓰지 않는다.

- Generated 문서는 직접 편집하지 않고 generator source와 tool을 수정해 재생성한다.
- Core 문서는 current 동작을 설명하며 진행률, 후보, 완료 이력을 소유하지 않는다.
- Planning 문서는 실행 판단만 소유하고 runtime 사실을 확정하지 않는다.
- Verification은 실행 절차와 pass/fail evidence를 소유하며 제품 계약을 새로 정의하지 않는다.
- Release는 별도 운영 문서군이며 core/planning 사실 권위에 참여하지 않는다.

## Update Rules

- Runtime behavior나 save contract가 바뀌면 관련 code/test와 같은 변경에서 담당 core 문서를 갱신한다.
- Catalog, translation, Boss pattern source가 바뀌면 generator를 실행하고 `--check`를 통과시킨다.
- Active track, next action, blocker가 바뀌면 `ACTIVE_EXECUTION_PLAN.md`만 갱신한다.
- Code/test로 증명되는 미결 선택이 생기거나 닫히면 `OPEN_DECISIONS.md`를 갱신한다.
- 재사용 test·QA 절차가 바뀌면 `TEST_QA_ACCEPTANCE.md`를 갱신한다.
- 같은 사실을 두 문서군에 복사하지 않고 authority가 낮은 문서는 소유 문서로 안내한다.
