# Repository Layout, Manifests, and Tracer Bullet Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn this repository into the `eranroseman` marketplace hosting the `software-development` and `sensemaking` plugins plus a curated upstream `superpowers` entry, prove it with static checks in CI, then cut this machine over to it on Claude Code and Codex and record the five gates.

**Architecture:** Two local plugins under `plugins/`, one marketplace file per harness at the repo root, and a `git-subdir` marketplace entry that installs 13 of obra/superpowers' 14 skills straight from upstream at a pinned sha. `software-development` vendors upstream's `brainstorming` skill with a narrowed description and ships a SessionStart hook that injects upstream's `using-superpowers` text with one reference repointed. Every static claim is a bash test under `tests/`, run by `tests/run.sh` locally and in GitHub Actions.

**Tech Stack:** bash, jq, python3 (+ pyyaml for the Codex validator), Claude Code CLI 2.1.220 (`claude plugin validate`), codex-cli 0.147.0, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-04-software-development-layout-and-tracer-design.md`. Section numbers below (§5.1, §8, …) refer to it.

## Global Constraints

- Marketplace name is `eranroseman` on both harnesses. Owner display name "Eran Roseman", URL `https://github.com/eranroseman`.
- Upstream pin: `https://github.com/obra/superpowers.git`, sha `b36e0829c6d0140e93cfef2ca599b1b07d4a7797`, version `6.3.0`, ref `main`. No fork.
- The curated `superpowers` entry lists exactly these 13 skill directories and never `brainstorming`: `dispatching-parallel-agents`, `executing-plans`, `finishing-a-development-branch`, `receiving-code-review`, `requesting-code-review`, `subagent-driven-development`, `systematic-debugging`, `test-driven-development`, `using-git-worktrees`, `using-superpowers`, `verification-before-completion`, `writing-plans`, `writing-skills`.
- Both plugins are version `0.1.0`, license MIT, author `{ "name": "Eran Roseman", "url": "https://github.com/eranroseman" }`.
- Component directories (`skills/`, `hooks/`) sit at each plugin root, never inside `.claude-plugin/`.
- Vendored `brainstorming` keeps `name: brainstorming`. Only the `description` line and a provenance header change; every other byte, and every file mode, matches upstream at the pinned sha.
- `rethink-audit` is copied byte-for-byte from `~/harness-backup/claude/skills/rethink-audit/`. Task 2 Step 3 verifies the copy once, by md5, at copy time. No test repeats that check: the source is machine-local, and sub-project 5 rewrites the file.
- Hook output envelope is exactly `{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"…"}}`.
- Hook payload is upstream `skills/using-superpowers/SKILL.md` at the pinned sha, inside upstream's `<EXTREMELY_IMPORTANT>` frame, with exactly one edit: line 30, `superpowers:brainstorming` → `software-development:brainstorming`.
- `superpowers` has no Codex marketplace entry; on Codex it arrives by symlinks from a clone pinned to the same sha.
- Commit messages are plain prose and end with the executing agent's attribution trailer (`Co-Authored-By: <agent name> <noreply@anthropic.com>`). The commit commands below show the plan author's trailer; substitute your own.
- All work happens on branch `tracer-bullet` cut from `main`; Tasks 9 to 11 run only after that branch is merged and pushed.

## Deviation From Spec

Spec §6.2 puts `"hooks": "./hooks/hooks.json"` in the Codex manifest and §10.3 tells CI to tolerate the validator's rejection of that key. This plan **omits the `hooks` key** from `plugins/software-development/.codex-plugin/plugin.json`. Reason: `codex-rs/core-plugins/src/loader.rs` at openai/codex `f3f6922519fa38487c8250c2b8a670a39a2cf9ff`, function `load_plugin_hooks`, line 1230: when the manifest has no `hooks` field, Codex loads `hooks/hooks.json` from the plugin root (`DEFAULT_HOOKS_CONFIG_FILE`). Upstream superpowers' own `tests/codex/test-marketplace-manifest.sh` documents the same fallback. The Codex validator therefore passes cleanly and the hook still loads by fallback. Gate G4 measures that fallback. Task 4 amends spec §6.2, §10.2, §10.3 and §12 so spec and repository agree.

Also verified 2026-09-04 and relied on below: Codex's hook-file parser (`codex-rs/config/src/hook_config.rs`, same sha) accepts `command`, `timeout`, `async`, `statusMessage` on a command hook and ignores unknown keys such as `shell`; only the file's top level rejects unknown keys. Spec §8's `hooks.json` therefore parses on Codex unchanged.

## File Structure

```text
.claude-plugin/marketplace.json                 Claude marketplace: two local plugins + curated superpowers (Task 3)
.agents/plugins/marketplace.json                Codex marketplace: two local plugins (Task 7)
README.md                                       marketplace overview, install on both harnesses, symlink recipe (Task 7)
plugins/sensemaking/
  .claude-plugin/plugin.json                    identity, no deps, no hooks (Task 1)
  .codex-plugin/plugin.json                     identity + interface block, skills path (Task 2)
  skills/rethink-audit/SKILL.md                 byte copy from harness-backup (Task 2)
  skills/rethink-audit/agents/openai.yaml       byte copy from harness-backup (Task 2)
  LICENSE, README.md                            (Task 1)
plugins/software-development/
  .claude-plugin/plugin.json                    identity + dependencies (Task 4)
  .codex-plugin/plugin.json                     identity + interface, skills path, no hooks key (Task 4)
  LICENSE                                       MIT + obra's notice for the vendored skill (Task 4)
  README.md                                     install, env var, what is vendored (Task 4)
  skills/brainstorming/                         8 files vendored from upstream (Task 5)
  hooks/hooks.json                              SessionStart wiring (Task 6)
  hooks/session-start                           bash: payload.md -> JSON envelope (Task 6)
  hooks/payload.md                              upstream using-superpowers + frame + one edit (Task 6)
tests/run.sh                                    runs tests/test-*.sh, exit 1 on any failure (Task 1)
tests/lib.sh                                    REPO_ROOT, fail(), upstream_sha(), fetch_upstream() (Task 1)
tests/test-json-wellformed.sh                   every manifest and hooks.json parses (Task 1)
tests/test-claude-validate.sh                   claude plugin validate --strict (Task 1, extended Task 3)
tests/test-codex-validate.sh                    validate_plugin.py on plugins/* (Task 2)
tests/test-upstream-pin.sh                      shallow fetch at sha; 13 listed dirs exist; brainstorming absent (Task 3)
tests/test-references-resolve.sh                marketplace source paths and dependency names resolve to real plugins (Task 4)
tests/test-vendored-brainstorming.sh            vendored tree == upstream except header + description (Task 5)
tests/test-hook.sh                              payload exactness + envelope round-trip (Task 6)
tests/test-codex-marketplace.sh                 Codex marketplace shape and agreement with Claude's (Task 7)
.github/workflows/validate.yml                  installs both validators, runs tests/run.sh (Task 8)
docs/superpowers/specs/2026-09-04-…-design.md   amended §6.2/§10.2/§10.3/§12 (Task 4); §14 gate results (Task 11)
```

All tests are bash scripts that `source tests/lib.sh`, use `set -euo pipefail`, and call `fail "message"` (prints `FAIL: message`, exits 1). A test passes when it exits 0. `tests/run.sh` is the single entry point for local runs and CI.

---

### Task 1: Test runner, JSON check, and the `sensemaking` plugin (Claude side)

**Files:**
- Create: `tests/run.sh`
- Create: `tests/lib.sh`
- Create: `tests/test-json-wellformed.sh`
- Create: `tests/test-claude-validate.sh`
- Create: `plugins/sensemaking/.claude-plugin/plugin.json`
- Create: `plugins/sensemaking/LICENSE`
- Create: `plugins/sensemaking/README.md`

