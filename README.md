# agent-plugins

The source repository for the `eranroseman` plugin marketplace, which serves
both Claude Code and Codex. It hosts three plugins:

- `software-development`: the glue plugin. obra/superpowers' `brainstorming`
  skill vendored with a narrowed description, plus a SessionStart hook on
  Claude Code (Codex is offered none, by design).
  Depends on the two entries below.
- `sensemaking`: skills shared with `research-vault`, starting with
  `rethink-audit`.
- `superpowers`: obra/superpowers taken straight from upstream at a pinned
  commit, 13 of its 14 skills. `brainstorming` is the one left out. This entry
  is Claude Code only; Codex gets the same skills by symlink, created by
  `bin/setup` as described in Install below.

## Install

One command adds the marketplace, and the script it delivers does the rest. It
is safely re-runnable, and `bin/doctor` is the same engine in check mode.

```
claude plugin marketplace add eranroseman/agent-plugins
bash ~/.claude/plugins/marketplaces/eranroseman/bin/setup
```

`bin/setup` requires the Claude Code CLI, plus `git`, `jq`, `node` and `npx`.
That is structural rather than a preference: the script lives in the clone
`claude plugin marketplace add` creates, and reads its declarations from it. A
Claude-only machine is fully supported.

Codex is optional. When `codex` is on `PATH` the same run adds the Codex
marketplace and installs both local plugins there. When it is not, that half
is reported as skipped and nothing else changes.

What the run leaves behind: both plugins installed on each harness present, a
clone of obra/superpowers at the pinned sha, thirteen symlinks into it under
`~/.agents/skills` — Codex's documented user skill root, created whether or
not Codex is present — and the declared skills.sh set installed at its
declared refs.

Two things it deliberately does not do. It never enables plugin auto-update —
that is a consent decision you make once in `/plugin` under Marketplaces. And it
never sets the telemetry variable documented in the plugin README. `bin/doctor`
reports the state of both.

## Update

The marketplace clone carries both the new declarations and the new copy of the
script, so it is refreshed first and the script re-run from it:

```
claude plugin marketplace update eranroseman
codex plugin marketplace upgrade
bash ~/.claude/plugins/marketplaces/eranroseman/bin/setup
```

Everything after that is the script's own work: re-adding the Codex plugins,
since Codex has no update verb; re-fetching the pinned clone; re-verifying the
thirteen links; and re-running `skills add` per declared skill. With auto-update
enabled, Claude Code refreshes itself and the first command is unnecessary.

Claude Code loads the new versions at the next launch or after
`/reload-plugins`: the CLI running the script is the one that has to restart.

## Checks

`tests/run.sh` runs every static check: manifest schema on both harnesses, the
upstream pin, the skills.sh pins, vendored-skill drift on both vendored skills,
hook output, the engine's shape, and the doctor's fault detection. Six of them
touch the network: the two pin checks, the two vendored-skill drift checks, the
hook payload check, and the engine's own test, whose upgrade-path assertion
fetches the pinned upstream tree when `claude` is on `PATH`. CI runs the same
script, plus an end-to-end `bin/setup` run against a scratch `HOME`.

## Design

`docs/superpowers/specs/2026-09-04-software-development-layout-and-tracer-design.md`.

`docs/superpowers/specs/2026-09-05-setup-and-drift-design.md` covers `bin/setup`,
`bin/doctor`, and the upstream watch.
