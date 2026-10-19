# HSquared.jl #416 — fit-free rank pre-check: warn when the requested variance
# components are not all separable (animal + dam, one sire per dam).
# Standalone:
# julia --project=. -e 'include("test/test_issue_416_weak_identifiability_warning.jl")'

using HSquared
using LinearAlgebra
using SparseArrays
using Test

@testset "issue 416 weak-identifiability pre-check" begin
    # 12 dams, each mated to its own unrelated sire, 4 phenotyped offspring each.
    nd, nk = 12, 4
    sires = ["s$i" for i in 1:nd]
    dams = ["d$i" for i in 1:nd]
    kids = ["k$(i)_$(j)" for i in 1:nd for j in 1:nk]
    ids = vcat(sires, dams, kids)
    sire_of = vcat(fill("0", 2nd), [sires[i] for i in 1:nd for j in 1:nk])
    dam_of = vcat(fill("0", 2nd), [dams[i] for i in 1:nd for j in 1:nk])
    ped = normalize_pedigree(ids, sire_of, dam_of)
    Ainv = pedigree_inverse(ped)
    idx = Dict(k => i for (i, k) in enumerate(ped.ids))
    n = length(kids)
    Z = sparse(1:n, [idx[k] for k in kids], 1.0, n, length(ped.ids))
    X = ones(n, 1)
    damgrp = repeat(1:nd, inner = nk)
    Zd = sparse(1:n, damgrp, 1.0, n, nd)
    Id = sparse(1.0I, nd, nd)
    y = [0.3 * sin(3.1i) + 0.5 * cos(1.7 * damgrp[i]) + 0.2 * sin(0.37i^2) for i in 1:n]

    help = read(joinpath(@__DIR__, "..", "src", "likelihood.jl"), String)
    @test occursin("_warn_weak_identifiability", help)

    # red on main: animal + dam-group, rank 2 for 3 components
    @test HSquared._weak_identifiability_rank(
        (Matrix(Z), Matrix(Zd)), (inv(Matrix(Ainv)), Matrix(1.0I, nd, nd)), n) == 2
    fit = nothing
    @test_logs (:warn, r"identif") min_level = Base.CoreLogging.Warn begin
        fit = fit_two_effect_reml(y, X, Z, Ainv, Zd, Id; iterations = 20, ids1 = ped.ids)
    end
    @test fit.converged isa Bool
    @test hasproperty(fit, :ratio1)

    # multi-effect path
    @test_logs (:warn, r"identif") min_level = Base.CoreLogging.Warn begin
        fit_multi_effect_reml(y, X, [(Z, Ainv), (Zd, Id)]; iterations = 20)
    end

    # control: animal + nest where nests cross-foster the offspring
    nest = [mod(j + 3i, 8) + 1 for i in 1:nd for j in 1:nk]
    Zn = sparse(1:n, nest, 1.0, n, 8)
    @test_logs min_level = Base.CoreLogging.Warn begin
        fit_two_effect_reml(y, X, Z, Ainv, Zn, sparse(1.0I, 8, 8); iterations = 20, ids1 = ped.ids)
    end

    # control: single-effect fit
    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
    @test_logs min_level = Base.CoreLogging.Warn begin
        fit_ai_reml(spec; iterations = 5)
    end

    # size cap: skipped (no rank, no warning) beyond the cell cap
    @test HSquared._weak_identifiability_rank((Z,), (Matrix(1.0I, size(Z, 2), size(Z, 2)),), 6000) === nothing
end
