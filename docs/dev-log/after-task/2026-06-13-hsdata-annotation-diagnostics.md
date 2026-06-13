# HSData Annotation Diagnostics

Date: 2026-06-13

Active lenses: Ada, Emmy, Jason, Pat, Hopper, Karpinski, Rose, Grace.

Spawned subagents: none.

## Goal

Mirror the R twin's annotation-feature diagnostics in Julia `HSData` while
keeping bridge payloads, model terms, automatic joins, and fitting behavior
unchanged.

## R Handoff

R commits:

- `cc62dd2 Add hs_data annotation diagnostics`;
- `87888d9 Record hs_data annotation CI evidence`.

Reported R evidence:

- focused hs-data tests: 94 pass;
- full tests: 388 pass, with live Julia bridge activated locally;
- `pkgdown::check_pkgdown()`: no problems;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- R-CMD-check `27464280256`: success;
- pkgdown `27464280265`: success;
- Pages `27464310951`: success.

R behavior:

- `hs_data(..., annotation = annot, annotation_id = "gene_id")` validates
  annotation feature keys against expression feature columns;
- `summary(hs_data(...))` and `data_status()` expose `annotation_status`;
- unkeyed annotation tables are accepted and reported as not key-checked.

## Julia Implementation

Added:

- `HSAnnotationSpec`;
- `HSDataAnnotationStatusRow`;
- `annotation_status` on `HSDataStatus`;
- `annotation_id` keyword support on `HSData`;
- keyed and unkeyed annotation diagnostics in `data_status(::HSData)`;
- tests for expression/annotation feature overlap, annotation-only features,
  expression features without annotation, duplicate annotation feature IDs,
  unkeyed status, invalid keys, missing values, empty expression feature sets,
  and matrix-like expression inputs without feature column names.

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
  to 440 checks; the Phase 1 HSData ID container testset has 100 checks.
- `julia --project=docs docs/make.jl`: passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependencies reported npm
  advisories in temporary build artifacts.
- `git diff --check`: passed.
- Additions-only ASCII scan: returned no matches.
- Claim-boundary scan: found only expected guardrail and blocked-wording hits
  around metadata diagnostics, bridge payloads, annotation joins, eQTL/omics,
  GLLVM workflows, marker/QTL/GWAS workflows, and genomic fitting.

Remote checks for implementation commit `09a3718`:

- CI `27464551542`: success on Julia 1 and Julia 1.10.
- Documenter `27464551547`: success.
- Pages deploy `27464583353`: success.
- GitHub Actions reported non-blocking Node 20 deprecation annotations for the
  action stack.

Live docs:

- `https://itchyshin.github.io/HSquared.jl/dev/data.html`: HTTP 200 and
  contains `Annotation Metadata` and `annotation_status`.
- `https://itchyshin.github.io/HSquared.jl/dev/api.html`: HTTP 200 and
  contains `HSAnnotationSpec` and `HSDataAnnotationStatusRow`.

## Public Claim Audit

Allowed wording:

- `HSData` can store annotation metadata;
- `annotation_id` validates annotation feature keys against table-like
  expression feature columns;
- `data_status(::HSData)` reports keyed or unkeyed annotation metadata
  diagnostics.

Blocked wording:

- bridge payload shape changed;
- annotation metadata is joined into fixed-effect design matrices;
- eQTL or omics models are implemented;
- GLLVM workflows are implemented;
- marker/QTL/GWAS workflows are implemented from this slice.

Rose verdict: clean with limitations. This is a metadata-diagnostics parity
slice only.

## Coordination Notes

- Julia lane only. No R repo edits were made.
- The R head `87888d9` is recorded as the source of the annotation-status
  handoff.
- No Julia engine API or bridge payload change is required by the R slice.

## Next Actions

1. Commit and push the remote-evidence update.
2. Watch CI, Documenter, and Pages for the evidence commit.
3. Update the issue ledger.
