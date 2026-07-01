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

# --- B2: covariance param list generalizes; t=2 names unchanged; no closure capture bug ---
p2 = _covariance_params(2)
check(length(p2) == 6, "t=2 must give 6 params, got $(length(p2))")
check(p2[1][1] == "G[1,1]" && p2[3][1] == "G[2,2]" && p2[4][1] == "R[1,1]",
      "t=2 param names/order changed")
p3 = _covariance_params(3)
check(length(p3) == 12, "t=3 must give 12 params (6 G + 6 R), got $(length(p3))")
# closure-capture check: each getter must read its OWN (i,j), not the last loop value
mock = (genetic_covariance = [10.0 11.0 12.0; 11.0 20.0 22.0; 12.0 22.0 30.0],
        gtrue = zeros(3, 3),
        residual_covariance = [40.0 0.0 0.0; 0.0 50.0 0.0; 0.0 0.0 60.0], rtrue = zeros(3, 3))
check(p3[1][2](mock) == 10.0 && p3[2][2](mock) == 11.0 && p3[6][2](mock) == 30.0,
      "closure capture bug: G getters do not read their own indices")

# --- B3: --traits=3 builds a 3×3 PD truth; t=2 default byte-identical ---
p3p = _parse_args(["--traits=3"])
check(size(p3p.g0) == (3, 3), "traits=3 must build a 3×3 G0, got $(size(p3p.g0))")
check(isposdef(Symmetric(p3p.g0)) && isposdef(Symmetric(p3p.r0)),
      "default 3-trait G0/R0 must be PD")
p2p = _parse_args(String[])
check(size(p2p.g0) == (2, 2) && p2p.g0 == [1.0 0.35; 0.35 0.7],
      "default t=2 truth must be byte-identical")

isempty(failures) || (foreach(println, failures); error("SELFTEST FAILED ($(length(failures)))"))
println("SELFTEST PASSED")
