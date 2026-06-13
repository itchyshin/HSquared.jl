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

const BACKEND_INFO_SYMBOLS = (:cpu, :threads, :cuda, :amdgpu, :metal, :oneapi)

const BACKEND_INFO_ACCELERATORS = Dict(
    :cpu => :none,
    :threads => :none,
    :cuda => :cuda,
    :amdgpu => :amdgpu,
    :metal => :metal,
    :oneapi => :oneapi,
)

"""
    BackendInfoRow

Typed status row returned by [`backend_info`](@ref).

Rows describe accepted backend names and whether a backend is execution-ready.
In Phase 1 all rows are selectable control metadata with
`execution_available == false` and `status == :planned`.
"""
struct BackendInfoRow
    backend::Symbol
    accelerator::Symbol
    requested::Bool
    selectable::Bool
    execution_available::Bool
    status::Symbol
    note::String
end

"""
    BackendInfo

Container returned by [`backend_info`](@ref).
"""
struct BackendInfo{TC}
    control::TC
    rows::Vector{BackendInfoRow}
end

Base.length(info::BackendInfo) = length(info.rows)
Base.getindex(info::BackendInfo, index::Int) = info.rows[index]
Base.iterate(info::BackendInfo, state...) = iterate(info.rows, state...)

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

_backend_symbol(::AutoBackend) = :auto
_backend_symbol(::CPUBackend) = :cpu
_backend_symbol(::ThreadsBackend) = :threads
_backend_symbol(::CUDABackend) = :cuda
_backend_symbol(::AMDGPUBackend) = :amdgpu
_backend_symbol(::MetalBackend) = :metal
_backend_symbol(::OneAPIBackend) = :oneapi

function _backend_note(backend::Symbol)
    backend == :cpu && return "Trusted default target; production backend dispatch is not implemented yet."
    backend == :threads && return "Planned multi-threaded CPU control; execution dispatch is not implemented yet."
    backend == :metal && return "Planned Apple/Mac accelerator control; execution dispatch is not implemented yet."
    return "Accepted by HSControl; execution dispatch is planned."
end

function _backend_requested(backend::Symbol, control)
    requested_backend = _backend_symbol(control.backend)
    requested_accelerator = control.accelerator

    return backend == requested_backend ||
           backend == requested_accelerator ||
           (requested_accelerator == :gpu && backend in (:cuda, :amdgpu, :metal, :oneapi))
end
