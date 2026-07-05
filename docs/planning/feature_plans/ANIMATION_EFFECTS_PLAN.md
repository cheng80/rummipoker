# Animation Effects Plan

이 문서는 전투/마켓 연출을 늘릴 때 참고할 적용 목록과 최적화 기준이다.
연출은 모두 transient presentation state이며, save/continue와 simulator 결과의
source of truth는 runtime state다.

모션 감각과 레퍼런스 게임별 연출 언어는
[RUMMI_POKER_REFERENCE_GAME_MOTION_STYLE_GUIDE.md](RUMMI_POKER_REFERENCE_GAME_MOTION_STYLE_GUIDE.md)를
참조한다. 이 문서는 구현 순서와 적용 범위를 관리하고, reference guide는 타일 조작,
점수/정산, 마켓, 보상/해금의 모션 아트 디렉션 기준으로 사용한다.

## 현재 적용 상태

- cash-out sheet의 단계별 보상 라인 등장
- Jester scoring burst
- scoring preview
- board/rank/overlap callout
- Jester/Item slot-local scoring burst
- Station Goal pulse
- board line confirm Flame particle overlay skeleton
- `_BoardScoringCallout`, `_ItemEffectFeedbackToast`, `_ScoringPreviewChip` 일부 `flutter_animate` 적용
- 전투/정산/마켓/보드/HUD/손패 연출 timing은 `lib/views/game/game_presentation_timings.dart`의 `GamePresentationTimings`와 `GamePresentationCue` 기준으로 중앙화

## 눈검증 진입점

- Route: `/game?fixture=animation_effects_eye_check`
- 확인 순서:
  - 진입 직후 scoring preview chip pulse와 board/rank/overlap callout 후보 상태를 본다.
  - `확정`을 눌러 line confirm particle, score callout, settlement step 흐름을 본다.
  - 다시 fixture에 진입한 뒤 보드 타일 하나를 선택하고 quick slot item을 눌러 item effect toast를 본다.
  - 필요하면 `tools/ios_sim_smoke.sh --route "/game?fixture=animation_effects_eye_check" --settle 8`로 iOS 화면을 연다.

## 공통 규칙

- 새 전투/정산/마켓 연출의 `Duration`, stagger 간격, hold delay는 먼저 `lib/views/game/game_presentation_timings.dart`에 이름 붙여 추가한다. 화면 파일에서 `Duration(milliseconds: ...)`, `Duration(seconds: ...)`, `420.ms` 같은 숫자 literal을 직접 늘리지 않는다.
- 같은 duration과 stagger가 함께 쓰이는 연출은 `GamePresentationCue`로 묶는다. 예: line confirm sweep, constraint cell flash, settlement score mote, market offer reveal처럼 index별 delay가 있는 연출.
- `GamePresentationTimings`와 `GamePresentationCue`는 화면 박자만 관리한다. AnimationController, 선택 상태, reveal 완료 여부, 저장 가능한 runtime 값은 들지 않는다.
- 새 연출을 추가한 뒤에는 `rg "Duration\\(milliseconds|Duration\\(seconds|\\.ms" lib/views/game lib/views/game/widgets -n`로 숫자 literal이 기준표 밖에 남지 않았는지 확인한다. 예외가 필요하면 코드 주석으로 이유를 남긴다.
- 새 modal/sheet/route/보상/아이템 효과는 120~260ms 범위의 짧은 fade/slide/step animation을 우선 검토한다.
- 점수/효과 내용을 읽어야 하는 callout, scoring preview, item toast는 320~420ms 진입 연출까지 허용한다.
- 아이템 효과는 수동/패시브 모두 발동 사실과 실제 delta가 명확히 보여야 한다. snackbar만으로 끝내지 말고 overlay, badge, `+1` float, resource pulse 중 하나를 제공한다.
- pulse/glow/border flash는 보조 강조로만 본다. 연출 보강의 중심은 source에서 target/result로 이동하는 flight/trail, 선택 대상의 실제 변화, 도착/결과 reveal처럼 방향과 원인이 보이는 애니메이션으로 둔다.
- Flutter 내장 `AnimationController`/`Tween`만 고집하지 않는다. 동일한 fade/slide/scale/number tween boilerplate가 반복되거나 연출이 2~3 step 이상으로 늘면 `flutter_animate` 같은 Flutter-native tween helper를 presentation layer 한정으로 검토한다.
- 입력 차단 barrier는 직접 `ModalBarrier`와 색상 값을 하드코딩하지 말고 `GameInputBarrier.modal()` 또는 `GameInputBarrier.feedback()`를 사용한다.
- battle item/Jester slot UI는 의미별 표시와 잠금 상태를 분리한다. Quick/Passive/Jester 표시 개수와 초기 해금 개수는 공용 상수/용량 메서드를 사용하고, 새 UI에서 `Q3`, `P2`, `Jester 5th` 잠금을 다시 하드코딩하지 않는다.
- 연출이 2~3개 이상 추가되면 `stageFlowPhase`와 `activeSettlement*` 같은 개별 field 확장보다 transient `GamePresentationEvent` / `presentationQueue` 구조를 먼저 검토한다.
- presentation queue는 save DTO에 포함하지 않는다. save/continue의 source of truth는 runtime state이며, queue는 비어 있어도 게임 결과가 변하지 않아야 한다.
- 과하지 않게 적용한다. 입력 대기, 반복 플레이 속도, 정보 가독성을 방해하면 애니메이션을 줄이거나 생략한다.

