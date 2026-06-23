# HabitCell 릴리즈 빌드 가이드

> Play Store / App Store 업로드용 릴리즈 빌드 절차

---

## 사전 준비

### 버전·빌드 번호 확인

업로드 전 `pubspec.yaml`의 `version`을 반드시 갱신:

```yaml
version: 1.0.1+2   # 1.0.1 = 버전명, 2 = 빌드 번호(versionCode)
```

- **같은 버전 재업로드 시에도** 빌드 번호는 반드시 증가해야 함
- `build-name` = versionName, `build-number` = versionCode

---

## Android (Play Store)

### 1. key.properties 설정

릴리즈 서명용 keystore 정보는 `android/key.properties`에 저장 (Git 미포함).

**초기 설정:**

```bash
cp android/key.properties.example android/key.properties
```

**key.properties 내용 (실제 비밀번호로 수정):**

```properties
storePassword=키스토어_비밀번호
keyPassword=별칭_비밀번호
keyAlias=habitcell_key
storeFile=/Users/cheng80/android_keystore/habitcell_keystore.jks
```

| 항목 | 값 |
|------|-----|
| keystore 경로 | `/Users/cheng80/android_keystore/habitcell_keystore.jks` |
| key alias | `habitcell_key` |

### 2. App Bundle 빌드 (권장)

Play Store 업로드용 AAB:

```bash
flutter build appbundle --release --build-name 1.0.1 --build-number 2
```

출력: `build/app/outputs/bundle/release/app-release.aab`

### 3. APK 빌드 (테스트·직접 배포용)

```bash
flutter build apk --release --build-name 1.0.1 --build-number 2
```

출력: `build/app/outputs/flutter-apk/app-release.apk`

### 4. key.properties 없을 때

`key.properties`가 없으면 release 빌드 시 **debug 서명**이 사용됨. Play Store 업로드는 불가.

---

## iOS (App Store)

### 1. IPA 릴리즈 빌드

App Store Connect 업로드용 IPA 생성:

```bash
flutter build ipa --release --build-name 1.0.1 --build-number 2
```

출력:
- 기본 경로: `build/ios/ipa/Runner.ipa`

### 2. Transporter로 업로드

1. Mac App Store에서 **Transporter** 앱 설치
2. Transporter 실행 후 Apple Developer 계정으로 로그인
3. `build/ios/ipa/Runner.ipa` 파일을 드래그 앤 드롭
4. **Deliver(전송)** 클릭하여 App Store Connect로 업로드
5. App Store Connect에서 처리 완료 후 TestFlight/심사 제출 진행

### 3. 업로드 전 확인 포인트

- `pubspec.yaml` 버전/빌드 번호 증가 여부 확인
- Xcode Signing(Team, Bundle Identifier, Provisioning Profile) 정상 설정 확인
- 동일 버전 재업로드 시 빌드 번호(`build-number`)는 반드시 증가

---

## 빌드 명령어 요약

| 플랫폼 | 명령어 |
|--------|--------|
| Android AAB | `flutter build appbundle --release --build-name <버전> --build-number <빌드번호>` |
| Android APK | `flutter build apk --release --build-name <버전> --build-number <빌드번호>` |
| iOS IPA | `flutter build ipa --release --build-name <버전> --build-number <빌드번호>` |

---

## 관련 문서

- [RELEASE_CHECKLIST.md](./RELEASE_CHECKLIST.md) — 앱 스토어 출시 체크리스트
- [IOS_PROFILE_BUILD.md](./IOS_PROFILE_BUILD.md) — iOS 프로필 빌드·실기기 설치
