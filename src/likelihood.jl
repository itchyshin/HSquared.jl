const DEFAULT_MAX_DENSE_CELLS = 1_000_000

"""
    GaussianLikelihoodResult

Result from evaluating the Gaussian animal-model log-likelihood at supplied
variance components.
"""
struct GaussianLikelihoodResult
    loglik::Float64
    beta::Vector{Float64}
    sigma_a2::Float64
    sigma_e2::Float64
    method::Symbol
    nobs::Int
    nfixed::Int
end

"""
    AnimalModelFit

Experimental low-level Gaussian animal-model fit object.

This is returned only for validated [`AnimalModelSpec`](@ref) inputs. It uses
the current dense likelihood evaluator or sparse REML validation objective and
a conservative optimizer path.
"""
struct AnimalModelFit{TS<:AnimalModelSpec}
    spec::TS
    likelihood::GaussianLikelihoodResult
    variance_components::NamedTuple{(:sigma_a2, :sigma_e2),Tuple{Float64,Float64}}
    converged::Bool
    optimizer_status::String
    iterations::Int
    target::Symbol
    dense_validation_path::Bool
    sparse_mme_path::Bool
    variance_components_source::Symbol
end

function AnimalModelFit(
    spec::AnimalModelSpec,
    likelihood::GaussianLikelihoodResult,
    variance_components::NamedTuple{(:sigma_a2, :sigma_e2),Tuple{Float64,Float64}},
    converged::Bool,
    optimizer_status::AbstractString,
    iterations::Integer,
)
    return AnimalModelFit(
        spec,
        likelihood,
        variance_components,
        converged,
        String(optimizer_status),
        Int(iterations),
        :variance_components,
        true,
        false,
        :estimated_dense_validation,
    )
end

"""
    BreedingValues

Experimental low-level container for animal-effect BLUPs/EBVs.
"""
struct BreedingValues{TID<:AbstractVector}
    ids::TID
    values::Vector{Float64}
end

"""
    HendersonMMEResult

Result from solving Henderson's mixed-model equations at supplied variance
components.

This is a Phase 1 engine utility. It uses sparse design and relationship
precision matrices, but it does not estimate variance components and is not a
production sparse fitting claim by itself.
"""
struct HendersonMMEResult{TS<:AnimalModelSpec,TID<:AbstractVector}
    spec::TS
    beta::Vector{Float64}
    animal_effects::BreedingValues{TID}
    sigma_a2::Float64
    sigma_e2::Float64
end

"""
    gaussian_loglik(spec, sigma_a2, sigma_e2; method = spec.method,
                    max_dense_cells = 1_000_000)

Evaluate the Gaussian ML or REML log-likelihood at supplied variance
components.

This Phase 1 evaluator is deliberately conservative: it forms dense matrices
from the validated `AnimalModelSpec` so the likelihood can be tested before the
production sparse solver lands. It does not optimize variance components and
does not return a fitted model. `max_dense_cells` is a safety guard for this
temporary dense path.
"""
function gaussian_loglik(
    spec::AnimalModelSpec,
    sigma_a2::Real,
    sigma_e2::Real;
    method = spec.method,
    max_dense_cells::Integer = DEFAULT_MAX_DENSE_CELLS,
)
    sigma_a2 > 0 ||
        throw(ArgumentError("sigma_a2 must be positive"))
    sigma_e2 > 0 ||
        throw(ArgumentError("sigma_e2 must be positive"))

    normalized_method = _coerce_method(method)
    normalized_method in (:ML, :REML) ||
        throw(ArgumentError("method must be :ML or :REML"))
    _check_dense_validation_size(spec, max_dense_cells)

    y = Float64.(spec.y)
    X = Matrix{Float64}(spec.X)
    Z = Matrix{Float64}(spec.Z)
    Ainv = Matrix{Float64}(spec.Ainv)

    n = length(y)
    p = size(X, 2)
    normalized_method == :REML && p >= n &&
        throw(ArgumentError("REML requires fewer fixed-effect columns than observations"))

    A = inv(Symmetric(Ainv))
    V = _dense_marginal_covariance(Z, A, sigma_a2, sigma_e2)
    cholV = cholesky(V; check = true)

    Vinv_y = cholV \ y
    Vinv_X = cholV \ X
    XtVinvX = Symmetric(transpose(X) * Vinv_X)
    cholXtVinvX = cholesky(XtVinvX; check = true)
    beta = cholXtVinvX \ (transpose(X) * Vinv_y)

    residual = y - X * beta
    quad = dot(residual, cholV \ residual)
    logdetV = logdet(cholV)

    loglik = if normalized_method == :ML
        -0.5 * (n * log(2 * pi) + logdetV + quad)
    else
        logdetXtVinvX = logdet(cholXtVinvX)
        -0.5 * ((n - p) * log(2 * pi) + logdetV + logdetXtVinvX + quad)
    end

    return GaussianLikelihoodResult(
        loglik,
        beta,
        Float64(sigma_a2),
        Float64(sigma_e2),
        normalized_method,
        n,
        p,
    )
end

"""
    sparse_reml_loglik(spec, sigma_a2, sigma_e2)

Evaluate the Gaussian REML log-likelihood at supplied positive variance
components using the sparse Henderson mixed-model-equation identity.

This is a Phase 1 validation bridge toward the production sparse optimizer. It
does not estimate variance components and it only evaluates REML.
"""
function sparse_reml_loglik(spec::AnimalModelSpec, sigma_a2::Real, sigma_e2::Real)
    sigma_a2 > 0 ||
        throw(ArgumentError("sigma_a2 must be positive"))
    sigma_e2 > 0 ||
        throw(ArgumentError("sigma_e2 must be positive"))

    n = length(spec.y)
    p = size(spec.X, 2)
    p < n ||
        throw(ArgumentError("REML requires fewer fixed-effect columns than observations"))

    lhs, rhs, y_precision_y = _sparse_mme_system(spec, sigma_a2, sigma_e2)
    lhs_factor = cholesky(Symmetric(lhs); check = true)
    solution = lhs_factor \ rhs

    q = size(spec.Ainv, 1)
    Ainv = sparse(Float64.(spec.Ainv))
    Ainv_factor = cholesky(Symmetric(Ainv); check = true)

    logdetR = n * log(Float64(sigma_e2))
    logdetG = q * log(Float64(sigma_a2)) - logdet(Ainv_factor)
    logdetC = logdet(lhs_factor)
    quad = y_precision_y - dot(rhs, solution)
    loglik = -0.5 * ((n - p) * log(2 * pi) + logdetR + logdetG + logdetC + quad)

    return GaussianLikelihoodResult(
        loglik,
        Vector{Float64}(solution[1:p]),
        Float64(sigma_a2),
        Float64(sigma_e2),
        :REML,
        n,
        p,
    )
end

"""
    fit_variance_components(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
                            method = spec.method, iterations = 1_000,
                            max_dense_cells = 1_000_000)

Optimize the dense Gaussian ML/REML objective over positive variance
components.

The optimizer works on log-variance parameters and uses `Optim.NelderMead()`.
This is an experimental Phase 1 path for tiny validation examples. It is not
AI-REML and is not the production sparse solver.
"""
function fit_variance_components(
    spec::AnimalModelSpec;
    initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
    method = spec.method,
    iterations::Integer = 1_000,
    max_dense_cells::Integer = DEFAULT_MAX_DENSE_CELLS,
)
    sigma_a2_start, sigma_e2_start = _coerce_initial_variances(initial)
    sigma_a2_start > 0 ||
        throw(ArgumentError("initial sigma_a2 must be positive"))
    sigma_e2_start > 0 ||
        throw(ArgumentError("initial sigma_e2 must be positive"))

    normalized_method = _coerce_method(method)
    _check_dense_validation_size(spec, max_dense_cells)
    objective(logtheta) = -gaussian_loglik(
        spec,
        exp(logtheta[1]),
        exp(logtheta[2]);
        method = normalized_method,
        max_dense_cells = max_dense_cells,
    ).loglik

    result = optimize(
        objective,
        log.([sigma_a2_start, sigma_e2_start]),
        NelderMead(),
        Optim.Options(iterations = iterations),
    )

    sigma_a2, sigma_e2 = exp.(Optim.minimizer(result))
    likelihood = gaussian_loglik(
        spec,
        sigma_a2,
        sigma_e2;
        method = normalized_method,
        max_dense_cells = max_dense_cells,
    )
    converged = Optim.converged(result)
    status = converged ? "converged" : "not_converged"

    return AnimalModelFit(
        spec,
        likelihood,
        (sigma_a2 = sigma_a2, sigma_e2 = sigma_e2),
        converged,
        status,
        Optim.iterations(result),
    )
end

"""
    fit_sparse_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
                    iterations = 1_000)

Optimize the sparse Gaussian REML validation objective over positive variance
components.

The optimizer works on log-variance parameters and uses
[`sparse_reml_loglik`](@ref) as the objective. This is a Phase 1 validation
path toward sparse fitting. It is REML-only, not AI-REML, not the default
fitting path, and not a production sparse solver.
"""
function fit_sparse_reml(
    spec::AnimalModelSpec;
    initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
    iterations::Integer = 1_000,
)
    spec.method == :REML ||
        throw(ArgumentError("fit_sparse_reml requires spec.method == :REML"))
    sigma_a2_start, sigma_e2_start = _coerce_initial_variances(initial)
    sigma_a2_start > 0 ||
        throw(ArgumentError("initial sigma_a2 must be positive"))
    sigma_e2_start > 0 ||
        throw(ArgumentError("initial sigma_e2 must be positive"))

    function objective(logtheta)
        try
            return -sparse_reml_loglik(
                spec,
                exp(logtheta[1]),
                exp(logtheta[2]),
            ).loglik
        catch err
            err isa PosDefException && return Inf
            rethrow()
        end
    end

    result = optimize(
        objective,
        log.([sigma_a2_start, sigma_e2_start]),
        NelderMead(),
        Optim.Options(iterations = iterations),
    )

    sigma_a2, sigma_e2 = exp.(Optim.minimizer(result))
    likelihood = sparse_reml_loglik(spec, sigma_a2, sigma_e2)
    converged = Optim.converged(result)
    status = converged ? "converged" : "not_converged"

    return AnimalModelFit(
        spec,
        likelihood,
        (sigma_a2 = sigma_a2, sigma_e2 = sigma_e2),
        converged,
        status,
        Optim.iterations(result),
        :sparse_reml,
        false,
        true,
        :estimated_sparse_reml_validation,
    )
end

"""
    fit_eigen_reml(spec; max_dense_n = 20_000)

Estimate the single-effect Gaussian animal-model variance components by a **one-factorization**
eigendecomposition path (the EMMA/GEMMA-style canonical transformation).

`A = Ainv⁻¹` is eigendecomposed **once** (`A = U Λ Uᵀ`; the eigenvectors of `A` are the eigenvectors of
`Ainv` and the eigenvalues are reciprocated), `y` and `X` are rotated by `Uᵀ`, and the REML profile
log-likelihood is then a sum over `n` scalars `σ²a·λᵢ + σ²e` — so every objective evaluation is `O(n)`
with NO mixed-model-equation factorization and NO selected inverse. A 1-D optimisation over the variance
ratio recovers the same optimum as [`fit_ai_reml`](@ref) (validated to ~1e-8).

Because the eigendecomposition is dense `O(n³)` and INDEPENDENT of the pedigree sparsity, this path beats
the sparse AI-REML iteration exactly when the sparse factorization / selected inverse blow up (high fill-in
or poorly-structured pedigrees at moderate `n`) and loses on well-structured pedigrees or large `n` (dense
`n³` + memory). Experimental, REML-only, and restricted to `Z = I` (one record per animal); use
[`fit_ai_reml`](@ref) for the general design or large sparse pedigrees. `max_dense_n` guards the dense path.
"""
function fit_eigen_reml(spec::AnimalModelSpec; max_dense_n::Integer = 20_000)
    spec.method == :REML ||
        throw(ArgumentError("fit_eigen_reml requires spec.method == :REML"))
    n = length(spec.y)
    p = size(spec.X, 2)
    p < n ||
        throw(ArgumentError("REML requires fewer fixed-effect columns than observations"))
    n <= max_dense_n ||
        throw(ArgumentError("fit_eigen_reml densely eigendecomposes A (O(n^3)); n=$n exceeds " *
                            "max_dense_n=$max_dense_n — use fit_ai_reml for large sparse pedigrees"))
    Z = sparse(Float64.(spec.Z))
    Z == sparse(1.0I, n, n) ||
        throw(ArgumentError("fit_eigen_reml requires Z = I (one record per animal); " *
                            "use fit_ai_reml for the general design"))

    # THE one dense factorization: eigen(Ainv). Eigenvectors of A = Ainv⁻¹ are those of Ainv;
    # eigenvalues of A are the reciprocals. Independent of the variance components, so it is done once.
    decomposition = eigen(Symmetric(Matrix(Float64.(spec.Ainv))))
    all(>(0), decomposition.values) ||
        throw(ArgumentError("Ainv must be positive definite"))
    vectors_t = transpose(decomposition.vectors)
    context = (eigenvalues = 1.0 ./ decomposition.values,
               y = vectors_t * Float64.(spec.y),
               X = vectors_t * Matrix(Float64.(spec.X)), n = n, p = p)

    objective(r) = (part = _genomic_profile_reml(context, r); part === nothing ? Inf : -part.loglik)
    result = optimize(objective, 1e-8, 1.0 - 1e-8; abs_tol = 1e-12)
    ratio = Optim.minimizer(result)
    part = _genomic_profile_reml(context, ratio)
    part === nothing &&
        throw(ArgumentError("eigen REML profile is non-finite at the optimum"))
    sigma_a2 = ratio * part.t_hat
    sigma_e2 = (1.0 - ratio) * part.t_hat
    converged = Optim.converged(result)
    likelihood = sparse_reml_loglik(spec, sigma_a2, sigma_e2)

    return AnimalModelFit(
        spec,
        likelihood,
        (sigma_a2 = sigma_a2, sigma_e2 = sigma_e2),
        converged,
        converged ? "converged" : "not_converged",
        Optim.iterations(result),
        :eigen_reml,
        true,
        false,
        :estimated_eigen_reml,
    )
end

# Heuristic route for `fit_animal_model(...; target = :auto)`: choose the eigen-once single-effect
# path (`fit_eigen_reml`) over sparse AI-REML ONLY when it is expected to win — a dense-feasible
# `Z = I` animal model whose MME is HIGH-FILL-IN. Fill is measured by `nnz(L)/n` of the
# (variance-independent) MME Cholesky, NOT by `n`: eigen-once loses on well-structured pedigrees at
# every `n`. Measured crossover (2026-07-24, `docs/dev-log/native-engine-arc/2026-07-24-ai-reml-convergence-findings.md`
# + fill scan): well-structured pedigrees sit at `nnz(L)/n ≈ 17–19` and sparse AI-REML wins; the
# eigen-once path wins on random/high-fill pedigrees at `nnz(L)/n ≥ 76` (n=2000..10000). The
# threshold sits conservatively inside that gap, biased toward the validated sparse default —
# mis-routing to sparse is a modest slowdown, mis-routing to eigen wastes the O(n³) dense path.
# EXPERIMENTAL first-pass heuristic; the exact crossover is a joint fill×n surface (V1-EIGEN-REML).
const _AUTO_EIGEN_FILL_THRESHOLD = 60.0

# F6 route threshold: the fill at which the MATRIX-FREE Monte-Carlo fitter takes over from
# sparse AI-REML past the dense eigen cap. Anchored to the LOWEST fill at which matrix-free was
# MEASURED to win on a single-effect high-fill pedigree — `nnz(L)/n = 150.7` (q=5000: exact
# 24.7 s vs matrix-free 8.8 s = 2.80x, recovering the exact optimum to 4.7e-3). Below that the
# exact path still won at the sizes measured (fill 76.9 → 0.38x). Deliberately conservative and
# biased toward the validated exact default: mis-routing to AI-REML is a slowdown, mis-routing
# to matrix-free buys speed with Monte-Carlo noise in the gradient.
#
# HONEST SCOPE: the 150.7 anchor is measured at n=5000 and EXTRAPOLATED to the n > max_dense_n
# tail this route serves, where the exact path's selected inverse is measured-infeasible anyway
# (q=20 000, fill 471: 1529 s). The true crossover is a joint fill x n surface; mapping it is
# owed work (validation-debt V1-MATFREE-REML), as is a recovery gate at tail scale.
const _AUTO_MATRIX_FREE_FILL_THRESHOLD = 150.0

function _auto_reml_route(spec::AnimalModelSpec;
                          max_dense_n::Integer = 20_000,
                          fill_threshold::Real = _AUTO_EIGEN_FILL_THRESHOLD,
                          matrix_free_fill_threshold::Real = _AUTO_MATRIX_FREE_FILL_THRESHOLD)
    n = length(spec.y)
    # eigen-once is only a candidate for the dense-feasible standard Z = I animal model
    eigen_candidate = n <= max_dense_n && sparse(Float64.(spec.Z)) == sparse(1.0I, n, n)
    # Past the dense cap the eigen rescue is gone, so a high-fill MME has no exact escape: that
    # is the F0-measured tail the matrix-free fitter exists for. Below the cap, keep the
    # previous behaviour exactly — never silently divert a fit the validated exact path handles.
    matrix_free_candidate = n > max_dense_n
    (eigen_candidate || matrix_free_candidate) || return :ai_reml

    lhs, _, _ = _sparse_mme_system(spec, 1.0, 1.0)   # MME sparsity pattern is variance-independent
    factor = try
        cholesky(Symmetric(lhs); check = true)
    catch err
        err isa LinearAlgebra.PosDefException || rethrow(err)
        return :ai_reml                              # indefinite MME → let the sparse path report it
    end
    fill = nnz(sparse(factor.L)) / n
    eigen_candidate && fill > fill_threshold && return :eigen_reml
    matrix_free_candidate && fill > matrix_free_fill_threshold && return :matrix_free_reml
    return :ai_reml
end

"""
    fit_ai_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
                iterations = 100, tol = 1e-8)

Estimate the Phase 1 Gaussian animal-model variance components by
average-information (AI) REML.

Each iteration solves the sparse Henderson mixed-model equations, reads the
variance-component score from the BLUP solution and the Takahashi selected
inverse (the `tr(Ainv * C^uu)` term), forms the average-information matrix from
two working-variate re-solves that reuse the same Cholesky factor, and takes an
AI/Newton step with step-halving to keep the variance components positive.

REML-only and experimental: it is validated to recover the same optimum as the
dense and sparse NelderMead optimizers, but is not yet checked against external
comparators or hardened for boundary/large-pedigree cases. The AI form is exact
for the *Gaussian* linear mixed model (the information matrix uses the data
directly, so it matches the observed information); it does NOT transfer to
Laplace-approximated / non-Gaussian models, where observed-information Newton is
required instead.

An optional **EM-REML warm-start** (`em_warmup`, default `0`) runs that many
EM-REML iterations before the AI/Newton loop. The EM update is the closed form
that zeroes the REML score, so it is monotone and stays strictly inside the
parameter space — a few iterations hand the AI step a good, in-bounds start. On
an *identified* problem this is **optimum-invariant** (the converged estimates are
unchanged) and improves robustness to poor starting values; `em_warmup = 0` is
byte-identical to the pre-warm-start path. It does NOT change the σ²→0 /
non-identified boundary behaviour (there the fit still returns `converged = false`),
and on a non-identified surface the warm-start can shift the non-converged
estimate — read the `converged` flag, not the value.
"""
function fit_ai_reml(
    spec::AnimalModelSpec;
    initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
    iterations::Integer = 100,
    tol::Real = 1e-8,
    em_warmup::Integer = 0,
)
    return _fit_ai_reml_diagnostics(
        spec;
        initial = initial,
        iterations = iterations,
        tol = tol,
        em_warmup = em_warmup,
    ).fit
end

