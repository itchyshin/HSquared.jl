# HSquared.jl #436 — payload-v2 must not silently drop fit kwargs.
# Standalone: julia --project=. -e 'include("test/test_payload_v2_ignored_kwargs.jl")'

using HSquared
using LinearAlgebra
using SparseArrays
using Test

function _supplied_pedigree_block(name, n)
    Z = sparse(1.0I, n, n)
    return Dict{String, Any}(
        "name" => name,
        "type" => "pedigree",
        "relmat_status" => "supplied",
        "relmat_inverse" => sparse(1.0I, n, n),
        "ids" => ["id$i" for i in 1:n],
        "Z" => Z,
    )
end

function _iid_block(name, n)
    return Dict{String, Any}(
        "name" => name,
        "type" => "iid",
        "relmat_status" => "identity",
        "ids" => ["lvl$i" for i in 1:n],
        "Z" => sparse(1.0I, n, n),
    )
end

function _animal_payload()
    return Dict{String, Any}(
        "payload_version" => 2,
        "y" => [1.0, 2.0],
        "X" => ones(2, 1),
        "method" => "REML",
        "random_effects" => [_supplied_pedigree_block("animal", 2)],
    )
end

function _two_effect_payload()
    return Dict{String, Any}(
        "payload_version" => 2,
        "y" => [1.0, 2.0],
        "X" => ones(2, 1),
        "method" => "REML",
        "random_effects" => [
            _supplied_pedigree_block("animal", 2),
            _iid_block("block", 2),
        ],
    )
end

function _multivariate_repeatability_payload()
    pedigree = _supplied_pedigree_block("animal", 2)
    pe = _iid_block("pe", 2)
    pe["ids"] = copy(pedigree["ids"])
    return Dict{String, Any}(
        "payload_version" => 2,
        "Y" => [1.0 2.0; 3.0 4.0],
        "X" => ones(2, 1),
        "method" => "REML",
        "random_effects" => [pedigree, pe],
    )
end

function _fit_error(payload; kwargs...)
    try
        fit_payload_v2(payload; kwargs...)
        return nothing
    catch e
        return e
    end
end

function _names_keyword(err, dispatch, keyword)
    msg = sprint(showerror, err)
    return err isa ArgumentError && occursin(string(keyword), msg) &&
        occursin(string(dispatch), msg)
end

@testset "Payload-v2 ignored fit kwargs error (HSquared.jl #436)" begin
    @test parse_payload_v2(_animal_payload()).dispatch == :animal
    @test parse_payload_v2(_two_effect_payload()).dispatch == :two_effect
    @test parse_payload_v2(_multivariate_repeatability_payload()).dispatch ==
        :multivariate_repeatability

    cases = (
        (:animal, _animal_payload(), (sigma_a2 = 100.0, sigma_e2 = 100.0)),
        (:two_effect, _two_effect_payload(), (sigma1 = 100.0, sigma2 = 100.0, sigma_e2 = 100.0)),
        (:multivariate_repeatability, _multivariate_repeatability_payload(),
         (G0 = [1.0 0.0; 0.0 1.0], P0 = [1.0 0.0; 0.0 1.0], R0 = [1.0 0.0; 0.0 1.0])),
    )
    for (dispatch, payload, initial) in cases
        @testset "$dispatch" begin
            err_initial = _fit_error(payload; initial = initial)
            @test _names_keyword(err_initial, dispatch, :initial)

            err_iterations = _fit_error(payload; iterations = 5)
            @test _names_keyword(err_iterations, dispatch, :iterations)

            err_auto = _fit_error(payload; scale_method = :auto)
            @test _names_keyword(err_auto, dispatch, :scale_method)

            err_bogus = _fit_error(payload; scale_method = :bogus)
            @test _names_keyword(err_bogus, dispatch, :scale_method)
        end
    end
end
