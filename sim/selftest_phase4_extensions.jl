# RNG-free deterministic self-test for the phase4 MV recovery harness extensions.
# Kept outside test/ so the package suite stays RNG-free; this file exercises only
# deterministic harness internals (pedigree shape, arg parsing, param-list generation).
#
# Run: julia --project=. sim/selftest_phase4_extensions.jl   (exit 0 = pass)
using HSquared, LinearAlgebra
include(joinpath(@__DIR__, "phase4_multivariate_reml_recovery.jl"))  # guarded main; brings helpers into scope

failures = String[]
check(cond, msg) = cond || push!(failures, msg)

# --- A1: full-sib pedigree structure ---
ped = _fullsib_pedigree(20, 2)            # 20 families × 2 offspring → 40 parents + 40 offspring
check(length(ped.ids) == 80, "fullsib q should be 80, got $(length(ped.ids))")
Ainv = pedigree_inverse(ped)              # must not throw
A = Matrix(inv(Symmetric(Matrix(Ainv))))
check(isposdef(Symmetric(A)), "A must be PD for a non-inbred full-sib pedigree")

isempty(failures) || (foreach(println, failures); error("SELFTEST FAILED ($(length(failures)))"))
println("SELFTEST PASSED")
