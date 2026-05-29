# 특수 타일 Modifier V1/V2 플랜

## 결론

- 기존 `shop_slot_market_v9` 구매 이벤트 추적, runtime 구매/사용 가치 probe, 가격/가치 판단 재개는 사용자에게 직접 보이는 기능이 아니라 내부 밸런스/검증 부채다. 이 작업은 나중에 반드시 재개하되, 현재 활성 구현 트랙에서는 뒤로 미룬다.
- 다음 활성 작업은 타일 구매를 단순 덱 장수 증가가 아니라 플레이어가 눈으로 보고 선택하는 덱 빌딩 축으로 확장하는 것이다.
- Balatro의 playing card modifier 구조는 최대한 참고하되, 이름/수치/발동 조건은 우리 게임의 타일, 라인, 확정, 다음 블라인드 덱 합성 구조로 변환한다.
- V1은 저장/복원, 마켓 표시, 전투 정산, 런 정보, 테스트까지 닫을 수 있는 작은 modifier 세트로 시작한다.
- V2는 적용 방법이 없는 것이 아니라 발동 타이밍이 더 복잡한 계층이다. V1 이후 판본, 보라 인장, 강철/석판 타일 순서로 연다.

## 참고 원칙

- 참고 대상은 Balatro의 card enhancement, seal, edition 구조다.
- 그대로 복제하지 않는다.
- 우리 런타임 용어는 `Tile modifier`로 통일한다.
- 유저 노출 명칭은 타일/보드 감각에 맞춘다.
- 마켓 구매 타일에만 modifier를 붙인다. 기본 52장 타일에 자동 modifier를 붙이지 않는다.
- 타일 구매 후보도 기존 마켓 정책과 같이 구매 후 자동 보충하지 않는다. 새 후보는 명시적 리롤 또는 다음 마켓 진입 때만 생성한다.

## 현재 시스템 상태

- `Tile`은 현재 `color`, `number`, `id`만 저장한다.
- `RummiRunProgress.addedDeckTiles`는 런 중 추가 타일을 저장하고, 다음 블라인드 덱 source에 합성한다.
- `tileOffers`는 마켓의 별도 Tile lane 후보이며, 구매 시 `addedDeckTiles`에 들어간다.
- 히든 족보와 덱 성장 V1은 이미 구현됐다.
- 아직 없는 것:
  - 타일별 modifier 저장 필드
  - modifier가 붙은 tile offer 생성
  - modifier badge/테두리/툴팁
  - 정산 시 modifier 발동
  - modifier 효과로 런 덱 상태가 바뀌는 경로

## 데이터 모델 목표

장기 목표 모델:

```text
Tile(color, number, id, enhancement?, seal?, edition?)
```

V1 제약:

- `enhancement` 1개까지.
- `seal` 1개까지.
- `edition`은 V1에서 보류하거나 내부 필드만 준비하지 않는다.
- modifier가 없는 기존 저장 데이터는 정상 복원한다.
- 물리 타일 identity는 계속 `color + number + id`를 기준으로 한다. modifier는 같은 물리 타일에 붙은 추가 속성이다.

## V1 범위

V1은 사용자 눈에 보이고 정산에서 바로 읽히는 효과만 넣는다.

| 계층 | 내부 id 후보 | 유저 노출 후보 | 효과 | 발동 타이밍 | V1 포함 |
| --- | --- | --- | --- | --- | --- |
| Enhancement | `chip_inlaid` | 칩 박힘 타일 | scoring contributor면 +20칩 | 확정 정산 | 1차 적용 |
| Enhancement | `score_gilded` | 점수 도금 타일 | scoring contributor면 점수 +20% | 확정 정산 | 1차 적용 |
| Enhancement | `gold_tile` | 골드 타일 | scoring contributor면 골드 +1 | 확정 후 run progress | 1차 적용 |
| Enhancement | `glass_tile` | 유리 타일 | scoring contributor면 점수 x1.5 | 확정 정산 | 1차 적용 |
| Enhancement | `wild_painted` | 와일드 타일 | 색 조건에서 모든 색으로 취급 | 라인 평가 | 보류 |
| Enhancement | `lucky_tile` | 럭키 타일 | 확률로 점수 +% 또는 골드 +N | 확정 정산 | 보류 |
| Seal | `blue_seal` | 푸른 인장 | 해당 확정 족보 성장 +1 | 확정 후 성장 처리 | 1차 적용 |
| Seal | `red_seal` | 붉은 인장 | 같은 타일 modifier 효과 1회 재발동 | modifier 정산 | 1차 적용 |

