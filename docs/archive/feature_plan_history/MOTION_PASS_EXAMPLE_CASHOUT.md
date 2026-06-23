# Motion Pass Example: Cash-out Gold Collect

## 짧은 버전

### 1. 어떤 동작인가

정산 후 Gold 보상을 받는 순간.

### 2. 어떤 느낌이어야 하나

- 1순위 레퍼런스: Clash Royale
- 2순위 레퍼런스: Balatro
- 목표 감각: 숫자만 바뀌지 말고, 보상 줄에서 Gold 쪽으로 결과가 이어짐.

### 3. 하지 말 것

- Gold 계산 변경 금지
- cash-out 보상 공식 변경 금지
- save 변경 금지
- Market economy 변경 금지
- 너무 긴 보상 연출 금지

### 4. 적용 방향

- 보상 줄이 먼저 짧게 나타남
- `+N Gold`가 짧게 튐
- Gold HUD가 pulse
- 끝나면 바로 다음 진행 가능

### 5. 검증

- fixture: `/game?fixture=final_boss_cash_out_ready&auto_cashout_loop=1`
- mp4 저장 경로: `/tmp/rummipoker_motion_qa_<timestamp>/cashout_gold_collect.mp4`
- 통과 기준: 보상 줄, `+N Gold`, Gold HUD pulse가 순서대로 보이고 텍스트/버튼 가림 없음.

---

## 일반 버전

### 1. 대상 액션

- 액션: cash-out Gold 보상 수령
- 화면: Cash-out / Settlement 이후
- 유저 입력: 정산 후 보상 수령 진행
- 실제 runtime 결과: Gold 보상 계산 완료, 다음 Market 진입 준비

### 2. 목표 감각

- 1순위 레퍼런스: Clash Royale
- 2순위 레퍼런스: Balatro
- 감정 목표: 보상을 실제로 받았다는 짧은 만족감

### 3. 금지선

- 게임 룰: 변경 금지
- 점수 계산: 변경 금지
- save schema: 변경 금지
- runtime state: 변경 금지
- economy: 변경 금지
- 새 package: 추가 금지
- 대규모 구조: 도입 금지

### 4. 현재 코드 상태

- 현재 위젯/구간: cash-out 보상 라인 UI
- 현재 timing token: `cashOutLineReveal`, `cashOutLinePulse`, `cashOutCollectBadge`, `cashOutCoinBurst`
- 현재 움직임: 보상 라인 reveal/pulse 중심
- 부족한 점: 보상 라인에서 Gold HUD로 수령됐다는 연결감이 약할 수 있음

### 5. 적용할 모션 문법

- Source: cash-out reward line
- Target: Gold HUD / market wallet
- Result: `+N Gold`, Gold total 변화
- 움직임: reward line reveal -> collect badge pop -> Gold HUD pulse
- 강도: reward level, 과한 burst 금지
- 길이: 기존 cash-out timing token 범위 사용

### 6. 최소 변경 계획

1. 변경 구간: cash-out 보상 라인
   - 변경 내용: `+N Gold` badge pop과 line pulse 강화
   - 새 timing 필요 여부: 없음. 기존 token 우선 사용

2. 변경 구간: Gold HUD 반응
   - 변경 내용: 보상 수령 순간 Gold HUD pulse 연결
   - 새 timing 필요 여부: 필요 시 `GamePresentationTimings`에 이름 있는 token 추가

### 7. 검증 방법

- 정적 검증:
  - `flutter analyze`
  - `git diff --check`
  - duration literal 검색

- 눈검증:
  - fixture: `/game?fixture=final_boss_cash_out_ready&auto_cashout_loop=1`
  - 녹화 방식: mp4
  - 저장 경로: `/tmp/rummipoker_motion_qa_<timestamp>/cashout_gold_collect.mp4`
  - 확인할 것: 보상 줄, `+N Gold`, Gold HUD pulse 순서와 텍스트/버튼 가림 여부

### 8. 완료 기준

- Source: 보상 라인이 먼저 보임
- Target: Gold HUD 또는 wallet 영역이 반응함
- Result: 실제 Gold 증가와 같은 `+N Gold`가 보임
- 게임 속도 방해 없음
- 보상 결과와 runtime 값 불일치 없음
- runtime/save 변경 없음
