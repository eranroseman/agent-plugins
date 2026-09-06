#!/usr/bin/env bash
# bin/doctor must report each seeded fault by name against a scratch HOME, and
# bin/setup must repair it. The assertions check that the named lines appear,
# not that they are the only ones. Needs no network and no CLI: every fault is
# filesystem or git state.
. "$(dirname "$0")/lib.sh"

DOCTOR="$REPO_ROOT/bin/doctor"
SETUP="$REPO_ROOT/bin/setup"
H="$(mktemp -d)"
trap 'rm -rf "$H"' EXIT

CLONE="$H/.local/share/software-development/upstream/superpowers"
SKILLS="$H/.agents/skills"
mkdir -p "$CLONE" "$SKILLS" || fail "could not seed $H"

# A clone at the wrong sha: an empty repository with one commit has a HEAD
# that cannot be the declared one, and needs no network.
git -C "$CLONE" init -q || fail "git init failed in $CLONE"
git -C "$CLONE" -c user.email=t@example.com -c user.name=t \
  commit -q --allow-empty -m seed || fail "could not seed a commit"
while IFS= read -r s; do
  mkdir -p "$CLONE/skills/$s"
done < <(jq -r '.plugins[] | select(.name == "superpowers") | .skills[]' "$MARKETPLACE" | sed 's#^\./##')

ln -s "$H/nowhere" "$SKILLS/writing-plans"            # dangling
mkdir -p "$SKILLS/executing-plans"                    # a directory where a link belongs
printf 'squat\n' > "$SKILLS/writing-skills"           # a regular file where a link belongs

# A lockfile entry with no ref: the state every skills.sh install is in today.
mkdir -p "$H/.agents"
cat > "$H/.agents/.skill-lock.json" <<'JSON'
{
  "version": 3,
  "skills": {
    "grilling": {
      "source": "mattpocock/skills",
      "sourceType": "github",
      "sourceUrl": "https://github.com/mattpocock/skills.git",
      "skillPath": "skills/productivity/grilling/SKILL.md"
    }
  },
  "dismissed": {}
}
JSON

if out="$(env HOME="$H" CODEX_HOME="$H/.codex" bash "$DOCTOR" 2>&1)"; then status=0; else status=$?; fi
[ "$status" -eq 1 ] || fail "doctor exited $status on a machine with five seeded faults"

for pat in \
  'pinned clone is at' \
  'dangling link' \
  'executing-plans exists and is not a symlink' \
  'writing-skills exists and is not a symlink' \
  'lockfile entry for grilling records no ref'
do
  printf '%s\n' "$out" | grep -q "$pat" || fail "doctor did not report: $pat"
done
printf '%s\n' "$out" | grep -q 'FAIL' || fail "doctor reported no FAIL line"

# Repair. Three things keep this run local, because a test in tests/run.sh must
# not clone a marketplace or install nineteen skills over the network:
#   - a bin directory without codex, so that half reports skipped rather than
#     adding a marketplace;
#   - an installed_plugins.json already carrying the declared versions, so the
#     Claude half reports OK without acting;
#   - a fully pinned lockfile, so the skills.sh half reports OK without acting.
#     The unpinned entry seeded above was for the check pass only.
# The clone still cannot be repaired without a network: the seeded repository
# has no origin, so the fetch fails at once and the clone stays reported.
# Every external the engine runs has to be here, or a repair fails for the
# wrong reason: with `rm` missing, the dangling link survives and the test
# reports a wrong target rather than a missing tool.
BIN="$H/bin"
mkdir -p "$BIN"
for t in bash git jq node npx claude sed awk grep find date readlink basename dirname \
         rm mv ln mkdir cp cat; do
  p="$(command -v "$t" 2>/dev/null)" || fail "the fixture needs $t on PATH"
  ln -sf "$p" "$BIN/$t"
done
if [ ! -x "$BIN/claude" ]; then
  printf 'SKIP: claude is not installed, so the repair half cannot run\n'
  printf 'doctor-faults: seeded faults reported; the repair half was not exercised\n'
  exit 0
fi
mkdir -p "$H/.claude/plugins"
sd="$(jq -r .version "$REPO_ROOT/plugins/software-development/.claude-plugin/plugin.json")"
sm="$(jq -r .version "$REPO_ROOT/plugins/sensemaking/.claude-plugin/plugin.json")"
sp="$(jq -r '.plugins[] | select(.name == "superpowers") | .version' "$MARKETPLACE")"
cat > "$H/.claude/plugins/installed_plugins.json" <<JSON
{"version":2,"plugins":{
  "software-development@eranroseman":[{"scope":"user","version":"$sd"}],
  "sensemaking@eranroseman":[{"scope":"user","version":"$sm"}],
  "superpowers@eranroseman":[{"scope":"user","version":"$sp"}]}}
JSON
jq '{version: 3,
     skills: (reduce (.sources[] as $s | $s.skills[] |
       {key: ., value: {source: $s.repo, ref: $s.ref}}) as $e ({}; . + {($e.key): $e.value})),
     dismissed: {}}' \
  "$REPO_ROOT/upstream/skills.json" > "$H/.agents/.skill-lock.json" \
  || fail "could not synthesise a pinned lockfile"

if out="$(env HOME="$H" CODEX_HOME="$H/.codex" PATH="$BIN" /bin/bash "$SETUP" 2>&1)"; then status=0; else status=$?; fi
[ "$status" -eq 1 ] || fail "bin/setup exited $status; the re-check must run and report the unrepairable clone"
printf '%s\n' "$out" | grep -q -- '--- re-checking ---' || fail "bin/setup did not re-check after applying"
[ -L "$SKILLS/writing-plans" ] || fail "the dangling link was not replaced"
[ "$(readlink -f "$SKILLS/writing-plans")" = "$CLONE/skills/writing-plans" ] \
  || fail "the repaired link points elsewhere"
[ -L "$SKILLS/writing-skills" ] || fail "the squatting file was not replaced by a link"
ls "$SKILLS" | grep -q 'aside' || fail "nothing was moved aside; squatters must be kept, not deleted"

printf 'doctor-faults: five seeded faults reported and the local ones repaired\n'
