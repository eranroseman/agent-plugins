#!/usr/bin/env bash
# The one class of residue the engine can prove and repair (spec §11, #25):
# a Claude plugin cache directory that known_marketplaces.json does not
# name, that no installed plugin's installPath lies under, and that has not
# been modified for an hour. Check mode names it as a FAIL with the four
# facts; apply mode deletes it and says so; a directory failing any guard is
# left alone and named with the guard; a registry jq cannot parse skips the
# whole walk and nothing is deleted; the CLI's temp_subdir_*.clone scratch
# directories are the same class under their own name. The Codex half only
# reports (plan B, P1). Needs no network; the clones are seeded at a wrong
# sha with no origin, and claude, node and npx are stubs.
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

skill() { mkdir -p "$1" && printf -- '---\nname: %s\n---\n%s\n' "$(basename "$1")" "$2" >"$1/SKILL.md"; }

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

saw() { printf '%s\n' "$OUT" | grep -qF -- "$1"; }

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
UPSTREAM="$H/.local/share/software-dev/upstream"
while IFS="$(printf '\t')" read -r name path skill; do
  [ -n "$name" ] || continue
  dir="$UPSTREAM/$name"
  if [ ! -d "$dir/.git" ]; then
    mkdir -p "$dir" || fail "could not seed $dir"
    git -C "$dir" init -q || fail "git init failed in $dir"
    git -C "$dir" -c user.email=t@example.com -c user.name=t commit -q --allow-empty -m seed \
      || fail "could not seed a commit in $dir"
  fi
  mkdir -p "$dir/$path/$skill"
done < <(jq -r '.plugins[] | select(.source.source? == "git-subdir") as $p
                | $p.skills[] | [$p.name, $p.source.path, (. | sub("^\\./"; ""))] | @tsv' "$MARKETPLACE")
jq '{version: 3,
     skills: (reduce (.sources[] as $s | $s.skills[] |
       {key: ., value: {source: $s.repo, ref: $s.ref}}) as $e ({}; . + {($e.key): $e.value})),
     dismissed: {}}' "$REPO_ROOT/skills.json" >"$H/.agents/.skill-lock.json" \
  || fail "could not synthesize a pinned lockfile"
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

# 4. No cache directory at all still reports, so the bracket holds.
mkdir -p "$T/h3/.agents/skills" || fail "could not seed h3"
OUT="$(env HOME="$T/h3" CODEX_HOME="$T/h3/.codex" PATH="$BIN" /bin/bash "$DOCTOR" 2>&1 || true)"
saw 'OK:   no Claude plugin cache at' || fail "no cache: the walk did not report:"$'\n'"$OUT"

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
rm -f "$BIN/codex"

printf 'doctor-cache: two deletable directories named and deleted, two guarded ones left alone by name, unreadable registries skip the walk, Codex reported only\n'
