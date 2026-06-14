# 2026-06-14 Loading Rotation Identifiability

## Task Goal

Record the Phase 4B loading metadata policy clearly enough that the existing
sign-canonicalized `genetic_loadings()` output cannot be overread as a solved
rotation or biological interpretation convention.

## Active Lenses And Spawned Agents

- Kirkpatrick/Gauss: factor-analytic covariance and rotation semantics.
- Hopper: result-shape and bridge boundary.
- Fisher/Rose: identifiability wording and public claim boundary.
- Grace: checks and audit trail.
- Spawned agents: none.

## Files Changed

- `docs/dev-log/decisions/2026-06-14-loading-rotation-identifiability.md`
- `src/validation_status.jl`
- `test/runtests.jl`
- `docs/design/03-engine-contract.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/design/06-public-claims-register.md`
- `docs/src/validation-status.md`
- `docs/src/multivariate-models.md`
- `docs/src/changelog.md`
- `ROADMAP.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.md`
- this report

## What Landed

The decision note records the current Phase 4B policy:

- returned low-rank and factor-analytic loading metadata uses a deterministic
  sign convention;
- for each loading column, the largest-absolute loading is made non-negative;
- this is a Julia-local metadata convention only;
- loading columns remain rotation-nonunique and uninterpreted.

The status surfaces now say that full loading rotation and interpretation are
still validation debt, rather than saying no convention exists at all.

## Checks Run

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`: passed.
  - Phase 0 scaffold/validation-status block is now 172 checks.
  - Phase 4B structured covariance testset remains 61 checks.
- `~/.juliaup/bin/julia --project=docs docs/make.jl`: passed.
  - Known caveats remained: 8 docstrings not included in the manual; local
    deployment skipped outside CI; VitePress default config substitutions;
    missing local logo/favicon/package.json substitutions; 4 npm audit
    advisories in generated docs dependencies.
- `git diff --check`: passed.
- Boundary scan found the intended sign-only and rotation-identifiability
  wording alongside explicit `result_payload()` and bridge-payload no-change
  boundaries.

## Public Claim Audit

Allowed:

- Phase 4B returned loading metadata is sign-canonicalized;
- the sign convention is deterministic and test-covered;
- the sign-only policy is recorded in a decision note;
- `V4-FA` remains partial.

Blocked:

- no unique factor-loading identification;
- no biological interpretation of loading columns;
- no full loading rotation convention;
- no R-facing `fa(K)` or rotation syntax;
- no bridge payload or `result_payload()` change;
- no external comparator parity for loading estimates;
- no covariance SE/LRT or production sparse/GPU support.

## Tests Of The Tests

The validation-status test now requires the `V4-FA` evidence to mention the
rotation-identifiability decision, so future row rewrites should preserve the
policy boundary.

## Coordination Notes

No R repository code was edited. This is useful for the R lane only as a future
boundary: R-facing covariance syntax, extractor wording, rotation choices, and
plots should not promise identified loadings until a coordinated design slice
chooses and validates that behavior.

## What Did Not Go Smoothly

Nothing material. The previous status wording was slightly ambiguous because it
said no loading rotation or identifiability convention existed, even though the
engine already had a deterministic sign convention for metadata.

## Known Limitations

- The decision does not choose a lower-triangular, varimax, target-rotation, or
  trait-anchored convention.
- It does not test likelihood or covariance invariance under post hoc
  rotations.
- It does not add external comparator evidence.

## Next Actions

1. Push the branch and confirm GitHub Actions.
2. Post PR and issue coordination notes for the Julia and R lanes.
3. Keep full loading rotation and interpretation as a separate evidence-gated
   slice.
