# Henderson MME Supplied-Variance Fixture Sync

Date: 2026-06-13

Active lenses: Ada, Shannon, Curie, Henderson, Fisher, Hopper, Karpinski, Rose,
Grace.

Spawned subagents: none.

## Goal

Mirror the R twin's issue #7 supplied-variance Henderson MME validation fixture
in Julia tests and docs while keeping the claim boundary explicit.

## R Handoff

R commits:

- `ec2a9cc Add Henderson MME validation fixture`;
- `ca8bce1 Record Henderson MME CI evidence`.

Reported R evidence:

- R-CMD-check `27461992645`: success;
- pkgdown `27461992626`: success;
- Pages `27462024756`: success.

R behavior:

- `hs_henderson_mme_validation_fixture()` records the fixture;
- `hs_solve_henderson_mme_reference()` computes an independent R MME reference;
- R tests compare expected `Ainv`, fixed effects, EBVs, fitted values, and
  `h2`, plus live Julia `HSquared.henderson_mme()` when available.

## Julia Implementation

Updated the existing Henderson MME testset to pin the shared fixture exactly:

- IDs: `founder_a`, `founder_b`, `animal_1`, `animal_2`, `animal_3`;
- supplied variances: `sigma_a2 = 1.2`, `sigma_e2 = 0.8`;
- expected fixed effects: `3.898701298701298`,
  `0.6454545454545471`;
- expected EBVs: `0`, `0`, `-0.054545454545454695`,
  `0.05454545454545385`, `0.8571428571428561`;
- expected fitted values: `3.844155844155843`, `4.5987012987012985`,
  `4.755844155844154`, `5.401298701298701`;
- expected `h2 = 0.6`.

The test also keeps the independent Julia MME reference solve as a consistency
check, and checks `henderson_mme()` plus the dense validation-path extractors
against the pinned fixture.

## Files Changed

- `test/runtests.jl`;
- `src/validation_status.jl`;
- `README.md`;
- `ROADMAP.md`;
- `docs/design/03-engine-contract.md`;
- `docs/design/04-validation-canon.md`;
- `docs/design/06-public-claims-register.md`;
- `docs/design/capability-status.md`;
- `docs/design/validation-debt-register.md`;
- `docs/dev-log/check-log.md`;
- `docs/dev-log/coordination-board.md`;
- `docs/dev-log/after-task/2026-06-13-henderson-mme-supplied-variance-fixture.md`;
- `docs/src/changelog.md`;
- `docs/src/index.md`;
- `docs/src/quickstart.md`;
- `docs/src/roadmap.md`;
- `docs/src/validation-status.md`.

## Checks

- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed. Testset totals sum
  to 358 checks; the Henderson MME supplied-variance validation fixture has
  28 checks.
- `julia --project=docs docs/make.jl`: passed. Local deployment was skipped as
  expected outside CI; Vitepress dependency installation still reported npm
  advisories in generated/transient build artifacts.
- `git diff --check`: passed.
- Additions-only ASCII scan: returned no matches.
- Claim scan: found only expected boundary wording around no
  variance-component estimation, no AI-REML, no fitted Mrode validation, no
  external fitted-model parity, no production sparse fitting, and no
  performance claim.
- Remote checks: pending.

## Public Claim Audit

Allowed wording:

- `henderson_mme()` matches the shared supplied-variance fixture for `Ainv`,
  fixed effects, EBVs, fitted values, and `h2`;
- R head `ca8bce1` also compares Julia against an independent R MME reference
  when the sibling checkout is available;
- this is supplied-variance equation-solve validation.

Blocked wording:

- variance-component estimation is validated;
- AI-REML is implemented or validated;
- fitted Mrode animal-model outputs are validated;
- ASReml, BLUPF90, DMU, WOMBAT, sommer, or MCMCglmm fitted-output parity
  exists;
- production sparse fitting is implemented.

Rose verdict: clean locally, pending remote CI evidence.

## Tests Of The Tests

- The fixture now uses pinned expected numerical values from the R handoff
  rather than only recomputing expected outputs inside Julia.
- The independent Julia MME reference solve remains in the test to detect
  fixture transcription mistakes.
- `validation_status()` tests assert that the `V1-MME` row remains `partial`
  and keeps no-variance-component-estimation wording.

## Coordination Notes

- Julia lane only. No R repo edits were made.
- No R-to-Julia bridge payload fields changed.
- No base `result_payload()` fields changed.
- No formula grammar or `HSData` semantics changed.

## What Did Not Go Smoothly

- The first test patch added new non-ASCII approximate-equality operators. The
  additions-only ASCII scan caught them, and the new checks were rewritten with
  `isapprox(...)`.

## Known Limitations

- This fixture validates supplied variance components only.
- It does not validate variance-component estimation, AI-REML, fitted Mrode
  output, external fitted-model comparators, production sparse reliability,
  production sparse PEV, or production sparse fitting.

## Next Actions

1. Commit and push the fixture sync.
2. Watch CI, Documenter, and Pages.
3. Update the GitHub issue with Julia evidence after remote checks are green.
