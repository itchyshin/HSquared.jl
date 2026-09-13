# #331 — covariance_structure_lrt / _mv_nparams must subtract the K(K-1)/2 (or
# r(r-1)/2) rotational indeterminacy that `ledermann_slack` already implies for
# `:factor_analytic` and `:lowrank` genetic-covariance structures. Before the
# fix, `_mv_nparams` counted `t*r` (`:lowrank`) / `t*r+t` (`:factor_analytic`)
# raw loading entries with no correction for the rotation group `O(r)`
# (dimension `r(r-1)/2`), so a Ledermann-valid comparison (positive
# `ledermann_slack`) could be wrongly refused by `covariance_structure_lrt`.
#
# NOTE on the numbers below vs. the issue text: `_mv_nparams` returns
# `ngen + t*(t+1)÷2` (the unstructured-R0 term is always added), so the
# function's own return value is 15 higher (t=5) / 21 higher (t=6) than the
# genetic-only `ngen` the issue quotes (14/15 and 15/18). The R0 term is
# identical on both sides of every `covariance_structure_lrt` comparison here,
# so it cancels in `df` — the assertions below use the REAL return value of
# `_mv_nparams`, not the issue's genetic-only shorthand.

using HSquared
using LinearAlgebra
using Test

@testset "#331 structured LRT df counts identified parameters" begin
    @testset "factor_analytic t=5 K=2 (Ledermann slack = 2, was wrongly refused)" begin
        @test ledermann_slack(5, 2) == 2
        @test fa_covered_flip_cell(5, 2)

        ped = normalize_pedigree(
            ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"],
            ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
            ["0", "0", "a2", "a2", "0", "0", "a4", "a6"],
        )
        Ainv = pedigree_inverse(ped)
        reps = 3
        rows = reduce(vcat, [fill(i, reps) for i in 1:8])
        Z = zeros(length(rows), 8)
        for (k, i) in enumerate(rows)
            Z[k, i] = 1.0
        end
        X = ones(length(rows), 1)
        y1base = [2.0, 3.0, 2.5, 3.5, 4.0, 1.5, 3.0, 4.5]
        y2base = reverse(y1base)
        off = [0.0, 0.3, -0.3]
        y1 = Float64[]; y2 = Float64[]; y3 = Float64[]; y4 = Float64[]; y5 = Float64[]
        for i in 1:8, r in 1:reps
            push!(y1, y1base[i] + off[r])
            push!(y2, y2base[i] - off[r])
            push!(y3, 1.0 + 0.5 * y1base[i] + 0.2 * off[r])
            push!(y4, 2.0 - 0.3 * y2base[i] + 0.2 - off[r])
            push!(y5, 0.5 * y1base[i] + 0.5 * y2base[i] + 0.1 * off[r])
        end
        Y5 = hcat(y1, y2, y3, y4, y5)

        full = fit_multivariate_reml(Y5, X, Z, Ainv)
        L0 = hcat(fill(0.3, 5), [0.2, -0.1, 0.3, -0.2, 0.1])
        fa = fit_multivariate_reml(
            Y5, X, Z, Ainv;
            genetic_structure = :factor_analytic, rank = 2,
            initial = (loadings = L0, uniqueness = fill(0.3, 5), R0 = Matrix(1.0I, 5, 5)),
        )
        @test fa.genetic_structure == :factor_analytic
        @test fa.genetic_rank == 2

        # Identified-parameter count: t*r + t - r(r-1)/2 (+ the unstructured-R0
        # term shared with `full`) = 5*2+5-1 = 14, plus R0 15 => 29.
        @test HSquared._mv_nparams(fa) == 29
        @test HSquared._mv_nparams(full) == 30   # unstructured: no rotational indeterminacy to remove

        lrt = covariance_structure_lrt(fa, full)   # (constrained, full) — fa nests inside unstructured
        @test lrt.df == 1                        # was: npf == npc == 30 => ArgumentError (df = 0)
        @test lrt.boundary == true
        @test 0.0 <= lrt.pvalue <= 1.0
        @test !occursin("conservative", lowercase(lrt.note))  # direction is not knowable; must not claim it is
    end

    @testset "lowrank t=6 rank=3 (rotational indeterminacy r(r-1)/2 = 3)" begin
        fake_full = (genetic_covariance = zeros(6, 6), genetic_structure = :unstructured, genetic_rank = 0)
        fake_lr = (genetic_covariance = zeros(6, 6), genetic_structure = :lowrank, genetic_rank = 3)

        # ngen(:lowrank) = t*r - r(r-1)/2 = 6*3-3 = 15, plus R0 t(t+1)/2 = 21 => 36.
        @test HSquared._mv_nparams(fake_lr) == 36
        @test HSquared._mv_nparams(fake_full) == 42   # unstructured t=6: t(t+1)/2 * 2 = 42
    end
end
