const DEFAULT_UNKNOWN_PARENT_VALUES = (missing, nothing, "", "0", 0)

"""
    Pedigree(ids, sire, dam, original_order)

Normalized pedigree with parent references encoded as row indices.

`sire` and `dam` use `0` for unknown parents. Rows are topologically sorted so
known parents always occur before their offspring.
"""
struct Pedigree{T}
    ids::Vector{T}
    sire::Vector{Int}
    dam::Vector{Int}
    original_order::Vector{Int}
end

Base.length(pedigree::Pedigree) = length(pedigree.ids)

function Base.show(io::IO, pedigree::Pedigree)
    print(io, "Pedigree(", length(pedigree), " animals)")
end

"""
    normalize_pedigree(ids, sire, dam; missing_values = ..., allow_selfing = false)

Validate, recode, and topologically sort an animal pedigree.

`ids`, `sire`, and `dam` must have the same length. Parent values must be either
unknown-parent markers or values present in `ids`. By default, `missing`,
`nothing`, `""`, `"0"`, and `0` are treated as unknown-parent markers.

The returned [`Pedigree`](@ref) stores parents as integer row indices, with `0`
for unknown parents.

`allow_selfing = true` permits self-fertilization (`sire == dam`), a Phase-3
non-standard-inheritance feature: the additive-relationship recursion and the
Henderson `Ainv` rules already handle a self (a selfed offspring of a non-inbred
parent has inbreeding `F = 1/2`, `A_ii = 3/2`). It is rejected by default to
preserve the sexual-pedigree contract; an individual still cannot be its own
parent.
"""
function normalize_pedigree(ids, sire, dam; missing_values = DEFAULT_UNKNOWN_PARENT_VALUES,
                            allow_selfing::Bool = false)
    ids_vec = collect(ids)
    sire_vec = collect(sire)
    dam_vec = collect(dam)

    n = length(ids_vec)
    length(sire_vec) == n ||
        throw(ArgumentError("ids and sire must have the same length"))
    length(dam_vec) == n ||
        throw(ArgumentError("ids and dam must have the same length"))

    id_to_index = Dict{Any,Int}()
    for (index, id) in pairs(ids_vec)
        _is_unknown_parent(id, missing_values) &&
            throw(ArgumentError("id values cannot be unknown-parent markers: $(_repr(id))"))
        haskey(id_to_index, id) &&
            throw(ArgumentError("duplicate pedigree id: $(_repr(id))"))
        id_to_index[id] = index
    end

    sire_index = Vector{Int}(undef, n)
    dam_index = Vector{Int}(undef, n)
    for index in 1:n
        id = ids_vec[index]
        sire_index[index] = _parent_index(sire_vec[index], id_to_index, missing_values, :sire, id)
        dam_index[index] = _parent_index(dam_vec[index], id_to_index, missing_values, :dam, id)

        sire_index[index] == index &&
            throw(ArgumentError("sire cannot equal id for $(_repr(id))"))
        dam_index[index] == index &&
            throw(ArgumentError("dam cannot equal id for $(_repr(id))"))
        if sire_index[index] != 0 && sire_index[index] == dam_index[index] && !allow_selfing
            throw(ArgumentError("sire and dam cannot be the same known parent for $(_repr(id)); pass allow_selfing = true to model self-fertilization"))
        end
    end

    order = _topological_order(ids_vec, sire_index, dam_index)
    sorted_position = Dict{Int,Int}(original => sorted for (sorted, original) in pairs(order))

    sorted_ids = ids_vec[order]
    sorted_sire = Vector{Int}(undef, n)
    sorted_dam = Vector{Int}(undef, n)
    for (sorted, original) in pairs(order)
        sorted_sire[sorted] = sire_index[original] == 0 ? 0 : sorted_position[sire_index[original]]
        sorted_dam[sorted] = dam_index[original] == 0 ? 0 : sorted_position[dam_index[original]]
    end

    return Pedigree(sorted_ids, sorted_sire, sorted_dam, order)
end

