# Pre-declaration — v0.8-S1 METIS-vs-AMD ordering benchmark (BANKED NEGATIVE)

**Date:** 2026-07-02 · **Lane:** Julia engine (`HSquared.jl`) · **Author:** Claude (solo).
**Predecessor:** the Phase 5 sparse benchmark identified the environmental-group-column
Cholesky fill-in as the K≥2 direct-factorization scale wall and named a fill-reducing ordering
(METIS) as the hypothesized enabler (doc-23, S1). This benchmark TESTS that hypothesis.

## 0. What this is

A **falsification test** of the S1 premise: does a METIS nested-dissection permutation beat
CHOLMOD's default AMD ordering for the multi-effect MME coefficient matrix `C` (the matrix of
`_sparse_multi_lhs_rhs`), on `nnz(L)` and factorization time, across q and K? The decision it
informs: **adopt METIS in the sparse multi-effect Cholesky ONLY if it robustly wins; otherwise
bank the negative and retain AMD, adding no dependency.**

**Metis is a BENCHMARK-ONLY dependency** — run in a throwaway env with HSquared + Metis. It is
DELIBERATELY NOT added to `HSquared.jl`'s `Project.toml`. Banking this negative IS the decision
not to take on that dependency for the default solve path. No covered flip; `validation_status()`
count **53 UNCHANGED**; `public_covered_count` **5**; row `V3-NEFFECT-SPARSE` `owed` note updated
to record the ordering finding.

## 1. Fixed experimental design (frozen)

- **Harness:** `sim/v08_s1_ordering_benchmark.jl`, opt-in (`HSQUARED_RUN_S1_ORDER=1`), OUT of CI,
  frozen byte-identical by `PREDECL`.
- **Data:** same DGP as the Phase 5 / S2 harnesses — half-sib pedigree animal effect + i.i.d.
  environmental groupings independent of the pedigree; `C` assembled via `_sparse_multi_lhs_rhs`
  at unit variances. Deterministic; `seed = 20260702`.
- **Grid (locked):** `q ∈ {2000, 5000, 10000, 20000, 50000}`, `K ∈ {1, 3}`, `trials = 3`.
- **Orderings:** **AMD** = CHOLMOD default `cholesky(C)`; **METIS** = `Metis.permutation(C)`
  nested dissection supplied via `cholesky(C; perm = …)`. Metrics: `nnz(L)` and best-of-`trials`
  factorization time for each.

## 2. Pre-declared claim + decision rule

- **ADOPT-METIS (positive)** would be licensed iff METIS reduces BOTH `nnz(L)` AND factorization
  time vs AMD **at every tested (q, K)** by a pre-declared margin of **≥ 1.2×** (a robust,
  monotone win — an ordering swap must not regress any tested case, since it would sit in the
  default solve path). Only then would adding a Metis dependency + a `ordering = :metis` path be
  considered.
- **BANK-NEGATIVE (the expected outcome)** if METIS does NOT win robustly — in particular if it
  is worse at any tested size (a common nested-dissection failure on matrices with dense-ish
  columns). Then: retain CHOLMOD AMD, add NO dependency, record the finding on
  `V3-NEFFECT-SPARSE`.

**Forbidden regardless of results:** any claim that AMD is optimal (it is only "not beaten
robustly by METIS on this structure"); any portable/absolute ordering claim; any cross-machine
absolute-time comparison. Machine-specific measurement.

## 3. Preliminary local signal (NOT the pre-declared result)

A local Mac measurement (2026-07-02, throwaway env) already shows the expected shape: METIS helps
at small/moderate q (fill x1.18–2.32, speed x1.3–1.8 at q≤10k K=3) but at **q=50k K=3 is 2.5×
MORE fill and 3.3× SLOWER** (fill x0.40, speed x0.31); K=1 is a wash (x1.01, AMD already
near-optimal, consistent with Phase 5's "K=1 already near-linear"). This is why S1 is expected to
bank a negative. The canonical run (a DRAC CPU node or Totoro) formalizes it on a recorded
manifest under the frozen protocol.

## 4. GO / NO-GO

- **GO** to run once: this pre-declaration + harness committed as `PREDECL`; a throwaway env with
  HSquared (dev'd at `PREDECL`) + Metis is instantiated on the run host.
- After the run: prove harness byte-identity; write the post-run checkpoint with the manifest +
  the AMD-vs-METIS table + the ADOPT/BANK decision per §2; then a real Rose audit before the
  `V3-NEFFECT-SPARSE` `owed`-note edit.
