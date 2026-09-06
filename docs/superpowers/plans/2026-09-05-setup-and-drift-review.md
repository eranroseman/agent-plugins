# Review record: setup and drift plan, 2026-09-05

Full findings behind the "Corrections from review" section of [the plan](2026-09-05-setup-and-drift.md). Five lenses ran over the plan — spec coverage in both directions, cold executability, whether its factual claims reproduce, the seven deviations, and damage to the machine — followed by an adversarial verification pass on the fourteen highest-severity findings.

**Fourteen confirmed, none refuted.** Duplicates are collapsed below: the annotated-tag defect was found independently by four lenses and the upgrade-verb gap by three, so nine distinct entries remain. Each keeps the longest fix text of its group.

Not every fix here has been applied to the plan. The two blockers and the twelve summaries are in the plan's own corrections section; this file is the detail an executor needs when applying them.

---

### BLOCKER :: Task 6, Step 3 (`ensure_claude`, plan lines 1525-1549); consumed by Task 13, Step 2 (lines 2655-2662)
lenses: coverage, danger (2 finding(s))

ISSUE: Task 6 Step 3's `ensure_claude` gives the Claude half only one apply verb — `claude plugin install software-development@eranroseman -y --scope user` — and `claude plugin update` appears nowhere in the plan. Measured on claude 2.1.261 against both a directory-source and a github-source marketplace: `install` on an already-installed plugin prints "already installed", exits 0, and leaves the old version on disk regardless of what the refreshed catalog declares; only `claude plugin update <plugin>@<marketplace>` moves it, and update does not cascade to dependencies. The plan's evidence bullet (line 41) measured only a fresh install in an empty scratch HOME, which is the one case where install is the right verb.

On this machine (installed 0.3.0, plan declares 0.4.0), Task 13 Step 2 therefore prints a false `DID: installed software-development@eranroseman`, then `FAIL: software-development@eranroseman is 0.3.0, declared 0.4.0`; the `--- re-checking ---` pass exits 1 and Step 8's `Expected: 0.4.0` gate never opens, leaving Steps 8-13 unreachable and the machine converged on everything except the plugin. Nothing in the plan can detect this: the CI e2e job always starts from an empty HOME, and `tests/test-doctor-faults.sh` seeds installed_plugins.json with the declared versions on purpose. The shipped engine consequently cannot do the job spec §9 step 2 assigns it — re-running `bin/setup` from the refreshed clone as the Claude update path whenever auto-update is off — for any machine with an older version installed, and the same gap makes the `superpowers@eranroseman` version check (lines 1553-1560) unrepairable after any `bin/bump-superpowers` run. 

FIX: Three edits, all inside Task 6.

1. Task 6 Step 3 — split the apply branch by installed state, and report `did` from the re-read rather than from exit status (update exits 0 when it decides nothing needs moving, so exit 0 is not evidence the version changed):

```bash
  installed_sd="$(installed_version software-development)"
  if [ "$installed_sd" != "$want" ] && applying; then
    if [ -z "$installed_sd" ]; then
      # Adding is a clean no-op on re-run, but only add when the marketplace is
      # unknown: an existing entry may point at a different source than ours.
      if ! jq -e '.eranroseman' "$KNOWN_MARKETPLACES" >/dev/null 2>&1; then
        if claude plugin marketplace add "$MARKETPLACE_SOURCE" >/dev/null 2>&1; then
          did "added the eranroseman marketplace from $MARKETPLACE_SOURCE"
        else
          bad "claude plugin marketplace add $MARKETPLACE_SOURCE failed"
          return
        fi
      fi
      # --scope user, never --scope project: project scope writes a checked-in
      # .claude/settings.json carrying enabledPlugins and extraKnownMarketplaces.
      if claude plugin install software-development@eranroseman -y --scope user >/dev/null 2>&1; then
        did "installed software-development@eranroseman (with sensemaking and superpowers)"
      else
        bad "claude plugin install software-development@eranroseman failed"
      fi
    else
      # install is a no-op on an already-installed plugin: it prints "already
      # installed", exits 0, and leaves the old version on disk (measured
      # 2026-09-05 on claude 2.1.261, both directory- and github-source
      # marketplaces). update is the only verb that moves it, and it exits 0
      # when it decides nothing needs moving, so the re-read below is what
      # reports success.
      claude plugin update software-development@eranroseman >/dev/null 2>&1 \
        || bad "claude plugin update software-development@eranroseman failed"
      if [ "$(installed_version software-development)" = "$want" ]; then
        did "updated software-development@eranroseman from $installed_sd to $want"
      fi
    fi
  fi
```

