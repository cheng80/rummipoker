# Active Execution Plan

> 문서 성격: 현재 실행 라우터
> 기준: 문서 진입과 읽는 순서는 `START_HERE.md`를 따른다. 이 문서는 `planning` 단계에서 현재 어떤 트랙을 실행할지 정한다.

이 문서는 닫힌 공모전 제출 이력과 post-contest 실제 Goal 실행을 분리한다.
새 세션은 `START_HERE.md`와 `current_system` 기준 문서를 읽은 뒤, 이 문서에서 현재 활성 트랙과 다음 작업만 확인한다.

## 1. 현재 활성 트랙

| Track | Status | 기준 문서 | 지금 판단 |
|---|---|---|---|
| 공모전 기준 완성 | Closed / off | `docs/planning/competition/COMPETITION_SUBMISSION_CHECKLIST.md` | 2026-05-15 12시경 최종 산출물을 우선 등록했다. 공모전 풀런봇/제출 체크리스트는 더 이상 활성 작업 큐가 아니며, 이후 공모전 문서는 제출 증거와 이력 참고로만 본다. |
| Post-contest 덱 빌딩 확장 | Active | `docs/planning/feature_plans/TILE_MODIFIER_V1_V2_PLAN.md` | 특수 타일 V1은 저장/마켓/손패/보드/런 정보/정산 반영까지 닫았고, V2-A 판본(`silver_edition`, `glow_edition`, `prism_edition`)도 additive 저장/마켓/정산/뱃지 경로를 열었다. 다음은 V2-B 이후가 아니라 fresh 데이터 기반 레벨링 재시작 전에 회귀 검증과 문서 정리 상태를 유지하는 것이다. |
| UI/UX 예정 연출 큐 | Active side track | `docs/planning/feature_plans/ANIMATION_EFFECTS_PLAN.md` | transient presentation state는 runtime save source-of-truth와 분리되어 있고, settlement 큐에서 Jester / Tile modifier / Item 효과 단계가 분리됐다. timing/metric 일부도 공용화했다. 남은 polish는 별도 시각 QA 후보로 두며 밸런스/경제/ML 재검증과 섞지 않는다. |
| 실제 Goal 기준 완성 | Active after stabilization | `docs/planning/goal/OVERALL_GOAL_PROGRESS.md` | 족보 레벨 성장, 덱 추가, 히든 족보 V1, 보스 클리어 덱 타일 보상, 타일 구매 연출/선택 표시 보강, 타이틀 로고/서브타이틀, 전투/마켓 튜토리얼 V1은 반영됐다. 공모전 이후에는 리팩터링, 최적화, 장기 밸런스, meta growth, 자연 full-play QA를 재개한다. |

현재는 공모전 기준 풀런봇 QA 플랜을 제출용 handoff 상태에서 완전히 닫았다. 한 locale 사이클 기준은 fresh 표준 난이도 S1~S8 Boss 클리어, 이어서 같은 locale fresh 도전 난이도 S1~S8 Boss 클리어와 S8 정산/보상/무한 도전 진입 직전 확인까지다. `ko`, `en` cycle은 2026-05-10에 완료했고, S2/S4/S6 Boss 보상 슬롯 해금, Market 해금 연출, 시스템 locale 기본값, debug fixture, web 제출 산물/BGM/메뉴/정산 UI 회귀 수정 뒤 2026-05-10~11 최신 후보에서 `ko` standard→challenge 재확인도 통과했다. 2026-05-15 12시경 최종 산출물을 우선 등록했으므로 `ja`, `zh-CN`, `zh-TW` full-run은 제출 gate가 아니라 post-contest 추가 검증 후보로만 남긴다. S9+ 무한 도전 장기 생존도 별도 확장 검증이다.

## 다음 세션 시작점

1. 완료: `docs/planning/feature_plans/TILE_MODIFIER_V1_V2_PLAN.md` 기준 특수 타일 V1.
   - `Tile` 모델에 `enhancement`, `seal` 저장 필드를 추가했고 modifier 없는 기존 저장 데이터는 정상 복원된다.
   - 포함 경로: `addedDeckTiles`, `tileOffers`, deck pile, board cells, hand, eliminated JSON roundtrip.
   - 마켓/보드/손패/런 정보/정산/확정 preview에 modifier 정보가 표시된다.
2. 완료: 특수 타일 V2-A 판본 1차.
   - `Tile.edition`으로 `silver_edition`, `glow_edition`, `prism_edition`을 additive 저장한다.
   - 마켓 가격 surcharge, 구매/저장/복원, 정산 breakdown, 타일 badge/설명, battle facade preview count를 검증했다.
3. 완료: runtime state와 transient presentation state 1차 분리.
   - 저장 기준은 `session`, `runProgress`, `stageStartSnapshot`으로 유지한다.
   - 선택/overlay/settlement animation 상태는 `GameSessionPresentationState.initial`로 복원 경계에서 초기화한다.
4. 완료: UI/UX 예정 연출 큐 1차.
   - settlement 단계에서 Jester, Tile modifier, Item 효과가 분리되어 발동한다.
   - 일부 HUD/timing 하드코딩 상수는 `game_card_metrics.dart`, `game_presentation_timings.dart`로 이동했다.
5. V1 세부 상태:
   - 완료: Tile lane 특수 후보 생성과 가격 surcharge.
   - 완료: 마켓/보드/손패/런 정보 modifier badge와 설명.
   - 완료: `chip_inlaid`, `score_gilded`, `gold_tile`, `glass_tile`, `blue_seal`, `red_seal` 정산 반영.
   - 완료: glass 파괴와 런 덱 source 제거/복원.
   - 보류: `wild_painted`, `lucky_tile`은 evaluator/RNG 재현 정책이 더 필요해 V1 후속 또는 V2 후보로 둔다.
