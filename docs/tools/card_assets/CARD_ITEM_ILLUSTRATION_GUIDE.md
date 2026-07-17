# 카드형 Item/Jester 일러스트 안내

카드 안의 그림은 카드 전체 UI가 아니라 중앙 장식 영역만 채운다. 카드명, 가격, 등급, 타입은 게임 화면이 따로 그린다.

> Source: `data/common/items_common_v1.json`, `data/common/jesters_common_phase5.json`, `assets/translations/data/ko/items.json`, `assets/translations/data/ko/jesters.json`, `lib/views/game/widgets/game_shared_widgets.dart`, `lib/views/game/widgets/game_shop_screen.dart`, `lib/views/game/widgets/game_jester_widgets.dart`.

## UI 크기 기준

| 항목 | 값 |
|---|---:|
| 실제 카드 face | 54 x 70 |
| 카드 비율 | 27:35 |
| 선택 테두리 포함 | 60 x 76 |
| Market offer cell | 72 x 92 |
| 적용 대상 | Jester, Q-Slot, Tool, Gear, Passive, Market 후보/보유 카드 |

카드가 작기 때문에 일러스트는 세부 장면보다 **중앙 기하 문장 1개 + 큰 실루엣**이 우선이다. 희귀도 등급 표시, 카드명, 타입/카테고리 배지, 가격/선택 상태는 런타임 UI가 담당한다. 작은 텍스트, 복잡한 캐릭터 얼굴, 실제 포커 문양은 쓰지 않는다.

## 카드 정보 계층

카드 일러스트는 카드 전체 face가 아니라 중앙 아트 영역이다. 현재 UI는 카드 위에 정보를 함께 올리므로, 생성 이미지가 정보 표시를 대신하거나 방해하면 실패로 본다.

| 정보 | 표시 주체 | 이미지 생성 규칙 |
|---|---|---|
| 희귀도 | 상단 등급 pill/라벨, 색 띠, 테두리 색, 필요 시 독립된 UI marker | 이미지에 등급 텍스트/별/마크를 넣지 않는다. |
| 타입/카테고리 | 하단 배지 | 이미지에 `Tool`, `Gear`, `Relic`, `Q-Slot`, `Jester` 글자를 넣지 않는다. |
| 이름 | 카드 중앙 텍스트 영역 | 상단/중앙 텍스트 영역과 겹치는 복잡한 장식을 피한다. |
| 가격/판매가 | Market 주변 UI 또는 정보창 | 가격표, 동전 숫자, 구매 가능 표시는 이미지에 넣지 않는다. |
| 선택/활성/잠김 | 런타임 테두리, glow, overlay | 상태별 이미지를 따로 만들지 않는다. |

Hard safe zone 기준:

- 상단 22%는 등급 pill/라벨, 희귀도 띠, 이름 가독성을 위한 UI 전용 no-art zone이다.
- 하단 20%는 타입/카테고리 배지 가독성을 위한 UI 전용 no-art zone이다.
- 좌우 8%는 카드 테두리, 선택선, 압축 표시를 위한 no-art zone이다.
- 중앙 `x 8-92%, y 22-80%` 안에 한 개의 큰 문장, 룬, 도구 실루엣을 둔다.
- no-art zone에는 낮은 대비 배경 질감만 허용한다. 문장 외곽선, 밝은 선, 탭, 띠, 배지처럼 보이는 도형은 실패다.
- 배경 질감은 허용하지만, UI 글자 뒤에서 고대비 선이 지나가면 실패다.
- 희귀도 차이는 색만으로 전달하지 않는다. 작은 카드에서도 `Common/Uncommon/Rare/Legendary` 또는 짧은 등급 표기, 색, 테두리 같은 UI 정보가 함께 보여야 한다.
- 타입 차이는 하단 배지가 1차 판독 수단이고, 이미지는 보조 힌트만 준다.

## UI와 일러스트 분리 원칙

일러스트는 카드 효과와 컨셉을 보여 주는 중앙 그림이다. 희귀도·등급, 타입, 가격, 선택 상태는 카드 UI가 따로 표시한다. 일러스트 시험과 등급 보강 UI도 별도 작업으로 진행한다.

