# Market / Item Smoke Checklist

> GCSE role: `Execution`
> Purpose: Market, reroll, and item-slot UI smoke scenarios to run after related changes.

## Automated Baseline

- `flutter analyze`
- `flutter test`
- Targeted suites when iterating:
  - `flutter test test/logic/item_effect_runtime_test.dart`
  - `flutter test test/logic/rummi_market_facade_test.dart`
  - `flutter test test/providers/game_session_notifier_test.dart`
  - `flutter test test/views/game/widgets/game_shop_screen_test.dart`
  - `flutter test test/views/game/widgets/game_station_read_path_test.dart`

## Targeted Market Buckets

| Bucket | Check | Primary tests / fixture |
| --- | --- | --- |
| `reroll_policy` | S1 first Market free reroll copy, stale first-reroll cleanup, item/passive discounted reroll copy and cost | `game_shop_reroll_confirmation_test.dart`, `game_shop_discounted_reroll_test.dart`, `rummi_market_facade_test.dart`, `/game?fixture=stale_first_reroll_market` |
| `tool_use_feedback` | Tool use source item name, result label, Gold HUD `+NG` duration, non-Gold use feedback | `game_shop_use_feedback_test.dart`, `game_shop_growth_use_feedback_test.dart`, `game_shop_non_gold_use_flight_test.dart`, `game_shop_screen_trade_ticket_test.dart`, `/game?fixture=market_item_motion_eye_check` |
| `offer_stability` | Bought Item offer leaves an empty slot until reroll/next Market; `trade_ticket` rerolls Item candidates only | `rummi_market_facade_test.dart`, `debug_run_fixture_service_test.dart`, `game_shop_screen_trade_ticket_test.dart` |
| `slot_height` | Jester/Slots and Tool/Gear tab sections keep matching outer heights; cards animate without moving outer containers | `/game?fixture=market_item_motion_eye_check` browser eye-check |

### 2026-06-10 Closing Status

- `tool_use_feedback`: Closed. Browser fixture confirms Tool use source/result feedback, Gold `+NG` placement, and post-use selection clear.
- `offer_stability`: Closed. Browser fixture confirms a bought Tool offer is removed without immediate refill, and `trade_ticket` rerolls Item candidates only.
- `slot_height`: Closed. Browser fixture confirms `Jester / Slots` and `Tool / Gear` tab sections keep stable outer heights during tab switch, buy, and Tool use feedback.

Browser evidence:

- `/tmp/rummi_offer_stability_tool_before_buy.png`
- `/tmp/rummi_offer_stability_after_buy.png`
- `/tmp/rummi_trade_ticket_tool_before.png`
- `/tmp/rummi_trade_ticket_tool_after.png`
- `/tmp/rummi_trade_ticket_jester_before.png`
- `/tmp/rummi_trade_ticket_jester_after.png`
- `/tmp/rummi_trade_ticket_tile_before.png`
- `/tmp/rummi_trade_ticket_tile_after.png`

## Market Flow Smoke

- Enter Market after cash-out and verify the title is `Market`, not `Jester Market`.
- Verify top Gold chip uses the coin icon, right-aligned number, and current run Gold.
- Verify `Jester / Slots` tab shows:
  - Jester card offers.
  - Q-slot offers.
  - passive relic offers.
  - `Q1-Q3` and `P1-P2` owned slots in the upper slot section.
- Verify `Tool / Gear` tab shows:
  - Tool offers.
  - Gear offers.
  - `T1-T3` and `G1-G2` owned slots in the upper slot section.
  - Stack count badges such as `x2` are centered at the bottom of occupied cards.
- Buy a Q-slot item and verify:
  - Gold decreases by item price.
  - Item appears in the next open Q slot.
  - Bought offer disappears from the current Market offer list.
- Buy a passive relic and verify:
  - Item appears in `P1` or `P2`.
  - Passive relays into battle item zone.
- Buy a Tool and verify:
  - Item appears under `Tool / Gear`, not Q/P slots.
  - It remains owned until a matching market-use hook consumes it.
- Buy a Gear and verify:
  - Item appears under `Tool / Gear`, not Q/P slots.
  - It appears in battle item zone under the Gear tab.

## Reroll Smoke

- S1 basic first Market shows `첫 리롤 무료`, not `리롤 5→0`.
- S1 basic first Market reroll confirmation says `상점 입장 보너스로 첫 리롤은 무료입니다.`
- The S1 basic first Market bonus is Market-wide once: using it in one lane consumes it for the other lanes.
- Later Markets and stale restored `firstRerollDiscount` state show normal `리롤 5`.
- Item/passive reroll discounts show original and discounted price, such as `리롤 5→4`.
- Normal first reroll outside the S1 basic first Market costs `5` Gold.
- Each reroll in the same Market increases the next reroll cost by `+2`.
- Entering the next Market resets reroll cost to `5`.
- With `Reroll Token` owned:
  - Buying it does not trigger a reroll.
  - Pressing reroll consumes one token when the discount applies.
  - Gold decreases by the discounted cost, not by the undiscounted cost.
  - Next reroll cost still increases by `+2`.
- Stale first-reroll fixture:
  - Open `/game?fixture=stale_first_reroll_market&debug_suppress_fixture_notice=1`.
  - Verify Jester lane button says `리롤 5`.
  - Switch to `Tool / Gear` and verify Tool lane button says `리롤 5`.
  - Verify no `첫 리롤 무료` and no `리롤 5→0` are visible.

## Deferred / Next-Entry Item Smoke

- `market_buy` items:
  - Buying the item does not discount itself.
  - The discount applies to the next eligible purchase.
  - The item stack is consumed only when its hook successfully applies.
- `enter_market` items:
  - Effects apply after the next Market opens.
  - Effects are not repeatedly applied without a new trigger or persistent rule.
- Boss/next-market items:
  - `boss_trophy` adds one Jester offer slot in the next Market.
  - The extra slot remains during rerolls in that Market.
  - The extra slot is gone in the following Market.
- Market-use tools:
  - `trade_ticket` rotates item offers only.
  - `coin_cache` and `thin_wallet` alter Gold only when explicitly used or when their conditional use rule is met.

## Battle View Smoke

- Battle item zone defaults to `Slots`.
- `Slots` tab shows `Q1-Q3` and `P1-P2`.
- `Tool / Gear` tab shows `T1-T3` and `G1-G2`.
- Occupied Jester and item cards share card sizing/inset rules; item cards use a distinct cool card face and centered count badges.
- Tapping Q-slot usable item opens the info overlay and shows `사용`.
- Tapping passive or gear item opens the info overlay and shows automatic-effect messaging.
- Tapping tool item opens the info overlay and shows Market-use messaging, not battle-use action.

## iOS Eye-Check

Use `tools/ios_sim_smoke.sh` when UI layout changes are complete.

- Confirm no bottom safe-area clipping in Market and title/continue screens.
- Confirm Market two-tab layout does not overflow on the target iPhone viewport.
- Confirm battle item zone tabs do not make the board unusably small.
- Capture output path in `docs/archive/verification_daily_logs/YYYY-MM-DD.md` when run.