**Interfaces:**
- Consumes: nothing.
- Produces: `tests/lib.sh` exporting `REPO_ROOT` (absolute repo path), `MARKETPLACE` (path to `.claude-plugin/marketplace.json`), `fail <msg>` (prints `FAIL: <msg>` to stderr, exit 1), `upstream_sha` (prints the sha from the marketplace's `superpowers` entry), `fetch_upstream` (prints an absolute path to a checkout of obra/superpowers at that sha). `tests/run.sh` runs every `tests/test-*.sh`. Later tasks add tests by dropping a `tests/test-<name>.sh` file.

- [ ] **Step 1: Create the branch**

```bash
git switch -c tracer-bullet main
```

- [ ] **Step 2: Write the runner and the shared library**

`tests/run.sh`:

```bash
#!/usr/bin/env bash
# Run every tests/test-*.sh and exit 1 if any fails.
# Same entry point for local runs and CI.
set -uo pipefail
cd "$(dirname "$0")/.."
status=0
for t in tests/test-*.sh; do
  if bash "$t"; then
    printf 'PASS %s\n' "$t"
  else
    printf 'FAIL %s\n' "$t"
    status=1
  fi
done
exit "$status"
```

`tests/lib.sh`:

```bash
#!/usr/bin/env bash
# Shared helpers for tests/test-*.sh. Source this file; do not execute it.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

# The pinned obra/superpowers sha, read from the one place it is declared.
upstream_sha() {
  jq -r '.plugins[] | select(.name == "superpowers") | .source.sha' "$MARKETPLACE"
}

# Shallow-fetch obra/superpowers at the pinned sha and print the checkout path.
# Reuses an existing checkout whose HEAD already matches. Override the location
# with UPSTREAM_DIR.
fetch_upstream() {
  local sha dir
  sha="$(upstream_sha)"
  dir="${UPSTREAM_DIR:-${TMPDIR:-/tmp}/software-development-upstream-superpowers}"
  if [ -d "$dir/.git" ] && [ "$(git -C "$dir" rev-parse HEAD)" = "$sha" ]; then
    printf '%s\n' "$dir"
    return
  fi
  rm -rf "$dir"
  mkdir -p "$dir"
  git -C "$dir" init -q
  git -C "$dir" remote add origin https://github.com/obra/superpowers.git
  git -C "$dir" fetch -q --depth 1 origin "$sha"
  git -C "$dir" checkout -q FETCH_HEAD
  printf '%s\n' "$dir"
}
```

```bash
chmod +x tests/run.sh
```

- [ ] **Step 3: Write the two failing tests**

`tests/test-json-wellformed.sh`:

```bash
#!/usr/bin/env bash
# Every marketplace manifest, plugin manifest, and hooks file must parse as JSON.
. "$(dirname "$0")/lib.sh"

found=0
while IFS= read -r f; do
  jq empty "$f" || fail "not valid JSON: $f"
  found=$((found + 1))
done < <(find "$REPO_ROOT/.claude-plugin" "$REPO_ROOT/.agents" "$REPO_ROOT/plugins" \
           -name '*.json' -not -path '*/skills/*' 2>/dev/null | sort)

[ "$found" -gt 0 ] || fail "no manifests found"
printf 'json: %s files well-formed\n' "$found"
```

`tests/test-claude-validate.sh`:

```bash
#!/usr/bin/env bash
# Schema-check every plugin manifest with Claude Code's own validator.
# --strict turns warnings (unknown fields, missing metadata) into failures.
. "$(dirname "$0")/lib.sh"

found=0
for p in "$REPO_ROOT"/plugins/*/; do
  [ -f "$p/.claude-plugin/plugin.json" ] || continue
  claude plugin validate --strict "$p" || fail "claude plugin validate --strict $p"
  found=$((found + 1))
done
[ "$found" -gt 0 ] || fail "no plugin manifests under plugins/"
```

- [ ] **Step 4: Run the tests to verify they fail**

Run: `tests/run.sh`
Expected: `FAIL: no manifests found`, `FAIL: no plugin manifests under plugins/`, two `FAIL tests/…` lines, exit 1.

- [ ] **Step 5: Write the sensemaking Claude manifest, LICENSE, README**

`plugins/sensemaking/.claude-plugin/plugin.json`:

```json
{
  "name": "sensemaking",
  "version": "0.1.0",
  "description": "Skills shared by software-development and research-vault.",
  "author": { "name": "Eran Roseman", "url": "https://github.com/eranroseman" },
  "homepage": "https://github.com/eranroseman/software-development",
  "repository": "https://github.com/eranroseman/software-development",
  "license": "MIT",
  "keywords": ["sensemaking", "skills", "design-audit"]
}
```

`plugins/sensemaking/LICENSE`:

```text
MIT License

Copyright (c) 2026 Eran Roseman

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

`plugins/sensemaking/README.md`:

```markdown
# sensemaking

Skills shared by `software-development` and, later, `research-vault`.

## Skills

- `rethink-audit`: clean-slate redesign audit of an existing module, service,
  or feature. Design and architecture only; it applies no changes.

## Install

Claude Code: installing `software-development@eranroseman` pulls this plugin
in as a dependency. To install it alone:

    claude plugin marketplace add eranroseman/software-development
    claude plugin install sensemaking@eranroseman

Codex has no dependency concept, so install it explicitly:

    codex plugin marketplace add https://github.com/eranroseman/software-development.git
    codex plugin add sensemaking@eranroseman

## License

MIT. See `LICENSE`.
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `tests/run.sh`
Expected: `json: 1 files well-formed`, `✔ Validation passed`, `PASS tests/test-claude-validate.sh`, `PASS tests/test-json-wellformed.sh`, exit 0.

- [ ] **Step 7: Commit**

```bash
git add tests plugins/sensemaking
git commit -m "Add test runner and the sensemaking plugin's Claude manifest

tests/run.sh is the single entry point for local runs and CI. Two checks
so far: every manifest parses, and claude plugin validate --strict passes.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 2: `sensemaking` Codex manifest and the `rethink-audit` skill

**Files:**
- Create: `plugins/sensemaking/.codex-plugin/plugin.json`
- Create: `plugins/sensemaking/skills/rethink-audit/SKILL.md` (copy)
- Create: `plugins/sensemaking/skills/rethink-audit/agents/openai.yaml` (copy)
- Create: `tests/test-codex-validate.sh`

**Interfaces:**
- Consumes: `tests/lib.sh` (`REPO_ROOT`, `fail`).
- Produces: the `CODEX_PLUGIN_VALIDATOR` environment variable contract. The test reads the validator path from it, defaulting to `$HOME/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py`. Task 8's CI sets it.

- [ ] **Step 1: Write the failing test**

`tests/test-codex-validate.sh`:

```bash
#!/usr/bin/env bash
# Run Codex's own plugin validator on every plugin. Both must pass cleanly.
# The validator ships with codex-cli under ~/.codex/skills/.system; CI fetches
# the same two files from openai/codex and points CODEX_PLUGIN_VALIDATOR at them.
. "$(dirname "$0")/lib.sh"

VALIDATOR="${CODEX_PLUGIN_VALIDATOR:-$HOME/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py}"
[ -f "$VALIDATOR" ] || fail "Codex validator not found at $VALIDATOR (set CODEX_PLUGIN_VALIDATOR)"

found=0
for p in "$REPO_ROOT"/plugins/*/; do
  [ -f "$p/.codex-plugin/plugin.json" ] || fail "$p has no .codex-plugin/plugin.json"
  python3 "$VALIDATOR" "$p" || fail "Codex validator rejected $p"
  found=$((found + 1))
done
[ "$found" -gt 0 ] || fail "no plugins under plugins/"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/test-codex-validate.sh`
Expected: `FAIL: /…/plugins/sensemaking/ has no .codex-plugin/plugin.json`, exit 1.

- [ ] **Step 3: Copy `rethink-audit` byte-for-byte and write the Codex manifest**

```bash
mkdir -p plugins/sensemaking/skills/rethink-audit/agents
cp ~/harness-backup/claude/skills/rethink-audit/SKILL.md plugins/sensemaking/skills/rethink-audit/SKILL.md
cp ~/harness-backup/claude/skills/rethink-audit/agents/openai.yaml plugins/sensemaking/skills/rethink-audit/agents/openai.yaml
md5sum plugins/sensemaking/skills/rethink-audit/SKILL.md plugins/sensemaking/skills/rethink-audit/agents/openai.yaml
```

Expected md5 output, exactly:

```text
41f9e1fc78aff3dcd302995322c88921  plugins/sensemaking/skills/rethink-audit/SKILL.md
2a3f8e6f9044a4126ced384dd59d2200  plugins/sensemaking/skills/rethink-audit/agents/openai.yaml
```

If either differs, `~/harness-backup` moved on since 2026-09-04; stop and report the diff rather than adapting. This is the only check on these two files' bytes. The source is machine-local, so no test repeats it, and sub-project 5 adapts the skill anyway.

`plugins/sensemaking/.codex-plugin/plugin.json`:

```json
{
  "name": "sensemaking",
  "version": "0.1.0",
  "description": "Skills shared by software-development and research-vault.",
  "author": { "name": "Eran Roseman", "url": "https://github.com/eranroseman" },
  "homepage": "https://github.com/eranroseman/software-development",
  "repository": "https://github.com/eranroseman/software-development",
  "license": "MIT",
  "keywords": ["sensemaking", "skills", "design-audit"],
  "skills": "./skills/",
  "interface": {
    "displayName": "Sensemaking",
    "shortDescription": "Skills shared by software-development and research-vault",
    "longDescription": "Clean-slate redesign audits and other sensemaking skills shared across Eran Roseman's software-development and research-vault harnesses.",
    "developerName": "Eran Roseman",
    "category": "Productivity",
    "capabilities": ["Instructions"],
    "websiteURL": "https://github.com/eranroseman/software-development",
    "defaultPrompt": ["Run a clean-slate redesign audit of this module."]
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `tests/run.sh`
Expected: `Plugin validation passed: /…/plugins/sensemaking/`, `json: 2 files well-formed`, three `PASS` lines, exit 0.

- [ ] **Step 5: Commit**

```bash
git add plugins/sensemaking tests/test-codex-validate.sh
git commit -m "Add the sensemaking Codex manifest and the rethink-audit skill

rethink-audit is a byte copy of ~/harness-backup/claude/skills/rethink-audit;
adaptation is sub-project 5. Codex's validate_plugin.py now runs in tests.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 3: Claude marketplace manifest and the upstream pin test

**Files:**
- Create: `.claude-plugin/marketplace.json`
- Create: `tests/test-upstream-pin.sh`
- Modify: `tests/test-claude-validate.sh`

**Interfaces:**
- Consumes: `tests/lib.sh` (`MARKETPLACE`, `upstream_sha`, `fetch_upstream`, `fail`).
- Produces: `.claude-plugin/marketplace.json`, the single source of truth for the pinned sha, the `6.3.0` version, and the 13-name list. Tasks 4, 5, 6, 7 and 10 read from it. Two files repeat the sha as human-readable provenance, the `software-development` LICENSE (Task 4) and the vendored `SKILL.md` header (Task 5); Task 5's test asserts both equal the marketplace value.

- [ ] **Step 1: Write the failing test**

`tests/test-upstream-pin.sh`:

```bash
#!/usr/bin/env bash
# The curated superpowers entry must point at a real upstream sha, list exactly
# the 13 skill directories that exist there, omit brainstorming, and carry the
# version upstream declares at that sha. Needs network access.
. "$(dirname "$0")/lib.sh"

[ -f "$MARKETPLACE" ] || fail "missing $MARKETPLACE"
sha="$(upstream_sha)"
[ "${#sha}" -eq 40 ] || fail "superpowers entry has no 40-char sha (got '$sha')"

UP="$(fetch_upstream)"
[ "$(git -C "$UP" rev-parse HEAD)" = "$sha" ] || fail "checkout HEAD != pinned sha"

mapfile -t listed < <(jq -r '.plugins[] | select(.name == "superpowers") | .skills[]' "$MARKETPLACE" | sed 's#^\./##' | sort)
[ "${#listed[@]}" -eq 13 ] || fail "expected 13 listed skills, got ${#listed[@]}"
for s in "${listed[@]}"; do
  [ "$s" != "brainstorming" ] || fail "brainstorming must not be listed"
  [ -f "$UP/skills/$s/SKILL.md" ] || fail "upstream has no skills/$s/SKILL.md at $sha"
done

# listed + brainstorming must be the whole upstream set, so a new upstream skill
# is a visible decision at the next sha bump rather than a silent omission.
diff <(printf '%s\n' "${listed[@]}" brainstorming | sort) \
     <(find "$UP/skills" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort) \
  || fail "listed skills + brainstorming != upstream skill directories"

want_version="$(jq -r '.plugins[] | select(.name == "superpowers") | .version' "$MARKETPLACE")"
have_version="$(jq -r '.version' "$UP/.claude-plugin/plugin.json")"
[ "$want_version" = "$have_version" ] || fail "version $want_version != upstream $have_version"

[ "$(jq -r '.plugins[] | select(.name == "superpowers") | .source.source' "$MARKETPLACE")" = "git-subdir" ] || fail "source.source must be git-subdir"
[ "$(jq -r '.plugins[] | select(.name == "superpowers") | .source.path' "$MARKETPLACE")" = "skills" ] || fail "source.path must be skills"
[ "$(jq -r '.plugins[] | select(.name == "superpowers") | .strict' "$MARKETPLACE")" = "false" ] || fail "strict must be false"

printf 'upstream-pin: 13 listed dirs exist at %s; brainstorming excluded; version %s\n' "$sha" "$want_version"
```

Also extend `tests/test-claude-validate.sh` so it validates the marketplace manifest first. The whole file, replacing the Task 1 version:

`tests/test-claude-validate.sh`:

```bash
#!/usr/bin/env bash
# Schema-check every plugin manifest with Claude Code's own validator.
# --strict turns warnings (unknown fields, missing metadata) into failures.
. "$(dirname "$0")/lib.sh"

[ -f "$MARKETPLACE" ] || fail "missing $MARKETPLACE"
claude plugin validate --strict "$MARKETPLACE" || fail "claude plugin validate --strict $MARKETPLACE"

found=0
for p in "$REPO_ROOT"/plugins/*/; do
  [ -f "$p/.claude-plugin/plugin.json" ] || continue
  claude plugin validate --strict "$p" || fail "claude plugin validate --strict $p"
  found=$((found + 1))
done
[ "$found" -gt 0 ] || fail "no plugin manifests under plugins/"
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `tests/run.sh`
Expected: `FAIL: missing /…/.claude-plugin/marketplace.json` from both `test-claude-validate.sh` and `test-upstream-pin.sh`, exit 1.

- [ ] **Step 3: Write the marketplace manifest (spec §5.1, verbatim)**

`.claude-plugin/marketplace.json`:

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

`./plugins/software-development` does not exist yet; `claude plugin validate --strict` checks the manifest schema, not source paths (verified 2026-09-04 with the directory absent).

- [ ] **Step 4: Run the tests to verify they pass**

Run: `tests/run.sh`
Expected: `upstream-pin: 13 listed dirs exist at b36e0829c6d0140e93cfef2ca599b1b07d4a7797; brainstorming excluded; version 6.3.0`, `✔ Validation passed` twice, four `PASS` lines, exit 0. The first run fetches upstream (a few seconds); later runs reuse `/tmp/software-development-upstream-superpowers`.

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/marketplace.json tests/test-upstream-pin.sh tests/test-claude-validate.sh
git commit -m "Add the eranroseman Claude marketplace with a curated superpowers entry

superpowers is a git-subdir entry rooted at upstream's skills/ directory,
pinned by sha, listing 13 of 14 skills. brainstorming is the one dropped;
software-development ships its own. A network test asserts the list against
the pinned checkout.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 4: `software-development` manifests, LICENSE, README, and spec amendment

**Files:**
- Create: `plugins/software-development/.claude-plugin/plugin.json`
- Create: `plugins/software-development/.codex-plugin/plugin.json`
- Create: `plugins/software-development/LICENSE`
- Create: `plugins/software-development/README.md`
- Create: `tests/test-references-resolve.sh`
- Modify: `docs/superpowers/specs/2026-09-04-software-development-layout-and-tracer-design.md` (§6.2, §10.2, §10.3, §12, §13)

**Interfaces:**
- Consumes: `tests/test-claude-validate.sh`, `tests/test-codex-validate.sh` (both already iterate `plugins/*/`).
- Produces: plugin id `software-development@eranroseman` with `dependencies: ["sensemaking", "superpowers"]`; Codex manifest with `"skills": "./skills/"` and no `hooks` key; `tests/test-references-resolve.sh`, which holds every string-source marketplace path and every `dependencies` name to a real plugin.

- [ ] **Step 1: Create the plugin directory and watch the existing tests fail**

```bash
mkdir -p plugins/software-development
touch plugins/software-development/.gitkeep
```

Run: `tests/run.sh`
Expected: `FAIL: /…/plugins/software-development/ has no .codex-plugin/plugin.json` from `test-codex-validate.sh`, exit 1. (`test-claude-validate.sh` skips directories without a Claude manifest, so it still passes; that is fine.)

- [ ] **Step 2: Write the failing references test**

The marketplace already names `./plugins/software-development` (Task 3) and this task declares `dependencies`. Nothing else checks that either resolves; an install would be the first thing to notice a stale path or a misspelt dependency.

`tests/test-references-resolve.sh`:

```bash
#!/usr/bin/env bash
# The marketplace listing promises directories that exist and dependency
# names that resolve to real plugins. Nothing else checks either claim
# statically; an install would be the first thing to notice a stale path or
# a renamed dependency.
. "$(dirname "$0")/lib.sh"

# Check A: every Claude marketplace entry with a plain-string source names a
# real plugin.json whose own name agrees with the marketplace entry's name.
found=0
while IFS= read -r entry; do
  name="$(jq -r '.name' <<<"$entry")"
  src="$(jq -r '.source' <<<"$entry" | sed 's#^\./##')"
  manifest="$REPO_ROOT/$src/.claude-plugin/plugin.json"
  [ -f "$manifest" ] || fail "$name: $src has no .claude-plugin/plugin.json"
  [ "$(jq -r '.name' "$manifest")" = "$name" ] || fail "$name: manifest name differs"
  found=$((found + 1))
done < <(jq -c '.plugins[] | select(.source | type == "string")' "$MARKETPLACE")

[ "$found" -gt 0 ] || fail "no string-source marketplace entries found"

# Check B: every plugin's declared dependency names a real marketplace plugin.
# The dependencies key is optional; a manifest without it is not a failure.
names="$(jq -r '.plugins[].name' "$MARKETPLACE")"
depcount=0
for pf in "$REPO_ROOT"/plugins/*/.claude-plugin/plugin.json; do
  pname="$(jq -r '.name' "$pf")"
  while IFS= read -r dep; do
    depcount=$((depcount + 1))
    grep -qxF "$dep" <<<"$names" || fail "$pname: dependency '$dep' is not a marketplace plugin"
  done < <(jq -r '.dependencies[]?' "$pf")
done

[ "$depcount" -gt 0 ] || fail "no dependencies found"

printf 'references-resolve: %s string-source path(s) resolve, %s dependency name(s) resolve\n' "$found" "$depcount"
```

Run: `bash tests/test-references-resolve.sh`
Expected: `FAIL: software-development: plugins/software-development has no .claude-plugin/plugin.json`, exit 1.

- [ ] **Step 3: Write both manifests, LICENSE, README**

`plugins/software-development/.claude-plugin/plugin.json` (spec §6.1, verbatim):

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

`plugins/software-development/.codex-plugin/plugin.json` (spec §6.2 minus the `hooks` key; see the deviation note at the top of this plan):

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

`plugins/software-development/LICENSE`:

```text
MIT License

Copyright (c) 2026 Eran Roseman

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

----------------------------------------------------------------------

skills/brainstorming/ is vendored from https://github.com/obra/superpowers
(directory skills/brainstorming/ at commit b36e0829c6d0140e93cfef2ca599b1b07d4a7797)
and remains under its original license:

MIT License

Copyright (c) 2025 Jesse Vincent

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

`plugins/software-development/README.md`:

```markdown
# software-development

The glue plugin of Eran Roseman's software-development harness. It is a thin
layer over two upstream skill packs, not a home for copies of them.

What it ships:

- `skills/brainstorming/`: obra/superpowers' `brainstorming` skill, vendored
  at a pinned commit with one change, a narrowed `description` so that it
  fires on build requests and no longer competes with `grilling`. The
  provenance header at the top of `SKILL.md` names the commit. Do not
  hand-edit the skill; re-vendor from upstream to update it.
- `hooks/session-start`: a SessionStart hook that injects `hooks/payload.md`,
  upstream's `using-superpowers` text with its one `superpowers:brainstorming`
  reference repointed at `software-development:brainstorming`.

What it depends on (Claude Code installs both automatically):

- `sensemaking@eranroseman`: shared skills, starting with `rethink-audit`.
- `superpowers@eranroseman`: obra/superpowers taken straight from upstream,
  13 of its 14 skills. `brainstorming` is the one left out.

## Install

Claude Code:

    claude plugin marketplace add eranroseman/software-development
    claude plugin install software-development@eranroseman

Codex (no dependency concept; superpowers arrives by symlink, see the
repository README):

    codex plugin marketplace add https://github.com/eranroseman/software-development.git
    codex plugin add software-development@eranroseman
    codex plugin add sensemaking@eranroseman

Codex prompts once to trust the SessionStart hook.

## Environment

The brainstorming skill's Visual Companion fetches a logo from an external
site unless `SUPERPOWERS_DISABLE_TELEMETRY` or `DISABLE_TELEMETRY` is set.
Set one of them in your shell profile.

## License

MIT. The vendored `skills/brainstorming/` is MIT, © 2025 Jesse Vincent. See
`LICENSE`.
```

```bash
rm plugins/software-development/.gitkeep
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `tests/run.sh`
Expected: `Plugin validation passed: /…/plugins/software-development/`, `✔ Validation passed` three times, `json: 5 files well-formed`, `references-resolve: 2 string-source path(s) resolve, 2 dependency name(s) resolve`, five `PASS` lines, exit 0.

- [ ] **Step 5: Amend the spec so it matches the manifest**

In `docs/superpowers/specs/2026-09-04-software-development-layout-and-tracer-design.md`:

(a) §6.2, in the JSON block, delete the line:

```json
  "hooks": "./hooks/hooks.json",
```

(b) §6.2, replace the paragraph that begins "`interface.displayName`, `shortDescription`, …" with:

```markdown
`interface.displayName`, `shortDescription`, `longDescription`, `developerName`, `category` and `defaultPrompt` are required by Codex's own validator. The manifest declares no `hooks` key: the validator rejects the key when present, and Codex's loader falls back to `hooks/hooks.json` at the plugin root when it is absent (`codex-rs/core-plugins/src/loader.rs`, `load_plugin_hooks`, `DEFAULT_HOOKS_CONFIG_FILE`, at openai/codex `f3f6922`). An empty object `"hooks": {}` would suppress that fallback, which is what upstream superpowers does to keep its Claude hook off Codex. Whether the fallback loads our hook is gate G4 (§10.2).
```

(c) §10.2, gate G4 row, replace the "Passes when" cell text with:

```markdown
Codex either loads `hooks/hooks.json` by manifest fallback after the trust prompt (a `software-development@eranroseman:hooks/hooks.json:session_start:0:0` entry appears under `[hooks.state]` in `~/.codex/config.toml` and the payload appears once in a session) or does not; either outcome is recorded and sub-project 3 designs against it
```

(d) §10.3, replace the second bullet with:

```markdown
- `python3 ~/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py plugins/<name>` on both plugins; both pass. CI fetches the same script from openai/codex at a pinned sha.
```

(e) §13, replace the bullet "Whether Codex honours `hooks` in a plugin manifest for our plugin (G4)." with:

```markdown
- Whether Codex loads `hooks/hooks.json` by manifest fallback for our plugin (G4).
```

(f) §12, add this row at the end of the table:

```markdown
| Codex loads `hooks/hooks.json` when the manifest has no `hooks` key; `{}` suppresses it; the hook-file parser accepts `timeout`, `async`, `statusMessage` and ignores `shell` | `codex-rs/core-plugins/src/loader.rs` line 1230 and `codex-rs/config/src/hook_config.rs` at openai/codex `f3f6922519fa38487c8250c2b8a670a39a2cf9ff`; upstream superpowers `tests/codex/test-marketplace-manifest.sh` |
```

- [ ] **Step 6: Commit**

```bash
git add plugins/software-development docs/superpowers/specs tests/test-references-resolve.sh
git commit -m "Add the software-development plugin manifests

The Codex manifest omits the hooks key: Codex loads hooks/hooks.json by
fallback when the key is absent, and its validator rejects the key when
present. The spec's sections 6.2, 10.2, 10.3, 12 and 13 now say the same.
A test holds the marketplace's source paths and the plugin's dependency
names to real plugins.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 5: Vendor the `brainstorming` skill

**Files:**
- Create: `plugins/software-development/skills/brainstorming/SKILL.md` (copied, then two edits)
- Create: `plugins/software-development/skills/brainstorming/visual-companion.md` (copy)
- Create: `plugins/software-development/skills/brainstorming/spec-document-reviewer-prompt.md` (copy)
- Create: `plugins/software-development/skills/brainstorming/scripts/frame-template.html` (copy)
- Create: `plugins/software-development/skills/brainstorming/scripts/helper.js` (copy)
- Create: `plugins/software-development/skills/brainstorming/scripts/server.cjs` (copy)
- Create: `plugins/software-development/skills/brainstorming/scripts/start-server.sh` (copy, mode 755)
- Create: `plugins/software-development/skills/brainstorming/scripts/stop-server.sh` (copy, mode 755)
- Create: `tests/test-vendored-brainstorming.sh`

**Interfaces:**
- Consumes: `tests/lib.sh` (`fetch_upstream`, `upstream_sha`, `fail`).
- Produces: skill `software-development:brainstorming` (Claude) / `software-development:brainstorming` (Codex catalog), invocable as `/brainstorming`. The provenance header's first line is `<!-- Vendored from https://github.com/obra/superpowers at <sha>`; sub-project 4 reads the sha from it. The drift test reads the sha from `.claude-plugin/marketplace.json` via `upstream_sha` and asserts the header carries that value.

- [ ] **Step 1: Write the failing test**

`tests/test-vendored-brainstorming.sh`:

```bash
#!/usr/bin/env bash
# The vendored brainstorming skill must equal upstream at the pinned sha in
# every byte and file mode, except: a provenance header right after the
# frontmatter, and line 3 (the description). Needs network access.
. "$(dirname "$0")/lib.sh"

V="$REPO_ROOT/plugins/software-development/skills/brainstorming"
[ -d "$V" ] || fail "missing $V"
UP="$(fetch_upstream)" || fail "could not fetch upstream at $(upstream_sha)"
U="$UP/skills/brainstorming"
sha="$(upstream_sha)"

# Same file set.
diff <(cd "$U" && find . -type f | sort) <(cd "$V" && find . -type f | sort) \
  || fail "file set differs from upstream"

# Every file: identical executable bit. Every file but SKILL.md: identical bytes.
while IFS= read -r f; do
  if [ -x "$U/$f" ] && [ ! -x "$V/$f" ]; then fail "$f lost its executable bit"; fi
  if [ ! -x "$U/$f" ] && [ -x "$V/$f" ]; then fail "$f gained an executable bit"; fi
  [ "$f" = "./SKILL.md" ] && continue
  cmp -s "$U/$f" "$V/$f" || fail "$f differs from upstream"
done < <(cd "$V" && find . -type f | sort)

# SKILL.md frontmatter: name untouched, line 3 is a description, narrowed text present.
[ "$(sed -n 1p "$V/SKILL.md")" = "---" ] || fail "line 1 is not a frontmatter fence"
[ "$(sed -n 2p "$V/SKILL.md")" = "name: brainstorming" ] || fail "name changed"
# Line 3: the narrowed description, verbatim.
want='description: "Design front door of the superpowers spine. Classifies a build request as spike, bounded, or architectural, then takes it from intent to an approved design, and to a written spec for architectural work, before any implementation. Use for \"let'"'"'s build, add, or change X\". Not for open-ended ideation, and not for stress-testing an existing plan."'
[ "$(sed -n 3p "$V/SKILL.md")" = "$want" ] || fail "line 3 is not the narrowed description, verbatim"
[ "$(sed -n 4p "$V/SKILL.md")" = "---" ] || fail "line 4 is not the closing frontmatter fence"

# Lines 5-9: the whole provenance header, verbatim.
expected_header="$(printf '%s\n' \
  "<!-- Vendored from https://github.com/obra/superpowers at $sha" \
  "     path: skills/brainstorming/" \
  "     MIT, © 2025 Jesse Vincent. The only local change is the description in the frontmatter above." \
  "     Do not hand-edit below this line; re-vendor from upstream to update." \
  "-->")"
[ "$(sed -n 5,9p "$V/SKILL.md")" = "$expected_header" ] || fail "lines 5-9 are not the provenance header"

# Body: drop line 3 and lines 5-9; rest must equal upstream minus line 3.
diff <(sed '3d' "$U/SKILL.md") <(sed -e '3d' -e '5,9d' "$V/SKILL.md") \
  || fail "SKILL.md changed beyond the header and the description"

# The LICENSE's provenance notice names the same commit as the pin.
grep -q "at commit $sha)" "$REPO_ROOT/plugins/software-development/LICENSE" \
  || fail "LICENSE provenance sha != marketplace sha"

printf 'vendored-brainstorming: matches upstream %s except header + description\n' "$sha"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/test-vendored-brainstorming.sh`
Expected: `FAIL: missing /…/plugins/software-development/skills/brainstorming`, exit 1.

- [ ] **Step 3: Copy the skill from the pinned checkout, preserving modes**

```bash
UP="$(bash -c '. tests/lib.sh; fetch_upstream')"
mkdir -p plugins/software-development/skills
cp -a "$UP/skills/brainstorming" plugins/software-development/skills/brainstorming
find plugins/software-development/skills/brainstorming -type f | sort
```

Expected: exactly these 8 paths:

```text
plugins/software-development/skills/brainstorming/SKILL.md
plugins/software-development/skills/brainstorming/scripts/frame-template.html
plugins/software-development/skills/brainstorming/scripts/helper.js
plugins/software-development/skills/brainstorming/scripts/server.cjs
plugins/software-development/skills/brainstorming/scripts/start-server.sh
plugins/software-development/skills/brainstorming/scripts/stop-server.sh
plugins/software-development/skills/brainstorming/spec-document-reviewer-prompt.md
plugins/software-development/skills/brainstorming/visual-companion.md
```

- [ ] **Step 4: Make the two permitted edits to SKILL.md**

Replace line 3 (the description) with this single line. The value is a YAML double-quoted scalar; the inner quotes are escaped as `\"`.

```bash
python3 - <<'EOF'
from pathlib import Path
p = Path("plugins/software-development/skills/brainstorming/SKILL.md")
lines = p.read_text().split("\n")
assert lines[0] == "---" and lines[1] == "name: brainstorming" and lines[2].startswith("description: ") and lines[3] == "---", lines[:4]
lines[2] = ('description: "Design front door of the superpowers spine. Classifies a build request as spike, bounded, '
            'or architectural, then takes it from intent to an approved design, and to a written spec for architectural '
            'work, before any implementation. Use for \\"let\'s build, add, or change X\\". Not for open-ended ideation, '
            'and not for stress-testing an existing plan."')
header = [
    "<!-- Vendored from https://github.com/obra/superpowers at b36e0829c6d0140e93cfef2ca599b1b07d4a7797",
    "     path: skills/brainstorming/",
    "     MIT, © 2025 Jesse Vincent. The only local change is the description in the frontmatter above.",
    "     Do not hand-edit below this line; re-vendor from upstream to update.",
    "-->",
]
lines[4:4] = header
p.write_text("\n".join(lines))
EOF
sed -n 1,12p plugins/software-development/skills/brainstorming/SKILL.md
```

Expected first lines:

```text
---
name: brainstorming
description: "Design front door of the superpowers spine. Classifies a build request as spike, bounded, or architectural, then takes it from intent to an approved design, and to a written spec for architectural work, before any implementation. Use for \"let's build, add, or change X\". Not for open-ended ideation, and not for stress-testing an existing plan."
---
<!-- Vendored from https://github.com/obra/superpowers at b36e0829c6d0140e93cfef2ca599b1b07d4a7797
     path: skills/brainstorming/
     MIT, © 2025 Jesse Vincent. The only local change is the description in the frontmatter above.
     Do not hand-edit below this line; re-vendor from upstream to update.
-->

# Brainstorming Ideas Into Designs

```

Confirm the frontmatter still parses as YAML and the name survived:

```bash
python3 -c "
import yaml,io
t=open('plugins/software-development/skills/brainstorming/SKILL.md').read().split('---')[1]
d=yaml.safe_load(t); print(d['name']); print(len(d['description']), 'chars'); print(d['description'][-60:])"
```

Expected: `brainstorming`, `344 chars`, and the description ending `not for stress-testing an existing plan.`

- [ ] **Step 5: Run the tests to verify they pass**

Run: `tests/run.sh`
Expected: `vendored-brainstorming: matches upstream b36e0829c6d0140e93cfef2ca599b1b07d4a7797 except header + description`, all six tests `PASS`, exit 0. The Codex validator now also parses `skills/brainstorming/SKILL.md`.

- [ ] **Step 6: Commit**

```bash
git add plugins/software-development/skills tests/test-vendored-brainstorming.sh
git commit -m "Vendor obra/superpowers' brainstorming skill with a narrowed description

Copied whole from upstream at b36e0829 (8 files). The name stays
brainstorming so bare-name mentions across the 13 curated skills still
resolve; only the description changes, so grilling and brainstorming no
longer compete on trigger text. A test holds every other byte to upstream.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 6: SessionStart hook

**Files:**
- Create: `plugins/software-development/hooks/hooks.json`
- Create: `plugins/software-development/hooks/session-start` (mode 755)
- Create: `plugins/software-development/hooks/payload.md`
- Create: `tests/test-hook.sh`

**Interfaces:**
- Consumes: `tests/lib.sh` (`fetch_upstream`, `fail`); upstream `skills/using-superpowers/SKILL.md` at the pinned sha.
- Produces: an executable `hooks/session-start` that takes no arguments, reads `hooks/payload.md` next to itself, and prints one JSON object on stdout: `{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"<payload>"}}`. Every C0 control character in the payload is escaped, not only the common five, so a future payload cannot silently break the envelope. `hooks/hooks.json` wires it for `startup|clear|compact`. Sub-project 3 replaces only `payload.md`.

- [ ] **Step 1: Write the failing test**

`tests/test-hook.sh`:

```bash
#!/usr/bin/env bash
# The SessionStart hook must (1) carry upstream's using-superpowers text inside
# upstream's frame with exactly one edit, (2) emit it as the documented JSON
# envelope so that a JSON parser recovers the payload byte-for-byte,
# (3) be wired by hooks.json, and (4) escape every C0 control character, not
# just the common five. Needs network access for (1).
. "$(dirname "$0")/lib.sh"

