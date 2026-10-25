---
description: Replace one plank with a better one (red, green, review, refactor; expand, migrate, contract) without stopping the product.
---

# Swap

Arguments: the plank name from `PLANKS.md`, optionally the target level or technology (for example `data sqlite`).

Branch: `swap/<plank>`. Each step ends with the system green. If the session ends midway, nothing may be left broken. Evidence of each phase goes to the "Evidence" section of `PLANKS.md` through `scripts/evidence.sh <phase> swap`.

## 0. Precondition

`scripts/test.sh all` is green. Read the plank's row, its pains and its appetite in `PLANKS.md`. Tell the user the plan in three lines and wait for a yes.

## 1. Find the seam

Identify the plank's port. If there is no port because the thing is tangled into other code, first extract one (Branch by Abstraction): create the interface, point the callers at it, keep the behavior. Core tests stay green.

## 2. Contract tests (positive and negative)

If the project uses contracts, make sure `contracts/` has a suite for the port that exercises the current adapter and that it passes. (At `TEST_LEVEL=none` there is no automated proof of a swap: tell the user and ask for a manual check of the behavior before and after.) If it does not exist, write it from the current behavior. It must include negative tests (`NEG`): what the port must refuse or must not do (invalid input rejected, nothing written on failure). The same suite will run against every adapter of the port.

## 3. RED: register the new adapter

Add the new adapter to the contract suite as an empty skeleton and run `scripts/evidence.sh red swap "<why they fail>"`. The contract tests must fail for the new adapter (it does nothing yet) and pass for the old one.

## 4. GREEN: expand, then migrate

- Expand: write the new adapter next to the old one until the contract suite passes for both. Nothing uses the new adapter yet.
- Migrate: point the wiring in `app/` at the new adapter (a config switch is fine while migrating). If the plank holds state (data), migrate it with a way back: write to both or backfill, read from the new one, keep the old one until the new one is proven. Never delete data in this step.
- Run `scripts/evidence.sh green swap`. Behavior must be identical for the user.

## 5. REVIEW

Follow `REVIEW_MODE` (see "Review" in `AGENTS.md`): the `reviewer` agent in `auto`, the user's own reviewer in `external`, no review in `off`. Record it with `scripts/evidence.sh review swap "<who and verdict>"` (not in `off`).

## 6. REFACTOR: contract

Remove the old adapter and the temporary switch. Keep an in-memory adapter only if tests use it as a test double. Skipping this step leaves two implementations and is the classic failure of a swap. Run `scripts/evidence.sh refactor swap`.

## 7. Record and ship

- Update `PLANKS.md`: new level, current adapter, resolved pains, and one line in "Swap history" (date, from, to, why, what became harder). Update the layer map in `docs/architecture.md` if a layer was added, removed or changed kind.
- Commit at the end of each phase without asking (`test(<plank>): ...` for the red, `refactor(<plank>): ...` for the migration and the contract).
- At R3, also write an ADR from `.agents/templates/adr.md`.
- Continue with the `ship` workflow using `refactor(<plank>): ...`.

## Whole-product rewrite in another language

Keep `acceptance/` untouched: `acceptance/core/` and `acceptance/features/` are the only tests that do not depend on the language, so together they are the definition of done. Build the new implementation in a sibling folder and point `RUN_CMD` at it. Rewrite the language-style tests of the specs (`SPEC_TESTS_DIR`) and the contracts for the new language as you go. Be aware that a bug fix or a detail covered only by an old language-style test has no black-box safety net: list those and decide with the user which ones deserve a new black-box test before switching. Switch only when every black-box test passes against the new implementation; then remove the old one.
