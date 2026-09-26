# Stage profile of the hsquared sparse repeatability route, reproducing
# julia-bridge.R:1338-1372 exactly. One machine, one dataset, warm timings.
using HSquared, SparseArrays, LinearAlgebra, DelimitedFiles, Printf

S = ENV["AUDIT_DIR"]
yid,  _ = readdlm(joinpath(S,"yid.csv"), ',', header=true)
Xr,   _ = readdlm(joinpath(S,"X.csv"),   ',', header=true)
pedr, _ = readdlm(joinpath(S,"ped.csv"), ',', String, header=true)

y  = Float64.(yid[:,1])
aid = string.(yid[:,2])
X  = Float64.(Xr)
pid  = strip.(pedr[:,1]); pdam = strip.(pedr[:,2]); psire = strip.(pedr[:,3])
miss(v) = [isempty(s) || s == "NA" ? "0" : s for s in v]

t_ped  = @elapsed ped  = normalize_pedigree(pid, miss(psire), miss(pdam))
t_ainv = @elapsed Ainv = pedigree_inverse(ped)
q = size(Ainv, 1)
pos = Dict(string(v) => i for (i,v) in enumerate(ped.ids))
rows = 1:length(y); cols = [pos[a] for a in aid]
Z = sparse(collect(rows), cols, ones(length(y)), length(y), q)
Ipe = spdiagm(0 => ones(q))
eff = [(Z, Ainv), (Z, Ipe)]
@printf("n=%d p=%d q=%d nnz(Ainv)=%d\n", length(y), size(X,2), q, nnz(Ainv))
@printf("normalize_pedigree: %.3f s\npedigree_inverse:   %.3f s\n", t_ped, t_ainv)

fit = fit_multi_effect(y, X, eff; method=:auto, verbose=false)   # warm up JIT
s, se2 = fit.variance_components.sigmas, fit.variance_components.sigma_e2
@printf("\nestimates: sigma_a2=%.7f sigma_pe2=%.7f sigma_e2=%.7f  iters=%s converged=%s\n",
        s[1], s[2], se2, string(fit.iterations), string(fit.converged))

best(f, n=3) = minimum(@elapsed(f()) for _ in 1:n)
t_fit  = best(() -> fit_multi_effect(y, X, eff; method=:auto, verbose=false))
t_vcse = best(() -> multi_effect_variance_component_standard_errors(y, X, eff, s, se2))
t_rse  = best(() -> multi_effect_ratio_standard_errors(y, X, eff, s, se2))
t_ri   = best(() -> multi_effect_sum_ratio_interval(y, X, eff, s, se2; which = 1:2))
t_unc  = best(() -> multi_effect_uncertainty(y, X, eff, s, se2))

@printf("\n--- stages (best of 3, warm) ---\n")
@printf("pedigree + Ainv                      %6.3f s\n", t_ped + t_ainv)
@printf("fit_multi_effect (AI-REML)           %6.3f s\n", t_fit)
@printf("vc standard errors                   %6.3f s\n", t_vcse)
@printf("ratio standard errors                %6.3f s\n", t_rse)
@printf("summed-ratio interval                %6.3f s\n", t_ri)
@printf("  -> three separate calls (R main)   %6.3f s\n", t_vcse + t_rse + t_ri)
@printf("multi_effect_uncertainty (one call)  %6.3f s   [hsquared#238]\n", t_unc)
@printf("\nengine total, R main path            %6.3f s\n", t_ped+t_ainv+t_fit+t_vcse+t_rse+t_ri)
@printf("engine total, with #238              %6.3f s\n", t_ped+t_ainv+t_fit+t_unc)
@printf("\nthreads: julia=%d blas=%d\n", Threads.nthreads(), BLAS.get_num_threads())
