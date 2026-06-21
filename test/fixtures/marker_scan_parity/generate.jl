using DelimitedFiles
using LinearAlgebra
using SparseArrays

using HSquared

const OUTDIR = @__DIR__

function write_table(path, header, rows)
    open(path, "w") do io
        println(io, join(header, ","))
        for row in rows
            println(io, join(row, ","))
        end
    end
end

ped = normalize_pedigree(
    ["a1", "a2", "a3", "a4", "a5", "a6"],
    ["0", "0", "a1", "a1", "a2", "a2"],
    ["0", "0", "a2", "a2", "0", "0"],
)
Ainv = pedigree_inverse(ped)
y = [2.0, 3.0, 2.5, 3.5, 4.0, 1.5]
X = ones(6, 1)
Z = sparse(1.0I, 6, 6)
markers = Float64[0 1 2; 1 1 0; 2 0 1; 0 2 1; 1 0 2; 2 1 0]
marker_ids = ["m1", "m2", "m3"]
sigma_a2 = 1.2
sigma_e2 = 0.8

spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
lik = gaussian_loglik(spec, sigma_a2, sigma_e2; method = :REML)
fit = AnimalModelFit(spec, lik, (sigma_a2 = sigma_a2, sigma_e2 = sigma_e2), true, "supplied", 0)
scan = mixed_model_marker_scan(fit, markers; marker_ids = marker_ids)
payload = marker_scan_result_payload(scan)

write_table(
    joinpath(OUTDIR, "phenotypes.csv"),
    ["id", "y"],
    [[ped.ids[i], y[i]] for i in eachindex(y)],
)
write_table(
    joinpath(OUTDIR, "pedigree.csv"),
    ["id", "sire", "dam"],
    [[ped.ids[i], ped.sire[i] == 0 ? "0" : ped.ids[ped.sire[i]], ped.dam[i] == 0 ? "0" : ped.ids[ped.dam[i]]] for i in eachindex(ped.ids)],
)
write_table(
    joinpath(OUTDIR, "markers.csv"),
    ["id"; marker_ids],
    [[ped.ids[i]; markers[i, :]] for i in axes(markers, 1)],
)
write_table(
    joinpath(OUTDIR, "expected_marker_scan_payload.csv"),
    [
        "marker_id",
        "effect",
        "standard_error",
        "z_score",
        "chisq",
        "p_value",
        "bonferroni_p_value",
        "bh_q_value",
        "lod_score",
        "denominator",
        "allele_frequency",
    ],
    [
        [
            payload.marker_ids[j],
            payload.effects[j],
            payload.standard_errors[j],
            payload.z_scores[j],
            payload.chisq[j],
            payload.p_values[j],
            payload.bonferroni_p_values[j],
            payload.bh_q_values[j],
            payload.lod_scores[j],
            payload.denominators[j],
            payload.allele_frequencies[j],
        ] for j in 1:payload.n_markers
    ],
)
write_table(
    joinpath(OUTDIR, "expected_metadata.csv"),
    ["field", "value"],
    [
        ["engine", payload.engine],
        ["target", string(payload.target)],
        ["n_markers", payload.n_markers],
        ["sigma_a2", sigma_a2],
        ["sigma_e2", sigma_e2],
        ["vanraden_scale", payload.vanraden_scale],
    ],
)
