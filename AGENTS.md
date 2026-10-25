# AGENTS.md

Canonical instructions for every AI agent working in this repository (Claude Code, Codex, Gemini CLI, Antigravity, Cursor, OpenCode, Copilot, Aider, Jules and others). Tool-specific files only point here.

This repository follows **Teseu-DD** (Teseu-Driven Development): ship a small, decoupled pilot that is already in use, then replace its parts one plank at a time. The acceptance tests are the only thing that never changes. The method works for any kind of project; the examples in the docs are only illustrations. The full method is in `README.md` (or `docs/teseu-dd.md` after `/start` has run).

## First thing in every session

1. Read `.harness.env`. If `NATIVE_LANGUAGE` is empty, ask the user what it is and save it there.
2. If `git config core.hooksPath` is not `.githooks`, run `scripts/setup.sh`.
3. If `TEST_CORE_CMD` is empty, the pilot does not exist yet: offer `/start`.
4. Never read or print `.env` (it holds secrets). `.env.example` is fine.

## Commands

Canonical definitions live in `.agents/workflows/<name>.md`. If your tool has no slash commands (Codex, Aider, Jules...), or the user types `/name` or says "run name", read that file and follow it exactly.

| Command | Use it when |
|---|---|
| `start` | Empty project: quick interview, layer map, one acceptance test, a fast decoupled pilot |
| `spec` | The user wants something new: interview, numbered spec, its tests, implementation |
| `backlog` | The user wants to write down several demands and order them (none, MoSCoW, RICE or ICE) |
| `verify` | Run the core, spec and contract tests plus the architecture rules |
| `planks` | Show the planks (parts), their levels and pains; suggest the next swap |
| `pain` | Something hurts: log it in `PLANKS.md` without acting |
| `swap` | Replace one plank with a better one without stopping the product |
| `harden` | Raise the rigor level (R0 to R3) |
| `review` | Run the read-only reviewer on the current changes |
| `ship` | Update the changelog, ask, push, propose the pull request |

If the user asks for new functionality in plain words, do not start coding: run `spec` first. If the user complains about something, run `pain`.

Scripts: `scripts/test.sh` (run a group of tests), `scripts/evidence.sh` (run a TDD phase and record the proof), `scripts/arch-check.sh` (layer rules), `scripts/changelog.sh` (history), `scripts/backlog.sh` (score and sort the backlog), `scripts/setup.sh` (git hooks), `scripts/sync-shells.sh` (regenerate the per-tool command files).

## The method in seven rules

1. **Acceptance tests are the contract.** `acceptance/core/` holds black-box tests of what the product delivers (the file has these columns, the message arrived). They talk to the product only through its public edge (command line, HTTP, files, a test sink...) and never import product code. Never edit, delete or weaken a core test to make a change pass. If the goal itself changed, the user must confirm, and the commit needs a `Core-Change: <reason>` footer (a git hook enforces it).
2. **Layers, always.** Even the fastest pilot is split in four code layers under `LAYERS_DIR` (default `src/`):
   - `ports/`: interfaces the core needs (data, input, delivery, clock, config...) and the plain data types that cross them. Depend on nothing but the language's standard library.
   - `core/`: business rules. Depends on `ports/` and the standard library only.
   - `adapters/`: implementations of ports (hardcoded, memory, file, sqlite, postgres, an external service...). Depend on `ports/` (and on `core/` types only when unavoidable), never on `app/`.
   - `app/`: entrypoints and wiring (CLI, HTTP, jobs). The only place that chooses which adapter runs.
   The port is the one-way door: think about it. The adapter is the two-way door: it may be as dumb as you like.
