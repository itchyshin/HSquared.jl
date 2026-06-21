# Opt-in JWAS.jl comparator for the univariate fitted animal-model target (#49).
#
# OPT-IN ONLY. This is NOT part of the HSquared.jl test suite, NOT in CI, and JWAS
# is NOT a package dependency. It runs only when HSQUARED_RUN_JWAS=true, in the
# SEPARATE comparator environment:
#
#     julia --project=comparator comparator/setup_jwas_env.jl
#     HSQUARED_RUN_JWAS=true julia --project=comparator comparator/run_jwas_animal_model.jl
#
# It fits the SAME single-trait animal model as the serialized target fixture with
# JWAS (Gibbs/MCMC, Bayesian) and reports AGREEMENT with the engine's REML target.
# JWAS posterior means and REML estimates are DIFFERENT estimators, so agreement is
# expected only approximately — the report never claims "parity" or "validation".

const FIXTURE = joinpath(@__DIR__, "..", "test", "fixtures", "animal_model_fitted_target")
const JWAS_OUTPUT_DIR = joinpath(@__DIR__, "results")

if get(ENV, "HSQUARED_RUN_JWAS", "false") != "true"
    println("""
    [skip] JWAS comparator is opt-in. Set HSQUARED_RUN_JWAS=true and run in the
           separate comparator env to execute:
             julia --project=comparator comparator/setup_jwas_env.jl
             HSQUARED_RUN_JWAS=true julia --project=comparator comparator/run_jwas_animal_model.jl
    """)
    exit(0)
end

# --- imports happen ONLY past the opt-in guard ---
using JWAS, CSV, DataFrames, DelimitedFiles, Statistics

read_named(path) = (rows = readdlm(path, ','; skipstart = 1); rows)

# engine REML targets (the serialized fixture)
vc = read_named(joinpath(FIXTURE, "expected_variance_components.csv"))
target_sigma_a2 = Float64(vc[findfirst(==("sigma_a2"), vc[:, 1]), 2])
target_sigma_e2 = Float64(vc[findfirst(==("sigma_e2"), vc[:, 1]), 2])
ebv_rows = read_named(joinpath(FIXTURE, "expected_ebv.csv"))
target_ebv = Dict(string(ebv_rows[i, 1]) => Float64(ebv_rows[i, 2]) for i in axes(ebv_rows, 1))

# JWAS needs a pedigree file and a phenotype DataFrame. Build them from the fixture.
ped_df = CSV.read(joinpath(FIXTURE, "pedigree.csv"), DataFrame)
pheno = CSV.read(joinpath(FIXTURE, "phenotypes.csv"), DataFrame)

# NOTE: confirm these JWAS API names against your installed JWAS version — the
# package's public API has shifted across releases. The shape below targets the
# JWAS "build_model / set_covariate / set_random / get_pedigree / runMCMC" flow.
# IN PARTICULAR: JWAS conventionally keys pedigree-linked random effects and EBV
# output off an `ID` column. The fixture's ID column is named `animal`; depending
# on your JWAS version you may need to rename it to `ID` in the phenotype DataFrame
# (and adjust the model term + the out[...] EBV key) before runMCMC.
ped_path = joinpath(@__DIR__, "_jwas_pedigree.csv")
CSV.write(ped_path, ped_df)
pedigree = cd(@__DIR__) do
    get_pedigree(ped_path, separator = ",", header = true)
end

model = build_model("y = intercept + x + animal")
set_covariate(model, "x")
set_random(model, "animal", pedigree)

out = cd(@__DIR__) do
    isdir(JWAS_OUTPUT_DIR) && rm(JWAS_OUTPUT_DIR; recursive = true, force = true)
    runMCMC(model, pheno; chain_length = 50_000, burnin = 10_000,
            output_samples_frequency = 100, seed = 20260620, outputEBV = true,
            output_folder = JWAS_OUTPUT_DIR)
end

# Extract JWAS posterior-mean variance components + EBVs (key names are
# version-dependent; adjust to your JWAS output keys if these differ).
ebv_df = out["EBV_y"]                                   # DataFrame with :ID, :EBV
jwas_ebv = Dict(string(ebv_df[i, :ID]) => Float64(ebv_df[i, :EBV]) for i in 1:nrow(ebv_df))

ids = collect(keys(target_ebv))
common = [id for id in ids if haskey(jwas_ebv, id)]
te = [target_ebv[id] for id in common]
je = [jwas_ebv[id] for id in common]
ebv_cor = cor(te, je)
ebv_maxabs = maximum(abs.(te .- je))

println("=== JWAS (MCMC posterior mean) vs HSquared.jl (REML) — AGREEMENT, not parity ===")
println("engine REML sigma_a2 = ", target_sigma_a2, " ; sigma_e2 = ", target_sigma_e2)
println("aligned animals: ", length(common))
println("EBV correlation (JWAS posterior mean vs REML): ", round(ebv_cor; digits = 4))
println("EBV max abs difference: ", round(ebv_maxabs; digits = 4))
println("""
NOTE: JWAS is MCMC/Bayesian and HSquared.jl reports REML — these are different
estimators, so agreement is expected to be approximate (shrinkage + prior + Monte
Carlo error). This run records AGREEMENT for honest cross-checking; it is NOT a
parity/validation claim and does not by itself move any capability to covered.
""")
