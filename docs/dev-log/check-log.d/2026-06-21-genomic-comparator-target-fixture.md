# 2026-06-21 Genomic GBLUP/SNP-BLUP Comparator Target Fixture

- Goal: advance #49 from the Julia side by serializing a deterministic
  GBLUP/SNP-BLUP comparator target that the R lane or an external package can
  consume later.
- Active lenses: Ada, Shannon, Hopper, Boole, Emmy, Gauss, Fisher, Curie,
  Jason, Grace, Rose.
- Spawned subagents: none.
- Starting point:
  - Julia `main` at `934a91e` after #139 merged.
  - R sync received during the slice: `hsquared` PRs #62-#66 are merged and R
    main is refreshed to `670931f`; R is waiting for the #49 comparator handoff.
- Implementation evidence:
  - Added `test/fixtures/genomic_gblup_snpblup_target/`.
  - The fixture serializes phenotype IDs/responses, marker dosages, supplied
    allele frequencies, a positive-definite VanRaden method-1 `G`, `Ginv`,
    beta, GBLUP GEBVs, SNP-BLUP marker effects/GEBVs, metadata, README, and
    a no-RNG generator.
  - Added testset `Phase 2 genomic GBLUP/SNP-BLUP target fixture (#49)`:
    22 assertions read the CSVs, recompute `G`, `Ginv`, `fit_gblup`, and
    `fit_snp_blup`, pin route agreement (`max diff ~= 1.11e-15`), and reject
    a perturbed GEBV.
  - Updated `validation_status()` and status tests so `V2-GBLUP` and
    `V2-SNPBLUP` record the serialized Julia target while keeping external
    comparator parity in the missing column.
  - Updated roadmap, validation canon, bridge compatibility matrix,
    public-claims register, capability status, validation-debt register,
    Documenter pages, changelog, and coordination board.
- Commands run:
  - `julia --project=. test/fixtures/genomic_gblup_snpblup_target/generate.jl`
    — passed; regenerated the committed CSVs.
  - `julia --project=. -e 'using Pkg; Pkg.test()'` — passed. The new #49
    testset passed 22/22 inside the full suite.
  - `julia --project=docs docs/make.jl` — passed with existing local warnings
    for omitted internal docstrings, skipped deployment detection, substituted
    Vitepress defaults, missing logo/favicon, and npm audit output.
  - `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-21-genomic-comparator-target-fixture.md`
    — passed.
  - `git diff --check` — passed.
- Boundary:
  - Julia-native comparator target only.
  - Not an AGHmatrix/sommer/BLUPF90/JWAS external comparator run.
  - Not public R genomic model-spec activation.
  - Not sparse/APY scaling.
  - Not weighted, standardized, Bayesian, or low-rank marker-prior support.
  - Not a covered-status promotion.
  - No R files touched.
- Rose verdict: clean with limitations. This is a useful handoff artifact for
  the R/external-comparator lane, not validation parity by itself.