"""
    _numerator_relationship(pedigree; max_relationship_cache = 10_000)
    _numerator_relationship(pedigree, rows; max_relationship_cache = 10_000)

Build the dense numerator (additive) relationship matrix `A` for a normalized
pedigree by the tabular recursion, or the submatrix `A[rows, rows]`.

Internal validation-only helper: dense and bounded by `max_relationship_cache`,
not production-scale. It is the single source of the relationship recursion,
shared by [`inbreeding_coefficients`](@ref) (which takes its diagonal) and by
single-step `A₂₂` construction.
"""
function _numerator_relationship(pedigree::Pedigree; max_relationship_cache::Integer = 10_000)
    n = length(pedigree)
    n <= max_relationship_cache ||
        throw(ArgumentError("_numerator_relationship currently uses a bounded relationship cache; got $(n) rows and max_relationship_cache = $(max_relationship_cache)"))

    relationship = zeros(Float64, n, n)

    for i in 1:n
        sire = pedigree.sire[i]
        dam = pedigree.dam[i]

        for j in 1:(i - 1)
            value = 0.0
            sire == 0 || (value += 0.5 * relationship[sire, j])
            dam == 0 || (value += 0.5 * relationship[dam, j])
            relationship[i, j] = value
            relationship[j, i] = value
        end

        relationship[i, i] = sire != 0 && dam != 0 ? 1.0 + 0.5 * relationship[sire, dam] : 1.0
    end

    return relationship
end

function _numerator_relationship(
    pedigree::Pedigree,
    rows::AbstractVector{<:Integer};
    max_relationship_cache::Integer = 10_000,
)
    A = _numerator_relationship(pedigree; max_relationship_cache = max_relationship_cache)
    return A[rows, rows]
end

"""
    inbreeding_coefficients(pedigree; max_relationship_cache = 10_000)
    inbreeding_coefficients(ids, sire, dam; max_relationship_cache = 10_000)

Return the inbreeding coefficient for each row of a normalized pedigree.

This Phase 1 utility uses a bounded numerator-relationship cache to compute the
parental inbreeding values needed by Henderson's direct inverse rules. It is
intended for validation and initial engine work, not for huge-scale claims.
"""
function inbreeding_coefficients(pedigree::Pedigree; max_relationship_cache::Integer = 10_000)
    relationship = _numerator_relationship(pedigree; max_relationship_cache = max_relationship_cache)
    return [relationship[i, i] - 1.0 for i in 1:length(pedigree)]
end

"""
    pedigree_inverse(pedigree; max_relationship_cache = 10_000)
    pedigree_inverse(ids, sire, dam; max_relationship_cache = 10_000)

Construct the sparse inverse additive relationship matrix `Ainv`.

The implementation follows Henderson's direct inverse contribution pattern:
each animal adds a scaled outer product of `[1, -1/2, -1/2]` over itself and its
known parents. The matrix is returned as a `SparseMatrixCSC{Float64,Int}`.
"""
function pedigree_inverse(pedigree::Pedigree; max_relationship_cache::Integer = 10_000)
    n = length(pedigree)
    parent_inbreeding = inbreeding_coefficients(pedigree; max_relationship_cache = max_relationship_cache)

    rows = Int[]
    cols = Int[]
    vals = Float64[]

    for animal in 1:n
        sire = pedigree.sire[animal]
        dam = pedigree.dam[animal]
        variance = _mendelian_sampling_variance(sire, dam, parent_inbreeding)
        variance > 0 ||
            throw(ArgumentError("non-positive Mendelian sampling variance for $(_repr(pedigree.ids[animal]))"))

        entries = Tuple{Int,Float64}[(animal, 1.0)]
        sire == 0 || push!(entries, (sire, -0.5))
        dam == 0 || push!(entries, (dam, -0.5))

        scale = inv(variance)
        for (row, row_weight) in entries
            for (col, col_weight) in entries
                push!(rows, row)
                push!(cols, col)
                push!(vals, scale * row_weight * col_weight)
            end
        end
    end

    return sparse(rows, cols, vals, n, n)
end

function pedigree_inverse(ids, sire, dam; kwargs...)
    return pedigree_inverse(normalize_pedigree(ids, sire, dam); kwargs...)
end

