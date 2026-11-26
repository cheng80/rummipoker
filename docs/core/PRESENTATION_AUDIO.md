# 연출과 사운드

이 문서는 플레이어의 행동과 게임 결과가 화면 움직임, 소리, 진동으로 어떻게 전달되는지 설명한다. 어느 화면에서 무엇을 누를 수 있는지는 [UI_UX](UI_UX.md)가 소유하고 연출 코드의 계층과 소리 출력 구조는 [SYSTEM_ARCHITECTURE](SYSTEM_ARCHITECTURE.md)가 소유한다.

연출은 게임 결과를 바꾸지 않는다. 점수, 보드, 골드를 먼저 확정하고 연출은 그 결과를 보여 주기만 한다. 그래서 연출 속도를 바꾸거나 건너뛰어도 게임 상태는 같다.

## 행동 결과를 알려 주는 신호

| 일어난 일 | 화면에서 보이는 변화 | 소리와 다음 안내 |
|---|---|---|
| tap·select | 전투 액션 버튼 누름 찌그러짐·juice, 손패 선택 시 떠오름·확대·기울기(spring-follow), 덱→손패·손패→보드 호 비행과 착지 파문 | 행동별 의미 키(배치·드로우·버림·아이템·줄 변환·이동·선택·미리보기 변화); web는 user gesture에서 audio unlock |
| battle 진입·예고 | 보드·손패 stagger deal, Boss `X`·제약 표시 찍힘, 점수 줄 숨쉬기 3회 뒤 정지, 한 칸 남은 줄 희미한 힌트, 확정 버튼 장전, 마지막 이동·버림·덱 0 자원 경고 | 정보 전달용이며 점수가 나지 않는 결과는 축하하지 않는다 |
| invalid battle action | action 유지, top notice 문구 유지, 해당 영역 좌우 흔들림 | 오류음과 error 햅틱. 무효 배치, 점유 칸 이동, 점수 줄 없는 확정, 아이템 실패, 가득 찬 손패 드로우, 잠긴 Jester·Item 슬롯 탭이 같은 입구(`_denyBattleAction`)를 쓴다 |
| confirm | callout, 타일 tick, 겹침 체인, Jester 순차 발동, 등급 callout, count-up, contributor 순차 제거 | tick pitch 상승, 등급별 소리, clear 시 clear SFX |
| battle Jester sell | 슬롯에서 카드 조각·코인 burst, 골드 count-up | sell cue |
| Item/Jester/tile effect | source badge, burst, flight, 2초 feedback | effect 결과 label 유지 |
| Market deny/success | deny shake·badge 또는 purchase flight·slot pulse·offer reveal·NEW reveal | notice로 guard 이유 표시, 구매 전 collection state 확인 |
| cash-out | 단계별 reward reveal, coin burst, 최종 current/total gold, 성장 보상 묶음 | collect SFX |
| game over | 2초 danger fade 동안 보드가 가라앉고 소리 하강, 뒤이어 modal | Deny SFX; retry/new run/exit 제공 |
| focus-out | tutorial 제거, veil/options, animation time pause | BGM pause; resume에서 적절한 scene BGM 복구 |

시간 상수는 [game_presentation_timings.dart](../../lib/views/game/game_presentation_timings.dart), audio 정책은 [sound_manager.dart](../../lib/resources/sound_manager.dart)가 소유한다. motion은 결과 state를 소유하지 않으며 pause 중 duration 진행을 멈춘다.

## 정산 연출

확정은 판정을 한 번 계산한 뒤 표시만 단계화한다. `boardLine → handRank → overlap → constraint → jester → tile → item → finalScore` 순서의 `ScoringPresentationStep`이 line callout, 타일 강조, effect burst, 목표 점수 증가를 제어한다. 이 presentation sequence는 저장 가능한 점수 결과를 다시 계산하지 않는다.

정산 한 박자는 다음 순서로 보인다. 박자와 등급 기준은 [game_settlement_pacing.dart](../../lib/views/game/game_settlement_pacing.dart)와 `GamePresentationTimings`의 전투 레인 구역이 소유한다.

