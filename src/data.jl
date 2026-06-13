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
    HSMarkerMapSpec

Validated marker-map metadata stored by [`HSData`](@ref).

This is metadata hygiene only. It does not parse genotype files, impute marker
dosages, construct genomic relationships, or run marker scans.
"""
struct HSMarkerMapSpec
    columns::NamedTuple{(:marker, :chromosome, :position),Tuple{Any,Any,Any}}
    marker_ids::Vector{String}
    chromosome::Vector{String}
    position::Vector{Float64}
end

"""
    HSGenotypeMarkerSpec

Validated alignment between genotype marker columns and a marker map.
"""
struct HSGenotypeMarkerSpec
    marker_ids::Vector{String}
    marker_map_index::Vector{Int}
end

"""
    HSDataIDOverlapRow

One ID-overlap count returned by [`data_status`](@ref).
"""
struct HSDataIDOverlapRow
    metric::String
    count::Int
end

"""
    HSDataMarkerStatusRow

One marker-map or genotype-marker diagnostic returned by [`data_status`](@ref).
"""
struct HSDataMarkerStatusRow
    metric::String
    value::String
end

"""
    HSDataStatus

Diagnostic container returned by [`data_status`](@ref).

This mirrors the R twin's `data_status()` surface for component presence,
ID-overlap counts, and marker-map/genotype-marker alignment status. It is
diagnostic only and does not build model specifications or relationship
matrices.
"""
struct HSDataStatus
    components::Vector{Symbol}
    id_overlap::Vector{HSDataIDOverlapRow}
    marker_status::Union{Nothing,Vector{HSDataMarkerStatusRow}}
end

"""
    HSData

In-memory container for matched phenotypes, pedigree, genotypes, expression,
marker annotation, and environmental data.

