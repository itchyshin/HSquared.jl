# 2026-06-14 Calibration Failure Response

## Task Goal

Record the response policy for the failed multivariate recovery calibration run
so future work cannot silently convert negative evidence into a calibration
claim.

## Active Lenses And Spawned Agents

- Curie/Fisher: simulation interpretation.
- Rose: claim-vs-evidence boundary.
- Grace: audit trail.
- Spawned agents: none.

## Files Changed

- `docs/dev-log/decisions/2026-06-14-calibration-failure-response.md`
- `docs/src/multivariate-models.md`
- `docs/src/changelog.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- this report

## What Landed

The decision note records that the failed 2026-06-14 calibration run cannot be
rescued by dropping failed seeds, silently relaxing thresholds, rerunning new
seeds until the pass count improves, or citing only passing subsets.

Allowed future responses must be declared before execution and include options
such as a larger DGP, justified threshold revision, optimizer diagnostics,
external comparator parity, or a narrower non-calibration claim.

## Public Claim Audit

Allowed:

- the failed calibration run is recorded as negative evidence;
- future reruns or threshold changes must be predeclared.

Blocked:

- no broad multi-seed calibration claim;
- no status promotion;
- no R-facing syntax;
- no bridge payload or `result_payload()` change;
- no comparator parity claim.

## Checks

- `git diff --check`: passed.
- Throttled `~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`: passed.
  - Recovery calibration log summarizer testset remains 12 checks.
  - Phase 0 scaffold/validation-status block remains 182 checks.
  - Phase 4B structured covariance testset remains 61 checks.
- Throttled `~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`: passed.
  - Known caveats remained: 8 docstrings not included in the manual; local
    deployment skipped outside CI; VitePress default config substitutions;
    missing local logo/favicon/package.json substitutions; 4 npm audit
    advisories in generated docs dependencies.
