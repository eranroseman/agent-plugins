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

Eliminate the problem > add a mechanism > add a rule; prose is the last resort — and when you use it, name the rungs you ruled out and why.

### Task reports

Every Concern names a durable home when written — an issue, a spec entry, or a recorded decline — and the plan closes only when all of them have landed.

## Codex only

### Security scanning

Nothing scans automatically: `codex-security`'s scan family — `security-scan`,
`security-diff-scan`, `deep-security-scan`, `finding-discovery` — is
explicit-invocation only. Run `security-diff-scan` on any diff touching `bin/`,
`hooks/`, or a workflow.
