using HSquared, Random, SparseArrays, LinearAlgebra, Statistics, Printf
import HSquared: _sparse_mme_system      # for the exact fill proxy used by _auto_reml_route

# Joint fill×n crossover benchmark for the `:auto` eigen-vs-sparse route (S4). The shipped
# `_auto_reml_route` (src/likelihood.jl) routes eigen-once when the MME fill proxy nnz(L)/n exceeds
# a SCALAR threshold (60, a conservative first-pass biased toward the validated sparse default). This
# maps the ACTUAL crossover — where `fit_eigen_reml` (fill-INDEPENDENT dense O(n³)) becomes faster
# than `fit_ai_reml` (fill-SENSITIVE) — as a function of BOTH n and fill, so the threshold can be
# recalibrated from measurement instead of a first-pass guess. NOT a covered-status move; the
# eigen/sparse fitters are unchanged, only the routing heuristic is being characterized.
#
#   env OPENBLAS_NUM_THREADS=8 julia --project=. sim/bench_eigen_crossover.jl   (Totoro; ≤100 cores)

BLAS.set_num_threads(8)   # dense eigendecomposition is BLAS3-parallel; Totoro etiquette ≤100 cores

# DGP identical to the Totoro bench_eigen.jl / gate builder (recursive Mendelian breeding values;
# `window` controls pedigree bandwidth ⇒ fill-in: window=0 random/high-fill, larger=lower-fill).
function build_spec(n; h2 = 0.4, seed = 1, window = 0)
    rng = MersenneTwister(seed)
    s = zeros(Int, n); d = zeros(Int, n)
    for i in 3:n
        lo = window > 0 ? max(1, i - window) : 1
        s[i] = rand(rng, lo:i-1); d[i] = rand(rng, lo:i-1)
        while d[i] == s[i]; d[i] = rand(rng, lo:i-1); end
    end
    Ainv = pedigree_inverse(collect(1:n), s, d)
    sa2 = h2; se2 = 1 - h2
    u = zeros(n)
    for i in 1:n
        (s[i] == 0 && d[i] == 0) ? (u[i] = sqrt(sa2) * randn(rng)) :
            (u[i] = 0.5 * (u[s[i]] + u[d[i]]) + sqrt(0.5 * sa2) * randn(rng))
    end
    y = 10.0 .+ u .+ sqrt(se2) .* randn(rng, n)
    animal_model_spec(y, ones(n, 1), sparse(1:n, 1:n, ones(n)), Ainv; ids = collect(1:n), method = :REML)
end

# The exact fill proxy _auto_reml_route compares to the threshold: nnz(L)/n of the sparse MME Cholesky.
function fill_proxy(spec)
    n = length(spec.y)
    lhs, _, _ = _sparse_mme_system(spec, 1.0, 1.0)
    F = cholesky(Symmetric(lhs))
    return nnz(sparse(F.L)) / n
end

const GRID_N = [1000, 2000, 4000]
const GRID_W = [0, 15, 30, 50, 100, 250]     # high-fill (0) → low-fill (250)

# precompile all three code paths
let sp = build_spec(300; window = 50); fit_eigen_reml(sp); fit_ai_reml(sp); fill_proxy(sp); HSquared._auto_reml_route(sp); end

println("eigen-vs-sparse crossover (BLAS=", BLAS.get_num_threads(), " threads); truth h²=0.4")
@printf("%-6s %-7s %-9s %-10s %-11s %-9s %-10s\n", "n", "window", "proxy", "t_eigen", "t_ai", "speedup", "route@60")
for n in GRID_N, w in GRID_W
    sp = build_spec(n; window = w, seed = 101)
    p = fill_proxy(sp)
    te = @elapsed fit_eigen_reml(sp)
    ta = @elapsed fit_ai_reml(sp; initial = (sigma_a2 = 0.8, sigma_e2 = 0.8))
    route = HSquared._auto_reml_route(sp)
    win = ta / te > 1 ? "eigen" : "sparse"     # which is actually faster
    @printf("%-6d %-7d %-9.1f %-10.3f %-11.3f %-9.2f %-10s %s\n",
            n, w, p, te, ta, ta / te, String(route), win)
    flush(stdout)
end
println("DONE")
