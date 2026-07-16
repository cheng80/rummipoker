# Rummi Poker

Rummi Poker는 숫자·색 타일을 5×5 보드에 배치해 여러 줄의 족보를 동시에 만드는 Flutter 덱빌딩 로그라이트입니다.

## 핵심 경험

- 타일을 뽑고 배치해 가로·세로·대각선 12줄에서 족보를 완성합니다.
- 확정하면 기여 타일만 제거되고 겹친 줄은 더 높은 점수 기회를 만듭니다.
- Battle 정산 뒤 Market에서 Jester, Item, Tile을 구매·판매·리롤하고 다음 Blind로 이어갑니다.
- 현재 run의 전투, Market, Blind Select 상태를 저장하고 이어하기·재시작할 수 있습니다.

## 기술 스택

- Flutter / Dart — 앱과 게임 UI
- Riverpod — session state와 provider
- GoRouter — route 전환
- easy_localization — `ko`, `en`, `ja`, `zh-CN`, `zh-TW`
- flame_audio — BGM·SFX
- shared_preferences — 로컬 설정과 storage adapter
- Firebase Analytics / Crashlytics — production 관측 경계

## Routes

| Path | Screen |
|---|---|
| `/` | Title |
| `/new-run` | New Run |
| `/blind-select` | Blind Select |
| `/game` | Battle, Settlement, Market host |
| `/setting` | Settings |
| `/trial` | Special Mode placeholder |
| `/archive` | Archive |

## 실행

```sh
flutter run
flutter run -d chrome
```

## 검증

```sh
dart run tools/generate_docs.dart --check
flutter test
flutter analyze
git diff --check
```
