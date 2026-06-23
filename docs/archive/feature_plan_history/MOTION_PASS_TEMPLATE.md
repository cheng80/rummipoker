# Motion Pass Template

## 짧은 버전

### 1. 어떤 동작인가

- 액션:
- 화면:
- 유저가 보는 순간:

### 2. 어떤 느낌이어야 하나

- 1순위 레퍼런스:
- 2순위 레퍼런스:
- 목표 감각:

### 3. 하지 말 것

- 게임 룰 변경 금지
- 점수/경제 계산 변경 금지
- save schema 변경 금지
- runtime state 변경 금지
- 새 animation package 추가 금지

### 4. 적용 방향

- 먼저 보일 것:
- 이어질 대상:
- 마지막 결과:

### 5. 검증

- fixture:
- mp4 저장 경로:
- 통과 기준:

---

## 일반 버전

### 1. 대상 액션

- 액션:
- 화면:
- 유저 입력:
- 실제 runtime 결과:

### 2. 목표 감각

- 1순위 레퍼런스:
- 2순위 레퍼런스:
- 감정 목표:

### 3. 금지선

- 게임 룰:
- 점수 계산:
- save schema:
- runtime state:
- economy:
- 새 package:
- 대규모 구조:

### 4. 현재 코드 상태

- 현재 위젯/구간:
- 현재 timing token:
- 현재 움직임:
- 부족한 점:

### 5. 적용할 모션 문법

- Source:
- Target:
- Result:
- 움직임:
- 강도:
- 길이:

### 6. 최소 변경 계획

1. 변경 구간:
   - 변경 내용:
   - 새 timing 필요 여부:

2. 변경 구간:
   - 변경 내용:
   - 새 timing 필요 여부:

### 7. 검증 방법

- 정적 검증:
  - `flutter analyze`
  - `git diff --check`
  - duration literal 검색

- 눈검증:
  - fixture:
  - 녹화 방식:
  - 저장 경로:
  - 확인할 것:

### 8. 완료 기준

- Source가 보이는가?
- Target이 보이는가?
- Result가 보이는가?
- 게임 속도 방해 없는가?
- 정답 추천처럼 보이지 않는가?
- runtime/save 변경 없는가?
