#!/usr/bin/env bash
# evidence.sh <red|green|review|refactor> <core|NNNN|swap> [note]
#
# Runs the right tests for one phase of the TDD cycle, checks that the result is the
# expected one and appends the proof to the "## Evidence" section of PILOT.md (core),
# of specs/NNNN-*.md (a spec) or of PLANKS.md (swap). Nothing is recorded when the
# expectation is not met.
#
#   red       the new tests FAIL (and the core still passes); needs a note: why it fails.
#             Which tests are required depends on the spec's kind (frontmatter):
#               feature   a black-box test under acceptance/features/ AND tests in the
#                         language's style under SPEC_TESTS_DIR, both naming the spec id
#                         (S0001_R1_...), and at least one negative test (NEG)
#               fix       a regression test naming the spec id, in either place
#               refactor, chore   no red: no new behavior is tested. Start with green.
#             core_change: true in the frontmatter says the demand changes what the pilot
#             promises: the core test is updated first, so it may fail in the red.
#   green     everything passes: core, the target's tests, the other specs, contracts and
#             the architecture rules. For a refactor or chore, the first green is the
#             baseline, recorded before touching anything.
#   review    no tests run. Needs a note: verdict and what was accepted or rejected.
#   refactor  same checks as green: proves the refactor changed no behavior.
#
# The order is enforced: red, green, review, refactor, then a new red.
# REVIEW_MODE in .harness.env: auto (built-in reviewer) and external (another reviewer)
# both keep the review phase and record who reviewed; off removes the phase, so refactor
# may follow green directly.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/.." && pwd)"
cd "$root"
# shellcheck source=lib/env.sh
. "$here/lib/env.sh"

usage() {
  echo "usage: scripts/evidence.sh <red|green|review|refactor> <core|NNNN|swap> [note]" >&2
  exit 64
}

phase="${1:-}"
target="${2:-}"
note="${3:-}"

case "$phase" in red|green|review|refactor) ;; *) usage ;; esac

case "$target" in
  core) doc="PILOT.md"; tests_dir="acceptance/core"; label="pilot" ;;
  swap) doc="PLANKS.md"; tests_dir="contracts"; label="swap" ;;
  [0-9][0-9][0-9][0-9])
    doc="$(printf '%s\n' specs/"$target"-*.md | head -n1)"
    tests_dir="$(env_get SPEC_TESTS_DIR tests)"
    label="spec $target"
    ;;
  *) usage ;;
esac

if [ ! -f "$doc" ]; then
  echo "evidence: $doc not found" >&2
  exit 2
fi

# fm_key <key>: value of a key in the frontmatter of $doc (comments after # are dropped)
fm_key() {
  awk -v k="$1" '
    /^---[ \t]*$/ { n++; next }
    n == 1 && index($0, k ":") == 1 {
      v = $0
      sub("^" k ":[ \t]*", "", v)
      sub("[ \t]*#.*$", "", v)
      sub("[ \t]+$", "", v)
      print v
      exit
    }' "$doc"
}

kind=""
core_change="false"
no_red=0
if [ "$target" != "core" ] && [ "$target" != "swap" ]; then
  kind="$(fm_key kind)"
  kind="${kind:-feature}"
  core_change="$(fm_key core_change)"
  core_change="${core_change:-false}"
  case "$kind" in
    feature|fix) ;;
    refactor|chore) no_red=1 ;;
    *)
      echo "evidence: unknown kind '$kind' in $doc (feature, fix, refactor, chore)" >&2
      exit 2
      ;;
  esac
fi
if [ "$phase" = "red" ] && [ "$no_red" = "1" ]; then
  echo "evidence: a $kind has no red: no new behavior is tested. Run green first (the baseline), then review and refactor." >&2
  exit 1
fi

review_mode="$(env_get REVIEW_MODE auto)"
case "$review_mode" in
  auto|external|off) ;;
  *)
    echo "evidence: unknown REVIEW_MODE '$review_mode' in .harness.env (auto, external, off)" >&2
    exit 2
    ;;
esac
if [ "$phase" = "review" ] && [ "$review_mode" = "off" ]; then
  echo "evidence: REVIEW_MODE=off, so there is no review phase. Go from green to refactor." >&2
  exit 1
fi

# --- the cycle must be followed in order -------------------------------------------
last="$(awk '/^## Evidence/{e=1} e && /^### (red|green|review|refactor) /{p=$2} END{print p}' "$doc")"
ok=0
baseline=0
case "$phase" in
  red)   case "${last:-none}" in none|refactor|red) ok=1 ;; esac ;;
  green)
    case "${last:-none}" in
      red|green) ok=1 ;;
      none|refactor) if [ "$no_red" = "1" ]; then ok=1; baseline=1; fi ;;
    esac
    ;;
  review) case "${last:-none}" in green|review) ok=1 ;; esac ;;
  refactor)
    case "${last:-none}" in
      review|refactor) ok=1 ;;
      green) if [ "$review_mode" = "off" ]; then ok=1; fi ;;
    esac
    ;;
esac
if [ "$ok" != "1" ]; then
  echo "evidence: cannot record '$phase' after '${last:-nothing}'. The cycle is red, green, review, refactor." >&2
  exit 1
fi

# --- helpers ------------------------------------------------------------------------
log="$(mktemp)"
trap 'rm -f "$log"' EXIT
summary=""
neg=""

show_log() { sed 's/\x1b\[[0-9;]*m//g' "$log" | tail -n "${1:-15}"; }

need() {
  if [ -z "$(env_get "$1" '')" ]; then
    echo "evidence: $1 is empty in .harness.env" >&2
    exit 2
  fi
}

