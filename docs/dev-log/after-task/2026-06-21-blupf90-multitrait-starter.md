# After-task — BLUPF90 multivariate comparator starter packet

Date: 2026-06-21. Lane: Julia engine (`HSquared.jl`). Branch:
`codex/mv-second-comparator-target`. Type: comparator scaffold / evidence setup.

## Summary

Added an opt-in BLUPF90-family starter packet generator for the deterministic
two-trait multivariate REML fixture. The generator rewrites
`test/fixtures/phase4_multitrait_parity/` into whitespace-delimited data,
pedigree, target covariance, and starter `renumf90.par` files under
`comparator/blupf90_multitrait/`.

This is designed to help the next evidence-producing leg: a second independent
same-estimand comparator beyond the already recorded `sommer` run.

## Active Lenses

Curie + Fisher + Mrode checked that the target remains the same bivariate
Gaussian animal-model estimand. Rose guarded the no-evidence-yet claim boundary.
Grace covered local checks. Shannon kept this as Julia-side scaffold only; no R
files were edited. No subagents were spawned.

## Files Changed

- `.gitignore` — ignores generated BLUPF90 starter inputs and outputs.
- `comparator/prepare_blupf90_multitrait.jl` — opt-in packet generator.
- `comparator/blupf90_multitrait/README.md` — run instructions and evidence
  boundary.
- `comparator/README.md` — comparator index updated with the BLUPF90 packet.
- `docs/src/validation-status.md` — stale public-doc wording updated so the
  multivariate REML row reflects the banked `sommer` + R-lane recovery evidence
  while staying `partial`.
- `docs/dev-log/check-log.d/2026-06-21-blupf90-multitrait-starter.md`

## Commands / Results

- `julia comparator/prepare_blupf90_multitrait.jl` — passed.
- `git status --short --ignored comparator/blupf90_multitrait comparator/prepare_blupf90_multitrait.jl .gitignore`
  — confirmed generated packet files are ignored.
- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` — passed.
- `~/.juliaup/bin/julia --project=docs docs/make.jl` — passed. Existing-style
  local-build warnings were observed for undocumented docstrings, missing local
  Vitepress logo/favicon assets, skipped deployment detection, and npm audit
  output.
- `git diff --check` — passed.

## Claim Boundary / Rose Audit

Clean with limitations. This packet is not BLUPF90 evidence. It does not run
RENUMF90, BLUPF90, or AIREMLF90, does not record comparator output, does not
choose a tolerance, and does not promote `V4-MV-REML`. The real evidence leg
still needs executable versions, generated parameter files, convergence output,
aligned estimates, and a claim audit.

## Next

- Run the packet on a machine with BLUPF90-family executables available.
- Record the exact `renf90.par`, output estimates, alignment rules, and
  tolerances.
- If the BLUPF90-family run agrees as a same-estimand comparator, update the
  validation ledgers as a second external comparator leg while keeping any
  remaining textbook-target blockers explicit.
