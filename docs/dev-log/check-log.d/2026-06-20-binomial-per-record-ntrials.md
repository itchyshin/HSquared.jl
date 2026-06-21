# 2026-06-20 Binomial per-record n_trials (the general cbind GLMM, #61)

- **Goal:** generalize the non-Gaussian Binomial family from a single COMMON
  `n_trials` scalar to a PER-RECORD `n_trials[i]` — the general
  `cbind(successes, failures)` GLMM the R lane flagged on #61 as the planned next
  bridge slice. Accuracy/capability, pure engine numerics; no speed/GPU.
- **Active lenses:** Gauss (numerics) + Noether (math-consistency) + Curie
  (edge-cases) + Rose (claims) — run as an actual adversarial-verification Workflow.
- **What landed (`src/nongaussian.jl`, all internal):**
  - `BinomialVectorResponse(n_trials::Vector{Int})` (non-empty, all ≥ 1; defensive copy).
  - `_fam_record(f, i)`: identity (`@inline`) for every scalar family — zero behavior
    change on existing paths — and a per-record scalar `BinomialResponse(n_trials[i])`
    for the vector case (a bitstype, so allocation-free). Threaded into **all 10**
    per-record kernel call sites in BOTH the Laplace and VA paths.
  - `_check_counts(::BinomialVectorResponse, y)`: `length(n_trials) == length(y)` AND
    `0 ≤ y[i] ≤ n_trials[i]`.
  - `fit_laplace_reml`: `n_trials` may be scalar OR vector (length + integer-valued
    checks); integer-valued reals accepted (R marshals doubles) with a clean
    `ArgumentError` on genuinely non-integer entries; `NonGaussianFit.n_trials`
    widened to `Union{Int,Vector{Int},Nothing}`; `nongaussian_result_payload` copies
    the vector. Docstrings updated (file header, `BinomialResponse` sibling,
    `fit_laplace_reml`, `NonGaussianFit`, payload).
- **TDD (`test/runtests.jl`, new testset "Phase 6 Binomial per-record n_trials
  (cbind GLMM)", 39 assertions, GREEN):**
  - `_fam_record` resolution (scalar families identity; vector → scalar view per i);
  - REDUCTION 1: `fill(m,n)` vector == scalar `BinomialResponse(m)` to ~1e-12
    (Laplace loglik/β/u AND VA ELBO) and the fitted path to 1e-6;
  - REDUCTION 2: all-ones vector == `BernoulliResponse` (logbinom(1,y)=0);
  - heterogeneous `n_trials` finite/converged and DISTINCT from `BR(10)`/`BR(15)` fits;
  - score/weight == central finite-difference of the loglik at a heterogeneous record;
  - β-fixed value gate vs an INDEPENDENT per-record tensor Gauss–Hermite oracle
    (Laplace |Δ|<0.2, VA ELBO ≤ truth);
  - `_check_counts` (length mismatch / `y[i] > n_trials[i]`) + constructor guards
    (empty / zero / negative);
  - bridge realism: integer-valued `Float64` vector accepted (== Int vector, fit to
    1e-8); genuinely non-integer vector → `ArgumentError`.
- **Recovery (opt-in, `sim/phase6_binomial_recovery.jl`, outside CI):** added a
  per-record scenario `nₐ ~ Uniform{1..30}` (MIXES binary Bernoulli with multi-trial
  Binomial records, q=345 half-sib, truth σ²a=1.0): **5/5 PASS, max rel 0.062, EBV
  cor 0.85–0.89** (gate rel ≤ 0.30, cor ≥ 0.80). The common-m=20 scenario is
  unchanged (5/5, rel ≤ 0.175).
- **Adversarial verification (Workflow `verify-per-record-ntrials`, 5 agents):**
  Gauss/Noether/Curie reviewed the diff from distinct lenses → 4 findings (1
  material) → the material finding adversarially verified as real → Rose gate.
  Verdict: **the CODE is correct, narrow, well-tested; NO code defect, NO overclaim**
  (the verifier independently re-ran `Pkg.test()` green and confirmed the GH oracle is
  genuine). The ONE blocker was a stale-NEGATIVE claim (the registers still said "no
  varying per-record n_trials") — the honest-status doctrine cuts both ways. Both
  registers fixed; the Curie LOW (float-vector error message) and NIT (mixed-regime
  recovery) were also addressed (the bridge-double acceptance + the `1:30` range).
- **Checks:** `Pkg.test()` GREEN (39 new + existing 31 binomial unchanged + full
  suite); `docs/make.jl` GREEN; `validation_status()` UNCHANGED (41 rows — no new
  statistical claim promoted; the Binomial family already had `V6-BINOMIAL`). Rose
  sweep: the stale clause existed in exactly the two registers (both fixed); the two
  remaining hits are dated historical after-task "Next" lists (this slice addresses
  them) + a gitignored `docs/build` artifact that regenerates.
- **Honest status:** EXPERIMENTAL, dense/validation-scale, no intervals, no external
  comparator, no R model-spec. Nothing promoted to `covered`.
