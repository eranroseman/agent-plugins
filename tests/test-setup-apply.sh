#!/usr/bin/env bash
# The apply block of the Claude half and the whole Codex half, which no
# fixture had driven (#17): a subset entry one version behind moves under
# `claude plugin update`; an entry missing from the registry is installed by
# name; and with codex present, `marketplace upgrade eranroseman`, `plugin
# add` and the second `plugin list --json` run in order. Each CLI is a stub
# that edits the same registry file the engine reads back, so the DID line
# is a re-read and the re-check's OK line is the proof. Needs no network:
# every clone is seeded at a wrong sha with no origin, so the clone check
# fails locally and nothing else reaches out.
. "$(dirname "$0")/lib.sh"

SETUP="$REPO_ROOT/bin/setup"
T="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$T"' EXIT

sd="$(jq -r .version "$REPO_ROOT/plugins/software-dev/.claude-plugin/plugin.json")"
sm="$(jq -r .version "$REPO_ROOT/plugins/sensemaking/.claude-plugin/plugin.json")"
sp="$(jq -r '.plugins[] | select(.name == "superpowers") | .version' "$MARKETPLACE")"
wcc="$(jq -r '.plugins[] | select(.name == "writing-clearly-and-concisely") | .version' "$MARKETPLACE")"

# A HOME whose clones exist at a sha that cannot be the declared one, with
# every skill directory present so the links have targets, and a lockfile
# pinned at the declared refs so the skills.sh half runs no command.
seed_home() {
  local h="$1" name path skill dir
  mkdir -p "$h/.agents/skills" "$h/.claude/plugins" "$h/.codex" || fail "could not seed $h"
  while IFS="$(printf '\t')" read -r name path skill; do
    [ -n "$name" ] || continue
    dir="$h/.local/share/software-dev/upstream/$name"
    if [ ! -d "$dir/.git" ]; then
      mkdir -p "$dir" || fail "could not seed $dir"
      git -C "$dir" init -q || fail "git init failed in $dir"
      git -C "$dir" -c user.email=t@example.com -c user.name=t \
        commit -q --allow-empty -m seed || fail "could not seed a commit in $dir"
    fi
    mkdir -p "$dir/$path/$skill"
  done < <(jq -r '.plugins[] | select(.source.source? == "git-subdir") as $p
                  | $p.skills[] | [$p.name, $p.source.path, (. | sub("^\\./"; ""))] | @tsv' "$MARKETPLACE")
  jq '{version: 3,
       skills: (reduce (.sources[] as $s | $s.skills[] |
         {key: ., value: {source: $s.repo, ref: $s.ref}}) as $e ({}; . + {($e.key): $e.value})),
       dismissed: {}}' "$REPO_ROOT/skills.json" >"$h/.agents/.skill-lock.json" \
    || fail "could not synthesize a pinned lockfile"
  printf '{"eranroseman":{"source":{"source":"github","repo":"eranroseman/agent-plugins"},"installLocation":"%s"}}\n' "$h/mkt" \
    >"$h/.claude/plugins/known_marketplaces.json" || fail "could not write known_marketplaces.json"
}

# The registry the claude stub edits: $1 the HOME, then name=version pairs.
write_registry() {
  local h="$1" body="" pair
  shift
  for pair in "$@"; do
    body="$body${body:+,}\"${pair%%=*}@eranroseman\":[{\"scope\":\"user\",\"version\":\"${pair#*=}\",\"installPath\":\"$h/.claude/plugins/cache/eranroseman/${pair%%=*}/${pair#*=}\"}]"
  done
  printf '{"version":2,"plugins":{%s}}\n' "$body" >"$h/.claude/plugins/installed_plugins.json" \
    || fail "could not write installed_plugins.json"
}

# A fixture PATH: the engine's own tools, a node that is never reached, an
# npx that must not be (the lockfile is pinned), and the two stubs.
fixture_bin() {
  local b="$1"
  link_tools "$b" bash git jq grep find date readlink basename dirname cut rm mv ln mkdir cat sha256sum
  printf '#!/usr/bin/env bash\nexit 1\n' >"$b/node" || fail "could not write the node stub"
  printf '#!/usr/bin/env bash\nexit 1\n' >"$b/npx" || fail "could not write the npx stub"
  chmod +x "$b/node" "$b/npx" || fail "could not make the stubs executable"
}

# The claude stub: answers --version; `plugin update X@eranroseman` sets X's
# registry version to the declared one; `plugin install X@eranroseman` adds
# X at the declared version. Anything else exits 1 and is a visible FAIL.
write_claude_stub() {
  cat >"$1/claude" <<'STUB' || fail "could not write the claude stub"
#!/usr/bin/env bash
reg="$HOME/.claude/plugins/installed_plugins.json"
declared() {
  case "$1" in
    software-dev | sensemaking) jq -r .version "$REPO/plugins/$1/.claude-plugin/plugin.json" ;;
    *) jq -r --arg n "$1" '.plugins[] | select(.name == $n) | .version' "$REPO/.claude-plugin/marketplace.json" ;;
  esac
}
case "$1 $2" in
  '--version ') printf '2.1.273 (Claude Code)\n' ;;
  'plugin update')
    name="${3%@eranroseman}"
    v="$(declared "$name")"
    jq --arg k "$3" --arg v "$v" '.plugins[$k][0].version = $v' "$reg" >"$reg.new" && mv "$reg.new" "$reg"
    ;;
  'plugin install')
    name="${3%@eranroseman}"
    v="$(declared "$name")"
    jq --arg k "$3" --arg v "$v" --arg p "$HOME/.claude/plugins/cache/eranroseman/$name/$v" \
      '.plugins[$k] = [{scope: "user", version: $v, installPath: $p}]' "$reg" >"$reg.new" && mv "$reg.new" "$reg"
    ;;
  *) exit 1 ;;
