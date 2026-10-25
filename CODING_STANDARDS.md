# Coding standards

The rules a review applies that no check holds. They sit on the last rung of `AGENTS.md`'s design discipline, and each says which higher rung was tried and why it is unavailable.

Decision, 2026-10-25: this file reverses Q20 of the standalone-and-references spec, which kept the suite rule in that spec alone, and the rule lives here too, because that spec has been a historical artifact since plan B's branch merged into main at 2ac3bbe.

## Red first

Every new or changed check is seen failing on a named mutation, with the FAIL line it states, and the mutation is then reverted; the commit body records both. Rung: no check can verify that a red-first happened.

## Sentences true in their commit

A diff makes every comment and sentence it writes or leaves behind true at that commit, and count-free where a count would go stale (#37). Rung: the reference check on documents holds paths, not meaning.

## No silent exit under `set -euo pipefail`

Three shapes end a script, or let it run on, with no line saying why:

- a `grep` in a captured pipeline: its no-match exit 1 fails the capture, and `set -e` ends the script. Add `|| true` only where an empty result is legitimate.
- a `fail` inside `$(...)`: it ends only that subshell, and where `set -e` is suspended (a function called under `||`, `&&` or `if`) the script runs on. The caller adds `|| exit 1`.
- a command captured with no status check: its failure ends the script with no FAIL line. Capture with `x="$(cmd)" || fail "<what failed>"`.

Rung: shellcheck's default checks have no rule for these. It does hold the related `local x="$(cmd)"`, whose `local` masks the status (SC2155, which `tests/test-lint-shell.sh` enforces), so that case is not a rule here. Its optional `check-set-e-suppressed` (SC2310) was tried: it flags every function called under `||`, the `|| exit 1` this rule prescribes included, so it stays off. A test cannot enumerate the shapes.

## The suite rule

A test holds one of two things: that nothing drifts from a third-party upstream, and that the plugins install. Beside those stand the linters (lint, format, spelling, vocabulary, the reference check on documents, the workflow lint), the skill-reference scan, the watch's tests and the runner's tests. Nothing holds this repository's own wording, literals, counts or headers: such a check keeps content alive only because the check exists, and every deliberate change then needs a second edit to satisfy it. Rung: a check that enforced this rule would itself hold the repository's own content, which the rule bars.
