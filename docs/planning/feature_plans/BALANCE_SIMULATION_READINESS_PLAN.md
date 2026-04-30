# Balance Simulation Readiness Plan

> GCSE role: `Execution`
> Role: `/plan-eng-review` 입력용 실행 범위 정리.

이 문서는 `docs/specs/V4/14_BALANCE_AUTOMATION_ML.md`를 바로 구현 지시로 쓰기 전에, 첫 simulator skeleton의 범위를 작게 고정하기 위한 계획이다.

## 0. Source Basis

이 계획은 아래 문서 기준을 따른다.

- `START_HERE.md`: 현재 playable prototype과 iOS simulator smoke를 기준 검증 흐름으로 유지한다.
- `docs/planning/STATUS.md`: 다음 구현 초점은 `balance simulation readiness`다.
- `docs/planning/MIGRATION_ROADMAP.md`: V4는 current prototype을 교체하지 않고 흡수/확장한다.
- `docs/planning/OPEN_DECISIONS.md`: Balance Automation은 Flutter UI 자동 클릭이 아니라 Dart game logic simulator + bot policy + JSONL 로그 구조다.
- `docs/specs/V4/14_BALANCE_AUTOMATION_ML.md`: `RummiPokerGridSession`, `HandEvaluator`, Jester effect, Item effect를 CLI/test harness에서 반복 실행하는 방향이다.
- `/office-hours` design doc: 첫 deliverable은 local Dart CLI 개발 도구이며, raw log는 git에 넣지 않는다.

따라서 이 pass의 성격은 새 게임 구조 설계가 아니라, 현재 런타임이 UI 없이 반복 호출될 수 있는지 확인하는 준비 작업이다.

## 1. Goal

현재 구현된 `Jester/Item 빌드 -> Boss modifier 제약 -> scoring feedback` 루프를 UI 없이 반복 실행할 수 있는 최소 준비를 한다.

첫 목표는 ML 모델이나 자동 밸런스 패치가 아니다. 목표는 seed 기반 전투 1개를 실행하고, 결과를 JSONL 한 줄로 남길 수 있는 skeleton을 만드는 것이다.

이 작업은 기존 playable runtime을 대체하지 않는다. iPhone simulator smoke로 검증해 온 앱 흐름은 유지하고, ML 레벨링을 위해 같은 runtime을 CLI에서 얇게 호출하는 분석 도구를 추가한다.

## 2. Non-goals

- Flutter UI 자동 클릭
- PyTorch 학습 코드
- 밸런스 수치 자동 수정
- Market 구매 정책까지 포함한 full run simulator
- Station Map graph 구현
- Archive / collection discovered id 저장
- raw simulation log commit
- 기존 battle / market / save 구조 재작성
- 기존 playable loop를 simulator 중심으로 재구성

## 3. Current Preconditions

- Station Preview v1 scope는 결정됐다.
- Market offer count / rarity roll planning은 완료됐다.
- `v4_pacing_baseline_1` 기준 target/reward/pressure는 문서화됐다.
- Boss modifier taxonomy와 constraint visual language는 정리됐다.
- Boss modifier v1 `빨간 타일 약화`는 preview, entry popup, battle marker, scoring callout, save/restore까지 연결됐다.
- Item runtime v1은 49개 적용 완료 / pendingHook 0개다.
- scoring feedback P0는 1차 구현 및 required iOS smoke가 끝났다.

## 4. First Skeleton Scope

### Runtime reuse boundary

첫 simulator는 기존 playable runtime 위에 얇게 얹는다.

권장 원칙:

- `RummiPokerGridSession`, `BlindSelectionSetup`, `RummiRunProgress`를 재사용한다.
- battle / market / save 구조를 simulator 때문에 바꾸지 않는다.
- catalog parser는 기존 `fromJsonString`을 우선 재사용한다.
- CLI import가 실제로 실패할 때만 catalog loader 분리를 별도 선행 작업으로 검토한다.
- parser / loader 분리는 첫 skeleton의 기본 전제 작업이 아니라 조건부 리스크다.

데이터 흐름:

```text
CLI args
  -> catalog JSON read
  -> existing fromJsonString parser
  -> BlindSelectionSetup selected spec
  -> RummiRunProgress start loadout
  -> RummiPokerGridSession battle loop
  -> greedy_v1 decision
  -> battle result snapshot
  -> JSONL writer
```