esac
STUB
  chmod +x "$1/claude" || fail "could not make the claude stub executable"
}

# The codex stub, stateful through $CODEX_HOME/state: `plugin marketplace
# list` names eranroseman, so the engine takes the upgrade branch;
# `marketplace upgrade eranroseman` and `plugin add` each record themselves;
# `plugin list --json` reports 0.0.1 until an add has run, then the declared
# version. Anything else exits 1.
write_codex_stub() {
  cat >"$1/codex" <<'STUB' || fail "could not write the codex stub"
#!/usr/bin/env bash
state="$CODEX_HOME/state"
mkdir -p "$state"
version_of() {
  if [ -f "$state/added-$1" ]; then
    jq -r .version "$REPO/plugins/$1/.codex-plugin/plugin.json"
  else
    printf '0.0.1'
  fi
}
case "$*" in
  '--version') printf 'codex-cli 0.147.0\n' ;;
  'plugin marketplace list') printf 'MARKETPLACE  ROOT\neranroseman  /nowhere\n' ;;
  'plugin marketplace upgrade eranroseman') : >"$state/upgraded" ;;
  'plugin add software-dev@eranroseman' | 'plugin add sensemaking@eranroseman')
    : >"$state/added-${3%@eranroseman}"
    ;;
  'plugin list --json')
    printf '{"installed":[{"pluginId":"software-dev@eranroseman","marketplaceName":"eranroseman","name":"software-dev","version":"%s","enabled":true},{"pluginId":"sensemaking@eranroseman","marketplaceName":"eranroseman","name":"sensemaking","version":"%s","enabled":true}]}\n' \
      "$(version_of software-dev)" "$(version_of sensemaking)"
    ;;
  *) exit 1 ;;
esac
STUB
  chmod +x "$1/codex" || fail "could not make the codex stub executable"
}

run_apply() { # $1 HOME, $2 PATH dir; leaves the output in OUT
  OUT="$(env HOME="$1" CODEX_HOME="$1/.codex" REPO="$REPO_ROOT" PATH="$2" /bin/bash "$SETUP" 2>&1 || true)"
}
saw() { printf '%s\n' "$OUT" | grep -qF -- "$1"; }

# 1. A subset entry one version behind: the update branch.
H1="$T/home-1"
seed_home "$H1"
write_registry "$H1" "software-dev=$sd" "sensemaking=$sm" "superpowers=0.0.1" "writing-clearly-and-concisely=$wcc"
B1="$T/bin-1"
fixture_bin "$B1"
write_claude_stub "$B1"
run_apply "$H1" "$B1"
saw "DID:  superpowers@eranroseman is now $sp" || fail "update branch: no DID line for superpowers:"$'\n'"$OUT"
[ "$(printf '%s\n' "$OUT" | grep -c "OK:   superpowers@eranroseman $sp installed")" -ge 1 ] \
  || fail "update branch: the re-check did not report superpowers at $sp:"$'\n'"$OUT"
saw 'SKIP: codex is not on PATH' || fail "update branch: the Codex half was not skipped with no codex:"$'\n'"$OUT"

# 2. A subset entry missing from the registry: the install branch.
H2="$T/home-2"
seed_home "$H2"
write_registry "$H2" "software-dev=$sd" "sensemaking=$sm" "superpowers=$sp"
run_apply "$H2" "$B1"
saw 'DID:  installed writing-clearly-and-concisely@eranroseman' || fail "install branch: no DID line:"$'\n'"$OUT"
[ "$(printf '%s\n' "$OUT" | grep -c "OK:   writing-clearly-and-concisely@eranroseman $wcc installed")" -ge 1 ] \
  || fail "install branch: the re-check did not report the entry installed:"$'\n'"$OUT"

# 3. Codex present: upgrade, add, and the second list read, in order.
H3="$T/home-3"
seed_home "$H3"
write_registry "$H3" "software-dev=$sd" "sensemaking=$sm" "superpowers=$sp" "writing-clearly-and-concisely=$wcc"
B3="$T/bin-3"
fixture_bin "$B3"
write_claude_stub "$B3"
write_codex_stub "$B3"
run_apply "$H3" "$B3"
[ -f "$H3/.codex/state/upgraded" ] || fail "codex: marketplace upgrade eranroseman never ran:"$'\n'"$OUT"
for p in software-dev sensemaking; do
  [ -f "$H3/.codex/state/added-$p" ] || fail "codex: plugin add did not run for $p:"$'\n'"$OUT"
done
saw "DID:  installed codex plugin software-dev $sd" || fail "codex: no DID line for software-dev:"$'\n'"$OUT"
saw "DID:  installed codex plugin sensemaking $sm" || fail "codex: no DID line for sensemaking:"$'\n'"$OUT"
[ "$(printf '%s\n' "$OUT" | grep -c "OK:   codex plugin software-dev $sd installed")" -ge 1 ] \
  || fail "codex: the re-check did not report software-dev installed:"$'\n'"$OUT"

printf 'setup-apply: the update and install branches of the Claude half and the Codex half ran under stateful stubs\n'
