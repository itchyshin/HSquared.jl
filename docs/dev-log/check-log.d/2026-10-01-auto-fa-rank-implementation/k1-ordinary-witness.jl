# One frozen ordinary-start K1 branch witness, not a recovery study.
using HSquared, LinearAlgebra, Random, SHA, Printf

const OUTPUT = joinpath(@__DIR__, "k1-ordinary-witness-data.tsv")
const IDS = collect(1:16)
const SIRE = [i <= 4 ? 0 : 1 + (i - 5) % 2 for i in IDS]
const DAM = [i <= 4 ? 0 : 3 + (i - 5) % 2 for i in IDS]
const PEDIGREE = normalize_pedigree(IDS, SIRE, DAM)
const A = Matrix(inv(Symmetric(Matrix(pedigree_inverse(PEDIGREE)))))
const LOADINGS = [2.0, -1.8, 1.7, 2.1]
const PSI = fill(0.15, 4)
const G = LOADINGS * LOADINGS' + Diagonal(PSI)
const R = Matrix(0.15I, 4, 4)
const RNG = MersenneTwister(90102)
const U = cholesky(Symmetric(A)).L * randn(RNG, 16, 4) * cholesky(Symmetric(Matrix(G))).L'
const E = randn(RNG, 16, 4) * cholesky(Symmetric(R)).L'
const Y = repeat(reshape([0.4, -0.1, 0.6, 1.0], 1, 4), 16, 1) + U + E
const X = ones(16, 1)
const Z = Matrix{Float64}(I, 16, 16)

open(OUTPUT, "w") do io
    println(io, "id\tsire\tdam\ty1\ty2\ty3\ty4")
    for i in IDS
        println(io, join((IDS[i], SIRE[i], DAM[i], Y[i,1], Y[i,2], Y[i,3], Y[i,4]), '\t'))
    end
end

println("dataset_sha256=", bytes2hex(sha256(read(OUTPUT))))
println("source_sha256=", bytes2hex(sha256(read(joinpath(@__DIR__, "..", "..", "src", "fa_rank_selection.jl")))))
seconds = @elapsed result = select_fa_rank(Y, X, Z, PEDIGREE;
    ids = PEDIGREE.ids, traits = ["y1", "y2", "y3", "y4"], iterations = 10_000)
@printf("elapsed_seconds=%.3f\n", seconds)
println("selection_status=", result.selection_status)
println("reason=", result.reason)
println("selected_rank=", result.selected_rank)
println("criterion_difference=", result.criterion_difference)
println("kernel_ratio=", result.kernel_ratio)
println("nesting_witness_discrepancy=", result.nesting_witness_discrepancy)
for row in result.candidate_summary
    println("candidate rank=",row.rank," status=",row.status," eligible=",row.eligible,
            " start=",row.selected_start," loglik=",row.loglik," reason=",row.reason)
end
for row in result.attempts
    println("attempt rank=",row.rank," start=",row.start_id," status=",row.status,
            " converged=",row.converged," iterations=",row.optimizer_iterations,
            " loglik=",row.loglik," recheck=",row.reevaluated_loglik,
            " discrepancy=",row.objective_discrepancy," reason=",row.reason)
end
if result.selected_fit !== nothing
    println("selected_G=", repr(result.selected_fit.genetic_covariance))
    println("selected_R=", repr(result.selected_fit.residual_covariance))
    println("selected_EBV=", repr(result.selected_fit.breeding_values.values))
end
