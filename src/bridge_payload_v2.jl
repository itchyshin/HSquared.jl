# bridge_payload_v2.jl — P0.3 Julia-side payload-v2 parser + dispatcher
#
# Contract: §6 of docs/design/21-payload-v2-multiblock-schema.md (FREEZE-READY).
# This file is CONTRACT-ONLY: it reuses existing estimators, adds no new
# numerics, and makes no covered-status change.  `public_covered_count` stays 1.
# `validation_status()` row count stays 52.
#
# Three public functions are exported from HSquared.jl:
#   parse_payload_v2(payload)  → ParsedPayloadV2 (resolved engine inputs + dispatch tag)
#   fit_payload_v2(payload)    → fit NamedTuple from the dispatched estimator
#   result_payload_v2(fit, parsed) → block-structured result (with single-block fast path)

"""
    ParsedPayloadV2

Internal struct produced by `parse_payload_v2`.  Carries the engine inputs ready
to hand to the dispatched estimator, plus the dispatch tag and per-block metadata.

Fields:
- `dispatch`       — Symbol: `:animal`, `:two_effect`, `:multi_effect`, `:direct_maternal`,
                     `:multivariate`, or `:coefcov` (frozen slot, not yet wired).
- `y` / `Y`        — response vector (univariate) or matrix (multivariate).
- `X`              — fixed-effects design matrix.
- `blocks`         — Vector of per-block NamedTuples with resolved engine matrices
                     `(name, type, Z, relmat_inverse, ids)`.  For `correlated` blocks:
                     also `partner_incidence` and `partner_name`.
- `method`         — Symbol `:REML` or `:ML`.
- `is_multivariate`— Bool.
"""
struct ParsedPayloadV2
    dispatch::Symbol
    y::Union{AbstractVector, Nothing}      # univariate
    Y::Union{AbstractMatrix, Nothing}      # multivariate
    X::AbstractMatrix
    blocks::Vector                          # Vector of NamedTuples
    method::Symbol
    is_multivariate::Bool
end

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

# Coerce a payload field that may arrive as a Symbol, String, or missing.
_sym(x::Symbol)  = x
_sym(x::AbstractString) = Symbol(x)
_sym(::Nothing)  = nothing
_sym(x) = x

# Build a sparse identity for an iid block.  §2, note on type="iid":
# "Julia uses I (never materializes the q_i × q_i identity)."
# We build a SparseMatrixCSC so the existing estimators receive a concrete type.
function _build_iid_relmat_inverse(q::Integer)
    return sparse(I, q, q)
end

# Build Ainv from pedigree rows packed in a block.  §2 note on type="pedigree":
# "relmat_status = 'build_in_julia' + pedigree rows + ids = ped.ids".
# The block's `pedigree` field is a Dict/NamedTuple with fields
# `id`, `sire`, `dam` (matching the top-level pedigree row shape in §2).
function _build_ainv_from_block_pedigree(ped)
    # Accept both Dict (JuliaCall) and NamedTuple forms.
    ids_raw  = _field(ped, "id",   :id)
    sire_raw = _field(ped, "sire", :sire)
    dam_raw  = _field(ped, "dam",  :dam)
    ids_raw  === nothing && throw(ArgumentError("pedigree block missing field 'id'"))
    sire_raw === nothing && throw(ArgumentError("pedigree block missing field 'sire'"))
    dam_raw  === nothing && throw(ArgumentError("pedigree block missing field 'dam'"))
    return pedigree_inverse(collect(ids_raw), collect(sire_raw), collect(dam_raw))
end

# Flexible field accessor: checks string key then symbol key; returns nothing if absent.
function _field(d, str_key, sym_key)
    d isa AbstractDict && haskey(d, str_key) && return d[str_key]
    d isa AbstractDict && haskey(d, sym_key)  && return d[sym_key]
    hasproperty(d, sym_key) && return getproperty(d, sym_key)
    return nothing
end

