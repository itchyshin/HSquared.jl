using LinearAlgebra
using Random
using Test
using HSquared

# Candidate-only tests. The implementation is deliberately not wired into
# src/HSquared.jl; include it here after the shared v1 context definitions.
if !isdefined(HSquared, :_Arc1FASpectralContext)
    Base.include(HSquared, joinpath(@__DIR__, "..", "src", "arc1_fa.jl"))
end
if !isdefined(HSquared, :_arc1_fa_v2_factor_state)
    Base.include(HSquared, joinpath(@__DIR__, "..", "src", "arc1_fa_factors.jl"))
end

function _arc1_factorv2_fixture()
    n = 6
    X = hcat(ones(n), [-1.0, -0.65, -0.2, 0.15, 0.7, 1.1])
    F = [1.0 0.0; 0.25 0.75; -0.5 0.4; 0.8 -0.35; -0.7 0.5; 0.35 1.0]
    B = F * transpose(F) + Diagonal([0.2, 0.35, 0.18, 0.4, 0.3, 0.22])
    Y = [0.2 0.9 -0.4 1.2; 1.1 0.4 0.7 -0.3; -0.1 1.5 0.2 0.8;
         0.7 0.1 1.3 -0.5; 1.4 0.6 -0.2 0.3; 0.5 1.0 0.9 1.1]
    L = [0.9 0 0 0; 0.12 1.0 0 0; -0.04 0.08 0.85 0; 0.06 -0.03 0.1 0.95]
    lambda = [-0.42, 0.31, -0.18, 0.53]
    delta = [0.24, 0.36, 0.19, 0.47] .- HSquared.FA_UNIQUENESS_FLOOR
    chol = Float64[]
    for j in 1:4, i in j:4
        push!(chol, i == j ? log(L[i, j]) : L[i, j])
    end
    p0 = vcat(log.(delta), chol)
    p1 = vcat(lambda, log.(delta), chol)
    (; Y, X, B, L, lambda, delta, p0, p1)
end

function _arc1_factorv2_dense_reml(Y, X, B, G, R)
    n = size(Y, 1)
    V = kron(G, B) + kron(R, Matrix{Float64}(I, n, n))
    Xfull = kron(Matrix{Float64}(I, 4, 4), X)
    y = vec(Y)
    FV = cholesky(Symmetric(V); check = true)
    ViX = FV \ Xfull
    FC = cholesky(Symmetric(transpose(Xfull) * ViX); check = true)
    beta = FC \ (transpose(Xfull) * (FV \ y))
    e = y - Xfull * beta
    ll = -0.5 * ((length(y) - size(Xfull, 2)) * log(2π) +
                 logdet(FV) + logdet(FC) + dot(e, FV \ e))
    (; loglik = ll, beta)
end

function _arc1_factorv2_fd(f, x; h = 2e-5)
    out = similar(x)
    for j in eachindex(x)
        plus, minus = copy(x), copy(x)
        plus[j] += h
        minus[j] -= h
        out[j] = (f(plus) - f(minus)) / (2h)
    end
    out
end

struct _Arc1FactorV2InterruptMatrix <: AbstractMatrix{Float64}
    dimensions::Tuple{Int,Int}
end
Base.size(x::_Arc1FactorV2InterruptMatrix) = x.dimensions
Base.getindex(::_Arc1FactorV2InterruptMatrix, ::Int, ::Int) = throw(InterruptException())

