# Balatro-Style Scoring Feedback Plan

> GCSE role: `Execution`
> Purpose: Jester/Item 중심 점수 발동 UI를 Balatro식 빌드 엔진 피드백으로 정리한다.

## 1. Review Conclusion

현재 전투 화면에서 Jester와 Item이 큰 비중을 차지하는 방향은 유지한다.

이 게임에서 Jester/Item은 일반 RPG 인벤토리가 아니라, Balatro의 Joker처럼 매 확정 점수 계산에 직접 개입하는 빌드 엔진이다. 따라서 접거나 숨기는 것이 아니라, 항상 보이되 점수 환산 순간에 어떤 카드와 아이템이 왜 발동했는지 명확히 보여줘야 한다.

핵심 문제는 공간 점유가 아니라 발동 인과관계의 가시성이다.

- Jester/Item은 보드 위 엔진으로 계속 노출한다.
- 확정 전에는 어떤 족보/라인/효과가 준비됐는지 preview한다.
- 확정 후에는 보드 라인, 족보 점수, overlap, Jester, Item, 최종 점수 이동을 순차적으로 보여준다.
- Item도 Jester와 같은 수준의 active effect 표시를 가져야 한다.

## 2. Evidence

2026-04-30 iPhone 17 simulator smoke:

```bash
tools/ios_sim_smoke.sh --device-id 4ED48B1D-BD2A-45F1-91F7-47EC4CE9D083 --route "/game?fixture=inventory_quick_slot_battle" --output-dir /tmp/rummipoker_ui_review/live_20260430_battle_slots --settle 8 --timeout 180
tools/ios_sim_smoke.sh --device-id 4ED48B1D-BD2A-45F1-91F7-47EC4CE9D083 --route "/game?fixture=stage2_market_resume" --output-dir /tmp/rummipoker_ui_review/live_20260430_market_resume --settle 8 --timeout 180
tools/ios_sim_smoke.sh --device-id 4ED48B1D-BD2A-45F1-91F7-47EC4CE9D083 --route "/game?fixture=stage2_scoring_snapshot&auto_cashout_loop=1&auto_enter_market=1&auto_advance_market=1" --output-dir /tmp/rummipoker_ui_review/live_20260430_auto_loop --settle 8 --timeout 180
```

Artifacts:

- `/tmp/rummipoker_ui_review/live_20260430_battle_slots/01_launch.png`
- `/tmp/rummipoker_ui_review/live_20260430_market_resume/01_launch.png`
- `/tmp/rummipoker_ui_review/live_20260430_auto_loop/01_launch.png`

Observed:

- Battle 화면은 Jester strip, Item slot zone, board, action rail, hand zone이 한 화면에 들어온다.
- Jester/Item은 의도대로 보드 위에 큰 빌드 영역으로 노출된다.
- Market 화면은 Jester/Slots와 Tool/Gear 탭, 보유 슬롯, offer lane, 상세 패널, reroll/next station CTA가 표시된다.
- Auto loop는 다음 Station 선택까지 도달한다.

## 3. Current Code Basis

현재 scoring runtime은 UI 개선에 필요한 정보를 이미 상당 부분 만든다.

- `lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart`
  - Jester는 장착 슬롯 순서대로 line score에 적용된다.
  - Confirm modifier Item도 line score에 적용되고 `effects`에 합산된다.
  - `ConfirmedLineBreakdown.effects`는 Jester/Item 발동 UI의 공통 입력 후보가 될 수 있다.
- `lib/views/game/widgets/game_jester_widgets.dart`
  - `GameJesterStrip`은 `activeEffects`를 `jesterId`로 매핑해 Jester 카드 burst를 보여준다.
- `lib/views/game/widgets/game_shared_widgets.dart`
  - `GameItemZoneSkeleton`은 Item slot을 표시하지만 active effect 입력을 받지 않는다.
- `lib/views/game_view.dart`
  - `_runSettlementSequence`가 line별 settlement 타이밍을 관리한다.

핵심 gap:

- Item confirm modifier가 점수에 반영되어도 battle item slot에서 직접 발동 표시되지 않는다.
- 확정 전 preview가 없어 플레이어가 어떤 engine이 준비됐는지 미리 읽기 어렵다.
- 확정 후 점수 계산 연출이 “보드 line -> 족보 -> overlap -> Jester -> Item -> 최종 점수” 순서로 분해되어 보이지 않는다.

## 4. Design Principles

1. Jester/Item은 접지 않는다.
2. 빈 슬롯과 잠금 슬롯은 조용하게, 장착 카드와 발동 카드는 강하게 보인다.
3. 점수형 효과는 반드시 원인 카드/아이템 위에서 먼저 빛난다.
4. 최종 점수는 Station Goal 게이지로 이동하거나 게이지 pulse로 연결된다.
5. Snackbar만으로 효과 발동을 설명하지 않는다.
6. UI polish는 combat rule, economy, save schema 변경과 섞지 않는다.

## 5. Implementation Checklist

### P0. Scoring Preview

- [x] `RummiBattleRuntimeFacade` 또는 별도 read model에서 현재 확정 가능 line preview를 제공한다.
- [x] Preview에는 line count, 대표 족보명, base score, overlap bonus, expected Jester/Item effect count를 포함한다.
- [x] Battle action area 근처에 compact preview chip을 표시한다.
- [x] 확정할 줄이 없을 때는 `확정 하기` CTA를 낮은 대비로 두고 reason text를 짧게 표시한다.

