# Codex 지시서: Rummi Poker Grid V4 마이그레이션 플랜 작성

> Archive role: `prompts`
> Role: 과거 계획 생성 지시서. 최신 구현 계획의 source of truth가 아니다.

> 목적: 이 지시서는 Codex가 **코드를 즉시 수정하지 않고**, 현재 Rummi Poker Grid 프로토타입을 보호하면서 V4 문서 기준으로 **실행 가능한 마이그레이션 플랜**을 작성하게 하기 위한 것이다.
>
> 이번 작업은 **plan-only / docs-only** 작업이다.

---

## 0. 핵심 원칙

현재 코드는 버릴 임시 코드가 아니라 **게임의 핵심 프로토타입**이다.

V4의 목적은 현재 작동하는 코어 루프를 부정하거나 재작성하는 것이 아니라, 아래 현재 핵심을 보존하면서 장기 제품 구조로 흡수 확장하는 것이다.

반드시 보존해야 하는 현재 핵심:

- 5x5 보드
- 12개 평가 라인
- 부분 줄 평가
- 즉시 확정
- One Pair = 0점 dead line
- High Card / One Pair는 확정 후보가 아님
- overlap 보너스
- contributor cell union만 제거
- `copiesPerTile` 기반 덱 구조
- 기본 hand size 1, debug 1~3
- board discard / hand discard 분리
- stage 기반 현재 루프
- cash-out → full-screen Jester shop → next stage
- Jester curated common runtime catalog
- active run save v2
- `stageStartSnapshot` 기반 현재 stage 재시작
- GetStorage + flutter_secure_storage + HMAC-SHA256 저장 무결성

---

## 1. 이번 Codex 작업의 목표

이번 작업의 목표는 **구현이 아니라 계획 수립**이다.

Codex는 저장소를 읽고, V4 문서와 현재 코드 구조를 대조한 뒤, 다음 산출물을 작성해야 한다.

```text
docs/planning/IMPLEMENTATION_PLAN.md
```

이미 해당 파일이 있다면 내용을 보존하면서 최신 기준으로 갱신한다.

이번 작업에서 허용되는 변경:

- `docs/planning/IMPLEMENTATION_PLAN.md` 생성 또는 수정
- 필요 시 `docs/planning/IMPLEMENTATION_PLAN.md` 안에 Risk Register 섹션 생성
- 필요 시 `docs/planning/IMPLEMENTATION_PLAN.md` 안에 Source Traceability 섹션 생성

이번 작업에서 금지되는 변경:

- `lib/` 수정 금지
- `test/` 수정 금지
- `data/` 수정 금지
- `pubspec.yaml` 수정 금지
- format/lint 자동 수정 금지
- 코드 rename 금지
- 저장 schema 변경 금지
- Jester id 변경 금지
- gameplay 수치 변경 금지
- One Pair 점수 변경 금지
- DB/Drift/SQLite/IndexedDB 도입 금지

---

## 2. 반드시 먼저 읽을 문서와 파일

아래 순서대로 읽고 계획을 세운다.

### 2.1 기준 문서

1. `START_HERE.md`
2. `docs/00_docs_README.md`
3. `docs/current_system/CURRENT_SYSTEM_OVERVIEW.md`
4. `docs/current_system/CURRENT_CODE_MAP.md`
5. `docs/current_system/CURRENT_TO_V4_GAP.md`
6. `docs/planning/STATUS.md`
7. `docs/planning/IMPLEMENTATION_PLAN.md`
8. `docs/planning/MIGRATION_ROADMAP.md`
9. `docs/specs/V4/00_README.md`
10. `docs/specs/V4/02_CORE_COMBAT_RULES.md`
11. `docs/specs/V4/03_RUN_META_ECONOMY.md`
12. `docs/specs/V4/04_JESTER_MARKET_CONTENT.md`
13. `docs/specs/V4/05_SAVE_CHECKPOINT_DATA.md`
14. `docs/specs/V4/06_UI_UX_FLOW.md`
15. `docs/specs/V4/07_TECHNICAL_ARCHITECTURE.md`
16. `docs/specs/V4/10_TERMINOLOGY_ALIAS.md`
17. `docs/planning/OPEN_DECISIONS.md`
18. `docs/planning/verification/TEST_QA_ACCEPTANCE.md`

