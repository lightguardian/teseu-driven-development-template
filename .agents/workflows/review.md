---
description: Run the read-only reviewer agent on the current changes and report findings.
---

# Review

This always runs the built-in reviewer, even when `REVIEW_MODE` is `external` or `off`: the user asked for it explicitly.

Delegate to the `reviewer` agent with the current diff (`git diff` and `git diff --cached`) against the default branch. Report its findings table and verdict to the user.

Do not fix anything until the user says which findings to fix.
