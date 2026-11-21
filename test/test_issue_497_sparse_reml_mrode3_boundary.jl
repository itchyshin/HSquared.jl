# HSquared.jl #497 — fit_sparse_reml (and fit_variance_components) must certify
# the residual-boundary optimum on the #412 Mrode 3 data instead of running to
# the iteration cap with converged = false.
# Standalone:
# julia --project=. -e 'include("test/test_issue_497_sparse_reml_mrode3_boundary.jl")'

using HSquared
using SparseArrays
using Test

@testset "#497 Mrode 3 residual-boundary fit converges" begin
    ids = string.(1:8)
    ped = normalize_pedigree(
        ids,
        ["0", "0", "0", "1", "3", "1", "4", "3"],
        ["0", "0", "0", "0", "2", "2", "5", "6"],
    )
    idx = Dict(k => i for (i, k) in enumerate(ped.ids))
    y = [4.5, 2.9, 3.9, 3.5, 5.0]
    X = hcat(ones(5), [1.0, 0.0, 0.0, 1.0, 1.0])
    Z = sparse(1:5, [idx[a] for a in string.(4:8)], 1.0, 5, 8)
    spec = animal_model_spec(y, X, Z, pedigree_inverse(ped); ids = ped.ids, method = :REML)

    for fit in (fit_sparse_reml(spec), fit_variance_components(spec))
        vc = fit.variance_components
        @test fit.converged
        @test fit.optimizer_status == "converged"
        @test vc.sigma_e2 / (vc.sigma_a2 + vc.sigma_e2) <= 1e-6
    end
    sparse_fit = fit_sparse_reml(spec)
    @test isapprox(sparse_fit.variance_components.sigma_a2, 0.6765; atol = 1e-3)
    @test isapprox(sparse_fit.likelihood.loglik, -3.9153; atol = 1e-3)

    # The boundary check must not certify a false boundary: with the iteration
    # cap far too small the run is still reported as not converged.
    @test !fit_sparse_reml(spec; iterations = 5).converged
end
