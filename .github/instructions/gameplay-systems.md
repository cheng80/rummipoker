---
description: 게임 규칙, 전투, 마켓, 성장, 저장, 카탈로그 작업 규칙
globs: ["lib/logic/**/*.dart", "lib/providers/**/*.dart", "lib/services/**/*.dart", "data/**/*.json", "assets/translations/data/**/*.json", "test/logic/**/*.dart", "test/providers/**/*.dart", "test/services/**/*.dart", "test/resources/**/*.dart"]
alwaysApply: false
---

# 게임 시스템 규칙

## 정본

- 수정 전에 `docs/core/GAME_DESIGN.md`, `GAME_RULES.md`, `RUN_ECONOMY.md`, `CONTENT_SYSTEM.md`, `SAVE_DATA.md`, `SYSTEM_ARCHITECTURE.md`의 관련 절을 읽는다. 구체 수치·ID·해금·저장 schema는 agent 규칙에 복제하지 않는다.
- 문서, 코드, 데이터, 테스트가 다르면 실행 코드와 회귀 테스트를 우선 조사하고 정본 문서를 같은 변경에서 동기화한다. 미정이거나 정책이 갈리면 구현 전에 사용자 결정을 받는다.

## 공통 불변식

- 유저 선택을 강제로 대신하거나 자동 지급·특정 slot 고정으로 전략을 제거하지 않는다. 숫자 penalty 변형뿐 아니라 파괴, 변형, 비활성, 순서, 조건부 제약 후보를 함께 검토한다.
- 한국어 노출 용어는 `칩`을 쓴다. 칩은 점수 재료이고 골드는 구매 재화다. 내부 ID와 표시명, 카드 ID와 tile modifier persistence 값은 분리한다.
- 효과는 적용 가능성 검사 후 실제 변화만 적용·기록한다. 상한 또는 대상 부재로 효과가 없으면 Item을 소비하거나 결합된 penalty만 적용하지 않는다.
- 새 content는 catalog, runtime, 저장·복원, 시뮬레이션, UI 표시, 번역, 테스트를 한 단위로 닫는다. 잠긴 slot이나 특수 tile을 UI만 먼저 노출하지 않는다.

## Market과 성장

- Jester/Item 후보는 현재 Market과 해당 lane reroll 동안 고정한다. 구매 빈자리는 자동 보충하지 않고 명시적 reroll 또는 다음 Market에서만 생성한다.
- 첫 reroll 무료는 S1 기본 첫 Market 전체에서 1회뿐이며 다음 Market이나 stale save에 남지 않는다. 아이템 할인과 문구를 구분한다.
- 보유 slot 확장은 Boss 진행 보상 축으로 유지한다. 후보 수·자원 상한을 늘리는 효과는 UI 수용량, 실패 시 미소모, 부분 적용량을 함께 검증한다. 체감·발동 피드백 없는 확률 보정 효과는 재도입하지 않는다.
- 족보 성장은 한 run 안에서 완성 이후 다음 완성 점수가 커지는 족보 레벨 성장이다. 외부 참고작은 taxonomy로만 사용하고 Rummi Poker의 보드 line, tile modifier, Market, Boss 상호작용에 맞춘다.

## 전투와 콘텐츠

- 자원 사용, 이동, 버림, Item은 족보 형성 또는 확정 점수 개선에 기여해야 한다. evidence만 얻기 위한 무의미한 소비를 만들지 않는다.
- `emergency_draw`는 덱을 소모하지 않는 비상 tile 생성이며 사용 전 game-over 판정을 미루지 않는다. 생성·복사·제거 효과는 어느 deck/session source가 바뀌는지 명시한다.
- Ritual/Fate 선택은 실제 보드 line/tile을 직접 선택하고 확인 후 적용한다. 일반 Market 카드는 현재 전투에 즉시 읽히는 변화를 줘야 하며 간접·다음 전투 예약형은 보류군에 둔다.
- 로얄은 같은 색 `1,10,11,12,13`이고 표기는 `10-11-12-13-1`이다. 플러시 하우스와 플러시 파이브는 일반 족보보다 우선하는 hidden 족보다.
- Boss 금지 pattern의 좌표·사용 가능 칸 수·등장 stage/difficulty를 데이터와 테스트로 함께 검증한다. 예시 mask와 구현 좌표가 다르면 명시한다.

## 저장과 완료 기준

- `stageStartSnapshot`은 Station 시작, `stakeStartSnapshot`은 현재 Blind 시작 기준이다. presentation 선택·overlay·animation은 저장하지 않으며 복원 후 초기 표시 상태에서 시작한다.
- 복원 뒤 변경되는 collection은 mutable copy로 보관한다. bookmark는 active-run과 별도 3 slot이며 불러오기가 현재 이어하기를 덮어쓴다는 확인을 제공한다.
- 문서·sim·ML·offline metric만 반영된 상태를 runtime 완료라고 부르지 않는다. 실제 앱 반영과 저장·복원·관련 테스트까지 통과해야 Done이다.