V1에서 보류:

- `steel_tile`
- `stone_tile`
- `purple_seal`
- `edition`

## V2 범위

V2는 적용 방법이 있지만 더 큰 구조 검증이 필요하다.

| 계층 | 내부 id 후보 | 유저 노출 후보 | 우리식 적용 방법 | 우선순위 |
| --- | --- | --- | --- | --- |
| Edition | `silver_edition` | 은빛 판본 | scoring contributor면 칩 +N | V2-A |
| Edition | `glow_edition` | 빛무늬 판본 | scoring contributor면 점수 +% | V2-A |
| Edition | `prism_edition` | 다색 판본 | scoring contributor면 점수 xN | V2-A |
| Seal | `purple_seal` | 보라 인장 | 손패/보드 버림으로 제거되면 다음 마켓 보상 예약 또는 Item 후보 보강 | V2-B |
| Enhancement | `steel_tile` | 강철 타일 | 손패에 남아 있는 동안 확정하면 점수 xN. 손패 최대치 전략과 함께 검증 | V2-C |
| Enhancement | `stone_tile` | 석판 타일 | 족보 조건에는 기여하지 않지만 확정 라인에 포함되면 고정 칩 보너스 | V2-D |

V2 설계 주의:

- Steel은 현재 손패 1장 중심 구조에서는 선택 재미가 약하다. 손패 최대치 증가와 같이 검증한다.
- Stone은 evaluator와 contributor 제거 정책을 크게 흔든다. 완전한 색/숫자 제거보다 “족보에는 기여하지 않는 라인 보너스 타일”로 변환한다.
- Purple Seal은 전투 중 즉시 아이템 지급으로 처리하지 않는다. 다음 마켓 보상 예약 쪽이 UI와 저장 경계가 안전하다.
- Edition은 Enhancement와 효과가 겹치므로, V2-A에서 하나의 modifier 계층으로만 표시하고 정산 순서를 명확히 한다.

## 마켓 규칙

- Tile lane에 기본 타일과 특수 타일이 섞인다.
- 초반에는 `chip_inlaid`, `score_gilded`, `gold_tile` 중심으로 낮은 확률 등장.
- 중반 이후 `glass_tile`, `blue_seal`, `red_seal`을 연다.
- `wild_painted`, `lucky_tile`은 효과 구현 전까지 실제 마켓 생성 풀에 넣지 않는다.
- 특수 타일 가격은 기본 타일 가격 위에 modifier surcharge를 더한다.
- 후보 수는 기존 Tile lane 기준을 유지한다.
- 구매 후 자동 보충하지 않는다.
- 명시적 tile reroll은 구매된 빈칸을 포함해 새 후보를 생성한다.

## 정산/평가 규칙

### 기본 순서

1. 라인 평가에서 `wild_painted` 색 판정을 반영한다.
2. scoring contributor를 확정한다.
3. contributor 타일의 enhancement/seal 효과를 모은다.
4. 칩 보너스, 점수 +%, 점수 xN, 골드 보상 순으로 정산한다.
5. 확정 후 성장 보조와 파괴/소멸 예약을 처리한다.
6. 제거되는 contributor와 런 덱 상태를 동기화한다.

### Red Seal 재발동

- `red_seal`은 같은 타일의 enhancement 효과를 1회 더 적용한다.
- `glass_tile`의 파괴 판정은 재발동하지 않는다. 점수 효과만 재발동한다.
- `gold_tile`의 골드 보상은 재발동 가능 여부를 V1 후반에서 테스트로 결정한다. 기본 후보는 재발동 가능이다.

### Blue Seal 성장 보조

