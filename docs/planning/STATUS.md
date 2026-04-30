# V4 Current Status

> GCSE role: `Execution`
> Source of truth: 최신 진행 상태, 다음 작업 판단.

이 문서는 최신 상태만 유지한다. 이전 상세 체크리스트는 `docs/archive/legacy/V4_STATUS_HISTORY_2026-04-22.md`에서 검색하고, 검증/산출물 이력은 `docs/planning/verification/daily_logs/YYYY-MM-DD.md` 날짜별 파일에서 검색한다.

## 1. Status Summary

| 기준 | 현재 상태 |
|---|---|
| Migration readiness | 거의 완료. 코어 보호, facade/read model, ruleset/save adapter, smoke 절차가 갖춰졌다. |
| Current playable prototype | 플레이 가능. title/new-run/blind/battle/settlement/market/next loop가 연결됐다. |
| V4 target product | 부분 구현. Item v1 데이터/loader/market read path/buy command/inventory save/battle item zone 일부가 연결됐다. |
| Docs organization | 목적형 폴더 분류와 문서 내부 의미 분리 완료. archive는 이력 검색용 참고 자료로 유지한다. |

현재 한 줄 결론:

> 프로토타입을 V4 구조로 흡수하기 위한 기반 공사는 거의 끝났고, Balatro-style scoring feedback P0, Item effect runtime v1 hook, full loop fixture smoke, Market -> Blind Select transition affordance, market readability polish는 1차 구현/검증됐다. 다음 구현 초점은 Settlement -> Market affordance, station/map 범위 결정, market offer count/rarity roll planning이다.

## 2. Latest Implementation State

- 코어 전투/save/restart는 regression test로 보호된다.
- `RummiStationRuntimeFacade`, `RummiMarketRuntimeFacade`, `RummiActiveRunSaveFacade`, `RummiBattleRuntimeFacade` 기반 read path가 1차 정리됐다.
- `small -> big -> boss -> market -> next station blind select` 루프가 연결됐다.
- Item은 `data/common/items_common_v1.json` 기준 49개 v1 후보 데이터와 한국어 번역 49개가 맞춰져 있다.
- `ItemDefinition` / `ItemCatalog` loader, market item offer read model, owned item inventory save/restore, item purchase command가 연결됐다.
- owned item/Jester는 저장 엔트리와 catalog/runtime state를 묶는 `OwnedItemInstance` / `OwnedJesterInstance` read layer를 통해 battle/market facade에 전달된다.
- battle item zone은 quick slot/passive rack item을 read model로 표시한다.
- `ItemEffectRuntime`은 현재 적용 완료와 pending hook을 `docs/planning/ITEM_EFFECT_RUNTIME_MATRIX.md`에서 관리한다.
- Group 5 inventory/sell hook 적용 완료: `spare_pouch` quick slot capacity와 `jester_hook` Jester 판매가 보너스가 구매/판매/read facade에 반영된다.
- Group 6 expiry guard hook 적용 완료: `safety_net`은 스테이션당 첫 전투 종료 위기에서 보드 버림 또는 구조 드로우를 제공하고 해당 사용 상태를 save/restore한다.
- Group 7 boss/next market offer hook 적용 완료: `boss_trophy`는 boss clear 후 다음 market의 Jester offer +1 delayed modifier를 저장하고, 해당 market의 reroll 동안 유지한 뒤 다음 market에서는 해제된다.
- Market use 단건 hook 적용 완료: `trade_ticket`은 market의 item offer 목록만 다음 구간으로 회전시키고 해당 offset을 save/restore한다.
- Group 8 board move follow-up hook 적용 완료: `slide_wax`는 다음 성공한 보드 이동에 slide bonus trigger marker를 저장/소비하고, save/restore 및 undo 복원 경계를 갖는다.
- Jester score effect는 `JesterEffectRuntime` 경유로 정리되어 animation/event 경계를 갖는다.
- 2026-04-30 huashu-design/Balatro 기준 UI 리뷰 결과, Jester/Item은 접는 인벤토리가 아니라 항상 보이는 scoring engine으로 유지한다. 확정 전 preview, Item slot active scoring effect, board/rank/overlap/Jester/Item/final score 순차 presentation은 1차 구현됐다. 실행 계획과 남은 smoke 기준은 `docs/planning/feature_plans/BALATRO_STYLE_SCORING_FEEDBACK_PLAN.md`를 따른다.
- Market build readability polish 1차 적용 완료: 선택 offer 상세 패널의 조건/효과 synergy tag, Jester offer 외부 selection frame, 구매 불가 reason 표시가 연결됐다. Offer 카드 자체는 슬롯 타입/가격/선택 상태만 담당한다.
- Home/New Run/Blind Select 시작 flow는 제품용 정보량으로 정리됐다. Home은 짧은 continue/new-run entry만 보여 주고, New Run은 Random/Seed entry 중심, Blind Select는 `Small/Big/Boss` 3개 card 비교와 명시적 play button 시작 액션을 사용한다.
- 문서 기준은 `START_HERE.md`와 `docs/00_docs_README.md`의 목적형 폴더 체계를 따른다.