# Instrumented implementation used by the preregistered v0.7 optimizer-
# localization study.  This is deliberately internal: optimizer controls and
# the diagnostics payload are not part of the public R/Julia contract.  The
# public `fit_ai_reml` wrapper above returns only `.fit`, preserving its result
# type and every fitted value while the study can consume counters recorded at
# the point where the corresponding event actually occurs.
function _fit_ai_reml_diagnostics(
    spec::AnimalModelSpec;
    initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
    iterations::Integer = 100,
    tol::Real = 1e-8,
    em_warmup::Integer = 0,
)
    spec.method == :REML ||
        throw(ArgumentError("fit_ai_reml requires spec.method == :REML"))
    sigma_a2, sigma_e2 = _coerce_initial_variances(initial)
    sigma_a2 > 0 || throw(ArgumentError("initial sigma_a2 must be positive"))
    sigma_e2 > 0 || throw(ArgumentError("initial sigma_e2 must be positive"))

    X = Float64.(spec.X)
    Z = sparse(Float64.(spec.Z))
    Ainv = sparse(Float64.(spec.Ainv))
    y = Float64.(spec.y)
    nfixed = size(X, 2)
    nrandom = size(Z, 2)
    nobs = length(y)
    factorizations = 0
    em_steps = 0
    step_halvings = 0
    last_relative_change = NaN
    ai_score_a = NaN
    ai_score_e = NaN
    ai_score_norm = NaN
    termination_reason = "iteration_limit"

    # EM-REML warm-start (Wave F scout lead). The EM update is the closed form that ZEROES the
    # REML score: σ²a = (u'A⁻¹u + tr(A⁻¹C^uu))/q and σ²e = e'e/(n − p − q + tr(A⁻¹C^uu)/σ²a).
    # Both are positive and the step is monotone (it never overshoots), so a few iterations from
    # any start walk safely toward the optimum and hand the AI/Newton loop a good, IN-BOUNDS
    # start — the robustness the AI step alone lacks near the σ²→0 boundary (cf. #182). Each EM
    # iteration reuses the same sparse MME solve the AI loop uses. Opt-in (`em_warmup`, default 0
    # → byte-identical to the pre-warm-start path); the step is taken only while it stays finite
    # and positive, otherwise we stop warming up and let the AI step run.
    for _ in 1:max(0, em_warmup)
        lhs, rhs, _ = _sparse_mme_system(spec, sigma_a2, sigma_e2)
        factorizations += 1
        factor = try
            cholesky(Symmetric(lhs); check = true)
        catch err
            err isa LinearAlgebra.PosDefException && break
            rethrow(err)
        end
        solution = factor \ rhs
        u = solution[(nfixed + 1):end]
        e = y .- X * solution[1:nfixed] .- Z * u
        trace_AC = selinv_trace_against(factor, Ainv, nfixed)
        uAu = dot(u, Ainv * u)
        a_em = (uAu + trace_AC) / nrandom
        e_em = dot(e, e) / (nobs - nfixed - nrandom + trace_AC / sigma_a2)
        (isfinite(a_em) && isfinite(e_em) && a_em > 0 && e_em > 0) || break
        rel = max(abs(a_em - sigma_a2) / sigma_a2, abs(e_em - sigma_e2) / sigma_e2)
        sigma_a2, sigma_e2 = a_em, e_em
        em_steps += 1
        rel < tol && break
    end

    # Per-iteration score-norm + variance-component trajectory (v0.7 optimizer-localization
    # diagnostics). Append-only: the public `fit_ai_reml` wrapper returns only `.fit`, so this
    # adds nothing to the public path. It distinguishes a healthy interior fit (score falls and
    # the relative-change criterion trips within a few iterations) from σ²→0 boundary behaviour
    # (a monotone march to the edge that exhausts step-halving). One row per Newton iteration:
    # (iter, score-norm at the entry σ², σ²a, σ²e, relative change that produced this entry).
    score_trace = Tuple{Int,Float64,Float64,Float64,Float64}[]
    converged = false
    iters = 0
    for it in 1:iterations
        iters = it
        lhs, rhs, _ = _sparse_mme_system(spec, sigma_a2, sigma_e2)
        factorizations += 1
        # Guard the main-loop factorization the same way the EM-warmup loop above does. An
        # indefinite mixed-model-equation coefficient matrix — e.g. from a numerically non-
        # positive-definite supplied precision such as an unblended genomic Ginv — makes
        # cholesky(...; check = true) throw PosDefException. Stop gracefully at the current
        # finite, positive variance components with converged = false (the V1-REML boundary
        # contract), rather than crashing fit_ai_reml with an uncaught exception.
        factor = try
            cholesky(Symmetric(lhs); check = true)
        catch err
            err isa LinearAlgebra.PosDefException || rethrow(err)
            termination_reason = "nonpositive_definite_mme"
            break
        end
        solution = factor \ rhs
        beta = solution[1:nfixed]
        u = solution[(nfixed + 1):end]
        e = y .- X * beta .- Z * u
        trace_AC = selinv_trace_against(factor, Ainv, nfixed)
        uAu = dot(u, Ainv * u)

        score_a = -0.5 / sigma_a2^2 * (nrandom * sigma_a2 - trace_AC - uAu)
        score_e =
            -0.5 / sigma_e2^2 *
            (sigma_e2 * (nobs - nfixed - nrandom + trace_AC / sigma_a2) - dot(e, e))
        ai_score_a = score_a
        ai_score_e = score_e
        ai_score_norm = hypot(score_a, score_e)
        push!(score_trace, (it, ai_score_norm, sigma_a2, sigma_e2, last_relative_change))
        if ai_score_norm < tol
            converged = true
            termination_reason = "score_tolerance"
            break
        end

        wa = (Z * u) ./ sigma_a2
        we = e ./ sigma_e2
        Pwa = _reml_project(factor, X, Z, wa, sigma_e2, nfixed)
        Pwe = _reml_project(factor, X, Z, we, sigma_e2, nfixed)
        information = 0.5 .* [dot(wa, Pwa) dot(wa, Pwe); dot(we, Pwa) dot(we, Pwe)]
        step = _ai_newton_step(information, [score_a, score_e])

        # Defense-in-depth for a genuinely NON-FINITE Newton step (NaN/Inf) from a degenerate
        # AI information matrix: stop at the current finite, positive variance components with
        # `converged = false` — the V1-REML boundary contract ("finite positive ... never
        # NaN") — rather than letting a non-finite step propagate. The SEPARATE case of a
        # *finite* step at the σ²→0 boundary (a step large relative to a tiny σ²a that even 60
        # halvings cannot bring back positive) is NOT handled here — it is caught by the
        # halving-exhaustion `break` just below.
        if !all(isfinite, step)
            termination_reason = "nonfinite_ai_step"
            break
        end

        a_new = sigma_a2 + step[1]
        e_new = sigma_e2 + step[2]
        halvings = 0
        while (a_new <= 0 || e_new <= 0) && halvings < 60
            step = step ./ 2
            a_new = sigma_a2 + step[1]
            e_new = sigma_e2 + step[2]
            halvings += 1
        end
        step_halvings += halvings
        # Step-halving cannot keep the variance components positive: σ has been driven to
        # the σ²→0 boundary on a weakly-identified spec (the finite Newton step is large
        # relative to a tiny σ²a, so even 60 halvings cannot recover a positive a_new). Stop
        # at the current finite, positive σ with converged=false — the V1-REML boundary
        # contract ("finite positive ... never NaN") — rather than throwing, which was an
        # intermittent CI failure on degenerate single-step fixtures.
        if !(a_new > 0 && e_new > 0)
            termination_reason = "step_halving_exhausted"
            break
        end
        # Scale-invariant convergence. The absolute REML score scales with n, so the
        # `hypot(score) < tol` check above becomes unreachable at large q (measured:
        # q=300k ran to the 100-iter cap with σ̂² already at truth). Also stop on the
        # RELATIVE change in the variance components, which is scale-free.
        rel_change = max(abs(a_new - sigma_a2) / sigma_a2, abs(e_new - sigma_e2) / sigma_e2)
        last_relative_change = rel_change
        sigma_a2, sigma_e2 = a_new, e_new
        if rel_change < tol
            converged = true
            termination_reason = "relative_change_tolerance"
            break
        end
    end

    # On the indefinite-MME stop the coefficient matrix is not positive definite at these
    # variance components, so sparse_reml_loglik would itself throw the same PosDefException.
    # Report a NaN loglik alongside the finite, positive variance components and
    # converged = false, instead of crashing; every other path keeps the exact original
    # likelihood computation (byte-identical).
    likelihood = if termination_reason == "nonpositive_definite_mme"
        GaussianLikelihoodResult(NaN, fill(NaN, nfixed), sigma_a2, sigma_e2, :REML, nobs, nfixed)
    else
        sparse_reml_loglik(spec, sigma_a2, sigma_e2)
    end
    status = converged ? "converged" : "not_converged"
    fit = AnimalModelFit(
        spec,
        likelihood,
        (sigma_a2 = sigma_a2, sigma_e2 = sigma_e2),
        converged,
        status,
        iters,
        :ai_reml,
        false,
        true,
        :estimated_ai_reml,
    )
    return (
        fit = fit,
        diagnostics = (
            termination_reason = termination_reason,
            em_steps = em_steps,
            factorizations = factorizations,
            step_halvings = step_halvings,
            last_relative_change = last_relative_change,
            ai_score_a = ai_score_a,
            ai_score_e = ai_score_e,
            ai_score_norm = ai_score_norm,
            score_trace = score_trace,
        ),
    )
end

const _GENOMIC_BOUNDARY_EPSILON = 1e-7
const _GENOMIC_BOUNDARY_GRID_STEP = 0.0025
const _GENOMIC_BOUNDARY_DELTA = 1e-6
const _GENOMIC_BOUNDARY_KKT_TOL = 1e-8
const _GENOMIC_BOUNDARY_MAX_DENSE_N = 2_000
const _GENOMIC_BOUNDARY_DOC46_COMMIT = "fe96a147"
const _GENOMIC_BOUNDARY_DOC46_SHA256 = "283ab00bab3da925f0ac2916959efacaa7fb711c5da4dce09dd49ea568eef030"

function _genomic_boundary_unresolved(ai, reason::AbstractString)
    fit = if ai === nothing
        nothing
    else
        old = ai.fit
        AnimalModelFit(old.spec, old.likelihood, old.variance_components, false,
                       "boundary_unresolved", old.iterations, old.target,
                       old.dense_validation_path, old.sparse_mme_path,
                       old.variance_components_source)
    end
    return (
        fit = fit,
        boundary = (
            status = "boundary_unresolved",
            reason = String(reason),
            profile_ratio = nothing,
            numerical_ratio = nothing,
            boundary_epsilon = _GENOMIC_BOUNDARY_EPSILON,
            profile_loglik = nothing,
            lower_derivative_per_observation = nothing,
            upper_derivative_per_observation = nothing,
        ),
        ai_diagnostics = ai === nothing ? nothing : ai.diagnostics,
    )
end

function _genomic_boundary_precheck(spec::AnimalModelSpec, provenance, kernel)
    n = length(spec.y)
    p = size(spec.X, 2)
    spec.method == :REML || return (ok = false, reason = "non_reml_method")
    n <= _GENOMIC_BOUNDARY_MAX_DENSE_N || return (ok = false, reason = "dense_limit")
    n > p || return (ok = false, reason = "nonpositive_reml_df")
    size(spec.Ainv) == (n, n) || return (ok = false, reason = "precision_dimension")
    size(spec.Z) == (n, n) || return (ok = false, reason = "nonidentity_Z")
    y = try Vector{Float64}(spec.y) catch; return (ok = false, reason = "nonnumeric_y") end
    X = try Matrix{Float64}(spec.X) catch; return (ok = false, reason = "nonnumeric_X") end
    Q = try Matrix{Float64}(spec.Ainv) catch; return (ok = false, reason = "nonnumeric_precision") end
    all(isfinite, y) || return (ok = false, reason = "nonfinite_y")
    all(isfinite, X) || return (ok = false, reason = "nonfinite_X")
    all(isfinite, Q) || return (ok = false, reason = "nonfinite_precision")
    isapprox(Q, transpose(Q); atol = 1e-12, rtol = 0) ||
        return (ok = false, reason = "asymmetric_precision")
    Z = try Matrix{Float64}(spec.Z) catch; return (ok = false, reason = "nonnumeric_Z") end
    all(isfinite, Z) || return (ok = false, reason = "nonfinite_Z")
    maximum(abs, Z .- Matrix{Float64}(I, n, n)) <= 1e-12 ||
        return (ok = false, reason = "nonidentity_Z")
    # Use an explicit, conservative tolerance so fail-closed rank validation is
    # stable across LAPACK versions. The default tolerance classified an exact
    # duplicate fixed-effect column as full rank on Julia 1.10/Linux CI.
    xrank = try
        rank(X; rtol = sqrt(eps(Float64)))
    catch
        return (ok = false, reason = "fixed_effect_rank_failure")
    end
    xrank == p || return (ok = false, reason = "rank_deficient_X")
    qfactor = try
        cholesky(Symmetric(Q); check = true)
    catch
        return (ok = false, reason = "nonpositive_precision")
    end
    provenance isa NamedTuple || return (ok = false, reason = "missing_genomic_provenance")
    required = (:relationship_source, :id_order_fingerprint, :precision_fingerprint)
    all(hasproperty(provenance, key) for key in required) ||
        return (ok = false, reason = "missing_genomic_provenance")
    source = provenance.relationship_source
    source in ("markers", "supplied_Ginv") ||
        return (ok = false, reason = "non_genomic_provenance")
    ids = try
        _canonical_genomic_ids(spec.ids, n)
    catch
        return (ok = false, reason = "invalid_genomic_ids")
    end
    _genomic_id_order_fingerprint(ids) == provenance.id_order_fingerprint ||
        return (ok = false, reason = "id_fingerprint_mismatch")
    _genomic_matrix_fingerprint("Q_lambda", Q, ids) == provenance.precision_fingerprint ||
        return (ok = false, reason = "precision_fingerprint_mismatch")
    K = nothing
    if source == "markers"
        kernel === nothing && return (ok = false, reason = "missing_marker_kernel")
        K = try Matrix{Float64}(kernel) catch
            return (ok = false, reason = "nonnumeric_marker_kernel")
        end
        size(K) == (n, n) || return (ok = false, reason = "kernel_dimension")
        all(isfinite, K) || return (ok = false, reason = "nonfinite_kernel")
        isapprox(K, transpose(K); atol = 1e-12, rtol = 0) ||
            return (ok = false, reason = "asymmetric_kernel")
        hasproperty(provenance, :kernel_fingerprint) ||
            return (ok = false, reason = "missing_kernel_fingerprint")
        _genomic_matrix_fingerprint("K_lambda", K, ids) == provenance.kernel_fingerprint ||
            return (ok = false, reason = "kernel_fingerprint_mismatch")
        maximum(abs, Q * K - Matrix{Float64}(I, n, n)) <= 1e-8 ||
            return (ok = false, reason = "kernel_precision_mismatch")
    end
    return (ok = true, reason = "ok", y = y, X = X, Q = Q, qfactor = qfactor,
            ids = ids, provenance = provenance, K = K)
end

function _genomic_refinement_accepted(converged, minimizer, minimum_value,
                                      lower, upper, incumbent_loglik, n)
    all(isfinite, (minimizer, minimum_value, lower, upper, incumbent_loglik)) || return false
    Bool(converged) || return false
    lower <= minimizer <= upper || return false
    -minimum_value + n * 1e-10 >= incumbent_loglik
end

function _genomic_fd_log_gradient_norm(spec::AnimalModelSpec, sigma_a2, sigma_e2)
    eta = log.([Float64(sigma_a2), Float64(sigma_e2)])
    gradient = zeros(2)
    h = 1e-5
    for j in eachindex(gradient)
        plus = copy(eta); minus = copy(eta)
        plus[j] += h; minus[j] -= h
        lp = sparse_reml_loglik(spec, exp(plus[1]), exp(plus[2])).loglik
        lm = sparse_reml_loglik(spec, exp(minus[1]), exp(minus[2])).loglik
        all(isfinite, (lp, lm)) || return Inf
        gradient[j] = (lp - lm) / (2h)
    end
    norm(gradient) / length(spec.y)
end

function _genomic_eigen_reml(context, sigma_a2::Real, sigma_e2::Real)
    sa = Float64(sigma_a2)
    se = Float64(sigma_e2)
    sa > 0 || throw(ArgumentError("sigma_a2 must be positive"))
    se > 0 || throw(ArgumentError("sigma_e2 must be positive"))
    h = sa .* context.eigenvalues .+ se
    all(isfinite, h) && all(>(0), h) || return nothing
    weights = 1.0 ./ h
    hi_x = weights .* context.X
    hi_y = weights .* context.y
    xt_hi_x = Symmetric(transpose(context.X) * hi_x)
    fixed_factor = try
        cholesky(xt_hi_x; check = true)
    catch
        return nothing
    end
    rhs = transpose(context.X) * hi_y
    beta = fixed_factor \ rhs
    quad = dot(context.y, hi_y) - dot(rhs, beta)
    df = context.n - context.p
    isfinite(quad) && quad > 0 && df > 0 || return nothing
    logdet_v = sum(log, h)
    logdet_fixed = 2sum(log, diag(fixed_factor.U))
    loglik = -0.5 * (df * log(2pi) + logdet_v + logdet_fixed + quad)
    isfinite(loglik) || return nothing
    return GaussianLikelihoodResult(loglik, Vector{Float64}(beta), sa, se,
                                    :REML, context.n, context.p)
end

function _genomic_eigen_fd_log_gradient_norm(context, sigma_a2, sigma_e2)
    eta = log.([Float64(sigma_a2), Float64(sigma_e2)])
    gradient = zeros(2)
    h = 1e-5
    for j in eachindex(gradient)
        plus = copy(eta); minus = copy(eta)
        plus[j] += h; minus[j] -= h
        plus_fit = _genomic_eigen_reml(context, exp(plus[1]), exp(plus[2]))
        minus_fit = _genomic_eigen_reml(context, exp(minus[1]), exp(minus[2]))
        (plus_fit === nothing || minus_fit === nothing) && return Inf
        lp = plus_fit.loglik
        lm = minus_fit.loglik
        all(isfinite, (lp, lm)) || return Inf
        gradient[j] = (lp - lm) / (2h)
    end
    norm(gradient) / context.n
end

function _genomic_profile_context(precheck)
    n = length(precheck.y)
    # Canonicalize both marker and supplied-Q routes through the exact same Q→K
    # numerical path. The marker K was already fingerprinted and checked against
    # Q in precheck; using it here would make the two public routes differ by
    # inversion roundoff on flat profile likelihoods.
    K = Matrix(precheck.qfactor \ Matrix{Float64}(I, n, n))
    K = (K + transpose(K)) / 2
    decomposition = try
        eigen(Symmetric(K))
    catch
        return nothing
    end
    all(isfinite, decomposition.values) && all(>(0), decomposition.values) || return nothing
    vectors_t = transpose(decomposition.vectors)
    return (eigenvalues = decomposition.values, y = vectors_t * precheck.y,
            X = vectors_t * precheck.X, n = n, p = size(precheck.X, 2))
end

function _genomic_boundary_classify_candidates(lower_ll, interior_ll, upper_ll,
                                                distinct_interior, d0, d1, n)
    tie_tol = n * 1e-10
    endpoint_pair_tie = abs(lower_ll - upper_ll) <= tie_tol &&
                        max(lower_ll, upper_ll) + tie_tol >= interior_ll
    lower_interior_tie = distinct_interior && abs(lower_ll - interior_ll) <= tie_tol
    upper_interior_tie = distinct_interior && abs(upper_ll - interior_ll) <= tie_tol
    if !endpoint_pair_tie && !lower_interior_tie &&
       lower_ll + tie_tol >= max(interior_ll, upper_ll) && d0 <= _GENOMIC_BOUNDARY_KKT_TOL
        return (status = "boundary_lower", reason = "likelihood_and_kkt")
    elseif !endpoint_pair_tie && !upper_interior_tie &&
           upper_ll + tie_tol >= max(lower_ll, interior_ll) && d1 >= -_GENOMIC_BOUNDARY_KKT_TOL
        return (status = "boundary_upper", reason = "likelihood_and_kkt")
    elseif distinct_interior && interior_ll - max(lower_ll, upper_ll) > tie_tol &&
           d0 > _GENOMIC_BOUNDARY_KKT_TOL && d1 < -_GENOMIC_BOUNDARY_KKT_TOL
        return (status = "interior_profile", reason = "profile_interior")
    end
    reason = endpoint_pair_tie ? "endpoint_pair_tie" :
             (lower_interior_tie || upper_interior_tie) ? "endpoint_interior_tie" :
             "classification_disagreement"
    return (status = "boundary_unresolved", reason = reason)
end

function _genomic_profile_reml_generic(context, ratio::Real)
    r = Float64(ratio)
    0.0 <= r <= 1.0 || return nothing
    h = r .* context.eigenvalues .+ (1.0 - r)
    all(isfinite, h) && all(>(0), h) || return nothing
    weights = 1.0 ./ h
    hi_x = weights .* context.X
    hi_y = weights .* context.y
    xt_hi_x = Symmetric(transpose(context.X) * hi_x)
    fixed_factor = try
        cholesky(xt_hi_x; check = true)
    catch
        return nothing
    end
    rhs = transpose(context.X) * hi_y
    quad = dot(context.y, hi_y) - dot(rhs, fixed_factor \ rhs)
    df = context.n - context.p
    isfinite(quad) && quad > 0 && df > 0 || return nothing
    t_hat = quad / df
    logdet_h = sum(log, h)
    logdet_fixed = 2sum(log, diag(fixed_factor.U))
    loglik = -0.5 * (df * (1 + log(2pi * t_hat)) + logdet_h + logdet_fixed)
    isfinite(loglik) || return nothing
    return (loglik = loglik, t_hat = t_hat)
end

function _genomic_profile_reml_p1(context, ratio::Real)
    r = Float64(ratio)
    0.0 <= r <= 1.0 || return nothing
    eigenvalues = context.eigenvalues
    x = view(context.X, :, 1)
    y = context.y
    a = 0.0
    b = 0.0
    c = 0.0
    logdet_h = 0.0
    @inbounds for i in eachindex(eigenvalues, x, y)
        h = r * eigenvalues[i] + (1.0 - r)
        isfinite(h) && h > 0 || return nothing
        weight = inv(h)
        xi = x[i]
        yi = y[i]
        a += xi * xi * weight
        b += xi * yi * weight
        c += yi * yi * weight
        logdet_h += log(h)
    end
    isfinite(a) && a > 0 || return nothing
    quad = c - b * b / a
    df = context.n - 1
    isfinite(quad) && quad > 0 && df > 0 || return nothing
    t_hat = quad / df
    loglik = -0.5 * (df * (1 + log(2pi * t_hat)) + logdet_h + log(a))
    isfinite(loglik) || return nothing
    return (loglik = loglik, t_hat = t_hat)
end

function _genomic_profile_reml(context, ratio::Real)
    context.p == 1 ? _genomic_profile_reml_p1(context, ratio) :
                     _genomic_profile_reml_generic(context, ratio)
end

