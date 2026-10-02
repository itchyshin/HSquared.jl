using Test
using HSquared

include(joinpath(@__DIR__, "..", "sim", "arc1", "reference.jl"))

module Arc1ReferenceFakeOptim
struct NelderMead end
struct Options
    iterations::Int
end
Options(; iterations) = Options(iterations)
const OBSERVED = Tuple{Vector{Float64},Vector{Float64}}[]
function optimize(f, params, ::NelderMead, _options)
    initial = Float64.(params)
    superior = copy(initial)
    superior[1] += 0.25
    f(superior)
    f(initial)
    push!(OBSERVED, (copy(superior), copy(initial)))
    error("controlled Optim exception after better then worse NM probes")
end
end

module Arc1ReferenceFakeEngine
using LinearAlgebra
const FA_UNIQUENESS_FLOOR = 1e-6
const Optim = Main.Arc1ReferenceFakeOptim
const FAIL_NEXT_UNIQUENESS_MAP = Ref(false)
function _fa_uniqueness_to_unconstrained(g)
    if FAIL_NEXT_UNIQUENESS_MAP[]
        FAIL_NEXT_UNIQUENESS_MAP[] = false
        error("controlled single K1 mapping failure")
    end
    log.(Float64.(g) .- FA_UNIQUENESS_FLOOR)
end
function _fa_uniqueness_from_unconstrained(eta)
    FA_UNIQUENESS_FLOOR .+ exp.(Float64.(eta))
end
function _cov_to_chol_params(M, t)
    L = cholesky(Symmetric(Matrix{Float64}(M))).L
    out = Float64[]
    for j in 1:t, i in j:t
        push!(out, i == j ? log(L[i, j]) : L[i, j])
    end
    out
end
function _chol_params_to_cov(params, t)
    L = zeros(t, t)
    idx = 1
    for j in 1:t, i in j:t
        L[i, j] = i == j ? exp(params[idx]) : params[idx]
        idx += 1
    end
    L * L'
end
function _arc1_fa_spectral_context(Y, X, B)
    (; status=:ok, context=(; n=size(Y, 1)))
end
function _arc1_fa_exact_objective_gradient(_ctx, params, rank)
    if rank == 0
        genetic = _fa_uniqueness_from_unconstrained(params[1:4])
    else
        loading = params[1:4]
        uniqueness = _fa_uniqueness_from_unconstrained(params[5:8])
        genetic = loading .^ 2 .+ uniqueness
    end
    loglik = sum(genetic)
    (; status=:ok, objective=-loglik / 100, raw_objective=-loglik,
       loglik, gradient=zeros(length(params)))
end
end

