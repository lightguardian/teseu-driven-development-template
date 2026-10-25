---
description: Interview for a new demand, write a numbered spec, then red, green, review and refactor with the tests its kind needs.
---

# Spec (one real problem at a time)

Arguments: what the user wants, in free text. Ask in `NATIVE_LANGUAGE`.

## 0. Precondition

Run `scripts/test.sh core` (it does nothing at `TEST_LEVEL=none`). If it is not green, stop: the product is already broken, so fix that first (or ask the user). If the demand is an item of `BACKLOG.md`, use it as the starting point and set it to `in-progress` when the spec is created.

## 1. Interview (one question at a time, at most 5)

1. **Was the previous pain solved?** Look at `PLANKS.md` (pain log) and the last spec. Is this still the most important thing to do now?
2. **What real problem does THIS spec solve?** Who hits it, how often, what is the evidence? If the user cannot name a real problem, say so and suggest not doing it.
3. **What changes for the user, in observable terms?** This becomes the positive criteria. For a refactor or chore: what must stay exactly the same, and why is the change worth it?
4. **What must it NOT do, and what must never happen?** The first becomes "Out of scope", the second becomes the negative tests.
5. **What is the ONE central point it touches, and what kind of demand is it?** (If it cannot or need not be tested, set `tests: none` in the spec and say why under "Tests".) The kind is `feature` (a new capability), `fix` (a bug), `refactor` (internal change, same behavior) or `chore` (tooling, docs, dependencies). If it touches more than two planks, suggest splitting it. If it is really "make X better or more robust", it is a swap: continue with `swap` instead.

**Core check** (no extra question unless in doubt): read `acceptance/core/` and the "Done when" of `PILOT.md`. Does this demand change what the pilot promised (for example, the message will no longer carry the image the core test expects)? If yes, set `core_change: true`, tell the user which core test is no longer true, and get a yes before updating it. If no, the core test must keep passing as it is.

## 2. Write `specs/NNNN-slug.md`

Copy `specs/_template.md` (NNNN is the next free number). Write the text in `SPEC_LANGUAGE` (the same as `NATIVE_LANGUAGE` when it is empty; headings, ids and Given/When/Then keywords stay in English). Set `kind`, `size` and `core_change` in the frontmatter. Fill: the pain, out of scope, requirements numbered `S<NNNN>-R1..Rn`, acceptance criteria in Given/When/Then including the sad paths (error, empty, abandonment), the planks touched (the first is the central point). Mark which criteria are negative. No MoSCoW (priorities live in `BACKLOG.md`, if the user keeps one). If it needs new vocabulary, update `GLOSSARY.md`. If it needs a layer that is not on the layer map in `docs/architecture.md` (a new external service, a new kind of storage, a new interface), add it to the map and to `PLANKS.md` before going on. A size `L` means split it first.

## 3. RED: the tests come first (not for a refactor, a chore, `tests: none` or `TEST_LEVEL=none`)

The tests depend on the kind:

- **feature:** the tests of the details under `SPEC_TESTS_DIR`, and, at `TEST_LEVEL=full`, also exactly one black-box test in `acceptance/features/NNNN-slug/` (the main positive path and the main negative one, end-to-end through the product's public edge, never importing product code; at the other levels it is optional), in the language's usual style and following `SPEC_TEST_STYLE` (`unit`, `e2e` or `mixed`; in `mixed`, pick per requirement). Unit tests may import the code under test and use fakes behind the ports. At least one test overall is negative (`NEGATIVE` in its name).
- **fix:** a regression test that reproduces the bug, in the language's usual style. A black-box test only if the bug broke what the core promises.
- **refactor and chore:** no red. Run `scripts/evidence.sh green NNNN` now to record the baseline (everything passes before the change), then skip to step 4.

Names carry the requirement id (`S0001_R1_...`). Make sure `TEST_SPECS_CMD` (all spec tests) and `TEST_SPEC_CMD` (every test that carries one spec's id, black-box and language ones, with `{spec}` in it) are set in `.harness.env`.

If `core_change` is true, update the core test first (with the user's yes). It will fail until the code changes; that failure is part of this red. Its commit needs `Core-Change: <reason>`.

Run `scripts/evidence.sh red NNNN "<why they fail>"`. It checks that the tests for this kind exist, that the new tests fail in BOTH stages (the feature's black-box test and the language-style tests), that the core tests still pass (unless `core_change`) and that a negative test exists, then records it in the spec and creates the checklist `specs/NNNN-slug.checklist.md`. A test that passes before any code is written proves nothing: strengthen it. Do not write product code until this evidence exists. Commit: `test(S<NNNN>): add failing tests for <slug>`.

## 4. GREEN: the least code that passes

- Put code in the right layer. New code uses the right pattern from the start (port, then adapter, wired in `app/`).
- Do not edit the pilot's adapters unless a requirement forces it. New behavior goes into new modules or adapters.
- No cleanup and no extras in this phase. Small steps; run the spec tests and the core tests after each one.
- Run `scripts/evidence.sh green NNNN`. Verification has two stages in this order. Stage 1, black-box: the core test, then this feature's test, then every other feature's. Stage 2, only if stage 1 passed: this spec's language-style tests, the other specs', the contracts and `scripts/arch-check.sh`. The run updates the checklist (`specs/NNNN-slug.checklist.md`, the core test on top) and records the pass only if every box is checked. If a stage fails, fix the code and run it again. A spec that passes its own tests but breaks the core is not done. Commit: `feat(<scope>): <what it does>` (or `fix(...)`).
- For a refactor or chore, this phase is the change itself, made after the baseline green and with every test still passing.

## 5. REVIEW

The review starts only when the checklist is complete (`scripts/evidence.sh review` refuses otherwise). Follow `REVIEW_MODE` (see "Review" in `AGENTS.md`). `auto`: run the `reviewer` agent on the diff and report its findings; the user triages every finding. `external`: say the work is ready for the user's own reviewer and wait for the verdict. Then run `scripts/evidence.sh review NNNN "<who, verdict, what was accepted or rejected>"`. `off`: skip this phase and go to the refactor.

## 6. REFACTOR

Only now. Apply the accepted findings and tidy the code (names, duplication, layer boundaries) without changing behavior. Run `scripts/evidence.sh refactor NNNN` to prove everything is still green. Commit: `refactor(<scope>): ...`.

## 7. Close and loop

- Set the spec status to `done`. Update `PLANKS.md` (levels, "Parked", resolved pains) and the layer map if it changed. If the demand came from `BACKLOG.md`, write the spec number in its Spec column, set it to `done` and run `scripts/backlog.sh`.
- Continue with the `ship` workflow (changelog, then the push, which asks). The next demand starts a new cycle with `spec`. For a spec of size M, you may run the cycle once per group of requirements.
