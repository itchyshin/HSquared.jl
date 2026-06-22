# Reproducible generator for the Julia-native fitted SIRE-MODEL target fixture (#16,
# Mrode Ch.4). The ENGINE fits its OWN sire model and serializes its OWN output — a
# sire model is an ordinary animal-model spec with a record->sire incidence Z and a
# sires-only pedigree_inverse; NO new fitting kernel. Run from the repo root:
#
#     julia --project=. test/fixtures/sire_model_fitted_target/generate.jl
#
# RNG is used ONCE here to realize a single dataset with genuine sire variance (so the
# REML optimum is interior). The realized data are committed, so the fixture + its CI
# self-consistency test are deterministic.
#
# HONESTY: the engine stores the estimated sire variance in its generic `sigma_a2`
# slot; here that IS sigma_s2 (sire variance). The engine's generic `heritability()`
# accessor returns sigma_s2/(sigma_s2+sigma_e2), which is NOT h^2 for a sire model —
# this fixture stores the corrected h^2 = 4*sigma_s2/(sigma_s2+sigma_e2) itself.
using HSquared, LinearAlgebra, SparseArrays, Random, Printf, DelimitedFiles

const DIR = @__DIR__

# Sires-only pedigree (12 sires, 3 generations; dams unknown — sire model).
sire_ids  = ["s$(i)" for i in 1:12]
sire_sire = ["0","0","0","0","s1","s1","s2","s3","s5","s6","s7","s8"]
sire_dam  = fill("0", 12)
ped  = normalize_pedigree(sire_ids, sire_sire, sire_dam)
Ainv = pedigree_inverse(ped)
ns   = length(ped.ids)
A    = inv(Matrix(Ainv))                       # validation-scale dense draw only

rng  = MersenneTwister(20260622)
nrec = 120
rec_sire_idx = [((i - 1) % ns) + 1 for i in 1:nrec]    # each sire gets ~6 records
x    = round.(randn(rng, nrec); digits = 3)
L    = cholesky(Symmetric(A)).L
sigma_s2_true, sigma_e2_true = 0.5, 4.5    # true h2 = 4*0.5/(0.5+4.5) = 0.4 (interior)
u    = sqrt(sigma_s2_true) .* (L * randn(rng, ns))     # sire transmitting abilities (ped.ids order)
y    = round.(8.0 .+ 1.5 .* x .+ u[rec_sire_idx] .+ sqrt(sigma_e2_true) .* randn(rng, nrec); digits = 4)

X = hcat(ones(nrec), x)
Z = sparse(1:nrec, rec_sire_idx, 1.0, nrec, ns)        # record -> sire incidence
spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
fit  = fit_variance_components(spec; initial = (sigma_a2 = 0.5, sigma_e2 = 4.5), method = :REML)

vc   = variance_components(fit)
sigma_s2, sigma_e2 = vc.sigma_a2, vc.sigma_e2          # engine sigma_a2 slot IS the sire variance
beta = fixed_effects(fit)
ebv  = breeding_values(fit)
pev  = prediction_error_variance(fit; method = :selinv)
rel  = reliability(fit; method = :selinv)
ll   = fit.likelihood.loglik
h2   = 4 * sigma_s2 / (sigma_s2 + sigma_e2)            # narrow-sense h^2 from the sire variance

@assert sigma_s2 > 0.05 "sire REML optimum is on/near the boundary; pick another design/seed"
@assert 0 < h2 < 1 "implied h2 = $(h2) outside (0,1); adjust the DGP (need 4*sigma_s2 < sigma_s2 + sigma_e2)"
@printf("fitted sire model: sigma_s2=%.6f sigma_e2=%.6f h2=%.6f loglik=%.6f converged=%s\n",
        sigma_s2, sigma_e2, h2, ll, fit.converged)

# --- serialize ---
writedlm(joinpath(DIR, "pedigree.csv"),  vcat(["sire" "sire_sire" "sire_dam"], hcat(ped.ids, sire_sire, sire_dam)), ',')
rec_ids    = ["r$(i)" for i in 1:nrec]
rec_labels = [ped.ids[rec_sire_idx[i]] for i in 1:nrec]
writedlm(joinpath(DIR, "phenotypes.csv"), vcat(["record" "sire" "x" "y"], hcat(rec_ids, rec_labels, x, y)), ',')
writedlm(joinpath(DIR, "expected_variance_components.csv"),
         vcat(["name" "value"], ["sigma_s2" sigma_s2; "sigma_e2" sigma_e2]), ',')
writedlm(joinpath(DIR, "expected_beta.csv"),
         vcat(["effect" "value"], ["Intercept" beta[1]; "x" beta[2]]), ',')
writedlm(joinpath(DIR, "expected_ebv.csv"),
         vcat(["id" "value"], hcat(ebv.ids, ebv.values)), ',')
writedlm(joinpath(DIR, "expected_reliability.csv"),
         vcat(["id" "pev" "reliability"], hcat(rel.ids, pev.values, rel.values)), ',')
writedlm(joinpath(DIR, "expected_metadata.csv"),
         vcat(["key" "value"],
              ["h2" h2; "loglik" ll; "sigma_s2" sigma_s2; "sigma_e2" sigma_e2;
               "sigma_a2_implied" 4 * sigma_s2; "converged" fit.converged;
               "n_sires" ns; "n_records" nrec; "method" "REML"; "model" "sire"]), ',')
println("wrote sire fixture CSVs to ", DIR)
