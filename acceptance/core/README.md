# acceptance/core/

The pilot's black-box test: the observable result the user asked for (`A01`) and what must never happen (`A02`, with `NEG` in the name).

This is the contract with the user. Every demand asks one question about it: does it still make sense? If the product's promise really changed (the e-mail no longer carries an image, so the test that expects one is wrong), update the test first, with the user's confirmation, and add `Core-Change: <reason>` to the commit message; a git hook enforces this. Never edit, weaken or delete a test here just to make a change pass.