@testset "Arc1 expanded reference starts" begin
    @test length(ARC1_REFERENCE_K0_SPLITS) == 6
    @test ARC1_REFERENCE_K0_SPLITS == (0.05, 0.15, 0.3, 0.5, 0.7, 0.9)
    @test length(ARC1_REFERENCE_K1_AMPLITUDES) == 8
    signs = arc1_reference_sign_patterns()
    @test length(signs) == 8
    @test signs == [[1.0, 1.0, 1.0, 1.0], [1.0, 1.0, 1.0, -1.0],
                    [1.0, 1.0, -1.0, 1.0], [1.0, 1.0, -1.0, -1.0],
                    [1.0, -1.0, 1.0, 1.0], [1.0, -1.0, 1.0, -1.0],
                    [1.0, -1.0, -1.0, 1.0], [1.0, -1.0, -1.0, -1.0]]
    @test length(unique(join.(signs))) == 8

    P = [4.0 0.5 0.0 0.0; 0.5 3.0 0.0 0.0;
         0.0 0.0 2.0 0.25; 0.0 0.0 0.25 1.5]
    k0 = arc1_reference_k0_start(Arc1ReferenceFakeEngine, P, 0.5)
    g = Arc1ReferenceFakeEngine._fa_uniqueness_from_unconstrained(k0.params[1:4])
    R = Arc1ReferenceFakeEngine._chol_params_to_cov(k0.params[5:14], 4)
    @test g ≈ 0.5 .* diag(P)
    @test R ≈ Diagonal(0.5 .* diag(P))
    @test R[1, 2] == 0.0
    tiny = arc1_reference_k0_start(Arc1ReferenceFakeEngine, fill(1e-12, 4, 4), 0.05)
    tiny_g = Arc1ReferenceFakeEngine._fa_uniqueness_from_unconstrained(tiny.params[1:4])
    tiny_R = Arc1ReferenceFakeEngine._chol_params_to_cov(tiny.params[5:14], 4)
    @test tiny_g ≈ fill(2 * Arc1ReferenceFakeEngine.FA_UNIQUENESS_FLOOR, 4)
    @test tiny_R ≈ Matrix(Diagonal(fill(0.95 * 2 * Arc1ReferenceFakeEngine.FA_UNIQUENESS_FLOOR, 4)))
    k1 = arc1_reference_k1_starts(Arc1ReferenceFakeEngine,
        (; genetic_diagonal=g, residual_covariance=R))
    @test length(k1) == 64
    @test first(k1).amplitude == first(ARC1_REFERENCE_K1_AMPLITUDES)
    @test first(k1).signs == [1.0, 1.0, 1.0, 1.0]
    @test last(k1).amplitude == last(ARC1_REFERENCE_K1_AMPLITUDES)
    @test last(k1).signs == [1.0, -1.0, -1.0, -1.0]
    @test all(k -> all(k.uniqueness .> Arc1ReferenceFakeEngine.FA_UNIQUENESS_FLOOR), k1)
    Arc1ReferenceFakeEngine.FAIL_NEXT_UNIQUENESS_MAP[] = true
    partly_invalid = arc1_reference_k1_starts(Arc1ReferenceFakeEngine,
        (; genetic_diagonal=g, residual_covariance=R))
    @test length(partly_invalid) == 64
    @test count(s -> hasproperty(s, :initialization_status), partly_invalid) == 1
    @test first(partly_invalid).initialization_status == :invalid_initialization
    @test first(partly_invalid).name == Symbol("amplitude_0.025_sign_pppp")
    @test count(s -> !hasproperty(s, :initialization_status) && length(s.params) == 18,
        partly_invalid) == 63

    Y = [1.0 0.0 2.0 -1.0; 2.0 2.0 1.0 0.0; 4.0 3.0 5.0 1.0; 8.0 9.0 4.0 2.0]
    X = [1.0 0.0; 1.0 1.0; 1.0 2.0; 1.0 3.0]
    expected = [begin
        column = Y[:, j]
        sum(abs2, column .- sum(column) / length(column)) / (length(column) - 1)
    end for j in 1:4]
    @test diag(arc1_reference_phenotypic_covariance(Y, X)) ≈ expected
end

