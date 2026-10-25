# core/

Business rules. Depends only on `ports/` and the language's standard library: it must not know about adapters, the web, the database or the e-mail provider.

If a rule needs the outside world (data, time, delivery), it asks a port for it.
