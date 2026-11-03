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
include(joinpath(source_root, "sim", "arc1", "artifact_container.jl"))
include(joinpath(source_root, "sim", "arc1", "execute_attempt.jl"))

function arc1_inspector_load_artifact(path)
    magic = open(path, "r") do io
        read(io, length(ARC1_CONTAINER_MAGIC))
    end
    return magic == ARC1_CONTAINER_MAGIC ? arc1_read_artifact_container(path) :
        open(deserialize, path)
end

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

function arc1_inspector_v4_design_context(payload, engine)
    payload !== nothing && hasproperty(payload, :design) &&
        hasproperty(payload, :data) || return nothing
    isdefined(engine, :_arc1_profile_context) || return nothing
    design = payload.design
    hasproperty(design, :y) && hasproperty(design, :X) && hasproperty(design, :Z) &&
        hasproperty(design, :pedigree) || return nothing
    try
        Ainv = getfield(engine, :pedigree_inverse)(design.pedigree)
        return getfield(engine, :_arc1_profile_context)(design.y, design.X,
            design.Z, Ainv)
    catch
        return nothing
    end
end

function arc1_inspector_v4_design_inputs_retained(payload)
    payload !== nothing && hasproperty(payload, :data) && hasproperty(payload, :design) ||
        return false
    design = payload.design
    return all(name -> hasproperty(design, name), (:y, :X, :Z, :pedigree))
end

function arc1_inspector_v4_certificate_validation(row, context, payload, engine)
    failed(design) = (structurally_valid=false, valid=false, design)
    hasproperty(row, :target) && row.target === :residual_variance &&
        hasproperty(row, :certificate) || return failed(:failed)
    certificate = row.certificate
    required = (:status, :reason, :certified, :precision, :rounding,
        :determinant, :residual_df, :design_identity, :convention, :E,
        :upper_bound, :threshold_lower, :gap_lower, :point_loglik, :cutoff,
        :separation_tolerance, :rounding_contract, :boundary_rounding_contract,
        :determinant_identity)
    structurally_complete = all(name -> hasproperty(certificate, name), required)
    structurally_complete || return failed(context === nothing ? :unavailable : :failed)

    expected_rounding_contract = (rational_numerator=:down,
        rational_denominator=:up, rational_division=:down, determinant_log=:down,
        boundary_variance_log=:down, residual_df_product_and_sum=:down,
        upper_bound_negation_and_product=:up, threshold_subtraction=:down,
        gap_subtraction=:down)
    expected_boundary_contract = (reference_threshold=:down,
        log_determinant_lower=:down, log_boundary_numerator=:up,
        residual_df_division=:up, exponential=:up,
        float_conversion=:nearest_then_nextfloat)
    structural_values_valid = certificate.status === :excluded_tail &&
        certificate.reason === nothing && certificate.certified === true &&
        certificate.precision === 256 && certificate.rounding === :directed_mpfr &&
        certificate.convention === :omit_2pi &&
        certificate.determinant_identity ===
            :detD_detHinvDH_equals_detHtH_detCtDC &&
        certificate.determinant isa Rational{BigInt} && certificate.determinant > 0 &&
        certificate.residual_df isa Integer && !(certificate.residual_df isa Bool) &&
        certificate.residual_df > 0 && certificate.E isa Float64 &&
        isfinite(certificate.E) && certificate.E > 0 &&
        certificate.upper_bound isa BigFloat && isfinite(certificate.upper_bound) &&
        certificate.threshold_lower isa BigFloat && isfinite(certificate.threshold_lower) &&
        certificate.gap_lower isa BigFloat && isfinite(certificate.gap_lower) &&
        certificate.gap_lower > BigFloat(1e-8) &&
        certificate.point_loglik isa Float64 && isfinite(certificate.point_loglik) &&
        certificate.cutoff isa Float64 && isfinite(certificate.cutoff) &&
        certificate.cutoff > 0 && certificate.separation_tolerance === 1e-8 &&
        isequal(certificate.rounding_contract, expected_rounding_contract) &&
        isequal(certificate.boundary_rounding_contract, expected_boundary_contract) &&
        certificate.design_identity isa AbstractString &&
        occursin(r"^[0-9a-f]{64}$", certificate.design_identity)
    structural_values_valid || return failed(context === nothing ? :unavailable : :failed)

    # A complete certificate without retained design inputs can be structurally
    # checked after interruption, but cannot be called fully validated.
    context === nothing && return (structurally_valid=true, valid=false,
        design=:unavailable)
    hasproperty(context, :residual_df) && hasproperty(context, :profile_v4_design_data) ||
        return failed(:failed)
    design_data = context.profile_v4_design_data
    design_matches = design_data.status === :ok &&
        design_data.determinant isa Rational{BigInt} && design_data.determinant > 0 &&
        certificate.residual_df == context.residual_df &&
        certificate.determinant == design_data.determinant &&
        certificate.design_identity == design_data.design_identity
    design_matches || return failed(:failed)
    hasproperty(context, :transformed_design) && payload !== nothing &&
        hasproperty(payload, :profile) ||
        return (structurally_valid=true, valid=false, design=:matched)
    profile = payload.profile
    hasproperty(profile, :point_fit) && profile.point_fit !== nothing &&
        hasproperty(profile.point_fit, :loglik) && hasproperty(profile, :cutoff) ||
        return (structurally_valid=true, valid=false, design=:matched)
    isdefined(engine, :_arc1_profile_v4_tail_certificate) ||
        return (structurally_valid=true, valid=false, design=:matched)
    point_loglik, cutoff = profile.point_fit.loglik, profile.cutoff
    point_loglik isa Float64 && isfinite(point_loglik) &&
        cutoff isa Float64 && isfinite(cutoff) && cutoff > 0 ||
        return (structurally_valid=true, valid=false, design=:matched)
    recomputed = try
        getfield(engine, :_arc1_profile_v4_tail_certificate)(
            context.transformed_design, certificate.E, point_loglik;
            cutoff, normalization_convention=:omit_2pi,
            design_data=context.profile_v4_design_data)
    catch
        return (structurally_valid=true, valid=false, design=:matched)
    end
    return (structurally_valid=true, valid=isequal(certificate, recomputed),
        design=:matched)
