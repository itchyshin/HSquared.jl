using HSquared
using LinearAlgebra
using Random
using Test

# This oracle deliberately assembles record-major V and X_full from scalar
# indices. It shares no Kronecker/order helper with the selector.
function _auto_fa_dense_reml(Y, X, A, G, R; shared_intercept = false)
    n, t = size(Y)
    p = size(X, 2)
    y = [Y[i, j] for i in 1:n for j in 1:t]
    D = zeros(n * t, shared_intercept ? p : p * t)
    V = zeros(n * t, n * t)
    for i in 1:n, a in 1:t
        row = (i - 1) * t + a
        if shared_intercept
            # Deliberately wrong negative-control design: one intercept shared
            # across all traits instead of one fixed intercept per trait.
            D[row, 1] = X[i, 1]
        else
            for c in 1:p
                D[row, (c - 1) * t + a] = X[i, c]
            end
        end
        for k in 1:n, b in 1:t
            col = (k - 1) * t + b
            V[row, col] = A[i, k] * G[a, b] + (i == k ? R[a, b] : 0.0)
        end
    end
    F = cholesky(Symmetric(V))
    yw = F.L \ y
    Dw = F.L \ D
    C = cholesky(Symmetric(Dw' * Dw))
    beta = C \ (Dw' * yw)
    e = yw - Dw * beta
    ll = -0.5 * ((n * t - p * t) * log(2π) +
        2sum(log, diag(F.L)) + 2sum(log, diag(C.L)) + dot(e, e))
    return (; loglik = ll, V, D, y)
end

function _auto_fa_fixture(; n = 12, seed = 20261001, informative = true)
    ids = collect(1:n)
    sire = zeros(Int, n); dam = zeros(Int, n)
    if informative
        for i in 5:n
            sire[i] = 1 + (i - 5) % 2
            dam[i] = 3 + (i - 5) % 2
        end
    end
    ped = normalize_pedigree(ids, sire, dam)
    A = informative ? Matrix(inv(Symmetric(Matrix(pedigree_inverse(ped))))) : Matrix{Float64}(I, n, n)
    rng = MersenneTwister(seed)
    lambda = reshape([0.85, -0.55, 0.72, 0.43], 4, 1)
    psi = [0.38, 0.52, 0.47, 0.61]
    G = lambda * lambda' + Diagonal(psi)
    R = [1.0 0.12 0.02 0.0; 0.12 0.9 -0.04 0.03;
         0.02 -0.04 1.1 0.08; 0.0 0.03 0.08 0.95]
    U = cholesky(Symmetric(A)).L * randn(rng, n, 4) * cholesky(Symmetric(Matrix(G))).L'
    E = randn(rng, n, 4) * cholesky(Symmetric(R)).L'
    Y = repeat(reshape([0.5, -0.2, 0.8, 1.1], 1, 4), n, 1) + U + E
    return (; Y, X = ones(n, 1), Z = Matrix{Float64}(I, n, n), ped, A, G, R, ids)
end

@testset "automatic FA independent ordering and confounding witnesses" begin
    d = _auto_fa_fixture()
    ell = _auto_fa_dense_reml(d.Y, d.X, d.A, d.G, d.R).loglik
    ap = [12, 3, 8, 1, 7, 2, 11, 4, 9, 6, 5, 10]
    tp = [3, 1, 4, 2]
    mapped = _auto_fa_dense_reml(d.Y[ap, tp], d.X[ap, :], d.A[ap, ap],
        d.G[tp, tp], d.R[tp, tp])
    @test mapped.loglik ≈ ell atol = 1e-10
    wrong_trait_order = [d.Y[i, j] for j in 1:4 for i in 1:12]
    @test norm(wrong_trait_order - mapped.y) > 1e-3

    # With one record per unrelated animal, only G+R enters V.
    I4 = Matrix{Float64}(I, 4, 4)
    G1 = [1.0 0.1 0 0; 0.1 1.2 0 0; 0 0 0.8 0.1; 0 0 0.1 1.1]
    R1 = Matrix{Float64}(I, 4, 4)
    G2 = G1 + Diagonal([0.2, 0.1, 0.3, 0.2])
    R2 = R1 - Diagonal([0.2, 0.1, 0.3, 0.2])
    V1 = kron(I4, G1) + kron(I4, R1)
    V2 = kron(I4, G2) + kron(I4, R2)
    @test V1 == V2

    # Half-sib relatedness is proportional to identity after removing the
    # intercept direction, so raw A != I does not rescue G/R separation.
    n, rho = 8, 0.25
    Ahs = (1 - rho) * Matrix{Float64}(I, n, n) + rho * ones(n, n)
    Xfull = ones(n, 1)
    Q = nullspace(Xfull')
    H = Q' * Ahs * Q
    J = Q' * Matrix{Float64}(I, n, n) * Q
    @test H ≈ (1 - rho) .* J atol = 1e-12
    K = hcat(vec(H) / norm(H), vec(J) / norm(J))
    @test det(K' * K) < 1e-12
end

@testset "automatic FA production selector preserves animal and trait order" begin
    d = _auto_fa_fixture()
    canonical_traits = ["a", "b", "c", "d"]
    c = HSquared.FA_UNIQUENESS_FLOOR
    runner_for = function (ordered_traits)
        ix = [findfirst(==(trait), canonical_traits) for trait in ordered_traits]
        G0 = Matrix(Diagonal(diag(d.G)[ix]))
        R = d.R[ix, ix]
        p0 = vcat(log.(diag(G0) .- c), HSquared._cov_to_chol_params(R, 4))
        # This controlled FA receipt is exactly nested at L=0, so the order
        # witness does not depend on an optimizer finding a better rank-1 fit.
        p1 = vcat(zeros(4), log.(diag(G0) .- c), HSquared._cov_to_chol_params(R, 4))
        return function (objective, params0, iterations, rank, start_id)
            p = rank == 0 ? copy(p0) : copy(p1)
            return (; phat=p, objective=objective(p), converged=true,
                    iterations=1, optimizer_status="permutation witness")
        end
    end
    runner = runner_for(canonical_traits)
    base = HSquared._select_fa_rank(d.Y, d.X, d.Z, d.ped; ids=d.ids,
        traits=canonical_traits, attempt_runner=runner)
    @test base.selection_status == :selected
    @test base.selected_rank == 0
    expected_G = Matrix(Diagonal(diag(d.G)))
    expected_R = copy(d.R)
    independent = _auto_fa_dense_reml(d.Y, d.X, d.A, expected_G, expected_R)
    @test base.selected_fit.genetic_covariance ≈ expected_G atol = 1e-10
    @test base.selected_fit.residual_covariance ≈ expected_R atol = 1e-10
    @test base.selected_fit.loglik ≈ independent.loglik atol = 1e-8

    # Row permutation must move Y, X and the observation-to-pedigree map as one
    # object. The independent dense REML oracle fixes the expected same G/R;
    # the returned ID-indexed BLUP matrix must agree after mapping by IDs.
    ap = [12, 3, 8, 1, 7, 2, 11, 4, 9, 6, 5, 10]
    animal = HSquared._select_fa_rank(d.Y[ap, :], d.X[ap, :], d.Z[ap, :], d.ped;
        ids=d.ids, traits=["a", "b", "c", "d"], attempt_runner=runner)
    @test animal.selection_status == :selected
    @test animal.selected_rank == base.selected_rank
    @test animal.criterion_difference ≈ base.criterion_difference atol = 1e-8
    @test animal.selected_fit.loglik ≈ base.selected_fit.loglik atol = 1e-8
    @test animal.selected_fit.genetic_covariance ≈ base.selected_fit.genetic_covariance atol = 1e-8
    @test animal.selected_fit.residual_covariance ≈ base.selected_fit.residual_covariance atol = 1e-8
    @test animal.selected_fit.breeding_values.ids == base.selected_fit.breeding_values.ids
    @test animal.selected_fit.breeding_values.values ≈ base.selected_fit.breeding_values.values atol = 1e-7

    # Trait permutation has to carry labels and both covariance axes, then map
    # the user-visible result back to the original trait order.
    tp = [3, 1, 4, 2]
    permuted_traits = canonical_traits[tp]
    trait_runner = runner_for(permuted_traits)
    trait = HSquared._select_fa_rank(d.Y[:, tp], d.X, d.Z, d.ped; ids=d.ids,
        traits=permuted_traits, attempt_runner=trait_runner)
    @test trait.selection_status == :selected
    @test trait.selected_rank == base.selected_rank
    @test trait.criterion_difference ≈ base.criterion_difference atol = 1e-8
    @test trait.selected_fit.loglik ≈ base.selected_fit.loglik atol = 1e-8
    @test trait.selected_fit.breeding_values.traits == ["c", "a", "d", "b"]
    @test trait.selected_fit.breeding_values.values[:, invperm(tp)] ≈
          base.selected_fit.breeding_values.values atol = 1e-7
    @test trait.selected_fit.genetic_covariance[invperm(tp), invperm(tp)] ≈
          base.selected_fit.genetic_covariance atol = 1e-8
    @test trait.selected_fit.residual_covariance[invperm(tp), invperm(tp)] ≈
          base.selected_fit.residual_covariance atol = 1e-8

    # Negative control: permuting responses but leaving Z in the old order is
    # a different model. Its independently evaluated likelihood must not pass
    # as an order-preserving transformation.
    wrong = HSquared._select_fa_rank(d.Y[ap, :], d.X[ap, :], d.Z, d.ped;
        ids=d.ids, traits=canonical_traits, attempt_runner=runner)
    @test wrong.selection_status == :selected
    @test abs(wrong.selected_fit.loglik - animal.selected_fit.loglik) > 1e-6
end

@testset "automatic FA selector dense REML and criterion contract" begin
    d = _auto_fa_fixture()
    ref = _auto_fa_dense_reml(d.Y, d.X, d.A, d.G, d.R)
    @test ref.y[1:4] == collect(d.Y[1, :])
    @test ref.V[1, 6] == d.A[1, 2] * d.G[1, 2]
    @test ref.V[1, 2] == d.A[1, 1] * d.G[1, 2] + d.R[1, 2]
    @test ref.loglik ≈ HSquared._multivariate_reml_loglik(
        d.Y, d.X, d.Z, pedigree_inverse(d.ped), d.G, d.R) atol = 1e-10

    q0, q1, qr = 14, 18, 10
    ell0, ell1 = -120.0, -115.0
    c0, c1 = -2ell0 + 2q0, -2ell1 + 2q1
    D = 8 - 2(ell1 - ell0)
    @test (q0 - qr, q1 - qr) == (4, 8)
    @test (c0, c1, D) == (268.0, 266.0, -2.0)
    @test c1 - c0 == D
    preferred = HSquared._fa_rank_score(ell0, ell1)
    @test preferred.criterion_difference == D
    @test preferred.selected_rank == 1
    # A 3.9-unit likelihood gain still favors K=0 under the declared +8
    # penalty; reversing the sign would incorrectly select K=1.
    margin_control = HSquared._fa_rank_score(0.0, 3.9)
    @test margin_control.criterion_difference ≈ 0.2
    @test margin_control.selected_rank == 0
    wrong_sign_difference = 8 + 2 * (4.1)
    @test wrong_sign_difference > 0
    just_over = HSquared._fa_rank_score(0.0, 4.1)
    @test (wrong_sign_difference < -1e-6 ? 1 : 0) != just_over.selected_rank
    wrong_penalty_difference = 6 - 2 * 3.9
    @test (wrong_penalty_difference < -1e-6 ? 1 : 0) != margin_control.selected_rank

    tau = 1e-6
    exact = HSquared._fa_rank_score(0.0, 4.0)
    inside = HSquared._fa_rank_score(0.0, 4.0 + tau / 4)
    outside_k1 = HSquared._fa_rank_score(0.0, 4.0 + tau)
    outside_k0 = HSquared._fa_rank_score(0.0, 4.0 - tau)
    @test exact.near_tie && exact.selected_rank == 0
    @test inside.near_tie && inside.selected_rank == 0
    @test !outside_k1.near_tie && outside_k1.selected_rank == 1
    @test !outside_k0.near_tie && outside_k0.selected_rank == 0
end

@testset "automatic FA matched floor and injected failure ledger" begin
    c = HSquared.FA_UNIQUENESS_FLOOR
    theta = log.([0.25, 0.4, 0.55, 0.7])
    G0, L0, psi0 = HSquared._fa_rank_cov(theta, 0)
    @test L0 === nothing
    @test psi0 ≈ c .+ exp.(theta)
    @test G0 ≈ Matrix(Diagonal(c .+ exp.(theta)))
    # Independent scalar construction is the O1 oracle; the no-floor version
    # is an explicit wrong comparator and must fail the same-covariance check.
    G0_ref = zeros(4, 4)
    for i in 1:4
        G0_ref[i, i] = c + exp(theta[i])
    end
    @test G0 ≈ G0_ref
    G0_unmatched = Matrix(Diagonal(exp.(theta)))
    @test !isapprox(G0_unmatched, G0_ref; atol=1e-12, rtol=1e-12)
    @test minimum(diag(G0_unmatched) .- c) < minimum(diag(G0_ref) .- c)
    loading = [0.4, -0.7, 0.2, 0.9]
    fa_params = vcat(loading, log.([0.3, 0.4, 0.5, 0.6]))
    G1, L1, psi1 = HSquared._fa_rank_cov(fa_params, 1)
    @test size(G0) == size(G1) == (4, 4)
    @test size(L1) == (4, 1)
    @test psi1 ≈ c .+ exp.(fa_params[5:8])
    @test G1 ≈ L1 * L1' + Diagonal(psi1)
    @test L1 ≈ reshape(loading, 4, 1)
    G1_ref = zeros(4, 4)
    for i in 1:4, j in 1:4
        G1_ref[i, j] = loading[i] * loading[j] +
                       (i == j ? c + exp(fa_params[4 + i]) : 0.0)
    end
    @test G1 ≈ G1_ref
    G1_unmatched = loading * loading' + Diagonal(exp.(fa_params[5:8]))
    @test !isapprox(G1_unmatched, G1_ref; atol=1e-12, rtol=1e-12)
    @test all(isposdef(Symmetric(g)) for g in (G0, G1))

    d = _auto_fa_fixture()
    calls = Tuple{Int,Symbol}[]
    runner = function (objective, params0, iterations, rank, start_id)
        push!(calls, (rank, start_id))
        rank == 1 && error("synthetic FA optimizer failure")
        p = copy(params0)
        return (; phat=p, objective=objective(p), converged=true,
                iterations=1, optimizer_status="injected")
    end
    result = HSquared._select_fa_rank(d.Y, d.X, d.Z, d.ped;
        ids=d.ids, attempt_runner=runner)
    @test result.selection_status == :unavailable
    @test result.selected_rank === nothing
    @test length(calls) == 4
    @test length(result.attempts) == 4
    @test all(a.rank == 0 || a.status == :failed for a in result.attempts)
    @test length(result.candidate_summary) == 2
    @test result.candidate_summary[1].eligible
    @test !result.candidate_summary[2].eligible
    @test result.candidate_summary[2].reason !== nothing
    @test result.candidate_summary[1].eligible && !result.candidate_summary[2].eligible
    @test all(a -> a.rank == 1 ? a.reason !== nothing : a.status == :completed, result.attempts)
    @test all(a -> a.rank == 1 ? a.loglik === nothing && a.criterion === nothing :
              a.loglik !== nothing && a.criterion !== nothing, result.attempts)
end

@testset "automatic FA rejects corrupted optimizer receipts" begin
    d = _auto_fa_fixture()
    corruptions = (
        :nonfinite,
        :wrong_length,
        :wrong_objective,
        :at_floor,
    )
    for corruption in corruptions
        runner = function (objective, params0, iterations, rank, start_id)
            p = copy(params0)
            reported = objective(p)
            if rank == 0
                if corruption == :nonfinite
                    p[1] = NaN
                    reported = objective(p)
                elseif corruption == :wrong_length
                    p = p[1:end-1]
                    reported = objective(p)
                elseif corruption == :wrong_objective
                    reported += 0.01
                elseif corruption == :at_floor
                    p[1] = -1000.0
                    reported = objective(p)
                end
            end
            return (; phat=p, objective=reported, converged=true,
                    iterations=1, optimizer_status="injected")
        end
        result = HSquared._select_fa_rank(d.Y, d.X, d.Z, d.ped;
            ids=d.ids, attempt_runner=runner)
        @test result.selection_status == :unavailable
        @test result.selected_rank === nothing
        @test any(a -> a.rank == 0 && a.status == :failed, result.attempts)
        @test all(!a.selected for a in result.attempts)
        if corruption == :wrong_objective
            bad = filter(a -> a.rank == 0, result.attempts)
            @test all(a -> a.status == :failed && a.optimizer_objective !== nothing &&
                a.objective_discrepancy > 1e-8, bad)
            @test all(a -> a.loglik === nothing && a.criterion === nothing, bad)
        end
    end

    # Invalid optimizer minima cannot contaminate cross-start range or the
    # start-sensitivity flag. K0 is retained as an eligible ordinary winner;
    # every K1 receipt is independently rejected by the same +0.01 offset.
    offset_runner = function (objective, params0, iterations, rank, start_id)
        p = copy(params0)
        value = objective(p)
        rank == 1 && (value += 0.01)
        return (; phat=p, objective=value, converged=true, iterations=1,
                optimizer_status="offset negative control")
    end
    offset = HSquared._select_fa_rank(d.Y, d.X, d.Z, d.ped;
        ids=d.ids, attempt_runner=offset_runner)
    @test offset.selection_status == :unavailable
    @test offset.candidate_summary[1].eligible
    @test !offset.candidate_summary[2].eligible
    @test offset.candidate_summary[2].loglik === nothing
    @test offset.candidate_summary[2].criterion === nothing
    @test offset.candidate_summary[2].objective_range === nothing
    @test !offset.start_sensitive
    invalid_fa = filter(a -> a.rank == 1, offset.attempts)
    @test all(a -> a.status == :failed && a.optimizer_objective !== nothing &&
        a.loglik === nothing && a.criterion === nothing, invalid_fa)

    # Force finite optimizer receipts to reach the covariance-definiteness
    # guard. The intentionally wrong finite raw objective is diagnostic only;
    # it must not hide the semidefinite estimate behind the objective guard.
    finite_semidefinite_r = function (objective, params0, iterations, rank, start_id)
        p = copy(params0)
        if rank == 0
            for j in (5, 9, 12, 14)
                p[j] = -600log(2.0)
            end
            return (; phat=p, objective=0.0, converged=true, iterations=1,
                    optimizer_status="finite objective semidefinite R control")
        end
        return (; phat=p, objective=objective(p), converged=true, iterations=1,
                optimizer_status="finite objective covariance control")
    end
    finite_r = HSquared._select_fa_rank(d.Y, d.X, d.Z, d.ped;
        ids=d.ids, attempt_runner=finite_semidefinite_r)
    bad_finite_r = filter(a -> a.rank == 0, finite_r.attempts)
    @test !isempty(bad_finite_r)
    @test all(a -> a.finite_objective === true && a.pd_residual === false &&
        a.status == :failed && occursin("non-positive-definite covariance estimate", a.reason) &&
        a.loglik === nothing && a.criterion === nothing, bad_finite_r)
end

@testset "automatic FA selected K1 fit uses same-covariance dense objective" begin
    d = _auto_fa_fixture(n = 24, seed = 90101)
    lambda = [2.0, -1.8, 1.7, 2.1]
    psi = fill(0.15, 4)
    G1 = lambda * lambda' + Diagonal(psi)
    R1 = 0.15I(4)
    rng = MersenneTwister(90102)
    U = cholesky(Symmetric(d.A)).L * randn(rng, 24, 4) * cholesky(Symmetric(Matrix(G1))).L'
    E = randn(rng, 24, 4) * cholesky(Symmetric(Matrix(R1))).L'
    Y = repeat(reshape([0.4, -0.1, 0.6, 1.0], 1, 4), 24, 1) + U + E
    rparams = HSquared._cov_to_chol_params(Matrix(R1), 4)
    p0 = vcat(log.(diag(G1) .- HSquared.FA_UNIQUENESS_FLOOR), rparams)
    p1 = vcat(lambda, log.(psi .- HSquared.FA_UNIQUENESS_FLOOR), rparams)
    runner = function (objective, params0, iterations, rank, start_id)
        p = rank == 0 ? copy(p0) : copy(p1)
        return (; phat=p, objective=objective(p), converged=true,
                iterations=1, optimizer_status="injected known covariance")
    end
    result = HSquared._select_fa_rank(Y, d.X, d.Z, d.ped; ids=d.ids,
        traits=["t1", "t2", "t3", "t4"], attempt_runner=runner)
    @test result.selection_status == :selected
    @test result.selected_rank == 1
    @test result.selected_fit !== nothing
    chosen = only(filter(a -> a.selected, result.attempts))
    @test chosen.rank == 1
    @test chosen.start_id == result.candidate_summary[2].selected_start
    ref = _auto_fa_dense_reml(Y, d.X, d.A, result.selected_fit.genetic_covariance,
        result.selected_fit.residual_covariance)
    @test isapprox(result.selected_fit.loglik, ref.loglik; atol=1e-8, rtol=0)
    @test isapprox(result.selected_fit.genetic_covariance, G1; atol=1e-8, rtol=1e-8)
    @test isapprox(result.selected_fit.residual_covariance, R1; atol=1e-8, rtol=1e-8)
    wrong_design = _auto_fa_dense_reml(Y, d.X, d.A,
        result.selected_fit.genetic_covariance, result.selected_fit.residual_covariance;
        shared_intercept=true)
    @test abs(wrong_design.loglik - ref.loglik) > 1e-8
    @test result.nesting_witness_discrepancy !== nothing
    @test result.nesting_witness_discrepancy <= 1e-8

    # Explicit fixed-rank behavior remains its ordinary fit result.
    fixed = fit_multivariate_reml(Y, d.X, d.Z, pedigree_inverse(d.ped);
        genetic_structure=:factor_analytic, rank=1, iterations=2, ids=d.ids)
    @test !hasproperty(fixed, :selection_status)
    @test fixed.genetic_rank == 1
end

@testset "automatic FA refuses non-PD covariance receipts and sole survivor" begin
    d = _auto_fa_fixture()
    c = HSquared.FA_UNIQUENESS_FLOOR
    semidefinite_r = function (objective, params0, iterations, rank, start_id)
        p = copy(params0)
        if rank == 0
            # Finite Cholesky log-diagonals whose squared scale underflows to
            # zero, producing a finite but semidefinite R estimate.
            for j in (5, 9, 12, 14)
                p[j] = -600log(2.0)
            end
            return (; phat=p, objective=0.0, converged=true,
                iterations=1, optimizer_status="semidefinite residual control")
        end
        return (; phat=p, objective=objective(p), converged=true,
                iterations=1, optimizer_status="semidefinite residual control")
    end
    rbad = HSquared._select_fa_rank(d.Y, d.X, d.Z, d.ped;
        ids=d.ids, attempt_runner=semidefinite_r)
    @test rbad.selection_status == :unavailable
    badr = filter(a -> a.rank == 0, rbad.attempts)
    @test !isempty(badr)
    @test all(a -> a.status == :failed && a.pd_residual === false &&
        a.finite_objective === true &&
        occursin("non-positive-definite covariance estimate", a.reason) &&
        a.loglik === nothing && a.criterion === nothing, badr)
    @test rbad.candidate_summary[1].reason !== nothing
    @test rbad.candidate_summary[1].loglik === nothing

    # Exact powers of two keep the huge loading finite while making the
    # uniqueness eigen-direction numerically disappear in LL' + diag(psi).
    huge_loading = function (objective, params0, iterations, rank, start_id)
        p = copy(params0)
        if rank == 1
            p[1:4] .= 2.0^500
            return (; phat=p, objective=0.0, converged=true,
                    iterations=1, optimizer_status="finite objective ill-conditioned G control")
        end
        return (; phat=p, objective=objective(p), converged=true,
                iterations=1, optimizer_status="finite ill-conditioned G control")
    end
    gbig = HSquared._select_fa_rank(d.Y, d.X, d.Z, d.ped;
        ids=d.ids, attempt_runner=huge_loading)
    badg = filter(a -> a.rank == 1, gbig.attempts)
    @test !isempty(badg)
    @test all(a -> a.status == :failed && a.finite_estimates &&
        a.finite_objective === true && all(isfinite, a.genetic_covariance) &&
        a.pd_genetic === false &&
        occursin("non-positive-definite covariance estimate", a.reason) &&
        a.loglik === nothing && a.criterion === nothing, badg)
    @test !gbig.candidate_summary[2].eligible
    @test gbig.candidate_summary[2].reason !== nothing

    # A sole eligible K0 candidate is not a permitted automatic winner.
    sole = HSquared._select_fa_rank(d.Y, d.X, d.Z, d.ped; ids=d.ids,
        attempt_runner=function (objective, params0, iterations, rank, start_id)
            rank == 1 && error("sole-survivor FA failure")
            p = copy(params0)
            (; phat=p, objective=objective(p), converged=true,
               iterations=1, optimizer_status="sole survivor control")
        end)
    @test sole.selection_status == :unavailable
    @test sole.selected_rank === nothing
    @test length(sole.candidate_summary) == 2
    @test sole.candidate_summary[1].eligible && !sole.candidate_summary[2].eligible
    @test sole.candidate_summary[1].reason === nothing
    @test sole.candidate_summary[2].reason !== nothing
    @test all(a -> a.rank == 1 ? a.status == :failed && a.reason !== nothing :
              a.status == :completed, sole.attempts)

    # At the exact floor, the diagonal-derived FA initializer would have
    # zero loading and is refused before an optimizer attempt is created.
    fake = (; genetic_covariance=Diagonal(fill(c, 4)),
            residual_covariance=Matrix{Float64}(I, 4, 4))
    @test_throws ArgumentError HSquared._fa_rank_retry_params(fake)
end

@testset "automatic FA near-floor flags and persistent non-nesting refusal" begin
    d = _auto_fa_fixture()
    c = HSquared.FA_UNIQUENESS_FLOOR
    delta = 5e-7
    rparams = HSquared._cov_to_chol_params(d.R, 4)
    p0 = vcat(log.(fill(delta, 4)), rparams)
    p1 = vcat(zeros(4), log.(fill(delta, 4)), rparams)
    near_floor_runner = function (objective, params0, iterations, rank, start_id)
        p = rank == 0 ? copy(p0) : copy(p1)
        return (; phat=p, objective=objective(p), converged=true, iterations=1,
                optimizer_status="eligible near-floor witness")
    end
    near = HSquared._select_fa_rank(d.Y, d.X, d.Z, d.ped; ids=d.ids,
        attempt_runner=near_floor_runner)
    @test near.selection_status == :selected
    @test near.selected_rank == 0
    @test near.boundary_sensitive
    @test near.candidate_summary[1].near_floor === true
    @test near.candidate_summary[2].near_floor === true
    @test near.candidate_summary[1].minimum_floor_distance ≈ delta atol = 1e-12
    @test near.candidate_summary[2].minimum_floor_distance ≈ delta atol = 1e-12
    @test all(a -> a.near_floor === true && a.status == :completed, near.attempts)
    @test all(a -> all(x -> 0 < x <= 1e-6, a.floor_distances), near.attempts)

    # Reuse the finite better-unconverged construction with a deliberately bad
    # but valid retry receipt. The selector must measure the L=0 witness and
    # refuse persistent K1 non-nesting after spending its sole retry.
    calls = Tuple{Int,Symbol}[]
    diagonal_objective = Ref(NaN)
    best_fa_params = function (objective, start)
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
        scores = [objective(p) for p in candidates]
        valid = findall(isfinite, scores)
        i = valid[argmin(scores[valid])]
        return candidates[i], scores[i]
    end
    nonnested_runner = function (objective, params0, iterations, rank, start_id)
        push!(calls, (rank, start_id))
        if rank == 0
            p = copy(params0)
            p[1:4] .-= 2.0
            p[5:end] .+= 1.5
            value = objective(p)
            diagonal_objective[] = value
            return (; phat=p, objective=value, converged=true,
                    iterations=1, optimizer_status="weak diagonal for non-nesting control")
        elseif rank == 1 && start_id in (:default, :balanced)
            p, value = best_fa_params(objective, params0)
            value < diagonal_objective[] - 1e-3 ||
                error("failed to create a better unconverged FA control")
            return (; phat=p, objective=value, converged=false, iterations=1,
                    optimizer_status="better but unconverged non-nesting control")
        end
        p = copy(params0)
        # Inflate each residual Cholesky diagonal: valid R, deliberately worse
        # likelihood than the matched diagonal fit, while retaining nonzero L.
        for j in (9, 13, 16, 18)
            p[j] += 3.0
        end
        return (; phat=p, objective=objective(p), converged=true, iterations=1,
                optimizer_status="persistent non-nesting retry control")
    end
    nonnested = HSquared._select_fa_rank(d.Y, d.X, d.Z, d.ped; ids=d.ids,
        attempt_runner=nonnested_runner)
    @test count(==((1, :diagonal_retry)), calls) == 1
    @test length(nonnested.attempts) <= 4
    @test nonnested.nesting_witness_discrepancy !== nothing
    @test nonnested.nesting_witness_discrepancy <= 1e-8
    @test nonnested.selection_status == :unavailable
    @test nonnested.selected_rank === nothing
    @test occursin("FA likelihood remains non-nested below the diagonal fit", nonnested.reason)
    @test nonnested.candidate_summary[1].eligible && nonnested.candidate_summary[2].eligible
    retry = only(filter(a -> a.rank == 1 && a.start_id == :diagonal_retry,
        nonnested.attempts))
    diagonal = only(filter(a -> a.rank == 0, nonnested.attempts))
    better_unconverged = filter(a -> a.rank == 1 && a.status == :completed &&
        a.converged === false, nonnested.attempts)
    @test !isempty(better_unconverged)
    @test all(a -> a.loglik !== nothing && isfinite(a.loglik) &&
        a.loglik > nonnested.candidate_summary[1].loglik + 1e-3,
        better_unconverged)
    @test retry.loglik < diagonal.loglik - 1e-6
    @test all(a -> a.status !== :unattempted, nonnested.attempts)
end

@testset "automatic FA bounded retry and interrupt ledger" begin
    d = _auto_fa_fixture()
    calls = Tuple{Int,Symbol}[]
    runner = function (objective, params0, iterations, rank, start_id)
        push!(calls, (rank, start_id))
        if rank == 1 && start_id == :default
            p = copy(params0); p[1:4] .= 0.0; p[5:8] .-= 2.0
            return (; phat=p, objective=objective(p), converged=true,
                    iterations=1, optimizer_status="injected")
        end
        p = copy(params0)
        return (; phat=p, objective=objective(p), converged=true,
                iterations=1, optimizer_status="injected")
    end
    retried = HSquared._select_fa_rank(d.Y, d.X, d.Z, d.ped;
        ids=d.ids, attempt_runner=runner)
    @test count(x -> x == (1, :diagonal_retry), calls) == 1
    @test length(retried.attempts) <= 4
    @test length(retried.candidate_summary) == 2
    retry_row = only(filter(a -> a.rank == 1 && a.start_id == :diagonal_retry,
        retried.attempts))
    @test all(!iszero, retry_row.initial_parameters[1:4])
    @test all(isfinite, retry_row.initial_parameters[1:4])

    ledger = Ref{Any}(nothing)
    interrupting = (objective, params0, iterations, rank, start_id) ->
        throw(InterruptException())
    @test_throws InterruptException HSquared._select_fa_rank(
        d.Y, d.X, d.Z, d.ped; ids=d.ids, ledger_sink=ledger,
        attempt_runner=interrupting)
    @test ledger[] !== nothing
    @test length(ledger[].attempts) == 1
    @test ledger[].attempts[1].status == :interrupted
    @test ledger[].selection_status == :interrupted

    call_number = Ref(0)
    between = function (objective, params0, iterations, rank, start_id)
        call_number[] += 1
        call_number[] == 2 && throw(InterruptException())
        p = copy(params0)
        return (; phat=p, objective=objective(p), converged=true,
                iterations=1, optimizer_status="injected")
    end
    @test_throws InterruptException HSquared._select_fa_rank(
        d.Y, d.X, d.Z, d.ped; ids=d.ids, ledger_sink=ledger,
        attempt_runner=between)
    @test length(ledger[].attempts) == 2
    @test ledger[].attempts[1].status != :interrupted
    @test ledger[].attempts[2].status == :interrupted

    between_candidates = Ref{Any}(nothing)
    @test_throws InterruptException HSquared._select_fa_rank(
        d.Y, d.X, d.Z, d.ped; ids=d.ids, ledger_sink=between_candidates,
        checkpoint=() -> throw(InterruptException()),
        attempt_runner=(objective, params0, iterations, rank, start_id) -> begin
            p = copy(params0)
            (; phat=p, objective=objective(p), converged=true,
               iterations=1, optimizer_status="injected")
        end)
    @test between_candidates[].selection_status == :interrupted
    @test length(between_candidates[].attempts) == 1
    @test between_candidates[].candidate_summary[1].status == :completed
    @test between_candidates[].candidate_summary[2].status == :unattempted
end

@testset "automatic FA better-unconverged retry trigger and bounded refusal" begin
    d = _auto_fa_fixture()
    calls = Tuple{Int,Symbol}[]
    diagonal_G = Ref{Any}(nothing)
    diagonal_R = Ref{Any}(nothing)
    diagonal_objective = Ref(NaN)
    best_fa_params = function (objective, start)
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
        scores = [objective(p) for p in candidates]
        eligible = findall(i -> isfinite(scores[i]), eachindex(scores))
        isempty(eligible) && error("test could not construct a finite FA receipt")
        i = eligible[argmin(scores[eligible])]
        return candidates[i], scores[i]
    end
    runner = function (objective, params0, iterations, rank, start_id)
        push!(calls, (rank, start_id))
        if rank == 0
            # Make the sole eligible K0 receipt deliberately poor. The FA
            # starts and retry still use the same observed data.
            p = copy(params0)
            p[1:4] .-= 2.0
            p[5:end] .+= 1.5
            diagonal_G[] = HSquared._fa_rank_cov(p[1:4], 0)[1]
            diagonal_R[] = HSquared._chol_params_to_cov(p[5:end], 4)
            value = objective(p)
            diagonal_objective[] = value
            return (; phat=p, objective=value, converged=true,
                    iterations=1, optimizer_status="injected weak diagonal")
        elseif rank == 1 && start_id == :default
            p, value = best_fa_params(objective, params0)
            value < diagonal_objective[] - 1e-3 ||
                error("test failed to make the unconverged FA receipt better than K0")
            return (; phat=p, objective=value, converged=false,
                    iterations=1, optimizer_status="injected better unconverged")
        elseif rank == 1 && start_id == :balanced
            g = diag(diagonal_G[])
            c = HSquared.FA_UNIQUENESS_FLOOR
            loading = [0.1 * (-1.0)^(i - 1) * sqrt(g[i] - c) for i in 1:4]
            psi = g .- loading.^2
            p = vcat(loading, log.(psi .- c),
                     HSquared._cov_to_chol_params(diagonal_R[], 4))
            return (; phat=p, objective=objective(p), converged=true,
                    iterations=1, optimizer_status="injected nested diagonal")
        end
        p = copy(params0)
        return (; phat=p, objective=objective(p), converged=true,
                iterations=1, optimizer_status="injected diagonal retry")
    end
    result = HSquared._select_fa_rank(d.Y, d.X, d.Z, d.ped;
        ids=d.ids, attempt_runner=runner)
    @test count(x -> x == (1, :diagonal_retry), calls) == 1
    @test length(result.attempts) == 4
    @test result.selection_status == :unavailable
    @test occursin("better finite unconverged FA attempt", result.reason)
    @test result.start_sensitive
    better_unconverged = filter(a -> a.rank == 1 && a.status == :completed &&
        a.converged === false, result.attempts)
    @test !isempty(better_unconverged)
    @test all(a -> a.loglik !== nothing && isfinite(a.loglik) &&
        a.loglik > result.candidate_summary[1].loglik + 1e-3,
        better_unconverged)
end

@testset "automatic FA interruption at each initial and retry start" begin
    d = _auto_fa_fixture()
    targets = ((0, :default), (1, :default), (1, :balanced), (1, :diagonal_retry))
    for target in targets
        ledger = Ref{Any}(nothing)
        runner = function (objective, params0, iterations, rank, start_id)
            (rank, start_id) == target && throw(InterruptException())
            p = copy(params0)
            if rank == 1 && start_id != :diagonal_retry
                p[1:4] .= 0.0
                p[5:8] .-= 2.0
            elseif rank == 1 && start_id == :diagonal_retry
                # Reaching this target means both initial FA starts completed
                # and the contract's single retry was authorized.
                p[1:4] .= 0.0
                p[5:8] .-= 2.0
            end
            return (; phat=p, objective=objective(p), converged=true,
                    iterations=1, optimizer_status="injected interruption witness")
        end
        @test_throws InterruptException HSquared._select_fa_rank(
            d.Y, d.X, d.Z, d.ped; ids=d.ids, ledger_sink=ledger,
            attempt_runner=runner)
        @test ledger[] !== nothing
        @test ledger[].selection_status == :interrupted
        @test !isempty(ledger[].attempts)
        @test ledger[].attempts[end].status == :interrupted
        @test (ledger[].attempts[end].rank, ledger[].attempts[end].start_id) == target
        @test all(a -> a.attempted, ledger[].attempts)
    end
end

@testset "automatic FA rejects forbidden data and confounded pedigree designs" begin
    d = _auto_fa_fixture()
    unsupported = select_fa_rank(d.Y, hcat(d.X, collect(1.0:size(d.Y, 1))), d.Z, d.ped;
        ids=d.ids)
    @test unsupported.selection_status == :unsupported_input
    @test isempty(unsupported.attempts)
    @test all(row.status == :unattempted for row in unsupported.candidate_summary)

    missing = copy(d.Y); missing[1, 2] = NaN
    bad_cases = (
        (missing, d.X, d.Z, d.ped, d.ids, ["a", "b", "c", "d"]),
        (d.Y, d.X, d.Z, d.ped, reverse(d.ids), ["a", "b", "c", "d"]),
        (d.Y, d.X, d.Z, d.ped, d.ids, ["a", "a", "c", "d"]),
        (d.Y, d.X, vcat(2 .* d.Z[1:1, :], d.Z[2:end, :]), d.ped, d.ids,
            ["a", "b", "c", "d"]),
    )
    for (Y, X, Z, ped, ids, traits) in bad_cases
        refused = select_fa_rank(Y, X, Z, ped; ids=ids, traits=traits)
        @test refused.selection_status == :unsupported_input
        @test isempty(refused.attempts)
        @test all(row.status == :unattempted for row in refused.candidate_summary)
    end
    too_few = select_fa_rank(d.Y[1:2, :], d.X[1:2, :], d.Z[1:2, :], d.ped;
        ids=d.ids)
    @test too_few.selection_status == :unsupported_input
    @test isempty(too_few.attempts)

    unrelated = normalize_pedigree(collect(1:12), zeros(Int, 12), zeros(Int, 12))
    identity = select_fa_rank(d.Y, d.X, d.Z, unrelated; ids=unrelated.ids)
    @test identity.selection_status == :unsupported_input
    @test isempty(identity.attempts)
    @test occursin("unresolved on REML contrasts", identity.reason)

    pid = ["s1", "d1", "d2", "d3", "d4", "o1", "o2", "o3", "o4"]
    psire = ["0", "0", "0", "0", "0", "s1", "s1", "s1", "s1"]
    pdam = ["0", "0", "0", "0", "0", "d1", "d2", "d3", "d4"]
    halfped = normalize_pedigree(pid, psire, pdam)
    Zhalf = zeros(4, length(halfped))
    for i in 1:4
        Zhalf[i, 5 + i] = 1.0
    end
    half = select_fa_rank(reshape(collect(1.0:16.0), 4, 4), ones(4, 1), Zhalf,
        halfped; ids=halfped.ids)
    @test half.selection_status == :unsupported_input
    @test isempty(half.attempts)
    @test occursin("unresolved on REML contrasts", half.reason)
end

@testset "automatic FA selector public shape and refusal contract" begin
    d = _auto_fa_fixture()
    @test isdefined(HSquared, :select_fa_rank)
    if isdefined(HSquared, :select_fa_rank)
        refused = select_fa_rank(d.Y[:, 1:3], d.X, d.Z, d.ped; ids=d.ids)
        @test refused.selection_status == :unsupported_input
        @test refused.selected_rank === nothing
        @test isempty(refused.attempts)
        @test length(refused.candidate_summary) == 2
        @test all(!row.eligible for row in refused.candidate_summary)

        repeated_Z = vcat(d.Z[1:5, :], d.Z[1:5, :])
        repeated_Y = vcat(d.Y[1:5, :], d.Y[1:5, :])
        repeated = select_fa_rank(repeated_Y, ones(10, 1), repeated_Z, d.ped;
            ids=vcat(d.ids[1:5], d.ids[1:5]))
        @test repeated.selection_status == :unsupported_input
        @test isempty(repeated.attempts)
    end
end
