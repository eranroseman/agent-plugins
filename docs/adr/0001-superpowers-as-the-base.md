# obra/superpowers is the base; mattpocock/skills supplements it

This marketplace curates `obra/superpowers` whole, as a `git-subdir` entry pinned
by sha, and takes `mattpocock/skills` through `npx skills add` at a pinned tag.
The asymmetry is deliberate: superpowers supplies the execution machine — a
controller that never implements, a reviewer told not to trust the report, round
caps, escalation and ledger discipline — and nothing in mattpocock's catalogue
corresponds to `receiving-code-review`, `verification-before-completion` or
`finishing-a-development-branch`. Mattpocock supplies per-task machinery and
craft skills the spine lacks, which is a supplement rather than a substrate.

## Considered options

**mattpocock as the base, with superpowers skills vendored into it.** Rejected,
and recorded because it will look attractive again — it did to the second of the
three analysis passes behind this decision, before full-text reading unwound it.
SDD consumes `writing-plans`' plan-file format, so vendoring SDD without
`writing-plans` means adapting its substrate: workable, but a fork maintained
forever, forfeiting upstream convergence.

Evidence: [2026-08-25 coding-companion plugins comparison](../archive/2026-08-25-coding-companion-plugins-comparison.md).
