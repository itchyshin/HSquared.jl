module MVH3RGScreen

using SHA
using LinearAlgebra

export screen_config, pedigree_layout, record_layout, expected_relationship_inverse,
       simulate_from_draws, selected_source_pin_paths,
       config_sha256, canonical_identity_sha256, source_inventory, verify_source_inventory, source_inventory_sha256,
       validate_simulation_data, validate_manifest, validate_run_manifest, runtime_identity,
       verify_bundle, simulate_stage, fit_stage, interval_stage,
       summarize_attempts

"""Frozen *proposal* for one H3 interior genetic-correlation screen cell.

This file does not execute at include time. Parent assignment remains an explicit
protocol admission item; the proposed order follows the repository's historical
round-robin half-sib generator (sires, dams, then offspring).
"""
screen_config() = (
    nsire = 8, ndam = 16, noffspring = 96,
    nanimals = 120, records = 240, ntraits = 2,
    mean = [2.0, 2.0],
    G = [1.0 0.35; 0.35 0.7],
    R = [0.8 0.2; 0.2 0.55],
    true_rg = 0.35 / sqrt(0.7),
    pe = nothing, missingness = 0,
    genetic_structure = :unstructured,
    pedigree_design = :round_robin_halfsib,
    pedigree_order = :sires_dams_offspring,
    record_order = :animal_then_replicate,
    records_per_animal = 2,
    initial = nothing, iterations = 5000,
    interval_method = :delta, interval_level = 0.95,
    interval_pair = (2, 1),
)

"""Historical half-sib ID and parent vectors, in their original concatenated order."""
function pedigree_layout(config = screen_config())
    sires = ["s$i" for i in 1:config.nsire]
    dams = ["d$i" for i in 1:config.ndam]
    offspring = ["o$i" for i in 1:config.noffspring]
    ids = vcat(sires, dams, offspring)
    sire = vcat(fill("0", config.nsire + config.ndam),
                [sires[((i - 1) % config.nsire) + 1] for i in 1:config.noffspring])
    dam = vcat(fill("0", config.nsire + config.ndam),
               [dams[((i - 1) % config.ndam) + 1] for i in 1:config.noffspring])
    return (ids = ids, sire = sire, dam = dam)
end

"Two adjacent complete records per animal, preserving the historical row order."
record_layout(layout = pedigree_layout()) = repeat(layout.ids; inner = 2)

"Pedigree precision implied by the frozen founders-first parent vectors."
function expected_relationship_inverse(config = screen_config())
    layout = pedigree_layout(config)
    index = Dict(id => i for (i, id) in pairs(layout.ids))
    q = length(layout.ids); A = zeros(q, q)
    for i in 1:q
        s = layout.sire[i] == "0" ? 0 : index[layout.sire[i]]
        d = layout.dam[i] == "0" ? 0 : index[layout.dam[i]]
        (s == 0 || s < i) && (d == 0 || d < i) ||
            throw(ArgumentError("pedigree layout is not topologically ordered"))
        for j in 1:(i - 1)
            A[i, j] = 0.5 * ((s == 0 ? 0.0 : A[s, j]) + (d == 0 ? 0.0 : A[d, j]))
            A[j, i] = A[i, j]
        end
        A[i, i] = 1.0 + (s == 0 || d == 0 ? 0.0 : 0.5 * A[s, d])
    end
    return inv(Symmetric(A)) |> Matrix
end

"Selected files pinned for this candidate; not a complete loaded-code/dependency closure."
selected_source_pin_paths(root = normpath(joinpath(@__DIR__, ".."))) = [
    joinpath(root, "sim", "mv_h3_rg_screen_20261004.jl"),
    joinpath(root, "test", "test_mv_h3_rg_screen_contract.jl"),
    joinpath(root, "sim", "phase4_multivariate_reml_recovery.jl"),
    joinpath(root, "src", "multivariate.jl"),
    joinpath(root, "src", "pedigree.jl"),
]

_canonical(x::NamedTuple) = join(("$(k)=$(repr(getproperty(x, k)))" for k in keys(x)), "\n")
config_sha256(config) = bytes2hex(sha256(_canonical(config)))

_identity_frame(tag, payload) = string(tag, ncodeunits(payload), ":", payload)

function _canonical_identity(x)
    x === nothing && return _identity_frame("n", "")
    x isa Bool && return _identity_frame("b", x ? "1" : "0")
    x isa Integer && return _identity_frame("i", repr(x))
    x isa AbstractFloat && return _identity_frame("f", repr(x))
    x isa Symbol && return _identity_frame("y", String(x))
    x isa AbstractString && return _identity_frame("s", String(x))
    if x isa AbstractDict
        pairs_encoded = [_identity_frame("p", string(_identity_frame("k", _canonical_identity(k)),
            _identity_frame("v", _canonical_identity(v)))) for (k, v) in x]
        sort!(pairs_encoded)
        return _identity_frame("d", join(pairs_encoded))
    elseif x isa NamedTuple
        return _canonical_identity(Dict(string(k) => getproperty(x, k) for k in keys(x)))
    elseif x isa Tuple
        return _identity_frame("t", join(_identity_frame.(Ref("e"), _canonical_identity.(collect(x)))))
    elseif x isa AbstractVector
        return _identity_frame("a", join(_identity_frame.(Ref("e"), _canonical_identity.(collect(x)))))
    end
    throw(ArgumentError("unsupported value in canonical runtime identity: $(typeof(x))"))
end