function _arc1_factorv2_big_objective(Y, X, B, params, k; bits = 256, mode = :coordinates)
    setprecision(BigFloat, bits) do
        c = BigFloat(HSquared.FA_UNIQUENESS_FLOOR)
        if mode == :retained
            state = HSquared._arc1_fa_v2_factor_state(params, k).state
            loading = BigFloat.(state.loadings)
            delta = BigFloat.(state.delta)
            LR = BigFloat.(state.residual_factor)
        else
            par = BigFloat.(params)
            if k == 0
                loading = zeros(BigFloat, 4, 0)
                eta = par[1:4]
                first_residual = 5
            else
                loading = reshape(par[1:4], 4, 1)
                eta = par[5:8]
                first_residual = 9
            end
            delta = exp.(eta)
            LR = zeros(BigFloat, 4, 4)
            index = first_residual - 1
            for j in 1:4, i in j:4
                index += 1
                LR[i, j] = i == j ? exp(par[index]) : par[index]
            end
        end
        G = loading * transpose(loading) + Diagonal(c .+ delta)
        R = LR * transpose(LR)
        Yb, Xb, Bb = BigFloat.(Y), BigFloat.(X), BigFloat.(B)
        n, p = size(Yb, 1), size(Xb, 2)
        df = 4n - 4p
        V = kron(G, Bb) + kron(R, Matrix{BigFloat}(I, n, n))
        Xfull = kron(Matrix{BigFloat}(I, 4, 4), Xb)
        y = vec(Yb)
        FV = cholesky(Symmetric(V); check = true)
        ViX = FV \ Xfull
        FC = cholesky(Symmetric(transpose(Xfull) * ViX); check = true)
        beta = FC \ (transpose(Xfull) * (FV \ y))
        residual = y - Xfull * beta
        raw = (df * log(2big(π)) + logdet(FV) + logdet(FC) + dot(residual, FV \ residual)) / 2
        (; objective = raw / df, loglik = -raw)
    end
end

function _arc1_factorv2_big_fd(Y, X, B, params, k; bits = 256, scale = big"1e-14")
    setprecision(BigFloat, bits) do
        center = BigFloat.(params)
        out = similar(center)
        for j in eachindex(center)
            h = scale * max(BigFloat(1), abs(center[j]))
            plus, minus = copy(center), copy(center)
            plus[j] += h
            minus[j] -= h
            fp = _arc1_factorv2_big_objective(Y, X, B, plus, k; bits, mode = :coordinates).objective
            fm = _arc1_factorv2_big_objective(Y, X, B, minus, k; bits, mode = :coordinates).objective
            out[j] = (fp - fm) / (2h)
        end
        out
    end
end

const _ARC1_FACTORV2_RETAINED_COORDINATES = (
    # Coordinates retained in fa-fixed-coordinate-prerun/results.toml for
    # Case 10 / seed 202610051019, balanced.
    [0.5397270510968595, -0.14898098215772482, 0.45849499282198775,
     -0.03869734037063283, -0.6491304865484382, -46.43743202222616,
     -23.61925220042417, -1.7933624364566507, -0.7143577664254082,
     0.12380812205076333, -0.15052200945788266, 0.21076217379813642,
     0.005829871521246336, 0.24694972431752035, -0.14924278179857856,
     -0.24921581802998582, 0.2433992016105675, -0.07477917075205318],
    # Coordinates retained for Case 3 / seed 202610050302, balanced.
    [-0.5514739334913559, -0.49569825118109234, 0.7564679571072862,
     1.0507336659455269, -25.826929379031807, -27.900455525756303,
     -0.656594691292747, -29.280795088634775, -0.17331947212006335,
     0.07156689106775757, 0.21568835329093303, 0.32702751136585256,
     -0.23778266053532557, 0.08984768610253359, 0.12827388581337668,
     -1.033325204812786, -0.3059441004246016, -18.74336534010888],
    # Coordinates retained for Case 11 / seed 202610051108, derived_a0.1_s1.
    [0.6566485574771947, -0.2315580239900849, 0.0494140501463466,
     0.13732198224674896, -24.919929256431885, -0.28518951967741113,
     -1.9291336857145691, -0.2626973873509556, -0.47225577263135265,
     0.6186791564281401, 0.07184688643151287, 0.07436498783125858,
     -2.965813212837078, -0.073598735641604, 0.5691977810682973,
     -0.3294232845434481, 0.20686183185278503, -18.623377098609936],
)

