# agent-plugins

One repository states the skills a machine should have on Claude Code and
Codex, delivers them as plugins each agent CLI installs with its own commands,
and watches the upstreams it takes skills from.

## Why

A skill reaches an agent from an upstream that moves, through an agent CLI
that installs plugins its own way. Done by hand that is a pin per upstream, a
copy per change, and two install procedures to keep in step, on every machine.
This repository states the set once: the skills it writes or changes ship in
one plugin, the skills it takes as they are come from subset entries that pin
part of an upstream at one commit, and a daily watch says when an upstream has
moved past a pin. Every pin is written once, in the marketplace manifest or in
`vendored.json`, and a test holds every copy to its upstream.

## What it ships

Marketplace entries in `.claude-plugin/marketplace.json`, the one file both
agent CLIs read. On Claude Code, installing `software-dev` brings the rest as
dependencies; on Codex, each is installed by name.

- `software-dev`: the plugin this repository writes or changes.
  - `setup-matt-pocock-skills`: a fork of mattpocock/skills' repository
    scaffolder, first-party since the fork. It writes the `## Agent skills`
    block to `AGENTS.md` and leaves `CLAUDE.md` as a one-line `@AGENTS.md`
    import, asks which git convention the repo uses, and carries that
    convention, the design ladder and the task-reports rule. User-invocable
    only.
  - `consistency-audit` and its agent `consistency-audit-inspector`: a
    first-party audit, user-invocable only, that reads a repository whole for
    contradictions, duplication, drifted terms and stale claims, and refutes
    every candidate before reporting it. On Codex, where a plugin cannot ship
    a subagent, it runs as one reader and says so.
  - `diagnosing-bugs`: a copy of mattpocock/skills' reproduction-first
    debugging loop at the `mattpocock` entry's pin, with one declared change,
    a description that shares no trigger word with
    `superpowers:systematic-debugging`. Model-invoked.
  - `finding-duplicate-functions`: a rewritten fork of obra/superpowers-lab's
    skill, for Python; the plugin LICENSE records what changed.
  - `rethink-audit`: a first-party clean-slate redesign audit of a module,
    service or feature; design only, applying no changes. Held for a redesign.
  - `adhd`: parallel divergent ideation under five isolated cognitive frames,
    scored, clustered and deepened, about ten agent calls. A copy of
    UditAkhourii/adhd at the pin `vendored.json` records, with two declared
    changes, the invocation gate in its frontmatter and the Codex policy file,
    so it is user-invocable only on both agent CLIs: `/adhd <problem>`.
- `elements-of-style`: softaworks/agent-toolkit's `writing-clearly-and-concisely`,
  one skill, a subset entry at a pinned commit. The entry carries obra's plugin
  name, so `elements-of-style:writing-clearly-and-concisely`, the name obra's
  `brainstorming` used through 6.4 and `consistency-audit` uses, names the
  skill this marketplace delivers. Installing obra's own `elements-of-style`
  beside it would give two skills of that name; the blocks here never install
  it.
- `mattpocock`: fifteen of mattpocock/skills' skills at a release tag, a
  subset entry: `grilling`, `handoff`, `teach`, `to-questionnaire`,
  `wait-what`, `writing-for-agents`, `research`, `wayfinder`, `wizard`,
  `codebase-design`, `domain-modeling`, `grill-with-docs`,
  `improve-codebase-architecture`, `prototype` and `triage`. The skills read
  `mattpocock:<name>` on both agent CLIs.

Superpowers is not an entry here. The blocks below install obra's own plugin
from obra's marketplace on each agent CLI; nothing in this repository pins,
copies or watches it, and a user's superpowers moves with obra's releases. A
machine that already has superpowers from another marketplace,
`superpowers@claude-plugins-official` among them, would get a second one
beside it, every skill twice; install from one.

Every skill a subset entry delivers is upstream's as written; a copy is made
only where this repository changes something, and the change is declared in
the upstream test. A fork is first-party and held to nothing.

## What it depends on

`software-dev` depends on `mattpocock` and `elements-of-style`, so one install
on Claude Code brings all three. Each entry is pinned at one upstream commit,
and the watch reports when the upstream moves.

`consistency-audit` uses `elements-of-style:writing-clearly-and-concisely` for
its report, `mattpocock:grilling` for its question round and
`mattpocock:domain-modeling` for the rulings that land in the glossary.

## Install

Claude Code:

