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
        isfinite(sigma_e2) || throw(ArgumentError("sigma_e2 must be finite"))
        value = Float64(sigma_e2)
        isfinite(value) && value > 0 || throw(ArgumentError(
            "sigma_e2 must be finite and positive after Float64 conversion"))
        return new(value)
    end
end

"""Poisson family with log link (`μ = exp(η)`)."""
struct PoissonResponse <: ResponseFamily end

"""Bernoulli family with logit link (`p = logistic(η)`) for binary 0/1 traits."""
struct BernoulliResponse <: ResponseFamily end

"""
Binomial family with logit link for counts of successes out of a common number of
trials `n_trials` (`y ∈ 0:n_trials`, `p = logistic(η)`). Generalises
`BernoulliResponse` (= `n_trials = 1`); five-seed Bernoulli and Binomial recovery
results are descriptive and do not establish that trial count shrinks variance bias.
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
        isfinite(theta) || throw(ArgumentError("theta (overdispersion) must be finite"))
        value = Float64(theta)
        isfinite(value) && value > 0 || throw(ArgumentError(
            "theta (overdispersion) must be finite and positive after Float64 conversion"))
        return new(value)
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
        all(isfinite, thresholds) || throw(ArgumentError(
            "OrderedProbitResponse thresholds must be finite"))
        values = Float64.(thresholds)
        all(isfinite, values) || throw(ArgumentError(
            "OrderedProbitResponse thresholds must be finite after Float64 conversion"))
        all(i -> values[i] < values[i + 1], 1:(length(values) - 1)) || throw(ArgumentError(
            "OrderedProbitResponse thresholds must be strictly increasing after Float64 conversion"))
        return new(values)
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
        isfinite(shape) || throw(ArgumentError("GammaResponse shape must be finite"))
        value = Float64(shape)
        isfinite(value) && value > 0 || throw(ArgumentError(
            "GammaResponse shape must be finite and positive after Float64 conversion"))
        return new(value)
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

# Trigamma ψ₁(x) = d/dx ψ(x) — same dependency-free strategy as `_digamma`:
# recurrence ψ₁(x) = ψ₁(x+1) + 1/x² up to x ≥ 6, then the asymptotic series
# ψ₁(x) ≈ 1/x + 1/(2x²) + 1/(6x³) − 1/(30x⁵) + 1/(42x⁷). Used for the Gamma
# log-scale residual variance V_link = Var(log Y | η) = ψ₁(shape)
# (doc-19 §3.1). Accurate to ~3e-9 for x > 0 (ψ₁(1) = π²/6, ψ₁(2) = π²/6 − 1).
function _trigamma(x::Real)
    z = Float64(x)
    ψ₁ = 0.0
    while z < 6.0
        ψ₁ += 1.0 / (z * z)
        z += 1.0
    end
    inv = 1.0 / z
    inv2 = inv * inv
    ψ₁ += inv + 0.5 * inv2 + inv2 * inv * (1 / 6 - inv2 * (1 / 30 - inv2 / 42))
    return ψ₁
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

@inline function _poisson_deviance_remainder(x)
    # expm1(x) - x is O(x²); direct subtraction discards nearly all useful
    # digits when a large count is close to its fitted mean. The short Taylor
    # series is ample on this interval, including for counts near Float64's
    # exact-integer limit.
    if abs(x) <= 0.5
        term = x * x / 2
        total = term
        for k in 3:18
            term *= x / k
            total += term
        end
        return total
    end
    return expm1(x) - x
end

@inline function _poisson_stirling_correction(y)
    invy = inv(y)
    invy2 = invy * invy
    return invy * (1 / 12 + invy2 * (-1 / 360 + invy2 * (1 / 1260 - invy2 / 1680)))
end

function _poisson_loglik(y, η)
    y == 0 && return -exp(η)
    y < 50 && return y * η - exp(η) - _logfactorial(y)

    x = η - log(y)
    x > log(floatmax(Float64)) && return -Inf
    deviance = y * _poisson_deviance_remainder(x)
    return -deviance - 0.5 * (log(2pi) + log(y)) - _poisson_stirling_correction(y)
end

_fam_loglik(::PoissonResponse, y, η) = _poisson_loglik(y, η)
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
# loop. The expected information is ≥ 0 by construction (Fisher scoring), keeping the
# working system PD. The FINAL Laplace determinant uses observed curvature
# through `_fam_observed_weight` below, not this scoring matrix. (Contrast: the logit Binomial
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

# The iteration may use Fisher scoring, but a Laplace determinant requires
# OBSERVED curvature at the mode. For a beta-binomial, writing c=(1-rho)/rho,
# p=logistic(eta), D=digamma(a+y)-digamma(a)-digamma(b+n-y)+digamma(b),
# the score is c*p*(1-p)*D. Differentiating once more gives the two terms below.
_fam_observed_weight(f::ResponseFamily, y, η) = _fam_weight(f, y, η)
function _fam_observed_weight(f::BetaBinomialResponse, y, η)
    p, c, a, b = _betabin_params(f, η)
    n = f.n_trials
    cp = c * p * (1.0 - p)
    D = _digamma(a + y) - _digamma(a) - _digamma(b + n - y) + _digamma(b)
    E = _trigamma(a + y) - _trigamma(a) + _trigamma(b + n - y) - _trigamma(b)
    return -(cp * (1.0 - 2p) * D + cp^2 * E)
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
    return _loggamma(Float64(k) + 1.0)
end

# Validate the response data against the family. Poisson (log link) requires
# non-negative integer counts; the per-record kernels would otherwise mix a
# raw-y score with a round(y) log-factorial and silently misreport the loglik.
function _check_finite_responses(yv)
    all(isfinite, yv) || throw(ArgumentError("responses must contain only finite values"))
    return nothing
end
_check_counts(::ResponseFamily, yv) = _check_finite_responses(yv)
function _check_counts(::PoissonResponse, yv)
    _check_finite_responses(yv)
    all(y -> isinteger(y) && y >= 0, yv) ||
        throw(ArgumentError("PoissonResponse requires non-negative integer counts"))
    return nothing
end
function _check_counts(::BernoulliResponse, yv)
    _check_finite_responses(yv)
    all(y -> y == 0 || y == 1, yv) ||
        throw(ArgumentError("BernoulliResponse requires binary 0/1 responses"))
    return nothing
end
function _check_counts(f::BinomialResponse, yv)
    _check_finite_responses(yv)
    all(y -> isinteger(y) && 0 <= y <= f.n_trials, yv) ||
        throw(ArgumentError("BinomialResponse requires integer counts in 0:n_trials"))
    return nothing
end
function _check_counts(f::BinomialVectorResponse, yv)
    length(f.n_trials) == length(yv) ||
        throw(ArgumentError("n_trials must have one entry per record (length(n_trials) == length(y))"))
    _check_finite_responses(yv)
    all(i -> isinteger(yv[i]) && 0 <= yv[i] <= f.n_trials[i], eachindex(yv)) ||
        throw(ArgumentError("BinomialVectorResponse requires integer counts with 0 <= y[i] <= n_trials[i]"))
    return nothing
end
function _check_counts(::NegativeBinomialResponse, yv)
    _check_finite_responses(yv)
    all(y -> isinteger(y) && y >= 0, yv) ||
        throw(ArgumentError("NegativeBinomialResponse requires non-negative integer counts"))
    return nothing
end
function _check_counts(f::BetaBinomialResponse, yv)
    _check_finite_responses(yv)
    all(y -> isinteger(y) && 0 <= y <= f.n_trials, yv) ||
        throw(ArgumentError("BetaBinomialResponse requires integer counts in 0:n_trials"))
    return nothing
end
function _check_counts(::BernoulliProbitResponse, yv)
    _check_finite_responses(yv)
    all(y -> y == 0 || y == 1, yv) ||
        throw(ArgumentError("BernoulliProbitResponse requires binary 0/1 responses"))
    return nothing
end
function _check_counts(f::OrderedProbitResponse, yv)
    _check_finite_responses(yv)
    K = length(f.thresholds) + 1
    all(y -> isinteger(y) && 1 <= y <= K, yv) ||
        throw(ArgumentError("OrderedProbitResponse requires integer category codes in 1:$(K)"))
    return nothing
end
function _check_counts(::GammaResponse, yv)
    _check_finite_responses(yv)
    all(y -> y > 0, yv) ||
        throw(ArgumentError("GammaResponse requires strictly positive responses"))
    return nothing
end

# Necessary proper-integral checks for a flat fixed-effect measure. An
# intercept is any vector in col(X) equal to one, including a rescaled column.
# This bounded guard does not diagnose general separation along other columns.
function _check_flat_effect_integral(family::ResponseFamily, y, X)
    p = size(X, 2)
    p == 0 && return nothing
    rank(X) == p || throw(ArgumentError(
        "X must have full column rank for a proper flat-measure fixed-effect integral"))
    n = length(y)
    has_intercept = norm(X * (X \ ones(n)) .- 1.0) <= 1e-8 * sqrt(n)
    has_intercept || return nothing
    improper = if family isa PoissonResponse || family isa NegativeBinomialResponse
        all(iszero, y)
    elseif family isa BernoulliResponse
        all(iszero, y) || all(==(1), y)
    elseif family isa BernoulliProbitResponse
        all(iszero, y) || all(==(1), y)
    elseif family isa OrderedProbitResponse
        all(==(1), y) || all(==(length(family.thresholds) + 1), y)
    elseif family isa BinomialResponse || family isa BetaBinomialResponse
        all(iszero, y) || all(==(family.n_trials), y)
    elseif family isa BinomialVectorResponse
        all(iszero, y) || all(y .== family.n_trials)
    else
        false
    end
    improper && throw(ArgumentError(
        "constant endpoint responses with an intercept have an improper flat-measure fixed-effect integral"))
    return nothing
end

"""
    laplace_marginal_loglik(y, X, Z, Ainv, sigma_a2, family; tol = 1e-10, maxiter = 100)

