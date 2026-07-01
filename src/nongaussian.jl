# Phase 6 foundation: Laplace-approximate marginal log-likelihood for the
# non-Gaussian animal model. EXPERIMENTAL, dense / validation-scale.
#
# Model:  η = Xβ + Zu,  u ~ N(0, A·σ²a)  with supplied A⁻¹ = `Ainv`; the response
# is conditionally exponential-family given η (a `ResponseFamily`). The
# marginal integrates out the joint mode [β (flat prior); u] by Laplace's method
# (penalized IRLS / Newton on the joint objective, then a Gaussian integral at
# the mode). β is integrated (flat prior), so for a Gaussian family this is the
# REML-type marginal and reduces EXACTLY to `sparse_reml_loglik`.
#
# This is the `:LA` marginal; the `:VA` (variational) marginal reuses the
# per-family kernels here (architecture adapted from the MIT DRM.jl
# `src/variational.jl` :LA/:VA dispatch). Families currently: Gaussian (identity
# link, exact), Poisson (log link, closed-form VA via the log-normal MGF),
# Bernoulli (logit link; the VA expected kernels use Gauss–Hermite quadrature
# because the logistic log-partition has no closed-form Gaussian expectation),
# and Binomial (logit link, `n_trials` successes — a common scalar denominator or a
# per-record vector; Bernoulli is `n_trials = 1`).
#
# The fitters `fit_laplace_reml` / `laplace_reml_interval` are exported
# (experimental); the marginal-loglik kernels and `ResponseFamily` types stay
# internal. Not wired into the R formula `fit_*` path; no R model-spec.
# Validation: Gaussian reduces to `sparse_reml_loglik` to machine
# precision; the Poisson mode solves the penalized score equation (∇ = 0); the
# per-family score/weight match finite differences of the conditional loglik.

abstract type ResponseFamily end

"""Gaussian family with identity link and residual variance `sigma_e2`."""
struct GaussianResponse <: ResponseFamily
    sigma_e2::Float64
    function GaussianResponse(sigma_e2::Real)
        sigma_e2 > 0 || throw(ArgumentError("sigma_e2 must be positive"))
        return new(Float64(sigma_e2))
    end
end

"""Poisson family with log link (`μ = exp(η)`)."""
struct PoissonResponse <: ResponseFamily end

"""Bernoulli family with logit link (`p = logistic(η)`) for binary 0/1 traits."""
struct BernoulliResponse <: ResponseFamily end

"""
Binomial family with logit link for counts of successes out of a common number of
trials `n_trials` (`y ∈ 0:n_trials`, `p = logistic(η)`). Generalises
`BernoulliResponse` (= `n_trials = 1`); more trials per record make the data more
informative, so the Laplace variance bias shrinks.
"""
struct BinomialResponse <: ResponseFamily
    n_trials::Int
    function BinomialResponse(n_trials::Integer)
        n_trials >= 1 || throw(ArgumentError("n_trials must be >= 1"))
        return new(Int(n_trials))
    end
end

"""
Binomial family with logit link and a PER-RECORD number of trials `n_trials[i]`
(`y[i] ∈ 0:n_trials[i]`). The general `cbind(successes, failures)` GLMM where the
trial denominator varies by observation; `BinomialResponse(m::Int)` is the common-
denominator special case. Internal: the fitter / bridge accept a scalar or vector
`n_trials` and construct the right type. The per-record kernels are resolved to the
matching scalar `BinomialResponse(n_trials[i])` via `_fam_record`, so the family
math is shared and the scalar path is untouched.
"""
struct BinomialVectorResponse <: ResponseFamily
    n_trials::Vector{Int}
    function BinomialVectorResponse(n_trials::AbstractVector{<:Integer})
        isempty(n_trials) && throw(ArgumentError("n_trials must be non-empty"))
        all(n -> n >= 1, n_trials) || throw(ArgumentError("every n_trials[i] must be >= 1"))
        return new(Vector{Int}(n_trials))
    end
end

"""
Negative-binomial family (NB2) with log link (`μ = exp(η)`) and overdispersion /
size parameter `theta > 0`: `Var(y|μ) = μ + μ²/theta`. As `theta → ∞` the family
→ Poisson. `theta` is an EXTRA estimable scalar (unlike the single-parameter
Poisson/Bernoulli/Binomial), so `fit_laplace_reml` profiles it jointly with
`sigma_a2`. Laplace-only at this slice (the NB variational ELBO has no closed form).
"""
struct NegativeBinomialResponse <: ResponseFamily
    theta::Float64
    function NegativeBinomialResponse(theta::Real)
        theta > 0 || throw(ArgumentError("theta (overdispersion) must be positive"))
        return new(Float64(theta))
    end
end

"""
Beta-binomial family (logit link): `y` successes out of `n_trials`, with the success
probability itself Beta-distributed across records to capture OVERdispersion relative
to the Binomial. Parameterised by the mean `p = logistic(η)` and an overdispersion
parameter `ρ ∈ (0,1)` (intra-class correlation; `ρ → 0` is the Binomial limit). The
conditional log-density marginalises the Beta latent in closed form:

    ℓ(y|η,ρ) = lbeta(α+y, β+n−y) − lbeta(α,β) + log C(n,y),

with `α = p(1−ρ)/ρ`, `β = (1−p)(1−ρ)/ρ` (so `α + β = (1−ρ)/ρ` is constant in η).
`n_trials` is a common scalar denominator (the per-record vector form is future work,
mirroring `BinomialVectorResponse`). `ρ` is a FIXED field — supplied/estimated outside
the per-η kernel, not per-record. Unlike the logit Binomial, the beta-binomial is NOT
log-concave in η, so the IRLS working weight uses the Fisher (expected) information
(see `_fam_weight`); the conditional kernel reuses the module's existing `_loggamma`.
"""
struct BetaBinomialResponse <: ResponseFamily
    n_trials::Int
    rho::Float64           # overdispersion ρ ∈ (0,1)
    function BetaBinomialResponse(n_trials::Integer, rho::Real)
        n_trials >= 1 || throw(ArgumentError("n_trials must be >= 1"))
        (0 < rho < 1) || throw(ArgumentError("rho (overdispersion) must be in (0,1)"))
        return new(Int(n_trials), Float64(rho))
    end
end

"""
Bernoulli family with a PROBIT link (`P(y=1|η) = Φ(η)`, the standard-normal CDF) for
binary 0/1 traits — the threshold / liability-scale animal model: an unobserved
liability `ℓ = η + e`, `e ~ N(0,1)`, is observed as `y = 1[ℓ > 0]`. With the sign
trick `s = 2y−1`, `P(y|η) = Φ(sη)`. The conditional is LOG-CONCAVE in η, so the IRLS
working weight `M(sη)·(M(sη)+sη) ∈ (0,1)` (the inverse-Mills form) is strictly
positive and the observed and expected information coincide (unlike beta-binomial).
Latent/liability scale: no observation-scale h² is surfaced here (that is the
Nakagawa–Schielzeth transform, a separate slice). Internal, Laplace-only.
"""
struct BernoulliProbitResponse <: ResponseFamily end

"""
Ordered-categorical probit (ordinal threshold / graded liability) — the T1
calving-ease family (v0.6). `K` ordered categories `1..K` sit on a standard-normal
latent scale with `K-1` SUPPLIED, strictly increasing cutpoints `θ`: with the
latent liability `l = η + e`, `e ~ N(0,1)`,

    P(y = k | η) = Φ(θ_k − η) − Φ(θ_{k-1} − η),   θ_0 = −∞, θ_K = +∞.

The binary `K = 2` case with `θ = [0]` reduces EXACTLY to `BernoulliProbitResponse`
(category 2 ↔ y = 1). EXPERIMENTAL, internal, Laplace-only, and SUPPLIED thresholds
only — JOINT cutpoint estimation is a follow-up (like the beta-binomial dispersion).
The conditional `ℓ = log P(y|η)` is LOG-CONCAVE in η (log of a Gaussian interval
probability), so the working weight is the OBSERVED information `−d²ℓ/dη² = score² −
(a·φ(a) − b·φ(b))/P`, which is `> 0` and equals the binary probit's observed weight at
`K = 2` — no Fisher-scoring substitution is needed (contrast the beta-binomial, which
is not log-concave in η).
Numerically moderate-range: the category probabilities use a tail-aware interval
form, but a category whose probability underflows in the deep latent tail is a
documented follow-up (a log-space `logsubexp` loglik).
"""
struct OrderedProbitResponse <: ResponseFamily
    thresholds::Vector{Float64}
    function OrderedProbitResponse(thresholds::AbstractVector{<:Real})
        length(thresholds) >= 1 ||
            throw(ArgumentError("OrderedProbitResponse needs >= 1 threshold (K >= 2 categories)"))
        all(i -> thresholds[i] < thresholds[i + 1], 1:(length(thresholds) - 1)) ||
            throw(ArgumentError("OrderedProbitResponse thresholds must be strictly increasing"))
        return new(Float64.(thresholds))
    end
end

"""
Gamma (log-link) family for a strictly-positive continuous response — a v0.6 plan
family (e.g. milk yield, longevity). Mean `μ = exp(η)`, SUPPLIED shape `ν > 0`:
`y | η ~ Gamma(shape ν, mean μ)`, density `(ν/μ)^ν y^{ν-1} e^{-νy/μ} / Γ(ν)`, `y > 0`.
The conditional `ℓ = ν(log ν − η) + (ν−1)log y − ν y e^{-η} − log Γ(ν)` is LOG-CONCAVE
in η, so the score `ν(y e^{-η} − 1)` and the OBSERVED-information weight `ν y e^{-η}`
are exact and `> 0` (no Fisher-scoring substitution; same convention as Poisson/probit).
At `ν = 1` the family reduces to the EXPONENTIAL. EXPERIMENTAL, internal, Laplace-only,
SUPPLIED shape (joint shape estimation is a follow-up, like the beta-binomial dispersion).
"""
struct GammaResponse <: ResponseFamily
    shape::Float64
    function GammaResponse(shape::Real)
        shape > 0 || throw(ArgumentError("GammaResponse shape must be positive, got $shape"))
        return new(Float64(shape))
    end
