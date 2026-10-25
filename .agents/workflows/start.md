---
description: Quick interview, layer map, failing acceptance test first, then a fast decoupled pilot you can use today.
---

# Start (the pilot)

Arguments: optional free text with the idea. Ask in `NATIVE_LANGUAGE`, write code in English.

Goal: a usable product that does ONE thing, already in the user's hands, built fast but in swappable layers. This works for any kind of project (a script, an API, a bot, a site, a report, a game...). No PRD, no MoSCoW, no per-story Given/When/Then. The cycle is red, green, review, refactor (see `AGENTS.md`).

## 1. Prepare (silently)

- Run `scripts/setup.sh` (git hooks). Read `.harness.env`; make sure `NATIVE_LANGUAGE` is set.
- If `acceptance/core/` already has tests, the pilot exists: stop and suggest `spec` or `planks`.

## 2. Interview (one question at a time, at most 5, skip what was already said)

1. **What do you want to do?** Ask for ONE function: the smallest thing that would already be useful. If the idea has many parts, ask which one hurts most and write the rest under "Parked" in `PLANKS.md`.
2. **Who feels the pain and what happens today without it?** One sentence is enough.
3. **How will we know it worked, and what must never happen?** Ask for the observable final result: what exists or arrives, where and in what format (a message in an inbox with this subject, a file with these columns, a JSON response, a line in a report, a game state). Then ask for the worst wrong outcome (it goes to the wrong person, a duplicate, bad input accepted, data lost). The first becomes the positive test, the second the negative test.
4. **Does anything need to be robust from day 0?** Real database, authentication, payments, other people's data, messages to third parties. If yes, that plank starts at L2 or L3 and you must say which real data the pilot will touch (see "Real-world risk" in `AGENTS.md`).
5. **Do you already have an architecture or a stack in mind?** Optional. Default: the stack already in the repository, otherwise the one the user knows best. If there is nothing to base a choice on, propose one and ask for a yes.

## 3. Layer map

From the answers, draft the layers this project will have and show them to the user as a table. Ask ONE question: "Is anything missing or extra?" Think about each kind:

- **code:** the four layers (`ports/`, `core/`, `adapters/`, `app/`);
- **services:** every external service the product will call (an e-mail provider, a payment gateway, an AI API, a map...), each one an adapter behind its own port;
- **data:** database, files, cache, queue;
- **interfaces:** how the product is used (CLI, the project's own API, a UI, a scheduled job);
- **tests:** acceptance, contracts, unit;
- **infrastructure:** configuration and secrets, authentication, logs, deployment.

Write the confirmed table in the "Project layers" section of `docs/architecture.md` (layer, kind, what lives here, port, where it starts, what would make it change). Every swappable layer also becomes a row in `PLANKS.md`. The map is an estimate: `spec` and `swap` keep it current.

## 4. Write `PILOT.md`

Fill the template with the answers: pain, who, the single function, "done when" (the observable result), "must never happen", the edge the tests will use, the stack, the robust-from-day-0 items, the appetite (how long or how many tokens this pilot is worth). Half a page.

## 5. RED: the tests come first

- Create in `acceptance/core/`: a positive black-box test (`A01`) for the observable result and at least one negative test (`A02`, with `NEG` in its name) for what must never happen. They talk to the product only through its edge and never import product code.
- Fill `RUN_CMD` and `TEST_CORE_CMD` in `.harness.env` (and `LAYERS_DIR` if the stack needs another folder).
- Run `scripts/evidence.sh red core "<why they fail>"`. It must fail for the right reason (the product does not exist yet, not a typo in the test), and it records the failure in `PILOT.md`. If it passes, the test proves nothing: fix the test.
- No product code before this evidence exists. Commit: `test: add the core acceptance tests`.

## 6. GREEN: the least code, fast, in layers

- Under `LAYERS_DIR` create `ports/`, `core/`, `adapters/` and `app/` as described in `AGENTS.md`, following the layer map.
- One port per thing that may change later. Each port gets at least one dumb adapter (hardcoded, in memory, a file, a fake of the external service). Spend two minutes on each port's shape and none on making the adapter good.
- Only `app/` wires adapters to ports.
- Loop until the core tests pass. If the same test fails twice for the same reason, stop and report.
- Run `scripts/evidence.sh green core`. It runs the core tests and `scripts/arch-check.sh` and records the pass. Commit: `feat: add the pilot`.

## 7. REVIEW and REFACTOR

- Review, according to `REVIEW_MODE` (see "Review" in `AGENTS.md`). `auto`: run the `reviewer` agent on the diff and report its findings; the user triages. `external`: say the work is ready for the user's own reviewer and wait for the verdict. Then run `scripts/evidence.sh review core "<who, verdict, what was accepted or rejected>"`. `off`: skip to the refactor.
- Refactor only now, and only what the review accepted or the layers require. Run `scripts/evidence.sh refactor core` to prove the tests are still green. Commit: `refactor: ...`.

## 8. Hand over

- Tell the user in three lines how to use the product right now.
- Fill `PLANKS.md`: one row per plank with its port, level (L0 to L3), current adapter, and the next level. Leave "trigger" empty until a pain shows up.
- Add the product's terms to `GLOSSARY.md`.
- Move the method's `README.md` to `docs/teseu-dd.md` and write a short `README.md` for this product from `PILOT.md` (how to run, how to test).
- `LICENSE` is the template's own MIT license. Ask one question: keep it, replace it with the license the user chooses, or delete it.
- Run `scripts/changelog.sh` and commit it as `docs(changelog): update changelog`, so the history starts with the pilot.
- Close with: "Use it. When something hurts, run /pain. When you want something new, run /spec. When you want to write several demands down, run /backlog." Do not push; that is `ship`.
