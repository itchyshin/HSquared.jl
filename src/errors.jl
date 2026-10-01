"""
    Phase0NotImplementedError(operation)

Legacy error type for public placeholders and unwired payload routes.
"""
struct Phase0NotImplementedError <: Exception
    operation::String
end

function Base.showerror(io::IO, err::Phase0NotImplementedError)
    print(
        io,
        err.operation,
        " is not implemented on this route in HSquared.jl. ",
        "Other model-fitting routes exist; see docs/design/capability-status.md ",
        "for the current boundary.",
    )
end

function _phase0_not_implemented(operation::AbstractString)
    throw(Phase0NotImplementedError(String(operation)))
end
