# Animation Effects Plan

이 문서는 전투/마켓 연출을 늘릴 때 참고할 적용 목록과 최적화 기준이다.
연출은 모두 transient presentation state이며, save/continue와 simulator 결과의
source of truth는 runtime state다.

## 현재 적용 상태

- cash-out sheet의 단계별 보상 라인 등장
- Jester scoring burst
- scoring preview
- board/rank/overlap callout
- Jester/Item slot-local scoring burst
- Station Goal pulse
- board line confirm Flame particle overlay skeleton
- `_BoardScoringCallout`, `_ItemEffectFeedbackToast`, `_ScoringPreviewChip` 일부 `flutter_animate` 적용

## 눈검증 진입점

- Route: `/game?fixture=animation_effects_eye_check`
- 확인 순서:
  - 진입 직후 scoring preview chip pulse와 board/rank/overlap callout 후보 상태를 본다.
  - `확정`을 눌러 line confirm particle, score callout, settlement step 흐름을 본다.
  - 다시 fixture에 진입한 뒤 보드 타일 하나를 선택하고 quick slot item을 눌러 item effect toast를 본다.
  - 필요하면 `tools/ios_sim_smoke.sh --route "/game?fixture=animation_effects_eye_check" --settle 8`로 iOS 화면을 연다.

## 공통 규칙

- 새 modal/sheet/route/보상/아이템 효과는 120~260ms 범위의 짧은 fade/slide/step animation을 우선 검토한다.
- 점수/효과 내용을 읽어야 하는 callout, scoring preview, item toast는 320~420ms 진입 연출까지 허용한다.
- 아이템 효과는 수동/패시브 모두 발동 사실과 실제 delta가 명확히 보여야 한다. snackbar만으로 끝내지 말고 overlay, badge, `+1` float, resource pulse 중 하나를 제공한다.
- Flutter 내장 `AnimationController`/`Tween`만 고집하지 않는다. 동일한 fade/slide/scale/number tween boilerplate가 반복되거나 연출이 2~3 step 이상으로 늘면 `flutter_animate` 같은 Flutter-native tween helper를 presentation layer 한정으로 검토한다.
- 입력 차단 barrier는 직접 `ModalBarrier`와 색상 값을 하드코딩하지 말고 `GameInputBarrier.modal()` 또는 `GameInputBarrier.feedback()`를 사용한다.
- battle item/Jester slot UI는 의미별 표시와 잠금 상태를 분리한다. Quick/Passive/Jester 표시 개수와 초기 해금 개수는 공용 상수/용량 메서드를 사용하고, 새 UI에서 `Q3`, `P2`, `Jester 5th` 잠금을 다시 하드코딩하지 않는다.
- 연출이 2~3개 이상 추가되면 `stageFlowPhase`와 `activeSettlement*` 같은 개별 field 확장보다 transient `GamePresentationEvent` / `presentationQueue` 구조를 먼저 검토한다.
- presentation queue는 save DTO에 포함하지 않는다. save/continue의 source of truth는 runtime state이며, queue는 비어 있어도 게임 결과가 변하지 않아야 한다.
- 과하지 않게 적용한다. 입력 대기, 반복 플레이 속도, 정보 가독성을 방해하면 애니메이션을 줄이거나 생략한다.

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
