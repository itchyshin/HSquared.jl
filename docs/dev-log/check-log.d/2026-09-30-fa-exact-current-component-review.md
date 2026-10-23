# 2026-09-30 exact-current FA component review

- Kirkpatrick specialist (Astra, high reasoning) reviewed current T4/K1 FA engine, multistart, uniqueness-map, and expected-information test pins. Hashes and the scoped verdict are in `docs/dev-log/source-review/2026-09-30-fa-exact-current-component-review.md`.
- Verdict: component PASS, whole A2 HOLD. The review found no new correctness defect in the bounded cell. It confirms the expected-information test is plug-in expected information and the current start tests establish the declared selection behavior, not robust recovery.
- The exact current Julia integrated candidate passed full `Pkg.test()` on these source/test bytes. The exact suite receipt is `docs/dev-log/check-log.d/2026-09-30-va-schur-recheck.md`.
- A stale RNG-free source docstring remains. Preflight found six refs with work on `src/multivariate.jl`; no source edit was made pending diff and ownership reconciliation.
- Separate current R live bridge run passed 213/213 with zero warnings or skips; R receipt: `hsquared/docs/dev-log/check-log.d/2026-09-30-live-fa-gllvm-bridge-recheck.md`. This does not close A2, E1, or V3.
