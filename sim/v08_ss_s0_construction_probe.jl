# v0.8 S0 — single-step H-inverse construction probe
# OPT-IN, OUT of CI. Does NOT flip V2-SSHINV. Not a Mrode Ch.11 anchor.
# Not an AGHmatrix / preGSf90 comparator run (neither is provisioned here).
#
# Dumps a tiny half-sib H^{-1} plus the G = A22 reduction residual so a later
# AGHmatrix::Hmatrix / Mrode Ch.11 leg has a pinned fixture. Construction
# identities already live in `test/runtests.jl`; this script only serializes
# a reviewable table.
#
# Run from the repository root:
#   env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
#     julia --project=. sim/v08_ss_s0_construction_probe.jl

using Dates
using HSquared
using LinearAlgebra
using Printf

function _tiny_pedigree()
    ids = ["s1", "d1", "d2", "o1", "o2", "o3"]
    sire = ["0", "0", "0", "s1", "s1", "s1"]
    dam = ["0", "0", "0", "d1", "d1", "d2"]
    return normalize_pedigree(ids, sire, dam)
end

function main()
    ped = _tiny_pedigree()
    Ainv = Matrix(pedigree_inverse(ped))
    A = Matrix(additive_relationship(ped))
    g = [4, 5, 6]  # three offspring treated as genotyped
    A22 = A[g, g]
    Hinv_reduce = single_step_inverse(Ainv, A, A22, g)
    reduce_resid = maximum(abs.(Hinv_reduce .- Ainv))
    Gslight = A22 + 0.05I
    Hinv_shift = single_step_inverse(Ainv, A, Gslight, g; ridge = 1e-8)
    println("# HSquared.jl v0.8 S0 single-step construction probe  $(Dates.now())")
    println("# host=$(gethostname())  julia=$(VERSION)")
    println("# NOT a covered flip. NOT Mrode Ch.11. NOT AGHmatrix parity.")
    println("# animals=$(length(ped.ids)) genotyped_rows=$(g)")
    @printf("# G=A22 reduction max|Hinv-Ainv|=%.3e (expect ~0)\n", reduce_resid)
    @printf("# G=A22+0.05I  max|Hinv_shift-Ainv|=%.3e (expect >0)\n",
            maximum(abs.(Hinv_shift .- Ainv)))
    println("i\tj\tAinv\tHinv_GeqA22\tHinv_Gshift")
    n = size(Ainv, 1)
    for i in 1:n, j in i:n
        @printf("%d\t%d\t%.8f\t%.8f\t%.8f\n",
                i, j, Ainv[i, j], Hinv_reduce[i, j], Hinv_shift[i, j])
    end
    reduce_resid <= 1e-10 || exit(1)
    return nothing
end

main()