function _genomic_boundary_profile(spec::AnimalModelSpec, precheck)
    n = length(spec.y)
    context = _genomic_profile_context(precheck)
    context === nothing && return (status = "boundary_unresolved", reason = "kernel_provenance_or_eigendecomposition")
    grid = collect(0.0:_GENOMIC_BOUNDARY_GRID_STEP:1.0)
    parts = [_genomic_profile_reml(context, r) for r in grid]
    any(isnothing, parts) && return (status = "boundary_unresolved", reason = "nonfinite_profile")
    values = [part.loglik for part in parts]
    interior_index = argmax(view(values, 2:(length(values) - 1))) + 1
    lower_r, upper_r = grid[interior_index - 1], grid[interior_index + 1]
    refined = try
        optimize(r -> -something(_genomic_profile_reml(context, r), (loglik = -Inf,)).loglik,
                 lower_r, upper_r; abs_tol = 1e-12)
    catch
        return (status = "boundary_unresolved", reason = "refinement_failed")
    end
    refinement = try
        (converged = Optim.converged(refined), minimizer = Optim.minimizer(refined),
         minimum = Optim.minimum(refined))
    catch
        return (status = "boundary_unresolved", reason = "refinement_failed")
    end
    _genomic_refinement_accepted(refinement.converged, refinement.minimizer,
        refinement.minimum, lower_r, upper_r, values[interior_index], n) ||
        return (status = "boundary_unresolved", reason = "refinement_failed")
    interior_r = refinement.minimizer
    interior_part = _genomic_profile_reml(context, interior_r)
    interior_part === nothing && return (status = "boundary_unresolved", reason = "refinement_failed")
    distinct_interior = _GENOMIC_BOUNDARY_EPSILON < interior_r < 1 - _GENOMIC_BOUNDARY_EPSILON
    if !distinct_interior
        interior_r = grid[interior_index]
        interior_part = parts[interior_index]
    end
    lower_part = first(parts)
    upper_part = last(parts)
    delta_lower = _genomic_profile_reml(context, _GENOMIC_BOUNDARY_DELTA)
    delta_upper = _genomic_profile_reml(context, 1 - _GENOMIC_BOUNDARY_DELTA)
    (delta_lower === nothing || delta_upper === nothing) &&
        return (status = "boundary_unresolved", reason = "endpoint_derivative_failed")
    d0 = (delta_lower.loglik - lower_part.loglik) / _GENOMIC_BOUNDARY_DELTA / n
    d1 = (upper_part.loglik - delta_upper.loglik) / _GENOMIC_BOUNDARY_DELTA / n
    classification = _genomic_boundary_classify_candidates(
        lower_part.loglik, interior_part.loglik, upper_part.loglik,
        distinct_interior, d0, d1, n)
    if classification.status == "boundary_lower"
        return (status = "boundary_lower", reason = "likelihood_and_kkt", profile_ratio = 0.0,
                exact = lower_part, d0 = d0, d1 = d1, context = context)
    elseif classification.status == "boundary_upper"
        return (status = "boundary_upper", reason = "likelihood_and_kkt", profile_ratio = 1.0,
                exact = upper_part, d0 = d0, d1 = d1, context = context)
    elseif classification.status == "interior_profile"
        return (status = "interior_profile", reason = "profile_interior", profile_ratio = interior_r,
                exact = interior_part, d0 = d0, d1 = d1, context = context)
    end
    return (status = "boundary_unresolved", reason = classification.reason)
end

function _fit_ai_reml_genomic_boundary(
    spec::AnimalModelSpec;
    provenance,
    kernel = nothing,
    initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
    iterations::Integer = 100,
    tol::Real = 1e-8,
    em_warmup::Integer = 0,
)
    precheck = _genomic_boundary_precheck(spec, provenance, kernel)
    precheck.ok || return _genomic_boundary_unresolved(nothing, precheck.reason)
    ai = _fit_ai_reml_diagnostics(spec; initial = initial, iterations = iterations,
                                  tol = tol, em_warmup = em_warmup)
    profile = _genomic_boundary_profile(spec, precheck)
    profile.status == "boundary_unresolved" &&
        return _genomic_boundary_unresolved(ai, profile.reason)
    if profile.status == "interior_profile"
        ratio_ai = ai.fit.variance_components.sigma_a2 /
                   (ai.fit.variance_components.sigma_a2 + ai.fit.variance_components.sigma_e2)
        oracle_components = (profile.profile_ratio * profile.exact.t_hat,
                             (1 - profile.profile_ratio) * profile.exact.t_hat)
        ai_components = (ai.fit.variance_components.sigma_a2, ai.fit.variance_components.sigma_e2)
        component_ok = all(abs(a - b) <= 1e-8 + 1e-5 * abs(b) for (a, b) in zip(ai_components, oracle_components))
        ratio_ok = abs(ratio_ai - profile.profile_ratio) <= 1e-8 + 1e-5 * abs(profile.profile_ratio)
        objective_ok = abs(ai.fit.likelihood.loglik - profile.exact.loglik) / length(spec.y) <= 1e-8
        gradient_ok = _genomic_eigen_fd_log_gradient_norm(profile.context, ai_components...) <= 1e-8
        if ai.fit.converged && component_ok && ratio_ok && objective_ok && gradient_ok
            return (
                fit = ai.fit,
                boundary = (status = "interior", reason = "ai_interior",
                    profile_ratio = profile.profile_ratio, numerical_ratio = ratio_ai,
                    boundary_epsilon = _GENOMIC_BOUNDARY_EPSILON,
                    profile_loglik = profile.exact.loglik,
                    lower_derivative_per_observation = profile.d0,
                    upper_derivative_per_observation = profile.d1),
                ai_diagnostics = ai.diagnostics,
            )
        end
        sigma_a2, sigma_e2 = oracle_components
        _genomic_eigen_fd_log_gradient_norm(profile.context, sigma_a2, sigma_e2) <= 1e-8 ||
            return _genomic_boundary_unresolved(ai, "interior_profile_gradient")
        likelihood = sparse_reml_loglik(spec, sigma_a2, sigma_e2)
        all(isfinite, (likelihood.loglik, sigma_a2, sigma_e2)) ||
            return _genomic_boundary_unresolved(ai, "interior_profile_nonfinite")
        abs(likelihood.loglik - profile.exact.loglik) / length(spec.y) <= 1e-8 ||
            return _genomic_boundary_unresolved(ai, "interior_profile_objective")
        fit = AnimalModelFit(spec, likelihood, (sigma_a2 = sigma_a2, sigma_e2 = sigma_e2),
                             true, "interior_rescued", ai.fit.iterations, :variance_components,
                             false, true, :estimated_ai_reml)
        return (
            fit = fit,
            boundary = (status = "interior_rescued", reason = "profile_interior",
                profile_ratio = profile.profile_ratio, numerical_ratio = profile.profile_ratio,
                boundary_epsilon = _GENOMIC_BOUNDARY_EPSILON,
                profile_loglik = profile.exact.loglik,
                lower_derivative_per_observation = profile.d0,
                upper_derivative_per_observation = profile.d1),
            ai_diagnostics = ai.diagnostics,
        )
    end
    ratio = profile.profile_ratio
    numerical_ratio = profile.status == "boundary_lower" ? _GENOMIC_BOUNDARY_EPSILON :
                      profile.status == "boundary_upper" ? 1 - _GENOMIC_BOUNDARY_EPSILON : ratio
    sigma_a2 = numerical_ratio * profile.exact.t_hat
    sigma_e2 = (1 - numerical_ratio) * profile.exact.t_hat
    # Preserve the frozen sparse-MME result representation at the two epsilon
    # boundaries. Near r = 1 the two algebraically equivalent forms differ by a
    # few ulps, consistently with cancellation in the determinant identity, so
    # replacing it would change the reported likelihood.
    likelihood = sparse_reml_loglik(spec, sigma_a2, sigma_e2)
    all(isfinite, (likelihood.loglik, sigma_a2, sigma_e2)) ||
        return _genomic_boundary_unresolved(ai, "boundary_representation_nonfinite")
    fit = AnimalModelFit(spec, likelihood, (sigma_a2 = sigma_a2, sigma_e2 = sigma_e2),
                         true, profile.status, ai.fit.iterations, :variance_components,
                         false, true, :estimated_ai_reml)
    return (
        fit = fit,
        boundary = (status = profile.status, reason = profile.status,
                    profile_ratio = ratio, numerical_ratio = numerical_ratio,
                    boundary_epsilon = _GENOMIC_BOUNDARY_EPSILON,
                    profile_loglik = profile.exact.loglik,
                    lower_derivative_per_observation = profile.d0,
                    upper_derivative_per_observation = profile.d1),
        ai_diagnostics = ai.diagnostics,
    )
end

# Apply the REML projection P to a vector via an MME re-solve that reuses
# `factor`: P w = (w - X b_w - Z u_w) / sigma_e2, where [b_w; u_w] solves the
# mixed-model equations with `w` in place of `y`.
function _reml_project(factor, X, Z, w, sigma_e2, nfixed)
    solution =
        factor \ vcat(transpose(X) * w ./ sigma_e2, transpose(Z) * w ./ sigma_e2)
    return (w .- X * solution[1:nfixed] .- Z * solution[(nfixed + 1):end]) ./ sigma_e2
end

# AI/Newton step for the 2x2 average-information matrix (symmetric PSD); ridge
# slightly if it is near-singular so the solve stays stable near a boundary.
function _ai_newton_step(information, score)
    detinfo = information[1, 1] * information[2, 2] - information[1, 2]^2
    scale = abs(information[1, 1]) * abs(information[2, 2]) + 1.0
    matrix = if detinfo <= 1e-12 * scale
        Symmetric(information + 1e-8 * (tr(information) / 2 + 1) * Matrix{Float64}(I, 2, 2))
    else
        Symmetric(information)
    end
    return matrix \ score
end

"""
    henderson_mme(spec, sigma_a2, sigma_e2)

Solve Henderson's mixed-model equations for fixed effects and animal-effect
BLUPs/EBVs at supplied positive variance components.

This forms the sparse equation system
`[X'R^-1X  X'R^-1Z; Z'R^-1X  Z'R^-1Z + Ainv / sigma_a2]` with
`R = sigma_e2 I`. It is a supplied-variance solver and does not optimize
variance components.
"""
function henderson_mme(spec::AnimalModelSpec, sigma_a2::Real, sigma_e2::Real)
    sigma_a2 > 0 ||
        throw(ArgumentError("sigma_a2 must be positive"))
    sigma_e2 > 0 ||
        throw(ArgumentError("sigma_e2 must be positive"))

    lhs, rhs, _ = _sparse_mme_system(spec, sigma_a2, sigma_e2)

    solution = lhs \ rhs
    nfixed = size(spec.X, 2)
    beta = Vector{Float64}(solution[1:nfixed])
    animal_effects = BreedingValues(
        collect(spec.ids),
        Vector{Float64}(solution[(nfixed + 1):end]),
    )

    return HendersonMMEResult(
        spec,
        beta,
        animal_effects,
        Float64(sigma_a2),
        Float64(sigma_e2),
    )
end

"""
    metafounder_animal_model(y, X, Z, pedigree, group_of, Gamma, sigma_a2, sigma_e2;
                             ids = pedigree.ids)

Supplied-variance Gaussian animal-model BLUP under a metafounder-augmented
relationship `A^Γ` (#53, Legarra et al. 2015). Builds the descriptive animal-only
metafounder precision `inv(A^Γ)` via [`metafounder_relationship_inverse`](@ref) and
solves the standard Henderson MME ([`henderson_mme`](@ref)) at supplied variance
components, returning the `HendersonMMEResult`. At `Γ = 0` this reduces EXACTLY to
the classical animal model (`metafounder_relationship_inverse → pedigree_inverse`),
so the fixed effects and EBVs match `henderson_mme` with `pedigree_inverse`.

SUPPLIED-variance and SUPPLIED-`Γ` only — neither `Γ` nor the variance components is
estimated. This is the animal-only BLUP under `A^Γ`; the combined system with
explicit metafounder effects ([`metafounder_inverse`](@ref)) is a separate path, and
there is no R-facing model-spec or bridge payload.
"""
function metafounder_animal_model(y::AbstractVector, X::AbstractMatrix, Z::AbstractMatrix,
        pedigree::Pedigree, group_of, Gamma::AbstractMatrix,
        sigma_a2::Real, sigma_e2::Real; ids = pedigree.ids)
    Ainv = metafounder_relationship_inverse(pedigree, group_of, Gamma)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ids)
    return henderson_mme(spec, sigma_a2, sigma_e2)
end

"""
    two_effect_mme(y, X, Z1, Ainv1, Z2, Ainv2, sigma1, sigma2, sigma_e2;
                   ids1 = nothing, ids2 = nothing)

Supplied-variance Henderson solve of a Gaussian model with **two independent
random effects**:

    y = X·β + Z1·u1 + Z2·u2 + e,
    u1 ~ N(0, sigma1·A1),  u2 ~ N(0, sigma2·A2),  e ~ N(0, sigma_e2·I),

with relationship inverses `Ainv1 = A1⁻¹`, `Ainv2 = A2⁻¹`. The mixed-model
equations carry the block-diagonal precision `blockdiag(Ainv1/sigma1,
Ainv2/sigma2)` for the stacked random effect `[u1; u2]`.

This is the general engine kernel for the standard two-random-effect
quantitative-genetic models: repeatability / permanent environment (`Z2 = Z1`,
`A2 = I`; see [`repeatability_mme`](@ref)), common environment (`Z2` = group
incidence, `A2 = I`), and maternal-environment (`Z2` = dam incidence, `A2 = I`).
Experimental, supplied-variance, engine-internal — it does not estimate variances
and does not cover correlated direct–maternal genetic effects (which need a 2×2
genetic covariance). Returns `(beta, effect1, effect2, variance_components)`.
"""
function two_effect_mme(
    y::AbstractVector,
    X::AbstractMatrix,
    Z1::AbstractMatrix,
    Ainv1::AbstractMatrix,
    Z2::AbstractMatrix,
    Ainv2::AbstractMatrix,
    sigma1::Real,
    sigma2::Real,
    sigma_e2::Real;
    ids1 = nothing,
    ids2 = nothing,
)
    sigma1 > 0 || throw(ArgumentError("sigma1 must be positive"))
    sigma2 > 0 || throw(ArgumentError("sigma2 must be positive"))
    sigma_e2 > 0 || throw(ArgumentError("sigma_e2 must be positive"))
    n = length(y)
    size(X, 1) == n || throw(ArgumentError("X must have one row per record"))
    size(Z1, 1) == n || throw(ArgumentError("Z1 must have one row per record"))
    size(Z2, 1) == n || throw(ArgumentError("Z2 must have one row per record"))
    n1 = size(Ainv1, 1)
    n2 = size(Ainv2, 1)
    size(Ainv1, 2) == n1 || throw(ArgumentError("Ainv1 must be square"))
    size(Ainv2, 2) == n2 || throw(ArgumentError("Ainv2 must be square"))
    size(Z1, 2) == n1 || throw(ArgumentError("Z1 columns must match Ainv1 dimensions"))
    size(Z2, 2) == n2 || throw(ArgumentError("Z2 columns must match Ainv2 dimensions"))
    e1ids = ids1 === nothing ? collect(1:n1) : collect(ids1)
    e2ids = ids2 === nothing ? collect(1:n2) : collect(ids2)
    length(e1ids) == n1 || throw(ArgumentError("ids1 length must match Ainv1 dimensions"))
    length(e2ids) == n2 || throw(ArgumentError("ids2 length must match Ainv2 dimensions"))

    yv = Float64.(y)
    Xs = sparse(Float64.(X))
    Z1s = sparse(Float64.(Z1))
    Z2s = sparse(Float64.(Z2))
    A1 = sparse(Float64.(Ainv1))
    A2 = sparse(Float64.(Ainv2))
    rp = inv(Float64(sigma_e2))
    Zf = hcat(Z1s, Z2s)
    Ginv = blockdiag(A1 .* inv(Float64(sigma1)), A2 .* inv(Float64(sigma2)))
    Xt = transpose(Xs)
    Zft = transpose(Zf)
    nfixed = size(Xs, 2)
    lhs = [
        rp * (Xt * Xs) rp * (Xt * Zf)
        rp * (Zft * Xs) rp * (Zft * Zf) + Ginv
    ]
    rhs = vcat(rp * (Xt * yv), rp * (Zft * yv))
    solution = lhs \ rhs
    beta = Vector{Float64}(solution[1:nfixed])
    u1 = Vector{Float64}(solution[(nfixed + 1):(nfixed + n1)])
    u2 = Vector{Float64}(solution[(nfixed + n1 + 1):(nfixed + n1 + n2)])
    return (
        beta = beta,
        effect1 = (ids = e1ids, values = u1),
        effect2 = (ids = e2ids, values = u2),
        variance_components = (
            sigma1 = Float64(sigma1),
            sigma2 = Float64(sigma2),
            sigma_e2 = Float64(sigma_e2),
        ),
    )
end

"""
    repeatability_mme(y, X, Z, Ainv, sigma_a2, sigma_pe2, sigma_e2; ids = nothing)

Supplied-variance Henderson solve of the repeatability / permanent-environment
animal model with repeated records:

    y = X·β + Z·a + Z·pe + e,
    a ~ N(0, sigma_a2·A),  pe ~ N(0, sigma_pe2·I),  e ~ N(0, sigma_e2·I),

where `Z` is the record→animal incidence (shared by the additive genetic effect
`a` and the permanent-environment effect `pe`), and `Ainv` is the relationship
inverse. The mixed-model equations carry a block-diagonal relationship precision
`blockdiag(Ainv/sigma_a2, I/sigma_pe2)` for the stacked random effect `[a; pe]`.

This is the first Phase-3 (standard quantitative-genetic) engine slice: a
supplied-variance MME solve (it does **not** estimate the variance components),
the analogue of [`henderson_mme`](@ref) for two random effects. Experimental and
engine-internal; the R `permanent()` / repeatability model-spec mapping and REML
estimation of the three variance components are coordinated separately and not
part of this function. Returns a `NamedTuple`
`(beta, animal_effects, permanent_effects, variance_components)`. Identifiability
of `a` vs `pe` requires repeated records (animals with more than one record).
"""
function repeatability_mme(
    y::AbstractVector,
    X::AbstractMatrix,
    Z::AbstractMatrix,
    Ainv::AbstractMatrix,
    sigma_a2::Real,
    sigma_pe2::Real,
    sigma_e2::Real;
    ids = nothing,
)
    na = size(Ainv, 1)
    # repeatability = the two-effect model with the permanent-environment effect
    # sharing Z and carrying an identity relationship (A2 = I).
    result = two_effect_mme(
        y, X, Z, Ainv, Z, sparse(1.0I, na, na),
        sigma_a2, sigma_pe2, sigma_e2; ids1 = ids, ids2 = ids,
    )
    return (
        beta = result.beta,
        animal_effects = result.effect1,
        permanent_effects = result.effect2,
        variance_components = (
            sigma_a2 = Float64(sigma_a2),
            sigma_pe2 = Float64(sigma_pe2),
            sigma_e2 = Float64(sigma_e2),
        ),
    )
end

# Dense REML log-likelihood and BLUPs for a general two-independent-random-effect
# model: V = sigma1·(Z1 A1 Z1') + sigma2·(Z2 A2 Z2') + sigma_e2·I (validation-scale,
# forms the n×n marginal covariance). `A1`, `A2` are dense relationship matrices.
function _two_effect_dense(y, X, Z1, A1, Z2, A2, sigma1, sigma2, sigma_e2)
    n = length(y)
    V = Symmetric(
        sigma1 .* (Z1 * A1 * transpose(Z1)) .+
        sigma2 .* (Z2 * A2 * transpose(Z2)) .+
        sigma_e2 .* Matrix(1.0I, n, n),
    )
    Vf = cholesky(V)
    ViX = Vf \ Matrix(X)
    XtViX = cholesky(Symmetric(transpose(X) * ViX))
    beta = XtViX \ (transpose(X) * (Vf \ y))
    r = y .- X * beta
    Vir = Vf \ r
    loglik = -0.5 * (logdet(Vf) + logdet(XtViX) + dot(r, Vir))
    u1 = sigma1 .* (A1 * (transpose(Z1) * Vir))
    u2 = sigma2 .* (A2 * (transpose(Z2) * Vir))
    return loglik, Vector{Float64}(beta), u1, u2
end

"""
    fit_two_effect_reml(y, X, Z1, Ainv1, Z2, Ainv2; initial, iterations = 200,
                        ids1 = nothing, ids2 = nothing)

REML estimation of the variance components `(sigma1, sigma2, sigma_e2)` of the
general two-independent-random-effect model (see [`two_effect_mme`](@ref)), by
maximizing the dense two-effect REML log-likelihood (NelderMead). Covers
common-environment (`c² = ratio2`) and maternal-environment variance estimation.

Returns a `NamedTuple` with `variance_components`, `ratio1 = sigma1/total`,
`ratio2 = sigma2/total`, `beta`, the two BLUPs, `loglik`, and `converged`.
Experimental, dense/validation-scale, REML-only; uncertainty intervals and the R
model-spec mapping are not part of this function. On small data the optimum can
sit on a boundary (a variance → 0).
"""
function fit_two_effect_reml(
    y::AbstractVector,
    X::AbstractMatrix,
    Z1::AbstractMatrix,
    Ainv1::AbstractMatrix,
    Z2::AbstractMatrix,
    Ainv2::AbstractMatrix;
    initial = (sigma1 = 1.0, sigma2 = 1.0, sigma_e2 = 1.0),
    iterations::Integer = 200,
    ids1 = nothing,
    ids2 = nothing,
)
    initial.sigma1 > 0 && initial.sigma2 > 0 && initial.sigma_e2 > 0 ||
        throw(ArgumentError("initial variance components must be positive"))
    n = length(y)
    size(X, 1) == n || throw(ArgumentError("X must have one row per record"))
    size(Z1, 1) == n || throw(ArgumentError("Z1 must have one row per record"))
    size(Z2, 1) == n || throw(ArgumentError("Z2 must have one row per record"))
    n1 = size(Ainv1, 1)
    n2 = size(Ainv2, 1)
    size(Ainv1, 2) == n1 || throw(ArgumentError("Ainv1 must be square"))
    size(Ainv2, 2) == n2 || throw(ArgumentError("Ainv2 must be square"))
    size(Z1, 2) == n1 || throw(ArgumentError("Z1 columns must match Ainv1 dimensions"))
    size(Z2, 2) == n2 || throw(ArgumentError("Z2 columns must match Ainv2 dimensions"))
    e1ids = ids1 === nothing ? collect(1:n1) : collect(ids1)
    e2ids = ids2 === nothing ? collect(1:n2) : collect(ids2)
    length(e1ids) == n1 || throw(ArgumentError("ids1 length must match Ainv1 dimensions"))
    length(e2ids) == n2 || throw(ArgumentError("ids2 length must match Ainv2 dimensions"))

    A1 = inv(Symmetric(Matrix{Float64}(Ainv1)))
    A2 = inv(Symmetric(Matrix{Float64}(Ainv2)))
    Xd = Matrix{Float64}(X)
    Z1d = Matrix{Float64}(Z1)
    Z2d = Matrix{Float64}(Z2)
    yv = Float64.(y)
    objective(p) = -_two_effect_dense(yv, Xd, Z1d, A1, Z2d, A2, exp(p[1]), exp(p[2]), exp(p[3]))[1]
    p0 = log.([Float64(initial.sigma1), Float64(initial.sigma2), Float64(initial.sigma_e2)])
    result = optimize(objective, p0, NelderMead(), Optim.Options(iterations = iterations))
    sigma1, sigma2, sigma_e2 = exp.(Optim.minimizer(result))
    loglik, beta, u1, u2 = _two_effect_dense(yv, Xd, Z1d, A1, Z2d, A2, sigma1, sigma2, sigma_e2)
    total = sigma1 + sigma2 + sigma_e2
    return (
        variance_components = (sigma1 = sigma1, sigma2 = sigma2, sigma_e2 = sigma_e2),
        ratio1 = sigma1 / total,
        ratio2 = sigma2 / total,
        beta = beta,
        effect1 = (ids = e1ids, values = u1),
        effect2 = (ids = e2ids, values = u2),
        loglik = loglik,
        converged = Optim.converged(result),
    )