end

# Per-record family resolution. For every family without per-record state this is
# the identity (compiles away; zero overhead in the per-observation comprehensions).
# For the per-record Binomial it returns the SCALAR `BinomialResponse` for record
# `i` — a bitstype (one `Int` field), so this is allocation-free, and it reuses the
# existing scalar Binomial kernels unchanged.
@inline _fam_record(f::ResponseFamily, ::Integer) = f
@inline _fam_record(f::BinomialVectorResponse, i::Integer) = BinomialResponse(f.n_trials[i])

# Resolve a single-variance-component family (:poisson / :bernoulli / :binomial /
# :beta_binomial) and its `n_trials` (scalar OR per-record vector; integer-valued reals
# already validated by the caller) to the `ResponseFamily` object the kernels consume.
# Shared by `fit_laplace_reml` and `laplace_reml_interval` so the two never drift.
# `:beta_binomial` additionally takes the FIXED overdispersion `rho` (its second
# parameter); σ²a is profiled at that supplied ρ. Only `fit_laplace_reml` passes
# `rho` — `laplace_reml_interval` rejects `:beta_binomial` in its own family guard
# before this call, so its `rho = nothing` default is never exercised for it.
function _resolve_single_family(family::Symbol, n_trials; rho = nothing)
    family === :poisson && return PoissonResponse()
    family === :bernoulli && return BernoulliResponse()
    family === :bernoulli_probit && return BernoulliProbitResponse()
    if family === :binomial
        n_trials isa AbstractVector && return BinomialVectorResponse(Int.(n_trials))
        # scalar: accept an integer-valued real (the R bridge marshals doubles) with a
        # clean error on a genuinely non-integer count, mirroring the vector contract.
        (n_trials isa Real && isinteger(n_trials)) ||
            throw(ArgumentError("n_trials must be an integer trial count (or a per-record integer vector)"))
        return BinomialResponse(Int(n_trials))
    end
    if family === :beta_binomial
        rho === nothing &&
            throw(ArgumentError("family = :beta_binomial requires the rho keyword"))
        # scalar common denominator only at this slice (per-record is future work)
        (n_trials isa Real && isinteger(n_trials)) ||
            throw(ArgumentError("beta_binomial n_trials must be a scalar integer trial count"))
        return BetaBinomialResponse(Int(n_trials), Float64(rho))
    end
    throw(ArgumentError("unsupported single-component family :$family"))
end

# Marginal-method dispatch (architecture mirrors the MIT DRM.jl :LA/:VA idea).
# The engine keeps the `marginal::Symbol` keyword/field (:laplace / :variational);
# this dispatch type is the canonical mapping the bridge payload uses to emit the
# R-facing method name ("laplace" / "va"), and it also accepts the DRM-style
# :LA / :VA spellings. Value-preserving: it does NOT change fit_laplace_reml
# numerics or the stored NonGaussianFit.marginal symbol.
abstract type MarginalMethod end
struct Laplace <: MarginalMethod end
struct Variational <: MarginalMethod end

_marginal_method(m::MarginalMethod) = m
function _marginal_method(s::Symbol)
    t = Symbol(uppercase(String(s)))
    (t === :LAPLACE || t === :LA) && return Laplace()
    (t === :VARIATIONAL || t === :VA) && return Variational()
    throw(ArgumentError("marginal must be :laplace/:LA or :variational/:VA, got :$s"))
end
_marginal_method_symbol(::Laplace) = :laplace
_marginal_method_symbol(::Variational) = :variational
# R-facing method token. Kept unabbreviated (matching the stored :variational
# symbol and the rest of the codebase, and the "laplace" sibling) — the exact
# on-the-wire token is pending R-lane agreement before it is a frozen contract.
_marginal_method_string(::Laplace) = "laplace"
_marginal_method_string(::Variational) = "variational"

# numerically stable logistic and log(1 + exp η)
_logistic(η) = η >= 0 ? 1.0 / (1.0 + exp(-η)) : (e = exp(η); e / (1.0 + e))
_log1pexp(η) = η > 0 ? η + log1p(exp(-η)) : log1p(exp(η))
_logbinom(m, y) = _logfactorial(m) - _logfactorial(y) - _logfactorial(m - y)

# Log-beta from the module's existing Lanczos `_loggamma` (multivariate.jl, in scope —
# included before nongaussian.jl). No `SpecialFunctions` dependency; valid for a,b > 0.
_lbeta(a, b) = _loggamma(a) + _loggamma(b) - _loggamma(a + b)

# Digamma ψ(x) = d/dx logΓ(x) for x > 0, by the standard recurrence-to-asymptotic
# series (the BetaBinomial score needs ψ; a finite-difference ψ is fragile, so this
# is a proper series). Push the argument to x ≥ 6 with ψ(x) = ψ(x+1) − 1/x, then use
# the asymptotic ψ(x) ≈ ln x − 1/(2x) − 1/(12x²) + 1/(120x⁴) − 1/(252x⁶) + 1/(240x⁸).
# Accurate to ~1e-10 for x > 0 (we only ever call it at α+y, β+n−y, α, β — all > 0),
# comfortably inside the rtol-1e-5 score-vs-finite-difference kernel gate.
function _digamma(x::Real)
    z = Float64(x)
    ψ = 0.0
    while z < 6.0
        ψ -= 1.0 / z
        z += 1.0
    end
    inv = 1.0 / z
    inv2 = inv * inv
    ψ += log(z) - 0.5 * inv -
         inv2 * (1 / 12 - inv2 * (1 / 120 - inv2 * (1 / 252 - inv2 / 240)))
    return ψ
end

# --- Dependency-free standard-normal primitives for the probit family (H3) -------
# Project.toml has no SpecialFunctions/Distributions; the coarse genomic
# `_standard_normal_cdf_approx` (7.5e-8) is NOT accurate enough for likelihood
# derivatives, and the tail ratio φ/Φ underflows. These reuse the module's existing,
# already-validated incomplete-gamma machinery (`_reg_gamma_p_series`/`_reg_gamma_q_cf`,
# multivariate.jl, in scope) via the identity erfc(z) = Q(1/2, z²), and add a LOG-form
# tail continued fraction so `_norm_logcdf` stays finite into the deep left tail.

const _LOG2PI = log(2π)

_norm_pdf(x) = exp(-0.5 * x * x) / sqrt(2π)
_norm_logpdf(x) = -0.5 * (x * x + _LOG2PI)

# erfc(z) for z ≥ 0 via Q(1/2, z²): series form when z² < a+1 = 1.5, else the cf.
_erfc_nonneg(z) = (zz = z * z; zz < 1.5 ? 1.0 - _reg_gamma_p_series(0.5, zz) :
                                          _reg_gamma_q_cf(0.5, zz))

# Continued-fraction value h of Q(a, x) (Lentz) — the underflow-free factor of
# `_reg_gamma_q_cf` (multivariate.jl), reproduced here so `_norm_logcdf` can take
# log(Q) WITHOUT the exp(-x) prefactor underflowing in the deep tail. (A separate
# function name, not a redefinition — no precompile conflict; verified against
# `_reg_gamma_q_cf` in the test suite.)
function _gamma_q_cf_h(a::Real, x::Real)
    tiny = 1e-300
    b = x + 1.0 - a
    cc = 1.0 / tiny
    d = 1.0 / b
    h = d
    @inbounds for i in 1:1000
        an = -i * (i - a)
        b += 2.0
        d = an * d + b
        abs(d) < tiny && (d = tiny)
        cc = b + an / cc
        abs(cc) < tiny && (cc = tiny)
        d = 1.0 / d
        del = d * cc
        h *= del
        abs(del - 1.0) < 1e-15 && break
    end
    return h
end

# log Φ(x), numerically stable into the deep left tail (Φ(x) = ½·erfc(−x/√2)).
# x ≥ 0: log1p(−½·erfc(x/√2)) (Φ near 1, no cancellation). x < 0 with x²/2 < 1.5:
# log(½·erfc) directly (Q is O(1)). x < 0 deep tail: the LOG-form cf
# log Q(½,z²) = −z² + log z − logΓ(½) + log h(z²), so logΦ stays finite at x = −40.
function _norm_logcdf(x::Real)
    if x >= 0
        return log1p(-0.5 * _erfc_nonneg(x / sqrt(2.0)))
    end
    z = -x / sqrt(2.0)            # > 0
    zz = z * z                    # = x²/2
    if zz < 1.5
        return log(0.5) + log(_erfc_nonneg(z))
    end
    return log(0.5) - zz + log(z) - _loggamma(0.5) + log(_gamma_q_cf_h(0.5, zz))
end

# Inverse Mills ratio φ(x)/Φ(x), via the logs so it stays finite as x → −∞ (→ |x|).
_norm_mills(x) = exp(_norm_logpdf(x) - _norm_logcdf(x))

# per-observation conditional log-density ℓ(y|η), score dℓ/dη, working weight -d²ℓ/dη²
_fam_loglik(f::GaussianResponse, y, η) = -0.5 * ((y - η)^2 / f.sigma_e2 + log(2π * f.sigma_e2))
_fam_score(f::GaussianResponse, y, η) = (y - η) / f.sigma_e2
_fam_weight(f::GaussianResponse, y, η) = 1.0 / f.sigma_e2

_fam_loglik(::PoissonResponse, y, η) = y * η - exp(η) - _logfactorial(y)
_fam_score(::PoissonResponse, y, η) = y - exp(η)
_fam_weight(::PoissonResponse, y, η) = exp(η)

_fam_loglik(::BernoulliResponse, y, η) = y * η - _log1pexp(η)
_fam_score(::BernoulliResponse, y, η) = y - _logistic(η)
_fam_weight(::BernoulliResponse, y, η) = (p = _logistic(η); p * (1.0 - p))

