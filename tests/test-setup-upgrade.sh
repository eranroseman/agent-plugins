#!/usr/bin/env bash
# The upgrade path. `claude plugin install` is a no-op on an already-installed
# plugin -- it prints "already installed", exits 0 and leaves the old version
# on disk -- so a machine holding an older version only moves under `claude
# plugin update`. The CI end-to-end job starts from an empty HOME and
# structurally cannot reach this path. The older install below is a real one
# rather than a hand-edited `version` field, because the CLI reads the version
# from the install path and answers "already at the latest version" to a
# seeded field. Fetches the pinned upstream trees, so it needs network.
# needs: claude
. "$(dirname "$0")/lib.sh"

SETUP="$REPO_ROOT/bin/setup"
W="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$W"' EXIT
PJ="plugins/software-dev/.claude-plugin/plugin.json"
# sensemaking too: it installs as a dependency, and a parent's update does
# not carry it, so its own update path is exercised here on every run.
PJS="plugins/sensemaking/.claude-plugin/plugin.json"
cp -a "$REPO_ROOT" "$W/repo" || fail "could not copy the checkout into $W"
jq '.version = "0.0.1"' "$REPO_ROOT/$PJ" >"$W/lowered" || fail "could not lower the version"
cp "$W/lowered" "$W/repo/$PJ" || fail "could not seed the lowered manifest"
jq '.version = "0.0.1"' "$REPO_ROOT/$PJS" >"$W/lowered-s" || fail "could not lower sensemaking's version"
cp "$W/lowered-s" "$W/repo/$PJS" || fail "could not seed sensemaking's lowered manifest"

mkdir -p "$W/home" || fail "could not create $W/home"
env HOME="$W/home" claude plugin marketplace add "$W/repo" >/dev/null 2>&1 \
  || fail "could not add the copied marketplace"
env HOME="$W/home" claude plugin install software-dev@eranroseman --scope user \
  >/dev/null 2>&1 || fail "could not seed the 0.0.1 install"
# Back to the declared version, and refresh the catalogue, mirroring the
# documented real-machine step.
cp "$REPO_ROOT/$PJ" "$W/repo/$PJ" || fail "could not restore the manifest"
cp "$REPO_ROOT/$PJS" "$W/repo/$PJS" || fail "could not restore sensemaking's manifest"
env HOME="$W/home" claude plugin marketplace update eranroseman >/dev/null 2>&1 \
  || fail "could not refresh the copied marketplace"

# The pinned clone, seeded from the shared checkout, so the only thing left
# for bin/setup to converge is the Claude half.
CLONE="$W/home/.local/share/software-dev/upstream/superpowers"
mkdir -p "$(dirname "$CLONE")" || fail "could not create the upstream root"
cp -a "$(fetch_upstream)" "$CLONE" || fail "could not seed the pinned clone"
# Every other curated entry's clone, the same way, so bin/setup has nothing
# to fetch: the CI end-to-end job is where the real clone is exercised.
while IFS="$(printf '\t')" read -r name url sha; do
  [ -n "$name" ] || continue
  [ "$name" != superpowers ] || continue
  cp -a "$(fetch_pinned "$url" "$sha" "${TMPDIR:-/tmp}/software-dev-upstream-$name")" \
    "$(dirname "$CLONE")/$name" || fail "could not seed the $name clone"
done < <(jq -r '.plugins[] | select(.source.source? == "git-subdir")
                | [.name, .source.url, .source.sha] | @tsv' "$MARKETPLACE")

# A bin directory without codex, mirroring tests/test-doctor-faults.sh: on a
# machine that has codex on PATH, ensure_codex is no longer a stub, and an
# inherited PATH would make it add the real eranroseman marketplace by
# cloning it over the network into this scratch CODEX_HOME on every run.
# claude is real, because the fixture drives it, and so is node: wherever
# claude was installed with npm, as on the CI runner, it is a node script.
# npx is a stub that exits 1: the pinned lockfile below means ensure_skills_sh
# never runs it, and an unexpected call is then a visible FAIL line rather
# than a network install.
BIN="$W/bin"
link_tools "$BIN" bash git jq node claude sed awk grep find date readlink basename dirname \
  rm mv ln mkdir cp cat sha256sum
printf '#!/usr/bin/env bash\nexit 1\n' >"$BIN/npx" || fail "could not write the npx stub"
chmod +x "$BIN/npx" || fail "could not make the npx stub executable"

# A fully pinned lockfile, mirroring tests/test-doctor-faults.sh: without it,
# ensure_skills_sh would find every declared skill unpinned and try to
# install all of them over the network on every run of this test.
mkdir -p "$W/home/.agents" || fail "could not create $W/home/.agents"
jq '{version: 3,
     skills: (reduce (.sources[] as $s | $s.skills[] |
       {key: ., value: {source: $s.repo, ref: $s.ref}}) as $e ({}; . + {($e.key): $e.value})),
     dismissed: {}}' \
  "$REPO_ROOT/skills.json" >"$W/home/.agents/.skill-lock.json" \
  || fail "could not synthesize a pinned lockfile"

want="$(jq -r .version "$REPO_ROOT/$PJ")" || fail "could not read the declared version"
if out="$(env HOME="$W/home" CODEX_HOME="$W/home/.codex" SD_MARKETPLACE_SOURCE="$W/repo" \
  PATH="$BIN" bash "$SETUP" 2>&1)"; then status=0; else status=$?; fi
got="$(jq -r '.plugins["software-dev@eranroseman"][0].version' \
  "$W/home/.claude/plugins/installed_plugins.json")" || fail "could not read the installed version"
[ "$got" = "$want" ] \
  || fail "bin/setup left software-dev at $got, declared $want:"$'\n'"$out"
want_s="$(jq -r .version "$REPO_ROOT/$PJS")" || fail "could not read sensemaking's declared version"
got_s="$(jq -r '.plugins["sensemaking@eranroseman"][0].version' \
  "$W/home/.claude/plugins/installed_plugins.json")" || fail "could not read sensemaking's installed version"
[ "$got_s" = "$want_s" ] \
  || fail "bin/setup left sensemaking at $got_s, declared $want_s; a dependency does not move with its parent:"$'\n'"$out"
[ "$status" -eq 0 ] \
  || fail "bin/setup did not converge on an upgradeable machine (exit $status):"$'\n'"$out"

printf 'setup-upgrade: software-dev and sensemaking moved to the declared versions under claude plugin update\n'
