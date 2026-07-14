#!/usr/bin/env julia

# Prospective recovery-v3 D2/D3/D4 confirmation boundary.
#
# This is deliberately NOT a general adaptive validator and performs NO fit.
# While the R-owned downstream contract remains under audit, the only admitted
# operation mirrors one frozen, unmistakably synthetic fixture.  The fixture
# authenticates the committed cell-table bytes plus concrete predecessor and
# pilot-decision lock primaries/sidecars, then derives one exact manifest.  It
# cannot establish campaign validity, consume a seed, or create replay evidence.

using SHA

const MIRROR_SCHEMA = "v07-genomic-recovery-v3-canonical-synthetic-mirror-2"
const BINDING_SCHEMA = "v07-genomic-recovery-v3-canonical-synthetic-bindings-2"
const FIXTURE_CONTRACT = "canonical_all_eligible_required_n_200"
const CANONICAL_CELL_TABLE_SHA256 =
    "9a41a7dee379f273bccdbb0bd03523c08566662bfdab401ac99be3f904c4a6bd"
const SEED_BASE = 2_028_000_000
const RIDGE = 0.01
const ALLOWED_STAGES = ("d2", "d3", "d4")
const COMPUTE_POLICY = "totoro_or_drac_only"
const SYNTHETIC_STATUS = "canonical_synthetic_schema_only_no_fit"
const RELATIONSHIP_SOURCE = "markers"
const RELATIONSHIP_METHOD = "vanraden1"
const ALLELE_FREQUENCY_SOURCE = "sample"
const RELATIONSHIP_SCALE = "K_lambda"
const D1_RECEIPT_SHA = repeat("d", 64)
const D1_SUMMARY_SHA = repeat("e", 64)
const D2_RECEIPT_SHA = repeat("f", 64)
const D2_SUMMARY_SHA = repeat("1", 64)
const D1_SYNTHETIC_ROOT = "/synthetic/v07-genomic-recovery-v3/d1"
const D2_SYNTHETIC_ROOT = "/synthetic/v07-genomic-recovery-v3/d2"

const CELL_COLUMNS = split(
    "cell_id cell_index n m marker_ratio marker_ratio_code truth_sigma_g2 " *
    "truth_sigma_e2 truth_ratio ridge",
)
const MANIFEST_COLUMNS = split(
    "stage cell_id cell_index seed_offset seed n m marker_ratio " *
    "marker_ratio_code truth_sigma_g2 truth_sigma_e2 truth_ratio ridge",
)
const PREDECESSOR_COLUMNS = split(
    "stage source_stage source_root adjudication_receipt_sha256 summary_sha256",
)
const DECISION_COLUMNS = split(
    "stage source_stage cell_id eligible required_n source_summary_sha256",
)
const BINDING_KEYS = split(
    "schema_version stage fixture_contract synthetic_only numerics_executable " *
    "compute_policy relationship_source relationship_method " *
    "allele_frequency_source relationship_scale ridge cell_table_sha256 " *
    "source_manifest_sha256 predecessor_lock_sha256 pilot_decision_lock_sha256",
)
const MIRROR_COLUMNS = split(
    "schema_version stage fixture_contract manifest_row_index cell_id cell_index " *
    "seed_offset seed n m marker_ratio marker_ratio_code truth_sigma_g2 " *
    "truth_sigma_e2 truth_ratio ridge relationship_source relationship_method " *
    "allele_frequency_source relationship_scale cell_table_sha256 " *
    "source_manifest_sha256 source_manifest_row_sha256 predecessor_lock_sha256 " *
    "pilot_decision_lock_sha256 replay_status fit_executed evidence_eligible",
)

# Frozen fixture cell membership and order.  Numeric/statistical fields are
# always taken from the authenticated canonical cell-table primary, never
# independently regenerated.
const D1_DECISION_IDS = [
    "n0120_m0060_q0500_r050",
    "n0120_m0400_q3333_r050",
    "n0120_m0600_q5000_r050",
    "n0300_m0150_q0500_r050",
    "n0300_m1000_q3333_r050",
    "n0300_m1500_q5000_r050",
    "n0600_m0300_q0500_r050",
    "n0600_m2000_q3333_r050",
    "n0600_m3000_q5000_r050",
    "n1200_m0600_q0500_r050",
    "n1200_m4000_q3333_r050",
    "n1200_m6000_q5000_r050",
]
const D2_DECISION_IDS = [
    "n0120_m0060_q0500_r020",
    "n0120_m0060_q0500_r080",
    "n0120_m0400_q3333_r020",
    "n0120_m0400_q3333_r080",
    "n0120_m0600_q5000_r020",
    "n0120_m0600_q5000_r080",
    "n0300_m0150_q0500_r020",
    "n0300_m0150_q0500_r080",
    "n0300_m1000_q3333_r020",
    "n0300_m1000_q3333_r080",
]
const FIXTURE_MANIFEST_IDS = Dict(
    "d2" => copy(D2_DECISION_IDS),
    "d3" => [
        "n0120_m0060_q0500_r020",
        "n0120_m0060_q0500_r050",
        "n0120_m0060_q0500_r080",
        "n0120_m0400_q3333_r020",
        "n0120_m0400_q3333_r050",
        "n0120_m0400_q3333_r080",
        "n0120_m0600_q5000_r020",
        "n0120_m0600_q5000_r050",
        "n0120_m0600_q5000_r080",
    ],
    "d4" => [
        "n0120_m0600_q5000_r020",
        "n0120_m0600_q5000_r050",
        "n0120_m0600_q5000_r080",
        "n0300_m0150_q0500_r020",
        "n0300_m0150_q0500_r050",
        "n0300_m0150_q0500_r080",
        "n0300_m1000_q3333_r020",
        "n0300_m1000_q3333_r050",
        "n0300_m1000_q3333_r080",
    ],
)

