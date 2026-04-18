# 제스터 카드 수치표 (`jesters_common_phase5.json`)

데이터 원본: `data/common/jesters_common_phase5.json`  
점수 합성식·특수 처리: `lib/logic/rummi_poker_grid/jester_meta.dart`

**표기**

- **`value` / `xValue`**: JSON 필드. `—`는 `null`.
- **칩 / 멀트**: 최종 줄 점수는 `game_logic_constants.md` §3 합성식 적용(멀트 보너스는 20당 배율 +1).
- **`tile_color_scored`**: `RummiJesterCard.fromJson`이 색 목록을 다음 순으로 합성한다 — (1) `mappedTileColors` (2) `originalSuitRefs` 포커 슈트명 → 타일 컬러 (3) `conditionValue` 문자열·배열. 허용 슈트: `diamonds`→옐로, `hearts`→레드, `spades`→블루, `clubs`→블랙.
- **`rank_scored` 등 랭크**: (1) `mappedTileNumbers` 정수·`"face_card"` 등 토큰 (2) `originalRankRefs` 문자열 (`ace`, `10`, `jack` …) (3) 비었을 때만 `conditionValue`의 숫자 배열.
- **빈 배열 필드**: 사용하지 않는 `mappedTileColors: []` / `mappedTileNumbers: []` 는 JSON에서 생략할 수 있다.

---

## 1. 범례 (`effectType`)

| effectType | 의미 |
|------------|------|
| `chips_bonus` | `value` 기반 칩 보너스(조건에 따라 장수·배수) |
| `mult_bonus` | `value` 기반 멀트 보너스(가산) |
| `xmult_bonus` | `xValue` 기반 배율 곱 |
| `stateful_growth` | 슬롯 상태·런 카운터와 연동(코드에서 별도 규칙) |
| `economy` | 전투 점수가 아닌 **골드**(스테이지 종료 정산) |
| `other` | Scholar 전용 분기 등 특수 처리 |

---

## 2. 카드별 수치·간단 설명

