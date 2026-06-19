# 2026-06-19 multivariate covariance SEs + LRTs (BT3 #47)

- Goal: close the V4-MV-REML/V4-FA "needs covariance SEs / LRTs" gap with
  asymptotic SEs (observed information + delta method) and a boundary-aware
  nested-structure LRT.
- Lenses: Gauss, Noether, Fisher, Curie, Rose.

## Commands / evidence

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` → exit 0,
  **1822/1822** (59 testsets; +30 from the new "Phase 4 multivariate covariance
  SEs + LRTs" testset).
- Pre-fix probe found the n=8 single-record multivariate optimum is on the
  genetic-correlation boundary (`rg→±1`) for every trait pattern, so the
  observed information is non-PD there; switched the positive SE/LRT tests to an
  interior repeated-records fixture (n=24) and added a test asserting the
  honest non-PD throw at n=8.

## Claim boundary

Experimental, asymptotic, dense/validation-scale, not coverage-calibrated;
unstructured fit only; no external comparator. No capability moved to covered.
