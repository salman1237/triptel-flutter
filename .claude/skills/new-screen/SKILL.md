---
name: new-screen
description: Build a new Triptel Flutter screen the house way (tokens, shared components, Eskimo-like layout, states, test, device screenshot). Use whenever adding or restyling a screen.
---
# New screen

1. Find the FR in `docs/Functional_Requirements.md` and its row in
   `docs/design-reference/README.md`. **Open the matching screenshot** and keep the
   layout similar (structure, hierarchy, CTA placement) in Triptel colours.
2. Read `docs/Design_System.md` §1–§4. Use only `core/theme` tokens and
   `core/widgets` components; if a needed component is missing, add it to
   `core/widgets` (generic), not inside the feature.
3. Create `lib/features/<feature>/presentation/<name>_screen.dart`. Data comes from a
   provider in `application/`; the screen never imports `dio`.
4. Implement all four states: loading (skeleton/three-dot), error (message + Retry),
   empty (icon in lilac circle + one sentence + CTA), data.
5. Register the route in `lib/app/router.dart`.
6. Strings via the translation helper; directional padding only (RTL).
7. Widget test in `test/features/<feature>/` covering data + error state. Break the
   screen on purpose once and confirm the test fails.
8. `bash harness.sh run`, navigate to it, `bash harness.sh shot <FR-id>`; compare against the reference
   screenshot. Optional: use the `mobile-mcp` server to tap through it.
9. Run the reviewer agent (`.claude/agents/reviewer.md`) before marking passing.