```sh install-claude
claude plugin marketplace add eranroseman/agent-plugins
claude plugin install software-dev@eranroseman
claude plugin marketplace add obra/superpowers-marketplace
claude plugin install superpowers@superpowers-marketplace
```

The second command brings the dependencies with it, at user scope by default.
The last two commands install obra's superpowers from obra's own marketplace,
the route obra's README gives beside the official one; it brings upstream's
own SessionStart hook.

Codex, which has no dependency concept, so each plugin is added by name:

```sh install-codex
codex plugin marketplace add eranroseman/agent-plugins && for p in software-dev mattpocock elements-of-style; do codex plugin add "$p@eranroseman"; done
codex plugin marketplace add obra/superpowers && codex plugin add superpowers@superpowers-dev
```

The second line adds obra's repository as a marketplace, which serves one
named `superpowers-dev`, and installs superpowers from it.

Codex takes the `owner/repo` shorthand, and neither agent CLI needs a login
for any command here.

## Update

Claude Code, one update per plugin, since a parent's update leaves its
dependencies at their old versions:

```sh update-claude
claude plugin marketplace update eranroseman
claude plugin update software-dev@eranroseman
claude plugin install software-dev@eranroseman
claude plugin update mattpocock@eranroseman
claude plugin update elements-of-style@eranroseman
claude plugin marketplace update superpowers-marketplace
claude plugin update superpowers@superpowers-marketplace
```

The `install` after `software-dev`'s update installs any dependency the new
release adds; on an installed plugin whose dependencies are present it
changes nothing. `claude plugin list` names a missing dependency and the
install command for it. Claude Code loads new versions at the next launch or
after `/reload-plugins`.

The last two lines refresh obra's marketplace and update superpowers from it.

Codex:

```sh update-codex
codex plugin marketplace upgrade eranroseman
codex plugin marketplace upgrade superpowers-dev
```

Each line re-clones its marketplace when its source moved and reinstalls
every installed plugin from the new commit. Never run `codex plugin
marketplace add` again for an update: on a marketplace already added it
reports it as such, exits 0 and refreshes nothing. A plugin the marketplace
gains later needs its own `codex plugin add`, as `mattpocock` and
`elements-of-style` do on this release; the cleanup below covers them.

## One-time cleanup

For a machine the retired script `bin/setup` converged before this release.
Run it once, before the update blocks:

```sh cleanup
claude plugin marketplace update eranroseman
claude plugin update software-dev@eranroseman
claude plugin install software-dev@eranroseman
claude plugin uninstall sensemaking@eranroseman
claude plugin uninstall superpowers@eranroseman
claude plugin uninstall writing-clearly-and-concisely@eranroseman
claude plugin marketplace add obra/superpowers-marketplace
claude plugin install superpowers@superpowers-marketplace
npx --yes skills remove codebase-design domain-modeling grill-with-docs grilling handoff improve-codebase-architecture prototype research resolving-merge-conflicts teach to-questionnaire triage wait-what wayfinder wizard working-with-claude-code writing-for-agents -g -y
find ~/.agents/skills -maxdepth 1 -type l -lname "$HOME/.local/share/software-dev/*" -delete
rm -rf ~/.local/share/software-dev
ls -d ~/.agents/skills/*.aside.* 2>/dev/null || true
codex plugin marketplace upgrade eranroseman
codex plugin remove sensemaking@eranroseman
for p in mattpocock elements-of-style; do codex plugin add "$p@eranroseman"; done
codex plugin marketplace add obra/superpowers && codex plugin add superpowers@superpowers-dev
```

- The first three lines move `software-dev` to this release, which installs
  the dependencies it adds.
- The uninstalls remove from Claude Code the plugins whose entries left the
  marketplace: `sensemaking`, whose two skills ship in `software-dev` now;
  `superpowers@eranroseman`, since superpowers now comes from obra's
  marketplace, which the next two lines install it from; and
  `writing-clearly-and-concisely@eranroseman`, whose skill `software-dev`'s
  update has just installed under the entry's new name, `elements-of-style`.
  On Codex no line removes `superpowers` or `writing-clearly-and-concisely`:
  both reached a converged machine through the script's links, which the
  `find` and `rm` remove, never as plugins.
- The skills.sh `remove` takes the seventeen skills the script installed that
  the `mattpocock` entry now brings or this release drops;
  `resolving-merge-conflicts` is named because the old install had it, though
  upstream has since removed it. `archify` and `developing-claude-code-plugins`
  stay installed and become your own, as does any other skills.sh install
  (`npx skills list -g` shows them; the same `remove` takes any you no longer
  want). The line needs `npx`, as the install it undoes did.
