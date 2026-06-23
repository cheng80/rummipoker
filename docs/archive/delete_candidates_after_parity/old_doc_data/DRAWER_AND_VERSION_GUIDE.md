# Drawer 설정 및 앱 버전 표시 가이드

> HabitCell에서 적용한 Drawer 구조·패키지·버전 관리 방식을 문서화. 다른 앱(Todo 등)에도 동일하게 적용할 수 있다.

---

## 1. Drawer 구조 (헤더·스크롤·푸터)

### 1.1 레이아웃 개요

```
Drawer
└── SafeArea
    └── Column
        ├── [헤더 - 고정] 제목, Divider
        ├── [중간 - 스크롤] Expanded + ListView
        └── [푸터 - 고정] 앱 버전
```

- **헤더**: 상단 고정. 앱 설정 제목, 길게 누르면 개발 메뉴 토글 등
- **중간**: `Expanded` + `ListView` → 메뉴가 많아지면 스크롤
- **푸터**: 하단 고정. 앱 버전 표시 (`package_info_plus`)

### 1.2 코드 구조 (Flutter)

```dart
return Drawer(
  child: SafeArea(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── 헤더 (고정) ─────────────────
        GestureDetector(
          onLongPress: () => setState(() => _showDevButtons = !_showDevButtons),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                Icon(Icons.settings, ...),
                Text('settings'.tr(), ...),
              ],
            ),
          ),
        ),
        Divider(height: 1),

        // ─── 중간 (스크롤) ─────────────────
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // 토글들 (다크모드, 화면꺼짐 등)
              // ListTile들 (언어, 카테고리, 백업 등)
              // 개발 메뉴 (조건부)
              if (_showDevButtons) ...[
                Divider(height: 1),
                ListTile(...),
              ],
            ],
          ),
        ),

        // ─── 푸터 (고정) ─────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final v = snapshot.data;
              final text = v != null
                  ? '${'appVersion'.tr()} ${v.version}+${v.buildNumber}'
                  : 'appVersion'.tr();
              return Text(text, style: TextStyle(color: p.textMeta, fontSize: 12));
            },
          ),
        ),
      ],
    ),
  ),
);
```

### 1.3 적용 시 유의사항

| 항목 | 설명 |
|------|------|
| `Expanded` | Column 내부에서 남은 공간을 ListView에 할당. 없으면 overflow |
| `ListView` | 스크롤 가능. 메뉴가 화면보다 길어지면 스크롤 |
| 푸터 | `Column`의 마지막 child. 항상 하단에 고정 |

---

## 2. 패키지 설정

### 2.1 package_info_plus

앱 버전·빌드 번호를 런타임에 조회한다.

**설치**

```bash
flutter pub add package_info_plus
```

**사용**

```dart
import 'package:package_info_plus/package_info_plus.dart';

// 비동기 조회 (FutureBuilder 등에서 사용)
final info = await PackageInfo.fromPlatform();
print(info.version);      // "1.0.0"
print(info.buildNumber);  // "1"
print(info.appName);      // 앱 이름
```

**주의**: `PackageInfo.fromPlatform()`은 `WidgetsFlutterBinding.ensureInitialized()` 이후에 호출. `runApp()` 전에 호출하면 예외 발생 가능. `FutureBuilder` 내부에서 호출하면 안전.

### 2.2 번역 키

다국어 지원 시 `appVersion` 키 추가:

| 파일 | 키 | 값 |
|------|-----|-----|
| ko.json | appVersion | "버전" |
| en.json | appVersion | "Version" |
| ja.json | appVersion | "バージョン" |
| zh-CN.json | appVersion | "版本" |
| zh-TW.json | appVersion | "版本" |

---

## 3. 버전 업데이트 방법

### 3.1 pubspec.yaml

```yaml
version: 1.0.0+1   # 버전명+빌드번호
```

| 구분 | 설명 | 예 |
|------|------|-----|
| 버전명 | 사용자 노출 (Drawer, 스토어) | 1.0.0 → 1.0.1 |
| 빌드 번호 | 스토어 업로드 시 이전보다 커야 함 | +1 → +2 |

**Flutter는 자동 증가 없음** → 마켓 빌드 시마다 수동 수정.

### 3.2 수동 수정

마켓 빌드 전 `pubspec.yaml` 수정:

```yaml
version: 1.0.1+2   # 이전 1.0.0+1 에서 올림
```

### 3.3 빌드 시 오버라이드

pubspec 수정 없이 빌드 시 지정:

```bash
flutter build apk --build-name=1.0.1 --build-number=2
flutter build appbundle --build-name=1.0.1 --build-number=2
flutter build ios --build-name=1.0.1 --build-number=2
```

### 3.4 CI/CD 자동화 (선택)

- Git 태그 또는 커밋 수로 `build-number` 자동 증가
- `pubspec.yaml`의 `version`은 수동, `--build-number`만 스크립트로 전달

---

## 4. 다른 앱에 적용하기 (Todo 등)

### 4.1 체크리스트

| 단계 | 작업 |
|------|------|
| 1 | `flutter pub add package_info_plus` |
| 2 | Drawer를 `Column` + `Expanded(ListView)` + 푸터 구조로 변경 |
| 3 | 푸터에 `FutureBuilder<PackageInfo>` 추가 |
| 4 | 번역 파일에 `appVersion` 키 추가 |
| 5 | `RELEASE_CHECKLIST.md`에 버전 업데이트 항목 추가 |

### 4.2 Drawer가 단순한 경우

메뉴가 적어 스크롤이 필요 없다면 `ListView`만 사용해도 된다. 푸터(버전)는 `Column` 마지막에 두면 된다.

```dart
Column(
  children: [
    Header(...),
    Expanded(child: ListView(children: [...])),
    FooterVersion(),  // 푸터
  ],
)
```

### 4.3 메뉴 분리 (화면 분리)

Drawer가 복잡해지면 일부 메뉴를 별도 화면으로 분리한다.

- 예: "백업" → `BackupSettings` 화면
- Drawer에는 "백업" 한 줄만 두고, 탭 시 해당 화면으로 이동

---

## 5. 참고 문서

| 문서 | 내용 |
|------|------|
| `README.md` | 버전 관리 요약 |
| `docs/RELEASE_CHECKLIST.md` | 출시 전 버전 업데이트 체크 항목 |

---

## 6. HabitCell 적용 요약

| 항목 | 적용 내용 |
|------|----------|
| Drawer | 헤더(세팅) 고정, 중간 스크롤, 푸터(버전) 고정 |
| 개발 메뉴 | 헤더 길게 누르기 → ListView 내 조건부 표시 |
| 백업 | 별도 `BackupSettings` 화면으로 분리 |
| 버전 표시 | `package_info_plus` + `FutureBuilder` |
| 번역 | appVersion (ko, en, ja, zh-CN, zh-TW) |
