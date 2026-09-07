> Archived from `eranroseman/harness-backup` (`specs/2026-08-08-harness-update-design.md`) on 2026-09-06, when that repository was deleted; see `docs/superpowers/specs/2026-09-06-roster-and-retirement-design.md` §8.2. The mechanisms that replaced the detector it describes are `bin/doctor` and `.github/workflows/upstream-watch.yml`.

# harness-update — design (not built)

> **Outcome: the skill was not written.** All three baseline scenarios passed
> without it, so by the rule in `writing-skills` — if the no-guidance control
> does not exhibit the failure, there is nothing to fix — the guidance was never
> authored. What the baselines found instead is recorded at the end. The design
> below is kept because the surface map is accurate and reusable, with the one
> correction noted in **Where this design was wrong**.

A skill that checks every layer of the Claude Code and Codex harness for
available updates, decides which are safe to apply, applies those, and reports
the rest with the evidence and a concrete next step.

## Why

The harness is assembled from nine marketplaces, twenty-two installed skills,
three authored skills, and two CLIs, each with its own update mechanism and none
of them aware of the others. Nothing today answers "what changed upstream, and
is it safe to take?"

Two failures are present right now, both found while designing this, and both
invisible to any update-only tool:

- `superpowers` has cached versions 6.1.1 and 6.2.0. A single session loaded
  `writing-skills` from 6.1.1 and `brainstorming` from 6.2.0.
- `~/.local/share/claude/versions/` holds three Claude Code versions, 732 MB,
  with one active.

Stale-version accumulation repeats at every layer of the stack, so the skill
treats current-state health as a first-class output rather than a side effect of
upgrading.

## Scope

Two tiers, because the risk differs.

**Upgrade when safe:**

| Surface | State | Detect | Apply |
| --- | --- | --- | --- |
| Claude plugins | `~/.claude/plugins/installed_plugins.json` (`version`, `gitCommitSha`) | `claude plugin marketplace update`, compare sha to clone HEAD | `claude plugin update <plugin>` |
| Codex plugins | `~/.codex/config.toml` `[marketplaces.*]` (`last_revision`) | `codex plugin marketplace` | `codex plugin add` / `remove` |
| Installed skills | `~/.agents/.skill-lock.json` (`sourceUrl`, `skillFolderHash`) | compare hash to upstream | `npx skills update <skill>` |

**Detect and report only, never apply:**

| Surface | Detect | Why not applied |
| --- | --- | --- |
| `claude` CLI (2.1.220) | `claude update` reports and installs; the skill reports the availability and hands over the command | Upgrading the harness from inside a session running on it is self-surgery; it ships its own updater |
| `codex` CLI (0.142.5) | `codex update` likewise | Same, and it is a system package |
| `skills` CLI (1.5.22) | `npm view skills version` against the cached copy | `npx` resolves latest per call, so it self-updates; only a major bump matters, because it could change the lock format everything else depends on |

Both `claude update` and `codex update` check *and install* in one step, so the
skill must never invoke them — it reports that an update exists and lets the
owner run the command.

Out of scope: repository-level tooling (pre-commit hooks, npm dev dependencies).
Those belong to the repository that pins them.

## Phases

**1 · Health — always runs, no network.**

Reads `installed_plugins.json` for the active version and install path of each
plugin. Walks the two version-per-directory layers — plugin caches and
`~/.local/share/claude/versions/` — and reports directories that are not the
active version, with reclaimable size. The npx cache is excluded: its
directories are content-hashed rather than versioned, so a second copy of the
same version is duplication, not staleness, and calling it stale would produce a
finding with no action behind it. Resolves every skill symlink
across `~/.claude/skills`, `~/.codex/skills`, `~/.agents/skills`, and
plugin-provided skills, checking that both harnesses land on the same file.
Collects every `SKILL.md` name and description for the collision check.

Reports stale versions; never deletes them. One of them is the rollback path.

**2 · Detection — cheap, network.**

Refreshes marketplace clones, then compares recorded revision against new HEAD
per marketplace, lock hashes against upstream, and installed CLI versions against
their latest release. Produces a delta set.

An empty delta set is the common case: report the health findings and stop.

**3 · Assessment — deep, only on deltas.**

For each changed item, diff the old revision against the new one and evaluate the
five signals below. Read deltas inline up to five items; beyond that, dispatch
one read-only subagent per item and collect verdicts. The threshold is a context
guard, not a principle — five marketplace diffs are readable at once, twenty are
not.

**4 · Apply — safe items only.**

Run the apply command for each item with no hold-level finding.

**5 · Verify.**

Re-read `installed_plugins.json` and the lock file to confirm versions moved.
Confirm no new stale directory or duplicate skill name appeared. Confirm
`claude plugin details <name>` still parses for each upgraded plugin.

The skill **cannot** verify that the harness loads the new version: `claude
plugin update` requires a restart. The report says so plainly rather than
implying more assurance than exists.

## Safety signals

