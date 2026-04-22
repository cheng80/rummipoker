# 01. Current Build Baseline

> 문서 성격: baseline
> 코드 반영 상태: implemented / partial 혼합
> Truth source priority: 실제 `lib/` 코드 우선
> 변경 정책: 이 문서의 `[CURRENT]` 항목은 별도 migration PR 전까지 기본 규칙으로 보호한다.

## 1. 현재 프로젝트 상태

[CURRENT]

현재 프로젝트는 플레이 가능한 보드형 로그라이트 전투 루프를 이미 갖춘 코어 프로토타입이다.

구현된 큰 축은 다음이다.

- 5x5 보드 전투
- 12줄 포커 족보 평가
- 부분 줄 평가
- 즉시 확정
- overlap 보너스
- contributor만 제거
- stage 목표 점수
- Jester 점수 보정
- cash-out
- full-screen Jester shop
- 다음 stage 진행
- active run save / continue
- stageStartSnapshot 기반 현재 stage 재시작

[V4_DECISION]

V4는 이 코어를 폐기하지 않는다. 장기 목표 구조는 현재 프로토타입 위에 단계적으로 올린다.

## 2. 핵심 코드 맵

[CURRENT]

| 영역 | 현재 주요 파일 | 현재 책임 |
|---|---|---|
| 타일/덱/보드 | `models/tile.dart`, `models/poker_deck.dart`, `models/board.dart` | 4색 x 13랭크 x copiesPerTile, 보드 스냅샷, 덱 보존 |
| 족보 | `hand_rank.dart`, `hand_evaluator.dart` | 족보 enum, 기본 점수, 부분 줄 판정, contributor index |
| 라인 평가 | `rummi_poker_grid_engine.dart`, `line_ref.dart` | 행/열/대각선 12줄 스캔 |
| 전투 세션 | `rummi_poker_grid_session.dart` | draw, place, discard, confirm, overlap, 제거, 만료, stage 전환 |
| stage 자원 | `rummi_blind_state.dart` | targetScore, scoreTowardBlind, board/hand discard |
| Jester / economy / run | `jester_meta.dart` | Jester 데이터, scoring, shop, cash-out, stage index, stateful 값 |
| 저장 | `active_run_save_service.dart`, `storage_helper.dart` | active run snapshot, HMAC, stageStartSnapshot |
| 전투 Provider | `game_session_state.dart`, `game_session_notifier.dart` | session/runProgress orchestration, 선택 상태, 정산 흐름 |
| 타이틀 Provider | `title_notifier.dart`, `title_state.dart` | continue 상태, 손상 세이브 처리 |
| 화면 | `title_view.dart`, `game_view.dart`, `game/widgets/*` | 타이틀, 전투, cash-out, shop, overlay |

## 3. 현재 전투 baseline

[CURRENT]

| 항목 | 현재 기준 |
|---|---|
| 보드 | `5 x 5` |
| 평가 라인 | 행 5 + 열 5 + 대각선 2 = 12줄 |
| 덱 | `4색 x 13랭크 x copiesPerTile` |
| 기본 copiesPerTile | 1 |
| 기본 손패 한도 | 1 |
| 디버그 손패 한도 | 1~3 |
| board discard | 기본 4 |
| hand discard | 기본 2 |
| Straight | 일반 5연속 + `10-11-12-13-1` 허용 |
| 확정 방식 | 현재 scoring line 전부 확정 |
| 제거 방식 | 라인 전체가 아니라 contributor cell union만 제거 |
| overlap | contributor cell이 여러 scoring line에 포함될 때 line score 배수 적용 |
| overlap alpha | 0.3 |
| overlap cap | 2.0 |

## 4. 현재 족보 점수

[CURRENT]

| Rank | Score | 확정 후보 여부 | 제거 여부 |
|---|---:|---|---|
| High Card | 0 | 아니오 | 아니오 |
| One Pair | 0 | 아니오 | 아니오 |
| Two Pair | 25 | 예 | contributor 4장 |
| Three of a Kind | 40 | 예 | contributor 3장 |
| Straight | 70 | 예 | 5장 전체 |
| Flush | 50 | 예 | 5장 전체 |
| Full House | 80 | 예 | 5장 전체 |
| Four of a Kind | 100 | 예 | contributor 4장 |
| Straight Flush | 150 | 예 | 5장 전체 |

[V4_DECISION]

One Pair는 V4 기본 규칙에서도 0점 dead line이다. One Pair 10점화는 `[EXPERIMENT]`로만 취급한다.

## 5. 현재 카드 수별 평가

[CURRENT]

실제 `HandEvaluator.evaluateLine` 기준:

| 현재 줄의 타일 수 | 가능한 최고 판정 |
|---:|---|
| 0 | 평가 없음 |
| 1 | High Card |
| 2 | One Pair 또는 High Card |
| 3 | Three of a Kind, One Pair, High Card |
| 4 | Four of a Kind, Two Pair, Three of a Kind, One Pair, High Card |
| 5 | Straight Flush, Four of a Kind, Full House, Flush, Straight, Three of a Kind, Two Pair, One Pair, High Card |

[WATCH]

`CURRENT_SYSTEM_OVERVIEW.md`에는 4장 줄의 대표 의미가 `Two Pair / Four of a Kind`로 요약되어 있으나, 실제 코드는 4장 `Three of a Kind`도 scoring candidate로 처리한다. V4는 실제 코드 기준을 채택한다.

## 6. 현재 confirm 처리 요약

[CURRENT]

