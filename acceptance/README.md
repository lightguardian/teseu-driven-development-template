# acceptance/

The only black-box tests of the method.

- `core/`: the pilot's tests. They are the contract with the user and the one part that never changes. A commit that modifies or deletes them needs a `Core-Change:` footer.

Rules for every test here:

- **Black box.** Talk to the product only through its public edge (command line, HTTP, files, a test sink...). Never import product code (`scripts/arch-check.sh` enforces it). That is what lets any layer, even the language, be replaced and still be checked by the same tests.
- **Positive and negative.** A positive test proves the thing works (`A01`). A negative test proves the wrong thing does not happen (`A02`, with `NEG` in the name).
- **Red first.** Write the test, watch it fail for the right reason, and record it with `scripts/evidence.sh red core "<why it fails>"` before writing product code.

The tests of the specs are not here: they are the language's usual unit or end-to-end tests, in `SPEC_TESTS_DIR` (default `tests/`). The test runner is chosen by `/start` for your stack and configured in `.harness.env`.
