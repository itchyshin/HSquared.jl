#!/usr/bin/env julia
# Scratch diagnostic. Never include repository tests or supply optimizer initial values.
using LinearAlgebra, Random, SHA, Serialization, TOML, Dates, Sockets

const EXPECTED_TREE = "d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a"
const EXPECTED_FIXTURE = "e621d60892c9ec9ceab6a1b06d051495d2aa1b9d6c70346023129a993b2d9085"
const SEED = 20260929
const START_CAP = 10_000
const ORACLE_ATOL = 1e-8
const SOLVE_RTOL = 1e-9
const SOLVE_ATOL = 1e-9
const AGREEMENT = 2e-3
const PRED_ATOL = 1e-5
const INTERIOR_SCREEN = 0.01
const FLOOR = 1e-4
const DEFAULT_REPO = "/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl"

sha(path) = bytes2hex(SHA.sha256(read(path)))

# Git identity is supplemental provenance. Source-only snapshots are valid when
# the mandatory byte fingerprints match; preserve missing metadata explicitly.
function git_metadata(repo)
    metadata = Dict{String, Any}()
    errors = Dict{String, String}()
    commands = (("git_head", `git -C $repo rev-parse HEAD`),
                ("git_branch", `git -C $repo branch --show-current`),
                ("git_status_porcelain", `git -C $repo status --porcelain`))
    for (name, command) in commands
        try
            metadata[name] = readchomp(pipeline(command; stderr = devnull))
        catch err
            metadata[name] = "unavailable"
            errors[name] = sprint(showerror, err)
        end
    end
    metadata["git_metadata_status"] = isempty(errors) ? "available" :
        length(errors) == length(commands) ? "unavailable" : "partial"
    metadata["git_metadata_errors"] = errors
    metadata
end

function tree_sha(root)
    paths = sort!([joinpath(d, f) for (d, _, fs) in walkdir(root) for f in fs])
    io = IOBuffer()
    for path in paths
        write(io, replace(relpath(path, root), '\\' => '/'), UInt8(0))
        write(io, read(path), UInt8(0))
    end
    bytes2hex(SHA.sha256(take!(io)))
end

# Exact random generator from frozen test/test_multivariate_fa_multistart.jl:181-203.
# The generating covariance is used for oracle checks, never as a fit start.
function fixture()
    rng = MersenneTwister(20260929)
    n, records, t = 40, 5, 4
    ids = collect(1:n)
    ped = HSquared.normalize_pedigree(ids, zeros(Int, n), zeros(Int, n))
    Ainv = HSquared.pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    loadings = reshape([1.4, 0.9, 0.7, 0.5], t, 1)
    uniqueness = [0.8, 0.7, 0.9, 0.8]
    G = Matrix(HSquared.factor_analytic_covariance(loadings, uniqueness))
    R = [1.0 0.12 0.0 0.0; 0.12 0.9 0.08 0.0; 0.0 0.08 0.85 0.07; 0.0 0.0 0.07 0.8]
    U = cholesky(Symmetric(A)).L * randn(rng, n, t) * transpose(cholesky(Symmetric(G)).L)
    LR = cholesky(Symmetric(R)).L
    N = n * records
    Y = Matrix{Float64}(undef, N, t)
    Z = zeros(N, n)
    row = 0
    for animal in 1:n, _ in 1:records
        row += 1
        Z[row, animal] = 1.0
        Y[row, :] .= [0.3, -0.4, 0.5, 1.0] .+ U[animal, :] .+
                     (transpose(randn(rng, t)) * transpose(LR))[:]
    end
    X = ones(N, 1)
    (; Y, X, Z, Ainv, A, G, R, loadings, uniqueness, ids,
       traits = ["t1", "t2", "t3", "t4"], seed = SEED)
end