canonical_identity_sha256(identity) = bytes2hex(sha256("mv-h3-runtime-identity-canonical-v1\n" * _canonical_identity(identity)))

"Return a deterministic SHA-256 inventory for the named input files."
function source_inventory(paths)
    rows = [(path = abspath(String(path)), sha256 = bytes2hex(sha256(read(path)))) for path in paths]
    isempty(rows) && throw(ArgumentError("source inventory must not be empty"))
    length(unique(getproperty.(rows, :path))) == length(rows) ||
        throw(ArgumentError("source inventory contains duplicate paths"))
    return rows
end

function _draws_sha256(E, e)
    vals = vcat(vec(Float64.(E)), vec(Float64.(e)))
    prefix = "E=$(size(E));e=$(size(e));"
    return bytes2hex(sha256(vcat(codeunits(prefix), reinterpret(UInt8, vals))))
end

function _dgp_design(E, e, config)
    layout = pedigree_layout(config)
    Ainv = expected_relationship_inverse(config)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    LA = cholesky(Symmetric(A)).L
    LG = cholesky(Symmetric(Matrix{Float64}(config.G))).L
    LR = cholesky(Symmetric(Matrix{Float64}(config.R))).L
    U = LA * Matrix{Float64}(E) * transpose(LG)
    X = ones(config.records, 1)
    Z = zeros(config.records, config.nanimals)
    Y = zeros(config.records, config.ntraits)
    row = 1
    for animal in 1:config.nanimals, _rep in 1:config.records_per_animal
        Z[row, animal] = 1.0
        Y[row, :] .= config.mean .+ U[animal, :] .+ LR * view(e, row, :)
        row += 1
    end
    return (Y = Y, X = X, Z = Z, Ainv = Ainv, ids = layout.ids,
            traits = ["trait1", "trait2"])
end

"Construct one Gaussian dataset from supplied standard-normal draws; no RNG or seed allocation."
function simulate_from_draws(E, e; config = screen_config())
    size(E) == (config.nanimals, config.ntraits) || throw(ArgumentError("E draw dimensions differ from pedigree × traits"))
    size(e) == (config.records, config.ntraits) || throw(ArgumentError("e draw dimensions differ from records × traits"))
    all(isfinite, E) && all(isfinite, e) || throw(ArgumentError("Gaussian standard-normal draws must be finite"))
    return merge(_dgp_design(E, e, config),
                 (E = Matrix{Float64}(E), e = Matrix{Float64}(e), draws_sha256 = _draws_sha256(E, e)))
end

function verify_source_inventory(rows)
    isempty(rows) && throw(ArgumentError("source inventory must not be empty"))
    for row in rows
        isfile(row.path) || throw(ArgumentError("pinned source file is missing: $(row.path)"))
        occursin(r"^[0-9a-f]{64}$", row.sha256) || throw(ArgumentError("invalid SHA-256 source pin"))
        actual = bytes2hex(sha256(read(row.path)))
        actual == row.sha256 || throw(ArgumentError("pinned source checksum mismatch: $(row.path)"))
    end
    return true
end

function _file_sha256(path)
    isfile(path) || throw(ArgumentError("required bundle file is missing: $path"))
    return bytes2hex(sha256(read(path)))
end

"Validate the separate screen or bounded timing manifest without allocating or running anything."
function validate_run_manifest(m)
    _get(m, "schema") == "mv-h3-rg-run-v1" || throw(ArgumentError("run manifest schema mismatch"))
    _get(m, "source_protocol_admission") == "HOLD" ||
        throw(ArgumentError("H3 source/protocol admission remains HOLD"))
    _get(m, "execution_authorized") === false ||
        throw(ArgumentError("manifest validation cannot authorize execution"))
    kind = _get(m, "kind")
    kind in ("screen", "timing") || throw(ArgumentError("run kind must be screen or timing"))
    attempts = _get(m, "attempts")
    seeds = get(m, "seed_inventory", nothing)
    if kind == "screen"
        attempts isa Integer && !(attempts isa Bool) && attempts == 48 ||
            throw(ArgumentError("screen manifest requires exactly 48 attempts"))
        seeds isa AbstractVector && length(seeds) == 48 ||
            throw(ArgumentError("screen manifest requires an explicit 48-seed inventory"))
        all(s -> s isa Integer && !(s isa Bool) && s > 0, seeds) && length(unique(seeds)) == 48 ||
            throw(ArgumentError("screen seed inventory must contain 48 unique positive integers"))
        any(k -> haskey(m, k), ("max_attempt_seconds", "max_total_seconds")) &&
            throw(ArgumentError("timing limits do not belong in the screen manifest"))
        return (kind = :screen, attempts = 48, seeds = collect(seeds), execution_enabled = false,
                allocation_verified = false, freshness_verified = false,
                external_fresh_process_verification_required = true, execution_admission_eligible = false)
    end
    attempts isa Integer && !(attempts isa Bool) && attempts == 3 ||
        throw(ArgumentError("timing manifest requires exactly three attempt slots"))
    max_each = _get(m, "max_attempt_seconds")
    max_total = _get(m, "max_total_seconds")
    max_each isa Real && !(max_each isa Bool) && isfinite(max_each) && 0 < max_each <= 600 ||
        throw(ArgumentError("timing attempt ceiling must be in (0, 600] seconds"))
    max_total isa Real && !(max_total isa Bool) && isfinite(max_total) && 0 < max_total <= 1800 ||
        throw(ArgumentError("timing total ceiling must be in (0, 1800] seconds"))
    max_total >= attempts * max_each ||
        throw(ArgumentError("timing total ceiling cannot be below the sum of attempt ceilings"))
    if seeds !== nothing
        _get(m, "seed_allocation_admission") == "ADMITTED" ||
            throw(ArgumentError("timing seeds require a separately admitted allocation"))
        allocation_sha = _get(m, "seed_allocation_sha256")
        allocation_sha isa AbstractString && occursin(r"^[0-9a-f]{64}$", allocation_sha) ||
            throw(ArgumentError("timing seed allocation requires its pinned SHA-256"))
        seeds isa AbstractVector && length(seeds) == attempts &&
            all(s -> s isa Integer && !(s isa Bool) && s > 0, seeds) && length(unique(seeds)) == attempts ||
            throw(ArgumentError("timing seed inventory must contain three unique positive integers"))
        bytes2hex(sha256(join(string.(seeds), "\n"))) == allocation_sha ||
            throw(ArgumentError("timing seed inventory differs from its admitted allocation checksum"))
    elseif haskey(m, "seed_allocation_admission") || haskey(m, "seed_allocation_sha256")
        throw(ArgumentError("seed allocation admission is present without a seed inventory"))
    end
    return (kind = :timing, attempts = attempts, seeds = seeds === nothing ? nothing : collect(seeds),
            max_attempt_seconds = Float64(max_each), max_total_seconds = Float64(max_total),
            execution_enabled = false, allocation_verified = false, freshness_verified = false,
            external_fresh_process_verification_required = true, execution_admission_eligible = false)