H="$REPO_ROOT/plugins/software-development/hooks"
[ -f "$H/payload.md" ] || fail "missing $H/payload.md"
[ -f "$H/hooks.json" ] || fail "missing $H/hooks.json"
[ -x "$H/session-start" ] || fail "$H/session-start missing or not executable"

# (1) payload exactness
UP="$(fetch_upstream)"
src="$UP/skills/using-superpowers/SKILL.md"
[ "$(sed -n 30p "$src")" = '- "Let'"'"'s build X" → superpowers:brainstorming first, then implementation skills.' ] \
  || fail "upstream line 30 is not the expected superpowers:brainstorming line; re-audit the edit"
expected="$(mktemp)"
{
  printf '<EXTREMELY_IMPORTANT>\nYou have superpowers.\n\n'
  printf '**Below is the full content of your %s skill - your introduction to using skills. For all other skills, use the %s tool:**\n\n' \
    "'superpowers:using-superpowers'" "'Skill'"
  sed '30s/superpowers:brainstorming/software-development:brainstorming/' "$src"
  printf '</EXTREMELY_IMPORTANT>\n'
} > "$expected"
diff "$expected" "$H/payload.md" || fail "payload.md != upstream using-superpowers inside upstream's frame with one edit"
rm -f "$expected"
[ "$(grep -c 'software-development:brainstorming' "$H/payload.md")" -eq 1 ] || fail "expected exactly one software-development:brainstorming"
if grep -q 'superpowers:brainstorming' "$H/payload.md"; then fail "a superpowers:brainstorming reference survived"; fi

