# Compute + Browser Full-Play Bot

> 문서 성격: 공모전 제출용 실제 UI full-play QA bot 제작 기준
> 호출 별명: `공모전 풀런봇`
> 영문 식별자: `contest_full_run_bot`
> 부분 실행 별명: `공모전 서브런봇`
> 부분 실행 영문 식별자: `contest_sub_run_bot`
> 1차 실행 환경: Browser/WebDriver + Compute Use hybrid
> 2차 보조 환경: Codex 앱 내장 Browser Use
> 현재 실행 라우터: `docs/planning/ACTIVE_EXECUTION_PLAN.md`
> 공모전 체크리스트: `docs/planning/competition/COMPETITION_SUBMISSION_CHECKLIST.md`

## 0. 제작 결론

공모전 full-play QA는 사람 수동 플레이가 아니라 제작된 bot 기준으로 닫는다.
bot은 Browser/WebDriver의 실행·로그 수집과 Compute Use의 화면 좌표·시각 조작을 함께 사용해 실제 Flutter Web 화면을 플레이한다.

앞으로 대화에서 `공모전 풀런봇 실행`, `공모전 풀런봇 준비`, `공모전 풀런봇 이어서`라고 말하면 이 문서의 Browser/WebDriver + Compute Use hybrid full-play gate를 뜻한다.
스크립트, 로그 prefix, 파일명에는 영문 식별자 `contest_full_run_bot`을 사용한다.

같은 엔진을 특정 목표 지점까지만 실행할 때는 `공모전 서브런봇`이라고 부른다.
스크립트, 로그 prefix, 파일명에는 영문 식별자 `contest_sub_run_bot`을 사용한다.

제작 기준:

- 1차 제출 gate는 Browser/WebDriver와 Compute Use를 결합해 재실행 가능해야 한다.
- Codex 앱 내장 Browser Use는 bot 실패 분석, 보조 눈검증, 최종 감각 확인에 사용한다.
- Browser/WebDriver는 앱 실행, console 확인, trace/video/screenshot 저장, runtime 상태 수집을 맡는다.
- Compute Use는 손패 타일, 보드 셀, 마켓 카드처럼 Flutter transform/canvas/semantics 때문에 selector tap이 흔들리는 실제 화면 조작을 맡는다.
- `tools/sim/planner_bot.dart`의 `planner_v2` 전투 판단은 재사용한다.
- 기존 시뮬레이션 bot만으로 통과 처리하지 않는다. 실제 UI 조작 증거가 필요하다.
- debug fixture, 즉시 클리어, forced reward 같은 보조 경로는 full-play 증거로 쓰지 않는다.

## 0.1 실행 방식 판단

1차 후보는 Browser/WebDriver + Compute Use hybrid다.
이유는 trace, video, screenshot, console log를 자동 산출물로 남기면서도 Flutter Web의 실제 화면 좌표 조작을 안정적으로 수행할 수 있기 때문이다.

단, Flutter Web은 일반 DOM 앱과 다르게 canvas/semantics 렌더링이 섞여 selector가 불안정할 수 있다.
Playwright나 Flutter `integration_test`의 selector/tap이 안정적이지 않으면 Browser-only 통과를 고집하지 않고 Compute Use 좌표 실행으로 전환한다.
이 경우에도 기준은 같다. 실제 Chrome에서 실행되고, debug fixture 없이 S1~S8을 UI action으로 클리어해야 한다.

| 후보 | 사용 판단 | 역할 |
|---|---|---|
| Browser/WebDriver + Compute Use | 1차 gate | 앱 실행, console/trace 수집, 화면 좌표 기반 실제 조작 |
| Playwright | text/role/key 기반 조작이 안정적인 구간에 사용 | trace/video/screenshot/console evidence |
| Flutter `integration_test` on Chrome | planner 상태 수집과 재현 가능한 smoke에 사용 | 실제 Chrome 실행 + widget 상태 확인 |
| Codex Browser Use | 1차 gate로 쓰지 않음 | 실패 분석, 보조 눈검증, 최종 감각 확인 |

## 0.2 실행 별명과 호출 예시

`공모전 풀런봇`은 S1부터 S8 boss 이후 런 완료/보상/도감 확인까지 닫는 최종 제출 gate다.
`공모전 서브런봇`은 같은 엔진을 쓰되 종료 조건만 제한해 특정 지점까지 빠르게 재현하는 부분 실행 bot이다.

