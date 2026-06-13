"""
    sparse_csc_matrix(nrow, ncol, colptr, rowval, nzval; index_base = :zero)

Construct a Julia `SparseMatrixCSC{Float64,Int}` from compressed sparse column
slots.

This is a bridge utility for R `Matrix::dgCMatrix` payloads. R stores column
pointers and row indices with zero-based indexing, so `index_base = :zero` is
the default. Use `index_base = :one` for Julia-style CSC slots.
"""
function sparse_csc_matrix(
    nrow::Integer,
    ncol::Integer,
    colptr,
    rowval,
    nzval;
    index_base = :zero,
)
    nrow > 0 || throw(ArgumentError("nrow must be positive"))
    ncol > 0 || throw(ArgumentError("ncol must be positive"))

    raw_colptr = Int.(collect(colptr))
    raw_rowval = Int.(collect(rowval))
    values = Float64.(collect(nzval))

    length(raw_colptr) == ncol + 1 ||
        throw(ArgumentError("colptr length must equal ncol + 1"))
    length(raw_rowval) == length(values) ||
        throw(ArgumentError("rowval and nzval must have the same length"))

    base = _coerce_index_base(index_base)
    julia_colptr, julia_rowval = if base == :zero
        raw_colptr .+ 1, raw_rowval .+ 1
    else
        raw_colptr, raw_rowval
    end

    nnz = length(values)
    first(julia_colptr) == 1 ||
        throw(ArgumentError("colptr must start at 0 for zero-based input or 1 for one-based input"))
    last(julia_colptr) == nnz + 1 ||
        throw(ArgumentError("last colptr entry must equal nnz + index offset"))

    for k in 1:(length(julia_colptr) - 1)
        julia_colptr[k] <= julia_colptr[k + 1] ||
            throw(ArgumentError("colptr must be nondecreasing"))
    end

    for row in julia_rowval
        1 <= row <= nrow ||
            throw(ArgumentError("row indices must be within matrix dimensions"))
    end

    _check_csc_row_order(julia_colptr, julia_rowval)

    return SparseMatrixCSC(Int(nrow), Int(ncol), julia_colptr, julia_rowval, values)
end

function _coerce_index_base(index_base::Symbol)
    normalized = Symbol(lowercase(String(index_base)))
    normalized in (:zero, :r) && return :zero
    normalized in (:one, :julia) && return :one
    throw(ArgumentError("index_base must be :zero, :r, :one, or :julia"))
end

function _coerce_index_base(index_base::AbstractString)
    return _coerce_index_base(Symbol(index_base))
end

function _coerce_index_base(index_base)
    throw(ArgumentError("index_base must be a Symbol or string"))
end

function _check_csc_row_order(colptr::Vector{Int}, rowval::Vector{Int})
    for col in 1:(length(colptr) - 1)
        start = colptr[col]
        stop = colptr[col + 1] - 1
        previous = 0
        for ptr in start:stop
            row = rowval[ptr]
            row > previous ||
                throw(ArgumentError("row indices must be strictly increasing within each CSC column"))
            previous = row
        end
    end
    return nothing
end
