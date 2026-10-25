---
description: Write down several demands in BACKLOG.md and order them with the chosen method (none, MoSCoW, RICE or ICE).
---

# Backlog (optional)

Arguments: `add <demand>`, `method <none|moscow|rice|ice>`, `next`, `done <ID>`, `drop <ID>`, or nothing (show and re-sort).

The default way of working needs no backlog: one demand at a time, from a pain to a spec. Use this only when the user wants to write several demands down and do them one by one later. An item is one line, not a spec: no Given/When/Then, no requirements here.

Write in `NATIVE_LANGUAGE`. Never put the | character inside a cell.

## `add <demand>`

1. Read `BACKLOG.md` and `PRIORITIZATION` in `.harness.env`. The next ID is `B` plus the highest number plus one, with three digits (`B001`).
2. Ask for the scores of the current method in ONE message, with the scale, and let the user answer all at once. If the user does not know a value, propose one and say it is a guess.
   - `none`: nothing to ask.
   - `moscow`: Must, Should, Could or Won't.
   - `rice`: Reach (people or occurrences per period, same period for all items), Impact (3 massive, 2 high, 1 medium, 0.5 low, 0.25 minimal), Confidence (100, 80 or 50), Effort (work sessions: S is 1, M is about 3, L is about 8).
   - `ice`: Impact, Confidence and Ease, each from 1 to 10.
3. Add the row with status `idea`, then run `scripts/backlog.sh` to compute the score and sort. Commit: `docs(backlog): add B003`.

## `method <name>`

1. Change `PRIORITIZATION` in `.harness.env`, rewrite the table header to the columns of the new method (see the Methods table in `BACKLOG.md`) and keep every item.
2. Ask for the new scores of all open items, in one message. Run `scripts/backlog.sh`. Commit: `docs(backlog): switch to rice`.
3. If the user asks which method to choose: `none` for one person and few demands; `moscow` to fit a fixed deadline; `rice` for many demands with some idea of reach; `ice` for a quick and rough ranking. They can also be combined: scope with MoSCoW, rank within a bucket by hand.

## `next`

Show the top open items (status `idea` or `ready`) with their scores and propose starting the first one with `/spec <demand>`. Set it to `in-progress` and write the spec number in the Spec column when `/spec` creates the spec.

## `done <ID>` and `drop <ID>`

Set the status and run `scripts/backlog.sh`. `/spec` does `done` by itself when a spec closes.

## Promoting a pain

A line in the pain log of `PLANKS.md` can become a demand: add it here and mark the pain as promoted.
