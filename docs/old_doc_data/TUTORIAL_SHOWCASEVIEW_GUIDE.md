# ShowcaseView 튜토리얼 구현 가이드

> TagDo 앱에서 적용한 `showcaseview` 패키지 기반 온보딩 튜토리얼 구현 방식을 문서화. 다른 앱에도 동일하게 적용할 수 있다.

---

## 1. 패키지 정보

```yaml
# pubspec.yaml
dependencies:
  showcaseview: ^5.0.1
```

- pub.dev: https://pub.dev/packages/showcaseview
- 위젯 위에 스포트라이트 오버레이를 띄워 단계별 안내를 제공

---

## 2. 핵심 제약 사항 (반드시 숙지)

### 2.1 튜토리얼 중 금지 동작

| 금지 동작 | 이유 | 증상 |
|-----------|------|------|
| **바텀시트 열기** | 오버레이와 새 라우트 충돌 | 멈춤, 무반응 |
| **다이얼로그 열기** | 포커스 충돌 | 멈춤, 무반응 |
| **페이지 이동 (Navigator.push)** | GlobalKey가 트리에서 사라짐 | 에러, 크래시 |
| **Drawer 열기/닫기 (수동)** | 오버레이 위치 꼬임 | 스포트라이트 위치 이탈 |

### 2.2 핵심 원칙

```
모든 Showcase 대상 위젯은 같은 화면에서 동시에 접근 가능해야 한다.
페이지 전환이나 모달은 튜토리얼이 끝난 뒤에만 허용한다.
```

### 2.3 Drawer 안 위젯을 포함하려면

Drawer 내부 위젯(예: 태그 관리)을 튜토리얼에 포함하려면:

1. 튜토리얼 시작 전에 **Drawer를 미리 열어놓는다**
2. Drawer 단계가 끝나면 `onComplete` 콜백에서 **Drawer를 닫는다**
3. 이후 단계는 메인 화면 위젯으로 이어간다

---

## 3. 아키텍처 (TagDo 기준)

### 3.1 파일 구조

```
lib/
├── view/
│   ├── home.dart           # 튜토리얼 메인: 초기화, 단계 정의, 시작/재시작
│   ├── home_widgets.dart   # 개별 위젯에 Showcase 래핑 (검색, 필터 등)
│   └── app_drawer.dart     # Drawer 내 Showcase 래핑 + "다시 보기" 메뉴
└── util/
    └── app_storage.dart    # 튜토리얼 완료 여부 영속화 (GetStorage)
```

### 3.2 역할 분담

| 파일 | 역할 |
|------|------|
| `home.dart` | GlobalKey 정의, ShowcaseView.register(), startShowCase(), 재시작 |
| `home_widgets.dart` | 각 위젯을 `Showcase(key: ..., child: ...)` 로 감싸기 |
| `app_drawer.dart` | Drawer 내 위젯 Showcase 래핑 + "튜토리얼 다시 보기" ListTile |
| `app_storage.dart` | `tutorial_completed` 플래그 저장/조회/초기화 |

---

## 4. 구현 단계

### 4.1 Step 1: GlobalKey 정의

튜토리얼 대상 위젯마다 `GlobalKey`를 하나씩 만든다.

```dart
// home.dart - State 클래스 내부
final _drawerKey = GlobalKey();     // 단계 1: 메뉴 버튼
final _searchKey = GlobalKey();     // 단계 2: 검색
final _addKey = GlobalKey();        // 단계 3: 할 일 추가
final _filterKey = GlobalKey();     // 단계 4: 필터 칩
final _firstItemKey = GlobalKey();  // 단계 5: 첫 번째 아이템
```

### 4.2 Step 2: Showcase로 위젯 감싸기

각 위젯을 `Showcase`로 래핑한다. 설명 텍스트는 다국어 키 사용.

```dart
Showcase(
  key: _searchKey,
  description: 'tutorial_step_2'.tr(),
  tooltipBackgroundColor: p.sheetBackground,
  textColor: p.textOnSheet,
  tooltipBorderRadius: ConfigUI.cardRadius,
  child: IconButton(
    onPressed: _toggleSearchMode,
    icon: Icon(Icons.search),
  ),
),
```

### 4.3 Step 3: ShowcaseView 등록 (initState/didChangeDependencies)

```dart
void _initTutorial(BuildContext context) {
  ShowcaseView.register(
    // 이미 완료했으면 비활성화
    enableShowcase: !AppStorage.getTutorialCompleted(),

    // 건너뛰기(dismiss) 또는 완료(finish) 시 플래그 저장
    onDismiss: (_) => AppStorage.setTutorialCompleted(),
    onFinish: () => AppStorage.setTutorialCompleted(),

    // 단계 전환 시 콜백 (Drawer 닫기 등)
    onComplete: (index, key) {
      // 예: Drawer 단계 → 메인 화면 단계 전환 시 Drawer 닫기
      if (index == 1) scaffoldKey.currentState?.closeDrawer();
    },

    // 건너뛰기/다음 버튼 설정
    globalTooltipActionConfig: TooltipActionConfig(
      alignment: MainAxisAlignment.spaceBetween,
      position: TooltipActionPosition.inside,
    ),
    globalTooltipActions: [
      TooltipActionButton(
        type: TooltipDefaultActionType.skip,
        name: 'tutorial_skip'.tr(),
        onTap: () => ShowcaseView.get().dismiss(),
      ),
      TooltipActionButton(
        type: TooltipDefaultActionType.next,
        name: 'tutorial_next'.tr(),
      ),
    ],
  );
}
```

### 4.4 Step 4: 튜토리얼 시작

