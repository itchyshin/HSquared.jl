# Sparse AI-REML: one workspace for the whole fit (HSquared.jl#352 / #360 follow-on).
#
# `fit_sparse_multi_effect_aireml` rebuilt the Henderson coefficient matrix from
# scratch and ran a FULL `cholesky` -- symbolic analysis included -- at every AI
# iteration, every EM warm-start iteration, and once more inside the closing
# `sparse_multi_reml_loglik`, which also re-derived every cross-product and each
# `log|Ai^-1|` a second time. The sparsity pattern of that matrix is the same at
# every one of those points; only its values move with sigma.
#
# The fit now shares one `_MultiREMLWorkspace` across all of it: the pattern is
# built once and only `nzval` is rewritten (`_assemble_lhs_rhs!`), and the
# symbolic factorization is reused through `cholesky!` (`_factorize!`). Measured
# on the great tit animal + permanent-environment fit (n = 11,856, q = 10,937):
# assemble + factorize 31.7 ms -> 5.9 ms per iteration, whole fit 0.87 s -> 0.65 s.
# Bitwise-identical output, which is what these tests pin.

@testset "sparse AI-REML workspace reuse (#352/#360 follow-on)" begin
    rng = MersenneTwister(20260921)
    nf, no = 30, 70
    n_animal = nf + no
    sire = zeros(Int, n_animal); dam = zeros(Int, n_animal)
    for k in (nf + 1):n_animal
        sire[k] = rand(rng, 1:nf)
        dam[k] = rand(rng, 1:nf)
        while dam[k] == sire[k]
            dam[k] = rand(rng, 1:nf)
        end
    end
    Ainv = pedigree_inverse(collect(1:n_animal), sire, dam)
    a = zeros(n_animal); a[1:nf] = randn(rng, nf)
    for k in (nf + 1):n_animal
        a[k] = 0.5 * (a[sire[k]] + a[dam[k]]) + randn(rng) * sqrt(0.5)
    end
    pe = randn(rng, n_animal) .* sqrt(0.6)
    rec = repeat(1:n_animal, 4)
    nobs = length(rec)
    y = [1.0 + a[i] + pe[i] + randn(rng) * sqrt(0.9) for i in rec]
    X = hcat(ones(nobs), randn(rng, nobs))
    Z = sparse(1:nobs, rec, 1.0, nobs, n_animal)
    Ipe = spdiagm(0 => ones(n_animal))
    effs = [(Z, Ainv), (Z, Ipe)]

    # (i) In-place assembly reproduces `_sparse_multi_lhs_rhs` EXACTLY -- the same
    # structure AND the same values, at several sigma and in mixed order, so a
    # later assembly can never inherit anything from an earlier one.
    ws = HSquared._multi_reml_workspace(y, X, effs)
    for (ss, se2) in (([1.0, 1.0], 1.0), ([0.7, 0.4], 1.2), ([3.0, 0.01], 0.05),
                      ([0.7, 0.4], 1.2), ([12.0, 9.0], 30.0))
        ref_lhs, ref_rhs = HSquared._sparse_multi_lhs_rhs(
            ws.XtX, ws.XtZ, ws.ZtX, ws.ZtZ, ws.Xty, ws.Zty, ws.Ainvs, ss, se2)
        got_lhs, got_rhs = HSquared._assemble_lhs_rhs!(ws, ss, se2)
        @test got_lhs.colptr == ref_lhs.colptr
        @test got_lhs.rowval == ref_lhs.rowval
        @test all(nonzeros(got_lhs) .=== nonzeros(ref_lhs))   # bitwise
        @test all(got_rhs .=== ref_rhs)
    end

    # (ii) The reused symbolic factorization gives the same factor as a fresh one.
    lhs, rhs = HSquared._assemble_lhs_rhs!(ws, [0.7, 0.4], 1.2)
    fresh = cholesky(Symmetric(copy(lhs)); check = true)
    reused = HSquared._factorize!(ws)                 # second factorization of ws
    @test logdet(reused) === logdet(fresh)
    @test all((reused \ rhs) .=== (fresh \ rhs))

    # (iii) The fit's closing log-likelihood is the standalone one, bitwise, at
    # the components it converged to -- the closing call no longer rebuilds the
    # problem, so this pins that the shortcut did not change the number.
    fit = HSquared.fit_sparse_multi_effect_aireml(y, X, effs)
    s = fit.variance_components.sigmas; se2 = fit.variance_components.sigma_e2
    @test fit.loglik === sparse_multi_reml_loglik(y, X, effs, s, se2)[1]
    @test fit.converged

    # (iv) The sparse fit still reduces to the dense oracle at this scale. The
    # workspace touches assembly and factorization, i.e. exactly the machinery
    # this reduction depends on, so it is re-pinned here rather than assumed.
    dense = fit_multi_effect_reml(y, X, effs)
    # rtol 1e-3: the two optimizers stop on different rules, so they agree to
    # roughly 1e-4 here. That is wide enough not to be a tolerance trap and tight
    # enough that a genuinely broken assembly cannot slip through.
    @test isapprox(collect(s), collect(dense.variance_components.sigmas); rtol = 1e-3)
    @test isapprox(se2, dense.variance_components.sigma_e2; rtol = 1e-3)

    # (v) An EM warm-start shares the same workspace and still lands on the
    # optimum (it takes a different path through it, so it is worth its own case).
    warm = HSquared.fit_sparse_multi_effect_aireml(y, X, effs; em_warmup = 3)
    @test isapprox(collect(warm.variance_components.sigmas), collect(s); rtol = 1e-5)
    @test isapprox(warm.variance_components.sigma_e2, se2; rtol = 1e-5)

    # (vi) `initial = :auto` is a data-scaled START, not a different estimator:
    # the same optimum, reached from somewhere else. It is NOT pinned to be
    # faster -- on THIS fixture, simulated at unit variance, `(1,…,1)` is already
    # an excellent start and `:auto` costs MORE iterations (12 against 10), while
    # on the great tit fit (var(y) = 3.0, optimum total 2.49) it costs fewer
    # (8 against 10). Iteration count is a property of the data, not of the
    # option, so what is pinned here is that it agrees.
    auto = HSquared.fit_sparse_multi_effect_aireml(y, X, effs; initial = :auto)
    @test auto.converged
    @test isapprox(collect(auto.variance_components.sigmas), collect(s); rtol = 1e-5)
    @test isapprox(auto.variance_components.sigma_e2, se2; rtol = 1e-5)
    @test isapprox(auto.loglik, fit.loglik; rtol = 1e-8)
    # the default is unchanged: (1,…,1), not the data-scaled start
    @test HSquared.fit_sparse_multi_effect_aireml(y, X, effs).iterations === fit.iterations

    # (vii) `initial` rejects an unsupported symbol by name rather than failing
    # somewhere inside with a MethodError.
    @test_throws ArgumentError HSquared.fit_sparse_multi_effect_aireml(
        y, X, effs; initial = :data)
    # a constant response has no variance to scale from
    @test_throws ArgumentError HSquared.fit_sparse_multi_effect_aireml(
        fill(2.0, nobs), X, effs; initial = :auto)
    # the vector path is untouched
    @test_throws ArgumentError HSquared.fit_sparse_multi_effect_aireml(
        y, X, effs; initial = [1.0, 1.0])
    @test_throws ArgumentError HSquared.fit_sparse_multi_effect_aireml(
        y, X, effs; initial = [1.0, -1.0, 1.0])
end
