module HSquared

using LinearAlgebra
using Optim
using SparseArrays

export AMDGPUBackend,
    AutoBackend,
    AnimalModelFit,
    AnimalModelSpec,
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
    breeding_values,
    fit_animal_model,
    fit_variance_components,
    fitted_values,
    fixed_effects,
    gaussian_loglik,
    henderson_mme,
    heritability,
    hsquared,
    id_map,
    inbreeding_coefficients,
    normalize_pedigree,
    pedigree_inverse,
    prediction_error_variance,
    reliability,
    result_payload,
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
include("placeholders.jl")

end