@testset "Arc1 v2 retained factor core (unwired candidate)" begin
    d = _arc1_factorv2_fixture()
    built = HSquared._arc1_fa_spectral_context(d.Y, d.X, d.B)
    @test built.status == :ok
    ctx = built.context

    @testset "factor decode preserves excess and declared packing order" begin
        for (k, params, expected_loadings) in ((0, d.p0, zeros(4, 0)), (1, d.p1, reshape(d.lambda, 4, 1)))
            decoded = HSquared._arc1_fa_v2_factor_state(params, k)
            @test decoded.status == :ok
            s = decoded.state
            @test s.rank == k
            @test s.factor_order == :loading_floor_uniqueness_residual
            @test s.loadings == expected_loadings
            @test s.delta ≈ d.delta atol = 2e-16 rtol = 0
            @test s.residual_factor ≈ d.L atol = 2e-15 rtol = 0
            @test s.pd_residual
            @test s.pd_genetic
        end

        # A positive excess can be smaller than one ulp at the floor. Its
        # mathematical value remains available even when rounded psi-c is 0.
        tiny_eta = log(eps(Float64(HSquared.FA_UNIQUENESS_FLOOR)) / 4)
        p = copy(d.p0)
        p[1] = tiny_eta
        tiny = HSquared._arc1_fa_v2_factor_state(p, 0)
        @test tiny.status == :ok
        @test tiny.state.delta[1] > 0
        @test tiny.state.psi[1] == tiny.state.floor
        @test tiny.state.rounded_floor_distance[1] == 0
        @test tiny.state.floor_rounding
        @test HSquared._arc1_fa_v2_factor_state(BigFloat.(d.p0), 0).status == :invalid_proposal
        @test HSquared._arc1_fa_v2_factor_state(Int.(round.(d.p0)), 0).status == :invalid_proposal
        @test HSquared._arc1_fa_v2_factor_state(fill("bad", 14), 0).status == :invalid_proposal
        @test HSquared._arc1_fa_v2_factor_state(d.p0, true).status == :invalid_proposal
        @test HSquared._arc1_fa_v2_factor_state(d.p0, 1.0).status == :invalid_proposal
    end

    @testset "spectral QR factors preserve K0/K1 covariance and ordering" begin
        for (k, params) in ((0, d.p0), (1, d.p1))
            state = HSquared._arc1_fa_v2_factor_state(params, k).state
            G = state.G
            R = d.L * transpose(d.L)
            for eigenvalue in (0.0, 0.17, 1.6)
                Lb = HSquared._arc1_fa_v2_block_factor(state, eigenvalue)
                @test Lb !== nothing
                @test istril(Lb)
                @test all(>(0), diag(Lb))
                @test Lb * transpose(Lb) ≈ eigenvalue .* G + R atol = 2e-14 rtol = 2e-14
                if eigenvalue == 0
                    @test Lb == state.residual_factor
                end
            end
        end
        # The residual coordinates use column-major lower-triangle packing.
        state = HSquared._arc1_fa_v2_factor_state(d.p0, 0).state
        @test state.residual_factor[2, 1] == d.p0[6]
        @test state.residual_factor[3, 2] == d.p0[10]
        @test log(state.residual_factor[4, 4]) == d.p0[14]
    end

    @testset "objective, full REML correction, independent QR certificate, and scores" begin
        for (k, params) in ((0, d.p0), (1, d.p1))
            out = HSquared._arc1_fa_v2_exact_objective_gradient(ctx, params, k)
            state = out.factor_state
            dense = _arc1_factorv2_dense_reml(d.Y, d.X, d.B, state.G, state.R)
            @test out.status == :ok
            @test out.loglik ≈ dense.loglik atol = 2e-9 rtol = 0
            @test out.fixed_effects ≈ reshape(dense.beta, size(d.X, 2), 4) atol = 2e-9 rtol = 0
            independent = HSquared._arc1_fa_v2_independent_loglik(d.Y, d.X, d.B, params, k)
            @test independent.status == :ok
            @test independent.loglik ≈ dense.loglik atol = 2e-9 rtol = 0
            @test last(independent.observations).stage == :likelihood
            @test HSquared._arc1_fa_v2_certify(d.Y, d.X, d.B, params, k, out.loglik).status == :ok
            f = x -> HSquared._arc1_fa_v2_exact_objective_gradient(ctx, x, k).objective
            @test out.gradient ≈ _arc1_factorv2_fd(f, params) atol = 4e-6 rtol = 3e-5

            # Reorder spectral blocks and their matching rotations. Values and
            # coordinate gradients must not depend on eigensolver order/sign.
            E = eigen(Symmetric(d.B))
            perm = reverse(eachindex(E.values))
            U = E.vectors[:, perm] * Diagonal([isodd(i) ? -1.0 : 1.0 for i in eachindex(perm)])
            reordered = HSquared._arc1_fa_context_from_eigen(d.Y, d.X, E.values[perm], U)
            @test reordered.status == :ok
            alt = HSquared._arc1_fa_v2_exact_objective_gradient(reordered.context, params, k)
            @test alt.loglik ≈ out.loglik atol = 2e-9 rtol = 0
            @test alt.gradient ≈ out.gradient atol = 2e-8 rtol = 0
        end
    end

    @testset "relationship symmetry follows the canonical model input" begin
        slight = copy(d.B)
        slight[1, 2] += 1e-13
        canonical = (slight + transpose(slight)) / 2
        spectral_slight = HSquared._arc1_fa_spectral_context(d.Y, d.X, slight)
        spectral_canonical = HSquared._arc1_fa_spectral_context(d.Y, d.X, canonical)
        @test spectral_slight.status == :ok
        @test spectral_canonical.status == :ok
        opt_slight = HSquared._arc1_fa_v2_exact_objective_gradient(spectral_slight.context, d.p1, 1)
        opt_canonical = HSquared._arc1_fa_v2_exact_objective_gradient(spectral_canonical.context, d.p1, 1)
        cert_slight = HSquared._arc1_fa_v2_independent_loglik(d.Y, d.X, slight, d.p1, 1)
        cert_canonical = HSquared._arc1_fa_v2_independent_loglik(d.Y, d.X, canonical, d.p1, 1)
        @test cert_slight.status == :ok
        @test cert_canonical.status == :ok
        @test opt_slight.loglik ≈ opt_canonical.loglik atol = 2e-12 rtol = 0
        @test cert_slight.loglik ≈ cert_canonical.loglik atol = 2e-12 rtol = 0

        material = copy(d.B)
        material[1, 2] += 1e-5
        @test HSquared._arc1_fa_spectral_context(d.Y, d.X, material).status == :invalid_input
        rejected = HSquared._arc1_fa_v2_independent_loglik(d.Y, d.X, material, d.p1, 1)
        @test rejected.status == :invalid_input
        @test rejected.failure_stage == :input
    end

    @testset "retained difficult coordinates against independent high precision" begin
        # These three saved coordinate vectors define new six-record diagnostic
        # cases here; this does not reproduce the retained 80-record witnesses.
        # Their original responses were reconstructed only for that prior evidence.
        for params in _ARC1_FACTORV2_RETAINED_COORDINATES
            decoded = HSquared._arc1_fa_v2_factor_state(params, 1)
            @test decoded.status == :ok
            out = HSquared._arc1_fa_v2_exact_objective_gradient(ctx, params, 1)
            @test out.status == :ok
            retained256 = _arc1_factorv2_big_objective(d.Y, d.X, d.B, params, 1;
                                                       bits = 256, mode = :retained)
            retained384 = _arc1_factorv2_big_objective(d.Y, d.X, d.B, params, 1;
                                                       bits = 384, mode = :retained)
            transformed256 = _arc1_factorv2_big_objective(d.Y, d.X, d.B, params, 1;
                                                          bits = 256, mode = :coordinates)
            @test abs(retained256.loglik - retained384.loglik) <= big"1e-70"
            @test abs(retained256.loglik - transformed256.loglik) <= big"1e-8"
            @test abs(BigFloat(out.loglik) - retained256.loglik) <= big"1e-8"
            for step in (big"1e-14", big"1e-18")
                hp_gradient = _arc1_factorv2_big_fd(d.Y, d.X, d.B, params, 1;
                                                   bits = 256, scale = step)
                @test norm(BigFloat.(out.gradient) - hp_gradient, Inf) <= big"5e-6"
            end
            independent = HSquared._arc1_fa_v2_independent_loglik(d.Y, d.X, d.B, params, 1)
            @test independent.status == :ok
            @test abs(BigFloat(independent.loglik) - retained256.loglik) <= big"1e-8"
        end
    end

    @testset "machine-domain and accuracy controls refuse" begin
        p = copy(d.p0)
        p[1] = -1000.0
        @test HSquared._arc1_fa_v2_factor_state(p, 0).status == :invalid_proposal
        p = copy(d.p0)
        p[1] = 1000.0
        @test HSquared._arc1_fa_v2_factor_state(p, 0).status == :invalid_proposal
        p = copy(d.p0)
        p[5] = -1000.0
        @test HSquared._arc1_fa_v2_factor_state(p, 0).status == :invalid_proposal
        p = copy(d.p1)
        p[1] = Inf
        @test HSquared._arc1_fa_v2_factor_state(p, 1).status == :invalid_proposal

        valid = HSquared._arc1_fa_v2_exact_objective_gradient(ctx, d.p1, 1)
        @test valid.status == :ok
        bad_certificate = HSquared._arc1_fa_v2_certify(d.Y, d.X, d.B, d.p1, 1, valid.loglik + 2e-8)
        @test bad_certificate.status == :failed
        @test bad_certificate.discrepancy > 1e-8
        @test HSquared._arc1_fa_v2_certify(d.Y, d.X, d.B, d.p1, 1, NaN).status == :failed

        at_limits = HSquared._arc1_fa_v2_accuracy_check(0.0, 1e-8, [0.0], [5e-6], [-5e-6], true)
        @test at_limits.passed
        @test HSquared._arc1_fa_v2_accuracy_check(0.0, 0.0, [1e-6], [1e-6], [1e-6], true).passed
        @test HSquared._arc1_fa_v2_accuracy_check(0.0, nextfloat(1e-8), [0.0], [0.0], [0.0], true).status == :failed
        @test HSquared._arc1_fa_v2_accuracy_check(0.0, 0.0, [nextfloat(1e-6)], [0.0], [0.0], true).status == :failed
        @test HSquared._arc1_fa_v2_accuracy_check(0.0, 0.0, [0.0], [nextfloat(5e-6)], [0.0], true).status == :failed
        @test HSquared._arc1_fa_v2_accuracy_check(0.0, 0.0, [0.0], [0.0], [0.0], false).status == :failed
        @test HSquared._arc1_fa_v2_accuracy_check(0.0, 0.0, nothing, [0.0], [0.0], true).status == :failed
        @test HSquared._arc1_fa_v2_accuracy_check(0.0, 0.0, [0.0], [0.0], [0.0], 1).status == :failed
        for leaf in ("bad", missing, true, 1 + 0im)
            malformed = HSquared._arc1_fa_v2_accuracy_check(
                0.0, 0.0, Any[leaf], [0.0], [0.0], true)
            @test malformed.status == :failed
            @test !malformed.passed
        end

        # Ordinary numerical failure is returned with all successful stages;
        # task interruption remains an exception and reaches the caller.
        singular_designs = (
            hcat(d.X[:, 1], d.X[:, 1]),
            hcat(d.X[:, 2], 2 .* d.X[:, 2]),
            hcat(d.X[:, 1], d.X[:, 2], 2 .* d.X[:, 1] .- 3 .* d.X[:, 2]),
        )
        for singular_X in singular_designs
            refused = HSquared._arc1_fa_v2_independent_loglik(d.Y, singular_X, d.B, d.p0, 0)
            @test refused.status == :invalid_input
            @test refused.failure_stage == :fixed_effect_design
            @test last(refused.observations).stage == :validated_input
        end
        @test_throws InterruptException HSquared._arc1_fa_v2_independent_loglik(
            _Arc1FactorV2InterruptMatrix(size(d.Y)), d.X, d.B, d.p0, 0)

        # The two saved residual-coordinate perturbations remain factor-valid.
        # Case 11's rounded residual-PD report is recorded as a Boolean below;
        # its historical classification is not assumed to be platform invariant.
        case3 = copy(_ARC1_FACTORV2_RETAINED_COORDINATES[2])
        case3[9] -= 1e-5
        residual_case3 = HSquared._arc1_fa_v2_factor_state(case3, 1)
        @test residual_case3.status == :ok
        @test residual_case3.state.factor_valid
        @test !residual_case3.state.pd_residual
        @test HSquared._arc1_fa_v2_block_factor(residual_case3.state, 0.7) !== nothing
        case11 = copy(_ARC1_FACTORV2_RETAINED_COORDINATES[3])
        case11[13] -= 1e-4
        residual_case11 = HSquared._arc1_fa_v2_factor_state(case11, 1)
        @test residual_case11.status == :ok
        @test residual_case11.state.factor_valid
        @test residual_case11.state.pd_residual isa Bool
        @test HSquared._arc1_fa_v2_block_factor(residual_case11.state, 0.7) !== nothing

        # A zero relationship eigenvalue is exact, not a dropped underflowed
        # genetic column; the residual factor remains authoritative.
        state = HSquared._arc1_fa_v2_factor_state(d.p1, 1).state
        @test HSquared._arc1_fa_v2_block_factor(state, 0.0) == state.residual_factor

        # Portable rounded-PD-loss control: the retained factor is nonsingular,
        # while its exact Float64 Gram has a duplicated leading row/column.
        rounding_params = copy(d.p0)
        rounding_params[5:14] .= (0.0, 1.0, 0.0, 0.0, log(1e-10), 0.0, 0.0, 0.0, 0.0, 0.0)
        rounding = HSquared._arc1_fa_v2_factor_state(rounding_params, 0)
        @test rounding.status == :ok
        rounding_factor = rounding.state.residual_factor
        @test all(>(0), diag(rounding_factor))
        @test rounding_factor[1:2, 1:2] == [1.0 0.0; 1.0 exp(rounding_params[9])]
        @test rounding.state.R[1:2, 1:2] == [1.0 1.0; 1.0 1.0]
        @test !rounding.state.pd_residual
        @test HSquared._arc1_fa_v2_block_factor(rounding.state, 0.0) == rounding_factor

        # A late score failure remains distinct from the valid likelihood that
        # was already evaluated at these exact coordinates and factors.
        valid_likelihood = HSquared._arc1_fa_v2_exact_objective_gradient(ctx, d.p1, 1)
        nonfinite_gradient = copy(valid_likelihood.gradient)
        nonfinite_gradient[1] = NaN
        preserved = HSquared._arc1_fa_v2_gradient_failure(
            valid_likelihood.raw_objective, ctx.df, valid_likelihood.factor_state,
            vec(permutedims(valid_likelihood.fixed_effects)), nonfinite_gradient)
        @test preserved.status == :failed
        @test preserved.loglik == valid_likelihood.loglik
        @test preserved.raw_objective == valid_likelihood.raw_objective
        @test preserved.gradient[1] === NaN
        @test preserved.observation.stage == :likelihood
        @test preserved.observation.parameters == d.p1
        @test preserved.observation.factor_state.parameters == d.p1
        @test last(preserved.observations).stage == :gradient
        @test last(preserved.observations).status == :failed
    end
end
