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
    mendelian_sampling_variances(pedigree; max_relationship_cache = 10_000)
    mendelian_sampling_variances(ids, sire, dam; max_relationship_cache = 10_000)

Per-individual Mendelian sampling variances `d_i` — the diagonal of `D` in the
decomposition `A = T·D·Tᵀ` of the additive relationship matrix (`T` unit
lower-triangular). `d_i` is the variance of an individual's breeding value
*given its parents*: `1` for a founder, `0.75 − 0.25·F_parent` with one known
parent, and `0.5 − 0.25·(F_sire + F_dam)` with both known. Returned in
`pedigree.ids` (topologically sorted) order; `det(A) = ∏_i d_i`.

These are the reciprocals (`1/d_i`) that scale the Henderson `pedigree_inverse`
contributions, and the within-family variances used in gene-dropping and
within-family accuracy.
"""
function mendelian_sampling_variances(pedigree::Pedigree; max_relationship_cache::Integer = 10_000)
    F = inbreeding_coefficients(pedigree; max_relationship_cache = max_relationship_cache)
    return [_mendelian_sampling_variance(pedigree.sire[i], pedigree.dam[i], F)
            for i in 1:length(pedigree)]
end

mendelian_sampling_variances(ids, sire, dam; kwargs...) =
    mendelian_sampling_variances(normalize_pedigree(ids, sire, dam); kwargs...)

"""
    additive_relationship(pedigree; max_relationship_cache = 10_000)
    additive_relationship(ids, sire, dam; max_relationship_cache = 10_000)

Dense additive (numerator) relationship matrix `A` for a pedigree — the companion
of the sparse [`pedigree_inverse`](@ref) (`A = inv(Ainv)`). `A[i, i] = 1 + F_i`
and `A[i, j]` is twice the coancestry of `i` and `j`. Returned in `pedigree.ids`
(topologically sorted) order.

Validation-scale and dense (bounded by `max_relationship_cache`); for production
use the sparse `pedigree_inverse`. This is the additive companion of the exported
[`dominance_relationship`](@ref), [`cytoplasmic_relationship`](@ref), and
[`clonal_relationship`](@ref) matrices.
"""
additive_relationship(pedigree::Pedigree; max_relationship_cache::Integer = 10_000) =
    _numerator_relationship(pedigree; max_relationship_cache = max_relationship_cache)

additive_relationship(ids, sire, dam; kwargs...) =
    additive_relationship(normalize_pedigree(ids, sire, dam); kwargs...)

# --- Meuwissen & Luo (1992) O(n·ancestors) inbreeding ---------------------------
# Minimal binary max-heap over ancestor row indices (no external dependency) so the
# ancestor traversal visits indices in strictly descending order.

@inline function _ml_heappush!(h::Vector{Int}, x::Int)
    push!(h, x)
    i = length(h)
    @inbounds while i > 1
        p = i >> 1
        h[p] >= h[i] && break
        h[p], h[i] = h[i], h[p]
        i = p
    end
    return h
end

@inline function _ml_heappop_max!(h::Vector{Int})
    @inbounds begin
        top = h[1]
        last = pop!(h)
        if !isempty(h)
            h[1] = last
            n = length(h); i = 1
            while true
                l = 2i; r = l + 1; m = i
                (l <= n && h[l] > h[m]) && (m = l)
                (r <= n && h[r] > h[m]) && (m = r)
                m == i && break
                h[i], h[m] = h[m], h[i]
                i = m
            end
        end
        return top
    end
end

"""
    _meuwissen_luo_inbreeding(pedigree) -> Vector{Float64}

