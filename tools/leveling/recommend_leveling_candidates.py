#!/usr/bin/env python3
"""pre-outcome 모델로 레벨링 후보 grid를 랭킹한다."""

from __future__ import annotations

import argparse
import csv
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from feature_table_autogen import ensure_feature_table


DEFAULT_FEATURES = "analysis/leveling/generated/features/leveling_preoutcome_feature_table.csv"
DEFAULT_OUT = "analysis/leveling/models/preoutcome_candidate_recommendations.csv"
DEFAULT_REPORT = "analysis/leveling/reports/preoutcome_candidate_recommendation_report.md"

NUMERIC_FEATURES = [
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
    base_experiment_id: str | None = None
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
    parser.add_argument(
        "--max-rows",
        type=int,
        default=60000,
        help="추천표 학습 비용 상한. 0 이하면 전체 row를 사용합니다.",
    )
    parser.add_argument(
        "--min-run-count",
        type=int,
        default=80,
        help="추천 모델 학습에서 이 run_count 미만 row를 제외합니다.",
    )
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
    ensure_feature_table(feature_path, feature_mode="preoutcome")
    df = pd.read_csv(feature_path, low_memory=False)
    original_row_count = len(df)
    before_filter_row_count = len(df)
    if args.min_run_count > 0:
        if "run_count" not in df.columns:
            raise SystemExit("--min-run-count를 쓰려면 run_count 컬럼이 필요합니다.")
        df = df[df["run_count"].fillna(0).astype(float) >= args.min_run_count].reset_index(drop=True)
        if len(df) < 8:
            raise SystemExit("min-run-count 적용 후 학습 row가 너무 적습니다.")
    if args.max_rows > 0 and len(df) > args.max_rows:
        df = df.sample(n=args.max_rows, random_state=args.seed).reset_index(drop=True)
    feature_columns = [
        key
        for key in [*NUMERIC_FEATURES, *CATEGORICAL_FEATURES]
        if key in df.columns
    ]
    target_column = "clear_rate_smoothed" if "clear_rate_smoothed" in df.columns else "clear_rate"
    if target_column not in df.columns:
        raise SystemExit("feature table에 clear_rate target이 없습니다.")
    if not feature_columns:
        raise SystemExit("사용 가능한 feature column이 없습니다.")

    numeric_features = [key for key in NUMERIC_FEATURES if key in feature_columns]
    categorical_features = [key for key in CATEGORICAL_FEATURES if key in feature_columns]
    for key in numeric_features:
        df[key] = df[key].fillna(0)
    for key in categorical_features:
        df[key] = df[key].fillna("")
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
    model.fit(df[feature_columns], df[target_column].astype(float))

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
            row_count=len(df),
            source_row_count=original_row_count,
            before_filter_row_count=before_filter_row_count,
            max_rows=args.max_rows,
            min_run_count=args.min_run_count,
            target_column=target_column,
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
            base_experiment_id="base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_runtime_station_pool_s4_rank_weight_v1",
        ),
        Candidate(
            candidate_id="runtime_s4_rank_growth_access_current",
            category="runtime_handoff",
            description="현재 handoff 후보: S4 rank pressure 가중 + growth access price band",
            base_experiment_id="base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_runtime_station_pool_s4_rank_weight_v1",
            sweep_reward_scale=0.40,
            sweep_price_scale=2.20,
            sim_economy_mode="gated_known_cost",
            sim_market_spend_mode="reroll_slot_sell_v1",
            sim_price_band_mode="growth_access_v1",
            sim_market_choice_mode="affordable_alternative_v1",
        ),
        Candidate(
            candidate_id="runtime_s4_rank_growth_access_slot_sell",
            category="runtime_handoff_probe",
            description="v9 상승 후보: S4 rank pressure + growth access + slot sell 유지, reroll spend 제거",
            base_experiment_id="base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_runtime_station_pool_s4_rank_weight_v1",
            sweep_reward_scale=0.40,
            sweep_price_scale=2.20,
            sim_economy_mode="gated_known_cost",
            sim_market_spend_mode="slot_sell_v1",
            sim_price_band_mode="growth_access_v1",
            sim_market_choice_mode="affordable_alternative_v1",
        ),
        Candidate(
            candidate_id="runtime_s4_rank_growth_access_first_reroll_free",
            category="runtime_handoff_probe",
            description="정책 안전 후보: 첫 리롤만 무료, 슬롯 교체/판매 유지",
            base_experiment_id="base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_runtime_station_pool_s4_rank_weight_v1",
            sweep_reward_scale=0.40,
            sweep_price_scale=2.20,
            sim_economy_mode="gated_known_cost",
            sim_market_spend_mode="first_reroll_free_v1",
            sim_price_band_mode="growth_access_v1",
            sim_market_choice_mode="affordable_alternative_v1",
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
            candidate_id="economy_r040_p220_growth_access_spend_choice",
            category="economy",
            description="성장 후보 구매 접근성을 열어 둔 reward 0.40 / price 2.2 + growth access price band",
            sweep_reward_scale=0.40,
            sweep_price_scale=2.20,
            sim_economy_mode="gated_known_cost",
            sim_market_spend_mode="reroll_slot_sell_v1",
            sim_price_band_mode="growth_access_v1",
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
                            "base_experiment_id": candidate.base_experiment_id or candidate.candidate_id,
                            "loadout_id": loadout,
                            "blind_tier": tier,
                            "difficulty": "standard",
                            "market_profile": market,
                            "resolved_market_profile": market,
                            "run_modifier": "basic",
                            "sim_boss_constraint_id": runtime_boss_constraint_id(station, tier, candidate),
                            "station": station,
                            "station_tier_index": station * 3 + tier_index,
                            "tier_index": tier_index,
                            "station_band_index": station_band_index(station),
                            "is_boss_tier": int(tier == "boss"),
                            "is_late_station": int(station >= 6),
                            "is_final_station": int(station >= 8),
                            "expected_target_score": expected_target_score(station, tier, candidate),
                            "expected_reward_gold": expected_reward_gold(tier, candidate),
                            "board_discard_pressure": int(tier in {"big", "boss"}),
                            "hand_discard_pressure": int(tier == "boss"),
                            "max_hand_size_pressure": int(tier == "boss"),
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
                            "is_shop_slot_market": int(market.startswith("shop_slot_market")),
                            "is_sim_policy_market": int(market in {
                                "shop_slot_market_v10",
                                "shop_slot_market_v11",
                                "shop_slot_market_v12",
                                "shop_slot_market_v13",
                            }),
                            "market_availability_index": market_availability_index(market),
                            "has_boss_constraint": int(runtime_boss_constraint_id(station, tier, candidate) != ""),
                            "boss_family_index": boss_family_index(runtime_boss_constraint_id(station, tier, candidate)),
                            "boss_level_index": boss_level_index(runtime_boss_constraint_id(station, tier, candidate)),
                            "boss_pressure_index": boss_pressure_index(runtime_boss_constraint_id(station, tier, candidate)),
                            "is_runtime_boss_modifier": int(runtime_boss_constraint_id(station, tier, candidate) != ""),
                            "economy_pressure_index": economy_pressure_index(
                                candidate.sweep_reward_scale,
                                candidate.sweep_price_scale,
                            ),
                            "station_boss_interaction": station * int(tier == "boss"),
                            "station_pressure_interaction": station * boss_pressure_index(runtime_boss_constraint_id(station, tier, candidate)),
                            "market_station_interaction": station * market_availability_index(market),
                            "economy_market_interaction": economy_pressure_index(
                                candidate.sweep_reward_scale,
                                candidate.sweep_price_scale,
                            ) * int(market != "none"),
                            "price_band_growth_access": int(candidate.sim_price_band_mode == "growth_access_v1"),
                            "price_band_catalog_normalized": int(candidate.sim_price_band_mode == "catalog_normalized_v1"),
                            "spend_mode_slot_sell": int(candidate.sim_market_spend_mode == "slot_sell_v1"),
                            "spend_mode_first_reroll_free": int(candidate.sim_market_spend_mode == "first_reroll_free_v1"),
                            "spend_mode_reroll_slot_sell_soft": int(candidate.sim_market_spend_mode == "reroll_slot_sell_soft_v1"),
                            "spend_mode_reroll_slot_sell": int(candidate.sim_market_spend_mode == "reroll_slot_sell_v1"),
                            "choice_mode_affordable_alternative": int(candidate.sim_market_choice_mode == "affordable_alternative_v1"),
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
        score -= 5.0
    if avg_s8_boss > 0.72:
        score -= 1.0

    return {
        "candidate_id": candidate.candidate_id,
        "category": candidate.category,
        "predicted_v9_clear_avg": round(avg_v9, 4),
        "predicted_none_clear_avg": round(avg_none, 4),
        "predicted_market_delta": round(market_delta, 4),
        "predicted_s1_boss_v9": round(avg_s1_boss, 4),
        "predicted_s8_boss_v9": round(avg_s8_boss, 4),
        "market_gate_pass": int(avg_v9 >= avg_none),
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


def station_band_index(station: int) -> int:
    if station <= 2:
        return 0
    if station <= 5:
        return 1
    if station <= 7:
        return 2
    return 3


def economy_pressure_index(reward_scale: float, price_scale: float) -> float:
    if reward_scale <= 0:
        return price_scale
    return price_scale / reward_scale


def market_availability_index(market: str) -> int:
    if not market.startswith("shop_slot_market"):
        return 0
    if market == "shop_slot_market_v9":
        return 1
    if market == "shop_slot_market_v10":
        return 2
    if market == "shop_slot_market_v11":
        return 3
    if market == "shop_slot_market_v12":
        return 4
    if market == "shop_slot_market_v13":
        return 5
    return 1


def runtime_boss_constraint_id(station: int, tier: str, candidate: Candidate) -> str:
    if tier != "boss":
        return ""
    if candidate.base_experiment_id and "runtime_station_pool_s4_rank_weight" in candidate.base_experiment_id:
        return {
            1: "yellow_dampener_v1",
            2: "blue_dampener_v1",
            3: "face_tile_dampener_v1",
            4: "single_rank_pressure",
            5: "repeat_rank_pressure_v4",
            6: "all_score_dampener_v1",
            7: "confirm_count_tax_v2",
            8: "confirm_limit_tax_v1",
        }.get(station, "")
    return ""


def boss_family_index(value: str) -> int:
    if value == "":
        return -1
    family_patterns = [
        ["color", "red_", "yellow_", "blue_", "black_"],
        ["line", "row_", "column_", "diagonal_"],
        ["face"],
        ["repeat"],
        ["single"],
        ["confirm_count"],
        ["confirm_limit"],
        ["all_score"],
        ["first_confirm"],
    ]
    for index, patterns in enumerate(family_patterns):
        if any(pattern in value for pattern in patterns):
            return index
    return len(family_patterns)


def boss_level_index(value: str) -> int:
    return {
        "yellow_dampener_v1": 0,
        "blue_dampener_v1": 1,
        "face_tile_dampener_v1": 1,
        "single_rank_pressure": 3,
        "repeat_rank_pressure_v4": 3,
        "all_score_dampener_v1": 4,
        "confirm_count_tax_v2": 5,
        "confirm_limit_tax_v1": 6,
    }.get(value, -1 if value == "" else 7)


def boss_pressure_index(value: str) -> float:
    return {
        "yellow_dampener_v1": 0.40,
        "blue_dampener_v1": 0.40,
        "face_tile_dampener_v1": 0.35,
        "single_rank_pressure": 0.30,
        "repeat_rank_pressure_v4": 0.20,
        "all_score_dampener_v1": 0.20,
        "confirm_count_tax_v2": 0.25,
        "confirm_limit_tax_v1": 0.30,
    }.get(value, 0.0)


def expected_target_score(station: int, tier: str, candidate: Candidate) -> int:
    base = {
        1: {"small": 240, "big": 264, "boss": 265},
        2: {"small": 372, "big": 431, "boss": 439},
        3: {"small": 463, "big": 537, "boss": 547},
        4: {"small": 580, "big": 672, "boss": 685},
        5: {"small": 725, "big": 841, "boss": 857},
        6: {"small": 923, "big": 1112, "boss": 1121},
        7: {"small": 1154, "big": 1391, "boss": 1401},
        8: {"small": 1441, "big": 1738, "boss": 1739},
    }.get(station, {}).get(tier, 0)
    tier_multiplier = {
        "small": candidate.small_target_multiplier,
        "big": candidate.big_target_multiplier,
        "boss": candidate.boss_target_multiplier,
    }.get(tier, 1.0)
    if tier == "boss" and station == 1:
        tier_multiplier *= candidate.s1_boss_target_multiplier
    if tier == "boss" and station == 2:
        tier_multiplier *= candidate.s2_boss_target_multiplier
    if tier == "boss" and station == 3:
        tier_multiplier *= candidate.s3_boss_target_multiplier
    return round(base * candidate.target_multiplier * tier_multiplier)


def expected_reward_gold(tier: str, candidate: Candidate) -> float:
    return {"small": 4, "big": 8, "boss": 12}.get(tier, 0) * candidate.reward_multiplier


def build_report(
    *,
    feature_path: Path,
    out_path: Path,
    rows: list[dict[str, Any]],
    row_count: int,
    source_row_count: int,
    before_filter_row_count: int,
    max_rows: int,
    min_run_count: int,
    target_column: str,
) -> str:
    top_rows = rows[:6]
    table = [
        "| 순위 | 후보 | 분류 | 통과 | 점수 | v9 평균 | none 평균 | 차이 | S1 boss | S8 boss |",
        "|---:|---|---|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for index, row in enumerate(top_rows, start=1):
        table.append(
            "| {rank} | `{candidate}` | {category} | {gate} | {score:.4f} | {v9:.4f} | {none:.4f} | {delta:.4f} | {s1:.4f} | {s8:.4f} |".format(
                rank=index,
                candidate=row["candidate_id"],
                category=row["category"],
                gate=row["market_gate_pass"],
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
            "- 결론: 이 추천표는 high-confidence row 기준 fresh resimulation 후보를 고르는 참고자료이며 ML 마감 근거가 아니다.",
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
            f"- source rows: {source_row_count}",
            f"- rows before filter: {before_filter_row_count}",
            f"- training rows: {row_count}",
            f"- max rows: {max_rows}",
            f"- min run count: {min_run_count}",
            f"- target: `{target_column}`",
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
