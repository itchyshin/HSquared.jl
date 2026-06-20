# CPU engine correctness audit — manual spot-check (2026-06-20)

Author: Ada (Julia lane). Status: **audit note**, no capability claim. Scope: the
CPU numerical engine, in response to the directive *"make sure the CPU stuff is done
properly — accuracy first"* before any GPU work.

## Method + honesty note

A multi-agent fan-out audit (9 subsystems × classify-evidence + adversarial
bug-hunt + verify) was attempted three times and did **not** deliver: two runs hit
API rate/session limits and a third produced no result. This note is therefore the
**reliable fallback**: (1) from-scratch manual re-derivation of the two subtlest
kernels, and (2) a consolidation of the per-kernel evidence-class posture already
recorded in `docs/design/capability-status.md` +
`docs/design/validation-debt-register.md`. It is a spot-check + posture summary, NOT
a comprehensive line-by-line audit of all ~10k LOC.

## Manual kernel re-derivations (from scratch)

### AI-REML average-information + score (`fit_ai_reml`, `src/likelihood.jl`) — CORRECT

Re-derived the two-component REML score and the Gilmour et al. average-information
matrix and matched them against the code:

- Working variates `wa = Zû/σ²a`, `we = ê/σ²e` ARE `(∂V/∂σ²a)·Py` and
  `(∂V/∂σ²e)·Py` (since `û = σ²a·AZᵀPy ⇒ ZAZᵀPy = Zû/σ²a`, and `Py = ê/σ²e`).
- `_reml_project` applies the REML projector `P` via an MME re-solve reusing the
  Cholesky factor (`Pw = (w − Xb_w − Zu_w)/σ²e`). Correct.
- The AI matrix `½·[wₖᵀ P wₗ]` is exactly `½·yᵀP(∂V/∂θₖ)P(∂V/∂θₗ)Py` — the genuine
  average information.
- `score_a`/`score_e` expand to the correct Johnson–Thompson trace identities
  `tr(P·ZAZᵀ) = [q − tr(A⁻¹Cᵘᵘ)/σ²a]/σ²a` and `tr(P) = [n−p−q + tr(A⁻¹Cᵘᵘ)/σ²a]/σ²e`,
  with `yᵀP·ZAZᵀ·Py = ûᵀA⁻¹û/σ²a²` and `yᵀP²y = êᵀê/σ²e²`.

The capability-status "~8% vs finite-difference Hessian" hedge is **not a bug**: it
is the expected gap between the *average information* (the AI Newton metric) and the
*observed-information* FD Hessian; they agree asymptotically, not exactly at finite
n. The code computes the right quantity.

### Laplace marginal (`laplace_marginal_loglik`, `src/nongaussian.jl`) — CORRECT

Standard penalized-IRLS mode-finding on `[β; u]` (Newton with the GLM weight
matrix + the `Ainv/σ²a` penalty block), then the Laplace marginal
`cond − ½·uᵀAinv u/σ²a − ½·q·log σ²a + ½·logdet(Ainv) + ½·p·log(2π) − ½·logdet(H)`.
The `+½·p·log(2π)` term correctly accounts for the flat-β integration; the Gaussian
family reduces EXACTLY to `sparse_reml_loglik` (tested). Correct.

## Evidence-class posture (consolidated)

The engine's internal validation is genuinely strong — most load-bearing kernels are
pinned by **independent in-repo oracles or limiting-case reductions**, not mere
self-consistency:

- **Independent oracle:** `multivariate_mme` (loop-built MME + marginal-GLS BLUP, 1e-10),
  `random_regression_mme` (dense marginal-GLS oracle, 1e-8), `henderson_mme` (shared
  R/Julia fixture), `takahashi_selinv` (== dense MME inverse diagonal to machine
  precision), `solve_animal_model_pcg` (== direct `henderson_mme`).
- **Reduction identity:** `fit_ai_reml`/`fit_sparse_reml` (cross-method agreement +
  AI-vs-FD-Hessian), `fit_multivariate_reml` (t=1 → univariate REML loglik exactly),
  `fit_random_regression_reml` (degree-0 → univariate), the non-Gaussian Laplace/VA
  (Gaussian-limit → `sparse_reml_loglik`; Bernoulli/Binomial → Gauss–Hermite bound).
- **Hand-checked fixtures:** pedigree `Ainv`/relationship matrices, Mendelian
  sampling variances, dominance/epistasis/cytoplasmic/clonal/metafounder relationships.

## Honest conclusion

- **Numerical correctness:** the CPU engine computes the right quantities for its
  inputs — the riskiest kernels were independently re-derived (above) and the rest
  carry independent-oracle/reduction evidence. No correctness bug was found in this
  spot-check.
- **The real remaining gap is EXTERNAL-comparator parity** (ASReml / sommer /
  BLUPF90 / JWAS / fitted-Mrode), which is what separates the `partial`/`experimental`
  rows from `covered`. That work is **cross-lane (needs the R lane)**, not solo
  engine work — see the `V*` rows' "still needs" columns. No solo manual audit can
  close it.
- **Therefore "done properly" on the CPU side is, for solo engine work, largely
  reached**: internally validated and honestly status-flagged. The promotion to
  `covered` is gated on the R-lane comparator runs, not on more engine code.
- GPU work remains correctly parked until a recorded CPU benchmark exists (no
  performance claim without evidence).

## Caveat

This is a spot-check, not exhaustive. A future comprehensive pass (when API limits
allow the multi-agent fan-out, or via incremental manual subsystem reviews) should
cover the remaining kernels line-by-line; this note records what was actually
verified, not more.
