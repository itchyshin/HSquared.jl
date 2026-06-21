# 2026-06-21 R Extractor Status Sync

- Goal: mirror the R twin's hsquared PR #85 (`80734b3`), #86 (`5bbc453`), and
  #87 (`6206b7b`) where Julia-owned public-claim and extractor wording had
  drifted after the R scan-result table and issue-status closeouts.
- Starting point:
  - HSquared.jl `main` was clean at `943c790` after PR #147.
  - The R sync reported hsquared `main` at `6206b7b`, with only unrelated
    Codex handover files untracked in the R worktree.
- Files changed:
  - `docs/design/06-public-claims-register.md`
  - `docs/src/genomics-qtl-gpu-hpc.md`
  - `docs/dev-log/coordination-board.md`
  - `docs/dev-log/check-log.d/2026-06-21-r-extractor-status-sync.md`
  - `docs/dev-log/after-task/2026-06-21-r-extractor-status-sync.md`
  - live GitHub issue #48 body (status text only).
- Scope:
  - credited hsquared PR #84 as R-consumed genomic target fixture evidence in
    the public-claims register, while keeping external genomic comparator
    evidence explicitly absent;
  - clarified that current marker/QTL/eQTL table views are scan-result views,
    while fit-level/map-annotated outputs remain planned;
  - recorded the R #83 marker-scan comparator-tool availability blocker in the
    live Julia #48 issue body.
- Checks:
  - `julia --project=. -e 'using HSquared; @assert any(r -> r.id == "V5-MARKER-THRESHOLD" && r.status == "partial", validation_status()); println("status ok")'`:
    passed (`status ok`) after two discarded smoke attempts that used the wrong
    diagnostic field/type.
  - `julia --project=docs docs/make.jl`: passed; existing local warnings
    remained (20 docstrings not in the manual, local deployment skipped, no
    optional Vitepress logo/favicon, and npm audit warnings in the local docs
    toolchain).
  - `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-21-r-extractor-status-sync.md`:
    passed.
  - `git diff --check`: passed.
- Boundary: docs/status/issue sync only. No Julia behavior changed, no R files
  were edited, no external genomic or marker-scan comparator was run, no
  calibrated threshold was activated, no formula-level `marker_scan()` syntax
  was activated, and no validation/public-claim promotion was made.