The existing re-read and `ok`/`bad` block below it stays as written and still delivers the verdict.

2. Task 6 Step 3 — give the `superpowers` check the same repair, since `bin/bump-superpowers` moves its declared `version` and update does not cascade from the parent. Replace the tail of that check with:

```bash
  have="$(installed_version superpowers)"
  want="$(jq -r '.plugins[] | select(.name == "superpowers") | .version' "$MARKETPLACE")"
  if [ "$have" != "$want" ] && applying; then
    claude plugin update superpowers@eranroseman >/dev/null 2>&1 \
      || bad "claude plugin update superpowers@eranroseman failed"
    have="$(installed_version superpowers)"
    [ "$have" = "$want" ] && did "updated superpowers@eranroseman to $want"
  fi
  if [ "$have" = "$want" ]; then
    ok "superpowers@eranroseman $want installed"
  else
    bad "superpowers@eranroseman is ${have:-not installed}, declared $want"
  fi
```

Leave `sensemaking` alone: its check compares no version, so there is nothing to repair against, and adding one is new scope.

3. Task 6 Step 1 — add an upgrade-path assertion, because the empty-HOME CI job structurally cannot reach it. It must create a *genuine* older install, not a hand-edited `version` field: seeding only that field leaves the CLI reading the real version from the install path, `update` answers "already at the latest version", and the test fails for the wrong reason (measured). The offline recipe, seconds not minutes: copy the repo into a temp dir, lower `plugins/software-development/.claude-plugin/plugin.json` to a fake older version, `claude plugin marketplace add "$TMP"` and `claude plugin install software-development@eranroseman -y --scope user` into `$H`, restore the declared version, `claude plugin marketplace update eranroseman`, then run `bin/setup` with `SD_MARKETPLACE_SOURCE="$TMP"` and assert `installed_plugins.json` now carries the declared version and setup exits 0. Gate it on `command -v claude` the way `tests/test-doctor-faults.sh` already gates its repair half.

Also worth one clause in Task 13 Step 2 or the Global Constraints, so the reason survives the plan: install is the fresh-machine verb and update is the update verb, and the spec's "clean no-op on re-run" (§7.3) means install does no harm, not that it converges. 
---

### BLOCKER :: Task 7, Step 3 (`ensure_codex`)
lenses: coverage (1 finding(s))

ISSUE: Task 7 Step 3's `ensure_codex` compares presence only, so `codex plugin add` — which is Codex's only upgrade mechanism — never runs on an already-installed plugin. Verified on codex-cli 0.147.0: `codex plugin --help` has no update verb; `codex plugin list` reports the version from `$CODEX_HOME/plugins/cache/<mkt>/<plugin>/<version>`, i.e. the installed version, not the catalog's (bumping a marketplace source 0.2.0 → 0.3.0 left list reading 0.2.0 until a re-add); and `codex plugin add` re-run is idempotent and exit-0, confirmed against `https://github.com/eranroseman/agent-plugins.git` in a scratch CODEX_HOME. The reference machine holds `~/.codex/plugins/cache/eranroseman/software-development/0.3.0`, so after the plan's 0.3.0 → 0.4.0 bump, Task 13 Step 2 prints `OK: codex plugin software-development present` while Codex stays on 0.3.0 and never receives the vendored `setup-matt-pocock-skills` from Task 2. This contradicts spec §9 step 3 ("It re-adds both Codex plugins, since Codex has no update verb") and leaves §11's "installed plugin version matching the manifest" with no Codex half. The plan's Self-Review maps §9 to README prose only, so the gap is unrecorded, and no gate can catch it: S1 uses a fresh scratch CODEX_HOME (always the add path), CI has no codex, S4 is typed on Claude, and Step 8's version gate reads Claude's installed_plugins.json. 

