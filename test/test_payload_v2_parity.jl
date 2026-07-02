# test_payload_v2_parity.jl — P0.5 cross-lane round-trip parity
#
# Contract: docs/design/21-payload-v2-multiblock-schema.md (FREEZE-READY).
# No covered-status change; this contract-only slice does not change public_covered_count
# or the validation_status() row count.
#
# Each fixture is a JSON file written by:
#   hsquared/tests/fixtures/emit_payload_v2_fixtures.R
# We read the JSON, reconstruct the engine inputs, run parse_payload_v2 +
# fit_payload_v2, and assert:
#   (i)  dispatch symbol matches expected
#   (ii) round-trip VCs ≈ direct Julia fit (tight tolerance)
#   (iii) for fixture (a): result_payload_v2 byte-identical to result_payload(direct)
#
# Boundary reconciliation checks are embedded in each testset sub-section.

using HSquared
using Test
using JSON3
using LinearAlgebra
using SparseArrays

const FIXTURE_DIR = joinpath(@__DIR__, "fixtures", "payload_v2")

# ---------------------------------------------------------------------------
# Helpers: reconstruct Julia types from the JSON fixture format
# ---------------------------------------------------------------------------

"""
    _json_to_sparse(Z_json) → SparseMatrixCSC{Float64, Int}

Reconstruct a sparse matrix from the triplet encoding:
  {"i": [1-based rows], "j": [1-based cols], "v": [values], "nrow": ..., "ncol": ...}
"""
function _json_to_sparse(Z_json)
    i_raw = Int.(Z_json["i"])
    j_raw = Int.(Z_json["j"])
    v_raw = Float64.(Z_json["v"])
    nrow  = Int(Z_json["nrow"])
    ncol  = Int(Z_json["ncol"])
    return sparse(i_raw, j_raw, v_raw, nrow, ncol)
end

