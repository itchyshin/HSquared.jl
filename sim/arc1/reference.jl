# Expanded best-found reference search for the Arc1 Gaussian FA study.
# Include from the simulation executor after loading HSquared.
using LinearAlgebra

const ARC1_REFERENCE_K0_SPLITS = (0.05, 0.15, 0.3, 0.5, 0.7, 0.9)
const ARC1_REFERENCE_K1_AMPLITUDES = (0.025, 0.1, 0.25, 0.5, 0.7, 0.9, 0.97, 0.995)
const ARC1_REFERENCE_BFGS_ITERATIONS = 10_000
const ARC1_REFERENCE_NM_ITERATIONS = 20_000
const ARC1_REFERENCE_RETAIN_PER_RANK = 4
const ARC1_REFERENCE_AGREEMENT = 1e-4

function arc1_reference_sign_patterns()
    # Frozen reference order: s4 changes fastest. This is intentionally not
    # the ordinary selector's integer-mask order.
    return [[1.0, s2, s3, s4] for (s2, s3, s4) in (
        (1.0, 1.0, 1.0), (1.0, 1.0, -1.0),
        (1.0, -1.0, 1.0), (1.0, -1.0, -1.0),
        (-1.0, 1.0, 1.0), (-1.0, 1.0, -1.0),
        (-1.0, -1.0, 1.0), (-1.0, -1.0, -1.0))]
end

function arc1_reference_phenotypic_covariance(Y, X)
    n, t = size(Y)
    t == 4 || throw(ArgumentError("Arc1 reference requires four traits"))
    size(X, 1) == n || throw(ArgumentError("X row count must match Y"))
    n > size(X, 2) || throw(ArgumentError("reference requires positive residual degrees of freedom"))
    all(isfinite, Y) && all(isfinite, X) || throw(ArgumentError("Y and X must be finite"))
    # Match the ordinary FA selector's data-only scale: per-trait sample
    # variance around that trait's sample mean (not truth or fitted residuals).
    variances = [begin
        column = view(Y, :, j)
        value = sum(abs2, column .- sum(column) / n) / (n - 1)
        isfinite(value) && value > 0 ? value : 1.0
    end for j in 1:4]
    return Matrix(Diagonal(Float64.(variances)))
end

function arc1_reference_k0_start(engine::Module, phenotypic_covariance, split)
    P = Matrix{Float64}(phenotypic_covariance)
    size(P) == (4, 4) || throw(ArgumentError("phenotypic covariance must be 4×4"))
    isfinite(split) && 0 < split < 1 || throw(ArgumentError("K0 split must be in (0, 1)"))
    floor = getfield(engine, :FA_UNIQUENESS_FLOOR)
    phen = diag(P)
    all(isfinite, phen) || throw(ArgumentError("phenotypic variances must be finite"))
    v = max.(phen, 2floor)
    g = max.(split .* v, 2floor)
    R = Matrix(Diagonal((1 - split) .* v))
    all(x -> isfinite(x) && x > floor, g) ||
        throw(ArgumentError("K0 split does not leave positive uniqueness above the floor"))
    rchol = getfield(engine, :_cov_to_chol_params)(R, 4)
    params = vcat(getfield(engine, :_fa_uniqueness_to_unconstrained)(g), rchol)
    return (; rank=0, name=Symbol("split_$(split)"), split, params,
            genetic_diagonal=Vector{Float64}(g), residual_covariance=R)
end

function arc1_reference_k1_starts(engine::Module, anchor)
    floor = getfield(engine, :FA_UNIQUENESS_FLOOR)
    g = Float64.(anchor.genetic_diagonal)
    R = Matrix{Float64}(anchor.residual_covariance)
    all(x -> isfinite(x) && x > floor, g) ||
        throw(ArgumentError("K1 anchor genetic variances must exceed the uniqueness floor"))
    rchol = getfield(engine, :_cov_to_chol_params)(R, 4)
    starts = NamedTuple[]
    for amplitude in ARC1_REFERENCE_K1_AMPLITUDES,
        signs in arc1_reference_sign_patterns()
        schedule_index = length(starts) + 1
        name = Symbol("amplitude_$(amplitude)_sign_$(join(ifelse.(signs .> 0, "p", "m")))")
        try
            loading = amplitude .* signs .* sqrt.(g .- floor)
            uniqueness = g .- loading .^ 2
            all(x -> isfinite(x) && x > floor, uniqueness) ||
                throw(ArgumentError("K1 reference start violates the uniqueness floor"))
            params = vcat(loading,
                getfield(engine, :_fa_uniqueness_to_unconstrained)(uniqueness), rchol)
            push!(starts, (; rank=1, name, amplitude, signs=copy(signs), loading,
                uniqueness, params, schedule_index))
        catch err
            err isa InterruptException && rethrow()
            push!(starts, (; rank=1, name, amplitude, signs=copy(signs),
                loading=Float64[], uniqueness=Float64[], params=Float64[],
                schedule_index,
                initialization_status=:invalid_initialization,
                failure_reason=sprint(showerror, err)))
        end
    end
    return starts
