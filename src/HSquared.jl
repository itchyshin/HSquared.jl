module HSquared

using SparseArrays

export AutoBackend,
    CPUBackend,
    CUDABackend,
    HSControl,
    Pedigree,
    Phase0NotImplementedError,
    fit_animal_model,
    hsquared,
    inbreeding_coefficients,
    normalize_pedigree,
    pedigree_inverse

include("backends.jl")
include("control.jl")
include("errors.jl")
include("pedigree.jl")
include("placeholders.jl")

end
