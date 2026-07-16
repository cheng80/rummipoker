#!/usr/bin/env python3
"""Build a deterministic card-frame preview HTML for generated emblem art."""

from __future__ import annotations

import html
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PROMPT_DOC = ROOT / "docs/tools/card_assets/CARD_ITEM_IMAGE_PROMPTS.md"
JESTERS_JSON = ROOT / "data/common/jesters_common_phase5.json"
ITEMS_JSON = ROOT / "data/common/items_common_v1.json"
MANIFEST_JSONL = ROOT / "tmp/imagegen/card_emblem_prompts.jsonl"
IMAGE_DIR = ROOT / "output/imagegen/card_emblems_builtin/all"
OUT_HTML = ROOT / "output/imagegen/card_emblems_builtin/card_preview_list.html"


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
        if match:
            rows[match.group(1)] = {
                "family": family,
                "name": name,
                "token": token,
            }
    return rows


def load_catalog_meta() -> dict[tuple[str, str], dict[str, str]]:
    doc = PROMPT_DOC.read_text(encoding="utf-8")
    prompt_meta = {
        "jester": parse_prompt_table(doc, "## 카드별 프롬프트 토큰: Jester"),
        "item": parse_prompt_table(doc, "## 카드별 프롬프트 토큰: Item / Tool / Gear / Passive"),
    }
    jesters = json.loads(JESTERS_JSON.read_text(encoding="utf-8"))
    items = json.loads(ITEMS_JSON.read_text(encoding="utf-8"))["items"]
    meta: dict[tuple[str, str], dict[str, str]] = {}
    for kind, entries in (("jester", jesters), ("item", items)):
        for entry in entries:
            card_id = entry["id"]
            table = prompt_meta[kind].get(card_id, {})
            meta[(kind, card_id)] = {
                "name": table.get("name") or entry.get("displayName") or card_id,
                "rarity": str(entry.get("rarity", "common")).lower(),
                "family": table.get("family", ""),
                "token": table.get("token", ""),
                "type": str(entry.get("slotHint") or entry.get("type") or kind),
            }
    return meta


def card_html(job: dict, info: dict[str, str]) -> str:
    image_name = html.escape(job["out"])
    card_id = html.escape(job["id"])
    display_name = html.escape(info["name"])
    rarity = html.escape(info["rarity"])
    family = html.escape(info["family"])
    kind = html.escape(job["kind"])
    card_type = html.escape(info["type"])
    badge_label = "J" if job["kind"] == "jester" else {
        "q": "Q",
        "utility": "T",
        "gear": "G",
        "passive": "P",
    }.get(info["type"], "I")
    badge_title = "Jester" if job["kind"] == "jester" else {
        "q": "Q-Slot",
        "utility": "Tool",
        "gear": "Gear",
        "passive": "Passive",
    }.get(info["type"], "Item")
    return f"""
      <article class="card-tile" data-kind="{kind}" data-rarity="{rarity}">
        <div class="card-frame {rarity} {kind} type-{html.escape(info["type"])}">
          <div class="rarity-bar"></div>
          <div class="type-badge" title="{html.escape(badge_title)}">{html.escape(badge_label)}</div>
          <div class="art-slot">
            <img src="all/{image_name}" alt="">
          </div>
          <div class="label">
            <div class="name">{display_name}</div>
            <div class="meta">{card_type}</div>
          </div>
        </div>
        <div class="caption">
          <strong>{card_id}</strong>
          <span>{rarity} · {family}</span>
        </div>
      </article>"""


def section_html(title: str, jobs: list[dict], meta: dict[tuple[str, str], dict[str, str]]) -> str:
    cards = "\n".join(card_html(job, meta[(job["kind"], job["id"])]) for job in jobs)
    return f"""
    <section>
      <header>
        <h2>{html.escape(title)}</h2>
        <p>{len(jobs)} cards</p>
      </header>
      <div class="grid">{cards}
      </div>
    </section>"""


