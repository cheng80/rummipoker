# Rummi Poker

Rummi Poker는 숫자·색 타일을 5×5 보드에 배치해 여러 줄의 족보를 동시에 만드는 덱빌딩 로그라이트입니다. 패키지와 런타임 내부 이름은 `Rummi Poker Grid`입니다.

## 핵심 경험

- 타일을 뽑고 배치해 가로·세로·대각선 12줄에서 족보를 완성합니다.
- 확정하면 기여 타일만 제거되고 겹친 줄은 더 높은 점수 기회를 만듭니다.
- Battle 정산 뒤 Market에서 Jester, Item, Tile을 구매·판매·리롤하고 다음 Blind로 이어갑니다.
- New Run에서 표준 또는 도전 난이도를 고릅니다.
- 한 run은 8번째 Station(S8) 이후에도 계속 진행할 수 있고, Archive에서 수집 내용을 확인할 수 있습니다.
- 현재 run의 주요 상태를 저장하고 이어하기·재시작할 수 있습니다. 첫 저장 시점, Market을 나갈 때, 보상이 다시 적용될 가능성 등 알려진 제한은 [SAVE_DATA](docs/core/SAVE_DATA.md)에 정리되어 있습니다.

## 문서 시작점

- 새로 읽기: [START_HERE](START_HERE.md)
- 게임 규칙: [GAME_RULES](docs/core/GAME_RULES.md)
- 경제와 Market: [RUN_ECONOMY](docs/core/RUN_ECONOMY.md)
- 콘텐츠 목록: [CONTENT_CATALOG](docs/generated/CONTENT_CATALOG.md)
- 현재 작업: [ACTIVE_EXECUTION_PLAN](docs/planning/ACTIVE_EXECUTION_PLAN.md)
- 역기획·재미 후보·광고 BM: [REVERSE_DESIGN_SYNTHESIS](docs/planning/REVERSE_DESIGN_SYNTHESIS.md)

## 기술 스택

- Flutter / Dart / Flame — 앱과 게임 실행 기반
- Riverpod — 게임 상태 관리
- GoRouter — 화면 이동
- easy_localization — `ko`, `en`, `ja`, `zh-CN`, `zh-TW`
- flame_audio — BGM·SFX
- shared_preferences — 기기 내 설정·저장
- Firebase Analytics / Crashlytics — 분석·충돌 기록

## 화면 경로

| 경로 | 화면 |
|---|---|
| `/` | Title 화면 |
| `/new-run` | New Run 화면 |
| `/blind-select` | Blind Select |
| `/game` | Battle·정산·Market |
| `/setting` | 설정 |
| `/trial` | 특별 모드 자리표시자 |
| `/archive` | Archive |

## 실행

```sh
flutter run
flutter run -d chrome
```

## 검증

문서 변경은 아래 명령으로 확인합니다.

```sh
dart run tools/check_docs_structure.dart
dart run tools/generate_docs.dart --check
flutter test test/tools/docs_structure_test.dart test/tools/generate_docs_test.dart
flutter analyze
git diff --check
```

전체 테스트는 다음 명령으로 실행합니다.

```sh
flutter test
```

테스트 결과는 실행 시점의 로그를 기준으로 판단하고, 실패와 skip 항목을 함께 확인합니다.
