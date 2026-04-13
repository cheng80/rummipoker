# Rummi Poker Grid — 이어하기 저장 아키텍처

> 목적: 앱 종료 후 다시 켰을 때 **현재 런을 이어하기** 위한 저장 방식을 고정한다.  
> 범위: 로컬 단일 세이브 슬롯, 무결성 검증, 푸시 대비 키 분리 정책.

---

## 0. 용어 구분

- **이어하기**
  - 저장된 **현재 런 상태**를 복원한다
  - 보드, 손패, 덱 순서, 골드, Jester 상태, 상점 상태까지 이어간다
- **시드 플레이**
  - 특정 시드로 **새 런을 시작**한다
  - 기존 저장 상태를 불러오는 기능이 아니다

따라서 타이틀 UX는 아래처럼 구분한다.

- `이어하기`: 저장된 현재 런 복원
- `랜덤 시작`: 랜덤 시드 새 런
- `시드 시작`: 사용자가 입력한 시드로 새 런

---

## 1. 목표

- 앱 종료 후 재실행 시 **현재 런 1개**를 복원할 수 있어야 한다.
- 복원 시 아래 상태가 실제 플레이와 동일해야 한다.
  - 보드
  - 손패
  - 남은 덱 순서
  - 제거 더미
  - 블라인드 점수/버림 자원
  - 스테이지
  - 골드
  - 장착 Jester
  - 상점 오퍼
  - stateful Jester 누적값
- 단순 로컬 파일 수정으로 골드나 진행 상태를 바꾸는 행위는 **검출 가능**해야 한다.
- 서버 없이도 동작해야 한다.

비목표:
- 완전한 치트 방지
- 여러 세이브 슬롯
- 클라우드 동기화
- 온라인 권위 서버 기반 저장

---

## 2. 저장 방식 결론

현재 프로젝트의 저장 방식은 **하이브리드 로컬 저장**으로 고정한다.

- **payload 저장소**: `GetStorage`
  - 런 전체 스냅샷 JSON 저장
- **비밀 키 저장소**: `flutter_secure_storage`
  - 앱 설치별 무결성 서명 키 저장
- **무결성 검증**: `HMAC-SHA256`
  - payload 저장 시 서명 생성
  - 불러올 때 서명 검증

즉, **게임 상태 본문은 일반 저장소**, **서명 키는 secure storage**, **복원 전 서명 검증** 구조다.

이 구조를 택한 이유:
- 현재 런 상태는 구조가 큰 JSON 스냅샷이라 secure storage 단독 저장소로 쓰기에는 부적합하다.
- `GetStorage`는 이미 프로젝트에 들어와 있어 도입 비용이 낮다.
- 금액/진행 상태 변조는 무결성 검증으로 우선 방어할 수 있다.

---

## 3. 위협 모델

이 설계가 막으려는 것:
- 저장 파일을 직접 열어 `gold`, `stageIndex`, `deckPile` 등을 수정하는 단순 변조
- 저장 데이터 일부만 덮어써서 상태를 유리하게 만드는 행위
- 저장 포맷 손상

이 설계가 완전히 막지 못하는 것:
- 루팅/탈옥 환경에서의 고급 조작
- 리패키징/런타임 패치
- 메모리 변조
- 서버 없는 상태에서의 강한 계정 보안

따라서 이 문서의 목표는 **강한 보안 저장소**가 아니라 **로컬 이어하기 + 무결성 검증**이다.

---

## 4. 저장 단위

저장 단위는 **현재 런 전체 스냅샷 1개**다.

권장 루트 구조:

```json
{
  "schemaVersion": 2,
  "savedAt": "2026-04-13T12:34:56.000Z",
  "activeScene": "battle",
  "session": { },
  "runProgress": { },
  "stageStartSession": { },
  "stageStartRunProgress": { }
}
```

`activeScene`은 현재 아래 둘 중 하나만 우선 지원한다.

- `battle`
- `shop`

UI 임시 상태는 저장하지 않는다.
- 선택된 손패
- 열린 상단 알림 / 하단 알림
- 임시 오버레이 인덱스
- 정산 연출 재생 중 상태

이유:
- 이어하기의 본질은 **게임 상태 복원**이지 **일시 UI 상태 재현**이 아니다.

추가 메모:
- 현재 저장 포맷은 **현재 시점 상태**와 함께 **현재 스테이지 시작 시점 스냅샷**도 저장한다.
- 옵션의 `재시작`은 세이브 삭제나 런 전체 재시작이 아니라, `stageStartSession` / `stageStartRunProgress` 복원으로 처리한다.
- 따라서 앱을 껐다 켜도 같은 기준으로 **현재 스테이지 재시작**이 가능하다.

