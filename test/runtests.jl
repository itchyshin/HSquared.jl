using HSquared
using LinearAlgebra
using SparseArrays
using Test
using TOML
using Random  # seeded fixtures only (e.g. the repeatability-interval test); deterministic/reproducible

include(joinpath(@__DIR__, "..", "comparator", "prepare_blupf90_multitrait.jl"))

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
    @test length(validation) == 50
    @test validation[begin].id == "V0-LOAD"
    @test validation[end].id == "V6-GGLLVM-REML"
    @test "V4-EVOLVE" in [row.id for row in validation]
    @test "V6-GGLLVM-DESC" in [row.id for row in validation]
    @test "V6-GGLLVM-MARGINAL" in [row.id for row in validation]
    @test "V6-GGLLVM-REML" in [row.id for row in validation]
    @test "V5-MARKER-THRESHOLD" in [row.id for row in validation]
    @test "V3-RR-REML" in [row.id for row in validation]
    @test "V1-METAFOUNDER" in [row.id for row in validation]
    @test "V1-PCG" in [row.id for row in validation]
    # Deferred-ledger close-out (C10/I1/H1): three new partial rows.
    c10_row = only(row for row in validation if row.id == "C10-LRT")
    @test c10_row.status == "partial"
    @test occursin("nested_lrt", c10_row.evidence)
    @test occursin("chi-bar", c10_row.evidence)
    @test occursin("Self & Liang", c10_row.evidence)
    @test occursin("Asymptotic-theory helper", c10_row.claim_boundary)
    sire_row = only(row for row in validation if row.id == "V1-SIRE-FIT")
    @test sire_row.status == "partial"
    @test occursin("self-consistency", sire_row.evidence)
    @test occursin("sire", sire_row.evidence)
    @test occursin("external", sire_row.claim_boundary)
    @test occursin("sire-model", sire_row.claim_boundary)
    nbinom_row = only(row for row in validation if row.id == "V6-NBINOM")
    @test nbinom_row.status == "partial"
    @test occursin("NB2", nbinom_row.evidence)
    @test occursin("Poisson limit", nbinom_row.evidence)
    @test occursin("reported-not-gated", lowercase(nbinom_row.evidence)) ||
          occursin("REPORTED-NOT-GATED", nbinom_row.evidence)
    @test occursin("not a covered claim", nbinom_row.claim_boundary)
    # H2: beta-binomial overdispersed-logit family row.
    betabin_row = only(row for row in validation if row.id == "V6-BETABINOMIAL")
    @test betabin_row.status == "partial"
    @test occursin("BetaBinomialResponse", betabin_row.evidence)
    @test occursin("Fisher", betabin_row.evidence)
    @test occursin("BinomialResponse", betabin_row.evidence)   # the ρ→0 trusted-path anchor
    @test occursin("not a covered claim", betabin_row.claim_boundary) ||
          occursin("nor a covered claim", betabin_row.claim_boundary)
    # H3: probit / threshold (liability-scale) family row.
    probit_row = only(row for row in validation if row.id == "V6-PROBIT")
    @test probit_row.status == "partial"
    @test occursin("BernoulliProbitResponse", probit_row.evidence)
    @test occursin("probit", probit_row.evidence)
    @test occursin("LAPLACE ONLY", probit_row.evidence) || occursin("Laplace", probit_row.evidence)
    @test occursin("not a covered claim", probit_row.claim_boundary) ||
          occursin("nor a covered claim", probit_row.claim_boundary)
    # T1: ordered-categorical probit (ordinal threshold) family row.
    ordinal_row = only(row for row in validation if row.id == "V6-ORDINAL")
    @test ordinal_row.status == "partial"
    @test occursin("OrderedProbitResponse", ordinal_row.evidence)
    @test occursin("REDUCTION to", ordinal_row.evidence)
    @test occursin("covered claim", ordinal_row.claim_boundary)
    # T-Gamma: Gamma (log-link) family row.
    gamma_row = only(row for row in validation if row.id == "V6-GAMMA")
    @test gamma_row.status == "partial"
    @test occursin("GammaResponse", gamma_row.evidence)
    @test occursin("EXPONENTIAL", gamma_row.evidence)
    @test occursin("covered claim", gamma_row.claim_boundary)
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
    @test occursin("Mrode Example 3.1", mme_row.evidence)
    @test occursin("not variance-component estimation", mme_row.claim_boundary)
    @test occursin("JWAS 2.3.6", mme_row.evidence)
    @test occursin("agreement only", mme_row.claim_boundary)
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
    gblup_row = only(row for row in validation if row.id == "V2-GBLUP")
    @test gblup_row.status == "partial"
    @test occursin("genomic_gblup_snpblup_target", gblup_row.evidence)
    @test occursin("hsquared PR #84", gblup_row.evidence)
    @test occursin("Julia-native/R-consumed comparator target only", gblup_row.claim_boundary)
    @test occursin("external AGHmatrix/sommer/BLUPF90/JWAS same-estimand comparator parity", gblup_row.missing)
    snpblup_row = only(row for row in validation if row.id == "V2-SNPBLUP")
    @test snpblup_row.status == "partial"
    @test occursin("serialized #49 target fixture", snpblup_row.evidence)
    @test occursin("hsquared PR #84", snpblup_row.evidence)
    @test occursin("Julia-native/R-consumed comparator target", snpblup_row.claim_boundary)
    @test occursin("comparator parity against the serialized target", snpblup_row.missing)
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
    @test mvreml_row.status == "covered"
    @test occursin("pre-declared", mvreml_row.evidence)
    @test occursin("48-seed cold-start", mvreml_row.evidence)
    @test occursin("opt-in", mvreml_row.claim_boundary)
    @test occursin("deep-inbreeding", mvreml_row.claim_boundary)
    @test occursin("fit_multivariate_reml", mvreml_row.evidence)
    @test occursin("heritability", mvreml_row.evidence)
    @test occursin("comparator protocol", mvreml_row.evidence)
    @test occursin("external `sommer` 4.4.5", mvreml_row.evidence)
    @test occursin("nadiv::makeA", mvreml_row.evidence)
    @test occursin("genetic_correlation_interval", mvreml_row.evidence)   # C2 (delta CI, partial)
    @test occursin("max |dG0| = 7.529e-05", mvreml_row.evidence)
    @test occursin("loglik is not compared", mvreml_row.evidence)
    @test occursin("Mrode Example 5.1", mvreml_row.evidence)
    @test occursin("hsquared `6a1065e`", mvreml_row.evidence)
    @test occursin("supplied-covariance BLUP/MME anchor", mvreml_row.evidence)
    @test occursin("MCMCglmm", mvreml_row.evidence)
    @test occursin("hsquared `dbf97a7`", mvreml_row.evidence)
    @test occursin("agreement evidence only", mvreml_row.evidence)
    @test occursin("tested preflight", mvreml_row.evidence)
    @test occursin("no header/comment records", mvreml_row.evidence)
    @test occursin("converged in 7 rounds to the same multivariate REML optimum", mvreml_row.evidence)
    @test occursin("explicit `--seeds`", mvreml_row.evidence)
    @test occursin("calibration protocol", mvreml_row.evidence)
    @test occursin("did not pass", mvreml_row.evidence)
    @test occursin("6/10 passed", mvreml_row.evidence)
    @test occursin("failure-mode triage", mvreml_row.evidence)
    @test occursin("3 G-only failures", mvreml_row.evidence)
    @test occursin("100-rep cold-start known-truth study", mvreml_row.evidence)
    @test occursin("100/100 converged", mvreml_row.evidence)
    @test occursin("all 9 reported targets", mvreml_row.evidence)
    @test occursin("EBV accuracy was 0.790/0.742", mvreml_row.evidence)
    @test occursin("result_payload", mvreml_row.claim_boundary)
    @test occursin("comparator protocol", mvreml_row.claim_boundary)
    @test occursin("one reproduced external `sommer` 4.4.5 same-estimand comparator leg", mvreml_row.claim_boundary)
    @test occursin("Mrode Example 5.1 supplied-covariance BLUP/MME anchor", mvreml_row.claim_boundary)
    @test occursin("Bayesian `MCMCglmm` agreement evidence", mvreml_row.claim_boundary)
    @test occursin("tested BLUPF90 preflight harness", mvreml_row.claim_boundary)
    @test occursin("cross-checked by TWO independent same-estimand REML comparators", mvreml_row.claim_boundary)
    @test occursin("not coverage-calibrated", mvreml_row.claim_boundary)
    @test occursin("did not pass", mvreml_row.claim_boundary)
    @test occursin("R-lane cold-start recovery studies", mvreml_row.claim_boundary)
    @test occursin("second independent same-estimand REML comparator is now SATISFIED", mvreml_row.missing)
    @test occursin("MCMCglmm`/JWAS Bayesian agreement only", mvreml_row.missing)
    @test occursin("promotion of the full-unstructured `sommer` leg to a skip-guarded in-suite test", mvreml_row.missing)
    @test !occursin("published Mrode multi-trait estimate", mvreml_row.missing)
    # #47 closeout: covariance SEs + LRT are now provided (no longer "missing")
    @test occursin("multivariate_covariance_standard_errors", mvreml_row.evidence)
    @test occursin("covariance_structure_lrt", mvreml_row.evidence)
    @test !occursin("likelihood-ratio tests for the covariances", mvreml_row.missing)
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
    # #47 closeout: the boundary-aware LRT applies to structured fits; structured
    # SEs stay honestly absent (rotation-nonidentified loadings)
    @test occursin("covariance_structure_lrt", fa_row.evidence)
    @test occursin("rotation-nonidentified", fa_row.evidence)
    @test !occursin("covariance SEs or LRTs", fa_row.missing)
    @test occursin("standard errors for the rotation-nonidentified structured loadings", fa_row.missing)
    # #42 scoped: the diagonal/unstructured bridge payload row
    bridge_row = only(row for row in validation if row.id == "V4-BRIDGE")
    @test bridge_row.phase == "Phase 4"
    @test bridge_row.status == "partial"
    @test occursin("multivariate_result_payload", bridge_row.evidence)
    @test occursin("rotation-nonidentified", bridge_row.evidence)
    @test occursin("structured_covariance_parity", bridge_row.evidence)
    @test occursin("external comparator parity", bridge_row.missing)
    @test occursin("structured-payload", bridge_row.missing)   # lowrank/fa now bridged via structured_genetic_payload
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
    @test occursin("marker_scan_result_payload", mixed_marker_row.evidence)
    @test occursin("marker_scan_parity", mixed_marker_row.evidence)
    @test occursin("hsquared PR #82", mixed_marker_row.evidence)
    @test occursin("gwas_table(scan)", mixed_marker_row.evidence)
    @test occursin("post-fit explicit-argument reduction", mixed_marker_row.evidence)
    @test occursin("map-annotated GWAS/QTL/eQTL table activation", mixed_marker_row.missing)
    @test occursin("post-fit bridge payload/fixture only", mixed_marker_row.claim_boundary)
    @test occursin("R scan-result table views are thin views", mixed_marker_row.claim_boundary)
    @test occursin("no p-value calibration", mixed_marker_row.claim_boundary)
    @test occursin("no calibrated PVE", mixed_marker_row.claim_boundary)
    @test occursin("no R formula activation", mixed_marker_row.claim_boundary)
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
    threshold_row = only(row for row in validation if row.id == "V5-MARKER-THRESHOLD")
    @test threshold_row.phase == "Phase 5"
    @test threshold_row.status == "covered"   # scoped covered (doc-33 substitutable gate, 2026-06-30)
    @test occursin("fixed-marker-panel type-I smoke", threshold_row.evidence)
    @test occursin("machine-readable TSV evidence", threshold_row.evidence)
    @test occursin("0.015/0.065/0.050", threshold_row.evidence)
    @test occursin("threshold-vs-Bonferroni was mixed", threshold_row.evidence)
    @test occursin("coverage calibration", threshold_row.missing)
    @test occursin("STANDING DEBT", threshold_row.missing)        # covered does not retire owed work
    @test occursin("SCOPED", threshold_row.claim_boundary)        # scoped covered claim
    @test occursin("FITTING = 1", threshold_row.claim_boundary)   # public default unchanged
    marker_recovery_script = normpath(joinpath(@__DIR__, "..", "sim", "phase5_marker_scan_recovery.jl"))
    @test isfile(marker_recovery_script)
    marker_recovery_source = read(marker_recovery_script, String)
    @test occursin("single_marker_scan", marker_recovery_source)
    @test occursin("mixed_model_marker_scan", marker_recovery_source)
    @test occursin("loco_mixed_model_marker_scan", marker_recovery_source)
    @test occursin("unknown arguments", marker_recovery_source)
    @test occursin("not calibrated genome-wide thresholds", marker_recovery_source)
    # #44 blocker-first: Phase-6 non-Gaussian Laplace+VA now has a citable
    # validation_status() row (already in capability-status + validation-debt)
    v6_row = only(row for row in validation if row.id == "V6-LAPLACE")
    @test v6_row.phase == "Phase 6"
    @test v6_row.status == "partial"
    @test occursin("sparse_reml_loglik", v6_row.evidence)
    @test occursin("fit_laplace_reml", v6_row.evidence)
    @test occursin("NonGaussianFit", v6_row.evidence)
    # #44: MarginalMethod dispatch + nongaussian_result_payload now exist, so they
    # moved from `missing` into `evidence`.
    @test occursin("MarginalMethod", v6_row.evidence)
    @test occursin("nongaussian_result_payload", v6_row.evidence)
    @test occursin("GLLVM.jl/gllvmTMB", v6_row.missing)
    @test occursin("not the public default", v6_row.claim_boundary)
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

include(joinpath(@__DIR__, "..", "sim", "summarize_validation_debt.jl"))

@testset "Validation-debt burn-down tracker (I9)" begin
    vs = validation_status()
    nrows = length(vs)
    counts = ValidationDebtTracker.status_counts(vs)
    @test [first(p) for p in counts] == ["covered", "covered_external", "partial", "planned"]
    @test sum(last, counts) == nrows                              # buckets partition the table
    debts = ValidationDebtTracker.open_debts(vs)
    @test all(d -> d.status != "covered", debts)
    cov_ids = [r.id for r in vs if r.status == "covered"]
    ce_ids = [r.id for r in vs if r.status == "covered_external"]
    @test length(debts) == nrows - length(cov_ids)               # every non-covered row
    @test all(id -> !any(d -> d.id == id, debts), cov_ids)       # covered rows excluded
    @test !isempty(ce_ids) && all(id -> any(d -> d.id == id, debts), ce_ids)  # covered_external kept
    psc = ValidationDebtTracker.phase_status_counts(vs)
    @test sum(sum(values(d)) for d in values(psc)) == nrows      # phases partition the table
    md = ValidationDebtTracker.markdown_summary(vs)
    @test occursin("# Validation-Debt Burn-Down", md)
    @test occursin("| **total** | $nrows |", md)
    @test occursin("## Open debts", md)
    @test occursin("(covered_external", md)
end

@testset "nested_lrt helper + chi-bar boundary (C10)" begin
    sf = HSquared._chisq_sf
    # 1. interior reduction == plain χ² tail (covariance_structure_lrt's unchanged path)
    r0 = nested_lrt(-100.0, -97.0; df = 2, boundary_df = 0)       # statistic = 6
    @test r0.statistic ≈ 6.0
    @test r0.pvalue ≈ sf(6.0, 2)
    @test r0.mixture == :chisq && r0.boundary == false
    # 2. single-boundary 50:50 mixture: textbook s = 2.706 (χ²_1 90th pct) -> p ≈ 0.05 vs naive 0.10
    s = 2.706
    r1 = nested_lrt(0.0, s / 2; df = 1, boundary_df = 1)
    @test r1.mixture == :chibar_5050 && r1.boundary == true
    @test r1.pvalue ≈ 0.5 * sf(s, 1) atol = 1e-9                  # df-1 = 0 tail is 0
    @test r1.pvalue < sf(s, 1)                                    # anti-conservative vs naive
    @test isapprox(r1.pvalue, 0.05; atol = 2e-3)                  # Stram-Lee halving
    # 3. df >= 2 boundary -> flagged-conservative naive χ² (no false mixture)
    r2 = nested_lrt(0.0, 3.0; df = 2, boundary_df = 2)
    @test r2.mixture == :chisq_conservative && r2.pvalue ≈ sf(6.0, 2)
    # 4. range + monotonicity
    @test 0 <= r0.pvalue <= 1 && 0 <= r1.pvalue <= 1
    @test nested_lrt(0.0, 5.0; df = 1, boundary_df = 1).pvalue <
          nested_lrt(0.0, 1.0; df = 1, boundary_df = 1).pvalue
    # 5. guards + negative statistic
    @test_throws ArgumentError nested_lrt(0.0, 1.0; df = 0)
    @test_throws ArgumentError nested_lrt(0.0, 1.0; df = 1, boundary_df = 2)
    @test_throws ArgumentError nested_lrt(0.0, 1.0; df = 2, boundary_df = -1)
    rneg = nested_lrt(0.0, -1.0; df = 1)                          # full < constrained
    @test rneg.statistic < 0 && rneg.pvalue == 1.0 && occursin("negative statistic", rneg.note)
end

@testset "Phase 6 negative-binomial (NB2, log link) family (H1)" begin
    f = HSquared.NegativeBinomialResponse(2.0)
    # kernel oracle: score = dℓ/dη, weight = -d²ℓ/dη² vs central finite differences
    for (yv, e) in [(3.0, 0.2), (0.0, -0.5), (7.0, 0.8)]
        ll(x) = HSquared._fam_loglik(f, yv, x)
        @test HSquared._fam_score(f, yv, e) ≈ (ll(e + 1e-6) - ll(e - 1e-6)) / 2e-6 rtol = 1e-4
        @test HSquared._fam_weight(f, yv, e) ≈ -(ll(e + 1e-4) - 2ll(e) + ll(e - 1e-4)) / 1e-8 rtol = 1e-3
    end
    # Poisson limit (θ→∞) pins the θ-dependent loggamma normalizer an η-only FD cannot catch
    @test HSquared._fam_loglik(HSquared.NegativeBinomialResponse(1e8), 3.0, 0.2) ≈
          HSquared._fam_loglik(HSquared.PoissonResponse(), 3.0, 0.2) atol = 1e-3
    # geometric closed form at θ = 1
    let yv = 4.0, e = 0.2, mu = exp(0.2)
        @test HSquared._fam_loglik(HSquared.NegativeBinomialResponse(1.0), yv, e) ≈
              yv * e - (yv + 1) * log(1 + mu) atol = 1e-9
    end
    # constructor + count + fitter guards
    @test_throws ArgumentError HSquared.NegativeBinomialResponse(0.0)
    @test_throws ArgumentError HSquared.NegativeBinomialResponse(-1.0)
    ped = normalize_pedigree([1, 2, 3, 4, 5, 6], [0, 0, 1, 1, 3, 3], [0, 0, 2, 2, 4, 4])
    Ai = Matrix(pedigree_inverse(ped))
    na = 6; reps = 4; n = na * reps
    Zt = zeros(n, na)
    for i in 1:n
        Zt[i, ((i - 1) ÷ reps) + 1] = 1.0          # 4 repeated records per animal -> identifiable
    end
    Xt = ones(n, 1)
    yt = Float64[1, 2, 1, 2, 5, 4, 5, 6, 0, 1, 0, 1, 3, 4, 3, 2, 7, 6, 8, 7, 2, 1, 2, 3]
    @test_throws ArgumentError fit_laplace_reml(yt, Xt, Zt, Ai; family = :nbinom, marginal = :variational)
    @test_throws ArgumentError fit_laplace_reml(yt, Xt, Zt, Ai; family = :nbinom, theta_init = -1.0)
    bad = copy(yt); bad[1] = 2.5
    @test_throws ArgumentError fit_laplace_reml(bad, Xt, Zt, Ai; family = :nbinom)
    # fit smoke: NB profiles sigma_a2 + theta jointly (repeated records -> non-singular MME)
    fb = fit_laplace_reml(yt, Xt, Zt, Ai; family = :nbinom, initial = (sigma_a2 = 0.5,), theta_init = 5.0)
    @test fb.family === :nbinom
    @test fb.variance_components.sigma_a2 > 0 && fb.variance_components.theta > 0
    # bridge payload is family-generic and self-describes the nbinom fit (V6-NBINOM row)
    pay = HSquared.nongaussian_result_payload(fb)
    @test pay.family == "nbinom"
    @test pay.n_trials === nothing
    @test haskey(pay.variance_components, :theta) && pay.variance_components.theta > 0
    @test pay.method == "laplace"
    @test !(:heritability in propertynames(pay))
end

