# bridge_payload_v2.jl — P0.3 Julia-side payload-v2 parser + dispatcher
#
# Contract: §6 of docs/design/21-payload-v2-multiblock-schema.md (ratification pending).
# This file is CONTRACT-ONLY: it reuses existing estimators, adds no new
# numerics, and makes no covered-status change (contract-only; this file does not
# move `public_covered_count`).  This file does not change the
# `validation_status()` row count.
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
                     `:multivariate`, `:multivariate_repeatability` (Y + pedigree + iid PE),
                     or `:coefcov` (frozen slot, not yet wired).
- `y` / `Y`        — response vector (univariate) or matrix (multivariate).
- `X`              — fixed-effects design matrix.
- `blocks`         — Vector of per-block NamedTuples with resolved engine matrices
                     `(name, type, Z, relmat_inverse, ids)`.  For `correlated` blocks:
                     also `partner_incidence` and `partner_name`. For `coefcov`: also `basis`,
                     `order`, `Phi`, `covariate`, `covariate_bounds`, and `cov_structure`.
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
    return first(_build_ainv_and_diag_from_block_pedigree(ped))
end

# Same, plus the animal self-relationships `diag(inv(Ainv)) = 1 .+ F` from the
# inbreeding coefficients `pedigree_inverse` already computes, in `Ainv`'s own
# (normalized) row order. `reliability` reads its denominator from them instead of a
# selected inverse of `Ainv`.
function _build_ainv_and_diag_from_block_pedigree(ped; ids = nothing)
    # Accept both Dict (JuliaCall) and NamedTuple forms.
    ids_raw  = _field(ped, "id",   :id)
    sire_raw = _field(ped, "sire", :sire)
    dam_raw  = _field(ped, "dam",  :dam)
    ids_raw  === nothing && throw(ArgumentError("pedigree block missing field 'id'"))
    sire_raw === nothing && throw(ArgumentError("pedigree block missing field 'sire'"))
    dam_raw  === nothing && throw(ArgumentError("pedigree block missing field 'dam'"))
    pedigree = normalize_pedigree(collect(ids_raw), collect(sire_raw), collect(dam_raw))
    Ainv, F = _pedigree_inverse_and_inbreeding(pedigree)
    if ids !== nothing
        length(ids) == length(pedigree) || throw(ArgumentError(
            "pedigree block ids length must match pedigree rows"))
        length(unique(ids)) == length(ids) || throw(ArgumentError(
            "pedigree block ids must be unique"))
        position = Dict{Any,Int}(id => i for (i, id) in enumerate(pedigree.ids))
        all(id -> haskey(position, id), ids) || throw(ArgumentError(
            "pedigree block ids must match pedigree IDs"))
        order = [position[id] for id in ids]
        if !all(i -> order[i] == i, eachindex(order))
            Ainv = Ainv[order, order]
            F = F[order]
        end
    end
    return Ainv, 1 .+ F
end

# Flexible field accessor: checks string key then symbol key; returns nothing if absent.
function _field(d, str_key, sym_key)
    d isa AbstractDict && haskey(d, str_key) && return d[str_key]
    d isa AbstractDict && haskey(d, sym_key)  && return d[sym_key]
    hasproperty(d, sym_key) && return getproperty(d, sym_key)
    return nothing
end

# Resolve the relmat_inverse for one block.  §2 field table.
_resolve_relmat_inverse(block, Z) = first(_resolve_relmat(block, Z))

# `(relmat_inverse, relationship_diag)`: the diagonal of `inv(relmat_inverse)` is
# known for free only when Julia builds a pedigree `Ainv` itself; otherwise `nothing`.
function _resolve_relmat(block, Z; ids = nothing)
    status = _field(block, "relmat_status", :relmat_status)
    status = status === nothing ? "build_in_julia" : string(status)

    if status == "identity"
        q = size(Z, 2)
        return _build_iid_relmat_inverse(q), nothing
    elseif status == "build_in_julia"
        ped = _field(block, "pedigree", :pedigree)
        ped === nothing && throw(ArgumentError(
            "block with relmat_status='build_in_julia' must supply a 'pedigree' field"))
        return _build_ainv_and_diag_from_block_pedigree(ped; ids = ids)
    elseif status == "supplied"
        ri = _field(block, "relmat_inverse", :relmat_inverse)
        ri === nothing && throw(ArgumentError(
            "block with relmat_status='supplied' must supply 'relmat_inverse'"))
        return ri, nothing
    else
        throw(ArgumentError("unknown relmat_status: '$status'"))
    end
end

