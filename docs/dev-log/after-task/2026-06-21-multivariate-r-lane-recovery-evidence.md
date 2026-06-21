# After-task — Multivariate REML R-lane recovery evidence mirror (V4-MV-REML)

Date: 2026-06-21. Lane: Julia engine (`HSquared.jl`). Branch:
`codex/mv-validation-comparator-gate`. Type: EVIDENCE / claim-status slice.

## Summary

Mirrored the R-lane 100-rep cold-start multivariate recovery study into the
Julia validation ledgers. The R study records 100/100 converged fits from
`G0 = R0 = diag(2)` starts on a 420-animal two-trait pedigree; all 9 reported
G0/R0/rg/h2 targets had 0 inside bias +/- 2*MCSE, and EBV accuracy was
0.790/0.742. This corroborates the Julia 12-seed bias/MCSE and cold-start
evidence, but remains validation-scale evidence only.

## Active Lenses

Ada + Shannon handled the cross-lane boundary. Curie + Fisher + Mrode reviewed
the validation-evidence interpretation. Rose guarded the claim boundary. Grace
covered local checks. No subagents were spawned.

## Files Changed

- `src/validation_status.jl` — V4-MV-REML evidence, missing-evidence, and
  claim-boundary strings now include the R-lane 100-rep study and remove stale
  "not broadly multi-seed calibrated" wording from the claim boundary.
- `test/runtests.jl` — validation-status tests now pin the R-lane recovery
  evidence and remaining blocker language.
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/design/06-public-claims-register.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.d/2026-06-21-multivariate-r-lane-recovery-evidence.md`
- `docs/dev-log/recovery-checkpoints/2026-06-21-multivariate-r-lane-recovery-evidence.md`

## Commands / Results

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` — passed.
- `~/.juliaup/bin/julia --project=docs docs/make.jl` — passed. Existing-style
  local-build warnings were observed for undocumented docstrings, missing local
  Vitepress logo/favicon assets, skipped deployment detection, and npm audit
  output.
- `git diff --check` — passed.

The R recovery study itself was not rerun in this Julia slice. It was imported
as sibling-lane evidence from the committed R script/result block and R2
coordination note.

## Claim Boundary / Rose Audit

Clean with limitations. This update supports the statement that recorded
validation-scale cold-start bias/MCSE evidence shows no detectable bias in the
Julia and R designs. It does **not** promote `V4-MV-REML` to `covered`: the
strict per-seed calibration protocol was not passed or re-declared, external
comparator evidence is still one `sommer` fixture/package, no published
Mrode-style multi-trait target is recorded, and ASReml/BLUPF90/JWAS or
equivalent independent parity remains open.

## Next

- Add a second independent comparator leg for the same deterministic fixture.
- Add a published/textbook multi-trait estimate target if one can be reproduced
  cleanly.
- Keep public R-facing multivariate coverage gated until those debts are paid.