# (2) envelope round-trip
out="$(CLAUDE_PLUGIN_ROOT="$REPO_ROOT/plugins/software-development" "$H/session-start")"
printf '%s' "$out" | jq -e '.hookSpecificOutput.hookEventName == "SessionStart"' >/dev/null \
  || fail "output is not the SessionStart envelope: $out"
[ "$(printf '%s' "$out" | jq 'keys | length')" -eq 1 ] || fail "envelope has extra top-level keys"
diff <(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext') "$H/payload.md" \
  || fail "additionalContext does not round-trip to payload.md"

# (3) wiring
[ "$(jq -r '.hooks.SessionStart[0].matcher' "$H/hooks.json")" = 'startup|clear|compact' ] || fail "matcher"
[ "$(jq -r '.hooks.SessionStart[0].hooks[0].type' "$H/hooks.json")" = 'command' ] || fail "hook type"
[ "$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$H/hooks.json")" = '"${CLAUDE_PLUGIN_ROOT}/hooks/session-start"' ] || fail "hook command"
[ "$(jq -r 'keys | join(",")' "$H/hooks.json")" = 'hooks' ] || fail "hooks.json top level must contain only 'hooks' (Codex rejects unknown top-level keys)"

# (4) the encoder escapes control characters, not just the common five
T="$(mktemp -d)"
cp "$H/session-start" "$T/session-start"
sample=$'x\x01\x0c\x1b\x1fy "q" \\ end'
printf '%s' "$sample" > "$T/payload.md"
out="$("$T/session-start")"
printf '%s' "$out" | jq -e . >/dev/null || fail "control characters produced invalid JSON"
[ "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext')" = "$sample" ] \
  || fail "control characters did not round-trip"
rm -rf "$T"

echo "hook: payload exact, envelope round-trips, wiring correct, control characters escaped"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/test-hook.sh`
Expected: `FAIL: missing /…/plugins/software-development/hooks/payload.md`, exit 1.

- [ ] **Step 3: Generate payload.md from the pinned checkout**

```bash
UP="$(bash -c '. tests/lib.sh; fetch_upstream')"
mkdir -p plugins/software-development/hooks
{
  printf '<EXTREMELY_IMPORTANT>\nYou have superpowers.\n\n'
  printf '**Below is the full content of your %s skill - your introduction to using skills. For all other skills, use the %s tool:**\n\n' \
    "'superpowers:using-superpowers'" "'Skill'"
  sed '30s/superpowers:brainstorming/software-development:brainstorming/' "$UP/skills/using-superpowers/SKILL.md"
  printf '</EXTREMELY_IMPORTANT>\n'
} > plugins/software-development/hooks/payload.md
grep -n 'brainstorming' plugins/software-development/hooks/payload.md
```

Expected:

```text
27:**Before entering plan mode:** if you haven't already brainstormed, invoke the brainstorming skill first.
35:- "Let's build X" → software-development:brainstorming first, then implementation skills.
```

(Line numbers are offset by the 5-line frame head; upstream's line 22 and line 30.)

- [ ] **Step 4: Write hooks.json and the hook script**

`plugins/software-development/hooks/hooks.json` (spec §8, verbatim):

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

`plugins/software-development/hooks/session-start`:

```bash
#!/usr/bin/env bash
# SessionStart hook for the software-development plugin.
#
# Reads hooks/payload.md (next to this script) and prints it as the
# additionalContext of a SessionStart envelope. Claude Code documents this
# envelope and Codex requires it, so one output serves both harnesses.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
payload="$(cat "${SCRIPT_DIR}/payload.md")"

# JSON-escape with bash parameter substitution: one pass per character class.
# Backslash first, so later passes do not double-escape it.
escape_for_json() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  # Remaining C0 controls (RFC 8259 section 7): U+0001-U+0008, U+000B, U+000C,
  # U+000E-U+001F. NUL cannot occur in a bash string; \n \r \t are handled above.
  local i byte esc
  for i in 1 2 3 4 5 6 7 8 11 12 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31; do
    printf -v byte "\\$(printf '%03o' "$i")"
    printf -v esc '\\u%04x' "$i"
    s="${s//"$byte"/$esc}"
  done
  printf '%s' "$s"
}

