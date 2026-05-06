#!/usr/bin/env python3
"""pre-outcome 모델로 레벨링 후보 grid를 랭킹한다."""

from __future__ import annotations

import argparse
import csv
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any


DEFAULT_FEATURES = "analysis/leveling/data/features/leveling_preoutcome_feature_table.csv"
DEFAULT_OUT = "analysis/leveling/models/preoutcome_candidate_recommendations.csv"
DEFAULT_REPORT = "analysis/leveling/reports/preoutcome_candidate_recommendation_report.md"

NUMERIC_FEATURES = [
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

LOADOUTS = ["progression_route_balanced", "progression_route_power"]
MARKETS = ["none", "shop_slot_market_v9"]
TIERS = [("small", 0), ("big", 1), ("boss", 2)]


@dataclass(frozen=True)
class Candidate:
    candidate_id: str
    category: str
    description: str
    target_multiplier: float = 1.0
    small_target_multiplier: float = 1.0
    big_target_multiplier: float = 1.0
    boss_target_multiplier: float = 1.0
    s1_boss_target_multiplier: float = 1.0
    s2_boss_target_multiplier: float = 1.0
    s3_boss_target_multiplier: float = 1.0
    reward_multiplier: float = 1.0
    sweep_reward_scale: float = 1.0
    sweep_price_scale: float = 1.0
    sim_economy_mode: str = "trace_only"
    sim_market_budget_mode: str = "none"
    sim_market_spend_mode: str = "none"
    sim_price_band_mode: str = "none"
    sim_market_choice_mode: str = "none"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="pre-outcome RandomForest baseline으로 후보 설정을 랭킹합니다.",
    )
    parser.add_argument("--features", default=DEFAULT_FEATURES)
    parser.add_argument("--out", default=DEFAULT_OUT)
    parser.add_argument("--report-out", default=DEFAULT_REPORT)
    parser.add_argument("--seed", type=int, default=42)
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
    df = pd.read_csv(feature_path)
    feature_columns = [
        key
        for key in [*NUMERIC_FEATURES, *CATEGORICAL_FEATURES]
        if key in df.columns
    ]
    if "clear_rate" not in df.columns:
        raise SystemExit("feature table에 clear_rate target이 없습니다.")
    if not feature_columns:
        raise SystemExit("사용 가능한 feature column이 없습니다.")

    numeric_features = [key for key in NUMERIC_FEATURES if key in feature_columns]
    categorical_features = [key for key in CATEGORICAL_FEATURES if key in feature_columns]
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
                    n_estimators=300,
                    min_samples_leaf=2,
                    random_state=args.seed,
                ),
            ),
        ],
    )
    model.fit(df[feature_columns], df["clear_rate"].astype(float))

    candidates = candidate_grid()
    rows = []
    for candidate in candidates:
        prediction_rows = rows_for_candidate(candidate)
        predictions = model.predict(pd.DataFrame(prediction_rows)[feature_columns])
        rows.append(score_candidate(candidate, prediction_rows, predictions))

    ranked = sorted(rows, key=lambda row: row["recommendation_score"], reverse=True)
    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=list(ranked[0].keys()),
            lineterminator="\n",
        )
        writer.writeheader()
        writer.writerows(ranked)

    report_path = Path(args.report_out)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(
        build_report(
            feature_path=feature_path,
            out_path=out_path,
            rows=ranked,
        ),
        encoding="utf-8",
    )
    print(f"recommendations: {out_path}")
    print(f"report: {report_path}")
    return 0


