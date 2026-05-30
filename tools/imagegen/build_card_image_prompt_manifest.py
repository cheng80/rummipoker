#!/usr/bin/env python3
"""Build JSONL prompts for card art image generation.

This script does not call any image API. It prepares input for the
imagegen CLI fallback `generate-batch` path after user approval.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PROMPT_DOC = ROOT / "docs/current_system/CARD_ITEM_IMAGE_PROMPTS.md"
JESTERS_JSON = ROOT / "data/common/jesters_common_phase5.json"
ITEMS_JSON = ROOT / "data/common/items_common_v1.json"
DEFAULT_OUT = ROOT / "tmp/imagegen/card_emblem_prompts.jsonl"

CARD_MASTER_STYLE = (
    "Small game card illustration for Rummi Poker, aspect ratio 27:35, "
    "readable at 54x70 px. Dark talisman card background, muted green-black "
    "surface, thin gold or off-white ink linework, one central geometric "
    "magic-circle emblem, subtle Rummikub tile motif, clean silhouette, "
    "limited internal lines, premium roguelite deckbuilder item icon style."
)

EMBLEM_MASTER_STYLE = (
    "Standalone central emblem art for a small Rummi Poker card. Generate only "
    "the inner illustration area, not the full card. Square canvas. Flat dark "
    "green-black background matching the card illustration slot. Centered "
    "geometric magic-circle emblem, thin gold or off-white ink linework, subtle "
    "Rummikub tile motif, clean silhouette, limited internal lines, premium "
    "roguelite deckbuilder item icon style. Readable after being scaled into "
    "a 54x70 px card face."
)

CONSTRAINTS = (
    "No text. No letters. No numbers unless specifically part of abstract "
    "node arrangement. No poker suits. No playing-card layout. No card border. "
    "No rarity ribbon. No UI frame. No character portrait. No tiny decorative "
    "clutter. Use one strong silhouette and only 3 to 5 internal line details."
)

FAMILY_VISUALS = {
    "경제 Jester 문장": "small coin circle plus receipt or pouch silhouette rune",
    "경제/상점 문장": "stamp, coin, and price-tag rune with square stamp and gold circle",
    "고배수 Jester 문장": "amplifying lens emblem with nested circles, triangular prism, thick outer ring",
    "덱/손패 문장": "stacked Rummikub-like tiles with one tile rising upward, simple linear pouch or needle detail",
    "보드 이동 문장": "3x3 grid with directional arrow emblem; use clear movement direction",
    "색상 룬": "large color swatch bar with three small circular swatch nodes",
    "색상 반응 Jester 문장": "central elemental rune with four matching color shards",
    "성장/기억 Jester 문장": "spiral record rune with accumulating nodes around an orbit",
    "숫자 반응 Jester 문장": "rank-orbit emblem using small abstract nodes, not readable numerals",
    "안전/버림 문장": "shield, net, and slipping tile emblem with protective ring",
    "점수 증폭 문장": "charging socket or polish emblem with energy core and short gauge marks",
    "점수 Jester 문장": "score wave emblem with central star or lens and two outward rings",
    "족보 반응 Jester 문장": "tile-dot hand-rank emblem; pair as twin circles, triple as triangle, four-kind as cross, straight as rising diagonal, flush as same-color five-dot cluster",
    "족보 성장 문장": "planet-study orbit rune with hand-rank dot pattern arranged like small star orbits",
    "의식/라인 기억 문장": "board line stored inside a circular memory orbit, three to five line nodes and one small memory node",
    "의식/덱 복사 문장": "key Rummikub-like tile copied into a deck, central tile with one ghost duplicate and a short orbital arrow",
    "의식/각인 문장": "small square tile stamped with a circular seal, two or three tiny light points",
    "의식/숫자 변환 문장": "abstract dot pattern changing from one tile rank arrangement into another, no readable numerals",
    "의식/덱 압축 문장": "weak tile pruned from a line, small pruning curve or shear silhouette and fading tile",
    "의식/보드 위치 문장": "tiny board grid with one glowing center, corner, diagonal, or bridge node inside a ritual circle",
    "의식/마켓 렌즈 문장": "ritual lens focusing on two small card-offer silhouettes with thin focus lines",
    "칩 Jester 문장": "coin-shaped chip magic circle with outer ring, inner dot, short radial ticks",
}

RARITY_ACCENTS = {
    "common": "subtle brass accent",
    "uncommon": "cool silver-blue accent",
    "rare": "deep violet and gold accent",
    "legendary": "warm gold and ember accent",
}


def parse_prompt_table(doc: str, heading: str) -> dict[str, dict[str, str]]:
    start = doc.index(heading)
    next_heading = doc.find("\n## ", start + len(heading))
    section = doc[start: next_heading if next_heading != -1 else len(doc)]
    rows: dict[str, dict[str, str]] = {}
    for line in section.splitlines():
        if not line.startswith("|") or "`" not in line:
            continue
        cells = [cell.strip() for cell in line.strip("|").split("|")]
        if len(cells) < 4:
            continue
        family, raw_id, name, token = cells[:4]
        match = re.search(r"`([^`]+)`", raw_id)
        if not match:
            continue
        rows[match.group(1)] = {
            "family": family,
            "name": name,
            "token": token,
        }
    return rows


def load_catalogs() -> tuple[list[dict], list[dict]]:
    jesters = json.loads(JESTERS_JSON.read_text(encoding="utf-8"))
    items_payload = json.loads(ITEMS_JSON.read_text(encoding="utf-8"))
    return jesters, items_payload["items"]


def prompt_for(
    entry: dict,
    kind: str,
    meta: dict[str, str],
    *,
    mode: str,
) -> str:
    rarity = str(entry.get("rarity", "common")).lower()
    family = meta["family"]
    token = meta["token"]
    visual = FAMILY_VISUALS.get(family, "single central geometric rune")
    accent = RARITY_ACCENTS.get(rarity, RARITY_ACCENTS["common"])
    display_name = meta["name"] or entry.get("displayName") or entry["id"]
    slot_hint = entry.get("slotHint") or "jester"

    master_style = EMBLEM_MASTER_STYLE if mode == "emblem" else CARD_MASTER_STYLE
    canvas_line = (
        "Canvas: square inner illustration plate only. Leave generous padding "
        "around the emblem so a deterministic card renderer can crop or mask it."
        if mode == "emblem"
        else "Canvas: portrait 27:35 full card illustration."
    )

    return (
        f"{master_style}\n"
        f"{canvas_line}\n"
        f"Card id: {entry['id']}.\n"
        f"Card display name for reference only, do not render text: {display_name}.\n"
        f"Card kind: {kind}; slot/type: {slot_hint}; rarity: {rarity}.\n"
        f"Family: {family}.\n"
        f"Visual concept: {visual}.\n"
        f"Distinguishing token: {token}. Express this as abstract geometry, color, "
        f"tile dots, orbit nodes, or silhouette detail, not literal text.\n"
        f"Rarity accent: {accent}; keep background dark green-black.\n"
        f"{CONSTRAINTS}"
    )


def build_jobs(limit: int | None = None, *, mode: str = "emblem") -> list[dict]:
    doc = PROMPT_DOC.read_text(encoding="utf-8")
    jester_meta = parse_prompt_table(doc, "## 카드별 프롬프트 토큰: Jester")
    item_meta = parse_prompt_table(doc, "## 카드별 프롬프트 토큰: Item / Tool / Gear / Passive")
    jesters, items = load_catalogs()

    jobs: list[dict] = []
    missing: list[str] = []
    for kind, catalog, meta_by_id in (
        ("jester", jesters, jester_meta),
        ("item", items, item_meta),
    ):
        for entry in catalog:
            card_id = entry["id"]
            meta = meta_by_id.get(card_id)
            if meta is None:
                missing.append(f"{kind}:{card_id}")
                continue
            jobs.append(
                {
                    "id": card_id,
                    "kind": kind,
                    "prompt": prompt_for(entry, kind, meta, mode=mode),
                    "use_case": "stylized-concept",
                    "style": "dark talisman roguelite card emblem",
                    "composition": (
                        "square inner illustration plate, one centered emblem, generous padding"
                        if mode == "emblem"
                        else "portrait 27:35 card face, one centered emblem, generous padding"
                    ),
                    "constraints": CONSTRAINTS,
                    "size": "1024x1024" if mode == "emblem" else "1024x1536",
                    "out": f"{kind}_{card_id}.png",
                    "output": f"{mode}/{kind}s/{card_id}.png",
                }
            )
    if missing:
        raise SystemExit("Missing prompt metadata: " + ", ".join(missing))
    return jobs[:limit] if limit else jobs


def build_planned_ritual_jobs(limit: int | None = None, *, mode: str = "emblem") -> list[dict]:
    doc = PROMPT_DOC.read_text(encoding="utf-8")
    ritual_meta = parse_prompt_table(doc, "## 카드별 프롬프트 토큰: Planned Ritual")
    jobs: list[dict] = []
    for card_id, meta in ritual_meta.items():
        rarity = "uncommon"
        if any(token in meta["token"] for token in ("boss", "secondary", "scarce", "sealed", "wild", "high_risk", "line_pack")):
            rarity = "rare"
        if any(token in meta["token"] for token in ("legendary", "sacrifice", "high_risk_tradeoff")):
            rarity = "legendary"
        if any(token in meta["token"] for token in ("small_line", "endpoint", "discount")):
            rarity = "common"
        entry = {
            "id": card_id,
            "displayName": meta["name"],
            "rarity": rarity,
            "slotHint": "q",
        }
        jobs.append(
            {
                "id": card_id,
                "kind": "ritual",
                "prompt": prompt_for(entry, "planned_ritual", meta, mode=mode),
                "use_case": "stylized-concept",
                "style": "dark talisman roguelite ritual card emblem",
                "composition": (
                    "square inner illustration plate, one centered ritual emblem, generous padding"
                    if mode == "emblem"
                    else "portrait 27:35 card face, one centered ritual emblem, generous padding"
                ),
                "constraints": CONSTRAINTS,
                "size": "1024x1024" if mode == "emblem" else "1024x1536",
                "out": f"ritual_{card_id}.png",
                "output": f"{mode}/rituals/{card_id}.png",
            }
        )
    return jobs[:limit] if limit else jobs


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    parser.add_argument("--limit", type=int, default=None)
    parser.add_argument(
        "--mode",
        choices=("emblem", "card"),
        default="emblem",
        help="emblem generates only the inner art area; card keeps the older full-card prompt.",
    )
    parser.add_argument(
        "--planned-ritual",
        action="store_true",
        help="Build prompt jobs for Planned Ritual candidates from CARD_ITEM_IMAGE_PROMPTS.md.",
    )
    args = parser.parse_args()

    jobs = (
        build_planned_ritual_jobs(limit=args.limit, mode=args.mode)
        if args.planned_ritual
        else build_jobs(limit=args.limit, mode=args.mode)
    )
    out_path = args.out if args.out.is_absolute() else ROOT / args.out
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8") as fh:
        for job in jobs:
            fh.write(json.dumps(job, ensure_ascii=False) + "\n")

    print(f"wrote {len(jobs)} jobs -> {out_path.relative_to(ROOT)}")
    print("dry-run only: no image API called")


if __name__ == "__main__":
    main()
