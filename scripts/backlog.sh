#!/usr/bin/env bash
# backlog.sh [--check]
# Recomputes the scores in BACKLOG.md and sorts it by the method set in .harness.env
# (PRIORITIZATION):
#   none     keeps the order of the IDs
#   moscow   Must, Should, Could, Won't
#   rice     Score = Reach x Impact x Confidence% / Effort, highest first
#   ice      Score = Impact x Confidence x Ease, highest first
# Open items (idea, ready, in-progress) come first, then done, then dropped.
# Cells must not contain the | character.
#
#   (no argument)  rewrite BACKLOG.md
#   --check        write nothing; exit 1 if the file is not scored and sorted
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$here/.."
# shellcheck source=lib/env.sh
. "$here/lib/env.sh"

file="BACKLOG.md"
method="$(env_get PRIORITIZATION none)"
mode="${1:-write}"

if [ ! -f "$file" ]; then
  echo "backlog: $file not found" >&2
  exit 2
fi

case "$method" in
  none)   expected="ID|Demand|Status|Spec" ;;
  moscow) expected="ID|Demand|MoSCoW|Status|Spec" ;;
  rice)   expected="ID|Demand|Reach|Impact|Confidence|Effort|Score|Status|Spec" ;;
  ice)    expected="ID|Demand|Impact|Confidence|Ease|Score|Status|Spec" ;;
  *)
    echo "backlog: unknown PRIORITIZATION '$method' (none, moscow, rice, ice)" >&2
    exit 2
    ;;
esac

rows="$(mktemp)"
out="$(mktemp)"
trap 'rm -f "$rows" "$out"' EXIT

errors=0
err() { echo "backlog: $1" >&2; errors=$((errors + 1)); }

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

# cells <row>: fills the array CELLS
cells() {
  local line="$1" part
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line#|}"
  line="${line%|}"
  CELLS=()
  while [[ "$line" == *"|"* ]]; do
    part="${line%%|*}"
    CELLS+=("$(trim "$part")")
    line="${line#*|}"
  done
  CELLS+=("$(trim "$line")")
}

col() { # col <name>: value of a column of the current row
  local k
  for k in "${!HDR[@]}"; do
    if [ "${HDR[$k]}" = "$1" ]; then printf '%s' "${CELLS[$k]}"; return 0; fi
  done
}

setcol() { # setcol <name> <value>
  local k
  for k in "${!HDR[@]}"; do
    if [ "${HDR[$k]}" = "$1" ]; then CELLS[$k]="$2"; return 0; fi
  done
}

join_row() {
  local line="|" c
  for c in "$@"; do line="$line $c |"; done
  printf '%s' "$line"
}

isnum() { [[ "$1" =~ ^[0-9]+([.][0-9]+)?$ ]]; }
isint() { [[ "$1" =~ ^[0-9]+$ ]]; }
awk_true() { awk -v v="$1" "BEGIN { exit !($2) }"; } # awk_true <value> <condition on v>

lines=()
while IFS= read -r l || [ -n "$l" ]; do lines+=("$l"); done < "$file"
n="${#lines[@]}"

hdr=-1
for ((i = 0; i < n; i++)); do
  if [[ "${lines[$i]}" =~ ^\|[[:space:]]*ID[[:space:]]*\| ]]; then hdr=$i; break; fi
done
if [ "$hdr" -lt 0 ]; then
  echo "backlog: no table starting with | ID | found in $file" >&2
  exit 2
fi

cells "${lines[$hdr]}"
HDR=("${CELLS[@]}")
got="$(IFS='|'; echo "${HDR[*]}")"
if [ "$got" != "$expected" ]; then
  echo "backlog: the table header does not match PRIORITIZATION=$method." >&2
  echo "  expected: | ${expected//|/ | } |" >&2
  echo "  found:    | ${got//|/ | } |" >&2
  echo "  Run /backlog method $method to rewrite it." >&2
  exit 2
fi
ncols="${#HDR[@]}"

end=$((hdr + 2))
for ((i = hdr + 2; i < n; i++)); do
  l="${lines[$i]}"
  case "$l" in "|"*) ;; *) break ;; esac
  end=$((i + 1))
  cells "$l"
  if [ "${#CELLS[@]}" -ne "$ncols" ]; then err "line $((i + 1)): expected $ncols cells"; continue; fi
  id="$(col ID)"
  status="$(col Status)"
  case "$status" in
    idea|ready|in-progress) group=0 ;;
    done) group=1 ;;
    dropped) group=2 ;;
    *) err "$id: Status must be idea, ready, in-progress, done or dropped (got '$status')"; continue ;;
  esac
  key=0
  case "$method" in
    moscow)
      case "$(col MoSCoW)" in
        Must) key=1 ;;
        Should) key=2 ;;
        Could) key=3 ;;
        "Won't") key=4 ;;
        *) err "$id: MoSCoW must be Must, Should, Could or Won't"; continue ;;
      esac
      ;;
    rice)
      r="$(col Reach)"; im="$(col Impact)"; cf="$(col Confidence)"; ef="$(col Effort)"
      if ! isnum "$r" || ! isnum "$im" || ! isnum "$cf" || ! isnum "$ef"; then
        err "$id: Reach, Impact, Confidence and Effort must be numbers"; continue
      fi
      case "$im" in 0.25|0.5|1|2|3) ;; *) err "$id: Impact must be 0.25, 0.5, 1, 2 or 3"; continue ;; esac
      if ! awk_true "$cf" "v > 0 && v <= 100"; then err "$id: Confidence must be between 1 and 100"; continue; fi
      if ! awk_true "$ef" "v > 0"; then err "$id: Effort must be greater than 0"; continue; fi
      score="$(awk -v a="$r" -v b="$im" -v c="$cf" -v d="$ef" 'BEGIN { printf "%.2f", a * b * c / 100 / d }')"
      setcol Score "$score"
      key="-$score"
      ;;
    ice)
      im="$(col Impact)"; cf="$(col Confidence)"; ea="$(col Ease)"
      ok=1
      for v in "$im" "$cf" "$ea"; do
        if ! isint "$v" || [ "$v" -lt 1 ] || [ "$v" -gt 10 ]; then ok=0; fi
      done
      if [ "$ok" -ne 1 ]; then err "$id: Impact, Confidence and Ease must be integers from 1 to 10"; continue; fi
      score=$((im * cf * ea))
      setcol Score "$score"
      key="-$score"
      ;;
  esac
  printf '%s\t%s\t%s\t%s\n' "$group" "$key" "$id" "$(join_row "${CELLS[@]}")" >> "$rows"
done

if [ "$errors" -gt 0 ]; then
  echo "backlog: $errors problem(s); nothing was written" >&2
  exit 1
fi

{
  for ((i = 0; i <= hdr + 1; i++)); do printf '%s\n' "${lines[$i]}"; done
  sort -t "$(printf '\t')" -k1,1n -k2,2n -k3,3 "$rows" | cut -f4
  for ((i = end; i < n; i++)); do printf '%s\n' "${lines[$i]}"; done
} > "$out"

case "$mode" in
  --check)
    if cmp -s "$out" "$file"; then echo "backlog: sorted and scored"; exit 0; fi
    echo "backlog: $file is not scored and sorted. Run scripts/backlog.sh." >&2
    exit 1
    ;;
  write)
    cp "$out" "$file"
    echo "backlog: updated $file (method: $method)"
    ;;
  *)
    echo "usage: scripts/backlog.sh [--check]" >&2
    exit 64
    ;;
esac