알림 정책 메모:
- 현재 앱의 기본 정보성 피드백은 `lib/utils/common_ui.dart` 의 `showTopNotice(...)` 를 사용한다.
- 이는 Flutter 기본 `SnackBar`가 아니라 `OverlayEntry` 기반 상단 오버레이 알림이다.
- 버튼을 가리기 쉬운 하단 배치 알림은 기본값으로 두지 않는다.
- 다만 아래 경우에는 하단 알림 variant를 별도로 둘 수 있다.
  - 사용자가 바로 눌러야 하는 액션이 포함된 경우
  - 입력 폼/키보드와 연계되어 하단 맥락이 더 자연스러운 경우
  - 상단 HUD와 충돌해 가독성이 더 나빠지는 경우

---

## 5. session 저장 범위

`RummiPokerGridSession`에서 이어하기에 필요한 필드는 아래다.

- `runSeed`
- `deckCopiesPerTile`
- `maxHandSize`
- `blind`
  - `targetScore`
  - `boardDiscardsRemaining`
  - `boardDiscardsMax`
  - `handDiscardsRemaining`
  - `handDiscardsMax`
  - `scoreTowardBlind`
- `deckPile`
  - **남은 덱 카드 리스트를 현재 순서 그대로 저장**
- `boardCells`
  - 5x5 보드 상태
- `hand`
- `eliminated`

동일한 구조를 `stageStartSession`에도 저장한다.

중요:
- 덱 복원은 RNG 상태를 되살리는 방식이 아니라, **현재 남은 카드 순서 자체를 저장**하는 방식으로 고정한다.
- `deckPile` 순서가 이어하기 정확도를 결정한다.

---

## 6. runProgress 저장 범위

`RummiRunProgress`에서 이어하기에 필요한 필드는 아래다.

- `stageIndex`
- `gold`
- `rerollCost`
- `ownedJesterIds`
  - 장착 순서를 유지해야 한다
- `shopOffers`
  - `slotIndex`
  - `cardId`
  - `price`
- `statefulValuesBySlot`
- `playedHandCounts`

동일한 구조를 `stageStartRunProgress`에도 저장한다.

중요:
- 상태형 Jester는 슬롯 인덱스가 규칙이다.
- 따라서 `ownedJesterIds` 순서와 `statefulValuesBySlot` 인덱스가 함께 복원되어야 한다.
- 상점 오퍼는 카드 id만이 아니라 **표시 순서와 가격**까지 같이 복원한다.

---

## 7. 세이브 메타와 키 구조

저장 키 이름은 아래처럼 고정한다.

- `active_run_payload_v1`
- `active_run_signature_v1`
- `save_device_key_v1`

`payload`는 `GetStorage`에 저장한다.  
`signature`는 `GetStorage`에 저장한다.  
`save_device_key_v1`는 `flutter_secure_storage`에 저장한다.

`schemaVersion`은 payload 내부에 포함한다.

---

## 8. 직렬화 정책

### 8.1 공통 원칙

- 모든 세이브 DTO는 `toJson()` / `fromJson()`을 가진다.
- 런타임 클래스에 직접 JSON 책임을 섞기보다, 필요하면 저장용 DTO를 별도 둔다.
- 저장 포맷은 **명시적 필드명**을 사용한다.
- 타일은 최소 아래 필드를 저장한다.
  - `color`
  - `number`
  - `id`

### 8.2 보드 저장 방식

보드는 아래 둘 중 하나가 가능하다.

- 25칸 전체 저장
- 점유 칸만 저장

1차 구현은 **25칸 전체 저장**을 권장한다.

이유:
- 복원 로직이 단순하다
- 디버깅이 쉽다
- 필드 수가 작아 저장 부담이 거의 없다

---

## 9. 서명 검증 방식

저장 시:

1. 런 스냅샷을 JSON 문자열로 직렬화
2. secure storage의 설치별 키를 읽음
3. `HMAC-SHA256(payload)` 생성
4. `payload + signature` 저장

로드 시:

1. `payload` 읽기
2. `signature` 읽기
3. secure storage의 설치별 키를 읽음
4. 같은 방식으로 HMAC 재계산
5. 서명이 일치하면 복원
6. 불일치하면 손상/변조로 간주

검증 실패 시 정책:
- 이어하기 버튼 비활성화 또는 오류 안내
- 메시지 예시: `저장 데이터가 손상되었거나 현재 버전과 호환되지 않습니다.`
- 필요 시 세이브 삭제 버튼 제공

---

## 10. autosave 정책

autosave는 아래 시점에 수행한다.