# Resolve the relmat_inverse for one block.  §2 field table.
function _resolve_relmat_inverse(block, Z)
    status = _field(block, "relmat_status", :relmat_status)
    status = status === nothing ? "build_in_julia" : string(status)

    if status == "identity"
        q = size(Z, 2)
        return _build_iid_relmat_inverse(q)
    elseif status == "build_in_julia"
        ped = _field(block, "pedigree", :pedigree)
        ped === nothing && throw(ArgumentError(
            "block with relmat_status='build_in_julia' must supply a 'pedigree' field"))
        return _build_ainv_from_block_pedigree(ped)
    elseif status == "supplied"
        ri = _field(block, "relmat_inverse", :relmat_inverse)
        ri === nothing && throw(ArgumentError(
            "block with relmat_status='supplied' must supply 'relmat_inverse'"))
        return ri
    else
        throw(ArgumentError("unknown relmat_status: '$status'"))
    end
end

# Parse a single block dict/namedtuple into a resolved NamedTuple.
function _parse_one_block(block)
    name = string(_field(block, "name", :name))
    btype = string(_field(block, "type", :type))
    btype in ("pedigree", "iid", "coefcov", "correlated") ||
        throw(ArgumentError("unknown block type '$btype'; expected pedigree, iid, coefcov, or correlated"))

    Z_raw = _field(block, "Z", :Z)
    Z_raw === nothing && throw(ArgumentError("block '$name' is missing field 'Z'"))
    Z = Z_raw isa AbstractMatrix ? Z_raw : Matrix{Float64}(Z_raw)

    relmat_inverse = _resolve_relmat_inverse(block, Z)

    # §2: ids field for this block (level ids vector)
    ids_raw = _field(block, "ids", :ids)
    block_ids = ids_raw === nothing ? collect(1:size(Z, 2)) : collect(ids_raw)

    if btype == "correlated"
        # §2 correlated block: Z → Zd, partner_incidence → Zm.
        Zm_raw = _field(block, "partner_incidence", :partner_incidence)
        Zm_raw === nothing && throw(ArgumentError(
            "correlated block '$name' is missing 'partner_incidence'"))
        Zm = Zm_raw isa AbstractMatrix ? Zm_raw : Matrix{Float64}(Zm_raw)
        partner_name = _field(block, "partner_name", :partner_name)
        return (name=name, type=btype, Z=Z, relmat_inverse=relmat_inverse,
                ids=block_ids, Zm=Zm, partner_name=string(partner_name))
    else
        return (name=name, type=btype, Z=Z, relmat_inverse=relmat_inverse, ids=block_ids)
    end
end

# ---------------------------------------------------------------------------
# Dispatch resolution — §6 dispatch table
# ---------------------------------------------------------------------------

# Determine dispatch symbol from the resolved block list.
# §6:
#   one pedigree/identity block → :animal
#   two independent blocks → :two_effect
#   K ≥ 3 independent blocks → :multi_effect
#   one correlated block (+ optional independent) → :direct_maternal
#   multivariate Y (one pedigree) → :multivariate (caller must pass is_mv=true)
#   one coefcov block → :coefcov (frozen slot, parser validates but doesn't run)
function _resolve_dispatch(blocks, is_multivariate::Bool)
    types = [b.type for b in blocks]
    n_correlated = count(==("correlated"), types)
    n_independent = count(t -> t in ("pedigree", "iid"), types)
    n_coefcov = count(==("coefcov"), types)
    K = length(blocks)

    if n_correlated > 1
        throw(ArgumentError(
            "cannot dispatch: more than one 'correlated' block is not supported"))
    end

    if n_correlated == 1 && n_coefcov > 0
        throw(ArgumentError(
            "cannot dispatch: mixing 'correlated' and 'coefcov' blocks is not supported"))
    end

    if n_coefcov > 1
        throw(ArgumentError(
            "cannot dispatch: more than one 'coefcov' block is not supported"))
    end

    if K == 0
        throw(ArgumentError("random_effects list is empty"))
    end

    # Correlated block present → direct-maternal estimator (§6 row 4).
    # The independent blocks (if any) are silently carried; in the current
    # implementation only the single-correlated-only form is fully wired,
    # matching fit_direct_maternal_reml's signature (y, X, Zd, Zm, Ainv).
    # A mixed correlated+independent combination is flagged as unsupported
    # so the parser fails clearly rather than silently dropping blocks.
    if n_correlated == 1
        if n_independent > 0
            throw(ArgumentError(
                "cannot dispatch: combining a 'correlated' block with independent blocks " *
                "is not yet wired (no estimator accepts both a 2×2 G_dm and additional " *
                "independent effects); revise the payload to separate them"))
        end
        return :direct_maternal
    end

    # coefcov slot: frozen, parser validates block but we cannot dispatch yet (§6).
    if n_coefcov == 1
        return :coefcov
    end

    # Independent blocks only.
    if is_multivariate
        K == 1 || throw(ArgumentError(
            "multivariate dispatch requires exactly one random-effect block"))
        return :multivariate
    end

    if K == 1
        return :animal
    elseif K == 2
        return :two_effect
    else
        return :multi_effect
    end
