# Run and Economy

## Run Flow

한 Station은 `Scout → Clash → Boss` 순서의 세 Blind로 구성된다. 각 Blind를 클리어할 때마다 Settlement와 Market을 거치며, Boss 뒤에만 Station 번호가 증가한다.

| 현재 상태 | 진입 조건 | 처리 | 다음 상태 |
|---|---|---|---|
| New Run | `표준` 또는 `도전`, 해금된 run modifier와 seed 선택 | 새 run 자원과 S1 Blind 진행도를 만든다 | S1 Blind Select |
| Blind Select | 현재 Station에서 직전 tier가 클리어됨 | 다음 selectable tier의 목표·자원·Boss 제약과 덱을 준비한다 | Battle |
| Battle | 선택한 Blind 시작 | 타일 배치·확정으로 누적 점수가 목표 이상이면 클리어; 만료 신호를 보호 효과가 막지 못하면 game over | Settlement 또는 종료 처리 |
| Settlement | Blind 클리어 | 잔여 보드·손패를 정리하고 골드·족보 성장·Boss 보상을 한 번 계산해 적용한다 | Market; 단 S8 Boss는 종료 선택 |
| Market | Settlement 완료 또는 S8에서 무한 도전 선택 | Jester·Item·타일 후보를 구매·판매·리롤한다 | 같은 Station의 다음 Blind Select; Boss 뒤에는 다음 Station Blind Select |
| S8 Boss 종료 선택 | S8 Boss Settlement 완료 | `런 완료`는 completed 기록 후 active run을 지운다. `무한 도전 진입`은 completed 보상을 한 번 기록하고 Market을 계속한다 | Title 또는 Market → S9 |
| Endless | Station 9 이상 | Station 기본 목표가 직전 규칙에서 1.25배씩 증가하고 Scout/Clash/Boss가 1/1.5/2배를 사용한다 | 같은 loop를 제한 없이 반복 |
| Terminal | 만료 후 새 run/나가기, 자발적 종료, 또는 런 완료 | run 결과·수집·Insight를 기록하고 종료를 확정한 경로는 active run을 지운다 | New Run 또는 Title |

진행 상태 정규화는 [blind_selection_setup.dart](../../lib/services/blind_selection_setup.dart), 화면 전환은 [game_session_notifier_station_commands.dart](../../lib/providers/features/rummi_poker_grid/game_session_notifier_station_commands.dart)와 [game_view_stage_flow.dart](../../lib/views/game/game_view_stage_flow.dart)가 소유한다.

## Difficulty와 Run Modifier

| 선택 | 현재 노출 | 목표 점수 | Blind 자원 | 추가 규칙 |
|---|---|---|---|---|
| `standard` | 선택 가능 | 기준값 | ruleset 기준 | S8 완료 시 `challenge` 해금 |
| `challenge` | 선택 가능 | 기준값 ×1.5, 반올림 | 보드 버림 -1, 손패 버림 -1 | 저장된 challenge carryover snapshot이 이미 있으면 시작 상태에 적용 |
| `relaxed` | 일반 선택 불가 | 기준값 ×0.8, 반올림 | 보드 버림 +1, 손패 버림 +1 | 저장 호환용 ID이며 선택 요청은 `standard`로 정규화 |

`basic` modifier는 목표·보상 1배다. `high_stakes`는 해금에 Insight 20을 사용하고 목표 ×1.04, 기본 Blind 보상 ×1.12를 각각 반올림한다. 난이도와 modifier 배율은 차례로 적용된다. 현재 선택 가능 여부와 배율의 권위는 [new_run_setup.dart](../../lib/services/new_run_setup.dart), tier별 목표·자원은 [blind_selection_spec.dart](../../lib/services/blind_selection_spec.dart)다.

## Current Economy Constants

| 계약 | 현재 값 | 적용 |
|---|---:|---|
| 새 run 시작 골드 | 0 | 모든 선택 난이도 |
| Blind 기본 클리어 골드 | 4 | run modifier 보상 배율을 곱해 반올림 |
| 첫 Blind 클리어 보너스 | 2 | S1 Scout Settlement 한 번 |
| 남은 보드 버림 | 1회당 2골드 | Settlement |
| 남은 손패 버림 | 1회당 1골드 | Settlement |
| 남은 보드 이동 | 1회당 1골드 | Settlement |
| Market 가격 배율 | `11 / 5` | 양수 base price에 곱해 반올림 |
| Market 기본 리롤 비용 | 5골드 | lane별 첫 raw cost |
| 리롤 비용 증가 | 사용마다 +2골드 | 사용한 lane에만 누적 |
| S1 Scout 첫 Market 리롤 할인 | 5골드 | 모든 lane 중 처음 사용한 리롤 한 번; 따라서 기본 비용이면 0골드 |
| 기본 후보 수 | 3 | Jester와 기본 Item offer 계약; 효과로 Item/Jester 후보가 늘 수 있음 |