@testset "Arc1 production adapter completes K0 refinements before anchoring K1" begin
    n = 12
    Y = [Float64(i * j + (j^2)) for i in 1:n, j in 1:4]
    X = ones(n, 1)
    B = Matrix{Float64}(I, n, n)
    P = arc1_reference_phenotypic_covariance(Y, X)
    calls = NamedTuple[]
    bfgs = (params, rank, budget, _objective) -> begin
        push!(calls, (; rank, params=copy(params), budget))
        k0_index = count(c -> c.rank == 0, calls)
        accepted = !(rank == 0 && k0_index == 6)
        (; phat=copy(params), optimizer_converged=accepted, accepted,
           line_search_success=true, iterations=1,
           optimizer_status=accepted ? "controlled" : "controlled finite-unaccepted",
           status=accepted ? :converged : :optimizer_unconverged,
           reason=accepted ? nothing : "controlled finite-unaccepted")
    end
    nm = (params, rank, budget, _objective) ->
        (; phat=copy(params), converged=true, iterations=1, optimizer_status="controlled NM")
    reference = arc1_fa_expanded_reference(Arc1ReferenceFakeEngine, Y, X, B;
        dataset_identity="same-observed-data", phenotypic_covariance=P,
        optimizer=bfgs, nelder_mead=nm,
        gradient_assessor=(_p, _rank, _ev)->(;status=:ok, passed=true))
    @test reference.status == :best_found
    @test reference.dataset_identity == "same-observed-data"
    @test reference.starts_planned == Dict(0 => 6, 1 => 64)
    @test reference.k0_anchor.source == :best_finite_reference_k0
    @test reference.k0_anchor.source_stage == :bfgs_initial
    @test reference.k0_anchor.start_name == Symbol("split_0.9")
    @test reference.k0_anchor.genetic_diagonal ≈ 0.9 .* diag(P)
    @test all(c -> c.rank == 0, calls[1:10])
    @test all(c -> c.rank == 1, calls[11:end])
    unaccepted_k0 = only(filter(r -> r.rank == 0 && r.stage == :bfgs_initial &&
        r.start_name == Symbol("split_0.9"), reference.rows))
    @test unaccepted_k0.finite
    @test !unaccepted_k0.optimizer_accepted
    @test !unaccepted_k0.optimizer_converged
    @test unaccepted_k0.optimizer_result_status == "optimizer_unconverged"
    @test occursin("finite-unaccepted", unaccepted_k0.optimizer_result_reason)
    @test count(c -> c.rank == 0 && c.budget == ARC1_REFERENCE_BFGS_ITERATIONS, calls) == 10
    @test count(c -> c.rank == 1 && c.budget == ARC1_REFERENCE_BFGS_ITERATIONS, calls) == 68
    @test reference.refinement_selection.per_rank == 4
    @test length(reference.refinement_selection.k0_initial) == 4
    @test length(reference.refinement_selection.k1_initial) == 4
    @test getproperty.(reference.refinement_selection.k0_initial, :start_name) ==
        [Symbol("split_0.9"), Symbol("split_0.7"),
         Symbol("split_0.5"), Symbol("split_0.3")]
    @test getproperty.(reference.refinement_selection.k1_initial, :schedule_index) == [1, 2, 3, 4]
    @test occursin("no convergence or gradient-acceptance filter",
        reference.refinement_selection.predicate)
    k1_initial = only(filter(r -> r.rank == 1 && r.stage == :bfgs_initial &&
        r.start_name == first(arc1_reference_k1_starts(Arc1ReferenceFakeEngine,
            (; genetic_diagonal=0.9 .* diag(P),
               residual_covariance=reference.k0_anchor.residual_covariance))).name,
        reference.rows))
    expected_loading = first(ARC1_REFERENCE_K1_AMPLITUDES) .* sqrt.(
        reference.k0_anchor.genetic_diagonal .- Arc1ReferenceFakeEngine.FA_UNIQUENESS_FLOOR)
    @test k1_initial.start_params[1:4] ≈ expected_loading
    @test all(r -> r.dataset_identity == reference.dataset_identity, reference.rows)
end

@testset "Arc1 production Nelder-Mead closure tracks better then worse evaluations" begin
    empty!(Arc1ReferenceFakeOptim.OBSERVED)
    n = 10
    Y = [Float64(i + 2j + i*j/10) for i in 1:n, j in 1:4]
    X = ones(n, 1)
    B = Matrix{Float64}(I, n, n)
    optimizer = (params, _rank, _budget, _objective) ->
        (; phat=copy(params), converged=true, iterations=1,
           optimizer_status="controlled BFGS")
    reference = arc1_fa_expanded_reference(Arc1ReferenceFakeEngine, Y, X, B;
        dataset_identity="tracked-default-nm", optimizer,
        gradient_assessor=(_p, _rank, _ev)->(; status=:ok, passed=true))
    @test !isempty(Arc1ReferenceFakeOptim.OBSERVED)
    nm_rows = filter(r -> r.rank == 0 && r.stage == :nelder_mead &&
        occursin("controlled Optim exception", r.failure_reason), reference.rows)
    @test length(nm_rows) == 4
    @test all(r -> r.evaluation_count == 2 && r.invalid_evaluation_count == 0, nm_rows)
    @test all(r -> r.finite && r.intermediate_best.params != r.start_params, nm_rows)
    @test all(r -> length(r.intermediate_maxima) == 1 &&
        r.intermediate_maxima[1].source == :objective_callback &&
        r.intermediate_maxima[1].params[1] > r.start_params[1], nm_rows)
    @test any(r -> r.rank == 0 && r.stage == :bfgs_initial && r.finite,
        reference.rows)
