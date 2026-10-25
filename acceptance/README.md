# acceptance/

Everything that proves, from the outside, that the product does what it should.

- `core/`: the pilot's tests. They are the contract with the user and the only part that never changes. A commit that modifies or deletes them needs a `Core-Change:` footer.
- `specs/NNNN-slug/`: the tests of each spec.

Rules for every test here:

- **Black box.** Talk to the product only through its public edge (command line, HTTP, files, a test SMTP sink...). Never import product code. That is what lets any layer, even the language, be replaced and still be checked by the same tests.
- **Positive and negative.** Positive tests prove the thing works. Negative tests prove the wrong thing does not happen. Put `NEG` in the name of every negative test.
- **Cite the requirement.** Spec tests carry the id (`S0001-R1`); pilot tests carry `A01`, `A02`...
- **Red first.** Write the test, watch it fail for the right reason, and record it with `scripts/evidence.sh red ...` before writing product code.

The test runner is chosen by `/start` for your stack and configured in `.harness.env` (`TEST_CORE_CMD`, `TEST_SPECS_CMD`).
