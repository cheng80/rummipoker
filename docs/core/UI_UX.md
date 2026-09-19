# 화면과 사용성

이 문서는 플레이어가 실제로 보는 화면과 조작 흐름을 설명한다. 화면 이름과 코드 경로는 개발자가 찾기 쉽게 남기고, 앞의 설명은 처음 보는 사람도 이해할 수 있게 쓴다.

## 화면별로 할 수 있는 일

[router.dart](../../lib/router.dart)와 [app_config.dart](../../lib/app_config.dart)가 관리하는 화면은 모두 7개다.

| 화면 | 주요 입력 | 들어갈 수 있는 조건 | 결과 | 문제가 생기면 |
|---|---|---|---|---|
| `/` Title | 새 run, 이어하기, 북마크 불러오기, Run 정보, 설정, 도감, 특별 모드 | 이어하기는 active record 또는 완전한 legacy pair가 `ActiveRunAvailability.available`이어야 함; 북마크는 비어 있지 않아야 함 | 선택 route로 이동하거나 verified active scene을 복원 | invalid save는 삭제/취소 dialog; 복원 실패는 손상 dialog; 빈 북마크는 notice |
| `/new-run` New Run | 표준/도전, basic/high-stakes, random seed 또는 정수 seed | 난이도와 modifier는 unlock state를 통과해야 하고 seed는 정수여야 함 | 새 `blindSelect` runtime을 저장하고 같은 객체를 `/blind-select`로 전달 | 저장 실패는 기존 active run을 유지한 채 notice; 잠긴 선택은 기본값으로 정규화; 잘못된 seed는 notice; 뒤로가기는 Title |
| `/blind-select` Blind Select | Scout, Clash, Boss 선택 | 직전 tier clear 뒤에만 다음 tier가 selectable | 선택한 목표·자원·Boss 제약으로 `/game` 진입 | locked card는 비활성·사유 표시; 뒤로가기는 restored run이면 Title, 새 run이면 New Run |
| `/game` Battle / Settlement / Market host | draw, 타일 선택·배치, 버림, 이동, Item, 확정, options, tutorial, Run 정보 | `GameStageFlowPhase`, board-move mode, scene, 자원·target precondition이 입력을 잠금 | runtime 갱신, 정산 연출, cash-out, Market dialog, 다음 Blind 또는 terminal | options에서 현재 Battle/Station 재시작·북마크·Title; expiry dialog에서 retry/new run/exit; lifecycle 복귀 시 options |
| `/setting` Settings | 화면 켜짐 유지, locale, BGM/SFX volume·mute, 연출 강도·정산 속도·화면 흔들림·진동, 닫기 | volume은 0..1 clamp; mute 시 slider 비활성; SFX slider를 놓으면 미리듣기 | StorageHelper와 Sound/Wakelock에 즉시 반영 | 닫기로 이전 route 복귀; 플랫폼 Wakelock 실패는 gameplay를 막지 않음 |
| `/trial` Special Mode | 뒤로가기 | gameplay 입력 없음 | 안내용 placeholder를 표시 | 뒤로가기로 이전 route 복귀 |
| `/archive` Archive | 수집 카드·Jester·Item 상세, 뒤로가기 | detail은 catalog와 수집 state load 뒤 사용 | device의 Insight·수집·Boss 기록을 read-only로 표시 | load 중 skeleton은 있으나 load error 전용 retry/error UI는 없음; 사용자는 뒤로간 뒤 재진입 |

Title의 저장 복구는 [title_view.dart](../../lib/views/title_view.dart), New Run guard는 [new_run_view.dart](../../lib/views/new_run_view.dart), Blind 순서는 [blind_select_view.dart](../../lib/views/blind_select_view.dart)가 소유한다.

## 전투 화면은 위에서 아래로 읽는다

Battle 화면은 위에서 아래로 다음 read/action hierarchy를 유지한다.