struct TSV
    columns::Vector{String}
    rows::Vector{Vector{String}}
    row_lines::Vector{String}
end

_sha256(path) = bytes2hex(sha256(read(path)))
_sha256_text(text) = bytes2hex(sha256(codeunits(text)))
_hex64(x) = length(x) == 64 && all(c -> isdigit(c) || c in 'a':'f', x)

function _must_fail(f, label)
    failed = false
    try
        f()
    catch
        failed = true
    end
    failed || error("negative control did not fail: $label")
    nothing
end

function _option(args, key; default=nothing)
    prefix = "--$key="
    hits = filter(x -> startswith(x, prefix), args)
    length(hits) <= 1 || error("--$key occurs more than once")
    isempty(hits) ? default : split(only(hits), "="; limit=2)[2]
end

function _required(args, key)
    value = _option(args, key)
    value === nothing && error("--$key is required")
    String(value)
end

function _reject_unknown_options(args)
    keys = (
        "--mode=",
        "--stage=",
        "--cell-table=",
        "--manifest=",
        "--predecessor-lock=",
        "--pilot-decision-lock=",
        "--bindings=",
        "--output=",
        "--cell-table-source=",
    )
    for arg in args
        any(startswith(arg, key) for key in keys) || error("unknown argument: $arg")
    end
    nothing
end

function _canonical_plain_file(path, label)
    isabspath(path) && normpath(path) == path || error("$label must be absolute and normalized")
    isfile(path) && !islink(path) && realpath(path) == path ||
        error("$label must be a canonical plain file")
    filesize(path) > 0 || error("$label must be nonempty")
    path
end

function _canonical_plain_dir(path, label)
    isabspath(path) && normpath(path) == path || error("$label must be absolute and normalized")
    isdir(path) && !islink(path) && realpath(path) == path ||
        error("$label must be a canonical plain directory")
    path
end

function _verify_pair(path, label)
    path = _canonical_plain_file(path, label)
    sidecar = _canonical_plain_file(path * ".sha256", "$label sidecar")
    digest = _sha256(path)
    read(sidecar, String) == "$digest  $(basename(path))\n" ||
        error("$label SHA-256 sidecar mismatch")
    digest
end

_verify_self() = _verify_pair(abspath(@__FILE__), "confirmation mirror tool")

function _read_tsv(path, columns, label)
    bytes = read(path)
    !isempty(bytes) && bytes[end] == 0x0a || error("$label lacks terminal LF")
    0x0d in bytes && error("$label contains CR bytes")
    lines = split(chop(String(bytes); tail=1), '\n'; keepempty=true)
    all(!isempty, lines) || error("$label contains a blank row")
    header = String.(split(lines[1], '\t'; keepempty=true))
    header == columns || error("$label schema or column order drift")
    row_lines = String.(lines[2:end])
    rows = [String.(split(line, '\t'; keepempty=true)) for line in row_lines]
    all(row -> length(row) == length(columns), rows) || error("malformed $label row")
    TSV(header, rows, row_lines)
end

_rowdict(table, row) = Dict(table.columns[i] => row[i] for i in eachindex(table.columns))

function _parse_int(x, label)
    occursin(r"^[0-9]+$", x) || error("$label must be a nonnegative integer")
    parse(Int, x)
end

function _parse_float(x, label)
    value = tryparse(Float64, x)
    value !== nothing && isfinite(value) || error("$label must be finite numeric")
    value
end

