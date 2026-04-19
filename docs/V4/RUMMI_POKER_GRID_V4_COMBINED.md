# Rummi Poker Grid V4 Combined Documentation

이 파일은 `rummi_poker_grid_design_docs_v4/` 문서 세트를 하나로 합친 버전이다. 원본 파일 단위 문서가 우선이다.



---

# Rummi Poker Grid Design Docs V4

> 문서 성격: V4 기준 문서 세트 / Current Baseline + Target Product Design + Migration Plan
> 코드 반영 상태: mixed
> Truth source priority:
> 1. 실제 `lib/` 코드
> 2. `docs/current_system/CURRENT_SYSTEM_OVERVIEW.md`
> 3. `docs/current_system/CURRENT_CODE_MAP.md`
> 4. `docs/current_system/CURRENT_TO_V4_GAP.md`
> 5. `docs/archive/`
> 6. V4의 `[TARGET]`, `[FUTURE]`, `[EXPERIMENT]` 섹션
>
> 핵심 정책: `[CURRENT]`로 표시된 항목만 현재 빌드 기준이다. `[TARGET]`은 장기 제품 목표이고, `[FUTURE]`는 이후 확장 후보이며, `[EXPERIMENT]`는 기본값이 아닌 실험안이다.

## 1. V4의 목적

V4는 V3처럼 현재 구현과 미래 목표가 같은 강도로 섞이는 문제를 막기 위한 기준 문서 세트다.

V4의 한 문장 정의는 다음이다.

> 현재 작동하는 `즉시 확정 + 부분 줄 평가 + overlap + contributor 제거` 보드 전투 프로토타입을, 장기 제품 구조로 안전하게 흡수 확장하기 위한 기준 문서.

V4는 새 게임을 다시 설계하는 문서가 아니다. 현재 코드가 이미 확보한 코어 루프를 보호하면서, 장기 구조인 Station, Market, Archive, Profile, Trial, Risk Grade 등을 단계적으로 얹기 위한 문서다.

## 2. V4에서 즉시 고정하는 결정

| 항목 | V4 결정 |
|---|---|
| 전투 코어 | 현재 구현을 V4의 핵심 규칙으로 채택한다. |
| 보드 | 5x5 유지. |
| 평가 라인 | 12줄 유지. |
| 부분 줄 평가 | 유지. 5칸 강제 완성으로 되돌리지 않는다. |
| 즉시 확정 | 유지. |
| Overlap | 유지. 기본 상수 `alpha = 0.3`, `cap = 2.0`. |
| 제거 규칙 | 줄 전체가 아니라 contributor만 제거한다. |
| One Pair | V4 기본 규칙에서도 0점 dead line으로 유지한다. |
| Stage / Blind 코드명 | 당장 코드 리네임하지 않는다. |
| Station | 장기 UI/메타 용어로 도입한다. 코드 심볼 리네임은 별도 단계. |
| 저장 | 현재 active run save v2 + stageStartSnapshot을 보호한다. |
| DB | 장기 목표로 정의하되 즉시 교체하지 않는다. |
| Jester | 현재 curated common Jester 중심 구조를 유지하고 Market/Content 계층으로 확장한다. |

## 3. V4에서 금지하는 즉시 변경

아래 항목은 V4 문서가 있어도 바로 코드 기본값으로 바꾸지 않는다.

- One Pair 10점화
- `Start Gold 6` 같은 장기 목표 경제 수치의 즉시 적용
- 30 Station 테이블 전체 확정
- Entry / Pressure / Lock의 즉시 런타임 강제 적용
- Drift / SQLite / IndexedDB로 active run save 즉시 교체
- `BlindState -> StationState`, `scoreTowardBlind -> scoreTowardStation` 같은 코드 심볼 일괄 리네임
- Jester ID 변경 또는 기존 저장 데이터와 맞지 않는 콘텐츠 ID 변경

## 4. 문서 라벨 규칙

| 라벨 | 의미 | 구현 근거 |
|---|---|---|
| `[CURRENT]` | 현재 코드가 실제로 구현한 기준 | 코드 / current docs |
| `[V4_DECISION]` | V4에서 기준으로 채택한 정책 | 현재 구현 + 설계 판단 |
| `[TARGET]` | 출시판 또는 중기 목표 | 구현 전 또는 부분 구현 |
| `[FUTURE]` | 이후 확장 후보 | 지금 구현 기준 아님 |
| `[MIGRATION]` | current에서 target으로 이동하는 절차 | PR 분해 기준 |
| `[EXPERIMENT]` | 기본값이 아닌 실험 ruleset | feature flag 필요 |
| `[WATCH]` | 코드와 문서, 의도 사이에 주의가 필요한 영역 | 검증 필요 |

## 5. 문서 구성

| 파일 | 역할 |
|---|---|
| `00_README.md` | V4 문서 읽는 법, 우선순위, 금지 규칙 |
| `01_CURRENT_BASELINE.md` | 현재 코드 기준 baseline |
| `02_CORE_COMBAT_RULES.md` | 전투 규칙, 평가, 확정, 제거, 만료 |
| `03_RUN_META_ECONOMY.md` | stage 기반 현재 루프와 Station 목표 구조 |
| `04_JESTER_MARKET_CONTENT.md` | 현재 Jester 구현과 장기 콘텐츠 체계 |
| `05_SAVE_CHECKPOINT_DATA.md` | active run save v2와 장기 데이터 구조 |
| `06_UI_UX_FLOW.md` | 현재 화면 흐름과 목표 UX |
| `07_TECHNICAL_ARCHITECTURE.md` | 현재 코드 경계와 목표 아키텍처 |
| `08_MIGRATION_ROADMAP.md` | PR 단위 이행 계획 |
| `09_TEST_QA_ACCEPTANCE.md` | 회귀 방지 테스트와 승인 조건 |
| `10_TERMINOLOGY_ALIAS.md` | 용어 정책과 코드 리네임 원칙 |
| `11_OPEN_DECISIONS.md` | 남은 결정사항과 실험 후보 |
| `12_CHANGELOG_FROM_V3.md` | V3 대비 V4 수정 원칙 |
| `V4_MASTER_SPEC.md` | 위 내용을 하나로 묶은 실행 기준 요약 |

## 6. 소스 입력

V4 작성 기준으로 사용한 실제 저장소 입력은 다음이다.

- `lib/`
  - 현재 Flutter 앱 코드 전체
- `docs/current_system/CURRENT_SYSTEM_OVERVIEW.md`
- `docs/current_system/CURRENT_CODE_MAP.md`
- `docs/current_system/CURRENT_TO_V4_GAP.md`
- `START_HERE.md`
- `docs/archive/`
  - 기존 설계/구현 배경 문서 묶음
- `docs/V4/rummi_poker_grid_design_docs_v4/`
  - V4 원본 파일 단위 문서 세트

## 7. 입력 파일 / 디렉터리 스냅샷 해시

디렉터리는 압축 파일이 아니라 **정렬된 파일 목록 기반 manifest hash**로 기록한다.

| 입력 | SHA-256 |
|---|---|
| `lib/` manifest | `a46a846294fd726a9dcb7db3f68393d740d33e0a191a12098c97afd5f12270c5` |
| `docs/archive/` manifest | `84207b219ef8ca03d1847de7fd63459e5033bf2d39c85cd747834448effa4e55` |
| `docs/V4/rummi_poker_grid_design_docs_v4/` manifest | `bfdd2ce05a1d385142cdd8a5915c3ae5ff2e336b7281c1a2da4817532ee979d8` |
| `START_HERE.md` | `acbb8f5937f2bde709661c03c79719f3fd43d0013fc0119e7f3df0aea701ef91` |
| `docs/current_system/CURRENT_CODE_MAP.md` | `40fb5b2269d21fc28c8c00a70d42c668242fe17e6c3991473307ee57a0a5fe7a` |
| `docs/current_system/CURRENT_SYSTEM_OVERVIEW.md` | `a087e8c397374a930f55214baf0de2ff968e850beb0c0e5a8e7130bd4eec32e6` |
| `docs/current_system/CURRENT_TO_V4_GAP.md` | `313376c89896eba0ba753ab5fc11b3e4c88e8181b5a0cbecab5859e050df666e` |
| `docs/archive/rummi_poker_grid_gdd.md` | `ac774448caf286ce0d91ee18bd793da53330e468a8005f3c11c179eb91c1e202` |
| `docs/archive/rummi_poker_grid_game_logic.md` | `579be5edcaee84b62c3aafbdc6851d0d695958904e70d75846eb2b3e8dec44f7` |
| `docs/archive/save_resume_architecture.md` | `550be359831548581e4f6172a8d9fbb4e8e920afd811033efd097872c6cacd36` |


---

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


---

# 02. Core Combat Rules

> 문서 성격: baseline + target
> 코드 반영 상태: current combat implemented
> 핵심 정책: 전투 코어는 V4에서 가장 먼저 보호한다.

## 1. 전투 정체성

[V4_DECISION]

Rummi Poker Grid의 전투 정체성은 다음 네 가지다.

1. 부분 줄 평가
2. 즉시 확정
3. overlap 보너스
4. contributor 제거

이 네 가지는 V4의 핵심 규칙으로 고정한다. 이후 Station, Risk, Market, Archive를 추가해도 이 전투 코어는 기본 ruleset에서 유지한다.

## 2. Board / Line

[CURRENT]

- Board size: 5 x 5
- 평가 라인: 12줄
  - row 5
  - column 5
  - main diagonal 1
  - anti diagonal 1
- 빈 칸이 있어도 현재 놓인 타일만으로 라인을 평가한다.
- 라인에 타일이 하나도 없으면 평가하지 않는다.