- 등급 보강 UI는 카드 컴포넌트에서 처리한다. 예: `C/U/R/L` 또는 짧은 등급명, 색, 테두리, 상세 정보 표시.
- 일러스트는 등급 UI를 대신하지 않는다. 카드가 Rare라서 이미지 안에 별, 왕관, 등급 문자를 넣는 방식은 쓰지 않는다.
- UI 장식처럼 보이는 띠, 탭, corner marker, badge shape가 이미지 안에 생기면 실제 카드 UI 결함으로 오해될 수 있으므로 실패로 본다.
- 이미지별 색 포인트는 효과군 구분 보조로만 쓴다. 희귀도 색과 충돌하거나 희귀도처럼 읽히면 안 된다.
- 일러스트 검수는 원본 이미지가 아니라 실제 카드 UI 위에 얹은 54x70 축소 상태로 한다. 상단/하단 UI 영역이 조금이라도 복잡해 보이면 재생성한다.

## 공통 아트 디렉션

- 스타일: dark talisman card, geometric magic-circle emblem, thin ink lines, muted fantasy UI.
- 중심부: 카드마다 큰 문장 1개. 내부 선은 3~5개 이하.
- 색: 컨셉별 포인트만 강하게 쓰고 바탕은 어두운 녹청/먹색 계열. 희귀도 색은 UI가 처리한다.
- 금지: 포커 카드 슈트, 실제 카드 레이아웃, 작은 설명문, 캐릭터 일러스트 과밀화.

## 컨셉군별 일러스트 문법

| 컨셉군 | 추천 일러스트 문법 |
|---|---|
| 경제 Jester 문장 | 작은 금화 원 + 영수증/주머니 실루엣 룬. |
| 경제/상점 문장 | 도장/코인/가격표 룬. 사각 도장과 금색 원을 결합. |
| 고배수 Jester 문장 | 증폭 렌즈 문장. 겹원, 삼각 프리즘, 굵은 외곽 링. |
| 덱/손패 문장 | 겹친 타일 더미 + 위로 떠오르는 타일. 바늘/주머니는 단순 선형 부속물. |
| 보드 이동 문장 | 3x3 격자 + 방향 화살표 문장. 이동/되돌림은 같은 격자에서 화살표 방향만 변경. |
| 색상 룬 | 색 견본 룬. 큰 색 막대와 작은 원 3개만 사용. |
| 색상 반응 Jester 문장 | 중앙 원소 룬 + 해당 색 파편 4개. 빨강/파랑/노랑/검정이 한눈에 보이게 한다. |
| 성장/기억 Jester 문장 | 나선형 기록 룬. 원 궤도에 노드가 누적되는 형태. |
| 숫자 반응 Jester 문장 | 숫자 궤도 문장. 1, 10/4, 짝수/홀수, 11~13, 수열을 작은 노드 배열로 표현한다. |
| 안전/버림 문장 | 방패/그물/빠지는 타일 문장. 점선 그물과 보호 링. |
| 점수 증폭 문장 | 충전구/광택 문장. 에너지 코어, 작은 + 눈금, 단순 원형 회로. |
| 점수 Jester 문장 | 점수 파동 문장. 중심 별/렌즈와 바깥으로 퍼지는 2중 원. |
| 족보 반응 Jester 문장 | 타일 점 배열 문장. 페어는 쌍원, 트리플은 삼각, 포카드는 네 점 십자, 스트레이트는 상승 사선, 플러시는 같은 색 5점. |
| 족보 성장 문장 | 연구/행성 카드 느낌의 궤도 룬. 족보별 점 배열을 작은 별궤도처럼 배치. |
| 칩 Jester 문장 | 코인형 칩 마법진. 바깥 원, 안쪽 점, 짧은 방사 눈금. |

## Jester 카드 분류표

