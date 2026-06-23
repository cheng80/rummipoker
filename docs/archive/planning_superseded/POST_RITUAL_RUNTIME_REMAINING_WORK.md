# Post Ritual Runtime Remaining Work

> 문서 성격: `ritual-runtime-20260603` 태그 이후 남은 작업 큐
> 기준 커밋: `adea171`
> 기준 태그: `ritual-runtime-20260603`
> 원칙: 눈검증은 후순위로 두고, 정책/런타임/구조 정리를 먼저 닫는다.

## 현재 상태

1번 "미커밋 변경분 정리"는 완료됐다.

- 커밋: `adea171 운명 의식 카드와 문맥 압축 도구 정리`
- 태그: `ritual-runtime-20260603`
- 원격: `main`과 태그 모두 push 완료
- worktree: 기준 확인 시 clean

따라서 다음 작업은 새 변경분 정리가 아니라, 아래 6개 큐를 순서대로 진행한다.

## 1. 운명/Fate 카드 마무리

목표: 족보 변환형 Fate 카드 16종을 현재 전투에서 즉시 이해되고, 밸런스상 normal market에 안전하게 들어갈 수 있는 상태로 닫는다.

작업:

- 16종 족보 변환형 Fate 카드 전체 동작 검증
- 변환 후 "어떤 줄이 어떤 족보로 바뀌었는지" 전달 강화
- 선택 선 flash, 변환 전후 highlight, 결과 패널/toast 보강
- Fate 카드 rarity/가격/weight 확정
- 강도 높은 카드 별도 점검:
  - `number_mask`
  - `flush_five_fate`
  - `flush_house_fate`
  - `wild_thread`
  - `off_color_rite`

완료 기준:

- 각 Fate 카드가 선택한 보드 선을 의도한 5칸 타일 세트로 바꾼다.
- 적용 직후 evaluator/확정 preview/정산 결과가 같은 족보를 읽는다.
- 유저가 적용 전후 결과를 텍스트와 보드 강조로 이해할 수 있다.
- common/uncommon 노출 금지, rare 이상 노출 정책이 catalog와 market facade에 반영된다.

## 2. Ritual 보류군 재설계

목표: Fate가 아닌 Ritual 카드가 "현재 전투에 즉시 도움 되는가" 기준을 통과하도록 효과, 선택 UI, 연출, 설명을 재정리한다.

작업:

- 모든 Ritual 후보를 현재 전투 즉시성 기준으로 재심사
- `boss_memory`, `thin_memory`, `minor_memory`는 catalog에서 삭제된 legacy 기억 의식으로 유지
- 덱 복사/메아리 6종 재설계:
  - `scoringTiles` 기준
  - 선택 UI 기준
  - deck flight/결과 연출 기준
- 타일 선택형 UI를 Fate 선 선택 UI 규칙과 통일
- seal/enhancement 효과 동기화:
  - 정산 코드
  - 타일 상세 문구
  - 정책 문서
  - session roundtrip 테스트

완료 기준:

- Ritual 선택 방식이 선 선택형/타일 선택형 모두 같은 시각 문법을 쓴다.
- 후보는 파란 테두리, 선택은 주황 테두리, 발동은 확인 버튼 이후에만 처리된다.
- 덱 추가/복사/소각/골드 획득은 수치 변경뿐 아니라 화면 연출로 결과가 보인다.
- 보류군과 normal market 노출군이 문서와 catalog에서 분리된다.

## 3. Item/Jester/Tool/Gear 정책 정화

목표: 전체 카드 catalog를 normal market, 보류, debug 전용으로 분리하고 가격/희귀도/출현 weight를 다시 맞춘다.

작업:

- 전체 catalog 기준 카드군 분리:
  - normal market
  - 보류
  - debug fixture 전용
- 가격, 희귀도, 출현 weight 재정렬
- 강한 카드와 약한 카드의 의도 명확화
- 가격/가치 재판단 후보:
  - `trade_ticket`
  - `ride_the_bus`
  - 고급 study 계열
  - `reroll_token`
- source -> target -> result 전달이 약한 아이템 연출 보강

완료 기준:

- 카드마다 "왜 이 가격/희귀도/출현률인가"가 문서상 설명된다.
- 마켓 후보 생성 로직과 문서의 normal/hold/debug 분류가 일치한다.
- 강한 효과는 rarity/가격/weight 중 하나 이상으로 제어된다.
- 약한 효과는 삭제, 보류, 또는 현재 전투 체감형으로 재설계된다.

## 4. 구조/성능 리팩터링

목표: 큰 view/widget 파일과 presentation state를 더 분해하고, 불필요 rebuild와 반복 계산을 줄인다.

작업:

- 추가 분해 후보:
  - `game_view.dart`
  - `game_shared_widgets.dart`
  - `game_shop_screen.dart`
- runtime state / presentation state 분리 2차
- overlay/dialog/animation queue 정리
- 하드코딩 상수 추가 분리:
  - spacing
  - radius
  - font size
  - duration
- 성능 후보:
  - 큰 widget tree rebuild 축소
  - 반복 계산 cache
  - const/static widget 정리
  - facade 계산 경계 점검
- mobile-first iOS/web smoke 기준 검증

완료 기준:

- 큰 파일의 책임이 더 작은 view/component/helper 단위로 분리된다.
- 저장/복원 source-of-truth는 runtime state에 남고, overlay/animation/dialog 상태는 presentation state로 분리된다.
- analyzer/test/build가 통과한다.
- 리팩터링 후 UI 동작 변경이 의도되지 않은 경우 snapshot/fixture test로 막는다.

## 5. 데이터/시뮬레이션 재개

목표: 정책 정화 이후 현재 catalog/runtime 기준 fresh 데이터로 밸런스 후보를 검증한다.

작업:

- Fate/Ritual 반영 후 fresh 데이터 재수집
- 구매/사용 가치 probe
- multi-seed 표준/도전 데이터 축적
- ML은 자동 밸런스 적용이 아니라 후보 검증용으로 유지
- full_run_bot reference trace는 단일 정답이 아니라 policy/feature sanity 자료로만 사용

완료 기준:

- 구 ML/시뮬레이션 산출물을 active 판단 근거로 재사용하지 않는다.
- fresh runtime/catalog/ruleset/bot policy 기준 데이터만 새 모델과 probe에 넣는다.
- 후보 추천은 자동 적용하지 않고, 정책 검토와 small resimulation을 거친다.

## 6. 후순위 눈검증

목표: 위 정책/런타임/구조 작업을 닫은 뒤 실제 화면 감각과 overflow를 확인한다.

작업:

- Fate 16종 fixture 순회
- Ritual 선택/flight 연출 확인
- 마켓 노출/가격 감각 확인
- 모바일 화면 overflow와 터치 가능성 확인
- 필요 시 풀런봇 QA로 장기 흐름 확인

완료 기준:

- 주요 fixture에서 console error, Flutter overflow, 화면 겹침이 없다.
- 카드 선택, 선 선택, 타일 선택, 확인/취소 흐름이 터치 기준으로 안정적이다.
- 최종적으로 full_run_bot 또는 동등한 장기 QA에서 정책/연출 회귀가 발견되지 않는다.

## 권장 진행 순서

1. 운명/Fate 카드 마무리
2. Ritual 보류군 재설계
3. Item/Jester/Tool/Gear 정책 정화
4. 구조/성능 리팩터링
5. 데이터/시뮬레이션 재개
6. 눈검증/풀런봇 QA로 닫기