6. 다음 활성 작업:
   - 완료: 구 ML/시뮬레이션 산출물은 active 판단 근거로 재사용하지 않고, 현재 runtime/catalog/ruleset/bot policy 기준 fresh row 5000건 이상을 먼저 쌓기 시작했다.
   - 2026-05-29 bootstrap: `logs/sim/fresh_runtime_20260529_planner_r200.jsonl` 5,049 rows, summary/economy audit 생성. tracked 요약은 `analysis/leveling/reports/fresh_runtime_data_2026_05_29.md`.
   - 2026-05-29 contest policy fresh data: `contest_policy_v1` chunked run 5,133 rows, 구매 event source/cost 추적, pre-outcome multi-target model scaffold(`clear_rate`, `avg_score_ratio`, `cleared_majority`)까지 생성했다.
   - 다음은 `MODE=grid` fresh run을 5,000+ rows 이상으로 다시 쌓아 market/loadout axis를 넓히고, classifier hit-rate가 높은 후보를 fresh resimulation으로 검증하는 것이다.
   - LLM autoplay는 대량 밸런스 기준이 아니라 전략 샘플러/decision label 보조 축으로만 검토한다. 적용 계약은 `docs/planning/leveling/LLM_AUTOPLAY_LEVELING_PLAN.md`를 따른다.
7. 대기열로 미룬 작업:
   - 구 산출물을 직접 이어 쓰지 않는 새 데이터셋 기반 `shop_slot_market_v9` 구매 이벤트 source candidate 추적.
   - 현재 runtime 기준 fresh row 기반 실제 runtime 후보 구매/사용 가치 probe.
   - fresh 경제/구매 데이터 기준 `trade_ticket`, `ride_the_bus`, 고급 study, `reroll_token` 가격/가치 판단 재개.
   - 장기 경제 gate와 `runtime_station_pool_economy_r400` 재검토.
   - LLM autoplay P0 scaffold: legal action request export, response validation, decision cache/local runner, fallback/decision log 분리.
8. 병렬로 하지 말 것: full-run bot 재개, 장기 r400/r800 sweep, 특수 타일 V2-B/C/D 구현.
   - V2-B/C/D는 fresh 데이터 baseline과 현 UI 회귀 검증이 닫힌 뒤 연다.

## 데이터 재시작 기준

기존 `analysis/leveling` 모델/리포트/메타데이터와 대량 `logs/sim`은 active 판단 경로에서 내린다.

- tracked legacy outputs: `docs/archive/leveling/legacy_ml_outputs_2026_05/`
- ignored legacy generated artifacts: `analysis/leveling/archive/legacy_pre_20260529/`
- ignored legacy simulation logs: `logs/archive/legacy_pre_20260529/sim/`

새 장기 밸런스, 경제, ML 작업은 archive 데이터를 feature table에 바로 섞지 않고, 현재 runtime/catalog/ruleset/bot policy 기준 fresh run부터 다시 쌓는다.

## 2. Post-contest 다음 작업

현재 실행 순서는 아래로 고정한다.

1. 완료: 손패 최대치 4장 이상 UI/효과 버그 수정.
   - 정책: 손패 최대치는 5장이다.
   - 5장 초과 손패 증가 효과는 실패 처리하고 아이템/효과를 소모하지 않는다.
   - 손패 증가와 패널티가 묶인 효과는 손패 증가가 실패하면 패널티만 적용하지 않는다.
   - 검증: `item_effect_runtime_test`, `game_station_read_path_test`, `dart analyze`, `git diff --check`.
2. 완료: 전투 자원 증가 상한/no-op 정책 적용.
   - 정책: 보드 버림 6회, 손패 버림 4회, 보드 이동 5회를 현재 runtime 상한으로 둔다.
   - 상한 도달 시 `보드 버림 최대치입니다.`, `손패 버림 최대치입니다.`, `보드 이동 최대치입니다.`로 실패 처리하고 소모하지 않는다.
   - 일부만 적용 가능한 경우에는 상한까지만 올리고 실제 증가량만 이벤트에 기록한다.
   - 검증: `item_effect_runtime_test`, `dart analyze`.
3. 완료: 보유 슬롯 확장 아이템 정책 정리.
   - 정책: Quick/Passive/Jester 보유 슬롯 확장은 Boss 진행 보상의 전용 축으로 둔다.
   - `spare_pouch`는 S2 Boss Quick Slot 해금과 충돌하므로 카탈로그/번역/테스트 fixture에서 삭제했다.
   - 아이템은 보유 슬롯 수 자체를 늘리지 않고 후보 수/할인/사용 보조/자원 보정 축으로 설계한다.
   - 검증: `item_definition_test`, `item_effect_runtime_test`, `game_session_notifier_test`, `dart analyze`.
4. 완료: Market 후보 슬롯 증가 상한/no-op 정책 적용 및 `shop_lens` 삭제.
   - 정책: Jester/Item 후보 슬롯은 현재 4개를 runtime 상한으로 둔다.
   - `shop_lens`는 유저가 효과를 체감하기 어렵고 source-target-result 연출 없이 후보 수만 바꾸는 효과라 카탈로그/번역/fixture에서 삭제한다.
   - `boss_trophy`는 다음 Market Jester 후보 슬롯이 4개를 넘지 않도록 실제 적용량만 예약하고, 이미 4개이면 `Jester 후보 슬롯 최대치입니다.`로 실패 처리한다.
   - 검증: `item_effect_runtime_test`, `dart analyze`.
