using Test, HSquared, LinearAlgebra, SparseArrays, Serialization, SHA

module Arc1ProfileEngineeringFixture
using LinearAlgebra, Random
include(joinpath(@__DIR__, "..", "sim", "arc1", "independent_dgp.jl"))
end

# The production module include is owned by the integration lane. This test is
# therefore runnable against the frozen source without changing src/HSquared.jl.
const ARC1_SOURCE = joinpath(@__DIR__, "..", "src", "arc1_profiles.jl")
if !isfile(ARC1_SOURCE)
    @testset "Arc1 profile source is present" begin
        @test isfile(ARC1_SOURCE)
    end
else
    isdefined(HSquared, :_arc1_profile_context) || Base.include(HSquared, ARC1_SOURCE)
const H = HSquared

struct Arc1PostRunCallbackResult
    minimizer::Vector{Float64}
    stopped_by::NamedTuple
    termination_code::Symbol
    iterations::Int
end
H.Optim.minimizer(result::Arc1PostRunCallbackResult) = result.minimizer
H.Optim.converged(::Arc1PostRunCallbackResult) = true

struct Arc1NativePostRunCallbackResult
    minimizer::Vector{Float64}
    stopped_by::NamedTuple
    termination_code::Any
    iterations::Int
end
H.Optim.minimizer(result::Arc1NativePostRunCallbackResult) = result.minimizer
H.Optim.converged(::Arc1NativePostRunCallbackResult) = true

function _arc1_test_data()
    na = 6
    n = 2na
    z = sparse(1:n, repeat(1:na, inner = 2), ones(n), n, na)
    A = Matrix{Float64}(I, na, na)
    for i in 2:na
        A[i, i - 1] = A[i - 1, i] = 0.16
    end
    Ainv = inv(A)
    X = hcat(ones(n), collect(range(-1.0, 1.0; length = n)))
    y = [0.4 + 0.2 * i + 0.1 * sin(1.7i) + 0.3 * (-1)^i for i in 1:n]
    return y, X, z, Ainv, A
end

