#!/usr/bin/env bash
# The doctor reads the upstream watch's run history over the public API and
# says whether the watch is alive (spec §12, #24): OK under 48 hours with a
# successful conclusion; FAIL at 48 hours or more, on an empty run list, or
# on any other conclusion; SKIP, never a need, when curl is absent, the
# response is not 200, or the body does not parse, so the exit code is
# untouched. Needs no network: curl is a stub that answers from two
# variables, and it records its arguments so the token header can be
# asserted.
. "$(dirname "$0")/lib.sh"

DOCTOR="$REPO_ROOT/bin/doctor"
T="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$T"' EXIT

BIN="$T/bin"
link_tools "$BIN" bash git jq grep find date readlink basename dirname cut mv ln mkdir cat sha256sum
# The stub honours the one call shape the engine makes, `-w '\n%{http_code}'`
# last: it prints $CURL_BODY, a newline, then $CURL_CODE, and logs its
# arguments.
cat >"$BIN/curl" <<'STUB' || fail "could not write the curl stub"
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$CURL_LOG"
printf '%s\n%s' "$CURL_BODY" "$CURL_CODE"
STUB
chmod +x "$BIN/curl" || fail "could not make the curl stub executable"
NOCURL="$T/bin-nocurl"
link_tools "$NOCURL" bash git jq grep find date readlink basename dirname cut mv ln mkdir cat sha256sum

runs_url='https://github.com/eranroseman/agent-plugins/actions/workflows/upstream-watch.yml'
body() { # $1 created_at, $2 conclusion; an empty $1 is an empty list
  if [ -z "$1" ]; then
    printf '{"total_count":0,"workflow_runs":[]}'
  else
    printf '{"total_count":1,"workflow_runs":[{"created_at":"%s","conclusion":"%s"}]}' "$1" "$2"
  fi
}
# $1 body, $2 code, then env assignments; leaves the output in OUT.
run_doctor() {
  local b="$1" c="$2" h="$T/home-$RANDOM"
  shift 2
  mkdir -p "$h/.agents/skills" || fail "could not seed $h"
  OUT="$(env -u GITHUB_TOKEN HOME="$h" CODEX_HOME="$h/.codex" PATH="$BIN" CURL_BODY="$b" CURL_CODE="$c" CURL_LOG="$T/curl.log" "$@" /bin/bash "$DOCTOR" 2>&1 || true)"
}
saw() { printf '%s\n' "$OUT" | grep -qF -- "$1"; }

fresh="$(date -u -d '5 hours ago' +%Y-%m-%dT%H:%M:%SZ)"
stale="$(date -u -d '3 days ago' +%Y-%m-%dT%H:%M:%SZ)"

# 1. Fresh and successful: OK, with the age.
run_doctor "$(body "$fresh" success)" 200
saw 'OK:   the watch ran on schedule 5 hour(s) ago and succeeded' || fail "fresh: not OK with the age:"$'\n'"$OUT"

# 2. Stale: FAIL naming the age and the workflow page.
run_doctor "$(body "$stale" success)" 200
saw "FAIL: the watch's last scheduled run was 72 hours ago, over 48; see $runs_url" || fail "stale: not a FAIL:"$'\n'"$OUT"

# 3. An empty run list, and a failed conclusion: FAIL each.
run_doctor "$(body '' '')" 200
saw "FAIL: no completed scheduled run of the watch is on record; see $runs_url" || fail "empty list: not a FAIL:"$'\n'"$OUT"
run_doctor "$(body "$fresh" failure)" 200
saw "FAIL: the watch's last scheduled run concluded failure, not success; see $runs_url" || fail "failure: not a FAIL:"$'\n'"$OUT"

# 4. Not 200, a body that does not parse, and no curl at all: SKIP, and the
# verdict does not count them as unanswered.
run_doctor '{"message":"rate limited"}' 403
saw 'SKIP: the runs API answered 403, not 200; the watch'"'"'s freshness is unanswered' || fail "403: not a SKIP:"$'\n'"$OUT"
run_doctor 'not json' 200
saw "SKIP: the runs API's body did not parse; the watch's freshness is unanswered" || fail "bad body: not a SKIP:"$'\n'"$OUT"
printf '%s\n' "$OUT" | grep -q 'for want of:.*curl' && fail "curl was counted as a need:"$'\n'"$OUT"
h="$T/home-nocurl"
mkdir -p "$h/.agents/skills" || fail "could not seed $h"
OUT="$(env HOME="$h" CODEX_HOME="$h/.codex" PATH="$NOCURL" /bin/bash "$DOCTOR" 2>&1 || true)"
saw "SKIP: curl is not on PATH, so the watch's run history is unread" || fail "no curl: not a SKIP:"$'\n'"$OUT"
printf '%s\n' "$OUT" | grep -q 'for want of:.*curl' && fail "no curl: counted as a need, which it is not:"$'\n'"$OUT"

# 5. The token travels as a bearer header when set, and not otherwise.
: >"$T/curl.log"
run_doctor "$(body "$fresh" success)" 200 GITHUB_TOKEN=t0k3n
grep -q -- '-H Authorization: Bearer t0k3n' "$T/curl.log" || fail "the token was not sent as a bearer header: $(cat "$T/curl.log")"
: >"$T/curl.log"
run_doctor "$(body "$fresh" success)" 200
grep -q 'Authorization' "$T/curl.log" && fail "an Authorization header was sent with no token: $(cat "$T/curl.log")"

printf 'doctor-freshness: OK under 48 hours, FAIL on stale, empty or failed, SKIP without curl or a 200 body; the token is a bearer header\n'
