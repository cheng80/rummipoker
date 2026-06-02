# Ritual Card Image Overlap Review

Last updated: 2026-05-31

## Scope

- Target: 38 planned Ritual card emblems.
- New app resources: `assets/images/cards/rituals_4x/ritual_*.png`
- Preserved originals: `output/imagegen/planned_rituals/originals/ritual_*.png`
- Prompt manifest: `output/imagegen/planned_rituals/planned_ritual_prompts.jsonl`
- Visual review sheets:
  - `output/imagegen/planned_rituals/ritual_contact_sheet.png`
  - `output/imagegen/planned_rituals/ritual_overlap_contact_sheet.png`
  - `output/imagegen/planned_rituals/ritual_overlap_review.html`

## Result

- Generated count: 38 / 38.
- Exact file duplicate against existing `assets/images/cards/emblems_4x`: none.
- Exact duplicate inside new Ritual set: none.
- App resource size: 216x216, matching existing `emblems_4x`.
- Original generated size: 1254x1254, preserved separately.
- 2026-05-31 policy update: prompt manifest was regenerated after Ritual effects moved from temporary rank/color conversion to explicit selected-line hand-rank override. Existing bitmap assets still pass as first art candidates because their central silhouettes already read as rank/line ritual emblems.

## Overlap Notes

The new cards intentionally share the dark talisman frame language with existing Jester/Item/Gear emblems. The check focused on whether the central object reads as a reused card concept.

| New Ritual | Closest existing concepts | Decision |
|---|---|---|
| `line_memory` | `item_board_scrap`, `item_hand_scrap` | Keep. Memory orbit and line nodes are distinct from scrap/discard icons. |
| `cross_memory` | `item_overlap_pin`, `item_straight_study` | Keep with caution. Cross layout is similar to overlap tools, but the row/column memory cross is a valid ritual identity. |
| `keystone_copy` | `item_pair_splint`, `jester_abstract_jester` | Keep. Duplicate tile silhouette reads as deck copy. |
| `rank_echo` | `item_rank_chalk`, `item_flush_powder` | Keep. Echo card/tile silhouette differs from chalk/powder tools. |
| `fate_straight_high` | `item_coin_cache`, `item_merchant_stamp` | Keep existing legacy asset `ritual_gold_seal_stamp.png` until regenerated. Coin-seal hybrid is close by theme but not silhouette-identical. |
| `fate_three_kind_high` | `item_coupon_stamp`, `item_merchant_stamp` | Keep existing legacy asset `ritual_line_seal_stamp.png` until regenerated. Line-through-seal makes it a ritual mark, not a shop stamp. |
| `line_pruner` | `item_thin_caliper`, `item_board_scrap` | Keep. Pruning curve and fading line read differently from caliper/scrap. |
| `ritual_coupon` | `item_coupon_stamp`, `item_trade_ticket` | Keep with caution. Needs runtime label/type badge to avoid shop coupon confusion. |
| `ritual_lens` | `item_item_invoice`, `item_merchant_stamp` | Keep. Lens and offer silhouettes distinguish it from invoice/stamp. |
| `prune_vendor` | `item_thin_caliper`, `item_item_invoice` | Keep. Vendor tray and shears make it market/prune specific. |

## Regeneration Candidates

No forced regeneration now.

Optional later polish:

- `rank_concord`, `color_concord`, `off_color_rite`, `wild_thread`, `number_mask`: if card-frame preview does not clearly read as forced hand-rank override, regenerate with stronger triangle/flush/full-house/cross/crown silhouettes.
- `cross_memory`: make row/column memory less similar to `overlap_pin` if the runtime card frame makes both too close.
- `ritual_coupon`: add stronger ritual discount token shape if it reads too close to existing coupon/trade items.
- `fate_three_kind_high`: add stronger line-node context if it reads too close to generic stamp items at small card size.
