"""
    HSControl(; backend = AutoBackend(), accelerator = :auto, precision = Float64,
              save = :minimal, save_fitted = false, save_residuals = false,
              save_design = false, save_factorization = false,
              disk_cache = false)

Store planned engine controls for future `HSquared.jl` model calls.

Phase 1 validates and records these controls so the R and Julia twins can agree
on names before production backend dispatch exists. CPU is the trusted
always-available path; accelerator names are future optional-extension
metadata.
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

    normalized_accelerator in ACCELERATOR_SYMBOLS ||
        throw(
            ArgumentError(
                "accelerator must be :auto, :none, :gpu, :cuda, :amdgpu, :metal, or :oneapi",
            ),
        )
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

"""
    backend_info(control = HSControl())

Return typed status rows for planned compute backends.

The rows mirror the R twin's `backend_info()` shape: `backend`,
`accelerator`, `requested`, `selectable`, `execution_available`, `status`, and
`note`. In Phase 1 all rows are accepted control metadata, all have
`execution_available == false`, and all have `status == :planned`.
"""
function backend_info(control::HSControl = HSControl())
    rows = [
        BackendInfoRow(
            backend,
            BACKEND_INFO_ACCELERATORS[backend],
            _backend_requested(backend, control),
            true,
            false,
            :planned,
            _backend_note(backend),
        ) for backend in BACKEND_INFO_SYMBOLS
    ]

    return BackendInfo(control, rows)
end

function backend_info(control)
    throw(ArgumentError("control must be an HSControl object"))
end

const ACCELERATOR_SYMBOLS = (:auto, :none, :gpu, :cuda, :amdgpu, :metal, :oneapi)

function _coerce_symbol(value::Symbol, name::Symbol)
    return value
end

function _coerce_symbol(value::AbstractString, name::Symbol)
    return Symbol(lowercase(value))
end

function _coerce_symbol(value, name::Symbol)
    throw(ArgumentError("$(name) must be a Symbol or string"))
end
