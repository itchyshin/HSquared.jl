module HSquared

using SparseArrays

export AutoBackend,
    AnimalModelSpec,
    CPUBackend,
    CUDABackend,
    GaussianFamily,
    HSControl,
    Pedigree,
    Phase0NotImplementedError,
    animal_model_spec,
    fit_animal_model,
    hsquared,
    inbreeding_coefficients,
    normalize_pedigree,
    pedigree_inverse

include("backends.jl")
include("control.jl")
include("errors.jl")
include("pedigree.jl")
include("model_spec.jl")
include("placeholders.jl")

end
