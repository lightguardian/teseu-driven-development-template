#!/usr/bin/env bash
# evidence.sh <red|green|review|refactor> <core|NNNN|swap> [note]
#
# Runs the right tests for one phase of the TDD cycle, checks that the result is the
# expected one, regenerates the checklist and appends the proof to the "## Evidence"
# section of PILOT.md (core), of specs/NNNN-*.md (a spec) or of PLANKS.md (swap).
# Nothing is recorded when the expectation is not met.
#
# Verification has TWO STAGES, always in this order:
#   stage 1  black-box, the central tests: the core test, then the feature's own black-box
#            test, then every other feature's. If stage 1 fails, stage 2 is not run.
#   stage 2  the language's own tests: the spec's tests, the other specs', the contracts,
#            then the architecture rules.
# The checklist (PILOT.checklist.md or specs/NNNN-*.checklist.md) lists the tests of each
# stage and is regenerated on every run. Review waits until every box is checked.
#
#   red       the new tests FAIL, in BOTH stages (and the core still passes); needs a note:
#             why it fails. Which tests are required depends on the spec's kind (frontmatter):
#               feature   a black-box test under acceptance/features/ AND tests in the
#                         language's style under SPEC_TESTS_DIR, both naming the spec id
#                         (S0001_R1_...), and at least one negative test (NEG)
#               fix       a regression test naming the spec id, in either place
#               refactor, chore   no red: no new behavior is tested. Start with green.
#             core_change: true in the frontmatter says the demand changes what the pilot
#             promises: the core test is updated first, so it may fail in the red.
#   green     both stages pass. For a refactor or chore, the first green is the baseline,
#             recorded before touching anything.
#   review    no tests run. Needs a note: verdict and what was accepted or rejected, and a
#             complete checklist.
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

checklist=""
case "$target" in
  core) doc="PILOT.md"; tests_dir="acceptance/core"; label="pilot"; checklist="PILOT.checklist.md" ;;
  swap) doc="PLANKS.md"; tests_dir="contracts"; label="swap" ;;
  [0-9][0-9][0-9][0-9])
    doc="$(printf '%s\n' specs/"$target"-*.md | grep -v '\.checklist\.md$' | head -n1)"
    tests_dir="$(env_get SPEC_TESTS_DIR tests)"
    label="spec $target"
    checklist="${doc%.md}.checklist.md"
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

have() { [ -n "$(env_get "$1" '')" ]; }

need() {
  if ! have "$1"; then
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

# stage <variable> <name> <command...>: like step, and stores pass or fail in <variable>
stage() {
  local var="$1" name="$2" rc
  shift 2
  step "$name" "$@"
  rc=$?
  if [ "$rc" -eq 0 ]; then printf -v "$var" '%s' pass; else printf -v "$var" '%s' fail; fi
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

# find_ids <regex> <dir>...: the distinct test ids found in the source files, one per line
find_ids() {
  local re="$1" d
  shift
  for d in "$@"; do
    if [ -d "$d" ]; then
      grep -rIhoE --exclude='*.md' --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.venv \
        --exclude-dir=venv --exclude-dir=vendor --exclude-dir=target --exclude-dir=dist \
        --exclude-dir=build --exclude-dir=__pycache__ -e "$re" "$d" 2>/dev/null
    fi
  done | sort -u
}

fmt_ids() { awk 'NF { printf "%s`%s`", (n++ ? ", " : ""), $0 } END { if (n) printf "\n" }'; }

die() { echo "evidence: $1" >&2; exit 1; }

fail_red() { # fail_red <which tests passed>
  echo "evidence: the new $1 PASSED before any product code was written, so they prove nothing. Strengthen them." >&2
  show_log >&2
  exit 1
}

# --- the checklist -------------------------------------------------------------------
# States: pass, fail, expectedfail (a red), notrun, na (does not apply)
R_core=notrun; R_feat_one=na; R_feat_all=na
R_spec_one=na; R_spec_all=na; R_contracts=na; R_arch=notrun

box() { case "$1" in pass) printf '[x]' ;; *) printf '[ ]' ;; esac; }
word() {
  case "$1" in
    pass) echo "passed" ;;
    fail) echo "FAILED" ;;
    expectedfail) echo "failed as expected (red)" ;;
    notrun) echo "not run" ;;
  esac
}
item() { # item <state> <text> [ids]
  if [ "$1" = "na" ]; then
    printf -- '- n/a: %s\n' "$2"
  else
    printf -- '- %s %s: %s%s\n' "$(box "$1")" "$2" "$(word "$1")" "${3:+ ($3)}"
  fi
}
stage_ok() { # stage_ok <state>...: true when every state is pass or na
  local s
  for s in "$@"; do
    case "$s" in pass|na) ;; *) return 1 ;; esac
  done
}

