abstract type AbstractBackend end

"""
    CPUBackend()

Select the trusted CPU execution path.

The CPU backend is the only always-available backend. Phase 1 records the
backend choice only; it does not route production fitting through a backend
dispatcher yet.
"""
struct CPUBackend <: AbstractBackend end

"""
    ThreadsBackend()

Select the planned multi-threaded CPU execution path.

This is metadata only. No threaded execution path is implemented yet.
"""
struct ThreadsBackend <: AbstractBackend end

"""
    CUDABackend()

Select the planned CUDA execution path.

CUDA is not a dependency and no GPU work is executed yet.
"""
struct CUDABackend <: AbstractBackend end

"""
    AMDGPUBackend()

Select the planned AMDGPU/ROCm execution path.

AMDGPU.jl is not a dependency and no GPU work is executed yet.
"""
struct AMDGPUBackend <: AbstractBackend end

"""
    MetalBackend()

Select the planned Apple Metal execution path.

Metal.jl is not a dependency and no GPU work is executed yet.
"""
struct MetalBackend <: AbstractBackend end

"""
    OneAPIBackend()

Select the planned Intel oneAPI execution path.

oneAPI.jl is not a dependency and no accelerator work is executed yet.
"""
struct OneAPIBackend <: AbstractBackend end

"""
    AutoBackend()

Let `HSquared.jl` choose an execution backend in a future implementation.

Until backend dispatch exists, `AutoBackend()` is control metadata only. CPU is
the trusted fallback.
"""
struct AutoBackend <: AbstractBackend end

const BACKEND_SYMBOLS = (:auto, :cpu, :threads, :cuda, :amdgpu, :metal, :oneapi)

const BACKEND_ERROR = "backend must be :auto, :cpu, :threads, :cuda, :amdgpu, :metal, :oneapi, or an HSquared backend object"

_backend_from_symbol(::Val{:auto}) = AutoBackend()
_backend_from_symbol(::Val{:cpu}) = CPUBackend()
_backend_from_symbol(::Val{:threads}) = ThreadsBackend()
_backend_from_symbol(::Val{:cuda}) = CUDABackend()
_backend_from_symbol(::Val{:amdgpu}) = AMDGPUBackend()
_backend_from_symbol(::Val{:metal}) = MetalBackend()
_backend_from_symbol(::Val{:oneapi}) = OneAPIBackend()

function _coerce_backend(backend::AbstractBackend)
    return backend
end

function _coerce_backend(backend::Symbol)
    if backend in BACKEND_SYMBOLS
        return _backend_from_symbol(Val(backend))
    end

    throw(ArgumentError(BACKEND_ERROR))
end

function _coerce_backend(backend::AbstractString)
    return _coerce_backend(Symbol(lowercase(backend)))
end

function _coerce_backend(backend)
    throw(ArgumentError(BACKEND_ERROR))
end
