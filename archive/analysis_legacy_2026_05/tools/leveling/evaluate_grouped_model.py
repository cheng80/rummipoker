#!/usr/bin/env python3
"""source_path 단위 holdout으로 레벨링 모델 누수 위험을 점검한다."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from feature_table_autogen import ensure_feature_table
from train_leveling_model import (
    PREOUTCOME_CATEGORICAL_FEATURES,
    PREOUTCOME_NUMERIC_FEATURES,
)


DEFAULT_STATION_FEATURES = ".omo/legacy_leveling/generated/features/leveling_preoutcome_feature_table.csv"
DEFAULT_SEQUENCE_FEATURES = ".omo/legacy_leveling/generated/features/leveling_preoutcome_sequence_feature_table.csv"
DEFAULT_OUT = ".omo/legacy_leveling/reports/preoutcome_grouped_validation_report.md"
DEFAULT_JSON = ".omo/legacy_leveling/models/preoutcome_grouped_validation_metrics.json"

SEQUENCE_NUMERIC_FEATURES = [
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
    "is_shop_slot_market",
    "is_sim_policy_market",
    "market_availability_index",
]


def main() -> int:
    parser = argparse.ArgumentParser(
        description="source_path 기준 group split으로 pre-outcome 모델을 검증합니다.",
    )
    parser.add_argument("--station-features", default=DEFAULT_STATION_FEATURES)
    parser.add_argument("--sequence-features", default=DEFAULT_SEQUENCE_FEATURES)
    parser.add_argument("--out", default=DEFAULT_OUT)
    parser.add_argument("--json-out", default=DEFAULT_JSON)
    parser.add_argument("--splits", type=int, default=5)
    parser.add_argument("--test-size", type=float, default=0.25)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--station-min-run-count", type=int, default=80)
    args = parser.parse_args()

    try:
        import pandas as pd
        from sklearn.compose import ColumnTransformer
        from sklearn.ensemble import RandomForestRegressor
        from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
        from sklearn.model_selection import GroupShuffleSplit
        from sklearn.pipeline import Pipeline
        from sklearn.preprocessing import OneHotEncoder
    except ImportError as error:
        raise SystemExit(
            "필요한 패키지가 없습니다. pandas와 scikit-learn 설치 후 다시 실행하세요: "
            f"{error}",
        ) from error

    station = evaluate(
        pd=pd,
        group_split_cls=GroupShuffleSplit,
        column_transformer_cls=ColumnTransformer,
        random_forest_cls=RandomForestRegressor,
        pipeline_cls=Pipeline,
        one_hot_encoder_cls=OneHotEncoder,
        mean_absolute_error=mean_absolute_error,
        mean_squared_error=mean_squared_error,
        r2_score=r2_score,
        feature_path=Path(args.station_features),
        feature_mode="preoutcome",
        target="clear_rate_smoothed",
        numeric_features=PREOUTCOME_NUMERIC_FEATURES,
        categorical_features=PREOUTCOME_CATEGORICAL_FEATURES,
        min_run_count=args.station_min_run_count,
        splits=args.splits,
        test_size=args.test_size,
        seed=args.seed,
    )
    sequence = evaluate(
        pd=pd,
        group_split_cls=GroupShuffleSplit,
        column_transformer_cls=ColumnTransformer,
        random_forest_cls=RandomForestRegressor,
        pipeline_cls=Pipeline,
        one_hot_encoder_cls=OneHotEncoder,
        mean_absolute_error=mean_absolute_error,
        mean_squared_error=mean_squared_error,
        r2_score=r2_score,
        feature_path=Path(args.sequence_features),
        feature_mode="preoutcome_sequence",
        target="path_clear_rate",
        numeric_features=SEQUENCE_NUMERIC_FEATURES,
        categorical_features=PREOUTCOME_CATEGORICAL_FEATURES,
        min_run_count=0,
        splits=args.splits,
        test_size=args.test_size,
        seed=args.seed,
    )

    payload = {"station_tier": station, "sequence_path": sequence}
    json_path = Path(args.json_out)
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    report_path = Path(args.out)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(build_report(station=station, sequence=sequence, json_path=json_path), encoding="utf-8")
    print(f"grouped metrics: {json_path}")
    print(f"report: {report_path}")
    return 0


def evaluate(
    *,
    pd: Any,
    group_split_cls: Any,
    column_transformer_cls: Any,
    random_forest_cls: Any,
    pipeline_cls: Any,
    one_hot_encoder_cls: Any,
    mean_absolute_error: Any,
    mean_squared_error: Any,
    r2_score: Any,
    feature_path: Path,
    feature_mode: str,
    target: str,
    numeric_features: list[str],
    categorical_features: list[str],
    min_run_count: int,
    splits: int,
    test_size: float,
    seed: int,
) -> dict[str, Any]:
    ensure_feature_table(feature_path, feature_mode=feature_mode)
    df = pd.read_csv(feature_path, low_memory=False)
    before_filter = len(df)
    if min_run_count > 0:
        df = df[df["run_count"].fillna(0).astype(float) >= min_run_count].reset_index(drop=True)

    features = [key for key in [*numeric_features, *categorical_features] if key in df.columns]
    nums = [key for key in numeric_features if key in features]
    cats = [key for key in categorical_features if key in features]
    x = df[features].copy()
    for key in nums:
        x[key] = x[key].fillna(0)
    for key in cats:
        x[key] = x[key].fillna("")
    y = df[target].astype(float)
    groups = df["source_path"].fillna("")

    splitter = group_split_cls(n_splits=splits, test_size=test_size, random_state=seed)
    rows = []
    for index, (train_index, test_index) in enumerate(splitter.split(x, y, groups), start=1):
        model = pipeline_cls(
            steps=[
                (
                    "preprocessor",
                    column_transformer_cls(
                        transformers=[
                            ("num", "passthrough", nums),
                            ("cat", one_hot_encoder_cls(handle_unknown="ignore"), cats),
                        ],
                    ),
                ),
                (
                    "model",
                    random_forest_cls(
                        n_estimators=120,
                        min_samples_leaf=2,
                        n_jobs=2,
                        random_state=seed + index,
                    ),
                ),
            ],
        )
        model.fit(x.iloc[train_index], y.iloc[train_index])
        prediction = model.predict(x.iloc[test_index])
        rows.append(
            {
                "split": index,
                "mae": float(mean_absolute_error(y.iloc[test_index], prediction)),
                "rmse": float(mean_squared_error(y.iloc[test_index], prediction) ** 0.5),
                "r2": float(r2_score(y.iloc[test_index], prediction)),
                "train_rows": int(len(train_index)),
                "test_rows": int(len(test_index)),
                "train_groups": int(groups.iloc[train_index].nunique()),
                "test_groups": int(groups.iloc[test_index].nunique()),
            },
        )

    return {
        "feature_path": str(feature_path),
        "feature_mode": feature_mode,
        "target": target,
        "row_count": int(len(df)),
        "before_filter_row_count": int(before_filter),
        "min_run_count": int(min_run_count),
        "source_group_count": int(groups.nunique()),
        "split_strategy": "source_path_group_shuffle",
        "splits": rows,
        "avg_mae": average(row["mae"] for row in rows),
        "avg_rmse": average(row["rmse"] for row in rows),
        "avg_r2": average(row["r2"] for row in rows),
    }


def average(values: Any) -> float:
    values = list(values)
    return float(sum(values) / len(values)) if values else 0.0


def build_report(*, station: dict[str, Any], sequence: dict[str, Any], json_path: Path) -> str:
    return "\n".join(
        [
            "# Pre-Outcome Grouped Validation Report",
            "",
            "## 최종 결론 요약",
            "",
            "- 결론: random row split만 보면 과적합/데이터 누수를 과소평가할 수 있다. source_path 단위로 실험 파일을 통째로 가리면 station/tier 점수는 크게 낮아진다.",
            f"- station/tier source split: MAE {station['avg_mae']:.4f}, RMSE {station['avg_rmse']:.4f}, R2 {station['avg_r2']:.4f}.",
            f"- sequence/path source split: MAE {sequence['avg_mae']:.4f}, RMSE {sequence['avg_rmse']:.4f}, R2 {sequence['avg_r2']:.4f}.",
            "- 사용 가능: sequence/path는 후보 선별 보조 신호로 유지한다.",
            "- 사용 주의: station/tier는 구간 위험 힌트로만 보고, 단독 추천 gate로 쓰지 않는다.",
            "- 다음 액션: 향후 ML gate 문구와 문서는 source split 점수를 함께 표기한다.",
            "",
            "## 핵심 지표",
            "",
            "| 모델 | MAE | RMSE | R2 | Row | Source groups | 판단 |",
            "|---|---:|---:|---:|---:|---:|---|",
            f"| station/tier | {station['avg_mae']:.4f} | {station['avg_rmse']:.4f} | {station['avg_r2']:.4f} | {station['row_count']} | {station['source_group_count']} | 구간 힌트 전용 |",
            f"| sequence/path | {sequence['avg_mae']:.4f} | {sequence['avg_rmse']:.4f} | {sequence['avg_r2']:.4f} | {sequence['row_count']} | {sequence['source_group_count']} | 후보 선별 보조 신호 |",
            "",
            "## 산출물",
            "",
            f"- JSON metrics: `{json_path}`",
            "",
        ],
    )


if __name__ == "__main__":
    raise SystemExit(main())
