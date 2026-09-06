## Agent skills

### Git

Merge back to main locally and push main to origin in the same motion. Fetch before claiming something is absent from origin.

### Issue tracker

GitHub Issues (github.com/eranroseman/agent-plugins), via `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five canonical labels (needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context (root `CONTEXT.md` + `docs/adr/`). See `docs/agents/domain.md`.

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
