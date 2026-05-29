# LLM Station Path Smoke

## Summary

- model: gemma4:e4b
- runs: 1
- station_range: S1~S1
- tiers: small
- turn_cap_per_blind: 1
- decisions: 1
- terminal_blinds: 1
- cleared_blinds: 0
- valid responses: 1
- fallback executions: 0
- fallback_rate: 0.0000
- diverged_from_baseline: 0
- divergence_rate: 0.0000
- avg_latency_ms: 24731.0

## Action Types

- draw: 1

## Scope

This is the first S1-S8-capable LLM station path runner.
It uses real blind specs, target scores, resources, and boss modifiers.
Market buy/sell/reroll and item-use choices are still pending before this can be treated as full balance evidence.