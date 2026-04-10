# 폰 기준 UI + 태블릿 가로 배경 확장 패턴

> **목적**: iPhone에서 설계한 세로형 게임/앱 UI를 **그대로 유지**하면서, iPad 등 **가로가 넓은 화면**에서는 콘텐츠를 **화면 중앙**에 두고, **좌우(또는 배경 레이어)만** 늘어나게 하는 구조를 문서화한다.  
> **구현 참조**: 이 저장소의 `lib/views/game_view.dart` (`LayoutBuilder` ~ `Center` / `FittedBox` 구간).

---

## 1. 해결하려는 문제

| 상황 | 원하는 동작 |
|:---|:---|
| 폰 | 가로·세로 **전체**를 게임 UI가 사용 |
| 태블릿·큰 화면 | UI **비율·밀도**는 폰과 동일하게 유지 |
| 태블릿·큰 화면 | **남는 가로**는 “빈 배경” 또는 테마 색으로 채움 (UI가 좌우로 늘어나지 않음) |

즉, **논리 해상도(디자인 기준)**는 폰에 고정하고, 물리적으로 큰 화면에서는 **스케일 + 중앙 정렬**로 맞춘다.

---

## 2. 위젯 레이어(바깥 → 안)

의도대로 동작하려면 **배경**과 **콘텐츠 프레임**을 **분리**한다.

```
Scaffold (예: 바깥은 검정)
└─ SafeArea
   └─ 전면 배경 (ColoredBox / Decoration / Stack 배경 등)  ← SafeArea 전체를 채움 → 태블릿에서 좌우 “배경만” 보임
      └─ LayoutBuilder
         └─ Center
            └─ SizedBox(width: frameWidth, height: frameHeight)  ← 실제 게임/앱이 그려지는 “프레임”
               └─ (선택) FittedBox + 고정 논리 크기 + MediaQuery 덮어쓰기
                  └─ 게임 Stack / Flame 임베드 / 본문 UI
```

**핵심**: 배경 위젯은 `Center`의 **바깥**(형제가 아니라 **부모 자식 트리상 위**)에 두어, `Center`가 줄이는 폭과 무관하게 **가로 전체**를 칠한다.

---

## 3. 크기 결정 알고리즘

### 3.1 기준 상수 (프로젝트마다 조정)

이 저장소에서는 **실제 기기 측정값**을 기준으로 둔다.

- `refW`, `refH`: 논리 설계 해상도 (예: **402 × 778** — **실제 값은 `lib/views/game_view.dart` 등 구현과 반드시 일치**시킬 것. 본 저장소 웹 분기에서는 예: **390 × 750**)
- `refAspect = refW / refH`
- `tabletThreshold`: “태블릿으로 본다”는 **짧은 변** 기준 (예: **500**)

### 3.2 입력

- `maxWidth`, `maxHeight`: `LayoutBuilder`가 주는 가용 크기 (보통 `SafeArea` 안)

### 3.3 태블릿 여부

```text
shortSide = min(maxWidth, maxHeight)
needsScale = (shortSide > tabletThreshold)
```

### 3.4 프레임 크기

```text
frameHeight = maxHeight

if needsScale:
  frameWidth = maxHeight * refAspect   // 세로에 맞춰 가로를 정함 → 폰과 같은 세로비의 “슬롯”
else:
  frameWidth = maxWidth                // 폰은 가로 전체 사용
```

태블릿에서 `frameWidth`는 `maxWidth`보다 작아질 수 있으며, 그때 **`Center`로 가로 중앙**에 두면 양옆은 부모 `ColoredBox` 배경만 보인다.

---

## 4. 논리 해상도 고정: `FittedBox` + `MediaQuery`

태블릿에서 `needsScale == true`일 때만, 안쪽 콘텐츠를 다음처럼 감싼다.

1. **`SizedBox(width: refW, height: refH)`**  
   - “이 subtree는 원래 이만큼짜리 화면이다”라고 고정한다.

2. **`MediaQuery.of(context).copyWith(size: Size(refW, refH))`**  
   - 자식 위젯이 `MediaQuery.size`로 레이아웃할 때 **항상 ref 크기**를 보도록 한다.  
   - `LayoutBuilder`와 혼동되지 않게: **바깥 `LayoutBuilder`는 물리 프레임**, 안쪽 **MediaQuery는 논리 폰 화면**.

3. **`FittedBox(fit: BoxFit.contain)`**  
   - refW×refH로 그려진 결과를 **`frameWidth`×`frameHeight` 박스 안에 비율 유지하며 맞춘다**.  
   - 폰에서는 보통 `needsScale`이 꺼져 있어 이 래핑을 생략해도 된다.

**주의**: `MediaQuery`를 덮어쓸 때는 `copyWith`로 **size만** 바꾸고, `textScaler`·패딩 등 다른 필드가 필요하면 그대로 전달하는 편이 안전하다.

---

## 5. 이 저장소에서의 대응 관계

| 구성 요소 | 역할 |
|:---|:---|
| `Scaffold(backgroundColor: Colors.black)` | 노치 바깥 등 여백 색 |
| `SafeArea` | 시스템 UI 영역 회피 |
| `ColoredBox` (검정) | **전체 안전 영역 배경** (태블릿 좌우·상하 여백 색). 테마에 맞춰 색만 바꿀 수 있음 |
| `LayoutBuilder` | `maxWidth`/`maxHeight` 획득 |
| `Center` + `SizedBox(frameWidth, frameHeight)` | 게임을 **가운데 세로 슬롯**에 배치 |
| `FittedBox` + 논리 `refW×refH` + `MediaQuery` | 태블릿에서 **폰과 동일 비율·동일 논리 크기** |

- **네이티브(iOS/Android 등)**: `lib/views/game_view.dart`의 `_buildNativePhoneTabletFrame`이 위 구조를 따른다. (`shortSide > 500`이면 태블릿 프레임 + `FittedBox` 경로)
- **웹**: 같은 `_refW`/`_refH`로 스케일하되, 별 배경·둥근 `ClipRRect` 유지 (브라우저 창용).

구현이 바뀌면 이 문서의 **§3 상수**와 **`game_view.dart` 상수·주석**을 함께 맞추는 것이 좋다.

---

## 6. 다른 프로젝트로 옮길 때 체크리스트

1. **기준 해상도** `refW`/`refH`를 팀의 메인 타깃 폰(또는 Figma 프레임)에 맞출 것.
2. **`tabletThreshold`**를 기기 스펙에 맞게 조정할 것 (500은 경험적 값).
3. 배경을 **프레임 바깥 전체**에 두었는지 확인할 것 (`Center` 안에만 두면 “배경만 늘어남”이 안 된다).
4. **키보드·스플릿 뷰** 등으로 `maxHeight`가 줄어드는 경우, `frameWidth` 공식이 의도대로인지 한 번 검증할 것.
5. **Flame / `GameWidget`**: 카메라·좌표계가 논리 크기를 따르는지, `MediaQuery` 덮어쓰기 후 터치 좌표가 어긋나지 않는지 확인할 것.
6. 접근성: `FittedBox`로 전체가 작게 보이면 **텍스트 스케일** 정책과 충돌할 수 있으니 필요 시 별도 검토.

---

## 7. 한 줄 요약

**배경은 SafeArea 전체**, **UI는 `maxHeight`와 기준 세로비로 만든 `frameWidth`×`frameHeight` 박스를 `Center`에 두고**, 태블릿에서는 **`refW`×`refH` 논리 화면을 `MediaQuery`로 고정한 뒤 `FittedBox`로 그 박스에 맞춘다.**
