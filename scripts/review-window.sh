#!/usr/bin/env bash
# review-window.sh <file> [question]
# Opens <file> in a review window, waits for it to be closed, then asks for approval.
# Exit 0 = approved. Anything else = blocked. Fails closed when it cannot ask a human.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/env.sh
. "$here/lib/env.sh"

file="${1:?usage: review-window.sh <file> [question]}"
question="${2:-Approve?}"
tool="$(env_get REVIEW_TOOL auto)"

has_tty() { ( exec </dev/tty ) 2>/dev/null; }

open_review() {
  local t="$tool" c ed
  if [ "$t" = "auto" ]; then
    for c in code cursor windsurf; do
      if command -v "$c" >/dev/null 2>&1; then t="$c"; break; fi
    done
  fi
  case "$t" in
    code|cursor|windsurf)
      command -v "$t" >/dev/null 2>&1 || { echo "review: '$t' not found in PATH" >&2; return 1; }
      "$t" --wait --new-window "$file"
      ;;
    editor)
      ed="${VISUAL:-${EDITOR:-}}"
      if [ -z "$ed" ] || ! has_tty; then echo "review: no \$EDITOR or no terminal" >&2; return 1; fi
      # shellcheck disable=SC2086
      $ed "$file" </dev/tty >/dev/tty
      ;;
    auto|terminal)
      has_tty || { echo "review: no GUI editor and no terminal available" >&2; return 1; }
      "${PAGER:-less}" "$file" </dev/tty >/dev/tty
      ;;
    *)
      echo "review: unknown REVIEW_TOOL '$tool'" >&2; return 1
      ;;
  esac
}

gui_confirm() {
  if command -v osascript >/dev/null 2>&1; then
    osascript -e "display dialog \"$question\" buttons {\"Cancel\",\"Approve\"} default button \"Cancel\"" >/dev/null 2>&1
  elif command -v zenity >/dev/null 2>&1 && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
    zenity --question --title="Review" --text="$question" --width=400 2>/dev/null
  else
    return 2
  fi
}

confirm() {
  local ans
  if has_tty; then
    printf '\n%s [y/N] ' "$question" >/dev/tty
    read -r ans </dev/tty || return 1
    case "$ans" in y|Y|yes|YES|s|S|sim|SIM) return 0 ;; *) return 1 ;; esac
  fi
  gui_confirm
}

if ! open_review; then
  echo "review: could not open the review window. Run this git command from your own terminal." >&2
  exit 1
fi

if confirm; then exit 0; fi

echo "review: not approved (or no way to ask). Nothing was committed or pushed." >&2
exit 1