end

function arc1_reference_optimizer_result(raw, fallback_params)
    params = try
        Float64.(collect(raw.phat))
    catch
        Float64.(fallback_params)
    end
    return (; params,
        optimizer_converged = hasproperty(raw, :optimizer_converged) ? Bool(raw.optimizer_converged) :
            (hasproperty(raw, :converged) ? Bool(raw.converged) : false),
        optimizer_accepted = hasproperty(raw, :accepted) ? Bool(raw.accepted) : missing,
        line_search_success = hasproperty(raw, :line_search_success) ?
            Bool(raw.line_search_success) : missing,
        iterations = hasproperty(raw, :iterations) ? Int(raw.iterations) : 0,
        optimizer_status = hasproperty(raw, :optimizer_status) ? string(raw.optimizer_status) :
            (hasproperty(raw, :status) ? string(raw.status) : "unknown"),
        result_status = hasproperty(raw, :status) ? string(raw.status) : "unknown",
        result_reason = hasproperty(raw, :reason) ? string(raw.reason) :
            (hasproperty(raw, :failure_reason) ? string(raw.failure_reason) : ""))
end

function arc1_reference_finite_evaluation(evaluation)
    hasproperty(evaluation, :status) && evaluation.status == :ok &&
        hasproperty(evaluation, :objective) && isfinite(evaluation.objective) &&
        hasproperty(evaluation, :raw_objective) && isfinite(evaluation.raw_objective) &&
        hasproperty(evaluation, :loglik) && isfinite(evaluation.loglik)
end

mutable struct Arc1ReferenceRunTracker
    evaluation_count::Int
    invalid_evaluation_count::Int
    best_evaluation::Any
    improving_maxima::Vector{Any}
end

function arc1_reference_prefer_global(point, current)
    current === nothing && return true
    point.loglik > current.loglik && return true
    point.loglik < current.loglik && return false
    point.schedule_index < current.schedule_index && return true
    point.schedule_index > current.schedule_index && return false
    return point.observation_order < current.observation_order
end

function arc1_reference_explicit_rejection(raw)
    hasproperty(raw, :accepted) && raw.accepted === false && return true
    if hasproperty(raw, :status)
        status = raw.status
        status in (:rejected, :failed, :invalid, :invalid_objective,
                   :invalid_proposal, :line_search_failed, :line_search_failure) && return true
        lowercase(string(status)) in ("rejected", "failed", "invalid", "invalid_objective",
            "invalid_proposal", "line_search_failed", "line_search_failure") && return true
    end
    return false
end

