# Roster, adoption routes, and the retirement of two repositories

**Status:** approved design, 2026-09-06. Sub-project 5 of 7, carrying the former sub-project 6.
**Scope:** which skills this marketplace carries, which plugin holds each, how each is adopted, where the four authored assets live, and the deletion of `eranroseman/harness-backup` and `eranroseman/rethink`.
**Not in scope:** whether the text of a rule changes what an agent does. That is [#23](https://github.com/eranroseman/agent-plugins/issues/23) and [#21](https://github.com/eranroseman/agent-plugins/issues/21) — the scaffolder's three defects, the `AGENTS.md` compression question, and the `diagnosing-bugs` routing baseline. It shares one file with this spec and blocks nothing in it.

## 1. Evidence standard

The prior tickets under [research-vault#53](https://github.com/eranroseman/research-vault/issues/53) were read in full as input. **Nothing on that map binds this design.** Its vocabulary — "decided", "measured", "evidence" — overstates what it holds, and the repository it describes has since been renamed, so every `knowledge-harness#N` link resolves into `research-vault`.

A claim below is a fact only when it rests on a primary source read on 2026-09-06: a file on this machine, a repository tree fetched from GitHub, a CLI `--help`, a live documentation page, or a session log. §12 lists each mechanism claim with its source.

Two survey passes read those tickets, 143 agents in total, each finding tagged VERIFIED, SUGGESTION or SUPERSEDED and every VERIFIED claim then re-checked by an independent agent instructed to reject it unless it could reproduce the evidence. **61 of them failed that re-check** and came back weakened or corrected. That ratio is the reason for this section, and the corrected forms are what appear below.

## 2. Purpose

Sub-project 2 shipped the machine layer: a marketplace, two plugins, a curated `superpowers` entry, `bin/setup`, `bin/doctor`, and a repository scaffolder that has now been through four repositories. What it did not settle is **which skills exist and where each one lives**.

Four authored assets are the forcing function. `consistency-audit`, its inspector agent, `finding-duplicate-functions` and `rethink-audit` live in `~/harness-backup/claude/`, symlinked live into both harnesses. They exist nowhere else. Until they have a home, `harness-backup` cannot be deleted, and until it is deleted the two global instruction files cannot empty.

## 3. Decisions

| Question | Decision |
| --- | --- |
| Which plugin holds a skill | `sensemaking` if it is **shared** or **not software-development-specific**; `software-dev` only when both are false (§4) |
| When a skill is copied into a plugin | Only when this marketplace must **change** it. Otherwise skills.sh, or a curated entry pinned by sha (§5) |
| The eighteen skills.sh skills | None moves. Their destinations are fixed **in advance** so a future adaptation does not relitigate placement (§4.2) |
| `consistency-audit` + inspector | Authored → `software-dev`. `permissionMode` deleted (§7.1) |
| `finding-duplicate-functions` | Vendored fork → `software-dev`, with provenance, drift test, LICENSE notice (§7.2) |
| `rethink-audit` | Authored → `sensemaking`, one reference repointed (§7.3) |
| `rethink` | **Deleted.** Its whole body already sits inside `rethink-audit` (§7.4) |
| `diagnosing-bugs` | Adopted, vendored → `software-dev`. **Not** gated — routing is its job, not the operator's (§6.1) |
| `adhd` | Adopted, **gated**, vendored → `sensemaking`. An expensive skill whose cost is the operator's call (§6.2) |
| `archify` | Adopted, skills.sh, pinned at `v2.16.0`. **Not** unpinnable (§6.3) |
| `writing-clearly-and-concisely` | Curated beside `sensemaking` at `path: "dist/plugins/..."` (§6.4) |
| The duplicated obra-dev pair | Drop the plugin, keep skills.sh — Codex's only route (§6.5) |
| `harness-backup` | **Deleted whole.** Thirty commits of config history accepted as lost (§8) |
| `eranroseman/rethink` | **Deleted.** #73 ruled this in 2026-08; none of its three obligations executed (§9) |
| Order | Migrate → prove on this machine → delete → empty both global files (§10) |

## 4. Which plugin holds a skill

### 4.1 The rule

> A skill belongs to `sensemaking` when **either** is true: it is **shared** by more than one product, or it is **not about software development**. It goes to `software-dev` only when both are false — its subject is software, and only that product needs it.

Sensemaking is the [organisational](https://en.wikipedia.org/wiki/Sensemaking) and [information-science](https://en.wikipedia.org/wiki/Sensemaking_%28information_science%29) term: turning a confused situation into one people can act on together — noticing what does not fit, naming it, and closing the gap between what someone knows and what they need to know. **It is not a synonym for reading, analysis, or documentation.**

That distinction is load-bearing, and this design records it because getting it wrong is cheap and silent. An earlier pass of this spec proposed a "reading versus building" split and placed `consistency-audit` and `setup-repository` in `sensemaking` on that basis. Both are wrong under the real rule: `consistency-audit` reads a repository's corpus and its configuration from `docs/agents/`, and `setup-repository` declares a repository's conventions. Both fail the second clause on inspection. The misreading happened because nothing in the repository stated the rule, so **`plugins/sensemaking/README.md` gains the definition above** as the first item of work.

### 4.2 The standing classification

Applying the rule to the eighteen skills `upstream/skills.json` declares:

| Plugin | Skills |
| --- | --- |
| **sensemaking** | `grilling` · `research` · `wayfinder` · `handoff` · `teach` · `to-questionnaire` · `wait-what` · `writing-for-agents` |
| **software-dev** | `codebase-design` · `domain-modeling` · `grill-with-docs` · `improve-codebase-architecture` · `prototype` · `resolving-merge-conflicts` · `triage` · `wizard` · `developing-claude-code-plugins` · `working-with-claude-code` |

`grill-with-docs` and `domain-modeling` sit with the code because both maintain ADRs and a glossary — project artifacts, not general ones. `writing-for-agents` is product-neutral.

**Nothing moves on this table.** Under §5 a skill is copied only when it must be changed, and none of the eighteen must be. What the table does is fix each destination in advance, so the day one of them needs a change the placement is already settled and is not relitigated under deadline. That is this section's output: not a migration, a standing answer.

It also prices `sensemaking` honestly. Eight of the eighteen would land there, so the plugin is not speculative — it is unoccupied, which is a different thing.

## 5. How a skill is adopted

Three routes, in ascending cost:

1. **skills.sh** — declared in `upstream/skills.json`, installed by `bin/setup` at a pinned ref, reaching both harnesses through `~/.agents/skills`. The name stays bare and `skillOverrides` still reaches it.
2. **Curated marketplace entry** — a `git-subdir` source pinned by sha, as `superpowers` is. No copy, no drift test. **Claude-only**: Codex has no curated-entry path, and its equivalent is a symlink farm `bin/setup` builds.
3. **Vendored** — copied into a plugin, with a provenance header, a drift test, and a LICENSE notice. Namespaced `<plugin>:<name>` and dropped from `upstream/skills.json` or it installs twice.

**A skill takes route 3 only when this marketplace must change it.** Sub-project 2's §12 declined the wholesale curated route for all eighteen mattpocock skills and listed its costs; that decision stands. What it did not decline was vendoring an individual skill, which is what `brainstorming` already is: `superpowers` is curated whole, and `brainstorming` was copied out of it because its description needed narrowing.

**Gate when the decision to invoke is inherently the human's; never to paper over a routing failure.** `adhd` is gated because spending five to ten times a normal answer on divergent ideation is a cost only the operator can authorise — they are in the loop by design. `diagnosing-bugs` is not gated, because an agent should reach for it unprompted when a bug resists reproduction, and requiring the operator to notice the wrong route was taken, interrupt, and type the right name is the failure rather than the fix. The two look like the same lever and are opposite decisions.

**`user-invocable-only` is not a fourth route.** `skillOverrides: {"<skill>": "user-invocable-only"}` was verified to reach skills.sh skills on Claude Code 2.1.263, and it was considered here for `diagnosing-bugs`. It is rejected as a general instrument: it produces the same outcome as not adopting the skill at all — one that only a user who already knows it exists can reach — while charging a settings key, a declaration and a lockfile entry for the privilege. Where a skill needs gating, rejection is the cheaper form of the same answer. Where it needs to fire correctly, only its description can do that.

## 6. The roster

### 6.1 `diagnosing-bugs` — adopt, vendor, do not gate

**The capability gap is real.** `superpowers:systematic-debugging` treats "Reproduce Consistently" as one bullet inside Phase 1. `diagnosing-bugs` makes the reproduction loop its entire Phase 1 — *"This is the skill. Everything else is mechanical"* — with ten ranked construction techniques, a tightening pass, a strategy for non-deterministic bugs, and an exit criterion that requires naming one command already run. It adds four things the other lacks entirely: minimisation to the smallest still-red scenario, three to five ranked falsifiable hypotheses shown before testing, a performance branch that measures before it logs, and tagged `[DEBUG-…]` instrumentation so cleanup is one grep.

**One audited instance supports it.** `docs/product-landscape/2026-08-25-coding-companion-plugins-comparison.md` records, of this repository's own work: *"the run's most expensive error class … maps onto its Phase-1 red-capable-loop criterion; systematic-debugging has no equivalent."*

**The collision was never measured and could not have been.** `diagnosing-bugs` has never been installed on this machine — absent from all three skill roots, both plugin caches, and the lockfile — so no session has ever held both in one catalog. Every claim about the trigger race is inference from two descriptions. The 2026-08-31 approval recorded in #60 and #75 is a **lapsed recommendation**: two of its three premises are dead, since the vendoring route it assumed was reversed on 2026-09-04 and its claim that `skillOverrides` cannot reach the skill is false on the route actually taken.

**The description has two independent defects.** At 156 characters it exceeds Codex's measured 122-character truncation, so Codex sees a fragment ending mid-list — broken irrespective of any collision. And its trigger list overlaps `systematic-debugging`'s almost entirely.

So: **vendored into `software-dev`**, with the description rewritten. The rewrite is the mechanism, not a workaround for one — a gated skill needs a human to notice the wrong route was taken, interrupt, and type the right name, which is enforcement by attention on every hard bug.

This spec ships a description that fixes the truncation and states the routing clause provisionally:

> Use when a bug resists reproduction, or for a performance regression.

69 characters, surviving Codex whole and disjoint from `systematic-debugging`'s 91.

**The routing was measured, 2026-09-06.** Two rounds of a selection experiment: a realistic catalogue of both contested skills plus seven installed distractors, one user request, the agent naming the single skill it would invoke and never asked why — asking makes an agent justify a choice and destroys the measurement.

Round one, five discriminating scenarios by five replicates, returned **25/25 in both arms**. That is the shape `writing-skills` warns about: a control that never exhibits the failure means either there is nothing to fix or the scenarios are too easy. Round one tested clear cases and never used the current description's own trigger vocabulary.

Round two did. Six scenarios that attach `debug this`, `broken`, `throwing`, `slow`, `diagnose` and `failing` to deterministically reproducible bugs, plus two genuinely ambiguous prompts scored separately:

| Scenario, all owned by `systematic-debugging` | Current | Rewritten |
| --- | --- | --- |
| "**Debug this**: NPE at line 42, every time I click Save" | 1/5 wrong | 0/5 |
| "The build is **broken**. Fix it." | 1/5 wrong | 0/5 |
| "**throwing** on empty input, deterministically" | 0/5 | 0/5 |
| "Can you **diagnose** why the parser fails? Fails identically every run." | **5/5 wrong** | 0/5 |
| "Two tests **failing** since my last commit, reproduces every run" | 0/5 | 0/5 |
| **Total** | **7/25** | **0/25** |

The failure concentrates where the description invites it: the bare word *diagnose* pulls `diagnosing-bugs` five times out of five onto a reproducible parser bug. On the ambiguous pair the current description is also unstable — a 3/2 split on one, and *"something's broken and I'm not sure where to start"* routed to `diagnosing-bugs` 5/5, which is backwards, since not knowing where to start is the front door's job. The rewritten description is stable and correct on both.

**Round three measured recall** — whether the skill fires when it is genuinely needed — on positives that deliberately avoid the new description's vocabulary: *"Sentry shows this crash twice a day, I have never once made it happen myself"*, *"git bisect points at a commit that only touches the README"*, *"two customers have reported it, we have never seen it internally"*. Two obvious reproducible bugs served as controls.

| | Current | Rewritten |
| --- | --- | --- |
| **Recall**, five scenarios | 24/25 | **25/25** |
| **Control**, two scenarios | 7/10 | **10/10** |

Across rounds two and three the rewritten description is **0 false positives in 35 negative trials and 25 of 25 on recall**. The current description misses one recall and three controls, two of them leaking to `test-driven-development` on a plain stack trace.

**Two scenarios are excluded, and both were the author's error rather than the descriptions'.** One sent 5/5 to `test-driven-development` in *both* arms because it stated the cause was already identified, which makes writing a failing test first correct. The other — *"I've tried three different fixes and none of them helped"* — is `systematic-debugging`'s documented territory: its body lists *"You've already tried multiple fixes"* and *"Previous fix didn't work"* under **Use this ESPECIALLY when**. Both expectations were written without reading the competing skill's body first, which is the check that would have caught them.

**Limits of this evidence.** It measures description-based selection with the descriptions in context, not a live catalogue on either harness. Two of eighty round-three cells returned with the safety classifier unavailable; both were current-description cells and both returned a bare skill name, so the risk to the result is negligible but it is recorded rather than dropped. It is a proxy, and a strong one for the mechanism at issue — the model reads descriptions and picks — but a live confirmation on both harnesses belongs to [#23](https://github.com/eranroseman/agent-plugins/issues/23)'s campaign.

Option E from #60 — restructuring `systematic-debugging` into a three-path classifier — is **unexecutable** and is not adopted. That file arrives through a `git-subdir` entry pointing at unmodified upstream; nothing local can edit it without vendoring a second skill out of the curated set.

### 6.2 `adhd` — adopt, gate, vendor into `sensemaking`

`UditAkhourii/adhd`, MIT, v0.1.4, pushed 2026-08-29. **Not the single-file skill the tickets describe**: a TypeScript CLI — `src/engine.ts`, `src/llm.ts`, `bench/`, `EVALS.md` — plus one skill at `skills/adhd/SKILL.md`, and a `.claude-plugin/marketplace.json` of its own. Only the skill is taken: its body states the loop runs "inside Claude with no install required", so `npm install -g adhd-agent` is an optional accelerant rather than a dependency.

**It is not gated, and it should be.** From its own body:

> This skill is expensive. About 10 Agent calls, 30 to 90 seconds wall clock, 5 to 10x a single answer. **Do not pay that cost when a direct answer is better. Run this gate before Phase 1.**

The skill defends its own cost by asking the model to talk itself out of running — prose at the bottom of the ladder. `disable-model-invocation: true` makes it structural, and it places `adhd` with the five gated escalation skills already on the roster: `wayfinder`, `handoff`, `teach`, `to-questionnaire`, `wait-what`. All five are gated upstream, verified on this machine. That is the class it belongs to.

**Gating dissolves two collisions, not one.** Its description claims *"brainstorm/ideate intents, or open-ended design, architecture, naming, API/SDK surface"*, which runs into `software-dev:brainstorming`, and *"fuzzy-debugging decisions"*, which runs into `systematic-debugging`. A gated skill competes for neither. The parent spec's standing instruction — that `adhd`, if adopted, is checked against `brainstorming`'s narrowed description — is discharged this way rather than by a second rewrite.

Its description is also **over 500 characters** against Codex's 122, so Codex sees a fragment ending inside the cognitive-frame list. On Codex the equivalent gate is `policy.allow_implicit_invocation: false`; the repository ships no `agents/` directory, so `agents/openai.yaml` is authored here.

Two changes — the gate and the Codex yaml — so route 3.

**Correct the record while writing it.** #80 and #111 both eliminate the skills.sh route by inferring install shape from repository shape. Upstream prescribes `npx skills add UditAkhourii/adhd`, so that route was open; it is foreclosed by the decision to gate, which is the honest reason to close it. #111's rung 2, forking, is not adopted: it buys merge flow at the price of a repository and permanent merge duty.

### 6.3 `archify` — adopt, skills.sh, pinned

**[#110](https://github.com/eranroseman/research-vault/issues/110)'s title premise is false.** `archify` is pinnable by the mechanism this repository already uses:

```
npx skills add tt-a1i/archify#v2.16.0 --skill archify -g -y
```

`#` is the ref selector. [bin/setup:441](../../../bin/setup) has been using it since 2026-09-05. The ticket reasoned from `@`, the wrong sigil. So `archify` is an ordinary pinned source — a third entry in `upstream/skills.json` at annotated tag `v2.16.0` — and the moving-branch, release-zip and fork trilemma the ticket posed dissolves. Two of those three would have produced assets `bin/upstream-watch` and `tests/test-skills-pin.sh` cannot represent.

Three edits follow:

- `tests/test-skills-pin.sh` asserts `[ "$total" -eq 18 ]`; it becomes 19.
- `bin/upstream-watch`'s prerelease filter matches `-alpha|-beta`. `archify` uses `-dev.N` and publishes a parallel `archify-dsh-*` tag series, so an unwidened filter will pick a dev tag as "newest" and report false drift indefinitely.
- **`archify` calls `tt-a1i.github.io` on every run** unless `ARCHIFY_UPDATE_CHECK_DISABLED=1` is set. A skill that phones home per invocation is a roster fact, and `bin/setup` sets that variable.

The #110 comment generalising the pinning finding across the whole installed set is retracted: as of 2026-09-06 the lockfile holds eighteen entries and none without a ref.

### 6.4 `writing-clearly-and-concisely` — curate

MIT, © 2026 Leonardo Flores, `softaworks/agent-toolkit` at sha `3027f20f3181`. Eight files: one skill plus the Elements of Style chapters. It needs no change, so route 2.

**The path matters and the obvious one is wrong.** `git-subdir` copies the whole subdirectory regardless of the `skills` allowlist — proven on this machine, since `brainstorming` sits in our `superpowers` cache despite being excluded from that entry. So `path: "skills"` would land all of agent-toolkit's skills on disk to load one. The entry uses upstream's own published shape:

```json
{ "source": "git-subdir", "path": "dist/plugins/writing-clearly-and-concisely",
  "sha": "3027f20f3181…", "strict": false,
  "skills": ["./skills/writing-clearly-and-concisely"] }
```

The `dist` and source trees are byte-identical at this sha, and a test asserts that equality at the pin the way `test-upstream-pin.sh` asserts the thirteen directories.

Three things ship with it or the decision is half-executed. **This is a migration, not a new adoption** — `writing-clearly-and-concisely@agent-toolkit` is installed on this machine right now at the identical sha, and leaving it produces two catalog entries emitting the same string. Upstream ships no plugin manifest and no version, so Claude fell back to the sha prefix; the version field is decided here rather than inherited. And **curation reaches Claude only** — Codex gains the skill through `bin/setup`'s symlinks or not at all.

### 6.5 The duplicated pair

`working-with-claude-code` and `developing-claude-code-plugins` arrive **twice**: through skills.sh, and through the installed `superpowers-developing-for-claude-code` plugin. Measured 2026-09-06, both routes live. This is the hazard that sent a bare invocation to the unadapted scaffolder during sub-project 2's cutover.

Drop the **plugin**, keep skills.sh. Keeping the plugin would leave Claude with two copies and Codex with one, since skills.sh is Codex's only route.

**Nothing can enforce absence.** A plugin manifest carries `dependencies` and no inverse, on either harness — Claude's keys are `author dependencies description homepage hooks keywords license name repository version`, Codex's the same shape plus `interface` and `skills`. There is no `conflicts`, no `replaces`, no `provides`. So a plugin cannot declare that installing it should remove something else, and the only available mechanism is detection.

This design creates three such cases: this pair, `writing-clearly-and-concisely@agent-toolkit` against the curated entry (§6.4), and `adhd` if it is ever installed from its own marketplace alongside the vendored copy. `bin/setup` already does this once, for `setup-matt-pocock-skills`, as a one-off `note`. That becomes a **declared conflict list** the doctor checks — a table of "if this is installed, ours is duplicated", reported rather than repaired, since removing another marketplace's plugin is not this script's business.

### 6.6 Roster items closed without work

**`grilling` versus `brainstorming`** needs nothing. The descriptions are disjoint, `skillOverrides` was removed on 2026-09-05, and the stale prose in both global files was deleted on 2026-09-06.

**The out-of-scope-bug mechanism** is carried by [#20](https://github.com/eranroseman/agent-plugins/issues/20) and nothing is built. Sub-project 3 shipped an admission standard — evidence that the problem exists, plus dependence on nothing beyond the plugin — and this mechanism fails both legs. `research-vault#84` is closed against #20; it is unblocked and unassigned, so a wayfinder frontier query would otherwise hand it to a session that re-decides a settled question.

**Prior-art search** is not closable as solved-by-`research`, which the earlier draft of this spec assumed. `research` is twelve lines with no corpus routing, citation graph, screening or gate. But `research-vault#82` is stale on all three of its load-bearing premises: its blocker closed 2026-09-04, its structural question was overtaken when prior-art search became **R26, a phase inside a specified-but-unbuilt `writing-reqs` skill**, and its landscape survey omits the upstream the author vendored three days before writing it — now live vault-side as `find-sources`. It is replaced by a narrower item on [#10](https://github.com/eranroseman/agent-plugins/issues/10).

**The requirements skills are not deferred, because the need is not established.** The work was specified as `writing-reqs` (39 requirements) and `sourcing` (19), both unconfirmed, in `research-vault/docs/superpowers/reqs/`. The research that was meant to close a perceived gap **widened the frame instead** and left the author unconvinced that a skill is the right answer to it.

"Deferred" would be the wrong word to leave in the record: it invites a later session to treat the specification as approved work waiting for a slot. **The need analysis is the work**, and it precedes any decision about `writing-reqs`, its prior-art phase, or competitive analysis. [#19](https://github.com/eranroseman/agent-plugins/issues/19) is the durable home; its body currently attributes #72's language to #81 and is repaired to say this instead.

**`consistency-audit` versus adversarial verification** ([#79](https://github.com/eranroseman/research-vault/issues/79)) **closes.** It has no second party — **no skill, command, agent or template named adversarial-verification exists** on this machine or in either marketplace — and no skill is wanted.

The evidence is this design's own construction. Two survey passes ran 143 agents over the prior tickets, every VERIFIED claim re-checked by an independent agent instructed to reject it unless the evidence reproduced, and **61 claims were downgraded**. That is adversarial verification performed at scale, driven by prompt alone, with no skill in existence and none missed. Agents do this when asked; a skill would be codifying a capability that is already reliable on request.

`consistency-audit` separately implements the whole method internally — an Iron Law forbidding unrefuted findings, two independent readers, a skeptic that did not raise the candidate, a four-way verdict taxonomy, a published refuted list, and an author-adjudication gate — so there is nothing left for a second artifact to own.

## 7. The four authored assets

### 7.1 `consistency-audit` and its inspector → `software-dev`

Authored. After `harness-backup` is deleted this repository is their only version, so there is no upstream, no provenance header and no drift test. They move together: the inspector is dispatched by the skill and by nothing else.

**`permissionMode: plan` is deleted from the inspector.** It guards nothing. The tool grant is `Read, Bash, WebFetch, WebSearch` — no write tool for plan mode to block — and the only write vector is Bash, which plan mode permits. Read-only is enforced where it already was: by the tool grant, and by a body that says *"Never create, edit, delete, stage, commit, switch branches, alter refs, install software, or change repository state."* No commit in the file's history explains the field. Deleting it also dissolves a migration hazard, since Claude Code's handling of `permissionMode` for plugin-shipped agents no longer matters to anything.

**A cost this placement carries, priced here rather than discovered later.** A Codex plugin cannot bundle a subagent declaratively — its manifest's components are skills, hooks, MCP servers, apps and interface. So on Codex, `consistency-audit` degrades to a single-reader, single-pass audit, losing the two-independent-readers property its own Iron Law rests on. The skill states that degradation in its own text rather than failing silently.

Worth recording: **the inspector has more than five times the invocation count of the skill that owns it.** The agent is the load-bearing half of the pair.

### 7.2 `finding-duplicate-functions` → `software-dev`

**Vendored**, and the only one of the four that is. A rewritten fork of `finding-duplicate-functions` in `obra/superpowers-lab` (MIT), carrying its own `PROVENANCE.md`: upstream's extractor is TypeScript and returns zero functions against Python, so phase 1 was rewritten and a structural pre-filter added. Six files including four under `scripts/`.

It takes the full vendoring treatment — provenance header, a drift test against upstream, a LICENSE notice — because it has an upstream that can move.

### 7.3 `rethink-audit` → `sensemaking`

Authored, and already copied into `sensemaking` byte-identically on 2026-09-04. One adaptation: its Boundaries section names `superpowers:brainstorming`, which **resolves to nothing in this marketplace** — the curated `superpowers` entry deliberately excludes that skill, which ships as `software-dev:brainstorming`. Same dangling-reference class as `using-superpowers:30`, and the same one-line fix the SessionStart hook already makes there.

Its other four references resolve correctly: `research`, `codebase-design`, `superpowers:writing-plans`, and "put it where the repository already keeps such notes".

Two things recorded and not acted on. `rethink-audit`'s `requires:` step and the specified `writing-reqs` skill both emit R-numbered requirement lines with per-item provenance, and the seam between them is real but undrawn; `writing-reqs` does not exist, so pointing Boundaries at it would replace one dangling reference with another. And its `prior-art:` step delegates to `research`, which §6.6 establishes does not do prior-art search.

### 7.4 `rethink` — deleted

Its entire body:

> Run a `/rethink-audit` pass on a fresh design question: no implementation exists, so work through `design:` and finish at `trade-offs:`.

`rethink-audit` already says, in its Method:

> On a fresh design question there is no implementation: run through `design:`, then `trade-offs:`.

The stub is a second name for an instruction already inside the file it delegates to. `research-vault#73` reached the same conclusion in 2026-08 and **none of its three obligations were executed**; they are work items in §10, not history.

## 8. Retiring `harness-backup`

### 8.1 Why the original argument does not apply

`research-vault#64` proposed a **backup-to-intent inversion**: the five copied files become repository-authored templates, `bin/setup` deploys them, and hand-editing a live file becomes drift for the doctor to catch.

**That mechanism was formally declined.** Sub-project 2's §3 and §7.6 rule that neither script ever writes a configuration file by hand, on either harness. So this retirement is not #64's proposal executed; it is a deletion without a replacement, and it must be argued on its own terms.

### 8.2 What the repository holds, sorted

Twenty-one tracked files.

**Twelve move here** — the four skills and the inspector agent, per §7.

**Six are dead or derived.** `bin/harness-drift-check.py` is superseded on both halves: `.github/workflows/upstream-watch.yml` covers the upstream half and `bin/doctor` the local one. `agents/.skill-lock.json` is derived from `upstream/skills.json`. `claude/CLAUDE.md` and `codex/AGENTS.md` go empty at §10 step 8. `.drift-state.json` and `.drift-cron.log` die with the detector.

**Two cannot come here, and are deleted with their history.** `claude/settings.json` (16 commits) and `codex/config.toml` (14) are personal machine state: `model`, `theme`, `effortLevel`, a statusline pointing into a plugin cache, nine `[projects.*]` trust entries naming absolute paths on this machine, a GitKraken MCP server. **`agent-plugins` is a public marketplace**; publishing either file ships a directory layout and editor preferences to anyone who clones it. Sub-project 2's §7.4 already forbids `--scope project` for exactly this reason, and folding the backups in would do by hand what that rule forbids by script.

Nothing else versions them. `~/.claude/backups` holds rotations of `.claude.json`, a different file, and is empty. **The loss accepted is the restore path** — thirty commits of history, and any way back from a bad hand-edit. The live files themselves are untouched by deleting a repository that copies them.

**One is archived**: `specs/2026-08-08-harness-update-design.md`, a design for a skill never written, whose own header records that all three baselines passed so `writing-skills` said not to author it.

### 8.3 What `rm -rf` breaks beyond the file list

The file accounting is not the deletion's blast radius:

- **A live weekly cron**, `17 9 * * 1`, invoking a script that no longer exists
- **Eight symlinks** across `~/.claude/skills` and `~/.codex/skills` pointing into the deleted tree
- **An open issue in `eranroseman/memoria-vault`**, the drift detector's out-of-repo destination
- The `rethink` marketplace registration and `~/dev/rethink` (§9)
- Three gitignored state files

Every one is an explicit step in §10.

### 8.4 What `bin/doctor` did not absorb

Recorded so the retirement does not claim more than it delivers. Three checks were **dropped**, not merged: `cli_drift`, `skill_asymmetry`, and `copies_drifted`. Ten of eleven marketplaces are locally unwatched. None of `research-vault#78`'s three offered checks shipped, though its derived-watched-set requirement did.

`copies_drifted` is the one that mattered, and it dies with its subject: it watched the five copied files, and after this retirement there are none.

### 8.5 The cron is not a fallback

It is tempting to hold the deletion until `upstream-watch` proves its schedule, since it has **never run on cron** — verified 2026-09-06, with a manual dispatch succeeding in 10 seconds, so the mechanism is sound and only the schedule is unproven ([#24](https://github.com/eranroseman/agent-plugins/issues/24)).

The weekly cron is not a fallback for it. Measured 2026-09-05: since the 2026-09-04 cutover removed `superpowers-dev` and added `eranroseman`, that detector's marketplace check compares **this repository** against its remote rather than `obra/superpowers`. It stopped watching what it was built to watch. Keeping it preserves nothing, and a repository is not kept alive around a scheduling question in a different repository.

## 9. Retiring `eranroseman/rethink`

A published marketplace: plugin v1.0.1, two skills, a `hooks/` directory never used, registered on Claude and installed on neither harness. Its copies of `rethink` and `rethink-audit` have **diverged** from the authored originals and lack the `agents/` directory those carry.

`research-vault#73` ruled on this in 2026-08 and none of it was carried out. The obligations, unchanged: de-register the marketplace, delete the repository, delete the two `harness-backup` copies, apply the adaptation. Nothing is taken from it — the authoritative copies are the authored ones in §7.

## 10. Sequencing and the gate

Migrate, prove, then delete. The gate is the only step that requires evidence rather than action, and it is the point of no return — sub-project 2's cutover used the same shape.

1. `plugins/sensemaking/README.md` gains the §4.1 definition
2. `sensemaking`: `rethink-audit` with its reference repointed
3. `software-dev`: `consistency-audit` + inspector minus `permissionMode`; `finding-duplicate-functions` with provenance, drift test, LICENSE notice
4. Delete the `rethink` stub from both locations
5. `diagnosing-bugs` vendored into `software-dev`; `adhd` vendored into `sensemaking`, gated on both harnesses, with an authored `agents/openai.yaml`; `archify` declared in `upstream/skills.json` at `v2.16.0`; `ARCHIFY_UPDATE_CHECK_DISABLED=1` set by `bin/setup`; `test-skills-pin.sh` count to 19; `upstream-watch`'s prerelease filter widened
6. `writing-clearly-and-concisely` curated at `dist/plugins/…`; the `agent-toolkit` install removed
7. The `superpowers-developing-for-claude-code` plugin uninstalled
8. **Gate.** Measured on this machine: every migrated skill loads from its plugin on both harnesses; the eight `harness-backup` symlinks are gone; `bin/doctor` reports clean; `claude plugin list` and `codex plugin list` agree with the manifests
9. `eranroseman/rethink`: de-register the marketplace, then delete the repository and `~/dev/rethink`
10. `harness-backup`: remove the crontab line, close the `memoria-vault` drift issue, archive the historical spec, then delete the repository
11. Remove the intro paragraph from `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`. Every surviving repository now has an `AGENTS.md`, so it self-negates as sub-project 2's §4.1 predicted, and both files go empty

Step 11 is why the order runs this way: **the retirement makes its own precondition true.**

## 11. Positions from the tickets not adopted

| Position | Disposition | Why |
| --- | --- | --- |
| `diagnosing-bugs` at rung 4, hard-gated (#60, #75) | Not adopted | A lapsed recommendation. Two of three premises dead, and gating charges attention on every hard bug for the outcome rejection gives free |
| Option E, the three-path classifier in `systematic-debugging` (#60) | Not adopted | Unexecutable against a `git-subdir` install of unmodified upstream |
| `archify` is unpinnable (#110) | **Refuted** | `#` is the ref selector; `bin/setup:441` has used it since 2026-09-05 |
| Fork `UditAkhourii/adhd` (#111 rung 2) | Not adopted | Buys merge flow for one skill file at the price of a repository and permanent merge duty. The survey's supporting claim, that the file is unchanged since 2026-06-04, is dropped: the repository was pushed 2026-08-29 and per-file staleness was not verified |
| `adhd` cannot use skills.sh (#80, #111) | **Refuted** | Both inferred install shape from repository shape; upstream prescribes `npx skills add` |
| The backup-to-intent inversion (#64) | Not adopted | Its mechanism was declined in sub-project 2's §3 and §7.6 |
| A `--capture` mode (#62) | Not adopted | Moot once nothing is backed up |
| `research` covers prior-art search | **Refuted** | Twelve lines; no corpus routing, citation graph, screening or gate |
| `consistency-audit` versus adversarial-verification as a boundary (#79) | **Closed** | No second party exists, and none is wanted: 143 agents in this design's own surveys performed adversarial verification on prompt alone, downgrading 61 claims |
| An adversarial-verification skill | Not adopted | The capability is reliable on request; a skill would codify what already works |

## 12. Mechanism claims and their sources

| Claim | Source |
| --- | --- |
| `git-subdir` copies a whole subdirectory regardless of the `skills` allowlist | `brainstorming` present in this machine's `superpowers` cache despite exclusion |
| Codex plugins cannot bundle a subagent declaratively | The Codex plugin manifest's component list |
| `skillOverrides: user-invocable-only` reaches skills.sh skills | Claude Code 2.1.263, read on this machine |
| A hand-added `policy:` block in an installed skill is clobbered on update | The skills.sh lockfile hash-tracks skill folders |
| Codex truncates descriptions at ~122 characters | Measured 2026-09-05, 198-character source |
| `#` is the skills.sh ref selector | `bin/setup:441`, in use since 2026-09-05 |
| `upstream-watch` runs correctly on demand | Run 34048034312, 2026-09-06, 10s, success |
| `diagnosing-bugs` has never been installed here | Absent from three skill roots, both plugin caches, and the lockfile |
| The inspector outweighs its skill 5:1 in invocations | Session transcript archive |
| `permissionMode` is set by no shipped plugin agent on this machine | caveman ×3, codex ×1, all absent |

Two claims are marked weaker than their sources suggested. Plan mode's exact Bash behaviour was **not** read from the installed binary, which could not be located; §7.1's conclusion rests on the tool grant and the body, not on that inference. And deleting `harness-backup` costs the **restore path**, not the current content of the two live configuration files, which the survey overstated.

## 13. Open items carried forward

- The `diagnosing-bugs` routing clause is measured by proxy (§6.1); live confirmation on both harnesses belongs to [#23](https://github.com/eranroseman/agent-plugins/issues/23).
- `writing-reqs` and `sourcing` are specified and unbuilt, and the **need analysis precedes them** — the research meant to close the gap widened the frame instead. [#19](https://github.com/eranroseman/agent-plugins/issues/19)'s brief is repaired to say so.
- Prior-art search and competitive analysis sit inside `writing-reqs` and wait on the same need analysis.
- A declared conflict list for `bin/doctor` (§6.5), since no manifest can express absence.
- `neuroarxiv` ([#88](https://github.com/eranroseman/research-vault/issues/88)) is untouched here.
- Whether `upstream-watch`'s schedule works is [#24](https://github.com/eranroseman/agent-plugins/issues/24), and gates nothing in this spec.
- `research-vault#53` is unmaintained. This spec supersedes it for every question above.