end

# One variance ratio `theta[keep_num] / total` and its logit-delta CI from the
# supplied REML observed-information matrix `info` (the central FD Hessian of the
# REML loglik at the optimum, negated). `theta` is the full length-`d` variance
# vector `[σ_1², …, σ_{d-1}², σ_e²]` (`d = 3` for the two-effect model, `d = K+1`
# for the K-effect model) and `keep_num` is the numerator component. Components
# whose variance is a negligible fraction of the total are BOUNDARY components:
# they are dropped from `info` (the interior information conditional on a boundary
# component being fixed at 0 is the corresponding sub-block), so a ratio built on
# a non-boundary numerator (e.g. `ratio1` when only σ2²→0) still gets a valid
# interval — this is what makes the σ2²=0 reduction match `heritability_interval`.
# A ratio whose OWN numerator or whose total-defining denominator is degenerate is
# flagged and returns a NaN CI (never a spuriously tight interval).
function _ratio_delta_ci(info::AbstractMatrix, theta::AbstractVector,
                         keep_num::Integer, level::Real, boundary_tol::Real)
    d = length(theta)
    total = sum(theta)
    ratio = theta[keep_num] / total
    # which of the d components sit on the boundary (σ_i / total ≈ 0)
    on_boundary = [theta[i] / total <= boundary_tol for i in 1:d]
    # the numerator itself at the boundary → the ratio is ≈ 0, no informative CI
    if on_boundary[keep_num]
        return (estimate = ratio, lower = NaN, upper = NaN, se = NaN,
                lower_clamped = false, upper_clamped = false, boundary = true)
    end
    keep = [i for i in 1:d if !on_boundary[i]]
    # need at least the numerator + one other component to define a ratio interval
    if length(keep) < 2
        return (estimate = ratio, lower = NaN, upper = NaN, se = NaN,
                lower_clamped = false, upper_clamped = false, boundary = true)
    end
    sub = Symmetric(Matrix(info)[keep, keep])
    isposdef(sub) ||
        return (estimate = ratio, lower = NaN, upper = NaN, se = NaN,
                lower_clamped = false, upper_clamped = false, boundary = true)
    covar = inv(sub)
    # delta-method gradient of ratio = θ[keep_num]/Σθ wrt the KEPT components only
    subtotal = sum(theta[k] for k in keep)   # == total (dropped comps are ≈ 0)
    g = [k == keep_num ? (subtotal - theta[keep_num]) / subtotal^2 :
                         -theta[keep_num] / subtotal^2 for k in keep]
    se = sqrt(max(dot(g, covar * g), 0.0))
    (0 < ratio < 1 && isfinite(se) && se > 0) ||
        return (estimate = ratio, lower = NaN, upper = NaN, se = se,
                lower_clamped = false, upper_clamped = false, boundary = true)
    z = _standard_normal_quantile((1 + level) / 2)
    eta = log(ratio / (1 - ratio))
    se_eta = se / (ratio * (1 - ratio))
    lower = 1 / (1 + exp(-(eta - z * se_eta)))
    upper = 1 / (1 + exp(-(eta + z * se_eta)))
    # logit keeps endpoints in (0, 1); flag if they reach the numerical rails
    return (estimate = ratio, lower = lower, upper = upper, se = se,
            lower_clamped = lower <= 1e-6, upper_clamped = upper >= 1 - 1e-6,
            boundary = false)
end

# Observed REML information = −Hessian of the REML loglik `f` at the variance
# vector `theta` (length `d`), by central finite differences with a
# component-relative step `fd_step · max(|θ_i|, 1e-3)`. Shared by the two-effect
# and K-effect ratio-interval paths.
function _reml_fd_information(f, theta::AbstractVector, fd_step::Real)
    d = length(theta)
    h = fd_step .* max.(abs.(theta), 1e-3)
    H = zeros(d, d)
    for i in 1:d, j in 1:d
        ei = zeros(d); ei[i] = h[i]
        ej = zeros(d); ej[j] = h[j]
        H[i, j] = (f(theta + ei + ej) - f(theta + ei - ej) -
                   f(theta - ei + ej) + f(theta - ei - ej)) / (4 * h[i] * h[j])
    end
    return Symmetric(-H)
end

"""
    two_effect_ratio_interval(y, X, Z1, Ainv1, Z2, Ainv2; level = 0.95,
                              which = :both, initial = ..., iterations = 200,
                              ids1 = nothing, ids2 = nothing, fd_step = 1e-4,
                              boundary_tol = 1e-6)

Asymptotic delta-method confidence interval(s) for the variance ratios of the
general two-effect REML model ([`fit_two_effect_reml`](@ref)):

    ratio1 = σ1² / (σ1² + σ2² + σe²),   ratio2 = σ2² / (σ1² + σ2² + σe²)

(e.g. `h²` and `c²` / `m²` for a common-environment / maternal model). Fits by
REML, forms the observed information as the central finite-difference Hessian of
the two-effect REML log-likelihood (`_two_effect_dense`) at the optimum, and
applies the delta method on the logit scale (so each interval lies in
`(0, 1)`) — the same machinery as [`repeatability_interval`](@ref) and
[`heritability_interval`](@ref) `method = :delta`.

`which` selects which ratio(s) to build an interval for (`:both`, `:ratio1`, or
`:ratio2`); the unrequested ratio still reports its point `estimate` with a `NaN`
interval. Returns a `NamedTuple` `(ratio1, ratio2, level, converged)` where each
of `ratio1`/`ratio2` is `(estimate, lower, upper, se, lower_clamped,
upper_clamped, boundary)`.

Boundary honesty: when a component sits on the variance boundary (σ → 0, i.e.
`σ_i / total ≤ boundary_tol`) the ratio built on it is flagged `boundary = true`
with a `NaN` interval — never a spuriously tight CI. A ratio built on a
non-boundary numerator drops the degenerate component and uses the corresponding
information sub-block (the interior information conditional on the boundary
component being fixed at 0), so e.g. `ratio1` remains well-defined when only
`σ2² → 0`; in that reduction it recovers [`heritability_interval`](@ref) on the
underlying animal model. `converged` is carried from the REML fit.

Experimental, asymptotic, delta-method, REML only; the interval is a large-sample
approximation and is NOT coverage-calibrated — on small samples the REML surface
is flat and the interval is unreliable (the parametric bootstrap,
`bootstrap_variance_component_interval`, is the only finite-sample-aware path). No
calibrated coverage is claimed.
"""
function two_effect_ratio_interval(
    y::AbstractVector, X::AbstractMatrix, Z1::AbstractMatrix, Ainv1::AbstractMatrix,
    Z2::AbstractMatrix, Ainv2::AbstractMatrix;
    level::Real = 0.95, which::Symbol = :both,
    initial = (sigma1 = 1.0, sigma2 = 1.0, sigma_e2 = 1.0),
    iterations::Integer = 200, ids1 = nothing, ids2 = nothing,
    fd_step::Real = 1e-4, boundary_tol::Real = 1e-6,
)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1)"))
    which in (:both, :ratio1, :ratio2) ||
        throw(ArgumentError("which must be :both, :ratio1, or :ratio2"))
    fit = fit_two_effect_reml(y, X, Z1, Ainv1, Z2, Ainv2;
                              initial = initial, iterations = iterations,
                              ids1 = ids1, ids2 = ids2)
    vc = fit.variance_components
    theta = [vc.sigma1, vc.sigma2, vc.sigma_e2]

    A1 = inv(Symmetric(Matrix{Float64}(Ainv1)))
    A2 = inv(Symmetric(Matrix{Float64}(Ainv2)))
    Xd = Matrix{Float64}(X); Z1d = Matrix{Float64}(Z1); Z2d = Matrix{Float64}(Z2)
    yv = Float64.(y)
    loglik(t) = _two_effect_dense(yv, Xd, Z1d, A1, Z2d, A2, t[1], t[2], t[3])[1]

    # observed information = −Hessian of the REML loglik (central finite differences)
    info = _reml_fd_information(loglik, theta, fd_step)

    na_ci = (estimate = NaN, lower = NaN, upper = NaN, se = NaN,
             lower_clamped = false, upper_clamped = false, boundary = false)
    r1 = which === :ratio2 ? merge(na_ci, (estimate = fit.ratio1,)) :
         _ratio_delta_ci(info, theta, 1, level, boundary_tol)
    r2 = which === :ratio1 ? merge(na_ci, (estimate = fit.ratio2,)) :
         _ratio_delta_ci(info, theta, 2, level, boundary_tol)
    return (ratio1 = r1, ratio2 = r2, level = level, converged = fit.converged)
end

"""
    multi_effect_mme(y, X, effects, sigmas, sigma_e2; ids = nothing)

Supplied-variance Henderson solve of the general model with an ARBITRARY number
`K` of independent random effects — the `K`-block generalization of
[`two_effect_mme`](@ref):

    y = X·β + Σ_{i=1}^{K} Z_i·u_i + e,
    u_i ~ N(0, sigma_i·A_i),  e ~ N(0, sigma_e2·I),

where `effects` is a vector of `(Z_i, Ainv_i)` pairs (`Z_i` the `n×q_i`
record→level incidence, `Ainv_i` the `q_i×q_i` relationship precision — pass
`I` for a plain i.i.d. `(1|group)` effect), `sigmas[i]` the variance of effect
`i`, and `sigma_e2 > 0`. The stacked random precision is
`blockdiag(A_1/σ_1, …, A_K/σ_K)` over `[u_1; …; u_K]` and the random design is
`hcat(Z_1, …, Z_K)`, exactly as the two-effect kernel. `ids` may be `nothing`
or a length-`K` vector of per-effect id vectors.

Returns `(beta, effects = [(ids, values), …], variance_components =
(sigmas, sigma_e2))`. The `K=2` case is byte-identical to [`two_effect_mme`](@ref).
Experimental, supplied-variance, engine-internal — it does not estimate variances
and does not cover correlated effects (a 2×2 direct–maternal `G` needs
`kron(inv(G), Ainv)`, a different structure).
"""
function multi_effect_mme(
    y::AbstractVector,
    X::AbstractMatrix,
    effects::AbstractVector,
    sigmas::AbstractVector,
    sigma_e2::Real;
    ids = nothing,
)
    K = length(effects)
    K >= 1 || throw(ArgumentError("at least one random effect is required"))
    length(sigmas) == K || throw(ArgumentError("sigmas length must match number of effects"))
    all(s -> s > 0, sigmas) || throw(ArgumentError("all sigmas must be positive"))
    sigma_e2 > 0 || throw(ArgumentError("sigma_e2 must be positive"))
    n = length(y)
    size(X, 1) == n || throw(ArgumentError("X must have one row per record"))
    Zs = SparseMatrixCSC{Float64,Int}[]
    Ainvs = SparseMatrixCSC{Float64,Int}[]
    qs = Int[]
    for (i, pair) in enumerate(effects)
        Zi, Ainvi = pair
        size(Zi, 1) == n || throw(ArgumentError("Z[$i] must have one row per record"))
        qi = size(Ainvi, 1)
        size(Ainvi, 2) == qi || throw(ArgumentError("Ainv[$i] must be square"))
        size(Zi, 2) == qi || throw(ArgumentError("Z[$i] columns must match Ainv[$i] dimensions"))
        push!(Zs, sparse(Float64.(Zi)))
        push!(Ainvs, sparse(Float64.(Ainvi)))
        push!(qs, qi)
    end
    if ids === nothing
        eids = [collect(1:qi) for qi in qs]
    else
        length(ids) == K || throw(ArgumentError("ids must be a length-$K vector of per-effect id vectors"))
        eids = [collect(ids[i]) for i in 1:K]
        for i in 1:K
            length(eids[i]) == qs[i] || throw(ArgumentError("ids[$i] length must match Ainv[$i] dimensions"))
        end
    end
    yv = Float64.(y)
    Xs = sparse(Float64.(X))
    rp = inv(Float64(sigma_e2))
    Zf = reduce(hcat, Zs)
    Ginv = blockdiag((Ainvs[i] .* inv(Float64(sigmas[i])) for i in 1:K)...)
    Xt = transpose(Xs)
    Zft = transpose(Zf)
    nfixed = size(Xs, 2)
    lhs = [
        rp * (Xt * Xs) rp * (Xt * Zf)
        rp * (Zft * Xs) rp * (Zft * Zf) + Ginv
    ]
    rhs = vcat(rp * (Xt * yv), rp * (Zft * yv))
    solution = lhs \ rhs
    beta = Vector{Float64}(solution[1:nfixed])
    effects_out = Vector{NamedTuple{(:ids, :values)}}(undef, K)
    off = nfixed
    for i in 1:K
        u = Vector{Float64}(solution[(off + 1):(off + qs[i])])
        effects_out[i] = (ids = eids[i], values = u)
        off += qs[i]
    end
    return (
        beta = beta,
        effects = effects_out,
        variance_components = (sigmas = Float64.(collect(sigmas)), sigma_e2 = Float64(sigma_e2)),
    )
end

# Dense REML log-likelihood and BLUPs for a general K-independent-random-effect
# model: V = Σ_i sigma_i·(Z_i A_i Z_i') + sigma_e2·I (validation-scale, forms the
# n×n marginal covariance). The genetic terms accumulate first, then the residual
# is added last, matching `_two_effect_dense`'s associativity so the K=2 case is
# byte-identical. `ZAs` is a vector of dense `(Z_i, A_i)` pairs.
function _multi_effect_dense(y, X, ZAs, sigmas, sigma_e2)
    n = length(y)
    K = length(ZAs)
    Vacc = zeros(n, n)
    for i in 1:K
        Zi, Ai = ZAs[i]
        Vacc = Vacc .+ sigmas[i] .* (Zi * Ai * transpose(Zi))
    end
    V = Symmetric(Vacc .+ sigma_e2 .* Matrix(1.0I, n, n))
    Vf = cholesky(V)
    ViX = Vf \ Matrix(X)
    XtViX = cholesky(Symmetric(transpose(X) * ViX))
    beta = XtViX \ (transpose(X) * (Vf \ y))
    r = y .- X * beta
    Vir = Vf \ r
    loglik = -0.5 * (logdet(Vf) + logdet(XtViX) + dot(r, Vir))
    us = [sigmas[i] .* (ZAs[i][2] * (transpose(ZAs[i][1]) * Vir)) for i in 1:K]
    return loglik, Vector{Float64}(beta), us
end

"""
    fit_multi_effect_reml(y, X, effects; initial = nothing, iterations = 200,
                          ids = nothing, max_dense_cells = 1_000_000)

REML estimation of the `K+1` variance components `(sigmas..., sigma_e2)` of the
general `K`-independent-random-effect model (see [`multi_effect_mme`](@ref)), by
maximizing the dense REML log-likelihood (`NelderMead` over `K+1` log-variances).
`effects` is a vector of `(Z_i, Ainv_i)` pairs; `initial`, if supplied, is a
length-`K+1` vector of positive starting variances (`[σ_1, …, σ_K, σ_e2]`),
otherwise all start at 1.

Returns a `NamedTuple` with `variance_components = (sigmas, sigma_e2)`, per-effect
`ratios`, `beta`, the `K` BLUPs (`effects = [(ids, values), …]`), `loglik`,
`converged`, and per-component `boundary` flags (`σ_i / total < 1e-6`).

Reductions: the `K=1` fit recovers the univariate animal-model REML optimum, and
the `K=2` fit is byte-identical to [`fit_two_effect_reml`](@ref) on identified
data. EXPERIMENTAL, dense/validation-scale, REML-only, Gaussian, INDEPENDENT
effects only (no correlated / direct–maternal covariance). The dense path forms
an `n×n` `V` (guarded by `max_dense_cells`); it is an oracle for small `K`
(≲4) and `n` (≲2000), NOT a production sparse estimator — that is the owed sparse
AI-REML `K`-component path. On small/uninformative data the optimum can sit on a
boundary (a variance → 0), reported via `converged` / `boundary`, never hidden.
Non-identifiability (e.g. two `A=I` effects on the same grouping) shows as a flat
ridge (`converged = false`); the engine reports it, it does not certify
identifiability.
"""
function fit_multi_effect_reml(
    y::AbstractVector,
    X::AbstractMatrix,
    effects::AbstractVector;
    initial = nothing,
    iterations::Integer = 200,
    ids = nothing,
    max_dense_cells::Integer = DEFAULT_MAX_DENSE_CELLS,
)
    K = length(effects)
    K >= 1 || throw(ArgumentError("at least one random effect is required"))
    n = length(y)
    size(X, 1) == n || throw(ArgumentError("X must have one row per record"))
    n * n <= max_dense_cells ||
        throw(ArgumentError("dense N-effect REML would form an $(n)×$(n) covariance " *
            "($(n * n) cells) exceeding max_dense_cells=$(max_dense_cells)"))
    As = Matrix{Float64}[]
    Zds = Matrix{Float64}[]
    qs = Int[]
    for (i, pair) in enumerate(effects)
        Zi, Ainvi = pair
        size(Zi, 1) == n || throw(ArgumentError("Z[$i] must have one row per record"))
        qi = size(Ainvi, 1)
        size(Ainvi, 2) == qi || throw(ArgumentError("Ainv[$i] must be square"))
        size(Zi, 2) == qi || throw(ArgumentError("Z[$i] columns must match Ainv[$i] dimensions"))
        push!(As, inv(Symmetric(Matrix{Float64}(Ainvi))))
        push!(Zds, Matrix{Float64}(Zi))
        push!(qs, qi)
    end
    if initial === nothing
        p0 = zeros(K + 1)
    else
        length(initial) == K + 1 ||
            throw(ArgumentError("initial must have length K+1 = $(K + 1) (one per effect plus residual)"))
        all(s -> s > 0, initial) || throw(ArgumentError("initial variance components must be positive"))
        p0 = log.(Float64.(collect(initial)))
    end
    yv = Float64.(y)
    Xd = Matrix{Float64}(X)
    ZAs = [(Zds[i], As[i]) for i in 1:K]
    function objective(p)
        sigmas = exp.(p[1:K])
        se2 = exp(p[K + 1])
        try
            val = -_multi_effect_dense(yv, Xd, ZAs, sigmas, se2)[1]
            return isfinite(val) ? val : Inf
        catch err
            (err isa PosDefException || err isa SingularException) && return Inf
            rethrow()
        end
    end
    result = optimize(objective, p0, NelderMead(), Optim.Options(iterations = iterations))
    popt = exp.(Optim.minimizer(result))
    sigmas = popt[1:K]
    se2 = popt[K + 1]
    loglik, beta, us = _multi_effect_dense(yv, Xd, ZAs, sigmas, se2)
    total = sum(sigmas) + se2
    eids = ids === nothing ? [collect(1:qs[i]) for i in 1:K] : [collect(ids[i]) for i in 1:K]
    effects_out = [(ids = eids[i], values = us[i]) for i in 1:K]
    return (
        variance_components = (sigmas = sigmas, sigma_e2 = se2),
        ratios = sigmas ./ total,
        beta = beta,
        effects = effects_out,
        loglik = loglik,
        converged = Optim.converged(result),
        iterations = Optim.iterations(result),
        f_calls = Optim.f_calls(result),
        boundary = [s / total < 1e-6 for s in sigmas],
    )
end

