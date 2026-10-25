#!/usr/bin/env bash
# test.sh <core|specs|contracts|all> [spec-number]
# Runs the test commands configured in .harness.env (TEST_CORE_CMD, TEST_SPECS_CMD,
# TEST_CONTRACTS_CMD). Fails closed: the core group has no command until /start creates
# the first acceptance test, and that is an error, never a green.
# In TEST_SPECS_CMD, {spec} is replaced by the folder name under acceptance/specs/
# (when a spec number is given) or by * (all specs).
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$here/.."
# shellcheck source=lib/env.sh
. "$here/lib/env.sh"

group="${1:-all}"
spec="${2:-}"

run_group() { # run_group <name> <key> <required: 0|1>
  local name="$1" key="$2" required="$3" cmd dir
  cmd="$(env_get "$key" "")"
  if [ -z "$cmd" ]; then
    if [ "$required" = "1" ]; then
      echo "test: $key is empty in .harness.env. Run /start to create the first acceptance test." >&2
      return 2
    fi
    echo "test: $name skipped ($key is empty)"
    return 0
  fi
  if [ "$name" = "specs" ]; then
    if [ -n "$spec" ]; then
      dir="$(printf '%s\n' acceptance/specs/"$spec"-* | head -n1)"
      if [ ! -d "$dir" ]; then
        echo "test: no folder acceptance/specs/${spec}-*" >&2
        return 2
      fi
      cmd="${cmd//\{spec\}/$(basename "$dir")}"
    else
      cmd="${cmd//\{spec\}/*}"
    fi
  fi
  echo "== $name: $cmd"
  bash -c "$cmd"
}

case "$group" in
  core)      run_group core TEST_CORE_CMD 1 ;;
  specs)     run_group specs TEST_SPECS_CMD 0 ;;
  contracts) run_group contracts TEST_CONTRACTS_CMD 0 ;;
  all)
    rc=0
    run_group core TEST_CORE_CMD 1 || rc=1
    run_group specs TEST_SPECS_CMD 0 || rc=1
    run_group contracts TEST_CONTRACTS_CMD 0 || rc=1
    exit "$rc"
    ;;
  *)
    echo "usage: scripts/test.sh <core|specs|contracts|all> [spec-number]" >&2
    exit 64
    ;;
esac
