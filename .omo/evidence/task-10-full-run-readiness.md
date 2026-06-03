# Task 10 Full-Run Readiness

Status: local final QA gate passed; full_run_bot not started in this task.

## Build Gate

- Command: `/Users/cheng80/flutter/bin/flutter build web --release --base-href "/rummipoker/"`
- Evidence: `.omo/evidence/task-10-web-build.txt`
- Result: PASS

## Fixture Smoke Gate

- Server: `flutter run -d web-server --web-hostname=127.0.0.1 --web-port=7357 --dart-define=SHOW_DEBUG_FIXTURES=true`
- Evidence: `.omo/evidence/task-10-fixture-smoke.txt`
- Screenshots:
  - `.omo/evidence/screenshots/task-10-fate-after-fix.png`
  - `.omo/evidence/screenshots/task-10-ritual_deck_echo-after-fix.png`
  - `.omo/evidence/screenshots/task-10-market_policy-after-fix.png`
  - `.omo/evidence/screenshots/task-10-mobile_fate-after-fix.png`
- Result: PASS
- Coverage:
  - Fate fixture
  - Ritual copy/echo fixture
  - Market slot policy fixture
  - Mobile viewport Fate fixture
- Important console error/warn/overflow: 0 after ignoring headless WebGL ReadPixels and Flutter viewport replacement noise.

## Bug Found And Fixed During Gate

- Initial fixture smoke found 404 for `assets/assets/images/cards/rituals_4x/ritual_flush_house_fate.png`.
- Fix:
  - `flush_house_fate` now aliases to existing `rank_concord` ritual emblem.
  - `flush_five_fate` now aliases to existing `color_concord` ritual emblem.
  - Added catalog-wide item emblem existence test.
- Evidence: `.omo/evidence/task-10-card-emblem-assets-test.txt`

## Final Verification

- Full analyzer: `.omo/evidence/final-dart-analyze.txt` PASS
- `git diff --check`: `.omo/evidence/final-git-diff-check.txt` PASS
- Changed-scope tests: `.omo/evidence/final-changed-scope-tests.txt` PASS
- Cleanup: `.omo/evidence/task-10-cleanup.txt` PASS

## Full-Run Bot Decision

- Do not start `full_run_bot` automatically in this task.
- Reason: full-run is a long-running external QA gate and requires user approval per project rules. Local web build and fixture smoke no longer block it.
- Recommended next run: start `풀런봇` as a separate approved gate from current code, beginning with the next locale cycle required by the project process.
- Known advisory risk before broad automation: Task 9 tiny S1-S4 sequence probe showed path_clear_rate 0.0 for both `none` and `shop_slot_market_v9`; this is a bot/path endurance signal, not a local build/fixture blocker.
