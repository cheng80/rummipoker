# Full Run Bot Trace Reference

- source: `/tmp/rummipoker_full_run_bot/full_trace_challenge_resume2_20260530_130411/full_run_trace.jsonl`
- rows: 435
- event types: {'run_start': 1, 'run_resumed': 1, 'market_enter': 6, 'market_decision': 20, 'market_bought_jester': 3, 'market_sold_jester': 2, 'market_after_evidence': 6, 'blind_opened': 6, 'battle_action': 368, 'cashout_to_market': 5, 'checkpoint_saved': 5, 'battle_item_use_start': 4, 'battle_item_use_applied': 4, 'market_bought_item': 3, 'run_complete': 1}

## Battle
- battle actions: 368
- action mix: {'draw': 178, 'place': 178, 'confirm': 9, 'moveBoard': 3}
- confirm preview score: min=525 max=8921 avg=3584.0
- by stage:
  - S7 big: {'draw': 27, 'place': 27, 'confirm': 1}
  - S7 boss: {'draw': 27, 'place': 27, 'confirm': 1, 'moveBoard': 1}
  - S7 small: {'draw': 15, 'place': 15}
  - S8 big: {'draw': 25, 'place': 25, 'confirm': 1}
  - S8 boss: {'draw': 52, 'place': 52, 'confirm': 4, 'moveBoard': 1}
  - S8 small: {'draw': 32, 'place': 32, 'confirm': 2, 'moveBoard': 1}

## Market
- market state events: 40
- market decisions: 20
- decision lanes: {'jester': 11, 'tile': 6, 'quickSlot': 3}
- buys: {'market_bought_jester': 3, 'market_bought_item': 3}
- sells: {'market_sold_jester': 2}

## Items
- battle item attempts: 4
- battle item applied: 4
- battle item ids: {'move_token': 1, 'line_polish': 1, 'yellow_swatch': 2}

## Usage
Use this report for trace sanity only. Use the raw JSONL as the training/reference source.
