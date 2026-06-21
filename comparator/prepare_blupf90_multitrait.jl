# Prepare an opt-in BLUPF90/RENUMF90 starter packet for the Phase 4
# multivariate REML fixture.
#
# This script does NOT run BLUPF90, RENUMF90, or AIREMLF90. It only rewrites the
# committed CSV fixture into whitespace-delimited files plus a conservative
# starter renumf90.par template so an external comparator lane can run the same
# two-trait animal-model estimand when BLUPF90 executables are available.
#
# Run from the repo root:
#
#   julia comparator/prepare_blupf90_multitrait.jl

using DelimitedFiles
using Printf

const ROOT = normpath(joinpath(@__DIR__, ".."))
const FIXTURE = joinpath(ROOT, "test", "fixtures", "phase4_multitrait_parity")
const OUT = joinpath(@__DIR__, "blupf90_multitrait")

function read_csv(path)
    readdlm(path, ','; header = true)
end

function write_lines(path, lines)
    open(path, "w") do io
        for line in lines
            println(io, line)
        end
    end
end

function named_matrix(path)
    data, _ = read_csv(path)
    names = string.(data[:, 1])
    values = Matrix{Float64}(undef, size(data, 1), size(data, 2) - 1)
    for i in axes(values, 1), j in axes(values, 2)
        values[i, j] = parse(Float64, string(data[i, j + 1]))
    end
    return names, values
end

mkpath(OUT)

ped, _ = read_csv(joinpath(FIXTURE, "pedigree.csv"))
pheno, _ = read_csv(joinpath(FIXTURE, "phenotypes.csv"))
_, G0 = named_matrix(joinpath(FIXTURE, "expected_genetic_covariance.csv"))
_, R0 = named_matrix(joinpath(FIXTURE, "expected_residual_covariance.csv"))

data_lines = ["# record animal x trait1 trait2"]
for i in axes(pheno, 1)
    push!(data_lines, join(string.(pheno[i, :]), " "))
end
write_lines(joinpath(OUT, "blupf90_multitrait.dat"), data_lines)

ped_lines = ["# animal sire dam"]
for i in axes(ped, 1)
    push!(ped_lines, join(string.(ped[i, :]), " "))
end
write_lines(joinpath(OUT, "blupf90_multitrait.ped"), ped_lines)

target_lines = String["quantity,row,column,value"]
for i in 1:2, j in 1:2
    push!(target_lines, @sprintf("G0,trait%d,trait%d,%.15g", i, j, G0[i, j]))
end
for i in 1:2, j in 1:2
    push!(target_lines, @sprintf("R0,trait%d,trait%d,%.15g", i, j, R0[i, j]))
end
write_lines(joinpath(OUT, "hsquared_targets.csv"), target_lines)

renum_lines = [
    "# Starter RENUMF90 instruction file for the HSquared.jl Phase 4",
    "# multivariate REML fixture. Review against your local RENUMF90/AIREMLF90",
    "# version before treating output as comparator evidence.",
    "DATAFILE blupf90_multitrait.dat",
    "TRAITS",
    "4 5",
    "FIELDS_PASSED TO OUTPUT",
    "1 2 3 4 5",
    "WEIGHT(S)",
    "",
    "RESIDUAL_VARIANCE",
    @sprintf("%.15g %.15g", R0[1, 1], R0[1, 2]),
    @sprintf("%.15g %.15g", R0[2, 1], R0[2, 2]),
    "# Shared numeric covariate x in column 3 for both traits.",
    "EFFECT",
    "3 3 cov",
    "# Animal effect in column 2 for both traits.",
    "EFFECT",
    "2 2 cross alpha",
    "RANDOM",
    "animal",
    "FILE",
    "blupf90_multitrait.ped",
    "(CO)VARIANCES",
    @sprintf("%.15g %.15g", G0[1, 1], G0[1, 2]),
    @sprintf("%.15g %.15g", G0[2, 1], G0[2, 2]),
]
write_lines(joinpath(OUT, "renumf90.par"), renum_lines)

println("Wrote BLUPF90 starter packet to ", OUT)
println("Next manual steps, if BLUPF90 executables are on PATH:")
println("  cd ", OUT)
println("  renumf90 renumf90.par")
println("  airemlf90 renf90.par")
println("Compare resulting G0/R0/beta/solutions to hsquared_targets.csv and the fixture expected_*.csv files.")
