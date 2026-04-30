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

> 프로토타입을 V4 구조로 흡수하기 위한 기반 공사는 거의 끝났고, Balatro-style scoring feedback P0, Item effect runtime v1 hook, full loop fixture smoke, Settlement -> Market affordance, Market -> Blind Select transition affordance, market readability polish는 1차 구현/검증됐다. Station Preview/Map scope, Market offer count/rarity roll 계획, Blind/Station pacing baseline, Boss modifier taxonomy, Starting deck archetype reference, Jester taxonomy reference, Consumable/Voucher taxonomy reference도 정리했다. 다음 구현 초점은 balance simulation readiness다.

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
- Jester taxonomy reference 정리 완료: Balatro식 Joker 목록은 발동 순서, condition inheritance, edition/penalty, 성장/경제/시장/점수식 변형 taxonomy 참고로만 사용한다. 기존 Jester id는 유지한다.
- Consumable/Voucher taxonomy reference 정리 완료: Balatro식 Tarot/Planet/Spectral/Voucher 구조는 confirm modifier, tile enhancement, rank progression, high-risk mutation, run-long passive 후보로 분리한다. 현재 Item 49개 runtime은 유지한다.
- 2026-04-30 huashu-design/Balatro 기준 UI 리뷰 결과, Jester/Item은 접는 인벤토리가 아니라 항상 보이는 scoring engine으로 유지한다. 확정 전 preview, Item slot active scoring effect, board/rank/overlap/Jester/Item/final score 순차 presentation은 1차 구현됐다. 실행 계획과 남은 smoke 기준은 `docs/planning/feature_plans/BALATRO_STYLE_SCORING_FEEDBACK_PLAN.md`를 따른다.
- Market build readability polish 1차 적용 완료: 선택 offer 상세 패널의 조건/효과 synergy tag, Jester offer 외부 selection frame, 구매 불가 reason 표시가 연결됐다. Offer 카드 자체는 슬롯 타입/가격/선택 상태만 담당한다.
- Settlement -> Market affordance 1차 적용 완료: cash-out sheet에서 Market 진입을 확정하면 market runtime/save를 먼저 완료한 뒤 짧은 `Market 준비` overlay를 재생하고 상점 route를 연다.
- Station Preview/Map scope decision 완료: 현재 `BlindSelectView`를 `Station Preview v1`로 공식화하고, Station Map 전체 구현은 후속으로 둔다. ML 로그의 station 단위는 `stageIndex + blind tier`를 기준으로 한다.
- Market offer count / rarity roll plan 완료: 기본 offer 수 3/3, v1 cap 5, rarity weight, 중복 제외, 구매 후 재노출 방지, item offer save/restore 개선 필요성을 `MARKET_OFFER_COUNT_RARITY_ROLL_PLAN.md`에 정리했다.
- Blind/Station pacing baseline 완료: 현재 target curve, difficulty multiplier, Small/Big/Boss pressure, reward preview/cash-out reward 기준을 `v4_pacing_baseline_1`로 문서화했다.
- Boss modifier 방향 정리: Boss는 장기적으로 visible rule modifier를 갖는 전투로 보며, draw 기반 손패 구조 때문에 Balatro식 face-down hand-card 패턴은 그대로 복사하지 않는다.
- Boss modifier v1 적용 완료: 보스 블라인드에 `빨간 타일 약화` 제약을 붙이고, 진입 팝업, Station Preview 표시, board/hand marker, scoring penalty callout, save/restore를 연결했다. 화면에는 내부 modifier 변수명 없이 한글 설명만 노출한다.
- 저장 정답 상태와 transient presentation state 분리 원칙을 Battle/Market/Settlement 전체 기준으로 고정했다. `session/runProgress/stageStartSnapshot`이 save/continue의 정답이고, HUD 표시 지연값/정산 step/selection/overlay/reveal은 저장하지 않는 presentation state다.
- 정산 점수 표시 보정 적용 완료: 확정 점수는 버튼 직후 runtime/save 기준으로 커밋하고, Station Goal 화면 숫자는 line별 final score 단계에서 뒤따라 표시한다. 후속 연출이 늘어나면 `GamePresentationEvent` / `presentationQueue` 형태의 transient event list로 묶는 것을 우선 검토한다.
- Starting deck archetype 방향 정리: Balatro식 시작 덱/카드 강화는 참고하되, 현재 New Run은 Random/Seed만 유지한다. 후속 작업은 `run_archetype_id`와 `tile_modifier_id` 기준으로 ML/simulator에 먼저 연결한다.
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
| 전환 UX | Settlement -> Market, Market -> Next Station -> Blind Select transition affordance | 1차 적용 |
| Station 구조 | Station Preview v1, Station Map, Station Definition/Modifier | Preview v1 scope 결정 완료 / Map graph와 Modifier는 후속 |
| Market 생성 규칙 | offer 갯수 증설, Balatro식 rarity 기반 shop roll | planning 완료 / 구현 후속 |
| Pacing | target score curve, small/big/boss 보상/압박, unlock tempo | baseline 문서화 완료 / 수치 변경은 후속 |
| Boss 제약 | Boss modifier taxonomy, tile color weaken v1 | v1 구현 완료 / 확장 후속 |
| 제약 표시 | Entry popup, compact marker, position-local penalty float | v1 구현 완료 |
| 시작 덱 | Starting deck archetype, tile enhancement reference | planning 완료 / ML 후속 |
| Jester 확장 | Jester activation order, edition/penalty, effect taxonomy | planning 완료 / 구현 후속 |
| Item 확장 | Consumable/Voucher taxonomy, rank progression, run passive | planning 완료 / 구현 후속 |
| Item 인벤토리 UX | 보유 아이템 판매 `sellItem` 구현 | 슬롯 수 제약 때문에 필요 / 후속 구현 |
| 피드백 | Balatro-style scoring preview, Jester/Item 그룹 발동, item/Jester 효과 delta 표시, Station Goal 내부 glow, 저장/연출 상태 분리 | P0 1차 구현 및 required iOS smoke 완료 / presentation queue 도입은 후속 |