| 컨셉군 | ID | 이름 | 효과 | 가격 | 희귀도 |
|---|---|---|---|---:|---|
| 점수 Jester 문장 | `jester` | 기본패 | 점수 +20%. | 2G | Common |
| 색상 반응 Jester 문장 | `greedy_jester` | 노랑 불씨 | 점수 라인의 노란 타일마다 점수 +15%. | 5G | Common |
| 색상 반응 Jester 문장 | `lusty_jester` | 빨강 불씨 | 점수 라인의 빨간 타일마다 점수 +15%. | 5G | Common |
| 색상 반응 Jester 문장 | `wrathful_jester` | 파랑 불씨 | 점수 라인의 파란 타일마다 점수 +15%. | 5G | Common |
| 색상 반응 Jester 문장 | `gluttonous_jester` | 검정 불씨 | 점수 라인의 검은 타일마다 점수 +15%. | 5G | Common |
| 족보 반응 Jester 문장 | `jolly_jester` | 페어 호출 | 원 페어 이상 점수 라인을 확정하면 점수 +40%. | 3G | Common |
| 족보 반응 Jester 문장 | `zany_jester` | 트리플 호출 | 트리플 이상 점수 라인을 확정하면 점수 +60%. | 4G | Common |
| 족보 반응 Jester 문장 | `mad_jester` | 투페어 호출 | 투 페어 이상 점수 라인을 확정하면 점수 +50%. | 4G | Common |
| 족보 반응 Jester 문장 | `crazy_jester` | 연속 호출 | 스트레이트 이상 점수 라인을 확정하면 점수 +60%. | 4G | Common |
| 족보 반응 Jester 문장 | `droll_jester` | 색상 호출 | 플러시 이상 점수 라인을 확정하면 점수 +50%. | 4G | Common |
| 족보 반응 Jester 문장 | `sly_jester` | 페어 칩 | 원 페어 이상 점수 라인을 확정하면 칩 +50. | 3G | Common |
| 족보 반응 Jester 문장 | `wily_jester` | 트리플 칩 | 트리플 이상 점수 라인을 확정하면 칩 +100. | 4G | Common |
| 족보 반응 Jester 문장 | `clever_jester` | 투페어 칩 | 투 페어 이상 점수 라인을 확정하면 칩 +80. | 4G | Common |
| 족보 반응 Jester 문장 | `devious_jester` | 연속 칩 | 스트레이트 이상 점수 라인을 확정하면 칩 +100. | 4G | Common |
| 족보 반응 Jester 문장 | `crafty_jester` | 색상 칩 | 플러시 이상 점수 라인을 확정하면 칩 +80. | 4G | Common |
| 점수 Jester 문장 | `half_jester` | 작은 손 | 3장 이하 점수 라인을 확정하면 점수 +100%. | 5G | Common |
| 고배수 Jester 문장 | `jester_stencil` | 빈 자리 | 빈 Jester 슬롯마다 1배 보너스. | 8G | Common |
| 점수 Jester 문장 | `abstract_jester` | 합창단 | 보유한 Jester마다 점수 +15%. | 4G | Common |
| 성장/기억 Jester 문장 | `green_jester` | 기세 | 확정할 때마다 점수 +5%. 버릴 때마다 점수 -5%. | 8G | Rare |
| 칩 Jester 문장 | `blue_jester` | 남은 덱 | 덱에 남은 타일마다 칩 +2. | 5G | Common |
| 숫자 반응 Jester 문장 | `scary_face` | 그림 칩 | 점수 라인의 11~13 타일마다 칩 +30. | 4G | Common |
| 숫자 반응 Jester 문장 | `smiley_face` | 그림 증폭 | 점수 라인의 11~13 타일마다 점수 +25%. | 4G | Common |
| 경제 Jester 문장 | `egg` | 예비 금화 | 정산 시 골드 +3. | 4G | Common |
| 칩 Jester 문장 | `bonus_jester` | 칩 고정핀 | 칩 +10. | 3G | Common |
| 성장/기억 Jester 문장 | `popcorn` | 시한 증폭 | 점수 +100%. Station을 마칠 때마다 점수 -20%. | 6G | Uncommon |
| 성장/기억 Jester 문장 | `ice_cream` | 줄어드는 칩 | 칩 +100. 확정할 때마다 칩 -5. | 7G | Uncommon |
| 경제 Jester 문장 | `delayed_gratification` | 미사용 환급 | 정산 시 남은 버림마다 골드 +2. | 4G | Common |
| 숫자 반응 Jester 문장 | `walkie_talkie` | 10과 4 | 점수 라인의 10 또는 4 타일마다 점수 +20%. | 4G | Common |
| 경제 Jester 문장 | `golden_jester` | 금빛 주머니 | 정산 시 골드 +4. | 6G | Common |
| 점수 Jester 문장 | `mystic_summit` | 마지막 힘 | 남은 버림이 0이면 점수 +75%. | 5G | Common |
| 숫자 반응 Jester 문장 | `even_steven` | 짝수 엔진 | 점수 라인의 짝수 타일마다 점수 +20%. | 4G | Common |
| 숫자 반응 Jester 문장 | `odd_todd` | 홀수 엔진 | 점수 라인의 홀수 타일마다 칩 +31. | 4G | Common |
| 숫자 반응 Jester 문장 | `scholar` | 1번 장부 | 점수 라인의 1 타일마다 칩 +20, 점수 +20%. | 4G | Common |
| 숫자 반응 Jester 문장 | `fibonacci` | 수열 보너스 | 점수 라인의 1, 2, 3, 5, 8 타일마다 점수 +40%. | 8G | Rare |
| 칩 Jester 문장 | `banner` | 남은 버림 | 남은 버림마다 칩 +30. | 7G | Rare |
| 점수 Jester 문장 | `gros_michel` | 숙성 부스터 | 점수 +75%. | 7G | Rare |
| 성장/기억 Jester 문장 | `supernova` | 런 기억 장치 | 이번 런에서 같은 족보를 확정한 횟수마다 점수 +5%. | 8G | Rare |
| 성장/기억 Jester 문장 | `ride_the_bus` | 무사고 연속 | 11~13 타일 없이 확정할 때마다 점수 +5%. | 6G | Uncommon |
| 족보 반응 Jester 문장 | `the_duo` | 페어 증폭 | 원 페어 이상 점수 라인을 확정하면 점수 x2. | 8G | Rare |
| 족보 반응 Jester 문장 | `the_trio` | 트리플 증폭 | 트리플 이상 점수 라인을 확정하면 점수 x3. | 8G | Rare |
| 족보 반응 Jester 문장 | `the_family` | 4묶음 증폭 | 4묶음 이상 점수 라인을 확정하면 점수 x4. | 8G | Rare |
| 족보 반응 Jester 문장 | `the_order` | 연속 증폭 | 스트레이트 이상 점수 라인을 확정하면 점수 x3. | 8G | Rare |
| 족보 반응 Jester 문장 | `the_tribe` | 색상 증폭 | 플러시 이상 점수 라인을 확정하면 점수 x2. | 8G | Rare |

