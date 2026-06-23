# LLM Station Path Smoke

## Summary

- model: gemma4:e4b
- runs: 1
- station_range: S1~S1
- tiers: small
- turn_cap_per_blind: 2
- decisions: 2
- item_decisions: 0
- market_decisions: 0
- terminal_blinds: 1
- cleared_blinds: 0
- valid responses: 2
- valid item responses: 0
- valid market responses: 0
- market_execute_failures: 0
- fallback executions: 0
- fallback_rate: 0.0000
- diverged_from_baseline: 1
- divergence_rate: 0.5000
- avg_latency_ms: 18473.5

## Action Types

- draw: 1
- place: 1

## Item Action Types


## Market Action Types


## Scope

This is the first S1-S8-capable LLM station path runner.
It uses real blind specs, target scores, resources, and boss modifiers.
Battle item-use and market buy/sell/reroll decision contracts are included as smoke rows.
Cleared blind cashout and market purchase/sell/reroll effects are applied to run progress.
Targeted item interactions, richer shop policy, and long S1-S8 runs are still pending before this can be treated as full balance evidence.