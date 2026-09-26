# agent-plugins

One command puts the same agent skills on Claude Code and Codex, and one script
tells you when a machine has drifted from them.

## Why

Skills reach an agent by three different routes: a subset entry taken from an
upstream at a pinned commit, `skills.sh` with its own lockfile, and skills
written here. The two agent CLIs consume them differently — Codex has no
dependency concept and no update verb, so anything Claude resolves
automatically has to be done explicitly there. And upstreams move underneath
all of it.

Done by hand that is a dozen decisions repeated on every machine, with no way
to answer "is this machine still what I think it is". The alternative is not a
better memory: it is a repository that states the intended machine state, a
script that converges a machine to it, and the same script in check mode to
report what does not match. A daily watch says when an upstream has moved past
a pin, and never moves one itself.

## What it ships

Four marketplace entries:

- `software-dev`: the glue plugin, for anyone building software with an agent; its README names every skill, hook and agent it ships and where each came from. Depends on the three entries below.
- `sensemaking`: skills for thinking work that is not code, shared with `research-vault`; its README says which plugin holds a skill, and why.
- `superpowers`: obra/superpowers at a pinned commit, a subset entry, Claude Code only; Codex reaches the same skills by symlink, created by `bin/setup` as described in Install below.
- `writing-clearly-and-concisely`: softaworks/agent-toolkit's one skill of that name, a subset entry at a pinned commit, Claude Code only, with the same Codex symlink.

## Install

One command adds the marketplace, and the script it delivers does the rest. It
is safely re-runnable, and `bin/doctor` is the same engine in check mode.

```sh
claude plugin marketplace add eranroseman/agent-plugins
bash ~/.claude/plugins/marketplaces/eranroseman/bin/setup
```

`bin/setup` requires the Claude Code CLI, plus `git`, `jq`, `node` and `npx`.
That is structural rather than a preference: the script lives in the clone
`claude plugin marketplace add` creates, and reads the desired state from it. A
Claude-only machine is fully supported.

Codex is optional. When `codex` is on `PATH` the same run adds the Codex
marketplace and installs both local plugins there. When it is not, that half
is reported as skipped and nothing else changes.

What the run leaves behind: both plugins installed on each agent CLI present, a
pinned clone per subset entry — obra/superpowers and softaworks/agent-toolkit
— fourteen symlinks into them under `~/.agents/skills` (Codex's documented
user skill root, created whether or not Codex is present), and the declared
skills.sh set installed at its declared refs.

Three things it deliberately does not do. It never enables plugin auto-update
— that is a consent decision you make once in `/plugin` under Marketplaces.
And it never sets the telemetry variable documented in the plugin README, or
the update-check variable documented there, for the same reason. `bin/doctor`
reports the operator decisions it never makes for you.

## Update

The marketplace clone carries both the new desired state and the new copy of the
script, so it is refreshed first and the script re-run from it:

```sh
claude plugin marketplace update eranroseman
codex plugin marketplace upgrade eranroseman
bash ~/.claude/plugins/marketplaces/eranroseman/bin/setup
```

Everything after that is the script's own work: re-adding the Codex plugins,
since Codex has no update verb; re-fetching the pinned clones; re-verifying
the symlinks; and re-running `skills add` per declared skill. With auto-update
enabled, Claude Code refreshes itself and the first command is unnecessary.

Claude Code loads the new versions at the next launch or after
`/reload-plugins`: the CLI running the script is the one that has to restart.

## Checks

`tests/run.sh` runs every check under `tests/`. It needs `bash` 4.4 or later,
`jq` and `git`, and refuses with the list otherwise. Some checks need a tool
this machine may lack: each such check is skipped with a line naming the
tool, and the run ends by summing what it did not verify. The versions those
checks are held to are declared in `tests/tools.txt`; the three npm tools
install with `npm install -g <tool>@<version>`, the three binaries from their
release pages. The Codex manifest check needs `python3` with `pyyaml` and the
validator `codex-cli` installs, or a copy fetched by the recipe in
`.github/workflows/validate.yml` and named by `CODEX_PLUGIN_VALIDATOR`. The
pin and drift checks fetch from GitHub; offline, they fail rather than skip.

Every run writes `tests/results.tsv`, one row per check under a header naming
the commit; a report cites that file rather than pasting output.
`scripts/format` rewrites what the format checks check. CI runs the same
script with `--no-skip`, so nothing is skipped there, uploads the result file
as an artifact, and runs `bin/setup` end to end against a scratch `HOME`.

## Layout

```text
bin/               the two commands a user runs: setup, and doctor, its check mode
scripts/           what CI and the maintainer run: the upstream watch, the superpowers bump, the formatter
plugins/           the two plugins, software-dev and sensemaking, each with its own README
skills.json        the desired state for skills.sh: sources, refs, skill names
vendored.json      the desired state for the vendored and forked trees: repo, branch, pinned sha, kind
.claude-plugin/    the Claude marketplace manifest: the two plugins and the two subset entries, with their pins
tests/             every check; tests/run.sh runs them and tests/tools.txt pins the tools
docs/agents/       the conventions the agents read: issue tracker, triage labels, domain docs
docs/Professional-Editorial-Standards-2024.md   the editorial reference
docs/superpowers/  historical artifacts: specs and plans as executed; vocabulary and paths current, content frozen
CONTEXT.md         the vocabulary: contested terms with their retired forms, and the leading words
AGENTS.md          the agents' instruction file; CLAUDE.md imports it
```