- Balatro의 Planet 생성 감각을 우리 족보 성장으로 변환한다.
- 후보안:
  - 이 타일이 contributor인 확정에서 최종 대표 족보에 성장 조각 +1.
  - 이미 해당 확정으로 기본 성장 +1이 들어간다면 추가 +1로 총 +2가 된다.
- UI에서는 정산 callout에 `푸른 인장: 족보 성장 +1`처럼 보여준다.

### Glass 파괴

- `glass_tile`은 확정 정산 뒤 확률로 파괴된다.
- 파괴되면 현재 전투 제거 더미뿐 아니라 다음 블라인드 덱 source에서도 제거되어야 한다.
- 파괴 대상은 물리 타일 identity로 찾는다.
- 파괴는 저장/복원과 stage restart 정책을 명확히 해야 한다.
  - 현재 전투 중 파괴가 발생하면 active run save에 반영한다.
  - stage restart는 stage start snapshot 기준으로 복원하므로 파괴도 되돌아간다.

1차 적용 메모:

- 현재 구현은 점수 x1.5와 파괴 판정을 적용한다.
- 파괴된 `glass_tile`은 확정 breakdown에 기록되고, `RummiRunProgress.addedDeckTiles`에서 같은 물리 타일을 제거해 다음 블라인드 덱 source와 active run save/stage restart snapshot 경계가 함께 맞는다.

### Wild/Lucky 보류 사유

- `wild_painted`는 evaluator의 색 판정과 contributor 선택을 바꾼다. Flush, Straight Flush, hidden rank와 보스 색 약화 판정까지 같이 테스트해야 하므로 1차 정산 보정 뒤 별도 단계로 연다.
- `lucky_tile`은 확률 발동을 전투 정산 RNG와 저장/재현 정책에 연결해야 한다. 현재 1차에서는 후보 생성과 저장만 열고 실제 효과는 보류한다.

## UI/UX 규칙

- 마켓 Tile offer에는 modifier badge를 표시한다.
- 보드/손패 타일에는 작은 badge 또는 테두리로 modifier를 표시한다.
- modifier 이름과 짧은 효과는 offer 상세/타일 상세에서 읽힌다.
- 정산에서는 발동한 modifier만 callout 또는 settlement burst로 보여준다.
- modifier가 없는 기본 타일과 시각적으로 구분되어야 한다.
- 색상만으로 의미를 전달하지 않는다. 작은 아이콘/문자 badge를 같이 둔다.
- 텍스트는 다국어 길이를 고려해 짧게 유지한다.

1차 적용 메모:

- 공통 `GameRummiTileCard`에 enhancement/seal badge를 붙여 마켓, 손패, 보드, 타일 이동/제거 flight가 같은 표시를 공유한다.
- 마켓 Tile offer compact label은 특수 타일이면 modifier 이름과 가격을 우선 보여주고, 상세 패널에 실제 효과 문구를 표시한다.
- 정산 floating burst는 기존 Jester/Item 효과 레이어를 재사용하되 `tile:` source는 Item이 아니라 특수 타일 이름으로 표시한다.
- 후속 작업은 확정 preview에서 “이번에 발동할 특수 타일”을 미리 강조하고, 타일별 발동 애니메이션 색/움직임을 세분화하는 것이다.

## 구현 순서

### 0. 플랜/라우팅

- 이 문서를 source-of-truth feature plan으로 둔다.
- `ACTIVE_EXECUTION_PLAN.md`에서 경제/probe 트랙을 대기열로 내리고, 특수 타일 V1을 현재 작업으로 둔다.

### 1. 데이터 모델과 저장

- `Tile`에 `enhancement`, `seal` 필드 추가.
- JSON 저장/복원 backward compatibility 테스트.
- `addedDeckTiles`, `tileOffers`, deck pile, board cells, hand, eliminated 모두 modifier를 유지하는지 확인.

### 2. 마켓 후보 생성

- Tile offer generator가 modifier 없는 기본 타일과 modifier 타일을 함께 생성한다.
- stage band에 따라 modifier 등장 확률과 종류를 제한한다.
- 가격 계산에 modifier surcharge를 반영한다.
- tile offer 구매 후 자동 보충 없음 회귀를 유지한다.