FIX: In Task 7, replace `codex_plugin_installed` with a version read and make the loop version-gated. This is parity with `ensure_claude`, which also acts only on mismatch, so it is not a new deviation from §9's unconditional "re-adds"; the literal alternative is to hoist `codex plugin add` out of the branch and run it on every apply, which I verified is idempotent.

    codex_plugin_version() {
      # $1 plugin name; empty when not installed. `codex plugin list --json`
      # reports the *installed* version, read from $CODEX_HOME/plugins/cache,
      # never config.toml (§7.4). `codex plugin add` is Codex's only upgrade
      # verb, so presence alone is not convergence (§9 step 3).
      printf '%s' "$CODEX_LIST" \
        | jq -r --arg k "$1@eranroseman" '.installed[] | select(.pluginId == $k) | .version'
    }

    ensure_codex() {
      local p want got
      if ! have codex; then
        skip "codex is not on PATH: the Codex half is unchecked and unapplied"
        return
      fi
      CODEX_LIST="$(codex plugin list --json 2>/dev/null)" || { bad "codex plugin list failed"; return; }

      for p in software-development sensemaking; do
        want="$(jq -r '.version' "$REPO_ROOT/plugins/$p/.claude-plugin/plugin.json")"
        [ -n "$want" ] && [ "$want" != null ] || { bad "could not read the declared version of $p"; continue; }
        got="$(codex_plugin_version "$p")"
        if [ "$got" != "$want" ] && applying; then
          if codex plugin marketplace list 2>/dev/null | grep -q '^eranroseman'; then
            # Never re-run `marketplace add`: it prints "already added". upgrade
            # is a true no-op when nothing moved, and covers §9 step 1 when the
            # human skipped it.
            codex plugin marketplace upgrade >/dev/null 2>&1 \
              || bad "codex plugin marketplace upgrade failed"
          elif codex plugin marketplace add "$CODEX_MARKETPLACE_SOURCE" >/dev/null 2>&1; then
            did "added the eranroseman marketplace to Codex"
          else
            bad "codex plugin marketplace add failed"
            continue
          fi
          # Codex has no dependency concept, so both plugins are named
          # explicitly, and no update verb, so add is also the upgrade.
          if codex plugin add "$p@eranroseman" >/dev/null 2>&1; then
            did "installed codex plugin $p $want"
          else
            bad "codex plugin add $p@eranroseman failed"
            continue
          fi
          CODEX_LIST="$(codex plugin list --json 2>/dev/null)"
          got="$(codex_plugin_version "$p")"
        fi
        if [ "$got" = "$want" ]; then
          ok "codex plugin $p $want installed"
        else
          bad "codex plugin $p is ${got:-not installed}, declared $want"
        fi
      done
    }

Three one-line companions: (1) update Task 7's opening measurement note — the engine now reads `codex plugin list --json`, whose shape is `{"installed":[{"pluginId","version","installed","enabled",...}],"available":[]}`, rather than the table (the table's version is the fourth whitespace field, since `installed, enabled` splits in two, and is empty when not installed); (2) Task 7 Step 5's expectation becomes `FAIL: codex plugin software-development is not installed, declared 0.4.0`; (3) Task 13 Step 2 adds `codex plugin marketplace upgrade` beside `claude plugin marketplace update eranroseman`, per §9 step 1, and Step 8's pre-flight verification should also read `codex plugin list --json` for 0.4.0 before the global files are emptied. 
---

### BLOCKER :: Task 2, Steps 1/3/4/8 (and Global Constraints, "Declared pins")
lenses: coverage, deviations, executability, ground-truth (5 finding(s))

ISSUE: `mattpocock/skills` `v1.2.3` is an ANNOTATED tag: `835450ef244ab7335f75d95b83e7d979eae22a6d` is the tag object; the commit it peels to is `6acc160e4e0cd062dbbbd7a1b26ae92855edf07e`. The plan declares the tag-object sha as if it were the commit (line 18) and then uses it in three places that need different objects:

(a) Line 279, `[ "$(git -C "$d" rev-parse HEAD)" = "$SHA" ] || fail "checkout HEAD != $SHA"`, compares a commit against a tag object and fails unconditionally. Reproduced verbatim: `FAIL: checkout HEAD != 835450ef244ab7335f75d95b83e7d979eae22a6d`, exit 1. `tests/test-vendored-scaffolder.sh` can never go green, so Task 2 Step 11 (line 594) cannot happen and the branch stalls.

(b) Lines 280-281, `git ls-remote --exit-code --tags … "refs/tags/$REF" | grep -q "$SHA"`, needs the tag-object sha — the unpeeled refspec prints only that row. So the two assertions require two different shas; correcting (a) alone breaks (b).

(c) Lines 389 (provenance header) and 507-508 (LICENSE) both read "commit 835450ef…", naming a tag object as a commit in a shipped legal notice.

Additionally, and independent of the sha: line 355's `grep -q "at tag $REF, commit $SHA" … LICENSE` can never match, because Step 8's block wraps between `commit` and the sha (lines 507-508). `grep` is line-based; verified exit 1. The test therefore has two unconditional failures, not one.

Plan line 41 claims this test "was run against it: it passes." That claim is false and is what will mislead the executor. 

FIX: Six edits, all in Task 2 plus one Global Constraints line.

1. Line 269 — carry both objects:
```
REF="v1.2.3"
SHA="6acc160e4e0cd062dbbbd7a1b26ae92855edf07e"      # the commit v1.2.3 peels to
TAG_OBJ="835450ef244ab7335f75d95b83e7d979eae22a6d"  # v1.2.3 is annotated; ls-remote prints this
```
Line 279 then passes unchanged. (Verified: fetching `6acc160e…` directly by sha works — `fetch_commit_status=0`, `HEAD=6acc160e…`.)

2. Lines 280-281 — grep the tag object, not the commit:
```
git ls-remote --exit-code --tags https://github.com/mattpocock/skills.git \
  "refs/tags/$REF" | grep -q "$TAG_OBJ" || fail "tag $REF no longer names $TAG_OBJ"
```
(Alternative, if you prefer one variable: query `"refs/tags/$REF^{}"` and grep `$SHA` — verified it prints `6acc160e…  refs/tags/v1.2.3^{}` and exits 0. Then drop `TAG_OBJ`, but note nothing would then detect the tag being re-pointed to a different tag object over the same commit.)

3. Line 373 (Step 3) — `git -C "$d" fetch -q --depth 1 origin 6acc160e4e0cd062dbbbd7a1b26ae92855edf07e`.

4. Line 389 (Step 4 header) — `…at tag v1.2.3, commit 6acc160e4e0cd062dbbbd7a1b26ae92855edf07e`.

5. Lines 507-508 (Step 8 LICENSE) — fix the sha AND un-wrap so line 355's grep can match on one line:
```
skills/setup-matt-pocock-skills/ is vendored from
https://github.com/mattpocock/skills (directory
skills/engineering/setup-matt-pocock-skills/,
at tag v1.2.3, commit 6acc160e4e0cd062dbbbd7a1b26ae92855edf07e) and remains
under its original license:
```
(Or leave the wrap and relax line 355 to `grep -q "commit $SHA"` — but then nothing checks the tag name in the LICENSE.)

6. Line 18 (Global Constraints, "Declared pins") — `mattpocock/skills` at tag `v1.2.3` (tag object `835450ef…`, commit `6acc160e4e0cd062dbbbd7a1b26ae92855edf07e`), `obra/superpowers-developing-for-claude-code` at tag `v0.3.1` (tag object `aa900d59…`, commit `74afe935da49efe782907e837a27ce618498099a`). Both are annotated tags; the shas previously given were tag objects.

Also correct line 41's "it passes" claim for the drift test, since that assertion is what would stop an executor from suspecting the plan. No change is needed in Task 1 (fetches `refs/tags/$ref`) or Task 11 (compares tag names) — both are correct on annotated tags. 
---

### MINOR :: Task 10, Step 3 (README "Install" section) vs Task 4 Step 3 (`main`) and Task 5 Step 3 (`ensure_links`)
lenses: coverage (1 finding(s))