## 3. Tile / Deck

[CURRENT]

- 색: red, blue, yellow, black
- 숫자: 1~13
- 물리 타일 identity: `Tile(color, number, id)`
- 덱 크기: `4 * 13 * copiesPerTile`
- 기본 copiesPerTile: 1
- 같은 로직으로 copiesPerTile 2, 즉 104장 구조도 대응 가능하다.

[V4_DECISION]

V4에서도 `copiesPerTile` 기반 구조를 유지한다. 문서나 UI에서 “52장 고정”으로 표현하지 않는다.

## 4. Hand Rank / Score

[CURRENT]

| Rank | Base Score | Dead Line | 확정 후보 |
|---|---:|---|---|
| High Card | 0 | 예 | 아니오 |
| One Pair | 0 | 예 | 아니오 |
| Two Pair | 25 | 아니오 | 예 |
| Three of a Kind | 40 | 아니오 | 예 |
| Straight | 70 | 아니오 | 예 |
| Flush | 50 | 아니오 | 예 |
| Full House | 80 | 아니오 | 예 |
| Four of a Kind | 100 | 아니오 | 예 |
| Straight Flush | 150 | 아니오 | 예 |

[V4_DECISION]

One Pair는 V4 기본 ruleset에서도 dead line이다. One Pair를 점수화하면 초반 템포, dead line 압박, overlap loop, Jester 밸런스가 모두 바뀌므로 기본값으로 도입하지 않는다.

[EXPERIMENT]

One Pair 10점 ruleset은 나중에 `RummiRulesetConfig.enablePairScoring` 같은 feature flag로만 검증한다.

## 5. Partial Line Evaluation

[CURRENT]

실제 코드 기준 가능한 판정:

| Occupied Count | 가능한 scoring rank |
|---:|---|
| 0 | 없음 |
| 1 | 없음 |
| 2 | 없음. One Pair는 가능하지만 dead line |
| 3 | Three of a Kind |
| 4 | Two Pair, Three of a Kind, Four of a Kind |
| 5 | Two Pair 이상 전체 족보 |

세부 처리:

- 4장 `7,7,7,12`는 Three of a Kind로 점수화 가능하다.
- 이 경우 contributor는 `7,7,7` 세 장이고 `12`는 남는다.
- 4장 `7,7,8,8`은 Two Pair이며 네 장 모두 contributor다.
- 5장 `7,7,7,12,13`은 Three of a Kind이며 contributor는 세 장이다.

## 6. Straight

[CURRENT]

Straight는 5장 전용이다.

허용:

- 일반 연속: `1-2-3-4-5`부터 `9-10-11-12-13`
- high-Ace wheel: `10-11-12-13-1`

불허:

- 중복 랭크 포함 straight
- 4장 straight preview의 scoring 처리
- partial straight bonus

[TARGET]

Station modifier나 Jester로 partial straight preview를 추가할 수는 있으나, 기본 hand evaluator의 rank로 넣지 않는다.

## 7. Flush

[CURRENT]

Flush는 5장 전용이다.

- 5장이 모두 같은 색이면 Flush
- Straight와 동시에 성립하면 Straight Flush
- 2~4장 같은 색은 기본 ruleset에서 scoring rank가 아니다.

## 8. Confirm Candidate

[CURRENT]

확정 후보 조건:

```text
candidate = evaluation.isDeadLine == false
```

즉, base score가 있는 rank만 확정 후보다.

[V4_DECISION]

V4 문서에서는 “확정 후보”와 “평가 결과”를 분리해서 쓴다.

- 평가 결과: High Card / One Pair도 포함
- 확정 후보: Two Pair 이상
- 제거 후보: 확정 후보의 contributor cell union

## 9. Contributor

[CURRENT]

Contributor는 실제 족보 성립에 필요한 타일만 뜻한다.

| Rank | Contributor |
|---|---|
| Two Pair | pair를 이루는 4장 |
| Three of a Kind | 같은 rank 3장 |
| Straight | 5장 전체 |
| Flush | 5장 전체 |
| Full House | 5장 전체 |
| Four of a Kind | 같은 rank 4장 |
| Straight Flush | 5장 전체 |

[V4_DECISION]

Jester 조건, face card 조건, scoring tile count 조건, 제거는 모두 contributor 기반 `scoringTiles`를 기준으로 한다.

## 10. Overlap

[CURRENT]

하나의 contributor cell이 여러 scoring line에 기여하면 overlap으로 간주한다.

공식:

```text
lineMultiplier = min(1 + alpha * (peakContributionCount - 1), cap)
alpha = 0.3
cap = 2.0
```

현재 line별 multiplier는 해당 line의 contributor cell 중 가장 높은 contribution count를 사용한다.

예:

| peakContributionCount | multiplier |
|---:|---:|
| 1 | 1.0 |
| 2 | 1.3 |
| 3 | 1.6 |
| 4 | 1.9 |
| 5+ | 2.0 cap |

[V4_DECISION]

Overlap은 V4의 전략 핵심으로 유지한다. 다만 장기적으로 alpha/cap은 Station modifier나 difficulty scaling으로 조정할 수 있다.

## 11. Jester Score Composition

[CURRENT]

라인 점수는 현재 다음 순서로 합성된다.

1. rank base score
2. overlap multiplier 적용 후 round
3. Jester별 chips/mult/xmult 적용
4. 최종 line score 계산

Jester compose 식:

```text
chips = baseScore + chipsBonus
if chips <= 0: finalScore = 0
multFactor = 1 + multBonus / 20.0
finalScore = round(chips * multFactor * xmultBonus)
```

[V4_DECISION]

One Pair처럼 baseScore가 0인 dead line은 Jester 보정으로 점수화하지 않는다. 확정 후보에 올라온 line에만 Jester를 적용한다.

## 12. Confirm Transaction

[CURRENT]

전투 logic 관점의 confirm transaction:

```text
scan 12 lines
→ evaluate each non-empty line
→ filter scoring candidates
→ build contributor cells
→ count overlap
→ calculate line scores
→ apply equipped Jesters in slot order
→ produce line breakdowns
→ remove contributor cell union
→ move removed tiles to eliminated
→ return score and clear signal
```

UI / Provider 관점:

```text
GameView confirm button
→ GameSessionNotifier.confirmLines()
→ session.confirmAllFullLines(applyScoreToBlind: false)
→ runProgress.onConfirmedLines(...)
→ settlement animation
→ line별 applyConfirmedLineScore(...)
→ save
→ stage clear flow if target met
```

[WATCH]

메서드명 `confirmAllFullLines`는 더 이상 실제 의미와 맞지 않는다. V4 migration에서는 `confirmScoringLines`를 새 이름으로 추가하고 기존 메서드는 compatibility wrapper로 유지하는 것이 좋다.

## 13. Discard

[CURRENT]

Board discard:

- board tile 제거
- board discard 1 소모
- 제거 타일은 `eliminated`로 이동
- 손패에 여유가 있으면 덱에서 1장 보충
- `green_jester` 등 discard 반응 stateful Jester가 갱신될 수 있음

Hand discard:

- 선택한 손패 타일 제거
- hand discard 1 소모
- 제거 타일은 `eliminated`로 이동
- 덱에서 1장 보충
- discard 반응 stateful Jester가 갱신될 수 있음

## 14. Expiry

[CURRENT]

현재 만료 신호:

1. `boardFullAfterDcExhausted`
   - board discard가 0 이하
   - board tile count가 25
2. `drawPileExhausted`
   - deck empty
   - hand empty
   - confirm 가능한 scoring line 없음

[TARGET]

V4에서 검토할 board lock 정책:

```text
board lock expiry = board full && boardDiscard == 0 && scoringCandidateLines.isEmpty
```

이 target은 현재 코드와 다르므로 즉시 바꾸지 않는다. 먼저 테스트와 UX 결정이 필요하다.

## 15. Balance Direction

[TARGET]

전투 밸런스는 다음 축으로 조정한다.

- target score curve
- board / hand discard 수
- Jester shop price
- shop offer pool
- overlap alpha/cap
- Station modifier
- deck copiesPerTile

[V4_DECISION]

One Pair 점수화로 난이도를 낮추는 접근은 기본 밸런스 조정 수단으로 사용하지 않는다. dead line 압박은 현재 게임의 중요한 감각이다.


---

# 03. Run Meta & Economy

> 문서 성격: current baseline + target product structure
> 코드 반영 상태: current stage loop implemented, Station target not implemented
> 핵심 정책: 현재 stage loop를 보호하고, Station은 장기 메타 구조로 단계 도입한다.

## 1. 현재 Run Loop

[CURRENT]

현재 런은 단순 stage 기반 루프다.

```text
Title
→ New Run / Continue
→ Stage Battle
→ Score Confirm
→ Stage Clear
→ Cash-out
→ Jester Shop
→ Next Stage
→ 반복
```

현재 구현된 요소:

- stage index
- target score
- board / hand discard
- stage clear reward
- Jester shop
- next stage advance
- stageStartSnapshot restart

현재 없는 요소:

- sector map
- station map
- entry / pressure / lock
- run kit
- risk grade
- trial
- archive / stats

## 2. Current Economy

[CURRENT]

| 항목 | 값 |
|---|---:|
| startingGold | 10 |
| stageClearGoldBase | 10 |
| remainingBoardDiscardGoldBonus | +5 |
| remainingHandDiscardGoldBonus | +2 |
| shopBaseRerollCost | 5 |
| reroll increment | +1 |
| shopOfferCount | 3 |
| maxJesterSlots | 5 |

Stage target score:

```text
stage 1 = 300
stage n = floor(300 * 1.6^(n - 1))
```

[WATCH]

