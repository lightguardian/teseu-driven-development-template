# Planks

> The ship's parts. One row per part that can be replaced on its own. Seeded from the layer map in `docs/architecture.md` by `/start`. Write in the team's native language.
> A plank is replaced when a real pain or a spare appetite says so, never "just because".

## Levels

| Level | Meaning | Examples |
|---|---|---|
| L0 | Hardcoded or fake, good enough to prove the idea | constants in code, a fixed list |
| L1 | Simple and local | in-memory, a file, a spreadsheet, a fake of an external service |
| L2 | Real but simple service | sqlite, a single process, a simple queue, the real external service on a free plan |
| L3 | Robust | postgres, managed queue, authentication, backups, monitoring |

## Planks

| Plank | Port | Level | Adapter now | Next level | Trigger (the pain) | Appetite |
|---|---|---|---|---|---|---|
| (example) data | `ports/records` | L0 | hardcoded list | L2 sqlite | I had to edit code to change the list | 1 session |

## Pain log

Newest first. Severity: 1 annoying, 2 slows me down, 3 blocks me or is risky. Filled by `/pain`.

| Date | Plank | Severity | What hurts | Status |
|---|---|---|---|---|

## Parked

Ideas that are not for now. Each one waits for a real pain to justify it. To order several demands, use `BACKLOG.md`.

-

## Swap history

One line per completed swap: date, plank, from, to, why, what became harder.

-

## Evidence

Filled by `scripts/evidence.sh <red|green|review|refactor> swap`. Do not edit by hand.