### 2.2 현재 코드 anchor

반드시 아래 코드를 직접 확인한 뒤 계획에 반영한다.

```text
lib/logic/rummi_poker_grid/models/tile.dart
lib/logic/rummi_poker_grid/models/poker_deck.dart
lib/logic/rummi_poker_grid/models/board.dart
lib/logic/rummi_poker_grid/hand_rank.dart
lib/logic/rummi_poker_grid/hand_evaluator.dart
lib/logic/rummi_poker_grid/rummi_poker_grid_engine.dart
lib/logic/rummi_poker_grid/rummi_blind_state.dart
lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart
lib/logic/rummi_poker_grid/jester_meta.dart
lib/providers/features/rummi_poker_grid/game_session_state.dart
lib/providers/features/rummi_poker_grid/game_session_notifier.dart
lib/providers/features/rummi_poker_grid/title_notifier.dart
lib/services/active_run_save_service.dart
lib/utils/storage_helper.dart
lib/views/title_view.dart
lib/views/game_view.dart
lib/views/game/widgets/game_shop_screen.dart
data/common/jesters_common_phase5.json
```

### 2.3 테스트 anchor

현재 보호해야 할 테스트 범위를 파악한다.

```text
test/logic/rummi_board_engine_test.dart
test/logic/rummi_session_test.dart
test/providers/game_session_notifier_test.dart
```

테스트 파일이 없거나 이름이 다르면 실제 `test/` 구조를 검색해서 동등한 테스트를 찾는다.

---

## 3. Source of Truth 우선순위

계획 작성 시 아래 우선순위를 따른다.

1. 실제 코드
2. 현재 테스트
3. `START_HERE.md`
4. `docs/current_system/CURRENT_SYSTEM_OVERVIEW.md`
5. `docs/current_system/CURRENT_CODE_MAP.md`
6. `docs/current_system/CURRENT_TO_V4_GAP.md`
7. V4 문서 세트
8. archive 문서
9. V3 문서

충돌이 발생하면 다음 규칙을 적용한다.

- 코드와 V4 문서가 충돌하면, 즉시 구현 계획에서는 **현재 코드 유지**를 기본값으로 둔다.
- V4 문서는 target/future 방향을 제시할 수 있지만, 현재 동작을 덮어쓰는 근거가 될 수 없다.
- V3 문서가 현재 코드와 충돌하면 V3는 legacy/reference로만 본다.
- One Pair 10점, Station 경제, DB 저장, 코드 rename은 기본 구현 계획에 넣지 않는다. 별도 experimental/future 단계로 분리한다.

---

## 4. 계획 문서 작성 규칙

`docs/planning/IMPLEMENTATION_PLAN.md`는 아래 라벨을 사용해야 한다.

```text
[CURRENT]
현재 코드에 이미 존재하는 사실

[PROTECT]
회귀 방지를 위해 먼저 테스트 또는 정책으로 보호해야 하는 항목

[MIGRATION]
현재 구조를 유지하면서 점진적으로 이동할 작업

[TARGET]
V4 목표 구조지만 아직 기본 구현으로 확정하지 않을 항목

[FUTURE]
장기 확장 또는 제품화 후반 항목

[DO-NOT-DO]
이번 단계 또는 초기 PR에서 금지할 작업

[OPEN]
결정이 필요한 항목
```

추측으로 단정하지 않는다.

확인 수준도 함께 표기한다.

```text
[CODE VERIFIED]
코드에서 직접 확인됨

[TEST VERIFIED]
테스트에서 보호됨

[DOC VERIFIED]
문서에서만 확인됨

[CONFLICT]
코드와 문서가 충돌함

[UNKNOWN]
현재 정보만으로 확인 불가
```

---

## 5. `docs/planning/IMPLEMENTATION_PLAN.md` 필수 목차