Inbreeding coefficient `F_i` for every animal by the Meuwissen & Luo (1992)
method. Accumulate the `T`-row of `A = T·D·Tᵀ` for animal `i` over its ancestors
(processed youngest-first via a max-heap): `A_ii = Σ_j L_ij² d_j`, so
`F_i = A_ii − 1`, where `d_j = 0.5 − 0.25(F_sire(j) + F_dam(j))` is the Mendelian
sampling variance (unknown-parent sentinel `F_0 = −1`). Runs in ~O(n·ancestors)
and never forms the dense `A`; the dense `_numerator_relationship`
diagonal is the validation oracle. Requires a topologically sorted pedigree
(parents before offspring), as produced by [`normalize_pedigree`](@ref).
"""
function _meuwissen_luo_inbreeding(pedigree::Pedigree)
    n = length(pedigree)
    sire = pedigree.sire
    dam = pedigree.dam
    F = zeros(Float64, n)
    L = zeros(Float64, n)          # working T-row (ancestor contributions)
    heap = Int[]
    sizehint!(heap, 64)
    f0(k) = k == 0 ? -1.0 : F[k]   # unknown-parent inbreeding sentinel
    @inbounds for i in 1:n
        s = sire[i]; d = dam[i]
        if s == 0 || d == 0
            F[i] = 0.0             # at least one unknown parent ⇒ not inbred
            continue
        end
        L[i] = 1.0
        _ml_heappush!(heap, i)
        fi = 0.0
        while !isempty(heap)
            j = _ml_heappop_max!(heap)
            lj = L[j]; L[j] = 0.0
            dj = 0.5 - 0.25 * (f0(sire[j]) + f0(dam[j]))
            fi += lj * lj * dj
            sj = sire[j]
            if sj != 0
                (L[sj] == 0.0) && _ml_heappush!(heap, sj)
                L[sj] += 0.5 * lj
            end
            dmj = dam[j]
            if dmj != 0
                (L[dmj] == 0.0) && _ml_heappush!(heap, dmj)
                L[dmj] += 0.5 * lj
            end
        end
        F[i] = fi - 1.0
    end
    return F
end

"""
    inbreeding_coefficients(pedigree; max_relationship_cache = 10_000)
    inbreeding_coefficients(ids, sire, dam; max_relationship_cache = 10_000)

Return the inbreeding coefficient for each row of a normalized pedigree.

Inbreeding is computed by the Meuwissen & Luo (1992) method
(`_meuwissen_luo_inbreeding`) in ~O(n·ancestors) without forming the dense
relationship matrix, so it scales to large pedigrees. `max_relationship_cache` is
accepted for signature compatibility but no longer bounds this path (it still
governs the dense `_numerator_relationship` used by `additive_relationship`
and single-step A₂₂, and as the inbreeding validation oracle).
"""
function inbreeding_coefficients(pedigree::Pedigree; max_relationship_cache::Integer = 10_000)
    return _meuwissen_luo_inbreeding(pedigree)
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

"""
    epistatic_relationship(pedigree; kind = :additive_additive)
    epistatic_relationship(ids, sire, dam; kind = :additive_additive)

Dense epistatic relationship matrix as a Hadamard (element-wise) product of the
additive `A` and dominance `D` relationship matrices (Henderson 1985):

- `kind = :additive_additive` → `A ∘ A`,
- `kind = :additive_dominance` → `A ∘ D`,
- `kind = :dominance_dominance` → `D ∘ D`.

