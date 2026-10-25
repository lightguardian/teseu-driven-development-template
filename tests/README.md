# tests/

The tests of the specs, in the language's usual style. Not black-box by rule: unit tests may import the code under test and use fakes behind the ports; end-to-end tests may drive the whole product. `SPEC_TEST_STYLE` in `.harness.env` says which one to write (`unit`, `e2e` or `mixed`).

- Names carry the requirement id (`S0001_R1_...`) so `TEST_SPEC_CMD` can run the tests of one spec.
- Negative tests carry `NEG` (`S0001_R2_NEG_...`). Every spec needs at least one.
- This folder is the default. Set `SPEC_TESTS_DIR` in `.harness.env` if your language keeps tests elsewhere (for example next to the code).
- The core test of the pilot is not here: it lives in `acceptance/core/` and is the only black-box suite.