아래 목차를 그대로 사용한다.

```md
# Rummi Poker Grid V4 Implementation Plan

## 1. Plan Scope
## 2. Current Baseline Summary
## 3. Non-Negotiable Protection Rules
## 4. Source Traceability
## 5. Current Code Anchors
## 6. Risk Register
## 7. Migration Phases
## 8. PR Breakdown
## 9. Test Strategy
## 10. Save Compatibility Strategy
## 11. Terminology Migration Strategy
## 12. Jester / Market Migration Strategy
## 13. UI / UX Migration Strategy
## 14. Open Decisions
## 15. Acceptance Criteria
## 16. First 3 PR Detailed Plan
## 17. Explicitly Deferred Work
```

---

## 6. 각 섹션 작성 지침

### 6.1 Plan Scope

이번 계획이 무엇을 하는지, 무엇을 하지 않는지 명확히 쓴다.

반드시 포함:

- 이 문서는 구현 플랜이다.
- 이 PR 자체는 plan-only/docs-only다.
- 현재 프로토타입 보호가 최우선이다.
- V4 target은 단계적으로 흡수한다.

### 6.2 Current Baseline Summary

현재 구현 요약을 작성한다.

반드시 포함:

- Combat: 5x5, 12라인, partial line, instant confirm, contributor removal, overlap
- Scoring: High Card 0, One Pair 0, Two Pair 이상 scoring
- Deck: `copiesPerTile`
- Run: stage → cash-out → shop → next stage
- Economy: start gold, reroll, clear reward는 현재 코드 기준으로 확인
- Jester: common curated catalog, equipped slots, shop buy/sell/reroll, stateful 일부
- Save: active run save v2, stageStartSnapshot, HMAC
- UI: title, game, full-screen shop, settings

### 6.3 Non-Negotiable Protection Rules

초기 마이그레이션에서 절대 깨면 안 되는 규칙을 쓴다.

필수 항목:

- One Pair는 기본 ruleset에서 계속 0점
- scoring candidate는 Two Pair 이상
- contributor union만 제거
- Jester id 변경 금지
- save schema 즉시 교체 금지
- `RummiBlindState` 등 코드 심볼 즉시 rename 금지
- Station/Market/Archive는 초기에는 target adapter 또는 UI-only 수준으로 제한

### 6.4 Source Traceability

현재 계획이 어떤 파일에 근거하는지 표로 작성한다.

형식:

```md
| Area | Current Source | V4 Source | Status | Notes |
|---|---|---|---|---|
| Combat scoring | `hand_rank.dart` | `02_CORE_COMBAT_RULES.md` | [CODE VERIFIED] | One Pair 0 |
```

### 6.5 Current Code Anchors

핵심 파일별 책임과 변경 위험도를 작성한다.

형식:

```md
| File | Responsibility | Migration Risk | Plan Policy |
|---|---|---:|---|
| `rummi_poker_grid_session.dart` | confirm/removal/stage transition | High | tests first |
```

위험도는 `Low / Medium / High / Critical` 중 하나로 표기한다.

### 6.6 Risk Register

최소 12개 이상의 리스크를 작성한다.

반드시 포함할 리스크:

1. One Pair 10점 오도입
2. contributor 제거 대신 line 전체 제거 회귀
3. overlap multiplier 변경으로 점수 회귀
4. Jester 발동 순서 변경
5. stageStartSnapshot 손상
6. active run save/load 호환성 파손
7. 코드 rename으로 Provider/UI/save 연결 파손
8. Station 용어가 current 구현처럼 오해됨
9. DB 도입으로 현재 continue가 깨짐
10. Jester catalog id 변경
11. economy 수치와 전투 룰 동시 변경
12. UI-only 변경이 도메인 변경으로 번짐

형식:

```md
| Risk | Impact | Likelihood | Mitigation | Guardrail Test |
|---|---|---|---|---|
```

### 6.7 Migration Phases

반드시 아래 대분류를 사용하되, 저장소 상태에 맞게 세분화한다.

