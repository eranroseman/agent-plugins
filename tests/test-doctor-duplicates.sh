#!/usr/bin/env bash
# bin/doctor must report one skill name reaching two different trees on one
# agent CLI, and a Claude plugin cache whose marketplace is not registered, and
# must stay quiet on the three false positives spec section 6.6 measured: the
# same content under two paths, a superseded plugin version, and the same
# name differing only across the two CLIs. Needs no network and no CLI: every
# route is filesystem state plus the two registry files. The Codex half is
# driven by two stub `codex plugin list --json` runs, one failing and one
# succeeding; the succeeding one is the only place in the suite where the
# Codex tab loop and its malformed-field guard execute an iteration.
. "$(dirname "$0")/lib.sh"

DOCTOR="$REPO_ROOT/bin/doctor"
H="$(mktemp -d)"
trap 'rm -rf "$H"' EXIT
A="$H/.agents/skills"
C="$H/.claude/skills"
X="$H/.codex/skills"
mkdir -p "$A" "$C" "$X" "$H/.claude/plugins" || fail "could not seed $H"

skill() { mkdir -p "$1" && printf -- '---\nname: %s\n---\n%s\n' "$(basename "$1")" "$2" >"$1/SKILL.md"; }

# alpha: one tree, two paths. Same content, so not a finding.
skill "$A/alpha" "alpha body"
ln -s "$A/alpha" "$C/alpha"

# beta: two trees on Claude. The finding.
skill "$A/beta" "beta as skills.sh installs it"
skill "$H/.claude/plugins/cache/mkt/plug/2.0.0/skills/beta" "beta as the plugin ships it"

# gamma: differs only in a superseded plugin version, which is not current.
skill "$A/gamma" "gamma current"
skill "$H/.claude/plugins/cache/mkt/plug/1.0.0/skills/gamma" "gamma old"

# delta: differs only across the two CLIs. Not a finding on either.
skill "$C/delta" "delta on claude"
skill "$X/delta" "delta on codex"

# A git-subdir cache whose skills sit at the plugin root, not under skills/.
skill "$H/.claude/plugins/cache/mkt/subdir/1.0.0/epsilon" "epsilon from the subset entry"
skill "$C/epsilon" "epsilon from a user copy"

cat >"$H/.claude/plugins/installed_plugins.json" <<JSON
{"version":2,"plugins":{
  "plug@mkt":[{"scope":"user","version":"2.0.0","installPath":"$H/.claude/plugins/cache/mkt/plug/2.0.0"}],
  "subdir@mkt":[{"scope":"user","version":"1.0.0","installPath":"$H/.claude/plugins/cache/mkt/subdir/1.0.0"}]}}
JSON
cat >"$H/.claude/plugins/known_marketplaces.json" <<'JSON'
{"mkt":{"source":{"source":"github","repo":"x/y"},"installLocation":"/nowhere"}}
JSON
# Residue: a cache directory for a marketplace the registry no longer names.
mkdir -p "$H/.claude/plugins/cache/gone/old/1.0.0/skills/zeta"

# No codex on this PATH: the Codex pool is not reported, and nothing is added
# to a marketplace over the network.
BIN="$H/bin"
link_tools "$BIN" bash git jq sed awk grep find date readlink basename dirname \
  mv ln mkdir cp cat sha256sum
out="$(env HOME="$H" CODEX_HOME="$H/.codex" PATH="$BIN" /bin/bash "$DOCTOR" 2>&1 || true)"

printf '%s\n' "$out" | grep -q 'NOTE: Claude: skill beta resolves to 2 different trees' \
  || fail "the doctor did not report beta:"$'\n'"$out"
printf '%s\n' "$out" | grep -q 'NOTE: Claude: skill epsilon resolves to 2 different trees' \
  || fail "the doctor did not see a git-subdir cache whose skills sit at its root:"$'\n'"$out"
for quiet in alpha gamma delta; do
  printf '%s\n' "$out" | grep -q "skill $quiet resolves" \
    && fail "the doctor reported $quiet, a measured false positive:"$'\n'"$out"
done
printf '%s\n' "$out" | grep -q "NOTE: plugin cache for an unregistered marketplace: $H/.claude/plugins/cache/gone" \
  || fail "the doctor did not report the unregistered cache:"$'\n'"$out"
printf '%s\n' "$out" | grep -q "unregistered marketplace: $H/.claude/plugins/cache/mkt" \
  && fail "the doctor reported a registered marketplace's cache as unregistered"
printf '%s\n' "$out" | grep -q 'NOTE: Codex:' \
  && fail "the Codex pool was reported with no codex on PATH"
