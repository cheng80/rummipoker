# 08. Migration Roadmap

> 문서 성격: migration plan
> 코드 반영 상태: planned
> 핵심 정책: 현재 코어 프로토타입을 보존하며 V4 target을 단계 도입한다.

## 0. Migration Principle

[V4_DECISION]

이 프로젝트의 current code는 버릴 코드가 아니라 게임의 핵심 프로토타입이다. V4 migration은 rewrite가 아니라 흡수 확장이다.

## 1. Phase 0 — Docs Lock

[MIGRATION]

목표:

- V4 문서를 기준으로 current/target/future 혼선 제거
- V3의 즉시 구현 오해 차단
- 현재 baseline 고정

작업:

- V4 docs commit
- README에 source priority 명시
- Current baseline 문서 추가
- One Pair 0점 dead line 결정 명시
- save v2 보호 정책 명시

완료 조건:

- README만 읽어도 target 항목을 current로 오해하지 않는다.
- Station, DB, Pair scoring이 즉시 구현 지시가 아님이 명확하다.

## 2. Phase 1 — Regression Tests

[MIGRATION]

목표:

- 현재 전투 코어 보호
- 저장/재시작 보호
- Jester score context 보호

필수 테스트:

- One Pair는 0점 dead line
- One Pair는 확정 후보 아님
- 4장 Three of a Kind는 scoring candidate
- contributor만 제거
- kicker는 남음
- overlap alpha/cap 계산
- Jester는 contributor scoringTiles 기준
- stage clear score 반영
- board discard / hand discard 분리
- active run save/load
- stageStartSnapshot restart
- activeScene shop restore

완료 조건:

- 위 테스트가 실패하면 V4 migration 작업을 merge하지 않는다.

## 3. Phase 2 — Naming Compatibility

[MIGRATION]

목표:

- legacy 의미와 실제 의미 차이를 wrapper로 완화
- 대규모 rename 없이 다음 작업 준비

작업:

- `confirmScoringLines` 추가
- `confirmAllFullLines`는 wrapper로 유지
- docs/comments의 “full lines” 표현 정리
- `isDeadLine` comment mismatch 수정
- `gddCanClearLine` 사용 여부 점검

금지:

- `RummiBlindState` rename
- save field rename
- economy 수치 변경

## 4. Phase 3 — Ruleset Config Skeleton

[MIGRATION]

목표:

- V4 target 실험을 기본 ruleset과 분리

작업:

- `RummiRulesetConfig` 초안 추가
- currentPrototype 기본값 정의
- overlap alpha/cap config화 검토
- Pair scoring flag 추가하되 default false
- Expiry policy flag 추가하되 current behavior 유지

완료 조건:

- current tests가 그대로 통과한다.
- flag를 켜지 않으면 게임 동작이 바뀌지 않는다.

## 5. Phase 4 — Station Terminology UI-only

[MIGRATION]

목표:

- 플레이어-facing 용어만 Station 방향으로 실험

작업:

- HUD label `STAGE` -> `STATION` 실험
- cash-out 문구 수정
- shop next stage 문구 수정
- title copy 정리

금지:

- code symbol rename
- save schema rename
- stageIndex field 변경

완료 조건:

- 기존 save continue 가능
- stageStartSnapshot restart 가능

## 6. Phase 5 — Market Adapter

[MIGRATION]

목표:

- Jester shop을 Market 구조로 확장할 준비

작업:

- `MarketOffer` domain 추가
- `RummiShopOffer` -> `MarketOffer` adapter
- 기존 GameShopScreen은 Jester offer 계속 표시
- offer category badge 추가 가능

금지:

- 기존 Jester id 변경
- shop catalog 필터 제거
- 미지원 effectType의 무분별한 노출

## 7. Phase 6 — Checkpoint / Save Adapter

[MIGRATION]

목표:

- Station Checkpoint, profile/archive target으로 갈 길 확보

작업:

- current save v2 golden test
- `rulesetVersion` 저장 검토
- save adapter 계층 추가
- `ActiveRunStageSnapshot`을 target `CheckpointState`로 mapping하는 문서/코드 추가

금지:

- active run save 제거
- DB로 즉시 교체

## 8. Phase 7 — Station Modifier Prototype

[MIGRATION]

목표:

- Entry / Pressure / Lock을 전투 엔진 외부 modifier로 실험

작업:

- `StationDefinition` 추가
- `StationModifier` interface 추가
- targetScore multiplier 또는 discard modifier처럼 낮은 위험도 효과부터 도입
- UI preview 추가

금지:

- HandEvaluator 기본 규칙 직접 변경
- Pair scoring 기본값 변경

## 9. Phase 8 — Archive / Stats Read Model

[MIGRATION]

목표:

- active run save와 분리된 장기 기록 도입

작업:

- run end summary 정의
- local archive read model 추가
- stats screen 초안
- collection discovered id 저장

금지:

- active run restore 로직과 archive 저장을 강하게 결합

## 10. Phase 9 — Balance Pass

[MIGRATION]

목표:

- Station 구조가 붙은 뒤 경제/난이도 재조정
- ML 기반 밸런스 자동화가 참조할 baseline balance version 확정

작업:

- target score curve 재검토
- starting gold 재검토
- discard reward 재검토
- Jester price/pool 조정
- risk grade별 multiplier 조정

ML readiness 선행 순서:

1. Station Preview/Map 최소 범위 결정
   - 완료 기준: `BlindSelectView`를 `Station Preview v1`로 공식화하고, Station Map graph는 후속으로 둔다.
2. Market offer count와 rarity weighted roll 규칙 결정
   - 완료 기준: `MARKET_OFFER_COUNT_RARITY_ROLL_PLAN.md`에서 기본 offer 수, cap, rarity weight, 중복 제외, save/restore 경계를 고정한다.
3. Blind/station pacing baseline 확정
   - 완료 기준: `BLIND_STATION_PACING_BASELINE_PLAN.md`에서 `v4_pacing_baseline_1` balance version으로 현재 target/reward/pressure 수치를 기록한다.
4. Boss modifier taxonomy 확정
   - 완료 기준: `BOSS_MODIFIER_TAXONOMY_PLAN.md`에서 Boss 제약 범주, preview/feedback/save/log 요구사항, Balatro Boss/Stake reference-only 정책을 고정한다.
5. Starting deck archetype 기준 확정
   - 완료 기준: `STARTING_DECK_ARCHETYPE_PLAN.md`에서 현재 기본 archetype, 후속 starting deck, tile enhancement, simulator log field를 분리한다.
6. Jester taxonomy 기준 확정
   - 완료 기준: `JESTER_REFERENCE_TAXONOMY_PLAN.md`에서 Jester 발동 순서, effect category, edition/penalty, ML feature 후보를 고정한다.
7. Consumable / voucher taxonomy 기준 확정
   - 완료 기준: `CONSUMABLE_VOUCHER_REFERENCE_PLAN.md`에서 Item consumable, rank progression, high-risk mutation, run-long passive/voucher 후보를 고정한다.
8. Constraint visual language 기준 확정
   - 완료 기준: `CONSTRAINT_VISUAL_LANGUAGE_PLAN.md`에서 entry popup, compact marker, position-local penalty float 기준을 고정한다.
9. Boss modifier v1 implementation pass
   - 완료 기준: 최소 1개 visible Boss rule modifier를 preview, entry popup, battle marker, scoring feedback, save/restore에 연결한다.
   - 현재 완료: `빨간 타일 약화` v1
10. Balance simulation readiness pass
11. `14_BALANCE_AUTOMATION_ML.md`의 simulator/JSONL/PyTorch 도입 순서 검토

금지:

- 테스트 없이 경제 수치 일괄 변경

## 11. Codex 작업 지시 템플릿

```text
작업 목표:
V4 migration의 [PHASE_NAME]만 수행한다.
현재 코드는 Rummi Poker Grid의 핵심 프로토타입이므로 재작성하지 않는다.

범위:
- 수정 허용: [FILES]
- 수정 금지: [FILES]

반드시 유지:
- 부분 줄 평가
- 즉시 확정
- One Pair = 0점 dead line
- contributor만 제거
- overlap alpha 0.3 / cap 2.0
- active run save v2
- stageStartSnapshot restart
- 기존 Jester id

완료 조건:
- 기존 behavior regression 없음
- save/load 호환 유지
- 테스트 추가 또는 기존 테스트 통과
- target 항목을 current로 선언하지 않음
```
