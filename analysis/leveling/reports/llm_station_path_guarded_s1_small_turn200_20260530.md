# LLM Station Path Smoke

## Summary

- model: gemma4:e4b
- runs: 1
- station_range: S1~S1
- tiers: small
- turn_cap_per_blind: 200
- decisions: 112
- item_decisions: 0
- market_decisions: 0
- terminal_blinds: 1
- cleared_blinds: 0
- valid responses: 112
- valid item responses: 0
- valid market responses: 0
- market_execute_failures: 0
- fallback executions: 0
- fallback_rate: 0.0000
- diverged_from_baseline: 21
- divergence_rate: 0.1875
- avg_latency_ms: 15078.1

## Action Types

- draw: 52
- place: 52
- confirm: 8

## Item Action Types


## Market Action Types


## Scope

This is the first S1-S8-capable LLM station path runner.
It uses real blind specs, target scores, resources, and boss modifiers.
Battle item-use and market buy/sell/reroll decision contracts are included as smoke rows.
Cleared blind cashout and market purchase/sell/reroll effects are applied to run progress.
Targeted item interactions, richer shop policy, and long S1-S8 runs are still pending before this can be treated as full balance evidence.