# specs/

One file per demand: `NNNN-slug.md`, created by `/spec` from `_template.md`.

- One spec solves one real problem.
- Requirements are numbered (`S0001-R1`) and every test cites them.
- Criteria use Given/When/Then, including the sad paths. Sad paths become negative tests (`NEG`).
- A spec has a size (S, M, L; L means split it first) and no MoSCoW priority.
- The `## Evidence` section at the end proves the red, green, review and refactor phases. It is filled by `scripts/evidence.sh`.

The spec's tests live in `acceptance/specs/NNNN-slug/`.