function arc1_reference_run!(rows, best, starts, rank, objective, optimizer,
                             gradient_assessor; stage, iterations, dataset_identity,
                             observation_counter)
    for (local_schedule_index, start) in enumerate(starts)
        schedule_index = hasproperty(start, :schedule_index) ?
            start.schedule_index : local_schedule_index
        tracker = Arc1ReferenceRunTracker(0, 0, nothing, Any[])
        row = (; rank, start_name=start.name, start_definition=deepcopy(start),
               start_params=copy(start.params), stage,
               schedule_index, iterations_budget=iterations, dataset_identity,
               status=:unattempted, failure_reason=nothing, params=copy(start.params),
               objective=Inf, raw_objective=Inf, loglik=-Inf, finite=false,
               terminal_valid=false, admissible=false,
               optimizer_converged=false, optimizer_iterations=0,
               optimizer_accepted=missing, line_search_success=missing,
               optimizer_status="not_run", optimizer_result_status="not_run",
               optimizer_result_reason="", gradient_assessment=nothing,
               gradient_assessment_params=nothing,
               evaluation_count=0, invalid_evaluation_count=0,
               intermediate_best=nothing, intermediate_maxima=Any[])
        if hasproperty(start, :initialization_status)
            row = merge(row, (; status=start.initialization_status,
                failure_reason=start.failure_reason))
        else
        try
            record_evaluation = function(params, ev; source=:optimizer)
                tracker.evaluation_count += 1
                observation_counter[] += 1
                if arc1_reference_finite_evaluation(ev)
                    point = (; params=Float64.(collect(params)),
                        objective=Float64(ev.objective), raw_objective=Float64(ev.raw_objective),
                        loglik=Float64(ev.loglik), source,
                        schedule_index, observation_order=observation_counter[])
                    previous = tracker.best_evaluation
                    if previous === nothing || point.loglik > previous.loglik
                        tracker.best_evaluation = point
                        push!(tracker.improving_maxima, point)
                    end
                    current = best[]
                    if arc1_reference_prefer_global(point, current)
                        best[] = (; rank, start_name=start.name, stage,
                            schedule_index, params=copy(point.params), objective=point.objective,
                            raw_objective=point.raw_objective, loglik=point.loglik,
                            dataset_identity, observation_source=source,
                            observation_order=point.observation_order)
                    end
                else
                    tracker.invalid_evaluation_count += 1
                end
                return nothing
            end
            tracked_objective = function(params, requested_rank)
                ev = try
                    objective(params, requested_rank)
                catch
                    tracker.evaluation_count += 1
                    tracker.invalid_evaluation_count += 1
                    rethrow()
                end
                record_evaluation(params, ev; source=:objective_callback)
                ev
            end
            raw = applicable(optimizer, start.params, rank, iterations,
                tracked_objective, record_evaluation) ?
                optimizer(start.params, rank, iterations, tracked_objective, record_evaluation) :
                optimizer(start.params, rank, iterations, tracked_objective)
            opt = arc1_reference_optimizer_result(raw, start.params)
            row = merge(row, (; optimizer_params=copy(opt.params),
                optimizer_converged=opt.optimizer_converged,
                optimizer_accepted=opt.optimizer_accepted,
                line_search_success=opt.line_search_success,
                optimizer_iterations=opt.iterations,
                optimizer_status=opt.optimizer_status,
                optimizer_result_status=opt.result_status,
                optimizer_result_reason=opt.result_reason))
            ev = tracked_objective(opt.params, rank)
            terminal_valid = arc1_reference_finite_evaluation(ev)
            row = merge(row, (; terminal_valid, terminal_params=copy(opt.params)))
            assessment = applicable(gradient_assessor, opt.params, rank, ev, record_evaluation) ?
                gradient_assessor(opt.params, rank, ev, record_evaluation) :
                gradient_assessor(opt.params, rank, ev)
            run_best = tracker.best_evaluation
            finite = run_best !== nothing
            gradient_ok = hasproperty(assessment, :passed) && assessment.passed
            no_explicit_line_failure = ismissing(opt.line_search_success) ||
                opt.line_search_success
            admissible = terminal_valid && opt.optimizer_converged && gradient_ok &&
                no_explicit_line_failure && !arc1_reference_explicit_rejection(raw)
            status = !finite ? :invalid_objective : admissible ?
                     :admissible : :finite_unaccepted
            raw_reason = hasproperty(raw, :reason) ? raw.reason :
                (hasproperty(raw, :failure_reason) ? raw.failure_reason : nothing)
            fallback_reason = !terminal_valid ?
                (hasproperty(ev, :reason) ? ev.reason : "terminal optimizer point is not finite and model-admissible") :
                !opt.optimizer_converged ? "optimizer did not converge" :
                !no_explicit_line_failure ? "optimizer reported an explicit line-search failure" :
                arc1_reference_explicit_rejection(raw) ? "optimizer explicitly rejected the terminal point" :
                !gradient_ok ? (hasproperty(assessment, :reason) ? assessment.reason :
                    "independent gradient assessment did not pass") : nothing
            row = merge(row, (; status, admissible,
                failure_reason = raw_reason === nothing || ismissing(raw_reason) ? fallback_reason : raw_reason,
                params=finite ? copy(run_best.params) : copy(opt.params),
                objective=finite ? run_best.objective : Inf,
                raw_objective=finite ? run_best.raw_objective : Inf,
                loglik=finite ? run_best.loglik : -Inf,
                finite,
                gradient_assessment=assessment,
                gradient_assessment_params=copy(opt.params),
                evaluation_count=tracker.evaluation_count,
                invalid_evaluation_count=tracker.invalid_evaluation_count,
                intermediate_best=run_best,
                intermediate_maxima=copy(tracker.improving_maxima)))
        catch err
            if err isa InterruptException
                row = merge(row, (; status=:interrupted, failure_reason="interrupted",
                    finite=tracker.best_evaluation !== nothing,
                    params=tracker.best_evaluation === nothing ? copy(start.params) :
                        copy(tracker.best_evaluation.params),
                    objective=tracker.best_evaluation === nothing ? Inf : tracker.best_evaluation.objective,
                    raw_objective=tracker.best_evaluation === nothing ? Inf : tracker.best_evaluation.raw_objective,
                    loglik=tracker.best_evaluation === nothing ? -Inf : tracker.best_evaluation.loglik,
                    evaluation_count=tracker.evaluation_count,
                    invalid_evaluation_count=tracker.invalid_evaluation_count,
                    intermediate_best=tracker.best_evaluation,
                    intermediate_maxima=copy(tracker.improving_maxima)))
                push!(rows, row)
                rethrow()
            end
            row = merge(row, (; status=:failed,
                failure_reason=sprint(showerror, err),
                finite=tracker.best_evaluation !== nothing,
                params=tracker.best_evaluation === nothing ? copy(start.params) :
                    copy(tracker.best_evaluation.params),
                objective=tracker.best_evaluation === nothing ? Inf : tracker.best_evaluation.objective,
                raw_objective=tracker.best_evaluation === nothing ? Inf : tracker.best_evaluation.raw_objective,
                loglik=tracker.best_evaluation === nothing ? -Inf : tracker.best_evaluation.loglik,
                evaluation_count=tracker.evaluation_count,
                invalid_evaluation_count=tracker.invalid_evaluation_count,
                intermediate_best=tracker.best_evaluation,
                intermediate_maxima=copy(tracker.improving_maxima)))
        end
        end
        push!(rows, row)
    end
    return nothing