def candidate_grid() -> list[Candidate]:
    return [
        Candidate(
            candidate_id="current_runtime_trace",
            category="baseline",
            description="현재 런타임 후보를 trace-only 기준으로 읽는 baseline",
        ),
        Candidate(
            candidate_id="economy_r040_p220_spend_choice",
            category="economy",
            description="현재 출품 baseline에 가까운 reward 0.40 / price 2.2 + reroll/slot/sell + affordable choice",
            sweep_reward_scale=0.40,
            sweep_price_scale=2.20,
            sim_economy_mode="gated_known_cost",
            sim_market_spend_mode="reroll_slot_sell_v1",
            sim_price_band_mode="catalog_normalized_v1",
            sim_market_choice_mode="affordable_alternative_v1",
        ),
        Candidate(
            candidate_id="economy_r040_p240_spend_choice",
            category="economy",
            description="경제 압박 강화 후보 reward 0.40 / price 2.4",
            sweep_reward_scale=0.40,
            sweep_price_scale=2.40,
            sim_economy_mode="gated_known_cost",
            sim_market_spend_mode="reroll_slot_sell_v1",
            sim_price_band_mode="catalog_normalized_v1",
            sim_market_choice_mode="affordable_alternative_v1",
        ),
        Candidate(
            candidate_id="economy_r038_p240_spend_choice",
            category="economy",
            description="보상 소폭 축소 + price 2.4 후보",
            sweep_reward_scale=0.38,
            sweep_price_scale=2.40,
            sim_economy_mode="gated_known_cost",
            sim_market_spend_mode="reroll_slot_sell_v1",
            sim_price_band_mode="catalog_normalized_v1",
            sim_market_choice_mode="affordable_alternative_v1",
        ),
        Candidate(
            candidate_id="economy_r040_p260_spend_choice",
            category="economy",
            description="가격 압박 강한 price 2.6 후보",
            sweep_reward_scale=0.40,
            sweep_price_scale=2.60,
            sim_economy_mode="gated_known_cost",
            sim_market_spend_mode="reroll_slot_sell_v1",
            sim_price_band_mode="catalog_normalized_v1",
            sim_market_choice_mode="affordable_alternative_v1",
        ),
        Candidate(
            candidate_id="target_boss_098",
            category="target",
            description="전체 boss target 0.98 후보",
            boss_target_multiplier=0.98,
        ),
        Candidate(
            candidate_id="target_big100_boss102",
            category="target",
            description="후반 압박 보존용 boss target 1.02 후보",
            boss_target_multiplier=1.02,
        ),
        Candidate(
            candidate_id="early_boss_soft_s1_098_s2_100_s3_100",
            category="target",
            description="S1 boss만 0.98로 낮추는 초반 완화 후보",
            s1_boss_target_multiplier=0.98,
        ),
        Candidate(
            candidate_id="market_v9_current_no_economy_change",
            category="market",
            description="마켓 v9 유지, economy sim 변경 없음",
        ),
    ]


def rows_for_candidate(candidate: Candidate) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for station in range(1, 9):
        for tier, tier_index in TIERS:
            for loadout in LOADOUTS:
                for market in MARKETS:
                    rows.append(
                        {
                            "base_experiment_id": candidate.candidate_id,
                            "loadout_id": loadout,
                            "blind_tier": tier,
                            "difficulty": "standard",
                            "market_profile": market,
                            "resolved_market_profile": market,
                            "run_modifier": "basic",
                            "sim_boss_constraint_id": "",
                            "station": station,
                            "tier_index": tier_index,
                            "difficulty_multiplier": 1.0,
                            "target_multiplier": candidate.target_multiplier,
                            "small_target_multiplier": candidate.small_target_multiplier,
                            "big_target_multiplier": candidate.big_target_multiplier,
                            "boss_target_multiplier": candidate.boss_target_multiplier,
                            "s1_boss_target_multiplier": candidate.s1_boss_target_multiplier,
                            "s2_boss_target_multiplier": candidate.s2_boss_target_multiplier,
                            "s3_boss_target_multiplier": candidate.s3_boss_target_multiplier,
                            "reward_multiplier": candidate.reward_multiplier,
                            "sweep_reward_scale": candidate.sweep_reward_scale,
                            "sweep_price_scale": candidate.sweep_price_scale,
                            "has_market_profile": int(market != "none"),
                            "market_profile_version": 9 if market == "shop_slot_market_v9" else 0,
                            "has_boss_constraint": 0,
                            "boss_family_index": -1,
                            "sim_economy_mode": candidate.sim_economy_mode,
                            "sim_market_budget_mode": candidate.sim_market_budget_mode,
                            "sim_market_spend_mode": candidate.sim_market_spend_mode,
                            "sim_price_band_mode": candidate.sim_price_band_mode,
                            "sim_market_choice_mode": candidate.sim_market_choice_mode,
                        },
                    )
    return rows


