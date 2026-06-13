# Genomic Reliability / PEV / Accuracy Semantics

Active lenses: Fisher, Gauss, Kirkpatrick, Curie, Rose (inline).
Spawned subagents: none (design from the `phase2-engine-plan` workflow).

## Goal

Close the silent-mislabeling gap that GBLUP opened: confirm and document that the
existing `reliability` / `prediction_error_variance` / `accuracy` extractors
already compute the correct genomic quantities for a GBLUP fit, and that the
`:selinv` PEV path carries over to a genomic `Ginv`.

## Files Changed

- `src/likelihood.jl` (docstring-only clarification on `reliability`; no logic
  change)
- `test/runtests.jl` (testset "Phase 2 genomic reliability / PEV / accuracy
  semantics")
- `src/validation_status.jl`, `docs/design/capability-status.md`,
  `docs/design/validation-debt-register.md` (V2-GBLUP evidence updated; no new
  row), `docs/src/changelog.md`, `docs/dev-log/check-log.md`,
  `docs/dev-log/after-task/2026-06-13-genomic-reliability.md`

## Implementation

`reliability` computes `1 − PEV_i / (σ²a · A_ii)` with `A = inv(Ainv)`. For a
genomic spec `Ainv = Ginv`, so `A = G + ridge·I` and `A_ii` is the genomic
self-relationship `diag(G)` (often ≠ 1) — the mathematically correct denominator.
No code change was needed; the docstring now states this explicitly.

## Checks

- `Pkg.test()`: passed, 637 total. New testset = 5 checks. Verified independently
  before pinning: genomic `diag(inv(Ginv))` = `[1.45, 1.45, 0.77, 1.11]` (≠ 1),
  `rel ∈ [0,1]`, `PEV = (1−rel)·σ²a·diag` to ~1e-16, `accuracy = √rel` exactly,
  `:selinv` == dense PEV to ~3e-16.

## Public Claim Audit

Allowed: genomic reliability/accuracy/PEV are computed from `diag(G)` via the
existing extractors; selinv PEV diagonal matches the dense path.

Blocked: any claim these reliabilities are validated against an external
genomic-reliability comparator (self-consistent only — that gap stays in
V2-GBLUP / V5-GBLUP); any performance claim for selinv on dense `Ginv` (no
speedup until sparse/APY `G`).

## Coordination Notes

Engine-internal; no public-contract change.

## Known Limitations

- Self-consistency only; no external genomic-reliability comparator.
- Dense `Ginv`; selinv is a correctness mirror here, not a speedup.

## Next Actions

1. Single-step `H⁻¹` construction utility (final engine slice).
