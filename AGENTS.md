# Working on iosevka

iosevka is a SwiftUI iOS word game (`iosevka.xcodeproj`, scheme `iosevka`,
bundle ID `zantonio.iosevka`).

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
- When several agents work at once, give each its own simulator and keep all
  simulator activity (installs, launches, tests) on your own device. Never reset
  or erase a shared simulator.
