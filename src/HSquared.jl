module HSquared

using LinearAlgebra
using Optim
using SparseArrays

export AutoBackend,
    AnimalModelFit,
    AnimalModelSpec,
    CPUBackend,
    CUDABackend,
    GaussianFamily,
    GaussianLikelihoodResult,
    HSControl,
    Pedigree,
    Phase0NotImplementedError,
    animal_model_spec,
    fit_animal_model,
    fit_variance_components,
    gaussian_loglik,
    hsquared,
    inbreeding_coefficients,
    normalize_pedigree,
    pedigree_inverse

include("backends.jl")
include("control.jl")
include("errors.jl")
include("pedigree.jl")
include("model_spec.jl")
include("likelihood.jl")
include("placeholders.jl")

end
