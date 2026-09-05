# software-development

The glue plugin of Eran Roseman's software-development harness. It is a thin
layer over two upstream skill packs, not a home for copies of them.

What it ships:

- `skills/brainstorming/`: obra/superpowers' `brainstorming` skill, vendored
  at a pinned commit with one change, a narrowed `description` so that it
  fires on build requests and no longer competes with `grilling`. The
  provenance header at the top of `SKILL.md` names the commit. Do not
  hand-edit the skill; re-vendor from upstream to update it.
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
build. The design spec in the repository records the evidence.

## Environment

The brainstorming skill's Visual Companion fetches a logo from an external
site unless `SUPERPOWERS_DISABLE_TELEMETRY` or `DISABLE_TELEMETRY` is set.
Set one of them in your shell profile.

## License

MIT. The vendored `skills/brainstorming/` is MIT, © 2025 Jesse Vincent. See
`LICENSE`.