5. 진행 중: Jester/Item/Tool/Gear 정책 리스크 검토 리스트를 작은 구현 후보로 분해한다.
   - 완료: `spare_pouch`는 Boss 보유 슬롯 해금과 겹쳐 삭제했다.
   - 완료: `lucky_counter`는 눈에 보이는 피드백이 없는 rarity weight 효과라 카탈로그에서 삭제했다.
   - 완료: `market_compass`는 현재 Market의 보이는 Jester/Item 후보 중 1G 이상 최저가 1개에만 `나침반` 할인 배지를 붙인다. 0G 후보에는 적용하지 않는다.
   - 완료: 전체 Item 55개를 `발동 객체 -> 적용 대상 -> 결과` 기준으로 재검토하는 1차 계약표를 `docs/planning/feature_plans/ITEM_PRESENTATION_CONTRACT_REVIEW.md`에 만들었다. `shop_lens`는 삭제 상태로 두고, 남은 활성 54개는 P0~P3 보강 우선순위로 분류했다.
   - 완료: `ItemPresentationEvent` / `ItemPresentationTarget` transient model 1차와 Market P0 일부 연출을 추가했다. 현재 Market reroll 할인, 구매 할인, `market_compass` 할인은 source -> target -> result toast를 표시하고, 구매 flight의 spent Gold는 실제 Gold 차이 기준으로 보정했다.
   - 다음 세션 프롬프트: `docs/planning/feature_plans/NEXT_SESSION_ITEM_PRESENTATION_PROMPT.md`
   - 완료: Chrome에서 Market P0 1차 연출을 눈검증했다. `market_compass`의 `나침반` 배지, 구매 시 `나침반 -> 기세 -> 구매가 -1G` source-target-result toast, 실제 Gold 18 -> 16 차감, `slot_unlock_market`의 `shop_lens` 없는 슬롯 해금 상태, Tile Shop `칩 N · 3G`, `런 정보`의 `타일 기준 칩` 표기를 확인했다. 기능뿐 아니라 overflow/잘림/겹침/프레임 누수 기준으로 봤고 미통과 항목은 없었다. 기록: `docs/planning/verification/daily_logs/2026-05-16.md`.
   - 완료: `trade_ticket`은 보유 Tool source -> Item 후보 영역 target -> 후보 교체 완료 result toast를 표시한다. 기존 lower feedback도 `Item 후보 교체`로 바꿨고, 테스트 중 발견한 Tool/Gear 사용/판매 action pane overflow를 고쳤다. 검증: `game_shop_screen_trade_ticket_test`, `game_shop_screen_test`, targeted analyze, `git diff --check`.
   - 완료: 조건부 사용 no-op 1차를 테스트 우선으로 닫았다. `slide_wax`는 보드 이동 자원이 없으면 `사용 가능한 보드 이동이 없습니다.`로 실패/미소모, `deck_needle`은 덱 확인 대상이 없으면 선택 overlay를 열지 않고 `덱에 확인할 타일이 없습니다.`로 실패/미소모, next-confirm 소모품은 이미 수동 one-shot confirm modifier가 queued이면 `이미 다음 확정 보너스가 준비되어 있습니다.`로 실패/미소모 처리한다.
   - 완료: `GameView` 전투 아이템 UI에서 `undo_seal` 이동 기록 없음, `emergency_draw` 손패 보유 상태 실패가 각각 명시 notice로 보이고 성공 burst가 뜨지 않는지 위젯 테스트로 고정했다.
   - 진행 원칙: 기존 no-op/조건 표시 작업 흐름은 유지한다. 다만 이제부터 `ITEM_EFFECT_RUNTIME_MATRIX.md`의 runtime 적용 상태와 `ANIMATION_EFFECTS_PLAN.md`의 발동/대상/결과 연출 coverage를 함께 확인한다. `applied`는 런타임 상태 변경 완료만 뜻하며, UX 전달 또는 연출 완료로 보지 않는다.
   - 완료: next-confirm 조건부 rank/color 계열의 1차 preview 표시를 추가했다. 수동 one-shot confirm modifier가 대기 중이면 확정 preview에 `아이템 대기 N`, `아이템 적용 A/N`, `아이템 조건 미충족 0/N`을 표시해 사용 전/확정 전 적용 가능 여부를 읽게 했다.
   - 완료: next-confirm 대기 상태를 Item zone에 `확정 대기 N` badge로 표시한다. 수동 소모품은 사용 즉시 인벤토리에서 사라지므로 원래 Quick slot에 계속 badge를 붙이지 않고, 같은 Item zone 안에서 대기 상태를 유지해 보이게 한다.
   - 완료: next-confirm 확정 순간 보너스 callout을 정리했다. 정산 presentation의 item/jester step에서도 floating settlement burst를 띄우고, item 이름은 `ItemTranslationScope`로 현지화해 `연속 준비 +40 칩`처럼 결과 delta를 확정 순간에 읽게 했다.
   - 완료: `deck_needle` 선택 UX를 보강했다. 덱 확인 dialog에서 후보마다 `후보 N`과 타일 코드를 표시하고, 선택 후보를 짧게 강조한 뒤 `버림 확정` result badge와 notice/toast에 실제 제거된 타일 코드(`R1 제거` 등)를 보여준다.
   - 완료: `emergency_draw` 성공 UX를 보강했다. 손패가 비어 있을 때 사용하면 기존 incoming hand tile 전환과 함께 hand zone에 `드로우 +1` badge를 표시하고, 실패 경로는 기존처럼 notice만 보여 성공 burst를 띄우지 않는다.
   - 완료: `slide_wax` 대기/발동 UX를 보강했다. 사용 후 Item zone에 `이동 보너스 대기` badge를 표시하고, 다음 보드 이동 성공 순간 `슬라이드 왁스 / 이동 보너스 발동` feedback을 보여준다.
   - 가격/가치: `ride_the_bus`, `reroll_token`, `trade_ticket`, `full_house_study`, `four_kind_study`, `straight_flush_study`.
   - 완료: delayed Market 계열 `boss_trophy` 표시 UI를 보강했다. 다음 Market Jester 후보 슬롯 보너스가 적용 중이면 Jester offer lane pager에 `트로피 +N` badge를 표시한다.
   - 정정: 위 2026-05-17 아이템 UX 항목은 대부분 badge/notice/toast/callout 기반의 표시/피드백 1차다. 새 발동 모션, target 이동, stagger, particle까지 완료됐다는 뜻이 아니다.
   - 기존 커밋 `ff93b15`의 animation-first UX 규칙을 다시 적용한다. 보강 기준은 "읽을 수 있음"이 아니라 아이템 source, target/목적지, 결과가 게임적으로 이어지는지다.
   - 완료: `deck_needle`은 선택 후보 flash/fade와 `버림 확정` result badge로 후보 선택이 discard 결과로 이어지는지 고정했다. 큰 discard 이동은 P2 polish 후보로만 남긴다.
   - 완료: `slide_wax`는 보드 이동 보너스 발동 시 이동 도착 칸에 bonus flash를 추가해 Quick slot queued 상태 -> 보드 이동 목적지 -> 결과 연결을 보강했다.
   - 완료: `emergency_draw`는 Quick slot source toast, 기존 hand incoming, `드로우 +1`, deck/hand resource pulse를 함께 검증해 source -> 덱/손패 -> 결과 연결을 고정했다.
   - 완료: next-confirm 16종은 `확정 대기 N` badge pulse, scoring preview item link flash, settlement item burst로 source -> preview -> result 연결을 고정했다.
   - 완료: `market_compass`, `boss_trophy`는 할인 대상 offer pulse와 후보 lane bonus pulse로 source -> Market 후보/할인 결과 연결을 고정했다. `shop_lens`는 원격 최신 변경 기준 삭제 상태로 유지한다.
   - 완료: P2 후보(`board_scrap`, `hand_scrap`, `move_token`, `battle_pouch`, `undo_seal`, Market 직접 사용/성장 아이템)의 source -> target/결과 연결도 1차 Done으로 닫았다. 전투 자원류는 하단 resource/hand capacity pulse, `undo_seal`은 되돌아간 board target flash, Market 직접 사용류는 item use flight/Gold badge/use feedback으로 고정했다.
   - 정정: pulse/glow는 보조 강조로만 사용한다. 추가 연출은 전투 item toast source -> result trail, `slide_wax` queued badge chevron 이동, 비골드 Market item use flight처럼 실제 이동/방향성을 우선한다.
   - 눈검증: 2026-05-17 정적 web build + Playwright fixture smoke로 `deck_needle`, `emergency_draw`, `slide_wax`, next-confirm, direct resource item, Market modifier, gold/non-gold Market item use flight를 확인했다. 산출물 `/tmp/rummipoker_item_motion_eye_check_20260517_152554/`, `/tmp/rummipoker_next_confirm_eye_check_20260517_153152/`, `/tmp/rummipoker_next_confirm_eye_check_more_20260517_153249/`, important console/error/overflow/warn 0건. Computer Use는 도구 서버 오류로 직접 조작하지 못했다.
   - 완료: 가격/가치 이상 후보 1차 audit를 갱신했다. `runtime_market_offer_audit` watchlist를 `ride_the_bus`, `reroll_token`, `trade_ticket`, `full_house_study`, `four_kind_study`, `straight_flush_study`까지 확장했고, r200에서 `reroll_token` 1000회, `trade_ticket` 600회, `full_house_study` 200회, `four_kind_study` 0회, `straight_flush_study` 200회, `ride_the_bus` 77회를 확인했다.
   - 완료: `catalog_audit_v3` sim-only price band를 추가했다. 고급 study 완화 가설을 same-seed r120으로 비교했지만 `catalog_normalized_v1`과 결과가 완전히 동일해, 현재 sim path가 실제 watchlist 카탈로그 구매 이벤트를 검증하지 못한다는 결론이다.
   - 다음 후보: 가격표를 바로 바꾸지 않는다. `shop_slot_market_v9` 구매 이벤트에 source candidate id를 남기거나 실제 runtime 후보 구매/사용 가치 probe를 만든 뒤, `trade_ticket`/`ride_the_bus`/고급 study 가격 판단을 다시 연다.