function _validate_resolved_block(name, Z, relmat_inverse, ids)
    relmat_inverse isa AbstractMatrix || throw(ArgumentError(
        "block '$name': relmat_inverse must be a matrix"))
    size(relmat_inverse, 1) == size(relmat_inverse, 2) || throw(ArgumentError(
        "block '$name': relmat_inverse must be square; got size $(size(relmat_inverse))"))
    size(Z, 2) == size(relmat_inverse, 1) || throw(ArgumentError(
        "block '$name': Z columns ($(size(Z, 2))) do not match " *
        "relmat_inverse dimension ($(size(relmat_inverse, 1)))"))
    length(ids) == size(Z, 2) || throw(ArgumentError(
        "block '$name': ids has length $(length(ids)) but Z has $(size(Z, 2)) columns"))
    length(unique(ids)) == length(ids) || throw(ArgumentError(
        "block '$name': ids must be unique"))
    return nothing
end

# Validate and retain the coefficient-covariance frozen slot. This does not
# wire a fitting route. Raw slopes need no standardization bounds; Legendre
# blocks require them so covariate-indexed results can be reconstructed later.
function _parse_coefcov_fields(block, name, Z)
    basis = _field(block, "basis", :basis)
    basis isa AbstractString && basis in ("raw", "legendre") || throw(ArgumentError(
        "coefcov block '$name': basis must be 'raw' or 'legendre'"))
    order_raw = _field(block, "order", :order)
    order_raw isa Integer && !(order_raw isa Bool) && order_raw >= 1 || throw(ArgumentError(
        "coefcov block '$name': order must be a positive integer (number of basis columns)"))
    Phi_raw = _field(block, "Phi", :Phi)
    Phi_raw isa AbstractMatrix && !issparse(Phi_raw) || throw(ArgumentError(
        "coefcov block '$name': Phi must be a dense real matrix"))
    size(Phi_raw) == (size(Z, 1), order_raw) || throw(ArgumentError(
        "coefcov block '$name': Phi must have $(size(Z, 1)) rows and $order_raw columns"))
    all(x -> x isa Real && !(x isa Bool) && isfinite(x), Phi_raw) || throw(ArgumentError(
        "coefcov block '$name': Phi must contain finite real values"))
    Phi = Matrix{Float64}(Phi_raw)
    all(isfinite, Phi) || throw(ArgumentError(
        "coefcov block '$name': Phi values must remain finite as Float64"))
    covariate = _field(block, "covariate", :covariate)
    covariate isa AbstractString && !isempty(strip(covariate)) || throw(ArgumentError(
        "coefcov block '$name': covariate must be a nonempty string"))
    bounds_raw = _field(block, "covariate_bounds", :covariate_bounds)
    bounds = if bounds_raw === nothing
        basis == "raw" || throw(ArgumentError(
            "coefcov block '$name': Legendre basis requires covariate_bounds"))
        nothing
    else
        bounds_raw isa AbstractVector && length(bounds_raw) == 2 &&
            all(x -> x isa Real && !(x isa Bool) && isfinite(x), bounds_raw) || throw(ArgumentError(
                "coefcov block '$name': covariate_bounds must contain two finite real values"))
        values = Float64.(bounds_raw)
        all(isfinite, values) && values[1] < values[2] || throw(ArgumentError(
            "coefcov block '$name': covariate_bounds must be finite with lower < upper"))
        values
    end
    cov_structure = _field(block, "cov_structure", :cov_structure)
    cov_structure isa AbstractString && cov_structure in ("unstructured", "diagonal") || throw(ArgumentError(
        "coefcov block '$name': cov_structure must be 'unstructured' or 'diagonal'"))
    return (basis=String(basis), order=Int(order_raw), Phi=Phi,
            covariate=String(covariate), covariate_bounds=bounds,
            cov_structure=String(cov_structure))
end

