# sensemaking

Skills shared by `software-dev` and, later, `research-vault`.

## Which plugin holds a skill

A skill belongs to `sensemaking` when **either** is true: it is **shared** by
more than one product, or it is **not about software development**. It goes
to `software-dev` only when both are false — its subject is software, and
only that product needs it.

Sensemaking is the organisational and information-science term: turning a
confused situation into one people can act on together — noticing what does
not fit, naming it, and closing the gap between what someone knows and what
they need to know. **It is not a synonym for reading, analysis, or
documentation.** `consistency-audit` reads a repository's corpus and its
configuration from `docs/agents/`; `setup-repository` declares a
repository's conventions. Both are about software and both live in
`software-dev`, whatever a "reading versus building" split would suggest.

The rule is applied in advance to every skill `upstream/skills.json`
declares, so the day one of them needs a change its placement is already
settled and is not relitigated under deadline. Nothing moves on this table
until a skill must change; a skill is copied into a plugin only then.

| Plugin | Skills |
| --- | --- |
| **sensemaking** | `grilling` · `research` · `wayfinder` · `handoff` · `teach` · `to-questionnaire` · `wait-what` · `writing-for-agents` |
| **software-dev** | `codebase-design` · `domain-modeling` · `grill-with-docs` · `improve-codebase-architecture` · `prototype` · `resolving-merge-conflicts` · `triage` · `wizard` · `developing-claude-code-plugins` · `working-with-claude-code` |

`grill-with-docs` and `domain-modeling` sit with the code because both
maintain ADRs and a glossary — project artifacts, not general ones.
`writing-for-agents` is product-neutral.

## Skills

- `rethink-audit`: clean-slate redesign audit of an existing module, service,
  or feature. Design and architecture only; it applies no changes.

## Install

Claude Code: installing `software-dev@eranroseman` pulls this plugin
in as a dependency. To install it alone:

    claude plugin marketplace add eranroseman/agent-plugins
    claude plugin install sensemaking@eranroseman

Codex has no dependency concept, so install it explicitly:

    codex plugin marketplace add https://github.com/eranroseman/agent-plugins.git
    codex plugin add sensemaking@eranroseman

## License

MIT. See `LICENSE`.
