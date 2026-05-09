# in_app_review 구현 가이드

> [pub.dev/packages/in_app_review](https://pub.dev/packages/in_app_review) 공식 지침 및 테스트 유의사항 요약

---

## 1. 핵심 원칙

**`requestReview()`는 버튼/Call-to-Action에 사용하지 말 것.** 플랫폼이 횟수 제한(quota)을 강제하므로, 버튼으로 호출하면 대부분 팝업이 뜨지 않는다. 대신 `openStoreListing()`를 버튼에 사용한다.

---

## 2. API 사용 지침

### `requestReview()` — 인앱 리뷰 팝업

| Do ✅ | Don't ❌ |
|-------|----------|
| 앱을 충분히 사용한 후 호출 (예: 할 일 완료 후, 며칠 후) | UI 버튼/CTA로 호출 |
| 가끔만 호출 (quota 초과 시 팝업 미표시) | 작업 중간에 끼어 넣기 |

```dart
if (await inAppReview.isAvailable()) {
  inAppReview.requestReview();
}
```

### `openStoreListing()` — 스토어 리뷰 화면으로 이동

- **횟수 제한 없음** → Drawer/설정에 "평점 남기기" 버튼으로 사용 가능
- **iOS/MacOS**: `appStoreId` 필수 (App Store Connect > General > App Information > Apple ID)
- **Windows**: `microsoftStoreId` 필수

```dart
inAppReview.openStoreListing(appStoreId: '앱스토어ID');
```

---

## 3. 공식 가이드라인 링크

- [Apple HIG - Ratings and Reviews](https://developer.apple.com/design/human-interface-guidelines/ios/system-capabilities/ratings-and-reviews/)
- [Android - When to request](https://developer.android.com/guide/playcore/in-app-review#when-to-request)
- [Android - Design guidelines](https://developer.android.com/guide/playcore/in-app-review#design-guidelines)

---

## 4. 테스트 유의사항

### Android

| 상황 | 해결 |
|------|------|
| 앱 미출시 | Internal testing track에 applicationID 등록 필요 |
| 리뷰 불가 | 해당 계정으로 Play Store에서 앱 다운로드 후 테스트 |
| 여러 계정 | Play Store 기본 계정 선택 |
| 엔터프라이즈 계정 | Gmail 계정 사용 |
| 이미 리뷰 작성 | Play Store에서 리뷰 삭제 |
| Quota 초과 | Internal test track 또는 Internal app sharing 사용 |
| Play Store/서비스 문제 | Play Store가 sideload된 기기일 수 있음 → 다른 기기 사용 |

**실제 리뷰 작성은 production track에서만 가능.** Internal testing 등에서는 Submit 버튼이 비활성화됨.

`requestReview()` 테스트: **Internal app sharing**으로 앱 번들 업로드 후 테스트.

### iOS

| 상황 | 비고 |
|------|------|
| `requestReview()` | 시뮬레이터·실기기에서 테스트 가능 |
| **TestFlight** | `requestReview()` 호출 시 **아무 동작 없음** (문서화됨) |
| 실제 리뷰 | production 환경에서만 가능, 로컬 테스트 시 Submit 비활성화 |
| `openStoreListing()` | **실기기만** (시뮬레이터에 App Store 없음) |

### MacOS

로컬 실행으로 테스트 가능.

---

## 5. TagDo 적용 방안

| 기능 | 호출 시점 | 메서드 |
|------|-----------|--------|
| 인앱 리뷰 팝업 | 할 일 N개 완료 후, 또는 앱 사용 며칠 후 | `requestReview()` |
| 평점 남기기 버튼 | Drawer/설정 메뉴 | `openStoreListing(appStoreId: '...')` |

- `requestReview()`: GetStorage에 완료 횟수·접속일 저장 후, 조건 만족 시 자동 호출
- `openStoreListing()`: Drawer에 ListTile 추가, 탭 시 호출

---

## 6. 플랫폼별 요구사항

- **Android**: API 21+, Google Play Store 설치 필요
- **iOS**: iOS 10.3+
- **MacOS**: 10.14+
