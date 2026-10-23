# After-task: current-candidate GLLVM estimand and bridge check

## 1. Goal

Strengthen the fixed-rank GLLVM reduction evidence and recheck the bounded live
R-Julia route on the exact current candidates.

## 2. Implemented

Added a Gaussian objective reduction regression with a nonidentity pedigree
and a two-column fixed-effect design. The test also verifies the stated
`-T*log(abs(det(C)))` shift when a nonsingular matrix changes the supplied
fixed-effect basis. Recorded scoped Noether and Hopper reviews of the current
engine and bridge sources.

## 3a. Decisions and Rejected Alternatives

- Kept the approved fixed rank K=2 Poisson GLLVM route unchanged.
- Compared the Gaussian objective with the existing multivariate REML oracle
  at the same X, covariance, and pedigree.
- Tested the fixed-effect coordinate shift directly rather than claiming that
  the flat-measure objective is invariant to arbitrary X reparameterization.
- Did not change capability status or infer broad model coverage from a tiny
  fixture.

## 4. Files Touched

- `test/genetic_gllvm_trait_effects.jl`
- `GATES.md`
- `docs/dev-log/source-review/2026-09-29-gllvm-current-exact-candidate.md`
- `docs/dev-log/check-log.d/2026-09-29-gllvm-current-exact-candidate.md`
- `docs/dev-log/after-task/2026-09-29-gllvm-current-exact-candidate.md`

## 5. Checks Run

- Julia GLLVM focused file: 73/73 passed; the new regression passed 6/6.
- Full Julia `Pkg.test()` exited 0 and ended with `Testing HSquared tests
  passed`. It emitted the existing project/manifest mismatch warning. No
  resolve or update was run.
- Live R GLLVM opt-in suite: 87/87 passed in 18.5 seconds, with no failures,
  warnings, or skips.
- `git diff --check -- test/genetic_gllvm_trait_effects.jl`: passed.

## 6. Tests of the Tests

The new fixture uses a six-animal pedigree, a nonidentity relationship, two
traits, one genetic factor, and an intercept plus numeric covariate. Both
objectives must converge and agree to `1e-8`. A nonsingular 2-by-2 transform
then changes the supplied fixed-effect coordinates while preserving their
column space; both Gaussian REML and the GLLVM integrated objective must shift
by `-T*log(abs(det(C)))` to `1e-8`.

## 7a. Issue Ledger

- Fixed: no focused Gaussian reduction fixture exercised a nontrivial
  multi-column fixed-effect design.
- Still open: whole-source review, same-objective external comparator,
  population recovery, and inference calibration.

## 8. Consistency Audit

Noether found the reviewed symbolic objective, trait-major ordering, latent
prior, observed-Hessian correction, Gaussian reduction, and `F*Λ' + D`
reconstruction consistent with the current Julia source. Hopper found the
bounded R payload and trait/pedigree order consistent with that engine
contract. The live bridge suite passed on these candidates. The GLLVM fit
remains experimental and partial.

## 9. What Did Not Go Smoothly

The most recent repo handover still points to an older Claude lane. Current
preflight shows this Codex candidate is the sole active local lane, and the
coordination board assigns the FA/GLLVM candidate work here. This slice held an
exact four-hour lease on its test and report paths; no R files were edited.

## 10. Known Residuals

- E1 remains open for unreviewed tracked source spans and whole-wave panel
  signoff.
- A2 remains open for FA fitted-information, ordinary-start recovery,
  inference, and full panel evidence.
- V3 remains open for full final-candidate checks and remaining parity and
  review reconciliation.
- The R route still lacks a matched external same-objective comparator and
  broader recovery or calibration evidence.
- Gaussian FA's fixed uniqueness floor differs from the GLLVM FA feasible
  set near zero.

## 11. Team Learning

Integrated Laplace objectives with flat fixed-effect measure depend on the
coordinates supplied for X. A Gaussian reduction test should therefore compare
the same design basis and separately test the known determinant adjustment
when that basis changes.

## 12. Cross-Product Coverage

This slice adds a Julia Gaussian reduction check and verifies the bounded
Poisson GLLVM R-Julia bridge on the matched local candidate. It does NOT cover
whole-file E1, the Gaussian FA engine gate, broad GLLVM recovery, GPU execution,
release submission, a registry submission, or a public release tag.
