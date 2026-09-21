# test_relationship_diag_1pF.jl -- the reliability denominator from 1 + F
#
# `reliability` needs the animal self-relationships diag(A) = diag(inv(Ainv)). #350
# reads them through a selected inverse of Ainv, whose cost is Θ(Σⱼ|L[:,j]|²) over
# the factor of Ainv. For a pedigree Ainv they are 1 + F_i, and `pedigree_inverse`
# already runs Meuwissen & Luo for F (Henderson's rules need F of every parent), so
# the diagonal is free wherever Julia builds Ainv from pedigree rows. The spec now
# carries it (`relationship_diag`) and `:auto` reads it; explicit `:selinv` / `:dense`
# stay the parity oracles.
#
# Pinned here: (i) `_pedigree_inverse_and_inbreeding` returns Ainv byte-identical to
# `pedigree_inverse` and F identical to `inbreeding_coefficients`; (ii) with the
# diagonal attached, `reliability(fit)` (`:auto`) takes it by identity and equals the
# `:selinv` and `:dense` reliabilities to 1e-10 on an inbred pedigree; (iii) the spec
# refuses a diagonal of the wrong length or with a non-positive entry; (iv) a
# payload-v2 single-pedigree fit built in Julia carries 1 + F in Ainv's own row
# order and its payload reliability equals the selected-inverse one to 1e-10.

using HSquared
using LinearAlgebra
using SparseArrays
using Random
using Test

# Discrete generations, parents drawn at random from the previous generation's
# 8 sires and 24 dams, so relatives mate and F > 0 from generation 3 on.
function _inbred_pedigree_1pF(ngen::Int, per_gen::Int; seed::Integer = 1)
    rng = MersenneTwister(seed)
    ids = String[]; sire = String[]; dam = String[]
    prev = String[]
    for g in 1:ngen
        cur = ["g$(g)_$(k)" for k in 1:per_gen]
        for id in cur
            push!(ids, id)
            if g == 1
                push!(sire, "0"); push!(dam, "0")
            else
                push!(sire, prev[rand(rng, 1:8)])
                push!(dam, prev[rand(rng, 9:32)])
            end
        end
        prev = cur
    end
    return ids, sire, dam
end

function _signal_records_1pF(ped, Ainv; seed::Integer = 11, sa2 = 0.5, se2 = 0.5)
    rng = MersenneTwister(seed)
    q = size(Ainv, 1)
    a = cholesky(Symmetric(Matrix(inv(Matrix(Ainv))))).L * randn(rng, q) .* sqrt(sa2)
    n = 2q
    Z = sparse(1:n, repeat(1:q, inner = 2), 1.0, n, q)
    y = Z * a .+ sqrt(se2) .* randn(rng, n)
    return y, ones(n, 1), Z
end

@testset "1+F (i): pedigree_inverse exposes the F it was built from, unchanged" begin
    ids, sire, dam = _inbred_pedigree_1pF(6, 40)
    ped = HSquared.normalize_pedigree(ids, sire, dam)
    Ainv, F = HSquared._pedigree_inverse_and_inbreeding(ped)
    Ainv_ref = HSquared.pedigree_inverse(ped)
    @test Ainv.colptr == Ainv_ref.colptr && Ainv.rowval == Ainv_ref.rowval
    @test reinterpret(UInt64, Ainv.nzval) == reinterpret(UInt64, Ainv_ref.nzval)
    @test F == HSquared.inbreeding_coefficients(ped)
    @test any(F .> 0)                                   # the fixture is inbred
end