end

# ---------------------------------------------------------------------------
# Public: parse_payload_v2
# ---------------------------------------------------------------------------

"""
    parse_payload_v2(payload) → ParsedPayloadV2

Parse a payload-v2 request object (a `Dict`, `NamedTuple`, or any property-
accessible container from JuliaCall) and return a `ParsedPayloadV2` struct
carrying resolved engine inputs and the chosen dispatch symbol.

Implements the §4 back-compat alias: a v0.1 payload (top-level `Z`/`Ainv`,
no `payload_version` or `payload_version = 1L`) is lifted to a single
`pedigree` block with `relmat_status = "build_in_julia"`.

Implements the §4 transition alias: a payload with legacy `Z`/`Z2`/`effect2`
but no `random_effects` is lifted to a two-block list.

The §2 grammar table governs which block types are accepted; unknown types
raise an `ArgumentError`.

CONTRACT-ONLY (docs/design/21-payload-v2-multiblock-schema.md §6):
no new estimator is added here.
"""
function parse_payload_v2(payload)
    # --- Resolve payload_version ---
    pv_raw = _field(payload, "payload_version", :payload_version)
    payload_version = pv_raw === nothing ? 1 : Int(pv_raw)

    # --- Response ---
    Y_raw = _field(payload, "Y", :Y)
    y_raw = _field(payload, "y", :y)
    is_multivariate = Y_raw !== nothing
    if is_multivariate
        Y = Y_raw isa AbstractMatrix ? Y_raw : Matrix{Float64}(Y_raw)
        y = nothing
    else
        y_raw === nothing && throw(ArgumentError("payload must supply 'y' (univariate) or 'Y' (multivariate)"))
        y = y_raw isa AbstractVector ? y_raw : vec(Float64.(y_raw))
        Y = nothing
    end

    # --- X ---
    X_raw = _field(payload, "X", :X)
    X_raw === nothing && throw(ArgumentError("payload must supply 'X'"))
    X = X_raw isa AbstractMatrix ? X_raw : Matrix{Float64}(X_raw)

    # --- method ---
    method_raw = _field(payload, "method", :method)
    method_sym = method_raw === nothing ? :REML : Symbol(uppercase(string(method_raw)))

    # --- Build random_effects block list ---
    re_raw = _field(payload, "random_effects", :random_effects)

    if payload_version <= 1 || re_raw === nothing
        # §4 back-compat alias: lift the flat v0.1 / two-effect shape.
        blocks = _lift_legacy_payload(payload)
    else
        # v2 path: parse the random_effects list.
        re_list = _coerce_to_list(re_raw)
        isempty(re_list) && throw(ArgumentError("random_effects list is empty"))
        blocks = [_parse_one_block(b) for b in re_list]
    end

    # --- Validate all blocks ---
    # Check: no two blocks share the same name (would break result labelling).
    names_seen = Set{String}()
    for b in blocks
        b.name in names_seen && throw(ArgumentError(
            "duplicate block name '$(b.name)' in random_effects; block names must be unique"))
        push!(names_seen, b.name)
    end

    # --- Dimension check: Z rows must equal number of observations ---
    n = is_multivariate ? size(Y, 1) : length(y)
    for b in blocks
        size(b.Z, 1) == n || throw(ArgumentError(
            "block '$(b.name)': Z has $(size(b.Z, 1)) rows but response has $n observations"))
        size(b.Z, 2) == size(b.relmat_inverse, 1) || throw(ArgumentError(
            "block '$(b.name)': Z columns ($(size(b.Z, 2))) do not match " *
            "relmat_inverse dimension ($(size(b.relmat_inverse, 1)))"))
        if b.type == "correlated"
            size(b.Zm, 1) == n || throw(ArgumentError(
                "block '$(b.name)' partner_incidence has $(size(b.Zm, 1)) rows but response has $n observations"))
            size(b.Zm, 2) == size(b.relmat_inverse, 1) || throw(ArgumentError(
                "block '$(b.name)' partner_incidence columns ($(size(b.Zm, 2))) must match " *
                "relmat_inverse dimension ($(size(b.relmat_inverse, 1)))"))
        end
    end

    dispatch = _resolve_dispatch(blocks, is_multivariate)

    return ParsedPayloadV2(dispatch, y, Y, X, blocks, method_sym, is_multivariate)