These give the orthogonal additive×additive, additive×dominance, and
dominance×dominance epistatic relationship matrices used for epistatic variance
components. Full sibs have additive×additive `= 1/4`. Returned in `pedigree.ids`
order. Experimental Phase 3 primitive, validation-scale and dense; inherits the
[`dominance_relationship`](@ref) non-inbred-parent assumption. No public
model-spec.
"""
function epistatic_relationship(pedigree::Pedigree; kind::Symbol = :additive_additive)
    if kind === :additive_additive
        A = additive_relationship(pedigree)
        return A .* A
    elseif kind === :additive_dominance
        return additive_relationship(pedigree) .* dominance_relationship(pedigree)
    elseif kind === :dominance_dominance
        D = dominance_relationship(pedigree)
        return D .* D
    else
        throw(ArgumentError("kind must be :additive_additive, :additive_dominance, or :dominance_dominance"))
    end
end

epistatic_relationship(ids, sire, dam; kwargs...) =
    epistatic_relationship(normalize_pedigree(ids, sire, dam); kwargs...)

# --- Metafounders (supplied Γ, descriptive, validation-scale) — Legarra et al. 2015 -----
#
# `A^Γ` generalizes the numerator relationship to UNKNOWN-PARENT GROUPS ("metafounders")
# carrying a supplied `m×m` covariance `Γ`. Each unknown parent slot is remapped to a
# metafounder column before the SAME tabular recursion runs; metafounders are seeded by
# `Γ` (metafounder self = `Γ[i,i]`, so metafounder inbreeding `F = Γ[i,i] − 1` may be
# negative) and inject founder relatedness. `Γ` is SUPPLIED, never estimated. At `Γ = 0`
# the metafounders become classical unrelated, non-inbred founders and `A^Γ` collapses to
# the standard `A` (the primary correctness anchor). Validation-scale and dense.

# Resolve the metafounder assignment into combined parent-index arrays over the augmented
# index `[metafounders 1..m; animals m+1..m+n]`. `group_of` is aligned to `pedigree.ids`
# (like `clone_of`): entry `i` is the metafounder-group label for animal `i`'s unknown
# parent slot(s); animals with both parents known carry an unknown-parent marker. Distinct
# labels resolve to columns `1..m` in stable first-appearance order. Every real animal's
# unknown parent is remapped to its metafounder column, so no literal `0` survives for an
# animal (a leftover unknown without a group label is a hard error, not a silent fallback).
function _metafounder_combined_indices(pedigree::Pedigree, group_of)
    n = length(pedigree)
    length(group_of) == n ||
        throw(ArgumentError("group_of must have one entry per pedigree individual"))
    label_to_col = Dict{Any,Int}()
    group_labels = Vector{Any}()
    needs = [pedigree.sire[i] == 0 || pedigree.dam[i] == 0 for i in 1:n]
    for i in 1:n
        needs[i] || continue
        label = group_of[i]
        _is_unknown_parent(label, DEFAULT_UNKNOWN_PARENT_VALUES) &&
            throw(ArgumentError("animal $(_repr(pedigree.ids[i])) has an unknown parent but no metafounder group label in group_of"))
        if !haskey(label_to_col, label)
            push!(group_labels, label)
            label_to_col[label] = length(group_labels)
        end
    end
    m = length(group_labels)
    sire_c = zeros(Int, m + n)
    dam_c = zeros(Int, m + n)
    for i in 1:n
        s = pedigree.sire[i]
        d = pedigree.dam[i]
        sire_c[m + i] = s == 0 ? label_to_col[group_of[i]] : m + s
        dam_c[m + i] = d == 0 ? label_to_col[group_of[i]] : m + d
    end
    return sire_c, dam_c, m, group_labels
end

# Validate the supplied metafounder covariance. `require_pd` for the inverse path (needs
# `Γ⁻¹`); PSD for the relationship path. Returns the symmetrized `Symmetric` view.
function _validate_gamma(Gamma::AbstractMatrix, m::Int; require_pd::Bool)
    size(Gamma, 1) == m && size(Gamma, 2) == m ||
        throw(ArgumentError("Gamma must be $(m)×$(m) (one row/column per resolved metafounder group); got $(size(Gamma))"))
    G = Matrix{Float64}(Gamma)
    all(isfinite, G) || throw(ArgumentError("Gamma must contain only finite values"))
    scale = max(1.0, maximum(abs, G; init = 1.0))
    maximum(abs.(G .- transpose(G)); init = 0.0) <= 1e-10 * scale ||
        throw(ArgumentError("Gamma must be symmetric"))
    Gsym = Symmetric(0.5 .* (G .+ transpose(G)))
    if m >= 1
        evmin = eigmin(Gsym)
        if require_pd
            evmin > 1e-12 * scale ||
                throw(ArgumentError("Gamma must be positive definite for the inverse path (eigmin = $(evmin))"))
        else
            evmin >= -1e-10 * scale ||
                throw(ArgumentError("Gamma must be positive semidefinite (eigmin = $(evmin))"))
        end
    end
    return Gsym
end

# Dense combined relationship over `[metafounders 1..m; animals m+1..m+n]`: seed the `Γ`
# block, then the EXISTING tabular off-diagonal/diagonal rules over the animal rows
# (metafounder parents inject founder relatedness; metafounders are pre-seeded, not
# recursed). Animals are already topologically sorted, so `m+1..N` respects dependencies.
function _metafounder_combined_A(m::Int, Gamma::AbstractMatrix, sire_c::Vector{Int}, dam_c::Vector{Int})
    N = length(sire_c)
    A = zeros(Float64, N, N)
    @inbounds for j in 1:m, i in 1:m
        A[i, j] = Gamma[i, j]
    end
    @inbounds for k in (m + 1):N
        s = sire_c[k]
        d = dam_c[k]
        for j in 1:(k - 1)
            val = 0.5 * (A[s, j] + A[d, j])
            A[k, j] = val
            A[j, k] = val
        end
        A[k, k] = 1.0 + 0.5 * A[s, d]
    end
    return A
end

"""
    metafounder_relationship(pedigree, group_of, Gamma; max_relationship_cache = 10_000)
    metafounder_relationship(ids, sire, dam, group_of, Gamma; ...)