6. 그 다음: 리팩터링 전에 runtime state와 presentation/overlay/dialog/animation state 분리 계획을 확정한다.
7. 이후: 장기 경제 gate를 다시 연다. 특히 `runtime_station_pool_economy_r400`에서 `shop_slot_market_v9`가 none/control보다 개선되지 않은 문제를 target/boss severity/market 구매력으로 분리해 본다.

## 3. 공모전 기준 상태 기록

2026-05-14 제출 전 상점 회귀 수정도 닫았다. 보유 Jester/Item/Passive 판매 시 명시적 리롤 없이 오퍼 리스트가 바뀌지 않게 했고, Jester 오퍼 구매 후 남은 오퍼 가격이 0G로 튀던 stale slot index 경로를 막았다. 첫 무료 Jester 리롤은 다음 Market에서 다시 복원되지 않도록 저장/복원 상태까지 보강했으며, 구매 할인은 원가/할인가/`할인` 배지로 UI에 드러난다. 검증은 `rummi_market_facade_test`, `item_definition_test`, `item_effect_runtime_test`, `game_session_notifier_test`, `game_shop_discount_badge_test`, `game_shop_sell_offer_stability_test`와 `market_discount_visual_bot` 상점 시각 매트릭스로 완료했다. 시각 매트릭스는 7개 fresh Chrome/Flutter drive 시나리오로 할인 Jester 구매/판매, 할인 Item offer 표시, Passive 판매 후 offer 유지, 리롤 할인/피드백, 비할인 Jester/Item 가격 표시, 슬롯 해금 Market 상태를 확인한다. 최신 로그는 `/tmp/rummipoker_market_discount_visual_bot/matrix_full_20260514_060908/10_market_discount_visual_bot.log`이며 `MARKET_DISCOUNT_VISUAL_BOT_PASS` 7건과 `All tests passed!` 7건을 기록했다. 이 수정은 full-run gate 재개 근거가 아니라 제출 전 발견된 상점 회귀의 로직/위젯/시각 회귀 방지다.

