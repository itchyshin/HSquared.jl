using DelimitedFiles
using Random
using HSquared

# Deterministic fixture for the genome-wide-CALIBRATED fixed-effect scan
# (`genome_wide_marker_scan`, the exact per-dataset add-one permutation rule). The R
# twin's `gwas(..., genome_wide = TRUE)` bridge reproduces this payload Julia-free (pure-R
# normalization parity) and, when a live Julia bridge is available, end-to-end. The RNG
# is pinned (MersenneTwister(SEED)) so the permutation null — and thus every genome-wide
# p-value and the threshold — is reproducible across the bridge.

const OUTDIR = @__DIR__
const SEED = 20264200
const NPERM = 300
const ALPHA = 0.05

function write_table(path, header, rows)
    open(path, "w") do io
        println(io, join(header, ","))
        for row in rows
            println(io, join(row, ","))
        end
    end
end

# small deterministic fixed-effect design with one planted causal marker
rng = MersenneTwister(SEED)
n, m = 24, 4
X = ones(n, 1)
markers = Float64.(rand(rng, 0:2, n, m))
causal = 2
gc = markers[:, causal] .- (sum(markers[:, causal]) / n)
y = 2.0 .+ 0.9 .* gc .+ randn(rng, n)
marker_ids = ["m$(j)" for j in 1:m]

scan = genome_wide_marker_scan(y, X, markers; n_permutations = NPERM, alpha = ALPHA,
                               marker_ids = marker_ids, rng = MersenneTwister(SEED))

write_table(joinpath(OUTDIR, "phenotypes.csv"), ["id", "y"],
            [["id$(i)", y[i]] for i in 1:n])
write_table(joinpath(OUTDIR, "markers.csv"), ["id"; marker_ids],
            [["id$(i)"; markers[i, :]] for i in 1:n])
write_table(
    joinpath(OUTDIR, "expected_genome_wide_scan_payload.csv"),
    ["marker_id", "effect", "standard_error", "z_score", "chisq", "p_value",
     "bonferroni_p_value", "bh_q_value", "lod_score", "genome_wide_p_value"],
    [[scan.marker_ids[j], scan.effects[j], scan.standard_errors[j], scan.z_scores[j],
      scan.chisq[j], scan.p_values[j], scan.bonferroni_p_values[j], scan.bh_q_values[j],
      scan.lod_scores[j], scan.genome_wide_p_values[j]] for j in 1:m],
)
write_table(
    joinpath(OUTDIR, "expected_metadata.csv"),
    ["field", "value"],
    [
        ["engine", "HSquared.jl"],
        ["target", string(scan.target)],
        ["n_markers", m],
        ["seed", SEED],
        ["n_permutations", scan.n_permutations],
        ["alpha", scan.alpha],
        ["calibration_method", string(scan.calibration.method)],
        ["rebuilt_per_dataset", scan.calibration.rebuilt_per_dataset],
        ["marker_panel_mode", string(scan.calibration.marker_panel_mode)],
        ["genome_wide_threshold", scan.genome_wide_threshold],
        ["genome_wide_p_min", scan.genome_wide_p_min],
        ["top_marker", scan.marker_ids[argmax(scan.chisq)]],
    ],
)
println("genome_wide_scan_parity fixture written (seed=", SEED, ", nperm=", NPERM,
        ", top=", scan.marker_ids[argmax(scan.chisq)], ", gw_p_min=", scan.genome_wide_p_min, ")")
