# HSData Environment Diagnostics

Date: 2026-06-13

Active lenses: Ada, Emmy, Darwin, Pat, Hopper, Karpinski, Rose, Grace.

Spawned subagents: none.

## Goal

Mirror the R twin's environment-key diagnostics in Julia `HSData` while
keeping bridge payloads, model terms, automatic joins, and fitting behavior
unchanged.

## R Handoff

R commits:

- `07c8145 Add hs_data environment diagnostics`;
- `e7fbb31 Record hs_data environment CI evidence`.

Reported R evidence:

- R-CMD-check `27463966276`: success;
- pkgdown `27463966261`: success;
- Pages `27463998276`: success.

R behavior:

- `hs_data(..., environment = env, environment_id = "site")` validates a
  shared key in phenotype and environment metadata;
- `summary(hs_data(...))` and `data_status()` expose `environment_status`;
- unkeyed environment tables are accepted and reported as not key-checked.

## Julia Implementation

Added:

- `HSEnvironmentSpec`;
- `HSDataEnvironmentStatusRow`;
- `environment_status` on `HSDataStatus`;
- `environment_id` keyword support on `HSData`;
- keyed and unkeyed environment diagnostics in `data_status(::HSData)`;
- tests for overlap counts, missing metadata keys, environment-only keys,
  duplicate environment IDs, unkeyed status, invalid keys, and missing values.

## Files Changed

- `src/HSquared.jl`;
- `src/data.jl`;
- `test/runtests.jl`;
- `README.md`;
- `ROADMAP.md`;
- `docs/design/03-engine-contract.md`;
- `docs/design/06-public-claims-register.md`;
- `docs/design/09-hsdata-contract.md`;
- `docs/design/capability-status.md`;
- `docs/design/validation-debt-register.md`;
- `docs/dev-log/check-log.md`;
- `docs/dev-log/coordination-board.md`;
- `docs/src/api.md`;
- `docs/src/changelog.md`;
- `docs/src/data.md`;
- `docs/src/index.md`;
- `docs/src/roadmap.md`.

## Checks

- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed. Testset totals sum
  to 421 checks; the Phase 1 HSData ID container testset has 81 checks.
- `julia --project=docs docs/make.jl`: passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependencies reported npm
  advisories in temporary build artifacts.
- `git diff --check`: passed.
- Additions-only ASCII scan: returned no matches.
- Claim-boundary scan: found only expected guardrail and blocked-wording hits
  around metadata diagnostics, bridge payloads, environment joins, model
  terms, multi-environment fitting, genotype parsing, marker scanning,
  QTL/eQTL, and GLLVM workflows.

Remote checks for implementation commit `6162e9b`:

- CI `27464260362`: success on Julia 1 and Julia 1.10.
- Documenter `27464260366`: success.
- Pages deploy `27464291912`: success.
- GitHub Actions reported non-blocking Node 20 deprecation annotations for the
  action stack.

Live docs:

- `https://itchyshin.github.io/HSquared.jl/dev/`: HTTP 200.
- `https://itchyshin.github.io/HSquared.jl/dev/data.html`: HTTP 200 and
  contains `Environment Metadata` and `environment_status`.
- `https://itchyshin.github.io/HSquared.jl/dev/api.html`: HTTP 200 and
  contains `HSEnvironmentSpec` and `HSDataEnvironmentStatusRow`.

## Public Claim Audit

Allowed wording:

- `HSData` can store environment metadata;
- `environment_id` validates a shared key across phenotype and environment
  metadata;
- `data_status(::HSData)` reports keyed or unkeyed environment metadata
  diagnostics.

Blocked wording:

- bridge payload shape changed;
- environment covariates are joined into fixed-effect design matrices;
- environmental fixed/random effects are implemented;
- multi-environment animal models are implemented;
- QTL/eQTL, GLLVM, genomic, or environmental workflows are implemented from
  this slice.

Rose verdict: clean with limitations. This is a metadata-diagnostics parity
slice only.

## Coordination Notes

- Julia lane only. No R repo edits were made.
- The R head `e7fbb31` is recorded as the source of the environment-status
  handoff.
- No Julia engine API or bridge payload change is required by the R slice.

## Next Actions

1. Commit and push the remote-evidence update.
2. Watch CI, Documenter, and Pages for the evidence commit.
3. Update the issue ledger.