상수와 가격 계산은 [jester_catalog_models.dart](../../lib/logic/rummi_poker_grid/jester_catalog_models.dart)의 `RummiEconomyConfig`, 적용은 [jester_run_progress.dart](../../lib/logic/rummi_poker_grid/jester_run_progress.dart)가 소유한다.

## Source, Sink, Cap, Reset

| 자원·상태 | Source | Sink/소비 | Cap 또는 하한 | Reset·지속 범위 |
|---|---|---|---|---|
| 골드 | Settlement 기본·잔여 행동·초과 달성 보상, Jester/Item 경제 효과, 점수 타일 효과, 판매 | 구매, lane 리롤 | 명시적 상한 없음; 구매·리롤은 잔액 부족 시 거부되어 0 미만이 되지 않음 | 새 run 0; 같은 run 전체에서 지속 |
| Insight | run 종료 시 `도달 Station + Boss 격파 수×2 + completed 12` | `high_stakes` 해금 20 | 명시적 상한 없음; 양수만 적립 | run 밖에 영구 저장 |
| Blind 점수 | 확정한 line들의 최종 점수 | 목표 달성 판정 | 명시적 상한 없음 | Blind마다 0 |
| 보드 버림 | 난이도·tier 초기값, Item 효과 | 보드 타일 버림 1회당 1 | Item 증가 지원 상한 6, 0 하한 | Blind마다 다시 계산 |
| 손패 버림 | 난이도·tier 초기값, Item 효과 | 손패 타일 버림 1회당 1 | Item 증가 지원 상한 4, 0 하한 | Blind마다 다시 계산 |
| 보드 이동 | ruleset 초기값 3, Item 효과 | 유효한 보드 이동 1회당 1 | Item 증가 지원 상한 5, 0 하한 | Blind마다 3으로 복원 후 Station-start 효과 적용 |
| 최대 손패 | 난이도·tier 초기값, Item 효과 | 직접 소비 없음 | Item 증가 지원 상한 5, 최소 1 | Blind마다 tier값으로 복원 후 효과 적용 |
| 리롤 비용 | Market 진입 시 lane별 5 | 성공한 리롤 뒤 해당 lane +2 | 할인 후 유효 비용 최소 0 | Market마다 모든 lane 5로 reset |
| Jester 슬롯 | 기본 4, S6 Boss 보상 +1 | Jester 보유; 판매 시 점유 해제 | 최대 5 | 같은 run에서 지속, 새 run reset |
| Quick 슬롯 | 기본 2, S2 Boss 보상 +1 | Quick Item 보유 | 최대 3 | 같은 run에서 지속, 새 run reset |
| Passive 슬롯 | 기본 1, S4 Boss 보상 +1 | Passive Item 보유 | 최대 2 | 같은 run에서 지속, 새 run reset |
| Item stack | 구매·효과 획득 | 사용·판매 | Item별 `stackable`·`maxStack`; Quick/Passive는 위 슬롯 cap도 적용 | 같은 run에서 지속, 새 run reset |
| 추가 덱 타일 | Boss 클리어 보상, 구매·복사·생성 효과 | 파괴·제거 효과 | 명시적 총량 cap 없음; 물리 ID로 구분 | 같은 run의 다음 Blind 덱에 포함; 새 run reset |
| 족보 성장 | 점수 족보 확정, 성장 Item·타일, 초과 달성 보너스 | 소비 없음 | 레벨 cap 없음; dead line은 성장하지 않음 | 같은 run에서 지속; 새 run reset |

전투 자원 cap은 [item_effect_runtime.dart](../../lib/logic/rummi_poker_grid/item_effect_runtime.dart), 슬롯 cap과 Boss 해금은 [jester_run_progress.dart](../../lib/logic/rummi_poker_grid/jester_run_progress.dart), run 밖 Insight는 [run_progression_service.dart](../../lib/services/run_progression_service.dart)와 [run_unlock_state_service.dart](../../lib/services/run_unlock_state_service.dart)가 소유한다.

## Settlement와 초과 달성

Settlement 총 골드는 다음 항의 합이다.

```text
round(4 × runModifier.rewardMultiplier)
+ S1 Scout 보너스 2
+ 남은 보드 버림 × 2
+ 남은 손패 버림 × 1
+ 남은 보드 이동 × 1
+ Jester 정산 골드
+ Item 정산 골드
+ 초과 달성 골드
```

일반 Blind는 목표의 130%, Boss는 120% 이상을 달성하면 해당 Blind에서 가장 기여한 성장 가능 족보에 progress +1을 한 번 지급한다. 이 보너스가 지급된 경우 기준 초과분 50%p마다 1골드를 정수 나눗셈으로 더하며 별도 cap은 없다. 확정 중 발생한 타일 골드는 즉시 run 골드에 더해지고 Settlement 식과 중복 계산하지 않는다.

