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

# --- A2: --design parses; default is half-sib (back-compat) ---
p_default = _parse_args(String[])
check(p_default.design == "halfsib", "default design must be halfsib, got $(p_default.design)")
p_fs = _parse_args(["--design=fullsib", "--npair=20", "--noffspring-per-pair=2"])
check(p_fs.design == "fullsib", "design=fullsib must parse")

# --- B1: t read from G0 dimension; t=2 path unchanged ---
# NOTE: positional field order must match struct MultivariateRecoveryConfig (Task A2).
cfg2 = MultivariateRecoveryConfig(20260616, 8, 16, 56, 3, 50, 0.25, 0.20, true,
            [1.0 0.35; 0.35 0.7], [0.8 0.2; 0.2 0.55], "selftest", true, 1.0e6,
            "halfsib", 20, 2)
Y2, X2, Z2, Ainv2, G2, R2, U2 = _simulate_repeated_records(cfg2)
check(size(Y2, 2) == 2, "t=2 sim must yield 2 trait columns")
check(size(U2, 2) == 2, "t=2 breeding values must have 2 columns")

isempty(failures) || (foreach(println, failures); error("SELFTEST FAILED ($(length(failures)))"))
println("SELFTEST PASSED")
