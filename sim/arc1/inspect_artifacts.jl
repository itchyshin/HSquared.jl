using Pkg
using Serialization
using SHA
using UUIDs

length(ARGS) == 1 || error("usage: inspect_artifacts.jl request-path")
artifact_paths = readlines(ARGS[1])
isempty(artifact_paths) && error("artifact request is empty")
source_root = realpath(dirname(dirname(dirname(@__FILE__))))
Pkg.activate(source_root; io=devnull)
include(joinpath(source_root, "sim", "arc1", "execution_identity.jl"))
Base.require(Base.PkgId(ARC1_HSQUARED_UUID, "HSquared"))
include(joinpath(source_root, "sim", "arc1", "engine_io.jl"))
include(joinpath(source_root, "sim", "arc1", "execute_attempt.jl"))

function arc1_inspector_loaded_engine_identity_matches(metadata, source_root)
    try
        runtime = metadata.execution_identity
        module_object = only([mod for (_, mod) in Base.loaded_modules
                              if nameof(mod) === :HSquared &&
                                 getfield(mod, :_ARC1_SOURCE_IDENTITY) isa AbstractString])
        module_source_identity = string(getfield(module_object, :_ARC1_SOURCE_IDENTITY))
        module_path = realpath(pathof(module_object))
        package_id = only([id for (id, mod) in Base.loaded_modules if mod === module_object])
        source_pins = Dict{String,String}(String(k) => String(v)
            for (k, v) in pairs(runtime.source_sha256_at_load))
        environment_pins = Dict{String,String}(String(k) => String(v)
            for (k, v) in pairs(runtime.environment_sha256))
        loaded_source = _arc1_snapshot(source_root, source_pins)
        loaded_environment = _arc1_environment_snapshot(source_root)
        runtime.engine_package_uuid == string(package_id.uuid) == string(ARC1_HSQUARED_UUID) &&
            runtime.engine_module_path == module_path == realpath(joinpath(source_root, "src", "HSquared.jl")) &&
            "HSquared" in runtime.loaded_module_names &&
            runtime.loaded_engine_source_sha256 == source_pins ==
                runtime.source_sha256_after_load == loaded_source &&
            environment_pins == loaded_environment &&
            runtime.active_project == realpath(joinpath(source_root, "Project.toml")) &&
            runtime.dependency_environment_verified === true &&
            hasproperty(metadata, :loaded_arc1_source_identity) &&
            metadata.loaded_arc1_source_identity == module_source_identity
    catch
        false
    end
end

