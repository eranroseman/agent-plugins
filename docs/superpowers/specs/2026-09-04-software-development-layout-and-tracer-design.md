# software-development: repository layout, manifests, and tracer bullet

**Status:** approved design, 2026-09-04. Sub-project 1 of 7 (see §11).
**Scope:** the public repository `eranroseman/software-development` as a marketplace hosting two plugins, the curated upstream `superpowers` entry, the Codex route, and the tracer bullet that proves the layout on both harnesses.
**Not in scope:** setup automation, hook payload redesign, drift monitoring, roster decisions, harness-backup retirement, research-vault integration. Each is its own sub-project (§11).

## 1. Evidence standard

Map [knowledge-harness#53](https://github.com/eranroseman/knowledge-harness/issues/53) and its tickets were read in full as input. Nothing on that map binds this design. A claim below counts as a fact only when it rests on a primary source read on 2026-09-04: a live documentation page, a CLI `--help`, a file on this machine, a repository tree fetched from GitHub, or a session log. §12 lists each mechanism claim with its source. Two claims could not be settled statically; they are tracer gates (§10.2), not facts.

Five map positions were reversed by the author during this design. §11.2 records each with the primary source it rests on. This session posted nothing to the knowledge-harness tracker; relaying the reversals to the map is the author's call.

## 2. Goal

Ship one public repository that installs, on Claude Code and Codex, a curated software-development harness:

- `software-development`: the glue plugin. Ships the narrowed `brainstorming` skill and a SessionStart hook. Depends on `sensemaking` and the curated `superpowers`.
- `sensemaking`: the shared plugin, installed by both `software-development` and, later, `research-vault`. Starts with `rethink-audit`.
- `superpowers`: obra's upstream, taken as-is by a curated marketplace entry that drops `brainstorming`. No fork.
- `mattpocock/skills`: upstream, taken as a declared subset through the skills.sh installer. Unchanged mechanism.

`software-development` is a glue layer over two upstream packs, not a home for copies of them.

## 3. Decisions

| Decision | Choice |
| --- | --- |
| Repository count | One: this repo hosts the marketplace and both plugins. `research-vault` stays in its own repo and is listed here by git URL once public. |
| Marketplace name | `eranroseman` (`eroseman` belongs to an unrelated GitHub account). |
| superpowers | Curated marketplace entry named `superpowers`, `git-subdir` at `path: skills`, `strict: false`, pinned by `sha`, listing 13 of 14 skill directories. `brainstorming` is the one dropped. |
| brainstorming | Vendored into `software-development` from upstream HEAD, **name kept**, only the description changed. Visual Companion kept. |
| using-superpowers | Kept in the curated entry (Codex needs `references/codex-tools.md`). Its line 30 still names `superpowers:brainstorming`; our hook payload repoints it. |
| SessionStart hook | `software-development` ships its own. Upstream's hook is not loaded (it sits outside the `skills` subdir). |
| Codex superpowers route | Symlinks from a clone pinned to the same sha, into `~/.codex/skills/`. Not a Codex plugin install. |
| mattpocock | skills.sh lockfile subset, declared in this repo (format decided in sub-project 2). `grilling` stays model-invocable; its `skillOverrides` mute is removed in the same motion the narrowed `brainstorming` lands. |
| sensemaking contents at tracer | `rethink-audit`, copied as-is from `harness-backup`. Adaptation is sub-project 5. |

## 4. Repository layout

```text
eranroseman/software-development
├── .claude-plugin/marketplace.json        Claude marketplace (§5.1)
├── .agents/plugins/marketplace.json       Codex marketplace (§5.2)
├── plugins/
│   ├── software-development/
│   │   ├── .claude-plugin/plugin.json     (§6.1)
│   │   ├── .codex-plugin/plugin.json      (§6.2)
│   │   ├── skills/brainstorming/          vendored, see §7
│   │   ├── hooks/hooks.json               (§8)
│   │   ├── hooks/session-start            (§8)
│   │   ├── LICENSE                        MIT, carries obra's notice for the vendored skill
│   │   └── README.md
│   └── sensemaking/
│       ├── .claude-plugin/plugin.json     (§6.3)
│       ├── .codex-plugin/plugin.json
│       ├── skills/rethink-audit/          SKILL.md + agents/openai.yaml, as-is
│       ├── LICENSE
│       └── README.md
├── docs/                                  existing agent docs and this spec
├── AGENTS.md, CLAUDE.md, CONTEXT.md       existing
└── .github/workflows/validate.yml         static checks (§10)
```

Component directories sit at each plugin root, never inside `.claude-plugin/`.

## 5. Marketplace manifests

### 5.1 `.claude-plugin/marketplace.json`

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "eranroseman",
  "owner": { "name": "Eran Roseman", "url": "https://github.com/eranroseman" },
  "description": "Eran Roseman's plugins: a curated software-development harness and the shared sensemaking skills.",
  "plugins": [
    {
      "name": "software-development",
      "source": "./plugins/software-development",
      "description": "Glue over superpowers and mattpocock/skills: narrowed brainstorming, session-start bridge rules.",
      "category": "development"
    },
    {
      "name": "sensemaking",
      "source": "./plugins/sensemaking",
      "description": "Skills shared by software-development and research-vault.",
      "category": "productivity"
    },
    {
      "name": "superpowers",
      "description": "obra/superpowers, curated: the process spine without brainstorming.",
      "category": "development",
      "source": {
        "source": "git-subdir",
        "url": "https://github.com/obra/superpowers.git",
        "path": "skills",
        "ref": "main",
        "sha": "b36e0829c6d0140e93cfef2ca599b1b07d4a7797"
      },
      "version": "6.3.0",
      "strict": false,
      "skills": [
        "./dispatching-parallel-agents",
        "./executing-plans",
        "./finishing-a-development-branch",
        "./receiving-code-review",
        "./requesting-code-review",
        "./subagent-driven-development",
        "./systematic-debugging",
        "./test-driven-development",
        "./using-git-worktrees",
        "./using-superpowers",
        "./verification-before-completion",
        "./writing-plans",
        "./writing-skills"
      ]
    }
  ]
}
```

Why this shape:

- `git-subdir` at `path: skills` makes the plugin root the `skills/` directory. That root contains no `skills/` subdirectory, so the default scan finds nothing and the listed paths are the complete set. Upstream's `hooks/hooks.json` and `.claude-plugin/plugin.json` sit outside the root, so no upstream hook loads and no manifest conflicts with `strict: false`.
- This is the exact shape of `amd-skills` in `anthropics/claude-plugins-official`: `git-subdir`, `path: skills`, `strict: false`, 4 of 8 upstream skill directories listed. Exclusion by a first-party marketplace is precedent, not a guess.
- The entry name `superpowers` keeps the `superpowers:` namespace. Every one of the 26 qualified cross-references in the 13 skills resolves unchanged. Cross-directory references inside those skills are sibling-relative (`../requesting-code-review/code-reviewer.md`), so they resolve under a `skills`-rooted plugin. No skill uses `${CLAUDE_PLUGIN_ROOT}`.
- `sha` is the pin; `ref` is documentation. `version` is set so that users receive an update only when the string changes. Bumping both together is a deliberate update.
- `dependencies` declared by `software-development` resolve inside this marketplace, so no `allowCrossMarketplaceDependenciesOn` is needed.

### 5.2 `.agents/plugins/marketplace.json`

```json
{
  "name": "eranroseman",
  "interface": { "displayName": "Eran Roseman" },
  "plugins": [
    {
      "name": "software-development",
      "source": { "source": "local", "path": "./plugins/software-development" },
      "policy": { "installation": "AVAILABLE", "authentication": "ON_INSTALL" },
      "category": "Developer Tools"
    },
    {
      "name": "sensemaking",
      "source": { "source": "local", "path": "./plugins/sensemaking" },
      "policy": { "installation": "AVAILABLE", "authentication": "ON_INSTALL" },
      "category": "Productivity"
    }
  ]
}
```

Codex has no dependency concept and cannot subset a plugin's `skills/` directory, so `superpowers` has no Codex entry. It arrives by symlink (§9.2).

## 6. Plugin manifests

### 6.1 `plugins/software-development/.claude-plugin/plugin.json`

```json
{
  "name": "software-development",
  "version": "0.1.0",
  "description": "Glue over superpowers and mattpocock/skills for Claude Code and Codex.",
  "author": { "name": "Eran Roseman", "url": "https://github.com/eranroseman" },
  "homepage": "https://github.com/eranroseman/software-development",
  "repository": "https://github.com/eranroseman/software-development",
  "license": "MIT",
  "keywords": ["software-development", "superpowers", "skills", "workflow"],
  "dependencies": ["sensemaking", "superpowers"]
}
```

Installing `software-development@eranroseman` installs both dependencies at the same scope and enables them; disabling either while `software-development` is enabled fails with a chained-command hint; `claude plugin uninstall software-development --prune` removes them if nothing else needs them. Hooks load from the default path `hooks/hooks.json`.

### 6.2 `plugins/software-development/.codex-plugin/plugin.json`

```json
{
  "name": "software-development",
  "version": "0.1.0",
  "description": "Glue over superpowers and mattpocock/skills for Claude Code and Codex.",
  "author": { "name": "Eran Roseman", "url": "https://github.com/eranroseman" },
  "homepage": "https://github.com/eranroseman/software-development",
  "repository": "https://github.com/eranroseman/software-development",
  "license": "MIT",
  "keywords": ["software-development", "superpowers", "skills", "workflow"],
  "skills": "./skills/",
  "interface": {
    "displayName": "Software Development",
    "shortDescription": "Curated software-development harness",
    "longDescription": "Narrowed brainstorming front door plus session-start bridge rules over the superpowers spine and mattpocock's engineering skills.",
    "developerName": "Eran Roseman",
    "category": "Developer Tools",
    "capabilities": ["Instructions", "Lifecycle hooks"],
    "websiteURL": "https://github.com/eranroseman/software-development",
    "defaultPrompt": ["Let's build a feature.", "Design this change before we implement it."]
  }
}
```

`interface.displayName`, `shortDescription`, `longDescription`, `developerName`, `category` and `defaultPrompt` are required by Codex's own validator. The manifest declares no `hooks` key: the validator rejects the key when present, and Codex's loader falls back to `hooks/hooks.json` at the plugin root when it is absent (`codex-rs/core-plugins/src/loader.rs`, `load_plugin_hooks`, `DEFAULT_HOOKS_CONFIG_FILE`, at openai/codex `f3f6922`). An empty object `"hooks": {}` would suppress that fallback, which is what upstream superpowers does to keep its Claude hook off Codex. Whether the fallback loads our hook is gate G4 (§10.2).

### 6.3 `plugins/sensemaking/`

Claude manifest: `name` `sensemaking`, `version` `0.1.0`, MIT, no `dependencies`, no hooks. Codex manifest: same identity, `"skills": "./skills/"`, an `interface` block with the required fields (`displayName` "Sensemaking", category "Productivity"), no `hooks`.

`skills/rethink-audit/` is copied byte-for-byte from `~/harness-backup/claude/skills/rethink-audit/` (`SKILL.md` and `agents/openai.yaml`, which already carries `policy.allow_implicit_invocation: true`). Its `design:` and `prior-art:` rungs reference `codebase-design` and `research` as optional ("if available"); both keep arriving through the mattpocock subset, so nothing dangles.

## 7. The vendored `brainstorming` skill

Source: `obra/superpowers` at `b36e0829`, directory `skills/brainstorming/` (8 files, 2,030 lines: `SKILL.md` 250, `visual-companion.md` 299, `spec-document-reviewer-prompt.md` 49, `scripts/` 1,432). Copied whole into `plugins/software-development/skills/brainstorming/`.

Changes, and only these:

1. A provenance header at the top of `SKILL.md`, after the frontmatter, as an HTML comment: upstream URL, sha, path, "MIT, © 2025 Jesse Vincent", and "do not hand-edit below this line; re-vendor from upstream to update".
2. The `description` field. Upstream:

   > You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation.

   Ours:

   > Design front door of the superpowers spine. Classifies a build request as spike, bounded, or architectural, then takes it from intent to an approved design, and to a written spec for architectural work, before any implementation. Use for "let's build, add, or change X". Not for open-ended ideation, and not for stress-testing an existing plan.

3. Nothing else. `name: brainstorming` stays, so `/brainstorming` keeps working and every bare-name mention in the 13 upstream skills stays valid. The body, the HARD-GATE, the three-path router, the terminal handoff to `writing-plans`, and the Visual Companion are untouched.

The Visual Companion's server fetches a logo from an external site unless `SUPERPOWERS_DISABLE_TELEMETRY` or `DISABLE_TELEMETRY` is set. That variable is set by setup (sub-project 2); the README of this plugin names it.

`grilling` and `brainstorming` no longer compete on description. `grilling` fires on "grill", "stress-test", and plan critique; `brainstorming` fires on build requests. `adhd`, if adopted later, is checked against this description (sub-project 5).

## 8. The SessionStart hook

`hooks/hooks.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/session-start\"",
            "shell": "bash",
            "timeout": 5,
            "async": false
          }
        ]
      }
    ]
  }
}
```

`hooks/session-start` reads `hooks/payload.md`, JSON-escapes it, and prints `{"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "..."}}`. That envelope is what Claude Code documents and what Codex requires; one output serves both harnesses.

Payload for the tracer bullet: the text of upstream `skills/using-superpowers/SKILL.md` at `b36e0829`, wrapped in the same `<EXTREMELY_IMPORTANT>` frame upstream uses, with exactly one edit: line 30, `superpowers:brainstorming` becomes `software-development:brainstorming`. Line 22 ("invoke the brainstorming skill first") is a bare-name mention and stays. `<SUBAGENT-STOP>` stays. The lean-router redesign, the admission test, and the bridge rules are sub-project 3; this payload exists so that the tracer measures a like-for-like replacement of upstream's injection.

Claude Code concatenates every matching SessionStart hook's `additionalContext` and runs matching hooks in parallel, so five other plugins' hooks keep composing with this one. Upstream superpowers' hook does not load (§5.1), so there is no duplicate injection.

## 9. Codex

### 9.1 Our plugins

```bash
codex plugin marketplace add https://github.com/eranroseman/software-development.git
codex plugin add software-development@eranroseman
codex plugin add sensemaking@eranroseman
```

Both `add` commands are explicit because Codex has no dependency field. Codex prompts once to trust the hook definition.

### 9.2 superpowers by symlink

```bash
git clone https://github.com/obra/superpowers.git ~/.local/share/software-development/upstream/superpowers
git -C ~/.local/share/software-development/upstream/superpowers checkout b36e0829c6d0140e93cfef2ca599b1b07d4a7797
for s in dispatching-parallel-agents executing-plans finishing-a-development-branch receiving-code-review requesting-code-review subagent-driven-development systematic-debugging test-driven-development using-git-worktrees using-superpowers verification-before-completion writing-plans writing-skills; do
  ln -s ~/.local/share/software-development/upstream/superpowers/skills/$s ~/.codex/skills/$s
done
```

Codex follows symlinked skill folders. `~/.agents/skills/` is not used because the skills.sh installer owns it. The 13-name list has one source of truth: the marketplace entry in §5.1. Sub-project 2 decides whether setup reads it from there or from a lockfile beside it; the tracer links by hand.

Gate G2 exists because Codex prefixes plugin skills with the plugin name (its catalog on this machine shows `superpowers:writing-plans`) while a skills-directory skill appears bare (`writing-plans`). The 26 qualified references in skill bodies then name catalog entries that do not exist on Codex. If Codex does not resolve them, the fallback is a plugin install: `codex plugin marketplace add https://github.com/obra/superpowers.git --ref v6.3.0` then `codex plugin add superpowers@superpowers`, which brings all 14 skills, `brainstorming` beside ours, and the symlinks are removed.

### 9.3 mattpocock

Unchanged mechanism: `npx skills add -g mattpocock/skills --skill <name,...> -y`, installing into `~/.agents/skills/` with the existing symlinks from `~/.claude/skills/` and `~/.codex/skills/`. Today's 18 stay. `diagnosing-bugs` joins if sub-project 5 approves it; the only Claude lever for its trigger race with `systematic-debugging` is `skillOverrides: user-invocable-only`, and Codex has none short of editing the installed copy's `openai.yaml`. Neither `mattpocock/skills` nor its skills ship a Codex plugin manifest, so the plugin route is Claude-only and is not taken.

## 10. Cutover and tracer bullet

### 10.1 Cutover, on this machine, in one sitting

Claude Code:

1. `claude plugin uninstall superpowers@superpowers-dev` at user scope.
2. From `/home/eranr/memoria-vault`, `claude plugin uninstall superpowers@superpowers-dev --scope project`. That project-scope entry (same `installPath`, different sha `3dcbd5c4`) is a second install and survives step 1.
3. `claude plugin marketplace add eranroseman/software-development`.
4. `claude plugin install software-development@eranroseman`. This pulls `sensemaking` and the curated `superpowers`.
5. Delete `skillOverrides.grilling` from `~/.claude/settings.json`, then refresh the `harness-backup` copy.
6. Leave the `superpowers-dev` marketplace registered until every gate passes; remove it afterwards.

Codex:

1. `codex plugin remove superpowers@superpowers-dev`; delete `[marketplaces.superpowers-dev]` (`source_type = "local"`) from `~/.codex/config.toml`.
2. §9.1, then §9.2.

Rollback reverses the order. Upstream pins are unchanged, so reinstalling the previous state is exact.

### 10.2 Gates

Every gate is checked on the live machine after cutover. Each has a recorded fallback.

| Gate | Passes when | Fallback if it fails |
| --- | --- | --- |
| G1 Claude catalog | `superpowers:brainstorming` is absent; the 13 `superpowers:*` skills, `software-development:brainstorming`, and `sensemaking:rethink-audit` are present (`claude plugin details`, then a session's skill list) | Fork `obra/superpowers` with `brainstorming` deleted and depend on the fork (the map's approach) |
| G2 Codex names | `$writing-plans` invokes from the symlink; an SDD-shaped prompt on Codex follows the `superpowers:test-driven-development` mention rather than stalling on it | Codex plugin install of upstream (§9.2) |
| G3 Claude hook | Our payload appears once at startup, `/clear`, and `/compact`; no upstream injection | Investigate; there is no design alternative, only a defect |
| G4 Codex hook | Codex either loads `hooks/hooks.json` by manifest fallback after the trust prompt (a `software-development@eranroseman:hooks/hooks.json:session_start:0:0` entry appears under `[hooks.state]` in `~/.codex/config.toml` and the payload appears once in a session) or does not; either outcome is recorded and sub-project 3 designs against it | None needed; the outcome is an input |
| G5 Front door | `/brainstorming` resolves on Claude to ours; its terminal step reaches `superpowers:writing-plans` | Defect, fix in place |

Fresh-machine reproducibility is not a gate here. It belongs to sub-project 2.

### 10.3 Static checks, in CI from the first commit

- `claude plugin validate --strict` on `.claude-plugin/marketplace.json` and both plugin manifests. This checks schema, not scan behaviour; it does not substitute for G1.
- `python3 ~/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py plugins/<name>` on both plugins; both pass. CI fetches the same script from openai/codex at a pinned sha.
- JSON well-formedness for all four manifests.
- A shallow clone of `obra/superpowers` at the pinned sha, asserting that every directory listed in §5.1 exists and that `brainstorming` is not listed.

### 10.4 Pins, recorded for sub-project 4

| Surface | Pin | Drift signal |
| --- | --- | --- |
| Curated superpowers | `sha` and `version` in §5.1 | upstream HEAD moves past the sha (release-driven bump) |
| Vendored brainstorming | sha in the provenance header | upstream `skills/brainstorming/` differs from the header's sha |
| Codex clone | HEAD of the clone | HEAD differs from the §5.1 sha, or a symlink target is missing |
| mattpocock subset | `skillFolderHash` in `~/.agents/.skill-lock.json` (the installer records no ref) | hash differs from upstream |

## 11. Decomposition plan

### 11.1 Sub-projects

| # | Sub-project | Depends on | Inherits from the map |
| --- | --- | --- | --- |
| 1 | Layout, manifests, tracer bullet (this spec) | — | #59, #89, #69 inputs |
| 2 | Setup and materialisation: own setup skill (not `setup-matt-pocock-skills` unless it turns out identical), cutover automation, the mattpocock subset manifest, the pinned clone and Codex symlinks, environment variables, the five `harness-backup` files as templates | 1 | #62, including the five live-tree findings |
| 3 | SessionStart hook payload: the lean router, admission test, bridge rules, Iron Laws; Codex hook posture from G4 | 1 | #61 |
| 4 | Drift: CI upstream watch (§10.4) and the local doctor (symlink targets, clone sha, unreferenced cache, unwired components) | 2 | #63, #78, #95 |
| 5 | Roster: `consistency-audit` and its inspector agent, `finding-duplicate-functions`, `working-with-claude-code`, `developing-claude-code-plugins`, `diagnosing-bugs` gating, `grilling` on Codex, `adhd` and `archify` carry, `rethink-audit` adaptation, the requirements and sourcing skills, prior-art search, the out-of-scope-bug mechanism | 1 | #60, #79, #80, #81, #82, #84, #86, #88, #110, #111 |
| 6 | `harness-backup` retirement | 2, 4 | #64, #51 |
| 7 | research-vault integration: list `research-vault@eranroseman` once that repo is public; `research-vault` declares `dependencies: ["sensemaking"]` or its own marketplace adds `allowCrossMarketplaceDependenciesOn: ["eranroseman"]` | 1, and research-vault's own release gate | #97 stays research-vault's |

Order: 1, then 2 and 3 in parallel, then 4, then 5, then 6. Sub-project 7 runs whenever research-vault goes public. Gate results from 1 feed 2, 3 and 4.

### 11.2 Map positions reversed on 2026-09-04

| Map position | Now | Primary source |
| --- | --- | --- |
| Fork `obra/superpowers` publicly (#75) | Curated upstream entry, no fork | `amd-skills` entry in `anthropics/claude-plugins-official`: `git-subdir`, `strict: false`, 4 of 8 upstream directories listed; Claude docs on `strict` and marketplace `skills`; Codex `.codex-plugin` `skills` supplements rather than replaces (plugin-creator reference), so Codex gets symlinks |
| Three distributables in one marketplace (#89, #75) | Two plugins plus upstream dependencies | Claude docs: `dependencies` resolve inside the declaring marketplace |
| Vendor mattpocock skills into the products (#75) | skills.sh declared subset, upstream-owned | `skills` CLI `add --skill`; `~/.agents/.skill-lock.json` shows 18 of 25 installed that way today |
| Mute `grilling`, rename `brainstorming` to `writing-specs` (#72, #60) | `grilling` as-is; `brainstorming` keeps its name, description narrowed | one qualified `superpowers:brainstorming` in the whole upstream tree; bare-name mentions in `writing-plans`, SDD, `using-superpowers` |
| Marketplace `eroseman` (#75) | `eranroseman` | `gh api users/eroseman` returns an unrelated account |

Not reversed: `sensemaking` exists and is shared by both products; the map's measurements about `skillOverrides` (no effect on plugin skills at Claude Code 2.1.220) and about the 26 qualified cross-references stand and are what this design routes around.

## 12. Mechanism claims and their sources

| Claim | Source, read 2026-09-04 |
| --- | --- |
| Marketplace entries accept `strict`, `skills`, `hooks`; `strict: false` makes the entry the entire definition; listed `skills` add to the default `skills/` scan; with a marketplace-root source the listed paths are the complete set | code.claude.com/docs/en/plugin-marketplaces |
| `git-subdir` source with `path`, `ref`, `sha`; `sha` takes precedence; `version` gates updates | same page |
| `dependencies` in plugin.json: auto-install at the same scope, transitive enable, disable guard, `uninstall --prune` | code.claude.com/docs/en/plugins-reference |
| `allowCrossMarketplaceDependenciesOn` exists on marketplace.json | code.claude.com/docs/en/plugin-marketplaces |
| SessionStart `additionalContext` values concatenate; matching hooks run in parallel | `working-with-claude-code/references/hooks.md` lines 520 and 776 |
| Plugin skills are namespaced `plugin-name:skill-name` | code.claude.com/docs/en/plugins-reference |
| `skillOverrides` never reaches plugin skills at 2.1.220 | resolver function quoted in knowledge-harness #60 from a read of the installed binary (not re-read this session); `claude --version` is 2.1.220 today; live docs state plugin skills are managed through `/plugin` |
| First-party subset precedent | `~/.claude/plugins/marketplaces/claude-plugins-official/.claude-plugin/marketplace.json`, entry `amd-skills`; `gh api repos/amd/skills/contents/skills` lists 8 directories |
| Upstream superpowers state | `gh api repos/obra/superpowers`: HEAD `b36e0829`, v6.3.0, 14 skill dirs; `.claude-plugin/plugin.json` declares no components; `.codex-plugin/plugin.json` has `"skills": "./skills/"`, `"hooks": {}` |
| Cross-reference counts | `grep -rho "superpowers:[a-z-]*" skills` on a clone at HEAD: 26 hits; exactly one names `brainstorming` (`using-superpowers/SKILL.md:30`) |
| Codex reads `$HOME/.agents/skills` and follows symlinked skill folders; skills are `$name`; description budget 2% of context or 8,000 chars | learn.chatgpt.com/docs/build-skills |
| Codex prefixes plugin skills | `~/.codex/sessions/2026/09/01/rollout-…jsonl`: catalog shows `superpowers:writing-plans:` and bare `rethink-audit:` |
| Codex plugin CLI has `add`, `list`, `marketplace`, `remove`; no dependency concept; `marketplace add` accepts a path, `owner/repo[@ref]`, or a git URL, with `--ref` | `codex plugin --help`, `codex plugin marketplace add --help`, codex-cli 0.147.0 |
| Codex manifest allowed keys and required `interface` fields; `hooks` rejected by the validator; `skills`/`hooks` supplement defaults | `~/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py`; `references/plugin-json-spec.md` |
| A Codex plugin with a `hooks` manifest field loads hooks after trust | `~/.codex/plugins/cache/ponytail/ponytail/4.9.0/.codex-plugin/plugin.json`; `[hooks.state]` in `~/.codex/config.toml` holds three ponytail entries |
| Codex marketplace entry shape (`local` path, `policy`, `category`, root `interface.displayName`) | plugin-creator `SKILL.md`; `eranroseman/rethink` capture in knowledge-harness #73 |
| skills.sh installs a subset with `--skill`; lockfile records `skillFolderHash` and no ref | `npx skills add --help` (1.5.x); `~/.agents/.skill-lock.json` |
| mattpocock ships a Claude plugin (25 skills) and no Codex manifest; 11 of 25 are model-invocable | `gh api repos/mattpocock/skills/contents/.claude-plugin/plugin.json`; per-skill frontmatter and `agents/openai.yaml` at HEAD `6654f6b6` |
| `eroseman` is taken; `eranroseman/{sensemaking,superpowers,research-vault}` do not exist; `knowledge-harness` is private | `gh api users/eroseman`; `gh repo view` |
| `sensemaking` collides with nothing across 373 marketplace entries | grep over `~/.claude/plugins/marketplaces/*/marketplace.json` |
| Codex loads `hooks/hooks.json` when the manifest has no `hooks` key; `{}` suppresses it; the hook-file parser accepts `timeout`, `async`, `statusMessage` and ignores `shell` | `codex-rs/core-plugins/src/loader.rs` line 1230 and `codex-rs/config/src/hook_config.rs` at openai/codex `f3f6922519fa38487c8250c2b8a670a39a2cf9ff`; upstream superpowers `tests/codex/test-marketplace-manifest.sh` |

## 13. Open items carried forward

- G1 and G2 are the two mechanism claims this design could not settle statically (§10.2).
- Whether Codex loads `hooks/hooks.json` by manifest fallback for our plugin (G4).
- The exact list format that setup reads for the 13 superpowers names and the mattpocock subset (sub-project 2).
- The hook payload beyond the tracer's like-for-like text (sub-project 3).
- `adhd`, `archify`, `diagnosing-bugs` gating, and every other roster question (sub-project 5).
