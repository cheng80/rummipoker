# Rummi Poker Grid — 실행 체크리스트

> 순서대로 진행. 항목을 끝낼 때마다 `[ ]` → `[x]`로 갱신한다.  
> 기획·규칙: `rummi_poker_grid_gdd.md` / 구현 스펙: `rummi_poker_grid_game_logic.md` / 구조: `rummi_poker_grid_migration_plan.md`

---

## 0. 기획 고정 (GDD·게임 로직 문서)

- [ ] **평가 라인**: 행 5 + 열 5 = 10줄 확정 여부 (`game_logic` §3과 동일하게)
- [ ] **Straight / Flush**: 색·A 끝내기(휠) 규칙 확정 (`game_logic` §4.1)
- [ ] **죽은 줄** vs **방치 패널티**(GDD §4.4 vs §6.3): 동시 적용인지, 하나로 통합인지
- [ ] **빈 칸이 있는 줄**의 핸드 처리 규칙
- [ ] **조커**: 보드 타일인지 메타 장착인지 (`game_logic` §6 반영)

---

## 1. 순수 로직 (`lib/logic/rummi_poker_grid/`)

- [ ] 모델: `Tile` / `TileColor`, 보드 5×5, 웨이스트(최대 3), 덱, 턴 상태
- [ ] `HandEvaluator`: 5장 → 족보·점수 (단위 테스트)
- [ ] 엔진 퍼사드: 드로우, 배치, 버림+보충, 라인 제거, 점수 합산 (테스트 우선)
- [ ] GDD 버림 횟수·턴 흐름과 엔진 이벤트 대응표 정리

---

## 2. Riverpod

- [ ] 세션·점수 요약 등 UI 스냅샷을 `Notifier`에 연결 (기존 `rummi_session` 확장 또는 신규)
- [ ] Flame ↔ `ref.read` 주입 패턴 확정 (`docs/riverpod_architecture.md` 참고)

---

## 3. Flame (`lib/game/rummi_poker_grid/`)

- [ ] `FlameGame` 스켈레톤 + 빈 5×5 슬롯(또는 격자)
- [ ] 타일 컴포넌트(렌더 + 탭)
- [ ] 라인 하이라이트·GDD §5.1 상태색(초록/중립/빨강)
- [ ] 웨이스트 슬롯 UI
- [ ] 터치·좌표: 태블릿 `FittedBox`+`MediaQuery` 경로에서 실기기 확인 (`docs/responsive-phone-frame-layout.md`)

---

## 4. Flutter 셸

- [ ] `GameView` 분리 또는 `GameWidget`을 새 `FlameGame`으로 교체
- [ ] `TitleView` / 라우트: 진입·모드 문구를 새 게임에 맞게
- [ ] 오버레이: 일시정지·클리어·설정 등 기존 패턴 재사용 여부 결정

---

## 5. 레거시 정리

- [ ] `BingoCardGame` 등을 `legacy_taptap/`로 이동하거나 제거 (라우트 단일화 시)
- [ ] `app_config`·번역·앱 표시 이름 갱신

---

## 6. 출시 전

- [ ] `docs/STORE_METADATA_PLAY_APPSTORE_2026.md` 패키지명·스크린샷·설명
- [ ] 웹 빌드 `base-href` 확인 (`docs/web_build.md`)

---

## 현재 진행 메모

_(작업하면서 날짜·이슈를 아래에 짧게 적어도 됨.)_
