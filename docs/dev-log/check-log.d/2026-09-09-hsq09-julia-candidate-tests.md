# HSquared 0.9 candidate — fresh ordinary Julia test receipt

- **Candidate:** `codex/hsq09-h3-prerun-20260909` at
  `989948daf66d126dee0e27ebd7eb02a2e57a72f3`; clean before and after the run.
- **Command:**
  ```sh
  JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
    /Users/z3437171/.juliaup/bin/julia --project=. \
    -e 'using Pkg; Pkg.test()'
  ```
- **Result:** exit success.  All printed testsets passed, including Aqua,
  Phase 0 scaffold (413/413), recovery-log and debt tools, NB2 (20/20),
  beta-binomial (85/85), Bernoulli-probit (66/66), non-Gaussian interval
  cross-family contract (14/14), and latent/observation-scale checks.
- **Environment note:** the first sandboxed attempt could not create Julia's
  `~/.julia/logs/manifest_usage.toml.pid` usage lock (EPERM) and did not enter
  the tests.  The retained result above is the subsequently authorized normal
  run, which passed.
- **Scope fence:** this is ordinary package-test evidence only.  It does not
  provide interval formation, calibration, S11, promotion, R-package, CI, or
  release evidence; in particular it does not override the retained H3 S10
  no-go.