end

"Capture the actual Julia and package environment identity; this performs no model work."
function runtime_identity(root = normpath(joinpath(@__DIR__, ".."));
                          julia_executable = joinpath(Sys.BINDIR, Base.julia_exename()))
    project = joinpath(realpath(root), "Project.toml")
    modules = [mod for (_, mod) in Base.loaded_modules if nameof(mod) === :HSquared]
    length(modules) == 1 || throw(ArgumentError("exactly one loaded HSquared module is required for bundle identity"))
    hsquared = pathof(only(modules))
    hsquared === nothing && throw(ArgumentError("loaded HSquared module has no source path"))
    hsquared = realpath(hsquared)
    return Dict{String,Any}(
        "julia_executable" => realpath(julia_executable),
        "julia_executable_sha256" => _file_sha256(julia_executable),
        "julia_version" => string(VERSION),
        "hsquared_module_path" => hsquared,
        "hsquared_source_sha256" => _file_sha256(hsquared),
        "project_path" => project,
        "active_project" => Base.active_project() === nothing ? nothing : realpath(Base.active_project()),
        "project_sha256" => _file_sha256(project),
        "manifest_sha256" => _file_sha256(joinpath(dirname(project), "Manifest.toml")),
        "julia_threads" => Threads.nthreads(),
        "blas_threads" => BLAS.get_num_threads(),
        "julia_threads_env" => get(ENV, "JULIA_NUM_THREADS", ""),
        "blas_thread_environment" => Dict(name => get(ENV, name, "") for name in
            ("OPENBLAS_NUM_THREADS", "OMP_NUM_THREADS", "VECLIB_MAXIMUM_THREADS", "MKL_NUM_THREADS", "BLIS_NUM_THREADS")),
        "blas_vendor" => string(BLAS.get_config()),
        "platform" => Dict("machine" => Sys.MACHINE, "kernel" => string(Sys.KERNEL), "arch" => string(Sys.ARCH)))
end

"Verify pinned source and runtime identity, returning a receipt; performs no RNG, fit, or simulation."
function verify_bundle(root, bundle)
    return _verify_bundle(root, bundle, runtime_identity(root))
end

