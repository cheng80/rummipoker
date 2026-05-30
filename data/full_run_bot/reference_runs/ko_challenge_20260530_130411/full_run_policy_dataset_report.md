# Full-run Policy Dataset Report

## Summary

- source: `data/full_run_bot/reference_runs/ko_challenge_20260530_130411/full_run_trace.jsonl`
- trace rows: 435
- dataset rows: 392
- success terminal: True

## Event Coverage

- battle_action: 368
- battle_item_use_applied: 4
- battle_item_use_start: 4
- blind_opened: 6
- cashout_to_market: 5
- checkpoint_saved: 5
- market_after_evidence: 6
- market_bought_item: 3
- market_bought_jester: 3
- market_decision: 20
- market_enter: 6
- market_sold_jester: 2
- run_complete: 1
- run_resumed: 1
- run_start: 1

## Battle Priors

- S7:big: {'confirm': 1, 'draw': 27, 'place': 27}
- S7:boss: {'confirm': 1, 'draw': 27, 'moveBoard': 1, 'place': 27}
- S7:small: {'draw': 15, 'place': 15}
- S8:big: {'confirm': 1, 'draw': 25, 'place': 25}
- S8:boss: {'confirm': 4, 'draw': 52, 'moveBoard': 1, 'place': 52}
- S8:small: {'confirm': 2, 'draw': 32, 'moveBoard': 1, 'place': 32}

## Market Priors

- jester: {'consider_buy': 9, 'sell_for_replacement': 2}
- quickSlot: {'consider_buy': 3}
- tile: {'consider_buy': 6}

## Item Observations

- line_polish: 1
- move_token: 1
- yellow_swatch: 2

## Judgment

This is useful as a high-stage full-run behavior reference and schema smoke.
It is not enough for model training by itself because it is a single successful seed and does not include full legal-action candidate sets.

## Recommended Next Use

1. Feed `full_run_policy_prior.json` into LLM comparison reports as a behavior prior.
2. Use `full_run_policy_dataset.jsonl` to validate ML feature extraction and chosen-action target shape.
3. Collect more standard/challenge multi-seed traces before training or balance recommendation.
