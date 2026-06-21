# R Extractor Status Sync

## Task Goal

Mirror the R twin's latest status-only closeouts (hsquared PR #85, #86, and
#87) into the small Julia-owned places that still had stale public-claim or
extractor wording.

## Active Lenses

- Ada + Shannon: cross-lane sequencing and lane boundary.
- Hopper + Emmy: extractor and bridge-surface wording.
- Jason + Fisher: comparator and threshold blocker semantics.
- Grace: docs checks.
- Rose: claim-vs-evidence boundary.

Spawned agents: none.

## Files Changed

- `docs/design/06-public-claims-register.md`
- `docs/src/genomics-qtl-gpu-hpc.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.d/2026-06-21-r-extractor-status-sync.md`
- `docs/dev-log/after-task/2026-06-21-r-extractor-status-sync.md`
- live GitHub issue #48 body (status text only).

## Checks Run

- `julia --project=. -e 'using HSquared; @assert any(r -> r.id == "V5-MARKER-THRESHOLD" && r.status == "partial", validation_status()); println("status ok")'`
  - Passed (`status ok`) after two discarded smoke attempts that used the wrong
    diagnostic field/type.
- `julia --project=docs docs/make.jl`
  - Passed; existing local warnings remained (20 docstrings not in the manual,
    local deployment skipped, no optional Vitepress logo/favicon, and npm audit
    warnings in the local docs toolchain).
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-21-r-extractor-status-sync.md`
  - Passed.
- `git diff --check`
  - Passed.

## Public Claim Audit

Clean with explicit limits. The genomic GBLUP/SNP-BLUP fixture is now described
as a Julia-native/R-consumed target because hsquared PR #84 mirrors and
recomputes it without live Julia. It is still not external comparator evidence.

The extractor wording now separates banked scan-result views from planned
fit-level/map-annotated GWAS/QTL/eQTL outputs, matching the R #87 boundary.

## Tests Of The Tests

No code or test fixture changed. The check for this slice is documentation
rendering plus the after-task validator and whitespace check; the behavioral
test suite was already exercised in the immediately preceding status/manifest
sync PR.

## Coordination Notes

No `hsquared` files were edited. The R worktree had its own active branch and
unrelated untracked handover files, so this slice stayed entirely in
`HSquared.jl`.

## What Did Not Go Smoothly

Nothing material. Two first-pass smoke commands failed because I guessed the
diagnostic row field/type (`validation_id` / symbol status) instead of using the
actual exported `id` and string `status` fields; the corrected smoke passed. The
only content subtlety was avoiding a Julia claim for an R-only `lod_scores(scan)`
S3 view; the design note now labels it as an R scan-result view.

## Known Limitations

- No AGHmatrix, rrBLUP, sommer, JWAS, BGLR, BLUPF90, PLINK, GenABEL, qvalue,
  GEMMA, GCTA, BOLT-LMM, or SAIGE comparator run is claimed.
- No calibrated genome-wide threshold is activated.
- No formula-level `marker_scan()` syntax or map-annotated fit-level
  GWAS/QTL/eQTL table workflow is activated.
- No validation row is promoted to covered.

## Next Actions

- Keep #48 focused on realistic-LD/design threshold calibration and accepted
  external/canonical marker-scan comparator evidence before public significance
  wording.
- Keep #49 focused on executable-backed same-estimand comparator evidence for
  genomic and multivariate targets.