end

# Coerce whatever JuliaCall delivers (Vector, Dict-of-numbered-keys, ...) to a plain Vector.
function _coerce_to_list(x)
    x isa AbstractVector && return x
    # If it's a Tuple, convert it
    x isa Tuple && return collect(x)
    # Fallback: try collect (covers iterables)
    return collect(x)
end

# §4 back-compat: lift flat v0.1 / v0.1-two-effect payload into block list.
function _lift_legacy_payload(payload)
    Z_raw = _field(payload, "Z", :Z)
    Z_raw === nothing && throw(ArgumentError(
        "legacy (v0.1) payload must supply top-level 'Z'"))
    Z = Z_raw isa AbstractMatrix ? Z_raw : Matrix{Float64}(Z_raw)

    # §4: top-level pedigree rows (same as today's bridge, bridge-payload.R:101-108).
    ped = _field(payload, "pedigree", :pedigree)

    # relmat_status from top-level metadata (bridge-payload.R:137 sets ainv_status).
    meta = _field(payload, "metadata", :metadata)
    ainv_status = meta !== nothing ? _field(meta, "ainv_status", :ainv_status) : nothing
    if ainv_status === nothing
        # fallback: if no ainv_status and no pedigree, treat as identity
        ainv_status = ped !== nothing ? "build_in_julia" : "identity"
    end

    ids_raw = _field(payload, "ids", :ids)
    block_ids = ids_raw === nothing ? collect(1:size(Z, 2)) : collect(ids_raw)

    # Build first block
    q = size(Z, 2)
    if string(ainv_status) == "build_in_julia"
        ped === nothing && throw(ArgumentError(
            "legacy payload with ainv_status='build_in_julia' must supply 'pedigree'"))
        Ainv = _build_ainv_from_block_pedigree(ped)
    elseif string(ainv_status) == "supplied"
        Ainv_raw = _field(payload, "Ainv", :Ainv)
        Ainv_raw === nothing && throw(ArgumentError(
            "legacy payload with ainv_status='supplied' must supply 'Ainv'"))
        Ainv = Ainv_raw isa AbstractMatrix ? Ainv_raw : Matrix{Float64}(Ainv_raw)
    else
        Ainv = _build_iid_relmat_inverse(q)
    end

    block1 = (name="animal", type="pedigree", Z=Z, relmat_inverse=Ainv, ids=block_ids)

    # Check for legacy two-effect slot (Z2 + effect2).  §4 transition alias.
    Z2_raw = _field(payload, "Z2", :Z2)
    if Z2_raw === nothing
        return [block1]
    end

    Z2 = Z2_raw isa AbstractMatrix ? Z2_raw : Matrix{Float64}(Z2_raw)
    effect2 = _field(payload, "effect2", :effect2)

    # effect2 may carry relationship info; default to iid.
    e2_rel = effect2 !== nothing ? _field(effect2, "relationship", :relationship) : nothing
    e2_name = effect2 !== nothing ? _field(effect2, "group", :group) : nothing
    e2_name = e2_name !== nothing ? string(e2_name) : "effect2"
    e2_type = (e2_rel !== nothing && string(e2_rel) == "pedigree") ? "pedigree" : "iid"

    if e2_type == "pedigree"
        # maternal_genetic shares the same Ainv (julia-bridge.R:896-900).
        Ainv2 = Ainv
    else
        q2 = size(Z2, 2)
        Ainv2 = _build_iid_relmat_inverse(q2)
    end
    ids2_raw = _field(payload, "ids2", :ids2)
    block2_ids = ids2_raw === nothing ? collect(1:size(Z2, 2)) : collect(ids2_raw)
    block2 = (name=e2_name, type=e2_type, Z=Z2, relmat_inverse=Ainv2, ids=block2_ids)

    return [block1, block2]
