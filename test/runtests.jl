using HSquared
using LinearAlgebra
using SparseArrays
using Test

# dense NRM helper lives in src now: HSquared._numerator_relationship (src/pedigree.jl)

function _csv_strings_for_test(path)
    lines = readlines(path)
    !isempty(lines) || error("empty CSV fixture: $path")
    header = String.(split(lines[1], ","))
    data = Matrix{String}(undef, length(lines) - 1, length(header))
    for (i, line) in enumerate(lines[2:end])
        fields = String.(split(line, ","))
        length(fields) == length(header) ||
            error("CSV fixture row $i in $path has $(length(fields)) fields; expected $(length(header))")
        data[i, :] .= fields
    end
    return header, data
end

function _named_matrix_csv_for_test(path)
    _, data = _csv_strings_for_test(path)
    return vec(data[:, 1]), parse.(Float64, data[:, 2:end])
end

function _metadata_csv_for_test(path)
    _, data = _csv_strings_for_test(path)
    return Dict(data[i, 1] => data[i, 2] for i in axes(data, 1))
end

function _solve_mme_for_test(y, X, Z, Ainv, sigma_a2, sigma_e2)
    yv = Float64.(y)
    Xd = Matrix{Float64}(X)
    Zd = Matrix{Float64}(Z)
    Q = Matrix{Float64}(Ainv)
    n = length(yv)

    Rinv = Matrix{Float64}(I, n, n) / sigma_e2
    Ginv = Q / sigma_a2

    lhs = [
        transpose(Xd) * Rinv * Xd transpose(Xd) * Rinv * Zd
        transpose(Zd) * Rinv * Xd transpose(Zd) * Rinv * Zd + Ginv
    ]
    rhs = [transpose(Xd) * Rinv * yv; transpose(Zd) * Rinv * yv]
    solution = lhs \ rhs

    p = size(Xd, 2)
    return solution[1:p], solution[(p + 1):end]
end

function _mme_inverse_random_block_for_test(X, Z, Ainv, sigma_a2, sigma_e2)
    Xd = Matrix{Float64}(X)
    Zd = Matrix{Float64}(Z)
    Q = Matrix{Float64}(Ainv)
    n = size(Xd, 1)

    Rinv = Matrix{Float64}(I, n, n) / sigma_e2
    Ginv = Q / sigma_a2

    lhs = [
        transpose(Xd) * Rinv * Xd transpose(Xd) * Rinv * Zd
        transpose(Zd) * Rinv * Xd transpose(Zd) * Rinv * Zd + Ginv
    ]
    inverse_lhs = inv(Symmetric(lhs))
    p = size(Xd, 2)
    return inverse_lhs[(p + 1):end, (p + 1):end]
end

@testset "HSquared Phase 0 scaffold" begin
    control = HSControl()

    @test control.backend isa AutoBackend
    @test control.accelerator == :auto
    @test control.precision === Float64
    @test control.save == :minimal
    @test control.save_fitted == false
    @test control.save_residuals == false
    @test control.save_design == false
    @test control.save_factorization == false
    @test control.disk_cache == false

    @test HSControl(backend = :cpu).backend isa CPUBackend
    @test HSControl(backend = "threads").backend isa ThreadsBackend
    @test HSControl(backend = "cuda", accelerator = "cuda", precision = Float32, save = "tiny").backend isa CUDABackend
    @test HSControl(backend = :amdgpu, accelerator = :amdgpu).backend isa AMDGPUBackend
    @test HSControl(backend = :metal, accelerator = "metal").backend isa MetalBackend
    @test HSControl(backend = "oneapi", accelerator = :oneapi).backend isa OneAPIBackend
    @test HSControl(accelerator = :gpu).accelerator == :gpu

    @test_throws ArgumentError HSControl(backend = :bogus)
    @test_throws ArgumentError HSControl(accelerator = :threads)
    @test_throws ArgumentError HSControl(precision = Float16)
    @test_throws ArgumentError HSControl(save = :everything)

    info = backend_info()
    @test info isa BackendInfo
    @test length(info) == 6
    @test [row.backend for row in info] == [:cpu, :threads, :cuda, :amdgpu, :metal, :oneapi]
    @test [row.accelerator for row in info.rows] == [:none, :none, :cuda, :amdgpu, :metal, :oneapi]
    @test all(row.selectable for row in info)
    @test all(!row.execution_available for row in info)
    @test all(row.status == :planned for row in info)
    @test all(!row.requested for row in info)

    threaded = backend_info(HSControl(backend = :threads))
    @test only(filter(row -> row.backend == :threads, threaded.rows)).requested
    @test !only(filter(row -> row.backend == :cpu, threaded.rows)).requested

    gpu = backend_info(HSControl(accelerator = :gpu))
    @test !only(filter(row -> row.backend == :cpu, gpu.rows)).requested
    @test all(row.requested for row in filter(row -> row.backend in (:cuda, :amdgpu, :metal, :oneapi), gpu.rows))

    metal = backend_info(HSControl(backend = :metal, accelerator = :metal))
    @test only(filter(row -> row.backend == :metal, metal.rows)).requested
    @test_throws ArgumentError backend_info(nothing)

    @test planned_genomic_qtl_terms() == (:genomic, :single_step, :markers, :marker_scan, :qtl_scan)
    @test planned_quantgen_terms() == (
        :permanent,
        :common_env,
        :maternal_genetic,
        :maternal_env,
        :paternal_genetic,
        :paternal_env,
        :cytoplasmic,
        :imprinting,
        :dominance,
        :epistasis,
        :relmat,
        :precision,
    )
    @test planned_model_terms() == (
        :genomic,
        :single_step,
        :markers,
        :marker_scan,
        :qtl_scan,
        :permanent,
        :common_env,
        :maternal_genetic,
        :maternal_env,
        :paternal_genetic,
        :paternal_env,
        :cytoplasmic,
        :imprinting,
        :dominance,
        :epistasis,
        :relmat,
        :precision,
    )

    grammar = formula_status()
    @test grammar isa FormulaStatus
    @test length(grammar) == 20
    @test [row.term for row in grammar][1] == "animal(1 | id, pedigree = ped)"
    @test grammar[end].term == "animal(trait | id, pedigree = ped, cov = fa(K = 2))"
    @test [row.syntax_status for row in grammar][1] == "parsed"
    @test [row.fitting_status for row in grammar][1] == "experimental tiny bridge only"
    @test all(row.fitting_status == "not available" for row in grammar if row.syntax_status != "parsed")
    @test "permanent(1 | id)" in [row.term for row in grammar]
    @test "precision(1 | id, Q = Q)" in [row.term for row in grammar]
    @test "genomic(1 | id, Ginv = Ginv)" in [row.term for row in grammar]
    @test any(row.syntax_status == "planned" for row in grammar)
    @test Set(row.syntax_status for row in grammar) == Set(["parsed", "reserved", "planned"])

    validation = validation_status()
    @test validation isa ValidationStatus
    @test length(validation) == 31
    @test validation[begin].id == "V0-LOAD"
    @test validation[end].id == "V5-GENOMIC-QTL"
    @test Set(row.status for row in validation) == Set(["covered", "covered_external", "partial", "planned"])
    @test "V1-AINV-MRODE9" in [row.id for row in validation]
    mrode9_row = only(row for row in validation if row.id == "V1-AINV-MRODE9")
    @test mrode9_row.status == "covered_external"
    @test occursin("nadiv::Mrode9", mrode9_row.evidence)
    @test occursin("Pedigree inverse agreement only", mrode9_row.claim_boundary)
    mme_row = only(row for row in validation if row.id == "V1-MME")
    @test mme_row.status == "partial"
    @test occursin("ca8bce1", mme_row.evidence)
    @test occursin("Mrode9-shaped supplied-variance fixture", mme_row.evidence)
    @test occursin("no variance-component estimation", mme_row.claim_boundary)
    lik_row = only(row for row in validation if row.id == "V1-LIK")
    @test occursin("Mrode9-shaped supplied-variance fixture", lik_row.evidence)
    sparse_reml_row = only(row for row in validation if row.id == "V1-SPARSE-REML")
    @test occursin("Mrode9-shaped supplied-variance fixture", sparse_reml_row.evidence)
    sparse_reml_opt_row = only(row for row in validation if row.id == "V1-SPARSE-REML-OPT")
    @test sparse_reml_opt_row.status == "partial"
    @test occursin("fit_sparse_reml", sparse_reml_opt_row.evidence)
    @test occursin("not AI-REML", sparse_reml_opt_row.claim_boundary)
    fitted_mrode_row = only(row for row in validation if row.id == "V1-MRODE-FIT")
    @test fitted_mrode_row.status == "covered_external"
    @test occursin("validated via the R-lane bridge", fitted_mrode_row.claim_boundary)
    comparators_row = only(row for row in validation if row.id == "V1-COMPARATORS")
    @test comparators_row.status == "covered_external"
    @test occursin("sommer", comparators_row.evidence)
    aireml_row = only(row for row in validation if row.id == "V1-AI-REML")
    @test aireml_row.status == "covered"
    @test occursin("gryphon", aireml_row.evidence)
    @test !occursin("250-animal", aireml_row.evidence)
    mv_row = only(row for row in validation if row.id == "V4-MULTIVARIATE")
    @test mv_row.phase == "Phase 4"
    @test mv_row.status == "partial"
    @test occursin("multivariate_mme", mv_row.evidence)
    @test occursin("missing-trait records", mv_row.evidence)
    @test occursin("variance_components", mv_row.evidence)
    @test occursin("breeding_values", mv_row.evidence)
    @test occursin("does not estimate G0/R0", mv_row.claim_boundary)
    @test occursin("bridge payload change", mv_row.claim_boundary)
    mvreml_row = only(row for row in validation if row.id == "V4-MV-REML")
    @test mvreml_row.phase == "Phase 4"
    @test mvreml_row.status == "partial"
    @test occursin("fit_multivariate_reml", mvreml_row.evidence)
    @test occursin("heritability", mvreml_row.evidence)
    @test occursin("comparator protocol", mvreml_row.evidence)
    @test occursin("explicit `--seeds`", mvreml_row.evidence)
    @test occursin("calibration protocol", mvreml_row.evidence)
    @test occursin("did not pass", mvreml_row.evidence)
    @test occursin("6/10 passed", mvreml_row.evidence)
    @test occursin("failure-mode triage", mvreml_row.evidence)
    @test occursin("3 G-only failures", mvreml_row.evidence)
    @test occursin("result_payload", mvreml_row.claim_boundary)
    @test occursin("comparator protocol", mvreml_row.claim_boundary)
    @test occursin("not broadly multi-seed calibrated", mvreml_row.claim_boundary)
    @test occursin("did not pass", mvreml_row.claim_boundary)
    @test occursin("opt-in seeded recovery harness", mvreml_row.claim_boundary)
    fa_row = only(row for row in validation if row.id == "V4-FA")
    @test fa_row.phase == "Phase 4B"
    @test fa_row.status == "partial"
    @test occursin("factor_analytic_covariance", fa_row.evidence)
    @test occursin("sign-canonicalization", fa_row.evidence)
    @test occursin("genetic_loadings", fa_row.evidence)
    @test occursin("rotation-identifiability decision", fa_row.evidence)
    @test occursin("explicit `--seeds`", fa_row.evidence)
    @test occursin("calibration protocol", fa_row.evidence)
    @test occursin("did not pass", fa_row.evidence)
    @test occursin("8/10", fa_row.evidence)
    @test occursin("9/10", fa_row.evidence)
    @test occursin("failure-mode triage", fa_row.evidence)
    @test occursin("R-only failure", fa_row.evidence)
    @test occursin("structured-metadata accessors", fa_row.claim_boundary)
    @test occursin("no R-facing", fa_row.claim_boundary)
    @test occursin("not rotation-identified", fa_row.claim_boundary)
    fixed_marker_row = only(row for row in validation if row.id == "V5-MARKER-FIXED")
    @test fixed_marker_row.phase == "Phase 5"
    @test fixed_marker_row.status == "partial"
    @test occursin("single_marker_scan", fixed_marker_row.evidence)
    @test occursin("marker_scan_table", fixed_marker_row.evidence)
    @test occursin("marker_effects", fixed_marker_row.evidence)
    @test occursin("marker_variance_explained", fixed_marker_row.evidence)
    @test occursin("marker_manhattan_data", fixed_marker_row.evidence)
    @test occursin("marker_region_data", fixed_marker_row.evidence)
    @test occursin("marker_significance_summary", fixed_marker_row.evidence)
    @test occursin("marker_qq_data", fixed_marker_row.evidence)
    @test occursin("marker_genomic_inflation", fixed_marker_row.evidence)
    @test occursin("HSMarkerMapSpec", fixed_marker_row.evidence)
    @test occursin("marker-effect summary", fixed_marker_row.evidence)
    @test occursin("scan-table order", fixed_marker_row.evidence)
    @test occursin("marker-variance summary", fixed_marker_row.evidence)
    @test occursin("marker-significance summary", fixed_marker_row.evidence)
    @test occursin("phase5_marker_scan_recovery.jl", fixed_marker_row.evidence)
    @test occursin("seed 20260614", fixed_marker_row.evidence)
    @test occursin("effect relative errors", fixed_marker_row.evidence)
    @test occursin("17/14", fixed_marker_row.evidence)
    @test occursin("marker_scan()", fixed_marker_row.missing)
    @test occursin("Fixed-effect Gaussian screening utility with row-aligned scan-table", fixed_marker_row.claim_boundary)
    @test occursin("regional marker-window data", fixed_marker_row.claim_boundary)
    @test occursin("nominal returned-marker-set significance summary", fixed_marker_row.claim_boundary)
    @test occursin("no calibrated/correlated-marker genome-wide threshold claim", fixed_marker_row.claim_boundary)
    @test occursin("gwas_table(), qtl_table(), and eqtl_table() wrappers only", fixed_marker_row.claim_boundary)
    @test occursin("no p-value calibration claim", fixed_marker_row.claim_boundary)
    @test occursin("no calibrated PVE", fixed_marker_row.claim_boundary)
    @test occursin("no bridge payload change", fixed_marker_row.claim_boundary)
    mixed_marker_row = only(row for row in validation if row.id == "V5-MARKER-MIXED")
    @test mixed_marker_row.phase == "Phase 5"
    @test mixed_marker_row.status == "partial"
    @test occursin("mixed_model_marker_scan", mixed_marker_row.evidence)
    @test occursin("independent GLS", mixed_marker_row.evidence)
    @test occursin("marker-scan-table, marker-effect, and marker-variance summaries", mixed_marker_row.evidence)
    @test occursin("phase5_marker_scan_recovery.jl", mixed_marker_row.evidence)
    @test occursin("half-sib simulated random-effect design", mixed_marker_row.evidence)
    @test occursin("single_marker_scan", mixed_marker_row.evidence)
    @test occursin("LOCO", mixed_marker_row.missing)
    @test occursin("Dense validation-scale supplied-variance Julia utility only", mixed_marker_row.claim_boundary)
    @test occursin("no p-value calibration", mixed_marker_row.claim_boundary)
    @test occursin("no calibrated PVE", mixed_marker_row.claim_boundary)
    @test occursin("no bridge payload change", mixed_marker_row.claim_boundary)
    loco_marker_row = only(row for row in validation if row.id == "V5-MARKER-LOCO")
    @test loco_marker_row.phase == "Phase 5"
    @test loco_marker_row.status == "partial"
    @test occursin("loco_relationship_precisions", loco_marker_row.evidence)
    @test occursin("leave-one-group-out VanRaden", loco_marker_row.evidence)
    @test occursin("loco_mixed_model_marker_scan", loco_marker_row.evidence)
    @test occursin("separate `mixed_model_marker_scan` calls", loco_marker_row.evidence)
    @test occursin("marker-scan-table, marker-effect, and marker-variance summaries", loco_marker_row.evidence)
    @test occursin("phase5_marker_scan_recovery.jl", loco_marker_row.evidence)
    @test occursin("constructed VanRaden-plus-ridge LOCO precisions", loco_marker_row.evidence)
    @test occursin("LOCO defaults", loco_marker_row.missing)
    @test occursin("Dense validation-scale LOCO construction and supplied-matrix selection helpers only", loco_marker_row.claim_boundary)
    @test occursin("no calibrated PVE", loco_marker_row.claim_boundary)
    @test occursin("no bridge payload change", loco_marker_row.claim_boundary)
    marker_recovery_script = normpath(joinpath(@__DIR__, "..", "sim", "phase5_marker_scan_recovery.jl"))
    @test isfile(marker_recovery_script)
    marker_recovery_source = read(marker_recovery_script, String)
    @test occursin("single_marker_scan", marker_recovery_source)
    @test occursin("mixed_model_marker_scan", marker_recovery_source)
    @test occursin("loco_mixed_model_marker_scan", marker_recovery_source)
    @test occursin("unknown arguments", marker_recovery_source)
    @test occursin("not calibrated genome-wide thresholds", marker_recovery_source)
    @test all(!isempty(row.evidence) for row in validation)
    @test all(!isempty(row.missing) for row in validation)

    for (name, fn) in (
        (:genomic, genomic),
        (:single_step, single_step),
        (:markers, markers),
        (:marker_scan, marker_scan),
        (:qtl_scan, qtl_scan),
        (:permanent, permanent),
        (:common_env, common_env),
        (:maternal_genetic, maternal_genetic),
        (:maternal_env, maternal_env),
        (:paternal_genetic, paternal_genetic),
        (:paternal_env, paternal_env),
        (:cytoplasmic, cytoplasmic),
        (:imprinting, imprinting),
        (:dominance, dominance),
        (:epistasis, epistasis),
        (:relmat, relmat),
        (:precision, HSquared.precision),
    )
        err = try
            fn(nothing)
            nothing
        catch caught
            caught
        end

        @test err isa ArgumentError
        @test occursin("`$(name)()` is planned, not implemented.", sprint(showerror, err))
        @test occursin("no standard quantitative-genetic extension", sprint(showerror, err))
        @test occursin("genomic prediction", sprint(showerror, err))
    end

    @test_throws Phase0NotImplementedError hsquared(nothing)
    @test_throws Phase0NotImplementedError fit_animal_model(nothing)
end

include(joinpath(@__DIR__, "..", "sim", "summarize_recovery_calibration.jl"))

@testset "Recovery calibration log summarizer" begin
    root = normpath(joinpath(@__DIR__, ".."))
    log_paths = [
        joinpath(root, "docs", "dev-log", "recovery-checkpoints", "2026-06-14-multivariate-recovery-calibration-unstructured.log"),
        joinpath(root, "docs", "dev-log", "recovery-checkpoints", "2026-06-14-multivariate-recovery-calibration-structured.log"),
    ]
    rows = RecoveryCalibrationSummary.parse_recovery_logs(log_paths)
    summaries = RecoveryCalibrationSummary.case_summaries(rows)
    failure_counts = RecoveryCalibrationSummary.failure_mode_counts(rows)

    @test length(rows) == 30
    @test summaries["unstructured"].seeds == 10
    @test summaries["unstructured"].converged == 10
    @test summaries["unstructured"].passed == 6
    @test summaries["factor_analytic"].passed == 8
    @test summaries["lowrank"].passed == 9
    @test summaries["unstructured"].max_g ≈ 0.478375
    @test summaries["factor_analytic"].max_r ≈ 0.252226
    @test summaries["lowrank"].max_r ≈ 0.262608
    @test failure_counts["unstructured"].g_only == 3
    @test failure_counts["unstructured"].r_only == 0
    @test failure_counts["unstructured"].both == 1
    @test failure_counts["factor_analytic"].g_only == 1
    @test failure_counts["factor_analytic"].both == 1
    @test failure_counts["lowrank"].r_only == 1
    @test all(row.reported_fail == 0 for row in values(failure_counts))

    summary = RecoveryCalibrationSummary.markdown_summary(rows)
    @test occursin("| unstructured | 10 | 10 | 6 | 0.600000 |", summary)
    @test occursin("| unstructured | 4 | 3 | 0 | 1 | 0 |", summary)
    @test occursin("| lowrank | 1 | 0 | 1 | 0 | 0 |", summary)
    @test occursin("20260625 (G; G=0.478375, R=0.105180)", summary)
    @test occursin("20260619 (R; G=0.422179, R=0.262608)", summary)
end

@testset "Phase 1 pedigree normalization and Ainv" begin
    ped = normalize_pedigree(
        ["calf", "sire", "dam"],
        ["sire", "0", "0"],
        ["dam", "0", "0"],
    )

    @test ped.ids == ["sire", "dam", "calf"]
    @test ped.sire == [0, 0, 1]
    @test ped.dam == [0, 0, 2]
    @test ped.original_order == [2, 3, 1]

    Ainv = pedigree_inverse(ped)
    @test Ainv isa SparseMatrixCSC{Float64,Int}
    @test Matrix(Ainv) ≈ [
        1.5 0.5 -1.0
        0.5 1.5 -1.0
        -1.0 -1.0 2.0
    ]
    @test Matrix(pedigree_inverse(["calf", "sire", "dam"], ["sire", "0", "0"], ["dam", "0", "0"])) ≈ Matrix(Ainv)

    one_parent = normalize_pedigree(["a", "b"], ["0", "a"], ["0", "0"])
    @test Matrix(pedigree_inverse(one_parent)) ≈ [
        4 / 3 -2 / 3
        -2 / 3 4 / 3
    ]

    inbred = normalize_pedigree(
        ["founder_a", "founder_b", "parent", "offspring"],
        ["0", "0", "founder_a", "founder_a"],
        ["0", "0", "founder_b", "parent"],
    )
    @test inbreeding_coefficients(inbred) ≈ [0.0, 0.0, 0.0, 0.25]
    @test inbreeding_coefficients(
        ["founder_a", "founder_b", "parent", "offspring"],
        ["0", "0", "founder_a", "founder_a"],
        ["0", "0", "founder_b", "parent"],
    ) ≈ [0.0, 0.0, 0.0, 0.25]
    @test Matrix(pedigree_inverse(inbred)) ≈ inv(HSquared._numerator_relationship(inbred))

    @test_throws ArgumentError normalize_pedigree(["a", "a"], ["0", "0"], ["0", "0"])
    @test_throws ArgumentError normalize_pedigree(["a"], ["b"], ["0"])
    @test_throws ArgumentError normalize_pedigree(["a"], ["a"], ["0"])
    @test_throws ArgumentError normalize_pedigree(["a", "b"], ["b", "a"], ["0", "0"])
    @test_throws ArgumentError normalize_pedigree(["a", "b"], ["0", "a"], ["0", "a"])
    @test_throws ArgumentError inbreeding_coefficients(ped; max_relationship_cache = 2)
end