write_checklist() {
  [ -n "$checklist" ] || return 0
  local core_ids feat_ids spec_ids s1 s2 result
  core_ids="$(find_ids 'A[0-9]{2}[A-Za-z0-9_]*' acceptance/core | fmt_ids)"
  feat_ids=""; spec_ids=""
  if [ -n "$kind" ]; then
    feat_ids="$(find_ids "S$target[_-]R[0-9]+[A-Za-z0-9_]*" acceptance/features | fmt_ids)"
    spec_ids="$(find_ids "S$target[_-]R[0-9]+[A-Za-z0-9_]*" "$tests_dir" | fmt_ids)"
  fi
  if stage_ok "$R_core" "$R_feat_one" "$R_feat_all"; then s1="passed"; else s1="not complete"; fi
  if stage_ok "$R_spec_one" "$R_spec_all" "$R_contracts" "$R_arch"; then s2="passed"; else s2="not complete"; fi
  if [ "$s1" = "passed" ] && [ "$s2" = "passed" ]; then result="complete"; else result="incomplete"; fi
  local title="$label"
  if [ -n "$kind" ]; then title="spec $(basename "$doc" .md)"; fi
  {
    printf '# Checklist: %s\n\n' "$title"
    printf 'Generated by `scripts/evidence.sh`. Do not edit by hand. Last run: %s, phase %s.\n\n' "$(date '+%Y-%m-%d %H:%M')" "$phase"
    printf 'Verification has two stages, always in this order: first the black-box tests (the central ones), then the tests of the language. Review, commit and ship wait until every box is checked.\n\n'
    printf '## Stage 1: black-box (the central tests)\n\n'
    item "$R_core" "Core test (acceptance/core)" "$core_ids"
    if [ -n "$kind" ]; then
      if [ "$R_feat_one" = "na" ]; then
        item na "no black-box test for this spec (kind: $kind)"
      else
        item "$R_feat_one" "This feature (acceptance/features)" "$feat_ids"
      fi
      if [ "$R_feat_all" = "na" ]; then item na "all the features (TEST_FEATURES_CMD is empty)"; else item "$R_feat_all" "All the features"; fi
    fi
    printf '\n## Stage 2: the language'"'"'s own tests\n\n'
    if [ -n "$kind" ]; then
      if [ "$R_spec_one" = "na" ]; then item na "no tests of its own (kind: $kind)"; else item "$R_spec_one" "This spec ($tests_dir)" "$spec_ids"; fi
      if [ "$R_spec_all" = "na" ]; then item na "all the specs (TEST_SPECS_CMD is empty)"; else item "$R_spec_all" "All the specs"; fi
      if [ "$R_contracts" = "na" ]; then item na "contracts (TEST_CONTRACTS_CMD is empty)"; else item "$R_contracts" "Contracts"; fi
    fi
    item "$R_arch" "Architecture rules (scripts/arch-check.sh)"
    printf '\n## Result\n\n'
    printf 'Stage 1: %s. Stage 2: %s.\n\n' "$s1" "$s2"
    printf 'Result: %s\n' "$result"
  } > "$checklist"
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
    if [ -n "$checklist" ]; then printf -- '- checklist: %s\n' "$checklist"; fi
    if [ -n "$note" ]; then printf -- '- note: %s\n' "$note"; fi
    if [ -s "$log" ]; then
      printf '\n```text\n'
      show_log 15
      printf '```\n'
    fi
  } >> "$doc"
  echo "evidence: recorded $phase for $label in $doc ($1)"
}

# items that this run is going to check start as "not run" (a failed stage 1 leaves stage 2 so)
if [ -n "$kind" ]; then
  [ "$no_red" != "1" ] && [ "$(count_files "S$target" acceptance/features)" -ge 1 ] && R_feat_one=notrun
  [ "$no_red" != "1" ] && [ "$(count_files "S$target" "$tests_dir")" -ge 1 ] && R_spec_one=notrun
  have TEST_FEATURES_CMD && R_feat_all=notrun
  have TEST_SPECS_CMD && R_spec_all=notrun
  have TEST_CONTRACTS_CMD && R_contracts=notrun