function inbreeding_coefficients(ids, sire, dam; kwargs...)
    return inbreeding_coefficients(normalize_pedigree(ids, sire, dam); kwargs...)
end

"""
    maternal_lineage(pedigree)
    maternal_lineage(ids, sire, dam)

Maternal-lineage label of each individual: the id of its earliest known maternal
ancestor (the maternal founder reached by following dam links). Two individuals
share a maternal lineage iff they carry the same label. Returned in
`pedigree.ids` (topologically sorted) order, aligned with
[`cytoplasmic_relationship`](@ref) and [`pedigree_inverse`](@ref).

This is the inheritance pattern of strictly maternally transmitted factors
(mitochondrial DNA / cytoplasm). An individual with no recorded dam is its own
maternal founder.
"""
function maternal_lineage(pedigree::Pedigree)
    n = length(pedigree)
    founder = Vector{Int}(undef, n)        # index of each individual's maternal founder
    for i in 1:n
        d = pedigree.dam[i]                # topological order ⇒ d == 0 or d < i
        founder[i] = d == 0 ? i : founder[d]
    end
    return [pedigree.ids[founder[i]] for i in 1:n]
end

maternal_lineage(ids, sire, dam) = maternal_lineage(normalize_pedigree(ids, sire, dam))

"""
    cytoplasmic_relationship(pedigree)
    cytoplasmic_relationship(ids, sire, dam)

Dense cytoplasmic (maternal-lineage) relationship matrix `C`: `C[i, j] = 1` if
`i` and `j` share a maternal lineage (see [`maternal_lineage`](@ref)), else `0`
(diagonal `1`). This is the relationship structure of strictly maternally
inherited factors (mitochondrial DNA, cytoplasm). Returned in `pedigree.ids`
(topologically sorted) order, so it aligns with [`pedigree_inverse`](@ref).

Experimental Phase 7 primitive — a relationship-construction helper for a
non-standard inheritance system. `C` is a 0/1 same-lineage indicator (rank =
number of maternal lineages), so it is singular whenever a lineage has more than
one member: use it as the relationship for an i.i.d. cytoplasmic lineage random
effect (a grouping), not as a matrix to invert.
"""
function cytoplasmic_relationship(pedigree::Pedigree)
    labels = maternal_lineage(pedigree)
    n = length(labels)
    C = zeros(Float64, n, n)
    for i in 1:n, j in 1:n
        C[i, j] = labels[i] == labels[j] ? 1.0 : 0.0
    end
    return C
end

cytoplasmic_relationship(ids, sire, dam) = cytoplasmic_relationship(normalize_pedigree(ids, sire, dam))

"""
    clonal_relationship(pedigree, clone_of)

Dense additive relationship matrix for a pedigree containing clonal (asexual)
ramets. `clone_of` is aligned to `pedigree.ids`: entry `i` is the id of the genet
that individual `i` is a clonal copy of, or an unknown-parent marker (`missing`,
`""`, `"0"`, `0`, …) if `i` is not a clone. Clonal ramets carry no new Mendelian
variation, so each ramet is genetically identical to its genet and inherits the
genet's whole row/column of the numerator relationship: `C[i, j] = A[rep(i),
rep(j)]`, where `rep` maps each individual to its ultimate genet (clone links are
followed transitively). Returned in `pedigree.ids` order, aligned with
[`pedigree_inverse`](@ref).

Experimental Phase 3 non-standard-inheritance primitive. Because clonemates are
identical rows, `C` is rank-deficient — it is a relationship matrix to use
directly, not to invert. Record the genets sexually in `pedigree`; record ramets
with unknown parents and mark them through `clone_of`.
"""
function clonal_relationship(pedigree::Pedigree, clone_of)
    n = length(pedigree)
    length(clone_of) == n ||
        throw(ArgumentError("clone_of must have one entry per pedigree individual"))
    id_to_index = Dict(id => i for (i, id) in pairs(pedigree.ids))
    genet = zeros(Int, n)              # genet index for each clone, 0 if not a clone
    for i in 1:n
        c = clone_of[i]
        _is_unknown_parent(c, DEFAULT_UNKNOWN_PARENT_VALUES) && continue
        haskey(id_to_index, c) ||
            throw(ArgumentError("clone_of references unknown genet id: $(_repr(c))"))
        genet[i] = id_to_index[c]
    end
    rep = collect(1:n)                 # resolve each individual to its ultimate genet
    for i in 1:n
        j = i
        steps = 0
        while genet[j] != 0
            j = genet[j]
            steps += 1
            steps > n &&
                throw(ArgumentError("clonal cycle detected starting from $(_repr(pedigree.ids[i]))"))
        end
        rep[i] = j
    end
    A = _numerator_relationship(pedigree)
    C = Matrix{Float64}(undef, n, n)
    for i in 1:n, j in 1:n
        C[i, j] = A[rep[i], rep[j]]
    end
    return C
