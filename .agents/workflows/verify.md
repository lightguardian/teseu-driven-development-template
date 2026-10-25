---
description: Run the core, spec and contract tests plus the architecture rules, and report.
---

# Verify

1. Run `scripts/test.sh all`, then `scripts/arch-check.sh`.
2. Report a short table: core, specs, contracts, architecture. For each failure give the test id, the likely cause and which of the two cases it is:
   - the test was wrong, or
   - a change broke the product.
3. Check the discipline too: every spec marked `done` has red, green, review and refactor entries in its `## Evidence` section (no review entry is expected when `REVIEW_MODE=off`), and the core suite and every spec have at least one negative test (`NEG`). List what is missing.
4. Fix nothing unless the user asks. A failing core test is never fixed by editing the test.
5. If `TEST_CORE_CMD` is empty, say the pilot does not exist yet and suggest `start`.