_fam_loglik(f::BinomialResponse, y, η) = y * η - f.n_trials * _log1pexp(η) + _logbinom(f.n_trials, Int(round(y)))
_fam_score(f::BinomialResponse, y, η) = y - f.n_trials * _logistic(η)
_fam_weight(f::BinomialResponse, y, η) = (p = _logistic(η); f.n_trials * p * (1.0 - p))

# Negative-binomial (NB2, log link). θ = f.theta enters the loggamma normalizer (so
# the OUTER profile over θ is correctly shaped) and the score/weight. score = dℓ/dη;
# weight = -d²ℓ/dη² = the OBSERVED Hessian (always > 0 here — the correct Laplace curvature).
_fam_loglik(f::NegativeBinomialResponse, y, η) =
    (μ = exp(η); θ = f.theta;
     y * η - (y + θ) * log(θ + μ) + θ * log(θ) +
     _loggamma(y + θ) - _loggamma(θ) - _logfactorial(y))
_fam_score(f::NegativeBinomialResponse, y, η) = (μ = exp(η); θ = f.theta; (y - μ) * θ / (θ + μ))
_fam_weight(f::NegativeBinomialResponse, y, η) = (μ = exp(η); θ = f.theta; θ * μ * (θ + y) / (θ + μ)^2)
# the NB normalizer reuses the module's existing `_loggamma` (Lanczos, in multivariate.jl).

# Beta-binomial (logit link, overdispersion ρ ∈ (0,1)). p = logistic(η), s = (1−ρ)/ρ,
# α = p·s, β = (1−p)·s (α + β = s, constant in η). Returns (p, s, α, β).
@inline function _betabin_params(f::BetaBinomialResponse, η)
    p = _logistic(η)
    s = (1.0 - f.rho) / f.rho
    return p, s, p * s, (1.0 - p) * s
end

# Conditional log-density: the Beta latent is marginalised in closed form. The
# η-dependent terms are lgamma(α+y) + lgamma(β+n−y) − lgamma(α) − lgamma(β) (the
# lgamma(α+β±·) terms are η-constant and cancel in the score).
function _fam_loglik(f::BetaBinomialResponse, y, η)
    n = f.n_trials
    _, _, α, β = _betabin_params(f, η)
    return _lbeta(α + y, β + (n - y)) - _lbeta(α, β) + _logbinom(n, Int(round(y)))
end

# score dℓ/dη = (dp/dη)·s·[ψ(α+y) − ψ(β+n−y) − ψ(α) + ψ(β)], with dp/dη = p(1−p).
function _fam_score(f::BetaBinomialResponse, y, η)
    n = f.n_trials
    p, s, α, β = _betabin_params(f, η)
    return p * (1.0 - p) * s *
           (_digamma(α + y) - _digamma(β + (n - y)) - _digamma(α) + _digamma(β))
end

# working weight = FISHER (expected) information −E[d²ℓ/dη²] = E[(dℓ/dη)²], NOT the raw
# observed −d²ℓ/dη². The beta-binomial is NOT log-concave in η (the observed second
# derivative ℓ_ηη = ℓ_pp·(p′)² + ℓ_p·p(1−p)(1−2p) has a sign-indefinite second term),
# so the OBSERVED information can be NEGATIVE and would break the
# `cholesky(Symmetric(H))` PD assumption in `laplace_marginal_loglik`'s IRLS Newton
# loop. The expected information is ≥ 0 by construction (Fisher scoring — the standard
# non-canonical-link Laplace choice), keeping H PD. (Contrast: the logit Binomial
# weight IS the observed information, because the canonical/log-concave logit link
# makes observed == expected.) Computed as Σ_{k=0}^n score(k,η)²·P(k|η,ρ) over the
# exact beta-binomial pmf — needs only ψ (no trigamma) and is strictly positive (the
# k = 0 bracket is ψ(β) − ψ(β+n) < 0, so the score is not identically zero). Ignores
# `y`: the expected information does not depend on the realised count.
function _fam_weight(f::BetaBinomialResponse, y, η)
    n = f.n_trials
    p, s, α, β = _betabin_params(f, η)
    lbαβ = _lbeta(α, β)
    ψα = _digamma(α)
    ψβ = _digamma(β)
    pre = p * (1.0 - p) * s
    info = 0.0
    @inbounds for k in 0:n
        logpk = _logbinom(n, k) + _lbeta(α + k, β + (n - k)) - lbαβ
        sc = pre * (_digamma(α + k) - _digamma(β + (n - k)) - ψα + ψβ)
        info += sc * sc * exp(logpk)
    end
    return info
end

# Bernoulli probit (threshold / liability). s = 2y−1, P(y|η) = Φ(sη), so
# ℓ = log Φ(sη); score = s·M(sη) (signed inverse-Mills ratio, via the tail-stable
# `_norm_mills`); weight = −d²ℓ/dη² = M(sη)·(M(sη)+sη). The logit-binomial uses the
# observed information because it is canonical/log-concave; the probit is ALSO
# log-concave, so its observed weight is ≥ 0 (in fact ∈ (0,1)) and equals the
# expected information — no Fisher-scoring substitution is needed (contrast
# beta-binomial). `y` enters only through the sign `s`.
_fam_loglik(::BernoulliProbitResponse, y, η) = _norm_logcdf((2 * y - 1) * η)
function _fam_score(::BernoulliProbitResponse, y, η)
    s = 2 * y - 1
    return s * _norm_mills(s * η)
end
function _fam_weight(::BernoulliProbitResponse, y, η)
    s = 2 * y - 1
    m = _norm_mills(s * η)
    return m * (m + s * η)
end

# Ordered-categorical probit kernels. Φ via the tail-stable log-cdf; the interval
# probability Φ(b) − Φ(a) (a ≤ b) is computed in whichever tail avoids 1−1
# cancellation, and ±Inf bounds fall through cleanly (Φ(−Inf)=0, Φ(+Inf)=1).
_norm_cdf(x) = x == Inf ? 1.0 : (x == -Inf ? 0.0 : exp(_norm_logcdf(x)))
function _ordered_interval_prob(a, b)   # P(a < e ≤ b), a ≤ b, standard normal
    a == b && return 0.0
    b <= 0 && return _norm_cdf(b) - _norm_cdf(a)     # left tail: both ≤ ½
    a >= 0 && return _norm_cdf(-a) - _norm_cdf(-b)   # upper tails Φ̄(a)−Φ̄(b): both ≤ ½
    return _norm_cdf(b) - _norm_cdf(a)               # straddles 0: well-conditioned
end
# Category-k latent bounds (θ_{k-1}−η, θ_k−η) with the ±Inf end thresholds.
function _ord_bounds(f::OrderedProbitResponse, k, η)
    K = length(f.thresholds) + 1
    a = k == 1 ? -Inf : f.thresholds[k - 1] - η
    b = k == K ? Inf : f.thresholds[k] - η
    return a, b
end
_ord_pdf(x) = isinf(x) ? 0.0 : _norm_pdf(x)         # φ(±Inf) = 0 for the end categories
function _fam_loglik(f::OrderedProbitResponse, y, η)
    a, b = _ord_bounds(f, Int(y), Float64(η))
    return log(_ordered_interval_prob(a, b))
end
# score = dℓ/dη = (φ(a) − φ(b)) / P, since dΦ(θ−η)/dη = −φ(θ−η).
function _fam_score(f::OrderedProbitResponse, y, η)
    a, b = _ord_bounds(f, Int(y), Float64(η))
    P = _ordered_interval_prob(a, b)
    return (_ord_pdf(a) - _ord_pdf(b)) / P
end
# working weight = OBSERVED information −d²ℓ/dη² = score² − (a·φ(a) − b·φ(b))/P.
# Ordered probit is log-concave in η (log of a Gaussian interval probability), so the
# observed information is ≥ 0 and equals the binary probit's observed weight at K = 2
# — no Fisher-scoring substitution needed (contrast beta-binomial). The a·φ(a) end term
# → 0 at an infinite bound (φ decays faster than a grows). Depends on the realised y
# (observed info), like the other log-concave families (Poisson/Binomial/probit).
function _fam_weight(f::OrderedProbitResponse, y, η)
    a, b = _ord_bounds(f, Int(y), Float64(η))
    P = _ordered_interval_prob(a, b)
    score = (_ord_pdf(a) - _ord_pdf(b)) / P
    aφa = isinf(a) ? 0.0 : a * _ord_pdf(a)
    bφb = isinf(b) ? 0.0 : b * _ord_pdf(b)
    return score * score - (aφa - bφb) / P
end

# Gamma (log link), mean μ = exp(η), supplied shape ν. ℓ = ν(log ν − η) + (ν−1)log y −
# ν y e^{-η} − log Γ(ν). Log-concave in η → observed info = −d²ℓ/dη² = ν y e^{-η} > 0
# (no Fisher-scoring substitution). ν = 1 reduces to the exponential.
function _fam_loglik(f::GammaResponse, y, η)
    ν = f.shape
    return ν * (log(ν) - η) + (ν - 1) * log(y) - ν * y * exp(-η) - _loggamma(ν)
end
_fam_score(f::GammaResponse, y, η) = f.shape * (y * exp(-η) - 1.0)
_fam_weight(f::GammaResponse, y, η) = f.shape * y * exp(-η)

function _logfactorial(y)
    k = Int(round(y))
    s = 0.0
    @inbounds for i in 2:k
        s += log(i)
    end
    return s
end

# Validate the response data against the family. Poisson (log link) requires
# non-negative integer counts; the per-record kernels would otherwise mix a
# raw-y score with a round(y) log-factorial and silently misreport the loglik.
_check_counts(::ResponseFamily, yv) = nothing
function _check_counts(::PoissonResponse, yv)
    all(y -> isinteger(y) && y >= 0, yv) ||
        throw(ArgumentError("PoissonResponse requires non-negative integer counts"))
    return nothing
