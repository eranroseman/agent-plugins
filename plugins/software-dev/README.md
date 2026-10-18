# software-dev

Eran Roseman's glue plugin for software development. It carries a fork of
mattpocock/skills' repository scaffolder, a copy of its debugging loop, a
rewritten fork of obra/superpowers-lab's duplicate finder, and a first-party
audit with its agent, each with its provenance below.

What it ships:

- `skills/setup-matt-pocock-skills/`: a fork of mattpocock/skills' repository
  scaffolder, first-party since the fork. It writes the `## Agent skills`
  block to `AGENTS.md` and leaves `CLAUDE.md` as a one-line `@AGENTS.md`
  import, so Codex reads the same rules Claude does; it asks which git
  convention the repo uses; and the block it writes carries that convention,
  the design ladder, and the task-reports rule. User-invocable only.
- `skills/consistency-audit/` and `agents/consistency-audit-inspector.md`:
  a first-party audit, user-invocable only, that reads a repository whole for
  contradictions, duplication, drifted terms and stale claims, refutes every
  candidate before reporting it, and dispatches the read-only inspector as
  two independent readers per slice. On Codex, where a plugin cannot ship a
  subagent, it runs as one reader and says so.
- `skills/diagnosing-bugs/`: mattpocock/skills' reproduction-first debugging
  loop, vendored at tag `v1.2.3` with one change, a 69-character description
  that Codex shows whole and that no longer shares a trigger word with
  `superpowers:systematic-debugging`. Model-invoked: it should fire unprompted
  when a bug resists reproduction.
- `skills/finding-duplicate-functions/`: a rewritten fork of
  obra/superpowers-lab's skill, for Python. Its `PROVENANCE.md` records what
  changed.

What it depends on (Claude Code installs all three automatically on a first
install; `bin/setup` adds a newly declared one to a machine that already has
an older version):

- `sensemaking@eranroseman`: shared skills: `rethink-audit` and `adhd`.
- `superpowers@eranroseman`: obra/superpowers taken straight from upstream,
  13 of its 14 skills. `brainstorming` is the one left out.
- `writing-clearly-and-concisely@eranroseman`: softaworks/agent-toolkit's
  skill of that name, a subset entry at a pinned commit. `consistency-audit`
  uses it for its report when present.

## Install

Installed by the same script as the rest of the marketplace, not by adding
this plugin on its own — Codex has no dependency concept, so a manual `codex
plugin add` here would skip the fourteen subset-entry symlinks entirely. See
the repository README's `## Install` section for the full picture; its
two-command bootstrap

```sh
claude plugin marketplace add eranroseman/agent-plugins
bash ~/.claude/plugins/marketplaces/eranroseman/bin/setup
```

installs this plugin, with its `sensemaking`, `superpowers` and
`writing-clearly-and-concisely` dependencies, on Claude Code, and on Codex too
when `codex` is on `PATH`.

## Environment

`archify`, installed through skills.sh at a pinned tag, runs a version check
once per authoring session: after the first candidate diagram it runs its
packaged `tt-a1i/archify:scripts/check-update.mjs`, which fetches a small manifest from
`https://tt-a1i.github.io/archify/skill-updates/archify/stable.json`, and if
a newer release exists it shows one notice and continues. The skill's own
text rules the rest: if the command cannot run it continues without a word,
it never downloads, installs or executes an update, and silence is never
consent. To turn the check off, set `ARCHIFY_UPDATE_CHECK_DISABLED=1` in the `env` map of `~/.claude/settings.json` on Claude Code, or in `~/.profile` on Codex; `check-update.mjs` tests exactly
that value. No setup step sets it for you: a network-behavior decision belongs to you. `bin/doctor`
reports the variable's state.

## Updates

Claude Code can update this plugin for you. Third-party marketplaces default to
auto-update off, so it is a choice you make once:

1. Run `/plugin`.
2. Open Marketplaces.
3. Select `eranroseman`.
4. Turn auto-update on.

With it on, Claude Code refreshes the marketplace and updates installed plugins
after a session starts, with a random delay of up to ten minutes, then either
prompts for `/reload-plugins` or loads the new version at the next launch. The
marketplace pins both subset entries — `superpowers` and
`writing-clearly-and-concisely` — at a fixed sha, so auto-update delivers this
repository's releases and never drags in either upstream's HEAD.

Without it, and on Codex either way, the repository README's Update section has
the commands to run.

## License

MIT. `skills/setup-matt-pocock-skills/` and `skills/diagnosing-bugs/` are MIT, © 2026 Matt
Pocock; the two templates under `skills/finding-duplicate-functions/scripts/`
are MIT, © 2025 Jesse Vincent. See `LICENSE`.
