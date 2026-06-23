# LLM Station Path Smoke

## Summary

- model: gemma4:e4b
- runs: 1
- station_range: S1~S1
- tiers: small
- turn_cap_per_blind: 200
- decisions: 106
- item_decisions: 0
- market_decisions: 1
- terminal_blinds: 1
- cleared_blinds: 1
- valid responses: 106
- valid item responses: 0
- valid market responses: 1
- market_execute_failures: 0
- fallback executions: 0
- fallback_rate: 0.0000
- diverged_from_baseline: 0
- divergence_rate: 0.0000
- avg_latency_ms: 14434.1

## Action Types

- draw: 50
- place: 50
- confirm: 6

## Item Action Types


## Market Action Types

- buyItem: 1

## Scope

This is the first S1-S8-capable LLM station path runner.
It uses real blind specs, target scores, resources, and boss modifiers.
Battle item-use and market buy/sell/reroll decision contracts are included as smoke rows.
Cleared blind cashout and market purchase/sell/reroll effects are applied to run progress.
Targeted item interactions, richer shop policy, and long S1-S8 runs are still pending before this can be treated as full balance evidence.