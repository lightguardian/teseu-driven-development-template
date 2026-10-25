---
description: Update the changelog, check everything, ask, push and propose the pull request.
---

# Ship

Commits are not held for approval: they happen at the end of each phase of the cycle, with Conventional Commits messages. Shipping is about the push, which always asks.

1. Run `scripts/test.sh core`, then `scripts/test.sh all` and `scripts/arch-check.sh`. Stop if anything fails. If the work implements a spec, its checklist (`specs/NNNN-slug.checklist.md`) must be complete: every box checked, the core test on top. If the work implements a spec or a swap, confirm its `## Evidence` has the red, green, review and refactor entries (no review entry when `REVIEW_MODE=off`); if one is missing, go back and do that phase.
2. Commit whatever is still pending, with a Conventional Commits message in English: `type(scope): description`, with `!` or a `BREAKING CHANGE:` footer for breaking changes. If a commit modifies `acceptance/core/`, the message needs a `Core-Change: <reason>` footer, and the user must have confirmed that the goal changed. If a hook rejects the commit, read its message and fix the cause; never use `--no-verify`.
3. Regenerate the history: `scripts/changelog.sh`, then commit `CHANGELOG.md` as `docs(changelog): update changelog`. Never edit it by hand.
4. Summarize what will go out (the commits since the last push, in a few lines). If `ASK_BEFORE_PUSH=true`, wait for an explicit "yes" in chat. Do not push without it.
5. Run `git push`. The `pre-push` hook may run the core tests, check the changelog and open a review window. Wait for it. If it fails with "could not open the review window", stop and ask the user to push from their own terminal.
6. Propose a PR title (English, Conventional Commits style) and description (`NATIVE_LANGUAGE`). Ask before creating the pull request.
