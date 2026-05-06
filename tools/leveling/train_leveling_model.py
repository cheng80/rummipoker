#!/usr/bin/env python3
"""레벨링 feature table로 ML 전환 스캐폴딩 metric을 만든다."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any

from feature_table_autogen import ensure_feature_table


DEFAULT_FEATURES = "analysis/leveling/generated/features/leveling_feature_table.csv"
DEFAULT_PREOUTCOME_FEATURES = "analysis/leveling/generated/features/leveling_preoutcome_feature_table.csv"
DEFAULT_PREOUTCOME_SEQUENCE_FEATURES = "analysis/leveling/generated/features/leveling_preoutcome_sequence_feature_table.csv"
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
    "station_tier_index",
    "tier_index",
    "station_band_index",
    "is_boss_tier",
    "is_late_station",
    "is_final_station",
    "expected_target_score",
    "expected_reward_gold",
    "board_discard_pressure",
    "hand_discard_pressure",
    "max_hand_size_pressure",
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
    "has_boss_constraint",
    "boss_family_index",
    "boss_level_index",
    "boss_pressure_index",
    "is_runtime_boss_modifier",
    "economy_pressure_index",
    "station_boss_interaction",
    "station_pressure_interaction",
    "market_station_interaction",
    "economy_market_interaction",
    "price_band_growth_access",
    "price_band_catalog_normalized",
    "spend_mode_slot_sell",
    "spend_mode_first_reroll_free",
    "spend_mode_reroll_slot_sell_soft",
    "spend_mode_reroll_slot_sell",
    "choice_mode_affordable_alternative",
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
    parser.add_argument(
        "--model-strategy",
        choices=["baseline", "auto"],
        default="auto",
        help="baseline은 기존 RandomForest 단일 모델, auto는 여러 tree 모델/하이퍼파라미터를 비교합니다.",
    )
    parser.add_argument(
        "--max-rows",
        type=int,
        default=60000,
        help="학습 비용 상한을 위해 사용할 최대 row 수. 0 이하면 전체 row를 사용합니다.",
    )
    parser.add_argument(
        "--min-run-count",
        type=int,
        default=0,
        help="preoutcome station/tier 학습에서 이 run_count 미만 row를 제외합니다.",
    )
    args = parser.parse_args()

    try:
        import pandas as pd
        from sklearn.compose import ColumnTransformer
        from sklearn.ensemble import ExtraTreesRegressor, RandomForestRegressor
        from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
        from sklearn.model_selection import GridSearchCV, KFold, train_test_split
        from sklearn.pipeline import Pipeline
        from sklearn.preprocessing import OneHotEncoder
    except ImportError as error:
        raise SystemExit(
            "필요한 패키지가 없습니다. pandas와 scikit-learn 설치 후 다시 실행하세요: "
            f"{error}",
        ) from error

    if args.feature_mode == "preoutcome":
        default_features = DEFAULT_PREOUTCOME_FEATURES
    elif args.feature_mode == "preoutcome_sequence":
        default_features = DEFAULT_PREOUTCOME_SEQUENCE_FEATURES
    else:
        default_features = DEFAULT_FEATURES
    feature_path = Path(args.features or default_features)
    ensure_feature_table(feature_path, feature_mode=args.feature_mode)

    df = pd.read_csv(feature_path, low_memory=False)
    if args.target not in df.columns:
        raise SystemExit(f"target 컬럼이 없습니다: {args.target}")
    if len(df) < 8:
        raise SystemExit("학습에는 최소 8개 이상의 group row가 필요합니다.")
    original_row_count = read_feature_source_row_count(feature_path) or len(df)
    before_filter_row_count = len(df)
    if args.feature_mode == "preoutcome" and args.min_run_count > 0:
        if "run_count" not in df.columns:
            raise SystemExit("--min-run-count를 쓰려면 run_count 컬럼이 필요합니다.")
        df = df[df["run_count"].fillna(0).astype(float) >= args.min_run_count].reset_index(drop=True)
        if len(df) < 8:
            raise SystemExit("min-run-count 적용 후 학습 row가 너무 적습니다.")
    if args.max_rows > 0 and len(df) > args.max_rows:
        df = df.sample(n=args.max_rows, random_state=args.seed).reset_index(drop=True)

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
            "is_shop_slot_market",
            "is_sim_policy_market",
            "market_availability_index",
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
    for key in numeric_features:
        x[key] = x[key].fillna(0)
    for key in categorical_features:
        x[key] = x[key].fillna("")
    y = df[args.target].astype(float)
    sample_weight = None
    if args.feature_mode == "preoutcome" and "run_count" in df.columns:
        sample_weight = df["run_count"].fillna(1).clip(lower=1).astype(float)

    if sample_weight is None:
        x_train, x_test, y_train, y_test = train_test_split(
            x,
            y,
            test_size=args.test_size,
            random_state=args.seed,
        )
        train_weight = None
    else:
        x_train, x_test, y_train, y_test, train_weight, _ = train_test_split(
            x,
            y,
            sample_weight,
            test_size=args.test_size,
            random_state=args.seed,
        )

    pipeline, model_selection = build_pipeline(
        numeric_features=numeric_features,
        categorical_features=categorical_features,
        strategy=args.model_strategy,
        seed=args.seed,
        row_count=len(df),
        random_forest_cls=RandomForestRegressor,
        extra_trees_cls=ExtraTreesRegressor,
        grid_search_cls=GridSearchCV,
        kfold_cls=KFold,
    )
    fit_params = {"model__sample_weight": train_weight} if train_weight is not None else {}
    pipeline.fit(x_train, y_train, **fit_params)
    if hasattr(pipeline, "best_params_"):
        model_selection["best_params"] = serializable_best_params(pipeline.best_params_)
        model_selection["best_cv_score"] = float(pipeline.best_score_)
        best_model = pipeline.best_estimator_.named_steps["model"]
        model_selection["selected_model"] = type(best_model).__name__
    predictions = pipeline.predict(x_test)
    mse = mean_squared_error(y_test, predictions)

    metrics = {
        "row_count": int(len(df)),
        "source_row_count": int(original_row_count),
        "before_filter_row_count": int(before_filter_row_count),
        "min_run_count": int(args.min_run_count),
        "train_count": int(len(x_train)),
        "test_count": int(len(x_test)),
        "target": args.target,
        "feature_mode": args.feature_mode,
        "model_strategy": args.model_strategy,
        "uses_run_count_sample_weight": bool(sample_weight is not None),
        "model_selection": model_selection,
        "mae": float(mean_absolute_error(y_test, predictions)),
        "rmse": float(mse ** 0.5),
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


def build_pipeline(
    *,
    numeric_features: list[str],
    categorical_features: list[str],
    strategy: str,
    seed: int,
    row_count: int,
    random_forest_cls: Any,
    extra_trees_cls: Any,
    grid_search_cls: Any,
    kfold_cls: Any,
) -> tuple[Any, dict[str, Any]]:
    from sklearn.compose import ColumnTransformer
    from sklearn.pipeline import Pipeline
    from sklearn.preprocessing import OneHotEncoder

    preprocessor = ColumnTransformer(
        transformers=[
            ("num", "passthrough", numeric_features),
            ("cat", OneHotEncoder(handle_unknown="ignore"), categorical_features),
        ],
    )
    baseline_model = random_forest_cls(
        n_estimators=160 if row_count > 50000 else 300,
        min_samples_leaf=2,
        n_jobs=2,
        random_state=seed,
    )
    baseline_pipeline = Pipeline(
        steps=[
            ("preprocessor", preprocessor),
            ("model", baseline_model),
        ],
    )
    if strategy == "baseline" or row_count < 40:
        return baseline_pipeline, {
            "strategy": "baseline",
            "selected_model": "RandomForestRegressor",
            "note": "row_count가 작거나 baseline 전략을 선택해 단일 모델을 사용했습니다.",
        }

    candidate_pipeline = Pipeline(
        steps=[
            ("preprocessor", preprocessor),
            ("model", baseline_model),
        ],
    )
    n_estimators = [240] if row_count > 50000 else [300, 600]
    min_samples_leaf = [2, 4] if row_count > 50000 else [1, 2, 4]
    max_features = ["sqrt"] if row_count > 50000 else ["sqrt", 1.0]
    param_grid = [
        {
            "model": [random_forest_cls(n_jobs=2, random_state=seed)],
            "model__n_estimators": n_estimators,
            "model__min_samples_leaf": min_samples_leaf,
            "model__max_features": max_features,
        },
        {
            "model": [extra_trees_cls(n_jobs=2, random_state=seed)],
            "model__n_estimators": n_estimators,
            "model__min_samples_leaf": min_samples_leaf,
            "model__max_features": max_features,
        },
    ]
    cv_splits = min(5, max(3, row_count // 200))
    search = grid_search_cls(
        estimator=candidate_pipeline,
        param_grid=param_grid,
        scoring="neg_root_mean_squared_error",
        cv=kfold_cls(n_splits=cv_splits, shuffle=True, random_state=seed),
        n_jobs=2,
    )
    return search, {
        "strategy": "auto",
        "cv_splits": cv_splits,
        "scoring": "neg_root_mean_squared_error",
        "candidate_models": ["RandomForestRegressor", "ExtraTreesRegressor"],
    }


def selected_model_name(metrics: dict[str, Any]) -> str:
    selection = metrics.get("model_selection")
    if not isinstance(selection, dict):
        return "RandomForestRegressor"
    selected = selection.get("selected_model")
    if isinstance(selected, str):
        return selected
    best_params = selection.get("best_params")
    if isinstance(best_params, dict):
        model = best_params.get("model")
        if model is not None:
            return type(model).__name__
    return "auto-selected tree regressor"


def serializable_best_params(params: dict[str, Any]) -> dict[str, Any]:
    sanitized: dict[str, Any] = {}
    for key, value in params.items():
        if key == "model":
            sanitized[key] = type(value).__name__
        else:
            sanitized[key] = value
    return sanitized


def write_feature_importance(
    pipeline: Any,
    numeric_features: list[str],
    categorical_features: list[str],
    out_path: Path,
) -> None:
    if hasattr(pipeline, "best_estimator_"):
        pipeline = pipeline.best_estimator_
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
        "| Feature | 중요도 |",
        "|---|---:|",
        *[
            f"| `{feature}` | {importance:.4f} |"
            for feature, importance in top_importances
        ],
    ]
    if feature_mode in {"preoutcome", "preoutcome_sequence"}:
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
            "# 레벨링 ML 전환 스캐폴드 리포트",
            "",
            "## 최종 결론 요약",
            "",
            "- 결론: 현재 모델은 설명용 scaffold이며 ML 마감 또는 추천 gate 완료 근거가 아니다.",
            f"- 핵심 점수: MAE {metrics['mae']:.4f}, RMSE {metrics['rmse']:.4f}, R2 {metrics['r2']:.4f}.",
            f"- 데이터: {metrics['row_count']} rows, train {metrics['train_count']}, test {metrics['test_count']}, target `{metrics['target']}`.",
            "- 사용 가능: 후속 probe 후보 영역 탐색과 feature sanity check.",
            "- 사용 금지: runtime 자동 변경, production ML 주장, 사람 승인 없는 target/boss/market/economy 적용.",
            "- NotebookLM 상태: 지표가 사용 수준이 아니므로 보고서/인포그래픽 재생성 source로 쓰기 전 단계.",
            "- 다음 액션: pre-outcome candidate grid와 run-level 데이터를 늘리고 MAE/RMSE/R2를 재평가한다.",
            "",
            "## 핵심 점수",
            "",
            "| 항목 | 현재값 | 이상값/최선 | 실무 사용 기준 | 판단 |",
            "|---|---:|---:|---|---|",
            f"| MAE | {metrics['mae']:.4f} | 0.0000 | target 0~1 기준 충분히 낮아야 함, 프로젝트 임계값 미정 | 기준 정의와 개선 필요 |",
            f"| RMSE | {metrics['rmse']:.4f} | 0.0000 | target 0~1 기준 큰 오차가 충분히 낮아야 함, 프로젝트 임계값 미정 | 기준 정의와 개선 필요 |",
            f"| R2 | {metrics['r2']:.4f} | 1.0000 | 실무 추천용은 높은 설명력이 필요, 프로젝트 임계값 미정 | 실무 추천 기준에는 부족 |",
            f"| Row | {metrics['row_count']} | 많을수록 좋음 | 후보 grid와 run-level 다양성이 충분해야 함 | 데이터 규모 확인용 |",
            "",
            "## 범위",
            "",
            "이 리포트는 실제 ML 전환 완료 보고서가 아니다.",
            "현재 모델은 outcome-derived summary feature로 `clear_rate`를 설명하는 baseline이며, target score, boss severity, market weight, economy scale 후보를 추천하지 않는다.",
            "런타임 밸런스를 자동으로 바꾸지 않으며, 현재 산출물을 ML 기반 밸런스 자동 조정 근거로 사용하지 않는다.",
            "",
            "## 데이터셋",
            "",
            f"- feature table: `{feature_path}`",
            f"- rows: {metrics['row_count']}",
            f"- rows before filter: {metrics.get('before_filter_row_count', metrics['row_count'])}",
            f"- min run count: {metrics.get('min_run_count', 0)}",
            f"- train rows: {metrics['train_count']}",
            f"- test rows: {metrics['test_count']}",
            f"- target: `{metrics['target']}`",
            "",
            "소스 summary:",
            "",
            *source_lines,
            "",
            "각 row는 experiment, loadout, blind tier, difficulty, market profile, run modifier, station, outcome summary 값으로 집계한 시뮬레이션 그룹이다. 현재 데이터셋은 시뮬레이션 기반이며 실제 플레이어 telemetry가 아니다.",
            "",
            "## 피처와 타깃 정의",
            "",
            "Target:",
            "",
            f"- `{metrics['target']}`: 집계된 시뮬레이션 그룹의 clear 비율.",
            "",
            "Numeric features:",
            "",
            *[f"- `{feature}`" for feature in NUMERIC_FEATURES],
            "",
            "Categorical features:",
            "",
            *[f"- `{feature}`" for feature in CATEGORICAL_FEATURES],
            "",
            "Silver-label 컬럼은 분석 맥락으로 feature table에 보존하지만, 이 첫 모델은 휴리스틱 라벨을 학습하지 않고 선택된 target을 직접 예측한다.",
            "",
            "## 모델",
            "",
            f"모델 전략: `{metrics.get('model_strategy', 'baseline')}`.",
            f"선택된 모델: `{selected_model_name(metrics)}`.",
            "",
            "선택 이유:",
            "",
            "- station, blind tier, market profile, resource residual 사이의 비선형 상호작용을 고정된 선형 가정 없이 다룰 수 있다.",
            "- 간단한 전처리 pipeline으로 numeric feature와 one-hot categorical feature를 함께 사용할 수 있다.",
            "- 첫 scaffold report에서 feature importance를 검토하기 쉽다.",
            "",
            "이 모델은 의도적으로 offline-only 설명 모델이다. runtime target score, boss modifier, market weight, economy constant를 직접 패치하지 않는다.",
            "",
            "## 지표",
            "",
            f"- MAE: {metrics['mae']:.4f}",
            f"- RMSE: {metrics['rmse']:.4f}",
            f"- R2: {metrics['r2']:.4f}",
            "",
            "해석:",
            "",
            f"- MAE `{metrics['mae']:.4f}` 수준은 held-out group에서 `{metrics['target']}`를 예측할 때의 평균 오차다.",
            f"- RMSE `{metrics['rmse']:.4f}` 수준은 큰 오차에 더 민감한 회귀 오차다.",
            f"- R2 `{metrics['r2']:.4f}` 수준은 값이 높을수록 이 시뮬레이션 데이터셋의 held-out variance를 더 많이 설명한다는 뜻이다.",
            "- 이것은 게임 밸런스가 완전히 닫혔다는 근거가 아니다.",
            "- 이것은 ML 전환이 완료됐다는 근거도 아니다.",
            "- 현재 summary row를 supervised modeling scaffold에 올릴 수 있고, outcome-derived feature가 clear-rate variance를 설명할 수 있음을 보여줄 뿐이다.",
            "",
            "## 피처 중요도 스냅샷",
            "",
            *top_importance_lines,
            "",
            "읽는 법:",
            "",
            "- outcome-derived feature가 지배적이면 이 모델은 처방형보다 설명형에 가깝다.",
            "- 이후 추천 모델은 outcome 설명을 넘어서 개입안을 추천할 수 있도록 전투 전 configuration feature를 추가해야 한다.",
            "",
            "## 산출물",
            "",
            f"- metrics JSON: `{metrics_path}`",
            f"- feature importance CSV: `{importance_path}`",
            "",
            "## 해석 규칙",
            "",
            "휴리스틱 라벨은 초기 silver label로만 사용한다. 실제 유저 데이터가 충분해지면 target과 metric을 다시 정의한다.",
            "",
            "## 추천 경계",
            "",
            "현재 허용되는 사용:",
            "",
            "- clear-rate 변화와 관련 있는 시뮬레이션 factor의 우선순위를 본다.",
            "- 후속 probe를 돌릴 후보 영역을 찾는다.",
            "- 실제 ML 전환 설계를 시작할 만큼 구조화된 summary data가 있는지 확인한다.",
            "",
            "현재 금지되는 사용:",
            "",
            "- runtime target score 자동 변경.",
            "- boss cycle/severity 자동 변경.",
            "- market candidate weight 자동 변경.",
            "- 플레이어 행동 모델링으로 해석.",
            "- 이미 ML 기반 밸런스라고 주장.",
            "- ML 마감 또는 추천 gate 완료 근거로 사용.",
            "",
            "## 다음 ML 단계",
            "",
            "실제 ML 전환은 아직 완료되지 않았다. 다음 모델은 outcome 설명을 넘어 개입안을 추천할 수 있도록 pre-outcome candidate feature를 추가해야 한다.",
            "",
            "- target multiplier candidate",
            "- boss modifier category and severity",
            "- market candidate availability/weight profile",
            "- reward scale and price scale",
            "- reroll lane spend and final gold features after the recent reroll split",
            "",
            "그 다음 후보 loop를 실행한다.",
            "",
            "1. 모델이 offline에서 candidate setting 순위를 매긴다.",
            "2. 시뮬레이터가 상위 후보를 실행한다.",
            "3. 사람 검토로 정책 제약과 playfeel을 확인한다.",
            "4. 승인된 후보만 runtime data/code에 적용한다.",
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
    is_sequence = metrics.get("feature_mode") == "preoutcome_sequence"
    title = (
        "# 레벨링 Pre-Outcome Sequence 전환 스캐폴드 리포트"
        if is_sequence
        else "# 레벨링 Pre-Outcome 전환 스캐폴드 리포트"
    )
    scope_subject = (
        "S1~S8 path 실행 전에 알 수 있는 조건만 feature로 사용해 "
        f"`{metrics['target']}`를 예측한다."
        if is_sequence
        else "시뮬레이션 실행 전에 알 수 있는 조건만 feature로 사용해 "
        f"`{metrics['target']}`를 예측한다."
    )
    if is_sequence and metrics["r2"] >= 0.9:
        conclusion = "현재 모델은 전체 경로 후보를 고르는 내부 추천 신호로 사용 가능하다. 단, 런타임 자동 적용 근거는 아니다."
        usable = "S1~S8 전체 경로 후보 선별, fresh resimulation 우선순위 정리."
        notebook = "NotebookLM source로 재가공 가능하나, 외부 발표용 재생성은 문서 동기화 후 진행한다."
        next_action = "fresh gate와 ML gate가 함께 맞는 후보를 runtime/economy handoff 문서에 연결한다."
        r2_judgment = "경로 후보 선별용으로 사용 가능"
    elif not is_sequence and metrics["r2"] >= 0.88:
        conclusion = "현재 모델은 station/tier 위험 구간을 보는 내부 진단 신호로 사용 가능하다. 단, 후보 최종 적용은 전체 경로 모델과 fresh simulation을 따른다."
        usable = "어느 station/tier가 위험한지 보는 병목 진단, feature sanity check."
        notebook = "NotebookLM source로 재가공 가능하나, 외부 발표용 재생성은 문서 동기화 후 진행한다."
        next_action = "전체 경로 추천표와 r400 이상 fresh 결과를 함께 보고 적용 후보를 정리한다."
        r2_judgment = "구간 위험 진단용으로 사용 가능"
    else:
        conclusion = "현재 모델은 pre-outcome 후보 추천 scaffold이며 ML 마감 또는 추천 gate 완료 근거가 아니다."
        usable = "후속 시뮬레이션 후보를 고르는 참고 신호와 feature sanity check."
        notebook = "지표가 사용 수준이 아니므로 보고서/인포그래픽 재생성 source로 쓰기 전 단계."
        next_action = "boss/market/economy candidate grid와 raw run-level 데이터를 늘리고 MAE/RMSE/R2를 재평가한다."
        r2_judgment = (
            "path triage 신호로 유망하나 단독 gate로는 부족"
            if is_sequence and metrics["r2"] >= 0.9
            else "실무 추천 기준에는 부족"
        )
    return "\n".join(
        [
            title,
            "",
            "## 최종 결론 요약",
            "",
            f"- 결론: {conclusion}",
            f"- 핵심 점수: MAE {metrics['mae']:.4f}, RMSE {metrics['rmse']:.4f}, R2 {metrics['r2']:.4f}.",
            f"- 데이터: {metrics['row_count']} rows, train {metrics['train_count']}, test {metrics['test_count']}, target `{metrics['target']}`.",
            f"- 사용 가능: {usable}",
            "- 사용 금지: runtime 자동 밸런싱, production ML 주장, 사람 승인 없는 target/boss/market/economy 적용.",
            f"- NotebookLM 상태: {notebook}",
            f"- 다음 액션: {next_action}",
            "",
            "## 핵심 점수",
            "",
            "| 항목 | 현재값 | 이상값/최선 | 실무 사용 기준 | 판단 |",
            "|---|---:|---:|---|---|",
            f"| MAE | {metrics['mae']:.4f} | 0.0000 | target 0~1 기준 충분히 낮아야 함, 프로젝트 임계값 미정 | 기준 정의와 개선 필요 |",
            f"| RMSE | {metrics['rmse']:.4f} | 0.0000 | target 0~1 기준 큰 오차가 충분히 낮아야 함, 프로젝트 임계값 미정 | 기준 정의와 개선 필요 |",
            f"| R2 | {metrics['r2']:.4f} | 1.0000 | 실무 추천용은 높은 설명력이 필요, 프로젝트 임계값 미정 | {r2_judgment} |",
            f"| Row | {metrics['row_count']} | 많을수록 좋음 | 후보 grid와 run-level 다양성이 충분해야 함 | 데이터 규모 확인용 |",
            "",
            "## 범위",
            "",
            "이 리포트는 계획된 ML transition scaffold다.",
            f"기존 outcome-derived summary feature를 제거하고, {scope_subject}",
            "모델은 후보 추천 루프를 설계하기 위한 오프라인 분석 도구이며, production ML이 아니고 런타임 target, boss, market, economy 값을 자동 변경하지 않는다.",
            "이 산출물만으로 production ML 자동 적용 완료를 주장하지 않는다. 후보 재시뮬레이션과 사람 검토 보고서를 함께 본다.",
            "",
            "## 데이터셋",
            "",
            f"- feature table: `{feature_path}`",
            f"- rows: {metrics['row_count']}",
            f"- train rows: {metrics['train_count']}",
            f"- test rows: {metrics['test_count']}",
            f"- target: `{metrics['target']}`",
            f"- feature mode: `{metrics['feature_mode']}`",
            "",
            "소스 summary:",
            "",
            *source_lines,
            "",
            "## 피처와 타깃 정의",
            "",
            "Target:",
            "",
            f"- `{metrics['target']}`: 집계된 시뮬레이션 그룹의 clear 비율.",
            "",
            "Pre-outcome numeric features:",
            "",
            *[f"- `{feature}`" for feature in numeric_features],
            "",
            "Pre-outcome categorical features:",
            "",
            *[f"- `{feature}`" for feature in categorical_features],
            "",
            "모델 feature에서 제외한 항목:",
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
            "",
            "제외된 필드는 outcome 값이므로, 시뮬레이션 실행 전 후보 추천에는 사용할 수 없다.",
            "`run_count`는 후보 조건 feature가 아니라 같은 조건을 몇 번 돌렸는지 나타내는 sample-size metadata이므로, 모델 입력 대신 학습 가중치와 저신뢰 row 필터로만 사용한다.",
            "",
            "## 모델",
            "",
            f"모델 전략: `{metrics.get('model_strategy', 'baseline')}`.",
            f"선택된 모델: `{selected_model_name(metrics)}`.",
            "",
            "선택 이유:",
            "",
            "- numeric/categorical simulation setting이 섞인 데이터를 다루는 단순 baseline으로 적합하다.",
            "- station, tier, market, boss, modifier 사이의 비선형 상호작용을 포착할 수 있다.",
            "- 첫 사람 검토에서 feature importance를 확인하기 쉽다.",
            "",
            "## 지표",
            "",
            f"- MAE: {metrics['mae']:.4f}",
            f"- RMSE: {metrics['rmse']:.4f}",
            f"- R2: {metrics['r2']:.4f}",
            "",
            "해석:",
            "",
            "- post-run result를 볼 수 없으므로 이전 outcome-summary scaffold보다 점수가 약한 것이 자연스럽다.",
            f"- RMSE `{metrics['rmse']:.4f}` 수준은 큰 오차에 더 민감한 회귀 오차다.",
            "- signal이 약하면 모델 ranking에 기대기 전에 candidate 다양성이나 raw run-level data를 늘리고 MAE/RMSE/R2를 함께 재평가해야 한다.",
            "",
            "## 피처 중요도 스냅샷",
            "",
            *top_importance_lines,
            "",
            "## 산출물",
            "",
            f"- metrics JSON: `{metrics_path}`",
            f"- feature importance CSV: `{importance_path}`",
            "",
            "## 추천 경계",
            "",
            "허용되는 다음 사용:",
            "",
            "- 후속 시뮬레이션을 위한 candidate setting 순위화",
            "- clear-rate variance를 설명하는 pre-run setting 식별",
            "- 사람 검토용 작은 candidate probe 선택",
            "",
            "허용되지 않는 사용:",
            "",
            "- runtime 자동 밸런싱",
            "- 재시뮬레이션 없는 target/boss/market/economy 직접 패치",
            "- 플레이어 telemetry modeling으로 해석",
            "- ML 마감 또는 추천 gate 완료 근거로 사용",
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
    metadata = read_feature_metadata(feature_path)
    source_paths = metadata.get("source_paths")
    if not isinstance(source_paths, list):
        return []
    return [str(path) for path in source_paths]


def read_feature_source_row_count(feature_path: Path) -> int | None:
    metadata = read_feature_metadata(feature_path)
    value = metadata.get("source_row_count")
    if isinstance(value, int):
        return value
    return None


def read_feature_metadata(feature_path: Path) -> dict[str, Any]:
    for metadata_path in feature_metadata_candidates(feature_path):
        if not metadata_path.exists():
            continue
        try:
            value = json.loads(metadata_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue
        if isinstance(value, dict):
            return value
    return {}


def feature_metadata_candidates(feature_path: Path) -> list[Path]:
    candidates = [feature_path.with_suffix(".metadata.json")]
    parts = feature_path.parts
    generated_marker = ("analysis", "leveling", "generated", "features")
    if parts[: len(generated_marker)] == generated_marker:
        candidates.append(
            Path("analysis/leveling/data/features")
            / feature_path.with_suffix(".metadata.json").name
        )
    return candidates


if __name__ == "__main__":
    raise SystemExit(main())