## 아이템 효과 UX Coverage

`ITEM_EFFECT_RUNTIME_MATRIX.md`는 런타임 상태 변경과 소모 정책의 기준 문서다. 이 문서는 같은 아이템 효과가 플레이어에게 어떻게 전달되는지 확인한다. `applied` 상태라도 아래 3단계 중 하나가 빠지면 UX 보강 후보로 남긴다.

주의: 아래의 "표시/피드백 1차 완료"는 badge, notice, toast, callout, 기존 hand/board 전환 재사용까지의 상태를 뜻한다. 새 이동 궤적, 타겟으로 날아가는 연출, stagger reveal, particle 같은 presentation 연출 완료를 뜻하지 않는다. 아이템 축은 단순히 "읽을 수 있음"으로 닫지 않고, 아이템 source, 목적지/대상, 결과가 게임적으로 이어지는지 따로 본다. badge/문구는 보조 정보이며, 필요한 경우 slot pulse, target flash, resource pulse, tile/offer/card flight, stagger reveal, settlement burst 같은 presentation을 추가한다.

1. 발동 인지
   - 수동 아이템: 눌린 슬롯 pulse, 사용 toast, 실패 deny feedback 중 하나를 보여준다.
   - queued 아이템: 사용 직후 다음 확정/다음 이동/다음 구매 같은 대기 상태 badge를 보여준다.
   - 패시브/자동 아이템: 발동 시점에 slot-local badge 또는 짧은 callout을 보여준다.
2. 대상 인지
   - 보드/손패/덱/마켓 후보/자원 HUD 중 어느 영역에 작용하는지 highlight, 선택 UI, 이동 연출, 또는 근처 badge로 보여준다.
   - 대상이 없는 실패는 notice만으로 끝낼 수 있지만, 성공처럼 보이는 burst나 소비 연출은 띄우지 않는다.
3. 결과 인지
   - 실제 delta를 `+1`, `-2`, 할인 배지, 카드 이동, 점수 delta, 자원 pulse처럼 읽히는 형태로 보여준다.
   - runtime 결과와 다른 과장 연출은 넣지 않는다. 일부만 적용된 효과는 실제 증가량만 표시한다.

### 2026-05-17 재점검: 아이템 Source -> Target -> Result

기존 커밋 `ff93b15`의 animation-first UX 규칙에 따라, 보강 기준은 "텍스트로 이해 가능"이 아니라 "아이템이 어디서 발동해 어디에 작용하고 무엇이 바뀌었는지 게임적으로 보이는가"다.

