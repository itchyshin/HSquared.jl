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
#
# F1 (Rose BLOCK on #339, resolution 1, Ada/Noether-decided): a factor-analytic
# null (`G = ΛΛ' + Ψ`, `Ψ > 0`) is a regular lower-dimensional submanifold of
# the unstructured parameter space, not a variance-at-zero boundary, so the
# classical χ²_df reference (df = identified-parameter difference) applies and
# the Self & Liang (1987) / Stram & Lee (1994) 50:50 chi-bar mixture must NOT
# be entered for structured nulls. A low-rank null (`G = ΛΛ'`, rank r < t)
# lies on the boundary of the PSD cone, where the true reference is a chi-bar
# mixture whose weights this function does not compute, so the naive χ²_df
# tail is reported with its direction relative to that mixture explicitly
# unknown. The assertions below pin `covariance_structure_lrt`'s
# `reference`/`boundary` fields and its `pvalue` against an independent
# `Distributions.jl` χ² tail, and pin that the 50:50 chi-bar mixture
# (`nested_lrt`'s own `boundary_df = 1` branch, left untouched) is never the
# source of that `pvalue` for either structured null.

using HSquared
using LinearAlgebra
using Test
using Distributions: Chisq, ccdf

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

        # F1 resolution 1: a factor-analytic null is a regular submanifold, not
        # a variance-at-zero boundary — `boundary` must be false and the
        # reference distribution the plain χ²_df, not a chi-bar mixture.
        @test lrt.boundary == false
        @test lrt.reference == :chisq
        @test 0.0 <= lrt.pvalue <= 1.0
        @test lrt.pvalue ≈ ccdf(Chisq(lrt.df), lrt.statistic)
        @test !occursin("conservative", lowercase(lrt.note))  # direction is not knowable; must not claim it is

        # Pin that the Self & Liang (1987) / Stram & Lee (1994) 50:50 chi-bar
        # mixture is never the source of `lrt.pvalue`: `nested_lrt`'s own
        # `boundary_df = 1` branch (left untouched, per F1's resolution) is
        # exactly what the pre-fix `covariance_structure_lrt` delegated to for
        # this df == 1 case, and it disagrees with the plain χ²_df tail above.
        buggy = HSquared.nested_lrt(fa.loglik, full.loglik; df = lrt.df, boundary_df = 1)
        @test buggy.mixture == :chibar_5050
        @test !isapprox(lrt.pvalue, buggy.pvalue)
    end

    @testset "lowrank t=6 rank=3 (rotational indeterminacy r(r-1)/2 = 3)" begin
        fake_full = (genetic_covariance = zeros(6, 6), genetic_structure = :unstructured,
                     genetic_rank = 0, loglik = -95.0)
        fake_lr = (genetic_covariance = zeros(6, 6), genetic_structure = :lowrank,
                  genetic_rank = 3, loglik = -100.0)

        # ngen(:lowrank) = t*r - r(r-1)/2 = 6*3-3 = 15, plus R0 t(t+1)/2 = 21 => 36.
        @test HSquared._mv_nparams(fake_lr) == 36
        @test HSquared._mv_nparams(fake_full) == 42   # unstructured t=6: t(t+1)/2 * 2 = 42

        # F1 resolution 1: a low-rank null genuinely sits on the PSD-cone
        # boundary — `boundary` stays true, but the reported p-value is the
        # naive (not the true chi-bar-mixture) χ²_df tail, direction unknown.
        lrt2 = covariance_structure_lrt(fake_lr, fake_full)
        @test lrt2.df == 6
        @test lrt2.boundary == true
        @test lrt2.reference == :chisq_naive_boundary
        @test 0.0 <= lrt2.pvalue <= 1.0
        @test lrt2.pvalue ≈ ccdf(Chisq(lrt2.df), lrt2.statistic)
        @test !occursin("conservative", lowercase(lrt2.note))
    end
end