| id | baseCost | effectType | value | xValue | 조건·참조 | 간단 설명 |
|----|----------|------------|-------|--------|-----------|-----------|
| `jester` | 2 | mult_bonus | 4 | — | `none` | 조건 없이 고정 멀트 보너스(패시브). |
| `greedy_jester` | 5 | mult_bonus | 3 | — | `tile_color_scored`, `conditionValue` **`yellow`** | 스코어 타일 중 옐로 **장당** +3 멀트. |
| `lusty_jester` | 5 | mult_bonus | 3 | — | `tile_color_scored`, **`red`** | 레드 장당 +3 멀트. |
| `wrathful_jester` | 5 | mult_bonus | 3 | — | `tile_color_scored`, **`blue`** | 블루 장당 +3 멀트. |
| `gluttonous_jester` | 5 | mult_bonus | 3 | — | `tile_color_scored`, **`black`** | 블랙 장당 +3 멀트. |
| `jolly_jester` | 3 | mult_bonus | 8 | — | `pair` | 줄 족보가 페어 계열이면 +8 멀트. |
| `zany_jester` | 4 | mult_bonus | 12 | — | `three_of_a_kind` | 트리플/풀하우스 등 “3장 동랭” 포함 시 +12 멀트. |
| `mad_jester` | 4 | mult_bonus | 10 | — | `two_pair` | 투페어·풀하우스 등이면 +10 멀트. |
| `crazy_jester` | 4 | mult_bonus | 12 | — | `straight` | 스트레이트/스트플이면 +12 멀트. |
| `droll_jester` | 4 | mult_bonus | 10 | — | `flush` | 플러시/스트플이면 +10 멀트. |
| `sly_jester` | 3 | chips_bonus | 50 | — | `pair` | 페어 계열이면 +50 칩. |
| `wily_jester` | 4 | chips_bonus | 100 | — | `three_of_a_kind` | 트리플 계열이면 +100 칩. |
| `clever_jester` | 4 | chips_bonus | 80 | — | `two_pair` | 투페어 계열이면 +80 칩. |
| `devious_jester` | 4 | chips_bonus | 100 | — | `straight` | 스트레이트 계열이면 +100 칩. |
| `crafty_jester` | 4 | chips_bonus | 80 | — | `flush` | 플러시 계열이면 +80 칩. |
| `half_jester` | 5 | mult_bonus | 20 | — | `played_hand_size_lte_3` | 스코어링 타일 수 ≤3이면 +20 멀트. |
| `jester_stencil` | 8 | xmult_bonus | — | 1.0 | `empty_jester_slots` | 빈 제스터 슬롯 수만큼 `xValue`를 **거듭제곱**해 곱함. |
| `abstract_jester` | 4 | mult_bonus | 3 | — | `owned_jester_count` | 보유 제스터 수×3 멀트(자기 자신 포함). |
| `green_jester` | 4 | stateful_growth | 1 | — | 슬롯 상태 | 확정마다 +1, 디스카드마다 −1 멀트(상태값이 멀트에 반영). |
| `blue_jester` | 5 | chips_bonus | 2 | — | `cards_remaining_in_deck` | 덱 잔량×2 칩. |
| `scary_face` | 4 | chips_bonus | 30 | — | 페이스 11–13 | 스코어 페이스 카드 **장당** +30 칩. |
| `smiley_face` | 4 | mult_bonus | 5 | — | 페이스 11–13 | 스코어 페이스 카드 **장당** +5 멀트. |
| `egg` | 4 | economy | 3 | — | `onRoundEnd` | 라운드 종료 골드 +3(전투 점수 아님). |
| `bonus_jester` | 3 | chips_bonus | 10 | — | `none` | 고정 +10 칩. |
| `popcorn` | 5 | stateful_growth | 20 | — | 멀트 감쇠 | 초기 상태 20 멀트; 스테이지 종료마다 **−4**(코드). |
| `ice_cream` | 5 | stateful_growth | 100 | — | 칩 감쇠 | 초기 100 칩 보너스; 줄 확정마다 **−5**(코드). |
| `delayed_gratification` | 4 | economy | 2 | — | 미사용 디스카드 | 종료 시 남은 보드+손 버림 횟수×2 골드. |
| `walkie_talkie` | 4 | mult_bonus | 4 | — | 랭크 10, 4 | 해당 랭크 스코어 **장당** +4 멀트. |
| `golden_jester` | 6 | economy | 4 | — | `onRoundEnd` | 블라인드 종료마다 골드 +4. |
| `mystic_summit` | 5 | mult_bonus | 15 | — | `zero_discards_remaining` | 남은 보드 버림 0일 때 +15 멀트. |
| `even_steven` | 4 | mult_bonus | 4 | — | 짝수 랭크 2,4,6,8,10 | 해당 랭크 스코어 장당 +4 멀트. |
| `odd_todd` | 4 | chips_bonus | 31 | — | 홀수 1,3,5,7,9 | 해당 랭크 스코어 장당 +31 칩. |
| `scholar` | 4 | other | 20 | — | 에이스(랭크 1) | **코드 고정**: 에이스당 칩 `value`, 멀트 **+4**/장. |
| `fibonacci` | 8 | mult_bonus | 8 | — | 1,2,3,5,8 | 해당 랭크 스코어 장당 +8 멀트. |
| `banner` | 5 | chips_bonus | 30 | — | `remaining_discards` | 남은 보드 버림 **횟수×30** 칩. |
| `gros_michel` | 5 | mult_bonus | 15 | — | `none` | 무조건 +15 멀트. |
| `supernova` | 5 | stateful_growth | — | — | 족보별 플레이 횟수 | JSON에 고정값 없음; **이번 런 해당 족보 확정 횟수**만큼 멀트. |
| `ride_the_bus` | 6 | stateful_growth | 1 | — | 페이스 없이 연속 | 페이스 미포함 확정마다 상태+1 멀트; 페이스 스코어 시 0으로 리셋(코드). |

---

## 3. 구현·데이터 불일치 시 참고

| 항목 | 내용 |
|------|------|
| `tile_color_scored` | 위 우선순위로 `mappedTileColors`를 채운다. `conditionValue`는 타일 컬러명 또는 슈트명 문자열을 받을 수 있다. |
| Scholar | `effectType`이 `other`이며 멀트 **+4**는 JSON이 아니라 `jester_meta.dart`에 하드코딩. |
| Supernova | `value`/`xValue`가 null — 런타임 `currentHandPlayedCount` 사용. |
| Popcorn / Ice Cream | 시작값은 `value`; 감소량(4, 5)은 코드 `RummiRunProgress`에 고정. |
| Mystic Summit | “디스카드”는 세션의 **보드 버림 잔량** 기준(`discardsRemaining`). |
| Jester Stencil | 빈 슬롯 = `maxJesterSlots - ownedJesterCount`; 곱은 `pow(xValue, empty)`. |

---

## 4. 상점·런 지원 범위 (코드 플래그 요약)

`RummiJesterCard`에서 일부만 `isSupportedInCurrent*`로 노출·처리된다. 전체 목록과 효과 구현 여부는 `jester_meta.dart` 및 `rummi_poker_grid_game_logic.md` §4.3을 본다.
