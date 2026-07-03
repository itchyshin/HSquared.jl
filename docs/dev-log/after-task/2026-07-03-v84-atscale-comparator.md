# After-task — v0.8-V8.4 at-scale external comparator (2026-07-03)

**Owner:** Claude solo (Opus), autonomous (goal: finish doc-25). **Branch:**
`feat/2026-07-03-v84-atscale` off `main` @ `2e01ace2`. **Counts:** rows **55**, covered **13**,
`public_covered_count` **5** — NO covered flip.

## Headline

Discharged V8.4's owed AT-SCALE comparator leg to the external tool's intrinsic ceiling: re-ran the
blupf90 same-estimand comparison at a **~5× larger q (q=4060)**. The exact sparse engine agrees with
blupf90 to 4.7e-6, and the matrix-free fit reaches the external optimum to ≤1%. Beyond blupf90's
ceiling, the exact-infeasible regime has **no external oracle by construction** — documented.

## What landed

- **`comparator/matfree_blupf90_atscale.jl`** (NEW, committed) — reconstructs the K=3 fixture at
  noffspring=4000 (q=4060), runs blupf90 (external) + `fit_sparse_multi_effect_aireml` (exact sparse)
  + `fit_multi_effect_mc_reml` (matrix-free, 6 seeds × 2 probe budgets), reports the 3-way comparison.
- **`docs/dev-log/recovery-checkpoints/2026-07-03-v84-atscale-comparator.md`** — banks the numbers +
  the intrinsic-ceiling reasoning.
- **Status sweep:** `V3-NEFFECT-MATFREE-FIT` (at-scale owed → delivered; only coverage-calibrated
  intervals remain owed), doc-25 V8.4 → DONE. `.gitignore`s the packet dir.

## Evidence (q=4060, local, blupf90+ 2.60)

- **Exact sparse == blupf90:** max abs diff **4.7e-6** — the exact engine's multi-effect estimand is
  externally validated at 5× the estimand-leg scale.
- **Matrix-free ≈ blupf90/exact:** ≤1% (nprobe 128 → 0.95%, 256 → 0.71%); σa² the noisiest
  component, tightening with `nprobe` (MC noise ∝1/√nprobe is larger at this q for a fixed budget —
  honest, controllable).

## Honesty pins

- The "at-scale" leg is intrinsically capped: no `q` is simultaneously (exact infeasible) AND
  (blupf90 feasible), since blupf90 forms the MME too. This leg runs at a q ~5× the estimand leg
  (q=4060, well within blupf90's reach); the exact-infeasible regime is validated by the internal
  exact-agreement + the 48-seed recovery gate, NOT an external oracle.
- `V3-NEFFECT-MATFREE-FIT` stays `partial`; NO covered flip; `public_covered_count` UNCHANGED. Only
  coverage-calibrated intervals remain owed. `Pkg.test()` GREEN (55).

## Next (finish doc-25)

Coverage-calibrated intervals — the last owed leg — is running on DRAC fir (job 46853279).
