# Scratch-only #496 paired diagnostic. Does not edit package source or CI.
using SHA, TOML

const PINNED_VERSION = v"1.13.3"
const PINNED_PROJECT = "8797dab5ac93c3c03e29c6fa3924056c173873d40356e8be86a7367344cdd9dc"
const PINNED_MANIFEST = "272ce679b561dedde1d733b783905cc6201cd9ed08b99acc1f87082e5454597b"
const EXECUTION_LIMIT_S = 600.0


function filehash(path)
    return bytes2hex(open(sha256, path))
end

function sourcehash(root)
    src = joinpath(root, "src")
    paths = sort!([relpath(joinpath(dir, f), root) for (dir, _, files) in walkdir(src) for f in files])
    io = IOBuffer()
    for path in paths
        # Normalize separator for a portable inventory identity, but not file bytes.
        write(io, replace(path, '\\' => '/'), UInt8(0))
        write(io, read(joinpath(root, path)))
        write(io, UInt8(0))
    end
    return bytes2hex(sha256(take!(io)))
end

if length(ARGS)==2 && ARGS[1]=="--worker"
    # Imports occur only in the child, after --project has selected the source.
    @eval using HSquared, Random, SparseArrays, LinearAlgebra
    @eval begin
        function _diag_poisson(rng, λ)
            L = exp(-λ); k = 0; p = 1.0
            while true
                p *= rand(rng)
                p <= L && return k
                k += 1
            end
        end
        function _diag_fixture(q::Int, n::Int; seed::Int, nfounders::Int=30)
            rng = MersenneTwister(seed)
            sire = fill("0", q); dam = fill("0", q)
            for i in (nfounders + 1):q
                a = rand(rng, 1:(i - 1)); b = rand(rng, 1:(i - 1))
                while b == a
                    b = rand(rng, 1:(i - 1))
                end
                sire[i] = string(a); dam[i] = string(b)
            end
            ped = HSquared.normalize_pedigree(string.(1:q), sire, dam)
            Ainv = HSquared.pedigree_inverse(ped)
            rec = vcat(collect(1:q), rand(rng, 1:q, n-q))
            Z = sparse(1:n, rec, 1.0, n, q)
            X = ones(n, 1)
            u = 0.6 .* randn(rng, q)
            η = 0.2 .+ Z * u
            ybin = Float64[rand(rng) < 1 / (1 + exp(-e)) for e in η]
            ypois = Float64[_diag_poisson(rng, exp(e)) for e in η]
            return (; Ainv, Z, X, ybin, ypois)
        end
    end
end

