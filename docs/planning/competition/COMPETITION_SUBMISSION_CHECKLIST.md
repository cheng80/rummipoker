# Competition Submission Checklist

> 문서 성격: 공모전 제출 준비용 실행 체크리스트
> 현재 실행 라우터: `docs/planning/ACTIVE_EXECUTION_PLAN.md`
> 기준 문서: `docs/planning/goal/OVERALL_GOAL_PROGRESS.md`, `docs/planning/leveling/LEVELING_APPLIED_STATUS.md`, `docs/current_system/CURRENT_LEVELING_POLICY.md`
> 목표: BIC 일반부문 1차 접수용 플레이 가능 빌드를 안정적으로 제출한다.
> full-play gate 별명: `공모전 풀런봇` (`contest_full_run_bot`)

이 문서는 공모전 제출 전 남은 작업을 작은 단위로 추적한다.
현재 활성 트랙과 다음 작업 선택은 `docs/planning/ACTIVE_EXECUTION_PLAN.md`를 따른다.
전체 진도와 장기 목표 판단은 `docs/planning/goal/OVERALL_GOAL_PROGRESS.md`를 기준으로 하고, 이 문서는 제출 준비 실행표로만 사용한다.

## 0. 제출 작업 첫 화면

현재 결론:

- 공모전 작업은 재개 가능하다.
- 제출 전 핵심은 새 기능 추가가 아니라 최신 빌드, Browser/WebDriver + Compute Use hybrid full-play bot, console 0건, 보상/도감/새 run 화면의 체감 QA다.
- runtime/economy/boss pool은 공모전 기준 임시 handoff 가능 상태이며, 장기 밸런스 완료는 아니다.
- full-play 기준은 사람 수동 플레이가 아니라 제작된 bot이 Browser/WebDriver의 실행·로그 수집과 Compute Use의 화면 좌표 조작을 결합해 S1~S8을 클리어하는 것이다.
- 이 hybrid full-play bot의 대화 호출 별명은 `공모전 풀런봇`이고, 영문 식별자는 `contest_full_run_bot`이다.
- Codex 앱 내장 Browser Use는 제출 gate가 아니라 bot 실패 구간 분석, 보조 눈검증, 최종 감각 확인에 사용한다.

오늘 바로 할 작업:

1. 최신 변경 후 제출 후보 web build를 다시 만든다.
2. 새 web-server 또는 최신 build 기준으로 console error/warn 0건을 확인한다.
3. Browser/WebDriver + Compute Use hybrid bot으로 debug fixture 없이 S1부터 S8까지 실제 UI full-play를 수행한다.
4. 게임오버 보상, 도감 카드 face, 새 run 화면이 다시 시작 욕구와 수집 욕구로 읽히는지 눈검증한다.
5. 제출 영상 촬영 기준으로 전투/마켓/정산/도감/새 run 화면이 한 게임처럼 이어지는지 확인한다.

제출 후보 Done 기준:

- `flutter analyze` 통과
- 핵심 `flutter test` 통과
- 최신 `flutter build web` 통과
- 최신 빌드 기준 Browser/WebDriver full-play QA console error/warn 0건
- Browser/WebDriver + Compute Use hybrid bot으로 debug fixture 없이 S1~S8 clear 확인
- full-play 중 마켓 구매와 아이템 실제 사용 증거 확인
- 게임오버/런 완료 보상, 도감, 새 run 복귀가 심사자에게 설명 없이 읽힌다는 눈검증

아직 열려 있는 위험:

- Browser/WebDriver + Compute Use hybrid full-play bot의 S1~S8 실제 UI clear 증거는 아직 없다.
- 도감은 수집/발견/구매/보상/보스/스테이지 이력을 저장하지만, 항목별 미발견/발견/획득/클리어 상태 상세 UI는 남아 있다.
- `power none`과 `balanced v9` seed 편차는 장기 밸런스 risk로 유지한다.
- 기억 카드 보상은 현재 기억 카드류 이력에 한정하며, 실제 보상 아이템/Jester 지급은 아직 없다.