Joint integrated-Laplace objective for the non-Gaussian animal model. It
approximates `∫∫ exp(ℓ(y | Xβ + Zu)) φ(u; 0, G) du dβ`, with `G = A·σ²a`.
The measure `dβ` has density one in the supplied X coefficient coordinates;
it is flat and unnormalized. The genetic Gaussian density is normalized.

At the joint mode of `F = ℓ(y | Xβ + Zu) - u′G⁻¹u/2`, the reported value is
`F - log|G|/2 + p*log(2π)/2 - log|H_joint|/2`, where `p = size(X, 2)` and
`H_joint` is the negative observed-curvature Hessian in `(β, u)` at that mode.
This integrates fixed effects as well as genetic effects. It generally differs
from conventional Laplace-ML, which profiles fixed effects after integrating
only genetic effects. The integral must be proper; current necessary guards
and local mode convergence do not establish propriety for every design.

Returns `(loglik, beta, u, converged, gradient_norm, iterations)`.
Experimental, dense, validation-scale. For `GaussianResponse` the integral is
exact and equals `sparse_reml_loglik` under the same fixed-effect measure and
likelihood normalization. That Gaussian REML reduction does not define a
non-Gaussian REML or AI-REML objective. The historical `fit_laplace_reml` name
is retained for compatibility.
"""
function laplace_marginal_loglik(y::AbstractVector, X::AbstractMatrix, Z::AbstractMatrix,
                                 Ainv::AbstractMatrix, sigma_a2::Real,
                                 family::ResponseFamily;
                                 tol::Real = 1e-10, maxiter::Integer = 100)
    sigma_a2 = _finite_positive_variance_float64("sigma_a2", sigma_a2)
    tol = _finite_positive_float64("tol", tol)
    maxiter >= 1 || throw(ArgumentError("maxiter must be positive"))
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
    Ai = _check_relationship_precision(Ai, q)
    _check_counts(family, yv)
    _check_flat_effect_integral(family, yv, Xd)

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
        step_eta = Xd * step[1:p] .+ Zd * step[(p + 1):end]
        step_penalty = sqrt(max(dot(step[(p + 1):end], Ai * step[(p + 1):end]) / sigma_a2, 0.0))
        current_penalty = sqrt(max(dot(u, Ai * u) / sigma_a2, 0.0))
        # Scale the stopping rule in predictor and random-effect penalty units,
        # not raw coefficients, so rescaling a fixed-effect column is harmless.
        step_scale = hypot(norm(step_eta), step_penalty)
        current_scale = hypot(norm(η), current_penalty)
        if step_scale <= tol * (1 + current_scale)
            converged = true
            break
        end
        current_objective = sum(_fam_loglik(_fam_record(family, i), yv[i], η[i]) for i in 1:n) -
                            0.5 * dot(u, Ai * u) / sigma_a2
        alpha = 1.0
        accepted = false
        for _ in 1:64
            beta_candidate = beta .+ alpha .* step[1:p]
            u_candidate = u .+ alpha .* step[(p + 1):end]
            eta_candidate = Xd * beta_candidate .+ Zd * u_candidate
            objective_candidate = sum(_fam_loglik(_fam_record(family, i), yv[i], eta_candidate[i]) for i in 1:n) -
                                  0.5 * dot(u_candidate, Ai * u_candidate) / sigma_a2
            allowance = 1e-12 * (1 + abs(current_objective))
            if isfinite(objective_candidate) && objective_candidate >= current_objective - allowance
                beta .= beta_candidate
                u .= u_candidate
                accepted = true
                break
            end
            alpha *= 0.5
        end
        accepted || break
    end

    η = Xd * beta .+ Zd * u
    w = [_fam_observed_weight(_fam_record(family, i), yv[i], η[i]) for i in 1:n]
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

@inline function _poisson_expected_mean_increment(ηbar, halfv)
    iszero(halfv) && return 0.0
    if halfv > 0
        log_mean = ηbar + halfv
        log_mean > log(floatmax(Float64)) && return Inf
        return exp(log_mean) * (-expm1(-halfv))
    end
    ηbar > log(floatmax(Float64)) && return -Inf
    return exp(ηbar) * expm1(halfv)
end

_fam_expected_loglik(::PoissonResponse, y, ηbar, v) =
    _poisson_loglik(y, ηbar) - _poisson_expected_mean_increment(ηbar, 0.5 * v)
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
function _va_covariance(family, Zd, P0, ηbar, v0, n, tol, covariance, maxiter)
    v = copy(v0)
    local S
    change = Inf
    converged = false
    iterations = 0
    for iteration in 1:maxiter
        iterations = iteration
        w = [_fam_expected_weight(_fam_record(family, i), ηbar[i], v[i]) for i in 1:n]
        Huu = transpose(Zd) * (w .* Zd) .+ P0
        S = covariance === :diagonal ? Diagonal(1.0 ./ diag(Huu)) : inv(Symmetric(Huu))
        ZS = Zd * S
        vnew = [dot(view(ZS, i, :), view(Zd, i, :)) for i in 1:n]
        change = maximum(abs.(vnew .- v))
        v = vnew
        if change < tol
            converged = true
            break
        end
    end
    return (S = S, v = v, converged = converged, iterations = iterations,
            fixed_point_error = change)
end

"""
    variational_marginal_loglik(y, X, Z, Ainv, sigma_a2, family;
                                covariance = :full, tol = 1e-10, maxiter = 100,
                                covariance_maxiter = 200)

Gaussian variational approximation for the non-Gaussian animal model. With no
fixed-effect columns (`size(X,2) == 0`), this maximises an evidence lower bound
(ELBO) over `q(u) = N(m,S)` for `u ~ N(0,A*sigma_a2)`. With fixed effects, it
optimises the conditional variational objective and adds a local Laplace
correction for integration over beta under a flat measure. That hybrid value
is **not guaranteed to be a lower bound** on the integrated log likelihood.

`covariance = :full` uses `S = (Z' Wtilde Z + Ainv/sigma_a2)^(-1)`;
`:diagonal` restricts S to a diagonal matrix. The returned `elbo` field keeps
its historical name for compatibility. Read `objective` and `is_lower_bound`:
- `:elbo`, true: no fixed effects;
- `:gaussian_reml`, true: Gaussian family with full covariance (exact REML);
- `:variational_laplace`, false: the other fixed-effect cases.

