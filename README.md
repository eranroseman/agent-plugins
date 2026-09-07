# agent-plugins

One command puts the same agent skills on Claude Code and Codex, and one script
tells you when a machine has drifted from them.

## Why

Skills reach an agent by three different routes: a curated upstream, a separate
installer with its own lockfile, and skills written here. Two harnesses consume
them differently — Codex has no dependency concept and no update verb, so
anything Claude resolves automatically has to be done explicitly there. And
upstreams move underneath all of it.

Done by hand that is a dozen decisions repeated on every machine, with no way
to answer "is this machine still what I think it is". The alternative is not a
better memory: it is a repository that states the intended machine state, a
script that converges a machine to it, and the same script in check mode to
report what does not match. A daily watch says when an upstream has moved past
a pin, and never moves one itself.

## What it ships

Four marketplace entries:

- `software-dev`: the glue plugin. obra/superpowers' `brainstorming`
  skill vendored with a narrowed description, the repository scaffolder,
  the authored `consistency-audit` with its inspector agent, a vendored
  `diagnosing-bugs`, a forked `finding-duplicate-functions`, plus a
  SessionStart hook on Claude Code (Codex is offered none, by design).
  Depends on the three entries below.
- `sensemaking`: skills shared with `research-vault`: `rethink-audit` and
  `adhd`. Its README states which plugin holds a skill, and why.
- `superpowers`: obra/superpowers taken straight from upstream at a pinned
  commit, 13 of its 14 skills. `brainstorming` is the one left out. This entry
  is Claude Code only; Codex gets the same skills by symlink, created by
  `bin/setup` as described in Install below.
- `writing-clearly-and-concisely`: softaworks/agent-toolkit's one skill of
  that name, curated at a pinned commit from upstream's published plugin
  directory. Claude Code only, by the same mechanism and with the same Codex
  symlink.

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
pinned clone per curated entry — obra/superpowers and softaworks/agent-toolkit
— fourteen symlinks into them under `~/.agents/skills` (Codex's documented
user skill root, created whether or not Codex is present), and the declared
skills.sh set installed at its declared refs.

Three things it deliberately does not do. It never enables plugin auto-update
— that is a consent decision you make once in `/plugin` under Marketplaces.
And it never sets the telemetry variable documented in the plugin README, or
`archify`'s own update-check variable, for the same reason. `bin/doctor`
reports the state of the first two; the plugin README covers the third by
instruction alone, for now.

## Update

The marketplace clone carries both the new declarations and the new copy of the
script, so it is refreshed first and the script re-run from it:

```
claude plugin marketplace update eranroseman
codex plugin marketplace upgrade
bash ~/.claude/plugins/marketplaces/eranroseman/bin/setup
```

Everything after that is the script's own work: re-adding the Codex plugins,
since Codex has no update verb; re-fetching the pinned clones; re-verifying
the symlinks; and re-running `skills add` per declared skill. With auto-update
enabled, Claude Code refreshes itself and the first command is unnecessary.

Claude Code loads the new versions at the next launch or after
`/reload-plugins`: the CLI running the script is the one that has to restart.

## Checks

`tests/run.sh` runs every static check: manifest schema on both harnesses, the
upstream pin, the skills.sh pins, the curated writing entry, drift on the five
vendored or forked skills, the invariants every plugin skill must hold, hook
output, the engine's shape, the doctor's fault detection, and the doctor's
duplicate detection. Ten of them touch the network: the three pin checks, the
five drift checks, the hook payload check, and the engine's own test, whose
upgrade-path assertion fetches the pinned upstream trees when `claude` is on
`PATH`. CI runs the same script, plus an end-to-end `bin/setup` run against a
scratch `HOME`.
