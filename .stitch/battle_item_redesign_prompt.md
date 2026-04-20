Battle screen redesign for a mobile card strategy game. Keep the existing dark arcade card-game feel, but redesign the battle HUD so Jesters and Items are clearly separated systems instead of one mixed content area.

**DESIGN SYSTEM (REQUIRED):**
- Platform: Mobile, iPhone portrait first
- Theme: dark arcade tabletop, tactile, bold, compact
- Background: Deep Night Navy (#0A0B1A)
- Primary Surface: Felt Green (#173F34)
- Secondary Surface: Muted Green (#20493D)
- Primary Accent: Warm Amber (#F4A81D) for confirm and major progression
- Secondary Accent: Teal Green (#267B67) for draw and safe progression
- Utility Accent: Market Blue (#2D6F9E)
- Danger Accent: Brick Red (#B74B3B)
- Text Primary: Soft White
- Buttons: chunky, low-height, strong silhouette, rounded rectangles, no text-button look, no glow blur
- Cards: rounded, readable, tactile game objects
- Layout rule: everything must fit inside a phone frame safe area without looking cramped

**Context And Constraints:**
- Current battle screen has top HUD, Jester strip, 5x5 board, hand/draw zone, bottom action row
- Jesters are persistent equipped synergy assets with fixed slots
- Items are a different system and must not look like “extra Jesters”
- Support future item types:
  - Consumable
  - Equipment
  - Passive Relic
  - Utility
- Prevent accidental taps:
  - Confirm must be visually and positionally separated from draw flow
  - Action grouping should reduce mis-taps on small phones

**Page Structure:**
1. **Top HUD:** Station, goal progress, gold, options. Keep compact readable chips.
2. **Jester Strip:** Dedicated equipped Jester area. Fixed slot language. Persistent synergy identity.
3. **Item Zone:** A separate zone from Jesters.
   - Show one possible future-ready pattern:
     - quick-use consumable slots
     - passive/equipment inventory summary
   - This zone must visually read as a different system from Jesters
4. **Main Board:** 5x5 board remains the visual center and should not lose dominance
5. **Hand / Draw Zone:** Keep the current functional relationship, but improve clarity and spacing
6. **Bottom Actions:** Clear grouping for draw, clear selection, discard actions, confirm
   - reduce accidental confirm presses
   - keep buttons tactile and compact
7. **Micro Status Layer:** Small hints for resources, consumable counts, or item cooldown/state if useful

**What To Explore Visually:**
- A battle layout where Jesters feel like “loadout cards”
- Items feel like “tools / relics / consumables” with a different shape language
- A cleaner, more intentional hierarchy than the current prototype
- Preserve the game feel, but avoid looking like a generic dashboard

**Deliverable Goal:**
- Produce a battle screen concept that can evolve from the current Jester-only prototype into a `Jester + Item split` runtime without redesigning again later.
