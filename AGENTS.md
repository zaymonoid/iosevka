# Working on iosevka

We are rapid prototyping:

- No backwards compatibility.
- Move fast and break things.
- No app data is sacred.
- Velocity and continuous improvement and iteration are paramount.

iosevka is a SwiftUI iOS word game (`iosevka.xcodeproj`, scheme `iosevka`,
bundle ID `zaymonoid.iosevka`).

## Tests

- `cd AppLogic && swift test`: the game logic and unit tests on macOS, no
  simulator (~1.5 s warm). Use this while iterating.
  `AppLogic/` is a SwiftPM package that symlinks `iosevka/` and `iosevkaTests/`
  and builds only the logic files listed in its `sources` (as module `iosevka`).
  Those files must import only Foundation, Combine and ObservableStore; add new
  logic files to `sources` and new app-only files to `exclude`.
- `npx -y mobilebuildmcp@2.7.1 simulator test`: everything, including UI tests,
  on the simulator. Run before handing off.

The app is portrait only, on iPhone and iPad.

## Simulator verification

Use MobileBuildMCP (formerly XcodeBuildMCP), pinned to `mobilebuildmcp@2.7.1`
with the `simulator` and `ui-automation` workflows. Project defaults (project,
scheme, simulator `iPhone 17 Pro`, bundle ID) are in
`.mobilebuildmcp/config.yaml`, so `build_run_sim` needs no arguments. It drives
the simulator with its bundled AXe; no setup step is needed. The same tools are
available from the shell:

- `npx -y mobilebuildmcp@2.7.1 simulator build-and-run`
- `npx -y mobilebuildmcp@2.7.1 ui-automation <tool> --simulator-id <udid>`

Tips:

- Keep round trips down: tap and type actions return a compact snapshot, so
  read that instead of calling `snapshot_ui` again; use `batch` for several taps
  on one screen; use `wait_for_ui` instead of sleeping; pass `sinceScreenHash`
  to skip a snapshot when nothing changed. Prefer snapshots to screenshots
  except for visual checks.
- Use current `elementRef`s; refresh the snapshot after navigation, scrolling or
  sheet changes.
- What AXe sees is not exactly what VoiceOver reads. AXe lists the children of
  combined and `accessibilityHidden` views, and it does not report traits. Put
  state that matters in `accessibilityValue`, not only in a trait, and keep
  clear accessibility labels on controls: the app is verified through the
  accessibility tree.
- `type_text` rejects newlines; submit with `key_press` (Return = 40).
- Look at screenshots, in light and dark, before calling visual work done.
- Tests run serially on the one simulator (`parallelizable = "NO"` in the
  shared scheme). Keep it that way: parallel testing boots a clone of the
  simulator per worker and eats the machine.
- When several agents work at once, give each its own simulator and keep all
  simulator activity (installs, launches, tests) on your own device. Never reset
  or erase a shared simulator.
