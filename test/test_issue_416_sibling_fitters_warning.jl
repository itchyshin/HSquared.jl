# HSquared.jl #416 — the fit-free rank pre-check, extended to the sibling fitters
# that PR #452 left out: sparse AI-REML, matrix-free MC-REML, repeatability
# (animal + permanent environment) and direct–maternal.
# Standalone:
# julia --project=. -e 'include("test/test_issue_416_sibling_fitters_warning.jl")'

using HSquared
using LinearAlgebra
using SparseArrays
using Test
using Logging

@testset "numerical rank is invariant to nonzero component scaling" begin
    d1 = Matrix(Diagonal([1.0, 2.0, 3.0, 4.0]))
    d2 = Matrix(Diagonal([1.0, 0.0, 0.0, 0.0]))
    for scale in (-1e12, -1.0, -1e-12, 1e-12, 1.0, 1e12)
        @test HSquared._weak_identifiability_stacked_rank([() -> scale .* d1, () -> d2], 4) == 3
    end

    # Missing components remain zero; two zero components and I have rank one.
    zero_cov = zeros(4, 4)
    @test HSquared._weak_identifiability_stacked_rank([() -> zero_cov, () -> d2], 4) == 2
    @test HSquared._weak_identifiability_stacked_rank([() -> zero_cov, () -> zero_cov], 4) == 1

    # The unchanged tolerance is relative to normalized column directions.
    for (delta, expected) in ((1e-10, 2), (1e-5, 3))
        almost = Matrix(Diagonal([1.0, delta, 0.0, 0.0]))
        @test HSquared._weak_identifiability_stacked_rank([() -> d2, () -> almost], 4) == expected
    end
    for bad in (NaN, Inf, -Inf)
        invalid = copy(d2)
        invalid[1, 1] = bad
        @test HSquared._weak_identifiability_stacked_rank([() -> invalid], 4) === nothing
    end

    # Normalization must not overflow for finite large columns or underflow
    # for a nonzero subnormal column.
    big = Matrix(Diagonal([1e308, 1e308, 0.0, 0.0]))
    tiny = Matrix(Diagonal([0.0, 0.0, nextfloat(0.0), 0.0]))
    @test HSquared._weak_identifiability_stacked_rank([() -> big, () -> tiny], 4) == 3
end

@testset "rank warning does not invent a confounded component" begin
    # Unrelated animals with two records each: animal and PE have equal
    # covariance, while PE and residual are distinguishable.
    Z = sparse([1, 2, 3, 4], [1, 1, 2, 2], ones(4), 4, 2)
    A = Matrix{Float64}(I, 2, 2)
    pe = Matrix(Z * transpose(Z))
    @test HSquared._weak_identifiability_stacked_rank([() -> pe, () -> pe], 4) == 2
    @test rank(hcat(vec(pe), vec(Matrix{Float64}(I, 4, 4)))) == 2
    # Generic multi-effect warnings must not identify V_A as the cause.
    io = IOBuffer()
    with_logger(SimpleLogger(io, Logging.Warn)) do
        HSquared._warn_weak_identifiability_rank(2, 3, ("effect 1", "effect 2"))
    end
    warning = String(take!(io))
    @test occursin("numerical rank", warning)
    @test occursin("Rank is numerical and tolerance-dependent", warning)
    @test occursin("does not prove structural non-identifiability", warning)
    @test !occursin("V_A cannot be separated", warning)
    @test !occursin("Cross-fostering or repeated records are needed", warning)
    @test !occursin("REML is flat along a ridge", warning)

    io = IOBuffer()
    with_logger(SimpleLogger(io, Logging.Warn)) do
        HSquared._warn_weak_identifiability_repeatability(Matrix(Z), A, 4)
    end
    warning = String(take!(io))
    @test occursin("numerical rank", warning)
    @test occursin("Rank is numerical and tolerance-dependent", warning)
    @test !occursin("V_pe cannot be separated from V_e", warning)
    @test !occursin("Repeated records per animal are needed", warning)
    @test !occursin("REML is flat along a ridge", warning)
end