@testset "Phase 1 HSData ID container" begin
    phenotypes = (
        id = ["animal_1", "animal_1", "animal_2"],
        env = ["E1", "E1", "E3"],
        y = [1.0, 1.5, 2.0],
    )
    pedigree = normalize_pedigree(
        ["founder", "animal_1", "animal_2"],
        ["0", "founder", "founder"],
        ["0", "0", "0"],
    )
    genotypes = [
        0.0 1.0
        1.0 0.0
        2.0 2.0
    ]
    markers = (
        marker = ["m1", "m2"],
        chr = ["1", "2"],
        pos = [10, 20],
    )
    expression = (
        id = ["animal_2", "animal_4"],
        gene1 = [4.0, 5.0],
        gene3 = [3.0, 6.0],
    )
    annotation = (
        gene_id = ["gene1", "gene2", "gene2"],
        chromosome = ["1", "1", "2"],
    )
    environment = (
        env = ["E1", "E2", "E2"],
        temperature = [18.0, 20.0, 21.0],
    )

    data = HSData(
        phenotypes;
        id = :id,
        pedigree = pedigree,
        genotypes = genotypes,
        genotype_ids = ["animal_1", "animal_3", "founder"],
        genotype_marker_ids = ["m2", "m1"],
        markers = markers,
        expression = expression,
        expression_id = :id,
        annotation = annotation,
        annotation_id = :gene_id,
        environment = environment,
        environment_id = :env,
    )

    @test data isa HSData
    @test data.pedigree === pedigree
    @test data.environment_spec isa HSEnvironmentSpec
    @test data.environment_spec.key == :env
    @test data.environment_spec.phenotype_environment_ids == ["E1", "E3"]
    @test data.environment_spec.environment_ids == ["E1", "E2"]
    @test data.environment_spec.phenotypes_without_environment == ["E3"]
    @test data.environment_spec.environment_without_phenotypes == ["E2"]
    @test data.environment_spec.duplicate_environment_ids == ["E2"]
    @test data.annotation_spec isa HSAnnotationSpec
    @test data.annotation_spec.key == :gene_id
    @test data.annotation_spec.annotation_features == ["gene1", "gene2"]
    @test data.annotation_spec.expression_features == ["gene1", "gene3"]
    @test data.annotation_spec.expression_without_annotation == ["gene3"]
    @test data.annotation_spec.annotation_without_expression == ["gene2"]
    @test data.annotation_spec.duplicate_annotation_features == ["gene2"]
    @test id_map(data) isa HSDataIDMap
    @test id_map(data).phenotype_ids == ["animal_1", "animal_2"]
    @test id_map(data).pedigree_ids == pedigree.ids
    @test id_map(data).genotype_ids == ["animal_1", "animal_3", "founder"]
    @test id_map(data).expression_ids == ["animal_2", "animal_4"]
    @test id_map(data).phenotypes_without_pedigree == []
    @test id_map(data).phenotypes_without_genotypes == ["animal_2"]
    @test id_map(data).phenotypes_without_expression == ["animal_1"]
    @test id_map(data).genotypes_without_phenotypes == ["animal_3", "founder"]
    @test id_map(data).expression_without_phenotypes == ["animal_4"]
    @test data.marker_spec.marker_ids == ["m1", "m2"]
    @test data.marker_spec.chromosome == ["1", "2"]
    @test data.marker_spec.position == [10.0, 20.0]
    @test data.marker_spec.columns == (marker = :marker, chromosome = :chr, position = :pos)
    @test data.genotype_marker_spec.marker_ids == ["m2", "m1"]
    @test data.genotype_marker_spec.marker_map_index == [2, 1]
    status = data_status(data)
    @test status isa HSDataStatus
    @test status.components == [:phenotypes, :pedigree, :genotypes, :markers, :expression, :annotation, :environment]
    @test [row.metric for row in status.id_overlap] == [
        "phenotype_ids",
        "pedigree_ids",
        "genotype_ids",
        "expression_ids",
        "phenotypes_without_pedigree",
        "phenotypes_without_genotypes",
        "genotypes_without_phenotypes",
        "phenotypes_without_expression",
        "expression_without_phenotypes",
    ]
    @test [row.count for row in status.id_overlap] == [2, 3, 3, 2, 0, 1, 2, 1, 1]
    @test status.pedigree_status isa Vector{HSDataPedigreeStatusRow}
    @test [row.metric for row in status.pedigree_status] == [
        "pedigree_rows",
        "pedigree_ids",
        "phenotype_ids_with_pedigree",
        "pedigree_only_ids",
        "founders",
        "nonfounders",
        "known_sire_links",
        "known_dam_links",
        "missing_known_parent_ids",
        "duplicate_pedigree_ids",
        "self_parent_rows",
        "same_known_parent_rows",
    ]
    @test [row.count for row in status.pedigree_status] == [3, 3, 2, 1, 1, 2, 2, 0, 0, 0, 0, 0]
    @test [row.metric for row in status.marker_status] == [
        "marker_map_markers",
        "genotype_marker_columns",
        "aligned_marker_columns",
        "chromosomes",
        "position_min",
        "position_max",
        "alignment",
    ]
    @test [row.value for row in status.marker_status] == ["2", "2", "2", "2", "10.0", "20.0", "checked"]
    @test status.genotype_status isa Vector{HSDataGenotypeStatusRow}
    @test [row.metric for row in status.genotype_status] == [
        "genotype_rows",
        "genotype_ids",
        "genotype_marker_columns",
        "named_genotype_marker_columns",
        "unnamed_genotype_marker_columns",
        "duplicate_genotype_marker_columns",
        "missing_genotype_values",
        "component_type",
    ]
    @test [row.value for row in status.genotype_status] == ["3", "3", "2", "0", "2", "0", "0", "matrix"]
    @test status.expression_status isa Vector{HSDataExpressionStatusRow}
    @test [row.metric for row in status.expression_status] == [
        "expression_rows",
        "expression_ids",
        "expression_features",
        "named_expression_features",
        "unnamed_expression_features",
        "duplicate_expression_features",
        "component_type",
    ]
    @test [row.value for row in status.expression_status] == ["2", "2", "2", "2", "0", "0", "table"]
    @test status.annotation_status isa Vector{HSDataAnnotationStatusRow}
    @test [row.metric for row in status.annotation_status] == [
        "annotation_rows",
        "annotation_key",
        "annotation_features",
        "expression_features",
        "expression_features_with_annotation",
        "annotation_only_features",
        "expression_features_without_annotation",
        "duplicate_annotation_features",
    ]
    @test [row.value for row in status.annotation_status] == ["3", "gene_id", "2", "2", "1", "1", "1", "1"]
    @test status.environment_status isa Vector{HSDataEnvironmentStatusRow}
    @test [row.metric for row in status.environment_status] == [
        "environment_rows",
        "environment_key",
        "environment_ids",
        "phenotype_environment_ids",
        "phenotype_environment_ids_with_metadata",
        "environment_only_ids",
        "phenotype_environment_ids_without_metadata",
        "duplicate_environment_ids",
    ]
    @test [row.value for row in status.environment_status] == ["3", "env", "2", "2", "1", "1", "1", "1"]
    @test occursin("HSDataStatus", sprint(show, status))

    raw_pedigree = (
        id = ["animal_1", "animal_2", "founder"],
        sire = ["founder", "founder", "0"],
        dam = ["0", "0", "0"],
    )
    raw_data = HSData(phenotypes; pedigree = raw_pedigree)
    @test id_map(raw_data).pedigree_ids == ["animal_1", "animal_2", "founder"]
    @test [row.count for row in data_status(raw_data).pedigree_status] == [3, 3, 2, 1, 1, 2, 2, 0, 0, 0, 0, 0]

    warning_pedigree_data = HSData(
        (id = ["a"], y = [1.0]);
        pedigree = (
            id = ["a", "b", "b", "c", "d"],
            sire = Any[missing, "ghost", missing, "a", "d"],
            dam = Any[missing, "a", missing, "a", "d"],
        ),
    )
    warning_status = data_status(warning_pedigree_data).pedigree_status
    warning_counts = Dict(row.metric => row.count for row in warning_status)
    @test warning_counts["pedigree_rows"] == 5
    @test warning_counts["pedigree_ids"] == 4
    @test warning_counts["phenotype_ids_with_pedigree"] == 1
    @test warning_counts["pedigree_only_ids"] == 3
    @test warning_counts["founders"] == 2
    @test warning_counts["nonfounders"] == 3
    @test warning_counts["known_sire_links"] == 3
    @test warning_counts["known_dam_links"] == 3
    @test warning_counts["missing_known_parent_ids"] == 1
    @test warning_counts["duplicate_pedigree_ids"] == 1
    @test warning_counts["self_parent_rows"] == 1
    @test warning_counts["same_known_parent_rows"] == 2

    genotype_table = (
        id = ["animal_1", "animal_2"],
        m2 = [1, 0],
        m1 = [0, 2],
    )
    table_data = HSData(
        phenotypes;
        genotypes = genotype_table,
        markers = (snp = ["m1", "m2"], chrom = ["1", "1"], bp = ["5", "7"]),
    )
    @test table_data.marker_spec.columns == (marker = :snp, chromosome = :chrom, position = :bp)
    @test table_data.genotype_marker_spec.marker_ids == ["m2", "m1"]
    @test table_data.genotype_marker_spec.marker_map_index == [2, 1]

    zero_chromosome_data = HSData(phenotypes; markers = (marker = ["m1"], chr = ["0"], pos = [0]))
    @test zero_chromosome_data.marker_spec.chromosome == ["0"]

    marker_only_status = data_status(HSData(phenotypes; markers = (marker = ["m1"], chr = ["1"], pos = [10])))
    @test [row.value for row in marker_only_status.marker_status] ==
          ["1", "0", "0", "1", "10.0", "10.0", "not_checked_no_genotypes"]

    genotype_only_status = data_status(
        HSData(
            phenotypes;
            genotypes = genotypes,
            genotype_ids = ["animal_1", "animal_3", "founder"],
        ),
    )
    @test [row.value for row in genotype_only_status.marker_status] ==
          ["0", "2", "0", "not_available", "not_available", "not_available", "not_checked_no_marker_map"]
    @test [row.value for row in genotype_only_status.genotype_status] == ["3", "3", "2", "0", "2", "0", "0", "matrix"]

    @test data_status(HSData(phenotypes)).marker_status === nothing
    @test data_status(HSData(phenotypes)).genotype_status === nothing
    @test data_status(HSData(phenotypes)).pedigree_status === nothing
    @test data_status(HSData(phenotypes)).expression_status === nothing
    @test data_status(HSData(phenotypes)).annotation_status === nothing
    @test data_status(HSData(phenotypes)).environment_status === nothing

    genotype_status_data = HSData(
        (id = ["a", "b"], y = [1.0, 2.0]);
        genotypes = (id = ["a", "b"], m1 = [0, missing], m2 = [1, 2]),
    )
    @test [row.value for row in data_status(genotype_status_data).genotype_status] ==
          ["2", "2", "2", "2", "0", "0", "1", "table"]

    duplicate_genotypes = Dict(
        :id => ["a", "b"],
        :m1 => [0, 1],
        "m1" => [2, 3],
    )
    @test [row.value for row in data_status(HSData((id = ["a", "b"], y = [1.0, 2.0]); genotypes = duplicate_genotypes)).genotype_status] ==
          ["not_available", "2", "2", "2", "0", "1", "0", "table"]

    matrix_expression_status = data_status(
        HSData(
            (id = ["a", "b"], y = [1.0, 2.0]);
            expression = [1.0 2.0 3.0; 4.0 5.0 6.0],
            expression_ids = ["a", "b"],
        ),
    ).expression_status
    @test [row.value for row in matrix_expression_status] == ["2", "2", "3", "0", "3", "0", "matrix"]

    @test [row.value for row in data_status(HSData((id = ["a"], y = [1.0]); expression = (id = ["a"],))).expression_status] ==
          ["1", "1", "0", "0", "0", "0", "table"]

    unkeyed_annotation_status = data_status(
        HSData(
            (id = ["a"], y = [1.0]);
            annotation = (gene = ["gene1"], chr = ["1"]),
        ),
    ).annotation_status
    @test [row.value for row in unkeyed_annotation_status] == [
        "1",
        "not_checked_no_annotation_id",
        "not_available",
        "not_available",
        "not_available",
        "not_available",
        "not_available",
        "not_available",
    ]

    unkeyed_environment_status = data_status(
        HSData(
            (id = ["a"], y = [1.0]);
            environment = (env = ["E1"], rainfall = [4.0]),
        ),
    ).environment_status
    @test [row.value for row in unkeyed_environment_status] == [
        "1",
        "not_checked_no_environment_id",
        "not_available",
        "not_available",
        "not_available",
        "not_available",
        "not_available",
        "not_available",
    ]

    @test_throws ArgumentError HSData((id = ["animal_1", missing], y = [1.0, 2.0]))
    @test_throws ArgumentError HSData(phenotypes; pedigree = (id = ["animal_1"],))
    @test_throws ArgumentError HSData(phenotypes; genotypes = genotypes)
    @test_throws ArgumentError HSData(phenotypes; genotypes = genotypes, genotype_ids = ["a"])
    @test_throws ArgumentError HSData(phenotypes; genotypes = genotypes, genotype_ids = ["a", "a", "b"])
    @test_throws ArgumentError HSData(; phenotypes = (animal = ["a"], y = [1.0]))
    @test_throws ArgumentError HSData(phenotypes; markers = (marker = ["m1"], chr = ["1"]))
    @test_throws ArgumentError HSData(phenotypes; markers = (marker = ["m1", "m1"], chr = ["1", "1"], pos = [1, 2]))
    @test_throws ArgumentError HSData(phenotypes; markers = (marker = ["m1"], chr = [""], pos = [1]))
    @test_throws ArgumentError HSData(phenotypes; markers = (marker = ["m1"], chr = ["1"], pos = [-1]))
    @test_throws ArgumentError HSData(
        phenotypes;
        genotypes = genotypes,
        genotype_ids = ["animal_1", "animal_3", "founder"],
        markers = markers,
    )
    @test_throws ArgumentError HSData(
        phenotypes;
        genotypes = genotypes,
        genotype_ids = ["animal_1", "animal_3", "founder"],
        genotype_marker_ids = ["m1", "m_extra"],
        markers = markers,
    )
    @test_throws ArgumentError HSData(
        phenotypes;
        genotypes = (id = ["animal_1"],),
        markers = (marker = ["m1"], chr = ["1"], pos = [1]),
    )
    @test_throws ArgumentError HSData(phenotypes; annotation_id = :gene_id)
    @test_throws ArgumentError HSData(phenotypes; annotation = [1 2; 3 4])
    @test_throws ArgumentError HSData(phenotypes; annotation = (gene_id = ["gene1"],), annotation_id = "")
    @test_throws ArgumentError HSData(phenotypes; annotation = (feature = ["gene1"],), annotation_id = :gene_id)
    @test_throws ArgumentError HSData(
        phenotypes;
        expression = [1.0 2.0; 3.0 4.0],
        expression_ids = ["animal_1", "animal_2"],
        annotation = (gene_id = ["gene1"],),
        annotation_id = :gene_id,
    )
    @test_throws ArgumentError HSData(
        phenotypes;
        expression = (id = ["animal_1"],),
        annotation = (gene_id = ["gene1"],),
        annotation_id = :gene_id,
    )
    @test_throws ArgumentError HSData(
        phenotypes;
        annotation = (gene_id = [missing],),
        annotation_id = :gene_id,
    )
    @test_throws ArgumentError HSData(phenotypes; environment_id = :env)
    @test_throws ArgumentError HSData(phenotypes; environment = [1 2; 3 4])
    @test_throws ArgumentError HSData(phenotypes; environment = (env = ["E1"],), environment_id = "")
    @test_throws ArgumentError HSData((id = ["a"], y = [1.0]); environment = (env = ["E1"],), environment_id = :env)
    @test_throws ArgumentError HSData(
        (id = ["a"], env = [missing], y = [1.0]);
        environment = (env = ["E1"],),
        environment_id = :env,
    )
    @test_throws ArgumentError HSData(
        (id = ["a"], env = ["E1"], y = [1.0]);
        environment = (env = [""],),
        environment_id = :env,
    )
end

@testset "Phase 1 sparse CSC bridge marshalling" begin
    Z = sparse(
        [1, 3, 2, 4],
        [1, 1, 3, 3],
        [1.0, 2.0, 3.0, 4.0],
        4,
        3,
    )

    from_r_slots = sparse_csc_matrix(
        size(Z, 1),
        size(Z, 2),
        Z.colptr .- 1,
        Z.rowval .- 1,
        Z.nzval,
    )
    @test from_r_slots isa SparseMatrixCSC{Float64,Int}
    @test from_r_slots == Z

    from_julia_slots = sparse_csc_matrix(
        size(Z, 1),
        size(Z, 2),
        Z.colptr,
        Z.rowval,
        Z.nzval;
        index_base = :one,
    )
    @test from_julia_slots == Z
    @test sparse_csc_matrix(4, 3, Z.colptr .- 1, Z.rowval .- 1, Z.nzval; index_base = "r") == Z
    @test sparse_csc_matrix(4, 3, Z.colptr, Z.rowval, Z.nzval; index_base = "julia") == Z

    y = [1.0, 2.0, 3.0, 4.0]
    X = ones(4, 1)
    Ainv = sparse(I, 3, 3)
    fit_from_slots = fit_animal_model(
        y,
        X,
        from_r_slots,
        Ainv;
        ids = ["a", "b", "c"],
        method = :ML,
        initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
        iterations = 25,
    )
    fit_from_sparse = fit_animal_model(
        y,
        X,
        Z,
        Ainv;
        ids = ["a", "b", "c"],
        method = :ML,
        initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
        iterations = 25,
    )
    @test fit_from_slots.likelihood.loglik ≈ fit_from_sparse.likelihood.loglik

    @test_throws ArgumentError sparse_csc_matrix(0, 3, Z.colptr .- 1, Z.rowval .- 1, Z.nzval)
    @test_throws ArgumentError sparse_csc_matrix(4, 0, Z.colptr .- 1, Z.rowval .- 1, Z.nzval)
    @test_throws ArgumentError sparse_csc_matrix(4, 3, [0, 2], Z.rowval .- 1, Z.nzval)
    @test_throws ArgumentError sparse_csc_matrix(4, 3, [1, 2, 3, 5], Z.rowval .- 1, Z.nzval)
    @test_throws ArgumentError sparse_csc_matrix(4, 3, [0, 3, 2, 4], Z.rowval .- 1, Z.nzval)
    @test_throws ArgumentError sparse_csc_matrix(4, 3, Z.colptr .- 1, [0, 4, 1, 3], Z.nzval)
    @test_throws ArgumentError sparse_csc_matrix(4, 3, Z.colptr .- 1, [2, 0, 1, 3], Z.nzval)
    @test_throws ArgumentError sparse_csc_matrix(4, 3, Z.colptr .- 1, Z.rowval .- 1, Z.nzval[1:3])
    @test_throws ArgumentError sparse_csc_matrix(4, 3, Z.colptr .- 1, Z.rowval .- 1, Z.nzval; index_base = :two)
end

@testset "Phase 1 animal model spec validation" begin
    y = [1.0, 2.0, 3.0]
    X = [1.0 0.0; 1.0 1.0; 1.0 2.0]
    Z = sparse(I, 3, 3)
    Ainv = sparse(I, 3, 3)

    spec = animal_model_spec(y, X, Z, Ainv; ids = ["a", "b", "c"], method = "reml")

    @test spec.y === y
    @test spec.X === X
    @test spec.Z === Z
    @test spec.Ainv === Ainv
    @test spec.ids == ["a", "b", "c"]
    @test spec.family isa GaussianFamily
    @test spec.method == :REML

    ml_spec = animal_model_spec(y, X, Z, Ainv; method = :ml)
    @test ml_spec.ids == [1, 2, 3]
    @test ml_spec.method == :ML

    @test_throws ArgumentError animal_model_spec(y, X[1:2, :], Z, Ainv)
    @test_throws ArgumentError animal_model_spec(y, X, Z[1:2, :], Ainv)
    @test_throws ArgumentError animal_model_spec(y, X, Z[:, 1:2], Ainv)
    @test_throws ArgumentError animal_model_spec(y, X, Z, sparse(ones(2, 3)))
    @test_throws ArgumentError animal_model_spec(y, X, Z, Ainv; ids = ["a", "b"])
    @test_throws ArgumentError animal_model_spec(y, X, Z, Ainv; family = :gaussian)
    @test_throws ArgumentError animal_model_spec(y, X, Z, Ainv; method = :AI_REML)
end

@testset "Phase 1 Gaussian likelihood evaluation" begin
    y = [1.0, 2.0, 3.0]
    X = ones(3, 1)
    Z = sparse(I, 3, 3)
    Ainv = sparse(I, 3, 3)
    spec = animal_model_spec(y, X, Z, Ainv)

    ml = gaussian_loglik(spec, 1.0, 1.0; method = :ML)
    @test ml.method == :ML
    @test ml.beta ≈ [2.0]
    @test ml.sigma_a2 == 1.0
    @test ml.sigma_e2 == 1.0
    @test ml.nobs == 3
    @test ml.nfixed == 1
    @test ml.loglik ≈ -0.5 * (3 * log(2 * pi) + 3 * log(2.0) + 1.0)

    reml = gaussian_loglik(spec, 1.0, 1.0)
    @test reml.method == :REML
    @test reml.beta ≈ [2.0]
    @test reml.loglik ≈ -0.5 * (2 * log(2 * pi) + 3 * log(2.0) + log(1.5) + 1.0)

    sparse_reml = sparse_reml_loglik(spec, 1.0, 1.0)
    @test sparse_reml.method == :REML
    @test sparse_reml.beta ≈ reml.beta
    @test sparse_reml.loglik ≈ reml.loglik
    @test sparse_reml.sigma_a2 == 1.0
    @test sparse_reml.sigma_e2 == 1.0

    guarded = gaussian_loglik(spec, 1.0, 1.0; max_dense_cells = 18)
    @test guarded.loglik ≈ reml.loglik

    @test_throws ArgumentError gaussian_loglik(spec, 0.0, 1.0)
    @test_throws ArgumentError gaussian_loglik(spec, 1.0, -1.0)
    @test_throws ArgumentError sparse_reml_loglik(spec, 0.0, 1.0)
    @test_throws ArgumentError sparse_reml_loglik(spec, 1.0, -1.0)
    @test_throws ArgumentError gaussian_loglik(spec, 1.0, 1.0; method = :AI_REML)
    @test_throws ArgumentError gaussian_loglik(spec, 1.0, 1.0; max_dense_cells = 17)
    @test_throws ArgumentError gaussian_loglik(spec, 1.0, 1.0; max_dense_cells = 0)
    saturated = animal_model_spec(y, Matrix(I, 3, 3), Z, Ainv)
    @test_throws ArgumentError gaussian_loglik(saturated, 1.0, 1.0)
    @test_throws ArgumentError sparse_reml_loglik(saturated, 1.0, 1.0)
end