end

function arc1_reference_stage_starts(rows, rank, stage, count)
    eligible = filter(r -> r.rank == rank && r.stage == stage && r.finite, rows)
    sort!(eligible; by=r -> (-r.loglik, r.schedule_index))
    return [(; rank, name=r.start_name, params=copy(r.params),
             schedule_index=r.schedule_index)
            for r in Iterators.take(eligible, count)]
end

function arc1_reference_selection_record(starts)
    return [(; start_name=start.name, schedule_index=start.schedule_index,
        params=copy(start.params)) for start in starts]
end

function arc1_reference_top_starts(rows, rank, count)
    eligible = filter(r -> r.rank == rank && r.finite, rows)
    sort!(eligible; by=r -> (-r.loglik, r.schedule_index))
    # A solution is carried once, by its best finite stage so far.
    chosen = NamedTuple[]
    seen = Set{String}()
    for row in eligible
        key = String(row.start_name)
        key in seen && continue
        push!(seen, key)
        push!(chosen, (; rank, name=row.start_name, params=copy(row.params),
                       schedule_index=row.schedule_index))
        length(chosen) == count && break
    end
    return chosen
end

function arc1_reference_default_optimizer(engine::Module, ctx, params, rank, iterations, objective,
                                          evaluation_callback)
    if rank == :nm
        error("rank must be numeric; use arc1_reference_nelder_mead for NM stages")
    end
    return getfield(engine, :_arc1_fa_bfgs)(ctx, params, rank;
        iterations, optimizer_tol=1e-8, final_gradient_tol=1e-6,
        evaluation_callback)
end

