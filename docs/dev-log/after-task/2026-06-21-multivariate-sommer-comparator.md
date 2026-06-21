# After-task — Multivariate REML sommer comparator evidence (V4-MV-REML)

Date: 2026-06-21. Lane: Julia engine (`HSquared.jl`). Branch:
`codex/mv-comparator-evidence`. Type: EVIDENCE / claim-status slice.

## Summary

Reproduced the R-lane `sommer` comparator run against
`test/fixtures/phase4_multitrait_parity/` and recorded the evidence in the Julia
engine repo. The comparator used `sommer` 4.4.5 and rebuilt `A` independently
with `nadiv::makeA`, then matched the stored Julia multivariate REML target
tightly: `max abs(dG0)=7.529e-05`, `max abs(dR0)=7.626e-06`,
`max abs(dbeta)=1.801e-06`, `max abs(dh2)=6.821e-05`, EBV correlations
1.000/1.000, and `max abs(dEBV)=4.398e-05`. REML loglik was not compared
because the two tools report different additive-constant scales.

## Active Lenses

Ada + Shannon handled the Claude-to-Codex handoff and cross-lane boundary.
Curie + Fisher + Mrode reviewed the validation evidence shape. Rose handled the
claim-vs-evidence boundary. Grace covered local checks. No subagents were
spawned.

## Files Changed

- `src/validation_status.jl` — V4-MV-REML evidence, missing-evidence, and
  claim-boundary strings updated from "no external comparator" to "one
  reproduced `sommer` fixture run; still partial".
- `test/runtests.jl` — validation-status tests now pin the comparator evidence
  strings and the partial-status boundary.
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/design/06-public-claims-register.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.d/2026-06-21-multivariate-sommer-comparator.md`
- `docs/dev-log/recovery-checkpoints/2026-06-21-multivariate-sommer-comparator.md`

## Commands / Results

- `Rscript data-raw/multivariate-comparator-study.R` from the read-only sibling
  `hsquared` repo — passed and printed the `sommer` 4.4.5 agreement metrics
  recorded above.
- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` — passed.
- `~/.juliaup/bin/julia --project=docs docs/make.jl` — passed. Existing-style
  warnings were observed for undocumented docstrings, missing local
  Vitepress assets, local-build deployment detection, and npm audit output.
- `git diff --check` — passed.

## Claim Boundary / Rose Audit

Clean with limitations. This removes the stale-negative statement that the
multivariate REML target had no external comparator evidence. It does **not**
promote `V4-MV-REML` to `covered`: the evidence is one deterministic
fixture/package, the broad recovery gate is still not passed or re-declared, no
published Mrode-style multi-trait target is recorded, and ASReml/BLUPF90/JWAS or
equivalent independent parity remains open. No R-facing multivariate model spec
or production sparse multivariate path is claimed.

## Coordination Notes

The sibling R repo was dirty before use and was treated as read-only. No issue
comments were posted and no sister-repo files were changed. The Julia-side status
now matches the R-lane comparator evidence while preserving the public-coverage
gate.

## Next

- Decide whether to add a second independent comparator package for the same
  fixture (ASReml, BLUPF90, JWAS, or equivalent).
- Revisit the broad multivariate recovery gate in bias/MCSE terms or run a
  relatedness-richer design with a predeclared pass rule.
- Keep R-facing multivariate syntax/bridge exposure gated until the R lane asks
  for it explicitly.