- callout과 발동 요약은 채점 중인 줄을 가리지 않는 보드 가장자리에 놓인다. 위·아래 두 줄 띠와 좌·우 두 칸 폭 중 contributor 칸과 겹치지 않는 첫 자리를 쓴다.
- 줄 안의 타일은 하나씩 반응한다. 음높이는 한 확정 전체에 걸쳐 tick마다 약 1.6%씩 오르며, 줄이 바뀌어도 처음으로 돌아가지 않는다. 여러 줄에 기여한 교차 타일은 맞을 때마다 다른 음색과 더 큰 juice를 쓰고, 맞은 횟수만큼 주황 글로우로 달아오른다.
- Jester는 왼쪽 슬롯부터 한 장씩 발동한다. 모션은 효과 유형별 세 가지다. 칩 가산은 내려찍기, % 가산은 부풀기, ×N 곱연산은 회전 섬광이다. 타일 modifier와 Item은 Jester의 금색과 다른 색 파티클을 쓰고, Boss 감점은 감점음을 낸다.
- 목표 점수와 골드는 약 0.5초 동안 count-up하며 tick 소리를 내고, 목표 진행 바도 함께 찬다.
- 줄 점수 등급은 목표 점수 대비 비율(10%·25%·50%)로 4단계다. 단계마다 callout 문구(5개 언어)와 `Collect` 음높이가 다르며, hit-stop과 화면 흔들림, 큰 점수 burst는 상위 2단계만 쓴다.
- 미리보기 점수가 남은 목표를 넘으면 확정 버튼과 목표 바가 초과 폭의 로그에 비례해 달아오른다. 그 확정의 마지막 finalScore는 짧은 hit-stop과 0.5배 슬로모션을 주는 피니셔다.
- 확정이 끝나면 contributor 타일이 줄 방향을 따라 35ms 간격으로 부풀었다 터지고, 빈 칸에 약 0.4초 잔광이 남으며, 남은 타일은 한 번 출렁인다. 이 연출은 입력을 막지 않는다.
- 설정의 정산 속도를 따르고, 한 확정에서 스텝이 8개를 넘으면 최대 2.5배까지 자동으로 가속한다. 정산 중 HUD 아래를 탭하면 남은 연출을 건너뛴다. 속도, 자동 가속, 스킵, 동작 줄이기 중 무엇을 써도 최종 점수·보드·골드·덱 상태는 같다.
- cash-out sheet는 짧은 fade·slide로 등장한다(동작 줄이기에서는 즉시). `Clear`는 이 최종 정산창이 처음 표시될 때만 한 번 재생한다. 줄별 채점, 앞선 overlay, 보상 count-up, 화면 재빌드에는 재생하지 않는다. 일반·복원·자동 정산과 S8 Boss 정산에 같은 규칙을 적용한다.

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
| 의미 레지스트리 `GameCue` | 게임 행동의 소리와 햅틱은 의미 키로 고르고 같은 시점에 낸다. 일반 UI 클릭은 공용 입력 부품이 `BtnSnd` 원음을 한 번 재생한다. 음원 12개를 등록하되 단어 음성을 일반 변주에 쓰지 않으며, 시각·햅틱만 필요한 cue는 소리를 생략한다([game_feedback_cues.dart](../../lib/views/game/game_feedback_cues.dart)) |

설정과 접근성 계약은 다음과 같다.

- 연출 강도 `끔/보통/강`은 juice·흔들림·파티클 양에 0/1/1.5배를 곱한다. 정산 속도 `즉시`는 연출 대기를 건너뛰지만 결과는 같다.
- OS의 동작 줄이기(`disableAnimations`, `reduceMotion`)가 켜져 있으면 juice와 흔들림, 추종 모션은 설정과 무관하게 0이고 설정 화면에 그 사실을 알린다.
- 화면 흔들림과 진동은 각각 끌 수 있다. 진동은 네이티브에서 `HapticFeedback`, Android 웹에서 20ms 이하 `navigator.vibrate`를 쓰고 iOS 웹에서는 아무것도 하지 않는다.
- 비언어 효과음은 웹의 Web Audio와 네이티브의 SoLoud 모두 같은 `pitch × 변주 × globalPitch` 값을 0.25~4로 제한해 음높이와 속도를 함께 바꾼다. 네이티브는 일시정지된 음성에 배율을 설정한 뒤 재생한다. 전역 pitch는 새로 시작하는 효과음에 적용하며, 게임오버 뒤 다음 run에서 1로 되돌린다. `Start`·`Clear`는 공통 출력 계층에서 호출부 pitch·변주·globalPitch와 무관하게 최종 rate 1을 보장한다. BGM은 기존 재생 경로를 유지한다.

