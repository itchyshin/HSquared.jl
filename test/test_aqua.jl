# Aqua is a TEST-ONLY dependency (declared in Project.toml [extras] / [targets]
# test, never in the package's runtime [deps] — adding it there would itself be
# an Aqua stale-deps violation). Under `Pkg.test()` / CI the test environment is
# stacked over the package, so `using Aqua` and `using HSquared` both resolve.
# Run the battery via `Pkg.test()` / CI (not against the bare package project).
using Aqua
using HSquared
using Test

# Julia General-registry hygiene battery (Aqua.jl). Sister pattern: DRM.jl.
#
# `ambiguities = false`: method-ambiguity detection is disabled. HSquared
# dispatches through LinearAlgebra / SparseArrays generics and future StatsAPI
# surfaces; Aqua's ambiguity pass reports cross-package ambiguities that are
# not introduced or fixable by HSquared. This is the standard Aqua exclusion
# for packages that extend external generics; it is out of scope for registry
# hygiene.
#
# Everything else (stale deps, undefined exports, project-extras consistency,
# unbound type parameters, method piracy, and `deps_compat`) runs at the
# default strictness. `deps_compat = true` enforces a `[compat]` entry for
# every `[deps]` package and for `julia` (see Project.toml).
@testset "Aqua.jl quality assurance" begin
    Aqua.test_all(HSquared; ambiguities = false, deps_compat = true)
end