## 1. 기준과 보류 항목

- 공모전 작업은 재개 가능하다.
- runtime/economy/boss pool은 공모전 기준 임시 handoff 가능 상태다.
- ML 갱신, production ML, runtime 자동 밸런싱은 보류한다.
- `power none` clear가 일부 seed에서 높고, `balanced v9`가 한 seed에서 60%를 살짝 밑도는 점은 known risk로 둔다.
- 세부 레벨링 재조정보다 플레이 가능성, 이해도, 제출 안정성을 우선한다.
- 도감, 보상 카드, 해금 확인 흐름은 공모전 이해도에 필요한 항목으로 본다. 필요하면 UI와 저장 구조 변경도 구현 대상으로 올린다.
- 완료 체크는 기능 존재만으로 닫지 않는다. 게임완성도, 심미성, 재미도, full-play bot 증거, 최신 제출 후보 빌드 기준으로 다시 본다.
- full-play bot 제작 기준은 `docs/planning/competition/COMPUTE_BROWSER_FULL_PLAY_BOT.md`를 따른다.

## 2. 공모전 마감 재점검

Status: In progress

- [ ] 최신 변경 후 제출 후보 web build를 다시 만든다.
- [ ] 최신 빌드 또는 새 web-server에서 console error/warn 0건을 다시 확인한다.
- [ ] Browser/WebDriver + Compute Use hybrid bot으로 debug fixture 없이 S1~S8 실제 UI clear를 확인한다.
- [ ] full-play bot이 마켓 구매와 아이템 실제 사용을 수행하고 로그에 남긴다.
- [ ] 게임오버 화면이 패배 후 다시 시작하고 싶게 만드는지 확인한다.
- [ ] 도감의 Jester/Item 카드가 마켓/보유 슬롯의 실물 카드 face와 같은 인상인지 확인한다.
- [ ] 첫 10분 플레이에서 “목표 이해 -> 선택 -> 결과 -> 보상 -> 다시 시작” 흐름이 심사자에게 설명 없이 읽히는지 확인한다.
- [ ] 제출 영상 촬영 기준으로 전투/마켓/정산/도감/새 run 화면이 한 게임처럼 이어지는지 확인한다.

완료로 되어 있지만 재점검할 항목:

- `Submission Smoke`의 `flutter build web` 통과는 최신 도감/게임오버 변경 전 증거일 수 있으므로 다시 실행한다.
- Browser Use full route QA는 debug fixture/즉시 클리어 보조가 섞였으므로 full-play bot 증거가 아니다.
- 게임오버 보상 루프는 저장/이동은 구현됐지만, 재도전 욕구와 보상감은 아직 눈검증이 필요하다.
- 도감은 수집 저장과 실물 카드 face 1차 표시가 됐지만, 항목별 상태와 화면 밀도는 아직 재점검 대상이다.

## 3. 텍스트/네이밍/IP 리스크

Status: In progress

- [x] 플레이어 노출 텍스트에서 원본 IP 냄새가 나는 이름을 찾는다.
- [x] `Joker` 원명이나 참고작 고유 조합명을 런타임 표시명/UI copy에서 제거한다.
- [x] `Jester`는 우리 게임 용어로 유지한다.
- [x] 보스 표시명과 설명은 우리 게임 룰 용어로 읽히게 정리한다.
- [x] 카드/Jester/Item/보스 효과 설명은 “언제, 무엇이, 얼마나, 언제까지”가 짧게 읽히게 정리한다.
- [x] 텍스트 변경 후 관련 fixture/test 또는 grep으로 잔여 표현을 확인한다.

진행 메모:

