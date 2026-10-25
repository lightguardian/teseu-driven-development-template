---
description: Interview for a new demand, write a numbered spec, then red, green, review and refactor with positive and negative tests.
---

# Spec (one real problem at a time)

Arguments: what the user wants, in free text. Ask in `NATIVE_LANGUAGE`.

## 0. Precondition

Run `scripts/test.sh core`. If it is not green, stop: the product is already broken, so fix that first (or ask the user). If the demand is an item of `BACKLOG.md`, use it as the starting point and set it to `in-progress` when the spec is created.

## 1. Interview (one question at a time, at most 5)

1. **Was the previous pain solved?** Look at `PLANKS.md` (pain log) and the last spec. Is this still the most important thing to do now?
2. **What real problem does THIS spec solve?** Who hits it, how often, what is the evidence? If the user cannot name a real problem, say so and suggest not doing it.
3. **What changes for the user, in observable terms?** This becomes the positive acceptance criteria.
4. **What must it NOT do, and what must never happen?** The first becomes "Out of scope", the second becomes the negative tests.
5. **Which plank does it touch?** A new plank, a new adapter, or a replacement? If the demand is really "make X better or more robust", it is a swap: continue with `swap` instead.

## 2. Write `specs/NNNN-slug.md`

Copy `specs/_template.md` (NNNN is the next free number). Write the text in `SPEC_LANGUAGE` (the same as `NATIVE_LANGUAGE` when it is empty; headings, ids and Given/When/Then keywords stay in English). Fill: the pain, out of scope, requirements numbered `S<NNNN>-R1..Rn`, acceptance criteria in Given/When/Then including the sad paths (error, empty, abandonment), size S/M/L (L means split it first), the planks touched. Mark which criteria are negative. No MoSCoW (priorities live in `BACKLOG.md`, if the user keeps one). If it needs new vocabulary, update `GLOSSARY.md`. If it needs a layer that is not on the layer map in `docs/architecture.md` (a new external service, a new kind of storage, a new interface), add it to the map and to `PLANKS.md` before going on.

## 3. RED: the tests come first

- Write one test per criterion under `SPEC_TESTS_DIR`, in the language's usual test style and following `SPEC_TEST_STYLE` (`unit`, `e2e` or `mixed`; in `mixed`, pick per requirement). Unlike the core test, these are not black-box by rule: unit tests may import the code under test and use fakes behind the ports. Names carry the requirement id (`S0001_R1_...`). Every sad path and every "must never happen" becomes a negative test with `NEG` in its name; there must be at least one.
- Make sure `TEST_SPECS_CMD` (all spec tests) and `TEST_SPEC_CMD` (one spec, with `{spec}` in it) are set in `.harness.env`.
- Run `scripts/evidence.sh red NNNN "<why they fail>"`. It checks that the new tests fail, that the core tests still pass and that a negative test exists, then records it in the spec. A test that passes before any code is written proves nothing: strengthen it.
- Do not write product code until this evidence exists. Commit: `test(S<NNNN>): add failing tests for <slug>`.

## 4. GREEN: the least code that passes

- Put code in the right layer. New code uses the right pattern from the start (port, then adapter, wired in `app/`).
- Do not edit the pilot's adapters unless a requirement forces it. New behavior goes into new modules or adapters.
- No cleanup and no extras in this phase. Small steps; run the spec tests and the core tests after each one.
- Run `scripts/evidence.sh green NNNN`. It runs the core tests, the spec's tests, the other specs' tests, the contract tests and `scripts/arch-check.sh`, and records the pass. A spec that passes its own tests but breaks the core is not done. Commit: `feat(<scope>): <what it does>`.

## 5. REVIEW

Follow `REVIEW_MODE` (see "Review" in `AGENTS.md`). `auto`: run the `reviewer` agent on the diff and report its findings; the user triages every finding. `external`: say the work is ready for the user's own reviewer and wait for the verdict. Then run `scripts/evidence.sh review NNNN "<who, verdict, what was accepted or rejected>"`. `off`: skip this phase and go to the refactor.

## 6. REFACTOR

Only now. Apply the accepted findings and tidy the code (names, duplication, layer boundaries) without changing behavior. Run `scripts/evidence.sh refactor NNNN` to prove everything is still green. Commit: `refactor(<scope>): ...`.

## 7. Close and loop

- Set the spec status to `done`. Update `PLANKS.md` (levels, "Parked", resolved pains) and the layer map if it changed. If the demand came from `BACKLOG.md`, write the spec number in its Spec column, set it to `done` and run `scripts/backlog.sh`.
- Continue with the `ship` workflow (changelog, then the push, which asks). The next demand starts a new cycle with `spec`. For a spec of size M, you may run the cycle once per group of requirements.
