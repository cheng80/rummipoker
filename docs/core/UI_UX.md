# 화면과 사용성

이 문서는 플레이어가 실제로 보는 화면과 조작 흐름을 설명한다. 화면 이름과 코드 경로는 개발자가 찾기 쉽게 남기고, 앞의 설명은 처음 보는 사람도 이해할 수 있게 쓴다.

## 화면별로 할 수 있는 일

[router.dart](../../lib/router.dart)와 [app_config.dart](../../lib/app_config.dart)가 관리하는 화면은 모두 7개다.

| 화면 | 주요 입력 | 들어갈 수 있는 조건 | 결과 | 문제가 생기면 |
|---|---|---|---|---|
| `/` Title | 새 run, 이어하기, 북마크 불러오기, Run 정보, 설정, 도감, 특별 모드 | 이어하기는 payload·signature 존재와 `ActiveRunAvailability.available`을 요구; 북마크는 비어 있지 않아야 함 | 선택 route로 이동하거나 verified active scene을 복원 | invalid save는 삭제/취소 dialog; 복원 실패는 손상 dialog; 빈 북마크는 notice |
| `/new-run` New Run | 표준/도전, basic/high-stakes, random seed 또는 정수 seed | 난이도와 modifier는 unlock state를 통과해야 하고 seed는 정수여야 함 | 기존 active run을 지우고 `/blind-select`로 이동 | 잠긴 선택은 기본값으로 정규화; 잘못된 seed는 notice; 뒤로가기는 Title |
| `/blind-select` Blind Select | Scout, Clash, Boss 선택 | 직전 tier clear 뒤에만 다음 tier가 selectable | 선택한 목표·자원·Boss 제약으로 `/game` 진입 | locked card는 비활성·사유 표시; 뒤로가기는 restored run이면 Title, 새 run이면 New Run |
| `/game` Battle / Settlement / Market host | draw, 타일 선택·배치, 버림, 이동, Item, 확정, options, tutorial, Run 정보 | `GameStageFlowPhase`, board-move mode, scene, 자원·target precondition이 입력을 잠금 | runtime 갱신, 정산 연출, cash-out, Market dialog, 다음 Blind 또는 terminal | options에서 현재 Battle/Station 재시작·북마크·Title; expiry dialog에서 retry/new run/exit; lifecycle 복귀 시 options |
| `/setting` Settings | 화면 켜짐 유지, locale, BGM/SFX volume·mute, 닫기 | volume은 0..1 clamp; mute 시 slider 비활성 | StorageHelper와 Sound/Wakelock에 즉시 반영 | 닫기로 이전 route 복귀; 플랫폼 Wakelock 실패는 gameplay를 막지 않음 |
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

Jester와 Item card/slot의 current logical size는 `54 × 70`이다. [game_card_metrics.dart](../../lib/views/game/widgets/game_card_metrics.dart)의 `kBattleItemSlotWidth = 54.0`, `kBattleItemSlotHeight = 70.0`가 단일 권위이며 Jester도 같은 값을 참조한다.

## 정산 화면

확정은 판정을 한 번 계산한 뒤 표시만 단계화한다. `boardLine → handRank → overlap → constraint → jester → tile → item → finalScore` 순서의 `ScoringPresentationStep`이 line callout, 타일 강조, effect burst, 목표 점수 증가를 제어한다. 이 presentation sequence는 저장 가능한 점수 결과를 다시 계산하지 않는다.

Blind clear 뒤에는 cleared/settlement overlay, cash-out sheet, gold·deck reward reveal이 이어진다. S8 Boss cash-out은 `무한 도전 진입`과 `런 완료`를 분리하고, 일반 cash-out은 Market 진입만 제공한다. cash-out dialog는 결과가 준비되기 전 action을 비활성화하며 SafeArea 안에서 표시된다. 구현은 [game_view_stage_flow.dart](../../lib/views/game/game_view_stage_flow.dart)와 [game_cashout_widgets.dart](../../lib/views/game/widgets/game_cashout_widgets.dart)가 소유한다.

## Market 화면