다음 작업 판단:

- "작동하는 한 바퀴" 검증이 목적이면 full loop smoke와 저장/복귀 경계를 먼저 본다.
- "ML 기반 밸런스 자동화"가 목적이면 Station/Market/Pacing 규칙을 먼저 고정하고, 그 다음 simulator readiness로 들어간다.
- "제품형 Station 한 바퀴"가 목적이면 Station Preview/Map의 최소 범위를 먼저 결정한다. 이 작업은 ML log schema의 station 단위도 함께 고정한다.
- "잔여 runtime 완성"은 `slide_wax`까지 처리되어 현재 v1 기준 완료 상태다.
- "아이템 인벤토리 사용성"이 목적이면 quick/passive/equipped 슬롯 수 제약을 고려해 보유 아이템 판매 `sellItem`을 먼저 구현한다.
- "정산 체감 속도/게임감"이 목적이면 Jester/Item 발동 그룹 표시 위에 카드 shake, impact spark, score trail 같은 이펙트 polish를 추가한다.
- "연출 구조 안정화"가 목적이면 새 이펙트를 먼저 늘리기보다 `GamePresentationEvent` / `presentationQueue` transient event list로 Battle/Market/Settlement 연출을 모을 수 있는지 설계한다.

ML readiness 기준 우선순위:

1. Station Preview/Map scope decision
   - ML 로그의 `station_id`, `blind_tier`, 선택지, modifier 범위를 흔들리지 않게 만든다.
   - 완료: `docs/planning/feature_plans/STATION_PREVIEW_MAP_SCOPE_PLAN.md`
   - Station Map 전체 구현이 아니라, simulator/log schema가 참조할 최소 Station 단위를 먼저 결정했다.
2. Market offer count and rarity roll planning pass
   - Jester / Item offer 기본 갯수, 증설 규칙, 중복 제외, 구매 후 재노출 방지, rarity weighted roll 규칙을 문서화한다.
   - `rarityWeights`와 `rarityWeightBonus`가 실제 roll과 simulator feature에 어떻게 반영되는지 정한다.
   - 완료: `docs/planning/feature_plans/MARKET_OFFER_COUNT_RARITY_ROLL_PLAN.md`
3. Blind / station pacing baseline pass
   - station target score curve, small/big/boss 보상/압박, discard reward, unlock tempo의 v1 baseline을 고정한다.
   - ML은 이 baseline version을 기준으로 데이터를 쌓는다.
   - 완료: `docs/planning/feature_plans/BLIND_STATION_PACING_BASELINE_PLAN.md`
4. Boss modifier taxonomy pass
   - Boss를 단순 target x2 전투가 아니라 visible rule modifier 전투로 다룬다.
   - Balatro Boss/Stake 제약은 참고하되, face-down hand-card 패턴은 draw 기반 구조에 맞게 재설계한다.
   - 완료: `docs/planning/feature_plans/BOSS_MODIFIER_TAXONOMY_PLAN.md`
5. Constraint visual language pass
   - Boss/Station/Jester/Item 제약은 진입 팝업으로 먼저 설명하고, 전투 중에는 작은 marker와 position-local penalty float만 사용한다.
   - 완료: `docs/planning/feature_plans/CONSTRAINT_VISUAL_LANGUAGE_PLAN.md`
