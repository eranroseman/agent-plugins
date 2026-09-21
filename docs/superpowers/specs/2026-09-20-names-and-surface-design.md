# Names the reader already knows, and a doctor that reports everything

**Status:** design, 2026-09-20, awaiting the maintainer's review. Milestones 3 (_Names, layout and README ownership_) and 4 (_Setup, doctor and watch surface_) of the tracker, in one spec, two plans and one branch, `names-and-surface`. §3 lists every decision with its source. This spec binds the two plans written from it and nothing after them; what must outlive the plans lands in `CONTEXT.md` (§4).
**Scope:** milestone 3: [#26](https://github.com/eranroseman/agent-plugins/issues/26), [#37](https://github.com/eranroseman/agent-plugins/issues/37) (all five items), [#59](https://github.com/eranroseman/agent-plugins/issues/59), plus [#57](https://github.com/eranroseman/agent-plugins/issues/57) as a disposition. Milestone 4: [#6](https://github.com/eranroseman/agent-plugins/issues/6), [#13](https://github.com/eranroseman/agent-plugins/issues/13), [#14](https://github.com/eranroseman/agent-plugins/issues/14), [#17](https://github.com/eranroseman/agent-plugins/issues/17), [#22](https://github.com/eranroseman/agent-plugins/issues/22), [#24](https://github.com/eranroseman/agent-plugins/issues/24), [#25](https://github.com/eranroseman/agent-plugins/issues/25), [#44](https://github.com/eranroseman/agent-plugins/issues/44), [#50](https://github.com/eranroseman/agent-plugins/issues/50), [#53](https://github.com/eranroseman/agent-plugins/issues/53), [#54](https://github.com/eranroseman/agent-plugins/issues/54), [#56](https://github.com/eranroseman/agent-plugins/issues/56), [#58](https://github.com/eranroseman/agent-plugins/issues/58), [#61](https://github.com/eranroseman/agent-plugins/issues/61), [#62](https://github.com/eranroseman/agent-plugins/issues/62), [#63](https://github.com/eranroseman/agent-plugins/issues/63), [#64](https://github.com/eranroseman/agent-plugins/issues/64).
**Not in scope:** the roster ([#52](https://github.com/eranroseman/agent-plugins/issues/52), milestone 5) beyond the record shapes that must survive it (§14); devendoring ([#21](https://github.com/eranroseman/agent-plugins/issues/21), milestone 6); the README beyond what #37 names ([#35](https://github.com/eranroseman/agent-plugins/issues/35), milestone 7); adopting any of the fourteen unruled upstream skills.

## 1. Evidence standard

A claim below is a fact only when it rests on one of: the tree at `1dd7362`, read on 2026-09-20; the verification sweep of the same day (twenty issues, one mapping agent and one refuting agent each, then one synthesis; every landed-or-live call checked against the tree, stale line numbers corrected); a primary document read the same day; or a run made the same day in a scratch copy of the checkout. Counts are outputs at `1dd7362`, not targets; each plan re-measures on the branch. §22 lists each mechanism claim with its source.

The sweep ran with an earlier premise, that plans are frozen and specs are maintained. The maintainer overrode both during the run (§4). Three of its recommendations rested on that premise and are struck: excluding `docs/superpowers/` from the reference check, amending the 1-2 spec for its three implementation deviations, and editing a quoted manifest in a spec. Its measurements stand.

## 2. Purpose

Milestone 3 makes the repository say what it means in words a newcomer already knows, moves four files to where a reader looks for them, and ends the root README's habit of restating what other files own. Milestone 4 makes the doctor and the watch report everything they can see, fail when they cannot see, and repair the one class of residue they can prove.

They share one branch because milestone 4 writes new report lines, new test names, new failure text, one new desired-state file and two new manifest keys, and every one of those would otherwise be created under a retired name or in a retired directory. Milestone 3 lands first, a gate, then milestone 4 is planned against the settled tree. Two plans because milestone 4 alone is seventeen issues and about forty findings, larger than milestones 1 and 2 together.

## 3. Decisions

Sources: **M** is the maintainer's answer of 2026-09-20; **S** is the verification sweep of the same day; **T** is a technical choice made by the designer, on the maintainer's instruction that a choice with one best technical answer is not a ruling.

| Question                                        | Decision                                                                                                                                                             | Source |
| ----------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| Packaging                                       | One spec, two plans, one branch; plan B written after gate 1                                                                                                         | M      |
| #37 item 1, who owns the skill inventory        | The root README names no skill. Eliminate, not guard                                                                                                                 | M      |
| #26, which substitution rows land               | All of them, as tabled; `harness` at durable sites only                                                                                                              | M      |
| #26, the two hook file names                    | By content: `using-superpowers.md`, `working-rules.md`                                                                                                               | M      |
| #26, `upstream/` and `bin/`                     | Root `skills.json`; `scripts/` for what CI and the maintainer run. Churn is an investment, not a cost                                                                | M      |
| Specs and plans                                 | Historical artifacts. Content frozen; vocabulary and paths kept current so a current reader can follow them. A spec binds the plan written from it and nothing after | M      |
| What binds                                      | `CONTEXT.md` and ADRs only; this repository has no ADRs, so `CONTEXT.md`                                                                                             | M      |
| #59, the backticked-path check                  | Adopted, over every owned markdown file including `docs/superpowers/`, with a history tier there (§8)                                                                | M, T   |
| #25, orphaned plugin caches                     | Eliminate: `bin/setup` deletes under four positive guards, the fourth a mtime floor; the doctor fails until then                                                     | M      |
| Substitutions in identifiers, flags, file names | Yes, all sites, so the `_Avoid_` list can be a test rather than a rule                                                                                               | T, S   |
| `harness` replacement                           | Name the CLI where one is meant; _agent CLI_ only where the sentence is generic                                                                                      | T, S   |
| `bin/format`                                    | Moves to `scripts/` by the audience rule it postdates                                                                                                                | T, S   |
| #24, the freshness signal                       | The doctor reads the run history over the public API; OK under 48 hours, FAIL otherwise, SKIP without `curl`. #24 closes, title corrected                            | T      |
| #62, both suspect kills                         | Fix both: the anchored pattern; a shared pathspec derivation plus a behavioural test                                                                                 | T      |
| #61 M3 and the bash probe                       | Floor 4.4, refused by `BASH_VERSINFO` in `bin/setup` and `tests/run.sh`                                                                                              | T      |
| #61 M6, M11, M12, M14                           | Literals kept plus a `tools.txt` shape assertion; first-match `awk`; hoist the `rm`; fix both PATH lists                                                             | T      |
| #61 M7                                          | One `(pattern, guard)` table in `tests/lib.sh`, landing in plan A                                                                                                    | T, S   |
| #61 M2, M18                                     | Declined: a spec's content is frozen                                                                                                                                 | M      |
| #64                                             | Declined: the launcher's retention bounds the accumulation                                                                                                           | T, S   |
| #56, where the vendored pins live               | Root `vendored.json`; the engine never reads it                                                                                                                      | T      |
| #53, the not-adopted record                     | Two new per-source keys in `skills.json`, the third bucket empty until #52                                                                                           | T, S   |
| #6's remaining scope, the action pins           | Bumped once now; then the watch reads `uses:` lines from the workflows, no copied record. `ubuntu-latest` stays                                                      | T, S   |
| #37, milestone                                  | All five items here; the tracker's placement wins over the 1-2 spec's                                                                                                | T      |
| #37 item 2, direction                           | Tagline and marketplace `description` drafted once, one string                                                                                                       | T, S   |
| Other-repository paths in prose                 | Written `owner/repo:path`; the check classifies by shape                                                                                                             | T      |
| Plugin versions                                 | Software-dev minor, sensemaking patch, one commit at the end of plan B                                                                                               | T      |

## 4. What binds, and where conventions live

A spec specifies what a plan implements. Its decisions are inputs to that plan; once the plan has run, the spec is a historical artifact beside it. The 1-2 spec called a spec a _maintained record_ that moves when the tree moves. That reading is retired. Both kinds of document keep the current vocabulary and current paths, edited in place, so that a reader today can follow them; their content is not amended to match later code.

Two consequences. Anything in this design meant to hold after plan B closes is written into `CONTEXT.md`, whose entries are listed in §5.5; this spec's §21 records declines so the workspace can close, and nothing in it is a rule. And #61's M2 and M18, which ask the 1-2 spec to be corrected about what a tool did and what the branch built, are declined on the issue: the account is wrong, and it is the account.

## 5. Vocabulary

### 5.1 The substitutions

Every row of #26's table lands: _payload_ becomes **additional context**; _installer_ as a person becomes **user** or no noun; _carrier_ becomes **instruction file**; _declaration_ as a noun becomes **desired state**; _authored_ becomes **first-party**; _gated_ as a skill property becomes **user-invocable only**, and the word leaves its other senses too — the prerequisite sense in `bin/setup`'s pool comment, `tests/test-setup-doctor.sh`'s three header comments and `tests/test-doctor-duplicates.sh`'s pool comment becomes _conditional on_, and `consistency-audit/SKILL.md`'s _deleted rather than gated_ becomes _deleted rather than guarded_, so §5.4 needs no sense exception; _curated_ and _curation_ become **subset entry**; _routing_ becomes **skill selection**. _Vendored_, _pin_, _concern_ and _marketplace clone_ keep their words.

The rows apply everywhere: prose, comments, help text, report and failure text, and identifiers. `curated_entries()` becomes `subset_entries()`; `tests/test-curated-writing-clearly-and-concisely.sh` becomes `tests/test-subset-writing-clearly-and-concisely.sh`, and the watch's template that prints that name into a drift issue follows; `--emit-payload` becomes `--emit-using-superpowers`; `claude_gated` and `codex_gated` become `claude_user_invocable` and `codex_user_invocable`; `payload_tmp` and `local harness` take the words their lines now use. Measured at HEAD outside the plans: `payload` 148 hits, 67 of them in code and READMEs; `curated` 92 hits in 19 files; `declaration` 34 in 8; `gated` 31 lines in 12 files, of which the skill sense is 10 in 4; `installer` 10 in 6; `routing` 10 in 2; `carrier` 9 in 4; `authored` 32 in 14, 11 of them in 9 files outside `docs/superpowers/`.

Identifiers rename for one reason: once no owned file carries an old word, the `_Avoid_` list is enforceable by a test (§5.4). An identifier left behind would need an exception, and an exception is a rule.

### 5.2 `harness`

Where a sentence means one CLI, it names it: Claude Code or Codex. _Agent CLI_ appears only where the sentence is generic: at HEAD, `## Why`'s first paragraph and the _What the run leaves behind_ line in the README; the _neither harness_ comment, the `report_duplicates` comment block and `report_pool`'s first parameter in `bin/setup`; and the generic comments and failure text in `test-doctor-duplicates.sh`, `test-doctor-silence.sh`, `test-plugin-skills.sh` and `test-vendored-diagnosing-bugs.sh`. Plan A re-measures the durable set with `grep -n -i harness`, and every other site names Claude Code or Codex. `harness-backup` and `knowledge-harness` stay wherever they are a repository's name. The one `harness` inside `plugins/software-dev/hooks/using-superpowers.md` is upstream's byte-locked text and stays until #21.

### 5.3 Two coupled pairs

`setup-repository/SKILL.md` carries _carrier_ in a sentence that `tests/test-vendored-scaffolder.sh` uses as a region delimiter; `finding-duplicate-functions/SKILL.md` carries _authored here_ in a line `tests/test-vendored-duplicates.sh` asserts. Each pair changes in one commit or its drift test fails.

### 5.4 `tests/test-vocabulary.sh`

Each `_Avoid_:` line in `CONTEXT.md` ends in a comma-separated list of bare surface forms and nothing else; a sense qualifier belongs in the definition sentence, and every inflection that must go is listed (`declaration, declarations`; `harness, harnesses`; `installer, installers`; `payload, payloads`; `curated, curation`). The test extracts the lists with `sed -n 's/.*_Avoid_: *//p'`, splits on commas, and for each form runs `grep -n -i -E '(^|[^[:alnum:]-])FORM([^[:alnum:]-]|$)'` over `checked()`'s list with no pathspec — shell, JSON and YAML in scope — minus `CONTEXT.md` and the documents named below; a multi-word form is one pattern; fenced blocks and code spans are scanned like prose. It fails naming file, line and form. `_` is not a word character to this pattern, so `payload_tmp` and `claude_gated` are hits; `-` is, so `harness-backup` and `knowledge-harness` are not, and there is no exception list. The price, stated: a hyphen-joined old word (`--emit-payload`, `payload-rules.md`) is invisible to this test and is held by its rename and by the file tests alone.

Because a sense qualifier is unenforceable, a banned word goes in every sense inside the scanned set: the README's _a separate installer with its own lockfile_ becomes _skills.sh with its own lockfile_, `PROVENANCE.md`'s _what no installer reproduces_ becomes _what no tool reproduces_, and the _maintained record_ comment in `tests/test-links-resolve.sh` is rewritten in §8's pass.

Under `docs/superpowers/` the higher rungs were tried: a prose-only scan (fences and code spans stripped, as §8 strips them) fires on any document whose subject is the old word — this spec's §5.1 and §5.5 first — and the older specs quote measurements in running text. So documents there dated on or before 2026-09-20 are excluded, and the test scans every spec and plan dated after this one, which holds the vocabulary for new documents at no cost.

Red first by mutation, as every guard here: run once against a scratch copy of the tree with one `_Avoid_` form seeded into a checked file, the result cited in the plan; then green on the branch. An old word surviving the renames is red on the tree itself and reopens the rename step.

### 5.5 `CONTEXT.md`

Written last in plan A, after every rename, in the shape of the reference implementation: one paragraph saying what the repository is, then Language, Relationships, Flagged ambiguities. It is the output of the renames, not a glossary.

**Contested entries**, winner named and losers under `_Avoid_`:

- **additional context** — what the SessionStart hook prints; Claude Code's own name for it. _Avoid_: payload, payloads.
- **user** — whoever runs `bin/setup`, or no noun; the tool that installs skills is named, `skills.sh`. _Avoid_: installer, installers.
- **instruction file** — `CLAUDE.md`, `AGENTS.md`, what both CLIs call them. _Avoid_: carrier.
- **desired state** — what `skills.json` and the marketplace manifest declare and `bin/setup` converges to. The verb _declare_ is a different word and stays. _Avoid_: declaration, declarations.
- **first-party** — a skill written here. _Avoid_: authored.
- **user-invocable only** — Claude Code's own `skillOverrides` value. _Avoid_: gated.
- **subset entry** — a marketplace entry taking part of an upstream at a pinned commit. _Avoid_: curated, curation.
- **skill selection** — how an agent picks a skill. _Avoid_: routing.
- **Claude Code, Codex, agent CLI** — the two, or the generic. _Avoid_: harness, harnesses.
- **historical artifact** — a spec once every plan written from it has run; a plan once executed. Vocabulary and paths kept current; content frozen. _Avoid_: maintained record, working paper.
- **vendored, forked** — a vendored tree is upstream's at a pinned commit, held byte-identical except for enumerated regions, updated by re-vendoring; a forked tree is first-party, holds named fragments to upstream, updated by editing. The test is which way edits flow. _Trees with a drift test_ is the superset, and is the formatter-exclusion class.

**Kept, defined inline where first used:** marketplace clone, pin, concern; _vendored_ is kept with its own entry above.

**Leading words**, pinned so they appear identically everywhere: ladder and rung, gate, drift, spine, front door, admission, tracer bullet. Plan A audits each across `AGENTS.md`, the hook files, `bin/`, `scripts/`, `tests/` and the READMEs; a word used two ways is unified, a word used nowhere is dropped from the list.

**Conventions:** `bin/` holds what a user runs, `scripts/` what CI and the maintainer run; a path in another repository is written `owner/repo:path`.

## 6. Moves and file names

- **`upstream/skills.json` → `skills.json`.** `upstream/` holds nothing else and goes. `upstream` is git's word for the repository you forked from; the file is a dependency manifest, and manifests sit at the root. Readers at HEAD: `bin/setup`, the watch, five tests, and one silence fixture that `mkdir`s the old layout before copying into it. 42 literal references in 13 files outside the plans.
- **`bin/upstream-watch`, `bin/bump-superpowers`, `bin/format` → `scripts/`.** `bin/` keeps `setup` and `doctor`, the two commands the README tells a stranger to type. `bin/format` postdates #26's audience table; by that table it is contributor tooling — named in failing check output, never run by CI (whose gate is `tests/run.sh --no-skip`) or by a user. `cspell.config.yaml` scopes comment-only spelling by the path glob `bin/*`, so the move commit adds `scripts/*` to that override or spelling goes red: reproduced, 20 unknown words. `checked_shell()` selects by shebang and needs no edit. `upstream-watch.yml` names the path twice.
- **`plugins/software-dev/hooks/payload.md` → `using-superpowers.md`; `payload-rules.md` → `working-rules.md`.** The first is upstream superpowers' own session-start text, vendored and byte-pinned; the second already titles itself _working rules_. Sites: the hook script, `scripts/bump-superpowers`' `mktemp` template and messages, the ownership table (§16), `tests/test-hook.sh`, the software-dev README's two `hooks/` lines, and the hook spec, whose §4.2 fence stops being an oracle: `working-rules.md` is the desired state, so `test-hook.sh` drops the §4.2 diff, its `extract_42` helper, the _specs move when the tree moves_ message and the comment calling the spec maintained, and keeps the round-trip and the `superpowers:<name>` checks against `working-rules.md` itself. The fence in the hook spec stays as the quotation it always was, its heading's path updated. The SessionStart output is byte-identical after the rename.
- **`AGENTS.md`'s two lines.** _An installer and a hook payload_ and the dead root `hooks/` are one edit: the words change, the path becomes `plugins/software-dev/hooks/`, and `scripts/` joins `bin/` as a surface a Codex scan covers.
- **Specs and plans.** Every moved path, every renamed file, the retired plugin name `software-development` and every substituted term are edited in all five specs and all six plans, by reviewed diff, not by blind substitution. The boundary is syntactic: inside a fenced block that reproduces tool output, a manifest or a measurement, inside quotation marks, and in a sentence whose subject is the old word itself (a substitution row, an `_Avoid_` entry), every word stays; everywhere else — headings and inline code spans that name an identifier, flag, path or file included — the new word or path is written, and a fenced block that is a command to run has its paths and flags updated, since a current reader runs it. The reviewer classifies each fence, not each word. The words that stay are why §5.4 excludes the documents written before it.

## 7. Root README, manifests, residuals

- **#37 item 1.** `## What it ships` becomes four entries at one line each, saying what each is and who it is for, naming no skill; the only skill-shaped token left is the entry name `writing-clearly-and-concisely`. The inventory lives in the per-plugin READMEs and the manifests. No guard is added, by the ruling: the inventory has no home in the root README to drift in, and a returning skill name is a review finding, not a test. The six stale statements the quality-gates design corrected have no home to go stale in.
- **#37 item 2.** The tagline and the marketplace's top-level `description` are drafted once under the new vocabulary and are one string; the Codex `shortDescription` follows. The SchemaStore schema documents top-level `description`.
- **#37 item 3.** The software-dev README's closing sentence _The design spec in the repository records the evidence_ is deleted; the evidence it points at (upstream removed its own Codex hook in v6.1.0; nothing sits at `hooks/hooks.json`) has been inline in the same paragraph since `a515d4c`.
- **#37 item 4.** A `## Layout` section: an ASCII tree, one comment per top-level path, written after the moves. `bin/` — commands a user runs; `scripts/` — what CI and the maintainer run; `plugins/` — the two plugins; `skills.json`, `vendored.json` — the desired state for skills.sh and the vendored trees; `tests/`; `docs/agents/` — conventions the agents read; `docs/Professional-Editorial-Standards-2024.md` — the editorial reference; `docs/superpowers/` — _historical artifacts: specs and plans as executed; vocabulary and paths current, content frozen_.
- **#37 item 5.** `checked '*.json'` joins the cspell call in `tests/test-spelling.sh`. Whole-file cspell over the eight JSON files reports one word, `Strunk`, which joins the dictionary; the issue's `jq` extraction guarded against noise that is not there. Thirteen user-facing strings are covered.
- **The doctor sentence** in the README is written count-free (_the doctor reports the operator decisions it never makes for you_), so #50 does not rewrite it.
- **#57** is recorded as superseded by item 1: its tables carry thirty skill names.
- **#22 residual.** `codex plugin marketplace upgrade eranroseman` at the three live sites; the fourth, the 2026-09-05 spec's §9 step 1, is frozen content (§4) and keeps the bare form; `tests/test-setup-doctor.sh` holds the README's fenced block to the script's usage text, so README and `bin/setup` move together.
- **#58.** The SchemaStore URL in the live manifest. `claude plugin validate --strict` never fetches it and passes either way.

## 8. The reference check (#59)

`tests/test-links-resolve.sh` keeps its markdown-link half and gains a backticked half, over every owned markdown file, fenced blocks unscanned. A backticked token is a candidate when it contains `/`. A trailing `:N` or `:N-M` is stripped. Resolution tries, in order, the document's directory, the repository root, and each `plugins/*/` root; specs and plans write plugin-relative paths, which a current reader can follow and the three roots resolve — a resolution rule, not an economy; where §6 moves or renames a file, the historical text is edited.

Excluded classes, each printed with its count so a zero is visible:

1. URLs.
2. Tokens beginning `~`, `$`, `/`, `"` or `.../` — home paths, variables, absolute paths, elisions.
3. Tokens containing `<`, `*` or `?` — placeholders and globs.
4. `owner/repo` slugs: two segments, the first not a directory at any root, so `bin/setpu` is still checked.
5. `owner/repo:path` and `owner/repo@ref:path` — the other-repository convention (§5.5). About thirty sites are rewritten to it, among them archify's `scripts/check-update.mjs` and superpowers-lab's `skills/finding-duplicate-functions`.
6. Paths `git check-ignore` accepts — runtime-only directories, classified by the same file that ignores them. `.worktrees/` and `worktrees/` join `.gitignore`: superpowers creates them, `working-rules.md` names them, and `test-hook.sh` round-trips that file byte for byte.
7. A declared absent-by-decision list, two entries at HEAD: `hooks/hooks.json` in the software-dev README, named because it must not exist; `docs/adr/` in `docs/agents/domain.md`, absent by #26's decision.
8. **History tier**, under `docs/superpowers/` only, for a path that resolves at none of the three roots. The test finds the last commit that touched it, `git -C "$REPO_ROOT" log --all -1 --format=%h -- "$root/$path"`, for each root, then reads that commit's `--name-status -M` line for the path. A `D` line means the file was deleted: the path passes, since git history is the archive. An `R` line means the file was moved: the path fails naming its successor, so the tier archives deleted files without excusing a stale name, which is the one class the ruling of §4 targets. No commit at all means the path never existed: a typo, and it fails. Measured: a pathspec on the old path alone makes `git log -M` report `D`, so the rename is read from `git show --name-status -M` of the commit, not from the log.

Everything else fails naming file, line and token. Measured at HEAD with the three roots: 856 tokens resolve; 366 do not, of which 162 are in specs, 165 in plans, and 39 elsewhere, most of those in vendored files outside the checked set. Day-one reds outside `docs/superpowers/`, fixed in the same commit: `AGENTS.md`'s `hooks/`, the two convention sites above, and the two `.gitignore` names. Inside it, the moves and renames of §6 clear the stale paths; the history tier and classes 2 to 5 cover the rest, and the plan measures the residue before the test goes green.

## 9. Gate 1

Full suite green with `tests/results.tsv` cited; CI green on the branch; `test-vocabulary.sh` green; `CONTEXT.md` written, in `checked()`'s list and scanned by the reference check (§8). Plan B is written now, against this tree.

## 10. The doctor's report-only pass

Three issues (#50, #54, #44) add to `report_only`, one 54-line function, and its dead `name` local goes; #17's false OK is in `ensure_claude`, beside the sensemaking read, and lands in the same pass. All of it in the ruled vocabulary, after the guards of §13. The numbered block comments go: the `reported()` bracket is the structure, and the numbers were a stale count; the bracket comment above `reported()` loses its count too (_prints NOTE lines before `report_duplicates`_), since the archify NOTE makes _two_ wrong.

- **#50.** One NOTE for `ARCHIFY_UPDATE_CHECK_DISABLED`, read from the environment and from the `env` map in `~/.claude/settings.json`, three wordings by exact value: `1`, and which source; unset in both, the check is on, the plugin README named, and this script never sets it; any other value, still on, because the checker tests for exactly `1`. `usage()`'s _two things left to you_ becomes count-free. The plugin README's closing sentence about the next rung goes; its paragraph ends at the instruction to set the variable and says `bin/doctor` reports its state. Three fixtures, one per wording: `env -u` for the unset case, hermetic on a maintainer's machine; `=1` in the environment; `=true` in the `env` map of a seeded `settings.json`, hashed before and after to prove the script never writes it.
- **#54.** Every key under `.skills` in `~/.agents/.skill-lock.json` that is not in `.sources[].skills[]` is one NOTE naming skill, `source` and `ref`, worded _not in the skills.sh desired state_ — true after #52 moves nine names to a subset entry, where _not declared_ would not be. None: one line says so. No lockfile: SKIP. A lockfile that `jq` cannot parse: FAIL, never the all-clear. The hand-written block for `setup-matt-pocock-skills` folds into this walk, keeping its `npx skills remove` remedy as that key's message.
- **#44.** One NOTE per CLI, `claude <version>` and, behind `have`, `codex <version>`, so a CLI that renames a verb shows as a fact change before it is a runtime failure. The four stub `claude` and `codex` fixtures answer `--version`.
- **#17's false OK, in `ensure_claude`.** The sensemaking block becomes `if [ -n "$want" ]; then` the existing comparison `else bad "sensemaking version unreadable from plugins/sensemaking/.claude-plugin/plugin.json"; fi`; the subset loop after it runs either way. Two fixtures: an unreadable manifest, and `"version": ""`.

## 11. Residue elimination (#25, #64)

The walk leaves `report_duplicates` for a new `ensure_cache()`, called from `main` after `ensure_codex` (it needs `CODEX_LIST`) with its own `reported` bracket; `report_duplicates`' header drops _Reported, never repaired_ and its comment about the unregistered cache, and `tests/test-doctor-duplicates.sh` repins on the new strings.

In apply mode `ensure_cache` deletes a directory under `~/.claude/plugins/cache/` when all four hold: `known_marketplaces.json` parses as a JSON object; the directory's name is absent from its keys; `installed_plugins.json` parses as a JSON object whose `.plugins` is an object, and no `installPath` in it lies under the directory — so an unreadable registry fails this guard rather than passing it; and the directory's own mtime is more than one hour old (`find "$dir" -maxdepth 0 -mmin +60`). Either registry failing to parse skips the whole walk with one line naming the file, and nothing is deleted. The deletion is a `did` line naming the path. In check mode the same directory is a FAIL naming the four facts, until apply runs. A directory failing a guard is left alone and printed as one NOTE, _left alone: path (the guard that failed)_; it touches neither `FAILURES` nor `UNANSWERED`. `temp_subdir_*.clone` entries — the CLI's scratch clones from git-subdir installs, four on the maintainer's machine today, misreported as marketplaces — pass the same guards; both their `did` line and their FAIL read _scratch clone from a git-subdir install_ in place of _cache for an unregistered marketplace_. Codex: in a run where `codex plugin marketplace list` and `codex plugin list --json` both succeed, the registered marketplace names replace the JSON keys and each listed plugin's `cache/<marketplace>/<name>/<version>` path replaces `installPath`, the mtime guard unchanged; if either command fails, the Codex half prints one SKIP and deletes nothing.

The engine's `aside_path()` and the 2026-09-05 spec's _never delete, move aside_ are for things a user made and might want back — a directory sitting where a symlink should be. A cache the CLI regenerates from a marketplace that no longer exists is not one, and moving it aside keeps the disk cost and adds a pile the walk must skip. The comment at the deletion says so, since the spec does not bind.

Today's guard is on the negative: `jq -e '.[$m]' … || note` fires on an unreadable file and on a `null` entry alike. It inverts.

**#64 is declined.** The launcher keeps its target and two superseded versions; the 486 MB observed at the cutover was three directories, which is that retention working. Recorded on the issue. The retention is a §22 claim with its check.

## 12. Watch freshness (#24)

The cron fires: fourteen scheduled runs since 2026-09-07, all successful, and the workflow reached `main` twelve seconds after the 2026-09-06 slot, so no slot was ever missed. What remains is the issue's second half: an empty `upstream-drift` list means _no drift_ or _nothing checked_, and nothing distinguishes them.

A new function `ensure_watch_fresh()` in `bin/setup`, called from `main` after `ensure_fresh_clone` and before `ensure_clones` so the two network checks sit together, with its own `before=$REPORTED` / `reported` bracket; `bin/doctor` inherits it through `--check`. One request: `GET https://api.github.com/repos/eranroseman/agent-plugins/actions/workflows/upstream-watch.yml/runs?event=schedule&status=completed&per_page=1`. Age is now minus `.workflow_runs[0].created_at`; conclusion is `.workflow_runs[0].conclusion`. OK when age is under 48 hours and conclusion is `success`; FAIL when age is 48 hours or more, the array is empty, or conclusion is anything else, naming `https://github.com/eranroseman/agent-plugins/actions/workflows/upstream-watch.yml`; SKIP through plain `skip`, never `needs` — `curl` is optional the way the Codex half is — when `curl` is absent, the response is not 200 (named), or the body does not parse, so the exit code is untouched and the fixtures, whose PATH lists carry no `curl`, print that SKIP and stay clean. The runner has `curl`, so `validate.yml`'s doctor step inherits this FAIL when the watch is stale; that coupling is wanted, a red e2e being the second place the silence shows. 48 hours because scheduled runs land 4.5 to 6.5 hours after the slot and one missed slot is weak evidence. No token, no artifact, no write permission. FAIL rather than NOTE because a machine converging to pins nobody is watching is a fact about that machine.

Issue #24 closes when this lands, its title corrected by comment. The predecessor's marker code, preserved in the issue, stays there.

## 13. Engine correctness

- **Bash floor 4.4.** `bin/setup` refuses below it by `BASH_VERSINFO` before anything else runs, `tests/run.sh`'s hard gate says 4.4, and the README's _`bash` 4 or later_ under `## Checks` becomes _4.4 or later_ in the same commit. Every distribution shipping below 4.4 is EOL. This removes #61 M3's `set -u` abort on an empty array by removing the version, not by guarding the idiom, and closes the 1-2 spec's open bash probe.
- **M9.** Apply mode's self re-check runs `"$BASH" "$REPO_ROOT/bin/setup" --check`, as `bin/doctor` already does.
- **M13.** Both `subset_entries` loops adopt the capture-and-check idiom `ensure_links` and `ensure_skills_sh` use; a partial `jq` abort is a FAIL naming what was lost, and a fixture with a non-scalar `version` in the second entry proves it.
- **#17, the apply block.** The second `CODEX_LIST` read gets `|| CODEX_LIST=""`. A stateful `codex` stub answers `plugin marketplace list`, `upgrade` or `add`, `plugin add`, then `plugin list --json` with changed output, and drives the apply block once. It lands after #22's named upgrade so the stub expects `eranroseman`. Two more fixtures under a stateful `claude` stub: one seeds a subset entry one version behind so the `update` branch runs, one omits the entry from `installed_plugins.json` so the `install` branch runs; each asserts the `did` line and the re-check's OK.
- **#14, in `scripts/bump-superpowers`.** Its two bare `mktemp` temporaries, the marketplace write and the re-vendored `SKILL.md`, are created beside their destination and registered in `cleanup()`; all five `mktemp` calls, the `mktemp -d` included, get `|| die`. The `[ -n "${1:-}" ] && exit 0 || exit 2` line stays with its comment.
- **#63 item 1.** Both `test-doctor-faults.sh` fixtures assert on `$out` content — the Claude half's own verdict line present or absent as expected — not on an exit status that is already 1.

## 14. Watch and pin records

- **#13 part 2.** A source with no stable tag is `die`, the shape the section's other failure already has; the report is loud or it fails.
- **#56.** A root `vendored.json`, an object keyed by local tree path, two entries at HEAD: `plugins/sensemaking/skills/adhd` and `plugins/software-dev/skills/finding-duplicate-functions`; each value `{repo, branch, sha, upstream_path, kind}` with `kind` one of `vendored` (adhd) or `forked` (finding-duplicate-functions) as §5.5 defines them. `tests/lib.sh` gains `vendored_sha <local-tree>` beside `upstream_sha()`; `brainstorming` and the hook file keep `upstream_sha()` because the marketplace pins them, and the two mattpocock trees keep their literal until #52 (§23). `test-vendored-duplicates.sh` and `test-vendored-adhd.sh` read their sha from it, and the four in-tree records per source — the provenance header at the top of each `SKILL.md`, `PROVENANCE.md`, and the plugin `LICENSE` notice — keep carrying the sha and are asserted equal to it before `fetch_pinned` runs, so a bump that forgets any record fails naming the mismatch whether or not the sha is fetchable. The watch gains a section shaped like its subset-entry one: pinned sha against the branch tip, `DRIFT=1`, a bump line. `bin/setup` never reads the file. The first run reports `adhd` moved, which is the report doing its job; the bump is a separate decision.
- **#53.** Each source in `skills.json` gains `not_adopted`, a list of `{name, reason}`, and `via_subset_entry`, a list of names, empty until #52. `tests/test-skills-pin.sh` asserts, per source, that the set of basenames of the parent directory of every `SKILL.md` in the tree fetched at the declared ref — the derivation the test already uses, the repository root excluded, a duplicate basename itself a failure naming both paths — equals the union of the three buckets and that the buckets are disjoint, failing with the names on each side. Its summary line prints, per source, the declared and not-adopted counts beside the total. The seven blocked names keep their reasons; the fourteen enter with _never evaluated; surfaced by the complement check on 2026-09-16_; `grill-me` with its alias reason. The `$comment` sentence about `setup-matt-pocock-skills` becomes that name's entry. Every reader keeps selecting `.sources[].skills[]`, so the new keys are inert to the engine and to #54's walk. #52's agent adds the subset entry's own complement test.
- **Action pins.** The four actions are bumped once to their current node24 releases, the trailing version comments by hand. Then the watch reads `uses: owner/repo@sha # vX.Y.Z` from the workflow files and reports a sha that is not what the named tag peels to; the workflow file is the desired state, and no copy is kept. `ubuntu-latest` stays: `ubuntu-26.04` fails the pinned actionlint until it learns the label, and `ubuntu-24.04` freezes an image nothing in the suite depends on, since the registry's tools sit ahead of the image's. This closes #6.

## 15. CI

`tests/test-workflows.sh` globs `*.yml` and `*.yaml`; GitHub runs both. `validate.yml`'s comments follow §5. Nothing else changes.

## 16. The ownership derivation

- **M7.** The two parallel arrays in `tests/lib.sh` become one `(pattern, guard)` table. Each guard test reads its own row through a helper, and `test-ownership.sh` asserts every row's guard calls that helper — a guard can no longer be repointed at any file that happens to contain the subject string, which the issue reproduced. The hook file rename is carried inside this redesign, so `using-superpowers.md` is named at one site rather than three, and the comment calling the class _vendored_ becomes _trees with a drift test_. **This lands first in plan A.**
- **M4.** A tracked file absent from the working tree fails `checked_shell()` and the reference check by name. The guard sits after the `head`, outside the `if`, where it is not a no-op. `test-links-resolve.sh`'s quiet skip — `[ -f "$f" ] || continue` before its scan loop — goes the same way: a tracked file absent from the working tree is a FAIL naming it, not a silently smaller scan.
- **M8.** Every `producer | grep -q && fail` in `test-ownership.sh` becomes a here-string over a captured list. Latent at 110 tracked paths, measured live near 450.
- **M17.** The shebang comment drops its count and keeps its argument.

## 17. Runner and fixtures

- **M10.** The runner's `mktemp` gets `|| { printf …; exit 2; }`.
- **M11, M6.** `registry_version` takes the first matching row (`{ if (!found++) v = $2 } END { if (!found) exit 1; print v }`; the issue's first fix was verified broken). A uniqueness and shape assertion over `tests/tools.txt` sits at the registry gate, so a duplicate or mangled row is loud before any test reads it. The five literals in `test-runner.sh` stay: they are the oracle a derived expectation would give up.
- **M12.** `rm -f "$RESULTS"` moves above the flag parse.
- **M1.** `run_case` asserts that the number in `N check(s) failed` equals the count of `FAIL:` lines, on every fixture; `bad` is the only writer of both. The Task-15 note is recorded on #61, not fixed.
- **M14.** Both fixture PATH lists gain `cut` and lose `sed`, `awk`, `find`, `cp`; the comment stays true.
- **M5.** `test-codex-validate.sh` prints a summary line. **M16.** `readlink -f` on the validator before its sibling is hashed.
- **#63 item 2.** `grep -q worktree` and the `superpowers:brainstorming` absence check return beside the round-trip, against `working-rules.md`. **#63 item 3.** The extractor self-test's synthetic README carries a ` ```sh ` fence.

## 18. Formatter and spelling

- **#62 item 2, and M19.** The pathspec lists spelled at five sites become named functions in `tests/lib.sh` that both `scripts/format` and the check tests call, which eliminates the dropped-glob class. M19 is then one edit: the prettier JSON list gains `*.jsonc`, and `.markdownlint-cli2.jsonc` is reformatted once. `tests/test-format-apply.sh`, with `# needs:` the three tools, un-formats copies of one shell, one markdown and one JSON file in a scratch tree, runs `scripts/format`, and asserts the three checks pass; the `exit 0` mutation goes red.
- **#62 item 1.** The hash-comment pattern becomes `/(?<=^|\s)#.*$/gm`, YAML-quoted; `insection` and `nosuchtool` leave the dictionary, since neither is prose.
- **#63 item 4.** No per-file callout for `skills.json`: every checked JSON file is `jq`-read data and formatter-owned alike.
- **M20.** The sensemaking README's `<problem>` continuation is rejoined to its list item so prettier's fixed point keeps it indented; `scripts/format` runs once and the check stays green.

## 19. Dispositions on the tracker

Each is a plan task that comments and closes: #57 superseded by §7; #64 declined with the retention fact; #24 closed with its title corrected; M2, M18 and the Task-15 note declined on #61; #44 item 1 closed on record, the committed review plan carrying the citation; #6 closed on the action bump; #26, #37, #59, #22, #58 and the rest on their commits.

## 20. Sequencing and the two gates

Branch `names-and-surface` from `main`.

**Plan A, milestone 3:**

1. The ownership table (§16, M7), then the hook file rename through it.
2. The moves, one commit each, suite green after each: `skills.json` to the root; `scripts/` with the cspell override; the silence fixture's layout.
3. The term renames, one commit per term, largest first: additional context, subset entry, desired state, then the small rows, then `harness` at durable sites. Specs and plans in each commit, reviewed for quoted words.
4. The reference check (§8): its day-one reds first, then the convention rewrites and the `.gitignore` entry, then green.
5. The README and manifest pass (§7): #37's five items, #22, #58.
6. `CONTEXT.md`, then `test-vocabulary.sh`: red on the seeded mutant, green on the tree.
7. **Gate 1** (§9).

**Plan B, milestone 4**, written after gate 1:

1. Engine correctness (§13): the floor and refusal, M9, M13, the #17 guards, #14. Each guard red first by the mutation its issue names.
2. The report-only pass (§10), residue (§11), freshness (§12), with their fixtures.
3. Watch and records (§14): #13, `vendored.json` with its reader and the drift tests reading it, the `skills.json` buckets and the complement test, the action bump and the `uses:` section.
4. Suite efficacy (§16 remainder, §17, §18) and CI (§15).
5. Dispositions (§19).
6. Version bump: software-dev minor, the hook directory changed; sensemaking patch; one commit.
7. **Gate 2**, the same evidence as gate 1, then merge to `main` and push in the same motion.

Every guard is added red first, by the mutation its issue names, and each plan cites the result file for each green rather than transcribing output. Plan B names functions, sections and anchors, never line numbers: HEAD moved once during the sweep, and plan A moves everything.

## 21. Positions not adopted

Declines, each with its home here so the workspace can close:

- **A heartbeat issue or a committed stamp for the watch** (#24's comment): both copy state the run history already holds, and the stamp needs `contents: write`.
- **NOTE or FAIL for orphaned caches** (#25's two lower rungs): the top rung is available with positive guards.
- **Move-aside for orphaned caches:** §11.
- **A copied record of the action pins** (§14): the workflow file is the desired state.
- **Guarding the empty-array expansion under a 4.0 floor** (#61 M3's first fix): a workaround for a version no shipping distribution has.
- **Deriving the shfmt expectation from the copied registry** (#61 M6): verified to make the test its own oracle.
- **Excluding `docs/superpowers/` from the backticked half** (the sweep's recommendation): superseded by the maintainer's ruling that paths stay current there, and by the history tier.
- **Keeping the hook spec's §4.2 fence as `working-rules.md`'s oracle:** §4; a spec does not bind after its plan.
- **Fixing the Task-15 note** (#61 M1's aside): recorded on the issue; the count assertion of §17 is the fix that matters.
- **Amending historical specs for implementation deviations or wrong attributions** (#61 M2, M18): §4.
- **Editing a spec's quoted manifest for #58:** a URL in a quotation is neither a term nor a path.
- **A doctor line for superseded Claude Code versions** (#64): §11.
- **Two specs:** milestone 4's text must use milestone 3's words and paths; two plans carry the size.
- **Keeping `bin/format` in `bin/`:** it fails the audience rule it postdates.
- **A per-file callout for `skills.json`'s formatter ownership** (#63 item 4): §18.
- **`ubuntu-24.04` or `ubuntu-26.04`:** §14.
- **Renaming prose only and leaving identifiers** (#26 option b): the `_Avoid_` list would need an exception, which is a rule.

## 22. Mechanism claims and their sources

| Claim                                                                                                                                                                                                                             | Source, read or run 2026-09-20                                               |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `payload` 148 hits outside the plans, 67 in code and READMEs; `upstream/skills.json` 42 references in 13 files                                                                                                                    | sweep, #26; `git grep -c`                                                    |
| Moving the two scripts out of `bin/` without the cspell override: 20 unknown words, 4 in the watch                                                                                                                                | sweep, #26, reproduced                                                       |
| `checked_shell()` selects by shebang; a moved script needs no derivation edit                                                                                                                                                     | `tests/lib.sh`, `checked_shell`                                              |
| 856 backticked slash tokens resolve with three roots; 366 do not: 162 specs, 165 plans, 39 elsewhere                                                                                                                              | scratch scanner over `git ls-files '*.md'`                                   |
| `git log --all -1 -- path` prints nothing for a path never tracked; with a pathspec on the old path alone, `git log -M` reports the rename commit as `D`, while `git show --name-status -M` of that commit reports `R098 old new` | run on `hooks/` and on `plugins/software-development/README.md` at `a3c797f` |
| In the ERE `(^\|[^[:alnum:]-])FORM([^[:alnum:]-]\|$)`, `_` is a boundary and `-` is not, so `payload_tmp` matches `payload` and `harness-backup` does not match `harness`                                                         | POSIX character classes; run with `grep -E` on both strings                  |
| `git check-ignore` exits 0 for a path matched by `.gitignore` whether or not it exists                                                                                                                                            | run on `.claude/worktrees/x`                                                 |
| The SchemaStore marketplace schema defines top-level `description` and `metadata.description`; the URL returns 200                                                                                                                | sweep, #37, fetched                                                          |
| `claude plugin validate --strict` does not fetch `$schema`                                                                                                                                                                        | #58, verified 2026-09-17                                                     |
| Four `temp_subdir_*.clone` directories in the cache root; every `installed_plugins.json` path points into `cache/<marketplace>/`                                                                                                  | `ls`, `jq` on the maintainer's machine                                       |
| The Claude Code launcher retains its target plus two superseded versions                                                                                                                                                          | sweep, #64, read at 2.1.273; **to confirm by count after the next update**   |
| Fourteen scheduled `upstream-watch` runs since 2026-09-07, all `success`; the file reached `main` twelve seconds after the 2026-09-06 slot                                                                                        | sweep, #24; `gh run list --event schedule`                                   |
| Scheduled runs land 4.5 to 6.5 hours after the 06:17 UTC slot                                                                                                                                                                     | sweep, #24, from the run timestamps                                          |
| The runs API answers unauthenticated for a public repository, 60 requests an hour                                                                                                                                                 | GitHub REST documentation                                                    |
| The four actions declare node20; GitHub forces node24; first node24 majors: checkout v5.0.0, setup-node v5.0.0, setup-python v6.0.0, upload-artifact v6.0.0                                                                       | sweep, #6; the actions' release pages                                        |
| actionlint 1.7.12 rejects `ubuntu-26.04` as a runner label unless `.github/actionlint.yaml` declares it                                                                                                                           | sweep, #6, run                                                               |
| `ubuntu-latest` migrates to 26.04 from 2026-10-19                                                                                                                                                                                 | GitHub's annotation on the `61714c1` runs, quoted in #6                      |
| `/(?<=^\|\s)#.*$/gm` excludes `insection` and `nosuchtool` and keeps trailing `# comment` text                                                                                                                                    | #62, verified                                                                |
| `bin/format` reduced to `exit 0`: suite 29/0/0; a dropped `*.json` glob: green on a clean tree, and once a JSON file is unformatted the prettier test goes red and its prescribed remedy does nothing                             | #62, reproduced; the clean-tree half re-measured 2026-09-20                  |
| Bash 4.0–4.3 abort on `"${arr[@]}"` with an empty array under `set -u`; 4.4 does not                                                                                                                                              | #61 M3, bash 4.3.0 built from source                                         |
| `{ print $2; exit 0 } END { exit 1 }` runs `END` after `exit` and takes the suite down                                                                                                                                            | #61 M11, verified                                                            |
| `printf … \| grep -q && fail` skips the assertion under `pipefail` past roughly 400–500 tracked paths                                                                                                                             | #61 M8, reproduced on a clone                                                |
| Fixture 10's count assertion is satisfied by 36 unrelated failures                                                                                                                                                                | #61 M1, mutant run                                                           |
| Neither `test-doctor-faults.sh` fixture reads the status of the run its stub was added for                                                                                                                                        | #63, read                                                                    |
| `aside_path()` names `<path>.aside.<timestamp>`; three call sites, all symlinks                                                                                                                                                   | `bin/setup`                                                                  |

## 23. Open items carried forward

- **Codex's plugin cache has no registry file** the doctor can read offline; §11 reads it through the CLI in the same run. If Codex grows a file, the walk reads that.
- **#52 rebalances the buckets** of §14: nine names move from `skills` to `via_subset_entry`, and the subset entry's own complement test is #52's.
- **#21 may devendor `using-superpowers.md` or `setup-repository/SKILL.md`.** That edits the ownership table of §16 and nothing else; the `harness` in the first becomes ours to rename then.
- **`docs/agents/domain.md` diverged from its scaffolder seed at `f76a73f`** (two fence languages); the other two are still byte-identical. The 1-2 spec's "byte-identical" note is history for that one file. Nothing here depends on it.
- **`test-vendored-diagnosing-bugs.sh` and `test-vendored-scaffolder.sh` hardcode `6acc160e`**, the commit `v1.2.3` peels to; they read it from the mattpocock subset entry once #52 creates it.
- **The leading-word audit** (§5.5) may drop words from the list; `CONTEXT.md` records what it found.
- **A hash-comment override keyed by shebang** rather than by path glob would spare the next move its cspell edit; not done here.
- **`tests/tools.txt` and `.markdownlint-cli2.jsonc`** were the two owned files no formatter parsed; after §18 the second is prettier's, and `tools.txt` has the shape assertion of §17.