Dense metafounder-augmented additive relationship matrix `A^Γ` (animal × animal, in
`pedigree.ids` order) for a SUPPLIED `m×m` symmetric positive-semidefinite metafounder
covariance `Γ` and a metafounder assignment `group_of`. `group_of` is aligned to
`pedigree.ids` like [`clonal_relationship`](@ref)'s `clone_of`: entry `i` is the
metafounder-group label of animal `i`'s unknown parent slot(s) (both unknown parents of
an animal share one group this slice); animals with both parents known carry an
unknown-parent marker. Distinct labels resolve to `Γ`'s rows `1..m` in stable
first-appearance order.

`A^Γ` is the existing tabular recursion with the leading `Γ` block seeded: a metafounder's
self-relationship is `Γ[i,i]` (so its inbreeding `F = Γ[i,i] − 1`, which is NEGATIVE for
`Γ[i,i] < 1`), and an animal's two unknown parents drawn from the same group `m` make it
inbred with `A_ii = 1 + Γ[m,m]/2` and two such founders related by `Γ[m,m]`. At `Γ = 0`
the result equals [`additive_relationship`](@ref) exactly.

`Γ` is SUPPLIED, NOT estimated. EXPERIMENTAL, validation-scale and dense (bounded by
`max_relationship_cache`); no external (BLUPF90) comparator, no R-facing metafounder
model-spec, no single-step `H^Γ`. Scale convention: `Γ[m,m]` is on the relationship scale
(`Γ[m,m] = 0` ⇒ classical founder), not an allele-frequency parameterization.
"""
function metafounder_relationship(pedigree::Pedigree, group_of, Gamma::AbstractMatrix;
                                  max_relationship_cache::Integer = 10_000)
    n = length(pedigree)
    n <= max_relationship_cache ||
        throw(ArgumentError("metafounder_relationship uses a bounded relationship cache; got $(n) rows and max_relationship_cache = $(max_relationship_cache)"))
    sire_c, dam_c, m, _ = _metafounder_combined_indices(pedigree, group_of)
    Gsym = _validate_gamma(Gamma, m; require_pd = false)
    A = _metafounder_combined_A(m, Matrix(Gsym), sire_c, dam_c)
    return A[(m + 1):(m + n), (m + 1):(m + n)]
end

metafounder_relationship(ids, sire, dam, group_of, Gamma::AbstractMatrix; kwargs...) =
    metafounder_relationship(normalize_pedigree(ids, sire, dam), group_of, Gamma; kwargs...)

"""
    metafounder_relationship_inverse(pedigree, group_of, Gamma; max_relationship_cache = 10_000)
    metafounder_relationship_inverse(ids, sire, dam, group_of, Gamma; ...)

DESCRIPTIVE dense inverse of the ANIMAL block of `A^Γ`, i.e. `inv(A^Γ_animals)`. This is
**distinct** from [`metafounder_inverse`](@ref): it is NOT the animal sub-block of the
combined `[metafounders; animals]` precision (conflating the two corrupts either the MME
or the descriptive inverse). At `Γ = 0` it equals `Matrix(pedigree_inverse(pedigree))`.
Validation-scale and dense; `Γ` supplied, not estimated.
"""
function metafounder_relationship_inverse(pedigree::Pedigree, group_of, Gamma::AbstractMatrix;
                                          max_relationship_cache::Integer = 10_000)
    A = metafounder_relationship(pedigree, group_of, Gamma; max_relationship_cache = max_relationship_cache)
    return inv(Symmetric(A))
end

metafounder_relationship_inverse(ids, sire, dam, group_of, Gamma::AbstractMatrix; kwargs...) =
    metafounder_relationship_inverse(normalize_pedigree(ids, sire, dam), group_of, Gamma; kwargs...)

"""
    metafounder_inbreeding(pedigree, group_of, Gamma; max_relationship_cache = 10_000)
    metafounder_inbreeding(ids, sire, dam, group_of, Gamma; ...)