end
function _check_counts(::BernoulliResponse, yv)
    all(y -> y == 0 || y == 1, yv) ||
        throw(ArgumentError("BernoulliResponse requires binary 0/1 responses"))
    return nothing
end
function _check_counts(f::BinomialResponse, yv)
    all(y -> isinteger(y) && 0 <= y <= f.n_trials, yv) ||
        throw(ArgumentError("BinomialResponse requires integer counts in 0:n_trials"))
    return nothing
end
function _check_counts(f::BinomialVectorResponse, yv)
    length(f.n_trials) == length(yv) ||
        throw(ArgumentError("n_trials must have one entry per record (length(n_trials) == length(y))"))
    all(i -> isinteger(yv[i]) && 0 <= yv[i] <= f.n_trials[i], eachindex(yv)) ||
        throw(ArgumentError("BinomialVectorResponse requires integer counts with 0 <= y[i] <= n_trials[i]"))
    return nothing
end
function _check_counts(::NegativeBinomialResponse, yv)
    all(y -> isinteger(y) && y >= 0, yv) ||
        throw(ArgumentError("NegativeBinomialResponse requires non-negative integer counts"))
    return nothing
end
function _check_counts(f::BetaBinomialResponse, yv)
    all(y -> isinteger(y) && 0 <= y <= f.n_trials, yv) ||
        throw(ArgumentError("BetaBinomialResponse requires integer counts in 0:n_trials"))
    return nothing
end
function _check_counts(::BernoulliProbitResponse, yv)
    all(y -> y == 0 || y == 1, yv) ||
        throw(ArgumentError("BernoulliProbitResponse requires binary 0/1 responses"))
    return nothing
end
function _check_counts(f::OrderedProbitResponse, yv)
    K = length(f.thresholds) + 1
    all(y -> isinteger(y) && 1 <= y <= K, yv) ||
        throw(ArgumentError("OrderedProbitResponse requires integer category codes in 1:$(K)"))
    return nothing
end
function _check_counts(::GammaResponse, yv)
    all(y -> y > 0, yv) ||
        throw(ArgumentError("GammaResponse requires strictly positive responses"))
    return nothing
end

"""
    laplace_marginal_loglik(y, X, Z, Ainv, sigma_a2, family; tol = 1e-10, maxiter = 100)

Laplace-approximate marginal log-likelihood of the non-Gaussian animal model,
integrating the random effect `u ~ N(0, A·σ²a)` (and `β` under a flat prior).
Returns `(loglik, beta, u, converged, gradient_norm, iterations)`.

Experimental, dense, validation-scale. For a `GaussianResponse` it is exact and
equals `sparse_reml_loglik`.
"""
function laplace_marginal_loglik(y::AbstractVector, X::AbstractMatrix, Z::AbstractMatrix,
                                 Ainv::AbstractMatrix, sigma_a2::Real,
                                 family::ResponseFamily;
                                 tol::Real = 1e-10, maxiter::Integer = 100)
    sigma_a2 > 0 || throw(ArgumentError("sigma_a2 must be positive"))
    yv = Float64.(y)
    Xd = Matrix{Float64}(X)
    Zd = Matrix{Float64}(Z)
    Ai = Matrix{Float64}(Ainv)
    n = length(yv)
    p = size(Xd, 2)
    q = size(Zd, 2)
    size(Xd, 1) == n || throw(ArgumentError("X must have one row per record"))
    size(Zd, 1) == n || throw(ArgumentError("Z must have one row per record"))
    size(Ai, 1) == q == size(Ai, 2) || throw(ArgumentError("Ainv must be q×q with q = size(Z,2)"))
    _check_counts(family, yv)

    beta = zeros(p)
    u = zeros(q)
    gnorm = Inf
    iters = 0
    converged = false
    local H
    for it in 1:maxiter
        iters = it
        η = Xd * beta .+ Zd * u
        s = [_fam_score(_fam_record(family, i), yv[i], η[i]) for i in 1:n]
        w = [_fam_weight(_fam_record(family, i), yv[i], η[i]) for i in 1:n]
        grad = vcat(transpose(Xd) * s, transpose(Zd) * s .- (Ai * u) ./ sigma_a2)
        gnorm = norm(grad)
        WX = w .* Xd
        WZ = w .* Zd
        H = [transpose(Xd)*WX transpose(Xd)*WZ
             transpose(Zd)*WX (transpose(Zd)*WZ .+ Ai ./ sigma_a2)]
        step = Symmetric(H) \ grad
        beta .+= step[1:p]
        u .+= step[(p + 1):end]
        if gnorm < tol
            converged = true
            break
        end
    end

    η = Xd * beta .+ Zd * u
    w = [_fam_weight(_fam_record(family, i), yv[i], η[i]) for i in 1:n]
    WX = w .* Xd
    WZ = w .* Zd
    H = [transpose(Xd)*WX transpose(Xd)*WZ
         transpose(Zd)*WX (transpose(Zd)*WZ .+ Ai ./ sigma_a2)]
    cond = sum(_fam_loglik(_fam_record(family, i), yv[i], η[i]) for i in 1:n)
    quad_u = dot(u, Ai * u) / sigma_a2
    logdet_Ainv = logdet(cholesky(Symmetric(Ai)))
    logdet_H = logdet(cholesky(Symmetric(H)))
    loglik = cond - 0.5 * quad_u - 0.5 * q * log(sigma_a2) + 0.5 * logdet_Ainv +
             0.5 * p * log(2π) - 0.5 * logdet_H
    return (loglik = converged ? loglik : NaN, beta = beta, u = u, converged = converged,
            gradient_norm = gnorm, iterations = iters)
end

# Expected conditional loglik / score / weight under the variational posterior
# q, where η ~ N(η̄, v). Closed forms: Gaussian (identity link) and Poisson
# (log link, via the log-normal MGF E[exp η] = exp(η̄ + v/2)).
_fam_expected_loglik(f::GaussianResponse, y, ηbar, v) = _fam_loglik(f, y, ηbar) - 0.5 * v / f.sigma_e2
_fam_expected_score(f::GaussianResponse, y, ηbar, v) = (y - ηbar) / f.sigma_e2
_fam_expected_weight(f::GaussianResponse, ηbar, v) = 1.0 / f.sigma_e2

_fam_expected_loglik(::PoissonResponse, y, ηbar, v) = y * ηbar - exp(ηbar + 0.5 * v) - _logfactorial(y)
_fam_expected_score(::PoissonResponse, y, ηbar, v) = y - exp(ηbar + 0.5 * v)
_fam_expected_weight(::PoissonResponse, ηbar, v) = exp(ηbar + 0.5 * v)

# Gauss–Hermite rule (Golub–Welsch), built once at load time, for families whose
# Gaussian expectation E_{η~N(η̄,v)}[g(η)] has no closed form (e.g. Bernoulli logit).
const _GH_NODES, _GH_WEIGHTS = let m = 20
    E = eigen(SymTridiagonal(zeros(m), [sqrt(k / 2) for k in 1:(m - 1)]))
    (E.values, sqrt(π) .* (E.vectors[1, :] .^ 2))
end
# E[g(η)] with η ~ N(η̄, v): change of variables η = η̄ + √(2v)·x against e^{-x²}.
function _gh_expect(g, ηbar, v)
    s = sqrt(2.0 * v)
    acc = 0.0
    @inbounds for k in eachindex(_GH_NODES)
        acc += _GH_WEIGHTS[k] * g(ηbar + s * _GH_NODES[k])
    end
    return acc / sqrt(π)
end

# Bernoulli (logit): no closed-form Gaussian expectation, so integrate the log
# partition and its η̄-derivatives by Gauss–Hermite. Using the SAME nodes makes
# `_fam_expected_score`/`_fam_expected_weight` exactly the η̄-derivatives of
# `_fam_expected_loglik`, so the VA Newton step stays consistent with the ELBO.
_fam_expected_loglik(::BernoulliResponse, y, ηbar, v) = y * ηbar - _gh_expect(_log1pexp, ηbar, v)
_fam_expected_score(::BernoulliResponse, y, ηbar, v) = y - _gh_expect(_logistic, ηbar, v)
_fam_expected_weight(::BernoulliResponse, ηbar, v) =
    _gh_expect(η -> (p = _logistic(η); p * (1.0 - p)), ηbar, v)

_fam_expected_loglik(f::BinomialResponse, y, ηbar, v) =
    y * ηbar - f.n_trials * _gh_expect(_log1pexp, ηbar, v) + _logbinom(f.n_trials, Int(round(y)))
_fam_expected_score(f::BinomialResponse, y, ηbar, v) = y - f.n_trials * _gh_expect(_logistic, ηbar, v)
_fam_expected_weight(f::BinomialResponse, ηbar, v) =
    f.n_trials * _gh_expect(η -> (p = _logistic(η); p * (1.0 - p)), ηbar, v)

# Self-consistent variational covariance S = (Zᵀ W̃ Z + P0)⁻¹ and per-record
# marginal variances v = diag(Z S Zᵀ), with W̃ depending on (η̄, v). Fixed-point.
function _va_covariance(family, Zd, P0, ηbar, v0, n, tol, covariance)
    v = copy(v0)
    local S
    for _ in 1:200
        w = [_fam_expected_weight(_fam_record(family, i), ηbar[i], v[i]) for i in 1:n]
        Huu = transpose(Zd) * (w .* Zd) .+ P0
        S = covariance === :diagonal ? Diagonal(1.0 ./ diag(Huu)) : inv(Symmetric(Huu))
        ZS = Zd * S
        vnew = [dot(view(ZS, i, :), view(Zd, i, :)) for i in 1:n]
        change = maximum(abs.(vnew .- v))
        v = vnew
        change < tol && break
    end
    return S, v
end

