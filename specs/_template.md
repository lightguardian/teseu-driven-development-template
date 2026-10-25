---
id: S0000
kind: feature   # feature | fix | refactor | chore
status: draft   # draft | in-progress | done
size: S         # S fits one session | M becomes a few tasks | L split it before implementing
core_change: false   # true when this demand changes what the pilot promises (the core test)
tests: auto     # auto | none (this demand cannot or need not be tested; say why under ## Tests)
planks: []      # planks this spec touches; the first is the central point, more than two means split it
---

# S0000: title

> Write the text in `SPEC_LANGUAGE` (`.harness.env`; the native language when empty). Headings, ids, Given/When/Then keywords and test names stay in English. One spec solves one real problem. No MoSCoW.
> Copy this file to `specs/NNNN-slug.md` (NNNN = next free number) with `/spec`.

## Pain

The real problem this spec solves: who hits it, how often, what is the evidence.

## Out of scope

What this spec will NOT do.

## Requirements

For a `refactor` or `chore`, write what must NOT change (the behavior stays the same) and why the change is worth it.

| ID | Requirement | Kind |
|---|---|---|
| S0000-R1 | | positive |
| S0000-R2 | | negative (NEGATIVE) |

## Acceptance criteria

Each criterion is verifiable by a test. Every sad path and every "must never happen" is a negative test. Not needed for a `refactor` or `chore`.

```gherkin
# S0000-R1 (positive)
Given <context>
When <action>
Then <observable result>

# S0000-R2 NEGATIVE (negative)
Given <context where it must be refused>
When <action>
Then <it is rejected / nothing is sent / nothing is written>
```

## Tests

- `feature`: one black-box test in `acceptance/features/NNNN-slug/` (the main positive path and the main negative one, through the product's public edge) and tests in the language's usual style under `SPEC_TESTS_DIR` (`SPEC_TEST_STYLE`: unit, e2e or mixed) for the details.
- `fix`: a regression test that fails first, in the language's usual style. A black-box test only if the bug broke what the core promises.
- `refactor` and `chore`: no new tests. Core, features and specs stay green.

Test names carry the requirement id (`S0000_R1_...`); negative ones carry `NEGATIVE`.
Done means: core tests, these tests, the other specs' tests and the contract tests of every port touched all pass.

## Evidence

Filled by `scripts/evidence.sh <red|green|review|refactor> NNNN`. Do not edit by hand.