Metafounder-aware inbreeding coefficient `F_i = A^Γ[i,i] − 1` for each animal (in
`pedigree.ids` order). Under metafounders an animal can have `F < 0` (heterozygote excess)
when its metafounder self-relationship `Γ < 1`. `Γ` supplied, not estimated.
"""
function metafounder_inbreeding(pedigree::Pedigree, group_of, Gamma::AbstractMatrix;
                                max_relationship_cache::Integer = 10_000)
    A = metafounder_relationship(pedigree, group_of, Gamma; max_relationship_cache = max_relationship_cache)
    return [A[i, i] - 1.0 for i in 1:length(pedigree)]
end

metafounder_inbreeding(ids, sire, dam, group_of, Gamma::AbstractMatrix; kwargs...) =
    metafounder_inbreeding(normalize_pedigree(ids, sire, dam), group_of, Gamma; kwargs...)

"""
    metafounder_inverse(pedigree, group_of, Gamma; max_relationship_cache = 10_000)
    metafounder_inverse(ids, sire, dam, group_of, Gamma; ...)

MME-ready sparse inverse of the COMBINED metafounder-augmented relationship over
`[metafounders 1..m; animals m+1..m+n]` (dimension `(m+n)×(m+n)`): the metafounder block
is seeded with `inv(Γ)` and each animal adds the existing Henderson `[1, −½, −½]/d_k`
outer product over its (animal, sire, dam) combined indices, where a parent index may be a
metafounder column. The Mendelian sampling variance `d_k = ½ − ¼(F_s + F_d)` uses the
combined inbreeding (metafounder `F = Γ − 1`), so `d_k` may EXCEED ½ (heterozygote excess)
— this is correct and not clamped.

Requires `Γ` symmetric POSITIVE DEFINITE (it inverts `Γ`). The leading `m` rows/columns
are the metafounder solutions; the animal block of this combined inverse is **not**
`inv(A^Γ_animals)` (see [`metafounder_relationship_inverse`](@ref)). `A_combined · this ≈
I` is the round-trip correctness anchor. Returned as a `SparseMatrixCSC{Float64,Int}`,
mirroring [`pedigree_inverse`](@ref). EXPERIMENTAL, validation-scale (still forms the dense
`A^Γ` to get `d_k`, bounded by `max_relationship_cache`); not wired into `henderson_mme`
this slice (the extra metafounder levels need the R bridge contract). `Γ` supplied.
"""
function metafounder_inverse(pedigree::Pedigree, group_of, Gamma::AbstractMatrix;
                             max_relationship_cache::Integer = 10_000)
    n = length(pedigree)
    n <= max_relationship_cache ||
        throw(ArgumentError("metafounder_inverse uses a bounded relationship cache; got $(n) rows and max_relationship_cache = $(max_relationship_cache)"))
    sire_c, dam_c, m, _ = _metafounder_combined_indices(pedigree, group_of)
    Gsym = _validate_gamma(Gamma, m; require_pd = true)
    A = _metafounder_combined_A(m, Matrix(Gsym), sire_c, dam_c)
    N = m + n
    F = [A[x, x] - 1.0 for x in 1:N]

    rows = Int[]
    cols = Int[]
    vals = Float64[]
    Ginv = inv(Gsym)
    for j in 1:m, i in 1:m
        push!(rows, i); push!(cols, j); push!(vals, Ginv[i, j])
    end
    for k in (m + 1):N
        s = sire_c[k]
        d = dam_c[k]
        variance = _mendelian_sampling_variance(s, d, F)   # s,d ≥ 1 ⇒ both-known branch
        variance > 0 ||
            throw(ArgumentError("non-positive Mendelian sampling variance for $(_repr(pedigree.ids[k - m]))"))
        scale = inv(variance)
        entries = ((k, 1.0), (s, -0.5), (d, -0.5))
        for (row, row_weight) in entries
            for (col, col_weight) in entries
                push!(rows, row); push!(cols, col); push!(vals, scale * row_weight * col_weight)
            end
        end
    end
    return sparse(rows, cols, vals, N, N)
end

metafounder_inverse(ids, sire, dam, group_of, Gamma::AbstractMatrix; kwargs...) =
    metafounder_inverse(normalize_pedigree(ids, sire, dam), group_of, Gamma; kwargs...)

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