이 수치들은 프로토타입 밸런스다. V4 target 경제를 설계할 수는 있지만, 현재 코드 기본값을 문서만으로 바꾸지 않는다.

## 3. Current Cash-out

[CURRENT]

Stage clear 후 cash-out은 다음을 합산한다.

```text
totalGold = stageClearGoldBase
          + remainingBoardDiscards * 5
          + remainingHandDiscards * 2
          + economyJesterBonuses
```

Economy Jester 현재 지원:

- `egg`
- `golden_jester`
- `delayed_gratification`

## 4. Stage에서 Station으로의 개념 전환

[TARGET]

V4 장기 제품 구조에서는 `stage`를 플레이어-facing 개념으로 `Station`에 흡수한다.

개념 매핑:

| Current | V4 Target | 설명 |
|---|---|---|
| Stage | Station | 하나의 전투 노드 |
| Blind | Station Objective | 목표 점수 + 자원 상태 |
| scoreTowardBlind | scoreTowardStation | 해당 전투 목표에 누적한 점수 |
| board/hand discard | Station Resources | 전투 내 제한 자원 |
| stageStartSnapshot | Station Checkpoint | 현재 Station 시작점 복원 |
| cash-out | Station Reward Settlement | 클리어 후 보상 정산 |
| shop | Market Stop | Station 사이 보상/구매 구간 |

[MIGRATION]

용어 전환 순서:

1. 문서 alias 추가
2. UI 텍스트 일부를 Station으로 전환
3. 저장 DTO와 코드명은 유지
4. 테스트 강화
5. 별도 refactor PR에서 내부 코드명 변경 검토

## 5. Sector / Station Structure

[TARGET]

장기 run은 다음 구조를 가진다.

```text
Run
└─ Sector[]
   └─ Station[]
      ├─ Combat Objective
      ├─ Station Modifiers
      ├─ Reward Rules
      └─ Market/Rest/Choice 연결
```

단, V4에서는 station 개수와 sector 개수를 확정하지 않는다. V3의 30 Station은 후보 테이블로 보존할 수 있지만, V4 기본 구현 지시로 박지 않는다.

## 6. Entry / Pressure / Lock

[TARGET]

Station modifier는 세 축으로 나눌 수 있다.

### Entry

전투 시작 전 조건 또는 비용.

예:

- 시작 손패 제한
- 특정 Jester 슬롯 잠금
- 시작 board discard 감소
- 특정 색/숫자 타일 선배치
- 입장 보상 또는 입장 패널티

### Pressure

전투 중 지속되는 압박.

예:

- target score 증가
- 특정 rank 점수 감소
- 확정 횟수 제한
- 일정 confirm 후 discard 감소
- deck draw 제한

### Lock

강한 제한 또는 해금 조건.

예:

- 특정 line 사용 불가
- 대각선만 bonus
- 특정 Station은 특정 Permit 필요
- 특정 Market 선택지 잠금

[MIGRATION]

Entry / Pressure / Lock은 전투 엔진 내부에 직접 끼워 넣지 말고, `StationRuleModifier` 형태로 `RummiRulesetConfig` 또는 run meta layer에서 주입한다.

## 7. Risk Grade / Trial

[TARGET]

Risk Grade는 run 시작 전 난이도 선택 계층이다.

가능한 조정 축:

- target score multiplier
- starting gold
- discard count
- shop price multiplier
- station modifier 등장률
- checkpoint 제한
- reward multiplier

Trial은 특별 규칙 run이다.

예:

- 특정 Jester pool만 사용
- hand size 변경
- copiesPerTile 변경
- Station modifier 고정
- 특정 scoring rank 금지 또는 bonus

[V4_DECISION]

Risk Grade와 Trial은 active run core가 안정화된 후 추가한다. 현재 baseline에는 없다.

## 8. Market Stop

[TARGET]

현재 shop은 Jester-only다. V4 target에서는 Market으로 확장한다.

Market 상품 후보:

- Jester
- Run Kit upgrade
- Permit
- Glyph
- Echo
- Sigil
- temporary consumable
- reroll / remove / upgrade service

[MIGRATION]

Market은 기존 `RummiRunProgress.shopOffers`를 깨지 않고 확장한다.

권장 순서:

1. 현재 Jester offer 유지
2. `MarketOffer` 추상 모델 추가
3. `JesterMarketOffer` adapter 추가
4. UI는 기존 shop card를 유지한 채 category badge만 추가
5. 이후 새 상품 타입 추가

## 9. Economy Target Policy

[TARGET]

경제 수치는 다음 순서로 잡는다.

1. 현재 프로토타입 수치를 baseline으로 기록
2. stage/station 목표 곡선 테스트 작성
3. run length 목표 결정
4. reward/cost 비율 산정
5. Station modifier 난이도와 함께 재밸런싱

[V4_DECISION]

최종 경제 수치는 V4 문서에서 확정하지 않는다. V4는 구조와 migration 절차를 확정한다.


---

# 04. Jester, Market & Content System

> 문서 성격: current baseline + target content architecture
> 코드 반영 상태: Jester current implemented, multi-content market not implemented
> 핵심 정책: 현재 Jester는 초기 제품의 중심축으로 유지하되, 장기 콘텐츠 계층과 분리 가능한 구조로 확장한다.

## 1. 현재 Jester 구현

[CURRENT]

현재 Jester 시스템은 `jester_meta.dart`에 집중되어 있다.

현재 책임:

- Jester 카드 모델
- JSON catalog load
- supported card filtering
- scoring effect 계산
- economy reward 계산
- stateful Jester 값 관리
- played hand count 관리
- shop offer 생성
- buy / sell / reroll
- stage target score 계산
- cash-out 계산

[WATCH]

현재 `jester_meta.dart`는 Jester, economy, run progress를 함께 품는다. 프로토타입에서는 적절하지만, V4 target에서는 분리가 필요하다.

## 2. Current Catalog

[CURRENT]

데이터 소스:

```text
data/common/jesters_common_phase5.json
```

현재 운영 카탈로그:

- common Jester 38종
- 상점 노출은 `isSupportedInCurrentRunMeta` 기준 필터링

지원 범주:

| 범주 | 현재 처리 |
|---|---|
| `chips_bonus` | onScore line scoring |
| `mult_bonus` | onScore line scoring |
| `xmult_bonus` | onScore line scoring |
| `scholar` | ace 기반 chips + mult 특수 처리 |
| `economy` | 일부 onRoundEnd 처리 |
| `stateful_growth` | 일부 card id 특수 처리 |

## 3. Current Scoring Jester Rules

[CURRENT]

Jester 점수 적용 기준:

- scoring candidate line에만 적용
- dead line에는 적용하지 않음
- contributor 기반 `scoringTiles`만 조건 판정에 사용
- 장착 슬롯 순서대로 순차 적용
- stateful 값은 slot index로 조회

Score context 현재 필드:

- discardsRemaining
- cardsRemainingInDeck
- ownedJesterCount
- maxJesterSlots
- stateValue
- currentHandPlayedCount

[WATCH]

`discardsRemaining`은 현재 board discard를 의미한다. hand discard까지 포함하는 조건이 필요하면 V4에서 context를 확장해야 한다.

## 4. Current Stateful Jester

[CURRENT]

현재 직접 처리되는 stateful Jester:

| ID | 현재 state 변화 |
|---|---|
| `supernova` | rank별 played count 기반 mult |
| `popcorn` | 초기 value, round end decay |
| `ice_cream` | 초기 value, confirm 후 감소 |
| `green_jester` | confirm 시 증가, discard 시 감소 |
| `ride_the_bus` | face card scoring 여부에 따라 증가/리셋 |

[V4_DECISION]

Stateful Jester는 slot index 기반 저장을 유지한다. 장기적으로 고유 instance id를 추가할 수 있지만, 기존 save와 호환되게 adapter가 필요하다.

## 5. Current Shop

[CURRENT]

현재 shop 특징:

- full-screen route
- Jester 중심 offer
- offer count 3
- reroll cost 5, reroll마다 +1
- 구매 시 ownedJesters에 추가
- 판매 시 baseCost 절반, 최소 1 gold
- owned id는 pool에서 제외
- test-only preferred offer path 존재

[WATCH]

검사용 상점 진입은 제품 빌드에서 제거 또는 debug flag 뒤로 숨겨야 한다.

## 6. V4 Content Layers

[TARGET]

V4 장기 콘텐츠는 다음 계층으로 나눈다.

| Content | 역할 | 현재 상태 |
|---|---|---|
| Jester | 전투 점수/경제/상태 보정 | partial implemented |
| Run Kit | run 시작 loadout / 초기 규칙 | not implemented |
| Permit | 콘텐츠/Station 접근 권한 | not implemented |
| Glyph | 특정 scoring 패턴/타일/라인 modifier | not implemented |
| Orbit | run 전체 궤도형 modifier / 장기 조건 | not implemented |
| Echo | 과거 run 또는 이전 Station 결과 반영 | not implemented |
| Sigil | 강한 제약과 강한 보상 | not implemented |
| Risk Grade | 난이도/보상 계층 | not implemented |
| Trial | 특수 룰 challenge run | not implemented |
| Archive | collection / stats / history | not implemented |

[V4_DECISION]

위 계층은 target architecture로 정의하되, 현재 build에 구현된 것으로 쓰지 않는다.

## 7. Unified Content Schema Target

[TARGET]

장기적으로 콘텐츠는 공통 meta를 가진다.

```text
ContentDefinition
- id
- type
- displayNameKey
- descriptionKey
- rarity / tier
- tags
- unlockCondition
- marketEligibility
- effectDefinition
- version
```

Jester는 다음처럼 adapter 가능하다.