function arc1_reference_nelder_mead(engine::Module, params, rank, iterations, objective)
    Optim = getfield(engine, :Optim)
    f = p -> begin
        ev = objective(p, rank)
        arc1_reference_finite_evaluation(ev) ? Float64(ev.objective) : Inf
    end
    result = Optim.optimize(f, Float64.(params), Optim.NelderMead(),
        Optim.Options(iterations=iterations))
    return (; phat=Optim.minimizer(result), optimizer_converged=Optim.converged(result),
        iterations=Optim.iterations(result), optimizer_status=sprint(Optim.summary, result))
end

"""Run the expanded deterministic reference on one already-observed dataset.

`starts` is a test seam. Production callers omit it and provide `engine` plus the
exact data arrays. Optimizer callbacks return a result with `phat`; all values
are re-evaluated by the exact objective before retention.
"""
function arc1_run_reference_search(; k0_starts, k1_starts, objective, optimizer,
        nelder_mead, gradient_assessor, dataset_identity, after_k0=(_rows, _best)->nothing)
    isempty(dataset_identity) && throw(ArgumentError("dataset identity is required"))
    rows = NamedTuple[]
    best = Dict(0 => Ref{Any}(nothing), 1 => Ref{Any}(nothing))
    observation_counters = Dict(0 => Ref(0), 1 => Ref(0))
    arc1_reference_run!(rows, best[0], k0_starts, 0, objective, optimizer,
        gradient_assessor; stage=:bfgs_initial, iterations=ARC1_REFERENCE_BFGS_ITERATIONS,
        dataset_identity, observation_counter=observation_counters[0])
    selected0 = arc1_reference_stage_starts(rows, 0, :bfgs_initial,
        ARC1_REFERENCE_RETAIN_PER_RANK)
    arc1_reference_run!(rows, best[0], selected0, 0, objective,
        nelder_mead, gradient_assessor; stage=:nelder_mead,
        iterations=ARC1_REFERENCE_NM_ITERATIONS, dataset_identity,
        observation_counter=observation_counters[0])
    nm0 = arc1_reference_stage_starts(rows, 0, :nelder_mead,
        ARC1_REFERENCE_RETAIN_PER_RANK)
    arc1_reference_run!(rows, best[0], nm0, 0, objective, optimizer,
        gradient_assessor; stage=:bfgs_final,
        iterations=ARC1_REFERENCE_BFGS_ITERATIONS, dataset_identity,
        observation_counter=observation_counters[0])

    # The K1 anchor is selected only after every scheduled K0 stage has run.
    after_k0(rows, best[0][])
    starts1 = k1_starts()
    arc1_reference_run!(rows, best[1], starts1, 1, objective, optimizer,
        gradient_assessor; stage=:bfgs_initial,
        iterations=ARC1_REFERENCE_BFGS_ITERATIONS, dataset_identity,
        observation_counter=observation_counters[1])
    selected1 = arc1_reference_stage_starts(rows, 1, :bfgs_initial,
        ARC1_REFERENCE_RETAIN_PER_RANK)
    arc1_reference_run!(rows, best[1], selected1, 1, objective,
        nelder_mead, gradient_assessor; stage=:nelder_mead,
        iterations=ARC1_REFERENCE_NM_ITERATIONS, dataset_identity,
        observation_counter=observation_counters[1])
    nm1 = arc1_reference_stage_starts(rows, 1, :nelder_mead,
        ARC1_REFERENCE_RETAIN_PER_RANK)
    arc1_reference_run!(rows, best[1], nm1, 1, objective, optimizer,
        gradient_assessor; stage=:bfgs_final,
        iterations=ARC1_REFERENCE_BFGS_ITERATIONS, dataset_identity,
        observation_counter=observation_counters[1])
    # Preserve each rank's best from every stage, including finite maxima from
    # optimizers that stopped unconverged or failed independent gradient checks.
    return (; status=:best_found, dataset_identity, rows,
        best_by_rank=Dict(k => best[k][] for k in (0, 1)),
        starts_planned=Dict(0 => length(k0_starts), 1 => length(starts1)),
        refinement_selection=(;
            predicate="finite exact objective: status == :ok and finite objective, raw_objective, and loglik; no convergence or gradient-acceptance filter",
            per_rank=ARC1_REFERENCE_RETAIN_PER_RANK,
            tie_order="descending loglik, then earliest start schedule index within rank",
            ranking_point="best valid observed point per start and stage, including optimizer callbacks and independent-gradient probes",
            k0_initial=arc1_reference_selection_record(selected0),
            k0_nelder_mead=arc1_reference_selection_record(nm0),
            k1_initial=arc1_reference_selection_record(selected1),
            k1_nelder_mead=arc1_reference_selection_record(nm1)),
        optimizer_budgets=(; bfgs=ARC1_REFERENCE_BFGS_ITERATIONS,
                           nelder_mead=ARC1_REFERENCE_NM_ITERATIONS,
                           retained_per_rank=ARC1_REFERENCE_RETAIN_PER_RANK),
        claim="best found under the frozen deterministic schedule; not a global optimum")