"""
    multi_effect_ratio_interval(y, X, effects; level = 0.95, which = :all,
                                initial = nothing, iterations = 200,
                                ids = nothing, fd_step = 1e-4,
                                boundary_tol = 1e-6)

Asymptotic delta-method confidence interval(s) for the per-component variance
ratios of the general `K`-independent-random-effect REML model
([`fit_multi_effect_reml`](@ref)) — the `K`-component generalization of
[`two_effect_ratio_interval`](@ref):

    ratio_i = σ_i² / (Σ_{j=1}^{K} σ_j² + σ_e²),   i = 1, …, K.

Fits by REML, forms the observed information as the central finite-difference
Hessian of the `K`-effect REML log-likelihood (`_multi_effect_dense`) over the
`K+1` variances at the optimum, and applies the delta method on the logit scale
(so each interval lies in `(0, 1)`) — the SAME machinery as
[`two_effect_ratio_interval`](@ref) / [`heritability_interval`](@ref)
`method = :delta`, sharing the finite-difference information and per-ratio
logit-delta helper.

`which` selects which component(s) to build an interval for: `:all` (default,
all `K`) or an integer `1 ≤ i ≤ K` (only component `i`; the others report their
point `estimate` with a `NaN` interval). Returns a `NamedTuple`
`(ratios, level, converged)` where `ratios` is a length-`K` vector of
`(estimate, lower, upper, se, lower_clamped, upper_clamped, boundary)`.

Boundary honesty (identical to the two-effect path): a component on the variance
boundary (σ_i / total ≤ `boundary_tol`) is flagged `boundary = true` with a `NaN`
interval — never a spuriously tight CI. A ratio built on a non-boundary numerator
drops the degenerate component(s) and uses the corresponding information sub-block
(the interior information conditional on the boundary component fixed at 0), so a
well-identified component keeps a valid interval even when another collapses.

Reductions: at `K = 2` this matches [`two_effect_ratio_interval`](@ref) (same
finite-difference information, same estimand); at `K = 1` it matches
[`heritability_interval`](@ref) `method = :delta` up to the finite-difference vs
analytic-AI information difference (same estimand, different information
estimator — a few-percent endpoint difference, not machine precision).

Experimental, asymptotic, delta-method, dense/validation-scale, REML only,
Gaussian, INDEPENDENT effects only (no correlated / direct–maternal covariance);
the dense path forms an `n×n` `V`. The interval is a large-sample approximation
and is NOT coverage-calibrated — on small samples the REML surface is flat and the
interval is unreliable (the parametric bootstrap,
`bootstrap_variance_component_interval`, is the only finite-sample-aware path). No
calibrated coverage is claimed.
"""
function multi_effect_ratio_interval(
    y::AbstractVector, X::AbstractMatrix, effects::AbstractVector;
    level::Real = 0.95, which::Union{Symbol,Integer} = :all,
    initial = nothing, iterations::Integer = 200, ids = nothing,
    fd_step::Real = 1e-4, boundary_tol::Real = 1e-6,
)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1)"))
    K = length(effects)
    K >= 1 || throw(ArgumentError("at least one random effect is required"))
    if which isa Symbol
        which === :all ||
            throw(ArgumentError("which must be :all or an integer component index 1..$K"))
    else
        1 <= which <= K ||
            throw(ArgumentError("which must be :all or an integer component index 1..$K"))
    end

    fit = fit_multi_effect_reml(y, X, effects; initial = initial,
                                iterations = iterations, ids = ids)
    sigmas = fit.variance_components.sigmas
    se2 = fit.variance_components.sigma_e2
    theta = vcat(collect(sigmas), se2)        # [σ_1², …, σ_K², σ_e²], length K+1

    As = [inv(Symmetric(Matrix{Float64}(pair[2]))) for pair in effects]
    Zds = [Matrix{Float64}(pair[1]) for pair in effects]
    ZAs = [(Zds[i], As[i]) for i in 1:K]
    Xd = Matrix{Float64}(X); yv = Float64.(y)
    loglik(t) = _multi_effect_dense(yv, Xd, ZAs, t[1:K], t[K + 1])[1]

    # observed information = −Hessian of the K-effect REML loglik (central FD),
    # shared with the two-effect path
    info = _reml_fd_information(loglik, theta, fd_step)

    na_ci = (estimate = NaN, lower = NaN, upper = NaN, se = NaN,
             lower_clamped = false, upper_clamped = false, boundary = false)
    ratios = Vector{typeof(na_ci)}(undef, K)
    for i in 1:K
        if which isa Integer && which != i
            ratios[i] = merge(na_ci, (estimate = fit.ratios[i],))
        else
            ratios[i] = _ratio_delta_ci(info, theta, i, level, boundary_tol)
        end
    end
    return (ratios = ratios, level = level, converged = fit.converged)
end

# Assemble the SPARSE Henderson mixed-model-equation coefficient matrix `C` and
# right-hand side for the general K-independent-random-effect model at the given
# variance components, from the iteration-invariant cross-products. `C` is the
# UNSCALED (1/σ_e²) Henderson form, so `C⁻¹`'s random-block diagonal is directly
# the PEV in σ² units — the same convention as `_sparse_mme_system` (K=1) — and the
# random block is ordered `[u_1; …; u_K]` (`hcat(Z_i)` design, `blockdiag(A_i⁻¹/σ_i²)`
# precision), matching `multi_effect_mme`. All blocks are `SparseMatrixCSC`, so the
# hvcat result is sparse (type-stable).
function _sparse_multi_lhs_rhs(XtX, XtZ, ZtX, ZtZ, Xty, Zty, Ainvs, sigmas, sigma_e2)
    K = length(Ainvs)
    rp = inv(sigma_e2)
    Ginv = blockdiag((Ainvs[i] .* inv(sigmas[i]) for i in 1:K)...)
    lhs = [
        rp .* XtX  rp .* XtZ
        rp .* ZtX  rp .* ZtZ .+ Ginv
    ]
    rhs = vcat(rp .* Xty, rp .* Zty)
    return lhs, rhs
end

"""
    sparse_multi_reml_loglik(y, X, effects, sigmas, sigma_e2) -> (loglik, beta, us)

Evaluate the Gaussian REML log-likelihood, fixed effects, and per-block BLUPs of
the general `K`-independent-random-effect model
`y = X·β + Σᵢ Zᵢ·uᵢ + e`, `uᵢ ~ N(0, σᵢ²·Aᵢ)`, `e ~ N(0, σ_e²·I)`,
at supplied positive variance components, using the sparse Henderson MME
determinant identity — the `K`-block generalization of [`sparse_reml_loglik`](@ref).
`effects` is a vector of `(Zᵢ, Ainvᵢ)` pairs (same contract as
[`multi_effect_mme`](@ref)).

The log-likelihood uses the package-wide full-constant convention
`−0.5·[(n−p)·log(2π) + log|R| + log|G| + log|C| + y'Py]` (identical to
`sparse_reml_loglik` / `fit_ai_reml`). It therefore equals the dense
`fit_multi_effect_reml` REML objective (`_multi_effect_dense`, which omits the
`(n−p)·log(2π)` constant) PLUS `−0.5·(n−p)·log(2π)`; this offset is the only
difference and is exact. Engine-internal, supplied-variance; it does not estimate.
"""
function sparse_multi_reml_loglik(
    y::AbstractVector,
    X::AbstractMatrix,
    effects::AbstractVector,
    sigmas::AbstractVector,
    sigma_e2::Real,
)
    K = length(effects)
    K >= 1 || throw(ArgumentError("at least one random effect is required"))
    length(sigmas) == K || throw(ArgumentError("sigmas length must match number of effects"))
    all(s -> s > 0, sigmas) || throw(ArgumentError("all sigmas must be positive"))
    sigma_e2 > 0 || throw(ArgumentError("sigma_e2 must be positive"))
    n = length(y)
    size(X, 1) == n || throw(ArgumentError("X must have one row per record"))
    yv = Float64.(y)
    Xs = sparse(Float64.(X))
    nfixed = size(Xs, 2)
    nfixed < n || throw(ArgumentError("REML requires fewer fixed-effect columns than observations"))

    Zs = SparseMatrixCSC{Float64,Int}[]
    Ainvs = SparseMatrixCSC{Float64,Int}[]
    qs = Int[]
    for (i, pair) in enumerate(effects)
        Zi, Ainvi = pair
        size(Zi, 1) == n || throw(ArgumentError("Z[$i] must have one row per record"))
        qi = size(Ainvi, 1)
        size(Ainvi, 2) == qi || throw(ArgumentError("Ainv[$i] must be square"))
        size(Zi, 2) == qi || throw(ArgumentError("Z[$i] columns must match Ainv[$i] dimensions"))
        push!(Zs, sparse(Float64.(Zi)))
        push!(Ainvs, sparse(Float64.(Ainvi)))
        push!(qs, qi)
    end

    ss = Float64.(collect(sigmas))
    se2 = Float64(sigma_e2)
    Zf = reduce(hcat, Zs)
    Xt = transpose(Xs); Zft = transpose(Zf)
    XtX = sparse(Xt * Xs); XtZ = sparse(Xt * Zf)
    ZtX = sparse(Zft * Xs); ZtZ = sparse(Zft * Zf)
    Xty = Vector(Xt * yv); Zty = Vector(Zft * yv)
    lhs, rhs = _sparse_multi_lhs_rhs(XtX, XtZ, ZtX, ZtZ, Xty, Zty, Ainvs, ss, se2)
    factor = cholesky(Symmetric(lhs); check = true)
    solution = factor \ rhs

    beta = Vector{Float64}(solution[1:nfixed])
    us = Vector{Vector{Float64}}(undef, K)
    off = nfixed
    for i in 1:K
        us[i] = Vector{Float64}(solution[(off + 1):(off + qs[i])])
        off += qs[i]
    end

    logdetR = n * log(se2)
    logdetG = 0.0
    for i in 1:K
        logdetG += qs[i] * log(ss[i]) - logdet(cholesky(Symmetric(Ainvs[i]); check = true))
    end
    logdetC = logdet(factor)
    quad = inv(se2) * dot(yv, yv) - dot(rhs, solution)      # y'Py
    loglik = -0.5 * ((n - nfixed) * log(2 * pi) + logdetR + logdetG + logdetC + quad)
    return loglik, beta, us
end

# AI/Newton step for the (K+1)×(K+1) average-information matrix (symmetric PSD).
# General-size analogue of `_ai_newton_step`: try a Cholesky solve, and if the AI
# matrix is not positive definite (near a boundary) or gives a non-finite step,
# ridge it by a small multiple of its mean diagonal and solve the symmetric system.
# Reduces to `_ai_newton_step` behaviour for a well-conditioned 2×2 (K=1).
function _ai_newton_step_nd(information::AbstractMatrix, score::AbstractVector)
    m = size(information, 1)
    A = Matrix{Float64}(information)
    A = (A .+ transpose(A)) ./ 2                       # symmetrize roundoff
    fac = cholesky(Symmetric(A); check = false)
    if issuccess(fac)
        step = fac \ score
        all(isfinite, step) && return step
    end
    ridge = 1e-8 * (tr(A) / m + 1)
    return Symmetric(A .+ ridge .* Matrix{Float64}(I, m, m)) \ score
end

"""
    fit_sparse_multi_effect_aireml(y, X, effects; initial = nothing,
                                   iterations = 100, tol = 1e-8, em_warmup = 0,
                                   ids = nothing)

Sparse average-information (AI) REML for the general `K`-independent-random-effect
Gaussian animal model
`y = X·β + Σᵢ Zᵢ·uᵢ + e`, `uᵢ ~ N(0, σᵢ²·Aᵢ)`, `e ~ N(0, σ_e²·I)`,
estimating the `K+1` variance components `(σ₁²,…,σ_K², σ_e²)`. This is the sparse,
scale-path generalization of the single-component [`fit_ai_reml`](@ref); it is the
production-shaped estimator behind the dense oracle [`fit_multi_effect_reml`](@ref)
(which forms an `n×n` `V` and is guarded by `max_dense_cells`).

`effects` is a vector of `(Zᵢ, Ainvᵢ)` pairs (`Zᵢ` the `n×qᵢ` record→level sparse
incidence, `Ainvᵢ` the `qᵢ×qᵢ` supplied relationship PRECISION — pass a sparse
identity for a plain i.i.d. `(1|group)` effect), the same contract as
[`multi_effect_mme`](@ref). `initial`, if supplied, is a length-`K+1` vector of
positive starting variances `[σ₁,…,σ_K,σ_e2]` (default all `1`).

Each iteration assembles the sparse Henderson MME coefficient matrix
`C = [X'R⁻¹X X'R⁻¹Z; Z'R⁻¹X Z'R⁻¹Z + blockdiag(Aᵢ⁻¹/σᵢ²)]` (`R = σ_e²·I`),
sparse-Cholesky factorizes it ONCE, reads each block's REML score
`∂ℓ/∂σᵢ² = −0.5·(qᵢ − tr(Aᵢ⁻¹C^{uᵢuᵢ})/σᵢ² − uᵢ'Aᵢ⁻¹uᵢ/σᵢ²)/σᵢ²`
from the BLUP solution and the **Takahashi selected inverse**
(`selinv_block_traces`, the `tr(Aᵢ⁻¹C^{uᵢuᵢ})` terms — no dense inverse is
formed), assembles the `(K+1)×(K+1)` average-information matrix from working-variate
re-solves that reuse the same Cholesky factor, and takes an AI/Newton step with
step-halving to keep every component positive. Convergence uses the SCALE-INVARIANT
relative-variance rule (the "F3" stopping rule shared with `fit_ai_reml`): the
absolute REML score scales with `n`, so at large `q` the fit also stops on the
relative change in the variance components. An optional EM-REML warm-start
(`em_warmup`, default `0` = byte-identical to the pure AI path) hands the AI step a
good in-bounds start.

CORRECTNESS: on the SAME data at small scale, the optimum reduces EXACTLY to the
dense [`fit_multi_effect_reml`](@ref) optimum (variance components and REML
log-likelihood) for `K = 2` and `K = 3`, and the `K = 1` path reduces to
[`fit_ai_reml`](@ref) (`test/runtests.jl`). Returns a `NamedTuple` with
`variance_components = (sigmas, sigma_e2)`, per-effect `ratios`, `beta`, the `K`
BLUPs (`effects = [(ids, values), …]`), `loglik` (full-constant convention,
identical to `fit_ai_reml`), `converged`, `iterations`, per-component `boundary`
flags (`σᵢ/total < 1e-6`), and `estimator = :sparse_multi_effect_aireml`.

EXPERIMENTAL, REML-only, Gaussian, INDEPENDENT effects only (no correlated /
direct–maternal 2×2 `G`). The sparse machinery EXISTS and is verified to reduce to
the dense optimum, but its scale/performance is NOT yet benchmarked (measure-first;
`sim/phase5_sparse_aireml_benchmark.jl` is the opt-in scaffold) and it is NOT the
public default fit path. On uninformative/non-identified data a component can ride
to the `σ²→0` boundary; the fit reports `converged = false` and never returns NaN.
"""
function fit_sparse_multi_effect_aireml(
    y::AbstractVector,
    X::AbstractMatrix,
    effects::AbstractVector;
    initial = nothing,
    iterations::Integer = 100,
    tol::Real = 1e-8,
    em_warmup::Integer = 0,
    ids = nothing,
)
    K = length(effects)
    K >= 1 || throw(ArgumentError("at least one random effect is required"))
    n = length(y)
    size(X, 1) == n || throw(ArgumentError("X must have one row per record"))

    Zs = SparseMatrixCSC{Float64,Int}[]
    Ainvs = SparseMatrixCSC{Float64,Int}[]
    qs = Int[]
    for (i, pair) in enumerate(effects)
        Zi, Ainvi = pair
        size(Zi, 1) == n || throw(ArgumentError("Z[$i] must have one row per record"))
        qi = size(Ainvi, 1)
        size(Ainvi, 2) == qi || throw(ArgumentError("Ainv[$i] must be square"))
        size(Zi, 2) == qi || throw(ArgumentError("Z[$i] columns must match Ainv[$i] dimensions"))
        push!(Zs, sparse(Float64.(Zi)))
        push!(Ainvs, sparse(Float64.(Ainvi)))
        push!(qs, qi)
    end
    yv = Float64.(y)
    Xs = sparse(Float64.(X))
    nfixed = size(Xs, 2)
    nfixed < n || throw(ArgumentError("REML requires fewer fixed-effect columns than observations"))

    if ids === nothing
        eids = [collect(1:qs[i]) for i in 1:K]
    else
        length(ids) == K || throw(ArgumentError("ids must be a length-$K vector of per-effect id vectors"))
        eids = [collect(ids[i]) for i in 1:K]
        for i in 1:K
            length(eids[i]) == qs[i] ||
                throw(ArgumentError("ids[$i] length must match Ainv[$i] dimensions"))
        end
    end

    if initial === nothing
        sigmas = ones(Float64, K)
        sigma_e2 = 1.0
    else
        length(initial) == K + 1 ||
            throw(ArgumentError("initial must have length K+1 = $(K + 1) (one per effect plus residual)"))
        all(s -> s > 0, initial) || throw(ArgumentError("initial variance components must be positive"))
        sigmas = Float64.(collect(initial[1:K]))
        sigma_e2 = Float64(initial[K + 1])
    end

    # Contiguous global offset of each random block within [β; u_1; …; u_K].
    offsets = Vector{Int}(undef, K)
    acc = nfixed
    for i in 1:K
        offsets[i] = acc
        acc += qs[i]
    end
    nrandom = acc - nfixed

    # Iteration-invariant cross-products (only the σ scaling + Ginv change per step).
    Zf = reduce(hcat, Zs)
    Xt = transpose(Xs); Zft = transpose(Zf)
    XtX = sparse(Xt * Xs); XtZ = sparse(Xt * Zf)
    ZtX = sparse(Zft * Xs); ZtZ = sparse(Zft * Zf)
    Xty = Vector(Xt * yv); Zty = Vector(Zft * yv)

    # EM-REML warm-start (closed-form, monotone, in-bounds): σᵢ² = (uᵢ'Aᵢ⁻¹uᵢ +
    # tr(Aᵢ⁻¹C^{uᵢuᵢ}))/qᵢ, σ_e² = e'e/(n − p − Σq + Σ tr(Aᵢ⁻¹C^{uᵢuᵢ})/σᵢ²).
    for _ in 1:max(0, em_warmup)
        lhs, rhs = _sparse_multi_lhs_rhs(XtX, XtZ, ZtX, ZtZ, Xty, Zty, Ainvs, sigmas, sigma_e2)
        factor = try
            cholesky(Symmetric(lhs); check = true)
        catch err
            err isa LinearAlgebra.PosDefException && break
            rethrow(err)
        end
        solution = factor \ rhs
        urand = solution[(nfixed + 1):end]
        e = yv .- Xs * solution[1:nfixed] .- Zf * urand
        traces = selinv_block_traces(factor, Ainvs, offsets)
        newsig = similar(sigmas)
        ok = true
        for i in 1:K
            ui = solution[(offsets[i] + 1):(offsets[i] + qs[i])]
            uAu = dot(ui, Ainvs[i] * ui)
            newsig[i] = (uAu + traces[i]) / qs[i]
            (isfinite(newsig[i]) && newsig[i] > 0) || (ok = false)
        end
        dfe = n - nfixed - nrandom + sum(traces[i] / sigmas[i] for i in 1:K)
        newe = dot(e, e) / dfe
        (ok && isfinite(newe) && newe > 0) || break
        rel = max(maximum(abs.(newsig .- sigmas) ./ sigmas), abs(newe - sigma_e2) / sigma_e2)
        sigmas = newsig
        sigma_e2 = newe
        rel < tol && break
    end

    converged = false
    iters = 0
    mme_indefinite = false
    for it in 1:iterations
        iters = it
        lhs, rhs = _sparse_multi_lhs_rhs(XtX, XtZ, ZtX, ZtZ, Xty, Zty, Ainvs, sigmas, sigma_e2)
        # Guard the main-loop factorization the same way the EM-warmup loop above does. An
        # indefinite multi-effect MME — e.g. from a non-positive-definite supplied precision —
        # makes cholesky(...; check = true) throw PosDefException. Stop gracefully at the current
        # finite, positive variance components with converged = false, mirroring the single-effect
        # fit_ai_reml guard, rather than crashing with an uncaught exception.
        factor = try
            cholesky(Symmetric(lhs); check = true)
        catch err
            err isa LinearAlgebra.PosDefException || rethrow(err)
            mme_indefinite = true
            break
        end
        solution = factor \ rhs
        urand = solution[(nfixed + 1):end]
        e = yv .- Xs * solution[1:nfixed] .- Zf * urand
        traces = selinv_block_traces(factor, Ainvs, offsets)

        us = [solution[(offsets[i] + 1):(offsets[i] + qs[i])] for i in 1:K]
        uAu = [dot(us[i], Ainvs[i] * us[i]) for i in 1:K]

        # REML scores: K component scores then the residual score (same identities
        # as fit_ai_reml, generalized to K blocks + a joint effective residual df).
        score = Vector{Float64}(undef, K + 1)
        for i in 1:K
            score[i] = -0.5 / sigmas[i]^2 * (qs[i] * sigmas[i] - traces[i] - uAu[i])
        end
        dfe = n - nfixed - nrandom + sum(traces[i] / sigmas[i] for i in 1:K)
        score[K + 1] = -0.5 / sigma_e2^2 * (sigma_e2 * dfe - dot(e, e))

        if norm(score) < tol
            converged = true
            break
        end

        # Working variates wᵢ = Zᵢuᵢ/σᵢ², w_e = e/σ_e²; AI[i,j] = 0.5·wᵢ'P wⱼ, with
        # P applied by an MME re-solve that reuses `factor` (stacked Zf ⇒ Σᵢ Zᵢu_{w,i}).
        W = Matrix{Float64}(undef, n, K + 1)
        for i in 1:K
            W[:, i] = (Zs[i] * us[i]) ./ sigmas[i]
        end
        W[:, K + 1] = e ./ sigma_e2
        PW = Matrix{Float64}(undef, n, K + 1)
        for j in 1:(K + 1)
            PW[:, j] = _reml_project(factor, Xs, Zf, W[:, j], sigma_e2, nfixed)
        end
        information = 0.5 .* (transpose(W) * PW)
        step = _ai_newton_step_nd(information, score)
        all(isfinite, step) || break

        newsig = sigmas .+ step[1:K]
        newe = sigma_e2 + step[K + 1]
        halvings = 0
        while (any(<=(0.0), newsig) || newe <= 0) && halvings < 60
            step = step ./ 2
            newsig = sigmas .+ step[1:K]
            newe = sigma_e2 + step[K + 1]
            halvings += 1
        end
        (all(>(0.0), newsig) && newe > 0) || break
        # Scale-invariant (F3) convergence on the relative variance-component change.
        rel_change = max(maximum(abs.(newsig .- sigmas) ./ sigmas), abs(newe - sigma_e2) / sigma_e2)
        sigmas = newsig
        sigma_e2 = newe
        if rel_change < tol
            converged = true
            break
        end
    end

    # On the indefinite-MME stop, sparse_multi_reml_loglik would rethrow the same
    # PosDefException; report a NaN loglik / EBVs alongside the finite, positive variance
    # components and converged = false instead of crashing. Every other path is unchanged.
    loglik, beta, us = if mme_indefinite
        (NaN, fill(NaN, nfixed), [fill(NaN, qs[i]) for i in 1:K])
    else
        sparse_multi_reml_loglik(yv, Xs, effects, sigmas, sigma_e2)
    end
    total = sum(sigmas) + sigma_e2
    effects_out = [(ids = eids[i], values = us[i]) for i in 1:K]
    status = converged ? "converged" : "not_converged"
    return (
        variance_components = (sigmas = sigmas, sigma_e2 = sigma_e2),
        ratios = sigmas ./ total,
        beta = beta,
        effects = effects_out,
        loglik = loglik,
        converged = converged,
        iterations = iters,
        boundary = [s / total < 1e-6 for s in sigmas],
        status = status,
        estimator = :sparse_multi_effect_aireml,
    )