```text
RummiJesterCard -> ContentDefinition(type: jester)
```

[MIGRATION]

기존 Jester JSON을 즉시 갈아엎지 않는다. 먼저 adapter layer를 추가한다.

## 8. Market Offer Target

[TARGET]

현재 `RummiShopOffer`는 Jester 전용이다. V4 target에서는 다음 구조를 지향한다.

```text
MarketOffer
- offerId
- slotIndex
- category
- contentId
- price
- currency
- availabilityReason
- debugSource
```

초기 adapter:

```text
RummiShopOffer(card) -> MarketOffer(category: jester, contentId: card.id)
```

## 9. Content ID Policy

[V4_DECISION]

- 기존 Jester id는 저장 데이터와 연결되므로 변경하지 않는다.
- 표시 이름 변경은 localization key에서 처리한다.
- effectType 문자열은 adapter로 보존한다.
- 삭제 예정 카드는 catalog에서 숨기되, save restore를 위해 id lookup은 유지한다.
- `ownedJesterIds`에 저장된 id는 앞으로도 복원 가능해야 한다.

## 10. Future Jester Refactor

[MIGRATION]

권장 분리:

```text
jester_meta.dart
→ jester_card.dart
→ jester_catalog.dart
→ jester_effect_engine.dart
→ run_progress.dart
→ economy_config.dart
→ market_offer.dart
→ market_service.dart
```

단, 첫 PR에서 분리하지 않는다. 현재 프로토타입 안정성을 위해 테스트를 먼저 보강한다.


---

# 05. Save, Checkpoint & Data Architecture

> 문서 성격: current baseline + target persistence architecture
> 코드 반영 상태: active run save v2 implemented, DB/archive target not implemented
> 핵심 정책: 저장 구조는 회귀 비용이 가장 크므로 current save를 보호한다.

## 1. Current Save Summary

[CURRENT]

현재 저장은 단일 active run snapshot 중심이다.

구성:

- `GetStorage` payload 저장
- `flutter_secure_storage` device key
- Web에서는 device key도 `GetStorage` fallback
- HMAC-SHA256 signature
- `schemaVersion = 2`
- active scene 저장: `battle` / `shop`
- stageStartSnapshot 저장

Storage keys:

| Key | 의미 |
|---|---|
| `active_run_payload_v1` | JSON payload |
| `active_run_signature_v1` | HMAC signature |
| `save_device_key_v1` | device key |

[WATCH]

Key suffix는 v1이고 payload schema는 v2다. V4에서는 key version과 schema version을 분리해서 다룬다.

## 2. Current Runtime Save Model

[CURRENT]

```text
ActiveRunRuntimeState
- activeScene
- session
- runProgress
- stageStartSnapshot

ActiveRunStageSnapshot
- session
- runProgress
```

`stageStartSnapshot`은 현재 stage 시작점 복원을 위한 핵심 구조다.

## 3. Current Payload Schema

[CURRENT]

```text
ActiveRunSaveData
- schemaVersion
- savedAt
- activeScene
- session
- runProgress
- stageStartSession
- stageStartRunProgress
```

```text
SavedSessionData
- runSeed
- deckCopiesPerTile
- maxHandSize
- runRandomState
- blind
- deckPile
- boardCells
- hand
- eliminated
```

```text
SavedRunProgressData
- stageIndex
- gold
- rerollCost
- ownedJesterIds
- shopOffers
- statefulValuesBySlot
- playedHandCounts
```

```text
SavedShopOfferData
- slotIndex
- cardId
- price
```

## 4. Integrity Flow

[CURRENT]

저장:

```text
build ActiveRunSaveData
→ jsonEncode
→ ensure device key
→ HMAC-SHA256(payload, deviceKey)
→ write payload + signature
```

로드:

```text
read payload + signature
→ read device key
→ compare HMAC
→ decode JSON
→ schemaVersion check
→ restore session
→ restore runProgress via Jester catalog lookup
→ restore stageStartSnapshot
```

## 5. Continue / Invalid Save Flow

[CURRENT]

Title flow:

1. `inspectActiveRun()`
2. `none / available / invalid`
3. available이면 continue 또는 delete 선택
4. invalid이면 손상/호환 불가 안내 후 delete 선택
5. load 성공 시 `GameView`로 restoredRun 전달
6. activeScene이 `shop`이면 catalog load 후 shop resume

## 6. Restart Semantics

[CURRENT]

인게임 재시작은 run 전체 리셋이 아니다.

의미:

```text
현재 stage 시작 시점으로 복원
```

복원 대상:

- board
- hand
- deck pile
- eliminated
- runRandom state
- target score / scoreTowardBlind / discards
- gold
- owned Jesters
- shop offers
- stateful Jester values
- played hand counts

[V4_DECISION]

이 의미는 V4 target에서도 유지한다. Station 구조에서는 `StationCheckpoint`로 이름만 확장한다.

## 7. Target Domain Data Model

[TARGET]

V4 장기 저장 도메인은 다음으로 나눈다.

```text
ProfileState
- profileId
- settings refs
- unlocks
- collection
- archive summary

ActiveRunState
- runId
- runSeed
- rulesetVersion
- currentSectorIndex
- currentStationIndex
- activeScene
- combatState
- runProgress
- marketState
- checkpointRef

CheckpointState
- runId
- stationIndex
- combatSnapshot
- runProgressSnapshot
- createdAt

RunHistoryRecord
- runId
- startedAt
- endedAt
- result
- reachedStation
- scoreSummary
- ownedContentSummary

ArchiveState
- discoveredContentIds
- bestRuns
- stats
- trials
```

[V4_DECISION]

물리 저장 엔진은 지금 확정하지 않는다. 도메인 경계를 먼저 정하고, 구현 엔진은 단계적으로 선택한다.

## 8. Persistence Engine Policy

[V4_DECISION]

- 현재 active run save v2는 유지한다.
- Drift / SQLite / IndexedDB는 target persistence layer 후보일 뿐이다.
- DB 도입은 active run save를 즉시 대체하지 않는다.
- 먼저 read-only mirror 또는 archive-only 저장으로 도입한다.

[MIGRATION]

권장 순서:

1. current save golden test 추가
2. schemaVersion 2 restore test 추가
3. save corruption test 추가
4. `rulesetVersion` 필드 추가 검토
5. DB read model 도입
6. active run save와 DB mirror 병행
7. 불일치 검사
8. active run 저장 전환 여부 결정

## 9. Save Compatibility Rules

[V4_DECISION]

- 기존 `ownedJesterIds`는 계속 복원 가능해야 한다.
- Jester id는 삭제하지 않는다.
- `stageIndex`는 Station 전환 후에도 adapter로 해석 가능해야 한다.
- `blind` JSON은 이름을 바꾸기 전에 adapter를 둔다.
- `stageStartSession` / `stageStartRunProgress`는 Station checkpoint로 migration 가능해야 한다.
- 저장 데이터의 서명 검증 실패 시 자동 복구하지 않고 invalid 처리한다.

## 10. Save Schema Migration Strategy

[MIGRATION]

V4 schema migration은 다음 원칙을 따른다.

```text
old payload parse
→ version check
→ version-specific adapter
→ current runtime model restore
→ optional upgraded save write
```

새 schema 후보:

```text
schemaVersion = 3
- rulesetVersion
- runId
- currentNodeKind
- currentNodeIndex
- checkpointVersion
- contentCatalogVersion
```

단, schemaVersion 3은 V4 문서만으로 즉시 도입하지 않는다. 먼저 테스트가 필요하다.

## 11. Security Scope

[CURRENT]

현재 HMAC은 로컬 tamper detection 목적이다. 서버 검증이나 경쟁 리더보드 보안 모델은 아니다.

[TARGET]

향후 archive/stats가 서버와 연결될 경우:

- active run local save와 server profile sync를 분리
- local HMAC은 계속 tamper detection으로 유지
- server-authoritative economy를 도입할 경우 별도 protocol 필요

현재 V4 범위에서는 서버 저장을 확정하지 않는다.


---

# 06. UI / UX Flow

> 문서 성격: current baseline + target UX
> 코드 반영 상태: title/battle/shop/settings implemented, station/archive/trial target not implemented
> 핵심 정책: 현재 플레이 가능한 흐름을 깨지 않고, 장기 화면을 옆으로 확장한다.

## 1. Current Screens

[CURRENT]

현재 주요 화면:

- `TitleView`
- `GameView`
- `GameShopScreen`
- `SettingView`

공통 레이아웃:

- `PhoneFrameScaffold`
- 논리 크기 390 x 750
- portrait-first
- `StarryBackground`
- `RummikubTileCanvas` 기반 타일 렌더

## 2. Current Title Flow

[CURRENT]

```text
TitleView
├─ 이어하기
│  ├─ no save: 버튼 미표시 또는 동작 없음
│  ├─ available: continue/delete dialog
│  └─ invalid: corrupted save dialog
├─ 랜덤 시작
├─ 시드 시작
├─ 디버그 fixture 시작(debug only)
└─ 설정
```

[V4_DECISION]

Title flow는 현재 형태를 유지한다. Run Kit, Risk Grade, Trial은 새 런 시작 전 하위 화면으로 추가한다.

## 3. Current Battle Flow

[CURRENT]

```text
GameView
→ catalog load
→ battle ready
→ draw/place/discard
→ confirm
→ settlement animation
→ score apply line by line
→ stage clear if target met
→ cash-out sheet
→ shop route
→ next stage
```

UI 구성:

1. top HUD
2. Jester 5-slot strip
3. 5x5 board
4. hand/draw zone
5. bottom action buttons
6. settlement overlay
7. stage clear overlay
8. Jester detail overlay