# step <name> <command...>: runs it, keeps the output, remembers pass or fail in $summary.
step() {
  local name="$1" rc
  shift
  { echo "\$ $*"; "$@"; } >>"$log" 2>&1
  rc=$?
  if [ "$rc" -eq 0 ]; then
    summary="${summary:+$summary, }$name: pass"
  else
    summary="${summary:+$summary, }$name: FAIL (exit $rc)"
  fi
  return "$rc"
}

# count_files <regex> <dir>: how many source files (not .md) under <dir> match the regex
count_files() {
  if [ -d "$2" ]; then
    grep -rIlE --exclude='*.md' --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.venv \
      --exclude-dir=venv --exclude-dir=vendor --exclude-dir=target --exclude-dir=dist \
      --exclude-dir=build --exclude-dir=__pycache__ -e "$1" "$2" 2>/dev/null | wc -l | tr -d ' '
  else
    echo 0
  fi
}

die() { echo "evidence: $1" >&2; exit 1; }

fail_red() {
  echo "evidence: the new tests PASSED before any product code was written, so they prove nothing. Strengthen them." >&2
  show_log >&2
  exit 1
}

record() {
  if ! grep -q '^## Evidence' "$doc"; then printf '\n## Evidence\n' >> "$doc"; fi
  {
    printf '\n### %s | %s | %s\n\n' "$phase" "$(date '+%Y-%m-%d %H:%M')" "$label"
    printf -- '- result: %s\n' "$1"
    if [ -n "$kind" ]; then printf -- '- kind: %s\n' "$kind"; fi
    if [ "$baseline" = "1" ]; then printf -- '- baseline: everything passed before the change\n'; fi
    if [ -n "$neg" ]; then printf -- '- negative tests found: %s\n' "$neg"; fi
    if [ "$phase" = "red" ] && [ "$core_change" = "true" ]; then printf -- '- core test updated for this spec (core_change: true)\n'; fi
    if [ "$phase" = "review" ]; then printf -- '- review mode: %s\n' "$review_mode"; fi
    if [ "$phase" = "refactor" ] && [ "$review_mode" = "off" ]; then printf -- '- review: skipped (REVIEW_MODE=off)\n'; fi
    if [ -n "$note" ]; then printf -- '- note: %s\n' "$note"; fi
    if [ -s "$log" ]; then
      printf '\n```text\n'
      show_log 15
      printf '```\n'
    fi
  } >> "$doc"
  echo "evidence: recorded $phase for $label in $doc ($1)"
}

# --- phases ---------------------------------------------------------------------------
case "$phase" in
  review)
    if [ -z "$note" ]; then
      echo "evidence: review needs a note (verdict and what was accepted or rejected)" >&2
      exit 64
    fi
    record "review recorded"
    ;;

  red)
    if [ -z "$note" ]; then
      echo "evidence: red needs a note saying why the tests fail (for example: the feature does not exist yet)" >&2
      exit 64
    fi
    case "$target" in
      core)
        neg="$(count_files 'NEG' "$tests_dir")"
        [ "$neg" -ge 1 ] || die "no negative test found in $tests_dir. Put NEG in the name of at least one test."
        need TEST_CORE_CMD
        if step core scripts/test.sh core; then fail_red; fi
        ;;
      swap)
        neg="$(count_files 'NEG' "$tests_dir")"
        [ "$neg" -ge 1 ] || die "no negative test found in $tests_dir. Put NEG in the name of at least one test."
        need TEST_CONTRACTS_CMD
        if step contracts scripts/test.sh contracts; then fail_red; fi
        ;;
      *)
        sid="S$target"
        bb_dir="acceptance/features"
        n_bb="$(count_files "$sid" "$bb_dir")"
        n_lang="$(count_files "$sid" "$tests_dir")"
        neg=$(( $(count_files "$sid.*NEG|NEG.*$sid" "$bb_dir") + $(count_files "$sid.*NEG|NEG.*$sid" "$tests_dir") ))
        if [ "$kind" = "feature" ]; then
          [ "$n_bb" -ge 1 ] || die "a feature needs a black-box test: no file under $bb_dir mentions $sid (put it in $bb_dir/$target-<slug>/)."
          [ "$n_lang" -ge 1 ] || die "a feature also needs tests in the language's style: no file under $tests_dir mentions $sid."
          [ "$neg" -ge 1 ] || die "no negative test found for $sid. Put NEG in the name of at least one test."
        else
          [ $((n_bb + n_lang)) -ge 1 ] || die "a fix needs a regression test that mentions $sid (under $tests_dir or $bb_dir)."
        fi
        need TEST_CORE_CMD
        need TEST_SPEC_CMD
        if [ "$core_change" = "true" ]; then
          step core scripts/test.sh core   # expected to fail: its test was just updated
        elif ! step core scripts/test.sh core; then
          echo "evidence: the core tests are already failing. Fix that before starting a spec (or set core_change: true if this spec changes what the pilot promises)." >&2
          show_log >&2
          exit 1
        fi
        if step "spec $target" scripts/test.sh specs "$target"; then fail_red; fi
        ;;
    esac
    record "failed as expected ($summary)"
    ;;

  green|refactor)
    failed=0
    step core scripts/test.sh core || failed=1
    case "$target" in
      core) ;;
      swap) step all scripts/test.sh all || failed=1 ;;
      *)
        if [ "$no_red" != "1" ]; then
          need TEST_SPEC_CMD
          step "spec $target" scripts/test.sh specs "$target" || failed=1
        fi
        step "all specs" scripts/test.sh specs || failed=1
        step contracts scripts/test.sh contracts || failed=1
        ;;
    esac
    step architecture scripts/arch-check.sh || failed=1
    if [ "$failed" = "1" ]; then
      echo "evidence: not recorded, something is failing: $summary" >&2
      show_log >&2
      exit 1
    fi
    record "all passed ($summary)"
    ;;
esac