2026-05-14 제출 전 용어 UX 보강도 닫았다. 유저 노출 `mult_bonus` 문구는 내부 `+N Mult`가 아니라 실제 공식 `1 + N / 20`에 맞춰 `점수 +N*5%`로 표시한다. `xmult_bonus`는 실제 곱셈이므로 `점수 xN`으로 유지한다. 한국어 `Chips`는 게임 용어 `칩`으로 통일하고, 런 정보 다이얼로그의 책 아이콘에서 `게임 용어` 설명을 열어 `칩`, `점수 +%`, `점수 xN`, `골드` 차이를 확인하게 했다. 검증은 `game_run_info_dialog_test`, `jester_translation_test`, `item_definition_test`, `game_shop_jester_runtime_value_test`, `game_shop_screen_test`, `game_station_read_path_test`, JSON validation, `git diff --check`로 완료했다. 남은 리스크는 다국어 카드/툴팁 문구가 길어진 화면의 실제 기기 눈검증이다.

## 4. 공모전 기준 닫힌 작업

상세 체크리스트는 `docs/planning/competition/COMPETITION_SUBMISSION_CHECKLIST.md`를 따른다.
아래 목록은 현재 실행 순서가 아니라 닫힌 제출 이력이다.

1. 완료: `contest_full_run_bot` `ko` locale 표준 난이도 fresh S1~S8 Boss full-run 통과.
2. 완료: 같은 `ko` cycle 내부의 도전 난이도 fresh S1부터 S8 Boss와 S8 정산/보상/무한 도전 진입 직전 확인 통과.
3. 완료: `contest_full_run_bot` `en` locale 표준 난이도 fresh S1~S8 Boss full-run 통과.
4. 완료: 같은 `en` cycle 내부의 도전 난이도 fresh S1부터 S8 Boss와 S8 정산/보상/무한 도전 진입 직전 확인 통과.
5. 완료: 잠긴 슬롯 해금 룰을 S2/S4/S6 Boss 보상으로 연결하고, Market 진입 시 해금 연출을 보여준 뒤 전투에는 해금된 슬롯 상태로 들어가게 했다.
6. 완료: 앱 기본 언어는 OS/브라우저 시스템 locale을 따르도록 `startLocale` 강제를 제거했고, `slot_unlock_market` debug fixture를 추가했다.
7. 완료: `/game?fixture=slot_unlock_market`에서 자동 튜토리얼 없이 해금 배너/슬롯 pulse를 눈검증했다. 자물쇠 확대/fade-out과 pulse가 1회 보이는 기준으로 조정했고, 반복 재생은 실제 플레이와 다르므로 넣지 않는다.
8. 완료: web 제출 산물에 icon/splash/OG image를 반영하고, 릴리즈 진입 메뉴에서 debug/special 메뉴가 보이지 않게 정리했다. 웹 BGM은 첫 터치/버튼 tap에서 unlock되고, 스크롤 중 같은 BGM을 stop/play 반복하지 않게 보정했다. 2026-05-14 추가로 focus-out 복귀 시 lifecycle pause만 recovery pending으로 표시하고, 첫 제스처에서는 `resume()`을 먼저 시도하며 실패한 경우에만 다음 제스처에서 `stop()`/`play()` fallback을 허용하도록 `SoundManager`에 제한했다. 웹뷰별 오디오 정책 때문에 BGM 위치 유지가 완전하지 않은 경우는 제출 blocker가 아니라 known limitation으로 둔다.
9. 완료: 정산 sheet 텍스트의 노란 밑줄 회귀를 `TextDecoration` 상속 차단으로 수정했고, `showGeneralDialog` 정산 overlay가 desktop/web에서 PhoneFrame 밖 전체 폭으로 새는 회귀를 `PhoneFrame` 제약과 landscape widget test로 막았다.
10. 완료: 최신 후보에서 `ko` standard→challenge 재확인을 통과했으므로 공모전 제출용 풀런봇 플랜은 닫는다. `ja`, `zh-CN`, `zh-TW`는 문제가 발견될 때 또는 공모전 이후 추가 검증으로 둔다.
11. 향후 문제 발생 또는 공모전 이후 locale cycle을 추가 검증할 때는 standard 실행 전 저장 세션/SharedPreferences를 지워 첫 전투/첫 Market 튜토리얼이 표시되는 조건으로 시작한다. 같은 locale의 challenge 실행은 새 도전 run으로 시작하되 같은 cycle 내부 진행이므로 battle/market tutorial seen 상태는 유지한다.
   - bot은 튜토리얼 overlay가 보이면 전투/마켓 액션보다 `Next/Done` 완료를 먼저 처리하고, fresh locale gate에서는 전투/마켓 튜토리얼 완료 로그가 없으면 pass로 인정하지 않는다.
   - fresh locale standard 실행은 WebDriver Chrome profile의 cookie/localStorage/sessionStorage도 초기화한다. 같은 locale challenge 실행은 active run/save를 새로 시작하되 tutorial seen flag는 유지하거나 bot 옵션으로 다시 세팅한다.