function _read_cells(path)
    _verify_pair(path, "canonical cell table") == CANONICAL_CELL_TABLE_SHA256 ||
        error("cell table differs from the frozen committed primary")
    table = _read_tsv(path, CELL_COLUMNS, "canonical cell table")
    length(table.rows) == 36 || error("canonical cell-table denominator drift")
    cells = Dict{String, NamedTuple}()
    order = String[]
    for (position, raw) in enumerate(table.rows)
        d = _rowdict(table, raw)
        cell = (
            cell_id=d["cell_id"],
            cell_index=_parse_int(d["cell_index"], "cell_index"),
            n=_parse_int(d["n"], "n"),
            m=_parse_int(d["m"], "m"),
            marker_ratio=_parse_float(d["marker_ratio"], "marker_ratio"),
            marker_ratio_text=d["marker_ratio"],
            marker_ratio_code=d["marker_ratio_code"],
            truth_sigma_g2=_parse_float(d["truth_sigma_g2"], "truth_sigma_g2"),
            truth_sigma_g2_text=d["truth_sigma_g2"],
            truth_sigma_e2=_parse_float(d["truth_sigma_e2"], "truth_sigma_e2"),
            truth_sigma_e2_text=d["truth_sigma_e2"],
            truth_ratio=_parse_float(d["truth_ratio"], "truth_ratio"),
            truth_ratio_text=d["truth_ratio"],
            ridge=_parse_float(d["ridge"], "ridge"),
            ridge_text=d["ridge"],
        )
        cell.cell_index == position || error("canonical cell-table row order drift")
        haskey(cells, cell.cell_id) && error("duplicate canonical cell ID")
        abs(cell.ridge - RIDGE) <= 1e-15 || error("canonical ridge drift")
        cells[cell.cell_id] = cell
        push!(order, cell.cell_id)
    end
    all(id -> haskey(cells, id), vcat(D1_DECISION_IDS, D2_DECISION_IDS,
        reduce(vcat, values(FIXTURE_MANIFEST_IDS)))) || error("fixture cell missing from canonical table")
    (cells=cells, order=order)
end

function _expected_predecessor_rows(stage)
    d1 = [stage, "d1", D1_SYNTHETIC_ROOT, D1_RECEIPT_SHA, D1_SUMMARY_SHA]
    stage == "d2" && return [d1]
    [d1, [stage, "d2", D2_SYNTHETIC_ROOT, D2_RECEIPT_SHA, D2_SUMMARY_SHA]]
end

function _read_predecessor_lock(path, stage)
    digest = _verify_pair(path, "synthetic predecessor lock")
    table = _read_tsv(path, PREDECESSOR_COLUMNS, "synthetic predecessor lock")
    table.rows == _expected_predecessor_rows(stage) ||
        error("predecessor lock differs from the frozen synthetic fixture")
    (table=table, digest=digest)
end

function _expected_decision_rows(stage)
    rows = [[stage, "d1", id, "TRUE", "200", D1_SUMMARY_SHA] for id in D1_DECISION_IDS]
    if stage != "d2"
        append!(rows, [[stage, "d2", id, "TRUE", "200", D2_SUMMARY_SHA] for id in D2_DECISION_IDS])
    end
    rows
end

function _read_decision_lock(path, stage, predecessor)
    digest = _verify_pair(path, "synthetic pilot-decision lock")
    table = _read_tsv(path, DECISION_COLUMNS, "synthetic pilot-decision lock")
    table.rows == _expected_decision_rows(stage) ||
        error("pilot-decision lock differs from the frozen synthetic fixture")
    pred = Dict(row[2] => row[5] for row in predecessor.table.rows)
    all(row -> pred[row[2]] == row[6], table.rows) ||
        error("pilot-decision lock summary digest differs from predecessor lock")
    (table=table, digest=digest)
end

function _expected_offsets(stage, cell)
    if stage == "d2"
        start = Dict(120 => 1001, 300 => 1101, 600 => 1201, 1200 => 1301)[cell.n]
        return start:(start + 47)
    elseif stage == "d3"
        return 2001:2200
    elseif stage == "d4"
        return 5001:5200
    end
    error("unsupported stage")
end

function _expected_manifest(stage, cell_data, decision)
    # The exact decision rows were authenticated above.  Membership and each
    # required-N are therefore derived from that lock, not from manifest shape.
    required = Dict(row[3] => _parse_int(row[5], "required_n") for row in decision.table.rows)
    rows = NamedTuple[]
    for id in FIXTURE_MANIFEST_IDS[stage]
        cell = cell_data.cells[id]
        expected_n = stage == "d2" ? 48 : required[id]
        expected_n == (stage == "d2" ? 48 : 200) || error("fixture required-N drift")
        offsets = _expected_offsets(stage, cell)
        length(offsets) == expected_n || error("fixture offset denominator drift")
        for offset in offsets
            push!(rows, (
                stage=stage,
                cell_id=id,
                cell_index=cell.cell_index,
                seed_offset=offset,
                seed=SEED_BASE + 10_000 * cell.cell_index + offset,
                n=cell.n,
                m=cell.m,
                marker_ratio=cell.marker_ratio,
                marker_ratio_code=cell.marker_ratio_code,
                truth_sigma_g2=cell.truth_sigma_g2,
                truth_sigma_e2=cell.truth_sigma_e2,
                truth_ratio=cell.truth_ratio,
                ridge=cell.ridge,
            ))
        end
    end
    rows
end