# Parse a single block dict/namedtuple into a resolved NamedTuple.
function _parse_one_block(block)
    name_raw = _field(block, "name", :name)
    name_raw === nothing && throw(ArgumentError("payload-v2 block is missing required field 'name'"))
    name_raw isa AbstractString || throw(ArgumentError("payload-v2 block 'name' must be a string"))
    isempty(strip(name_raw)) && throw(ArgumentError("payload-v2 block 'name' must not be empty"))
    name = String(name_raw)
    type_raw = _field(block, "type", :type)
    type_raw === nothing && throw(ArgumentError("payload-v2 block '$name' is missing required field 'type'"))
    btype = string(type_raw)
    btype in ("pedigree", "iid", "coefcov", "correlated") ||
        throw(ArgumentError("unknown block type '$btype'; expected pedigree, iid, coefcov, or correlated"))

    Z_raw = _field(block, "Z", :Z)
    Z_raw === nothing && throw(ArgumentError("payload-v2 block '$name' is missing required field 'Z'"))
    Z = Z_raw isa AbstractMatrix ? Z_raw : Matrix{Float64}(Z_raw)

    status_raw = _field(block, "relmat_status", :relmat_status)
    status_raw === nothing && throw(ArgumentError(
        "payload-v2 block '$name' is missing required field 'relmat_status'"))
    # §2: ids field for this block (level ids vector)
    ids_raw = _field(block, "ids", :ids)
    ids_raw === nothing && throw(ArgumentError(
        "payload-v2 block '$name' is missing required field 'ids'"))
    block_ids = collect(ids_raw)

    # Keep the declared relationship type consistent with how the precision
    # matrix will be constructed. Otherwise an identity matrix can be fitted
    # and returned under an animal/pedigree label.
    if btype == "iid" && string(status_raw) != "identity"
        throw(ArgumentError(
            "payload-v2 block '$name' has type='iid' but relmat_status='$(status_raw)'; " *
            "iid blocks require relmat_status='identity'"))
    elseif btype == "pedigree" && string(status_raw) == "identity"
        throw(ArgumentError(
            "payload-v2 block '$name' has type='pedigree' but relmat_status='identity'"))
    elseif btype == "correlated" && !(string(status_raw) in ("build_in_julia", "supplied"))
        throw(ArgumentError(
            "payload-v2 block '$name' has type='correlated' but relmat_status='$(status_raw)'; " *
            "correlated blocks require relmat_status='build_in_julia' or 'supplied'"))
    end
    relmat_inverse, relationship_diag = _resolve_relmat(block, Z; ids = block_ids)
    _validate_resolved_block(name, Z, relmat_inverse, block_ids)

    if btype == "coefcov"
        fields = _parse_coefcov_fields(block, name, Z)
        return merge((name=name, type=btype, Z=Z, relmat_inverse=relmat_inverse,
                      ids=block_ids, relationship_diag=relationship_diag), fields)
    elseif btype == "correlated"
        # §2 correlated block: Z → Zd, partner_incidence → Zm.
        Zm_raw = _field(block, "partner_incidence", :partner_incidence)
        Zm_raw === nothing && throw(ArgumentError(
            "correlated block '$name' is missing 'partner_incidence'"))
        Zm = Zm_raw isa AbstractMatrix ? Zm_raw : Matrix{Float64}(Zm_raw)
        partner_name = _field(block, "partner_name", :partner_name)
        partner_name = partner_name === nothing ? "maternal" : string(partner_name)
        isempty(strip(partner_name)) && throw(ArgumentError(
            "correlated block '$name' partner_name must be non-empty"))
        partner_name == name && throw(ArgumentError(
            "correlated block '$name' partner_name must differ from the direct block name"))
        return (name=name, type=btype, Z=Z, relmat_inverse=relmat_inverse,
                ids=block_ids, Zm=Zm, partner_name=partner_name)
    else
        return (name=name, type=btype, Z=Z, relmat_inverse=relmat_inverse, ids=block_ids,
                relationship_diag=relationship_diag)
    end
end

# ---------------------------------------------------------------------------
# Dispatch resolution — §6 dispatch table
# ---------------------------------------------------------------------------

"""
    _resolve_dispatch(blocks, is_multivariate) → Symbol

Choose the existing payload-v2 estimator from the resolved block list
(HSquared.jl #352). This adds no estimator.

Univariate independent blocks:

- 1 pedigree block → `:animal`
- 2 independent blocks → `:two_effect` (animal + permanent environment when
  the second block is iid; also common environment / maternal environment)
- 3 or more independent blocks → `:multi_effect`

Two effects are not rejected. `fit_repeatability_reml` is the dedicated
`Z2 = Z1`, `A2 = I` special case of that two-effect kernel.

Other existing arms: one correlated block → `:direct_maternal`; multivariate
`Y` with one pedigree block → `:multivariate`; multivariate `Y` with pedigree
+ iid → `:multivariate_repeatability`; one `coefcov` block → `:coefcov`
(frozen slot).
"""
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
    # Only the correlated-only form is wired: the estimator accepts
    # (y, X, Zd, Zm, Ainv), so mixed correlated+independent blocks are rejected.
    if n_correlated == 1
        is_multivariate && throw(ArgumentError(
            "payload-v2 does not support correlated random-effect blocks with multivariate 'Y'"))
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
        if K == 1
            return :multivariate
        end
        if K == 2 && count(==("pedigree"), types) == 1 && count(==("iid"), types) == 1
            return :multivariate_repeatability
        end
        throw(ArgumentError(
            "multivariate dispatch accepts one pedigree block, or pedigree + iid " *
            "permanent environment; got K=$K types=$(types)"))
    end

    if K == 1
        blocks[1].type == "pedigree" || throw(ArgumentError(
            "single-block animal dispatch requires a pedigree block; got '$(blocks[1].type)'"))
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