- `data/common/jesters_common_phase5.json`과 `assets/translations/data/{ko,en}/jesters.json`는 이미 독자 표시명 기준이었다.
- QA fixture로 화면에 노출될 수 있는 `lib/services/debug_run_fixture_service.dart`의 원본 계열 Jester 표시명을 `Run Call`, `Face Battery`, `Momentum Meter`, `Fading Boost`, `Reserve Coin`으로 교체했다.
- `Crazy Jester`, `Scary Face`, `Green Jester`, `Popcorn`, `Egg`, `Played hand`, `face cards`, `Straight`, `Flush`는 debug fixture에서 제거했다.
- 영어 Jester/Item fallback과 상점 tag label의 `Straight`/`Flush` 표현을 `run`, `same-color`, `Run`, `Color` 기준으로 바꿨다.
- 보스 modifier title/ruleText는 원본명 없이 색상/라인/확정/족보 제한으로 읽힌다.

## 4. 보스/상점/정산 설명 QA

Status: In progress

- [x] 보스 제약 설명이 말줄임표 없이 읽히는지 확인한다.
- [x] 타일 위 제약 배지가 숫자와 색상 바를 가리지 않는지 확인한다.
- [x] 라인 제약은 개별 타일 배지로 잘못 표시되지 않는지 확인한다.
- [x] 상점 첫 리롤 무료 문구가 `첫 리롤 무료`로 보이는지 확인한다.
- [x] 리롤 확인창에 `상점 입장 보너스로 첫 리롤은 무료입니다.`가 보이는지 확인한다.
- [x] `정찰` 표현이 플레이어 노출 텍스트에 남아 있지 않은지 확인한다.
- [x] 정산 보상/기억 카드/런 완료 문구가 짧고 명확한지 확인한다.

진행 메모:

- 보스 제약 dialog의 `ruleText`는 내부 스크롤로 표시되고 말줄임표를 쓰지 않는다.
- `test/views/game/widgets/game_shop_reroll_confirmation_test.dart`에서 무료 리롤 버튼과 확인창 문구를 검증했다.
- `test/views/game/widgets/game_cashout_widgets_test.dart`에서 기억 카드 보상, 일반 정산의 `Market으로`, 최종 정산의 `계속 진행`/`런 완료` 분기를 검증한다.
- Browser Use QA에서 `boss_row_constraint_preview`는 라인 제약이 보스 팝업/preview 문구로만 표시되고 개별 타일 배지로 뜨지 않는 것을 확인했다.
- Browser Use QA에서 S1 Boss 색상 제약은 보드 위 타일 숫자와 색상 바를 가리는 별도 배지 없이 표시되는 것을 확인했다.

## 5. 핵심 Run Flow QA

Status: In progress

- [ ] 새 run 시작 -> 전투 -> 마켓 -> 보스 -> 정산 -> 게임오버/런 완료 -> 실제 보상 획득 -> 새 run 복귀가 자연 플레이 기준 end-to-end로 끊기지 않는다.
- [x] debug fixture/즉시 클리어 보조를 사용한 split QA에서 주요 화면 전환이 끊기지 않는지 확인한다.
- [x] 새 run 시작이 정상 동작한다.
- [x] S1 전투에서 배치, 확정, 드로우, 버림이 끊기지 않는다.
- [x] 전투 후 마켓 진입이 정상 동작한다.
- [x] 구매, 판매, 장착, 사용, 리롤이 정상 동작한다.
- [x] 보스 전투 후 정산 또는 실패 흐름이 정상 동작한다.
- [x] 게임오버 시 보상 확인 후 Title 또는 새 run 화면으로 돌아갈 수 있다.
- [x] 런 완료 시 보상 확인 후 Title 또는 새 run 화면으로 돌아갈 수 있다.
- [x] 실제 기억 카드 획득 후 다음 새 run 시작 화면과 도감에서 최신 상태가 보인다.
- [x] 저장/이어하기가 현재 runtime state 기준으로 복구된다.
- [x] presentation state가 저장 기준으로 섞이지 않는다.

진행 메모:

- `test/views/game/game_view_test.dart`, `test/services/active_run_save_service_test.dart`, `test/services/run_progression_service_test.dart`, `test/services/run_unlock_state_service_test.dart`, `test/services/run_completion_flow_test.dart` 통과.
- 저장/복원 테스트에서 boss modifier, 확정 transaction, stageStartSnapshot round-trip을 확인했다.
- Browser Use로 Flutter web-server 기준 split QA를 수행했고, fresh origin은 `127.0.0.1:7360`으로 다시 확인했다.
- Title -> 새 게임 시작 -> 새 run 설정 -> 랜덤 시작 -> Station Select -> S1 전투 진입 -> 드로우 -> 타일 배치까지 실제 화면에서 확인했다. S1 확정/버림까지의 완전 수동 플레이는 아직 별도 확인이 필요하다.
- Browser Use로 fresh origin `127.0.0.1:7360`에서 새 run 설정 화면을 다시 확인했다. 난이도는 `표준`/`도전`만 노출되고, `도전` 선택 후 URL이 `difficulty=challenge`로 유지되며 S1 Scout 목표가 288로 표시돼 표준 240 대비 1.2배 target이 적용되는 것을 확인했다.
- `game_over_insight_ready` fixture에서 드로우 후 게임오버 dialog가 표시되고, 보상 카드가 `기억 카드 획득`으로 보이며 `나가기` 후 Title과 새 run 화면으로 복귀하는 것을 확인했다.
- `final_boss_cash_out_ready` fixture에서 S8 Boss 확정 후 정산 완료 sheet가 `런 완료`, `계속 진행`, `기억 카드 획득`을 표시하고, `런 완료`는 Title로 복귀하며 `계속 진행`은 Market과 S9 Station Select로 이어지는 것을 확인했다.
- Browser Use QA에서 S1 전투의 드로우, 손패 버림, 타일 배치, 확정 버튼 피드백이 새 console error 없이 동작하는 것을 확인했다.
- 최신 `127.0.0.1:7361` 기준 Browser Use 한 세션에서 Title -> 새 run -> Station Select -> Scout/Clash/Boss -> 정산 -> Market -> 다음 Station 흐름을 확인했다. 전투 클리어는 디버그 `현재 구간 즉시 클리어` 보조를 사용했다.
- 같은 Browser Use QA 세션에서 `final_boss_cash_out_ready` fixture로 S8 정산 완료 -> `런 완료` -> Title -> `새 게임 시작` -> 새 run 화면 복귀까지 최신 문구 기준으로 다시 확인했다.
- 위 QA는 화면 전환 smoke이며, 실제 수집 보상까지 포함한 full-play bot 증거가 아니다.
- 디버그 보조 없는 S1~S8 bot full-play와 실제 보상 획득/저장/도감 반영은 다시 확인해야 한다.
- 2026-05-07: 게임오버에서 `새 run 준비` CTA를 추가했고, 보상/수집 기록은 `run_unlock_state_v1`에 저장해 새 run 화면과 도감에서 읽을 수 있게 했다. full-play bot QA는 아직 열려 있다.

## 6. 게임오버/런 완료 보상 루프

Status: In progress

- [x] 패배 시 기억 카드 보상이 보인다.
- [x] 패배 후 Title 또는 새 run 화면으로 자연스럽게 돌아간다.
- [x] S8 boss 완료 후 런 완료 또는 계속 진행을 선택할 수 있다.
- [x] 런 완료 보상 후 내부 메타 값이 반영된다.
- [x] 게임오버/런 완료 기억 카드 보상이 단순 내부 수치가 아니라 획득 이력으로 저장된다.
- [x] 획득한 기억 카드 보상이 새 run 화면과 도감에서 확인된다.
- [x] high stakes 해금/선택 상태가 기존 저장과 충돌하지 않는다.
- [x] 새 run 재시작 동선이 심사자가 이해할 수 있게 이어진다.
- [x] 회차 결과 보상 산식이 도달 스테이션, 보스 처치 수, 클리어 여부를 기준으로 계산되는지 확인한다.
- [x] 보상이 다음 run의 선택지를 여는 역할에 머물고, 인런 자동 지급이나 특정 성장 강제가 되지 않는지 확인한다.
- [x] high stakes처럼 회차 선택으로 바뀌는 target/reward 배율이 UI preview, runtime, 저장/복원에서 같은 값으로 이어지는지 확인한다.
- [x] 회차 보상이 너무 커서 다음 run 난이도를 무효화하지 않는지 공모전 기준 known risk로 남길지 판단한다.

