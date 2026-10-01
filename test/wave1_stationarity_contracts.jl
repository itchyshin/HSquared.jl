using Test, LinearAlgebra, SparseArrays, HSquared

# Independent marginal-covariance score: no MME or selected-inverse machinery.
function _w107_dense_score(y, X, A, variances)
    a, e = variances
    Vi = inv(a .* A + e * I)
    P = Vi - Vi * X * ((X' * Vi * X) \ (X' * Vi))
    py = P * y
    return [0.5 * (dot(py, A * py) - tr(P * A)),
            0.5 * (dot(py, py) - tr(P))]
end

@testset "W1 ND successful solve and scale-relative ridge fallback" begin
    # Preserve the established Cholesky arithmetic when regularization is not
    # needed: even roundoff changes can alter an unstable boundary trajectory.
    information = reshape([2.0], 1, 1)
    score = [1.0]
    factor = cholesky(Symmetric(information); check = false)
    @test issuccess(factor)
    @test HSquared._ai_newton_step_nd(information, score) == factor \ score

    # This PSD matrix is singular, so it exercises the ridge fallback itself.
    # Scaling the response by c scales information by c^-4, score by c^-2,
    # and the variance update by c^2.
    singular_information = ones(2, 2)
    singular_score = [1.0, -1.0]
    @test !issuccess(cholesky(Symmetric(singular_information); check = false))
    step = HSquared._ai_newton_step_nd(singular_information, singular_score)
    @test all(isfinite, step)
    for c in (1e-3, 1e3)
        scaled_step = HSquared._ai_newton_step_nd(
            singular_information ./ c^4, singular_score ./ c^2)
        @test scaled_step ./ c^2 ≈ step rtol = 1e-12
    end
end

@testset "W1-07 small scores and steps do not certify stationarity" begin
    ped = normalize_pedigree(collect(1:8), [0, 0, 1, 1, 3, 3, 5, 6],
                             [0, 0, 2, 2, 4, 4, 4, 7])
    Ainv = pedigree_inverse(ped)
    A = inv(Matrix(Ainv))
    X = ones(8, 1)
    Z = sparse(1.0I, 8, 8)
    for (response_multiplier, scale) in ((1.0, 1e4), (2.0, 2e4))
        y = response_multiplier * scale .* [2.0, 4, 3, 5, 2, 6, 3, 4]
        start = scale^2
        spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
        # Previously the first case exited on the raw score, the second on a
        # ridge-suppressed step. Both starts are far from stationary.
        single = HSquared._fit_ai_reml_diagnostics(
            spec; initial = (sigma_a2 = start, sigma_e2 = start), iterations = 1)
        multi = fit_sparse_multi_effect_aireml(
            y, X, [(Z, Ainv)]; initial = [start, start], iterations = 1)
        single_vc = collect(values(single.fit.variance_components))
        multi_vc = [only(multi.variance_components.sigmas), multi.variance_components.sigma_e2]
        @test !single.fit.converged
        @test !multi.converged
        for vc in (single_vc, multi_vc)
            @test all(isfinite, vc) && all(>(0), vc)
            @test norm(vc .* _w107_dense_score(y, X, A, vc)) > 1e-3
        end
    end
end

@testset "W1-07 interior AI-REML fits are invariant to response units" begin
    ped = normalize_pedigree(collect(1:8), [0, 0, 1, 1, 2, 2, 3, 5],
                             [0, 0, 2, 2, 0, 0, 4, 6])
    Ainv = pedigree_inverse(ped)
    A = inv(Matrix(Ainv))
    X = ones(8, 1)
    Z = sparse(1.0I, 8, 8)
    y0 = [2.0, 3.0, 2.5, 3.5, 4.0, 1.5, 3.0, 4.5]
    spec0 = animal_model_spec(y0, X, Z, Ainv; ids = ped.ids, method = :REML)
    baseline = fit_ai_reml(spec0)
    baseline_vc = collect(values(baseline.variance_components))
    @test baseline.converged
    for scale in (1e-4, 1.0, 1e3, 1e4, 1e6)
        y = scale .* y0
        spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
        single = HSquared._fit_ai_reml_diagnostics(
            spec; initial = (sigma_a2 = scale^2, sigma_e2 = scale^2))
        multi = fit_sparse_multi_effect_aireml(
            y, X, [(Z, Ainv)]; initial = [scale^2, scale^2])
        @test single.fit.converged
        @test multi.converged
        single_vc = collect(values(single.fit.variance_components))
        multi_vc = [only(multi.variance_components.sigmas), multi.variance_components.sigma_e2]
        for vc in (single_vc, multi_vc)
            @test vc ./ scale^2 ≈ baseline_vc rtol = 2e-5
            # This is the gradient in log-variance coordinates per residual df.
            # Check it at the returned point, independently of the fit diagnostics.
            @test norm(vc .* _w107_dense_score(y, X, A, vc)) / 7 < 1e-8
            # Match the fitter's common-scale score stop, which remains
            # sensitive when one variance component is tiny.
            @test norm(_w107_dense_score(y, X, A, vc)) * maximum(vc) / 7 < 1e-8
        end
        # A converged fit's diagnostic score must describe its returned point.
        reported = [single.diagnostics.ai_score_a, single.diagnostics.ai_score_e]
        @test scale^2 .* reported ≈
              scale^2 .* _w107_dense_score(y, X, A, single_vc) atol = 1e-12
        # REML transforms by -(n-p)log(scale) under response-unit changes.
        @test single.fit.likelihood.loglik + 7log(scale) ≈
              baseline.likelihood.loglik atol = 1e-9
        @test multi.loglik + 7log(scale) ≈ baseline.likelihood.loglik atol = 1e-9
    end
