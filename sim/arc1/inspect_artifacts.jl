using Pkg
using Serialization
using SHA
using UUIDs

const ARC1_HSQUARED_UUID = UUID("a0667dea-0f38-44e8-9150-4fda00624eac")

length(ARGS) == 1 || error("usage: inspect_artifacts.jl request-path")
artifact_paths = readlines(ARGS[1])
isempty(artifact_paths) && error("artifact request is empty")
source_root = realpath(dirname(dirname(dirname(@__FILE__))))
Pkg.activate(source_root; io=devnull)
Base.require(Base.PkgId(ARC1_HSQUARED_UUID, "HSquared"))
include(joinpath(source_root, "sim", "arc1", "engine_io.jl"))
include(joinpath(source_root, "sim", "arc1", "execute_attempt.jl"))

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
        arc1_json(arc1_json_receipt(retained_result))
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
    push!(rows, (; path, metadata, receipt_summary=summary,
        retained_result_present=retained_result !== nothing,
        retained_result_status=retained_status, retained_result_success=retained_success,
        retained_data_present=retained_data !== nothing,
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