12. full-run 도중 실패하면 game over/retry/checkpoint 로그를 먼저 확인한다.
13. 실패 원인이 policy 문제면 문서만 바꾸지 말고 policy code/test를 먼저 고친 뒤 재실행한다.
14. game over가 아니어도 UI overflow, 튜토리얼 target/문구 문제, Jester/Item/자원 카드 제목·설명 잘림, 다국어 텍스트 넘침이 발견되면 제출 QA 결함으로 수정하고 해당 locale gate를 다시 실행한다.
15. full-run 도중 세션이 종료되면 마지막 로그/출력 디렉터리/checkpoint를 먼저 확인하고, debug fixture 없이 이어서 진행한다.

최근 `contest_full_run_bot` 기준선:

- 2026-05-10 `ko` fresh 표준 locale gate 로그: `/tmp/rummipoker_contest_full_run_bot/standard_ko_20260510_104511/10_contest_full_run_bot.log`
- 출력 디렉터리: `/tmp/rummipoker_contest_full_run_bot/standard_ko_20260510_104511`
- 실행 조건: `--seed 91460 --difficulty standard --locale ko --web-port 7363 --browser-profile-dir /tmp/rummipoker_contest_full_run_bot/standard_ko_profile_20260510_104511 --output-dir /tmp/rummipoker_contest_full_run_bot/standard_ko_20260510_104511 --skip-pub-get`
- 결과: `CONTEST_FULL_RUN_BOT_PASS`, `All tests passed!`, S8 boss run complete
- locale/fresh 조건: `locale=ko`, `resolvedLocale=ko`, `freshStorage=true`
- 튜토리얼: 첫 battle tutorial completed, 첫 market tutorial completed
- S8 boss 정산: `951/3 -> 778/2 -> 246/1`, 목표 `1739` 통과
- game over/retry/Flutter semantics warning/UI overflow/error/warn: 없음
- 보스 클리어 덱 타일 보상: S2 `deck=53`부터 S8 `deck=59`까지 증가 확인
- 종료 후 WebDriver Chrome, Chrome Helper, ChromeDriver, Flutter web 서버 잔류 프로세스 없음

- 2026-05-10 `ko` fresh 도전 locale gate 로그: `/tmp/rummipoker_contest_full_run_bot/challenge_ko_20260510_115046/10_contest_full_run_bot.log`
- 출력 디렉터리: `/tmp/rummipoker_contest_full_run_bot/challenge_ko_20260510_115046`
- 실행 조건: `--seed 91460 --difficulty challenge --locale ko --web-port 7364 --browser-profile-dir /tmp/rummipoker_contest_full_run_bot/challenge_ko_profile_20260510_115046 --output-dir /tmp/rummipoker_contest_full_run_bot/challenge_ko_20260510_115046 --tutorials-already-seen --skip-pub-get`
- 결과: `CONTEST_FULL_RUN_BOT_PASS`, `All tests passed!`, S8 boss run complete
- locale/fresh 조건: `locale=ko`, `resolvedLocale=ko`, `freshStorage=true`, `difficulty=challenge`
- 튜토리얼: 같은 locale cycle 내부 challenge 실행이므로 `--tutorials-already-seen`으로 battle/market tutorial seen 상태를 유지했다. fresh 튜토리얼 완료 로그는 이 실행에서 요구하지 않는다.
- S8 small 정산: `1622/2 -> 230/1`, 목표 `1729` 통과
- S8 big 정산: `1009/2 -> 1032/2 -> 368/1`, 목표 `2086` 통과
- S8 boss 정산: `1010/3 -> 869/2 -> 312/1`, 목표 `2087` 통과
- S8 시작 덱: `deck=59`
- game over/retry/Flutter semantics warning/UI overflow/error/warn: 없음
- 종료 후 WebDriver Chrome, Chrome Helper, ChromeDriver, Flutter web 서버 잔류 프로세스 없음

- 2026-05-10 `en` fresh 표준 locale gate 로그: `/tmp/rummipoker_contest_full_run_bot/standard_en_20260510_140623/10_contest_full_run_bot.log`
- 출력 디렉터리: `/tmp/rummipoker_contest_full_run_bot/standard_en_20260510_140623`
- 실행 조건: `--seed 91460 --difficulty standard --locale en --web-port 7365 --browser-profile-dir /tmp/rummipoker_contest_full_run_bot/standard_en_profile_20260510_140623 --output-dir /tmp/rummipoker_contest_full_run_bot/standard_en_20260510_140623 --skip-pub-get`
- 결과: `CONTEST_FULL_RUN_BOT_PASS`, `All tests passed!`, S8 boss run complete
- locale/fresh 조건: `locale=en`, `resolvedLocale=en`, `freshStorage=true`
- 튜토리얼: 첫 battle tutorial completed, 첫 market tutorial completed
- S8 small 정산: `1539/2`, 목표 `1441` 통과
- S8 big 정산: `902/2 -> 925/2`, 목표 `1738` 통과
- S8 boss 정산: `951/3 -> 778/2 -> 246/1`, 목표 `1739` 통과
- S8 시작 덱: `deck=59`
- game over/retry/Flutter semantics warning/UI overflow/error/warn: 없음
- 종료 후 WebDriver Chrome, Chrome Helper, ChromeDriver, Flutter web 서버 잔류 프로세스 없음

