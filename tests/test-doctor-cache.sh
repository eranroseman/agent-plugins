#!/usr/bin/env bash
# The one class of residue the engine can prove and repair (spec §11, #25):
# a Claude plugin cache directory that known_marketplaces.json does not
# name, that no installed plugin's installPath lies under, that no installed
# plugin's key names after its @, and that has not been modified for an
# hour. Check mode names it as a FAIL with the four facts; apply mode
# deletes it and says so; a directory failing any guard is left alone and
# named with the guard; a registry jq cannot parse, or an installed entry
# with neither an installPath nor an @marketplace, skips the whole walk and
# nothing is deleted; the CLI's temp_subdir_*.clone scratch directories are
# the same class under their own name. The Codex half only reports (plan B,
# P1). Needs no network; the clones are seeded at a wrong sha with no
# origin, and claude, node and npx are stubs.
. "$(dirname "$0")/lib.sh"

DOCTOR="$REPO_ROOT/bin/doctor"
SETUP="$REPO_ROOT/bin/setup"
T="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$T"' EXIT

BIN="$T/bin"
link_tools "$BIN" bash git jq grep find date readlink basename dirname cut rm mv ln mkdir cat sha256sum
for t in claude node npx; do
  printf '#!/usr/bin/env bash\n[ "$1" = --version ] && { printf "2.1.273 (Claude Code)\\n"; exit 0; }\nexit 1\n' >"$BIN/$t" \
    || fail "could not write the $t stub"
  chmod +x "$BIN/$t" || fail "could not make the $t stub executable"
done

# A HOME with a registered marketplace `mkt`, an installed plugin under it,
# and five other cache directories, one per verdict.
seed() {
  local h="$1" cache="$1/.claude/plugins/cache"
  mkdir -p "$h/.agents/skills" "$cache" || fail "could not seed $h"
  skill "$cache/mkt/plug/1.0.0/skills/alpha" "alpha"
  skill "$cache/held/plug/1.0.0/skills/beta" "beta"
  mkdir -p "$cache/gone/old/1.0.0/skills/zeta" "$cache/fresh/x" "$cache/temp_subdir_1789739987658_kwt7rv.clone/skills" \
    || fail "could not seed the cache"
  cat >"$h/.claude/plugins/installed_plugins.json" <<JSON || fail "could not write installed_plugins.json"
{"version":2,"plugins":{
  "plug@mkt":[{"scope":"user","version":"1.0.0","installPath":"$cache/mkt/plug/1.0.0"}],
  "plug@held":[{"scope":"user","version":"1.0.0","installPath":"$cache/held/plug/1.0.0"}]}}
JSON
  printf '{"mkt":{"source":{"source":"github","repo":"x/y"},"installLocation":"/nowhere"}}\n' \
    >"$h/.claude/plugins/known_marketplaces.json" || fail "could not write known_marketplaces.json"
  # gone, held and the scratch clone are old; fresh was modified just now.
  touch -d '2 hours ago' "$cache/gone" "$cache/held" "$cache/temp_subdir_1789739987658_kwt7rv.clone" \
    || fail "could not age the directories"
}

# 1. Check mode: the two deletable directories are FAILs naming the facts,
# the two guarded ones are NOTEs naming the guard, the registered one is silent.
H="$T/h1"
seed "$H"
OUT="$(env HOME="$H" CODEX_HOME="$H/.codex" PATH="$BIN" /bin/bash "$DOCTOR" 2>&1 || true)"
saw "FAIL: cache for an unregistered marketplace: $H/.claude/plugins/cache/gone (not in known_marketplaces.json, no installed plugin under it, unmodified for over an hour); bin/setup deletes it" \
  || fail "check mode: the orphaned cache was not a FAIL with the four facts:"$'\n'"$OUT"
saw "FAIL: scratch clone from a git-subdir install: $H/.claude/plugins/cache/temp_subdir_1789739987658_kwt7rv.clone (not in known_marketplaces.json, no installed plugin under it, unmodified for over an hour); bin/setup deletes it" \
  || fail "check mode: the scratch clone was not named as such:"$'\n'"$OUT"