function _read_manifest(path, stage, cell_data, decision)
    digest = _verify_pair(path, "canonical synthetic manifest")
    table = _read_tsv(path, MANIFEST_COLUMNS, "canonical synthetic manifest")
    expected = _expected_manifest(stage, cell_data, decision)
    length(table.rows) == length(expected) || error("synthetic manifest denominator drift")
    for (position, (raw, canonical)) in enumerate(zip(table.rows, expected))
        d = _rowdict(table, raw)
        exact = (
            "stage" => canonical.stage,
            "cell_id" => canonical.cell_id,
            "cell_index" => canonical.cell_index,
            "seed_offset" => canonical.seed_offset,
            "seed" => canonical.seed,
            "n" => canonical.n,
            "m" => canonical.m,
            "marker_ratio_code" => canonical.marker_ratio_code,
        )
        for (field, value) in exact
            d[field] == string(value) || error("manifest row $position differs in $field")
        end
        numeric = (
            "marker_ratio" => canonical.marker_ratio,
            "truth_sigma_g2" => canonical.truth_sigma_g2,
            "truth_sigma_e2" => canonical.truth_sigma_e2,
            "truth_ratio" => canonical.truth_ratio,
            "ridge" => canonical.ridge,
        )
        for (field, value) in numeric
            parsed = _parse_float(d[field], field)
            if field == "truth_sigma_e2"
                # R may serialize 1 - 0.8 as 0.19999999999999996.  Admit only
                # this machine-representation neighbourhood, not scientific
                # tolerance, and normalize output to the cell-table spelling.
                abs(parsed - value) <= 2 * max(eps(parsed), eps(value)) ||
                    error("manifest row $position differs from canonical $field")
            else
                parsed == value ||
                    error("manifest row $position differs from canonical $field")
            end
        end
    end
    (table=table, digest=digest)
end

function _read_bindings(path, stage, hashes)
    digest = _verify_pair(path, "canonical synthetic bindings")
    table = _read_tsv(path, ["key", "value"], "canonical synthetic bindings")
    first.(table.rows) == BINDING_KEYS || error("binding key order drift")
    length(table.rows) == length(BINDING_KEYS) || error("binding denominator drift")
    values = Dict(row[1] => row[2] for row in table.rows)
    expected = Dict(
        "schema_version" => BINDING_SCHEMA,
        "stage" => stage,
        "fixture_contract" => FIXTURE_CONTRACT,
        "synthetic_only" => "true",
        "numerics_executable" => "false",
        "compute_policy" => COMPUTE_POLICY,
        "relationship_source" => RELATIONSHIP_SOURCE,
        "relationship_method" => RELATIONSHIP_METHOD,
        "allele_frequency_source" => ALLELE_FREQUENCY_SOURCE,
        "relationship_scale" => RELATIONSHIP_SCALE,
        "ridge" => "0.01",
        "cell_table_sha256" => hashes.cell_table,
        "source_manifest_sha256" => hashes.manifest,
        "predecessor_lock_sha256" => hashes.predecessor,
        "pilot_decision_lock_sha256" => hashes.decision,
    )
    values == expected || error("bindings differ from authenticated synthetic primaries or metadata")
    (values=values, digest=digest)
end

function _mirror_text(manifest, stage, hashes, cell_data)
    io = IOBuffer()
    println(io, join(MIRROR_COLUMNS, '\t'))
    for (position, (raw, line)) in enumerate(zip(manifest.table.rows, manifest.table.row_lines))
        d = _rowdict(manifest.table, raw)
        cell = cell_data.cells[d["cell_id"]]
        values = String[
            MIRROR_SCHEMA,
            stage,
            FIXTURE_CONTRACT,
            string(position),
            d["cell_id"],
            d["cell_index"],
            d["seed_offset"],
            d["seed"],
            d["n"],
            d["m"],
            cell.marker_ratio_text,
            d["marker_ratio_code"],
            cell.truth_sigma_g2_text,
            cell.truth_sigma_e2_text,
            cell.truth_ratio_text,
            cell.ridge_text,
            RELATIONSHIP_SOURCE,
            RELATIONSHIP_METHOD,
            ALLELE_FREQUENCY_SOURCE,
            RELATIONSHIP_SCALE,
            hashes.cell_table,
            hashes.manifest,
            _sha256_text(line * "\n"),
            hashes.predecessor,
            hashes.decision,
            SYNTHETIC_STATUS,
            "false",
            "false",
        ]
        println(io, join(values, '\t'))
    end
    String(take!(io))
end

