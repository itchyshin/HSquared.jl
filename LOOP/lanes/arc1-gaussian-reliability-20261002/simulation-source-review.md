# Simulation and execution review: required next repairs

The parent independently reproduced 30 Python component tests. These do not yet prove campaign execution or simulator covariance. Source inspection and an isolated counterexample found the following required work before any study is admitted.

1. `Arc1AttemptStore.rows()` currently turns every started row without a result into an interrupted result. In the same live process, `begin(1)` followed by `rows()` creates that failure and makes `finish(1, success)` raise `FileExistsError`. Make progress reads read-only. Use explicit recovery with exclusive ownership/liveness protection; a concurrent caller must not declare an active attempt dead. Add a regression with an actively held attempt, progress reads, an overlapping worker and a genuinely dead owner. Preserve immutable completed failures and keep orphan recovery explicit.
2. Separate the immutable source root from the per-cell output directory. A single root-level `run-admission.json` and `attempts/` cannot hold multiple admitted cells. Define safe output ownership before four workers start. Revalidate source/environment before each resumed execution, and pin actual loaded engine identity and BLAS environment in execution evidence.
3. Admission currently enumerates source files statically and omits the new profile/bootstrap/interface modules. Discover or explicitly include every executed module and its tests. Validate the redundant environment hash mapping too; it must not disagree with the pinned Project/Manifest bytes. Source hashes alone do not prove which engine executed. Integrate the actual Julia executor before claiming source-bound execution.
4. The current DGP tests check pedigree covariance values and row permutation, but do not test the random generator's inheritance coefficients. Add an independent deterministic innovation-basis covariance test. With controlled standard-normal innovations, reconstruct the generator's linear map and compare its covariance to the independent pedigree oracle, genetic/residual covariance and repeatability kernels. This can catch a corrupted Mendelian coefficient without relying on a stochastic tolerance or the fitter's covariance code. Keep normal seeded generation unchanged.
5. Add the two declared exact-zero repeatability cells, which the current truth helper rejects. Return explicit record IDs for both records per offspring and test arbitrary record ordering. Restrict unsupported singular FA truth inputs or handle them explicitly; `rho=1` is currently accepted by the truth helper but fails its Cholesky simulator.
6. Expanded-reference refinements are the top four finite solutions per rank, as Astra clarified. Record this and the adopted zero-face/Brent details in the canonical contract before regenerating a reviewed manifest. Keep confirmation allocation 400 until the separate pre-study allocation decision is approved.

The runner and simulator are useful foundations. Study execution, full source admission, expanded reference, scientific gate summaries and exact-source retention remain incomplete. No campaign or calibration claim follows from the component tests.


## Scientific-checker repair review

Luna reports 40 receipt adversary tests, 14 scientific-gate tests and four launcher tests passing after six source-review repairs. The new transport fixture runs a fresh Julia child and passes its actual JSON through durable storage, receipt assembly and the Python checker. It remains explicitly synthetic test evidence, separate from studies and scientific acceptance. Logs are in `.unlazy/arc1-gaussian-reliability/evidence/receipt-admission-repairs/`.

The repaired source is frozen for an independent read-only Astra high review. The exact ten-file hash inventory, brief and dispatch are in `evidence/scientific-checkers-astra-review/`. Required checks cover common profile maxima and identities, exact Boolean/nesting guards, preserved selector audit flags, full reference histories and start provenance, external source/admission/artifact binding, and hard confirmation holds. No candidate manifest was regenerated and no allocated study was admitted. The existing cell launcher supports one explicit global outer index and a separate output root; batching/shard reconciliation is a separate pending engineering leaf.

## Fresh Astra review of receipt admission, 2026-10-02

The bounded reviewer completed in 410.156 seconds with all ten reviewed source hashes unchanged. Verdict: BLOCKED. The full report is retained in `.unlazy/arc1-gaussian-reliability/evidence/scientific-checkers-astra-review/review.md`.

Bootstrap prefix and guard validation, plus selector audit-flag transport, received bounded acceptance. Remaining defects were reproduced in profile method-version transport and pre-engine failure records; reference start, uniqueness, fallback, intermediate-maximum and iteration-budget validation; full-artifact semantic binding and returned outer/seed handling; and consistency of pilot-qualification evidence before confirmation admission. Passing 14 scientific-gate and seven focused adversary tests did not detect these defects. Luna owns the repairs. No source admission, study, or acceptance gate was created by this review.

## Second receipt-admission review

Astra's second review completed in 572.701 seconds with eleven scoped hashes unchanged. Verdict: BLOCKED. The original reference mutations, actual profile-method transport, and valid pre-engine failure denominators passed their bounded checks. Remaining defects concern encoded reference parameters and history order, identity rewriting in the neighboring live launcher, an inspector that trusts its duplicated summary instead of the retained result, returned-fit failures conflicting with artifact checks, and a pilot cache that can reuse stale referenced artifacts. Full report: `.unlazy/arc1-gaussian-reliability/evidence/scientific-checkers-astra-review-v2/review.md`.

Luna owns repairs across the full S3 path, including `run_cell.py`. The next freeze must include those transitive launcher and inspector files. No study or admission was created.
