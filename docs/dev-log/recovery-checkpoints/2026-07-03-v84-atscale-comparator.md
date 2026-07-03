# V8.4 AT-SCALE — external same-estimand comparator for the matrix-free fit at larger q (2026-07-03)

The AT-SCALE leg V8.4's estimand leg left owed. The validation-scale estimand leg
(`comparator/matfree_blupf90_neffect.jl`, q=860) validated the matrix-free fit against blupf90 at
small scale. This leg runs the SAME 3 estimators at a **~5× larger q (q=4060)** — the largest scale
where the external tool still runs.

## The honest ceiling (why "at-scale" is intrinsically capped)

The matrix-free fit's raison d'être is `q` where the EXACT/direct path is INFEASIBLE (K≥2
Cholesky-fill-limited past ~50k). But **blupf90 — and any external REML tool — forms the MME too**,
so it ALSO cannot run there. There is therefore **no `q` where (exact infeasible) AND (external tool
feasible)** — the exact-infeasible regime has **no external oracle by construction**. This leg does
the most that is physically possible: a 3-way comparison at the largest `q` blupf90 handles.

## Run (`comparator/matfree_blupf90_atscale.jl 4000`, q=4060, K=3, local)

- **Executables:** `renumf90` 1.166 + `blupf90+` 2.60 (`comparator/bin/`), Mac arm64. Fixture = the
  same DGP as the estimand leg (seed 20260800) but noffspring 800→4000 → q=4060.

**Exact-sparse engine vs blupf90 (the estimand at scale):**

| Component | `fit_sparse_multi_effect_aireml` | blupf90+ 2.60 | abs diff |
|---|---|---|---|
| σa² | 1.02780 | 1.02780 | — |
| σg1² | 0.52025 | 0.52025 | — |
| σg2² | 0.50406 | 0.50406 | — |
| σe² | 0.99109 | 0.99109 | — |

max abs diff **4.73e-6** (blupf90 5-sig-fig floor) — the EXACT sparse engine's estimand is externally
validated at q=4060.

**Matrix-free `fit_multi_effect_mc_reml` vs blupf90/exact (6 seeds, shared_probes):**

| nprobe | max rel \|matfree mean − blupf90\| | worst component |
|---|---|---|
| 128 | **0.0095** (0.95%) | σa² (0.98%, SD 0.014) |
| 256 | **0.0071** (0.71%) | σa² (0.71%, SD 0.015) |

The matrix-free across-seed mean reaches blupf90's/exact's optimum to **≤1%** at q=4060. σa² is the
noisiest component and tightens with `nprobe` (0.95%→0.71% as 128→256) — the MC noise (∝1/√nprobe) is
larger at this q for a fixed probe budget than at q=860 (≤0.15%), an honest and controllable trade
(more probes/seeds → tighter).

## What this discharges (honest)

- The exact sparse engine's multi-effect estimand is externally validated (blupf90) at **q=4060**, 5×
  the estimand leg — not just at validation scale.
- The matrix-free fit reaches the external optimum to **≤1%** (MC-controllable) at q=4060.
- Combined with the estimand leg (≤0.15% at q=860), the internal exact-agreement
  (matrix-free==exact-sparse), and the pre-declared 48-seed recovery gate, the matrix-free path is
  externally corroborated across scales up to blupf90's ceiling.
- **The exact-infeasible regime (q≫50k) has no external oracle by construction** — this is the
  intrinsic limit of any external-comparator leg, documented, not a gap that more work closes.
- `V3-NEFFECT-MATFREE-FIT` stays `partial`; NO covered flip; `public_covered_count` UNCHANGED.
  Binaries/packet git-ignored; committed = the script + this checkpoint.