end

function arc1_fa_expanded_reference(engine::Module, Y, X, B;
        dataset_identity, phenotypic_covariance=arc1_reference_phenotypic_covariance(Y, X),
        optimizer=nothing, nelder_mead=nothing, gradient_assessor=nothing)
    spectral = getfield(engine, :_arc1_fa_spectral_context)(Y, X, B)
    spectral.status == :ok || return (; status=:unsupported_input,
        reason=spectral.reason, dataset_identity, rows=NamedTuple[],
        best_by_rank=Dict(0 => nothing, 1 => nothing))
    ctx = spectral.context
    objective = (params, rank) -> getfield(engine, :_arc1_fa_exact_objective_gradient)(ctx, params, rank)
    bfgs = optimizer === nothing ?
        ((params, rank, iterations, _objective, evaluation_callback) ->
            arc1_reference_default_optimizer(engine, ctx, params, rank, iterations,
                objective, evaluation_callback)) : optimizer
    nm = nelder_mead === nothing ?
        ((params, rank, iterations, tracked_objective) -> arc1_reference_nelder_mead(
            engine, params, rank, iterations, tracked_objective)) : nelder_mead
    gradients = gradient_assessor === nothing ?
        ((params, rank, ev, evaluation_callback) -> begin
            sweep = getfield(engine, :_arc1_fa_central_gradient_sweep)(ctx, params, rank;
                evaluation_callback)
            analytic_norm = hasproperty(ev, :gradient) && all(isfinite, ev.gradient) ?
                norm(ev.gradient, Inf) : Inf
            (; status=sweep.status, steps=sweep.steps, infinity_norms=sweep.norms,
               discrepancies=sweep.discrepancies, analytic_gradient_inf_norm=analytic_norm,
               passed=sweep.status == :ok && maximum(sweep.norms) <= 5e-6 &&
                      maximum(sweep.discrepancies) <= 5e-6 && analytic_norm <= 1e-6)
        end) : gradient_assessor

    k0_starts = NamedTuple[]
    for (schedule_index, split) in enumerate(ARC1_REFERENCE_K0_SPLITS)
        try
            start = arc1_reference_k0_start(engine, phenotypic_covariance, split)
            push!(k0_starts, merge(start, (; schedule_index)))
        catch err
            err isa InterruptException && rethrow()
            push!(k0_starts, (; rank=0, name=Symbol("split_$(split)"), split, schedule_index,
                params=Float64[], initialization_status=:invalid,
                failure_reason=sprint(showerror, err)))
        end
    end
    # Invalid starts are still retained as rows; they are excluded from calls
    # to the optimizer by the validity filter in the adapter below.
    valid_k0 = filter(s -> !hasproperty(s, :initialization_status), k0_starts)
    invalid_k0 = filter(s -> hasproperty(s, :initialization_status), k0_starts)
    # The data-only fallback is used only if every observed K0 point is invalid.
    fallback_anchor = try
        arc1_reference_k0_start(engine, phenotypic_covariance, 0.5)
    catch err
        err isa InterruptException && rethrow()
        nothing
    end
    anchor = Ref{Any}(nothing)
    # Starts are materialized after the full K0 initial/NM/BFGS schedule.
    k1_starts = () -> try
        reference_anchor = anchor[] === nothing ? fallback_anchor : anchor[]
        reference_anchor === nothing &&
            throw(ArgumentError("neither an admissible K0 fit nor analytic f=0.5 anchor is available"))
        arc1_reference_k1_starts(engine, reference_anchor)
    catch err
        err isa InterruptException && rethrow()
        [ (; rank=1, name=Symbol("reference_k1_$(i)"), params=Float64[],
             initialization_status=:invalid_initialization,
             failure_reason=sprint(showerror, err)) for i in 1:64 ]
    end
    result = arc1_run_reference_search(; k0_starts=valid_k0,
        k1_starts, objective,
        optimizer=bfgs, nelder_mead=nm, gradient_assessor=gradients,
        dataset_identity,
        after_k0=(rows, _best) -> begin
            best_k0 = _best
            if best_k0 !== nothing
                anchor[] = (; genetic_diagonal=getfield(engine, :_fa_uniqueness_from_unconstrained)(best_k0.params[1:4]),
                    residual_covariance=getfield(engine, :_chol_params_to_cov)(best_k0.params[5:14], 4),
                    loglik=best_k0.loglik, source=best_k0.start_name,
                    source_stage=best_k0.stage,
                    observation_source=best_k0.observation_source)
            end
        end)
    if isempty(invalid_k0)
        anchor_record = anchor[] === nothing ?
            (; source=:analytic_split_fallback, split=0.5,
               genetic_diagonal=fallback_anchor === nothing ? nothing : fallback_anchor.genetic_diagonal,
               residual_covariance=fallback_anchor === nothing ? nothing : fallback_anchor.residual_covariance,
               status=fallback_anchor === nothing ? :invalid_initialization : :available) :
            (; source=:best_finite_reference_k0, split=missing,
               genetic_diagonal=anchor[].genetic_diagonal,
               residual_covariance=anchor[].residual_covariance,
               loglik=anchor[].loglik, start_name=anchor[].source,
               source_stage=anchor[].source_stage,
               observation_source=anchor[].observation_source, status=:available)
        return merge(result, (; starts_planned=Dict(0 => 6, 1 => 64),
            k0_anchor=anchor_record))
    end
    invalid_rows = [(; rank=0, start_name=s.name, stage=:start_generation,
        start_definition=deepcopy(s), schedule_index=s.schedule_index,
        iterations_budget=0, dataset_identity, status=:invalid_initialization,
        failure_reason=s.failure_reason, params=Float64[], objective=Inf,
        raw_objective=Inf, loglik=-Inf, finite=false, optimizer_converged=false,
        optimizer_iterations=0, optimizer_status="not_run", gradient_assessment=nothing)
        for s in invalid_k0]
    return merge(result, (; rows=vcat(invalid_rows, result.rows),
        starts_planned=Dict(0 => 6, 1 => 64),
        k0_anchor=anchor[] === nothing ?
            (; source=:analytic_split_fallback, split=0.5,
               genetic_diagonal=fallback_anchor === nothing ? nothing : fallback_anchor.genetic_diagonal,
               residual_covariance=fallback_anchor === nothing ? nothing : fallback_anchor.residual_covariance,
               status=fallback_anchor === nothing ? :invalid_initialization : :available) :
            (; source=:best_finite_reference_k0, split=missing,
               genetic_diagonal=anchor[].genetic_diagonal,
               residual_covariance=anchor[].residual_covariance,
               loglik=anchor[].loglik, start_name=anchor[].source,
               source_stage=anchor[].source_stage,
               observation_source=anchor[].observation_source, status=:available)))
end

function arc1_reference_rank_comparison(ordinary_loglik, reference; rank,
                                        tolerance=ARC1_REFERENCE_AGREEMENT)
    best = hasproperty(reference, :best_by_rank) && haskey(reference.best_by_rank, rank) ?
        reference.best_by_rank[rank] : nothing
    if ordinary_loglik === nothing || ismissing(ordinary_loglik) ||
       !(ordinary_loglik isa Real) || !isfinite(ordinary_loglik)
        return (; rank, status=:not_applicable, passed=false, shortfall=missing,
                ordinary_loglik, reference_loglik=best === nothing ? missing : best.loglik)
    end
    if best === nothing || !isfinite(best.loglik)
        return (; rank, status=:unresolved, passed=false, shortfall=missing,
                ordinary_loglik=Float64(ordinary_loglik), reference_loglik=missing,
                reason="reference maximum unavailable")
    end
    shortfall = Float64(best.loglik - ordinary_loglik)
    return (; rank, status=:compared, passed=shortfall <= tolerance,
        tolerance, shortfall, ordinary_loglik=Float64(ordinary_loglik),
        reference_loglik=Float64(best.loglik), best_found=true)
end