- 2026-05-10 `en` fresh 도전 locale gate 로그: `/tmp/rummipoker_contest_full_run_bot/challenge_en_20260510_145813/10_contest_full_run_bot.log`
- 출력 디렉터리: `/tmp/rummipoker_contest_full_run_bot/challenge_en_20260510_145813`
- 실행 조건: `--seed 91460 --difficulty challenge --locale en --web-port 7366 --browser-profile-dir /tmp/rummipoker_contest_full_run_bot/challenge_en_profile_20260510_145813 --output-dir /tmp/rummipoker_contest_full_run_bot/challenge_en_20260510_145813 --tutorials-already-seen --skip-pub-get`
- 결과: `CONTEST_FULL_RUN_BOT_PASS`, `All tests passed!`, S8 boss run complete
- locale/fresh 조건: `locale=en`, `resolvedLocale=en`, `freshStorage=true`, `difficulty=challenge`
- 튜토리얼: 같은 locale cycle 내부 challenge 실행이므로 `--tutorials-already-seen`으로 battle/market tutorial seen 상태를 유지했다. fresh 튜토리얼 완료 로그는 이 실행에서 요구하지 않는다.
- S8 small 정산: `1622/2 -> 230/1`, 목표 `1729` 통과
- S8 big 정산: `1009/2 -> 1032/2 -> 368/1`, 목표 `2086` 통과
- S8 boss 정산: `1010/3 -> 869/2 -> 312/1`, 목표 `2087` 통과
- S8 시작 덱: `deck=59`
- game over/retry/Flutter semantics warning/UI overflow/error/warn: 없음
- 종료 후 WebDriver Chrome, Chrome Helper, ChromeDriver, Flutter web 서버 잔류 프로세스 없음

- 2026-05-10~11 최신 후보 `ko` 재확인 표준 로그: `/tmp/rummipoker_contest_full_run_bot/standard_ko_recheck_20260510_233626/10_contest_full_run_bot.log`
- 결과: `CONTEST_FULL_RUN_BOT_PASS`, `All tests passed!`, S8 boss run complete
- grep 기준 game over/retry/Flutter semantics warning/UI overflow/error/warn: 없음
- 종료 후 WebDriver Chrome, Chrome Helper, ChromeDriver, Flutter web 서버 잔류 프로세스 없음

- 2026-05-10~11 최신 후보 `ko` 재확인 도전 로그: `/tmp/rummipoker_contest_full_run_bot/challenge_ko_recheck_20260511_005027/10_contest_full_run_bot.log`
- 결과: `CONTEST_FULL_RUN_BOT_PASS`, `All tests passed!`, S8 boss run complete
- locale/fresh 조건: `locale=ko`, `resolvedLocale=ko`, `freshStorage=true`, `difficulty=challenge`
- S8 boss 목표 `2087` 통과, S8 시작 덱 `deck=59`
- grep 기준 game over/retry/Flutter semantics warning/UI overflow/error/warn: 없음
- 종료 후 WebDriver Chrome, Chrome Helper, ChromeDriver, Flutter web 서버 잔류 프로세스 없음

- 최신 fresh 표준 실행 로그: `/tmp/rummipoker_contest_full_run_bot/fresh_after_reward_tile_rules_20260509_201727/10_contest_full_run_bot.log`
- 실행 조건: `--seed 91460 --difficulty standard --web-port 7362 --skip-pub-get`
- 결과: `CONTEST_FULL_RUN_BOT_PASS`, `All tests passed!`, S8 boss run complete
- S8 boss 정산: `870/3 -> 728/2 -> 312/1`, 목표 `1739` 통과
- game over/retry: 없음
- 보스 클리어 덱 타일 보상: S2 `deck=53`부터 S8 `deck=59`까지 증가 확인
- 당시 남은 문제: `Semantic node ... scopesRoute and namesRoute ... missing the label` Flutter semantics 경고가 반복 출력됐다. 2026-05-10 보정 후 최신 build smoke에서는 재현되지 않았다.

최근 2026-05-10 검증:

- `flutter analyze` 통과
- 핵심 `flutter test` 묶음 통과
- `flutter build web` 통과
- Browser/CDP smoke 통과: `/`, `/new-run`, `/archive`, `/game?fixture=game_over_insight_ready&debug_show_game_over_on_load=1`, `/game?fixture=final_boss_cash_out_ready&debug_complete_run_on_load=1` 모두 앱 warn/error/exception 0건
- Flutter semantics route label 경고는 dialog/bottom sheet route label 보정 뒤 최신 build smoke에서 재현되지 않음
- Headless Chrome의 `Falling back to CPU-only rendering`은 WebGL 없는 headless 환경 경고라 앱 경고로 집계하지 않음
- `contest_full_run_bot` market policy는 `*_study` 같은 직접 족보 성장 아이템과 Tool/Gear lane 구매 후보를 평가하도록 code/test 동기화 완료
- S8 boss 이후 `무한 도전 진입` CTA를 표시하고, S9+는 Scout 1배, Clash 1.5배, Boss 2배 target 비율에 station 상승률을 적용한다. Station Select, 전투 HUD, 정산 라벨은 `무한 도전` 색상과 경고 톤으로 표시한다.
- 타이틀 로고 이미지와 서브타이틀 `타일로 만드는 포커 런` 적용 완료
- `docs/submission_kit/` 제출 문서 세트 정리 완료. 이번 웹 제출 기준에서는 문서화로 닫고, Android/iOS 실제 release artifact 생성은 해당 플랫폼 제출 시 별도 gate로 둔다.
- 전투/마켓 튜토리얼 V1은 `tutorial_coach_mark`로 구현. `flutter analyze`, 핵심 widget test, `flutter build web` 통과. 리사이즈 후 focus 위치/크기 눈검증도 완료했다.
- 2026-05-10 추가 UI/Web 회귀 수정: icon/splash/OG image를 최신 asset으로 반영, 릴리즈 홈 메뉴를 도감 중심으로 정리, 웹 BGM unlock과 스크롤 중 묵음 회귀 수정, 정산 sheet의 `TextDecoration` 상속 밑줄과 `showGeneralDialog` PhoneFrame 폭 회귀 수정. 검증: `flutter analyze`, `flutter test test/views/game/widgets/game_cashout_widgets_test.dart`, `flutter test test/views/game/game_view_test.dart`, `flutter build web --release --base-href "/rummipoker/"`.
- 2026-05-14 웹 focus-out BGM 후속 완화: `lib/resources/sound_manager.dart`에서 focus-out recovery pending, resume-first, duplicate pointer replay guard, fallback-on-next-gesture 정책을 적용했다. 검증: `flutter test test/resources/sound_manager_test.dart`, `flutter test test/views/game/game_view_test.dart`, `flutter analyze lib/app.dart lib/resources/sound_manager.dart test/resources/sound_manager_test.dart`, `flutter build web`, `git diff --check`. 실제 웹뷰에서는 BGM 위치 유지가 완전하지 않을 수 있어 known limitation으로 남긴다.
- 2026-05-14 용어 UX 보강: Jester/Item의 `mult_bonus` 노출 문구를 `점수 +%`로 환산하고 `xmult_bonus`는 `점수 xN`으로 유지했다. 한국어 Chips는 `칩`으로 통일하며, 런 정보에서 `게임 용어` 다이얼로그를 열어 칩/점수 보정/골드 차이를 설명한다. 검증: `flutter test test/views/game/widgets/game_run_info_dialog_test.dart test/logic/jester_translation_test.dart test/logic/item_definition_test.dart test/views/game/widgets/game_shop_jester_runtime_value_test.dart test/views/game/widgets/game_shop_screen_test.dart test/views/game/widgets/game_station_read_path_test.dart`.

