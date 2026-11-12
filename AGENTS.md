# AGENTS.md

The maintained instructions for every coding agent (Claude Code, Codex, others)
are in [`CLAUDE.md`](./CLAUDE.md). Read it first; it is kept in one place on purpose
so the two can't drift.

Notes for non-Claude tools:
- `.claude/skills/*/SKILL.md` and `.claude/agents/reviewer.md` are plain markdown:
  open and follow them manually.
- `.claude/hooks/*` are not enforced for you. Read `docs/Rules.md` and never run
  `rm -rf`, `git reset --hard`, `git push --force` or `git clean -f` here.
- `claude-progress.md`, `feature_list.json` and `DECISIONS.md` are shared state for
  every tool. WIP = 1 applies regardless of which tool opened the session.