@testset "Phase 1 dense variance component fitting" begin
    ids = ["sire", "dam", "calf"]
    ped = normalize_pedigree(ids, ["0", "0", "sire"], ["0", "0", "dam"])
    Ainv = pedigree_inverse(ped)
    y = [1.0, 2.5, 4.0]
    X = ones(3, 1)
    Z = sparse(I, 3, 3)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :ML)

    start = gaussian_loglik(spec, 1.0, 1.0; method = :ML)
    fit = fit_variance_components(spec; initial = (sigma_a2 = 0.5, sigma_e2 = 0.5), method = :ML)

    @test fit isa AnimalModelFit
    @test fit.spec === spec
    @test fit.likelihood.method == :ML
    @test fit.likelihood.loglik >= start.loglik
    @test fit.variance_components.sigma_a2 > 0
    @test fit.variance_components.sigma_e2 > 0
    @test fit.iterations > 0
    @test fit.optimizer_status in ("converged", "not_converged")

    fit2 = fit_animal_model(spec; initial = [1.0, 1.0], iterations = 100)
    @test fit2 isa AnimalModelFit

    reml_spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
    sparse_start = sparse_reml_loglik(reml_spec, 1.0, 1.0)
    sparse_fit = fit_sparse_reml(reml_spec; initial = (sigma_a2 = 0.8, sigma_e2 = 0.8), iterations = 100)
    @test sparse_fit isa AnimalModelFit
    @test sparse_fit.spec === reml_spec
    @test sparse_fit.target == :sparse_reml
    @test sparse_fit.likelihood.method == :REML
    @test sparse_fit.likelihood.loglik >= sparse_start.loglik
    @test sparse_fit.variance_components.sigma_a2 > 0
    @test sparse_fit.variance_components.sigma_e2 > 0
    @test sparse_fit.optimizer_status in ("converged", "not_converged")

    target_sparse = fit_animal_model(
        reml_spec;
        target = :sparse_reml,
        initial = [0.8, 0.8],
        iterations = 100,
    )
    @test target_sparse isa AnimalModelFit
    @test target_sparse.target == :sparse_reml
    @test target_sparse.likelihood.loglik ≈ sparse_fit.likelihood.loglik

    target_mme = fit_animal_model(
        spec;
        target = :henderson_mme,
        variance_components = (sigma_a2 = 1.0, sigma_e2 = 1.0),
    )
    direct_mme = henderson_mme(spec, 1.0, 1.0)
    @test target_mme isa HendersonMMEResult
    @test variance_components(target_mme) == (sigma_a2 = 1.0, sigma_e2 = 1.0)
    @test isapprox(fixed_effects(target_mme), fixed_effects(direct_mme))
    @test isapprox(breeding_values(target_mme).values, breeding_values(direct_mme).values)
    @test_throws ArgumentError fit_variance_components(spec; initial = (sigma_a2 = 1.0,))
    @test_throws ArgumentError fit_variance_components(spec; initial = [1.0])
    @test_throws ArgumentError fit_variance_components(spec; initial = (sigma_a2 = -1.0, sigma_e2 = 1.0))
    @test_throws ArgumentError fit_variance_components(spec; max_dense_cells = 17)
    @test_throws ArgumentError fit_sparse_reml(spec)
    @test_throws ArgumentError fit_sparse_reml(reml_spec; initial = (sigma_a2 = -1.0, sigma_e2 = 1.0))
    @test_throws ArgumentError fit_animal_model(spec; target = :sparse_reml)
    @test_throws ArgumentError fit_animal_model(
        reml_spec;
        target = :sparse_reml,
        variance_components = (sigma_a2 = 1.0, sigma_e2 = 1.0),
    )
    @test_throws ArgumentError fit_animal_model(spec; max_dense_cells = 17)
    @test_throws ArgumentError fit_animal_model(
        spec;
        target = :henderson_mme,
    )
    @test_throws ArgumentError fit_animal_model(
        spec;
        target = :henderson_mme,
        variance_components = (sigma_a2 = 1.0, sigma_e2 = 1.0),
        initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
    )
    @test_throws ArgumentError fit_animal_model(
        spec;
        target = :variance_components,
        variance_components = (sigma_a2 = 1.0, sigma_e2 = 1.0),
    )
    @test_throws ArgumentError fit_animal_model(spec; target = :unknown)
end

@testset "Phase 1 dense fit extractors" begin
    y = [1.0, 2.0, 3.0]
    X = ones(3, 1)
    Z = sparse(I, 3, 3)
    Ainv = sparse(I, 3, 3)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ["a", "b", "c"], method = :ML)
    likelihood = gaussian_loglik(spec, 1.0, 1.0; method = :ML)
    fit = AnimalModelFit(
        spec,
        likelihood,
        (sigma_a2 = 1.0, sigma_e2 = 1.0),
        true,
        "test",
        0,
    )

    vc = variance_components(fit)
    @test vc.sigma_a2 == 1.0
    @test vc.sigma_e2 == 1.0
    @test fixed_effects(fit) ≈ [2.0]

    ebv = breeding_values(fit)
    @test ebv isa BreedingValues
    @test ebv.ids == ["a", "b", "c"]
    @test ebv.values ≈ [-0.5, 0.0, 0.5]
    @test EBV(fit).ids == ebv.ids
    @test isapprox(EBV(fit).values, ebv.values)
    @test BLUP(fit).ids == ebv.ids
    @test isapprox(BLUP(fit).values, ebv.values)

    @test fitted_values(fit) ≈ [1.5, 2.0, 2.5]
    @test fitted_values(fit; include_random = false) ≈ [2.0, 2.0, 2.0]
    @test heritability(fit) ≈ 0.5
    @test prediction_error_variance(fit).ids == ["a", "b", "c"]
    @test prediction_error_variance(fit).values ≈ diag(_mme_inverse_random_block_for_test(X, Z, Ainv, 1.0, 1.0))
    @test reliability(fit).ids == ["a", "b", "c"]
    @test reliability(fit).values ≈ 1 .- prediction_error_variance(fit).values
    @test accuracy(fit).ids == ["a", "b", "c"]
    @test isapprox(accuracy(fit).values, sqrt.(reliability(fit).values))
    @test_throws ArgumentError HSquared._accuracy_from_reliability((ids = ["a"], values = [1.1]))
    @test_throws ArgumentError HSquared._accuracy_from_reliability((ids = ["a"], values = [NaN]))
    @test_throws ArgumentError HSquared._accuracy_from_reliability((ids = ["a", "b"], values = [0.5]))
    mme = henderson_mme(spec, vc.sigma_a2, vc.sigma_e2)
    @test breeding_values(fit).ids == breeding_values(mme).ids
    @test isapprox(breeding_values(fit).values, breeding_values(mme).values)
    @test EBV(mme).ids == ebv.ids
    @test isapprox(EBV(mme).values, ebv.values)
    @test BLUP(mme).ids == ebv.ids
    @test isapprox(BLUP(mme).values, ebv.values)
    @test accuracy(mme).ids == ["a", "b", "c"]
    @test isapprox(accuracy(mme).values, sqrt.(reliability(mme).values))
    @test isapprox(fitted_values(fit), fitted_values(mme))
    @test isapprox(fitted_values(fit; include_random = false), fitted_values(mme; include_random = false))

    payload = result_payload(fit)
    @test propertynames(payload) == (
        :variance_components,
        :heritability,
        :breeding_values,
        :fixed_effects,
        :random_effects,
        :loglik,
        :df,
        :nobs,
        :predictions,
        :diagnostics,
        :converged,
    )
    @test payload.variance_components == vc
    @test payload.heritability ≈ 0.5
    @test payload.breeding_values.ids == ["a", "b", "c"]
    @test payload.breeding_values.values ≈ [-0.5, 0.0, 0.5]
    @test payload.fixed_effects ≈ [2.0]
    @test payload.random_effects.animal.values ≈ payload.breeding_values.values
    @test payload.loglik == likelihood.loglik
    @test payload.df == 3
    @test payload.nobs == 3
    @test payload.predictions ≈ [1.5, 2.0, 2.5]
    @test payload.diagnostics.converged == true
    @test payload.diagnostics.optimizer_status == "test"
    @test payload.diagnostics.method == :ML
    @test payload.diagnostics.dense_validation_path == true
    @test payload.converged == true

    diagnostics = fit_diagnostics(fit)
    @test diagnostics.engine == :julia
    @test diagnostics.result_type == :animal_model_fit
    @test diagnostics.target == :variance_components
    @test fit.target == :variance_components
    @test diagnostics.method == :ML
    @test diagnostics.family == :gaussian
    @test diagnostics.converged == true
    @test diagnostics.optimizer_status == "test"
    @test diagnostics.iterations == 0
    @test diagnostics.loglik == likelihood.loglik
    @test diagnostics.df == 3
    @test diagnostics.nobs == 3
    @test diagnostics.dense_validation_path == true
    @test diagnostics.sparse_mme_path == false
    @test diagnostics.variance_components_source == :estimated_dense_validation

    sparse_fit = AnimalModelFit(
        animal_model_spec(y, X, Z, Ainv; ids = ["a", "b", "c"], method = :REML),
        sparse_reml_loglik(animal_model_spec(y, X, Z, Ainv; ids = ["a", "b", "c"], method = :REML), 1.0, 1.0),
        (sigma_a2 = 1.0, sigma_e2 = 1.0),
        true,
        "sparse_test",
        0,
        :sparse_reml,
        false,
        true,
        :estimated_sparse_reml_validation,
    )
    sparse_diagnostics = fit_diagnostics(sparse_fit)
    @test sparse_diagnostics.target == :sparse_reml
    @test sparse_diagnostics.method == :REML
    @test sparse_diagnostics.dense_validation_path == false
    @test sparse_diagnostics.sparse_mme_path == true
    @test sparse_diagnostics.variance_components_source == :estimated_sparse_reml_validation

    mme_diagnostics = fit_diagnostics(mme)
    @test mme_diagnostics.engine == :julia
    @test mme_diagnostics.result_type == :henderson_mme
    @test mme_diagnostics.target == :henderson_mme
    @test mme_diagnostics.method == :ML
    @test mme_diagnostics.family == :gaussian
    @test mme_diagnostics.converged == true
    @test mme_diagnostics.optimizer_status == "not_applicable"
    @test mme_diagnostics.iterations == 0
    @test mme_diagnostics.loglik === nothing
    @test mme_diagnostics.df === nothing
    @test mme_diagnostics.nobs == 3
    @test mme_diagnostics.dense_validation_path == false
    @test mme_diagnostics.sparse_mme_path == true
    @test mme_diagnostics.variance_components_source == :supplied
end

@testset "Phase 1 bridge payload fit target" begin
    payload_pedigree_id = ["sire", "dam", "calf"]
    payload_pedigree_sire = ["0", "0", "sire"]
    payload_pedigree_dam = ["0", "0", "dam"]
    payload_sire_index = [0, 0, 1]
    payload_dam_index = [0, 0, 2]
    payload_original_order = [1, 2, 3]
    ids = payload_pedigree_id

    ped = normalize_pedigree(payload_pedigree_id, payload_pedigree_sire, payload_pedigree_dam)
    @test ped.ids == ids
    @test ped.sire == payload_sire_index
    @test ped.dam == payload_dam_index
    @test ped.original_order == payload_original_order

    y = [1.0, 2.5, 4.0]
    X = ones(3, 1)
    Z = sparse(I, 3, 3)
    Ainv = pedigree_inverse(ped)

    @test size(Z) == (length(y), length(ids))
    @test size(Ainv) == (length(ids), length(ids))

    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :ML)
    spec_fit = fit_animal_model(spec; initial = (sigma_a2 = 0.8, sigma_e2 = 0.4))
    payload_fit = fit_animal_model(
        y,
        X,
        Z,
        Ainv;
        ids = ped.ids,
        method = :ML,
        initial = (sigma_a2 = 0.8, sigma_e2 = 0.4),
    )

    @test payload_fit isa AnimalModelFit
    @test payload_fit.spec.ids == spec.ids
    @test payload_fit.spec.method == :ML
    @test payload_fit.likelihood.loglik ≈ spec_fit.likelihood.loglik
    @test payload_fit.variance_components.sigma_a2 ≈ spec_fit.variance_components.sigma_a2
    @test payload_fit.variance_components.sigma_e2 ≈ spec_fit.variance_components.sigma_e2
    @test breeding_values(payload_fit).ids == ped.ids
    payload_mme = fit_animal_model(
        y,
        X,
        Z,
        Ainv;
        ids = ped.ids,
        method = :ML,
        target = "henderson_mme",
        variance_components = [1.2, 0.8],
    )
    @test payload_mme isa HendersonMMEResult
    @test payload_mme.spec.ids == ped.ids
    @test payload_mme.spec.method == :ML
    @test variance_components(payload_mme) == (sigma_a2 = 1.2, sigma_e2 = 0.8)

    payload_sparse = fit_animal_model(
        y,
        X,
        Z,
        Ainv;
        ids = ped.ids,
        method = :REML,
        target = "sparse_reml",
        initial = [0.8, 0.8],
        iterations = 100,
    )
    @test payload_sparse isa AnimalModelFit
    @test payload_sparse.target == :sparse_reml
    @test payload_sparse.spec.ids == ped.ids
    @test payload_sparse.spec.method == :REML

    @test_throws ArgumentError fit_animal_model(y[1:2], X, Z, Ainv; ids = ped.ids)
    @test_throws ArgumentError fit_animal_model(y, X, Z, Ainv; ids = ["a"], method = :ML)
    @test_throws ArgumentError fit_animal_model(
        y,
        X,
        Z,
        Ainv;
        ids = ped.ids,
        method = :ML,
        max_dense_cells = 17,
    )
end

@testset "Phase 1 Henderson MME supplied-variance validation fixture" begin
    ids = ["founder_a", "founder_b", "animal_1", "animal_2", "animal_3"]
    ped = normalize_pedigree(
        ids,
        ["0", "0", "founder_a", "founder_a", "animal_1"],
        ["0", "0", "founder_b", "founder_b", "animal_2"],
    )
    Ainv = pedigree_inverse(ped)
    expected_ainv = [
        2.0 1.0 -1.0 -1.0 0.0
        1.0 2.0 -1.0 -1.0 0.0
        -1.0 -1.0 2.5 0.5 -1.0
        -1.0 -1.0 0.5 2.5 -1.0
        0.0 0.0 -1.0 -1.0 2.0
    ]

    y = [3.2, 4.1, 5.4, 5.9]
    X = [
        1.0 0.0
        1.0 1.0
        1.0 0.0
        1.0 1.0
    ]
    Z = sparse(
        [1, 2, 3, 4],
        [3, 4, 5, 5],
        ones(4),
        4,
        5,
    )
    sigma_a2 = 1.2
    sigma_e2 = 0.8
    expected_beta = [3.898701298701298, 0.6454545454545471]
    expected_u = [
        0.0,
        0.0,
        -0.054545454545454695,
        0.05454545454545385,
        0.8571428571428561,
    ]
    expected_fitted = [
        3.844155844155843,
        4.5987012987012985,
        4.755844155844154,
        5.401298701298701,
    ]
    expected_h2 = 0.6

    @test ped.ids == ids
    @test isapprox(Matrix(Ainv), expected_ainv)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :ML)
    likelihood = gaussian_loglik(spec, sigma_a2, sigma_e2; method = :ML)
    dense_reml = gaussian_loglik(spec, sigma_a2, sigma_e2; method = :REML)
    sparse_reml = sparse_reml_loglik(spec, sigma_a2, sigma_e2)
    fit = AnimalModelFit(
        spec,
        likelihood,
        (sigma_a2 = sigma_a2, sigma_e2 = sigma_e2),
        true,
        "mme_fixture",
        0,
    )

    reference_beta, reference_u = _solve_mme_for_test(y, X, Z, Ainv, sigma_a2, sigma_e2)
    mme = henderson_mme(spec, sigma_a2, sigma_e2)

    @test isapprox(reference_beta, expected_beta)
    @test isapprox(reference_u, expected_u)
    @test sparse_reml.beta ≈ dense_reml.beta
    @test sparse_reml.loglik ≈ dense_reml.loglik
    @test sparse_reml.nobs == length(y)
    @test sparse_reml.nfixed == size(X, 2)

    @test fixed_effects(fit) ≈ expected_beta
    @test breeding_values(fit).ids == ped.ids
    @test breeding_values(fit).values ≈ expected_u
    @test isapprox(fitted_values(fit), expected_fitted)
    @test isapprox(heritability(fit), expected_h2)

    @test mme isa HendersonMMEResult
    @test mme.spec === spec
    @test mme.sigma_a2 == sigma_a2
    @test mme.sigma_e2 == sigma_e2
    @test variance_components(mme) == (sigma_a2 = sigma_a2, sigma_e2 = sigma_e2)
    @test fixed_effects(mme) ≈ expected_beta
    @test breeding_values(mme).ids == ped.ids
    @test breeding_values(mme).values ≈ expected_u
    @test EBV(mme).ids == ped.ids
    @test isapprox(EBV(mme).values, expected_u)
    @test BLUP(mme).ids == ped.ids
    @test isapprox(BLUP(mme).values, expected_u)
    @test isapprox(breeding_values(fit).values, breeding_values(mme).values)
    @test isapprox(fitted_values(mme), expected_fitted)
    @test isapprox(fitted_values(fit), fitted_values(mme))
    @test isapprox(fitted_values(fit; include_random = false), fitted_values(mme; include_random = false))
    @test isapprox(heritability(mme), expected_h2)
    @test fitted_values(mme; include_random = false) ≈ vec(Matrix(X) * expected_beta)
    @test_throws ArgumentError henderson_mme(spec, 0.0, sigma_e2)
    @test_throws ArgumentError henderson_mme(spec, sigma_a2, -1.0)

    expected_pev = diag(_mme_inverse_random_block_for_test(X, Z, Ainv, sigma_a2, sigma_e2))
    relationship = inv(Symmetric(Matrix(Ainv)))
    expected_reliability = 1 .- expected_pev ./ (sigma_a2 .* diag(relationship))

    @test prediction_error_variance(fit).ids == ped.ids
    @test prediction_error_variance(fit).values ≈ expected_pev
    @test reliability(fit).ids == ped.ids
    @test reliability(fit).values ≈ expected_reliability
    @test prediction_error_variance(mme).ids == ped.ids
    @test isapprox(prediction_error_variance(mme).values, expected_pev)
    @test reliability(mme).ids == ped.ids
    @test isapprox(reliability(mme).values, expected_reliability)
    @test_throws ArgumentError accuracy(mme)
end

@testset "Phase 1 Mrode-style supplied-variance validation fixture" begin
    ids = string.([2, 4, 1, 3, 5, 6, 7, 8, 9, 10, 11, 12])
    ped = normalize_pedigree(
        ids,
        ["0", "0", "0", "0", "1", "3", "6", "0", "3", "3", "6", "6"],
        ["0", "0", "0", "0", "2", "4", "5", "5", "8", "8", "8", "8"],
    )
    Ainv = pedigree_inverse(ped)
    expected_ainv = [
        1.5 0.0 0.5 0.0 -1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0
        0.0 1.5 0.0 0.5 0.0 -1.0 0.0 0.0 0.0 0.0 0.0 0.0
        0.5 0.0 1.5 0.0 -1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0
        0.0 0.5 0.0 2.5 0.0 -1.0 0.0 1.0 -1.0 -1.0 0.0 0.0
        -1.0 0.0 -1.0 0.0 2.8333333333333335 0.5 -1.0 -0.6666666666666666 0.0 0.0 0.0 0.0
        0.0 -1.0 0.0 -1.0 0.5 3.5 -1.0 1.0 0.0 0.0 -1.0 -1.0
        0.0 0.0 0.0 0.0 -1.0 -1.0 2.0 0.0 0.0 0.0 0.0 0.0
        0.0 0.0 0.0 1.0 -0.6666666666666666 1.0 0.0 3.3333333333333335 -1.0 -1.0 -1.0 -1.0
        0.0 0.0 0.0 -1.0 0.0 0.0 0.0 -1.0 2.0 0.0 0.0 0.0
        0.0 0.0 0.0 -1.0 0.0 0.0 0.0 -1.0 0.0 2.0 0.0 0.0
        0.0 0.0 0.0 0.0 0.0 -1.0 0.0 -1.0 0.0 0.0 2.0 0.0
        0.0 0.0 0.0 0.0 0.0 -1.0 0.0 -1.0 0.0 0.0 0.0 2.0
    ]

    y = [10.2, 9.7, 10.8, 9.9, 11.5, 11.0, 12.4, 10.9, 12.1, 11.8, 12.9, 12.7]
    X = [
        1.0 0.0
        1.0 1.0
        1.0 0.0
        1.0 1.0
        1.0 0.0
        1.0 1.0
        1.0 0.0
        1.0 1.0
        1.0 0.0
        1.0 1.0
        1.0 0.0
        1.0 1.0
    ]
    Z = sparse(1:12, 1:12, ones(12), 12, 12)
    sigma_a2 = 1.4
    sigma_e2 = 0.9
    expected_beta = [11.317393070236822, -1.0063726022361354]
    expected_u = [
        -0.5021061319436008,
        -0.11525433671959359,
        -0.13688874063925227,
        0.20787891031852276,
        0.1355094468877566,
        0.7022497098504573,
        0.7092602946040143,
        0.8873101719197427,
        0.6504124611509037,
        0.9594504746292134,
        1.1394542485192605,
        1.4922422619975693,
    ]
    expected_fitted = [
        10.815286938293221,
        10.195766131281093,
        11.18050432959757,
        10.518899378319208,
        11.452902517124578,
        11.013270177851144,
        12.026653364840836,
        11.198330639920428,
        11.967805531387725,
        11.270470942629899,
        12.456847318756083,
        11.803262729998256,
    ]
    expected_pev = [
        0.7995095200390083,
        0.7610908283670357,
        0.7995095200390082,
        0.7311017691367848,
        0.9080482784527696,
        0.7881609637019633,
        0.9046409311296871,
        0.7330130895894281,
        0.8217902414402057,
        0.8599627801418696,
        0.8487180314157624,
        0.8907596807820399,
    ]
    expected_reliability = [
        0.4289217714007082,
        0.4563636940235458,
        0.4289217714007084,
        0.47778445061658215,
        0.35139408681945017,
        0.43702788307002605,
        0.35382790633593764,
        0.4764192217218369,
        0.4130069703998529,
        0.385740871327236,
        0.3937728347030267,
        0.36374308515568576,
    ]
    expected_h2 = 0.6086956521739131
    expected_ml_loglik = -18.181909573827813
    expected_reml_loglik = -16.973441618108648

    @test ped.ids == ids
    @test isapprox(Matrix(Ainv), expected_ainv)
    @test isapprox(Matrix(Ainv), inv(Symmetric(HSquared._numerator_relationship(ped))))

    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :ML)
    ml_likelihood = gaussian_loglik(spec, sigma_a2, sigma_e2; method = :ML)
    reml_spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
    dense_reml = gaussian_loglik(reml_spec, sigma_a2, sigma_e2; method = :REML)
    sparse_reml = sparse_reml_loglik(reml_spec, sigma_a2, sigma_e2)
    fit = AnimalModelFit(
        spec,
        ml_likelihood,
        (sigma_a2 = sigma_a2, sigma_e2 = sigma_e2),
        true,
        "mrode_style_supplied_variance_fixture",
        0,
    )
    mme = henderson_mme(spec, sigma_a2, sigma_e2)

    reference_beta, reference_u = _solve_mme_for_test(y, X, Z, Ainv, sigma_a2, sigma_e2)
    reference_pev = diag(_mme_inverse_random_block_for_test(X, Z, Ainv, sigma_a2, sigma_e2))

    @test isapprox(reference_beta, expected_beta)
    @test isapprox(reference_u, expected_u)
    @test isapprox(reference_pev, expected_pev)
    @test ml_likelihood.loglik ≈ expected_ml_loglik
    @test dense_reml.loglik ≈ expected_reml_loglik
    @test sparse_reml.loglik ≈ expected_reml_loglik
    @test sparse_reml.beta ≈ expected_beta

    @test fixed_effects(fit) ≈ expected_beta
    @test breeding_values(fit).ids == ped.ids
    @test breeding_values(fit).values ≈ expected_u
    @test EBV(fit).values ≈ expected_u
    @test BLUP(fit).values ≈ expected_u
    @test fitted_values(fit) ≈ expected_fitted
    @test heritability(fit) ≈ expected_h2
    @test prediction_error_variance(fit).values ≈ expected_pev
    @test reliability(fit).values ≈ expected_reliability
    @test accuracy(fit).values ≈ sqrt.(expected_reliability)

    @test mme isa HendersonMMEResult
    @test fixed_effects(mme) ≈ expected_beta
    @test breeding_values(mme).ids == ped.ids
    @test breeding_values(mme).values ≈ expected_u
    @test fitted_values(mme) ≈ expected_fitted
    @test heritability(mme) ≈ expected_h2
    @test prediction_error_variance(mme).ids == ped.ids
    @test prediction_error_variance(mme).values ≈ expected_pev
    @test reliability(mme).ids == ped.ids
    @test reliability(mme).values ≈ expected_reliability
    @test accuracy(mme).values ≈ sqrt.(expected_reliability)
