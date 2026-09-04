# software-development

The glue plugin of Eran Roseman's software-development harness. It is a thin
layer over two upstream skill packs, not a home for copies of them.

What it ships:

- `skills/brainstorming/`: obra/superpowers' `brainstorming` skill, vendored
  at a pinned commit with one change, a narrowed `description` so that it
  fires on build requests and no longer competes with `grilling`. The
  provenance header at the top of `SKILL.md` names the commit. Do not
  hand-edit the skill; re-vendor from upstream to update it.
- `hooks/session-start`: a SessionStart hook that injects `hooks/payload.md`,
  upstream's `using-superpowers` text with its one `superpowers:brainstorming`
  reference repointed at `software-development:brainstorming`.

What it depends on (Claude Code installs both automatically):

- `sensemaking@eranroseman`: shared skills, starting with `rethink-audit`.
- `superpowers@eranroseman`: obra/superpowers taken straight from upstream,
  13 of its 14 skills. `brainstorming` is the one left out.

## Install

Claude Code:

    claude plugin marketplace add eranroseman/software-development
    claude plugin install software-development@eranroseman

Codex (no dependency concept; superpowers arrives by symlink, see the
repository README):

    codex plugin marketplace add https://github.com/eranroseman/software-development.git
    codex plugin add software-development@eranroseman
    codex plugin add sensemaking@eranroseman

Codex does not currently load this plugin's SessionStart hook. The hook files
ship, and the Codex manifest omits the `hooks` key so that Codex's documented
fallback to `hooks/hooks.json` can pick them up, but on codex-cli 0.147.0 no
trust prompt appears and nothing is registered. Measured 2026-09-04; see gate
G4 in the design spec's tracer results.

## Environment

The brainstorming skill's Visual Companion fetches a logo from an external
site unless `SUPERPOWERS_DISABLE_TELEMETRY` or `DISABLE_TELEMETRY` is set.
Set one of them in your shell profile.

## License

MIT. The vendored `skills/brainstorming/` is MIT, © 2025 Jesse Vincent. See
`LICENSE`.
