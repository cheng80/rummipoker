#!/usr/bin/env python3
"""레벨링 feature table로 ML 전환 스캐폴딩 metric을 만든다."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any


DEFAULT_FEATURES = "analysis/leveling/data/features/leveling_feature_table.csv"
DEFAULT_PREOUTCOME_FEATURES = "analysis/leveling/data/features/leveling_preoutcome_feature_table.csv"
DEFAULT_REPORT = "analysis/leveling/reports/model_recommendation_report.md"
DEFAULT_PREOUTCOME_REPORT = "analysis/leveling/reports/preoutcome_baseline_model_report.md"
DEFAULT_MODEL_DIR = "analysis/leveling/models"

NUMERIC_FEATURES = [
    "station",
    "run_count",
    "avg_score_ratio",
    "avg_turn_count",
    "avg_confirm_action_count",
    "avg_max_single_confirm_score",
    "avg_remaining_deck",
    "avg_remaining_board_discards",
    "avg_remaining_hand_discards",
    "avg_remaining_board_moves",
    "slow_clear_share_of_clears",
]

CATEGORICAL_FEATURES = [
    "experiment_id",
    "loadout_id",
    "blind_tier",
    "difficulty",
    "market_profile",
    "run_modifier",
    "tempo_risk_label",
]

PREOUTCOME_NUMERIC_FEATURES = [
    "station",
    "tier_index",
    "difficulty_multiplier",
    "target_multiplier",
    "small_target_multiplier",
    "big_target_multiplier",
    "boss_target_multiplier",
    "s1_boss_target_multiplier",
    "s2_boss_target_multiplier",
    "s3_boss_target_multiplier",
    "reward_multiplier",
    "sweep_reward_scale",
    "sweep_price_scale",
    "has_market_profile",
    "market_profile_version",
    "has_boss_constraint",
    "boss_family_index",
]

PREOUTCOME_CATEGORICAL_FEATURES = [
    "base_experiment_id",
    "loadout_id",
    "blind_tier",
    "difficulty",
    "market_profile",
    "resolved_market_profile",
    "run_modifier",
    "sim_boss_constraint_id",
    "sim_economy_mode",
    "sim_market_budget_mode",
    "sim_market_spend_mode",
    "sim_price_band_mode",
    "sim_market_choice_mode",
]


def main() -> int:
    parser = argparse.ArgumentParser(
        description="레벨링 feature table로 RandomForest 설명 baseline을 학습하고 MD 리포트를 만듭니다.",
    )
    parser.add_argument(
        "--feature-mode",
        choices=["outcome_summary", "preoutcome", "preoutcome_sequence"],
        default="outcome_summary",
        help="학습에 사용할 feature set. preoutcome은 사전 조건 feature만 사용합니다.",
    )
    parser.add_argument("--features", default=None, help="feature table CSV")
    parser.add_argument("--target", default="clear_rate", help="예측 target 컬럼")
    parser.add_argument("--report-out", default=None, help="MD 리포트 출력 경로")
    parser.add_argument("--model-dir", default=DEFAULT_MODEL_DIR, help="모델 산출물 폴더")
    parser.add_argument("--test-size", type=float, default=0.25)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    try:
        import pandas as pd
        from sklearn.compose import ColumnTransformer
        from sklearn.ensemble import RandomForestRegressor
        from sklearn.metrics import mean_absolute_error, r2_score
        from sklearn.model_selection import train_test_split
        from sklearn.pipeline import Pipeline
        from sklearn.preprocessing import OneHotEncoder
    except ImportError as error:
        raise SystemExit(
            "필요한 패키지가 없습니다. pandas와 scikit-learn 설치 후 다시 실행하세요: "
            f"{error}",
        ) from error

    default_features = DEFAULT_PREOUTCOME_FEATURES if args.feature_mode in {"preoutcome", "preoutcome_sequence"} else DEFAULT_FEATURES
    feature_path = Path(args.features or default_features)
    if not feature_path.exists():
        raise SystemExit(f"feature table이 없습니다: {feature_path}")

    df = pd.read_csv(feature_path)
    if args.target not in df.columns:
        raise SystemExit(f"target 컬럼이 없습니다: {args.target}")
    if len(df) < 8:
        raise SystemExit("학습에는 최소 8개 이상의 group row가 필요합니다.")

    if args.feature_mode == "preoutcome_sequence":
        all_numeric_features = [
            "station_path_length",
            "tier_path_length",
            "difficulty_multiplier",
            "target_multiplier",
            "small_target_multiplier",
            "big_target_multiplier",
            "boss_target_multiplier",
            "s1_boss_target_multiplier",
            "s2_boss_target_multiplier",
            "s3_boss_target_multiplier",
            "reward_multiplier",
            "sweep_reward_scale",
            "sweep_price_scale",
            "has_market_profile",
            "market_profile_version",
        ]
        all_categorical_features = PREOUTCOME_CATEGORICAL_FEATURES
    elif args.feature_mode == "preoutcome":
        all_numeric_features = PREOUTCOME_NUMERIC_FEATURES
        all_categorical_features = PREOUTCOME_CATEGORICAL_FEATURES
    else:
        all_numeric_features = NUMERIC_FEATURES
        all_categorical_features = CATEGORICAL_FEATURES

    features = [key for key in [*all_numeric_features, *all_categorical_features] if key in df.columns]
    numeric_features = [key for key in all_numeric_features if key in features]
    categorical_features = [key for key in all_categorical_features if key in features]
    if not features:
        raise SystemExit("사용 가능한 feature 컬럼이 없습니다.")

    x = df[features].copy()
    y = df[args.target].astype(float)
    x_train, x_test, y_train, y_test = train_test_split(
        x,
        y,
        test_size=args.test_size,
        random_state=args.seed,
    )

    preprocessor = ColumnTransformer(
        transformers=[
            ("num", "passthrough", numeric_features),
            ("cat", OneHotEncoder(handle_unknown="ignore"), categorical_features),
        ],
    )
    model = RandomForestRegressor(
        n_estimators=200,
        min_samples_leaf=2,
        random_state=args.seed,
    )
    pipeline = Pipeline(
        steps=[
            ("preprocessor", preprocessor),
            ("model", model),
        ],
    )
    pipeline.fit(x_train, y_train)
    predictions = pipeline.predict(x_test)

    metrics = {
        "row_count": int(len(df)),
        "train_count": int(len(x_train)),
        "test_count": int(len(x_test)),
        "target": args.target,
        "feature_mode": args.feature_mode,
        "mae": float(mean_absolute_error(y_test, predictions)),
        "r2": float(r2_score(y_test, predictions)) if len(y_test) > 1 else 0.0,
    }

    model_dir = Path(args.model_dir)
    model_dir.mkdir(parents=True, exist_ok=True)
    artifact_prefix = args.target if args.feature_mode == "outcome_summary" else f"{args.target}_{args.feature_mode}"
    importance_path = model_dir / f"{artifact_prefix}_feature_importance.csv"
    write_feature_importance(pipeline, numeric_features, categorical_features, importance_path)
    metrics_path = model_dir / f"{artifact_prefix}_metrics.json"
    metrics_path.write_text(json.dumps(metrics, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    default_report = DEFAULT_PREOUTCOME_REPORT if args.feature_mode == "preoutcome" else DEFAULT_REPORT
    report_path = Path(args.report_out or default_report)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(
        build_report(
            feature_path=feature_path,
            metrics=metrics,
            importance_path=importance_path,
            metrics_path=metrics_path,
            source_paths=read_feature_source_paths(feature_path),
            feature_mode=args.feature_mode,
            numeric_features=numeric_features,
            categorical_features=categorical_features,
        ),
        encoding="utf-8",
    )

    print(f"report: {report_path}")
    print(f"metrics: {metrics_path}")
    print(f"feature importance: {importance_path}")
    return 0


def write_feature_importance(
    pipeline: Any,
    numeric_features: list[str],
    categorical_features: list[str],
    out_path: Path,
) -> None:
    preprocessor = pipeline.named_steps["preprocessor"]
    model = pipeline.named_steps["model"]
    names: list[str] = []
    names.extend(numeric_features)
    if categorical_features:
        encoder = preprocessor.named_transformers_["cat"]
        names.extend(encoder.get_feature_names_out(categorical_features).tolist())

    importances = model.feature_importances_
    rows = sorted(zip(names, importances), key=lambda entry: entry[1], reverse=True)
    with out_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(["feature", "importance"])
        writer.writerows(rows)


def build_report(
    *,
    feature_path: Path,
    metrics: dict[str, Any],
    importance_path: Path,
    metrics_path: Path,
    source_paths: list[str],
    feature_mode: str,
    numeric_features: list[str],
    categorical_features: list[str],
) -> str:
    top_importances = read_top_importances(importance_path, limit=10)
    source_lines = [f"- `{source_path}`" for source_path in source_paths]
    if not source_lines:
        source_lines = ["- source metadata not found"]
    top_importance_lines = [
        "| Feature | Importance |",
        "|---|---:|",
        *[
            f"| `{feature}` | {importance:.4f} |"
            for feature, importance in top_importances
        ],
    ]
    if feature_mode == "preoutcome":
        return build_preoutcome_report(
            feature_path=feature_path,
            metrics=metrics,
            importance_path=importance_path,
            metrics_path=metrics_path,
            source_lines=source_lines,
            top_importance_lines=top_importance_lines,
            numeric_features=numeric_features,
            categorical_features=categorical_features,
        )

    return "\n".join(
        [
            "# Leveling ML Transition Scaffold Report",
            "",
            "## Scope",
            "",
            "이 리포트는 실제 ML 전환 완료 보고서가 아니다.",
            "현재 모델은 outcome-derived summary feature로 `clear_rate`를 설명하는 baseline이며, target score, boss severity, market weight, economy scale 후보를 추천하지 않는다.",
            "런타임 밸런스를 자동으로 바꾸지 않으며, 현재 산출물을 ML 기반 밸런스 자동 조정 근거로 사용하지 않는다.",
            "",
            "## Dataset",
            "",
            f"- feature table: `{feature_path}`",
            f"- rows: {metrics['row_count']}",
            f"- train rows: {metrics['train_count']}",
            f"- test rows: {metrics['test_count']}",
            f"- target: `{metrics['target']}`",
            "",
            "Source summaries:",
            "",
            *source_lines,
            "",
            "Each row is a simulation group aggregated by experiment, loadout, blind tier, difficulty, market profile, run modifier, station, and outcome summary values. The current dataset is simulation-derived. It is not live player telemetry.",
            "",
            "## Feature And Target Definition",
            "",
            "Target:",
            "",
            f"- `{metrics['target']}`: clear share for the aggregated simulation group.",
            "",
            "Numeric features:",
            "",
            *[f"- `{feature}`" for feature in NUMERIC_FEATURES],
            "",
            "Categorical features:",
            "",
            *[f"- `{feature}`" for feature in CATEGORICAL_FEATURES],
            "",
            "Silver-label columns are preserved in the feature table as analysis context, but this first model predicts the selected target directly rather than training on heuristic labels.",
            "",
            "## Model",
            "",
            "Model type: `RandomForestRegressor`.",
            "",
            "Reason:",
            "",
            "- It handles non-linear interactions between station, blind tier, market profile, and resource residuals without requiring a fixed linear assumption.",
            "- It can mix numeric and one-hot categorical features through a simple preprocessing pipeline.",
            "- Feature importance is easy to inspect for a first scaffold report.",
            "",
            "This model is intentionally offline-only and descriptive. It does not patch runtime target scores, boss modifiers, market weights, or economy constants.",
            "",
            "## Metric",
            "",
            f"- MAE: {metrics['mae']:.4f}",
            f"- R2: {metrics['r2']:.4f}",
            "",
            "Interpretation:",
            "",
            f"- MAE around `{metrics['mae']:.4f}` is the average held-out group prediction error for `{metrics['target']}`.",
            f"- R2 around `{metrics['r2']:.4f}` means the model explains most held-out variance in this simulation dataset when the value is high.",
            "- This is not evidence that the game is fully balanced.",
            "- This is also not evidence that ML transition is complete.",
            "- It only shows that the current summary rows can be loaded into a supervised modeling scaffold and that outcome-derived features can explain held-out clear-rate variance.",
            "",
            "## Feature Importance Snapshot",
            "",
            *top_importance_lines,
            "",
            "Reading:",
            "",
            "- If outcome-derived features dominate, the model is more descriptive than prescriptive.",
            "- Future recommendation models should add pre-battle configuration features so they can suggest interventions rather than only explain outcomes.",
            "",
            "## Artifacts",
            "",
            f"- metrics JSON: `{metrics_path}`",
            f"- feature importance CSV: `{importance_path}`",
            "",
            "## Interpretation Rule",
            "",
            "휴리스틱 라벨은 초기 silver label로만 사용한다. 실제 유저 데이터가 충분해지면 target과 metric을 다시 정의한다.",
            "",
            "## Recommendation Boundary",
            "",
            "Current valid use:",
            "",
            "- Rank which simulation factors are associated with clear-rate changes.",
            "- Identify candidate regions for follow-up probes.",
            "- Verify that the project has enough structured summary data to start designing a real ML transition.",
            "",
            "Current invalid use:",
            "",
            "- Automatically changing runtime target score.",
            "- Automatically changing boss cycle/severity.",
            "- Automatically changing market candidate weights.",
            "- Treating this as player-behavior modeling.",
            "- Claiming that balance is already ML-driven.",
            "",
            "## Next ML Step",
            "",
            "Actual ML transition has not happened yet. The next model must add pre-outcome candidate features so it can recommend interventions rather than only explain outcomes:",
            "",
            "- target multiplier candidate",
            "- boss modifier category and severity",
            "- market candidate availability/weight profile",
            "- reward scale and price scale",
            "- reroll lane spend and final gold features after the recent reroll split",
            "",
            "Then run a candidate loop:",
            "",
            "1. Model ranks candidate settings offline.",
            "2. Simulator runs the top candidates.",
            "3. Human review checks policy constraints and playfeel.",
            "4. Only approved candidates are applied to runtime data/code.",
            "",
        ],
    )


def build_preoutcome_report(
    *,
    feature_path: Path,
    metrics: dict[str, Any],
    importance_path: Path,
    metrics_path: Path,
    source_lines: list[str],
    top_importance_lines: list[str],
    numeric_features: list[str],
    categorical_features: list[str],
) -> str:
    return "\n".join(
        [
            "# Leveling Pre-Outcome Transition Scaffold Report",
            "",
            "## Scope",
            "",
            "이 리포트는 planned ML transition scaffold다.",
            "기존 outcome-derived summary feature를 제거하고, 시뮬레이션 실행 전에 알 수 있는 조건만 feature로 사용해 `clear_rate`를 예측한다.",
            "모델은 후보 추천 루프를 설계하기 위한 오프라인 분석 도구이며, production ML이 아니고 런타임 target, boss, market, economy 값을 자동 변경하지 않는다.",
            "이 산출물만으로 실제 ML 이행 완료를 주장하지 않는다. 후보 재시뮬레이션과 사람 승인 보고서가 별도로 필요하다.",
            "",
            "## Dataset",
            "",
            f"- feature table: `{feature_path}`",
            f"- rows: {metrics['row_count']}",
            f"- train rows: {metrics['train_count']}",
            f"- test rows: {metrics['test_count']}",
            f"- target: `{metrics['target']}`",
            f"- feature mode: `{metrics['feature_mode']}`",
            "",
            "Source summaries:",
            "",
            *source_lines,
            "",
            "## Feature And Target Definition",
            "",
            "Target:",
            "",
            f"- `{metrics['target']}`: aggregated simulation group clear share.",
            "",
            "Pre-outcome numeric features:",
            "",
            *[f"- `{feature}`" for feature in numeric_features],
            "",
            "Pre-outcome categorical features:",
            "",
            *[f"- `{feature}`" for feature in categorical_features],
            "",
            "Excluded from model features:",
            "",
            "- `avg_score_ratio`",
            "- `avg_turn_count`",
            "- `avg_confirm_action_count`",
            "- `avg_max_single_confirm_score`",
            "- `avg_remaining_deck`",
            "- `avg_remaining_board_discards`",
            "- `avg_remaining_hand_discards`",
            "- `avg_remaining_board_moves`",
            "- `slow_clear_share_of_clears`",
            "- `run_count`",
            "",
            "These excluded fields are outcomes or sample-size metadata, so they cannot be used for candidate recommendation before a simulation is run.",
            "",
            "## Model",
            "",
            "Model type: `RandomForestRegressor`.",
            "",
            "Reason:",
            "",
            "- It is a simple baseline for mixed numeric/categorical simulation settings.",
            "- It can capture non-linear station, tier, market, boss, and modifier interactions.",
            "- Feature importance is inspectable enough for a first human review.",
            "",
            "## Metric",
            "",
            f"- MAE: {metrics['mae']:.4f}",
            f"- R2: {metrics['r2']:.4f}",
            "",
            "Interpretation:",
            "",
            "- This score is expected to be weaker than the previous outcome-summary scaffold because it cannot peek at post-run results.",
            "- Useful signal here means candidate settings have enough structure for a first recommendation loop.",
            "- Poor signal means more candidate diversity or raw run-level data is needed before relying on model ranking.",
            "",
            "## Feature Importance Snapshot",
            "",
            *top_importance_lines,
            "",
            "## Artifacts",
            "",
            f"- metrics JSON: `{metrics_path}`",
            f"- feature importance CSV: `{importance_path}`",
            "",
            "## Recommendation Boundary",
            "",
            "Allowed next use:",
            "",
            "- rank candidate settings for follow-up simulation",
            "- identify which pre-run settings explain clear-rate variance",
            "- choose small candidate probes for human review",
            "",
            "Not allowed:",
            "",
            "- runtime auto-balancing",
            "- direct target/boss/market/economy patch without resimulation",
            "- treating this as player telemetry modeling",
            "",
        ],
    )


def read_top_importances(path: Path, *, limit: int) -> list[tuple[str, float]]:
    rows: list[tuple[str, float]] = []
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            try:
                rows.append((row["feature"], float(row["importance"])))
            except (KeyError, ValueError):
                continue
            if len(rows) >= limit:
                break
    return rows


def read_feature_source_paths(feature_path: Path) -> list[str]:
    metadata_path = feature_path.with_suffix(".metadata.json")
    if not metadata_path.exists():
        return []
    try:
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return []
    source_paths = metadata.get("source_paths")
    if not isinstance(source_paths, list):
        return []
    return [str(path) for path in source_paths]


if __name__ == "__main__":
    raise SystemExit(main())
