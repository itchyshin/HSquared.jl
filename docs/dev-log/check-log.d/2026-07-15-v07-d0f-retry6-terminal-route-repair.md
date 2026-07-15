# Check log — Retry-6 terminal route blocker and seed-free repair

- Every pre-RNG Retry-6 gate passed before the first phenotype: two separated
  review batches, clean deploy, retired-packet preflight, seed lock, preseal,
  bootstrap materialization, Julia zero-seed preflight, and chronology audit.
- Totoro D0F completed 576 official fits, 576 base-R recomputations, and 576
  Julia replays. All three summaries were complete; maximum attempt parity was
  `3.1832314562052488e-12` and maximum summary parity
  `7.1054273576010019e-15`.
- The first post-run receipt writer failed before writing a receipt because
  Julia replay rows were re-admitted under the ordinary-R route during summary
  reconstruction. Exact diagnostics found zero malformed evidence rows.
- Retry-6 root frozen read-only: 9,248 files / 598 directories; content digest
  `148da8ef…d754f` unchanged; freeze log `f34da1d2…a0255`; no live worker.
- R seed-free repair checks: recovery-v3 family **822 pass / 0 fail / 0 warn /
  0 skip**; official driver, recomputer/adjudicator, admission, D0F/D1 preseal,
  and seed-lock selftests passed; recomputer sidecar and `git diff --check`
  passed. The seed-lock-focused file passed 60/60 after classifying 42,067
  historical seeds and 3,456 retired D0F seeds.
- Public boundary: no Retry-6 adjudication, D1, D2, activation, capability move,
  merge, release, G10, or `public_covered_count` change.
- Julia exact-head CI initially exposed a pre-existing platform-sensitive
  boundary contract: Linux/Julia 1.10 returned finite-difference SEs for an
  almost rank-one fitted covariance that local Julia 1.10 rejected. The SE
  path now directly rejects fitted genetic or residual correlations within
  `1e-6` of `-1` or `1`, before relying on the finite-difference information
  matrix. Full local Julia 1.10 `Pkg.test()` passed after the repair; the
  original exact-head run was green on current Julia and red only on 1.10.
