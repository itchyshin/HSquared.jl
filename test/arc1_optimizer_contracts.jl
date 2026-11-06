using LinearAlgebra
using Random
using Test
using HSquared

if !isdefined(HSquared, :_arc1_fa_spectral_context)
    Base.include(HSquared, joinpath(@__DIR__, "..", "src", "arc1_fa.jl"))
end

function _arc1_optimizer_fixture()
    rng = MersenneTwister(810204)
    n = 8
    ped = HSquared.normalize_pedigree(collect(1:n),
        [0, 0, 0, 0, 1, 1, 2, 3], [0, 0, 0, 0, 2, 3, 3, 4])
    Ainv = Matrix(HSquared.pedigree_inverse(ped))
    A = Matrix(inv(Symmetric(Ainv)))
    Z = Matrix{Float64}(I, n, n)
    B = Z * A * transpose(Z)
    X = ones(n, 1)
    λ = [0.62, -0.44, 0.31, -0.53]
    ψ = [0.24, 0.33, 0.29, 0.21]
    G = λ * transpose(λ) + Diagonal(ψ)
    R = [0.7 0.08 0.03 0.0; 0.08 0.8 0.06 0.02;
         0.03 0.06 0.75 0.04; 0.0 0.02 0.04 0.72]
    V = kron(B, G) + kron(Matrix{Float64}(I, n, n), R)
    μ = repeat(reshape([0.2, 0.7, -0.4, 1.0], 1, 4), n, 1)
    Y = μ + reshape(cholesky(Symmetric(V)).L * randn(rng, 4n), 4, n)'
    (; Y, X, Z, Ainv, A, B, ped, λ, ψ, G, R)
end

# Captured from `_arc1_optimizer_fixture()` on Julia 1.10.12 with seed 810204.
# Julia's seeded normal stream differs by version, so the two ranking-specific
# tests use the same observed data without weakening their guard assertions.
function _arc1_optimizer_fixed_fixture()
    Y = [
        -0.40140207525058874 2.559604366527611 0.8333169121961425 0.6704617581383823;
        1.9068741079634872 1.1662718789008413 -0.3248133038090736 1.364759328617372;
        0.08481432080100494 0.6851698976958058 -0.3546044389663982 1.4783444083769548;
        -0.3296888810486585 0.4273958657578079 -1.020589712937248 1.8666001356852273;
        0.6171536929192267 1.5792911149303972 -2.3586701402876407 1.8521925956824572;
        -1.407588866109029 1.0807938526967908 -0.532642796689568 1.0212517691639607;
        1.4684314692762959 1.043497495705527 0.7311767298254738 -0.5431312235017971;
        0.11644743095380924 0.6907329195315112 -0.6331671664544012 1.2088708669483672
    ]
    return merge(_arc1_optimizer_fixture(), (; Y))
end

function _arc1_optimizer_params(λ, ψ, R)
    L = Matrix(cholesky(Symmetric(R)).L)
    rp = Float64[]
    for j in 1:4, i in j:4
        push!(rp, i == j ? log(L[i, j]) : L[i, j])
    end
    vcat(λ, log.(ψ .- HSquared.FA_UNIQUENESS_FLOOR), rp)
end

function _arc1_optimizer_params_from_factor(λ, ψ, L)
    chol = Float64[]
    for j in 1:4, i in j:4
        push!(chol, i == j ? log(L[i, j]) : L[i, j])
    end
    vcat(λ, log.(ψ .- HSquared.FA_UNIQUENESS_FLOOR), chol)
end

function _arc1_bigfloat_reml_reference(params, Y, X, B, k; precision = 256)
    setprecision(BigFloat, precision) do
        theta = BigFloat.(params)
        Yb, Xb, Bb = BigFloat.(Y), BigFloat.(X), BigFloat.(B)
        if k == 0
            ψ = BigFloat(HSquared.FA_UNIQUENESS_FLOOR) .+ exp.(theta[1:4])
            G = Matrix(Diagonal(ψ))
            chol_start = 5
        else
            λ = theta[1:4]
            ψ = BigFloat(HSquared.FA_UNIQUENESS_FLOOR) .+ exp.(theta[5:8])
            G = λ * transpose(λ) + Diagonal(ψ)
            chol_start = 9
        end
        L = zeros(BigFloat, 4, 4)
        idx = chol_start - 1
        for j in 1:4, i in j:4
            idx += 1
            L[i, j] = i == j ? exp(theta[idx]) : theta[idx]
        end
        R = L * transpose(L)
        n = size(Yb, 1)
        I4 = Matrix{BigFloat}(I, 4, 4)
        V = kron(Bb, G) + kron(Matrix{BigFloat}(I, n, n), R)
        Xfull = kron(Xb, I4)
        y = vec(permutedims(Yb))
        FV = cholesky(Symmetric(V))
        Vinv = FV \ Matrix{BigFloat}(I, length(y), length(y))
        C = transpose(Xfull) * Vinv * Xfull
        FC = cholesky(Symmetric(C))
        β = FC \ (transpose(Xfull) * Vinv * y)
        e = y - Xfull * β
        df = length(y) - size(Xfull, 2)
        raw = (BigFloat(0.5) * (df * log(2big(pi)) + logdet(FV) +
            logdet(FC) + dot(e, Vinv * e)))
        return (; objective = raw / df, raw_objective = raw,
            fixed_effects = permutedims(reshape(Float64.(β), 4, size(X, 2))))
    end
end

function _arc1_bigfloat_reml_gradient(params, Y, X, B, k;
    precision = 256, relative_step = "1e-24")
    setprecision(BigFloat, precision) do
        theta = BigFloat.(params)
        gradient = Vector{Float64}(undef, length(theta))
        for j in eachindex(theta)
            h = BigFloat(relative_step) * max(BigFloat(1), abs(theta[j]))
            plus, minus = copy(theta), copy(theta)
            plus[j] += h
            minus[j] -= h
            fp = _arc1_bigfloat_reml_reference(plus, Y, X, B, k;
                precision).objective
            fm = _arc1_bigfloat_reml_reference(minus, Y, X, B, k;
                precision).objective
            gradient[j] = Float64((fp - fm) / (2h))
        end
        gradient
    end
end

function _arc1_dense_reml_reference(params, Y, X, B, k)
    if k == 0
        ψ = HSquared._fa_uniqueness_from_unconstrained(@view params[1:4])
        G = Matrix(Diagonal(ψ))
        chol = @view params[5:14]
    else
        λ = Float64.(@view params[1:4])
        ψ = HSquared._fa_uniqueness_from_unconstrained(@view params[5:8])
        G = λ * transpose(λ) + Diagonal(ψ)
        chol = @view params[9:18]
    end
    R = HSquared._chol_params_to_cov(chol, 4)
    n, t = size(Y)
    Xfull = kron(X, Matrix{Float64}(I, t, t))
    y = vec(permutedims(Y))
    V = kron(B, G) + kron(Matrix{Float64}(I, n, n), R)
    FV = cholesky(Symmetric(V))
    Vinv = FV \ Matrix{Float64}(I, length(y), length(y))
    C = transpose(Xfull) * Vinv * Xfull
    FC = cholesky(Symmetric(C))
    β = FC \ (transpose(Xfull) * Vinv * y)
    e = y - Xfull * β
    df = length(y) - size(Xfull, 2)
    raw = 0.5 * (df * log(2π) + logdet(FV) + logdet(FC) + dot(e, Vinv * e))
    (; objective = raw / df, raw_objective = raw,
       fixed_effects = permutedims(reshape(β, t, size(X, 2))))
end

function _arc1_dense_reml_gradient(params, Y, X, B, k)
    gradient = similar(Float64.(params))
    for j in eachindex(params)
        h = 1e-5 * max(1.0, abs(params[j]))
        plus, minus = copy(Float64.(params)), copy(Float64.(params))
        plus[j] += h
        minus[j] -= h
        gradient[j] = (_arc1_dense_reml_reference(plus, Y, X, B, k).objective -
                       _arc1_dense_reml_reference(minus, Y, X, B, k).objective) / (2h)
    end
    gradient
end

function _arc1_direct_linesearch(f, derivative; x0 = 0.0, alpha = 1.0,
                                 max_domain_restarts = 32,
                                 max_callback_requests = 256, make_pair = nothing,
                                 observation_events = nothing, evaluate_observer = nothing,
                                 line_search_stats = nothing)
    NLS = HSquared.Optim.NLSolversBase
    x = [Float64(x0)]
    stats = line_search_stats === nothing ?
        HSquared._Arc1LineSearchStats(; observation_events) : line_search_stats
    objective = z -> begin
        value = f(z[1])
        evaluate_observer === nothing || evaluate_observer(stats, z[1], value)
        value
    end
    g! = function (g, z)
        g[1] = derivative(z[1])
        g
    end
    df = NLS.OnceDifferentiable(objective, g!, x)
    phi0, grad0 = NLS.value_gradient!(df, x)
    dphi0 = grad0[1]
    xnew = copy(x)
    options = (; max_domain_restarts, max_callback_requests)
    ls = make_pair === nothing ? HSquared._Arc1DomainHagerZhang(stats; options...) :
        HSquared._Arc1DomainHagerZhang(stats; options..., make_pair)
    result = try
        (value = ls(df, x, [1.0], alpha, xnew, phi0, dphi0), error = nothing)
    catch err
        (value = nothing, error = err)
    end
    (; result..., x, xnew, df, stats, phi0, dphi0)
end

