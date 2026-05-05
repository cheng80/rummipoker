# Heuristic Leveling Simulation Direction

> 문서 성격: current leveling entry / active summary
> 명칭 주의: 이 문서는 파일명에 `ML`이 남아 있지만, 현재 내용은 학습 모델을 적용한 머신러닝 기준이 아니다.
> 현재 단계는 Flutter CLI 시뮬레이션, bot proxy, 규칙 기반 진단 라벨, 사람이 승인하는 레벨링 적용 절차다.
> 실제 머신러닝 전환 전까지 이 문서를 “AI가 학습해 밸런스를 자동 조정한다”는 근거로 사용하지 않는다.
> 현재 기준: `docs/current_system/CURRENT_LEVELING_POLICY.md`
> 시뮬레이션/휴리스틱 기준: `docs/current_system/CURRENT_LEVELING_SIMULATION_BASELINE.md`
> 런타임 기준표: `docs/current_system/CURRENT_LEVELING_RUNTIME_SPEC.md`
> 적용 상태: `docs/planning/LEVELING_APPLIED_STATUS.md`
> 긴 실험 이력: `docs/archive/leveling/ML_LEVELING_SIMULATION_DIRECTION_HISTORY.md`

## 용어 정정

- 이 문서와 일부 기존 파일명/도구명의 `ML`은 역사적 이름이다.
- 현재까지 실제 적용된 것은 supervised model, train/test split, validation metric이 있는 학습 모델이 아니다.
- 현재 파이프라인은 “시뮬레이션 기반 레벨링 분석”과 “규칙 기반 휴리스틱 라벨링”이다.
- `analysis/leveling/`의 현재 feature table과 RandomForest 리포트는 실제 ML 전환 완료가 아니라, 전환을 준비하기 위한 스캐폴딩과 설명 baseline이다.
- 향후 실제 ML 전환 시에는 기존 시뮬레이션 결과를 feature table로 정리하고, 휴리스틱 라벨은 초기 `silver label`로만 사용한다.
- 모델 추천은 런타임 자동 적용이 아니라 후보 추천, 재시뮬레이션 검증, 사람 승인 후 적용 순서로 다룬다.

## 현재 확정 정책 요약

- 레벨링은 특정 성장 루트를 유저에게 강제하거나 보장하지 않는다.
- S1 첫 클리어 보너스 골드 외에는 유저에게 공짜 지급이 없다.
- 아이템, Jester, Pack, Tarot-like, Planet-like, 덱 타일, board discard, hand discard, max hand size, slot은 자동 지급하지 않는다.
- 레벨링이 조정할 수 있는 것은 `target score`, `boss constraint`, `market candidate availability`, `rarity/tag/category/slot weight`, 병목 허용치다.
- 특정 구간까지 필요한 성장축을 얻지 못했더라도 직접 지급하지 않는다. 허용되는 보정은 마켓 등장 확률과 슬롯 노출 확률 조정뿐이다.
- 후보가 마켓에 등장해도 구매, 판매, 장착, 사용은 유저 선택이다.
- 마켓 보정은 특정 offer slot 위치를 고정하지 않는다. 후보 위치는 stage/reroll/rng에 따라 흔들려야 한다.
- Rare/Legendary는 초반에도 확률 0으로 막지 않는다.

## 과거 실험 해석 주의사항

- `docs/archive/leveling/ML_LEVELING_SIMULATION_DIRECTION_HISTORY.md`는 과거 실험 로그이며 현재 정책 기준이 아니다.
- 과거 문서의 `resource`, `sustain`, `voucher_resource`, `resource +1`, `soft_resource` 표현은 당시 sim proxy 이름으로만 본다.
- 자동 resource +1이 포함된 과거 experiment는 실제 적용 후보가 아니라 폐기/비교용 이력이다.
- bot 선택은 유저 선택 성향 proxy다. bot이 구매한 결과를 게임이 지급해야 한다는 뜻으로 해석하지 않는다.
- archive 내용을 실제 적용 후보로 되살리려면 먼저 `CURRENT_LEVELING_POLICY.md`에 맞게 요약/승격한 뒤 검토한다.

## 현재 분석 판단

- v84~v86 smoke 기준에서 `shop_slot_market_v9`는 점수 전환 후보를 충분히 노출한다.
- 잔여 S8 boss 실패는 주로 deck exhausted 쪽이며, 즉시 target 하향이나 자동 자원 지급으로 풀지 않는다.
- 다음 검토 후보는 S7~S8 boss 구간에서 덱/타일 형상 보정 후보가 마켓 후보군에 안정적으로 포함되는지 확인하는 것이다.
- 이 후보도 직접 지급이 아니라 market-only availability/weight 조정으로만 본다.

## 다음 작업 기준

1. 실제 적용 전 `CURRENT_LEVELING_POLICY.md`를 먼저 확인한다.
2. 기존 장기 sweep 맥락을 볼 때만 archive history를 검색한다.
3. 조정 후보를 적을 때마다 “직접 지급인가, 마켓 노출인가?”를 먼저 판정한다.
4. 직접 지급으로 읽히는 후보는 폐기하거나 market-only 후보로 다시 번역한다.
