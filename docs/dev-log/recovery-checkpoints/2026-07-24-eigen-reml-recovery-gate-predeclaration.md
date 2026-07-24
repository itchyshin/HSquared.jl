# Pre-declaration — `fit_eigen_reml` bias/MCSE known-truth recovery gate (doc-16 / doc-33 path-(b))

**Status: PRE-DECLARED, committed BEFORE the 48-seed run** (no post-hoc threshold relaxation —
`docs/dev-log/decisions/2026-06-14-calibration-failure-response`). **Date:** 2026-07-24 · **Lane:**
Julia engine (`HSquared.jl`) · **Branch:** `codex/2026-07-13-v07-performance-localization`.

This is the **G11 known-truth recovery leg** for a POSSIBLE `V1-EIGEN-REML` experimental→covered
close. It **promotes nothing.** A covered move additionally requires the same-estimand external REML
comparator (`sommer`; G11 comparator leg), a real **Rose** audit (G8), maintainer sign-off (G10), and
the R bridge — and even then the flip is the owner's call. **`public_covered_count` stays 5**; this run
cannot move it. A gate FAILURE is a **banked negative**: `V1-EIGEN-REML` stays `partial`.

## What is being validated

`fit_eigen_reml` (`src/likelihood.jl`) estimates the two variance components of the single-effect
Gaussian animal model (`Z = I`, one record per animal) by the EMMA/GEMMA canonical transformation:
eigendecompose `A = Ainv⁻¹` ONCE (dense `O(n³)`, variance-independent), rotate `y`/`X`, then a 1-D
optimisation over the variance ratio via the already-validated `_genomic_profile_reml`. In-CI it already
recovers `fit_ai_reml` to `rtol = 1e-6` on one deterministic fixture (`test/runtests.jl`). This gate adds
the missing **known-truth, multi-seed** evidence: that eigen-once, run standalone across 48 cold-start
seeds, **recovers the true `(σ²a, σ²e)` with no detectable across-seed bias**, in BOTH the well-structured
and the high-fill regimes.

## Model / DGP (locked)

- **Model:** single-effect Gaussian animal model, `y = μ + u + e`, `Z = I_n` (one record/animal).
- **Breeding values (EXACT covariance):** `u = √σ²a · chol(A).L · z`, `z ~ N(0, I)`, `A = inv(Ainv)` —
  so `Cov(u) = σ²a · A` **exactly**, independent of the realized inbreeding (no Mendelian-recursion
  approximation that could bias the recovery target).
- **Residual:** `e ~ N(0, σ²e · I)`.
- **Truth (interior, off-boundary):** `(σ²a, σ²e) = (1.0, 1.5)` → **h² = 0.4**, `μ = 2.0`, **n = 1000**
  (≤ `max_dense_n = 20_000`; keeps eigen `O(n³)` fast).
