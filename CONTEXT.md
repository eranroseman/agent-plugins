# agent-plugins

One repository states the skills a machine should have on Claude Code and Codex, converges a machine to that state, reports where a machine differs from it, and watches the upstreams it takes skills from. A contested term names the winner and lists the retired forms under _Avoid_.

## Language

**additional context**:
What the SessionStart hook prints into a session; Claude Code's own name for it.
_Avoid_: payload, payloads

**user**:
Whoever runs `bin/setup`, or no noun at all; a program is named, never called an installer.
_Avoid_: installer, installers

**instruction file**:
`CLAUDE.md` and `AGENTS.md`, what both CLIs call the file they read at the start of a session.
_Avoid_: carrier

**desired state**:
What the repository says a machine and its pinned upstreams should hold: the skills, the plugins, the vendored and forked trees, and the action pins. The verb _declare_ is a different word and stays.
_Avoid_: declaration, declarations

**first-party**:
A skill, agent or file written in this repository, as opposed to third-party.
_Avoid_: authored

**user-invocable only**:
A skill the user invokes and the model never selects on its own.
_Avoid_: gated

**subset entry**:
A marketplace entry that takes part of an upstream repository at a pinned commit: `superpowers` and `writing-clearly-and-concisely`.
_Avoid_: curated, curation

**skill selection**:
How an agent picks a skill for the task in front of it.
_Avoid_: routing

**agent CLI**:
Claude Code or Codex, where a sentence means either; a sentence that means one names it.
_Avoid_: harness, harnesses

**historical artifact**:
A spec once every plan written from it has run, and a plan once it has executed. Its vocabulary and paths are kept current so a reader today can follow it; its content is frozen.
_Avoid_: maintained record, working paper

**vendored**:
A tree that is upstream's at a pinned commit, held byte-identical by a drift test except for enumerated regions. Edits flow in from upstream.

**forked**:
A tree that is first-party and holds named fragments to upstream under a drift test. Edits flow out from here.

**tree with a drift test**:
A vendored or forked tree; the files this repository does not own outright.

### Leading words

Pinned so they read identically in every file; each recruits a meaning the reader already has.

**ladder** and **rung**:
Eliminate the problem, add a mechanism, add a rule, then prose; climb from the top and stop at the first rung that holds.

**gate**:
A condition that must hold before the next thing runs.

**drift**:
An upstream moved past a pin, or a machine differs from the desired state.

**spine**:
The superpowers process skills, brainstorm to finish.

**front door**:
`brainstorming`, where a build request enters the spine.
