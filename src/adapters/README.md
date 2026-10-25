# adapters/

Implementations of the ports: hardcoded, in memory, a file, sqlite, postgres, SMTP...

An adapter is the two-way door: in the pilot it may be as dumb as you like, because it will be replaced. It depends on `ports/` (and on `core/` types only when unavoidable), never on `app/`. Each plank in `PLANKS.md` points to the adapter that serves it today.