function predeclared_cases()
    eye = Matrix{Float64}(I, 4, 4)
    scales = [2.0, 0.5, 1.5, 0.8]
    [(name = "baseline", M = eye, permutation = collect(1:4)),
     (name = "units_D1", M = Matrix(Diagonal(scales)), permutation = collect(1:4)),
     (name = "units_inverse_D1", M = Matrix(Diagonal(1 ./ scales)), permutation = collect(1:4)),
     (name = "order_3142", M = eye[:, [3, 1, 4, 2]], permutation = [3, 1, 4, 2]),
     (name = "order_4321", M = eye[:, [4, 3, 2, 1]], permutation = [4, 3, 2, 1])]
end

# Deterministic native-endian Float64 bytes, column-major arrays, named dimensions.
function array_hash(a)
    io = IOBuffer()
    write(io, string(size(a)), UInt8(0))
    write(io, reinterpret(UInt8, vec(Matrix{Float64}(a))))
    bytes2hex(SHA.sha256(take!(io)))
end

function fixed_eval(d, Y, G, R)
    n, t = size(Y); p = size(d.X, 2); q = size(d.Z, 2)
    y, Xf, Zf, indiv, N = HSquared._mv_observed(Y, d.X, d.Z, n, t, q, p)
    ll = HSquared._multivariate_reml_loglik(Y, d.X, d.Z, d.Ainv, G, R)
    beta, ebv = HSquared._mv_gls_blup(y, Xf, Zf, d.A, indiv, N, G, R, t, p, q)
    (; loglik = ll, beta, ebv)
end

function undo_fit(f, M)
    Mi = inv(M)
    (; G = transpose(Mi) * f.genetic_covariance * Mi,
       R = transpose(Mi) * f.residual_covariance * Mi,
       loadings = transpose(Mi) * f.genetic_loadings,
       psi = diag(transpose(Mi) * Diagonal(f.genetic_uniqueness) * Mi),
       beta = f.beta * Mi, ebv = f.breeding_values.values * Mi)
end

clean(x) = replace(string(x), '\t' => ' ', '\n' => ' ', '\r' => ' ')
function tsv(io, xs...)
    println(io, join(clean.(xs), '\t')); flush(io)
end
function require_check!(failures, condition, message)
    condition || push!(failures, message)
end
finite_fit(f) = isfinite(f.loglik) && all(a -> all(isfinite, a),
    (f.genetic_covariance, f.residual_covariance, f.genetic_loadings,
     f.genetic_uniqueness, f.beta, f.breeding_values.values))

