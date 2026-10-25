#!/usr/bin/env bash
# env_get KEY DEFAULT
# Reads KEY from .harness.env ONLY. The process environment is ignored on purpose,
# so "REVIEW_BEFORE_COMMIT=false git commit" cannot lower the harness rules.
env_get() {
  local key="$1" def="${2-}" root file val=""
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  file="$root/.harness.env"
  if [ -f "$file" ]; then
    val="$(grep -E "^[[:space:]]*${key}=" "$file" | tail -n1 | cut -d= -f2- \
      | sed -e 's/[[:space:]]*#.*$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
            -e 's/^"//' -e 's/"$//')" || true
  fi
  if [ -z "$val" ]; then printf '%s' "$def"; else printf '%s' "$val"; fi
}