진행 메모:

- `GameOverInsightRewardCard`와 `GameCashOutSheet` 테스트에서 기억 카드 보상과 `런 완료` 분기를 확인한다.
- `RunProgressionService`와 `RunUnlockStateService` 테스트에서 보상/해금 상태 갱신을 확인했다.
- 현재 내부 보상 산식은 도달 스테이션, 보스 처치 수, 클리어 보너스를 더해 메타 보상값을 계산한다.
- 플레이어에게는 수치 재화가 아니라 `기억 카드` 전용 보상처럼 보여준다. 내부 `insight` 계열 값은 유지하되, 별도 `earnedMemoryCardIds` 이력을 함께 남긴다.
- 현재 `high_stakes`는 내부 메타 보상값으로 해금되며 target score 1.04, reward 1.12를 명시 적용한다. 직접 골드, 아이템, Jester, 자원을 지급하지 않는다.
- S8 Boss 정산 후 `계속 진행`을 고르면 S8 승리 보상/난이도 해금을 1회 처리한 뒤 Market으로 들어가고, 다음 Station에서 S9+ 기록 도전으로 이어진다.
- S8 승리 보상은 `runCompletionRewardClaimed`로 저장/복원해 계속 진행 중 중복 지급되지 않게 했다.
- 보상 산식상 S8 완료 보상은 기억 카드 36이며, 현재 이 값은 인런 자원이 아니라 `하이 스테이크` 같은 다음 런 규칙을 여는 데만 쓰인다. 공모전 기준으로는 다음 run 난이도를 무효화하는 즉시 위험보다 해금 선택 폭이 아직 얕은 점을 known risk로 둔다.
- Browser Use QA에서 패배 후 `나가기` -> Title -> `새 게임 시작` -> 새 run 설정 화면 복귀를 확인했다.
- Browser Use QA에서 런 완료 후 `런 완료` -> Title -> `새 게임 시작` -> 새 run 설정 화면 복귀를 확인했다.
- 최신 소스 기준 게임오버/런 완료 보상은 수치 재화 문구가 아니라 `기억 카드 획득` 카드로 보인다. 이전 `build/web` 산출물에서는 stale build 때문에 구버전 보상 문구가 보였으므로 제출 후보 빌드는 반드시 최신 소스로 재빌드해야 한다.
- 실제 보상 아이템/Jester 지급은 아직 없다. 현재 보상 이력은 기억 카드류 보상에 한정한다.

## 7. 도감/수집 확인

Status: In progress

- [x] Title에서 도감 화면으로 들어갈 수 있다.
- [x] 도감 placeholder에 `기억 카드`가 전용 보상 카드처럼 표시된다.
- [x] 도감 placeholder에 `하이 스테이크` 런 규칙 설명이 표시된다.
- [x] 도감 placeholder에 Jester/Item/Boss 주요 항목이 표시된다.
- [x] 기억 카드가 어떤 해금에 쓰이는지 도감과 새 run 화면이 같은 말로 설명한다.
- [x] 도감 화면에서 수치 재화처럼 보이는 `Insight +N` 표현이 노출되지 않는다.
- [x] 도감이 실제 발견/획득/구매/클리어 상태를 저장하고 복원한다.
- [x] 마켓에 한 번이라도 나온 Jester/Item을 발견 항목으로 남긴다.
- [x] 구매한 Jester/Item을 획득 이력으로 남긴다.
- [x] 게임오버/런 완료 보상으로 얻은 기억 카드류 보상을 도감에 남긴다.
- [x] 만난 Boss와 보스 규칙을 도감에 남긴다.
- [x] 클리어한 스테이지/Station/Boss 진행 이력을 도감에서 확인할 수 있다.
- [ ] 도감 항목이 미발견/발견/획득/클리어 같은 상태를 구분한다.

