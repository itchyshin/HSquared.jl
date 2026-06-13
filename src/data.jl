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
    HSAnnotationSpec

Validated expression-feature annotation metadata stored by [`HSData`](@ref).

This is metadata hygiene only. It does not join annotation covariates into
model matrices, fit eQTL or omics models, or run GLLVM workflows.
"""
struct HSAnnotationSpec
    key::Symbol
    annotation_features::Vector{String}
    expression_features::Vector{String}
    expression_without_annotation::Vector{String}
    annotation_without_expression::Vector{String}
    duplicate_annotation_features::Vector{String}
end

"""
    HSEnvironmentSpec

Validated environment-key metadata stored by [`HSData`](@ref).

This is metadata hygiene only. It does not add environmental model terms,
join environment covariates into design matrices, or fit multi-environment
models.
"""
struct HSEnvironmentSpec
    key::Symbol
    phenotype_environment_ids::Vector{String}
    environment_ids::Vector{String}
    phenotypes_without_environment::Vector{String}
    environment_without_phenotypes::Vector{String}
    duplicate_environment_ids::Vector{String}
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
    HSDataAnnotationStatusRow

One annotation-metadata diagnostic returned by [`data_status`](@ref).
"""
struct HSDataAnnotationStatusRow
    metric::String
    value::String
end

"""
    HSDataExpressionStatusRow

One expression-component diagnostic returned by [`data_status`](@ref).
"""
struct HSDataExpressionStatusRow
    metric::String
    value::String
end

"""
    HSDataEnvironmentStatusRow

One environment-metadata diagnostic returned by [`data_status`](@ref).
"""
struct HSDataEnvironmentStatusRow
    metric::String
    value::String
end

"""
    HSDataPedigreeStatusRow

One pedigree diagnostic returned by [`data_status`](@ref).
"""
struct HSDataPedigreeStatusRow
    metric::String
    count::Int
end

"""
    HSDataStatus

Diagnostic container returned by [`data_status`](@ref).

This mirrors the R twin's `data_status()` surface for component presence,
ID-overlap counts, pedigree status, marker-map/genotype-marker alignment
status, expression status, expression-feature annotation status, and
environment-key metadata status. It is diagnostic only and does not build
model specifications, join covariates, or construct relationship matrices.
"""
struct HSDataStatus
    components::Vector{Symbol}
    id_overlap::Vector{HSDataIDOverlapRow}
    pedigree_status::Union{Nothing,Vector{HSDataPedigreeStatusRow}}
    marker_status::Union{Nothing,Vector{HSDataMarkerStatusRow}}
    expression_status::Union{Nothing,Vector{HSDataExpressionStatusRow}}
    annotation_status::Union{Nothing,Vector{HSDataAnnotationStatusRow}}
    environment_status::Union{Nothing,Vector{HSDataEnvironmentStatusRow}}
end

"""
    HSData

In-memory container for matched phenotypes, pedigree, genotypes, expression,
marker annotation, and environmental data.

This is a conservative Phase 1 mirror of the R `hs_data()` contract. It stores
the supplied objects and records exact-ID overlap diagnostics, but it does not
construct relationship matrices, read file-backed data, or fit a model.
"""
struct HSData{TP,TPed,TG,TM,TMS,TGMS,TE,TA,TAS,TEnv,TES}
    phenotypes::TP
    pedigree::TPed
    genotypes::TG
    markers::TM
    marker_spec::TMS
    genotype_marker_spec::TGMS
    expression::TE
    expression_id::Symbol
    annotation::TA
    annotation_spec::TAS
    annotation_id::Union{Nothing,Symbol}
    environment::TEnv
    environment_spec::TES
    environment_id::Union{Nothing,Symbol}
    pedigree_id::Symbol
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
- `expression`, `annotation`, and `environment`: stored as supplied;
- `annotation_id`: optional feature key column for expression/annotation
  metadata diagnostics;
- `environment_id`: optional shared key column for phenotype/environment
  metadata diagnostics.