- **Two pre-declared pedigree arms** (built by the SAME `window`-parameterized builder as the routing
  test in `test/runtests.jl`, so the fill regime is the tested one):
  - **Arm WS — well-structured:** `window = 50` → parents drawn from `[i-50, i-1]` → low fill-in
    (`nnz(L)/n ≈ 17–19`; the regime `:auto` routes to sparse AI-REML).
  - **Arm HF — high-fill:** `window = 0` → parents drawn from `[1, i-1]` → high fill-in
    (`nnz(L)/n ≥ 76`; eigen-once's intended win regime).
  In BOTH arms the gate fits `fit_eigen_reml` AND `fit_ai_reml` on identical data.

## Seeds (cold-start; UNSEEN at declaration)

- **Arm WS:** `20267000 .. 20267047` (48 seeds).
- **Arm HF:** `20267100 .. 20267147` (48 seeds).
- Disjoint from each other and from every prior gate (grep-verified against `sim/`, `test/`,
  `comparator/`, `docs/`: two-effect `20260618..622`, neffect `20260800..847`, direct-maternal
  `20264000..047`, etc. — `20267xxx` is clear). One `MersenneTwister(seed)` per fit.

## PASS criteria (ALL required; NO post-hoc relaxation)

For **EACH** arm:

1. **eigen 48/48 converged.**
2. **AI-REML 48/48 converged** (so the agreement in (4) is over the full 48).
3. **`|bias| ≤ 2·MCSE`** for eigen `σ²a` **AND** eigen `σ²e` (bias = across-seed mean − truth;
   MCSE = sd/√48). Read as: **no detectable across-seed bias** (a low-power non-rejection), never
   "unbiased".
4. **`max` over seeds of the eigen-vs-AI-REML relative difference `≤ 1e-6`** for `σ²a` AND `σ²e` (the
   substitutability corroboration: eigen and sparse AI-REML are the SAME estimand by a different route).

**Overall GATE = (Arm WS PASS) AND (Arm HF PASS).** The script prints per-arm bias/MCSE tables, a
`GATE: PASS|FAIL` line, and a machine-readable `GATE_JSON {...}` line, and exits `0` on PASS / `1` on FAIL.

## Scope of the resulting evidence (if it passes + comparator agrees + Rose + owner)

`fit_eigen_reml` correctly recovers the single-effect `(σ²a, σ²e)` on the tested `Z=I`, interior-`h²`,
`n=1000` designs in BOTH fill regimes, agreeing with sparse AI-REML to `1e-6`. **Documented scope edges
(not bugs):** `Z ≠ I` and `n > max_dense_n` (the dense wall) are guarded `ArgumentError`s, not covered
claims. **Not retired by a pass:** larger-`n` / broader-`h²` recovery, a 2nd same-estimand comparator,
the R `method="eigen"` surface. Engine-covered ≠ R-public-covered; `public_covered_count` stays 5.

## Run command

```sh
env OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase_eigen_reml_recovery_gate.jl
```

## Pre-commit smoke (functional check only — NOT the 48-seed evidence)

Before committing this freeze, a tiny-`n`, few-seed smoke confirmed the script **runs end-to-end,
emits well-formed `GATE_JSON`, and the fits are finite / near-truth / eigen≈AI-REML** — a functional
check of the harness, not the acceptance evidence (the acceptance criteria above are the STANDARD gate
used by every prior covered close; they are not tuned to any observed result). Smoke (n=250, 2 seeds/arm,
local Julia 1.10.0, 2026-07-24) recorded at commit time:

```
[WS seed=20267000] eigen conv=true σ²a=1.3348 σ²e=1.6133 | AI conv=true σ²a=1.3348 σ²e=1.6133 | reldiff σ²a=2.91e-08 σ²e=9.36e-09 | target=eigen_reml
[WS seed=20267001] eigen conv=true σ²a=1.0794 σ²e=1.5261 | AI conv=true σ²a=1.0794 σ²e=1.5261 | reldiff σ²a=7.52e-09 σ²e=2.26e-09 | target=eigen_reml
[HF seed=20267000] eigen conv=true σ²a=1.4994 σ²e=1.6074 | AI conv=true σ²a=1.4994 σ²e=1.6074 | reldiff σ²a=1.22e-08 σ²e=4.54e-09 | target=eigen_reml
[HF seed=20267001] eigen conv=true σ²a=0.4573 σ²e=1.8114 | AI conv=true σ²a=0.4573 σ²e=1.8114 | reldiff σ²a=1.70e-07 σ²e=2.24e-08 | target=eigen_reml
SMOKE_OK eigen gate harness runs, fits finite + near-truth, eigen≈AI-REML ≤ 1e-6
```

Both fitters converge on every smoke case; eigen ≈ AI-REML to 1e-7–1e-9; estimates finite (single small-n
draws show the expected sampling spread, e.g. HF seed 20267001 σ²a=0.46). The 48-seed × n=1000 evidence
is produced by the run below, NOT here.

> Related: `docs/design/16-promotion-gate-predicates.md` (G1–G11) ·
> `sim/phase_eigen_reml_recovery_gate.jl` (the frozen gate) ·
> `docs/dev-log/native-engine-arc/2026-07-24-ai-reml-convergence-findings.md` (eigen benchmark) ·
> prior gates: `2026-07-01-neffect-recovery-gate-predeclaration.md`,
> `2026-07-01-direct-maternal-recovery-gate-predeclaration.md`.
