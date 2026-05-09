# iOS 프로필 빌드 및 실기기 설치

## 사전 준비

- Mac + Xcode
- iPhone 실기기 (USB 또는 무선 연결)
- Apple Developer 계정 (서명용)

## 1. 연결된 기기 확인

```bash
flutter devices
```

예시 출력:
```
00008120-00140CD03C44C01E • CHENG_iPhone (wireless) • ios • iOS 18.x
```

## 2. 프로필 빌드

실기기용 프로필 모드 빌드 (성능 측정·디버깅용):

```bash
flutter build ios --profile -d <DEVICE_ID>
```

**예시 (CHENG_iPhone):**
```bash
flutter build ios --profile -d 00008120-00140CD03C44C01E
```

빌드 결과: `build/ios/iphoneos/Runner.app`

## 3. 실기기에 설치 및 실행

### 방법 A: Flutter run (권장)

```bash
flutter run --profile -d <DEVICE_ID>
```

**예시:**
```bash
flutter run --profile -d 00008120-00140CD03C44C01E
```

### 방법 B: Xcode에서 실행

1. `ios/Runner.xcworkspace`를 Xcode로 열기
2. 상단 기기 선택에서 해당 iPhone 선택
3. Run (⌘R) 실행

### 방법 C: 빌드된 앱만 설치

```bash
# Xcode 커맨드라인 도구로 설치
xcrun devicectl device install app --device <DEVICE_ID> build/ios/iphoneos/Runner.app
```

## 참고

| 모드 | 용도 |
|------|------|
| `--debug` | 기본, 핫 리로드, 디버깅 |
| `--profile` | 성능 프로파일링, 실기기 테스트 |
| `--release` | 스토어 배포용 |
