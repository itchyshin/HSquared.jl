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
genomic spec `Ainv = Ginv`, so `A = G + ridge·I` and `A_ii = diag(inv(Ginv)) =
diag(G) + ridge` (the regularized genomic self-relationship, often ≠ 1) — so the
ridge perturbs the reported reliability/accuracy. No code change was needed; the
docstring now states this explicitly.

## Checks

- `Pkg.test()`: passed. Testset = 7 checks: PEV independently anchored against a
  re-assembled MME inverse; reliability rebuilt from that independent PEV and the
  `diag(inv(Ginv)) = diag(G) + ridge` denominator (so a wrong denominator fails);
  `diag(inv(Ginv)) ≠ 1`; `rel ∈ [0,1]`; `accuracy = √reliability` vs the
  independent reliability; `:selinv` == dense PEV. (PEV/accuracy were
  independently anchored after an adversarial review flagged the original
  assertions as tautological/definitional.)

## Public Claim Audit

Allowed: genomic reliability/accuracy/PEV are computed from
`diag(inv(Ginv)) = diag(G) + ridge` via the existing extractors; selinv PEV
diagonal matches the dense path.

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
