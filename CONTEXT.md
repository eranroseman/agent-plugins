# agent-plugins

One repository states the skills a machine should have on Claude Code and Codex, converges a machine to that state, reports where a machine differs from it, and watches the upstreams it takes skills from. The words below are the ones its files use for that. A contested entry names the winner and lists the retired forms under _Avoid_; a leading word is pinned so it reads the same in every file.

## Language

**additional context**:
What the SessionStart hook prints into a session; Claude Code's own name for it.
_Avoid_: payload, payloads

**user**:
Whoever runs `bin/setup`, or no noun at all. The tool that installs skills is named: `skills.sh`.
_Avoid_: installer, installers

**instruction file**:
`CLAUDE.md` and `AGENTS.md`, what both CLIs call the file they read at the start of a session.
_Avoid_: carrier

**desired state**:
What `skills.json` and the marketplace manifest declare and `bin/setup` converges a machine to. The verb _declare_ is a different word and stays.
_Avoid_: declaration, declarations

**first-party**:
A skill, agent or file written in this repository, as opposed to third-party.
_Avoid_: authored

**user-invocable only**:
A skill the user invokes and the model never selects on its own; Claude Code's own `skillOverrides` value. On Claude Code it is `disable-model-invocation: true`, on Codex `allow_implicit_invocation: false`.
_Avoid_: gated

**subset entry**:
A marketplace entry that takes part of an upstream repository at a pinned commit: `superpowers` and `writing-clearly-and-concisely`.
_Avoid_: curated, curation

**skill selection**:
How an agent picks a skill for the task in front of it.
_Avoid_: routing

**Claude Code, Codex, agent CLI**:
The two, or the generic. A sentence that means one names it; _agent CLI_ appears only where a sentence means either.
_Avoid_: harness, harnesses

**historical artifact**:
A spec once every plan written from it has run, and a plan once it has executed. Its vocabulary and paths are kept current so a reader today can follow it; its content is frozen.
_Avoid_: maintained record, working paper

**vendored**:
A tree that is upstream's at a pinned commit, held byte-identical by a drift test except for enumerated regions, and updated by re-vendoring. Edits flow in from upstream.

**forked**:
A tree that is first-party and holds named fragments to upstream under a drift test, updated by editing here. Edits flow out from here. _Trees with a drift test_ is the superset of both, and is the formatter's exclusion class.

### Leading words

Pinned so they read identically in every file; each recruits a meaning the reader already has.

- **ladder** and **rung**: eliminate the problem, add a mechanism, add a rule, then prose; climb from the top and stop at the first rung that holds.
- **gate**: a condition that must hold before the next thing runs: the runner's hard gate, a skill's invocation gate, the `claude` and `codex` gates in `bin/setup`, and a milestone's gate.
- **drift**: an upstream moved past a pin, or a machine differs from the desired state.
- **spine**: the superpowers process skills, brainstorm to finish.
- **front door**: `brainstorming`, where a build request enters the spine.

## Relationships

- `bin/` holds what a user runs; `scripts/` holds what CI and the maintainer run.
- A path in another repository is written `owner/repo:path`, or `owner/repo@ref:path` when the ref matters, so the reference check can tell it from a path here.
- The desired state lives in two files: `.claude-plugin/marketplace.json` for the plugins and the subset entries, `skills.json` for what `skills.sh` installs. `bin/setup` converges a machine to both; `bin/doctor` is the same engine in check mode.

## Flagged ambiguities

- "installer" meant both a person and a program. Resolved: the person is the **user**; the program is named, `bin/setup` or `skills.sh`.
- "payload" meant the hook's output here and the hook's input everywhere else. Resolved: **additional context**, the CLI's own word.
- "vendored" and "forked" were used as if defined. Resolved by the direction edits flow, above.
- "curated" read as editorial praise for what is a subtraction. Resolved: **subset entry**.
- "first-party" once meant Anthropic's own marketplace in the 2026-09-04 layout spec. That sense is historical and stays there; here the word means written in this repository.
- The `upstream` directory read as a copy of an upstream repository and held this repository's own dependency manifest. Resolved: `skills.json` at the root.
- "gate" was audited for divergent senses on 2026-09-23 and carries one, a precondition, in each of its uses.
- "admission" and "tracer bullet" were candidates for the leading words and appear in no durable file; dropped.