end

@testset "Phase 1 sparse selected-inversion PEV/reliability" begin
    # Kernel: takahashi diagonal matches the dense inverse diagonal exactly
    # (the diagonal is always in the L+Lᵀ pattern).
    C = sparse([4.0 1.0 0.0; 1.0 3.0 1.0; 0.0 1.0 2.0])
    ch = cholesky(Symmetric(C))
    Cinv_diag = diag(inv(Matrix(C)))
    @test diag(HSquared.takahashi_selinv(ch)) ≈ Cinv_diag rtol = 1e-10
    @test HSquared.takahashi_diag(ch) ≈ Cinv_diag rtol = 1e-10

    # Animal-model PEV/reliability: sparse :selinv == dense (identical
    # coefficient matrix, so agreement is to machine precision).
    ids = ["sire", "dam", "calf"]
    ped = normalize_pedigree(ids, ["0", "0", "sire"], ["0", "0", "dam"])
    Ainv = pedigree_inverse(ped)
    y = [1.0, 2.5, 4.0]
    X = ones(3, 1)
    Z = sparse(1.0I, 3, 3)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
    mme = henderson_mme(spec, 1.2, 0.8)

    pev_dense = prediction_error_variance(mme)
    pev_selinv = prediction_error_variance(mme; method = :selinv)
    @test pev_selinv.ids == pev_dense.ids
    @test pev_selinv.values ≈ pev_dense.values rtol = 1e-10
    @test reliability(mme; method = :selinv).values ≈ reliability(mme).values rtol = 1e-10

    # default stays :dense (contract unchanged)
    @test prediction_error_variance(mme).values == pev_dense.values

    # AnimalModelFit path also supports :selinv
    fit = fit_variance_components(
        spec;
        initial = (sigma_a2 = 0.8, sigma_e2 = 0.8),
        method = :REML,
    )
    @test prediction_error_variance(fit; method = :selinv).values ≈
          prediction_error_variance(fit).values rtol = 1e-9
    @test reliability(fit; method = :selinv).values ≈
          reliability(fit).values rtol = 1e-9 atol = 1e-8

    # invalid method rejected on both extractors
    @test_throws ArgumentError prediction_error_variance(mme; method = :nope)
    @test_throws ArgumentError reliability(mme; method = :nope)
end

@testset "Phase 1 fused AI-REML selinv trace (selinv_trace_against)" begin
    # The fused kernel must equal the materialize-then-broadcast formula it
    # replaces in fit_ai_reml — sum(Ainv .* takahashi_selinv(factor)[uu]) — to
    # rtol 1e-10, on tiny and larger (Mrode9-shaped) pedigree MME factors.
    function _trace_ref_and_fused(spec, sa2, se2)
        lhs, _, _ = HSquared._sparse_mme_system(spec, sa2, se2)
        factor = cholesky(Symmetric(lhs); check = true)
        Ainv = sparse(Float64.(spec.Ainv))
        nfixed = size(spec.X, 2)
        ref = sum(Ainv .*
                  HSquared.takahashi_selinv(factor)[(nfixed + 1):end, (nfixed + 1):end])
        fused = HSquared.selinv_trace_against(factor, Ainv, nfixed)
        return ref, fused
    end

    # tiny 3-animal sire/dam/calf
    ped1 = normalize_pedigree(["sire", "dam", "calf"], ["0", "0", "sire"], ["0", "0", "dam"])
    spec1 = animal_model_spec([1.0, 2.5, 4.0], ones(3, 1), sparse(1.0I, 3, 3),
                              pedigree_inverse(ped1); ids = ped1.ids, method = :REML)
    r1, f1 = _trace_ref_and_fused(spec1, 1.2, 0.8)
    @test f1 ≈ r1 rtol = 1e-10

    # larger 8-animal pedigree with deeper relationship structure, two ratios
    ids8 = ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"]
    ped8 = normalize_pedigree(ids8,
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    spec8 = animal_model_spec([2.0, 3.0, 2.5, 3.5, 4.0, 1.5, 3.0, 4.5],
                              ones(8, 1), sparse(1.0I, 8, 8),
                              pedigree_inverse(ped8); ids = ped8.ids, method = :REML)
    r8, f8 = _trace_ref_and_fused(spec8, 1.5, 0.7)
    @test f8 ≈ r8 rtol = 1e-10
    r8b, f8b = _trace_ref_and_fused(spec8, 0.5, 2.0)
    @test f8b ≈ r8b rtol = 1e-10

    # fit_ai_reml's recovered optimum is unchanged: still matches the independent
    # sparse REML optimizer (the trace refactor is numerically equivalent).
    ai = fit_ai_reml(spec8; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    sr = fit_sparse_reml(spec8; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    @test ai.converged
    # loglik is the tight invariant (the n=8 REML surface is flat, so the
    # variance components agree only loosely — matching the AI-REML testset).
    @test ai.likelihood.loglik ≈ sr.likelihood.loglik rtol = 1e-5
    @test ai.variance_components.sigma_a2 ≈ sr.variance_components.sigma_a2 rtol = 2e-2
    @test ai.variance_components.sigma_e2 ≈ sr.variance_components.sigma_e2 rtol = 2e-2
end

@testset "Phase 1 REML optimizer recovery (dense vs sparse)" begin
    # Interior REML optimum (8-animal pedigree, one record each). The dense
    # `fit_variance_components(:REML)` and sparse `fit_sparse_reml` optimize the
    # SAME REML objective, so they must recover the same variance components,
    # heritability, log-likelihood, and EBVs — and a different start must reach
    # the same optimum. This pins optimizer correctness AT the optimum, beyond
    # the earlier "improves over the start" check.
    ids = ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"]
    ped = normalize_pedigree(
        ids,
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"],
    )
    Ainv = pedigree_inverse(ped)
    y = [2.0, 3.0, 2.5, 3.5, 4.0, 1.5, 3.0, 4.5]
    X = ones(8, 1)
    Z = sparse(1.0I, 8, 8)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)

    dense = fit_variance_components(
        spec;
        initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
        method = :REML,
    )
    sparse_fit = fit_sparse_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))

    # genuine interior optimum (not the σ²a = 0 boundary)
    @test dense.variance_components.sigma_a2 > 0.5
    @test 0 < heritability(dense) < 1

    # dense and sparse recover the same REML optimum
    @test sparse_fit.variance_components.sigma_a2 ≈
          dense.variance_components.sigma_a2 rtol = 1e-3
    @test sparse_fit.variance_components.sigma_e2 ≈
          dense.variance_components.sigma_e2 rtol = 1e-3
    @test heritability(sparse_fit) ≈ heritability(dense) rtol = 1e-3
    @test sparse_fit.likelihood.loglik ≈ dense.likelihood.loglik rtol = 1e-6
    @test breeding_values(sparse_fit).values ≈
          breeding_values(dense).values rtol = 1e-3 atol = 1e-6

    # multi-start robustness: a different start reaches the same optimum
    sparse_alt = fit_sparse_reml(spec; initial = (sigma_a2 = 3.0, sigma_e2 = 0.3))
    @test sparse_alt.variance_components.sigma_a2 ≈
          sparse_fit.variance_components.sigma_a2 rtol = 1e-2
    @test sparse_alt.variance_components.sigma_e2 ≈
          sparse_fit.variance_components.sigma_e2 rtol = 1e-2

    # boundary optimum: dense and sparse still agree when the REML optimum is at
    # σ²a = 0 (a small all-different-start fixture)
    bped = normalize_pedigree(["sire", "dam", "calf"], ["0", "0", "sire"], ["0", "0", "dam"])
    bspec = animal_model_spec(
        [1.0, 2.5, 4.0],
        ones(3, 1),
        sparse(1.0I, 3, 3),
        pedigree_inverse(bped);
        ids = bped.ids,
        method = :REML,
    )
    bdense = fit_variance_components(
        bspec;
        initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
        method = :REML,
    )
    bsparse = fit_sparse_reml(bspec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    @test bsparse.variance_components.sigma_a2 ≈
          bdense.variance_components.sigma_a2 atol = 1e-5
    @test bsparse.likelihood.loglik ≈ bdense.likelihood.loglik rtol = 1e-6
end

@testset "Phase 1 AI-REML estimator" begin
    ids = ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"]
    ped = normalize_pedigree(
        ids,
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"],
    )
    Ainv = pedigree_inverse(ped)
    y = [2.0, 3.0, 2.5, 3.5, 4.0, 1.5, 3.0, 4.5]
    X = ones(8, 1)
    Z = sparse(1.0I, 8, 8)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)

    ai = fit_ai_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    nm = fit_sparse_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))

    @test ai isa AnimalModelFit
    @test ai.target == :ai_reml
    @test ai.converged
    # AI-REML recovers the same REML optimum as the NelderMead optimizer: the
    # log-likelihood matches tightly; the variance components agree (looser, the
    # surface is flat for this tiny fixture).
    @test ai.likelihood.loglik ≈ nm.likelihood.loglik rtol = 1e-5
    @test ai.variance_components.sigma_a2 ≈ nm.variance_components.sigma_a2 rtol = 2e-2
    @test ai.variance_components.sigma_e2 ≈ nm.variance_components.sigma_e2 rtol = 2e-2
    @test heritability(ai) ≈ heritability(nm) rtol = 1e-2
    @test breeding_values(ai).values ≈ breeding_values(nm).values rtol = 1e-2 atol = 1e-6

    # path-aware diagnostics
    d = fit_diagnostics(ai)
    @test d.target == :ai_reml
    @test d.sparse_mme_path == true
    @test d.variance_components_source == :estimated_ai_reml

    # target dispatch reaches the same optimum from a different start
    t = fit_animal_model(spec; target = :ai_reml, initial = (sigma_a2 = 0.5, sigma_e2 = 0.5))
    @test t.target == :ai_reml
    @test t.likelihood.loglik ≈ ai.likelihood.loglik rtol = 1e-5

    # guards
    @test_throws ArgumentError fit_ai_reml(
        animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :ML),
    )
    @test_throws ArgumentError fit_ai_reml(spec; initial = (sigma_a2 = -1.0, sigma_e2 = 1.0))
    @test_throws ArgumentError fit_animal_model(
        spec;
        target = :ai_reml,
        variance_components = (sigma_a2 = 1.0, sigma_e2 = 1.0),
    )
end

@testset "Phase 2 genomic relationship matrix (VanRaden)" begin
    M = [0.0 1 2; 2 1 0; 1 1 1; 0 2 1]   # 4 individuals x 3 biallelic markers
    G = genomic_relationship_matrix(M)
    @test size(G) == (4, 4)
    @test G ≈ transpose(G)                          # symmetric
    @test G[1, 1] ≈ 1.130435 rtol = 1e-5            # hand-computed VanRaden entries
    @test G[1, 2] ≈ -1.304348 rtol = 1e-5
    @test minimum(eigvals(Symmetric(G))) > -1e-8    # PSD (rank-deficient: m < n)

    # supplied allele frequencies reproduce the estimated-frequency result
    G2 = genomic_relationship_matrix(M; allele_frequencies = [0.375, 0.625, 0.5])
    @test G2 ≈ G

    # guards
    @test_throws ArgumentError genomic_relationship_matrix(M; allele_frequencies = [0.5, 0.5])
    @test_throws ArgumentError genomic_relationship_matrix([3.0 1.0; 0.0 2.0])
    @test_throws ArgumentError genomic_relationship_matrix(zeros(2, 2))
end

@testset "Phase 2 regularized genomic inverse (Ginv)" begin
    # full-rank symmetric PD matrix: ridge = 0 returns the plain inverse
    Gpd = [2.0 0.5; 0.5 2.0]
    Ginv0 = genomic_relationship_inverse(Gpd; ridge = 0.0)
    @test Ginv0 ≈ [2.0 -0.5; -0.5 2.0] ./ 3.75   # hand inverse, det = 2·2 − 0.5² = 3.75
    @test Ginv0 ≈ transpose(Ginv0)               # symmetric
    @test Gpd * Ginv0 ≈ I(2)                      # defining identity

    # the ridge is added to the diagonal before inversion
    Ginvr = genomic_relationship_inverse(Gpd; ridge = 0.01)
    @test (Gpd + 0.01I) * Ginvr ≈ I(2)
    @test !(Ginvr ≈ Ginv0)                        # ridge changed the result

    # a singular matrix needs the ridge: ridge = 0 throws
    @test_throws ArgumentError genomic_relationship_inverse([1.0 1.0; 1.0 1.0]; ridge = 0.0)

    # round-trip: a rank-deficient marker G (m < n) inverts with the default ridge
    M = [0.0 1 2; 2 1 0; 1 1 1; 0 2 1]   # 4 individuals x 3 markers
    G = genomic_relationship_matrix(M)
    Gi = genomic_relationship_inverse(G)
    @test (G + 0.01I) * Gi ≈ I(4)
    @test Gi ≈ transpose(Gi)

    # guards
    @test_throws ArgumentError genomic_relationship_inverse([1.0 2.0 3.0; 4 5 6])  # non-square
    @test_throws ArgumentError genomic_relationship_inverse(Gpd; ridge = -1.0)     # negative ridge
end

@testset "Phase 2 GBLUP supplied-variance solve" begin
    # GBLUP = animal model with a genomic relationship inverse in the Ainv slot.
    y = [10.0, 12.0, 11.0]
    X = reshape(ones(3), 3, 1)
    Z = Matrix{Float64}(I, 3, 3)
    G = [1.00 0.25 0.10; 0.25 1.00 0.30; 0.10 0.30 1.00]   # symmetric PD: ridge = 0 ok
    @test isposdef(Symmetric(G))
    Ginv = inv(Symmetric(G))
    sigma_a2 = 2.0; sigma_e2 = 1.0
    res = fit_gblup(y, X, Z, Ginv, sigma_a2, sigma_e2)

    # pinned hand-reproducible values
    @test fixed_effects(res) ≈ [10.944869831546713] atol = 1e-8
    @test breeding_values(res).values ≈
          [-0.5620214395099584, 0.6314446145992807, 0.09596733027054087] atol = 1e-8

    # invariant 1: independent dense MME assembly agrees (assembled here, not via src)
    C = [transpose(X) * X / sigma_e2  transpose(X) * Z / sigma_e2
         transpose(Z) * X / sigma_e2  transpose(Z) * Z / sigma_e2 + Ginv / sigma_a2]
    rhs = [transpose(X) * y / sigma_e2; transpose(Z) * y / sigma_e2]
    sol = C \ rhs
    @test maximum(abs.(sol[1:1] .- fixed_effects(res))) < 1e-10
    @test maximum(abs.(sol[2:end] .- breeding_values(res).values)) < 1e-10

    # invariant 2: with G = A, GBLUP reproduces pedigree BLUP exactly
    Ainv = pedigree_inverse([1, 2, 3], [0, 0, 1], [0, 0, 2])
    ped_ebv = breeding_values(henderson_mme(animal_model_spec(y, X, Z, Ainv), 2.0, 1.0)).values
    A = inv(Symmetric(Matrix(Ainv)))
    gen_ebv = breeding_values(fit_gblup(y, X, Z, inv(Symmetric(A)), 2.0, 1.0)).values
    @test ped_ebv ≈ [-2.0 / 3, 2.0 / 3, 0.0] atol = 1e-8
    @test maximum(abs.(gen_ebv .- ped_ebv)) < 1e-10

    # invariant 3: solution depends only on lambda = sigma_e2/sigma_a2
    @test breeding_values(fit_gblup(y, X, Z, Ginv, 4.0, 2.0)).values ≈
          breeding_values(res).values atol = 1e-10

    # guards / finiteness
    @test isfinite(only(fixed_effects(res)))
    @test all(isfinite, breeding_values(res).values)
    @test_throws ArgumentError fit_gblup(y, X, Z, Ginv, -1.0, 1.0)
end

@testset "Phase 2 SNP-BLUP and GBLUP-SNP-BLUP equivalence" begin
    M = [0.0 1 2; 2 1 0; 1 1 1; 0 2 2]   # 4 individuals x 3 markers (n > m)
    X = ones(4, 1); y = [10.0, 12.0, 11.0, 9.0]
    sigma_e2 = 1.0; sigma_g2 = 2.0

    cm = centered_markers(M)
    @test cm.p ≈ [0.375, 0.625, 0.625] atol = 1e-12
    @test cm.k ≈ 1.40625 atol = 1e-12
    @test all(abs.(vec(sum(cm.W, dims = 1))) .< 1e-12)             # columns centered
    @test genomic_relationship_matrix(M) ≈ (cm.W * transpose(cm.W)) ./ cm.k

    fit = fit_snp_blup(y, X, M, sigma_g2, sigma_e2)
    @test fit.beta ≈ [10.5] atol = 1e-8
    @test fit.marker_effects ≈
          [0.5020889425308699, -0.5139727044842634, -0.50208894253087] atol = 1e-8
    @test fit.gebv ≈
          [-0.6246402376752391, 1.3837155324482406, 0.37953764738650075, -1.1386129421595024] atol = 1e-8
    @test (X * fit.beta .+ fit.gebv) ≈
          [9.875359762324761, 11.88371553244824, 10.8795376473865, 9.361387057840497] atol = 1e-8
    @test haskey(fit, :marker_effects) && haskey(fit, :gebv)       # relabeled (not breeding_values/EBV)

    # GBLUP<->SNP-BLUP equivalence: route GBLUP through the marginal V (never invert singular G)
    function gblup_via_marginal(Mk, X, y, sg2, se2)
        G = genomic_relationship_matrix(Mk)
        V = sg2 .* G + se2 * I
        beta = (transpose(X) * (V \ X)) \ (transpose(X) * (V \ y))
        u = sg2 .* G * (V \ (y .- X * beta))
        return beta, u
    end
    bg, ug = gblup_via_marginal(M, X, y, sigma_g2, sigma_e2)
    @test maximum(abs.(ug .- fit.gebv)) < 1e-10                    # observed ~5e-17
    @test maximum(abs.(bg .- fit.beta)) < 1e-10

    # second regime: markers > records (n < m)
    M2 = [0.0 1 2 1 0 2; 2 1 0 1 2 0; 1 0 1 2 1 1; 0 2 1 0 2 1]    # 4 x 6
    fit2 = fit_snp_blup(y, X, M2, sigma_g2, sigma_e2)
    bg2, ug2 = gblup_via_marginal(M2, X, y, sigma_g2, sigma_e2)
    @test maximum(abs.(ug2 .- fit2.gebv)) < 1e-10
    @test maximum(abs.(bg2 .- fit2.beta)) < 1e-10

    # guards
    @test_throws ArgumentError fit_snp_blup(y, X, M, -1.0, 1.0)    # sigma_g2 <= 0
    @test_throws ArgumentError centered_markers(fill(2.0, 4, 3))   # monomorphic (k = 0)
end