"""
    variational_marginal_loglik(y, X, Z, Ainv, sigma_a2, family;
                                covariance = :full, tol = 1e-10, maxiter = 100)

Gaussian-variational (VA / ELBO) marginal for the non-Gaussian animal model — a
sibling of [`laplace_marginal_loglik`](@ref) that maximises the evidence lower
bound over a Gaussian variational posterior `q(u) = N(m, S)` for the correlated
random effect `u ~ N(0, A·σ²a)`, with `β` integrated under a flat prior.

`covariance = :full` (the validated foundation) profiles `S` to the closed-form
`S* = (Zᵀ W̃ Z + Ainv/σ²a)⁻¹` — the FULL joint covariance, which preserves the
pedigree relatedness (a diagonal / mean-field `S` would discard it and would not
be REML-exact). Returns
`(elbo, beta, m, S, converged, gradient_norm, iterations, covariance)`.

`elbo` is a LOWER BOUND on `log p(y)`, and is tight — equal to
[`laplace_marginal_loglik`](@ref) and to `sparse_reml_loglik` — for the Gaussian
family (the optimal full-covariance `q` is the exact Gaussian posterior, so the
KL vanishes). EXPERIMENTAL, dense, validation-scale; not exported, not wired into
fitting, no R model-spec. Architecture follows the MIT DRM.jl `:LA`/`:VA` idea;
the correlated-prior kernel is reimplemented here. Meaningful only when
`converged == true`.
"""
function variational_marginal_loglik(y::AbstractVector, X::AbstractMatrix, Z::AbstractMatrix,
                                     Ainv::AbstractMatrix, sigma_a2::Real,
                                     family::ResponseFamily;
                                     covariance::Symbol = :full,
                                     tol::Real = 1e-10, maxiter::Integer = 100)
    sigma_a2 > 0 || throw(ArgumentError("sigma_a2 must be positive"))
    covariance in (:full, :diagonal) ||
        throw(ArgumentError("covariance must be :full or :diagonal"))
    yv = Float64.(y)
    Xd = Matrix{Float64}(X)
    Zd = Matrix{Float64}(Z)
    Ai = Matrix{Float64}(Ainv)
    n = length(yv)
    p = size(Xd, 2)
    q = size(Zd, 2)
    size(Xd, 1) == n || throw(ArgumentError("X must have one row per record"))
    size(Zd, 1) == n || throw(ArgumentError("Z must have one row per record"))
    size(Ai, 1) == q == size(Ai, 2) || throw(ArgumentError("Ainv must be q×q with q = size(Z,2)"))
    _check_counts(family, yv)
    P0 = Ai ./ sigma_a2

    beta = zeros(p)
    m = zeros(q)
    v = zeros(n)
    S = Matrix{Float64}(undef, q, q)
    gnorm = Inf
    iters = 0
    converged = false
    for outer_it in 1:maxiter
        iters = outer_it
        ηbar = Xd * beta .+ Zd * m
        S, v = _va_covariance(family, Zd, P0, ηbar, v, n, tol, covariance)
        w = [_fam_expected_weight(_fam_record(family, i), ηbar[i], v[i]) for i in 1:n]
        g = [_fam_expected_score(_fam_record(family, i), yv[i], ηbar[i], v[i]) for i in 1:n]
        grad = vcat(transpose(Xd) * g, transpose(Zd) * g .- P0 * m)
        gnorm = norm(grad)
        WX = w .* Xd
        WZ = w .* Zd
        H = [transpose(Xd)*WX transpose(Xd)*WZ
             transpose(Zd)*WX (transpose(Zd)*WZ .+ P0)]
        step = Symmetric(H) \ grad
        beta .+= step[1:p]
        m .+= step[(p + 1):end]
        if gnorm < tol
            converged = true
            break
        end
    end

    # ELBO and gradient at the returned mode
    ηbar = Xd * beta .+ Zd * m
    S, v = _va_covariance(family, Zd, P0, ηbar, v, n, tol, covariance)
    g = [_fam_expected_score(_fam_record(family, i), yv[i], ηbar[i], v[i]) for i in 1:n]
    gnorm = norm(vcat(transpose(Xd) * g, transpose(Zd) * g .- P0 * m))
    Ell = sum(_fam_expected_loglik(_fam_record(family, i), yv[i], ηbar[i], v[i]) for i in 1:n)
    logdet_Ainv = logdet(cholesky(Symmetric(Ai)))
    logdet_S = covariance === :diagonal ? sum(log, diag(S)) : logdet(cholesky(Symmetric(S)))
    kl = 0.5 * ((dot(m, Ai * m) + tr(Ai * S)) / sigma_a2 + q * log(sigma_a2) -
                logdet_Ainv - logdet_S - q)
    # β integrated under a flat prior (Laplace over β): the Schur-complement
    # curvature X'W̃X − X'W̃Z S Z'W̃X (= X'V⁻¹X for Gaussian) gives the REML-type
    # correction that makes the Gaussian ELBO tight (== sparse_reml_loglik).
    beta_term = 0.0
    if p > 0
        w = [_fam_expected_weight(_fam_record(family, i), ηbar[i], v[i]) for i in 1:n]
        XtWZ = transpose(Xd) * (w .* Zd)
        schur = Symmetric(transpose(Xd) * (w .* Xd) .- XtWZ * S * transpose(XtWZ))
        beta_term = 0.5 * p * log(2π) - 0.5 * logdet(cholesky(schur))
    end
    elbo = converged ? (Ell - kl + beta_term) : NaN
    return (elbo = elbo, beta = beta, m = m, S = S, converged = converged,
            gradient_norm = gnorm, iterations = iters, covariance = covariance)
end

"""
    NonGaussianFit

Experimental fitted-object container for the non-Gaussian animal model returned by
[`fit_laplace_reml`](@ref). Fields: `variance_components`, `marginal_loglik`,
`beta`, `breeding_values` (the posterior-mode random effect), `ids`, `converged`,
`family`, `marginal`, `n_trials` (the Binomial trials denominator for
`family = :binomial` — a scalar common denominator or a per-record `Vector{Int}`;
`nothing` for every other family), and `dispersion` (the FIXED supplied
overdispersion `ρ` for `family = :beta_binomial`; `nothing` for every other family —
the negative-binomial `theta` is ESTIMATED and lives in `variance_components`, not
here). Use the extractor
functions [`breeding_values`](@ref) (→ `BreedingValues(ids, values)`),
[`variance_components`](@ref), and [`fixed_effects`](@ref) for the same access
contract as [`AnimalModelFit`](@ref); this is a distinct type so its extractors do
not collide with the multivariate `NamedTuple` extractors.
"""
struct NonGaussianFit
    variance_components::NamedTuple
    marginal_loglik::Float64
    beta::Vector{Float64}
    breeding_values::Vector{Float64}
    ids::Vector
    converged::Bool
    family::Symbol
    marginal::Symbol
    n_trials::Union{Int,Vector{Int},Nothing}
    dispersion::Union{Float64,Nothing}
end

variance_components(fit::NonGaussianFit) = fit.variance_components
fixed_effects(fit::NonGaussianFit) = fit.beta
breeding_values(fit::NonGaussianFit) = BreedingValues(fit.ids, fit.breeding_values)
EBV(fit::NonGaussianFit) = breeding_values(fit)

"""
    nongaussian_result_payload(fit::NonGaussianFit)

Bridge-ready, "boring" result payload (a `NamedTuple` of scalars / arrays /
nested `NamedTuple`s — Julia structs stay Julia-side) for a non-Gaussian
animal-model fit from [`fit_laplace_reml`](@ref). It mirrors the top-level shape
of [`multivariate_result_payload`](@ref) (the univariate [`result_payload`](@ref)
predates this convention and nests `method`/diagnostics differently) so the R twin
can marshal one shape and the R non-Gaussian family-acceptance can fire.

Fields: `engine`, `target = "nongaussian_reml"`, `family`
(`"gaussian"`/`"poisson"`/`"bernoulli"`/`"binomial"`/`"nbinom"`/`"beta_binomial"`/`"bernoulli_probit"`),
`n_trials` (the Binomial/beta-binomial trials denominator — a scalar common
denominator or a per-record integer vector; `nothing` for other families — so a
counts payload is self-describing on the data scale), `dispersion` (the FIXED
overdispersion `ρ` for `family = "beta_binomial"`; `nothing` for every other family —
the negative-binomial `theta` is ESTIMATED and rides in `variance_components`),
`method` (`"laplace"`/`"variational"`,
resolved through the internal `MarginalMethod` dispatch from the stored marginal
symbol), `variance_components`, `fixed_effects`, `breeding_values = (ids, values)`,
`loglik`, and `converged`.

The payload shape is deliberately **family-uniform** and therefore carries NO
`heritability` field: a `NonGaussianFit` computes none, and h² is left to the
consumer (it is derivable from `variance_components` for the Gaussian family, but
on the liability scale the logit/log-link families have no residual-variance scale
on which a single h² is defined here — surfacing one would be an unbacked claim).
EXPERIMENTAL: the fitter is not the public default, not wired into the R formula
path, and has no external comparator; the Bernoulli single-trial variance is
downward-biased (an information effect). The R-facing `method` token
(`"laplace"`/`"variational"`) and family-acceptance shape are pending R-lane
agreement before this is treated as a frozen contract.
"""
function nongaussian_result_payload(fit::NonGaussianFit)
    return (
        engine = "HSquared.jl",
        target = "nongaussian_reml",
        family = String(fit.family),
        n_trials = fit.n_trials isa AbstractVector ? copy(fit.n_trials) : fit.n_trials,
        dispersion = fit.dispersion,
        method = _marginal_method_string(_marginal_method(fit.marginal)),
        variance_components = fit.variance_components,
        fixed_effects = copy(fit.beta),
        breeding_values = (ids = copy(fit.ids), values = copy(fit.breeding_values)),
        loglik = fit.marginal_loglik,
        converged = fit.converged,
    )
end

