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
        from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
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
    mse = mean_squared_error(y_test, predictions)

    metrics = {
        "row_count": int(len(df)),
        "train_count": int(len(x_train)),
        "test_count": int(len(x_test)),
        "target": args.target,
        "feature_mode": args.feature_mode,
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
        "| Feature | 중요도 |",
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
            "모델 종류: `RandomForestRegressor`.",
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
    return "\n".join(
        [
            "# 레벨링 Pre-Outcome 전환 스캐폴드 리포트",
            "",
            "## 최종 결론 요약",
            "",
            "- 결론: 현재 모델은 pre-outcome 후보 추천 scaffold이며 ML 마감 또는 추천 gate 완료 근거가 아니다.",
            f"- 핵심 점수: MAE {metrics['mae']:.4f}, RMSE {metrics['rmse']:.4f}, R2 {metrics['r2']:.4f}.",
            f"- 데이터: {metrics['row_count']} rows, train {metrics['train_count']}, test {metrics['test_count']}, target `{metrics['target']}`.",
            "- 사용 가능: 후속 시뮬레이션 후보를 고르는 참고 신호와 feature sanity check.",
            "- 사용 금지: runtime 자동 밸런싱, production ML 주장, 사람 승인 없는 target/boss/market/economy 적용.",
            "- NotebookLM 상태: 지표가 사용 수준이 아니므로 보고서/인포그래픽 재생성 source로 쓰기 전 단계.",
            "- 다음 액션: boss/market/economy candidate grid와 raw run-level 데이터를 늘리고 MAE/RMSE/R2를 재평가한다.",
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
            "이 리포트는 계획된 ML transition scaffold다.",
            "기존 outcome-derived summary feature를 제거하고, 시뮬레이션 실행 전에 알 수 있는 조건만 feature로 사용해 `clear_rate`를 예측한다.",
            "모델은 후보 추천 루프를 설계하기 위한 오프라인 분석 도구이며, production ML이 아니고 런타임 target, boss, market, economy 값을 자동 변경하지 않는다.",
            "이 산출물만으로 실제 ML 이행 완료를 주장하지 않는다. 후보 재시뮬레이션과 사람 승인 보고서가 별도로 필요하다.",
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
            "- `run_count`",
            "",
            "제외된 필드는 outcome 또는 sample-size metadata이므로, 시뮬레이션 실행 전 후보 추천에는 사용할 수 없다.",
            "",
            "## 모델",
            "",
            "모델 종류: `RandomForestRegressor`.",
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