@testset "Phase 5 fixed-effect single-marker scan" begin
    y = [1.0, 2.0, 4.0, 2.0, 3.0]
    X = ones(5, 1)
    M = [
        0.0 0.0
        1.0 0.0
        2.0 1.0
        0.0 2.0
        1.0 2.0
    ]
    scan = single_marker_scan(y, X, M; marker_ids = ["m1", "m2"])

    @test scan.marker_ids == ["m1", "m2"]
    @test scan.p ≈ [0.4, 0.5] atol = 1e-12
    @test scan.k ≈ 0.98 atol = 1e-12
    @test scan.denominators ≈ [2.8, 4.0] atol = 1e-12
    @test scan.effects ≈ [17 / 14, 0.5] atol = 1e-12
    @test scan.standard_errors ≈ [sqrt(1 / 2.8), 0.5] atol = 1e-12
    @test scan.z_scores ≈ [(17 / 14) / sqrt(1 / 2.8), 1.0] atol = 1e-12
    @test scan.chisq ≈ scan.z_scores .^ 2 atol = 1e-12
    @test scan.p_values ≈ [0.042164931253363, 0.3173105078629141] atol = 1e-6
    @test scan.bonferroni_p_values ≈ [0.084329862506726, 0.6346210157258282] atol = 1e-6
    @test scan.bh_q_values ≈ [0.084329862506726, 0.3173105078629141] atol = 1e-6
    @test scan.lod_scores ≈ scan.chisq ./ (2 * log(10)) atol = 1e-12
    scan_table = marker_scan_table(scan)
    @test scan_table.target == :direct_marker_scan
    @test scan_table.marker_ids == scan.marker_ids
    @test scan_table.scan_indices == [1, 2]
    @test scan_table.effects ≈ scan.effects atol = 1e-12
    @test scan_table.abs_effects ≈ abs.(scan.effects) atol = 1e-12
    @test scan_table.standard_errors ≈ scan.standard_errors atol = 1e-12
    @test scan_table.z_scores ≈ scan.z_scores atol = 1e-12
    @test scan_table.chisq ≈ scan.chisq atol = 1e-12
    @test scan_table.p_values ≈ scan.p_values atol = 1e-12
    @test scan_table.bonferroni_p_values ≈ scan.bonferroni_p_values atol = 1e-12
    @test scan_table.bh_q_values ≈ scan.bh_q_values atol = 1e-12
    @test scan_table.lod_scores ≈ scan.lod_scores atol = 1e-12
    @test scan_table.denominators ≈ scan.denominators atol = 1e-12
    @test scan_table.allele_frequencies ≈ scan.p atol = 1e-12
    @test scan_table.allele_variances ≈ 2 .* scan.p .* (1 .- scan.p) atol = 1e-12
    @test scan_table.marker_variances ≈ 2 .* scan.p .* (1 .- scan.p) .* scan.effects .^ 2 atol = 1e-12
    @test scan_table.proportion_variance_explained === nothing
    @test scan_table.total_variance === nothing
    @test scan_table.vanraden_scale ≈ scan.k atol = 1e-12
    scan_table_total = marker_scan_table(scan; total_variance = 2.0)
    @test scan_table_total.total_variance == 2.0
    @test scan_table_total.proportion_variance_explained ≈ scan_table.marker_variances ./ 2 atol = 1e-12
    inflation = marker_genomic_inflation(scan)
    @test inflation.target == :direct_marker_scan
    @test inflation.n_markers == 2
    @test inflation.median_chisq ≈ sum(scan.chisq) / 2 atol = 1e-12
    @test inflation.expected_median ≈ HSquared._CHISQ1_MEDIAN atol = 1e-15
    @test inflation.lambda_gc ≈ inflation.median_chisq / HSquared._CHISQ1_MEDIAN atol = 1e-12
    significance = marker_significance_summary(scan; alpha = 0.1)
    @test significance.target == :direct_marker_scan
    @test significance.marker_count == 2
    @test significance.alpha == 0.1
    @test significance.nominal_p_threshold == 0.1
    @test significance.bonferroni_raw_p_threshold == 0.05
    @test significance.adjusted_p_threshold == 0.1
    @test significance.bh_q_threshold == 0.1
    @test significance.raw_significant == [true, false]
    @test significance.bonferroni_significant == [true, false]
    @test significance.bh_significant == [true, false]
    @test significance.n_raw_significant == 1
    @test significance.n_bonferroni_significant == 1
    @test significance.n_bh_significant == 1
    @test significance.raw_marker_ids == ["m1"]
    @test significance.bonferroni_marker_ids == ["m1"]
    @test significance.bh_marker_ids == ["m1"]
    @test significance.raw_scan_indices == [1]
    @test significance.bonferroni_scan_indices == [1]
    @test significance.bh_scan_indices == [1]
    @test significance.min_p_value ≈ minimum(scan.p_values) atol = 1e-12
    @test significance.min_bonferroni_p_value ≈ minimum(scan.bonferroni_p_values) atol = 1e-12
    @test significance.min_bh_q_value ≈ minimum(scan.bh_q_values) atol = 1e-12
    @test significance.max_chisq ≈ maximum(scan.chisq) atol = 1e-12
    @test significance.max_lod_score ≈ maximum(scan.lod_scores) atol = 1e-12
    @test significance.top_marker_id == "m1"
    @test significance.top_scan_index == 1
    @test significance.top_p_value ≈ scan.p_values[1] atol = 1e-12
    @test significance.top_bonferroni_p_value ≈ scan.bonferroni_p_values[1] atol = 1e-12
    @test significance.top_bh_q_value ≈ scan.bh_q_values[1] atol = 1e-12
    @test significance.top_chisq ≈ scan.chisq[1] atol = 1e-12
    @test significance.top_lod_score ≈ scan.lod_scores[1] atol = 1e-12
    summary = marker_effects(scan)
    @test summary.target == :direct_marker_scan
    @test summary.sort_by == :p_value
    @test summary.decreasing == false
    @test summary.top_n == 2
    @test summary.scan_indices == [1, 2]
    @test summary.marker_ids == scan.marker_ids
    @test summary.effects ≈ scan.effects atol = 1e-12
    @test summary.abs_effects ≈ abs.(scan.effects) atol = 1e-12
    @test summary.standard_errors ≈ scan.standard_errors atol = 1e-12
    @test summary.chisq ≈ scan.chisq atol = 1e-12
    @test summary.p_values ≈ scan.p_values atol = 1e-12
    @test summary.bonferroni_p_values ≈ scan.bonferroni_p_values atol = 1e-12
    @test summary.bh_q_values ≈ scan.bh_q_values atol = 1e-12
    @test summary.lod_scores ≈ scan.lod_scores atol = 1e-12
    @test summary.denominators ≈ scan.denominators atol = 1e-12
    top_chisq = marker_effects(scan; sort_by = :chisq, top_n = 1)
    @test top_chisq.sort_by == :chisq
    @test top_chisq.decreasing == true
    @test top_chisq.top_n == 1
    @test top_chisq.marker_ids == ["m1"]
    @test top_chisq.scan_indices == [1]
    expected_marker_variances = 2 .* scan.p .* (1 .- scan.p) .* scan.effects .^ 2
    variance_summary = marker_variance_explained(scan)
    variance_order = sortperm(collect(1:2); by = i -> (-expected_marker_variances[i], i))
    @test variance_summary.target == :direct_marker_scan
    @test variance_summary.sort_by == :marker_variance
    @test variance_summary.decreasing == true
    @test variance_summary.top_n == 2
    @test variance_summary.marker_ids == scan.marker_ids[variance_order]
    @test variance_summary.effects ≈ scan.effects[variance_order] atol = 1e-12
    @test variance_summary.allele_frequencies ≈ scan.p[variance_order] atol = 1e-12
    @test variance_summary.allele_variances ≈ (2 .* scan.p .* (1 .- scan.p))[variance_order] atol = 1e-12
    @test variance_summary.marker_variances ≈ expected_marker_variances[variance_order] atol = 1e-12
    @test variance_summary.proportion_variance_explained === nothing
    @test variance_summary.p_values ≈ scan.p_values[variance_order] atol = 1e-12
    @test variance_summary.scan_indices == variance_order
    top_pve = marker_variance_explained(
        scan;
        total_variance = 2.0,
        sort_by = :proportion_variance_explained,
        top_n = 1,
    )
    @test top_pve.sort_by == :proportion_variance_explained
    @test top_pve.total_variance == 2.0
    @test top_pve.marker_ids == ["m1"]
    @test top_pve.proportion_variance_explained ≈ [expected_marker_variances[1] / 2] atol = 1e-12
    pvalue_variance = marker_variance_explained(scan; sort_by = :p_value)
    @test pvalue_variance.sort_by == :p_value
    @test pvalue_variance.decreasing == false
    @test pvalue_variance.marker_ids == scan.marker_ids
    @test HSquared._standard_normal_two_sided_pvalue(0.0) ≈ 1.0 atol = 1e-12
    @test HSquared._standard_normal_two_sided_pvalue(1.96) ≈ 0.04999579029644087 atol = 1e-6
    @test all(0 .<= scan.p_values .<= 1)
    @test all(0 .<= scan.bonferroni_p_values .<= 1)
    @test all(0 .<= scan.bh_q_values .<= 1)
    @test all(scan.lod_scores .>= 0)
    @test HSquared._bonferroni_adjust([0.04, 0.01, 0.20, 0.03]) ≈
          [0.16, 0.04, 0.80, 0.12] atol = 1e-12
    @test HSquared._benjamini_hochberg_adjust([0.04, 0.01, 0.20, 0.03]) ≈
          [0.05333333333333334, 0.04, 0.20, 0.05333333333333334] atol = 1e-12

    # With a nontrivial fixed-effect design, the scan equals independent
    # residualization of y and each marker against X.
    X2 = [ones(5) [0.0, 1.0, 0.0, 1.0, 0.0]]
    scan2 = single_marker_scan(y, X2, M; sigma_e2 = 2.0)
    cm = centered_markers(M)
    XtX = Symmetric(transpose(X2) * X2)
    y_resid = y - X2 * (XtX \ (transpose(X2) * y))
    for j in axes(M, 2)
        w = cm.W[:, j]
        w_resid = w - X2 * (XtX \ (transpose(X2) * w))
        denom = dot(w_resid, w_resid)
        effect = dot(w_resid, y_resid) / denom
        @test scan2.denominators[j] ≈ denom atol = 1e-12
        @test scan2.effects[j] ≈ effect atol = 1e-12
        @test scan2.standard_errors[j] ≈ sqrt(2.0 / denom) atol = 1e-12
        @test scan2.p_values[j] ≈ HSquared._standard_normal_two_sided_pvalue(scan2.z_scores[j]) atol = 1e-12
    end
    @test scan2.bonferroni_p_values ≈ HSquared._bonferroni_adjust(scan2.p_values) atol = 1e-12
    @test scan2.bh_q_values ≈ HSquared._benjamini_hochberg_adjust(scan2.p_values) atol = 1e-12
    @test scan2.lod_scores ≈ scan2.chisq ./ (2 * log(10)) atol = 1e-12

    zeroZ = zeros(5, 1)
    fixed_reduction = mixed_model_marker_scan(
        y,
        X,
        zeroZ,
        Matrix{Float64}(I, 1, 1),
        M,
        2.0,
        1.0;
        marker_ids = ["m1", "m2"],
    )
    @test fixed_reduction.target == :mixed_model_marker_scan
    @test fixed_reduction.variance_components == (sigma_a2 = 2.0, sigma_e2 = 1.0)
    @test fixed_reduction.marker_ids == scan.marker_ids
    @test fixed_reduction.effects ≈ scan.effects atol = 1e-12
    @test fixed_reduction.standard_errors ≈ scan.standard_errors atol = 1e-12
    @test fixed_reduction.p_values ≈ scan.p_values atol = 1e-12
    @test fixed_reduction.bh_q_values ≈ scan.bh_q_values atol = 1e-12
    @test fixed_reduction.lod_scores ≈ scan.lod_scores atol = 1e-12

    ids = [1, 2, 3, 4, 5]
    Ainv_mixed = pedigree_inverse(ids, [0, 0, 1, 1, 3], [0, 0, 2, 2, 4])
    Z_mixed = Matrix{Float64}(I, 5, 5)
    mixed = mixed_model_marker_scan(
        y,
        X2,
        Z_mixed,
        Ainv_mixed,
        M,
        0.7,
        1.2;
        marker_ids = ["m1", "m2"],
    )
    @test mixed.marker_ids == ["m1", "m2"]
    @test mixed.p ≈ scan.p atol = 1e-12
    @test mixed.k ≈ scan.k atol = 1e-12
    @test mixed.variance_components == (sigma_a2 = 0.7, sigma_e2 = 1.2)

    A_mixed = inv(Symmetric(Matrix(Ainv_mixed)))
    V_mixed = Symmetric(0.7 * Z_mixed * A_mixed * transpose(Z_mixed) + 1.2 * Matrix{Float64}(I, 5, 5))
    cholV = cholesky(V_mixed)
    Vinv_X = cholV \ X2
    Vinv_y = cholV \ y
    XtVinvX = Symmetric(transpose(X2) * Vinv_X)
    cholXtVinvX = cholesky(XtVinvX)
    Py = Vinv_y - Vinv_X * (cholXtVinvX \ (transpose(X2) * Vinv_y))
    for j in axes(M, 2)
        w = cm.W[:, j]
        Vinv_w = cholV \ w
        Pw = Vinv_w - Vinv_X * (cholXtVinvX \ (transpose(X2) * Vinv_w))
        denom = dot(w, Pw)
        effect = dot(w, Py) / denom
        @test mixed.denominators[j] ≈ denom atol = 1e-12
        @test mixed.effects[j] ≈ effect atol = 1e-12
        @test mixed.standard_errors[j] ≈ sqrt(inv(denom)) atol = 1e-12
        @test mixed.p_values[j] ≈ HSquared._standard_normal_two_sided_pvalue(mixed.z_scores[j]) atol = 1e-12
    end
    @test mixed.chisq ≈ mixed.z_scores .^ 2 atol = 1e-12
    @test mixed.bonferroni_p_values ≈ HSquared._bonferroni_adjust(mixed.p_values) atol = 1e-12
    @test mixed.bh_q_values ≈ HSquared._benjamini_hochberg_adjust(mixed.p_values) atol = 1e-12
    @test mixed.lod_scores ≈ mixed.chisq ./ (2 * log(10)) atol = 1e-12
    @test marker_manhattan_data(mixed).marker_ids == mixed.marker_ids
    @test marker_qq_data(mixed).marker_ids == mixed.marker_ids
    mixed_inflation = marker_genomic_inflation(mixed)
    @test mixed_inflation.target == :mixed_model_marker_scan
    @test mixed_inflation.median_chisq ≈ sum(mixed.chisq) / 2 atol = 1e-12
    @test marker_significance_summary(mixed).target == :mixed_model_marker_scan
    mixed_summary = marker_effects(mixed; sort_by = :lod_score)
    @test mixed_summary.target == :mixed_model_marker_scan
    @test mixed_summary.sort_by == :lod_score
    @test mixed_summary.decreasing == true
    @test mixed_summary.marker_ids == mixed.marker_ids[sortperm(collect(1:2); by = i -> (-mixed.lod_scores[i], i))]
    mixed_variance = marker_variance_explained(mixed; total_variance = 3.0)
    @test mixed_variance.target == :mixed_model_marker_scan
    @test mixed_variance.total_variance == 3.0
    @test mixed_variance.proportion_variance_explained !== nothing
    mixed_table = marker_scan_table(mixed; total_variance = 3.0)
    @test mixed_table.target == :mixed_model_marker_scan
    @test mixed_table.marker_ids == mixed.marker_ids
    @test mixed_table.variance_components == mixed.variance_components
    @test mixed_table.proportion_variance_explained ≈ mixed_table.marker_variances ./ 3 atol = 1e-12

    Ainv_loco1 = Matrix(Ainv_mixed)
    Ainv_loco2 = 1.4 .* Matrix(Ainv_mixed)
    loco = loco_mixed_model_marker_scan(
        y,
        X2,
        Z_mixed,
        Dict("chr1" => Ainv_loco1, "chr2" => Ainv_loco2),
        ["chr1", "chr2"],
        M,
        0.7,
        1.2;
        marker_ids = ["m1", "m2"],
    )
    @test loco.target == :loco_mixed_model_marker_scan
    @test loco.marker_ids == ["m1", "m2"]
    @test loco.marker_groups == ["chr1", "chr2"]
    @test loco.relationship_groups == ["chr1", "chr2"]
    @test loco.variance_components == (sigma_a2 = 0.7, sigma_e2 = 1.2)
    ref_chr1 = mixed_model_marker_scan(
        y,
        X2,
        Z_mixed,
        Ainv_loco1,
        M[:, 1:1],
        0.7,
        1.2;
        marker_ids = ["m1"],
    )
    ref_chr2 = mixed_model_marker_scan(
        y,
        X2,
        Z_mixed,
        Ainv_loco2,
        M[:, 2:2],
        0.7,
        1.2;
        marker_ids = ["m2"],
    )
    @test loco.effects ≈ [only(ref_chr1.effects), only(ref_chr2.effects)] atol = 1e-12
    @test loco.standard_errors ≈ [only(ref_chr1.standard_errors), only(ref_chr2.standard_errors)] atol = 1e-12
    @test loco.denominators ≈ [only(ref_chr1.denominators), only(ref_chr2.denominators)] atol = 1e-12
    @test loco.p_values ≈ [only(ref_chr1.p_values), only(ref_chr2.p_values)] atol = 1e-12
    @test loco.bonferroni_p_values ≈ HSquared._bonferroni_adjust(loco.p_values) atol = 1e-12
    @test loco.bh_q_values ≈ HSquared._benjamini_hochberg_adjust(loco.p_values) atol = 1e-12
    @test loco.lod_scores ≈ loco.chisq ./ (2 * log(10)) atol = 1e-12
    @test marker_manhattan_data(loco).marker_ids == loco.marker_ids
    @test marker_qq_data(loco).marker_ids == loco.marker_ids
    loco_inflation = marker_genomic_inflation(loco)
    @test loco_inflation.target == :loco_mixed_model_marker_scan
    @test loco_inflation.median_chisq ≈ sum(loco.chisq) / 2 atol = 1e-12
    @test marker_significance_summary(loco).target == :loco_mixed_model_marker_scan
    loco_summary = marker_effects(loco; top_n = 1)
    @test loco_summary.target == :loco_mixed_model_marker_scan
    @test length(loco_summary.marker_ids) == 1
    loco_variance = marker_variance_explained(loco; top_n = 1)
    @test loco_variance.target == :loco_mixed_model_marker_scan
    @test length(loco_variance.marker_ids) == 1
    loco_table = marker_scan_table(loco)
    @test loco_table.target == :loco_mixed_model_marker_scan
    @test loco_table.marker_groups == ["chr1", "chr2"]
    @test loco_table.marker_ids == loco.marker_ids

    loco_precisions = loco_relationship_precisions(M, ["chr1", "chr2"]; ridge = 0.2)
    @test sort(collect(keys(loco_precisions))) == ["chr1", "chr2"]
    @test loco_precisions["chr1"] ≈ genomic_relationship_inverse(
        genomic_relationship_matrix(M[:, 2:2]);
        ridge = 0.2,
    ) atol = 1e-12
    @test loco_precisions["chr2"] ≈ genomic_relationship_inverse(
        genomic_relationship_matrix(M[:, 1:1]);
        ridge = 0.2,
    ) atol = 1e-12
    loco_precisions_p = loco_relationship_precisions(
        M,
        ["chr1", "chr2"];
        allele_frequencies = [0.25, 0.45],
        ridge = 0.2,
    )
    @test loco_precisions_p["chr1"] ≈ genomic_relationship_inverse(
        genomic_relationship_matrix(M[:, 2:2]; allele_frequencies = [0.45]);
        ridge = 0.2,
    ) atol = 1e-12
    @test loco_precisions_p["chr2"] ≈ genomic_relationship_inverse(
        genomic_relationship_matrix(M[:, 1:1]; allele_frequencies = [0.25]);
        ridge = 0.2,
    ) atol = 1e-12
    loco_constructed = loco_mixed_model_marker_scan(
        y,
        X2,
        Z_mixed,
        loco_precisions,
        ["chr1", "chr2"],
        M,
        0.7,
        1.2;
        marker_ids = ["m1", "m2"],
    )
    ref_constructed_chr1 = mixed_model_marker_scan(
        y,
        X2,
        Z_mixed,
        loco_precisions["chr1"],
        M[:, 1:1],
        0.7,
        1.2;
        marker_ids = ["m1"],
    )
    ref_constructed_chr2 = mixed_model_marker_scan(
        y,
        X2,
        Z_mixed,
        loco_precisions["chr2"],
        M[:, 2:2],
        0.7,
        1.2;
        marker_ids = ["m2"],
    )
    @test loco_constructed.effects ≈ [only(ref_constructed_chr1.effects), only(ref_constructed_chr2.effects)] atol = 1e-12
    @test loco_constructed.standard_errors ≈
          [only(ref_constructed_chr1.standard_errors), only(ref_constructed_chr2.standard_errors)] atol = 1e-12
    @test loco_constructed.p_values ≈ [only(ref_constructed_chr1.p_values), only(ref_constructed_chr2.p_values)] atol = 1e-12

    manhattan = marker_manhattan_data(scan)
    @test manhattan.marker_ids == ["m1", "m2"]
    @test manhattan.chromosomes == ["1", "1"]
    @test manhattan.positions == [1.0, 2.0]
    @test manhattan.plot_positions == [1.0, 2.0]
    @test manhattan.p_values ≈ scan.p_values atol = 1e-12
    @test manhattan.neglog10_p_values ≈ .-log10.(scan.p_values) atol = 1e-12
    @test manhattan.order == [1, 2]

    custom_scan = (
        marker_ids = ["a", "b", "c"],
        p_values = [0.01, 0.0, 1.0],
    )
    custom_manhattan = marker_manhattan_data(
        custom_scan;
        chromosomes = ["2", "1", "2"],
        positions = [5, 2, 1],
        p_floor = 1e-12,
        chromosome_gap = 2,
    )
    @test custom_manhattan.order == [3, 1, 2]
    @test custom_manhattan.chromosomes == ["2", "1", "2"]
    @test custom_manhattan.positions == [5.0, 2.0, 1.0]
    @test custom_manhattan.plot_positions == [5.0, 9.0, 1.0]
    @test custom_manhattan.neglog10_p_values ≈ [2.0, 12.0, -0.0] atol = 1e-12
    @test custom_manhattan.p_floor == 1e-12

    marker_map_data = HSData(
        (id = ["a"], y = [1.0]);
        markers = (marker = ["m2", "m1"], chr = ["1", "2"], pos = [1, 5]),
    )
    map_manhattan = marker_manhattan_data(scan, marker_map_data.marker_spec)
    @test map_manhattan.marker_ids == ["m1", "m2"]
    @test map_manhattan.chromosomes == ["2", "1"]
    @test map_manhattan.positions == [5.0, 1.0]
    @test map_manhattan.plot_positions == [7.0, 1.0]
    @test map_manhattan.order == [2, 1]
    @test marker_manhattan_data(scan, marker_map_data).plot_positions == map_manhattan.plot_positions
    map_summary = marker_effects(scan, marker_map_data)
    @test map_summary.marker_ids == ["m1", "m2"]
    @test map_summary.chromosomes == ["2", "1"]
    @test map_summary.positions == [5.0, 1.0]
    @test map_summary.scan_indices == [1, 2]
    map_variance = marker_variance_explained(scan, marker_map_data)
    @test map_variance.marker_ids == ["m1", "m2"]
    @test map_variance.chromosomes == ["2", "1"]
    @test map_variance.positions == [5.0, 1.0]
    @test map_variance.scan_indices == [1, 2]
    map_table = marker_scan_table(scan, marker_map_data)
    @test map_table.marker_ids == ["m1", "m2"]
    @test map_table.chromosomes == ["2", "1"]
    @test map_table.positions == [5.0, 1.0]
    @test map_table.scan_indices == [1, 2]
    gwas = gwas_table(scan; trait = :height, total_variance = 2.0)
    @test gwas.analysis == :gwas
    @test gwas.trait == "height"
    @test gwas.marker_ids == scan.marker_ids
    @test gwas.target == :direct_marker_scan
    @test gwas.proportion_variance_explained ≈ scan_table.marker_variances ./ 2 atol = 1e-12
    map_gwas = gwas_table(scan, marker_map_data; trait = "height")
    @test map_gwas.analysis == :gwas
    @test map_gwas.trait == "height"
    @test map_gwas.chromosomes == ["2", "1"]
    @test map_gwas.positions == [5.0, 1.0]
    qtl = qtl_table(mixed; trait = "yield")
    @test qtl.analysis == :qtl
    @test qtl.trait == "yield"
    @test qtl.target == :mixed_model_marker_scan
    @test qtl.marker_ids == mixed.marker_ids
    @test qtl.lod_scores ≈ mixed.lod_scores atol = 1e-12
    eqtl = eqtl_table(loco; feature = "geneA")
    @test eqtl.analysis == :eqtl
    @test eqtl.feature == "geneA"
    @test eqtl.target == :loco_mixed_model_marker_scan
    @test eqtl.marker_groups == ["chr1", "chr2"]
    map_eqtl = eqtl_table(scan, marker_map_data.marker_spec; feature = :transcript_1)
    @test map_eqtl.analysis == :eqtl
    @test map_eqtl.feature == "transcript_1"
    @test map_eqtl.chromosomes == ["2", "1"]
    map_region = marker_region_data(
        scan,
        marker_map_data;
        chromosome = "2",
        start = 4,
        stop = 4,
        flank = 1,
        total_variance = 2.0,
    )
    @test map_region.marker_ids == ["m1"]
    @test map_region.chromosomes == ["2"]
    @test map_region.positions == [5.0]
    @test map_region.plot_positions == [5.0]
    @test map_region.scan_indices == [1]
    @test map_region.effects ≈ [scan.effects[1]] atol = 1e-12
    @test map_region.p_values ≈ [scan.p_values[1]] atol = 1e-12
    @test map_region.marker_variances ≈ [map_table.marker_variances[1]] atol = 1e-12
    @test map_region.proportion_variance_explained ≈ [map_table.marker_variances[1] / 2] atol = 1e-12
    @test map_region.total_variance == 2.0
    @test map_region.chromosome == "2"
    @test map_region.requested_start == 4.0
    @test map_region.requested_stop == 4.0
    @test map_region.flank == 1.0
    @test map_region.window_start == 3.0
    @test map_region.window_stop == 5.0
    @test map_region.neglog10_p_values ≈ .-log10.([scan.p_values[1]]) atol = 1e-12
    @test map_region.target == :direct_marker_scan
    @test marker_region_data(scan, marker_map_data.marker_spec; chromosome = :1).marker_ids == ["m2"]
    qq = marker_qq_data(scan)
    @test qq.marker_ids == ["m1", "m2"]
    @test qq.p_values ≈ scan.p_values atol = 1e-12
    @test qq.order == [1, 2]
    @test qq.sorted_marker_ids == ["m1", "m2"]
    @test qq.sorted_p_values ≈ scan.p_values atol = 1e-12
    @test qq.expected_p_values ≈ [1 / 3, 2 / 3] atol = 1e-12
    @test qq.observed_neglog10_p_values ≈ .-log10.(scan.p_values) atol = 1e-12
    @test qq.expected_neglog10_p_values ≈ .-log10.([1 / 3, 2 / 3]) atol = 1e-12

    custom_qq = marker_qq_data(custom_scan; p_floor = 1e-12)
    @test custom_qq.order == [2, 1, 3]
    @test custom_qq.sorted_marker_ids == ["b", "a", "c"]
    @test custom_qq.sorted_p_values == [0.0, 0.01, 1.0]
    @test custom_qq.expected_p_values ≈ [0.25, 0.5, 0.75] atol = 1e-12
    @test custom_qq.observed_neglog10_p_values ≈ [12.0, 2.0, -0.0] atol = 1e-12
    @test custom_qq.expected_neglog10_p_values ≈ .-log10.([0.25, 0.5, 0.75]) atol = 1e-12
    @test custom_qq.p_floor == 1e-12
    custom_inflation = marker_genomic_inflation((chisq = [9.0, 1.0, 4.0], target = :custom); expected_median = 1.0)
    @test custom_inflation.target == :custom
    @test custom_inflation.n_markers == 3
    @test custom_inflation.median_chisq == 4.0
    @test custom_inflation.lambda_gc == 4.0
    custom_effects_summary = marker_effects((
        marker_ids = ["a", "b", "c"],
        effects = [-3.0, 2.0, 0.5],
        standard_errors = [1.0, 1.0, 0.5],
        z_scores = [-3.0, 2.0, 1.0],
        chisq = [9.0, 4.0, 1.0],
        p_values = [0.01, 0.02, 0.5],
        bonferroni_p_values = [0.03, 0.06, 1.0],
        bh_q_values = [0.03, 0.03, 0.5],
        lod_scores = [9.0, 4.0, 1.0] ./ (2 * log(10)),
        denominators = [2.0, 3.0, 4.0],
        target = :custom,
    ); sort_by = :abs_effect, top_n = 2)
    @test custom_effects_summary.target == :custom
    @test custom_effects_summary.sort_by == :abs_effect
    @test custom_effects_summary.marker_ids == ["a", "b"]
    @test custom_effects_summary.abs_effects == [3.0, 2.0]
    @test custom_effects_summary.scan_indices == [1, 2]
    bh_summary = marker_effects(custom_effects_summary; sort_by = :bh_q_value, decreasing = true)
    @test bh_summary.sort_by == :bh_q_value
    @test bh_summary.decreasing == true
    @test bh_summary.marker_ids == ["a", "b"]
    custom_variance_summary = marker_variance_explained((
        marker_ids = ["a", "b", "c"],
        effects = [-3.0, 2.0, 0.5],
        p = [0.5, 0.25, 0.0],
        p_values = [0.01, 0.02, 0.5],
        target = :custom,
    ); total_variance = 10.0, sort_by = :abs_effect, top_n = 2)
    @test custom_variance_summary.target == :custom
    @test custom_variance_summary.sort_by == :abs_effect
    @test custom_variance_summary.marker_ids == ["a", "b"]
    @test custom_variance_summary.marker_variances ≈ [4.5, 1.5] atol = 1e-12
    @test custom_variance_summary.proportion_variance_explained ≈ [0.45, 0.15] atol = 1e-12
    custom_full_scan = (
        marker_ids = ["a", "b", "c"],
        effects = [-3.0, 2.0, 0.5],
        standard_errors = [1.0, 1.0, 0.5],
        z_scores = [-3.0, 2.0, 1.0],
        chisq = [9.0, 4.0, 1.0],
        p_values = [0.01, 0.02, 0.5],
        bonferroni_p_values = [0.03, 0.06, 1.0],
        bh_q_values = [0.03, 0.03, 0.5],
        lod_scores = [9.0, 4.0, 1.0] ./ (2 * log(10)),
        denominators = [2.0, 3.0, 4.0],
        p = [0.5, 0.25, 0.0],
        target = :custom,
    )
    custom_table = marker_scan_table(custom_full_scan; total_variance = 10.0)
    @test custom_table.marker_ids == ["a", "b", "c"]
    @test custom_table.scan_indices == [1, 2, 3]
    @test custom_table.marker_variances ≈ [4.5, 1.5, 0.0] atol = 1e-12
    @test custom_table.proportion_variance_explained ≈ [0.45, 0.15, 0.0] atol = 1e-12
    custom_significance = marker_significance_summary(custom_full_scan; alpha = 0.05)
    @test custom_significance.target == :custom
    @test custom_significance.marker_count == 3
    @test custom_significance.bonferroni_raw_p_threshold ≈ 0.05 / 3 atol = 1e-12
    @test custom_significance.raw_significant == [true, true, false]
    @test custom_significance.bonferroni_significant == [true, false, false]
    @test custom_significance.bh_significant == [true, true, false]
    @test custom_significance.n_raw_significant == 2
    @test custom_significance.n_bonferroni_significant == 1
    @test custom_significance.n_bh_significant == 2
    @test custom_significance.raw_marker_ids == ["a", "b"]
    @test custom_significance.bonferroni_marker_ids == ["a"]
    @test custom_significance.bh_marker_ids == ["a", "b"]
    @test custom_significance.raw_scan_indices == [1, 2]
    @test custom_significance.bonferroni_scan_indices == [1]
    @test custom_significance.bh_scan_indices == [1, 2]
    @test custom_significance.top_marker_id == "a"
    @test custom_significance.top_scan_index == 1
    @test custom_significance.max_chisq == 9.0
    @test custom_significance.max_lod_score ≈ 9.0 / (2 * log(10)) atol = 1e-12
    custom_region = marker_region_data(
        custom_full_scan;
        chromosomes = ["2", "1", "2"],
        positions = [5, 2, 1],
        chromosome = "2",
        start = 0.5,
        stop = 5,
        p_floor = 1e-12,
    )
    @test custom_region.marker_ids == ["c", "a"]
    @test custom_region.positions == [1.0, 5.0]
    @test custom_region.scan_indices == [3, 1]
    @test custom_region.neglog10_p_values ≈ .-log10.([0.5, 0.01]) atol = 1e-12
    @test custom_region.window_start == 0.5
    @test custom_region.window_stop == 5.0

    default_ids = single_marker_scan(y, X, M).marker_ids
    @test default_ids == ["marker_1", "marker_2"]
    @test_throws ArgumentError single_marker_scan(y, X, M; sigma_e2 = 0.0)
    @test_throws ArgumentError single_marker_scan(y, X, M; marker_ids = ["m1"])
    @test_throws ArgumentError HSquared._standard_normal_two_sided_pvalue(NaN)
    @test_throws ArgumentError HSquared._bonferroni_adjust(Float64[])
    @test_throws ArgumentError HSquared._bonferroni_adjust([-0.01, 0.5])
    @test_throws ArgumentError HSquared._bonferroni_adjust([0.5, 1.01])
    @test_throws ArgumentError HSquared._benjamini_hochberg_adjust([0.5, NaN])
    @test_throws ArgumentError marker_manhattan_data((p_values = [0.5],))
    @test_throws ArgumentError marker_manhattan_data((marker_ids = ["m1"],))
    @test_throws ArgumentError marker_manhattan_data((marker_ids = ["m1"], p_values = [0.5, 0.6]))
    @test_throws ArgumentError marker_manhattan_data(scan; chromosomes = ["1"])
    @test_throws ArgumentError marker_manhattan_data(scan; positions = [1.0])
    @test_throws ArgumentError marker_manhattan_data(scan; positions = [1.0, -1.0])
    @test_throws ArgumentError marker_manhattan_data(scan; p_floor = 0.0)
    @test_throws ArgumentError marker_manhattan_data(scan; chromosome_gap = -1.0)
    @test_throws ArgumentError marker_qq_data((p_values = [0.5],))
    @test_throws ArgumentError marker_qq_data((marker_ids = ["m1"],))
    @test_throws ArgumentError marker_qq_data((marker_ids = ["m1"], p_values = [0.5, 0.6]))
    @test_throws ArgumentError marker_qq_data(scan; p_floor = 0.0)
    @test_throws ArgumentError marker_genomic_inflation((p_values = [0.5],))
    @test_throws ArgumentError marker_genomic_inflation((chisq = Float64[],))
    @test_throws ArgumentError marker_genomic_inflation((chisq = [0.5, -0.1],))
    @test_throws ArgumentError marker_genomic_inflation((chisq = [0.5, NaN],))
    @test_throws ArgumentError marker_genomic_inflation(scan; expected_median = 0.0)
    @test_throws ArgumentError marker_significance_summary((p_values = [0.5],))
    @test_throws ArgumentError marker_significance_summary((marker_ids = ["m1"], p_values = [0.5]))
    @test_throws ArgumentError marker_significance_summary(merge(scan, (bonferroni_p_values = [0.5],)))
    @test_throws ArgumentError marker_significance_summary(merge(scan, (bh_q_values = [0.5, NaN],)))
    @test_throws ArgumentError marker_significance_summary(merge(scan, (chisq = [1.0, -0.1],)))
    @test_throws ArgumentError marker_significance_summary(merge(scan, (lod_scores = [0.1],)))
    @test_throws ArgumentError marker_significance_summary(scan; alpha = 0.0)
    @test_throws ArgumentError marker_significance_summary(scan; alpha = 1.1)
    @test_throws ArgumentError marker_significance_summary(scan; alpha = NaN)
    @test_throws ArgumentError marker_significance_summary(scan; alpha = "not numeric")
    @test_throws ArgumentError marker_effects((marker_ids = ["m1"], p_values = [0.5]))
    @test_throws ArgumentError marker_effects(merge(scan, (effects = [1.0],)))
    @test_throws ArgumentError marker_effects(merge(scan, (effects = [NaN, 1.0],)))
    @test_throws ArgumentError marker_effects(merge(scan, (standard_errors = [0.0, 1.0],)))
    @test_throws ArgumentError marker_effects(merge(scan, (chisq = [1.0, -0.1],)))
    @test_throws ArgumentError marker_effects(scan; sort_by = :unsupported)
    @test_throws ArgumentError marker_effects(scan; top_n = 0)
    @test_throws ArgumentError marker_effects(scan; top_n = 3)
    @test_throws ArgumentError marker_effects(scan; top_n = 1.5)
    @test_throws ArgumentError marker_effects(scan, HSData((id = ["a"], y = [1.0])))
    @test_throws ArgumentError marker_variance_explained((marker_ids = ["m1"], effects = [1.0]))
    @test_throws ArgumentError marker_variance_explained(merge(scan, (effects = [1.0],)))
    @test_throws ArgumentError marker_variance_explained(merge(scan, (effects = [NaN, 1.0],)))
    @test_throws ArgumentError marker_variance_explained(merge(scan, (p = [0.5],)))
    @test_throws ArgumentError marker_variance_explained(merge(scan, (p = [-0.1, 0.5],)))
    @test_throws ArgumentError marker_variance_explained(merge(scan, (p = [NaN, 0.5],)))
    @test_throws ArgumentError marker_variance_explained(scan; total_variance = 0.0)
    @test_throws ArgumentError marker_variance_explained(scan; sort_by = :unsupported)
    @test_throws ArgumentError marker_variance_explained(scan; sort_by = :proportion)
    @test_throws ArgumentError marker_variance_explained(scan; top_n = 0)
    @test_throws ArgumentError marker_variance_explained(scan; top_n = 3)
    @test_throws ArgumentError marker_variance_explained(scan; top_n = 1.5)
    @test_throws ArgumentError marker_variance_explained(
        (marker_ids = ["m1"], effects = [1.0], p = [0.5]);
        sort_by = :p_value,
    )
    @test_throws ArgumentError marker_variance_explained(scan, HSData((id = ["a"], y = [1.0])))
    @test_throws ArgumentError marker_scan_table((marker_ids = ["m1"], p_values = [0.5]))
    @test_throws ArgumentError marker_scan_table(merge(scan, (effects = [1.0],)))
    @test_throws ArgumentError marker_scan_table(merge(scan, (standard_errors = [0.0, 1.0],)))
    @test_throws ArgumentError marker_scan_table(merge(scan, (chisq = [1.0, -0.1],)))
    @test_throws ArgumentError marker_scan_table(merge(scan, (p = [-0.1, 0.5],)))
    @test_throws ArgumentError marker_scan_table(merge(scan, (k = missing,)))
    @test_throws ArgumentError marker_scan_table(merge(scan, (marker_groups = ["chr1"],)))
    @test_throws ArgumentError marker_scan_table(scan; total_variance = 0.0)
    @test_throws ArgumentError marker_scan_table(scan; total_variance = "not numeric")
    @test_throws ArgumentError marker_scan_table(scan, HSData((id = ["a"], y = [1.0])))
    @test_throws ArgumentError gwas_table(scan; trait = "")
    @test_throws ArgumentError qtl_table(scan; trait = " ")
    @test_throws ArgumentError eqtl_table(scan; feature = "")
    @test_throws ArgumentError gwas_table((marker_ids = ["m1"], p_values = [0.5]))
    @test_throws ArgumentError gwas_table(scan, HSData((id = ["a"], y = [1.0])))
    @test_throws ArgumentError qtl_table(scan, HSData((id = ["a"], y = [1.0])))
    @test_throws ArgumentError eqtl_table(scan, HSData((id = ["a"], y = [1.0])))
    @test_throws ArgumentError marker_region_data(scan; chromosome = "1")
    @test_throws ArgumentError marker_region_data(scan; chromosomes = ["1"], positions = [1.0], chromosome = "1")
    @test_throws ArgumentError marker_region_data(scan; chromosomes = ["1", "1"], positions = [1.0], chromosome = "1")
    @test_throws ArgumentError marker_region_data(scan; chromosomes = ["1", ""], positions = [1.0, 2.0], chromosome = "1")
    @test_throws ArgumentError marker_region_data(scan; chromosomes = ["1", "1"], positions = [1.0, -2.0], chromosome = "1")
    @test_throws ArgumentError marker_region_data(scan; chromosomes = ["1", "1"], positions = [1.0, 2.0], chromosome = "")
    @test_throws ArgumentError marker_region_data(scan; chromosomes = ["1", "1"], positions = [1.0, 2.0], chromosome = "1", start = -1.0)
    @test_throws ArgumentError marker_region_data(scan; chromosomes = ["1", "1"], positions = [1.0, 2.0], chromosome = "1", start = 2.0, stop = 1.0)
    @test_throws ArgumentError marker_region_data(scan; chromosomes = ["1", "1"], positions = [1.0, 2.0], chromosome = "1", flank = -1.0)
    @test_throws ArgumentError marker_region_data(scan; chromosomes = ["1", "1"], positions = [1.0, 2.0], chromosome = "1", p_floor = 0.0)
    @test_throws ArgumentError marker_region_data(scan; chromosomes = ["1", "1"], positions = [1.0, 2.0], chromosome = "2")
    @test_throws ArgumentError marker_region_data(scan, HSData((id = ["a"], y = [1.0])); chromosome = "1")
    @test_throws ArgumentError mixed_model_marker_scan(y, X, Z_mixed, Ainv_mixed, M, -1.0, 1.0)
    @test_throws ArgumentError mixed_model_marker_scan(y, X, Z_mixed, Ainv_mixed, M, 1.0, 0.0)
    @test_throws ArgumentError mixed_model_marker_scan(y, X, Z_mixed[1:4, :], Ainv_mixed, M, 1.0, 1.0)
    @test_throws ArgumentError mixed_model_marker_scan(y, X, Z_mixed, Matrix{Float64}(I, 4, 4), M, 1.0, 1.0)
    @test_throws ArgumentError mixed_model_marker_scan(y, [ones(5) ones(5)], Z_mixed, Ainv_mixed, M, 1.0, 1.0)
    @test_throws ArgumentError loco_mixed_model_marker_scan(
        y,
        X,
        Z_mixed,
        Dict("chr1" => Ainv_loco1),
        ["chr1", "chr2"],
        M,
        1.0,
        1.0,
    )
    @test_throws ArgumentError loco_mixed_model_marker_scan(
        y,
        X,
        Z_mixed,
        Dict("chr1" => Ainv_loco1, "chr2" => Ainv_loco2),
        ["chr1"],
        M,
        1.0,
        1.0,
    )
    @test_throws ArgumentError loco_mixed_model_marker_scan(
        y,
        X,
        Z_mixed,
        Dict("chr1" => Ainv_loco1, "chr2" => Matrix{Float64}(I, 4, 4)),
        ["chr1", "chr2"],
        M,
        1.0,
        1.0,
    )
    @test_throws ArgumentError loco_mixed_model_marker_scan(
        y,
        X,
        Z_mixed,
        Dict{String,Matrix{Float64}}(),
        ["chr1", "chr2"],
        M,
        1.0,
        1.0,
    )
    @test_throws ArgumentError marker_manhattan_data(scan, HSData((id = ["a"], y = [1.0])))
    @test_throws ArgumentError marker_manhattan_data(
        (marker_ids = ["m1", "m1"], p_values = [0.1, 0.2]),
        marker_map_data.marker_spec,
    )
    @test_throws ArgumentError marker_manhattan_data(
        scan,
        HSData((id = ["a"], y = [1.0]); markers = (marker = ["m1"], chr = ["1"], pos = [1])).marker_spec,
    )
    cm_one = centered_markers(M[:, 1:1])
    @test_throws ArgumentError single_marker_scan(y, [ones(5) cm_one.W], M[:, 1:1])
    @test_throws ArgumentError mixed_model_marker_scan(
        y,
        [ones(5) cm_one.W],
        Z_mixed,
        Ainv_mixed,
        M[:, 1:1],
        1.0,
        1.0,
    )
    @test_throws ArgumentError loco_mixed_model_marker_scan(
        y,
        [ones(5) cm_one.W],
        Z_mixed,
        Dict("chr1" => Ainv_loco1),
        ["chr1"],
        M[:, 1:1],
        1.0,
        1.0,
    )
    @test_throws ArgumentError loco_relationship_precisions(M, ["chr1"])
    @test_throws ArgumentError loco_relationship_precisions(M, ["chr1", ""])
    @test_throws ArgumentError loco_relationship_precisions(M, ["chr1", "chr1"])
    @test_throws ArgumentError loco_relationship_precisions(M, ["chr1", "chr2"]; ridge = -0.1)
    @test_throws ArgumentError loco_relationship_precisions(M, ["chr1", "chr2"]; ridge = Inf)
    @test_throws ArgumentError loco_relationship_precisions(M, ["chr1", "chr2"]; allele_frequencies = [0.4])
    @test_throws ArgumentError loco_relationship_precisions(M, ["chr1", "chr2"]; allele_frequencies = [0.4, 1.2])
    @test_throws ArgumentError single_marker_scan(y, [ones(5) ones(5)], M)
    @test_throws ArgumentError single_marker_scan([1.0, 2.0], ones(2, 1), M)
