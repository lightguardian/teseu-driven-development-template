# acceptance/core/

The pilot's black-box tests: the observable result the user asked for (`A01`) and what must never happen (`A02`, with `NEG` in the name).

This folder is the contract with the user. Do not edit, weaken or delete a test here to make a change pass. If the goal itself changed, confirm it with the user and add `Core-Change: <reason>` to the commit message; a git hook enforces this.
