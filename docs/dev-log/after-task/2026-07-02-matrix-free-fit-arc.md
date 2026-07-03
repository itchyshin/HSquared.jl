# After-task — v0.8 matrix-free Monte-Carlo REML FIT arc (2026-07-02)

**Session:** Claude solo (Opus), autonomous (7–8 h authorization). Continuation of the v0.7/v0.8
first wave (PR #248), building the matrix-free *fit* — the production large-`q` fitting engine that
lifts v0.8-S2 from a SOLVE to a FIT.
**Repos:** `HSquared.jl` only (Julia engine). R twin frozen — untouched.
**Branch:** `feat/2026-07-02-matrix-free-fit` (Slices A/B/C + usability; PREDECL `66ac9521` for the
Slice C compute committed BEFORE the run).

## Headline

Built and validated the **matrix-free Monte-Carlo EM-REML fit** end to end: it fits the
K-independent-effect model with NO factorization (matrix-free solves + a Hutchinson stochastic
trace), and **recovers the exact AI-REML variance components within Monte-Carlo error**. The one
science risk — is the MC gradient noise benign? — is resolved: benign, controllable by probe count.
**No covered flip; honesty pins held** (`validation_status()` rows **53** / covered **13** /
`public_covered_count` **5** UNCHANGED).

## What landed (all committed, tests + docs green)

1. **Slice A — `mc_reml_block_traces`** (Hutchinson stochastic trace). The AI-REML score needs
   `tr(Aᵢ⁻¹C⁻¹[uᵢ,uᵢ])`; the exact path reads it from a Cholesky selected inverse (a factor the
   matrix-free world avoids). This estimates it matrix-free via Rademacher probes + matrix-free
   solves. **Unbiased** — validated to sit within its MC error band of the exact
   `selinv_block_traces`, converging ~1/√nprobe. Commit `03bb64d9`.
2. **Slice B — `fit_multi_effect_mc_reml`** (matrix-free Monte-Carlo EM-REML fit). Each EM step =
   a matrix-free PCG solve + the Hutchinson trace; same closed-form EM update as
   `fit_sparse_multi_effect_aireml`'s warmup, traces MC-estimated; fixed probe seed across
   iterations (correlated sampling) → deterministic convergent map. **Recovers the exact optimum
   to ~0.7%** at nprobe=300 (q=300, K=2), tighter with more probes. No `loglik` (stochastic
   log-det owed). Commit `19f6dcc3`.
3. **Slice C — pre-declared recovery + scale gate** (DRAC fir, PREDECL `66ac9521`, job 46725575).
   **Both legs PASS.** Recovery (48 seeds, K=3, q=960): all converged, MC reproduces the exact
   AI-REML fit to **2.6%** (≤5% primary criterion); secondary `|bias|≤2·MCSE` for all four
   components (max 1.20), exact fit sharing the means. Scale: the FIT **converges at every size to
   q=200,000** (11.5s→586s, q=10k→200k) — where the direct multi-effect AI-REML is fill-limited past
   ~50k. Extends the S2 SOLVE feasibility (q=10⁶) to the FIT. Result checkpoint
   `docs/dev-log/recovery-checkpoints/2026-07-02-v08-s2fit-recovery-scale-result.md`.
4. **Usability — `fit_multi_effect(...; method=:auto)`** + the "Fitting at scale" doc page. Routes
   exact-vs-matrix-free by feasibility (K==1 || N≤direct_max_n → exact; else matrix-free, with a
   switch `@info` + MCSE), overridable; the doc page explains the accuracy-vs-feasibility trade.
   Commit `56c6e13f`.

## Process notes

- **De-risked before investing:** a 6-seed local recovery smoke (q=960) showed the MC fit tracks
  the EXACT fit per-dataset (max reldiff 2.6%), so the recovery gate's PRIMARY criterion was
  designed as PAIRED (MC reproduces the covered exact estimator) rather than re-litigating the
  estimator's own small-sample bias (already the covered `V3-NEFFECT-REML` gate). The gate records
  both MC and exact per seed to show the exact fit shares any residual small-sample scatter.
- **Symbolic-fill predictor investigated + rejected:** CHOLMOD's symbolic `analyze` does not
  cleanly expose the predicted `nnz(L)` in Julia and is only ~3× cheaper than the full
  factorization — so the `:auto` dispatch uses an honest calibrated size heuristic (documented as
  such, always overridable), not a precise fill prediction.
- **Cross-project issues filed:** the matrix-free + Hutchinson-trace methodology was flagged to the
  sister teams for their large-dataset feasibility — gllvmTMB #705, drmTMB #714, GLLVM.jl #167,
  DRM.jl #327 (shared methodology, not shared code; the Julia twins noted as directly reusable).

## Evidence

- Pre-declaration: `docs/dev-log/recovery-checkpoints/2026-07-02-v08-s2fit-recovery-scale-predeclaration.md`.
- Result: `docs/dev-log/recovery-checkpoints/2026-07-02-v08-s2fit-recovery-scale-result.md`.
- Raw: `sim/drac/results/s2fit_recovery_46725575.tsv`, `s2fit_scale_46725575.tsv`.
- Ultra-plan for completing the arc: `docs/design/25-completion-ultraplan.md`.

## Checks

- `Pkg.test()` GREEN (count guard 53; new testsets: MC trace unbiasedness, MC-EM recovery,
  `:auto` dispatch). `docs/make.jl` GREEN (new "Fitting at scale" page + api.md refs).
- Honesty pins: rows 53 / covered 13 / `public_covered_count` 5 UNCHANGED. Nothing promoted; the
  matrix-free fit is experimental (exact path preferred at validation scale; covered flip owes
  the loglik + intervals + external comparator).
- Real `rose-systems-auditor` (Opus) over the whole arc → **PROMOTE-WITH-CHANGES**: independently
  reproduced every load-bearing number (rows 54 / covered 13 / partial 37 / `public_covered_count`
  5; recovery 2.6%/secondary bias-MCSE; scale q=200k timings from the raw TSVs), confirmed
  pre-declaration-before-run (PREDECL committed 5 min before the run start), harness byte-identity,
  Pkg.test GREEN, and no covered flip. 3 fixes applied: (1) a doc-page overclaim (attributed the
  SOLVE's q=10⁶ reach to the FIT — corrected to the FIT's q=200k), (2) a stale V1-PCG owed-clause
  (the matrix-free FIT it listed as owed is now delivered), (3) a cosmetic scale-table `n` column
  (n = q).

## Next

See `docs/design/25-completion-ultraplan.md`. Highest-leverage next: **V8.1 + V8.2** — the
matrix-free REML loglik (stochastic log-det) + trace variance reduction (the K×-cheaper
shared-probe estimator), which complete the fit into a *full* REML fit and cut its cost at scale.
Then the v0.7 GPU fan-out (G-B Float32 + cross-device agreement replicates).
