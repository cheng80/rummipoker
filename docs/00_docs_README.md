# 문서 안내

이 문서는 각 문서가 무슨 일을 맡는지 알려 주는 안내서다. 게임 규칙을 찾을 때는 [START_HERE.md](../START_HERE.md)의 읽기 순서를 따르면 된다. 파일 이름은 `START_HERE.md`다.

## 문서 종류와 역할

| 문서군 | 경계 | 소유자 |
|---|---|---|
| `docs/core/` | current runtime 계약을 주제별로 설명 | 해당 runtime 변경 작업자 |
| `docs/planning/` | active track, next action, blocker, open decision | 현재 작업 책임자 |
| `docs/generated/` | code/data에서 재생성한 정확한 catalog·pattern 표 | `tools/generate_docs.dart` |
| `docs/planning/verification/` | 반복 가능한 test·QA acceptance | 검증 절차 변경 작업자 |
| `docs/release/` | 빌드·배포·스토어·홍보를 위한 별도 문서군 | 출시 작업 책임자 |
| `docs/tools/` | 문서·이미지·asset 생성 입력과 사용법 | 해당 도구 변경 작업자 |

## 무엇을 가장 믿어야 하나

사실 판단 순서는 `code/data/test → generated → core → planning`이다. 하위 단계는 상위 단계의 사실을 덮어쓰지 않는다.

- Generated 문서는 직접 편집하지 않고 generator source와 tool을 수정해 재생성한다.
- Core 문서는 current 동작을 설명하며 진행률, 후보, 완료 이력을 소유하지 않는다.
- Planning 문서는 실행 판단만 소유하고 runtime 사실을 확정하지 않는다.
- Verification은 실행 절차와 pass/fail evidence를 소유하며 제품 계약을 새로 정의하지 않는다.
- Release는 별도 운영 문서군이며 core/planning 사실 권위에 참여하지 않는다.

## 자주 나오는 개발 용어

문서에 코드와 같은 이름을 남겨야 하는 곳이 있어 아래처럼 읽으면 된다.

| 문서 용어 | 쉽게 말하면 |
|---|---|
| runtime | 앱을 실제로 실행했을 때의 상태 |
| source of truth | 내용이 다를 때 가장 먼저 믿는 기준 |
| facade | 복잡한 상태를 화면이 읽기 좋은 모양으로 바꾼 값 |
| snapshot | 나중에 되돌아가기 위해 저장해 둔 기준점 |
| schema | 저장 파일의 항목과 형식 약속 |
| slot | Jester나 Item을 넣어 두는 보관칸 |
| pool / offer | Market에 나올 수 있는 후보 목록과 이번에 보여 준 후보 |
| trigger / hook | 효과가 실행되는 시점과 실행 지점 |
| restore | 저장해 둔 게임을 다시 여는 일 |
| migration | 예전 저장 형식을 새 형식으로 바꾸는 일 |

## 문서를 고치는 규칙

- Runtime behavior나 save contract가 바뀌면 관련 code/test와 같은 변경에서 담당 core 문서를 갱신한다.
- Catalog, translation, Boss pattern source가 바뀌면 generator를 실행하고 `--check`를 통과시킨다.
- Active track, next action, blocker가 바뀌면 `ACTIVE_EXECUTION_PLAN.md`만 갱신한다.
- Code/test로 증명되는 미결 선택이 생기거나 닫히면 `OPEN_DECISIONS.md`를 갱신한다.
- 재사용 test·QA 절차가 바뀌면 `TEST_QA_ACCEPTANCE.md`를 갱신한다.
- 같은 사실을 두 문서군에 복사하지 않고 authority가 낮은 문서는 소유 문서로 안내한다.

## 새 문서를 만들거나 고칠 때

- 새 문서는 먼저 기존 문서 확장으로 해결할 수 있는지 확인한다. 새 파일은 아래 registry에 경로·유형·역할을 추가해야 한다.
- Markdown 문서는 `docs/core/`, `docs/planning/`, `docs/generated/`, `docs/release/`, `docs/tools/`, `docs/archive/` 중 하나에만 둔다. `docs/00_docs_README.md`는 이 registry의 정본이다.
- `docs/superpowers/specs/**`와 `docs/superpowers/plans/**`는 선택적 스킬 산출물이다. registry와 `START_HERE.md` 등록 대상에서 제외하며 제품 정본으로 사용하지 않는다.
- Superpowers 산출물에서 확정된 제품 계약과 현재 실행 상태는 각각 `docs/core/`와 `docs/planning/`의 담당 문서에 반영한다.
- 모든 Markdown 문서는 H1 제목을 갖는다. `docs/planning/` 문서는 첫 화면에 `> 역할:`을 둔다.
- `docs/generated/` 문서는 `DO NOT EDIT`와 generator 경로를 헤더에 남기고, source와 generator를 수정해 재생성한다.
- 문서 삭제·이동·신규 추가는 `dart run tools/check_docs_structure.dart`를 통과해야 한다.