saw "NOTE: left alone: $H/.claude/plugins/cache/held (an installed plugin's installPath lies under it)" \
  || fail "check mode: the directory holding an installed plugin was not left alone by name:"$'\n'"$OUT"
saw "NOTE: left alone: $H/.claude/plugins/cache/fresh (modified less than an hour ago)" \
  || fail "check mode: the fresh directory was not left alone by name:"$'\n'"$OUT"
saw "$H/.claude/plugins/cache/mkt" && fail "check mode: the registered marketplace's cache was reported:"$'\n'"$OUT"
saw 'OK:   5 Claude plugin cache director(ies) walked, 1 registered' \
  || fail "check mode: the walk's summary line is wrong or missing:"$'\n'"$OUT"

# 2. Apply mode deletes exactly the two, says so, and the re-check is clean
# of them. The clones are seeded so nothing reaches the network.
seed_clones "$H"
seed_lockfile "$H"
OUT="$(env HOME="$H" CODEX_HOME="$H/.codex" PATH="$BIN" /bin/bash "$SETUP" 2>&1 || true)"
saw "DID:  deleted cache for an unregistered marketplace: $H/.claude/plugins/cache/gone" \
  || fail "apply: the orphaned cache's deletion was not reported:"$'\n'"$OUT"
saw "DID:  deleted scratch clone from a git-subdir install: $H/.claude/plugins/cache/temp_subdir_1789739987658_kwt7rv.clone" \
  || fail "apply: the scratch clone's deletion was not reported:"$'\n'"$OUT"
[ ! -e "$H/.claude/plugins/cache/gone" ] || fail "apply: the orphaned cache survived"
[ ! -e "$H/.claude/plugins/cache/temp_subdir_1789739987658_kwt7rv.clone" ] || fail "apply: the scratch clone survived"
for keep in mkt held fresh; do
  [ -d "$H/.claude/plugins/cache/$keep" ] || fail "apply: $keep was deleted"
done
[ "$(printf '%s\n' "$OUT" | grep -c 'OK:   3 Claude plugin cache director(ies) walked, 1 registered')" -ge 1 ] \
  || fail "apply: the re-check did not walk three directories:"$'\n'"$OUT"

# 3. An unreadable registry, either one: the whole walk is one SKIP and
# nothing is deleted, even a directory that would pass every guard.
for reg in known_marketplaces.json installed_plugins.json; do
  H2="$T/h-$reg"
  seed "$H2"
  printf '{\n' >"$H2/.claude/plugins/$reg" || fail "could not corrupt $reg"
  OUT="$(env HOME="$H2" CODEX_HOME="$H2/.codex" PATH="$BIN" /bin/bash "$DOCTOR" 2>&1 || true)"
  saw "SKIP: $H2/.claude/plugins/$reg does not parse" || fail "$reg unreadable: the walk was not skipped by name:"$'\n'"$OUT"
  saw 'FAIL: cache for an unregistered' && fail "$reg unreadable: a directory was still judged:"$'\n'"$OUT"
done

# 3b. A registry that is empty, blank, or the wrong JSON shape must skip the
# whole walk exactly as a syntax error does (spec §11): jq's slurp mode reads
# a 0-byte or blank file as zero documents, not a parse error, so the guard
# must demand exactly one document of the right shape, not merely "parses".
for reg in known_marketplaces.json installed_plugins.json; do
  for variant in empty whitespace array null; do
    H2="$T/h-$reg-$variant"
    seed "$H2"
    case "$variant" in
      empty) printf '' >"$H2/.claude/plugins/$reg" ;;
      whitespace) printf '   \n\t\n' >"$H2/.claude/plugins/$reg" ;;
      array) printf '[]' >"$H2/.claude/plugins/$reg" ;;
      null) printf 'null' >"$H2/.claude/plugins/$reg" ;;
    esac
    OUT="$(env HOME="$H2" CODEX_HOME="$H2/.codex" PATH="$BIN" /bin/bash "$DOCTOR" 2>&1 || true)"
    saw "SKIP: $H2/.claude/plugins/$reg does not parse" \
      || fail "$reg $variant: the walk was not skipped by name:"$'\n'"$OUT"
    saw 'FAIL: cache for an unregistered' \
      && fail "$reg $variant: a directory was still judged:"$'\n'"$OUT"
  done
