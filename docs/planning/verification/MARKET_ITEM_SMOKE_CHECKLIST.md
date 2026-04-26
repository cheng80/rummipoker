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

- First reroll in a Market costs `5` Gold.
- Each reroll in the same Market increases the next reroll cost by `+2`.
- Entering the next Market resets reroll cost to `5`.
- With `Reroll Token` owned:
  - Buying it does not trigger a reroll.
  - Pressing reroll consumes one token.
  - Gold does not decrease for that reroll.
  - Next reroll cost still increases by `+2`.
- Reroll button is disabled or not shown as actionable for `Tool / Gear` if current policy keeps reroll tied to the card/slot offer lane.

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
- Tapping Q-slot usable item opens the info overlay and shows `사용`.
- Tapping passive or gear item opens the info overlay and shows automatic-effect messaging.
- Tapping tool item opens the info overlay and shows Market-use messaging, not battle-use action.

## iOS Eye-Check

Use `tools/ios_sim_smoke.sh` when UI layout changes are complete.

- Confirm no bottom safe-area clipping in Market and title/continue screens.
- Confirm Market two-tab layout does not overflow on the target iPhone viewport.
- Confirm battle item zone tabs do not make the board unusably small.
- Capture output path in `docs/planning/verification/daily_logs/YYYY-MM-DD.md` when run.
