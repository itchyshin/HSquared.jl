abstract type AbstractBackend end

"""
    CPUBackend()

Select the planned CPU execution path.

Phase 0 records the backend choice only. Fitting and sparse solvers are not
implemented yet.
"""
struct CPUBackend <: AbstractBackend end

"""
    CUDABackend()

Select the planned CUDA execution path.

Phase 0 records the backend choice only. CUDA is not a dependency and no GPU
work is executed yet.
"""
struct CUDABackend <: AbstractBackend end

"""
    AutoBackend()

Let `HSquared.jl` choose an execution backend in a future implementation.
"""
struct AutoBackend <: AbstractBackend end

_backend_from_symbol(::Val{:cpu}) = CPUBackend()
_backend_from_symbol(::Val{:cuda}) = CUDABackend()
_backend_from_symbol(::Val{:auto}) = AutoBackend()

function _coerce_backend(backend::AbstractBackend)
    return backend
end

function _coerce_backend(backend::Symbol)
    if backend in (:cpu, :cuda, :auto)
        return _backend_from_symbol(Val(backend))
    end

    throw(ArgumentError("backend must be :auto, :cpu, :cuda, or an HSquared backend object"))
end

function _coerce_backend(backend::AbstractString)
    return _coerce_backend(Symbol(lowercase(backend)))
end

function _coerce_backend(backend)
    throw(ArgumentError("backend must be :auto, :cpu, :cuda, or an HSquared backend object"))
end
