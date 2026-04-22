# Current System Overview

> GCSE role: `Context`
> Source of truth: 현재 프로토타입의 실제 시스템 상태 요약.

문서 목적: `V4` 기획/설계 문서를 다시 작성할 때, **현재 코드가 실제로 무엇을 구현하고 있는지**를 빠르게 파악할 수 있게 하는 기준 문서다.

이 문서는 아래를 우선 기준으로 요약한다.

- 실제 코드
- `START_HERE.md`
- `docs/archive/`

이 문서는 장기 목표 문서가 아니다.  
의미는 “현재 프로토타입이 여기까지 와 있다”는 사실 정리다.

---

## 1. 현재 프로젝트 성격

현재 프로젝트는 **초기 프로토타입에서 플레이 가능한 보드형 로그라이트 전투 루프**를 먼저 붙여 놓은 상태다.

현재 구현의 핵심 특징:

1. `Rummi Poker Grid`의 핵심 전투 규칙은 이미 동작한다.
2. 상점, Jester, cash-out, stage advance, continue/save, restart까지 1차 루프가 연결되어 있다.
3. 메타 구조는 아직 단순하다.
4. 경제, 장기 progression, 대규모 콘텐츠 계층은 아직 확장 전이다.
5. 따라서 현재 코드는 **“작동하는 코어 프로토타입”** 이고, `V4`는 이를 장기 목표 구조로 재편하는 문서가 되어야 한다.

---

## 2. 현재 핵심 게임 규칙

### 2.1 보드와 평가 축

- 보드: `5 x 5`
- 평가 라인: `12줄`
  - 행 5
  - 열 5
  - 주 대각선 1
  - 반 대각선 1

### 2.2 부분 줄 평가

현재는 **빈 칸이 있는 줄도 현재 놓인 카드만으로 판정**한다.

카드 수별 성립 의미:

- 1장: High Card
- 2장: One Pair 가능
- 3장: Three of a Kind 가능
- 4장: Two Pair / Four of a Kind 가능
- 5장: Straight / Flush / Full House / Straight Flush 포함 전체 족보 가능

### 2.3 현재 점수 규칙

현재 구현 기준:

- High Card: `0`
- One Pair: `0`
- Two Pair: `25`
- Three of a Kind: `40`
- Straight: `70`
- Flush: `50`
- Full House: `80`
- Four of a Kind: `100`
- Straight Flush: `150`

중요:

- **하이카드와 원페어는 dead line** 이다.
- 즉, 판정은 하되 점수는 없다.
- 확정 시 제거 대상도 아니다.

### 2.4 Confirm 규칙

현재는 **즉시 확정 + 부분 줄 평가** 규칙을 쓴다.

- 플레이어가 `확정` 버튼을 누르면
- 현재 보드에서 점수 성립 가능한 라인을 전부 평가하고
- 라인별 점수를 합산한 뒤
- 각 라인의 **족보 성립 contributor만 제거**한다.

줄 전체 제거가 아니다.

예:

- Two Pair는 4장만 제거되고 키커는 남는다.
- Four of a Kind는 4장만 제거된다.
- Straight / Flush / Full House / Straight Flush는 5장 전체가 contributor라 5장이 제거된다.

### 2.5 Overlap 규칙

현재는 overlap 보너스가 있다.

- 하나의 타일이 여러 scoring line에 기여하면 overlap으로 취급한다.
- contributor 타일의 겹침 정도에 따라 라인 점수에 배수가 붙는다.
- 현재 구현 상수:
  - `alpha = 0.3`
  - `cap = 2.0`

### 2.6 Straight 규칙

- 일반 연속 허용
- `10-11-12-13-1`도 Straight로 인정

---

## 3. 덱 / 손패 / 버림 / 만료

### 3.1 덱 구조

현재 덱은 고정 52장 숫자 문구가 아니라 **`copiesPerTile` 기반**이다.