1. 상단 정보: Station·난이도, Blind/Boss 제약, 현재 점수와 목표, 골드, 설정과 튜토리얼 버튼.
2. Jester zone: slot 순서, 잠금 상태, 정산 중 활성 효과.
3. Item zone: Quick/Passive와 Tool/Gear 탭, stack·사용 가능 상태, 정산 효과.
4. 5×5 보드: 선택한 타일, 점수에 쓰이는 타일, Boss 금지칸, 이동 전·후 위치, 정산 연출.
5. Scoring preview와 action bar: 예상 족보·점수·효과 수, 확정, Run 정보, 이동·보드 버림·손패 버림.
6. Bottom info와 hand: 덱, 이동, 두 버림 자원, 손패 현재/최대, draw 가능 칸, 선택·long press 상세.

View는 mutable session을 직접 표시하지 않고 `RummiStationRuntimeFacade`, `RummiBattleRuntimeFacade`, `RummiMarketRuntimeFacade`를 읽는다. board/hand 선택은 presentation state이고 save 정답 상태가 아니다. layout은 [game_view_layout_widgets.dart](../../lib/views/game/game_view_layout_widgets.dart), HUD는 [game_shared_battle_hud_widgets.dart](../../lib/views/game/widgets/game_shared_battle_hud_widgets.dart), hand는 [game_hand_zone.dart](../../lib/views/game/widgets/game_hand_zone.dart)가 소유한다.

보드 이동은 타일 선택 → `타일 이동` → 빈 목적지 칸 선택 순서로 조작하며, 목적지를 선택하면 별도 확인 없이 즉시 이동한다. 이동 횟수가 없거나 목적지가 유효하지 않으면 상태를 바꾸지 않고 notice로 이유를 알린다.

Jester와 Item card/slot의 current logical size는 `54 × 70`이다. [game_card_metrics.dart](../../lib/views/game/widgets/game_card_metrics.dart)의 `kBattleItemSlotWidth = 54.0`, `kBattleItemSlotHeight = 70.0`가 단일 권위이며 Jester도 같은 값을 참조한다.

## 정산 화면

확정은 판정을 한 번 계산한 뒤 표시만 단계화한다. `boardLine → handRank → overlap → constraint → jester → tile → item → finalScore` 순서의 `ScoringPresentationStep`이 line callout, 타일 강조, effect burst, 목표 점수 증가를 제어한다. 이 presentation sequence는 저장 가능한 점수 결과를 다시 계산하지 않는다.

정산 한 박자는 다음 순서로 보인다. 박자와 등급 기준은 [game_settlement_pacing.dart](../../lib/views/game/game_settlement_pacing.dart)와 `GamePresentationTimings`의 전투 레인 구역이 소유한다.

- callout과 발동 요약은 채점 중인 줄을 가리지 않는 보드 가장자리에 놓인다. 위·아래 두 줄 띠와 좌·우 두 칸 폭 중 contributor 칸과 겹치지 않는 첫 자리를 쓴다.
- 줄 안의 타일은 하나씩 반응한다. 음높이는 한 확정 전체에 걸쳐 tick마다 약 1.6%씩 오르며, 줄이 바뀌어도 처음으로 돌아가지 않는다. 여러 줄에 기여한 교차 타일은 맞을 때마다 다른 음색과 더 큰 juice를 쓰고, 맞은 횟수만큼 주황 글로우로 달아오른다.
- Jester는 왼쪽 슬롯부터 한 장씩 발동한다. 모션은 효과 유형별 세 가지다. 칩 가산은 내려찍기, % 가산은 부풀기, ×N 곱연산은 회전 섬광이다. 타일 modifier와 Item은 Jester의 금색과 다른 색 파티클을 쓰고, Boss 감점은 감점음을 낸다.
- 목표 점수와 골드는 약 0.5초 동안 count-up하며 tick 소리를 내고, 목표 진행 바도 함께 찬다.
- 줄 점수 등급은 목표 점수 대비 비율(10%·25%·50%)로 4단계다. 단계마다 callout 문구(5개 언어)와 소리가 다르며, hit-stop과 화면 흔들림, 큰 점수 burst는 상위 2단계만 쓴다.
- 미리보기 점수가 남은 목표를 넘으면 확정 버튼과 목표 바가 초과 폭의 로그에 비례해 달아오른다. 그 확정의 마지막 finalScore는 짧은 hit-stop과 0.5배 슬로모션을 주는 피니셔다.
- 확정이 끝나면 contributor 타일이 줄 방향을 따라 35ms 간격으로 부풀었다 터지고, 빈 칸에 약 0.4초 잔광이 남으며, 남은 타일은 한 번 출렁인다. 이 연출은 입력을 막지 않는다.
- 설정의 정산 속도를 따르고, 한 확정에서 스텝이 8개를 넘으면 최대 2.5배까지 자동으로 가속한다. 정산 중 HUD 아래를 탭하면 남은 연출을 건너뛴다. 속도, 자동 가속, 스킵, 동작 줄이기 중 무엇을 써도 최종 점수·보드·골드·덱 상태는 같다.
- cash-out sheet는 짧은 fade·slide로 등장한다(동작 줄이기에서는 즉시).

