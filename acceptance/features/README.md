# acceptance/features/

The black-box tests of the `feature` specs: one folder per spec, `acceptance/features/NNNN-slug/`.

A feature is a demand that adds a new capability (for example, a second currency next to the first). It gets exactly one black-box test here, covering the main positive path and the main negative one, through the product's public edge. The details of the feature are tested in the language's usual style under `SPEC_TESTS_DIR`.

Refactors, chores and bug fixes do not get a black-box test here. A bug fix gets a regression test in the language's style, unless the bug broke what the core promises.

Rules (the same as `acceptance/core/`):

- **Black box.** Talk to the product only through its public edge. Never import product code (`scripts/arch-check.sh` enforces it).
- **Name the spec.** Test names carry the requirement id (`S0002_R1_...`); negative ones carry `NEGATIVE`.
- **Red first.** Write the test, watch it fail for the right reason, and record it with `scripts/evidence.sh red NNNN "<why it fails>"`.
- **Together with `acceptance/core/`, this folder is the safety net of a full rewrite** (another language, another stack): everything here must pass against the new implementation.

These tests may become obsolete over time, and that is fine. Modifying, retiring or deleting one needs an `Acceptance-Change: <why>` footer in the commit message (a git hook enforces it).
