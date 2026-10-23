using HSquared, LinearAlgebra, DelimitedFiles
function rcsv(path)
    x = readdlm(path, ',', Float64; skipstart=1)
    return Matrix{Float64}(x)
end
Y = rcsv("/private/tmp/fa-same-model-exact-20260930/fa_ref_Y.csv")
A = rcsv("/private/tmp/fa-same-model-exact-20260930/fa_ref_A.csv")
Z = rcsv("/private/tmp/fa-same-model-exact-20260930/fa_ref_Z.csv")
X = ones(size(Y,1),1)
λ = [1.0,0.8,0.65,0.5]
ψ = [.35,.4,.5,.45]
G0 = λ*λ' + Diagonal(ψ)
R0 = [1.0 .12 0 0; .12 .9 .08 0; 0 .08 .85 .07; 0 0 .07 .8]
println("julia_version ", VERSION)
println("start_loglik ", HSquared._multivariate_reml_loglik(Y,X,Z,inv(Symmetric(A)),G0,R0))
elapsed = @elapsed fit = fit_multivariate_reml(Y,X,Z,inv(Symmetric(A));
    genetic_structure=:factor_analytic,rank=1,iterations=10000,
    initial=(G0=G0,R0=R0,loadings=reshape(λ,4,1),uniqueness=ψ))
RG = rcsv("/private/tmp/fa-same-model-exact-20260930/fa_ref_R_Ghat.csv")
RR = rcsv("/private/tmp/fa-same-model-exact-20260930/fa_ref_R_Rhat.csv")
println("elapsed_s ",elapsed)
println("converged ",fit.converged," iterations ",fit.iterations)
println("loglik ",fit.loglik)
println("lambda ",vec(fit.genetic_loadings))
println("psi ",fit.genetic_uniqueness)
println("Gdiag ",diag(fit.genetic_covariance))
println("Rdiag ",diag(fit.residual_covariance))
println("h2 ",fit.heritability)
println("max_abs_Gdiff ",maximum(abs.(fit.genetic_covariance-RG)))
println("max_abs_Rdiff ",maximum(abs.(fit.residual_covariance-RR)))
println("Rhat_in_Julia_loglik ",HSquared._multivariate_reml_loglik(Y,X,Z,inv(Symmetric(A)),RG,RR))
println("Jhat_in_Julia_loglik ",HSquared._multivariate_reml_loglik(Y,X,Z,inv(Symmetric(A)),fit.genetic_covariance,fit.residual_covariance))
writedlm("/private/tmp/fa-same-model-exact-20260930/fa_ref_J_Ghat.csv",fit.genetic_covariance,',')
writedlm("/private/tmp/fa-same-model-exact-20260930/fa_ref_J_Rhat.csv",fit.residual_covariance,',')
writedlm("/private/tmp/fa-same-model-exact-20260930/fa_ref_J_EBV.csv",fit.breeding_values.values,',')