ISSUE: Task 10 Step 3's README puts the thirteen `~/.agents/skills` symlinks inside the Codex-gated paragraph (plan line 2174) and closes it with "When it is not, that half is reported as skipped and nothing else changes" — but `main` calls `ensure_links` ungated (plan line 1083) and `ensure_links` (plan line 1340) has no `have codex` test, unlike `ensure_codex` which does. Two of the plan's own artifacts require the ungated form: the `tests/test-doctor-faults.sh` repair pass runs with `PATH="$BIN"` built from a tool list that excludes `codex` and then asserts the links were repaired, and the Task 6 CI e2e job runs setup and doctor on a codex-free runner and requires doctor to exit clean. So a Claude-only user reads that nothing else changes and gets thirteen symlinks. Same stale claim appears a second time inside the plan at line 2681, in Task 13's gate S1 narration, where it is now factually wrong about what CI reaches. The README also contradicts itself: line 2180 already lists the symlinks harness-neutrally. Nothing catches this — the Task 10 README↔`--help` test compares fenced code blocks only, never prose, and `usage()` is already neutral. The spec is not on the README's side as the original finding claimed: §7.3 states the symlink step ungated and separate from the Codex step, and §11 bullet 3 says all five doctor faults (three of them link faults) are detected "with neither CLI present"; only §11 bullet 2 and §13 S1's "namely" clause say otherwise. The plan resolved that spec inconsistency in favour of §7.3 and never said so. 

FIX: Three edits, all in the plan; no code, no test, no gate changes.

1. Plan lines 2174-2177 (Task 10 Step 3, README `## Install`). Cut the link clause out of the Codex paragraph:
   "Codex is optional. When `codex` is on `PATH` the same run adds the Codex marketplace and installs both local plugins there. When it is not, that half is reported as skipped and nothing else changes."
   Keep the rationale by folding it into the neutral sentence at line 2180:
   "What the run leaves behind: both plugins installed on each harness present, a clone of obra/superpowers at the pinned sha, thirteen symlinks into it under `~/.agents/skills` — Codex's documented user skill root, created whether or not Codex is present — and the declared skills.sh set installed at its declared refs."

