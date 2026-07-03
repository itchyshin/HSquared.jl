# Check-log — v0.8-V8.4 at-scale external comparator (2026-07-03)

**Slice:** the AT-SCALE leg of the matrix-free external comparator (V8.4). Branch
`feat/2026-07-03-v84-atscale`. New: `comparator/matfree_blupf90_atscale.jl`.

## Key result (q=4060, local, blupf90+ 2.60)

- **Exact sparse (`fit_sparse_multi_effect_aireml`) == blupf90:** max abs diff **4.7e-6** — the exact
  multi-effect estimand externally validated at 5× the estimand-leg scale (q=860 → 4060).
- **Matrix-free (`fit_multi_effect_mc_reml`) ≈ blupf90/exact:** ≤1% (nprobe 128 → 0.95%, 256 →
  0.71%); σa² the noisiest, tightens with nprobe (MC-controllable).

## The intrinsic ceiling (documented)

No `q` is simultaneously (exact infeasible) AND (blupf90 feasible) — blupf90 forms the MME too. So
the exact-infeasible regime (q≫50k) has NO external oracle BY CONSTRUCTION; it is validated by the
internal exact-agreement (matrix-free==exact-sparse) + the 48-seed recovery gate. This leg does the
most physically possible.

## Evidence

- Script `comparator/matfree_blupf90_atscale.jl`; checkpoint
  `2026-07-03-v84-atscale-comparator.md`. Binaries/packet git-ignored.
- No `src/` change (comparator + evidence + status strings). `Pkg.test()` GREEN (count 55 UNCHANGED);
  `V3-NEFFECT-MATFREE-FIT` stays `partial`.

## Honesty

NO covered flip; `public_covered_count` UNCHANGED. Only coverage-calibrated intervals remain owed.
