"""
    HSDataIDMap

Conservative ID-overlap summary for [`HSData`](@ref).

IDs are matched exactly with Julia equality. The first slice deliberately does
not coerce `1` to `"1"` or otherwise normalize values across sources.
"""
struct HSDataIDMap
    phenotype_ids::Vector{Any}
    pedigree_ids::Vector{Any}
    genotype_ids::Vector{Any}
    expression_ids::Vector{Any}
    phenotypes_without_pedigree::Vector{Any}
    phenotypes_without_genotypes::Vector{Any}
    phenotypes_without_expression::Vector{Any}
    genotypes_without_phenotypes::Vector{Any}
    expression_without_phenotypes::Vector{Any}
end

"""
    HSData

In-memory container for matched phenotypes, pedigree, genotypes, expression,
marker annotation, and environmental data.

This is a conservative Phase 1 mirror of the R `hs_data()` contract. It stores
the supplied objects and records exact-ID overlap diagnostics, but it does not
construct relationship matrices, read file-backed data, or fit a model.
"""
struct HSData{TP,TPed,TG,TM,TE,TA,TEnv}
    phenotypes::TP
    pedigree::TPed
    genotypes::TG
    markers::TM
    expression::TE
    annotation::TA
    environment::TEnv
    id_map::HSDataIDMap
end

function Base.show(io::IO, data::HSData)
    print(
        io,
        "HSData(",
        length(data.id_map.phenotype_ids),
        " phenotype IDs, ",
        length(data.id_map.pedigree_ids),
        " pedigree IDs, ",
        length(data.id_map.genotype_ids),
        " genotype IDs)",
    )
end

function Base.show(io::IO, id_map::HSDataIDMap)
    print(
        io,
        "HSDataIDMap(",
        length(id_map.phenotype_ids),
        " phenotype IDs)",
    )
end

"""
    HSData(phenotypes; id = :id, pedigree = nothing, genotypes = nothing, ...)
    HSData(; phenotypes, id = :id, pedigree = nothing, genotypes = nothing, ...)

Create an in-memory data container and ID-overlap map.

Required:

- `phenotypes`: table-like object with an ID column.

Optional:

- `pedigree`: either a normalized [`Pedigree`](@ref) or table-like object with
  a pedigree ID column;
- `genotypes`: table-like or matrix-like object with `genotype_ids` supplied
  for matrix-like data, or an ID column for table-like data;
- `markers`, `expression`, `annotation`, and `environment`: stored as supplied.

When a pedigree is supplied, every unique phenotype ID must appear in the
pedigree IDs. Genotype and expression mismatches are recorded in `id_map`
instead of rejected, because ungenotyped and unexpressed phenotyped individuals
are valid inputs for later phases.
"""
function HSData(
    phenotypes;
    id = :id,
    pedigree = nothing,
    pedigree_id = :id,
    genotypes = nothing,
    genotype_id = :id,
    genotype_ids = nothing,
    markers = nothing,
    expression = nothing,
    expression_id = :id,
    expression_ids = nothing,
    annotation = nothing,
    environment = nothing,
)
    return HSData(;
        phenotypes = phenotypes,
        id = id,
        pedigree = pedigree,
        pedigree_id = pedigree_id,
        genotypes = genotypes,
        genotype_id = genotype_id,
        genotype_ids = genotype_ids,
        markers = markers,
        expression = expression,
        expression_id = expression_id,
        expression_ids = expression_ids,
        annotation = annotation,
        environment = environment,
    )
end

