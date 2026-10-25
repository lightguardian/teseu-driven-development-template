---
id: S0000
status: draft   # draft | in-progress | done
size: S         # S fits one session | M becomes a few tasks | L split it before implementing
planks: []      # planks this spec touches
---

# S0000: title

> Write in the team's native language. One spec solves one real problem. No MoSCoW.
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

Folder: `acceptance/specs/NNNN-slug/`. Test names cite the requirement id; negative ones carry `NEG`.
Done means: core tests, these tests and the contract tests of every port touched all pass.

## Evidence

Filled by `scripts/evidence.sh <red|green|review|refactor> NNNN`. Do not edit by hand.