# printf rather than a heredoc: bash 5.3+ heredocs can hang inside hooks
# (https://github.com/obra/superpowers/issues/571).
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' \
  "$(escape_for_json "$payload")"
```

```bash
chmod +x plugins/software-development/hooks/session-start
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `tests/run.sh`
Expected: `hook: payload exact, envelope round-trips, wiring correct, control characters escaped`, `json: 6 files well-formed`, seven `PASS` lines, exit 0.

- [ ] **Step 6: Commit**

```bash
git add plugins/software-development/hooks tests/test-hook.sh
git commit -m "Add the SessionStart hook with upstream's using-superpowers payload

The payload is upstream's text inside upstream's frame with one edit: the
superpowers:brainstorming reference now names software-development:brainstorming.
The script emits the hookSpecificOutput envelope that both harnesses read.
A test regenerates the payload from the pinned checkout and diffs it.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 7: Codex marketplace manifest

**Files:**
- Create: `.agents/plugins/marketplace.json`
- Create: `README.md` (repository root)
- Create: `tests/test-codex-marketplace.sh`

**Interfaces:**
- Consumes: `tests/lib.sh` (`REPO_ROOT`, `MARKETPLACE`, `fail`); both `.codex-plugin/plugin.json` files.
- Produces: Codex marketplace `eranroseman` exposing `software-development@eranroseman` and `sensemaking@eranroseman`.

- [ ] **Step 1: Write the failing test**

`tests/test-codex-marketplace.sh`:

```bash
#!/usr/bin/env bash
# The Codex marketplace must expose exactly the two local plugins, point each
# at a directory that carries a matching Codex manifest, and agree with the
# Claude marketplace on names. superpowers has no Codex entry: it arrives by
# symlink because Codex cannot subset a plugin's skills.
. "$(dirname "$0")/lib.sh"