"""
    fit_laplace_reml(y, X, Z, Ainv; family = :gaussian, marginal = :laplace,
                     initial = nothing, ids = nothing, iterations = 200)

Estimate the variance component(s) of the non-Gaussian animal model by maximising
the marginal log-likelihood (`marginal = :laplace`) or the ELBO
(`marginal = :variational`) over the variance components. `family = :gaussian`
estimates `(sigma_a2, sigma_e2)` (NelderMead); `family = :poisson`,
`family = :bernoulli`, and `family = :binomial` (which requires the `n_trials`
keyword — a common scalar denominator OR a per-record integer vector of length
`length(y)`, the general `cbind(successes, failures)` GLMM) estimate the single
`sigma_a2` (Brent). `family = :beta_binomial` is the OVERdispersed logit-binomial
(`BetaBinomialResponse`); it requires BOTH `n_trials` (scalar) and `rho`
(the fixed overdispersion `ρ ∈ (0,1)`), estimates `sigma_a2` (Brent) at that supplied
fixed ρ, and is Laplace-only (`marginal = :variational` is rejected).
`family = :bernoulli_probit` is the binary threshold / liability-scale model
(`BernoulliProbitResponse`, probit link `Φ(η)`); it estimates the single `sigma_a2`
(Brent) and is also Laplace-only (its variational expected information is
response-dependent; `marginal = :variational` is rejected). Returns a
[`NonGaussianFit`](@ref)
with fields `variance_components`, `marginal_loglik`, `beta`, `breeding_values`,
`ids`, `converged`, `family`, `marginal`, and the extractor methods
`breeding_values(fit)` / `variance_components(fit)` / `fixed_effects(fit)`.

Binary `:bernoulli` data carries little variance information at small scale, so
`sigma_a2` is prone to running to a search-bound boundary; `:binomial` with more
trials per record is more informative and recovers `sigma_a2` far better (see
`sim/phase6_binomial_recovery.jl`).

EXPERIMENTAL, dense/validation-scale — the first *fitted* non-Gaussian step.
For the Gaussian family the objective is the exact REML log-likelihood, so this
recovers the same estimate as [`fit_sparse_reml`](@ref). Exported as an
experimental fitter; not the public default, not wired into the R formula path,
no R model-spec, no external comparator.
"""
function fit_laplace_reml(y::AbstractVector, X::AbstractMatrix, Z::AbstractMatrix,
                          Ainv::AbstractMatrix; family::Symbol = :gaussian,
                          marginal::Symbol = :laplace, initial = nothing,
                          n_trials = nothing, rho = nothing, ids = nothing,
                          theta_init::Real = 1.0, iterations::Integer = 200)
    family in (:gaussian, :poisson, :bernoulli, :binomial, :nbinom, :beta_binomial, :bernoulli_probit, :ordered_probit, :gamma) ||
        throw(ArgumentError("family must be :gaussian, :poisson, :bernoulli, :binomial, :nbinom, :beta_binomial, :bernoulli_probit, :ordered_probit, or :gamma"))
    # probit (threshold) is Laplace-only at this slice: its variational expected
    # information is response-dependent (−E[ℓ″] varies with the sign s = 2y−1), which
    # the y-free `_fam_expected_weight` signature cannot carry — a VA kernel is
    # explicit follow-up. Reject `:variational` with a clear error.
    family === :bernoulli_probit && !(_marginal_method(marginal) isa Laplace) &&
        throw(ArgumentError("family = :bernoulli_probit supports only marginal = :laplace at this slice (no variational kernel); got :$(marginal)"))
    family === :binomial && n_trials === nothing &&
        throw(ArgumentError("family = :binomial requires the n_trials keyword"))
    # beta-binomial is a TWO-parameter family (σ²a + the overdispersion ρ). This slice
    # estimates σ²a (Brent) at a SUPPLIED FIXED ρ, so BOTH keywords are required; joint
    # (σ²a, ρ) estimation is explicit follow-up. Laplace-only (no VA kernel for it).
    if family === :beta_binomial
        n_trials === nothing &&
            throw(ArgumentError("family = :beta_binomial requires the n_trials keyword"))
        rho === nothing &&
            throw(ArgumentError("family = :beta_binomial requires the rho keyword (the fixed overdispersion)"))
        _marginal_method(marginal) isa Laplace ||
            throw(ArgumentError("family = :beta_binomial supports only marginal = :laplace at this slice (no variational kernel); got :$(marginal)"))
    end
    # `n_trials` may be a common scalar denominator OR a per-record integer vector
    # (the general cbind(successes, failures) GLMM). A vector must match the data and
    # carry integer counts; integer-valued reals are accepted (the R bridge marshals
    # doubles) but genuinely non-integer entries get a clean error, not a MethodError.
    if family === :binomial && n_trials isa AbstractVector
        length(n_trials) == length(y) ||
            throw(ArgumentError("a per-record n_trials vector must have length(n_trials) == length(y)"))
        all(isinteger, n_trials) ||
            throw(ArgumentError("a per-record n_trials vector must contain integer trial counts"))
    end
    # Resolve the marginal through the MarginalMethod dispatch (accepts the engine
    # :laplace/:variational and the DRM-style :LA/:VA spellings; throws otherwise),
    # then store the canonical symbol. Value-preserving for :laplace/:variational.
    mm = _marginal_method(marginal)
    marginal = _marginal_method_symbol(mm)
    margfun = mm isa Variational ? variational_marginal_loglik : laplace_marginal_loglik
    val(r) = mm isa Variational ? r.elbo : r.loglik
    aids = ids === nothing ? collect(1:size(Z, 2)) : collect(ids)
    if family === :gaussian
        sa0, se0 = initial === nothing ? (1.0, 1.0) :
                   (Float64(initial.sigma_a2), Float64(initial.sigma_e2))
        (sa0 > 0 && se0 > 0) || throw(ArgumentError("initial variances must be positive"))
        obj(p) = -val(margfun(y, X, Z, Ainv, exp(p[1]), GaussianResponse(exp(p[2]))))
        res = optimize(obj, log.([sa0, se0]), NelderMead(), Optim.Options(iterations = iterations))
        sa2, se2 = exp.(Optim.minimizer(res))
        fit = margfun(y, X, Z, Ainv, sa2, GaussianResponse(se2))
        return NonGaussianFit((sigma_a2 = sa2, sigma_e2 = se2), val(fit), fit.beta,
                              marginal === :variational ? fit.m : fit.u, aids,
                              Optim.converged(res) && fit.converged, :gaussian, marginal, nothing, nothing)
    elseif family === :nbinom
        # negative-binomial: TWO estimable scalars (sigma_a2 + the overdispersion theta),
        # profiled jointly by NelderMead. Laplace-only (the NB ELBO has no closed form).
        mm isa Laplace ||
            throw(ArgumentError("family = :nbinom supports only marginal = :laplace at this slice (the NB variational ELBO has no closed form); got :$(marginal)"))
        sa0 = initial === nothing ? 1.0 : Float64(initial.sigma_a2)
        (sa0 > 0 && theta_init > 0) || throw(ArgumentError("initial sigma_a2 and theta_init must be positive"))
        objnb(p) = -laplace_marginal_loglik(y, X, Z, Ainv, exp(p[1]), NegativeBinomialResponse(exp(p[2]))).loglik
        res = optimize(objnb, log.([sa0, Float64(theta_init)]), NelderMead(),
                       Optim.Options(iterations = iterations))
        sa2, theta = exp.(Optim.minimizer(res))
        fit = laplace_marginal_loglik(y, X, Z, Ainv, sa2, NegativeBinomialResponse(theta))
        return NonGaussianFit((sigma_a2 = sa2, theta = theta), fit.loglik, fit.beta,
                              fit.u, aids, Optim.converged(res) && fit.converged, :nbinom, :laplace, nothing, nothing)
    elseif family === :ordered_probit
        # ordered-categorical probit: JOINTLY estimate σ²a AND the K-1 cutpoints θ.
        # IDENTIFICATION: fix θ_1 = 0 (drop the intercept location, standard for a
        # cumulative link with a probit residual variance fixed at 1) and estimate the
        # remaining θ_2..θ_{K-1} through POSITIVE increments δ (θ_j = θ_{j-1} + exp(δ_j)),
        # so strict ordering is automatic and the search is unconstrained. K is read from
        # the data (codes 1..K). Laplace-only (the ordinal VA kernel is a follow-up).
        mm isa Laplace ||
            throw(ArgumentError("family = :ordered_probit supports only marginal = :laplace at this slice (no variational kernel); got :$(marginal)"))
        all(yi -> isinteger(yi) && yi >= 1, y) ||
            throw(ArgumentError("family = :ordered_probit requires integer category codes >= 1"))
        K = Int(maximum(y))
        K >= 2 || throw(ArgumentError("family = :ordered_probit needs >= 2 categories in the data"))
        sa0 = initial === nothing ? 1.0 : Float64(initial.sigma_a2)
        sa0 > 0 || throw(ArgumentError("initial sigma_a2 must be positive"))
        ndelta = K - 2                                   # free cutpoints beyond the fixed θ_1 = 0
        _cuts(δ) = ndelta == 0 ? [0.0] : cumsum(vcat(0.0, exp.(collect(δ))))  # length K-1
        # Guard the objective: during the simplex search NelderMead probes (σ²a, θ)
        # configurations where the penalized-IRLS Hessian degenerates (a category with
        # ~0 probability under every record); return a large finite penalty so the
        # optimizer walks away from those regions rather than throwing.
        # Safety rail on σ²a: threshold models weakly identify the breeding-value
        # variance on uninformative data (it is confounded with the fixed unit probit
        # residual absent relatedness/replication), so the MLE can run to the boundary.
        # Confine the search to log(sa0) ± 8 (σ²a within ~3000× of the start) — the same
        # bounded-search spirit as the single-component Brent path. A returned estimate
        # at the rail is a self-describing "not credibly identified at this design" signal.
        logsa0 = log(sa0)
        function objord(p)
            abs(p[1] - logsa0) > 8.0 && return 1.0e12    # σ²a safety rail
            m = try
                laplace_marginal_loglik(y, X, Z, Ainv, exp(p[1]),
                                        OrderedProbitResponse(_cuts(@view p[2:end])))
            catch err
                err isa Union{LinearAlgebra.SingularException, LinearAlgebra.PosDefException, DomainError} ?
                    nothing : rethrow(err)
            end
            (m === nothing || !isfinite(m.loglik)) ? 1.0e12 : -m.loglik
        end
        if ndelta == 0                                   # K = 2: only σ²a (1-D Brent), θ = [0]
            res = optimize(s -> objord([s]), log(sa0) - 6.0, log(sa0) + 6.0)
            sa2 = exp(Optim.minimizer(res)); thetahat = [0.0]
        else
            res = optimize(objord, vcat(log(sa0), zeros(ndelta)), NelderMead(),
                           Optim.Options(iterations = iterations))
            pmin = Optim.minimizer(res); sa2 = exp(pmin[1]); thetahat = _cuts(pmin[2:end])
        end
        fit = laplace_marginal_loglik(y, X, Z, Ainv, sa2, OrderedProbitResponse(thetahat))
        return NonGaussianFit((sigma_a2 = sa2, cutpoints = thetahat), fit.loglik, fit.beta,
                              fit.u, aids, Optim.converged(res) && fit.converged,
                              :ordered_probit, :laplace, nothing, nothing)
    elseif family === :gamma
        # Gamma (log link): TWO estimable scalars (σ²a + the shape ν), profiled jointly by
        # NelderMead over (log σ²a, log ν) — the same shape as :nbinom. Well identified GIVEN
        # relatedness/replication; on uninformative data (few animals, no replication) the
        # shape (flat likelihood for large ν) and σ²a are weakly identified and the optimum
        # can run away — so both are confined by a safety rail (log(init) ± 8, within ~3000×
        # of the start; an estimate at a rail is a "not credibly identified at this design"
        # signal), matching the ordinal joint-estimation guard. Laplace-only (the Gamma
        # variational ELBO is a follow-up). `theta_init` seeds the shape ν.
        mm isa Laplace ||
            throw(ArgumentError("family = :gamma supports only marginal = :laplace at this slice (no variational kernel); got :$(marginal)"))
        all(yi -> yi > 0, y) ||
            throw(ArgumentError("family = :gamma requires strictly positive responses"))
        sa0 = initial === nothing ? 1.0 : Float64(initial.sigma_a2)
        (sa0 > 0 && theta_init > 0) || throw(ArgumentError("initial sigma_a2 and theta_init (shape) must be positive"))
        lsa0 = log(sa0); lth0 = log(Float64(theta_init))
        function objg(p)
            (abs(p[1] - lsa0) > 8.0 || abs(p[2] - lth0) > 8.0) && return 1.0e12   # σ²a + ν safety rails
            m = try
                laplace_marginal_loglik(y, X, Z, Ainv, exp(p[1]), GammaResponse(exp(p[2])))
            catch err
                err isa Union{LinearAlgebra.SingularException, LinearAlgebra.PosDefException, DomainError} ?
                    nothing : rethrow(err)
            end
            (m === nothing || !isfinite(m.loglik)) ? 1.0e12 : -m.loglik
        end
        res = optimize(objg, log.([sa0, Float64(theta_init)]), NelderMead(),
                       Optim.Options(iterations = iterations))
        sa2, shape = exp.(Optim.minimizer(res))
        fit = laplace_marginal_loglik(y, X, Z, Ainv, sa2, GammaResponse(shape))
        return NonGaussianFit((sigma_a2 = sa2, shape = shape), fit.loglik, fit.beta,
                              fit.u, aids, Optim.converged(res) && fit.converged, :gamma, :laplace, nothing, nothing)
    else
        # single-variance-component families: Poisson (log link), Bernoulli/Binomial
        # (logit), and beta-binomial (logit, σ²a estimated at the supplied fixed ρ)
        fam = _resolve_single_family(family, n_trials; rho = rho)
        sa0 = initial === nothing ? 1.0 : Float64(initial.sigma_a2)
        sa0 > 0 || throw(ArgumentError("initial sigma_a2 must be positive"))
        res = optimize(s -> -val(margfun(y, X, Z, Ainv, exp(s), fam)),
                       log(sa0) - 6.0, log(sa0) + 6.0)
        sa2 = exp(Optim.minimizer(res))
        fit = margfun(y, X, Z, Ainv, sa2, fam)
        stored_n = family === :binomial ?
                   (n_trials isa AbstractVector ? Vector{Int}(n_trials) : Int(n_trials)) :
                   family === :beta_binomial ? Int(n_trials) : nothing
        stored_disp = family === :beta_binomial ? Float64(rho) : nothing
        return NonGaussianFit((sigma_a2 = sa2,), val(fit), fit.beta,
                              marginal === :variational ? fit.m : fit.u, aids,
                              Optim.converged(res) && fit.converged, family, marginal,
                              stored_n, stored_disp)
    end
