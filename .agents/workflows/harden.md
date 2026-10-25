---
description: Raise the rigor level (R1, R2, R3), creating only the documents and checks that level needs.
---

# Harden

Arguments: the target level (`R1`, `R2`, `R3`). Default: the next one after `RIGOR` in `.harness.env`.

Never lower a level. Show the user what will change and wait for a yes. Documents are generated in reverse mode: from the code, the specs and the tests that exist. Never invent a business rule; unknowns go to "Open questions".

| Level | When | What turns on |
|---|---|---|
| R0 | Pilot, personal use | `PILOT.md`, `PLANKS.md`, layer map, core tests, Conventional Commits, changelog, push asks |
| R1 | Used every day | `RUN_CORE_BEFORE_PUSH=true`, a contract suite for every port, a product README, a complete `.env.example` |
| R2 | Other people use it | `docs/prd.md` from `.agents/templates/prd.md` (reverse), `docs/architecture.md` kept current, CI (`.agents/templates/ci.yml` to `.github/workflows/ci.yml`, with the stack's toolchain), `REVIEW_BEFORE_PUSH=true` |
| R3 | Money, third-party data, mass messages | ADR for every swap, migrations with rollback, authentication, rate limits, backups, audit trail, and a secrets scan |

Steps:

1. Read `RIGOR`, `PLANKS.md`, specs and tests. Report which items of the target level already hold and which are missing.
2. Apply the missing items one by one. Edit only `RIGOR` and the toggles of the table in `.harness.env`.
3. Tell the user what you cannot do for them: protect the default branch on GitHub (Settings, Branches), require the CI check, enable secret scanning, set up backups.
4. Commit (`chore: raise rigor to R2`) and continue with `ship`.
