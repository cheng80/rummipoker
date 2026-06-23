# Station Target Log Curve 2026-05-19

> 문서 성격: post-contest 레벨링 변경 노트
> 상태: runtime applied, fresh sweep open
> 코드 기준: `lib/services/blind_selection_spec.dart`
> 기준 문서: `docs/current_system/CURRENT_LEVELING_RUNTIME_SPEC.md`

## 결론 요약

S1~S8의 표준 목표 점수를 로그형 상향 표로 교체했다.

확인된 문제는 S4 Scout에서 `4535 / 580`처럼 성장한 run이 목표를 약 7.8배 초과해, Station 목표가 현재 족보 성장/Jester/초과 보상 속도를 따라가지 못하는 상태였다.

이번 변경은 target score 런타임 반영이다. 장기 clear rate, S6~S8 Boss 체감, 초과 점수 보너스에 따른 골드 snowball은 아직 fresh sweep으로 닫지 않았으므로 open risk다.

## 적용 표

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

## 설계 의도

- S1 Scout는 기존 `240`의 2배인 `480`으로 올려 초반 입구를 너무 갑자기 막지 않는다.
- S1~S8은 로그형 상승 체감을 갖게 해 후반으로 갈수록 성장 선택이 더 중요해지게 한다.
- 같은 station 안에서는 `Scout < Clash < Boss` 압박을 명확히 두고, Boss를 실제 성장 체크포인트로 둔다.
- S4 Scout `4535` 사례는 새 S4 Scout `1250`도 넘지만, 새 S4 Boss `2750`부터는 성장/빌드 품질을 더 요구한다.
- S8 Boss `11400`은 현재 성장 시스템이 후반에도 목표를 쉽게 압도하지 않게 만드는 1차 상한이다.

## 이번 변경 범위

- 런타임 target table: `BlindSelectionSpecBuilder._standardTargetScore`
- 레거시 next-stage fallback Scout target: `RummiRunProgress.targetForStage`
- 현재 runtime station pool 시뮬 profile의 target source: `tools/sim/run_balance_sim.dart`
- 분석/추천 도구의 pre-outcome target 복제 표: `tools/leveling/build_feature_table.py`, `tools/leveling/recommend_leveling_candidates.py`
- 고정 테스트 기대값: `test/services/blind_selection_setup_test.dart`, `test/providers/game_session_notifier_test.dart`, `test/tools/sim/balance_sim_test.dart`
- 기준 문서: `docs/current_system/CURRENT_LEVELING_RUNTIME_SPEC.md`, `docs/planning/leveling/LEVELING_APPLIED_STATUS.md`

## 아직 닫지 않은 검증

- S1~S8 standard/challenge full path fresh simulation
- `challenge` multiplier `1.5` 기준 S1~S8 Boss 도달률과 S8 Boss stop reason
- S4~S8 Boss 도달 전투별 실패율
- `shop_slot_market_v9`가 none/control 대비 더 나빠지는지 여부
- 초과 점수 보너스가 target 상향 후에도 과한 골드 공급으로 남는지 여부
- 무성장/약성장 run이 S2~S3 이후 자연스럽게 막히는지 여부

## 다음 액션

1. target 출력과 관련 단위 테스트를 먼저 통과시킨다.
2. 짧은 r80/r120 smoke로 S1~S8 station path의 stop reason을 확인한다.
3. S4~S8에서 여전히 과도한 초과 달성이 반복되면 target을 더 올리기 전에 초과 점수 보너스와 골드 공급을 분리해 본다.
4. S8 Boss가 지나치게 막히면 target 하향보다 먼저 마켓 성장 선택, boss severity, deck exhausted 원인을 같이 본다.