Market은 `/game` 위의 fullscreen dialog이며 active save scene은 `shop`이다.

- `Jester / Slots`와 `Tool / Gear` 두 탭이 같은 화면 위치를 공유한다.
- 현재 lane의 보유 slot, 선택 상세, 후보, 가격·할인, 구매·판매·사용·리롤 action을 함께 보여준다.
- 구매·리롤은 확인과 affordability/cap guard를 거친다. 거절은 shake/badge/notice, 성공은 flight/pulse/reveal로 구분한다.
- state-changing action은 save queue에 들어간다. 다음 Blind/auto-advance 경로에서는 flush하지만 Main Menu·options exit는 현재 flush하지 않는다.
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
| tap·select | selection border, button state, tile pop | button SFX; web는 user gesture에서 audio unlock |
| invalid battle action | action 유지, top notice | 상태를 바꾸지 않고 이유 표시 |
| confirm | line sweep, contributor lift/remove, rank/overlap/effect callout, score mote | clear 시 clear SFX |
| Item/Jester/tile effect | source badge, burst, flight, 2초 feedback | effect 결과 label 유지 |
| Market deny/success | deny shake·badge 또는 purchase flight·slot pulse·offer reveal | notice로 guard 이유 표시 |
| cash-out | 단계별 reward reveal, coin burst, total gold | collect SFX |
| game over | 2초 danger fade 뒤 modal | time-up SFX; retry/new run/exit 제공 |
| focus-out | tutorial 제거, veil/options, animation time pause | BGM pause; resume에서 적절한 scene BGM 복구 |

시간 상수는 [game_presentation_timings.dart](../../lib/views/game/game_presentation_timings.dart), audio 정책은 [sound_manager.dart](../../lib/resources/sound_manager.dart)가 소유한다. motion은 결과 state를 소유하지 않으며 pause 중 duration 진행을 멈춘다.

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
- settings/locale/archive: [setting_view_test.dart](../../test/views/setting_view_test.dart), [archive_view_test.dart](../../test/views/archive_view_test.dart)



## Known Presentation Gaps

역기획 기준 현재 화면 정보는 아래처럼 runtime 사실과 어긋날 수 있다. 이를 의도된 UX 계약으로 쓰지 않는다.

- Blind Select 보상 미리보기는 Scout/Clash/Boss를 4/8/12 또는 High Stakes 4/9/13으로 보여 주지만 Settlement 기본 골드는 모든 tier 4다.
- 점수 정산 라벨의 `Jester` 합계는 Jester뿐 아니라 tile/Item/Boss 효과 합을 포함할 수 있다. seal ID `tile_seal:*`는 Item으로 오분류될 수 있다.
- cash-out 네비게이션 버튼은 step 3에서 열릴 수 있지만 최종 합계 reveal은 step 4/5까지 이어질 수 있다.
- Game Over의 `기억 카드 획득` 문구는 실제 지급 금액 없이 선택 전에 표시되며, Retry는 지급하지 않는다.
- Challenge carryover 안내가 보이지만 현재 completion summary는 growth/deck 필드를 채우지 않아 실완료 후 snapshot이 비어 있다.
- Tool/Gear UI는 3/2 슬롯만 렌더하지만 구매 cap이 없어 숨은 보유가 생길 수 있다.
- Archive 분모는 Item 91개를 쓰지만 normal Market 노출에서 제외된 5개가 있어 일반 수집 91/91은 도달 불가하다.
- Battle/Market coach mark만 있고 Blind, Boss 규칙, cash-out, 실패 학습, unlock spend, Archive 온보딩은 없다.
- locale 설정은 세션 전용(`saveLocale:false`)이며 핵심 화면 문자열 일부와 content catalog 번역이 미완이다.

## Source and Update Trigger

route set, screen input guard/recovery, Battle hierarchy, card dimensions, Market tabs, tutorial/modal/lifecycle order, presentation cue, locale list, semantics 또는 phone-frame policy가 바뀌면 같은 변경에서 이 문서와 직접 보호 테스트를 갱신한다.
