#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
cd "$repo_root"

today="$(date +%Y%m%d)"

DART_BIN="${DART_BIN:-/Users/cheng80/flutter/bin/dart}"
PYTHON_BIN="${PYTHON_BIN:-python3}"
BOT="${BOT:-contest_policy_v1}"
MODE="${MODE:-standard}"
CHUNKS="${CHUNKS:-30}"
RUNS_PER_CHUNK="${RUNS_PER_CHUNK:-5}"
SEED="${SEED:-94600}"
SEED_STRIDE="${SEED_STRIDE:-100000}"
FLUSH_EVERY_ROWS="${FLUSH_EVERY_ROWS:-50}"
DO_MODEL="${DO_MODEL:-1}"
MIN_RUN_COUNT="${MIN_RUN_COUNT:-3}"
OUT_PREFIX="${OUT_PREFIX:-logs/sim/fresh_runtime_${today}_${BOT}_chunked}"
FEATURE_PREFIX="${FEATURE_PREFIX:-analysis/leveling/generated/features/fresh_${BOT}_${today}}"
METADATA_PREFIX="${METADATA_PREFIX:-analysis/leveling/data/features/fresh_${BOT}_${today}}"
MODEL_DIR="${MODEL_DIR:-analysis/leveling/models/fresh_${BOT}_${today}_preoutcome}"
MODEL_REPORT_DIR="${MODEL_REPORT_DIR:-analysis/leveling/reports}"
MODEL_TARGETS="${MODEL_TARGETS:-clear_rate avg_score_ratio cleared_majority}"

experiment_id="${EXPERIMENT_ID:-base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_runtime_station_pool_v1}"
if [[ "$MODE" == "grid" ]]; then
  market_profiles="${MARKET_PROFILES:-none,shop_slot_market_v9,shop_slot_market_v12,shop_slot_market_v13,shop_slot_market_v16}"
  loadout_ids="${LOADOUT_IDS:-progression_route_balanced progression_route_power progression_route_delayed}"
else
  market_profiles="${MARKET_PROFILES:-none,shop_slot_market_v9}"
  loadout_ids="${LOADOUT_IDS:-progression_route_balanced progression_route_power}"
fi
stations="${STATIONS:-1,2,3,4,5,6,7,8}"
blind_tiers="${BLIND_TIERS:-small,big,boss}"
difficulty="${DIFFICULTY:-standard}"
run_modifier="${RUN_MODIFIER:-basic}"

if [[ ! -x "$DART_BIN" ]]; then
  DART_BIN="dart"
fi

echo "[leveling] out_prefix=$OUT_PREFIX"
echo "[leveling] mode=$MODE bot=$BOT chunks=$CHUNKS runs_per_chunk=$RUNS_PER_CHUNK seed=$SEED"

sim_args=(
  --bot "$BOT"
  --sequence-mode station_path
  --stations "$stations"
  --blind-tiers "$blind_tiers"
  --difficulty "$difficulty"
  --experiment-id "$experiment_id"
  --market-profiles "$market_profiles"
  --sim-economy-mode gated_known_cost
  --sim-reward-scale "${SIM_REWARD_SCALE:-0.40}"
  --sim-price-scale "${SIM_PRICE_SCALE:-2.2}"
  --sim-market-spend-mode "${SIM_MARKET_SPEND_MODE:-reroll_slot_sell_v1}"
  --sim-market-choice-mode "${SIM_MARKET_CHOICE_MODE:-affordable_alternative_v1}"
  --sim-price-band-mode "${SIM_PRICE_BAND_MODE:-catalog_normalized_v1}"
  --run-modifier "$run_modifier"
)

for loadout in $loadout_ids; do
  sim_args+=(--loadout-id "$loadout")
done

"$PYTHON_BIN" tools/sim/chunked_balance_run.py \
  --resume \
  --chunks "$CHUNKS" \
  --runs-per-chunk "$RUNS_PER_CHUNK" \
  --seed "$SEED" \
  --seed-stride "$SEED_STRIDE" \
  --out-prefix "$OUT_PREFIX" \
  --dart "$DART_BIN" \
  --flush-every-rows "$FLUSH_EVERY_ROWS" \
  -- "${sim_args[@]}"

jsonl_path="${OUT_PREFIX}.jsonl"
summary_path="${OUT_PREFIX}_summary.json"
audit_path="${OUT_PREFIX}_economy_audit.json"

"$PYTHON_BIN" tools/sim/economy_audit.py \
  --jsonl "$jsonl_path" \
  --summary "$summary_path" \
  --json-out "$audit_path"

"$PYTHON_BIN" tools/leveling/build_feature_table.py "$summary_path" \
  --feature-mode preoutcome \
  --out "${FEATURE_PREFIX}_preoutcome_battle.csv" \
  --metadata-out "${METADATA_PREFIX}_preoutcome_battle.metadata.json"

"$PYTHON_BIN" tools/leveling/build_feature_table.py "$summary_path" \
  --feature-mode outcome_summary \
  --out "${FEATURE_PREFIX}_outcome_summary.csv" \
  --metadata-out "${METADATA_PREFIX}_outcome_summary.metadata.json"

"$PYTHON_BIN" tools/leveling/build_feature_table.py "$summary_path" \
  --feature-mode preoutcome_sequence \
  --out "${FEATURE_PREFIX}_preoutcome_sequence.csv" \
  --metadata-out "${METADATA_PREFIX}_preoutcome_sequence.metadata.json"

if [[ "$DO_MODEL" == "1" ]]; then
  if [[ ! -x .venv_leveling/bin/python ]]; then
    "$PYTHON_BIN" -m venv .venv_leveling
  fi
  if ! .venv_leveling/bin/python - <<'PY' >/dev/null 2>&1
import pandas  # noqa: F401
import sklearn  # noqa: F401
PY
  then
    .venv_leveling/bin/python -m pip install -q -r tools/sim/requirements.txt
  fi
  for target in $MODEL_TARGETS; do
    task="regression"
    if [[ "$target" == "cleared_majority" ]]; then
      task="classification"
    fi
    .venv_leveling/bin/python tools/leveling/train_leveling_model.py \
      --feature-mode preoutcome \
      --features "${FEATURE_PREFIX}_preoutcome_battle.csv" \
      --target "$target" \
      --task "$task" \
      --report-out "${MODEL_REPORT_DIR}/fresh_${BOT}_${today}_${target}_preoutcome_model_report.md" \
      --model-dir "${MODEL_DIR}/${target}" \
      --test-size "${TEST_SIZE:-0.25}" \
      --seed "${MODEL_SEED:-20260529}" \
      --model-strategy "${MODEL_STRATEGY:-auto}" \
      --min-run-count "$MIN_RUN_COUNT"
  done
fi

rows="$(wc -l < "$jsonl_path" | tr -d ' ')"
echo "[leveling] complete rows=$rows"
echo "[leveling] jsonl=$jsonl_path"
echo "[leveling] summary=$summary_path"
echo "[leveling] audit=$audit_path"
echo "[leveling] metadata=${METADATA_PREFIX}_*.metadata.json"
if [[ "$DO_MODEL" == "1" ]]; then
  echo "[leveling] model_reports=${MODEL_REPORT_DIR}/fresh_${BOT}_${today}_*_preoutcome_model_report.md"
  echo "[leveling] model_dir=$MODEL_DIR"
fi
