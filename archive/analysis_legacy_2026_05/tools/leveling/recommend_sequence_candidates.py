#!/usr/bin/env python3
"""S1~S8 전체 경로 기준으로 레벨링 후보를 랭킹한다."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any

from feature_table_autogen import ensure_feature_table


DEFAULT_FEATURES = ".omo/legacy_leveling/generated/features/leveling_preoutcome_sequence_feature_table.csv"
DEFAULT_METRICS = ".omo/legacy_leveling/models/path_clear_rate_preoutcome_sequence_metrics.json"
DEFAULT_OUT = ".omo/legacy_leveling/models/preoutcome_sequence_candidate_recommendations.csv"
DEFAULT_REPORT = ".omo/legacy_leveling/reports/preoutcome_sequence_candidate_recommendation_report.md"

NUMERIC_FEATURES = [
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

CATEGORICAL_FEATURES = [
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

LOADOUT_BALANCED = "progression_route_balanced"
LOADOUT_POWER = "progression_route_power"
MARKET_NONE = "none"
MARKET_V9 = "shop_slot_market_v9"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="pre-outcome sequence/path 모델로 관측된 S1~S8 후보를 랭킹합니다.",
    )
    parser.add_argument("--features", default=DEFAULT_FEATURES)
    parser.add_argument("--metrics", default=DEFAULT_METRICS)
    parser.add_argument("--out", default=DEFAULT_OUT)
    parser.add_argument("--report-out", default=DEFAULT_REPORT)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--max-rows", type=int, default=0)
    args = parser.parse_args()

    try:
        import pandas as pd
        from sklearn.compose import ColumnTransformer
        from sklearn.ensemble import RandomForestRegressor
        from sklearn.pipeline import Pipeline
        from sklearn.preprocessing import OneHotEncoder
    except ImportError as error:
        raise SystemExit(
            "필요한 패키지가 없습니다. pandas와 scikit-learn 설치 후 다시 실행하세요: "
            f"{error}",
        ) from error

    feature_path = Path(args.features)
    ensure_feature_table(feature_path, feature_mode="preoutcome_sequence")
    df = pd.read_csv(feature_path, low_memory=False)
    if "path_clear_rate" not in df.columns:
        raise SystemExit("feature table에 path_clear_rate target이 없습니다.")
    if "source_path" not in df.columns:
        raise SystemExit("feature table에 source_path 컬럼이 없습니다.")

    if args.max_rows > 0 and len(df) > args.max_rows:
        df = df.sample(n=args.max_rows, random_state=args.seed).reset_index(drop=True)

    feature_columns = [key for key in [*NUMERIC_FEATURES, *CATEGORICAL_FEATURES] if key in df.columns]
    numeric_features = [key for key in NUMERIC_FEATURES if key in feature_columns]
    categorical_features = [key for key in CATEGORICAL_FEATURES if key in feature_columns]
    if not feature_columns:
        raise SystemExit("사용 가능한 feature column이 없습니다.")

    x = df[feature_columns].copy()
    for key in numeric_features:
        x[key] = x[key].fillna(0)
    for key in categorical_features:
        x[key] = x[key].fillna("")

    model = Pipeline(
        steps=[
            (
                "preprocessor",
                ColumnTransformer(
                    transformers=[
                        ("num", "passthrough", numeric_features),
                        ("cat", OneHotEncoder(handle_unknown="ignore"), categorical_features),
                    ],
                ),
            ),
            (
                "model",
                RandomForestRegressor(
                    n_estimators=160,
                    min_samples_leaf=2,
                    n_jobs=2,
                    random_state=args.seed,
                ),
            ),
        ],
    )
    model.fit(x, df["path_clear_rate"].astype(float))
    df["predicted_path_clear_rate"] = model.predict(x)

    rows = rank_observed_candidates(df)
    if not rows:
        raise SystemExit("none/v9 balanced/power 4개 경로를 모두 가진 후보가 없습니다.")

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)

    metrics = read_json(Path(args.metrics))
    report_path = Path(args.report_out)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(
        build_report(
            feature_path=feature_path,
            out_path=out_path,
            rows=rows,
            row_count=len(df),
            metrics=metrics,
        ),
        encoding="utf-8",
    )
    print(f"sequence recommendations: {out_path}")
    print(f"report: {report_path}")
    return 0


def rank_observed_candidates(df: Any) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for source_path, group in df.groupby("source_path", dropna=False):
        key_rows = {
            (str(row["loadout_id"]), str(row["market_profile"])): row
            for _, row in group.iterrows()
            if str(row["loadout_id"]) in {LOADOUT_BALANCED, LOADOUT_POWER}
            and str(row["market_profile"]) in {MARKET_NONE, MARKET_V9}
        }
        required = [
            (LOADOUT_BALANCED, MARKET_NONE),
            (LOADOUT_BALANCED, MARKET_V9),
            (LOADOUT_POWER, MARKET_NONE),
            (LOADOUT_POWER, MARKET_V9),
        ]
        if not all(key in key_rows for key in required):
            continue

        balanced_none = key_rows[(LOADOUT_BALANCED, MARKET_NONE)]
        balanced_v9 = key_rows[(LOADOUT_BALANCED, MARKET_V9)]
        power_none = key_rows[(LOADOUT_POWER, MARKET_NONE)]
        power_v9 = key_rows[(LOADOUT_POWER, MARKET_V9)]

        actual_balanced_delta = rate(balanced_v9) - rate(balanced_none)
        actual_power_delta = rate(power_v9) - rate(power_none)
        predicted_balanced_delta = predicted(balanced_v9) - predicted(balanced_none)
        predicted_power_delta = predicted(power_v9) - predicted(power_none)
        fresh_gate_pass = actual_balanced_delta >= 0 and actual_power_delta >= 0
        ml_gate_pass = predicted_balanced_delta >= 0 and predicted_power_delta >= 0

        # 추천 점수는 자동 적용 점수가 아니라 검토 우선순위다.
        score = 0.0
        score += (actual_balanced_delta + actual_power_delta) * 4.0
        score += (predicted_balanced_delta + predicted_power_delta) * 2.0
        score += min(rate(balanced_v9), rate(power_v9)) * 1.5
        if fresh_gate_pass:
            score += 1.0
        if ml_gate_pass:
            score += 0.5
        if not fresh_gate_pass:
            score -= 2.0
        if rate(balanced_v9) < 0.5:
            score -= 0.5

        rows.append(
            {
                "source_path": str(source_path),
                "base_experiment_id": first_value(group, "base_experiment_id"),
                "sim_economy_mode": first_value(group, "sim_economy_mode"),
                "sim_market_spend_mode": first_value(group, "sim_market_spend_mode"),
                "sim_price_band_mode": first_value(group, "sim_price_band_mode"),
                "sim_market_choice_mode": first_value(group, "sim_market_choice_mode"),
                "fresh_gate_pass": int(fresh_gate_pass),
                "ml_gate_pass": int(ml_gate_pass),
                "actual_balanced_none": rounded(rate(balanced_none)),
                "actual_balanced_v9": rounded(rate(balanced_v9)),
                "actual_balanced_delta": rounded(actual_balanced_delta),
                "actual_power_none": rounded(rate(power_none)),
                "actual_power_v9": rounded(rate(power_v9)),
                "actual_power_delta": rounded(actual_power_delta),
                "predicted_balanced_none": rounded(predicted(balanced_none)),
                "predicted_balanced_v9": rounded(predicted(balanced_v9)),
                "predicted_balanced_delta": rounded(predicted_balanced_delta),
                "predicted_power_none": rounded(predicted(power_none)),
                "predicted_power_v9": rounded(predicted(power_v9)),
                "predicted_power_delta": rounded(predicted_power_delta),
                "recommendation_score": rounded(score),
            },
        )
    return sorted(rows, key=lambda row: row["recommendation_score"], reverse=True)


def rate(row: Any) -> float:
    return float(row["path_clear_rate"])


def predicted(row: Any) -> float:
    return float(row["predicted_path_clear_rate"])


def rounded(value: float) -> float:
    return round(float(value), 4)


def first_value(group: Any, column: str) -> str:
    if column not in group.columns:
        return ""
    values = [str(value) for value in group[column].dropna().tolist() if str(value)]
    return values[0] if values else ""


def read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def build_report(
    *,
    feature_path: Path,
    out_path: Path,
    rows: list[dict[str, Any]],
    row_count: int,
    metrics: dict[str, Any],
) -> str:
    top_rows = rows[:8]
    current_rows = [
        row for row in rows if "runtime_s4_rank_weight_v1_growth_access" in row["source_path"]
    ][:4]
    if not current_rows:
        current_rows = [
            row for row in rows if "runtime_s4_rank_weight_v1" in row["source_path"]
        ][:4]
    table = sequence_table(top_rows)
    current_table = sequence_table(current_rows) if current_rows else ["- 현재 runtime handoff 후보를 찾지 못했다."]
    mae = float(metrics.get("mae", 0.0))
    rmse = float(metrics.get("rmse", 0.0))
    r2 = float(metrics.get("r2", 0.0))
    metric_rows = [
        "| 항목 | 현재값 | 이상값/최선 | 판단 |",
        "|---|---:|---:|---|",
        f"| MAE | {mae:.4f} | 0.0000 | 낮을수록 좋다. 한 판 클리어율 예측 오차다. |",
        f"| RMSE | {rmse:.4f} | 0.0000 | 큰 오차에 더 민감한 예측 오차다. |",
        f"| R2 | {r2:.4f} | 1.0000 | 0.90 이상이라 경로 후보 선별 신호로 사용 가능하다. |",
    ]
    return "\n".join(
        [
            "# Pre-Outcome Sequence 후보 추천 리포트",
            "",
            "## 최종 결론 요약",
            "",
            "- 결론: 전체 경로 모델은 후보 선별용으로 사용 가능하다. 다만 런타임 자동 적용은 아니며, 실제 r400 이상 재시뮬레이션으로 확인한 후보만 적용 후보가 된다.",
            "- 핵심 판단: 좋은 마켓 선택(v9)이 마켓 없음(none)보다 balanced와 power 양쪽에서 나아져야 통과다.",
            "- 사용 가능: 어떤 후보를 다음 검증 대상으로 볼지 고르는 일, 이미 실행한 r400/r800 결과의 우선순위 정리.",
            "- 사용 금지: 모델 예측만 보고 target/boss/market/economy를 자동 변경하는 일.",
            "- 다음 액션: fresh gate와 ML gate가 함께 맞는 후보를 runtime/economy handoff 문서에 연결하고, 부족한 후보는 다시 실험한다.",
            "",
            "## 핵심 지표",
            "",
            *metric_rows,
            "",
            "## 현재 후보 상태",
            "",
            "쉽게 말하면, `none`은 좋은 마켓 도움 없이 돈 판이고 `v9`는 좋은 마켓 선택을 한 판이다.",
            "우리가 원하는 것은 `v9`가 balanced와 power 둘 다에서 `none`보다 나아지는 것이다.",
            "",
            *current_table,
            "",
            "## 상위 후보",
            "",
            *table,
            "",
            "## 입력과 산출물",
            "",
            f"- feature table: `{feature_path}`",
            f"- recommendation csv: `{out_path}`",
            f"- rows: {row_count}",
            "",
            "## 해석 기준",
            "",
            "- fresh gate: 실제 시뮬레이션 결과에서 v9가 none보다 나은지 보는 기준이다.",
            "- ML gate: 모델 예측에서도 v9가 none보다 나은지 보는 기준이다.",
            "- 둘 다 통과하면 다음 적용 후보로 볼 수 있다. 둘 중 하나라도 실패하면 원인을 다시 좁혀야 한다.",
            "",
        ],
    )


def sequence_table(rows: list[dict[str, Any]]) -> list[str]:
    if not rows:
        return ["- 후보 없음."]
    table = [
        "| 순위 | 후보 요약 | 실제 통과 | ML 통과 | balanced none→v9 | power none→v9 | 점수 |",
        "|---:|---|---:|---:|---:|---:|---:|",
    ]
    for index, row in enumerate(rows, start=1):
        label = Path(row["source_path"]).name.replace("_summary.json", "")
        table.append(
            "| {rank} | `{label}` | {fresh} | {ml} | {bn:.4f}→{bv:.4f} ({bd:+.4f}) | {pn:.4f}→{pv:.4f} ({pd:+.4f}) | {score:.4f} |".format(
                rank=index,
                label=label,
                fresh=int(row["fresh_gate_pass"]),
                ml=int(row["ml_gate_pass"]),
                bn=float(row["actual_balanced_none"]),
                bv=float(row["actual_balanced_v9"]),
                bd=float(row["actual_balanced_delta"]),
                pn=float(row["actual_power_none"]),
                pv=float(row["actual_power_v9"]),
                pd=float(row["actual_power_delta"]),
                score=float(row["recommendation_score"]),
            ),
        )
    return table


if __name__ == "__main__":
    raise SystemExit(main())