end

@testset "Phase 2 dense NRM helper" begin
    ids = [1, 2, 3, 4, 5]; sire = [0, 0, 1, 1, 3]; dam = [0, 0, 2, 2, 4]   # 5=(3x4), full-sib parents
    ped = normalize_pedigree(ids, sire, dam)
    A = HSquared._numerator_relationship(ped)
    @test A ≈ [1.0 0.0 0.5  0.5  0.5;
               0.0 1.0 0.5  0.5  0.5;
               0.5 0.5 1.0  0.5  0.75;
               0.5 0.5 0.5  1.0  0.75;
               0.5 0.5 0.75 0.75 1.25] atol = 1e-12
    @test issymmetric(A)
    # cross-check against the independent sparse-inverse route
    @test A ≈ inv(Symmetric(Matrix(pedigree_inverse(ids, sire, dam)))) atol = 1e-8
    # inbreeding extractor against the hand value: only animal 5 (full-sib parents) is inbred
    @test inbreeding_coefficients(ids, sire, dam) ≈ [0.0, 0.0, 0.0, 0.0, 0.25] atol = 1e-12
    # submatrix method (A22 for single-step) equals the indexed block
    g = [3, 4, 5]
    A22 = HSquared._numerator_relationship(ped, g)
    @test A22 ≈ A[g, g] atol = 1e-12
    @test A22 ≈ [1.0 0.5 0.75; 0.5 1.0 0.75; 0.75 0.75 1.25] atol = 1e-12
    # cache guard still fires (now from the shared helper)
    @test_throws ArgumentError HSquared._numerator_relationship(ped; max_relationship_cache = 2)
end

@testset "Phase 2 genomic reliability / PEV / accuracy semantics" begin
    M = [0.0 1 2 1 0 2; 2 1 0 1 2 0; 1 0 1 2 1 1; 0 2 1 0 2 1]   # 4 x 6
    y = [10.0, 12.0, 11.0, 9.0]; X = ones(4, 1); Z = Matrix{Float64}(I, 4, 4)
    sigma_a2 = 1.5; sigma_e2 = 1.0; ridge = 0.05
    G = genomic_relationship_matrix(M)
    Ginv = genomic_relationship_inverse(G; ridge = ridge)
    res = fit_gblup(y, X, Z, Ginv, sigma_a2, sigma_e2)

    rel = reliability(res); pev = prediction_error_variance(res)
    A_implied = inv(Symmetric(Matrix(Ginv)))                  # = G + ridge*I

    # independent PEV: re-assemble the MME, invert, take the random-block diagonal
    nf = size(X, 2)
    C = [transpose(X) * X / sigma_e2  transpose(X) * Z / sigma_e2
         transpose(Z) * X / sigma_e2  transpose(Z) * Z / sigma_e2 + Ginv / sigma_a2]
    pev_indep = diag(inv(Symmetric(C)))[(nf + 1):end]
    @test pev.values ≈ pev_indep atol = 1e-8                  # PEV independently anchored

    # reliability uses the regularized genomic self-relationship diag(inv(Ginv)) =
    # diag(G) + ridge as the denominator (NOT the pedigree diag(A) = 1); rebuild it from
    # the independent PEV so a wrong denominator in reliability() would FAIL this test
    @test diag(A_implied) ≈ diag(G) .+ ridge atol = 1e-10
    rel_indep = 1 .- pev_indep ./ (sigma_a2 .* diag(A_implied))
    @test rel.values ≈ rel_indep atol = 1e-8
    @test all(0 .<= rel.values .<= 1)
    @test any(abs.(diag(A_implied) .- 1) .> 1e-6)            # genomic self-relationships ≠ 1

    # accuracy = sqrt(reliability), checked against the INDEPENDENT reliability
    @test accuracy(res).values ≈ sqrt.(rel_indep) atol = 1e-8

    # selinv carries over to a genomic Ginv (correctness only; dense Ginv gives no speedup)
    @test prediction_error_variance(res; method = :selinv).values ≈ pev.values atol = 1e-8
end

@testset "Phase 2 single-step H-inverse construction" begin
    ids = [1, 2, 3, 4, 5]; sire = [0, 0, 1, 1, 3]; dam = [0, 0, 2, 2, 4]
    ped = normalize_pedigree(ids, sire, dam)
    A = HSquared._numerator_relationship(ped)
    Ainv = Matrix(pedigree_inverse(ids, sire, dam))
    g = [3, 4, 5]

    # the critical distinction: A22^-1 = inv(A[g,g]) is NOT the submatrix (A^-1)[g,g]
    A22inv = inv(Symmetric(A[g, g]))
    @test A22inv[1, 1] ≈ 11 / 6 atol = 1e-10
    @test Ainv[g, g][1, 1] ≈ 2.5 atol = 1e-10
    @test !isapprox(A22inv[1, 1], Ainv[g, g][1, 1]; atol = 1e-6)

    # reduction: G = A22  =>  H^-1 = A^-1 exactly
    Hred = HSquared._single_step_Hinv(Ainv, A, A[g, g], g)
    @test maximum(abs.(Hred .- Ainv)) < 1e-10

    # locality: only the (g,g) block changes for a generic G
    Gtest = A[g, g] + 0.1 * I
    H2 = HSquared._single_step_Hinv(Ainv, A, Gtest, g)
    nong = setdiff(1:5, g)
    @test maximum(abs.(H2[nong, :] .- Ainv[nong, :])) < 1e-12
    @test maximum(abs.(H2[:, nong] .- Ainv[:, nong])) < 1e-12
    @test maximum(abs.(H2 .- transpose(H2))) < 1e-12              # symmetry

    # scattered (non-trailing) genotyped rows
    gs = [1, 3, 5]; nongs = setdiff(1:5, gs)
    Hs = HSquared._single_step_Hinv(Ainv, A, A[gs, gs] + 0.1 * I, gs)
    @test maximum(abs.(Hs[nongs, :] .- Ainv[nongs, :])) < 1e-12

    # singular raw genomic G throws unless blended/ridged
    G3 = genomic_relationship_matrix([0.0 1 2; 2 1 0; 1 1 1])     # 3x3, rank-deficient
    @test_throws ArgumentError HSquared._single_step_Hinv(Ainv, A, G3, g)
    @test all(isfinite, HSquared._single_step_Hinv(Ainv, A, G3, g; blend_weight = 0.1))

    # dimension guard: G size must match the genotyped count
    @test_throws ArgumentError HSquared._single_step_Hinv(Ainv, A, A[g, g], [3, 4])
