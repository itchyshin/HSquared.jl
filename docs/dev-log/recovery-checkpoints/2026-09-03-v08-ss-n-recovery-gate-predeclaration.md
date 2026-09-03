# Pre-declaration — V2-SSHINV n≫6 single-step recovery gate (2026-09-03)

Status: **PRE-DECLARED, committed BEFORE any gate run.** Campaign **NOT RUN** at
freeze. Smoke / construct may prove the path; they are not the gate.
No post-hoc relaxation (2026-06-14 rule). **Not a covered flip.**
`V2-SSHINV` stays **partial**. `public_covered_count` stays **7**.
Experimental **0.7.0**. Never 1.0 / CRAN. FA is a sibling lane — do not flip it
here.

Lane: `cursor/08-ss-20260903` (WT `~/local-scratch/lanes/HSquared.jl-08-ss-20260903`).
PR: https://github.com/itchyshin/HSquared.jl/pull/295
Driver: `sim/v08_ss_s2_recovery.jl`
Freeze commit: **the git commit that introduced this file and the driver
together.** Record that SHA on the receipts; do not edit gate text after freeze.

```
PLATFORM: cursor | LANE: cursor/08-ss-20260903
OTHER LANES: FA sibling cursor/08-fa-20260903 #292 · G5 stale-copy #296 ·
             H1/H3 #294 · Codex DRAFT #137/#274 cite-only
Active lenses: Ada · Shannon · Curie/Fisher/Mrode (gate text) · Rose fence
Spawned subagents: none
Current lane: Julia 0.8 single-step WT, sim/ + this checkpoint only
```

## Why n=6 is not a gate

Packed AGHmatrix construction smoke (seed `20260903`) recovered
σ²a = 0.076 vs truth 1.0 (converged). Expected: 6 animals / 3 genotyped / 2 VCs
is unidentified. Dump only. Construction AGREE (`max|Hinv Δ| = 4.24e-12` vs
AGHmatrix::Hmatrix Martini, τ=ω=1) is G3, not G11.

## Estimator + DGP (frozen)

`fit_single_step_reml` on `y = μ + u + e` with **true** covariance `H`,
`G ≠ A₂₂`.

| knob | frozen value | why |
|---|---|---|
| pedigree | 40 sires / 80 dams / 120 offspring | deterministic half-sib; n = 240 |
| dense fence | n² = 57 600 ≤ 1e6 | validation-scale, not production |
| genotyped | last generation only (`o*`; 120/240 = 50%) | ordinary ssGBLUP missing-genotype pattern |
| `G` | `A₂₂ + 0.05 I` | **same estimand** as the AGHmatrix Hmatrix packet; **not** VanRaden (`V2-GRM` stays out) |
| knobs | τ = ω = 1, blend = ridge = 0 | G7 remains retained debt |
| truth | (σ²a, σ²e, μ) = (1.0, 1.5, 2.0) | same as n=6 dump |
| start | (σ²a, σ²e) = (0.5, 1.0) | cold; not at truth |
| draw | `u ~ N(0, H σ²a)` via `chol(H)` | supplied `H` is the exact model |

Breeding values are drawn from the **same** `H` the fitter rebuilds from
`(A, G, genotyped_rows)` at the frozen knobs, so σ²a is the exact estimand
(no model misspecification). This tests the REML **estimator** on a
constructed single-step precision, not marker→`G` realism.

**Rejected for this SHA:** VanRaden `G` on last-gen markers (mixes `V2-GRM`);
`G = A₂₂` (that is pedigree REML; already in-suite); n = 6; metafounder `H^Γ`;
non-default τ/ω/blend/ridge.

If n = 240 still collapses like n = 6, that is a **banked negative** on this
SHA. A larger n is a **new** predeclaration. Do not post-hoc relax PASS or n.

## Seeds (UNSEEN at declaration)

48 cold-start seeds **20265000 .. 20265047**.

Disjoint from genomic `20260800..47`, two-effect `20260700..`,
direct-maternal `20264000..`, n=6 smoke `20260903`, FA S2 `20260914..23`,
and the path-only seeds below.

Path-only (never a gate verdict):

- construct: no seed
- smoke: `20264999`
- feasibility: `20264990 .. 20264992`

## PASS criteria (ALL required; fixed here)

