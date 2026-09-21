# Post-fit uncertainty: one information matrix, reused (HSquared.jl#352 follow-on).
#
# `multi_effect_variance_component_standard_errors`, `multi_effect_ratio_standard_errors`
# and `multi_effect_sum_ratio_interval` each built their own finite-difference
# Hessian of the REML log-likelihood, and that Hessian rebuilt every
# sigma-INDEPENDENT quantity at every one of its evaluation points -- the sparse
# conversions, the four cross-products, each `log|Ai^-1|`, and the symbolic
# factorization of a Henderson coefficient matrix whose sparsity pattern never
# changes. On the great tit animal + permanent-environment fit (n = 11,856,
# q = 10,937) the three calls cost 4.37 s against 0.87 s for the fit itself.
#
# The three changes here are all VALUE-PRESERVING, which is what these tests pin:
#   * `_MultiREMLWorkspace` hoists the sigma-independent work and reuses the
#     symbolic factor through `cholesky!`;
#   * `_reml_fd_information` runs the upper triangle and mirrors it, instead of
#     computing the `i > j` cells that `Symmetric` then discarded;
#   * `multi_effect_uncertainty` returns all three products from ONE covariance.
# Measured after: 0.76 s for the three separate calls, 0.25 s through
# `multi_effect_uncertainty`. Bitwise-identical output on the great tit fixture
# (loglik, BLUPs, the full 3x3 covariance, every SE and the interval).