Returns `(elbo, beta, m, S, converged, gradient_norm, iterations, covariance,
objective, is_lower_bound, covariance_converged, covariance_iterations,
covariance_fixed_point_error)`. New convergence diagnostics are appended to
preserve the prior positional field order. Convergence requires both the outer
gradient and the inner covariance fixed point to meet `tol`. A true lower-bound
flag describes the mathematical objective; numerical quadrature and
convergence tolerances still apply.
Experimental, dense, validation-scale; meaningful only when `converged == true`.
For the full-covariance Gaussian family it equals [`laplace_marginal_loglik`](@ref)
and `sparse_reml_loglik`. This Gaussian reduction does not establish a bound for
non-Gaussian beta integration. With fixed effects, the local correction holds
the variational covariance fixed; it does not account for how the optimized
covariance changes with the fixed-effect coefficients. Architecture follows
the MIT DRM.jl VA dispatch idea; the correlated-prior kernel is reimplemented
here.
"""
function variational_marginal_loglik(y::AbstractVector, X::AbstractMatrix, Z::AbstractMatrix,
                                     Ainv::AbstractMatrix, sigma_a2::Real,
                                     family::ResponseFamily;
                                     covariance::Symbol = :full,
                                     tol::Real = 1e-10, maxiter::Integer = 100,
                                     covariance_maxiter::Integer = 200)
    sigma_a2 = _finite_positive_variance_float64("sigma_a2", sigma_a2)
    tol = _finite_positive_float64("tol", tol)
    maxiter >= 1 || throw(ArgumentError("maxiter must be positive"))
    covariance in (:full, :diagonal) ||
        throw(ArgumentError("covariance must be :full or :diagonal"))
    covariance_maxiter >= 1 || throw(ArgumentError("covariance_maxiter must be positive"))
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
    Ai = _check_relationship_precision(Ai, q)
    _check_counts(family, yv)
    _check_flat_effect_integral(family, yv, Xd)
    P0 = Ai ./ sigma_a2

    beta = zeros(p)
    m = zeros(q)
    v = zeros(n)
    S = Matrix{Float64}(undef, q, q)
    gnorm = Inf
    iters = 0
    converged = false
    covariance_result = nothing
    for outer_it in 1:maxiter
        iters = outer_it
        ηbar = Xd * beta .+ Zd * m
        covariance_result = _va_covariance(family, Zd, P0, ηbar, v, n, tol,
                                            covariance, covariance_maxiter)
        S, v = covariance_result.S, covariance_result.v
        w = [_fam_expected_weight(_fam_record(family, i), ηbar[i], v[i]) for i in 1:n]
        g = [_fam_expected_score(_fam_record(family, i), yv[i], ηbar[i], v[i]) for i in 1:n]
        grad = vcat(transpose(Xd) * g, transpose(Zd) * g .- P0 * m)
        gnorm = norm(grad)
        WX = w .* Xd
        WZ = w .* Zd
        H = [transpose(Xd)*WX transpose(Xd)*WZ
             transpose(Zd)*WX (transpose(Zd)*WZ .+ P0)]
        step = Symmetric(H) \ grad
        step_beta = step[1:p]
        step_m = step[(p + 1):end]
        # Same scaled step test and backtracking line search as
        # laplace_marginal_loglik. An absolute gradient test from beta = 0,
        # m = 0 takes a full Newton step that can leave the ELBO.
        step_eta = Xd * step_beta .+ Zd * step_m
        step_penalty = sqrt(max(dot(step_m, P0 * step_m), 0.0))
        current_penalty = sqrt(max(dot(m, P0 * m), 0.0))
        step_scale = hypot(norm(step_eta), step_penalty)
        current_scale = hypot(norm(ηbar), current_penalty)
        if step_scale <= tol * (1 + current_scale) && covariance_result.converged
            converged = true
            break
        end
        current_objective = sum(_fam_expected_loglik(_fam_record(family, i), yv[i], ηbar[i], v[i]) for i in 1:n) -
                            0.5 * dot(m, P0 * m)
        alpha = 1.0
        accepted = false
        for _ in 1:64
            beta_candidate = beta .+ alpha .* step_beta
            m_candidate = m .+ alpha .* step_m
            eta_candidate = Xd * beta_candidate .+ Zd * m_candidate
            objective_candidate = sum(_fam_expected_loglik(_fam_record(family, i), yv[i], eta_candidate[i], v[i]) for i in 1:n) -
                                  0.5 * dot(m_candidate, P0 * m_candidate)
            allowance = 1e-12 * (1 + abs(current_objective))
            if isfinite(objective_candidate) && objective_candidate >= current_objective - allowance
                beta .= beta_candidate
                m .= m_candidate
                accepted = true
                break
            end
            alpha *= 0.5
        end
        accepted || break
    end

    # ELBO and gradient at the returned mode
    ηbar = Xd * beta .+ Zd * m
    covariance_result = _va_covariance(family, Zd, P0, ηbar, v, n, tol,
                                        covariance, covariance_maxiter)
    S, v = covariance_result.S, covariance_result.v
    g = [_fam_expected_score(_fam_record(family, i), yv[i], ηbar[i], v[i]) for i in 1:n]
    gnorm = norm(vcat(transpose(Xd) * g, transpose(Zd) * g .- P0 * m))
    converged = converged && covariance_result.converged
    Ell = sum(_fam_expected_loglik(_fam_record(family, i), yv[i], ηbar[i], v[i]) for i in 1:n)
    logdet_Ainv = logdet(cholesky(Symmetric(Ai)))
    logdet_S = covariance === :diagonal ? sum(log, diag(S)) : logdet(cholesky(Symmetric(S)))
    kl = 0.5 * ((dot(m, Ai * m) + tr(Ai * S)) / sigma_a2 + q * log(sigma_a2) -
                logdet_Ainv - logdet_S - q)
    # β integrated under a flat prior by a local Laplace correction. The mean
    # Hessian block, not the variational covariance S, determines this Schur
    # complement. For a Gaussian response this is X'V⁻¹X and gives the exact
    # REML correction when the full covariance family is used. For non-Gaussian
    # responses the covariance response to β is held fixed in this local
    # approximation; the result is labelled variational_laplace, not an ELBO.
    beta_term = 0.0
    if p > 0
        w = [_fam_expected_weight(_fam_record(family, i), ηbar[i], v[i]) for i in 1:n]
        XtWZ = transpose(Xd) * (w .* Zd)
        mean_hessian = Symmetric(transpose(Zd) * (w .* Zd) .+ P0)
        mean_factor = cholesky(mean_hessian)
        schur = Symmetric(
            transpose(Xd) * (w .* Xd) .- XtWZ * (mean_factor \ transpose(XtWZ)),
        )
        beta_term = 0.5 * p * log(2π) - 0.5 * logdet(cholesky(schur))
    end
    elbo = converged ? (Ell - kl + beta_term) : NaN
    objective = p == 0 ? :elbo :
                (family isa GaussianResponse && covariance === :full ? :gaussian_reml : :variational_laplace)
    return (elbo = elbo, beta = beta, m = m, S = S, converged = converged,
            gradient_norm = gnorm, iterations = iters, covariance = covariance,
            objective = objective, is_lower_bound = objective !== :variational_laplace,
            covariance_converged = covariance_result.converged,
            covariance_iterations = covariance_result.iterations,
            covariance_fixed_point_error = covariance_result.fixed_point_error)
end

"""
    NonGaussianFit