Boss 클리어는 무작위 추가 덱 타일 하나를 지급하고 S2/S4/S6의 슬롯 보상을 판정한다. 이 계약은 [jester_run_progress.dart](../../lib/logic/rummi_poker_grid/jester_run_progress.dart)와 [rummi_overkill_growth_test.dart](../../test/logic/rummi_overkill_growth_test.dart)가 보호한다.

## Market 거래 계약

- 구매 가격은 먼저 `round(basePrice × 11 / 5)`로 만든다. 성장 접근 Jester/Item은 희귀도별 5/7/8/14골드 cap을 적용한 뒤, 다음 구매·category·최저가 후보 할인을 빼고 최소 0으로 만든다.
- Jester, 타일, Quick, Passive, Tool, Gear 리롤은 각각 비용을 가진다. 성공한 lane만 +2가 되고, 다음 Market에서 모두 5로 돌아간다.
- Jester 구매는 골드와 슬롯이 모두 충분할 때만 성공하며 해당 후보를 제거한다. Item 구매는 골드, placement cap, stack cap을 모두 만족해야 한다. 구매한 빈자리는 같은 Market에서 자동 보충하지 않는다.
- Item 판매는 catalog의 `sellPrice`를 0 이상으로 적용하고 한 stack을 제거한다. Jester 판매가는 `max(1, baseCost ~/ 2)`이며 보유 Item의 판매 보너스를 더할 수 있다.
- Market offer는 Station 구간, 희귀도, 성장축 결손, run modifier 압력에 따른 가중치로 뽑는다. 후보 선택은 보상이나 자동 지급이 아니며 구매는 항상 플레이어 행동이다.

거래 precondition과 가격은 [jester_run_progress.dart](../../lib/logic/rummi_poker_grid/jester_run_progress.dart), Item 후보 구성은 [rummi_market_facade_builders.dart](../../lib/logic/rummi_poker_grid/rummi_market_facade_builders.dart)가 소유한다.

## Leveling Invariants

- `High Card`와 `One Pair`는 dead line이며 레벨 0, 성장 보너스 0이다. 나머지 족보는 레벨 1에서 시작한다.
- 성장 progress 요구량은 현재 모든 성장 가능 족보에서 레벨당 1이다. 완성 또는 progress +1은 곧 레벨 +1이며 초과 progress는 반복 적용된다.
- 점수 보너스는 `(level - 1) × 족보별 growthStep`이고 현재 확정은 성장 적용 전 상태로 점수를 계산한 뒤 완료 기록을 올린다. 즉 이번 완성으로 오른 레벨은 다음 완성부터 점수에 반영된다.
- 일반 점수 족보와 숨은 고급 족보 모두 성장 가능하며 step은 [rummi_hand_growth.dart](../../lib/logic/rummi_poker_grid/rummi_hand_growth.dart)가 단일 권위다.
- 성장, 완성 횟수, 추가 덱 타일은 active run에 저장되고 그 run의 다음 Blind에서 유지된다. 새 run은 이를 reset한다. Challenge setup에는 저장된 carryover snapshot을 읽는 호환 경계가 있지만 현재 game completion summary는 새 snapshot을 채우지 않으므로 이를 일반적인 새 run 계승 규칙으로 보지 않는다. Jester·Item·골드는 carryover 대상이 아니다.

## Source와 Test Anchors

- run 선택·난이도·modifier: [new_run_setup.dart](../../lib/services/new_run_setup.dart), [blind_selection_setup_test.dart](../../test/services/blind_selection_setup_test.dart)
- Station/Blind 목표와 endless: [blind_selection_spec.dart](../../lib/services/blind_selection_spec.dart), [blind_selection_setup_test.dart](../../test/services/blind_selection_setup_test.dart)
- Settlement·Market·성장·슬롯: [jester_run_progress.dart](../../lib/logic/rummi_poker_grid/jester_run_progress.dart), [rummi_session_test.dart](../../test/logic/rummi_session_test.dart), [rummi_hand_growth_test.dart](../../test/logic/rummi_hand_growth_test.dart)
- run loop phase: [game_session_notifier_station_commands.dart](../../lib/providers/features/rummi_poker_grid/game_session_notifier_station_commands.dart), [game_session_notifier_test.dart](../../test/providers/game_session_notifier_test.dart)
- terminal·Insight·해금: [game_view_run_end_flow.dart](../../lib/views/game/game_view_run_end_flow.dart), [run_progression_service_test.dart](../../test/services/run_progression_service_test.dart), [run_unlock_state_service_test.dart](../../test/services/run_unlock_state_service_test.dart)

## Source와 Update Trigger

코드와 보호 테스트가 이 문서보다 우선한다. 다음이 바뀌면 같은 변경에서 이 문서를 갱신한다.

- New Run 선택 가능 난이도, modifier 배율·해금 비용
- Station/Blind 전환, S8 terminal 또는 endless 분기
- `RummiEconomyConfig`, 가격·판매·리롤 계산
- 골드·Insight source/sink, 전투 자원·slot cap과 reset 시점
- 족보 growth step, progress 요구량, challenge 계승 범위
