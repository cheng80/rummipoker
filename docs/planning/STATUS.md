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

> 프로토타입을 V4 구조로 흡수하기 위한 기반 공사는 거의 끝났고, 다음 구현 초점은 Item effect runtime의 남은 hook과 station/market pacing polish다.

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
- Jester score effect는 `JesterEffectRuntime` 경유로 정리되어 animation/event 경계를 갖는다.
- 문서 기준은 `START_HERE.md`와 `docs/00_docs_README.md`의 목적형 폴더 체계를 따른다.

## 3. Current Verification Baseline

최근 문서 정리 및 정합성 검증 기준:

- `flutter analyze`: 통과
- `flutter test`: 통과, 224 tests passed
- Markdown absolute link check: 통과
- `git diff --check`: 통과
- item catalog: 49 items / 49 ko translations, runtime applied 48 / pendingHook 1
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
| 기능 안정화 | `slide_wax` item hook | 남은 pending hook 1개 |
| 루프 검증 | full loop smoke 재실행, market resume/save restore, death/continue/restart 경계 확인 | 필요 |
| 전환 UX | Settlement -> Market, Market -> Next Station, Blind Select 도착감/짧은 transition affordance | 미정/후속 |
| Station 구조 | Station Map, Station Preview, Station Definition/Modifier | 아직 미구현, 별도 phase |
| Pacing | target score curve, small/big/boss 보상/압박, unlock tempo | 후속 balance/polish |
| 피드백 | item/Jester 효과 delta 표시, settlement bonus row, resource pulse/float | 후속 UI polish |

다음 작업 판단:

- "작동하는 한 바퀴" 검증이 목적이면 full loop smoke와 저장/복귀 경계를 먼저 본다.
- "제품형 Station 한 바퀴"가 목적이면 Station Preview/Map의 최소 범위를 먼저 결정한다.
- "잔여 runtime 완성"이 목적이면 `slide_wax`를 처리한다.

우선순위:

1. Full loop smoke / save-restore 경계 점검
   - `Battle -> Settlement -> Market -> Next Station/Blind Select -> Battle` 루프를 다시 실행
   - market resume, next station checkpoint, death/continue/restart 경계 확인
2. Item effect runtime 남은 hook 처리
   - 남은 pending hook은 `slide_wax`
3. B7 Next Station Loop follow-up
   - next station transition command와 blindSelect save scene 연결은 1차 완료
   - 남은 작업은 transition affordance와 Station Preview/Map 범위 결정
4. Market / battle interaction polish
   - market card/item slot 기준 유지
   - 설명 패널 높이와 텍스트 말줄임 기준 안정화
   - button/dialog visual consistency 유지
5. UI animation polish pass
   - 기존 적용 유지: cash-out sheet의 단계별 보상 라인 등장, Jester scoring burst
   - 현재 진행분 적용 후보: settlement item bonus row 등장 타이밍, total gold 강조, Market route 진입/복귀, Next Station/Blind Select 전환
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

- `full loop smoke and restore boundary pass`
- `item effect runtime slide wax hook`
- `ui animation polish pass`
- `blind/station pacing polish`
