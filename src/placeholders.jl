"""
    hsquared(args...; kwargs...)

Planned high-level Julia entry point for inheritance-aware quantitative-genetic
models.

This function is intentionally not implemented in Phase 0.
"""
function hsquared(args...; kwargs...)
    return _phase0_not_implemented("hsquared()")
end

"""
    fit_animal_model(...)

Fit a Gaussian animal model through one of the supported Phase 1 engine methods.
Implemented overloads accept an `AnimalModelSpec` or `y, X, Z, Ainv`. Targets
include `:variance_components`, `:sparse_reml`, `:ai_reml`, and `:henderson_mme`;
see the method-specific documentation for their arguments and limits.

Unsupported call shapes reach the fail-closed fallback and throw
`Phase0NotImplementedError`.
"""
function fit_animal_model(args...; kwargs...)
    return _phase0_not_implemented("fit_animal_model()")
end