def main() -> None:
    jobs = [json.loads(line) for line in MANIFEST_JSONL.read_text(encoding="utf-8").splitlines()]
    missing = [job["out"] for job in jobs if not (IMAGE_DIR / job["out"]).exists()]
    if missing:
        raise SystemExit("Missing generated images: " + ", ".join(missing))

    meta = load_catalog_meta()
    jester_jobs = [job for job in jobs if job["kind"] == "jester"]
    item_jobs = [job for job in jobs if job["kind"] == "item"]

    html_text = f"""<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Rummi Poker Card Emblem Composite Preview</title>
  <style>
    :root {{
      color-scheme: dark;
      --page: #0b0f0d;
      --panel: #101713;
      --card: #15231d;
      --slot: #0d1713;
      --ink: #d8bd76;
      --line: #304239;
      --muted: #93a79a;
      --text: #f1e7c2;
    }}

    * {{ box-sizing: border-box; }}

    body {{
      margin: 0;
      background: var(--page);
      color: var(--text);
      font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    }}

    main {{
      width: min(1380px, 100%);
      margin: 0 auto;
      padding: 28px;
    }}

    .page-title {{
      display: flex;
      justify-content: space-between;
      align-items: end;
      gap: 20px;
      margin-bottom: 26px;
      border-bottom: 1px solid #27362f;
      padding-bottom: 18px;
    }}

    h1, h2, p {{ margin: 0; }}

    h1 {{
      font-size: 22px;
      font-weight: 700;
      letter-spacing: 0;
    }}

    .summary {{
      color: var(--muted);
      font-size: 13px;
      text-align: right;
    }}

    section + section {{ margin-top: 38px; }}

    header {{
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 14px;
    }}

    h2 {{
      font-size: 16px;
      font-weight: 700;
    }}

    header p {{
      color: var(--muted);
      font-size: 12px;
    }}

    .grid {{
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(132px, 1fr));
      gap: 18px 14px;
    }}

    .card-tile {{
      min-width: 0;
      display: grid;
      justify-items: center;
      gap: 8px;
    }}

    .card-frame {{
      width: 108px;
      height: 140px;
      border: 2px solid #626a66;
      border-radius: 8px;
      background:
        linear-gradient(180deg, #1a2b24, var(--card)),
        var(--card);
      box-shadow: inset 0 0 0 1px #26352e, 0 10px 22px #0008;
      padding: 6px 7px 7px;
      display: grid;
      grid-template-rows: 10px 82px 1fr;
      gap: 5px;
      position: relative;
    }}

    .rarity-bar {{
      width: calc(100% - 22px);
      height: 10px;
      border-radius: 4px;
      box-shadow: inset 0 0 0 1px #ffffff38;
      background: linear-gradient(90deg, #3f4642, #7f8983, #4b534e);
    }}

    .type-badge {{
      position: absolute;
      top: 6px;
      right: 7px;
      width: 18px;
      height: 10px;
      border-radius: 4px;
      display: grid;
      place-items: center;
      z-index: 2;
      color: #fff8d7;
      font-size: 7px;
      font-weight: 800;
      line-height: 1;
      box-shadow: inset 0 0 0 1px #ffffff55;
      background: #75603a;
    }}

    .jester .type-badge {{
      background: linear-gradient(180deg, #8b4fd1, #51327f);
    }}

    .type-q .type-badge {{
      background: linear-gradient(180deg, #3f89d7, #22507f);
    }}

    .type-utility .type-badge {{
      background: linear-gradient(180deg, #b0843c, #6c4c20);
    }}

    .type-gear .type-badge {{
      background: linear-gradient(180deg, #6f8994, #3c555f);
    }}

    .type-passive .type-badge {{
      background: linear-gradient(180deg, #4f9a6d, #2e6447);
    }}

    .uncommon {{
      border-color: #5ab8c6;
    }}

    .uncommon .rarity-bar {{
      background: linear-gradient(90deg, #246a79, #87e1ed, #2f8290);
    }}

    .rare {{
      border-color: #9c86d7;
    }}

    .rare .rarity-bar {{
      background: linear-gradient(90deg, #5d4aa0, #d6b46a, #5d4aa0);
    }}

    .legendary {{
      border-color: #e39a45;
    }}

    .legendary .rarity-bar {{
      background: linear-gradient(90deg, #9c4c23, #f5c76d, #d9782c);
    }}

    .art-slot {{
      border-radius: 6px;
      overflow: hidden;
      background: var(--slot);
      box-shadow: inset 0 0 0 1px var(--line), inset 0 0 18px #0009;
      display: grid;
      place-items: center;
      position: relative;
    }}

    .art-slot img {{
      width: 68px;
      height: 68px;
      object-fit: contain;
      display: block;
    }}

    .label {{
      min-width: 0;
      display: grid;
      align-content: center;
      gap: 2px;
    }}

    .name {{
      color: #f0dfaa;
      font-size: 10px;
      line-height: 1.12;
      text-align: center;
      overflow-wrap: anywhere;
    }}

    .meta {{
      color: var(--muted);
      font-size: 8px;
      line-height: 1;
      text-align: center;
      text-transform: uppercase;
    }}

    .caption {{
      width: 124px;
      display: grid;
      gap: 2px;
      text-align: center;
    }}

    .caption strong {{
      font-size: 11px;
      font-weight: 650;
      overflow-wrap: anywhere;
    }}

    .caption span {{
      color: var(--muted);
      font-size: 10px;
      line-height: 1.2;
    }}

    @media (max-width: 560px) {{
      main {{ padding: 18px 12px; }}
      .page-title {{
        align-items: start;
        flex-direction: column;
      }}
      .summary {{ text-align: left; }}
      .grid {{
        grid-template-columns: repeat(auto-fill, minmax(112px, 1fr));
      }}
    }}
  </style>
</head>
<body>
  <main>
    <div class="page-title">
      <div>
        <h1>Rummi Poker Card Emblem Composite Preview</h1>
      </div>
      <p class="summary">97 generated emblems · deterministic card frame · 2x display scale</p>
    </div>
{section_html("Jester", jester_jobs, meta)}
{section_html("Item / Tool / Gear / Passive", item_jobs, meta)}
  </main>
</body>
</html>
"""
    OUT_HTML.parent.mkdir(parents=True, exist_ok=True)
    OUT_HTML.write_text(html_text, encoding="utf-8")
    print(f"wrote {OUT_HTML.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
