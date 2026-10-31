# hsquared#266 (option 1): an OPT-IN switch on the pedigree result payload that skips
# the eager prediction error variance (PEV) and reliability summaries. At N = 50,000
# they cost 530 s of a 2,009 s warm R call (hsquared#266, perf-se lane), with no way
# for the R user to defer them. The default stays eager and byte-identical: the
# first testset pins the exact default payload so a future edit cannot silently make
# it lazy. With `skip_pev_reliability = true` the two fields are absent, the shape
# an older engine returned and the R bridge already handles; every other field is
# unchanged.

using HSquared
using SparseArrays
using Test

function _fit_266(fitter)
    ped = HSquared.normalize_pedigree(1:6, [0, 0, 1, 1, 3, 3], [0, 0, 2, 2, 4, 4])
    Ainv = HSquared.pedigree_inverse(ped)
    Z = spzeros(12, 6)
    for r in 1:12
        Z[r, cld(r, 2)] = 1.0
    end
    y = [10.2, 9.8, 11.5, 12.0, 8.7, 9.4, 10.9, 11.3, 12.4, 11.8, 9.9, 10.6]
    X = ones(12, 1)
    return fitter(y, X, Z, Ainv)
end

const _DEFAULT_FIELDS_266 = (
    :variance_components, :heritability, :breeding_values, :fixed_effects,
    :random_effects, :loglik, :df, :nobs, :predictions,
    :prediction_error_variance, :reliability, :diagnostics, :converged,
)

@testset "hsquared#266 skip_pev_reliability (opt-in, default eager)" begin
    for (label, fitter) in (
            ("fit_animal_model", (y, X, Z, A) -> fit_animal_model(y, X, Z, A; method = :REML)),
            ("fit_ai_reml", (y, X, Z, A) -> fit_ai_reml(animal_model_spec(y, X, Z, A; method = :REML))),
        )
        fit = _fit_266(fitter)
        @testset "$label: default payload is unchanged" begin
            default = result_payload(fit)
            @test propertynames(default) == _DEFAULT_FIELDS_266
            @test isequal(default, result_payload(fit; skip_pev_reliability = false))
            pev = prediction_error_variance(fit; method = :auto)
            rel = reliability(fit; method = :auto, pev = pev)
            @test isequal(default.prediction_error_variance, (ids = pev.ids, values = pev.values))
            @test isequal(default.reliability, (ids = rel.ids, values = rel.values))
        end
        @testset "$label: opt-in skips PEV and reliability only" begin
            default = result_payload(fit)
            lean = result_payload(fit; skip_pev_reliability = true)
            @test !hasproperty(lean, :prediction_error_variance)
            @test !hasproperty(lean, :reliability)
            kept = Tuple(f for f in _DEFAULT_FIELDS_266
                         if f ∉ (:prediction_error_variance, :reliability))
            @test propertynames(lean) == kept
            for f in kept
                @test isequal(getproperty(lean, f), getproperty(default, f))
            end
        end
    end

    @testset "result_payload_v2 :animal fast path passes the switch through" begin
        payload = Dict(
            "y" => [10.2, 9.8, 11.5, 12.0, 8.7, 9.4, 10.9, 11.3, 12.4, 11.8, 9.9, 10.6],
            "X" => ones(12, 1),
            "Z" => Matrix(sparse(1:12, cld.(1:12, 2), ones(12), 12, 6)),
            "pedigree" => Dict("id" => collect(1:6), "sire" => [0, 0, 1, 1, 3, 3],
                               "dam" => [0, 0, 2, 2, 4, 4]),
            "metadata" => Dict("ainv_status" => "build_in_julia"),
        )
        parsed = parse_payload_v2(payload)
        @test parsed.dispatch == :animal
        fit = fit_payload_v2(payload)
        @test isequal(result_payload_v2(fit, parsed), result_payload(fit))
        lean = result_payload_v2(fit, parsed; skip_pev_reliability = true)
        @test isequal(lean, result_payload(fit; skip_pev_reliability = true))
        @test !hasproperty(lean, :prediction_error_variance)
    end
end
