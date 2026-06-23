# LLM Turn Loop Smoke

## Summary

- model: gemma4:e4b
- runs: 2
- turn_cap: 3
- decisions: 6
- valid responses: 6
- fallback executions: 0
- fallback_rate: 0.0000
- diverged_from_baseline: 5
- divergence_rate: 0.8333
- llm_execute_failures: 0
- baseline_execute_failures: 0
- avg_latency_ms: 20446.3
- llm_target_reached_runs: 0
- baseline_target_reached_runs: 0
- final_score_delta_vs_baseline: 150

## LLM/Fallback Executed Action Types

- place: 3
- confirm: 1
- draw: 2

## Baseline Action Types

- place: 3
- draw: 3

## Scope

This is a short turn-loop smoke. It validates multi-turn wiring, fallback behavior, and baseline divergence only.
It is not yet a balance recommendation source.