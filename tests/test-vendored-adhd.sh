#!/usr/bin/env bash
# The vendored adhd skill must equal UditAkhourii/adhd at the pinned commit
# except: a provenance header right after the frontmatter, line 3 (the
# description, shortened so Codex shows it whole), an added line 5 carrying
# Claude's invocation gate, and an added agents/openai.yaml carrying Codex's.
# Gated on both harnesses because its cost is the operator's call (spec
# section 6.2). Needs network access.
. "$(dirname "$0")/lib.sh"

V="$REPO_ROOT/plugins/sensemaking/skills/adhd"
[ -d "$V" ] || fail "missing $V"

# The repository's HEAD on 2026-09-06. Its only tag, v0.1.4, dates from
# 2026-05-30 and predates both this SKILL.md text and the plugin manifest,
# so the pin is a commit.
SHA="16dc239ff186b869372e75095cfa58fc0ee89927"
UP="$(fetch_pinned https://github.com/UditAkhourii/adhd.git "$SHA" \
  "${TMPDIR:-/tmp}/software-dev-upstream-adhd")"
U="$UP/skills/adhd"
[ -f "$U/SKILL.md" ] || fail "upstream has no skills/adhd/SKILL.md at $SHA"

# Upstream ships one file; ours adds the Codex policy file and nothing else.
diff <(cd "$U" && find . -type f | sort; printf './agents/openai.yaml\n' | sort) \
     <(cd "$V" && find . -type f | sort) \
  || fail "file set is not upstream's plus agents/openai.yaml"

# Frontmatter: lines 1, 2 and 4 are upstream's; 3 is ours; 5 is the gate; 6 closes.
diff <(sed -n '1,2p;4p' "$U/SKILL.md") <(sed -n '1,2p;4p' "$V/SKILL.md") \
  || fail "the frontmatter fences, name or license line were edited"
[ "$(sed -n 4p "$U/SKILL.md")" = "license: MIT" ] || fail "upstream frontmatter shape changed; re-audit the vendoring"
want='description: Parallel divergent ideation under five isolated cognitive frames, scored, clustered, deepened. Costs 5 to 10x one answer.'
[ "$(sed -n 3p "$V/SKILL.md")" = "$want" ] || fail "line 3 is not the shortened description, verbatim"
desc="${want#description: }"
[ "${#desc}" -le 122 ] || fail "the description is ${#desc} characters; Codex truncates at 122"
[ "$(sed -n 5p "$V/SKILL.md")" = "disable-model-invocation: true" ] \
  || fail "line 5 must carry Claude's gate, disable-model-invocation: true"
[ "$(sed -n 6p "$V/SKILL.md")" = "---" ] || fail "line 6 is not the closing frontmatter fence"
grep -qx '  allow_implicit_invocation: false' "$V/agents/openai.yaml" \
  || fail "agents/openai.yaml must carry Codex's gate, allow_implicit_invocation: false"

# Lines 7-12: the whole provenance header, verbatim.
expected_header="$(printf '%s\n' \
  "<!-- Vendored from https://github.com/UditAkhourii/adhd at commit $SHA" \
  "     path: skills/adhd/ (the repository's only skill; its tag v0.1.4 predates this text and the plugin manifest)" \
  "     MIT, (c) 2026 ADHD contributors. Local changes: the description above, shortened to 121 characters so" \
  "     Codex shows it whole, and the invocation gate, disable-model-invocation: true, paired with" \
  "     policy.allow_implicit_invocation: false in agents/openai.yaml. Nothing else is edited." \
  "-->")"
[ "$(sed -n 7,12p "$V/SKILL.md")" = "$expected_header" ] || fail "lines 7-12 are not the provenance header"

# Body: upstream minus its line 3 equals ours minus lines 3, 5 and 7-12.
diff <(sed '3d' "$U/SKILL.md") <(sed -e '3d' -e '5d' -e '7,12d' "$V/SKILL.md") \
  || fail "SKILL.md changed beyond the header, the description and the gate"

# The LICENSE's provenance notice names the same commit.
grep -q "at commit $SHA)" "$REPO_ROOT/plugins/sensemaking/LICENSE" \
  || fail "LICENSE provenance does not name commit $SHA"
grep -q "Copyright (c) 2026 ADHD contributors" "$REPO_ROOT/plugins/sensemaking/LICENSE" \
  || fail "LICENSE lacks upstream's copyright line"

printf 'vendored-adhd: matches UditAkhourii/adhd %s except header, description (%s chars) and the two gates\n' "$SHA" "${#desc}"