rows = Any[]
for artifact_path in artifact_paths
    path = realpath(artifact_path)
    artifact = open(deserialize, path)
    hasproperty(artifact, :metadata) || error("artifact lacks retained metadata: $path")
    metadata = artifact.metadata
    hasproperty(metadata, :outer) || error("artifact metadata lacks outer index: $path")
    hasproperty(metadata, :seed_string) || error("artifact metadata lacks exact seed: $path")
    hasproperty(metadata, :cell) || error("artifact metadata lacks cell identity: $path")
    hasproperty(metadata, :execution_identity) || error("artifact metadata lacks execution identity field: $path")
    summary = hasproperty(artifact, :receipt_summary) ? artifact.receipt_summary : nothing
    hasproperty(metadata, :driver_protocol_identity) ||
        error("artifact metadata lacks full admitted driver/protocol identity: $path")
    # The executor flattens `artifact_payload` into the JLS top level when it
    # adds metadata and the receipt summary. Accept the nested shape only for
    # older local fixtures; production artifacts are inspected at top level.
    payload = hasproperty(artifact, :artifact_payload) ? artifact.artifact_payload : artifact
    retained_result = payload !== nothing && hasproperty(payload, :result) ? payload.result : nothing
    retained_data = payload !== nothing && hasproperty(payload, :data) ? payload.data : nothing
    retained_design = payload !== nothing && hasproperty(payload, :design) ? payload.design : nothing
    retained_receipt_json = retained_result === nothing ? nothing :
        arc1_json(merge(arc1_json_receipt(retained_result),
            (; requested_profile_method_version=hasproperty(metadata, :requested_profile_method_version) ?
                metadata.requested_profile_method_version : nothing)))
    embedded_receipt_json = summary === nothing ? nothing : arc1_json(summary)
    summary_matches = summary === nothing ? retained_result === nothing :
        retained_result !== nothing && retained_receipt_json == embedded_receipt_json
    recomputed_semantic_identity = retained_data === nothing || retained_design === nothing ? nothing :
        arc1_semantic_data_identity(retained_data, retained_design)
    semantic_identity_matches = recomputed_semantic_identity === nothing ?
        !hasproperty(metadata, :semantic_data_identity_sha256) &&
        !hasproperty(metadata, :data_identity_method) :
        hasproperty(metadata, :semantic_data_identity_sha256) &&
        hasproperty(metadata, :data_identity_method) &&
        metadata.data_identity_method == ARC1_DATA_IDENTITY_METHOD &&
        recomputed_semantic_identity == metadata.semantic_data_identity_sha256
    data_seed_matches = retained_data === nothing ? nothing :
        hasproperty(retained_data, :seed) && string(retained_data.seed) == metadata.seed_string
    raw_result_matches = retained_result === nothing ? summary === nothing :
        arc1_raw_result_matches_derived_receipt(payload, retained_result, metadata)
    raw_result_projection_difference = retained_result === nothing ? nothing :
        arc1_raw_result_projection_difference(payload, retained_result, metadata)
    reference_scale_matches = retained_result === nothing ? true :
        arc1_reference_scale_matches_retained_y(payload, retained_result)
    retained_status = retained_result !== nothing && hasproperty(retained_result, :status) ?
        string(retained_result.status) : hasproperty(metadata, :status) ? string(metadata.status) : nothing
    retained_success = retained_result !== nothing && hasproperty(retained_result, :success) ?
        Bool(retained_result.success) : hasproperty(metadata, :status) ? false : nothing
    requested_profile_version = hasproperty(metadata, :requested_profile_method_version) ?
        metadata.requested_profile_method_version : nothing
    metadata_profile_version = hasproperty(metadata, :profile_method_version) ?
        metadata.profile_method_version : nothing
    retained_v3_evidence = payload !== nothing && hasproperty(payload, :v3_profile_evidence) ?
        payload.v3_profile_evidence : nothing
    loaded_engine_source_identity_matches = arc1_inspector_loaded_engine_identity_matches(metadata, source_root)
    retained_v3_evidence_dict = retained_v3_evidence isa AbstractDict ? retained_v3_evidence : nothing
    v3_actual = retained_v3_evidence_dict === nothing ? nothing :
        get(retained_v3_evidence_dict, :actual_method_version, nothing)
    v3_source = retained_v3_evidence_dict === nothing ? nothing :
        get(retained_v3_evidence_dict, :source_identity, nothing)
    v3_records = retained_v3_evidence_dict === nothing ? Any[] :
        get(retained_v3_evidence_dict, :arc1_profile_v3_evaluations, Any[])
    loaded_engine = only([mod for (_, mod) in Base.loaded_modules
                          if nameof(mod) === :HSquared &&
                             getfield(mod, :_ARC1_SOURCE_IDENTITY) isa AbstractString])
    loaded_source_identity = string(getfield(loaded_engine, :_ARC1_SOURCE_IDENTITY))
    retained_result_source_identity = retained_result !== nothing &&
        hasproperty(retained_result, :source_identity) ? retained_result.source_identity : nothing
    retained_result_reference_source_identity = retained_result !== nothing &&
        hasproperty(retained_result, :reference_source_identity) ?
            retained_result.reference_source_identity : nothing
    retained_result_identity_matches = if requested_profile_version != "arc1_profile_v3"
        true
    elseif retained_result === nothing
        get(metadata, :status, nothing) in ("error", "interrupted")
    else
        retained_profile_version = hasproperty(retained_result, :profile_method_version) ?
            string(retained_result.profile_method_version) : nothing
        retained_result_identity = hasproperty(retained_result, :source_identity) ?
            retained_result.source_identity : nothing
        retained_reference_identity = hasproperty(retained_result, :reference_source_identity) ?
            retained_result.reference_source_identity : nothing
        retained_profile_version == "arc1_profile_v3" &&
            retained_result_identity == loaded_source_identity &&
            retained_reference_identity == loaded_source_identity
    end
    sink_identity_matches = if requested_profile_version != "arc1_profile_v3"
        retained_v3_evidence === nothing
    elseif retained_v3_evidence_dict === nothing ||
           get(retained_v3_evidence_dict, :requested_method_version, nothing) != requested_profile_version
        false
    elseif v3_actual === nothing
        v3_source === nothing && isempty(v3_records) && metadata_profile_version === nothing
    else
        v3_actual == "arc1_profile_v3" && v3_source == loaded_source_identity &&
            metadata_profile_version == "arc1_profile_v3" &&
            (!haskey(retained_v3_evidence_dict, :returned_method_version) ||
             retained_v3_evidence_dict[:returned_method_version] == "arc1_profile_v3")
    end
    v3_evidence_identity_matches = sink_identity_matches &&
        (requested_profile_version != "arc1_profile_v3" ||
         (loaded_engine_source_identity_matches && retained_result_identity_matches))
    v3_evidence_partial_present = retained_v3_evidence isa AbstractDict &&
        !isempty(get(retained_v3_evidence, :arc1_profile_v3_evaluations, Any[]))
    retained_profile_version = retained_result !== nothing && hasproperty(retained_result, :profile_method_version) ?
        string(retained_result.profile_method_version) : nothing
    profile_method_identity_matches = requested_profile_version === nothing ?
        metadata_profile_version === nothing && retained_profile_version === nothing :
        retained_profile_version !== nothing ?
            metadata_profile_version == requested_profile_version == retained_profile_version &&
                get(metadata, :profile_method_version_mismatch, false) !== true :
            get(metadata, :profile_method_version_mismatch, false) !== true &&
                (metadata_profile_version == requested_profile_version ||
                 (metadata_profile_version === nothing &&
                  get(metadata, :status, nothing) in ("error", "interrupted")))
    push!(rows, (; path, metadata, receipt_summary=summary,
        retained_result_present=retained_result !== nothing,
        retained_result_status=retained_status, retained_result_success=retained_success,
        retained_data_present=retained_data !== nothing,
        profile_method_identity_matches,
        retained_v3_evidence_present=retained_v3_evidence !== nothing,
        # Keep the actual retained sink available to the independent checker.
        # This is deliberately projected from JLS bytes, not copied from the
        # stored receipt summary, so native enum/tuple/dict leaves remain
        # auditable at the artifact boundary.
        v3_evidence_records=retained_v3_evidence_dict,
        v3_evidence_identity_matches,
        retained_result_identity_matches,
        retained_result_source_identity,
        retained_result_reference_source_identity,
        loaded_engine_source_identity_matches,
        v3_evidence_partial_present,
        data_seed_matches_metadata=data_seed_matches,
        raw_result_matches_derived_receipt=raw_result_matches,
        raw_result_projection_difference,
        reference_scale_matches_retained_y=reference_scale_matches,
        receipt_summary_matches_retained_result=summary_matches,
        retained_result_summary_sha256=retained_receipt_json === nothing ? nothing :
            bytes2hex(sha256(codeunits(retained_receipt_json))),
        embedded_receipt_summary_sha256=embedded_receipt_json === nothing ? nothing :
            bytes2hex(sha256(codeunits(embedded_receipt_json))),
        data_identity_sha256=hasproperty(metadata, :data_identity_sha256) ?
            metadata.data_identity_sha256 : nothing,
        data_identity_method=hasproperty(metadata, :data_identity_method) ?
            metadata.data_identity_method : nothing,
        semantic_data_identity_sha256=hasproperty(metadata, :semantic_data_identity_sha256) ?
            metadata.semantic_data_identity_sha256 : nothing,
        recomputed_semantic_data_identity_sha256=recomputed_semantic_identity,
        semantic_data_identity_matches_recomputed=semantic_identity_matches))
end
println(arc1_json(rows))
