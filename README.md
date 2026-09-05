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
  is Claude Code only; Codex gets the same skills by symlink (below).

## Claude Code

    claude plugin marketplace add eranroseman/agent-plugins
    claude plugin install software-development@eranroseman

That one install pulls in `sensemaking` and the curated `superpowers`.

## Codex

Codex has no dependency concept and cannot subset a plugin's skills, so the
two local plugins install explicitly and `superpowers` arrives by symlink
from a clone pinned to the same commit:

    codex plugin marketplace add https://github.com/eranroseman/agent-plugins.git
    codex plugin add software-development@eranroseman
    codex plugin add sensemaking@eranroseman

    REPO=/path/to/this/checkout
    SHA="$(jq -r '.plugins[] | select(.name == "superpowers") | .source.sha' "$REPO/.claude-plugin/marketplace.json")"
    CLONE=~/.local/share/software-development/upstream/superpowers
    git clone https://github.com/obra/superpowers.git "$CLONE" && git -C "$CLONE" checkout "$SHA"
    for s in $(jq -r '.plugins[] | select(.name == "superpowers") | .skills[]' "$REPO/.claude-plugin/marketplace.json" | sed 's#^\./##'); do
      [ -e ~/.codex/skills/"$s" ] && { echo "ALREADY EXISTS: ~/.codex/skills/$s"; continue; }
      ln -s "$CLONE/skills/$s" ~/.codex/skills/"$s"
    done

The 13 names have one source of truth: the `superpowers` entry in
`.claude-plugin/marketplace.json`.

## Checks

`tests/run.sh` runs every static check: manifest schema on both harnesses,
the upstream pin, vendored-skill drift, hook output. CI runs the same script.

## Design

`docs/superpowers/specs/2026-09-04-software-development-layout-and-tracer-design.md`.