end

rows = Any[]
for artifact_path in artifact_paths
    path = realpath(artifact_path)
    artifact = arc1_inspector_load_artifact(path)
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
    receipt_projection = arc1_inspector_receipt_projection(summary)
    embedded_receipt_summary = receipt_projection.receipt_summary
    embedded_receipt_json = embedded_receipt_summary === nothing ? nothing :
        arc1_json(embedded_receipt_summary)
    summary_matches = summary === nothing ? retained_result === nothing :
        receipt_projection.qualifiable && retained_result !== nothing &&
            retained_receipt_json == embedded_receipt_json
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
    raw_result_projection_difference = retained_result === nothing ? nothing :
        arc1_raw_result_projection_difference(payload, retained_result, metadata)
    raw_result_matches = retained_result === nothing ? summary === nothing :
        raw_result_projection_difference === nothing
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
    retained_v3_evidence_summary = arc1_profile_evidence_summary(retained_v3_evidence_dict)
    include_full_v3_evidence = get(ENV, "ARC1_INSPECT_INCLUDE_V3_EVIDENCE", "false") == "true"
    v3_actual = retained_v3_evidence_dict === nothing ? nothing :
        get(retained_v3_evidence_dict, :actual_method_version, nothing)
    v3_source = retained_v3_evidence_dict === nothing ? nothing :
        get(retained_v3_evidence_dict, :source_identity, nothing)
    v3_records = retained_v3_evidence_dict === nothing ? Any[] :
        get(retained_v3_evidence_dict, :arc1_profile_v3_evaluations, Any[])
    v4_records = retained_v3_evidence_dict === nothing ? Any[] :
        get(retained_v3_evidence_dict, :arc1_profile_v4_evaluations, Any[])
    v4_tail_certificates_present = retained_v3_evidence_dict !== nothing &&
        haskey(retained_v3_evidence_dict, :v4_tail_certificates)
    v4_tail_certificates = v4_tail_certificates_present ?
        retained_v3_evidence_dict[:v4_tail_certificates] : nothing
    v4_tail_certificates_shape = !v4_tail_certificates_present ? "missing" :
        v4_tail_certificates isa AbstractVector ? "vector" : "malformed"
    loaded_engine = only([mod for (_, mod) in Base.loaded_modules
                          if nameof(mod) === :HSquared &&
                             getfield(mod, :_ARC1_SOURCE_IDENTITY) isa AbstractString])
    v4_design_context = requested_profile_version == "arc1_profile_v4" ?
        arc1_inspector_v4_design_context(payload, loaded_engine) : nothing
    profile_evidence_required = requested_profile_version in
        ("arc1_profile_v3", "arc1_profile_v4")
    v4_evidence_aliases_match = requested_profile_version != "arc1_profile_v4" ||
        (retained_v3_evidence_dict !== nothing &&
         haskey(retained_v3_evidence_dict, :arc1_profile_v3_evaluations) &&
         haskey(retained_v3_evidence_dict, :arc1_profile_v4_evaluations) &&
         v3_records isa AbstractVector && v4_records isa AbstractVector &&
         v3_records === v4_records)
    v4_certificate_checks = requested_profile_version == "arc1_profile_v4" &&
        v4_tail_certificates isa AbstractVector ?
        [arc1_inspector_v4_certificate_validation(row, v4_design_context,
            payload, loaded_engine) for row in v4_tail_certificates] : Any[]
    v4_certificate_present = requested_profile_version == "arc1_profile_v4" &&
        v4_tail_certificates isa AbstractVector && !isempty(v4_tail_certificates)
    interrupted_design_absent = v4_certificate_present &&
        !arc1_inspector_v4_design_inputs_retained(payload) &&
        v4_design_context === nothing && get(metadata, :status, nothing) == "interrupted"
    interrupted_without_design = interrupted_design_absent &&
        all(check -> check.structurally_valid, v4_certificate_checks)
    v4_certificate_validation_status = requested_profile_version != "arc1_profile_v4" ?
        "not_applicable" : v4_tail_certificates_shape != "vector" ? "invalid" :
        !v4_certificate_present ? "no_certificate" :
        all(check -> check.valid, v4_certificate_checks) ? "validated" :
        interrupted_without_design ? "design_correspondence_unavailable_interrupted" : "invalid"
    v4_certificate_design_correspondence = v4_tail_certificates_shape != "vector" ? "failed" :
        !v4_certificate_present ? "not_applicable" :
        all(check -> check.design === :matched, v4_certificate_checks) ? "matched" :
        interrupted_design_absent ? "unavailable_interrupted" : "failed"
    v4_tail_certificate_evidence_valid = requested_profile_version != "arc1_profile_v4" ||
        v4_tail_certificates_shape == "vector" &&
            (!v4_certificate_present || v4_certificate_validation_status == "validated")
    loaded_source_identity = string(getfield(loaded_engine, :_ARC1_SOURCE_IDENTITY))
    retained_result_source_identity = retained_result !== nothing &&
        hasproperty(retained_result, :source_identity) ? retained_result.source_identity : nothing
    retained_result_reference_source_identity = retained_result !== nothing &&
        hasproperty(retained_result, :reference_source_identity) ?
            retained_result.reference_source_identity : nothing
    retained_result_identity_matches = if !profile_evidence_required
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
        retained_profile_version == requested_profile_version &&
            retained_result_identity == loaded_source_identity &&
            retained_reference_identity == loaded_source_identity
    end
    sink_identity_matches = if !profile_evidence_required
        retained_v3_evidence === nothing
    elseif retained_v3_evidence_dict === nothing ||
           get(retained_v3_evidence_dict, :requested_method_version, nothing) != requested_profile_version
        false
    elseif v3_actual === nothing
        v3_source === nothing && isempty(v3_records) && isempty(v4_records) &&
            metadata_profile_version === nothing &&
            (requested_profile_version != "arc1_profile_v4" ||
             (!haskey(retained_v3_evidence_dict, :arc1_profile_v3_evaluations) &&
              !haskey(retained_v3_evidence_dict, :arc1_profile_v4_evaluations)))
    else
        v3_actual == requested_profile_version && v3_source == loaded_source_identity &&
            metadata_profile_version == requested_profile_version &&
            v4_evidence_aliases_match && v4_tail_certificate_evidence_valid &&
            (!haskey(retained_v3_evidence_dict, :returned_method_version) ||
             retained_v3_evidence_dict[:returned_method_version] == requested_profile_version)
    end
    v3_evidence_identity_matches = sink_identity_matches &&
        (!profile_evidence_required ||
         (loaded_engine_source_identity_matches && retained_result_identity_matches))
    v3_evidence_partial_present = retained_v3_evidence isa AbstractDict &&
        !isempty(requested_profile_version == "arc1_profile_v4" ? v4_records : v3_records)
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
    push!(rows, (; path, metadata,
        receipt_summary_status=receipt_projection.status,
        receipt_summary=embedded_receipt_summary,
        receipt_summary_diagnostic=receipt_projection.diagnostic_summary,
        retained_result_present=retained_result !== nothing,
        retained_result_status=retained_status, retained_result_success=retained_success,
        retained_data_present=retained_data !== nothing,
        profile_method_identity_matches,
        retained_v3_evidence_present=retained_v3_evidence !== nothing,
        # Keep the artifact transport compact. The native container reader
        # validates every event record and its alias/reference structure; the
        # full object is included only for legacy attempt receipts that still
        # duplicate the history in JSON.
        v3_evidence_records=retained_v3_evidence_summary,
        v3_evidence_records_full=include_full_v3_evidence ? retained_v3_evidence_dict : nothing,
        v3_evidence_identity_matches,
        v4_evidence_aliases_match,
        v4_tail_certificate_evidence_valid,
        v4_tail_certificates_shape,
        v4_tail_certificate_validation_status=v4_certificate_validation_status,
        v4_tail_certificate_design_correspondence=v4_certificate_design_correspondence,
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