6. Boss modifier v1 implementation pass
   - 완료: 보스 블라인드의 첫 visible rule modifier로 `빨간 타일 약화`를 적용했다.
   - 연결: Blind Select card, battle entry popup, board/hand compact marker, scoring penalty callout, save/restore.
7. Balance simulation readiness pass
   - `docs/specs/V4/14_BALANCE_AUTOMATION_ML.md` 기준으로 log field, deterministic seed, bot boundary, UI 의존성 제거 목록을 확정한다.
   - `/plan-eng-review` 입력 범위는 `docs/planning/feature_plans/BALANCE_SIMULATION_READINESS_PLAN.md`를 기준으로 본다.
   - 현재 권장 구현 진입점은 기존 runtime을 재구성하는 것이 아니라 CLI import spike로 재사용 가능성을 먼저 확인하는 것이다.
   - `run_archetype_id = standard_tile_deck_v1` 같은 시작 덱 기준 필드를 read-only로 먼저 포함한다.
   - Jester effect category와 edition/penalty count는 `JESTER_REFERENCE_TAXONOMY_PLAN.md` 기준으로 feature 후보에 포함한다.
   - Consumable/Voucher effect category와 rank progression은 `CONSUMABLE_VOUCHER_REFERENCE_PLAN.md` 기준으로 feature 후보에 포함한다.
   - 아직 PyTorch 구현이 아니라 `tools/sim/run_balance_sim.dart`를 만들 수 있는 준비 상태를 만든다.
8. Save/restore 확장 점검
   - scoring feedback P0와 `slide_wax` runtime 기준 targeted regression은 통과
   - 2026-04-30 fixture full loop smoke는 Station 2 Blind Select까지 도달
   - 남은 수동 점검 후보: 실제 non-fixture app background/continue eye-check
9. B7 Next Station Loop follow-up
   - next station transition command와 blindSelect save scene 연결은 1차 완료
   - Market -> Blind Select 전환 affordance는 1차 적용
   - Settlement -> Market 전환 affordance는 1차 적용
   - 남은 작업은 Station Preview/Map 범위 결정
10. Market / battle interaction polish
   - market card/item slot 기준 유지
   - 설명 패널 높이와 텍스트 말줄임 기준 안정화
   - button/dialog visual consistency 유지
11. UI animation polish pass
   - 기존 적용 유지: cash-out sheet의 단계별 보상 라인 등장, Jester scoring burst
   - 현재 진행분 적용: scoring preview, board/rank/overlap callout, Jester/Item slot-local scoring burst, Station Goal pulse
   - 남은 후보: settlement item bonus row 등장 타이밍, total gold 강조, Market route 진입/복귀, Next Station/Blind Select 전환
   - 다음 UI 작업 기본 규칙: 새 modal/sheet/route/보상/아이템 효과는 120~260ms 범위의 짧은 fade/slide/step animation을 우선 검토
   - 아이템 효과는 수동/패시브 모두 발동 사실과 실제 delta가 명확히 보여야 한다. snackbar만으로 끝내지 말고 overlay, badge, `+1` float, resource pulse 중 하나를 제공한다.
   - 입력 차단 barrier는 직접 `ModalBarrier`와 색상 값을 하드코딩하지 말고 `GameInputBarrier.modal()` 또는 `GameInputBarrier.feedback()`를 사용한다.
   - battle item/Jester slot UI는 의미별 표시와 잠금 상태를 분리한다. Quick/Passive/Jester 표시 개수와 초기 해금 개수는 공용 상수/용량 메서드를 사용하고, 새 UI에서 `Q3`, `P2`, `Jester 5th` 잠금을 다시 하드코딩하지 않는다.
   - 연출이 2~3개 이상 추가되면 `stageFlowPhase`와 `activeSettlement*` 같은 개별 field 확장보다 transient `GamePresentationEvent` / `presentationQueue` 구조를 먼저 검토한다.
   - presentation queue는 save DTO에 포함하지 않는다. save/continue의 source of truth는 runtime state이며, queue는 비어 있어도 게임 결과가 변하지 않아야 한다.
   - 과하지 않게 적용: 입력 대기, 반복 플레이 속도, 정보 가독성을 방해하면 애니메이션을 줄이거나 생략
12. Deferred run rule decision
   - Balatro식 blind skip 도입 여부와 조건 결정
   - 도입 시 save/checkpoint/reward 규칙을 먼저 문서화

다음 PR 후보:

- `balance simulation readiness pass`
- `balance simulation skeleton implementation pass`
- `market rarity roll implementation pass`
- `presentation queue architecture pass`
- `ui animation polish pass`
- `blind/station pacing polish`