end

# Dense REML log-likelihood + BLUPs for the direct–maternal model: one trait, one
# relationship A, two incidences (Z_d = record→animal, Z_m = record→dam), a 2×2
# genetic covariance G_dm over [a_d; a_m] (effect-outer, Var = kron(G_dm, A)):
#   V = W·kron(G_dm, A)·Wᵀ + σ²e·I,  W = [Z_d  Z_m].
function _direct_maternal_dense(y, X, Zd, Zm, A, G_dm, sigma_e2)
    n = length(y)
    q = size(A, 1)
    Sigma_u = kron(G_dm, A)                  # 2q×2q, effect-outer
    W = hcat(Zd, Zm)                         # n×2q
    V = Symmetric(W * Sigma_u * transpose(W) .+ sigma_e2 .* Matrix(1.0I, n, n))
    Vf = cholesky(V)
    ViX = Vf \ Matrix(X)
    XtViX = cholesky(Symmetric(transpose(X) * ViX))
    beta = XtViX \ (transpose(X) * (Vf \ y))
    r = y .- X * beta
    Vir = Vf \ r
    loglik = -0.5 * (logdet(Vf) + logdet(XtViX) + dot(r, Vir))
    u = Sigma_u * (transpose(W) * Vir)
    return loglik, Vector{Float64}(beta), Vector{Float64}(u[1:q]), Vector{Float64}(u[(q + 1):(2q)])
end

"""
    fit_direct_maternal_reml(y, X, Zd, Zm, Ainv; initial = nothing,
                             iterations = 200, ids = nothing,
                             max_dense_cells = 1_000_000)

REML estimation of the direct–maternal genetic model — one trait, one relationship
`A = Ainv⁻¹`, a DIRECT additive effect (incidence `Zd`, record→animal) and a
MATERNAL additive effect (incidence `Zm`, record→dam) with a `2×2` genetic
covariance `G_dm` over `[a_d; a_m]` (`Var = kron(G_dm, A)`), plus residual `σ²e`.
The `2×2` `G_dm` is estimated by dense REML over a log-Cholesky parameterization
(so `G_dm` stays positive definite), reusing the multivariate `_chol_params_to_cov`
machinery; the direct/maternal BLUPs come from the marginal GLS form.

Returns a `NamedTuple` with `variance_components = (G_dm, sigma_ad, sigma_am,
sigma_dm, sigma_e2)`, the direct–maternal `genetic_correlation` `r_am`, `beta`,
`direct_effects`/`maternal_effects` `(ids, values)`, `loglik`, and `converged`.

Reduction: with a diagonal `G_dm` (`σ_dm = 0`) `_direct_maternal_dense` equals the
two-independent-effect dense model `[(Zd, A), (Zm, A)]`. COVERED at validation
scale (opt-in, NOT the public default), dense (n ≤ ~1000), REML-only, Gaussian.
This is the FIRST correlated random-effect structure (`σ_dm ≠ 0`), distinct from
independent multi-effect and from multivariate G0-over-traits. Evidence: an R
surface (`target="direct_maternal"` / `maternal_genetic()`), a `sommer` 4.4.5
`covm()` same-estimand REML comparator (AGREE, all entries ≤ 1.1e-2 rel.diff),
and a PRE-DECLARED 48-seed bias/MCSE recovery gate (48/48 converged, all four
`|bias| ≤ 2·MCSE`; see
`docs/dev-log/recovery-checkpoints/2026-07-01-direct-maternal-covered-evidence.md`).
INTERPRETATION FENCE (Willham): a negative `r_am` is real and expected; the
direct heritability `σ_ad/σ_P` is NOT "the heritability" (the selection-relevant
total additive variance involves `σ_dm`); callers must label direct-vs-total,
never emit a bare h². On small/uninformative data or `|r_am| → 1` the optimum
can sit on a boundary (`converged = false`); identifiability generally needs
designed data (the direct–maternal/PE/cytoplasmic confound).
"""
function fit_direct_maternal_reml(
    y::AbstractVector,
    X::AbstractMatrix,
    Zd::AbstractMatrix,
    Zm::AbstractMatrix,
    Ainv::AbstractMatrix;
    initial = nothing,
    iterations::Integer = 200,
    ids = nothing,
    max_dense_cells::Integer = DEFAULT_MAX_DENSE_CELLS,
)
    n = length(y)
    q = size(Ainv, 1)
    size(X, 1) == n || throw(ArgumentError("X must have one row per record"))
    size(Zd, 1) == n || throw(ArgumentError("Zd must have one row per record"))
    size(Zm, 1) == n || throw(ArgumentError("Zm must have one row per record"))
    size(Ainv, 2) == q || throw(ArgumentError("Ainv must be square"))
    size(Zd, 2) == q || throw(ArgumentError("Zd columns must match Ainv dimensions"))
    size(Zm, 2) == q || throw(ArgumentError("Zm columns must match Ainv dimensions"))
    n * n <= max_dense_cells ||
        throw(ArgumentError("dense direct–maternal REML would form an $(n)×$(n) covariance " *
            "($(n * n) cells) exceeding max_dense_cells=$(max_dense_cells)"))
    A = inv(Symmetric(Matrix{Float64}(Ainv)))
    Xd = Matrix{Float64}(X)
    Zdd = Matrix{Float64}(Zd)
    Zmd = Matrix{Float64}(Zm)
    yv = Float64.(y)
    mu = sum(yv) / n
    vp = n > 1 ? sum(abs2, yv .- mu) / (n - 1) : 1.0
    vp > 0 || (vp = 1.0)
    if initial !== nothing && hasproperty(initial, :G_dm)
        G0 = Matrix(Float64.(Matrix(initial.G_dm)))
        size(G0) == (2, 2) || throw(ArgumentError("initial.G_dm must be 2×2"))
        isposdef(Symmetric(G0)) || throw(ArgumentError("initial.G_dm must be positive definite"))
    else
        G0 = Matrix(Diagonal(fill(0.33 * vp, 2)))
    end
    se0 = if initial !== nothing && hasproperty(initial, :sigma_e2)
        s = Float64(initial.sigma_e2)
        s > 0 || throw(ArgumentError("initial.sigma_e2 must be positive"))
        s
    else
        0.33 * vp
    end
    function negloglik(p)
        G = _chol_params_to_cov(@view(p[1:3]), 2)
        se2 = exp(p[4])
        try
            val = -_direct_maternal_dense(yv, Xd, Zdd, Zmd, A, G, se2)[1]
            return isfinite(val) ? val : Inf
        catch err
            (err isa PosDefException || err isa SingularException) && return Inf
            rethrow()
        end
    end
    p0 = vcat(_cov_to_chol_params(G0, 2), log(se0))
    result = optimize(negloglik, p0, NelderMead(), Optim.Options(iterations = iterations))
    popt = Optim.minimizer(result)
    G_dm = Matrix(Symmetric(_chol_params_to_cov(popt[1:3], 2)))
    se2 = exp(popt[4])
    loglik, beta, ad, am = _direct_maternal_dense(yv, Xd, Zdd, Zmd, A, G_dm, se2)
    aids = ids === nothing ? collect(1:q) : collect(ids)
    length(aids) == q || throw(ArgumentError("ids length must match Ainv dimensions"))
    r_am = G_dm[1, 2] / sqrt(G_dm[1, 1] * G_dm[2, 2])
    return (
        variance_components = (
            G_dm = G_dm,
            sigma_ad = G_dm[1, 1],
            sigma_am = G_dm[2, 2],
            sigma_dm = G_dm[1, 2],
            sigma_e2 = se2,
        ),
        genetic_correlation = r_am,
        beta = beta,
        direct_effects = (ids = aids, values = ad),
        maternal_effects = (ids = aids, values = am),
        loglik = loglik,
        converged = Optim.converged(result),
    )
end

"""
    direct_maternal_interval(y, X, Zd, Zm, Ainv; level = 0.95, initial = nothing,
                             iterations = 200, ids = nothing, fd_step = 1e-4,
                             max_dense_cells = 1_000_000)

Asymptotic delta-method standard errors and confidence intervals for the
direct–maternal REML model ([`fit_direct_maternal_reml`](@ref)). Fits the model,
forms the observed information as the central finite-difference Hessian of the
dense REML log-likelihood over the four natural variance components
`θ = (σ²_ad, σ²_am, σ_dm, σ²e)` at the optimum, inverts it for `cov(θ̂)`, and
delta-transforms to each reported quantity — the SAME finite-difference-Hessian +
delta machinery as [`repeatability_interval`](@ref).

Returns a `NamedTuple` with per-component `(estimate, se, lower, upper)` records
for the variance components (`sigma_ad`, `sigma_am`, `sigma_dm`, `sigma_e2`), the
direct–maternal genetic correlation `r_am` (Fisher-`z` interval, so it stays in
`(-1, 1)`), and the Willham labelled triple `direct_heritability` (`σ²_ad/σ_P`),
`maternal_ratio` (`σ²_am/σ_P`), and `total_heritability`
(`h²_T = (σ²_ad + 1.5·σ_dm + 0.5·σ²_am)/σ_P`, Willham (1972), with
`σ_P = σ²_ad + σ²_am + σ_dm + σ²e` — the SAME convention as the R
`total_heritability()` surface).

INTERVALS ARE ASYMPTOTIC / UNCALIBRATED (normal-`z` Wald / delta on the observed
REML information; Fisher-`z` for `r_am`), NOT coverage-calibrated — the same house
convention as every other interval helper. Variance-component Wald bounds are NOT
clamped (a lower bound may fall below 0 on a flat surface; that is honest and
flagged by `information_posdef`). If the observed information is not positive
definite (flat surface / boundary optimum, e.g. `|r_am| → 1`) the interval is
undefined and an error is thrown, mirroring [`repeatability_interval`](@ref).
Internal / opt-in; this does NOT change the fitted result or any R-facing surface.
"""
function direct_maternal_interval(
    y::AbstractVector, X::AbstractMatrix, Zd::AbstractMatrix, Zm::AbstractMatrix,
    Ainv::AbstractMatrix;
    level::Real = 0.95,
    initial = nothing,
    iterations::Integer = 200,
    ids = nothing,
    fd_step::Real = 1e-4,
    max_dense_cells::Integer = DEFAULT_MAX_DENSE_CELLS,
)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1)"))
    fit = fit_direct_maternal_reml(y, X, Zd, Zm, Ainv; initial = initial,
                                   iterations = iterations, ids = ids,
                                   max_dense_cells = max_dense_cells)
    vc = fit.variance_components
    theta = [vc.sigma_ad, vc.sigma_am, vc.sigma_dm, vc.sigma_e2]

    A = inv(Symmetric(Matrix{Float64}(Ainv)))
    Xd = Matrix{Float64}(X); Zdd = Matrix{Float64}(Zd); Zmd = Matrix{Float64}(Zm)
    yv = Float64.(y)
    # REML loglik as a function of the natural VCs (G = [σ²_ad σ_dm; σ_dm σ²_am]).
    function loglik(t)
        G = [t[1] t[3]; t[3] t[2]]
        se2 = t[4]
        se2 > 0 || return NaN
        try
            return _direct_maternal_dense(yv, Xd, Zdd, Zmd, A, G, se2)[1]
        catch err
            (err isa PosDefException || err isa SingularException) && return NaN
            rethrow()
        end
    end

    # observed information = −Hessian of the REML loglik (central finite differences)
    h = fd_step .* max.(abs.(theta), 1e-3)
    H = zeros(4, 4)
    for i in 1:4, j in 1:4
        ei = zeros(4); ei[i] = h[i]
        ej = zeros(4); ej[j] = h[j]
        H[i, j] = (loglik(theta + ei + ej) - loglik(theta + ei - ej) -
                   loglik(theta - ei + ej) + loglik(theta - ei - ej)) / (4 * h[i] * h[j])
    end
    all(isfinite, H) ||
        throw(ArgumentError("direct–maternal interval undefined: the REML surface is not " *
            "finite under perturbation (boundary optimum / non-PD G_dm; e.g. |r_am| → 1)"))
    info = Symmetric(-H)
    isposdef(info) ||
        throw(ArgumentError("direct–maternal interval undefined: REML information is not " *
            "positive definite (flat surface / boundary optimum)"))
    covar = inv(info)

    zq = _standard_normal_quantile((1 + level) / 2)
    seof(g) = sqrt(max(dot(g, covar * g), 0.0))
    function wald(est, g)
        s = seof(g)
        return (estimate = est, se = s, lower = est - zq * s, upper = est + zq * s)
    end

    sad, sam, sdm, se2 = theta
    sP = sad + sam + sdm + se2

    # variance components: gradients are the standard basis vectors
    vc_out = (
        sigma_ad = wald(sad, [1.0, 0.0, 0.0, 0.0]),
        sigma_am = wald(sam, [0.0, 1.0, 0.0, 0.0]),
        sigma_dm = wald(sdm, [0.0, 0.0, 1.0, 0.0]),
        sigma_e2 = wald(se2, [0.0, 0.0, 0.0, 1.0]),
    )

    # genetic correlation r_am = σ_dm / sqrt(σ²_ad σ²_am); Fisher-z interval
    r = fit.genetic_correlation
    abs(r) < 1 || throw(ArgumentError("direct–maternal r_am is on the ±1 boundary; interval undefined"))
    denom = sqrt(sad * sam)
    gr = [-0.5 * r / sad, -0.5 * r / sam, 1.0 / denom, 0.0]
    se_r = seof(gr)
    zr = atanh(r); se_zr = se_r / (1 - r^2)
    r_ci = (estimate = r, se = se_r, method = :fisher_z,
            lower = tanh(zr - zq * se_zr), upper = tanh(zr + zq * se_zr))

    # Willham labelled triple over σ_P = σ²_ad + σ²_am + σ_dm + σ²e
    sP2 = sP^2
    direct_h2 = wald(sad / sP, [(sP - sad) / sP2, -sad / sP2, -sad / sP2, -sad / sP2])
    m2 = wald(sam / sP, [-sam / sP2, (sP - sam) / sP2, -sam / sP2, -sam / sP2])
    N = sad + 1.5 * sdm + 0.5 * sam
    total_h2 = wald(N / sP,
        [(sP - N) / sP2, (0.5 * sP - N) / sP2, (1.5 * sP - N) / sP2, -N / sP2])

    return (
        level = level,
        converged = fit.converged,
        variance_components = vc_out,
        genetic_correlation = r_ci,
        direct_heritability = direct_h2,
        maternal_ratio = m2,
        total_heritability = merge(total_h2,
            (convention = "Willham (1972): (σ²_ad + 1.5σ_dm + 0.5σ²_am)/σ_P, σ_P = σ²_ad+σ²_am+σ_dm+σ²e",)),
        interval_method = "asymptotic_delta_uncalibrated",
        information_posdef = true,
    )
end

# Repeatability dense loglik = the two-effect dense loglik with the
# permanent-environment effect sharing Z and carrying an identity relationship.
function _repeatability_dense(y, X, Z, A, sigma_a2, sigma_pe2, sigma_e2)
    na = size(A, 1)
    return _two_effect_dense(y, X, Z, A, Z, Matrix(1.0I, na, na), sigma_a2, sigma_pe2, sigma_e2)
end

"""
    fit_repeatability_reml(y, X, Z, Ainv; initial, iterations = 200, ids = nothing)

Estimate the three variance components `(sigma_a2, sigma_pe2, sigma_e2)` of the
repeatability / permanent-environment animal model by REML, by maximizing the
dense two-random-effect REML log-likelihood over the log-variances (NelderMead).

Returns a `NamedTuple` with `variance_components`, the repeatability
`t = (sigma_a2 + sigma_pe2) / total`, the heritability `h² = sigma_a2 / total`,
`beta`, the `a` / `pe` BLUPs at the estimate, `loglik`, and `converged`.

Experimental and validation-scale: it forms the dense `n×n` marginal covariance,
so it is for small problems, not production. REML-only. Uncertainty intervals for
`t` / `h²` and the R model-spec mapping are not part of this function. Separating
`sigma_a2` from `sigma_pe2` needs relationship contrast and replication; on small
data the optimum can sit on a boundary (one variance → 0).
"""
function fit_repeatability_reml(
    y::AbstractVector,
    X::AbstractMatrix,
    Z::AbstractMatrix,
    Ainv::AbstractMatrix;
    initial = (sigma_a2 = 1.0, sigma_pe2 = 1.0, sigma_e2 = 1.0),
    iterations::Integer = 200,
    ids = nothing,
)
    initial.sigma_a2 > 0 && initial.sigma_pe2 > 0 && initial.sigma_e2 > 0 ||
        throw(ArgumentError("initial variance components must be positive"))
    n = length(y)
    size(X, 1) == n || throw(ArgumentError("X must have one row per record"))
    size(Z, 1) == n || throw(ArgumentError("Z must have one row per record"))
    na = size(Ainv, 1)
    size(Ainv, 2) == na || throw(ArgumentError("Ainv must be square"))
    size(Z, 2) == na || throw(ArgumentError("Z columns must match Ainv dimensions"))
    encoded_ids = ids === nothing ? collect(1:na) : collect(ids)
    length(encoded_ids) == na ||
        throw(ArgumentError("ids length must match Ainv dimensions"))

    A = inv(Symmetric(Matrix{Float64}(Ainv)))
    Xd = Matrix{Float64}(X)
    Zd = Matrix{Float64}(Z)
    yv = Float64.(y)
    objective(p) = -_repeatability_dense(yv, Xd, Zd, A, exp(p[1]), exp(p[2]), exp(p[3]))[1]
    p0 = log.([Float64(initial.sigma_a2), Float64(initial.sigma_pe2), Float64(initial.sigma_e2)])
    result = optimize(objective, p0, NelderMead(), Optim.Options(iterations = iterations))
    sigma_a2, sigma_pe2, sigma_e2 = exp.(Optim.minimizer(result))
    loglik, beta, ahat, pehat =
        _repeatability_dense(yv, Xd, Zd, A, sigma_a2, sigma_pe2, sigma_e2)
    total = sigma_a2 + sigma_pe2 + sigma_e2
    return (
        variance_components = (sigma_a2 = sigma_a2, sigma_pe2 = sigma_pe2, sigma_e2 = sigma_e2),
        repeatability = (sigma_a2 + sigma_pe2) / total,
        heritability = sigma_a2 / total,
        beta = beta,
        animal_effects = (ids = encoded_ids, values = ahat),
        permanent_effects = (ids = encoded_ids, values = pehat),
        loglik = loglik,
        converged = Optim.converged(result),
    )
end

"""
    repeatability_interval(y, X, Z, Ainv; level = 0.95, initial = ..., iterations = 200,
                           ids = nothing, fd_step = 1e-4)

Asymptotic delta-method confidence interval for the repeatability
`t = (σ²a + σ²pe) / (σ²a + σ²pe + σ²e)` of the repeatability / permanent-environment
animal model. Fits by REML ([`fit_repeatability_reml`](@ref)), forms the observed
information as the central finite-difference Hessian of the REML log-likelihood at
the optimum, and applies the delta method to `t` on the logit scale (so the
interval lies in `(0, 1)`). Returns `(repeatability, lower, upper, level, se)`.

Experimental, asymptotic. `t` is the well-identified summary of this model (the
`σ²a`/`σ²pe` split is weakly identified, so a per-component SE is unreliable, but
`t` is stable). Throws if the REML information is not positive definite (a flat
surface / boundary optimum), or if `t` is on the `(0, 1)` boundary.
"""
function repeatability_interval(
    y::AbstractVector, X::AbstractMatrix, Z::AbstractMatrix, Ainv::AbstractMatrix;
    level::Real = 0.95,
    initial = (sigma_a2 = 1.0, sigma_pe2 = 1.0, sigma_e2 = 1.0),
    iterations::Integer = 200, ids = nothing, fd_step::Real = 1e-4,
)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1)"))
    fit = fit_repeatability_reml(y, X, Z, Ainv; initial = initial, iterations = iterations, ids = ids)
    vc = fit.variance_components
    theta = [vc.sigma_a2, vc.sigma_pe2, vc.sigma_e2]

    A = inv(Symmetric(Matrix{Float64}(Ainv)))
    Xd = Matrix{Float64}(X); Zd = Matrix{Float64}(Z); yv = Float64.(y)
    loglik(t) = _repeatability_dense(yv, Xd, Zd, A, t[1], t[2], t[3])[1]

    # observed information = −Hessian of the REML loglik (central finite differences)
    h = fd_step .* max.(theta, 1e-3)
    H = zeros(3, 3)
    for i in 1:3, j in 1:3
        ei = zeros(3); ei[i] = h[i]
        ej = zeros(3); ej[j] = h[j]
        H[i, j] = (loglik(theta + ei + ej) - loglik(theta + ei - ej) -
                   loglik(theta - ei + ej) + loglik(theta - ei - ej)) / (4 * h[i] * h[j])
    end
    info = Symmetric(-H)
    isposdef(info) ||
        throw(ArgumentError("repeatability interval undefined: REML information is not positive definite (flat surface / boundary optimum)"))
    covar = inv(info)

    total = sum(theta)
    t = (theta[1] + theta[2]) / total
    0 < t < 1 || throw(ArgumentError("repeatability estimate is on the (0, 1) boundary; interval undefined"))
    # delta-method gradient of t = (σ²a + σ²pe)/total wrt (σ²a, σ²pe, σ²e)
    g = [theta[3] / total^2, theta[3] / total^2, -(theta[1] + theta[2]) / total^2]
    se = sqrt(max(dot(g, covar * g), 0.0))

    z = _standard_normal_quantile((1 + level) / 2)
    eta = log(t / (1 - t)); se_eta = se / (t * (1 - t))
    lower = 1 / (1 + exp(-(eta - z * se_eta)))
    upper = 1 / (1 + exp(-(eta + z * se_eta)))
    return (repeatability = t, lower = lower, upper = upper, level = level, se = se)
end