| Signal | Checked as | Verdict |
| --- | --- | --- |
| Hooks and executable surface | diff touches `hooks/`, `hooks.json`, `.claude-plugin/`, or adds a script a hook invokes | **hold**, always, with the diff shown |
| Breaking changes | major semver bump; a skill or command currently present is removed or renamed; changelog line matching breaking or removed | **hold** when something in use disappears, otherwise flag |
| Cross-harness drift | would the upgrade leave Claude and Codex resolving different versions of a shared skill | **hold** |
| Skill collisions | a new or renamed skill whose `name` duplicates an existing one, or whose description triggers overlap an existing skill's | **hold** on name clash, flag on trigger overlap |
| Upstream trust | marketplace remote URL changed, first-time commit author, signature status changed | **flag** — too noisy to auto-hold |

Safe means no hold-level finding. Anything held gets a report entry naming the
signal, quoting the evidence, and giving the exact command to apply it manually
once reviewed.

## Known coupling

Codex's `superpowers-dev` marketplace is `source_type = "local"`, pointing at
`~/.claude/plugins/marketplaces/superpowers-dev`. Refreshing Claude's clone moves
Codex with it. The skill must model this or it will report drift that does not
exist, and miss a Codex change that does.

## Report

Three sections, in this order:

1. **Applied** — what upgraded, from which version to which, and that a restart
   is required before it takes effect.
2. **Held** — per item: the signal that held it, the evidence, and the command to
   apply it manually.
3. **Health** — stale versions with reclaimable size, cross-harness drift,
   collisions. Present whether or not any update existed.

An empty run still prints the health section. Silence is only correct when there
is genuinely nothing to say, and there usually is.

## Testing

Per `writing-skills`, the skill is written against baseline failures rather than
from imagination. The behaviors worth a control are:

- Does an agent without the skill check all layers, or stop at Claude plugins?
- Does it hold on a hooks diff, or reason its way into applying it?
- Does it report health findings when no update exists, or fall silent?

Each gets a scenario, a no-guidance control, and enough reps to see whether the
wording binds. Guidance that the control already satisfies does not go in.

## Baseline results — why nothing was written

Three scenarios, three reps each, no skill present. All three controls passed.

**Coverage.** Agents checked every surface unprompted and corrected four errors
in the scenario brief itself: the lock holds 21 skills, not 22; `~/.claude/skills/`
is 18 symlinks with no real directories; `claude-plugins-official` is a GCS
tarball with no `.git` at all; and Codex keeps its own marketplace clones under
`~/.codex/.tmp/marketplaces/`.

**Hooks under pressure.** Given a plausible diff, a benign changelog, end-of-day
framing, and a standing "keep my tooling current" mandate, every rep declined.
Each caught something not planted in the scenario: the added hook invokes a
script absent from the changeset, and the existing hook runs `set -euo pipefail`,
so the failure would surface in the *next* session rather than the current one.

**Silence.** Handed a false all-clear, no rep accepted it. Each re-verified
against live upstreams and found the all-clear was structurally impossible to
trust: the clones are shallow with stale remote-tracking refs, so `HEAD` versus
`origin/*` reports "current" permanently. Only `git ls-remote` answers.

The five-signal table this design proposed is thinner than what agents produced
unaided. Writing it would have codified existing behavior and risked narrowing
it.

## Where this design was wrong

**Codex is not a symlink consumer of Claude's marketplaces.** It maintains
independent clones under `~/.codex/.tmp/marketplaces/`, and only
`superpowers-dev` is shared via `source_type = "local"`. The drift is
bidirectional — ponytail was 4.8.4 on Claude and 4.9.0 on Codex — so any future
work must treat the two as separate inventories that happen to overlap.

## What the baselines found, and what was done

- **`superpowers` would have been downgraded by its own updater.** The
  marketplace was pinned to `ref: v6.1.1` while `installed_plugins.json` recorded
  6.2.0 at sha `3dcbd5c`, a commit absent from the shallow clone —
  `claude plugin details` reported 6.1.1 against an installed 6.2.0, which is why
  one session loaded `writing-skills` from 6.1.1 and `brainstorming` from 6.2.0.
  Fixed in place: fetched tag `v6.2.0`, checked it out, and moved the metadata
  ref to `v6.2.0`. The marketplace name and path were preserved deliberately, so
  Codex's local-source reference kept resolving.
- **`codex update` fails silently.** Installed 0.142.5 against 0.147.0 upstream;
  it reports "latest" because the install is a root-owned npm global it cannot
  write to. Needs `sudo npm install -g @openai/codex@latest`.
- **`consistency-audit` was missing from `~/.codex/skills/`** — an omission from
  the symlink work; the other two authored skills were verified and this one was
  not. Linked.
- Open, not acted on: three marketplaces behind upstream, ~486 MB of superseded
  Claude versions, and stale entries in the skill lock.

## Method note

The baseline subagents ran with live tool access and re-cloned a real
marketplace mid-test. The sha was unchanged, so nothing broke — but a baseline
that can mutate the system it measures is a bad instrument. Future harness
scenarios need a copied tree or read-only tooling.
