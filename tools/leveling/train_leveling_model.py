#!/usr/bin/env python3
"""레벨링 feature table로 오프라인 추천 모델의 1차 metric을 만든다."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any


DEFAULT_FEATURES = "analysis/leveling/data/features/leveling_feature_table.csv"
DEFAULT_REPORT = "analysis/leveling/reports/model_recommendation_report.md"
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


def main() -> int:
    parser = argparse.ArgumentParser(
        description="레벨링 feature table로 RandomForest 회귀 모델을 학습하고 MD 리포트를 만듭니다.",
    )
    parser.add_argument("--features", default=DEFAULT_FEATURES, help="feature table CSV")
    parser.add_argument("--target", default="clear_rate", help="예측 target 컬럼")
    parser.add_argument("--report-out", default=DEFAULT_REPORT, help="MD 리포트 출력 경로")
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

    feature_path = Path(args.features)
    if not feature_path.exists():
        raise SystemExit(f"feature table이 없습니다: {feature_path}")

    df = pd.read_csv(feature_path)
    if args.target not in df.columns:
        raise SystemExit(f"target 컬럼이 없습니다: {args.target}")
    if len(df) < 8:
        raise SystemExit("학습에는 최소 8개 이상의 group row가 필요합니다.")

    features = [key for key in [*NUMERIC_FEATURES, *CATEGORICAL_FEATURES] if key in df.columns]
    numeric_features = [key for key in NUMERIC_FEATURES if key in features]
    categorical_features = [key for key in CATEGORICAL_FEATURES if key in features]

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
        "mae": float(mean_absolute_error(y_test, predictions)),
        "r2": float(r2_score(y_test, predictions)) if len(y_test) > 1 else 0.0,
    }

    model_dir = Path(args.model_dir)
    model_dir.mkdir(parents=True, exist_ok=True)
    importance_path = model_dir / f"{args.target}_feature_importance.csv"
    write_feature_importance(pipeline, numeric_features, categorical_features, importance_path)
    metrics_path = model_dir / f"{args.target}_metrics.json"
    metrics_path.write_text(json.dumps(metrics, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    report_path = Path(args.report_out)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(
        build_report(
            feature_path=feature_path,
            metrics=metrics,
            importance_path=importance_path,
            metrics_path=metrics_path,
            source_paths=read_feature_source_paths(feature_path),
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
        writer = csv.writer(handle)
        writer.writerow(["feature", "importance"])
        writer.writerows(rows)


def build_report(
    *,
    feature_path: Path,
    metrics: dict[str, Any],
    importance_path: Path,
    metrics_path: Path,
    source_paths: list[str],
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
    return "\n".join(
        [
            "# Leveling Model Recommendation Report",
            "",
            "## Scope",
            "",
            "이 리포트는 오프라인 분석 모델 결과다. 런타임 밸런스를 자동으로 바꾸지 않는다.",
            "모델 추천은 후보 생성 근거이며, 후보는 반드시 재시뮬레이션과 사람 승인을 거쳐야 한다.",
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
            "- Feature importance is easy to inspect for a first transition report.",
            "",
            "This model is intentionally offline-only. It does not patch runtime target scores, boss modifiers, market weights, or economy constants.",
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
            "- This is not evidence that the game is fully balanced. It is evidence that the simulation summary features are predictive enough to support offline candidate ranking.",
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
            "- Support report evidence that the project has moved beyond pure rules-only analysis into an offline supervised modeling step.",
            "",
            "Current invalid use:",
            "",
            "- Automatically changing runtime target score.",
            "- Automatically changing boss cycle/severity.",
            "- Automatically changing market candidate weights.",
            "- Treating this as player-behavior modeling.",
            "",
            "## Next ML Step",
            "",
            "The next model should add pre-outcome candidate features so it can recommend interventions rather than only explain outcomes:",
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