function HSData(;
    phenotypes,
    id = :id,
    pedigree = nothing,
    pedigree_id = :id,
    genotypes = nothing,
    genotype_id = :id,
    genotype_ids = nothing,
    markers = nothing,
    expression = nothing,
    expression_id = :id,
    expression_ids = nothing,
    annotation = nothing,
    environment = nothing,
)
    phenotype_ids = _unique_ids(_column(phenotypes, id, "phenotypes"), "phenotype"; allow_repeated = true)
    isempty(phenotype_ids) &&
        throw(ArgumentError("phenotypes must contain at least one non-missing ID"))

    pedigree_ids = _pedigree_ids(pedigree, pedigree_id)
    genotype_ids_vec = _source_ids(
        genotypes,
        genotype_id,
        genotype_ids,
        "genotypes";
        allow_repeated = false,
    )
    expression_ids_vec = _source_ids(
        expression,
        expression_id,
        expression_ids,
        "expression";
        allow_repeated = false,
    )

    phenotypes_without_pedigree = _ordered_setdiff(phenotype_ids, pedigree_ids)
    if pedigree !== nothing && !isempty(phenotypes_without_pedigree)
        throw(
            ArgumentError(
                "all phenotype IDs must be present in pedigree; missing $(length(phenotypes_without_pedigree)): $(_repr(phenotypes_without_pedigree[1]))",
            ),
        )
    end

    map = HSDataIDMap(
        phenotype_ids,
        pedigree_ids,
        genotype_ids_vec,
        expression_ids_vec,
        phenotypes_without_pedigree,
        _ordered_setdiff(phenotype_ids, genotype_ids_vec),
        _ordered_setdiff(phenotype_ids, expression_ids_vec),
        _ordered_setdiff(genotype_ids_vec, phenotype_ids),
        _ordered_setdiff(expression_ids_vec, phenotype_ids),
    )

    return HSData(
        phenotypes,
        pedigree,
        genotypes,
        markers,
        expression,
        annotation,
        environment,
        map,
    )
end

"""
    id_map(data)

Return the conservative ID-overlap map stored in an [`HSData`](@ref).
"""
function id_map(data::HSData)
    return data.id_map
end

function _pedigree_ids(::Nothing, pedigree_id)
    return Any[]
end

function _pedigree_ids(pedigree::Pedigree, pedigree_id)
    return _unique_ids(pedigree.ids, "pedigree"; allow_repeated = false)
end

function _pedigree_ids(pedigree, pedigree_id)
    return _unique_ids(_column(pedigree, pedigree_id, "pedigree"), "pedigree"; allow_repeated = false)
end

function _source_ids(::Nothing, column, explicit_ids, role; allow_repeated::Bool)
    explicit_ids === nothing ||
        throw(ArgumentError("$(role) IDs were supplied but $(role) data is nothing"))
    return Any[]
end

function _source_ids(source, column, explicit_ids, role; allow_repeated::Bool)
    if explicit_ids !== nothing
        ids = _unique_ids(explicit_ids, role; allow_repeated = allow_repeated)
        row_count = _row_count(source)
        row_count === nothing || length(ids) == row_count ||
            throw(ArgumentError("$(role) IDs length must match the number of rows in $(role)"))
        return ids
    end

    return _unique_ids(_column(source, column, role), role; allow_repeated = allow_repeated)
end

function _column(source, column, role::AbstractString)
    name = _column_symbol(column, role)
    if source isa AbstractDict
        haskey(source, name) && return source[name]
        string_name = String(name)
        haskey(source, string_name) && return source[string_name]
    end

    if name in propertynames(source)
        return getproperty(source, name)
    end

    throw(ArgumentError("$(role) must contain ID column :$(name), or explicit IDs must be supplied"))
end

function _column_symbol(column::Symbol, role)
    return column
end

function _column_symbol(column::AbstractString, role)
    return Symbol(column)
end

function _column_symbol(column, role)
    throw(ArgumentError("$(role) ID column must be a Symbol or string"))
end

function _unique_ids(ids, role::AbstractString; allow_repeated::Bool)
    values = Any[]
    seen = Set{Any}()
    for id in ids
        _is_missing_id(id) &&
            throw(ArgumentError("$(role) IDs cannot contain missing, nothing, or empty strings"))
        if !(id in seen)
            push!(values, id)
            push!(seen, id)
        elseif !allow_repeated
            throw(ArgumentError("duplicate $(role) ID: $(_repr(id))"))
        end
    end
    return values
end

function _ordered_setdiff(left, right)
    right_set = Set(right)
    return Any[id for id in left if !(id in right_set)]
end

function _row_count(source)
    try
        return size(source, 1)
    catch
        return nothing
    end
end

function _is_missing_id(id)
    return ismissing(id) || id === nothing || (id isa AbstractString && isempty(id))
end