end

@testset "Arc1 reference keeps finite stage maxima and uses four per rank" begin
    k0 = [(; rank=0, name=Symbol("k0_$(i)"), params=[Float64(i), 0.0]) for i in 1:6]
    k1 = [(; rank=1, name=Symbol("k1_$(i)"), params=[Float64(i), 0.0]) for i in 1:64]
    called_nm = Dict(0 => Float64[], 1 => Float64[])
    bfgs_calls = Dict(0 => Float64[], 1 => Float64[])
    objective = (p, rank) -> begin
        loglik = p[1] + p[2]
        (; status=:ok, objective=-loglik / 100, raw_objective=-loglik,
           loglik, gradient=[0.0])
    end
    bfgs = (p, rank, budget, _objective) -> begin
        push!(bfgs_calls[rank], p[1])
        # The best K0 start is finite even though its optimizer stopped early.
        converged = !(rank == 0 && p[1] == 6.0)
        (; phat=copy(p), converged, iterations=min(budget, 3),
           optimizer_status=converged ? "converged" : "iteration limit",
           status=converged ? :converged : :not_converged)
    end
    nm = (p, rank, budget, _objective) -> begin
        push!(called_nm[rank], p[1])
        refined = copy(p); refined[2] += 0.25
        (; phat=refined, converged=false, iterations=min(budget, 4),
           optimizer_status="NM limit", status=:not_converged)
    end
    gradient = (_p, _rank, _ev) -> (; status=:ok, passed=true, infinity_norm=0.0)
    result = arc1_run_reference_search(; k0_starts=k0, k1_starts=()->k1,
        objective, optimizer=bfgs, nelder_mead=nm,
        gradient_assessor=gradient, dataset_identity="fixture-sha256")

    @test result.starts_planned == Dict(0 => 6, 1 => 64)
    @test length(called_nm[0]) == 4
    @test length(called_nm[1]) == 4
    @test Set(called_nm[0]) == Set([3.0, 4.0, 5.0, 6.0])
    @test Set(called_nm[1]) == Set([61.0, 62.0, 63.0, 64.0])
    @test length(bfgs_calls[0]) == 10
    @test length(bfgs_calls[1]) == 68
    @test result.best_by_rank[0].loglik == 6.25
    @test result.best_by_rank[1].loglik == 64.25
    @test result.best_by_rank[0].stage == :nelder_mead
    @test all(r -> r.dataset_identity == "fixture-sha256", result.rows)
    @test all(r -> isapprox(r.raw_objective, r.objective * 100), filter(r -> r.finite, result.rows))
    @test any(r -> r.rank == 0 && r.start_name == :k0_6 &&
                   r.stage == :bfgs_initial && r.status == :finite_unaccepted && r.finite,
              result.rows)
    @test occursin("not a global optimum", result.claim)

    comparison = arc1_reference_rank_comparison(6.25005, result; rank=0)
    @test comparison.status == :compared
    @test comparison.passed
    @test arc1_reference_rank_comparison(6.2498, result; rank=0).passed == false
    @test arc1_reference_rank_comparison(nothing, result; rank=0).status == :not_applicable
    @test arc1_reference_rank_comparison(missing, result; rank=0).status == :not_applicable
    missing_reference = (; best_by_rank=Dict(0 => nothing))
    missing_ref_comparison = arc1_reference_rank_comparison(6.0, missing_reference; rank=0)
    @test missing_ref_comparison.status == :unresolved
    @test !missing_ref_comparison.passed