M="$REPO_ROOT/.agents/plugins/marketplace.json"
[ -f "$M" ] || fail "missing $M"

[ "$(jq -r '.name' "$M")" = "eranroseman" ] || fail "marketplace name"
[ "$(jq -r '.interface.displayName' "$M")" = "Eran Roseman" ] || fail "displayName"
[ "$(jq '.plugins | length' "$M")" -eq 2 ] || fail "expected exactly 2 plugins"

for i in 0 1; do
  name="$(jq -r ".plugins[$i].name" "$M")"
  [ "$(jq -r ".plugins[$i].source.source" "$M")" = "local" ] || fail "$name: source.source must be local"
  path="$(jq -r ".plugins[$i].source.path" "$M")"
  manifest="$REPO_ROOT/$path/.codex-plugin/plugin.json"
  [ -f "$manifest" ] || fail "$name: $path has no .codex-plugin/plugin.json"
  [ "$(jq -r '.name' "$manifest")" = "$name" ] || fail "$name: manifest name differs"
  [ "$(jq -c ".plugins[$i].policy" "$M")" = '{"installation":"AVAILABLE","authentication":"ON_INSTALL"}' ] || fail "$name: policy"
  jq -e ".plugins[$i].category | type==\"string\" and length>0" "$M" >/dev/null || fail "$name: category"
done

if jq -e '.plugins[] | select(.name == "superpowers")' "$M" >/dev/null; then
  fail "superpowers must not have a Codex entry"
fi

diff <(jq -r '.plugins[] | select(.source | type == "string") | .name' "$MARKETPLACE" | sort) \
     <(jq -r '.plugins[].name' "$M" | sort) \
  || fail "Claude and Codex marketplaces disagree on the local plugins"

echo "codex-marketplace: 2 local plugins, manifests match, no superpowers entry"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/test-codex-marketplace.sh`
Expected: `FAIL: missing /…/.agents/plugins/marketplace.json`, exit 1.

- [ ] **Step 3: Write the Codex marketplace (spec §5.2, verbatim)**

`.agents/plugins/marketplace.json`:

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

- [ ] **Step 4: Write the repository README**

The `software-development` plugin README points here for the Codex symlink recipe.

`README.md`:

```markdown
# software-development

A plugin marketplace for Claude Code and Codex, named `eranroseman`. It hosts:

- `software-development`: the glue plugin. obra/superpowers' `brainstorming`
  skill vendored with a narrowed description, plus a SessionStart hook.
  Depends on the two entries below.
- `sensemaking`: skills shared with `research-vault`, starting with
  `rethink-audit`.
- `superpowers`: obra/superpowers taken straight from upstream at a pinned
  commit, 13 of its 14 skills. `brainstorming` is the one left out. This entry
  is Claude Code only; Codex gets the same skills by symlink (below).

## Claude Code

    claude plugin marketplace add eranroseman/software-development
    claude plugin install software-development@eranroseman

That one install pulls in `sensemaking` and the curated `superpowers`.

## Codex

Codex has no dependency concept and cannot subset a plugin's skills, so the
two local plugins install explicitly and `superpowers` arrives by symlink
from a clone pinned to the same commit:

    codex plugin marketplace add https://github.com/eranroseman/software-development.git
    codex plugin add software-development@eranroseman
    codex plugin add sensemaking@eranroseman

    REPO=/path/to/this/checkout
    SHA="$(jq -r '.plugins[] | select(.name == "superpowers") | .source.sha' "$REPO/.claude-plugin/marketplace.json")"
    CLONE=~/.local/share/software-development/upstream/superpowers
    git clone https://github.com/obra/superpowers.git "$CLONE" && git -C "$CLONE" checkout "$SHA"
    for s in $(jq -r '.plugins[] | select(.name == "superpowers") | .skills[]' "$REPO/.claude-plugin/marketplace.json" | sed 's#^\./##'); do
      [ -e ~/.codex/skills/"$s" ] && { echo "ALREADY EXISTS: ~/.codex/skills/$s"; continue; }
      ln -s "$CLONE/skills/$s" ~/.codex/skills/"$s"
    done

The 13 names have one source of truth: the `superpowers` entry in
`.claude-plugin/marketplace.json`.

## Checks

`tests/run.sh` runs every static check: manifest schema on both harnesses,
the upstream pin, vendored-skill drift, hook output. CI runs the same script.

## Design

`docs/superpowers/specs/2026-09-04-software-development-layout-and-tracer-design.md`.
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `tests/run.sh`
Expected: `codex-marketplace: 2 local plugins, manifests match, no superpowers entry`, `json: 7 files well-formed`, eight `PASS` lines, exit 0.

- [ ] **Step 6: Commit**

```bash
git add .agents/plugins/marketplace.json README.md tests/test-codex-marketplace.sh
git commit -m "Add the eranroseman Codex marketplace and the repository README

Two local plugins. superpowers has no Codex entry because Codex cannot
subset a plugin's skills directory; it arrives by symlink from a clone at
the same pinned sha. The README carries the recipe.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 8: CI workflow, push, and merge

**Files:**
- Create: `.github/workflows/validate.yml`

**Interfaces:**
- Consumes: `tests/run.sh`; the `CODEX_PLUGIN_VALIDATOR` contract from Task 2.
- Produces: a green `validate` check on every push and pull request; `main` containing everything above, which Tasks 9 and 10 install from GitHub.

- [ ] **Step 1: Rehearse the CI environment locally**

The workflow will fetch the Codex validator from openai/codex instead of `~/.codex`. Prove the fetched copy behaves like the local one before writing the workflow:

```bash
D="$(mktemp -d)"
for f in validate_plugin.py identifier_validation.py; do
  curl -sfL "https://raw.githubusercontent.com/openai/codex/f3f6922519fa38487c8250c2b8a670a39a2cf9ff/codex-rs/skills/src/assets/samples/plugin-creator/scripts/$f" -o "$D/$f"
done
md5sum "$D/validate_plugin.py" ~/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py
CODEX_PLUGIN_VALIDATOR="$D/validate_plugin.py" tests/run.sh
```

Expected: both md5 lines read `57d8f21fd3416e97c624f46aa090868f`; eight `PASS` lines, exit 0.

- [ ] **Step 2: Write the workflow**

`.github/workflows/validate.yml`:

```yaml
name: validate