### CLI

후보 명령:

```bash
dart run tools/sim/run_balance_sim.dart --runs 10 --bot greedy_v1 --seed 42 --jester jolly_jester --item slide_wax --out logs/sim_balance.jsonl
```

첫 skeleton은 Market 구매를 제외하므로, 검증할 시작 빌드는 CLI 인자로 직접 주입한다.

- `--jester <id>`: 시작 owned Jester id. 여러 번 전달 가능.
- `--item <id>`: 시작 owned Item id. 여러 번 전달 가능.
- 첫 구현은 scenario JSON을 만들지 않는다. 조합 batch 파일은 후속 pass로 둔다.

### Dataset unit

첫 row는 `battle start -> battle result` 단위다.

Market 구매, reroll, reward 선택, 다음 station 경로 선택은 첫 skeleton에서 제외한다.
시작 loadout은 `--jester`, `--item` 인자로 주입한다.

### Bot policy

첫 bot은 `greedy_v1` 하나만 둔다.

권장 최소 기준:

- 가능한 보드 배치 후보를 만든다.
- 배치 후 즉시 확정 가능한 점수가 가장 높은 후보를 고른다.
- 동일 점수면 deterministic tie-breaker를 사용한다.
- 보드 버림, 손패 버림, 보드 이동은 첫 skeleton에서는 최소 규칙만 둔다.

`random_bot`은 crash 탐지용으로 유용하지만, 첫 `/plan-eng-review` 범위에서는 선택 사항으로 둔다.

Sequential implementation, no parallelization opportunity.

첫 skeleton은 `tools/sim`과 기존 runtime import 경계를 같이 만지므로, worktree를 나누기보다 순차 구현이 안전하다.

## 5. Log Contract v1

필수 top-level field:

```text
schema_version
sim_id
run_id
seed
bot_policy
app_version
balance_version
ruleset_id
catalog_versions
run_archetype_id
tile_deck_composition_id
tile_modifier_pool_id
is_debug_run
is_fixture
station
blind_tier
target_score
start_state
result
```

`start_state` 최소 field:

```text
gold
hands_remaining
board_discards
hand_discards
board_moves
jester_ids
item_ids
deck_size
```

`result` 최소 field:

```text
cleared
final_score
score_ratio
turn_count
```

## 6. Implementation Boundaries for /plan-eng-review

### Preferred files to inspect

- `lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart`
- `lib/logic/rummi_poker_grid/jester_meta.dart`
- `lib/logic/rummi_poker_grid/item_definition.dart`
- `lib/logic/rummi_poker_grid/item_effect_runtime.dart`
- `lib/services/blind_selection_setup.dart`
- `lib/services/active_run_save_service.dart`
- `docs/specs/V4/14_BALANCE_AUTOMATION_ML.md`

### Candidate files to create

- `tools/sim/run_balance_sim.dart`
- `tools/sim/bot_policy.dart`
- `tools/sim/greedy_bot.dart`

조건부 후보:

- `lib/logic/rummi_poker_grid/jester_catalog_loader.dart`
- `lib/logic/rummi_poker_grid/item_catalog_loader.dart`

위 loader 분리는 `dart run tools/sim/run_balance_sim.dart`에서 기존 catalog parser import가 실제로 막힐 때만 진행한다.

### Candidate tests

- `test/tools/sim/balance_sim_test.dart`

필수 테스트 요구:

- CLI args:
  - `--runs`, `--bot`, `--seed`, `--out`을 파싱한다.
  - `--jester`, `--item`을 여러 번 받을 수 있다.
  - unknown bot은 실패한다.
  - `--out` 누락은 실패한다.
- Catalog boundary:
  - CLI에서 기존 `RummiJesterCatalog.fromJsonString`, `ItemCatalog.fromJsonString`을 import할 수 있는지 먼저 검증한다.
  - import가 실패하면 loader 분리를 별도 선행 작업으로 처리한다.
  - loader를 분리하게 되면 새 asset loader는 기존 `fromJsonString` parser에 위임한다.
- Battle runner:
  - selected blind spec을 `BlindSelectionSetup` 기준으로 만든다.
  - 시작 Jester/Item loadout이 run state에 반영된다.
  - `greedy_v1`은 같은 seed에서 같은 결과를 낸다.
  - clear 시 종료한다.
  - expiry 또는 legal action 없음 상태에서 종료한다.