end

@testset "Arc1 equal global likelihood prefers earlier schedule then observation" begin
    starts = [(; rank=0, name=Symbol("k0_$(i)"), schedule_index=i,
        params=[Float64(i), 0.0]) for i in 1:6]
    objective = (p, _rank) -> begin
        loglik = p[1] == 6.0 ? 10.0 :
            p[1] == 1.0 && p[2] > 0 ? 10.0 :
            p[1] == 1.0 ? 9.5 : 9.0 - p[1] / 100
        (; status=:ok, objective=-loglik / 100, raw_objective=-loglik,
           loglik, gradient=zeros(length(p)))
    end
    bfgs = (p, _rank, _budget, _objective) ->
        (; phat=copy(p), optimizer_converged=true, iterations=1,
           optimizer_status="controlled", accepted=true, line_search_success=true,
           status=:converged)
    nm = (p, _rank, _budget, _objective) -> begin
        candidate = copy(p)
        p[1] == 1.0 && (candidate[2] = 0.5)
        (; phat=candidate, optimizer_converged=true, iterations=1,
           optimizer_status="controlled NM", accepted=true, line_search_success=true,
           status=:converged)
    end
    result = arc1_run_reference_search(; k0_starts=starts,
        k1_starts=()->NamedTuple[], objective, optimizer=bfgs, nelder_mead=nm,
        gradient_assessor=(_p, _rank, _ev)->(; status=:ok, passed=true),
        dataset_identity="equal-cross-stage-tie")
    @test result.best_by_rank[0].loglik == 10.0
    @test result.best_by_rank[0].start_name == :k0_1
    @test result.best_by_rank[0].schedule_index == 1
    @test result.best_by_rank[0].stage == :nelder_mead
    @test result.best_by_rank[0].observation_order < maximum(
        r.intermediate_best.observation_order for r in result.rows
        if r.rank == 0 && r.finite && r.intermediate_best !== nothing)
end

@testset "Arc1 row admissibility requires terminal fit and independent checks" begin
    start = [(; rank=0, name=:only, schedule_index=1, params=[0.0])]
    objective = (p, _rank) -> begin
        value = only(p)
        isfinite(value) ?
            (; status=:ok, objective=-value / 100, raw_objective=-value,
               loglik=value, gradient=[0.0]) :
            (; status=:invalid_proposal, objective=Inf, raw_objective=Inf,
               loglik=-Inf, reason="nonfinite terminal fixture", gradient=[Inf])
    end
    function run_case(raw; gradient_pass=true, add_better_probe=false)
        optimizer = function(p, _rank, _budget, tracked_objective)
            add_better_probe && tracked_objective([8.0], 0)
            merge((; phat=add_better_probe ? [NaN] : copy(p)), raw)
        end
        arc1_run_reference_search(; k0_starts=start, k1_starts=()->NamedTuple[],
            objective, optimizer,
            nelder_mead=(p, _r, _b, _o)->(; phat=copy(p), optimizer_converged=true,
                iterations=1, optimizer_status="NM", accepted=true,
                line_search_success=true, status=:converged),
            gradient_assessor=(_p, _r, _ev)->(; status=:ok, passed=gradient_pass),
            dataset_identity="admissibility")
    end
    accepted_but_gradient_fails = run_case((; optimizer_converged=true, accepted=true,
        line_search_success=true, iterations=17, optimizer_status="converged",
        status=:converged); gradient_pass=false)
    row = only(filter(r -> r.rank == 0 && r.stage == :bfgs_initial,
        accepted_but_gradient_fails.rows))
    @test row.optimizer_accepted === true
    @test row.terminal_valid
    @test !row.admissible
    @test row.status == :finite_unaccepted
    @test accepted_but_gradient_fails.best_by_rank[0] !== nothing

    explicitly_rejected = run_case((; optimizer_converged=true, accepted=false,
        line_search_success=true, iterations=12, optimizer_status="rejected",
        status=:rejected); gradient_pass=true)
    rejected_row = only(filter(r -> r.rank == 0 && r.stage == :bfgs_initial,
        explicitly_rejected.rows))
    @test !rejected_row.admissible
    @test rejected_row.optimizer_accepted === false

    line_search_failed = run_case((; optimizer_converged=true, accepted=true,
        line_search_success=false, iterations=9, optimizer_status="line search failed",
        status=:line_search_failed); gradient_pass=true)
    line_row = only(filter(r -> r.rank == 0 && r.stage == :bfgs_initial,
        line_search_failed.rows))
    @test !line_row.admissible
    @test line_row.line_search_success === false

    invalid_terminal = run_case((; optimizer_converged=true, accepted=true,
        line_search_success=true, iterations=5, optimizer_status="converged",
        status=:converged); gradient_pass=true, add_better_probe=true)
    invalid_row = only(filter(r -> r.rank == 0 && r.stage == :bfgs_initial,
        invalid_terminal.rows))
    @test !invalid_row.terminal_valid
    @test !invalid_row.admissible
    @test invalid_row.finite
    @test invalid_row.params == [8.0]
    @test invalid_terminal.best_by_rank[0].params == [8.0]
