# LLM vs Full-run Prior Comparison

## Summary

- input: `logs/llm/station_path_s1_s8_item_market_sweep_20260530.jsonl`
- prior: `data/full_run_bot/reference_runs/ko_challenge_20260530_130411/full_run_policy_prior.json`
- comparison rows: 120
- prior available rows: 63
- prior gap rows: 57

## Rows By Type

- llm_battle_item_decision: 48
- llm_market_decision: 24
- llm_station_path_turn: 48

## Risk Flags

- diverged_from_baseline: 24
- no_reference_prior_for_lane: 21
- no_reference_prior_for_stage: 36
- unknown_market_lane: 21

## Actions By Stage

- S1:big: {'draw': 1, 'place': 1, 'skip': 3}
- S1:boss: {'draw': 1, 'place': 1, 'skip': 3}
- S1:small: {'buyJester': 1, 'draw': 1, 'place': 1, 'skip': 2}
- S2:big: {'buyJester': 1, 'draw': 1, 'place': 1, 'skip': 2}
- S2:boss: {'draw': 1, 'place': 1, 'skip': 3}
- S2:small: {'buyJester': 1, 'draw': 1, 'place': 1, 'skip': 2}
- S3:big: {'draw': 1, 'place': 1, 'skip': 3}
- S3:boss: {'draw': 1, 'place': 1, 'skip': 3}
- S3:small: {'draw': 1, 'place': 1, 'skip': 3}
- S4:big: {'draw': 1, 'place': 1, 'skip': 3}
- S4:boss: {'draw': 1, 'place': 1, 'skip': 3}
- S4:small: {'draw': 1, 'place': 1, 'skip': 3}
- S5:big: {'draw': 1, 'place': 1, 'skip': 3}
- S5:boss: {'draw': 1, 'place': 1, 'skip': 3}
- S5:small: {'draw': 1, 'place': 1, 'skip': 3}
- S6:big: {'draw': 1, 'place': 1, 'skip': 3}
- S6:boss: {'draw': 1, 'place': 1, 'skip': 3}
- S6:small: {'draw': 1, 'place': 1, 'skip': 3}
- S7:big: {'draw': 1, 'place': 1, 'skip': 3}
- S7:boss: {'draw': 1, 'place': 1, 'skip': 3}
- S7:small: {'draw': 1, 'place': 1, 'skip': 3}
- S8:big: {'draw': 1, 'place': 1, 'skip': 3}
- S8:boss: {'draw': 1, 'place': 1, 'skip': 3}
- S8:small: {'draw': 1, 'place': 1, 'skip': 3}

## Sample Divergences

- S1:small llm_station_path_turn selected=draw executed=draw prior_top=None flags=no_reference_prior_for_stage
- S1:small llm_station_path_turn selected=place executed=place prior_top=None flags=no_reference_prior_for_stage,diverged_from_baseline
- S1:big llm_station_path_turn selected=draw executed=draw prior_top=None flags=no_reference_prior_for_stage
- S1:big llm_station_path_turn selected=place executed=place prior_top=None flags=no_reference_prior_for_stage,diverged_from_baseline
- S1:big llm_market_decision selected=skip executed=None prior_top=None flags=unknown_market_lane,no_reference_prior_for_lane
- S1:boss llm_station_path_turn selected=draw executed=draw prior_top=None flags=no_reference_prior_for_stage
- S1:boss llm_station_path_turn selected=place executed=place prior_top=None flags=no_reference_prior_for_stage,diverged_from_baseline
- S1:boss llm_market_decision selected=skip executed=None prior_top=None flags=unknown_market_lane,no_reference_prior_for_lane
- S2:small llm_station_path_turn selected=draw executed=draw prior_top=None flags=no_reference_prior_for_stage
- S2:small llm_station_path_turn selected=place executed=place prior_top=None flags=no_reference_prior_for_stage,diverged_from_baseline
- S2:big llm_station_path_turn selected=draw executed=draw prior_top=None flags=no_reference_prior_for_stage
- S2:big llm_station_path_turn selected=place executed=place prior_top=None flags=no_reference_prior_for_stage,diverged_from_baseline

## Use

This report is diagnostic only. A prior gap means the tracked reference run does not cover that station/tier yet.
Use repeated divergences in covered S7/S8 stages to decide which LLM prompt or guard rule to improve.