function validate_fit(d, c, f, mapped)
    failures = String[]
    require_check!(failures, finite_fit(f), "nonfinite_return")
    require_check!(failures, f.traits == d.traits[c.permutation], "fit_trait_labels")
    require_check!(failures, f.breeding_values.traits == d.traits[c.permutation], "EBV_trait_labels")
    require_check!(failures, f.breeding_values.ids == d.ids, "EBV_ID_order")
    require_check!(failures, f.genetic_structure == :factor_analytic && f.genetic_rank == 1,
                   "FA_structure_rank")
    require_check!(failures, isapprox(f.genetic_covariance,
        f.genetic_loadings * transpose(f.genetic_loadings) + Diagonal(f.genetic_uniqueness);
        rtol = 1e-10, atol = 1e-10), "G_reconstruction")
    require_check!(failures, isapprox(mapped.G,
        mapped.loadings * transpose(mapped.loadings) + Diagonal(mapped.psi);
        rtol = 1e-10, atol = 1e-10), "mapped_G_reconstruction")
    require_check!(failures, all(>=(FLOOR), f.genetic_uniqueness), "returned_psi_below_floor")
    direct = fixed_eval(d, d.Y * c.M, f.genetic_covariance, f.residual_covariance)
    require_check!(failures, abs(f.loglik - direct.loglik) <= ORACLE_ATOL, "returned_loglik_reevaluation")
    require_check!(failures, isapprox(f.beta, direct.beta; rtol = SOLVE_RTOL, atol = SOLVE_ATOL),
                   "returned_beta_reevaluation")
    require_check!(failures, isapprox(f.breeding_values.values, direct.ebv;
        rtol = SOLVE_RTOL, atol = SOLVE_ATOL), "returned_EBV_reevaluation")
    dg = f.fa_start_diagnostics
    require_check!(failures, dg.strategy == :default_and_balanced && dg.starts_attempted == 2 &&
        length(dg.starts) == 2 && [s.name for s in dg.starts] == [:default, :balanced],
        "ordinary_two_start_status")
    valid = filter(s -> s.valid && s.loglik !== nothing && isfinite(s.loglik), collect(dg.starts))
    converged = filter(s -> s.converged, valid)
    eligible = isempty(converged) ? valid : converged
    if isempty(eligible)
        push!(failures, "no_valid_reported_start")
    else
        chosen = eligible[argmax([s.loglik for s in eligible])]
        require_check!(failures, chosen.name == dg.selected_start && chosen.converged == f.converged &&
            chosen.iterations == f.iterations && abs(chosen.loglik - f.loglik) <= ORACLE_ATOL,
            "selected_start_status")
        better = any(s -> !s.converged && s.loglik > chosen.loglik, valid)
        require_check!(failures, dg.better_nonconverged_start == better, "better_nonconverged_status")
        expected_range = length(valid) > 1 ? maximum(s.loglik for s in valid) - minimum(s.loglik for s in valid) : nothing
        require_check!(failures, expected_range === nothing ? dg.objective_range === nothing :
            isapprox(dg.objective_range, expected_range; atol = 1e-8, rtol = 1e-10), "objective_range_status")
    end
    distance = minimum(f.genetic_uniqueness .- FLOOR)
    require_check!(failures, isapprox(dg.minimum_uniqueness, minimum(f.genetic_uniqueness);
        atol = 1e-12, rtol = 1e-12) && isapprox(dg.uniqueness_floor_distance, distance;
        atol = 1e-12, rtol = 1e-12), "uniqueness_status")
    require_check!(failures, dg.near_uniqueness_floor == (distance <= 0.01 * FLOOR), "near_floor_status")
    (; failures, direct)
end

# Test the exact model identity on all five maps at truth and every returned pair.
function oracle_checks(d, pair_name, G, R, cases, io)
    failures = String[]; rows = Any[]
    local original
    try
        original = fixed_eval(d, d.Y, G, R)
    catch err
        message = sprint(showerror, err, catch_backtrace())
        for c in cases
            push!(failures, "oracle_original_exception_$(pair_name)_$(c.name)")
            push!(rows, (; pair_name, map = c.name, ok = false, exception = message))
            tsv(io, pair_name, c.name, false, "NA", "NA", "NA", "NA", message)
        end
        return (; failures, rows)
    end
    for c in cases
        begin_time = time_ns()
        try
            transformed = fixed_eval(d, d.Y * c.M, transpose(c.M) * G * c.M,
                                     transpose(c.M) * R * c.M)
            shift = (size(d.Y, 1) - rank(d.X)) * logabsdet(c.M)[1]
            ll_error = abs(transformed.loglik - (original.loglik - shift))
            beta_error = norm(transformed.beta * inv(c.M) - original.beta)
            ebv_error = norm(transformed.ebv * inv(c.M) - original.ebv)
            ok = isfinite(ll_error) && ll_error <= ORACLE_ATOL &&
                isapprox(transformed.beta * inv(c.M), original.beta; rtol = SOLVE_RTOL, atol = SOLVE_ATOL) &&
                isapprox(transformed.ebv * inv(c.M), original.ebv; rtol = SOLVE_RTOL, atol = SOLVE_ATOL)
            ok || push!(failures, "oracle_$(pair_name)_$(c.name)")
            row = (; pair_name, map = c.name, ok, ll_error, beta_error, ebv_error,
                     seconds = (time_ns() - begin_time) / 1e9, exception = "")
            push!(rows, (; row..., original, transformed))
            tsv(io, pair_name, c.name, ok, ll_error, beta_error, ebv_error, row.seconds, "")
        catch err
            message = sprint(showerror, err, catch_backtrace())
            push!(failures, "oracle_exception_$(pair_name)_$(c.name)")
            push!(rows, (; pair_name, map = c.name, ok = false, exception = message))
            tsv(io, pair_name, c.name, false, "NA", "NA", "NA", (time_ns() - begin_time) / 1e9, message)
        end
    end
    (; failures, rows)