end

@testset "Arc1 assessor exception keeps optimizer receipt and better probe" begin
    starts = [(; rank=0, name=:only, schedule_index=1, params=[0.0])]
    objective = (p, _rank) -> (; status=:ok, objective=-only(p) / 100,
        raw_objective=-only(p), loglik=only(p), gradient=[0.0])
    optimizer = (p, _rank, _budget, _objective) ->
        (; phat=copy(p), optimizer_converged=true, accepted=true,
           line_search_success=true, iterations=37, optimizer_status="frozen status",
           status=:converged, reason="receipt reason")
    assessment_calls = Ref(0)
    gradient = function(_p, rank, _ev, observe)
        assessment_calls[] += 1
        if assessment_calls[] == 1
            better = [5.0]
            observe(better, objective(better, rank); source=:gradient_probe)
            error("controlled assessor failure")
        end
        (; status=:ok, passed=true)
    end
    result = arc1_run_reference_search(; k0_starts=starts,
        k1_starts=()->NamedTuple[], objective, optimizer,
        nelder_mead=(p, _r, _b, _o)->(; phat=copy(p), optimizer_converged=true,
            accepted=true, line_search_success=true, iterations=1,
            optimizer_status="NM", status=:converged),
        gradient_assessor=gradient, dataset_identity="assessor-exception")
    row = only(filter(r -> r.rank == 0 && r.stage == :bfgs_initial, result.rows))
    @test row.status == :failed
    @test occursin("controlled assessor failure", row.failure_reason)
    @test row.optimizer_status == "frozen status"
    @test row.optimizer_result_status == "converged"
    @test row.optimizer_result_reason == "receipt reason"
    @test row.optimizer_iterations == 37
    @test row.optimizer_converged
    @test row.optimizer_accepted === true
    @test row.line_search_success === true
    @test row.finite
    @test row.intermediate_best.params == [5.0]
    @test result.best_by_rank[0].observation_source == :gradient_probe
end

@testset "Arc1 reference preserves optimizer failures" begin
    starts = [(; rank=0, name=:only, params=[1.0])]
    objective = (_p, _rank) -> (; status=:ok, objective=-0.1,
        raw_objective=-10.0, loglik=10.0, gradient=[0.0])
    failed = (_p, _rank, _iterations, _objective) -> error("controlled optimizer failure")
    result = arc1_run_reference_search(; k0_starts=starts, k1_starts=()->NamedTuple[],
        objective, optimizer=failed, nelder_mead=failed,
        gradient_assessor=(_p, _rank, _ev)->(;status=:not_run, passed=false),
        dataset_identity="same-data")
    @test any(r -> r.start_name == :only && r.stage == :bfgs_initial &&
                   r.status == :failed && occursin("controlled optimizer failure", r.failure_reason),
              result.rows)
    @test result.best_by_rank[0] === nothing
    @test result.best_by_rank[1] === nothing
