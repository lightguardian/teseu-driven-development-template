---
description: Show the planks, their levels and logged pains, and suggest the next swap.
---

# Planks

Read-only. Change nothing unless the user then asks for a swap.

1. Read `PLANKS.md`, the specs in `specs/`, and `git log --oneline -30`.
2. Print the planks table: plank, port, level, adapter now, next level, trigger, appetite.
3. List the open pains from the pain log, newest first.
4. Flag these situations:
   - a plank at L0 or L1 that touches real or third-party data (risk);
   - a plank with a pain logged more than once (strong trigger);
   - a plank that got several `fix(...)` commits since the pilot (stop patching, swap it);
   - parked ideas that a recent spec made cheap.
5. Suggest at most two swaps, each with: the plank, from level to level, why now, and the appetite. Ask which one to run with `swap`.