function _verify_bundle(root, bundle, observed)
    root = realpath(root)
    _get(bundle, "schema") == "mv-h3-rg-bundle-v1" || throw(ArgumentError("bundle schema mismatch"))
    _get(bundle, "source_protocol_admission") == "HOLD" ||
        throw(ArgumentError("H3 source/protocol admission remains HOLD"))
    _get(bundle, "execution_authorized") === false ||
        throw(ArgumentError("bundle verification cannot authorize execution"))
    rows = _get(bundle, "source_inventory")
    all(hasproperty(row, :path) && hasproperty(row, :sha256) for row in rows) ||
        throw(ArgumentError("bundle source inventory rows require path and sha256"))
    expected = sort(relpath.(selected_source_pin_paths(root), Ref(root)))
    paths = String[row.path for row in rows]
    length(unique(paths)) == length(paths) && sort(paths) == expected ||
        throw(ArgumentError("bundle source inventory differs from the selected-file pin set"))
    absolute_rows = [(path = joinpath(root, row.path), sha256 = row.sha256) for row in rows]
    verify_source_inventory(absolute_rows)
    identity = _get(bundle, "identity")
    identity_keys = ("julia_executable", "julia_executable_sha256", "julia_version",
                "hsquared_module_path", "hsquared_source_sha256", "project_path", "active_project",
                "project_sha256", "manifest_sha256", "julia_threads", "blas_threads",
                "julia_threads_env", "blas_thread_environment", "blas_vendor", "platform")
    Set(keys(identity)) == Set(identity_keys) || throw(ArgumentError("bundle runtime identity fields differ from contract"))
    for key in identity_keys
        haskey(identity, key) || throw(ArgumentError("bundle runtime identity missing $key"))
        haskey(observed, key) && identity[key] == observed[key] ||
            throw(ArgumentError("observed runtime identity differs for $key"))
    end
    identity["project_path"] == joinpath(root, "Project.toml") ||
        throw(ArgumentError("bundle project path differs from verified root"))
    identity["active_project"] == identity["project_path"] ||
        throw(ArgumentError("active Julia project differs from bundle project"))
    identity["project_sha256"] == _file_sha256(joinpath(root, "Project.toml")) ||
        throw(ArgumentError("Project.toml checksum differs from bundle identity"))
    identity["manifest_sha256"] == _file_sha256(joinpath(root, "Manifest.toml")) ||
        throw(ArgumentError("Manifest.toml checksum differs from bundle identity"))
    identity["hsquared_module_path"] == joinpath(root, "src", "HSquared.jl") ||
        throw(ArgumentError("HSquared module path differs from verified source root"))
    identity["hsquared_source_sha256"] == _file_sha256(joinpath(root, "src", "HSquared.jl")) ||
        throw(ArgumentError("HSquared source checksum differs from bundle identity"))
    realpath(identity["julia_executable"]) == identity["julia_executable"] ||
        throw(ArgumentError("Julia executable path must be canonical"))
    identity["julia_executable_sha256"] == _file_sha256(identity["julia_executable"]) ||
        throw(ArgumentError("Julia executable checksum differs from bundle identity"))
    identity["julia_threads"] isa Integer && identity["julia_threads"] > 0 ||
        throw(ArgumentError("invalid Julia runtime thread count"))
    identity["blas_threads"] isa Integer && identity["blas_threads"] > 0 ||
        throw(ArgumentError("invalid BLAS runtime thread count"))
    julia_env = identity["julia_threads_env"]
    (isempty(julia_env) || (tryparse(Int, julia_env) == identity["julia_threads"])) ||
        throw(ArgumentError("JULIA_NUM_THREADS environment pin disagrees with runtime count"))
    blas_env = identity["blas_thread_environment"]
    blas_env isa AbstractDict && Set(keys(blas_env)) == Set(("OPENBLAS_NUM_THREADS", "OMP_NUM_THREADS",
        "VECLIB_MAXIMUM_THREADS", "MKL_NUM_THREADS", "BLIS_NUM_THREADS")) ||
        throw(ArgumentError("BLAS thread environment is incomplete"))
    for (name, value) in blas_env
        isempty(value) || (tryparse(Int, value) == identity["blas_threads"]) ||
            throw(ArgumentError("$name environment pin disagrees with runtime BLAS thread count"))
    end
    bundle_hash = canonical_identity_sha256(identity)
    source_hash = source_inventory_sha256(absolute_rows)
    return Dict("schema" => "mv-h3-rg-verification-receipt-v1", "selected_pins_verified" => true,
                "source_pin_scope" => "selected_file_pin_set_not_complete_loaded_code_closure",
                "loaded_code_identity_verified" => false, "dependency_resolution_verified" => false,
                "allocation_verified" => false, "freshness_verified" => false,
                "external_fresh_process_immutable_bundle_verification_required" => true,
                "execution_admission_eligible" => false, "execution_performed" => false,
                "source_sha256" => source_hash,
                "identity_sha256" => bundle_hash, "source_count" => length(absolute_rows),
                "active_project" => identity["active_project"], "julia_version" => identity["julia_version"])
end

function source_inventory_sha256(rows)
    isempty(rows) && throw(ArgumentError("source inventory must not be empty"))
    ordered = sort(collect(rows); by = row -> row.path)
    return bytes2hex(sha256(join(("$(row.path)=$(row.sha256)" for row in ordered), "\n")))
end

"""Reject data not matching the frozen complete H3 design and row/animal mapping."""
function validate_simulation_data(sim, config = screen_config())
    for name in (:Y, :X, :Z, :Ainv, :ids, :traits, :E, :e, :draws_sha256)
        hasproperty(sim, name) || throw(ArgumentError("simulation data missing $name"))
    end
    Y, X, Z, Ainv = sim.Y, sim.X, sim.Z, sim.Ainv
    layout = pedigree_layout(config)
    size(Y) == (config.records, config.ntraits) || throw(ArgumentError("Y dimensions differ from complete H3 design"))
    size(X) == (config.records, 1) && all(==(1), X) || throw(ArgumentError("X must be the shared intercept for every record"))
    size(Z) == (config.records, config.nanimals) || throw(ArgumentError("Z dimensions differ from complete H3 design"))
    all(isfinite, Y) || throw(ArgumentError("Y contains non-finite observations"))
    size(sim.E) == (config.nanimals, config.ntraits) && size(sim.e) == (config.records, config.ntraits) ||
        throw(ArgumentError("standard-normal draw dimensions differ from frozen DGP"))
    all(isfinite, sim.E) && all(isfinite, sim.e) || throw(ArgumentError("DGP draws are non-finite"))
    sim.draws_sha256 == _draws_sha256(sim.E, sim.e) || throw(ArgumentError("DGP draw checksum mismatch"))
    collect(sim.ids) == layout.ids || throw(ArgumentError("animal ID/order differs from frozen pedigree layout"))
    length(sim.traits) == config.ntraits && length(unique(sim.traits)) == config.ntraits ||
        throw(ArgumentError("trait labels must be unique and match the two trait columns"))
    for animal in 1:config.nanimals, rep in 1:config.records_per_animal
        row = (animal - 1) * config.records_per_animal + rep
        count(x -> !iszero(x), view(Z, row, :)) == 1 && Z[row, animal] == 1 ||
            throw(ArgumentError("Z row $row violates frozen animal/record mapping"))
    end
    size(Ainv) == (config.nanimals, config.nanimals) || throw(ArgumentError("Ainv dimensions differ from pedigree"))
    all(isfinite, Ainv) && isapprox(Ainv, transpose(Ainv); atol = 1e-10, rtol = 1e-10) ||
        throw(ArgumentError("Ainv must be finite and symmetric"))
    try
        cholesky(Symmetric(Matrix{Float64}(Ainv)); check = true)
    catch
        throw(ArgumentError("Ainv must be positive definite"))
    end
    isapprox(Matrix{Float64}(Ainv), expected_relationship_inverse(config); atol = 1e-8, rtol = 1e-8) ||
        throw(ArgumentError("Ainv does not match the frozen pedigree relationship matrix"))
    expected = _dgp_design(sim.E, sim.e, config)
    isapprox(Y, expected.Y; atol = 1e-10, rtol = 1e-10) ||
        throw(ArgumentError("Y does not match the frozen L_A E L_G' and e L_R' Gaussian transforms"))
    return true
