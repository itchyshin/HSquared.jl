# 2026-06-21 R Genomic Comparator Sync

- Goal: mirror the R twin's hsquared PR #83 (`1c239ec`) and PR #84 (`52507da`)
  into Julia-owned comparator/status ledgers without changing engine behavior or
  validation status.
- Starting point:
  - HSquared.jl `main` was clean at `a350225` after PR #146.
  - R sync reported hsquared `main` clean at `52507da`, with only the two
    unrelated Codex handover files untracked.
- Files changed:
  - `test/fixtures/comparator_targets.toml`
  - `test/runtests.jl`
  - `src/validation_status.jl`
  - `docs/src/validation-status.md`
  - `docs/design/capability-status.md`
  - `docs/design/validation-debt-register.md`
  - `docs/src/genomic-models.md`
  - `docs/src/genomics-qtl-gpu-hpc.md`
  - `comparator/README.md`
  - `ROADMAP.md`
  - `docs/dev-log/coordination-board.md`
  - `docs/dev-log/check-log.d/2026-06-21-r-genomic-comparator-sync.md`
  - `docs/dev-log/after-task/2026-06-21-r-genomic-comparator-sync.md`
- Scope:
  - changed the `genomic_gblup_snpblup_target` manifest entry from
    `julia_target` to `julia_target_r_consumed`;
  - recorded hsquared PR #84 as a Julia-free R consumer check for supplied-
    frequency VanRaden `G`, `Ginv`, supplied-variance GBLUP MME, and SNP-BLUP
    route agreement;
  - recorded hsquared PR #83 as marker-scan comparator/threshold-tool blocker
    evidence only.
- Checks:
  - `julia --project=. -e 'using TOML; d = TOML.parsefile("test/fixtures/comparator_targets.toml"); @assert any(t -> t["id"] == "genomic_gblup_snpblup_target" && t["evidence_type"] == "julia_target_r_consumed", d["target"]); println("manifest ok")'`:
    passed (`manifest ok`).
  - `julia --project=. -e 'using Pkg; Pkg.test()'`: passed.
  - `julia --project=docs docs/make.jl`: passed; existing local warnings
    remained (20 docstrings not in the manual, local deployment skipped, no
    optional Vitepress logo/favicon, and npm audit warnings in the local docs
    toolchain).
  - `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-21-r-genomic-comparator-sync.md`:
    passed.
  - `git diff --check`: passed.
- Boundary: status/docs/manifest/test sync only. No Julia behavior changed, no R
  files were edited, no AGHmatrix/rrBLUP/sommer/JWAS/BLUPF90 or marker-scan
  external comparator was run, no calibrated threshold was activated, no public
  R genomic model-spec or formula-level marker-scan syntax was activated, and no
  validation/public-claim promotion was made.