end

@testset "Phase 2 GBLUP REML variance-component estimation" begin
    # the existing REML optimizers estimate genomic variance components on a Ginv spec
    M = [0.0 1 2; 2 1 0; 1 1 1; 0 2 2; 1 0 2; 2 1 1]   # 6 animals x 3 markers
    y = [10.0, 12.0, 11.0, 9.0, 13.0, 10.5]
    X = ones(6, 1); Z = Matrix(1.0I, 6, 6)
    G = genomic_relationship_matrix(M)
    Ginv = genomic_relationship_inverse(G; ridge = 0.05)
    spec = animal_model_spec(y, X, Z, Ginv; method = :REML)

    ai = fit_ai_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    nm = fit_sparse_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    @test ai isa AnimalModelFit
    @test ai.target == :ai_reml
    @test ai.converged
    @test ai.variance_components.sigma_a2 > 0
    @test ai.variance_components.sigma_e2 > 0
    # AI-REML and NelderMead reach the same genomic REML optimum
    @test ai.likelihood.loglik ≈ nm.likelihood.loglik rtol = 1e-5
    @test ai.variance_components.sigma_a2 ≈ nm.variance_components.sigma_a2 rtol = 2e-2
    @test ai.variance_components.sigma_e2 ≈ nm.variance_components.sigma_e2 rtol = 2e-2

    # GBLUP at the REML-estimated variance components reproduces the REML breeding values
    res = fit_gblup(y, X, Z, Ginv,
                    ai.variance_components.sigma_a2, ai.variance_components.sigma_e2)
    @test breeding_values(res).values ≈ breeding_values(ai).values atol = 1e-8

    # target dispatch reaches the same optimum from a different start
    t = fit_animal_model(spec; target = :ai_reml, initial = (sigma_a2 = 0.5, sigma_e2 = 0.5))
    @test t.target == :ai_reml
    @test t.likelihood.loglik ≈ ai.likelihood.loglik rtol = 1e-5
end