## 3. Current Verification Baseline

최근 문서 정리 및 정합성 검증 기준:

- `flutter analyze`: 통과
- 2026-04-30 scoring feedback P0 구현 후 targeted tests 통과:
  - `flutter test test/views/game/widgets/game_station_read_path_test.dart test/views/game/game_view_test.dart test/providers/game_session_notifier_test.dart`
  - `flutter test test/views/game/game_view_test.dart test/providers/game_session_notifier_test.dart test/services/active_run_save_service_test.dart`
  - `flutter test test/views/game/widgets/game_station_read_path_test.dart test/views/game/game_view_test.dart test/providers/game_session_notifier_test.dart test/services/active_run_save_service_test.dart test/logic/item_effect_runtime_test.dart test/logic/jester_effect_runtime_test.dart`
- `flutter test`: 통과, 224 tests passed
- Markdown absolute link check: 통과
- `git diff --check`: 통과
- item catalog: 49 items / 49 ko translations, runtime applied 49 / pendingHook 0
- phase5 jester catalog: 38 jesters / 61 ko translations, phase5 기준 누락 없음

의미 있는 앱 실구동 검증이 필요한 경우 아래 스크립트를 먼저 사용한다.

- `tools/ios_sim_smoke.sh`
- `tools/web_build_smoke.sh`

검증/산출물 이력은 `docs/planning/verification/daily_logs/`의 날짜별 파일에 남긴다.

최근 iOS smoke:

- 2026-04-25: default launch, auto cash-out loop to Blind Select, market resume, cash-out sheet route 확인.
- 2026-04-25 추가: `settlement_item_bonus` fixture로 `coin_funnel` / `hand_funnel` item bonus row까지 iOS 화면 확인.
- 2026-04-25 추가: `inventory_sell_hook_shop` fixture에서 `jester_hook` 판매가 `+3` 표시, `inventory_quick_slot_battle` fixture에서 `spare_pouch` quick slot 3칸 표시 확인.
- 2026-04-25 추가: `safety_net_expiry_guard` fixture에서 Safety Net 보유와 보드가 꽉 찬 종료 위기 상태 확인. 구조 feedback은 provider test로 확인하고, snackbar는 필요 시 수동 eye-check 대상이다.
- 2026-04-26 추가: `inventory_quick_slot_battle` fixture에서 Q1-Q3/P1-P2 분리, Q/P 잠금 표시, item name 2줄 표시 확인. `inventory_sell_hook_shop` fixture에서 Jester 5th 잠금과 Item Slot Q3/P2 잠금 표시 확인.
- 2026-04-27 추가: market/battle slot tabs 정리 후 default launch, `inventory_sell_hook_shop`, `inventory_quick_slot_battle` iOS smoke 통과. Battle HUD blind label, Jester/item shared card sizing, rarity bars, item card face color, selected slot frame, and centered item count badge follow-up까지 반영. 산출물은 `docs/planning/verification/daily_logs/2026-04-27.md` 참고.
- 2026-04-28 추가: Home/New Run/Blind Select 시작 화면 정보량 축소 후 default launch, `/new-run`, `/blind-select?seed=12345&difficulty=standard` iOS smoke 통과. Blind Select는 3개 card가 한 화면에 들어오고, 시작 액션은 card 전체 tap이 아닌 play button으로 분리됐다. 산출물은 `docs/planning/verification/daily_logs/2026-04-28.md` 참고.
- 2026-04-30 추가: Balatro-style scoring feedback 리뷰용 iOS smoke 통과. `inventory_quick_slot_battle`, `stage2_market_resume`, `stage2_scoring_snapshot&auto_cashout_loop=1&auto_enter_market=1&auto_advance_market=1` route를 iPhone 17에서 확인했다. 산출물은 `docs/planning/verification/daily_logs/2026-04-30.md` 참고.
- 2026-04-30 추가: scoring feedback P0 구현 후 required iOS smoke 재실행 통과. `inventory_quick_slot_battle`, `stage2_market_resume`, `stage2_scoring_snapshot&auto_cashout_loop=1&auto_enter_market=1&auto_advance_market=1` route를 iPhone 17에서 확인했다. 산출물은 `docs/planning/verification/daily_logs/2026-04-30.md` 참고.
- 2026-04-30 추가: `slide_wax` runtime hook, full loop/save-restore boundary recheck, Market -> Blind Select transition affordance 적용 후 targeted tests와 iOS auto loop smoke가 통과했다. 산출물은 `docs/planning/verification/daily_logs/2026-04-30.md` 참고.
- 확인 필요: title launch에서 iOS in-app review prompt가 화면을 가림. item bonus row leading label `I`는 추후 product/design 판단 가능.