function worker(outpath)
    VERSION == PINNED_VERSION || error("expected Julia 1.13.3")
    root = dirname(Base.active_project())
    filehash(joinpath(root,"Project.toml")) == PINNED_PROJECT || error("project hash mismatch")
    filehash(joinpath(root,"Manifest.toml")) == PINNED_MANIFEST || error("manifest hash mismatch")
    LinearAlgebra.BLAS.get_num_threads() == 1 || error("BLAS must use one thread")
    Threads.nthreads() == 2 || error("Julia must use two threads")
    small = _diag_fixture(300, 300; seed=4211)
    fx = _diag_fixture(2000, 2000; seed=4210)
    fam = HSquared.BernoulliResponse()
    # Match the original test's order: small warm-up, public q=2000 call, timed fit.
    HSquared.variational_marginal_loglik(small.ybin,small.X,small.Z,small.Ainv,0.4,fam)
    HSquared._variational_marginal_loglik_sparse(small.ybin,small.X,small.Z,small.Ainv,0.4,fam;dense_covariance=false)
    pub = @timed HSquared.variational_marginal_loglik(fx.ybin,fx.X,fx.Z,fx.Ainv,0.4,fam)
    fit = @timed HSquared._variational_marginal_loglik_sparse(fx.ybin,fx.X,fx.Z,fx.Ainv,0.4,fam;dense_covariance=false)
    # Audit a unit-weight Hessian proxy only, outside the timed run. It is not the initial Hessian.
    Zt = sparse(transpose(fx.Z)); H = Zt * fx.Z + fx.Ainv / 0.4
    fac = cholesky(Symmetric(H)); sel = HSquared._va_selinv(fac)
    function index(j,k)
        a,b = minmax(sel.iperm[j],sel.iperm[k])
        return a==b ? sel.colptr[a] : HSquared._csc_rowidx(sel.colptr,sel.rowval,a,b)
    end
    rows = rowvals(Zt); vals = nonzeros(Zt)
    missing_rows = sum(any(!iszero(vals[a]) && !iszero(vals[b]) && index(rows[a],rows[b]) == -1
        for a in nzrange(Zt,i), b in nzrange(Zt,i)) for i in 1:size(Zt,2))
    ar = rowvals(fx.Ainv); av = nonzeros(fx.Ainv)
    missing_cols = sum(any(!iszero(av[k]) && index(ar[k],j) == -1
        for k in nzrange(fx.Ainv,j)) for j in 1:size(fx.Ainv,2))
    parts = (fx.ybin, vec(fx.X), fx.Z.colptr, rowvals(fx.Z), nonzeros(fx.Z),
             fx.Ainv.colptr, rowvals(fx.Ainv), nonzeros(fx.Ainv))
    fixturehash = bytes2hex(sha256(join((join(string.(x), ",") for x in parts), "|")))
    data = Dict(
        "source_tree_sha256"=>sourcehash(root), "project_sha256"=>filehash(joinpath(root,"Project.toml")),
        "manifest_sha256"=>filehash(joinpath(root,"Manifest.toml")), "fixture_sha256"=>fixturehash,
        "julia_version"=>string(VERSION), "machine"=>string(Sys.MACHINE),
        "kernel"=>string(Sys.KERNEL), "cpu_name"=>string(Sys.CPU_NAME),
        "cpu_threads"=>Sys.CPU_THREADS, "julia_threads"=>Threads.nthreads(),
        "blas_threads"=>LinearAlgebra.BLAS.get_num_threads(), "blas_vendor"=>string(LinearAlgebra.BLAS.vendor()),
        "fit_time_s"=>fit.time, "fit_gc_s"=>fit.gctime, "fit_alloc_bytes"=>fit.bytes,
        "fit_compile_s"=>(hasproperty(fit,:compile_time) ? fit.compile_time : -1.0),
        "public_time_s"=>pub.time, "public_gc_s"=>pub.gctime, "public_alloc_bytes"=>pub.bytes,
        "public_S_rows"=>size(pub.value.S,1), "public_S_cols"=>size(pub.value.S,2),
        "runner_image"=>get(ENV,"ImageOS","unknown"), "runner_image_version"=>get(ENV,"ImageVersion","unknown"),
        "elbo"=>fit.value.elbo, "converged"=>fit.value.converged,
        "public_converged"=>pub.value.converged, "public_elbo"=>pub.value.elbo,
        "returned_S_nothing"=>(fit.value.S === nothing),
        "unit_weight_proxy_missing_rows"=>missing_rows, "unit_weight_proxy_missing_precision_cols"=>missing_cols,
        "fallback_scope"=>"unit-weight structural proxy only; actual timed fallback calls not instrumented")
    open(outpath,"w") do io; TOML.print(io,data; sorted=true); end
end

function terminate_child(proc)
    process_running(proc) || return
    if Sys.iswindows()
        # /T requests termination of the subprocess tree as well as the worker.
        pid = getpid(proc)
        try
            run(pipeline(ignorestatus(`taskkill /PID $pid /T /F`), stdout=devnull, stderr=devnull))
        catch caught
            println(stderr, "taskkill failed: ", sprint(showerror, caught))
        end
    end
    if process_running(proc)
        try
            Sys.iswindows() ? kill(proc) : kill(proc, Base.SIGKILL)
        catch caught
            println(stderr, "worker termination failed: ", sprint(showerror, caught))
        end
    end
    wait(proc)
    process_running(proc) && error("worker remained alive after termination")
end

function run_with_deadline(command, outpath, errpath, deadline)
    proc = nothing
    open(outpath,"w") do stdout_io
        open(errpath,"w") do stderr_io
            try
                proc = run(pipeline(command, stdout=stdout_io, stderr=stderr_io); wait=false)
                while process_running(proc)
                    if time_ns() >= deadline
                        terminate_child(proc)
                        error("diagnostic deadline exceeded; worker terminated")
                    end
                    sleep(0.2)
                end
                wait(proc)
                success(proc) || error("worker failed; inspect retained stdout/stderr")
            finally
                if proc !== nothing && process_running(proc)
                    terminate_child(proc)
                end
            end
        end
    end
end