end

_get(m, key) = haskey(m, key) ? m[key] : throw(ArgumentError("manifest missing $key"))

"Validate screen identity and allocation. `test_mode` is for callback contract tests only."
function validate_manifest(m; test_mode::Bool = false)
    _get(m, "schema") == "mv-h3-rg-screen-v1" || throw(ArgumentError("manifest schema mismatch"))
    _get(m, "cell_id") == "h3-interior-rg-delta" || throw(ArgumentError("manifest cell mismatch"))
    config = _get(m, "config")
    config == screen_config() || throw(ArgumentError("screen configuration mismatch"))
    _get(m, "config_sha256") == config_sha256(config) || throw(ArgumentError("configuration checksum mismatch"))
    source_hash = _get(m, "source_sha256")
    occursin(r"^[0-9a-f]{64}$", source_hash) || throw(ArgumentError("source pin must be a SHA-256 digest"))
    source_rows = _get(m, "source_inventory")
    source_paths = abspath.(getproperty.(source_rows, :path))
    length(unique(source_paths)) == length(source_paths) ||
        throw(ArgumentError("source inventory contains duplicate source identities"))
    Set(source_paths) == Set(abspath.(selected_source_pin_paths())) ||
        throw(ArgumentError("source inventory does not match the selected-file pin set"))
    source_inventory_sha256(source_rows) == source_hash ||
        throw(ArgumentError("source inventory digest mismatch"))
    verify_source_inventory(source_rows)
    seeds = _get(m, "seed_inventory")
    attempts = _get(m, "attempts")
    attempts == 48 || throw(ArgumentError("screen attempt count must be 48"))
    length(seeds) == attempts || throw(ArgumentError("seed inventory length differs from attempt count"))
    all(s -> s isa Integer && s > 0, seeds) || throw(ArgumentError("seeds must be positive integers"))
    length(unique(seeds)) == length(seeds) || throw(ArgumentError("seed inventory contains duplicates"))
    _get(m, "source_protocol_admission") == "HOLD" ||
        throw(ArgumentError("screen source/protocol admission is held pending independent review"))
    test_mode || throw(ArgumentError("screen execution is held pending source/protocol admission; test callbacks only"))
    seed_hash = bytes2hex(sha256(join(string.(seeds), "\n")))
    return (attempts = attempts, seeds = collect(seeds), config_sha256 = config_sha256(config),
            source_sha256 = source_hash, seed_inventory_sha256 = seed_hash, claim_eligible = false,
            allocation_verified = false, freshness_verified = false,
            external_fresh_process_verification_required = true, execution_admission_eligible = false)
end

_failure(seed, stage, err) = (seed = seed, stage = stage, status = Symbol(stage, :_failed), value = nothing,
                               error = sprint(showerror, err))

function simulate_stage(manifest; simulate, test_mode::Bool = false)
    validated = validate_manifest(manifest; test_mode)
    provenance = (config_sha256 = validated.config_sha256,
                  source_sha256 = validated.source_sha256,
                  seed_inventory_sha256 = validated.seed_inventory_sha256)
    out = NamedTuple[]
    for seed in validated.seeds
        push!(out, try
            value = simulate(seed)
            validate_simulation_data(value)
            attempt_provenance = merge(provenance, (input_sha256 = value.draws_sha256,))
            (seed = seed, stage = :simulation, status = :simulated, value = value,
             provenance = attempt_provenance, error = nothing)
        catch err
            merge(_failure(seed, :simulation, err), (; provenance))
        end)
    end
    return out
end