@testset "1+F (ii): :auto reads the attached diagonal; equals :selinv and :dense" begin
    ids, sire, dam = _inbred_pedigree_1pF(6, 40)
    ped = HSquared.normalize_pedigree(ids, sire, dam)
    Ainv, F = HSquared._pedigree_inverse_and_inbreeding(ped)
    y, X, Z = _signal_records_1pF(ped, Ainv)
    spec = HSquared.animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML,
                                      relationship_diag = 1 .+ F)
    fit = HSquared.fit_ai_reml(spec)
    @test fit.converged
    @test fit.spec.relationship_diag == 1 .+ F
    @test HSquared._relationship_diag(fit.spec, :auto) === fit.spec.relationship_diag
    @test maximum(abs.(HSquared._relationship_diag(fit.spec, :selinv) .- (1 .+ F))) <= 1e-10

    rel_auto = HSquared.reliability(fit).values
    rel_selinv = HSquared.reliability(fit; method = :selinv).values
    rel_dense = HSquared.reliability(fit; method = :dense).values
    @test maximum(abs.(rel_auto .- rel_selinv)) <= 1e-10
    @test maximum(abs.(rel_auto .- rel_dense)) <= 1e-10

    # without the diagonal nothing changes: :auto falls back to the selected inverse
    spec0 = HSquared.animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
    @test spec0.relationship_diag === nothing
    fit0 = HSquared.fit_ai_reml(spec0)
    @test fit0.variance_components == fit.variance_components
    @test maximum(abs.(HSquared.reliability(fit0).values .- rel_auto)) <= 1e-10
end

@testset "1+F (iii): the spec validates the supplied diagonal" begin
    ids, sire, dam = _inbred_pedigree_1pF(3, 40)
    ped = HSquared.normalize_pedigree(ids, sire, dam)
    Ainv, F = HSquared._pedigree_inverse_and_inbreeding(ped)
    y, X, Z = _signal_records_1pF(ped, Ainv)
    @test_throws ArgumentError HSquared.animal_model_spec(y, X, Z, Ainv;
        relationship_diag = (1 .+ F)[1:end-1])
    bad = 1 .+ F; bad[3] = 0.0
    @test_throws ArgumentError HSquared.animal_model_spec(y, X, Z, Ainv; relationship_diag = bad)
    bad[3] = NaN
    @test_throws ArgumentError HSquared.animal_model_spec(y, X, Z, Ainv; relationship_diag = bad)
end

@testset "1+F (iv): payload-v2 pedigree built in Julia carries 1 + F in Ainv's order" begin
    ids, sire, dam = _inbred_pedigree_1pF(5, 40; seed = 7)
    ped = HSquared.normalize_pedigree(ids, sire, dam)
    Ainv_ref, F_ref = HSquared._pedigree_inverse_and_inbreeding(ped)
    y, X, Z = _signal_records_1pF(ped, Ainv_ref; seed = 71)
    payload = Dict(
        "payload_version" => 2,
        "y" => y,
        "X" => X,
        "random_effects" => [
            Dict("name" => "animal", "type" => "pedigree", "Z" => Matrix(Z),
                 "relmat_status" => "build_in_julia",
                 "pedigree" => Dict("id" => ids, "sire" => sire, "dam" => dam),
                 "ids" => ped.ids),
        ],
    )
    parsed = HSquared.parse_payload_v2(payload)
    b = parsed.blocks[1]
    @test b.relationship_diag == 1 .+ F_ref
    @test maximum(abs.(HSquared._relationship_diag(b.relmat_inverse, :selinv) .- b.relationship_diag)) <= 1e-10

    fit = HSquared.fit_payload_v2(payload)
    @test fit.spec.relationship_diag == 1 .+ F_ref
    out = HSquared.result_payload_v2(fit, parsed)
    rel_selinv = HSquared.reliability(fit; method = :selinv).values
    @test maximum(abs.(out.reliability.values .- rel_selinv)) <= 1e-10

    # a supplied Ainv carries no diagonal: :auto keeps the selected inverse
    payload_s = deepcopy(payload)
    payload_s["random_effects"][1]["relmat_status"] = "supplied"
    payload_s["random_effects"][1]["relmat_inverse"] = Ainv_ref
    @test HSquared.parse_payload_v2(payload_s).blocks[1].relationship_diag === nothing
end