| 별명 | 영문 식별자 | 목적 | 기본 종료 조건 |
|---|---|---|---|
| `공모전 풀런봇` | `contest_full_run_bot` | 최종 제출 full-play gate | S8 boss clear, 런 완료, 보상/복귀/도감 확인 |
| `공모전 서브런봇` | `contest_sub_run_bot` | 특정 stage/scene까지 재현, 실패 구간 격리 | 사용자가 지정한 target 도달 |

사용자가 이렇게 말하면 같은 의미로 해석한다.

- `공모전 풀런봇 실행`: S1부터 S8 boss 이후 제출 Done 기준까지 진행한다.
- `공모전 풀런봇 이어서`: 마지막 중단 지점과 로그를 확인해 가능한 경우 이어서 진행한다.
- `공모전 서브런봇 S3까지`: S3의 지정 tier 또는 기본 boss clear 후 정지한다. tier가 없으면 S3 boss clear를 기본 목표로 본다.
- `공모전 서브런봇 S5 Market까지`: S5 전투 클리어 후 Market 진입을 확인하고 정지한다.
- `공모전 서브런봇 S8 Boss 진입까지`: S8 boss 전투 화면 진입을 확인하고 정지한다.
- `공모전 서브런봇 아이템 사용까지`: 첫 실제 Item 사용 증거를 확보하면 정지한다.

서브런봇 target은 아래 필드로 기록한다.

```text
contest_sub_run_bot target
- targetStage: S1..S8
- targetTier: small | big | boss | any
- targetScene: Title | NewRunSetup | StationSelect | Battle | CashOut | Market | RunComplete | Archive
- requiredEvidence: market_purchase | item_purchase | item_use | boss_seen | boss_clear | reward_seen | archive_seen
```

서브런봇 결과는 full-play Done을 대체하지 않는다.
특정 구간 실패 재현, 좌표 보정, 마켓/아이템 정책 검증, 제출 영상 후보 장면 확인에만 사용한다.

## 1. Done 기준

아래를 모두 만족해야 bot 제작과 full-play QA를 완료로 본다.

- 최신 제출 후보 web build 또는 최신 Flutter web-server에서 시작한다.
- 새 run을 시작해 S1 small부터 S8 boss까지 실제 화면 조작으로 클리어한다.
- 각 station에서 전투 진입, 드로우, 타일 배치, 확정, 정산, 마켓 이동을 실제 UI로 수행한다.
- 마켓에서 최소 1회 이상 Jester 또는 카드형 성장 구매를 수행한다.
- 마켓에서 최소 1회 이상 Item 구매를 수행한다.
- 전투 또는 마켓에서 최소 1회 이상 Item을 실제 사용한다.
- S8 boss 이후 런 완료, 보상 확인, 새 run 복귀 또는 도감 반영까지 확인한다.
- Browser/WebDriver console log 기준 새 error/warn 0건을 확인한다.
- 실행 로그에는 stage, blind tier, 구매 내역, 아이템 사용, stop reason, console 결과를 남긴다.

## 2. 구조

```text
최신 web build/server
  |
  v
Browser/WebDriver
  - 앱 실행
  - console error/warn 확인
  - trace/video/screenshot 저장
  |
  v
Compute 판단
  - 현재 scene 판정
  - 전투 action 결정
  - 마켓 action 결정
  - 실패/재시도 판단
  |
  v
Compute Use 실행
  - 실제 화면 좌표 클릭/드래그
  - 손패/보드/마켓 카드 조작
  - selector tap 실패 구간 fallback
  |
  v
Full-play evidence
  - S1~S8 clear trace
  - market purchase trace
  - item use trace
  - reward/archive/new run trace
```

## 3. 판단 계층

### 전투 판단

전투 판단은 기존 `planner_v2`를 우선 재사용한다.

`planner_v2`가 내는 action을 실제 UI 조작으로 번역한다.

| Bot action | Hybrid 조작 |
|---|---|
| `draw` | text/role click 우선, 실패 시 Compute Use로 드로우 버튼 좌표 클릭 |
| `place(handIndex,row,col)` | Browser runtime 상태로 대상 타일/셀을 정하고 Compute Use로 손패 타일과 보드 셀 좌표 클릭 |
| `confirm` | text/role click 우선, 실패 시 Compute Use로 확정 버튼 좌표 클릭 |
| `discardBoard(row,col)` | Compute Use로 보드 셀과 보드 버림 버튼 좌표 클릭 |
| `stop(reason)` | 실행 중단, 로그에 reason 기록 |

