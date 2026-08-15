# 웹 오디오 복귀 픽스처와 NAS 배포

**Goal:** 화면 복귀 뒤 웹 SFX를 안정적으로 다시 해제하고 게임오버와 Market 오디오 상태를 바로 검사할 수 있게 배포한다.

**Why planning is required:** 운영 NAS 배포로 외부 상태가 바뀐다.

**Acceptance:** 기준 revision과 변경 범위를 확인하고 관련 테스트, 정적 분석, release web build가 통과해야 한다. 배포 전 원격 핵심 파일 hash를 임시 rollback 근거로 보존한다. 배포나 hash 비교가 실패하면 추가 rollout을 중단한다. 배포 뒤 로컬·원격 핵심 파일 hash 일치, 공개 진입점 HTTP 200, 업로드 ZIP HTTP 404를 확인한다.

### Outcome 1: 화면 복귀 후 SFX 풀 재잠금 복구

- Work: `document.visibilitychange`에서 숨김 상태가 되면 진행 중인 웹 SFX 슬롯을 정리하고 다음 사용자 입력에서만 다시 unlock한다. Dart는 모든 웹 오디오 제스처를 JavaScript 풀에 전달하되 기존 BGM 재개 차단과 사용자 제스처 복구 순서는 유지한다.
- Verify: `flutter test test/resources/sound_manager_test.dart && node --test test/web/rummi_poker_sfx_test.mjs`

### Outcome 2: 게임오버·Market 오디오 QA 직접 진입

- Work: 기존 게임오버와 Market runtime builder를 재사용해 제목 화면의 디버그 메뉴와 URL에서 두 QA 상태로 직접 진입한다. 프로덕션 게임 흐름은 바꾸지 않는다.
- Verify: `flutter test test/services/debug_run_fixture_service_test.dart`

### Outcome 3: 검증된 웹 산출물 NAS 배포

- Work: `https://cheng80.myqnapcloud.com/rummipoker/`의 현재 핵심 파일 hash를 임시 보존하고 `tools/deploy_rummipoker_web.sh --debug-fixtures`로 QA 빌드를 배포한다. 기본 release 배포에서는 fixture 노출을 계속 끈다. 배포 뒤 지정 파일 hash, 공개 진입점, 배포 ZIP 제거를 확인한다.
- Risks/open questions: Safari에서 실제로 소리가 들리는지는 자동 테스트와 HTTP 검사만으로 증명할 수 없다. 이번 배포는 사용자가 두 픽스처로 실기 확인할 수 있는 상태까지 제공한다.
- Verify: `flutter analyze && flutter test && tools/deploy_rummipoker_web.sh --debug-fixtures`
