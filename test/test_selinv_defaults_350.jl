# test_selinv_defaults_350.jl -- #350: sparse defaults for the post-fit summaries
#
# Finding (Szymon Drobniak, measured at q = 5,000 animals, one BLAS thread): the
# AI-REML fit takes 0.03 s, but the summaries the R bridge calls on every fit
# did not scale:
#   (a) `reliability` formed the dense `A = inv(Ainv)` only to read `diag(A)`
#       (5.8 s, 0.8 GB inside `result_payload`);
#   (b) `breeding_values_plot_data` went through `prediction_error_variance`
#       whose default was `method = :dense`, a dense (p+q)x(p+q) MME inverse
#       (11.4 s, 1.8 GB), although the `:selinv` Takahashi path already gave
#       the same PEV in 0.002 s / 10 MB.
#
# Pinned here: (i) parity -- at q = 1,000 the `:selinv` and `:dense` PEV agree
# on every diagonal entry to 1e-8, the sparse selected-inverse `diag(inv(Ainv))`
# used by `reliability` equals the old dense `diag(inv(Ainv))` AND `1 + F_i`
# (inbreeding) to 1e-8, and the new `reliability` equals the old dense formula
# to 1e-8; (ii) budget -- at q = 3,000, `result_payload` + `breeding_values_plot_data`
# together allocate under 100 MB and take under 1 s (warm).
#
# Fixture: half-sib pedigree (sires 5 %, dams 10 %, offspring 85 %), two records
# per animal, `y = 0.3 * randn` under a fixed seed (the same shape as the
# measuring script). Fitted by `fit_ai_reml`, the bridge's fitter.

using HSquared
using LinearAlgebra
using SparseArrays
using Random
using Test

function _halfsib_pedigree_350(q::Int)
    nsire = round(Int, 0.05q)
    ndam = round(Int, 0.10q)
    noff = q - nsire - ndam
    ids = collect(1:q)
    sire = zeros(Int, q)
    dam = zeros(Int, q)
    for k in 1:noff
        i = nsire + ndam + k
        sire[i] = 1 + (k - 1) % nsire
        dam[i] = nsire + 1 + (k - 1) % ndam
    end
    return HSquared.normalize_pedigree(ids, sire, dam)
end

function _halfsib_fit_350(q::Int; seed::Integer = 350)
    ped = _halfsib_pedigree_350(q)
    Ainv = HSquared.pedigree_inverse(ped)
    n = 2q
    rng = MersenneTwister(seed)
    y = 0.3 .* randn(rng, n)
    X = ones(n, 1)
    Z = sparse(1:n, repeat(1:q, inner = 2), 1.0, n, q)
    spec = HSquared.animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
    return ped, HSquared.fit_ai_reml(spec)
end

@testset "350 (i): selinv PEV/reliability parity with the dense oracle, q = 1,000" begin
    ped, fit = _halfsib_fit_350(1_000)
    @test fit.converged
    vc = fit.variance_components
    @test vc.sigma_a2 > 0 && vc.sigma_e2 > 0

    pev_dense = HSquared.prediction_error_variance(fit; method = :dense)
    pev_selinv = HSquared.prediction_error_variance(fit; method = :selinv)
    @test pev_selinv.ids == pev_dense.ids
    @test length(pev_selinv.values) == 1_000
    @test maximum(abs.(pev_selinv.values .- pev_dense.values)) <= 1e-8

    # The default is now the sparse path (was :dense).
    @test HSquared.prediction_error_variance(fit).values == pev_selinv.values

    # Animal self-relationship: old dense diag(inv(Ainv)) == 1 + F_i (pedigree
    # identity) == the sparse selected-inverse diagonal that reliability now uses.
    Ainv = fit.spec.Ainv
    diag_dense = diag(inv(Symmetric(Matrix{Float64}(Ainv))))
    @test maximum(abs.(diag_dense .- (1 .+ HSquared.inbreeding_coefficients(ped)))) <= 1e-8
    @test maximum(abs.(HSquared._relationship_diag(Ainv) .- diag_dense)) <= 1e-8

    # New reliability == the old implementation (dense inv(Ainv) denominator).
    rel_old = 1 .- pev_dense.values ./ (vc.sigma_a2 .* diag_dense)
    rel_new = HSquared.reliability(fit)
    @test rel_new.ids == pev_dense.ids
    @test maximum(abs.(rel_new.values .- rel_old)) <= 1e-8
    @test maximum(abs.(HSquared.reliability(fit; method = :dense).values .- rel_old)) <= 1e-8
    @test maximum(abs.(HSquared.reliability(fit; method = :selinv).values .- rel_old)) <= 1e-8

    # Inbred pedigree (full-sib and half-sib matings, F_i > 0): the 1 + F_i
    # identity and the sparse diagonal hold off the F = 0 special case too.
    ped8 = HSquared.normalize_pedigree(
        ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"],
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"],
    )
    Ainv8 = HSquared.pedigree_inverse(ped8)
    F8 = HSquared.inbreeding_coefficients(ped8)
    @test any(F8 .> 0)
    diag8_dense = diag(inv(Symmetric(Matrix{Float64}(Ainv8))))
    @test maximum(abs.(diag8_dense .- (1 .+ F8))) <= 1e-8
    @test maximum(abs.(HSquared._relationship_diag(Ainv8) .- diag8_dense)) <= 1e-8
end

@testset "350 (ii): result_payload + breeding_values_plot_data budget, q = 3,000" begin
    _, fit = _halfsib_fit_350(3_000)
    @test fit.converged

    both(f) = (HSquared.result_payload(f), HSquared.breeding_values_plot_data(f))
    both(fit)                                   # warm-up (JIT)
    GC.gc()
    bytes = @allocated both(fit)
    secs = @elapsed both(fit)
    @info "350 budget at q = 3,000" bytes_MB = bytes / 1e6 seconds = secs
    @test bytes < 100_000_000
    @test secs < 1.0

    payload, plot_data = both(fit)
    @test payload.prediction_error_variance.values ==
          HSquared.prediction_error_variance(fit; method = :selinv).values
    @test plot_data.pev == HSquared.prediction_error_variance(fit; method = :selinv).values
    @test payload.reliability.values == HSquared.reliability(fit; method = :selinv).values
end