## 4. Current Confirm UX

[CURRENT]

확정 가능한 contributor cell은 `scoringCellSet(session)`로 강조한다.

- dead line은 강조하지 않는다.
- scoring candidate의 contributor cell만 강조한다.
- 키커나 non-contributor는 강조하지 않는다.
- 정산 시 해당 contributor cell이 사라진다.

[TARGET]

V4 UX 개선 후보:

- line별 rank badge
- overlap multiplier badge
- Jester effect token animation
- dead line risk hint
- contributor vs remaining tile 시각 구분

## 5. Current Cash-out UX

[CURRENT]

Stage clear 후 cash-out sheet가 뜬다.

표시해야 하는 정보:

- stage index
- target score
- blind reward
- remaining board discard reward
- remaining hand discard reward
- economy Jester reward
- total gold
- current gold

[TARGET]

Station 전환 후에는 `Station Reward Settlement`로 표현할 수 있다.

## 6. Current Shop UX

[CURRENT]

Shop은 bottom sheet가 아니라 full-screen route다.

기능:

- 3개 offer 표시
- reroll
- buy
- owned Jester 표시
- selected Jester 상세
- sell
- next stage

[TARGET]

Market 확장 후에는 다음 category를 표시한다.

- Jester
- Upgrade
- Permit
- Glyph
- Echo
- Service

단, 기존 Jester shop UX를 먼저 유지한다.

## 7. Target Product Flow

[TARGET]

장기 제품 UX:

```text
Title
├─ Continue
├─ New Run
│  ├─ Run Kit Select
│  ├─ Risk Grade Select
│  └─ Start
├─ Trial
├─ Archive
├─ Settings
└─ Credits / Info

Run
├─ Station Map
├─ Station Entry Preview
├─ Battle
├─ Settlement
├─ Market / Reward
└─ Next Station

Archive
├─ Collection
├─ Jester Database
├─ Run History
├─ Stats
└─ Trial Records
```

[V4_DECISION]

이 target flow는 현재 build의 필수 구현이 아니다. Migration 단계에 따라 도입한다.

## 8. UI Terminology

[MIGRATION]

UI 용어 전환 우선순위:

1. 플레이어-facing 문구에서 `Stage`를 `Station`으로 전환할 수 있다.
2. 코드 내부 `stageIndex`, `RummiBlindState`, `scoreTowardBlind`는 유지한다.
3. save schema는 먼저 adapter를 둔다.
4. 모든 화면에서 용어가 안정화된 뒤 코드 rename을 검토한다.

## 9. Debug UX Policy

[CURRENT]

현재 debug 요소:

- debug hand size 1~3
- debug fixture menu
- shop inspect offers

[V4_DECISION]

Debug 동선은 개발에는 유지하되, release build에서는 다음 중 하나로 처리한다.

- `kDebugMode` 뒤로 숨김
- developer options로 이동
- QA build flavor 전용

## 10. Accessibility / Readability Target

[TARGET]

V4 UI 개선 방향:

- board tile readability 우선
- overlap/score feedback는 텍스트와 애니메이션 모두 제공
- color-only feedback 금지
- Jester effect 설명은 한 줄 요약 + 상세 패널 분리
- seed/run id 복사 기능 추가
- save invalid 메시지는 사용자가 선택할 수 있게 표시


---

# 07. Technical Architecture

> 문서 성격: current code map + target architecture
> 코드 반영 상태: current implemented, target refactor planned
> 핵심 정책: 현재 프로토타입을 보호하기 위해 한 PR에서 한 축만 바꾼다.

## 1. Current Layers

[CURRENT]

현재 코드는 다음 계층으로 읽는다.

```text
lib/logic/rummi_poker_grid/
  순수 전투 로직에 가까운 계층

lib/logic/rummi_poker_grid/jester_meta.dart
  Jester + economy + run progress 복합 계층

lib/providers/features/rummi_poker_grid/
  Riverpod orchestration 계층

lib/views/
  UI orchestration + navigation + save trigger 계층

lib/services/
  persistence / debug fixture / platform service 계층
```

## 2. Current Core Boundaries

[CURRENT]

| 파일 | 현재 책임 |
|---|---|
| `tile.dart` | 타일 값 객체 |
| `poker_deck.dart` | 덱 생성, 셔플, 스냅샷 |
| `board.dart` | 5x5 cell storage |
| `hand_rank.dart` | rank enum, score, dead line |
| `hand_evaluator.dart` | 라인 평가, contributor index |
| `rummi_poker_grid_engine.dart` | 12줄 평가 |
| `rummi_poker_grid_session.dart` | 전투 session 퍼사드 |
| `rummi_blind_state.dart` | 현재 전투 목표와 discard 자원 |
| `jester_meta.dart` | Jester/economy/run/shop |
| `active_run_save_service.dart` | active run save/load |
| `game_session_notifier.dart` | 전투 flow orchestration |
| `game_view.dart` | 전투 UI, 정산 시퀀스, 저장 호출 |

## 3. Current State Management

[CURRENT]

`GameSessionState`는 mutable `session`, mutable `runProgress`를 보관하고 `revision` 증가로 redraw를 유도한다.

장점:

- 프로토타입 속도가 빠르다.
- 기존 session 객체를 그대로 조작할 수 있다.
- save snapshot을 만들기 쉽다.

주의:

- pure immutable state는 아니다.
- state mutation 후 `revision` 누락 시 UI 갱신이 빠질 수 있다.
- 장기적으로 action/reducer 형태로 나눌 수 있다.

## 4. Target Domain Split

[TARGET]

V4 장기 구조는 다음처럼 분리한다.

```text
core/combat
- Tile
- Board
- Deck
- HandEvaluator
- LineEvaluator
- CombatSession
- ConfirmTransaction

core/ruleset
- RummiRulesetConfig
- ScoreTable
- ExpiryPolicy
- OverlapPolicy

core/run
- RunProgress
- StationProgress
- Checkpoint
- RewardSettlement

core/content
- ContentDefinition
- JesterDefinition
- MarketOffer
- EffectDefinition

core/effects
- JesterEffectEngine
- ModifierEngine
- StationModifierEngine

services/persistence
- ActiveRunSaveService
- SaveAdapter
- ArchiveRepository

providers
- GameSessionNotifier
- TitleNotifier
- SettingsNotifier

views
- Title
- Battle
- Market
- StationMap
- Archive
```

[MIGRATION]

이 구조는 한 번에 만들지 않는다. 먼저 adapter와 테스트를 추가한 뒤 파일 분리를 진행한다.

## 5. Ruleset Config Target

[TARGET]

V4에서 실험 규칙은 config로 분리한다.

```dart
class RummiRulesetConfig {
  final bool enablePairScoring;
  final bool enableStationTerminology;
  final bool enableEntryPressureLock;
  final bool enableRunKit;
  final bool enableArchive;
  final double overlapAlpha;
  final double overlapCap;
}
```

기본값:

```dart
const currentPrototypeRuleset = RummiRulesetConfig(
  enablePairScoring: false,
  enableStationTerminology: false,
  enableEntryPressureLock: false,
  enableRunKit: false,
  enableArchive: false,
  overlapAlpha: 0.3,
  overlapCap: 2.0,
);
```

[V4_DECISION]

ruleset config 도입 전까지 현재 코드 상수를 기본값으로 유지한다.

## 6. Confirm Transaction Refactor

[MIGRATION]

현재 `confirmAllFullLines`를 다음 구조로 점진 분리한다.

```text
ConfirmScoringLinesUseCase
- scan lines
- evaluate candidates
- compute overlap
- apply scoring effects
- produce removal set
- produce settlement result
```

권장 API:

```dart
ConfirmClearResult confirmScoringLines(...);

@Deprecated('Use confirmScoringLines. Kept for prototype compatibility.')
ConfirmClearResult confirmAllFullLines(...) => confirmScoringLines(...);
```

단, 현재 Provider와 UI가 의존하므로 한 PR에서 이름 변경과 로직 변경을 동시에 하지 않는다.

## 7. Jester Meta Refactor

[MIGRATION]

현재 `jester_meta.dart`는 크지만 작동한다. 분리 순서:

1. 테스트 보강
2. `RummiEconomyConfig` 분리
3. `RummiRunProgress` 분리
4. `RummiJesterCard` / `Catalog` 분리
5. `JesterEffectEngine` 분리
6. `MarketOffer` adapter 추가
7. 기존 import compatibility 유지

## 8. Persistence Refactor

[MIGRATION]

저장은 다음 원칙으로만 수정한다.

- schema 변경은 별도 PR
- HMAC verification 유지
- old save invalid 처리 유지
- save/load golden test 필수
- stageStartSnapshot equivalent 유지
- activeScene restore 유지

## 9. Naming Refactor Policy

[V4_DECISION]

코드명 rename은 마지막 단계다.

지금 유지:

- `RummiBlindState`
- `scoreTowardBlind`
- `confirmAllFullLines`
- `stageIndex`

나중에 검토:

- `StationState`
- `scoreTowardStation`
- `confirmScoringLines`
- `stationIndex`

[MIGRATION]

이름 변경은 save schema, provider, tests가 준비된 뒤 compatibility adapter와 함께 수행한다.

## 10. PR Safety Rule

[V4_DECISION]

한 PR에서 동시에 하지 말 것:

- 전투 룰 변경 + 저장 schema 변경
- 코드 rename + 경제 밸런스 변경
- DB 도입 + active run save 제거
- Jester refactor + catalog id 변경
- UI terminology 변경 + provider state 구조 변경

권장 단위:

1. docs only
2. tests only
3. pure logic only
4. provider orchestration only
5. UI copy only
6. persistence adapter only


