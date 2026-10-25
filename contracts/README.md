# contracts/

One test suite per port. The same suite runs against EVERY adapter of that port (hardcoded, in memory, sqlite, postgres...). If a new adapter passes the contract, it is a valid replacement. This is what makes a plank swap safe.

Include negative tests (`NEG`): what the port must refuse or must not do (invalid input rejected, nothing written when an operation fails).

Unlike `acceptance/`, contract tests may import the adapters they exercise. Configure the runner in `.harness.env` (`TEST_CONTRACTS_CMD`).