Experimental fitted-object container for the non-Gaussian animal model returned by
[`fit_laplace_reml`](@ref). Fields: `variance_components`, `marginal_loglik`,
`beta`, `breeding_values` (the posterior-mode random effect), `ids`, `converged`,
`family`, `marginal`, `n_trials` (the Binomial trials denominator for
`family = :binomial` — a scalar common denominator or a per-record `Vector{Int}`;
`nothing` for every other family), `dispersion` (the FIXED supplied
overdispersion `ρ` for `family = :beta_binomial`; `nothing` for every other family —
the negative-binomial `theta` is ESTIMATED and lives in `variance_components`, not
here), `boundary` (`true` when the returned variance-component estimate sits at the
search boundary — the bracket endpoint for the single-variance families, or the
±8-log-unit safety rail for the jointly-estimated families — meaning the point
estimate is a function of the START VALUE, not the data; see #327), and
`restart_estimate` (the second-start point estimate of `sigma_a2` from an opt-in
`restart_check = true` fit, `nothing` otherwise). Use the extractor
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
    boundary::Bool
    restart_estimate::Union{Nothing,Float64}
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
path, and has no external comparator; the Bernoulli single-trial variance estimate has shown error in a five-seed
recovery study; those seeds do not establish bias direction or cause. The R-facing `method` token
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
    nongaussian_three_field_payload(fit::NonGaussianFit;
                                    predictor_variance = 0.0,
                                    response_length = nothing)

Private versioned transport envelope for the ratified 0.9 conditional
Poisson/Bernoulli/Binomial three-field contract.  This deliberately does not
alter [`nongaussian_result_payload`](@ref), whose family-uniform experimental
shape remains a separate legacy bridge surface.

The currently fitted non-Gaussian model has one additive component and no
additional random-effect or observation components.  The envelope therefore
records `components = (V_A, V_RE = 0, V_O = 0)`, derives `mu` from exactly one
intercept, and rejects a nonzero fixed-effect predictor variance.  A vector
Binomial denominator requires `response_length` so its shape is checked without
confusing the number of records with the number of animal effects.
"""
function nongaussian_three_field_payload(
    fit::NonGaussianFit;
    predictor_variance::Real = 0.0,
    response_length::Union{Nothing,Integer} = nothing,
)
    fit.converged ||
        throw(ArgumentError("nongaussian_three_field_payload refuses a non-converged fit (converged = false)"))
    fit.family in (:poisson, :bernoulli, :binomial) ||
        throw(ArgumentError("nongaussian_three_field_payload supports only :poisson, :bernoulli, and :binomial; got :$(fit.family)"))
    # #347: the family gate runs FIRST so the boundary message below can name the exact
    # bound. The three supported families are all single-variance Brent searches, whose
    # bound is the bracket endpoint exp(log(sa0) ± 6). The jointly-estimated families
    # (:gamma, :nbinom, :gaussian, :ordered_probit with K ≥ 3) stop on a ±8-log-unit rail
    # instead and must never be told "± 6"; they cannot reach this line.
    fit.boundary &&
        throw(ArgumentError("nongaussian_three_field_payload refuses a fit at its search boundary " *
                             "(boundary = true): the estimate sits on the rail of the log-scale search " *
                             "bracket exp(log(initial.sigma_a2) ± 6), a function of the supplied " *
                             "`initial`, not the data; retry with a different `initial` to recentre the " *
                             "bracket -- restart_check = true only makes the boundary check stricter and " *
                             "cannot clear an already-flagged boundary (#327)"))
    iszero(predictor_variance) ||
        throw(ArgumentError("the 0.9 three-field contract requires predictor_variance = 0"))
    length(fit.beta) == 1 ||
        throw(ArgumentError("the 0.9 three-field contract requires exactly one (Intercept) fixed effect"))

    V_A = Float64(fit.variance_components.sigma_a2)
    isfinite(V_A) && V_A > 0.0 ||
        throw(ArgumentError("the 0.9 three-field contract requires a finite positive sigma_a2"))
    μ = Float64(only(fit.beta))
    isfinite(μ) || throw(ArgumentError("the 0.9 three-field contract requires a finite intercept"))
    components = (V_A = V_A, V_RE = 0.0, V_O = 0.0)
    V_eta_random = components.V_A + components.V_RE + components.V_O

    trials = if fit.family === :binomial
        _three_field_binomial_trials(fit.n_trials, response_length)
    else
        fit.n_trials === nothing ||
            throw(ArgumentError("family :$(fit.family) must transport n_trials = nothing in the 0.9 three-field contract"))
        nothing
    end

    h2_liability, h2_observation, observation_reason = if fit.family === :poisson
        # Eq. 26, written as 1/lambda_bar to avoid an unnecessary intermediate.
        (nothing,
         V_A / (expm1(V_eta_random) + exp(-(μ + V_eta_random / 2))),
         nothing)
    elseif fit.family === :binomial && trials isa AbstractVector &&
           !all(==(first(trials)), trials)
        # A vector denominator has no scalar proportion-scale estimand until its
        # population weighting rule is separately declared.  In particular, do
        # not silently replace it with a mean trial count.
        (V_A / (V_eta_random + _VAR_LOGISTIC),
         NaN,
         "varying_trials_no_scalar_estimand")
    else
        # The ratified Bernoulli/common-trial Binomial data scale is the existing
        # Gauss--Hermite proportion estimand.  `trials` is `nothing` only for
        # Bernoulli, which is the n_trials = 1 special case; a constant trial
        # vector is exactly the common-trial Binomial case, not an averaging rule.
        # An all-one vector is the per-record representation of Bernoulli, so
        # use the same family in the h2 calculation.
        scalar_family = if fit.family === :bernoulli ||
                           (trials isa AbstractVector && all(==(1), trials))
            BernoulliResponse()
        else
            BinomialResponse(trials isa AbstractVector ? first(trials) : trials)
        end
        observation = nongaussian_heritability(V_A, μ, scalar_family).h2_observation
        (V_A / (V_eta_random + _VAR_LOGISTIC), observation, nothing)
    end

    return (
        schema = "nongaussian_three_field_v09",
        family = String(fit.family),
        method = _marginal_method_string(_marginal_method(fit.marginal)),
        loglik = fit.marginal_loglik,
        converged = fit.converged,
        breeding_ids = string.(collect(fit.ids)),
        breeding_values = collect(Float64, fit.breeding_values),
        components = components,
        fixed_effects = (names = ["(Intercept)"], values = [μ]),
        h2_latent = V_A / V_eta_random,
        h2_liability = h2_liability,
        h2_observation = h2_observation,
        h2_observation_undefined_reason = observation_reason,
        n_trials = trials,
    )
end

function _three_field_binomial_trials(
    n_trials::Union{Int,Vector{Int},Nothing},
    response_length::Union{Nothing,Integer},
)
    n_trials === nothing &&
        throw(ArgumentError("family :binomial requires n_trials in the 0.9 three-field contract"))
    if n_trials isa Int
        n_trials > 1 ||
            throw(ArgumentError("family :binomial requires a scalar n_trials greater than one; n_trials = 1 is Bernoulli"))
        return n_trials
    end

    response_length === nothing &&
        throw(ArgumentError("a vector n_trials requires response_length for exact shape validation"))
    response_length > 0 ||
        throw(ArgumentError("response_length must be positive when n_trials is a vector"))
    length(n_trials) == response_length ||
        throw(ArgumentError("vector n_trials must have response_length entries"))
    all(>(0), n_trials) ||
        throw(ArgumentError("vector n_trials must contain only positive integers"))
    return copy(n_trials)
end

"""
    fit_laplace_reml(y, X, Z, Ainv; family = :gaussian, marginal = :laplace,
                     initial = nothing, ids = nothing, iterations = 200,
                     restart_check = false)

Estimate the variance component(s) of the non-Gaussian animal model by maximising
the integrated Laplace objective (`marginal = :laplace`) or the Gaussian
variational objective (`marginal = :variational`) over the variance components.
With fixed effects, non-Gaussian VA adds a Laplace beta correction and is not
guaranteed to be a lower bound; see `variational_marginal_loglik`. `family = :gaussian`
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
`ids`, `converged`, `family`, `marginal`, `boundary`, `restart_estimate`, and the
extractor methods `breeding_values(fit)` / `variance_components(fit)` /
`fixed_effects(fit)`.

**Every family's variance-component search is bounded**, and `converged = true`
alone does NOT mean the estimate is informative: a search that stops on its own
boundary reports a point estimate that is a function of the START VALUE (`initial`),
not the data (#327). `fit.boundary` reports this honestly for every family. Two
mechanisms produce it: a **Brent bracket endpoint** at `exp(log(sa0) ± 6)` — the
single-variance families (`:poisson`, `:bernoulli`, `:binomial`, `:beta_binomial`,
`:bernoulli_probit`) and `:ordered_probit` with `K = 2`, where only `σ²a` is free —
and a **±8-log-unit joint safety rail** around the supplied start, for the
jointly-estimated searches (`:gamma`, `:ordered_probit` with `K ≥ 3`, and now
`:gaussian` and `:nbinom`, which had no rail at all before #327 and gained the one
`:gamma` already used). The five-seed Bernoulli and Binomial recovery runs differ in their observed
`sigma_a2` estimates; that contrast does not establish the cause or a family-wide
search-bound tendency (see `sim/phase6_binomial_recovery.jl`).
`nongaussian_three_field_payload` (private) refuses a `boundary = true` fit.

When supplied, `ids` must contain exactly one unique identifier for each
breeding value (`size(Z, 2)`).

`restart_check = true` (opt-in, doubles the cost of the fit) refits ONCE from a
second start `sa0 * exp(3.0)` (hard-coded `restart_check = false` on that inner
call, so there is no recursion) and compares the two `sigma_a2` point estimates on
the log scale: a gap `> 0.01` sets `boundary = true` even when neither fit landed
exactly on its own rail (the two-start fence itself was sized in the #327 wave-4
campaign comment — 27/27 truncated replicates detected, 0 false positives over 80
replicate pairs — but that measurement used `:poisson` only, a second start of `sa0
* 10` rather than `sa0 * exp(3)`, and a relative rather than a log-scale gap; the
threshold shipped here is the same order of magnitude, not the measured
configuration, and is unmeasured for the other eight families). The second estimate
is exposed in `restart_estimate` (`nothing` when `restart_check = false`). This check
is one-directional (#347): it can only turn `boundary` from `false` to `true`, never
the reverse, so `restart_check = true` cannot clear an already-flagged boundary — it
is a stricter detector, not a fix. The only lever that changes the point estimate
itself is a different `initial`, which recentres the search bracket/rail.

EXPERIMENTAL, dense/validation-scale — the first *fitted* non-Gaussian step. For the
Gaussian family the objective is the exact REML log-likelihood **inside the
±8-log-unit box around the supplied `initial`** that #327 added, so it recovers the
same estimate as [`fit_sparse_reml`](@ref) whenever the optimum lies inside that box
— which the default `initial = (sigma_a2 = 1.0, sigma_e2 = 1.0)` makes `σ² ∈ [e⁻⁸,
e⁸]`. Outside it the search stops on the rail, returns a start-dependent estimate,
and sets `boundary = true`; pass an `initial` on the scale of the data (or read
`fit.boundary`) rather than assuming agreement. Exported as an experimental fitter;
not the public default, not wired into the R formula path, no R model-spec, no
external comparator.
"""
function fit_laplace_reml(y::AbstractVector, X::AbstractMatrix, Z::AbstractMatrix,
                          Ainv::AbstractMatrix; family::Symbol = :gaussian,
                          marginal::Symbol = :laplace, initial = nothing,
                          n_trials = nothing, rho = nothing, ids = nothing,
                          theta_init::Real = 1.0, iterations::Integer = 200,
                          restart_check::Bool = false)
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
    Ainv = _check_relationship_precision(Ainv, size(Z, 2))
    margfun = mm isa Variational ? variational_marginal_loglik : laplace_marginal_loglik
    val(r) = mm isa Variational ? r.elbo : r.loglik
    aids = ids === nothing ? collect(1:size(Z, 2)) : collect(ids)
    length(aids) == size(Z, 2) ||
        throw(ArgumentError("ids must have one identifier per breeding value (length(ids) == size(Z, 2))"))
    length(unique(aids)) == length(aids) ||
        throw(ArgumentError("ids must contain unique identifiers for breeding values"))
    # Shared start value for sigma_a2, used by every branch below AND by the
    # opt-in restart (so the restart's bumped start is anchored to the same
    # `initial` the caller actually supplied).
    sa0 = initial === nothing ? 1.0 : Float64(initial.sigma_a2)
    fit_result = if family === :gaussian
        se0 = initial === nothing ? 1.0 : Float64(initial.sigma_e2)
        (sa0 > 0 && se0 > 0) || throw(ArgumentError("initial variances must be positive"))
        # ±8-log-unit safety rail on BOTH (log σ²a, log σ²e), matching :gamma/:nbinom
        # (#327): an unbounded joint search can otherwise run away with no signal at all.
        lsa0 = log(sa0); lse0 = log(se0)
        function objgs(p)
            (abs(p[1] - lsa0) > 8.0 || abs(p[2] - lse0) > 8.0) && return 1.0e12   # σ²a + σ²e safety rails
            -val(margfun(y, X, Z, Ainv, exp(p[1]), GaussianResponse(exp(p[2]))))
        end
        res = optimize(objgs, log.([sa0, se0]), NelderMead(), Optim.Options(iterations = iterations))
        pmin = Optim.minimizer(res); sa2, se2 = exp.(pmin)
        fit = margfun(y, X, Z, Ainv, sa2, GaussianResponse(se2))
        boundary = abs(pmin[1] - lsa0) >= 8.0 - 1e-6 || abs(pmin[2] - lse0) >= 8.0 - 1e-6
        NonGaussianFit((sigma_a2 = sa2, sigma_e2 = se2), val(fit), fit.beta,
                       marginal === :variational ? fit.m : fit.u, aids,
                       Optim.converged(res) && fit.converged, :gaussian, marginal, nothing, nothing,
                       boundary, nothing)
    elseif family === :nbinom
        # negative-binomial: TWO estimable scalars (sigma_a2 + the overdispersion theta),
        # profiled jointly by NelderMead. Laplace-only (the NB ELBO has no closed form).
        mm isa Laplace ||
            throw(ArgumentError("family = :nbinom supports only marginal = :laplace at this slice (the NB variational ELBO has no closed form); got :$(marginal)"))
        (sa0 > 0 && theta_init > 0) || throw(ArgumentError("initial sigma_a2 and theta_init must be positive"))
        # ±8-log-unit safety rail on BOTH (log σ²a, log θ), matching :gamma (#327): an
        # uninformative design can otherwise run θ to the degenerate Poisson limit.
        lsa0 = log(sa0); lth0 = log(Float64(theta_init))
        function objnb(p)
            (abs(p[1] - lsa0) > 8.0 || abs(p[2] - lth0) > 8.0) && return 1.0e12   # σ²a + θ safety rails
            -laplace_marginal_loglik(y, X, Z, Ainv, exp(p[1]), NegativeBinomialResponse(exp(p[2]))).loglik
        end
        res = optimize(objnb, log.([sa0, Float64(theta_init)]), NelderMead(),
                       Optim.Options(iterations = iterations))
        pmin = Optim.minimizer(res); sa2, theta = exp.(pmin)
        fit = laplace_marginal_loglik(y, X, Z, Ainv, sa2, NegativeBinomialResponse(theta))
        boundary = abs(pmin[1] - lsa0) >= 8.0 - 1e-6 || abs(pmin[2] - lth0) >= 8.0 - 1e-6
        NonGaussianFit((sigma_a2 = sa2, theta = theta), fit.loglik, fit.beta,
                       fit.u, aids, Optim.converged(res) && fit.converged, :nbinom, :laplace, nothing, nothing,
                       boundary, nothing)
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
        boundary = if ndelta == 0                        # K = 2: only σ²a (1-D Brent), θ = [0]
            res = optimize(s -> objord([s]), log(sa0) - 6.0, log(sa0) + 6.0)
            sa2 = exp(Optim.minimizer(res)); thetahat = [0.0]
            abs(log(sa2) - logsa0) >= 6.0 - 1e-6
        else
            res = optimize(objord, vcat(log(sa0), zeros(ndelta)), NelderMead(),
                           Optim.Options(iterations = iterations))
            pmin = Optim.minimizer(res); sa2 = exp(pmin[1]); thetahat = _cuts(pmin[2:end])
            abs(pmin[1] - logsa0) >= 8.0 - 1e-6
        end
        fit = laplace_marginal_loglik(y, X, Z, Ainv, sa2, OrderedProbitResponse(thetahat))
        NonGaussianFit((sigma_a2 = sa2, cutpoints = thetahat), fit.loglik, fit.beta,
                       fit.u, aids, Optim.converged(res) && fit.converged,
                       :ordered_probit, :laplace, nothing, nothing, boundary, nothing)
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
        pmin = Optim.minimizer(res); sa2, shape = exp.(pmin)
        fit = laplace_marginal_loglik(y, X, Z, Ainv, sa2, GammaResponse(shape))
        boundary = abs(pmin[1] - lsa0) >= 8.0 - 1e-6 || abs(pmin[2] - lth0) >= 8.0 - 1e-6
        NonGaussianFit((sigma_a2 = sa2, shape = shape), fit.loglik, fit.beta,
                       fit.u, aids, Optim.converged(res) && fit.converged, :gamma, :laplace, nothing, nothing,
                       boundary, nothing)
    else
        # single-variance-component families: Poisson (log link), Bernoulli/Binomial
        # (logit), and beta-binomial (logit, σ²a estimated at the supplied fixed ρ)
        fam = _resolve_single_family(family, n_trials; rho = rho)
        sa0 > 0 || throw(ArgumentError("initial sigma_a2 must be positive"))
        lsa0 = log(sa0)
        function objsv(s)
            m = try
                margfun(y, X, Z, Ainv, exp(s), fam)
            catch err
                err isa Union{LinearAlgebra.SingularException, LinearAlgebra.PosDefException, DomainError} ?
                    nothing : rethrow(err)
            end
            (m === nothing || !isfinite(val(m))) ? 1.0e12 : -val(m)
        end
        res = optimize(objsv, lsa0 - 6.0, lsa0 + 6.0; iterations = iterations)
        sa2 = exp(Optim.minimizer(res))
        fit = margfun(y, X, Z, Ainv, sa2, fam)
        stored_n = family === :binomial ?
                   (n_trials isa AbstractVector ? Vector{Int}(n_trials) : Int(n_trials)) :
                   family === :beta_binomial ? Int(n_trials) : nothing
        stored_disp = family === :beta_binomial ? Float64(rho) : nothing
        boundary = abs(log(sa2) - lsa0) >= 6.0 - 1e-6
        NonGaussianFit((sigma_a2 = sa2,), val(fit), fit.beta,
                       marginal === :variational ? fit.m : fit.u, aids,
                       Optim.converged(res) && fit.converged, family, marginal,
                       stored_n, stored_disp, boundary, nothing)
    end
    !restart_check && return fit_result
    # Opt-in two-start restart (#327 wave-4): refit ONCE from a second start, hard-coded
    # `restart_check = false` on the inner call so there is no recursion. Compares the
    # two point estimates on the log scale (consistent with the bracket units above);
    # a gap this large means the estimate moved with the start, so flag boundary = true
    # even when neither individual fit landed exactly on its own rail.
    restart_initial = family === :gaussian ?
        (sigma_a2 = sa0 * exp(3.0), sigma_e2 = (initial === nothing ? 1.0 : Float64(initial.sigma_e2))) :
        (sigma_a2 = sa0 * exp(3.0),)
    fit2 = fit_laplace_reml(y, X, Z, Ainv; family = family, marginal = marginal,
                            initial = restart_initial, n_trials = n_trials, rho = rho,
                            ids = ids, theta_init = theta_init, iterations = iterations,
                            restart_check = false)
    sa2_2 = fit2.variance_components.sigma_a2
    boundary2 = fit_result.boundary || abs(log(fit_result.variance_components.sigma_a2) - log(sa2_2)) > 0.01
    return NonGaussianFit(fit_result.variance_components, fit_result.marginal_loglik, fit_result.beta,
                          fit_result.breeding_values, fit_result.ids, fit_result.converged,
                          fit_result.family, fit_result.marginal, fit_result.n_trials,
                          fit_result.dispersion, boundary2, sa2_2)
end

function _laplace_profile_lrt(y, X, Z, Ainv, sigma_a2, family, loglik_hat, cutoff;
                              maxiter::Integer = 100)
    profile = laplace_marginal_loglik(y, X, Z, Ainv, sigma_a2, family; maxiter = maxiter)
    (profile.converged && isfinite(profile.loglik)) ||
        throw(ArgumentError("profile likelihood evaluation failed to converge at sigma_a2 = $sigma_a2"))
    deviance = 2 * (loglik_hat - profile.loglik) - cutoff
    isfinite(deviance) ||
        throw(ArgumentError("profile likelihood evaluation was non-finite at sigma_a2 = $sigma_a2"))
    return deviance
end

"""
    laplace_reml_interval(y, X, Z, Ainv; family = :poisson, marginal = :laplace,
                          level = 0.95, initial = nothing, n_trials = nothing,
                          iterations = 1000)

Profile likelihood-ratio confidence interval for the single-variance-component
non-Gaussian animal-model `sigma_a2`, by inverting the marginal LRT
`2·(ℓ̂ − ℓ(sigma_a2)) ≤ χ²₁,level`. Returns
`(sigma_a2, lower, upper, level, lower_clamped, upper_clamped, converged)` — the
`*_clamped` flags report whether an endpoint reached the search bound (the profile
did not cross the χ² threshold within range) so a non-crossing endpoint is NOT a
confidence limit. A point fit must converge and must not be flagged at its bounded
search rail; otherwise the function throws instead of returning profile endpoints.
Each profile evaluation must also converge and return a finite likelihood. For a
returned interval, `converged` is true for the point fit.

Supports the single-variance-component families `family = :poisson`,
`family = :bernoulli`, `family = :bernoulli_probit`, and `family = :binomial` (which requires `n_trials` — a
scalar common denominator or a per-record integer vector, the same contract as
[`fit_laplace_reml`](@ref)). The Gaussian two-component case needs nuisance
profiling and is future work.

This is a profile-LIKELIHOOD-ratio interval, so `marginal = :laplace` is required:
the variational `:VA` objective (including its Laplace beta correction when fixed
effects are present) is not the marginal log-likelihood, so its differences are not χ²₁-calibrated — `:variational`
throws rather than return an uncalibrated quantity dressed as a CI.

EXPERIMENTAL, asymptotic, single-component only — preliminary coverage
CHARACTERIZATION only (`sim/phase6_nongaussian_interval_coverage.jl`, opt-in,
validation-scale; observed coverage is cell-dependent with both under- and
over-coverage, NOT a calibrated guarantee. Whether
the interval is two-sided depends on where `σ̂²a` sits relative to the flat
near-zero region of the profile, NOT on the family alone: a Binomial fit whose
`σ̂²a` is clear of zero gives two interior LRT roots, but a small `σ̂²a` or the tested binary `:bernoulli` fixture can leave a flat profile so an endpoint reaches the search bound (flagged via `*_clamped`) — honest
but not a confidence limit (the tested binary profile shape does not establish
a general information limit or explain variance-estimation error). Reuses `_profile_root`.
"""
function laplace_reml_interval(y::AbstractVector, X::AbstractMatrix, Z::AbstractMatrix,
                               Ainv::AbstractMatrix; family::Symbol = :poisson,
                               marginal::Symbol = :laplace, level::Real = 0.95,
                               initial = nothing, n_trials = nothing,
                               iterations::Integer = 1000)
    family in (:poisson, :bernoulli, :binomial, :bernoulli_probit) ||
        throw(ArgumentError("laplace_reml_interval supports family = :poisson, :bernoulli, :binomial, or :bernoulli_probit"))
    family === :binomial && n_trials === nothing &&
        throw(ArgumentError("family = :binomial requires the n_trials keyword"))
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1)"))
    iterations > 0 || throw(ArgumentError("iterations must be positive"))
    _marginal_method(marginal) isa Laplace ||
        throw(ArgumentError("laplace_reml_interval is a profile-LIKELIHOOD-ratio interval and requires marginal = :laplace; the variational objective is not a χ²₁-calibrated LRT statistic"))
    if family === :binomial && n_trials isa AbstractVector
        length(n_trials) == length(y) ||
            throw(ArgumentError("a per-record n_trials vector must have length(n_trials) == length(y)"))
        all(isinteger, n_trials) ||
            throw(ArgumentError("a per-record n_trials vector must contain integer trial counts"))
    end
    fam = _resolve_single_family(family, n_trials)
    fit = fit_laplace_reml(y, X, Z, Ainv; family = family, marginal = :laplace,
                           initial = initial, n_trials = n_trials,
                           iterations = iterations)
    fit.converged ||
        throw(ArgumentError("laplace_reml_interval requires a converged point fit"))
    isfinite(fit.marginal_loglik) ||
        throw(ArgumentError("laplace_reml_interval requires a finite point-fit likelihood"))
    fit.boundary &&
        throw(ArgumentError("laplace_reml_interval refuses a point fit flagged at the search boundary"))
    sa2hat = fit.variance_components.sigma_a2
    llhat = fit.marginal_loglik
    z = _standard_normal_quantile((1 + level) / 2)
    q = z * z
    target(sa2) = _laplace_profile_lrt(y, X, Z, Ainv, sa2, fam, llhat, q)
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
#    the theoretical population projection satisfies h²_obs ∈ [0,1] when the
#    observation variance is finite and positive, including zero at V_A = 0.
#    Finite quadrature approximates these population moments. The expectation is
#    over the LINEAR-PREDICTOR distribution η ~ N(μ, V_A + V_fixed) — the π²/3 logit
#    residual is NOT added to this integration variance (it is an observation-process
#    term, not predictor spread; matching de Villemereuil's QGglmm `binom1.logit`).
#  • Estimand per family: PROPORTION for Bernoulli/Binomial, COUNT for Poisson.
# This is asymptotic/validation-scale; the exact decomposition awaits a same-estimand
# QGglmm/MCMCglmm comparator + a Fisher/Falconer review before any promotion.
# Descriptor inputs also arrive through synthetic fits, independently of family constructors.
function _h2_finite_real(value, label; nonnegative::Bool = false, positive::Bool = false)
    value isa Real || throw(ArgumentError("$label must be a real number"))
    isfinite(value) || throw(ArgumentError("$label must be finite"))
    nonnegative && value < 0 && throw(ArgumentError("$label must be nonnegative"))
    positive && value <= 0 && throw(ArgumentError("$label must be positive"))
    converted = Float64(value)
    isfinite(converted) || throw(ArgumentError("$label must be finite after Float64 conversion"))
    nonnegative && converted < 0 && throw(ArgumentError("$label must be nonnegative after Float64 conversion"))
    positive && converted <= 0 && throw(ArgumentError("$label must be positive after Float64 conversion"))
    return converted
end

function _h2_finite_total(values...)
    total = sum(values)
    isfinite(total) || throw(ArgumentError("heritability total variance must be finite in Float64"))
    return total
end

function _h2_trial_int(value)
    value isa Real && isfinite(value) && isinteger(value) && value > 0 && value <= typemax(Int) ||
        throw(ArgumentError("n_trials must contain positive integers representable as Int"))
    return Int(value)
end

function _h2_trials(value)
    if value isa AbstractVector
        isempty(value) && throw(ArgumentError("n_trials must be nonempty"))
        trials = _h2_trial_int.(value)
        return all(==(first(trials)), trials) ? first(trials) : trials
    end
    return _h2_trial_int(value)
end

function _h2_cutpoints(value)
    value === nothing && throw(ArgumentError("nongaussian_heritability for :ordered_probit needs cutpoints"))
    points = collect(value)
    isempty(points) && throw(ArgumentError("ordered-probit cutpoints must be nonempty"))
    converted = [_h2_finite_real(point, "ordered-probit cutpoint") for point in points]
    all(diff(converted) .> 0) || throw(ArgumentError("ordered-probit cutpoints must be strictly increasing after Float64 conversion"))
    return converted
end

function _nongaussian_h2_core(family::Symbol, V_A::Float64, mu::Float64, sigma_e2::Float64,
                              n_trials::Int, V_fixed::Float64, converged::Bool;
                              cutpoints = nothing, shape::Float64 = NaN)
    _h2_finite_real(V_A, "sigma_a2"; nonnegative = true)
    _h2_finite_real(V_fixed, "predictor_variance"; nonnegative = true)
    _h2_finite_real(mu, "mu")
    V_pred = _h2_finite_total(V_A, V_fixed)
    if family === :gaussian
        V_fixed == 0 || throw(ArgumentError("Gaussian heritability is conditional on fixed effects; predictor_variance must be zero"))
        _h2_finite_real(sigma_e2, "sigma_e2"; positive = true)
        total = _h2_finite_total(V_A, sigma_e2)
        h2 = V_A / total
        return (family = :gaussian, sigma_a2 = V_A, mu = mu,
                latent_total_variance = total, h2_latent = h2, h2_observation = h2,
                var_distribution = sigma_e2, var_link = sigma_e2, converged = converged,
                information_limited = false,
                caveat = "Gaussian identity link: conditional on fixed effects; predictor_variance must be zero. Latent and observation scales coincide.",
                method = :gaussian_identity)
    elseif family === :poisson
        V_pred = V_A + V_fixed                       # linear-predictor variance
        λ = exp(mu + V_pred / 2)                      # E[exp η]; Ψ = λ for the log link
        V_A_obs = λ^2 * V_A                           # Ψ²·V_A (Stein)
        V_P_obs = λ^2 * (exp(V_pred) - 1) + λ         # Var(exp η) + E[Poisson var]
        return (family = :poisson, sigma_a2 = V_A, mu = mu, latent_total_variance = V_pred,
                h2_latent = NaN, h2_observation = V_A == 0 ? 0.0 : V_A_obs / V_P_obs,
                var_distribution = λ, var_link = 0.0, converged = converged,
                information_limited = false,
                caveat = "Poisson log link: latent h² is degenerate (no latent residual) → NaN; observation/count scale via the log-normal–Poisson closed form (NS 2017).",
                method = :lognormal_poisson)
    elseif family === :bernoulli || family === :binomial
        V_pred = V_A + V_fixed
        _h2_trial_int(n_trials)
        latent_total = _h2_finite_total(V_pred, _VAR_LOGISTIC)
        p̄ = _gh_expect(_logistic, mu, V_pred)
        Ψ = _gh_expect(η -> (p = _logistic(η); p * (1.0 - p)), mu, V_pred)
        Ep2 = _gh_expect(η -> (p = _logistic(η); p * p), mu, V_pred)
        var_p = Ep2 - p̄^2                             # Var of the mean proportion
        V_A_obs = Ψ^2 * V_A                           # Ψ²·V_A (Stein) ≤ var_p
        var_dist = Ψ / n_trials                       # proportion-scale sampling variance
        info_lim = n_trials == 1
        return (family = family, sigma_a2 = V_A, mu = mu, latent_total_variance = latent_total,
                h2_latent = V_A / latent_total, h2_observation = V_A == 0 ? 0.0 : V_A_obs / (var_p + var_dist),
                var_distribution = var_dist, var_link = _VAR_LOGISTIC, converged = converged,
                information_limited = info_lim,
                caveat = info_lim ?
                    "Single-trial Bernoulli: flagged information_limited; available five-seed results do not establish bias direction or cause, so report this scale with the limitation." :
                    "Binomial logit: observation scale on the PROPORTION estimand via Gauss–Hermite quadrature.",
                method = :logit_quadrature)
    elseif family === :bernoulli_probit || family === :ordered_probit
        # Threshold (probit) family: the LIABILITY scale IS the latent scale, with the
        # probit latent residual V_link = 1 (Dempster–Lerner 1950; doc-19 §2.3). The
        # liability h² = V_A/(V_A + 1 + V_fixed) is the selection-relevant PRIMARY scale;
        # it does NOT depend on μ or the cutpoints (those set the observed incidence, not
        # the liability partition).
        latent_total = _h2_finite_total(V_pred, 1.0)
        V_pred = V_A + V_fixed
        if family === :bernoulli_probit
            # BINARY observed-0/1 scale: QGglmm probit integration over η ~ N(μ, V_A+V_fixed) —
            # p̄ = E[Φ(η)], Ψ = E[φ(η)], h²_obs = Ψ²·V_A/[p̄(1−p̄)] = the Dempster–Lerner transform.
            p̄ = _gh_expect(_norm_cdf, mu, V_pred)
            Ψ = _gh_expect(_norm_pdf, mu, V_pred)
            return (family = :bernoulli_probit, sigma_a2 = V_A, mu = mu, latent_total_variance = latent_total,
                    h2_latent = V_A / latent_total, h2_observation = V_A == 0 ? 0.0 : Ψ^2 * V_A / (p̄ * (1.0 - p̄)),
                    var_distribution = p̄ * (1.0 - p̄), var_link = 1.0, converged = converged,
                    information_limited = true,
                    caveat = "Probit binary threshold: h2_latent is the liability (selection-relevant) scale (V_link = 1, Dempster–Lerner 1950); h2_observation is the observed-0/1 scale via the QGglmm probit integration = the Dempster–Lerner transform z²/[p(1−p)] (verified equal). In the exact finite-moment model, h2_observation is no greater than h2_latent; equal at zero genetic variance. Finite quadrature approximates this ordering. information_limited = true: this flag marks the tested design; available five-seed recovery does not establish a population bias direction or cause for σ²a. Both h² scales inherit uncertainty in σ²a. Plug-in point estimates (no calibrated interval).",
                    method = :probit_liability)
        else
            # ORDINAL (K>2) observed scale — PER-CATEGORY. For each category k the observed
            # indicator 1[y=k] has data-scale h²_k = Ψ_k²·V_A/[p_k(1−p_k)], with the marginal
            # category probability p_k = E[Φ(θ_k−η) − Φ(θ_{k-1}−η)] and Ψ_k = E[φ(θ_{k-1}−η) −
            # φ(θ_k−η)] = E[∂P(y=k|η)/∂η], integrated over η ~ N(μ, V_A+V_fixed) (θ_0=−∞, θ_K=+∞).
            # Returned as the VECTOR `h2_observation_by_category`; the SCALAR `h2_observation` stays
            # NaN (there is no single ordinal observed h²). VALIDATED against QGglmm `model="ordinal"`
            # (`comparator/qgglmm_ordinal_observed/`).
            cutpoints === nothing &&
                throw(ArgumentError("nongaussian_heritability for :ordered_probit needs the cutpoints (from the fit's variance_components.cutpoints or the OrderedProbitResponse family object)"))
            θ = vcat(-Inf, _h2_cutpoints(cutpoints), Inf)   # θ_0 .. θ_K
            K = length(θ) - 1
            h2_by_cat = Vector{Float64}(undef, K)
            p_min = 1.0
            for k in 1:K
                p_k = _gh_expect(η -> _norm_cdf(θ[k+1] - η) - _norm_cdf(θ[k] - η), mu, V_pred)
                Ψ_k = _gh_expect(η -> _norm_pdf(θ[k] - η) - _norm_pdf(θ[k+1] - η), mu, V_pred)
                h2_by_cat[k] = V_A == 0 ? 0.0 : Ψ_k^2 * V_A / (p_k * (1.0 - p_k))
                p_min = min(p_min, p_k)
            end
            return (family = :ordered_probit, sigma_a2 = V_A, mu = mu, latent_total_variance = latent_total,
                    h2_latent = V_A / latent_total, h2_observation = NaN,
                    h2_observation_by_category = h2_by_cat,
                    var_distribution = NaN, var_link = 1.0, converged = converged,
                    information_limited = p_min < 0.05,
                    caveat = "Ordinal probit threshold: h2_latent is the liability (selection-relevant, primary) scale (V_link = 1), which inherits uncertainty in the fitted σ²a (information_limited flags any modelled category with marginal probability < 0.05). The observed scale is PER-CATEGORY — h2_observation_by_category[k] = Ψ_k²V_A/[p_k(1−p_k)] per category indicator (validated vs QGglmm model=ordinal); the scalar h2_observation stays NaN. NOTE: for INTERIOR categories P(y=k|η) is non-monotone in the breeding value, so the per-category value is a Stein first-order estimand that can substantially UNDERSTATE the exact indicator genetic variance — it is DESCRIPTIVE, not an independently selectable heritability; the liability scale is the selection summary. Plug-in point estimates (no calibrated interval).",
                    method = :probit_liability)
        end
    elseif family === :gamma
        # Gamma (log link). LATENT (log) scale: V_link = Var(log Y | η) = ψ₁(shape) (trigamma), EXACT,
        # mean-independent (doc-19 §3.1); NON-degenerate unlike Poisson (V_link = 0).
        # OBSERVATION/DATA scale (the NS-2017 multiplicative form): over η ~ N(μ, V_A+V_fixed),
        # μ = exp(η), Var(y|η) = μ²/ν; Ψ = E[dμ/dη] = E[μ]; V_A,obs = Ψ²·V_A;
        # V_P,obs = Var(μ) + E[μ²/ν]. All lognormal closed forms, so
        # h²_obs = V_A/[e^{V_pred}(1+1/ν) − 1] (μ CANCELS). VALIDATED against QGglmm's custom
        # Gamma model (var.func = μ²/ν) to ~5e-11 (`comparator/qgglmm_gamma_observed/`).
        isnan(shape) && throw(ArgumentError("nongaussian_heritability for :gamma needs the shape ν (from the fit's variance_components.shape or the GammaResponse family object)"))
        _h2_finite_real(shape, "Gamma shape"; positive = true)
        V_link = _trigamma(shape)
        latent_total = _h2_finite_total(V_pred, V_link)
        V_pred = V_A + V_fixed
        Ψ = exp(mu + V_pred / 2)                            # E[dμ/dη] = E[exp η]
        var_mu = (exp(V_pred) - 1.0) * exp(2.0 * mu + V_pred)   # Var(exp η) (lognormal)
        e_var = exp(2.0 * mu + 2.0 * V_pred) / shape        # E[Var(y|η)] = E[μ²/ν]
        h2_obs = V_A == 0 ? 0.0 : Ψ^2 * V_A / (var_mu + e_var)              # = V_A/[e^{V_pred}(1+1/ν) − 1]
        return (family = :gamma, sigma_a2 = V_A, mu = mu, latent_total_variance = latent_total,
                h2_latent = V_A / latent_total, h2_observation = h2_obs,
                var_distribution = e_var, var_link = V_link, converged = converged,
                information_limited = false,
                caveat = "Gamma log link: latent (log) scale V_link = trigamma(shape) = Var(log Y | eta), the log-residual variance (EXACT, doc-19 §3.1); observation/data scale = the NS-2017 multiplicative form V_A/[e^{V_pred}(1+1/ν)−1], validated against QGglmm's custom Gamma model.",
                method = :gamma_trigamma_latent)
    else
        throw(ArgumentError("nongaussian_heritability supports :gaussian/:poisson/:bernoulli/:binomial (observation scale), :bernoulli_probit/:ordered_probit (liability scale), and :gamma (latent/log scale, V_link = trigamma(shape)); family :$family is follow-up (beta-binomial / negative-binomial overdispersion each need their own link-variance derivation)"))
    end
end

_h2_family_params(f::GaussianResponse) = (:gaussian, 1, f.sigma_e2)
_h2_family_params(::PoissonResponse) = (:poisson, 1, NaN)
_h2_family_params(::BernoulliResponse) = (:bernoulli, 1, NaN)
_h2_family_params(f::BinomialResponse) = (:binomial, f.n_trials, NaN)
_h2_family_params(::BernoulliProbitResponse) = (:bernoulli_probit, 1, NaN)
_h2_family_params(::OrderedProbitResponse) = (:ordered_probit, 1, NaN)
_h2_family_params(::GammaResponse) = (:gamma, 1, NaN)   # the shape ν is threaded separately (kwarg)
_h2_family_params(f::ResponseFamily) = throw(ArgumentError("nongaussian_heritability does not support $(typeof(f)) (follow-up: beta-binomial, negative-binomial)"))

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
the theoretical population projection satisfies `h2_observation ∈ [0,1]` when
observation variance is finite and positive, including zero at `V_A = 0`), integrating
over the LINEAR-PREDICTOR distribution
`η ~ N(μ, V_A + V_fixed)` (the π²/3 logit residual is NOT added to the integration
variance) via the module's existing 20-node Gauss–Hermite for logit, which approximates
the population moments, and the
log-normal closed form for Poisson. Estimand: PROPORTION for Bernoulli/Binomial,
COUNT for Poisson; Gaussian reduces to `V_A/(V_A+σ²e)` on both scales. Gaussian uses
this conditional ratio on both scales and requires `predictor_variance = 0`; nonzero
fixed-effect spread is rejected. **Threshold families** (`:bernoulli_probit`, `:ordered_probit`) report the **liability** scale: the
latent scale IS the liability with `V_link = 1` (Dempster–Lerner 1950), the
selection-relevant primary heritability `V_A/(V_A+1+V_fixed)` — returned in `h2_latent`
(independent of μ and the cutpoints). The BINARY `:bernoulli_probit` observed-0/1 scale IS
computed (the QGglmm probit integration `Ψ²V_A/[p̄(1−p̄)]` = the Dempster–Lerner transform,
verified equal); the ORDINAL (K>2) per-category observed scale needs the cutpoints and
stays a follow-up (`h2_observation = NaN`).

`mu` (link-scale population mean) defaults to the fit's single intercept; with >1
fixed effect it is REQUIRED (and `predictor_variance`, the fixed-effect linear-
predictor variance, is the NS "variance explained by fixed effects" term). This is
additional fixed-predictor spread, not total predictor variance. `V_η = V_A + V_fixed`
assumes zero covariance between genetic and fixed contributions and a normal
predictor approximation. The
function REFUSES a non-converged fit; sets `information_limited = true` for the tested single-trial Bernoulli condition; available five-seed evidence does not establish a population bias direction or cause; and returns `h2_observation = NaN`
with a caveat for genuinely varying per-record `n_trials` (a single data-scale h²
is ill-defined under varying denominators). Constant fit trial vectors use their
common scalar trial count.

EXPERIMENTAL, dense/validation-scale; exact in its closed-form limbs and anchored to
an independent quadrature oracle in `test/runtests.jl`, but its estimates inherit uncertainty in latent
σ²a (especially for single-trial Bernoulli); it has a QGglmm external comparator for the
logit + binary-probit observation scales (`comparator/qgglmm_probit_observed/`) but not yet
for the other observation scales / MCMCglmm, nor a Fisher/Falconer sign-off — not the public
default, not covered. Deliberately
NOT added to `nongaussian_result_payload` (that shape stays family-uniform).
"""
function nongaussian_heritability(fit::NonGaussianFit; mu = nothing, n_trials = nothing,
                                  predictor_variance::Real = 0.0)
    fit.converged ||
        throw(ArgumentError("nongaussian_heritability refuses a non-converged fit (converged = false)"))
    V_A = _h2_finite_real(fit.variance_components.sigma_a2, "sigma_a2"; nonnegative = true)
    V_fixed = _h2_finite_real(predictor_variance, "predictor_variance"; nonnegative = true)
    fit.family === :gaussian && predictor_variance != 0 &&
        throw(ArgumentError("Gaussian heritability is conditional on fixed effects; predictor_variance must be zero"))
    μ = if mu !== nothing
        _h2_finite_real(mu, "mu")
    elseif length(fit.beta) == 1
        _h2_finite_real(fit.beta[1], "mu")
    else
        throw(ArgumentError("mu (link-scale population mean) is required: the fit has $(length(fit.beta)) fixed effects, so the intercept is ambiguous — supply `mu` (and `predictor_variance` for the fixed-effect spread)"))
    end
    V_pred = _h2_finite_total(V_A, V_fixed)
    nt = fit.family === :binomial ? _h2_trials(n_trials === nothing ? fit.n_trials : n_trials) : 1
    if fit.family === :binomial && nt isa AbstractVector
        lt = _h2_finite_total(V_pred, _VAR_LOGISTIC)
        return (family = :binomial, sigma_a2 = V_A, mu = μ, latent_total_variance = lt,
                h2_latent = V_A / lt, h2_observation = NaN, var_distribution = NaN,
                var_link = _VAR_LOGISTIC, converged = fit.converged, information_limited = false,
                caveat = "Per-record varying n_trials: a single observation-scale h² is ill-defined under varying denominators → NaN (not silently averaged).",
                method = :logit_quadrature)
    end
    nt_int = if fit.family === :binomial
        nt === nothing && throw(ArgumentError("family = :binomial needs n_trials (from the fit or the keyword)"))
        nt
    else
        1
    end
    σ²e = fit.family === :gaussian ? _h2_finite_real(fit.variance_components.sigma_e2, "sigma_e2"; positive = true) : NaN
    cp = fit.family === :ordered_probit ? fit.variance_components.cutpoints : nothing
    sh = fit.family === :gamma ? _h2_finite_real(fit.variance_components.shape, "Gamma shape"; positive = true) : NaN
    return _nongaussian_h2_core(fit.family, V_A, μ, σ²e, nt_int, V_fixed,
                                fit.converged; cutpoints = cp, shape = sh)
end

function nongaussian_heritability(sigma_a2::Real, mu::Real, family::ResponseFamily;
                                  predictor_variance::Real = 0.0)
    fam_sym, nt, σ²e = _h2_family_params(family)
    cp = family isa OrderedProbitResponse ? family.thresholds : nothing
    sh = family isa GammaResponse ? _h2_finite_real(family.shape, "Gamma shape"; positive = true) : NaN
    V_A = _h2_finite_real(sigma_a2, "sigma_a2"; nonnegative = true)
    μ = _h2_finite_real(mu, "mu")
    V_fixed = _h2_finite_real(predictor_variance, "predictor_variance"; nonnegative = true)
    fam_sym === :gaussian && predictor_variance != 0 &&
        throw(ArgumentError("Gaussian heritability is conditional on fixed effects; predictor_variance must be zero"))
    return _nongaussian_h2_core(fam_sym, V_A, μ, σ²e, nt,
                                V_fixed, true; cutpoints = cp, shape = sh)
end
