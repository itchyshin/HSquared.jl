# R Genomic Comparator Sync

## Task Goal

Record the R twin's hsquared PR #83 (`1c239ec`) and PR #84 (`52507da`) in
Julia-owned comparator/status ledgers. The genomic GBLUP/SNP-BLUP target is now
R-consumed internal route evidence; the marker-scan comparator-tool report is
blocker evidence only.

## Active Lenses

- Ada + Shannon: cross-lane sequencing and lane boundary.
- Curie + Fisher: validation target and comparator semantics.
- Jason: external-tool availability / scout framing.
- Hopper + Emmy: bridge/consumer-surface language.
- Grace: manifest and docs checks.
- Rose: claim-vs-evidence boundary.

Spawned agents: none.

## Files Changed

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

## Checks Run

- `julia --project=. -e 'using TOML; d = TOML.parsefile("test/fixtures/comparator_targets.toml"); @assert any(t -> t["id"] == "genomic_gblup_snpblup_target" && t["evidence_type"] == "julia_target_r_consumed", d["target"]); println("manifest ok")'`
  - Passed (`manifest ok`).
- `julia --project=. -e 'using Pkg; Pkg.test()'`
  - Passed.
- `julia --project=docs docs/make.jl`
  - Passed; existing local warnings remained (20 docstrings not in the manual,
    local deployment skipped, no optional Vitepress logo/favicon, and npm audit
    warnings in the local docs toolchain).
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-21-r-genomic-comparator-sync.md`
  - Passed.
- `git diff --check`
  - Passed.

## Public Claim Audit

Clean with explicit limits. hsquared PR #84 proves that the R lane can consume
the Julia genomic target fixture and independently recompute the internal route
identities without live Julia. That is stronger bridge/fixture evidence, but it
is still not an external comparator.

hsquared PR #83 is a blocker report: the local environment lacks the marker-scan
comparator/threshold tools needed for a PLINK/GenABEL/qvalue-style evidence leg.
It does not advance threshold calibration.

## Tests Of The Tests

The manifest regression now requires `genomic_gblup_snpblup_target` to be
classified as `julia_target_r_consumed`, checks that its status mentions PR #84,
and keeps the boundary text tied to an internal consumer check. The marker-scan
target also asserts that PR #83 is recorded as tool-availability blocker
evidence.

## Coordination Notes

No `hsquared` files were edited. This branch only mirrors the R lane's new
evidence/blocker state into Julia-owned docs and the comparator manifest.

## What Did Not Go Smoothly

The first manifest edit briefly left duplicate `evidence_type` keys; it was
caught by inspection before checks and removed.

## Known Limitations

- No AGHmatrix, rrBLUP, sommer, JWAS, BLUPF90, PLINK, GenABEL, qvalue, GEMMA,
  GCTA, BOLT-LMM, or SAIGE comparator run is claimed.
- No calibrated genome-wide threshold is activated.
- No public R genomic model-spec or formula-level marker-scan syntax is
  activated.
- No validation row is promoted to covered.

## Next Actions

- Keep #49 focused on executable-backed same-estimand comparator evidence.
- Keep #48 focused on realistic-LD/design threshold calibration plus accepted
  external/canonical marker-scan comparator evidence before any public
  significance wording.