function _validate_fit_result(fit)
    for field in (:converged, :loglik, :genetic_covariance, :residual_covariance,
                  :genetic_correlation, :residual_correlation)
        hasproperty(fit, field) || throw(ArgumentError("fit result missing $field"))
    end
    fit.converged === true || throw(ArgumentError("fit did not converge"))
    isfinite(fit.loglik) || throw(ArgumentError("fit log likelihood is non-finite"))
    for field in (:genetic_covariance, :residual_covariance, :genetic_correlation, :residual_correlation)
        value = Matrix{Float64}(getproperty(fit, field))
        size(value) == (2, 2) && all(isfinite, value) ||
            throw(ArgumentError("fit $field must be a finite 2×2 matrix"))
        isapprox(value, transpose(value); atol = 1e-10, rtol = 1e-10) ||
            throw(ArgumentError("fit $field must be symmetric"))
    end
    G = Matrix{Float64}(fit.genetic_covariance)
    R = Matrix{Float64}(fit.residual_covariance)
    RG = Matrix{Float64}(fit.genetic_correlation)
    RR = Matrix{Float64}(fit.residual_correlation)
    all(>(0), diag(G)) && all(>(0), diag(R)) ||
        throw(ArgumentError("fit covariance estimates must have positive marginal variances"))
    for (name, matrix) in ((:genetic_covariance, G), (:residual_covariance, R),
                           (:genetic_correlation, RG), (:residual_correlation, RR))
        try
            cholesky(Symmetric(matrix); check = true)
        catch
            throw(ArgumentError("fit $name must be positive definite"))
        end
    end
    rg = Matrix{Float64}(fit.genetic_correlation)
    isapprox(diag(rg), ones(2); atol = 1e-8, rtol = 1e-8) ||
        throw(ArgumentError("fit genetic correlation diagonal must equal one"))
    all(abs.(rg) .<= 1) || throw(ArgumentError("fit genetic correlations are outside [-1, 1]"))
    expected_rg = G[1, 2] / sqrt(G[1, 1] * G[2, 2])
    isapprox(rg, transpose(rg); atol = 1e-10, rtol = 1e-10) &&
        isapprox(rg[1, 2], expected_rg; atol = 1e-8, rtol = 1e-8) ||
        throw(ArgumentError("fit genetic correlation does not match its covariance estimate"))
    expected_rr = R[1, 2] / sqrt(R[1, 1] * R[2, 2])
    isapprox(RG, transpose(RG); atol = 1e-10, rtol = 1e-10) &&
        isapprox(diag(RR), ones(2); atol = 1e-8, rtol = 1e-8) &&
        isapprox(RR[1, 2], expected_rr; atol = 1e-8, rtol = 1e-8) ||
        throw(ArgumentError("fit residual correlation does not match its covariance estimate"))
    return true
end

function fit_evidence_sha256(fit)
    values = vcat(vec(Float64.(Matrix(fit.genetic_covariance))),
                  vec(Float64.(Matrix(fit.residual_covariance))),
                  vec(Float64.(Matrix(fit.genetic_correlation))),
                  vec(Float64.(Matrix(fit.residual_correlation))),
                  [Float64(fit.loglik), fit.converged === true ? 1.0 : 0.0])
    return bytes2hex(sha256(reinterpret(UInt8, values)))
end

function _fit_payload(fit)
    _validate_fit_result(fit)
    payload = (converged = true, loglik = Float64(fit.loglik),
               genetic_covariance = Matrix{Float64}(fit.genetic_covariance),
               residual_covariance = Matrix{Float64}(fit.residual_covariance),
               genetic_correlation = Matrix{Float64}(fit.genetic_correlation),
               residual_correlation = Matrix{Float64}(fit.residual_correlation))
    return merge(payload, (sha256 = fit_evidence_sha256(payload),))
end

function _rejected_fit_diagnostic(fit)
    rendered = sprint(show, fit)
    return (type = string(typeof(fit)), rendered, sha256 = bytes2hex(sha256(rendered)))
end

function _validate_fit_payload(payload)
    payload === nothing && throw(ArgumentError("successful-fit record lacks retained fit evidence"))
    hasproperty(payload, :sha256) || throw(ArgumentError("retained fit evidence lacks its checksum"))
    _validate_fit_result(payload)
    fit_evidence_sha256(payload) == payload.sha256 ||
        throw(ArgumentError("retained fit evidence checksum mismatch"))
    return true
end

"`fit` has the exact public fitter shape: fit(Y,X,Z,Ainv; keywords...)."
function fit_stage(simulations; fit, config = screen_config())
    config == screen_config() || throw(ArgumentError("fit-stage configuration differs from the frozen screen contract"))
    out = NamedTuple[]
    for attempt in simulations
        if attempt.status != :simulated
            push!(out, merge((seed = attempt.seed, stage = attempt.stage, status = attempt.status,
                              value = nothing, fit_payload = nothing, error = attempt.error),
                             hasproperty(attempt, :provenance) ? (; provenance = attempt.provenance) : NamedTuple()))
        else
            fit_value = nothing
            returned = false
            row = try
                sim = attempt.value
                fit_value = fit(sim.Y, sim.X, sim.Z, sim.Ainv;
                            genetic_structure = config.genetic_structure,
                            initial = config.initial, iterations = config.iterations,
                            ids = sim.ids, traits = sim.traits)
                returned = true
                _validate_fit_result(fit_value)
                (seed = attempt.seed, stage = :fit, status = :fit, value = fit_value, simulation = sim,
                 fit_payload = _fit_payload(fit_value), rejected_fit_diagnostic = nothing,
                 provenance = attempt.provenance, error = nothing)
            catch err
                diagnostic = returned ? _rejected_fit_diagnostic(fit_value) : nothing
                merge(_failure(attempt.seed, :fit, err),
                      (; provenance = attempt.provenance, fit_payload = nothing,
                         rejected_fit_diagnostic = diagnostic))
            end
            push!(out, row)
        end
    end
    return out
end

