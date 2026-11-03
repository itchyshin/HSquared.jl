# 2026-10-04 MV+PE eight-seed screening run

Status: screening evidence only. This does not change capability status or close H3.

## Declared screen contract

The unchanged script `sim/phase4_multivariate_repeatability_recovery.jl` declares the local screen: 8 sires, 16 dams, 48 offspring, four records per animal, two traits, and default seeds 20260926 through 20260933. Truth matrices are G0 = [[1.00, 0.30], [0.30, 0.80]], P0 = [[0.50, 0.10], [0.10, 0.40]], and R0 = [[0.80, 0.15], [0.15, 0.70]]. The screening rule is that each unique G0, P0, and R0 element and each trait repeatability has absolute Monte Carlo bias no greater than two MCSE among converged seeds. A pass is a directional screen, not a covered-status decision.

This is a **truth-started** screen: `run_one` initializes the fit at the exact G0, P0, and R0 truth matrices and permits 2,000 iterations. It therefore gives no evidence that ordinary starts reliably reach these fits. Eight seeds also give weak bias discrimination; G21's mean is about 42% above truth and still passes because its MCSE is large. The log retains all eight individual values only for G11, P11, and t1; the other eight quantities' per-seed estimates are absent, so their printed means and MCSEs cannot be reconstructed from the log. The independent numeric checker cross-checked the eleven displayed three-decimal inequalities against the script's printed decisions; it did not reconstruct all summaries from raw attempts.

## Execution and result

Julia 1.10.0 ran locally against the current dirty Julia worktree with Julia, OpenBLAS, OMP, and vecLib set to one thread. The shared Julia depot rejected its compiled-cache lock before any seed ran. That failed launch is retained at the start of the log. Retrying with `JULIA_DEPOT_PATH=/private/tmp/hsq-julia-depot:/Users/z3437171/.julia` completed all eight fits. Final screen process exit was 0 and the script printed `GATE_PASS`.

All 8/8 fits converged. All 11 gated quantities passed:

| Quantity | Truth | Mean | Bias | MCSE |
|---|---:|---:|---:|---:|
| G11 | 1.000 | 1.142 | 0.142 | 0.113 |
| G21 | 0.300 | 0.427 | 0.127 | 0.073 |
| G22 | 0.800 | 0.872 | 0.072 | 0.151 |
| P11 | 0.500 | 0.502 | 0.002 | 0.092 |
| P21 | 0.100 | 0.082 | -0.018 | 0.074 |
| P22 | 0.400 | 0.364 | -0.036 | 0.081 |
| R11 | 0.800 | 0.788 | -0.012 | 0.021 |
| R21 | 0.150 | 0.154 | 0.004 | 0.008 |
| R22 | 0.700 | 0.724 | 0.024 | 0.022 |
| t1 | 0.652 | 0.670 | 0.017 | 0.019 |
| t2 | 0.632 | 0.625 | -0.007 | 0.018 |

Retained output: `docs/dev-log/check-log.d/2026-10-04-mv-pe-8-seed-screen.log`, SHA-256 `f743066e2bdfacddaaf82f9413c3927dc0cd938743f3f222351b704ab184e432`. Julia HEAD was `0e4e5d742000f66bdb2127e43ca3756b432a5f10`; the checkout was dirty. The screen file hash was `50243cbd1a6765b1cee16811493cf94df452756729dfac8db51564ba749156b2`; fitted model source `src/multivariate.jl` hash was `2947cb72d8850593a62ca41e84c8125a52194a12730d0ad2b72b4b3d57c474a9`. These are direct-file fingerprints, not a complete source/dependency/test freeze.

Totoro was not used because its checkout was detached at a different commit (`3762eff09144f1da88de4f83ba872ffff7507d80`) and Julia 1.12.6, so it could not run this exact dirty source snapshot. Its pre-existing untracked simulation files were left untouched.

## Interpretation and next action

This is a passing truth-started eight-seed development screen for one bounded MV+PE DGP. It supplies no interval coverage, no broad recovery calibration, no ordinary-start optimizer evidence, no arbitrary-trait result, no missing-data result, and no R parity for the full fitted payload. The separate R one-seed recovery and `sommer` comparator checks are recorded in `docs/dev-log/check-log.d/2026-10-04-mv-parity-and-pe-route-tests.md`. H3 remains open. Freeze the full paired sources, tests, dependencies, and seed protocol for an ordinary-start study; obtain independent validation review; then decide the scale and criteria of the next seed study.

## Independent scientific review

Astra reviewed the current simulator, fitted source, retained log, and this report on 2026-10-04. Decision: **PASS as a truth-started eight-seed development screen only**. Astra confirmed the eleven printed inequalities pass, but independently reconstructed only G11, P11, and t1 from retained per-seed values; the remaining per-seed values are not in the log. The review also confirmed all eight fits converged and the earlier cache-lock failure occurred before simulation. No source, test, fit, or simulation was changed or run by the reviewer. Review limitations and complete ratios are retained in the review message for this task; this concise record does not upgrade the screen to ordinary-start recovery or calibration evidence.

## Evidence and prose assessment

Style: 2/10, medium confidence; exact cell details and numerical results dominate this technical record. Genre/coverage: internal validation check log, all sections reviewed. Evidence/repair: truth-start, weak discrimination, and unreconstructable summaries are stated explicitly. Gates: science passes for this bounded screen result only; facts pass against the execution log, source fingerprints, and independent Astra review; references pass for the internal paths cited. Provenance: self-review of this 2026-10-04 update after independent scientific review; the review assessed results and scope, not prose style.