<!-- DOCUMENT_REGISTRY_START -->
| 경로 | 유형 | 역할 |
|---|---|---|
| `docs/00_docs_README.md` | governance | 문서 경계·권위·작성 규칙 |
| `docs/core/CONTENT_SYSTEM.md` | core | 콘텐츠 runtime 계약 |
| `docs/core/GAME_DESIGN.md` | core | 게임 정체성·코어 루프 |
| `docs/core/GAME_RULES.md` | core | 보드·족보·전투 규칙 |
| `docs/core/RUN_ECONOMY.md` | core | run·정산·경제 계약 |
| `docs/core/SAVE_DATA.md` | core | 저장 schema·복원 계약 |
| `docs/core/SYSTEM_ARCHITECTURE.md` | core | runtime 계층·소유권 |
| `docs/core/UI_UX.md` | core | 화면·입력·피드백 계약 |
| `docs/generated/BOSS_PATTERNS.md` | generated | 코드에서 생성한 Boss 표 |
| `docs/generated/CONTENT_CATALOG.md` | generated | 데이터에서 생성한 콘텐츠 목록 |
| `docs/planning/ACTIVE_EXECUTION_PLAN.md` | planning | 현재 실행 상태·다음 행동 |
| `docs/planning/OPEN_DECISIONS.md` | planning | code/test 근거가 있는 미결정 |
| `docs/planning/REVERSE_DESIGN_SYNTHESIS.md` | planning | 역기획 비교·재미 후보·BM 권고 요약 |
| `docs/planning/verification/TEST_QA_ACCEPTANCE.md` | planning | 반복 검증 절차·acceptance |
| `docs/planning/verification/ko_cycle_review.md` | planning | ko locale gate 실행·검토 결과 |
| `docs/release/00_release_README.md` | release | 출시 문서군 정의 |
| `docs/release/APP_STORE_SCREENSHOTS_SKILL_USAGE_KO.md` | release | 스토어 스크린샷 스킬 안내 |
| `docs/release/project_information_poster_image_prompt.md` | release | 포스터 생성 원천 prompt |
| `docs/release/rummipoker_nas_deploy.md` | release | NAS 배포 절차 |
| `docs/release/web_build.md` | release | 웹 빌드 절차 |
| `docs/release/submission_kit/ANDROID_BUILD_NOTES.md` | release | Android 빌드 메모 |
| `docs/release/submission_kit/BUILD_GUIDE.md` | release | 제출 빌드 안내 |
| `docs/release/submission_kit/FIREBASE_RELEASE_SETUP.md` | release | Firebase 출시 설정 |
| `docs/release/submission_kit/IN_APP_REVIEW_GUIDE.md` | release | 인앱 리뷰 안내 |
| `docs/release/submission_kit/IOS_PROFILE_BUILD.md` | release | iOS profile 빌드 안내 |
| `docs/release/submission_kit/README.md` | release | 제출 키트 정의 |
| `docs/release/submission_kit/RELEASE_CHECKLIST.md` | release | 출시 체크리스트 |
| `docs/release/submission_kit/SCREENSHOT_PROMO_COPY_KO_EN.md` | release | 스크린샷 홍보 문구 |
| `docs/release/submission_kit/STORE_METADATA_KO_EN.md` | release | 스토어 metadata |
| `docs/release/submission_kit/TUTORIAL_COACH_MARK_PLAN.md` | release | 튜토리얼 coach mark 계획 |
| `docs/release/submission_kit/WEB_BUILD_GUIDE.md` | release | 웹 제출 빌드 안내 |
| `docs/tools/00_tools_README.md` | tools | 도구 문서군 정의 |
| `docs/tools/card_assets/CARD_ITEM_ILLUSTRATION_GUIDE.md` | tools | 카드 일러스트 규칙 |
| `docs/tools/card_assets/CARD_ITEM_IMAGE_PROMPTS.md` | tools | 카드 이미지 prompt |
<!-- DOCUMENT_REGISTRY_END -->