"""
    fit_animal_model(spec; target = :variance_components, ...)

Fit or solve the Phase 1 Gaussian animal-model engine target for a validated
[`AnimalModelSpec`](@ref).

The default `target = :variance_components` dispatches to
[`fit_variance_components`](@ref), the experimental dense validation optimizer.
`target = :sparse_reml` dispatches to [`fit_sparse_reml`](@ref), the
experimental sparse REML validation optimizer.
`target = :ai_reml` dispatches to [`fit_ai_reml`](@ref) (the sparse AI-REML path),
`target = :eigen_reml` to [`fit_eigen_reml`](@ref) (eigen-once, `Z = I`, dense-capped), and
`target = :matrix_free_reml` to [`fit_matrix_free_reml`](@ref) (matrix-free Monte-Carlo
EM-REML; STOCHASTIC — estimates carry Monte-Carlo error).
`target = :henderson_mme` requires supplied `variance_components` and returns a
[`HendersonMMEResult`](@ref). The Henderson target solves mixed-model equations
at supplied variance components; it does not estimate them and does not return
log-likelihood, AIC, `df`, or optimizer diagnostics.

`target = :auto` picks a fitter from the MME fill-in `nnz(L)/n` (variance-independent) and `n`,
biased toward the validated exact default — it diverts only where the exact path is
measured-infeasible:

| condition | route | why |
|---|---|---|
| `n ≤ 20 000`, `Z = I`, fill > 60 | [`fit_eigen_reml`](@ref) | dense eigen-once beats a high-fill sparse factorization |
| `n > 20 000`, fill > 150 | [`fit_matrix_free_reml`](@ref) | past the dense cap a high-fill MME has no exact escape (F0: q=20 000, fill 471 → 1529 s) |
| otherwise | [`fit_ai_reml`](@ref) | the validated sparse default |

The `:auto` route to the STOCHASTIC matrix-free fitter fires only in that measured tail; below
the dense cap `:auto` never diverts a fit the exact path handles. Both thresholds are
first-pass heuristics — see [`fit_matrix_free_reml`](@ref) for what the matrix-free route owes.
"""
function fit_animal_model(
    spec::AnimalModelSpec;
    target = :variance_components,
    variance_components = nothing,
    kwargs...,
)
    normalized_target = _coerce_fit_target(target)

    if normalized_target == :variance_components
        variance_components === nothing ||
            throw(ArgumentError("variance_components is only used when target = :henderson_mme"))
        return fit_variance_components(spec; kwargs...)
    end

    if normalized_target == :sparse_reml
        variance_components === nothing ||
            throw(ArgumentError("variance_components is not used when target = :sparse_reml"))
        return fit_sparse_reml(spec; kwargs...)
    end

    if normalized_target == :ai_reml
        variance_components === nothing ||
            throw(ArgumentError("variance_components is not used when target = :ai_reml"))
        return fit_ai_reml(spec; kwargs...)
    end

    if normalized_target == :eigen_reml
        variance_components === nothing ||
            throw(ArgumentError("variance_components is not used when target = :eigen_reml"))
        return fit_eigen_reml(spec; kwargs...)
    end

    if normalized_target == :matrix_free_reml
        variance_components === nothing ||
            throw(ArgumentError("variance_components is not used when target = :matrix_free_reml"))
        return fit_matrix_free_reml(spec; kwargs...)
    end

    if normalized_target == :auto
        variance_components === nothing ||
            throw(ArgumentError("variance_components is not used when target = :auto"))
        isempty(kwargs) ||
            throw(ArgumentError("target = :auto selects the fitter and its defaults; pass " *
                                "target = :eigen, :ai_reml, or :matrix_free to set optimizer " *
                                "keyword arguments"))
        route = _auto_reml_route(spec)
        route == :eigen_reml && return fit_eigen_reml(spec)
        route == :matrix_free_reml && return fit_matrix_free_reml(spec)
        return fit_ai_reml(spec)
    end

    isempty(kwargs) ||
        throw(ArgumentError("target = :henderson_mme does not accept optimizer keyword arguments"))
    sigma_a2, sigma_e2 = _coerce_supplied_variance_components(variance_components)
    return henderson_mme(spec, sigma_a2, sigma_e2)
end

function fit_animal_model(
    y::AbstractVector,
    X::AbstractMatrix,
    Z::AbstractMatrix,
    Ainv::AbstractMatrix;
    ids = nothing,
    family = GaussianFamily(),
    method = :REML,
    target = :variance_components,
    variance_components = nothing,
    kwargs...,
)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ids, family = family, method = method)
    return fit_animal_model(
        spec;
        target = target,
        variance_components = variance_components,
        kwargs...,
    )
end

"""
    variance_components(fit)

Return the additive and residual variance components from an experimental
low-level [`AnimalModelFit`](@ref).
"""
function variance_components(fit::AnimalModelFit)
    return fit.variance_components
end

function variance_components(result::HendersonMMEResult)
    return (sigma_a2 = result.sigma_a2, sigma_e2 = result.sigma_e2)
end

"""
    fixed_effects(fit)

Return the fixed-effect estimates from an experimental low-level
[`AnimalModelFit`](@ref).
"""
function fixed_effects(fit::AnimalModelFit)
    return copy(fit.likelihood.beta)
end

function fixed_effects(result::HendersonMMEResult)
    return copy(result.beta)
end

"""
    fit_diagnostics(fit)

Return compact status metadata for an experimental low-level fit result.

This is an extractor over fields already stored on the result object. It does
not refit a model, run an optimizer, compute PEV/reliability, or change the
bridge-facing [`result_payload`](@ref) contract.
"""
function fit_diagnostics(fit::AnimalModelFit)
    vc = variance_components(fit)

    return (
        engine = :julia,
        result_type = :animal_model_fit,
        target = fit.target,
        method = fit.likelihood.method,
        family = :gaussian,
        converged = fit.converged,
        optimizer_status = fit.optimizer_status,
        iterations = fit.iterations,
        loglik = fit.likelihood.loglik,
        df = fit.likelihood.nfixed + length(vc),
        nobs = fit.likelihood.nobs,
        dense_validation_path = fit.dense_validation_path,
        sparse_mme_path = fit.sparse_mme_path,
        variance_components_source = fit.variance_components_source,
    )
end

function fit_diagnostics(result::HendersonMMEResult)
    return (
        engine = :julia,
        result_type = :henderson_mme,
        target = :henderson_mme,
        method = result.spec.method,
        family = :gaussian,
        converged = true,
        optimizer_status = "not_applicable",
        iterations = 0,
        loglik = nothing,
        df = nothing,
        nobs = length(result.spec.y),
        dense_validation_path = false,
        sparse_mme_path = true,
        variance_components_source = :supplied,
    )
end

"""
    breeding_values(fit)

Return animal-effect BLUPs/EBVs for an experimental low-level
[`AnimalModelFit`](@ref).

The current implementation solves Henderson's mixed-model equations at the
fit's variance components and returns the animal-effect block. Variance
component estimation is still the experimental dense path; this only changes
the EBV/BLUP extraction equation solve.
"""
function breeding_values(fit::AnimalModelFit)
    vc = fit.variance_components
    return breeding_values(henderson_mme(fit.spec, vc.sigma_a2, vc.sigma_e2))
end

function breeding_values(result::HendersonMMEResult)
    return BreedingValues(result.animal_effects.ids, copy(result.animal_effects.values))
end

"""
    EBV(fit)

Alias for [`breeding_values`](@ref), matching the R twin's applied
quantitative-genetic extractor vocabulary.
"""
EBV(fit) = breeding_values(fit)

"""
    BLUP(fit)

Alias for [`breeding_values`](@ref). For the Phase 1 animal-effect block, the
returned values are the same animal BLUPs/EBVs as [`breeding_values`](@ref).
"""
BLUP(fit) = breeding_values(fit)

"""
    fitted_values(fit; include_random = true)

Return fitted values for an experimental low-level [`AnimalModelFit`](@ref).

The current implementation solves Henderson's mixed-model equations at the
fit's variance components, then computes `X * beta + Z * u` from that supplied
variance solution. Variance-component estimation is still the experimental
dense path.
"""
function fitted_values(fit::AnimalModelFit; include_random::Bool = true)
    vc = fit.variance_components
    mme = henderson_mme(fit.spec, vc.sigma_a2, vc.sigma_e2)
    return fitted_values(mme; include_random = include_random)
end

function fitted_values(result::HendersonMMEResult; include_random::Bool = true)
    spec = result.spec
    fitted = Matrix{Float64}(spec.X) * result.beta

    if include_random
        fitted = fitted + Matrix{Float64}(spec.Z) * result.animal_effects.values
    end

    return Vector{Float64}(fitted)
end

"""
    heritability(fit)

Return simple narrow-sense heritability for the Phase 1 univariate Gaussian
animal model: `sigma_a2 / (sigma_a2 + sigma_e2)`.
"""
function heritability(fit::AnimalModelFit)
    vc = fit.variance_components
    return vc.sigma_a2 / (vc.sigma_a2 + vc.sigma_e2)
end

function heritability(result::HendersonMMEResult)
    vc = variance_components(result)
    return vc.sigma_a2 / (vc.sigma_a2 + vc.sigma_e2)
end

"""
    prediction_error_variance(fit)

Return dense prediction error variances for animal-effect BLUPs/EBVs from an
experimental low-level [`AnimalModelFit`](@ref).

The current implementation forms and inverts the dense mixed-model-equation
coefficient matrix. It is a validation-path extractor for tiny examples, not a
production sparse reliability calculation.
"""
function prediction_error_variance(fit::AnimalModelFit; method::Symbol = :dense)
    values = _pev_values(
        fit.spec,
        fit.variance_components.sigma_a2,
        fit.variance_components.sigma_e2,
        method,
    )
    return (ids = collect(fit.spec.ids), values = values)
end

"""
    prediction_error_variance(result::HendersonMMEResult)

Return dense prediction error variances for a supplied-variance Henderson MME
result.

This uses the same dense inverse of the mixed-model-equation coefficient matrix
as [`prediction_error_variance(::AnimalModelFit)`](@ref). It is a tiny
validation-path extractor, not production sparse selected inversion.
"""
function prediction_error_variance(result::HendersonMMEResult; method::Symbol = :dense)
    values = _pev_values(result.spec, result.sigma_a2, result.sigma_e2, method)
    return (ids = collect(result.spec.ids), values = values)
end

"""
    reliability(fit)

Return dense animal-level reliability values for the Phase 1 univariate animal
model.

Reliability is computed as `1 - PEV_i / (sigma_a2 * A_ii)` using the dense
relationship matrix `A = inv(Ainv)` implied by the supplied precision. For a
genomic spec (`Ainv = Ginv`) this `A_ii` is `diag(inv(Ginv)) = diag(G) + ridge`
(the regularized genomic self-relationship, often ≠ 1), so the ridge perturbs the
reported reliability/accuracy and the same extractor yields genomic reliabilities.
Values are not clipped; small examples can expose weakly informed animals
directly.
"""
function reliability(fit::AnimalModelFit; method::Symbol = :dense, pev = nothing)
    pev_res = pev === nothing ? prediction_error_variance(fit; method = method) : pev
    A = inv(Symmetric(Matrix{Float64}(fit.spec.Ainv)))
    animal_variance = fit.variance_components.sigma_a2 .* diag(A)

    all(>(0), animal_variance) ||
        throw(ArgumentError("animal-level additive variances must be positive"))

    return (
        ids = pev_res.ids,
        values = Vector{Float64}(1 .- pev_res.values ./ animal_variance),
    )
end

function reliability(result::HendersonMMEResult; method::Symbol = :dense)
    pev = prediction_error_variance(result; method = method)
    A = inv(Symmetric(Matrix{Float64}(result.spec.Ainv)))
    animal_variance = result.sigma_a2 .* diag(A)

    all(>(0), animal_variance) ||
        throw(ArgumentError("animal-level additive variances must be positive"))

    return (
        ids = pev.ids,
        values = Vector{Float64}(1 .- pev.values ./ animal_variance),
    )
end

"""
    accuracy(fit)

Return animal-level accuracy values as `sqrt(reliability(fit))`.

This is a validation-scale extractor over the existing reliability method. It
does not add independent accuracy validation and it rejects non-finite or
out-of-range reliability values instead of silently clipping them.
"""
function accuracy(fit)
    return _accuracy_from_reliability(reliability(fit))
end

function _accuracy_from_reliability(reliability_result)
    ids = getproperty(reliability_result, :ids)
    values = Float64.(getproperty(reliability_result, :values))
    length(ids) == length(values) ||
        throw(ArgumentError("reliability ids and values must have the same length"))
    all(isfinite, values) ||
        throw(ArgumentError("reliability values must be finite to compute accuracy"))
    all(value -> 0 <= value <= 1, values) ||
        throw(ArgumentError("reliability values must be within [0, 1] to compute accuracy"))

    return (ids = collect(ids), values = sqrt.(values))
end

