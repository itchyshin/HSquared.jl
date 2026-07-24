# 2026-07-24 — `fit_eigen_reml` experimental→covered evidence package (staged; G11 discharged)

Branch `codex/2026-07-13-v07-performance-localization`. Fences held throughout: `public_covered_count`
stays **5**, **no capability-status row flipped**, D1 (D-68) / TMB / R-twin / 4 foreign dirty files untouched.

- **Local smoke** (julia 1.10.0, n=250, 2 seeds/arm): eigen + AI-REML converge, eigen≡AI-REML 1e-7–1e-9.
  GREEN. Gated the API before any commit/Totoro run. (Recorded in the predeclaration doc.)
- **Recovery gate — PASS.** `env OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase_eigen_reml_recovery_gate.jl`
  on Totoro (julia 1.12.6), at the FROZEN predeclaration commit `1d9ec57d`: `GATE: PASS (WS=true HF=true)`,
  exit 0. Both arms 48/48 converged (eigen + AI-REML); all `|bias| ≤ 2·MCSE` (max 1.01·MCSE, WS σ²a);
  eigen ≡ AI-REML ≤ 2.62e-7 (all-96 max; the two arms are a fill gradient WS≈17→HF≈49 at n=1000, both below
  the `:auto` threshold 60 — the gate validates eigen by DIRECT fits, not inside `:auto`'s eigen regime). Evidence:
  `docs/dev-log/recovery-checkpoints/2026-07-24-eigen-reml-recovery-gate-{predeclaration,result}.md`.
- **Same-estimand REML comparator — AGREE.** `julia comparator/prepare_sommer_eigen.jl` then
  `Rscript comparator/run_sommer_eigen.R` (R 4.6.0, sommer 4.4.5): `COMPARATOR: AGREE (max rel.diff 7.77e-09)`,
  exit 0 — engine `(σ²a,σ²e)=(1.266229,1.442756)` ≡ sommer to 7.77e-9 on gate seed 20267000. Evidence:
  `docs/dev-log/recovery-checkpoints/2026-07-24-eigen-reml-comparator.md`. (This is the G11 comparator leg;
  with the gate above, G11 is discharged. G8/G10/R-bridge still owed.)
- **`:auto` crossover benchmark.** `julia sim/bench_eigen_crossover.jl` on Totoro (BLAS=8): full n×window
  grid; crossover brackets n=2000 ∈ (50.8,75.6), n=4000 ∈ (57,108.7); the proxy is n-dependent. Decision:
  KEEP `_AUTO_EIGEN_FILL_THRESHOLD=60` (validated, conservative; n-adaptive deferred). Evidence:
  `docs/dev-log/native-engine-arc/2026-07-24-eigen-auto-threshold-crossover.md`.
- **`Pkg.test()`** (local, julia 1.10.0): **PASSED** — "Testing HSquared tests passed", 0 failures/errors,
  incl. the eigen-matches-AI-REML + `:auto`-routing testsets. Only a test COMMENT changed (no assertion/src).
- **Rose G8 audit: CLEAR-WITH-CHANGES** (`docs/dev-log/scout/2026-07-24-rose-eigen-evidence-audit.md`) —
  evidence genuine + independently reproduced (Rose reran the gate seeds + the comparator engine target),
  all fences hold; 3 wording corrections applied (HF arm at n=1000 is `nnz(L)/n≈49` < threshold 60 → `:auto`
  routes both arms to sparse; the all-96 eigen≡AI-REML bound is 2.62e-7 not 2.18e-7).
- **`docs/make.jl` (Documenter):** NOT re-run — no `docs/src/` or Documenter-source file changed this session
  (edits are under `docs/design/` + `docs/dev-log/`, outside the Documenter build tree; `src/` untouched), so
  the rendered site is unaffected; the Documenter CI job on the pushed commits covers it.
- **Melissa plan-vs-actual reconcile:** `docs/dev-log/plan-actual/2026-07-24-eigen-promotion-evidence.md`
  (2 drift, 2 unclear, 1 adaptive) — all five addressed in this consolidation (Rose verdict finalized;
  `docs/make.jl` reasoned above; G3 accounted below; orchestrator-inline routing rationale recorded in the
  after-task; S4-keep-60 is the recorded adaptive).
- **Git hygiene:** each commit staged EXPLICITLY (never `-A`); the 4 foreign dirty files remained unstaged in
  every commit; feature-branch only, never `main`.

> Related: `docs/dev-log/after-task/2026-07-24-eigen-promotion-evidence-package.md` ·
> `docs/design/16-promotion-gate-predicates.md` (G1–G11).
