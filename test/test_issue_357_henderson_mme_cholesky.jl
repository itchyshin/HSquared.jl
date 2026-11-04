using HSquared
using LinearAlgebra
using SparseArrays
using Test

@testset "issue 357 henderson_mme uses Cholesky on the SPD MME" begin
    ids = ["founder_a", "founder_b", "animal_1", "animal_2", "animal_3"]
    ped = normalize_pedigree(
        ids,
        ["0", "0", "founder_a", "founder_a", "animal_1"],
        ["0", "0", "founder_b", "founder_b", "animal_2"],
    )
    Ainv = pedigree_inverse(ped)
    y = [3.2, 4.1, 5.4, 5.9]
    X = [
        1.0 0.0
        1.0 1.0
        1.0 0.0
        1.0 1.0
    ]
    Z = sparse([1, 2, 3, 4], [3, 4, 5, 5], ones(4), 4, 5)
    sigma_a2 = 1.2
    sigma_e2 = 0.8
    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :ML)
    lhs, rhs, _ = HSquared._sparse_mme_system(spec, sigma_a2, sigma_e2)
    chol_sol = cholesky(Symmetric(lhs); check = true) \ rhs
    lu_sol = lhs \ rhs
    mme = henderson_mme(spec, sigma_a2, sigma_e2)
    nfixed = size(spec.X, 2)

    @test fixed_effects(mme) ≈ chol_sol[1:nfixed] atol = 0
    @test breeding_values(mme).values ≈ chol_sol[(nfixed + 1):end] atol = 0
    @test chol_sol ≈ lu_sol atol = 0
    @test fixed_effects(mme) ≈ [3.898701298701298, 0.6454545454545471]
    @test breeding_values(mme).values ≈ [
        0.0,
        0.0,
        -0.054545454545454695,
        0.05454545454545385,
        0.8571428571428561,
    ]
end
