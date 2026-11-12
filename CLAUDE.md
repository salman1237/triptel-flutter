# CLAUDE.md

## Goal
Reliable, verified work over speed: a Flutter customer app for Triptel that any
agent can keep building across short sessions without re-deriving context.

## Project Overview
**Triptel** — travel-eSIM marketplace. This repo is the **customer (USER) mobile app**
in Flutter 3.27 / Dart 3.6 (Android + iOS), talking to the existing FastAPI backend's
**beta** environment: `https://beta.triptel.co/api/v1`. Pure client: no backend code
here. Backend lives in `D:\eSim\backend`, web storefront in `D:\eSim\frontend`, an
older React Native attempt in `D:\eSim\Triptel-MobileApp` (reference only).
UX follows the Eskimo eSIM app's patterns, re-skinned in Triptel purple/white.

## Quick Start
- Install: `bash harness.sh setup` (or `./init.sh`)
- Run on the phone: `bash harness.sh run`
- Test: `bash harness.sh test`
- Full verification: `bash harness.sh verify`
- On-device evidence: `bash harness.sh device-check` / `bash harness.sh shot <screen>`

## Operating mode: AUTONOMOUS (default)
The user has granted all permissions. **Do not ask for approval, do not stop to
check in.** Work through `feature_list.json` feature by feature, in order, and start
the next one as soon as the current one is committed. The loop:

```
goal:  every feature in feature_list.json is "passing" (or "blocked" with a reason)
loop:  pick → build → verify → review → commit → log → next
stop:  only when no "not_started"/"active" items remain
```

1. **Pick** — the `active` item, else the first `not_started` item. Set it `active`
   (only one at a time).
2. **Build** — read its FR, the docs it lists, and its `docs/design-reference/`
   screenshot; follow the `new-screen` / `new-api-call` skills.
3. **Verify** — the item's `verification` command + `bash harness.sh verify`; for `ui`/`device`
   items also `verify-on-device`. Prove the test fails with the feature reverted.
4. **Review** — run the `reviewer` agent; fix every FAIL, re-verify.
5. **Commit & push** — `git add` the feature's files, `git commit -m "feat(<area>): <FR-id> <behavior>"`,
   then `git push`. Record the commit hash + screenshot paths in `evidence`, set
   `passing`, commit and push that too. **Never ask before committing or pushing.**
6. **Log** — append a short entry to `claude-progress.md` (what, evidence, gotchas);
   add to `DECISIONS.md` if you made a judgment call.
7. **Next** — immediately continue with the next item. Don't end the turn between features.

**Blockers never stop the loop:** if a feature needs something only the user or the
backend can provide (OAuth client, Mac for iOS, missing endpoint, real payment),
build everything that's possible, set it `blocked` with `"blocked_reason"`, list it
under "Blocked" / "User actions pending" in `claude-progress.md`, and move on.
Only stop the whole loop for something destructive or irreversible outside this repo
(production data, real money beyond the smallest beta test, deleting user files).

### Git: commit and push everything, always, without asking
- Remote: **https://github.com/salman1237/triptel-flutter** (public), branch `main`.
- Commit + `git push origin main` after every meaningful step: each feature, each
  state/log update, each doc fix, each harness change. Small commits, pushed
  immediately — the remote is the backup and the audit trail.
- Conventional messages: `feat(area): FR-xxx …`, `fix(…)`, `docs: …`, `chore(harness): …`,
  `test: …`. End with the Co-Authored-By line your tool's instructions require.
- If a push is rejected: `git pull --rebase origin main`, re-verify, push again.
  Never force-push, never rewrite pushed history.
- **The repo is public:** never commit secrets, tokens, keystores, `.env`, `key.properties`,
  real customers' data, or screenshots showing personal info (redact first).
  `git status` + `git diff --cached` before each commit.

Context: when the context is getting long, finish the current feature, commit, update
`claude-progress.md` with the exact next step, then continue (the log is the handoff).

## Start (every session)
1. Read `claude-progress.md` (done, active, next step, blocked).
2. `git status` — if uncommitted work exists, it's the active feature in progress:
   finish it, don't discard it.
3. Run `bash harness.sh verify` to confirm you start from green, then enter the loop above.

## End (every feature, and before any pause)
1. `bash harness.sh verify` green; device evidence for UI features.
2. `feature_list.json` evidence/state, `claude-progress.md`, `DECISIONS.md` updated.
3. Committed **and pushed**. Nothing unverified is committed; nothing verified is left unpushed.

## Hard Constraints
- **Customer app only.** No admin/merchant/agent/partner screens or endpoints.
- **Beta API only**, via `--dart-define=API_BASE_URL` (default beta).
- Every amount from the API is **EUR** — even products labelled `"USD"` (docs/API.md §0.2).
- `PROCESSING`/timeout is never a failure; only `FAILED` is.
- JWT only in `flutter_secure_storage`; only `ApiClient` adds the auth header.
- QR: error correction H, 22 % logo on a white disc.
- Compatibility detection never blocks a purchase; it gates install buttons.
- Theme tokens + shared components only; no raw colours in features.
- **WIP = 1**; a feature becomes `passing` only via its verification command,
  proven to fail when the feature is reverted.

## Topic Docs
- **API Reference** (`docs/API.md`) — required before any API call or model.
- **Functional Requirements** (`docs/Functional_Requirements.md`) — required before building a feature; every FR = one `feature_list.json` item.
- **Design System** (`docs/Design_System.md`) — required before building or styling a screen.
- **Design Reference** (`docs/design-reference/`) — Eskimo screenshots; keep each screen's layout similar to its reference, in Triptel colours.
- **Architecture** (`docs/Architecture.md`) — required when adding files, providers, routes.
- **Rules** (`docs/Rules.md`) — required reading when writing any code.
- **Technical Requirements** (`docs/Technical_Requirements.md`) — when adding a dependency or touching build/test/device/MCP setup.
- **Non-Functional Requirements** (`docs/Non_Functional_Requirements.md`) — performance, offline, security, accessibility bars.

## Tools in this harness
- Skills: `.claude/skills/new-screen`, `new-api-call`, `verify-on-device`.
- Reviewer agent: `.claude/agents/reviewer.md` — run it before marking a feature passing (maker ≠ checker).
- Hooks: `.claude/hooks/block-destructive.sh` (PreToolUse), `.claude/hooks/stop-gate.sh` (Stop: reminds to verify + update state).
- MCP: `context7` (library docs), `mobile-mcp` (drive/screenshot the phone for UI polish), `dart` (needs Flutter ≥ 3.35). See `.mcp.json`.
