# Write the known-truth Y used by test_multivariate_repeatability.jl.
# Run on Julia 1.10 (the stream that originally recovered G0/P0):
#   julia +1.10 --project=. test/fixtures/hs237_mv_pe_recovery/generate.jl
#
# Julia 1.13 changed both randn() and MersenneTwister(Int) uniforms, so a
# live seed is not a pin. Do not regenerate on a newer Julia.

using DelimitedFiles
using HSquared
using LinearAlgebra
using Random

function _hs237_halfsib(nsire, ndam, noffspring)
    sire_ids = ["s$i" for i in 1:nsire]
    dam_ids = ["d$i" for i in 1:ndam]
    off_ids = ["o$i" for i in 1:noffspring]
    ids = vcat(sire_ids, dam_ids, off_ids)
    sire = vcat(
        fill("0", nsire + ndam),
        [sire_ids[((i - 1) % nsire) + 1] for i in 1:noffspring],
    )
    dam = vcat(
        fill("0", nsire + ndam),
        [dam_ids[((i - 1) % ndam) + 1] for i in 1:noffspring],
    )
    return normalize_pedigree(ids, sire, dam)
end

function _write_fixture()
    VERSION.major == 1 && VERSION.minor == 10 ||
        error("regenerate only on Julia 1.10; this Julia is ", VERSION)

    G0 = [1.00 0.30; 0.30 0.80]
    P0 = [0.50 0.10; 0.10 0.40]
    R0 = [0.80 0.15; 0.15 0.70]
    rng = Random.MersenneTwister(20260926)
    ped = _hs237_halfsib(8, 16, 48)
    Ainv = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    q = length(ped.ids)
    U = cholesky(Symmetric(A)).L * randn(rng, q, 2) * transpose(cholesky(Symmetric(G0)).L)
    PE = randn(rng, q, 2) * transpose(cholesky(Symmetric(P0)).L)
    records = 4
    n = q * records
    Y = zeros(n, 2)
    row = 1
    for animal in 1:q, _rep in 1:records
        Y[row, :] .= 2.0 .+ U[animal, :] .+ PE[animal, :] .+
                     (randn(rng, 1, 2) * transpose(cholesky(Symmetric(R0)).L))[1, :]
        row += 1
    end

    out = joinpath(@__DIR__, "Y.csv")
    open(out, "w") do io
        println(io, "y1,y2")
        for i in 1:n
            println(io, Y[i, 1], ",", Y[i, 2])
        end
    end
    println("wrote ", out)
    println("Y11 ", Y[1, 1], " Ysum ", sum(Y), " nrows ", n)
    return Y
end

_write_fixture()
