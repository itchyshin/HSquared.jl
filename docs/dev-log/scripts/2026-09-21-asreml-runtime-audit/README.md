# 2026-09-21 — ASReml-vs-HSquared.jl runtime audit harness

The scripts behind `docs/dev-log/after-task/2026-09-21-asreml-runtime-audit.md`.
They are committed because the 2026-09-21 post-fit arc's reconstruction scripts
were **not**, and its numbers therefore cannot be re-run by anyone else.

**Development evidence only.** ASReml is a commercial, licence-gated engine and is
**forbidden as a covered comparator leg** (`docs/design/52-v07-exact-G-comparator-recipe.md:21`).
Nothing these scripts produce is a validation claim or moves a capability row.
They will not run in CI, and are not wired into it.

## Data

Not in this repo. Both CSVs live in the R twin at `hsquared/dev-test/`:
`great_tit_breeding_data.csv`, `great_tit_pedigree.csv`. Real study data; do not copy it here.

## Run order

```sh
export AUDIT_DIR=/some/scratch   TWIN_DIR=/path/to/hsquared
export JL_DIR="$PWD"

Rscript 00-prep.R          # prepPed + ainverse (full AND pruned) -> prepared.rds
Rscript 01-asreml.R        # ASReml arm, both pedigrees, 3 reps
Rscript 05c.R              # prepPed / ainverse construction cost
Rscript 06-asreml-decomp.R # ASReml setup vs per-iteration (maxit sweep)
Rscript 09-se-cost.R       # cost of ASReml's SEs (AI matrix, already built)
Rscript 03-export.R        # y / X / pedigree -> CSV for the Julia arm
julia --project=. 04-profile.jl    # engine stage profile
julia --project=. 11-iter-split.jl # inside ONE AI-REML iteration
julia --project=. 12-tol.jl        # tol x initial sweep
Rscript 08-bridge-split.R  # JuliaCall stage split incl. marshalling
```

## Two traps these scripts exist to document

- **Cold-call timings are JIT, not work.** `04-profile.jl` times the pedigree path on its
  FIRST call and reports 0.370 s; `07`/`11` time it warm and get 0.012 s. Anything timed once
  in Julia is a compile-time measurement. Every number in the report is best-of-3 or better.
- **R's lazy evaluation silently fakes a fast result.** `min(replicate(n, system.time(e)))`
  forces the promise `e` once and reuses the value, so reps 2..n cost nothing and the minimum
  is 0.000 s. Pass a *function* and call it (`sapply(seq_len(n), function(i) ... f() ...)`).
