using HSquared
using LinearAlgebra
using Printf
using SparseArrays

const DIR = @__DIR__

fmt(x) = @sprintf("%.17g", x)
payload_n_trials(payload) =
    payload.n_trials === nothing ? "nothing" :
    payload.n_trials isa AbstractVector ? join(payload.n_trials, ";") :
    string(payload.n_trials)

function write_csv(path, rows)
    open(path, "w") do io
        for row in rows
            println(io, join(row, ","))
        end
    end
end

ids = ["a1", "a2", "a3", "a4", "a5", "a6"]
sire = ["0", "0", "a1", "a1", "a2", "a2"]
dam = ["0", "0", "a2", "a2", "0", "0"]
ped = normalize_pedigree(ids, sire, dam)
Ainv = pedigree_inverse(ped)
X = [ones(length(ids)) [-1.0, -0.5, 0.0, 0.5, 1.0, 1.5]]
Z = sparse(1.0I, length(ids), length(ids))

poisson_y = [8.0, 1.0, 9.0, 0.0, 7.0, 1.0]
binomial_successes = [0.0, 1.0, 5.0, 1.0, 8.0, 2.0]
binomial_trials = [2, 4, 5, 6, 10, 12]

cases = [
    (
        id = "poisson_laplace",
        family = :poisson,
        marginal = :laplace,
        y = poisson_y,
        n_trials = nothing,
        fit = fit_laplace_reml(
            poisson_y,
            X,
            Z,
            Ainv;
            family = :poisson,
            marginal = :laplace,
            ids = ped.ids,
            initial = (sigma_a2 = 1.0,),
            iterations = 500,
        ),
    ),
    (
        id = "binomial_vector_variational",
        family = :binomial,
        marginal = :variational,
        y = binomial_successes,
        n_trials = binomial_trials,
        fit = fit_laplace_reml(
            binomial_successes,
            X,
            Z,
            Ainv;
            family = :binomial,
            n_trials = binomial_trials,
            marginal = :variational,
            ids = ped.ids,
            initial = (sigma_a2 = 1.0,),
            iterations = 500,
        ),
    ),
]

all(case.fit.converged for case in cases) || error("all fixture fits must converge")

write_csv(
    joinpath(DIR, "pedigree.csv"),
    vcat([["id", "sire", "dam"]],
         [[ped.ids[i],
           ped.sire[i] == 0 ? "0" : ped.ids[ped.sire[i]],
           ped.dam[i] == 0 ? "0" : ped.ids[ped.dam[i]]] for i in eachindex(ped.ids)]),
)
write_csv(
    joinpath(DIR, "poisson_phenotypes.csv"),
    vcat([["id", "y", "x"]],
         [[ped.ids[i], fmt(poisson_y[i]), fmt(X[i, 2])] for i in eachindex(ped.ids)]),
)
write_csv(
    joinpath(DIR, "binomial_phenotypes.csv"),
    vcat([["id", "successes", "n_trials", "x"]],
         [[ped.ids[i], fmt(binomial_successes[i]), string(binomial_trials[i]), fmt(X[i, 2])]
          for i in eachindex(ped.ids)]),
)

metadata_rows = [["case", "field", "value"]]
vc_rows = [["case", "component", "value"]]
fixed_rows = [["case", "effect", "value"]]
ebv_rows = [["case", "id", "value"]]

for case in cases
    payload = nongaussian_result_payload(case.fit)
    propertynames(payload) == (
        :engine,
        :target,
        :family,
        :n_trials,
        :dispersion,
        :method,
        :variance_components,
        :fixed_effects,
        :breeding_values,
        :loglik,
        :converged,
    ) || error("unexpected payload fields for $(case.id)")
    push!(metadata_rows, [case.id, "engine", payload.engine])
    push!(metadata_rows, [case.id, "target", payload.target])
    push!(metadata_rows, [case.id, "family", payload.family])
    push!(metadata_rows, [case.id, "method", payload.method])
    push!(metadata_rows, [case.id, "n_trials", payload_n_trials(payload)])
    push!(metadata_rows, [case.id, "loglik", fmt(payload.loglik)])
    push!(metadata_rows, [case.id, "converged", string(payload.converged)])
    push!(metadata_rows, [case.id, "n_fixed_effects", string(length(payload.fixed_effects))])
    push!(metadata_rows, [case.id, "n_breeding_values", string(length(payload.breeding_values.values))])
    for component in propertynames(payload.variance_components)
        push!(vc_rows, [case.id, string(component), fmt(getproperty(payload.variance_components, component))])
    end
    for (effect, value) in zip(["Intercept", "x"], payload.fixed_effects)
        push!(fixed_rows, [case.id, effect, fmt(value)])
    end
    for (id, value) in zip(payload.breeding_values.ids, payload.breeding_values.values)
        push!(ebv_rows, [case.id, id, fmt(value)])
    end
end

write_csv(joinpath(DIR, "expected_payload_metadata.csv"), metadata_rows)
write_csv(joinpath(DIR, "expected_variance_components.csv"), vc_rows)
write_csv(joinpath(DIR, "expected_fixed_effects.csv"), fixed_rows)
write_csv(joinpath(DIR, "expected_breeding_values.csv"), ebv_rows)

println("wrote non-Gaussian parity fixture CSVs to ", DIR)