This is a conservative Phase 1 mirror of the R `hs_data()` contract. It stores
the supplied objects and records exact-ID overlap diagnostics, but it does not
construct relationship matrices, read file-backed data, or fit a model.
"""
struct HSData{TP,TPed,TG,TM,TMS,TGMS,TE,TA,TEnv}
    phenotypes::TP
    pedigree::TPed
    genotypes::TG
    markers::TM
    marker_spec::TMS
    genotype_marker_spec::TGMS
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

function Base.show(io::IO, status::HSDataStatus)
    print(io, "HSDataStatus(", join(string.(status.components), ", "), ")")
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
- `markers`: table-like marker metadata with marker, chromosome, and position
  columns, using common aliases;
- `expression`, `annotation`, and `environment`: stored as supplied.

When a pedigree is supplied, every unique phenotype ID must appear in the
pedigree IDs. Genotype and expression mismatches are recorded in `id_map`
instead of rejected, because ungenotyped and unexpressed phenotyped individuals
are valid inputs for later phases. When both `genotypes` and `markers` are
supplied, genotype marker names must match marker-map IDs exactly after marker
names are normalized to strings.
"""
function HSData(
    phenotypes;
    id = :id,
    pedigree = nothing,
    pedigree_id = :id,
    genotypes = nothing,
    genotype_id = :id,
    genotype_ids = nothing,
    genotype_marker_ids = nothing,
    markers = nothing,
    marker_id = nothing,
    chromosome = nothing,
    position = nothing,
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
        genotype_marker_ids = genotype_marker_ids,
        markers = markers,
        marker_id = marker_id,
        chromosome = chromosome,
        position = position,
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
    genotype_marker_ids = nothing,
    markers = nothing,
    marker_id = nothing,
    chromosome = nothing,
    position = nothing,
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
    marker_spec = _marker_map_spec(
        markers;
        marker_id = marker_id,
        chromosome = chromosome,
        position = position,
    )
    genotype_marker_spec = _genotype_marker_spec(
        genotypes,
        genotype_id,
        genotype_marker_ids,
        marker_spec,
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
        marker_spec,
        genotype_marker_spec,
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

"""
    data_status(data::HSData)

Return component, ID-overlap, and marker-alignment diagnostics for an
[`HSData`](@ref) object.

This mirrors the R twin's `data_status()` helper. It does not parse genotype
files, construct genomic relationships, build bridge payloads, or fit models.
"""
function data_status(data::HSData)
    return HSDataStatus(
        _data_components(data),
        _data_id_overlap(data.id_map),
        _data_marker_status(data),
    )
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

function _marker_map_spec(::Nothing; marker_id, chromosome, position)
    return nothing
end

function _marker_map_spec(markers; marker_id, chromosome, position)
    marker_column = _pick_marker_column(markers, marker_id, (:marker, :marker_id, :snp, :snp_id, :id), "marker")
    chromosome_column = _pick_marker_column(markers, chromosome, (:chromosome, :chr, :chrom), "chromosome")
    position_column = _pick_marker_column(markers, position, (:position, :pos, :bp, :base_pair), "position")

    marker_ids = _string_ids(_column(markers, marker_column, "markers"), "markers"; allow_repeated = false)
    chromosome_values = _chromosome_values(_column(markers, chromosome_column, "markers"))
    position_values = _position_values(_column(markers, position_column, "markers"))
    length(marker_ids) == length(chromosome_values) == length(position_values) ||
        throw(ArgumentError("markers columns must have equal lengths"))

    return HSMarkerMapSpec(
        (marker = marker_column, chromosome = chromosome_column, position = position_column),
        marker_ids,
        chromosome_values,
        position_values,
    )
end

function _genotype_marker_spec(genotypes, genotype_id, genotype_marker_ids, ::Nothing)
    genotype_marker_ids === nothing ||
        throw(ArgumentError("genotype_marker_ids requires markers to be supplied"))
    return nothing
end

function _genotype_marker_spec(::Nothing, genotype_id, genotype_marker_ids, marker_spec::HSMarkerMapSpec)
    genotype_marker_ids === nothing ||
        throw(ArgumentError("genotype_marker_ids were supplied but genotypes data is nothing"))
    return nothing
end

function _genotype_marker_spec(genotypes, genotype_id, genotype_marker_ids, marker_spec::HSMarkerMapSpec)
    marker_ids = _genotype_marker_ids(genotypes, genotype_id, genotype_marker_ids)

    missing_from_map = _ordered_setdiff(marker_ids, marker_spec.marker_ids)
    missing_from_genotypes = _ordered_setdiff(marker_spec.marker_ids, marker_ids)
    if !isempty(missing_from_map) || !isempty(missing_from_genotypes)
        details = String[]
        isempty(missing_from_map) || push!(details, "missing from markers: $(join(missing_from_map, ", "))")
        isempty(missing_from_genotypes) || push!(details, "missing from genotypes: $(join(missing_from_genotypes, ", "))")
        throw(ArgumentError("genotype marker columns must match marker IDs exactly; $(join(details, "; "))"))
    end

    marker_map_index = [findfirst(==(id), marker_spec.marker_ids)::Int for id in marker_ids]
    return HSGenotypeMarkerSpec(marker_ids, marker_map_index)
end

function _genotype_marker_ids(source::AbstractMatrix, genotype_id, genotype_marker_ids)
    genotype_marker_ids !== nothing ||
        throw(ArgumentError("matrix-like genotypes require genotype_marker_ids when markers are supplied"))
    marker_ids = _string_ids(genotype_marker_ids, "genotype marker columns"; allow_repeated = false)
    length(marker_ids) == size(source, 2) ||
        throw(ArgumentError("genotype_marker_ids length must match the number of columns in genotypes"))
    return marker_ids
end

function _genotype_marker_ids(source, genotype_id, genotype_marker_ids)
    if genotype_marker_ids !== nothing
        marker_ids = _string_ids(genotype_marker_ids, "genotype marker columns"; allow_repeated = false)
        column_count = _genotype_marker_column_count(source, genotype_id)
        column_count === nothing || length(marker_ids) == column_count ||
            throw(ArgumentError("genotype_marker_ids length must match the number of marker columns in genotypes"))
        return marker_ids
    end

    names = _column_names(source)
    names === nothing &&
        throw(ArgumentError("genotypes must be table-like or supply genotype_marker_ids when markers are supplied"))
    marker_columns = Any[name for name in names if !_same_column_name(name, genotype_id)]
    isempty(marker_columns) &&
        throw(ArgumentError("genotypes must contain at least one marker column when markers are supplied"))
    return _string_ids(marker_columns, "genotype marker columns"; allow_repeated = false)
end

function _pick_marker_column(source, explicit, aliases::Tuple, label::AbstractString)
    if explicit !== nothing
        name = _column_symbol(explicit, "markers")
        _column(source, name, "markers")
        return name
    end

    names = _column_names(source)
    names === nothing &&
        throw(ArgumentError("markers must be table-like with marker, chromosome, and position columns"))
    lower_names = lowercase.(string.(names))
    for alias in aliases
        hit = findfirst(==(String(alias)), lower_names)
        hit === nothing || return names[hit]
    end

    throw(
        ArgumentError(
            "markers must contain a $(label) column; recognized aliases include $(join(string.(aliases), ", "))",
        ),
    )
end

function _column_names(source)
    if source isa AbstractDict
        return collect(keys(source))
    elseif source isa AbstractMatrix
        return nothing
    else
        names = propertynames(source)
        isempty(names) && return nothing
        return collect(names)
    end
end

function _genotype_marker_column_count(source::AbstractMatrix, genotype_id)
    return size(source, 2)
end

function _genotype_marker_column_count(source, genotype_id)
    names = _column_names(source)
    names === nothing && return nothing
    return count(name -> !_same_column_name(name, genotype_id), names)
end

function _same_column_name(left, right)
    return string(left) == string(_column_symbol(right, "genotypes"))
end

function _string_ids(ids, role::AbstractString; allow_repeated::Bool)
    values = String[]
    seen = Set{String}()
    for id in ids
        _is_missing_id(id) &&
            throw(ArgumentError("$(role) IDs cannot contain missing, nothing, empty strings, or `0`"))
        value = string(id)
        (isempty(value) || value == "0") &&
            throw(ArgumentError("$(role) IDs cannot contain missing, nothing, empty strings, or `0`"))
        if !(value in seen)
            push!(values, value)
            push!(seen, value)
        elseif !allow_repeated
            throw(ArgumentError("duplicate $(role) ID: $(value)"))
        end
    end
    return values
end

function _chromosome_values(values)
    out = String[]
    for value in values
        _is_missing_id(value) &&
            throw(ArgumentError("markers chromosome column cannot contain missing or empty values"))
        chromosome = string(value)
        isempty(chromosome) &&
            throw(ArgumentError("markers chromosome column cannot contain missing or empty values"))
        push!(out, chromosome)
    end
    return out
end

function _position_values(values)
    return [_position_value(value) for value in values]
end

function _position_value(value)
    (ismissing(value) || value === nothing) &&
        throw(ArgumentError("markers position column must contain finite non-negative numeric positions"))
    position = if value isa Real
        Float64(value)
    elseif value isa AbstractString
        isempty(value) &&
            throw(ArgumentError("markers position column must contain finite non-negative numeric positions"))
        try
            parse(Float64, value)
        catch
            throw(ArgumentError("markers position column must contain finite non-negative numeric positions"))
        end
    else
        try
            Float64(value)
        catch
            throw(ArgumentError("markers position column must contain finite non-negative numeric positions"))
        end
    end

    isfinite(position) && position >= 0 ||
        throw(ArgumentError("markers position column must contain finite non-negative numeric positions"))
    return position
end

function _data_components(data::HSData)
    components = Symbol[]
    push!(components, :phenotypes)
    data.pedigree === nothing || push!(components, :pedigree)
    data.genotypes === nothing || push!(components, :genotypes)
    data.markers === nothing || push!(components, :markers)
    data.expression === nothing || push!(components, :expression)
    data.annotation === nothing || push!(components, :annotation)
    data.environment === nothing || push!(components, :environment)
    return components
end

function _data_id_overlap(map::HSDataIDMap)
    return [
        HSDataIDOverlapRow("phenotype_ids", length(map.phenotype_ids)),
        HSDataIDOverlapRow("pedigree_ids", length(map.pedigree_ids)),
        HSDataIDOverlapRow("genotype_ids", length(map.genotype_ids)),
        HSDataIDOverlapRow("expression_ids", length(map.expression_ids)),
        HSDataIDOverlapRow("phenotypes_without_pedigree", length(map.phenotypes_without_pedigree)),
        HSDataIDOverlapRow("phenotypes_without_genotypes", length(map.phenotypes_without_genotypes)),
        HSDataIDOverlapRow("genotypes_without_phenotypes", length(map.genotypes_without_phenotypes)),
        HSDataIDOverlapRow("phenotypes_without_expression", length(map.phenotypes_without_expression)),
        HSDataIDOverlapRow("expression_without_phenotypes", length(map.expression_without_phenotypes)),
    ]
end

function _data_marker_status(data::HSData)
    marker_spec = data.marker_spec
    genotype_marker_count = _data_genotype_marker_count(data)

    marker_spec === nothing && genotype_marker_count == 0 && return nothing

    marker_count = marker_spec === nothing ? 0 : length(marker_spec.marker_ids)
    aligned_count = data.genotype_marker_spec === nothing ? 0 : length(data.genotype_marker_spec.marker_ids)
    chromosome_count = marker_spec === nothing ? nothing : length(unique(marker_spec.chromosome))
    position_min = marker_spec === nothing ? nothing : minimum(marker_spec.position)
    position_max = marker_spec === nothing ? nothing : maximum(marker_spec.position)
    alignment = _data_marker_alignment(marker_spec, data.genotype_marker_spec, genotype_marker_count)

    return [
        HSDataMarkerStatusRow("marker_map_markers", string(marker_count)),
        HSDataMarkerStatusRow("genotype_marker_columns", string(genotype_marker_count)),
        HSDataMarkerStatusRow("aligned_marker_columns", string(aligned_count)),
        HSDataMarkerStatusRow("chromosomes", _optional_status_value(chromosome_count)),
        HSDataMarkerStatusRow("position_min", _optional_status_value(position_min)),
        HSDataMarkerStatusRow("position_max", _optional_status_value(position_max)),
        HSDataMarkerStatusRow("alignment", alignment),
    ]
end

function _data_genotype_marker_count(data::HSData)
    data.genotypes === nothing && return 0
    data.genotype_marker_spec === nothing || return length(data.genotype_marker_spec.marker_ids)
    return _fallback_genotype_marker_count(data.genotypes)
end

function _fallback_genotype_marker_count(genotypes::AbstractMatrix)
    return size(genotypes, 2)
end

function _fallback_genotype_marker_count(genotypes)
    names = _column_names(genotypes)
    names === nothing && return 0
    return count(name -> string(name) != "id", names)
end

function _data_marker_alignment(marker_spec, genotype_marker_spec, genotype_marker_count::Int)
    genotype_marker_spec === nothing || return "checked"
    marker_spec === nothing && genotype_marker_count > 0 && return "not_checked_no_marker_map"
    marker_spec === nothing || return "not_checked_no_genotypes"
    return "not_applicable"
end

function _optional_status_value(value)
    value === nothing && return "not_available"
    return string(value)
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