on:
  push:
  pull_request:

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 22

      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      # `claude plugin validate` needs no login or onboarding: verified
      # 2026-09-04 by running it with an empty HOME. Pinned to the version the
      # design was measured against.
      - name: Install Claude Code CLI
        run: npm install -g @anthropic-ai/claude-code@2.1.220

      # Codex ships validate_plugin.py inside the CLI's system skills, which a
      # fresh runner does not have. The same two files live in openai/codex
      # (Apache-2.0); fetch them at a pinned sha. md5 matched the local copy
      # on 2026-09-04: 57d8f21fd3416e97c624f46aa090868f.
      - name: Fetch the Codex plugin validator
        run: |
          pip install pyyaml
          mkdir -p "$RUNNER_TEMP/codex-validator"
          for f in validate_plugin.py identifier_validation.py; do
            curl -sfL "https://raw.githubusercontent.com/openai/codex/f3f6922519fa38487c8250c2b8a670a39a2cf9ff/codex-rs/skills/src/assets/samples/plugin-creator/scripts/$f" \
              -o "$RUNNER_TEMP/codex-validator/$f"
          done
          echo "CODEX_PLUGIN_VALIDATOR=$RUNNER_TEMP/codex-validator/validate_plugin.py" >> "$GITHUB_ENV"

      - name: Run static checks
        run: tests/run.sh
```

`jq` and `git` are preinstalled on `ubuntu-latest`.

- [ ] **Step 3: Validate the YAML and commit**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/validate.yml')); print('yaml ok')"
git add .github/workflows/validate.yml
git commit -m "Run the static checks in GitHub Actions

Installs Claude Code at the measured version, fetches Codex's plugin
validator from openai/codex at a pinned sha, and runs tests/run.sh.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

- [ ] **Step 4: Push the branch and watch CI**

The branch push exists only to get a CI run on the exact commits before `main` moves; the repository's git policy (AGENTS.md, "Git") is to merge locally and push `main` in the same motion, not to open a pull request.

```bash
git push -u origin tracer-bullet
until id="$(gh run list --branch tracer-bullet --limit 1 --json databaseId --jq '.[0].databaseId')" && [ -n "$id" ]; do sleep 5; done
gh run watch --exit-status "$id"
```

Expected: the `validate` job completes and `gh run watch` exits 0. If it fails, read `gh run view "$id" --log-failed` and fix the workflow; do not weaken a test to make CI pass.

- [ ] **Step 5: Merge to main and push in one motion**

Integrate with `superpowers:finishing-a-development-branch`; the merge itself is:

```bash
git switch main
git merge --ff-only tracer-bullet && git push origin main
git push origin --delete tracer-bullet && git branch -d tracer-bullet
until id="$(gh run list --branch main --limit 1 --json databaseId,headSha --jq '.[0] | select(.headSha == "'"$(git rev-parse HEAD)"'") | .databaseId')" && [ -n "$id" ]; do sleep 5; done
gh run watch --exit-status "$id"
```

Expected: `main` carries every commit above, the branch is gone locally and on origin, and `main`'s own `validate` run exits 0.

---

### Task 9: Cutover on Claude Code and gates G1, G3, G5

> **Stop and confirm with the user before this task.** It uninstalls the `superpowers` plugin the current Claude Code session may be running on, edits `~/.claude/settings.json` and `~/.claude/CLAUDE.md`, and is run from a terminal outside Claude Code, followed by a restart. The executing agent presents these commands to the user and waits for the reported output; it must not run them through its own Bash tool, because the session it runs in is the one being changed underneath it. Prerequisite: Task 8 merged to `main` on GitHub.

**Files:**
- Modify: `~/.claude/settings.json` (delete `skillOverrides.grilling`)
- Modify: `~/.claude/CLAUDE.md` (delete the paragraph documenting that override)
- Modify: `~/harness-backup/claude/CLAUDE.md`, `~/harness-backup/claude/settings.json` (refresh copies)

**Interfaces:**
- Consumes: `main` on GitHub.
- Produces: `software-development@eranroseman`, `sensemaking@eranroseman`, `superpowers@eranroseman` installed at user scope; `superpowers@superpowers-dev` gone at both scopes; recorded G1/G3/G5 outcomes for Task 11.

- [ ] **Step 1: Record the rollback data**

```bash
mkdir -p ~/cutover-2026-09-04
claude plugin marketplace list > ~/cutover-2026-09-04/marketplaces.before.txt
cp ~/.claude/plugins/installed_plugins.json ~/cutover-2026-09-04/installed_plugins.before.json
cp ~/.claude/plugins/known_marketplaces.json ~/cutover-2026-09-04/known_marketplaces.before.json
cp ~/.claude/settings.json ~/cutover-2026-09-04/settings.before.json
cp ~/.claude/CLAUDE.md ~/cutover-2026-09-04/CLAUDE.before.md
grep -A1 superpowers-dev ~/cutover-2026-09-04/marketplaces.before.txt
```

Expected: `Source: GitHub (obra/superpowers)`. Rollback is `claude plugin marketplace add obra/superpowers` (the marketplace is named `superpowers-dev` by its own manifest) then `claude plugin install superpowers@superpowers-dev` at user scope and, from `/home/eranr/memoria-vault`, at project scope, plus restoring the four copied files.

- [ ] **Step 2: Uninstall the old plugin at both scopes (spec §10.1 steps 1 to 2)**

```bash
claude plugin uninstall superpowers@superpowers-dev
(cd /home/eranr/memoria-vault && claude plugin uninstall superpowers@superpowers-dev --scope project)
python3 -c "
import json; d=json.load(open('$HOME/.claude/plugins/installed_plugins.json'))
print([k for k in d.get('plugins', d) if 'superpowers@superpowers-dev' in k])"
python3 -c "
import json; d=json.load(open('$HOME/.claude/settings.json'))
print('STALE enabledPlugins key' if 'superpowers@superpowers-dev' in d.get('enabledPlugins', {}) else 'enabledPlugins clean')"
```

Expected: `[]` and `enabledPlugins clean`. If the second line reports a stale key, remove it:

```bash
python3 - <<'EOF'
import json, pathlib
p = pathlib.Path.home() / ".claude/settings.json"
d = json.loads(p.read_text())
d.get("enabledPlugins", {}).pop("superpowers@superpowers-dev", None)
p.write_text(json.dumps(d, indent=2) + "\n")
EOF
```

- [ ] **Step 3: Add the marketplace and install (spec §10.1 steps 3 to 4)**

```bash
claude plugin marketplace add eranroseman/software-development
claude plugin install software-development@eranroseman
claude plugin list
```

Expected: the list shows `software-development@eranroseman`, `sensemaking@eranroseman`, and `superpowers@eranroseman`, all enabled at user scope. The two dependencies were pulled in by the one install.

- [ ] **Step 4: Remove the grilling mute (spec §10.1 step 5)**

```bash
python3 - <<'EOF'
import json, pathlib
p = pathlib.Path.home() / ".claude/settings.json"
d = json.loads(p.read_text())
d.get("skillOverrides", {}).pop("grilling", None)
if d.get("skillOverrides") == {}:
    del d["skillOverrides"]