done
# installed_plugins.json only: a .plugins that parses but is the wrong shape.
H2="$T/h-installed_plugins.json-plugins-array"
seed "$H2"
printf '{"plugins":[]}\n' >"$H2/.claude/plugins/installed_plugins.json"
OUT="$(env HOME="$H2" CODEX_HOME="$H2/.codex" PATH="$BIN" /bin/bash "$DOCTOR" 2>&1 || true)"
saw "SKIP: $H2/.claude/plugins/installed_plugins.json does not parse" \
  || fail "installed_plugins.json with a non-object .plugins: the walk was not skipped by name:"$'\n'"$OUT"
saw 'FAIL: cache for an unregistered' \
  && fail "installed_plugins.json with a non-object .plugins: a directory was still judged:"$'\n'"$OUT"
# The critical case, in apply mode too: a blank registry must not reach rm -rf
# for a directory that would otherwise be registered or held.
seed_clones "$T/h-known_marketplaces.json-empty"
seed_lockfile "$T/h-known_marketplaces.json-empty"
OUT="$(env HOME="$T/h-known_marketplaces.json-empty" CODEX_HOME="$T/h-known_marketplaces.json-empty/.codex" PATH="$BIN" \
  /bin/bash "$SETUP" 2>&1 || true)"
for keep in mkt held gone fresh; do
  [ -d "$T/h-known_marketplaces.json-empty/.claude/plugins/cache/$keep" ] \
    || fail "blank known_marketplaces.json: apply mode deleted $keep:"$'\n'"$OUT"
done

# 3c. Guard 2 (registered) must not depend on an external's exit code or on
# a marketplace name being free of regex-special characters: a name that
# would confuse a pattern match is still recognized and its cache stays
# silent.
H7="$T/h7"
seed "$H7"
# shellcheck disable=SC2015  # both commands must succeed; fail is right when either does not
jq --arg m 'mk.t+x' '. + {($m): {"source":{"source":"github","repo":"x/y"},"installLocation":"/nowhere"}}' \
  "$H7/.claude/plugins/known_marketplaces.json" >"$H7/.claude/plugins/known_marketplaces.json.tmp" \
  && mv "$H7/.claude/plugins/known_marketplaces.json.tmp" "$H7/.claude/plugins/known_marketplaces.json" \
  || fail "could not add the regex-special marketplace"
mkdir -p "$H7/.claude/plugins/cache/mk.t+x/old/1.0.0/skills/zeta" || fail "could not seed the regex-special cache"
touch -d '2 hours ago' "$H7/.claude/plugins/cache/mk.t+x" || fail "could not age the regex-special cache"
OUT="$(env HOME="$H7" CODEX_HOME="$H7/.codex" PATH="$BIN" /bin/bash "$DOCTOR" 2>&1 || true)"
saw "$H7/.claude/plugins/cache/mk.t+x" \
  && fail "regex-special marketplace name: its cache was reported though registered:"$'\n'"$OUT"
saw 'OK:   6 Claude plugin cache director(ies) walked, 2 registered' \
  || fail "regex-special marketplace name: the walk's summary line is wrong:"$'\n'"$OUT"

# 4. No cache directory at all still reports, so the bracket holds.
mkdir -p "$T/h3/.agents/skills" || fail "could not seed h3"
OUT="$(env HOME="$T/h3" CODEX_HOME="$T/h3/.codex" PATH="$BIN" /bin/bash "$DOCTOR" 2>&1 || true)"
saw 'OK:   no Claude plugin cache at' || fail "no cache: the walk did not report:"$'\n'"$OUT"

