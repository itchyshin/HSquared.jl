"""
    GaussianFamily()

Marker for the Phase 1 Gaussian animal-model family.
"""
struct GaussianFamily end

"""
    AnimalModelSpec

Bridge-ready low-level specification for the first Gaussian animal-model
engine target.

The spec stores the response `y`, fixed-effect design `X`, animal-effect design
`Z`, sparse relationship precision `Ainv`, encoded animal `ids`, family marker,
and fitting `method`. It validates dimensions only; it does not fit a model.
"""
struct AnimalModelSpec{TY<:AbstractVector,TX<:AbstractMatrix,TZ<:AbstractMatrix,TQ<:AbstractMatrix,TID<:AbstractVector}
    y::TY
    X::TX
    Z::TZ
    Ainv::TQ
    ids::TID
    family::GaussianFamily
    method::Symbol
end

"""
    animal_model_spec(y, X, Z, Ainv; ids = nothing, family = GaussianFamily(),
                      method = :REML)

Validate and store the low-level inputs for the first Gaussian animal-model
engine target.

This function checks dimensions, ID length, family, and `method`. It is the
Julia-side mirror of the R parser contract, not a fitting routine.
"""
function animal_model_spec(
    y::AbstractVector,
    X::AbstractMatrix,
    Z::AbstractMatrix,
    Ainv::AbstractMatrix;
    ids = nothing,
    family = GaussianFamily(),
    method = :REML,
)
    normalized_method = _coerce_method(method)
    normalized_method in (:ML, :REML) ||
        throw(ArgumentError("method must be :ML or :REML"))

    family isa GaussianFamily ||
        throw(ArgumentError("family must be GaussianFamily() in Phase 1"))

    n = length(y)
    size(X, 1) == n ||
        throw(ArgumentError("X must have one row per response value"))
    size(Z, 1) == n ||
        throw(ArgumentError("Z must have one row per response value"))
    size(Ainv, 1) == size(Ainv, 2) ||
        throw(ArgumentError("Ainv must be square"))
    size(Z, 2) == size(Ainv, 1) ||
        throw(ArgumentError("Z columns must match Ainv dimensions"))

    encoded_ids = ids === nothing ? collect(1:size(Ainv, 1)) : collect(ids)
    length(encoded_ids) == size(Ainv, 1) ||
        throw(ArgumentError("ids length must match Ainv dimensions"))

    return AnimalModelSpec(y, X, Z, Ainv, encoded_ids, family, normalized_method)
end

function _coerce_method(method::Symbol)
    return Symbol(uppercase(String(method)))
end

function _coerce_method(method::AbstractString)
    return Symbol(uppercase(method))
end

function _coerce_method(method)
    throw(ArgumentError("method must be :ML, :REML, \"ML\", or \"REML\""))
end
