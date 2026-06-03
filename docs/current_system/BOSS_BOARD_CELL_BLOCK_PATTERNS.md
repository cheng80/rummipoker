# Boss Board Cell Block Patterns

이 문서는 현재 구현된 보스전 `보드 칸 금지` modifier 패턴 기준이다.

- `1`: 타일 배치 가능
- `0`: 타일 배치 금지
- 모든 패턴은 금지칸 `0`을 5칸 이하로 유지한다.
- 금지칸은 전투 보드에서 빨간 굵은 `X`로 표시한다.
- 손패 타일 배치와 보드 이동 목적지 모두 금지칸을 거부한다.
- 점수 약화 modifier와 달리 점수 계산 multiplier에는 영향이 없다.
- 대표 debug fixture: `/game?fixture=boss_board_cell_block_preview&debug_suppress_fixture_notice=1`
- 오른쪽 열 금지 fixture: `/game?fixture=boss_board_cell_block_right_column_preview&debug_suppress_fixture_notice=1`
- 주대각선 금지 fixture: `/game?fixture=boss_board_cell_block_main_diagonal_preview&debug_suppress_fixture_notice=1`

## Difficulty Groups

표준/완화 모드는 S3부터 보드 금지를 열고, S6부터 대각선 금지를 연다.
10~14번은 표준/완화 모드에서는 출현 보류한다. 도전 모드는 S1부터 보드 금지를 열고 S7~S8에 10~14번도 출현시킨다.

| No. | 구현 ID | 표시명 | 금지칸 수 | 표준/완화 출현 | 도전 출현 |
|---:|---|---|---:|---|---|
| 1 | `board_block_right_column_v1` | 오른쪽 열 금지 | 5 | S3~S5 | S1 |
| 2 | `board_block_top_row_v1` | 위쪽 행 금지 | 5 | S3~S5 | S1 |
| 3 | `board_block_left_column_v1` | 왼쪽 열 금지 | 5 | S3~S5 | S2 |
| 4 | `board_block_bottom_row_v1` | 아래쪽 행 금지 | 5 | S3~S5 | S3 |
| 5 | `board_block_four_corners_v1` | 네 모서리 금지 | 4 | S3~S5 | S4 |
| 6 | `board_block_center_column_v1` | 가운데 열 금지 | 5 | S3~S5 | S4 |
| 7 | `board_block_center_row_v1` | 가운데 행 금지 | 5 | S3~S5 | S5 |
| 8 | `board_block_main_diagonal_v1` | 주대각선 금지 | 5 | S6+ | S6 |
| 9 | `board_block_anti_diagonal_v1` | 역대각선 금지 | 5 | S6+ | S6 |
| 10 | `board_block_center_cross_v1` | 중앙 십자 금지 | 5 | 보류 | S7 |
| 11 | `board_block_corners_center_v1` | 모서리와 중심 금지 | 5 | 보류 | S7 |
| 12 | `board_block_inner_x_v1` | 내부 X 금지 | 5 | 보류 | S8 |
| 13 | `board_block_checker_a_v1` | 체커 A 금지 | 5 | 보류 | S8 |
| 14 | `board_block_checker_b_v1` | 체커 B 금지 | 4 | 보류 | S8 |

## Pattern Masks

### 1. 오른쪽 열 금지

```text
11110
11110
11110
11110
11110
```

### 2. 위쪽 행 금지

```text
00000
11111
11111
11111
11111
```

### 3. 왼쪽 열 금지

```text
01111
01111
01111
01111
01111
```

### 4. 아래쪽 행 금지

```text
11111
11111
11111
11111
00000
```

### 5. 네 모서리 금지

```text
01110
11111
11111
11111
01110
```

### 6. 가운데 열 금지

```text
11011
11011
11011
11011
11011
```

### 7. 가운데 행 금지

```text
11111
11111
00000
11111
11111
```

### 8. 주대각선 금지

```text
01111
10111
11011
11101
11110
```

### 9. 역대각선 금지

```text
11110
11101
11011
10111
01111
```

### 10. 중앙 십자 금지

```text
11111
11011
10001
11011
11111
```

### 11. 모서리와 중심 금지

```text
01110
11111
11011
11111
01110
```

### 12. 내부 X 금지

```text
11111
10101
11011
10101
11111
```

### 13. 체커 A 금지

```text
01110
11111
10101
11111
11011
```

`체커 A`는 5칸 제한을 지키는 현재 구현 패턴이다. 과거 제안 중 아래 마스크는 `0`이 7칸이므로 사용하지 않는다.

```text
01110
11111
01010
11111
01110
```

### 14. 체커 B 금지

```text
11111
10101
11111
10101
11111
```

## Runtime Touchpoints

- Modifier data: `lib/logic/rummi_poker_grid/boss_modifier.dart`
- Station pool: `lib/services/blind_selection_spec.dart`
- Placement and board move guard: `lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart`
- Board marker UI: `lib/views/game/widgets/game_shared_board_widgets.dart`
- Debug fixture: `lib/services/debug_run_fixture_builders.dart`

## Verification

Current guard tests:

- `flutter test test/logic/rummi_session_test.dart`
- `flutter test test/services/blind_selection_setup_test.dart`
- `flutter test test/views/game/widgets/game_board_motion_widgets_test.dart`
- `flutter test test/services/debug_run_fixture_service_test.dart`
