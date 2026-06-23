# LLM Station Path Smoke

## Summary

- model: gemma4:e4b
- runs: 1
- station_range: S1~S8
- tiers: small, big, boss
- turn_cap_per_blind: 2
- initial_gold: 20
- initial_items: board_scrap, chip_capsule, battle_pouch
- decisions: 48
- item_decisions: 48
- market_decisions: 24
- terminal_blinds: 24
- cleared_blinds: 0
- valid responses: 48
- valid item responses: 48
- valid market responses: 24
- market_execute_failures: 0
- fallback executions: 0
- fallback_rate: 0.0000
- diverged_from_baseline: 24
- divergence_rate: 0.5000
- avg_latency_ms: 16946.0

## Action Types

- draw: 24
- place: 24

## Item Action Types

- skip: 48

## Market Action Types

- buyJester: 3
- skip: 21

## Scope

This is the first S1-S8-capable LLM station path runner.
It uses real blind specs, target scores, resources, and boss modifiers.
Battle item-use and market buy/sell/reroll decision contracts are included as smoke rows.
Cleared blind cashout and market purchase/sell/reroll effects are applied to run progress.
Targeted item interactions, richer shop policy, and long S1-S8 runs are still pending before this can be treated as full balance evidence.