### P0. Item Active Effect Display

- [x] `GameItemZoneSkeleton`에 active item effects 입력을 추가한다.
- [x] `RummiJesterEffectBreakdown`을 그대로 쓸지, `ScoringEffectBreakdown` 같은 중립 타입으로 분리할지 결정한다.
  - 현재는 save/schema 변경 없이 `ConfirmedLineBreakdown.effects`와 `RummiJesterEffectBreakdown`을 공통 scoring effect 입력으로 재사용한다.
- [x] Q/P/T/G slot이 발동하면 Jester와 같은 수준의 border pulse, badge, float token을 표시한다.
- [x] Item effect badge는 `+Chips`, `+Mult`, `xMult`, `+Score`, `overlap` 계열을 구분한다.
  - 현재 표시 타입: `+Chips`, `+Mult`, `xMult`, `+Score`. `temporary_overlap_cap_bonus`는 scoring modifier 결과 기준 `xMult` 계열로 표시한다.
- [x] 수동 사용 Item feedback과 passive/confirm score Item feedback을 시각적으로 구분한다.
  - 수동 사용은 기존 item feedback toast, confirm/passive scoring은 item slot 위치의 pulse/badge/float로 분리한다.

### P0. Sequential Scoring Presentation

- [x] `_runSettlementSequence`를 line 단위뿐 아니라 effect step 단위로 표현할 수 있게 확장한다.
- [x] Step order를 고정한다: board line -> hand rank/base -> overlap -> Jester slot order -> Item slot order -> final score.
- [x] Jester는 현재 장착 슬롯 순서와 동일하게 pulse한다.
- [x] Item은 slot label 순서 또는 실제 modifier 적용 순서를 따른다.
  - 현재는 `ConfirmedLineBreakdown.effects`의 실제 적용 순서를 따르고, 해당 item id가 있는 Q/P/T/G slot 위치에서 표시한다.
- [x] 최종 점수 적용 시 Station Goal 숫자와 progress bar가 pulse한다.

Implementation notes:

- 2026-04-30 적용 완료.
- scoring transaction은 정산 버튼 직후 계산/커밋/저장되고, animation은 저장된 결과를 재생하는 presentation으로 동작한다.
- 중앙 floating text는 최종 점수 합산에만 사용하고, board/rank/overlap은 board 위 callout, Jester/Item 점수는 각 slot 위치 burst로 표시한다.
- iOS smoke 재실행 완료. 현재 검증은 `flutter analyze`, 관련 widget/provider/save tests, required iOS smoke 3 routes 기준이다.

### P1. Battle Slot Visual Hierarchy

- [ ] 빈 Jester slot과 잠금 slot의 대비를 낮춘다.
- [ ] 장착된 Jester/Item의 카드 face 대비를 유지하거나 강화한다.
- [ ] 발동 가능한 카드와 발동 불가능한 카드를 상태로 구분한다.
- [ ] 선택 상태와 발동 상태가 충돌하지 않게 selection frame과 scoring pulse layer를 분리한다.

### P1. Market Build Readability

- [ ] Offer 카드에 현재 빌드와의 시너지 태그를 추가한다.
- [ ] 예: `Straight 강화`, `discard 기반`, `face card 조건`, `첫 확정`, `overlap`.
- [ ] 보유 슬롯/오퍼/상세 패널 사이 selection 연결을 더 강하게 표시한다.
- [ ] 구매 불가 상태는 가격만 비활성화하지 말고 이유를 짧게 표시한다.

### P2. Station Reward/Risk Framing

- [ ] Blind Select의 Small/Big/Boss 카드를 risk/reward 선택으로 더 강하게 표현한다.
- [ ] 현재 빌드 기준 추천/위험 hint를 넣을 수 있는 read model 여지를 둔다.
- [ ] Next Station transition은 완료감 후 선택 화면으로 넘어가게 짧은 affordance를 추가한다.

## 6. Acceptance Criteria

- 전투 화면에서 Jester/Item은 항상 visible build engine으로 남는다.
- 확정 전 플레이어가 이번 확정 예상 점수와 발동 가능 효과 수를 알 수 있다.
- 확정 후 발동한 Jester와 Item이 각각 자기 카드/슬롯 위치에서 pulse한다.
- Item으로 인해 점수가 증가한 경우, 증가 원인이 Item slot에서 직접 보인다.
- Station Goal 증가가 최종 점수 적용과 시각적으로 연결된다.
- iOS smoke에서 battle, market, auto loop route가 overflow 없이 통과한다.

Required smoke routes:

```bash
tools/ios_sim_smoke.sh --route "/game?fixture=inventory_quick_slot_battle" --settle 8
tools/ios_sim_smoke.sh --route "/game?fixture=stage2_market_resume" --settle 8
tools/ios_sim_smoke.sh --route "/game?fixture=stage2_scoring_snapshot&auto_cashout_loop=1&auto_enter_market=1&auto_advance_market=1" --settle 8
```

Recommended tests:

- `flutter analyze`
- `flutter test test/views/game/widgets/game_station_read_path_test.dart`
- `flutter test test/providers/game_session_notifier_test.dart`
- `flutter test test/logic/jester_effect_runtime_test.dart test/logic/item_effect_runtime_test.dart`

## 7. Not In Scope

- One Pair scoring 변경
- Jester id 변경
- save schema 변경
- Station/Blind 코드 symbol rename
- economy 수치 변경
- Jester/Item 영역 접기 또는 인벤토리식 숨김 처리