end

@testset "Arc1 retains intermediate maxima across worse and invalid probes then failure" begin
    starts = [(; rank=0, name=:only, params=[0.0])]
    k1 = [(; rank=1, name=Symbol("k1_$(i)"), params=[Float64(i)],
            initialization_status=i == 2 ? :invalid_initialization : nothing,
            failure_reason=i == 2 ? "controlled single mapping failure" : nothing)
           for i in 1:64]
    # Remove the marker from valid starts so only the single failed mapping is skipped.
    k1 = [s.initialization_status === nothing ?
          (; rank=s.rank, name=s.name, params=s.params) : s for s in k1]
    rank1_calls = Ref(0)
    objective = (p, _rank) -> begin
        value = only(p)
        isfinite(value) ?
            (; status=:ok, objective=-value / 100, raw_objective=-value,
               loglik=value, gradient=[0.0]) :
            (; status=:invalid_proposal, objective=Inf, raw_objective=Inf,
               loglik=-Inf, reason="controlled invalid objective", gradient=[Inf])
    end
    bfgs = (p, rank, _budget, tracked_objective) -> begin
        if rank == 1
            rank1_calls[] += 1
        elseif p[1] == 0.0
            tracked_objective([4.0], rank)
            tracked_objective([3.0], rank)
            tracked_objective([NaN], rank)
            error("controlled failure after intermediate evaluations")
        end
        (; phat=copy(p), converged=true, iterations=1, optimizer_status="controlled")
    end
    nm = (p, _rank, _budget, _objective) ->
        (; phat=copy(p), converged=true, iterations=1, optimizer_status="controlled NM")
    result = arc1_run_reference_search(; k0_starts=starts, k1_starts=()->k1,
        objective, optimizer=bfgs, nelder_mead=nm,
        gradient_assessor=(_p, _rank, _ev)->(; status=:ok, passed=true),
        dataset_identity="exception-ledger")
    initial = only(filter(r -> r.rank == 0 && r.stage == :bfgs_initial, result.rows))
    @test initial.status == :failed
    @test occursin("controlled failure after intermediate evaluations", initial.failure_reason)
    @test initial.finite
    @test initial.evaluation_count == 3
    @test initial.invalid_evaluation_count == 1
    @test initial.intermediate_best.params == [4.0]
    @test initial.intermediate_best.loglik == 4.0
    @test only(initial.intermediate_maxima).params == [4.0]
    @test result.best_by_rank[0].params == [4.0]
    @test arc1_reference_rank_comparison(4.0 - 1.5e-4, result; rank=0).passed == false
    @test arc1_reference_rank_comparison(4.0 - 0.5e-4, result; rank=0).passed
    @test rank1_calls[] == 63 + 4
    invalid_k1 = only(filter(r -> r.rank == 1 && r.status == :invalid_initialization,
        result.rows))
    @test invalid_k1.start_name == :k1_2
    @test count(r -> r.rank == 1 && r.stage == :bfgs_initial, result.rows) == 64
end