end

"""
    laplace_reml_interval(y, X, Z, Ainv; family = :poisson, marginal = :laplace,
                          level = 0.95, initial = nothing, n_trials = nothing)

Profile likelihood-ratio confidence interval for the single-variance-component
non-Gaussian animal-model `sigma_a2`, by inverting the marginal LRT
`2·(ℓ̂ − ℓ(sigma_a2)) ≤ χ²₁,level`. Returns
`(sigma_a2, lower, upper, level, lower_clamped, upper_clamped, converged)` — the
`*_clamped` flags report whether an endpoint reached the search bound (the profile
did not cross the χ² threshold within range) so a non-crossing endpoint is NOT a
confidence limit, and `converged` echoes the point-fit convergence; both make a
degenerate interval self-describing rather than a silent finite triple.

Supports the single-variance-component families `family = :poisson`,
`family = :bernoulli`, and `family = :binomial` (which requires `n_trials` — a
scalar common denominator or a per-record integer vector, the same contract as
[`fit_laplace_reml`](@ref)). The Gaussian two-component case needs nuisance
profiling and is future work.

This is a profile-LIKELIHOOD-ratio interval, so `marginal = :laplace` is required:
the variational `:VA` objective is the ELBO (a lower bound), not the marginal
log-likelihood, so `2·(ELBÔ − ELBO(σ²a))` is not χ²₁-calibrated — `:variational`
throws rather than return an uncalibrated quantity dressed as a CI.

EXPERIMENTAL, asymptotic, single-component only — preliminary coverage
CHARACTERIZATION only (`sim/phase6_nongaussian_interval_coverage.jl`, opt-in,
validation-scale; read as conservative/over-covering), NOT a calibrated coverage
guarantee. Whether
the interval is two-sided depends on where `σ̂²a` sits relative to the flat
near-zero region of the profile, NOT on the family alone: a Binomial fit whose
`σ̂²a` is clear of zero gives two interior LRT roots, but a small `σ̂²a` (or binary
`:bernoulli` data, which is uninformative about the latent variance) leaves a flat
profile so an endpoint reaches the search bound (flagged via `*_clamped`) — honest
but not a confidence limit (the same information effect that biases binary
`sigma_a2`). Reuses `_profile_root`.
"""
function laplace_reml_interval(y::AbstractVector, X::AbstractMatrix, Z::AbstractMatrix,
                               Ainv::AbstractMatrix; family::Symbol = :poisson,
                               marginal::Symbol = :laplace, level::Real = 0.95,
                               initial = nothing, n_trials = nothing)
    family in (:poisson, :bernoulli, :binomial, :bernoulli_probit) ||
        throw(ArgumentError("laplace_reml_interval supports family = :poisson, :bernoulli, :binomial, or :bernoulli_probit"))
    family === :binomial && n_trials === nothing &&
        throw(ArgumentError("family = :binomial requires the n_trials keyword"))
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1)"))
    _marginal_method(marginal) isa Laplace ||
        throw(ArgumentError("laplace_reml_interval is a profile-LIKELIHOOD-ratio interval and requires marginal = :laplace; the variational ELBO is a lower bound, not a χ²₁-calibrated LRT statistic"))
    if family === :binomial && n_trials isa AbstractVector
        length(n_trials) == length(y) ||
            throw(ArgumentError("a per-record n_trials vector must have length(n_trials) == length(y)"))
        all(isinteger, n_trials) ||
            throw(ArgumentError("a per-record n_trials vector must contain integer trial counts"))
    end
    fam = _resolve_single_family(family, n_trials)
    fit = fit_laplace_reml(y, X, Z, Ainv; family = family, marginal = :laplace,
                           initial = initial, n_trials = n_trials)
    sa2hat = fit.variance_components.sigma_a2
    llhat = fit.marginal_loglik
    z = _standard_normal_quantile((1 + level) / 2)
    q = z * z
    target(sa2) = 2 * (llhat - laplace_marginal_loglik(y, X, Z, Ainv, sa2, fam).loglik) - q
    lo_bound = sa2hat * 1e-4
    up_bound = sa2hat * 1e4
    lower = _profile_root(target, lo_bound, sa2hat)
    upper = _profile_root(target, up_bound, sa2hat)
    # a clamp is exactly `_profile_root`'s non-crossing condition: the deviance never
    # reached the χ² threshold within the search range (so the endpoint is the bound).
    lower_clamped = target(lo_bound) <= 0
    upper_clamped = target(up_bound) <= 0
    return (sigma_a2 = sa2hat, lower = lower, upper = upper, level = level,
            lower_clamped = lower_clamped, upper_clamped = upper_clamped,
            converged = fit.converged)
end

# Logistic distribution variance — the latent-scale residual variance the logit link
# implies (the variance of a standard logistic). Used ONLY for the latent-scale h²
# (the "distribution-specific variance" of Nakagawa & Schielzeth 2017), NOT for the
# observation-scale integration (see `_nongaussian_h2_core`).
const _VAR_LOGISTIC = (π^2) / 3