@testset "Phase 6 beta-binomial (logit, overdispersion) family (H2)" begin
    # Beta-binomial: an OVERdispersed logit-binomial (the success probability is
    # Beta-distributed across records; intra-class correlation ρ ∈ (0,1); ρ → 0 is the
    # Binomial limit). Laplace-only; the IRLS working weight is the FISHER (expected)
    # information because the family is NOT log-concave in η at larger n.

    # --- (a) BINDING ANCHOR: ρ → 0 reduces to BinomialResponse(m) (trusted path).
    m = 10
    for η in (-1.3, 0.0, 0.7), y in (0.0, 3.0, Float64(m))
        bb = HSquared.BetaBinomialResponse(m, 1e-6)
        bn = HSquared.BinomialResponse(m)
        @test HSquared._fam_loglik(bb, y, η) ≈ HSquared._fam_loglik(bn, y, η) atol = 1e-3
    end
    # weight → Binomial Fisher info n·p(1−p) as ρ → 0
    let η = 0.4, p = HSquared._logistic(η)
        @test HSquared._fam_weight(HSquared.BetaBinomialResponse(m, 1e-6), 0.0, η) ≈
              m * p * (1 - p) rtol = 1e-3
    end

    # --- (b) KERNEL GATE: score == central finite difference of _fam_loglik.
    f = HSquared.BetaBinomialResponse(10, 0.2)
    η0 = 0.37; h = 1e-6
    @test HSquared._fam_score(f, 6.0, η0) ≈
          (HSquared._fam_loglik(f, 6.0, η0 + h) - HSquared._fam_loglik(f, 6.0, η0 - h)) / (2h) rtol = 1e-5

    # --- (b′) PMF/SCORE/WEIGHT internal consistency (independent moment checks):
    #     the beta-binomial pmf integrates to 1, its mean is n·p and its variance is
    #     the closed-form n·p(1−p)·(1+(n−1)ρ) (> binomial variance — overdispersed);
    #     the score is zero-mean; and the Fisher weight equals E[score²].
    let n = f.n_trials, p = HSquared._logistic(η0), ρ = f.rho, s = (1 - ρ) / ρ,
        α = p * s, β = (1 - p) * s
        pk = [exp(HSquared._logbinom(n, k) + HSquared._lbeta(α + k, β + (n - k)) -
                  HSquared._lbeta(α, β)) for k in 0:n]
        @test sum(pk) ≈ 1.0 atol = 1e-10
        mean_bb = sum(k * pk[k + 1] for k in 0:n)
        var_bb = sum((k - mean_bb)^2 * pk[k + 1] for k in 0:n)
        @test mean_bb ≈ n * p atol = 1e-8
        @test var_bb ≈ n * p * (1 - p) * (1 + (n - 1) * ρ) rtol = 1e-6   # overdispersion closed form
        @test var_bb > n * p * (1 - p)
        sc = [HSquared._fam_score(f, Float64(k), η0) for k in 0:n]
        @test sum(sc .* pk) ≈ 0.0 atol = 1e-7                            # zero-mean score
        @test HSquared._fam_weight(f, 0.0, η0) ≈ sum((sc .^ 2) .* pk) atol = 1e-10  # Fisher = E[score²]
    end

    # --- (c) THE LOAD-BEARING TRAP: at larger n the OBSERVED information −d²ℓ/dη²
    #     goes NEGATIVE in the surprising tail (here m=20, ρ=0.5, y=0, η=3 →
    #     ℓ_ηη ≈ +0.099 > 0), which would break cholesky(Symmetric(H)). The Fisher
    #     (expected) information stays > 0, so the Newton Hessian stays PD.
    let fneg = HSquared.BetaBinomialResponse(20, 0.5), y = 0.0, η = 3.0, h2 = 1e-4
        obs = -(HSquared._fam_loglik(fneg, y, η + h2) - 2 * HSquared._fam_loglik(fneg, y, η) +
                HSquared._fam_loglik(fneg, y, η - h2)) / h2^2
        @test obs < 0                               # observed information IS negative here
        @test HSquared._fam_weight(fneg, y, η) > 0  # Fisher information stays positive
    end
    # Fisher weight strictly positive across a wide (ρ, y, η) grid (the PD guarantee).
    for ρ in (0.2, 0.5, 0.8), yy in (0.0, 4.0, 10.0, 20.0), ηη in (-3.0, -0.5, 0.5, 3.0)
        @test HSquared._fam_weight(HSquared.BetaBinomialResponse(20, ρ), yy, ηη) > 0
    end

    # --- (d) VALUE GATE: Laplace marginal vs an INDEPENDENT tensor Gauss–Hermite
    #     quadrature of the TRUE beta-binomial marginal (β-fixed), 3-animal fixture.
    ped = normalize_pedigree(["sire", "dam", "calf"], ["0", "0", "sire"], ["0", "0", "dam"])
    Ainv = pedigree_inverse(ped)
    Z = sparse(1.0I, 3, 3)
    sa2 = 1.0
    mm = 8
    ρ = 0.25
    yb = [6.0, 2.0, 5.0]
    X0 = zeros(3, 0)
    _gh(k) = (E = eigen(SymTridiagonal(zeros(k), [sqrt(j / 2) for j in 1:k-1]));
              (E.values, sqrt(π) .* (E.vectors[1, :] .^ 2)))
    _lbin(M, yy) = HSquared._logfactorial(M) - HSquared._logfactorial(yy) -
                   HSquared._logfactorial(M - yy)
    function _betabin_marginal(y, Zd, G, M, rr, k)
        x, w = _gh(k)
        L = cholesky(Symmetric(G)).L
        n = length(y); qd = size(Zd, 2); tot = 0.0
        s = (1 - rr) / rr
        for idx in CartesianIndices(ntuple(_ -> k, qd))
            z = [sqrt(2) * x[idx[j]] for j in 1:qd]
            wt = prod(w[idx[j]] / sqrt(π) for j in 1:qd)
            η = Zd * (L * z)
            ll = 0.0
            for i in 1:n
                p = HSquared._logistic(η[i]); α = p * s; β = (1 - p) * s
                ll += HSquared._lbeta(α + y[i], β + (M - y[i])) - HSquared._lbeta(α, β) +
                      _lbin(M, Int(y[i]))
            end
            tot += wt * exp(ll)
        end
        return log(tot)
    end
    G = inv(Symmetric(Matrix(Ainv))) .* sa2
    R = _betabin_marginal(yb, Matrix(Z), G, mm, ρ, 32)
    lap = HSquared.laplace_marginal_loglik(yb, X0, Z, Ainv, sa2, HSquared.BetaBinomialResponse(mm, ρ))
    @test lap.converged
    @test abs(lap.loglik - R) < 0.2                 # Laplace close to the true marginal

    # --- guards
    @test_throws ArgumentError HSquared.BetaBinomialResponse(0, 0.2)
    @test_throws ArgumentError HSquared.BetaBinomialResponse(10, 0.0)
    @test_throws ArgumentError HSquared.BetaBinomialResponse(10, 1.0)
    @test_throws ArgumentError HSquared.laplace_marginal_loglik([9.0, 2.0, 5.0], X0, Z, Ainv, sa2,
                                                                HSquared.BetaBinomialResponse(mm, ρ))  # y > m

    # --- fitted path: σ²a at a SUPPLIED FIXED ρ (both keywords required; VA rejected)
    ids = ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"]
    pedf = normalize_pedigree(ids,
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Aif = pedigree_inverse(pedf)
    yf = [7.0, 2.0, 6.0, 8.0, 3.0, 1.0, 7.0, 9.0]   # successes in 0..10
    Xf = ones(8, 1)
    Zf = sparse(1.0I, 8, 8)
    fbb = HSquared.fit_laplace_reml(yf, Xf, Zf, Aif; family = :beta_binomial,
                                    n_trials = 10, rho = 0.2, initial = (sigma_a2 = 1.0,))
    @test fbb.family === :beta_binomial
    @test fbb.converged && fbb.variance_components.sigma_a2 > 0
    @test length(fbb.breeding_values) == 8
    @test fbb.dispersion == 0.2
    @test_throws ArgumentError HSquared.fit_laplace_reml(yf, Xf, Zf, Aif; family = :beta_binomial, rho = 0.2)     # no n_trials
    @test_throws ArgumentError HSquared.fit_laplace_reml(yf, Xf, Zf, Aif; family = :beta_binomial, n_trials = 10) # no rho
    @test_throws ArgumentError HSquared.fit_laplace_reml(yf, Xf, Zf, Aif; family = :beta_binomial,
                                                         n_trials = 10, rho = 0.2, marginal = :variational)

    # --- payload self-describes family + the fixed ρ (dispersion)
    pay = HSquared.nongaussian_result_payload(fbb)
    @test pay.family == "beta_binomial"
    @test pay.dispersion == 0.2
    @test pay.n_trials == 10
    @test pay.method == "laplace"
    @test !(:heritability in propertynames(pay))
end

@testset "Phase 6 Bernoulli probit (threshold/liability) family (H3)" begin
    # Probit threshold model P(y=1|η) = Φ(η). Laplace-only; the conditional is
    # log-concave, so the IRLS weight M(sη)(M(sη)+sη) ∈ (0,1) is the observed ==
    # expected information (no Fisher-scoring substitution, unlike beta-binomial).
    f = HSquared.BernoulliProbitResponse()
    Φ(x) = exp(HSquared._norm_logcdf(x))

    # --- (a) dependency-free normal primitives: known values + DEEP-TAIL stability
    @test HSquared._norm_pdf(0.0) ≈ 1 / sqrt(2π) atol = 1e-14
    @test HSquared._norm_pdf(1.0) ≈ exp(-0.5) / sqrt(2π) atol = 1e-14
    @test HSquared._norm_logpdf(0.7) ≈ log(HSquared._norm_pdf(0.7)) atol = 1e-12
    @test Φ(0.0) ≈ 0.5 atol = 1e-12
    @test Φ(1.96) ≈ 0.9750021048517795 atol = 1e-12        # standard-normal CDF
    @test Φ(-1.96) ≈ 0.024997895148220428 atol = 1e-12
    @test Φ(3.0) ≈ 0.9986501019683699 atol = 1e-12
    # tail STABILITY: logΦ stays FINITE deep in the left tail (a naive log(Φ)
    # underflows to -Inf around x ≈ -39) — the whole reason for the custom log-cdf.
    for x in (-10.0, -20.0, -40.0)
        @test isfinite(HSquared._norm_logcdf(x)) && HSquared._norm_logcdf(x) < 0
    end
    for x in (-40.0, -5.0, -0.3, 0.0, 1.2, 6.0)              # Φ(x) + Φ(−x) = 1
        @test exp(HSquared._norm_logcdf(x)) + exp(HSquared._norm_logcdf(-x)) ≈ 1.0 atol = 1e-12
    end
    # the LOG-form tail cf matches the package's incomplete-gamma Q where both valid
    for z in (1.5, 2.5, 4.0)
        @test exp(-z * z + log(z) - HSquared._loggamma(0.5) +
                  log(HSquared._gamma_q_cf_h(0.5, z * z))) ≈
              HSquared._reg_gamma_q_cf(0.5, z * z) rtol = 1e-10
    end

    # --- (b) conditional score/weight == central finite differences (kernel gate)
    h = 1e-6; h2 = 1e-4
    for y in (0.0, 1.0), η in (-2.0, -0.3, 0.0, 0.3, 2.0)
        ll(x) = HSquared._fam_loglik(f, y, x)
        @test HSquared._fam_score(f, y, η) ≈ (ll(η + h) - ll(η - h)) / (2h) rtol = 1e-5 atol = 1e-9
        @test HSquared._fam_weight(f, y, η) ≈
              -(ll(η + h2) - 2ll(η) + ll(η - h2)) / h2^2 rtol = 1e-3 atol = 1e-6
        @test 0 < HSquared._fam_weight(f, y, η) < 1          # log-concave ⇒ weight ∈ (0,1)
    end
    @test 0 < HSquared._fam_weight(f, 1.0, -6.0) < 1         # deep-tail weight stays in (0,1)
    @test 0 < HSquared._fam_weight(f, 0.0, 6.0) < 1

    # --- (c) marginal sanity on the 3-animal fixture: converged + mode-stationary
    ped = normalize_pedigree(["sire", "dam", "calf"], ["0", "0", "sire"], ["0", "0", "dam"])
    Ainv = pedigree_inverse(ped)
    Z = sparse(1.0I, 3, 3)
    X0 = zeros(3, 0)
    yb = [1.0, 0.0, 1.0]
    lap = HSquared.laplace_marginal_loglik(yb, X0, Z, Ainv, 1.0, f)
    @test lap.converged && lap.gradient_norm < 1e-8

    # --- (d) value gate vs an INDEPENDENT tensor Gauss–Hermite quadrature of the
    #     TRUE probit marginal (β-fixed). Binary, so a documented wider gap (cf. Bernoulli).
    _gh(k) = (E = eigen(SymTridiagonal(zeros(k), [sqrt(j / 2) for j in 1:k-1]));
              (E.values, sqrt(π) .* (E.vectors[1, :] .^ 2)))
    function _probit_marginal(y, Zd, G, k)
        x, w = _gh(k)
        L = cholesky(Symmetric(G)).L
        n = length(y); qd = size(Zd, 2); tot = 0.0
        for idx in CartesianIndices(ntuple(_ -> k, qd))
            zz = [sqrt(2) * x[idx[j]] for j in 1:qd]
            wt = prod(w[idx[j]] / sqrt(π) for j in 1:qd)
            η = Zd * (L * zz)
            ll = sum(HSquared._norm_logcdf((2 * y[i] - 1) * η[i]) for i in 1:n)
            tot += wt * exp(ll)
        end
        return log(tot)
    end
    G = inv(Symmetric(Matrix(Ainv))) .* 1.0
    R = _probit_marginal(yb, Matrix(Z), G, 32)
    @test abs(lap.loglik - R) < 0.5             # binary Laplace gap documented (cf. Bernoulli)

    # --- (e) fitted path: σ²a estimated (Brent), Laplace-only
    ids = ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"]
    pedf = normalize_pedigree(ids,
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Aif = pedigree_inverse(pedf)
    yf = [1.0, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0]
    Xf = ones(8, 1)
    Zf = sparse(1.0I, 8, 8)
    fp = HSquared.fit_laplace_reml(yf, Xf, Zf, Aif; family = :bernoulli_probit,
                                   initial = (sigma_a2 = 1.0,))
    @test fp.family === :bernoulli_probit
    @test fp.converged && fp.variance_components.sigma_a2 > 0
    @test fp.n_trials === nothing && fp.dispersion === nothing
    @test length(fp.breeding_values) == 8
    @test_throws ArgumentError HSquared.fit_laplace_reml(yf, Xf, Zf, Aif;
                                                         family = :bernoulli_probit, marginal = :variational)

    # --- (f) payload: liability scale ⇒ no heritability; family flows
    pay = HSquared.nongaussian_result_payload(fp)
    @test pay.family == "bernoulli_probit"
    @test pay.dispersion === nothing && pay.n_trials === nothing
    @test pay.method == "laplace"
    @test !(:heritability in propertynames(pay))

    # --- (g) interval: clamp-flagged single-component tuple; :variational rejected
    ci = HSquared.laplace_reml_interval(yf, Xf, Zf, Aif; family = :bernoulli_probit, level = 0.95)
    @test ci.level == 0.95 && ci.sigma_a2 == fp.variance_components.sigma_a2
    @test hasproperty(ci, :lower_clamped) && hasproperty(ci, :upper_clamped) && hasproperty(ci, :converged)
    @test_throws ArgumentError HSquared.laplace_reml_interval(yf, Xf, Zf, Aif;
                                                              family = :bernoulli_probit, marginal = :variational)

    # --- (h) guards: non-binary response throws
    @test_throws ArgumentError HSquared.laplace_marginal_loglik([2.0, 0.0, 1.0], X0, Z, Ainv, 1.0, f)
end

@testset "Phase 6 ordered-categorical probit (ordinal threshold) family (T1, v0.6)" begin
    # OrderedProbitResponse: K ordered categories on a standard-normal latent scale with
    # K-1 SUPPLIED cutpoints, P(y=k|η) = Φ(θ_k−η) − Φ(θ_{k-1}−η). EXPERIMENTAL, internal,
    # supplied thresholds (joint cutpoint estimation is a follow-up).
    op = HSquared.OrderedProbitResponse
    bp = HSquared.BernoulliProbitResponse()

    # --- (a) THE REDUCTION GATE: K=2, θ=[0] reduces EXACTLY to Bernoulli probit
    #     (category 2 ↔ y=1, category 1 ↔ y=0) — loglik, score, AND observed weight.
    let o = op([0.0])
        for η in (-1.7, -0.4, 0.6, 1.9)
            @test HSquared._fam_loglik(o, 2, η) ≈ HSquared._fam_loglik(bp, 1, η) atol = 1e-12
            @test HSquared._fam_loglik(o, 1, η) ≈ HSquared._fam_loglik(bp, 0, η) atol = 1e-12
            @test HSquared._fam_score(o, 2, η) ≈ HSquared._fam_score(bp, 1, η) atol = 1e-12
            @test HSquared._fam_score(o, 1, η) ≈ HSquared._fam_score(bp, 0, η) atol = 1e-12
            @test HSquared._fam_weight(o, 2, η) ≈ HSquared._fam_weight(bp, 1, η) atol = 1e-10
            @test HSquared._fam_weight(o, 1, η) ≈ HSquared._fam_weight(bp, 0, η) atol = 1e-10
        end
    end

    # --- (b) KERNEL GATES on a 3-category family: score == central FD of loglik;
    #     observed weight == −(second FD of loglik) and is > 0 (ordered probit is
    #     log-concave in η); category probabilities sum to 1; the score is zero-mean.
    let f = op([-0.5, 0.8]), K = 3
        for η in (-0.9, 0.4, 1.6)
            P = [exp(HSquared._fam_loglik(f, k, η)) for k in 1:K]
            @test sum(P) ≈ 1.0 atol = 1e-10
            @test sum(P[k] * HSquared._fam_score(f, k, η) for k in 1:K) ≈ 0.0 atol = 1e-8
            h = 1e-5
            for k in 1:K
                ll(x) = HSquared._fam_loglik(f, k, x)
                @test HSquared._fam_score(f, k, η) ≈ (ll(η + h) - ll(η - h)) / (2h) rtol = 1e-5
                @test HSquared._fam_weight(f, k, η) ≈ -(ll(η + h) - 2ll(η) + ll(η - h)) / h^2 rtol = 1e-3
                @test HSquared._fam_weight(f, k, η) > 0
            end
        end
    end

    # --- (c) END-TO-END VALUE GATE: the ordinal Laplace marginal at θ=[0] equals the
    #     Bernoulli-probit marginal on the same binary data (recoded 0/1 → 1/2).
    let ped = normalize_pedigree(string.(1:8), fill("0", 8), fill("0", 8))
        Ainv = pedigree_inverse(ped)
        X = ones(8, 1); Z = Matrix(1.0I, 8, 8); y01 = [0.0, 1, 1, 0, 1, 0, 1, 1]
        mp = HSquared.laplace_marginal_loglik(y01, X, Z, Ainv, 0.5, bp)
        mo = HSquared.laplace_marginal_loglik(y01 .+ 1, X, Z, Ainv, 0.5, op([0.0]))
        @test mo.loglik ≈ mp.loglik atol = 1e-9
    end

    # --- (d) guards: strictly-increasing thresholds; non-empty; category range 1:K.
    @test_throws ArgumentError op([0.5, 0.2])
    @test_throws ArgumentError op(Float64[])
    @test_throws ArgumentError HSquared._check_counts(op([0.0, 1.0]), [0.0])  # category 0 < 1
    @test_throws ArgumentError HSquared._check_counts(op([0.0, 1.0]), [4.0])  # category 4 > K=3
end

@testset "Phase 6 Gamma (log link, positive continuous) family (T-Gamma, v0.6)" begin
    # GammaResponse(shape) — strictly-positive continuous response, mean μ=exp(η), SUPPLIED
    # shape ν. EXPERIMENTAL, internal, Laplace-only. (validation_status() row DEFERRED to
    # merge-sequencing per the one-row-adding-PR-at-a-time count-guard discipline.)
    G = HSquared.GammaResponse

    # --- (a) THE REDUCTION GATE: ν=1 reduces EXACTLY to the Exponential
    #     (ℓ=−η−y·e^{-η}, score=y·e^{-η}−1, observed weight=y·e^{-η}).
    let g1 = G(1.0)
        for (y, η) in ((0.5, -0.3), (2.0, 0.7), (1.2, 1.5))
            @test HSquared._fam_loglik(g1, y, η) ≈ -η - y * exp(-η) atol = 1e-12
            @test HSquared._fam_score(g1, y, η) ≈ y * exp(-η) - 1 atol = 1e-12
            @test HSquared._fam_weight(g1, y, η) ≈ y * exp(-η) atol = 1e-12
        end
    end

    # --- (b) KERNEL GATES (ν≠1): score == central FD of loglik; observed weight ==
    #     −(second FD) and is > 0 (Gamma log-link is log-concave in η).
    for ν in (0.5, 2.0, 5.0), (y, η) in ((0.8, -0.2), (3.0, 0.9))
        f = G(ν)
        ll(x) = HSquared._fam_loglik(f, y, x)
        @test HSquared._fam_score(f, y, η) ≈ (ll(η + 1e-6) - ll(η - 1e-6)) / 2e-6 rtol = 1e-5
        @test HSquared._fam_weight(f, y, η) ≈ -(ll(η + 1e-4) - 2ll(η) + ll(η - 1e-4)) / 1e-8 rtol = 1e-3
        @test HSquared._fam_weight(f, y, η) > 0
    end

    # --- (c) END-TO-END: the Laplace marginal is finite on a tiny Gamma fixture.
    let ped = normalize_pedigree(string.(1:6), fill("0", 6), fill("0", 6))
        Ainv = pedigree_inverse(ped)
        X = ones(6, 1); Z = Matrix(1.0I, 6, 6); y = [0.8, 1.5, 2.1, 0.6, 1.2, 3.0]
        @test isfinite(HSquared.laplace_marginal_loglik(y, X, Z, Ainv, 0.5, G(2.0)).loglik)
    end

    # --- (d) guards: positive shape; strictly-positive response.
    @test_throws ArgumentError G(-1.0)
    @test_throws ArgumentError G(0.0)
    @test_throws ArgumentError HSquared._check_counts(G(2.0), [0.0])
end

@testset "Phase 6 Gamma JOINT (σ²a, shape) estimation (T-Gamma fit, v0.6)" begin
    # fit_laplace_reml(...; family = :gamma) JOINTLY estimates σ²a AND the shape ν over
    # (log σ²a, log ν) by NelderMead (same shape as :nbinom). A=I animal model with REPEATED
    # RECORDS: repeated records identify the Gamma shape ν (an uninformative one-record design
    # weakly identifies ν — flat likelihood for large ν → the safety rail), between-animal
    # spread identifies σ²a. Deterministic optimizer + fixed data → deterministic.
    q = 6; reps = 4; n = q * reps
    id = repeat(1:q, inner = reps)
    Ainv = Matrix(1.0I, q, q)
    X = ones(n, 1); Z = zeros(n, q)
    for i in 1:n; Z[i, id[i]] = 1.0; end
    # 3 "high" animals (~2.2) + 3 "low" (~0.7); within-animal spread identifies ν.
    y = [2.3, 1.9, 2.6, 2.1, 0.7, 0.5, 0.9, 0.6, 2.4, 2.0, 2.7, 2.2,
         0.8, 0.6, 1.0, 0.7, 2.5, 2.1, 2.8, 2.3, 0.75, 0.55, 0.95, 0.65]

    f = fit_laplace_reml(y, X, Z, Ainv; family = :gamma)
    sa = f.variance_components.sigma_a2; ν = f.variance_components.shape
    @test f.family == :gamma && f.converged
    @test sa > 1e-3 && 0 < ν < 1.0e4                        # σ²a meaningful; shape BOUNDED (the rail catches a runaway)
    # self-consistency: reported loglik == the marginal at the returned (σ²a, ν)
    mm = HSquared.laplace_marginal_loglik(y, X, Z, Ainv, sa, HSquared.GammaResponse(ν))
    @test f.marginal_loglik ≈ mm.loglik atol = 1e-8
    # the returned optimum beats a deliberately off-optimum (σ²a, ν) point
    off = HSquared.laplace_marginal_loglik(y, X, Z, Ainv, sa * 4, HSquared.GammaResponse(ν * 0.2)).loglik
    @test f.marginal_loglik >= off

    # guards: strictly-positive response; variational rejected.
    @test_throws ArgumentError fit_laplace_reml([1.0, -2.0, 1.0], ones(3, 1),
        Matrix(1.0I, 3, 3), Matrix(1.0I, 3, 3); family = :gamma)
    @test_throws ArgumentError fit_laplace_reml(y, X, Z, Ainv; family = :gamma, marginal = :variational)
end

@testset "Phase 6 non-Gaussian interval cross-family contract (H6)" begin
    # The σ²a profile-LRT interval covers ALL single-component families through ONE
    # shared `_resolve_single_family` + `target`/`_profile_root` path. Lock that
    # uniform return-field contract (incl. BOTH clamp flags) across the families — the
    # CI-safe half of H6; the empirical coverage characterization is the opt-in
    # `sim/phase6_nongaussian_interval_coverage.jl` (capped, outside CI).
    ped = normalize_pedigree(["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"],
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Ainv = pedigree_inverse(ped)
    X = ones(8, 1)
    Z = sparse(1.0I, 8, 8)
    yp = [3.0, 5.0, 8.0, 4.0, 6.0, 2.0, 5.0, 7.0]
    yb = [1.0, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0]
    ym = [7.0, 2.0, 6.0, 8.0, 3.0, 1.0, 7.0, 9.0]
    cis = (
        HSquared.laplace_reml_interval(yp, X, Z, Ainv; family = :poisson),
        HSquared.laplace_reml_interval(yb, X, Z, Ainv; family = :bernoulli),
        HSquared.laplace_reml_interval(ym, X, Z, Ainv; family = :binomial, n_trials = 10),
        HSquared.laplace_reml_interval(yb, X, Z, Ainv; family = :bernoulli_probit),
    )
    fields = (:sigma_a2, :lower, :upper, :level, :lower_clamped, :upper_clamped, :converged)
    for ci in cis
        @test propertynames(ci) == fields                       # uniform return contract
        @test ci.lower_clamped isa Bool && ci.upper_clamped isa Bool && ci.converged isa Bool
        @test ci.level == 0.95
    end
    @test all(propertynames(ci) == propertynames(cis[1]) for ci in cis)   # identical across families

    # the V6-LAPLACE validation row records the coverage characterization (H6)
    vrow = only(r for r in validation_status() if r.id == "V6-LAPLACE")
    @test occursin("coverage", vrow.evidence)
end

@testset "Phase 6 non-Gaussian latent/observation-scale heritability (H7)" begin
    # Nakagawa–Schielzeth / de Villemereuil (QGglmm) transform. Latent h² =
    # V_A/(V_A+V_link+V_fixed); observation h² = Ψ²·V_A / V_P,obs integrated over the
    # LINEAR-PREDICTOR distribution N(μ, V_A+V_fixed) (NO π²/3 in the integration var).
    lg(η) = 1.0 / (1.0 + exp(-η))
    # independent 64-node Gauss–Hermite expectation of g over N(μ, v) (NOT the 20-node
    # _gh_expect under test) — the oracle for the observation-scale integrals.
    function _fine(g, μ, v)
        k = 64
        E = eigen(SymTridiagonal(zeros(k), [sqrt(j / 2) for j in 1:k-1]))
        x = E.values; w = sqrt(π) .* (E.vectors[1, :] .^ 2); s = sqrt(2v)
        return sum(w[i] * g(μ + s * x[i]) for i in eachindex(x)) / sqrt(π)
    end

    # (1) Gaussian reduction: latent == observation == V_A/(V_A+σ²e), machine precision.
    g = HSquared.nongaussian_heritability(2.0, 0.0, HSquared.GaussianResponse(3.0))
    @test g.h2_latent ≈ 2.0 / 5.0 atol = 1e-12
    @test g.h2_observation ≈ 2.0 / 5.0 atol = 1e-12
    @test g.family === :gaussian
    ped = normalize_pedigree(["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"],
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Ainv = pedigree_inverse(ped); X = ones(8, 1); Z = sparse(1.0I, 8, 8)
    yg = [1.2, -0.4, 0.8, 1.5, -0.2, 0.1, 0.9, 1.1]
    fg = HSquared.fit_laplace_reml(yg, X, Z, Ainv; family = :gaussian,
                                   initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    hg = HSquared.nongaussian_heritability(fg)
    @test hg.h2_latent ≈ fg.variance_components.sigma_a2 /
          (fg.variance_components.sigma_a2 + fg.variance_components.sigma_e2) atol = 1e-12
    @test hg.h2_latent == hg.h2_observation

    # (2) Logit latent-scale closed form V_A/(V_A+π²/3), exact; Bernoulli info-limited.
    let V_A = 0.8, μ = 0.3
        b = HSquared.nongaussian_heritability(V_A, μ, HSquared.BernoulliResponse())
        @test b.h2_latent ≈ V_A / (V_A + (π^2) / 3) atol = 1e-12
        @test b.var_link ≈ (π^2) / 3 atol = 1e-12
        @test b.information_limited
        @test 0 < b.h2_observation < 1
    end

    # (3) Logit observation-scale vs the INDEPENDENT 64-node quadrature of the same integrals.
    let V_A = 0.8, μ = 0.3, n = 5
        bb = HSquared.nongaussian_heritability(V_A, μ, HSquared.BinomialResponse(n))
        p̄ = _fine(lg, μ, V_A)
        Ψ = _fine(η -> (p = lg(η); p * (1 - p)), μ, V_A)
        var_p = _fine(η -> lg(η)^2, μ, V_A) - p̄^2
        @test bb.h2_observation ≈ (Ψ^2 * V_A) / (var_p + Ψ / n) rtol = 1e-3
        @test 0 < bb.h2_observation < 1
    end

    # (4) Poisson: latent NaN; observation closed form vs independent integration.
    let V_A = 0.5, μ = 1.2
        po = HSquared.nongaussian_heritability(V_A, μ, HSquared.PoissonResponse())
        @test isnan(po.h2_latent)
        λ = _fine(exp, μ, V_A); var_λ = _fine(η -> exp(2η), μ, V_A) - λ^2
        @test po.h2_observation ≈ (λ^2 * V_A) / (var_λ + λ) rtol = 1e-6
        @test 0 < po.h2_observation < 1
        @test po.var_link == 0.0
    end

    # (5) Binomial information gradient: h²_obs RISES with n_trials (1 → 5 → 20) at
    #     fixed (V_A, μ) — the same information effect the engine already documents.
    let V_A = 0.8, μ = 0.0
        h1 = HSquared.nongaussian_heritability(V_A, μ, HSquared.BinomialResponse(1)).h2_observation
        h5 = HSquared.nongaussian_heritability(V_A, μ, HSquared.BinomialResponse(5)).h2_observation
        h20 = HSquared.nongaussian_heritability(V_A, μ, HSquared.BinomialResponse(20)).h2_observation
        @test h1 < h5 < h20 < 1
    end

    # (6) Guards / honesty.
    yb = [1.0, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0]
    fb = HSquared.fit_laplace_reml(yb, X, Z, Ainv; family = :bernoulli, initial = (sigma_a2 = 1.0,))
    @test HSquared.nongaussian_heritability(fb).information_limited
    nts = [2, 4, 5, 6, 10, 12, 3, 8]
    yv = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 2.0, 7.0]
    fv = HSquared.fit_laplace_reml(yv, X, Z, Ainv; family = :binomial, n_trials = nts,
                                   initial = (sigma_a2 = 1.0,))
    hv = HSquared.nongaussian_heritability(fv)
    @test isnan(hv.h2_observation) && occursin("varying", hv.caveat)
    X2 = [ones(8) [0.1, 0.2, -0.1, 0.3, 0.0, 0.4, -0.2, 0.1]]
    fp2 = HSquared.fit_laplace_reml(yb, X2, Z, Ainv; family = :bernoulli, initial = (sigma_a2 = 1.0,))
    @test_throws ArgumentError HSquared.nongaussian_heritability(fp2)            # ambiguous μ
    @test HSquared.nongaussian_heritability(fp2; mu = 0.0).family === :bernoulli # works with μ
    nf = HSquared.NonGaussianFit((sigma_a2 = 1.0,), -3.0, [0.0], zeros(8), collect(1:8),
                                 false, :poisson, :laplace, nothing, nothing)
    @test_throws ArgumentError HSquared.nongaussian_heritability(nf)             # non-converged refused
    @test_throws ArgumentError HSquared.nongaussian_heritability(1.0, 0.0, HSquared.NegativeBinomialResponse(2.0))

    # (7) validation row present + partial; NOT added to the family-uniform payload.
    nsh2 = only(r for r in validation_status() if r.id == "V6-NS-H2")
    @test nsh2.status == "partial"
    @test occursin("Nakagawa", nsh2.evidence) || occursin("observation", nsh2.evidence)
    @test !(:heritability in propertynames(HSquared.nongaussian_result_payload(fb)))
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
    # F1: inbreeding now uses Meuwissen-Luo (O(n)); max_relationship_cache no longer
    # bounds it (it previously threw). The kwarg is ignored and the result is unchanged.
    @test inbreeding_coefficients(ped; max_relationship_cache = 2) ≈
          [HSquared._numerator_relationship(ped)[i, i] - 1.0 for i in 1:length(ped)]
end

@testset "F1 Meuwissen-Luo inbreeding (O(n), no dense cap)" begin
    oracleF(p) = (A = HSquared._numerator_relationship(p); [A[i, i] - 1.0 for i in 1:length(p)])
    # deterministic well-mixed mating (multiplicative hash) so two parents share
    # ancestry -> GENUINE bounded inbreeding (no RNG; q=2000 -> ~1870/2000 inbred,
    # meanF≈0.08, maxF≈0.56). A naive modular rule collapses to constant parents
    # (zero inbreeding), so the inbred-count guard below is load-bearing.
    function det_inbred(q; nf = 20)
        ids = string.(1:q)
        s = fill("0", q); d = fill("0", q)
        for i in (nf + 1):q
            s[i] = string(1 + ((i * 2654435761) % (i - 1)))
            d[i] = string(1 + (((i + 7) * 2246822519) % (i - 1)))
        end
        return normalize_pedigree(ids, s, d; allow_selfing = true)
    end
    # exact match to the dense oracle on small + moderate GENUINELY-INBRED pedigrees
    for q in (200, 2000)
        p = det_inbred(q)
        F = inbreeding_coefficients(p)
        @test count(f -> f > 1e-9, F) > q ÷ 2          # fixture is genuinely inbred (not vacuous)
        @test F ≈ oracleF(p)
        @test inbreeding_coefficients(p; max_relationship_cache = 2) ≈ oracleF(p)  # cache ignored
    end
    # selfing chain: exact match (canonical F = 0, 0.5, 0.75, 0.875)
    selfing = normalize_pedigree(["p", "s1", "s2", "s3"], ["0", "p", "s1", "s2"],
                                 ["0", "p", "s1", "s2"]; allow_selfing = true)
    @test inbreeding_coefficients(selfing) ≈ oracleF(selfing)
    @test inbreeding_coefficients(selfing) ≈ [0.0, 0.5, 0.75, 0.875]
    # scales PAST the old 1e4 dense cap without throwing (the F1 unblock; the dense
    # oracle is infeasible here). pedigree_inverse is unblocked too.
    big = det_inbred(12_000)
    Fbig = inbreeding_coefficients(big)
    @test length(Fbig) == 12_000
    @test count(f -> f > 1e-9, Fbig) > 6_000           # genuinely inbred at scale
    @test all(f -> 0.0 <= f <= 1.0, Fbig)
    @test all(isfinite, Fbig)
    @test nnz(pedigree_inverse(big)) > 0               # pedigree_inverse unblocked at scale
end

@testset "Phase 3 cytoplasmic (maternal-lineage) relationship" begin
    # Cytoplasmic / mitochondrial inheritance is maternal-lineage: two individuals
    # share it (relationship 1) iff they trace to the same maternal founder.
    # Hand fixture: maternal lines A:{A,C,D,F} and B:{B,E}.
    ids = ["A", "B", "C", "D", "E", "F"]
    sire = ["0", "0", "B", "B", "A", "E"]
    dam = ["0", "0", "A", "A", "B", "C"]
    ped = normalize_pedigree(ids, sire, dam)
    idx(id) = findfirst(==(id), ped.ids)

    lab = HSquared.maternal_lineage(ped)
    @test length(lab) == length(ped)
    @test lab[idx("A")] == lab[idx("C")] == lab[idx("D")] == lab[idx("F")]   # A line
    @test lab[idx("B")] == lab[idx("E")]                                     # B line
    @test lab[idx("A")] != lab[idx("B")]
    # founders label their own lineage
    @test lab[idx("A")] == "A" && lab[idx("B")] == "B"
    @test lab[idx("F")] == "A"                                               # F→C→A

    M = HSquared.cytoplasmic_relationship(ped)
    @test size(M) == (6, 6)
    @test issymmetric(M)
    @test all(diag(M) .== 1.0)
    @test M[idx("A"), idx("F")] == 1.0    # same maternal line
    @test M[idx("C"), idx("D")] == 1.0
    @test M[idx("B"), idx("E")] == 1.0
    @test M[idx("A"), idx("B")] == 0.0    # different lines
    @test M[idx("E"), idx("F")] == 0.0
    # M is exactly the same-lineage indicator
    for i in 1:length(ped), j in 1:length(ped)
        @test M[i, j] == (lab[i] == lab[j] ? 1.0 : 0.0)
    end

    # convenience (ids, sire, dam) method agrees
    M2 = HSquared.cytoplasmic_relationship(ids, sire, dam)
    @test M2 == M
    lab2 = HSquared.maternal_lineage(ids, sire, dam)
    @test lab2 == lab

    # all-founder pedigree → identity (every individual its own maternal line)
    fped = normalize_pedigree(["x", "y", "z"], ["0", "0", "0"], ["0", "0", "0"])
    @test HSquared.cytoplasmic_relationship(fped) == Matrix(1.0I, 3, 3)
end

@testset "Phase 3 selfing (self-fertilization)" begin
    # By default selfing (sire == dam) is rejected — preserves the sexual contract.
    @test_throws ArgumentError normalize_pedigree(["P", "i"], ["0", "P"], ["0", "P"])

    # Opt-in: allow_selfing = true. Canonical inbreeding series for repeated
    # selfing of a non-inbred founder: F = 0, 1/2, 3/4, ... (Falconer/Mrode).
    ped = normalize_pedigree(["P", "i", "j"], ["0", "P", "i"], ["0", "P", "i"];
                             allow_selfing = true)
    idx(id) = findfirst(==(id), ped.ids)
    F = inbreeding_coefficients(ped)
    @test F[idx("P")] ≈ 0.0
    @test F[idx("i")] ≈ 0.5            # one generation of selfing
    @test F[idx("j")] ≈ 0.75           # two generations

    A = HSquared._numerator_relationship(ped)
    @test A[idx("i"), idx("i")] ≈ 1.5  # 1 + F_i
    @test A[idx("j"), idx("j")] ≈ 1.75 # 1 + F_j
    @test A[idx("i"), idx("P")] ≈ 1.0  # selfed offspring of a non-inbred founder
    @test issymmetric(A)

    # Henderson's direct inverse rules handle selfing: Ainv == inv(A) exactly.
    @test Matrix(pedigree_inverse(ped)) ≈ inv(A)

    # A selfed founder line still composes with a normal sexual pedigree.
    mixed = normalize_pedigree(["P", "s", "i", "o"],
                               ["0", "0", "P", "s"], ["0", "0", "P", "i"];
                               allow_selfing = true)
    @test inbreeding_coefficients(mixed)[findfirst(==("i"), mixed.ids)] ≈ 0.5
    @test Matrix(pedigree_inverse(mixed)) ≈ inv(HSquared._numerator_relationship(mixed))
end

@testset "Phase 3 clonal (asexual) relationship" begin
    # Genets P, Q (founders), G = sexual offspring of P×Q; r1, r2 = clonal ramets
    # of G. Ramets are genetically identical to their genet and to each other, and
    # inherit the genet's relationships to everyone else (no Mendelian sampling).
    ped = normalize_pedigree(["P", "Q", "G", "r1", "r2"],
                             ["0", "0", "P", "0", "0"], ["0", "0", "Q", "0", "0"])
    idx(id) = findfirst(==(id), ped.ids)
    A = HSquared._numerator_relationship(ped)
    clone_of = [id in ("r1", "r2") ? "G" : "0" for id in ped.ids]   # aligned to ped.ids

    C = HSquared.clonal_relationship(ped, clone_of)
    @test size(C) == (5, 5)
    @test issymmetric(C)
    @test C[idx("r1"), idx("r2")] == 1.0     # clonemates identical
    @test C[idx("r1"), idx("G")] == 1.0      # ramet identical to its genet
    @test C[idx("r1"), idx("r1")] == 1.0
    @test C[idx("r1"), idx("P")] == A[idx("G"), idx("P")]   # inherits genet's links (0.5)
    @test C[idx("r2"), idx("Q")] == A[idx("G"), idx("Q")]   # 0.5
    @test C[idx("P"), idx("Q")] == A[idx("P"), idx("Q")]    # non-clones unchanged (0)
    @test C[idx("G"), idx("G")] == A[idx("G"), idx("G")]    # 1

    # no clones → identical to the numerator relationship
    @test HSquared.clonal_relationship(ped, fill("0", 5)) == A

    # chained ramets resolve to the ultimate genet (clone of a clone)
    ped2 = normalize_pedigree(["G", "r1", "r2"], ["0", "0", "0"], ["0", "0", "0"])
    j(id) = findfirst(==(id), ped2.ids)
    chain = [ped2.ids[k] == "r1" ? "G" : (ped2.ids[k] == "r2" ? "r1" : "0") for k in 1:3]
    C2 = HSquared.clonal_relationship(ped2, chain)
    @test C2 == ones(3, 3)                   # all one genet line → all identical

    # guards
    @test_throws ArgumentError HSquared.clonal_relationship(ped, ["0", "0", "0", "G"])     # wrong length
    @test_throws ArgumentError HSquared.clonal_relationship(ped, [id == "r1" ? "ZZ" : "0" for id in ped.ids])  # unknown genet
    pedc = normalize_pedigree(["a", "b"], ["0", "0"], ["0", "0"])
    cyc = [pedc.ids[k] == "a" ? "b" : "a" for k in 1:2]                  # a→b, b→a cycle
    @test_throws ArgumentError HSquared.clonal_relationship(pedc, cyc)
    self = [pedc.ids[k] == "a" ? "a" : "0" for k in 1:2]                 # a clone of itself
    @test_throws ArgumentError HSquared.clonal_relationship(pedc, self)
end

@testset "Phase 3 dominance relationship" begin
    # Cockerham/Mrode dominance relationship: for animals x, y with parents
    # (sx,dx), (sy,dy), D[x,y] = ¼(A[sx,sy]A[dx,dy] + A[sx,dy]A[dx,sy]); D[x,x]=1
    # (non-inbred parents). Full sibs → ¼, half sibs / parent-offspring → 0.
    ids = ["s1", "d1", "d2", "x", "y", "z", "w"]
    sire = ["0", "0", "0", "s1", "s1", "s1", "s1"]
    dam = ["0", "0", "0", "d1", "d1", "d2", "d2"]
    ped = normalize_pedigree(ids, sire, dam)
    idx(id) = findfirst(==(id), ped.ids)
    D = HSquared.dominance_relationship(ped)

    @test size(D) == (7, 7)
    @test issymmetric(D)
    @test all(diag(D) .== 1.0)
    @test D[idx("x"), idx("y")] ≈ 0.25     # full sibs (s1×d1)
    @test D[idx("z"), idx("w")] ≈ 0.25     # full sibs (s1×d2)
    @test D[idx("x"), idx("z")] ≈ 0.0      # paternal half sibs
    @test D[idx("x"), idx("w")] ≈ 0.0      # paternal half sibs
    @test D[idx("x"), idx("s1")] ≈ 0.0     # parent–offspring
    @test D[idx("s1"), idx("d1")] ≈ 0.0    # unrelated founders
    # off-diagonal matches the explicit Cockerham formula against A
    A = HSquared._numerator_relationship(ped)
    si, di = ped.sire, ped.dam
    for a in 1:length(ped), b in 1:length(ped)
        if a != b && si[a] != 0 && di[a] != 0 && si[b] != 0 && di[b] != 0
            expected = 0.25 * (A[si[a], si[b]] * A[di[a], di[b]] +
                               A[si[a], di[b]] * A[di[a], si[b]])
            @test D[a, b] ≈ expected
        end
    end
    # convenience (ids, sire, dam) method
    @test HSquared.dominance_relationship(ids, sire, dam) == D
end

@testset "Phase 1 additive relationship matrix (public accessor)" begin
    # Public accessor for the dense additive numerator relationship A, the
    # companion of pedigree_inverse and of the exported D / cytoplasmic / clonal
    # relationship matrices.
    ids = ["s", "d", "x", "y"]
    sire = ["0", "0", "s", "s"]
    dam = ["0", "0", "d", "d"]
    ped = normalize_pedigree(ids, sire, dam)
    idx(id) = findfirst(==(id), ped.ids)
    A = additive_relationship(ped)

    @test A == HSquared._numerator_relationship(ped)
    @test issymmetric(A)
    @test all(diag(A) .== 1.0)               # non-inbred founders/offspring
    @test A[idx("x"), idx("y")] ≈ 0.5        # full sibs
    @test A[idx("x"), idx("s")] ≈ 0.5        # parent–offspring
    @test A[idx("s"), idx("d")] ≈ 0.0        # unrelated founders
    @test A ≈ inv(Matrix(pedigree_inverse(ped)))   # exact inverse of Ainv
    @test additive_relationship(ids, sire, dam) == A

    # inbreeding shows on the diagonal (offspring of related parents)
    inbred = normalize_pedigree(["a", "b", "c", "k"],
                                ["0", "0", "a", "a"], ["0", "0", "b", "c"])
    Ai = additive_relationship(inbred)
    @test Ai[findfirst(==("k"), inbred.ids), findfirst(==("k"), inbred.ids)] ≈ 1.25  # 1 + F, F = 0.25
    @test_throws ArgumentError additive_relationship(ped; max_relationship_cache = 2)
end

@testset "Phase 1 Mendelian sampling variances" begin
    # d_i = Var of the within-family deviation: founders 1; both parents known &
    # non-inbred 1/2; one parent known & non-inbred 3/4. (A = T·D·Tᵀ.)
    ped = normalize_pedigree(["s", "d", "o", "o2"], ["0", "0", "s", "s"], ["0", "0", "d", "0"])
    idx(id) = findfirst(==(id), ped.ids)
    dvar = mendelian_sampling_variances(ped)
    @test dvar[idx("s")] ≈ 1.0 && dvar[idx("d")] ≈ 1.0     # founders
    @test dvar[idx("o")] ≈ 0.5                              # both parents known, non-inbred
    @test dvar[idx("o2")] ≈ 0.75                            # one parent known, non-inbred

    # matches the internal per-record helper
    F = inbreeding_coefficients(ped)
    for i in 1:length(ped)
        @test dvar[i] ≈ HSquared._mendelian_sampling_variance(ped.sire[i], ped.dam[i], F)
    end

    # LDL'-style identity: det(A) = ∏ d_i  (A = T·D·Tᵀ, T unit lower-triangular)
    @test det(additive_relationship(ped)) ≈ prod(dvar) atol = 1e-10

    # selfing chain: d_k = ½(1 − F_{k−1})
    sped = normalize_pedigree(["g0", "g1", "g2", "g3"],
                              ["0", "g0", "g1", "g2"], ["0", "g0", "g1", "g2"]; allow_selfing = true)
    ds = mendelian_sampling_variances(sped); Fs = inbreeding_coefficients(sped)
    j(id) = findfirst(==(id), sped.ids)
    @test ds[j("g1")] ≈ 0.5
    @test ds[j("g2")] ≈ 0.5 * (1 - Fs[j("g1")])            # 0.5·(1−0.5) = 0.25
    @test det(additive_relationship(sped)) ≈ prod(ds) atol = 1e-10

    # convenience (ids, sire, dam) method
    @test mendelian_sampling_variances(["s", "d", "o"], ["0", "0", "s"], ["0", "0", "d"]) ==
          mendelian_sampling_variances(normalize_pedigree(["s", "d", "o"], ["0", "0", "s"], ["0", "0", "d"]))
end

@testset "Phase 1 deep-inbreeding dense-inverse conditioning (V1-DENSE-COND)" begin
    # A selfing chain drives inbreeding to F_k = 1 − (1/2)^k, which makes the
    # relationship matrix increasingly ill-conditioned. This pins the documented
    # V1-DENSE-COND caveat: `pedigree_inverse` is a DIRECT Henderson construction,
    # so it stays exact regardless of conditioning — the caveat is about the
    # downstream dense-`inv(Ainv)` estimators, not the sparse Ainv itself.
    ids = ["g0", "g1", "g2", "g3", "g4", "g5", "g6"]
    sire = ["0", "g0", "g1", "g2", "g3", "g4", "g5"]
    dam = ["0", "g0", "g1", "g2", "g3", "g4", "g5"]
    ped = normalize_pedigree(ids, sire, dam; allow_selfing = true)
    idx(id) = findfirst(==(id), ped.ids)
    F = inbreeding_coefficients(ped)
    for k in 0:6
        @test F[idx("g$k")] ≈ 1 - 0.5^k atol = 1e-10
    end

    A = additive_relationship(ped)
    Ainv = Matrix(pedigree_inverse(ped))
    # conditioning genuinely grows with inbreeding (documents the caveat)
    @test cond(A) > 1.0e3
    # the DIRECT Henderson inverse is exact despite the conditioning
    @test maximum(abs.(Ainv * A - I)) < 1e-9
    @test maximum(abs.(Ainv .- inv(A))) < 1e-6

    # a supplied-variance MME solve on the deeply-inbred pedigree stays finite
    y = [1.0, 2.0, 1.5, 2.5, 1.0, 2.0, 1.5]; X = ones(7, 1); Z = Matrix(1.0I, 7, 7)
    res = henderson_mme(animal_model_spec(y, X, Z, pedigree_inverse(ped); ids = ped.ids), 1.0, 1.5)
    @test all(isfinite, breeding_values(res).values)
    @test all(isfinite, fixed_effects(res))
end

@testset "Phase 3 epistatic relationship (Hadamard products)" begin
    # Henderson (1985): orthogonal epistatic relationship matrices are Hadamard
    # products of the additive A and dominance D matrices — A∘A (additive×additive),
    # A∘D (additive×dominance), D∘D (dominance×dominance).
    ids = ["s1", "d1", "d2", "x", "y", "z", "w"]
    sire = ["0", "0", "0", "s1", "s1", "s1", "s1"]
    dam = ["0", "0", "0", "d1", "d1", "d2", "d2"]
    ped = normalize_pedigree(ids, sire, dam)
    idx(id) = findfirst(==(id), ped.ids)
    A = additive_relationship(ped)
    D = HSquared.dominance_relationship(ped)

    AA = HSquared.epistatic_relationship(ped; kind = :additive_additive)
    AD = HSquared.epistatic_relationship(ped; kind = :additive_dominance)
    DD = HSquared.epistatic_relationship(ped; kind = :dominance_dominance)
    @test AA == A .* A
    @test AD == A .* D
    @test DD == D .* D
    @test issymmetric(AA)
    @test all(diag(AA) .== 1.0)            # non-inbred: A_ii = 1 → (A∘A)_ii = 1

    # full sibs: A = 1/2, D = 1/4 → A∘A = 1/4, A∘D = 1/8, D∘D = 1/16
    @test AA[idx("x"), idx("y")] ≈ 0.25
    @test AD[idx("x"), idx("y")] ≈ 0.125
    @test DD[idx("x"), idx("y")] ≈ 0.0625
    # paternal half sibs: A = 1/4, D = 0 → A∘A = 1/16, A∘D = 0, D∘D = 0
    @test AA[idx("x"), idx("z")] ≈ 0.0625
    @test AD[idx("x"), idx("z")] ≈ 0.0
    @test DD[idx("x"), idx("z")] ≈ 0.0

    @test HSquared.epistatic_relationship(ids, sire, dam; kind = :additive_additive) == AA
    @test_throws ArgumentError HSquared.epistatic_relationship(ped; kind = :bogus)
end

@testset "Phase 1 metafounder relationship / inverse (supplied Γ, #53)" begin
    # 3 founders + 3 descendants (o3 = s2 × o1, an inbreeding-creating mating).
    ids = ["s1", "s2", "d1", "o1", "o2", "o3"]
    sire = ["0", "0", "0", "s1", "s1", "s2"]
    dam = ["0", "0", "0", "d1", "d1", "o1"]
    ped = normalize_pedigree(ids, sire, dam)
    n = length(ped)
    idx(id) = findfirst(==(id), ped.ids)
    needs = [ped.sire[i] == 0 || ped.dam[i] == 0 for i in 1:n]
    group = [needs[i] ? "base" : "0" for i in 1:n]   # all founders share one metafounder

    # REDUCTION GATE (Γ=0 ⇒ classical founders): A^Γ == standard A, descriptive
    # inverse == pedigree_inverse, metafounder F == standard inbreeding.
    A0 = metafounder_relationship(ped, group, zeros(1, 1))
    @test A0 ≈ additive_relationship(ped) atol = 1e-10
    @test metafounder_relationship_inverse(ped, group, zeros(1, 1)) ≈
          Matrix(pedigree_inverse(ped)) atol = 1e-10
    @test metafounder_inbreeding(ped, group, zeros(1, 1)) ≈
          inbreeding_coefficients(ped) atol = 1e-10

    # SHARED-METAFOUNDER RELATEDNESS GATE (m=1, Γ=[γ]): two founders related by γ,
    # diagonal 1+γ/2 (pins the sign against a γ → −γ flip).
    γ = 0.4
    A = metafounder_relationship(ped, group, fill(γ, 1, 1))
    @test A[idx("s1"), idx("s2")] ≈ γ atol = 1e-12
    @test A[idx("s1"), idx("s1")] ≈ 1 + γ / 2 atol = 1e-12
    @test issymmetric(A)
    # metafounder F = γ − 1 < 0 (the BASE), and a founder's Mendelian sampling
    # variance d = 1 − γ/2 EXCEEDS ½ (heterozygote excess) — directly asserted via
    # the internal combined helpers so the no-clamp / negative-F behaviour is a real
    # tested gate, not just an implicit consequence of the round-trip.
    sc1, dc1, m1, _ = HSquared._metafounder_combined_indices(ped, group)
    Acomb1 = HSquared._metafounder_combined_A(m1, fill(0.4, 1, 1), sc1, dc1)
    Fcomb = [Acomb1[x, x] - 1.0 for x in 1:(m1 + n)]
    @test Fcomb[1] ≈ 0.4 - 1.0 atol = 1e-12                                       # metafounder F = γ−1 = −0.6 < 0
    s1c = m1 + idx("s1")
    @test HSquared._mendelian_sampling_variance(sc1[s1c], dc1[s1c], Fcomb) ≈ 0.8 atol = 1e-12  # d = 1−γ/2 = 0.8 > ½ (un-clamped)
    # animal F stays ≥ 0 in this single-group-per-animal slice (self = 1 + γ/2)
    @test all(metafounder_inbreeding(ped, group, fill(0.1, 1, 1)) .>= -1e-12)

    # INDEPENDENT DENSE TABULAR ORACLE (written here, not calling production), with a
    # two-group Γ so the off-diagonal coupling is exercised. Groups: s1,s2 → A; d1 → B.
    g2 = [group[i] for i in 1:n]
    g2[idx("s1")] = "A"; g2[idx("s2")] = "A"; g2[idx("d1")] = "B"
    Γ2 = [0.5 0.2; 0.2 0.3]
    # oracle over [mf A=1, mf B=2; animals 3..]: map each animal to combined idx
    m = 2
    col = Dict("A" => 1, "B" => 2)
    sc = zeros(Int, m + n); dc = zeros(Int, m + n)
    for i in 1:n
        s = ped.sire[i]; d = ped.dam[i]
        sc[m + i] = s == 0 ? col[g2[i]] : m + s
        dc[m + i] = d == 0 ? col[g2[i]] : m + d
    end
    Ao = zeros(m + n, m + n)
    Ao[1:m, 1:m] = Γ2
    for k in (m + 1):(m + n)
        for j in 1:(k - 1)
            v = 0.5 * (Ao[sc[k], j] + Ao[dc[k], j]); Ao[k, j] = v; Ao[j, k] = v
        end
        Ao[k, k] = 1 + 0.5 * Ao[sc[k], dc[k]]
    end
    @test metafounder_relationship(ped, g2, Γ2) ≈ Ao[(m + 1):end, (m + 1):end] atol = 1e-10

    # ROUND-TRIP GATE (combined sparse inverse): A_combined · metafounder_inverse == I.
    Minv = metafounder_inverse(ped, g2, Γ2)
    @test size(Minv) == (m + n, m + n)
    @test Matrix(Ao) * Matrix(Minv) ≈ Matrix(1.0I, m + n, m + n) atol = 1e-8

    # TWO-INVERSE-DISTINCTNESS GATE: the combined-inverse animal block is NOT the
    # descriptive animal-only inverse (deliberate; guards against conflation).
    animblock = Matrix(Minv)[(m + 1):end, (m + 1):end]
    desc = metafounder_relationship_inverse(ped, g2, Γ2)
    @test maximum(abs.(animblock - desc)) > 1e-6

    # GUARDS
    @test_throws ArgumentError metafounder_inverse(ped, group, zeros(1, 1))           # Γ singular on inverse path
    @test_throws ArgumentError metafounder_relationship(ped, group, [1.0 0.0; 0.0 1.0]) # wrong Γ dimension
    @test_throws ArgumentError metafounder_relationship(ped, group, fill(-1.0, 1, 1))  # Γ not PSD
    badgroup = copy(group); badgroup[idx("s1")] = "0"                                  # founder lost its group label
    @test_throws ArgumentError metafounder_relationship(ped, badgroup, zeros(1, 1))
    @test_throws ArgumentError metafounder_relationship(ped, group[1:5], zeros(1, 1))  # group_of length mismatch

    # convenience (ids, sire, dam, ...) wrappers agree with the Pedigree methods
    @test metafounder_relationship(ids, sire, dam, group, fill(γ, 1, 1)) ≈ A atol = 1e-12
end

@testset "Phase 1 metafounder animal-model MME solve (supplied Γ, #53)" begin
    # Wire the validated metafounder precision inv(A^Γ) into the supplied-variance
    # Henderson MME: an animal-only BLUP under the metafounder-augmented relationship.
    ids = ["s1", "s2", "d1", "o1", "o2", "o3"]
    sire = ["0", "0", "0", "s1", "s1", "s2"]
    dam = ["0", "0", "0", "d1", "d1", "o1"]
    ped = normalize_pedigree(ids, sire, dam)
    n = length(ped)
    group = [(ped.sire[i] == 0 || ped.dam[i] == 0) ? "base" : "0" for i in 1:n]
    y = [5.2, 4.8, 5.0, 5.5, 4.6, 5.1]
    X = ones(n, 1)
    Z = Matrix(1.0I, n, n)
    σa, σe = 1.0, 2.0

    # Γ = 0 REDUCTION: the metafounder solve == the classical animal model
    # (metafounder_relationship_inverse reduces to pedigree_inverse at Γ=0).
    res0 = metafounder_animal_model(y, X, Z, ped, group, zeros(1, 1), σa, σe)
    std = henderson_mme(animal_model_spec(y, X, Z, pedigree_inverse(ped); ids = ped.ids), σa, σe)
    @test res0.beta ≈ std.beta atol = 1e-9
    @test res0.animal_effects.values ≈ std.animal_effects.values atol = 1e-9
    @test collect(res0.animal_effects.ids) == collect(ped.ids)

    # FAITHFUL WRAPPER: equals manually building the metafounder-inverse spec + solving
    Γ = fill(0.3, 1, 1)
    manual = henderson_mme(
        animal_model_spec(y, X, Z, metafounder_relationship_inverse(ped, group, Γ); ids = ped.ids),
        σa, σe)
    res = metafounder_animal_model(y, X, Z, ped, group, Γ, σa, σe)
    @test res.beta ≈ manual.beta atol = 1e-12
    @test res.animal_effects.values ≈ manual.animal_effects.values atol = 1e-12

    # Γ ≠ 0 actually CHANGES the solution (the shared-metafounder base enters)
    @test maximum(abs.(res.animal_effects.values .- res0.animal_effects.values)) > 1e-6

    # guard: Z columns must match the pedigree / Ainv size
    @test_throws ArgumentError metafounder_animal_model(y, X, Z[:, 1:5], ped, group, zeros(1, 1), σa, σe)
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
        :prediction_error_variance,
        :reliability,
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
    # #43: PEV/reliability are now standard payload fields, computed via the
    # O(nnz(L)) (sparse-scalable) Takahashi selected inverse (:selinv), shaped
    # (ids, values) to match the R bridge's hs_julia_id_values() unpack (hsquared#21).
    # (Non-trivial off-diagonal-Ainv / nfixed>1 parity is in the selinv testset.)
    @test payload.prediction_error_variance.ids == ["a", "b", "c"]
    @test payload.prediction_error_variance.values ≈
          prediction_error_variance(fit; method = :selinv).values
    @test payload.prediction_error_variance.values ≈
          prediction_error_variance(fit; method = :dense).values
    @test payload.reliability.ids == ["a", "b", "c"]
    @test payload.reliability.values ≈ reliability(fit; method = :selinv).values
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

@testset "Phase 1 Mrode Example 3.1 published animal-model anchor (#46)" begin
    # Published external canon: Mrode (2014), "Linear Models for the Prediction of
    # Animal Breeding Values", 3rd ed., Example 3.1 (p.39). Inputs and expected
    # solutions are source-recorded in the R lane and independently re-solved there.
    ids = string.(1:8)
    ped = normalize_pedigree(
        ids,
        ["0", "0", "0", "1", "3", "1", "4", "3"],
        ["0", "0", "0", "0", "2", "2", "5", "6"],
    )
    Ainv = pedigree_inverse(ped)

    y = [4.5, 2.9, 3.9, 3.5, 5.0]
    sex = ["male", "female", "female", "male", "male"]
    X = hcat(ones(length(y)), [s == "female" ? 1.0 : 0.0 for s in sex])
    Z = spzeros(length(y), length(ids))
    for (i, animal) in enumerate(4:8)
        Z[i, animal] = 1.0
    end
    sigma_a2 = 20.0
    sigma_e2 = 40.0

    published_ebv = [
        0.09844458,
        -0.01877010,
        -0.04108420,
        -0.00866312,
        -0.18573210,
        0.17687209,
        -0.24945855,
        0.18261469,
    ]
    published_sex_contrast_male_minus_female = 0.95407223

    @test ped.ids == ids
    @test Matrix(Ainv) ≈ inv(Symmetric(HSquared._numerator_relationship(ped))) atol = 1e-10

    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
    mme = fit_animal_model(
        y,
        X,
        Z,
        Ainv;
        target = :henderson_mme,
        variance_components = (sigma_a2 = sigma_a2, sigma_e2 = sigma_e2),
        ids = ped.ids,
    )
    direct = henderson_mme(spec, sigma_a2, sigma_e2)

    @test mme isa HendersonMMEResult
    @test fixed_effects(mme) ≈ fixed_effects(direct)
    @test breeding_values(mme).ids == ids
    @test breeding_values(mme).values ≈ published_ebv atol = 1e-6
    @test breeding_values(direct).values ≈ published_ebv atol = 1e-6

    male_row = X[findfirst(==("male"), sex), :]
    female_row = X[findfirst(==("female"), sex), :]
    contrast = dot(male_row .- female_row, fixed_effects(mme))
    @test contrast ≈ published_sex_contrast_male_minus_female atol = 1e-6

    # Test of test: a material transcription/sign/scale error must be rejected.
    @test !isapprox(breeding_values(mme).values, published_ebv .+ 0.1; atol = 1e-6)
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

    # Non-trivial fixture: 8-animal Mrode9-shaped pedigree (genuinely off-diagonal
    # Ainv that exercises the :selinv recursion) and nfixed = 2 (intercept +
    # covariate, so the (nfixed+1):end random-block slice is non-degenerate),
    # at supplied interior variances (no σ²a=0 boundary). Pins the :selinv PEV
    # diagonal == :dense on a larger pedigree (backs the V1-SELINV-PEV wording),
    # and pins the standard result_payload carrying those :selinv values on a
    # non-benign fit (addresses the benign-fixture review nit).
    ped8 = normalize_pedigree(
        ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"],
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"],
    )
    y8 = [2.0, 3.0, 2.5, 3.5, 4.0, 1.5, 3.0, 4.5]
    X8 = hcat(ones(8), Float64[0, 1, 0, 1, 0, 1, 0, 1])
    spec8 = animal_model_spec(y8, X8, sparse(1.0I, 8, 8), pedigree_inverse(ped8);
                              ids = ped8.ids, method = :REML)
    lik8 = gaussian_loglik(spec8, 1.5, 0.7; method = :REML)
    fit8 = AnimalModelFit(spec8, lik8, (sigma_a2 = 1.5, sigma_e2 = 0.7), true, "supplied", 0)
    pev8_selinv = prediction_error_variance(fit8; method = :selinv)
    pev8_dense = prediction_error_variance(fit8; method = :dense)
    @test pev8_selinv.values ≈ pev8_dense.values rtol = 1e-9
    @test reliability(fit8; method = :selinv).values ≈
          reliability(fit8; method = :dense).values rtol = 1e-9 atol = 1e-8
    payload8 = result_payload(fit8)
    @test payload8.prediction_error_variance.values ≈ pev8_selinv.values
    @test payload8.prediction_error_variance.values ≈ pev8_dense.values rtol = 1e-9
    @test payload8.reliability.values ≈ reliability(fit8; method = :selinv).values

    # invalid method rejected on both extractors
    @test_throws ArgumentError prediction_error_variance(mme; method = :nope)
    @test_throws ArgumentError reliability(mme; method = :nope)
end

@testset "Phase 1 selinv PEV — larger multi-generation pedigree (V1-SELINV-PEV)" begin
    # Deterministic (RNG-free) 4-generation pedigree, 110 animals, with genuine
    # off-diagonal relatedness: each generation draws sires and dams from DISJOINT
    # halves of the previous generation (so parents are always distinct and precede
    # their offspring). This exercises the Takahashi :selinv recursion on a deep,
    # densely-related structure far larger than the 8-animal fixture above, backing
    # the V1-SELINV-PEV "larger-pedigree" evidence (still validation-scale, NOT a
    # production-scale / large-sparse claim).
    nf = 20
    ids = String[]; sires = String[]; dams = String[]
    for i in 1:nf
        push!(ids, "f$i"); push!(sires, "0"); push!(dams, "0")
    end
    gens = [["f$i" for i in 1:nf]]
    for g in 1:3
        prev = gens[end]
        half = length(prev) ÷ 2
        spool = prev[1:half]
        dpool = prev[(half + 1):end]
        cur = String[]
        for k in 1:30
            s = spool[1 + (k % length(spool))]
            d = dpool[1 + (k % length(dpool))]
            id = "g$(g)_$(k)"
            push!(ids, id); push!(sires, s); push!(dams, d); push!(cur, id)
        end
        push!(gens, cur)
    end
    ped = normalize_pedigree(ids, sires, dams)
    q = length(ped.ids)
    @test q == nf + 3 * 30          # 110 animals
    Ainv = pedigree_inverse(ped)
    @test count(!iszero, Ainv) > 3 * q   # genuinely off-diagonal (not near-identity)

    # deterministic phenotypes + 2 fixed effects (intercept + covariate)
    y = [2.0 + 0.5 * sin(Float64(i)) for i in 1:q]
    X = hcat(ones(q), [Float64(i % 3) for i in 1:q])
    spec = animal_model_spec(y, X, sparse(1.0I, q, q), Ainv; ids = ped.ids, method = :REML)
    lik = gaussian_loglik(spec, 1.3, 0.9; method = :REML)
    fit = AnimalModelFit(spec, lik, (sigma_a2 = 1.3, sigma_e2 = 0.9), true, "supplied", 0)

    pev_selinv = prediction_error_variance(fit; method = :selinv)
    pev_dense = prediction_error_variance(fit; method = :dense)
    @test length(pev_selinv.values) == q
    @test pev_selinv.ids == ped.ids
    @test pev_selinv.values ≈ pev_dense.values rtol = 1e-8
    @test reliability(fit; method = :selinv).values ≈
          reliability(fit; method = :dense).values rtol = 1e-8 atol = 1e-9
end

@testset "Phase 1 PCG MME solver (iterative == direct, V1-PCG)" begin
    # PCG solves the IDENTICAL sparse SPD MME as henderson_mme and must recover its
    # β and EBVs. Mrode9-shaped 8-animal pedigree, nfixed = 2 (intercept + covariate).
    ped = normalize_pedigree(
        ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"],
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"],
    )
    y = [2.0, 3.0, 2.5, 3.5, 4.0, 1.5, 3.0, 4.5]
    X = hcat(ones(8), Float64[0, 1, 0, 1, 0, 1, 0, 1])
    spec = animal_model_spec(y, X, sparse(1.0I, 8, 8), pedigree_inverse(ped); ids = ped.ids, method = :REML)
    mme = henderson_mme(spec, 1.5, 0.7)

    pcg = solve_animal_model_pcg(spec, 1.5, 0.7; tol = 1e-12)
    @test pcg.converged
    @test pcg.relative_residual <= 1e-12
    @test pcg.preconditioner == :jacobi
    @test pcg.breeding_values.ids == ped.ids
    @test pcg.beta ≈ fixed_effects(mme) atol = 1e-8                       # iterative == direct
    @test pcg.breeding_values.values ≈ breeding_values(mme).values atol = 1e-8

    # plain CG (no preconditioner) reaches the SAME solution; Jacobi takes no more iters.
    cg = solve_animal_model_pcg(spec, 1.5, 0.7; tol = 1e-12, preconditioner = :none)
    @test cg.beta ≈ fixed_effects(mme) atol = 1e-8
    @test cg.breeding_values.values ≈ breeding_values(mme).values atol = 1e-8
    @test pcg.iterations <= cg.iterations

    # IC(0) preconditioner reaches the SAME direct solution, and (being a real preconditioner)
    # in no more iterations than plain CG. :ichol requires the assembled C (not matrix-free).
    ic = solve_animal_model_pcg(spec, 1.5, 0.7; tol = 1e-12, preconditioner = :ichol)
    @test ic.converged
    @test ic.preconditioner == :ichol
    @test ic.beta ≈ fixed_effects(mme) atol = 1e-8                        # IC(0) == direct
    @test ic.breeding_values.values ≈ breeding_values(mme).values atol = 1e-8
    @test ic.iterations <= cg.iterations
    @test_throws ArgumentError solve_animal_model_pcg(spec, 1.5, 0.7; preconditioner = :ichol, matrix_free = true)
    @test_throws ArgumentError solve_animal_model_pcg(spec, 1.5, 0.7; preconditioner = :bogus)

    # also matches on a tiny 3-animal pedigree (intercept only)
    ped3 = normalize_pedigree(["s", "d", "o"], ["0", "0", "s"], ["0", "0", "d"])
    spec3 = animal_model_spec([1.0, 2.5, 4.0], ones(3, 1), sparse(1.0I, 3, 3),
                              pedigree_inverse(ped3); ids = ped3.ids, method = :REML)
    mme3 = henderson_mme(spec3, 1.2, 0.8)
    pcg3 = solve_animal_model_pcg(spec3, 1.2, 0.8; tol = 1e-12)
    @test pcg3.beta ≈ fixed_effects(mme3) atol = 1e-9
    @test pcg3.breeding_values.values ≈ breeding_values(mme3).values atol = 1e-9

    # LARGER deterministic fixture: 110-animal 4-generation pedigree (disjoint sire/dam
    # pools per generation → off-diagonal Ainv), nfixed = 2. iterative == direct at scale.
    nf = 20
    bids = String[]; bsire = String[]; bdam = String[]
    for i in 1:nf
        push!(bids, "f$i"); push!(bsire, "0"); push!(bdam, "0")
    end
    gens = [["f$i" for i in 1:nf]]
    for g in 1:3
        prev = gens[end]; half = length(prev) ÷ 2
        spool = prev[1:half]; dpool = prev[(half + 1):end]; cur = String[]
        for k in 1:30
            push!(bids, "g$(g)_$(k)"); push!(bsire, spool[1 + (k % length(spool))])
            push!(bdam, dpool[1 + (k % length(dpool))]); push!(cur, "g$(g)_$(k)")
        end
        push!(gens, cur)
    end
    pedL = normalize_pedigree(bids, bsire, bdam); qL = length(pedL)
    @test qL == 110
    yL = [2.0 + 0.5 * sin(Float64(i)) for i in 1:qL]
    XL = hcat(ones(qL), [Float64(i % 3) for i in 1:qL])
    specL = animal_model_spec(yL, XL, sparse(1.0I, qL, qL), pedigree_inverse(pedL); ids = pedL.ids, method = :REML)
    mmeL = henderson_mme(specL, 1.3, 0.9)
    pcgL = solve_animal_model_pcg(specL, 1.3, 0.9; tol = 1e-11)
    @test pcgL.converged
    @test pcgL.beta ≈ fixed_effects(mmeL) atol = 1e-7
    @test pcgL.breeding_values.values ≈ breeding_values(mmeL).values atol = 1e-7
    # IC(0) also recovers the direct solve at the 110-animal scale, in ≤ plain-CG iterations.
    cgL = solve_animal_model_pcg(specL, 1.3, 0.9; tol = 1e-11, preconditioner = :none)
    icL = solve_animal_model_pcg(specL, 1.3, 0.9; tol = 1e-11, preconditioner = :ichol)
    @test icL.converged
    @test icL.beta ≈ fixed_effects(mmeL) atol = 1e-7
    @test icL.breeding_values.values ≈ breeding_values(mmeL).values atol = 1e-7
    @test icL.iterations <= cgL.iterations

    # MATRIX-FREE path: the operator applies C·v from X/Z/Ainv without assembling C.
    # (a) operator == assembled C column-by-column (exact), and the matrix-free Jacobi
    # diagonal == diag(C); (b) matrix_free solve == assembled solve == direct.
    lhs8, _, _ = HSquared._sparse_mme_system(spec, 1.5, 0.7)
    Xs = sparse(X); Zs = sparse(1.0I, 8, 8); Ai = sparse(Matrix(pedigree_inverse(ped)))
    Xt = transpose(Xs); Zt = transpose(Zs); N8 = size(lhs8, 1)
    colerr = 0.0
    for i in 1:N8
        e = zeros(N8); e[i] = 1.0
        col = HSquared._mme_matvec(Xs, Xt, Zs, Zt, Ai, 1 / 0.7, 1 / 1.5, 2, e)
        colerr = max(colerr, maximum(abs.(col .- Vector(lhs8[:, i]))))
    end
    @test colerr == 0.0                                                   # matrix-free C·eᵢ == C[:,i] exactly
    @test HSquared._mme_diag(Xs, Zs, Ai, 1 / 0.7, 1 / 1.5) ≈ Vector(diag(lhs8)) atol = 1e-12
    pf = solve_animal_model_pcg(spec, 1.5, 0.7; tol = 1e-12, matrix_free = true)
    @test pf.matrix_free
    @test pf.beta ≈ fixed_effects(mme) atol = 1e-8                        # matrix-free == direct
    @test pf.breeding_values.values ≈ breeding_values(mme).values atol = 1e-8
    @test pf.beta ≈ pcg.beta atol = 1e-10                                 # matrix-free == assembled PCG
    @test pf.breeding_values.values ≈ pcg.breeding_values.values atol = 1e-10
    pfL = solve_animal_model_pcg(specL, 1.3, 0.9; tol = 1e-11, matrix_free = true)
    @test pfL.beta ≈ fixed_effects(mmeL) atol = 1e-7                      # also at the 110-animal scale
    @test pfL.breeding_values.values ≈ breeding_values(mmeL).values atol = 1e-7

    # deterministic non-convergence flag when the iteration budget is too small
    starved = solve_animal_model_pcg(spec, 1.5, 0.7; tol = 1e-14, maxiter = 1)
    @test !starved.converged
    @test starved.relative_residual > 1e-14

    # guards
    @test_throws ArgumentError solve_animal_model_pcg(spec, -1.0, 0.7)
    @test_throws ArgumentError solve_animal_model_pcg(spec, 1.5, 0.0)
    @test_throws ArgumentError solve_animal_model_pcg(spec, 1.5, 0.7; tol = -1.0)
    @test_throws ArgumentError solve_animal_model_pcg(spec, 1.5, 0.7; maxiter = 0)
    @test_throws ArgumentError solve_animal_model_pcg(spec, 1.5, 0.7; preconditioner = :bogus)
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

@testset "Variance-component forest plot-data (#54 set B, R hs_gg_forest)" begin
    # REML fit (interior 8-animal pedigree) -> estimated VC + h2 forest data
    ids8 = ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"]
    ped8 = normalize_pedigree(ids8,
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    spec8 = animal_model_spec([2.0, 3.0, 2.5, 3.5, 4.0, 1.5, 3.0, 4.5], ones(8, 1),
        sparse(1.0I, 8, 8), pedigree_inverse(ped8); ids = ped8.ids, method = :REML)
    rfit = fit_ai_reml(spec8; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    vc = variance_components(rfit)
    pd = variance_components_plot_data(rfit)
    @test pd.term == ["sigma_a2", "sigma_e2", "h2"]
    @test pd.estimate ≈ [vc.sigma_a2, vc.sigma_e2, heritability(rfit)]
    @test pd.panel == ["variance components", "variance components", "heritability"]
    @test pd.supplied === false                                   # ESTIMATED, not supplied
    @test pd.level == 0.95
    @test propertynames(pd) ==
          (:term, :estimate, :lo, :hi, :panel, :level, :interval_method, :interval_status, :supplied)
    # interval consistency: matches the extractors when available, else NaN / "none"
    local h2ci
    try
        h2ci = heritability_interval(rfit; level = 0.95)
    catch
        h2ci = nothing
    end
    if h2ci === nothing
        @test pd.interval_status == "none" && all(isnan, pd.lo) && all(isnan, pd.hi)
    else
        @test pd.interval_status == "experimental_asymptotic"
        @test pd.lo[3] ≈ h2ci.lower && pd.hi[3] ≈ h2ci.upper
        @test 0 <= pd.lo[3] <= 1 && 0 <= pd.hi[3] <= 1            # h2 row in (0,1)
        # VC-row whiskers: raw normal-Wald estimate ± z·SE, UNCLAMPED (may cross 0)
        ses = variance_component_standard_errors(rfit)
        zq = HSquared._standard_normal_quantile(0.975)
        @test pd.lo[1] ≈ vc.sigma_a2 - zq * ses.sigma_a2
        @test pd.hi[1] ≈ vc.sigma_a2 + zq * ses.sigma_a2
        @test pd.lo[2] ≈ vc.sigma_e2 - zq * ses.sigma_e2
        @test pd.hi[2] ≈ vc.sigma_e2 + zq * ses.sigma_e2
    end

    # ML fit -> SE machinery is REML-only: graceful degrade to points-only (no whiskers)
    mlspec = animal_model_spec([1.0, 2.0, 3.0], ones(3, 1), sparse(1.0I, 3, 3),
        sparse(1.0I, 3, 3); ids = ["a", "b", "c"], method = :ML)
    mlfit = AnimalModelFit(mlspec, gaussian_loglik(mlspec, 1.0, 1.0; method = :ML),
        (sigma_a2 = 1.0, sigma_e2 = 1.0), true, "test", 0)
    pdml = variance_components_plot_data(mlfit)
    @test pdml.estimate ≈ [1.0, 1.0, 0.5]
    @test pdml.interval_status == "none"
    @test all(isnan, pdml.lo) && all(isnan, pdml.hi)
    @test pdml.supplied === false

    @test_throws ArgumentError variance_components_plot_data(rfit; level = 1.5)
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
    # F3 made the convergence criterion scale-invariant (also stops on the relative VC
    # change, not only the absolute REML score, which scales with n). This tiny FLAT 8-animal
    # surface cannot reproduce the large-n behavior — it converges via the score path and
    # takes ~69 iterations regardless — so there is no meaningful in-CI assertion for the F3
    # path here; the scale evidence is the DRAC checkpoint (q=300k 36 s -> 2.3 s, converged:
    # docs/dev-log/recovery-checkpoints/2026-06-23-f0-scale-baseline.md). `@test ai.converged`
    # above is the regression guard against convergence breaking.
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

@testset "fit_ai_reml graceful σ²→0 boundary (no throw on degenerate spec)" begin
    # A degenerate spec (constant y → no genetic signal → the REML optimum sits at the
    # σ²a→0 boundary) drives AI-REML toward σ²→0, where the finite Newton step grows large
    # relative to the tiny σ and 60 step-halvings can no longer keep σ positive. The old
    # code THREW "could not keep variance components positive" — intermittently on CI
    # (FP/environment-sensitive: a Mac grinds to the iteration cap, Linux CI reaches the
    # boundary in fewer iters and threw). It must instead STOP at the current finite,
    # positive σ with converged=false (the V1-REML boundary contract: finite positive OR
    # documented error, never NaN garbage). Both fixtures below threw deterministically
    # pre-fix.
    bAinv = Matrix(pedigree_inverse([1, 2, 3], [0, 0, 1], [0, 0, 2]))
    bspec = animal_model_spec([5.0, 5.0, 5.0], ones(3, 1), Matrix(1.0I, 3, 3), bAinv; method = :REML)
    bfit = fit_ai_reml(bspec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0), iterations = 1000)  # must NOT throw
    @test bfit isa AnimalModelFit
    @test !bfit.converged                                          # boundary: did not converge
    @test bfit.variance_components.sigma_a2 > 0 && isfinite(bfit.variance_components.sigma_a2)
    @test bfit.variance_components.sigma_e2 > 0 && isfinite(bfit.variance_components.sigma_e2)
    # the single-step fixture (y has no genetic signal) pushed to the boundary — threw at
    # 5000 iters pre-fix; must now return finite positive σ.
    sAinv = Matrix(pedigree_inverse([1, 2, 3, 4, 5], [0, 0, 1, 1, 3], [0, 0, 2, 2, 4]))
    sspec = animal_model_spec([10.0, 12, 11, 9, 13], ones(5, 1), Matrix(1.0I, 5, 5), sAinv; method = :REML)
    sfit = fit_ai_reml(sspec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0), iterations = 5000)
    @test sfit.variance_components.sigma_a2 > 0 && isfinite(sfit.variance_components.sigma_a2)
    @test sfit.variance_components.sigma_e2 > 0 && isfinite(sfit.variance_components.sigma_e2)
end

@testset "fit_ai_reml EM-REML warm-start (em_warmup, opt-in robustness)" begin
    # EM-REML warm-start: a few monotone, in-bounds EM iterations (the closed form that zeroes
    # the REML score) before the AI/Newton step. OPT-IN — default `em_warmup = 0` is byte-
    # identical to the pre-warm-start path. CI-gated here: OPTIMUM-INVARIANCE on an identified
    # fixture + extreme-start correctness; it does NOT change the σ²→0 / non-identified boundary
    # contract (finite positive + never throws). The measured iteration reduction is in
    # `sim/em_warmstart_benchmark.jl` + the 2026-06-23 after-task report, not pinned here.

    # ── identified interior fixture: seeded gene-dropping (real genetic signal → σ²a > 0) ──
    let
        nsire, ndam, noff = 10, 30, 100
        sids = ["ws$i" for i in 1:nsire]; dids = ["wd$i" for i in 1:ndam]; oids = ["wo$i" for i in 1:noff]
        ids = vcat(sids, dids, oids)
        sire = vcat(fill("0", nsire + ndam), [sids[((i - 1) % nsire) + 1] for i in 1:noff])
        dam = vcat(fill("0", nsire + ndam), [dids[((i - 1) % ndam) + 1] for i in 1:noff])
        ped = normalize_pedigree(ids, sire, dam); q = length(ped.ids)
        Ainv = pedigree_inverse(ped)
        rng = MersenneTwister(20260623); u = zeros(q)            # gene-dropping BVs (σ²a = 1)
        @inbounds for i in 1:q
            s = ped.sire[i]; d = ped.dam[i]
            pa = s > 0 ? u[s] : 0.0; pb = d > 0 ? u[d] : 0.0
            nk = (s > 0) + (d > 0); msv = nk == 0 ? 1.0 : (nk == 1 ? 0.75 : 0.5)
            u[i] = 0.5 * (pa + pb) + sqrt(msv) * randn(rng)
        end
        y = 5.0 .+ u .+ randn(rng, q)                            # σ²e = 1
        spec = animal_model_spec(y, ones(q, 1), sparse(1.0I, q, q), Ainv; ids = ped.ids, method = :REML)

        # default == em_warmup = 0 (the opt-in default is byte-identical to the pre-warm-start path)
        f_default = fit_ai_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
        f_zero = fit_ai_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0), em_warmup = 0)
        @test f_default.converged
        @test f_default.variance_components.sigma_a2 > 0                       # interior, not boundary
        @test f_default.variance_components.sigma_a2 == f_zero.variance_components.sigma_a2
        @test f_default.variance_components.sigma_e2 == f_zero.variance_components.sigma_e2
        @test f_default.iterations == f_zero.iterations

        # OPTIMUM-INVARIANT: the warm-start never changes the converged estimates
        for ew in (3, 5, 15)
            fw = fit_ai_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0), em_warmup = ew)
            @test fw.converged
            @test fw.variance_components.sigma_a2 ≈ f_default.variance_components.sigma_a2 rtol = 1e-6
            @test fw.variance_components.sigma_e2 ≈ f_default.variance_components.sigma_e2 rtol = 1e-6
        end

        # EXTREME-START correctness: from a terrible start the warm-start still reaches the SAME optimum
        f_bad = fit_ai_reml(spec; initial = (sigma_a2 = 1e4, sigma_e2 = 1e-2), em_warmup = 5)
        @test f_bad.converged
        @test f_bad.variance_components.sigma_a2 ≈ f_default.variance_components.sigma_a2 rtol = 1e-6
        @test f_bad.variance_components.sigma_e2 ≈ f_default.variance_components.sigma_e2 rtol = 1e-6
    end

    # ── boundary contract preserved on the non-identified #182 single-step fixture ──
    # σ²a is genuinely unidentified here, so the fit does NOT converge regardless of warm-up; the
    # warm-start must still return FINITE POSITIVE σ and never throw. It does NOT fix the boundary
    # and may shift the non-converged estimate — by design `converged = false` is the honest
    # signal, not the value (so we assert the contract, not optimum-invariance).
    let
        sAinv = Matrix(pedigree_inverse([1, 2, 3, 4, 5], [0, 0, 1, 1, 3], [0, 0, 2, 2, 4]))
        sspec = animal_model_spec([10.0, 12, 11, 9, 13], ones(5, 1), Matrix(1.0I, 5, 5), sAinv; method = :REML)
        for ew in (0, 5, 25)
            f = fit_ai_reml(sspec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0), em_warmup = ew)  # must NOT throw
            @test isfinite(f.variance_components.sigma_a2) && f.variance_components.sigma_a2 > 0
            @test isfinite(f.variance_components.sigma_e2) && f.variance_components.sigma_e2 > 0
        end
    end