## 4. Recommended Reading

새 작업 세션은 아래 순서를 따른다.

1. `START_HERE.md`
2. `docs/00_docs_README.md`
3. `docs/current_system/CURRENT_SYSTEM_OVERVIEW.md`
4. `docs/current_system/CURRENT_CODE_MAP.md`
5. `docs/current_system/CURRENT_TO_V4_GAP.md`
6. `docs/planning/STATUS.md`
7. `docs/planning/IMPLEMENTATION_PLAN.md`
8. `docs/planning/MIGRATION_ROADMAP.md`
9. `docs/planning/ITEM_EFFECT_RUNTIME_MATRIX.md`

필요할 때만 추가로 본다.

- `docs/planning/feature_plans/BOARD_MOVE_HAND_SIZE_ITEM_JESTER_PLAN.md`
- `docs/planning/feature_plans/BALATRO_STYLE_SCORING_FEEDBACK_PLAN.md`
- `docs/planning/verification/TEST_QA_ACCEPTANCE.md`
- `docs/planning/OPEN_DECISIONS.md`

## 5. Next Work

### Station Full-Loop Readiness

현재 판단:

- 기술 루프는 연결됨: `Battle -> Settlement/Cash-out -> Market -> Next Station/Blind Select -> Battle`.
- 이 루프는 iOS smoke에서 여러 차례 통과했고, current playable prototype 기준으로는 한 바퀴 진행 가능하다.
- 제품 UX 기준의 Station 한 바퀴는 아직 미완성이다. 현재는 stage/blind 기반 루프를 Station 용어와 UI로 읽게 만든 상태이며, Station Map/Preview/Modifier 구조는 별도 단계다.

남은 항목을 성격별로 분리한다.

| 범위 | 남은 항목 | 상태 |
|---|---|---|
| 기능 안정화 | Item effect runtime v1 hook | 49개 적용 완료 / pendingHook 0개 |
| 루프 검증 | full loop smoke, market resume, save/restart 경계 확인 | fixture smoke 및 targeted regression 통과 / non-fixture background continue는 optional eye-check |
| 전환 UX | Market -> Next Station -> Blind Select transition affordance | 1차 적용 / Settlement -> Market은 후속 |
| Station 구조 | Station Map, Station Preview, Station Definition/Modifier | 아직 미구현, 별도 phase |
| Market 생성 규칙 | offer 갯수 증설, Balatro식 rarity 기반 shop roll | 후순위 적용 계획에 추가 |
| Pacing | target score curve, small/big/boss 보상/압박, unlock tempo | 후속 balance/polish |
| 피드백 | Balatro-style scoring preview, Jester/Item 순차 발동, item/Jester 효과 delta 표시, Station Goal pulse | P0 1차 구현 및 required iOS smoke 완료 |