총 장수:

`4색 × 13랭크 × copiesPerTile`

현재 기본값:

- `copiesPerTile = 1`
- 기본 52장

필요하면 같은 로직으로 104장도 지원 가능하다.

### 3.2 손패

- 기본 손패 한도: `1장`
- 현재 디버그 조절 범위: `1~3장`

실제 전투 밀도와 UI는 **1장 기준**으로 읽는 것이 맞다.

### 3.3 버림 자원

현재 버림은 둘로 분리되어 있다.

- `board discard`
  - 보드 타일 제거용
- `hand discard`
  - 손패 타일 버리고 새 타일 보충

기본값:

- board discard: `4`
- hand discard: `2`

### 3.4 만료 조건

현재 만료 신호는 아래 두 축이다.

1. `board discard == 0` 상태에서 보드 25칸이 꽉 찬 경우
2. 현재 덱이 모두 소모되고, 손패/확정 가능한 점수 줄도 없어 더 진행할 수 없는 경우

---

## 4. 현재 메타 루프

현재 메타 루프는 **stage 기반 단순 루프**다.

흐름:

1. 게임 시작
2. stage 전투
3. 확정으로 목표 점수 달성
4. 실시간 정산
5. stage clear overlay
6. cash-out
7. Jester shop
8. 다음 stage 진입

아직 없는 것:

- sector / station map
- entry / pressure / lock
- run kit
- permit
- orbit
- glyph
- echo
- sigil
- archive / stats 완성형 구조
- risk grade / trial

즉, 현재는 **stage + shop + next stage** 구조다.

---

## 5. 현재 경제와 상점

현재 경제는 프로토타입용이지만 실제로 동작한다.

기본값:

- 시작 골드: `10`
- stage clear 기본 보상: `10`
- 남은 board discard 보상: `+5`씩
- 남은 hand discard 보상: `+2`씩
- 상점 리롤 기본 비용: `5`
- 상점 기본 오퍼 수: `3`

현재 상점 특징:

1. Jester 중심 상점이다.
2. 전투 점수 또는 라운드 종료 경제에 **즉시 반영 가능한 Jester만** 우선 노출한다.
3. 판매가 / 구매가 / 리롤이 동작한다.
4. 상점은 바텀시트가 아니라 **전체 화면 라우트**다.
5. 테스트용으로 검사 전용 오퍼를 강제로 띄우는 경로도 아직 남아 있다.

---

## 6. Jester 시스템 현재 상태

현재 Jester는 장기 제품 구조의 일부만 구현돼 있다.

### 6.1 현재 구현 범위

1. curated common Jester 카탈로그 사용
2. 전투 점수에 직접 반영 가능한 Jester 처리
3. 라운드 종료 경제형 일부 처리
4. stateful Jester 일부 처리
5. 장착 슬롯 5칸
6. 상점 구매 / 판매 / 보유 슬롯 / 상세 패널

### 6.2 현재 데이터 소스

- `data/common/jesters_common_phase5.json`

현재 운영 카탈로그 기준:

- common Jester 38종

### 6.3 현재 구현된 대표 범주

- `chips_bonus`
- `mult_bonus`
- `xmult_bonus`
- `scholar` 특수 처리
- economy 일부
- stateful 일부

### 6.4 stateful Jester 예시

- `green_jester`
- `supernova`
- `popcorn`
- `ice_cream`
- `ride_the_bus`

### 6.5 아직 없는 것

- imprint/edition 계층
- orbit/glyph/echo와 연계된 런 전체 시너지
- 장기 unlock 계층
- rarity / weight / archetype 기반 완성형 market control

---

## 7. 저장 / 이어하기 / 재시작

현재 저장 시스템은 이미 중요 기능으로 들어와 있다.

### 7.1 현재 저장 방식

- `GetStorage` payload
- `flutter_secure_storage` device key
- `HMAC-SHA256` 서명