진행 메모:

- Title의 `기록실` 진입은 `도감`으로 바꿨다.
- 도감에는 `기억 카드`, `하이 스테이크`, `Jester`, `Item`, `Boss` 항목을 공모전 확인용 placeholder로 먼저 배치했다.
- 게임오버 보상, 새 run 화면, 도감 화면에서 `Insight +N` 같은 수치 재화 표현이 보이지 않는 것을 grep과 web screenshot으로 확인했다.
- 내부 메타 보상값은 유지하되, 도감용 수집 이력은 `run_unlock_state_v1`의 `seenMarketJesterIds`, `seenMarketItemIds`, `boughtJesterIds`, `boughtItemIds`, `seenBossModifierIds`, `clearedStationKeys`, `earnedMemoryCardIds`에 따로 저장한다.
- 도감은 내 기록 섹션에서 실제 Jester 카드 face와 Item 카드 face를 재사용해 보여준다. 구매/Boss/Station은 아직 요약 텍스트이며, 미발견/발견/획득/클리어를 분리한 전용 상세 UI는 남아 있다.
- Browser Use QA에서 Title의 `도감` 진입, `기억 카드`, `하이 스테이크`, `Jester`, `Item`, `Boss` 항목 표시를 확인했다.
- 최신 소스 기준 새 run 화면은 `기억 카드 보유`, `기억 카드 필요`, `기억 카드로 해금`으로 표시된다.

## 8. Submission Smoke

Status: Reopened for latest candidate

- [x] `flutter analyze` 통과.
- [x] 핵심 `flutter test` 통과.
- [ ] 최신 변경 후 `flutter build web` 통과.
- [ ] Browser/WebDriver + Compute Use hybrid bot으로 S1~S8 실제 UI clear를 최신 빌드 기준으로 검증한다.
- [ ] full-play bot 로그에 마켓 구매와 아이템 실제 사용 증거를 남긴다.
- [ ] 제출 후보 빌드에서 콘솔 에러나 화면 깨짐이 없는지 확인한다.
- [ ] 최종 빌드 산출물과 실행 경로를 정리한다.

진행 메모:

- `tools/prototype_submission_smoke.sh --skip-pub-get` 통과.
- 로그 경로: `/tmp/rummipoker_submission_smoke/20260507_132745`
- 자동 smoke는 코드 분석, 핵심 테스트, web 빌드 생성까지 확인했다. 실제 화면 조작과 콘솔 확인은 browser/compute QA에서 별도로 닫는다.
- Browser Use는 `tool_search`에서 `mcp__node_repl__.js`가 노출되어 정상 사용 가능했다. Computer Use fallback은 사용하지 않았다.
- 최신 Flutter web-server 기준 Browser Use QA에서 Title/new run/S1 전투 진입/게임오버 보상/런 완료 보상/도감 진입을 확인했다.
- 웹 제출 후보에서는 `WakelockPlus` 호출을 건너뛰어 브라우저의 wake lock 거부가 console error로 남지 않게 했다. Browser Use timestamp-filter console check에서 새 error/warn 0건을 확인했다.
- 최신 소스 기준 `flutter build web` 통과. 제출 후보 산출물은 `build/web`이며, 현재 눈검증용 Flutter web-server는 `http://127.0.0.1:7361`에서 실행 중이다.
- 이전 `127.0.0.1:7360` 서버는 stale 문자열을 보여줄 수 있으므로, 제출 전 확인은 최신 빌드 또는 새로 띄운 서버 기준으로 한다.
- `127.0.0.1:7361` Browser Use full route QA 후 `tab.dev.logs` 기준 error/warn 0건을 확인했다.
- 이후 도감/게임오버/수집 저장 변경이 들어갔으므로 제출 후보 build와 browser QA는 다시 열었다.
- 2026-05-08 기준 공모전 full-play QA는 사람 수동 플레이가 아니라 `docs/planning/competition/COMPUTE_BROWSER_FULL_PLAY_BOT.md`의 Browser/WebDriver + Compute Use hybrid bot 기준으로 닫는다.