- 드로우 후
- 보드 배치 후
- 보드 버림 후
- 손패 버림 후
- 줄 확정 후
- 상점 구매/판매/리롤 후
- 스테이지 전환 직전과 직후
- 앱 lifecycle이 `paused` / `inactive` 로 내려갈 때

원칙:

- 저장은 항상 **현재 시점 스냅샷 + 현재 스테이지 시작 스냅샷**을 같이 갱신한다.
- `stageStartSession` / `stageStartRunProgress` 는 스테이지 시작 직후 기준으로만 바뀐다.
- 따라서 전투 중간 저장이 여러 번 일어나도, 옵션의 `재시작` 기준점은 유지된다.

---

## 11. 웹 검증 흐름

웹에서는 `flutter run -d chrome` 개발 세션에 Playwright가 직접 붙을 때, Flutter가 스플래시에서 멈추는 경우가 있었다.  
현재 프로젝트의 웹 저장/이어하기 검증은 **정적 빌드 결과물(`build/web`)을 로컬 서버에 올린 뒤 Playwright로 검증**하는 절차를 기준으로 삼는다.

### 11.1 검증 목적

- 웹에서도 `active_run_payload_v1` 가 정상 저장되는지 확인
- 게임에서 `옵션 -> 나가기` 이후 타이틀이 **새로고침 없이 즉시** 갱신되는지 확인
- 타이틀에 `이어하기` 버튼이 즉시 노출되는지 확인

### 11.2 사전 조건

- `flutter build web` 이 성공해야 한다
- Playwright가 설치되어 있어야 한다
- 검증 대상은 `build/web` 정적 산출물이다

### 11.3 로컬 검증 절차

1. 웹 빌드

```bash
flutter build web
```

2. 정적 서버 실행

```bash
python3 -m http.server 8787 --directory build/web
```

3. Playwright가 없다면 별도 임시 디렉터리에서 설치

```bash
mkdir -p /tmp/rummipoker_pw
cd /tmp/rummipoker_pw
npm init -y
npm install playwright
npx playwright install chromium
```

4. 검증 스크립트 실행

핵심 흐름은 아래 순서다.

- `localStorage.clear()`
- 타이틀 진입
- Flutter semantics 활성화
- `랜덤 시작`
- 인게임 옵션 열기
- `나가기`
- 타이틀 복귀 후 `이어하기` 노출 확인

실제 검증에 사용한 예시는 아래와 같다.

```js
const { chromium } = require('playwright');

(async() => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 430, height: 932 },
    isMobile: true,
    hasTouch: true,
  });
  const page = await context.newPage();

  await page.goto('http://127.0.0.1:8787/', {
    waitUntil: 'networkidle',
    timeout: 120000,
  });
  await page.waitForTimeout(6000);
  await page.evaluate(() => localStorage.clear());
  await page.reload({ waitUntil: 'networkidle', timeout: 120000 });
  await page.waitForTimeout(6000);

  await page.locator('flt-semantics-placeholder').focus();
  await page.keyboard.press('Enter');
  await page.waitForTimeout(1000);

  await page.getByRole('button', { name: '랜덤 시작' }).click();
  await page.waitForTimeout(5000);

  await page.locator('flt-semantics[role="button"]').first().click();
  await page.waitForTimeout(1500);
  await page.getByRole('button', { name: '나가기' }).click();
  await page.waitForTimeout(3000);

  const bodyHtml = await page.locator('body').innerHTML();
  console.log(bodyHtml.includes('이어하기') ? 'HAS_CONTINUE' : 'NO_CONTINUE');
  console.log(
    'storage_len=',
    (await page.evaluate(() => localStorage.getItem('GetStorage') || '')).length,
  );

  await page.screenshot({ path: '/tmp/rummipoker_pw/verify_continue_title.png' });
  await browser.close();
})();
```

### 11.4 판정 기준

검증 성공 기준은 아래다.

- 게임 진입 후 `GetStorage` 길이가 증가한다
- 옵션 메뉴에 `나가기` 가 노출된다
- 타이틀 복귀 후 본문 HTML 또는 semantics 트리에 `이어하기` 가 존재한다
- 최종 스크린샷에서 `이어하기` 버튼이 보인다

### 11.5 현재 확인 결과

2026-04-13 기준, 정적 빌드 + Playwright 경로에서 아래를 확인했다.

- `랜덤 시작 -> 옵션 나가기 -> 타이틀 즉시 이어하기 표시` 성공
- 웹 `localStorage` 에 active run payload 유지 확인
- 검증 스크린샷: `/tmp/rummipoker_pw/verify_continue_title.png`

주의:

- 개발용 `flutter run -d chrome` 세션은 Playwright 재현성이 낮을 수 있다.
- 웹 회귀 검증은 우선 **정적 빌드 기준**으로 반복하는 것이 안전하다.

