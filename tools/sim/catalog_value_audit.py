#!/usr/bin/env python3
"""카탈로그 가격과 효과 역할군의 불일치 후보를 점검한다."""

from __future__ import annotations

import argparse
import json
import statistics
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any, Iterable


DEFAULT_ITEM_CATALOG = Path("data/common/items_common_v1.json")
DEFAULT_JESTER_CATALOG = Path("data/common/jesters_common_phase5.json")
MARKET_PRICE_SCALE_NUMERATOR = 11
MARKET_PRICE_SCALE_DENOMINATOR = 5
SHOP_BASE_REROLL_COST = 5


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Item/Jester 카탈로그 가격, rarity, 효과 역할군을 점검합니다.",
    )
    parser.add_argument("--items", type=Path, default=DEFAULT_ITEM_CATALOG)
    parser.add_argument("--jesters", type=Path, default=DEFAULT_JESTER_CATALOG)
    parser.add_argument("--json-out", type=Path)
    args = parser.parse_args()

    items = _load_items(args.items)
    jesters = _load_jesters(args.jesters)
    report = build_report(items=items, jesters=jesters)

    if args.json_out is not None:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        args.json_out.write_text(
            json.dumps(report, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

    print_report(report)
    return 0


def build_report(
    *,
    items: list[dict[str, Any]],
    jesters: list[dict[str, Any]],
) -> dict[str, Any]:
    item_rows = [_item_value_row(item) for item in items]
    jester_rows = [_jester_value_row(jester) for jester in jesters]
    all_rows = item_rows + jester_rows
    return {
        "schema_version": 1,
        "summary": {
            "item_count": len(item_rows),
            "jester_count": len(jester_rows),
            "catalog_count": len(all_rows),
        },
        "price_by_kind": _group_price_stats(all_rows, "kind"),
        "price_by_rarity": _group_price_stats(all_rows, "rarity"),
        "price_by_role": _group_price_stats(all_rows, "role"),
        "price_by_kind_role": _group_price_stats(all_rows, "kind_role"),
        "outliers": _outliers(all_rows),
        "rows": sorted(
            all_rows,
            key=lambda row: (
                str(row["kind"]),
                str(row["role"]),
                int(row["price"]),
                str(row["id"]),
            ),
        ),
    }


def print_report(report: dict[str, Any]) -> None:
    summary = report["summary"]
    print("# Catalog value audit")
    print()
    print(
        f"- items: {summary['item_count']}, "
        f"jesters: {summary['jester_count']}, total: {summary['catalog_count']}"
    )
    _print_stats("Price by role", report["price_by_role"])
    _print_stats("Price by kind/role", report["price_by_kind_role"])

    outliers = report["outliers"]
    print()
    print("## Outliers")
    for key, title in [
        ("self_refund_items", "self-refund item candidates"),
        ("cheap_growth_engines", "cheap growth engine candidates"),
        ("cheap_high_impact", "cheap high-impact candidates"),
        ("expensive_low_impact", "expensive low-impact candidates"),
        ("sell_ratio_high", "high sell-ratio candidates"),
    ]:
        rows = outliers.get(key, [])
        print(f"- {title}: {len(rows)}")
        for row in rows[:10]:
            detail = row.get("detail") or row.get("effect") or ""
            print(
                "  - "
                f"{row['kind']}:{row['id']} {row['price']}G "
                f"(effective {row['effective_price']}G) "
                f"({row['rarity']}, {row['role']}) {detail}"
            )


def _print_stats(title: str, stats: dict[str, dict[str, Any]]) -> None:
    print()
    print(f"## {title}")
    for key, row in sorted(stats.items()):
        print(
            f"- {key}: n={row['count']}, min={row['min']}, "
            f"avg={row['avg']}, median={row['median']}, max={row['max']}"
        )


def _load_items(path: Path) -> list[dict[str, Any]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    rows = data.get("items") if isinstance(data, dict) else data
    if not isinstance(rows, list):
        raise ValueError(f"Invalid item catalog: {path}")
    return [row for row in rows if isinstance(row, dict)]


def _load_jesters(path: Path) -> list[dict[str, Any]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    rows = data if isinstance(data, list) else data.get("jesters")
    if not isinstance(rows, list):
        raise ValueError(f"Invalid Jester catalog: {path}")
    return [row for row in rows if isinstance(row, dict)]


def _item_value_row(item: dict[str, Any]) -> dict[str, Any]:
    effect = item.get("effect") if isinstance(item.get("effect"), dict) else {}
    role = _item_role(item, effect)
    price = _int(item.get("basePrice"))
    effective_price = _effective_market_price(price)
    sell_price = _int(item.get("sellPrice"))
    immediate_value = _item_immediate_value(effect)
    return {
        "kind": "item",
        "id": str(item.get("id") or ""),
        "rarity": str(item.get("rarity") or "unknown"),
        "role": role,
        "kind_role": f"item:{role}",
        "price": price,
        "effective_price": effective_price,
        "sell_price": sell_price,
        "sell_ratio": round(sell_price / price, 3) if price > 0 else 0,
        "effect": str(effect.get("op") or ""),
        "effect_timing": str(effect.get("timing") or ""),
        "amount": effect.get("amount"),
        "immediate_value": immediate_value,
        "detail": str(item.get("effectText") or ""),
    }


def _jester_value_row(card: dict[str, Any]) -> dict[str, Any]:
    role = _jester_role(card)
    price = _int(card.get("baseCost"))
    effective_price = _effective_market_price(price)
    return {
        "kind": "jester",
        "id": str(card.get("id") or ""),
        "rarity": str(card.get("rarity") or "unknown"),
        "role": role,
        "kind_role": f"jester:{role}",
        "price": price,
        "effective_price": effective_price,
        "sell_price": max(1, price // 2) if price > 0 else 0,
        "sell_ratio": round((max(1, price // 2) / price), 3)
        if price > 0
        else 0,
        "effect": str(card.get("effectType") or ""),
        "effect_timing": str(card.get("trigger") or ""),
        "amount": card.get("value") if card.get("value") is not None else card.get("xValue"),
        "immediate_value": 0,
        "detail": str(card.get("effectText") or ""),
    }


def _item_role(item: dict[str, Any], effect: dict[str, Any]) -> str:
    op = str(effect.get("op") or "")
    tags = {str(tag) for tag in item.get("tags", []) if isinstance(tag, str)}
    if op in {
        "gain_gold",
        "free_next_reroll",
        "discount_next_purchase",
        "sell_price_bonus",
    }:
        return "economy"
    if op in {
        "add_board_discard",
        "add_hand_discard",
        "add_board_move",
        "increase_hand_size",
        "increase_hand_size_with_discard_penalty",
    } or tags.intersection({"discard", "move", "hand_size"}):
        return "resource"
    if op in {"peek_deck_discard_one", "undo_last_board_move"} or tags.intersection(
        {"deck", "selection", "undo"}
    ):
        return "deck_control"
    if op in {"chips_bonus", "mult_bonus", "xmult_bonus"}:
        return "score_boost"
    if "market" in tags or op in {
        "extra_item_offer_slot",
        "reroll_item_offers_only",
    }:
        return "market"
    if "boss" in tags:
        return "boss_tool"
    if "relic" in tags or item.get("type") == "relic":
        return "relic"
    return "utility"


def _jester_role(card: dict[str, Any]) -> str:
    effect_type = str(card.get("effectType") or "")
    trigger = str(card.get("trigger") or "")
    condition_value = str(card.get("conditionValue") or "")
    if effect_type == "stateful_growth":
        if condition_value == "mult_decay":
            return "tempo_score_boost"
        return "growth_engine"
    if effect_type == "xmult_bonus":
        return "xmult_engine"
    if effect_type in {"chips_bonus", "mult_bonus"}:
        return "score_boost"
    if effect_type == "economy" or trigger == "onRoundEnd":
        return "economy"
    return "utility"


def _item_immediate_value(effect: dict[str, Any]) -> float:
    op = str(effect.get("op") or "")
    amount = _float(effect.get("amount"))
    if op == "gain_gold":
        return amount
    if op == "free_next_reroll":
        return float(SHOP_BASE_REROLL_COST)
    if op == "discount_next_purchase":
        return amount
    return 0.0


def _group_price_stats(
    rows: Iterable[dict[str, Any]],
    group_key: str,
) -> dict[str, dict[str, Any]]:
    groups: dict[str, list[int]] = defaultdict(list)
    for row in rows:
        price = _int(row.get("price"))
        if price > 0:
            groups[str(row.get(group_key) or "unknown")].append(price)
    return {key: _numeric_stats(values) for key, values in groups.items()}


def _numeric_stats(values: list[int]) -> dict[str, Any]:
    counts = Counter(values)
    return {
        "count": len(values),
        "min": min(values),
        "max": max(values),
        "avg": round(statistics.mean(values), 2),
        "median": statistics.median(values),
        "price_counts": dict(sorted(counts.items())),
    }


def _outliers(rows: list[dict[str, Any]]) -> dict[str, list[dict[str, Any]]]:
    common_prices = [
        _int(row["price"])
        for row in rows
        if row["rarity"] == "common" and _int(row["price"]) > 0
    ]
    common_median = statistics.median(common_prices) if common_prices else 0
    return {
        "self_refund_items": [
            row
            for row in rows
            if row["kind"] == "item"
            and _float(row["immediate_value"])
            >= _int(row["effective_price"])
            > 0
        ],
        "cheap_growth_engines": [
            row
            for row in rows
            if row["role"] == "growth_engine"
            and common_median
            and _int(row["price"]) <= common_median + 2
        ],
        "cheap_high_impact": [
            row
            for row in rows
            if row["role"] in {"growth_engine", "xmult_engine", "market"}
            and common_median
            and _int(row["price"]) <= common_median + 2
        ],
        "expensive_low_impact": [
            row
            for row in rows
            if row["role"] in {"utility", "economy"}
            and _int(row["price"]) >= common_median + 5
        ],
        "sell_ratio_high": [
            row for row in rows if _float(row["sell_ratio"]) > 0.55
        ],
    }


def _int(value: Any) -> int:
    return int(value) if isinstance(value, (int, float)) else 0


def _effective_market_price(base_price: int) -> int:
    if base_price <= 0:
        return 0
    return round(
        base_price * MARKET_PRICE_SCALE_NUMERATOR / MARKET_PRICE_SCALE_DENOMINATOR
    )


def _float(value: Any) -> float:
    return float(value) if isinstance(value, (int, float)) else 0.0


if __name__ == "__main__":
    raise SystemExit(main())
