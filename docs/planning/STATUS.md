# V4 Current Status

> GCSE role: `Execution`
> Source of truth: 최신 진행 상태, 다음 작업 판단.

이 문서는 최신 상태만 유지한다. 이전 상세 체크리스트와 긴 검증 이력은 `docs/archive/legacy/V4_STATUS_HISTORY_2026-04-22.md`에서 검색한다.

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
- battle item zone은 quick slot/passive rack item을 read model로 표시한다.
- `ItemEffectRuntime`은 현재 적용 완료와 pending hook을 `docs/planning/ITEM_EFFECT_RUNTIME_MATRIX.md`에서 관리한다.
- Jester score effect는 `JesterEffectRuntime` 경유로 정리되어 animation/event 경계를 갖는다.
- 문서 기준은 `START_HERE.md`와 `docs/00_docs_README.md`의 목적형 폴더 체계를 따른다.

## 3. Current Verification Baseline

최근 문서 정리 및 정합성 검증 기준:

- `flutter analyze`: 통과
- `flutter test`: 통과, 188 tests passed
- Markdown absolute link check: 통과
- `git diff --check`: 통과
- item catalog: 49 items / 49 ko translations
- phase5 jester catalog: 38 jesters / 61 ko translations, phase5 기준 누락 없음

의미 있는 앱 실구동 검증이 필요한 경우 아래 스크립트를 먼저 사용한다.

- `tools/ios_sim_smoke.sh`
- `tools/web_build_smoke.sh`

과거 iOS/web smoke 산출물 경로 전체 목록은 `docs/archive/legacy/V4_STATUS_HISTORY_2026-04-22.md`에서 검색한다.

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

우선순위:

1. Item effect runtime 남은 hook 처리
   - Group 3: Direct Gold and Economy Hooks
   - Group 4: Settlement Reward Modifiers
   - Group 5 이후 pending hook은 `ITEM_EFFECT_RUNTIME_MATRIX.md` 기준으로 진행
2. Market / battle interaction polish
   - market card/item slot 기준 유지
   - 설명 패널 높이와 텍스트 말줄임 기준 안정화
   - button/dialog visual consistency 유지
3. Blind / station pacing polish
   - station target scale 기본값 재점검
   - small/big/boss 보상/압박 수치 재조정
   - blind unlock tempo와 continue 복귀 동선 확인
4. Deferred run rule decision
   - Balatro식 blind skip 도입 여부와 조건 결정
   - 도입 시 save/checkpoint/reward 규칙을 먼저 문서화

다음 PR 후보:

- `item effect runtime direct economy hook`
- `item effect runtime settlement reward hook`
- `blind/station pacing polish`
