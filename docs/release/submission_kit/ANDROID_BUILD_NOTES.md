# Android Build Notes

## 목적

Android Play Store 제출 후보 빌드 절차다. Android 빌드만 진행할 때는 이 문서 하나만 보면 된다. 과거 앱 package, signing, icon 설정은 그대로 가져오지 않는다.

## 공통 준비

```bash
flutter pub get
flutter analyze
```

Android 제출 전에는 `applicationId`, 버전명, build number, release signing을 함께 확인한다.

## 기본 명령

```bash
flutter build appbundle --release --build-name=<버전명> --build-number=<빌드번호>
flutter build apk --release --build-name=<버전명> --build-number=<빌드번호>
```

출력:

- AAB: `build/app/outputs/bundle/release/app-release.aab`
- APK: `build/app/outputs/flutter-apk/app-release.apk`

주의:

- 같은 버전명을 다시 업로드해도 `--build-number`는 반드시 증가해야 한다.
- title 화면 하단 버전 footer가 제출 빌드 번호와 일치하는지 확인한다.

## Release signing

Play Store 업로드용 AAB는 release signing이 적용되어야 한다. `android/key.properties`는 Git에 포함하지 않고 로컬에만 둔다. 현재 Gradle 설정은 release build 요청 시 `android/key.properties`가 없으면 빌드를 실패시킨다.

### 1. Keystore 생성

Rummi Poker 제출용 keystore가 없다면 먼저 생성한다.

```bash
mkdir -p ~/android_keystore
keytool -genkey -v \
  -keystore ~/android_keystore/rummipoker_keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias rummipoker_key
```

```bash
mkdir -p /Users/cheng80/android_keystore

keytool -genkeypair \
  -v \
  -keystore /Users/cheng80/android_keystore/rummipoker_keystore.jks \
  -storepass 'm32821616' \
  -keypass 'm32821616' \
  -alias rummipoker_key \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -dname "CN=rummipoker, OU=dev, O=rummipoker, L=Seoul, ST=Seoul, C=KR"

```

주의:

- 이 `.jks` 파일은 앱 업데이트 서명에 계속 필요하므로 백업해야 한다.
- keystore 비밀번호, key 비밀번호, alias를 잃어버리면 같은 앱의 업데이트가 불가능해질 수 있다.
- `.jks` 파일은 Git에 포함하지 않는다.

### 2. key.properties 설정

초기 설정:

```bash
cp android/key.properties.example android/key.properties
```

`android/key.properties` 예시:

```properties
storePassword=<keystore-password>
keyPassword=<key-password>
keyAlias=<rummi-poker-key-alias>
storeFile=<absolute-path-to-rummi-poker-keystore.jks>
```

예시:

```properties
storePassword=실제_키스토어_비밀번호
keyPassword=실제_키_비밀번호
keyAlias=rummipoker_key
storeFile=/Users/cheng80/android_keystore/rummipoker_keystore.jks
```

주의:

- 과거 문서의 `habitcell_key`나 HabitCell keystore 경로를 그대로 쓰지 않는다.
- Rummi Poker 제출용 keystore, alias, 비밀번호를 별도로 확정한다.
- `android/key.properties`가 없거나 잘못되면 release 빌드가 실패해야 정상이다.

### 3. Gradle 연결

`android/app/build.gradle.kts`는 `android/key.properties`를 읽어 release signingConfig에 연결한다. 제출 전에는 release build 로그와 출력물을 확인해 debug signing으로 떨어지지 않았는지 확인한다.

## 확인 항목

- `applicationId`가 Rummi Poker 제출용으로 확정됐는지
- 앱 표시명이 Rummi Poker로 보이는지
- 버전 코드와 버전명이 제출 정책과 맞는지
- release signing 설정이 적용됐는지
- release build가 `android/key.properties` 없이 성공하지 않는지
- `android/key.properties`가 Git에 포함되지 않았는지
- `.jks` 또는 `.keystore` 파일이 Git에 포함되지 않았는지
- minSdk/targetSdk가 현재 Flutter/Play Console 기준과 맞는지
- Android 13+ 권한 안내가 실제 사용 권한과 맞는지
- Debug fixture 진입점이 release에서 숨겨지는지

## 제출 주의점

- HabitCell/TagDo 시대의 앱명, 아이콘, 스플래시, package id는 재사용하지 않는다.
- Gradle 문법이나 Android plugin 버전은 현재 프로젝트 파일을 기준으로 판단한다.
- 스토어 데이터 보안 설문은 실제 SDK와 네트워크 사용 기준으로 제출 직전 재확인한다.