## 9. 심미성/재미도 재점검

Status: In progress

- [ ] 게임오버 dialog의 `기억 카드 획득` 카드가 보상처럼 보이는지 확인한다.
- [ ] `다시 도전`, `새 run 준비`, `나가기` 버튼 우선순위가 자연스러운지 확인한다.
- [ ] 도감의 Jester/Item 실물 카드 face가 작거나 답답하지 않은지 확인한다.
- [ ] 도감에서 구매/Boss/Station 기록이 텍스트 요약으로만 남아도 공모전 기준 충분한지 판단한다.
- [ ] 새 run 화면에서 기억 카드/규칙 해금 정보가 다음 런 동기로 읽히는지 확인한다.
- [ ] 마켓 구매/판매/리롤이 심사자가 보기에도 카드 게임 액션처럼 보이는지 확인한다.
- [ ] 정산 sheet가 보상/진행의 쾌감을 충분히 주는지 확인한다.
- [ ] 보스 제약이 어렵게 느껴지되 억울하거나 설명 부족으로 보이지 않는지 확인한다.

진행 메모:

- 이 섹션은 기능 완성 체크가 아니라 제출 전 눈검증/영상 기준 체크다.
- 문제가 보이면 새 시스템을 크게 추가하지 않고 문구, 버튼 위계, spacing, 카드 face 재사용, 화면 전환 안정화 범위에서 해결한다.

## 10. Feature Freeze 기준

Status: In progress

- [x] 새 레벨링/경제/ML 조정은 공모전 이후로 미룬다.
- [x] 대형 저장 포맷 변경은 공모전 이후로 미룬다.
- [x] `run_unlock_state_v1`에 도감 수집 이력을 추가한 소형 변경은 공모전 핵심 흐름 보강으로 적용하고 테스트했다.
- [x] 신규 대형 UI 구조 변경은 공모전 이후로 미룬다.
- [x] 제출 전에는 버그 수정, 문구 정리, QA 안정화만 허용한다.

진행 메모:

- 현재 남은 제출 전 작업은 자연 full end-to-end QA, 최신 빌드 산출물/실행 경로 정리, 문구/시각/재미도 회귀 확인으로 제한한다.
- 밸런스 수치, ML 리포트 갱신, 새 저장 구조, 큰 화면 구조 변경은 제출 후 polishing으로 분리한다.

## Known Risk

- `power none`은 fresh r400 일부 seed에서 58.8~62.0%로 목표 45~55%보다 높다.
- `balanced v9`는 fresh seed 93041에서 59.0%로 목표 60%를 살짝 밑돈다.
- 현재는 장기 밸런스 완료가 아니라 공모전 임시 handoff다.
- 장기 밸런스에서는 multi-seed r400/r800과 ML 리포트 갱신을 다시 수행한다.
- Browser/WebDriver + Compute Use hybrid bot으로 S1~S8 실제 UI clear를 아직 완료하지 않았다.
- 도감은 수집/발견/구매/보상/보스/스테이지 이력을 저장하지만, 아직 항목별 미발견/발견/획득/클리어 상태를 나눈 상세 UI는 없다.
- 기억 카드 보상은 내부 `insight` 계열 값을 유지하면서 `earnedMemoryCardIds` 획득 이력을 함께 남긴다. 실제 보상 아이템/Jester 지급은 아직 없다.