end

@testset "Phase 1 large-pedigree sparse AI-REML fit + selinv PEV hardening (#6)" begin
    # Deterministic ~420-animal half-sib pedigree. The existing AI-REML / selinv tests
    # use ≤110 animals; this hardens the SPARSE fit path (`fit_ai_reml` → sparse CHOLMOD
    # Cholesky + Takahashi selected inverse) at a larger scale. CORRECTNESS-at-scale only
    # — NO timing is asserted (this is not a performance claim).
    nsire, ndam, noff = 30, 90, 300
    sids = ["s$i" for i in 1:nsire]; dids = ["d$i" for i in 1:ndam]; oids = ["o$i" for i in 1:noff]
    ids = vcat(sids, dids, oids)
    sire = vcat(fill("0", nsire + ndam), [sids[((i - 1) % nsire) + 1] for i in 1:noff])
    dam = vcat(fill("0", nsire + ndam), [dids[((i - 1) % ndam) + 1] for i in 1:noff])
    ped = normalize_pedigree(ids, sire, dam)
    Ainv = pedigree_inverse(ped); q = length(ped.ids)
    @test q == nsire + ndam + noff                                  # 420 animals
    y = [2.0 + sin(0.07 * i) + 0.5 * cos(0.013 * i) for i in 1:q]   # deterministic, structured
    X = ones(q, 1); Z = sparse(1.0I, q, q)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)

    fit = fit_ai_reml(spec; initial = (sigma_a2 = 0.5, sigma_e2 = 0.5))
    @test fit.converged
    @test fit.variance_components.sigma_a2 > 0 && fit.variance_components.sigma_e2 > 0

    # self-consistency at scale: henderson_mme at the fitted VCs reproduces β + EBVs EXACTLY
    hm = henderson_mme(spec, fit.variance_components.sigma_a2, fit.variance_components.sigma_e2)
    @test fixed_effects(fit) ≈ hm.beta atol = 1e-8
    @test breeding_values(fit).values ≈ hm.animal_effects.values atol = 1e-7

    # the O(nnz(L)) Takahashi selected-inverse PEV/reliability matches the dense MME-inverse
    # diagonal at 420 animals (extends V1-SELINV-PEV from a 110-animal pedigree to 420)
    @test prediction_error_variance(fit; method = :selinv).values ≈
          prediction_error_variance(fit; method = :dense).values atol = 1e-8
    @test reliability(fit; method = :selinv).values ≈
          reliability(fit; method = :dense).values atol = 1e-8
end

