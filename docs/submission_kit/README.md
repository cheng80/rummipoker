# Rummi Poker 제출 준비 문서

이 폴더는 `docs/old_doc_data/`의 과거 HabitCell/TagDo 제출 문서를 Rummi Poker 기준으로 다시 정리한 작업용 문서다. 원본 자료는 참고용으로 남기고, 실제 제출 준비와 다음 구현 판단은 이 폴더와 `docs/planning/competition/` 문서를 기준으로 한다.

## 현재 앱 기준

- 게임명: Rummi Poker
- 서브타이틀: 타일로 만드는 포커 런
- 장르 방향: 타일 배치, 포커 핸드 점수화, 로그라이트 성장, Jester/Item/보스 제약
- 공모전 QA 기준: 사람 수동 플레이가 아니라 `contest_full_run_bot` 기준
- Debug fixture: 눈검증과 재현 보조 전용이며 full-play evidence로 쓰지 않는다.

## 문서 목록

- `RELEASE_CHECKLIST.md`: 공모전/스토어 제출 전 체크리스트
- `BUILD_GUIDE.md`: 공통 버전 관리 기준
- `WEB_BUILD_GUIDE.md`: Web 빌드와 Browser QA 기준
- `STORE_METADATA_KO_EN.md`: 한국어/영어 스토어 문구 초안
- `SCREENSHOT_PROMO_COPY_KO_EN.md`: 스크린샷 구성과 홍보 문구
- `IN_APP_REVIEW_GUIDE.md`: 인앱 리뷰 적용 기준
- `IOS_PROFILE_BUILD.md`: iOS profile/release 빌드 메모
- `ANDROID_BUILD_NOTES.md`: Android 빌드와 과거 문서 이관 주의점
- `TUTORIAL_COACH_MARK_PLAN.md`: `tutorial_coach_mark` 기반 전투/상점 튜토리얼 구현 기준

## old_doc_data 이관 판단

- 과거 앱명, 패키지명, 스토어 ID, 태그/할 일 중심 설명은 재사용하지 않는다.
- `icon_splash/`의 과거 이미지 자산은 현재 게임 룩과 맞지 않아 제출 자산으로 복사하지 않는다.
- ShowcaseView 관련 과거 문서는 참고용으로만 남긴다. 실제 앱 구현은 `tutorial_coach_mark` 기준으로 전환했다.
- 스토어 정책, 데이터 보안, 연령 등급은 제출 직전 공식 콘솔 기준으로 재확인한다.
