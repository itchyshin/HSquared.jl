# Check log — 2026-09-07 release-record cleanup (Julia)

- Scope: paired documentation records only. No Julia source, public API,
  version, capability-status cell, test fixture, fit, release, tag, or
  deployment was changed or run.
- `git diff --check`: **PASS**.
- `julia --project=docs docs/make.jl`: **PASS**. Documenter completed its
  document checks and Vitepress render. It retained the existing warning that
  42 checked docstrings are not included in the manual and skipped deployment
  because no CI environment was detected; neither warning is introduced by
  this record cleanup.
- Manual source reconciliation: **PASS**. The capability ledger records the
  2026-09-01 S5 tail-scale PASS at frozen scope while `V1-MATFREE-REML` remains
  experimental/partial and promotion-held.
- Public evidence pins recorded in the paired decision: Julia head
  `a1c2401e194dba4f2fdffd580ccbc061b1c0df5a` with CI runs 34152604486 and
  34152548409; R head `4b7bfefa0ddb7003d4f3e8dc7bbb5b9bb83355c6` with CI runs
  34153464768 and 34153676260. These are cited as prior public evidence, not
  rerun by this cleanup.