"""
    _json_to_dense(X_json) → Matrix{Float64}

Reconstruct a dense matrix from the flat row-major encoding:
  {"data": [...], "nrow": n, "ncol": p}
Julia receives data as a row-major flat vector; reshape and transpose.
"""
function _json_to_dense(X_json)
    data = Float64.(X_json["data"])
    nrow = Int(X_json["nrow"])
    ncol = Int(X_json["ncol"])
    # R writes row-major (t(M) → flat), so reshape → transpose to get n×p
    return Matrix{Float64}(reshape(data, ncol, nrow)')
end

"""
    _json_pedigree_to_dict(ped_json) → Dict{String, Any}

Convert JSON pedigree sub-object to the Dict form the parser expects.
JSON `null` values arrive as `nothing` in JSON3; `nothing ∈ DEFAULT_UNKNOWN_PARENT_VALUES`
so pedigree_inverse will treat them as unknown parents.
"""
function _json_pedigree_to_dict(ped_json)
    # JSON3 objects are iterable; convert to plain Dict.
    d = Dict{String, Any}()
    for k in keys(ped_json)
        v = ped_json[k]
        # Arrays of mixed String/nothing from JSON3 come as JSON3.Array.
        # collect() handles both plain vectors and JSON3.Array.
        d[string(k)] = v === nothing ? nothing : collect(v)
    end
    return d
end

"""
    _json_block_to_dict(blk_json) → Dict{String, Any}

Convert one JSON block entry to the Dict form parse_payload_v2 expects.
Reconstructs the sparse Z and (if present) pedigree sub-dict.
"""
function _json_block_to_dict(blk_json)
    d = Dict{String, Any}()
    d["name"]          = String(blk_json["name"])
    d["type"]          = String(blk_json["type"])
    d["relmat_status"] = String(blk_json["relmat_status"])
    d["ids"]           = collect(String, blk_json["ids"])
    d["Z"]             = _json_to_sparse(blk_json["Z"])

    # pedigree sub-dict: present for pedigree blocks, null for iid blocks.
    ped = get(blk_json, "pedigree", nothing)
    if ped !== nothing
        d["pedigree"] = _json_pedigree_to_dict(ped)
    else
        d["pedigree"] = nothing
    end

    # relmat_inverse is always null in our fixtures (Julia builds it).
    d["relmat_inverse"] = nothing

    return d
end

"""
    load_fixture(fname) → Dict{String, Any}

Load a payload_v2 JSON fixture and reconstruct all engine-ready inputs.
Returns a Dict suitable for parse_payload_v2.
"""
function load_fixture(fname)
    path = joinpath(FIXTURE_DIR, fname)
    isfile(path) || error("Fixture file not found: $path\n  " *
        "Run: Rscript tests/fixtures/emit_payload_v2_fixtures.R")
    raw = JSON3.read(read(path, String))

    # Build the payload dict for parse_payload_v2.
    payload = Dict{String, Any}()
    payload["payload_version"] = Int(raw["payload_version"])
    payload["y"]               = Float64.(raw["y"])
    payload["X"]               = _json_to_dense(raw["X"])
    payload["method"]          = String(raw["method"])

    re_raw = raw["random_effects"]
    payload["random_effects"] = [_json_block_to_dict(b) for b in re_raw]

    return payload
end

# ---------------------------------------------------------------------------
# Fixture (a): single-pedigree animal model
#   Formula (R): y ~ sex + animal(1 | id, pedigree = ped_abcd)
#   Dispatch expected: :animal
#   Back-compat check: result_payload_v2 byte-identical to result_payload(direct)
# ---------------------------------------------------------------------------

@testset "P0.5 payload-v2 parity — fixture (a) single animal model" begin
    payload_a = load_fixture("fixture_a_single_animal.json")

    # ---- 1. Parse + dispatch check ------------------------------------------
    parsed_a = parse_payload_v2(payload_a)
    @test parsed_a.dispatch == :animal
    @test length(parsed_a.blocks) == 1
    @test parsed_a.blocks[1].name == "animal"
    @test parsed_a.blocks[1].type == "pedigree"
    @test !parsed_a.is_multivariate

    # ---- 2. Round-trip fit via payload-v2 -----------------------------------
    fit_v2_a = fit_payload_v2(payload_a)
    @test fit_v2_a isa AnimalModelFit

    # ---- 3. Direct Julia fit on the same inputs ----------------------------
    # Reconstruct Ainv directly from the pedigree ids/sire/dam we know.
    # Pedigree: a,b are founders; c has parents a,b; d has parents a,c.
    # These match fixture (a): ids = ["a","b","c","d"], sire=[NA,NA,"a","a"], dam=[NA,NA,"b","c"]
    # The emitter uses hs_topological_pedigree which normalizes order, so use the
    # block's pedigree field as the ground truth.
    blk_a = parsed_a.blocks[1]
    Ainv_direct = blk_a.relmat_inverse  # already built by parse_payload_v2
    Z_direct    = blk_a.Z
    y_direct    = parsed_a.y
    X_direct    = parsed_a.X

    fit_direct_a = fit_animal_model(y_direct, X_direct,
                                    sparse(Matrix{Float64}(Z_direct)),
                                    sparse(Matrix{Float64}(Ainv_direct));
                                    ids = blk_a.ids, method = :REML)
    @test fit_direct_a isa AnimalModelFit

    # ---- 4. VC parity: round-trip == direct (tight tolerance) --------------
    vc_v2     = fit_v2_a.variance_components
    vc_direct = fit_direct_a.variance_components
    @test abs(vc_v2.sigma_a2 - vc_direct.sigma_a2) <= 1e-8 * max(1.0, abs(vc_direct.sigma_a2))
    @test abs(vc_v2.sigma_e2 - vc_direct.sigma_e2) <= 1e-8 * max(1.0, abs(vc_direct.sigma_e2))

    max_abs_a  = max(abs(vc_v2.sigma_a2 - vc_direct.sigma_a2),
                     abs(vc_v2.sigma_e2 - vc_direct.sigma_e2))
    max_rel_a  = max(
        abs(vc_v2.sigma_a2 - vc_direct.sigma_a2) / max(eps(), abs(vc_direct.sigma_a2)),
        abs(vc_v2.sigma_e2 - vc_direct.sigma_e2) / max(eps(), abs(vc_direct.sigma_e2))
    )
    @info "Fixture (a) VC diff" max_abs=max_abs_a max_rel=max_rel_a

    # ---- 5. v0.1 byte-identity: result_payload_v2 == result_payload(direct) -
    res_v2     = result_payload_v2(fit_v2_a, parsed_a)
    res_direct = result_payload(fit_direct_a)
    # Both are AnimalModelFit: the v2 fast path must delegate to result_payload.
    @test res_v2.variance_components.sigma_a2 === res_direct.variance_components.sigma_a2
    @test res_v2.heritability ≈ res_direct.heritability
    @test res_v2.loglik ≈ res_direct.loglik
    @test res_v2.converged == res_direct.converged
    @test res_v2.random_effects.animal.ids == res_direct.random_effects.animal.ids
    @test res_v2.random_effects.animal.values ≈ res_direct.random_effects.animal.values

    # strict floating-point identity (same computation path):
    @test res_v2.variance_components.sigma_a2 === res_direct.variance_components.sigma_a2
    @test res_v2.variance_components.sigma_e2 === res_direct.variance_components.sigma_e2
    @test res_v2.loglik === res_direct.loglik
    @info "Fixture (a) byte-identity" sigma_a2_identical=(res_v2.variance_components.sigma_a2 === res_direct.variance_components.sigma_a2)

    # ---- 6. Boundary check: pedigree null-to-nothing roundtrip --------------
    # The R emitter writes NA parents as JSON null; JSON3 reads them as nothing.
    # normalize_pedigree must accept nothing in the sire/dam vectors.
    # This is implicitly proven by the above fit passing (Ainv was built OK).
    @test size(Ainv_direct, 1) == length(blk_a.ids)
end

# ---------------------------------------------------------------------------
# Fixture (b): animal + common_env()  → :two_effect
#   Formula (R): y ~ animal(1 | id, pedigree = ped_abcd) + common_env(1 | litter)
#   Dispatch expected: :two_effect
#   Block 2 must be iid (relmat_status = "identity") and have 2 litter levels.
# ---------------------------------------------------------------------------

@testset "P0.5 payload-v2 parity — fixture (b) animal + common_env" begin
    payload_b = load_fixture("fixture_b_animal_common_env.json")

    # ---- 1. Parse + dispatch check ------------------------------------------
    parsed_b = parse_payload_v2(payload_b)
    @test parsed_b.dispatch == :two_effect
    @test length(parsed_b.blocks) == 2
    @test parsed_b.blocks[1].name == "animal"
    @test parsed_b.blocks[2].name == "common_env"
    @test parsed_b.blocks[2].type == "iid"
    @test size(parsed_b.blocks[2].relmat_inverse, 1) == length(parsed_b.blocks[2].ids)

    # ---- 2. Round-trip fit --------------------------------------------------
    fit_v2_b = fit_payload_v2(payload_b)
    @test fit_v2_b.converged

    # ---- 3. Direct Julia fit -----------------------------------------------
    b1_b = parsed_b.blocks[1]
    b2_b = parsed_b.blocks[2]
    y_b  = parsed_b.y
    X_b  = parsed_b.X

    fit_direct_b = fit_two_effect_reml(y_b, X_b,
                                        Matrix{Float64}(b1_b.Z),
                                        Matrix{Float64}(b1_b.relmat_inverse),
                                        Matrix{Float64}(b2_b.Z),
                                        Matrix{Float64}(b2_b.relmat_inverse))
    @test fit_direct_b.converged

    # ---- 4. VC parity -------------------------------------------------------
    vc_v2_b     = fit_v2_b.variance_components
    vc_direct_b = fit_direct_b.variance_components
    @test abs(vc_v2_b.sigma1    - vc_direct_b.sigma1)    <= 1e-8 * max(1.0, abs(vc_direct_b.sigma1))
    @test abs(vc_v2_b.sigma2    - vc_direct_b.sigma2)    <= 1e-8 * max(1.0, abs(vc_direct_b.sigma2))
    @test abs(vc_v2_b.sigma_e2  - vc_direct_b.sigma_e2)  <= 1e-8 * max(1.0, abs(vc_direct_b.sigma_e2))

    max_abs_b = max(abs(vc_v2_b.sigma1 - vc_direct_b.sigma1),
                    abs(vc_v2_b.sigma2 - vc_direct_b.sigma2),
                    abs(vc_v2_b.sigma_e2 - vc_direct_b.sigma_e2))
    max_rel_b = max(
        abs(vc_v2_b.sigma1   - vc_direct_b.sigma1)   / max(eps(), abs(vc_direct_b.sigma1)),
        abs(vc_v2_b.sigma2   - vc_direct_b.sigma2)   / max(eps(), abs(vc_direct_b.sigma2)),
        abs(vc_v2_b.sigma_e2 - vc_direct_b.sigma_e2) / max(eps(), abs(vc_direct_b.sigma_e2))
    )
    @info "Fixture (b) VC diff" max_abs=max_abs_b max_rel=max_rel_b

    # ---- 5. result_payload_v2 structured result -----------------------------
    res_v2_b = result_payload_v2(fit_v2_b, parsed_b)
    @test hasproperty(res_v2_b, :variance_components)
    @test hasproperty(res_v2_b.variance_components, :residual)
    @test hasproperty(res_v2_b.variance_components, :blocks)
    @test length(res_v2_b.variance_components.blocks) == 2
    @test res_v2_b.variance_components.blocks[1].name == "animal"
    @test res_v2_b.variance_components.blocks[2].name == "common_env"
    @test res_v2_b.variance_components.blocks[1].variance ≈ vc_direct_b.sigma1
    @test res_v2_b.variance_components.blocks[2].variance ≈ vc_direct_b.sigma2
    @test res_v2_b.variance_components.residual ≈ vc_direct_b.sigma_e2

    # ---- 6. Boundary: iid block has correct relmat_inverse (identity) -------
    @test b2_b.relmat_inverse ≈ I   # sparse identity over L=2 litter levels
    @test size(b2_b.relmat_inverse) == (2, 2)

    # ---- 7. Boundary: K=2 iid+pedigree dispatches :two_effect (not :multi_effect)
    # This is enforced in _resolve_dispatch: K==2 → :two_effect.
    # If it incorrectly dispatched :multi_effect, fit_payload_v2 would call
    # fit_multi_effect_reml and the VC field names would differ. The vc_v2_b
    # field-name test above already proves the dispatch was :two_effect.
    @test parsed_b.dispatch == :two_effect  # re-assert for clarity
end

# ---------------------------------------------------------------------------
# Fixture (c): animal + permanent()  → :two_effect
#   Formula (R): y ~ animal(1 | id, pedigree = ped_abc) + permanent(1 | id)
#   Dispatch expected: :two_effect
#   Key boundary: permanent ids = observed subset (3 < pedigree could be larger)
#                 permanent Z is the same sparse matrix as animal Z
#                 legacy Z2 / effect2 are NULL (permanent uses Z, not Z2)
# ---------------------------------------------------------------------------

@testset "P0.5 payload-v2 parity — fixture (c) animal + permanent" begin
    payload_c = load_fixture("fixture_c_animal_permanent.json")

    # ---- 1. Parse + dispatch check ------------------------------------------
    parsed_c = parse_payload_v2(payload_c)
    @test parsed_c.dispatch == :two_effect
    @test length(parsed_c.blocks) == 2
    @test parsed_c.blocks[1].name == "animal"
    @test parsed_c.blocks[2].name == "permanent"
    @test parsed_c.blocks[2].type == "iid"

    # ---- 2. Boundary: permanent ids = observed subset ----------------------
    # The R emitter sets permanent ids = unique(as.character(permanent$values))
    # which is the OBSERVED subset, not the full pedigree.  The parser must NOT
    # assume len(ids) == pedigree size; it must size relmat_inverse to len(ids).
    b_perm = parsed_c.blocks[2]
    n_perm = length(b_perm.ids)
    @test size(b_perm.relmat_inverse) == (n_perm, n_perm)
    # Z has q columns = number of observed animals (same as animal block here
    # since ped_abc has 3 animals all observed).
    @test size(b_perm.Z, 2) == n_perm

    # ---- 3. Boundary: permanent Z == animal Z (same sparse matrix content) -
    b_anim = parsed_c.blocks[1]
    @test Matrix{Float64}(b_anim.Z) ≈ Matrix{Float64}(b_perm.Z)

    # ---- 4. Round-trip fit --------------------------------------------------
    fit_v2_c = fit_payload_v2(payload_c)
    @test fit_v2_c.converged

    # ---- 5. Direct Julia fit -----------------------------------------------
    y_c  = parsed_c.y
    X_c  = parsed_c.X

    fit_direct_c = fit_two_effect_reml(y_c, X_c,
                                        Matrix{Float64}(b_anim.Z),
                                        Matrix{Float64}(b_anim.relmat_inverse),
                                        Matrix{Float64}(b_perm.Z),
                                        Matrix{Float64}(b_perm.relmat_inverse))
    @test fit_direct_c.converged

    # ---- 6. VC parity -------------------------------------------------------
    vc_v2_c     = fit_v2_c.variance_components
    vc_direct_c = fit_direct_c.variance_components
    @test abs(vc_v2_c.sigma1   - vc_direct_c.sigma1)   <= 1e-8 * max(1.0, abs(vc_direct_c.sigma1))
    @test abs(vc_v2_c.sigma2   - vc_direct_c.sigma2)   <= 1e-8 * max(1.0, abs(vc_direct_c.sigma2))
    @test abs(vc_v2_c.sigma_e2 - vc_direct_c.sigma_e2) <= 1e-8 * max(1.0, abs(vc_direct_c.sigma_e2))

    max_abs_c = max(abs(vc_v2_c.sigma1 - vc_direct_c.sigma1),
                    abs(vc_v2_c.sigma2 - vc_direct_c.sigma2),
                    abs(vc_v2_c.sigma_e2 - vc_direct_c.sigma_e2))
    max_rel_c = max(
        abs(vc_v2_c.sigma1   - vc_direct_c.sigma1)   / max(eps(), abs(vc_direct_c.sigma1)),
        abs(vc_v2_c.sigma2   - vc_direct_c.sigma2)   / max(eps(), abs(vc_direct_c.sigma2)),
        abs(vc_v2_c.sigma_e2 - vc_direct_c.sigma_e2) / max(eps(), abs(vc_direct_c.sigma_e2))
    )
    @info "Fixture (c) VC diff" max_abs=max_abs_c max_rel=max_rel_c

    # ---- 7. result_payload_v2 structured result -----------------------------
    res_v2_c = result_payload_v2(fit_v2_c, parsed_c)
    @test hasproperty(res_v2_c, :variance_components)
    @test length(res_v2_c.variance_components.blocks) == 2
    @test res_v2_c.variance_components.blocks[1].name == "animal"
    @test res_v2_c.variance_components.blocks[2].name == "permanent"
    @test res_v2_c.variance_components.blocks[1].variance ≈ vc_direct_c.sigma1
    @test res_v2_c.variance_components.blocks[2].variance ≈ vc_direct_c.sigma2
end
