export const meta = {
  name: 'task-review',
  description: "Review one task's diff: lenses chosen by the paths it changes, each Critical or Important finding put to a refuter",
  whenToUse: "After an implementer reports a task done; docs/agents/plans.md names the args",
  phases: [
    { title: 'Review', detail: 'spec+quality; shell and docs-truth too when a high-risk path changed', model: 'opus' },
    { title: 'Refute', detail: "one refuter per lens for that lens's Critical and Important findings", model: 'opus' },
  ],
}

// args: { brief, rulings?, context?, report, base, head, worktree, workspace,
// changed: the paths `git diff --name-only base..head` prints, readme_blocks?:
// true when the diff touches a fenced `sh` block in the README }.
const A = args || {}
const need = ['brief', 'report', 'base', 'head', 'worktree', 'workspace'].filter(k => !A[k])
if (!Array.isArray(A.changed) || !A.changed.length) need.push('changed (a non-empty array of paths)')
if (need.length) throw new Error(`task-review: missing args: ${need.join(', ')}`)

// The lenses follow the paths, not the diff's size: a change to what CI, the
// install job or a user's install runs gets three, anything else one.
const RISKY = [/^tests\//, /^scripts\//, /^\.github\//, /^\.claude-plugin\//, /^plugins\/[^/]+\/\.(claude|codex)-plugin\//, /^vendored\.json$/]
const risky = A.changed.filter(p => RISKY.some(r => r.test(p)) || (p === 'README.md' && A.readme_blocks === true))
const head7 = A.head.slice(0, 7)
const reportPath = key => `${A.workspace}/review-${head7}-${key}.md`

const INPUTS = `Worktree: ${A.worktree}, read-only for you: never edit, stage, commit, check out, stash or reset there. For a working copy use \`git -C ${A.worktree} worktree add /tmp/<dir> ${A.head} --detach\` and remove it afterwards; scratch only under /tmp; never install into the real HOME; do not post to GitHub.
Requirements: the brief ${A.brief}${A.rulings ? `, amended by the controller's rulings ${A.rulings} (rulings win where they differ; they were made deliberately, so a diff that follows a ruling instead of the brief is compliant)` : ''}.${A.context ? ` Shared context, constraints and conventions: ${A.context}.` : ''}
Apply ${A.worktree}/CODING_STANDARDS.md, the rules no check holds.
Implementer's report, unverified claims; do not trust it: ${A.report}
Diff under review: \`git -C ${A.worktree} diff ${A.base}..${A.head}\`, its commits \`git -C ${A.worktree} log ${A.base}..${A.head}\`. Changed paths: ${A.changed.join(', ')}.
Severity: Critical = breaks something now (a build, an install, a check that can never fail); Important = cannot be trusted until fixed (wrong or fragile behavior, a missed requirement, a swallowed error, a test that asserts nothing, a false sentence); anything else is Minor. A stated rationale never downgrades a finding. Cite file:line for every finding; report only real defects, with evidence.`

const TRUTH = `Every sentence and comment the diff writes or leaves behind must be true at ${A.head}, and count-free where a count would go stale: check the ones it touches and the ones that name what it changes or deletes (grep the tracked tree at ${A.head} outside docs/superpowers for deleted or renamed names). A sentence the brief or a ruling mandates verbatim that is false is still a finding; say so in its why.`

const LENSES = [
  {
    key: 'spec+quality',
    prompt: `You are the task reviewer: first whether the diff matches its requirements (the brief and any rulings), then whether it is well built. A task-scoped gate, not a merge review.
Read the diff once. Inspect code outside it only to evaluate a concrete named risk (a deleted helper still called elsewhere is one: check the call sites). Do not re-run the suite; run a focused check only for a specific doubt.
Part 1, spec compliance: Missing (a requirement skipped, or claimed and not done; go through the brief step by step, and every ruling), Extra (unrequested), Misunderstood.
Part 2, quality: error handling, edge cases, checks that verify real behavior, structure.${risky.length ? '' : `\nPart 3, truth: ${TRUTH}`}`,
  },
  ...(risky.length
    ? [
        {
          key: 'shell',
          prompt: `You are a reviewer with ONE lens: correctness of the changed shell, tests, workflows and manifests. For each changed hunk of shell: does it behave under the script's own options (set -euo pipefail, errexit inside command substitutions and functions, pipefail with a grep that matches nothing, unset variables)? Does each new guard fail with its stated message on bad input and pass on good input (try it in a scratch copy under /tmp when cheap)? Did a deletion leave a caller, a sourced reference, a workflow step or a fixture dangling (grep the tree at ${A.head})? Does a workflow edit leave valid YAML and nothing naming a removed job or variable? Do manifest and vendored.json edits keep both agent CLIs' manifests in agreement? Not style.`,
        },
        { key: 'docs-truth', prompt: `You are a reviewer with ONE lens: truth. ${TRUTH} Compare each README and AGENTS.md claim the diff touches to the tree at ${A.head}.` },
      ]
    : []),
]
if (risky.length) log(`three lenses: ${risky.join(', ')} changed`)
else log('one lens: no high-risk path changed')

const FIND = {
  type: 'object',
  properties: {
    verdict: { type: 'string', description: 'approved | needs fixes' },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          severity: { type: 'string', enum: ['Critical', 'Important', 'Minor'] },
          where: { type: 'string', description: 'file:line' },
          what: { type: 'string' },
          why: { type: 'string' },
          fix: { type: 'string' },
        },
        required: ['severity', 'where', 'what', 'why'],
      },
    },
  },
  required: ['verdict', 'findings'],
}
const VERDICTS = {
  type: 'object',
  properties: {
    verdicts: {
      type: 'array',
      items: {
        type: 'object',
        properties: { id: { type: 'string' }, real: { type: 'boolean' }, reason: { type: 'string' } },
        required: ['id', 'real', 'reason'],
      },
    },
  },
  required: ['verdicts'],
}

