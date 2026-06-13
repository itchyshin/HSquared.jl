module HSquared

using LinearAlgebra
using SparseArrays

export AutoBackend,
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
