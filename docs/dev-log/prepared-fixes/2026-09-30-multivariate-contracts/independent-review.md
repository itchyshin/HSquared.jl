# Independent multivariate contracts review — 2026-09-30

## Verdict

**PASS for the bounded MV01–MV05 repair and scoped MV06 honesty changes at the exact pins below.** This permits the parent to compose/apply the patch and register the test once. It is not a whole multivariate, E1, A2, V3, inference-calibration, campaign, or release approval. No live/proposal source was edited.

## Exact artifact verification

- Candidate HEAD observed: `6271cfd58651e69cd27a64dcf02cb8960a29e260`.
- Original/live multivariate SHA-256: `fc41aefefb61b2cc915d4f802b0017dc4daea5daa795a9d3421854e9c4958670`.
- Prepared final multivariate: `f975657ef43d86045171a9265e5536370043a46fc72880a3e80ee87fcad699c2`.
- Patch: `105dcd37e391d06efbf042bfac85de622a5087af0329e79c8ad462f8f3c73b43`.
- Regression test: `c794be805263c73e4e3d454924dffef3aa1ac3f7bd4abd3b435d95fcb7d42504`.

Verified these files against pins.json, ran git apply --check in owned scratch against the exact original, applied there, and byte-compared replayed source/test with final prepared artifacts. All exact. Source dependencies came from the author's prepared package snapshot; this review approves this multivariate component, not an independently audited whole source tree.

## Fresh evidence

Scratch root: `/private/tmp/e1-multivariate-contracts-independent-20260930/`.

Final-source regression: **107/107 PASS, exit 0**, test-body 8.1 s (`final-107.log`). This is the actual final source after the two docstring edits, not the previous numerical pin.

Independent challenges: **48/48 PASS**, 7.2 s (`independent.log`): multi-factor LL' and LL'+diag(psi), rotation invariance, covariance positive definiteness; analytic mixed quadratic Hessian and linear Jacobian; representable tiny step `1e-150` at zero; no callback for nonfinite/nonperturbable coordinates; independent even-df chi-square exponential/polynomial tails at statistics 0 through 1000; huge negative likelihood-difference tail; invalid degrees; saturated supplied MME beta=Y/EBV=0; preservation of raw valid string/symbol labels; observed-trait rank loss with missing records; zero-iteration rejection.

Selected existing signed neighbors: **4/4** start selection, **12/12** FA overflow/objective exception behavior, **2/2** rank-deficient fixed effects, all exit 0. Only these non-fitting testsets were parsed and evaluated from `test/test_multivariate_fa_multistart.jl`; no full-file/full-suite claim.

Every Julia launch was estimated before launch at less than two minutes (initial cached launches estimated under a minute/few minutes overall), Julia threads=1 and BLAS environment=1. First two launches hit the compiled-cache sandbox restriction before tests. Fresh reruns used `--compiled-modules=no --startup-file=no` and the existing scratch/depot paths, without dependency resolution or update. No statistical optimizer, campaign, GPU, remote compute, or Pkg.test ran. Rank-deficient fit guards reject before optimization.

## Numerical and contract assessment

The Float64 square check is appropriate for the covariance uncertainty route, where both Hessian and Jacobian consume the same step and the Hessian needs h². It intentionally rejects some steps that a standalone internal Jacobian could mathematically use (e.g. h=1e-200 at zero). That is a conservative shared internal helper contract, not evidence that every representable Jacobian step is supported. No public valid uncertainty route is lost by demanding representable h²; a future general differentiation API should separate Hessian/Jacobian step contracts if needed. The accepted `1e-150` control demonstrates that no arbitrary practical cutoff was added.

String normalization uses stripped string views for uniqueness, while returning original values/order. This rejects colliding `1`/`"1"` and whitespace variants; it does not silently rewrite returned identifiers. Valid raw spaced strings and symbol traits survived the supplied solve. Exact trait/animal alignment beyond entry-point labels and synthetic-result authenticity remain caller contracts.

The new MME rank test is mathematically appropriate: with supplied covariance, a full-rank saturated fixed design has a well-defined solve and must remain allowed. The independent saturated solve confirms that. REML needs N-p'>0 and full observed-design rank; the positive df guard correctly rejects saturation. Missing-trait rank loss was tested independently for both REML routes and supplied MME.

Likelihood finite checks handle original and converted values. The positive-infinity statistic tail is the correct limit; negative overflow is clamped to the null-tail 1. Independent df2/4/6 analytic tails and existing FA objective guards passed. The mixture wording preserves legacy tokens while removing the unsupported universal conservativity claim. Convergence refusal gates uncertainty without changing point estimates.

## Unchanged bodies and retained limits

Patch inspection confirms no edits to `_mv_reml_objective`, `_mv_reml_loglik_core` numerical body, `_mv_pe_reml_loglik_core`, optimizer calls/algorithms, FA start generation/selection, absolute uniqueness floor, or fitted covariance parameter maps. Fitter modifications are declared early labels, iteration/residual-df/rank guards, and removal of former late label checks. Exported covariance builders now reject nonfinite reconstruction. The existing objective/start tests above directly challenge the untouched neighboring behavior.

The 200-seed frozen campaign remains historical at its source/driver pins and was not rerun. This source change needs function-level reconciliation in the parent evidence record; constructor/guard correctness does not establish covariance recovery, expected/observed information calibration, loading inference, missingness calibration, ordinary-start robustness, automatic rank, generic result authenticity, performance or GPU.

## Operational notes

Only owned scratch files/report were written. Parent and other lanes remain active. Lane preflight was respected; canonical route manifest and graph context were read. Graph automatic cache write was sandbox-denied; exact proposal/live pins and patch spans decided the conclusions. Brain retrieval returned broad history and was not used as numerical evidence. Graph tool-estimated avoided reading total through this review/next-review context calls: 1,160,273 tokens (not measured model usage).
