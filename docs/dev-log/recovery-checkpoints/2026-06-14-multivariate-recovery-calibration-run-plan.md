# 2026-06-14 Multivariate Recovery Calibration Run Plan

## Scope

This run plan executes the protocol in
`docs/dev-log/decisions/2026-06-14-multivariate-recovery-calibration-protocol.md`
for the current dense/validation-scale multivariate recovery harnesses:

- `sim/phase4_multivariate_reml_recovery.jl` (`V4-MV-REML`)
- `sim/phase4b_structured_covariance_recovery.jl` (`V4-FA`)

It is an opt-in local run outside CI. It does not add RNG to the test suite and
does not change R syntax, bridge payloads, `result_payload()`, covariance
standard errors, likelihood-ratio tests, or comparator parity.

## Engine Code SHA

The Julia engine code to be calibrated is:

```text
042bd58c4b444b6d78ed4bd7e62662dea8bdc005
```

This checkpoint is a docs-only record layered on top of that code state.

## Julia And Platform

```text
Julia Version 1.10.0
Commit 3120989f39b (2023-12-25 18:01 UTC)
OS: macOS (arm64-apple-darwin22.4.0)
CPU: 20 x Apple M1 Ultra
Threads: 1 on 16 virtual cores
```

## Commands

Unstructured Phase 4 multivariate REML recovery:

```sh
~/.juliaup/bin/julia --project=. sim/phase4_multivariate_reml_recovery.jl --seeds=20260616,20260617,20260618,20260619,20260620,20260621,20260622,20260623,20260624,20260625
```

Structured Phase 4B recovery (`factor_analytic` and `lowrank`):

```sh
~/.juliaup/bin/julia --project=. sim/phase4b_structured_covariance_recovery.jl --case=both --seeds=20260614,20260615,20260616,20260617,20260618,20260619,20260620,20260621,20260622,20260623
```

Raw output will be preserved under `docs/dev-log/recovery-checkpoints/` and
summarized in the check-log and after-task report.

## Seeds

- Unstructured: `20260616`, `20260617`, `20260618`, `20260619`, `20260620`,
  `20260621`, `20260622`, `20260623`, `20260624`, `20260625`.
- Structured `factor_analytic`: `20260614`, `20260615`, `20260616`,
  `20260617`, `20260618`, `20260619`, `20260620`, `20260621`, `20260622`,
  `20260623`.
- Structured `lowrank`: `20260614`, `20260615`, `20260616`, `20260617`,
  `20260618`, `20260619`, `20260620`, `20260621`, `20260622`, `20260623`.

No seed will be dropped or replaced after seeing results.

## Iteration Caps And Thresholds

Defaults from the scripts will be used.

Unstructured:

- iterations: `5000`
- relative `G` error threshold: `0.25`
- relative `R` error threshold: `0.20`

Structured:

- iterations: `5000`
- relative `G` error threshold: `0.45`
- relative `R` error threshold: `0.25`

## Data-Generating Parameters

Unstructured harness:

- traits: `2`
- sires: `8`
- dams: `16`
- offspring: `56`
- animals: `80`
- records per animal: `3`
- observations: `240`
- generating `G`:

```text
[1.0  0.35
 0.35 0.7]
```

- generating `R`:

```text
[0.8 0.2
 0.2 0.55]
```

Structured harness:

- traits: `3`
- sires: `6`
- dams: `12`
- offspring: `42`
- animals: `60`
- records per animal: `3`
- observations: `180`
- loading matrix:

```text
[ 0.9
  0.55
 -0.35]
```

- uniqueness vector for `factor_analytic`:

```text
[0.35, 0.45, 0.55]
```

- generating residual `R`:

```text
[0.85  0.18  0.05
 0.18  0.75 -0.08
 0.05 -0.08  0.65]
```

The `lowrank` case uses `G = Lambda * Lambda'`. The `factor_analytic` case uses
`G = Lambda * Lambda' + diagm(uniqueness)`.

## Planned Summary

The execution report will include, for each case:

- seeds requested and completed;
- pass and convergence counts;
- mean, median, and maximum relative `G` error;
- mean, median, and maximum relative `R` error;
- a seed-level table with convergence, iterations, relative errors, thresholds,
  and pass/fail;
- a Wilson 95% interval for the pass proportion;
- failed seeds and raw output if any seed fails.