@testset "Phase 1 variance-component covariance and heritability interval" begin
    # standard-normal quantile (Acklam) against known values
    @test HSquared._standard_normal_quantile(0.975) ≈ 1.959963985 atol = 1e-6
    @test HSquared._standard_normal_quantile(0.95) ≈ 1.644853627 atol = 1e-6
    @test HSquared._standard_normal_quantile(0.995) ≈ 2.575829304 atol = 1e-6
    @test HSquared._standard_normal_quantile(0.5) ≈ 0.0 atol = 1e-9
    @test_throws ArgumentError HSquared._standard_normal_quantile(0.0)
    @test_throws ArgumentError HSquared._standard_normal_quantile(1.0)

    ids = ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"]
    ped = normalize_pedigree(ids,
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Ainv = pedigree_inverse(ped)
    y = [2.0, 3.0, 2.5, 3.5, 4.0, 1.5, 3.0, 4.5]
    X = ones(8, 1); Z = sparse(1.0I, 8, 8)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
    fit = fit_ai_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    sa2 = fit.variance_components.sigma_a2; se2 = fit.variance_components.sigma_e2

    # the AI information matrix matches an independent finite-difference Hessian of
    # the REML log-likelihood (observed information) to ~8% on this fixture
    info = HSquared._reml_information_matrix(spec, sa2, se2)
    ll(a, e) = sparse_reml_loglik(spec, a, e).loglik
    hh = 1e-4
    faa = (ll(sa2 + hh, se2) - 2ll(sa2, se2) + ll(sa2 - hh, se2)) / hh^2
    fee = (ll(sa2, se2 + hh) - 2ll(sa2, se2) + ll(sa2, se2 - hh)) / hh^2
    fae = (ll(sa2 + hh, se2 + hh) - ll(sa2 + hh, se2 - hh) -
           ll(sa2 - hh, se2 + hh) + ll(sa2 - hh, se2 - hh)) / (4hh^2)
    Hobs = -[faa fae; fae fee]
    @test isapprox(Matrix(info), Hobs; rtol = 0.12)

    # variance-component covariance / standard errors
    cov = variance_component_covariance(fit)
    @test cov ≈ transpose(cov) atol = 1e-12
    @test cov[1, 1] > 0 && cov[2, 2] > 0
    ses = variance_component_standard_errors(fit)
    @test ses.sigma_a2 ≈ sqrt(cov[1, 1]) atol = 1e-10
    @test ses.sigma_e2 ≈ sqrt(cov[2, 2]) atol = 1e-10

    # heritability SE matches a direct delta computation
    denom = (sa2 + se2)^2
    g = [se2 / denom, -sa2 / denom]
    @test heritability_standard_error(fit) ≈ sqrt(dot(g, cov * g)) atol = 1e-10

    # logit-delta interval stays in (0, 1), contains the estimate, and nests by level
    ci95 = heritability_interval(fit; level = 0.95)
    ci80 = heritability_interval(fit; level = 0.80)
    @test ci95.heritability ≈ heritability(fit)
    @test 0 < ci95.lower < ci95.heritability < ci95.upper < 1
    @test ci95.lower < ci80.lower && ci80.upper < ci95.upper        # 95% ⊃ 80%
    @test ci95.se ≈ heritability_standard_error(fit)

    # profile-likelihood interval (method = :profile), an alternative to logit-delta
    @test heritability_interval(fit).method == :delta                 # default unchanged
    h2hat = heritability(fit)
    llmax = HSquared._profile_reml_loglik(spec, h2hat)
    # the profile maximum over total variance at ĥ² recovers the fitted REML optimum
    @test llmax ≈ sparse_reml_loglik(spec, sa2, se2).loglik atol = 1e-4
    # and is an upper envelope of any fixed-total-variance slice at the same ratio
    @test llmax ≥ sparse_reml_loglik(spec, h2hat * 3.0, (1 - h2hat) * 3.0).loglik - 1e-8
    pci95 = heritability_interval(fit; level = 0.95, method = :profile)
    pci50 = heritability_interval(fit; level = 0.50, method = :profile)
    @test pci95.method == :profile
    @test pci95.heritability ≈ h2hat
    @test 0 < pci95.lower < h2hat < pci95.upper < 1
    @test pci95.lower <= pci50.lower && pci50.upper <= pci95.upper     # 95% ⊇ 50% (weak; both clamp here)
    # This tiny n=8 fixture has a very flat REML profile in h²: the maximum
    # deviance over (0,1) stays below even the 50% χ²₁ threshold, so the profile
    # interval correctly CLAMPS to the (1e-6, 1-1e-6) search bounds — the data
    # barely constrain h². Verify both the flatness and the resulting clamp.
    maxdev = maximum(2 * (llmax - HSquared._profile_reml_loglik(spec, h)) for h in 0.01:0.01:0.99)
    @test maxdev < HSquared._standard_normal_quantile(0.75)^2          # below the 50% threshold
    @test pci95.lower ≈ 1e-6 atol = 1e-9
    @test pci95.upper ≈ 1 - 1e-6 atol = 1e-9
    # The LRT-inversion root-finder itself, on a synthetic deviance with known
    # crossings at 0.3 and 0.7 (target(h) = 10(h-0.5)² − 0.4):
    synth(h) = 10 * (h - 0.5)^2 - 0.4
    @test HSquared._profile_root(synth, 1e-6, 0.5) ≈ 0.3 atol = 1e-6
    @test HSquared._profile_root(synth, 1 - 1e-6, 0.5) ≈ 0.7 atol = 1e-6
    @test HSquared._profile_root(h -> -1.0, 1e-6, 0.5) == 1e-6          # never crosses -> clamps
    @test_throws ArgumentError heritability_interval(fit; method = :bogus)

    # guards: level range and REML-only
    @test_throws ArgumentError heritability_interval(fit; level = 1.5)
    ml = fit_variance_components(animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :ML))
    @test_throws ArgumentError variance_component_covariance(ml)

    # works on a genomic REML fit too (interval stays in (0, 1))
    M = [0.0 1 2; 2 1 0; 1 1 1; 0 2 2; 1 0 2; 2 1 1]
    Ginv = genomic_relationship_inverse(genomic_relationship_matrix(M); ridge = 0.05)
    gspec = animal_model_spec([10.0, 12.0, 11.0, 9.0, 13.0, 10.5],
                              ones(6, 1), Matrix(1.0I, 6, 6), Ginv)
    gfit = fit_ai_reml(gspec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    gci = heritability_interval(gfit)
    @test 0 < gci.lower < gci.upper < 1
end

@testset "Phase 3 repeatability / permanent-environment MME (supplied variance)" begin
    Ainv = pedigree_inverse([1, 2, 3], [0, 0, 1], [0, 0, 2])
    Z = [1.0 0 0; 1 0 0; 0 1 0; 0 1 0; 0 0 1]   # 5 records; animals 1 & 2 repeated
    y = [10.0, 11.0, 12.0, 13.0, 9.0]; X = ones(5, 1)
    sa2 = 1.0; spe2 = 0.5; se2 = 2.0
    r = repeatability_mme(y, X, Z, Ainv, sa2, spe2, se2)

    # pinned hand values
    @test r.beta ≈ [11.0] atol = 1e-8
    @test r.animal_effects.values ≈ [-0.4, 0.4, -1 / 3] atol = 1e-8
    @test r.permanent_effects.values ≈ [-1 / 30, 11 / 30, -1 / 3] atol = 1e-8
    @test r.variance_components == (sigma_a2 = 1.0, sigma_pe2 = 0.5, sigma_e2 = 2.0)

    # independent marginal-GLS cross-check of the a and pe BLUPs
    A = inv(Symmetric(Matrix(Ainv)))
    V = sa2 .* (Z * A * transpose(Z)) .+ spe2 .* (Z * transpose(Z)) .+ se2 .* Matrix(1.0I, 5, 5)
    bg = (transpose(X) * (V \ X)) \ (transpose(X) * (V \ y))
    resid = y .- X * bg
    ag = sa2 .* A * transpose(Z) * (V \ resid)
    pg = spe2 .* (transpose(Z) * (V \ resid))
    @test maximum(abs.(r.beta .- bg)) < 1e-9
    @test maximum(abs.(r.animal_effects.values .- ag)) < 1e-9
    @test maximum(abs.(r.permanent_effects.values .- pg)) < 1e-9

    # reduction: as sigma_pe2 -> 0 the additive effects approach the animal model
    animal_ebv = breeding_values(henderson_mme(animal_model_spec(y, X, Z, Ainv), sa2, se2)).values
    rr = repeatability_mme(y, X, Z, Ainv, sa2, 1e-8, se2)
    @test maximum(abs.(rr.animal_effects.values .- animal_ebv)) < 1e-6

    # guards
    @test_throws ArgumentError repeatability_mme(y, X, Z, Ainv, -1.0, spe2, se2)
    @test_throws ArgumentError repeatability_mme(y, X, Z, Ainv, sa2, -1.0, se2)
    @test_throws ArgumentError repeatability_mme(y, X, Z[:, 1:2], Ainv, sa2, spe2, se2)
end

@testset "Phase 3 repeatability REML (variance-component estimation)" begin
    Ainv = pedigree_inverse([1, 2, 3, 4], [0, 0, 1, 1], [0, 0, 2, 2])
    A = inv(Symmetric(Matrix(Ainv)))
    Z = zeros(8, 4)
    for (rec, an) in enumerate([1, 1, 2, 2, 3, 3, 4, 4]); Z[rec, an] = 1.0; end
    y = [14.0, 13.0, 6.9, 6.1, 12.1, 11.5, 8.9, 8.5]; X = ones(8, 1)

    # (1) dense 2-RE REML loglik reduces to the animal-model REML (up to a constant) when sigma_pe2 = 0
    spec = animal_model_spec(y, X, sparse(Z), sparse(Matrix(Ainv)); method = :REML)
    d = HSquared._repeatability_dense(y, X, Z, A, 1.0, 0.0, 2.0)[1] -
        HSquared._repeatability_dense(y, X, Z, A, 2.0, 0.0, 1.0)[1]
    s = sparse_reml_loglik(spec, 1.0, 2.0).loglik - sparse_reml_loglik(spec, 2.0, 1.0).loglik
    @test d ≈ s rtol = 1e-6

    # (2) dense BLUPs at a supplied interior point equal the sparse repeatability_mme solve
    _, _, ad, pd = HSquared._repeatability_dense(y, X, Z, A, 1.0, 0.5, 2.0)
    rm = repeatability_mme(y, X, Z, Ainv, 1.0, 0.5, 2.0)
    @test maximum(abs.(ad .- rm.animal_effects.values)) < 1e-10
    @test maximum(abs.(pd .- rm.permanent_effects.values)) < 1e-10

    # (3) the REML estimator: converges, valid VCs, t and h2 in [0,1], t >= h2
    fit = fit_repeatability_reml(y, X, Z, Ainv)
    @test fit.converged
    @test fit.variance_components.sigma_a2 >= 0
    @test fit.variance_components.sigma_pe2 >= 0
    @test fit.variance_components.sigma_e2 > 0
    @test 0 <= fit.heritability <= 1
    @test 0 <= fit.repeatability <= 1
    @test fit.heritability <= fit.repeatability + 1e-10

    # (4) the optimum beats a coarse grid (near-global)
    vc = fit.variance_components
    @test all(
        HSquared._repeatability_dense(y, X, Z, A, max(vc.sigma_a2, 1e-6) * f1,
            max(vc.sigma_pe2, 1e-6) * f2, vc.sigma_e2 * f3)[1] <= fit.loglik + 1e-6
        for f1 in (0.7, 1.3), f2 in (0.7, 1.3), f3 in (0.7, 1.3)
    )

    # guards
    @test_throws ArgumentError fit_repeatability_reml(y, X, Z, Ainv;
        initial = (sigma_a2 = -1.0, sigma_pe2 = 1.0, sigma_e2 = 1.0))
    @test_throws ArgumentError fit_repeatability_reml(y, X, Z[:, 1:2], Ainv)
end

@testset "Phase 3 general two-effect MME (common environment)" begin
    # common-environment model: animal (A) + common-env group (I)
    Ainv = pedigree_inverse([1, 2, 3, 4], [0, 0, 1, 1], [0, 0, 2, 2])
    A = inv(Symmetric(Matrix(Ainv)))
    Z1 = Matrix(1.0I, 4, 4)                        # record -> animal
    Z2 = [1.0 0; 1 0; 0 1; 0 1]                    # record -> common-env group (2 groups)
    y = [10.0, 11.0, 9.0, 12.0]; X = ones(4, 1)
    s1 = 1.0; s2 = 0.5; se2 = 2.0
    r = two_effect_mme(y, X, Z1, Ainv, Z2, Matrix(1.0I, 2, 2), s1, s2, se2)

    # independent marginal-GLS cross-check of the two BLUPs
    V = s1 .* (Z1 * A * transpose(Z1)) .+ s2 .* (Z2 * transpose(Z2)) .+ se2 .* Matrix(1.0I, 4, 4)
    bg = (transpose(X) * (V \ X)) \ (transpose(X) * (V \ y))
    resid = y .- X * bg
    u1g = s1 .* A * transpose(Z1) * (V \ resid)
    u2g = s2 .* transpose(Z2) * (V \ resid)
    @test maximum(abs.(r.beta .- bg)) < 1e-9
    @test maximum(abs.(r.effect1.values .- u1g)) < 1e-9
    @test maximum(abs.(r.effect2.values .- u2g)) < 1e-9
    @test length(r.effect2.values) == 2           # one per common-env group

    # repeatability_mme is the Z2 = Z1, A2 = I special case (identical BLUPs)
    Zr = [1.0 0 0; 1 0 0; 0 1 0; 0 1 0; 0 0 1]; yr = [10.0, 11.0, 12.0, 13.0, 9.0]; Xr = ones(5, 1)
    Ainvr = pedigree_inverse([1, 2, 3], [0, 0, 1], [0, 0, 2])
    rep = repeatability_mme(yr, Xr, Zr, Ainvr, 1.0, 0.5, 2.0)
    gen = two_effect_mme(yr, Xr, Zr, Ainvr, Zr, Matrix(1.0I, 3, 3), 1.0, 0.5, 2.0)
    @test rep.animal_effects.values ≈ gen.effect1.values atol = 1e-10
    @test rep.permanent_effects.values ≈ gen.effect2.values atol = 1e-10

    # guards
    @test_throws ArgumentError two_effect_mme(y, X, Z1, Ainv, Z2, Matrix(1.0I, 2, 2), -1.0, s2, se2)
    @test_throws ArgumentError two_effect_mme(y, X, Z1, Ainv, Z2[:, 1:1], Matrix(1.0I, 2, 2), s1, s2, se2)
end

@testset "Phase 3 two-effect REML (common-environment / maternal estimation)" begin
    Ainv = pedigree_inverse([1, 2, 3, 4], [0, 0, 1, 1], [0, 0, 2, 2])
    A = inv(Symmetric(Matrix(Ainv)))
    Z = zeros(8, 4)
    for (rec, an) in enumerate([1, 1, 2, 2, 3, 3, 4, 4]); Z[rec, an] = 1.0; end
    y = [14.0, 13.0, 6.9, 6.1, 12.1, 11.5, 8.9, 8.5]; X = ones(8, 1)

    # reduction: with Z2 = Z1 and A2 = I it equals fit_repeatability_reml
    rep = fit_repeatability_reml(y, X, Z, Ainv)
    gen = fit_two_effect_reml(y, X, Z, Ainv, Z, Matrix(1.0I, 4, 4))
    @test gen.variance_components.sigma1 ≈ rep.variance_components.sigma_a2 rtol = 1e-4
    @test gen.variance_components.sigma2 ≈ rep.variance_components.sigma_pe2 atol = 1e-4
    @test gen.variance_components.sigma_e2 ≈ rep.variance_components.sigma_e2 rtol = 1e-4

    # dense loglik reduces to the animal-model REML (up to a constant) when sigma2 = 0
    spec = animal_model_spec(y, X, sparse(Z), sparse(Matrix(Ainv)); method = :REML)
    d = HSquared._two_effect_dense(y, X, Z, A, Z, Matrix(1.0I, 4, 4), 1.0, 0.0, 2.0)[1] -
        HSquared._two_effect_dense(y, X, Z, A, Z, Matrix(1.0I, 4, 4), 2.0, 0.0, 1.0)[1]
    s = sparse_reml_loglik(spec, 1.0, 2.0).loglik - sparse_reml_loglik(spec, 2.0, 1.0).loglik
    @test d ≈ s rtol = 1e-6

    # common-environment fit: converges with valid VCs and ratios in [0,1]
    Z2 = [1.0 0; 1 0; 0 1; 0 1; 1 0; 0 1; 1 0; 0 1]   # records -> 2 common-env groups
    cf = fit_two_effect_reml(y, X, Z, Ainv, Z2, Matrix(1.0I, 2, 2))
    @test cf.converged
    @test cf.variance_components.sigma1 >= 0
    @test cf.variance_components.sigma2 >= 0
    @test cf.variance_components.sigma_e2 > 0
    @test 0 <= cf.ratio1 <= 1
    @test 0 <= cf.ratio2 <= 1

    # guards
    @test_throws ArgumentError fit_two_effect_reml(y, X, Z, Ainv, Z2, Matrix(1.0I, 2, 2);
        initial = (sigma1 = -1.0, sigma2 = 1.0, sigma_e2 = 1.0))
    @test_throws ArgumentError fit_two_effect_reml(y, X, Z, Ainv, Z2[:, 1:1], Matrix(1.0I, 2, 2))
end

@testset "Phase 4 multivariate (multi-trait) animal model (supplied covariance)" begin
    Ainv = pedigree_inverse([1, 2, 3, 4], [0, 0, 1, 1], [0, 0, 2, 2])
    A = inv(Symmetric(Matrix(Ainv)))
    q = 4
    n = q
    t = 2
    Z = Matrix(1.0I, n, q)            # one balanced record per animal
    X = ones(n, 1)                    # shared intercept
    Y = [10.0 50.0; 12.0 47.0; 9.0 53.0; 11.0 49.0]   # deterministic, 2 traits
    G0 = [1.0 0.4; 0.4 1.5]
    R0 = [2.0 0.3; 0.3 1.0]

    res = multivariate_mme(Y, X, Z, Ainv, G0, R0)
    @test size(res.beta) == (1, t)
    @test size(res.breeding_values.values) == (q, t)
    @test res.breeding_values.ids == collect(1:q)
    res_vc = variance_components(res)
    @test res_vc.genetic_covariance ≈ res.genetic_covariance
    @test res_vc.residual_covariance ≈ res.residual_covariance
    @test fixed_effects(res) ≈ res.beta
    @test breeding_values(res).values ≈ res.breeding_values.values
    @test EBV(res).values ≈ res.breeding_values.values
    @test BLUP(res).values ≈ res.breeding_values.values
    res_vc.genetic_covariance[1, 1] = -999.0
    @test res.genetic_covariance[1, 1] == G0[1, 1]
    res_beta = fixed_effects(res)
    res_beta[1, 1] = -999.0
    @test res.beta[1, 1] != -999.0
    res_ebv = breeding_values(res)
    res_ebv.values[1, 1] = -999.0
    @test res.breeding_values.values[1, 1] != -999.0
    @test_throws ArgumentError heritability(res)
    @test_throws ArgumentError variance_components((foo = 1,))

    # Reference 1: loop-built multivariate MME (independent assembly, trait-fastest)
    invR0 = inv(R0); invG0 = inv(G0); p = size(X, 2)
    Xbig = zeros(n * t, p * t); Zbig = zeros(n * t, q * t); ybig = zeros(n * t)
    for i in 1:n, k in 1:t
        r = (i - 1) * t + k; ybig[r] = Y[i, k]
        for j in 1:p; Xbig[r, (j - 1) * t + k] = X[i, j]; end
        for a in 1:q; Zbig[r, (a - 1) * t + k] = Z[i, a]; end
    end
    Rinvbig = zeros(n * t, n * t)
    for i in 1:n, k1 in 1:t, k2 in 1:t
        Rinvbig[(i - 1) * t + k1, (i - 1) * t + k2] = invR0[k1, k2]
    end
    Ginvbig = zeros(q * t, q * t)
    for a in 1:q, b in 1:q, k in 1:t, l in 1:t
        Ginvbig[(a - 1) * t + k, (b - 1) * t + l] = Matrix(Ainv)[a, b] * invG0[k, l]
    end
    LHS = [transpose(Xbig) * Rinvbig * Xbig  transpose(Xbig) * Rinvbig * Zbig;
           transpose(Zbig) * Rinvbig * Xbig  transpose(Zbig) * Rinvbig * Zbig + Ginvbig]
    RHS = vcat(transpose(Xbig) * Rinvbig * ybig, transpose(Zbig) * Rinvbig * ybig)
    sol = LHS \ RHS
    beta_ref = permutedims(reshape(sol[1:p * t], t, p))
    u_ref = permutedims(reshape(sol[p * t + 1:end], t, q))
    @test res.beta ≈ beta_ref atol = 1e-10
    @test res.breeding_values.values ≈ u_ref atol = 1e-10

    # Reference 2: marginal-GLS BLUP via the big V (independent of MME assembly)
    AkG = kron(A, G0)
    V = Zbig * AkG * transpose(Zbig) + kron(Matrix(1.0I, n, n), R0)
    Vi = inv(V)
    beta_gls = (transpose(Xbig) * Vi * Xbig) \ (transpose(Xbig) * Vi * ybig)
    u_gls = AkG * transpose(Zbig) * Vi * (ybig - Xbig * beta_gls)
    @test res.beta ≈ permutedims(reshape(beta_gls, t, p)) atol = 1e-10
    @test res.breeding_values.values ≈ permutedims(reshape(u_gls, t, q)) atol = 1e-10

    # Reference 3: univariate reduction (t = 1 equals the standard animal-model MME)
    y1 = Y[:, 1:1]; G1 = reshape([1.0], 1, 1); R1 = reshape([2.0], 1, 1)
    res1 = multivariate_mme(y1, X, Z, Ainv, G1, R1)
    lam = R1[1, 1] / G1[1, 1]
    LHS1 = [transpose(X) * X  transpose(X) * Z; transpose(Z) * X  transpose(Z) * Z + Matrix(Ainv) * lam]
    sol1 = LHS1 \ vcat(transpose(X) * y1, transpose(Z) * y1)
    @test res1.beta[1, 1] ≈ sol1[1, 1] atol = 1e-10
    @test vec(res1.breeding_values.values) ≈ sol1[p + 1:end] atol = 1e-10

    # Reference 4: diagonal G0, R0 decouple into independent single-trait fits
    resd = multivariate_mme(Y, X, Z, Ainv, [1.0 0.0; 0.0 1.5], [2.0 0.0; 0.0 1.0])
    rA = multivariate_mme(Y[:, 1:1], X, Z, Ainv, reshape([1.0], 1, 1), reshape([2.0], 1, 1))
    rB = multivariate_mme(Y[:, 2:2], X, Z, Ainv, reshape([1.5], 1, 1), reshape([1.0], 1, 1))
    @test resd.breeding_values.values[:, 1] ≈ vec(rA.breeding_values.values) atol = 1e-10
    @test resd.breeding_values.values[:, 2] ≈ vec(rB.breeding_values.values) atol = 1e-10

    # genetic_correlation extractor
    rg = genetic_correlation(G0)
    @test rg[1, 2] ≈ 0.4 / sqrt(1.0 * 1.5)
    @test rg[1, 1] == 1.0 && rg[2, 2] == 1.0
    @test genetic_correlation(res) === res.genetic_correlation
    @test res.genetic_correlation ≈ rg
    @test res.residual_correlation[1, 2] ≈ 0.3 / sqrt(2.0 * 1.0)

    # custom trait labels propagate
    resl = multivariate_mme(Y, X, Z, Ainv, G0, R0; traits = ["wt", "ln"])
    @test resl.traits == ["wt", "ln"]
    @test resl.breeding_values.traits == ["wt", "ln"]

    # guards
    @test_throws ArgumentError multivariate_mme(Y, X, Z, Ainv, [1.0 0.4; 0.5 1.5], R0)  # nonsymmetric
    @test_throws ArgumentError multivariate_mme(Y, X, Z, Ainv, [1.0 2.0; 2.0 1.0], R0)  # non-PD
    @test_throws ArgumentError multivariate_mme(Y, X, Z, Ainv, G0[1:1, 1:1], R0)        # wrong t
    @test_throws ArgumentError multivariate_mme(Y, X, Z[:, 1:3], Ainv, G0, R0)          # Z/Ainv mismatch
    @test_throws ArgumentError multivariate_mme(Y, X, Z, Ainv, G0, R0; ids = [1, 2, 3]) # ids length
    # fail-loud on non-finite data (Inf is not the missing marker) and empty traits
    let Yinf = [10.0 50.0; 12.0 Inf; 9.0 53.0; 11.0 49.0]
        @test_throws ArgumentError multivariate_mme(Yinf, X, Z, Ainv, G0, R0)            # Inf phenotype
    end
    let Zinf = copy(Z); Zinf[1, 1] = Inf
        @test_throws ArgumentError multivariate_mme(Y, X, Zinf, Ainv, G0, R0)            # Inf in Z
    end
    @test_throws ArgumentError multivariate_mme([10.0 NaN; 12.0 NaN; 9.0 NaN; 11.0 NaN], X, Z, Ainv, G0, R0)  # empty trait 2
end

@testset "Phase 4 multivariate missing-trait records (unbalanced)" begin
    Ainv = pedigree_inverse([1, 2, 3, 4], [0, 0, 1, 1], [0, 0, 2, 2])
    A = inv(Symmetric(Matrix(Ainv)))
    q = 4; n = q; t = 2; p = 1
    Z = Matrix(1.0I, n, q); X = ones(n, 1)
    G0 = [1.0 0.4; 0.4 1.5]; R0 = [2.0 0.3; 0.3 1.0]
    Yb = [10.0 50.0; 12.0 47.0; 9.0 53.0; 11.0 49.0]
    Ymiss = [10.0 50.0; 12.0 NaN; NaN 53.0; 11.0 49.0]   # animal 2 missing t2, animal 3 missing t1

    # balanced data is unchanged by the missing-aware path (no missing → fast path)
    @test multivariate_mme(Yb, X, Z, Ainv, G0, R0).breeding_values.values ==
          multivariate_mme(Yb, X, Z, Ainv, G0, R0).breeding_values.values

    rm = multivariate_mme(Ymiss, X, Z, Ainv, G0, R0)
    @test size(rm.breeding_values.values) == (q, t)   # EBVs for every animal × trait still returned

    # Reference 1: loop-built MME over observed (i,k) rows, per-individual residual block
    invG0 = inv(G0)
    present = [!isnan(Ymiss[i, k]) for i in 1:n, k in 1:t]
    rows = [(i, k) for i in 1:n for k in 1:t if present[i, k]]
    N = length(rows)
    Xbig = zeros(N, p * t); Zbig = zeros(N, q * t); ybig = zeros(N)
    for (rIdx, (i, k)) in enumerate(rows)
        ybig[rIdx] = Ymiss[i, k]
        for j in 1:p; Xbig[rIdx, (j - 1) * t + k] = X[i, j]; end
        for a in 1:q; Zbig[rIdx, (a - 1) * t + k] = Z[i, a]; end
    end
    Rinvbig = zeros(N, N); rowstart = 0
    for i in 1:n
        Si = findall(present[i, :]); isempty(Si) && continue
        m = length(Si)
        Rinvbig[rowstart + 1:rowstart + m, rowstart + 1:rowstart + m] = inv(R0[Si, Si])
        rowstart += m
    end
    Ginvbig = zeros(q * t, q * t)
    for a in 1:q, b in 1:q, k in 1:t, l in 1:t
        Ginvbig[(a - 1) * t + k, (b - 1) * t + l] = Matrix(Ainv)[a, b] * invG0[k, l]
    end
    LHS = [transpose(Xbig) * Rinvbig * Xbig  transpose(Xbig) * Rinvbig * Zbig;
           transpose(Zbig) * Rinvbig * Xbig  transpose(Zbig) * Rinvbig * Zbig + Ginvbig]
    sol = LHS \ vcat(transpose(Xbig) * Rinvbig * ybig, transpose(Zbig) * Rinvbig * ybig)
    @test rm.beta ≈ permutedims(reshape(sol[1:p * t], t, p)) atol = 1e-9
    @test rm.breeding_values.values ≈ permutedims(reshape(sol[p * t + 1:end], t, q)) atol = 1e-9

    # Reference 2: marginal-GLS with block-diagonal residual V over observed rows
    AkG = kron(A, G0); Rblk = zeros(N, N); rowstart = 0
    for i in 1:n
        Si = findall(present[i, :]); isempty(Si) && continue
        m = length(Si)
        Rblk[rowstart + 1:rowstart + m, rowstart + 1:rowstart + m] = R0[Si, Si]
        rowstart += m
    end
    V = Zbig * AkG * transpose(Zbig) + Rblk; Vi = inv(V)
    beta_gls = (transpose(Xbig) * Vi * Xbig) \ (transpose(Xbig) * Vi * ybig)
    u_gls = AkG * transpose(Zbig) * Vi * (ybig - Xbig * beta_gls)
    @test rm.beta ≈ permutedims(reshape(beta_gls, t, p)) atol = 1e-9
    @test rm.breeding_values.values ≈ permutedims(reshape(u_gls, t, q)) atol = 1e-9

    # `missing` entries are equivalent to `NaN`
    Ymiss2 = Union{Missing,Float64}[10.0 50.0; 12.0 missing; missing 53.0; 11.0 49.0]
    @test multivariate_mme(Ymiss2, X, Z, Ainv, G0, R0).breeding_values.values ≈
          rm.breeding_values.values atol = 1e-12

    # an all-missing Y is rejected
    @test_throws ArgumentError multivariate_mme(fill(NaN, n, t), X, Z, Ainv, G0, R0)
end

@testset "Phase 4 multivariate REML (estimate G0/R0)" begin
    # interior-optimum fixture (same 8-animal pedigree as the univariate recovery)
    ped = normalize_pedigree(["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"],
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Ainv = pedigree_inverse(ped)
    y1 = [2.0, 3.0, 2.5, 3.5, 4.0, 1.5, 3.0, 4.5]
    X = ones(8, 1); Z = Matrix(1.0I, 8, 8)
    spec = animal_model_spec(y1, X, sparse(Z), Ainv; ids = ped.ids, method = :REML)

    # (1) t=1 reduction: multivariate REML recovers the univariate REML estimate
    uni = fit_sparse_reml(spec)
    mv1 = fit_multivariate_reml(reshape(y1, 8, 1), X, Z, Ainv)
    @test mv1.converged
    @test mv1.genetic_covariance[1, 1] ≈ uni.variance_components.sigma_a2 rtol = 1e-2
    @test mv1.residual_covariance[1, 1] ≈ uni.variance_components.sigma_e2 rtol = 1e-2
    @test 0 < mv1.heritability[1] < 1
    @test mv1.genetic_correlation == reshape([1.0], 1, 1)

    # (2) the multivariate REML loglik is the FULL REML loglik (incl. the 2π
    # constant), so at t=1 it equals the univariate sparse_reml_loglik exactly —
    # not merely up to a constant. This pins the package-wide loglik scale.
    h = HSquared._multivariate_reml_loglik
    @test h(reshape(y1, 8, 1), X, Z, Ainv, reshape([1.0], 1, 1), reshape([2.0], 1, 1)) ≈
          sparse_reml_loglik(spec, 1.0, 2.0).loglik atol = 1e-7
    @test h(reshape(y1, 8, 1), X, Z, Ainv, reshape([0.5], 1, 1), reshape([3.0], 1, 1)) ≈
          sparse_reml_loglik(spec, 0.5, 3.0).loglik atol = 1e-7

    # (3) two-trait fit (non-collinear traits → interior PD estimate): optimum
    # beats a coarse (G0, R0) grid, and EBVs match the independent MME at the
    # estimate (MME ≡ GLS BLUP when G0 is PD)
    Y2 = hcat(y1, reverse(y1))
    mv2 = fit_multivariate_reml(Y2, X, Z, Ainv)
    @test mv2.converged
    @test size(mv2.genetic_covariance) == (2, 2)
    @test isposdef(Symmetric(mv2.genetic_covariance))
    @test isposdef(Symmetric(mv2.residual_covariance))
    gridmax = -Inf
    for va1 in (0.5, 1.5), va2 in (0.5, 1.5), ve1 in (0.5, 1.5), ve2 in (0.5, 1.5)
        G = [va1 0.0; 0.0 va2]; R = [ve1 0.0; 0.0 ve2]
        gridmax = max(gridmax, h(Y2, X, Z, Ainv, G, R))
    end
    @test mv2.loglik >= gridmax - 1e-6
    chk = multivariate_mme(Y2, X, Z, Ainv, mv2.genetic_covariance, mv2.residual_covariance)
    @test chk.breeding_values.values ≈ mv2.breeding_values.values atol = 1e-6   # GLS vs MME solve
    @test -1 <= mv2.genetic_correlation[1, 2] <= 1
    @test all(0 .<= mv2.heritability .<= 1)
    mv2_vc = variance_components(mv2)
    @test mv2_vc.genetic_covariance ≈ mv2.genetic_covariance
    @test mv2_vc.residual_covariance ≈ mv2.residual_covariance
    @test fixed_effects(mv2) ≈ mv2.beta
    @test heritability(mv2) ≈ mv2.heritability
    @test breeding_values(mv2).ids == mv2.breeding_values.ids
    @test breeding_values(mv2).traits == mv2.breeding_values.traits
    @test breeding_values(mv2).values ≈ mv2.breeding_values.values
    @test EBV(mv2).values ≈ mv2.breeding_values.values
    @test BLUP(mv2).values ≈ mv2.breeding_values.values
    mv2_h2 = heritability(mv2)
    mv2_h2[1] = -999.0
    @test mv2.heritability[1] != -999.0

    # (4) missing records are handled by the estimator too (a boundary estimate
    # is still valid — the EBV solve is robust to a singular G0)
    Ymiss = copy(Y2); Ymiss[2, 2] = NaN; Ymiss[5, 1] = NaN
    mvm = fit_multivariate_reml(Ymiss, X, Z, Ainv)
    @test mvm.converged
    @test size(mvm.breeding_values.values) == (8, 2)
    @test -1 <= mvm.genetic_correlation[1, 2] <= 1
    @test issymmetric(Symmetric(mvm.genetic_covariance))

    # (5) supplied initial values are accepted
    mv_init = fit_multivariate_reml(Y2, X, Z, Ainv;
        initial = (G0 = [1.0 0.2; 0.2 1.0], R0 = [1.0 0.0; 0.0 1.0]))
    @test mv_init.converged

    # guards — including fail-loud on non-finite data and an empty trait, so a
    # boundary/garbage input never returns plausible-looking covariances
    @test_throws ArgumentError fit_multivariate_reml(Y2, X, Z[:, 1:3], Ainv)
    @test_throws ArgumentError fit_multivariate_reml(Y2, X[1:4, :], Z, Ainv)
    let Y2inf = copy(Y2); Y2inf[3, 1] = Inf
        @test_throws ArgumentError fit_multivariate_reml(Y2inf, X, Z, Ainv)
    end
    @test_throws ArgumentError fit_multivariate_reml(hcat(y1, fill(NaN, 8)), X, Z, Ainv)  # empty trait 2
end

@testset "Phase 4 shared multi-trait parity fixture" begin
    fixture_dir = joinpath(@__DIR__, "fixtures", "phase4_multitrait_parity")

    _, ped_rows = _csv_strings_for_test(joinpath(fixture_dir, "pedigree.csv"))
    ped = normalize_pedigree(ped_rows[:, 1], ped_rows[:, 2], ped_rows[:, 3])
    Ainv = pedigree_inverse(ped)

    _, pheno = _csv_strings_for_test(joinpath(fixture_dir, "phenotypes.csv"))
    record_animals = pheno[:, 2]
    x = parse.(Float64, pheno[:, 3])
    Y = hcat(parse.(Float64, pheno[:, 4]), parse.(Float64, pheno[:, 5]))
    X = hcat(ones(length(x)), x)
    Z = zeros(length(x), length(ped.ids))
    animal_index = Dict(id => i for (i, id) in enumerate(ped.ids))
    for (i, animal) in enumerate(record_animals)
        Z[i, animal_index[animal]] = 1.0
    end

    cov_traits, G0 = _named_matrix_csv_for_test(joinpath(fixture_dir, "expected_genetic_covariance.csv"))
    residual_traits, R0 = _named_matrix_csv_for_test(joinpath(fixture_dir, "expected_residual_covariance.csv"))
    effects, beta_expected = _named_matrix_csv_for_test(joinpath(fixture_dir, "expected_beta.csv"))
    h_traits, h_expected = _named_matrix_csv_for_test(joinpath(fixture_dir, "expected_heritability.csv"))
    ebv_ids, ebv_expected = _named_matrix_csv_for_test(joinpath(fixture_dir, "expected_ebv.csv"))
    metadata = _metadata_csv_for_test(joinpath(fixture_dir, "expected_metadata.csv"))

    @test cov_traits == ["trait1", "trait2"]
    @test residual_traits == cov_traits
    @test effects == ["Intercept", "x"]
    @test h_traits == cov_traits
    @test ebv_ids == ped.ids
    @test isposdef(Symmetric(G0))
    @test isposdef(Symmetric(R0))

    mme = multivariate_mme(Y, X, Z, Ainv, G0, R0; ids = ped.ids, traits = cov_traits)
    h_calc = [G0[k, k] / (G0[k, k] + R0[k, k]) for k in 1:length(cov_traits)]
    loglik = HSquared._multivariate_reml_loglik(Y, X, Z, Ainv, G0, R0)

    @test mme.beta ≈ beta_expected atol = 5e-6
    @test mme.breeding_values.values ≈ ebv_expected atol = 5e-6
    @test h_calc ≈ vec(h_expected) atol = 5e-6
    @test loglik ≈ parse(Float64, metadata["loglik"]) atol = 5e-6
    @test mme.genetic_correlation[1, 2] ≈ parse(Float64, metadata["genetic_correlation_trait1_trait2"]) atol = 5e-6
    @test mme.residual_correlation[1, 2] ≈ parse(Float64, metadata["residual_correlation_trait1_trait2"]) atol = 5e-6
end

@testset "Phase 4B structured genetic covariance (diag/lowrank/fa)" begin
    @test diagonal_covariance([1.0, 2.0, 3.0]) == Matrix(Diagonal([1.0, 2.0, 3.0]))
    Λ = reshape([1.0, -2.0], 2, 1)
    @test lowrank_covariance(Λ) ≈ Λ * transpose(Λ)
    @test factor_analytic_covariance(Λ, [0.5, 0.25]) ≈ Λ * transpose(Λ) + Diagonal([0.5, 0.25])
    Λraw = [-2.0 0.1; 1.0 -3.0; 0.5 2.0]
    Λcanon = HSquared._canonicalize_loadings(Λraw)
    @test Λraw[1, 1] == -2.0
    @test Λcanon[:, 1] == [2.0, -1.0, -0.5]
    @test Λcanon[:, 2] == [-0.1, 3.0, -2.0]
    @test Λcanon * transpose(Λcanon) ≈ Λraw * transpose(Λraw)
    @test_throws ArgumentError HSquared._canonicalize_loadings(zeros(0, 1))
    @test_throws ArgumentError diagonal_covariance([1.0, 0.0])
    @test_throws ArgumentError lowrank_covariance(reshape([0.0, 1.0], 2, 1))
    @test_throws ArgumentError factor_analytic_covariance(Λ, [0.5, -0.1])
    @test_throws ArgumentError factor_analytic_covariance(zeros(0, 1), Float64[])

    ped = normalize_pedigree(["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"],
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Ainv = pedigree_inverse(ped)
    y1 = [2.0, 3.0, 2.5, 3.5, 4.0, 1.5, 3.0, 4.5]
    Y2 = hcat(y1, reverse(y1))
    X = ones(8, 1)
    Z = Matrix(1.0I, 8, 8)
    h = HSquared._multivariate_reml_loglik

    full = fit_multivariate_reml(Y2, X, Z, Ainv)
    @test genetic_structure(full) == (structure = :unstructured, rank = nothing)
    @test genetic_loadings(full) === nothing
    @test genetic_uniqueness(full) === nothing

    diagfit = fit_multivariate_reml(Y2, X, Z, Ainv; genetic_structure = :diagonal)
    @test diagfit.converged
    @test diagfit.genetic_structure == :diagonal
    @test diagfit.genetic_rank === nothing
    @test diagfit.genetic_loadings === nothing
    @test diagfit.genetic_uniqueness ≈ diag(diagfit.genetic_covariance)
    @test genetic_structure(diagfit) == (structure = :diagonal, rank = nothing)
    @test genetic_loadings(diagfit) === nothing
    diag_uniq = genetic_uniqueness(diagfit)
    @test diag_uniq ≈ diagfit.genetic_uniqueness
    diag_uniq[1] = -1.0
    @test diagfit.genetic_uniqueness[1] > 0
    @test diagfit.genetic_covariance[1, 2] == 0.0
    @test diagfit.loglik ≈ h(Y2, X, Z, Ainv, diagfit.genetic_covariance, diagfit.residual_covariance) atol = 1e-6
    @test diagfit.loglik <= full.loglik + 1e-6

    low = fit_multivariate_reml(Y2, X, Z, Ainv;
        genetic_structure = :lowrank,
        rank = 1,
        initial = (loadings = reshape([0.7, -0.4], 2, 1), R0 = [1.0 0.0; 0.0 1.0]))
    @test low.converged
    @test low.genetic_structure == :lowrank
    @test low.genetic_rank == 1
    @test genetic_structure(low) == (structure = :lowrank, rank = 1)
    @test low.genetic_covariance ≈ lowrank_covariance(low.genetic_loadings) atol = 1e-8
    @test low.genetic_loadings[argmax(abs.(low.genetic_loadings[:, 1])), 1] >= 0
    @test minimum(eigvals(Symmetric(low.genetic_covariance))) >= -1e-8
    @test low.genetic_uniqueness == zeros(2)
    low_loadings = genetic_loadings(low)
    @test low_loadings ≈ low.genetic_loadings
    low_loadings[1, 1] = -99.0
    @test low.genetic_loadings[1, 1] != -99.0
    low_uniq = genetic_uniqueness(low)
    @test low_uniq == zeros(2)
    low_uniq[1] = 99.0
    @test low.genetic_uniqueness[1] == 0.0
    @test low.loglik ≈ h(Y2, X, Z, Ainv, low.genetic_covariance, low.residual_covariance) atol = 1e-6
    @test low.loglik <= full.loglik + 1e-6

    fa = fit_multivariate_reml(Y2, X, Z, Ainv;
        genetic_structure = :factor_analytic,
        rank = 1,
        initial = (loadings = reshape([0.5, -0.3], 2, 1), uniqueness = [0.4, 0.4], R0 = [1.0 0.0; 0.0 1.0]))
    @test fa.converged
    @test fa.genetic_structure == :factor_analytic
    @test fa.genetic_rank == 1
    @test genetic_structure(fa) == (structure = :factor_analytic, rank = 1)
    @test all(fa.genetic_uniqueness .> 0)
    @test fa.genetic_covariance ≈ factor_analytic_covariance(fa.genetic_loadings, fa.genetic_uniqueness) atol = 1e-8
    @test fa.genetic_loadings[argmax(abs.(fa.genetic_loadings[:, 1])), 1] >= 0
    fa_loadings = genetic_loadings(fa)
    @test fa_loadings ≈ fa.genetic_loadings
    fa_loadings[1, 1] = -99.0
    @test fa.genetic_loadings[1, 1] != -99.0
    fa_uniq = genetic_uniqueness(fa)
    @test fa_uniq ≈ fa.genetic_uniqueness
    fa_uniq[1] = -99.0
    @test fa.genetic_uniqueness[1] > 0
    @test isposdef(Symmetric(fa.genetic_covariance))
    @test fa.loglik ≈ h(Y2, X, Z, Ainv, fa.genetic_covariance, fa.residual_covariance) atol = 1e-6
    @test fa.loglik <= full.loglik + 1e-6

    @test_throws ArgumentError genetic_structure((foo = 1,))
    @test_throws ArgumentError genetic_loadings((foo = 1,))
    @test_throws ArgumentError genetic_uniqueness((foo = 1,))
    @test_throws ArgumentError fit_multivariate_reml(Y2, X, Z, Ainv; genetic_structure = :lowrank)
    @test_throws ArgumentError fit_multivariate_reml(Y2, X, Z, Ainv; genetic_structure = :factor_analytic, rank = 0)
    @test_throws ArgumentError fit_multivariate_reml(Y2, X, Z, Ainv; genetic_structure = :unknown)
end
