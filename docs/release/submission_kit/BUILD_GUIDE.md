# Build Guide

## 역할

이 문서는 플랫폼 공통 버전 관리만 다룬다. 실제 빌드 절차는 각 플랫폼 문서 하나만 열어도 끝까지 진행할 수 있게 분리한다.

- Web: `WEB_BUILD_GUIDE.md`
- Android: `ANDROID_BUILD_NOTES.md`
- iOS: `IOS_PROFILE_BUILD.md`

## 공통 버전 관리

현재 앱은 title 진입 메뉴 하단 footer에 앱 버전을 고정 표시한다. 버전 값은 `package_info_plus`의 `PackageInfo.fromPlatform()`으로 읽고, 표시 문구는 번역 키 `appVersion`을 사용한다.

기본 버전은 `pubspec.yaml`의 `version` 값을 따른다.

```yaml
version: 1.0.0+1
```

마켓 빌드에서 버전명/빌드번호를 명시해야 할 때는 플랫폼별 빌드 명령의 `--build-name`, `--build-number` 옵션으로 override할 수 있다.

```bash
flutter build appbundle --build-name=1.0.0 --build-number=1
flutter build ios --build-name=1.0.0 --build-number=1
flutter build web --build-name=1.0.0 --build-number=1
```

주의:

- 같은 버전명을 다시 업로드하더라도 build number는 반드시 이전 업로드보다 커야 한다.
- `build-name`은 사용자에게 보이는 버전명, `build-number`는 스토어 업로드용 내부 빌드 번호다.
- 제출 직전에는 `pubspec.yaml`, 빌드 명령 override, title footer 표시가 서로 같은 값을 가리키는지 확인한다.
- title 화면 하단의 `버전 1.0.0+1` 또는 각 언어의 `appVersion` 문구가 실제 제출 빌드 번호와 일치해야 한다.
