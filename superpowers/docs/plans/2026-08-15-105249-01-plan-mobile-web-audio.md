# 모바일 웹 오디오 안정화와 NAS 배포

**Goal:** Rummi Poker의 실제 웹 오디오 경로를 비교 검증해 효과음 누락 위험의 근본 원인만 최소 수정하고, NAS 배포본을 연결된 iPhone Safari에서 확인한다.
**Why planning is required:** 운영 NAS 배포와 실기기 원격 검사가 포함된 외부 상태 변경 작업이다.
**Acceptance:** 기준 SHA `f21b7d8`에서 시작해 관련 테스트·분석·웹 빌드가 통과하고, 사용자 승인 대상인 `https://cheng80.myqnapcloud.com/rummipoker/`에 배포한다. 배포 전 현재 원격 핵심 파일 hash를 rollback 근거로 저장하며, 검사 실패·배포 응답 실패·원격 hash 불일치·오디오 MIME 오류가 있으면 다음 단계로 진행하지 않는다. 배포 후 핵심 파일 hash, 진입점, 업로드 ZIP 제거와 iPhone Safari의 실제 사용자 제스처 이후 BGM·SFX·console·network를 확인한다.

### Outcome 1: Rummi Poker에 맞는 원인과 최소 수정 확정
- Work: `SoundManager`, 호출자, `audioplayers`·`flame_audio` 설치 버전과 실제 `AudioPool` 구현, 웹 자산 경로를 Stone Match 사례와 비교한다. 플레이어 증가, 자산 URL, 반복 unlock 중 일치하는 원인만 수정하고 재현 가능한 회귀 테스트를 남긴다.
- Risks/open questions: iPhone Safari에서만 나타나는 누락은 데스크톱 자동 테스트로 완전히 증명할 수 없다. 렌더링 최적화는 Rummi Poker hot path 근거가 있을 때만 포함한다.
- Verify: `flutter test test/resources/sound_manager_test.dart`

### Outcome 2: 배포 가능한 웹 산출물 검증
- Work: 관련 전체 회귀, 정적 분석, 문서 일치, release web build와 오디오 자산의 실제 build 경로·MIME 기대값을 확인한다.
- Verify: `flutter analyze && flutter test && dart run tools/generate_docs.dart --check && git diff --check`

### Outcome 3: NAS 배포와 rollback 가능 상태 확인
- Work: 배포 직전 target revision과 clean scope를 재확인하고 현재 원격 핵심 파일 hash를 임시 근거로 보존한다. `tools/deploy_rummipoker_web.sh`로 rollout한 뒤 로컬·원격 8개 파일 SHA-256, public entrypoint, `rummipoker.zip` 404와 대표 오디오 응답을 확인한다. 실패 시 추가 배포를 중단하고 이전 원격 hash·Git 기준으로 복구 판단을 남긴다.
- Verify: `tools/deploy_rummipoker_web.sh`

### Outcome 4: 연결된 iPhone Safari 실기 검증
- Work: 배포 URL을 Safari에서 열고 최초 사용자 제스처 후 BGM과 연속 SFX를 재생한다. 원격 Web Inspector에서 console 오류, 실제 오디오 URL·Content-Type, 가능한 재생 진단 상태를 확인한다. Inspector가 노출되지 않으면 연결 상태와 실패 원인을 기록하고 `xctrace` 또는 원격 HTTP·실기 청취 근거로 가능한 범위까지 검증한다.
- Verify: `xcrun devicectl list devices`

### Outcome 5: lifecycle 복귀 후 BGM 무음 회귀 수정
- Reproduction: iPhone Safari에서 background/foreground 복귀 후 자동 일시정지 화면을 닫으면 SFX는 정상이나 BGM만 복귀하지 않는다. 일반 options pause와 lifecycle pause를 분리 확인한다.
- Hypothesis: lifecycle pause가 BGM을 pending으로 표시하지만 최초 SFX unlock 뒤의 `unlockForWeb()` 조기 반환이 다음 사용자 제스처의 BGM 복구를 차단한다. 또한 `audioplayers_web 5.1.1`의 기존 player는 내부 `AudioContext` 상태를 노출하지 않으므로 pending 복구 때 resume 상태를 신뢰하지 않고 새 player/context로 재생해야 한다.
- Stop conditions: focused 회귀 테스트, 전체 테스트, release build 중 하나라도 실패하거나 iPhone에서 pause→resume BGM 복귀가 확인되지 않으면 재배포 완료로 판정하지 않는다.
- Rollback: 직전 NAS 배포 hash와 `/tmp/rummipoker_predeploy_20260815_1100/SHA256SUMS`를 유지하고, 새 배포 hash 불일치 시 추가 rollout을 중단한다.