@testset "issue 416 weak-identifiability pre-check: sibling fitters" begin
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
    q = length(ped.ids)
    n = length(kids)
    Z = sparse(1:n, [idx[k] for k in kids], 1.0, n, q)
    X = ones(n, 1)
    damgrp = repeat(1:nd, inner = nk)
    Zd = sparse(1:n, damgrp, 1.0, n, nd)
    Id = sparse(1.0I, nd, nd)
    y = [0.3 * sin(3.1i) + 0.5 * cos(1.7 * damgrp[i]) + 0.2 * sin(0.37i^2) for i in 1:n]
    nest = [mod(j + 3i, 8) + 1 for i in 1:nd for j in 1:nk]
    Zn = sparse(1:n, nest, 1.0, n, 8)
    In = sparse(1.0I, 8, 8)
    W = Base.CoreLogging.Warn

    @testset "sparse AI-REML (animal + dam)" begin
        fit = nothing
        @test_logs (:warn, r"identif") min_level = W begin
            fit = fit_sparse_multi_effect_aireml(y, X, [(Z, Ainv), (Zd, Id)]; iterations = 5)
        end
        @test fit.converged isa Bool
        # control: cross-fostered nest separates the components
        @test_logs min_level = W fit_sparse_multi_effect_aireml(y, X, [(Z, Ainv), (Zn, In)]; iterations = 5)
    end

    @testset "matrix-free MC-REML (animal + dam)" begin
        @test_logs (:warn, r"identif") match_mode = :any min_level = W begin
            fit_multi_effect_mc_reml(y, X, [(Z, Ainv), (Zd, Id)]; iterations = 2, nprobe = 4)
        end
        @test_logs min_level = W fit_multi_effect_mc_reml(y, X, [(Z, Ainv), (Zn, In)]; iterations = 2, nprobe = 4)
    end

    @testset "repeatability: one record per animal" begin
        # Z Z' = I when each animal has one record: V_pe is confounded with V_e.
        @test_logs (:warn, r"identif") min_level = W begin
            fit_repeatability_reml(y, X, Z, Ainv; iterations = 20)
        end
        # control: two records per animal
        Z2 = sparse(1:2n, vcat([idx[k] for k in kids], [idx[k] for k in kids]), 1.0, 2n, q)
        y2 = vcat(y, y .+ [0.1 * cos(2.3i) for i in 1:n])
        @test_logs min_level = W fit_repeatability_reml(y2, ones(2n, 1), Z2, Ainv; iterations = 20)
    end

    @testset "direct-maternal: only offspring phenotyped, one sire per dam" begin
        Zm = sparse(1:n, [idx[dams[g]] for g in damgrp], 1.0, n, q)
        @test_logs (:warn, r"identif") min_level = W begin
            fit_direct_maternal_reml(y, X, Z, Zm, Ainv; iterations = 20)
        end
        # control: three generations, dams phenotyped, each sire mated to two dams
        gs = ["gs$i" for i in 1:nd]; gd = ["gd$i" for i in 1:nd]
        sk(i, j) = sires[mod(i + (j > 2 ? 1 : 0) - 1, nd) + 1]
        ids3 = vcat(gs, gd, sires, dams, kids)
        sire3 = vcat(fill("0", 3nd), gs, [sk(i, j) for i in 1:nd for j in 1:nk])
        dam3 = vcat(fill("0", 3nd), gd, [dams[i] for i in 1:nd for j in 1:nk])
        ped3 = normalize_pedigree(ids3, sire3, dam3)
        Ainv3 = pedigree_inverse(ped3)
        idx3 = Dict(k => i for (i, k) in enumerate(ped3.ids))
        q3 = length(ped3.ids)
        rec = vcat(dams, kids)
        mom = vcat(gd, [dams[g] for g in damgrp])
        n3 = length(rec)
        Zd3 = sparse(1:n3, [idx3[r] for r in rec], 1.0, n3, q3)
        Zm3 = sparse(1:n3, [idx3[m] for m in mom], 1.0, n3, q3)
        y3 = [0.4 * sin(2.3i) + 0.3 * cos(0.71i^2) for i in 1:n3]
        @test_logs min_level = W fit_direct_maternal_reml(y3, ones(n3, 1), Zd3, Zm3, Ainv3; iterations = 20)
    end
end

@testset "issue 416 sparse pre-check size cap" begin
    # skipped (no rank, no warning) past the tighter sparse-route cell cap
    m = 2000
    Zbig = sparse(1:m, 1:m, 1.0, m, m)
    @test HSquared._weak_identifiability_rank_sparse([Zbig, Zbig], [sparse(1.0I, m, m), sparse(1.0I, m, m)], m) === nothing
    # within the cap the rank is computed (Z = I, A = I is confounded with the residual)
    m = 200
    Zs = sparse(1:m, 1:m, 1.0, m, m)
    @test HSquared._weak_identifiability_rank_sparse([Zs], [sparse(1.0I, m, m)], m) == 1
end

@testset "issue 416 repeatability and direct-maternal pre-check size cap" begin
    # Both dense fitters pass their covariance closures to the stacked rank with the
    # dense cell cap (n^2 * (m + 1) cells). Past it the rank is skipped before any
    # closure runs, and a skipped rank emits no warning.
    W = Base.CoreLogging.Warn
    never = () -> error("covariance formed past the cell cap")
    cap = HSquared._WEAK_IDENTIFIABILITY_MAX_CELLS
    # repeatability: animal + permanent environment (m = 2, 3 columns)
    n = 3652
    @test n^2 * 3 > cap && (n - 1)^2 * 3 <= cap
    r = HSquared._weak_identifiability_stacked_rank([never, never], n)
    @test r === nothing
    @test_logs min_level = W HSquared._warn_weak_identifiability_rank(
        r, 3, ("sigma_a2", "sigma_pe2"); hint = "h", remedy = "r")
    # direct-maternal: direct, covariance, maternal (m = 3, 4 columns)
    n = 3163
    @test n^2 * 4 > cap && (n - 1)^2 * 4 <= cap
    r = HSquared._weak_identifiability_stacked_rank([never, never, never], n)
    @test r === nothing
    @test_logs min_level = W HSquared._warn_weak_identifiability_rank(
        r, 4, ("direct genetic", "direct-maternal covariance", "maternal genetic");
        hint = "h", remedy = "r")
end
