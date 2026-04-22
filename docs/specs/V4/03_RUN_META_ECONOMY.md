# 03. Run Meta & Economy

> 문서 성격: Run meta / Station / Economy 기능 계약
> 코드 반영 상태: current stage loop implemented, Station target planned
> 핵심 정책: 현재 stage loop를 보호하고, Station은 장기 메타 구조로 단계 도입한다.

현재 run loop와 economy 수치 상세는 `docs/current_system/CURRENT_BUILD_BASELINE.md`를 기준으로 본다.
진행 상태와 다음 구현 순서는 `docs/planning/STATUS.md`와 `docs/planning/MIGRATION_ROADMAP.md`를 기준으로 본다.

## 1. Current Boundary Reference

[CURRENT]

현재 구현에서 보호해야 할 사실만 요약한다.

- current loop는 `battle -> settlement/cash-out -> market -> next stage`다.
- current economy 수치는 migration 전 기본값으로 보호한다.
- `stageStartSnapshot`은 현재 stage 시작점 복원 기준이다.
- sector map, station map, entry/pressure/lock, run kit, risk grade, trial, archive/stats는 target 영역이다.

## 2. Stage To Station Alias Contract

[TARGET]

V4 장기 제품 구조에서는 `stage`를 플레이어-facing 개념으로 `Station`에 흡수한다.

| Current | V4 Target | 설명 |
|---|---|---|
| Stage | Station | 하나의 전투 노드 |
| Blind | Station Objective | 목표 점수 + 자원 상태 |
| scoreTowardBlind | scoreTowardStation | 해당 전투 목표에 누적한 점수 |
| board/hand discard | Station Resources | 전투 내 제한 자원 |
| stageStartSnapshot | Station Checkpoint | 현재 Station 시작점 복원 |
| cash-out | Station Reward Settlement | 클리어 후 보상 정산 |
| shop | Market Stop | Station 사이 보상/구매 구간 |

[MIGRATION]

용어 전환 순서:

1. 문서 alias 추가
2. UI 텍스트 일부를 Station으로 전환
3. 저장 DTO와 코드명은 유지
4. 테스트 강화
5. 별도 refactor PR에서 내부 코드명 변경 검토

## 3. Sector / Station Structure

[TARGET]

장기 run은 다음 구조를 가진다.

```text
Run
└─ Sector[]
   └─ Station[]
      ├─ Combat Objective
      ├─ Station Modifiers
      ├─ Reward Rules
      └─ Market/Rest/Choice 연결
```

V4에서는 station 개수와 sector 개수를 확정하지 않는다. V3의 30 Station은 후보 테이블로 보존할 수 있지만, V4 기본 구현 지시로 박지 않는다.

## 4. Station Modifier Contract

[TARGET]

Station modifier는 세 축으로 나눈다.

```text
Entry
- 전투 시작 전 조건 또는 비용

Pressure
- 전투 중 지속되는 압박

Lock
- 강한 제한 또는 해금 조건
```

예시:

- 시작 손패 제한
- Jester 슬롯 잠금
- 시작 board discard 감소
- target score 증가
- 특정 rank 점수 감소
- 확정 횟수 제한
- 특정 line 사용 불가
- Permit 필요 조건

[MIGRATION]

Entry / Pressure / Lock은 전투 엔진 내부에 직접 끼워 넣지 않는다.
`StationRuleModifier` 형태로 `RummiRulesetConfig` 또는 run meta layer에서 주입한다.

## 5. Risk Grade / Trial Contract

[TARGET]

Risk Grade는 run 시작 전 난이도 선택 계층이다.

가능한 조정 축:

- target score multiplier
- starting gold
- discard count
- shop price multiplier
- station modifier 등장률
- checkpoint 제한
- reward multiplier

Trial은 특별 규칙 run이다.

예시:

- 특정 Jester pool만 사용
- hand size 변경
- copiesPerTile 변경
- Station modifier 고정
- 특정 scoring rank 금지 또는 bonus

Risk Grade와 Trial은 active run core가 안정화된 후 추가한다.

## 6. Market Stop Contract

[TARGET]

Market은 Jester-only shop에서 multi-content market으로 확장한다.

Market 상품 후보:

- Jester
- Item
- Run Kit upgrade
- Permit
- Glyph
- Echo
- Sigil
- temporary consumable
- reroll / remove / upgrade service

내부 도메인 경계는 `Jester / Item / Permit / Glyph / Echo / Service`를 유지한다.
상점 UI 카테고리는 유저 이해를 위해 상위 그룹으로 다시 묶을 수 있다.

권장 UI 카테고리:

```text
Jester Shop
- Jester

Utility Shop
- Item
- Service

Meta Shop
- Permit
- Run Kit upgrade
- Sigil

Modifier / Pack
- Glyph
- Echo
```

[MIGRATION]

Market은 기존 `RummiRunProgress.shopOffers`를 깨지 않고 확장한다.

권장 순서:

1. 현재 Jester offer 유지
2. `MarketOffer` 추상 모델 추가
3. `JesterMarketOffer` adapter 추가
4. UI는 기존 shop card를 유지한 채 category badge만 추가
5. 이후 새 상품 타입 추가

## 7. Economy Policy

[V4_DECISION]

경제 확장은 `Jester 강화`와 `Item 도입`을 같은 축으로 취급하지 않는다.

- Jester economy는 `장착/판매/시너지 자산` 기준으로 본다.
- Item economy는 `구매/소모/장착/서비스` 기준으로 별도 본다.
- 장기 수치 조정은 Jester price curve와 Item price curve를 분리해서 잡는다.
- economy pass는 multi-content market 구조가 잡힌 뒤 진행한다.

[TARGET]

경제 수치는 다음 순서로 잡는다.

1. 현재 프로토타입 수치를 baseline으로 기록
2. stage/station 목표 곡선 테스트 작성
3. run length 목표 결정
4. reward/cost 비율 산정
5. Station modifier 난이도와 함께 재밸런싱

최종 경제 수치는 V4 문서에서 확정하지 않는다. V4는 구조와 migration 절차를 확정한다.