# 4b. Guard 3 (an installed plugin's installPath lies under it) must survive a
# literal-prefix trap: a HOME passed with a trailing slash must not silently
# build a doubled slash into the cache root and lose the match.
H5="$T/h5"
seed "$H5"
OUT="$(env HOME="$H5/" CODEX_HOME="$H5/.codex" PATH="$BIN" /bin/bash "$DOCTOR" 2>&1 || true)"
saw "NOTE: left alone: $H5/.claude/plugins/cache/held (an installed plugin's installPath lies under it)" \
  || fail "HOME with a trailing slash: the held cache was not left alone by name:"$'\n'"$OUT"
seed_clones "$H5"
seed_lockfile "$H5"
OUT="$(env HOME="$H5/" CODEX_HOME="$H5/.codex" PATH="$BIN" /bin/bash "$SETUP" 2>&1 || true)"
[ -d "$H5/.claude/plugins/cache/held" ] \
  || fail "HOME with a trailing slash: apply mode deleted the held cache:"$'\n'"$OUT"

# 4c. Same guard, reached the other way: the registry records the installPath
# through a symlinked ancestor of HOME rather than HOME's own real path.
H6="$T/h6"
seed "$H6"
ln -s "$H6" "$T/link6" || fail "could not create the symlinked HOME prefix"
cat >"$H6/.claude/plugins/installed_plugins.json" <<JSON || fail "could not rewrite installed_plugins.json"
{"version":2,"plugins":{
  "plug@mkt":[{"scope":"user","version":"1.0.0","installPath":"$H6/.claude/plugins/cache/mkt/plug/1.0.0"}],
  "plug@held":[{"scope":"user","version":"1.0.0","installPath":"$T/link6/.claude/plugins/cache/held/plug/1.0.0"}]}}
JSON
OUT="$(env HOME="$H6" CODEX_HOME="$H6/.codex" PATH="$BIN" /bin/bash "$DOCTOR" 2>&1 || true)"
saw "NOTE: left alone: $H6/.claude/plugins/cache/held (an installed plugin's installPath lies under it)" \
  || fail "installPath through a symlinked HOME prefix: the held cache was not left alone by name:"$'\n'"$OUT"
seed_clones "$H6"
seed_lockfile "$H6"
OUT="$(env HOME="$H6" CODEX_HOME="$H6/.codex" PATH="$BIN" /bin/bash "$SETUP" 2>&1 || true)"
[ -d "$H6/.claude/plugins/cache/held" ] \
  || fail "installPath through a symlinked HOME prefix: apply mode deleted the held cache:"$'\n'"$OUT"

# 4d. Same guard, for an installed entry that records no installPath at all:
# the marketplace its key names after the @ holds its cache directory.
H10="$T/h10"
seed "$H10"
cat >"$H10/.claude/plugins/installed_plugins.json" <<JSON || fail "could not rewrite installed_plugins.json"
{"version":2,"plugins":{
  "plug@mkt":[{"scope":"user","version":"1.0.0","installPath":"$H10/.claude/plugins/cache/mkt/plug/1.0.0"}],
  "plug@held":[{"scope":"user","version":"1.0.0"}]}}
JSON
OUT="$(env HOME="$H10" CODEX_HOME="$H10/.codex" PATH="$BIN" /bin/bash "$DOCTOR" 2>&1 || true)"
saw "NOTE: left alone: $H10/.claude/plugins/cache/held (an installed plugin's key names this marketplace)" \
  || fail "an installed entry with no installPath: its marketplace's cache was not left alone by name:"$'\n'"$OUT"
seed_clones "$H10"
seed_lockfile "$H10"
OUT="$(env HOME="$H10" CODEX_HOME="$H10/.codex" PATH="$BIN" /bin/bash "$SETUP" 2>&1 || true)"
[ -d "$H10/.claude/plugins/cache/held" ] \
  || fail "an installed entry with no installPath: apply mode deleted its marketplace's cache:"$'\n'"$OUT"

