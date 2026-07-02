# After-task — Phase 5 sparse benchmark + direct–maternal 2nd comparator + intervals (2026-07-02)

**Session:** Claude solo (Fable), resumed after the R twin froze. Executed a pre-planned
12-hour agenda (ultra-plan) with a user checkpoint before compute.
**Repos:** `HSquared.jl` only (Julia engine). R twin (`hsquared`) untouched — frozen.
**Branch:** `feat/2026-07-02-phase5-sparse-benchmark` (PREDECL `662663ed` pushed; rest per the
commit ledger below).

## Headline

Closed the one remaining compute-gated owed item — the **Phase 5 sparse-vs-dense AI-REML
performance benchmark** — plus two additive hardening slices on the covered direct–maternal
model, all under full pre-declaration / Rose discipline. **No covered flip; honesty pins held**
(`validation_status()` rows **53** / covered **13** / `public_covered_count` **5** UNCHANGED).

## What landed

1. **Phase 5 benchmark (V3-NEFFECT-SPARSE stays `partial`, evidence banked).** Pre-declared
   protocol (`662663ed`, committed BEFORE the run; harness byte-identical), run on `totoro`
   (1-core). **GO** decision. Results:
   - Sparse ≤ dense at ALL overlap sizes (**122×→692×** min-time, q=200→1000; monotone,
     sign-stable; dense `converged=true`; same-optimum ≤3.3e-5).
   - K=1 sparse near-linear (log-log slope **1.01**, feasible to q=50000); K=3 ~quadratic
     (slope **2.25**; q≥20000 infeasible in-budget).
   - **Finding:** the K=1-vs-K=3 contrast pinpoints the multi-effect environmental-group columns'
     Cholesky fill-in as the K≥2 scale bottleneck → a fill-reducing ordering (METIS) is the next
     enabler.
   - Confound disclosed (sparse ~8–11 AI-Newton iters vs dense ~250–276 NelderMead f_calls).
   - Machine-specific measurement; no isolated-LA / GPU / production / accuracy / portable claim.

2. **Direct–maternal BLUPF90 2nd comparator (V4-DIRECT-MATERNAL stays `covered`).** `blupf90+`
   2.60 AIREMLF90 2×2-G (`OPTIONAL mat`) converged from a neutral start to the engine optimum
   ~3e-5 on all four components (dam-identification verified; ABSOLUTE-variance, column-identified;
   verified against the raw `blupf90.log`). The owed 2nd same-estimand comparator is discharged
   (point-estimate, single fixture).

3. **Direct–maternal asymptotic intervals (additive engine code).** New exported
   `direct_maternal_interval` — observed-information FD-Hessian → delta-method SEs/CIs for the VCs,
   r_am (Fisher-z), and the Willham triple; labelled asymptotic/uncalibrated; throws on non-PD
   information. 32/32 tests. Corroborated by BLUPF90's AI-based SEs (~10%). No R-surface change.

4. **Hygiene:** Falconer→Willham fence fix (`likelihood.jl:1661`); doc-33→doc-16 canonicalization
   (4 files); `.gitignore` additions.

## Process notes

- **Pre-freeze review of the benchmark** by Karpinski (timing) + Gauss (same-optimum) →
  SOUND-WITH-FIXES (loglik + all-K σ recorded; GC suppressed in the timed region; dense-converged
  visibility) — all applied. **Pre-freeze review of the pre-declaration** by Fisher (decision rule)
  + Rose (freeze baseline — caught the byte-identity baseline had to pin to the PREDECL commit,
  not the prior HEAD) — all applied.
- **Declared-grid deviation handled transparently:** the initial declared-grid run revealed K=3
  q≥20000 infeasible (super-quadratic fill-in); K=3 capped at the feasible range, K=1 ran the full
  grid; the RUN not completing the top cells (harness unchanged) is the honest feasibility result,
  not a claim relaxation. Declared-attempt log preserved.
- **Subagent claim verified, not trusted:** the BLUPF90 subagent reported "committed" but had made
  no commits (verified via git log); its numbers were independently confirmed against the raw
  `blupf90.log`.

## Evidence

- `docs/dev-log/recovery-checkpoints/2026-07-02-phase5-sparse-benchmark{,-predeclaration}.md`
- `docs/dev-log/recovery-checkpoints/2026-07-02-direct-maternal-blupf90-comparator.md`
- `sim/phase5_sparse_benchmark_{K3,K1}.tsv`
- `docs/dev-log/check-log.d/2026-07-02-phase5-benchmark-dm-comparator-intervals.md`

## Checks

- `Pkg.test()` — GREEN (interval testset 32/32; count guard pins 53; no failures).
- `docs/make.jl` — GREEN (exit 0, zero dead links; added the direct-maternal family to
  `api.md` to resolve the new docstring's `@ref` — also closed a pre-existing manual gap).
- Real `rose-systems-auditor` (Fable) audit over all three deliverables → **PROMOTE-WITH-CHANGES**
  (benchmark PROMOTE, BLUPF90 PROMOTE, intervals PROMOTE-WITH-CHANGES). Rose independently
  reproduced every load-bearing number; 3 doc-hygiene fixes applied (SE cross-check softened
  "~10%"→"~4–12% (max 11.5%)" + banked, check-log completed, `/docs/package.json` gitignored).
- Honesty pins: rows 53 / covered 13 / `public_covered_count` 5 UNCHANGED (verified live at all
  pin sites; `tools/` + `control-centre/` untouched). Nothing promoted.

## Commit ledger (branch `feat/2026-07-02-phase5-sparse-benchmark`)

- `662663ed` — pre-declaration + rewritten harness + additive `fit_multi_effect_reml`
  (`iterations`/`f_calls`) edit, committed **BEFORE** the run (the freeze baseline).
- close-out commit — benchmark results (TSVs + checkpoint) + BLUPF90 comparator + DM intervals
  + hygiene + evidence-only status edits + check-log + this report + AGENTS.md snapshot.
- PR pending; maintainer owns merge (engine-only; R twin frozen).

## Next

- Owed on V3-NEFFECT-SPARSE: a fill-reducing ordering (METIS) for near-linear K≥2 scaling (the
  benchmark's concrete finding), a pre-declared recovery gate for the sparse code path, a
  same-estimand comparator through the sparse path at scale, the R multi-term `(1|g)` bridge.
- Owed on V4-DIRECT-MATERNAL: calibrated (coverage-validated) intervals, broader-DGP recovery,
  the maternal-A2 generalization.
- R twin remains frozen — no cross-lane action taken; the covered-status surfaces are already
  reconciled (coordination board).