@testset "post-fit uncertainty reuse (#352 follow-on)" begin
    rng = MersenneTwister(20260921)
    nf, no = 40, 90
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

    a = zeros(n_animal)
    a[1:nf] = randn(rng, nf)
    for k in (nf + 1):n_animal
        a[k] = 0.5 * (a[sire[k]] + a[dam[k]]) + randn(rng) * sqrt(0.5)
    end
    pe = randn(rng, n_animal) .* sqrt(0.6)
    reps = 4
    rec = repeat(1:n_animal, reps)
    nobs = length(rec)
    y = [1.5 + a[i] + pe[i] + randn(rng) * sqrt(0.8) for i in rec]
    X = ones(nobs, 1)
    Z = sparse(1:nobs, rec, 1.0, nobs, n_animal)
    Ipe = spdiagm(0 => ones(n_animal))
    effs = [(Z, Ainv), (Z, Ipe)]

    fit = HSquared.fit_sparse_multi_effect_aireml(y, X, effs)
    s = fit.variance_components.sigmas
    se2 = fit.variance_components.sigma_e2

    # (i) The workspace is a pure hoist: a sequence of evaluations sharing one
    # workspace (and therefore one symbolic factorization, via `cholesky!`) must
    # be BITWISE equal to independent `sparse_multi_reml_loglik` calls. Bitwise,
    # not approximate -- the point of the split is that no arithmetic moved.
    ws = HSquared._multi_reml_workspace(y, X, effs)
    for (ts, te) in ((s, se2), (s .* 1.07, se2 * 0.93), (s .* 0.5, se2 * 2.0),
                     ([s[1], s[2] * 3], se2), (s, se2 * 1.001))
        ref_ll, ref_beta, ref_us = sparse_multi_reml_loglik(y, X, effs, ts, te)
        got_ll, got_beta, got_us = HSquared._multi_reml_loglik!(ws, ts, te)
        @test got_ll === ref_ll                      # bitwise
        @test all(got_beta .=== ref_beta)
        @test all(all(got_us[k] .=== ref_us[k]) for k in 1:2)
    end

    # (ii) The workspace is reusable in any order, so a later point never depends
    # on which points preceded it through the cached factor.
    ws_a = HSquared._multi_reml_workspace(y, X, effs)
    ws_b = HSquared._multi_reml_workspace(y, X, effs)
    HSquared._multi_reml_loglik!(ws_a, s .* 2, se2 * 3)      # different point first
    @test HSquared._multi_reml_loglik!(ws_a, s, se2)[1] ===
          HSquared._multi_reml_loglik!(ws_b, s, se2)[1]

    # (iii) `sparse_multi_reml_loglik` keeps its argument checks, in the order it
    # applied them before the workspace split (sigma checks ahead of shape checks).
    @test_throws ArgumentError sparse_multi_reml_loglik(y, X, effs, [s[1]], se2)
    @test_throws ArgumentError sparse_multi_reml_loglik(y, X, effs, [-1.0, s[2]], se2)
    @test_throws ArgumentError sparse_multi_reml_loglik(y, X, effs, s, -1.0)
    @test_throws ArgumentError sparse_multi_reml_loglik(y, X, [], s, se2)

    # (iv) The symmetric FD loop reproduces the full-grid Hessian EXACTLY on the
    # triangle `Symmetric` actually reads, and returns a symmetric matrix. The
    # reference below is the pre-change full `d x d` loop, verbatim.
    function _full_grid_information(f, theta, fd_step)
        d = length(theta)
        h = fd_step .* max.(abs.(theta), 1e-3)
        H = zeros(d, d)
        for i in 1:d, j in 1:d
            ei = zeros(d); ei[i] = h[i]
            ej = zeros(d); ej[j] = h[j]
            H[i, j] = (f(theta + ei + ej) - f(theta + ei - ej) -
                       f(theta - ei + ej) + f(theta - ei - ej)) / (4 * h[i] * h[j])
        end
        return Symmetric(-H)
    end
    theta = vcat(collect(s), se2)
    ll(t) = sparse_multi_reml_loglik(y, X, effs, t[1:2], t[3])[1]
    info_ref = _full_grid_information(ll, theta, 1e-4)
    info_new = HSquared._reml_fd_information(ll, theta, 1e-4)
    for i in 1:3, j in 1:3
        @test info_new[i, j] === info_ref[i, j]      # bitwise on what Symmetric reads
    end
    @test Matrix(info_new) == transpose(Matrix(info_new))

    # (v) The FD loop evaluates its function `4*d*(d+1)/2` times, not `4*d^2`:
    # 24 rather than 36 at d = 3. Counted, so a future edit that reinstates the
    # discarded lower-triangle cells fails here rather than silently costing 50%.
    calls = Ref(0)
    counted(t) = (calls[] += 1; ll(t))
    HSquared._reml_fd_information(counted, theta, 1e-4)
    @test calls[] == 4 * 3 * 4 ÷ 2

    # (vi) `multi_effect_uncertainty` returns EXACTLY what the three standalone
    # functions return -- it only stops paying for three identical Hessians.
    unc = multi_effect_uncertainty(y, X, effs, s, se2)
    vcse = multi_effect_variance_component_standard_errors(y, X, effs, s, se2)
    rse = multi_effect_ratio_standard_errors(y, X, effs, s, se2)
    ci = multi_effect_sum_ratio_interval(y, X, effs, s, se2)
    cov = multi_effect_variance_component_covariance(y, X, effs, s, se2)
    @test unc.covariance == cov
    @test unc.variance_component_se.sigmas == vcse.sigmas
    @test unc.variance_component_se.sigma_e2 === vcse.sigma_e2
    @test unc.ratio_se == rse
    @test unc.sum_ratio_interval.estimate === ci.estimate
    @test unc.sum_ratio_interval.lower === ci.lower
    @test unc.sum_ratio_interval.upper === ci.upper
    @test unc.sum_ratio_interval.se === ci.se
    @test unc.level == 0.95

    # (vii) `which` and `level` reach the interval, and only the interval.
    u1 = multi_effect_uncertainty(y, X, effs, s, se2; which = 1:1, level = 0.90)
    c1 = multi_effect_sum_ratio_interval(y, X, effs, s, se2; which = 1:1, level = 0.90)
    @test u1.sum_ratio_interval.estimate === c1.estimate
    @test u1.sum_ratio_interval.lower === c1.lower
    @test u1.level == 0.90
    @test u1.ratio_se == rse                    # unchanged by `which`

    # (viii) A ratio on the rail is NOT a covariance failure, and the two are
    # reported separately: only the logit interval is unavailable, while the
    # standard errors come back normally. `boundary_tol` puts a perfectly healthy
    # fit on the rail, which isolates this from the near-zero-component case in
    # (x) -- there the covariance itself is what fails.
    rail = multi_effect_uncertainty(y, X, effs, s, se2; which = 1:1, boundary_tol = 0.9)
    @test rail.sum_ratio_interval.boundary
    @test isnan(rail.sum_ratio_interval.lower) && isnan(rail.sum_ratio_interval.upper)
    @test all(isfinite, rail.variance_component_se.sigmas)
    @test isfinite(rail.variance_component_se.sigma_e2)
    @test all(isfinite, rail.ratio_se)
    @test rail.ratio_se == rse                  # unaffected by the rail
    # the standalone interval agrees, and still returns rather than throwing
    rail_ci = multi_effect_sum_ratio_interval(y, X, effs, s, se2; which = 1:1,
                                              boundary_tol = 0.9)
    @test rail_ci.boundary && isnan(rail_ci.lower)

    # (ix) Argument validation matches the interval's.
    @test_throws ArgumentError multi_effect_uncertainty(y, X, effs, s, se2; level = 1.5)
    @test_throws ArgumentError multi_effect_uncertainty(y, X, effs, s, se2; which = 1:5)

    # (x) A component too close to zero for a finite-difference step makes the
    # covariance itself unavailable, so NOTHING here is available: refused ONCE,
    # rather than returning NaN standard errors. The standalone interval still
    # absorbs it and returns a boundary row, which is its own documented contract.
    @test_throws ArgumentError multi_effect_uncertainty(y, X, effs, [1e-12, s[2]], se2)
    @test_throws ArgumentError multi_effect_variance_component_standard_errors(
        y, X, effs, [1e-12, s[2]], se2)
    @test multi_effect_sum_ratio_interval(y, X, effs, [1e-12, s[2]], se2).boundary
end
