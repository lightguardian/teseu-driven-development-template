#!/usr/bin/env bash
# arch-check.sh
# Cheap fitness functions for the layer rules (see docs/architecture.md):
#   1. core/ imports nothing from adapters/ or app/ (it may use ports/)
#   2. ports/ import nothing from core/, adapters/ or app/
#   3. adapters/ import nothing from app/
#   4. acceptance tests never import product code
# Imports are detected line by line (import, from, use, using, #include, extern crate,
# require(...), import(...)). That catches the usual slips in most languages; it is
# a guardrail, not a parser. Exit 0 = ok, 1 = violation, 2 = layers folder missing.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$here/.."
# shellcheck source=lib/env.sh
. "$here/lib/env.sh"

layers="$(env_get LAYERS_DIR src)"
if [ ! -d "$layers/core" ]; then
  echo "arch: $layers/core not found (check LAYERS_DIR in .harness.env)" >&2
  exit 2
fi

p_line='^[[:space:]]*(import|from|use|using|#include|extern[[:space:]]+crate)[[:space:]]'
p_call='(require|import)[[:space:]]*\('

violations=0

# check <dir> <description> <forbidden regex fragment>
check() {
  local dir="$1" why="$2" word="$3" f out
  [ -d "$dir" ] || return 0
  while IFS= read -r f; do
    out="$(grep -InE -e "$p_line" -e "$p_call" "$f" 2>/dev/null \
      | grep -E "(^|[^[:alnum:]_])${word}([^[:alnum:]_]|\$)" || true)"
    if [ -n "$out" ]; then
      while IFS= read -r line; do
        echo "arch: violation: $f:${line%%:*}: $why" >&2
        violations=$((violations + 1))
      done <<< "$out"
    fi
  done < <(find "$dir" -type f ! -name README.md)
}

for layer in adapters app; do
  check "$layers/core" "core must not depend on $layer" "$layer"
done
for layer in core adapters app; do
  check "$layers/ports" "ports must not depend on $layer" "$layer"
done
check "$layers/adapters" "adapters must not depend on app" "app"

layers_re="$(printf '%s' "$layers" | sed 's#[][\\.*^$/+?(){}|]#\\&#g')"
check "acceptance" "acceptance tests must not import product code" "$layers_re"

if [ -z "$(find acceptance/core -type f ! -name README.md 2>/dev/null | head -n1)" ]; then
  echo "arch: warning: acceptance/core has no tests yet (run /start)"
fi

if [ "$violations" -gt 0 ]; then
  echo "arch: $violations violation(s)" >&2
  exit 1
fi
echo "arch: ok"