# Acklam (2003) rational approximation to the standard-normal quantile
# (|abs error| < 1.15e-9). Lets the heritability interval pick a two-sided z
# without a Distributions/SpecialFunctions dependency.
function _standard_normal_quantile(p::Real)
    0 < p < 1 || throw(ArgumentError("p must be in (0, 1)"))
    a = (-3.969683028665376e+01, 2.209460984245205e+02, -2.759285104469687e+02,
         1.383577518672690e+02, -3.066479806614716e+01, 2.506628277459239e+00)
    b = (-5.447609879822406e+01, 1.615858368580409e+02, -1.556989798598866e+02,
         6.680131188771972e+01, -1.328068155288572e+01)
    c = (-7.784894002430293e-03, -3.223964580411365e-01, -2.400758277161838e+00,
         -2.549732539343734e+00, 4.374664141464968e+00, 2.938163982698783e+00)
    d = (7.784695709041462e-03, 3.224671290700398e-01, 2.445134137142996e+00,
         3.754408661907416e+00)
    plow = 0.02425
    phigh = 1 - plow
    if p < plow
        q = sqrt(-2 * log(p))
        return (((((c[1] * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5]) * q + c[6]) /
               ((((d[1] * q + d[2]) * q + d[3]) * q + d[4]) * q + 1)
    elseif p <= phigh
        q = p - 0.5
        r = q * q
        return (((((a[1] * r + a[2]) * r + a[3]) * r + a[4]) * r + a[5]) * r + a[6]) * q /
               (((((b[1] * r + b[2]) * r + b[3]) * r + b[4]) * r + b[5]) * r + 1)
    else
        q = sqrt(-2 * log(1 - p))
        return -(((((c[1] * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5]) * q + c[6]) /
                ((((d[1] * q + d[2]) * q + d[3]) * q + d[4]) * q + 1)
    end
end

# 2x2 average-information (AI) matrix for (sigma_a2, sigma_e2) of the REML
# objective at the given variance components — the same AI metric fit_ai_reml
# uses. Its inverse is the asymptotic variance-component covariance. (Recomputed
# here rather than shared with the fit_ai_reml hot loop, which also needs the
# score and reuses its factor.)
function _reml_information_matrix(spec::AnimalModelSpec, sigma_a2::Real, sigma_e2::Real)
    X = Float64.(spec.X)
    Z = sparse(Float64.(spec.Z))
    y = Float64.(spec.y)
    nfixed = size(X, 2)
    lhs, rhs, _ = _sparse_mme_system(spec, sigma_a2, sigma_e2)
    factor = cholesky(Symmetric(lhs); check = true)
    solution = factor \ rhs
    beta = solution[1:nfixed]
    u = solution[(nfixed + 1):end]
    e = y .- X * beta .- Z * u
    wa = (Z * u) ./ sigma_a2
    we = e ./ sigma_e2
    Pwa = _reml_project(factor, X, Z, wa, sigma_e2, nfixed)
    Pwe = _reml_project(factor, X, Z, we, sigma_e2, nfixed)
    return Symmetric(0.5 .* [dot(wa, Pwa) dot(wa, Pwe); dot(we, Pwa) dot(we, Pwe)])
end

"""
    variance_component_covariance(fit)

Asymptotic covariance of the estimated `(sigma_a2, sigma_e2)` for a REML
[`AnimalModelFit`](@ref): the inverse of the average-information matrix. This is a
large-sample approximation and is unreliable on small samples, where the REML
surface is flat and the matrix is ill-conditioned. Experimental; REML only.
"""
function variance_component_covariance(fit::AnimalModelFit)
    fit.spec.method == :REML ||
        throw(ArgumentError("variance_component_covariance requires a REML fit"))
    info = _reml_information_matrix(
        fit.spec,
        fit.variance_components.sigma_a2,
        fit.variance_components.sigma_e2,
    )
    return inv(info)
end

"""
    variance_component_standard_errors(fit)

Asymptotic standard errors of `(sigma_a2, sigma_e2)` for a REML fit, as a
`NamedTuple`. See [`variance_component_covariance`](@ref) for the caveats.
"""
function variance_component_standard_errors(fit::AnimalModelFit)
    cov = variance_component_covariance(fit)
    return (sigma_a2 = sqrt(cov[1, 1]), sigma_e2 = sqrt(cov[2, 2]))
end

"""
    heritability_standard_error(fit)

Delta-method asymptotic standard error of `h² = sigma_a2 / (sigma_a2 + sigma_e2)`
for a REML fit, from [`variance_component_covariance`](@ref). Asymptotic; see the
caveats there.
"""
function heritability_standard_error(fit::AnimalModelFit)
    sigma_a2 = fit.variance_components.sigma_a2
    sigma_e2 = fit.variance_components.sigma_e2
    cov = variance_component_covariance(fit)
    denom = (sigma_a2 + sigma_e2)^2
    g = [sigma_e2 / denom, -sigma_a2 / denom]
    return sqrt(max(0.0, dot(g, cov * g)))
end

# Profile REML log-likelihood at a fixed heritability `h2`: maximize the REML
# objective over the total variance `V` along the ray
# `(sigma_a2, sigma_e2) = (h2*V, (1-h2)*V)`. A 1-D maximization reusing
# `sparse_reml_loglik`; the search bracket is anchored on the phenotypic-variance
# scale of `y`. `h2` must be strictly interior to `(0, 1)`. Used by the
# profile-likelihood heritability interval.
function _profile_reml_loglik(spec::AnimalModelSpec, h2::Real)
    0 < h2 < 1 || throw(ArgumentError("h2 must be in (0, 1)"))
    y = Float64.(spec.y)
    n = length(y)
    ybar = sum(y) / n
    v0 = max(sum(abs2, y .- ybar) / max(1, n - 1), eps())
    function objective(logV)
        V = exp(logV)
        try
            return -sparse_reml_loglik(spec, h2 * V, (1 - h2) * V).loglik
        catch err
            err isa PosDefException && return Inf
            rethrow()
        end
    end
    result = optimize(objective, log(v0 * 1e-4), log(v0 * 1e4))
    return -Optim.minimum(result)
end

# Profile REML log-likelihood at a fixed additive variance `sigma_a2`: maximize
# over the NUISANCE residual variance `sigma_e2`. The sigma_a2 companion of
# `_profile_reml_loglik` (which profiles total variance at fixed h²); a 1-D
# maximization reusing `sparse_reml_loglik`, bracketed on the phenotypic variance
# of `y`. Used by `variance_component_interval`.
function _profile_reml_loglik_sigma_a2(spec::AnimalModelSpec, sigma_a2::Real)
    sigma_a2 > 0 || throw(ArgumentError("sigma_a2 must be positive"))
    y = Float64.(spec.y)
    n = length(y)
    ybar = sum(y) / n
    v0 = max(sum(abs2, y .- ybar) / max(1, n - 1), eps())
    function objective(logE)
        sigma_e2 = exp(logE)
        try
            return -sparse_reml_loglik(spec, sigma_a2, sigma_e2).loglik
        catch err
            err isa PosDefException && return Inf
            rethrow()
        end
    end
    result = optimize(objective, log(v0 * 1e-6), log(v0 * 1e4))
    return -Optim.minimum(result)
end

# Root of `target` on the heritability axis for the profile interval. `anchor`
# is the point-estimate side where `target(anchor) < 0`; `bound` is the search
# boundary. If `target(bound) <= 0` the interval reaches the search bound and the
# (clamped) bound is returned; otherwise bisect to the crossing.
function _profile_root(target, bound::Real, anchor::Real)
    target(bound) > 0 || return float(bound)
    a, b = float(anchor), float(bound)
    for _ in 1:200
        m = 0.5 * (a + b)
        fm = target(m)
        (abs(fm) < 1e-9 || abs(b - a) < 1e-13) && return m
        fm < 0 ? (a = m) : (b = m)
    end
    return 0.5 * (a + b)
end

function _heritability_interval_profile(fit::AnimalModelFit; level::Real)
    fit.spec.method == :REML ||
        throw(ArgumentError("profile heritability interval requires a REML fit"))
    h2 = heritability(fit)
    0 < h2 < 1 ||
        throw(ArgumentError("heritability estimate is on the (0, 1) boundary; interval undefined"))
    spec = fit.spec
    llmax = _profile_reml_loglik(spec, h2)
    z = _standard_normal_quantile((1 + level) / 2)
    q = z * z
    target(h) = 2 * (llmax - _profile_reml_loglik(spec, h)) - q
    lower = _profile_root(target, 1e-6, h2)
    upper = _profile_root(target, 1 - 1e-6, h2)
    return (heritability = h2, lower = lower, upper = upper, level = level, method = :profile)
end

"""
    heritability_interval(fit; level = 0.95, method = :delta)

Experimental two-sided confidence interval for `h²` of a REML
[`AnimalModelFit`](@ref).

`method = :delta` (default) builds the interval on the logit scale (delta method)
and back-transforms, so it always lies in `(0, 1)`; it returns
`(heritability, lower, upper, level, se, method)`.

`method = :profile` inverts the REML likelihood-ratio statistic: it profiles the
REML log-likelihood over the total variance at each fixed `h²` and reports the
`h²` range where `2·(ℓmax − ℓprofile(h²)) ≤ χ²₁,level`. Endpoints that reach the
`(0, 1)` search bounds are clamped. It returns
`(heritability, lower, upper, level, method)` (no `se`).

Both are large-sample approximations: on small samples the REML surface is flat,
so the intervals are wide.
"""
function heritability_interval(fit::AnimalModelFit; level::Real = 0.95, method::Symbol = :delta)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1)"))
    if method === :profile
        return _heritability_interval_profile(fit; level = level)
    end
    method === :delta ||
        throw(ArgumentError("method must be :delta or :profile"))
    h2 = heritability(fit)
    0 < h2 < 1 ||
        throw(ArgumentError("heritability estimate is on the (0, 1) boundary; interval undefined"))
    se = heritability_standard_error(fit)
    z = _standard_normal_quantile((1 + level) / 2)
    eta = log(h2 / (1 - h2))
    se_eta = se / (h2 * (1 - h2))
    lower = 1 / (1 + exp(-(eta - z * se_eta)))
    upper = 1 / (1 + exp(-(eta + z * se_eta)))
    return (heritability = h2, lower = lower, upper = upper, level = level, se = se, method = :delta)
end

function _variance_component_interval_profile(fit::AnimalModelFit; level::Real)
    fit.spec.method == :REML ||
        throw(ArgumentError("profile variance-component interval requires a REML fit"))
    sigma_a2 = fit.variance_components.sigma_a2
    sigma_a2 > 0 ||
        throw(ArgumentError("sigma_a2 estimate is on the boundary; interval undefined"))
    spec = fit.spec
    llmax = _profile_reml_loglik_sigma_a2(spec, sigma_a2)
    z = _standard_normal_quantile((1 + level) / 2)
    q = z * z
    target(v) = 2 * (llmax - _profile_reml_loglik_sigma_a2(spec, v)) - q
    lo_bound = sigma_a2 * 1e-4
    up_bound = sigma_a2 * 1e4
    lower = _profile_root(target, lo_bound, sigma_a2)
    upper = _profile_root(target, up_bound, sigma_a2)
    lower_clamped = target(lo_bound) <= 0
    upper_clamped = target(up_bound) <= 0
    return (sigma_a2 = sigma_a2, lower = lower, upper = upper, level = level,
            lower_clamped = lower_clamped, upper_clamped = upper_clamped,
            method = :profile)
end

"""
    variance_component_interval(fit; level = 0.95, method = :profile)

Profile likelihood-ratio confidence interval for the additive variance component
`sigma_a2` of a REML [`AnimalModelFit`](@ref). It inverts
`2·(ℓmax − ℓprofile(sigma_a2)) ≤ χ²₁,level` while profiling the residual variance
`sigma_e2` as a NUISANCE at each candidate `sigma_a2` — the variance-component
companion of [`heritability_interval`](@ref) `method = :profile` (which profiles
the total variance at fixed `h²`).

Returns `(sigma_a2, lower, upper, level, lower_clamped, upper_clamped, method)`.
The `*_clamped` flags report an endpoint that reached the `(sigma_a2·1e-4,
sigma_a2·1e4)` search bound (the profile did not cross the χ² threshold within
range), so a non-crossing endpoint is self-describing — on small samples the REML
surface is flat and the interval clamps.

Applies unchanged to a genomic GBLUP / supplied-`Ginv` REML fit (`fit_gblup_reml`,
or any `method = :REML` spec with `Ginv` in the `Ainv` slot): the profiler reads
only the spec's precision through `sparse_reml_loglik`. On a genomic spec `sigma_a2`
is the GENOMIC additive variance and the interval is CONDITIONAL on the supplied
`Ginv` (ridge + centering), so the implied `A_ii = diag(inv(Ginv)) ≠ 1` — not a
pedigree-scale `sigma_a2`. A non-PD `Ginv` degrades to a clamped endpoint (the
`PosDefException` is caught as `Inf`), never a silent number.

Experimental, asymptotic, REML only; no coverage calibration.
"""
function variance_component_interval(fit::AnimalModelFit; level::Real = 0.95,
                                     method::Symbol = :profile)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1)"))
    method === :profile ||
        throw(ArgumentError("variance_component_interval supports method = :profile only"))
    return _variance_component_interval_profile(fit; level = level)
end

"""
    variance_components_plot_data(fit::AnimalModelFit; level = 0.95)

Plot-ready data for the variance-component + heritability forest figure (plotting
set B): tidy parallel vectors `(term, estimate, lo, hi, panel, level,
interval_method, interval_status, supplied = false)` shaped to drop directly into
the R `hs_gg_forest` contract. The variance-component rows (`sigma_a2`, `sigma_e2`)
carry asymptotic `estimate ± z·SE` — NOT clamped, since an asymptotic CI can cross
zero (surfaced, never hidden); the `h2` row carries the logit-delta
[`heritability_interval`](@ref) (always in `(0,1)`). `lo`/`hi` are `NaN` where the
interval is unavailable (no fabricated whiskers); `interval_status` is
`"experimental_asymptotic"` (NOT coverage-calibrated) when any interval is present,
else `"none"`. `interval_method` is a coarse roll-up tag (`"asymptotic_reml"`):
the VC-row whiskers are normal-Wald on the raw variance scale, the `h2`-row whisker
is the logit-delta back-transform — both asymptotic, both from the REML AI matrix.
`supplied = false` is the honest-status hinge — these are ESTIMATED, unlike the
descriptive supplied-`K_g`/`G` plot-data sets. Intervals are REML-only; a non-REML
fit degrades gracefully to points-only (`lo`/`hi` all `NaN`, `interval_status =
"none"`).
"""
function variance_components_plot_data(fit::AnimalModelFit; level::Real = 0.95)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1)"))
    vc = variance_components(fit)
    h2 = heritability(fit)
    z = _standard_normal_quantile((1 + level) / 2)
    vc_lo = [NaN, NaN]
    vc_hi = [NaN, NaN]
    try
        se = variance_component_standard_errors(fit)
        vc_lo = [vc.sigma_a2 - z * se.sigma_a2, vc.sigma_e2 - z * se.sigma_e2]
        vc_hi = [vc.sigma_a2 + z * se.sigma_a2, vc.sigma_e2 + z * se.sigma_e2]
    catch
    end
    h2_lo = NaN
    h2_hi = NaN
    try
        ci = heritability_interval(fit; level = level)
        h2_lo = ci.lower
        h2_hi = ci.upper
    catch
    end
    has_interval = any(isfinite, vc_lo) || isfinite(h2_lo)
    return (term = ["sigma_a2", "sigma_e2", "h2"],
            estimate = [vc.sigma_a2, vc.sigma_e2, h2],
            lo = [vc_lo[1], vc_lo[2], h2_lo],
            hi = [vc_hi[1], vc_hi[2], h2_hi],
            panel = ["variance components", "variance components", "heritability"],
            level = Float64(level),
            interval_method = has_interval ? "asymptotic_reml" : "none",
            interval_status = has_interval ? "experimental_asymptotic" : "none",
            supplied = false)
end

"""
    breeding_values_plot_data(fit::AnimalModelFit; trait = 1)

Plot-ready data for the EBV "caterpillar" figure (plotting set B): tidy parallel
vectors `(id, trait, value, pev, pev_scale)` shaped to drop directly into the R
`autoplot.R` breeding-value plot (per the #93 R-twin alignment — this closes the last
live-parity gap R flagged). `value` is the EBV ([`breeding_values`](@ref)), `pev` the
prediction error variance ([`prediction_error_variance`](@ref), dense path), and
`pev_scale = "validation"` is the honest-status flag: the PEV denominator forms the
dense `inv(Ainv)`, so it is VALIDATION-scale, NOT a production large-pedigree
reliability claim. The R column convention is followed exactly (EBV as `value`).
Univariate `AnimalModelFit`; `trait` is the (single) trait label. Plot-DATA only —
no drawing backend, no estimation.
"""
function breeding_values_plot_data(fit::AnimalModelFit; trait = 1)
    bv = breeding_values(fit)
    pev = prediction_error_variance(fit)
    n = length(bv.values)
    return (id = collect(bv.ids),
            trait = fill(trait, n),
            value = collect(bv.values),
            pev = collect(pev.values),
            pev_scale = "validation")
end

"""
    result_payload(fit)

Return a bridge-facing result payload with field names aligned to the R
`hsquared_fit` contract.

This is an experimental low-level payload. It is intended to make the R-Julia
result shape explicit before live bridge execution is widened beyond tiny
validation paths.

The payload includes `prediction_error_variance` and `reliability` as standard
fields (each a `(ids, values)` named tuple). The PEV is computed through the
`O(nnz(L))` (sparse-scalable) Takahashi selected inverse (`method = :selinv`),
which matches the dense MME inverse diagonal to machine precision for
well-conditioned validation-scale fits (`V1-SELINV-PEV`). The R twin unpacks
these top-level fields directly via `hs_julia_id_values()` (`hsquared#21`), so
the opportunistic per-extractor enrichment is no longer required. The PEV is
computed once here and reused by `reliability` (no second factorization). This
remains a validation-scale path, not a production large-pedigree reliability
claim: in particular the `reliability` denominator still forms the dense
`A = inv(Ainv)` for the animal self-relationships (a sparse selected-inverse
diagonal of `Ainv` is the production-direction follow-up).
"""
function result_payload(fit::AnimalModelFit)
    vc = variance_components(fit)
    beta = fixed_effects(fit)
    bv = breeding_values(fit)
    predictions = fitted_values(fit)
    pev = prediction_error_variance(fit; method = :selinv)
    rel = reliability(fit; method = :selinv, pev = pev)

    return (
        variance_components = vc,
        heritability = heritability(fit),
        breeding_values = (ids = bv.ids, values = bv.values),
        fixed_effects = beta,
        random_effects = (animal = (ids = bv.ids, values = bv.values),),
        loglik = fit.likelihood.loglik,
        df = fit.likelihood.nfixed + length(vc),
        nobs = fit.likelihood.nobs,
        predictions = predictions,
        prediction_error_variance = (ids = pev.ids, values = pev.values),
        reliability = (ids = rel.ids, values = rel.values),
        diagnostics = (
            converged = fit.converged,
            optimizer_status = fit.optimizer_status,
            iterations = fit.iterations,
            method = fit.likelihood.method,
            dense_validation_path = fit.dense_validation_path,
        ),
        converged = fit.converged,
    )
end

function _coerce_initial_variances(initial::NamedTuple)
    haskey(initial, :sigma_a2) ||
        throw(ArgumentError("initial must include sigma_a2"))
    haskey(initial, :sigma_e2) ||
        throw(ArgumentError("initial must include sigma_e2"))
    return Float64(initial.sigma_a2), Float64(initial.sigma_e2)
end

function _coerce_initial_variances(initial::Tuple)
    length(initial) == 2 ||
        throw(ArgumentError("initial must contain two variance components"))
    return Float64(initial[1]), Float64(initial[2])
end

function _coerce_initial_variances(initial::AbstractVector)
    length(initial) == 2 ||
        throw(ArgumentError("initial must contain two variance components"))
    return Float64(initial[1]), Float64(initial[2])
end

function _coerce_initial_variances(initial)
    throw(ArgumentError("initial must be a NamedTuple, tuple, or vector"))
end

function _coerce_fit_target(target::Symbol)
    target in (:variance_components, :dense_validation) && return :variance_components
    target in (:sparse_reml, :sparse_reml_validation) && return :sparse_reml
    target in (:ai_reml, :ai_reml_validation) && return :ai_reml
    target in (:eigen, :eigen_reml) && return :eigen_reml
    target in (:matrix_free, :matrix_free_reml) && return :matrix_free_reml
    target == :auto && return :auto
    target == :henderson_mme && return :henderson_mme
    throw(ArgumentError("target must be :variance_components, :sparse_reml, :ai_reml, :eigen_reml, " *
                        ":matrix_free_reml, :auto, or :henderson_mme"))
end

function _coerce_fit_target(target::AbstractString)
    return _coerce_fit_target(Symbol(target))
end

function _coerce_fit_target(target)
    throw(ArgumentError("target must be a Symbol or string"))
end

function _coerce_supplied_variance_components(::Nothing)
    throw(ArgumentError("variance_components must be supplied when target = :henderson_mme"))
end

function _coerce_supplied_variance_components(variance_components::NamedTuple)
    haskey(variance_components, :sigma_a2) ||
        throw(ArgumentError("variance_components must include sigma_a2"))
    haskey(variance_components, :sigma_e2) ||
        throw(ArgumentError("variance_components must include sigma_e2"))
    return Float64(variance_components.sigma_a2), Float64(variance_components.sigma_e2)
end

function _coerce_supplied_variance_components(variance_components::Tuple)
    length(variance_components) == 2 ||
        throw(ArgumentError("variance_components must contain two values"))
    return Float64(variance_components[1]), Float64(variance_components[2])
end

function _coerce_supplied_variance_components(variance_components::AbstractVector)
    length(variance_components) == 2 ||
        throw(ArgumentError("variance_components must contain two values"))
    return Float64(variance_components[1]), Float64(variance_components[2])
end

function _coerce_supplied_variance_components(variance_components)
    throw(ArgumentError("variance_components must be a NamedTuple, tuple, or vector"))
end

function _dense_marginal_covariance(Z::AbstractMatrix, A::AbstractMatrix, sigma_a2, sigma_e2)
    n = size(Z, 1)
    return Symmetric(sigma_a2 * Z * A * transpose(Z) + sigma_e2 * I(n))
end

function _sparse_mme_system(spec::AnimalModelSpec, sigma_a2::Real, sigma_e2::Real)
    y = Float64.(spec.y)
    X = sparse(Float64.(spec.X))
    Z = sparse(Float64.(spec.Z))
    Ainv = sparse(Float64.(spec.Ainv))

    residual_precision = inv(Float64(sigma_e2))
    relationship_precision = inv(Float64(sigma_a2))

    Xt = transpose(X)
    Zt = transpose(Z)
    lhs = [
        residual_precision * (Xt * X) residual_precision * (Xt * Z)
        residual_precision * (Zt * X) residual_precision * (Zt * Z) + relationship_precision * Ainv
    ]
    rhs = [
        residual_precision * (Xt * y);
        residual_precision * (Zt * y)
    ]

    return lhs, rhs, residual_precision * dot(y, y)
end

function _check_dense_validation_size(spec::AnimalModelSpec, max_dense_cells::Integer)
    max_dense_cells > 0 ||
        throw(ArgumentError("max_dense_cells must be a positive integer"))

    nobs = length(spec.y)
    nanimals = size(spec.Ainv, 1)
    dense_cells = nobs * nobs + nanimals * nanimals
    dense_cells <= max_dense_cells ||
        throw(
            ArgumentError(
                "dense validation path would allocate at least $(dense_cells) dense covariance/relationship cells; increase max_dense_cells for tiny validation work or wait for the sparse production solver",
            ),
        )

    return dense_cells
end

function _dense_mme_random_inverse_block(
    spec::AnimalModelSpec,
    sigma_a2::Real,
    sigma_e2::Real,
)
    X = Matrix{Float64}(spec.X)
    Z = Matrix{Float64}(spec.Z)
    Ainv = Matrix{Float64}(spec.Ainv)

    residual_precision = inv(sigma_e2)
    relationship_precision = Ainv / sigma_a2

    lhs = [
        residual_precision * transpose(X) * X residual_precision * transpose(X) * Z
        residual_precision * transpose(Z) * X residual_precision * transpose(Z) * Z + relationship_precision
    ]
    inverse_lhs = inv(Symmetric(lhs))
    nfixed = size(X, 2)
    return inverse_lhs[(nfixed + 1):end, (nfixed + 1):end]
end

# Prediction error variances = diagonal of the random-effect block of the MME
# coefficient-matrix inverse. `:dense` forms and inverts the dense MME (the tiny
# validation reference); `:selinv` uses the Takahashi selected inverse of the
# sparse MME coefficient matrix in O(nnz(L)). Both paths use the identical
# coefficient matrix, so the diagonal agrees to machine precision.
function _pev_values(spec::AnimalModelSpec, sigma_a2::Real, sigma_e2::Real, method::Symbol)
    if method === :selinv
        return _selinv_mme_random_pev(spec, sigma_a2, sigma_e2)
    elseif method === :dense
        block = _dense_mme_random_inverse_block(spec, sigma_a2, sigma_e2)
        return Vector{Float64}(diag(block))
    else
        throw(ArgumentError("prediction-error-variance method must be :dense or :selinv"))
    end
end

# Sparse selected-inversion PEV: the diagonal of C^-1 at the random-effect rows,
# where C is the sparse Henderson MME coefficient matrix from
# `_sparse_mme_system`. The diagonal is always in the L+Lᵀ pattern, so
# `takahashi_diag` returns it exactly.
function _selinv_mme_random_pev(spec::AnimalModelSpec, sigma_a2::Real, sigma_e2::Real)
    lhs, _, _ = _sparse_mme_system(spec, sigma_a2, sigma_e2)
    factor = cholesky(Symmetric(lhs); check = true)
    diag_inv = takahashi_diag(factor)
    nfixed = size(spec.X, 2)
    return Vector{Float64}(diag_inv[(nfixed + 1):end])
end

"""
    bootstrap_variance_component_interval(fit::AnimalModelFit; level = 0.95,
        n_boot = 1000, estimator = :sparse_reml,
        rng = Random.MersenneTwister(0x48324352), max_dense_cells = $(DEFAULT_MAX_DENSE_CELLS))

Parametric (Gaussian) bootstrap percentile confidence intervals for `sigma_a2`,
`sigma_e2`, and `h² = σ²a/(σ²a+σ²e)` of a fitted univariate Gaussian REML animal
model — a cross-check on the asymptotic delta / profile-LRT intervals
([`heritability_interval`](@ref), [`variance_component_interval`](@ref)).

Mechanism: at the fitted `(β, σ²a, σ²e)`, simulate Gaussian responses over the
SUPPLIED relationship — `a* = chol(inv(Ainv)).L · randn · √σ²a`,
`e* = randn · √σ²e`, `y* = Xβ + Za* + e*` — refit each replicate with the SAME REML
estimator (`:sparse_reml` → [`fit_sparse_reml`](@ref); `:ai_reml` →
[`fit_ai_reml`](@ref)), and take percentile endpoints from the converged replicate
vectors via the in-package type-7 `_empirical_upper_quantile` (no `Statistics`
dependency). A replicate whose refit throws (`PosDefException`, etc.) or returns a
non-finite/boundary variance is DROPPED and counted: `n_converged` reports how many
of `n_boot` survived (non-convergence is surfaced, not hidden).

Returns a `NamedTuple`: `sigma_a2`, `sigma_e2`, `heritability` (the point estimates
from `fit`); `sigma_a2_ci`, `sigma_e2_ci`, `heritability_ci` (each `(lower, upper)`);
`level`, `n_boot`, `n_converged`, `method = :parametric_bootstrap_percentile`; and
`replicates` (the per-component converged-replicate vectors).

The interval FUNCTION is deterministic: `rng` defaults to a fixed-seed
`MersenneTwister`, so the result is reproducible at the call site (only opt-in sim
harnesses vary the seed).

EXPERIMENTAL, REML-only, univariate-Gaussian, dense/validation-scale (it forms
`inv(Ainv)` + `chol(A)`, guarded by `max_dense_cells`). It is a PERCENTILE bootstrap
(BCa is out of scope); its OWN coverage is NOT calibrated in CI (an opt-in coverage
sim is deferred follow-up) — it is the cross-check the delta/profile interval debt
names, not evidence that those intervals are correct. Rejects non-REML fits;
multivariate / non-Gaussian bootstrap CIs are separate slices.
"""
function bootstrap_variance_component_interval(fit::AnimalModelFit; level::Real = 0.95,
                                               n_boot::Integer = 1000,
                                               estimator::Symbol = :sparse_reml,
                                               rng::AbstractRNG = Random.MersenneTwister(0x48324352),
                                               max_dense_cells::Integer = DEFAULT_MAX_DENSE_CELLS)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1)"))
    n_boot > 0 || throw(ArgumentError("n_boot must be a positive integer"))
    estimator in (:sparse_reml, :ai_reml) ||
        throw(ArgumentError("estimator must be :sparse_reml or :ai_reml"))
    spec = fit.spec
    spec.method == :REML ||
        throw(ArgumentError("bootstrap_variance_component_interval requires a REML fit (spec.method == :REML)"))
    _check_dense_validation_size(spec, max_dense_cells)

    X = Matrix{Float64}(spec.X)
    Z = Matrix{Float64}(spec.Z)
    A = inv(Symmetric(Matrix{Float64}(Matrix(spec.Ainv))))
    LA = cholesky(Symmetric(A)).L
    beta = Float64.(fit.likelihood.beta)
    s2a = fit.variance_components.sigma_a2
    s2e = fit.variance_components.sigma_e2
    h2 = s2a / (s2a + s2e)
    n = length(spec.y); q = size(Z, 2)
    mu = X * beta
    refit = estimator === :sparse_reml ? fit_sparse_reml : fit_ai_reml

    sa = Float64[]; se = Float64[]; hh = Float64[]
    for _ in 1:n_boot
        ystar = mu .+ Z * (LA * randn(rng, q) .* sqrt(s2a)) .+ randn(rng, n) .* sqrt(s2e)
        try
            spec_b = animal_model_spec(ystar, X, Z, spec.Ainv; ids = spec.ids, method = :REML)
            fb = refit(spec_b)
            sab = fb.variance_components.sigma_a2; seb = fb.variance_components.sigma_e2
            (isfinite(sab) && isfinite(seb) && sab > 0 && seb > 0) || continue
            push!(sa, sab); push!(se, seb); push!(hh, sab / (sab + seb))
        catch
            # PosDefException / non-converged refit → dropped, surfaced via n_converged
        end
    end
    n_conv = length(sa)
    n_conv > 0 ||
        throw(ArgumentError("no bootstrap replicate converged to a finite interior optimum; no interval is reported"))
    plo = (1 - level) / 2; phi = (1 + level) / 2
    _ci(v) = (lower = _empirical_upper_quantile(v, plo), upper = _empirical_upper_quantile(v, phi))
    return (sigma_a2 = s2a, sigma_e2 = s2e, heritability = h2,
            sigma_a2_ci = _ci(sa), sigma_e2_ci = _ci(se), heritability_ci = _ci(hh),
            level = Float64(level), n_boot = Int(n_boot), n_converged = n_conv,
            method = :parametric_bootstrap_percentile,
            replicates = (sigma_a2 = sa, sigma_e2 = se, heritability = hh))
end