다음 작업 판단:

- "작동하는 한 바퀴" 검증이 목적이면 full loop smoke와 저장/복귀 경계를 먼저 본다.
- "제품형 Station 한 바퀴"가 목적이면 Station Preview/Map의 최소 범위를 먼저 결정한다.
- "잔여 runtime 완성"은 `slide_wax`까지 처리되어 현재 v1 기준 완료 상태다.

우선순위:

1. Save/restore 확장 점검
   - scoring feedback P0와 `slide_wax` runtime 기준 targeted regression은 통과
   - 2026-04-30 fixture full loop smoke는 Station 2 Blind Select까지 도달
   - 남은 수동 점검 후보: 실제 non-fixture app background/continue eye-check
2. B7 Next Station Loop follow-up
   - next station transition command와 blindSelect save scene 연결은 1차 완료
   - Market -> Blind Select 전환 affordance는 1차 적용
   - 남은 작업은 Settlement -> Market affordance와 Station Preview/Map 범위 결정
3. Market / battle interaction polish
   - market card/item slot 기준 유지
   - 설명 패널 높이와 텍스트 말줄임 기준 안정화
   - button/dialog visual consistency 유지
4. Market offer generation follow-up
   - Jester / Item offer 기본 갯수와 증설 규칙을 재검토한다.
   - `boss_trophy`, `shop_lens`처럼 offer 수를 늘리는 효과는 유지하되, 기본 offer 수와 unlock/보상 기반 증설 조건을 별도 balance pass에서 조정한다.
   - 현재 Item offer는 catalog 순서 + reroll offset 기반이므로, 후속에서 Balatro식 rarity 기반 weighted roll로 바꾼다.
   - Jester offer도 현재 지원 가능한 pool의 균등 랜덤이므로, 후속에서 rarity weight, 중복 제외, 현재 빌드/스테이션 조건 가중치를 분리 검토한다.
   - `rarityWeights`와 `rarityWeightBonus`는 데이터/상태가 있으나 현재 roll에 직접 반영되지 않으므로, 적용 시 테스트와 smoke 기준을 함께 추가한다.
5. UI animation polish pass
   - 기존 적용 유지: cash-out sheet의 단계별 보상 라인 등장, Jester scoring burst
   - 현재 진행분 적용: scoring preview, board/rank/overlap callout, Jester/Item slot-local scoring burst, Station Goal pulse
   - 남은 후보: settlement item bonus row 등장 타이밍, total gold 강조, Market route 진입/복귀, Next Station/Blind Select 전환
   - 다음 UI 작업 기본 규칙: 새 modal/sheet/route/보상/아이템 효과는 120~260ms 범위의 짧은 fade/slide/step animation을 우선 검토
   - 아이템 효과는 수동/패시브 모두 발동 사실과 실제 delta가 명확히 보여야 한다. snackbar만으로 끝내지 말고 overlay, badge, `+1` float, resource pulse 중 하나를 제공한다.
   - 입력 차단 barrier는 직접 `ModalBarrier`와 색상 값을 하드코딩하지 말고 `GameInputBarrier.modal()` 또는 `GameInputBarrier.feedback()`를 사용한다.
   - battle item/Jester slot UI는 의미별 표시와 잠금 상태를 분리한다. Quick/Passive/Jester 표시 개수와 초기 해금 개수는 공용 상수/용량 메서드를 사용하고, 새 UI에서 `Q3`, `P2`, `Jester 5th` 잠금을 다시 하드코딩하지 않는다.
   - 과하지 않게 적용: 입력 대기, 반복 플레이 속도, 정보 가독성을 방해하면 애니메이션을 줄이거나 생략
6. Blind / station pacing polish
   - station target scale 기본값 재점검
   - small/big/boss 보상/압박 수치 재조정
   - blind unlock tempo와 continue 복귀 동선 확인
7. Deferred run rule decision
   - Balatro식 blind skip 도입 여부와 조건 결정
   - 도입 시 save/checkpoint/reward 규칙을 먼저 문서화

다음 PR 후보:

- `settlement to market affordance pass`
- `market offer count and rarity roll planning pass`
- `ui animation polish pass`
- `blind/station pacing polish`
