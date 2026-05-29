# LLM Station Path Smoke

## Summary

- model: gemma4:e4b
- runs: 1
- station_range: S1~S1
- tiers: small, big, boss
- turn_cap_per_blind: 200
- decisions: 214
- item_decisions: 108
- market_decisions: 1
- terminal_blinds: 2
- cleared_blinds: 1
- valid responses: 214
- valid item responses: 108
- valid market responses: 1
- market_execute_failures: 0
- fallback executions: 0
- fallback_rate: 0.0000
- diverged_from_baseline: 54
- divergence_rate: 0.2523
- avg_latency_ms: 13873.0

## Turn Count Semantics

`turn` and `turn_cap_per_blind` are action-step counts, not deck-card counts.
A typical tile consumes two action steps: one `draw` and one `place`.
Additional `confirm`, discard, move, item, and market decisions are logged as separate rows.

## Action Types

- draw: 102
- place: 102
- confirm: 10

## Item Action Types

- skip: 108

## Market Action Types

- buyItem: 1

## Scope

This is the first S1-S8-capable LLM station path runner.
It uses real blind specs, target scores, resources, and boss modifiers.
Battle item-use and market buy/sell/reroll decision contracts are included as smoke rows.
Cleared blind cashout and market purchase/sell/reroll effects are applied to run progress.
Targeted item interactions, richer shop policy, and long S1-S8 runs are still pending before this can be treated as full balance evidence.