### 효과음 역할과 소유권

| 역할 | 음원·시점 | 소유권 |
|---|---|---|
| 일반 입력 | 메뉴·설정·분류·상품 선택은 `BtnSnd` 원음 1회 | 공용 버튼 또는 명시적 클릭 cue 중 한 곳. UI 원음 flag로 globalPitch도 무시 |
| 거래·행동 결과 | 구매·판매·리롤·아이템 사용·줄 변환·해금·Station 이동은 `BtnSnd` 원음 1회. 거절과 게임오버는 `Deny` 원음 | 결과 handler가 소유하며 버튼 기본음과 겹치지 않는다 |
| 타일 조작 | 선택 `TilePick`, 배치 `TilePlace`, 버리기 `CardToss`. 드로우·이동은 `BtnSnd` | 원음 1회, 호출부 pitch·변주·globalPitch를 무시 |
| 승리 | `Reward` 원음 | 승리 연출 시작 시 1회 |
| 정산 보호 | `scoreTick`, `overlapHit`, `penalty`, `jesterFire`, `tileModifierFire`, `itemFire`, `bigScore1..4`, `countTick`, `cashOutCollect` | 기존 음원·배율·변주·상승식·타이밍 유지. 정산 전 확정 버튼은 `BtnSnd` |
| 단어 음성 | `Clear`는 최종 정산창 첫 표시 원음 1회. `Start`는 승인된 재생 상황 없음 | 일반 효과음으로 변주하지 않는다 |
| 무음 | 자동 보스 소개·상하단 notice·점수 미리보기 변화·NEW·상점 자동 진입 | 기존 시각·햅틱은 유지 |

2026-09-21 Jev-1.13.0의 한국어·영어 메타데이터 평가를 동일 기준으로 적용했다. 19개 상황을 한영으로 총 38번 판단했으며, 8개가 양쪽 기준을 통과했다. 나머지 11개는 기본 클릭·무음 정책에 따라 BtnSnd 또는 무음으로 정했다. 평가 19개와 별도로 정산 전 `confirmPress`는 기본 클릭 정책을 적용했다. 모델의 실제 청취 결과로 간주하지 않으며 런타임 모델 의존성은 없다. 등록 파일·출처는 `assets/audio/sfx/CREDITS.md`, 전체 44개 매핑과 정산 보호 baseline은 `test/resources/fixtures/audio_cue_contract.json`에서 검증한다.

버튼 기본음과 결과음의 중복은 시간 기반 차단 대신 호출 소유권으로 막는다. HUD 도움말·옵션·보스 정보, 카드 상세, 선택창·뒤로·닫기와 사용자 건너뛰기는 BtnSnd 원음 1회다. 자동 장면 종료에는 클릭음을 내지 않는다. 보드의 실제 선택·해제와 이동 취소는 BtnSnd를 내며, 빈칸 ignored·입력 잠금·비활성 컨트롤은 예외다. 정보가 없는 보스 HUD는 비활성이고 활성 판매가 거절되면 Deny를 낸다. 즉시 아이템 사용은 결과 handler, 대상 선택창을 여는 별도 클릭은 버튼음이 소유한다. `GameTileChoiceDialog`는 선택·닫기 후 호출부의 결과음 소유 여부를 각각 명시한다. 기존 Fail·TimeUp의 발화 여부는 검증하지 않았으며 보호된 정산 외에서 재사용하지 않는다.

### 공통 입력, 팝업, 화면 전환

전투·정산·상점 밖의 입력은 모두 같은 규칙으로 반응한다. 플레이어는 눌렀는지, 받아들여졌는지, 거절됐는지를 손과 귀로 구분할 수 있다.

