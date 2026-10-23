using Test, LinearAlgebra, HSquared
const H = HSquared

# Successful guard visits stop the supplied-loading kernel before mode work.
struct DescriptorRecordGuardPassed <: Exception end
function H._check_flat_effect_integral(f::H.ResponseFamily,
                                     y::AbstractVector{Float64}, X::AbstractMatrix{Float64})
    invoke(H._check_flat_effect_integral, Tuple{H.ResponseFamily, Any, Any}, f, y, X)
    throw(DescriptorRecordGuardPassed())
end
const probe_method = which(H._check_flat_effect_integral,
    Tuple{H.ResponseFamily, AbstractVector{Float64}, AbstractMatrix{Float64}})
function rejection_message(f)
    try
        f()
    catch e
        return e isa ArgumentError && occursin("per-record binomial", sprint(showerror, e))
    end
    return false
end
@testset "GLLVM descriptor and record guards" begin
try
@testset "GLLVM record family boundary" begin
    Ai = Matrix{Float64}(I, 2, 2)
    Y = reshape([0.0, 1.0], 2, 1)
    X = zeros(2, 0)
    bvr = H.BinomialVectorResponse([2, 3])
    for family in (bvr, [bvr], H.ResponseFamily[bvr])
        @test rejection_message(() -> H.gllvm_laplace_marginal_loglik(
            Y, Ai, ones(1, 1), family; X=X, maxiter=0))
    end
    @test rejection_message(() -> H.gllvm_laplace_marginal_loglik(
        hcat([1.0, 2.0], vec(Y)), Ai, ones(2, 1),
        [H.GaussianResponse(1.0), bvr]; X=X, maxiter=0))
    for family in (H.BinomialResponse(3), [H.BinomialResponse(3)], H.PoissonResponse())
        @test_throws DescriptorRecordGuardPassed H.gllvm_laplace_marginal_loglik(
            Y, Ai, ones(1, 1), family; X=X, maxiter=0)
    end
    @test_throws DescriptorRecordGuardPassed H.gllvm_laplace_marginal_loglik(
        [1.0 2.0 1.0; 2.0 1.0 3.0], Ai, [1.0 0.2; 0.4 0.9; 0.3 0.5],
        H.PoissonResponse(); X=X, maxiter=0)
end
finally
    Base.delete_method(probe_method)
end
@test which(H._check_flat_effect_integral,
    Tuple{H.ResponseFamily, Vector{Float64}, Matrix{Float64}}) ===
    which(H._check_flat_effect_integral, Tuple{H.ResponseFamily, Any, Any})

@testset "GLLVM synthetic descriptor metadata" begin
    L = [1.0 0.2; 0.4 0.9; 0.3 0.5]
    psi = [0.3, 0.4, 0.6]
    G = L * L' + Diagonal(psi)
    function result(; covariance=G, loadings=L, uniqueness=psi, rank=2, structure=:factor_analytic)
        return (genetic_covariance=covariance, residual_covariance=Matrix{Float64}(I, 3, 3),
            beta=zeros(1, 3), breeding_values=(ids=[1], traits=["a", "b", "c"], values=zeros(1, 3)),
            genetic_structure=structure, genetic_rank=rank,
            genetic_loadings=loadings, genetic_uniqueness=uniqueness)
    end
    for bad in ([0.2], [0.2, 0.3], [0.2, 0.3, 0.4, 0.5],
                [NaN, 0.3, 0.4], [Inf, 0.3, 0.4], [-0.1, 0.3, 0.4],
                diag(G) .+ 1.0)
        @test_throws ArgumentError H.genetic_gllvm_descriptors(result(uniqueness=bad))
    end
    for bad in (0, -1, 1.5, 4, nothing, true)
        @test_throws ArgumentError H.genetic_gllvm_descriptors(result(rank=bad))
    end
    for bad in (ones(2, 2), ones(3, 1), fill(NaN, 3, 2), fill(Inf, 3, 2))
        @test_throws ArgumentError H.genetic_gllvm_descriptors(result(loadings=bad))
    end
    @test_throws ArgumentError H.genetic_gllvm_descriptors(result(uniqueness=nothing))
    @test_throws ArgumentError H.genetic_gllvm_descriptors(result(structure=:lowrank))
    fa = H.genetic_gllvm_descriptors(result())
    @test fa.communality ≈ vec(sum(abs2, L; dims=2)) ./ diag(G)
    @test fa.rank == 2
    theta = 0.7
    Q = [cos(theta) -sin(theta); sin(theta) cos(theta)]
    rotated = H.genetic_gllvm_descriptors(result(loadings=L*Q))
    @test rotated.genetic_covariance ≈ fa.genetic_covariance
    @test rotated.communality ≈ fa.communality
    pure = result(covariance=L*L', uniqueness=nothing, structure=:lowrank)
    @test H.genetic_gllvm_descriptors(pure).communality == ones(3)
    @test H.genetic_gllvm_descriptors(merge(pure, (genetic_uniqueness=zeros(3),))).communality == ones(3)
    @test H.genetic_gllvm_descriptors(result(uniqueness=zeros(3))).communality == ones(3)
    @test H.genetic_gllvm_descriptors(result(loadings=nothing)).communality ≈ fa.communality
    @test H.genetic_gllvm_descriptors(result(uniqueness=diag(G))).communality == zeros(3)
    @test_throws ArgumentError H.genetic_gllvm_descriptors(fill(NaN, 3, 2))
    @test_throws ArgumentError H.genetic_gllvm_descriptors(L; uniqueness=[0.2, 0.3])
    @test_throws ArgumentError H.genetic_gllvm_descriptors(L; uniqueness=zeros(3))
end

@testset "GLLVM fitter entry and retained descriptor controls" begin
    Ai = Matrix{Float64}(I, 2, 2)
    bvr = H.BinomialVectorResponse([2, 3])
    for family in (bvr, [bvr], H.ResponseFamily[bvr])
        @test rejection_message(() -> H.fit_gllvm_laplace_reml(
            reshape([0.0, 1.0], 2, 1), Ai, family; rank=0))
    end
    @test rejection_message(() -> H.fit_gllvm_laplace_reml(
        [1.0 0.0; 2.0 1.0], Ai, [H.GaussianResponse(1.0), bvr]; rank=0))
    # Standalone varying-trial count validation and scalar record mapping stay available.
    @test H._check_counts(bvr, [0.0, 1.0]) === nothing
    @test H._fam_record(bvr, 2).n_trials == 3
    L = [1.0 0.2; 0.4 0.9; 0.3 0.5]
    pure = H.genetic_gllvm_descriptors(L)
    @test pure.communality ≈ ones(3)
    @test pure.rank == 2
    @test H.genetic_gllvm_descriptors([L ones(3)]).rank == 3
    @test H.genetic_gllvm_descriptors([L ones(3) ones(3)]).rank == 4
end
end