@testset "Arc1 gradient probes can supply the best finite reference point" begin
    starts = [(; rank=0, name=:initial, params=[0.0])]
    objective = (p, _rank) -> (; status=:ok, objective=-only(p) / 100,
        raw_objective=-only(p), loglik=only(p), gradient=[0.0])
    bfgs = (p, _rank, _budget, _objective) ->
        (; phat=copy(p), converged=true, iterations=1, optimizer_status="converged")
    nm = (p, _rank, _budget, _objective) ->
        (; phat=copy(p), converged=true, iterations=1, optimizer_status="converged NM")
    gradient_calls = Ref(0)
    gradient = function(_p, rank, _ev, observe)
        gradient_calls[] += 1
        if gradient_calls[] == 1
            params = [2.5]
            observe(params, objective(params, rank); source=:gradient_probe)
        end
        (; status=:ok, passed=false, reason="controlled gradient refusal")
    end
    result = arc1_run_reference_search(; k0_starts=starts, k1_starts=()->NamedTuple[],
        objective, optimizer=bfgs, nelder_mead=nm,
        gradient_assessor=gradient, dataset_identity="gradient-probe-only")
    @test result.best_by_rank[0].params == [2.5]
    @test result.best_by_rank[0].loglik == 2.5
    @test result.best_by_rank[0].observation_source == :gradient_probe
    initial = only(filter(r -> r.rank == 0 && r.stage == :bfgs_initial, result.rows))
    @test ismissing(initial.optimizer_accepted)
    @test initial.status == :finite_unaccepted
    @test initial.intermediate_best.params == [2.5]
    @test initial.gradient_assessment_params == [0.0]
    @test initial.params == [2.5]
    @test any(m -> m.source == :gradient_probe, initial.intermediate_maxima)
end

@testset "Arc1 engine observation hook records exact gradient-sweep evaluations" begin
    Y = [1.0 0.5 -0.2 1.1; 0.2 1.4 0.8 -0.7; -0.4 0.3 1.2 0.1;
         1.1 -0.8 0.6 0.9; 0.7 0.2 -1.0 1.3]
    X = ones(size(Y, 1), 1)
    B = Matrix{Float64}(I, size(Y, 1), size(Y, 1))
    ctx = HSquared._arc1_fa_spectral_context(Y, X, B).context
    params = vcat(fill(log(0.25), 4), zeros(10))
    baseline = HSquared._arc1_fa_central_gradient_sweep(ctx, params, 0)
    explicit_nothing = HSquared._arc1_fa_central_gradient_sweep(ctx, params, 0;
        evaluation_callback=nothing)
    @test baseline == explicit_nothing
    events = Tuple{Vector{Float64},Symbol}[]
    mutating_observer = function(p, evaluation)
        push!(events, (copy(p), evaluation.status))
        fill!(p, 99.0)
    end
    observed = HSquared._arc1_fa_central_gradient_sweep(ctx, params, 0;
        evaluation_callback=mutating_observer)
    @test observed == baseline
    @test length(events) == 1 + 4length(params)
    @test events[1] == (params, :ok)
    @test params == vcat(fill(log(0.25), 4), zeros(10))

    assessment_events = Tuple{Vector{Float64},Symbol}[]
    assess_observer = (p, ev) -> push!(assessment_events, (copy(p), ev.status))
    HSquared._arc1_fa_assess_optimizer_result((; phat=params,
        optimizer_converged=false, line_search_success=false, iterations=1,
        optimizer_status="controlled"), ctx, 0; evaluation_callback=assess_observer)
    @test length(assessment_events) == 2 + 4length(params)
    @test all(status == :ok && length(p) == length(params)
        for (p, status) in assessment_events)

    invalid_events = Tuple{Vector{Float64},Symbol}[]
    invalid_observer = (p, ev) -> push!(invalid_events, (copy(p), ev.status))
    implicit_default = HSquared._arc1_fa_bfgs(ctx, [NaN], 0; iterations=1)
    explicit_default = HSquared._arc1_fa_bfgs(ctx, [NaN], 0; iterations=1,
        evaluation_callback=nothing)
    @test isequal(implicit_default, explicit_default)
    invalid_result = HSquared._arc1_fa_bfgs(ctx, [NaN], 0; iterations=1,
        evaluation_callback=invalid_observer)
    @test invalid_result.status == implicit_default.status
    @test invalid_result.reason == implicit_default.reason
    @test length(invalid_events) == 2
    @test all(status != :ok for (_, status) in invalid_events)
end