// Each finding carries an id the refuter echoes, so a verdict is matched to
// its finding by id, never by position. A pipeline stage that throws drops its
// item, so each stage catches its own agent's failure, thrown or rejected: a
// reviewer's findings outlive a refuter that fails.
const id = (key, i) => `${key}-${i}`
const failure = e => (e && e.message) || String(e)
phase('Review')
const runs = await pipeline(
  LENSES,
  async l => {
    try {
      return {
        rev: await agent(`${l.prompt}\n${INPUTS}\nWrite your full report (verdict, every finding with its evidence, what you checked) to ${reportPath(l.key)}, the one file you may write; then return the compact result.`, {
          label: `review:${l.key}`,
          phase: 'Review',
          schema: FIND,
          model: 'opus',
        }),
      }
    } catch (e) {
      return { rev: null, error: failure(e) }
    }
  },
  async (run, l) => {
    if (!run.rev) return run
    const big = run.rev.findings.map((f, i) => ({ ...f, id: id(l.key, i) })).filter(f => f.severity !== 'Minor')
    if (!big.length) return { ...run, verdicts: [] }
    const list = big.map(f => `[${f.id}] ${f.severity} ${f.where}: ${f.what}\nWhy: ${f.why}\nFix: ${f.fix || ''}`).join('\n\n')
    try {
      const v = await agent(
        `${INPUTS}\n\nA reviewer reported the findings below against this diff. Try to REFUTE each: re-check the evidence yourself in the diff and the tree at ${A.head}, and against the brief and rulings (a diff that follows a ruling is compliant; a requirement met elsewhere in the diff is not missing). real=true only if it survives; default to real=false when the evidence does not reproduce. Return one verdict per finding, its id copied exactly.\n\n${list}`,
        { label: `refute:${l.key}`, phase: 'Refute', schema: VERDICTS, model: 'opus' },
      )
      return { ...run, verdicts: v ? v.verdicts : null }
    } catch (e) {
      return { ...run, verdicts: null, refuteError: failure(e) }
    }
  },
)

const lenses = []
const findings = []
const reports = []
LENSES.forEach((l, k) => {
  const run = runs[k] || { rev: null }
  if (!run.rev) {
    log(`${l.key}: ${run.error ? `the reviewer failed: ${run.error}` : 'the reviewer returned nothing'}; this lens did not run`)
    lenses.push({ lens: l.key, verdict: 'no result' })
    return
  }
  lenses.push({ lens: l.key, verdict: run.rev.verdict })
  reports.push(reportPath(l.key))
  const unrefuted = run.refuteError ? `the refuter failed: ${run.refuteError}` : 'the refuter returned nothing'
  if (run.verdicts === null) log(`${l.key}: ${unrefuted}; its Critical and Important findings carry real: null`)
  const byId = new Map((run.verdicts || []).map(v => [v.id, v]))
  run.rev.findings.forEach((f, i) => {
    const v = byId.get(id(l.key, i))
    const minor = f.severity === 'Minor'
    findings.push({
      lens: l.key,
      severity: f.severity,
      where: f.where,
      what: f.what,
      real: minor || !v ? null : v.real,
      refuter_reason: minor ? 'Minor: not sent to a refuter' : v ? v.reason : run.verdicts === null ? unrefuted : 'no verdict came back for this finding',
    })
  })
})
return { lenses, findings, reports }