end

"""
    dominance_relationship(pedigree)
    dominance_relationship(ids, sire, dam)

Dense dominance relationship matrix `D` (Cockerham). For animals `x`, `y` with
both parents known — sires `sx, sy`, dams `dx, dy` —
`D[x, y] = ¼·(A[sx, sy]·A[dx, dy] + A[sx, dy]·A[dx, sy])`, where `A` is the
additive numerator relationship. The diagonal is set to `1`, and any pair in
which either animal has an unknown parent has `D = 0`. Returned in `pedigree.ids`
order, aligned with [`pedigree_inverse`](@ref).

Experimental Phase 3 primitive, validation-scale and dense — `D` is the
relationship for a dominance random effect. The off-diagonal formula is general;
the unit diagonal and the absence of dominance-inbreeding corrections hold for
non-inbred parents (the standard textbook case). Full sibs have `D = 1/4`, half
sibs and parent–offspring `D = 0`.
"""
function dominance_relationship(pedigree::Pedigree)
    n = length(pedigree)
    A = _numerator_relationship(pedigree)
    s = pedigree.sire
    d = pedigree.dam
    D = Matrix{Float64}(undef, n, n)
    for i in 1:n
        D[i, i] = 1.0
        for j in 1:(i - 1)
            if s[i] != 0 && d[i] != 0 && s[j] != 0 && d[j] != 0
                value = 0.25 * (A[s[i], s[j]] * A[d[i], d[j]] +
                                A[s[i], d[j]] * A[d[i], s[j]])
            else
                value = 0.0
            end
            D[i, j] = value
            D[j, i] = value
        end
    end
    return D
end

dominance_relationship(ids, sire, dam) = dominance_relationship(normalize_pedigree(ids, sire, dam))

function _parent_index(parent, id_to_index::Dict{Any,Int}, missing_values, role::Symbol, child_id)
    _is_unknown_parent(parent, missing_values) && return 0
    haskey(id_to_index, parent) &&
        return id_to_index[parent]

    throw(ArgumentError("$(role) $(_repr(parent)) for id $(_repr(child_id)) is not present in ids"))
end

function _topological_order(ids, sire_index::Vector{Int}, dam_index::Vector{Int})
    n = length(ids)
    state = zeros(UInt8, n)
    order = Int[]

    function visit(index)
        state[index] == 2 && return nothing
        state[index] == 1 &&
            throw(ArgumentError("pedigree contains a parent-offspring cycle involving $(_repr(ids[index]))"))

        state[index] = 1
        sire_index[index] == 0 || visit(sire_index[index])
        dam_index[index] == 0 || visit(dam_index[index])
        state[index] = 2
        push!(order, index)
        return nothing
    end

    for index in 1:n
        visit(index)
    end

    return order
end

function _mendelian_sampling_variance(sire::Int, dam::Int, parent_inbreeding::Vector{Float64})
    if sire == 0 && dam == 0
        return 1.0
    elseif sire == 0
        return 0.75 - 0.25 * parent_inbreeding[dam]
    elseif dam == 0
        return 0.75 - 0.25 * parent_inbreeding[sire]
    else
        return 0.5 - 0.25 * (parent_inbreeding[sire] + parent_inbreeding[dam])
    end
end

function _is_unknown_parent(value, missing_values)
    return any(marker -> isequal(value, marker), missing_values)
end

function _repr(value)
    return sprint(show, value)
end
