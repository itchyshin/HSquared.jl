# 2026-07-14 — v0.7 D0F retry-2 blocker and retry-3 prospective repair

- Retry 2 is unadjudicated: 576 R fits, 576 base-R recomputations, zero Julia
  replay rows.
- Julia command construction now forces concrete strings and reproduces the
  exact `SubString` Git-root runtime type.
- Added a zero-seed `preflight` mode that opens only the sealed inputs and
  executes exact Julia commit/blob/sidecar/ancestry/clean-tree checks before
  smoke or official fitting.
- Fresh adversarial review found and the repair now rejects pre-existing output
  subtrees/summaries; the R producer/downstream low-convergence contract is
  cross-layer tested at zero and one successful fit.
- R freezes disjoint retry-3 seeds and hardened downstream evidence schemas,
  history, summaries, reviews, canonical paths, and deployed Git state.
- Checks: Julia selftest/full `Pkg.test()` PASS; R 52 + 222 + 157 focused
  assertions and built-package check 0/0/0 PASS; sidecars/diff checks PASS.
  Fresh exact preflight review: Grace CLEAN, Fisher/Noether BLOCKED; both
  findings are repaired and await exact review renewal.
- No recovery, D1/D2 seed, activation, capability/count move, release, G10, or
  GitHub Actions campaign occurred.