### Outcome 6: 북마크 저장 후 옵션 자동 종료의 BGM 복귀 순서 수정
- Reproduction: 같은 lifecycle 일시정지 화면에서 일반 닫기는 BGM이 복귀하지만, `북마크하기`를 완료해 화면이 자동 종료되면 BGM이 무음이다. 메인 화면에서 북마크를 불러와 route 재진입하면 BGM은 정상이다.
- Hypothesis: 두 경로는 모두 `resumeGame` 결과로 같은 cleanup branch에 도달하지만, 북마크 경로만 slot 선택·확인 뒤 비동기 저장을 기다린다. WebKit의 transient user activation이 끝난 뒤 `resumeBgm()`이 실행되어 HTML media `play()`가 소리 없이 복귀하지 못한다. 저장 데이터·SFX pool·BGM asset은 원인이 아니다.
- Cheapest check: 일반 닫기와 북마크 저장 경로의 `Navigator.pop` 전후 호출 순서를 비교하고, Inspector에서 `HTMLMediaElement.play/pause`와 user activation을 임시 기록한다.
- Fix boundary: 저장 자체나 SFX를 바꾸지 않는다. 마지막 slot/덮어쓰기 사용자 gesture가 살아 있는 동안 기존 공용 BGM 시작 경로를 재사용하고, 고정 delay나 별도 player 추상화를 추가하지 않는다.
- Stop conditions: 정확한 pause→bookmark→dialog close 회귀 테스트, 전체 테스트, release build, 동일 iPhone Safari 재현 중 하나라도 실패하면 완료하지 않는다.
- Superseded evidence: Inspector에서 북마크 제스처의 BGM `play()`는 user activation이 활성인 상태로 실제 호출됐다. 따라서 비동기 저장 뒤 activation 소실이 확정 원인이 아니며, 해당 전용 조기 재생은 Outcome 7의 pause/options 무음 계약을 위반해 제거한다.

### Outcome 7: pause/options 표시 중 조기 BGM 복귀 차단
- Reproduction: 최종 iPhone Safari 검사에서 focus-out→foreground 뒤 pause/options 화면이 보이는 동안 `Main_BGM`의 `play()`가 2회 호출됐다. 북마크 저장 제스처에서도 실제 gameplay 복귀 전에 BGM이 시작됐다.
- Root cause hypothesis: 앱 전역 pointer unlock과 북마크 전용 복귀 호출이 lifecycle pending BGM을 pause/options overlay 안에서 소비한다. 북마크 성공 시 options를 자동 종료해 명시적인 `계속하기` 전환도 우회한다.
- Cheapest check: pause/options 범위를 기존 BGM auto-resume block으로 감싸고, 일반 닫기·북마크 저장·명시적 닫기의 BGM 복귀 counter를 정확한 widget sequence로 비교한다.
- Fix boundary: SFX unlock/pool은 유지한다. 북마크 저장은 options를 닫거나 BGM을 재개하지 않고, options가 실제로 닫힌 공용 `resumeGame` branch 한 곳에서만 사용자 제스처 BGM 복귀를 실행한다. 고정 delay·새 상태 머신·새 player 추상화는 추가하지 않는다.
- Acceptance: focus-out→return→pause dialog visible 및 bookmark 완료 후에도 BGM paused, 명시적 continue 직후 BGM resume/start, SFX 정상, console/audio network 신규 오류 없음.
- Stop conditions: exact focused test, analyze/full test, release build, NAS hash/entrypoint/zip, 동일 iPhone Inspector 경로 중 하나라도 실패하면 완료하지 않는다.
- Current verification: exact test red(`resume count 0`, expected 1)→green, focused 14 pass, `flutter analyze` no issues, full 745 pass/3 skip, docs/diff check pass, NAS base-href release build pass. 소스와 release JS에 임시 `__bgmTrace`/`qa_bgm` 계측은 없다.
- Deployment result: 기본 checkout의 권한 600 `.env`를 복사 없이 `--env-file`로 참조해 HTTP 200 배포했다. 원격 8개 SHA가 local build와 일치했고 entrypoint 200, 서버 ZIP 404, BGM/SFX `audio/mpeg`를 확인했다. 이전 hash는 `/tmp/rummipoker_predeploy_20260815_smZyLw/SHA256SUMS`에 보존했다.
- iPhone result: iPhone 14 Pro Max Safari cache-bust 빌드에서 focus-out→return→options visible은 BGM `pause` 뒤 추가 `play` 0, bookmark 저장 뒤 options 유지 및 추가 `play` 0, 명시적 continue 직후 `play` 1 증가(`userActivation=true`, `playError=0)를 Inspector로 확인했다. 최종 SFX는 `plays=4`, `drops=0`, `errors=0`, `slots=4`였고 사용자가 BGM 정상 청취를 확인했다. console 오류 1건은 기존 `flutter.js.map` 404뿐이다. 페이지 전용 trace wrapper는 원복해 `trace=undefined`, `wrapped=false`를 확인했다.
