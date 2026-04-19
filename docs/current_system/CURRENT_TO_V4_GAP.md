# Current To V4 Gap

문서 목적: 현재 프로토타입과 앞으로 작성할 `V4` 목표 문서 사이의 차이를 정리한다.

이 문서는 아래 질문에 답하기 위해 만든다.

1. 지금 유지해야 할 핵심은 무엇인가?
2. 앞으로 바꿀 구조는 무엇인가?
3. 지금 당장 문서에 확정하면 안 되는 것은 무엇인가?

---

## 1. 현재 프로토타입의 강점

현재 시스템은 아래 핵심을 이미 확보했다.

1. **즉시 확정**
2. **부분 줄 평가**
3. **overlap 보너스**
4. **contributor만 제거**
5. **Jester 기반 점수 증폭**
6. **cash-out + shop + next stage**
7. **continue / active run save / stage restart**

즉, `V4`는 빈 설계에서 시작하는 문서가 아니라  
이미 작동하는 코어 게임 루프를 상위 구조로 재편하는 문서가 되어야 한다.

---

## 2. V4에서 유지해야 할 핵심

### 2.1 반드시 유지 권장

아래는 현재 시스템의 정체성에 가까워서 `V4`에서도 유지하는 쪽이 좋다.

1. 5x5 보드
2. 12라인 평가
3. 5장 강제 완성 제거
4. 부분 줄 평가
5. 즉시 확정
6. overlap 중심 전략
7. contributor만 제거
8. `copiesPerTile` 기반 덱 구조
9. Jester 중심 초기 빌드 구조
10. active run + restart 가능한 체크포인트 개념

### 2.2 유지하되 재표현 가능

아래는 개념은 유지하되 명칭이나 메타 구조는 바뀔 수 있다.

1. `stage`
2. `blind`
3. 현재 상점 경제 수치
4. 현재 notifier/file 분리 방식
5. 현재 저장 DTO 이름

---

## 3. V4에서 확장해야 할 축

현재 프로토타입에 없는 장기 목표는 아래다.

### 3.1 메타 루프 확장

현재:

- stage 기반 단순 연속 루프

장기 목표:

- sector / station 구조
- entry / pressure / lock
- station map

### 3.2 콘텐츠 계층 확장

현재:

- Jester 중심

장기 목표:

- Run Kit
- Permit
- Orbit
- Glyph
- Echo
- Sigil
- Risk Grade
- Trial
- Archive

### 3.3 데이터 구조 확장

현재:

- active run save v2
- stage start snapshot

장기 목표:

- profile
- active run
- checkpoint
- run history
- archive
- stats

### 3.4 UX 확장

현재:

- title
- battle
- shop
- setting

장기 목표:

- station map
- run kit select
- risk grade select
- archive
- stats
- trial select
- victory/defeat summary

---

## 4. 현재와 V4 사이의 핵심 차이 표

| 주제 | 현재 프로토타입 | V4에서 다뤄야 할 방향 |
|---|---|---|
| 전투 코어 | 이미 구현됨 | 유지/정리 |
| 원페어 점수 | 0점 dead line | 유지 여부 명확히 결정 필요 |
| 메타 루프 | stage 기반 | sector/station 구조 정의 |
| shop | Jester 중심 | market 전체 구조 재설계 |
| economy | 프로토타입 수치 | 장기 밸런스 목표 기준 재설계 |
| save | active run v2 | profile/run/checkpoint/history 분리 방향 제시 |
| content | curated Jester 38종 중심 | 다층 콘텐츠 체계 추가 |
| UI | 전투 중심 | 제품 전체 플로우 확장 |
| terminology | old/prototype 이름 혼재 | canonical 명칭 정책 정리 |

---

## 5. V4에서 특히 조심해야 할 오해

### 5.1 “현재 문서와 다르면 다 틀렸다”는 오해

아니다.

현재는 초기 프로토타입이므로:

- 경제 수치는 바뀔 수 있다.
- 메타 구조도 커질 수 있다.
- 저장 구조도 재설계될 수 있다.

