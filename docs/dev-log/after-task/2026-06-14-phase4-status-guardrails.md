# 2026-06-14 Phase 4 Status Guardrails

## Task Goal

Tighten the Phase 4/4B evidence guardrails on the `phase4b-factor-analytic-g`
branch after the multivariate accessor and structured-covariance slices.

This slice fixes a stale backend-roadmap row that still read as if
factor-analytic G matrices were only planned, and strengthens
`validation_status()` tests so the current extractor, bridge-boundary, recovery,
and loading-identifiability wording is regression-tested.

## Active Lenses And Spawned Agents

- Ada/Shannon: lane and twin-boundary discipline.
- Rose: public claim and evidence wording.
- Grace: local checks and audit trail.
- Karpinski: keep the change narrow and regression-test focused.
- Spawned agents: none.

## Files Changed

- `docs/src/backend-algorithm-roadmap.md`
- `test/runtests.jl`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-14-phase4-status-guardrails.md`

## Checks Run

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`: passed.
- `~/.juliaup/bin/julia --project=docs docs/make.jl`: passed.
  - Known caveats remained: 8 docstrings not included in the manual; local
    deployment skipped outside CI; VitePress default config substitutions;
    missing local logo/favicon/package.json substitutions; 4 npm audit
    advisories in generated docs dependencies.
- `git diff --check`: passed.
- Source-doc stale wording scan:
  - old `Factor-analytic G matrices | GPU-friendly later | ... | planned` row:
    no hits;
  - old `Multivariate G matrices | planned | no implementation yet` row:
    no hits.

## Public Claim Audit

No capability was promoted.

Allowed wording after this slice:

- Phase 4B structured genetic covariance support has an experimental dense
  CPU validation-scale engine path.
- GPU execution, backend dispatch, performance claims, and production sparse
  FA fitting remain planned.
- Multivariate result accessors are Julia-local wrappers over existing fields.

Blocked wording remains:

- no R-facing multivariate covariance-structure syntax;
- no bridge-payload or `result_payload()` widening;
- no external multi-trait comparator parity;
- no loading rotation/identifiability convention beyond deterministic sign
  canonicalization;
- no GPU execution or speed claim.

## Tests Of The Tests

The Phase 0 validation-status test block now asserts that:

- `V4-MULTIVARIATE` evidence mentions `variance_components` and
  `breeding_values`, and its boundary still mentions no bridge payload change;
- `V4-MV-REML` evidence mentions `heritability`, and its boundary still
  mentions `result_payload`, opt-in seeded recovery, and not multi-seed
  calibrated;
- `V4-FA` evidence mentions sign-canonicalization, and its boundary still says
  no R-facing syntax and not rotation-identified.

These are claim-regression tests, not numerical-method tests.

## Coordination Notes

This was a Julia-lane status/test/docs slice only. The R repo was not edited.
The coordination board records that the backend roadmap now separates the
implemented dense CPU validation-scale Phase 4B path from future
GPU/performance work, with no R syntax or bridge change.

## What Did Not Go Smoothly

The local environment still lacks the `gh` CLI, so GitHub status and comments
need the connector or API-token curl path rather than `gh run list`.

## Known Limitations

- The Phase 4/4B validation rows remain partial.
- No new covariance SE/LRT, external comparator, multi-seed calibration, or
  production sparse/GPU evidence was added.
- The docs build warnings listed above are pre-existing/local-build caveats and
  were not changed by this slice.

## Next Actions

- Push the branch and confirm GitHub Actions for the new head.
- Post a Julia PR / issue coordination note once CI is known.
- Keep the next engine slice focused on one remaining evidence gap, such as
  R-lane comparator handoff for the serialized multi-trait fixture or a
  deeper Phase 4B identifiability/rotation design note.
