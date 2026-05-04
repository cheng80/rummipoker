#!/usr/bin/env python3
"""런타임 골드 보상과 카탈로그 가격대를 비교하는 경제 감사 도구."""

from __future__ import annotations

import argparse
import json
import statistics
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable


DEFAULT_ITEM_CATALOG = Path("data/common/items_common_v1.json")
DEFAULT_JESTER_CATALOG = Path("data/common/jesters_common_phase5.json")
DEFAULT_SUMMARY = Path("logs/sim/ml_sweep_boss_runtime_v90_long_r800_summary.json")


@dataclass(frozen=True)
class EconomyConfig:
    stage_clear_gold_base: int = 10
    first_blind_clear_bonus_gold: int = 5
    remaining_board_discard_gold_bonus: int = 5
    remaining_hand_discard_gold_bonus: int = 2
    standard_board_discards: int = 4
    standard_hand_discards: int = 2


def main() -> int:
    parser = argparse.ArgumentParser(
        description="카탈로그 가격과 sweep 기반 골드 보상 추정치를 비교합니다.",
    )
    parser.add_argument("--items", type=Path, default=DEFAULT_ITEM_CATALOG)
    parser.add_argument("--jesters", type=Path, default=DEFAULT_JESTER_CATALOG)
    parser.add_argument("--summary", type=Path, default=DEFAULT_SUMMARY)
    parser.add_argument(
        "--jsonl",
        type=Path,
        help="summary-only가 아닌 sweep JSONL이 있으면 마켓 구매 이벤트를 추가 집계합니다.",
    )
    parser.add_argument("--json-out", type=Path)
    args = parser.parse_args()

    config = EconomyConfig()
    item_catalog = _load_json(args.items)
    jester_catalog = _load_json(args.jesters)
    summary = _load_json(args.summary) if args.summary.exists() else None

    report = {
        "schema_version": 1,
        "inputs": {
            "items": str(args.items),
            "jesters": str(args.jesters),
            "summary": str(args.summary) if summary is not None else None,
            "jsonl": str(args.jsonl) if args.jsonl is not None else None,
        },
        "config": config.__dict__,
        "price_stats": {
            "items_by_rarity": _price_stats(
                item_catalog.get("items", []),
                price_key="basePrice",
                group_key="rarity",
            ),
            "items_by_type": _price_stats(
                item_catalog.get("items", []),
                price_key="basePrice",
                group_key="type",
            ),
            "jesters_by_rarity": _price_stats(
                jester_catalog,
                price_key="baseCost",
                group_key="rarity",
            ),
            "jesters_by_effect_type": _price_stats(
                jester_catalog,
                price_key="baseCost",
                group_key="effectType",
            ),
        },
        "reward_envelope": _reward_envelope(config),
        "summary_reward_estimate": _summary_reward_estimate(summary, config),
        "jsonl_market_trace": _jsonl_market_trace(args.jsonl),
        "catalog_value_flags": _catalog_value_flags(
            item_catalog.get("items", []),
            jester_catalog,
            config,
        ),
    }
    report["purchase_power"] = _purchase_power(report)
    report["calibration_candidates"] = _calibration_candidates(report)
    report["signals"] = _signals(report)

    if args.json_out is not None:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        args.json_out.write_text(
            json.dumps(report, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

    _print_report(report)
    return 0


def _load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _price_stats(
    rows: Iterable[dict[str, Any]],
    *,
    price_key: str,
    group_key: str,
) -> dict[str, dict[str, Any]]:
    grouped: dict[str, list[int]] = defaultdict(list)
    for row in rows:
        group = str(row.get(group_key) or "unknown")
        price = row.get(price_key)
        if isinstance(price, (int, float)):
            grouped[group].append(int(price))

    return {
        group: _numeric_summary(values)
        for group, values in sorted(grouped.items(), key=lambda entry: entry[0])
    }


def _numeric_summary(values: list[int]) -> dict[str, Any]:
    if not values:
        return {"count": 0}
    counts = Counter(values)
    return {
        "count": len(values),
        "min": min(values),
        "max": max(values),
        "avg": round(statistics.mean(values), 2),
        "median": statistics.median(values),
        "price_counts": dict(sorted(counts.items())),
    }


def _catalog_value_flags(
    items: list[dict[str, Any]],
    jesters: list[dict[str, Any]],
    config: EconomyConfig,
) -> dict[str, Any]:
    """런타임 가격을 직접 바꾸기 전 확인할 가치/가격 불일치 후보."""

    item_self_refund_risks = []
    for item in items:
        price = _int(item.get("basePrice"))
        effect = item.get("effect") if isinstance(item.get("effect"), dict) else {}
        op = str(effect.get("op") or "")
        amount = _float(effect.get("amount"))
        estimated_value = 0.0
        reason = ""
        if op == "gain_gold":
            estimated_value = amount
            reason = "즉시 골드 회수"
        elif op == "free_next_reroll":
            estimated_value = config.stage_clear_gold_base / 2
            reason = "기본 리롤 비용 대체"
        elif op == "discount_next_purchase":
            estimated_value = amount
            reason = "다음 구매 할인"
        if price > 0 and estimated_value >= price:
            item_self_refund_risks.append(
                {
                    "id": item.get("id"),
                    "rarity": item.get("rarity"),
                    "base_price": price,
                    "estimated_immediate_value": round(estimated_value, 2),
                    "reason": reason,
                }
            )

    common_prices = [
        _int(card.get("baseCost"))
        for card in jesters
        if card.get("rarity") == "common" and _int(card.get("baseCost")) > 0
    ]
    common_median = statistics.median(common_prices) if common_prices else 0
    elevated_rarity_low_price = []
    high_impact_low_price = []
    high_impact_types = {"xmult_bonus", "stateful_growth", "retrigger", "rule_modifier"}
    for card in jesters:
        price = _int(card.get("baseCost"))
        rarity = str(card.get("rarity") or "common")
        effect_type = str(card.get("effectType") or "")
        row = {
            "id": card.get("id"),
            "rarity": rarity,
            "base_cost": price,
            "effect_type": effect_type,
            "condition_type": card.get("conditionType"),
            "value": card.get("value"),
            "x_value": card.get("xValue"),
        }
        if rarity in {"uncommon", "rare", "legendary"} and common_median and price <= common_median:
            elevated_rarity_low_price.append(row)
        if effect_type in high_impact_types and common_median and price <= common_median + 1:
            high_impact_low_price.append(row)

    return {
        "note": "자동 적용값이 아니라 가격 조정 전 검토 후보",
        "item_self_refund_risks": item_self_refund_risks,
        "jester_common_median_cost": common_median,
        "jester_elevated_rarity_low_price": elevated_rarity_low_price,
        "jester_high_impact_low_price": high_impact_low_price,
    }


def _reward_envelope(config: EconomyConfig) -> dict[str, Any]:
    tiers = {
        "small": (
            config.standard_board_discards,
            config.standard_hand_discards,
        ),
        "big": (
            max(1, config.standard_board_discards - 1),
            config.standard_hand_discards,
        ),
        "boss": (
            max(1, config.standard_board_discards - 1),
            max(1, config.standard_hand_discards - 1),
        ),
    }
    rows = {}
    for tier, (board_discards, hand_discards) in tiers.items():
        max_gold = _cashout_gold(
            config,
            station=1,
            tier=tier,
            remaining_board_discards=board_discards,
            remaining_hand_discards=hand_discards,
        )
        min_gold = _cashout_gold(
            config,
            station=1,
            tier=tier,
            remaining_board_discards=0,
            remaining_hand_discards=0,
        )
        rows[tier] = {
            "standard_unused_resources_gold_s1": max_gold,
            "spent_all_resources_gold_s1": min_gold,
            "unused_resources_after_s1": max_gold
            - (config.first_blind_clear_bonus_gold if tier == "small" else 0),
        }
    return rows


def _summary_reward_estimate(
    summary: dict[str, Any] | None,
    config: EconomyConfig,
) -> dict[str, Any]:
    if summary is None:
        return {"available": False, "reason": "summary file not found"}
    groups = summary.get("groups")
    if not isinstance(groups, list):
        return {"available": False, "reason": "summary has no groups"}

    by_market: dict[str, list[tuple[float, int]]] = defaultdict(list)
    by_station_tier: dict[str, list[tuple[float, int]]] = defaultdict(list)
    for group in groups:
        if not isinstance(group, dict):
            continue
        run_count = _int(group.get("run_count"))
        if run_count <= 0:
            continue
        station = _int(group.get("station"))
        tier = str(group.get("blind_tier") or "")
        board = _float(group.get("avg_remaining_board_discards"))
        hand = _float(group.get("avg_remaining_hand_discards"))
        gold = _cashout_gold(
            config,
            station=station,
            tier=tier,
            remaining_board_discards=board,
            remaining_hand_discards=hand,
        )
        market = str(group.get("market_profile") or "unknown")
        by_market[market].append((gold, run_count))
        by_station_tier[f"S{station} {tier}"].append((gold, run_count))

    return {
        "available": True,
        "source_path": summary.get("source_path"),
        "sweep": summary.get("sweep"),
        "avg_estimated_cashout_gold_by_market": {
            key: round(_weighted_average(values), 2)
            for key, values in sorted(by_market.items())
        },
        "avg_estimated_cashout_gold_by_station_tier": {
            key: round(_weighted_average(values), 2)
            for key, values in sorted(by_station_tier.items())
        },
    }


def _jsonl_market_trace(path: Path | None) -> dict[str, Any]:
    if path is None:
        return {"available": False, "reason": "jsonl input not provided"}
    if not path.exists():
        return {"available": False, "reason": "jsonl file not found"}

    row_count = 0
    battle_count = 0
    sequence_count = 0
    purchase_event_count = 0
    missing_cost_event_count = 0
    offered_slot_count = 0
    category_counts: Counter[str] = Counter()
    by_category: dict[str, list[int]] = defaultdict(list)
    by_content: dict[str, list[int]] = defaultdict(list)
    by_market: dict[str, int] = Counter()
    by_station: dict[str, int] = Counter()
    economy_trace_count = 0
    economy_cashout_gold = 0
    economy_known_market_spend = 0
    economy_reroll_spend = 0
    economy_sell_recovery = 0
    economy_unaffordable_events = 0
    economy_missing_cost_events = 0
    economy_slot_replace_events = 0
    economy_final_gold_values: list[int] = []
    economy_final_gold_by_market: dict[str, list[int]] = defaultdict(list)
    economy_sequence_by_market_loadout: dict[str, dict[str, Any]] = defaultdict(
        lambda: {
            "run_count": 0,
            "path_clear_count": 0,
            "final_gold_values": [],
        }
    )
    economy_mode = ""
    economy_price_band_mode = ""
    economy_market_choice_mode = ""
    economy_by_station_tier: dict[str, dict[str, list[int]]] = defaultdict(
        lambda: defaultdict(list)
    )
    economy_by_market_station_tier: dict[str, dict[str, list[int]]] = defaultdict(
        lambda: defaultdict(list)
    )

    with path.open(encoding="utf-8") as handle:
        for line in handle:
            if not line.strip():
                continue
            row_count += 1
            row = json.loads(line)
            row_type = row.get("row_type")
            if row_type == "battle":
                battle_count += 1
                trace = row.get("sim_economy_trace")
                if isinstance(trace, dict):
                    economy_trace_count += 1
                    if not economy_mode:
                        economy_mode = str(trace.get("mode") or "")
                    if not economy_price_band_mode:
                        economy_price_band_mode = str(
                            trace.get("price_band_mode") or ""
                        )
                    if not economy_market_choice_mode:
                        economy_market_choice_mode = str(
                            trace.get("market_choice_mode") or ""
                        )
                    station_tier = (
                        f"S{_int(row.get('station'))} "
                        f"{str(row.get('blind_tier') or 'unknown')}"
                    )
                    market_station_tier = (
                        f"{str(row.get('market_profile') or 'unknown')}|"
                        f"{station_tier}"
                    )
                    economy_by_station_tier[station_tier]["gold_before_market"].append(
                        _int(trace.get("gold_before_market"))
                    )
                    economy_by_station_tier[station_tier]["gold_after_cashout"].append(
                        _int(trace.get("gold_after_cashout"))
                    )
                    economy_by_station_tier[station_tier]["cashout_gold"].append(
                        _int(trace.get("cashout_gold"))
                    )
                    economy_by_market_station_tier[market_station_tier][
                        "gold_before_market"
                    ].append(_int(trace.get("gold_before_market")))
                    economy_by_market_station_tier[market_station_tier][
                        "gold_after_cashout"
                    ].append(_int(trace.get("gold_after_cashout")))
                    economy_by_market_station_tier[market_station_tier][
                        "cashout_gold"
                    ].append(_int(trace.get("cashout_gold")))
                    economy_cashout_gold += _int(trace.get("cashout_gold"))
                    economy_known_market_spend += _int(
                        trace.get("known_market_spend")
                    )
                    economy_reroll_spend += _int(trace.get("reroll_spend"))
                    economy_sell_recovery += _int(trace.get("sell_recovery"))
                    economy_unaffordable_events += _int(
                        trace.get("unaffordable_event_count")
                    )
                    economy_missing_cost_events += _int(
                        trace.get("missing_cost_event_count")
                    )
                    economy_slot_replace_events += _int(
                        trace.get("slot_replace_event_count")
                    )
            elif row_type == "sequence_summary":
                sequence_count += 1
                summary = row.get("sim_economy_summary")
                if isinstance(summary, dict):
                    final_gold = _int(summary.get("final_gold"))
                    economy_final_gold_values.append(final_gold)
                    market = str(row.get("market_profile") or "unknown")
                    loadout = str(row.get("loadout_id") or "unknown")
                    economy_final_gold_by_market[market].append(final_gold)
                    sequence_key = f"{loadout}|{market}"
                    sequence_bucket = economy_sequence_by_market_loadout[
                        sequence_key
                    ]
                    sequence_bucket["run_count"] += 1
                    if row.get("path_cleared") is True:
                        sequence_bucket["path_clear_count"] += 1
                    sequence_bucket["final_gold_values"].append(final_gold)
            market = str(row.get("market_profile") or "unknown")
            by_market[market] += 1
            station = row.get("station")
            if isinstance(station, (int, float)):
                by_station[f"S{int(station)}"] += 1
            slots = row.get("market_shop_slots")
            if isinstance(slots, list):
                offered_slot_count += len(slots)
            events = row.get("market_purchase_events")
            if not isinstance(events, list):
                continue
            for event in events:
                if not isinstance(event, dict):
                    continue
                purchase_event_count += 1
                category = str(event.get("category") or "unknown")
                content_id = str(event.get("content_id") or "unknown")
                category_counts[category] += 1
                cost = event.get("cost")
                if isinstance(cost, (int, float)):
                    by_category[category].append(int(cost))
                    by_content[content_id].append(int(cost))
                else:
                    missing_cost_event_count += 1

    return {
        "available": True,
        "row_count": row_count,
        "battle_row_count": battle_count,
        "sequence_summary_row_count": sequence_count,
        "purchase_event_count": purchase_event_count,
        "missing_cost_event_count": missing_cost_event_count,
        "offered_slot_count": offered_slot_count,
        "purchase_event_count_by_category": dict(sorted(category_counts.items())),
        "row_count_by_market": dict(sorted(by_market.items())),
        "row_count_by_station": dict(sorted(by_station.items())),
        "purchase_cost_by_category": {
            key: _numeric_summary(values)
            for key, values in sorted(by_category.items())
        },
        "purchase_cost_by_content": {
            key: _numeric_summary(values)
            for key, values in sorted(by_content.items())
        },
        "sim_economy_trace": {
            "available": economy_trace_count > 0,
            "mode": economy_mode,
            "price_band_mode": economy_price_band_mode,
            "market_choice_mode": economy_market_choice_mode,
            "battle_trace_count": economy_trace_count,
            "total_cashout_gold": economy_cashout_gold,
            "known_market_spend": economy_known_market_spend,
            "reroll_spend": economy_reroll_spend,
            "sell_recovery": economy_sell_recovery,
            "missing_cost_event_count": economy_missing_cost_events,
            "unaffordable_event_count": economy_unaffordable_events,
            "slot_replace_event_count": economy_slot_replace_events,
            "final_gold": _numeric_summary(economy_final_gold_values)
            if economy_final_gold_values
            else {"count": 0},
            "final_gold_by_market": {
                key: _numeric_summary(values)
                for key, values in sorted(economy_final_gold_by_market.items())
            },
            "sequence_by_market_loadout": {
                key: {
                    "run_count": bucket["run_count"],
                    "path_clear_count": bucket["path_clear_count"],
                    "path_clear_rate": round(
                        bucket["path_clear_count"] / bucket["run_count"], 4
                    )
                    if bucket["run_count"]
                    else 0,
                    "final_gold": _numeric_summary(bucket["final_gold_values"]),
                }
                for key, bucket in sorted(
                    economy_sequence_by_market_loadout.items()
                )
            },
            "by_station_tier": {
                key: {
                    metric: _numeric_summary(values)
                    for metric, values in sorted(metrics.items())
                }
                for key, metrics in sorted(economy_by_station_tier.items())
            },
            "by_market_station_tier": {
                key: {
                    metric: _numeric_summary(values)
                    for metric, values in sorted(metrics.items())
                }
                for key, metrics in sorted(economy_by_market_station_tier.items())
            },
        },
    }


def _purchase_power(report: dict[str, Any]) -> dict[str, Any]:
    item_stats = report["price_stats"]["items_by_rarity"]
    jester_stats = report["price_stats"]["jesters_by_rarity"]
    rewards = {
        "S1 small unused": report["reward_envelope"]["small"][
            "standard_unused_resources_gold_s1"
        ],
        "S1 small spent_all": report["reward_envelope"]["small"][
            "spent_all_resources_gold_s1"
        ],
    }
    summary_estimate = report.get("summary_reward_estimate", {})
    by_market = summary_estimate.get("avg_estimated_cashout_gold_by_market", {})
    if isinstance(by_market, dict):
        for market, gold in by_market.items():
            rewards[f"summary {market} avg"] = gold

    anchors = {
        "common_item_avg": _float(item_stats.get("common", {}).get("avg")),
        "uncommon_item_avg": _float(item_stats.get("uncommon", {}).get("avg")),
        "rare_item_avg": _float(item_stats.get("rare", {}).get("avg")),
        "common_jester_avg": _float(jester_stats.get("common", {}).get("avg")),
        "uncommon_jester_avg": _float(
            jester_stats.get("uncommon", {}).get("avg")
        ),
        "rare_jester_avg": _float(jester_stats.get("rare", {}).get("avg")),
    }
    rows: dict[str, dict[str, float]] = {}
    for reward_label, reward_gold in rewards.items():
        reward = _float(reward_gold)
        rows[reward_label] = {
            anchor: round(reward / price, 2)
            for anchor, price in anchors.items()
            if price > 0
        }
    return {
        "reward_to_price_ratios": rows,
        "anchors": anchors,
    }


def _calibration_candidates(report: dict[str, Any]) -> dict[str, Any]:
    """수치 변경안이 아니라 다음 sweep 후보를 잡기 위한 산정표."""

    common_item = _float(
        report["price_stats"]["items_by_rarity"].get("common", {}).get("avg")
    )
    common_jester = _float(
        report["price_stats"]["jesters_by_rarity"].get("common", {}).get("avg")
    )
    common_anchor = (common_item + common_jester) / 2
    if common_anchor <= 0:
        return {"available": False, "reason": "common price anchor missing"}

    target_common_buys_per_cashout = {
        "tight": 2.0,
        "standard": 3.0,
        "generous": 4.0,
    }
    reward_targets = {
        key: round(common_anchor * count, 2)
        for key, count in target_common_buys_per_cashout.items()
    }
    current_summary = report.get("summary_reward_estimate", {}).get(
        "avg_estimated_cashout_gold_by_market",
        {},
    )
    current_avg = 0.0
    if isinstance(current_summary, dict) and current_summary:
        current_avg = statistics.mean(_float(value) for value in current_summary.values())

    reward_scale_to_targets = {
        key: round(target / current_avg, 3) if current_avg > 0 else 0
        for key, target in reward_targets.items()
    }
    price_scale_to_targets = {
        key: round(current_avg / target, 3) if target > 0 else 0
        for key, target in reward_targets.items()
    }
    return {
        "available": True,
        "note": "직접 적용값이 아니라 economy sweep 후보를 만들기 위한 산정표",
        "common_price_anchor": round(common_anchor, 2),
        "current_summary_avg_cashout": round(current_avg, 2),
        "target_common_buys_per_cashout": target_common_buys_per_cashout,
        "reward_targets": reward_targets,
        "reward_scale_to_targets": reward_scale_to_targets,
        "price_scale_to_targets": price_scale_to_targets,
    }


def _cashout_gold(
    config: EconomyConfig,
    *,
    station: int,
    tier: str,
    remaining_board_discards: float,
    remaining_hand_discards: float,
) -> float:
    first_bonus = (
        config.first_blind_clear_bonus_gold
        if station == 1 and tier == "small"
        else 0
    )
    return (
        config.stage_clear_gold_base
        + first_bonus
        + remaining_board_discards * config.remaining_board_discard_gold_bonus
        + remaining_hand_discards * config.remaining_hand_discard_gold_bonus
    )


def _signals(report: dict[str, Any]) -> list[str]:
    signals: list[str] = []
    item_common = report["price_stats"]["items_by_rarity"].get("common", {})
    jester_common = report["price_stats"]["jesters_by_rarity"].get("common", {})
    small_max = report["reward_envelope"]["small"][
        "standard_unused_resources_gold_s1"
    ]
    common_item_avg = _float(item_common.get("avg"))
    common_jester_avg = _float(jester_common.get("avg"))
    if common_item_avg and small_max >= common_item_avg * 8:
        signals.append(
            "S1 small 자원 미사용 보상만으로 평균 common item 약 8개 이상 구매 가능"
        )
    if common_jester_avg and small_max >= common_jester_avg * 8:
        signals.append(
            "S1 small 자원 미사용 보상만으로 평균 common Jester 약 8개 이상 구매 가능"
        )
    summary_estimate = report.get("summary_reward_estimate", {})
    by_market = summary_estimate.get("avg_estimated_cashout_gold_by_market", {})
    if isinstance(by_market, dict):
        for market, gold in by_market.items():
            if _float(gold) >= common_item_avg * 7:
                signals.append(
                    f"{market} 기존 summary 추정 평균 보상이 common item 평균가의 7배 이상"
                )
    calibration = report.get("calibration_candidates", {})
    if isinstance(calibration, dict) and calibration.get("available"):
        standard_price_scale = _float(
            calibration.get("price_scale_to_targets", {}).get("standard")
        )
        if standard_price_scale >= 2:
            signals.append(
                f"현재 보상을 유지하면 standard 구매력 기준 평균 가격을 약 {standard_price_scale}배로 올려야 함"
            )
    if not signals:
        signals.append("즉시 경고 기준을 넘은 경제 신호 없음")
    jsonl_trace = report.get("jsonl_market_trace", {})
    if isinstance(jsonl_trace, dict) and jsonl_trace.get("available"):
        events = _int(jsonl_trace.get("purchase_event_count"))
        slots = _int(jsonl_trace.get("offered_slot_count"))
        if slots > 0 and events == 0:
            signals.append("raw JSONL에 offer 노출은 있으나 구매 이벤트가 없어 경제 소비 모델이 비어 있음")
        missing_cost = _int(jsonl_trace.get("missing_cost_event_count"))
        if events > 0 and missing_cost / events >= 0.5:
            signals.append(
                "raw JSONL 구매 이벤트 절반 이상이 cost=null이라 실제 가격 산정 근거로 약함"
            )
        sim_trace = jsonl_trace.get("sim_economy_trace", {})
        if isinstance(sim_trace, dict) and sim_trace.get("available"):
            final_gold = sim_trace.get("final_gold", {})
            avg_final_gold = _float(final_gold.get("avg"))
            mode = str(sim_trace.get("mode") or "sim economy")
            if avg_final_gold >= 100:
                by_market = sim_trace.get("final_gold_by_market", {})
                v9_final = _float(
                    by_market.get("shop_slot_market_v9", {}).get("avg")
                )
                none_final = _float(by_market.get("none", {}).get("avg"))
                if v9_final and none_final and v9_final < 40 <= none_final:
                    signals.append(
                        f"{mode} 전체 평균 최종 잔고 {avg_final_gold}G는 none {none_final}G 영향이 크고, v9는 {v9_final}G로 낮음"
                    )
                else:
                    signals.append(
                        f"{mode} 평균 최종 잔고가 {avg_final_gold}G로 높아 구매/가격 gate 필요"
                    )
    return signals


def _weighted_average(values: list[tuple[float, int]]) -> float:
    total_weight = sum(weight for _, weight in values)
    if total_weight <= 0:
        return 0
    return sum(value * weight for value, weight in values) / total_weight


def _int(value: Any) -> int:
    return int(value) if isinstance(value, (int, float)) else 0


def _float(value: Any) -> float:
    return float(value) if isinstance(value, (int, float)) else 0.0


def _print_report(report: dict[str, Any]) -> None:
    print("# Economy audit")
    print()
    print("## Price stats")
    _print_stats("Items by rarity", report["price_stats"]["items_by_rarity"])
    _print_stats("Jesters by rarity", report["price_stats"]["jesters_by_rarity"])
    print()
    print("## Reward envelope")
    for tier, row in report["reward_envelope"].items():
        print(
            f"- {tier}: S1 자원 미사용 {row['standard_unused_resources_gold_s1']}G, "
            f"자원 전부 사용 {row['spent_all_resources_gold_s1']}G"
        )
    estimate = report["summary_reward_estimate"]
    if estimate.get("available"):
        print()
        print("## Existing summary estimate")
        for market, gold in estimate["avg_estimated_cashout_gold_by_market"].items():
            print(f"- {market}: 평균 추정 cashout {gold}G")
    trace = report["jsonl_market_trace"]
    if trace.get("available"):
        print()
        print("## JSONL market trace")
        print(f"- rows: {trace['row_count']}")
        print(f"- offered slots: {trace['offered_slot_count']}")
        print(f"- purchase events: {trace['purchase_event_count']}")
        print(f"- missing cost events: {trace['missing_cost_event_count']}")
        for category, count in trace["purchase_event_count_by_category"].items():
            print(f"- {category}: events={count}")
        for category, row in trace["purchase_cost_by_category"].items():
            print(
                f"- {category}: n={row['count']}, avg cost={row['avg']}, "
                f"min={row['min']}, max={row['max']}"
            )
        sim_trace = trace.get("sim_economy_trace", {})
        if sim_trace.get("available"):
            final_gold = sim_trace["final_gold"]
            print(
                f"- sim economy cashout: {sim_trace['total_cashout_gold']}G, "
                f"known spend: {sim_trace['known_market_spend']}G"
            )
            print(
                f"- sim economy reroll spend: {sim_trace['reroll_spend']}G, "
                f"sell recovery: {sim_trace['sell_recovery']}G, "
                f"slot replace events: {sim_trace['slot_replace_event_count']}"
            )
            print(
                f"- sim economy final gold avg: {final_gold['avg']}G, "
                f"min={final_gold['min']}, max={final_gold['max']}"
            )
            print(
                "- sim economy unaffordable events: "
                f"{sim_trace['unaffordable_event_count']}"
            )
            final_by_market = sim_trace.get("final_gold_by_market", {})
            if isinstance(final_by_market, dict) and final_by_market:
                print("- sim economy final gold by market:")
                for market, row in sorted(final_by_market.items()):
                    print(
                        "  - "
                        f"{market}: avg {row['avg']}G, "
                        f"min={row['min']}, max={row['max']}"
                    )
            sequence_by_market_loadout = sim_trace.get(
                "sequence_by_market_loadout",
                {},
            )
            if (
                isinstance(sequence_by_market_loadout, dict)
                and sequence_by_market_loadout
            ):
                print("- sequence clear/final gold by loadout and market:")
                for key, row in sorted(sequence_by_market_loadout.items()):
                    final = row["final_gold"]
                    print(
                        "  - "
                        f"{key}: clear {row['path_clear_rate'] * 100:.1f}%, "
                        f"final avg {final['avg']}G"
                    )
            by_station_tier = sim_trace.get("by_station_tier", {})
            for key in ["S1 small", "S4 boss", "S8 boss"]:
                row = by_station_tier.get(key)
                if not row:
                    continue
                before = row["gold_before_market"]
                after = row["gold_after_cashout"]
                print(
                    f"- {key}: before avg {before['avg']}G, "
                    f"after avg {after['avg']}G"
                )
            by_market_station_tier = sim_trace.get("by_market_station_tier", {})
            if isinstance(by_market_station_tier, dict):
                for key in [
                    "none|S8 boss",
                    "shop_slot_market_v9|S8 boss",
                ]:
                    row = by_market_station_tier.get(key)
                    if not row:
                        continue
                    before = row["gold_before_market"]
                    after = row["gold_after_cashout"]
                    print(
                        f"- {key}: before avg {before['avg']}G, "
                        f"after avg {after['avg']}G"
                    )
    value_flags = report.get("catalog_value_flags", {})
    if isinstance(value_flags, dict):
        print()
        print("## Catalog value flags")
        print(f"- note: {value_flags.get('note')}")
        print(
            "- Jester common median cost: "
            f"{value_flags.get('jester_common_median_cost')}"
        )
        item_risks = value_flags.get("item_self_refund_risks", [])
        if isinstance(item_risks, list) and item_risks:
            print("- item self-refund risks:")
            for row in item_risks[:8]:
                print(
                    "  - "
                    f"{row.get('id')}: price {row.get('base_price')}G, "
                    f"value {row.get('estimated_immediate_value')}G, "
                    f"{row.get('reason')}"
                )
        rarity_flags = value_flags.get("jester_elevated_rarity_low_price", [])
        if isinstance(rarity_flags, list) and rarity_flags:
            print("- elevated rarity low-price Jesters:")
            for row in rarity_flags[:8]:
                print(
                    "  - "
                    f"{row.get('id')}: {row.get('rarity')} "
                    f"{row.get('base_cost')}G, {row.get('effect_type')}"
                )
        impact_flags = value_flags.get("jester_high_impact_low_price", [])
        if isinstance(impact_flags, list) and impact_flags:
            print("- high-impact low-price Jesters:")
            for row in impact_flags[:8]:
                print(
                    "  - "
                    f"{row.get('id')}: {row.get('base_cost')}G, "
                    f"{row.get('effect_type')} / {row.get('condition_type')}"
                )
    purchase_power = report["purchase_power"]
    print()
    print("## Purchase power")
    for reward_label, ratios in purchase_power["reward_to_price_ratios"].items():
        common_item = ratios.get("common_item_avg")
        common_jester = ratios.get("common_jester_avg")
        print(
            f"- {reward_label}: common item {common_item}개, "
            f"common Jester {common_jester}개"
        )
    calibration = report["calibration_candidates"]
    if calibration.get("available"):
        print()
        print("## Calibration candidates")
        print(
            f"- current avg cashout: {calibration['current_summary_avg_cashout']}G"
        )
        for label, target in calibration["reward_targets"].items():
            reward_scale = calibration["reward_scale_to_targets"][label]
            price_scale = calibration["price_scale_to_targets"][label]
            print(
                f"- {label}: target {target}G, "
                f"reward scale x{reward_scale}, price scale x{price_scale}"
            )
    print()
    print("## Signals")
    for signal in report["signals"]:
        print(f"- {signal}")


def _print_stats(title: str, stats: dict[str, dict[str, Any]]) -> None:
    print()
    print(f"### {title}")
    for group, row in stats.items():
        print(
            f"- {group}: n={row['count']}, min={row['min']}, "
            f"avg={row['avg']}, median={row['median']}, max={row['max']}"
        )


if __name__ == "__main__":
    raise SystemExit(main())