## Item / Tool / Gear / Passive 카드 분류표

| 컨셉군 | 슬롯/종류 | ID | 이름 | 효과 | 구매가 | 판매가 | 희귀도 |
|---|---|---|---|---|---:|---:|---|
| 경제/상점 문장 | Tool | `reroll_token` | 리롤 칩 | 다음 상점 리롤 비용이 1 줄어듭니다. | 5G | 1G | Common |
| 경제/상점 문장 | Tool | `coupon_stamp` | 할인 도장 | 다음 아이템 또는 Jester 구매 가격이 2 줄어듭니다. | 4G | 2G | Common |
| 경제/상점 문장 | Tool | `coin_cache` | 금화 보관함 | 즉시 골드 +3. | 4G | 1G | Common |
| 족보 성장 문장 | Tool | `two_pair_study` | 투 페어 연구 | 상점에서 사용하면 투 페어 성장 +1. | 6G | 3G | Uncommon |
| 족보 성장 문장 | Tool | `triple_study` | 트리플 연구 | 상점에서 사용하면 트리플 성장 +1. | 7G | 3G | Uncommon |
| 족보 성장 문장 | Tool | `straight_study` | 스트레이트 연구 | 상점에서 사용하면 스트레이트 성장 +1. | 8G | 4G | Uncommon |
| 족보 성장 문장 | Tool | `flush_study` | 플러시 연구 | 상점에서 사용하면 플러시 성장 +1. | 8G | 4G | Uncommon |
| 족보 성장 문장 | Tool | `full_house_study` | 풀하우스 연구 | 상점에서 사용하면 풀하우스 성장 +1. | 9G | 4G | Rare |
| 족보 성장 문장 | Tool | `four_kind_study` | 포카드 연구 | 상점에서 사용하면 포카드 성장 +1. | 10G | 5G | Rare |
| 족보 성장 문장 | Tool | `straight_flush_study` | 스티플 연구 | 상점에서 사용하면 스티플 성장 +1. | 12G | 6G | Rare |
| 안전/버림 문장 | Q-Slot | `board_scrap` | 보드 패스 | 이번 Station의 보드 버림 +1. | 4G | 2G | Common |
| 안전/버림 문장 | Q-Slot | `hand_scrap` | 손패 패스 | 이번 Station의 손패 버림 +1. | 4G | 2G | Common |
| 점수 증폭 문장 | Q-Slot | `chip_capsule` | 칩 충전구 | 다음 확정에 칩 +25. | 4G | 2G | Common |
| 점수 증폭 문장 | Q-Slot | `mult_capsule` | 점수 충전구 | 다음 확정에 점수 +30%. | 4G | 2G | Common |
| 점수 증폭 문장 | Q-Slot | `line_polish` | 점수 광택제 | 다음 확정의 최종 점수가 x1.25가 됩니다. | 6G | 3G | Uncommon |
| 점수 증폭 문장 | Q-Slot | `straight_oil` | 연속 준비 | 다음 스트레이트 이상 확정에 칩 +40. | 5G | 2G | Uncommon |
| 점수 증폭 문장 | Q-Slot | `flush_powder` | 색상 준비 | 다음 플러시 이상 확정에 점수 +40%. | 5G | 2G | Uncommon |
| 점수 증폭 문장 | Q-Slot | `pair_splint` | 페어 고정대 | 다음 투 페어 확정에 칩 +35. | 5G | 2G | Uncommon |
| 점수 증폭 문장 | Q-Slot | `overlap_pin` | 겹침 핀 | 다음 확정의 겹침 보너스 한도가 조금 증가합니다. | 8G | 4G | Rare |
| 덱/손패 문장 | Q-Slot | `emergency_draw` | 비상 드로우 | 손패가 비어 있으면 덱을 소모하지 않고 무작위 타일 1장을 즉시 생성합니다. | 7G | 3G | Rare |
| 경제/상점 문장 | Gear | `ledger_clip` | 장부 클립 | 상점에 들어갈 때 골드 +1. | 5G | 2G | Common |
| 안전/버림 문장 | Gear | `discard_glove` | 보드 장갑 | 각 Station 시작 시 보드 버림 +1. | 6G | 3G | Common |
| 안전/버림 문장 | Gear | `mulligan_sleeve` | 손패 슬리브 | 각 Station 시작 시 손패 버림 +1. | 7G | 3G | Uncommon |
| 경제/상점 문장 | Gear | `jester_hook` | Jester 후크 | Jester 판매 가격 +1골드. | 7G | 3G | Rare |
| 점수 증폭 문장 | Gear | `score_abacus` | 점수 주판 | 각 Station의 첫 확정에 칩 +30. | 9G | 4G | Rare |
| 점수 증폭 문장 | Gear | `thin_caliper` | 짧은 줄 | 3장 이하 확정에 점수 +20%. | 9G | 4G | Rare |
| 경제/상점 문장 | Passive | `stage_map` | Station 지도 | Boss 클리어 보상 골드 +1. | 6G | 3G | Common |
| 경제/상점 문장 | Passive | `merchant_stamp` | 상점 도장 | 상점에 들어갈 때 첫 리롤 비용이 1 줄어듭니다. | 8G | 4G | Uncommon |
| 안전/버림 문장 | Passive | `safety_net` | 안전 장치망 | Station마다 런 종료 전투 막힘을 1회 막습니다. | 8G | 4G | Uncommon |
| 안전/버림 문장 | Passive | `coin_funnel` | 보드 환급 | 정산 시 남은 보드 버림마다 보상 골드 +1. | 9G | 4G | Uncommon |
| 안전/버림 문장 | Passive | `hand_funnel` | 손패 환급 | 정산 시 남은 손패 버림마다 보상 골드 +1. | 9G | 4G | Uncommon |
| 점수 증폭 문장 | Passive | `echo_bell` | 메아리 종 | 각 Station의 두 번째 확정에 첫 확정 점수의 10%를 더합니다. | 12G | 6G | Rare |
| 경제/상점 문장 | Passive | `boss_trophy` | Boss 전리품 | Boss를 클리어하면 다음 Market의 Jester 후보 +1. | 15G | 7G | Legendary |
| 경제/상점 문장 | Tool | `thin_wallet` | 빈 지갑 | 골드가 3 이하일 때만 사용 가능. 골드 +5. | 7G | 2G | Uncommon |
| 경제/상점 문장 | Tool | `trade_ticket` | 아이템 티켓 | 아이템 후보만 다시 뽑습니다. | 6G | 3G | Uncommon |
| 경제/상점 문장 | Tool | `jester_invoice` | Jester 청구서 | 다음 Jester 구매 가격이 4 줄어듭니다. | 8G | 4G | Rare |
| 경제/상점 문장 | Tool | `item_invoice` | 아이템 청구서 | 다음 아이템 구매 가격이 4 줄어듭니다. | 8G | 4G | Rare |
| 색상 룬 | Q-Slot | `red_swatch` | 빨강 견본 | 다음 확정에서 빨간 타일마다 점수 +10%. | 4G | 2G | Common |
| 색상 룬 | Q-Slot | `blue_swatch` | 파랑 견본 | 다음 확정에서 파란 타일마다 점수 +10%. | 4G | 2G | Common |
| 색상 룬 | Q-Slot | `black_swatch` | 검정 견본 | 다음 확정에서 검은 타일마다 점수 +10%. | 4G | 2G | Common |
| 색상 룬 | Q-Slot | `yellow_swatch` | 노랑 견본 | 다음 확정에서 노란 타일마다 점수 +10%. | 4G | 2G | Common |
| 점수 증폭 문장 | Q-Slot | `rank_chalk` | 숫자 분필 | 다음 확정에서 같은 숫자 타일마다 칩 +12. | 6G | 3G | Uncommon |
| 덱/손패 문장 | Q-Slot | `deck_needle` | 덱 바늘 | 덱 맨 위 타일 3장을 보고 1장을 버립니다. | 9G | 4G | Rare |
| 덱/손패 문장 | Q-Slot | `battle_pouch` | 전투 주머니 | 이번 Battle 동안 최대 손패 크기 +1. | 7G | 3G | Uncommon |
| 점수 증폭 문장 | Gear | `tile_polisher` | 타일 광택기 | 각 Station에서 처음 점수화된 타일에 칩 +20. | 14G | 7G | Legendary |
| 보드 이동 문장 | Q-Slot | `move_token` | 이동 칩 | 이번 Station의 보드 이동 +1. | 5G | 2G | Common |
| 보드 이동 문장 | Q-Slot | `slide_wax` | 슬라이드 왁스 | 다음 보드 이동이 슬라이드 보너스도 발동합니다. | 6G | 3G | Uncommon |
| 보드 이동 문장 | Tool | `board_lift` | 이동 예약 | 다음 Station에 보드 이동 +1을 예약합니다. | 8G | 4G | Uncommon |
| 보드 이동 문장 | Q-Slot | `undo_seal` | 되돌림 표식 | 마지막 보드 이동을 1회 되돌립니다. | 9G | 4G | Rare |
| 보드 이동 문장 | Gear | `organizer_glove` | 정리 장갑 | 각 Station 시작 시 보드 이동 +1. | 9G | 4G | Uncommon |
| 덱/손패 문장 | Passive | `travel_pouch` | 여행 주머니 | 최대 손패 크기 +1. | 11G | 5G | Rare |
| 덱/손패 문장 | Gear | `wide_grip` | 넓은 손잡이 | 각 Station 시작 시 최대 손패 크기 +1, 보드 버림 -1. | 11G | 5G | Rare |
| 덱/손패 문장 | Passive | `grand_satchel` | 큰 가방 | 각 Station 시작 시 최대 손패 크기 +2, 손패 버림 -1. | 16G | 8G | Legendary |
| 경제/상점 문장 | Passive | `market_compass` | 상점 나침반 | Market에 들어갈 때 아이템/Jester 첫 후보 중 더 싼 쪽을 1골드 할인합니다. | 16G | 8G | Legendary |