`RummiPokerGridSession.confirmAllFullLines`는 이름은 legacy지만 실제 동작은 “현재 보드의 scoring line 즉시 확정”이다.

처리 순서:

1. `RummiPokerGridEngine.listEvaluatedLines(board)`로 현재 타일이 있는 라인 평가
2. `evaluation.isDeadLine == false`인 라인만 scoring candidate로 선택
3. 각 라인의 `contributingIndexes`를 실제 board cell로 변환
4. contributor cell별 contribution count 계산
5. line별 overlap multiplier 계산
6. overlap이 반영된 baseLineScore 계산
7. 장착 Jester를 슬롯 순서대로 적용
8. line breakdown 생성
9. scoring candidate들의 contributor cell union 제거
10. 제거된 타일은 `eliminated`로 이동
11. stage 목표 달성 여부 계산

[WATCH]

`GameSessionNotifier.confirmLines`는 정산 연출을 위해 `applyScoreToBlind: false`로 confirm 결과를 만들고, `GameView` 정산 시퀀스가 line별로 `applyConfirmedLineScore`를 호출한다. 따라서 점수 반영 시점은 “confirm 계산 시점”과 “연출 정산 시점”이 분리되어 있다.

## 7. 현재 만료 baseline

[CURRENT]

`RummiExpirySignal`은 두 가지다.

| Signal | 현재 의미 |
|---|---|
| `boardFullAfterDcExhausted` | board discard가 0 이하이고 보드 25칸이 모두 찬 경우 |
| `drawPileExhausted` | 덱이 비고, 손패가 비고, 확정 가능한 scoring line도 없는 경우 |

[WATCH]

현재 코드의 `boardFullAfterDcExhausted`는 보드가 꽉 차고 board discard가 0이면 scoring candidate 존재 여부를 따로 보지 않는다. V4 target에서는 “확정 가능한 점수 줄이 있으면 먼저 확정 기회를 주는가?”를 별도 결정사항으로 둔다.

## 8. 현재 stage / economy baseline

[CURRENT]

| 항목 | 현재 값 |
|---|---:|
| stageIndex 시작 | 1 |
| 시작 골드 | 10 |
| stage clear 기본 보상 | 10 |
| 남은 board discard 보상 | 개당 +5 |
| 남은 hand discard 보상 | 개당 +2 |
| shop 기본 offer 수 | 3 |
| shop 기본 reroll cost | 5 |
| reroll 증가 | +1 |
| Jester 슬롯 | 5 |
| stage 1 목표 점수 | 300 |
| stage n 목표 점수 | `floor(300 * 1.6^(n-1))` |

## 9. 현재 Jester baseline

[CURRENT]

현재 Jester는 `data/common/jesters_common_phase5.json`을 기준으로 로드되며, `RummiJesterCatalog.shopCatalog`는 현재 런타임에서 실제 처리 가능한 카드만 shop pool로 필터링한다.

현재 지원 범주:

- scoring: `chips_bonus`, `mult_bonus`, `xmult_bonus`, `scholar`
- economy: `egg`, `golden_jester`, `delayed_gratification`
- stateful: `supernova`, `popcorn`, `ice_cream`, `green_jester`, `ride_the_bus`

Jester 적용 규칙:

- 장착 슬롯 순서대로 적용한다.
- stateful 값은 슬롯 인덱스를 키로 저장한다.
- 점수 보정은 scoringTiles, rank, context를 기준으로 한다.
- face card 판정은 contributor 기반 `scoringTiles`에 대해서만 이루어진다.

## 10. 현재 저장 baseline

[CURRENT]

| 항목 | 현재 구현 |
|---|---|
| 저장 엔진 | `GetStorage` payload |
| 보안 키 | `flutter_secure_storage`, 웹에서는 `GetStorage` fallback |
| 무결성 | HMAC-SHA256 |
| schemaVersion | 2 |
| storage key | `active_run_payload_v1`, `active_run_signature_v1`, `save_device_key_v1` |
| activeScene | `battle`, `shop` |
| 저장 범위 | session, runProgress, activeScene, stageStartSnapshot |
| continue | title에서 availability 검사 후 restore |
| 재시작 | 현재 stage 시작 시점으로 복원 |

[WATCH]

storage key 이름은 `v1`이지만 payload `schemaVersion`은 2다. V4 save migration에서는 key version과 payload schema version을 별도 개념으로 유지한다.

## 11. 현재 UI baseline

[CURRENT]

주요 화면:

- `TitleView`
- `GameView`
- `GameShopScreen`
- `SettingView`

현재 타이틀 flow:

1. 이어하기 가능 여부 확인
2. 저장 데이터 available / invalid / none 분기
3. 랜덤 시작
4. 시드 시작
5. 디버그 fixture 시작
6. 설정 진입

현재 전투 flow:

1. stage battle
2. draw / place / board discard / hand discard
3. confirm
4. settlement animation
5. target score 달성 시 clear overlay
6. cash-out sheet
7. full-screen shop
8. next stage

## 12. 현재 미구현 또는 target-only

[CURRENT: NOT IMPLEMENTED]

다음은 현재 코드 기준 미구현이다.

- sector / station map
- entry / pressure / lock
- run kit
- permit
- orbit
- glyph
- echo
- sigil
- risk grade
- trial
- archive
- stats
- profile-level unlock 구조
- final DB-backed persistence layer

[V4_DECISION]

위 항목들은 V4 target에서 다루되, current baseline으로 선언하지 않는다.
