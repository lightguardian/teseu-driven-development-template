# specs/

One file per demand: `NNNN-slug.md`, created by `/spec` from `_template.md`.

- The text is written in `SPEC_LANGUAGE` (see `.harness.env`; the native language when empty). Headings, ids and Given/When/Then keywords stay in English.
- Every spec has a `kind`: `feature` (a new capability), `fix` (a bug), `refactor` or `chore` (no new behavior). The kind decides its tests: a feature gets one black-box test in `acceptance/features/` plus language-style tests; a fix gets a regression test; a refactor or chore gets none and has no red.
- One spec solves one real problem.
- Requirements are numbered (`S0001-R1`) and every test cites them.
- Criteria use Given/When/Then, including the sad paths. Sad paths become negative tests (`NEG`).
- A spec has a size (S, M, L; L means split it first) and no MoSCoW priority.
- The `## Evidence` section at the end proves the red, green, review and refactor phases. It is filled by `scripts/evidence.sh`.

The spec's tests live under `SPEC_TESTS_DIR` (default `tests/`), in the language's usual style: unit, end-to-end or mixed (`SPEC_TEST_STYLE`). Their names carry the spec id (`S0001_R1_...`).