| 우선순위 | 아이템/묶음 | Source | Target / 목적지 | 현재 상태 | 재판단 |
|---|---|---|---|---|---|
| Done | `deck_needle` | Quick slot | 덱 top 후보 -> 버림 결과 | 후보 번호/타일 코드, 선택 후보 flash/fade, `버림 확정` result badge, `R1 제거` notice/toast | 선택 후보가 즉시 버림 결과로 확정됐다는 dialog 내부 feedback과 실제 제거 notice를 테스트로 고정했다. 큰 discard flight는 P2 polish로만 남긴다. |
| Done | `slide_wax` | Quick slot queued 상태 | 다음 보드 이동 flight와 이동 완료 타일 | `이동 보너스 대기` badge, 기존 board move flight, 발동 feedback, 이동 도착 칸 bonus flash | 보드 이동에 보너스가 붙었다는 목적지/결과 연결을 도착 칸 flash로 보강했다. |
| Done | `emergency_draw` | Quick slot / 덱 | 손패 영역 | item source toast, 기존 hand incoming transition, `드로우 +1` badge, deck/hand resource pulse | 추가 모션 없이 기존 hand incoming + 덱/손패 pulse를 source -> target -> result 체인으로 검증 고정했다. |
| Done | next-confirm 소모품 16종: `chip_capsule`, `mult_capsule`, `line_polish`, `straight_oil`, `flush_powder`, `pair_splint`, `overlap_pin`, `red_swatch`, `blue_swatch`, `black_swatch`, `yellow_swatch`, `rank_chalk`, `score_abacus`, `thin_caliper`, `tile_polisher`, `echo_bell` | Quick slot 또는 passive/equipped slot | scoring preview -> 확정 라인 -> settlement score | `확정 대기 N`, queued badge pulse, preview chip link flash, preview 적용/미충족 표시, settlement item burst | slot/Item zone에서 preview/확정 결과로 이어지는 최소 연출 체인을 테스트로 고정했다. |
| Done | Market 후보/할인 적용: `market_compass`, `boss_trophy` | Passive/equipped item | Market 후보 lane / 할인 후보 / Jester offer count | `나침반`, `트로피 +N` badge, lane bonus pulse, discount offer pulse | 후보 슬롯 증가와 할인 대상이 각각 lane/offer에서 pulse로 연결되도록 보강하고 widget test로 고정했다. `shop_lens`는 원격 최신 변경 기준 삭제 상태로 유지한다. |
| Done | 전투 자원 직접 증가: `board_scrap`, `hand_scrap`, `move_token`, `battle_pouch` | Quick slot | 하단 자원 HUD / 손패 capacity | item toast, source label, 하단 resource pulse, hand capacity gain badge | 실제 바뀐 자원/손패 capacity 영역이 pulse/badge로 반응하는지 테스트로 고정했다. |
| Done | 전투 조작형: `undo_seal` | Quick slot | 마지막 board move tile 위치 | 실패 notice, 성공 item toast, 되돌아간 칸 flash | 실패는 no-op/미소모 notice로, 성공은 되돌아간 board target flash로 고정했다. |
| Done | Market 직접 사용/성장: `coin_cache`, `thin_wallet`, `trade_ticket`, `*_study`, `reroll_token`, `coupon_stamp`, `jester_invoice`, `item_invoice` | Inventory item | Gold HUD, item offer lane, reroll cost, 다음 구매 가격, hand growth state | market item use feedback/flight, gold gain badge, 가격/리롤/후보 read path | 상점 직접 사용은 slot source -> use feedback -> gold/offer/reroll/read-path로 이어지는 기존 연출/테스트를 유지한다. 세부 효과별 더 큰 flight는 P3 polish로만 남긴다. |

현재 P1 이상 보강 후보는 개별 아이템 기준 22종이며, 2026-05-17에 모두 1차 Done으로 닫았다.

- `deck_needle`, `slide_wax`, `emergency_draw`: 3종
- next-confirm 계열: 16종
- Market 후보/할인 적용: 3종

완료 기준은 저장/런타임 변경이 아니라 presentation read path다. source -> target/목적지 -> result 연결이 테스트로 고정된 상태이며, 더 큰 flight/particle/polish는 P3 visual polish로만 다룬다.

P2 재점검 후보까지 2026-05-17에 모두 1차 Done으로 닫았다. 남은 것은 신규 정책 결함이 아니라 시각 polish 후보로 취급한다.

2026-05-17 추가 정정: pulse/glow만으로는 시선 유도력이 약하므로, 1차 Done 이후 polish도 단순 glow 반복이 아니라 실제 이동/방향성 중심으로 잡는다. 전투 아이템 toast는 source label -> result trail을 표시하고, `slide_wax` queued badge는 내부 chevron 이동으로 "다음 이동에 실린 효과"를 보이며, Market 직접 사용류는 gold gain 여부와 무관하게 item card flight를 띄운다.

2026-05-17 Playwright 눈검증: `item_motion_eye_check`, `next_confirm_motion_eye_check`, `animation_effects_eye_check`, `market_modifier_shop`, `market_item_motion_eye_check` fixture를 정적 web build에서 열어 source -> target/result 연출을 확인했다. 산출물은 `/tmp/rummipoker_item_motion_eye_check_20260517_152554/`, `/tmp/rummipoker_next_confirm_eye_check_20260517_153152/`, `/tmp/rummipoker_next_confirm_eye_check_more_20260517_153249/`이며 important console/error/overflow/warn은 0건이다. Computer Use는 도구 서버 오류로 직접 조작하지 못했으므로, Playwright screenshot과 로컬 image view 확인을 근거로 남긴다.

## 전투 연출 후보

1. 점수 미리보기 변화
   - Flutter `flutter_animate`
   - score delta, target reach, 부족 상태를 숫자 pulse/색 변화로 표시
   - HUD container 전체 scale/translate 금지

2. 카드/라인 확정 피드백
   - Flutter callout + Flame particle overlay
   - 확정 가능한 라인 badge는 짧은 fade/slide
   - 확정 순간 scoring cell 중심에 작은 spark

3. 아이템/Jester 발동 callout
   - Flutter `flutter_animate`
   - `+score`, `+gold`, `-turn`, `block`, `copy` 같은 slot-local badge
   - 여러 발동은 개별 난사보다 그룹으로 묶는다.