function _adapt_interval(raw, fit, config, provenance)
    for field in (:trait_i, :trait_j, :estimate, :lower, :upper, :lower_clamped,
                  :upper_clamped, :level, :method, :converged)
        hasproperty(raw, field) || throw(ArgumentError("interval result missing $field"))
    end
    raw.converged === true || throw(ArgumentError("interval result is not tied to a converged fit"))
    raw.level == config.interval_level && raw.method == config.interval_method ||
        throw(ArgumentError("interval level or method differs from the frozen contract"))
    length(raw.trait_i) == length(raw.trait_j) == length(raw.estimate) ==
        length(raw.lower) == length(raw.upper) == length(raw.lower_clamped) ==
        length(raw.upper_clamped) == 1 || throw(ArgumentError("interval result must contain exactly the requested pair"))
    (raw.trait_i[1], raw.trait_j[1]) == config.interval_pair ||
        throw(ArgumentError("interval result pair differs from requested pair"))
    estimate = Float64(raw.estimate[1]); lower = Float64(raw.lower[1]); upper = Float64(raw.upper[1])
    fit_estimate = Float64(fit.genetic_correlation[2, 1])
    isfinite(estimate) && -1 < estimate < 1 && isapprox(estimate, fit_estimate; atol = 1e-10, rtol = 1e-10) ||
        throw(ArgumentError("interval estimate is invalid or does not match fitted correlation"))
    isfinite(lower) && isfinite(upper) && -1 < lower <= estimate <= upper < 1 ||
        throw(ArgumentError("interval bounds must be finite, interior to [-1,1], and contain the estimate"))
    raw.lower_clamped[1] === false && raw.upper_clamped[1] === false ||
        throw(ArgumentError("clamped interval bounds are refused"))
    return (estimate = estimate, fit_estimate = fit_estimate, lower = lower, upper = upper,
            pair = config.interval_pair,
            level = Float64(raw.level), method = raw.method, converged = true,
            lower_clamped = false, upper_clamped = false,
            fit_loglik = Float64(fit.loglik), fit_genetic_covariance = Matrix{Float64}(fit.genetic_covariance),
            fit_residual_covariance = Matrix{Float64}(fit.residual_covariance),
            fit_genetic_correlation = Matrix{Float64}(fit.genetic_correlation),
            fit_residual_correlation = Matrix{Float64}(fit.residual_correlation),
            fit_sha256 = fit_evidence_sha256(fit), provenance)
end

"`interval` has the exact API shape: interval(fit,Y,X,Z,Ainv; level,method,pairs)."
function interval_stage(fits; interval, config = screen_config())
    config == screen_config() || throw(ArgumentError("interval-stage configuration differs from the frozen screen contract"))
    out = NamedTuple[]
    for attempt in fits
        if attempt.status != :fit
            push!(out, merge((seed = attempt.seed, stage = attempt.stage, status = attempt.status, interval = nothing,
                              fit_payload = hasproperty(attempt, :fit_payload) ? attempt.fit_payload : nothing,
                              rejected_fit_diagnostic = hasproperty(attempt, :rejected_fit_diagnostic) ?
                                  attempt.rejected_fit_diagnostic : nothing,
                              error = attempt.error),
                             hasproperty(attempt, :provenance) ? (; provenance = attempt.provenance) : NamedTuple()))
        else
            push!(out, try
                sim = attempt.simulation
                raw = interval(attempt.value, sim.Y, sim.X, sim.Z, sim.Ainv;
                               level = config.interval_level, method = config.interval_method,
                               pairs = [config.interval_pair])
                formed = _adapt_interval(raw, attempt.value, config, attempt.provenance)
                (seed = attempt.seed, stage = :interval, status = :formed, interval = formed, fit_payload = attempt.fit_payload,
                 rejected_fit_diagnostic = nothing,
                 provenance = attempt.provenance, error = nothing)
            catch err
                (seed = attempt.seed, stage = :interval, status = :interval_failed, interval = nothing,
                 fit_payload = attempt.fit_payload,
                 rejected_fit_diagnostic = nothing,
                 provenance = attempt.provenance, error = sprint(showerror, err))
            end)
        end
    end
    return out
end

