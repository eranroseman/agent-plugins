## Agent skills

### Git

Merge back to main locally and push main to origin in the same motion. Fetch before claiming something is absent from origin.

### Issue tracker

GitHub Issues (github.com/eranroseman/agent-plugins), via `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five canonical labels (needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context (root `CONTEXT.md` + `docs/adr/`). See `docs/agents/domain.md`.

### Design discipline

Eliminate the problem > add a mechanism > add a rule; prose is the last resort.

Climb from the top and stop at the first rung that holds. A rule nobody can enforce is the weakest thing you can ship, and it goes stale silently. When prose really is the last resort, **say which higher rungs you tried and why they were unavailable** — an unexplained rule is indistinguishable from a lazy one, and the next reader cannot tell whether to re-attempt the climb.

### Task reports

The SDD skill never commits its `.superpowers/sdd/` reports, and its Finish step
deletes the workspace — a report is not a durable home. Reports name a
destination per Concern at write time; a plan's workspace closes only after
every Concern's disposition has landed in that home — an issue, a spec entry, or
a recorded decline.

### Security scanning on Codex

Nothing scans passively on Codex: `codex-security`'s scan family
(`security-scan`, `security-diff-scan`, `deep-security-scan`,
`finding-discovery`) is explicit-invocation only. This repository ships an
installer and a hook payload, so run a scan yourself on a diff that touches
`bin/`, `hooks/`, or a workflow.
