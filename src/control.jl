"""
    HSControl(; backend = AutoBackend(), accelerator = :auto, precision = Float64,
              save = :minimal, save_fitted = false, save_residuals = false,
              save_design = false, save_factorization = false,
              disk_cache = false)

Store planned engine controls for future `HSquared.jl` model calls.

Phase 0 validates and records these controls so the R and Julia twins can agree
on names before model fitting exists.
"""
struct HSControl
    backend::AbstractBackend
    accelerator::Symbol
    precision::DataType
    save::Symbol
    save_fitted::Bool
    save_residuals::Bool
    save_design::Bool
    save_factorization::Bool
    disk_cache::Bool
end

function HSControl(;
    backend = AutoBackend(),
    accelerator = :auto,
    precision = Float64,
    save = :minimal,
    save_fitted::Bool = false,
    save_residuals::Bool = false,
    save_design::Bool = false,
    save_factorization::Bool = false,
    disk_cache::Bool = false,
)
    normalized_backend = _coerce_backend(backend)
    normalized_accelerator = _coerce_symbol(accelerator, :accelerator)
    normalized_save = _coerce_symbol(save, :save)

    normalized_accelerator in (:auto, :none, :cuda) ||
        throw(ArgumentError("accelerator must be :auto, :none, or :cuda"))
    normalized_save in (:minimal, :full, :tiny) ||
        throw(ArgumentError("save must be :minimal, :full, or :tiny"))
    precision in (Float64, Float32) ||
        throw(ArgumentError("precision must be Float64 or Float32"))

    return HSControl(
        normalized_backend,
        normalized_accelerator,
        precision,
        normalized_save,
        save_fitted,
        save_residuals,
        save_design,
        save_factorization,
        disk_cache,
    )
end

function _coerce_symbol(value::Symbol, name::Symbol)
    return value
end

function _coerce_symbol(value::AbstractString, name::Symbol)
    return Symbol(lowercase(value))
end

function _coerce_symbol(value, name::Symbol)
    throw(ArgumentError("$(name) must be a Symbol or string"))
end
