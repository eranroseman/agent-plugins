# software-development

Eran Roseman's glue plugin for software development. It is a thin
layer over two upstream skill packs, not a home for copies of them.

What it ships:

- `skills/brainstorming/`: obra/superpowers' `brainstorming` skill, vendored
  at a pinned commit with one change, a narrowed `description` so that it
  fires on build requests and no longer competes with `grilling`. The
  provenance header at the top of `SKILL.md` names the commit. Do not
  hand-edit the skill; re-vendor from upstream to update it.
- `skills/setup-matt-pocock-skills/`: mattpocock/skills' repository scaffolder,
  vendored at tag `v1.2.3` with two changes. It writes the `## Agent skills`
  block to `AGENTS.md` and leaves `CLAUDE.md` as a one-line `@AGENTS.md` import,
  so Codex reads the same rules Claude does; and the block it writes carries a
  Git convention and the task-reports rule. User-invoked only. The provenance
  header at the top of `SKILL.md` names the commit.
- `hooks/session-start`, Claude Code only: a SessionStart hook that injects
  `hooks/payload.md`, upstream's `using-superpowers` text with its one
  `superpowers:brainstorming` reference repointed at
  `software-development:brainstorming`, followed by `hooks/payload-rules.md`,
  this plugin's own working rules. The Claude manifest declares the hook as
  `hooks/claude-hooks.json`.

What it depends on (Claude Code installs both automatically):

- `sensemaking@eranroseman`: shared skills, starting with `rethink-audit`.
- `superpowers@eranroseman`: obra/superpowers taken straight from upstream,
  13 of its 14 skills. `brainstorming` is the one left out.

## Install

Claude Code:

    claude plugin marketplace add eranroseman/agent-plugins
    claude plugin install software-development@eranroseman

Codex (no dependency concept; superpowers arrives by symlink, see the
repository README):

    codex plugin marketplace add https://github.com/eranroseman/agent-plugins.git
    codex plugin add software-development@eranroseman
    codex plugin add sensemaking@eranroseman

Codex gets the skills and no hook, by design. Codex follows the skills
without a session-start injection: obra/superpowers removed its own Codex hook
in v6.1.0 for that reason, and the reference machine ran two months of Codex
sessions with superpowers and no injection. Nothing exists at the path Codex
loads by fallback, `hooks/hooks.json`, so no hook is offered on any Codex
build that keeps its documented fallback path and manifest order. The design
spec in the repository records the evidence.

## Environment

Nothing here needs configuring to work. One optional variable is worth knowing
about, and no setup step sets it for you.

The brainstorming skill's Visual Companion is an opt-in browser view, offered
only when a question is genuinely clearer shown than described. When its page
loads, it renders a logo from `primeradiant.com`, with the superpowers version
in the query string. Your browser therefore reveals its address, user agent,
and the time of the request, though the referrer is suppressed. That URL is the
only external address in the whole skill.

To render the page without it, set any one of `SUPERPOWERS_DISABLE_TELEMETRY`,
`DISABLE_TELEMETRY`, or `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` to any value
other than `0`, `false`, `no`, or `off`. On Claude Code an `env` entry in
`~/.claude/settings.json` reaches the session; on Codex a line in `~/.profile`
does, since its shell runs `bash -lc`. `~/.bashrc` does not work, because it
returns early for non-interactive shells.

If you never accept the Visual Companion offer, the request never happens.

## License

MIT. The vendored `skills/brainstorming/` is MIT, © 2025 Jesse Vincent. See
`LICENSE`.
