---
id: S0000
status: draft   # draft | in-progress | done
size: S         # S fits one session | M becomes a few tasks | L split it before implementing
planks: []      # planks this spec touches
---

# S0000: title

> Write the text in `SPEC_LANGUAGE` (`.harness.env`; the native language when empty). Headings, ids, Given/When/Then keywords and test names stay in English. One spec solves one real problem. No MoSCoW.
> Copy this file to `specs/NNNN-slug.md` (NNNN = next free number) with `/spec`.

## Pain

The real problem this spec solves: who hits it, how often, what is the evidence.

## Out of scope

What this spec will NOT do.

## Requirements

| ID | Requirement | Kind |
|---|---|---|
| S0000-R1 | | positive |
| S0000-R2 | | negative (NEG) |

## Acceptance criteria

Each criterion is verifiable by a test. Every sad path and every "must never happen" is a negative test.

```gherkin
# S0000-R1 (positive)
Given <context>
When <action>
Then <observable result>

# S0000-R2 NEG (negative)
Given <context where it must be refused>
When <action>
Then <it is rejected / nothing is sent / nothing is written>
```

## Tests

Under `SPEC_TESTS_DIR`, in the language's usual style (`SPEC_TEST_STYLE`: unit, e2e or mixed). Test names carry the requirement id (`S0000_R1_...`); negative ones carry `NEG`.
Done means: core tests, these tests, the other specs' tests and the contract tests of every port touched all pass.

## Evidence

Filled by `scripts/evidence.sh <red|green|review|refactor> NNNN`. Do not edit by hand.