function _write_once(path, text; after_primary_link=nothing)
    isabspath(path) && normpath(path) == path || error("output must be absolute and normalized")
    parent = _canonical_plain_dir(dirname(path), "output parent")
    (ispath(path) || ispath(path * ".sha256")) && error("create-once output already exists")
    primary_tmp = tempname(parent)
    sidecar_tmp = tempname(parent)
    expected_digest = _sha256_text(text)
    primary_identity = nothing
    sidecar_identity = nothing
    identity(p) = let s = lstat(p)
        (s.device, s.inode, s.mode, s.nlink, s.size, s.ctime)
    end
    same_identity(p, expected) = try
        identity(p) == expected
    catch
        false
    end
    try
        open(primary_tmp, "w") do io
            write(io, text)
        end
        Base.Filesystem.hardlink(primary_tmp, path)
        primary_identity = identity(path)
        after_primary_link !== nothing && after_primary_link(path)
        same_identity(path, primary_identity) ||
            error("create-once primary ownership changed during publication")
        _sha256(path) == expected_digest ||
            error("create-once primary content changed during publication")
        open(sidecar_tmp, "w") do io
            print(io, "$expected_digest  $(basename(path))\n")
        end
        Base.Filesystem.hardlink(sidecar_tmp, path * ".sha256")
        sidecar_identity = identity(path * ".sha256")
        same_identity(path, primary_identity) && _sha256(path) == expected_digest ||
            error("create-once primary changed before publication completed")
        same_identity(path * ".sha256", sidecar_identity) ||
            error("create-once sidecar ownership changed during publication")
        _verify_pair(path, "canonical synthetic mirror output")
    catch
        sidecar = path * ".sha256"
        sidecar_identity !== nothing && same_identity(sidecar, sidecar_identity) &&
            rm(sidecar; force=true)
        primary_identity !== nothing && same_identity(path, primary_identity) &&
            rm(path; force=true)
        rethrow()
    finally
        rm(primary_tmp; force=true)
        rm(sidecar_tmp; force=true)
    end
    nothing
end

function mirror_canonical_synthetic(
    stage,
    cell_table_path,
    manifest_path,
    predecessor_path,
    decision_path,
    bindings_path,
    output_path,
)
    stage in ALLOWED_STAGES || error("stage must be d2, d3, or d4")
    basename(output_path) == "v07_genomic_recovery_v3_$(stage)_canonical_synthetic_mirror.tsv" ||
        error("output basename must identify the canonical synthetic mirror")
    cell_data = _read_cells(cell_table_path)
    predecessor = _read_predecessor_lock(predecessor_path, stage)
    decision = _read_decision_lock(decision_path, stage, predecessor)
    manifest = _read_manifest(manifest_path, stage, cell_data, decision)
    hashes = (
        cell_table=CANONICAL_CELL_TABLE_SHA256,
        manifest=manifest.digest,
        predecessor=predecessor.digest,
        decision=decision.digest,
    )
    bindings = _read_bindings(bindings_path, stage, hashes)

    # Re-authenticate every input immediately before the only write.
    _verify_pair(cell_table_path, "canonical cell table") == hashes.cell_table ||
        error("cell table changed during validation")
    _verify_pair(manifest_path, "canonical synthetic manifest") == hashes.manifest ||
        error("manifest changed during validation")
    _verify_pair(predecessor_path, "synthetic predecessor lock") == hashes.predecessor ||
        error("predecessor lock changed during validation")
    _verify_pair(decision_path, "synthetic pilot-decision lock") == hashes.decision ||
        error("pilot-decision lock changed during validation")
    _verify_pair(bindings_path, "canonical synthetic bindings") == bindings.digest ||
        error("synthetic bindings changed during validation")

    _write_once(output_path, _mirror_text(manifest, stage, hashes, cell_data))
    mirror = _read_tsv(output_path, MIRROR_COLUMNS, "canonical synthetic mirror output")
    length(mirror.rows) == length(manifest.table.rows) || error("mirror lost manifest rows")
    all(row -> row[end-2:end] == [SYNTHETIC_STATUS, "false", "false"], mirror.rows) ||
        error("synthetic/non-evidence output label drift")
    nothing
end

function _table_text(columns, rows)
    io = IOBuffer()
    println(io, join(columns, '\t'))
    for row in rows
        println(io, join(row, '\t'))
    end
    String(take!(io))
end

function _write_pair(path, text)
    write(path, text)
    write(path * ".sha256", "$(_sha256(path))  $(basename(path))\n")
end

function _manifest_text(stage, cell_data, decision; ids=FIXTURE_MANIFEST_IDS[stage], counts=nothing)
    required = Dict(row[3] => _parse_int(row[5], "required_n") for row in decision.table.rows)
    rows = Vector{Vector{String}}()
    for id in ids
        cell = cell_data.cells[id]
        count = counts === nothing ? (stage == "d2" ? 48 : required[id]) : counts[id]
        first_offset = stage == "d2" ? Dict(120 => 1001, 300 => 1101,
            600 => 1201, 1200 => 1301)[cell.n] : stage == "d3" ? 2001 : 5001
        for offset in first_offset:(first_offset + count - 1)
            push!(rows, String[
                stage,
                id,
                string(cell.cell_index),
                string(offset),
                string(SEED_BASE + 10_000 * cell.cell_index + offset),
                string(cell.n),
                string(cell.m),
                string(cell.marker_ratio),
                cell.marker_ratio_code,
                string(cell.truth_sigma_g2),
                string(cell.truth_sigma_e2),
                string(cell.truth_ratio),
                string(cell.ridge),
            ])
        end
    end
    _table_text(MANIFEST_COLUMNS, rows)
end