"""Summarize all attempts; duplicate, foreign, or missing seeds invalidate the ledger.

`F` counts successful fits, `I` counts interpretable formed intervals, and `C`
counts those intervals covering `truth_rg`. The proposed floor is 44/48; this
summary never makes a scientific claim eligible while admission is held.
"""
function summarize_attempts(manifest, records; truth_rg::Real = screen_config().true_rg, test_mode::Bool = true)
    truth_rg == screen_config().true_rg || throw(ArgumentError("coverage truth differs from frozen G covariance"))
    validated = validate_manifest(manifest; test_mode)
    observed = getproperty.(records, :seed)
    length(observed) == validated.attempts || throw(ArgumentError("attempt ledger has missing or extra rows"))
    length(unique(observed)) == length(observed) || throw(ArgumentError("attempt ledger has duplicate seeds"))
    Set(observed) == Set(validated.seeds) || throw(ArgumentError("attempt ledger contains foreign or missing seeds"))
    expected_provenance = (config_sha256 = validated.config_sha256,
                           source_sha256 = validated.source_sha256,
                           seed_inventory_sha256 = validated.seed_inventory_sha256)
    all(r -> hasproperty(r, :provenance) && all(k -> hasproperty(r.provenance, k) &&
        getproperty(r.provenance, k) == getproperty(expected_provenance, k), keys(expected_provenance)), records) ||
        throw(ArgumentError("attempt row provenance differs from the validated input checksums"))
    all(r -> r.status in (:formed, :simulation_failed, :fit_failed, :interval_failed,
                           :not_interpretable), records) || throw(ArgumentError("unknown attempt status"))
    all(r -> hasproperty(r, :stage) && r.stage ==
        (r.status == :simulation_failed ? :simulation : r.status == :fit_failed ? :fit :
         r.status in (:interval_failed, :not_interpretable, :formed) ? :interval : :invalid), records) ||
        throw(ArgumentError("attempt row stage does not match its terminal status"))
    all(r -> r.status == :simulation_failed ||
        (hasproperty(r.provenance, :input_sha256) &&
         occursin(r"^[0-9a-f]{64}$", r.provenance.input_sha256)), records) ||
        throw(ArgumentError("successful simulation attempt lacks its standard-normal input checksum"))
    for r in records
        fit_succeeded = r.status in (:formed, :interval_failed, :not_interpretable)
        if fit_succeeded
            hasproperty(r, :fit_payload) || throw(ArgumentError("successful-fit row lacks retained fit evidence"))
            _validate_fit_payload(r.fit_payload)
        else
            (!hasproperty(r, :fit_payload) || r.fit_payload === nothing) ||
                throw(ArgumentError("failed simulation or fit row must not carry successful-fit evidence"))
        end
        r.status == :formed || continue
        hasproperty(r, :interval) || throw(ArgumentError("formed attempt lacks interval evidence"))
        iv = r.interval
        for field in (:estimate, :fit_estimate, :lower, :upper, :pair, :level, :method, :converged,
                      :lower_clamped, :upper_clamped, :fit_loglik, :fit_genetic_covariance,
                      :fit_residual_covariance, :fit_genetic_correlation, :fit_residual_correlation,
                      :fit_sha256, :provenance)
            hasproperty(iv, field) || throw(ArgumentError("formed interval lacks $field provenance"))
        end
        iv.provenance == r.provenance || throw(ArgumentError("formed interval provenance mismatch"))
        iv.fit_sha256 == r.fit_payload.sha256 ||
            throw(ArgumentError("formed interval is not bound to the retained successful-fit evidence"))
        iv.pair == screen_config().interval_pair && iv.level == screen_config().interval_level &&
            iv.method == screen_config().interval_method && iv.converged === true ||
            throw(ArgumentError("formed interval pair, level, method, or convergence mismatch"))
        all(isfinite, (iv.estimate, iv.lower, iv.upper, iv.fit_loglik)) &&
            -1 < iv.lower <= iv.estimate <= iv.upper < 1 ||
            throw(ArgumentError("formed interval has invalid estimate, bounds, or fit likelihood"))
        iv.lower_clamped === false && iv.upper_clamped === false ||
            throw(ArgumentError("clamped interval bounds are refused"))
        all(size(getproperty(iv, field)) == (2, 2) for field in
            (:fit_genetic_covariance, :fit_residual_covariance, :fit_genetic_correlation,
             :fit_residual_correlation)) ||
            throw(ArgumentError("formed interval fit evidence has invalid dimensions"))
        all(all(isfinite, getproperty(iv, field)) for field in
            (:fit_genetic_covariance, :fit_residual_covariance, :fit_genetic_correlation,
             :fit_residual_correlation)) ||
            throw(ArgumentError("formed interval fit evidence is non-finite"))
        isapprox(iv.estimate, iv.fit_estimate; atol = 1e-10, rtol = 1e-10) ||
            throw(ArgumentError("formed interval estimate differs from fit estimate"))
        Gfit = iv.fit_genetic_covariance; rgfit = iv.fit_genetic_correlation
        fit_rho = Gfit[1, 2] / sqrt(Gfit[1, 1] * Gfit[2, 2])
        isapprox(fit_rho, iv.fit_estimate; atol = 1e-8, rtol = 1e-8) &&
            isapprox(rgfit[1, 2], iv.fit_estimate; atol = 1e-8, rtol = 1e-8) ||
            throw(ArgumentError("formed interval fit estimate does not match its covariance evidence"))
        evidence_fit = (genetic_covariance = Gfit, residual_covariance = iv.fit_residual_covariance,
                        genetic_correlation = rgfit, residual_correlation = iv.fit_residual_correlation,
                        loglik = iv.fit_loglik, converged = true)
        fit_evidence_sha256(evidence_fit) == iv.fit_sha256 ||
            throw(ArgumentError("formed interval fit evidence checksum mismatch"))
    end
    N = length(records)
    F = count(r -> r.status in (:formed, :not_interpretable, :interval_failed) &&
        hasproperty(r, :fit_payload) && r.fit_payload !== nothing, records)
    I = count(r -> r.status == :formed, records)
    C = count(r -> r.status == :formed && r.interval.lower <= truth_rg <= r.interval.upper, records)
    FoverN = F / N; IoverN = I / N; CoverN = C / N; CoverI = I == 0 ? missing : C / I
    return (N = N, F = F, I = I, C = C, F_over_N = FoverN, I_over_N = IoverN,
            C_over_N = CoverN, C_over_I = CoverI,
            interpretability_floor = 44, interpretability_floor_met = I >= 44,
            config_sha256 = validated.config_sha256,
            source_sha256 = validated.source_sha256,
            seed_inventory_sha256 = validated.seed_inventory_sha256,
            input_sha256_by_seed = Dict(r.seed => get(r.provenance, :input_sha256, nothing) for r in records),
            # This candidate harness has no admitted protocol/source qualification.
            claim_eligible = false)
end

end # module