p.write_text(json.dumps(d, indent=2) + "\n")
print("skillOverrides:", d.get("skillOverrides"))
EOF
```

Expected: `skillOverrides: None`.

In `~/.claude/CLAUDE.md`, under `**Grilling.**`, delete this paragraph (keep the routing paragraph above it):

```markdown
Backed by `skillOverrides: {"grilling": "name-only"}` in `settings.json` —
description stripped so free-form requests have little to match, invocability kept
so `triage`'s nested call still works. The bare name stays visible; the rule above
closes that gap. Keep this policy in `settings.json`, never in the vendored
`SKILL.md` — a skill update overwrites that file, silently, and harness-backup
does not cover it.
```

Then refresh the harness-backup copies (its README's refresh block) and commit there:

```bash
cd ~/harness-backup
cp ~/.claude/CLAUDE.md ~/.claude/settings.json claude/
cp ~/.codex/AGENTS.md ~/.codex/config.toml codex/
cp ~/.agents/.skill-lock.json agents/
git status --short
git add -A && git commit -m "Drop the grilling skillOverrides mute; brainstorming's narrowed description replaces it

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
cd -
```

Expected: `git status --short` lists `claude/CLAUDE.md` and `claude/settings.json` (and, if Task 10 ran first, `codex/config.toml`).

- [ ] **Step 5: Gate G1, Claude catalog (static half)**

```bash
claude plugin details superpowers@eranroseman
claude plugin details software-development@eranroseman
claude plugin details sensemaking@eranroseman
```

Expected: `superpowers@eranroseman` lists 13 skills and no `brainstorming`; `software-development@eranroseman` lists one skill (`brainstorming`) and one SessionStart hook; `sensemaking@eranroseman` lists `rethink-audit`. Record the three inventories.

- [ ] **Step 6: Gates G1 (session half), G3 and G5, in a fresh session**

Restart Claude Code (quit every running instance first, so the removed plugin's hook cannot linger). Start an interactive `claude` session in any directory and ask, verbatim:

1. `From your available skills list, print every namespaced skill name (one containing a colon) that contains "brainstorming" or "rethink-audit" or ends with ":writing-plans". Names only, one per line, nothing else.`
   Expected, G1: exactly `software-development:brainstorming`, `sensemaking:rethink-audit`, `superpowers:writing-plans`; no `superpowers:brainstorming`. A bare `rethink-audit` also exists on Claude (the harness-backup symlink at `~/.claude/skills/rethink-audit`); it is the same duplicate Task 10 Step 6 records for Codex and is not a G1 failure.
2. `Count how many times the exact line "You have superpowers." appears in your system context. Reply with the number only.`
   Expected, G3 startup: `1`. (`0` means the hook did not run; `2` means the old plugin's injection lingers.)

Then, still in that session:

1. Type `/clear`, then ask the same "You have superpowers." count question. Expected: `1`.
2. Type `/compact`, then ask it again. Expected: `1`.
3. Type `/brainstorming` and confirm it resolves (the skill loads and opens with its classification step). Ask: "Which skill did you just load, by its full namespaced name, and what does its description begin with?" Expected: `software-development:brainstorming`, "Design front door of the superpowers spine". That is G5's first half.
4. G5 second half: the vendored skill's terminal handoff is a bare-name mention (`writing-plans`, seven places in `SKILL.md`). Ask: "If brainstorming's terminal step invokes the writing-plans skill, which namespaced skill would the Skill tool resolve that to?" Expected: `superpowers:writing-plans`, and it is the only `writing-plans` in the list.

Record each answer verbatim for Task 11. If G1 fails, the fallback is the fork route (spec §10.2); if G3 or G5 fails, it is a defect to fix in place before Task 10.

---

### Task 10: Cutover on Codex and gates G2, G4

> **Stop and confirm with the user before this task.** It removes `superpowers@superpowers-dev` from Codex, edits `~/.codex/config.toml`, and creates 13 symlinks under `~/.codex/skills/`. As in Task 9, the executing agent presents the commands and the in-session checks to the user and records the reported results. Prerequisite: Task 9 done.

**Files:**
- Modify: `~/.codex/config.toml` (marketplace removed, plugins added, hook trust recorded by Codex)
- Create: `~/.local/share/software-development/upstream/superpowers` (clone at the pinned sha)
- Create: 13 symlinks `~/.codex/skills/<name>` → that clone's `skills/<name>`

**Interfaces:**
- Consumes: `main` on GitHub; the 13-name list in `.claude-plugin/marketplace.json`.
- Produces: `software-development@eranroseman` and `sensemaking@eranroseman` installed on Codex; 13 bare superpowers skills reachable as `$<name>`; recorded G2/G4 outcomes for Task 11.

- [ ] **Step 1: Record rollback data and remove the old plugin (spec §10.1 Codex step 1)**

```bash
cp ~/.codex/config.toml ~/cutover-2026-09-04/codex-config.before.toml
codex plugin remove superpowers@superpowers-dev
codex plugin marketplace remove superpowers-dev
grep -n 'superpowers-dev' ~/.codex/config.toml || echo "no superpowers-dev entries remain"
```

Expected: `no superpowers-dev entries remain`. Rollback: `codex plugin marketplace add /home/eranr/.claude/plugins/marketplaces/superpowers-dev` then `codex plugin add superpowers@superpowers-dev` (that directory exists only while the Claude marketplace `superpowers-dev` is still registered, which is why Task 11 removes it last).

- [ ] **Step 2: Install our plugins (spec §9.1)**

```bash
codex plugin marketplace add https://github.com/eranroseman/software-development.git
codex plugin add software-development@eranroseman
codex plugin add sensemaking@eranroseman
codex plugin list | grep -i 'eranroseman'
grep -n 'eranroseman' ~/.codex/config.toml
```

Expected: both plugins listed as installed; `config.toml` has `[marketplaces.eranroseman]` with `source_type = "git"`, `[plugins."software-development@eranroseman"]` and `[plugins."sensemaking@eranroseman"]` with `enabled = true`. Note whether `codex plugin add software-development@eranroseman` prompted to trust a hook; that is the first G4 observation.

- [ ] **Step 3: Clone upstream at the pinned sha and link the 13 skills (spec §9.2)**

The list comes from the marketplace file so there is one source of truth:

```bash
REPO=/home/eranr/software-development
SHA="$(jq -r '.plugins[] | select(.name == "superpowers") | .source.sha' "$REPO/.claude-plugin/marketplace.json")"
CLONE=~/.local/share/software-development/upstream/superpowers
mkdir -p "$(dirname "$CLONE")"
git clone -q https://github.com/obra/superpowers.git "$CLONE"
git -C "$CLONE" checkout -q "$SHA"
for s in $(jq -r '.plugins[] | select(.name == "superpowers") | .skills[]' "$REPO/.claude-plugin/marketplace.json" | sed 's#^\./##'); do
  [ -e ~/.codex/skills/"$s" ] && { echo "ALREADY EXISTS: ~/.codex/skills/$s"; continue; }
  ln -s "$CLONE/skills/$s" ~/.codex/skills/"$s"
done
ls -l ~/.codex/skills | grep -c "upstream/superpowers/skills"
git -C "$CLONE" rev-parse HEAD
```

Expected: `13`, then the pinned sha. No `ALREADY EXISTS` line; if one appears, that name collides with an existing entry in `~/.codex/skills/` and must be reported, not overwritten.

- [ ] **Step 4: Gate G4, Codex hook**

```bash
grep -n 'software-development@eranroseman' ~/.codex/config.toml
```

Expected if the fallback loads: a `[hooks.state."software-development@eranroseman:hooks/hooks.json:session_start:0:0"]` block with a `trusted_hash`. Then start `codex` and ask: "Count how many times the exact line 'You have superpowers.' appears in your context. Reply with the number only." Expected `1` if the hook ran, `0` if Codex ignored it. Record the outcome either way; both are valid inputs to sub-project 3.

- [ ] **Step 5: Gate G2, Codex names**

In a `codex` session:

1. Type `$writing-plans` and confirm the skill loads from the symlink (it opens with "I'm using the writing-plans skill"). Ask: "Which file did that skill load from? Print the absolute path." Expected: a path under `~/.local/share/software-development/upstream/superpowers/skills/writing-plans/`.
2. Give an SDD-shaped prompt: "Use the subagent-driven-development skill to plan how you would implement a one-task plan. Do not implement; describe which skills you would invoke and by what name." Expected: the model reaches `superpowers:test-driven-development` in the skill body and resolves it to the bare `test-driven-development` (or names it and continues) rather than stalling on a missing `superpowers:` catalog entry.

Record the observed behaviour. If G2 fails, apply the recorded fallback: remove the 13 symlinks, then `codex plugin marketplace add https://github.com/obra/superpowers.git --ref v6.3.0` and `codex plugin add superpowers@superpowers`, and record that `brainstorming` now exists twice on Codex.

- [ ] **Step 6: Note the `rethink-audit` duplicate**

`~/.codex/skills/rethink-audit` is an existing symlink into `~/.claude/skills/` (the harness-backup route). After Step 2, Codex also has `sensemaking:rethink-audit`. Record that both exist; removing the symlink belongs to sub-project 6 (harness-backup retirement), not to this tracer.

- [ ] **Step 7: Refresh harness-backup**

```bash
cd ~/harness-backup
cp ~/.codex/AGENTS.md ~/.codex/config.toml codex/
git status --short
git add -A && git commit -m "Codex: replace superpowers-dev with the eranroseman marketplace

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
cd -
```

---

### Task 11: Record gate results and finish the cutover

**Files:**
- Modify: `docs/superpowers/specs/2026-09-04-software-development-layout-and-tracer-design.md` (append §14)

**Interfaces:**
- Consumes: the recorded G1 to G5 observations from Tasks 9 and 10.
- Produces: §14 in the spec, the input sub-projects 2, 3 and 4 read; the `superpowers-dev` marketplace removed from Claude Code.

- [ ] **Step 1: Append the results section to the spec**

Fill each cell with what was observed, verbatim where the plan asked for verbatim answers. Keep the table shape.

```markdown
## 14. Tracer results, 2026-09-04

Cutover performed on this machine per §10.1. Claude Code 2.1.220, codex-cli 0.147.0.

| Gate | Result | Evidence |
| --- | --- | --- |
| G1 Claude catalog | PASS / FAIL | `claude plugin details superpowers@eranroseman`: <N> skills, brainstorming absent. Session skill list: <names printed> |
| G2 Codex names | PASS / FAIL | `$writing-plans` loaded from <path>. SDD prompt: <observed behaviour on the `superpowers:test-driven-development` mention> |
| G3 Claude hook | PASS / FAIL | "You have superpowers." count at startup <n>, after `/clear` <n>, after `/compact` <n> |
| G4 Codex hook | LOADED / IGNORED | `[hooks.state]` entry <present/absent>; in-session count <n>; trust prompt <shown/not shown> |
| G5 Front door | PASS / FAIL | `/brainstorming` resolved to <name>; description begins "<text>"; `writing-plans` resolves to <name> |

Observations carried to later sub-projects:

- `rethink-audit` exists twice on Codex (bare symlink from harness-backup, and `sensemaking:rethink-audit`). Sub-project 6.
- <anything else seen during cutover>
```

- [ ] **Step 2: Remove the old marketplace (spec §10.1 step 6), only if every gate passed or has a recorded fallback applied**

The user runs this from a terminal, and runs it last: Task 10's Codex rollback path re-adds the marketplace from `~/.claude/plugins/marketplaces/superpowers-dev`, which this command deletes.

```bash
claude plugin marketplace remove superpowers-dev
claude plugin marketplace list | grep -c superpowers-dev || echo "superpowers-dev removed"
```

Expected: `superpowers-dev removed`.

- [ ] **Step 3: Commit and push**

```bash
git add docs/superpowers/specs
git commit -m "Record tracer bullet gate results

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
git push origin main
```

- [ ] **Step 4: Clean up the rollback snapshots once the results are committed**

```bash
rm -rf ~/cutover-2026-09-04
```