- 누름: 입력 부품은 공용 `PressFeedback`([common_ui.dart](../../lib/utils/common_ui.dart))을 거친다. pointer-down에 살짝 찌그러지고, tap에는 juice와 햅틱, `BtnSnd` 원음(pitch 1, 변주 0)이 따른다. 자체 cue를 가진 호출부는 `playSound: false`로 공용 소리를 끈다. 비활성 입력과 자동 닫힘은 클릭음을 내지 않는다. 공용 버튼, 아이콘 칩, 메뉴 타일, 타이틀·New Run 카드, Blind play 버튼, 난이도·modifier 카드, Archive 카드와 페이지 버튼이 여기에 해당한다. 런 시작과 전투 시작 같은 결정 버튼은 juice를 더 크게 준다.
- 거절: 비활성 이어하기 카드, 잠기거나 이미 끝난 Blind의 play 버튼, 기억 카드가 모자란 modifier는 눌러도 상태가 바뀌지 않는다. 대신 좌우로 짧게 흔들리고 `deny` 소리와 error 햅틱이 난다. 화면 전체를 번쩍이지는 않는다.
- 의미 소리: 런 시작(`runStart`), 전투 시작(`battleStart`), 이어하기·북마크 복원(`runRestore`), 난이도·modifier·언어·연출 설정 선택(`choiceSelect`)은 의미 cue를 쓰고, 옵션·뒤로·닫기·튜토리얼·북마크 클릭은 공용 버튼 또는 `withButtonSound`가 소리를 맡는다. `runStart`, `battleStart`, `runRestore`의 효과음은 기존 `BtnSnd` 원음(pitch 1)을 유지한다. 상점 탭·분류·페이지·상품 선택과 해제는 같은 항목을 다시 눌러도 클릭마다 `BtnSnd` 한 번만 낸다. 언어·연출 설정도 pitch 1과 변주 0을 유지한다. 음소거 해제는 설정을 먼저 적용하고 클릭음을 내며, 음소거 설정은 소리를 내지 않는다. 정산 카운트와 결과 효과는 보호된 게임 cue를 유지한다. top·bottom notice는 소리를 내지 않는다. 호출부가 이미 다른 cue를 냈다면 `cue: null`로 끈다.
- modifier 해금: 기억 카드로 modifier를 해금하면 그 카드가 크게 튕기고 FX 레이어 불꽃이 튀며 `unlock`의 `BtnSnd` 소리가 난다. Station 이동은 `BtnSnd`, 런 승리는 `Reward`를 쓰며 `Clear`를 재사용하지 않는다.
- 팝업: `showAppDialog`와 `showGameFramedDialog`는 220ms scale-pop으로 열리고 140ms 만에 닫힌다. barrier는 route 애니메이션을 따라 fade된다. 닫힌 직후 route를 바꿀 때 `endOfFrame`을 기다리는 규칙은 변함없이 적용된다.
- 화면 전환: route는 280ms fade와 짧은 slide로 바뀐다. 디버그 픽스처, `auto_*`·`debug_*` 쿼리, OS 동작 줄이기에서는 즉시 전환해 풀런봇과 자동 흐름을 늦추지 않는다. 타이틀에서 전투로 나갈 때 웹 BGM은 320ms 동안 줄어든 뒤 멈춘다.
- 동작 줄이기에서는 흔들림, juice, 팝업 scale이 모두 빠진다. 소리, 햅틱, fade는 남는다. 시간 값은 `GamePresentationTimings`에, cue 매핑은 `gameFeedbackCues`의 T0 구역에 있다.

### 흐름과 메타 화면

한 런이 열리는 순간과 닫히는 순간, 그리고 그 사이를 잇는 화면은 같은 규칙으로 반응한다. 연출은 결과 state를 바꾸지 않으며, 읽어야 하는 글자를 가리지 않는다.

