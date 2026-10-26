# Part of #409: the heritability profile maximises the REML log-likelihood over
# the total variance V along (sigma_a2, sigma_e2) = (h*V, (1-h)*V). That is a
# scale family, so the maximiser is V = y'Py / (n - p) in closed form and one
# factorisation per h replaces the inner 1-D search. Reference endpoints are the
# same ones recorded from main before any #409 change (see
# test_issue_409_profile_interval_hoist.jl); the evaluation counter shows the
# inner search is gone.
using Test, LinearAlgebra, SparseArrays, HSquared

@testset "Issue 409: closed-form total-variance profile for h2" begin
    nanim = 120
    ids = ["a$i" for i in 1:nanim]
    sire = [i <= 10 ? "0" : "a$(1 + i % 5)" for i in 1:nanim]
    dam = [i <= 10 ? "0" : "a$(6 + i % 5)" for i in 1:nanim]
    ped = normalize_pedigree(ids, sire, dam)
    Ainv = pedigree_inverse(ped)
    a = cholesky(Symmetric(Matrix(Ainv))).L \ [sin(1.3 * i) for i in 1:nanim]
    y = 10 .+ 1.2 .* a .+ [1.4 * cos(2.1 * i + 0.3) for i in 1:nanim]
    spec = animal_model_spec(y, ones(nanim, 1), sparse(1.0I, nanim, nanim), Ainv;
                             ids = ped.ids, method = :REML)
    fit = fit_sparse_reml(spec)
    @test fit.converged

    # Closed-form profile agrees with a brute-force search over V at fixed h.
    ctx = HSquared._profile_reml_context(spec)
    for h in (0.05, 0.3, 0.44, 0.7, 0.95)
        brute = maximum(
            HSquared.sparse_reml_loglik(spec, h * V, (1 - h) * V).loglik
            for V in exp.(range(log(0.05), log(50.0); length = 4001)))
        closed = HSquared._profile_reml_loglik(ctx, h)
        @test closed >= brute - 1e-9
        @test closed ≈ brute atol = 1e-4
    end

    counter = HSquared._SPARSE_REML_EVALS
    counter[] = 0
    h = heritability_interval(fit; method = :profile)
    @test h.lower ≈ 0.15389657583498323 atol = 1e-7
    @test h.upper ≈ 0.78883205496024766 atol = 1e-7
    @test !h.lower_clamped && !h.upper_clamped
    # Two bisections of at most ~45 steps each, one factorisation per step.
    @test counter[] <= 150
end
