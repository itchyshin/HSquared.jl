# HJ1 — iterative_solve.jl MC-REML status helpers and ichol breakdown path.

using HSquared
using LinearAlgebra
using SparseArrays
using Test

@testset "iterative solve MC status helpers (HJ1)" begin
    @test !HSquared._mc_reml_relative_change_converged(0.01, [0.1], 1e-2)
    @test HSquared._mc_reml_relative_change_converged(0.001, [0.1, 0.2], 1e-2)
    @test !HSquared._mc_reml_relative_change_converged(0.001, [NaN], 1e-2)
    @test HSquared._mc_reml_optimizer_status(true) == "fixed_point_relchange"
    @test HSquared._mc_reml_optimizer_status(false) == "not_converged"

    ped = normalize_pedigree(["a", "b"], ["0", "0"], ["0", "0"])
    n = 2
    y = [1.1, 2.2]
    X = ones(n, 1)
    Z = sparse(1.0I, n, n)
    Ainv = sparse(Matrix(pedigree_inverse(ped)))
    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids)
    lhs, rhs, _ = HSquared._sparse_mme_system(spec, 1.0, 1.0)
    L = HSquared._ichol0_factor(sparse(lhs))
    @test L isa SparseMatrixCSC
    ic = solve_animal_model_pcg(spec, 1.0, 1.0; preconditioner = :ichol, tol = 1e-12)
    direct = henderson_mme(spec, 1.0, 1.0)
    @test ic.beta ≈ fixed_effects(direct)
    @test ic.breeding_values.values ≈ breeding_values(direct).values atol = 1e-9
end