end

@testset "W1-07 nonstationary boundary fits remain unconverged" begin
    ped = normalize_pedigree(collect(1:8), [0, 0, 1, 1, 3, 3, 5, 6],
                             [0, 0, 2, 2, 4, 4, 4, 7])
    Ainv = pedigree_inverse(ped)
    X = ones(8, 1)
    Z = sparse(1.0I, 8, 8)
    y = [2.0, 4, 3, 5, 2, 6, 3, 4]
    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
    single = fit_ai_reml(spec)
    multi = fit_sparse_multi_effect_aireml(y, X, [(Z, Ainv)])
    @test !single.converged
    @test !multi.converged
    @test all(>(0), values(single.variance_components))
    @test all(>(0), multi.variance_components.sigmas) && multi.variance_components.sigma_e2 > 0
    @test isfinite(single.likelihood.loglik) && isfinite(multi.loglik)
end

@testset "W1-07 stationarity retains frozen genomic fit precision" begin
    fixture_dir = joinpath(@__DIR__, "fixtures", "genomic_public_activation_target")
    function read_fixture(name)
        lines = readlines(joinpath(fixture_dir, name))
        header = split(first(lines), ',')
        rows = reduce(vcat, [permutedims(split(line, ',')) for line in lines[2:end]])
        return header, rows
    end
    header, marker_rows = read_fixture("markers.csv")
    ids = vec(marker_rows[:, 1])
    construction = HSquared._genomic_activation_construction(
        parse.(Float64, marker_rows[:, 2:end]), ids; marker_names = header[2:end])
    _, phenotype_rows = read_fixture("phenotypes.csv")
    id_to_row = Dict(id => i for (i, id) in enumerate(ids))
    record_rows = [id_to_row[id] for id in phenotype_rows[:, 2]]
    y = parse.(Float64, phenotype_rows[:, 4])
    X = hcat(ones(length(y)), parse.(Float64, phenotype_rows[:, 3]))
    Z = sparse(1:length(y), record_rows, 1.0, length(y), length(ids))
    _, fit_rows = read_fixture("expected_fit.csv")
    scalar = Dict(fit_rows[i, 1] => fit_rows[i, 3]
                  for i in axes(fit_rows, 1) if isempty(fit_rows[i, 2]))
    expected_vc = parse.(Float64, [scalar["sigma_g2"], scalar["sigma_e2"]])
    expected_ratio = parse(Float64, scalar["genomic_variance_ratio"])
    expected_gebv = Dict(fit_rows[i, 2] => parse(Float64, fit_rows[i, 3])
                         for i in axes(fit_rows, 1) if fit_rows[i, 1] == "gebv")
    spec = animal_model_spec(y, X, Z, construction.Q; ids = ids, method = :REML)
    single = HSquared._fit_ai_reml_diagnostics(spec)
    B = Matrix(Z * construction.K * Z')
    # The dimensionless score alone can stop before the historical relative-
    # step tolerance. Require both safeguards without loosening or regenerating
    # the existing cross-twin fixture. Its independent dense optimum differs
    # from these stored components by less than 7e-10.
    @test single.diagnostics.last_relative_change < 1e-8
    vc = collect(values(single.fit.variance_components))
    gebv = breeding_values(single.fit).values
    @test single.fit.converged
    @test maximum(abs.(vc .- expected_vc)) <= 1e-8
    @test abs(vc[1] / sum(vc) - expected_ratio) <= 1e-8
    @test maximum(abs.(gebv .- [expected_gebv[id] for id in ids])) <= 1e-8
    @test norm(vc .* _w107_dense_score(y, X, B, vc)) / (length(y) - size(X, 2)) < 1e-8
end