function _binding_text(stage, hashes; overrides=Dict{String, String}())
    values = Dict(
        "schema_version" => BINDING_SCHEMA,
        "stage" => stage,
        "fixture_contract" => FIXTURE_CONTRACT,
        "synthetic_only" => "true",
        "numerics_executable" => "false",
        "compute_policy" => COMPUTE_POLICY,
        "relationship_source" => RELATIONSHIP_SOURCE,
        "relationship_method" => RELATIONSHIP_METHOD,
        "allele_frequency_source" => ALLELE_FREQUENCY_SOURCE,
        "relationship_scale" => RELATIONSHIP_SCALE,
        "ridge" => "0.01",
        "cell_table_sha256" => hashes.cell_table,
        "source_manifest_sha256" => hashes.manifest,
        "predecessor_lock_sha256" => hashes.predecessor,
        "pilot_decision_lock_sha256" => hashes.decision,
    )
    merge!(values, overrides)
    _table_text(["key", "value"], [[key, values[key]] for key in BINDING_KEYS])
end

function _race_write_once(root, round)
    output = joinpath(root, "race-$round.tsv")
    text = "canonical synthetic race $round\n"
    code = "include(ARGS[1]); _write_once(ARGS[2], ARGS[3])"
    processes = Base.Process[]
    for _ in 1:3
        cmd = `$(Base.julia_cmd()) --startup-file=no -e $code $(abspath(@__FILE__)) $output $text`
        push!(processes, run(pipeline(cmd; stdout=devnull, stderr=devnull); wait=false))
    end
    wait.(processes)
    count(success, processes) == 1 || error("concurrent create-once must have one winner")
    read(output, String) == text || error("loser deleted or changed winner primary")
    _verify_pair(output, "concurrent create-once winner")
    nothing
end

