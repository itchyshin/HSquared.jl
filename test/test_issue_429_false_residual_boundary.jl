# HSquared.jl #429 — the default NelderMead routes must not stop at a false
# residual boundary (Ve -> 0, converged = true) below an interior REML optimum.
# Standalone:
# julia --project=. -e 'include("test/test_issue_429_false_residual_boundary.jl")'

using HSquared
using LinearAlgebra
using SparseArrays
using Test

# SplitMix64 uniforms and Box-Muller normals. Integer arithmetic keeps the
# fixture bit-stable across Julia versions and platforms.
mutable struct _I429SplitMix
    state::UInt64
end

function _i429_uniform(rng::_I429SplitMix)
    rng.state += 0x9e3779b97f4a7c15
    z = rng.state
    z = (z ⊻ (z >> 30)) * 0xbf58476d1ce4e5b9
    z = (z ⊻ (z >> 27)) * 0x94d049bb133111eb
    z = z ⊻ (z >> 31)
    return ((z >> 11) + 0.5) / 2.0^53
end

_i429_normal(rng::_I429SplitMix) =
    sqrt(-2 * log(_i429_uniform(rng))) * cos(2 * pi * _i429_uniform(rng))

# Full-sib design shaped like the Plodia PO data in #429: unrelated sire/dam
# pairs, one record per offspring, a plate fixed effect, and a response
# variance near 0.035 (far below the unit-scale (1, 1) default start).
function _i429_fullsib_spec(; seed = 8, families = 12, offspring = 8, plates = 6,
                            sigma_a2 = 0.0095, sigma_e2 = 0.025)
    rng = _I429SplitMix(UInt64(seed))
    ids = String[]
    sire = String[]
    dam = String[]
    for f in 1:families
        append!(ids, ["S$f", "D$f"])
        append!(sire, ["0", "0"])
        append!(dam, ["0", "0"])
    end
    plate_effect = [0.05 * _i429_normal(rng) for _ in 1:plates]
    y = Float64[]
    plate = Int[]
    records = String[]
    for f in 1:families
        a_sire = sqrt(sigma_a2) * _i429_normal(rng)
        a_dam = sqrt(sigma_a2) * _i429_normal(rng)
        for k in 1:offspring
            id = "o$(f)_$k"
            push!(ids, id)
            push!(sire, "S$f")
            push!(dam, "D$f")
            a = (a_sire + a_dam) / 2 + sqrt(sigma_a2 / 2) * _i429_normal(rng)
            p = ((f + (k <= offspring ÷ 2 ? 0 : 1)) % plates) + 1
            push!(plate, p)
            push!(records, id)
            push!(y, 1.17 + plate_effect[p] + a + sqrt(sigma_e2) * _i429_normal(rng))
        end
    end
    ped = normalize_pedigree(ids, sire, dam)
    X = hcat(ones(length(y)), [plate[i] == l ? 1.0 : 0.0 for i in eachindex(y), l in 2:plates])
    position = Dict(id => i for (i, id) in enumerate(ped.ids))
    Z = sparse(1:length(y), [position[id] for id in records], ones(length(y)),
               length(y), length(ped.ids))
    return animal_model_spec(y, X, Z, pedigree_inverse(ped); ids = ped.ids, method = :REML)
end

_i429_min_share(fit) = begin
    vc = fit.variance_components
    min(vc.sigma_a2, vc.sigma_e2) / (vc.sigma_a2 + vc.sigma_e2)
end

@testset "issue 429 default NelderMead routes escape a false residual boundary" begin
    spec = _i429_fullsib_spec()
    @test 0.01 < sum(abs2, spec.y .- sum(spec.y) / length(spec.y)) / (length(spec.y) - 1) < 0.1

    # AI-REML from the same default start reaches the interior optimum.
    reference = fit_ai_reml(spec; iterations = 200)
    @test reference.converged
    @test _i429_min_share(reference) > 0.05

    # Default dense route (the R `animal()` default target), the sparse
    # NelderMead target, and the generic fit_animal_model default.
    for (name, fit) in (
        ("fit_variance_components", fit_variance_components(spec)),
        ("fit_sparse_reml", fit_sparse_reml(spec)),
        ("fit_animal_model", fit_animal_model(spec)),
    )
        @testset "$name" begin
            @test fit.converged
            @test _i429_min_share(fit) > 0.05
            @test isapprox(fit.likelihood.loglik, reference.likelihood.loglik; atol = 1e-5)
            @test isapprox(fit.variance_components.sigma_a2,
                           reference.variance_components.sigma_a2; rtol = 1e-3)
            @test isapprox(fit.variance_components.sigma_e2,
                           reference.variance_components.sigma_e2; rtol = 1e-3)
        end
    end

    # A genuine residual-boundary optimum (Mrode 3 records, #412) stays on the
    # boundary: the refit only replaces a fit it beats.
    mrode_ids = string.(1:8)
    mrode_ped = normalize_pedigree(
        mrode_ids,
        ["0", "0", "0", "1", "3", "1", "4", "3"],
        ["0", "0", "0", "0", "2", "2", "5", "6"],
    )
    mrode_y = [4.5, 2.9, 3.9, 3.5, 5.0]
    mrode_X = hcat(ones(5), [0.0, 1.0, 1.0, 0.0, 0.0])
    mrode_Z = spzeros(5, 8)
    for (i, animal) in enumerate(4:8)
        mrode_Z[i, animal] = 1.0
    end
    mrode = animal_model_spec(mrode_y, mrode_X, mrode_Z, pedigree_inverse(mrode_ped);
                              ids = mrode_ped.ids, method = :REML)
    for fit in (fit_variance_components(mrode), fit_sparse_reml(mrode))
        vc = fit.variance_components
        @test fit.converged
        @test vc.sigma_e2 / (vc.sigma_a2 + vc.sigma_e2) <= 1e-6
    end
end
