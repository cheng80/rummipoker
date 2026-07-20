"""Balatro reference index를 우리 게임용 치환 backlog로 변환한다."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any


SOURCE_DEFAULT = Path("test/fixtures/research/balatro_reference_index.json")
OUT_DEFAULT = Path("test/fixtures/research/rummi_balatro_adaptation_backlog.json")

SECTION_CATEGORY = {
    "조커 강화 및 패널티": "edition_or_sticker",
    "일반": "jester",
    "희귀": "jester",
    "레어": "jester",
    "전설": "jester",
    "타로카드": "item_tarot",
    "행성카드": "item_planet",
    "유령카드": "item_spectral",
    "바우처": "item_voucher",
}

SECTION_RARITY = {
    "일반": "common",
    "희귀": "uncommon",
    "레어": "rare",
    "전설": "legendary",
}

DIRECT_JESTERS = {
    "Greedy Joker",
    "Lusty Joker",
    "Wrathful Joker",
    "Gluttonous Joker",
    "Jolly Joker",
    "Zany Joker",
    "Mad Joker",
    "Crazy Joker",
    "Droll Joker",
    "Sly Joker",
    "Wily Joker",
    "Clever Joker",
    "Devious Joker",
    "Crafty Joker",
    "Half Joker",
    "Banner",
    "Mystic Summit",
    "Scary Face",
    "Abstract Joker",
    "Delayed Gratification",
    "Gros Michel",
    "Even Steven",
    "Odd Todd",
    "Scholar",
    "Supernova",
    "Ride the Bus",
    "Blue Joker",
    "Green Joker",
    "Golden Joker",
    "Popcorn",
    "Walkie Talkie",
    "Smiley Face",
    "Joker Stencil",
    "Fibonacci",
    "Blackboard",
    "Cloud 9",
    "Rocket",
    "Bull",
    "Flash Card",
    "Spare Trousers",
    "Ramen",
    "Castle",
    "Acrobat",
    "The Duo",
    "The Trio",
    "The Family",
    "The Order",
    "The Tribe",
    "Stuntman",
}

ADAPT_JESTERS = {
    "Raised Fist",
    "Chaos the Clown",
    "Business Card",
    "Runner",
    "Splash",
    "Faceless Joker",
    "To Do List",
    "Red Card",
    "Square Joker",
    "Riff-Raff",
    "Photograph",
    "Reserved Parking",
    "Mail-In Rebate",
    "Fortune Teller",
    "Juggler",
    "Drunkard",
    "Swashbuckler",
    "Shoot the Moon",
    "Four Fingers",
    "Loyalty Card",
    "Dusk",
    "Space Joker",
    "Burglar",
    "Sixth Sense",
    "Constellation",
    "Hiker",
    "Card Sharp",
    "Shortcut",
    "Turtle Bean",
    "Erosion",
    "To the Moon",
    "Stone Joker",
    "DNA",
    "Vagabond",
    "Baron",
    "Obelisk",
    "Baseball Card",
    "Ancient Joker",
    "Campfire",
    "Wee Joker",
    "Hit the Road",
    "Burnt Joker",
}

DEFER_JESTERS = {
    "8 Ball",
    "Credit Card",
    "Misprint",
    "Egg",
    "Cavendish",
    "Hallucination",
    "Golden Ticket",
    "Hanging Chad",
    "Mime",
    "Ceremonial Dagger",
    "Marble Joker",
    "Hack",
    "Pareidolia",
    "Madness",
    "Vampire",
    "Midas Mask",
    "Luchador",
    "Gift Card",
    "Trading Card",
    "Diet Cola",
    "Seltzer",
    "Mr. Bones",
    "Sock and Buskin",
    "Troubadour",
    "Certification",
    "Smeared Joker",
    "Throwback",
    "Blueprint",
    "Invisible Joker",
    "Brainstorm",
    "Canio",
    "Triboulet",
    "Yorick",
    "Chicot",
    "Perkeo",
}

PLANET_HANDS = {
    "Mercury": "pair",
    "Venus": "three_of_a_kind",
    "Earth": "full_house",
    "Mars": "four_of_a_kind",
    "Jupiter": "flush",
    "Saturn": "straight",
    "Uranos": "two_pair",
    "Neptune": "straight_flush",
    "Pluto": "high_card",
    "Planet X": "five_of_a_kind",
    "Ceres": "flush_house",
    "Eris": "flush_five",
}

TAROT_TILE_MUTATORS = {
    "The Magician",
    "The Empress",
    "The Hierophant",
    "The Lovers",
    "The Chariot",
    "Justice",
    "Strength",
    "The Hanged Man",
    "Death",
    "The Devil",
    "The Tower",
    "The Star",
    "The Moon",
    "The Sun",
    "The World",
}

TAROT_ECONOMY = {"The Hermit", "Temperance"}
TAROT_GENERATORS = {
    "The Fool",
    "The High Priestess",
    "The Emperor",
    "The Wheel of Fortune",
    "Judgement",
}

VOUCHER_DIRECT = {
    "Overstock",
    "Overstock Plus",
    "Clearance Sale",
    "Liquidation",
    "Reroll Surplus",
    "Reroll Glut",
    "Grabber",
    "Nacho Tong",
    "Wasteful",
    "Recyclomancy",
    "Tarot Merchant",
    "Tarot Tycoon",
    "Planet Merchant",
    "Planet Tycoon",
    "Seed Money",
    "Money Tree",
    "Antimatter",
    "Paint Brush",
    "Palette",
}

VOUCHER_ADAPT = {
    "Hone",
    "Glow Up",
    "Crystal Ball",
    "Omen Globe",
    "Telescope",
    "Observatory",
    "Blank",
    "Magic Trick",
    "Illusion",
    "Hieroglyph",
    "Petroglyph",
    "Retcon",
    "Director's Cut",
}

EDITION_PRIORITY = {
    "Foil": 1,
    "Holographic": 1,
    "Polychrome": 1,
    "Negative": 2,
    "Eternal": 3,
    "Perishable": 3,
    "Rental": 3,
    "Base": 4,
}

ADAPTED_ID_OVERRIDES = {
    "Greedy Joker": "greedy_jester",
    "Lusty Joker": "lusty_jester",
    "Wrathful Joker": "wrathful_jester",
    "Gluttonous Joker": "gluttonous_jester",
    "Jolly Joker": "jolly_jester",
    "Zany Joker": "zany_jester",
    "Mad Joker": "mad_jester",
    "Crazy Joker": "crazy_jester",
    "Droll Joker": "droll_jester",
    "Sly Joker": "sly_jester",
    "Wily Joker": "wily_jester",
    "Clever Joker": "clever_jester",
    "Devious Joker": "devious_jester",
    "Crafty Joker": "crafty_jester",
    "Half Joker": "half_jester",
    "Abstract Joker": "abstract_jester",
    "Green Joker": "green_jester",
    "Blue Joker": "blue_jester",
    "Scary Face": "scary_face",
    "Smiley Face": "smiley_face",
    "Joker Stencil": "jester_stencil",
    "Golden Joker": "golden_jester",
}


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Build our game adaptation backlog from crawled Balatro names."
    )
    parser.add_argument("--source", type=Path, default=SOURCE_DEFAULT)
    parser.add_argument("--out", type=Path, default=OUT_DEFAULT)
    args = parser.parse_args()

    source = json.loads(args.source.read_text(encoding="utf-8"))
    items = [_adapt_item(item) for item in source["items"]]
    summary = _build_summary(items)
    payload = {
        "schema_version": 1,
        "source": str(args.source),
        "mapping_rules": {
            "suit_to_tile_color": {
                "diamonds": "yellow",
                "hearts": "red",
                "spades": "blue",
                "clubs": "black",
            },
            "face_card_to_tile_number": [11, 12, 13],
            "rank_to_tile_number": "1..13",
            "chips": "base_score/chips_bonus",
            "mult": "additive_multiplier",
            "xmult": "multiplicative_multiplier",
            "money": "gold",
            "ante": "station_index_or_station_curve",
        },
        "priority_meaning": {
            "1": "우선 구현: 현재 S5/S6 병목과 직접 연결되거나 runtime 확장이 작음",
            "2": "다음 구현: 시스템은 필요하지만 핵심 병목 해결 뒤 적용",
            "3": "차후 계획: 복사/파괴/인장/복잡한 카드 변형 등 기반 시스템 필요",
            "4": "보존만: 원본 호환성 또는 현재 미사용 족보/기본 항목",
        },
        "summary": summary,
        "items": items,
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(args.out)
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return 0


def _adapt_item(item: dict[str, Any]) -> dict[str, Any]:
    en_name = item["en_name"]
    section = item["section"]
    category = SECTION_CATEGORY.get(section, "unknown")
    base = {
        "source_id": item["source_id"],
        "source_section": section,
        "source_ko_name": item["ko_name"],
        "source_en_name": en_name,
        "adapted_id": ADAPTED_ID_OVERRIDES.get(en_name, _to_id(en_name)),
        "adapted_category": category,
        "adapted_rarity": SECTION_RARITY.get(section),
        "mapping_status": "defer",
        "runtime_status": "needs_system",
        "priority": 3,
        "effect_family": "unknown",
        "notes": [],
    }

    if category == "jester":
        _classify_jester(base, en_name)
    elif category == "edition_or_sticker":
        _classify_edition(base, en_name)
    elif category == "item_planet":
        _classify_planet(base, en_name)
    elif category == "item_tarot":
        _classify_tarot(base, en_name)
    elif category == "item_voucher":
        _classify_voucher(base, en_name)
    elif category == "item_spectral":
        _classify_spectral(base, en_name)
    return base


def _classify_jester(row: dict[str, Any], en_name: str) -> None:
    if en_name in DIRECT_JESTERS:
        row.update(
            mapping_status="direct",
            runtime_status="catalog_or_runtime_extension",
            priority=1,
            effect_family=_jester_effect_family(en_name),
        )
        return
    if en_name in ADAPT_JESTERS:
        row.update(
            mapping_status="adapt",
            runtime_status="small_system_extension",
            priority=2,
            effect_family=_jester_effect_family(en_name),
        )
        return
    if en_name in DEFER_JESTERS:
        row.update(
            mapping_status="defer",
            runtime_status="needs_large_system",
            priority=3,
            effect_family=_jester_effect_family(en_name),
        )
        return
    row["notes"].append("미분류 Jester: 구현 전 효과 계열 확인 필요")


def _jester_effect_family(en_name: str) -> str:
    color_names = {
        "Greedy Joker",
        "Lusty Joker",
        "Wrathful Joker",
        "Gluttonous Joker",
    }
    hand_mult = {
        "Jolly Joker",
        "Zany Joker",
        "Mad Joker",
        "Crazy Joker",
        "Droll Joker",
        "The Duo",
        "The Trio",
        "The Family",
        "The Order",
        "The Tribe",
    }
    hand_chips = {"Sly Joker", "Wily Joker", "Clever Joker", "Devious Joker", "Crafty Joker"}
    if en_name in color_names:
        return "tile_color_scored_mult"
    if en_name in hand_mult:
        return "hand_rank_mult_or_xmult"
    if en_name in hand_chips:
        return "hand_rank_chips"
    if en_name in {"Fibonacci", "Even Steven", "Odd Todd", "Scholar", "Walkie Talkie", "Scary Face", "Smiley Face"}:
        return "tile_number_scored"
    if en_name in {"Supernova", "Ride the Bus", "Green Joker", "Flash Card", "Spare Trousers", "Castle", "Runner", "Square Joker"}:
        return "stateful_growth"
    if en_name in {"Banner", "Mystic Summit", "Blue Joker", "Bull"}:
        return "resource_scaled_score"
    if en_name in {"Golden Joker", "Delayed Gratification", "Rocket", "To the Moon", "Cloud 9"}:
        return "economy"
    if en_name in {"Juggler", "Drunkard", "Burglar", "Troubadour"}:
        return "resource_capacity"
    if en_name in {"Foil", "Holographic", "Polychrome"}:
        return "edition_score_modifier"
    return "special"


def _classify_edition(row: dict[str, Any], en_name: str) -> None:
    row.update(
        adapted_category="edition",
        adapted_rarity=None,
        mapping_status="adapt",
        runtime_status="needs_edition_layer",
        priority=EDITION_PRIORITY.get(en_name, 3),
        effect_family={
            "Foil": "flat_chips_bonus",
            "Holographic": "flat_mult_bonus",
            "Polychrome": "xmult_bonus",
            "Negative": "slot_modifier",
            "Eternal": "sell_destroy_lock",
            "Perishable": "round_limited_disable",
            "Rental": "upkeep_cost",
            "Base": "none",
        }.get(en_name, "edition_modifier"),
    )


def _classify_planet(row: dict[str, Any], en_name: str) -> None:
    hand = PLANET_HANDS.get(en_name)
    row.update(
        mapping_status="direct" if hand not in {"high_card", "five_of_a_kind", "flush_house", "flush_five"} else "defer",
        runtime_status="needs_hand_rank_level_system",
        priority=1 if hand not in {"high_card", "five_of_a_kind", "flush_house", "flush_five"} else 4,
        effect_family="hand_rank_level",
        adapted_payload={"hand_rank": hand},
    )
    if hand == "high_card":
        row["notes"].append("현재 사용하지 않는 족보라 원본 보존 후 보류")
    elif hand in {"five_of_a_kind", "flush_house", "flush_five"}:
        row["notes"].append("중복/특수 족보 확장 시 재검토")


def _classify_tarot(row: dict[str, Any], en_name: str) -> None:
    if en_name in TAROT_TILE_MUTATORS:
        row.update(
            mapping_status="adapt",
            runtime_status="needs_tile_mutation_item",
            priority=1,
            effect_family="tile_mutation_or_enhancement",
        )
    elif en_name in TAROT_ECONOMY:
        row.update(
            mapping_status="direct",
            runtime_status="catalog_or_runtime_extension",
            priority=1,
            effect_family="economy",
        )
    elif en_name in TAROT_GENERATORS:
        row.update(
            mapping_status="adapt",
            runtime_status="needs_offer_or_item_generation",
            priority=2,
            effect_family="content_generation",
        )
    else:
        row.update(
            mapping_status="defer",
            runtime_status="needs_system",
            priority=3,
            effect_family="special",
        )


def _classify_spectral(row: dict[str, Any], en_name: str) -> None:
    row.update(
        mapping_status="adapt",
        runtime_status="needs_high_risk_item_layer",
        priority=3,
        effect_family="high_risk_transform",
    )
    if en_name in {"Black Hole", "The Soul"}:
        row["priority"] = 4
        row["notes"].append("전설/전체 족보 계열이라 후순위")


def _classify_voucher(row: dict[str, Any], en_name: str) -> None:
    if en_name in VOUCHER_DIRECT:
        row.update(
            mapping_status="direct",
            runtime_status="passive_relic_or_market_modifier",
            priority=1,
            effect_family="run_wide_modifier",
        )
    elif en_name in VOUCHER_ADAPT:
        row.update(
            mapping_status="adapt",
            runtime_status="needs_voucher_layer",
            priority=2,
            effect_family="run_wide_modifier",
        )
    else:
        row.update(
            mapping_status="defer",
            runtime_status="needs_system",
            priority=3,
            effect_family="special",
        )


def _build_summary(items: list[dict[str, Any]]) -> dict[str, Any]:
    summary: dict[str, Any] = {
        "total": len(items),
        "by_priority": {},
        "by_category": {},
        "by_mapping_status": {},
    }
    for item in items:
        _inc(summary["by_priority"], str(item["priority"]))
        _inc(summary["by_category"], item["adapted_category"])
        _inc(summary["by_mapping_status"], item["mapping_status"])
    return summary


def _inc(target: dict[str, int], key: str) -> None:
    target[key] = target.get(key, 0) + 1


def _to_id(name: str) -> str:
    return re.sub(r"_+", "_", re.sub(r"[^a-z0-9]+", "_", name.lower())).strip("_")


if __name__ == "__main__":
    raise SystemExit(main())
