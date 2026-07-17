# 스크린샷과 홍보 문구

## 만들 때 지킬 것

- 실제 게임 화면을 우선 사용한다.
- Debug fixture는 디버그 UI, 내부 QA 버튼, 개발용 라벨이 화면에 남는 경우 제출 스크린샷에 쓰지 않는다.
- 단, 유저에게 보이는 최종 플레이 화면과 동일하게 보이도록 만든 스크린샷 제작용 fixture는 허용한다. 이 경우 fixture는 원하는 장면을 안정적으로 구성하기 위한 도구이며, 캡처 결과에는 디버그 모드 관련 UI가 보이면 안 된다.
- 포커 이미지는 족보 개념 설명에만 연결하고, 카지노/도박 인상은 피한다.
- 로고와 타일은 현재 게임의 초록 보드, 숫자 타일, 골드 코인 톤과 맞춘다.

## 스크린샷 구성

1. Title / New Run
   - KO: 타일로 만드는 포커 런
   - EN: A poker run built with tiles
   - Body KO: 숫자 타일을 놓고 매 런 다른 성장 루트를 찾아보세요.
   - Body EN: Place number tiles and find a new growth path every run.

2. Battle Grid
   - KO: 12개 라인을 한 번에 계산
   - EN: Score across 12 board lines
   - Body KO: 한 줄이 아니라 보드 전체를 보며 큰 정산 타이밍을 만듭니다.
   - Body EN: Plan the whole board, not just one line, before you cash in.

3. Run Info / Hand Growth
   - KO: 완성한 조합이 런 안에서 성장
   - EN: Completed hands grow the run
   - Body KO: 자주 완성한 족보가 다음 전투의 점수 기반이 됩니다.
   - Body EN: The hands you complete become stronger inside the same run.

4. Market / Jester / Item
   - KO: Jester와 Item으로 매번 다른 빌드
   - EN: Build around Jesters and Items
   - Body KO: 상점에서 보유 영역을 채우고 다음 전투의 해법을 바꿉니다.
   - Body EN: Fill your slots in the Market and reshape the next battle.

5. Boss Constraint
   - KO: 보스 제약에 배치를 바꾸세요
   - EN: Adapt your board to boss rules
   - Body KO: 같은 타일도 보스 규칙에 따라 전혀 다른 선택이 됩니다.
   - Body EN: The same tiles ask for different plans when boss rules change.

6. Settlement / Game Over / Endless
   - KO: 정산하고 더 깊이 도전
   - EN: Cash out, then push deeper
   - Body KO: 보상을 챙기고 다음 스테이션, 또는 끝없는 도전으로 이어갑니다.
   - Body EN: Claim rewards, enter the next station, or keep pushing deeper.

## 생성기와 캡처 경로

- 생성기: `tools/app_store_screenshots/`
- 원본 캡처: `tools/app_store_screenshots/public/screenshots/{ko,en}/`
- App Store 이미지 export: 생성기 화면의 `Export PNG` 버튼으로 현재 선택한 locale/slide를 저장한다.
- Flutter 원본 캡처: `tools/app_store_screenshots`에서 `npm run capture:flutter`을 실행한다.
- 캡처 범위는 웹 페이지 전체가 아니라 모바일 `PhoneFrame` 기준 `390x750` 안전 영역 안쪽이다. App Store 합성용 원본에는 브라우저 배경, 데스크톱 여백, debug notice가 들어가면 안 된다.
- 제출 후보 원본은 iPhone Simulator 캡처를 기본으로 한다. 실행 명령은 `tools/ios_app_store_screenshot_capture.sh --locales ko,en --output-dir tools/app_store_screenshots/public/screenshots`이며, 이 경로는 실제 iOS safe area와 디바이스 해상도를 기준으로 캡처한다.
- 웹 캡처(`npm run capture:flutter`)는 빠른 구성 확인용 보조 경로로만 사용한다. 최종 제출 후보 판단은 Simulator 원본과 `tools/app_store_screenshots/exports/{ko,en}/` 결과를 기준으로 한다.

## 홍보 문구 후보

한국어:

```text
숫자 타일로 포커 라인을 만들고, 런마다 다른 성장 루트를 찾아보세요.
```

```text
한 줄을 넘어서 여러 줄을 동시에 완성하는 타일 포커 로그라이트.
```

English:

```text
Place number tiles, build poker lines, and discover a new run every time.
```

```text
A tile poker roguelite about planning more than one line at once.
```