```text
Phase 0: Plan lock
Phase 1: Regression tests
Phase 2: Compatibility wrappers
Phase 3: Ruleset config skeleton
Phase 4: UI-only terminology bridge
Phase 5: Market/Jester adapter preparation
Phase 6: Save/checkpoint adapter preparation
Phase 7: Station target prototype behind feature flag
Phase 8: Archive/stats read model
Phase 9: Balance pass
Phase 10: Optional code rename
```

각 Phase마다 아래를 작성한다.

```md
### Phase N: Name

Goal:
Files likely touched:
Allowed changes:
Forbidden changes:
Required tests:
Acceptance criteria:
Rollback strategy:
```

### 6.8 PR Breakdown

실제 PR 단위로 쪼갠다.

각 PR은 작고 되돌릴 수 있어야 한다.

형식:

```md
| PR | Type | Goal | Files | Risk | Must Pass | Not Allowed |
|---|---|---|---|---|---|---|
```

권장 순서:

1. docs-only plan lock
2. combat regression tests
3. save/restart regression tests
4. confirm compatibility wrapper
5. ruleset config skeleton
6. terminology alias UI-only
7. market offer adapter
8. save/checkpoint adapter
9. archive/stats read model
10. station feature flag prototype

### 6.9 Test Strategy

테스트 우선순위를 작성한다.

반드시 포함:

- `HandRank.onePair.score == 0`
- One Pair는 confirm 후보가 아님
- Two Pair contributor 4장만 제거
- Four of a Kind contributor 4장만 제거
- Straight / Flush / Full House는 5장 contributor
- overlap alpha/cap 유지
- board full + no discard 만료 조건
- deck exhausted + no playable action 만료 조건
- stage clear → cash-out → shop → next stage
- stageStartSnapshot restart
- active run save/load HMAC 검증
- corrupted save 처리
- Jester stateful value save/restore

### 6.10 Save Compatibility Strategy

저장 관련 계획은 특히 보수적으로 작성한다.

반드시 포함:

- current active run save v2는 유지
- DB/Archive는 즉시 대체가 아니라 read model 또는 adapter로 접근
- 기존 save payload와 stageStartSnapshot을 깨지 않는다
- schema 변경이 필요하면 별도 PR + migration test + rollback plan 필요

### 6.11 Terminology Migration Strategy

`Stage/Blind`와 `Station/Objective`의 용어 전환 전략을 작성한다.

기본 정책:

- 초기: 문서 alias
- 다음: UI-only 용어 전환
- 마지막: 코드 심볼 rename

코드 rename은 가장 뒤로 보낸다.

### 6.12 Jester / Market Migration Strategy

현재 Jester 중심 shop을 장기 Market 구조로 확장하는 계획을 작성한다.

기본 정책:

- current `jester_meta.dart`의 기능을 즉시 분해하지 않는다.
- 먼저 adapter/read model을 둔다.
- Jester id와 save된 stateful slot 구조를 보호한다.
- Run Kit / Permit / Glyph / Orbit / Echo / Sigil은 target/future로 분리한다.

### 6.13 UI / UX Migration Strategy

현재 UI 흐름을 보호하면서 장기 UX로 가는 계획을 작성한다.

기본 정책:

- title → game → cash-out → shop → next stage 유지
- full-screen shop 유지
- Station map / Archive / Trial은 별도 route로 target 처리
- 전투 화면 리디자인은 전투 로직 변경 PR과 분리

### 6.14 Open Decisions

아직 결정하지 말아야 할 항목과 결정이 필요한 항목을 분리한다.

반드시 포함:

- One Pair 10점 실험 여부
- 최종 Station 수
- Entry/Pressure/Lock 수치
- 최종 economy 수치
- DB 엔진 도입 시점
- Archive/Stats 최소 범위
- 코드 rename 시점

### 6.15 Acceptance Criteria

계획 문서가 완료되었다고 볼 수 있는 조건을 작성한다.

필수 조건:

