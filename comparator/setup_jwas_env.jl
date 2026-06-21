# Opt-in setup for the separate JWAS comparator environment.
#
# JWAS.jl is not registered in Julia General, so Pkg.instantiate() alone cannot
# resolve it from Project.toml. This helper records the unregistered source in
# the local, git-ignored comparator/Manifest.toml.

using Pkg

Pkg.activate(@__DIR__)
Pkg.add(url = "https://github.com/reworkhow/JWAS.jl")
Pkg.instantiate()

println("JWAS comparator environment is ready. Run:")
println("  HSQUARED_RUN_JWAS=true julia --project=comparator comparator/run_jwas_animal_model.jl")
