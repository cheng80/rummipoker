# Mimi Seed Agent

Mimi Seed MCP가 이 프로젝트에 연결되어 있습니다.
Google Play · App Store · Firebase · AdMob을 도구로 직접 제어합니다.

## 세션 시작

1. 출시/스토어/Firebase/AdMob 요청은 먼저 `mimi_seed_status`로 연결 상태를 확인
2. 인증 누락이면 `mimi_seed_auth_start` 또는 아래 로컬 인증 명령을 안내
3. Claude Code에서 도구 schema가 deferred 상태라면 필요한 도구를 `ToolSearch(query="select:<tool>[,<tool>...]")`로 먼저 로드

## 출시 요청 처리 순서

1. 항상 `playstore_check_submission_risks` / `appstore_check_submission_risks` 로 블로커 확인
2. 릴리즈 노트는 `docs/releases.json`을 SSOT로 확인/작성 → 사용자 확인 후 적용
3. 스토어 **쓰기** 작업(submit, apply, reply, delete)은 반드시 사용자 명시 동의 후 실행
4. 출시 완료 후 적용 결과와 실패 지점 요약

## 인증 복구

- Google/Firebase/AdMob/Play OAuth: `npx -y @yoonion/mimi-seed-mcp mimi-seed-auth`
- App Store Connect: `npx -y @yoonion/mimi-seed-mcp mimi-seed-appstore-auth`
- Play service account: `npx -y @yoonion/mimi-seed-mcp mimi-seed-playstore-auth`

## 앱 정보
  packageName: com.cheng80.rummipoker
  bundleId: com.cheng80.rummipoker
  bundleId: com.cheng80.rummipoker.RunnerTests

## 슬래시 커맨드

- `/mimi-seed:getting-started` — 처음 사용자 온보딩 (연결 스캔 → 능력 카탈로그 → 첫 액션)
- `/mimi-seed:deploy` — 전체 출시 파이프라인
- `/mimi-seed:health` — 연결 상태 빠른 확인
- `/mimi-seed:review-inbox` — 미답변 리뷰 답변