Blind clear 뒤에는 cleared/settlement overlay, cash-out sheet, gold·deck reward reveal이 이어진다. S8 Boss cash-out은 `무한 도전 진입`과 `런 완료`를 분리하고, 일반 cash-out은 Market 진입만 제공한다. cash-out dialog는 결과가 준비되기 전 action을 비활성화하며 SafeArea 안에서 표시된다. 구현은 [game_view_stage_flow.dart](../../lib/views/game/game_view_stage_flow.dart)와 [game_cashout_widgets.dart](../../lib/views/game/widgets/game_cashout_widgets.dart)가 소유한다.

## Market 화면

Market은 `/game` 위의 fullscreen dialog이며 active save scene은 `shop`이다.

- `Jester / Slots`와 `Tool / Gear` 두 탭이 같은 화면 위치를 공유한다.
- 현재 lane의 보유 slot, 선택 상세, 후보, 가격·할인, 구매·판매·사용·리롤 action을 함께 보여준다.
- 구매·리롤은 확인과 affordability/cap guard를 거친다. 거절은 shake/badge/notice, 성공은 flight/pulse/reveal로 구분한다.
- state-changing action은 save queue에 넣는다. 다음 Blind, auto-advance, 화면 하단 메인 메뉴, options의 Title 이탈은 queue를 flush한 뒤 이동한다. flush에 실패하면 Market에 남아 notice를 표시한다.
- 첫 자동 tutorial은 entry와 tab layout이 안정된 뒤 시작하고, 수동 다시보기는 현재 layout에서 즉시 시작한다.

화면은 [game_shop_screen.dart](../../lib/views/game/widgets/game_shop_screen.dart), 선택·guard는 [game_shop_selection_flow.dart](../../lib/views/game/widgets/game_shop_selection_flow.dart), 구매 feedback은 [game_shop_purchase_flow.dart](../../lib/views/game/widgets/game_shop_purchase_flow.dart)가 소유한다.

## Archive 화면

Archive는 `RunUnlockState`, Jester catalog, Item catalog를 함께 읽어 기억 카드, 발견/구매한 콘텐츠, Boss/Station 기록을 표시한다. 미수집 항목과 수집 항목을 구분하고 runtime 구매나 active run을 바꾸지 않는다. load 전에는 기본 state와 loading card를 표시한다. 현재 Future error 전용 상태와 retry button은 구현돼 있지 않으므로 이를 복구 완료로 간주하지 않는다. 근거는 [archive_view.dart](../../lib/views/archive_view.dart)와 [archive_view_test.dart](../../test/views/archive_view_test.dart)다.

## 튜토리얼과 팝업이 겹칠 때의 우선순위

위계는 `screen content < tutorial overlay < presentation pause veil / modal dialog`다. options, pause, focus-out, route 전환 전에 tutorial overlay를 먼저 제거하므로 tutorial이 dialog 위에 남지 않는다.

- 자동 Battle tutorial은 battle scene, unlocked stage flow, stable first layout에서만 시작한다.
- 자동 Market tutorial은 Market entry와 tab switch가 끝난 뒤 시작한다.
- `Done`은 seen을 complete로 저장하고, 사용자의 `Skip`은 seen을 skip으로 저장한다.
- focus-out, options, pause, dispose에 의한 강제 제거는 seen을 기록하지 않으며 다음 진입 때 첫 step부터 다시 시작한다.
- resize 중 tutorial은 현재 focus index를 기억해 overlay를 다시 만들지만, 강제 종료는 index를 0으로 reset한다.
- `inactive`는 250ms debounce 후 pause로 확정한다. `paused`/`hidden`은 즉시 tutorial을 제거하고 save/BGM pause를 요청한다. resume은 options를 열거나 진행 중 presentation을 재개한다.
- Battle과 Market 모두 상단 직접 버튼과 options에서 tutorial 다시보기에 접근한다.