# 4e. An installed entry whose key names no marketplace and which records no
# installPath cannot be placed under any directory: the whole walk is one
# SKIP naming the key, and nothing is deleted, even in apply mode.
H11="$T/h11"
seed "$H11"
cat >"$H11/.claude/plugins/installed_plugins.json" <<JSON || fail "could not rewrite installed_plugins.json"
{"version":2,"plugins":{
  "plug@mkt":[{"scope":"user","version":"1.0.0","installPath":"$H11/.claude/plugins/cache/mkt/plug/1.0.0"}],
  "plug@held":[{"scope":"user","version":"1.0.0","installPath":"$H11/.claude/plugins/cache/held/plug/1.0.0"}],
  "stray":[{"scope":"user","version":"1.0.0"}]}}
JSON
OUT="$(env HOME="$H11" CODEX_HOME="$H11/.codex" PATH="$BIN" /bin/bash "$DOCTOR" 2>&1 || true)"
saw 'SKIP: installed_plugins.json entry stray has no installPath and no @marketplace; not walking' \
  || fail "an entry with neither an installPath nor an @marketplace: the walk was not skipped by name:"$'\n'"$OUT"
printf '%s\n' "$OUT" | grep -qE '^FAIL: (cache for an unregistered|scratch clone)' \
  && fail "an entry with neither an installPath nor an @marketplace: a directory was still judged:"$'\n'"$OUT"
seed_clones "$H11"
seed_lockfile "$H11"
OUT="$(env HOME="$H11" CODEX_HOME="$H11/.codex" PATH="$BIN" /bin/bash "$SETUP" 2>&1 || true)"
for keep in mkt held gone fresh temp_subdir_1789739987658_kwt7rv.clone; do
  [ -d "$H11/.claude/plugins/cache/$keep" ] \
    || fail "an entry with neither an installPath nor an @marketplace: apply mode deleted $keep:"$'\n'"$OUT"
done

# 5. The Codex half reports and never deletes: a directory config.toml does
# not record and no installed plugin sits under is a NOTE; the recorded one
# and the one holding an installed plugin are silent; the two stay on disk.
H4="$T/h4"
mkdir -p "$H4/.agents/skills" "$H4/.codex/plugins/cache/reg/a" "$H4/.codex/plugins/cache/orphan" "$H4/.codex/plugins/cache/inst" \
  || fail "could not seed h4"
skill "$H4/.codex/plugins/cache/inst/theta/1.0.0/skills/gamma" "gamma"
printf '[marketplaces.reg]\nsource = "x"\n' >"$H4/.codex/config.toml" || fail "could not write config.toml"
cat >"$BIN/codex" <<'STUB' || fail "could not write the codex stub"
#!/usr/bin/env bash
[ "$1" = --version ] && { printf 'codex-cli 0.147.0\n'; exit 0; }
[ "$*" = "plugin list --json" ] || exit 1
printf '{"installed":[{"pluginId":"theta@inst","marketplaceName":"inst","name":"theta","version":"1.0.0","enabled":true}]}\n'
STUB
chmod +x "$BIN/codex" || fail "could not make the codex stub executable"
OUT="$(env HOME="$H4" CODEX_HOME="$H4/.codex" PATH="$BIN" /bin/bash "$DOCTOR" 2>&1 || true)"
saw "NOTE: Codex plugin cache for a marketplace config.toml does not record: $H4/.codex/plugins/cache/orphan (left alone; remove it by hand)" \
  || fail "codex: the unrecorded cache was not reported:"$'\n'"$OUT"
