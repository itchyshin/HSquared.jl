module HSquared

using LinearAlgebra
using Optim
using SparseArrays

export AutoBackend,
    AnimalModelFit,
    AnimalModelSpec,
    BreedingValues,
    CPUBackend,
    CUDABackend,
    GaussianFamily,
    GaussianLikelihoodResult,
    HSControl,
    HSData,
    HSDataIDMap,
    Pedigree,
    Phase0NotImplementedError,
    animal_model_spec,
    breeding_values,
    fit_animal_model,
    fit_variance_components,
    fitted_values,
    fixed_effects,
    gaussian_loglik,
    heritability,
    hsquared,
    id_map,
    inbreeding_coefficients,
    normalize_pedigree,
    pedigree_inverse,
    result_payload,
    variance_components

include("backends.jl")
include("control.jl")
include("errors.jl")
include("pedigree.jl")
include("data.jl")
include("model_spec.jl")
include("likelihood.jl")
include("placeholders.jl")

end