상태 저장은 [tutorial_state_service.dart](../../lib/services/tutorial_state_service.dart), Battle 위계는 [game_view_presentation_flow.dart](../../lib/views/game/game_view_presentation_flow.dart), Market 위계는 [game_shop_setup_flow.dart](../../lib/views/game/widgets/game_shop_setup_flow.dart)가 소유한다.

## 행동 결과를 알려 주는 신호

| 일어난 일 | 화면에서 보이는 변화 | 소리와 다음 안내 |
|---|---|---|
| tap·select | 전투 액션 버튼 누름 찌그러짐·juice, 손패 선택 시 떠오름·확대·기울기(spring-follow), 덱→손패·손패→보드 호 비행과 착지 파문 | 행동별 의미 키(배치·드로우·버림·아이템·줄 변환·이동·선택·미리보기 변화); web는 user gesture에서 audio unlock |
| battle 진입·예고 | 보드·손패 stagger deal, Boss `X`·제약 표시 찍힘, 점수 줄 숨쉬기 3회 뒤 정지, 한 칸 남은 줄 희미한 힌트, 확정 버튼 장전, 마지막 이동·버림·덱 0 자원 경고 | 정보 전달용이며 점수가 나지 않는 결과는 축하하지 않는다 |
| invalid battle action | action 유지, top notice 문구 유지, 해당 영역 좌우 흔들림 | 오류음과 error 햅틱. 무효 배치, 점유 칸 이동, 점수 줄 없는 확정, 아이템 실패, 가득 찬 손패 드로우, 잠긴 Jester·Item 슬롯 탭이 같은 입구(`_denyBattleAction`)를 쓴다 |
| confirm | callout, 타일 tick, 겹침 체인, Jester 순차 발동, 등급 callout, count-up, contributor 순차 제거 | tick pitch 상승, 등급별 소리, clear 시 clear SFX |
| battle Jester sell | 슬롯에서 카드 조각·코인 burst, 골드 count-up | sell cue |
| Item/Jester/tile effect | source badge, burst, flight, 2초 feedback | effect 결과 label 유지 |
| Market deny/success | deny shake·badge 또는 purchase flight·slot pulse·offer reveal | notice로 guard 이유 표시 |
| cash-out | 단계별 reward reveal, coin burst, total gold | collect SFX |
| game over | 2초 danger fade 뒤 modal | time-up SFX; retry/new run/exit 제공 |
| focus-out | tutorial 제거, veil/options, animation time pause | BGM pause; resume에서 적절한 scene BGM 복구 |

시간 상수는 [game_presentation_timings.dart](../../lib/views/game/game_presentation_timings.dart), audio 정책은 [sound_manager.dart](../../lib/resources/sound_manager.dart)가 소유한다. motion은 결과 state를 소유하지 않으며 pause 중 duration 진행을 멈춘다.

## 연출 기반과 설정

연출은 공통 기반 하나를 거치며, 각 화면은 아래 API만 호출하고 자체 타이머나 전역 `timeDilation`은 쓰지 않는다. 구현은 [lib/widgets/fx](../../lib/widgets/fx/)가 소유한다.

