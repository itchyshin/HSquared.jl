using HSquared
using LinearAlgebra
using SparseArrays
using Test

function _dense_relationship_for_test(pedigree)
    n = length(pedigree)
    A = zeros(Float64, n, n)

    for i in 1:n
        sire = pedigree.sire[i]
        dam = pedigree.dam[i]

        for j in 1:(i - 1)
            value = 0.0
            sire == 0 || (value += 0.5 * A[sire, j])
            dam == 0 || (value += 0.5 * A[dam, j])
            A[i, j] = value
            A[j, i] = value
        end

        A[i, i] = sire != 0 && dam != 0 ? 1.0 + 0.5 * A[sire, dam] : 1.0
    end

    return A
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
    @test length(validation) == 13
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
    @test fitted_mrode_row.status == "planned"
    @test occursin("Fitted Mrode validation is not covered", fitted_mrode_row.claim_boundary)
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
    @test Matrix(pedigree_inverse(inbred)) ≈ inv(_dense_relationship_for_test(inbred))

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
    @test isapprox(Matrix(Ainv), inv(Symmetric(_dense_relationship_for_test(ped))))

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
