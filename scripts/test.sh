#!/usr/bin/env bash
# test.sh <core|features|specs|contracts|all> [spec-number]
# Runs the test commands configured in .harness.env. Fails closed: the core group has no
# command until /start creates the first acceptance test, and that is an error, never a green.
#
# Stage 1, black-box (the central tests):
#   core                 TEST_CORE_CMD       the pilot's test (acceptance/core)
#   features             TEST_FEATURES_CMD   the black-box tests of all the features
#   features NNNN        TEST_FEATURE_CMD    the black-box test of ONE feature; {spec} becomes S0001
# Stage 2, the language's own tests:
#   specs                TEST_SPECS_CMD      the tests of all the specs
#   specs NNNN           TEST_SPEC_CMD       the tests of ONE spec; {spec} becomes S0001
#   contracts            TEST_CONTRACTS_CMD  one suite per port, run against every adapter
#   all                  core, features, specs and contracts, in this order
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$here/.."
# shellcheck source=lib/env.sh
. "$here/lib/env.sh"

group="${1:-all}"
spec="${2:-}"

run_group() { # run_group <name> <key> <required: 0|1>
  local name="$1" key="$2" required="$3" cmd
  cmd="$(env_get "$key" "")"
  if [ -z "$cmd" ]; then
    if [ "$required" = "1" ]; then
      if [ "$key" = "TEST_CORE_CMD" ]; then
        echo "test: $key is empty in .harness.env. Run /start to create the first acceptance test." >&2
      else
        echo "test: $key is empty in .harness.env. Set it to the command that runs the tests of one spec." >&2
      fi
      return 2
    fi
    echo "test: $name skipped ($key is empty)"
    return 0
  fi
  cmd="${cmd//\{spec\}/S$spec}"
  echo "== $name: $cmd"
  bash -c "$cmd"
}

case "$group" in
  core) run_group core TEST_CORE_CMD 1 ;;
  features)
    if [ -n "$spec" ]; then
      run_group "feature S$spec" TEST_FEATURE_CMD 1
    else
      run_group features TEST_FEATURES_CMD 0
    fi
    ;;
  specs)
    if [ -n "$spec" ]; then
      run_group "spec S$spec" TEST_SPEC_CMD 1
    else
      run_group specs TEST_SPECS_CMD 0
    fi
    ;;
  contracts) run_group contracts TEST_CONTRACTS_CMD 0 ;;
  all)
    rc=0
    run_group core TEST_CORE_CMD 1 || rc=1
    run_group features TEST_FEATURES_CMD 0 || rc=1
    run_group specs TEST_SPECS_CMD 0 || rc=1
    run_group contracts TEST_CONTRACTS_CMD 0 || rc=1
    exit "$rc"
    ;;
  *)
    echo "usage: scripts/test.sh <core|features|specs|contracts|all> [spec-number]" >&2
    exit 64
    ;;
esac