Browser/WebDriver에서 직접 읽은 runtime 상태를 `planner_v2` 입력으로 넘긴다.
화면과 runtime 상태가 어긋나면 Compute Use screenshot으로 hand/board/score/target을 다시 판독하고, 그 결과를 로그에 남긴 뒤 action을 재선택한다.

### 마켓 판단

마켓은 기존 경제/레벨링 bot의 구매 proxy를 참고하되, full-play QA용으로 아래 정책을 둔다.

- 구매 가능하면 성장 효과가 분명한 Jester를 우선 구매한다.
- Item offer가 있고 골드가 충분하면 최소 1개는 구매한다.
- quick slot 또는 즉시 사용 가능한 utility item은 다음 전투 또는 마켓에서 실제 사용한다.
- 슬롯이 부족하면 판매가 가능한 항목을 팔지, 구매를 포기할지 Compute 판단으로 결정하고 로그에 남긴다.
- 리롤은 무료/할인 조건이 화면에 보일 때 우선 사용하되, S1~S8 클리어 안정성을 해치지 않는 선에서만 사용한다.

## 4. Scene 상태 기계

```text
Title
  -> NewRunSetup
  -> StationSelect
  -> Battle(Small)
  -> CashOut
  -> Market
  -> StationSelect
  -> Battle(Big)
  -> CashOut
  -> Market
  -> StationSelect
  -> Battle(Boss)
  -> CashOut
  -> Market
  -> ... repeat until S8 Boss
  -> RunComplete
  -> Reward
  -> Title or NewRunSetup
  -> Archive spot-check
```

허용되지 않는 경로:

- `fixture=` route로 시작
- `현재 구간 즉시 클리어` 같은 debug action 사용
- S8 fixture로 직접 점프
- 시뮬레이션 결과만 보고 UI QA를 통과 처리

## 5. 실행 로그 형식

full-play 실행 결과는 daily log 또는 별도 QA 로그에 아래 형태로 남긴다.

```text
Full-play bot run
- build/server: <path-or-url>
- seed/difficulty/modifier: <value>
- runner: Browser/WebDriver + Compute Use hybrid
- start time: <local time>
- console baseline timestamp: <timestamp>
- result: pass/fail
- last scene: <scene>
- reached stage: S<n> <small|big|boss>
- market purchases:
  - S<n> Market: <item-or-jester-id/display-name>, price <gold>
- item uses:
  - S<n> <battle|market>: <item-id/display-name>, result <summary>
- S1~S8 trace:
  - S1 small: clear
  - S1 big: clear
  - S1 boss: clear
  - ...
  - S8 boss: clear
- console: error 0, warn 0
- screenshots/video: <paths-if-any>
- notes: <known-risk-or-observation>
```

## 6. 제작 범위와 보류

이번 제작 범위:

- full-play bot 기준을 공모전 Done Evidence로 고정한다.
- Browser/WebDriver + Compute Use hybrid를 1차 제출 gate로 문서화한다.
- Codex 내장 Browser Use는 보조 디버깅/눈검증 경로로 문서화한다.
- 기존 `planner_v2`를 전투 판단 엔진으로 재사용한다.
- 마켓 구매와 아이템 사용을 full-play 필수 증거에 포함한다.

이번 범위에서 하지 않는 것:

- Browser Use만으로 제출 gate를 닫는 방식
- Browser-only selector/tap만으로 Flutter Web 조작 안정성을 보장했다고 보는 방식
- production runtime 자동 밸런싱
- ML 추천 모델 갱신
- 사람 수동 플레이를 full-play evidence로 대체
- debug fixture 기반 S8 점프를 full-play evidence로 인정

## 7. 다음 실행 순서

1. `tools/prototype_submission_smoke.sh`로 analyze/test/build 후보를 만든다.
2. 최신 build 또는 Flutter web-server URL을 Browser/WebDriver로 열고 console/trace 수집을 시작한다.
3. Compute 판단으로 현재 scene을 분류한다.
4. 전투에서는 `planner_v2` action을 Compute Use 화면 좌표 조작으로 번역한다.
5. 마켓에서는 구매/리롤/판매/아이템 사용 정책을 Compute Use 조작으로 적용한다.
6. S8 boss clear 후 보상, 새 run 복귀, 도감 반영을 확인한다.
7. console error/warn 0건과 실행 로그를 competition checklist에 반영한다.
