# Android Gradle 설정 마이그레이션

> 2026-02-16 기준, table_now_app 프로젝트 설정에 맞춰 habit_app Android 빌드 구성을 업데이트한 내역입니다.

---

## 개요

- **목적**: AGP/Gradle 버전 호환성 문제 해결 및 최신 Flutter 템플릿 정렬
- **참고 프로젝트**: `table_now_app` (Team01_Project_02)
- **변경일**: 2026-02-16

---

## 변경 사항 요약

| 항목 | 이전 | 이후 |
|------|------|------|
| **빌드 스크립트 형식** | Groovy (`.gradle`) | Kotlin DSL (`.gradle.kts`) |
| **Android Gradle Plugin (AGP)** | 7.3.0 → 8.9.1 | **8.11.1** |
| **Gradle** | 8.10 → 8.11.1 | **8.14** |
| **Kotlin** | 1.7.10 → 2.1.0 | **2.2.20** |
| **Java** | 1.8 | **17** |

---

## 파일별 변경 내역

### 1. `android/settings.gradle` → `android/settings.gradle.kts`

- Groovy → Kotlin DSL 변환
- `pluginManagement` 블록 Kotlin 문법 적용
- 플러그인 버전:
  - `com.android.application`: 8.11.1
  - `org.jetbrains.kotlin.android`: 2.2.20
- FlutterFire(Google Services) 미사용으로 해당 플러그인 미포함

### 2. `android/build.gradle` → `android/build.gradle.kts`

- Groovy → Kotlin DSL 변환
- `buildscript` 블록 제거 (플러그인 버전은 `settings.gradle.kts`에서 관리)
- `rootProject.buildDir` → `rootProject.layout.buildDirectory` API로 변경
- `subprojects` 블록 유지 (`evaluationDependsOn(":app")` 포함)

### 3. `android/app/build.gradle` → `android/app/build.gradle.kts`

- Groovy → Kotlin DSL 변환
- **Java 1.8 → Java 17** 업그레이드
- `versionCode`/`versionName`: `localProperties` 대신 `flutter.versionCode`/`flutter.versionName` 직접 사용
- `sourceSets` 제거 (기본값 사용)
- `compileSdkVersion` → `compileSdk` (Kotlin DSL 문법)
- `minSdkVersion` → `minSdk`, `targetSdkVersion` → `targetSdk`
- `coreLibraryDesugaringEnabled` → `isCoreLibraryDesugaringEnabled`

### 4. `android/gradle/wrapper/gradle-wrapper.properties`

```properties
# 이전
distributionUrl=https\://services.gradle.org/distributions/gradle-8.11.1-all.zip

# 이후
distributionUrl=https\://services.gradle.org/distributions/gradle-8.14-all.zip
```

---

## 삭제된 파일

- `android/settings.gradle`
- `android/build.gradle`
- `android/app/build.gradle`

---

## 생성된 파일

- `android/settings.gradle.kts`
- `android/build.gradle.kts`
- `android/app/build.gradle.kts`

---

## 호환성

- **Flutter**: 3.38.9 (stable) 기준 테스트 완료
- **빌드 결과**: `flutter build apk --debug` 성공 확인

---

## 참고

- table_now_app은 FlutterFire(Google Services)를 사용하나, habit_app은 미사용
- Java 17 업그레이드로 인해 일부 플러그인 호환성 이슈가 있을 수 있음
- 문제 발생 시 `--stacktrace` 옵션으로 빌드하여 상세 로그 확인
