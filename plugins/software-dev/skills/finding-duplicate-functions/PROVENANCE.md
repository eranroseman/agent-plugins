# Provenance

This skill is a fork, not an original. `SKILL.md` says so in its opening; this
file records what was checked, when, and against what — the detail a vendoring
decision needs and a one-paragraph attribution cannot carry.

Recorded 2026-08-29, resolving the provenance gap found by
[knowledge-harness#51](https://github.com/eranroseman/knowledge-harness/issues/51).

## Upstream

[`obra/superpowers-lab`](https://github.com/obra/superpowers-lab), path
`skills/finding-duplicate-functions`. MIT.

**Fork point: unknown.** It was not recorded when the fork was taken, and a
shallow clone cannot recover it. Upstream's tip when this file was written was
`51111f7` (`51111f74f24058117752d9aa917cb19859f8ec86`, 2026-06-01); every comparison below is against that commit, which is
where the fork stands *now*, not where it started.

## What changed

Upstream is implemented in bash and extracts from TypeScript/JavaScript sources:
`extract-functions.sh`, `generate-report.sh`, `prepare-category-analysis.sh`.

The fork exists because that extractor returns zero functions against Python.
Phase 1 was reimplemented in Python — `extract-functions.py` and `cluster.py`,
adding a structural pre-filter — and upstream's three shell scripts have no local
counterpart. `SKILL.md` was rewritten.

`SKILL.md`'s phrase "the upstream extractor is TypeScript/JavaScript" means the
language it *reads*, not the language it is *written in*. Both readings have
appeared in notes about this skill; the extractor is bash, and it parses TS/JS.

## What is carried unchanged

Two prompt templates, byte-identical to upstream at `51111f7` — verified by diff
on 2026-08-29:

- `scripts/categorize-prompt.md`
- `scripts/find-duplicates-prompt.md`

Re-run that diff before assuming they are still current; upstream moves and
nothing here watches it.

## Where it lives

In `software-dev`, since 2026-09-06: its subject is software and only that
product needs it (the placement rule in `plugins/sensemaking/README.md`).
It was custodied in `harness-backup` before that, under that repository's
rule of holding what no installer reproduces; that repository is retired.

`tests/test-vendored-duplicates.sh` holds the two carried templates
byte-identical to upstream at the commit above, so a drift there is a
failing test rather than a note nobody re-reads. Nothing watches upstream
for changes to the parts that were rewritten; that is the cost of a fork,
and it was taken because the upstream extractor returns nothing for Python.
