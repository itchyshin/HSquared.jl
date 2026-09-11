# H3 r_am launcher-depot recovery — 2026-09-10

Job `2833083` was stopped after task IDs 495–504 exited before writing any
receipt. Retained stderr identifies the cause uniformly: the batch launcher
could not load `Optim`, because `JULIA_DEPOT_PATH` omitted the existing H1
offline depot. This is deployment plumbing, not a model or fixture result.

The repair is deliberately narrow: the launcher now pins
`$ROOT/julia-depot:$H1_DEPOT` and `JULIA_PKG_OFFLINE=true`. Test-first evidence:
the launcher test first failed for all three missing strings; after the repair it
passed 18 assertions. The manifest changed from a single failure range to two
closed, named failure windows (490–494 scheduler SIGBUS; 495–504 missing Optim),
binds the revised launcher SHA-256, resumes at task 505, and rejects mutation.

Before any successor task is submitted, the exact sealed source must load
`HSquared` on Narval with the launcher environment and no fit. The ten failed
task IDs must then be materialized as non-interval receipts and hash-verified;
they are not eligible for a retry or replacement. No promotion or release is
part of this amendment.
