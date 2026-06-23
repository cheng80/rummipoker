# Station Target Quick Brief

> 문서 성격: 개별 확인용 핵심 축약
> 최신 기준일: 2026-05-19
> 상세 기준: `docs/current_system/CURRENT_LEVELING_RUNTIME_SPEC.md`
> 변경 노트: `docs/archive/leveling/target_curve_history/STATION_TARGET_LOG_CURVE_2026_05_19.md`

## 한 줄 결론

현재 Station 목표 점수는 기존 성장 속도보다 너무 낮았기 때문에, S1~S8 표준 목표를 로그형으로 크게 올리고 `challenge` 난이도 배율도 `1.5`로 올렸다.

## 현재 적용값

| Station | Scout | Clash | Boss |
|---:|---:|---:|---:|
| S1 | 480 | 720 | 960 |
| S2 | 650 | 1000 | 1350 |
| S3 | 900 | 1400 | 1900 |
| S4 | 1250 | 2000 | 2750 |
| S5 | 1750 | 2850 | 3950 |
| S6 | 2450 | 4050 | 5650 |
| S7 | 3450 | 5750 | 8050 |
| S8 | 4850 | 8150 | 11400 |

난이도 배율:

| Difficulty | Multiplier |
|---|---:|
| standard | 1.0 |
| challenge | 1.5 |

예시:

- S8 Boss standard: `11400`
- S8 Boss challenge: `17100`
- S8 Boss challenge + high_stakes: `17784`

## 바꾼 이유

실제 플레이에서 S4 Scout가 `4535 / 580`처럼 목표를 약 7.8배 초과하는 상태가 확인됐다.

이 상태에서는 전투 목표가 성장한 run을 평가하지 못하고, 초과 점수 보너스와 골드 snowball도 너무 쉽게 커질 수 있다.

## 의도

- S1은 기존 Scout `240`의 2배인 `480`으로 올려 초반 입구를 유지한다.
- S4 이후부터는 성장 선택과 마켓 선택이 실제 압박을 느끼게 한다.
- Boss는 단순히 보상이 큰 전투가 아니라 성장 체크포인트로 둔다.
- `challenge x1.5`는 표준보다 조금 어려운 모드가 아니라 상위 도전 모드로 읽히게 한다.

## 아직 열린 검증

- S1~S8 standard/challenge fresh path clear rate
- S6~S8 Boss stop reason: board locked인지 deck exhausted인지
- `shop_slot_market_v9`가 none/control보다 실제로 도움이 되는지
- 초과 점수 보너스가 여전히 과한 골드 공급으로 남는지
- S8 Boss가 너무 막히면 target을 바로 낮추기보다 market 선택, boss severity, deck exhausted 원인을 함께 본다.

## 관련 코드

- Runtime target: `lib/services/blind_selection_spec.dart`
- Legacy fallback: `lib/logic/rummi_poker_grid/jester_meta.dart`
- Simulation target parity: `tools/sim/run_balance_sim.dart`
- Feature table target parity: `tools/leveling/build_feature_table.py`
