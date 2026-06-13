"""
    Phase0NotImplementedError(operation)

Error thrown by public Phase 0 placeholders.
"""
struct Phase0NotImplementedError <: Exception
    operation::String
end

function Base.showerror(io::IO, err::Phase0NotImplementedError)
    print(
        io,
        err.operation,
        " is a Phase 0 scaffold in HSquared.jl. ",
        "Model fitting is planned but not implemented yet; see ROADMAP.md and ",
        "docs/design/capability-status.md for the current boundary.",
    )
end

function _phase0_not_implemented(operation::AbstractString)
    throw(Phase0NotImplementedError(String(operation)))
end