Independent-block count (HSquared.jl #352): 1 pedigree block → `:animal`;
2 independent blocks → `:two_effect` (animal + permanent environment when
the second block is iid); 3 or more independent blocks → `:multi_effect`.
Two effects are not rejected.

CONTRACT-ONLY (docs/design/21-payload-v2-multiblock-schema.md §6):
no new estimator is added here.
"""
function parse_payload_v2(payload)
    # --- Resolve payload_version ---
    pv_raw = _field(payload, "payload_version", :payload_version)
    payload_version = if pv_raw === nothing
        1
    elseif pv_raw isa Integer && !(pv_raw isa Bool) && pv_raw in (1, 2)
        Int(pv_raw)
    else
        throw(ArgumentError(
            "unsupported payload_version $(repr(pv_raw)); expected integer 1 or 2"))
    end

    # --- Response ---
    Y_raw = _field(payload, "Y", :Y)
    y_raw = _field(payload, "y", :y)
    Y_raw !== nothing && y_raw !== nothing && throw(ArgumentError(
        "payload must supply exactly one response field: 'y' or 'Y'"))
    is_multivariate = Y_raw !== nothing
    if is_multivariate
        Y = Y_raw isa AbstractMatrix ? Y_raw : Matrix{Float64}(Y_raw)
        size(Y, 1) > 0 && size(Y, 2) > 0 || throw(ArgumentError(
            "multivariate response 'Y' must have at least one observation and one trait"))
        y = nothing
    else
        y_raw === nothing && throw(ArgumentError("payload must supply 'y' (univariate) or 'Y' (multivariate)"))
        y = y_raw isa AbstractVector ? y_raw : vec(Float64.(y_raw))
        !isempty(y) || throw(ArgumentError("univariate response 'y' must have at least one observation"))
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

    if payload_version == 1
        re_raw === nothing || throw(ArgumentError(
            "payload_version=1 uses the legacy flat shape and cannot include 'random_effects'"))
        blocks = _lift_legacy_payload(payload)
    elseif re_raw === nothing
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
    for b in blocks
        if b.type == "correlated" && b.partner_name in names_seen
            throw(ArgumentError(
                "correlated block '$(b.name)' partner_name '$(b.partner_name)' " *
                "collides with a random_effects block name"))
        end
    end

    # --- Dimension check: Z rows must equal number of observations ---
    n = is_multivariate ? size(Y, 1) : length(y)
    size(X, 1) == n || throw(ArgumentError(
        "X has $(size(X, 1)) rows but response has $n observations"))
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

    if dispatch == :multivariate_repeatability
        # The current estimator uses one incidence for both animal and
        # permanent effects. Do not silently substitute the pedigree block
        # when the payload supplies a different PE design or ID ordering.
        ped = blocks[findfirst(b -> b.type == "pedigree", blocks)]
        pe = blocks[findfirst(b -> b.type == "iid", blocks)]
        ped.ids == pe.ids || throw(ArgumentError(
            "multivariate repeatability requires identical pedigree and iid IDs in the same order"))
        ped.Z == pe.Z || throw(ArgumentError(
            "multivariate repeatability requires identical pedigree and iid incidence matrices"))
    end

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
    string(ainv_status) == "identity" && throw(ArgumentError(
        "legacy animal payload uses identity precision but is labelled as a pedigree model; " *
        "identity precision cannot be labelled as an animal model"))

    ids_raw = _field(payload, "ids", :ids)
    if ids_raw === nothing && ped !== nothing
        ids_raw = _field(ped, "id", :id)
    end
    block_ids = ids_raw === nothing ? collect(1:size(Z, 2)) : collect(ids_raw)

    # Build first block
    q = size(Z, 2)
    relationship_diag = nothing
    if string(ainv_status) == "build_in_julia"
        ped === nothing && throw(ArgumentError(
            "legacy payload with ainv_status='build_in_julia' must supply 'pedigree'"))
        Ainv, relationship_diag = _build_ainv_and_diag_from_block_pedigree(ped; ids = block_ids)
    elseif string(ainv_status) == "supplied"
        Ainv_raw = _field(payload, "Ainv", :Ainv)
        Ainv_raw === nothing && throw(ArgumentError(
            "legacy payload with ainv_status='supplied' must supply 'Ainv'"))
        Ainv = Ainv_raw isa AbstractMatrix ? Ainv_raw : Matrix{Float64}(Ainv_raw)
    else
        throw(ArgumentError(
            "unknown legacy ainv_status '$(ainv_status)'; expected 'build_in_julia' or 'supplied'"))
    end

    _validate_resolved_block("animal", Z, Ainv, block_ids)

    block1 = (name="animal", type="pedigree", Z=Z, relmat_inverse=Ainv, ids=block_ids,
              relationship_diag=relationship_diag)

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
    e2_type = if e2_rel === nothing || string(e2_rel) == "identity"
        "iid"
    elseif string(e2_rel) == "pedigree"
        "pedigree"
    else
        throw(ArgumentError(
            "unknown legacy effect2 relationship '$(e2_rel)'; expected 'identity' or 'pedigree'"))
    end

    ids2_raw = _field(payload, "ids2", :ids2)
    block2_ids = ids2_raw === nothing ?
        (e2_type == "pedigree" ? copy(block_ids) : collect(1:size(Z2, 2))) : collect(ids2_raw)
    if e2_type == "pedigree"
        # maternal_genetic shares the first block's relationship, expressed in
        # the column order declared by ids2 (julia-bridge.R:896-900).
        length(block2_ids) == length(block_ids) &&
            length(unique(block_ids)) == length(block_ids) &&
            length(unique(block2_ids)) == length(block2_ids) || throw(ArgumentError(
                "legacy pedigree effect ids2 must be a permutation of first-block ids"))
        position = Dict{Any,Int}(id => i for (i, id) in enumerate(block_ids))
        all(id -> haskey(position, id), block2_ids) || throw(ArgumentError(
            "legacy pedigree effect ids2 must be a permutation of first-block ids"))
        order = [position[id] for id in block2_ids]
        if all(i -> order[i] == i, eachindex(order))
            Ainv2 = Ainv
            relationship_diag2 = relationship_diag
        else
            Ainv2 = Ainv[order, order]
            relationship_diag2 = relationship_diag === nothing ? nothing : relationship_diag[order]
        end
        block2 = (name=e2_name, type=e2_type, Z=Z2, relmat_inverse=Ainv2,
                  ids=block2_ids, relationship_diag=relationship_diag2)
    else
        Ainv2 = _build_iid_relmat_inverse(size(Z2, 2))
        block2 = (name=e2_name, type=e2_type, Z=Z2, relmat_inverse=Ainv2, ids=block2_ids)
    end

    _validate_resolved_block(e2_name, Z2, Ainv2, block2_ids)

    return [block1, block2]
end

# ---------------------------------------------------------------------------
# Public: fit_payload_v2
# ---------------------------------------------------------------------------

"""
    fit_payload_v2(payload; scale_method = :dense, initial = nothing,
                  iterations = nothing) → fit NamedTuple

Parse a payload-v2 request and run the dispatched estimator, returning the
estimator's raw `NamedTuple` result.  For a single-pedigree-block payload
this is exactly the result of `fit_animal_model(…)`.

`initial` and `iterations` (hsquared#212) are forwarded ONLY to the
`:multi_effect` and `:direct_maternal` dispatch arms — the two engine calls
this dispatcher previously hardcoded with neither. Default `nothing`
for both reproduces the exact pre-#212-fix call (each underlying fitter's own
default: `fit_multi_effect_reml`'s `initial = nothing` / `iterations = 200`,
`fit_direct_maternal_reml`'s `initial = nothing` / `iterations = 200`). For
`:multi_effect`, forwarding applies on BOTH `scale_method` routes (#343): the
default `:dense` fitter `fit_multi_effect_reml`, and the opt-in `:auto` route's
`fit_multi_effect`, which itself forwards `kwargs...` to whichever engine it
selects (`fit_sparse_multi_effect_aireml`'s `initial = nothing` / `iterations = 100`,
or `fit_multi_effect_mc_reml`'s `initial = nothing` / `iterations = 200`). A
supplied `initial`, `iterations`, or non-default `scale_method` on any other
wired arm (`:animal`, `:two_effect`, `:multivariate_repeatability`; also
non-default `scale_method` on `:direct_maternal`) raises `ArgumentError` and
names the unsupported keyword (HSquared.jl#436). `:multivariate` and
`:coefcov` still raise `Phase0NotImplementedError`.

The `:coefcov` dispatch is a frozen slot: `fit_payload_v2` raises
`Phase0NotImplementedError` for it (§6: "no coefcov payload fitting route is
currently wired").
"""
function fit_payload_v2(payload; scale_method::Symbol = :dense,
                        initial = nothing, iterations::Union{Nothing,Integer} = nothing)
    parsed = parse_payload_v2(payload)
    return _dispatch_fit(parsed; scale_method = scale_method, initial = initial, iterations = iterations)
end

# Honour table for fit_payload_v2 kwargs (HSquared.jl#436). A supplied
# initial / iterations / non-default scale_method is either forwarded by the
# arm or rejected here with the keyword named.
function _reject_unsupported_fit_kwargs(dispatch::Symbol;
                                        scale_method::Symbol,
                                        initial,
                                        iterations)
    honours_initial = dispatch in (:multi_effect, :direct_maternal)
    honours_iterations = dispatch in (:multi_effect, :direct_maternal)
    honours_scale_method = dispatch === :multi_effect
    unsupported = String[]
    !honours_initial && initial !== nothing && push!(unsupported, "initial")
    !honours_iterations && iterations !== nothing && push!(unsupported, "iterations")
    !honours_scale_method && scale_method !== :dense && push!(unsupported, "scale_method")
    isempty(unsupported) && return nothing
    throw(ArgumentError(
        "payload-v2 $dispatch dispatch does not support $(join(unsupported, ", "))"))
end

function _dispatch_fit(parsed::ParsedPayloadV2; scale_method::Symbol = :dense,
                       initial = nothing, iterations::Union{Nothing,Integer} = nothing)
    dispatch = parsed.dispatch
    blocks   = parsed.blocks
    X        = parsed.X
    method   = parsed.method
    _reject_unsupported_fit_kwargs(dispatch; scale_method = scale_method,
                                   initial = initial, iterations = iterations)

    if dispatch in (:two_effect, :multi_effect, :direct_maternal,
                    :multivariate_repeatability) && method !== :REML
        throw(ArgumentError("payload-v2 $dispatch dispatch is REML-only; got method=$method"))
    end

    if dispatch == :animal
        # §6 row 1: single pedigree block → fit_animal_model.
        b = blocks[1]
        y = parsed.y
        return fit_animal_model(y, X, sparse(Matrix{Float64}(b.Z)),
                                sparse(Matrix{Float64}(b.relmat_inverse));
                                ids = b.ids, method = method,
                                relationship_diag = get(b, :relationship_diag, nothing))

    elseif dispatch == :two_effect
        # §6 row 2: two independent blocks → fit_two_effect_reml.
        b1, b2 = blocks[1], blocks[2]
        y = parsed.y
        return fit_two_effect_reml(y, X,
                                   Matrix{Float64}(b1.Z), Matrix{Float64}(b1.relmat_inverse),
                                   Matrix{Float64}(b2.Z), Matrix{Float64}(b2.relmat_inverse);
                                   ids1 = b1.ids, ids2 = b2.ids)

    elseif dispatch == :multi_effect
        # §6 row 3: K ≥ 2 independent blocks. `scale_method = :dense` (DEFAULT — the frozen
        # contract, byte-identical) → the dense `fit_multi_effect_reml`. `scale_method = :auto`
        # → `fit_multi_effect(:auto)`, which routes to the SPARSE-EXACT AI-REML (reduces exactly
        # to the dense optimum) for validation-scale problems and to the EXPERIMENTAL matrix-free
        # Monte-Carlo fit for large ones (with a stochastic loglik so the result stays
        # bridge-shape-compatible). The covered claim is on the validation-scale (exact) path;
        # the large-scale matrix-free path is experimental (opt-in).
        y = parsed.y
        per_block_ids = [b.ids for b in blocks]
        # hsquared#212 / #343: forwarded to both the dense fitter (`:dense`) and, via
        # `fit_multi_effect`'s `kwargs...`, to whichever engine `:auto` selects
        # (`fit_sparse_multi_effect_aireml` or `fit_multi_effect_mc_reml` — both accept
        # `initial`/`iterations`). Only forwarded when supplied (not `nothing`), so the
        # default call on either path stays byte-identical to each fitter's own defaults.
        multi_effect_kwargs = iterations === nothing ?
            (initial === nothing ? NamedTuple() : (initial = initial,)) :
            (initial === nothing ? (iterations = iterations,) : (initial = initial, iterations = iterations))
        if scale_method === :auto
            effects = [(sparse(Matrix{Float64}(b.Z)), sparse(Matrix{Float64}(b.relmat_inverse))) for b in blocks]
            return fit_multi_effect(y, X, effects; method = :auto, ids = per_block_ids,
                                    compute_loglik = true, verbose = false, multi_effect_kwargs...)
        elseif scale_method === :dense
            effects = [(Matrix{Float64}(b.Z), Matrix{Float64}(b.relmat_inverse)) for b in blocks]
            return fit_multi_effect_reml(y, X, effects; ids = per_block_ids, multi_effect_kwargs...)
        else
            throw(ArgumentError("scale_method must be :dense (default) or :auto"))
        end

    elseif dispatch == :direct_maternal
        # §6 row 4: one correlated block → fit_direct_maternal_reml.
        b = blocks[1]   # only correlated block (mixed correlated+independent rejected at parse)
        y = parsed.y
        # hsquared#212: forward `initial`/`iterations` (both default nothing -> the
        # fitter's own defaults, byte-identical to the pre-#212-fix call).
        dm_kwargs = iterations === nothing ?
            (initial === nothing ? NamedTuple() : (initial = initial,)) :
            (initial === nothing ? (iterations = iterations,) : (initial = initial, iterations = iterations))
        return fit_direct_maternal_reml(y, X,
                                        Matrix{Float64}(b.Z),
                                        Matrix{Float64}(b.Zm),
                                        Matrix{Float64}(b.relmat_inverse);
                                        ids = b.ids, dm_kwargs...)

    elseif dispatch == :multivariate
        # §6 row 5: multivariate Y (one pedigree block) → fit_multivariate_reml.
        # fit_multivariate_reml requires a supplied G0 and R0; without them we
        # cannot proceed.  Flag as not yet wired at the payload-v2 layer
        # (the direct estimator call still works for callers who supply G0/R0).
        throw(Phase0NotImplementedError(
            "multivariate dispatch via payload-v2 requires caller-supplied G0 and R0 " *
            "(use fit_multivariate_reml directly)"))

    elseif dispatch == :multivariate_repeatability
        # hsquared #237: multivariate Y + pedigree + iid PE.
        # R's current bridge uses a dedicated fitter caller; this generic payload
        # dispatcher is wired independently and preserves the same bounded route.
        ped = blocks[findfirst(b -> b.type == "pedigree", blocks)]
        return fit_multivariate_repeatability_reml(
            Matrix{Float64}(parsed.Y),
            X,
            Matrix{Float64}(ped.Z),
            Matrix{Float64}(ped.relmat_inverse);
            ids = ped.ids)

    elseif dispatch == :coefcov
        # §6 frozen slot: coefcov estimator not yet wired at the payload layer.
        throw(Phase0NotImplementedError(
            "coefcov block dispatch is a frozen slot in payload-v2 (§6); " *
            "no coefcov payload fitting route is currently wired"))

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
fitter must return `AnimalModelFit`; the wrapper delegates to `result_payload`
to preserve the complete flat v0.1 fields and current R extractors. Partial
raw tuples are rejected rather than exposed as incomplete legacy results.

For multi-block fits the result carries:
- `variance_components.blocks` — ordered list of per-block variance records.
- `variance_components.residual` — scalar σ²e for univariate fits; the
  experimental multivariate-repeatability route carries a trait covariance matrix.
- `random_effects` — ordered list of `(name, ids, values)` records.
- `loglik`, `df`, `nobs`, `diagnostics`, `converged` — top-level fields.

The experimental multivariate-repeatability extension labels its matrix columns
with top-level `traits`. It is Julia-only until the R normalizer and parity tests
support that extension (docs/design/21-payload-v2-multiblock-schema.md §5).

CONTRACT-ONLY (docs/design/21-payload-v2-multiblock-schema.md §5, §6).
"""
function _v2_structured_result_metadata(fit, parsed::ParsedPayloadV2, n_variance::Integer;
                                        direct_maternal::Bool = false)
    parsed.method === :REML || throw(ArgumentError(
        "payload-v2 $(parsed.dispatch) result is REML-only; got method=$(parsed.method)"))
    parsed.y === nothing && throw(ArgumentError(
        "payload-v2 $(parsed.dispatch) result requires a univariate response"))
    n = length(parsed.y)
    p = size(parsed.X, 2)
    convention_fields = if direct_maternal
        # _direct_maternal_dense omits the (n-p)log(2π) term, like the other
        # dense multi-effect objectives; its fit tuple has no convention fields.
        loglik_convention_fields(LOGLIK_CONVENTION_OMIT_2PI, n, p)
    else
        required = (:loglik_convention, :loglik_full_constant_offset,
                    :loglik_comparable_across_routes)
        all(k -> hasproperty(fit, k), required) || throw(ArgumentError(
            "payload-v2 $(parsed.dispatch) result is missing loglik convention metadata"))
        (loglik_convention = fit.loglik_convention,
         loglik_full_constant_offset = fit.loglik_full_constant_offset,
         loglik_comparable_across_routes = fit.loglik_comparable_across_routes)
    end
    stochastic = (hasproperty(fit, :dispatch) && fit.dispatch === :matrix_free) ||
                 (hasproperty(fit, :estimator) && fit.estimator === :matrix_free_mc_em_reml)
    if stochastic && !hasproperty(fit, :loglik_mcse)
        throw(ArgumentError("payload-v2 stochastic result is missing loglik_mcse"))
    end
    diagnostics = (
        method = :REML,
        optimizer_status = fit.converged ? "converged" : "not_converged",
        loglik_convention = convention_fields.loglik_convention,
        loglik_full_constant_offset = convention_fields.loglik_full_constant_offset,
        loglik_comparable_across_routes =
            convention_fields.loglik_comparable_across_routes && !stochastic,
        loglik_stochastic = stochastic,
    )
    if stochastic
        diagnostics = merge(diagnostics, (loglik_mcse = fit.loglik_mcse,))
    end
    return (df = p + n_variance, nobs = n, diagnostics = diagnostics)
end

function result_payload_v2(fit, parsed::ParsedPayloadV2)
    dispatch = parsed.dispatch
    blocks = parsed.blocks

    if dispatch == :animal
        # §5 single-pedigree-block fast path: delegate to the existing v0.1
        # result_payload (AnimalModelFit).  Returns the full legacy shape byte-
        # identically, so hs_normalize_julia_result() and all R S3 extractors
        # return identical output.
        fit isa AnimalModelFit || throw(ArgumentError(
            "single-pedigree result_payload_v2 requires an AnimalModelFit to preserve the complete legacy result contract"))
        return result_payload(fit)
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
        return merge((
            variance_components = (residual=vc.sigma_e2, blocks=variance_blocks),
            random_effects = re_blocks,
            loglik = fit.loglik,
            converged = fit.converged,
        ), _v2_structured_result_metadata(fit, parsed, 3))
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
        return merge((
            variance_components = (residual=vc.sigma_e2, blocks=variance_blocks),
            random_effects = re_blocks,
            loglik = fit.loglik,
            converged = fit.converged,
            boundary = fit.boundary,
        ), _v2_structured_result_metadata(fit, parsed, length(blocks) + 1))
    end

    if dispatch == :direct_maternal
        # §5: correlated result — direct-vs-partner labelling.
        vc = fit.variance_components    # (G_dm, sigma_ad, sigma_am, sigma_dm, sigma_e2)
        b = blocks[1]
        partner_name = hasproperty(b, :partner_name) ? b.partner_name : "maternal"
        variance_blocks = [
            (
                name       = partner_name,
                type       = "correlated",
                G          = vc.G_dm,
                direct_variance  = vc.sigma_ad,
                partner_variance = vc.sigma_am,
                covariance = vc.sigma_dm,
                correlation = fit.genetic_correlation,
            ),
        ]
        fit.direct_effects.ids == fit.maternal_effects.ids || throw(ArgumentError(
            "result_payload_v2: correlated direct and partner effects must share the block ID order"))
        re_blocks = [(
            name=partner_name,
            ids=fit.direct_effects.ids,
            direct=fit.direct_effects.values,
            partner=fit.maternal_effects.values,
        )]
        return merge((
            variance_components = (residual=vc.sigma_e2, blocks=variance_blocks),
            random_effects = re_blocks,
            loglik = fit.loglik,
            converged = fit.converged,
        ), _v2_structured_result_metadata(fit, parsed, 4; direct_maternal = true))
    end

    if dispatch == :multivariate_repeatability
        parsed.method === :REML || throw(ArgumentError(
            "payload-v2 multivariate_repeatability result is REML-only; got method=$(parsed.method)"))
        ped = blocks[findfirst(b -> b.type == "pedigree", blocks)]
        pe = blocks[findfirst(b -> b.type == "iid", blocks)]
        t = size(parsed.Y, 2)
        nobs = count(_is_present, parsed.Y)
        nfixed = size(parsed.X, 2) * t
        n_covariance = t * (t + 1) ÷ 2
        convention = loglik_convention_fields(LOGLIK_CONVENTION_FULL, nobs, nfixed)
        diagnostics = merge((
            method = :REML,
            optimizer_status = fit.converged ? "converged" : "not_converged",
            loglik_stochastic = false,
        ), convention)
        block_result = (
            variance_components = (
                residual = Matrix(fit.residual_covariance),
                blocks = [
                    (name = ped.name, type = ped.type, variance = Matrix(fit.genetic_covariance)),
                    (name = pe.name, type = pe.type, variance = Matrix(fit.permanent_covariance)),
                ],
            ),
            random_effects = [
                (name = ped.name, ids = fit.breeding_values.ids,
                 values = Matrix(fit.breeding_values.values)),
                (name = pe.name, ids = fit.permanent_effects.ids,
                 values = Matrix(fit.permanent_effects.values)),
            ],
            df = nfixed + 3 * n_covariance,
            nobs = nobs,
            diagnostics = diagnostics,
        )
        return merge(
            multivariate_repeatability_result_payload(fit),
            block_result,
            (component_names = [ped.name, pe.name, "residual"],),
        )
    end

    throw(ArgumentError("result_payload_v2: unrecognised dispatch symbol: $dispatch"))
end
