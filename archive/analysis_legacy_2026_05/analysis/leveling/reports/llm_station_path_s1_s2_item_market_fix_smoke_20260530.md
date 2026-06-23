# LLM Station Path Smoke

## Summary

- model: gemma4:e4b
- runs: 1
- station_range: S1~S2
- tiers: small, big, boss
- turn_cap_per_blind: 2
- initial_gold: 20
- initial_items: board_scrap, chip_capsule, battle_pouch
- decisions: 12
- item_decisions: 12
- market_decisions: 6
- terminal_blinds: 6
- cleared_blinds: 0
- valid responses: 12
- valid item responses: 12
- valid market responses: 6
- market_execute_failures: 0
- fallback executions: 0
- fallback_rate: 0.0000
- diverged_from_baseline: 6
- divergence_rate: 0.5000
- avg_latency_ms: 15702.6

## Action Types

- draw: 6
- place: 6

## Item Action Types

- skip: 12

## Market Action Types

- buyJester: 3
- skip: 3

## Scope

This is the first S1-S8-capable LLM station path runner.
It uses real blind specs, target scores, resources, and boss modifiers.
Battle item-use and market buy/sell/reroll decision contracts are included as smoke rows.
Cleared blind cashout and market purchase/sell/reroll effects are applied to run progress.
Targeted item interactions, richer shop policy, and long S1-S8 runs are still pending before this can be treated as full balance evidence.