def score_candidate(
    candidate: Candidate,
    prediction_rows: list[dict[str, Any]],
    predictions: Any,
) -> dict[str, Any]:
    enriched = [
        {**row, "prediction": float(prediction)}
        for row, prediction in zip(prediction_rows, predictions, strict=True)
    ]
    v9 = [row["prediction"] for row in enriched if row["market_profile"] == "shop_slot_market_v9"]
    none = [row["prediction"] for row in enriched if row["market_profile"] == "none"]
    s1_boss = [
        row["prediction"]
        for row in enriched
        if row["station"] == 1
        and row["blind_tier"] == "boss"
        and row["market_profile"] == "shop_slot_market_v9"
    ]
    s8_boss = [
        row["prediction"]
        for row in enriched
        if row["station"] == 8
        and row["blind_tier"] == "boss"
        and row["market_profile"] == "shop_slot_market_v9"
    ]
    avg_v9 = average(v9)
    avg_none = average(none)
    avg_s1_boss = average(s1_boss)
    avg_s8_boss = average(s8_boss)
    market_delta = avg_v9 - avg_none

    # 정책 점수는 자동 적용용이 아니라 사람 검토 우선순위다.
    score = 0.0
    score += max(0.0, 1.0 - abs(avg_s1_boss - 0.88)) * 2.0
    score += max(0.0, 1.0 - abs(avg_s8_boss - 0.58)) * 2.0
    score += max(-0.5, min(0.5, market_delta)) * 3.0
    if candidate.sweep_price_scale >= 2.2:
        score += 0.15
    if candidate.sweep_price_scale > 2.5:
        score -= 0.25
    if avg_v9 < avg_none:
        score -= 2.0

    return {
        "candidate_id": candidate.candidate_id,
        "category": candidate.category,
        "predicted_v9_clear_avg": round(avg_v9, 4),
        "predicted_none_clear_avg": round(avg_none, 4),
        "predicted_market_delta": round(market_delta, 4),
        "predicted_s1_boss_v9": round(avg_s1_boss, 4),
        "predicted_s8_boss_v9": round(avg_s8_boss, 4),
        "reward_scale": candidate.sweep_reward_scale,
        "price_scale": candidate.sweep_price_scale,
        "boss_target_multiplier": candidate.boss_target_multiplier,
        "s1_boss_target_multiplier": candidate.s1_boss_target_multiplier,
        "sim_market_spend_mode": candidate.sim_market_spend_mode,
        "sim_market_choice_mode": candidate.sim_market_choice_mode,
        "recommendation_score": round(score, 4),
        "description": candidate.description,
    }


def average(values: list[float]) -> float:
    if not values:
        return 0.0
    return sum(values) / len(values)


def build_report(*, feature_path: Path, out_path: Path, rows: list[dict[str, Any]]) -> str:
    top_rows = rows[:6]
    table = [
        "| 순위 | 후보 | 분류 | 점수 | v9 평균 | none 평균 | 차이 | S1 boss | S8 boss |",
        "|---:|---|---|---:|---:|---:|---:|---:|---:|",
    ]
    for index, row in enumerate(top_rows, start=1):
        table.append(
            "| {rank} | `{candidate}` | {category} | {score:.4f} | {v9:.4f} | {none:.4f} | {delta:.4f} | {s1:.4f} | {s8:.4f} |".format(
                rank=index,
                candidate=row["candidate_id"],
                category=row["category"],
                score=float(row["recommendation_score"]),
                v9=float(row["predicted_v9_clear_avg"]),
                none=float(row["predicted_none_clear_avg"]),
                delta=float(row["predicted_market_delta"]),
                s1=float(row["predicted_s1_boss_v9"]),
                s8=float(row["predicted_s8_boss_v9"]),
            ),
        )
    return "\n".join(
        [
            "# Pre-Outcome 후보 추천 리포트",
            "",
            "## 최종 결론 요약",
            "",
            "- 결론: 이 추천표는 fresh resimulation 후보를 고르는 참고자료이며 ML 마감 근거가 아니다.",
            f"- 1위 후보: `{top_rows[0]['candidate_id']}` / score {float(top_rows[0]['recommendation_score']):.4f}." if top_rows else "- 1위 후보: 없음.",
            "- 사용 가능: 후보 우선순위 정리와 후속 probe 설계.",
            "- 사용 금지: 추천 후보를 runtime target/boss/market/economy 값에 자동 적용.",
            "- NotebookLM 상태: 모델 지표가 사용 수준이 된 뒤 보고서/인포그래픽 source로 재생성한다.",
            "- 다음 액션: 상위 후보를 fresh resimulation으로 검증하고 사람 검토표에 통합한다.",
            "",
            "## 핵심 점수",
            "",
            *table,
            "",
            "## 범위",
            "",
            "이 보고서는 실제 ML 전환의 후보 추천 단계다.",
            "모델은 pre-outcome feature만 사용해 후보 grid를 랭킹하지만, 런타임 값은 자동으로 바꾸지 않는다.",
            "추천 후보는 반드시 fresh resimulation과 사람 검토를 거쳐야 한다.",
            "",
            "## 입력",
            "",
            f"- feature table: `{feature_path}`",
            f"- recommendation csv: `{out_path}`",
            "",
            "## 상위 후보 상세",
            "",
            *table,
            "",
            "## 해석",
            "",
            "- `predicted_market_delta`가 음수인 후보는 좋은 market 선택 proxy가 none보다 나빠질 수 있어 위험하다.",
            "- S1 boss는 entry 안정성을, S8 boss는 후반 압박 보존 여부를 보기 위한 모델상 proxy다.",
            "- 이 점수는 자동 밸런싱 점수가 아니라 fresh resimulation 후보를 고르기 위한 사람 검토 우선순위다.",
            "",
            "## 다음 단계",
            "",
            "상위 후보 중 economy 후보와 target 후보를 분리해 fresh resimulation을 실행하고, 결과가 정책 위반 없이 안정적인지 확인한다.",
            "",
        ],
    )


if __name__ == "__main__":
    raise SystemExit(main())