# Core latent-/observation-scale heritability (Nakagawa–Schielzeth 2017 / de
# Villemereuil QGglmm transform). ESTIMAND CONVENTIONS (documented because the spec
# is delicate here and this is validation-only):
#  • Latent/link scale: h²_lat = V_A / (V_A + V_link + V_fixed), V_link = π²/3 for
#    logit, 0 for the log link (Poisson has NO latent residual → h²_lat = NaN, the
#    exact reason the payload refuses a single h²), σ²e for Gaussian.
#  • Observation/data scale: the additive genetic variance is V_A,obs = Ψ²·V_A with
#    Ψ = E[g⁻¹′(η)] the AVERAGE inverse-link derivative — under the model's
#    joint-Gaussian latent assumption, by Stein's lemma this is the variance of the
#    linear regression of the mean on the breeding value, so V_A,obs ≤ Var(mean) and
#    h²_obs ∈ (0,1) (verified numerically in the tests, not assumed). The expectation is
#    over the LINEAR-PREDICTOR distribution η ~ N(μ, V_A + V_fixed) — the π²/3 logit
#    residual is NOT added to this integration variance (it is an observation-process
#    term, not predictor spread; matching de Villemereuil's QGglmm `binom1.logit`).
#  • Estimand per family: PROPORTION for Bernoulli/Binomial, COUNT for Poisson.
# This is asymptotic/validation-scale; the exact decomposition awaits a same-estimand
# QGglmm/MCMCglmm comparator + a Fisher/Falconer review before any promotion.
function _nongaussian_h2_core(family::Symbol, V_A::Float64, mu::Float64, sigma_e2::Float64,
                              n_trials::Int, V_fixed::Float64, converged::Bool)
    if family === :gaussian
        h2 = V_A / (V_A + sigma_e2)
        return (family = :gaussian, sigma_a2 = V_A, mu = mu,
                latent_total_variance = V_A + sigma_e2, h2_latent = h2, h2_observation = h2,
                var_distribution = sigma_e2, var_link = sigma_e2, converged = converged,
                information_limited = false,
                caveat = "Gaussian identity link: latent and observation scales coincide.",
                method = :gaussian_identity)
    elseif family === :poisson
        V_pred = V_A + V_fixed                       # linear-predictor variance
        λ = exp(mu + V_pred / 2)                      # E[exp η]; Ψ = λ for the log link
        V_A_obs = λ^2 * V_A                           # Ψ²·V_A (Stein)
        V_P_obs = λ^2 * (exp(V_pred) - 1) + λ         # Var(exp η) + E[Poisson var]
        return (family = :poisson, sigma_a2 = V_A, mu = mu, latent_total_variance = V_pred,
                h2_latent = NaN, h2_observation = V_A_obs / V_P_obs,
                var_distribution = λ, var_link = 0.0, converged = converged,
                information_limited = false,
                caveat = "Poisson log link: latent h² is degenerate (no latent residual) → NaN; observation/count scale via the log-normal–Poisson closed form (NS 2017).",
                method = :lognormal_poisson)
    elseif family === :bernoulli || family === :binomial
        V_pred = V_A + V_fixed
        latent_total = V_A + _VAR_LOGISTIC + V_fixed
        p̄ = _gh_expect(_logistic, mu, V_pred)
        Ψ = _gh_expect(η -> (p = _logistic(η); p * (1.0 - p)), mu, V_pred)
        Ep2 = _gh_expect(η -> (p = _logistic(η); p * p), mu, V_pred)
        var_p = Ep2 - p̄^2                             # Var of the mean proportion
        V_A_obs = Ψ^2 * V_A                           # Ψ²·V_A (Stein) ≤ var_p
        var_dist = Ψ / n_trials                       # proportion-scale sampling variance
        info_lim = n_trials == 1
        return (family = family, sigma_a2 = V_A, mu = mu, latent_total_variance = latent_total,
                h2_latent = V_A / latent_total, h2_observation = V_A_obs / (var_p + var_dist),
                var_distribution = var_dist, var_link = _VAR_LOGISTIC, converged = converged,
                information_limited = info_lim,
                caveat = info_lim ?
                    "Single-trial Bernoulli: the latent σ²a is downward-biased (information effect), so the observation-scale h² inherits that bias — never present it as clean." :
                    "Binomial logit: observation scale on the PROPORTION estimand via Gauss–Hermite quadrature.",
                method = :logit_quadrature)
    else
        throw(ArgumentError("nongaussian_heritability supports :gaussian/:poisson/:bernoulli/:binomial; family :$family is follow-up (probit V_link = 1, beta-binomial / negative-binomial overdispersion each need their own link-variance derivation)"))
    end
end

_h2_family_params(f::GaussianResponse) = (:gaussian, 1, f.sigma_e2)
_h2_family_params(::PoissonResponse) = (:poisson, 1, NaN)
_h2_family_params(::BernoulliResponse) = (:bernoulli, 1, NaN)
_h2_family_params(f::BinomialResponse) = (:binomial, f.n_trials, NaN)
_h2_family_params(f::ResponseFamily) = throw(ArgumentError("nongaussian_heritability does not support $(typeof(f)) (follow-up: probit, beta-binomial, negative-binomial)"))

"""
    nongaussian_heritability(fit::NonGaussianFit; mu = nothing, n_trials = nothing, predictor_variance = 0.0)
    nongaussian_heritability(sigma_a2, mu, family::ResponseFamily; predictor_variance = 0.0)

Latent- and observation-scale heritability for a non-Gaussian animal model — the
Nakagawa–Schielzeth (2017) / de Villemereuil (QGglmm) transform that fills the gap
the family-uniform `nongaussian_result_payload` deliberately leaves (it carries NO
`heritability`, since "reuse the Gaussian ratio" is wrong off the identity link).

Returns a self-describing `NamedTuple`:
`(family, sigma_a2, mu, latent_total_variance, h2_latent, h2_observation,
var_distribution, var_link, converged, information_limited, caveat, method)`.

**Latent/link scale** `h2_latent = V_A / (V_A + V_link + V_fixed)`: `V_link = π²/3`
(logit), `σ²e` (Gaussian), and `0` for the Poisson log link — which makes the
Poisson latent h² DEGENERATE, returned as `NaN` (the precise reason the payload
refuses a single h²). **Observation/data scale** uses the QGglmm decomposition
`V_A,obs = Ψ²·V_A` (`Ψ = E[g⁻¹′(η)]`, the average inverse-link derivative; by Stein's
lemma the exact variance of the regression of the mean on the breeding value, so
`h2_observation ∈ (0,1)`), integrating over the LINEAR-PREDICTOR distribution
`η ~ N(μ, V_A + V_fixed)` (the π²/3 logit residual is NOT added to the integration
variance) via the module's existing 20-node Gauss–Hermite for logit and the
log-normal closed form for Poisson. Estimand: PROPORTION for Bernoulli/Binomial,
COUNT for Poisson; Gaussian reduces to `V_A/(V_A+σ²e)` on both scales.

`mu` (link-scale population mean) defaults to the fit's single intercept; with >1
fixed effect it is REQUIRED (and `predictor_variance`, the fixed-effect linear-
predictor variance, is the NS "variance explained by fixed effects" term). The
function REFUSES a non-converged fit; sets `information_limited = true` with the
downward-bias caveat for single-trial Bernoulli; and returns `h2_observation = NaN`
with a caveat for a per-record varying `n_trials` (a single data-scale h² is
ill-defined under varying denominators — not silently averaged).

EXPERIMENTAL, dense/validation-scale; exact in its closed-form limbs and anchored to
an independent quadrature oracle in `test/runtests.jl`, but it inherits the latent
σ²a bias (especially single-trial Bernoulli) and has NO same-estimand external
(QGglmm/MCMCglmm) comparator yet — not the public default, not covered. Deliberately
NOT added to `nongaussian_result_payload` (that shape stays family-uniform).
"""
function nongaussian_heritability(fit::NonGaussianFit; mu = nothing, n_trials = nothing,
                                  predictor_variance::Real = 0.0)
    fit.converged ||
        throw(ArgumentError("nongaussian_heritability refuses a non-converged fit (converged = false)"))
    V_A = Float64(fit.variance_components.sigma_a2)
    μ = if mu !== nothing
        Float64(mu)
    elseif length(fit.beta) == 1
        fit.beta[1]
    else
        throw(ArgumentError("mu (link-scale population mean) is required: the fit has $(length(fit.beta)) fixed effects, so the intercept is ambiguous — supply `mu` (and `predictor_variance` for the fixed-effect spread)"))
    end
    nt = n_trials === nothing ? fit.n_trials : n_trials
    if fit.family === :binomial && nt isa AbstractVector
        lt = V_A + _VAR_LOGISTIC + Float64(predictor_variance)
        return (family = :binomial, sigma_a2 = V_A, mu = μ, latent_total_variance = lt,
                h2_latent = V_A / lt, h2_observation = NaN, var_distribution = NaN,
                var_link = _VAR_LOGISTIC, converged = fit.converged, information_limited = false,
                caveat = "Per-record varying n_trials: a single observation-scale h² is ill-defined under varying denominators → NaN (not silently averaged).",
                method = :logit_quadrature)
    end
    nt_int = if fit.family === :binomial
        nt === nothing && throw(ArgumentError("family = :binomial needs n_trials (from the fit or the keyword)"))
        Int(nt)
    else
        1
    end
    σ²e = fit.family === :gaussian ? Float64(fit.variance_components.sigma_e2) : NaN
    return _nongaussian_h2_core(fit.family, V_A, μ, σ²e, nt_int, Float64(predictor_variance),
                                fit.converged)
end

function nongaussian_heritability(sigma_a2::Real, mu::Real, family::ResponseFamily;
                                  predictor_variance::Real = 0.0)
    fam_sym, nt, σ²e = _h2_family_params(family)
    return _nongaussian_h2_core(fam_sym, Float64(sigma_a2), Float64(mu), σ²e, nt,
                                Float64(predictor_variance), true)
end
