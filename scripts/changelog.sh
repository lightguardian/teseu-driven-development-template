#!/usr/bin/env bash
# changelog.sh [--check]
# Generates CHANGELOG.md from the Conventional Commits of the current branch. No external
# tool needed. Sections: [Unreleased], then one per tag v* from newest to oldest. Inside a
# section commits are grouped by type; breaking changes are listed first. Commits whose
# scope is "changelog" are left out, so committing the changelog does not make it stale.
#
#   (no argument)  write CHANGELOG.md
#   --check        write nothing; exit 1 if the CHANGELOG.md committed in HEAD is missing or
#                  out of date (used by the pre-push hook and by CI)
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$here/.."

mode="${1:-write}"
out="CHANGELOG.md"

data="$(mktemp)"
tmp="$(mktemp)"
trap 'rm -f "$data" "$tmp"' EXIT

titles=("Features" "Bug fixes" "Performance" "Refactor" "Documentation" "Tests" "Build and CI" "Style" "Chores" "Reverts")

type_title() {
  case "$1" in
    feat) echo "Features" ;;
    fix) echo "Bug fixes" ;;
    perf) echo "Performance" ;;
    refactor) echo "Refactor" ;;
    docs) echo "Documentation" ;;
    test) echo "Tests" ;;
    build|ci) echo "Build and CI" ;;
    style) echo "Style" ;;
    chore) echo "Chores" ;;
    revert) echo "Reverts" ;;
    *) echo "" ;;
  esac
}

re='^([a-z]+)(\(([^)]*)\))?(!)?:[[:space:]](.+)$'

# collect <section-index> <git log range args...>
# Appends one tab-separated line per conventional commit to $data:
# section, group title, breaking (0/1), scope, description, hash, date
collect() {
  local idx="$1" rec h d s b type scope bang desc breaking title
  shift
  while IFS= read -r -d $'\x1e' rec; do
    rec="${rec#"${rec%%[![:space:]]*}"}"
    [ -n "$rec" ] || continue
    h="${rec%%$'\x1f'*}"; rec="${rec#*$'\x1f'}"
    d="${rec%%$'\x1f'*}"; rec="${rec#*$'\x1f'}"
    s="${rec%%$'\x1f'*}"; b="${rec#*$'\x1f'}"
    [[ $s =~ $re ]] || continue
    type="${BASH_REMATCH[1]}"
    scope="${BASH_REMATCH[3]}"
    bang="${BASH_REMATCH[4]}"
    desc="${BASH_REMATCH[5]//$'\t'/ }"
    [ "$scope" = "changelog" ] && continue
    title="$(type_title "$type")"
    [ -n "$title" ] || continue
    breaking=0
    [ -n "$bang" ] && breaking=1
    if printf '%s' "$b" | grep -Eq '^BREAKING[ -]CHANGE:'; then breaking=1; fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$idx" "$title" "$breaking" "$scope" "$desc" "$h" "$d" >> "$data"
  done < <(git log --no-merges --format='%h%x1f%ad%x1f%s%x1f%b%x1e' --date=short "$@" 2>/dev/null)
}

# entries <section-index> <breaking: 1|any> <group title or empty>
entries() {
  awk -F'\t' -v i="$1" -v br="$2" -v t="$3" '
    $1 == i && (br == "any" || $3 == br) && (t == "" || $2 == t) {
      d = $5
      d = toupper(substr(d, 1, 1)) substr(d, 2)
      s = ($4 != "") ? "**" $4 ":** " : ""
      printf "- %s%s (%s, %s)\n", s, d, $6, $7
    }' "$data"
}

# render <section-index> <heading>
render() {
  local idx="$1" heading="$2" title body
  printf '## %s\n\n' "$heading"
  if ! awk -F'\t' -v i="$idx" '$1 == i { f = 1 } END { exit !f }' "$data"; then
    printf '_No changes._\n\n'
    return 0
  fi
  body="$(entries "$idx" 1 "")"
  if [ -n "$body" ]; then printf '### Breaking changes\n\n%s\n\n' "$body"; fi
  for title in "${titles[@]}"; do
    body="$(entries "$idx" any "$title")"
    if [ -n "$body" ]; then printf '### %s\n\n%s\n\n' "$title" "$body"; fi
  done
  return 0
}

tags=()
while IFS= read -r t; do
  [ -n "$t" ] && tags+=("$t")
done < <(git tag --list 'v*' --sort=-creatordate --merged HEAD 2>/dev/null)

if [ "${#tags[@]}" -eq 0 ]; then
  collect 0 HEAD
else
  collect 0 "${tags[0]}..HEAD"
  for i in "${!tags[@]}"; do
    next=$((i + 1))
    if [ "$next" -lt "${#tags[@]}" ]; then
      collect "$next" "${tags[$i]}" "^${tags[$next]}"
    else
      collect "$next" "${tags[$i]}"
    fi
  done
fi

{
  printf '# Changelog\n\n'
  printf 'History of what was done, generated from Conventional Commits by `scripts/changelog.sh`. Do not edit by hand.\n\n'
  render 0 "[Unreleased]"
  for i in "${!tags[@]}"; do
    render $((i + 1)) "[${tags[$i]}] - $(git log -1 --format=%ad --date=short "${tags[$i]}")"
  done
} > "$tmp"

case "$mode" in
  --check)
    if git show "HEAD:$out" 2>/dev/null | cmp -s - "$tmp"; then
      echo "changelog: up to date"
      exit 0
    fi
    echo "changelog: $out is missing or out of date in HEAD." >&2
    echo "  Run scripts/changelog.sh and commit it as: docs(changelog): update changelog" >&2
    exit 1
    ;;
  write)
    cp "$tmp" "$out"
    echo "changelog: wrote $out"
    ;;
  *)
    echo "usage: scripts/changelog.sh [--check]" >&2
    exit 64
    ;;
esac
