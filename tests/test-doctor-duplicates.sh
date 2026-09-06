#!/usr/bin/env bash
# bin/doctor must report one skill name reaching two different trees on one
# harness, and a Claude plugin cache whose marketplace is not registered, and
# must stay quiet on the three false positives spec section 6.6 measured: the
# same content under two paths, a superseded plugin version, and the same
# name differing only across harnesses. Needs no network and no CLI: every
# route is filesystem state plus the two registry files.
. "$(dirname "$0")/lib.sh"

DOCTOR="$REPO_ROOT/bin/doctor"
H="$(mktemp -d)"
trap 'rm -rf "$H"' EXIT
A="$H/.agents/skills"; C="$H/.claude/skills"; X="$H/.codex/skills"
mkdir -p "$A" "$C" "$X" "$H/.claude/plugins" || fail "could not seed $H"

skill() { mkdir -p "$1" && printf -- '---\nname: %s\n---\n%s\n' "$(basename "$1")" "$2" > "$1/SKILL.md"; }

# alpha: one tree, two paths. Same content, so not a finding.
skill "$A/alpha" "alpha body"
ln -s "$A/alpha" "$C/alpha"

# beta: two trees on Claude. The finding.
skill "$A/beta" "beta as skills.sh installs it"
skill "$H/.claude/plugins/cache/mkt/plug/2.0.0/skills/beta" "beta as the plugin ships it"

# gamma: differs only in a superseded plugin version, which is not current.
skill "$A/gamma" "gamma current"
skill "$H/.claude/plugins/cache/mkt/plug/1.0.0/skills/gamma" "gamma old"

# delta: differs only across harnesses. Not a finding on either.
skill "$C/delta" "delta on claude"
skill "$X/delta" "delta on codex"

# A git-subdir cache whose skills sit at the plugin root, not under skills/.
skill "$H/.claude/plugins/cache/mkt/subdir/1.0.0/epsilon" "epsilon from the curated entry"
skill "$C/epsilon" "epsilon from a user copy"

cat > "$H/.claude/plugins/installed_plugins.json" <<JSON
{"version":2,"plugins":{
  "plug@mkt":[{"scope":"user","version":"2.0.0","installPath":"$H/.claude/plugins/cache/mkt/plug/2.0.0"}],
  "subdir@mkt":[{"scope":"user","version":"1.0.0","installPath":"$H/.claude/plugins/cache/mkt/subdir/1.0.0"}]}}
JSON
cat > "$H/.claude/plugins/known_marketplaces.json" <<'JSON'
{"mkt":{"source":{"source":"github","repo":"x/y"},"installLocation":"/nowhere"}}
JSON
# Residue: a cache directory for a marketplace the registry no longer names.
mkdir -p "$H/.claude/plugins/cache/gone/old/1.0.0/skills/zeta"

# No codex on this PATH: the Codex pool is not reported, and nothing is added
# to a marketplace over the network.
BIN="$H/bin"
mkdir -p "$BIN"
for t in bash git jq sed awk grep find date readlink basename dirname \
         mv ln mkdir cp cat sha256sum; do
  p="$(command -v "$t" 2>/dev/null)" || fail "the fixture needs $t on PATH"
  ln -sf "$p" "$BIN/$t"
done
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

printf 'doctor-duplicates: one Claude duplicate and one residue reported; three false positives quiet\n'
