module HSquared

using LinearAlgebra
using Optim
using SparseArrays

export AMDGPUBackend,
    AutoBackend,
    AnimalModelFit,
    AnimalModelSpec,
    BackendInfo,
    BackendInfoRow,
    BreedingValues,
    CPUBackend,
    CUDABackend,
    GaussianFamily,
    GaussianLikelihoodResult,
    HendersonMMEResult,
    HSControl,
    HSData,
    HSDataIDMap,
    MetalBackend,
    OneAPIBackend,
    Pedigree,
    Phase0NotImplementedError,
    ThreadsBackend,
    animal_model_spec,
    backend_info,
    breeding_values,
    fit_animal_model,
    fit_variance_components,
    fitted_values,
    fixed_effects,
    gaussian_loglik,
    genomic,
    henderson_mme,
    heritability,
    hsquared,
    id_map,
    inbreeding_coefficients,
    marker_scan,
    markers,
    normalize_pedigree,
    pedigree_inverse,
    planned_model_terms,
    prediction_error_variance,
    qtl_scan,
    reliability,
    result_payload,
    single_step,
    sparse_reml_loglik,
    sparse_csc_matrix,
    variance_components

include("backends.jl")
include("control.jl")
include("errors.jl")
include("pedigree.jl")
include("data.jl")
include("sparse_bridge.jl")
include("model_spec.jl")
include("likelihood.jl")
include("planned_terms.jl")
include("placeholders.jl")

end