즉, **하이브리드 로컬 저장 + 무결성 검증** 구조다.

### 7.2 저장 범위

현재 active run 저장에는 아래가 포함된다.

- 현재 session
- 현재 run progress
- active scene
- `stageStartSnapshot`

### 7.3 stage start snapshot

이 구조는 현재 시스템의 핵심이다.

의미:

- 현재 stage 시작 시점의 세션과 진행 상태를 함께 저장
- 재시작 / 게임오버 다시하기 / 앱 재실행 후 재시작에 사용

### 7.4 현재 재시작 의미

현재 인게임 `재시작`은 런 전체 리셋이 아니다.

의미:

- **현재 stage 시작 시점으로 복원**

복원 대상:

- 보드
- 손패
- 덱 순서
- 제거 더미
- 현재 stage 골드
- 장착 Jester
- 상점 상태
- stateful Jester 값

### 7.5 continue 동작

타이틀의 `이어하기`는 현재 런 복원이다.

현재 title flow:

- 세이브 존재 확인
- 무결성 검사
- 복원 가능 / 손상 세이브 / 삭제 분기 처리

---

## 8. 현재 UI 구조

현재 주요 화면:

- `TitleView`
- `GameView`
- `SettingView`
- `GameShopScreen`

### 8.1 전투 화면 구조

현재 전투 화면은 Flutter 위젯 중심이다.

구성:

1. 상단 HUD
2. Jester 5슬롯 스트립
3. 5x5 보드
4. 손패/드로우 영역
5. 하단 액션 버튼
6. 확정 정산 오버레이 / cash-out / shop 이동

### 8.2 공통 레이아웃

- `PhoneFrameScaffold`
- 논리 크기 `390 x 750`
- 중앙 정렬 phone-frame 레이아웃

### 8.3 배경 및 연출

- `StarryBackground` 사용
- 현재 Flame은 핵심 화면이 아니라 보조 연출 후보

---

## 9. 현재 상태 관리 구조

현재는 Riverpod 기반으로 분리되어 있다.

### 9.1 전투

- `GameSessionNotifier`
- 세션, 상점, stage 흐름, 선택 상태, UI 잠금, 연출 상태 관리

### 9.2 타이틀

- `TitleNotifier`
- continue 가능 여부 / 저장 삭제 / 손상 세이브 분기

### 9.3 설정

- `SettingsNotifier`
- 볼륨, 음소거, 화면 꺼짐 방지 등

---

## 10. 현재 구현됨 / 부분 구현 / 미구현

### 10.1 구현됨

- 즉시 확정
- 부분 줄 평가
- overlap 보너스
- contributor만 제거
- stage 목표 점수
- Jester 상점
- cash-out
- 다음 stage 진행
- continue
- active run save/load
- stage start restart

### 10.2 부분 구현

- economy
- Jester pool / 분류
- stateful Jester 범위
- UI polish
- 테스트용 shop 동선 제거 여부
- 유저 문구 정리

### 10.3 미구현

- sector/station 메타 구조
- entry/pressure/lock
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
- 장기 데이터 구조

---

## 11. V4 작성 시 반드시 유지해야 할 현재 핵심 사실

1. 현재 전투의 핵심은 **즉시 확정 + 부분 줄 평가 + overlap + contributor 제거**다.
2. 현재는 **원페어 0점 dead line** 이다.
3. 현재는 `copiesPerTile` 기반 덱 구조다.
4. 현재는 **stage 기반 루프 + full-screen Jester shop** 이다.
5. 현재 저장은 **active run + stageStartSnapshot** 중심이다.
6. 현재는 Jester 중심 프로토타입이며, 장기 콘텐츠 계층은 아직 추가되지 않았다.
7. `V4`는 현재 코드를 복기하는 문서가 아니라, **현재 구조를 흡수해 장기 목표로 연결하는 문서**가 되어야 한다.