4. Boss/제약 상태 강조
   - Flutter badge flash 또는 Flame impact particle
   - 점수 감소/무효화 순간만 표시
   - 작은 점이나 단독 `!` 대신 점수 영향이 읽히는 배지 사용

5. Objective / Station goal 변화
   - Flutter pulse
   - 목표 근접/달성 순간만 강조
   - clear/gameover 연출 충돌 방지

6. 큰 점수/clear burst
   - Flame particle overlay
   - 큰 점수, boss clear, stage clear에만 사용
   - 반복 confirm마다 과하게 터뜨리지 않는다.

## 마켓 연출 후보

1. Market route 진입/복귀
   - Flutter `flutter_animate`
   - 짧은 fade/slide
   - 구매/리롤 입력을 지연하지 않음

2. 상품 카드 등장/리롤
   - Flutter `flutter_animate`
   - 새 상품만 짧은 stagger fade/slide
   - 카드 크기와 grid layout shift 금지

3. 구매 성공/실패
   - Flutter `flutter_animate`
   - 성공: slot pulse, gold `-cost` badge
   - 실패: 돈 부족/슬롯 부족 deny feedback

4. 장착 슬롯 변화
   - Flutter `flutter_animate`
   - 새 아이템/Jester 슬롯 scale pulse
   - passive/quick/Jester 의미 표시는 기존 UI 규칙 유지

5. rarity/passive 상태
   - Flutter border/glow 최소 사용
   - rarity 자체를 과장하지 않고 상태 변화만 읽히게 한다.

## Flame 적용 범위

- 현재 1차 구조는 Flutter 보드 위 `IgnorePointer` + 투명 `GameWidget` visual overlay다.
- Flame은 runtime 결과를 계산하지 않고, 외부에서 전달받은 좌표에 짧은 이펙트만 그린다.
- 우선 적용 대상은 line confirm, clear burst, boss/constraint impact다.
- 마켓은 Flutter 위젯 중심이므로 Flame particle은 후순위다.
- 보드 전체 Flame renderer 이관, Flame HUD 전환은 성능 문제가 실제로 보일 때 재검토한다.

## bejeweled_classic 참고 요소

참고 프로젝트: repo 외부 `bejeweled_classic` 참고 구현. 로컬 위치는 PC마다 다를 수 있으므로 문서에는 절대경로를 고정하지 않는다.

- 바로 적용:
  - `flutter_animate`로 기존 `TweenAnimationBuilder` 보일러플레이트 축소
  - Flutter 보드/마켓 callout polish
- 1차 Flame 적용:
  - Flutter 보드 위 `IgnorePointer` + 투명 `GameWidget` visual overlay
  - line confirm/clear/boss impact 파티클만 transient로 처리
- 재사용 후보:
  - `ParticleBurst`/`ParticlePool` 구조
  - 이벤트 강도별 count/lifetime/speed 조절
  - GameWidget 1회 생성/마운트 분리 패턴
- 보류:
  - 보드 전체 Flame 렌더러 이관
  - Flame HUD 전환
  - 웹 SFX `AudioPool` 재설계

## 최적화 기준

- Flutter UI 연출은 짧은 `flutter_animate` 체인으로 처리하고, 매 프레임 `setState`/전체 화면 rebuild를 만들지 않는다.
- Flame visual overlay는 필요할 때만 마운트한다. 상시 `GameWidget` 루프는 테스트 `pumpAndSettle`과 배터리/FPS에 영향을 주므로 금지한다.
- 파티클은 `ParticlePool`로 재사용하고, 일반 confirm/medium/big clear처럼 강도별 count/lifetime/speed 상한을 둔다.
- 배경·보드 chrome·반복 장식은 `RepaintBoundary`, `CustomPainter.shouldRepaint == false`, 또는 Flame `ui.Picture` 캐시 후보로 본다.
- 보드 타일 36칸은 당장 Flutter 위젯 유지. 연출이 타일별로 늘어 프레임 드랍이 보이면 타일 단위 `RepaintBoundary` 또는 보드 단일 painter/Flame renderer 이관을 다시 검토한다.
- blur/glow/saveLayer 계열은 큰 면적에 반복 적용하지 않는다. glow는 작은 파티클/배지에만 제한하고, fullscreen flash는 피한다.
- 이펙트 좌표·큐·표시 tick은 transient presentation state다. save DTO, simulator input/output, runtime scoring에는 포함하지 않는다.

## 적용 순서

1. 남은 기존 callout/toast Tween 보일러플레이트를 순차 치환
2. line confirm particle 위치를 iOS 시뮬레이터에서 확인
3. clear burst와 boss/constraint impact를 Flame overlay에 추가
4. Market 상품 카드 등장/리롤 stagger 적용
5. 구매 성공/실패 feedback 적용
6. 프레임 드랍이 보일 때만 타일 단위 repaint/보드 renderer 최적화 재검토