end

# ---------------------------------------------------------------------------
# Public: fit_payload_v2
# ---------------------------------------------------------------------------

"""
    fit_payload_v2(payload) → fit NamedTuple

Parse a payload-v2 request and run the dispatched estimator, returning the
estimator's raw `NamedTuple` result.  For a single-pedigree-block payload
this is exactly the result of `fit_animal_model(…)`.

The `:coefcov` dispatch is a frozen slot: `fit_payload_v2` raises
`Phase0NotImplementedError` for it (§6: "no multi-block coefcov estimator is
wired yet").
"""
function fit_payload_v2(payload)
    parsed = parse_payload_v2(payload)
    return _dispatch_fit(parsed)
end

function _dispatch_fit(parsed::ParsedPayloadV2)
    dispatch = parsed.dispatch
    blocks   = parsed.blocks
    X        = parsed.X
    method   = parsed.method

    if dispatch == :animal
        # §6 row 1: single pedigree block → fit_animal_model.
        b = blocks[1]
        y = parsed.y
        return fit_animal_model(y, X, sparse(Matrix{Float64}(b.Z)),
                                sparse(Matrix{Float64}(b.relmat_inverse));
                                ids = b.ids, method = method)

    elseif dispatch == :two_effect
        # §6 row 2: two independent blocks → fit_two_effect_reml.
        b1, b2 = blocks[1], blocks[2]
        y = parsed.y
        return fit_two_effect_reml(y, X,
                                   Matrix{Float64}(b1.Z), Matrix{Float64}(b1.relmat_inverse),
                                   Matrix{Float64}(b2.Z), Matrix{Float64}(b2.relmat_inverse);
                                   ids1 = b1.ids, ids2 = b2.ids)

    elseif dispatch == :multi_effect
        # §6 row 3: K ≥ 2 independent blocks → fit_multi_effect_reml.
        y = parsed.y
        effects = [(Matrix{Float64}(b.Z), Matrix{Float64}(b.relmat_inverse)) for b in blocks]
        per_block_ids = [b.ids for b in blocks]
        return fit_multi_effect_reml(y, X, effects; ids = per_block_ids)

    elseif dispatch == :direct_maternal
        # §6 row 4: one correlated block → fit_direct_maternal_reml.
        b = blocks[1]   # only correlated block (mixed correlated+independent rejected at parse)
        y = parsed.y
        return fit_direct_maternal_reml(y, X,
                                        Matrix{Float64}(b.Z),
                                        Matrix{Float64}(b.Zm),
                                        Matrix{Float64}(b.relmat_inverse);
                                        ids = b.ids)

    elseif dispatch == :multivariate
        # §6 row 5: multivariate Y (one pedigree block) → fit_multivariate_reml.
        # fit_multivariate_reml requires a supplied G0 and R0; without them we
        # cannot proceed.  Flag as not yet wired at the payload-v2 layer
        # (the direct estimator call still works for callers who supply G0/R0).
        throw(Phase0NotImplementedError(
            "multivariate dispatch via payload-v2 requires caller-supplied G0 and R0 " *
            "(use fit_multivariate_reml directly)"))

    elseif dispatch == :coefcov
        # §6 frozen slot: coefcov estimator not yet wired at the payload layer.
        throw(Phase0NotImplementedError(
            "coefcov block dispatch is a frozen slot in payload-v2 (§6); " *
            "the multi-block random-regression estimator is not yet wired"))

    else
        throw(ArgumentError("unrecognised dispatch symbol: $dispatch"))
    end
end

# ---------------------------------------------------------------------------
# Public: result_payload_v2
# ---------------------------------------------------------------------------