---

# 08. Migration Roadmap

> 문서 성격: migration plan
> 코드 반영 상태: planned
> 핵심 정책: 현재 코어 프로토타입을 보존하며 V4 target을 단계 도입한다.

## 0. Migration Principle

[V4_DECISION]

이 프로젝트의 current code는 버릴 코드가 아니라 게임의 핵심 프로토타입이다. V4 migration은 rewrite가 아니라 흡수 확장이다.

## 1. Phase 0 — Docs Lock

[MIGRATION]

목표:

- V4 문서를 기준으로 current/target/future 혼선 제거
- V3의 즉시 구현 오해 차단
- 현재 baseline 고정

작업:

- V4 docs commit
- README에 source priority 명시
- Current baseline 문서 추가
- One Pair 0점 dead line 결정 명시
- save v2 보호 정책 명시

완료 조건:

- README만 읽어도 target 항목을 current로 오해하지 않는다.
- Station, DB, Pair scoring이 즉시 구현 지시가 아님이 명확하다.

## 2. Phase 1 — Regression Tests

[MIGRATION]

목표:

- 현재 전투 코어 보호
- 저장/재시작 보호
- Jester score context 보호

필수 테스트:

- One Pair는 0점 dead line
- One Pair는 확정 후보 아님
- 4장 Three of a Kind는 scoring candidate
- contributor만 제거
- kicker는 남음
- overlap alpha/cap 계산
- Jester는 contributor scoringTiles 기준
- stage clear score 반영
- board discard / hand discard 분리
- active run save/load
- stageStartSnapshot restart
- activeScene shop restore

완료 조건:

- 위 테스트가 실패하면 V4 migration 작업을 merge하지 않는다.

## 3. Phase 2 — Naming Compatibility

[MIGRATION]

목표:

- legacy 의미와 실제 의미 차이를 wrapper로 완화
- 대규모 rename 없이 다음 작업 준비

작업:

- `confirmScoringLines` 추가
- `confirmAllFullLines`는 wrapper로 유지
- docs/comments의 “full lines” 표현 정리
- `isDeadLine` comment mismatch 수정
- `gddCanClearLine` 사용 여부 점검

금지:

- `RummiBlindState` rename
- save field rename
- economy 수치 변경

## 4. Phase 3 — Ruleset Config Skeleton

[MIGRATION]

목표:

- V4 target 실험을 기본 ruleset과 분리

작업:

- `RummiRulesetConfig` 초안 추가
- currentPrototype 기본값 정의
- overlap alpha/cap config화 검토
- Pair scoring flag 추가하되 default false
- Expiry policy flag 추가하되 current behavior 유지

완료 조건:

- current tests가 그대로 통과한다.
- flag를 켜지 않으면 게임 동작이 바뀌지 않는다.

## 5. Phase 4 — Station Terminology UI-only

[MIGRATION]

목표:

- 플레이어-facing 용어만 Station 방향으로 실험

작업:

- HUD label `STAGE` -> `STATION` 실험
- cash-out 문구 수정
- shop next stage 문구 수정
- title copy 정리

금지:

- code symbol rename
- save schema rename
- stageIndex field 변경

완료 조건:

- 기존 save continue 가능
- stageStartSnapshot restart 가능

## 6. Phase 5 — Market Adapter

[MIGRATION]

목표:

- Jester shop을 Market 구조로 확장할 준비

작업:

- `MarketOffer` domain 추가
- `RummiShopOffer` -> `MarketOffer` adapter
- 기존 GameShopScreen은 Jester offer 계속 표시
- offer category badge 추가 가능

금지:

- 기존 Jester id 변경
- shop catalog 필터 제거
- 미지원 effectType의 무분별한 노출

## 7. Phase 6 — Checkpoint / Save Adapter

[MIGRATION]

목표:

- Station Checkpoint, profile/archive target으로 갈 길 확보

작업:

- current save v2 golden test
- `rulesetVersion` 저장 검토
- save adapter 계층 추가
- `ActiveRunStageSnapshot`을 target `CheckpointState`로 mapping하는 문서/코드 추가

금지:

- active run save 제거
- DB로 즉시 교체

## 8. Phase 7 — Station Modifier Prototype

[MIGRATION]

목표:

- Entry / Pressure / Lock을 전투 엔진 외부 modifier로 실험

작업:

- `StationDefinition` 추가
- `StationModifier` interface 추가
- targetScore multiplier 또는 discard modifier처럼 낮은 위험도 효과부터 도입
- UI preview 추가

금지:

- HandEvaluator 기본 규칙 직접 변경
- Pair scoring 기본값 변경

## 9. Phase 8 — Archive / Stats Read Model

[MIGRATION]

목표:

- active run save와 분리된 장기 기록 도입

작업:

- run end summary 정의
- local archive read model 추가
- stats screen 초안
- collection discovered id 저장

금지:

- active run restore 로직과 archive 저장을 강하게 결합

## 10. Phase 9 — Balance Pass

[MIGRATION]

목표:

- Station 구조가 붙은 뒤 경제/난이도 재조정

작업:

- target score curve 재검토
- starting gold 재검토
- discard reward 재검토
- Jester price/pool 조정
- risk grade별 multiplier 조정

금지:

- 테스트 없이 경제 수치 일괄 변경

## 11. Codex 작업 지시 템플릿

```text
작업 목표:
V4 migration의 [PHASE_NAME]만 수행한다.
현재 코드는 Rummi Poker Grid의 핵심 프로토타입이므로 재작성하지 않는다.

범위:
- 수정 허용: [FILES]
- 수정 금지: [FILES]

반드시 유지:
- 부분 줄 평가
- 즉시 확정
- One Pair = 0점 dead line
- contributor만 제거
- overlap alpha 0.3 / cap 2.0
- active run save v2
- stageStartSnapshot restart
- 기존 Jester id

완료 조건:
- 기존 behavior regression 없음
- save/load 호환 유지
- 테스트 추가 또는 기존 테스트 통과
- target 항목을 current로 선언하지 않음
```


---

# 09. Test, QA & Acceptance Criteria

> 문서 성격: QA baseline + migration acceptance
> 코드 반영 상태: planned test expansion
> 핵심 정책: V4 migration은 테스트 보호망 없이 시작하지 않는다.

## 1. Test Policy

[V4_DECISION]

V4 migration에서 테스트는 문서보다 강한 보호 장치다. 특히 다음 영역은 테스트 없이 수정하지 않는다.

- HandEvaluator
- confirm transaction
- contributor removal
- overlap
- Jester scoring
- active run save/load
- stageStartSnapshot restart
- shop buy/sell/reroll

## 2. Combat Logic Tests

[MIGRATION]

필수 케이스:

### Dead line

- 1장 line은 High Card, score 0, 확정 불가
- 2장 pair는 One Pair, score 0, 확정 불가
- 3장 pair + kicker는 One Pair, score 0, 확정 불가

### Partial scoring

- 3장 같은 rank는 Three of a Kind, score 40, 3장 제거
- 4장 `A,A,A,K`는 Three of a Kind, A 3장 제거, K 유지
- 4장 `A,A,K,K`는 Two Pair, 4장 제거
- 4장 `A,A,A,A`는 Four of a Kind, 4장 제거

### 5-card scoring

- Straight score 70
- Flush score 50
- Full House score 80
- Four of a Kind score 100, kicker 유지
- Straight Flush score 150
- `10-11-12-13-1` straight 인정

## 3. Confirm Transaction Tests

[MIGRATION]

필수 검증:

- 12줄 중 scoring candidate만 정산
- 여러 line이 동시에 성립하면 모두 정산
- contributor cell union만 제거
- 같은 타일이 두 line에 겹치면 한 번만 제거
- overlap multiplier line별 계산
- baseScoreSum, jesterBonusSum, scoreAdded 일관성
- stage clear signal이 target score 기준으로 계산

## 4. Overlap Tests

[MIGRATION]

필수 케이스:

| contribution count | expected multiplier |
|---:|---:|
| 1 | 1.0 |
| 2 | 1.3 |
| 3 | 1.6 |
| 4 | 1.9 |
| 5+ | 2.0 |

테스트는 round 후 line score도 확인한다.

## 5. Jester Tests

[MIGRATION]

필수 검증:

- Jester는 dead line에 적용되지 않는다.
- Jester는 contributor scoringTiles만 본다.
- face card 조건은 contributor에 있는 face card만 센다.
- scholar는 Ace contributor 기준으로 동작한다.
- slot order 적용이 안정적이다.
- stateful slot index가 save/load 후 유지된다.
- `green_jester` confirm/discard 변화
- `ride_the_bus` face card scoring 시 reset
- `ice_cream` confirm 후 감소
- `popcorn` round end decay
- `supernova` played hand count 참조

## 6. Deck Conservation Tests

[MIGRATION]

항상 유지해야 하는 불변식:

```text
deck.remaining + hand.length + boardTileCount + eliminated.length == totalDeckSize
```

검증 액션:

- draw
- place
- board discard
- hand discard
- confirm
- discardStageRemainder
- prepareNextBlind
- save/load 후 conservation

## 7. Save / Load Tests

[MIGRATION]

필수 검증:

- valid save restore
- invalid HMAC이면 invalid
- missing payload/signature 처리
- schemaVersion mismatch invalid
- activeScene battle restore
- activeScene shop restore
- stageStartSnapshot restore
- ownedJesterIds restore
- shopOffers restore
- statefulValuesBySlot restore
- playedHandCounts restore
- deckPile/boardCells/hand/eliminated restore
- runRandomState restore

## 8. Restart Tests

[MIGRATION]

필수 검증:

- current stage 중 액션 후 restart하면 stage 시작점으로 돌아간다.
- gold, owned Jesters, shopOffers, stateful values도 stage 시작점으로 돌아간다.
- restart는 run 전체 초기화가 아니다.
- game over retry는 stageStartSnapshot을 사용한다.

## 9. Provider / UI Flow Tests

[MIGRATION]

필수 검증:

- `GameSessionNotifier.confirmLines`가 result 반환
- confirm result가 없을 때 null
- applyConfirmedLineScore가 점수 반영
- prepareCashOut가 gold 반영
- openShop이 offers 생성
- buy/sell/reroll 동작
- advanceToNextStage가 stageStartSnapshot 갱신
- pendingResumeShop 처리

## 10. Manual QA Checklist

[MIGRATION]

새 build마다 최소 확인:

1. 새 랜덤 run 시작
2. 시드 run 시작
3. 타이틀에서 이어하기
4. 손상 save 삭제 flow
5. draw/place/confirm
6. One Pair 확정 불가
7. Three of a Kind 부분 확정 가능
8. overlap 시 점수 증가 표시
9. contributor만 사라지는지 확인
10. stage clear → cash-out → shop → next stage
11. shop에서 buy/sell/reroll
12. app background 후 복귀 save 유지
13. 현재 stage 재시작
14. game over retry

## 11. Merge Gate

[V4_DECISION]

다음 조건을 만족하지 않으면 V4 migration PR은 merge하지 않는다.

- current baseline 테스트 통과
- save/load 테스트 통과
- 기존 save 호환성 판단 명시
- 변경된 ruleset이 있으면 default false
- docs의 `[CURRENT]`와 코드가 불일치하지 않음
- 디버그 전용 기능이 release UI에 노출되지 않음


---

# 10. Terminology & Alias Policy

> 문서 성격: terminology policy
> 코드 반영 상태: current names retained
> 핵심 정책: 플레이어-facing 용어와 코드 심볼을 분리해서 단계 전환한다.

## 1. Naming Problem

[CURRENT]

현재 코드에는 prototype/legacy 용어가 남아 있다.

예:

- `stage`
- `blind`
- `scoreTowardBlind`
- `confirmAllFullLines`
- `discardsRemaining` alias

하지만 실제 게임 의미는 이미 다음에 가깝다.

- stage = 하나의 전투 노드
- blind = 해당 전투 목표와 자원 상태
- confirmAllFullLines = scoring line 즉시 확정

## 2. Alias Table

[V4_DECISION]

| Current Code Term | V4 Canonical Concept | 전환 정책 |
|---|---|---|
| Stage | Station | UI 먼저, 코드 나중 |
| Blind | Station Objective / Combat Objective | 코드 유지 |
| `RummiBlindState` | `StationCombatState` 후보 | rename 보류 |
| `scoreTowardBlind` | `scoreTowardStation` 후보 | save adapter 전까지 유지 |
| `confirmAllFullLines` | `confirmScoringLines` | wrapper 추가 후 점진 전환 |
| Board Discard | Board Discard | 유지 |
| Hand Discard | Hand Discard | 유지 |
| Jester | Jester | 유지 |
| Shop | Market | UI는 단계 전환, 내부는 유지 |
| Stage Start Snapshot | Station Checkpoint | 개념 전환, 저장 구조 보호 |

## 3. Current / UI / Target 구분

[MIGRATION]

| 층 | 지금 써도 되는 용어 | 비고 |
|---|---|---|
| 코드 내부 | stage, blind | 유지 |
| 저장 DTO | stageStartSession, blind | 유지 |
| 개발 문서 current | stage/blind + alias | 둘 다 표기 |
| 플레이어 UI | Stage 또는 Station | 단계 실험 가능 |
| target docs | Station, Station Objective | target 명칭 |

## 4. Code Rename Rules

[V4_DECISION]

코드 rename은 다음 조건 전까지 금지한다.

- save/load golden test 존재
- provider tests 존재
- activeScene restore tests 존재
- old save migration adapter 존재
- UI copy 전환 완료
- current-to-target alias가 문서화됨

금지 예:

```text
한 PR에서 RummiBlindState rename + save schema 변경 + Station economy 도입
```

허용 예:

```text
새 confirmScoringLines 메서드 추가 + 기존 confirmAllFullLines wrapper 유지
```

## 5. Documentation Phrase Rules

[V4_DECISION]

문서에서 다음 표현을 피한다.

- “현재 구현은 5장 완성을 기다린다.”
- “One Pair는 현재 10점이다.”
- “V4는 Drift/SQLite를 즉시 사용한다.”
- “Station 구조가 현재 구현되어 있다.”
- “Blind 이름은 즉시 제거한다.”

대신 다음처럼 쓴다.

- “현재는 부분 줄 평가와 즉시 확정을 사용한다.”
- “One Pair는 현재/V4 기본 모두 0점 dead line이다.”
- “DB 계층은 target이며 active run save v2를 즉시 대체하지 않는다.”
- “Station은 target 메타 용어이고 current code는 stage/blind 명칭을 유지한다.”

## 6. Player-facing Copy Target

[TARGET]

장기 UI 문구 예:

| Current UI | Target UI |
|---|---|
| Stage 1 | Station 1 |
| 목표 점수 | Station Goal |
| 보상 | Reward |
| 확정 | Confirm |
| 보드 버림 | Board Discard |
| 손패 버림 | Hand Discard |
| 상점 | Market |
| 다음 스테이지 | Next Station |

[V4_DECISION]

`Confirm`, `Board Discard`, `Hand Discard`, `Jester`는 게임 규칙 이해에 직접 중요하므로 무리하게 바꾸지 않는다.


---

# 11. Open Decisions & Experiments

> 문서 성격: decision log
> 코드 반영 상태: mixed
> 핵심 정책: 결정되지 않은 항목을 current처럼 쓰지 않는다.

## 1. 확정 결정

[V4_DECISION]

| 결정 | 상태 | 이유 |
|---|---|---|
| 현재 전투 코어 유지 | 확정 | 이미 playable loop가 작동함 |
| One Pair 0점 dead line 유지 | 확정 | dead line 압박과 현재 밸런스 보호 |
| contributor만 제거 | 확정 | V4 전투 정체성 |
| overlap 유지 | 확정 | 핵심 전략성 |
| active run save v2 보호 | 확정 | continue/restart 회귀 방지 |
| Station은 target 용어 | 확정 | 현재 stage loop와 장기 구조 연결 |
| 코드 심볼 rename 보류 | 확정 | save/provider/test 영향 큼 |

## 2. 아직 열려 있는 결정

### 2.1 Board Full Expiry

[WATCH]

현재:

```text
boardDiscard <= 0 && boardFull이면 boardFullAfterDcExhausted
```

검토 target:

```text
boardDiscard <= 0 && boardFull && scoringCandidateLines.isEmpty이면 expiry
```

질문:

- 보드가 꽉 찼지만 scoring line이 있으면 확정을 먼저 허용할 것인가?
- 현재 UI에서 game over dialog가 confirm 기회를 빼앗는가?
- 전략적으로 board full은 즉시 실패가 더 재미있는가, 아니면 scoring 기회가 남아야 하는가?

권장:

- 실험 flag로 검증한다.
- 현재 behavior를 즉시 바꾸지 않는다.

### 2.2 One Pair Scoring

[EXPERIMENT]

후보:

```text
One Pair = 10점
```

위험:

- 초반 난이도 급락
- dead line 개념 약화
- Pair 조건 Jester 폭발 가능성
- overlap pair loop 가능성
- target score curve 재조정 필요

결정:

- 기본 V4 ruleset에는 넣지 않는다.
- 실험 ruleset에서만 검증한다.

### 2.3 Station Count

[TARGET]

V3의 30 Station은 후보일 뿐이다.

열린 질문:

- 모바일 1 run 목표 시간이 몇 분인가?
- Station당 평균 전투 시간이 몇 분인가?
- Market 빈도는 얼마가 적절한가?
- Sector당 boss/finale가 필요한가?

결정:

- V4에서는 구조만 정의하고 숫자는 고정하지 않는다.

### 2.4 Economy Curve

[WATCH]

현재:

- startingGold 10
- stageClearGoldBase 10
- reroll 5
- stage target `300 * 1.6^(n-1)`

열린 질문:

- Station 구조에서 보상이 너무 빠르게 누적되는가?
- Jester 가격과 reward 비율이 맞는가?
- Risk Grade별 gold multiplier가 필요한가?

결정:

- 현재 값은 baseline으로 보존한다.
- target economy pass는 Station prototype 후 진행한다.

### 2.5 Jester Instance Identity

[WATCH]

현재 stateful 값은 slot index 기반이다.

장점:

- 단순함
- 현재 save와 잘 맞음

위험:

- Jester 이동/정렬/강화/edition 추가 시 slot 기반만으로 부족

Target:

- `ownedJesterInstanceId` 추가 후보
- 기존 `ownedJesterIds`와 adapter 필요

결정:

- 지금은 slot index 유지.
- content upgrade/edition 도입 전 instance id 설계.

### 2.6 Persistence Engine

[TARGET]

후보:

- current GetStorage + HMAC 유지
- Drift
- SQLite
- IndexedDB
- hybrid: active run snapshot + archive DB

결정:

- 엔진은 지금 확정하지 않는다.
- active run은 current 구조 유지.
- archive/stats부터 별도 저장소 도입 가능.

### 2.7 Flame Role

[WATCH]

현재 핵심 화면은 Flutter-first이고 Flame은 보조 연출 후보에 가깝다.

질문:

- 타일/보드 렌더를 Flame으로 옮길 필요가 있는가?
- 현재 Flutter 위젯 성능이 충분한가?
- 이펙트만 Flame/Canvas로 두는 게 맞는가?