- JSONL writer:
  - run마다 한 줄을 쓴다.
  - top-level required field가 모두 있다.
  - `start_state` required field가 모두 있다.
  - `result` required field가 모두 있다.

테스트 커버리지 다이어그램:

```text
CODE PATHS                                           USER / DEV FLOWS
[+] tools/sim/run_balance_sim.dart                  [+] Local balance smoke
  ├── [GAP] args parse success                        ├── [GAP] runs 10 rows to logs/sim_balance.jsonl
  ├── [GAP] missing --out failure                     ├── [GAP] unknown bot exits with clear error
  ├── [GAP] unknown bot failure                       └── [GAP] repeated --jester/--item reflected in start_state
  └── [GAP] repeated loadout args

[+] catalog import boundary
  ├── [GAP] existing Jester fromJsonString usable
  └── [GAP] existing Item fromJsonString usable

[+] battle runner
  ├── [GAP] selected blind spec from BlindSelectionSetup
  ├── [GAP] same seed + same bot gives same result
  ├── [GAP] clear terminates
  └── [GAP] expiry / no legal action terminates

[+] JSONL writer
  ├── [GAP] required top-level fields
  ├── [GAP] required start_state fields
  └── [GAP] required result fields

COVERAGE TARGET: all new skeleton paths covered before implementation is considered complete.
```

### Avoid

- `lib/views/**`
- app route changes
- save schema changes
- economy number changes
- `RummiBlindState` rename
- current Jester id changes
- duplicate catalog parsers inside `tools/sim`
- existing playable loop rewrites

### What already exists

- `RummiPokerGridSession`: 전투 상태와 scoring 실행의 중심. 재사용한다.
- `BlindSelectionSetup`: station/blind별 목표 점수와 보상 spec 생성. 재사용한다.
- `RummiRunProgress`: owned Jester/Item, station, gold 등 run state. 재사용한다.
- `RummiJesterCatalog.fromJsonString`: Jester catalog parser. 재사용한다.
- `ItemCatalog.fromJsonString`: Item catalog parser. 재사용한다.
- iOS simulator smoke flow: playable 앱 검증 기준으로 유지한다.

## 7. Technical Notes

- CLI에서는 Flutter `rootBundle`을 기대하지 않는다.
- catalog는 `File(...).readAsStringSync()`로 읽고 `RummiJesterCatalog.fromJsonString`, `ItemCatalog.fromJsonString`에 전달한다.
- catalog parsing은 중복 구현하지 않는다.
- catalog model의 Flutter import가 CLI 실행을 막는 경우에만 loader 분리를 진행한다.
- simulation output은 앱 active run save와 분리한다.
- `logs/`는 raw output 위치로만 쓰고 git commit 대상에서 제외한다.
- 같은 seed, 같은 bot, 같은 balance version은 같은 결과를 내야 한다.

## 8. Failure Modes

| Failure | Impact | Required handling |
|---|---|---|
| CLI에서 catalog parser import 실패 | simulator가 중복 parser를 만들 위험 | 먼저 import spike로 확인하고, 실패 시 loader 분리를 별도 선행 작업으로 처리 |
| seed가 실제 battle randomness에 끝까지 전달되지 않음 | 같은 조건에서 결과가 흔들려 로그 신뢰도 하락 | determinism test 필수 |
| greedy bot이 legal action 없음 상태를 처리하지 못함 | 무한 루프 또는 빈 로그 | turn cap과 no-action termination 필요 |
| JSONL field 누락 | 후속 report/ML 입력이 깨짐 | required field test 필수 |
| debug fixture와 sim log 혼합 | 모델이 fixture 데이터를 실제 결과로 학습 | `is_debug_run=false`, `is_fixture=false` 명시 |
| simulator 구현을 위해 save/runtime 구조 변경 | playable loop 회귀 위험 | save schema, route, battle/market 구조 변경 금지 |

## 9. Open Decisions

1. `greedy_v1`이 보드 버림과 보드 이동까지 고려할 것인가?
   - 권장: 첫 skeleton은 배치와 확정 중심으로 시작하고, 버림/이동은 후속 pass에서 강화한다.