On the **full** 48-seed block, `--mode=gate` with seeds exactly
`20265000:20265047`:

1. **Convergence:** 48/48 seeds converge.
2. **No detectable bias:** `|bias| ≤ 2·MCSE` for **σ²a and σ²e**, where
   `bias = mean(θ̂) − truth` and `MCSE = sd(θ̂)/√48`.

**h²** = σ²a / (σ²a+σ²e) is **reported, not gated.** Derived-estimand identity
+ locked citation is design-41 §3.3 (blocker 3, cheap); do not flip h² on
this gate alone.

A shard of the locked block may be written to TSV for Totoro fan-out; the
verdict is only the full-block aggregate.

## Interpretation (declared in advance)

- **PASS** = no detectable across-seed bias — a low-power non-rejection.
  Never “unbiased”.
- **FAIL** = banked negative. `V2-SSHINV` stays `partial`. No relaxation.
- Either way: this SHA does **not** flip covered, does **not** bump to 0.8.0,
  and does **not** change the FA lane. Count stays 7.

## Still open after a PASS (note only; do not fake)

| §3 item | state |
|---|---|
| G5 second comparator / fit-level honesty | AGHmatrix closed **construction**. `preGSf90` / `blupf90+` not provisioned. Recovery-substitution disclosure **not written**. |
| Darwin SIGN | not signed; nothing PASS’d to sign until this gate exists |
| Boole `single_step()` freeze | **FROZEN 2026-09-03** — `docs/design/56-single-step-grammar-freeze.md` (ordinary defaults only; maintainer nod still pending for a flip) |
| R catch-up + element-wise parity | R already opt-in partial; engine evidence not yet mirrored |
| Interval coverage prereg | not the 0.8 critical path; say “not coverage-calibrated” |
| Rose CLEAN + G10 | spawn only after 1–7 are on disk |

## Pre-lock path probe (disjoint seeds; not the gate)

Local Julia 1.10.0, `JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1`, before this
commit. Used only to confirm n = 240 is not the n=6 unidentified collapse.
Gate seeds `20265000..47` were **not** run.

| mode | result |
|---|---|
| construct | n=240, n_geno=120, max\|G−A₂₂\|=0.05, cond(H)=12.65, ~9 s |
| smoke `20264999` | conv, σ²a=0.3908, σ²e=2.0495 (one-seed dump) |
| feasibility `20264990..92` | 3/3 conv; σ²a = 0.95, 0.79, 0.26; mean 0.67; high sampling variance, **not** n=6 (~0.08) collapse |

One-fit wall after compile is ~1 s. 48-seed sequential is minutes, not hours.

## RESULT (run 2026-09-03, AFTER freeze `8e6e038b`) — **GATE: PASS**

`sim/v08_ss_s2_recovery.jl --mode=gate`, seeds `20265000..20265047`,
Totoro, julia 1.10.0, `JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1`.
Freeze SHA `8e6e038b37046f65ad3aa5b54ca2616e523263c6`.
Driver SHA-256 `c010249bf46c2824b2c576137731b629b7e3c1da1a33de99c943997e05bd3d86`
byte-identical to freeze (`git diff 8e6e038b -- sim/v08_ss_s2_recovery.jl` empty).
Raw TSV/log (outside git): `totoro:~/hsq_work/results/v08_ss_s2_n240_8e6e038b/`.

| component | mean | truth | bias | MCSE | \|bias\|/MCSE | verdict |
|---|---|---|---|---|---|---|
| σ²a | 1.0441 | 1.00 | +0.0441 | 0.0516 | 0.86 | PASS |
| σ²e | 1.4586 | 1.50 | −0.0414 | 0.0466 | 0.89 | PASS |
| h² (reported, not gated) | 0.4147 | 0.40 | +0.0147 | 0.0187 | 0.79 | (not a PASS object) |

**48/48 converged; σ²a and σ²e `|bias| ≤ 2·MCSE` → GATE PASS.**
Read as no detectable across-seed bias — **never “unbiased”**.

**Still not a flip.** `V2-SSHINV` stays **partial**. Count stays **7**.
Experimental **0.7.0**. FA sibling untouched. Boole ordinary-default
`single_step()` freeze is now on disk (`docs/design/56-single-step-grammar-freeze.md`).
G5 / Darwin / R catch-up / Rose CLEAN remain open (note only; not invented here).
