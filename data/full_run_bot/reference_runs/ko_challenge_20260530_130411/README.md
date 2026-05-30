# Full-run bot reference run: ko challenge 2026-05-30 13:04:11

This folder stores a tracked reference slice for future ML/LLM simulation work.

- Source run: `/private/tmp/rummipoker_full_run_bot/full_trace_challenge_resume2_20260530_130411`
- Runner: `tools/full_run_bot.sh`
- Seed: `91460`
- Difficulty: `challenge`
- Locale: `ko`
- Result: S8 boss clear, `All tests passed`
- Trace rows: `435`

Included files:

- `full_run_trace.jsonl`: raw full-run trace events extracted from the driver log.
- `full_run_trace_reference.md`: compact human-readable run summary.
- `full_run_decision_reference.json`: compact decision reference for simulation probes.
- `full_run_policy_dataset.jsonl`: chosen-action rows for ML/LLM schema smoke.
- `full_run_policy_prior.json`: compact behavior prior for LLM comparison and sim probes.
- `full_run_policy_dataset_report.md`: data-quality and use-case report.

Regenerate derived files:

```bash
python3 tools/full_run_policy_dataset.py \
  data/full_run_bot/reference_runs/ko_challenge_20260530_130411/full_run_trace.jsonl \
  --dataset-out data/full_run_bot/reference_runs/ko_challenge_20260530_130411/full_run_policy_dataset.jsonl \
  --prior-out data/full_run_bot/reference_runs/ko_challenge_20260530_130411/full_run_policy_prior.json \
  --report-out data/full_run_bot/reference_runs/ko_challenge_20260530_130411/full_run_policy_dataset_report.md
```

Excluded files:

- `10_full_run_bot.log`
- `runner_console.log`
- `chromedriver.log`
- `chromedriver_install.log`

Those logs are execution artifacts and are not needed for normal model/reference reuse.