- Boss 인트로: Boss Station에 들어가면 붉은 띠가 들어오고 Boss 이름이 도장처럼 찍히며 제약 아이콘이 차례로 떨어진다. `bossIntro` cue와 가벼운 흔들림을 쓴다. 배너는 자동으로 닫히지 않고 플레이어가 확인 버튼을 눌러야 닫힌다. 닫히면 제약 표시가 배너 자리에서 보드·손패의 해당 칸으로 날아가고, 닿는 순간 기존 `GameStampIn` 도장이 찍힌다. 그때까지 보드의 Boss 표시는 숨어 있다. 자동 튜토리얼은 이 흐름이 끝난 뒤 시작한다.
- Blind Select: 카드가 80ms 간격으로 차례로 들어오고, 상태 배지는 방금 깬 tier를 OPEN에서 CLEAR로, 새로 열린 tier를 LOCKED에서 OPEN으로 짧게 바꾼다. Boss 카드의 위험 표시는 세 번 맥동하고 멈춘다. play를 누르면 고른 카드가 커지고 나머지가 물러난 뒤 240ms 안에 전투로 넘어간다. 화면 위쪽 진행 띠는 S1부터 마지막 Station까지의 경로를 그리며, Market에서 돌아와 Station이 올라가면 현재 위치가 한 칸 나아간다. 무한 구간은 모든 칸을 완료로 두고 끝에 무한 표시를 붙인다. 띠는 저장 필드를 더하지 않고 현재 run 상태만 읽는다.
- 런 완료: 마지막 Boss를 깬 뒤 기록 저장과 save 정리가 끝나면 승리 장면이 뜬다. `victory` cue가 울리고 코인·불꽃 연출 뒤 런 요약 수치가 차례로 count-up된다. 수치는 이미 있는 run 기록에서만 가져온다. 2.4초가 지나면 스스로 끝나고, 그 전에 어디를 탭해도 바로 끝나며, 끝난 뒤에는 BGM이 줄어들고 타이틀로 이동한다.
- 게임 오버: 기존 2초 위험 fade 동안 비언어 효과음이 `rampGlobalPitch(0.5, ...)`로 내려가고, 보드는 Transform으로 가라앉으며 기울어진다. 채도를 빼는 대신 어두운 막을 색 알파로 겹친다. 결과 창의 기억 카드는 세로축으로 한 번 돌아 공개되고, 네 버튼은 의미에 맞는 cue를 쓴다. 어느 출구로 나가든, GameView가 사라질 때든 전역 pitch는 1로 돌아온다.
- 타이틀과 웹 splash: 앱을 켜고 처음 타이틀에 올 때만 로고가 내려앉고 진입 카드가 차례로 들어온다. 버전 문자열은 fade로 바뀐다. 상시 idle 움직임은 연출 강도 `강`에서만 돌고 화면을 떠나면 멈춘다. 웹 splash는 첫 프레임 위에서 240ms fade한 뒤 사라진다.
- Archive: 수집 카운터는 0에서 count-up되고, 상태 배지는 미발견·발견·획득마다 서로 다른 결로 전환된다. 마지막으로 확인한 뒤 새로 발견한 항목에는 `NEW` 꼬리표가 붙고, 그 카드를 처음 열면 한 번 뒤집히며 공개된다.
- 동작 줄이기와 연출 강도 `끔`에서는 위 움직임이 모두 빠지고 같은 정보와 같은 탭으로 흐름이 이어진다. `auto_*` 자동 흐름에서는 Boss 제약 비행과 승리 장면을 건너뛰어 봇을 늦추지 않는다. 시간 값은 `GamePresentationTimings`의 T4 구역에 있다.

## 특수 타일 재질과 배경 분위기

특수 타일은 기존 글자 배지를 유지하면서 면과 가장자리에 재질을 더한다. 칩 박힘은 작은 금속 점, 점수 도금은 얇은 세로선, 골드는 금색 안쪽 테두리, 유리는 대각 반사광으로 구분한다. 은빛·빛무늬·다색 판본은 각각 은색·청록색·무지개색 가장자리를 쓴다. 인장은 왼쪽 아래에 점이나 빗금으로 새기며 오른쪽 아래의 글자 배지는 그대로 남는다.

작은 보드 타일과 큰 상세 타일은 `TileMaterialMetrics`를 공유한다. 면의 무늬는 숫자와 색 띠보다 먼저 그리고 움직이는 반사광은 가장자리에 제한한다. 아이템 효과의 `accent`가 켜지면 가장자리 재질 띠를 생략해 금색 대상 링을 보존한다. 숫자, 인장·판본 배지, Boss 제약 `X`, 선택 테두리의 위치는 바꾸지 않는다. 구현은 [tile_material.dart](../../lib/widgets/fx/tile_material.dart)와 [rummikub_tile_canvas.dart](../../lib/game/rummi_poker_grid/rummikub_tile_canvas.dart)에 있다.

반사광은 공용 시계 하나로 200ms마다 갱신하며 화면에 보이는 타일은 최대 4장까지 움직인다. 나머지는 타일 안쪽에 하이라이트가 놓이는 phase 0.25에서 시작한다. 가시성 검사는 한 프레임에 한 번 예약하고 tick 안에서는 검사 결과를 재사용한다. 화면 밖으로 나가거나 숨겨진 타일은 갱신하지 않는다. 재질 타일이 없거나 연출 강도가 꺼져 있거나 OS 동작 줄이기가 켜져 있으면 시계를 멈춘다. 앱 비활성 상태에서도 움직이지 않으며 정산 속도를 바꾸거나 연출을 생략해도 타일 데이터는 달라지지 않는다.

