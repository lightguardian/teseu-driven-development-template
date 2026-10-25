# Backlog

> Optional. The default way of working is one demand at a time: something hurts (`/pain`), you ask for it (`/spec`), it gets built. Use this file only when you want to write down several demands to do one by one later. A backlog item is a one-line idea, not a spec: no Given/When/Then here.
> Ordering method: `PRIORITIZATION` in `.harness.env` (none, moscow, rice, ice). `/backlog` adds items and `scripts/backlog.sh` recomputes the scores and sorts the table. Do not put the | character inside a cell.

## Demands

| ID | Demand | Status | Spec |
|---|---|---|---|

Status: `idea` | `ready` | `in-progress` | `done` | `dropped`. The Spec column gets the spec number (`0001`) when `/spec` starts.

## Methods

| Method | Columns | Score | Use it when |
|---|---|---|---|
| `none` | Status, Spec | none, you order by hand | one person, few demands, the default |
| `moscow` | MoSCoW (Must, Should, Could, Won't) | buckets, no number | you must fit a fixed deadline or release |
| `rice` | Reach, Impact, Confidence, Effort | Reach x Impact x Confidence% / Effort | many demands and some idea of how many people or how often |
| `ice` | Impact, Confidence, Ease (1 to 10) | Impact x Confidence x Ease | quick and rough ranking, little data |

RICE scales: Reach is how many people or occurrences per period (use the same period for all items); Impact is 3 massive, 2 high, 1 medium, 0.5 low, 0.25 minimal; Confidence is a percentage (100, 80 or 50; below 50 is a moonshot); Effort is in work sessions (a spec of size S is 1, M is about 3, L is about 8; split L).

Other methods that this template does not automate: WSJF (cost of delay divided by job size, for committed work in larger teams), Kano (needs customer surveys), Value vs Effort (a quick 2x2 matrix) and Story Mapping (for a first MVP). If you want one of them, keep it in `none` mode and write your own columns in the Demand text.