function _arc1_dense_reml_oracle(y, X, Z, A, Va, Vpe, Ve)
    V = Va .* (Z * A * Z') + Vpe .* (Z * Z') + Ve .* Matrix{Float64}(I, length(y), length(y))
    F = cholesky(Symmetric(Matrix(V)); check = true)
    ViX = F \ X
    Viy = F \ y
    C = Symmetric(X' * ViX)
    FC = cholesky(C; check = true)
    beta = FC \ (X' * Viy)
    residual = y - X * beta
    q = dot(residual, F \ residual)
    logdet_v = 2sum(log, diag(F.L))
    logdet_c = 2sum(log, diag(FC.L))
    n, p = length(y), size(X, 2)
    return (loglik = -0.5 * (logdet_v + logdet_c + q), beta = beta)
end

function _arc1_bigfloat_dense_reml_oracle(y, X, Z, A, Va, Vpe, Ve)
    by, bX, bZ, bA = BigFloat.(y), BigFloat.(X), BigFloat.(Matrix(Z)), BigFloat.(A)
    n = length(by)
    V = BigFloat(Va) .* (bZ * bA * bZ') + BigFloat(Vpe) .* (bZ * bZ') +
        BigFloat(Ve) .* Matrix{BigFloat}(I, n, n)
    F = cholesky(Symmetric(V))
    ViX, Viy = F \ bX, F \ by
    FC = cholesky(Symmetric(bX' * ViX))
    beta = FC \ (bX' * Viy)
    residual = by - bX * beta
    q = dot(residual, F \ residual)
    loglik = -BigFloat(0.5) * (2sum(log, diag(F.L)) +
                               2sum(log, diag(FC.L)) + q)
    return (loglik = Float64(loglik), beta = Float64.(beta))
end

@testset "Arc1 repeatability profile exact objective" begin
    y, X, Z, Ainv, A = _arc1_test_data()
    context = H._arc1_profile_context(y, X, Z, Ainv)

    @testset "v3 double-zero corner certificate uses native continuation evidence" begin
        df, s0, ve = 20.0, 1.0, 1.25
        full_score(c) = (-100.0 - 0.01c[1] - 0.02c[2], :ok)
        centered_score(c) = (; loglik=first(full_score(c)) - 2.0, status=:ok)
        gradient_score(c; free_indices=1:3) = begin
            ll, _ = full_score(c)
            g = [0.01 / df, 0.02 / df, 0.0]
            (; loglik=ll, component_gradient=g, log_gradient=g[free_indices] .* c[free_indices])
        end
        native_pair(first_contact, second_contact; original_iterations=3,
                    continuation_iterations=1, changes=NamedTuple()) = begin
            floor = s0 * 2.0^-40
            original_components = [0.01, 0.02, ve]
            original_components[first_contact] = floor
            original_contact = (component=first_contact, side=:lower,
                value=floor, log_value=log(floor))
            continuation_components = copy(original_components)
            continuation_components[second_contact] = floor
            original_ll, _ = full_score(original_components)
            continuation_ll, _ = full_score(continuation_components)
            original = merge((loglik=original_ll, max_valid_loglik=original_ll,
                centered_loglik=original_ll-2, max_valid_centered_loglik=original_ll-2,
                centering_ve=ve, components=original_components, converged=false,
                optimizer_converged=true, optimizer_status="converged",
                termination_code=H.Optim.TerminationCode.NoObjectiveChange,
                analytic_gradient_valid=true, line_search_failed=false,
                iterations=original_iterations, free_indices=[1,2],
                finite_difference_errors=Dict(first_contact=>Inf, second_contact=>0.0),
                gradient_norm=1e-2, hit_bound=true,
                hit_bound_components=[original_contact]), changes)
            continuation_contact = (component=second_contact, side=:lower,
                value=floor, log_value=log(floor))
            continuation = (loglik=continuation_ll, max_valid_loglik=continuation_ll,
                centered_loglik=continuation_ll-2,
                max_valid_centered_loglik=continuation_ll-2, centering_ve=ve,
                components=continuation_components, converged=false,
                optimizer_converged=true, optimizer_status="converged",
                termination_code=H.Optim.TerminationCode.GradientNorm,
                analytic_gradient_valid=true, line_search_failed=false,
                iterations=continuation_iterations, free_indices=[second_contact],
                finite_difference_errors=Dict(second_contact=>Inf),
                gradient_norm=1e-12, hit_bound=true,
                hit_bound_components=[continuation_contact])
            # The retained producer face is the exact intersection [0, 0, Ve],
            # independently optimized from the original positive candidate.
            face_components=[0.0,0.0,ve]
            face_ll, _=full_score(face_components)
            face=(status=:ok,zero_index=first_contact,components=face_components,
                loglik=face_ll,centered_loglik=face_ll-2,max_valid_loglik=face_ll,
                max_valid_centered_loglik=face_ll-2,centering_ve=ve)
            corner=[0.0,0.0,ve]; corner_ll,_=full_score(corner)
            intersection=(status=:ok,components=corner,loglik=corner_ll,
                centered_loglik=corner_ll-2,max_valid_loglik=corner_ll,
                max_valid_centered_loglik=corner_ll-2,centering_ve=ve)
            certificate=(status=:face_likelihood_mismatch,zero_indices=[first_contact],
                centered_active=true,likelihood_spread=abs(original_ll-face_ll),
                # This is a controlled native-shaped mismatch witness. Its
                # optimizer score is deliberately distinct from the exact
                # fixed-Ve face score, as required by v2 eligibility.
                likelihood_spread_centered=2e-8,
                centering_ve=ve,
                candidate_max_valid_centered_loglik=original_ll-2,
                components=face_components,loglik=face_ll)
            (;original,continuation,face,intersection,certificate,corner)
        end
        @testset "both native lower-contact orders resolve only the physical corner" begin
            for (first_contact,second_contact) in ((1,2),(2,1))
                f=native_pair(first_contact,second_contact)
                full_max=Ref(f.original.max_valid_loglik)
                centered_max=Ref(f.original.max_valid_centered_loglik)
                result=H._arc1_profile_v3_double_zero_corner_certificate(
                    f.original,f.continuation,3,s0,df,[f.face],f.intersection,
                    f.certificate,components->full_score(components),
                    (components;free_indices)->gradient_score(components;free_indices),
                    centered_score,ve;maximum_seen=full_max,
                    centered_maximum_seen=centered_max)
                @test result.status == :resolved_double_zero_corner
                @test result.components == f.corner
                @test result.loglik == first(full_score(f.corner))
                @test result.centered_loglik == centered_score(f.corner).loglik
                @test result.original_native.converged === false
                @test result.returned_native.converged === false
                @test result.original_native.termination_code ===
                    H.Optim.TerminationCode.NoObjectiveChange
                @test result.returned_native.termination_code ===
                    H.Optim.TerminationCode.GradientNorm
                @test result.iterations == (original=3, continuation=1, combined=4, allowance=1997)
                @test length(result.forward_differences) == 6
                @test all(r->r.centered_estimate > 0,
                    result.forward_differences)
                @test result.centered_score_spread <= 1e-8
                @test full_max[] >= result.loglik
                @test centered_max[] >= result.centered_loglik
            end
        end

        @testset "native metadata, budget, and physical checks fail closed" begin
            f=native_pair(1,2)
            run(f;kwargs...) = H._arc1_profile_v3_double_zero_corner_certificate(
                f.original,f.continuation,3,s0,df,[f.face],f.intersection,
                f.certificate,components->full_score(components),
                (components;free_indices)->gradient_score(components;free_indices),
                centered_score,ve;maximum_seen=Ref(f.original.max_valid_loglik),
                centered_maximum_seen=Ref(f.original.max_valid_centered_loglik),kwargs...)
            wrong_enum=merge(f.continuation,(termination_code=:gradient_converged,))
            @test run(merge(f,(continuation=wrong_enum,))).status == :continuation_native_record_invalid
            @test run(merge(f,(continuation=merge(f.continuation,(converged=true,)),))).status == :continuation_native_record_invalid
            @test run(merge(f,(continuation=merge(f.continuation,(iterations=1998,)),))).status == :combined_budget_exceeded
            changed_held=copy(f.continuation.components); changed_held[1]+=eps()
            @test run(merge(f,(continuation=merge(f.continuation,(components=changed_held,)),))).status == :held_component_changed
            extra_contact=merge(f.continuation,(;hit_bound_components=[f.continuation.hit_bound_components[1],
                (component=3,side=:lower,value=0.0,log_value=-Inf)]))
            @test run(merge(f,(continuation=extra_contact,))).status == :continuation_native_record_invalid
            negative_infinite_fd=merge(f.continuation,
                (;finite_difference_errors=Dict(2=>-Inf)))
            @test run(merge(f,(continuation=negative_infinite_fd,))).status ==
                :continuation_contact_fd_mismatch
            negative_norm_original=merge(f.original,(;gradient_norm=-1.0))
            @test H._arc1_profile_v3_original_status(negative_norm_original,
                f.certificate,3,s0,[f.face],ve) == :original_gradient_norm_invalid
            negative_original_fd=merge(f.original,(;finite_difference_errors=
                Dict(1=>-Inf,2=>0.0)))
            @test H._arc1_profile_v3_original_status(negative_original_fd,
                f.certificate,3,s0,[f.face],ve) != :eligible
            bad_gradient=(components;free_indices)->merge(gradient_score(components;free_indices),
                (;component_gradient=[5e-6/s0,0.02/df,0.0]))
            @test H._arc1_profile_v3_double_zero_corner_certificate(f.original,f.continuation,
                3,s0,df,[f.face],f.intersection,f.certificate,components->full_score(components),
                bad_gradient,centered_score,ve;maximum_seen=Ref(-Inf),
                centered_maximum_seen=Ref(-Inf)).status == :active_derivative_not_positive
            wrong_certificate_ve=merge(f.certificate,(;centering_ve=ve+eps(ve)))
            @test H._arc1_profile_v3_native_pair_status(f.original,f.continuation,
                3,s0,df,wrong_certificate_ve,[f.face],ve) ==
                    :initial_certificate_centering_tag_mismatch
            wrong_zero=merge(f.certificate,(;zero_indices=[3]))
            @test H._arc1_profile_v3_native_pair_status(f.original,f.continuation,
                3,s0,df,wrong_zero,[f.face],ve) == :original_native_record_invalid
            bad_probe(c)=begin
                ll,_=full_score(c)
                c[1] == s0*1e-4 && c[2] == 0.0 ?
                    (first(full_score(f.corner))+2e-7,:ok) : (ll,:ok)
            end
            bad_centered_probe(c)=begin
                ll,status=bad_probe(c)
                (;loglik=ll-2.0,status)
            end
            rejected=H._arc1_profile_v3_double_zero_corner_certificate(
                f.original,f.continuation,3,s0,df,[f.face],f.intersection,f.certificate,
                bad_probe,(components;free_indices)->gradient_score(components;free_indices),
                bad_centered_probe,ve;maximum_seen=Ref(-Inf),centered_maximum_seen=Ref(-Inf))
            @test rejected.status == :better_corner_probe_likelihood
            @test rejected.max_valid_loglik > first(full_score(f.corner))
        end

        @testset "complete producer histories and saved intersection evidence are fail-closed" begin
            f=native_pair(1,2)
            run(f;kwargs...) = H._arc1_profile_v3_double_zero_corner_certificate(
                f.original,f.continuation,3,s0,df,[f.face],f.intersection,
                f.certificate,components->full_score(components),
                (components;free_indices)->gradient_score(components;free_indices),
                centered_score,ve;maximum_seen=Ref(-Inf),
                centered_maximum_seen=Ref(-Inf),kwargs...)
            better_centered=merge(f.certificate,(;candidate_max_valid_centered_loglik=
                centered_score(f.corner).loglik+2e-7))
            retained=run(merge(f,(certificate=better_centered,)))
            @test retained.status == :resolved_double_zero_corner
            @test retained.max_valid_centered_loglik ==
                centered_score(f.corner).loglik+2e-7
            untagged=Base.structdiff(better_centered,(;centering_ve=ve))
            refused=run(merge(f,(certificate=untagged,)))
            @test refused.status == :centered_history_provenance_unresolved
            @test refused.max_valid_loglik >= f.original.loglik
            @test !isempty(refused.provenance_failures)

            for bad_intersection in (
                    merge(f.intersection,(;loglik=NaN)),
                    merge(f.intersection,(;centered_loglik=NaN)),
                    merge(f.intersection,(;centering_ve=ve+1)),
                    merge(f.intersection,(;centered_loglik=f.intersection.centered_loglik+2e-8)))
                result=run(merge(f,(intersection=bad_intersection,)))
                @test result.status in (:intersection_evidence_invalid,
                    :corner_score_spread_unresolved)
            end
            missing_score=Base.structdiff(f.intersection,(centered_loglik=f.intersection.centered_loglik,))
            @test run(merge(f,(intersection=missing_score,))).status ==
                :intersection_evidence_invalid
            missing_full=Base.structdiff(f.intersection,(loglik=f.intersection.loglik,))
            @test run(merge(f,(intersection=missing_full,))).status ==
                :intersection_evidence_invalid
            nested=merge(f.face,(;physical_zero_endpoint_certificate=(;
                status=:refused,max_valid_loglik=25.0,
                max_valid_centered_loglik=centered_score(f.corner).loglik+3e-7,
                centering_ve=ve)))
            nested_result=run(merge(f,(face=nested,)))
            @test nested_result.max_valid_loglik >= 25.0
            @test nested_result.max_valid_centered_loglik >=
                centered_score(f.corner).loglik+3e-7
        end

        @testset "caller-owned evidence survives evaluator error and interrupt" begin
            f=native_pair(1,2)
            sink=Dict{Symbol,Any}()
            sink_record=H._arc1_profile_v3_sink_record!(sink,:residual_variance,ve)
            calls=Ref(0)
            interrupting_centered(c) = begin
                calls[] += 1
                throw(InterruptException())
            end
            caught=nothing
            try
                H._arc1_profile_v3_double_zero_corner_certificate(
                    f.original,f.continuation,3,s0,df,[f.face],f.intersection,
                    f.certificate,components->(first(full_score(components))+2e-7,:ok),
                    (components;free_indices)->gradient_score(components;free_indices),
                    interrupting_centered,ve;maximum_seen=Ref(-Inf),
                    centered_maximum_seen=Ref(-Inf),sink_record)
            catch err
                caught=err
            end
            @test caught isa InterruptException
            @test calls[] == 1
            @test length(sink[:arc1_profile_v3_evaluations]) == 1
            events=only(sink[:arc1_profile_v3_evaluations])[:events]
            @test length(events) == 2
            @test events[1][:status] == :returned
            @test events[1][:value] > first(full_score(f.corner))
            @test events[2][:status] == :interrupted
            @test events[2][:components] == f.continuation.components
            @test only(sink[:arc1_profile_v3_evaluations])[:max_valid_loglik] ==
                events[1][:value]
            @test only(sink[:arc1_profile_v3_evaluations])[:max_valid_centered_loglik] >=
                f.original.max_valid_centered_loglik
        end

        @testset "retained native continuation literal passes without inventing its omitted original" begin
            saved_s0=1.0213678541957403
            saved_df=319.0
            saved_ve=1.3477029634204154
            saved_floor=saved_s0*2.0^-40
            saved_original_components=[0.007718128329318392,
                9.289286519522098e-13,saved_ve]
            saved_face=(status=:ok,zero_index=2,components=[0.0,0.0,saved_ve],
                loglik=-171.35761740585306,centered_loglik=-102.0851168294925,
                max_valid_loglik=-171.35761740585306,
                max_valid_centered_loglik=-102.0851168294925,
                centering_ve=saved_ve)
            saved_initial=(status=:face_likelihood_mismatch,zero_indices=[2],
                likelihood_spread=0.09417426962855302,centered_active=true,
                likelihood_spread_centered=0.09417426962858144)
            # The serialized reduction omitted the original optimizer flags.
            # These fields are an explicit producer-shaped control, not claimed
            # as observed native flags; observed original components/contact and
            # the continuation below are copied from the retained witness.
            saved_original=(loglik=-171.45179167548162,
                max_valid_loglik=-171.4517867700702,
                centered_loglik=-102.17928619370966,
                max_valid_centered_loglik=-102.17928619370966,
                centering_ve=saved_ve,components=saved_original_components,
                converged=false,optimizer_converged=true,optimizer_status="converged",
                termination_code=H.Optim.TerminationCode.NoObjectiveChange,
                analytic_gradient_valid=true,line_search_failed=false,iterations=3,
                free_indices=[1,2],finite_difference_errors=Dict(1=>0.0,2=>Inf),
                gradient_norm=0.01,hit_bound=true,
                hit_bound_components=[(component=2,side=:lower,
                    value=9.289286519522098e-13,log_value=-27.70474445995877)])
            saved_returned=(loglik=-171.35761740586906,
                max_valid_loglik=-171.35761740586904,
                centered_loglik=-102.08511682950854,
                max_valid_centered_loglik=-102.08511682950851,
                centering_ve=saved_ve,
                components=[9.289286519522133e-13,9.289286519522098e-13,saved_ve],
                converged=false,optimizer_converged=true,optimizer_status="converged",
                termination_code=H.Optim.TerminationCode.GradientNorm,
                analytic_gradient_valid=true,line_search_failed=false,iterations=1,
                free_indices=[1],finite_difference_errors=Dict(1=>Inf),
                gradient_norm=3.2892007033503394e-14,hit_bound=true,
                hit_bound_components=[(component=1,side=:lower,
                    value=9.289286519522133e-13,log_value=-27.704744459958768)])
            @test saved_returned.hit_bound_components[1].value ==
                saved_returned.components[1] > 0
            @test saved_returned.hit_bound_components[1].value >= saved_floor
            @test H._arc1_profile_v3_native_pair_status(saved_original,saved_returned,
                3,saved_s0,saved_df,saved_initial,[saved_face],saved_ve) == :eligible
        end

        @testset "raw nuisance dispatches one v3 continuation without changing v1/v2" begin
            y0, _, Z0, Ainv0, _ = _arc1_test_data()
            na = size(Z0, 2)
            Xpaired = hcat(ones(length(y0)), repeat(collect(1.0:na), inner=2))
            ctx = H._arc1_profile_context(y0, Xpaired, Z0, Ainv0)
            fixed_ve, scale = 1.25, 1.0
            @test H._arc1_profile_fixed_ve_centering_eligible(ctx, 3, fixed_ve)
            df0 = ctx.residual_df
            floor = scale * 2.0^-40
            score(c) = H._arc1_loglik_for_components(ctx, c)
            centered(c) = H._arc1_profile_centered_loglik_at(ctx, c, fixed_ve)
            gradient(c; free_indices=1:3) =
                H._arc1_profile_objective_gradient(ctx, c; free_indices)
            counts = Dict(:bfgs=>0, :certificate=>0, :continuation=>0)
            bfgs = (context, base, free, starts, s) -> begin
                counts[:bfgs] += 1
                components = counts[:bfgs] == 1 ? [floor, 0.02, fixed_ve] :
                    [0.0, 0.0, fixed_ve]
                ll, status = score(components)
                cen = centered(components)
                counts[:bfgs] == 1 ?
                    (loglik=ll,max_valid_loglik=ll,centered_loglik=cen.loglik,
                     max_valid_centered_loglik=cen.loglik,centering_ve=fixed_ve,
                     components,converged=false,optimizer_converged=true,
                     optimizer_status="converged",
                     termination_code=H.Optim.TerminationCode.NoObjectiveChange,
                     analytic_gradient_valid=true,line_search_failed=false,
                     iterations=3,free_indices=[1,2],
                     finite_difference_errors=Dict(1=>Inf,2=>0.0),
                     gradient_norm=1e-2,hit_bound=true,
                     hit_bound_components=[(component=1,side=:lower,
                         value=floor,log_value=log(floor))]) :
                    (loglik=ll,max_valid_loglik=ll,centered_loglik=cen.loglik,
                     max_valid_centered_loglik=cen.loglik,centering_ve=fixed_ve,
                     components,converged=true,optimizer_converged=true,
                     optimizer_status="converged",
                     termination_code=H.Optim.TerminationCode.GradientNorm,
                     analytic_gradient_valid=true,line_search_failed=false,
                     iterations=1,free_indices=[1,2],
                     finite_difference_errors=Dict(1=>0.0,2=>0.0),
                     gradient_norm=0.0,hit_bound=false,
                     hit_bound_components=Any[])
            end
            scalar = (context, make_components, s; kwargs...) -> begin
                components = make_components(0.0)
                ll, status = score(components); cen = centered(components)
                (;status=:ok,value=0.0,loglik=ll,max_valid_loglik=ll,
                  centered_loglik=cen.loglik,max_valid_centered_loglik=cen.loglik,
                  centering_ve=fixed_ve,components,converged=true,
                  gradient_norm=0.0,optimizer_status="converged",hit_bound=false,
                  candidates=Any[],physical_zero_endpoint_certificate=nothing)
            end
            initial = (candidate, args...; kwargs...) -> begin
                counts[:certificate] += 1
                (;status=:face_likelihood_mismatch,zero_indices=[1],
                  likelihood_spread=0.094,centered_active=true,
                  likelihood_spread_centered=0.094,
                  centering_ve=fixed_ve,
                  candidate_max_valid_centered_loglik=candidate.max_valid_centered_loglik)
            end
            continuation = (context, base, free, start, s, allowance) -> begin
                counts[:continuation] += 1
                @test base == [floor,0.02,fixed_ve]
                @test free == [2]
                @test allowance == 1997
                components = [floor,floor,fixed_ve]
                ll,_=score(components); cen=centered(components)
                (loglik=ll,max_valid_loglik=ll,centered_loglik=cen.loglik,
                 max_valid_centered_loglik=cen.loglik,centering_ve=fixed_ve,
                 components,converged=false,optimizer_converged=true,
                 optimizer_status="converged",
                 termination_code=H.Optim.TerminationCode.GradientNorm,
                 analytic_gradient_valid=true,line_search_failed=false,
                 iterations=1,free_indices=[2],finite_difference_errors=Dict(2=>Inf),
                 gradient_norm=1e-12,hit_bound=true,
                 hit_bound_components=[(component=2,side=:lower,
                    value=floor,log_value=log(floor))])
            end
            common = (;bfgs_runner=bfgs,scalar_profile_runner=scalar,
                loglik_runner=(context,components)->score(components),
                gradient_runner=(context,components;free_indices=1:3)->
                    gradient(components;free_indices),certificate_runner=initial,
                refinement_runner=continuation)

            v1=H._arc1_raw_nuisance(ctx,:residual_variance,fixed_ve,scale;
                common...,method_version=:arc1_profile_v1)
            @test v1.method_version == :arc1_profile_v1
            @test counts[:continuation] == 0
            counts[:bfgs]=0; counts[:certificate]=0
            v2=H._arc1_raw_nuisance(ctx,:residual_variance,fixed_ve,scale;
                common...,method_version=:arc1_profile_v2)
            @test v2.method_version == :arc1_profile_v2
            @test counts[:continuation] == 1
            counts[:bfgs]=0; counts[:certificate]=0; counts[:continuation]=0
            raw_sink=Dict{Symbol,Any}(
                :requested_method_version=>"arc1_profile_v3",
                :actual_method_version=>"arc1_profile_v3")
            v3=H._arc1_raw_nuisance(ctx,:residual_variance,fixed_ve,scale;
                common...,method_version=:arc1_profile_v3,
                v3_evidence_sink=raw_sink)
            @test v3.method_version == :arc1_profile_v3
            @test v3.status == :ok
            @test counts[:continuation] == 1
            raw=only(filter(x->x.kind==:raw_nuisance_search,v3.nuisance_statuses))
            @test raw.resolved_by_double_zero_corner == 1
            @test only(raw.lower_bound_resolutions).double_zero_corner_certificate.status ==
                :resolved_double_zero_corner
            @test only(raw.lower_bound_resolutions).
                double_zero_corner_certificate.returned_native.converged === false
            @test raw_sink[:requested_method_version] == "arc1_profile_v3"
            @test raw_sink[:actual_method_version] == "arc1_profile_v3"
            @test !isempty(raw_sink[:arc1_profile_v3_evaluations])
            @test all(ev->ev[:target]==:residual_variance &&
                ev[:fixed_value]==fixed_ve && ev[:status] in (:ok,:nuisance_unresolved),
                raw_sink[:arc1_profile_v3_evaluations])
            @test any(ev->!isempty(ev[:producer_history]),
                raw_sink[:arc1_profile_v3_evaluations])
            corner_gradient = only(filter(event ->
                get(event, :source_kind, nothing) === :gradient,
                raw_sink[:arc1_profile_v3_evaluations][1][:events]))
            @test corner_gradient[:kind] === :full
            @test corner_gradient[:evaluation_valid] === true
            @test corner_gradient[:value] isa Real
            @test get(raw_sink[:arc1_profile_v3_evaluations][1],
                :max_valid_loglik, -Inf) >= corner_gradient[:value]

            nested_scalar = (context,make_components,s;kwargs...) -> begin
                face=scalar(context,make_components,s;kwargs...)
                endpoint=(status=:nuisance_unresolved,max_valid_loglik=100.0,
                    max_valid_centered_loglik=face.centered_loglik+2e-7,
                    centering_ve=fixed_ve)
                merge(face,(;physical_zero_endpoint_certificate=endpoint))
            end
            nested_v3=H._arc1_raw_nuisance(ctx,:residual_variance,fixed_ve,scale;
                common...,scalar_profile_runner=nested_scalar,
                method_version=:arc1_profile_v3)
            @test nested_v3.status == :nuisance_unresolved
            @test nested_v3.max_valid_loglik >= 100.0
            @test nested_v3.max_valid_centered_loglik > nested_v3.centered_loglik+1e-8

            counts[:bfgs]=0; counts[:certificate]=0; counts[:continuation]=0
            bad_original_bfgs = (args...) -> begin
                candidate = bfgs(args...)
                counts[:bfgs] == 1 ? merge(candidate,(;iterations=true)) : candidate
            end
            bad_v3=H._arc1_raw_nuisance(ctx,:residual_variance,fixed_ve,scale;
                common...,bfgs_runner=bad_original_bfgs,method_version=:arc1_profile_v3)
            @test counts[:continuation] == 0
            bad_raw=only(filter(x->x.kind==:raw_nuisance_search,bad_v3.nuisance_statuses))
            @test any(x->x.status==:original_iteration_count_invalid,
                bad_raw.lower_bound_resolutions)
        end
    end

    if get(ENV, "ARC1_PROFILE_V3_ONLY", "0") != "1"

    @testset "explicit v2 refinement eligibility uses native optimizer fields" begin
        native = H._arc1_bfgs_candidate(context, [1.0, 0.0, 0.0], [2, 3],
            [2.0^-40, 1.0], 1.0;
            optimizer_runner = (objective, gradient!, start) ->
                Arc1NativePostRunCallbackResult(copy(start), (ls_failed = false,),
                    H.Optim.TerminationCode.NoObjectiveChange, 13))
        @test native.optimizer_status == "converged"
        @test native.termination_code == H.Optim.TerminationCode.NoObjectiveChange
        @test native.optimizer_converged
        @test !native.line_search_failed
        @test !native.converged
        @test native.hit_bound_components ==
            [(component = 2, side = :lower, value = native.components[2],
              log_value = log(2.0^-40))]

        face = (status = :ok, zero_index = 2, loglik = -10.0,
            components = [0.7, 0.0, 0.9])
        candidate = (loglik = -10.0 - 2e-7, max_valid_loglik = -10.0 - 2e-7,
            components = [0.7, 1e-13, 0.9], converged = false,
            optimizer_converged = true, optimizer_status = "converged",
            termination_code = H.Optim.TerminationCode.NoObjectiveChange,
            analytic_gradient_valid = true, line_search_failed = false,
            iterations = 13, free_indices = [2, 3],
            finite_difference_errors = Dict(2 => Inf, 3 => 4e-6),
            hit_bound = true,
            hit_bound_components = [(component = 2, side = :lower, value = 1e-13)])
        initial = (status = :face_likelihood_mismatch,
            zero_indices = [2], likelihood_spread = 2e-7,
            centered_active = false, likelihood_spread_centered = NaN)
        @test H._arc1_profile_v2_refinement_eligible(candidate, initial, 1, [face])
        @test !H._arc1_profile_v2_refinement_eligible(
            merge(candidate, (termination_code = :gradient_converged,)), initial, 1, [face])
        @test !H._arc1_profile_v2_refinement_eligible(
            merge(candidate, (optimizer_converged = false,)), initial, 1, [face])
        @test !H._arc1_profile_v2_refinement_eligible(
            merge(candidate, (line_search_failed = true,)), initial, 1, [face])
        @test !H._arc1_profile_v2_refinement_eligible(
            merge(candidate, (finite_difference_errors = Dict(2 => Inf, 3 => 5.1e-6),)),
            initial, 1, [face])
        @test !H._arc1_profile_v2_refinement_eligible(
            merge(candidate, (hit_bound_components = [(component = 2, side = :upper,
                value = 1e-13)],)), initial, 1, [face])
        @test_throws ArgumentError H._arc1_raw_nuisance(
            (residual_df = 5,), :additive_variance, 1.0, 1.0;
            method_version = :unknown)
    end

    @testset "v2 positive-bound continuation is one fixed-coordinate certified step" begin
        df, s0 = 20.0, 1.0
        objective(components) = begin
            ll = -100.0 - 0.02 * components[2] - (components[3] - 1.0)^2
            (ll, :ok)
        end
        gradient(components; free_indices) = begin
            component_gradient = [0.0, 0.02 / df,
                2 * (components[3] - 1.0) / df]
            ll, _ = objective(components)
            (loglik = ll, component_gradient = component_gradient,
             log_gradient = component_gradient[free_indices] .* components[free_indices])
        end
        face = (status = :ok, zero_index = 2, loglik = -100.0,
            components = [1.0, 0.0, 1.0])
        candidate = (candidate_index = 8, loglik = first(objective([1.0, 1e-13, 1.01])),
            max_valid_loglik = first(objective([1.0, 1e-13, 1.01])),
            components = [1.0, 1e-13, 1.01], converged = false,
            optimizer_converged = true, optimizer_status = "converged",
            termination_code = H.Optim.TerminationCode.NoObjectiveChange,
            analytic_gradient_valid = true, line_search_failed = false,
            gradient_norm = 0.02, iterations = 13, free_indices = [2, 3],
            finite_difference_errors = Dict(2 => Inf, 3 => 0.0), hit_bound = true,
            hit_bound_components = [(component = 2, side = :lower, value = 1e-13)])
        initial = (status = :face_likelihood_mismatch, zero_indices = [2],
            centered_active = false,
            likelihood_spread = abs(candidate.loglik - face.loglik),
            max_valid_loglik = candidate.max_valid_loglik)
        continuation_calls = Ref(0)
        runner = (ctx, base, free, start, scale, allowance) -> begin
            continuation_calls[] += 1
            @test base == [1.0, 1e-13, 1.01]
            @test free == [3]
            @test start == [1.01]
            @test allowance == 1987
            ll, _ = objective([1.0, 1e-13, 1.0])
            (loglik = ll, max_valid_loglik = ll, components = [1.0, 1e-13, 1.0],
             free_indices = [3], converged = true, gradient_norm = 0.0,
             optimizer_converged = true, analytic_gradient_valid = true,
             line_search_failed = false, finite_difference_errors = Dict(3 => 0.0),
             hit_bound = false, hit_bound_components = Any[], iterations = 1,
             termination_code = H.Optim.TerminationCode.GradientNorm,
             optimizer_status = "converged", objective_evaluations = 4,
             gradient_evaluations = 2)
        end
        seen = Ref(candidate.max_valid_loglik)
        refined = H._arc1_positive_bound_refinement((residual_df = df,), candidate,
            1, s0, df, [face], nothing, initial, objective, gradient;
            maximum_seen = seen, continuation_runner = runner)
        @test refined.status == :resolved_positive_bound_refine
        @test refined.components == face.components
        @test refined.loglik == face.loglik
        @test refined.continuation.original_iterations == 13
        @test refined.continuation.continuation_iterations == 1
        @test refined.continuation.combined_iterations == 14
        @test continuation_calls[] == 1
        @test seen[] == face.loglik

        better_history = merge(candidate, (max_valid_loglik = face.loglik + 2e-8,))
        history_seen = Ref(better_history.max_valid_loglik)
        blocked = H._arc1_positive_bound_refinement((residual_df = df,), better_history,
            1, s0, df, [face], nothing, initial, objective, gradient;
            maximum_seen = history_seen, continuation_runner = runner)
        @test blocked.status == :candidate_maximum_mismatch
        @test blocked.continuation.max_valid_loglik == face.loglik + 2e-8

        exhausted = merge(candidate, (iterations = 2000,))
        exhausted_calls = Ref(0)
        no_budget = H._arc1_positive_bound_refinement((residual_df = df,), exhausted,
            1, s0, df, [face], nothing, initial, objective, gradient;
            maximum_seen = Ref(exhausted.max_valid_loglik),
            continuation_runner = (args...) -> (exhausted_calls[] += 1))
        @test no_budget.status == :not_eligible
        @test exhausted_calls[] == 0

        # A valid full-likelihood maximum survives a continuation exception;
        # only a correctly tagged same-Ve centered maximum is admitted.
        centered_candidate = merge(candidate, (components = [1e-13, 0.5, 0.9],
            free_indices = [1, 2],
            finite_difference_errors = Dict(1 => Inf, 2 => 0.0),
            hit_bound_components = [(component = 1, side = :lower, value = 1e-13)],
            max_valid_loglik = -4.5, centered_loglik = 1.0,
            max_valid_centered_loglik = 2.0, centering_ve = 0.9))
        centered_face = (status = :ok, zero_index = 1, loglik = -5.0,
            components = [0.0, 0.5, 0.9], centered_loglik = 1.0,
            max_valid_centered_loglik = 1.0, centering_ve = 0.9)
        wrong_tag_certificate = (status = :face_likelihood_mismatch,
            zero_indices = [1], centered_active = false, likelihood_spread = 2e-7,
            max_valid_loglik = -4.0, max_valid_centered_loglik = 10.0,
            centering_ve = 0.8)
        full_history = Ref(-5.0)
        centered_history = Ref(-Inf)
        exception = H._arc1_positive_bound_refinement((residual_df = df,),
            centered_candidate, 3, s0, df, [centered_face], nothing,
            wrong_tag_certificate, objective, gradient;
            maximum_seen = full_history, centered_maximum_seen = centered_history,
            centered_loglik_at = components -> (1.0, :ok), centering_ve = 0.9,
            continuation_runner = (args...) -> error("controlled v2 continuation error"))
        @test exception.status == :continuation_exception
        @test full_history[] == -4.0
        @test centered_history[] == 2.0
        @test exception.continuation.max_valid_loglik == -4.0
        @test exception.continuation.max_valid_centered_loglik == 2.0
        @test exception.continuation.original_native_max_valid_centered_loglik == 2.0
        @test exception.continuation.original_native_centering_ve == 0.9

        failed_return = H._arc1_positive_bound_refinement((residual_df = df,), candidate,
            1, s0, df, [face], nothing, initial, objective, gradient;
            maximum_seen = Ref(candidate.max_valid_loglik),
            continuation_runner = (ctx, base, free, start, scale, allowance) ->
                (loglik = -100.0, components = [1.0, 1e-13, 1.0], iterations = 7,
                 free_indices = [3], converged = false, optimizer_converged = false,
                 gradient_norm = 2e-5, analytic_gradient_valid = true,
                 line_search_failed = false, finite_difference_errors = Dict(3 => 0.0),
                 hit_bound_components = Any[], optimizer_status = "not_converged"))
        @test failed_return.status == :continuation_unresolved
        @test failed_return.continuation.continuation_iterations == 7
        @test failed_return.continuation.combined_iterations == 20
    end

    @testset "raw nuisance enters positive-bound refinement only for explicit v2" begin
        df = 20.0
        mock = (residual_df = df,)
        objective(components) = (-100.0 - 0.02 * components[2] -
            (components[3] - 1.0)^2, :ok)
        gradient(components; free_indices = 1:3) = begin
            component_gradient = [0.0, 0.02 / df,
                2 * (components[3] - 1.0) / df]
            ll, _ = objective(components)
            (loglik = ll, component_gradient = component_gradient,
             log_gradient = component_gradient[free_indices] .* components[free_indices])
        end
        bfgs_calls, certificate_calls, refinement_calls = Ref(0), Ref(0), Ref(0)
        bfgs = (ctx, base, free, starts, scale) -> begin
            bfgs_calls[] += 1
            if bfgs_calls[] == 1
                components = [1.0, 1e-13, 1.01]
                ll, _ = objective(components)
                return (loglik = ll, max_valid_loglik = ll, components,
                    converged = false, optimizer_converged = true,
                    optimizer_status = "converged",
                    termination_code = H.Optim.TerminationCode.NoObjectiveChange,
                    analytic_gradient_valid = true, line_search_failed = false,
                    gradient_norm = 0.02, iterations = 13, free_indices = [2, 3],
                    finite_difference_errors = Dict(2 => Inf, 3 => 0.0),
                    hit_bound = true,
                    hit_bound_components = [(component = 2, side = :lower,
                        value = 1e-13)])
            end
            components = [1.0, 0.5, 0.5]
            ll, _ = objective(components)
            (loglik = ll, max_valid_loglik = ll, components, converged = true,
             optimizer_status = "converged", hit_bound = false,
             hit_bound_components = Any[], gradient_norm = 0.0)
        end
        scalar = (ctx, make_components, scale; kwargs...) -> begin
            zero_index = kwargs[:held_zero_component]
            value = zero_index == 2 ? 1.0 : 0.5
            components = make_components(value)
            ll, _ = objective(components)
            (status = :ok, value, loglik = ll, max_valid_loglik = ll,
             components, converged = true, gradient_norm = 0.0,
             optimizer_status = "converged", hit_bound = false, candidates = Any[],
             physical_zero_endpoint_certificate = nothing)
        end
        initial_certificate = (candidate, args...) -> begin
            certificate_calls[] += 1
            (status = :face_likelihood_mismatch, zero_indices = [2],
             likelihood_spread = abs(candidate.loglik + 100.0),
             centered_active = false, max_valid_loglik = candidate.max_valid_loglik)
        end
        refinement = (ctx, base, free, start, scale, allowance) -> begin
            refinement_calls[] += 1
            @test base == [1.0, 1e-13, 1.01]
            @test free == [3]
            @test start == [1.01]
            @test allowance == 1987
            components = [1.0, 1e-13, 1.0]
            ll, _ = objective(components)
            (loglik = ll, max_valid_loglik = ll, components, free_indices = [3],
             converged = true, optimizer_converged = true,
             optimizer_status = "converged", termination_code = H.Optim.TerminationCode.GradientNorm,
             gradient_norm = 0.0, analytic_gradient_valid = true,
             line_search_failed = false, finite_difference_errors = Dict(3 => 0.0),
             hit_bound = false, hit_bound_components = Any[], iterations = 1,
             objective_evaluations = 4, gradient_evaluations = 2)
        end
        common = (; bfgs_runner = bfgs, scalar_profile_runner = scalar,
            loglik_runner = (ctx, components) -> objective(components),
            gradient_runner = (ctx, components; free_indices = 1:3) ->
                gradient(components; free_indices),
            certificate_runner = initial_certificate, refinement_runner = refinement)
        v1 = H._arc1_raw_nuisance(mock, :additive_variance, 1.0, 1.0;
            common..., method_version = :arc1_profile_v1)
        @test v1.method_version == :arc1_profile_v1
        @test v1.status in (:ok, :nuisance_unresolved)
        @test refinement_calls[] == 0
        @test certificate_calls[] == 1
        bfgs_calls[] = 0
        certificate_calls[] = 0
        default = H._arc1_raw_nuisance(mock, :additive_variance, 1.0, 1.0;
            common...)
        @test default.method_version == :arc1_profile_v1
        @test default.status == v1.status
        @test default.loglik == v1.loglik
        @test default.max_valid_loglik == v1.max_valid_loglik
        @test refinement_calls[] == 0
        bfgs_calls[] = 0
        certificate_calls[] = 0
        v2 = H._arc1_raw_nuisance(mock, :additive_variance, 1.0, 1.0;
            common..., method_version = :arc1_profile_v2)
        @test v2.method_version == :arc1_profile_v2
        @test v2.status == :ok
        @test only(filter(x -> x.kind == :raw_nuisance_search,
            v2.nuisance_statuses)).resolved_by_positive_bound_refine == 1
        @test refinement_calls[] == 1
        @test certificate_calls[] == 1
        @test v2.max_valid_loglik == -100.0
    end

    @testset "v2 rejects superior refinement history and rechecks projected free gradients" begin
        df = 20.0
        mock = (residual_df = df,)
        mode = Ref(:plain)
        objective(components) = begin
            ll = -100.0 - 0.02 * components[2] - (components[3] - 1.0)^2
            if mode[] == :late_history && components[3] == 1.0
                components[2] == 1e-4 && (ll = -100.0 + 2e-7)
                components[2] == 2e-4 && (ll = -100.0 + 4.8e-6)
            elseif mode[] == :projected_fd && components[2] == 0.0
                ll -= 0.01 * (components[3] - 1.0)
            end
            (ll, :ok)
        end
        gradient(components; free_indices = 1:3) = begin
            component_gradient = [0.0, 0.02 / df,
                2 * (components[3] - 1.0) / df]
            ll, _ = objective(components)
            (loglik = ll, component_gradient = component_gradient,
             log_gradient = component_gradient[free_indices] .* components[free_indices])
        end
        bfgs_calls, certificate_calls, refinement_calls, polish_calls =
            Ref(0), Ref(0), Ref(0), Ref(0)
        bfgs = (ctx, base, free, starts, scale) -> begin
            bfgs_calls[] += 1
            components = bfgs_calls[] == 1 ? [1.0, 1e-13, 1.01] : [1.0, 0.5, 0.5]
            ll, _ = objective(components)
            if bfgs_calls[] == 1
                return (loglik = ll, max_valid_loglik = ll, components,
                    converged = false, optimizer_converged = true,
                    optimizer_status = "converged",
                    termination_code = H.Optim.TerminationCode.NoObjectiveChange,
                    analytic_gradient_valid = true, line_search_failed = false,
                    gradient_norm = 0.02, iterations = 13, free_indices = [2, 3],
                    finite_difference_errors = Dict(2 => Inf, 3 => 0.0),
                    hit_bound = true,
                    hit_bound_components = [(component = 2, side = :lower,
                        value = 1e-13)])
            end
            (loglik = ll, max_valid_loglik = ll, components, converged = true,
             optimizer_status = "converged", hit_bound = false,
             hit_bound_components = Any[], gradient_norm = 0.0)
        end
        scalar = (ctx, make_components, scale; kwargs...) -> begin
            zero_index = kwargs[:held_zero_component]
            value = zero_index == 2 ? 1.0 : 0.5
            components = make_components(value)
            ll, _ = objective(components)
            (status = :ok, value, loglik = ll, max_valid_loglik = ll,
             components, converged = true, gradient_norm = 0.0,
             optimizer_status = "converged", hit_bound = false, candidates = Any[],
             physical_zero_endpoint_certificate = nothing)
        end
        refinement = (ctx, base, free, start, scale, allowance) -> begin
            refinement_calls[] += 1
            components = [1.0, 1e-13, 1.0]
            ll, _ = objective(components)
            (loglik = ll, max_valid_loglik = ll, components, free_indices = [3],
             converged = true, optimizer_converged = true,
             optimizer_status = "converged",
             termination_code = H.Optim.TerminationCode.GradientNorm,
             gradient_norm = 0.0, analytic_gradient_valid = true,
             line_search_failed = false, finite_difference_errors = Dict(3 => 0.0),
             hit_bound = false, hit_bound_components = Any[], iterations = 1,
             objective_evaluations = 4, gradient_evaluations = 2)
        end
        common = (; bfgs_runner = bfgs, scalar_profile_runner = scalar,
            loglik_runner = (ctx, components) -> objective(components),
            gradient_runner = (ctx, components; free_indices = 1:3) ->
                gradient(components; free_indices), refinement_runner = refinement)

        mode[] = :late_history
        bfgs_calls[] = 0; certificate_calls[] = 0; refinement_calls[] = 0
        late_certificate = (candidate, args...) -> begin
            certificate_calls[] += 1
            if certificate_calls[] == 1
                return (status = :face_likelihood_mismatch, zero_indices = [2],
                    likelihood_spread = 2e-7, centered_active = false,
                    max_valid_loglik = candidate.max_valid_loglik)
            end
            H._arc1_zero_bound_face_certificate(candidate, args...)
        end
        late = H._arc1_raw_nuisance(mock, :additive_variance, 1.0, 1.0;
            common..., certificate_runner = late_certificate,
            method_version = :arc1_profile_v2)
        late_search = only(filter(x -> x.kind == :raw_nuisance_search,
            late.nuisance_statuses))
        @test late.status == :nuisance_unresolved
        @test late.max_valid_loglik > late.loglik + 1e-8
        @test late_search.resolved_by_positive_bound_refine == 1
        @test late_search.unresolved_competitor

        mode[] = :projected_fd
        bfgs_calls[] = 0; certificate_calls[] = 0; refinement_calls[] = 0
        projected_certificate = (candidate, index, scale, residual_df, faces,
                                 intersection, loglik_at, gradient_at; kwargs...) -> begin
            certificate_calls[] += 1
            certificate_calls[] == 1 && return (status = :face_likelihood_mismatch,
                zero_indices = [2], likelihood_spread = 2e-7,
                centered_active = false, max_valid_loglik = candidate.max_valid_loglik)
            H._arc1_zero_bound_face_certificate(candidate, index, scale, residual_df,
                faces, intersection, loglik_at, gradient_at; kwargs...)
        end
        projected = H._arc1_raw_nuisance(mock, :additive_variance, 1.0, 1.0;
            common..., certificate_runner = projected_certificate,
            method_version = :arc1_profile_v2)
        projected_search = only(filter(x -> x.kind == :raw_nuisance_search,
            projected.nuisance_statuses))
        @test projected.status == :nuisance_unresolved
        @test projected_search.resolved_by_positive_bound_refine == 0
        @test any(x -> hasproperty(x, :status) &&
            x.status == :remaining_finite_difference_unresolved,
            projected_search.lower_bound_resolutions)

        mode[] = :chain
        bfgs_calls[] = 0; certificate_calls[] = 0; refinement_calls[] = 0
        polish_runner = (args...; kwargs...) -> begin
            polish_calls[] += 1
            (; status = :projected_gradient_unresolved,
               continuation = (; status = :projected_gradient_unresolved))
        end
        chained_certificate = (candidate, index, scale, residual_df, faces,
                              intersection, loglik_at, gradient_at; kwargs...) -> begin
            certificate_calls[] += 1
            certificate_calls[] == 1 ?
                (status = :face_likelihood_mismatch, zero_indices = [2],
                 likelihood_spread = 2e-7, centered_active = false,
                 max_valid_loglik = candidate.max_valid_loglik) :
                (status = :projected_gradient_unresolved, zero_indices = [2],
                 max_valid_loglik = candidate.max_valid_loglik)
        end
        chain_gradient = (ctx, components; free_indices = 1:3) -> begin
            result = gradient(components; free_indices)
            if components[2] == 0.0
                derivative = copy(result.component_gradient)
                derivative[3] = 2e-6 / components[3]
                result = merge(result, (component_gradient = derivative,
                    log_gradient = derivative[free_indices] .* components[free_indices]))
            end
            result
        end
        H._arc1_raw_nuisance(mock, :additive_variance, 1.0, 1.0;
            common..., gradient_runner = chain_gradient,
            certificate_runner = chained_certificate,
            polish_runner = polish_runner, method_version = :arc1_profile_v2)
        @test refinement_calls[] == 1
        @test polish_calls[] == 0
    end

    @testset "positive components agree with independent dense REML oracle" begin
        for (Va, Vpe, Ve) in ((0.3, 0.2, 0.5), (1.1, 0.05, 0.7))
            got = H._arc1_profile_reml(context, Va, Vpe, Ve)
            expected = _arc1_dense_reml_oracle(y, X, Z, A, Va, Vpe, Ve)
            @test got.status == :ok
            @test got.loglik ≈ expected.loglik atol = 1e-10
            @test got.beta ≈ expected.beta atol = 1e-10
            @test got.loglik_convention == :reml_omit_2pi
            @test !got.loglik_comparable_across_routes
        end
    end

    @testset "exact additive and permanent zero faces remain evaluable" begin
        for (Va, Vpe, Ve) in ((0.0, 0.4, 0.6), (0.3, 0.0, 0.7), (0.0, 0.0, 1.0))
            got = H._arc1_profile_reml(context, Va, Vpe, Ve)
            expected = _arc1_dense_reml_oracle(y, X, Z, A, Va, Vpe, Ve)
            @test got.status == :ok
            @test got.loglik ≈ expected.loglik atol = 1e-10
            @test got.beta ≈ expected.beta atol = 1e-10
        end
    end

    @testset "unphenotyped ancestors retain full-pedigree covariance marginal" begin
        n_animal, n_observed = 8, 6
        A_full = Matrix{Float64}(I, n_animal, n_animal) .+ 0.08
        A_observed = A_full[3:end, 3:end]
        n = 2n_observed
        Xfull = hcat(ones(n), collect(range(-1.0, 1.0; length = n)))
        yfull = [0.2 * i + 0.15 * cos(0.9i) for i in 1:n]
        observed_index = repeat(3:n_animal, inner = 2)
        Zfull = sparse(1:n, observed_index, ones(n), n, n_animal)
        Zobserved = sparse(1:n, repeat(1:n_observed, inner = 2), ones(n), n, n_observed)
        full_context = try
            H._arc1_profile_context(yfull, Xfull, Zfull, inv(A_full))
        catch
            nothing
        end
        @test full_context !== nothing
        if full_context !== nothing
            observed_context = H._arc1_profile_context(
                yfull, Xfull, Zobserved, inv(A_observed))
            full_fit = H._arc1_profile_reml(full_context, 0.3, 0.2, 0.5)
            observed_fit = H._arc1_profile_reml(observed_context, 0.3, 0.2, 0.5)
            @test full_fit.status == observed_fit.status == :ok
            @test full_fit.loglik ≈ observed_fit.loglik atol = 1e-10
        end
    end

    @testset "zero residual variance reports a singular proposal" begin
        got = H._arc1_profile_reml(context, 0.3, 0.2, 0.0)
        @test got.status == :singular_proposal
        @test !isfinite(got.loglik)
    end

    @testset "analytic total-scale profile and ratio parameterizations" begin
        proportions = (0.3, 0.2, 0.5)
        scale = H._arc1_profile_scale(context, proportions)
        V0 = proportions[1] .* (Z * A * Z') + proportions[2] .* (Z * Z') +
             proportions[3] .* Matrix{Float64}(I, length(y), length(y))
        F0 = cholesky(Symmetric(Matrix(V0)); check = true)
        ViX0, Viy0 = F0 \ X, F0 \ y
        P_y = Viy0 - ViX0 * ((X' * ViX0) \ (X' * Viy0))
        @test scale ≈ dot(y, P_y) / (length(y) - size(X, 2)) rtol = 1e-10
        h = H._arc1_components_at_ratio(:heritability, 0.25, 1.7, 0.4)
        t = H._arc1_components_at_ratio(:repeatability, 0.65, 1.7, 0.3)
        @test h == (sigma_a2 = 1.7 * 0.25,
                    sigma_pe2 = 1.7 * 0.75 * 0.4,
                    sigma_e2 = 1.7 * 0.75 * 0.6)
        @test t == (sigma_a2 = 1.7 * 0.65 * 0.3,
                    sigma_pe2 = 1.7 * 0.65 * 0.7,
                    sigma_e2 = 1.7 * 0.35)
        @test h.sigma_a2 / sum(values(h)) ≈ 0.25
        @test (t.sigma_a2 + t.sigma_pe2) / sum(values(t)) ≈ 0.65
    end

    @testset "profile likelihood is stable to large fixed-effect shifts" begin
        proportions = (0.3, 0.2, 0.5)
        shift = X * [1.0e7, -2.0e7]
        shifted_y = y + shift
        base_fit = H._arc1_profile_reml(context, proportions...)
        shifted_context = H._arc1_profile_context(shifted_y, X, Z, Ainv)
        shifted_fit = H._arc1_profile_reml(shifted_context, proportions...)
        base_scale = H._arc1_profile_scale(context, proportions)
        shifted_scale = H._arc1_profile_scale(shifted_context, proportions)
        base_components = H._arc1_components_at_ratio(:heritability, 0.25, base_scale, 0.4)
        shifted_components = H._arc1_components_at_ratio(:heritability, 0.25, shifted_scale, 0.4)

        @test shifted_fit.loglik ≈ base_fit.loglik atol = 1e-6
        @test shifted_scale ≈ base_scale atol = 1e-7
        @test shifted_components.sigma_a2 ≈ base_components.sigma_a2 atol = 1e-7
        @test shifted_components.sigma_pe2 ≈ base_components.sigma_pe2 atol = 1e-7
        @test shifted_components.sigma_e2 ≈ base_components.sigma_e2 atol = 1e-7
    end

    @testset "paired reduction preserves record and animal order and dense oracle" begin
        components = (0.3, 0.2, 0.5)
        reference = H._arc1_profile_reml(context, components...)
        record_order = [7, 2, 11, 4, 9, 1, 12, 3, 8, 5, 10, 6]
        record_context = H._arc1_profile_context(y[record_order], X[record_order, :],
                                                 Z[record_order, :], Ainv)
        record_fit = H._arc1_profile_reml(record_context, components...)
        animal_order = [6, 2, 5, 1, 4, 3]
        animal_context = H._arc1_profile_context(y, X, Z[:, animal_order],
            Ainv[animal_order, animal_order])
        animal_fit = H._arc1_profile_reml(animal_context, components...)
        @test record_fit.loglik ≈ reference.loglik atol = 1e-10
        @test record_fit.beta ≈ reference.beta atol = 1e-10
        @test animal_fit.loglik ≈ reference.loglik atol = 1e-10
        @test animal_fit.beta ≈ reference.beta atol = 1e-10

        repeated = H._arc1_profile_context(y, X, Z, Matrix{Float64}(I, 6, 6))
        repeated_fit = H._arc1_profile_reml(repeated, components...)
        @test repeated_fit.loglik ≈ _arc1_dense_reml_oracle(
            y, X, Z, Matrix{Float64}(I, 6, 6), components...).loglik atol = 1e-10
        @test repeated_fit.beta ≈ _arc1_dense_reml_oracle(
            y, X, Z, Matrix{Float64}(I, 6, 6), components...).beta atol = 1e-10

        tiny_fit = H._arc1_profile_reml(context, 0.3, 0.2, 1e-10)
        tiny_oracle = _arc1_bigfloat_dense_reml_oracle(y, X, Z, A, 0.3, 0.2, 1e-10)
        @test tiny_fit.status == :ok
        @test tiny_fit.loglik ≈ tiny_oracle.loglik atol = 1e-6
        @test tiny_fit.beta ≈ tiny_oracle.beta atol = 1e-6
    end

    @testset "fixed residual variance centering is exact and gated" begin
        na = 8
        n = 2na
        Zp = sparse(1:n, repeat(1:na, inner = 2), ones(n), n, na)
        between = repeat([0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0], inner = 2)
        Xp = hcat(ones(n), between)
        contrast = isodd.(1:n) .* 2 .- 1
        yp = 0.2 .+ 0.1 .* sin.(1:n) .+ 1.5 .* contrast
        pair_context = H._arc1_profile_context(yp, Xp, Zp, Matrix{Float64}(I, na, na))
        Ve = 9.814158264884749e-7
        components = [8.732732243825042e-13, 0.7451281637812672, Ve]
        @test H._arc1_profile_fixed_ve_centering_eligible(pair_context, 3, Ve)
        @test !H._arc1_profile_fixed_ve_centering_eligible(pair_context, 1, Ve)
        @test !H._arc1_profile_fixed_ve_centering_eligible(pair_context, 3, 0.0)
        for invalid_tag in (missing, nothing, NaN, Inf, "not-a-variance", true)
            invalid_record = (centering_ve = invalid_tag, centered_loglik = 10.0,
                max_valid_centered_loglik = 10.0)
            @test !H._arc1_profile_centering_tag_matches(invalid_record, Ve)
            @test H._arc1_profile_centered_value(
                invalid_record, :max_valid_centered_loglik, Ve) === nothing
            @test H._arc1_profile_comparison_loglik(invalid_record, Ve) == -Inf
        end

        full = H._arc1_profile_reml(pair_context, components...)
        centered = H._arc1_profile_centered_loglik(pair_context, components)
        constant = H._arc1_profile_centering_constant(pair_context, Ve)
        @test full.status == centered.status == :ok
        @test maximum(abs, pair_context.transformed_design[(na + 1):(2na), :]) == 0.0
        @test abs(centered.loglik + constant - full.loglik) <= 1e-7
        @test abs(constant) > 1e7

        record_level_X = hcat(Xp, repeat([1.0, -1.0], na))
        nonzero_context = H._arc1_profile_context(yp, record_level_X, Zp,
                                                   Matrix{Float64}(I, na, na))
        @test !H._arc1_profile_fixed_ve_centering_eligible(nonzero_context, 3, Ve)

        # Controlled adapters make every full likelihood tie at a large
        # magnitude. The nuisance wrapper must select by the centered score,
        # while retaining the original full likelihood and full maximum.
        controlled_bfgs(ctx, base, free, start, scale) = begin
            values = copy(base)
            values[free] .= start
            centered_value = 1.0e8 - ((values[1] - 0.5)^2 + (values[2] - 1.0)^2)
            (loglik = 1.0e8, max_valid_loglik = 1.0e8,
             centered_loglik = centered_value,
             max_valid_centered_loglik = centered_value, centering_ve = base[3],
             components = values, converged = true, gradient_norm = 0.0,
             optimizer_status = "controlled", hit_bound = false)
        end
        controlled_scalar(ctx, make_components, scale; kwargs...) = begin
            values = make_components(0.75)
            centered_value = 1.0e8 - ((values[1] - 0.5)^2 + (values[2] - 1.0)^2)
            (loglik = 1.0e8, max_valid_loglik = 1.0e8, status = :ok,
             value = 0.75, centered_active = true, centered_loglik = centered_value,
             max_valid_centered_loglik = centered_value, centering_ve = Ve,
             candidates = Any[], physical_zero_endpoint_certificate = (status = :not_attempted,))
        end
        controlled_gradient(ctx, values; free_indices = collect(1:3)) =
            (component_gradient = zeros(3), log_gradient = zeros(length(free_indices)))
        controlled = H._arc1_raw_nuisance(pair_context, :residual_variance, Ve, 1.0;
            bfgs_runner = controlled_bfgs, scalar_profile_runner = controlled_scalar,
            loglik_runner = (ctx, values) -> (1.0e8, :ok),
            gradient_runner = controlled_gradient)
        @test controlled.status == :ok
        @test only(controlled.nuisance_statuses).best_certified.components[1:2] == [0.5, 1.0]
        @test controlled.centered_loglik == 1.0e8
        @test controlled.loglik == controlled.max_valid_loglik == 1.0e8
        @test controlled.max_valid_centered_loglik == 1.0e8

        # A native optimizer exception has valid centered history but no
        # terminal centered score. If that history is noncompetitive, the
        # failed start must not change the baseline refusal policy.
        native_failed_start = H._arc1_bfgs_candidate(pair_context,
            [0.0, 0.0, Ve], [1, 2], [0.1, 0.1], 1.0;
            centered_loglik_at = values ->
                H._arc1_profile_centered_loglik_at(pair_context, values, Ve),
            centering_ve = Ve,
            optimizer_runner = (f, g, z) -> (f(z); error("controlled stop")))
        stable_good_start(ctx, base, free, start, scale) = begin
            values = copy(base); values[free] .= start
            merge(native_failed_start, (loglik = 1.0e8, max_valid_loglik = 1.0e8,
                centered_loglik = 1.0e8, max_valid_centered_loglik = 1.0e8,
                components = values, converged = true, gradient_norm = 0.0,
                hit_bound = false, hit_bound_components = Any[],
                optimizer_status = "controlled converged"))
        end
        native_calls = Ref(0)
        native_then_good(ctx, base, free, start, scale) = begin
            native_calls[] += 1
            native_calls[] == 1 ? native_failed_start :
                stable_good_start(ctx, base, free, start, scale)
        end
        native_failure_result = H._arc1_raw_nuisance(pair_context,
            :residual_variance, Ve, 1.0; bfgs_runner = native_then_good,
            scalar_profile_runner = controlled_scalar,
            loglik_runner = (ctx, values) -> (1.0e8, :ok),
            gradient_runner = controlled_gradient)
        @test native_failed_start.centering_ve == Ve
        @test !hasproperty(native_failed_start, :centered_loglik)
        @test native_failure_result.status == :ok
        native_search = only(native_failure_result.nuisance_statuses)
        @test native_search.unresolved_competitor == false
        @test isempty(native_search.invalid_centering_tag_indices)
        @test !isempty(native_search.invalid_centered_record_indices)

        # Missing native diagnostic metadata is rejected before the failure
        # summary reads it, with the finite likelihood history retained.
        missing_optimizer_status(ctx, base, free, start, scale) =
            Base.structdiff(stable_good_start(ctx, base, free, start, scale),
                NamedTuple{(:optimizer_status,)})
        missing_optimizer_result = H._arc1_raw_nuisance(pair_context,
            :residual_variance, Ve, 1.0; bfgs_runner = missing_optimizer_status,
            scalar_profile_runner = controlled_scalar,
            loglik_runner = (ctx, values) -> (-1.0e10, :ok),
            gradient_runner = controlled_gradient)
        @test missing_optimizer_result.status == :nuisance_unresolved
        @test missing_optimizer_result.max_valid_loglik == 1.0e8
        @test !isempty(only(missing_optimizer_result.nuisance_statuses).
            invalid_bfgs_record_indices)

        # Optional diagnostics may be omitted, but a present value must still
        # have its declared Boolean type before the consumer reads it.
        omitted_optional_boolean(ctx, base, free, start, scale) =
            Base.structdiff(stable_good_start(ctx, base, free, start, scale),
                NamedTuple{(:line_search_failed,)})
        omitted_boolean_result = H._arc1_raw_nuisance(pair_context,
            :residual_variance, Ve, 1.0; bfgs_runner = omitted_optional_boolean,
            scalar_profile_runner = controlled_scalar,
            loglik_runner = (ctx, values) -> (1.0e8, :ok),
            gradient_runner = controlled_gradient)
        @test omitted_boolean_result.status == :ok
        malformed_optional_boolean(ctx, base, free, start, scale) = merge(
            stable_good_start(ctx, base, free, start, scale),
            (line_search_failed = nothing,))
        malformed_boolean_result = H._arc1_raw_nuisance(pair_context,
            :residual_variance, Ve, 1.0; bfgs_runner = malformed_optional_boolean,
            scalar_profile_runner = controlled_scalar,
            loglik_runner = (ctx, values) -> (1.0e8, :ok),
            gradient_runner = controlled_gradient)
        @test malformed_boolean_result.status == :nuisance_unresolved
        @test !isempty(only(malformed_boolean_result.nuisance_statuses).
            invalid_bfgs_record_indices)

        # A converged terminal point cannot hide a better same-start history.
        history_bfgs(ctx, base, free, start, scale) = begin
            values = copy(base); values[free] .= start
            (loglik = -1.0e10, max_valid_loglik = -1.0e10,
             centered_loglik = 0.0, max_valid_centered_loglik = 2e-7,
             centering_ve = base[3], components = values, converged = true,
             gradient_norm = 0.0, optimizer_status = "controlled", hit_bound = false)
        end
        low_scalar(ctx, make_components, scale; kwargs...) = begin
            values = make_components(0.75)
            (loglik = -1.0e10, max_valid_loglik = -1.0e10, status = :ok,
             value = 0.75, centered_active = true, centered_loglik = -1.0,
             max_valid_centered_loglik = -1.0, centering_ve = Ve,
             candidates = Any[], physical_zero_endpoint_certificate = (status = :not_attempted,))
        end
        historical = H._arc1_raw_nuisance(pair_context, :residual_variance, Ve, 1.0;
            bfgs_runner = history_bfgs, scalar_profile_runner = low_scalar,
            loglik_runner = (ctx, values) -> (-1.0e10, :ok),
            gradient_runner = controlled_gradient)
        @test historical.centered_loglik == 0.0
        @test historical.max_valid_centered_loglik == 2e-7
        @test historical.max_valid_centered_loglik > historical.centered_loglik + 1e-8
        @test historical.status == :nuisance_unresolved

        # Scalar answers tagged at another Ve cannot donate either a score or a
        # maximum to this fixed-Ve nuisance profile.
        flat_bfgs(ctx, base, free, start, scale) = begin
            values = copy(base); values[free] .= start
            (loglik = -1.0e10, max_valid_loglik = -1.0e10,
             centered_loglik = 0.0, max_valid_centered_loglik = 0.0,
             centering_ve = base[3], components = values, converged = true,
             gradient_norm = 0.0, optimizer_status = "controlled", hit_bound = false)
        end
        wrong_tag_scalar(ctx, make_components, scale; kwargs...) = begin
            values = make_components(0.75)
            (loglik = -1.0e10, max_valid_loglik = -1.0e10 + 1.0, status = :ok,
             value = 0.75, centered_active = true, centered_loglik = 10.0,
             max_valid_centered_loglik = 10.0, centering_ve = 2Ve,
             candidates = Any[], physical_zero_endpoint_certificate = (status = :not_attempted,))
        end
        wrong_tag = H._arc1_raw_nuisance(pair_context, :residual_variance, Ve, 1.0;
            bfgs_runner = flat_bfgs, scalar_profile_runner = wrong_tag_scalar,
            loglik_runner = (ctx, values) -> (-1.0e10, :ok),
            gradient_runner = controlled_gradient)
        @test wrong_tag.status == :nuisance_unresolved
        @test wrong_tag.centered_loglik == 0.0
        @test wrong_tag.max_valid_centered_loglik == 0.0
        @test wrong_tag.max_valid_loglik == -1.0e10 + 1.0
        bad_face_diagnostics = filter(d -> d.kind == :exact_zero_face,
            only(wrong_tag.nuisance_statuses).exact_zero_faces)
        @test length(bad_face_diagnostics) == 2
        @test all(d -> !d.centering_tag_valid, bad_face_diagnostics)
        bad_face_diagnostic = first(bad_face_diagnostics)
        @test !bad_face_diagnostic.centering_tag_valid
        @test bad_face_diagnostic.source_centering_ve == 2Ve

        # Missing and explicitly absent scalar tags return a refusal with
        # retained full and centered maxima instead of throwing TypeError.
        scalar_without_tag(ctx, make_components, scale; kwargs...) =
            (loglik = -1.0e10, max_valid_loglik = -1.0e10 + 1.0, status = :ok,
             value = 0.75, centered_active = true, centered_loglik = 10.0,
             max_valid_centered_loglik = 10.0, candidates = Any[],
             physical_zero_endpoint_certificate = (status = :not_attempted,))
        scalar_nothing_tag(ctx, make_components, scale; kwargs...) = merge(
            scalar_without_tag(ctx, make_components, scale; kwargs...),
            (centering_ve = nothing,))
        scalar_missing_tag(ctx, make_components, scale; kwargs...) = merge(
            scalar_without_tag(ctx, make_components, scale; kwargs...),
            (centering_ve = missing,))
        for bad_scalar in (scalar_without_tag, scalar_nothing_tag, scalar_missing_tag)
            untagged = H._arc1_raw_nuisance(pair_context, :residual_variance, Ve, 1.0;
                bfgs_runner = flat_bfgs, scalar_profile_runner = bad_scalar,
                loglik_runner = (ctx, values) -> (-1.0e10, :ok),
                gradient_runner = controlled_gradient)
            @test untagged.status == :nuisance_unresolved
            @test untagged.loglik == -1.0e10
            @test untagged.max_valid_loglik == -1.0e10 + 1.0
            @test untagged.max_valid_centered_loglik == 0.0
            @test all(d -> !d.centering_tag_valid, only(untagged.nuisance_statuses).exact_zero_faces)
        end

        # A valid Ve tag authorizes the retained centered maximum even when
        # the scalar's terminal centered score is invalid.
        invalid_terminal_scalar(ctx, make_components, scale; kwargs...) = begin
            values = make_components(0.75)
            (loglik = -1.0e10, max_valid_loglik = -1.0e10 + 1.0, status = :ok,
             value = 0.75, centered_active = true, centered_loglik = -Inf,
             max_valid_centered_loglik = 10.0, centering_ve = Ve,
             candidates = Any[], physical_zero_endpoint_certificate = (status = :not_attempted,))
        end
        invalid_terminal = H._arc1_raw_nuisance(pair_context, :residual_variance, Ve, 1.0;
            bfgs_runner = flat_bfgs, scalar_profile_runner = invalid_terminal_scalar,
            loglik_runner = (ctx, values) -> (-1.0e10, :ok),
            gradient_runner = controlled_gradient)
        @test invalid_terminal.status == :nuisance_unresolved
        @test invalid_terminal.max_valid_loglik == -1.0e10 + 1.0
        @test invalid_terminal.max_valid_centered_loglik == 10.0
        invalid_face = first(filter(d -> d.kind == :exact_zero_face,
            only(invalid_terminal.nuisance_statuses).exact_zero_faces))
        @test invalid_face.centering_tag_valid
        @test !invalid_face.centered_score_valid

        # A wrongly tagged BFGS historical maximum cannot enter the aggregate
        # or be relabeled with the fixed-Ve tag returned to the caller.
        wrong_tag_bfgs(ctx, base, free, start, scale) = begin
            values = copy(base); values[free] .= start
            (loglik = -1.0e10, max_valid_loglik = -1.0e10,
             centered_loglik = 0.0, max_valid_centered_loglik = 10.0,
             centering_ve = 2Ve, components = values, converged = true,
             gradient_norm = 0.0, optimizer_status = "controlled", hit_bound = false)
        end
        wrong_bfgs = H._arc1_raw_nuisance(pair_context, :residual_variance, Ve, 1.0;
            bfgs_runner = wrong_tag_bfgs, scalar_profile_runner = low_scalar,
            loglik_runner = (ctx, values) -> (-1.0e10, :ok),
            gradient_runner = controlled_gradient)
        @test wrong_bfgs.status == :nuisance_unresolved
        @test wrong_bfgs.max_valid_centered_loglik < 10.0
        @test wrong_bfgs.centering_ve == Ve
        @test only(wrong_bfgs.nuisance_statuses).unresolved_competitor == false
        @test !isempty(only(wrong_bfgs.nuisance_statuses).invalid_centered_record_indices)

        ordered_calls = Ref(0)
        terminal_above_declared_max(ctx, base, free, start, scale) = begin
            ordered_calls[] += 1
            values = copy(base); values[free] .= start
            first = ordered_calls[] == 1
            (loglik = -1.0e10, max_valid_loglik = -1.0e10,
             centered_loglik = first ? 2e-7 : 0.0,
             max_valid_centered_loglik = 0.0, centering_ve = Ve,
             components = values, converged = !first, hit_bound = false,
             gradient_norm = 0.0, optimizer_status = "controlled",
             hit_bound_components = Any[])
        end
        terminal_history_result = H._arc1_raw_nuisance(pair_context,
            :residual_variance, Ve, 1.0; bfgs_runner = terminal_above_declared_max,
            scalar_profile_runner = low_scalar,
            loglik_runner = (ctx, values) -> (-1.0e10, :ok),
            gradient_runner = controlled_gradient)
        @test terminal_history_result.status == :nuisance_unresolved
        @test terminal_history_result.max_valid_centered_loglik == 2e-7
        @test H._arc1_raw_competitor_is_competitive(
            (converged = false, hit_bound = true, centered_loglik = 0.0,
             max_valid_centered_loglik = -1.0, centering_ve = Ve), 0.0;
            centering_ve = Ve)

        # An inconsistent hit_bound/contact pair is rejected even when its
        # terminal likelihood only ties the winner and its declared maximum
        # is stale and lower.
        bound_calls = Ref(0)
        bound_control(ctx, base, free, start, scale) = begin
            bound_calls[] += 1
            values = copy(base); values[free] .= start
            if bound_calls[] == 1
                (loglik = -1.0e10, max_valid_loglik = -1.0e10,
                 centered_loglik = 0.0, max_valid_centered_loglik = -1.0,
                 centering_ve = Ve, components = values, converged = false,
                 hit_bound = true, hit_bound_components = Any[], gradient_norm = 0.0,
                 optimizer_status = "inconsistent controlled bound")
            else
                (loglik = -1.0e10, max_valid_loglik = -1.0e10,
                 centered_loglik = 0.0, max_valid_centered_loglik = 0.0,
                 centering_ve = Ve, components = values, converged = true,
                 hit_bound = false, hit_bound_components = Any[], gradient_norm = 0.0,
                 optimizer_status = "controlled converged")
            end
        end
        inconsistent_bound_result = H._arc1_raw_nuisance(pair_context,
            :residual_variance, Ve, 1.0; bfgs_runner = bound_control,
            scalar_profile_runner = low_scalar,
            loglik_runner = (ctx, values) -> (-1.0e10, :ok),
            gradient_runner = controlled_gradient)
        @test inconsistent_bound_result.status == :nuisance_unresolved
        @test inconsistent_bound_result.max_valid_centered_loglik == 0.0
        @test !isempty(only(inconsistent_bound_result.nuisance_statuses).
            invalid_bfgs_record_indices)

        # Continuation maximum tags are checked before their score or maximum
        # can be merged into the accumulated same-Ve history.
        continuation_candidate = (candidate_index = 1, loglik = -1.0e10,
            max_valid_loglik = -1.0e10, centered_loglik = -1.0,
            max_valid_centered_loglik = -1.0, centering_ve = Ve,
            components = [0.2, 1e-13, Ve], converged = false,
            optimizer_converged = true, gradient_norm = 0.0,
            finite_difference_error = 0.0, analytic_gradient_valid = true,
            line_search_failed = false, free_indices = [1, 2],
            finite_difference_errors = Dict(1 => 0.0, 2 => Inf),
            hit_bound = true, iterations = 20,
            hit_bound_components = [(component = 2, side = :lower, value = 1e-13)])
        initial_unresolved = (status = :projected_gradient_unresolved,
            projected_loglik = -1.0e6, projected_centered_loglik = -1.0)
        invalid_candidate_history = merge(continuation_candidate,
            (loglik = -1.0e6 + 2e-7, max_valid_loglik = -1.0e6,
             centered_loglik = -Inf, max_valid_centered_loglik = 2e-7))
        invalid_candidate_full_max = Ref(-1.0e6)
        invalid_candidate_centered_max = Ref(-1.0)
        refused_candidate_history = H._arc1_projected_face_polish(pair_context,
            invalid_candidate_history, 3, 1.0, pair_context.residual_df, Any[], nothing,
            initial_unresolved; maximum_seen = invalid_candidate_full_max,
            centered_maximum_seen = invalid_candidate_centered_max,
            centered_loglik_at = components ->
                H._arc1_profile_centered_loglik_at(pair_context, components, Ve),
            centering_ve = Ve)
        @test refused_candidate_history.status == :candidate_centered_score_invalid
        @test invalid_candidate_full_max[] == -1.0e6 + 2e-7
        @test invalid_candidate_centered_max[] == 2e-7
        @test refused_candidate_history.continuation.max_valid_centered_loglik == 2e-7

        # The direct consumer rejects a malformed candidate before reading
        # components, while retaining both independently valid histories.
        malformed_candidate = merge(invalid_candidate_history,
            (components = nothing,))
        malformed_full_max, malformed_centered_max = Ref(-1.0e6), Ref(3e-7)
        malformed_polish = H._arc1_projected_face_polish(pair_context,
            malformed_candidate, 3, 1.0, pair_context.residual_df, Any[], nothing,
            initial_unresolved; maximum_seen = malformed_full_max,
            centered_maximum_seen = malformed_centered_max,
            centered_loglik_at = components ->
                H._arc1_profile_centered_loglik_at(pair_context, components, Ve),
            centering_ve = Ve)
        @test malformed_polish.status == :candidate_record_invalid
        @test malformed_full_max[] == -1.0e6 + 2e-7
        @test malformed_centered_max[] == 3e-7
        @test malformed_polish.continuation.max_valid_centered_loglik == 3e-7
        @test malformed_polish.continuation.centering_ve == Ve

        # Malformed contacts are checked before any `contact.component` read.
        malformed_contact = merge(continuation_candidate,
            (hit_bound_components = [(component = :bad, side = :lower)],))
        contact_full_max, contact_centered_max = Ref(-1.0e10), Ref(3e-7)
        refused_contact = H._arc1_projected_face_polish(pair_context,
            malformed_contact, 3, 1.0, pair_context.residual_df, Any[], nothing,
            initial_unresolved; maximum_seen = contact_full_max,
            centered_maximum_seen = contact_centered_max,
            centered_loglik_at = components ->
                H._arc1_profile_centered_loglik_at(pair_context, components, Ve),
            centering_ve = Ve)
        @test refused_contact.status == :candidate_record_invalid
        @test refused_contact.continuation.max_valid_centered_loglik == 3e-7

        # The direct returned refusal carries accumulated history, not only
        # the invalid certificate's lower historical maximum.
        bad_certificate = (status = :projected_gradient_unresolved,
            max_valid_loglik = -1.0e10, centering_ve = Ve,
            max_valid_centered_loglik = 2e-7)
        certificate_centered_max = Ref(3e-7)
        refused_certificate = H._arc1_projected_face_polish(pair_context,
            continuation_candidate, 3, 1.0, pair_context.residual_df, Any[], nothing,
            bad_certificate; maximum_seen = Ref(-1.0e10),
            centered_maximum_seen = certificate_centered_max,
            centered_loglik_at = components ->
                H._arc1_profile_centered_loglik_at(pair_context, components, Ve),
            centering_ve = Ve)
        @test refused_certificate.status == :initial_certificate_record_invalid
        @test refused_certificate.continuation.max_valid_centered_loglik == 3e-7
        @test refused_certificate.continuation.centering_ve == Ve

        wrong_continuation_runner = (ctx, base, free, start, scale, budget) ->
            (loglik = -1.0e10, max_valid_loglik = -1.0e10,
             centered_loglik = 10.0, max_valid_centered_loglik = 10.0,
             centering_ve = 2Ve, components = copy(base), free_indices = copy(free),
             converged = true, gradient_norm = 0.0, optimizer_converged = true,
             analytic_gradient_valid = true, line_search_failed = false,
             finite_difference_errors = Dict(1 => 0.0), finite_difference_error = 0.0,
             hit_bound = false, hit_bound_components = Any[], iterations = 5,
             objective_evaluations = 1, gradient_evaluations = 1,
             termination_code = :gradient_converged, stopped_by = :gradient,
             optimizer_status = "converged")
        continuation_full_max = Ref(-1.0e10)
        continuation_centered_max = Ref(-1.0)
        rejected_continuation = H._arc1_projected_face_polish(pair_context,
            continuation_candidate, 3, 1.0, pair_context.residual_df, Any[], nothing,
            initial_unresolved; maximum_seen = continuation_full_max,
            centered_maximum_seen = continuation_centered_max,
            centered_loglik_at = components ->
                H._arc1_profile_centered_loglik_at(pair_context, components, Ve),
            centering_ve = Ve, continuation_runner = wrong_continuation_runner)
        @test rejected_continuation.status == :continuation_centering_tag_mismatch
        @test continuation_centered_max[] == -1.0
        @test rejected_continuation.continuation.max_valid_loglik == -1.0e10

        # Same-Ve centered history is ingested before an invalid terminal
        # score refuses a continuation, and reaches the raw nuisance guard.
        invalid_centered_continuation = (ctx, base, free, start, scale, budget) ->
            (loglik = -1.0e6, max_valid_loglik = -1.0e6 + 2e-7,
             centered_loglik = -Inf, max_valid_centered_loglik = 2e-7,
             centering_ve = Ve, components = copy(base), iterations = 5,
             optimizer_status = :exception_return, termination_code = :exception)
        continuation_centered_max = Ref(-1.0)
        rejected_invalid_centered_continuation = H._arc1_projected_face_polish(
            pair_context, continuation_candidate, 3, 1.0, pair_context.residual_df,
            Any[], nothing, initial_unresolved;
            maximum_seen = Ref(-1.0e6), centered_maximum_seen = continuation_centered_max,
            centered_loglik_at = components ->
                H._arc1_profile_centered_loglik_at(pair_context, components, Ve),
            centering_ve = Ve, continuation_runner = invalid_centered_continuation)
        @test rejected_invalid_centered_continuation.status == :continuation_centered_score_invalid
        @test continuation_centered_max[] == 2e-7
        @test rejected_invalid_centered_continuation.continuation.max_valid_centered_loglik == 2e-7

        boundary_bfgs(ctx, base, free, start, scale) = begin
            values = copy(base); values[free] .= start; values[1] = 1e-13
            (loglik = -1.0e6, max_valid_loglik = -1.0e6,
             centered_loglik = 0.0, max_valid_centered_loglik = 0.0,
             centering_ve = Ve, components = values, converged = false,
             optimizer_converged = true, analytic_gradient_valid = true,
             line_search_failed = false, gradient_norm = 0.0,
             optimizer_status = "controlled", hit_bound = true,
             hit_bound_components = [(component = 1, side = :lower, value = 1e-13)],
             free_indices = copy(free), iterations = 5,
             finite_difference_errors = Dict(1 => 0.0, 2 => Inf))
        end
        unresolved_certificate(args...; kwargs...) = (
            status = :projected_gradient_unresolved, projected_loglik = -1.0e6,
            projected_centered_loglik = -1.0)
        centered_probe_polish(ctx, candidate, index, scale, df, faces, intersection, initial; kwargs...) =
            H._arc1_projected_face_polish(ctx, candidate, index, scale, df, faces,
                intersection, initial; continuation_runner = invalid_centered_continuation,
                kwargs...)
        raw_probe = H._arc1_raw_nuisance(pair_context, :residual_variance, Ve, 1.0;
            bfgs_runner = boundary_bfgs, scalar_profile_runner = low_scalar,
            certificate_runner = unresolved_certificate, polish_runner = centered_probe_polish,
            loglik_runner = (ctx, values) -> (-1.0e6, :ok),
            gradient_runner = controlled_gradient)
        @test raw_probe.status == :nuisance_unresolved
        @test raw_probe.max_valid_loglik == -1.0e6 + 2e-7
        @test raw_probe.max_valid_centered_loglik == 2e-7
        @test raw_probe.max_valid_centered_loglik > raw_probe.centered_loglik + 1e-8
        probe_state = H._Arc1ProfileState(nothing, 1.0, -1.0e6,
            Dict{Symbol,Dict{Float64,Any}}(), Dict{Symbol,Int}(), -Inf, Any[])
        @test H._arc1_include_valid_profile_max!(probe_state, raw_probe) == -1.0e6 + 2e-7
        all_targets = Dict{Symbol,Any}(name =>
            (confidence_set = [(0.0, 1.0)], status = :finite_grid_resolved,
             search_status = :finite_grid_resolved, formed = true)
            for name in H._ARC1_PROFILE_TARGETS)
        @test H._arc1_apply_point_fit_guard!(all_targets, -1.0e6 - 5e-7,
            probe_state.max_constrained_loglik)
        @test all(all_targets[name].search_status == :point_fit_not_optimal
                  for name in H._ARC1_PROFILE_TARGETS)

        # Adapter histories share one ingestion contract: finite full maxima
        # survive any centered-tag failure, while centered maxima require the
        # exact fixed-Ve tag and do not require a valid terminal score.
        matrix_records = (
            candidate = (max_valid_loglik = -8.0, loglik = NaN,
                max_valid_centered_loglik = 2e-7, centered_loglik = -Inf,
                centering_ve = Ve),
            continuation = (max_valid_loglik = -7.0, loglik = -Inf,
                max_valid_centered_loglik = 3e-7, centered_loglik = NaN,
                centering_ve = Ve),
            scalar = (max_valid_loglik = -6.0, loglik = -Inf,
                max_valid_centered_loglik = 4e-7, centered_loglik = -Inf,
                centered_active = false, centering_ve = Ve),
            certificate = (max_valid_loglik = -5.0, loglik = NaN,
                max_valid_centered_loglik = 5e-7, centered_loglik = -Inf,
                status = :refused, centering_ve = Ve),
        )
        for (adapter, good_record) in pairs(matrix_records)
            full_seen, centered_seen = Ref(-Inf), Ref(-Inf)
            history = H._arc1_profile_record_likelihood_history!(full_seen,
                good_record; centered_maximum = centered_seen, centering_ve = Ve)
            @test history.centering_tag_valid
            @test full_seen[] == good_record.max_valid_loglik
            @test centered_seen[] == good_record.max_valid_centered_loglik

            # Invalid, absent, or wrong tags never contaminate centered history;
            # terminal-only centered evidence is the allowed max fallback.
            for invalid_tag in (missing, nothing, 2Ve)
                bad = merge(good_record, (centering_ve = invalid_tag,))
                full_seen, centered_seen = Ref(-Inf), Ref(-Inf)
                bad_history = H._arc1_profile_record_likelihood_history!(full_seen,
                    bad; centered_maximum = centered_seen, centering_ve = Ve)
                @test !bad_history.centering_tag_valid
                @test full_seen[] == good_record.max_valid_loglik
                @test centered_seen[] == -Inf
            end
            terminal_only = merge(good_record,
                (centered_loglik = 6e-7, max_valid_centered_loglik = nothing))
            @test H._arc1_profile_centered_value(terminal_only,
                :max_valid_centered_loglik, Ve; fallback_field = :centered_loglik) == 6e-7
        end

        for adapter in (:candidate, :continuation, :scalar, :returned_certificate),
            terminal_state in (:valid, :invalid, :missing),
            full_history_present in (false, true),
            centered_history_present in (false, true),
            tag_state in (:correct, :wrong, :missing, :absent)
            tag = tag_state === :correct ? Ve : tag_state === :wrong ? 2Ve : missing
            record = (adapter = adapter, status = :controlled)
            tag_state === :absent || (record = merge(record, (centering_ve = tag,)))
            if terminal_state !== :missing
                record = merge(record, (loglik = terminal_state === :valid ? -10.0 : NaN,
                    centered_loglik = terminal_state === :valid ? 1e-7 : -Inf))
            end
            full_history_present &&
                (record = merge(record, (max_valid_loglik = -9.0,)))
            centered_history_present &&
                (record = merge(record, (max_valid_centered_loglik = 3e-7,)))
            full_seen, centered_seen = Ref(-Inf), Ref(-Inf)
            H._arc1_profile_record_likelihood_history!(full_seen, record;
                centered_maximum = centered_seen, centering_ve = Ve)
            expected_full = full_history_present ? -9.0 :
                terminal_state === :valid ? -10.0 : -Inf
            @test full_seen[] == expected_full
            centered_is_tagged = tag_state === :correct
            expected_centered = !centered_is_tagged ? -Inf :
                centered_history_present ? 3e-7 :
                terminal_state === :valid ? 1e-7 : -Inf
            @test centered_seen[] == expected_centered
        end

        # Candidate terminal-only evidence and a returned refusing certificate
        # must reach the raw nuisance maximum and prevent false acceptance.
        terminal_only_bfgs(ctx, base, free, start, scale) = begin
            values = copy(base); values[free] .= start
            record = (loglik = -1.0e6, max_valid_loglik = -1.0e6,
                centered_loglik = 2e-7, centering_ve = Ve, components = values,
                converged = false, gradient_norm = 0.0,
                optimizer_status = "controlled", hit_bound = false)
            record
        end
        terminal_only_candidate = H._arc1_raw_nuisance(pair_context,
            :residual_variance, Ve, 1.0; bfgs_runner = terminal_only_bfgs,
            scalar_profile_runner = low_scalar,
            loglik_runner = (ctx, values) -> (-1.0e6, :ok),
            gradient_runner = controlled_gradient)
        @test terminal_only_candidate.max_valid_centered_loglik == 2e-7
        @test terminal_only_candidate.status == :nuisance_unresolved

        boundary_bfgs_for_certificate(ctx, base, free, start, scale) = begin
            values = copy(base); values[free] .= start; values[1] = 1e-13
            merge(boundary_bfgs(ctx, base, free, start, scale), (components = values,))
        end
        for certificate_tag in (Ve, 2Ve, missing, :absent)
            returned_history_certificate(args...; kwargs...) = begin
                record = (status = :test_refusal,
                    max_valid_loglik = -1.0e6 + 1.0,
                    max_valid_centered_loglik = 7e-7, centered_loglik = -Inf)
                certificate_tag === :absent ? record :
                    merge(record, (centering_ve = certificate_tag,))
            end
            returned_certificate_history = H._arc1_raw_nuisance(pair_context,
                :residual_variance, Ve, 1.0; bfgs_runner = boundary_bfgs_for_certificate,
                scalar_profile_runner = low_scalar,
                certificate_runner = returned_history_certificate,
                loglik_runner = (ctx, values) -> (-1.0e6, :ok),
                gradient_runner = controlled_gradient)
            @test returned_certificate_history.max_valid_loglik == -1.0e6 + 1.0
            @test returned_certificate_history.max_valid_centered_loglik ==
                (certificate_tag === Ve ? 7e-7 : 0.0)
            @test returned_certificate_history.status == :nuisance_unresolved
            if certificate_tag === Ve
                search = only(filter(x -> x.kind == :raw_nuisance_search,
                    returned_certificate_history.nuisance_statuses))
                @test any(row -> hasproperty(row, :centering_ve) &&
                    row.centering_ve === Ve, search.lower_bound_resolutions)
            end
        end

        # Scalar history is tag-governed even when its own active flag is false
        # or absent, and invalid coordinates return a structured refusal.
        inactive_scalar(ctx, make_components, scale; kwargs...) =
            (loglik = -1.0e6, max_valid_loglik = -1.0e6 + 2.0,
             centered_loglik = -Inf, max_valid_centered_loglik = 8e-7,
             centering_ve = Ve, status = :nuisance_unresolved, value = 0.75,
             centered_active = false, candidates = Any[],
             physical_zero_endpoint_certificate = (status = :not_attempted,))
        for scalar_runner in (inactive_scalar,
                (ctx, make_components, scale; kwargs...) ->
                    Base.structdiff(inactive_scalar(ctx, make_components, scale; kwargs...),
                        NamedTuple{(:centered_active,)}))
            inactive_history = H._arc1_raw_nuisance(pair_context,
                :residual_variance, Ve, 1.0; bfgs_runner = flat_bfgs,
                scalar_profile_runner = scalar_runner,
                loglik_runner = (ctx, values) -> (-1.0e6, :ok),
                gradient_runner = controlled_gradient)
            @test inactive_history.max_valid_centered_loglik == 8e-7
            @test inactive_history.max_valid_loglik == -1.0e6 + 2.0
        end

        for scalar_tag in (Ve, 2Ve, missing, :absent)
            invalid_scalar(ctx, make_components, scale; kwargs...) = begin
                record = (loglik = -Inf, max_valid_loglik = -1.0e6 + 3.0,
                    centered_loglik = -Inf, max_valid_centered_loglik = 9e-7,
                    status = :nuisance_unresolved, value = NaN,
                    centered_active = false, candidates = Any[],
                    physical_zero_endpoint_certificate = (status = :not_attempted,))
                scalar_tag === :absent ? record : merge(record, (centering_ve = scalar_tag,))
            end
            invalid_scalar_result = H._arc1_raw_nuisance(pair_context,
                :residual_variance, Ve, 1.0; bfgs_runner = flat_bfgs,
                scalar_profile_runner = invalid_scalar,
                loglik_runner = (ctx, values) -> (-1.0e6, :ok),
                gradient_runner = controlled_gradient)
            @test invalid_scalar_result.status == :nuisance_unresolved
            @test invalid_scalar_result.max_valid_loglik == -1.0e6 + 3.0
            @test invalid_scalar_result.max_valid_centered_loglik ==
                (scalar_tag === Ve ? 9e-7 : 0.0)
            @test any(d -> d.status == :invalid_coordinate,
                only(invalid_scalar_result.nuisance_statuses).exact_zero_faces)
        end

        # Histories returned by an injected polish continuation must be
        # ingested by the wrapper before it decides the candidate's status.
        for polish_tag in (Ve, 2Ve, missing, :absent)
            returned_polish(args...; kwargs...) = begin
                continuation = (status = :continuation_exception,
                    max_valid_loglik = -1.0e6 + 4.0,
                    max_valid_centered_loglik = 2e-7,
                    centered_loglik = -Inf)
                continuation = polish_tag === :absent ? continuation :
                    merge(continuation, (centering_ve = polish_tag,))
                (status = :polish_refused, continuation)
            end
            polish_history = H._arc1_raw_nuisance(pair_context,
                :residual_variance, Ve, 1.0; bfgs_runner = boundary_bfgs,
                scalar_profile_runner = low_scalar,
                certificate_runner = unresolved_certificate,
                polish_runner = returned_polish,
                loglik_runner = (ctx, values) -> (-1.0e6, :ok),
                gradient_runner = controlled_gradient)
            @test polish_history.max_valid_loglik == -1.0e6 + 4.0
            @test polish_history.max_valid_centered_loglik ==
                (polish_tag === Ve ? 2e-7 : 0.0)
            @test polish_history.status == :nuisance_unresolved
        end

        # A bound candidate may omit its explicit maximum; its finite terminal
        # likelihood still feeds both diagnosis and the retained full maximum.
        bound_candidate_without_max(ctx, base, free, start, scale) =
            Base.structdiff(boundary_bfgs(ctx, base, free, start, scale),
                NamedTuple{(:max_valid_loglik,)})
        missing_candidate_max = H._arc1_raw_nuisance(pair_context,
            :residual_variance, Ve, 1.0; bfgs_runner = bound_candidate_without_max,
            scalar_profile_runner = low_scalar,
            certificate_runner = (args...; kwargs...) -> (status = :test_refusal,),
            loglik_runner = (ctx, values) -> (-1.0e6, :ok),
            gradient_runner = controlled_gradient)
        @test missing_candidate_max.max_valid_loglik == -1.0e6
        @test missing_candidate_max.status == :nuisance_unresolved
        malformed_bfgs_record(ctx, base, free, start, scale) =
            (max_valid_loglik = -1.0e6 + 7.0,
             max_valid_centered_loglik = 5e-7, centering_ve = Ve)
        malformed_candidate = H._arc1_raw_nuisance(pair_context,
            :residual_variance, Ve, 1.0; bfgs_runner = malformed_bfgs_record,
            scalar_profile_runner = low_scalar,
            loglik_runner = (ctx, values) -> (-1.0e6, :ok),
            gradient_runner = controlled_gradient)
        @test malformed_candidate.status == :nuisance_unresolved
        @test malformed_candidate.max_valid_loglik == -1.0e6 + 7.0
        @test malformed_candidate.max_valid_centered_loglik == 5e-7

        partial_certificate(args...; kwargs...) =
            (max_valid_loglik = -1.0e6 + 8.0,
             max_valid_centered_loglik = 6e-7, centering_ve = Ve)
        partial_certificate_result = H._arc1_raw_nuisance(pair_context,
            :residual_variance, Ve, 1.0; bfgs_runner = boundary_bfgs,
            scalar_profile_runner = low_scalar,
            certificate_runner = partial_certificate,
            loglik_runner = (ctx, values) -> (-1.0e6, :ok),
            gradient_runner = controlled_gradient)
        @test partial_certificate_result.status == :nuisance_unresolved
        @test partial_certificate_result.max_valid_loglik == -1.0e6 + 8.0
        @test partial_certificate_result.max_valid_centered_loglik == 6e-7

        partial_polish(args...; kwargs...) =
            (status = :polish_refused, max_valid_loglik = -1.0e6 + 9.0,
             max_valid_centered_loglik = 7e-7, centering_ve = Ve)
        partial_polish_result = H._arc1_raw_nuisance(pair_context,
            :residual_variance, Ve, 1.0; bfgs_runner = boundary_bfgs,
            scalar_profile_runner = low_scalar,
            certificate_runner = unresolved_certificate,
            polish_runner = partial_polish,
            loglik_runner = (ctx, values) -> (-1.0e6, :ok),
            gradient_runner = controlled_gradient)
        @test partial_polish_result.status == :nuisance_unresolved
        @test partial_polish_result.max_valid_loglik == -1.0e6 + 9.0
        @test partial_polish_result.max_valid_centered_loglik == 7e-7
        no_max_bound = bound_candidate_without_max(pair_context,
            [0.0, 0.0, Ve], [1, 2], [0.2, 1e-13], 1.0)
        no_max_polish = H._arc1_projected_face_polish(pair_context,
            no_max_bound, 3, 1.0, pair_context.residual_df, Any[], nothing,
            (status = :not_eligible,); centered_loglik_at = components ->
                H._arc1_profile_centered_loglik_at(pair_context, components, Ve),
            centered_maximum_seen = Ref(-Inf), centering_ve = Ve)
        @test no_max_polish.status == :not_eligible
        @test no_max_polish.continuation.max_valid_loglik == -1.0e6

        missing_scalar_value(ctx, make_components, scale; kwargs...) =
            (loglik = -Inf, max_valid_loglik = -1.0e6 + 5.0,
             centered_loglik = -Inf, max_valid_centered_loglik = 3e-7,
             centering_ve = Ve, status = :nuisance_unresolved,
             centered_active = false, candidates = Any[],
             physical_zero_endpoint_certificate = (status = :not_attempted,))
        missing_value_result = H._arc1_raw_nuisance(pair_context,
            :residual_variance, Ve, 1.0; bfgs_runner = flat_bfgs,
            scalar_profile_runner = missing_scalar_value,
            loglik_runner = (ctx, values) -> (-1.0e6, :ok),
            gradient_runner = controlled_gradient)
        @test missing_value_result.status == :nuisance_unresolved
        @test missing_value_result.max_valid_loglik == -1.0e6 + 5.0
        @test missing_value_result.max_valid_centered_loglik == 3e-7
        @test any(d -> d.status == :invalid_coordinate,
            only(missing_value_result.nuisance_statuses).exact_zero_faces)

        # The scalar engine catches a later centered callback failure and
        # returns histories retained by earlier valid evaluations.
        callback_calls = Ref(0)
        throwing_centered_callback(components) = begin
            callback_calls[] += 1
            callback_calls[] == 1 ? (2e-7, :ok) :
                throw(ErrorException("controlled centered callback failure"))
        end
        scalar_callback_runner(ctx, make_components, scale; kwargs...) =
            H._arc1_scalar_profile_max(ctx, make_components, scale;
                profile_loglik_at = components -> (-1.0e6 + 6.0, :ok),
                centered_loglik_at = throwing_centered_callback,
                centering_ve = Ve)
        callback_history = H._arc1_raw_nuisance(pair_context,
            :residual_variance, Ve, 1.0; bfgs_runner = flat_bfgs,
            scalar_profile_runner = scalar_callback_runner,
            loglik_runner = (ctx, values) -> (-1.0e6, :ok),
            gradient_runner = controlled_gradient)
        @test callback_calls[] >= 2
        @test callback_history.status == :nuisance_unresolved
        @test callback_history.max_valid_loglik == -1.0e6 + 6.0
        @test callback_history.max_valid_centered_loglik == 2e-7

        post_run_calls = Ref(0)
        post_run_callback(components) = begin
            post_run_calls[] += 1
            post_run_calls[] == 1 ? (2e-7, :ok) :
                throw(ErrorException("post-run centered callback failure"))
        end
        post_run = H._arc1_bfgs_candidate(pair_context, [0.0, 0.0, Ve], [1, 2],
            [0.1, 0.1], 1.0; centered_loglik_at = post_run_callback,
            centering_ve = Ve,
            optimizer_runner = (objective, gradient, start) -> begin
                objective(start)
                Arc1PostRunCallbackResult(copy(start), (ls_failed = false,),
                                          :controlled, 7)
            end)
        @test post_run_calls[] == 2
        @test !post_run.converged
        @test post_run.max_valid_centered_loglik == 2e-7
        @test post_run.centering_ve == Ve
        @test post_run.optimizer_status == "post-run centered callback failure"
        @test post_run.iterations == 7

        interrupt_post_run_calls = Ref(0)
        interrupt_post_run_callback(components) = begin
            interrupt_post_run_calls[] += 1
            interrupt_post_run_calls[] == 1 ? (2e-7, :ok) : throw(InterruptException())
        end
        @test_throws InterruptException H._arc1_bfgs_candidate(pair_context,
            [0.0, 0.0, Ve], [1, 2], [0.1, 0.1], 1.0;
            centered_loglik_at = interrupt_post_run_callback, centering_ve = Ve,
            optimizer_runner = (objective, gradient, start) -> begin
                objective(start)
                Arc1PostRunCallbackResult(copy(start), (ls_failed = false,),
                                          :controlled, 7)
            end)
        @test interrupt_post_run_calls[] == 2

        interrupt_calls = Ref(0)
        interrupting_centered_callback(components) = begin
            interrupt_calls[] += 1
            interrupt_calls[] == 1 ? (2e-7, :ok) : throw(InterruptException())
        end
        interrupt_scalar_runner(ctx, make_components, scale; kwargs...) =
            H._arc1_scalar_profile_max(ctx, make_components, scale;
                profile_loglik_at = components -> (-1.0e6, :ok),
                centered_loglik_at = interrupting_centered_callback,
                centering_ve = Ve)
        @test_throws InterruptException H._arc1_raw_nuisance(pair_context,
            :residual_variance, Ve, 1.0; bfgs_runner = flat_bfgs,
            scalar_profile_runner = interrupt_scalar_runner,
            loglik_runner = (ctx, values) -> (-1.0e6, :ok),
            gradient_runner = controlled_gradient)
        @test interrupt_calls[] >= 2

        # Native scalar status variants and their nested producers are
        # collected through the raw consumer, not only by the helper.
        nested_history_certificate(args...; kwargs...) = (
            status = :test_refusal,
            max_valid_loglik = -1.0e6,
            max_valid_centered_loglik = 40.0,
            original_native_max_valid_centered_loglik = 5.0,
            original_native_centering_ve = Ve,
            candidates = [
                (status = :exact_endpoint, evaluation_valid = true,
                 centered_evaluation_valid = true, loglik = -1.0e6 + 1.0,
                 centered_loglik = 10.0, centering_ve = Ve),
                (status = :unresolved, evaluation_valid = true,
                 centered_evaluation_valid = true, loglik = -1.0e6 + 2.0,
                 centered_loglik = 11.0, centering_ve = Ve),
                (status = :physical_zero_endpoint, evaluation_valid = true,
                 centered_evaluation_valid = true, loglik = -1.0e6 + 3.0,
                 centered_loglik = 12.0, centering_ve = Ve)],
            physical_zero_endpoint_certificate = (
                status = :endpoint_forward_derivative_unresolved,
                endpoint_loglik = -1.0e6 + 4.0, endpoint_loglik_valid = true,
                lower_loglik = -1.0e6 + 5.0, lower_loglik_valid = true,
                forward_logliks = [-1.0e6 + 6.0, -1.0e6 + 7.0],
                forward_logliks_valid = true),
            point_scores = Dict(:saved_intersection =>
                (; full = -1.0e6 + 8.0, centered = 20.0,
                 centering_ve = Ve, evaluation_valid = true,
                 centered_evaluation_valid = true)),
            forward_differences = [(; points = [
                (; full = -1.0e6 + 9.0, centered = 30.0, centering_ve = Ve)])],
            observations = [
                (kind = :full, value = -1.0e6 + 10.0, status = :returned,
                 evaluation_valid = true),
                (kind = :centered, value = 99.0, status = :returned,
                 evaluation_valid = true)])
        nested_history = H._arc1_raw_nuisance(pair_context,
            :residual_variance, Ve, 1.0; method_version = :arc1_profile_v3,
            v3_evidence_sink = Dict{Symbol,Any}(), bfgs_runner = boundary_bfgs,
            scalar_profile_runner = low_scalar,
            certificate_runner = nested_history_certificate,
            loglik_runner = (ctx, values) -> (-1.0e6, :ok),
            gradient_runner = controlled_gradient)
        @test nested_history.max_valid_loglik == -1.0e6 + 10.0
        @test nested_history.max_valid_centered_loglik == 30.0
        @test nested_history.status == :nuisance_unresolved
        nested_diagnostic = only(nested_history.nuisance_statuses)
        @test any(f -> f.reason == :centered_provenance_mismatch,
            nested_diagnostic.v3_history_provenance_failures)

        # V3 adds the strict corner route only for the centered residual
        # target. Otherwise the inherited single v2 continuation still runs.
        function inherited_v2_dispatch(ctx, target, fixed)
            target_index = findfirst(==(target),
                (:additive_variance, :permanent_environment_variance,
                 :residual_variance))
            contact_index = first(filter(i -> i != target_index, (1, 2)))
            remaining_index = only(filter(i -> i != target_index &&
                i != contact_index, 1:3))
            contact_value = 2.0^-40
            bfgs_calls = Ref(0)
            continuation_calls = Ref(0)
            native_candidate(ctx, base, free, start, scale) = begin
                bfgs_calls[] += 1
                values = copy(base)
                values[contact_index] = contact_value
                values[remaining_index] = 0.75
                (loglik = -1.0e6, max_valid_loglik = -1.0e6,
                 components = values, converged = false, gradient_norm = 0.0,
                 hit_bound = true,
                 hit_bound_components = [(component = contact_index,
                     side = :lower, value = contact_value)],
                 optimizer_converged = true, optimizer_status = "converged",
                 termination_code = H.Optim.TerminationCode.NoObjectiveChange,
                 analytic_gradient_valid = true, line_search_failed = false,
                 iterations = 5, free_indices = copy(free),
                 finite_difference_errors = Dict(contact_index => Inf,
                     remaining_index => 0.0))
            end
            scalar(ctx, make_components, scale; kwargs...) =
                (loglik = -1.0e6, max_valid_loglik = -1.0e6,
                 status = :ok, value = 0.75, candidates = Any[])
            initial(args...; kwargs...) =
                (status = :face_likelihood_mismatch,
                 zero_indices = [contact_index], likelihood_spread = 1.0,
                 centered_active = false)
            continued(ctx, base, free, start, scale, allowance) = begin
                continuation_calls[] += 1
                error("controlled continuation stop")
            end
            raw = H._arc1_raw_nuisance(ctx, target, fixed, 1.0;
                method_version = :arc1_profile_v3, bfgs_runner = native_candidate,
                scalar_profile_runner = scalar, certificate_runner = initial,
                refinement_runner = continued,
                loglik_runner = (ctx, values) -> (-1.0e6, :ok),
                gradient_runner = controlled_gradient)
            @test bfgs_calls[] == length(H._ARC1_START_MULTIPLIERS)^2
            @test continuation_calls[] > 0
            @test raw.method_version == :arc1_profile_v3
        end
        inherited_v2_dispatch(pair_context, :additive_variance, 0.2)
        inherited_v2_dispatch(pair_context, :permanent_environment_variance, 0.2)
        inherited_v2_dispatch(nonzero_context, :residual_variance, Ve)

        # The raw sink is caller-owned and updated before the next fallible
        # callback. An interrupt on the intersection gradient cannot erase
        # its already returned full likelihood or escape classification.
        raw_interrupt_sink = Dict{Symbol,Any}()
        raw_gradient_calls = Ref(0)
        interrupt_on_intersection_gradient(ctx, values; free_indices = collect(1:3)) = begin
            raw_gradient_calls[] += 1
            raw_gradient_calls[] == 3 && throw(InterruptException())
            (component_gradient = zeros(3), loglik = -1.0e6)
        end
        raw_interrupt = try
            H._arc1_raw_nuisance(pair_context, :residual_variance, Ve, 1.0;
                method_version = :arc1_profile_v3,
                v3_evidence_sink = raw_interrupt_sink,
                bfgs_runner = flat_bfgs, scalar_profile_runner = low_scalar,
                loglik_runner = (ctx, values) ->
                    (all(iszero, values[1:2]) ? 100.0 : -1.0e6, :ok),
                gradient_runner = interrupt_on_intersection_gradient)
            nothing
        catch err
            err
        end
        @test raw_interrupt isa InterruptException
        @test raw_gradient_calls[] == 3
        raw_interrupt_record = only(raw_interrupt_sink[:arc1_profile_v3_evaluations])
        @test raw_interrupt_record[:status] == :interrupted
        @test raw_interrupt_record[:max_valid_loglik] == 100.0
        @test any(e -> e[:kind] == :raw_exception && e[:status] == :interrupted,
            raw_interrupt_record[:events])
    end

    @testset "retained N80 coordinates reproduce centered engine arithmetic" begin
        data = Arc1ProfileEngineeringFixture.arc1_simulate_repeatability(
            UInt64(2026100204), 80, :interior)
        ped = H.Pedigree(copy(data.pedigree.ids), copy(data.pedigree.sire),
            copy(data.pedigree.dam), collect(eachindex(data.pedigree.ids)))
        record_ids = data.record_animal_ids
        X80 = ones(length(record_ids), 1)
        Z80 = zeros(length(record_ids), length(ped.ids))
        for (i, id) in pairs(record_ids)
            Z80[i, data.observed_id_to_row[id]] = 1.0
        end
        saved_context = H._arc1_profile_context(data.y, X80, Z80,
            H.pedigree_inverse(ped))
        rounded_response_fingerprint(values) = bytes2hex(sha256(join(
            string.(round.(Float64.(vec(values)); digits = 12)), ",")))
        @test data.seed == UInt64(2026100204)
        @test rounded_response_fingerprint(data.y) ==
            "2852964d10287545877a0396a5eacd72e5d9a54417a2929be846f5a701cd5708"
        @test size(saved_context.transformed_design) == (length(record_ids), 1)
        @test length(saved_context.transformed_response) == length(record_ids)
            @test size(saved_context.transformed_design, 2) == 1
            @test maximum(abs, saved_context.transformed_design[
                (saved_context.nobserved_animals + 1):(2saved_context.nobserved_animals), :]) == 0.0
            cases = (
                ([8.732732243825042e-13, 0.7451281637812672, 9.814158264884749e-7],
                 [0.0, 0.7451276801470778, 9.814158264884749e-7],
                 -57.79606581137294, -57.796065811381126),
                ([8.732732243825042e-13, 0.7450648653896434, 8.88276206174465e-5],
                 [0.0, 0.7450842922916205, 8.88276206174465e-5],
                 -57.79606582476545, -57.79606581137183))
            for (candidate, face, candidate_expected, face_expected) in cases
                candidate_center = H._arc1_profile_centered_loglik(saved_context, candidate)
                face_center = H._arc1_profile_centered_loglik(saved_context, face)
                candidate_full = H._arc1_profile_reml(saved_context, candidate...).loglik
                constant = H._arc1_profile_centering_constant(saved_context, candidate[3])
                @test candidate_center.status == face_center.status == :ok
                @test candidate_center.loglik ≈ candidate_expected atol = 1e-9
                @test face_center.loglik ≈ face_expected atol = 1e-9
                @test candidate_full ≈ candidate_center.loglik + constant atol = 1e-7
            end
            c7 = cases[2]
            @test H._arc1_profile_centered_loglik(saved_context, c7[1]).loglik -
                H._arc1_profile_centered_loglik(saved_context, c7[2]).loglik < -1e-8

            # The native certificate producer compares on the centered scale;
            # a large but finite full-likelihood diagnostic spread must not
            # reinstate its full-scale gate in the downstream validator.
            m = saved_context.nobserved_animals
            scaled_context = merge(saved_context, (transformed_response = vcat(
                view(saved_context.transformed_response, 1:m),
                16 .* view(saved_context.transformed_response, (m + 1):(2m))),))
            candidate_values, face_values = cases[1][1], cases[1][2]
            ve = candidate_values[3]
            candidate_full = H._arc1_profile_reml(scaled_context,
                candidate_values...).loglik
            face_full = H._arc1_profile_reml(scaled_context, face_values...).loglik
            candidate_centered = H._arc1_profile_centered_loglik(
                scaled_context, candidate_values).loglik
            face_centered = H._arc1_profile_centered_loglik(
                scaled_context, face_values).loglik
            candidate_record = (loglik = candidate_full,
                max_valid_loglik = candidate_full, centered_loglik = candidate_centered,
                max_valid_centered_loglik = candidate_centered, centering_ve = ve,
                components = copy(candidate_values), iterations = 50,
                free_indices = [1, 2], hit_bound_components = [
                    (component = 1, side = :lower, value = candidate_values[1])],
                converged = false, hit_bound = true, optimizer_converged = true,
                gradient_norm = 0.0, analytic_gradient_valid = true,
                line_search_failed = false,
                finite_difference_errors = Dict(1 => Inf, 2 => 0.0))
            face_record = (zero_index = 1, status = :ok, loglik = face_full,
                centered_loglik = face_centered,
                max_valid_centered_loglik = face_centered, centering_ve = ve,
                components = copy(face_values))
            native_certificate = H._arc1_zero_bound_face_certificate(
                candidate_record, 3, 1.0, scaled_context.residual_df, [face_record],
                nothing, components ->
                    H._arc1_loglik_for_components(scaled_context, components),
                (components; free_indices) -> H._arc1_profile_objective_gradient(
                    scaled_context, components; free_indices);
                centered_loglik_at = components ->
                    H._arc1_profile_centered_loglik_at(scaled_context, components, ve),
                centering_ve = ve, historical_likelihoods = [candidate_full],
                historical_centered_likelihoods = [candidate_centered])
            @test native_certificate.status == :resolved_lower_bound_by_zero_face
            @test native_certificate.likelihood_spread_centered <= 1e-8
            @test H._arc1_profile_resolved_face_certificate_valid(
                native_certificate, true)
            controlled_full_spread = merge(native_certificate,
                (likelihood_spread = 9.54e-7,))
            @test H._arc1_profile_resolved_face_certificate_valid(
                controlled_full_spread, true)
            @test !H._arc1_profile_resolved_face_certificate_valid(
                controlled_full_spread, false)
    end

    @testset "paired reduced analytic gradient matches finite differences" begin
        components = [0.3, 0.2, 0.5]
        result = H._arc1_profile_objective_gradient(context, components)
        @test result.loglik ≈ _arc1_dense_reml_oracle(y, X, Z, A, components...).loglik atol = 1e-10
        @test result.beta ≈ _arc1_dense_reml_oracle(y, X, Z, A, components...).beta atol = 1e-10
        @test result.objective ≈ -result.loglik / context.residual_df atol = 1e-12
        for i in eachindex(components)
            step = 1e-6 * components[i]
            plus, minus = copy(components), copy(components)
            plus[i] += step
            minus[i] -= step
            fp = -H._arc1_profile_reml(context, plus...).loglik / context.residual_df
            fm = -H._arc1_profile_reml(context, minus...).loglik / context.residual_df
            natural = (fp - fm) / (2step)
            @test result.component_gradient[i] ≈ natural rtol = 2e-5 atol = 2e-7
            @test result.log_gradient[i] ≈ natural * components[i] rtol = 2e-5 atol = 2e-7
        end

        face = H._arc1_profile_objective_gradient(context, [0.0, 0.2, 0.5];
                                                   free_indices = [2, 3])
        @test length(face.log_gradient) == 2
        for (j, i) in pairs([2, 3])
            step = 1e-6 * components[i]
            plus = [0.0, 0.2, 0.5]
            minus = copy(plus)
            plus[i] += step
            minus[i] -= step
            fp = -H._arc1_profile_reml(context, plus...).loglik / context.residual_df
            fm = -H._arc1_profile_reml(context, minus...).loglik / context.residual_df
            natural = (fp - fm) / (2step)
            @test face.component_gradient[i] ≈ natural rtol = 2e-5 atol = 2e-7
            @test face.log_gradient[j] ≈ natural * [0.0, 0.2, 0.5][i] rtol = 2e-5 atol = 2e-7
        end
    end

    @testset "confidence-set scan preserves disconnected components" begin
        score(x) = (x - 0.2) * (x - 0.4) * (x - 0.6) * (x - 0.8)
        grid = collect(0.0:0.1:1.0)
        scan = H._arc1_segments_from_scores(grid, score.(grid), score; tolerance = 1e-7)
        @test scan.status == :ok
        @test length(scan.segments) == 2
        @test scan.segments[1][1] ≈ 0.2 atol = 1e-7
        @test scan.segments[1][2] ≈ 0.4 atol = 1e-7
        @test scan.segments[2][1] ≈ 0.6 atol = 1e-7
        @test scan.segments[2][2] ≈ 0.8 atol = 1e-7
    end

    @testset "unresolved root gaps remain unresolved" begin
        score(x) = x - 0.5
        scan = H._arc1_segments_from_scores([0.0, 1.0], [-0.5, 0.5],
                                             x -> x == 0.5 ? NaN : score(x);
                                             tolerance = 1e-7)
        @test scan.status == :unresolved_search
        @test isempty(scan.segments)
    end

    @testset "root termination follows bracket width rather than LR residual" begin
        score(x) = x - 0.5000000001
        scan = H._arc1_segments_from_scores([0.0, 1.0], [score(0.0), score(1.0)],
                                             score; tolerance = 1e-7)
        @test scan.status == :ok
        @test scan.root_terminations == [:bracket_tolerance]
        @test scan.roots[1] ≈ 0.5000000001 atol = 1e-7
        adjacent = [1.0e16, nextfloat(1.0e16)]
        unresolved = H._arc1_segments_from_scores(adjacent, [-1.0, 1.0],
            x -> x == adjacent[1] ? -1.0 : 1.0; tolerance = 1e-6)
        @test unresolved.status == :unresolved_search
        @test unresolved.root_terminations == [:representable_limit]
    end

    @testset "adaptive midpoints use target-scale geometry" begin
        @test H._arc1_midpoint(:heritability, 0.2, 0.8) == 0.5
        @test H._arc1_midpoint(:additive_variance, 0.25, 4.0) == 1.0
    end

    @testset "bounded Brent certifies its final bracket with Optim keywords" begin
        search = H._arc1_bounded_brent(x -> (x - 0.37)^2, 0.0, 1.0;
            x_tolerance = 1e-7, likelihood_tolerance = 1e-8, max_evaluations = 2000)
        @test search.status == :ok
        @test search.certified
        @test search.evaluations <= 2000
        @test search.bracket[2] - search.bracket[1] <= 1e-7
        @test search.likelihood_spread <= 1e-8
    end

    @testset "analytic singular endpoints are excluded without nuisance failure" begin
        score(x) = x == 0.0 || x == 1.0 ? Inf : (x - 0.3) * (x - 0.7)
        grid = [0.0, 0.5, 1.0]
        scan = H._arc1_segments_from_scores(grid, score.(grid), score; tolerance = 1e-7)
        @test scan.status == :ok
        @test length(scan.segments) == 1
        @test scan.segments[1][1] ≈ 0.3 atol = 1e-7
        @test scan.segments[1][2] ≈ 0.7 atol = 1e-7
    end

    @testset "common unrestricted maximum is enforced" begin
        @test H._arc1_point_fit_not_optimal(-4.0, -4.0 + 1.01e-7)
        @test !H._arc1_point_fit_not_optimal(-4.0, -4.0 + 0.99e-7)
        @test H._arc1_raw_competitor_is_competitive(
            (converged = false, loglik = -4.0 + 0.5e-8, hit_bound = true), -4.0)
        @test !H._arc1_raw_competitor_is_competitive(
            (converged = false, loglik = -4.0, hit_bound = false), -4.0)
        @test H._arc1_raw_competitor_is_competitive(
            (converged = false, loglik = -4.0 + 1.1e-8, hit_bound = false), -4.0)
    end

    @testset "raw nuisance polishing maximum reaches the shared five-target guard" begin
        point_loglik = 10.0
        raw_mock_context = (residual_df = 5,)
        candidate = (; loglik=point_loglik, max_valid_loglik=point_loglik,
            components=[1.0, 1.0, 1.0], converged=false, hit_bound=true,
            hit_bound_components=[(component=2, side=:lower, value=1e-13)],
            gradient_norm=2e-6, finite_difference_error=0.0,
            analytic_gradient_valid=true, line_search_failed=false,
            optimizer_status="controlled failed start", iterations=20)
        bfgs_runner = (ctx, base, free, starts, scale) -> candidate
        scalar_profile_runner = (ctx, make_components, scale; kwargs...) -> begin
            components = make_components(1.0)
            (; loglik=point_loglik, max_valid_loglik=point_loglik,
               components, converged=true, gradient_norm=0.0,
               optimizer_status="controlled face", hit_bound=false,
               status=:ok, candidates=Any[], value=1.0,
               physical_zero_endpoint_certificate=nothing)
        end
        loglik_runner = (ctx, components) -> (point_loglik, :ok)
        gradient_runner = (ctx, components; kwargs...) ->
            (; component_gradient=zeros(3), loglik=point_loglik)
        certificate_runner = (args...) ->
            (; status=:projected_gradient_unresolved,
               max_valid_loglik=point_loglik,
               projected_loglik=point_loglik,
               projected_centered_loglik=point_loglik)
        polish_runner = (ctx, candidate, index, scale, df, faces, intersection,
                         initial; maximum_seen, kwargs...) -> begin
            maximum_seen[] = point_loglik + 2e-7
            (; status=:better_probe_likelihood,
               continuation=(; status=:better_probe_likelihood,
                   parent_candidate_index=candidate.candidate_index,
                   max_valid_loglik=maximum_seen[]))
        end

        for target in (:additive_variance, :permanent_environment_variance,
                       :residual_variance)
            raw = H._arc1_raw_nuisance(raw_mock_context, target, 1.0, 1.0;
                bfgs_runner, scalar_profile_runner, loglik_runner,
                gradient_runner, certificate_runner, polish_runner)
            @test raw.status == :nuisance_unresolved
            @test raw.max_valid_loglik == point_loglik + 2e-7
            state = H._Arc1ProfileState(nothing, 1.0, point_loglik,
                Dict{Symbol,Dict{Float64,Any}}(), Dict{Symbol,Int}(), -Inf, Any[])
            @test H._arc1_include_valid_profile_max!(state, raw) == point_loglik + 2e-7
            targets = Dict{Symbol,Any}(target_name =>
                (confidence_set=[(0.0, 1.0)], status=:finite_grid_resolved,
                 search_status=:finite_grid_resolved, formed=true)
                for target_name in H._ARC1_PROFILE_TARGETS)
            @test H._arc1_apply_point_fit_guard!(targets, point_loglik,
                state.max_constrained_loglik)
            @test all(targets[t].search_status == :point_fit_not_optimal
                      for t in H._ARC1_PROFILE_TARGETS)
            @test all(!targets[t].formed && targets[t].confidence_set === nothing
                      for t in H._ARC1_PROFILE_TARGETS)
        end

        # Status, likelihood, and components alone cannot stand in for a
        # zero-face certificate's likelihood and derivative evidence.
        cert_calls = Ref(0)
        certificate_candidate(ctx, base, free, starts, scale) = begin
            cert_calls[] += 1
            bound = cert_calls[] == 1
            (; loglik = point_loglik, max_valid_loglik = point_loglik,
               components = [1.0, 1.0, 1.0], converged = !bound, hit_bound = bound,
               hit_bound_components = bound ?
                   [(component = 2, side = :lower, value = 1e-13)] : Any[],
               gradient_norm = 0.0, optimizer_converged = true,
               analytic_gradient_valid = true, line_search_failed = false,
               optimizer_status = "controlled", iterations = 3,
               free_indices = [2, 3], finite_difference_error = 0.0,
               finite_difference_errors = Dict(2 => Inf, 3 => 0.0))
        end
        partial_resolved_certificate(args...; kwargs...) =
            (status = :resolved_lower_bound_by_zero_face, loglik = point_loglik,
             components = [1.0, 0.0, 1.0])
        @test !H._arc1_profile_resolved_face_certificate_valid(
            partial_resolved_certificate(), false)
        partial_certificate_result = H._arc1_raw_nuisance(raw_mock_context,
            :additive_variance, 1.0, 1.0; bfgs_runner = certificate_candidate,
            scalar_profile_runner = scalar_profile_runner,
            loglik_runner = loglik_runner, gradient_runner = gradient_runner,
            certificate_runner = partial_resolved_certificate)
        partial_certificate_diagnostics = only(filter(x -> x.kind == :raw_nuisance_search,
            partial_certificate_result.nuisance_statuses))
        @test partial_certificate_diagnostics.resolved_lower_bound_by_zero_face == 0
        @test only(partial_certificate_diagnostics.lower_bound_resolutions).status ==
              :certificate_record_invalid
    end

    @testset "resolved raw candidates report the polished gradient" begin
        raw_mock_context = (residual_df = 5,)
        calls = Ref(0)
        bfgs_runner = (ctx, base, free, starts, scale) -> begin
            calls[] += 1
            bound = calls[] == 1
            (; loglik=2.0, max_valid_loglik=2.0, components=[1.0, 1.0, 1.0],
               converged=false, hit_bound=bound,
               hit_bound_components=bound ? [(component=2, side=:lower, value=1e-13)] : Any[],
               gradient_norm=2e-6, finite_difference_error=0.0,
               analytic_gradient_valid=true, line_search_failed=false,
               optimizer_status="controlled failed start", iterations=20)
        end
        scalar_profile_runner = (ctx, make_components, scale; kwargs...) -> begin
            components = make_components(1.0)
            (; loglik=2.0, max_valid_loglik=2.0, components,
               converged=false, gradient_norm=0.0, optimizer_status="face unresolved",
               hit_bound=true, status=:nuisance_unresolved, candidates=Any[], value=1.0,
               physical_zero_endpoint_certificate=nothing)
        end
        certificate_runner = (args...) ->
            (; status=:projected_gradient_unresolved, max_valid_loglik=2.0,
               projected_loglik=2.0, projected_centered_loglik=2.0)
        resolved_boundary_certificate = (
            status = :resolved_lower_bound_by_zero_face, zero_indices = [2],
            components = [1.0, 0.0, 1.0], projected_components = [1.0, 0.0, 1.0],
            loglik = 2.0, original_loglik = 2.0, projected_loglik = 2.0,
            face_loglik = 2.0, likelihood_spread = 0.0, centered_active = false,
            candidate_centered_loglik = NaN, projected_centered_loglik = NaN,
            face_centered_loglik = NaN, candidate_max_valid_centered_loglik = NaN,
            likelihood_spread_centered = NaN, projected_log_gradient_norm = 0.0,
            analytic_active_derivatives = Dict(2 => 1e-4),
            forward_derivatives = Dict(2 => (1e-4, 1e-4)))
        polish_runner = (ctx, candidate, index, scale, df, faces, intersection,
                         initial; maximum_seen, kwargs...) -> begin
            (; status=:resolved_projected_face_polish, loglik=2.0,
               components=[1.0, 0.0, 1.0], max_valid_loglik=2.0,
               boundary_certificate=resolved_boundary_certificate,
               continuation=(; status=:resolved_projected_face_polish,
                   continuation_gradient_norm=7e-7,
                   parent_candidate_index=candidate.candidate_index,
                   max_valid_loglik=2.0))
        end
        raw = H._arc1_raw_nuisance(raw_mock_context, :additive_variance, 1.0, 1.0;
            bfgs_runner, scalar_profile_runner,
            loglik_runner=(ctx, components)->count(>(0), components) == 1 ?
                (-Inf, :singular_proposal) : (2.0, :ok),
            gradient_runner=(ctx, components; kwargs...)->(;component_gradient=zeros(3)),
            certificate_runner, polish_runner)
        search = only(filter(x -> x.kind == :raw_nuisance_search, raw.nuisance_statuses))
        @test search.resolved_by_projected_face_polish == 1
        @test search.best_certified.gradient_norm == 7e-7
        @test search.best_certified.polished_gradient_norm == 7e-7
        @test search.best_certified.original_gradient_norm == 2e-6
    end

    @testset "unresolved profiles still update the shared valid maximum" begin
        state = H._Arc1ProfileState(nothing, 1.0, -2.0,
            Dict{Symbol,Dict{Float64,Any}}(), Dict{Symbol,Int}(), -2.0, Any[])
        profile = (loglik = -Inf, max_valid_loglik = -1.5,
                   status = :nuisance_unresolved)
        @test H._arc1_include_valid_profile_max!(state, profile) == -1.5
        @test H._arc1_point_fit_not_optimal(-2.0, state.max_constrained_loglik)
    end

    function fake_profile_state(scorefn; s0 = 1.0, failfn = x -> false,
                                budget = 4097)
        state = H._Arc1ProfileState(nothing, s0, 0.0,
            Dict{Symbol,Dict{Float64,Any}}(), Dict{Symbol,Int}(), 0.0, Any[])
        calls = Ref(0)
        cache = Dict{Float64,Any}()
        evaluator = function (x)
            x = Float64(x)
            haskey(cache, x) && return cache[x]
            if calls[] >= budget
                return (loglik = -Inf, status = :unresolved_search_budget,
                        nuisance_statuses = Any[:target_evaluation_budget])
            end
            calls[] += 1
            for target in H._ARC1_PROFILE_TARGETS
                state.evaluation_counts[target] = calls[]
            end
            if failfn(x)
                cache[x] = (loglik = -Inf, status = :nuisance_unresolved,
                            nuisance_statuses = Any[:synthetic_nuisance_failure])
            else
                ll = -(scorefn(x) + H._ARC1_PROFILE_CUTOFF_95) / 2
                cache[x] = (loglik = ll, status = :ok, nuisance_statuses = Any[])
            end
            return cache[x]
        end
        return state, evaluator
    end

    @testset "artificial profile scans retain components and classify failures" begin
        # Two disjoint confidence components must both survive the scan.
        disconnected(x) = 1.0e6 * (x - 0.2) * (x - 0.4) * (x - 0.6) * (x - 0.8)
        state, evaluator = fake_profile_state(disconnected)
        result = H._arc1_target_search(state, :heritability, 0.5;
                                      profile_evaluator = evaluator)
        @test result.search_status == :finite_grid_resolved
        @test length(result.segments) == 2
        @test result.segments[1][1] ≈ 0.2 atol = 1e-6
        @test result.segments[2][2] ≈ 0.8 atol = 1e-6

        # A sampled narrow peak triggers breadth-first refinement and remains in
        # the point set used to identify its roots.
        shallow(x) = 10.0 - 20.0 * exp(-((x - 0.5025) / 0.0008)^2)
        state, evaluator = fake_profile_state(shallow)
        result = H._arc1_target_search(state, :heritability, 0.5;
                                      profile_evaluator = evaluator)
        @test result.refinements > 0
        @test result.search_status == :finite_grid_resolved
        @test length(result.segments) >= 1

        # A sampled likelihood maximum at an existing grid vertex is detected
        # even when its LR score is not cutoff-adjacent.
        vertex_peak(x) = 1.0 + 1000.0 * (x - 0.5)^2
        state, evaluator = fake_profile_state(vertex_peak)
        result = H._arc1_target_search(state, :heritability, 0.5;
                                      profile_evaluator = evaluator)
        @test result.refinements > 0
        @test result.evaluated > 401

        # The raw rail includes the upper-domain component and the full tail.
        upper_component(x) = x > 9e5 ? -0.1 : 1.0
        state, evaluator = fake_profile_state(upper_component)
        result = H._arc1_target_search(state, :additive_variance, 1.0;
                                      profile_evaluator = evaluator)
        @test result.domain[2] == 1.0e6
        @test any(segment -> segment[2] == 1.0e6, result.segments)
        @test result.search_status == :unbracketed_limits

        # Nuisance failures under the evaluation cap retain a distinct cause.
        state, evaluator = fake_profile_state(x -> 100.0 * ((x - 0.5)^2 - 0.0004);
                                              failfn = x -> 0.49 < x < 0.51)
        result = H._arc1_target_search(state, :heritability, 0.5;
                                      profile_evaluator = evaluator)
        @test result.search_status == :nuisance_unresolved
        @test result.evaluated < 4097
        @test result.nuisance_statuses[1].counts[:nuisance] > 0
        @test length(result.nuisance_statuses[1].examples[:nuisance]) <= 3

        # A genuine cap exhaustion refuses rather than returning a partial scan.
        state, evaluator = fake_profile_state(x -> x - 0.5; budget = 3)
        result = H._arc1_target_search(state, :heritability, 0.5;
                                      profile_evaluator = evaluator)
        @test result.search_status == :unresolved_search_budget
        @test result.evaluated == 3

        # Raw resolution is measured in octaves for positive values and on the
        # declared first gap in the original variance units.
        raw_grid = H._arc1_target_grid(:additive_variance, 0.4, 1.0)
        @test raw_grid[1] == 0.0
        @test raw_grid[2] <= 1e-6
        @test maximum(log2(raw_grid[i + 1] / raw_grid[i])
                      for i in 2:length(raw_grid)-1) <= 1 / 8 + 1e-10
    end

    @testset "ratio nuisance accepts zero genetic boundary and excludes singular ratio one" begin
        diagnostics = Any[]
        h0 = H._arc1_ratio_nuisance(context, :heritability, 0.0,
                                    H._arc1_profile_scale(context, (0.3, 0.2, 0.5)), diagnostics)
        h1 = H._arc1_ratio_nuisance(context, :heritability, 1.0,
                                    H._arc1_profile_scale(context, (0.3, 0.2, 0.5)), diagnostics)
        hmid = H._arc1_ratio_nuisance(context, :heritability, 0.75,
                                      H._arc1_profile_scale(context, (0.3, 0.2, 0.5)), diagnostics)
        t0 = H._arc1_ratio_nuisance(context, :repeatability, 0.0,
                                    H._arc1_profile_scale(context, (0.3, 0.2, 0.5)), diagnostics)
        @test h0.status == :ok
        @test isfinite(h0.loglik)
        @test h1.status == :singular_proposal
        @test hmid.status == :ok
        @test hmid.nuisance_statuses[1].winner_status == :brent
        @test 0.0 < hmid.nuisance_statuses[1].best_allocation < 1.0
        @test t0.status == :ok
        @test isfinite(t0.loglik)
        face = H._arc1_scalar_profile_max(context, v -> [0.0, 0.0, v],
                                          H._arc1_profile_scale(context, (0.3, 0.2, 0.5)))
        @test face.status == :ok
        @test any(c -> c.status == :brent, face.candidates)
        @test face.max_valid_loglik >= face.loglik
    end

    @testset "raw lower-bound contact resolves only through certified exact-zero face" begin
        df = 20.0
        s0 = 1.0
        ll0 = -100.0
        slope = 0.02
        curvature = 0.001
        q(x) = -ll0 / df + slope * x + curvature * x^2
        objective(components) = (-df * q(components[2] / s0), :ok)
        gradient(components; free_indices) = begin
            x = components[2] / s0
            component_gradient = [0.0, (slope + 2curvature * x) / s0, 0.0]
            (component_gradient, log_gradient = component_gradient[free_indices] .*
                components[free_indices])
        end
        face = (status = :ok, zero_index = 2, loglik = ll0,
                components = [2.0, 0.0, 3.0])
        candidate = (loglik = ll0, components = [2.0, 1e-13, 3.0],
            max_valid_loglik = ll0,
            converged = false, optimizer_converged = true, gradient_norm = 0.0,
            finite_difference_error = 0.0, analytic_gradient_valid = true,
            line_search_failed = false,
            free_indices = [2, 3], finite_difference_errors = Dict(2 => Inf, 3 => 0.0),
            hit_bound_components = [(component = 2, side = :lower, value = 1e-13)])
        certificate = H._arc1_zero_bound_face_certificate(candidate, 1, s0, df,
            [face], nothing, objective, gradient)
        @test certificate.status == :resolved_lower_bound_by_zero_face
        @test certificate.components == [2.0, 0.0, 3.0]
        @test certificate.face_loglik == ll0
        @test certificate.projected_log_gradient_norm <= 1e-6
        @test certificate.analytic_active_derivatives[2] > 5e-6
        @test all(all(>=(0), estimates) for estimates in values(certificate.forward_derivatives))
        @test maximum(abs(fd - certificate.analytic_active_derivatives[index])
                      for (index, estimates) in certificate.forward_derivatives
                      for fd in estimates) <= 5e-6
        malformed_candidate_max = Ref(ll0)
        malformed_certificate = H._arc1_zero_bound_face_certificate(
            merge(candidate, (components = nothing,
                max_valid_loglik = ll0 + 2e-8)), 1, s0, df, [face], nothing,
            objective, gradient; maximum_seen = malformed_candidate_max)
        @test malformed_certificate.status == :candidate_record_invalid
        @test malformed_candidate_max[] == ll0 + 2e-8
        bad_remaining_gradient(components; free_indices) = begin
            component_gradient = [0.0, slope / s0, 2e-6]
            (component_gradient, log_gradient = component_gradient[free_indices] .*
                components[free_indices])
        end
        gradient_refusal = H._arc1_zero_bound_face_certificate(candidate, 1, s0, df,
            [face], nothing, objective, bad_remaining_gradient)
        @test gradient_refusal.status == :projected_gradient_unresolved
        @test gradient_refusal.original_loglik == gradient_refusal.projected_loglik ==
              gradient_refusal.face_loglik
        @test gradient_refusal.projected_gradient_norm > 1e-6

        negative_objective(components) = (df * (0.1 * components[2] / s0), :ok)
        negative_gradient(components; free_indices) = begin
            component_gradient = [0.0, -0.1 / s0, 0.0]
            (component_gradient, log_gradient = component_gradient[free_indices] .*
                components[free_indices])
        end
        rejected = H._arc1_zero_bound_face_certificate(candidate, 1, s0, df,
            [merge(face, (loglik = 0.0,))], nothing, negative_objective, negative_gradient)
        @test rejected.status != :resolved_lower_bound_by_zero_face
        mismatched_face = merge(face, (loglik = ll0 + 1e-7,))
        @test H._arc1_zero_bound_face_certificate(candidate, 1, s0, df,
            [mismatched_face], nothing, objective, gradient).status == :face_likelihood_mismatch
        disallowed_residual = merge(candidate, (components = [2.0, 3.0, 1e-13],
            free_indices = [2, 3], finite_difference_errors = Dict(2 => 0.0, 3 => Inf),
            hit_bound_components = [(component = 3, side = :lower, value = 1e-13)],))
        @test H._arc1_zero_bound_face_certificate(disallowed_residual, 1, s0, df,
            [face], nothing, objective, gradient).status == :ineligible_contact
        upper = merge(candidate, (hit_bound_components =
            [(component = 2, side = :upper, value = 1e6)],))
        @test H._arc1_zero_bound_face_certificate(upper, 1, s0, df,
            [face], nothing, objective, gradient).status != :resolved_lower_bound_by_zero_face
        flat_objective(components) = (-df * (components[2] / s0)^2, :ok)
        flat_gradient(components; free_indices) = begin
            component_gradient = [0.0, 2components[2] / (s0^2), 0.0]
            (component_gradient, log_gradient = component_gradient[free_indices] .*
                components[free_indices])
        end
        flat_candidate = merge(candidate, (loglik = 0.0,))
        @test H._arc1_zero_bound_face_certificate(flat_candidate, 1, s0, df,
            [merge(face, (loglik = 0.0,))], nothing,
            flat_objective, flat_gradient).status != :resolved_lower_bound_by_zero_face

        # The intersection is the only matching reduced model for two hits.
        both = merge(candidate, (components = [1e-13, 1e-13, 3.0],
            free_indices = [1, 2], finite_difference_errors = Dict(1 => Inf, 2 => Inf),
            hit_bound_components = [(component = 1, side = :lower, value = 1e-13),
                                    (component = 2, side = :lower, value = 1e-13)]))
        intersection = (status = :ok, loglik = ll0, components = [0.0, 0.0, 3.0])
        both_objective(components) = (-df * q(components[1] / s0 + components[2] / s0), :ok)
        both_gradient(components; free_indices) = begin
            component_gradient = fill((slope + 2curvature *
                (components[1] + components[2]) / s0) / s0, 3)
            component_gradient[3] = 0.0
            (component_gradient, log_gradient = component_gradient[free_indices] .*
                components[free_indices])
        end
        both_certificate = H._arc1_zero_bound_face_certificate(both, 3, s0, df,
            Any[], intersection, both_objective, both_gradient)
        @test both_certificate.status == :resolved_lower_bound_by_zero_face
        @test both_certificate.components == [0.0, 0.0, 3.0]

        # A matching final boundary likelihood cannot erase a better valid
        # interior value visited earlier by this same failed optimizer start.
        better_interior = merge(candidate, (max_valid_loglik = ll0 + 2e-8,))
        @test H._arc1_zero_bound_face_certificate(better_interior, 1, s0, df,
            [face], nothing, objective, gradient).status == :candidate_maximum_mismatch

        # The certified face, rather than the approximate projection, supplies
        # the accepted components and likelihood. The projection remains a
        # separate diagnostic.
        different_face = merge(face, (components = [2.0, 0.0, 3.25],))
        face_result = H._arc1_zero_bound_face_certificate(candidate, 1, s0, df,
            [different_face], nothing, objective, gradient)
        @test face_result.status == :resolved_lower_bound_by_zero_face
        @test face_result.components == different_face.components
        @test face_result.loglik == different_face.loglik
        @test face_result.projected_components == [2.0, 0.0, 3.0]
    end

    @testset "fixed-Ve certificates use centered values without relaxing limits" begin
        df, s0, Ve = 159.0, 0.9601740644340048, 9.814158264884749e-7
        analytic = 0.007596111699614222
        centered_q(components) = 2.0 + analytic * components[1] / s0
        centered_at(components) = (-df * centered_q(components), :ok)
        large_constant = -1.7798907109322877e7
        full_at(components) = (centered_at(components)[1] + large_constant, :ok)
        gradient_at(components; free_indices) = begin
            component_gradient = [analytic / s0, 0.0, 0.0]
            (loglik = full_at(components)[1], component_gradient = component_gradient,
             log_gradient = component_gradient[free_indices] .* components[free_indices])
        end
        face_components = [0.0, 0.7451276801470778, Ve]
        face_center = centered_at(face_components)[1]
        face = (status = :ok, zero_index = 1,
                loglik = full_at(face_components)[1], centered_loglik = face_center,
                centering_ve = Ve, components = face_components)
        candidate_components = [8.732732243825042e-13, 0.7451281637812672, Ve]
        candidate_center = centered_at(candidate_components)[1]
        candidate = (loglik = full_at(candidate_components)[1],
            centered_loglik = candidate_center, max_valid_loglik = full_at(candidate_components)[1],
            max_valid_centered_loglik = candidate_center + 8.18e-12, centering_ve = Ve,
            components = candidate_components, converged = false, optimizer_converged = true,
            gradient_norm = 0.0, finite_difference_error = 0.0,
            analytic_gradient_valid = true, line_search_failed = false,
            free_indices = [1, 2], finite_difference_errors = Dict(1 => Inf, 2 => 0.0),
            hit_bound_components = [(component = 1, side = :lower, value = candidate_components[1])])
        certificate = H._arc1_zero_bound_face_certificate(candidate, 3, s0, df,
            [face], nothing, full_at, gradient_at;
            centered_loglik_at = centered_at, centering_ve = Ve,
            historical_likelihoods = [candidate.max_valid_loglik],
            historical_centered_likelihoods = [candidate.max_valid_centered_loglik])
        @test certificate.status == :resolved_lower_bound_by_zero_face
        @test certificate.likelihood_spread_centered <= 1e-8
        @test certificate.analytic_active_derivatives[1] ≈ analytic atol = 1e-14
        @test maximum(abs(fd - analytic) for fd in certificate.forward_derivatives[1]) < 5e-6
        @test certificate.loglik == face.loglik

        # The real saved candidate 7 has a centered candidate-to-face spread
        # above the unchanged threshold and remains unresolved.
        candidate7_components = [8.732732243825042e-13, 0.7450648653896434, 8.88276206174465e-5]
        face7_components = [0.0, 0.7450842922916205, candidate7_components[3]]
        candidate7_center = centered_at(candidate7_components)[1]
        face7_center = candidate7_center + 1.3393630342542925e-8
        c7 = merge(candidate, (components = candidate7_components,
            loglik = full_at(candidate7_components)[1], centered_loglik = candidate7_center,
            max_valid_loglik = full_at(candidate7_components)[1],
            max_valid_centered_loglik = candidate7_center,
            centering_ve = candidate7_components[3]))
        face7 = merge(face, (components = face7_components,
            loglik = full_at(face7_components)[1], centered_loglik = face7_center,
            centering_ve = candidate7_components[3]))
        refused = H._arc1_zero_bound_face_certificate(c7, 3, s0, df,
            [face7], nothing, full_at, gradient_at;
            centered_loglik_at = centered_at, centering_ve = candidate7_components[3])
        @test refused.status == :face_likelihood_mismatch
        @test refused.likelihood_spread_centered > 1e-8
        @test refused.likelihood_spread_centered ≈ 1.3393630342542925e-8 atol = 2e-14
        wrong_face_tag = merge(face, (centering_ve = 2Ve,))
        wrong_face_certificate = H._arc1_zero_bound_face_certificate(candidate, 3, s0, df,
            [wrong_face_tag], nothing, full_at, gradient_at;
            centered_loglik_at = centered_at, centering_ve = Ve)
        @test wrong_face_certificate.status == :centering_tag_mismatch_face
        @test wrong_face_certificate.observed_centering_ve == 2Ve

        # Even when the full likelihoods are indistinguishable at this scale,
        # an improving same-Ve centered probe remains a competitive failure.
        centered_probe = (loglik = large_constant, max_valid_loglik = large_constant,
            centered_loglik = -2.0, max_valid_centered_loglik = -1.9999998,
            centering_ve = Ve, converged = false, hit_bound = true)
        @test H._arc1_raw_competitor_is_competitive(centered_probe, -2.0;
            centering_ve = Ve)
        wrong_ve_probe = merge(centered_probe, (centering_ve = 2Ve,))
        @test !H._arc1_raw_competitor_is_competitive(wrong_ve_probe, -2.0;
            centering_ve = Ve)
        untagged_probe = (loglik = large_constant, max_valid_loglik = large_constant,
            converged = false, hit_bound = true)
        @test !H._arc1_raw_competitor_is_competitive(untagged_probe, -2.0;
            centering_ve = Ve)
        @test H._arc1_profile_comparison_loglik(centered_probe, Ve) == -2.0
        @test H._arc1_profile_comparison_loglik(wrong_ve_probe, Ve) == -Inf
    end

    @testset "failed profile paths retain their best valid likelihood" begin
        state = H._Arc1ProfileState(nothing, 1.0, 0.0,
            Dict{Symbol,Dict{Float64,Any}}(), Dict{Symbol,Int}(), -Inf, Any[])
        @test H._arc1_include_valid_profile_max!(state,
            (loglik = -Inf, max_valid_loglik = 2.0, status = :nuisance_unresolved)) == 2.0
        @test H._arc1_point_fit_not_optimal(1.0, state.max_constrained_loglik)

        # A valid BFGS trial remains part of the shared maximum even if a later
        # optimizer callback throws and no final candidate is returned.
        failed_bfgs = H._arc1_bfgs_candidate(context, zeros(3), [1, 2, 3],
            [0.3, 0.2, 0.5], 1.0; optimizer_runner = (objective, gradient!, start) -> begin
                objective(start)
                objective(start .+ 0.001)
                error("synthetic optimizer exit after valid trials")
            end)
        @test failed_bfgs.loglik == -Inf
        @test isfinite(failed_bfgs.max_valid_loglik)
        failed_state = H._Arc1ProfileState(nothing, 1.0, 0.0,
            Dict{Symbol,Dict{Float64,Any}}(), Dict{Symbol,Int}(), -Inf, Any[])
        H._arc1_include_valid_profile_max!(failed_state, failed_bfgs)
        @test failed_state.max_constrained_loglik == failed_bfgs.max_valid_loglik
        @test H._arc1_point_fit_not_optimal(failed_bfgs.max_valid_loglik - 1e-6,
                                            failed_state.max_constrained_loglik)

        # A Brent exception still returns its best finite log-likelihood trial.
        failed_brent = H._arc1_bounded_brent(x -> x < 0.5 ? -12.0 :
            error("synthetic objective exception"), 0.0, 1.0;
            x_tolerance = 1e-7, max_evaluations = 20)
        @test failed_brent.result === nothing
        @test failed_brent.max_valid_loglik == 12.0
        cache = Dict(0.25 => 9.0, 0.4 => 11.0, 0.75 => 20.0)
        failed_ratio_no_result = (result = nothing, max_valid_loglik = 10.0)
        failed_ratio_uncertified = (result = :uncertified, max_valid_loglik = 12.0)
        @test H._arc1_unresolved_brent_max(cache, failed_ratio_no_result,
            0.0, 0.5) == 11.0
        @test H._arc1_unresolved_brent_max(cache, failed_ratio_uncertified,
            0.0, 0.5) == 12.0
        ratio_failure = (loglik = -Inf,
            max_valid_loglik = H._arc1_unresolved_brent_max(cache,
                failed_ratio_uncertified, 0.0, 0.5), status = :nuisance_unresolved)
        ratio_state = H._Arc1ProfileState(nothing, 1.0, 0.0,
            Dict{Symbol,Dict{Float64,Any}}(), Dict{Symbol,Int}(), -Inf, Any[])
        H._arc1_include_valid_profile_max!(ratio_state, ratio_failure)
        @test H._arc1_point_fit_not_optimal(11.0, ratio_state.max_constrained_loglik)

        # The raw-nuisance reduction must not drop a valid maximum merely
        # because every final result is marked failed.
        failed_candidates = [(loglik = -Inf, max_valid_loglik = 13.0),
                             (loglik = -Inf, max_valid_loglik = 12.0)]
        @test H._arc1_max_valid_profile_likelihood(failed_candidates) == 13.0
        @test H._arc1_raw_competitor_is_competitive(
            (converged = false, loglik = -Inf, max_valid_loglik = 13.0,
             hit_bound = false), 12.0)

        # Certificate likelihood and gradient probes share one maximum recorder.
        probe_max = Ref(-Inf)
        probe_ll(components) = (components[1], :ok)
        probe_gradient(components; free_indices) =
            (loglik = components[1] + 0.25,
             component_gradient = zeros(3), log_gradient = zeros(length(free_indices)))
        recorded_ll, recorded_gradient = H._arc1_profile_probe_recorders!(
            probe_max, probe_ll, probe_gradient)
        @test recorded_ll([4.0, 0.0, 1.0]) == (4.0, :ok)
        @test recorded_gradient([5.0, 0.0, 1.0]; free_indices = [3]).loglik == 5.25
        @test probe_max[] == 5.25

        # If a later certificate callback throws, earlier valid values survive
        # and still invalidate the shared point fit.
        throw_calls = Ref(0)
        throwing_ll(components) = (throw_calls[] += 1;
            throw_calls[] == 1 ? (components[1], :ok) :
            error("synthetic later certificate failure"))
        throwing_recorded_ll, _ = H._arc1_profile_probe_recorders!(
            probe_max, throwing_ll, probe_gradient)
        @test throwing_recorded_ll([7.0, 0.0, 1.0]) == (7.0, :ok)
        @test_throws ErrorException throwing_recorded_ll([8.0, 0.0, 1.0])
        @test probe_max[] == 7.0
        H._arc1_include_valid_profile_max!(state,
            (loglik = -Inf, max_valid_loglik = probe_max[], status = :nuisance_unresolved))
        @test state.max_constrained_loglik == 7.0
        @test H._arc1_point_fit_not_optimal(6.0, state.max_constrained_loglik)

        point_failure = H._arc1_point_failure_result(nothing, :heritability,
                                                     :point_fit_unconverged)
        @test hasproperty(point_failure, :point_fit_not_optimal)
        @test !point_failure.point_fit_not_optimal
    end

    @testset "physical zero endpoint certifies only a valid reduced scalar face" begin
        df, s0 = 20.0, 1.0
        q0, slope, curvature = 5.0, 0.02, 0.001
        endpoint = [0.0, 0.0, 3.0] # Va held at zero; Ve target fixed
        make_components(value) = [0.0, value, 3.0]
        q(components) = q0 + slope * components[2] / s0 +
                        curvature * (components[2] / s0)^2
        objective(components) = (-df * q(components), :ok)
        gradient(components; free_indices) = begin
            component_gradient = [0.0,
                (slope + 2curvature * components[2] / s0) / s0, 0.0]
            (loglik = -df * q(components), component_gradient = component_gradient,
             log_gradient = component_gradient[free_indices] .* components[free_indices])
        end
        lower = make_components(s0 * 2.0^-40)
        lower_ll = first(objective(lower))
        cert = H._arc1_physical_zero_endpoint_certificate(make_components, 2, 3, 1,
            s0, df, lower, lower_ll, Ref(lower_ll), objective, gradient)
        @test cert.status == :resolved_physical_zero_endpoint
        @test cert.components == endpoint
        @test cert.loglik == first(objective(endpoint))
        @test cert.analytic_derivative > 5e-6
        @test all(>=(0), cert.forward_derivatives)
        @test abs(cert.forward_derivatives[1] - cert.analytic_derivative) <= 5e-6
        @test abs(cert.forward_derivatives[2] - cert.analytic_derivative) <= 5e-6

        @test H._arc1_physical_zero_endpoint_certificate(make_components, 2, 3, 1,
            s0, df, lower, lower_ll, Ref(lower_ll + 2e-8), objective, gradient).status ==
            :better_probe_likelihood
        @test H._arc1_physical_zero_endpoint_certificate(make_components, 2, 3, 1,
            s0, df, lower, lower_ll + 2e-7, Ref(lower_ll), objective, gradient).status ==
            :lower_endpoint_likelihood_mismatch
        better_probe(components; free_indices) = merge(gradient(components; free_indices),
            (loglik = first(objective(endpoint)) + 2e-8,))
        @test H._arc1_physical_zero_endpoint_certificate(make_components, 2, 3, 1,
            s0, df, lower, lower_ll, Ref(lower_ll), objective, better_probe).status ==
            :better_probe_likelihood
        singular(components) = (NaN, :singular_proposal)
        singular_certificate = H._arc1_physical_zero_endpoint_certificate(
            make_components, 2, 3, 1, s0, df, lower, lower_ll, Ref(lower_ll),
            singular, gradient)
        @test singular_certificate.status == :physical_zero_endpoint_invalid
        @test isnan(singular_certificate.endpoint_loglik)
        @test !singular_certificate.endpoint_loglik_valid
        @test singular_certificate.max_valid_loglik == lower_ll
        flat_gradient(components; free_indices) = merge(gradient(components; free_indices),
            (component_gradient = zeros(3),))
        @test H._arc1_physical_zero_endpoint_certificate(make_components, 2, 3, 1,
            s0, df, lower, lower_ll, Ref(lower_ll), objective, flat_gradient).status ==
            :endpoint_derivative_not_positive
        mismatch(components) = (first(objective(components)) + 1e-5, :ok)
        @test H._arc1_physical_zero_endpoint_certificate(make_components, 2, 3, 1,
            s0, df, lower, lower_ll, Ref(lower_ll), mismatch, gradient).status ==
            :lower_endpoint_likelihood_mismatch
        changed_other = [0.1, lower[2], 3.0]
        @test H._arc1_physical_zero_endpoint_certificate(make_components, 2, 3, 1,
            s0, df, changed_other, lower_ll, Ref(lower_ll), objective, gradient).status ==
            :fixed_components_mismatch
        @test H._arc1_physical_zero_endpoint_certificate(make_components, 3, 2, 1,
            s0, df, lower, lower_ll, Ref(lower_ll), objective, gradient).status ==
            :ineligible_zero_endpoint
    end

    @testset "certified physical-zero endpoint supersedes its artificial scalar endpoint" begin
        s0 = 1.0
        df = context.residual_df
        q0, slope, curvature = 2.0, 0.02, 0.001
        make_components(value) = [value, 0.0, 3.0]
        endpoint_ll = -df * q0
        function scalar_ll(components, bump)
            value = components[1]
            lower = s0 * 2.0^-40
            if isapprox(value, lower; rtol = 1e-12, atol = 0.0)
                return endpoint_ll + bump, :ok
            end
            x = value / s0
            return -df * (q0 + slope * x + curvature * x^2), :ok
        end
        scalar_gradient(components; free_indices) = begin
            x = components[1] / s0
            component_gradient = [(slope + 2curvature * x) / s0, 0.0, 0.0]
            (loglik = -df * (q0 + slope * x + curvature * x^2),
             component_gradient = component_gradient,
             log_gradient = component_gradient[free_indices] .* components[free_indices])
        end
        for bump in (0.0, 5e-9)
            result = H._arc1_scalar_profile_max(context, make_components, s0;
                physical_zero_component = 1, target_component = 3,
                held_zero_component = 2,
                profile_loglik_at = components -> scalar_ll(components, bump),
                profile_gradient_at = scalar_gradient)
            @test result.physical_zero_endpoint_certificate.status ==
                  :resolved_physical_zero_endpoint
            @test result.status == :ok
            @test result.value == 0.0
            @test result.winner_status == :physical_zero_endpoint
            @test !isempty(result.superseded_lower_endpoint_indices)
            artificial = result.candidates[only(result.superseded_lower_endpoint_indices)]
            @test artificial.loglik == endpoint_ll + bump
            @test result.max_valid_loglik == endpoint_ll + bump
        end
    end

    @testset "projected-face polish is one bounded continuation from its own projection" begin
        df, s0, ll0 = 20.0, 1.0, -100.0
        slope, curvature = 0.02, 0.001
        q(x) = -ll0 / df + slope * x + curvature * x^2
        objective(components) = (-df * q(components[2] / s0), :ok)
        exact_gradient(components; free_indices) = begin
            x = components[2] / s0
            component_gradient = [0.0, (slope + 2curvature * x) / s0, 0.0]
            (loglik = first(objective(components)), component_gradient = component_gradient,
             log_gradient = component_gradient[free_indices] .* components[free_indices])
        end
        initial_bad_gradient(components; free_indices) = begin
            g = exact_gradient(components; free_indices)
            component_gradient = copy(g.component_gradient)
            component_gradient[3] = 2e-6
            (loglik = g.loglik, component_gradient = component_gradient,
             log_gradient = component_gradient[free_indices] .* components[free_indices])
        end
        face = (status = :ok, zero_index = 2, loglik = ll0,
                components = [2.0, 0.0, 3.0])
        original = (candidate_index = 4, loglik = ll0,
            max_valid_loglik = ll0, components = [2.0, 1e-13, 3.0],
            converged = false, optimizer_converged = true, gradient_norm = 0.0,
            finite_difference_error = 0.0, analytic_gradient_valid = true,
            line_search_failed = false, free_indices = [2, 3],
            finite_difference_errors = Dict(2 => Inf, 3 => 0.0),
            hit_bound = true, iterations = 40,
            hit_bound_components = [(component = 2, side = :lower, value = 1e-13)])
        initial = H._arc1_zero_bound_face_certificate(original, 1, s0, df,
            [face], nothing, objective, initial_bad_gradient)
        @test initial.status == :projected_gradient_unresolved
        function polished_result(base, free, start, iterations; kwargs...)
            (loglik = ll0, max_valid_loglik = ll0, components = copy(base),
             free_indices = copy(free), converged = true, gradient_norm = 0.0,
             optimizer_converged = true, analytic_gradient_valid = true,
             line_search_failed = false, finite_difference_errors = Dict(3 => 0.0),
             finite_difference_error = 0.0, hit_bound = false,
             hit_bound_components = Any[], iterations = 100,
             objective_evaluations = 23, gradient_evaluations = 8,
             termination_code = :gradient_converged, stopped_by = :gradient,
             optimizer_status = "converged")
        end
        runner_calls = Ref(0)
        starts_seen = Ref{Any}(nothing)
        runner = (ctx, base, free, start, scale, budget) -> begin
            runner_calls[] += 1
            starts_seen[] = (copy(base), copy(free), copy(start), budget)
            polished_result(base, free, start, budget)
        end
        maximum_seen = Ref(ll0)
        result = H._arc1_projected_face_polish(context, original, 1, s0, df,
            [face], nothing, initial; maximum_seen, loglik_at = objective,
            gradient_at = exact_gradient, continuation_runner = runner)
        @test result.status == :resolved_projected_face_polish
        @test result.components == [2.0, 0.0, 3.0]
        @test result.loglik == ll0
        @test starts_seen[] == ([2.0, 0.0, 3.0], [3], [3.0], 1960)
        @test runner_calls[] == 1
        @test result.continuation.parent_candidate_index == 4
        @test result.continuation.original_iterations == 40
        @test result.continuation.continuation_iterations == 100
        @test result.continuation.combined_iterations == 140
        @test result.continuation.objective_evaluations == 23
        @test result.continuation.gradient_evaluations == 8
        @test original.components == [2.0, 1e-13, 3.0]
        @test original.loglik == ll0

        # Exhaustion does not invoke an optimizer or increase its allowance.
        exhausted = merge(original, (iterations = 2000,))
        exhausted_calls = Ref(0)
        no_runner = (args...) -> (exhausted_calls[] += 1; polished_result(args[2],
            args[3], args[4], args[6]))
        exhausted_result = H._arc1_projected_face_polish(context, exhausted, 1,
            s0, df, [face], nothing, initial; maximum_seen = Ref(ll0),
            loglik_at = objective, gradient_at = exact_gradient,
            continuation_runner = no_runner)
        @test exhausted_result.status == :iteration_budget_exhausted
        @test exhausted_result.continuation.parent_candidate_index == 4
        @test exhausted_calls[] == 0

        no_coordinates = merge(original, (free_indices=[1],))
        no_coordinates_result = H._arc1_projected_face_polish(context, no_coordinates,
            1, s0, df, [face], nothing, initial; maximum_seen=Ref(ll0),
            loglik_at=objective, gradient_at=exact_gradient)
        @test no_coordinates_result.status == :no_remaining_positive_coordinates
        @test no_coordinates_result.continuation.parent_candidate_index == 4

        exception_runner = (args...) -> error("controlled continuation exception")
        exception_result = H._arc1_projected_face_polish(context, original, 1,
            s0, df, [face], nothing, initial; maximum_seen=Ref(ll0),
            loglik_at=objective, gradient_at=exact_gradient,
            continuation_runner=exception_runner)
        @test exception_result.status == :continuation_exception
        @test exception_result.continuation.parent_candidate_index == 4
        @test occursin("controlled continuation exception",
                       exception_result.continuation.error)

        # A second bound contact is retained as a refusal.
        another_bound_runner = (ctx, base, free, start, scale, budget) ->
            merge(polished_result(base, free, start, budget),
                  (converged = false,
                   hit_bound_components = [(component = 3, side = :lower, value = 1e-13)]))
        another_bound = H._arc1_projected_face_polish(context, original, 1, s0,
            df, [face], nothing, initial; maximum_seen = Ref(ll0),
            loglik_at = objective, gradient_at = exact_gradient,
            continuation_runner = another_bound_runner)
        @test another_bound.status == :additional_bound_contact

        better_history_runner = (ctx, base, free, start, scale, budget) ->
            merge(polished_result(base, free, start, budget),
                  (max_valid_loglik = ll0 + 2e-8,))
        better_history_max = Ref(ll0)
        better_history = H._arc1_projected_face_polish(context, original, 1,
            s0, df, [face], nothing, initial; maximum_seen = better_history_max,
            loglik_at = objective, gradient_at = exact_gradient,
            continuation_runner = better_history_runner)
        @test better_history.status == :candidate_maximum_mismatch
        @test better_history_max[] == ll0 + 2e-8

        better_probe_gradient(components; free_indices) = merge(
            exact_gradient(components; free_indices), (loglik = ll0 + 2e-8,))
        better_probe_max = Ref(ll0)
        better_probe = H._arc1_projected_face_polish(context, original, 1,
            s0, df, [face], nothing, initial; maximum_seen = better_probe_max,
            loglik_at = objective, gradient_at = better_probe_gradient,
            continuation_runner = runner)
        @test better_probe.status == :better_probe_likelihood
        @test better_probe_max[] == ll0 + 2e-8

        failed_gradient_runner = (ctx, base, free, start, scale, budget) ->
            merge(polished_result(base, free, start, budget),
                  (converged = false, gradient_norm = 2e-6,))
        failed_gradient = H._arc1_projected_face_polish(context, original, 1,
            s0, df, [face], nothing, initial; maximum_seen = Ref(ll0),
            loglik_at = objective, gradient_at = exact_gradient,
            continuation_runner = failed_gradient_runner)
        @test failed_gradient.status == :continuation_unresolved

        failed_fd_runner = (ctx, base, free, start, scale, budget) ->
            merge(polished_result(base, free, start, budget),
                  (converged = false, finite_difference_errors = Dict(3 => 6e-6),))
        failed_fd = H._arc1_projected_face_polish(context, original, 1, s0,
            df, [face], nothing, initial; maximum_seen = Ref(ll0),
            loglik_at = objective, gradient_at = exact_gradient,
            continuation_runner = failed_fd_runner)
        @test failed_fd.status == :continuation_unresolved

        mismatch_runner = (ctx, base, free, start, scale, budget) ->
            merge(polished_result(base, free, start, budget),
                  (loglik = ll0 + 2e-7, max_valid_loglik = ll0 + 2e-7,))
        mismatch = H._arc1_projected_face_polish(context, original, 1, s0,
            df, [face], nothing, initial; maximum_seen = Ref(ll0),
            loglik_at = objective, gradient_at = exact_gradient,
            continuation_runner = mismatch_runner)
        @test mismatch.status == :face_likelihood_mismatch

        # A converged-looking partial adapter record is refused after its
        # returned history is ingested; it cannot reach the merger below.
        partial_continuation_runner = (ctx, base, free, start, scale, budget) ->
            (loglik = ll0 - 1.0, max_valid_loglik = ll0 + 2e-8,
             components = copy(base), iterations = 4, converged = true,
             free_indices = copy(free))
        partial_continuation_max = Ref(ll0)
        partial_continuation = H._arc1_projected_face_polish(context, original,
            1, s0, df, [face], nothing, initial;
            maximum_seen = partial_continuation_max, loglik_at = objective,
            gradient_at = exact_gradient,
            continuation_runner = partial_continuation_runner)
        @test partial_continuation.status == :continuation_record_invalid
        @test partial_continuation_max[] == ll0 + 2e-8

        partial_initial_certificate = (status = :projected_gradient_unresolved,
            max_valid_loglik = ll0 + 3e-8)
        partial_certificate_max = Ref(ll0)
        partial_certificate = H._arc1_projected_face_polish(context, original,
            1, s0, df, [face], nothing, partial_initial_certificate;
            maximum_seen = partial_certificate_max, loglik_at = objective,
            gradient_at = exact_gradient)
        @test partial_certificate.status == :initial_certificate_record_invalid
        @test partial_certificate_max[] == ll0 + 3e-8
        missing_status_max = Ref(ll0)
        missing_status_certificate = H._arc1_projected_face_polish(context,
            original, 1, s0, df, [face], nothing,
            (max_valid_loglik = ll0 + 4e-8,);
            maximum_seen = missing_status_max, loglik_at = objective,
            gradient_at = exact_gradient)
        @test missing_status_certificate.status == :initial_certificate_record_invalid
        @test missing_status_max[] == ll0 + 4e-8
    end

    @testset "raw nuisance optimizer only stops on the gradient" begin
        options = H._arc1_bfgs_options()
        @test options.iterations == 2000
        @test options.g_abstol == 1e-8
        @test options.f_reltol == 0.0
        @test options.x_abstol == 0.0
    end

    if get(ENV, "ARC1_SKIP_EXPENSIVE_PROFILE_WRAPPER", "0") != "1"
    @testset "all-five Arc1 profile wrapper reports one shared point maximum" begin
        fit = H._arc1_repeatability_profile_intervals(y, X, Z, Ainv)
        @test fit.point_fit_status == :ok
        @test !fit.point_fit_not_optimal
        @test Set(keys(fit.targets)) == Set(H._ARC1_PROFILE_TARGETS)
        @test fit.method_version == :arc1_profile_v1
        @test fit.loglik_convention == :reml_omit_2pi
        formed_count = 0
        for target_name in H._ARC1_PROFILE_TARGETS
            target_fit = fit.targets[target_name]
            @test target_fit.search_status in (:finite_grid_resolved, :nuisance_unresolved,
                :root_unresolved, :resolution_unresolved, :unbracketed_limits,
                :unresolved_search_budget, :unresolved_search, :point_fit_not_optimal)
            @test target_fit.formed == (target_fit.search_status == :finite_grid_resolved &&
                                        !isempty(target_fit.confidence_set))
            target_fit.formed && (formed_count += 1)
            @test length(target_fit.profile_diagnostics) == target_fit.evaluated
            @test target_fit.evaluated <= 4097
        end
        @test formed_count >= 1
        @test fit.targets[:repeatability].formed
        @test_throws ArgumentError H._arc1_repeatability_profile_intervals(y, X, Z, Ainv;
                                                                           level = 0.9)
        @test_throws ArgumentError H._arc1_repeatability_profile_intervals(y, X, Z, Ainv;
                                                                           cutoff = 3.0)
    end
    end
    end
end
end

# These bounded contract tests run in every profile-file mode. They exercise
# no whole-profile wrapper or Optim optimizer and guard producer provenance,
# inheritance, and interruption behavior in the mandatory suite.
@testset "Arc1 v3 bounded producer, provenance, and callback contracts" begin
        yv3, _, Zv3, Ainvv3, _ = _arc1_test_data()
        na_v3 = size(Zv3, 2)
        Xv3 = hcat(ones(length(yv3)), repeat(collect(1.0:na_v3), inner = 2))
        ctx_v3 = H._arc1_profile_context(yv3, Xv3, Zv3, Ainvv3)
        Ve_v3 = 1.25

        @testset "native scalar callbacks are components-only" begin
            full_calls, gradient_calls = Ref(0), Ref(0)
            polynomial_full(components) = begin
                full_calls[] += 1
                (-10.0 - 0.01 * sum(components[1:2]), :ok)
            end
            polynomial_centered(components) =
                (-7.0 - 0.01 * sum(components[1:2]), :ok)
            polynomial_gradient(components; free_indices) = begin
                gradient_calls[] += 1
                (; loglik = -10.0 - 0.01 * sum(components[1:2]),
                   component_gradient = [0.01 / ctx_v3.residual_df,
                       0.01 / ctx_v3.residual_df, 0.0])
            end
            make_components(value) = [0.0, Float64(value), Ve_v3]
            scalar = H._arc1_scalar_profile_max(ctx_v3, make_components, 1.0;
                physical_zero_component = 2, target_component = 3,
                held_zero_component = 1,
                profile_loglik_at = polynomial_full,
                profile_gradient_at = polynomial_gradient,
                centered_loglik_at = polynomial_centered,
                centering_ve = Ve_v3)
            @test full_calls[] > 0
            @test gradient_calls[] > 0
            @test all(candidate.status != :brent for candidate in scalar.candidates)
        end

        function native_bfgs_v3(ctx, base, free, start, scale)
            components = copy(base)
            components[free] .= start
            score = -20.0 - sum(components[1:2])
            centered_score = -15.0 - sum(components[1:2])
            return (loglik = score, max_valid_loglik = score,
                centered_loglik = centered_score,
                max_valid_centered_loglik = centered_score,
                centering_ve = Ve_v3, components, converged = true,
                optimizer_converged = true, optimizer_status = "converged",
                termination_code = H.Optim.TerminationCode.GradientNorm,
                analytic_gradient_valid = true, line_search_failed = false,
                iterations = 1, free_indices = copy(free),
                finite_difference_errors = Dict(i => 0.0 for i in free),
                gradient_norm = 0.0, hit_bound = false,
                hit_bound_components = Any[])
        end
        raw_loglik_v3(ctx, components) = (-20.0 - sum(components[1:2]), :ok)
        raw_gradient_v3(ctx, components; free_indices = 1:3) =
            (; loglik = first(raw_loglik_v3(ctx, components)),
               component_gradient = [0.0, 0.0, 0.0])

        @testset "raw caller binds callbacks to native scalar signatures" begin
            full_calls, gradient_calls = Ref(0), Ref(0)
            polynomial_full(components) = begin
                full_calls[] += 1
                (-10.0 - 0.01 * sum(components[1:2]), :ok)
            end
            polynomial_centered(components) =
                (-7.0 - 0.01 * sum(components[1:2]), :ok)
            function polynomial_gradient(ctx, components; free_indices = 1:3)
                gradient_calls[] += 1
                (; loglik = first(polynomial_full(components)),
                   component_gradient = [0.01 / ctx_v3.residual_df,
                       0.01 / ctx_v3.residual_df, 0.0])
            end
            raw_polynomial_full(ctx, components) = polynomial_full(components)
            function native_scalar_consumer(ctx, make_components, scale;
                    profile_loglik_at, profile_gradient_at, centering_ve,
                    physical_zero_component, target_component, held_zero_component,
                    kwargs...)
                return H._arc1_scalar_profile_max(ctx, make_components, scale;
                    profile_loglik_at, profile_gradient_at,
                    centered_loglik_at = polynomial_centered, centering_ve,
                    physical_zero_component, target_component, held_zero_component)
            end
                raw = H._arc1_raw_nuisance(ctx_v3, :residual_variance, Ve_v3, 1.0;
                    method_version = :arc1_profile_v3, bfgs_runner = native_bfgs_v3,
                    scalar_profile_runner = native_scalar_consumer,
                    loglik_runner = raw_polynomial_full,
                gradient_runner = polynomial_gradient)
            @test full_calls[] > 0
            @test gradient_calls[] > 0
            @test raw.method_version == :arc1_profile_v3
            @test all(d -> d.status != :scalar_callback_exception,
                filter(d -> d.kind == :exact_zero_face, raw.nuisance_statuses))
        end

        @testset "native aliases are accepted and real container cycles refuse" begin
            endpoint = (status = :endpoint_forward_derivative_unresolved,
                loglik = -10.0, endpoint_loglik_valid = true,
                centered_loglik = -7.0, endpoint_centered_loglik = -7.0,
                endpoint_centered_loglik_valid = true, centering_ve = Ve_v3)
            scalar_with_alias(ctx, make_components, scale; kwargs...) = begin
                components = make_components(0.5)
                (status = :nuisance_unresolved, value = 0.5,
                 loglik = -30.0, max_valid_loglik = -30.0,
                 centered_loglik = -25.0, max_valid_centered_loglik = -25.0,
                 centering_ve = Ve_v3, components,
                 candidates = [(boundary_certificate = endpoint,)],
                 physical_zero_endpoint_certificate = endpoint)
            end
            alias_result = H._arc1_raw_nuisance(ctx_v3, :residual_variance,
                Ve_v3, 1.0; method_version = :arc1_profile_v3,
                bfgs_runner = native_bfgs_v3,
                scalar_profile_runner = scalar_with_alias,
                loglik_runner = raw_loglik_v3, gradient_runner = raw_gradient_v3)
            alias_diagnostic = only(filter(d -> d.kind == :raw_nuisance_search,
                alias_result.nuisance_statuses))
            @test !any(f -> f.reason == :cycle_detected,
                alias_diagnostic.v3_history_provenance_failures)

            shared = (status = :ok, loglik = -1.0)
            alias_record = (physical_zero_endpoint_certificate = shared,
                candidates = [(boundary_certificate = shared,)])
            alias_history = H._arc1_profile_v3_history!(Ref(-Inf), Ref(-Inf),
                alias_record, Ve_v3)
            @test isempty(alias_history.provenance_failures)
            dictionary_cycle = Dict{Symbol,Any}()
            dictionary_cycle[:observations] = dictionary_cycle
            dictionary_history = H._arc1_profile_v3_history!(Ref(-Inf),
                Ref(-Inf), (observations = dictionary_cycle,), Ve_v3)
            @test any(f -> f.reason == :cycle_detected,
                dictionary_history.provenance_failures)
            vector_cycle = Any[]
            push!(vector_cycle, vector_cycle)
            vector_history = H._arc1_profile_v3_history!(Ref(-Inf), Ref(-Inf),
                (observations = vector_cycle,), Ve_v3)
            @test any(f -> f.reason == :cycle_detected,
                vector_history.provenance_failures)
        end

        @testset "original centered maxima require original producer tags" begin
            tag_cases = ((nothing, Ve_v3, 1.0), (2Ve_v3, Ve_v3, 1.0),
                (Ve_v3, 2Ve_v3, 100.0), (Ve_v3, nothing, 100.0))
            for (original_tag, current_tag, expected) in tag_cases
                fields = (original_native_max_valid_centered_loglik = 100.0,
                    max_valid_centered_loglik = 1.0)
                original_tag === nothing ||
                    (fields = merge(fields,
                        (original_native_centering_ve = original_tag,)))
                current_tag === nothing ||
                    (fields = merge(fields, (centering_ve = current_tag,)))
                full, centered = Ref(-Inf), Ref(-Inf)
                history = H._arc1_profile_v3_history!(full, centered,
                    fields, Ve_v3)
                @test centered[] == expected
                if original_tag !== Ve_v3 || current_tag !== Ve_v3
                    @test !isempty(history.provenance_failures)
                end
            end

            missing_original_bfgs(ctx, base, free, start, scale) =
                merge(native_bfgs_v3(ctx, base, free, start, scale),
                    (original_native_max_valid_centered_loglik = 100.0,))
            scalar_below_original(ctx, make_components, scale; kwargs...) = begin
                components = make_components(0.5)
                (status = :nuisance_unresolved, value = 0.5,
                 loglik = -30.0, max_valid_loglik = -30.0,
                 centered_loglik = -25.0, max_valid_centered_loglik = -25.0,
                 centering_ve = Ve_v3, components, candidates = Any[])
            end
            result = H._arc1_raw_nuisance(ctx_v3, :residual_variance,
                Ve_v3, 1.0; method_version = :arc1_profile_v3,
                bfgs_runner = missing_original_bfgs,
                scalar_profile_runner = scalar_below_original,
                loglik_runner = raw_loglik_v3, gradient_runner = raw_gradient_v3)
            diagnostic = only(filter(d -> d.kind == :raw_nuisance_search,
                result.nuisance_statuses))
            @test result.status == :nuisance_unresolved
            @test result.max_valid_centered_loglik < 100.0
            @test any(f -> f.reason == :centered_provenance_mismatch,
                diagnostic.v3_history_provenance_failures)
        end

        @testset "nested native producers retain only valid tagged histories" begin
            nested_history_certificate(args...; kwargs...) = (
                status = :test_refusal,
                max_valid_loglik = -20.0,
                max_valid_centered_loglik = -15.0,
                original_native_max_valid_centered_loglik = -14.0,
                original_native_centering_ve = Ve_v3,
                candidates = [
                    (status = :exact_endpoint, evaluation_valid = true,
                     centered_evaluation_valid = true, loglik = -19.0,
                     centered_loglik = -10.0, centering_ve = Ve_v3),
                    (status = :unresolved, evaluation_valid = true,
                     centered_evaluation_valid = true, loglik = -18.0,
                     centered_loglik = -9.0, centering_ve = Ve_v3),
                    (status = :physical_zero_endpoint, evaluation_valid = true,
                     centered_evaluation_valid = true, loglik = -17.0,
                     centered_loglik = -8.0, centering_ve = Ve_v3)],
                physical_zero_endpoint_certificate = (
                    status = :endpoint_forward_derivative_unresolved,
                    endpoint_loglik = -16.0, endpoint_loglik_valid = true,
                    lower_loglik = -15.0, lower_loglik_valid = true,
                    forward_logliks = [-14.0, -13.0],
                    forward_logliks_valid = true),
                point_scores = Dict(:saved_intersection =>
                    (; full = -12.0, centered = 1.0,
                     centering_ve = Ve_v3, evaluation_valid = true,
                     centered_evaluation_valid = true)),
            forward_differences = [(; points = [
                    (; full = -11.0, centered = 30.0,
                     centering_ve = Ve_v3)])],
                observations = [
                    (kind = :full, value = -10.5, status = :returned,
                     evaluation_valid = true),
                    (kind = :centered, value = 99.0, status = :returned,
                     evaluation_valid = true)])
            scalar_for_nested(ctx, make_components, scale; kwargs...) = merge(
                (status = :nuisance_unresolved, value = 0.5,
                 loglik = -30.0, max_valid_loglik = -30.0,
                 centered_loglik = -25.0, max_valid_centered_loglik = -25.0,
                 centering_ve = Ve_v3, components = make_components(0.5)),
                nested_history_certificate())
            raw = H._arc1_raw_nuisance(ctx_v3, :residual_variance, Ve_v3,
                1.0; method_version = :arc1_profile_v3,
                bfgs_runner = native_bfgs_v3,
                scalar_profile_runner = scalar_for_nested,
                certificate_runner = nested_history_certificate,
                loglik_runner = raw_loglik_v3, gradient_runner = raw_gradient_v3)
            diagnostic = only(filter(d -> d.kind == :raw_nuisance_search,
                raw.nuisance_statuses))
            @test raw.max_valid_loglik == -10.5
            @test raw.max_valid_centered_loglik == 30.0
            @test raw.status == :nuisance_unresolved
            @test any(f -> f.reason == :centered_provenance_mismatch,
                diagnostic.v3_history_provenance_failures)
        end

        @testset "resolved and refused endpoint terminal scores survive raw collection" begin
            floor = 2.0^-40
            make_endpoint(value) = [0.0, Float64(value), Ve_v3]
            full_score(components) = (-10.0 - 0.01 * components[2], :ok)
            centered_score(components) = (-7.0 - 0.01 * components[2], :ok)
            good_gradient(components; free_indices) =
                (; loglik = first(full_score(components)),
                   component_gradient = [0.0,
                       0.01 / ctx_v3.residual_df, 0.0])
            bad_gradient(components; free_indices) =
                (; loglik = first(full_score(components)),
                   component_gradient = [0.0, 0.0, 0.0])
            function endpoint_certificate(gradient_at)
                lower = make_endpoint(floor)
                lower_full = first(full_score(lower))
                lower_centered = first(centered_score(lower))
                full_max = Ref(lower_full)
                centered_max = Ref(lower_centered)
                return H._arc1_physical_zero_endpoint_certificate(make_endpoint,
                    2, 3, 1, 1.0, ctx_v3.residual_df, lower, lower_full,
                    full_max, full_score, gradient_at;
                    centered_loglik_at = centered_score, centering_ve = Ve_v3,
                    lower_centered_loglik = lower_centered,
                    centered_maximum_seen = centered_max)
            end
            resolved = endpoint_certificate(good_gradient)
            refused = endpoint_certificate(bad_gradient)
            @test resolved.status == :resolved_physical_zero_endpoint
            @test refused.status == :endpoint_derivative_not_positive
            @test resolved.endpoint_loglik_valid
            @test refused.endpoint_loglik_valid
            @test resolved.endpoint_centered_loglik_valid
            @test refused.endpoint_centered_loglik_valid

            function scalar_with_endpoint(endpoint_record)
                function scalar(ctx, make_components, scale; kwargs...)
                    components = make_components(0.5)
                    return (status = :nuisance_unresolved, value = 0.5,
                        loglik = -30.0, max_valid_loglik = -30.0,
                        centered_loglik = -25.0, max_valid_centered_loglik = -25.0,
                        centering_ve = Ve_v3, components, candidates = Any[],
                        physical_zero_endpoint_certificate = endpoint_record)
                end
                scalar
            end
            function terminal_record(certificate)
                if certificate.status == :resolved_physical_zero_endpoint
                    return (status = certificate.status, loglik = certificate.loglik,
                        endpoint_loglik_valid = certificate.endpoint_loglik_valid,
                        centered_loglik = certificate.centered_loglik,
                        endpoint_centered_loglik = certificate.endpoint_centered_loglik,
                        endpoint_centered_loglik_valid =
                            certificate.endpoint_centered_loglik_valid,
                        centering_ve = Ve_v3)
                end
                return (status = certificate.status,
                    endpoint_loglik = certificate.endpoint_loglik,
                    endpoint_loglik_valid = certificate.endpoint_loglik_valid,
                    endpoint_centered_loglik = certificate.endpoint_centered_loglik,
                    endpoint_centered_loglik_valid =
                        certificate.endpoint_centered_loglik_valid,
                    centering_ve = Ve_v3)
            end
            for certificate in (resolved, refused)
                record = terminal_record(certificate)
                result = H._arc1_raw_nuisance(ctx_v3, :residual_variance,
                    Ve_v3, 1.0; method_version = :arc1_profile_v3,
                    bfgs_runner = native_bfgs_v3,
                    scalar_profile_runner = scalar_with_endpoint(record),
                    loglik_runner = raw_loglik_v3,
                    gradient_runner = raw_gradient_v3)
                @test result.max_valid_loglik >= -10.0
                @test result.max_valid_centered_loglik >= -7.0
            end
            invalid_endpoint = (status = :resolved_physical_zero_endpoint,
                loglik = 1e6, endpoint_loglik_valid = false,
                centered_loglik = 1e6, endpoint_centered_loglik = 1e6,
                endpoint_centered_loglik_valid = false, centering_ve = Ve_v3)
            invalid_result = H._arc1_raw_nuisance(ctx_v3, :residual_variance,
                Ve_v3, 1.0; method_version = :arc1_profile_v3,
                bfgs_runner = native_bfgs_v3,
                scalar_profile_runner = scalar_with_endpoint(invalid_endpoint),
                loglik_runner = raw_loglik_v3, gradient_runner = raw_gradient_v3)
            @test invalid_result.max_valid_loglik < 1e6
            @test invalid_result.max_valid_centered_loglik < 1e6
        end

        @testset "inherited routes and interruption history remain covered" begin
            ypair = [0.2 + 0.1sin(i) + 1.5 * (isodd(i) ? -1 : 1) for i in 1:16]
            na_pair = 8
            Zpair = sparse(1:16, repeat(1:na_pair, inner = 2), ones(16),
                16, na_pair)
            between = repeat([0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0], inner = 2)
            Xpair = hcat(ones(16), between)
            pair_context = H._arc1_profile_context(ypair, Xpair, Zpair,
                Matrix{Float64}(I, na_pair, na_pair))
            nonzero_context = H._arc1_profile_context(ypair,
                hcat(Xpair, repeat([1.0, -1.0], na_pair)), Zpair,
                Matrix{Float64}(I, na_pair, na_pair))
            Ve_pair = 9.814158264884749e-7
            @test H._arc1_profile_fixed_ve_centering_eligible(
                pair_context, 3, Ve_pair)
            @test !H._arc1_profile_fixed_ve_centering_eligible(
                nonzero_context, 3, Ve_pair)

            function inherited_v2_dispatch(context, target, fixed)
                target_index = findfirst(==(target),
                    (:additive_variance, :permanent_environment_variance,
                     :residual_variance))
                contact_index = first(filter(i -> i != target_index, (1, 2)))
                remaining_index = only(filter(i -> i != target_index &&
                    i != contact_index, 1:3))
                contact_value = 2.0^-40
                bfgs_calls = Ref(0)
                continuation_calls = Ref(0)
                function native_candidate(ctx, base, free, start, scale)
                    bfgs_calls[] += 1
                    values = copy(base)
                    values[contact_index] = contact_value
                    values[remaining_index] = 0.75
                    (loglik = -1.0e6, max_valid_loglik = -1.0e6,
                     components = values, converged = false, gradient_norm = 0.0,
                     hit_bound = true,
                     hit_bound_components = [(component = contact_index,
                         side = :lower, value = contact_value)],
                     optimizer_converged = true, optimizer_status = "converged",
                     termination_code = H.Optim.TerminationCode.NoObjectiveChange,
                     analytic_gradient_valid = true, line_search_failed = false,
                     iterations = 5, free_indices = copy(free),
                     finite_difference_errors = Dict(contact_index => Inf,
                         remaining_index => 0.0))
                end
                scalar(ctx, make_components, scale; kwargs...) =
                    (loglik = -1.0e6, max_valid_loglik = -1.0e6,
                     status = :ok, value = 0.75, candidates = Any[])
                initial(args...; kwargs...) =
                    (status = :face_likelihood_mismatch,
                     zero_indices = [contact_index], likelihood_spread = 1.0,
                     centered_active = false)
                function continued(ctx, base, free, start, scale, allowance)
                    continuation_calls[] += 1
                    @test allowance <= 2000
                    error("controlled continuation stop")
                end
                result = H._arc1_raw_nuisance(context, target, fixed, 1.0;
                    method_version = :arc1_profile_v3,
                    bfgs_runner = native_candidate,
                    scalar_profile_runner = scalar,
                    certificate_runner = initial,
                    refinement_runner = continued,
                    loglik_runner = (ctx, values) -> (-1.0e6, :ok),
                    gradient_runner = raw_gradient_v3)
                @test bfgs_calls[] == length(H._ARC1_START_MULTIPLIERS)^2
                @test continuation_calls[] > 0
                @test result.method_version == :arc1_profile_v3
            end
            inherited_v2_dispatch(pair_context, :additive_variance, 0.2)
            inherited_v2_dispatch(pair_context,
                :permanent_environment_variance, 0.2)
            inherited_v2_dispatch(nonzero_context, :residual_variance, Ve_pair)

            sink = Dict{Symbol,Any}()
            gradient_calls = Ref(0)
            function interrupt_intersection(ctx, components; free_indices = 1:3)
                gradient_calls[] += 1
                gradient_calls[] == 3 && throw(InterruptException())
                return (; loglik = 100.0, component_gradient = zeros(3))
            end
            scalar_for_interrupt(ctx, make_components, scale; kwargs...) = begin
                components = make_components(0.5)
                (status = :nuisance_unresolved, value = 0.5,
                 loglik = -30.0, max_valid_loglik = -30.0,
                 centered_loglik = -25.0, max_valid_centered_loglik = -25.0,
                 centering_ve = Ve_v3, components, candidates = Any[])
            end
            thrown = try
                H._arc1_raw_nuisance(ctx_v3, :residual_variance, Ve_v3, 1.0;
                    method_version = :arc1_profile_v3, v3_evidence_sink = sink,
                    bfgs_runner = native_bfgs_v3,
                    scalar_profile_runner = scalar_for_interrupt,
                    loglik_runner = (ctx, values) ->
                        (all(iszero, values[1:2]) ? 100.0 : -20.0, :ok),
                    gradient_runner = interrupt_intersection)
                nothing
            catch err
                err
            end
            @test thrown isa InterruptException
            @test gradient_calls[] == 3
            event_record = only(sink[:arc1_profile_v3_evaluations])
            @test event_record[:status] == :interrupted
            @test event_record[:max_valid_loglik] == 100.0
        end

        @testset "native zero-face certificate carries its own fixed-Ve tag" begin
            ve = 9.74052290149441e-7
            df, s0 = 1.0, 1.0
            analytic = 0.019254271008761707
            original = [9.289286519522098e-13, 0.6397602825832304, ve]
            projected = [0.0, 0.6397602825832304, ve]
            face_components = [0.0, 0.6397602721682137, ve]
            original_full = -62815142.74513186
            projected_full = -62815142.74513186
            face_full = -62815142.74513185
            original_centered = -101.97981224657958
            projected_centered = -101.97981224657403
            face_centered = -101.97981224657396
            candidate_centered_maximum = -101.97981224657954

            full_score(components) = components == original ? (original_full, :ok) :
                components == projected ? (projected_full, :ok) :
                components == face_components ? (face_full, :ok) : (face_full, :ok)
            centered_score(components) = components == original ? (original_centered, :ok) :
                components == projected ? (projected_centered, :ok) :
                components == face_components ? (face_centered, :ok) :
                (face_centered - df * analytic * components[1] / s0, :ok)
            gradient_score(components; free_indices) = begin
                component_gradient = [analytic / s0, 0.0, 0.0]
                (; loglik = first(full_score(components)), component_gradient,
                   log_gradient = component_gradient[free_indices] .* components[free_indices])
            end

            candidate = (loglik = original_full, max_valid_loglik = original_full,
                centered_loglik = original_centered,
                max_valid_centered_loglik = candidate_centered_maximum,
                centering_ve = ve, components = original, optimizer_converged = true,
                analytic_gradient_valid = true, line_search_failed = false,
                free_indices = [1, 2], finite_difference_errors = Dict(1 => Inf, 2 => 0.0),
                gradient_norm = 0.0, hit_bound_components =
                    [(component = 1, side = :lower, value = original[1])])
            face = (status = :ok, zero_index = 1, loglik = face_full,
                centered_loglik = face_centered, max_valid_centered_loglik = face_centered,
                centering_ve = ve, components = face_components)

            certificate = H._arc1_zero_bound_face_certificate(candidate, 3, s0, df,
                [face], nothing, full_score, gradient_score;
                centered_loglik_at = centered_score, centering_ve = ve,
                historical_likelihoods = [original_full],
                historical_centered_likelihoods = [candidate_centered_maximum])
            @test certificate.status == :resolved_lower_bound_by_zero_face
            @test certificate.centered_active
            @test certificate.centering_ve === ve
            @test certificate.candidate_max_valid_centered_loglik == candidate_centered_maximum
            full_history, centered_history = Ref(-Inf), Ref(-Inf)
            history = H._arc1_profile_v3_history!(full_history, centered_history,
                certificate, ve; path = "native-zero-face-certificate")
            @test isempty(history.provenance_failures)
            @test centered_history[] == face_centered

            mismatched_maximum = merge(candidate,
                (max_valid_centered_loglik = face_centered + 2e-8,))
            mismatch_certificate = H._arc1_zero_bound_face_certificate(
                mismatched_maximum, 3, s0, df, [face], nothing,
                full_score, gradient_score; centered_loglik_at = centered_score,
                centering_ve = ve)
            @test mismatch_certificate.status == :candidate_maximum_mismatch
            @test mismatch_certificate.centering_ve === ve

            unresolved_gradient(components; free_indices) = merge(
                gradient_score(components; free_indices),
                (log_gradient = fill(2e-6, length(free_indices)),))
            unresolved_certificate = H._arc1_zero_bound_face_certificate(
                candidate, 3, s0, df, [face], nothing, full_score,
                unresolved_gradient; centered_loglik_at = centered_score,
                centering_ve = ve)
            @test unresolved_certificate.status == :projected_gradient_unresolved
            @test unresolved_certificate.centering_ve === ve

            malformed_tagged = merge(candidate, (components = nothing,))
            invalid_tagged = H._arc1_zero_bound_face_certificate(malformed_tagged,
                3, s0, df, [face], nothing, full_score, gradient_score;
                centered_loglik_at = centered_score, centering_ve = ve)
            @test invalid_tagged.status == :candidate_record_invalid
            @test invalid_tagged.max_valid_loglik == original_full
            @test invalid_tagged.max_valid_centered_loglik == candidate_centered_maximum
            @test invalid_tagged.centering_ve === ve

            malformed_wrong_tag = merge(malformed_tagged, (centering_ve = 2ve,))
            invalid_wrong_tag = H._arc1_zero_bound_face_certificate(malformed_wrong_tag,
                3, s0, df, [face], nothing, full_score, gradient_score;
                centered_loglik_at = centered_score, centering_ve = ve)
            @test invalid_wrong_tag.status == :candidate_record_invalid
            @test invalid_wrong_tag.max_valid_loglik == original_full
            @test invalid_wrong_tag.max_valid_centered_loglik == -Inf
            @test invalid_wrong_tag.centering_ve === 2ve

            malformed_untagged = Base.structdiff(malformed_tagged,
                NamedTuple{(:centering_ve,)}((ve,)))
            invalid_untagged = H._arc1_zero_bound_face_certificate(malformed_untagged,
                3, s0, df, [face], nothing, full_score, gradient_score;
                centered_loglik_at = centered_score, centering_ve = ve)
            @test invalid_untagged.status == :candidate_record_invalid
            @test invalid_untagged.max_valid_loglik == original_full
            @test invalid_untagged.max_valid_centered_loglik == -Inf
            @test !hasproperty(invalid_untagged, :centering_ve)
        end
end