When a pedigree is supplied, every unique phenotype ID must appear in the
pedigree IDs. Genotype and expression mismatches are recorded in `id_map`
instead of rejected, because ungenotyped and unexpressed phenotyped individuals
are valid inputs for later phases. When both `genotypes` and `markers` are
supplied, genotype marker names must match marker-map IDs exactly after marker
names are normalized to strings. When `environment` and `environment_id` are
supplied, `HSData` records overlap between phenotype environment keys and
environment metadata keys. It does not join environment covariates into model
matrices.
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
    annotation_id = nothing,
    environment = nothing,
    environment_id = nothing,
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
        annotation_id = annotation_id,
        environment = environment,
        environment_id = environment_id,
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
    annotation_id = nothing,
    environment = nothing,
    environment_id = nothing,
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
    annotation_spec = _annotation_spec(
        annotation,
        expression;
        expression_id = expression_id,
        annotation_id = annotation_id,
    )
    environment_spec = _environment_spec(
        environment,
        phenotypes;
        environment_id = environment_id,
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
        _column_symbol(expression_id, "expression"),
        annotation,
        annotation_spec,
        annotation_spec === nothing ? nothing : annotation_spec.key,
        environment,
        environment_spec,
        environment_spec === nothing ? nothing : environment_spec.key,
        _column_symbol(pedigree_id, "pedigree"),
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

Return component, ID-overlap, marker-alignment, expression, annotation-feature,
and environment-key diagnostics for an
[`HSData`](@ref) object.

This mirrors the R twin's `data_status()` helper. It does not parse genotype
files, construct genomic relationships, join expression, annotation, or
environment covariates, build bridge payloads, or fit models.
"""
function data_status(data::HSData)
    return HSDataStatus(
        _data_components(data),
        _data_id_overlap(data.id_map),
        _data_pedigree_status(data),
        _data_marker_status(data),
        _data_expression_status(data),
        _data_annotation_status(data),
        _data_environment_status(data),
    )
end

function _pedigree_ids(::Nothing, pedigree_id)
    return Any[]
end

function _pedigree_ids(pedigree::Pedigree, pedigree_id)
    return _unique_ids(pedigree.ids, "pedigree"; allow_repeated = false)
end

function _pedigree_ids(pedigree, pedigree_id)
    return _unique_ids(_column(pedigree, pedigree_id, "pedigree"), "pedigree"; allow_repeated = true)
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

function _environment_spec(::Nothing, phenotypes; environment_id)
    environment_id === nothing ||
        throw(ArgumentError("environment_id can be supplied only when environment is supplied"))
    return nothing
end

function _annotation_spec(::Nothing, expression; expression_id, annotation_id)
    annotation_id === nothing ||
        throw(ArgumentError("annotation_id can be supplied only when annotation is supplied"))
    return nothing
end

function _annotation_spec(annotation, expression; expression_id, annotation_id)
    _column_names(annotation) !== nothing ||
        throw(ArgumentError("annotation must be table-like when supplied"))
    annotation_id === nothing && return nothing

    key = _key_column_symbol(annotation_id, "annotation")
    annotation_features = _environment_key_values(
        _column(annotation, key, "annotation"),
        "annotation",
        key,
    )
    expression_features = _expression_feature_ids(expression, expression_id)
    duplicates = _duplicate_string_ids(annotation_features)
    unique_annotation = _unique_strings(annotation_features)
    unique_expression = _unique_strings(expression_features)

    return HSAnnotationSpec(
        key,
        unique_annotation,
        unique_expression,
        _ordered_setdiff(unique_expression, unique_annotation),
        _ordered_setdiff(unique_annotation, unique_expression),
        duplicates,
    )
end

function _environment_spec(environment, phenotypes; environment_id)
    _column_names(environment) !== nothing ||
        throw(ArgumentError("environment must be table-like when supplied"))
    environment_id === nothing && return nothing

    key = _key_column_symbol(environment_id, "environment")
    phenotype_values = _environment_key_values(
        _column(phenotypes, key, "phenotypes"),
        "phenotypes",
        key,
    )
    environment_values = _environment_key_values(
        _column(environment, key, "environment"),
        "environment",
        key,
    )
    phenotype_ids = _unique_strings(phenotype_values)
    environment_ids = _unique_strings(environment_values)
    duplicates = _duplicate_string_ids(environment_values)

    return HSEnvironmentSpec(
        key,
        phenotype_ids,
        environment_ids,
        _ordered_setdiff(phenotype_ids, environment_ids),
        _ordered_setdiff(environment_ids, phenotype_ids),
        duplicates,
    )
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

function _data_pedigree_status(data::HSData)
    data.pedigree === nothing && return nothing
    ids, sire, dam = _pedigree_status_vectors(data.pedigree, data.pedigree_id)
    pedigree_ids = data.id_map.pedigree_ids
    phenotype_ids = data.id_map.phenotype_ids
    duplicate_ids = _duplicate_ids(ids)
    missing_parents = _ordered_setdiff(_unique_known_parents(sire, dam), _unique_ids(ids, "pedigree"; allow_repeated = true))
    founders = [sire[i] === nothing && dam[i] === nothing for i in eachindex(ids)]
    self_parent_rows = 0
    same_known_parent_rows = 0
    known_sire_links = 0
    known_dam_links = 0
    for i in eachindex(ids)
        row_self_parent = false
        if sire[i] !== nothing
            known_sire_links += 1
            isequal(sire[i], ids[i]) && (row_self_parent = true)
        end
        if dam[i] !== nothing
            known_dam_links += 1
            isequal(dam[i], ids[i]) && (row_self_parent = true)
        end
        row_self_parent && (self_parent_rows += 1)
        sire[i] !== nothing && dam[i] !== nothing && isequal(sire[i], dam[i]) && (same_known_parent_rows += 1)
    end

    return [
        HSDataPedigreeStatusRow("pedigree_rows", length(ids)),
        HSDataPedigreeStatusRow("pedigree_ids", length(pedigree_ids)),
        HSDataPedigreeStatusRow("phenotype_ids_with_pedigree", length(_ordered_intersect(phenotype_ids, pedigree_ids))),
        HSDataPedigreeStatusRow("pedigree_only_ids", length(_ordered_setdiff(pedigree_ids, phenotype_ids))),
        HSDataPedigreeStatusRow("founders", count(founders)),
        HSDataPedigreeStatusRow("nonfounders", length(ids) - count(founders)),
        HSDataPedigreeStatusRow("known_sire_links", known_sire_links),
        HSDataPedigreeStatusRow("known_dam_links", known_dam_links),
        HSDataPedigreeStatusRow("missing_known_parent_ids", length(missing_parents)),
        HSDataPedigreeStatusRow("duplicate_pedigree_ids", length(duplicate_ids)),
        HSDataPedigreeStatusRow("self_parent_rows", self_parent_rows),
        HSDataPedigreeStatusRow("same_known_parent_rows", same_known_parent_rows),
    ]
end

function _pedigree_status_vectors(pedigree::Pedigree, pedigree_id::Symbol)
    ids = Any[pedigree.ids...]
    sire = Vector{Union{Nothing,Any}}(undef, length(pedigree))
    dam = Vector{Union{Nothing,Any}}(undef, length(pedigree))
    for i in eachindex(ids)
        sire[i] = pedigree.sire[i] == 0 ? nothing : ids[pedigree.sire[i]]
        dam[i] = pedigree.dam[i] == 0 ? nothing : ids[pedigree.dam[i]]
    end
    return ids, sire, dam
end

function _pedigree_status_vectors(pedigree, pedigree_id::Symbol)
    id_values = Any[_column(pedigree, pedigree_id, "pedigree")...]
    sire_values, dam_values = _raw_parent_columns(pedigree, length(id_values))
    _unique_ids(id_values, "pedigree"; allow_repeated = true)
    sire = _parent_status_values(sire_values)
    dam = _parent_status_values(dam_values)
    length(sire) == length(id_values) && length(dam) == length(id_values) ||
        throw(ArgumentError("pedigree id, sire, and dam columns must have equal lengths"))
    return id_values, sire, dam
end

function _raw_parent_columns(pedigree, n::Int)
    names = _column_names(pedigree)
    names === nothing && return fill(nothing, n), fill(nothing, n)

    sire_name = _pick_optional_column(names, (:sire, :father))
    dam_name = _pick_optional_column(names, (:dam, :mother))
    if sire_name === nothing || dam_name === nothing
        if length(names) >= 3
            sire_name = names[2]
            dam_name = names[3]
        else
            return fill(nothing, n), fill(nothing, n)
        end
    end

    return Any[_column(pedigree, sire_name, "pedigree")...], Any[_column(pedigree, dam_name, "pedigree")...]
end

function _pick_optional_column(names, aliases::Tuple)
    lower_names = lowercase.(string.(names))
    for alias in aliases
        hit = findfirst(==(String(alias)), lower_names)
        hit === nothing || return names[hit]
    end
    return nothing
end

function _parent_status_values(values)
    return Union{Nothing,Any}[_is_unknown_parent(value, DEFAULT_UNKNOWN_PARENT_VALUES) ? nothing : value for value in values]
end

function _unique_known_parents(sire, dam)
    return _unique_ids(Any[parent for parent in vcat(sire, dam) if parent !== nothing], "pedigree parent"; allow_repeated = true)
end

function _duplicate_ids(ids)
    seen = Set{Any}()
    duplicates = Any[]
    duplicate_seen = Set{Any}()
    for id in ids
        if id in seen && !(id in duplicate_seen)
            push!(duplicates, id)
            push!(duplicate_seen, id)
        else
            push!(seen, id)
        end
    end
    return duplicates
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

function _data_annotation_status(data::HSData)
    data.annotation === nothing && return nothing
    annotation_rows = _row_count(data.annotation)
    row_value = annotation_rows === nothing ? "not_available" : string(annotation_rows)

    if data.annotation_spec === nothing
        return [
            HSDataAnnotationStatusRow("annotation_rows", row_value),
            HSDataAnnotationStatusRow("annotation_key", "not_checked_no_annotation_id"),
            HSDataAnnotationStatusRow("annotation_features", "not_available"),
            HSDataAnnotationStatusRow("expression_features", "not_available"),
            HSDataAnnotationStatusRow("expression_features_with_annotation", "not_available"),
            HSDataAnnotationStatusRow("annotation_only_features", "not_available"),
            HSDataAnnotationStatusRow("expression_features_without_annotation", "not_available"),
            HSDataAnnotationStatusRow("duplicate_annotation_features", "not_available"),
        ]
    end

    spec = data.annotation_spec
    return [
        HSDataAnnotationStatusRow("annotation_rows", row_value),
        HSDataAnnotationStatusRow("annotation_key", String(spec.key)),
        HSDataAnnotationStatusRow("annotation_features", string(length(spec.annotation_features))),
        HSDataAnnotationStatusRow("expression_features", string(length(spec.expression_features))),
        HSDataAnnotationStatusRow(
            "expression_features_with_annotation",
            string(length(_ordered_intersect(spec.expression_features, spec.annotation_features))),
        ),
        HSDataAnnotationStatusRow("annotation_only_features", string(length(spec.annotation_without_expression))),
        HSDataAnnotationStatusRow(
            "expression_features_without_annotation",
            string(length(spec.expression_without_annotation)),
        ),
        HSDataAnnotationStatusRow("duplicate_annotation_features", string(length(spec.duplicate_annotation_features))),
    ]
end

function _data_environment_status(data::HSData)
    data.environment === nothing && return nothing
    environment_rows = _row_count(data.environment)
    row_value = environment_rows === nothing ? "not_available" : string(environment_rows)

    if data.environment_spec === nothing
        return [
            HSDataEnvironmentStatusRow("environment_rows", row_value),
            HSDataEnvironmentStatusRow("environment_key", "not_checked_no_environment_id"),
            HSDataEnvironmentStatusRow("environment_ids", "not_available"),
            HSDataEnvironmentStatusRow("phenotype_environment_ids", "not_available"),
            HSDataEnvironmentStatusRow("phenotype_environment_ids_with_metadata", "not_available"),
            HSDataEnvironmentStatusRow("environment_only_ids", "not_available"),
            HSDataEnvironmentStatusRow("phenotype_environment_ids_without_metadata", "not_available"),
            HSDataEnvironmentStatusRow("duplicate_environment_ids", "not_available"),
        ]
    end

    spec = data.environment_spec
    return [
        HSDataEnvironmentStatusRow("environment_rows", row_value),
        HSDataEnvironmentStatusRow("environment_key", String(spec.key)),
        HSDataEnvironmentStatusRow("environment_ids", string(length(spec.environment_ids))),
        HSDataEnvironmentStatusRow("phenotype_environment_ids", string(length(spec.phenotype_environment_ids))),
        HSDataEnvironmentStatusRow(
            "phenotype_environment_ids_with_metadata",
            string(length(_ordered_intersect(spec.phenotype_environment_ids, spec.environment_ids))),
        ),
        HSDataEnvironmentStatusRow("environment_only_ids", string(length(spec.environment_without_phenotypes))),
        HSDataEnvironmentStatusRow(
            "phenotype_environment_ids_without_metadata",
            string(length(spec.phenotypes_without_environment)),
        ),
        HSDataEnvironmentStatusRow("duplicate_environment_ids", string(length(spec.duplicate_environment_ids))),
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

function _data_expression_status(data::HSData)
    data.expression === nothing && return nothing

    features = _expression_status_feature_ids(data.expression, data.expression_id)
    has_feature_name = [feature !== nothing && !isempty(feature) for feature in features]
    named_features = String[feature::String for (feature, has_name) in zip(features, has_feature_name) if has_name]
    duplicate_features = _duplicate_string_ids(named_features)

    return [
        HSDataExpressionStatusRow("expression_rows", _optional_status_value(_row_count(data.expression))),
        HSDataExpressionStatusRow("expression_ids", string(length(data.id_map.expression_ids))),
        HSDataExpressionStatusRow("expression_features", string(length(features))),
        HSDataExpressionStatusRow("named_expression_features", string(length(named_features))),
        HSDataExpressionStatusRow("unnamed_expression_features", string(count(!, has_feature_name))),
        HSDataExpressionStatusRow("duplicate_expression_features", string(length(duplicate_features))),
        HSDataExpressionStatusRow("component_type", _component_type(data.expression)),
    ]
end

function _optional_status_value(value)
    value === nothing && return "not_available"
    return string(value)
end

function _expression_status_feature_ids(::Nothing, expression_id)
    return Union{Nothing,String}[]
end

function _expression_status_feature_ids(expression::AbstractMatrix, expression_id)
    return Union{Nothing,String}[nothing for _ in 1:size(expression, 2)]
end

function _expression_status_feature_ids(expression, expression_id)
    names = _column_names(expression)
    names === nothing && return Union{Nothing,String}[]
    return Union{Nothing,String}[string(name) for name in names if !_same_column_name(name, expression_id)]
end

function _component_type(source::AbstractMatrix)
    return "matrix"
end

function _component_type(source)
    _column_names(source) === nothing && return string(typeof(source))
    return "table"
end

function _expression_feature_ids(::Nothing, expression_id)
    return String[]
end

function _expression_feature_ids(expression::AbstractMatrix, expression_id)
    throw(ArgumentError("matrix-like expression requires named feature columns when annotation_id is supplied"))
end

function _expression_feature_ids(expression, expression_id)
    names = _column_names(expression)
    names === nothing &&
        throw(ArgumentError("expression must be table-like when annotation_id is supplied"))
    feature_columns = Any[name for name in names if !_same_column_name(name, expression_id)]
    isempty(feature_columns) &&
        throw(ArgumentError("expression must contain at least one feature column when annotation_id is supplied"))
    return _string_ids(feature_columns, "expression feature columns"; allow_repeated = false)
end

function _key_column_symbol(column, role)
    name = _column_symbol(column, role)
    isempty(String(name)) &&
        throw(ArgumentError("$(role) key column must be non-empty"))
    return name
end

function _environment_key_values(values, role::AbstractString, key::Symbol)
    out = String[]
    for value in values
        (ismissing(value) || value === nothing) &&
            throw(ArgumentError("$(role) column :$(key) cannot contain missing or empty values"))
        text = string(value)
        isempty(text) &&
            throw(ArgumentError("$(role) column :$(key) cannot contain missing or empty values"))
        push!(out, text)
    end
    return out
end

function _unique_strings(values)
    out = String[]
    seen = Set{String}()
    for value in values
        if !(value in seen)
            push!(out, value)
            push!(seen, value)
        end
    end
    return out
end

function _duplicate_string_ids(values)
    seen = Set{String}()
    duplicates = String[]
    duplicate_seen = Set{String}()
    for value in values
        if value in seen && !(value in duplicate_seen)
            push!(duplicates, value)
            push!(duplicate_seen, value)
        else
            push!(seen, value)
        end
    end
    return duplicates
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

function _ordered_intersect(left, right)
    right_set = Set(right)
    return Any[id for id in left if id in right_set]
end

function _row_count(source)
    try
        return size(source, 1)
    catch
        return nothing
    end
end

function _row_count(source::NamedTuple)
    names = propertynames(source)
    isempty(names) && return 0
    first_column = getproperty(source, names[1])
    try
        return length(first_column)
    catch
        return nothing
    end
end

function _is_missing_id(id)
    return ismissing(id) || id === nothing || (id isa AbstractString && isempty(id))
end