### 3. 전투 표시

- hand/board tile widget에 modifier badge 표시.
- tile shop offer에 modifier 이름/효과 표시.
- run info 덱 섹션에 modifier 타일 요약 표시.

### 4. 평가/정산 V1

- `chip_inlaid`, `score_gilded`, `gold_tile`, `glass_tile`, `blue_seal`, `red_seal` 효과 적용.
- settlement breakdown에 modifier source를 남긴다.
- `wild_painted`, `lucky_tile`, glass 파괴와 런 덱 제거 반영은 후속 단계로 분리한다.

### 5. V1 검증

- logic/save/widget test.
- `flutter analyze`.
- 핵심 `flutter test`.
- web build.
- 필요 시 Market fixture 눈검증.

### 6. V2-A 판본

- edition 3종 추가.
- enhancement/seal/edition 정산 순서 테스트.
- UI badge stack 정리.

### 7. V2-B 보라 인장

- 버림 제거 hook 추가.
- 다음 마켓 보상 예약 상태 추가.
- 전투 중 즉시 인벤토리 지급은 하지 않는다.

### 8. V2-C/D 강철/석판

- Steel은 손패 보유 발동 타이밍과 hand size 전략을 먼저 테스트한다.
- Stone은 evaluator 영향이 크므로 별도 테스트 묶음으로 연다.

## 테스트 계획

- `test/logic/tile_model_test.dart` 또는 인접 테스트
  - modifier 없는 과거 JSON 복원.
  - enhancement/seal 포함 JSON roundtrip.
- `test/services/active_run_save_service_test.dart`
  - modifier 타일이 addedDeckTiles, tileOffers, board/hand/eliminated에서 보존된다.
- `test/logic/hand_evaluator_test.dart`
  - wild 타일이 색 조건에 반영된다.
  - wild가 숫자 조건까지 바꾸지는 않는다.
- `test/logic/rummi_settlement_facade_test.dart` 또는 인접 정산 테스트
  - chip/score/gold/lucky/glass/blue seal 정산.
  - red seal 재발동 후보 검증.
- `test/logic/rummi_session_test.dart`
  - glass 파괴 후 다음 블라인드 덱 source에서 제거된다.
  - stage restart snapshot 기준으로 파괴가 복원된다.
- `test/logic/rummi_market_facade_test.dart`
  - 특수 tile offer 표시/가격/구매.
  - 구매 후 자동 보충 없음.
  - 리롤 후 새 후보 생성.
- `test/views/game/widgets/game_shop_screen_test.dart`
  - tile offer modifier badge와 설명.
- `test/views/game/widgets/game_run_info_dialog_test.dart`
  - modifier 타일이 덱 요약에서 읽힌다.

## 리스크

- 저장 포맷이 넓어진다. backward compatibility 테스트가 필수다.
- `wild_painted`는 flush/color/boss modifier와 상호작용한다. 색 판정 helper를 중복 구현하지 않는다.
- `glass_tile`은 런 덱에서 물리 타일 제거가 필요하다. 보드 제거와 덱 source 제거를 혼동하면 저장/복원 버그가 난다.
- UI badge가 작으면 효과가 안 읽힌다. 타일 상세/마켓 상세/정산 callout까지 같이 둔다.
- modifier가 많아지면 마켓 판단이 복잡해진다. V1은 낮은 등장률과 짧은 효과 텍스트로 시작한다.
- bot/sim은 처음에는 특수 타일 가치를 완전히 이해하지 못할 수 있다. V1 runtime 반영 뒤 bot 정책 보강 여부를 별도로 본다.

## 대기 작업

아래 작업은 폐기하지 않는다. 특수 타일 V1 이후 다시 연다.

- `shop_slot_market_v9` 구매 이벤트 source candidate 추적.
- 실제 runtime 후보 구매/사용 가치 probe.
- `trade_ticket`, `ride_the_bus`, 고급 study, `reroll_token` 가격/가치 판단 재개.
- 장기 경제 gate와 `runtime_station_pool_economy_r400` 재검토.