자동 저장은 **상태 변경 직후 저장**을 기본으로 한다.

저장 트리거:
- 드로우 후
- 배치 후
- 보드 버림 후
- 손패 버림 후
- 줄 확정 후
- 캐시아웃 후
- 상점 열기 후
- 상점 리롤 후
- 상점 구매 후
- 상점 판매 후
- 다음 스테이지 진입 직후
- 디버그 손패 크기 변경 후
- 앱 lifecycle `paused` / `inactive` / `hidden` 진입 시

원칙:
- 주기 저장보다 **이벤트 기반 저장**을 우선한다.
- 저장 실패가 게임 진행을 막지는 않되, 로그와 UI 표시로 추적 가능해야 한다.

---

## 11. 앱 진입/복원 UX

타이틀 화면에서 세이브 존재 여부와 서명 검증 결과에 따라 분기한다.

- 유효한 세이브 있음
  - `이어하기` 버튼 노출
  - 버튼 탭 시 `이어하기 / 삭제하기 / 취소` 선택
- 세이브 없음
  - `랜덤 시작`, `시드 시작`만 노출
- 세이브는 있으나 손상/호환 불가
  - `이어하기` 버튼은 유지
  - 탭 시 손상 안내 후 `삭제하기`를 유도

1차 구현 UX 원칙:
- 이어하기는 **최근 런 1개만** 지원
- 시드 플레이는 이어하기와 별개로 항상 **새 런 시작 기능**이다
- 현재 세이브가 있으면 새 게임 시작 시 덮어쓰기 여부를 확인할 수 있다

---

## 12. 푸시 알림 대비 키 분리 정책

세이브용 키와 푸시용 식별자는 **같은 값으로 재사용하지 않는다**.

분리 대상:

- `saveDeviceKey`
  - 세이브 payload 서명 검증용 비밀 키
  - 서버와 공유하지 않음
- `installationId`
  - 앱 설치 식별용 UUID
  - 필요 시 서버 전송 가능
- `pushToken`
  - FCM/APNs 등록 토큰
  - 푸시 전송용

이유:
- 보안 경계가 다르다
- 수명 주기가 다르다
- 세이브 키는 비밀 유지가 우선이고, 푸시 토큰은 서버 등록이 목적이다

향후 푸시를 붙이더라도, 이어하기 저장의 `saveDeviceKey`를 푸시 식별에 재사용하면 안 된다.

---

## 13. 플랫폼 정책

- Android / iOS / macOS / Windows / Linux
  - 하이브리드 저장을 기본 경로로 사용
- Web
  - 같은 구조를 유지하되, secure storage를 강한 비밀 저장소로 간주하지 않는다
  - 웹에서는 **무결성 체크** 수준으로만 해석한다

즉 웹은 모바일과 동일한 UX를 제공하되, 같은 보안 수준을 약속하지 않는다.

---

## 14. 구현 순서

1. 세이브 DTO와 JSON 스키마 확정
2. `flutter_secure_storage` / `crypto` 의존성 추가
3. 설치별 `saveDeviceKey` 생성/조회 계층 구현
4. HMAC 유틸 구현
5. `RummiPokerGridSession` / `RummiRunProgress` -> DTO 변환 추가
6. load / save / clear / verify 서비스 구현
7. `GameView` autosave 트리거 연결
8. `TitleView` 이어하기 진입 연결
9. 손상 세이브 처리 UI 추가
10. 테스트 및 문서 갱신

---

## 15. 테스트 기준

- 세이브 후 즉시 로드하면 `session`과 `runProgress`가 동일해야 한다
- 세이브 후 로드한 `stageStartSession` / `stageStartRunProgress`로 현재 스테이지 재시작이 가능해야 한다
- 덱 순서가 저장/복원 후 변하지 않아야 한다
- `ownedJesterIds` 순서와 `statefulValuesBySlot`가 같이 복원되어야 한다
- payload 한 필드라도 수정되면 서명 검증이 실패해야 한다
- `schemaVersion` 불일치 시 복원을 거부해야 한다
- 세이브 삭제 후 이어하기가 사라져야 한다

---

## 16. 현재 결정 사항 요약

- 이어하기는 **런 전체 스냅샷 1개**를 저장한다
- 그 스냅샷 안에 **현재 시점 + 현재 스테이지 시작 시점**을 함께 저장한다
- 저장소는 **GetStorage + flutter_secure_storage + HMAC** 하이브리드 구조다
- 세이브용 키와 푸시용 식별자는 **분리**한다
- 1차 목표는 **단일 로컬 이어하기 + 무결성 검증**이다
