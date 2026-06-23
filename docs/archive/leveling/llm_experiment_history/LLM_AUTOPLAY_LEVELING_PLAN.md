# LLM Autoplay Leveling Plan

> Status: Draft / post-fresh-data side track
> Source notes: `/Users/cheng80/Desktop/rummipoker_llm_autoplay_leveling_strategy.md`, `/Users/cheng80/Desktop/rummipoker_codex_llm_bot_instruction.md`

## 결론

LLM autoplay는 RummiPoker의 대량 밸런스 기준으로 쓰지 않는다.

적용 목적은 아래로 제한한다.

- 사람처럼 느리게 판단하는 전략 샘플러
- heuristic bot이 놓치는 행동 후보 발견
- 사람이 할 법한 실수/오해 패턴 수집
- 향후 imitation learning용 decision label 수집
- fresh 레벨링 리포트 해석 보조

대량 clear rate, score ratio, economy gate, market value 판단은 계속 Dart simulator의 `planner_v3`, `full_run_policy_v1`, fresh ML pipeline을 기준으로 한다.

## 현재 구조와 맞는 적용 방식

현재 `BalanceSimBotPolicy.chooseAction`은 sync 경계다.
LLM 호출은 latency, timeout, async I/O가 있으므로 기존 bot interface를 바로 async로 바꾸지 않는다.

1차 적용은 아래 둘 중 하나로 제한한다.

1. Decision cache 방식
   - Dart가 state + legal action request JSONL을 export한다.
   - Python local LLM runner가 request를 읽고 decision JSONL을 만든다.
   - Dart runner는 decision cache를 읽어 선택 action id를 검증하고 실행한다.
2. 별도 LLM simulation runner
   - 기존 `run_balance_sim.dart`를 깨지 않고 `tools/sim/run_llm_balance_sim.dart` 또는 Python orchestrator에서 slow loop를 관리한다.

기존 `run_balance_sim.dart --bot full_run_policy_v1` 경로는 변경하지 않는다.

## 핵심 계약

LLM은 action을 직접 만들지 않는다.
Dart가 legal action list를 만들고, LLM은 `selected_action_id`만 고른다.

필수 검증:

- selected action id가 legal action list에 존재해야 한다.
- action type은 허용 목록이어야 한다.
- 좌표, hand index, resource, confirm 가능 여부는 Dart session에서 재검증한다.
- invalid면 같은 request 재시도 1회까지 허용한다.
- 재시도 실패 시 `full_run_policy_v1` fallback을 사용한다.
- invalid count, fallback count, latency, selected action, reason은 별도 decision log에 남긴다.

허용 action type:

- `draw`
- `place`
- `confirm`
- `discardHand`
- `discardBoard`
- `moveBoard`
- `stop`

## 로그 분리

LLM 로그는 기존 bot 로그와 섞지 않는다.

추천 위치:

- request/response: `logs/llm/`
- sim output: `logs/sim/llm_gemma4_v1/`
- tracked report: `analysis/leveling/reports/`

`logs/` 산출물은 기본적으로 git 추적하지 않는다.
tracked 대상은 schema 문서, runner 코드, lightweight metrics/report만 둔다.

## 1차 구현 범위

P0 scaffold:

1. `tools/sim/llm_action_schema.dart`
   - `LlmLegalAction`
   - `LlmActionRequest`
   - `LlmActionResponse`
   - `LlmActionValidationResult`
2. `tools/sim/llm_state_exporter.dart`
   - `RummiPokerGridSession`을 LLM 입력 JSON으로 export
   - board, hand, target score, remaining score, resources, jester/item summary 포함
3. Legal action generator
   - draw/place/confirm/discard/move/stop 후보 생성
   - deterministic action id 사용
4. Response validation
   - selected id 검증
   - invalid reason 분류
5. Python local runner scaffold
   - `tools/llm_agent/run_llm_policy.py`
   - Ollama adapter
   - JSON-only response parsing
6. README
   - 목적/비목표
   - local LLM server 요구사항
   - smoke command
   - invalid/fallback 해석 기준

P1 execution:

1. decision cache 기반 LLM runner 연결
2. `llm_gemma4_v1` smoke 10 runs
3. `planner_v3`, `full_run_policy_v1` 같은 seed 비교
4. invalid/fallback/latency/clear/score/turn count 리포트 생성

로컬 LLM 서버와 모델 세팅은 `docs/archive/leveling/llm_experiment_history/LLM_LOCAL_SETUP_PLAN.md`를 따른다.

P2 learning data:

1. full_run_policy_v1 decision log를 silver label로 export
2. LLM decision과 fallback 결과를 함께 저장
3. 사람 검토용 disagreement report 생성
4. SFT/LoRA는 데이터 품질 확인 뒤 별도 플랜으로 분리

## 비목표

- LLM 결과를 밸런스 정답으로 사용하지 않는다.
- LLM 결과를 자동으로 target, boss, market, economy patch에 적용하지 않는다.
- 앱 runtime 또는 모바일 기기 안에 LLM을 탑재하지 않는다.
- Flutter UI 자동 클릭 방식으로 LLM autoplay를 만들지 않는다.
- 현재 sync bot policy를 무리하게 async 구조로 바꾸지 않는다.
- LoRA/SFT/RLHF/GRPO는 1차 구현 범위가 아니다.

## 평가 지표

LLM bot smoke 후 최소 아래 지표를 기록한다.

- invalid_action_rate
- fallback_rate
- avg_latency_ms
- clear_rate
- avg_score_ratio
- avg_turn_count
- slow_clear_rate
- avg_remaining_deck
- avg_remaining_board_discards
- avg_remaining_hand_discards

판단 기준:

- clear_rate가 높아도 fallback 의존이 크면 유효한 LLM policy로 보지 않는다.
- turn count가 과하게 길면 실제 유저 proxy로 약하다.
- prompt 때문에 지나치게 보수적이거나 비현실적 패턴을 반복하면 분석용 라벨로만 둔다.
- 대량 밸런스 판단은 여전히 fresh Dart simulator와 ML candidate probe를 기준으로 한다.

## Fresh ML Pipeline과 연결

LLM autoplay는 현재 fresh ML pipeline의 다음 단계와 병렬 보조 축이다.

- `MODE=grid` fresh run: 대량 통계와 모델 target 개선
- LLM autoplay: 소량 전략 샘플과 disagreement label 수집

두 데이터는 처음부터 섞지 않는다.
LLM decision log는 별도 dataset으로 보고, 나중에 feature sanity나 candidate probe 설명에만 연결한다.

## Acceptance Criteria

1. state/action request JSON schema가 문서화되어 있다.
2. legal action list를 deterministic id로 만들 수 있다.
3. LLM response는 selected action id만 실행 판단에 사용한다.
4. invalid action은 Dart에서 막히고 fallback이 기록된다.
5. LLM decision log JSONL이 기존 sim JSONL과 분리된다.
6. local LLM server가 없어도 graceful failure가 된다.
7. smoke 10 runs 이상이 실행 가능하다.
8. 결과 리포트가 LLM을 밸런스 정답으로 주장하지 않는다.
