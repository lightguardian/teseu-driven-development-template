# Pilot

Status: not started   <!-- /start changes it to: started -->

> Half a page, filled by `/start`. Write in the team's native language (`NATIVE_LANGUAGE`).
> The pilot does ONE thing. Everything else goes to "Parked" in `PLANKS.md`.

## Pain

Who suffers and what happens today without this.

## The one function

The smallest thing that would already be useful.

## Done when (positive test `A01`)

The observable final result: what arrives, where and in what format.

## Must never happen (negative test `A02`, with `NEG` in its name)

The worst wrong outcome: a message to the wrong person, a duplicate, bad input accepted.

## Edge

How the tests reach the product from outside: command line, HTTP, files, a test SMTP sink...

## Stack and architecture hint

The stack in use, and any architecture the developer already has in mind (optional).

## Robust from day 0

Anything that cannot be a toy even in the pilot (real database, authentication, payments, third-party data, messages to third parties), and which real data the pilot will touch.

## Appetite

How much time or how many tokens this pilot is worth.

## Evidence

Filled by `scripts/evidence.sh <red|green|review|refactor> core`. Do not edit by hand.