2. catalog loader 분리가 첫 PR에 필요한가?
   - 권장: 먼저 CLI import spike로 확인한다. 실패할 때만 loader 분리를 별도 선행 작업으로 진행한다.
3. 시작 loadout을 scenario JSON으로 받을 것인가?
   - 결정: 첫 skeleton은 `--jester`, `--item` 인자만 사용한다. scenario JSON은 후속 pass로 둔다.
4. `random_bot`을 첫 PR에 같이 넣을 것인가?
   - 권장: skeleton 검증이 작게 끝나면 후속으로 추가한다.
5. `logs/`를 `.gitignore`에 추가할 것인가?
   - 권장: 첫 simulator 구현 PR에서 함께 처리한다.
6. `balance_version` 값은 어디서 읽을 것인가?
   - 권장: 첫 skeleton은 문자열 상수 `v4_pacing_baseline_1`로 시작하고, 후속에 config화한다.

## 10. Acceptance Criteria

- `/plan-eng-review`가 첫 simulator skeleton의 구현 범위를 이 문서만 보고 판단할 수 있다.
- 첫 구현은 Flutter UI 없이 전투 1개 이상의 결과를 JSONL로 쓸 수 있어야 한다.
- 기존 playable runtime 구조를 재작성하지 않는다.
- CLI에서 기존 catalog parser import 가능 여부를 먼저 확인한다.
- seed determinism을 테스트한다.
- CLI args, repeated loadout args, JSONL required field, clear/expiry termination을 테스트한다.
- simulator 로그는 `is_debug_run=false`, `is_fixture=false`를 명시한다.
- 첫 구현은 PyTorch, report generation, auto balance candidate export를 포함하지 않는다.

## 11. NOT in scope

- Market 구매 policy: 첫 skeleton은 시작 loadout을 CLI 인자로 받는다.
- Full run simulation: 첫 단위는 battle start -> battle result다.
- PyTorch training/evaluation: JSONL 생성 이후 후속 pass다.
- Balance candidate export: 사람이 검토할 리포트 이후 검토한다.
- Station Map graph: 현재 `BlindSelectView`/Station Preview v1 기준을 사용한다.
- Save schema migration: simulator output은 active run save와 분리한다.
- Flutter UI automation: iOS smoke는 앱 검증용이고 simulator 데이터 생성 수단이 아니다.
- Runtime rewrite: 기존 playable loop를 유지한다.

## 12. /plan-eng-review Result

Status: scope accepted with guardrails.

Architecture review:

- Issue: simulator가 기존 runtime 위에 얇게 얹히지 않으면 playable loop 회귀 위험이 크다.
- Decision: `tools/sim` 중심으로 시작하고, `lib` 구조 변경은 CLI import 실패가 확인될 때만 한다.

Code quality review:

- Issue: catalog parser를 tools 안에 다시 만들면 Jester/Item 정의가 drift된다.
- Decision: 기존 `fromJsonString` parser 재사용을 acceptance criteria로 둔다.

Test review:

- Issue: determinism, CLI args, required JSONL field, termination path가 빠지면 로그가 ML 입력으로 쓸 수 없다.
- Decision: `test/tools/sim/balance_sim_test.dart`에 skeleton path를 모두 먼저 고정한다.

Performance review:

- Issue: 첫 pass에서 50,000회 simulation을 목표로 잡으면 병목과 구조 변경 압박이 커진다.
- Decision: 첫 구현은 `--runs 10` smoke와 deterministic result에 집중하고, 1,000회 이상은 후속 performance pass에서 본다.

Unresolved decisions:

- `greedy_v1`이 보드 버림/보드 이동까지 고려할지는 후속 강화로 둔다.
- catalog loader 분리는 CLI import spike 결과에 따라 별도 작업으로 결정한다.
- `logs/` gitignore 반영은 simulator 구현 PR에서 처리한다.

## 13. Handoff

다음 단계는 구현 전 CLI import spike다.

구현 진입 질문:

- 현재 runtime을 CLI에서 재사용할 때 Flutter 의존성이 남아 있는가?
- 기존 catalog parser를 `tools/sim`에서 바로 import할 수 있는가?
- import가 가능하면 `tools/sim` skeleton만으로 시작할 수 있는가?
- import가 막히면 loader 분리를 별도 작은 선행 작업으로 뺄 것인가?