3. **Know the layers of this project.** The code layers above are only part of the picture. `docs/architecture.md` has a **layer map** for this project: code, external services (each one is an adapter behind a port), data, interfaces (including the project's own API), tests and infrastructure. `/start` writes it, every swappable layer becomes a plank in `PLANKS.md`, and any spec that needs a layer not on the map updates the map first.
4. **The pilot is frozen legacy.** After `/start`, touch the pilot's adapters only for critical bugs, always with a test. New behavior goes into new modules or adapters behind a port. If a patch to a plank is growing, stop and propose `/swap` instead of patching.
5. **Red, green, review, refactor.** Every unit of work (the pilot, a spec, a swap) follows the TDD cycle in this order: (1) write the tests and watch them fail for the right reason (red); (2) write the least code that makes them pass (green); (3) review with the read-only `reviewer`; (4) refactor with the tests staying green. Then the cycle starts again. Record each phase with `scripts/evidence.sh <red|green|review|refactor> <core|NNNN|swap>`: it runs the tests, checks that the result is the expected one, and appends the proof to the `## Evidence` section of `PILOT.md`, of the spec, or of `PLANKS.md`. Do not write product code before a red is recorded. Do not refactor before the review.
6. **Every spec has positive and negative tests.** Positive tests prove that the thing works. Negative tests prove that the wrong thing does not happen: invalid input is rejected, the forbidden action is denied, a failed operation leaves no side effect, nothing is sent to someone who opted out. Put `NEG` in the name of every negative test. The core suite and every spec need at least one, and every sad path of a Given/When/Then becomes one. A spec has numbered requirements (`S0001-R1`) and tests whose names cite them. A spec is done when the core tests, its own tests and the contract tests of every port it touched all pass. Run `scripts/test.sh core` before and after every change; if a test fails, either the test was wrong (fix it and explain; if it is a core test, ask the user) or the change broke the product (fix the code, never the test).
7. **Rigor follows use.** `RIGOR` in `.harness.env` says R0 to R3. Do not create documents or enable checks above the current level. `/harden` raises it when the user decides.

## Interviews

- One question at a time, in `NATIVE_LANGUAGE`. At most 5 per interview. Skip what the user already answered.
- If the user is vague, offer 2 or 3 concrete options instead of an open question.
- Stop as soon as you can write the test (`start`) or the spec (`spec`).
- Never invent a business rule. Ask, or park the idea in `PLANKS.md` under "Parked".
- The pilot has no PRD, no MoSCoW, no personas and no per-story Given/When/Then. Specs use Given/When/Then (with the sad paths) and size S/M/L. Priorities exist only if the user keeps a `BACKLOG.md` and chooses a method (`PRIORITIZATION`).

## Real-world risk

"Production" in this method is in quotes, but real people may be affected. If the product will send messages to third parties, handle money, or store other people's personal data, say so before its first real use and propose the R3 items (authentication, limits, backup, audit trail).

## Language

| `NATIVE_LANGUAGE` (see `.harness.env`) | English |
|---|---|
| Interviews and chat with the user | Code and identifiers |
| `PILOT.md`, `PLANKS.md`, `BACKLOG.md`, `GLOSSARY.md` text | Commits and branch names |
| Specs | Test names |
| Issues and PR descriptions | PR titles, ADRs, `docs/architecture.md`, this file |

Code comments are in English. Never mix languages inside code. Consult `GLOSSARY.md` before naming anything.

## Git rules

- Branches: `feature/<slug>`, `fix/<slug>`, `chore/<slug>`, `swap/<plank>`.
- Commits follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/): `type(scope): description`, with `!` or a `BREAKING CHANGE:` footer for breaking changes. Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert. A plank swap is usually `refactor(<plank>): ...`. A hook rejects anything else.
- **Commit without asking.** Commit at the end of each phase of the cycle (red as `test(S0001): ...`, green as `feat(...)` or `fix(...)`, refactor as `refactor(...)`), so the history shows what was done. Never use `--no-verify`.
- **Ask before every push.** If `ASK_BEFORE_PUSH` is `true`: summarize what will go out and wait for an explicit "yes" in chat before `git push`. Never force push.
- **History.** `CHANGELOG.md` is generated from the commits by `scripts/changelog.sh`. Never edit it by hand. Before a push, regenerate it and commit it as `docs(changelog): update changelog`. The pre-push hook blocks a push when it is stale (`ENFORCE_CHANGELOG`).
- The pre-push hook may also run the core tests (`RUN_CORE_BEFORE_PUSH`) and open a review window (`REVIEW_BEFORE_PUSH`). Wait for it. If it fails because nobody answered, stop and tell the user to run the command from their own terminal. Never retry in a loop.
- Never edit `.githooks/` or the review scripts, and never lower a rule in `.harness.env`. You may edit it only to fill `NATIVE_LANGUAGE`, `LAYERS_DIR`, `RUN_CMD` and `TEST_*_CMD` (during `/start`), `PRIORITIZATION` (during `/backlog`), and to raise `RIGOR` and its toggles (during `/harden`, with the user's approval).
- Never commit `.env`, keys, cookies or personal config, not even to a private repository.

## Review

Before the push, run the `reviewer` agent (read-only) on the work and report its findings. The user decides which ones to fix. You never dismiss one silently.

## Scope

Do not widen the scope of the current spec. If you find something out of scope, tell the user, or log it with `pain`. If the same test fails twice for the same reason, stop and report instead of trying a third approach.
