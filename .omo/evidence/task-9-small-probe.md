# Task 9 Fresh Data Small Probe

Status: current-catalog small probe complete. Advisory-only; no model recommendation is applied.

## Metadata

- commit_hash: `adea1717562c13cdb5be52b2c38b428703fd5e30`
- item_catalog_sha256: `12a5907abd10a4278fd1847c596e1fb7cd3232346619432664cb180502b701d5`
- jester_catalog_sha256: `539a19213ec2a2186481249751a45e63425cef61f5ca679f8f26bf48985e1b97`
- inputs: `data/common/items_common_v1.json`, `data/common/jesters_common_phase5.json`
- archive_inputs: `[]`
- advisory_only: `True`

## Runtime Offer Watchlist

- command evidence: `.omo/evidence/task-9-runtime-market-offer-audit.txt`
- runs_per_stage: 80, stages: [1, 2, 3, 4, 5, 6, 7, 8]
- seen coverage: jesters 1.0, items 0.9884
- bought coverage: jesters 1.0, items 0.8837
- four_kind_study: exposure_count=0
- full_house_study: exposure_count=80
- jester_hook: exposure_count=320
- reroll_token: exposure_count=400
- ride_the_bus: exposure_count=16
- straight_flush_study: exposure_count=80
- trade_ticket: exposure_count=240

## Purchase And Use Proxy

- command evidence: `.omo/evidence/task-9-economy-audit.txt`
- purchase_event_count: 29
- purchase_event_count_by_category: `{'jester': 15, 'pack': 12, 'planet': 2}`
- catalog watchlist purchase/source events:
  - four_kind_study: content=0, proxy=0, source=0
  - full_house_study: content=0, proxy=0, source=0
  - jester_hook: content=0, proxy=0, source=0
  - reroll_token: content=0, proxy=0, source=0
  - ride_the_bus: content=0, proxy=0, source=0
  - straight_flush_study: content=0, proxy=0, source=0
  - trade_ticket: content=0, proxy=0, source=0

Use-frequency note: this CLI sequence probe records catalog/proxy purchase events, not real UI item activation. Because every catalog watchlist content/source event is 0 in this small run, watchlist use frequency is also treated as 0 for this gate, not as proof the cards are weak.

## Clear Rate And Score Ratio

- command evidence: `.omo/evidence/task-9-balance-sim-small-probe-run.txt`
- summary evidence: `.omo/evidence/task-9-balance-summary-report.txt`
- market=none: path_clear_rate=0.0, avg_cleared_steps=3.875, avg_total_score_ratio=1.0279, failures={'S2 boss': 3, 'S1 boss': 4, 'S3 boss': 1}
- market=shop_slot_market_v9: path_clear_rate=0.0, avg_cleared_steps=5.625, avg_total_score_ratio=1.0253, failures={'S2 boss': 5, 'S2 big': 1, 'S3 boss': 2}

## Gate Decision

- Early-game overpowered Fate frequency: not observed in this small probe. Runtime watchlist exposure exists, but the sequence economy trace did not purchase the catalog watchlist IDs.
- Broad multi-seed restart: do not start from archived ML outputs. Proceed only from current catalog/runtime artifacts listed above.
- Risk before broad restart: S1-S4 path_clear_rate is 0.0 for both `none` and `shop_slot_market_v9` in this tiny sequence sample, despite avg_total_score_ratio near 1.03. Treat this as a bot/path endurance signal to inspect before long S1-S8 sweeps, not as an automatic pricing change.
- Conclusion: Task 9 small fresh gate is complete and advisory-only. No model recommendation or runtime balance change is applied.