@testset "ARC1 optimizer and opt-in policy contracts" begin
    @testset "spectral context caches record rotations outside evaluations" begin
        d = _arc1_optimizer_fixture()
        built = HSquared._arc1_fa_spectral_context(d.Y, d.X, d.B)
        @test built.status == :ok
        ctx = built.context
        @test length(ctx.design_blocks) == size(d.Y, 1)
        @test length(ctx.response_blocks) == size(d.Y, 1)
        @test ctx.df == 4 * size(d.Y, 1) - 4 * size(d.X, 2)
        p = _arc1_optimizer_params(d.λ, d.ψ, d.R)
        one = HSquared._arc1_fa_exact_objective_gradient(ctx, p, 1)
        two = HSquared._arc1_fa_exact_objective_gradient(ctx, p, 1)
        @test one.status == :ok
        @test two.objective == one.objective
        @test two.gradient == one.gradient
        @test one.objective ≈ one.raw_objective / ctx.df atol = 1e-12 rtol = 0
    end

    @testset "v1 factorized spectral blocks preserve eigenvalue cases" begin
        Rfactor = [1.3 0.0 0.0 0.0; 0.2 1.1 0.0 0.0;
                   -0.1 0.15 0.9 0.0; 0.05 -0.08 0.12 1.2]
        ψ = [0.2, 0.35, 0.18, 0.42]
        λ = [0.7, -0.4, 0.25, 0.55]
        cases = ((0, hcat(Matrix(Diagonal(sqrt.(ψ))), zeros(4, 1))),
                 (1, hcat(Matrix(Diagonal(sqrt.(ψ))), λ)))
        dvalues = (0.0, nextfloat(0.0), 0.7, 1.4, 1.4)
        for (rank, Gfactor) in cases, dvalue in dvalues
            block = HSquared._arc1_fa_v1_block_factor(Rfactor, Gfactor, dvalue)
            @test block.status == :ok
            @test all(isfinite, block.factor)
            @test all(diag(block.factor) .> 0)
            @test istril(block.factor)
            expected = Rfactor * transpose(Rfactor) + dvalue *
                (Gfactor * transpose(Gfactor))
            @test block.factor * transpose(block.factor) ≈ expected atol = 1e-12 rtol = 1e-12
            @test all(isfinite, block.inverse)
            @test block.inverse ≈ inv(Symmetric(expected)) atol = 1e-10 rtol = 1e-10
            @test block.logdet ≈ logdet(Symmetric(expected)) atol = 1e-10 rtol = 1e-10
        end
        zero_rank1 = HSquared._arc1_fa_v1_block_factor(Rfactor, cases[2][2], 0.0)
        @test zero_rank1.factor * transpose(zero_rank1.factor) == Rfactor * transpose(Rfactor)
    end

    @testset "v1 factorized block guards retain strict floor and numerical failures" begin
        Rfactor = Matrix{Float64}(I, 4, 4)
        ψ = fill(HSquared.FA_UNIQUENESS_FLOOR + 1e-8, 4)
        Gfactor = hcat(Matrix(Diagonal(sqrt.(ψ))), fill(1e8, 4))
        @test minimum(ψ .- HSquared.FA_UNIQUENESS_FLOOR) > 0
        rounded_G = fill(1e16, 4, 4) + Diagonal(ψ)
        @test !isposdef(Symmetric(rounded_G))
        retained = HSquared._arc1_fa_v1_block_factor(Rfactor, Gfactor, 0.5)
        @test retained.status == :ok
        @test all(isfinite, retained.factor)
        @test all(isfinite, retained.inverse)
        @test isfinite(retained.logdet)

        @test HSquared._arc1_fa_v1_block_factor(fill(NaN, 4, 4), Gfactor, 1.0).status == :failed
        @test HSquared._arc1_fa_v1_block_factor(Rfactor, Gfactor, Inf).status == :failed
        @test HSquared._arc1_fa_v1_block_factor(Rfactor, Gfactor, -1.0).status == :failed
        tiny = nextfloat(0.0)
        underflowed = zeros(4, 1)
        underflowed[1] = tiny
        @test HSquared._arc1_fa_v1_block_factor(Rfactor, underflowed, tiny).status == :failed
        @test HSquared._arc1_fa_v1_block_factor(zeros(4, 4), Gfactor, 1.0).status == :failed
        @test HSquared._arc1_fa_v1_block_factor(Matrix(Diagonal(fill(1e-309, 4))),
            zeros(4, 1), 0.0).status == :failed
        d = _arc1_optimizer_fixture()
        ctx = HSquared._arc1_fa_spectral_context(d.Y, d.X, d.B).context
        p = _arc1_optimizer_params(d.λ, d.ψ, d.R)
        poverflow = copy(p)
        poverflow[1] = 1e308
        overflowed_G = HSquared._arc1_fa_exact_objective_gradient(ctx, poverflow, 1)
        @test overflowed_G.status == :invalid_proposal
        @test occursin("finite", overflowed_G.reason)
        poverflow_R = copy(p)
        poverflow_R[9] = 400.0
        overflowed_R = HSquared._arc1_fa_exact_objective_gradient(ctx, poverflow_R, 1)
        @test overflowed_R.status == :invalid_proposal
        @test occursin("finite", overflowed_R.reason)
        punderflow = copy(p)
        punderflow[end - 9] = -1000.0
        @test HSquared._arc1_fa_exact_objective_gradient(ctx, punderflow, 1).status == :invalid_proposal

        strict_ψ = fill(HSquared.FA_UNIQUENESS_FLOOR + 1e-8, 4)
        retained_params = _arc1_optimizer_params(fill(1e8, 4), strict_ψ, d.R)
        retained_G = fill(1e16, 4, 4) + Diagonal(strict_ψ)
        @test all(isfinite, retained_G)
        @test !isposdef(Symmetric(retained_G))
        @test minimum(strict_ψ .- HSquared.FA_UNIQUENESS_FLOOR) > 0
        retained_eval = HSquared._arc1_fa_exact_objective_gradient(ctx, retained_params, 1)
        @test retained_eval.status == :invalid_proposal
        @test retained_eval.reason !== nothing &&
            occursin("positive definite", retained_eval.reason)

        # Nearby internal proposals retain the strict uniqueness floor but
        # must be refused because their rounded dense genetic covariance is
        # not positive definite at Float64 precision.
        for (λscale, extra_ψ) in ((1 - 1e-8, 0.9e-8), (1.0, 1e-8),
                                  (1 + 1e-8, 1.1e-8))
            nearby_ψ = fill(HSquared.FA_UNIQUENESS_FLOOR + extra_ψ, 4)
            nearby_λ = fill(1e8 * λscale, 4)
            nearby_G = nearby_λ * transpose(nearby_λ) + Diagonal(nearby_ψ)
            @test minimum(nearby_ψ .- HSquared.FA_UNIQUENESS_FLOOR) > 0
            @test all(isfinite, nearby_G)
            @test !isposdef(Symmetric(nearby_G))
            nearby_params = _arc1_optimizer_params(nearby_λ, nearby_ψ, d.R)
            nearby_eval = HSquared._arc1_fa_exact_objective_gradient(ctx, nearby_params, 1)
            @test nearby_eval.status == :invalid_proposal
            @test nearby_eval.reason !== nothing &&
                occursin("positive definite", nearby_eval.reason)
        end

    end

    @testset "v1 collinear residual factor agrees with BigFloat full REML oracle" begin
        n = 5
        Y = [0.1i + 0.03t^2 + sin(i * t / 3) for i in 1:n, t in 1:4]
        X = hcat(ones(n), collect(range(-1.0, 1.0; length = n)))
        # Keep all likelihood blocks away from the residual-only singular limit
        # while still testing the rounded non-PD residual Gram in the factors.
        eigenvalues = [0.5, 0.75, 1.0, 1.5, 2.0]
        B = Matrix(Diagonal(eigenvalues))
        U = Matrix{Float64}(I, n, n)
        ctx = HSquared._arc1_fa_context_from_eigen(Y, X, eigenvalues, U; B).context
        L = [1.0 0.0 0.0 0.0;
             1.0 1e-9 0.0 0.0;
             0.2 0.1 0.8 0.0;
             0.15 -0.1 0.2 1.1]
        ψ = fill(0.3, 4)
        λ = [0.7, -0.4, 0.25, 0.55]
        params = _arc1_optimizer_params_from_factor(λ, ψ, L)
        rounded_R = L * transpose(L)
        @test all(isfinite, rounded_R)
        @test !isposdef(Symmetric(rounded_R))
        @test minimum(ψ .- HSquared.FA_UNIQUENESS_FLOOR) > 0

        Gfactor = hcat(Matrix(Diagonal(sqrt.(ψ))), λ)
        for dvalue in (0.0, nextfloat(0.0), 0.7)
            block = HSquared._arc1_fa_v1_block_factor(L, Gfactor, dvalue)
            @test block.status == :ok
            setprecision(BigFloat, 256) do
                Lb, Gb = BigFloat.(L), BigFloat.(Gfactor)
                Vb = Lb * transpose(Lb) + BigFloat(dvalue) * Gb * transpose(Gb)
                F = cholesky(Symmetric(Vb))
                inverse_b = F \ Matrix{BigFloat}(I, 4, 4)
                @test block.logdet ≈ Float64(logdet(F)) atol = 1e-10 rtol = 1e-10
                @test block.inverse ≈ Float64.(inverse_b) atol = 1e-8 rtol = 1e-8
                factor_b = BigFloat.(block.factor)
                @test factor_b * transpose(factor_b) ≈ Vb atol = 1e-15 rtol = 1e-15
            end
        end

        fit = HSquared._arc1_fa_exact_objective_gradient(ctx, params, 1)
        reference = _arc1_bigfloat_reml_reference(params, Y, X, B, 1)
        @test fit.status == :ok
        @test fit.objective ≈ reference.objective atol = 1e-8 rtol = 1e-8
        @test fit.raw_objective ≈ reference.raw_objective atol = 1e-8 rtol = 1e-8
        @test fit.fixed_effects ≈ reference.fixed_effects atol = 1e-6 rtol = 1e-6
        ref256 = _arc1_bigfloat_reml_reference(params, Y, X, B, 1; precision = 256)
        ref384 = _arc1_bigfloat_reml_reference(params, Y, X, B, 1; precision = 384)
        @test ref256.objective ≈ ref384.objective atol = 1e-40 rtol = 1e-40
        @test ref256.raw_objective ≈ ref384.raw_objective atol = 1e-40 rtol = 1e-40
        @test ref256.fixed_effects == ref384.fixed_effects
        grad256_coarse = _arc1_bigfloat_reml_gradient(params, Y, X, B, 1;
            precision = 256, relative_step = "1e-18")
        grad256_fine = _arc1_bigfloat_reml_gradient(params, Y, X, B, 1;
            precision = 256, relative_step = "1e-21")
        big_gradient = _arc1_bigfloat_reml_gradient(params, Y, X, B, 1;
            precision = 384, relative_step = "1e-21")
        @test grad256_coarse ≈ grad256_fine atol = 1e-8 rtol = 1e-8
        @test grad256_fine ≈ big_gradient atol = 1e-8 rtol = 1e-8
        @test fit.gradient ≈ big_gradient atol = 5e-6 rtol = 5e-6
        sweep = HSquared._arc1_fa_central_gradient_sweep(ctx, params, 1)
        @test sweep.status == :ok
        @test maximum(norm(g - big_gradient, Inf) for g in sweep.gradients) <= 5e-6
    end

    @testset "v1 collinear residual full likelihood refuses unresolved low-eigenvalue cases" begin
        n = 5
        Y = [0.1i + 0.03t^2 + sin(i * t / 3) for i in 1:n, t in 1:4]
        X = hcat(ones(n), collect(range(-1.0, 1.0; length = n)))
        L = [1.0 0.0 0.0 0.0;
             1.0 1e-9 0.0 0.0;
             0.2 0.1 0.8 0.0;
             0.15 -0.1 0.2 1.1]
        ψ = fill(0.3, 4)
        λ = [0.7, -0.4, 0.25, 0.55]
        params = _arc1_optimizer_params_from_factor(λ, ψ, L)
        for first_eigenvalue in (0.0, nextfloat(0.0), 1e-12, 2e-12)
            eigenvalues = [first_eigenvalue, 0.75, 1.0, 1.5, 2.0]
            B = Matrix(Diagonal(eigenvalues))
            U = Matrix{Float64}(I, n, n)
            ctx = HSquared._arc1_fa_context_from_eigen(Y, X, eigenvalues, U; B).context
            reference = _arc1_bigfloat_reml_reference(params, Y, X, B, 1; precision = 384)
            @test isfinite(reference.objective)
            @test all(isfinite, reference.fixed_effects)
            fit = HSquared._arc1_fa_exact_objective_gradient(ctx, params, 1)
            @test fit.status == :invalid_proposal
            @test fit.reason !== nothing
            if first_eigenvalue == 0.0 || first_eigenvalue == nextfloat(0.0)
                @test fit.reason == "fixed-effect information is not positive definite"
            end
        end
    end

    @testset "v1 production condition screen brackets the empirical cutoff" begin
        n = 5
        Y = [0.1i + 0.03t^2 + sin(i * t / 3) for i in 1:n, t in 1:4]
        L = [1.0 0.0 0.0 0.0;
             1.0 1e-8 0.0 0.0;
             0.2 0.1 0.8 0.0;
             0.15 -0.1 0.2 1.1]
        ψ = fill(0.3, 4)
        cases = (
            (; loading = 0.5 .* [0.7, -0.4, 0.25, 0.55],
                d = 1e-5, slope_scale = 1.0, expected = 9.135682483651612e-11,
                status = :ok),
            (; loading = 2.0 .* [0.4, 0.4, -0.4, -0.4],
                d = 2e-5, slope_scale = 100.0, expected = 1.0448225299525316e-10,
                status = :invalid_proposal),
        )
        for case in cases
            eigenvalues = [case.d, 0.75, 1.0, 1.5, 2.0]
            B = Matrix(Diagonal(eigenvalues))
            X = hcat(ones(n), case.slope_scale .* collect(range(-1.0, 1.0; length = n)))
            U = Matrix{Float64}(I, n, n)
            ctx = HSquared._arc1_fa_context_from_eigen(Y, X, eigenvalues, U; B).context
            params = _arc1_optimizer_params_from_factor(case.loading, ψ, L)

            # Reconstruct C from the same production block factors used by the
            # likelihood, then verify the expected side of the frozen cutoff.
            Gfactor = hcat(Matrix(Diagonal(sqrt.(ψ))), case.loading)
            C = zeros(4 * size(X, 2), 4 * size(X, 2))
            for i in 1:n
                block = HSquared._arc1_fa_v1_block_factor(L, Gfactor, eigenvalues[i])
                @test block.status == :ok
                D = ctx.design_blocks[i]
                C .+= transpose(D) * block.inverse * D
            end
            screen = HSquared._arc1_v1_fixed_effect_condition_screen(C)
            @test screen.eps_condition ≈ case.expected rtol = 1e-9
            @test screen.status == case.status

            # Exercise the actual exact-REML path, not only the screen helper.
            fit = HSquared._arc1_fa_exact_objective_gradient(ctx, params, 1)
            @test fit.status == case.status
            if case.status == :invalid_proposal
                @test occursin("empirical numerical condition screen", fit.reason)
            else
                reference = _arc1_bigfloat_reml_reference(params, Y, X, B, 1; precision = 384)
                @test fit.objective ≈ reference.objective atol = 1e-8 rtol = 1e-8
                @test fit.raw_objective ≈ reference.raw_objective atol = 1e-8 rtol = 1e-8
                @test fit.fixed_effects ≈ reference.fixed_effects atol = 1e-6 rtol = 1e-6
                gradient = _arc1_bigfloat_reml_gradient(params, Y, X, B, 1;
                    precision = 384, relative_step = "1e-21")
                @test fit.gradient ≈ gradient atol = 5e-6 rtol = 5e-6
            end
        end

        @test HSquared._arc1_v1_fixed_effect_condition_screen(zeros(4, 4)).status == :invalid_proposal
        bad = Matrix{Float64}(I, 4, 4)
        bad[1, 1] = NaN
        @test HSquared._arc1_v1_fixed_effect_condition_screen(bad).status == :invalid_proposal
    end

    @testset "v1 dense REML and gradients agree for multi-column fixed effects" begin
        d = _arc1_optimizer_fixture()
        X = hcat(ones(size(d.Y, 1)), collect(range(-1.0, 1.0; length = size(d.Y, 1))))
        ctx = HSquared._arc1_fa_spectral_context(d.Y, X, d.B).context
        for k in (0, 1)
            params = k == 0 ? vcat(log.(d.ψ .- HSquared.FA_UNIQUENESS_FLOOR),
                HSquared._cov_to_chol_params(d.R, 4)) :
                _arc1_optimizer_params(d.λ, d.ψ, d.R)
            fit = HSquared._arc1_fa_exact_objective_gradient(ctx, params, k)
            reference = _arc1_dense_reml_reference(params, d.Y, X, d.B, k)
            @test fit.status == :ok
            @test fit.objective ≈ reference.objective atol = 1e-9 rtol = 1e-9
            @test fit.raw_objective ≈ reference.raw_objective atol = 1e-8 rtol = 1e-9
            @test fit.fixed_effects ≈ reference.fixed_effects atol = 1e-9 rtol = 1e-9
            dense_gradient = _arc1_dense_reml_gradient(params, d.Y, X, d.B, k)
            @test fit.gradient ≈ dense_gradient atol = 3e-5 rtol = 3e-5
            sweep = HSquared._arc1_fa_central_gradient_sweep(ctx, params, k)
            @test sweep.status == :ok
        end
        near_floor_ψ = fill(HSquared.FA_UNIQUENESS_FLOOR + 1e-4, 4)
        near_floor_params = _arc1_optimizer_params(d.λ, near_floor_ψ, d.R)
        near_floor_fit = HSquared._arc1_fa_exact_objective_gradient(ctx, near_floor_params, 1)
        @test near_floor_fit.status == :ok
        near_floor_sweep = HSquared._arc1_fa_central_gradient_sweep(ctx, near_floor_params, 1)
        @test near_floor_sweep.status == :ok
    end

    @testset "BFGS reports its independently recomputed final gradient" begin
        d = _arc1_optimizer_fixture()
        ctx = HSquared._arc1_fa_spectral_context(d.Y, d.X, d.B).context
        p = _arc1_optimizer_params(d.λ, d.ψ, d.R)
        out = HSquared._arc1_fa_bfgs(ctx, p, 1; iterations = 2)
        @test out.algorithm == :bfgs_hager_zhang
        @test out.iterations <= 2
        @test length(out.phat) == 18
        @test out.final_gradient_inf_norm isa Real
        @test out.objective ≈ out.raw_objective / ctx.df atol = 1e-10 rtol = 0
        @test out.numerical_gradient_status == :ok
        @test length(out.numerical_gradient_inf_norms) == 2
        @test length(out.numerical_gradient_discrepancies) == 2
        @test out.line_search_stats.objective_evaluations > 0
        @test out.line_search_stats.objective_evaluations <= out.line_search_stats.callback_requests
        @test out.accepted == (out.optimizer_converged && out.line_search_success &&
                               out.final_gradient_inf_norm <= 1e-6 &&
                               maximum(out.numerical_gradient_inf_norms) <= 5e-6 &&
                               maximum(out.numerical_gradient_discrepancies) <= 5e-6)
        observed_events = Any[]
        observed = HSquared._arc1_fa_bfgs(ctx, p, 1; iterations = 2,
                                          observation_events = observed_events)
        @test observed.phat == out.phat
        @test observed.status == out.status
        @test observed.accepted == out.accepted
        @test observed.objective == out.objective
        @test observed.raw_objective == out.raw_objective
        @test observed.line_search_stats == out.line_search_stats
        @test any(event -> event.stage == :hager_zhang_terminal &&
                           event.outcome == :accepted, observed_events)

        state_events = Any[]
        state_observed = HSquared._arc1_fa_bfgs(ctx, p, 1; iterations = 2,
            optimizer_state_events = state_events)
        @test state_observed.phat == out.phat
        @test state_observed.status == out.status
        @test state_observed.accepted == out.accepted
        @test state_observed.objective == out.objective
        @test state_observed.line_search_stats == out.line_search_stats
        @test !isempty(state_events)
        @test first(state_events).iteration == 0
        @test first(state_events).update == :initial_state
        @test all(event -> length(event.gradient) == 18 &&
                           size(event.inverse_hessian) == (18, 18), state_events)
        @test all(event -> event.reconstruction == :not_applicable ||
                           event.reconstruction == :matches_optim_bfgs_state, state_events)
        @test any(event -> event.accepted && event.update == :updated, state_events)
        @test !out.line_search_recovery.attempted
    end

    @testset "BFGS identity fallback is bounded and keeps the shared budget" begin
        d = _arc1_optimizer_fixture()
        ctx = HSquared._arc1_fa_spectral_context(d.Y, d.X, d.B).context
        p = _arc1_optimizer_params(d.λ, d.ψ, d.R)
        I18 = Matrix{Float64}(I, length(p), length(p))
        trace_state(x, gradient) = (; metadata = Dict("x" => copy(x),
            "g(x)" => copy(gradient), "~inv(H)" => I18,
            "Current step size" => 1.0))
        terminal = "Hager-Zhang failed: synthetic interval contraction refusal"

        # The original start refuses once; a strict identity-direction search
        # succeeds, and one fresh BFGS continuation receives exactly the
        # original remainder after charging the accepted identity step.
        calls, budgets = Ref(0), Int[]
        runner = function (f, g!, start, budget, stats)
            push!(budgets, budget)
            calls[] += 1
            if calls[] == 1
                stats.terminal_reason = terminal
                return (; minimizer = copy(start), converged = false,
                    line_search_success = false, iterations = 2,
                    status = "synthetic Hager-Zhang refusal",
                    terminal_reason = terminal,
                    trace = [trace_state(start, zeros(length(start)))])
            end
            moved = copy(start)
            moved[1] += 1e-4
            f(moved)
            gradient = zeros(length(moved))
            g!(gradient, moved)
            return (; minimizer = moved, converged = true,
                line_search_success = true, iterations = 1,
                status = "converged after a continuation move",
                terminal_reason = stats.terminal_reason,
                trace = [trace_state(start, zeros(length(start)))])
        end
        state_events, observations = Any[], Any[]
        observed_callback_points = Vector{Float64}[]
        recovered = HSquared._arc1_fa_bfgs(ctx, p, 1; iterations = 20,
            optimizer_runner = runner, optimizer_state_events = state_events,
            observation_events = observations,
            evaluation_callback = (x, _) -> push!(observed_callback_points, copy(x)))
        @test calls[] == 2
        @test budgets == [20, 17]
        @test recovered.iterations == 4
        @test recovered.line_search_recovery.attempted
        @test recovered.line_search_recovery.original_terminal_reason == terminal
        @test recovered.line_search_stats.optimizer_runs[1].terminal_reason == terminal
        @test recovered.line_search_stats.optimizer_runs[3].terminal_reason === nothing
        @test recovered.line_search_terminal_reason === nothing
        @test recovered.line_search_recovery.identity.accepted
        @test recovered.line_search_recovery.identity.iterations == 1
        @test recovered.line_search_recovery.continuation.iterations == 1
        @test recovered.line_search_stats.optimizer_runs[1].stage == :original
        @test recovered.line_search_stats.optimizer_runs[2].stage == :identity_metric_step
        @test recovered.line_search_stats.optimizer_runs[3].stage == :continuation
        @test recovered.line_search_stats.objective_evaluations <=
              recovered.line_search_stats.callback_requests
        @test count(event -> event.update == :identity_metric_restart, state_events) == 1
        @test last(state_events).iteration == 3
        accepted_search = only(filter(event -> event.stage == :line_search_wolfe_check &&
            event.outcome == :accepted, observations))
        origin_gradient = HSquared._arc1_fa_policy_objective_gradient(
            ctx, accepted_search.origin, 1, "arc1_v1").gradient
        @test accepted_search.direction ≈ -origin_gradient
        @test accepted_search.requested_initial_step == 1.0
        recovery_identity = recovered.line_search_recovery.identity
        @test recovered.phat != recovery_identity.endpoint
        @test any(x -> x == recovered.phat, observed_callback_points)
        endpoint_gradient = HSquared._arc1_fa_policy_objective_gradient(
            ctx, recovery_identity.endpoint, 1, "arc1_v1").gradient
        @test recovery_identity.origin_gradient ≈ origin_gradient
        @test recovery_identity.endpoint_gradient ≈ endpoint_gradient
        @test recovery_identity.endpoint - recovery_identity.origin ≈
              recovery_identity.step .* -origin_gradient
        identity_trace = only(filter(event -> event.update == :identity_metric_restart,
            state_events))
        @test identity_trace.x_displacement ==
              recovery_identity.endpoint - recovery_identity.origin
        @test identity_trace.gradient == endpoint_gradient
        @test identity_trace.gradient_change ≈ endpoint_gradient - origin_gradient
        @test recovered.numerical_gradient_status == :ok
        @test recovered.final_status == :ok
        @test recovered.accepted == (recovered.optimizer_converged &&
            recovered.line_search_success && recovered.final_gradient_inf_norm <= 1e-6 &&
            maximum(recovered.numerical_gradient_inf_norms) <= 5e-6 &&
            maximum(recovered.numerical_gradient_discrepancies) <= 5e-6)

        # Turning on state/event observers leaves cached objective counts and
        # the callback stream unchanged.
        calls[] = 0
        empty!(budgets)
        plain_callback_points = Vector{Float64}[]
        plain_recovered = HSquared._arc1_fa_bfgs(ctx, p, 1; iterations = 20,
            optimizer_runner = runner,
            evaluation_callback = (x, _) -> push!(plain_callback_points, copy(x)))
        @test plain_recovered.line_search_stats.callback_requests ==
              recovered.line_search_stats.callback_requests
        @test plain_recovered.line_search_stats.objective_evaluations ==
              recovered.line_search_stats.objective_evaluations
        @test plain_callback_points == observed_callback_points

        # A failed fallback leaves both the optimizer result and evaluation
        # callback at the last accepted origin even after a rejected trial.
        refused_calls = Ref(0)
        refusing_runner = function (f, g!, start, budget, stats)
            refused_calls[] += 1
            (; minimizer = copy(start), converged = false,
               line_search_success = false, iterations = 1,
               status = "synthetic Hager-Zhang refusal",
               terminal_reason = terminal, trace = nothing)
        end
        callback_points = Vector{Float64}[]
        rejected_coordinates = Ref{Vector{Float64}}()
        identity_refusal = function (df, origin, direction, alpha, endpoint,
                                     phi0, dphi0, stats)
            trial = origin .+ 0.25 .* direction
            rejected_coordinates[] = copy(trial)
            HSquared.Optim.NLSolversBase.value_gradient!(df, trial)
            throw(HSquared.Optim.LineSearches.LineSearchException(
                "synthetic identity search refusal", 0.0))
        end
        failed = HSquared._arc1_fa_bfgs(ctx, p, 1; iterations = 20,
            optimizer_runner = refusing_runner,
            identity_search_runner = identity_refusal,
            evaluation_callback = (x, _) -> push!(callback_points, copy(x)))
        @test refused_calls[] == 1
        @test !failed.line_search_recovery.identity.accepted
        @test failed.phat == p
        rejected_index = findlast(==(rejected_coordinates[]), callback_points)
        restored_index = findnext(==(p), callback_points, rejected_index + 1)
        @test rejected_index !== nothing
        @test restored_index !== nothing
        @test failed.line_search_recovery.continuation === nothing
        @test !failed.accepted

        # The identity step consumes the final available iteration; it does
        # not launch a zero-budget or replenished continuation.
        boundary_calls = Ref(0)
        boundary_runner = function (f, g!, start, budget, stats)
            boundary_calls[] += 1
            (; minimizer = copy(start), converged = false,
               line_search_success = false, iterations = 1,
               status = "synthetic Hager-Zhang refusal",
               terminal_reason = terminal, trace = nothing)
        end
        boundary = HSquared._arc1_fa_bfgs(ctx, p, 1; iterations = 2,
            optimizer_runner = boundary_runner)
        @test boundary_calls[] == 1
        @test boundary.iterations == 2
        @test boundary.line_search_recovery.identity.accepted
        @test boundary.line_search_recovery.continuation === nothing
        @test boundary.line_search_success
        @test occursin("no iteration budget remains", boundary.line_search_terminal_reason)
        @test !boundary.accepted

        # A second optimizer refusal is terminal: the single fallback cannot
        # trigger another identity reset. The near-floor final point still
        # passes through covariance and both finite-difference assessments.
        near_floor = copy(p)
        near_floor[5:8] .= log(1e-4)
        second_calls = Ref(0)
        second_terminal = "Hager-Zhang failed: synthetic continuation refusal"
        second_refusal_runner = function (f, g!, start, budget, stats)
            second_calls[] += 1
            if second_calls[] == 1
                return (; minimizer = copy(start), converged = false,
                    line_search_success = false, iterations = 1,
                    status = "synthetic Hager-Zhang refusal",
                    terminal_reason = terminal, trace = nothing)
            end
            (; minimizer = copy(start), converged = false,
               line_search_success = false, iterations = 0,
               status = "synthetic continuation line-search refusal",
               terminal_reason = second_terminal, trace = nothing)
        end
        second_refusal = HSquared._arc1_fa_bfgs(ctx, near_floor, 1;
            iterations = 20, optimizer_runner = second_refusal_runner)
        @test second_calls[] == 2
        @test second_refusal.line_search_recovery.identity.accepted
        @test second_refusal.line_search_recovery.continuation.iterations == 0
        @test second_refusal.line_search_recovery.continuation.terminal_reason == second_terminal
        @test second_refusal.final_status == :ok
        @test second_refusal.numerical_gradient_status == :ok
        @test !second_refusal.line_search_success
        @test second_refusal.line_search_terminal_reason == second_terminal
        @test !second_refusal.accepted
        @test minimum(HSquared._fa_uniqueness_from_unconstrained(
            @view second_refusal.phat[5:8]) .- HSquared.FA_UNIQUENESS_FLOOR) > 0
        # A separate successful zero-iteration continuation still receives
        # normal near-floor assessment at its initial point.
        zero_iteration_calls = Ref(0)
        zero_iteration_runner = function (f, g!, start, budget, stats)
            zero_iteration_calls[] += 1
            if zero_iteration_calls[] == 1
                return (; minimizer = copy(start), converged = false,
                    line_search_success = false, iterations = 1,
                    status = "synthetic Hager-Zhang refusal",
                    terminal_reason = terminal, trace = nothing)
            end
            (; minimizer = copy(start), converged = true,
               line_search_success = true, iterations = 0,
               status = "converged at continuation initial point",
               terminal_reason = nothing, trace = nothing)
        end
        zero_iteration = HSquared._arc1_fa_bfgs(ctx, near_floor, 1;
            iterations = 20, optimizer_runner = zero_iteration_runner)
        @test zero_iteration_calls[] == 2
        @test zero_iteration.line_search_recovery.identity.accepted
        @test zero_iteration.line_search_recovery.continuation.iterations == 0
        @test zero_iteration.final_status == :ok
        @test zero_iteration.numerical_gradient_status == :ok
        @test zero_iteration.line_search_success
        @test minimum(HSquared._fa_uniqueness_from_unconstrained(
            @view zero_iteration.phat[5:8]) .- HSquared.FA_UNIQUENESS_FLOOR) > 0
        @test zero_iteration.accepted == (zero_iteration.optimizer_converged &&
            zero_iteration.line_search_success &&
            zero_iteration.final_gradient_inf_norm <= zero_iteration.final_gradient_tol &&
            maximum(zero_iteration.numerical_gradient_inf_norms) <= 5e-6 &&
            maximum(zero_iteration.numerical_gradient_discrepancies) <= 5e-6)

        # Exercise real Optim -> ARC1 Hager-Zhang exception handling. The
        # synthetic evaluator has a valid start and refuses every nonzero
        # trial, so both searches must restore the actual accepted origin.
        valid_origin = copy(p)
        valid_value = HSquared._arc1_fa_policy_objective_gradient(
            ctx, valid_origin, 1, "arc1_v1")
        isolated_origin_evaluator = function (context, parameters, rank, policy)
            isequal(parameters, valid_origin) ? valid_value :
                HSquared._arc1_fa_invalid("synthetic isolated-origin domain", length(parameters))
        end
        integration_events = Any[]
        integrated_refusal = HSquared._arc1_fa_bfgs(ctx, valid_origin, 1;
            iterations = 20, objective_evaluator = isolated_origin_evaluator,
            observation_events = integration_events)
        @test integrated_refusal.line_search_recovery.attempted
        @test !integrated_refusal.line_search_recovery.identity.accepted
        @test integrated_refusal.line_search_recovery.identity.origin == valid_origin
        @test integrated_refusal.line_search_recovery.identity.endpoint == valid_origin
        @test integrated_refusal.phat == valid_origin
        @test !integrated_refusal.line_search_success
        @test length(integrated_refusal.line_search_stats.optimizer_runs) == 2
        @test integrated_refusal.line_search_stats.callback_requests > 0
        @test count(event -> event.stage == :line_search_terminal &&
            event.outcome == :failed, integration_events) >= 2

        # Optim increments its iteration counter before invoking a line
        # search. With a one-iteration allowance, its real refusal consumes
        # the cap and must not launch the identity fallback.
        capped_refusal = HSquared._arc1_fa_bfgs(ctx, valid_origin, 1;
            iterations = 1, objective_evaluator = isolated_origin_evaluator)
        @test capped_refusal.iterations == 1
        @test !capped_refusal.line_search_success
        @test !capped_refusal.line_search_recovery.attempted
        @test length(capped_refusal.line_search_stats.optimizer_runs) == 1

        # Both Optim runs below are real. The first injected search refuses
        # after a trial, the guarded identity search accepts its strict Wolfe
        # step, and the continuation's injected search refuses after another
        # trial and explicit cache restoration.
        continuation_reason = "controlled Optim continuation refusal"
        search_indices = Int[]
        search_invocations = Dict{Int,Int}()
        trials_by_run = Dict{Int,Vector{Float64}}()
        controlled_factory = function (stats, run_index)
            push!(search_indices, run_index)
            reason = run_index == 1 ? terminal : continuation_reason
            search_invocations[run_index] = 0
            return function (df, origin, direction, alpha, xnew, phi0, dphi0)
                search_invocations[run_index] += 1
                trial = origin .+ (0.25 * alpha) .* direction
                trials_by_run[run_index] = copy(trial)
                HSquared.Optim.NLSolversBase.value_gradient!(df, trial)
                copyto!(xnew, origin)
                HSquared.Optim.NLSolversBase.value_gradient!(df, origin)
                stats.terminal_reason = reason
                throw(HSquared.Optim.LineSearches.LineSearchException(reason, 0.0))
            end
        end
        continuation_callbacks = Vector{Float64}[]
        moved_then_refused = HSquared._arc1_fa_bfgs(ctx, p, 1;
            iterations = 20, line_search_factory = controlled_factory,
            evaluation_callback = (x, _) -> push!(continuation_callbacks, copy(x)))
        accepted_identity = moved_then_refused.line_search_recovery.identity
        @test search_indices == [1, 2]
        @test search_invocations == Dict(1 => 1, 2 => 1)
        @test accepted_identity.accepted
        @test moved_then_refused.line_search_recovery.continuation.iterations == 1
        @test !moved_then_refused.line_search_recovery.continuation.line_search_success
        @test moved_then_refused.line_search_terminal_reason == continuation_reason
        @test moved_then_refused.iterations == 3 # original refusal + identity + continuation refusal
        @test length(moved_then_refused.line_search_stats.optimizer_runs) == 3
        @test moved_then_refused.phat == accepted_identity.endpoint
        continuation_trial = trials_by_run[2]
        trial_index = findlast(==(continuation_trial), continuation_callbacks)
        restored_index = findnext(==(accepted_identity.endpoint), continuation_callbacks,
            trial_index + 1)
        @test trial_index !== nothing
        @test restored_index !== nothing
        @test moved_then_refused.line_search_recovery.original_terminal_reason == terminal
        @test moved_then_refused.line_search_recovery.continuation.terminal_reason ==
              continuation_reason
        @test moved_then_refused.line_search_stats.optimizer_runs[3].iterations == 1

        # Only a line-search exception is eligible for recovery. Other
        # failures from the identity search propagate unchanged.
        non_linesearch_failure = function (df, origin, direction, alpha, endpoint,
                                           phi0, dphi0, stats)
            trial = origin .+ 0.25 .* direction
            HSquared.Optim.NLSolversBase.value_gradient!(df, trial)
            throw(ArgumentError("synthetic non-line-search failure"))
        end
        @test_throws ArgumentError HSquared._arc1_fa_bfgs(ctx, p, 1;
            iterations = 20, optimizer_runner = refusing_runner,
            identity_search_runner = non_linesearch_failure)
    end

    @testset "BFGS trace reconstruction distinguishes updates, skips, and resets" begin
        trace_state(x, gradient, inverse_hessian; step = 1.0) =
            (; metadata = Dict("x" => x, "g(x)" => gradient,
                "~inv(H)" => inverse_hessian, "Current step size" => step))
        I2 = Matrix{Float64}(I, 2, 2)
        x0, g0 = zeros(2), [1.0, 0.0]
        x1, g1 = [-1.0, 0.0], [0.0, 1.0]
        d1 = [-1.0, 0.0]
        H1 = HSquared._arc1_bfgs_inverse_update(I2, d1, g1 - g0)
        updated = HSquared._arc1_bfgs_trace_events([
            trace_state(x0, g0, I2), trace_state(x1, g1, H1)])
        @test length(updated) == 2
        @test updated[2].accepted
        @test updated[2].curvature == 1.0
        @test updated[2].update == :updated
        @test !updated[2].reset_before_search
        @test updated[2].search_direction == d1
        @test updated[2].displacement == d1
        @test updated[2].x_displacement == x1 - x0
        @test updated[2].reconstruction == :matches_optim_bfgs_state

        skipped_x, skipped_g = [-1.0, 0.0], [2.0, 0.0]
        skipped = HSquared._arc1_bfgs_trace_events([
            trace_state(x0, g0, I2), trace_state(skipped_x, skipped_g, I2)])
        @test skipped[2].curvature == -1.0
        @test skipped[2].update == :skipped_nonpositive_curvature
        @test skipped[2].reconstruction == :matches_optim_bfgs_state

        negative_H = -I2
        reset_x, reset_g = [-1.0, 0.0], [0.0, 1.0]
        reset_H = HSquared._arc1_bfgs_inverse_update(I2, d1, reset_g - g0)
        reset = HSquared._arc1_bfgs_trace_events([
            trace_state(x0, g0, negative_H), trace_state(reset_x, reset_g, reset_H)])
        @test reset[2].reset_before_search
        @test reset[2].update == :updated
        @test reset[2].reconstruction == :matches_optim_bfgs_state

        large_x0, large_g0 = [1e16, 0.0], [-2.0, -2.0]
        large_x1, large_g1 = [1e16, 1.0], [-1.0, -1.0]
        large_H = HSquared._arc1_bfgs_inverse_update(I2, [1.0, 1.0], [1.0, 1.0])
        rounded = HSquared._arc1_bfgs_trace_events([
            trace_state(large_x0, large_g0, I2), trace_state(large_x1, large_g1, large_H; step = 0.5)])
        @test rounded[2].displacement == [1.0, 1.0]
        @test rounded[2].x_displacement == [0.0, 1.0]
        @test rounded[2].curvature == 2.0
        @test rounded[2].reconstruction == :matches_optim_bfgs_state

        corrupted = copy(H1)
        corrupted[1, 1] += 1e-4
        mismatch = HSquared._arc1_bfgs_trace_events([
            trace_state(x0, g0, I2), trace_state(x1, g1, corrupted)])
        @test mismatch[2].reconstruction == :mismatch
        @test_throws ArgumentError HSquared._arc1_bfgs_trace_events([
            (; metadata = Dict("x" => x0))])
    end

    @testset "invalid proposal sentinels and nonconverged points cannot pass" begin
        d = _arc1_optimizer_fixture()
        ctx = HSquared._arc1_fa_spectral_context(d.Y, d.X, d.B).context
        p = _arc1_optimizer_params(d.λ, d.ψ, d.R)
        pinvalid = copy(p)
        pinvalid[end - 9] = -1000.0
        out = HSquared._arc1_fa_bfgs(ctx, pinvalid, 1; iterations = 2)
        @test !out.accepted
        @test out.status == :failed
        @test out.final_status == :invalid_proposal
        invalid_events = Any[]
        observed_invalid = HSquared._arc1_fa_bfgs(ctx, pinvalid, 1; iterations = 2,
            observation_events = invalid_events)
        @test observed_invalid.status == out.status
        @test observed_invalid.final_status == out.final_status
        @test observed_invalid.raw_objective == out.raw_objective
        @test hasproperty(observed_invalid, :line_search_stats) ==
              hasproperty(out, :line_search_stats) == false
        invalid_event = only(filter(event -> event.stage == :evaluator_rejection,
                                    invalid_events))
        @test invalid_event.reason == out.reason
        @test invalid_event.coordinates == pinvalid
        @test invalid_event.coordinates !== pinvalid
        @test invalid_event.counters == (callback_requests = 0,
            objective_evaluations = 0, rejected_trials = 0, domain_restarts = 0)

        # A finite optimizer result with an inaccurate final score must fail
        # the policy criterion, regardless of the optimizer's status flag.
        forced = HSquared._arc1_fa_assess_optimizer_result(
            (; phat = p, optimizer_converged = true, iterations = 1,
               line_search_success = true,
               optimizer_status = "forced_converged"), ctx, 1)
        @test !forced.accepted
        @test forced.optimizer_converged
        @test forced.optimizer_assessment_status == :numerical_gradient_failure
        @test occursin("gradient", forced.optimizer_assessment_reason)
        @test forced.final_gradient_inf_norm > 1e-6

        terminal_reason = "Hager-Zhang failed: synthetic interval contraction failure"
        terminal = HSquared._arc1_fa_assess_optimizer_result(
            (; phat = p, optimizer_converged = false, iterations = 1,
               line_search_success = false, line_search_terminal_reason = terminal_reason,
               optimizer_status = "forced_line_search_failure"), ctx, 1)
        @test terminal.status == :line_search_failed
        @test terminal.line_search_terminal_reason == terminal_reason
        @test terminal.optimizer_assessment_reason == terminal_reason
    end

    @testset "central-difference failures retain actual perturbation diagnostics" begin
        d = _arc1_optimizer_fixture()
        ctx = HSquared._arc1_fa_spectral_context(d.Y, d.X, d.B).context
        p = _arc1_optimizer_params(d.λ, d.ψ, d.R)
        p[1] = 2.5
        evaluation_order = Vector{Float64}[]
        evaluator = function (_, parameters, k, policy)
            push!(evaluation_order, copy(parameters))
            length(parameters) == length(p) || error("unexpected parameter vector")
            if parameters[1] > p[1]
                return (; status = :invalid_proposal,
                    reason = "synthetic plus-side covariance failure")
            end
            return (; status = :ok, reason = nothing, objective = 2.0,
                gradient = zeros(length(parameters)))
        end
        observed_parameters = Vector{Float64}[]
        fd = HSquared._arc1_fa_central_gradient_sweep(ctx, p, 1;
            objective_evaluator = evaluator,
            evaluation_callback = (parameters, _) -> push!(observed_parameters, copy(parameters)))
        @test fd.status == :failed
        @test occursin("parameter 1", fd.reason)
        @test length(fd.failed_sides) == 1
        failure = only(fd.failed_sides)
        @test failure.side == :plus
        @test failure.parameter == 1
        @test failure.relative_scale == 1e-4
        @test failure.absolute_step == 2.5e-4
        @test failure.objective_status == :invalid_proposal
        @test failure.objective_reason == "synthetic plus-side covariance failure"
        @test length(evaluation_order) == 3
        @test evaluation_order[1] == p
        @test evaluation_order[2][1] == p[1] + failure.absolute_step
        @test evaluation_order[3][1] == p[1] - failure.absolute_step
        @test observed_parameters == evaluation_order
    end

    @testset "production optimizer projection retains failure diagnostics" begin
        failed_sides = [(; side = :minus, parameter = 14, relative_scale = 1e-4,
            absolute_step = 2e-4, objective_status = :invalid_proposal,
            objective_reason = "synthetic residual covariance failure")]
        terminal_reason = "Hager-Zhang failed: synthetic terminal reason"
        fit = (; phat = [1.0, 2.0], raw_objective = 12.0,
            optimizer_converged = false, optimizer_assessment_status = :line_search_failure,
            optimizer_assessment_reason = terminal_reason, iterations = 7,
            optimizer_status = "synthetic failure", objective = 6.0,
            final_gradient_inf_norm = 0.3, numerical_gradient_inf_norms = (0.1, 0.2),
            numerical_gradient_discrepancies = (0.01, 0.02),
            numerical_gradient_status = :failed,
            numerical_gradient_failed_sides = failed_sides,
            line_search_success = false, line_search_terminal_reason = terminal_reason,
            line_search_stats = (; callback_requests = 4),
            algorithm = :bfgs_hager_zhang)
        out = HSquared._fa_rank_optimizer_output(fit)
        @test out.phat == fit.phat
        @test out.objective == fit.raw_objective
        @test out.optimizer_assessment === fit
        @test out.line_search_terminal_reason == terminal_reason
        @test out.numerical_gradient_failed_sides === failed_sides
    end

    @testset "guarded Hager-Zhang restarts only on invalid trials" begin
        # Invalid requests retain their own coordinates and unknown callback
        # results before the request guard decides whether to reject them.
        invalid_request_events = Any[]
        invalid_request_stats = HSquared._Arc1LineSearchStats(
            ; observation_events = invalid_request_events)
        invalid_trial = HSquared._arc1_requested_trial!(invalid_request_stats,
            [0.0], [1.0], NaN)
        @test isnan(invalid_trial[1])
        invalid_request = invalid_request_stats.diagnostic_context
        @test all(isnan, invalid_request.coordinates) && all(isnan, invalid_trial)
        @test invalid_request.direction == [1.0]
        @test isnan(invalid_request.step)
        @test invalid_request.value === nothing && invalid_request.slope === nothing
        HSquared._arc1_observation!(invalid_request_stats, :line_search_rejection,
            "line-search trial step is nonfinite or nonpositive"; step = NaN,
            outcome = :rejected)
        invalid_event = only(invalid_request_events)
        @test isnan(invalid_event.coordinates[1]) && isnan(invalid_event.step)
        @test invalid_event.value === nothing && invalid_event.slope === nothing
        unobserved_stats = HSquared._Arc1LineSearchStats()
        @test HSquared._arc1_requested_trial!(unobserved_stats, [0.0], [1.0], NaN) === nothing
        @test unobserved_stats.diagnostic_context === nothing

        # The endpoints are valid, while secant/bisection trials through the
        # open interval are outside the objective domain.
        bad_interval(x) = 0.74 < x < 0.76
        f(x) = bad_interval(x) ? Inf : (x - 0.75)^2
        df(x) = bad_interval(x) ? -0.5 : 2(x - 0.75)
        recovered = _arc1_direct_linesearch(f, df)
        @test recovered.error === nothing
        @test recovered.stats.domain_restarts > 0
        @test recovered.stats.rejected_trials > 0
        @test recovered.stats.callback_requests <= 256
        @test recovered.stats.objective_evaluations <= recovered.stats.callback_requests
        step, value = recovered.value
        @test isfinite(step) && isfinite(value)
        @test recovered.xnew[1] ≈ step atol = 1e-12
        @test 0.1 * recovered.dphi0 >= (value - recovered.phi0) / step
        @test 2(step - 0.75) >= 0.9 * recovered.dphi0

        # A finite value with a nonfinite directional derivative must follow
        # the same guarded restart path.
        slope(x) = 0.45 < x < 0.55 ? NaN : 2(x - 1)
        nonfinite_slope = _arc1_direct_linesearch(x -> (x - 1)^2, slope; alpha = 0.5)
        @test nonfinite_slope.error === nothing
        @test nonfinite_slope.stats.domain_restarts > 0
        @test nonfinite_slope.stats.rejected_trials > 0

        # An invalid open ray exhausts the restart allowance. Optim receives
        # alpha=0 and both its trial vector and differentiated cache return to
        # the original feasible point.
        always_bad(x) = x > 0 ? Inf : -x
        always_bad_grad(x) = -1.0
        exhausted = _arc1_direct_linesearch(always_bad, always_bad_grad;
            max_domain_restarts = 1, max_callback_requests = 256)
        @test exhausted.error isa HSquared.Optim.LineSearches.LineSearchException
        @test exhausted.error.alpha == 0.0
        @test exhausted.stats.domain_restarts == 1
        @test exhausted.xnew == [0.0]
        value0, gradient0 = HSquared.Optim.NLSolversBase.value_gradient!(exhausted.df, exhausted.x)
        @test value0 == 0.0
        @test gradient0 == [-1.0]

        # A finite Hager-Zhang return that satisfies neither Wolfe condition
        # must preserve the rejected trial witness and restore the origin.
        finite_return_events = Any[]
        finite_return = _arc1_direct_linesearch(x -> x > 0.75 ? Inf : -x, x -> -1.0;
            observation_events = finite_return_events)
        @test finite_return.error isa HSquared.Optim.LineSearches.LineSearchException
        @test occursin("finite step that satisfies neither Wolfe condition",
                       sprint(showerror, finite_return.error))
        @test finite_return.xnew == [0.0]
        # Inspect the raw OnceDifferentiable caches before a test-side refresh
        # can hide a failed restoration. Both callbacks should have run at the
        # origin after the rejected trial.
        @test finite_return.df.x_f == [0.0]
        @test finite_return.df.x_df == [0.0]
        @test finite_return.df.F == 0.0
        @test finite_return.df.DF == [-1.0]
        wolfe_checks = filter(event -> event.stage == :line_search_wolfe_check,
                              finite_return_events)
        @test length(wolfe_checks) == 1
        if length(wolfe_checks) == 1
            check = only(wolfe_checks)
            @test check.outcome == :rejected
            @test check.origin == [0.0]
            @test check.direction == [1.0]
            @test check.requested_initial_step == 1.0
            @test check.initial_step == 0.5
            @test check.step_cap == 0.5
            @test check.domain_restart == 1
            @test check.returned_step > 0
            @test check.returned_step == 0.5
            @test check.origin_value == 0.0
            @test check.origin_slope == -1.0
            @test check.trial_value == -0.5
            @test check.trial_slope == -1.0
            @test !check.wolfe && !check.approximate_wolfe
        end

        # Callback exhaustion is a distinct bounded refusal and must also
        # restore the state before Optim sees the failure.
        budgeted = _arc1_direct_linesearch(always_bad, always_bad_grad;
            max_domain_restarts = 32, max_callback_requests = 1)
        @test budgeted.error isa HSquared.Optim.LineSearches.LineSearchException
        @test budgeted.error.alpha == 0.0
        @test budgeted.stats.callback_requests == 1
        @test budgeted.xnew == [0.0]

        # A rejected requested step is reported at that trial, even when the
        # callback budget refuses it before objective evaluation. The
        # terminal event then reports the restored origin.
        budget_events = Any[]
        budget_refused = _arc1_direct_linesearch(x -> (x - 1)^2, x -> 2(x - 1);
            x0 = 0.0, alpha = 0.5, max_callback_requests = 0,
            observation_events = budget_events)
        rejection = only(filter(event -> event.stage == :line_search_rejection,
                                budget_events))
        terminal = only(filter(event -> event.stage == :line_search_terminal,
                               budget_events))
        @test rejection.coordinates == [0.5]
        @test rejection.direction == [1.0]
        @test rejection.step == 0.5
        @test rejection.value === nothing && rejection.slope === nothing
        @test terminal.coordinates == [0.0]
        @test terminal.direction == [1.0]
        @test terminal.step === nothing
        @test terminal.value == budget_refused.phi0
        @test terminal.slope == budget_refused.dphi0
        @test budget_refused.xnew == [0.0]

        # A regular quadratic still returns an independently verified Wolfe
        # step and does not need a domain restart.
        valid = _arc1_direct_linesearch(x -> (x - 1)^2, x -> 2(x - 1))
        @test valid.error === nothing
        @test valid.value[1] ≈ 1.0 atol = 1e-12
        @test valid.stats.domain_restarts == 0
        @test valid.stats.rejected_trials == 0

        # Observation is opt-in and does not alter callbacks, counters, the
        # returned Wolfe point, or the exact evaluator reason retained by the
        # synthetic adapter.
        observe_rejection = function (stats, x, value)
            isfinite(value) || HSquared._arc1_observation!(stats,
                :evaluator_rejection, "synthetic residual covariance lost PD";
                coordinates = [x], value, outcome = :invalid_residual_covariance)
            nothing
        end
        plain = _arc1_direct_linesearch(f, df)
        events = Any[]
        watched = _arc1_direct_linesearch(f, df; observation_events = events,
                                          evaluate_observer = observe_rejection)
        @test watched.error === nothing
        @test watched.value == plain.value
        @test watched.xnew == plain.xnew
        @test (watched.stats.callback_requests, watched.stats.objective_evaluations,
               watched.stats.rejected_trials, watched.stats.domain_restarts) ==
              (plain.stats.callback_requests, plain.stats.objective_evaluations,
               plain.stats.rejected_trials, plain.stats.domain_restarts)
        evaluator_events = filter(event -> event.stage == :evaluator_rejection, events)
        @test !isempty(evaluator_events)
        @test all(event.reason == "synthetic residual covariance lost PD" for event in evaluator_events)
        @test all(event.coordinates !== nothing && event.direction !== nothing &&
                  event.step !== nothing && event.value !== nothing && hasproperty(event, :slope) &&
                  event.counters.callback_requests > 0 for event in evaluator_events)
        @test events[1].coordinates !== events[2].coordinates
        preserved = copy(events[2].coordinates)
        events[1].coordinates[1] = -999.0
        @test events[2].coordinates == preserved
        @test events[1].direction !== events[2].direction

        shared_events = Any[]
        shared_stats = HSquared._Arc1LineSearchStats(; observation_events = shared_events)
        first_search = _arc1_direct_linesearch(x -> (x - 1)^2, x -> 2(x - 1);
            observation_events = shared_events, line_search_stats = shared_stats)
        first_request_count = shared_stats.callback_requests
        second_search = _arc1_direct_linesearch(x -> (x - 1)^2, x -> 2(x - 1);
            observation_events = shared_events, line_search_stats = shared_stats)
        terminal_events = filter(event -> event.stage == :hager_zhang_terminal, shared_events)
        @test first_search.error === nothing && second_search.error === nothing
        @test [event.search_index for event in terminal_events] == [1, 2]
        @test terminal_events[1].counters.callback_requests == first_request_count
        @test terminal_events[2].counters.callback_requests ==
              shared_stats.callback_requests - first_request_count

        # Terminal Hager-Zhang failure logs preserve the refusal reason and
        # the same restored iterate/cache as the observer-free path.
        plain_failure = _arc1_direct_linesearch(always_bad, always_bad_grad;
            max_domain_restarts = 1, max_callback_requests = 256)
        failure_events = Any[]
        logged_failure = _arc1_direct_linesearch(always_bad, always_bad_grad;
            max_domain_restarts = 1, max_callback_requests = 256,
            observation_events = failure_events)
        @test sprint(showerror, plain_failure.error) == sprint(showerror, logged_failure.error)
        @test logged_failure.xnew == plain_failure.xnew == [0.0]
        @test (logged_failure.stats.callback_requests, logged_failure.stats.objective_evaluations,
               logged_failure.stats.rejected_trials, logged_failure.stats.domain_restarts) ==
              (plain_failure.stats.callback_requests, plain_failure.stats.objective_evaluations,
               plain_failure.stats.rejected_trials, plain_failure.stats.domain_restarts)
        terminal_refusal = only(filter(event -> event.stage == :line_search_terminal &&
            event.outcome == :failed, failure_events))
        @test occursin("restart budget exhausted", terminal_refusal.reason)
        @test plain_failure.stats.terminal_reason == terminal_refusal.reason
        @test logged_failure.stats.terminal_reason == terminal_refusal.reason

        # An unexpected exception at ARC1's final value/gradient check must
        # propagate only after restoring xnew and the differentiated cache.
        callback_calls = Ref(0)
        final_error = _arc1_direct_linesearch(x -> (x - 1)^2, x -> 2(x - 1);
            make_pair = function (df, xnew, x0, direction)
                phi = alpha -> (alpha - 1)^2
                phidphi = alpha -> begin
                    if isapprox(alpha, 1.0; atol = 1e-12, rtol = 0)
                        callback_calls[] += 1
                        callback_calls[] == 2 && error("unexpected final callback failure")
                    end
                    ((alpha - 1)^2, 2(alpha - 1))
                end
                phi, phidphi
            end)
        @test final_error.error isa ErrorException
        @test occursin("unexpected final callback failure", sprint(showerror, final_error.error))
        @test callback_calls[] == 2
        @test final_error.xnew == [0.0]
        value0, gradient0 = HSquared.Optim.NLSolversBase.value_gradient!(final_error.df, final_error.x)
        @test value0 == 1.0
        @test gradient0 == [-2.0]
        @test final_error.stats.rejected_trials == 0
    end

    @testset "frozen derived starts and opt-in API boundaries" begin
        d = _arc1_optimizer_fixture()
        ctx = HSquared._fa_rank_context(d.Y, d.X, d.Z, d.ped, nothing)
        tiny_phen = [1e-5, 0.24, 0.37, 0.51]
        tiny_Y = copy(ctx.Y)
        centered = collect(range(-1.0, 1.0; length = size(tiny_Y, 1)))
        centered .*= sqrt(1e-8 / sum(abs2, centered) * (length(centered) - 1))
        tiny_Y[:, 1] .= centered .+ 2.0
        tiny_Y[:, 2] .= 3.0
        tiny_Y[:, 3] .= [isodd(i) ? -1e200 : 1e200 for i in axes(tiny_Y, 1)]
        ctx = merge(ctx, (; Y = tiny_Y, phen = tiny_phen))
        default_params = first(HSquared._fa_rank_starts(ctx))
        k0_starts = HSquared._arc1_k0_start_schedule(ctx, default_params)
        @test length(k0_starts) == 6
        @test getproperty.(k0_starts, :split) == [0.05, 0.15, 0.3, 0.5, 0.7, 0.9]
        @test k0_starts[4].start_id == :default
        @test k0_starts[4].params == default_params
        @test k0_starts[4].params[5:end] == HSquared._fa_rank_starts(ctx)[1][5:end]
        floor = HSquared.FA_UNIQUENESS_FLOOR
        sample_variance = [begin
            raw = sum(abs2, ctx.Y[:, j] .- sum(ctx.Y[:, j]) / size(ctx.Y, 1)) /
                  (size(ctx.Y, 1) - 1)
            isfinite(raw) && raw > 0 ? raw : 1.0
        end for j in 1:size(ctx.Y, 2)]
        variance = max.(sample_variance, 2floor)
        expected_g = max.(0.3 .* variance, 2floor)
        expected_R = Matrix(Diagonal((1 - 0.3) .* variance))
        expected_03 = vcat(HSquared._fa_uniqueness_to_unconstrained(expected_g),
                           HSquared._cov_to_chol_params(expected_R, 4))
        @test k0_starts[3].params == expected_03
        @test k0_starts[3].params != vcat(
            HSquared._fa_uniqueness_to_unconstrained(max.(0.3 .* max.(tiny_phen, 2floor), 2floor)),
            HSquared._cov_to_chol_params(Matrix(Diagonal(0.7 .* max.(tiny_phen, 2floor))), 4))
        floored_half_R = HSquared._cov_to_chol_params(
            Matrix(Diagonal(0.5 .* variance)), 4)
        @test k0_starts[4].params[5:end] != floored_half_R

        diagonal = (; genetic_covariance = Matrix(Diagonal([0.8, 1.1, 0.9, 1.3])),
                    residual_covariance = d.R)
        starts = HSquared._arc1_derived_starts(diagonal)
        @test length(starts) == 16
        @test length(unique([s.name for s in starts])) == 16
        for a in starts
            @test a.loading[1] > 0
            @test all(a.uniqueness .> HSquared.FA_UNIQUENESS_FLOOR)
            @test diag(a.loading * transpose(a.loading) + Diagonal(a.uniqueness)) ≈
                  diag(diagonal.genetic_covariance) atol = 1e-12 rtol = 0
            @test a.params[9:18] == HSquared._cov_to_chol_params(d.R, 4)
        end
        @test length(unique(Tuple(sign.(s.loading)) for s in starts[1:8])) == 8
        @test all(all(isapprox.(starts[i].loading ./ starts[i + 8].loading,
                               fill(0.1 / 0.7, 4); atol = 1e-12, rtol = 0))
                  for i in 1:8)

        @test HSquared._ARC1_SOURCE_IDENTITY isa String
        @test length(HSquared._ARC1_SOURCE_IDENTITY) == 64
        bad_iterations = HSquared.select_fa_rank(d.Y, d.X, d.Z, d.ped;
            optimizer_policy = "arc1_v1", iterations = 1_999)
        @test bad_iterations.selection_status == :unsupported_input
        @test occursin("2,000", bad_iterations.reason)
        @test bad_iterations.optimizer_policy == "arc1_v1"
        @test bad_iterations.optimizer_policy_version == 1
        @test bad_iterations.source_identity == HSquared._ARC1_SOURCE_IDENTITY
        @test bad_iterations.optimizer_algorithm == :bfgs_hager_zhang
        bad_policy = HSquared.select_fa_rank(d.Y, d.X, d.Z, d.ped;
            optimizer_policy = "custom")
        @test bad_policy.selection_status == :unsupported_input
        @test occursin("unknown optimizer_policy", bad_policy.reason)
        matrix_policy = try
            HSquared.fit_multivariate_reml(d.Y, d.X, d.Z, d.Ainv;
                genetic_structure = :factor_analytic, rank = 1,
                optimizer_policy = "arc1_v1")
            nothing
        catch err
            err
        end
        @test matrix_policy isa ArgumentError
        @test occursin("validated Pedigree", sprint(showerror, matrix_policy))
        initial_policy = try
            HSquared.fit_multivariate_reml(d.Y, d.X, d.Z, d.ped;
                genetic_structure = :factor_analytic, rank = 1,
                optimizer_policy = "arc1_v1", initial = (; G0 = d.G, R0 = d.R))
            nothing
        catch err
            err
        end
        @test initial_policy isa ArgumentError
        @test occursin("truth starts", sprint(showerror, initial_policy))
    end

    @testset "complete frozen attempt ledger survives interruption" begin
        d = _arc1_optimizer_fixture()
        ledger = Ref{Any}(nothing)
        interrupted_runner = (ctx, p, k, name) -> throw(InterruptException())
        @test_throws InterruptException HSquared._arc1_select_fa_rank(
            d.Y, d.X, d.Z, d.ped; ledger_sink = ledger,
            optimizer_policy = "arc1_v1",
            attempt_runner = interrupted_runner)
        @test ledger[] !== nothing
        @test length(ledger[].attempts) == 24
        @test ledger[].optimizer_policy == "arc1_v1"
        @test ledger[].optimizer_policy_version == 1
        @test ledger[].source_identity == HSquared._ARC1_SOURCE_IDENTITY
        @test ledger[].optimizer_algorithm == :bfgs_hager_zhang
        @test ledger[].optimizer_iterations == 2_000
        @test ledger[].starts_planned == 24
        @test ledger[].starts_attempted == 1
        @test count(a -> a.attempted, ledger[].attempts) == 1
        @test count(a -> a.status == :unattempted, ledger[].attempts) == 23
        k1_planned = filter(a -> a.rank == 1, ledger[].attempts)
        @test getproperty.(k1_planned, :schedule_index) == collect(1:18)
        @test all(a -> a.k0_anchor_start_id === nothing, k1_planned)
        @test first(filter(a -> a.rank == 0, ledger[].attempts)).status == :interrupted
        @test occursin("optimizer start", ledger[].reason)
    end

    @testset "a better finite failed K1 receipt blocks selection" begin
        d = _arc1_optimizer_fixture()
        diagonal_G, diagonal_R = Ref{Any}(nothing), Ref{Any}(nothing)
        diagonal_objective = Ref(Inf)
        fixture_ctx = HSquared._fa_rank_context(d.Y, d.X, d.Z, d.ped, nothing)
        default_k0_params = first(HSquared._fa_rank_starts(fixture_ctx))
        call_order = Tuple{Int,Symbol}[]
        find_better = function (objective, start)
            candidates = Vector{Vector{Float64}}()
            for loading_scale in (0.0, 0.25, 0.5, 1.0, 1.5),
                uniqueness_shift in (-2.0, -1.0, 0.0, 1.0, 2.0),
                residual_shift in (-1.0, 0.0, 1.0, 2.0)
                p = copy(start)
                p[1:4] .*= loading_scale
                p[5:8] .+= uniqueness_shift
                p[9:end] .+= residual_shift
                push!(candidates, p)
            end
            values = [objective(p) for p in candidates]
            i = argmin(values)
            candidates[i], values[i]
        end
        runner = function (ctx, params0, rank, start_id)
            push!(call_order, (rank, start_id))
            raw_objective(p, k) = HSquared._arc1_fa_exact_objective_gradient(ctx, p, k).raw_objective
            if rank == 0
                p = copy(default_k0_params)
                p[1:4] .-= 2.0
                p[5:end] .+= 1.5
                value = raw_objective(p, 0)
                diagonal_objective[] = value
                diagonal_G[] = HSquared._fa_rank_cov(p[1:4], 0)[1]
                diagonal_R[] = HSquared._chol_params_to_cov(p[5:end], 4)
                return (; phat = p, objective = value, converged = true,
                    iterations = 1, optimizer_status = "injected weak K0")
            elseif start_id == :default
                p, value = find_better(x -> raw_objective(x, 1), params0)
                value < diagonal_objective[] - 1e-3 || error("fixture lacks better finite K1 receipt")
                return (; phat = p, objective = value, converged = true,
                    optimizer_converged = true, line_search_success = false,
                    line_search_terminal_reason = "Hager-Zhang failed: injected reason",
                    numerical_gradient_failed_sides = [(; side = :minus, parameter = 14,
                        relative_scale = 1e-4, absolute_step = 2e-4,
                        objective_status = :invalid_proposal,
                        objective_reason = "injected perturbed objective reason")],
                    optimizer_assessment_status = :line_search_failure,
                    optimizer_assessment_reason = "injected line search failure",
                    iterations = 1, optimizer_status = "better failed K1")
            end
            g = diag(diagonal_G[])
            loading = [0.1 * (-1.0)^(i - 1) * sqrt(g[i] - HSquared.FA_UNIQUENESS_FLOOR) for i in 1:4]
            psi = g .- loading.^2
            p = vcat(loading, log.(psi .- HSquared.FA_UNIQUENESS_FLOOR),
                HSquared._cov_to_chol_params(diagonal_R[], 4))
            return (; phat = p, objective = raw_objective(p, 1), converged = true,
                iterations = 1, optimizer_status = "eligible nested K1")
        end
        ledger = Ref{Any}(nothing)
        result = HSquared._arc1_select_fa_rank(d.Y, d.X, d.Z, d.ped;
            ledger_sink = ledger, optimizer_policy = "arc1_v1", attempt_runner = runner)
        expected_k0 = Symbol.("split_0.05 split_0.15 split_0.3 default split_0.7 split_0.9" |> split)
        @test call_order[1:6] == [(0, name) for name in expected_k0]
        @test count(a -> a.rank == 0 && a.attempted, result.attempts) == 6
        @test count(a -> a.rank == 1 && a.attempted, result.attempts) == 18
        @test length(result.attempts) == 24
        eligible_k0 = filter(a -> a.rank == 0 && a.eligible, result.attempts)
        best_k0 = eligible_k0[argmax(getproperty.(eligible_k0, :loglik))]
        expected_derived = HSquared._arc1_derived_starts(best_k0)
        for expected in expected_derived
            observed = only(filter(a -> a.rank == 1 && a.start_id == expected.name, result.attempts))
            @test observed.initial_parameters == expected.params
        end
        @test result.selection_status == :unavailable
        @test occursin("better finite unaccepted K1", result.reason)
        @test result.source_identity == HSquared._ARC1_SOURCE_IDENTITY
        @test ledger[].source_identity == HSquared._ARC1_SOURCE_IDENTITY
        failed = only(filter(a -> a.rank == 1 && a.start_id == :default, result.attempts))
        @test failed.status == :failed
        @test failed.optimizer_converged
        @test failed.optimizer_assessment_status == :line_search_failure
        @test failed.optimizer_assessment_reason == "injected line search failure"
        @test failed.line_search_terminal_reason == "Hager-Zhang failed: injected reason"
        @test failed.numerical_gradient_failed_sides == [(; side = :minus, parameter = 14,
            relative_scale = 1e-4, absolute_step = 2e-4,
            objective_status = :invalid_proposal,
            objective_reason = "injected perturbed objective reason")]
        @test failed.loglik > result.candidate_summary[2].loglik
    end

    @testset "K0 schedule accounting fails closed and retains initialization metadata" begin
        d = _arc1_optimizer_fixture()
        original_builder = HSquared._arc1_k0_start_schedule
        invalid_first = function (ctx, params)
            starts = original_builder(ctx, params)
            firstrow = merge(first(starts), (; params = Float64[],
                initialization_status = :invalid,
                failure_reason = "injected initialization failure"))
            [firstrow; starts[2:end]]
        end
        runner = function (ctx, params0, rank, start_id)
            fit = HSquared._arc1_fa_exact_objective_gradient(ctx, params0, rank)
            fit.status == :ok || error("fixture objective failed")
            (; phat = copy(params0), objective = fit.raw_objective,
               converged = true, iterations = 1, optimizer_status = "injected accepted start")
        end
        result = HSquared._arc1_select_fa_rank(d.Y, d.X, d.Z, d.ped;
            optimizer_policy = "arc1_v1", attempt_runner = runner,
            k0_start_builder = invalid_first)
        @test result.guard_results.schedule_complete === false
        @test result.selection_status == :unavailable
        @test occursin("six-start K0 and 18-start K1", result.reason)
        @test count(a -> a.rank == 0 && a.attempted, result.attempts) == 5
        @test count(a -> a.rank == 1 && a.attempted, result.attempts) == 18
        failed_init = only(filter(a -> a.rank == 0 && a.start_id == Symbol("split_0.05"),
                                  result.attempts))
        @test failed_init.status == :failed
        @test failed_init.attempted === false
        @test failed_init.split == 0.05
        @test failed_init.schedule_index == 1
        @test failed_init.initialization_status == :invalid

        all_fail = function (ctx, params, rank, start_id)
            rank == 0 && error("injected K0 optimizer failure")
            error("K1 must stay unattempted without eligible K0")
        end
        failed = HSquared._arc1_select_fa_rank(d.Y, d.X, d.Z, d.ped;
            optimizer_policy = "arc1_v1", attempt_runner = all_fail)
        @test failed.selection_status == :unavailable
        @test failed.guard_results.schedule_complete === false
        @test count(a -> a.rank == 0 && a.attempted, failed.attempts) == 6
        @test count(a -> a.rank == 1 && a.attempted, failed.attempts) == 0
        @test count(a -> a.rank == 1 && a.status == :unattempted, failed.attempts) == 18
    end

    @testset "a better finite unaccepted K0 receipt blocks selection" begin
        d = _arc1_optimizer_fixed_fixture()
        runner = function (ctx, params0, rank, start_id)
            exact(p, k) = HSquared._arc1_fa_exact_objective_gradient(ctx, p, k)
            if rank == 0 && start_id == Symbol("split_0.05")
                fit = HSquared._arc1_fa_bfgs(ctx, params0, 0; optimizer_policy = "arc1_v1")
                value = exact(fit.phat, 0).raw_objective
                return (; phat = fit.phat, objective = value, converged = fit.optimizer_converged,
                    line_search_success = false, optimizer_assessment_status = :line_search_failure,
                    iterations = 1, optimizer_status = "better failed K0")
            end
            result = exact(params0, rank)
            result.status == :ok || error("injected objective failed")
            return (; phat = copy(params0), objective = result.raw_objective,
                converged = true, iterations = 1, optimizer_status = "accepted start")
        end
        result = HSquared._arc1_select_fa_rank(d.Y, d.X, d.Z, d.ped;
            optimizer_policy = "arc1_v1", attempt_runner = runner)
        @test count(a -> a.rank == 0 && a.attempted, result.attempts) == 6
        @test count(a -> a.rank == 1 && a.attempted, result.attempts) == 18
        @test result.guard_results.better_unaccepted_k0 === true
        @test result.guard_results.better_unaccepted === true
        @test result.selection_status == :unavailable
        @test occursin("better finite unaccepted K0", result.reason)
        unaccepted = only(filter(a -> a.rank == 0 && a.start_id == Symbol("split_0.05"),
                                 result.attempts))
        @test unaccepted.status == :failed
        @test unaccepted.finite_objective === true
        @test unaccepted.finite_estimates === true
        @test unaccepted.loglik > result.candidate_summary[1].loglik
    end

    @testset "best later K0 start anchors all derived K1 starts" begin
        d = _arc1_optimizer_fixed_fixture()
        runner = function (ctx, params0, rank, start_id)
            fit = HSquared._arc1_fa_exact_objective_gradient(ctx, params0, rank)
            fit.status == :ok || error("injected objective failed")
            (; phat = copy(params0), objective = fit.raw_objective,
                converged = true, iterations = 1, optimizer_status = "accepted start")
        end
        result = HSquared._arc1_select_fa_rank(d.Y, d.X, d.Z, d.ped;
            optimizer_policy = "arc1_v1", attempt_runner = runner)
        k0 = filter(a -> a.rank == 0 && a.eligible, result.attempts)
        @test length(k0) == 6
        best = k0[argmax(getproperty.(k0, :loglik))]
        @test best.start_id == Symbol("split_0.3")
        @test all(best.loglik > row.loglik for row in k0 if row.start_id != best.start_id)
        k1_rows = filter(a -> a.rank == 1, result.attempts)
        @test getproperty.(k1_rows, :schedule_index) == collect(1:18)
        @test all(a -> a.k0_anchor_start_id == string(best.start_id), k1_rows)
        starts = HSquared._arc1_derived_starts(best)
        @test length(starts) == 16
        for start in starts
            observed = only(filter(a -> a.rank == 1 && a.start_id == start.name,
                                   result.attempts))
            @test observed.initial_parameters == start.params
        end
    end
end