2. Plan line 2681 (Task 13 Step 3, gate S1). "namely the Codex install and the thirteen symlinks" → "namely the Codex install, and Codex's own resolution of the thirteen symlinks" (the manual run is still the only place §7.3's namespacing claim can be checked, because that needs the binary; the links' creation and verification are CI's).

3. Add to "Deviations from the spec, decided while planning":
   "**D8. The thirteen symlinks are created on every machine, not only where `codex` is present.** §7.3 states the symlink step ungated and separate from the Codex step, and §11's fault bullet says all five faults are filesystem and git state detectable "with neither CLI present"; §11's CI bullet and §13 S1 nevertheless place the symlinks beyond a runner's reach. The engine follows §7.3: `ensure_links` has no binary gate, so the CI end-to-end job creates and verifies the links and `tests/test-doctor-faults.sh` repairs them on a codex-free `PATH`. Veto: gate `ensure_links` on `have codex` in both modes, and drop the link assertions from the fault fixture's repair pass and from CI's doctor-clean step — which removes link coverage from the automated halves of both S1 and S2."

Explicitly do not gate `ensure_links` on `have codex`: it breaks the automated half of gate S1, guts the repair half of gate S2, and contradicts spec §7.3. 
---

### IMPORTANT :: Task 13, Steps 2 and 7 (gate S3)
lenses: coverage (1 finding(s))

ISSUE: Task 13 sequences gate S3 so that its own experiment is consumed before it can be observed. Step 2 (plan lines 2655-2662) installs 0.4.0 by two explicit commands - `claude plugin marketplace update eranroseman` and `bin/setup`, whose `ensure_claude` (plan line 1515ff) runs `claude plugin install software-development@eranroseman -y --scope user` - and Step 8 (line 2744) depends on that having happened. Step 7 (line 2740) only turns auto-update on afterwards, then asserts "The 0.3.0 -> 0.4.0 bump is the natural experiment", which by then is false; the same paragraph has already quietly retargeted the gate at "a later published release". Spec §13 (line 276) and §16 (line 325) both name the 0.3.0 -> 0.4.0 bump specifically, and §16 makes S3 on this release the sub-project's one remaining open question. Under the plan's ordering S3 can only be recorded pending in Step 12's table, against a release that does not exist, and the plan records no deviation for that - while the contradictory sentence invites the worse outcome of recording S3 as observed on evidence an explicit command produced. Live state confirms the setup: 0.3.0 installed, `extraKnownMarketplaces.eranroseman` carries no `autoUpdate` key, and the source is `github: eranroseman/agent-plugins`. 

FIX: Reorder Task 13 so the toggle precedes the bump, and delete the false sentence. No engine change; setup still never writes `autoUpdate`.

1. Insert a new Step 1 before the current "Merge and push":
   "Step 1: Turn auto-update on, before the release exists. In `/plugin` under Marketplaces, select `eranroseman` and turn auto-update on. Note the date. Confirm the starting point:
   ```bash
   jq -r '.extraKnownMarketplaces.eranroseman.autoUpdate' ~/.claude/settings.json   # true
   jq -r '.plugins[\"software-development@eranroseman\"][0].version' ~/.claude/plugins/installed_plugins.json   # 0.3.0
   ```
   This is the setup for gate S3; the toggle has no effect until 0.4.0 is pushed."

2. Keep the current merge-and-push step as Step 2, then insert the observation window as Step 3, before the current Step 2:
   "Step 3: Gate S3 - observe the bump. Start a fresh Claude session (`claude -p 'reply with the single word ok'` is enough) and re-read the installed version after the documented delay of up to ten minutes:
   ```bash
   jq -r '.plugins[\"software-development@eranroseman\"][0].version' ~/.claude/plugins/installed_plugins.json
   ```
   `0.4.0` with no update command typed since Step 1 is S3 passing. Still `0.3.0` after the window is S3 failing: §9's 'nothing to run' becomes step 1 for Claude as well and the README says so. Record the reading and both timestamps either way; nothing in the engine changes on either branch, since it never writes the key. If this environment cannot start a session that triggers the background refresh, record that as a deviation rather than substituting a later release."

3. Leave the current Step 2 exactly as written, now as Step 4, retitled "Refresh the marketplace clone and confirm 0.4.0 is installed". It is the fallback on either branch: `ensure_claude` finds 0.4.0 already present and prints `OK:`, or installs it itself. Step 8's `Only after Step 2 shows 0.4.0 installed` becomes `Only after Step 4 shows 0.4.0 installed`.

4. Delete the old Step 7 gate block (plan lines 2731-2740) entirely - the toggle moved to Step 1 and the reading to Step 3 - and with it the sentences "a later published release" and "The 0.3.0 -> 0.4.0 bump is the natural experiment".

5. Change Step 12's table row to:
   `| S3 Auto-update | [pass/fail: the version read after the window, the date auto-update was enabled, and the push and read timestamps] |`
   and drop "Gate S3's outcome, if it is still pending when the branch closes" from Step 14, which no longer applies. 
---

### MINOR :: Task 9, Step 3 (`report_only`, item 3) and Task 4 Step 3 (`main`)
lenses: coverage (1 finding(s))

ISSUE: Plan Task 9 Step 3 places the stale-marketplace-clone check as item 3 inside `report_only`, which Task 4's `main` (plan line 1087) calls last, while spec §7.1 states in bold that it is "the doctor's first check". The departure is real but is a diagnosability and spec-conformance gap, not a damage-prevention one: because `ensure_claude` never runs `claude plugin marketplace update` (the command would delete the running script's own directory), a stale clone applies stale pins in apply mode no matter where the check sits, and the finding's own non-aborting fix does not change that. On a machine converged by the same stale script, `declared_sha` comes from the same stale manifest, so every other check reports OK and the staleness FAIL is the only failure in the report — it is neither buried nor misleading. The substantive defect is that the plan drops a bolded spec clause without recording it in its Deviations section, which already carries D3 and D6 about this same check. 

FIX: Either conform or record the departure; both are cheap.

Preferred (conform, matching the finding's shape): split the staleness block into its own function and call it first.
- Task 4 Step 3: add `ensure_fresh_clone() { :; }` to the stub list beside `report_only()`, and put `ensure_fresh_clone` as the first call in `main`, before `ensure_clone`.
- Task 4 Interfaces (plan line 907): update the dispatch list to "`ensure_fresh_clone`, `ensure_clone`, `ensure_links`, `ensure_claude`, `ensure_codex`, `ensure_skills_sh`, `report_only`" and note that Task 9 fills two.
- Task 9 Files bullet (plan line 1933): `Modify: bin/setup (ensure_fresh_clone, report_only)`.
- Task 9 Step 3: move item 3 (plan lines 2012-2033) verbatim into `ensure_fresh_clone`, keeping D3's directory-source skip and the `ls-remote` resolution unchanged; renumber the remaining items 4 to 3 and 5 to 4, and drop `loc`/`source_kind`/`head`/`tip` from `report_only`'s `local` line.
- Self-Review Type consistency (plan line 2857): add `ensure_fresh_clone` to the list of names stubbed in Task 4 and filled in Task 9.
No other edit is needed: `KNOWN_MARKETPLACES` and `skip()` are top-level and assigned before `main "$@"` runs, and Task 9's directory-source test and `tests/test-doctor-faults.sh` both grep for lines rather than order.

Alternative (record the grouping): add one line to the Deviations section — "D8. The stale-clone check runs last, inside `report_only`, not first as §7.1 says. It belongs with the four things the engine describes and never repairs, and the script cannot refresh its own clone mid-run in any case; on a machine converged by the same stale script it is the only FAIL in the report. Veto: hoist it into `ensure_fresh_clone` and call it first in `main`." 
---

### MINOR :: Task 7, Step 3 (variables added near the top of `bin/setup`) vs Global Constraints and Deviation D5
lenses: coverage (1 finding(s))

ISSUE: Task 7, Step 3 introduces a second environment override, `SD_CODEX_MARKETPLACE_SOURCE` (plan line 1738), that the plan's own Global Constraints line 20 ("One environment override exists, `SD_MARKETPLACE_SOURCE`") and Deviation D5 line 58 ("nothing else in the engine is overridable") both state does not exist. Nothing in the plan reads or sets it: the CI end-to-end job sets only `SD_MARKETPLACE_SOURCE` (line 1601), no test sets either, gate S1 sets neither, and `bin/setup --help` documents neither. It is dead configuration surface that falsifies a constraint the plan declares binding on every task. One precision on the original finding: the deviation record is not silent about the variable — line 2857's "Type consistency" note discloses `CODEX_MARKETPLACE_SOURCE` as deliberately distinct from `MARKETPLACE_SOURCE`. What no part of the plan discloses is the `SD_`-prefixed environment override wrapping it, which is the thing lines 20 and 58 claim is unique. 

FIX: Drop the indirection at plan line 1738 (Task 7, Step 3, the "Add beside the other variables near the top of `bin/setup`" block), so it reads:

CODEX_MARKETPLACE_SOURCE="https://github.com/eranroseman/agent-plugins.git"

Lines 20 and 58 then need no edit, and the plan's "nothing else in the engine is overridable" becomes true as written. This cannot change the `bash -n` or `shellcheck` results the plan reports for the assembled 475-line script: the variable is still read at line 1710, so no SC2034 appears, and no other construct changes. Prefer this over amending D5 and line 20 to name a second override, which costs more text and forces the plan to state a purpose for a knob no task, test, or CI job reads. 
---

### MINOR :: Task 5, Step 2
lenses: executability (1 finding(s))

ISSUE: docs/superpowers/plans/2026-09-05-setup-and-drift.md:1265 (Task 5, Step 2) predicts a failure the run cannot produce. The Task 5 fixture `git init`s `$CLONE` and adds a seed commit, so Task 4's skeleton `ensure_clone` finds `$CLONE_DIR/.git` and prints `OK: pinned clone exists`; every other check is still a `{ :; }` stub, so `FAILURES` stays 0 and the doctor prints `clean` and exits 0. The test dies at the earlier guard `[ "$status" -eq 1 ]` with `FAIL: doctor exited 0 on a machine with four seeded faults`, never reaching the pattern loop. Both the predicted message (`FAIL: doctor did not report: dangling link`) and the parenthetical's reasoning ("the stub `ensure_clone` from Task 4 already reports a missing clone") are wrong; the fixture creates the clone rather than omitting it. Verified by extracting Task 4's `bin/setup`/`bin/doctor` and Task 5's test verbatim into /tmp/rev5/repo and running them. 

FIX: Replace line 1265 of docs/superpowers/plans/2026-09-05-setup-and-drift.md:

- Expected: `FAIL: doctor did not report: dangling link`, exit 1. (The stub `ensure_clone` from Task 4 already reports a missing clone, but nothing looks at links.)
+ Expected: `FAIL: doctor exited 0 on a machine with four seeded faults`, exit 1. (The fixture creates the clone, so Task 4's skeleton `ensure_clone` reports `OK: pinned clone exists`; every other check is still a stub, so nothing is counted as a failure and the doctor exits 0 before any of the four faults is looked at.)

Nothing else changes: the fixture, the assertions and Step 3's implementation are all correct as written. 
---

### MINOR :: Task 5, Step 1 (tests/test-doctor-faults.sh, repair half)
lenses: executability (1 finding(s))

ISSUE: Task 5, Step 1, plan lines 1223-1224: the restricted-PATH tool list `for t in git jq node npx claude sed awk grep find date readlink basename dirname rm mv ln mkdir cp cat` omits `bash`. `bin/setup`'s apply mode ends with `"$REPO_ROOT/bin/setup" --check` (line 1091), executed as a file, so its `#!/usr/bin/env bash` shebang must resolve `bash` on PATH. The run at line 1250 sets `PATH="$BIN"`, so the re-check dies with `/usr/bin/env: 'bash': No such file or directory` and setup exits 127 instead of 1. This violates the fixture's own comment at lines 1219-1221 ("Every external the engine runs has to be here"), and it is an oversight rather than a choice: Task 4's test comment at ~line 943 spells out this exact 127 mechanism for the outer invocation, which line 1250 guards with `/bin/bash`, while the inner re-exec was missed. The consequence is narrower than "S2 is unverified": every `ensure_*` runs before the re-exec, so the four local repairs complete and the filesystem assertions genuinely observe them. What is lost is only the re-check half of setup's contract inside this test — and that is separately covered by Task 6's CI job (lines 1599-1606, `bash bin/setup` in apply mode, full PATH, unswallowed exit status, every push) and Task 13's manual gates. The practical cost is a confusing red herring for anyone who removes the output suppression while debugging this test. 

FIX: At plan line 1223, add `bash` to the tool list:

```bash
for t in bash git jq node npx claude sed awk grep find date readlink basename dirname \
         rm mv ln mkdir cp cat; do
```

That is the whole root-cause fix, and Task 8 leaves the list alone so it propagates to the five-fault form. It changes nothing observable on its own, though, because line 1250 still discards output and status. To make the fix confirmable — recommended as a follow-on, not required — replace line 1250 with the plan's own capture idiom (Global Constraint line 31, already used at line 1195), dropping `|| true` only because the capture form replaces it:

```bash
if out="$(env HOME="$H" CODEX_HOME="$H/.codex" PATH="$BIN" /bin/bash "$SETUP" 2>&1)"; then status=0; else status=$?; fi
[ "$status" -eq 1 ] || fail "bin/setup exited $status; the re-check must run and report the unrepairable clone"
printf '%s\n' "$out" | grep -q -- '--- re-checking ---' || fail "bin/setup did not re-check after applying"
```

Verified in /tmp/pr5: with `bash` in the list this passes; with `bash` removed it fails loudly with `FAIL: bin/setup exited 127; the re-check must run and report the unrepairable clone`. Nothing in `tests/` is shellchecked (the lint assertion at plan line 926 covers `bin/` only), and `out`/`status` are already declared earlier in the same test, so neither addition affects lint. 
---

