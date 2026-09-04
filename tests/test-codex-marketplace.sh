#!/usr/bin/env bash
# The Codex marketplace must expose exactly the two local plugins, point each
# at a directory that carries a matching Codex manifest, and agree with the
# Claude marketplace on names. superpowers has no Codex entry: it arrives by
# symlink because Codex cannot subset a plugin's skills.
. "$(dirname "$0")/lib.sh"

M="$REPO_ROOT/.agents/plugins/marketplace.json"
[ -f "$M" ] || fail "missing $M"

[ "$(jq -r '.name' "$M")" = "eranroseman" ] || fail "marketplace name"
[ "$(jq -r '.interface.displayName' "$M")" = "Eran Roseman" ] || fail "displayName"
[ "$(jq '.plugins | length' "$M")" -eq 2 ] || fail "expected exactly 2 plugins"

for i in 0 1; do
  name="$(jq -r ".plugins[$i].name" "$M")"
  [ "$(jq -r ".plugins[$i].source.source" "$M")" = "local" ] || fail "$name: source.source must be local"
  path="$(jq -r ".plugins[$i].source.path" "$M")"
  manifest="$REPO_ROOT/$path/.codex-plugin/plugin.json"
  [ -f "$manifest" ] || fail "$name: $path has no .codex-plugin/plugin.json"
  [ "$(jq -r '.name' "$manifest")" = "$name" ] || fail "$name: manifest name differs"
  [ "$(jq -c ".plugins[$i].policy" "$M")" = '{"installation":"AVAILABLE","authentication":"ON_INSTALL"}' ] || fail "$name: policy"
  [ -n "$(jq -r ".plugins[$i].category" "$M")" ] || fail "$name: category"
done

if jq -e '.plugins[] | select(.name == "superpowers")' "$M" >/dev/null; then
  fail "superpowers must not have a Codex entry"
fi

diff <(jq -r '.plugins[] | select(.source | type == "string") | .name' "$MARKETPLACE" | sort) \
     <(jq -r '.plugins[].name' "$M" | sort) \
  || fail "Claude and Codex marketplaces disagree on the local plugins"

echo "codex-marketplace: 2 local plugins, manifests match, no superpowers entry"