function selftest(cell_table_source)
    source = _canonical_plain_file(cell_table_source, "committed cell-table source")
    _sha256(source) == CANONICAL_CELL_TABLE_SHA256 || error("selftest source is not canonical")
    root = realpath(mktempdir())
    try
        cell_table = joinpath(root, "v07_genomic_recovery_v3_cell_table.tsv")
        _write_pair(cell_table, read(source, String))
        cell_data = _read_cells(cell_table)
        for stage in ALLOWED_STAGES
            predecessor_path = joinpath(root, "$stage-predecessor-lock.tsv")
            decision_path = joinpath(root, "$stage-pilot-decision-lock.tsv")
            manifest_path = joinpath(root, "$stage-manifest.tsv")
            bindings_path = joinpath(root, "$stage-bindings.tsv")
            output_path = joinpath(
                root, "v07_genomic_recovery_v3_$(stage)_canonical_synthetic_mirror.tsv",
            )
            _write_pair(
                predecessor_path,
                _table_text(PREDECESSOR_COLUMNS, _expected_predecessor_rows(stage)),
            )
            decision_rows = _expected_decision_rows(stage)
            _write_pair(decision_path, _table_text(DECISION_COLUMNS, decision_rows))
            decision = (
                table=TSV(DECISION_COLUMNS, decision_rows,
                    [join(row, '\t') for row in decision_rows]),
                digest=_sha256(decision_path),
            )
            manifest_text = _manifest_text(stage, cell_data, decision)
            # Normalize a valid R decimal spelling through parsed canonical
            # values rather than demanding Julia's independently formatted 0.2.
            stage == "d3" && (manifest_text = replace(
                manifest_text,
                "\t0.8\t0.2\t0.8\t0.01\n" =>
                    "\t0.8\t0.19999999999999996\t0.8\t0.01\n";
                count=1,
            ))
            _write_pair(manifest_path, manifest_text)
            hashes = (
                cell_table=CANONICAL_CELL_TABLE_SHA256,
                manifest=_sha256(manifest_path),
                predecessor=_sha256(predecessor_path),
                decision=_sha256(decision_path),
            )
            _write_pair(bindings_path, _binding_text(stage, hashes))
            mirror_canonical_synthetic(
                stage,
                cell_table,
                manifest_path,
                predecessor_path,
                decision_path,
                bindings_path,
                output_path,
            )
            expected_rows = stage == "d2" ? 480 : 1800
            mirror = _read_tsv(output_path, MIRROR_COLUMNS, "$stage mirror")
            length(mirror.rows) == expected_rows || error("$stage mirror denominator selftest")
            if stage == "d3"
                output_text = read(output_path, String)
                !occursin("0.19999999999999996", output_text) ||
                    error("R decimal spelling was not normalized to the cell-table primary")
            end
            _must_fail("create-once output") do
                mirror_canonical_synthetic(
                    stage,
                    cell_table,
                    manifest_path,
                    predecessor_path,
                    decision_path,
                    bindings_path,
                    output_path,
                )
            end
        end

        # Hopper/Noether attacks: each mutation carries a fresh valid sidecar;
        # hash-shaped or shape-correct substitutes still cannot pass.
        stage = "d3"
        pred = joinpath(root, "$stage-predecessor-lock.tsv")
        decisions = joinpath(root, "$stage-pilot-decision-lock.tsv")
        manifest = joinpath(root, "$stage-manifest.tsv")
        binding = joinpath(root, "$stage-bindings.tsv")
        decision_rows = _expected_decision_rows(stage)
        decision = (table=TSV(DECISION_COLUMNS, decision_rows,
            [join(row, '\t') for row in decision_rows]), digest=_sha256(decisions))

        impossible_ids = vcat(D2_DECISION_IDS,
            ["n0300_m1500_q5000_r020", "n0300_m1500_q5000_r080"])
        impossible = joinpath(root, "impossible-six-pair-d2.tsv")
        _write_pair(impossible, _manifest_text("d2", cell_data,
            (table=TSV(DECISION_COLUMNS, _expected_decision_rows("d2"), String[]), digest="");
            ids=impossible_ids))
        _must_fail("impossible six-pair D2") do
            _read_manifest(impossible, "d2", cell_data,
                (table=TSV(DECISION_COLUMNS, _expected_decision_rows("d2"), String[]), digest=""))
        end

        duplicate_ratio_ids = vcat(FIXTURE_MANIFEST_IDS["d3"][1:6], [
            "n0300_m0150_q0500_r020",
            "n0300_m0150_q0500_r050",
            "n0300_m0150_q0500_r080",
        ])
        duplicate_ratio = joinpath(root, "duplicate-ratio-d3.tsv")
        _write_pair(duplicate_ratio, _manifest_text("d3", cell_data, decision;
            ids=duplicate_ratio_ids))
        _must_fail("duplicate marker-ratio D3 triplet") do
            _read_manifest(duplicate_ratio, "d3", cell_data, decision)
        end

        reversed_d4 = joinpath(root, "reversed-d4.tsv")
        _write_pair(reversed_d4, _manifest_text("d4", cell_data,
            (table=TSV(DECISION_COLUMNS, decision_rows, String[]), digest="");
            ids=reverse(FIXTURE_MANIFEST_IDS["d4"])))
        _must_fail("reversed D4 order") do
            _read_manifest(reversed_d4, "d4", cell_data, decision)
        end

        counts = Dict(id => 200 for id in FIXTURE_MANIFEST_IDS["d3"])
        counts[FIXTURE_MANIFEST_IDS["d3"][1]] = 201
        arbitrary_count = joinpath(root, "arbitrary-201-d3.tsv")
        _write_pair(arbitrary_count, _manifest_text("d3", cell_data, decision; counts=counts))
        _must_fail("arbitrary 201-vs-200 confirmation count") do
            _read_manifest(arbitrary_count, "d3", cell_data, decision)
        end

        numeric_drift_dir = joinpath(root, "numeric-drift-attack")
        mkdir(numeric_drift_dir)
        numeric_drift = joinpath(numeric_drift_dir, "d3-manifest.tsv")
        drift_text = replace(read(manifest, String),
            "\t0.2\t0.8\t0.2\t0.01\n" =>
                "\t0.2000000000009\t0.8\t0.2\t0.01\n"; count=1)
        _write_pair(numeric_drift, drift_text)
        drift_hashes = (
            cell_table=CANONICAL_CELL_TABLE_SHA256,
            manifest=_sha256(numeric_drift),
            predecessor=_sha256(pred),
            decision=_sha256(decisions),
        )
        drift_binding = joinpath(numeric_drift_dir, "d3-bindings.tsv")
        _write_pair(drift_binding, _binding_text(stage, drift_hashes))
        _must_fail("fresh-sidecar and rebound 9e-13 canonical numeric drift") do
            mirror_canonical_synthetic(
                stage,
                cell_table,
                numeric_drift,
                pred,
                decisions,
                drift_binding,
                joinpath(numeric_drift_dir,
                    "v07_genomic_recovery_v3_d3_canonical_synthetic_mirror.tsv"),
            )
        end

        forged_rows = deepcopy(decision_rows)
        forged_rows[1][4] = "FALSE"
        forged_lock = joinpath(root, "forged-decision-lock.tsv")
        _write_pair(forged_lock, _table_text(DECISION_COLUMNS, forged_rows))
        _must_fail("fresh-sidecar forged decision lock") do
            _read_decision_lock(forged_lock, stage, _read_predecessor_lock(pred, stage))
        end
        forged_required_rows = deepcopy(decision_rows)
        forged_required_rows[1][5] = "201"
        forged_required = joinpath(root, "forged-required-n-lock.tsv")
        _write_pair(forged_required, _table_text(DECISION_COLUMNS, forged_required_rows))
        _must_fail("fresh-sidecar forged required-N decision") do
            _read_decision_lock(forged_required, stage, _read_predecessor_lock(pred, stage))
        end

        forged_pred_rows = deepcopy(_expected_predecessor_rows(stage))
        forged_pred_rows[2][5] = repeat("2", 64)
        forged_pred = joinpath(root, "forged-predecessor-lock.tsv")
        _write_pair(forged_pred, _table_text(PREDECESSOR_COLUMNS, forged_pred_rows))
        _must_fail("fresh-sidecar forged predecessor lock") do
            _read_predecessor_lock(forged_pred, stage)
        end

        hashes = (
            cell_table=CANONICAL_CELL_TABLE_SHA256,
            manifest=_sha256(manifest),
            predecessor=_sha256(pred),
            decision=_sha256(decisions),
        )
        metadata_attacks = Dict(
            "relationship_source" => "supplied_Ginv",
            "relationship_method" => "unknown",
            "allele_frequency_source" => "fixed_half",
            "relationship_scale" => "pedigree_A",
            "ridge" => "0.02",
        )
        for (field, replacement) in metadata_attacks
            bad_metadata = joinpath(root, "bad-$field-bindings.tsv")
            _write_pair(bad_metadata, _binding_text(stage, hashes;
                overrides=Dict(field => replacement)))
            _must_fail("$field metadata mutation") do
                _read_bindings(bad_metadata, stage, hashes)
            end
        end

        changed_table = joinpath(root, "changed-cell-table.tsv")
        changed_text = replace(read(cell_table, String), "\t0.2\t0.8\t0.2\t0.01\n" =>
            "\t0.2000000000001\t0.8\t0.2\t0.01\n"; count=1)
        _write_pair(changed_table, changed_text)
        _must_fail("fresh-sidecar changed canonical cell table") do
            _read_cells(changed_table)
        end

        _must_fail("summary-looking output basename") do
            mirror_canonical_synthetic(
                stage,
                cell_table,
                manifest,
                pred,
                decisions,
                binding,
                joinpath(root, "d3_summary_julia.tsv"),
            )
        end
        _must_fail("real confirmation replay remains unavailable") do
            main(["--mode=replay", "--stage=d2"])
        end
        _must_fail("D1 is not a downstream stage") do
            main(["--mode=mirror-canonical-synthetic", "--stage=d1"])
        end

        for round in 1:3
            _race_write_once(root, round)
        end

        # Exact ownership-cleanup attack: after this invocation links its
        # primary, replace the pathname with a symlink to a backup hardlink and
        # pre-create the sidecar so publication fails.  Cleanup must leave all
        # replacement paths untouched.
        replacement = joinpath(root, "replacement-attack.tsv")
        backup = joinpath(root, "replacement-attack-original-inode.tsv")
        attacker_sidecar = replacement * ".sha256"
        hook = function(path)
            Base.Filesystem.hardlink(path, backup)
            rm(path)
            symlink(backup, path)
            write(attacker_sidecar, "attacker-owned sidecar\n")
        end
        _must_fail("replacement symlink ownership cleanup") do
            _write_once(replacement, repeat("x", 1024); after_primary_link=hook)
        end
        islink(replacement) || error("cleanup deleted attacker replacement symlink")
        isfile(backup) || error("cleanup deleted attacker backup hardlink")
        read(attacker_sidecar, String) == "attacker-owned sidecar\n" ||
            error("cleanup deleted or changed attacker sidecar")

        blessed_replacement = joinpath(root, "blessed-replacement-attack.tsv")
        replacement_hook = function(path)
            rm(path)
            write(path, "attacker replacement\n")
        end
        _must_fail("replacement primary cannot be blessed on success path") do
            _write_once(
                blessed_replacement,
                "intended canonical\n";
                after_primary_link=replacement_hook,
            )
        end
        read(blessed_replacement, String) == "attacker replacement\n" ||
            error("cleanup deleted or changed unowned replacement primary")
        !ispath(blessed_replacement * ".sha256") ||
            error("failed replacement publication created a sidecar")
    finally
        rm(root; recursive=true, force=true)
    end
    println(
        "v0.7 genomic recovery-v3 D2-D4 canonical synthetic mirror selftest: " *
        "PASS (no HSquared import, fit, official RNG, seed consumption, or evidence)",
    )
    nothing
