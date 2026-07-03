# Check-log — v0.8-V8.5 APY sparse-structured genomic inverse (2026-07-03)

**Slice:** the large-genotyped-population scale path for the genomic inverse `Ginv`. New:
`apy_genomic_relationship_inverse(G, core; ridge)` (exported). New validation-status row `V2-APY`
(`partial`). Branch `feat/2026-07-03-v85-apy`.

## What it is

The Algorithm for Proven & Young (APY; Misztal et al. 2014). Partition animals into a `core` set `c`
and non-core `n`. APY factorizes only the `core × core` block `Gcc` and adds a DIAGONAL
conditional-variance ("Mendelian") correction for the non-core animals:

- `Mnn = Diagonal(gᵢᵢ − G[i,c]·Gcc⁻¹·G[c,i])`  (each non-core animal's conditional variance);
- `Ginv = [[Gcc⁻¹ + Gcc⁻¹Gcn·Mnn⁻¹·GncGcc⁻¹, −Gcc⁻¹Gcn·Mnn⁻¹]; [−Mnn⁻¹·GncGcc⁻¹, Mnn⁻¹]]`.

Cost `O(ncore³ + nnoncore·ncore²)` instead of the dense `O(n³)` inverse — the standard way large
genotyped populations avoid an intractable dense `G`-inverse.

## Key result

- **EXACT-REDUCTION gate:** `core = 1:n` (all animals) reproduces the full regularized
  `genomic_relationship_inverse(G; ridge)` to **~1e-15** (`max|APY − full inv| = 3.8e-15` at n=120,
  ridge=0.01) — a machine-precision identity, not a tolerance. This is the load-bearing correctness
  test: APY with the full population IS the regularized dense inverse.
- **APPROXIMATION:** fed through `fit_gblup`, the APY GEBVs converge to the full-inverse GEBVs as the
  core grows. Near-full core (n−3) → GEBV correlation **0.9996**; small core (n/3) → **0.986**;
  monotone in core size (`cor(near) > cor(small)`). With a full-rank `G` (m > n) the sub-full-core
  case is a genuine low-rank approximation, so a near-full core is the robust demonstration of
  convergence.
- Guards: non-positive conditional variance (increase core / ridge), empty/out-of-range core, and
  negative ridge all throw `ArgumentError`.

## Evidence

- Prototype `scratchpad/apy_proto.jl`: core=all diff 0.0; ncore 40/80/120 → GEBV corr
  0.986/0.996/1.0.
- Test (`test/runtests.jl` "APY genomic inverse ..."): exact-reduction (core=all == full inv, <1e-8;
  core=all GEBV == full GEBV, <1e-6), monotone approximation (near>small, near>0.99), 3 guards.
- `Pkg.test()` GREEN; `docs/make.jl` GREEN (1 new api.md entry).
- `validation_status()` count **54 → 55** (`V2-APY` partial added; covered 13 UNCHANGED,
  `public_covered_count` 5 UNCHANGED). Cache refreshed (`tools/status_cache.json`).

## Honesty

Validation-scale, supplied-`G`, **caller-supplied `core`** (no core-selection algorithm), **dense
return** (the APY STRUCTURE — no genuinely sparse/on-device `Ginv` yet). The exact-reduction identity
is machine-precision; the sub-full-core case is an APPROXIMATION that is *demonstrated* but not
gate-calibrated. No covered flip; `V2-APY` is `partial`. Owed (does NOT retire): a core-selection
algorithm, a sparse/on-device representation, a large-`n` scale/timing benchmark, an
accuracy-vs-core recovery gate, and an external APY comparator (BLUPF90 `OPTION apy`/`sommer`). Not
the public default.