- 첫 3개 PR이 명확해야 한다.
- 각 PR의 금지 작업이 명시되어야 한다.
- 현재 코어 전투 보호 테스트가 식별되어야 한다.
- save/restart 보호 전략이 있어야 한다.
- Station/Market/Archive가 current로 오해되지 않아야 한다.
- One Pair 0점 규칙이 보호되어야 한다.

### 6.16 First 3 PR Detailed Plan

첫 3개 PR은 상세 작업 체크리스트까지 작성한다.

권장:

```text
PR 1: V4 implementation plan lock
PR 2: combat regression tests
PR 3: save/restart regression tests
```

각 PR마다:

- Goal
- Files to inspect
- Files to change
- Tests to add or run
- Review checklist
- Abort conditions

### 6.17 Explicitly Deferred Work

초기 마이그레이션에서 미루는 작업을 명시한다.

반드시 포함:

- One Pair 10점 기본 도입
- Station 30개 전체 구현
- Entry/Pressure/Lock 본 구현
- DB 저장소 교체
- Archive 완성형 구현
- Risk Grade / Trial 구현
- 대규모 코드 rename
- Jester catalog id 변경
- economy full rebalance

---

## 7. Codex 작업 절차

Codex는 아래 순서로 작업한다.

1. 문서와 코드 anchor를 읽는다.
2. 현재 구현 사실을 요약한다.
3. V4 target과 현재 구현 사이의 차이를 표로 만든다.
4. 위험한 충돌 항목을 분류한다.
5. 구현 순서를 Phase로 나눈다.
6. Phase를 PR 단위로 쪼갠다.
7. 첫 3개 PR을 상세화한다.
8. 금지 작업과 deferred work를 명시한다.
9. `docs/planning/IMPLEMENTATION_PLAN.md`를 작성한다.
10. 변경 파일 목록을 최종 요약한다.

---

## 8. 최종 응답 형식

작업 완료 후 Codex는 다음 형식으로 보고한다.

```md
## Summary
- 작성/수정한 문서:
- 이번 작업에서 코드 변경 여부: 없음
- 주요 결정:

## Current Baseline Protected
- 보호한 current facts:

## Plan Output
- 생성된 플랜 문서 경로:
- 첫 3개 PR:

## Risks Found
- 가장 위험한 충돌 5개:

## Deferred
- 이번 플랜에서 명시적으로 미룬 작업:

## Verification
- 읽은 주요 파일:
- 수정한 파일:
- 수정하지 않은 영역:
```

---

## 9. 금지 문장 / 금지 판단

아래 식으로 판단하거나 작성하지 않는다.

- “V4에 있으므로 지금 구현한다.”
- “Station이 canonical이므로 Blind 코드를 rename한다.”
- “DB 구조가 V4 target이므로 현재 save를 교체한다.”
- “One Pair 10점이 더 자연스러우므로 기본 점수를 바꾼다.”
- “Jester catalog를 새 구조에 맞춰 id를 정리한다.”
- “UI 용어 정리와 도메인 rename을 같은 PR에서 처리한다.”
- “경제 수치 변경과 전투 룰 변경을 같은 PR에서 처리한다.”

---

## 10. 핵심 판단 기준

계획이 애매할 때는 아래 기준을 따른다.

1. 현재 플레이 가능한 코어 루프를 보호한다.
2. 전투 룰 변경보다 회귀 테스트를 먼저 둔다.
3. 저장 구조 변경보다 save/load compatibility를 먼저 둔다.
4. 용어 변경보다 alias 정책을 먼저 둔다.
5. 장기 target은 feature flag 또는 adapter 뒤에 둔다.
6. 큰 변경은 작고 되돌릴 수 있는 PR로 분리한다.
7. 코드 rename은 마지막 단계로 보낸다.
8. 문서와 코드가 충돌하면 코드 기준으로 계획한다.

---

## 11. 최종 한 줄 목표

Codex는 이번 작업에서 구현하지 않는다.

**현재 Rummi Poker Grid 핵심 프로토타입을 보호하면서 V4 target으로 이동하기 위한, 작고 검증 가능한 PR 단위의 실행 계획을 작성한다.**
