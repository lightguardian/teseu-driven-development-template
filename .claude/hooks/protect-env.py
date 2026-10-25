#!/usr/bin/env python3
"""PreToolUse hook: stop Claude Code from reading or writing .env files.

Reads the hook payload (JSON) on stdin. Exit 2 blocks the tool call and sends
stderr back to Claude. Any other failure is turned into a block by
`onFailure: "block"` in settings.json, so this fails closed.

Blocked: .env and .env.<anything> (.env.local, .env.production, ...).
Allowed: .env.example / .sample / .template / .dist (no secrets) and
.harness.env (the template's committed, non-secret config).
"""
import fnmatch
import json
import re
import sys

SAFE_SUFFIXES = (".example", ".sample", ".template", ".dist")
# Only the fields that hold a path. Never Grep's `pattern`: that is a content
# regex, and searching for "process.env" must keep working.
PATH_KEYS = {
    "Read": ("file_path",),
    "Edit": ("file_path",),
    "Write": ("file_path",),
    "NotebookEdit": ("notebook_path",),
    "Grep": ("path", "glob"),
    "Glob": ("pattern", "path"),
}
TOKEN_RE = re.compile(r"[^\s'\";|&<>()=`$]+")


def is_env_name(name: str) -> bool:
    name = name.lower()
    if name.endswith(SAFE_SUFFIXES):
        return False
    if name == ".env" or name.startswith(".env."):
        return True
    # globs that can expand to ".env": .e*, .en?, .env*, .*
    if name.startswith(".") and any(c in name for c in "*?["):
        return fnmatch.fnmatchcase(".env", name)
    return False


def token_hits(text: str) -> bool:
    for token in TOKEN_RE.findall(text):
        if is_env_name(token.rsplit("/", 1)[-1]):
            return True
    return False


def main() -> int:
    payload = json.load(sys.stdin)
    tool = payload.get("tool_name", "")
    args = payload.get("tool_input") or {}

    if tool == "Bash":
        targets = [args.get("command", "")]
    else:
        targets = [args[k] for k in PATH_KEYS.get(tool, ()) if isinstance(args.get(k), str)]

    if any(token_hits(t) for t in targets):
        print(
            "Blocked: .env files are off-limits to Claude (secrets). "
            "Ask the user to run the command themselves, or use .env.example.",
            file=sys.stderr,
        )
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