| 기반 | 계약 |
|---|---|
| 연출 시계 `PresentationClock` | 정산·전환 대기는 이 시계로 기다린다. pause 중에는 시간이 흐르지 않고, 정산 속도 설정(1x/2x/4x/즉시)만큼 빨라지며, hit-stop은 다음 대기 앞에 짧은 정지를 넣는다. 결과 state는 시계에 의존하지 않는다 |
| juice `Juice` | 찌그러짐 뒤 약 8Hz로 0.4초 동안 감쇠 진동하는 스케일·미세 회전. 공용 버튼 `GameChromeButton`은 pointer-down에 찌그러지고 tap에 juice와 선택 햅틱을 낸다 |
| spring-follow `SpringFollow` | 고정 시간 트윈 대신 위치·스케일·회전을 축마다 다른 계수로 지수 추종한다 |
| 화면 흔들림 `ScreenShake` | trauma(0~1)를 더하고 선형으로 줄이며 흔들림은 trauma²다. 난수 없이 사인파를 섞는다. 호스트는 `PhoneFrame` 안에 하나다 |
| FX 레이어 `FxLayer` | 앱 루트의 전체 화면 `CustomPainter` 한 장. 파티클은 구운 스프라이트 atlas를 `drawRawAtlas` 한 번으로 그리고, 그릴 것이 없으면 티커를 멈춘다. 프리셋은 `lineConfirm`, `constraintImpact`, `largeScore`, `burst`, `sparks`, `coins`, `shards`다 |
| 구운 글로우 `FxBoxGlow` | 애니메이션되는 그림자·글로우는 프레임마다 blur를 계산하지 않고 한 번 구운 이미지의 크기와 투명도만 바꾼다 |
| 의미 레지스트리 `GameCue` | 소리와 햅틱은 의미 키로 고르고 항상 같은 시점에 낸다. 지금은 효과음 7개와 pitch·변주 조합으로 매핑한다([game_feedback_cues.dart](../../lib/views/game/game_feedback_cues.dart)) |

설정과 접근성 계약은 다음과 같다.

- 연출 강도 `끔/보통/강`은 juice·흔들림·파티클 양에 0/1/1.5배를 곱한다. 정산 속도 `즉시`는 연출 대기를 건너뛰지만 결과는 같다.
- OS의 동작 줄이기(`disableAnimations`, `reduceMotion`)가 켜져 있으면 juice와 흔들림, 추종 모션은 설정과 무관하게 0이고 설정 화면에 그 사실을 알린다.
- 화면 흔들림과 진동은 각각 끌 수 있다. 진동은 네이티브에서 `HapticFeedback`, Android 웹에서 20ms 이하 `navigator.vibrate`를 쓰고 iOS 웹에서는 아무것도 하지 않는다.
- 웹 효과음은 Web Audio `playbackRate`로 음높이를 바꾼다. 반면 네이티브는 audioplayers가 음높이를 유지한 채 속도만 바꾸므로 원음으로 재생한다. 전역 pitch 배율은 게임오버 연출용이며 다음 run에서 1로 되돌린다.

## 접근성과 언어 지원 현황

| 영역 | 구현됨 | 테스트로 보호됨 | 검증 gap |
|---|---|---|---|
| route/dialog semantics | Title image label, HUD progress semantics, modal `scopesRoute/namesRoute`, tile choice와 bookmark dialog label | widget interaction과 dialog route test 일부 | screen-reader traversal, focus order, action announcement를 검사하는 semantics test 없음 |
| touch/readability | scrollable long screens, 54×70 card, button disabled state, long text soft-wrap/FittedBox, visible guard feedback | Market/Blind/Boss 일부 overflow·ellipsis assertion | 모든 route의 큰 text scale, keyboard-only, switch access, 실제 screen reader 검증 없음 |
| locale | `ko`, `en`, `ja`, `zh-CN`, `zh-TW`; system locale 기본, 한국어 fallback; Settings에서 즉시 변경 | 기본 navigation/settings localization test와 일부 CJK-friendly no-ellipsis widget assertion | 5 locale × 7 route 전체 overflow, 실제 CJK font fallback·줄바꿈·접근성 label 검증 없음 |
| dynamic layout | MediaQuery textScaler를 보존하고 일부 word-wrap helper가 scaler 반영 | 개별 widget layout test | fixed 390×750 frame 안의 최대 text scale, foldable/tablet/rotation 전체 검증 없음 |

구현됨은 code path가 존재한다는 뜻이고, 보호됨은 명시적 assertion이 있다는 뜻이다. gap 항목은 현재 완료 상태가 아니다. locale bootstrap은 [main.dart](../../lib/main.dart), locale code mapping은 [translation_locale_code.dart](../../lib/resources/translation_locale_code.dart), word wrap은 [game_word_wrap_text.dart](../../lib/views/game/widgets/game_word_wrap_text.dart)가 소유한다.

## 휴대폰 화면 크기와 안전 영역

모든 7 route는 기본적으로 `PhoneFrameScaffold`를 사용한다. Scaffold는 SafeArea 안에 logical `390 × 750` frame을 중앙 배치하고, available width/height 중 작은 scale로 `BoxFit.contain`한다. frame 내부 MediaQuery size만 390×750으로 고정하며 locale과 text scaler는 상위 값을 유지한다. notice와 cash-out/modal도 별도 SafeArea를 사용한다.

