---
name: finding-duplicate-functions
description: Find functions that serve the same purpose under different names. Use when auditing a Python codebase for semantic duplication, before a consolidation refactor, or when agent-written code is suspected of reimplementing helpers it could have imported.
---
<!-- Forked from https://github.com/obra/superpowers-lab at commit 51111f74f24058117752d9aa917cb19859f8ec86
     path: skills/finding-duplicate-functions/
     MIT, (c) 2025 Jesse Vincent. A rewritten fork, not a copy: scripts/categorize-prompt.md and
     scripts/find-duplicates-prompt.md are upstream's, byte for byte; everything else is authored here.
     PROVENANCE.md records what changed and why. Edit this skill here; there is nothing to re-vendor.
-->

# Finding Duplicate-Intent Functions

Agent-written codebases accumulate semantic duplicates: helpers implemented
again because importing the existing one was never considered. Copy-paste
detectors find syntactic duplicates. This finds *same intent, different name* —
and the expensive case underneath it, *same name, different contract*.

Fork of `finding-duplicate-functions` in
[obra/superpowers-lab](https://github.com/obra/superpowers-lab) (MIT). The
upstream extractor is TypeScript/JavaScript and returns zero functions against
Python; phase 1 is rewritten and a structural pre-filter added. The two prompt
templates in `scripts/` are upstream, unchanged.

## The Iron Law

**A cluster is a candidate, never a verdict.** Structural identity and model
agreement both produce plausible duplicates that are load-bearing on
inspection. Every group is refuted before it reaches the report, and a group
that survives carries the evidence that refuted the alternative.

Deleting a duplicate that was carrying a contract is the expensive direction of
this error. Prefer INVESTIGATE.

## Process

```
1. extract    scripts/extract-functions.py       -> catalog.json
2. cluster    scripts/cluster.py                 -> structural groups
3. categorize scripts/categorize-prompt.md       -> categorized.json   (large corpora only)
4. detect     scripts/find-duplicates-prompt.md  -> duplicate groups
5. refute     second reader per surviving group
6. report     grouped by confidence, with call-site evidence
```

### 1. Extract

```bash
python3 scripts/extract-functions.py src/ -o catalog.json --root "$PWD"
```

Walks `FunctionDef` / `AsyncFunctionDef`. Test files are excluded unless
`--include-tests`. Emits the upstream schema — `file`, `name`, `line`,
`exportType`, `context` — plus two fields the prompts ignore and `cluster.py`
needs: `body_lines` and `args`.

`exportType` maps Python convention onto the upstream vocabulary: class
children are `method`, a leading underscore is `internal`, everything else is
`named`.

### 2. Cluster (structural pre-filter)

```bash
python3 scripts/cluster.py catalog.json -o clusters.json
```

Normalizes each short function to an AST shape — identifier choices masked,
attribute and call names kept — and reports cross-file groups. Different-name
groups sort first.

This is free and it is precise. On a 1552-function corpus it cut the candidate
set to four before any model ran. It cannot see intent without shared structure,
so it never replaces step 4.

### 3. Categorize — only when the corpus is too large to read

Skip this for a single package: one package is already one category. For a
whole-repo run, use `scripts/categorize-prompt.md` with a cheap model, then
split by category and run step 4 per category with 3+ functions.

### 4. Detect

Use `scripts/find-duplicates-prompt.md`. Run it inline when one slice fits in
context — a subagent buys nothing and costs a round trip. Fan out per category
only when the corpus forced step 3.

The prompt grades HIGH / MEDIUM / LOW and recommends CONSOLIDATE, INVESTIGATE,
or KEEP_SEPARATE.

### 5. Refute

Every surviving group gets a second reader that tries to break it. The
questions that actually kill candidates:

- **Does the output cross a boundary?** Two helpers with identical bodies are
  free to diverge later unless something compares their results. Find the sink —
  a shared record field, a schema, a stored digest — and name it.
- **Is the difference load-bearing?** A slice, a truncation, a fallback string
  may be the reason the second copy exists. Read every call site before
  recommending a survivor.
- **Is it already recorded?** A comment at the site saying "byte-identical to X,
  which writes what this reads" is a ruling, not a defect. Report it as
  KEEP_SEPARATE and move on.

Trust order when layers disagree: schema, then tests, then code, then docs.

### 6. Report

Group by confidence, highest first. Each group carries: the intent, every
member as `file:line`, how the implementations differ, the recommendation, and
the evidence from step 5. State what you could not check — an unproven
cross-module comparison is the difference between CONSOLIDATE and INVESTIGATE.

Before acting on a CONSOLIDATE: confirm the survivor has tests covering the
callers of everything being deleted.

## Where duplicates cluster

Hashing and digest helpers, path relativization, slug and case normalization,
canonical JSON, error-to-string formatting, date formatting, validation
predicates, API response shaping.

Hashing is the richest seam and the most dangerous. The failure is rarely two
identical functions — it is six functions computing the same digest where one
omits a prefix, and both formats land in the same record field.

## Common mistakes

**Trusting the structural pre-filter as the answer.** It finds renamed copies.
The duplicates that matter often share no structure at all.

**Skipping refutation because the group looks obvious.** Obvious groups are
where the load-bearing exception hides.

**Consolidating on name similarity.** `_rel` and `relpath` may be duplicates;
`sanitize` and `escape` usually are not.

**Running the whole repo through step 4.** Categorize first, or scope to one
package. A flat corpus produces noise and burns tokens.