end

function main(args=ARGS)
    _reject_unknown_options(args)
    mode = _option(args, "mode"; default="selftest")
    if mode == "selftest"
        default_source = normpath(joinpath(
            @__DIR__, "..", "..", "hsquared", "docs", "design",
            "v07_genomic_recovery_v3_cell_table.tsv",
        ))
        source = _option(args, "cell-table-source"; default=default_source)
        return selftest(String(source))
    end
    mode in ("replay", "fit", "verify-replay", "summarize", "validate-final") &&
        error(
            "D2-D4 Julia numerics are fail-closed until the R downstream " *
            "packet, attempt, summary, and adjudication schemas pass audit",
        )
    mode == "mirror-canonical-synthetic" ||
        error("mode must be selftest or mirror-canonical-synthetic")
    stage = lowercase(_required(args, "stage"))
    stage in ALLOWED_STAGES || error("--stage must be d2, d3, or d4")
    mirror_canonical_synthetic(
        stage,
        _required(args, "cell-table"),
        _required(args, "manifest"),
        _required(args, "predecessor-lock"),
        _required(args, "pilot-decision-lock"),
        _required(args, "bindings"),
        _required(args, "output"),
    )
end

abspath(PROGRAM_FILE) == abspath(@__FILE__) && begin
    _verify_self()
    main()
end
