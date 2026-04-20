---
page: market-item-redesign
---
Market screen redesign for a mobile card strategy game. Preserve the current dark green felt game identity, but redesign the market so Jesters and Items are clearly separated sections with different buying logic and visual language.

**DESIGN SYSTEM (REQUIRED):**
- Platform: Mobile, iPhone portrait first
- Theme: tactile arcade market, dense but readable
- Background: Deep Night Navy (#0A0B1A)
- Primary Surface: Felt Green (#173F34)
- Secondary Surface: Muted Green (#20493D)
- Primary Accent: Warm Amber (#F4A81D)
- Secondary Accent: Teal Green (#267B67)
- Utility Accent: Market Blue (#2D6F9E)
- Neutral Action: Gray-Green (#4C5A55)
- Text Primary: Soft White
- Buttons: low-height chunky game buttons, no text-button styling, no glow blur
- Cards: compact, high-information, easy to scan on phone

**Reference Inputs:**
- `/tmp/rummipoker_ios_smoke/economy_redesign_market_20260421/01_launch.png`
- `/tmp/rummipoker_ios_smoke/economy_redesign_battle_20260421_seq/01_launch.png`
- `/tmp/rp_playwright_smoke/title_continue_dialog_fixed.png`
- `/tmp/rp_playwright_smoke/blind_start_dialog_fixed.png`

**Context And Constraints:**
- Current market is effectively Jester-only
- Future market must support both:
  - Jester section
  - Item section
- Jesters are persistent slot-based synergy assets
- Items are not the same category and may be consumable, equipment, passive relic, or utility
- Keep the phone safe area and avoid cramped interaction zones
- Drag-to-sell area, reroll, list scrolling, buy buttons, and next-station progression must have clear separation

**Page Structure:**
1. **Top Header:** Market title, current gold, options
2. **Owned Jester Area:** Existing equipped Jesters shown as fixed-slot persistent assets
3. **Owned Item Summary:** Separate visual treatment from Jesters
4. **Sell / Service Utility Band:** Drag target, reroll, and utility actions with better spacing and clearer grouping
5. **Jester Offers Section:** Offer cards optimized for long-term synergy assets
6. **Item Offers Section:** Different card treatment from Jesters
7. **Bottom Progression Actions:** Return / next station / optional service actions

**Deliverable Goal:**
- Produce a market concept that can scale from the current Jester-only prototype to a multi-content market while keeping the existing mobile game identity.
