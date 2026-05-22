---
name: rummi-runtime-video-capture
description: Record real Rummi Poker Flutter web runtime interactions with Playwright video capture, especially fixture-based UI/effect validation such as special tile settlement, boss constraint overlays, market animation, or battle feedback. Use when the user asks to make or verify an actual implementation video, webm, mp4, GIF-like proof, or runtime effect recording.
---

# Rummi Runtime Video Capture

Use this skill to record the actual Flutter web app, not a design mockup.

## Workflow

1. Prefer an existing debug fixture that starts close to the target scene.
2. If the target state cannot be reached reliably, add or update a small fixture first and test it.
3. Build web with debug fixtures enabled:
   ```bash
   flutter build web --dart-define=SHOW_DEBUG_FIXTURES=true
   ```
4. Run `scripts/capture_rummi_runtime_video.sh` with a route, output name, and click sequence.
5. Inspect the before/after screenshots and the generated `.webm`/`.mp4`.
6. Stop any local servers or browser processes left by the capture.

## Script

The bundled script records with Playwright using system Chrome and converts to mp4 if `ffmpeg` exists.

Example:

```bash
.agents/skills/rummi-runtime-video-capture/scripts/capture_rummi_runtime_video.sh \
  --route "/game?fixture=special_tile_battle_preview&debug_suppress_fixture_notice=1" \
  --name special_tile_effect_validation \
  --clicks "195,461,1200;335,668,8500"
```

Click tuple format is:

```text
x,y,waitAfterMs;x,y,waitAfterMs
```

For the current special tile boss constraint fixture:

- `195,461,1200`: close the boss intro by pressing `전투 시작`.
- `335,668,8500`: press `확정 하기` and wait through settlement.

## Validation Notes

- Always keep screenshots beside videos:
  - `<name>_before.png`
  - `<name>_after.png`
- For boss/constraint checks, make sure the before screenshot shows both the constraint marker and tile modifier badges.
- For settlement/effect checks, make sure the after screenshot shows score/gold changed or board cleared.
- If the capture opens title/splash instead of the fixture, use path routing (`/game?...`), not hash routing.