`addPostFrameCallback`에서 시작해야 위젯 트리가 완성된 후 실행된다.

```dart
WidgetsBinding.instance.addPostFrameCallback((_) async {
  if (AppStorage.getTutorialCompleted() || !mounted) return;

  // Drawer 내 위젯이 포함된 경우: 먼저 Drawer 열기
  await Future.delayed(const Duration(milliseconds: 400));
  if (!mounted) return;
  scaffoldKey.currentState?.openDrawer();
  await Future.delayed(const Duration(milliseconds: 350));
  if (!mounted) return;

  // 단계 순서대로 키 배열 전달
  final keys = [
    _drawerInnerKey,  // Drawer 안 위젯
    _drawerKey,       // 메뉴 버튼 (Drawer 닫힌 후 보임)
    _searchKey,
    _addKey,
    _filterKey,
    _firstItemKey,
  ];
  ShowcaseView.get().startShowCase(keys);
});
```

### 4.5 Step 5: 영속화 (GetStorage)

```dart
// app_storage.dart
class AppStorage {
  static const String _keyTutorialCompleted = 'tutorial_completed';

  static bool getTutorialCompleted() =>
      _storage.read<bool>(_keyTutorialCompleted) ?? false;

  static Future<void> setTutorialCompleted() =>
      _storage.write(_keyTutorialCompleted, true);

  static Future<void> resetTutorialCompleted() =>
      _storage.write(_keyTutorialCompleted, false);
}
```

### 4.6 Step 6: "다시 보기" 기능

Drawer 등에 "튜토리얼 다시 보기" 메뉴를 추가한다.

```dart
// app_drawer.dart
ListTile(
  leading: Icon(Icons.school_outlined),
  title: Text('tutorial_replay'.tr()),
  onTap: () {
    Navigator.pop(context);                    // Drawer 닫기
    AppStorage.resetTutorialCompleted();        // 플래그 초기화
    widget.onTutorialReplay?.call();            // 콜백 호출
  },
),

// home.dart - 재시작 콜백
void _restartTutorial() {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    scaffoldKey.currentState?.openDrawer();
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    final sv = ShowcaseView.get();
    sv.enableShowcase = true;
    sv.startShowCase(keys);
  });
}
```

---

## 5. 번역 키

| 키 | ko | en | ja |
|----|----|----|-----|
| tutorial_skip | 건너뛰기 | Skip | スキップ |
| tutorial_next | 다음 | Next | 次へ |
| tutorial_step_1 | 태그로 할 일을 분류합니다... | Categorize with tags... | タグで分類... |
| tutorial_replay | 튜토리얼 다시 보기 | Replay tutorial | チュートリアル再生 |

---

## 6. Drawer 포함 튜토리얼 흐름도

```
앱 시작
  │
  ├─ AppStorage.getTutorialCompleted() == true → 튜토리얼 스킵
  │
  └─ false → 튜토리얼 시작
       │
       ├─ [1] postFrameCallback 대기 (400ms)
       ├─ [2] Drawer 열기 (openDrawer)
       ├─ [3] Drawer 애니메이션 대기 (350ms)
       ├─ [4] startShowCase([drawerInner, drawer, search, add, filter, item])
       │
       │   단계 1: Drawer 내 위젯 스포트라이트
       │   단계 2: 메뉴 버튼 → onComplete에서 closeDrawer()
       │   단계 3~N: 메인 화면 위젯들
       │
       ├─ 사용자가 "건너뛰기" → onDismiss → setTutorialCompleted()
       └─ 마지막 단계 완료 → onFinish → setTutorialCompleted()
```

---

## 7. 다른 앱에 적용 체크리스트

| 단계 | 작업 |
|------|------|
| 1 | `flutter pub add showcaseview` |
| 2 | 튜토리얼 대상 위젯에 `GlobalKey` 정의 |
| 3 | 각 위젯을 `Showcase(key: ..., child: ...)` 로 래핑 |
| 4 | 메인 화면에서 `ShowcaseView.register()` 호출 |
| 5 | `addPostFrameCallback`에서 `startShowCase(keys)` |
| 6 | AppStorage에 완료 플래그 저장/조회/초기화 |
| 7 | 번역 파일에 튜토리얼 텍스트 키 추가 |
| 8 | "다시 보기" 메뉴 추가 (선택) |
| 9 | **Drawer 포함 시**: 미리 열기 + onComplete에서 닫기 |

---

## 8. 트러블슈팅

| 증상 | 원인 | 해결 |
|------|------|------|
| 튜토리얼 중 멈춤/무반응 | 바텀시트·다이얼로그·페이지 이동 시도 | 튜토리얼 중 모달/네비게이션 금지 |
| 스포트라이트 위치 이상 | GlobalKey 위젯이 화면에 없음 | 모든 대상이 같은 화면에 있는지 확인 |
| 앱 재시작 시 튜토리얼 반복 | 완료 플래그 미저장 | onDismiss + onFinish 모두에서 저장 |
| Drawer 단계에서 스포트라이트 안 보임 | Drawer가 안 열린 상태 | startShowCase 전에 openDrawer + delay |
| "다시 보기" 후 동작 안 함 | enableShowcase가 false | 재시작 시 `sv.enableShowcase = true` 설정 |
| dispose 시 에러 | ShowcaseView 미해제 | dispose에서 `ShowcaseView.get().unregister()` 호출 |

---

## 9. 참고

- TagDo 구현: `lib/view/home.dart`, `lib/view/home_widgets.dart`, `lib/view/app_drawer.dart`
- 영속화: `lib/util/app_storage.dart` (GetStorage)
- showcaseview 공식 문서: https://pub.dev/packages/showcaseview