fi

# --- phases ---------------------------------------------------------------------------
case "$phase" in
  review)
    if [ -z "$note" ]; then
      echo "evidence: review needs a note (verdict and what was accepted or rejected)" >&2
      exit 64
    fi
    if [ -n "$checklist" ]; then
      if [ ! -f "$checklist" ] || ! grep -q '^Result: complete' "$checklist" || grep -q '^- \[ \]' "$checklist"; then
        die "the checklist ($checklist) is not complete. Review, commit and ship wait until every box is checked: run scripts/evidence.sh green $target."
      fi
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
        if stage R_core core scripts/test.sh core; then fail_red "core tests"; fi
        R_core=expectedfail
        ;;
      swap)
        neg="$(count_files 'NEG' "$tests_dir")"
        [ "$neg" -ge 1 ] || die "no negative test found in $tests_dir. Put NEG in the name of at least one test."
        need TEST_CONTRACTS_CMD
        if step contracts scripts/test.sh contracts; then fail_red "contract tests"; fi
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
        # stage 1: the core must pass (unless this spec changes it), the feature's black-box test must fail
        if [ "$core_change" = "true" ]; then
          stage R_core core scripts/test.sh core   # expected to fail: its test was just updated
          [ "$R_core" = "fail" ] && R_core=expectedfail
        elif ! stage R_core core scripts/test.sh core; then
          write_checklist
          echo "evidence: the core tests are already failing. Fix that before starting a spec (or set core_change: true if this spec changes what the pilot promises)." >&2
          show_log >&2
          exit 1
        fi
        bad=""
        if [ "$n_bb" -ge 1 ]; then
          need TEST_FEATURE_CMD
          if stage R_feat_one "feature $target" scripts/test.sh features "$target"; then bad="black-box tests"; else R_feat_one=expectedfail; fi
        fi
        # stage 2: the language tests must fail too
        if [ "$n_lang" -ge 1 ]; then
          need TEST_SPEC_CMD
          if stage R_spec_one "spec $target" scripts/test.sh specs "$target"; then bad="${bad:+$bad and }language tests"; else R_spec_one=expectedfail; fi
        fi
        [ -z "$bad" ] || fail_red "$bad"
        ;;
    esac
    write_checklist
    record "failed as expected ($summary)"
    ;;

  green|refactor)
    failed=0
    case "$target" in
      core)
        stage R_core core scripts/test.sh core || failed=1
        if [ "$failed" = "0" ]; then stage R_arch architecture scripts/arch-check.sh || failed=1; fi
        ;;
      swap)
        step all scripts/test.sh all || failed=1
        step architecture scripts/arch-check.sh || failed=1
        ;;
      *)
        sid="S$target"
        bb_dir="acceptance/features"
        need TEST_CORE_CMD
        # stage 1: black-box, the central tests (the core first)
        stage R_core core scripts/test.sh core || failed=1
        if [ "$no_red" != "1" ] && [ "$(count_files "$sid" "$bb_dir")" -ge 1 ]; then
          need TEST_FEATURE_CMD
          stage R_feat_one "feature $target" scripts/test.sh features "$target" || failed=1
        fi
        if have TEST_FEATURES_CMD; then
          stage R_feat_all "all features" scripts/test.sh features || failed=1
        fi
        # stage 2: the language's own tests, only when stage 1 passed
        if [ "$failed" = "0" ]; then
          if [ "$no_red" != "1" ] && [ "$(count_files "$sid" "$tests_dir")" -ge 1 ]; then
            need TEST_SPEC_CMD
            stage R_spec_one "spec $target" scripts/test.sh specs "$target" || failed=1
          fi
          if have TEST_SPECS_CMD; then stage R_spec_all "all specs" scripts/test.sh specs || failed=1; fi
          if have TEST_CONTRACTS_CMD; then stage R_contracts contracts scripts/test.sh contracts || failed=1; fi
          stage R_arch architecture scripts/arch-check.sh || failed=1
        else
          summary="${summary}, stage 2: not run"
        fi
        ;;
    esac
    write_checklist
    if [ "$failed" = "1" ]; then
      echo "evidence: not recorded, something is failing: $summary" >&2
      [ -n "$checklist" ] && echo "evidence: see $checklist" >&2
      show_log >&2
      exit 1
    fi
    record "all passed ($summary)"
    ;;
esac
