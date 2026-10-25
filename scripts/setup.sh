#!/usr/bin/env bash
# setup.sh
# One-time setup after cloning or creating a repository from this template:
# makes the scripts and hooks executable and points git at .githooks.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

chmod +x .githooks/* scripts/*.sh 2>/dev/null || true

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git config core.hooksPath .githooks
  echo "setup: core.hooksPath = .githooks"
else
  echo "setup: this is not a git repository yet. Run git init, then scripts/setup.sh again."
fi

echo "setup: next, copy .env.example to .env if the product needs local config (never commit .env)."