saw "$H4/.codex/plugins/cache/reg" && fail "codex: the recorded marketplace's cache was reported:"$'\n'"$OUT"
saw "$H4/.codex/plugins/cache/inst" && fail "codex: the cache holding an installed plugin was reported:"$'\n'"$OUT"
# P1's central promise, in apply mode: the Codex half never calls rm, so an
# unaccounted-for directory and one holding an installed plugin both survive.
seed_clones "$H4"
seed_lockfile "$H4"
OUT="$(env HOME="$H4" CODEX_HOME="$H4/.codex" PATH="$BIN" /bin/bash "$SETUP" 2>&1 || true)"
[ -d "$H4/.codex/plugins/cache/orphan" ] || fail "codex apply: orphan was deleted, but the Codex half never deletes:"$'\n'"$OUT"
[ -d "$H4/.codex/plugins/cache/inst" ] || fail "codex apply: inst was deleted, but the Codex half never deletes:"$'\n'"$OUT"
rm -f "$BIN/codex"

# 5b. Controller amendment P-3: a missing config.toml means no recorded
# names, not a crash or a leak -- codex is present, a cache directory is
# unaccounted for, and nothing about config.toml reaches stderr.
H8="$T/h8"
mkdir -p "$H8/.agents/skills" "$H8/.codex/plugins/cache/orphan" || fail "could not seed h8"
cat >"$BIN/codex" <<'STUB' || fail "could not write the codex stub"
#!/usr/bin/env bash
[ "$1" = --version ] && { printf 'codex-cli 0.147.0\n'; exit 0; }
[ "$*" = "plugin list --json" ] || exit 1
printf '{"installed":[]}\n'
STUB
chmod +x "$BIN/codex" || fail "could not make the codex stub executable"
STDERR8="$T/h8-stderr"
OUT="$(env HOME="$H8" CODEX_HOME="$H8/.codex" PATH="$BIN" /bin/bash "$DOCTOR" 2>"$STDERR8" || true)"
saw "NOTE: Codex plugin cache for a marketplace config.toml does not record: $H8/.codex/plugins/cache/orphan (left alone; remove it by hand)" \
  || fail "no config.toml: the unrecorded cache was not reported:"$'\n'"$OUT"
[ -s "$STDERR8" ] && fail "no config.toml: stderr was not empty:"$'\n'"$(cat "$STDERR8")"
rm -f "$BIN/codex" "$STDERR8"

# 5c. codex present but `plugin list --json` failed earlier (ensure_codex
# already reported it): the Codex cache is skipped by name, not silently
# judged with an empty list, and nothing is deleted even in apply mode.
H9="$T/h9"
mkdir -p "$H9/.agents/skills" "$H9/.codex/plugins/cache/orphan" || fail "could not seed h9"
printf '[marketplaces.reg]\nsource = "x"\n' >"$H9/.codex/config.toml" || fail "could not write config.toml"
cat >"$BIN/codex" <<'STUB' || fail "could not write the codex stub"
#!/usr/bin/env bash
[ "$1" = --version ] && { printf 'codex-cli 0.147.0\n'; exit 0; }
exit 1
STUB
chmod +x "$BIN/codex" || fail "could not make the codex stub executable"
OUT="$(env HOME="$H9" CODEX_HOME="$H9/.codex" PATH="$BIN" /bin/bash "$DOCTOR" 2>&1 || true)"
saw 'SKIP: codex plugin list failed earlier, so the Codex plugin cache is not judged' \
  || fail "codex plugin list failed: the cache walk was not skipped by name:"$'\n'"$OUT"
saw "$H9/.codex/plugins/cache/orphan" && fail "codex plugin list failed: a directory was still judged:"$'\n'"$OUT"
seed_clones "$H9"
seed_lockfile "$H9"
OUT="$(env HOME="$H9" CODEX_HOME="$H9/.codex" PATH="$BIN" /bin/bash "$SETUP" 2>&1 || true)"
[ -d "$H9/.codex/plugins/cache/orphan" ] \
  || fail "codex plugin list failed: apply mode deleted orphan despite the SKIP:"$'\n'"$OUT"
rm -f "$BIN/codex"

printf 'doctor-cache: two deletable directories named and deleted, two guarded ones left alone by name, unreadable registries skip the walk, Codex reported only\n'