하지만 아래는 함부로 흔들면 안 된다.

- 현재 작동하는 전투 코어
- continue / restart 안정성
- contributor 기반 제거 규칙

### 5.2 “V4가 현재 코드를 그대로 설명해야 한다”는 오해

아니다.

`V4`는 **장기 목표 문서**다.  
다만 현재 코드를 무시하면 안 된다.

즉, `V4`는 아래를 동시에 해야 한다.

1. 현재 프로토타입의 사실을 받아들이고
2. 장기 목표를 명확히 제시하고
3. 둘 사이의 이행 순서를 설명해야 한다.

### 5.3 “DB를 바로 최종형으로 구현해야 한다”는 오해

아니다.

`V4` 문서에서는 최종 저장 구조를 설계할 수 있다.  
하지만 구현은 단계적으로 가야 한다.

우선순위는:

1. current save 안정성 유지
2. checkpoint 개념 유지
3. 장기 구조와 호환되는 도메인 모델 정의
4. 저장 엔진 교체는 나중

---

## 6. V4에서 결정해야 할 핵심 질문

`V4` 문서는 아래를 명시적으로 답해야 한다.

1. **현재 전투 코어 중 무엇을 고정 규칙으로 채택하는가?**
2. **원페어는 계속 dead line인가?**
3. **stage 기반 프로토타입을 sector/station으로 어떻게 변환하는가?**
4. **장기 market는 Jester-only가 아니라 어떤 구성을 가지는가?**
5. **save는 어떤 도메인 단위로 쪼개는가?**
6. **archive / stats / unlock는 active run과 어떻게 분리되는가?**
7. **현재 Jester 데이터와 장기 콘텐츠 데이터는 어떤 공통 스키마를 가지는가?**
8. **현재 restart 개념을 장기 구조에서 어떻게 유지하는가?**

---

## 7. 권장 V4 작성 프레임

`V4`는 아래 3층 구조로 작성하는 것이 좋다.

### 7.1 Layer A: Current Baseline

포함할 것:

- 현재 전투 코어
- 현재 저장/재시작 개념
- 현재 Jester / shop / economy 현황

### 7.2 Layer B: Target Product Design

포함할 것:

- sector/station
- market 확장
- 콘텐츠 계층
- progression / archive / stats

### 7.3 Layer C: Migration Plan

포함할 것:

- 지금 유지할 것
- 먼저 갈아탈 것
- 나중에 옮길 것
- save compatibility 전략

이 세 층이 없으면 `V4`는 다시 “현재 설명과 미래 목표가 섞인 문서”가 될 가능성이 높다.

---

## 8. 지금 당장 확정하지 말아야 할 것

아래는 `V4`에서 너무 이르게 고정하면 위험하다.

1. 최종 경제 수치
2. 최종 market weight 수치
3. 모든 station target 표
4. 최종 DB 물리 저장 엔진 세부
5. 모든 콘텐츠 수량
6. 현재 구현과 맞지 않는 코드 클래스명 강제 rename

이들은 방향을 정하는 것은 괜찮지만,  
**현재 프로토타입 검증 없이 확정안처럼 쓰면 다시 문서-코드 괴리**가 생긴다.

---

## 9. V4에서 먼저 고정하면 좋은 것

아래는 수치보다 구조가 중요하므로 먼저 고정하는 편이 좋다.

1. 현재 코어 전투를 어디까지 계승할지
2. 메타 루프 계층도
3. 저장 도메인 구조
4. 콘텐츠 카테고리 경계
5. terminology 정책
6. current-to-target migration 단계

---

## 10. 짧은 결론

`V4`는 아래 한 문장으로 정의하면 된다.

> **현재 작동하는 즉시 확정 보드 전투 프로토타입을, 장기 제품 구조로 흡수 확장하기 위한 기준 문서**

즉, `V4`의 일은:

1. 현재를 부정하지 않고
2. 미래 목표를 명확히 하고
3. 이동 경로를 설계하는 것이다.
