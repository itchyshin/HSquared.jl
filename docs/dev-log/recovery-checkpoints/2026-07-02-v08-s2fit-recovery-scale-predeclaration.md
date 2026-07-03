# Pre-declaration — v0.8-S2-FIT matrix-free MC-EM-REML recovery gate + scale feasibility

**Date:** 2026-07-02 · **Lane:** Julia engine (`HSquared.jl`) · **Author:** Claude (solo,
autonomous session). **Predecessor:** Slices A (`mc_reml_block_traces`) + B
(`fit_multi_effect_mc_reml`), committed on `feat/2026-07-02-matrix-free-fit` — the matrix-free
Monte-Carlo EM-REML FIT that lifts v0.8-S2 from a SOLVE to a FIT. This gate supplies the
correctness-at-scale evidence the FIT owes.

## 0. What this is (and is NOT)

`fit_multi_effect_mc_reml` fits the K-independent-effect Gaussian model with NO factorization:
each EM step is a matrix-free PCG solve + the Hutchinson trace. Slices A/B are unit-gated
(estimator unbiased vs the exact selected inverse; the fit recovers the exact
`fit_sparse_multi_effect_aireml` optimum to ~0.7% at small q). What is **owed** — and what this
supplies — is (1) a **pre-declared multi-seed recovery gate** through the MC fit and (2) a
**FIT scale-feasibility** measurement. **Measurement, not promotion.** No covered flip;
`validation_status()` rows **53** / covered **13** / `public_covered_count` **5** UNCHANGED.

## 1. Frozen harness

`sim/v08_s2fit_recovery_scale.jl`, opt-in (`HSQUARED_RUN_S2FIT=recovery|scale`), OUT of CI,
frozen byte-identical by the pre-declaration commit `PREDECL` (proven post-run:
`git show PREDECL:sim/v08_s2fit_recovery_scale.jl` == the harness that ran). Deterministic.

## 2. Recovery gate — design (frozen)

- **DGP:** K=3 KNOWN-truth — effect 1 additive (half-sib pedigree, gene-dropped, σ²a); effects
  2,3 environmental factors assigned INDEPENDENTLY of the pedigree (σ²_e1, σ²_e2); residual σ²e.
  Truth `(σ²a, σ²_e1, σ²_e2, σ²e) = (1.0, 0.5, 0.5, 1.0)`. `q = 960`, `n = q`.
- **48 seeds** (`base_seed = 20260800`, seeds `+1..+48`). Per seed: fit BOTH the matrix-free
  `fit_multi_effect_mc_reml` (`nprobe = 200`, probe seed `base+100000+s`) AND the EXACT
  `fit_sparse_multi_effect_aireml` on the same data (the reference).

- **PRIMARY criterion (the claim this gate licenses):** ALL 48 seeds converge **AND**
  `max over seeds of |MC − EXACT| / EXACT ≤ 0.05` — i.e. the matrix-free MC fit **REPRODUCES**
  the exact AI-REML fit (the *covered* `V3-NEFFECT-REML` estimator) on identical data. This
  tests exactly what the matrix-free approximation adds: does the stochastic trace distort the
  estimate? It does not re-litigate the estimator's own small-sample recovery (that is the
  covered `V3-NEFFECT-REML` gate #230).
- **SECONDARY (reported, NOT the gate):** per-component `|mean bias vs truth| ≤ 2·MCSE`. This is
  a JOINT estimator+DGP property that the EXACT fit **shares** (the harness records `ex_mean`
  alongside `mc_mean` to show it). It is reported for completeness; a secondary miss driven by
  small-sample scatter that the exact fit shares is NOT a matrix-free-fit failure.

  *Rationale for the paired primary criterion:* the exact estimator's unbiasedness is already
  covered; the NEW thing here is the MC approximation, so the gate targets MC-vs-exact fidelity
  directly. Local 6-seed pre-run check (q=960, nprobe=200): PASS — `max|MC−EXACT|/EXACT = 2.6%`,
  all converged, secondary ratios ≤ 1.9 with exact sharing the means. (This is a wiring check,
  NOT the pre-declared result.)

## 3. Scale feasibility — design (frozen)

`HSQUARED_RUN_S2FIT=scale`: fit `q ∈ {10000, 50000, 100000, 200000}` (`nprobe = 48`, 1 seed
each; K=3 same DGP). Record per q: `converged`, EM iterations, wall-clock, σ estimates.
**Claim licensed:** the matrix-free FIT remains feasible (converges, bounded wall-clock) at
`q` well beyond the direct AI-REML's K≥2 fill wall — extending the S2 SOLVE feasibility (shown
to q=10⁶) to the FIT. Machine-specific; single-core; NO cross-machine comparison; the FIT's
per-iteration cost is `1 + nprobe·K` matrix-free solves, so absolute times are reported as
measured, not extrapolated to q=10⁶ (a q=10⁶ FIT is feasible-but-hours by the S2 solve cost —
NOT claimed as run unless a cell completes).

## 4. Pre-declared claims + decision rule

- **R1 (recovery — the headline):** licensed iff the PRIMARY criterion (§2) holds → "the
  matrix-free MC-EM-REML fit reproduces the exact AI-REML variance components (the covered
  `V3-NEFFECT-REML` estimator) across 48 seeds to ≤5%, all converged." Report the max
  MC-vs-exact reldiff + the secondary table.
- **R2 (scale — descriptive):** report the FIT wall-clock + EM iterations + convergence per q;
  state the largest q that completes feasibly. Machine-specific.

**Forbidden regardless of results:** any covered flip; any claim the MC fit is MORE accurate
than exact (it is not — it approximates it); any cross-machine time comparison; any q=10⁶ FIT
claim unless a cell actually completes; any calibrated-interval claim (intervals not addressed
here). Every number tagged machine-specific.

## 5. Bank-a-negative clause

If the PRIMARY criterion misses (MC does not reproduce exact within 5%, or convergence
failures), it is a **BANKED NEGATIVE**: the checkpoint records the table + the honest read, the
fit stays experimental with "recovery gate run; MC-vs-exact fidelity <X> at nprobe=200" wording,
and the remedy (more probes / variance reduction) is noted. No result discarded or re-run for a
better number; the harness is not modified post-hoc (byte-identity §1). A scale cell that
OOMs/aborts is recorded as a banked feasibility limit for that q, NOT retried.

## 6. GO / NO-GO

- **GO** to run once: (a) this pre-declaration + the frozen harness are committed as `PREDECL`
  (Slices A/B source already committed + tested); (b) `Pkg.test()` green (count 53) — confirmed;
  (c) DRAC fir checked out to `PREDECL` + instantiated.
- After the run: prove harness byte-identity; write the post-run checkpoint with the manifest,
  the recovery table (MC vs exact + secondary bias/MCSE), the scale table, and the decision per
  §4/§5; then a real Rose audit before any status edit.