이 구조는 notch와 system inset을 피하고 desktop/web에서도 동일 logical 좌표를 제공한다. 다만 fixed frame이 모든 device class와 큰 text scale에서 overflow가 없음을 보장하지는 않는다. 구현 근거는 [phone_frame_scaffold.dart](../../lib/widgets/phone_frame_scaffold.dart)다.

## Source and Test Anchors

- routes/screens: [router.dart](../../lib/router.dart), [title_view_test.dart](../../test/views/title_view_test.dart), [blind_select_view_test.dart](../../test/views/blind_select_view_test.dart)
- Battle read/input: [game_session_state.dart](../../lib/providers/features/rummi_poker_grid/game_session_state.dart), [game_station_read_path_test.dart](../../test/views/game/widgets/game_station_read_path_test.dart)
- settlement/Market: [game_cashout_widgets_test.dart](../../test/views/game/widgets/game_cashout_widgets_test.dart), [game_shop_screen_test.dart](../../test/views/game/widgets/game_shop_screen_test.dart)
- lifecycle/tutorial: [game_view_lifecycle_test.dart](../../test/views/game/game_view_lifecycle_test.dart), [game_shop_lifecycle_test.dart](../../test/views/game/widgets/game_shop_lifecycle_test.dart), [tutorial_state_service_test.dart](../../test/services/tutorial_state_service_test.dart)
- settings/locale/archive: [setting_view_test.dart](../../test/views/setting_view_test.dart), [setting_view_effects_test.dart](../../test/views/setting_view_effects_test.dart), [archive_view_test.dart](../../test/views/archive_view_test.dart)
- 전투 레인 연출: [settlement_speed_equivalence_test.dart](../../test/views/game/battle_lane/settlement_speed_equivalence_test.dart), [settlement_pacing_test.dart](../../test/views/game/battle_lane/settlement_pacing_test.dart), [contributor_clear_test.dart](../../test/views/game/battle_lane/contributor_clear_test.dart), [battle_input_feel_test.dart](../../test/views/game/battle_lane/battle_input_feel_test.dart)
- 연출 기반: [presentation_clock_test.dart](../../test/widgets/fx/presentation_clock_test.dart), [motion_fx_test.dart](../../test/widgets/fx/motion_fx_test.dart), [game_feedback_test.dart](../../test/resources/game_feedback_test.dart), [rummi_poker_sfx_test.mjs](../../test/web/rummi_poker_sfx_test.mjs)



## Known Presentation Gaps

역기획 기준 현재 화면 정보는 아래처럼 runtime 사실과 어긋날 수 있다. 이를 의도된 UX 계약으로 쓰지 않는다.

- 점수 정산 라벨의 `Jester` 합계는 Jester뿐 아니라 tile/Item/Boss 효과 합을 포함할 수 있다. seal ID `tile_seal:*`는 Item으로 오분류될 수 있다.
- cash-out 네비게이션 버튼은 step 3에서 열릴 수 있지만 최종 합계 reveal은 step 4/5까지 이어질 수 있다.
- Game Over의 `기억 카드 획득` 문구는 실제 지급 금액 없이 선택 전에 표시되며, Retry는 지급하지 않는다.
- Tool/Gear UI는 3/2 슬롯만 렌더하지만 구매 cap이 없어 숨은 보유가 생길 수 있다.
- Archive 분모는 Item 91개를 쓰지만 normal Market 노출에서 제외된 5개가 있어 일반 수집 91/91은 도달 불가하다.
- Battle/Market coach mark만 있고 Blind, Boss 규칙, cash-out, 실패 학습, unlock spend, Archive 온보딩은 없다.
- locale 설정은 세션 전용(`saveLocale:false`)이며 핵심 화면 문자열 일부와 content catalog 번역이 미완이다.

## Source and Update Trigger

route set, screen input guard/recovery, Battle hierarchy, card dimensions, Market tabs, tutorial/modal/lifecycle order, presentation cue, 연출 기반·설정·동작 줄이기 계약, locale list, semantics 또는 phone-frame policy가 바뀌면 같은 변경에서 이 문서와 직접 보호 테스트를 갱신한다.
