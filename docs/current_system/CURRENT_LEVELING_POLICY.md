# Current Leveling Policy

> 문서 성격: current policy / leveling source of truth
> 적용 범위: target score, boss constraint, market candidate availability, market weight, simulation interpretation
> 우선순위: 실제 코드와 테스트 다음으로 이 문서를 우선한다. 과거 planning/archive 문서가 이 문서와 충돌하면 이 문서를 따른다.
> 시뮬레이션 기준값: `docs/current_system/CURRENT_LEVELING_SIMULATION_BASELINE.md`
> 런타임 기준표: `docs/current_system/CURRENT_LEVELING_RUNTIME_SPEC.md`

## 1. 핵심 원칙

- 레벨링은 특정 성장 루트를 유저에게 강제하거나 보장하지 않는다.
- 게임은 유저의 구매, 판매, 장착, 사용 선택을 대신하지 않는다.
- 시스템의 역할은 어떤 선택을 하더라도 게임이 무너지지 않도록 난이도와 시장 구조를 받치는 것이다.
- 실제 적용 가능한 레버는 `target score`, `boss constraint`, `market candidate availability`, `rarity/tag/category/slot weight`, 병목 허용치다.

## 2. 절대 금지

- S1 첫 클리어 보너스 골드 외에는 공짜 지급이 없다.
- 아이템, Jester, Pack, Tarot-like, Planet-like, 덱 타일을 직접 지급하지 않는다.
- board discard, hand discard, max hand size, slot, hand size 같은 자원을 자동 보정하거나 숨은 기본값으로 올리지 않는다.
- 특정 성장축을 못 얻었다는 이유로 게임이 구매, 장착, 사용을 대신하지 않는다.
- 마켓 보정이 특정 offer slot 위치를 고정하지 않는다.

## 3. 허용되는 보정

- 특정 구간에서 필요한 성장 후보가 상점에 등장할 가능성을 올릴 수 있다.
- 보정은 candidate availability, category/tag/rarity/slot weight, 가격 검토, reroll/seed 기반 노출 확률로만 한다.
- 후보가 등장해도 구매 여부, 기존 보유물 판매 여부, 슬롯 정리는 유저 선택이다.
- Rare/Legendary 후보는 초반에도 확률 0으로 막지 않는다.

## 4. 시뮬레이션 해석

- bot 선택은 유저 선택 성향을 재현하는 proxy일 뿐이다.
- bot이 특정 아이템을 샀다는 결과는 “게임이 지급해야 한다”가 아니라 “그 후보가 유효한 구매 선택지일 수 있다”로만 해석한다.
- `resource`, `sustain`, `voucher_resource` 같은 과거 sim 이름은 자동 자원 지급 의미가 아니다.
- 자동 resource +1이 포함된 과거 experiment는 실제 기준 후보가 아니라 폐기/비교용 이력이다.
- 빠른 probe는 탐색용이다. 실제 기준값 재검증은 기존 장기 sweep 맥락의 station curve, small/big/boss tier, difficulty, loadout, market profile을 함께 본다.

## 5. 현재 S8 후반 판단

- v84~v86 smoke 기준에서 `shop_slot_market_v9`는 점수 전환 후보를 충분히 노출한다.
- 잔여 S8 boss 실패는 주로 deck exhausted 쪽이며, 즉시 target 하향이나 자동 자원 지급으로 풀지 않는다.
- 다음 검토 후보는 S7~S8 boss 구간에서 덱/타일 형상 보정 후보가 마켓 후보군에 안정적으로 포함되는지 확인하는 것이다.
- 후보는 마켓에만 뜬다. 구매, 판매, 슬롯 정리는 유저 선택이다.

## 6. 전체 수집 가능성 보정

- 전체 수집 보정은 특정 성장축 부족 보정과 별개다.
- 현재 허용된 보정은 “아직 구매하지 않은 후보 +45”, “아직 마켓에서 보지 못한 후보 +90”처럼 Jester/Item 개별 후보의 등장 가중치만 올리는 방식이다.
- 이미 한 번 구매한 뒤 판매한 Jester/Item은 `bought*Ids` 기록에 남는다. 다시 등장할 수는 있지만 “미수집 후보” 보정은 받지 않는다.
- 이 보정은 직접 지급, 자동 구매, 특정 슬롯 고정, 카탈로그 제거가 아니다.
- 수집 audit는 `tools/sim/runtime_market_offer_audit.dart`의 누적 collection path로 본다. 핵심 지표는 `seen coverage`, `bought coverage`, `gold blocked`, `capacity blocked`, `unseen/unbought ids`다.
- 한 run에서 모든 후보를 동시에 보유해야 한다는 뜻은 아니다. 마켓을 반복 통과하는 여러 fresh path에서 전체 catalog가 실제로 보이고 살 수 있는지를 본다.

## 7. 과거 자료 사용법

- 긴 실험 로그와 이전 후보는 `docs/archive/leveling/`에서 검색한다.
- archive 문서는 현재 기준이 아니다. 필요한 내용은 이 문서나 current/spec 문서로 승격한 뒤 사용한다.
- 과거 문서의 `resource +1`, `soft_resource`, `sustain` 표현은 당시 실험 이름으로 보고 현재 정책으로 해석하지 않는다.

## 8. 과거 데이터 재사용 기준

- 과거 시뮬레이션 row와 리포트는 `historical prior`로만 사용한다.
- 현재 clear rate, 카드 가치, 마켓 구매력, S1~S8 통과율, ML 추천 결론은 현재 runtime/catalog/ruleset/bot policy로 fresh resimulation을 다시 돌린 뒤에만 판단한다.
- UI 변경만으로 CLI 레벨링 데이터가 무효가 되지는 않지만, 룰, 카드, 경제, 마켓, 정산, 저장 상태, bot policy가 바뀌면 데이터 분포가 바뀐 것으로 본다.
- 과거 row를 분석 테이블에 섞을 때는 `balance_version`, `ruleset_id`, `catalog_versions`, `experiment_id`, `market_profile`, `bot_policy`를 feature 또는 grouping key로 보존한다.
- 현재 추천 근거로 쓰는 데이터셋에는 최신 runtime 기준 fresh row를 우선하고, 과거 row는 낮은 신뢰도의 방향성 참고 또는 비교 이력으로만 둔다.