별 배경은 F의 구운 `FxSprites` atlas를 `drawRawAtlas`로 그린다. 별의 알파만 바꾸는 레이어를 `RepaintBoundary`로 분리하고 기본 그라디언트의 raster cache 힌트는 유지한다. 연출 강도 끔·동작 줄이기에서는 정지 배경을 표시한다. 배경 위젯이 교체돼도 남아 있는 소유자가 공유 시계를 유지하며, 연출을 다시 켜면 메뉴 색조도 즉시 다시 그린다.

[FxAmbient](../../lib/widgets/fx/fx_ambient.dart)는 `setMood(FxAmbientMood.battle | market | boss | reward | menu)`와 `pulse(strength)`를 제공한다. 분위기 색조는 900ms에 걸쳐 목표 색으로 바뀌고 짧은 밝기 반응은 800ms 안에 끝난다. 호출은 상태가 바뀌는 순간에 한 번만 한다. 타이틀·New Run·Blind Select 진입은 `menu`, 전투 진입과 Station 재시작은 현재 blind에 맞춰 `battle` 또는 `boss`, Boss 인트로가 열릴 때는 `boss`, 스테이지 클리어와 cash-out은 `reward`, Market이 열려 있는 동안은 `market`이고 닫히면 전투 분위기로 돌아온다. 점수 등급이 상위 두 단계일 때는 결과 state를 반영한 뒤 `pulse`를 한 번 부른다. 설정과 도감은 타이틀에서만 들어가므로 따로 호출하지 않는다. 이 API는 화면 분위기만 바꾸며 게임 결과와 입력 가능 여부에는 관여하지 않는다. 성능 비교는 픽스처 확정 구간의 `frameCount`가 300 이상인 회차만 사용한다. 유효 회차를 전후 3회씩 얻지 못하면 환경 부하로 측정 불가로 기록하고 통합 단계에서 다시 확인한다.

## Source and Test Anchors

- 공통 입력·팝업·전환: [common_input_feedback_test.dart](../../test/utils/common_input_feedback_test.dart), [title_continue_deny_test.dart](../../test/views/title_continue_deny_test.dart), [new_run_modifier_unlock_feedback_test.dart](../../test/views/new_run_modifier_unlock_feedback_test.dart)
- 전투 레인 연출: [settlement_speed_equivalence_test.dart](../../test/views/game/battle_lane/settlement_speed_equivalence_test.dart), [settlement_pacing_test.dart](../../test/views/game/battle_lane/settlement_pacing_test.dart), [contributor_clear_test.dart](../../test/views/game/battle_lane/contributor_clear_test.dart), [battle_input_feel_test.dart](../../test/views/game/battle_lane/battle_input_feel_test.dart)
- 흐름과 메타 화면: [boss_intro_flow_test.dart](../../test/views/game/flow_meta/boss_intro_flow_test.dart), [run_end_flow_test.dart](../../test/views/game/flow_meta/run_end_flow_test.dart), [run_complete_flow_test.dart](../../test/views/game/flow_meta/run_complete_flow_test.dart), [run_victory_overlay_test.dart](../../test/views/game/flow_meta/run_victory_overlay_test.dart), [blind_select_flow_test.dart](../../test/views/flow_meta/blind_select_flow_test.dart), [title_entrance_test.dart](../../test/views/flow_meta/title_entrance_test.dart), [archive_new_test.dart](../../test/views/flow_meta/archive_new_test.dart), [archive_seen_service_test.dart](../../test/services/archive_seen_service_test.dart)
- 배경 분위기: [game_view_ambient_test.dart](../../test/views/game/game_view_ambient_test.dart), [game_view_test.dart](../../test/views/game/game_view_test.dart)의 정산→Market 흐름
- 연출 기반: [presentation_clock_test.dart](../../test/widgets/fx/presentation_clock_test.dart), [motion_fx_test.dart](../../test/widgets/fx/motion_fx_test.dart), [game_feedback_test.dart](../../test/resources/game_feedback_test.dart), [rummi_poker_sfx_test.mjs](../../test/web/rummi_poker_sfx_test.mjs)

## Source and Update Trigger

정산 연출 순서, presentation cue, 연출 기반·설정·동작 줄이기 계약, 효과음 역할·소유권, 타일 재질, 배경 분위기가 바뀌면 같은 변경에서 이 문서와 직접 보호 테스트를 갱신한다.