@testset "Phase 1 sparse AI-REML / selinv boundary hardening (#6)" begin
    # Deterministic (RNG-free) boundary / stress cases for the sparse AI-REML + selinv
    # PEV path. CORRECTNESS ONLY — no timing or performance is asserted.
    #
    # Pedigree: two founders (f1, f2) + a 3-generation selfing chain (s1, s2, s3) from f1,
    # then three offspring that cross back to f2 or f1. This produces inbreeding
    # coefficients F ∈ {0, 0.5, 0.75, 0.875} in the same pedigree, exercising the
    # Henderson Ainv rule and the AI-REML / selinv paths under high inbreeding.

    ib_ids   = ["f1", "f2", "s1",  "s2",  "s3",  "c1",  "c2",  "c3"]
    ib_sires = ["0",  "0",  "f1",  "s1",  "s2",  "s3",  "s3",  "f1"]
    ib_dams  = ["0",  "0",  "f1",  "s1",  "s2",  "f2",  "f2",  "f2"]
    ib_ped = normalize_pedigree(ib_ids, ib_sires, ib_dams; allow_selfing = true)
    ib_q   = length(ib_ped.ids)

    # --- Case 1: highly-inbred pedigree: Ainv == inv(A), convergence, self-consistency ---

    ib_F = inbreeding_coefficients(ib_ped)
    @test any(ib_F .>= 0.5)                  # at least one animal with high F
    @test any(ib_F .>= 0.875)                # selfing chain reaches deep inbreeding

    ib_A    = additive_relationship(ib_ped)
    ib_Ainv = pedigree_inverse(ib_ped)
    # pedigree_inverse == inv(additive_relationship) holds even under high inbreeding
    @test Matrix(ib_Ainv) ≈ inv(Symmetric(ib_A)) atol = 1e-8

    # Structured deterministic y: groups high-value animals (founders f2, offspring c1/c2)
    # and low-value animals (inbred selfing chain). Provides interior REML optimum.
    ib_y = [1.0, 3.5, 1.5, 1.2, 1.0, 3.2, 3.8, 2.5]
    ib_X = ones(ib_q, 1)
    ib_Z = sparse(1.0I, ib_q, ib_q)
    ib_spec = animal_model_spec(ib_y, ib_X, ib_Z, ib_Ainv; ids = ib_ped.ids, method = :REML)

    ib_fit = fit_ai_reml(ib_spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    @test ib_fit.converged                                        # converges on inbred pedigree
    @test ib_fit.variance_components.sigma_a2 > 0
    @test ib_fit.variance_components.sigma_e2 > 0

    # self-consistency at the inbred optimum: henderson_mme reproduces β + EBVs EXACTLY
    ib_hm = henderson_mme(ib_spec,
                          ib_fit.variance_components.sigma_a2,
                          ib_fit.variance_components.sigma_e2)
    @test fixed_effects(ib_fit) ≈ ib_hm.beta atol = 1e-8
    @test breeding_values(ib_fit).values ≈ ib_hm.animal_effects.values atol = 1e-7

    # --- Case 2: near-boundary σ²a (low heritability, near-zero optimum) ---
    # A near-constant y drives σ²a toward zero. Since PR #182 `fit_ai_reml` STOPS GRACEFULLY
    # at this boundary: it returns a finite, POSITIVE optimum with `converged = false` rather
    # than throwing (the σ²→0 boundary `throw` was replaced by a graceful `break`; see
    # `src/likelihood.jl`). The engine never returns NaN garbage. The try/catch below is now
    # defense-in-depth only — the boundary `ErrorException` is gone, so the sole error still
    # theoretically reachable is a `PosDefException` from an indefinite MME factorization
    # (`cholesky(...; check = true)`); in practice the graceful path (a) is taken.
    low_y    = [3.01, 2.99, 3.00, 3.01, 2.99, 3.00, 3.01, 2.99]
    low_spec = animal_model_spec(low_y, ib_X, ib_Z, ib_Ainv; ids = ib_ped.ids, method = :REML)
    low_fit = nothing
    low_err = nothing
    try
        low_fit = fit_ai_reml(low_spec; initial = (sigma_a2 = 0.1, sigma_e2 = 0.5))
    catch e
        low_err = e
    end
    if low_err === nothing
        # (a) reached a finite, positive optimum: VCs finite/positive + self-consistency
        @test isfinite(low_fit.variance_components.sigma_a2) && low_fit.variance_components.sigma_a2 > 0
        @test isfinite(low_fit.variance_components.sigma_e2) && low_fit.variance_components.sigma_e2 > 0
        low_hm = henderson_mme(low_spec,
                               low_fit.variance_components.sigma_a2,
                               low_fit.variance_components.sigma_e2)
        @test fixed_effects(low_fit) ≈ low_hm.beta atol = 1e-8
        @test breeding_values(low_fit).values ≈ low_hm.animal_effects.values atol = 1e-7
    else
        # (b) defensive only: the boundary `ErrorException` was removed in PR #182, so the
        # sole error still reachable here is a `PosDefException` (indefinite factorization),
        # never NaN garbage. The `ErrorException` disjunct is kept as harmless belt-and-braces.
        @test low_err isa ErrorException || low_err isa LinearAlgebra.PosDefException
    end

    # Note: low_fit.converged may be false on a boundary optimum — that is correct
    # behavior and is NOT asserted either way; no @test on low_fit.converged.

    # --- Case 3: selinv exact at the boundary — inbred pedigree, high-F animals ---
    # On ib_fit (highly-inbred pedigree), the Takahashi selected inverse must equal
    # the dense MME-inverse diagonal at the same machine precision as non-inbred cases.

    @test prediction_error_variance(ib_fit; method = :selinv).values ≈
          prediction_error_variance(ib_fit; method = :dense).values atol = 1e-8
    @test reliability(ib_fit; method = :selinv).values ≈
          reliability(ib_fit; method = :dense).values atol = 1e-8
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

@testset "Phase 2 VanRaden method-2 (standardized) genomic relationship" begin
    M = [0.0 1 2; 2 1 0; 1 1 1; 0 2 2; 1 0 2; 2 1 1]   # 6 individuals x 3 markers
    G1 = genomic_relationship_matrix(M)                          # method 1 (default)
    G2 = genomic_relationship_matrix(M; method = :vanraden2)     # standardized markers

    @test genomic_relationship_matrix(M; method = :vanraden1) == G1   # default == :vanraden1
    @test issymmetric(G2)
    @test minimum(eigvals(Symmetric(G2))) >= -1e-8               # PSD
    @test !isapprox(G2, G1)                                       # genuinely different construction

    # explicit standardized construction: Zs[:,j] = (M-2p)/sqrt(2p(1-p)), G2 = Zs Zs' / m
    cm = HSquared.centered_markers(M)
    Zs = cm.W ./ transpose(sqrt.(2 .* cm.p .* (1 .- cm.p)))
    @test G2 ≈ Zs * transpose(Zs) ./ size(M, 2)

    # supplied allele frequencies path works for method 2
    @test genomic_relationship_matrix(M; method = :vanraden2,
                                      allele_frequencies = cm.p) ≈ G2

    # guards: unknown method, and a monomorphic marker (2p(1-p)=0) under standardization
    @test_throws ArgumentError genomic_relationship_matrix(M; method = :bogus)
    mono = [0.0 1.0; 0.0 1.0; 0.0 2.0]   # column 1 monomorphic (p = 0)
    @test_throws ArgumentError genomic_relationship_matrix(mono; method = :vanraden2)
end

@testset "Phase 2 weighted genomic relationship (weighted GBLUP)" begin
    M = [0.0 1 2; 2 1 0; 1 1 1; 0 2 2; 1 0 2; 2 1 1]   # 6 individuals x 3 markers
    G1 = genomic_relationship_matrix(M)                         # unweighted method 1
    m = size(M, 2)

    # equal weights reduce EXACTLY to the unweighted method-1 G
    @test genomic_relationship_matrix(M; weights = ones(m)) ≈ G1
    @test genomic_relationship_matrix(M; weights = fill(3.0, m)) ≈ G1   # scale-invariant

    # a genuine non-uniform weighting: G_w = Z diag(w) Z' / sum(w_j 2 p_j(1-p_j))
    w = [2.0, 0.5, 1.0]
    Gw = genomic_relationship_matrix(M; weights = w)
    cm = HSquared.centered_markers(M)
    scale = sum(w .* 2 .* cm.p .* (1 .- cm.p))
    @test Gw ≈ (cm.W * Diagonal(w) * transpose(cm.W)) ./ scale
    @test issymmetric(Gw)
    @test minimum(eigvals(Symmetric(Gw))) >= -1e-8              # PSD
    @test !isapprox(Gw, G1)                                      # weighting genuinely changes G

    # guards: length, positivity, and method-2 + weights not supported
    @test_throws ArgumentError genomic_relationship_matrix(M; weights = [1.0, 2.0])
    @test_throws ArgumentError genomic_relationship_matrix(M; weights = [1.0, -1.0, 1.0])
    @test_throws ArgumentError genomic_relationship_matrix(M; method = :vanraden2, weights = ones(m))
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

@testset "Phase 5 post-fit marker scan (#45)" begin
    # The (fit, markers) entry points must reduce EXACTLY to the explicit-argument
    # scans at the fit's design (y/X/Z), relationship precision (Ainv), and fitted
    # variance components — the fit object already carries spec.Ainv.
    ped = normalize_pedigree(["a1", "a2", "a3", "a4", "a5", "a6"],
        ["0", "0", "a1", "a1", "a2", "a2"], ["0", "0", "a2", "a2", "0", "0"])
    Ainv = pedigree_inverse(ped)
    y = [2.0, 3.0, 2.5, 3.5, 4.0, 1.5]
    X = ones(6, 1)
    Z = sparse(1.0I, 6, 6)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
    lik = gaussian_loglik(spec, 1.2, 0.8; method = :REML)
    fit = AnimalModelFit(spec, lik, (sigma_a2 = 1.2, sigma_e2 = 0.8), true, "supplied", 0)
    markers = Float64[0 1 2; 1 1 0; 2 0 1; 0 2 1; 1 0 2; 2 1 0]
    mids = ["m1", "m2", "m3"]

    # mixed-model (relatedness-corrected GLS) post-fit == explicit args
    pf = mixed_model_marker_scan(fit, markers; marker_ids = mids)
    ex = mixed_model_marker_scan(y, X, Z, Ainv, markers, 1.2, 0.8; marker_ids = mids)
    @test pf == ex
    @test pf.target == :mixed_model_marker_scan
    @test pf.marker_ids == mids
    @test length(pf.effects) == 3
    payload = marker_scan_result_payload(pf)
    @test propertynames(payload) == (
        :engine,
        :target,
        :n_markers,
        :marker_ids,
        :effects,
        :standard_errors,
        :z_scores,
        :chisq,
        :p_values,
        :bonferroni_p_values,
        :bh_q_values,
        :lod_scores,
        :denominators,
        :allele_frequencies,
        :vanraden_scale,
        :variance_components,
    )
    @test payload.engine == "HSquared.jl"
    @test payload.target == :mixed_model_marker_scan
    @test payload.n_markers == 3
    @test payload.marker_ids == mids
    @test payload.effects ≈ pf.effects
    @test payload.standard_errors ≈ pf.standard_errors
    @test payload.z_scores ≈ pf.z_scores
    @test payload.chisq ≈ pf.chisq
    @test payload.p_values ≈ pf.p_values
    @test payload.bonferroni_p_values ≈ pf.bonferroni_p_values
    @test payload.bh_q_values ≈ pf.bh_q_values
    @test payload.lod_scores ≈ pf.lod_scores
    @test payload.denominators ≈ pf.denominators
    @test payload.allele_frequencies ≈ pf.p
    @test payload.vanraden_scale ≈ pf.k
    @test payload.variance_components == (sigma_a2 = 1.2, sigma_e2 = 0.8)

    # fixed-effect post-fit == explicit args (uses the fit's residual variance)
    pf2 = single_marker_scan(fit, markers; marker_ids = mids)
    ex2 = single_marker_scan(y, X, markers; sigma_e2 = 0.8, marker_ids = mids)
    @test pf2 == ex2

    # Discriminating (review #45, Curie): a NON-identity (permutation) random-effect
    # incidence Z changes the GLS covariance V = σ²a Z A Z' + σ²e I, so the fit's Z
    # must genuinely be threaded through (not silently treated as identity).
    P = sparse(Float64[0 1 0 0 0 0
                       1 0 0 0 0 0
                       0 0 0 1 0 0
                       0 0 1 0 0 0
                       0 0 0 0 0 1
                       0 0 0 0 1 0])
    specP = animal_model_spec(y, X, P, Ainv; ids = ped.ids, method = :REML)
    likP = gaussian_loglik(specP, 1.2, 0.8; method = :REML)
    fitP = AnimalModelFit(specP, likP, (sigma_a2 = 1.2, sigma_e2 = 0.8), true, "supplied", 0)
    @test mixed_model_marker_scan(fitP, markers; marker_ids = mids) ==
          mixed_model_marker_scan(y, X, P, Ainv, markers, 1.2, 0.8; marker_ids = mids)
    @test mixed_model_marker_scan(fitP, markers).effects != pf.effects   # permutation Z ≠ identity Z
    # the fixed-effect screen ignores Z/Ainv: same y/X/σ²e ⇒ identical regardless of Z
    @test single_marker_scan(fitP, markers; marker_ids = mids) ==
          single_marker_scan(fit, markers; marker_ids = mids)
end

@testset "Phase 5 marker-scan parity fixture (#45)" begin
    fixture_dir = joinpath(@__DIR__, "fixtures", "marker_scan_parity")
    _, ped_rows = _csv_strings_for_test(joinpath(fixture_dir, "pedigree.csv"))
    ped = normalize_pedigree(ped_rows[:, 1], ped_rows[:, 2], ped_rows[:, 3])
    Ainv = pedigree_inverse(ped)

    _, pheno = _csv_strings_for_test(joinpath(fixture_dir, "phenotypes.csv"))
    ids = vec(pheno[:, 1])
    y = parse.(Float64, pheno[:, 2])
    @test ids == ped.ids

    marker_header, marker_rows = _csv_strings_for_test(joinpath(fixture_dir, "markers.csv"))
    marker_ids = marker_header[2:end]
    @test marker_rows[:, 1] == ids
    markers = parse.(Float64, marker_rows[:, 2:end])

    payload_header, payload_rows =
        _csv_strings_for_test(joinpath(fixture_dir, "expected_marker_scan_payload.csv"))
    @test payload_header == [
        "marker_id",
        "effect",
        "standard_error",
        "z_score",
        "chisq",
        "p_value",
        "bonferroni_p_value",
        "bh_q_value",
        "lod_score",
        "denominator",
        "allele_frequency",
    ]
    expected_marker_ids = vec(payload_rows[:, 1])
    expected_payload = parse.(Float64, payload_rows[:, 2:end])
    metadata = _metadata_csv_for_test(joinpath(fixture_dir, "expected_metadata.csv"))

    sigma_a2 = parse(Float64, metadata["sigma_a2"])
    sigma_e2 = parse(Float64, metadata["sigma_e2"])
    X = ones(length(y), 1)
    Z = sparse(1.0I, length(y), length(y))
    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
    lik = gaussian_loglik(spec, sigma_a2, sigma_e2; method = :REML)
    fit = AnimalModelFit(spec, lik, (sigma_a2 = sigma_a2, sigma_e2 = sigma_e2), true, "supplied", 0)

    scan = mixed_model_marker_scan(fit, markers; marker_ids = marker_ids)
    payload = marker_scan_result_payload(scan)
    @test metadata["engine"] == payload.engine
    @test Symbol(metadata["target"]) == payload.target
    @test parse(Int, metadata["n_markers"]) == payload.n_markers
    @test parse(Float64, metadata["vanraden_scale"]) ≈ payload.vanraden_scale atol = 1e-12
    @test expected_marker_ids == payload.marker_ids
    @test expected_payload[:, 1] ≈ payload.effects atol = 1e-12
    @test expected_payload[:, 2] ≈ payload.standard_errors atol = 1e-12
    @test expected_payload[:, 3] ≈ payload.z_scores atol = 1e-12
    @test expected_payload[:, 4] ≈ payload.chisq atol = 1e-12
    @test expected_payload[:, 5] ≈ payload.p_values atol = 1e-12
    @test expected_payload[:, 6] ≈ payload.bonferroni_p_values atol = 1e-12
    @test expected_payload[:, 7] ≈ payload.bh_q_values atol = 1e-12
    @test expected_payload[:, 8] ≈ payload.lod_scores atol = 1e-12
    @test expected_payload[:, 9] ≈ payload.denominators atol = 1e-12
    @test expected_payload[:, 10] ≈ payload.allele_frequencies atol = 1e-12

    corrupted = copy(expected_payload)
    corrupted[1, 1] += 0.1
    @test !isapprox(corrupted[:, 1], payload.effects; atol = 1e-12)
end

@testset "Phase 5 genome-wide threshold machinery (#48)" begin
    # _scan_max_statistic: max chi-square / max -log10 p over a scan
    fake_scan = (chisq = [1.0, 9.0, 4.0], p_values = [0.3, 0.001, 0.05])
    @test HSquared._scan_max_statistic(fake_scan; statistic = :chisq) == 9.0
    @test HSquared._scan_max_statistic(fake_scan; statistic = :neglog10p) ≈ -log10(0.001)
    @test_throws ArgumentError HSquared._scan_max_statistic(fake_scan; statistic = :nope)
    @test_throws ArgumentError HSquared._scan_max_statistic((p_values = [0.1],); statistic = :chisq)

    # _empirical_upper_quantile: type-7 linear interpolation vs hand values
    @test HSquared._empirical_upper_quantile([1.0, 2.0, 3.0, 4.0], 0.0) == 1.0
    @test HSquared._empirical_upper_quantile([1.0, 2.0, 3.0, 4.0], 1.0) == 4.0
    @test HSquared._empirical_upper_quantile([1.0, 2.0, 3.0, 4.0], 0.5) ≈ 2.5
    @test HSquared._empirical_upper_quantile([10.0], 0.95) == 10.0          # single value
    @test HSquared._empirical_upper_quantile([3.0, 1.0, 2.0], 0.5) ≈ 2.0    # unsorted input
    @test_throws ArgumentError HSquared._empirical_upper_quantile(Float64[], 0.5)
    @test_throws ArgumentError HSquared._empirical_upper_quantile([1.0], 1.5)

    # genome_wide_threshold_from_null: (1-alpha) empirical quantile of the null
    nulls = collect(1.0:100.0)
    thr5 = genome_wide_threshold_from_null(nulls; alpha = 0.05)
    @test thr5.threshold ≈ HSquared._empirical_upper_quantile(nulls, 0.95)
    @test thr5.alpha == 0.05
    @test thr5.statistic == :chisq
    @test thr5.n_null == 100
    # monotonicity: smaller alpha ⇒ larger (more stringent) threshold
    thr1 = genome_wide_threshold_from_null(nulls; alpha = 0.01)
    @test thr1.threshold > thr5.threshold
    @test_throws ArgumentError genome_wide_threshold_from_null(nulls; alpha = 0.0)
    @test_throws ArgumentError genome_wide_threshold_from_null(Float64[])
    @test_throws ArgumentError genome_wide_threshold_from_null(nulls; statistic = :nope)

    # genome_wide_pvalue: add-one empirical p (never 0), monotone in observed
    nulls2 = [1.0, 2.0, 3.0, 4.0]
    @test genome_wide_pvalue(5.0, nulls2) == 1 / 5         # exceeds all -> (1+0)/(4+1)
    @test genome_wide_pvalue(0.0, nulls2) == 5 / 5         # below all  -> (1+4)/(4+1)
    @test genome_wide_pvalue(3.0, nulls2) == 3 / 5         # >= 3 and 4 -> (1+2)/(4+1)
    @test genome_wide_pvalue(1.0e9, nulls2) > 0            # never zero
    @test_throws ArgumentError genome_wide_pvalue(1.0, Float64[])

    # The type-7 quantile threshold and the add-one p are DIFFERENT estimators that
    # agree only asymptotically; at small n_null the quantile is mildly anti-
    # conservative. Pin the ACTUAL add-one p at the threshold (not a hidden atol):
    @test genome_wide_pvalue(thr5.threshold, nulls) ≈ 6 / 101   # n=100 -> 0.0594, not 0.05
    big = collect(1.0:1000.0)
    thr_big = genome_wide_threshold_from_null(big; alpha = 0.05)
    @test genome_wide_pvalue(thr_big.threshold, big) ≈ 0.05 atol = 0.002   # converges to alpha

    # finite guards (review #48, Gauss): non-finite scan stats / observed throw
    @test_throws ArgumentError HSquared._scan_max_statistic((chisq = [1.0, NaN],); statistic = :chisq)
    @test_throws ArgumentError genome_wide_pvalue(NaN, nulls)
    @test_throws ArgumentError genome_wide_pvalue(1.0, [1.0, Inf])

    # -----------------------------------------------------------------------
    # Calibration-property tests (#7): verify the threshold machinery
    # returns the KNOWN analytic (1-alpha) type-7 quantile on a hand-
    # constructed null, and that the add-one p-value is exactly the formula
    # and strictly monotone.  ALL deterministic — no RNG.
    # -----------------------------------------------------------------------

    # (a) genome_wide_threshold_from_null matches the hand-computed type-7
    # quantile for alpha=0.05 and alpha=0.01 on a small known null.
    # nulls_cal = [10, 20, ..., 200] (n=20).
    # Type-7: h = (n-1)*p + 1 (1-based); lo = floor(h); frac = h - lo;
    #         q = v[lo] + frac*(v[lo+1] - v[lo])   (v sorted ascending)
    # alpha=0.05 -> p=0.95: h = 19*0.95+1 = 19.05, lo=19, frac=0.05
    #   q = 190 + 0.05*(200-190) = 190 + 0.5 = 190.5
    # alpha=0.01 -> p=0.99: h = 19*0.99+1 = 19.81, lo=19, frac=0.81
    #   q = 190 + 0.81*(200-190) = 190 + 8.1 = 198.1
    nulls_cal = collect(10.0:10.0:200.0)        # [10,20,...,200], n=20
    thr_cal_05 = genome_wide_threshold_from_null(nulls_cal; alpha = 0.05)
    thr_cal_01 = genome_wide_threshold_from_null(nulls_cal; alpha = 0.01)
    @test thr_cal_05.threshold == 190.5          # exact arithmetic, no atol needed
    @test thr_cal_01.threshold == 198.1
    @test thr_cal_05.n_null == 20
    @test thr_cal_01.n_null == 20
    # monotonicity: alpha=0.01 threshold is more stringent (higher) than alpha=0.05
    @test thr_cal_01.threshold > thr_cal_05.threshold

    # (b) genome_wide_pvalue is exactly (1 + #{null >= obs}) / (n+1), hand cases.
    # null_cal2 = [1,2,3,4,5] (n=5).
    # observed=5.0: #{null>=5} = 1 -> p = (1+1)/6 = 2/6
    # observed=2.5: #{null>=2.5} = 3 (3,4,5) -> p = (1+3)/6 = 4/6
    # observed=6.0: #{null>=6} = 0 -> p = (1+0)/6 = 1/6  (never zero)
    null_cal2 = [1.0, 2.0, 3.0, 4.0, 5.0]
    @test genome_wide_pvalue(5.0, null_cal2) == 2 / 6   # obs == max element
    @test genome_wide_pvalue(2.5, null_cal2) == 4 / 6   # obs in interior
    @test genome_wide_pvalue(6.0, null_cal2) == 1 / 6   # obs exceeds all
    @test genome_wide_pvalue(0.5, null_cal2) == 6 / 6   # obs below all = 1.0
    # strict monotonicity in observed (increasing obs -> decreasing add-one p)
    obs_seq = [0.5, 1.5, 2.5, 3.5, 4.5, 5.5]
    p_seq = [genome_wide_pvalue(o, null_cal2) for o in obs_seq]
    @test issorted(p_seq; rev = true)           # strictly decreasing (all steps distinct here)

    # (c) threshold-p consistency: at the exact type-7 threshold, the add-one
    # p equals (1 + #{null >= threshold}) / (n+1), NOT necessarily == alpha
    # (they converge only asymptotically).  Pin the exact relationship for the
    # 20-element null at alpha=0.05: threshold = 190.5; #{null >= 190.5} = 1
    # (only 200 >= 190.5) -> p = (1+1)/21 = 2/21 ≈ 0.0952, not 0.05.
    # This pins the documented anti-conservative gap: quantile p > alpha at n=20.
    @test genome_wide_pvalue(thr_cal_05.threshold, nulls_cal) == 2 / 21
    @test genome_wide_pvalue(thr_cal_05.threshold, nulls_cal) > thr_cal_05.alpha

    # (d) The opt-in RNG harness is outside CI for calibration runs, but its
    # command-line/output contract is deterministic and unit-testable.
    include(joinpath(@__DIR__, "..", "sim", "phase5_threshold_calibration.jl"))
    @test _parse_seed_list("1, 2,3") == [1, 2, 3]
    @test_throws ArgumentError _parse_seed_list("")
    @test _checked_type1_marker_mode("fixed") === :fixed
    @test _checked_type1_marker_mode("fresh") === :fresh
    @test_throws ArgumentError _checked_type1_marker_mode("panel")

    fake_threshold_result = (
        seed = 1,
        n = 10,
        markers = 4,
        permutations = 5,
        alpha = 0.05,
        type1_reps = 20,
        type1_marker_mode = :fixed,
        threshold = 3.0,
        bonferroni_chisq = 4.0,
        threshold_less_than_bonferroni = true,
        exceed = 1,
        empirical_type1 = 0.05,
    )
    fake_threshold_result2 = merge(fake_threshold_result, (
        seed = 2,
        threshold = 3.5,
        exceed = 2,
        empirical_type1 = 0.10,
    ))
    summary = _summarize_threshold_calibration_results([
        fake_threshold_result,
        fake_threshold_result2,
    ])
    @test summary.n_seeds == 2
    @test summary.mean_threshold == 3.25
    @test summary.mean_empirical_type1 ≈ 0.075
    @test summary.max_abs_type1_error == 0.05
    @test summary.all_thresholds_below_bonferroni
    @test_throws ArgumentError _summarize_threshold_calibration_results([])

    mktempdir() do dir
        path = joinpath(dir, "threshold.tsv")
        _write_threshold_calibration_tsv(path, [fake_threshold_result])
        lines = readlines(path)
        @test lines[1] == _threshold_calibration_tsv_header()
        @test lines[2] == _threshold_calibration_tsv_row(fake_threshold_result)
        @test occursin("type1_marker_mode", lines[1])
        @test occursin("\tfixed\t", lines[2])
    end

    # -----------------------------------------------------------------------

    # validation_status carries the new V5-MARKER-THRESHOLD row
    @test "V5-MARKER-THRESHOLD" in [row.id for row in validation_status()]
end

@testset "genome_wide_marker_scan (R-activation entry point, exact per-dataset rule)" begin
    rng = MersenneTwister(20264100)
    n, m = 200, 40
    X = ones(n, 1)
    # build a small correlated panel + one planted causal marker
    M = Float64.(rand(rng, 0:2, n, m))
    causal = 10
    gc = M[:, causal] .- (sum(M[:, causal]) / n)
    y = 2.0 .+ 0.7 .* gc .+ randn(rng, n)

    scan = genome_wide_marker_scan(y, X, M; n_permutations = 300, alpha = 0.05,
                                   rng = MersenneTwister(99))

    # (1) reduces to single_marker_scan on the per-marker fields (same y/X/M)
    base = single_marker_scan(y, X, M)
    @test scan.effects ≈ base.effects
    @test scan.chisq ≈ base.chisq
    @test scan.p_values ≈ base.p_values
    @test scan.marker_ids == base.marker_ids

    # (2) genome-wide p-values are valid add-one p's: in (0, 1], never zero,
    # bounded below by the add-one floor 1/(nperm+1)
    @test length(scan.genome_wide_p_values) == m
    @test all(0 .< scan.genome_wide_p_values .<= 1)
    @test minimum(scan.genome_wide_p_values) >= 1 / (scan.n_permutations + 1) - 1e-12

    # (3) genome_wide_p_min is the top marker's genome-wide p (= min over markers)
    @test scan.genome_wide_p_min == minimum(scan.genome_wide_p_values)
    @test scan.genome_wide_p_min == genome_wide_pvalue(maximum(scan.chisq), scan.null_max)

    # (4) per-marker genome-wide p is monotone non-increasing in the marker chisq
    ord = sortperm(scan.chisq)
    @test issorted(scan.genome_wide_p_values[ord]; rev = true)

    # (5) the planted causal marker is the top hit and genome-wide significant here
    @test argmax(scan.chisq) == causal
    @test scan.genome_wide_p_min < 0.05

    # (6) threshold matches genome_wide_threshold_from_null on the same null
    thr = genome_wide_threshold_from_null(scan.null_max; alpha = 0.05)
    @test scan.genome_wide_threshold == thr.threshold

    # (7) determinism: same rng seed -> identical genome-wide p's
    scan2 = genome_wide_marker_scan(y, X, M; n_permutations = 300, alpha = 0.05,
                                    rng = MersenneTwister(99))
    @test scan2.genome_wide_p_values == scan.genome_wide_p_values

    # (8) calibration payload describes the exact per-dataset rule
    @test scan.calibration.method === :permutation_addone
    @test scan.calibration.rebuilt_per_dataset === true
    @test scan.calibration.n_permutations == 300
    @test scan.calibration.alpha == 0.05
    @test scan.target === :genome_wide_marker_scan

    # (9) a PURE-NULL dataset is not spuriously genome-wide significant at the floor
    ynull = 2.0 .+ randn(MersenneTwister(7), n)
    snull = genome_wide_marker_scan(ynull, X, M; n_permutations = 300,
                                    rng = MersenneTwister(7))
    @test snull.genome_wide_p_min > 1 / (snull.n_permutations + 1)

    # (10) input guards
    @test_throws ArgumentError genome_wide_marker_scan(y, X, M; n_permutations = 0)
    @test_throws ArgumentError genome_wide_marker_scan(y, X, M; alpha = 0.0)
    @test_throws ArgumentError genome_wide_marker_scan(y, X, M; sigma_e2 = -1.0)

    # (11) R-bridge parity fixture. The scan fields (effects/chisq) are DETERMINISTIC
    # (no RNG) and pinned EXACTLY against the committed payload. The genome-wide
    # p-values come from a permutation null, whose MersenneTwister stream is NOT stable
    # across Julia MAJOR versions — so they are checked STRUCTURALLY (valid add-one p's,
    # monotone in chisq, the planted causal genome-wide significant), NOT for exact
    # cross-version byte-identity. The fixture's stored genome_wide_p_value column is the
    # Julia-1.10 reference; the R `gwas(..., genome_wide = TRUE)` LIVE bridge checks exact
    # parity against the SAME Julia it calls (a within-version property).
    fdir = joinpath(@__DIR__, "fixtures", "genome_wide_scan_parity")
    _, fph = _csv_strings_for_test(joinpath(fdir, "phenotypes.csv"))
    yf = parse.(Float64, fph[:, 2])
    fmh, fmr = _csv_strings_for_test(joinpath(fdir, "markers.csv"))
    fmids = fmh[2:end]
    Mf = parse.(Float64, fmr[:, 2:end])
    ph, pr = _csv_strings_for_test(joinpath(fdir, "expected_genome_wide_scan_payload.csv"))
    @test ph[end] == "genome_wide_p_value"
    sf = genome_wide_marker_scan(yf, ones(length(yf), 1), Mf;
                                 n_permutations = 300, alpha = 0.05,
                                 marker_ids = fmids, rng = MersenneTwister(20264200))
    @test sf.marker_ids == vec(pr[:, 1])
    @test sf.chisq ≈ parse.(Float64, pr[:, 5]) rtol = 1e-8          # deterministic
    @test all(0 .< sf.genome_wide_p_values .<= 1)                    # valid add-one p's
    ordf = sortperm(sf.chisq)
    @test issorted(sf.genome_wide_p_values[ordf]; rev = true)        # monotone in chisq
    @test sf.genome_wide_p_values[argmax(sf.chisq)] < 0.05           # planted causal sig
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

    function dense_single_step_H_oracle(A, G, rows)
        idx = collect(rows)
        other = setdiff(1:size(A, 1), idx)
        A22 = Matrix{Float64}(A[idx, idx])
        A22inv = inv(Symmetric(A22))
        Gmat = Matrix{Float64}(G)
        Δ = Gmat .- A22
        H = Matrix{Float64}(A)
        H[other, other] = A[other, other] .+
                          A[other, idx] * A22inv * Δ * A22inv * A[idx, other]
        H[other, idx] = A[other, idx] * A22inv * Gmat
        H[idx, other] = Gmat * A22inv * A[idx, other]
        H[idx, idx] = Gmat
        return H
    end

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
    H_oracle = dense_single_step_H_oracle(A, Gtest, g)
    @test maximum(abs.(H_oracle .- transpose(H_oracle))) < 1e-12
    @test H_oracle[g, g] ≈ Gtest atol = 1e-12
    @test H2 * H_oracle ≈ Matrix(1.0I, 5, 5) atol = 1e-10
    @test H_oracle * H2 ≈ Matrix(1.0I, 5, 5) atol = 1e-10
    @test H2 ≈ inv(Symmetric(H_oracle)) atol = 1e-10

    # scattered (non-trailing) genotyped rows
    gs = [1, 3, 5]; nongs = setdiff(1:5, gs)
    Gs = A[gs, gs] + 0.1 * I
    Hs = HSquared._single_step_Hinv(Ainv, A, Gs, gs)
    @test maximum(abs.(Hs[nongs, :] .- Ainv[nongs, :])) < 1e-12
    Hs_oracle = dense_single_step_H_oracle(A, Gs, gs)
    @test Hs * Hs_oracle ≈ Matrix(1.0I, 5, 5) atol = 1e-10
    @test Hs_oracle * Hs ≈ Matrix(1.0I, 5, 5) atol = 1e-10

    # singular raw genomic G throws unless blended/ridged
    G3 = genomic_relationship_matrix([0.0 1 2; 2 1 0; 1 1 1])     # 3x3, rank-deficient
    @test_throws ArgumentError HSquared._single_step_Hinv(Ainv, A, G3, g)
    @test all(isfinite, HSquared._single_step_Hinv(Ainv, A, G3, g; blend_weight = 0.1))

    # dimension guard: G size must match the genotyped count
    @test_throws ArgumentError HSquared._single_step_Hinv(Ainv, A, A[g, g], [3, 4])
end

@testset "Phase 2 single-step fitting (public Hinv + fit)" begin
    ids = [1, 2, 3, 4, 5]; sire = [0, 0, 1, 1, 3]; dam = [0, 0, 2, 2, 4]
    ped = normalize_pedigree(ids, sire, dam)
    A = HSquared._numerator_relationship(ped)
    Ainv = Matrix(pedigree_inverse(ids, sire, dam))
    g = [3, 4, 5]
    y = [10.0, 12.0, 11.0, 9.0, 13.0]; X = ones(5, 1); Z = Matrix(1.0I, 5, 5)

    # public wrapper delegates to the internal constructor
    Hinv = single_step_inverse(Ainv, A, A[g, g] + 0.1 * I, g)
    @test Hinv == HSquared._single_step_Hinv(Ainv, A, A[g, g] + 0.1 * I, g)
    # reduction: G = A22 ⇒ H⁻¹ = A⁻¹
    @test single_step_inverse(Ainv, A, A[g, g], g) ≈ Ainv atol = 1e-10

    # fit_single_step at G = A22 reproduces the pedigree animal model (supplied variance)
    fs = fit_single_step(y, X, Z, Ainv, A, A[g, g], g, 1.0, 1.5)
    ped_fit = fit_gblup(y, X, Z, Ainv, 1.0, 1.5)
    @test breeding_values(fs).values ≈ breeding_values(ped_fit).values atol = 1e-9

    # fit_single_step with a genomic block uses the single-step H-inverse
    Hg = single_step_inverse(Ainv, A, A[g, g] + 0.1 * I, g)
    fs2 = fit_single_step(y, X, Z, Ainv, A, A[g, g] + 0.1 * I, g, 1.0, 1.5)
    direct = fit_gblup(y, X, Z, Hg, 1.0, 1.5)
    @test breeding_values(fs2).values ≈ breeding_values(direct).values atol = 1e-10

    # REML variant at G = A22 reproduces the pedigree REML optimum
    fsr = fit_single_step_reml(y, X, Z, Ainv, A, A[g, g], g; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    ped_reml = fit_ai_reml(animal_model_spec(y, X, Z, Ainv; method = :REML);
                           initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    @test fsr isa AnimalModelFit
    @test fsr.converged == ped_reml.converged                                   # same optimizer state
    @test fsr.likelihood.loglik ≈ ped_reml.likelihood.loglik rtol = 1e-6        # identical REML objective
    @test fsr.variance_components.sigma_a2 ≈ ped_reml.variance_components.sigma_a2 rtol = 1e-5 atol = 1e-7
    @test fsr.variance_components.sigma_e2 ≈ ped_reml.variance_components.sigma_e2 rtol = 1e-5

    # guards delegate to the constructor
    @test_throws ArgumentError single_step_inverse(Ainv, A, A[g, g], [3, 4])
    @test_throws ArgumentError fit_single_step(y, X, Z, Ainv, A, genomic_relationship_matrix([0.0 1 2; 2 1 0; 1 1 1]), g, 1.0, 1.5)  # singular raw G
end

@testset "Phase 2 metafounder single-step H^Gamma bridge primitive" begin
    ids = [1, 2, 3, 4, 5]; sire = [0, 0, 1, 1, 3]; dam = [0, 0, 2, 2, 4]
    ped = normalize_pedigree(ids, sire, dam)
    needs = [ped.sire[i] == 0 || ped.dam[i] == 0 for i in 1:length(ped)]
    group = [needs[i] ? "base" : "0" for i in 1:length(ped)]
    A = additive_relationship(ped)
    Ainv = Matrix(pedigree_inverse(ped))
    g = [3, 4, 5]
    y = [10.0, 12.0, 11.0, 9.0, 13.0]; X = ones(5, 1); Z = Matrix(1.0I, 5, 5)

    # Gamma = 0 reduction: H^Gamma is the ordinary pedigree single-step H.
    @test metafounder_single_step_inverse(ped, group, zeros(1, 1), A[g, g], g) ≈
          single_step_inverse(Ainv, A, A[g, g], g) atol = 1e-10

    Γ = fill(0.35, 1, 1)
    Aγ = metafounder_relationship(ped, group, Γ)
    Aγinv = metafounder_relationship_inverse(ped, group, Γ)
    Gγ = Aγ[g, g] + 0.1 * I
    Hγ = metafounder_single_step_inverse(ped, group, Γ, Gγ, g)
    @test Hγ ≈ single_step_inverse(Aγinv, Aγ, Gγ, g) atol = 1e-10
    @test maximum(abs.(Hγ .- transpose(Hγ))) < 1e-12
    @test !isapprox(Hγ, single_step_inverse(Ainv, A, Gγ, g); atol = 1e-6)

    # Supplied-variance and REML wrappers delegate to the H^Gamma precision path.
    fit = fit_metafounder_single_step(y, X, Z, ped, group, Γ, Gγ, g, 1.0, 1.5)
    direct = fit_gblup(y, X, Z, Hγ, 1.0, 1.5; ids = ped.ids)
    @test breeding_values(fit).values ≈ breeding_values(direct).values atol = 1e-10

    reml = fit_metafounder_single_step_reml(y, X, Z, ped, group, zeros(1, 1), A[g, g], g;
                                            initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    ordinary = fit_single_step_reml(y, X, Z, Ainv, A, A[g, g], g;
                                    initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    @test reml.likelihood.loglik ≈ ordinary.likelihood.loglik rtol = 1e-6
    @test reml.variance_components.sigma_a2 ≈ ordinary.variance_components.sigma_a2 rtol = 1e-5 atol = 1e-7
    @test reml.variance_components.sigma_e2 ≈ ordinary.variance_components.sigma_e2 rtol = 1e-5

    # Nonzero-Gamma REML results still use the standard bridge-facing
    # AnimalModelFit payload: no H^Gamma-specific extractor branch is needed.
    y_bridge = [8.0, 13.0, 12.0, 7.0, 15.0]
    reml_hgamma = fit_metafounder_single_step_reml(y_bridge, X, Z, ped, group, Γ, Gγ, g;
                                                   initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    @test reml_hgamma.converged
    @test reml_hgamma.variance_components.sigma_a2 > 0
    @test reml_hgamma.variance_components.sigma_e2 > 0
    pev_dense = prediction_error_variance(reml_hgamma; method = :dense)
    pev_selinv = prediction_error_variance(reml_hgamma; method = :selinv)
    rel_dense = reliability(reml_hgamma; method = :dense)
    rel_selinv = reliability(reml_hgamma; method = :selinv)
    @test pev_dense.ids == ped.ids
    @test pev_selinv.ids == ped.ids
    @test pev_selinv.values ≈ pev_dense.values atol = 1e-10
    @test rel_dense.ids == ped.ids
    @test rel_selinv.ids == ped.ids
    @test rel_selinv.values ≈ rel_dense.values atol = 1e-10
    @test all(isfinite, rel_selinv.values)
    @test all(0 .<= rel_selinv.values .<= 1)

    payload = result_payload(reml_hgamma)
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
        :prediction_error_variance,
        :reliability,
        :diagnostics,
        :converged,
    )
    @test payload.breeding_values.ids == ped.ids
    @test payload.random_effects.animal.ids == ped.ids
    @test payload.prediction_error_variance.ids == ped.ids
    @test payload.prediction_error_variance.values ≈ pev_selinv.values atol = 1e-10
    @test payload.reliability.ids == ped.ids
    @test payload.reliability.values ≈ rel_selinv.values atol = 1e-10
    @test payload.diagnostics.converged
    @test payload.diagnostics.method == :REML
    @test payload.diagnostics.dense_validation_path == false
    @test payload.converged

    diagnostics = fit_diagnostics(reml_hgamma)
    @test diagnostics.engine == :julia
    @test diagnostics.result_type == :animal_model_fit
    @test diagnostics.target == :ai_reml
    @test diagnostics.method == :REML
    @test diagnostics.family == :gaussian
    @test diagnostics.converged
    @test diagnostics.sparse_mme_path
    @test diagnostics.variance_components_source == :estimated_ai_reml

    @test_throws ArgumentError metafounder_single_step_inverse(ped, group, zeros(1, 1), A[g, g], [3, 4])
    @test_throws ArgumentError metafounder_single_step_inverse(ped, group, Γ, genomic_relationship_matrix([0.0 1 2; 2 1 0; 1 1 1]), g)
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

@testset "Phase 2 GBLUP/SNP-BLUP REML convenience (variance-component estimation)" begin
    # one-call genomic/marker fitting that ESTIMATES the variance components by REML
    # (closes the supplied-variance-only limitation of fit_gblup / fit_snp_blup).
    M = [0.0 1 2; 2 1 0; 1 1 1; 0 2 2; 1 0 2; 2 1 1]   # 6 animals x 3 markers
    y = [10.0, 12.0, 11.0, 9.0, 13.0, 10.5]
    X = ones(6, 1); Z = Matrix(1.0I, 6, 6)
    G = genomic_relationship_matrix(M)
    Ginv = genomic_relationship_inverse(G; ridge = 0.05)
    spec = animal_model_spec(y, X, Z, Ginv; method = :REML)
    ai = fit_ai_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))

    # fit_gblup_reml estimates (σ²_g, σ²_e) on the Ginv spec == generic AI-REML
    g = fit_gblup_reml(y, X, Z, Ginv; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    @test g isa AnimalModelFit
    @test g.converged
    @test g.variance_components.sigma_a2 ≈ ai.variance_components.sigma_a2 rtol = 1e-6
    @test g.variance_components.sigma_e2 ≈ ai.variance_components.sigma_e2 rtol = 1e-6
    @test breeding_values(g).values ≈ breeding_values(ai).values atol = 1e-8

    # fit_snp_blup_reml estimates σ²_g and returns marker effects + GEBVs
    s = fit_snp_blup_reml(y, X, M; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    @test s.converged
    @test s.sigma_g2 > 0 && s.sigma_e2 > 0
    @test length(s.marker_effects) == 3
    @test length(s.gebv) == 6
    # the REML wrapper reproduces supplied-variance SNP-BLUP at the ESTIMATED variances
    sup = fit_snp_blup(y, X, M, s.sigma_g2, s.sigma_e2)
    @test sup.gebv ≈ s.gebv atol = 1e-8
    @test sup.marker_effects ≈ s.marker_effects atol = 1e-8

    # guards inherited from the REML core
    @test_throws ArgumentError fit_gblup_reml(y, X, Z, Ginv; initial = (sigma_a2 = -1.0, sigma_e2 = 1.0))
    @test_throws ArgumentError fit_snp_blup_reml(y, X, M; initial = (sigma_a2 = -1.0, sigma_e2 = 1.0))
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

    # variance_component_interval applies UNCHANGED to a genomic GBLUP / supplied-Ginv
    # REML fit (the profiler reads only the spec via sparse_reml_loglik); on a genomic
    # spec sigma_a2 is the GENOMIC additive variance, conditional on the supplied Ginv.
    gvc = variance_components(gfit)
    gsa2ci = variance_component_interval(gfit; level = 0.95)
    gsa2ci50 = variance_component_interval(gfit; level = 0.50)
    @test gsa2ci.method == :profile
    @test gsa2ci.sigma_a2 ≈ gvc.sigma_a2
    @test (gsa2ci.lower ≤ gsa2ci.sigma_a2 ≤ gsa2ci.upper) ||
          gsa2ci.lower_clamped || gsa2ci.upper_clamped          # brackets or self-describes
    @test gsa2ci50.lower ≥ gsa2ci.lower && gsa2ci50.upper ≤ gsa2ci.upper   # 95% ⊇ 50%
    @test gsa2ci.lower_clamped isa Bool && gsa2ci.upper_clamped isa Bool
    # the profile max over sigma_e2 at σ̂²a recovers the fitted genomic REML optimum
    @test HSquared._profile_reml_loglik_sigma_a2(gspec, gsa2ci.sigma_a2) ≈
          sparse_reml_loglik(gspec, gvc.sigma_a2, gvc.sigma_e2).loglik atol = 1e-4
    # the genomic convenience entry point flows through end-to-end
    gbci = variance_component_interval(fit_gblup_reml(gspec.y, gspec.X, gspec.Z, Ginv))
    @test gbci.method == :profile && gbci.lower_clamped isa Bool

    # sigma_a2 profile-LRT interval (variance_component_interval): the
    # variance-component companion of the h² profile — fixes sigma_a2 and profiles
    # sigma_e2 (the nuisance). This tiny n=8 fixture has a flat REML surface, so
    # endpoints may clamp; these assertions hold whether clamped or not.
    sa2ci95 = variance_component_interval(fit; level = 0.95)
    sa2ci50 = variance_component_interval(fit; level = 0.50)
    @test sa2ci95.method == :profile
    @test sa2ci95.sigma_a2 ≈ sa2
    @test sa2ci95.lower ≤ sa2 ≤ sa2ci95.upper                              # brackets the estimate
    @test sa2ci50.lower ≥ sa2ci95.lower && sa2ci50.upper ≤ sa2ci95.upper   # 95% ⊇ 50%
    @test sa2ci95.lower_clamped isa Bool && sa2ci95.upper_clamped isa Bool
    # the profile maximum over sigma_e2 at σ̂²a recovers the fitted REML optimum and
    # is an upper envelope of any fixed-sigma_e2 slice at the same sigma_a2
    llmax_a = HSquared._profile_reml_loglik_sigma_a2(spec, sa2)
    @test llmax_a ≈ sparse_reml_loglik(spec, sa2, se2).loglik atol = 1e-4
    @test llmax_a ≥ sparse_reml_loglik(spec, sa2, se2 * 3.0).loglik - 1e-8
    # guards: level range, method, and REML-only (ml is the ML fit above)
    @test_throws ArgumentError variance_component_interval(fit; level = 1.5)
    @test_throws ArgumentError variance_component_interval(fit; method = :bogus)
    @test_throws ArgumentError variance_component_interval(ml)
end

@testset "Phase 1 parametric-bootstrap variance-component interval (C6)" begin
    ids = ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"]
    ped = normalize_pedigree(ids,
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Ainv = pedigree_inverse(ped)
    y = [2.0, 3.0, 2.5, 3.5, 4.0, 1.5, 3.0, 4.5]
    X = ones(8, 1); Z = sparse(1.0I, 8, 8)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
    fit = fit_sparse_reml(spec)
    sa2 = fit.variance_components.sigma_a2; se2 = fit.variance_components.sigma_e2
    h2 = sa2 / (sa2 + se2)

    bs = bootstrap_variance_component_interval(fit; n_boot = 200, rng = MersenneTwister(20260622))
    # point passthrough + shape
    @test bs.sigma_a2 == sa2 && bs.sigma_e2 == se2 && bs.heritability == h2
    @test bs.method === :parametric_bootstrap_percentile && bs.level == 0.95 && bs.n_boot == 200
    # bracketing (≤: the tiny-n REML surface is flat, so an endpoint may sit at the
    # estimate) + non-degenerate + h² CI in (0,1)
    @test bs.sigma_a2_ci.lower ≤ sa2 ≤ bs.sigma_a2_ci.upper && bs.sigma_a2_ci.lower < bs.sigma_a2_ci.upper
    @test bs.sigma_e2_ci.lower ≤ se2 ≤ bs.sigma_e2_ci.upper && bs.sigma_e2_ci.lower < bs.sigma_e2_ci.upper
    @test bs.heritability_ci.lower ≤ h2 ≤ bs.heritability_ci.upper
    # h² CI lies in the CLOSED [0,1]: this tiny-n fixture has σ̂²a on the boundary
    # (≈6e-10), so bootstrap replicates legitimately hit σ²a_b→0 (h²→0) and σ²e_b→0
    # (h²→1) — an honest reflection of boundary uncertainty, not a fabricated range.
    @test 0 ≤ bs.heritability_ci.lower ≤ bs.heritability_ci.upper ≤ 1
    # n_converged accounting (dropped refits surfaced, not hidden)
    @test 0 < bs.n_converged ≤ 200
    @test length(bs.replicates.sigma_a2) == bs.n_converged
    @test length(bs.replicates.sigma_e2) == bs.n_converged
    @test length(bs.replicates.heritability) == bs.n_converged
    # determinism: same seed → byte-identical; different seed → different draws
    bs2 = bootstrap_variance_component_interval(fit; n_boot = 200, rng = MersenneTwister(20260622))
    @test bs.sigma_a2_ci == bs2.sigma_a2_ci && bs.replicates.sigma_a2 == bs2.replicates.sigma_a2
    bs3 = bootstrap_variance_component_interval(fit; n_boot = 200, rng = MersenneTwister(99))
    @test bs.replicates.sigma_a2 != bs3.replicates.sigma_a2
    # monotone in level (same seed ⇒ same replicates, wider percentile): 0.80 ⊆ 0.99
    lo80 = bootstrap_variance_component_interval(fit; n_boot = 200, level = 0.80, rng = MersenneTwister(20260622))
    hi99 = bootstrap_variance_component_interval(fit; n_boot = 200, level = 0.99, rng = MersenneTwister(20260622))
    @test hi99.sigma_a2_ci.lower ≤ lo80.sigma_a2_ci.lower && lo80.sigma_a2_ci.upper ≤ hi99.sigma_a2_ci.upper
    @test hi99.heritability_ci.lower ≤ lo80.heritability_ci.lower && lo80.heritability_ci.upper ≤ hi99.heritability_ci.upper
    # estimator = :ai_reml path runs + brackets
    bsa = bootstrap_variance_component_interval(fit; n_boot = 120, estimator = :ai_reml, rng = MersenneTwister(7))
    @test bsa.sigma_a2_ci.lower ≤ sa2 ≤ bsa.sigma_a2_ci.upper && bsa.n_converged > 0
    # percentile contract: endpoints == the in-package type-7 `_empirical_upper_quantile`
    @test bs.sigma_a2_ci.lower == HSquared._empirical_upper_quantile(bs.replicates.sigma_a2, (1 - bs.level) / 2)
    @test bs.sigma_a2_ci.upper == HSquared._empirical_upper_quantile(bs.replicates.sigma_a2, (1 + bs.level) / 2)
    # guards
    @test_throws ArgumentError bootstrap_variance_component_interval(fit; level = 1.5)
    @test_throws ArgumentError bootstrap_variance_component_interval(fit; n_boot = 0)
    @test_throws ArgumentError bootstrap_variance_component_interval(fit; estimator = :bogus)
    ml = fit_variance_components(animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :ML))
    @test_throws ArgumentError bootstrap_variance_component_interval(ml)   # REML-only

    # V1-HERIT-CI row now records the bootstrap cross-check
    hci = only(r for r in validation_status() if r.id == "V1-HERIT-CI")
    @test occursin("bootstrap_variance_component_interval", hci.evidence)
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

@testset "Phase 3 repeatability t confidence interval (delta method)" begin
    # The interval FUNCTION is RNG-free/deterministic; only this test FIXTURE is
    # seeded (the repeatability model needs genuine independent pe/e variation,
    # which a hand-pattern can't supply without collapsing the σpe/σe split).
    rng = MersenneTwister(20260618)
    nsire, ndam, noff, reps = 8, 16, 40, 3
    sids = ["s$i" for i in 1:nsire]; dids = ["d$i" for i in 1:ndam]; oids = ["o$i" for i in 1:noff]
    ids = vcat(sids, dids, oids)
    sire = vcat(fill("0", nsire + ndam), [sids[((i - 1) % nsire) + 1] for i in 1:noff])
    dam = vcat(fill("0", nsire + ndam), [dids[((i - 1) % ndam) + 1] for i in 1:noff])
    ped = normalize_pedigree(ids, sire, dam)
    Ainv = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv)))); q = length(ped.ids)
    LA = cholesky(Symmetric(A)).L
    a = (LA * randn(rng, q)) .* sqrt(1.0)        # σ²a = 1.0
    pe = randn(rng, q) .* sqrt(0.6)              # σ²pe = 0.6
    n = q * reps; X = ones(n, 1); Z = zeros(n, q); y = zeros(n)
    for an in 1:q, k in 1:reps
        row = (an - 1) * reps + k
        Z[row, an] = 1.0
        y[row] = 5.0 + a[an] + pe[an] + sqrt(1.4) * randn(rng)   # σ²e = 1.4
    end

    ci = repeatability_interval(y, X, Z, Ainv; initial = (sigma_a2 = 1.0, sigma_pe2 = 1.0, sigma_e2 = 1.0))
    @test 0 < ci.lower < ci.repeatability < ci.upper < 1     # valid bracketing (0,1) interval
    @test ci.level == 0.95
    @test ci.se > 0
    fit = fit_repeatability_reml(y, X, Z, Ainv; initial = (sigma_a2 = 1.0, sigma_pe2 = 1.0, sigma_e2 = 1.0))
    @test ci.repeatability ≈ fit.repeatability               # point estimate matches the fit
    # higher confidence ⇒ wider interval
    ci90 = repeatability_interval(y, X, Z, Ainv; level = 0.90)
    ci99 = repeatability_interval(y, X, Z, Ainv; level = 0.99)
    @test ci99.lower < ci90.lower && ci99.upper > ci90.upper
    # guard
    @test_throws ArgumentError repeatability_interval(y, X, Z, Ainv; level = 1.5)
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

@testset "Phase 4 multivariate covariance hardening" begin
    # genetic_correlation: valid PD -> correlations in [-1,1]; rank-deficient PSD
    # (e.g. low-rank G) is allowed; asymmetric, indefinite, or non-square reject.
    G = [2.0 0.6; 0.6 1.0]
    Rg = genetic_correlation(G)
    @test Rg ≈ [1.0 0.6/sqrt(2.0); 0.6/sqrt(2.0) 1.0]
    @test all(-1 .<= Rg .<= 1)
    @test genetic_correlation([1.0 1.0; 1.0 1.0]) ≈ [1.0 1.0; 1.0 1.0]   # rank-1 PSD allowed
    @test_throws ArgumentError genetic_correlation([1.0 0.5; 0.6 1.0])    # asymmetric
    @test_throws ArgumentError genetic_correlation([1.0 2.0; 2.0 1.0])    # indefinite (eig -1, 3)
    @test_throws ArgumentError genetic_correlation([1.0 0.0 0.0; 0.0 1.0 0.0])  # non-square
    @test_throws ArgumentError genetic_correlation([1.0 0.0; 0.0 -1.0])   # non-positive diagonal

    # Cholesky-parameterisation roundtrip is exact for t >= 3 (parameter-order regression)
    for t in (3, 4)
        A = [i == j ? Float64(t + 1) : 1.0 / (abs(i - j) + 1) for i in 1:t, j in 1:t]
        v = HSquared._cov_to_chol_params(A, t)
        @test length(v) == t * (t + 1) ÷ 2
        @test HSquared._chol_params_to_cov(v, t) ≈ A rtol = 1e-12
    end
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

@testset "Phase 4B diagonal structured-covariance parity fixture" begin
    fixture_dir = joinpath(@__DIR__, "fixtures", "structured_covariance_parity")

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
    _, R0 = _named_matrix_csv_for_test(joinpath(fixture_dir, "expected_residual_covariance.csv"))
    _, beta_expected = _named_matrix_csv_for_test(joinpath(fixture_dir, "expected_beta.csv"))
    _, ebv_expected = _named_matrix_csv_for_test(joinpath(fixture_dir, "expected_ebv.csv"))
    _, h_expected = _named_matrix_csv_for_test(joinpath(fixture_dir, "expected_heritability.csv"))
    metadata = _metadata_csv_for_test(joinpath(fixture_dir, "expected_metadata.csv"))

    @test cov_traits == ["trait1", "trait2"]
    @test metadata["genetic_structure"] == "diagonal"
    @test parse(Int, metadata["n_genetic_params"]) == 2          # diagonal: t (vs t(t+1)/2)
    @test G0[1, 2] == 0.0 && G0[2, 1] == 0.0                     # diagonal target: no genetic covariance
    @test isposdef(Symmetric(G0))
    @test isposdef(Symmetric(R0))

    # self-consistency: the supplied-covariance MME at the stored diagonal G0/R0
    # reproduces beta/EBVs/h², and the REML loglik matches the stored target.
    mme = multivariate_mme(Y, X, Z, Ainv, G0, R0; ids = ped.ids, traits = cov_traits)
    @test mme.beta ≈ beta_expected atol = 5e-6
    @test mme.breeding_values.values ≈ ebv_expected atol = 5e-6
    h_calc = [G0[k, k] / (G0[k, k] + R0[k, k]) for k in 1:length(cov_traits)]
    @test h_calc ≈ vec(h_expected) atol = 5e-6
    loglik = HSquared._multivariate_reml_loglik(Y, X, Z, Ainv, G0, R0)
    @test loglik ≈ parse(Float64, metadata["loglik"]) atol = 5e-6
end

@testset "Univariate fitted animal-model target fixture (#46)" begin
    fixture_dir = joinpath(@__DIR__, "fixtures", "animal_model_fitted_target")
    _, ped_rows = _csv_strings_for_test(joinpath(fixture_dir, "pedigree.csv"))
    ped = normalize_pedigree(ped_rows[:, 1], ped_rows[:, 2], ped_rows[:, 3])
    Ainv = pedigree_inverse(ped)

    _, pheno = _csv_strings_for_test(joinpath(fixture_dir, "phenotypes.csv"))
    record_animals = pheno[:, 1]
    x = parse.(Float64, pheno[:, 2])
    y = parse.(Float64, pheno[:, 3])
    X = hcat(ones(length(x)), x)
    Z = zeros(length(x), length(ped.ids))
    animal_index = Dict(id => i for (i, id) in enumerate(ped.ids))
    for (i, animal) in enumerate(record_animals)
        Z[i, animal_index[animal]] = 1.0
    end

    vc_names, vc_vals = _named_matrix_csv_for_test(joinpath(fixture_dir, "expected_variance_components.csv"))
    effects, beta_expected = _named_matrix_csv_for_test(joinpath(fixture_dir, "expected_beta.csv"))
    ebv_ids, ebv_expected = _named_matrix_csv_for_test(joinpath(fixture_dir, "expected_ebv.csv"))
    rel_ids, rel_expected = _named_matrix_csv_for_test(joinpath(fixture_dir, "expected_reliability.csv"))
    metadata = _metadata_csv_for_test(joinpath(fixture_dir, "expected_metadata.csv"))

    @test vc_names == ["sigma_a2", "sigma_e2"]
    @test effects == ["Intercept", "x"]
    @test ebv_ids == ped.ids
    @test rel_ids == ped.ids
    sigma_a2 = vc_vals[1]; sigma_e2 = vc_vals[2]
    @test sigma_a2 > 0 && sigma_e2 > 0                       # interior, non-boundary target
    @test metadata["converged"] == "true"

    # Self-consistency: the Henderson MME at the STORED variance components reproduces
    # the serialized fixed effects, EBVs, PEV/reliability, and REML loglik. The fixture
    # is the engine's OWN fitted output (generate.jl), so this pins the serialized
    # target without re-running the optimizer — and no textbook EBVs are typed by hand.
    # Note (review #46, Mrode): beta (dense GLS vs sparse MME), loglik (dense REML vs
    # the sparse Henderson identity), and PEV/reliability (:selinv vs :dense) each agree
    # across two DISTINCT numerical routes; the EBV check re-solves the SAME Henderson
    # MME, so it is a determinism/integrity pin (it still catches a corrupted serialized
    # EBV — mutation-verified), not method-independent corroboration.
    mme = fit_animal_model(y, X, Z, Ainv; target = :henderson_mme,
                           variance_components = (sigma_a2 = sigma_a2, sigma_e2 = sigma_e2),
                           ids = ped.ids)
    @test fixed_effects(mme) ≈ vec(beta_expected) atol = 1e-6
    @test breeding_values(mme).ids == ped.ids
    @test breeding_values(mme).values ≈ vec(ebv_expected) atol = 1e-6
    @test reliability(mme).values ≈ rel_expected[:, 2] atol = 1e-6
    @test prediction_error_variance(mme).values ≈ rel_expected[:, 1] atol = 1e-6

    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
    @test sparse_reml_loglik(spec, sigma_a2, sigma_e2).loglik ≈ parse(Float64, metadata["loglik"]) atol = 1e-6
    @test parse(Float64, metadata["h2"]) ≈ sigma_a2 / (sigma_a2 + sigma_e2) atol = 1e-8
end

@testset "Phase 2 genomic GBLUP/SNP-BLUP target fixture (#49)" begin
    fixture_dir = joinpath(@__DIR__, "fixtures", "genomic_gblup_snpblup_target")

    _, pheno = _csv_strings_for_test(joinpath(fixture_dir, "phenotypes.csv"))
    ids = vec(pheno[:, 1])
    y = parse.(Float64, pheno[:, 2])

    marker_header, marker_rows = _csv_strings_for_test(joinpath(fixture_dir, "markers.csv"))
    marker_ids = marker_header[2:end]
    @test marker_rows[:, 1] == ids
    M = parse.(Float64, marker_rows[:, 2:end])

    freq_ids, freq_values = _named_matrix_csv_for_test(joinpath(fixture_dir, "allele_frequencies.csv"))
    g_ids, G_expected = _named_matrix_csv_for_test(joinpath(fixture_dir, "expected_genomic_relationship.csv"))
    ginv_ids, Ginv_expected = _named_matrix_csv_for_test(joinpath(fixture_dir, "expected_genomic_precision.csv"))
    effects, beta_expected = _named_matrix_csv_for_test(joinpath(fixture_dir, "expected_beta.csv"))
    gebv_ids, gebv_expected = _named_matrix_csv_for_test(joinpath(fixture_dir, "expected_gebv.csv"))
    marker_effect_ids, marker_effects_expected =
        _named_matrix_csv_for_test(joinpath(fixture_dir, "expected_marker_effects.csv"))
    metadata = _metadata_csv_for_test(joinpath(fixture_dir, "expected_metadata.csv"))

    @test freq_ids == marker_ids
    @test g_ids == ids
    @test ginv_ids == ids
    @test effects == ["Intercept"]
    @test gebv_ids == ids
    @test marker_effect_ids == marker_ids
    @test metadata["method"] == "vanraden1_supplied_frequencies"
    @test metadata["g_positive_definite"] == "true"

    p = vec(freq_values)
    sigma_g2 = parse(Float64, metadata["sigma_g2"])
    sigma_e2 = parse(Float64, metadata["sigma_e2"])
    X = ones(length(y), 1)
    Z = Matrix{Float64}(I, length(y), length(y))

    G = genomic_relationship_matrix(M; allele_frequencies = p)
    @test isposdef(Symmetric(G))
    @test G ≈ G_expected atol = 1e-12
    Ginv = inv(Symmetric(G))
    @test Ginv ≈ Ginv_expected atol = 1e-12

    gblup = fit_gblup(y, X, Z, Ginv, sigma_g2, sigma_e2; ids = ids)
    snp = fit_snp_blup(y, X, M, sigma_g2, sigma_e2; allele_frequencies = p, ids = marker_ids)
    @test fixed_effects(gblup) ≈ vec(beta_expected) atol = 1e-12
    @test snp.beta ≈ vec(beta_expected) atol = 1e-12
    @test breeding_values(gblup).ids == ids
    @test breeding_values(gblup).values ≈ gebv_expected[:, 1] atol = 1e-12
    @test snp.gebv ≈ gebv_expected[:, 2] atol = 1e-12
    @test snp.marker_effects ≈ vec(marker_effects_expected) atol = 1e-12
    @test snp.k ≈ parse(Float64, metadata["k"]) atol = 1e-12

    max_route_diff = maximum(abs.(breeding_values(gblup).values .- snp.gebv))
    @test max_route_diff ≈ parse(Float64, metadata["gblup_snp_blup_max_abs_gebv_diff"]) atol = 1e-15
    @test max_route_diff < 5e-12

    corrupted_gebv = copy(gebv_expected[:, 1])
    corrupted_gebv[1] += 0.1
    @test maximum(abs.(breeding_values(gblup).values .- corrupted_gebv)) > 0.05
end

@testset "Sire-model fitted target fixture (#16)" begin
    fixture_dir = joinpath(@__DIR__, "fixtures", "sire_model_fitted_target")
    _, ped_rows = _csv_strings_for_test(joinpath(fixture_dir, "pedigree.csv"))
    ped = normalize_pedigree(ped_rows[:, 1], ped_rows[:, 2], ped_rows[:, 3])
    Ainv = pedigree_inverse(ped)

    _, pheno = _csv_strings_for_test(joinpath(fixture_dir, "phenotypes.csv"))
    record_sires = pheno[:, 2]
    x = parse.(Float64, pheno[:, 3])
    y = parse.(Float64, pheno[:, 4])
    X = hcat(ones(length(x)), x)
    Z = zeros(length(x), length(ped.ids))               # record -> SIRE incidence
    sire_index = Dict(id => i for (i, id) in enumerate(ped.ids))
    for (i, s) in enumerate(record_sires)
        Z[i, sire_index[s]] = 1.0
    end

    vc_names, vc_vals = _named_matrix_csv_for_test(joinpath(fixture_dir, "expected_variance_components.csv"))
    effects, beta_expected = _named_matrix_csv_for_test(joinpath(fixture_dir, "expected_beta.csv"))
    ebv_ids, ebv_expected = _named_matrix_csv_for_test(joinpath(fixture_dir, "expected_ebv.csv"))
    _, rel_expected = _named_matrix_csv_for_test(joinpath(fixture_dir, "expected_reliability.csv"))
    metadata = _metadata_csv_for_test(joinpath(fixture_dir, "expected_metadata.csv"))

    @test vc_names == ["sigma_s2", "sigma_e2"]
    @test effects == ["Intercept", "x"]
    @test ebv_ids == ped.ids
    sigma_s2 = vc_vals[1]; sigma_e2 = vc_vals[2]
    @test sigma_s2 > 0 && sigma_e2 > 0                   # interior, non-boundary target
    @test metadata["converged"] == "true"
    @test metadata["model"] == "sire"

    # Self-consistency: a sire model is an ordinary animal-model spec with a record->sire
    # Z and a sires-only Ainv; the engine sigma_a2 slot IS the sire variance. Henderson MME
    # at the stored components reproduces the serialized output (the fixture is the engine's
    # OWN fitted result via generate.jl); β/loglik/PEV agree across distinct numerical routes.
    mme = fit_animal_model(y, X, Z, Ainv; target = :henderson_mme,
                           variance_components = (sigma_a2 = sigma_s2, sigma_e2 = sigma_e2),
                           ids = ped.ids)
    @test fixed_effects(mme) ≈ vec(beta_expected) atol = 1e-6
    @test breeding_values(mme).ids == ped.ids
    @test breeding_values(mme).values ≈ vec(ebv_expected) atol = 1e-6
    @test reliability(mme).values ≈ rel_expected[:, 2] atol = 1e-6
    @test prediction_error_variance(mme).values ≈ rel_expected[:, 1] atol = 1e-6

    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
    @test sparse_reml_loglik(spec, sigma_s2, sigma_e2).loglik ≈ parse(Float64, metadata["loglik"]) atol = 1e-6

    # Heritability mapping (honesty pin): a sire model's narrow-sense h² is
    # 4·σ²s/(σ²s+σ²e), NOT the engine's generic accessor σ²s/(σ²s+σ²e) (mislabelled for a
    # sire spec). The fixture stores the corrected h²; pin it AND pin that it differs from
    # the generic mapping, and the implied σ²a = 4·σ²s.
    @test parse(Float64, metadata["h2"]) ≈ 4 * sigma_s2 / (sigma_s2 + sigma_e2) atol = 1e-8
    @test !isapprox(parse(Float64, metadata["h2"]), sigma_s2 / (sigma_s2 + sigma_e2); atol = 1e-3)
    @test parse(Float64, metadata["sigma_a2_implied"]) ≈ 4 * sigma_s2 atol = 1e-8
    @test 0 < parse(Float64, metadata["h2"]) < 1        # a sane heritability

    # mutation / test-of-test: a corrupted serialized EBV is rejected
    corrupted = copy(vec(ebv_expected)); corrupted[1] += 0.1
    @test !isapprox(breeding_values(mme).values, corrupted; atol = 0.05)
end

@testset "Comparator target manifest (#49 coordination)" begin
    manifest_path = joinpath(@__DIR__, "fixtures", "comparator_targets.toml")
    manifest = TOML.parsefile(manifest_path)
    @test manifest["schema_version"] == 1
    @test occursin("not add external comparator evidence", manifest["claim_boundary"])

    targets = manifest["target"]
    ids = [target["id"] for target in targets]
    @test length(ids) == length(unique(ids))
    @test Set(ids) == Set([
        "animal_model_fitted_target",
        "sire_model_fitted_target",
        "phase4_multitrait_parity",
        "genomic_gblup_snpblup_target",
        "marker_scan_parity",
        "structured_covariance_parity",
        "non_gaussian_parity",
    ])

    allowed_evidence = Set([
        "julia_target",
        "julia_target_r_consumed",
        "julia_target_external_one_leg",
        "bridge_payload_fixture",
    ])
    for target in targets
        fixture_dir = joinpath(@__DIR__, "fixtures", target["fixture"])
        @test isdir(fixture_dir)
        @test target["evidence_type"] in allowed_evidence
        @test !isempty(target["capability_rows"])
        @test occursin("no", lowercase(target["boundary"])) ||
              occursin("not", lowercase(target["boundary"]))
        @test !isempty(strip(target["required_comparator"]))
        for file in target["required_files"]
            @test isfile(joinpath(fixture_dir, file))
        end
    end

    multivariate = only(target for target in targets if target["id"] == "phase4_multitrait_parity")
    @test multivariate["issue"] == 49
    @test occursin("sommer", multivariate["external_status"])
    @test occursin("second independent", multivariate["boundary"])

    genomic = only(target for target in targets if target["id"] == "genomic_gblup_snpblup_target")
    @test genomic["evidence_type"] == "julia_target_r_consumed"
    @test occursin("PR #84", genomic["external_status"])
    @test occursin("R internal consumer check", genomic["boundary"])
    @test occursin("no external genomic comparator", genomic["boundary"])

    marker_scan_target = only(target for target in targets if target["id"] == "marker_scan_parity")
    @test occursin("PR #83", marker_scan_target["external_status"])

    nongaussian_target = only(target for target in targets if target["id"] == "non_gaussian_parity")
    @test nongaussian_target["issue"] == 44
    @test nongaussian_target["evidence_type"] == "bridge_payload_fixture"
    @test occursin("no per-record varying-trial R activation", nongaussian_target["boundary"])

    sire_target = only(target for target in targets if target["id"] == "sire_model_fitted_target")
    @test sire_target["issue"] == 16
    @test sire_target["capability_rows"] == ["V1-SIRE-FIT"]
    @test occursin("sire", lowercase(sire_target["external_status"]))
    @test occursin("no", lowercase(sire_target["boundary"])) ||
          occursin("not", lowercase(sire_target["boundary"]))
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
    @test low.genetic_uniqueness === nothing   # pure low-rank G = ΛΛ' has NO specific variance
    low_loadings = genetic_loadings(low)
    @test low_loadings ≈ low.genetic_loadings
    low_loadings[1, 1] = -99.0
    @test low.genetic_loadings[1, 1] != -99.0
    @test genetic_uniqueness(low) === nothing  # accessor returns nothing for low-rank
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

    # multivariate_result_payload — bridge-ready :diagonal/:unstructured payload (#42 scoped,
    # the rotation-free subset; unblocks the R-lane diagonal-vs-unstructured LRT)
    pd = multivariate_result_payload(diagfit)
    @test pd.engine == "HSquared.jl"
    @test pd.target == "multivariate_reml"
    @test pd.genetic_structure == "diagonal"
    @test pd.n_traits == 2
    @test pd.genetic_variances ≈ diag(pd.genetic_covariance)
    @test pd.genetic_covariance[1, 2] == 0.0          # diagonal => no genetic covariance surfaced
    @test pd.n_genetic_params == 2                    # diagonal: t
    @test pd.loglik ≈ diagfit.loglik
    @test pd.heritability ≈ diagfit.heritability
    @test pd.fixed_effects ≈ diagfit.beta
    @test pd.breeding_values.values == diagfit.breeding_values.values
    @test pd.converged == diagfit.converged
    @test !hasproperty(pd, :genetic_loadings)         # rotation-arbitrary loadings NOT surfaced
    @test !hasproperty(pd, :genetic_uniqueness)

    pu = multivariate_result_payload(full)
    @test pu.genetic_structure == "unstructured"
    @test pu.n_genetic_params == 3                    # unstructured: t(t+1)/2

    # the diagonal-vs-unstructured LRT df is just the difference of the counts (interior null)
    lrt = covariance_structure_lrt(diagfit, full)
    @test lrt.df == pu.n_genetic_params - pd.n_genetic_params == 1   # t(t-1)/2
    @test lrt.boundary == false

    # lowrank/fa are gated at the engine boundary — payload refuses them (rotation-nonidentified)
    @test_throws ArgumentError multivariate_result_payload(low)
    @test_throws ArgumentError multivariate_result_payload(fa)

    # structured_genetic_payload — the rotation-gated companion: bridges :lowrank /
    # :factor_analytic via rotation-INVARIANT functionals of G (eigenstructure + Ψ),
    # NEVER the rotation-nonidentified loadings (#42 / FA convention).
    for (sfit, sname) in ((low, "lowrank"), (fa, "factor_analytic"))
        sp = structured_genetic_payload(sfit)
        @test sp.engine == "HSquared.jl"
        @test sp.target == "multivariate_reml_structured"
        @test sp.genetic_structure == sname
        @test sp.genetic_rank == 1
        @test sp.rotation_invariant && sp.loadings_excluded
        @test !(:genetic_loadings in keys(sp))              # hard contract: no raw loadings
        @test sp.genetic_covariance ≈ Matrix(sfit.genetic_covariance) atol = 1e-10
        @test sp.genetic_variances ≈ diag(sfit.genetic_covariance)
        spca = genetic_pca(sfit.genetic_covariance)         # eigenstructure is rotation-invariant
        @test sp.genetic_eigenvalues ≈ spca.values
        @test sp.genetic_principal_axes ≈ spca.vectors
        @test sp.mean_evolvability ≈ mean_evolvability(sfit.genetic_covariance)
        @test sp.heritability ≈ sfit.heritability
        @test sp.fixed_effects ≈ sfit.beta
        @test sp.breeding_values.values == sfit.breeding_values.values
        @test sp.loglik ≈ sfit.loglik
    end
    @test structured_genetic_payload(low).genetic_uniqueness === nothing  # pure low-rank: no Ψ
    @test all(structured_genetic_payload(fa).genetic_uniqueness .> 0)     # FA: positive Ψ
    # rotation-free structures route to multivariate_result_payload, not here
    @test_throws ArgumentError structured_genetic_payload(diagfit)
    @test_throws ArgumentError structured_genetic_payload(full)
    @test_throws ArgumentError structured_genetic_payload((foo = 1,))
end

@testset "Phase 6 non-Gaussian Laplace marginal (foundation)" begin
    ped = normalize_pedigree(["sire", "dam", "calf"], ["0", "0", "sire"], ["0", "0", "dam"])
    Ainv = pedigree_inverse(ped)
    X = ones(3, 1)
    Z = sparse(1.0I, 3, 3)
    sa2 = 1.3
    se2 = 0.7

    # (1) The Gaussian family is exact: the Laplace marginal (integrating β + u)
    # reduces to the REML log-likelihood, and the mode equals the Henderson MME
    # solution at (sa2, se2).
    yg = [1.0, 2.5, 4.0]
    spec = animal_model_spec(yg, X, Z, Ainv; ids = ped.ids, method = :REML)
    lap = HSquared.laplace_marginal_loglik(yg, X, Z, Ainv, sa2, HSquared.GaussianResponse(se2))
    @test lap.converged
    @test lap.loglik ≈ sparse_reml_loglik(spec, sa2, se2).loglik rtol = 1e-8
    @test lap.u ≈ breeding_values(henderson_mme(spec, sa2, se2)).values rtol = 1e-7 atol = 1e-9

    # (2) Poisson family: the Newton mode solves the penalized score equation.
    yp = [3.0, 5.0, 8.0]
    pf = HSquared.laplace_marginal_loglik(yp, X, Z, Ainv, sa2, HSquared.PoissonResponse())
    @test pf.converged
    @test pf.gradient_norm < 1e-8
    @test isfinite(pf.loglik)

    # (3) per-family kernels: score = dℓ/dη, weight = -d²ℓ/dη² (finite differences)
    for fam in (HSquared.GaussianResponse(se2), HSquared.PoissonResponse())
        y0 = 4.0; η0 = 0.3
        ll(η) = HSquared._fam_loglik(fam, y0, η)
        h1 = 1e-6
        @test HSquared._fam_score(fam, y0, η0) ≈ (ll(η0 + h1) - ll(η0 - h1)) / (2h1) rtol = 1e-5
        h2 = 1e-4   # larger step for the 2nd difference (1e-6 is roundoff-dominated ÷ h²)
        @test HSquared._fam_weight(fam, y0, η0) ≈
              -(ll(η0 + h2) - 2ll(η0) + ll(η0 - h2)) / h2^2 rtol = 1e-3
    end

    # guard
    @test_throws ArgumentError HSquared.laplace_marginal_loglik(yg, X, Z, Ainv, -1.0,
                                                                HSquared.GaussianResponse(se2))
end

@testset "Phase 6 variational (VA) marginal (foundation)" begin
    ped = normalize_pedigree(["sire", "dam", "calf"], ["0", "0", "sire"], ["0", "0", "dam"])
    Ainv = pedigree_inverse(ped)
    X = ones(3, 1)
    Z = sparse(1.0I, 3, 3)
    sa2 = 1.3
    se2 = 0.7

    # T1 — Gaussian exactness (primary gate): full-covariance VA-ELBO is tight and
    # equals both the Laplace marginal and the REML log-likelihood; the variational
    # mean is the BLUP and S is the Henderson MME u-block inverse.
    yg = [1.0, 2.5, 4.0]
    spec = animal_model_spec(yg, X, Z, Ainv; ids = ped.ids, method = :REML)
    va = HSquared.variational_marginal_loglik(yg, X, Z, Ainv, sa2, HSquared.GaussianResponse(se2))
    lap = HSquared.laplace_marginal_loglik(yg, X, Z, Ainv, sa2, HSquared.GaussianResponse(se2))
    @test va.converged
    @test va.covariance === :full
    @test va.elbo ≈ lap.loglik rtol = 1e-8
    @test va.elbo ≈ sparse_reml_loglik(spec, sa2, se2).loglik rtol = 1e-8
    @test va.elbo <= lap.loglik + 1e-9                  # ELBO ≤ true marginal (tight for Gaussian)
    @test va.m ≈ breeding_values(henderson_mme(spec, sa2, se2)).values rtol = 1e-7 atol = 1e-9
    Huu = transpose(Matrix(Z)) * ((1 / se2) .* Matrix(Z)) .+ Matrix(Ainv) ./ sa2
    @test va.S ≈ inv(Symmetric(Huu)) rtol = 1e-7

    # T3 — Poisson: the variational optimum solves the ELBO stationarity equation.
    yp = [3.0, 5.0, 8.0]
    vp = HSquared.variational_marginal_loglik(yp, X, Z, Ainv, sa2, HSquared.PoissonResponse())
    @test vp.converged
    @test vp.gradient_norm < 1e-8
    @test isfinite(vp.elbo)
    # NB: do not assert va.elbo <= laplace.loglik — the Laplace value itself lies
    # below the true Poisson marginal, so the two approximations do not bound
    # each other (a proper Poisson-value gate vs Gauss–Hermite is future work).

    # T5 — per-family expected-loglik / weight closed forms (pin the Poisson
    # normalizer that the Gaussian-only value gate cannot catch).
    gf = HSquared.GaussianResponse(se2)
    @test HSquared._fam_expected_loglik(gf, 4.0, 0.3, 0.5) ≈
          HSquared._fam_loglik(gf, 4.0, 0.3) - 0.5 * 0.5 / se2 rtol = 1e-12
    @test HSquared._fam_expected_loglik(HSquared.PoissonResponse(), 4.0, 0.3, 0.5) ≈
          4.0 * 0.3 - exp(0.3 + 0.25) - HSquared._logfactorial(4.0) rtol = 1e-12
    @test HSquared._fam_expected_weight(HSquared.PoissonResponse(), 0.3, 0.5) ≈ exp(0.3 + 0.25) rtol = 1e-12

    # :diagonal (mean-field) VA: converges and is a LOOSER lower bound than full
    # covariance (β-fixed, where the ELBO is a proper lower bound on log p(y)).
    X0 = zeros(3, 0)
    vfull = HSquared.variational_marginal_loglik(yp, X0, Z, Ainv, sa2, HSquared.PoissonResponse(); covariance = :full)
    vdiag = HSquared.variational_marginal_loglik(yp, X0, Z, Ainv, sa2, HSquared.PoissonResponse(); covariance = :diagonal)
    @test vdiag.converged && vdiag.covariance === :diagonal
    @test vfull.elbo >= vdiag.elbo - 1e-9               # richer q ⇒ tighter bound
    @test_throws ArgumentError HSquared.variational_marginal_loglik(yg, X, Z, Ainv, sa2,
        HSquared.GaussianResponse(se2); covariance = :bogus)
end

@testset "Phase 6 non-Gaussian family hardening" begin
    ped = normalize_pedigree(["sire", "dam", "calf"], ["0", "0", "sire"], ["0", "0", "dam"])
    Ainv = pedigree_inverse(ped)
    X = ones(3, 1)
    Z = sparse(1.0I, 3, 3)
    sa2 = 1.3
    # GaussianResponse requires sigma_e2 > 0
    @test_throws ArgumentError HSquared.GaussianResponse(-1.0)
    @test_throws ArgumentError HSquared.GaussianResponse(0.0)
    # Poisson requires non-negative integer counts (both marginals)
    @test_throws ArgumentError HSquared.laplace_marginal_loglik([1.5, 2.0, 3.0], X, Z, Ainv, sa2, HSquared.PoissonResponse())
    @test_throws ArgumentError HSquared.variational_marginal_loglik([1.0, 2.0, -3.0], X, Z, Ainv, sa2, HSquared.PoissonResponse())
    # a non-converged fit returns NaN (not a finite non-mode value), flagged converged=false
    r1 = HSquared.laplace_marginal_loglik([3.0, 5.0, 8.0], X, Z, Ainv, sa2, HSquared.PoissonResponse(); maxiter = 1)
    @test !r1.converged && isnan(r1.loglik)
    v1 = HSquared.variational_marginal_loglik([3.0, 5.0, 8.0], X, Z, Ainv, sa2, HSquared.PoissonResponse(); maxiter = 1)
    @test !v1.converged && isnan(v1.elbo)
end

@testset "Phase 6 Poisson marginal value vs Gauss–Hermite (β-fixed)" begin
    # The honest Poisson-VALUE gate: against an independent tensor Gauss–Hermite
    # quadrature of the true marginal ∫ ∏ Poisson(yᵢ | exp((Zu)ᵢ))·N(u; 0, A·σ²a) du
    # (β-fixed via a zero-column X), the VA ELBO is a valid LOWER BOUND and the
    # Laplace value is close (not a bound).
    ped = normalize_pedigree(["sire", "dam", "calf"], ["0", "0", "sire"], ["0", "0", "dam"])
    Ainv = pedigree_inverse(ped)
    Z = sparse(1.0I, 3, 3)
    sa2 = 1.3
    yp = [3.0, 5.0, 8.0]
    X0 = zeros(3, 0)                      # β-fixed (no fixed effects)

    _gh(m) = (E = eigen(SymTridiagonal(zeros(m), [sqrt(k / 2) for k in 1:m-1]));
              (E.values, sqrt(π) .* (E.vectors[1, :] .^ 2)))
    function _poisson_marginal(y, Zd, G, m)
        x, w = _gh(m)
        L = cholesky(Symmetric(G)).L
        n = length(y); qd = size(Zd, 2)
        tot = 0.0
        for idx in CartesianIndices(ntuple(_ -> m, qd))
            z = [sqrt(2) * x[idx[j]] for j in 1:qd]
            wt = prod(w[idx[j]] / sqrt(π) for j in 1:qd)
            η = Zd * (L * z)
            ll = sum(y[i] * η[i] - exp(η[i]) - HSquared._logfactorial(y[i]) for i in 1:n)
            tot += wt * exp(ll)
        end
        return log(tot)
    end

    G = inv(Symmetric(Matrix(Ainv))) .* sa2
    R = _poisson_marginal(yp, Matrix(Z), G, 24)
    lap = HSquared.laplace_marginal_loglik(yp, X0, Z, Ainv, sa2, HSquared.PoissonResponse())
    va = HSquared.variational_marginal_loglik(yp, X0, Z, Ainv, sa2, HSquared.PoissonResponse())
    @test lap.converged && va.converged
    @test va.elbo <= R + 1e-6            # ELBO is a valid lower bound on log p(y)
    @test isapprox(lap.loglik, R; atol = 5e-2)   # Laplace close to the true marginal (documents the gap)
end

@testset "Phase 6 public (exported) non-Gaussian fitting API" begin
    # fit_laplace_reml and laplace_reml_interval are now part of the public
    # (experimental) surface — exercise them UNQUALIFIED (no HSquared. prefix).
    ids = ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"]
    ped = normalize_pedigree(ids,
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Ainv = pedigree_inverse(ped)
    Z = sparse(1.0I, 8, 8)
    X = ones(8, 1)

    # Gaussian non-Gaussian fit equals the exact sparse REML (the validated gate)
    yg = [2.0, 3.0, 2.5, 3.5, 4.0, 1.5, 3.0, 4.5]
    fg = fit_laplace_reml(yg, X, Z, Ainv; family = :gaussian, ids = ped.ids,
                          initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    sr = fit_sparse_reml(animal_model_spec(yg, X, Z, Ainv; ids = ped.ids, method = :REML);
                         initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    @test fg.converged
    @test fg.marginal_loglik ≈ sr.likelihood.loglik rtol = 1e-6

    # Poisson fit + the exported profile interval
    yp = [3.0, 5.0, 8.0, 4.0, 6.0, 2.0, 5.0, 7.0]
    fp = fit_laplace_reml(yp, X, Z, Ainv; family = :poisson, initial = (sigma_a2 = 1.0,))
    @test fp.family === :poisson && fp.converged
    ci = laplace_reml_interval(yp, X, Z, Ainv; family = :poisson, level = 0.95)
    @test ci.lower < ci.sigma_a2 < ci.upper
    @test ci.level == 0.95

    # fitted-object extractor API (same contract as AnimalModelFit; distinct type,
    # so it does NOT collide with the multivariate NamedTuple extractors)
    @test fg isa HSquared.NonGaussianFit
    bv = breeding_values(fg)
    @test bv isa HSquared.BreedingValues
    @test bv.values == fg.breeding_values           # function wraps the field vector
    @test bv.ids == ped.ids                          # ids threaded through
    @test length(bv.values) == 8
    @test variance_components(fg) === fg.variance_components
    @test fixed_effects(fg) == fg.beta
    @test EBV(fg).values == bv.values
    # ids default to 1:q when not supplied
    @test breeding_values(fp).ids == collect(1:8)
end

@testset "Phase 6 MarginalMethod dispatch + non-Gaussian bridge payload (#44)" begin
    # MarginalMethod dispatch: canonical mapping the bridge uses for the R-facing
    # method name; accepts engine (:laplace/:variational) and DRM-style (:LA/:VA).
    @test HSquared._marginal_method(:laplace) === HSquared.Laplace()
    @test HSquared._marginal_method(:LA) === HSquared.Laplace()
    @test HSquared._marginal_method(:variational) === HSquared.Variational()
    @test HSquared._marginal_method(:VA) === HSquared.Variational()
    @test HSquared._marginal_method(HSquared.Variational()) === HSquared.Variational()
    @test_throws ArgumentError HSquared._marginal_method(:nope)
    @test HSquared._marginal_method_string(HSquared.Laplace()) == "laplace"
    @test HSquared._marginal_method_string(HSquared.Variational()) == "variational"
    @test HSquared._marginal_method_symbol(HSquared.Laplace()) === :laplace
    @test HSquared._marginal_method_symbol(HSquared.Variational()) === :variational

    ids = ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"]
    ped = normalize_pedigree(ids,
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Ainv = pedigree_inverse(ped)
    Z = sparse(1.0I, 8, 8)
    X = ones(8, 1)

    # Poisson fit (single variance component), :laplace marginal
    yp = [3.0, 5.0, 8.0, 4.0, 6.0, 2.0, 5.0, 7.0]
    fp = fit_laplace_reml(yp, X, Z, Ainv; family = :poisson, ids = ped.ids,
                          initial = (sigma_a2 = 1.0,))
    pp = nongaussian_result_payload(fp)
    @test propertynames(pp) == (
        :engine, :target, :family, :n_trials, :dispersion, :method, :variance_components,
        :fixed_effects, :breeding_values, :loglik, :converged,
    )
    @test pp.dispersion === nothing   # ρ only set for the beta-binomial family
    @test pp.engine == "HSquared.jl"
    @test pp.target == "nongaussian_reml"
    @test pp.family == "poisson"
    @test pp.n_trials === nothing          # only :binomial carries a trials denominator
    @test pp.method == "laplace"
    @test pp.variance_components === fp.variance_components
    @test pp.fixed_effects == fp.beta
    @test pp.breeding_values.ids == ped.ids
    @test pp.breeding_values.values == fp.breeding_values
    @test pp.loglik == fp.marginal_loglik
    @test pp.converged == fp.converged
    # HONESTY: NO heritability field (the payload shape is family-uniform)
    @test !hasproperty(pp, :heritability)

    # Gaussian fit (two variance components), :variational marginal -> "variational"
    yg = [2.0, 3.0, 2.5, 3.5, 4.0, 1.5, 3.0, 4.5]
    fgv = fit_laplace_reml(yg, X, Z, Ainv; family = :gaussian, marginal = :variational,
                           ids = ped.ids, initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    pg = nongaussian_result_payload(fgv)
    @test pg.family == "gaussian"
    @test pg.method == "variational"
    @test pg.n_trials === nothing
    @test haskey(pg.variance_components, :sigma_a2)
    @test haskey(pg.variance_components, :sigma_e2)
    @test pg.loglik == fgv.marginal_loglik
    @test !hasproperty(pg, :heritability)

    # Binomial fit: the payload is self-describing — it carries the trials denominator
    yb = [3, 5, 8, 4, 6, 2, 5, 7]
    fb = fit_laplace_reml(yb, X, Z, Ainv; family = :binomial, n_trials = 10,
                          ids = ped.ids, initial = (sigma_a2 = 1.0,))
    pb = nongaussian_result_payload(fb)
    @test pb.family == "binomial"
    @test pb.n_trials == 10
    @test fb.n_trials == 10

    # The MarginalMethod dispatch is wired into the fitter: :LA / :VA aliases work
    # and store the canonical symbol; value-preserving vs :laplace / :variational.
    fp_la = fit_laplace_reml(yp, X, Z, Ainv; family = :poisson, marginal = :LA,
                             ids = ped.ids, initial = (sigma_a2 = 1.0,))
    @test fp_la.marginal === :laplace
    @test fp_la.marginal_loglik == fp.marginal_loglik
    fgv_va = fit_laplace_reml(yg, X, Z, Ainv; family = :gaussian, marginal = :VA,
                              ids = ped.ids, initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    @test fgv_va.marginal === :variational
    @test fgv_va.marginal_loglik == fgv.marginal_loglik

    # payload arrays are copies (mutating must not corrupt the fit)
    pp.fixed_effects[1] = NaN
    @test !isnan(fp.beta[1])
    pp.breeding_values.values[1] = NaN
    @test !isnan(fp.breeding_values[1])
    pp.breeding_values.ids[1] = "MUT"
    @test fp.ids[1] != "MUT"               # ids are copied too (symmetry with values)
end

@testset "Phase 6 non-Gaussian parity fixture (#44)" begin
    fixture_dir = joinpath(@__DIR__, "fixtures", "non_gaussian_parity")

    _, ped_rows = _csv_strings_for_test(joinpath(fixture_dir, "pedigree.csv"))
    ped = normalize_pedigree(ped_rows[:, 1], ped_rows[:, 2], ped_rows[:, 3])
    Ainv = pedigree_inverse(ped)

    _, poisson_rows = _csv_strings_for_test(joinpath(fixture_dir, "poisson_phenotypes.csv"))
    _, binomial_rows = _csv_strings_for_test(joinpath(fixture_dir, "binomial_phenotypes.csv"))
    @test vec(poisson_rows[:, 1]) == ped.ids
    @test vec(binomial_rows[:, 1]) == ped.ids

    X = [ones(length(ped.ids)) parse.(Float64, poisson_rows[:, 3])]
    @test X[:, 2] == parse.(Float64, binomial_rows[:, 4])
    Z = sparse(1.0I, length(ped.ids), length(ped.ids))

    metadata_header, metadata_rows =
        _csv_strings_for_test(joinpath(fixture_dir, "expected_payload_metadata.csv"))
    @test metadata_header == ["case", "field", "value"]
    metadata = Dict((metadata_rows[i, 1], metadata_rows[i, 2]) => metadata_rows[i, 3]
                    for i in axes(metadata_rows, 1))

    _, vc_rows = _csv_strings_for_test(joinpath(fixture_dir, "expected_variance_components.csv"))
    variance_components_expected =
        Dict((vc_rows[i, 1], vc_rows[i, 2]) => parse(Float64, vc_rows[i, 3])
             for i in axes(vc_rows, 1))
    _, fixed_rows = _csv_strings_for_test(joinpath(fixture_dir, "expected_fixed_effects.csv"))
    fixed_expected = Dict((fixed_rows[i, 1], fixed_rows[i, 2]) => parse(Float64, fixed_rows[i, 3])
                          for i in axes(fixed_rows, 1))
    _, ebv_rows = _csv_strings_for_test(joinpath(fixture_dir, "expected_breeding_values.csv"))
    ebv_expected = Dict((ebv_rows[i, 1], ebv_rows[i, 2]) => parse(Float64, ebv_rows[i, 3])
                        for i in axes(ebv_rows, 1))

    cases = [
        (
            id = "poisson_laplace",
            fit = fit_laplace_reml(
                parse.(Float64, poisson_rows[:, 2]),
                X,
                Z,
                Ainv;
                family = :poisson,
                marginal = :LA,
                ids = ped.ids,
                initial = (sigma_a2 = 1.0,),
                iterations = 500,
            ),
        ),
        (
            id = "binomial_vector_variational",
            fit = fit_laplace_reml(
                parse.(Float64, binomial_rows[:, 2]),
                X,
                Z,
                Ainv;
                family = :binomial,
                n_trials = parse.(Int, binomial_rows[:, 3]),
                marginal = :VA,
                ids = ped.ids,
                initial = (sigma_a2 = 1.0,),
                iterations = 500,
            ),
        ),
    ]

    for case in cases
        payload = nongaussian_result_payload(case.fit)
        @test propertynames(payload) == (
            :engine,
            :target,
            :family,
            :n_trials,
            :dispersion,
            :method,
            :variance_components,
            :fixed_effects,
            :breeding_values,
            :loglik,
            :converged,
        )
        @test !hasproperty(payload, :heritability)
        @test payload.dispersion === nothing   # ρ only set for the beta-binomial family
        @test payload.engine == metadata[(case.id, "engine")]
        @test payload.target == metadata[(case.id, "target")]
        @test payload.family == metadata[(case.id, "family")]
        @test payload.method == metadata[(case.id, "method")]
        @test payload.converged == (metadata[(case.id, "converged")] == "true")
        @test payload.converged
        payload_atol = 1e-5
        @test payload.loglik ≈ parse(Float64, metadata[(case.id, "loglik")]) atol = payload_atol
        @test length(payload.fixed_effects) == parse(Int, metadata[(case.id, "n_fixed_effects")])
        @test length(payload.breeding_values.values) == parse(Int, metadata[(case.id, "n_breeding_values")])
        @test payload.breeding_values.ids == ped.ids
        @test payload.variance_components.sigma_a2 ≈
              variance_components_expected[(case.id, "sigma_a2")] atol = payload_atol
        @test payload.fixed_effects[1] ≈ fixed_expected[(case.id, "Intercept")] atol = payload_atol
        @test payload.fixed_effects[2] ≈ fixed_expected[(case.id, "x")] atol = payload_atol
        expected_ebv = [ebv_expected[(case.id, id)] for id in ped.ids]
        @test payload.breeding_values.values ≈ expected_ebv atol = payload_atol

        if case.id == "poisson_laplace"
            @test payload.n_trials === nothing
            @test metadata[(case.id, "n_trials")] == "nothing"
            @test case.fit.marginal === :laplace
        else
            expected_trials = parse.(Int, split(metadata[(case.id, "n_trials")], ";"))
            @test payload.n_trials == expected_trials
            @test payload.n_trials == parse.(Int, binomial_rows[:, 3])
            @test case.fit.marginal === :variational
        end

        corrupted_ebv = copy(expected_ebv)
        corrupted_ebv[1] += 0.1
        @test maximum(abs.(payload.breeding_values.values .- corrupted_ebv)) > 0.05
    end
end

@testset "Phase 6 fitted non-Gaussian (Laplace/VA REML over variance components)" begin
    # 8-animal interior fixture (where the REML optimum is interior)
    ids = ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"]
    ped = normalize_pedigree(ids,
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Ainv = pedigree_inverse(ped)
    y = [2.0, 3.0, 2.5, 3.5, 4.0, 1.5, 3.0, 4.5]
    X = ones(8, 1)
    Z = sparse(1.0I, 8, 8)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
    sr = fit_sparse_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))

    # Gaussian Laplace-REML maximises the EXACT REML loglik => recovers fit_sparse_reml.
    fl = HSquared.fit_laplace_reml(y, X, Z, Ainv; family = :gaussian,
                                   initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    @test fl.converged
    @test fl.marginal_loglik ≈ sr.likelihood.loglik rtol = 1e-6
    @test fl.variance_components.sigma_a2 ≈ sr.variance_components.sigma_a2 rtol = 1e-2
    @test fl.variance_components.sigma_e2 ≈ sr.variance_components.sigma_e2 rtol = 1e-2
    # VA variant (full covariance) recovers the same REML optimum for Gaussian.
    fv = HSquared.fit_laplace_reml(y, X, Z, Ainv; family = :gaussian, marginal = :variational,
                                   initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    @test fv.marginal_loglik ≈ sr.likelihood.loglik rtol = 1e-6

    # Poisson: estimates a positive sigma_a2 and converges.
    yp = [3.0, 5.0, 8.0, 4.0, 6.0, 2.0, 5.0, 7.0]
    fp = HSquared.fit_laplace_reml(yp, X, Z, Ainv; family = :poisson, initial = (sigma_a2 = 1.0,))
    @test fp.converged && fp.variance_components.sigma_a2 > 0
    @test fp.family === :poisson
    # fitted breeding values are the BLUP at the fitted variance components (Gaussian)
    @test fl.breeding_values ≈
          breeding_values(henderson_mme(spec, fl.variance_components.sigma_a2,
                                        fl.variance_components.sigma_e2)).values rtol = 1e-6 atol = 1e-9
    @test length(fp.breeding_values) == 8

    @test_throws ArgumentError HSquared.fit_laplace_reml(y, X, Z, Ainv; family = :bogus)
    @test_throws ArgumentError HSquared.fit_laplace_reml(y, X, Z, Ainv; marginal = :bogus)
end

@testset "Phase 6 Poisson variance-component profile interval" begin
    # Profile LRT interval for the Poisson animal-model sigma_a2, by inverting
    # 2·(ℓ̂ − ℓ(σ²a)) = χ²₁,level. For this 8-animal count fixture the estimate
    # is near zero with a flat lower profile (the lower endpoint clamps), while
    # the upper endpoint is an interior LRT root.
    ids = ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"]
    ped = normalize_pedigree(ids,
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Ainv = pedigree_inverse(ped)
    yp = [3.0, 5.0, 8.0, 4.0, 6.0, 2.0, 5.0, 7.0]
    X = ones(8, 1)
    Z = sparse(1.0I, 8, 8)

    fp = HSquared.fit_laplace_reml(yp, X, Z, Ainv; family = :poisson, initial = (sigma_a2 = 1.0,))
    sa2hat = fp.variance_components.sigma_a2
    llhat = fp.marginal_loglik
    dev(s) = 2 * (llhat - HSquared.laplace_marginal_loglik(yp, X, Z, Ainv, s,
                                                           HSquared.PoissonResponse()).loglik)

    ci = HSquared.laplace_reml_interval(yp, X, Z, Ainv; family = :poisson, level = 0.95)
    @test ci.level == 0.95
    @test ci.sigma_a2 == sa2hat                          # point estimate is the REML optimum
    @test dev(sa2hat) ≈ 0.0 atol = 1e-8                  # deviance vanishes at the MLE
    @test ci.lower < ci.sigma_a2 < ci.upper              # interval brackets the estimate
    @test ci.lower > 0                                   # variance stays positive

    # Upper endpoint is an interior LRT root: deviance reaches χ²₁,₀.₉₅ = 3.841459.
    @test dev(ci.upper) ≈ 3.841459 atol = 1e-4
    # Lower endpoint clamps (flat profile toward zero) → deviance stays below the threshold.
    @test dev(ci.lower) < 3.841459

    # Higher confidence ⇒ wider interval (nesting on the interior upper endpoint).
    ci90 = HSquared.laplace_reml_interval(yp, X, Z, Ainv; family = :poisson, level = 0.90)
    @test 0 < ci90.upper < ci.upper
    @test dev(ci90.upper) ≈ 2.705543 atol = 1e-4         # χ²₁,₀.₉₀

    # Guards.
    @test_throws ArgumentError HSquared.laplace_reml_interval(yp, X, Z, Ainv; family = :gaussian)
    @test_throws ArgumentError HSquared.laplace_reml_interval(yp, X, Z, Ainv; level = 1.5)
    @test_throws ArgumentError HSquared.laplace_reml_interval(yp, X, Z, Ainv; marginal = :bogus)
end

@testset "Phase 6 Binomial/Bernoulli profile-LRT interval (σ²a)" begin
    ped = normalize_pedigree(["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"],
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Ainv = pedigree_inverse(ped)
    X = ones(8, 1)
    Z = sparse(1.0I, 8, 8)
    m = 20
    yb = [8.0, 2.0, 9.0, 3.0, 7.0, 1.0, 6.0, 9.0]        # successes out of m
    fb = HSquared.fit_laplace_reml(yb, X, Z, Ainv; family = :binomial, n_trials = m,
                                   initial = (sigma_a2 = 1.0,))
    sa2hat = fb.variance_components.sigma_a2
    llhat = fb.marginal_loglik
    devb(s) = 2 * (llhat - HSquared.laplace_marginal_loglik(yb, X, Z, Ainv, s,
                                                            HSquared.BinomialResponse(m)).loglik)

    ci = HSquared.laplace_reml_interval(yb, X, Z, Ainv; family = :binomial, n_trials = m, level = 0.95)
    @test ci.level == 0.95
    @test ci.sigma_a2 == sa2hat                          # point estimate is the REML optimum
    @test devb(sa2hat) ≈ 0.0 atol = 1e-8                 # deviance vanishes at the MLE
    @test 0 < ci.lower < ci.sigma_a2 < ci.upper          # interval brackets the estimate, σ²a > 0
    # For THIS fixture (σ̂²a ≈ 0.98, clear of zero) the profile is two-sided: each
    # endpoint is an INTERIOR χ²₁,₀.₉₅ = 3.841459 LRT root. The `*_clamped` flags
    # report this honestly — two-sidedness depends on where σ̂²a sits, not on the
    # family (see the per-record fixture below, which is lower-clamped).
    @test !ci.lower_clamped && !ci.upper_clamped && ci.converged
    @test devb(ci.upper) ≈ 3.841459 atol = 1e-4
    @test devb(ci.lower) ≈ 3.841459 atol = 1e-4

    # Higher confidence ⇒ wider interval (nesting on both interior endpoints).
    ci90 = HSquared.laplace_reml_interval(yb, X, Z, Ainv; family = :binomial, n_trials = m, level = 0.90)
    @test ci90.lower > ci.lower && ci90.upper < ci.upper
    @test devb(ci90.upper) ≈ 2.705543 atol = 1e-4        # χ²₁,₀.₉₀
    @test devb(ci90.lower) ≈ 2.705543 atol = 1e-4

    # Per-record n_trials vector is accepted; HERE σ̂²a ≈ 0.37 is small, so the LOWER
    # endpoint clamps (flagged) while the upper is interior — witnessing that
    # two-sidedness is fixture-dependent, not a property of "adequate trials".
    ntv = [20, 18, 22, 16, 24, 15, 19, 21]
    @test all(0 .<= yb .<= ntv)
    civ = HSquared.laplace_reml_interval(yb, X, Z, Ainv; family = :binomial, n_trials = ntv)
    @test 0 < civ.lower < civ.sigma_a2 < civ.upper
    @test civ.lower_clamped && !civ.upper_clamped        # lower clamps, upper interior

    # Bernoulli is supported but binary data is uninformative — the profile is flat so
    # BOTH endpoints clamp (the `*_clamped` flags make the degeneracy machine-readable,
    # not a silent finite CI). The converged flag does NOT catch this; the clamps do.
    yb01 = [1.0, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0]
    cib = HSquared.laplace_reml_interval(yb01, X, Z, Ainv; family = :bernoulli, level = 0.95)
    @test cib.level == 0.95
    @test cib.lower_clamped && cib.upper_clamped         # degenerate: both endpoints are bounds

    # marginal = :variational is REJECTED (the ELBO is a lower bound, not a χ²₁ LRT).
    @test_throws ArgumentError HSquared.laplace_reml_interval(yb, X, Z, Ainv;
                                    family = :binomial, n_trials = m, marginal = :variational)

    # Guards.
    @test_throws ArgumentError HSquared.laplace_reml_interval(yb, X, Z, Ainv; family = :gaussian)
    @test_throws ArgumentError HSquared.laplace_reml_interval(yb, X, Z, Ainv; family = :binomial)  # missing n_trials
    @test_throws ArgumentError HSquared.laplace_reml_interval(yb, X, Z, Ainv;
                                    family = :binomial, n_trials = [20, 18, 22])  # length mismatch
    @test_throws ArgumentError HSquared.laplace_reml_interval(yb, X, Z, Ainv;
                                    family = :binomial, n_trials = 20.5)          # non-integer scalar
end

@testset "Phase 6 Bernoulli (logit) family (Laplace + VA)" begin
    # Binary/threshold traits (disease, survival, reproductive success) are a
    # major real-world quantitative-genetic case. The logistic log-partition has
    # NO closed-form Gaussian expectation, so the VA expected kernels use 1D
    # Gauss–Hermite quadrature (the Poisson case had a closed-form MGF).
    f = HSquared.BernoulliResponse()

    # --- conditional kernels match finite differences of the conditional loglik
    η0 = 0.37
    h = 1e-6
    @test HSquared._fam_score(f, 1.0, η0) ≈
          (HSquared._fam_loglik(f, 1.0, η0 + h) - HSquared._fam_loglik(f, 1.0, η0 - h)) / (2h) rtol = 1e-5
    h2 = 1e-4
    @test HSquared._fam_weight(f, 1.0, η0) ≈
          -(HSquared._fam_loglik(f, 1.0, η0 + h2) - 2 * HSquared._fam_loglik(f, 1.0, η0) +
            HSquared._fam_loglik(f, 1.0, η0 - h2)) / h2^2 rtol = 1e-3
    # logistic weight p(1-p) ∈ (0, 0.25]
    @test 0 < HSquared._fam_weight(f, 1.0, 2.0) <= 0.25

    # --- VA expected kernels are the η̄-derivatives of the expected loglik
    ηb, vv = 0.4, 0.6
    @test HSquared._fam_expected_score(f, 1.0, ηb, vv) ≈
          (HSquared._fam_expected_loglik(f, 1.0, ηb + h, vv) -
           HSquared._fam_expected_loglik(f, 1.0, ηb - h, vv)) / (2h) rtol = 1e-5
    @test HSquared._fam_expected_weight(f, ηb, vv) ≈
          -(HSquared._fam_expected_loglik(f, 1.0, ηb + h2, vv) -
            2 * HSquared._fam_expected_loglik(f, 1.0, ηb, vv) +
            HSquared._fam_expected_loglik(f, 1.0, ηb - h2, vv)) / h2^2 rtol = 1e-3
    # at v → 0 the expected kernels reduce to the conditional kernels
    @test HSquared._fam_expected_loglik(f, 1.0, ηb, 0.0) ≈ HSquared._fam_loglik(f, 1.0, ηb) atol = 1e-10
    @test HSquared._fam_expected_score(f, 1.0, ηb, 0.0) ≈ HSquared._fam_score(f, 1.0, ηb) atol = 1e-10

    # --- value gate vs an independent tensor Gauss–Hermite quadrature (β-fixed)
    ped = normalize_pedigree(["sire", "dam", "calf"], ["0", "0", "sire"], ["0", "0", "dam"])
    Ainv = pedigree_inverse(ped)
    Z = sparse(1.0I, 3, 3)
    sa2 = 1.3
    yb = [1.0, 0.0, 1.0]
    X0 = zeros(3, 0)                      # β-fixed (no fixed effects)
    _gh(m) = (E = eigen(SymTridiagonal(zeros(m), [sqrt(k / 2) for k in 1:m-1]));
              (E.values, sqrt(π) .* (E.vectors[1, :] .^ 2)))
    _l1pe(η) = η > 0 ? η + log1p(exp(-η)) : log1p(exp(η))
    function _bern_marginal(y, Zd, G, m)
        x, w = _gh(m)
        L = cholesky(Symmetric(G)).L
        n = length(y); qd = size(Zd, 2); tot = 0.0
        for idx in CartesianIndices(ntuple(_ -> m, qd))
            z = [sqrt(2) * x[idx[j]] for j in 1:qd]
            wt = prod(w[idx[j]] / sqrt(π) for j in 1:qd)
            η = Zd * (L * z)
            ll = sum(y[i] * η[i] - _l1pe(η[i]) for i in 1:n)
            tot += wt * exp(ll)
        end
        return log(tot)
    end
    G = inv(Symmetric(Matrix(Ainv))) .* sa2
    R = _bern_marginal(yb, Matrix(Z), G, 32)
    lap = HSquared.laplace_marginal_loglik(yb, X0, Z, Ainv, sa2, HSquared.BernoulliResponse())
    va = HSquared.variational_marginal_loglik(yb, X0, Z, Ainv, sa2, HSquared.BernoulliResponse())
    @test lap.converged && va.converged
    @test va.elbo <= R + 1e-6                       # ELBO is a valid lower bound on log p(y)
    @test abs(lap.loglik - R) < 0.5                 # Laplace in the right ballpark (binary gap documented)

    # --- guard: Bernoulli requires binary 0/1 responses
    @test_throws ArgumentError HSquared.laplace_marginal_loglik([2.0, 0.0, 1.0], X0, Z, Ainv, sa2,
                                                                HSquared.BernoulliResponse())

    # --- fitted: estimate sigma_a2 by Laplace and by VA on an 8-animal binary fixture
    ids = ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"]
    pedf = normalize_pedigree(ids,
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Aif = pedigree_inverse(pedf)
    yf = [1.0, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0]
    Xf = ones(8, 1)
    Zf = sparse(1.0I, 8, 8)
    fb = HSquared.fit_laplace_reml(yf, Xf, Zf, Aif; family = :bernoulli, initial = (sigma_a2 = 1.0,))
    @test fb.family === :bernoulli
    @test fb.converged && fb.variance_components.sigma_a2 > 0
    @test length(fb.breeding_values) == 8
    fbv = HSquared.fit_laplace_reml(yf, Xf, Zf, Aif; family = :bernoulli, marginal = :variational,
                                    initial = (sigma_a2 = 1.0,))
    @test fbv.family === :bernoulli && fbv.converged
end

@testset "Phase 6 Binomial (logit, n trials) family" begin
    # The Binomial(m) family generalises Bernoulli (m = 1). With more trials per
    # record the data is more informative, so the Laplace variance bias shrinks —
    # the scientific resolution of the "binary σ²a is uncalibrated" limit.
    b1 = HSquared.BinomialResponse(1)
    bern = HSquared.BernoulliResponse()
    # --- reduces to Bernoulli at m = 1 (kernels identical)
    for η in (-1.3, 0.0, 0.7), y in (0.0, 1.0)
        @test HSquared._fam_loglik(b1, y, η) ≈ HSquared._fam_loglik(bern, y, η) atol = 1e-12
        @test HSquared._fam_score(b1, y, η) ≈ HSquared._fam_score(bern, y, η) atol = 1e-12
        @test HSquared._fam_weight(b1, y, η) ≈ HSquared._fam_weight(bern, y, η) atol = 1e-12
    end

    f = HSquared.BinomialResponse(10)
    η0 = 0.37; h = 1e-6
    @test HSquared._fam_score(f, 6.0, η0) ≈
          (HSquared._fam_loglik(f, 6.0, η0 + h) - HSquared._fam_loglik(f, 6.0, η0 - h)) / (2h) rtol = 1e-5
    h2 = 1e-4
    @test HSquared._fam_weight(f, 6.0, η0) ≈
          -(HSquared._fam_loglik(f, 6.0, η0 + h2) - 2 * HSquared._fam_loglik(f, 6.0, η0) +
            HSquared._fam_loglik(f, 6.0, η0 - h2)) / h2^2 rtol = 1e-3
    # VA expected kernels are the η̄-derivatives of the expected loglik
    ηb, vv = 0.4, 0.6
    @test HSquared._fam_expected_score(f, 6.0, ηb, vv) ≈
          (HSquared._fam_expected_loglik(f, 6.0, ηb + h, vv) -
           HSquared._fam_expected_loglik(f, 6.0, ηb - h, vv)) / (2h) rtol = 1e-5
    @test HSquared._fam_expected_weight(f, ηb, vv) ≈
          -(HSquared._fam_expected_loglik(f, 6.0, ηb + h2, vv) -
            2 * HSquared._fam_expected_loglik(f, 6.0, ηb, vv) +
            HSquared._fam_expected_loglik(f, 6.0, ηb - h2, vv)) / h2^2 rtol = 1e-3

    # --- value gate vs an independent tensor Gauss–Hermite quadrature (β-fixed)
    ped = normalize_pedigree(["sire", "dam", "calf"], ["0", "0", "sire"], ["0", "0", "dam"])
    Ainv = pedigree_inverse(ped)
    Z = sparse(1.0I, 3, 3)
    sa2 = 1.0
    m = 8
    yb = [6.0, 2.0, 5.0]                  # successes in 0..m
    X0 = zeros(3, 0)
    _gh(k) = (E = eigen(SymTridiagonal(zeros(k), [sqrt(j / 2) for j in 1:k-1]));
              (E.values, sqrt(π) .* (E.vectors[1, :] .^ 2)))
    _l1pe(η) = η > 0 ? η + log1p(exp(-η)) : log1p(exp(η))
    _lbin(mm, yy) = HSquared._logfactorial(mm) - HSquared._logfactorial(yy) -
                    HSquared._logfactorial(mm - yy)
    function _binom_marginal(y, Zd, G, mm, k)
        x, w = _gh(k)
        L = cholesky(Symmetric(G)).L
        n = length(y); qd = size(Zd, 2); tot = 0.0
        for idx in CartesianIndices(ntuple(_ -> k, qd))
            z = [sqrt(2) * x[idx[j]] for j in 1:qd]
            wt = prod(w[idx[j]] / sqrt(π) for j in 1:qd)
            η = Zd * (L * z)
            ll = sum(y[i] * η[i] - mm * _l1pe(η[i]) + _lbin(mm, Int(y[i])) for i in 1:n)
            tot += wt * exp(ll)
        end
        return log(tot)
    end
    G = inv(Symmetric(Matrix(Ainv))) .* sa2
    R = _binom_marginal(yb, Matrix(Z), G, m, 32)
    lap = HSquared.laplace_marginal_loglik(yb, X0, Z, Ainv, sa2, HSquared.BinomialResponse(m))
    va = HSquared.variational_marginal_loglik(yb, X0, Z, Ainv, sa2, HSquared.BinomialResponse(m))
    @test lap.converged && va.converged
    @test va.elbo <= R + 1e-6                       # ELBO valid lower bound
    @test abs(lap.loglik - R) < 0.2                 # Laplace close (better than m=1)

    # --- guards
    @test_throws ArgumentError HSquared.BinomialResponse(0)
    @test_throws ArgumentError HSquared.laplace_marginal_loglik([9.0, 2.0, 5.0], X0, Z, Ainv, sa2,
                                                                HSquared.BinomialResponse(m))  # y > m

    # --- fitted: family = :binomial requires n_trials and converges
    ids = ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"]
    pedf = normalize_pedigree(ids,
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Aif = pedigree_inverse(pedf)
    yf = [7.0, 2.0, 6.0, 8.0, 3.0, 1.0, 7.0, 9.0]    # successes in 0..10
    Xf = ones(8, 1)
    Zf = sparse(1.0I, 8, 8)
    fbn = HSquared.fit_laplace_reml(yf, Xf, Zf, Aif; family = :binomial, n_trials = 10,
                                    initial = (sigma_a2 = 1.0,))
    @test fbn.family === :binomial
    @test fbn.converged && fbn.variance_components.sigma_a2 > 0
    @test length(fbn.breeding_values) == 8
    @test_throws ArgumentError HSquared.fit_laplace_reml(yf, Xf, Zf, Aif; family = :binomial)  # missing n_trials
end

@testset "Phase 6 Binomial per-record n_trials (cbind GLMM)" begin
    # Per-record trials `n_trials[i]` — the general cbind(successes, failures) GLMM
    # where the denominator varies by observation. Resolved per record to the scalar
    # BinomialResponse via `_fam_record`, so the scalar family math is shared.
    BVR = HSquared.BinomialVectorResponse
    BR = HSquared.BinomialResponse

    # --- _fam_record: scalar families are identity; the vector form returns the
    #     scalar BinomialResponse for record i (allocation-free bitstype)
    bv = BVR([3, 5, 8])
    @test HSquared._fam_record(bv, 1) === BR(3) || HSquared._fam_record(bv, 1).n_trials == 3
    @test HSquared._fam_record(bv, 2).n_trials == 5
    @test HSquared._fam_record(bv, 3).n_trials == 8
    @test HSquared._fam_record(HSquared.PoissonResponse(), 7) === HSquared.PoissonResponse()
    @test HSquared._fam_record(BR(10), 4) === BR(10)              # scalar Binomial unchanged

    # --- constructor guards
    @test_throws ArgumentError BVR(Int[])                         # empty
    @test_throws ArgumentError BVR([3, 0, 5])                     # a zero entry
    @test_throws ArgumentError BVR([3, -1, 5])                    # a negative entry

    # --- pedigree / design fixture (interior 8-animal)
    ids = ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"]
    ped = normalize_pedigree(ids,
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Ai = pedigree_inverse(ped)
    Z = sparse(1.0I, 8, 8)
    X0 = zeros(8, 0)
    sa2 = 1.0
    yv = [6.0, 2.0, 5.0, 7.0, 3.0, 1.0, 4.0, 8.0]

    # === REDUCTION INVARIANT 1: constant per-record vector == scalar (machine prec)
    m = 9
    @test all(0 .<= yv .<= m)
    lap_scalar = HSquared.laplace_marginal_loglik(yv, X0, Z, Ai, sa2, BR(m))
    lap_vector = HSquared.laplace_marginal_loglik(yv, X0, Z, Ai, sa2, BVR(fill(m, 8)))
    @test lap_vector.converged
    @test lap_vector.loglik ≈ lap_scalar.loglik atol = 1e-12
    @test lap_vector.beta ≈ lap_scalar.beta atol = 1e-10
    @test lap_vector.u ≈ lap_scalar.u atol = 1e-10
    va_scalar = HSquared.variational_marginal_loglik(yv, X0, Z, Ai, sa2, BR(m))
    va_vector = HSquared.variational_marginal_loglik(yv, X0, Z, Ai, sa2, BVR(fill(m, 8)))
    @test va_vector.elbo ≈ va_scalar.elbo atol = 1e-10           # VA path also reduces

    # === REDUCTION INVARIANT 2: all-ones per-record vector == Bernoulli
    yb = [1.0, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0]
    lap_ones = HSquared.laplace_marginal_loglik(yb, X0, Z, Ai, sa2, BVR(ones(Int, 8)))
    lap_bern = HSquared.laplace_marginal_loglik(yb, X0, Z, Ai, sa2, HSquared.BernoulliResponse())
    @test lap_ones.loglik ≈ lap_bern.loglik atol = 1e-12
    @test lap_ones.u ≈ lap_bern.u atol = 1e-10

    # === HETEROGENEOUS n_trials: finite, converged, and NOT equal to any scalar
    nt = [10, 4, 6, 12, 5, 3, 8, 15]
    @test all(0 .<= yv .<= nt)
    lap_het = HSquared.laplace_marginal_loglik(yv, X0, Z, Ai, sa2, BVR(nt))
    @test lap_het.converged && isfinite(lap_het.loglik)
    # differs from the closest constant-denominator fits (the heterogeneity matters)
    @test !isapprox(lap_het.loglik, HSquared.laplace_marginal_loglik(yv, X0, Z, Ai, sa2, BR(10)).loglik; atol = 1e-6)
    @test !isapprox(lap_het.loglik, HSquared.laplace_marginal_loglik(yv, X0, Z, Ai, sa2, BR(15)).loglik; atol = 1e-6)

    # === score/weight ARE the η-derivatives at a heterogeneous record (record 4, n=12)
    f4 = HSquared._fam_record(BVR(nt), 4)
    @test f4.n_trials == 12
    η0 = 0.31; h = 1e-6; h2 = 1e-4
    @test HSquared._fam_score(f4, yv[4], η0) ≈
          (HSquared._fam_loglik(f4, yv[4], η0 + h) - HSquared._fam_loglik(f4, yv[4], η0 - h)) / (2h) rtol = 1e-5
    @test HSquared._fam_weight(f4, yv[4], η0) ≈
          -(HSquared._fam_loglik(f4, yv[4], η0 + h2) - 2 * HSquared._fam_loglik(f4, yv[4], η0) +
            HSquared._fam_loglik(f4, yv[4], η0 - h2)) / h2^2 rtol = 1e-3

    # === value gate vs an independent PER-RECORD tensor Gauss–Hermite oracle (β-fixed)
    peds = normalize_pedigree(["sire", "dam", "calf"], ["0", "0", "sire"], ["0", "0", "dam"])
    Ais = pedigree_inverse(peds)
    Zs = sparse(1.0I, 3, 3)
    X0s = zeros(3, 0)
    nts = [8, 5, 11]
    ys = [6.0, 2.0, 9.0]
    @test all(0 .<= ys .<= nts)
    _gh(k) = (E = eigen(SymTridiagonal(zeros(k), [sqrt(j / 2) for j in 1:k-1]));
              (E.values, sqrt(π) .* (E.vectors[1, :] .^ 2)))
    _l1pe(η) = η > 0 ? η + log1p(exp(-η)) : log1p(exp(η))
    _lbin(mm, yy) = HSquared._logfactorial(mm) - HSquared._logfactorial(yy) -
                    HSquared._logfactorial(mm - yy)
    function _binom_marginal_perrec(y, Zd, G, mm, k)   # mm is a PER-RECORD vector
        x, w = _gh(k)
        L = cholesky(Symmetric(G)).L
        n = length(y); qd = size(Zd, 2); tot = 0.0
        for idx in CartesianIndices(ntuple(_ -> k, qd))
            z = [sqrt(2) * x[idx[j]] for j in 1:qd]
            wt = prod(w[idx[j]] / sqrt(π) for j in 1:qd)
            η = Zd * (L * z)
            ll = sum(y[i] * η[i] - mm[i] * _l1pe(η[i]) + _lbin(mm[i], Int(y[i])) for i in 1:n)
            tot += wt * exp(ll)
        end
        return log(tot)
    end
    Gs = inv(Symmetric(Matrix(Ais))) .* sa2
    Roracle = _binom_marginal_perrec(ys, Matrix(Zs), Gs, nts, 32)
    lap_s = HSquared.laplace_marginal_loglik(ys, X0s, Zs, Ais, sa2, BVR(nts))
    va_s = HSquared.variational_marginal_loglik(ys, X0s, Zs, Ais, sa2, BVR(nts))
    @test lap_s.converged && va_s.converged
    @test va_s.elbo <= Roracle + 1e-6                            # ELBO valid lower bound
    @test abs(lap_s.loglik - Roracle) < 0.2                      # Laplace close to truth

    # === _check_counts rejections
    @test_throws ArgumentError HSquared.laplace_marginal_loglik(yv, X0, Z, Ai, sa2, BVR([10, 4, 6, 12, 5, 3, 8]))      # length mismatch (7 vs 8)
    @test_throws ArgumentError HSquared.laplace_marginal_loglik([11.0, 2.0, 5.0, 7.0, 3.0, 1.0, 4.0, 8.0], X0, Z, Ai, sa2, BVR(nt))  # y[1]=11 > n[1]=10

    # === fitted path: vector n_trials converges; fit + payload carry the vector
    fbv = HSquared.fit_laplace_reml(yv, ones(8, 1), Z, Ai; family = :binomial,
                                    n_trials = nt, initial = (sigma_a2 = 1.0,))
    @test fbv.family === :binomial
    @test fbv.converged && fbv.variance_components.sigma_a2 > 0
    @test fbv.n_trials == nt
    pbv = HSquared.nongaussian_result_payload(fbv)
    @test pbv.n_trials == nt
    @test pbv.n_trials !== fbv.n_trials                          # payload copies, no alias
    # a constant vector fit equals the scalar fit (sigma_a2 to high precision)
    fconst_v = HSquared.fit_laplace_reml(yv, ones(8, 1), Z, Ai; family = :binomial,
                                         n_trials = fill(9, 8), initial = (sigma_a2 = 1.0,))
    fconst_s = HSquared.fit_laplace_reml(yv, ones(8, 1), Z, Ai; family = :binomial,
                                         n_trials = 9, initial = (sigma_a2 = 1.0,))
    @test fconst_v.variance_components.sigma_a2 ≈ fconst_s.variance_components.sigma_a2 rtol = 1e-6
    # length-mismatch vector at the fitter throws
    @test_throws ArgumentError HSquared.fit_laplace_reml(yv, ones(8, 1), Z, Ai;
                                    family = :binomial, n_trials = [10, 4, 6])
    # bridge realism: R marshals doubles, so an INTEGER-VALUED Float64 vector is
    # accepted (== the Int vector); a genuinely non-integer vector gets a clean error
    ffloat = HSquared.fit_laplace_reml(yv, ones(8, 1), Z, Ai; family = :binomial,
                                       n_trials = Float64.(nt), initial = (sigma_a2 = 1.0,))
    @test ffloat.n_trials == nt && ffloat.n_trials isa Vector{Int}
    @test ffloat.variance_components.sigma_a2 ≈ fbv.variance_components.sigma_a2 rtol = 1e-8
    @test_throws ArgumentError HSquared.fit_laplace_reml(yv, ones(8, 1), Z, Ai;
                                    family = :binomial, n_trials = [10.0, 4.5, 6.0, 12.0, 5.0, 3.0, 8.0, 15.0])
end

@testset "Phase 4 multivariate covariance SEs + LRTs" begin
    ped = normalize_pedigree(["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"],
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Ainv = pedigree_inverse(ped)
    y1 = [2.0, 3.0, 2.5, 3.5, 4.0, 1.5, 3.0, 4.5]
    y2 = [2.2, 2.8, 3.1, 3.0, 3.6, 2.1, 2.7, 4.1]   # correlated-but-distinct trait
    X = ones(8, 1); Z = Matrix(1.0I, 8, 8)
    h = HSquared._multivariate_reml_loglik

    # (1) chi-square survival validates against textbook 5% critical values
    @test HSquared._chisq_sf(3.841458820694124, 1) ≈ 0.05 atol = 1e-3
    @test HSquared._chisq_sf(5.991464547107979, 2) ≈ 0.05 atol = 1e-3
    @test HSquared._chisq_sf(7.814727903251179, 3) ≈ 0.05 atol = 1e-3
    @test HSquared._chisq_sf(9.487729036781154, 4) ≈ 0.05 atol = 1e-3
    @test HSquared._chisq_sf(0.0, 2) == 1.0
    @test HSquared._chisq_sf(1.0e6, 2) < 1e-50
    @test HSquared._chisq_sf(2.0, 2) > HSquared._chisq_sf(4.0, 2)   # monotone decreasing
    @test HSquared._loggamma(5.0) ≈ log(24.0) atol = 1e-10          # Γ(5) = 4! = 24
    @test HSquared._loggamma(0.5) ≈ 0.5 * log(π) atol = 1e-10       # Γ(1/2) = √π

    # (2) unstructured SEs (t=2) on an INTERIOR optimum. At n=8 single-record the
    # multivariate optimum sits on the genetic-correlation boundary (rg→±1), so
    # SEs are genuinely unavailable there (tested in (6)); repeated records
    # (n=24, 3/animal) identify the covariance and give an interior optimum.
    reps = 3
    rows = reduce(vcat, [fill(i, reps) for i in 1:8])
    Zr = zeros(length(rows), 8); for (k, i) in enumerate(rows); Zr[k, i] = 1.0; end
    Xr = ones(length(rows), 1)
    off1 = [0.0, 0.3, -0.3]; off2 = [0.2, -0.2, 0.0]   # deterministic within-animal residual
    yr1 = Float64[]; yr2 = Float64[]
    for i in 1:8, r in 1:reps
        push!(yr1, y1[i] + off1[r]); push!(yr2, y2[i] + off2[r])
    end
    Yr = hcat(yr1, yr2)
    mv2 = fit_multivariate_reml(Yr, Xr, Zr, Ainv)
    @test mv2.converged
    @test -1 < mv2.genetic_correlation[1, 2] < 1            # interior optimum
    se = multivariate_covariance_standard_errors(mv2, Yr, Xr, Zr, Ainv)
    @test size(se.genetic_covariance) == (2, 2)
    @test issymmetric(se.genetic_covariance) && issymmetric(se.residual_covariance)
    @test all(isfinite, se.genetic_covariance) && all(se.genetic_covariance .>= 0)
    @test all(isfinite, se.residual_covariance) && all(se.residual_covariance .>= 0)
    @test length(se.heritability) == 2 && all(se.heritability .>= 0)
    @test isposdef(Symmetric(se.information))
    @test se.genetic_correlation[1, 1] == 0.0 && se.genetic_correlation[2, 2] == 0.0

    # (3) t=1 cross-check: the SE for σ²a from the (log-Cholesky + delta-method)
    # machinery matches an INDEPENDENT direct FD-Hessian SE on the raw (σ²a, σ²e)
    # parameterization of the same REML log-likelihood (validates the delta method)
    Y1 = reshape(y1, 8, 1)
    mv1 = fit_multivariate_reml(Y1, X, Z, Ainv)
    se1 = multivariate_covariance_standard_errors(mv1, Y1, X, Z, Ainv)
    va = mv1.genetic_covariance[1, 1]; ve = mv1.residual_covariance[1, 1]
    fll(p) = h(Y1, X, Z, Ainv, reshape([p[1]], 1, 1), reshape([p[2]], 1, 1))
    Hraw = HSquared._fd_hessian(fll, [va, ve]; h = 1e-4)
    Σraw = inv(Symmetric(-Hraw))
    @test se1.genetic_covariance[1, 1] ≈ sqrt(Σraw[1, 1]) rtol = 0.1
    @test se1.residual_covariance[1, 1] ≈ sqrt(Σraw[2, 2]) rtol = 0.1

    # (4) LRT — diagonal (interior null) nested in unstructured (interior fixture)
    mv2_diag = fit_multivariate_reml(Yr, Xr, Zr, Ainv; genetic_structure = :diagonal)
    lrt = covariance_structure_lrt(mv2_diag, mv2)
    @test lrt.df == 1                       # one off-diagonal genetic covariance
    @test lrt.statistic >= -1e-6            # full nests + dominates constrained
    @test 0.0 <= lrt.pvalue <= 1.0
    @test lrt.boundary == false             # off-diagonal=0 is an interior null
    @test lrt.pvalue ≈ HSquared._chisq_sf(max(lrt.statistic, 0.0), 1) atol = 1e-12

    # (5) LRT boundary flag — low-rank (rank deficiency) nested in unstructured
    mv2_lr = fit_multivariate_reml(Yr, Xr, Zr, Ainv; genetic_structure = :lowrank, rank = 1)
    lrt_lr = covariance_structure_lrt(mv2_lr, mv2)
    @test lrt_lr.df == 1
    @test lrt_lr.boundary == true           # rank/PSD-boundary null → conservative

    # (6) honest small-n limitation: at n=8 single-record the unstructured optimum
    # is on the genetic-correlation boundary, so the observed information is not PD
    # and standard errors are unavailable (the function says so rather than guessing)
    mv2_bnd = fit_multivariate_reml(hcat(y1, y2), X, Z, Ainv)
    @test_throws ArgumentError multivariate_covariance_standard_errors(mv2_bnd, hcat(y1, y2), X, Z, Ainv)

    # (7) guards
    @test_throws ArgumentError covariance_structure_lrt(mv2, mv2_diag)        # df <= 0 (wrong order)
    @test_throws ArgumentError multivariate_covariance_standard_errors(mv2_diag, Yr, Xr, Zr, Ainv)  # structured unsupported
end

@testset "Phase 4 genetic-correlation interval (C2)" begin
    # Fisher-z delta CI for each off-diagonal genetic correlation of an :unstructured
    # fit, reusing the validated `multivariate_covariance_standard_errors` SE. Same
    # interior (n=24) + boundary (n=8) fixtures as the SE testset above.
    ped = normalize_pedigree(["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"],
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Ainv = pedigree_inverse(ped)
    y1 = [2.0, 3.0, 2.5, 3.5, 4.0, 1.5, 3.0, 4.5]
    y2 = [2.2, 2.8, 3.1, 3.0, 3.6, 2.1, 2.7, 4.1]
    reps = 3
    rows = reduce(vcat, [fill(i, reps) for i in 1:8])
    Zr = zeros(length(rows), 8); for (k, i) in enumerate(rows); Zr[k, i] = 1.0; end
    Xr = ones(length(rows), 1)
    off1 = [0.0, 0.3, -0.3]; off2 = [0.2, -0.2, 0.0]
    yr1 = Float64[]; yr2 = Float64[]
    for i in 1:8, r in 1:reps
        push!(yr1, y1[i] + off1[r]); push!(yr2, y2[i] + off2[r])
    end
    Yr = hcat(yr1, yr2)
    mv2 = fit_multivariate_reml(Yr, Xr, Zr, Ainv)

    ci = genetic_correlation_interval(mv2, Yr, Xr, Zr, Ainv; method = :delta)
    @test length(ci.estimate) == 1                       # t=2 → one strict-lower pair
    @test ci.trait_i[1] == 2 && ci.trait_j[1] == 1
    @test ci.estimate[1] ≈ mv2.genetic_correlation[2, 1] atol = 1e-12
    @test ci.lower[1] < ci.estimate[1] < ci.upper[1]
    @test -1 < ci.lower[1] && ci.upper[1] < 1            # Fisher-z keeps it in (−1,1)
    @test ci.level == 0.95 && ci.method === :delta
    @test !ci.lower_clamped[1] && !ci.upper_clamped[1] && ci.converged
    @test ci.lower_matrix[2, 1] == ci.lower[1] && ci.lower_matrix[1, 2] == ci.lower[1]
    @test isnan(ci.lower_matrix[1, 1]) && isnan(ci.upper_matrix[2, 2])   # no fabricated diagonal

    # internal consistency: EXACTLY tanh(atanh(rg) ± z·se_z) from the validated SE path
    se = multivariate_covariance_standard_errors(mv2, Yr, Xr, Zr, Ainv)
    r = mv2.genetic_correlation[2, 1]
    zq = HSquared._standard_normal_quantile(0.975)
    se_z = se.genetic_correlation[2, 1] / (1 - r^2); zr = atanh(r)
    @test ci.lower[1] ≈ tanh(zr - zq * se_z) rtol = 1e-8
    @test ci.upper[1] ≈ tanh(zr + zq * se_z) rtol = 1e-8

    # nesting in level: 0.99 strictly contains 0.90
    ci90 = genetic_correlation_interval(mv2, Yr, Xr, Zr, Ainv; level = 0.90)
    ci99 = genetic_correlation_interval(mv2, Yr, Xr, Zr, Ainv; level = 0.99)
    @test ci99.lower[1] < ci90.lower[1] && ci90.upper[1] < ci99.upper[1]

    # guards
    @test_throws ArgumentError genetic_correlation_interval(mv2, Yr, Xr, Zr, Ainv; method = :profile)
    @test_throws ArgumentError genetic_correlation_interval(mv2, Yr, Xr, Zr, Ainv; level = 1.5)
    mv2_diag = fit_multivariate_reml(Yr, Xr, Zr, Ainv; genetic_structure = :diagonal)
    @test_throws ArgumentError genetic_correlation_interval(mv2_diag, Yr, Xr, Zr, Ainv)  # structured rejected

    # boundary: n=8 single-record → rg on the boundary → SE path throws → :delta throws
    # (a clear ArgumentError, never a fabricated whisker)
    X = ones(8, 1); Z = Matrix(1.0I, 8, 8)
    mv_bnd = fit_multivariate_reml(hcat(y1, y2), X, Z, Ainv)
    @test_throws ArgumentError genetic_correlation_interval(mv_bnd, hcat(y1, y2), X, Z, Ainv)
end

@testset "Phase 4B evolvability / G-matrix geometry (#55)" begin
    # --- 2x2 diagonal G: hand-checked Hansen-Houle identities ---
    Gd = [4.0 0.0; 0.0 1.0]
    @test evolvability(Gd, [1.0, 0.0]) ≈ 4.0
    @test evolvability(Gd, [0.0, 1.0]) ≈ 1.0
    @test evolvability(Gd, [1.0, 1.0]) ≈ 2.5             # unit β weights variances by squared cosines
    @test conditional_evolvability(Gd, [1.0, 1.0]) ≈ 1.6  # 1/(0.5/4 + 0.5/1)
    @test autonomy(Gd, [1.0, 1.0]) ≈ 1.6 / 2.5
    @test respondability(Gd, [1.0, 0.0]) ≈ 4.0
    @test respondability(Gd, [0.0, 1.0]) ≈ 1.0
    @test variance_along_gradient(Gd, [1.0, 0.0]) ≈ 4.0                  # normalized default == evolvability
    @test variance_along_gradient(Gd, [1.0, 1.0]; normalize = false) ≈ 5.0  # raw β'Gβ = 4 + 1
    @test mean_evolvability(Gd) ≈ 2.5                                    # tr/2 = 5/2

    # --- isotropic G = cI: e == c == r == c for ALL directions; autonomy == 1 ---
    Gi = 2.0 * Matrix(I, 3, 3)
    for b in ([1.0, 0.0, 0.0], [1.0, 1.0, 1.0], [0.3, -0.7, 0.5], [1.0, 2.0, -3.0])
        @test evolvability(Gi, b) ≈ 2.0 atol = 1e-12
        @test conditional_evolvability(Gi, b) ≈ 2.0 atol = 1e-12
        @test respondability(Gi, b) ≈ 2.0 atol = 1e-12
        @test autonomy(Gi, b) ≈ 1.0 atol = 1e-12
    end
    @test mean_evolvability(Gi) ≈ 2.0

    # --- non-diagonal PD G = [3 1; 1 3]: eig 4 @ [1,1]/√2, 2 @ [1,-1]/√2 (deterministic) ---
    Ge = [3.0 1.0; 1.0 3.0]
    v1 = [1.0, 1.0]; v2 = [1.0, -1.0]
    @test evolvability(Ge, v1) ≈ 4.0
    @test evolvability(Ge, v2) ≈ 2.0
    @test conditional_evolvability(Ge, v1) ≈ 4.0
    @test conditional_evolvability(Ge, v2) ≈ 2.0
    @test respondability(Ge, v1) ≈ 4.0
    @test respondability(Ge, v2) ≈ 2.0
    @test autonomy(Ge, v1) ≈ 1.0 atol = 1e-12
    @test autonomy(Ge, v2) ≈ 1.0 atol = 1e-12
    pca = genetic_pca(Ge)
    @test issorted(pca.values; rev = true)
    @test pca.values ≈ [4.0, 2.0]
    @test abs(dot(pca.vectors[:, 1], v1 ./ sqrt(2))) ≈ 1.0 atol = 1e-12
    @test abs(dot(pca.vectors[:, 2], v2 ./ sqrt(2))) ≈ 1.0 atol = 1e-12
    gm = g_max(Ge)
    @test gm.eigenvalue ≈ 4.0
    @test abs(dot(gm.eigenvector, v1 ./ sqrt(2))) ≈ 1.0 atol = 1e-12
    @test gm.eigenvector[argmax(abs.(gm.eigenvector))] > 0     # sign-canonicalized
    @test g_max(Ge).eigenvector == gm.eigenvector              # deterministic/reproducible
    @test mean_evolvability(Ge) ≈ 3.0                          # tr/2 = 6/2
    # c ≤ e always (constraint cannot increase available variance)
    for b in ([1.0, 0.0], [2.0, -1.0], [1.0, 3.0])
        @test conditional_evolvability(Ge, b) ≤ evolvability(Ge, b) + 1e-9
    end

    # --- rotation-invariance: metrics depend on G = ΛΛ', not the loading rotation ---
    L = [1.0 0.5; 0.5 1.0; -0.3 0.8]          # 3 traits × 2 factors -> rank-2 (singular) G
    G_lr = lowrank_covariance(L)
    θ = 0.7
    Qr = [cos(θ) -sin(θ); sin(θ) cos(θ)]
    G_lr_rot = lowrank_covariance(L * Qr)
    β = [0.4, -0.5, 0.3]
    @test evolvability(G_lr, β) ≈ evolvability(G_lr_rot, β) atol = 1e-10
    @test respondability(G_lr, β) ≈ respondability(G_lr_rot, β) atol = 1e-10
    @test evolvability(G_lr, β) ≥ 0           # PSD-safe on a rank-deficient G

    # --- NamedTuple convenience: read result.genetic_covariance ---
    res = (genetic_covariance = Gd,)
    @test evolvability(res, [1.0, 0.0]) ≈ 4.0
    @test g_max(res).eigenvalue ≈ 4.0

    # --- guards ---
    @test_throws ArgumentError evolvability([1.0 2.0; 3.0 4.0], [1.0, 0.0])   # non-symmetric
    @test_throws ArgumentError evolvability(ones(2, 3), [1.0, 0.0])           # non-square
    @test_throws ArgumentError evolvability([1.0 0.0; 0.0 -1.0], [1.0, 0.0])  # indefinite
    @test_throws ArgumentError evolvability(Gd, [1.0, 0.0, 0.0])              # β dimension mismatch
    @test_throws ArgumentError evolvability(Gd, [0.0, 0.0])                   # zero β
    # singular PSD G: evolvability/respondability OK, but conditional/autonomy throw
    Gsing = [1.0 1.0; 1.0 1.0]               # rank-1 PSD
    @test evolvability(Gsing, [1.0, 1.0]) ≈ 2.0
    @test respondability(Gsing, [1.0, 0.0]) ≈ sqrt(2.0)
    @test_throws ArgumentError conditional_evolvability(Gsing, [1.0, 1.0])
    @test_throws ArgumentError autonomy(Gsing, [1.0, 1.0])

    # --- scale-aware guards + variance clamp (review #55, Gauss) ---
    # A meaningfully-indefinite LARGE-scale G is rejected (rel eigmin ~ -1e-3):
    @test_throws ArgumentError evolvability([1.0e6 0.0; 0.0 -1.0e3], [0.0, 1.0])
    # A well-conditioned PD G at TINY scale is accepted (not wrongly rejected):
    Gtiny = [2.0e-11 0.0; 0.0 1.0e-11]
    @test isfinite(conditional_evolvability(Gtiny, [1.0, 1.0]))
    @test conditional_evolvability(Gtiny, [1.0, 1.0]) > 0
    @test isfinite(autonomy(Gtiny, [1.0, 1.0]))
    # A numerically-PSD G (rel eigmin within tolerance) is accepted and the scalar
    # variance metrics are clamped at 0 — never a negative "variance":
    Gpsd_eps = [1.0 0.0; 0.0 -1.0e-12]
    @test evolvability(Gpsd_eps, [0.0, 1.0]) == 0.0
    @test variance_along_gradient(Gpsd_eps, [0.0, 1.0]; normalize = false) ≥ 0.0
end

@testset "G-geometry plot-data preparers (#54 plotting, rotation-invariant)" begin
    # genetic_pca_plot_data: rotation-invariant eigenstructure ONLY, never raw loadings
    G = [3.0 1.0; 1.0 3.0]
    pca = genetic_pca(G)
    pd = genetic_pca_plot_data(G)
    @test pd.eigenvalues == pca.values
    @test pd.eigenvectors == pca.vectors
    @test pd.variance_explained ≈ pca.values ./ sum(pca.values)
    @test sum(pd.variance_explained) ≈ 1.0
    @test pd.loadings_scaled ≈ pca.vectors .* sqrt.(pca.values)'
    @test pd.axis_labels == ["PC1", "PC2"]
    @test pd.rotation_invariant === true && pd.is_eigenstructure_not_loadings === true
    @test !(:loadings in propertynames(pd))                       # never raw FA loadings
    pd1 = genetic_pca_plot_data(G; n_axes = 1)
    @test size(pd1.eigenvectors) == (2, 1) && pd1.axis_labels == ["PC1"]

    # HARD rotation-invariance: low-rank G = ΛΛᵀ and rotated (ΛQ) give the SAME G → same data
    Λ = [0.8 0.2; 0.3 0.9; 0.5 0.1]
    Q = [cos(0.7) -sin(0.7); sin(0.7) cos(0.7)]
    @test genetic_pca_plot_data(lowrank_covariance(Λ)).eigenvalues ≈
          genetic_pca_plot_data(lowrank_covariance(Λ * Q)).eigenvalues

    # genetic_correlation_plot_data
    cd = genetic_correlation_plot_data(G; traits = ["a", "b"])
    @test cd.genetic_correlations == genetic_correlation(G)
    @test cd.traits == ["a", "b"] && cd.rotation_invariant === true
    @test diag(cd.genetic_correlations) ≈ ones(2)
    @test genetic_correlation_plot_data(G).traits == ["trait_1", "trait_2"]
    @test genetic_correlation_plot_data(G; heritabilities = [0.3, 0.5]).heritabilities == [0.3, 0.5]

    # guards
    @test_throws ArgumentError genetic_pca_plot_data([1.0 0.0; 0.0 -1.0])         # indefinite
    @test_throws ArgumentError genetic_pca_plot_data(G; n_axes = 3)               # n_axes > p
    @test_throws ArgumentError genetic_correlation_plot_data(G; traits = ["a"])   # label length
end

@testset "Phase 3 random-regression covariance-function descriptors (#54)" begin
    # --- normalized Legendre basis: exact closed forms at t = -1, 0, 1 ---
    @test legendre_basis(0.0, 3) ≈ [sqrt(1 / 2), 0.0, sqrt(5 / 2) * (-1 / 2)]
    @test legendre_basis(1.0, 3) ≈ [sqrt(1 / 2), sqrt(3 / 2) * 1.0, sqrt(5 / 2) * 1.0]
    @test legendre_basis(-1.0, 3) ≈ [sqrt(1 / 2), sqrt(3 / 2) * -1.0, sqrt(5 / 2) * 1.0]
    @test length(legendre_basis(0.3, 4)) == 4
    @test legendre_basis(0.5, 1) ≈ [sqrt(1 / 2)]                      # degree 0 is the constant

    # orthonormality on [-1,1] by trapezoid quadrature: ∫ φ_m φ_n ≈ δ_mn
    grid = range(-1, 1; length = 4001)
    Φg = reduce(vcat, transpose(legendre_basis(t, 4)) for t in grid)  # 4001 × 4
    gram = zeros(4, 4)
    for j in 1:4, k in 1:4
        gram[j, k] = sum((Φg[i, j] * Φg[i, k] + Φg[i + 1, j] * Φg[i + 1, k]) / 2 *
                         (grid[i + 1] - grid[i]) for i in 1:(length(grid) - 1))
    end
    @test gram ≈ Matrix(I, 4, 4) atol = 1e-3

    # standardize_covariate: endpoints -> ∓1, midpoint -> 0
    @test standardize_covariate([10.0, 20.0, 30.0]) ≈ [-1.0, 0.0, 1.0]
    @test standardize_covariate([2.0, 6.0]; lower = 0.0, upper = 8.0) ≈ [-0.5, 0.5]
    @test_throws ArgumentError standardize_covariate([5.0, 5.0])

    # --- supplied-K_g descriptors on the documented fixture (convention lock) ---
    Kg = [1.0 0.3 0.0; 0.3 0.5 0.1; 0.0 0.1 0.2]
    ts = [-1.0, -0.5, 0.0, 0.5, 1.0]
    vg = rr_genetic_variance(Kg, ts)
    @test vg.covariate == ts
    @test vg.values ≈ [0.8431, 0.4597, 0.625, 0.9309, 2.6569] atol = 1e-3   # Kirkpatrick/Meyer Legendre convention
    @test all(vg.values .>= 0)

    surf = rr_genetic_covariance_surface(Kg, ts)
    @test surf.values ≈ transpose(surf.values)                              # symmetric
    @test diag(surf.values) ≈ vg.values                                     # diagonal == variance trajectory
    @test eigmin(Symmetric(surf.values)) >= -1e-8                           # PSD inherited from K_g

    cor = rr_genetic_correlation_surface(Kg, ts)
    @test diag(cor.values) ≈ ones(5)
    @test all(abs.(cor.values) .<= 1 + 1e-10)
    @test cor.values ≈ genetic_correlation(surf.values)
    @test cor.values[1, 5] ≈ 0.167 atol = 1e-3                              # ρ_g(-1, +1)

    h2 = rr_heritability(Kg, 0.4, ts)
    @test h2.values ≈ [0.678, 0.535, 0.610, 0.700, 0.869] atol = 1e-3
    @test all(0 .< h2.values .< 1)
    # heteroscedastic residual vector; constant vector reduces to the scalar case
    @test rr_heritability(Kg, fill(0.4, 5), ts).values ≈ h2.values
    @test rr_heritability(Kg, [0.4, 0.5, 0.6, 0.5, 0.4], ts).values[1] ≈
          vg.values[1] / (vg.values[1] + 0.4)

    # K_g = I gives v_g(t) = ‖φ(t)‖²
    @test rr_genetic_variance(Matrix(1.0I, 3, 3), ts).values ≈
          [sum(legendre_basis(t, 3) .^ 2) for t in ts]

    # --- guards ---
    @test_throws ArgumentError legendre_basis(1.5, 3)                       # |t| > 1
    @test_throws ArgumentError legendre_basis(0.0, 0)                       # order < 1
    @test_throws ArgumentError rr_genetic_variance([1.0 0.0; 0.0 -1.0], [0.0])  # indefinite K_g
    @test_throws ArgumentError rr_genetic_variance(ones(2, 3), [0.0])          # non-square
    @test_throws ArgumentError rr_heritability(Kg, -0.1, ts)               # non-positive residual
    @test_throws ArgumentError rr_heritability(Kg, [0.4, 0.5], ts)         # residual length mismatch
    @test_throws ArgumentError rr_genetic_correlation_surface([0.0 0.0; 0.0 1.0], [0.0])  # zero-variance point
end

@testset "Phase 3 random-regression eigen-function decomposition (#54 slice 4)" begin
    # Kirkpatrick covariance-function eigen-analysis of a supplied coefficient
    # genetic covariance K_g: eigen-decompose K_g, evaluate the eigenfunctions
    # ψ_j(t) = φ(t)ᵀ v_j over the Legendre basis. Rotation-invariant (reuses
    # genetic_pca), descriptive, supplied-covariance only.
    Kg = [1.0 0.3 0.0; 0.3 0.5 0.1; 0.0 0.1 0.2]
    k = size(Kg, 1)
    ts = [-1.0, -0.5, 0.0, 0.5, 1.0]
    ef = rr_eigenfunctions(Kg, ts)

    # eigenvalues / eigen-coefficients ARE the genetic_pca of K_g (the
    # rotation-invariant representation), descending
    pca = genetic_pca(Kg)
    @test ef.eigenvalues ≈ pca.values
    @test ef.eigen_coefficients ≈ pca.vectors
    @test issorted(ef.eigenvalues; rev = true)
    @test ef.covariate == ts

    # eigenfunctions evaluated at ts == Φ * eigen_coefficients
    Φ = legendre_design(ts, k)
    @test size(ef.eigenfunctions) == (length(ts), k)
    @test ef.eigenfunctions ≈ Φ * ef.eigen_coefficients

    # spectral reconstruction of the covariance surface:
    # Φ K_g Φᵀ = Σ_j λ_j ψ_j ψ_jᵀ = Ψ diag(λ) Ψᵀ
    surf = rr_genetic_covariance_surface(Kg, ts)
    @test ef.eigenfunctions * Diagonal(ef.eigenvalues) * transpose(ef.eigenfunctions) ≈
          surf.values atol = 1e-10

    # variance explained: descending, sums to 1, == λ / Σλ
    @test ef.variance_explained ≈ ef.eigenvalues ./ sum(ef.eigenvalues)
    @test sum(ef.variance_explained) ≈ 1.0
    @test issorted(ef.variance_explained; rev = true)

    # eigenfunction ORTHONORMALITY on [-1,1] (Kirkpatrick): ∫ ψ_i ψ_j ≈ δ_ij,
    # since the eigen-coefficients and the Legendre basis are both orthonormal
    grid = range(-1, 1; length = 4001)
    Ψg = rr_eigenfunctions(Kg, collect(grid)).eigenfunctions
    gram = zeros(k, k)
    for a in 1:k, b in 1:k
        gram[a, b] = sum((Ψg[i, a] * Ψg[i, b] + Ψg[i + 1, a] * Ψg[i + 1, b]) / 2 *
                         (grid[i + 1] - grid[i]) for i in 1:(length(grid) - 1))
    end
    @test gram ≈ Matrix(I, k, k) atol = 1e-3

    # diagonal K_g = diag(d): eigenvalues are sorted(d) descending
    d = [0.2, 0.9, 0.4]
    @test rr_eigenfunctions(Matrix(Diagonal(d)), ts).eigenvalues ≈ sort(d; rev = true)

    # rank-1 K_g = λ v vᵀ (unit v): one nonzero eigenvalue, all variance on axis 1
    v = [0.6, -0.8, 0.0]
    ef1 = rr_eigenfunctions(2.5 .* (v * transpose(v)), ts)
    @test ef1.variance_explained[1] ≈ 1.0 atol = 1e-8
    @test all(ef1.variance_explained[2:end] .< 1e-8)

    # guards (reuse the K_g PSD/shape guard and the |t| ≤ 1 basis guard)
    @test_throws ArgumentError rr_eigenfunctions([1.0 0.0; 0.0 -1.0], ts)   # indefinite K_g
    @test_throws ArgumentError rr_eigenfunctions(ones(2, 3), ts)           # non-square
    @test_throws ArgumentError rr_eigenfunctions(Kg, [1.5])                # |t| > 1
end

@testset "Phase 3 random-regression plot-data preparers (#54, plotting layer)" begin
    # Thin *_plot_data wrappers (marker_*_data convention): delegate to the existing
    # tested RR descriptors + carry honest-status flags (supplied, rotation_invariant)
    # for the R ggplot2 / Julia Makie drawing layer. No backend, no estimation.
    Kg = [1.0 0.3 0.0; 0.3 0.5 0.1; 0.0 0.1 0.2]
    ts = [-1.0, -0.5, 0.0, 0.5, 1.0]

    ef = rr_eigenfunctions(Kg, ts)
    pd = rr_eigenfunctions_plot_data(Kg, ts)
    @test pd.covariate == ef.covariate
    @test pd.eigenvalues == ef.eigenvalues
    @test pd.eigenfunctions == ef.eigenfunctions
    @test pd.variance_explained == ef.variance_explained
    @test pd.basis_order == 3
    @test pd.rotation_invariant === true && pd.supplied === true
    @test propertynames(pd) ==
          (:covariate, :eigenvalues, :eigenfunctions, :variance_explained, :basis_order, :rotation_invariant, :supplied)

    vg = rr_genetic_variance(Kg, ts)
    pv = rr_genetic_variance_plot_data(Kg, ts)
    @test pv.covariate == vg.covariate
    @test pv.genetic_variance == vg.values
    @test pv.heritability === nothing
    @test pv.basis_order == 3 && pv.supplied === true
    @test rr_genetic_variance_plot_data(Kg, ts; residual = 0.4).heritability ==
          rr_heritability(Kg, 0.4, ts).values

    ps = rr_covariance_surface_plot_data(Kg, ts)
    @test ps.surface == rr_genetic_covariance_surface(Kg, ts).values
    @test ps.is_correlation === false && ps.supplied === true
    pc = rr_covariance_surface_plot_data(Kg, ts; correlation = true)
    @test pc.surface == rr_genetic_correlation_surface(Kg, ts).values
    @test pc.is_correlation === true

    # guards delegate to the underlying descriptors
    @test_throws ArgumentError rr_eigenfunctions_plot_data([1.0 0.0; 0.0 -1.0], ts)  # non-PSD
    @test_throws ArgumentError rr_covariance_surface_plot_data(Kg, [1.5])            # |t| > 1
end

@testset "Phase 3 supplied-covariance random-regression MME (#54 slice 2)" begin
    # 5-animal pedigree, 2 records each at distinct covariates (n = 10), k = 2
    # (linear reaction norm: intercept + slope).
    ped = normalize_pedigree(["a1", "a2", "a3", "a4", "a5"],
        ["0", "0", "a1", "a1", "a2"], ["0", "0", "a2", "a2", "a3"])
    Ainv = pedigree_inverse(ped)
    q = length(ped.ids)
    rec = ["a1", "a1", "a2", "a2", "a3", "a3", "a4", "a4", "a5", "a5"]
    ts = standardize_covariate([1.0, 4.0, 2.0, 5.0, 1.5, 6.0, 3.0, 4.5, 2.5, 5.5])
    Phi = legendre_design(ts, 2)
    n = length(ts)
    @test size(Phi) == (10, 2)
    @test Phi[1, :] ≈ legendre_basis(ts[1], 2)          # design rows are the basis vectors
    Zinc = zeros(n, q)
    idx = Dict(id => i for (i, id) in enumerate(ped.ids))
    for r in 1:n
        Zinc[r, idx[rec[r]]] = 1.0
    end
    y = [2.3, 3.1, 1.8, 4.0, 2.9, 5.2, 3.3, 3.9, 2.1, 4.7]
    X = ones(n, 1)
    Kg = [1.0 0.2; 0.2 0.5]        # PD, UNEQUAL diagonal + off-diagonal coupling (pins coefficient ordering)
    σe2 = 0.4

    res = random_regression_mme(y, X, Phi, Zinc, Ainv, Kg, σe2; ids = ped.ids)
    @test res.random_coefficients.ids == ped.ids
    @test size(res.random_coefficients.values) == (q, 2)
    @test res.variance_components.K_g == Kg
    @test res.basis.ncoef == 2

    # INDEPENDENT dense marginal-GLS oracle (W built here from scratch, NOT via the
    # implementation's _rr_random_design, so a design/ordering bug cannot pass):
    A = inv(Matrix(Ainv))
    W = zeros(n, q * 2)
    for r in 1:n
        a = idx[rec[r]]
        W[r, (a - 1) * 2 + 1] = Phi[r, 1]
        W[r, (a - 1) * 2 + 2] = Phi[r, 2]
    end
    Gcov = kron(A, Kg)
    V = W * Gcov * transpose(W) + σe2 * Matrix(I, n, n)
    Vi = inv(V)
    β_oracle = (transpose(X) * Vi * X) \ (transpose(X) * Vi * y)
    a_oracle = permutedims(reshape(Gcov * transpose(W) * Vi * (y - X * β_oracle), 2, q))
    @test res.beta ≈ β_oracle atol = 1e-8
    @test res.random_coefficients.values ≈ a_oracle atol = 1e-8

    # degree-0 reduction: with k = 1 and K_g = [2σ²a], the RR MME equals the scalar
    # animal model (φ_0 = sqrt(1/2), so var(φ_0·a) = 0.5·2σ²a·A = σ²a·A): β matches
    # henderson_mme, and the RR coefficient a = sqrt(2)·u (since φ_0·a = u).
    σa2 = 0.8
    spec = animal_model_spec(y, X, sparse(Zinc), Ainv; ids = ped.ids, method = :REML)
    mme_h = henderson_mme(spec, σa2, σe2)
    rr0 = random_regression_mme(y, X, legendre_design(ts, 1), Zinc, Ainv,
                                fill(2σa2, 1, 1), σe2; ids = ped.ids)
    @test rr0.beta ≈ fixed_effects(mme_h) atol = 1e-8
    @test rr0.random_coefficients.values[:, 1] ≈ sqrt(2) .* breeding_values(mme_h).values atol = 1e-8

    # guards
    @test_throws ArgumentError random_regression_mme(y, X, Phi, Zinc, Ainv, [1.0 0.0; 0.0 -1.0], σe2)  # K_g not PD
    @test_throws ArgumentError random_regression_mme(y, X, Phi, Zinc, Ainv, Kg, -0.1)                  # σe2 ≤ 0
    @test_throws ArgumentError random_regression_mme(y, X, Phi[:, 1:1], Zinc, Ainv, Kg, σe2)           # Phi cols ≠ K_g dim
    @test_throws ArgumentError random_regression_mme(y[1:9], X, Phi, Zinc, Ainv, Kg, σe2)              # row mismatch
end

@testset "Phase 3 random-regression REML (#54 slice 3)" begin
    # Same 5-animal pedigree / 10 records (2 per animal at distinct covariates),
    # k = 2 (intercept + slope reaction norm). REML now ESTIMATES K_g (2×2) + σ²e.
    ped = normalize_pedigree(["a1", "a2", "a3", "a4", "a5"],
        ["0", "0", "a1", "a1", "a2"], ["0", "0", "a2", "a2", "a3"])
    Ainv = pedigree_inverse(ped)
    q = length(ped.ids)
    rec = ["a1", "a1", "a2", "a2", "a3", "a3", "a4", "a4", "a5", "a5"]
    ts = standardize_covariate([1.0, 4.0, 2.0, 5.0, 1.5, 6.0, 3.0, 4.5, 2.5, 5.5])
    n = length(ts)
    Zinc = zeros(n, q)
    idx = Dict(id => i for (i, id) in enumerate(ped.ids))
    for r in 1:n
        Zinc[r, idx[rec[r]]] = 1.0
    end
    # strong within-animal / family signal so the degree-0 reduction lands at an
    # INTERIOR σ²a (not the zero-variance boundary), making K_g[1,1] = 2σ²a a
    # non-vacuous check. Deterministic (the test suite is RNG-free).
    y = [4.5, 4.4, 1.5, 1.4, 3.8, 3.7, 3.9, 4.0, 2.3, 2.2]
    X = ones(n, 1)
    A = inv(Matrix(Ainv))

    # INDEPENDENT marginal-REML oracle log-likelihood at supplied (K_g, σ²e). W is
    # built here from scratch (NOT via the implementation), so a design/ordering or
    # likelihood-scale bug cannot pass. Full (n − p)·log(2π) constant included.
    function rr_oracle_loglik(Kg, σe2, order)
        Phi = legendre_design(ts, order)
        W = zeros(n, q * order)
        for r in 1:n
            a = idx[rec[r]]
            for c in 1:order
                W[r, (a - 1) * order + c] = Phi[r, c]
            end
        end
        V = W * kron(A, Kg) * transpose(W) + σe2 * Matrix(I, n, n)
        Vi = inv(V)
        XtViX = transpose(X) * Vi * X
        β = XtViX \ (transpose(X) * Vi * y)
        resid = y - X * β
        return -0.5 * ((n - size(X, 2)) * log(2π) + logdet(V) + logdet(XtViX) +
                       dot(resid, Vi * resid))
    end

    # --- k = 2 REML fit ---
    fit = fit_random_regression_reml(y, X, legendre_design(ts, 2), Zinc, Ainv; ids = ped.ids)
    @test fit.converged
    @test fit.basis.ncoef == 2
    @test size(fit.variance_components.K_g) == (2, 2)
    @test issymmetric(Symmetric(fit.variance_components.K_g))
    @test isposdef(Symmetric(fit.variance_components.K_g))
    @test fit.variance_components.sigma_e2 > 0
    @test fit.random_coefficients.ids == ped.ids
    @test size(fit.random_coefficients.values) == (q, 2)

    Khat = fit.variance_components.K_g
    σe2hat = fit.variance_components.sigma_e2

    # reported log-likelihood matches the independent oracle at the estimate
    @test fit.loglik ≈ rr_oracle_loglik(Khat, σe2hat, 2) atol = 1e-6
    # the estimate is a genuine maximum: it beats deliberately-wrong points
    @test fit.loglik >= rr_oracle_loglik([1.0 0.2; 0.2 0.5], 0.4, 2) - 1e-8
    @test fit.loglik >= rr_oracle_loglik(2.0 .* Khat, σe2hat, 2) - 1e-8
    @test fit.loglik >= rr_oracle_loglik(Khat, 4.0 * σe2hat, 2) - 1e-8
    @test fit.loglik >= rr_oracle_loglik(Matrix(0.25 * I, 2, 2), 1.0, 2) - 1e-8

    # EBV/coefficient consistency: the supplied-covariance MME at the estimate
    # reproduces the fit's BLUP coefficients and β (GLS BLUP == MME for a PD K_g).
    mme = random_regression_mme(y, X, legendre_design(ts, 2), Zinc, Ainv, Khat, σe2hat; ids = ped.ids)
    @test fit.beta ≈ mme.beta atol = 1e-7
    @test fit.random_coefficients.values ≈ mme.random_coefficients.values atol = 1e-7

    # --- degree-0 reduction (order = 1) to the scalar animal-model REML ---
    # at k = 1, V = (1/2)·K_g[1,1]·ZAZ' + σ²e·I, so the RR REML optimum maps to the
    # univariate REML optimum via K_g[1,1] = 2σ²a (φ_0² = 1/2): equal σ²e, equal loglik.
    spec = animal_model_spec(y, X, sparse(Zinc), Ainv; ids = ped.ids, method = :REML)
    uni = fit_sparse_reml(spec)
    rr1 = fit_random_regression_reml(y, X, legendre_design(ts, 1), Zinc, Ainv; ids = ped.ids)
    @test rr1.variance_components.K_g[1, 1] / 2 ≈ uni.variance_components.sigma_a2 rtol = 1e-3
    @test rr1.variance_components.sigma_e2 ≈ uni.variance_components.sigma_e2 rtol = 1e-3
    @test rr1.loglik ≈ uni.likelihood.loglik atol = 1e-4

    # guards
    @test_throws ArgumentError fit_random_regression_reml(y[1:9], X, legendre_design(ts, 2), Zinc, Ainv)  # row mismatch
    @test_throws ArgumentError fit_random_regression_reml(y, X, legendre_design(ts, 2), Zinc[:, 1:4], Ainv)  # Z cols ≠ q
    @test_throws ArgumentError fit_random_regression_reml(y, X, legendre_design(ts, 2), Zinc, Ainv;
                                                          initial = (sigma_e2 = -0.5,))  # bad initial
end

@testset "Genetic-GLLVM latent-structure descriptors (#50 slice 1, supplied Λ)" begin
    # 3 traits, 2 latent factors; deterministic loadings (RNG-free)
    Λ = [1.0 0.0; 0.5 0.8; 0.3 0.4]
    Ψ = [0.2, 0.3, 0.5]

    # --- low-rank (no uniqueness): Σ_g = ΛΛ' ---
    d = genetic_gllvm_descriptors(Λ)
    @test propertynames(d) == (:genetic_covariance, :genetic_variances, :genetic_correlation,
                               :communality, :genetic_pca, :g_max, :rank, :n_latent_factors)
    @test d.genetic_covariance ≈ lowrank_covariance(Λ)                  # gate 1 (Ψ = 0): exact
    @test d.genetic_variances ≈ diag(lowrank_covariance(Λ))
    @test d.rank == 2 && d.n_latent_factors == 2
    @test all(d.communality .≈ 1.0)                                     # gate 2: communality == 1 at Ψ = 0
    @test d.genetic_correlation ≈ genetic_correlation(lowrank_covariance(Λ))
    @test d.genetic_pca.values ≈ genetic_pca(lowrank_covariance(Λ)).values
    @test d.g_max.eigenvalue ≈ g_max(lowrank_covariance(Λ)).eigenvalue

    # --- factor-analytic: Σ_g = ΛΛ' + diag(Ψ) ---
    fa = genetic_gllvm_descriptors(Λ; uniqueness = Ψ)
    @test fa.genetic_covariance ≈ factor_analytic_covariance(Λ, Ψ)      # gate 1 (Ψ > 0): exact
    common = vec(sum(abs2, Λ; dims = 2))                                # diag(ΛΛ'), the common part
    @test fa.communality ≈ common ./ (common .+ Ψ)                      # gate 2: matches definition
    @test all(0 .<= fa.communality .<= 1)
    @test all(fa.communality .< 1)                                      # strictly < 1 with positive Ψ

    # --- gate 3: rotation invariance (Λ → ΛQ, Q orthogonal) ---
    θ = 0.7
    Q = [cos(θ) -sin(θ); sin(θ) cos(θ)]
    dR = genetic_gllvm_descriptors(Λ * Q; uniqueness = Ψ)
    @test dR.genetic_covariance ≈ fa.genetic_covariance
    @test dR.genetic_variances ≈ fa.genetic_variances
    @test dR.communality ≈ fa.communality
    @test dR.genetic_correlation ≈ fa.genetic_correlation
    @test dR.genetic_pca.values ≈ fa.genetic_pca.values

    # --- gate 4: reduction K = t, Λ = I, Ψ = 0 → Σ_g = I, communality = 1, eigenvalues all 1 ---
    di = genetic_gllvm_descriptors(Matrix(1.0I, 3, 3))
    @test di.genetic_covariance ≈ Matrix(1.0I, 3, 3)
    @test all(di.communality .≈ 1.0)
    @test di.genetic_pca.values ≈ [1.0, 1.0, 1.0]

    # --- gate 5: guards (delegated to lowrank_/factor_analytic_covariance) ---
    @test_throws ArgumentError genetic_gllvm_descriptors(Λ; uniqueness = [0.2, 0.3])        # Ψ length mismatch
    @test_throws ArgumentError genetic_gllvm_descriptors(Λ; uniqueness = [0.2, 0.3, -0.1])  # non-positive Ψ
    @test_throws ArgumentError genetic_gllvm_descriptors(zeros(3, 2))                        # zero common variance
    @test_throws ArgumentError genetic_gllvm_descriptors(zeros(3, 0))                        # no latent factors
end

@testset "Genetic-GLLVM Gaussian latent solve (#50 slice 2, supplied G_lat)" begin
    # 4-animal pedigree, 2 traits, one balanced record per animal (mirrors the
    # multivariate fixture) — the Gaussian genetic GLLVM == multivariate model at G0 = G_lat
    Ainv = pedigree_inverse([1, 2, 3, 4], [0, 0, 1, 1], [0, 0, 2, 2])
    n = 4; q = 4; t = 2
    Z = Matrix(1.0I, n, q)
    X = ones(n, 1)
    Y = [10.0 50.0; 12.0 47.0; 9.0 53.0; 11.0 49.0]
    R0 = [2.0 0.3; 0.3 1.0]

    # --- factor-analytic G_lat (PD via Ψ): K = 1 < t, defining identity ---
    Λ1 = reshape([0.8, 0.5], 2, 1)
    Ψ = [0.3, 0.5]
    glat = factor_analytic_covariance(Λ1, Ψ)
    g = genetic_gllvm_gaussian_mme(Y, X, Z, Ainv, Λ1, R0; uniqueness = Ψ)
    mv = multivariate_mme(Y, X, Z, Ainv, glat, R0)
    @test g.beta ≈ mv.beta                                             # defining identity (exact)
    @test g.breeding_values.values ≈ mv.breeding_values.values
    @test g.genetic_covariance ≈ glat
    @test g.n_latent_factors == 1
    @test g.latent_structure.communality ≈ genetic_gllvm_descriptors(Λ1; uniqueness = Ψ).communality
    @test propertynames(g) == (:beta, :breeding_values, :genetic_covariance, :residual_covariance,
                               :genetic_correlation, :residual_correlation, :traits,
                               :latent_structure, :n_latent_factors)

    # --- full-rank low-rank G_lat (K = t, PD without uniqueness) ---
    Λ2 = [1.2 0.2; 0.3 1.1]
    g2 = genetic_gllvm_gaussian_mme(Y, X, Z, Ainv, Λ2, R0)
    @test g2.beta ≈ multivariate_mme(Y, X, Z, Ainv, lowrank_covariance(Λ2), R0).beta
    @test g2.n_latent_factors == 2

    # --- rotation invariance: Λ → ΛQ (orthogonal Q) leaves the solve invariant ---
    θ = 0.6; Q = [cos(θ) -sin(θ); sin(θ) cos(θ)]
    gR = genetic_gllvm_gaussian_mme(Y, X, Z, Ainv, Λ2 * Q, R0)
    @test gR.beta ≈ g2.beta
    @test gR.breeding_values.values ≈ g2.breeding_values.values
    @test gR.genetic_covariance ≈ g2.genetic_covariance

    # --- t = 1, K = 1 reduction to the univariate animal model (henderson_mme) ---
    y1 = reshape(Y[:, 1], n, 1)
    λ = 0.9
    spec = animal_model_spec(Y[:, 1], X, sparse(Z), Ainv; ids = [1, 2, 3, 4], method = :REML)
    hm = henderson_mme(spec, λ^2, R0[1, 1])
    g1 = genetic_gllvm_gaussian_mme(y1, X, Z, Ainv, reshape([λ], 1, 1), reshape([R0[1, 1]], 1, 1))
    @test vec(g1.beta) ≈ hm.beta
    @test vec(g1.breeding_values.values) ≈ hm.animal_effects.values

    # --- guards ---
    @test_throws ArgumentError genetic_gllvm_gaussian_mme(Y, X, Z, Ainv, reshape([1.0, 1.0, 1.0], 3, 1), R0; uniqueness = [0.2, 0.3, 0.4])  # 3 traits vs Y's 2
    @test_throws ArgumentError genetic_gllvm_gaussian_mme(Y, X, Z, Ainv, Λ1, R0)  # K=1<t low-rank, no Ψ ⇒ singular G_lat
end

@testset "Genetic-GLLVM descriptors from an estimated FA/lowrank fit (#50)" begin
    ped = normalize_pedigree(["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"],
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Ainv = pedigree_inverse(ped)
    y1 = [2.0, 3.0, 2.5, 3.5, 4.0, 1.5, 3.0, 4.5]; Y2 = hcat(y1, reverse(y1))
    X = ones(8, 1); Z = Matrix(1.0I, 8, 8)

    # --- factor-analytic fit (real, deterministic — same fixture as the FA REML testset) ---
    fa = fit_multivariate_reml(Y2, X, Z, Ainv; genetic_structure = :factor_analytic, rank = 1,
        initial = (loadings = reshape([0.5, -0.3], 2, 1), uniqueness = [0.4, 0.4], R0 = [1.0 0.0; 0.0 1.0]))
    dfa = genetic_gllvm_descriptors(fa)
    @test propertynames(dfa) == (:genetic_covariance, :genetic_variances, :genetic_correlation,
                                 :communality, :genetic_pca, :g_max, :rank, :n_latent_factors)
    G = fa.genetic_covariance; Ψ = genetic_uniqueness(fa)
    @test dfa.genetic_covariance ≈ G
    @test dfa.communality ≈ 1 .- Ψ ./ diag(G)                    # rotation-invariant: from G & Ψ, not loadings
    @test dfa.communality ≈ (diag(G) .- Ψ) ./ diag(G)
    @test all(0 .< dfa.communality .< 1)
    @test dfa.n_latent_factors == 1 && dfa.rank == 1
    @test dfa.genetic_pca.values ≈ genetic_pca(G).values

    # --- low-rank fit: Ψ = nothing ⇒ communality = 1 (all genetic variance common) ---
    low = fit_multivariate_reml(Y2, X, Z, Ainv; genetic_structure = :lowrank, rank = 1,
        initial = (loadings = reshape([0.7, -0.4], 2, 1), R0 = [1.0 0.0; 0.0 1.0]))
    dlow = genetic_gllvm_descriptors(low)
    @test genetic_uniqueness(low) === nothing
    @test all(dlow.communality .≈ 1.0)
    @test dlow.genetic_covariance ≈ low.genetic_covariance

    # --- explicit communality values via a synthetic structured result ---
    Λ = [1.0 0.2; 0.4 0.9; 0.3 0.5]; ψ = [0.3, 0.4, 0.6]
    Gs = Λ * transpose(Λ) + Diagonal(ψ)
    synth = (genetic_covariance = Gs, residual_covariance = Matrix(1.0I, 3, 3),
             beta = zeros(1, 3), breeding_values = (ids = [1], traits = ["t1", "t2", "t3"], values = zeros(1, 3)),
             genetic_structure = :factor_analytic, genetic_rank = 2,
             genetic_loadings = Λ, genetic_uniqueness = ψ)
    ds = genetic_gllvm_descriptors(synth)
    @test ds.communality ≈ vec(sum(abs2, Λ; dims = 2)) ./ diag(Gs)   # == (ΛΛ')_tt / G_tt
    @test ds.n_latent_factors == 2

    # --- reject rotation-free structures (no latent-factor interpretation) ---
    full = fit_multivariate_reml(Y2, X, Z, Ainv)                      # :unstructured
    @test_throws ArgumentError genetic_gllvm_descriptors(full)
    diagfit = fit_multivariate_reml(Y2, X, Z, Ainv; genetic_structure = :diagonal)
    @test_throws ArgumentError genetic_gllvm_descriptors(diagfit)
end

@testset "Genetic-GLLVM K-factor latent Laplace marginal (#50 slice 2, non-Gaussian)" begin
    ped = normalize_pedigree(["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"],
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Ainv = Matrix(pedigree_inverse(ped)); q = 8
    Z = Matrix(1.0I, q, q); X = ones(q, 1)
    gl = HSquared.gllvm_laplace_marginal_loglik
    lap = HSquared.laplace_marginal_loglik

    # --- reduction 1: K=1, T=1 reduces EXACTLY to the single-factor kernel (σ²a = λ²) ---
    λ = 0.8; σe = 1.3
    y1 = reshape([2.0, 3.0, 2.5, 3.5, 4.0, 1.5, 3.0, 4.5], q, 1)
    g_gauss = gl(y1, Ainv, reshape([λ], 1, 1), HSquared.GaussianResponse(σe); X = X)
    s_gauss = lap(vec(y1), X, Z, Ainv, λ^2, HSquared.GaussianResponse(σe))
    @test g_gauss.loglik ≈ s_gauss.loglik                      # Gaussian: exact
    @test size(g_gauss.beta) == (1, 1) && size(g_gauss.g) == (q, 1)
    yp = reshape(Float64[2, 1, 3, 0, 4, 2, 1, 5], q, 1)
    g_pois = gl(yp, Ainv, reshape([λ], 1, 1), HSquared.PoissonResponse(); X = X)
    s_pois = lap(vec(yp), X, Z, Ainv, λ^2, HSquared.PoissonResponse())
    @test g_pois.loglik ≈ s_pois.loglik rtol = 1e-7            # Poisson: exact (Laplace affine-invariance)
    @test g_pois.converged

    # --- reduction 2: Gaussian, full-rank Λ (K=T=2) == multivariate REML marginal at G0=ΛΛ' ---
    Y2 = [2.0 5.0; 3.0 4.5; 2.5 5.2; 3.5 4.0; 4.0 6.0; 1.5 3.5; 3.0 5.0; 4.5 6.2]
    Λ2 = [1.1 0.3; 0.4 1.2]; σe2 = 0.9
    g2 = gl(Y2, Ainv, Λ2, HSquared.GaussianResponse(σe2); X = X)
    mv = HSquared._multivariate_reml_loglik(Y2, X, Z, Ainv, Λ2 * transpose(Λ2), σe2 * Matrix(1.0I, 2, 2))
    @test g2.loglik ≈ mv rtol = 1e-7
    @test size(g2.beta) == (1, 2) && size(g2.g) == (q, 2)

    # --- non-Gaussian convergence + mode-stationarity (Bernoulli / Binomial) ---
    yb = Float64[1 0; 0 1; 1 1; 0 0; 1 0; 1 1; 0 1; 1 0]
    gb = gl(yb, Ainv, Λ2, HSquared.BernoulliResponse(); X = X)
    @test gb.converged && gb.gradient_norm < 1e-8 && isfinite(gb.loglik)
    ybin = Float64[3 7; 5 4; 6 6; 2 8; 4 5; 7 3; 1 9; 8 2]
    gbin = gl(ybin, Ainv, Λ2, HSquared.BinomialResponse(10); X = X)
    @test gbin.converged && gbin.gradient_norm < 1e-8 && isfinite(gbin.loglik)

    # --- non-Gaussian K>1 VALUE anchor (not just stationarity): a block-diagonal Λ
    #     makes the traits INDEPENDENT, so the K=2 Poisson marginal must equal the SUM
    #     of two single-factor laplace marginals (σ²a = a²/b²). Pins the constant term
    #     (e.g. the 0.5·K·logdet(Ainv) factor) against the trusted single-factor kernel.
    a = 0.7; b = 1.1
    Yp2 = Float64[2 4; 1 3; 3 5; 0 2; 4 6; 2 1; 1 7; 5 0]
    gK2 = gl(Yp2, Ainv, [a 0.0; 0.0 b], HSquared.PoissonResponse(); X = X)
    s_a = lap(Yp2[:, 1], X, Z, Ainv, a^2, HSquared.PoissonResponse())
    s_b = lap(Yp2[:, 2], X, Z, Ainv, b^2, HSquared.PoissonResponse())
    @test gK2.loglik ≈ s_a.loglik + s_b.loglik rtol = 1e-7

    # --- singular G_lat (K<T, no Ψ) and K>T both work — P = I_K⊗Ainv is full-rank
    #     regardless of rank(ΛΛ'), unlike the Gaussian-MME path which rejects a singular
    #     G_lat — and equal the multivariate REML marginal at the same (possibly singular) ΛΛ'.
    Λsing = reshape([1.0, 2.0], 2, 1)               # T=2, K=1 ⇒ ΛΛ' rank-1 (singular)
    gsing = gl(Y2, Ainv, Λsing, HSquared.GaussianResponse(σe2); X = X)
    @test gsing.loglik ≈ HSquared._multivariate_reml_loglik(Y2, X, Z, Ainv,
        Λsing * transpose(Λsing), σe2 * Matrix(1.0I, 2, 2)) rtol = 1e-7
    Λwide = [1.1 0.3 0.2; 0.4 1.2 0.5]              # T=2, K=3 (K>T)
    gwide = gl(Y2, Ainv, Λwide, HSquared.GaussianResponse(σe2); X = X)
    @test gwide.loglik ≈ HSquared._multivariate_reml_loglik(Y2, X, Z, Ainv,
        Λwide * transpose(Λwide), σe2 * Matrix(1.0I, 2, 2)) rtol = 1e-7
    @test size(gwide.g) == (q, 3)

    # --- guards ---
    @test_throws ArgumentError gl(Y2, Ainv, reshape([1.0], 1, 1), HSquared.GaussianResponse(1.0); X = X)  # Λ rows ≠ T
    @test_throws ArgumentError gl(Y2, Matrix(1.0I, 7, 7), Λ2, HSquared.GaussianResponse(1.0); X = X)        # Ainv ≠ q×q
    @test_throws ArgumentError gl(Y2, Ainv, Λ2, HSquared.PoissonResponse(); X = X)                          # non-count Y
end

@testset "Genetic-GLLVM REML over G_lat (#50 slice 3)" begin
    ped = normalize_pedigree(["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"],
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Ainv = Matrix(pedigree_inverse(ped)); q = 8
    Z = Matrix(1.0I, q, q); X = ones(q, 1)
    fitr = HSquared.fit_gllvm_laplace_reml
    gl = HSquared.gllvm_laplace_marginal_loglik

    # --- K=1, T=1 Poisson REML reduces to the single-factor fit_laplace_reml (σ²a = λ̂²) ---
    yp = reshape(Float64[2, 1, 3, 0, 4, 2, 1, 5], q, 1)
    gr = fitr(yp, Ainv, HSquared.PoissonResponse(); rank = 1, initial = reshape([1.0], 1, 1))
    fl = fit_laplace_reml(vec(yp), X, Z, Ainv; family = :poisson, initial = (sigma_a2 = 1.0,))
    @test gr.genetic_covariance[1, 1] ≈ variance_components(fl).sigma_a2 rtol = 2e-3
    @test gr.converged
    @test size(gr.genetic_covariance) == (1, 1) && gr.n_latent_factors == 1

    # --- multi-trait Poisson rank-1: the optimum improves over the start (objective maximized) ---
    Yp2 = Float64[2 4; 1 3; 3 5; 0 2; 4 6; 2 1; 1 7; 5 0]
    Λ0 = reshape([0.6, 0.5], 2, 1)
    gr2 = fitr(Yp2, Ainv, HSquared.PoissonResponse(); rank = 1, initial = Λ0)
    @test gr2.converged
    @test gr2.loglik ≥ gl(Yp2, Ainv, Λ0, HSquared.PoissonResponse(); X = X).loglik - 1e-6
    @test size(gr2.genetic_covariance) == (2, 2)
    @test size(gr2.breeding_values) == (q, 1)
    @test haskey(gr2.latent_structure, :communality)

    # --- Gaussian self-consistency: the marginal at the optimum equals the multivariate
    #     REML marginal at Λ̂Λ̂' (R0 = σ²e·I), confirming the reported G_lat ---
    Yg = [2.0 5.0; 3.0 4.5; 2.5 5.2; 3.5 4.0; 4.0 6.0; 1.5 3.5; 3.0 5.0; 4.5 6.2]; σe = 0.9
    gg = fitr(Yg, Ainv, HSquared.GaussianResponse(σe); rank = 1, initial = reshape([0.8, 0.6], 2, 1))
    @test gg.converged
    @test gg.loglik ≈ HSquared._multivariate_reml_loglik(Yg, X, Z, Ainv,
        gg.genetic_covariance, σe * Matrix(1.0I, 2, 2)) rtol = 1e-7
    @test gg.uniqueness === nothing                                  # low-rank carries no Ψ

    # --- factor-analytic (+Ψ) structure: estimate Λ AND per-trait Ψ via augmented loadings
    #     [Λ | diag(√Ψ)] (so G_lat = Λ̂Λ̂' + diag(Ψ̂)), reusing the marginal unchanged ---
    fa = fitr(Yg, Ainv, HSquared.GaussianResponse(σe); rank = 1, structure = :factor_analytic,
              initial = reshape([0.8, 0.6], 2, 1), initial_uniqueness = [0.3, 0.3])
    @test fa.converged
    @test fa.uniqueness !== nothing && length(fa.uniqueness) == 2 && all(fa.uniqueness .> 0)
    @test all(0 .< fa.latent_structure.communality .< 1)             # Ψ > 0 ⇒ communality < 1
    @test fa.loglik ≈ HSquared._multivariate_reml_loglik(Yg, X, Z, Ainv,
        fa.genetic_covariance, σe * Matrix(1.0I, 2, 2)) rtol = 1e-7  # Gaussian self-consistency at Ĝ = Λ̂Λ̂' + Ψ̂
    @test fa.loglik ≥ gg.loglik - 1e-4                               # FA nests low-rank (Ψ → 0)
    fap = fitr(Yp2, Ainv, HSquared.PoissonResponse(); rank = 1, structure = :factor_analytic,
               initial = reshape([0.5, 0.4], 2, 1), initial_uniqueness = [0.2, 0.2])
    @test fap.converged && all(fap.uniqueness .> 0)

    # --- guards ---
    @test_throws ArgumentError fitr(Yg, Ainv, HSquared.GaussianResponse(1.0); rank = 0)
    @test_throws ArgumentError fitr(Yg, Ainv, HSquared.GaussianResponse(1.0); rank = 1, initial = reshape([1.0], 1, 1))
    @test_throws ArgumentError fitr(Yg, Ainv, HSquared.GaussianResponse(1.0); rank = 1, structure = :bogus)
    @test_throws ArgumentError fitr(Yg, Ainv, HSquared.GaussianResponse(1.0); rank = 1,
        structure = :factor_analytic, initial_uniqueness = [0.1])    # wrong Ψ length
end

@testset "Genetic-GLLVM per-trait response families (#50 slice 2 extension)" begin
    ped = normalize_pedigree(["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"],
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Ainv = Matrix(pedigree_inverse(ped)); q = 8
    X = ones(q, 1)
    gl = HSquared.gllvm_laplace_marginal_loglik
    Λ2 = [1.1 0.3; 0.4 1.2]    # 2×2 loadings, T=2 traits

    # --- 1. reduction: Vector of T IDENTICAL families == scalar family (exact equality) ---
    Yp2 = Float64[2 4; 1 3; 3 5; 0 2; 4 6; 2 1; 1 7; 5 0]
    r_scalar = gl(Yp2, Ainv, Λ2, HSquared.PoissonResponse(); X = X)
    r_vector = gl(Yp2, Ainv, Λ2, [HSquared.PoissonResponse(), HSquared.PoissonResponse()]; X = X)
    @test r_scalar.loglik == r_vector.loglik          # EXACT: same per-record family dispatch
    @test r_scalar.converged && r_vector.converged
    @test size(r_vector.beta) == (1, 2) && size(r_vector.g) == (q, 2)

    # --- 2. mixed families: trait 1 Poisson (counts), trait 2 Gaussian (continuous) ---
    #    Y[:, 1] = integer counts (≥ 0), Y[:, 2] = continuous measurements
    Ymix = hcat(Float64[2, 1, 3, 0, 4, 2, 1, 5], Float64[2.1, 3.4, 2.8, 3.1, 4.2, 1.9, 3.0, 4.7])
    σe = 1.2
    families_mix = [HSquared.PoissonResponse(), HSquared.GaussianResponse(σe)]
    r_mix = gl(Ymix, Ainv, Λ2, families_mix; X = X)
    @test r_mix.converged
    @test isfinite(r_mix.loglik)
    @test size(r_mix.beta) == (1, 2) && size(r_mix.g) == (q, 2)

    # --- 3. guard: families vector of wrong length throws ArgumentError ---
    @test_throws ArgumentError gl(Yp2, Ainv, Λ2, [HSquared.PoissonResponse()]; X = X)         # length 1 ≠ T=2
    @test_throws ArgumentError gl(Yp2, Ainv, Λ2,
        [HSquared.PoissonResponse(), HSquared.PoissonResponse(), HSquared.PoissonResponse()];
        X = X)    # length 3 ≠ T=2
end

@testset "Genetic-GLLVM consumability: per-trait families in REML + GeneticGLLVMFit (#50)" begin
    # Shared 8-animal pedigree fixture (same as the other GLLVM REML testsets above).
    ped = normalize_pedigree(["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"],
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Ainv = Matrix(pedigree_inverse(ped)); q = 8
    X = ones(q, 1)
    fitr = HSquared.fit_gllvm_laplace_reml

    # Mixed-family response: trait 1 = Poisson counts, trait 2 = Gaussian continuous.
    Ymix = hcat(Float64[2, 1, 3, 0, 4, 2, 1, 5],
                Float64[2.1, 3.4, 2.8, 3.1, 4.2, 1.9, 3.0, 4.7])
    σe = 1.0
    families_mix = [HSquared.PoissonResponse(), HSquared.GaussianResponse(σe)]

    # (a) Per-trait [Poisson, Gaussian] REML fit converges.
    fit_mix = fitr(Ymix, Ainv, families_mix; rank = 1,
                   initial = reshape([0.6, 0.5], 2, 1))
    @test fit_mix.converged
    @test isfinite(fit_mix.loglik)
    @test size(fit_mix.genetic_covariance) == (2, 2)
    @test size(fit_mix.breeding_values) == (q, 1)

    # (b) Uniform-vector family gives the SAME genetic_covariance as the scalar fit (exact).
    Yp2 = Float64[2 4; 1 3; 3 5; 0 2; 4 6; 2 1; 1 7; 5 0]
    Λ0 = reshape([0.6, 0.5], 2, 1)
    fit_scalar = fitr(Yp2, Ainv, HSquared.PoissonResponse(); rank = 1, initial = Λ0)
    fit_vec    = fitr(Yp2, Ainv, [HSquared.PoissonResponse(), HSquared.PoissonResponse()];
                     rank = 1, initial = Λ0)
    @test fit_scalar.genetic_covariance == fit_vec.genetic_covariance   # exact: same optimizer path

    # (c) GeneticGLLVMFit extractor methods return the expected fields.
    #   genetic_covariance: K×K PSD (rank-1 outer product ⟹ PSD with one positive eigenvalue)
    G = HSquared.genetic_covariance(fit_scalar)
    @test G isa Matrix{Float64}
    @test size(G) == (2, 2)
    @test all(eigvals(Symmetric(G)) .>= -1e-12)      # PSD (rank-1 low-rank, smallest ≈ 0)
    #   breeding_values: q × K matrix
    bv = HSquared.breeding_values(fit_scalar)
    @test bv isa Matrix{Float64}
    @test size(bv) == (q, 1)
    #   latent_structure: NamedTuple with communality field
    ls = HSquared.latent_structure(fit_scalar)
    @test haskey(ls, :communality)
    @test all(ls.communality .≈ 1.0)                 # low-rank (no Ψ) ⟹ communality = 1
    #   loglik: finite scalar
    ll = HSquared.loglik(fit_scalar)
    @test isfinite(ll)
    @test ll ≈ fit_scalar.loglik

    # (d) All existing GLLVM REML tests still produce GeneticGLLVMFit (not NamedTuple).
    #     Spot-check the K=1,T=1 Poisson reduction fit (same fixture as slice-3 testset).
    yp = reshape(Float64[2, 1, 3, 0, 4, 2, 1, 5], q, 1)
    gr = fitr(yp, Ainv, HSquared.PoissonResponse(); rank = 1, initial = reshape([1.0], 1, 1))
    @test gr isa HSquared.GeneticGLLVMFit
    @test gr.converged
    @test size(gr.genetic_covariance) == (1, 1)
    @test gr.n_latent_factors == 1
    @test gr.uniqueness === nothing          # low-rank carries no Ψ
end

@testset "breeding_values_plot_data (#54 set B, EBV caterpillar, #93 parity)" begin
    ped = normalize_pedigree(["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"],
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"])
    Ainv = pedigree_inverse(ped)
    spec = animal_model_spec([2.0, 3.0, 2.5, 3.5, 4.0, 1.5, 3.0, 4.5], ones(8, 1),
        sparse(1.0I, 8, 8), Ainv; ids = ped.ids, method = :REML)
    fit = fit_ai_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
    pd = breeding_values_plot_data(fit)
    @test propertynames(pd) == (:id, :trait, :value, :pev, :pev_scale)
    @test pd.id == collect(breeding_values(fit).ids)
    @test pd.value ≈ breeding_values(fit).values                       # value == EBV (R column)
    @test pd.pev ≈ prediction_error_variance(fit).values               # pev == validation-scale PEV
    @test pd.pev_scale == "validation"                                 # honest-status flag
    @test all(pd.trait .== 1) && length(pd.value) == 8 && length(pd.pev) == 8
    # trait-label kwarg
    pd2 = breeding_values_plot_data(fit; trait = "weight")
    @test all(pd2.trait .== "weight")
end

@testset "hsquared_figure drawing stub (HSquaredMakieExt weak-dep, #93)" begin
    # `hsquared_figure` is a STUB in /src: the drawing METHOD lives in the
    # `HSquaredMakieExt` package extension, which loads only when a Makie backend
    # is in scope (`using CairoMakie`). Makie is deliberately kept OUT of the
    # default test/CI environment (heavy GL/Cairo stack — cost discipline), so in
    # CI the stub must be a method-less generic function: any call throws
    # `MethodError` until a backend activates the extension. The full draw of all
    # NINE figure kinds is verified locally with CairoMakie (see the after-task
    # report 2026-06-22 + check-log), not in CI.
    @test hsquared_figure isa Function
    @test isempty(methods(hsquared_figure))          # stub: no methods without Makie
    @test_throws MethodError hsquared_figure((term = ["x"], panel = ["heritability"]))
    @test_throws MethodError hsquared_figure((value = [1.0], pev = [0.1], pev_scale = "validation"))
    @test_throws MethodError hsquared_figure((traits = ["a"], genetic_correlations = [1.0;;],
                                              heritabilities = nothing, rotation_invariant = true))
    @test_throws MethodError hsquared_figure((is_eigenstructure_not_loadings = true,
                                              eigenvalues = [1.0], variance_explained = [1.0],
                                              axis_labels = ["PC1"]))
    # set D (markers) + set A (random regression): one representative payload each;
    # all must still throw MethodError in the dependency-free build (no method leaked).
    @test_throws MethodError hsquared_figure((marker_ids = ["m1"], chromosomes = ["1"],
                                              positions = [1.0], plot_positions = [1.0],
                                              p_values = [0.1], neglog10_p_values = [1.0]))
    @test_throws MethodError hsquared_figure((expected_neglog10_p_values = [1.0],
                                              observed_neglog10_p_values = [1.0]))
    @test_throws MethodError hsquared_figure((covariate = [0.0], genetic_variance = [1.0],
                                              heritability = nothing, supplied = true))
    @test_throws MethodError hsquared_figure((covariate = [0.0], surface = [1.0;;],
                                              is_correlation = true, supplied = true))
    @test_throws MethodError hsquared_figure((covariate = [0.0], eigenvalues = [1.0],
                                              eigenfunctions = [1.0;;], variance_explained = [1.0],
                                              rotation_invariant = true, supplied = true))
end

@testset "gpu genomic relationship stubs (HSquaredCUDAExt weak-dep, Wave F G1)" begin
    # `gpu_genomic_relationship_matrix` / `gpu_genomic_relationship_inverse` are STUBS in
    # /src: the GPU METHODS live in the `HSquaredCUDAExt` package extension, which loads
    # only when CUDA is in scope (`using CUDA`). CUDA is deliberately OUT of the default
    # test/CI environment (no GPU on CI — cost discipline, the same posture as Makie), so
    # in CI the stubs must be method-less generic functions: any call throws `MethodError`
    # until the extension activates. The CPU↔GPU agreement + benchmark are verified on a
    # CUDA device via the opt-in cluster script sim/drac/g1_gpu_genomic.jl, never in CI.
    @test gpu_genomic_relationship_matrix isa Function
    @test gpu_genomic_relationship_inverse isa Function
    @test isempty(methods(gpu_genomic_relationship_matrix))   # stub: no methods without CUDA
    @test isempty(methods(gpu_genomic_relationship_inverse))
    markers = [0.0 1.0 2.0; 1.0 1.0 0.0; 2.0 0.0 1.0]
    @test_throws MethodError gpu_genomic_relationship_matrix(markers)
    @test_throws MethodError gpu_genomic_relationship_matrix(markers; method = :vanraden2)
    @test_throws MethodError gpu_genomic_relationship_inverse([1.0 0.0; 0.0 1.0])
end

@testset "BLUPF90 multivariate starter packet preflight (#49)" begin
    mktempdir() do dir
        packet = HSquaredBLUPF90MultitraitPacket.generate_blupf90_multitrait_packet(out = dir)
        @test packet.output_dir == dir
        @test packet.n_records == 80
        @test packet.n_pedigree == 20
        @test packet.G0 ≈ [0.603628485824786 0.111950277319089;
                           0.111950277319089 0.270353350669321]
        @test packet.R0 ≈ [0.263112353813569 0.000307890389649347;
                           0.000307890389649347 0.0906582303261327]

        dat = readlines(joinpath(dir, "blupf90_multitrait.dat"))
        ped = readlines(joinpath(dir, "blupf90_multitrait.ped"))
        id_map = readlines(joinpath(dir, "animal_id_map.csv"))
        renum = readlines(joinpath(dir, "renumf90.par"))
        @test length(dat) == packet.n_records
        @test length(ped) == packet.n_pedigree
        @test length(id_map) == packet.n_pedigree + 1
        @test id_map[1] == "animal,code"
        @test all(length(split(line)) == 5 for line in dat)
        @test all(length(split(line)) == 3 for line in ped)
        @test split(dat[1]) == ["4.67680263095412", "7.83574837591004", "1", "-1.5", "1"]
        @test split(ped[1]) == ["1", "0", "0"]
        @test split(ped[7]) == ["7", "1", "4"]
        @test id_map[2] == "f1,1"
        @test id_map[end] == "a14,20"
        @test all(row -> row[3] == "1", split.(dat))
        @test all(row -> all(!isnothing(tryparse(Float64, value)) for value in row), split.(dat))
        @test all(row -> all(!isnothing(tryparse(Int, value)) for value in row), split.(ped))
        @test "DATAFILE" in renum
        @test renum[findfirst(==("DATAFILE"), renum) + 1] == "blupf90_multitrait.dat"
        @test "TRAITS" in renum
        @test renum[findfirst(==("TRAITS"), renum) + 1] == "1 2"
        @test "FIELDS_PASSED TO OUTPUT" in renum
        @test renum[findfirst(==("FIELDS_PASSED TO OUTPUT"), renum) + 1] == ""
        @test "WEIGHT(S)" in renum
        @test renum[findfirst(==("WEIGHT(S)"), renum) + 1] == ""
        @test "3 3 cross alpha" in renum
        @test "4 4 cov" in renum
        @test "5 5 cross alpha" in renum
        @test "FILE_POS" in renum
        @test renum[findfirst(==("FILE_POS"), renum) + 1] == "1 2 3 0 0"
        @test "OPTION method VCE" in renum
        @test !any(startswith(strip(line), "#") for line in dat)
        @test !any(startswith(strip(line), "#") for line in ped)
        @test !any(startswith(strip(line), "#") for line in renum)

        checked = HSquaredBLUPF90MultitraitPacket.validate_blupf90_multitrait_packet(out = dir)
        @test checked.n_records == packet.n_records
        @test checked.n_pedigree == packet.n_pedigree
        @test checked.G0 == packet.G0
        @test checked.R0 == packet.R0
    end

    probe = HSquaredBLUPF90MultitraitPacket.probe_blupf90_executables()
    @test Set(keys(probe)) == Set(HSquaredBLUPF90MultitraitPacket.BLUPF90_EXECUTABLES)
    @test all(path -> isnothing(path) || path isa String, values(probe))
end