"""
    result_payload_v2(fit, parsed::ParsedPayloadV2) → NamedTuple

Build the block-structured result payload (§5) from an estimator fit and the
`ParsedPayloadV2` produced by `parse_payload_v2`.

**Single-pedigree-block fast path (§5):** when `dispatch == :animal`, the
result contains the legacy flat fields (`variance_components.sigma_a2`,
`random_effects.animal`, scalar `heritability`, etc.) byte-identically to
the current v0.1 `result_payload(fit::AnimalModelFit)`.

For multi-block fits the result carries:
- `variance_components.blocks` — ordered list of per-block variance records.
- `variance_components.residual` — scalar σ²e (always present, §5).
- `random_effects` — ordered list of `(name, ids, values)` records.
- `loglik`, `converged` — always present.

CONTRACT-ONLY (docs/design/21-payload-v2-multiblock-schema.md §5, §6).
"""
function result_payload_v2(fit, parsed::ParsedPayloadV2)
    dispatch = parsed.dispatch
    blocks = parsed.blocks

    if dispatch == :animal
        # §5 single-pedigree-block fast path: delegate to the existing v0.1
        # result_payload (AnimalModelFit).  Returns the full legacy shape byte-
        # identically, so hs_normalize_julia_result() and all R S3 extractors
        # return identical output.
        fit isa AnimalModelFit && return result_payload(fit)

        # If fit is a raw NamedTuple from fit_animal_model (non-AnimalModelFit),
        # synthesize the legacy flat fields from what the estimator returned.
        vc = fit.variance_components
        sigma_a2 = vc.sigma_a2
        sigma_e2 = vc.sigma_e2
        h2 = sigma_a2 / (sigma_a2 + sigma_e2)
        b = blocks[1]
        return (
            variance_components = vc,
            heritability = h2,
            random_effects = (animal = (ids = b.ids, values = fit.effects isa NamedTuple ?
                                         fit.effects.values : fit.effects),),
            loglik = fit.loglik,
            converged = fit.converged,
        )
    end

    if dispatch == :two_effect
        # §5: two-block structured result.
        vc = fit.variance_components    # (sigma1, sigma2, sigma_e2)
        b1, b2 = blocks[1], blocks[2]
        variance_blocks = [
            (name=b1.name, type=b1.type, variance=vc.sigma1),
            (name=b2.name, type=b2.type, variance=vc.sigma2),
        ]
        re_blocks = [
            (name=b1.name, ids=fit.effect1.ids, values=fit.effect1.values),
            (name=b2.name, ids=fit.effect2.ids, values=fit.effect2.values),
        ]
        return (
            variance_components = (residual=vc.sigma_e2, blocks=variance_blocks),
            random_effects = re_blocks,
            loglik = fit.loglik,
            converged = fit.converged,
        )
    end

    if dispatch == :multi_effect
        # §5: multi-block structured result.
        vc = fit.variance_components    # (sigmas::Vector, sigma_e2)
        variance_blocks = [
            (name=blocks[i].name, type=blocks[i].type, variance=vc.sigmas[i])
            for i in eachindex(blocks)
        ]
        re_blocks = [
            (name=blocks[i].name, ids=fit.effects[i].ids, values=fit.effects[i].values)
            for i in eachindex(blocks)
        ]
        return (
            variance_components = (residual=vc.sigma_e2, blocks=variance_blocks),
            random_effects = re_blocks,
            loglik = fit.loglik,
            converged = fit.converged,
            boundary = fit.boundary,
        )
    end

    if dispatch == :direct_maternal
        # §5: correlated result — direct-vs-partner labelling.
        vc = fit.variance_components    # (G_dm, sigma_ad, sigma_am, sigma_dm, sigma_e2)
        b = blocks[1]
        partner_name = hasproperty(b, :partner_name) ? b.partner_name : "maternal"
        variance_blocks = [
            (
                name       = b.name,
                type       = "correlated",
                G          = vc.G_dm,
                direct_variance  = vc.sigma_ad,
                partner_variance = vc.sigma_am,
                covariance = vc.sigma_dm,
                correlation = fit.genetic_correlation,
            ),
        ]
        re_blocks = [
            (name=b.name,     ids=fit.direct_effects.ids,   values=fit.direct_effects.values),
            (name=partner_name, ids=fit.maternal_effects.ids, values=fit.maternal_effects.values),
        ]
        return (
            variance_components = (residual=vc.sigma_e2, blocks=variance_blocks),
            random_effects = re_blocks,
            loglik = fit.loglik,
            converged = fit.converged,
        )
    end

    throw(ArgumentError("result_payload_v2: unrecognised dispatch symbol: $dispatch"))
end