function main()
    length(ARGS) == 5 || error("usage: julia paired.jl BASELINE_ROOT CANDIDATE_ROOT BASELINE_SRC_SHA256 CANDIDATE_SRC_SHA256 OUTPUT_DIR")
    VERSION == PINNED_VERSION || error("expected Julia 1.13.3")
    baseline, candidate = abspath.(ARGS[1:2])
    expected_src = ARGS[3:4]
    output = abspath(ARGS[5])
    isdir(output) && !isempty(readdir(output)) && error("output directory must be empty")
    mkpath(output)
    for root in (baseline,candidate), file in ("Project.toml","Manifest.toml")
        isfile(joinpath(root,file)) || error("missing $(joinpath(root,file))")
    end
    for root in (baseline,candidate)
        filehash(joinpath(root,"Manifest.toml")) == PINNED_MANIFEST || error("manifest hash mismatch")
        filehash(joinpath(root,"Project.toml")) == PINNED_PROJECT || error("project hash mismatch")
    end
    all(sourcehash(root) == expected for (root,expected) in zip((baseline,candidate),expected_src)) || error("source-tree hash mismatch")
    labels = ("baseline", "candidate", "candidate", "baseline")
    roots = (baseline, candidate, candidate, baseline)
    rows = []
    deadline = time_ns() + UInt64(round(Int, EXECUTION_LIMIT_S * 1e9))
    for i in eachindex(labels)
        outfile=joinpath(output,"run-$i.toml")
        command=`$(Base.julia_cmd()) --startup-file=no --project=$(roots[i]) $(@__FILE__) --worker $outfile`
        env=merge(ENV, Dict("OPENBLAS_NUM_THREADS"=>"1", "JULIA_NUM_THREADS"=>"2",
            "JULIA_NUM_PRECOMPILE_TASKS"=>"1", "JULIA_PKG_PRECOMPILE_AUTO"=>"0"))
        open(joinpath(output,"run-$i.started"),"w") do io
            println(io, labels[i])
        end
        run_with_deadline(setenv(command,env),joinpath(output,"run-$i.stdout.log"),
                          joinpath(output,"run-$i.stderr.log"),deadline)
        row=TOML.parsefile(outfile); row["label"]=labels[i]; row["order"]=i
        push!(rows,row)
    end
    length(unique(r["fixture_sha256"] for r in rows)) == 1 || error("fixture mismatch")
    all(r["julia_version"] == string(PINNED_VERSION) for r in rows) || error("Julia versions differ")
    for root in (baseline,candidate)
        filehash(joinpath(root,"Manifest.toml")) == PINNED_MANIFEST || error("manifest changed during diagnostic")
        filehash(joinpath(root,"Project.toml")) == PINNED_PROJECT || error("project changed during diagnostic")
    end
    all(r["converged"] && r["public_converged"] && r["returned_S_nothing"] && r["public_S_rows"] == 2000 && r["public_S_cols"] == 2000 for r in rows) || error("fit or output-shape failure")
    all(isapprox(r["elbo"],r["public_elbo"]; atol=1e-10,rtol=0) for r in rows) || error("public/fit objective mismatch")
    all(isapprox(r["elbo"],rows[1]["elbo"]; atol=1e-10,rtol=0) for r in rows) || error("baseline/candidate objective mismatch")
    guard_ok = all(r["fit_time_s"] < 10.0 && r["fit_alloc_bytes"] < 100 * 2000^2 &&
                   r["public_alloc_bytes"] < 150 * 2000^2 for r in rows)
    result = Dict("runs"=>rows, "experiment_class"=>"exploratory: two runs per source",
                  "all_repeated_original_time_and_allocation_limits_pass"=>guard_ok)
    open(joinpath(output,"summary.toml"),"w") do io
        TOML.print(io,result; sorted=true)
    end
    println("exploratory paired diagnostic; see ", joinpath(output,"summary.toml"))
    guard_ok || error("original time or allocation limit failed; results retained")
end

if length(ARGS)==2 && ARGS[1]=="--worker"
    worker(ARGS[2])
elseif length(ARGS)==2 && ARGS[1]=="--selftest-timeout"
    out = abspath(ARGS[2]); mkpath(out)
    command = `$(Base.julia_cmd()) --startup-file=no -e $("sleep(60)")`
    caught = try
        run_with_deadline(command, joinpath(out,"timeout.stdout.log"),
            joinpath(out,"timeout.stderr.log"), time_ns()+UInt64(1_000_000_000))
        nothing
    catch err
        err
    end
    caught isa ErrorException && occursin("deadline exceeded", sprint(showerror,caught)) || error("timeout self-test failed")
    println("timeout self-test: child terminated and reaped")
else
    main()
end
