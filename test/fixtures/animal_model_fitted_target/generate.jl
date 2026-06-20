# Reproducible generator for the Julia-native fitted univariate animal-model target
# fixture (#46). The ENGINE fits its OWN model and serializes its OWN output — no
# textbook EBVs are typed from memory. Run from the repo root:
#
#     julia --project=. test/fixtures/animal_model_fitted_target/generate.jl
#
# RNG is used ONCE here to realize a single dataset with genuine additive structure
# (so the REML optimum is interior, not on the sigma_a2 = 0 boundary). The realized
# y/x are committed, so the fixture + its CI self-consistency test are deterministic.
using HSquared, LinearAlgebra, SparseArrays, Random, Printf, DelimitedFiles

const DIR = @__DIR__

# Deterministic multi-generation pedigree (Mrode/gryphon-shaped, 20 animals).
ids  = ["a$(i)" for i in 1:20]
sire = ["0","0","0","0","0","0","a1","a1","a2","a4","a4","a5","a7","a8","a9","a7","a8","a9","a13","a14"]
dam  = ["0","0","0","0","0","0","a2","a3","a3","a5","a6","a6","a10","a11","a12","a12","a10","a11","a16","a17"]
ped  = normalize_pedigree(ids, sire, dam)
Ainv = pedigree_inverse(ped)
n    = length(ped.ids)
A    = inv(Matrix(Ainv))                      # validation-scale dense draw only

rng = MersenneTwister(20260620)
x   = round.(randn(rng, n); digits = 3)        # one numeric covariate
L   = cholesky(Symmetric(A)).L
sigma_a2_true, sigma_e2_true = 1.0, 1.0
u   = sqrt(sigma_a2_true) .* (L * randn(rng, n))
y   = round.(5.0 .+ 2.0 .* x .+ u .+ sqrt(sigma_e2_true) .* randn(rng, n); digits = 4)

X = hcat(ones(n), x)
Z = sparse(1.0I, n, n)
spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
fit  = fit_variance_components(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0), method = :REML)

vc   = variance_components(fit)
beta = fixed_effects(fit)
ebv  = breeding_values(fit)
h2   = heritability(fit)
pev  = prediction_error_variance(fit; method = :selinv)
rel  = reliability(fit; method = :selinv)
ll   = fit.likelihood.loglik

@assert vc.sigma_a2 > 0.05 "REML optimum is on/near the boundary; pick another design/seed"
@printf("fitted: sigma_a2=%.6f sigma_e2=%.6f h2=%.6f loglik=%.6f converged=%s\n",
        vc.sigma_a2, vc.sigma_e2, h2, ll, fit.converged)

# --- serialize ---
writedlm(joinpath(DIR, "pedigree.csv"),  vcat(["animal" "sire" "dam"], hcat(ped.ids, sire, dam)), ',')
writedlm(joinpath(DIR, "phenotypes.csv"), vcat(["animal" "x" "y"], hcat(ped.ids, x, y)), ',')
writedlm(joinpath(DIR, "expected_variance_components.csv"),
         vcat(["name" "value"], ["sigma_a2" vc.sigma_a2; "sigma_e2" vc.sigma_e2]), ',')
writedlm(joinpath(DIR, "expected_beta.csv"),
         vcat(["effect" "value"], ["Intercept" beta[1]; "x" beta[2]]), ',')
writedlm(joinpath(DIR, "expected_ebv.csv"),
         vcat(["id" "value"], hcat(ebv.ids, ebv.values)), ',')
writedlm(joinpath(DIR, "expected_reliability.csv"),
         vcat(["id" "pev" "reliability"], hcat(rel.ids, pev.values, rel.values)), ',')
writedlm(joinpath(DIR, "expected_metadata.csv"),
         vcat(["key" "value"],
              ["h2" h2; "loglik" ll; "sigma_a2" vc.sigma_a2; "sigma_e2" vc.sigma_e2;
               "converged" fit.converged; "n_animals" n; "method" "REML"]), ',')
println("wrote fixture CSVs to ", DIR)