end

function comparison(d, baseline, current, c)
    b, a = baseline.mapped, current.mapped
    Si = Diagonal(1 ./ sqrt.(diag(d.G + d.R)))
    relative(A, B) = norm(Si * (A - B) * Si) / max(norm(Si * B * Si), eps(Float64))
    corrected_ll = current.fit.loglik + (size(d.Y, 1) - rank(d.X)) * logabsdet(c.M)[1]
    sign = dot(vec(a.loadings), vec(b.loadings)) < 0 ? -1.0 : 1.0
    g_error = relative(a.G, b.G); r_error = relative(a.R, b.R)
    psi_error = norm(Si * Diagonal(a.psi - b.psi) * Si) / max(norm(Si * Diagonal(b.psi) * Si), eps(Float64))
    loading_error = norm(Si * (sign .* a.loadings - b.loadings)) / max(norm(Si * b.loadings), eps(Float64))
    ll_error = abs(corrected_ll - baseline.fit.loglik)
    beta_ok = isapprox(a.beta, b.beta; rtol = AGREEMENT, atol = PRED_ATOL)
    ebv_ok = isapprox(a.ebv, b.ebv; rtol = AGREEMENT, atol = PRED_ATOL)
    agreement = ll_error <= AGREEMENT && g_error <= AGREEMENT && r_error <= AGREEMENT && beta_ok && ebv_ok
    # Apply the interior screen in BOTH input and reverse-mapped units. Include
    # the baseline point mapped to this case, exposing different feasible sets.
    baseline_forward_psi = diag(transpose(c.M) * Diagonal(b.psi) * c.M)
    min_psi_screen = minimum(vcat(b.psi, a.psi, current.fit.genetic_uniqueness, baseline_forward_psi))
    interior = min_psi_screen > INTERIOR_SCREEN
    start_status_differs = [(s.valid, s.converged) for s in current.fit.fa_start_diagnostics.starts] !=
                          [(s.valid, s.converged) for s in baseline.fit.fa_start_diagnostics.starts]
    status_differs = current.fit.converged != baseline.fit.converged || start_status_differs
    sensitivity = !agreement || status_differs || !current.fit.converged || !baseline.fit.converged
    correctness = !isempty(current.failures) || !isempty(baseline.failures)
    category = correctness ? "correctness_failure" : !interior ? "floor_constrained" :
        sensitivity ? "optimizer_sensitivity" : "interior_agreement"
    (; category, corrected_ll, ll_error, g_error, r_error, psi_error, loading_error,
       loading_sign = sign, beta_ok, ebv_ok, beta_error = norm(a.beta - b.beta),
       ebv_error = norm(a.ebv - b.ebv), agreement, status_differs, start_status_differs, sensitivity, interior,
       min_psi_screen, mapped_floor_distance = minimum(a.psi .- FLOOR),
       baseline_forward_floor_distance = minimum(baseline_forward_psi .- FLOOR))
end

function preflight()
    get(ENV, "HSQ_RUN_ORDINARY_UNIT_ORDER", "") == "YES" ||
        error("Opt-in required: HSQ_RUN_ORDINARY_UNIT_ORDER=YES; no fit was run")
    length(ARGS) == 2 || error("Usage: script.jl FROZEN_REPO NEW_OUTPUT_DIRECTORY")
    repo, output = abspath.(ARGS)
    ispath(output) && error("Refusing existing output path: $output")
    abspath(dirname(Base.active_project())) == repo || error("Launch with --project=FROZEN_REPO")
    Threads.nthreads() <= 4 || error("Use JULIA_NUM_THREADS<=4")
    LinearAlgebra.BLAS.set_num_threads(1)
    source_hash = tree_sha(joinpath(repo, "src"))
    source_hash == EXPECTED_TREE || error("Frozen source-tree hash mismatch: $source_hash")
    fixture_path = joinpath(repo, "test", "test_multivariate_fa_multistart.jl")
    sha(fixture_path) == EXPECTED_FIXTURE || error("Frozen fixture-file hash mismatch")
    (; repo, output, source_hash, fixture_path)
