module HSquared

export AutoBackend,
    CPUBackend,
    CUDABackend,
    HSControl,
    Phase0NotImplementedError,
    fit_animal_model,
    hsquared

include("backends.jl")
include("control.jl")
include("errors.jl")
include("placeholders.jl")

end
