# acceptance/

The only black-box tests of the method, which means end-to-end tests through the product's public edge, written with whatever tool you prefer. All of this is optional: `TEST_LEVEL` in `.harness.env` sets how much testing the project asks for (`none`, `unit`, `core` by default, or `full`).

- `core/`: the pilot's test, the contract with the user. It is revisited on every demand ("does this still make sense?") and changes only on purpose: when the product's promise itself changes. A commit that modifies or deletes it needs a `Core-Change:` footer.
- `features/NNNN-slug/`: one black-box test per `feature` spec, for demands that add a capability. They may become obsolete; changing or retiring one needs an `Acceptance-Change:` footer.

Rules for every test here:

- **Black box.** Talk to the product only through its public edge (command line, HTTP, files, a test sink...). Never import product code (`scripts/arch-check.sh` enforces it). That is what lets any layer, even the language, be replaced and still be checked by the same tests.
- **Positive and negative.** A positive test proves the thing works (`A01`, `S0002_R1_...`). A negative test proves the wrong thing does not happen (`A02`, with `NEG` in the name).
- **Red first.** Write the test, watch it fail for the right reason, and record it with `scripts/evidence.sh red ... "<why it fails>"` before writing product code.
- **Not for everything.** A refactor, a chore or a bug fix has no black-box test here: nothing observable from outside is new.

Their commands are `TEST_CORE_CMD`, `TEST_FEATURES_CMD` (all the features) and `TEST_FEATURE_CMD` (one feature, with `{spec}`). Verification runs them first (stage 1), and only then the language's own tests (stage 2).

The tests of the details are not here: they are the language's usual unit or end-to-end tests, in `SPEC_TESTS_DIR` (default `tests/`). The test runner is chosen by `/start` for your stack and configured in `.harness.env`.
