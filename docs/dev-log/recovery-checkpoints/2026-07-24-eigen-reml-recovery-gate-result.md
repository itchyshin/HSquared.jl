# Result — `fit_eigen_reml` known-truth recovery gate: **PASS** (both arms)

**Date:** 2026-07-24 · **Pre-declaration:** `2026-07-24-eigen-reml-recovery-gate-predeclaration.md`
(frozen at commit `1d9ec57d`, BEFORE this run) · **Run:** Totoro, `~/.juliaup/bin/julia` **1.12.6**,
`OPENBLAS_NUM_THREADS=1`, checkout **`1d9ec57d`** (the frozen commit) · **Gate script:**
`sim/phase_eigen_reml_recovery_gate.jl`.

This discharges the **G11 known-truth recovery leg** for `V1-EIGEN-REML`. It promotes nothing on its
own — the same-estimand external REML comparator (`sommer`), a real **Rose** audit (G8), the R bridge,
and maintainer sign-off (G10) are still required, and even then the flip is the owner's call.
**`public_covered_count` stays 5.**

## Verdict: **GATE PASS** (Arm WS = PASS, Arm HF = PASS)

Truth `(σ²a, σ²e) = (1.0, 1.5)` → h² = 0.4, μ = 2.0, n = 1000, 48 cold-start seeds per arm.

### Arm WS — well-structured pedigree (`window = 50`, seeds `20267000..047`)
eigen **48/48** converged · AI-REML **48/48** converged

| param | mean | truth | bias | MCSE | \|bias\|/MCSE | verdict |
|---|---|---|---|---|---|---|
| σ²a | 0.9700 | 1.00 | −0.0300 | 0.0297 | **1.01** | PASS (≤2) |
| σ²e | 1.4998 | 1.50 | −0.0002 | 0.0118 | 0.02 | PASS |

eigen ≈ AI-REML max rel.diff: σ²a = **2.62e-7**, σ²e = 6.34e-8 (tol 1e-6) → PASS.

### Arm HF — high-fill pedigree (`window = 0`, seeds `20267100..147`)
eigen **48/48** converged · AI-REML **48/48** converged

| param | mean | truth | bias | MCSE | \|bias\|/MCSE | verdict |
|---|---|---|---|---|---|---|
| σ²a | 1.0001 | 1.00 | +0.0001 | 0.0326 | 0.00 | PASS |
| σ²e | 1.4960 | 1.50 | −0.0040 | 0.0152 | 0.26 | PASS |

eigen ≈ AI-REML max rel.diff: σ²a = **2.18e-7**, σ²e = 4.94e-8 (tol 1e-6) → PASS.

## Honest reading

- **No detectable across-seed bias** in either arm at the pre-declared `|bias| ≤ 2·MCSE` bound. This is a
  low-power non-rejection at 48 seeds — read as "no bias detected", **never "unbiased"**.
- The largest ratio is **Arm WS σ²a at 1.01·MCSE** (mean 0.970 vs truth 1.00) — a mild, statistically
  undetectable negative offset consistent with finite-sample REML at n=1000; it is *within* the bound, not
  a boundary ride. Every other parameter is ≤ 0.26·MCSE.
- **eigen ≡ AI-REML numerically** (≤ 2.6e-7 across all 96 fits): the substitutability corroboration holds —
  `fit_eigen_reml` and sparse `fit_ai_reml` are the SAME single-effect REML estimand by a different route,
  in BOTH fill regimes. Recovery therefore holds where eigen is actually used (high-fill), not only where
  `:auto` would pick sparse.

## What remains for a covered close (NOT discharged here)

- **G11 comparator leg:** an external same-estimand REML comparator (`sommer` primary; `blupf90+` optional
  2nd leg) — in progress.
- **G8:** a real spawned **Rose** claim-vs-evidence audit.
- **R bridge:** the R `method="eigen"` route (R-lane job) — not this lane.
- **G10:** maintainer sign-off. `public_covered_count` stays 5 until then.

## Reproduce

```sh
cd ~/hsq_work/HSquared.jl && git checkout 1d9ec57d
env OPENBLAS_NUM_THREADS=1 ~/.juliaup/bin/julia --project=. sim/phase_eigen_reml_recovery_gate.jl
# → GATE: PASS  (WS=true HF=true); exit 0
```

### `GATE_JSON` (verbatim)

```json
{"gate_pass":true,"truth":{"sa":1.0,"se":1.5},"arms":{"WS":{"pass":true,"eigen_converged":48,"ai_converged":48,"n":48,"sa":{"bias":-0.029972,"mcse":0.029689,"mean":0.970028},"se":{"bias":-0.0002,"mcse":0.011815,"mean":1.4998},"max_reldiff_sa":2.62e-7,"max_reldiff_se":6.34e-8},"HF":{"pass":true,"eigen_converged":48,"ai_converged":48,"n":48,"sa":{"bias":0.000109,"mcse":0.032627,"mean":1.000109},"se":{"bias":-0.003981,"mcse":0.015229,"mean":1.496019},"max_reldiff_sa":2.18e-7,"max_reldiff_se":4.94e-8}}}
```

> Related: `docs/design/16-promotion-gate-predicates.md` (G11) ·
> `sim/phase_eigen_reml_recovery_gate.jl` · the predeclaration doc (frozen `1d9ec57d`).