결정:

- V4에서 Flame 전환을 기본 목표로 두지 않는다.
- UI polish와 effect 최적화 후 재검토.

## 3. Experiment Registry

[EXPERIMENT]

| 실험 | Default | 필요 테스트 |
|---|---|---|
| Pair scoring | off | combat balance, target score, Jester pair condition |
| Board full confirm grace | off | expiry UX, game over timing |
| Station terminology UI | off 또는 gradual | copy consistency, save unaffected |
| Market adapter | off 또는 compatibility | shop flow, buy/sell/reroll |
| Risk Grade | off | economy curve, reward multiplier |
| Station modifiers | off | ruleset isolation |

## 4. Known Code Notes

[WATCH]

- `HandEvaluation.isDeadLine` 주석은 “하이카드만”처럼 보이지만 실제 `isDeadLineRank`는 High Card와 One Pair를 dead line으로 처리한다. 주석 정리가 필요하다.
- `confirmAllFullLines` 이름은 현재 동작과 맞지 않는다. 실제로는 scoring candidate line 즉시 확정이다.
- `gddCanClearLine`은 현재 모든 rank에 true를 반환하지만 확정 후보 필터에는 `isDeadLine`이 쓰인다. 사용 의미 정리가 필요하다.
- `RummiBlindState.discardsRemaining`은 board discard alias다. hand discard와 혼동하지 않도록 문서화가 필요하다.


---

# 12. Changelog From V3

> 문서 성격: V3 -> V4 policy changelog
> 코드 반영 상태: docs-only
> 핵심 정책: V3의 방향성은 살리되, current/target 혼선을 제거한다.

## 1. V4가 V3에서 바로잡은 것

[V4_DECISION]

V3의 문제는 방향성이 아니라 권한 구조였다. V3에는 현재 구현과 미래 목표가 같은 강도로 선언되어 있어, 다음 개발 세션에서 잘못된 코드 변경을 유도할 수 있었다.

V4는 다음을 바로잡는다.

| 영역 | V3 위험 | V4 수정 |
|---|---|---|
| 문서 권한 | target을 즉시 구현 기준처럼 표현 | `[CURRENT]`, `[TARGET]`, `[FUTURE]`, `[EXPERIMENT]` 분리 |
| One Pair | 10점 current처럼 읽힐 위험 | V4 기본은 0점 dead line |
| Station | 30 Station 확정처럼 읽힘 | 구조 target, 숫자는 미확정 |
| Entry/Pressure/Lock | current 전제처럼 읽힘 | Station modifier target |
| 저장 | Drift/SQLite가 즉시 기준처럼 읽힘 | current active run save v2 보호 |
| 코드 rename | StationState 등 즉시 rename 위험 | UI-first, code rename later |
| Migration | 오래된 5장 완성 프로토타입에서 출발하는 듯함 | 현재 즉시 확정 build에서 출발 |
| 콘텐츠 | Run Kit/Permit/Glyph 등을 current처럼 읽힘 | content layers target으로 격리 |

## 2. One Pair 정책 변경

[V4_DECISION]

V4는 One Pair를 0점 dead line으로 고정한다.

이유:

- 현재 코드와 일치한다.
- dead line 압박을 유지한다.
- contributor 제거 전략을 보호한다.
- Jester pair condition 폭발을 막는다.
- target score curve 재작업을 피한다.

One Pair 10점은 별도 실험이다.

## 3. Run Structure 정책 변경

[V4_DECISION]

V4는 현재 stage loop를 인정한다.

현재:

```text
stage + cash-out + Jester shop + next stage
```

Target:

```text
sector + station + market + archive
```

전환은 개념/UX부터 진행하고 코드 rename은 나중이다.

## 4. Save 정책 변경

[V4_DECISION]

V4는 현재 save를 제품 안정성의 핵심으로 본다.

현재 save:

- active run snapshot
- GetStorage
- HMAC
- schemaVersion 2
- stageStartSnapshot

Target save:

- profile
- active run
- checkpoint
- run history
- archive
- stats

단, target save는 current save를 즉시 대체하지 않는다.

## 5. Content 정책 변경

[V4_DECISION]

V4는 Jester 중심 current를 인정하고, 장기 content layer를 target으로 둔다.

현재:

- curated common Jester 38종
- current scoring/economy/stateful subset
- Jester-only shop

Target:

- Jester
- Run Kit
- Permit
- Glyph
- Orbit
- Echo
- Sigil
- Risk Grade
- Trial
- Archive

## 6. Implementation Policy 변경

[V4_DECISION]

V4 기준 구현 순서:

```text
docs lock
→ regression tests
→ compatibility wrapper
→ ruleset config
→ UI terminology
→ market adapter
→ save adapter
→ station modifier
→ archive/stats
→ balance pass
```

V3처럼 큰 target 문서를 근거로 한 번에 code rewrite하지 않는다.


---

# Rummi Poker Grid V4 Master Spec

> 문서 성격: master spec
> 코드 반영 상태: current baseline + target roadmap
> 사용법: 구현자는 이 문서를 먼저 읽고, 세부 항목은 개별 V4 문서를 참조한다.

## 1. V4 정의

Rummi Poker Grid V4는 “현재 작동하는 즉시 확정 보드 전투 프로토타입을 장기 제품 구조로 흡수 확장하기 위한 기준”이다.

V4는 current build를 부정하지 않는다. 현재 build는 이미 다음 핵심을 확보했다.

- 5x5 보드
- 12라인 평가
- 부분 줄 평가
- 즉시 확정
- One Pair 0점 dead line
- overlap 보너스
- contributor만 제거
- Jester 점수 보정
- cash-out
- Jester shop
- next stage
- active run save/load
- stageStartSnapshot restart

## 2. V4 기본 규칙

| 항목 | V4 기본값 |
|---|---|
| Board | 5 x 5 |
| Lines | 12 |
| Deck | `4 * 13 * copiesPerTile` |
| copiesPerTile | 1 |
| Hand size | 기본 1, debug 1~3 |
| Board discard | 4 |
| Hand discard | 2 |
| Confirm | scoring candidate line 즉시 확정 |
| Removal | contributor cell union만 제거 |
| Dead line | High Card, One Pair |
| Overlap | alpha 0.3, cap 2.0 |
| Stage loop | current 유지 |
| Save | active run save v2 유지 |

## 3. Score Table

| Rank | Score | V4 의미 |
|---|---:|---|
| High Card | 0 | dead line |
| One Pair | 0 | dead line |
| Two Pair | 25 | scoring |
| Three of a Kind | 40 | scoring |
| Flush | 50 | scoring |
| Straight | 70 | scoring |
| Full House | 80 | scoring |
| Four of a Kind | 100 | scoring |
| Straight Flush | 150 | scoring |

V4 기본 ruleset에서 One Pair는 계속 0점이다.

## 4. Confirm Flow

```text
Player taps Confirm
→ evaluate 12 lines
→ filter Two Pair or better
→ collect contributor cells
→ compute overlap contribution count
→ apply overlap multiplier
→ apply equipped Jesters by slot order
→ create line breakdowns
→ remove contributor union
→ move removed tiles to eliminated
→ settlement animation
→ apply line scores
→ if target met: cash-out → shop → next stage
→ save
```

## 5. Current Code Anchors

| Anchor | 파일 |
|---|---|
| Combat session | `lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart` |
| Hand rank | `lib/logic/rummi_poker_grid/hand_rank.dart` |
| Hand evaluation | `lib/logic/rummi_poker_grid/hand_evaluator.dart` |
| Board scan | `lib/logic/rummi_poker_grid/rummi_poker_grid_engine.dart` |
| Run/economy/Jester | `lib/logic/rummi_poker_grid/jester_meta.dart` |
| Save | `lib/services/active_run_save_service.dart` |
| Provider orchestration | `lib/providers/features/rummi_poker_grid/game_session_notifier.dart` |
| Runtime UI | `lib/views/game_view.dart` |

## 6. V4 Target Structure

장기 target:

```text
Run
└─ Sector[]
   └─ Station[]
      ├─ Entry
      ├─ Pressure
      ├─ Lock
      ├─ Combat Objective
      ├─ Reward Settlement
      └─ Market
```

Content target:

```text
Jester
Run Kit
Permit
Glyph
Orbit
Echo
Sigil
Risk Grade
Trial
Archive
```

Data target:

```text
ProfileState
ActiveRunState
CheckpointState
RunHistoryRecord
ArchiveState
Stats
```

## 7. Migration Order

```text
0. V4 docs lock
1. regression tests
2. compatibility wrappers
3. ruleset config skeleton
4. Station terminology UI-only
5. MarketOffer adapter
6. save/checkpoint adapter
7. Station modifier prototype
8. Archive/stats read model
9. balance pass
10. optional code rename
```

## 8. Do Not Do

V4 작업에서 바로 하면 안 되는 것:

- One Pair를 기본 10점으로 변경
- current save를 DB로 즉시 교체
- `RummiBlindState` 같은 코드명을 바로 rename
- Jester id 변경
- Station target을 current implementation처럼 문서화
- 경제 수치와 전투 룰을 한 PR에서 동시에 변경
- save schema와 provider 구조를 한 PR에서 동시에 변경

## 9. First Implementation PR Recommendation

첫 PR은 docs-only 또는 tests-only가 좋다.

권장 첫 작업:

```text
V4 문서 추가
→ current combat regression test 추가
→ save/load regression test 추가
→ confirmScoringLines wrapper 추가
```

코드는 지금 작동하는 프로토타입이므로, 기능 확장은 보호 테스트 뒤에 진행한다.