end

function run_diagnostic(config)
    repo, output, source_hash, fixture_path = config.repo, config.output, config.source_hash, config.fixture_path
    realpath(pathof(HSquared)) == realpath(joinpath(repo, "src", "HSquared.jl")) ||
        error("HSquared loaded from a different candidate")
    HSquared.FA_UNIQUENESS_FLOOR == FLOOR || error("Frozen uniqueness floor mismatch")
    mkpath(dirname(output)); mkdir(output) # Exclusive ownership; no overwrite or resume.
    cases = predeclared_cases()
    manifest = Dict{String, Any}(
        "created_utc" => string(Dates.now(Dates.UTC)), "repo" => repo,
        "script_sha256" => sha(@__FILE__), "source_tree_sha256" => source_hash,
        "fixture_file_sha256" => sha(fixture_path), "seed" => SEED,
        "julia_version" => string(VERSION), "julia_executable" => joinpath(Sys.BINDIR, Base.julia_exename()),
        "julia_threads" => Threads.nthreads(), "blas_threads" => BLAS.get_num_threads(),
        "blas_config" => sprint(show, BLAS.get_config()), "host" => gethostname(),
        "word_size" => Sys.WORD_SIZE, "endian_bom" => string(Base.ENDIAN_BOM),
        "expected_fit_denominator" => 5, "starts_per_fit" => 2, "iterations_per_start" => START_CAP,
        "initial_keyword_supplied" => false, "runtime_estimate_seconds" => 3600,
        "estimate_basis" => "Parent's bounded estimate from same-fixture evidence; launch owner must confirm it before execution",
        "oracle_atol" => ORACLE_ATOL, "solve_rtol" => SOLVE_RTOL, "solve_atol" => SOLVE_ATOL,
        "comparison_targets" => Dict("loglik_atol" => AGREEMENT, "fixed_metric_covariance_relative" => AGREEMENT,
            "prediction_rtol" => AGREEMENT, "prediction_atol" => PRED_ATOL, "interior_screen" => INTERIOR_SCREEN),
        "scope" => "diagnostic completion only; not A2 acceptance, population recovery, intervals, or covered promotion",
        "cases" => [Dict("name" => c.name, "permutation" => c.permutation,
                          "map_rows" => [collect(c.M[i, :]) for i in 1:4]) for c in cases])
    merge!(manifest, git_metadata(repo))
    manifest["source_files"] = Dict(replace(relpath(joinpath(dir, f), repo), '\\' => '/') => sha(joinpath(dir, f))
        for (dir, _, fs) in walkdir(joinpath(repo, "src")) for f in fs)
    for name in ("Project.toml", "Manifest.toml")
        isfile(joinpath(repo, name)) && (manifest[name * "_sha256"] = sha(joinpath(repo, name)))
    end
    readme = joinpath(@__DIR__, "README.md")
    isfile(readme) && (manifest["readme_sha256"] = sha(readme))
    generator_lines = split(read(fixture_path, String), '\n')[181:203]
    manifest["generator_span_sha256"] = bytes2hex(SHA.sha256(join(generator_lines, "\n") * "\n"))
    manifest["generator_span"] = "test/test_multivariate_fa_multistart.jl:181-203"
    open(joinpath(output, "manifest.toml"), "w") do io; TOML.print(io, manifest); flush(io); end
    d = fixture()
    serialize(joinpath(output, "fixture.jls"), d)
    manifest["data_array_sha256"] = Dict(string(k) => array_hash(getproperty(d, k))
        for k in (:Y, :X, :Z, :Ainv, :G, :R, :loadings))
    manifest["data_array_sha256"]["uniqueness"] = array_hash(reshape(d.uniqueness, :, 1))
    manifest["data_array_sha256"]["ids"] = bytes2hex(SHA.sha256(join(d.ids, ",")))
    manifest["data_array_sha256"]["traits"] = bytes2hex(SHA.sha256(join(d.traits, "\0")))
    manifest["fixture_artifact_sha256"] = sha(joinpath(output, "fixture.jls"))
    manifest["data_hash_schema"] = "array dimensions/NUL/native-endian Float64 column-major bytes; IDs comma-separated; labels NUL-separated"
    manifest["fixed_trait_metric"] = sqrt.(diag(d.G + d.R))
    open(joinpath(output, "manifest.toml"), "w") do io; TOML.print(io, manifest); flush(io); end
    results = Dict{String, Any}(); global_failures = String[]
    overall_start = time_ns()
    oracle_io = open(joinpath(output, "oracles.tsv"), "w")
    fit_io = open(joinpath(output, "fits.tsv"), "w")
    start_io = open(joinpath(output, "starts.tsv"), "w")
    compare_io = open(joinpath(output, "comparisons.tsv"), "w")
    try
        tsv(oracle_io, "covariance_pair", "map", "passed", "loglik_abs_error", "beta_norm_error", "EBV_norm_error", "seconds", "exception")
        tsv(fit_io, "case", "fit_returned", "finite", "converged", "iterations", "loglik", "selected_start", "objective_range", "better_nonconverged_start", "minimum_uniqueness", "floor_distance", "near_floor", "fit_seconds", "case_seconds", "correctness_failures", "artifact_sha256", "exception")
        tsv(start_io, "case", "start", "available", "valid", "converged", "iterations", "loglik", "minimum_uniqueness", "floor_distance", "note")
        tsv(compare_io, "case", "category", "corrected_loglik", "loglik_abs_difference", "G_fixed_metric_relative", "R_fixed_metric_relative", "psi_fixed_metric_relative", "loading_aligned_relative", "loading_sign", "beta_agrees", "EBV_agrees", "beta_norm_difference", "EBV_norm_difference", "agreement_targets_met", "status_differs", "optimizer_sensitivity", "interior_screen", "minimum_screen_uniqueness", "mapped_floor_distance", "baseline_forward_floor_distance")
        truth_oracle = oracle_checks(d, "generating_covariance", d.G, d.R, cases, oracle_io)
        append!(global_failures, truth_oracle.failures)
        serialize(joinpath(output, "generating_oracles.jls"), truth_oracle)
        for c in cases
            case_start = time_ns(); fit_start = time_ns(); fit_seconds = NaN
            raw_fit = nothing; mapped = nothing; current = nothing; message = ""
            failures = String[]
            append!(failures, truth_oracle.failures)
            try
                raw_fit = HSquared.fit_multivariate_reml(d.Y * c.M, d.X, d.Z, d.Ainv;
                    genetic_structure = :factor_analytic, rank = 1, iterations = START_CAP,
                    ids = d.ids, traits = d.traits[c.permutation])
                fit_seconds = (time_ns() - fit_start) / 1e9
                mapped = undo_fit(raw_fit, c.M)
                validation = validate_fit(d, c, raw_fit, mapped)
                append!(failures, validation.failures)
                oracles = oracle_checks(d, c.name, mapped.G, mapped.R, cases, oracle_io)
                append!(failures, oracles.failures)
                current = (; fit = raw_fit, mapped, validation, oracles, failures, fit_seconds)
            catch err
                fit_seconds = isnan(fit_seconds) ? (time_ns() - fit_start) / 1e9 : fit_seconds
                message = sprint(showerror, err, catch_backtrace())
                push!(failures, "named_case_exception")
                current = (; fit = raw_fit, mapped, failures, fit_seconds, exception = message)
            end
            append!(global_failures, ["$(c.name):$x" for x in failures])
            # Each named call survives, including exceptions and partial API returns.
            results[c.name] = current
            artifact = joinpath(output, c.name * ".jls")
            serialize(artifact, (; case = c, result = current, input_Y = d.Y * c.M))
            if raw_fit !== nothing
                dg = raw_fit.fa_start_diagnostics
                for s in dg.starts
                    tsv(start_io, c.name, s.name, true, s.valid, s.converged, s.iterations,
                        s.loglik, s.minimum_uniqueness, s.uniqueness_floor_distance, "reported_by_frozen_API")
                end
                tsv(fit_io, c.name, true, finite_fit(raw_fit), raw_fit.converged, raw_fit.iterations,
                    raw_fit.loglik, dg.selected_start, dg.objective_range, dg.better_nonconverged_start,
                    minimum(raw_fit.genetic_uniqueness), minimum(raw_fit.genetic_uniqueness .- FLOOR),
                    dg.near_uniqueness_floor, fit_seconds, (time_ns() - case_start) / 1e9,
                    join(failures, ";"), sha(artifact), message)
            else
                for name in ("default", "balanced")
                    tsv(start_io, c.name, name, false, "NA", "NA", "NA", "NA", "NA", "NA",
                        "API exception; inner attempt status unavailable; retained in denominator")
                end
                tsv(fit_io, c.name, false, false, "NA", "NA", "NA", "NA", "NA", "NA", "NA",
                    "NA", "NA", fit_seconds, (time_ns() - case_start) / 1e9, join(failures, ";"), sha(artifact), message)
            end
            baseline = get(results, "baseline", nothing)
            if raw_fit !== nothing && mapped !== nothing && baseline !== nothing && baseline.fit !== nothing && baseline.mapped !== nothing
                cmp = comparison(d, baseline, current, c)
                tsv(compare_io, c.name, cmp.category, cmp.corrected_ll, cmp.ll_error, cmp.g_error,
                    cmp.r_error, cmp.psi_error, cmp.loading_error, cmp.loading_sign, cmp.beta_ok,
                    cmp.ebv_ok, cmp.beta_error, cmp.ebv_error, cmp.agreement, cmp.status_differs,
                    cmp.sensitivity, cmp.interior, cmp.min_psi_screen, cmp.mapped_floor_distance,
                    cmp.baseline_forward_floor_distance)
                serialize(joinpath(output, c.name * "_comparison.jls"), cmp)
            else
                tsv(compare_io, c.name, "correctness_failure", fill("NA", 18)...)
            end
            println("Finished named case ", c.name, "; exceptions retained; seconds=", (time_ns() - case_start) / 1e9)
            flush(stdout)
        end
    finally
        close.([oracle_io, fit_io, start_io, compare_io])
    end
    source_after = tree_sha(joinpath(repo, "src"))
    source_after == source_hash || push!(global_failures, "source_changed_during_run")
    returned = count(c -> results[c.name].fit !== nothing, cases)
    finite = count(c -> results[c.name].fit !== nothing && finite_fit(results[c.name].fit), cases)
    summary = Dict("status" => "diagnostic_complete", "A2_complete" => false,
        "all_five_attempted" => length(results) == 5, "full_denominator" => 5,
        "fit_returns" => returned, "finite_returns" => finite,
        "correctness_failure_count" => length(global_failures), "correctness_failures" => global_failures,
        "source_tree_after_sha256" => source_after, "seconds" => (time_ns() - overall_start) / 1e9,
        "exit_code" => isempty(global_failures) && finite == 5 ? 0 : 2,
        "interpretation" => "Optimizer sensitivity and floor constraints are measured limitations, not a retrospective population pass bar; panel acceptance remains external")
    open(joinpath(output, "summary.toml"), "w") do io; TOML.print(io, summary); flush(io); end
    serialize(joinpath(output, "all_results.jls"), results)
    artifacts = Dict(f => sha(joinpath(output, f)) for f in readdir(output) if isfile(joinpath(output, f)))
    open(joinpath(output, "artifact_hashes.toml"), "w") do io; TOML.print(io, artifacts); flush(io); end
    println("diagnostic_complete; A2_complete=false; attempted=5/5; finite=", finite,
            "/5; correctness_failures=", length(global_failures)); flush(stdout)
    summary["exit_code"]
end

if abspath(PROGRAM_FILE) == @__FILE__
    config = preflight()
    # Import at top level after the opt-in and fingerprint guards. Calling the
    # runner afterward keeps newly loaded package methods in the current world.
    using HSquared
    exit(run_diagnostic(config))
end
