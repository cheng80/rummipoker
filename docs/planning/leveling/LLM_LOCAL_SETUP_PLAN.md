# LLM Local Setup Plan

> Status: Draft
> Parent: `docs/planning/leveling/LLM_AUTOPLAY_LEVELING_PLAN.md`

## 목적

`llm_gemma4_v1`은 RummiPoker 밸런스 정답 bot이 아니다.
로컬 LLM을 붙이는 목적은 소량 autoplay decision label과 heuristic bot 대비 판단 차이를 수집하는 것이다.

5번 작업은 실제 장기 실행이 아니라 local model endpoint를 안정적으로 띄우고, decision cache smoke 10 runs까지 갈 수 있는 세팅을 정하는 단계다.

## 권장 경로

Ollama local server만 사용한다.

- 설치/실행이 단순하다.
- HTTP API가 안정적이다.
- prompt-only smoke에 충분하다.

처음부터 OpenAI API나 유료 원격 API를 쓰지 않는다.
이 실험은 반복 호출과 실패 재시도가 있으므로 비용/쿼터 리스크가 있다.

## 모델 후보

1차 smoke:

- `gemma4:e4b`
- temperature `0.2`
- top_p `0.9`
- timeout `60s`

현재 로컬 `ollama list` 기준 `gemma4:e4b`가 설치되어 있다.
`ollama show gemma4:e4b` 기준 architecture `gemma4`, parameters `8.0B`, quantization `Q4_K_M`이다.

## 세팅 순서

1. local LLM server 확인
   - Ollama: `ollama serve`
   - model pull: `ollama pull <model>`
   - health check: `/api/tags`
2. prompt 파일 작성
   - `tools/llm_agent/prompts/rummi_policy_system.md`
   - `tools/llm_agent/prompts/rummi_policy_action_schema.md`
3. Python runner 작성
   - `tools/llm_agent/run_llm_policy.py`
   - 입력: LLM action request JSON
   - 출력: LLM action response JSON
   - 실패 시 `status=error` JSON 반환
4. adapter 작성
   - `tools/llm_agent/adapters/ollama_gemma.py`
5. decision cache smoke
   - Dart가 request JSONL export
   - Python runner가 response JSONL 생성
   - Dart가 response를 validation 후 fallback 처리
6. report 생성
   - invalid_action_rate
   - fallback_rate
   - avg_latency_ms
   - selected action type distribution
   - short reason sample

## 환경 변수 / CLI 초안

Python runner:

```bash
python3 tools/llm_agent/run_llm_policy.py \
  --input logs/llm/requests_smoke.jsonl \
  --out logs/llm/responses_smoke.jsonl \
  --backend ollama \
  --model gemma4:e4b \
  --temperature 0.2 \
  --timeout-seconds 60
```

향후 Dart runner:

```bash
/Users/cheng80/flutter/bin/dart run tools/sim/run_llm_balance_sim.dart \
  --runs 10 \
  --bot llm_gemma4_v1 \
  --fallback-bot contest_policy_v1 \
  --request-out logs/llm/requests_smoke.jsonl \
  --response-in logs/llm/responses_smoke.jsonl \
  --decision-log logs/llm/decisions_smoke.jsonl \
  --out logs/sim/llm_gemma4_v1/smoke_10.jsonl
```

## Prompt 계약

System prompt 핵심:

- 너는 RummiPoker 자동 플레이 정책이다.
- 목표는 현재 battle 클리어 가능성을 높이는 것이다.
- 반드시 제공된 `legal_actions` 중 하나만 선택한다.
- 새 action id를 만들지 않는다.
- JSON만 반환한다.
- 불확실하면 보수적인 선택을 한다.

출력 형식:

```json
{
  "schema_version": 1,
  "status": "ok",
  "selected_action_id": "ACTION_ID",
  "confidence": 0.72,
  "reason": "short reason"
}
```

## 실패 처리

- invalid JSON: `status=error`, `error_code=invalid_json`
- timeout: `status=error`, `error_code=timeout`
- empty response: `status=error`, `error_code=empty_response`
- unknown action id: Dart validation에서 fallback
- schema mismatch: Dart validation에서 fallback

Fallback은 `contest_policy_v1`로 시작한다.
같은 request 재요청 1회는 P1에서만 켠다.

## Git 추적 기준

Commit:

- schema/export/generator/validation Dart code
- Python runner/adapters
- prompt templates
- README/setup plan
- lightweight smoke report

Do not commit:

- `logs/llm/`
- `logs/sim/llm_gemma4_v1/`
- model weights
- local server config
- raw request/response JSONL

## Smoke Pass 기준

P1 smoke는 아래를 만족해야 pass다.

- 10 runs 이상 실행 가능
- invalid action rate 기록
- fallback rate 기록
- avg latency 기록
- local LLM 서버가 꺼져 있으면 graceful error와 fallback 경로가 작동
- 기존 `planner_v3`, `contest_policy_v1` 경로의 시뮬레이션 테스트는 영향 없음

## 2026-05-29 Local Smoke

`gemma4:e4b`로 단일 request JSON smoke를 실행했다.

- runner: `tools/llm_agent/run_llm_policy.py`
- model: `gemma4:e4b`
- result: `status=ok`
- selected action: `confirm_current`
- latency: 31,698ms
- judgment: Ollama 연결과 JSON-only 응답 계약은 동작한다. 첫 decision은 목표 클리어 가능한 confirm action을 정상 선택했다.

## 보류

- LoRA/SFT
- RLHF/GRPO
- 앱 runtime 내 LLM 탑재
- OpenAI API 사용
- LLM 결과 자동 밸런스 반영