- The `find` removes the script's symlinks into its clones, and the `rm` the
  clones.
- The `ls` lists what the script moved aside inside the skill root, where
  Codex loads each as a bare skill; review each by hand, since it may be
  yours.
- The Codex `upgrade` is the update block's own first line, so the adds after
  it find the new entries; then `sensemaking` is removed there, the two entries
  are added, `mattpocock` new to the marketplace and `elements-of-style` under
  its new name, and the last line adds obra's superpowers, as the install
  block does.
- Without the cleanup, both agent CLIs load each mattpocock skill twice, bare
  beside `mattpocock:<name>`, and Codex lists every superpowers skill twice.

A repository scaffolded before this release keeps its glossary as
`CONTEXT.md`, which upstream's `domain-modeling` no longer reads: it writes
`GLOSSARY.md` and would start a second glossary beside the old file. In each
such repository, run `git mv CONTEXT.md GLOSSARY.md`.

## Notes

- `archify` is not shipped. [tt-a1i/archify](https://github.com/tt-a1i/archify)
  gives its own install instructions; this repository neither pins nor
  watches it.
- `developing-claude-code-plugins` is not shipped either. Each agent CLI's own
  documentation is current: [Claude Code's documentation map](https://code.claude.com/docs/en/claude_code_docs_map.md)
  and [Codex's plugin build page](https://developers.openai.com/plugins/build/plugins).
  Anyone who wants the skill can install obra's own,
  `superpowers-developing-for-claude-code@superpowers-marketplace` from
  `obra/superpowers-marketplace`, on either agent CLI, which brings
  `working-with-claude-code` with it; this repository neither pins nor
  watches it.
- Claude Code's auto-update is off by default for a third-party marketplace.
  Turning it on is your choice, made once in `/plugin` under Marketplaces:
  select `eranroseman` and turn auto-update on. With it on, Claude Code
  refreshes the marketplace and updates installed plugins after a session
  starts, then prompts for `/reload-plugins` or loads the new version at the
  next launch. The marketplace pins its subset entries at a fixed commit, so
  auto-update delivers this repository's releases and never an upstream's
  HEAD.

## Checks

`tests/run.sh` runs every check under `tests/`. It needs `bash` 4.4 or later,
`jq` and `git`, and refuses with the list otherwise. Some checks need a tool
this machine may lack: each such check is skipped with a line naming the
tool, and the run ends by summing what it did not verify. The versions those
checks are held to are declared in `tests/tools.txt`; the three npm tools
install with `npm install -g <tool>@<version>`, the three binaries from their
release pages. The Codex manifest check needs `python3` with `pyyaml` and
fetches Codex's validator from GitHub at a pinned commit, as the upstream
test fetches each pin; offline, they fail rather than skip.

Every run writes `tests/results.tsv`, one row per check under a header naming
the commit; a report cites that file rather than pasting output.
`scripts/format` rewrites what the format checks check. CI runs the same
script with `--no-skip`, so nothing is skipped there, uploads the result file
as an artifact, and, in a second job that also runs daily, installs the plugin
and its entries through the install blocks above on the newest stable
release of each agent CLI and asserts that each loads the skills it declares,
and that every `superpowers:` reference in the shipped skills names a skill
obra's installed superpowers provides on both agent CLIs.

## Layout

```text
scripts/           what CI and the maintainer run: the upstream watch and the formatter
plugins/           the one plugin, software-dev
vendored.json      one record per upstream repository copied or forked from: its pin, its copies and its forks
.claude-plugin/    the marketplace manifest both agent CLIs read: the plugins and the subset entries, with their pins
.github/           the CI workflows, and dependabot.yml, which moves their action pins
tests/             every check; tests/run.sh runs them, tests/install-check.sh is the install job's, and tests/tools.txt pins the tools
docs/agents/       the conventions the agents read: issue tracker, triage labels, domain docs
docs/Professional-Editorial-Standards-2024.md   the editorial reference
docs/superpowers/  historical artifacts: specs and plans, each read as of its commit
GLOSSARY.md        the vocabulary: contested terms with their retired forms, and the leading words
AGENTS.md          the agents' instruction file; CLAUDE.md imports it
```

## License

MIT. See `LICENSE`. Each upstream this repository copies or forks from is
credited in the plugin's own LICENSE.