printf '%s\n' "$out" | grep -q 'FAIL:.*resolves' \
  && fail "a duplicate finding was reported as FAIL:, not NOTE: -- report, never repair:"$'\n'"$out"

# The all-clear says how many trees it hashed (#40): trees hashed, not
# passed, so a SKILL.md sha256sum could not read lowers the count instead
# of hiding inside it. A second HOME with two distinct skills and no
# duplicate.
H2="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$H" "$H2"' EXIT
mkdir -p "$H2/.agents/skills" || fail "could not seed $H2"
skill "$H2/.agents/skills/alpha" "alpha alone"
skill "$H2/.agents/skills/beta" "beta alone"
out="$(env HOME="$H2" CODEX_HOME="$H2/.codex" PATH="$BIN" /bin/bash "$DOCTOR" 2>&1 || true)"
printf '%s\n' "$out" | grep -q 'NOTE: Claude: 2 skill tree(s) hashed; no name resolves to more than one tree' \
  || fail "the Claude all-clear does not say how many trees it hashed:"$'\n'"$out"

# The Codex all-clear is conditional on the pool being complete, not on codex being
# on PATH (#40): with codex present and `codex plugin list --json` failing,
# the FAIL line stands and no all-clear is printed over a pool missing its
# plugin half. A stub codex that exits 1 is that machine. The stub prints
# partial JSON before it fails, because a failed command's stdout is still
# captured by $(...).
printf '#!/usr/bin/env bash\nprintf '"'"'{"installed":[\\n'"'"'\nexit 1\n' >"$BIN/codex" || fail "could not write the codex stub"
chmod +x "$BIN/codex" || fail "could not make the codex stub executable"
out="$(env HOME="$H2" CODEX_HOME="$H2/.codex" PATH="$BIN" /bin/bash "$DOCTOR" 2>&1 || true)"
printf '%s\n' "$out" | grep -q 'FAIL: codex plugin list failed' \
  || fail "a failing codex plugin list was not reported:"$'\n'"$out"
printf '%s\n' "$out" | grep -q 'NOTE: Codex:' \
  && fail "the Codex pool was reported over a failed codex plugin list:"$'\n'"$out"
rm -f "$BIN/codex"

# The other half of that gate: a codex whose `plugin list --json` succeeds.
# Without one nothing in the suite executes a single iteration of the Codex tab
# loop, so nothing asserts its field indices or its malformed-field guard, and
# the complete-pool gate is only ever seen shut. Two valid entries, each with a
# skill under the cache path the loop builds from marketplace, name and
# version, and a third with an empty version for the guard. The pool then holds
# four trees -- the two under $HOME/.agents/skills, which Codex reads directly,
# plus one from each valid entry's cache -- and the count is what says both
# entries were iterated and the path was built from the right three fields.
mkdir -p "$H2/.codex/plugins/cache" || fail "could not seed the codex plugin cache"
skill "$H2/.codex/plugins/cache/mkt/theta/1.0.0/skills/gamma" "gamma as the theta plugin ships it"
skill "$H2/.codex/plugins/cache/mkt/iota/2.0.0/skills/delta" "delta as the iota plugin ships it"
cat >"$BIN/codex" <<'STUB' || fail "could not write the succeeding codex stub"
#!/usr/bin/env bash
# Check mode reaches `plugin list --json` and no other codex verb.
cat <<'JSON'
{"installed":[
  {"pluginId":"theta@mkt","marketplaceName":"mkt","name":"theta","version":"1.0.0","enabled":true},
  {"pluginId":"iota@mkt","marketplaceName":"mkt","name":"iota","version":"2.0.0","enabled":true},
  {"pluginId":"kappa@mkt","marketplaceName":"mkt","name":"kappa","version":"","enabled":true}
]}
JSON
STUB
chmod +x "$BIN/codex" || fail "could not make the codex stub executable"
out="$(env HOME="$H2" CODEX_HOME="$H2/.codex" PATH="$BIN" /bin/bash "$DOCTOR" 2>&1 || true)"
printf '%s\n' "$out" | grep -qF "FAIL: a codex plugin list entry is malformed: marketplace='mkt' name='kappa' version=''" \
  || fail "an entry with an empty version was not reported as malformed:"$'\n'"$out"
printf '%s\n' "$out" | grep -qF 'NOTE: Codex: 4 skill tree(s) hashed; no name resolves to more than one tree' \
  || fail "the Codex pool is not the two trees under .agents/skills plus one from each valid entry's cache:"$'\n'"$out"
rm -f "$BIN/codex"

printf 'doctor-duplicates: one Claude duplicate and one residue reported; three false positives quiet; a Codex pool of 4 over a succeeding codex plugin list\n'