## 5. 공모전 Done Evidence

공모전 트랙은 기능 존재만으로 닫지 않는다.
아래 증거가 있어야 제출 후보로 본다.

- `flutter analyze` 통과
- 핵심 `flutter test` 통과
- 최신 `flutter build web` 통과
- Browser/WebDriver full-play QA에서 최신 빌드 기준 console error/warn 0건
- Browser/WebDriver + Compute Use hybrid bot으로 debug fixture 없이 `ko`, `en` 표준 S1~S8 Boss clear와 도전 S1~S8 Boss clear 확인. 최신 후보에서는 `ko` standard→challenge 재확인까지 통과했으므로 제출용 full-run bot 플랜은 닫는다. `ja`, `zh-CN`, `zh-TW`는 문제 발견 시 또는 공모전 이후 추가 검증으로 둔다.
- full-play 중 마켓 구매와 아이템 실제 사용 증거 확인
- 게임오버/런 완료 보상, 도감, 새 run 복귀가 심사자에게 설명 없이 읽힌다는 눈검증
- 전투/마켓 튜토리얼이 첫 진입/다시 보기/포커스 아웃/옵션 겹침/창 크기 변경에서 깨지지 않는다는 눈검증. full-run locale gate에서는 각 실행 전 세션을 지워 첫 전투/첫 Market 튜토리얼도 함께 확인한다.

## 6. 지금 시작하지 않는 작업

아래 항목은 실제 Goal 기준 완성 트랙으로 넘긴다.

- 장기 multi-seed r400/r800 밸런스 확정
- ML 리포트 갱신과 NotebookLM용 재가공
- production ML 또는 runtime 자동 밸런싱
- 신규 대형 UI 구조 변경
- 전체 카탈로그 가격 2차 재산정
- 반복 플레이용 해금 tree와 run modifier 깊이 확장

예외적으로 지금 시작하는 작업:

- 족보 완성 시 족보 자체가 성장하는 최소 런타임 규칙: 반영 완료
- 그 규칙에 필요한 저장/복원/정산 테스트: 반영 완료
- 게임 중/게임 밖에서 언제든 족보 성장 상태를 확인하는 `런 정보` 화면 또는 동등한 UI: 반영 완료
- Planet-like 직접 족보 성장 아이템군과 초과 클리어 대표 족보 성장 보너스: 반영 완료
- `handGrowthStates(level/progress/requiredProgress)` 분리: 반영 완료. `playedHandCounts`는 완성 횟수/Jester 통계용으로 유지하고 점수 성장 source를 분리했다.
- 타이틀의 `런 정보` 직접 진입점과 게임오버 런 요약/랜덤 도발 문구: 반영 완료. 정산 progress bar는 이번 범위에서 제외한다.
- 타이틀 로고/서브타이틀, submission kit 문서화, 전투/마켓 튜토리얼 V1: 반영 완료. 튜토리얼 리사이즈 눈검증도 완료했다.
- 새 run까지 이어지는 영구 계승은 이번 1차 범위에서 제외하고 별도 검토로 남긴다.
- 공모전 풀런봇이 성장한 족보를 평가하도록 하는 bot 정책 동기화

## 7. 문서 교통정리

| 필요 | 읽을 문서 |
|---|---|
| 전체 문서 흐름과 읽는 순서 | `START_HERE.md` |
| docs 폴더 분류 규칙 | `docs/00_docs_README.md` |
| 현재 코드 사실과 보호 규칙 | `docs/current_system/*` |
| 현재 실행 트랙 선택 | `docs/planning/ACTIVE_EXECUTION_PLAN.md` |
| 공모전 제출 이력 참고 | `docs/planning/competition/COMPETITION_SUBMISSION_CHECKLIST.md` |
| 과거 공모전 제출 handoff | `docs/planning/competition/NEXT_SESSION_SUBMISSION_HANDOFF_PROMPT.md` |
| 과거 공모전 full-play bot 제작 기준 | `docs/planning/competition/COMPUTE_BROWSER_FULL_PLAY_BOT.md` |
| 실제 Goal 전체 진도 | `docs/planning/goal/OVERALL_GOAL_PROGRESS.md` |
| 장기 레벨링/경제 적용 상태 | `docs/planning/leveling/*` |
| 과거 V4/migration 순서 lock | `docs/archive/planning_legacy_2026_05/*` |

`docs/archive/planning_legacy_2026_05/*`는 현재 실행 판단 기준이 아니다.
