# 2026-06-21 R GWAS table sync

- Goal: mirror the R twin's hsquared PR #82 (`934269a`) scan-result table
  surface into Julia-owned status and contract docs without changing engine
  behavior or validation status.
- Starting point:
  - HSquared.jl `main` was clean at `b0d14ba` after the comparator target
    manifest.
  - hsquared `main` was clean at `934269a` after PR #82, with only the two
    unrelated handover files untracked in the R checkout.
- Files changed:
  - `src/validation_status.jl`
  - `docs/src/validation-status.md`
  - `docs/design/03-engine-contract.md`
  - `ROADMAP.md`
  - `test/runtests.jl`
  - `docs/dev-log/coordination-board.md`
  - `docs/dev-log/check-log.d/2026-06-21-r-gwas-table-sync.md`
  - `docs/dev-log/after-task/2026-06-21-r-gwas-table-sync.md`
- Live GitHub action:
  - GitHub app issue update failed with `403 Resource not accessible by integration`.
  - `gh issue edit 45 --repo itchyshin/HSquared.jl --body-file -`: passed.
    The closed #45 body now records the completed Julia payload, R
    `gwas(fit, markers)`, R PR #82 `gwas_table(scan)` / `lod_scores(scan)`,
    and the still-open #48 / map-table / formula-syntax gates.
- Checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'`: passed.
  - `julia --project=docs docs/make.jl`: passed; existing local warnings
    remained (20 docstrings not in the manual, local deployment skipped, no
    optional Vitepress logo/favicon, and npm audit warnings in the local docs
    toolchain).
  - `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-21-r-gwas-table-sync.md`:
    passed.
  - `git diff --check`: passed.
- Boundary: status/contract sync only. No Julia marker-scan behavior changed, no
  R files were edited, no calibrated genome-wide threshold was activated, no
  formula-level `marker_scan()` grammar was added, no fit-level/map-annotated
  QTL/GWAS/eQTL workflow was added, no external comparator evidence was claimed,
  and no validation/public-claim promotion was made.
